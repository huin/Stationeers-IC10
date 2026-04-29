-- Lua script to manage intake of atmospheric Venus gasses, filter to collect
-- N2 and CO2 in separate tanks, then cool them to 25C for use in greenhouse
-- and other purposes. The Lua chip can be housed in the air conditioner.

local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

-- include:PrefabNamed.lua

local PH_ACTIVE_VENT = -842048328
local PH_AIRCON = -2087593337
local PH_FILTRATION = -348054045
local PH_VOLPUMP = -321403609
local PH_PIPEANA = 435685051
local PH_GAS_SENSOR = -1252983604

--- @alias WantGlobal {
---   cooling_active: number,
--- }

--- @alias WantPipeline {
---   filter_on: number,
---   volpump_on: number,
--- }

--- @alias PipelineState fun(pl: Pipeline, want_global: WantGlobal, want_pl: WantPipeline): PipelineState

--- @alias Pipeline {
---   name: string,
---   filter: PrefabNamed,
---   vol_pump: PrefabNamed,
---   cold_pa: PrefabNamed,
---   target_cooling_pressure_kpa: number,
---   target_cold_pressure_kpa: number,
---   current_state: PipelineState,
--- }

--- @type number
local TARGET_TEMPERATURE_K
--- @type number
local TARGET_TEMPERATURE_TOLERANCE_K
--- Only run atmospheric intake when atmosphere below this temperature.
--- @type number
local INTAKE_BELOW_TEMPERATURE_K

--- @type PrefabNamed
local ATMOSPHERE_GS
--- @type PrefabNamed
local INTAKE
--- @type PrefabNamed
local COOLER

--- Minimum pressure at which a tank is worth pumping from.
--- @type number
local MIN_TANK_PRESSURE = 100
--- Maximum pressure to fill a tank to.
--- @type number
local MAX_TANK_PRESSURE = 49000

--- @type [Pipeline]
local PIPELINES

function configuration()
	TARGET_TEMPERATURE_K = util.temp(25, "C", "K")
	TARGET_TEMPERATURE_TOLERANCE_K = 4.0
	INTAKE_BELOW_TEMPERATURE_K = util.temp(380, "C", "K")

	ATMOSPHERE_GS = PrefabNamed:new({ ph = PH_GAS_SENSOR, nh = hash("Atmospheric Gas Sensor") })
	INTAKE = PrefabNamed:new({ ph = PH_ACTIVE_VENT, nh = hash("AV Atmosphere Intake") })
	COOLER = PrefabNamed:new({ ph = PH_AIRCON, nh = hash("Cooling Tanks Air Conditioner") })

	PIPELINES = {
		{
			name = "N2",
			filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("N2 Filtration") }),
			vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("N2 Volume Pump") }),
			cold_pa = PrefabNamed:new({ ph = PH_PIPEANA, nh = hash("Cold N2 Pipe Analyzer") }),
			target_cooling_pressure_kpa = 1000,
			target_cold_pressure_kpa = 1000,
			current_state = pl_state_wait,
		},
		{
			name = "CO2",
			filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("CO2 Filtration") }),
			vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("CO2 Volume Pump") }),
			cold_pa = PrefabNamed:new({ ph = PH_PIPEANA, nh = hash("Cold CO2 Pipe Analyzer") }),
			target_cooling_pressure_kpa = 1000,
			target_cold_pressure_kpa = 5000,
			current_state = pl_state_wait,
		},
	}
end

--- @type table<PipelineState, string>
local state_names

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	-- COOLER is assumed to be housing this Lua chip.
	COOLER:write_batch(LT.On, 1)

	if is_atmospheric_temperature_good() and can_fill_atmospheric_tank() then
		INTAKE:write_batch(LT.Mode, 1) -- Intake mode.
		INTAKE:write_batch(LT.PressureInternal, MAX_TANK_PRESSURE)
		INTAKE:write_batch(LT.On, 1)
	else
		INTAKE:write_batch(LT.On, 0)
	end

	--- @type WantGlobal
	local want_global = { cooling_active = 0 }
	for _, pl in ipairs(PIPELINES) do
		run_pipeline(pl, want_global)
	end
	-- Use Mode for aircon, so that it can house the chip (powering itself off
	-- would be a bad idea).
	COOLER:write_batch(LT.Mode, want_global.cooling_active)
	COOLER:write_batch(LT.Setting, TARGET_TEMPERATURE_K)
end

--- @param pl Pipeline
--- @param want_global WantGlobal
function run_pipeline(pl, want_global)
	pl.cold_pa:write_batch(LT.On, 1)
	--- @type WantPipeline
	local want_pl = { filter_on = 0, volpump_on = 0 }
	-- TODO: Check filtration filters.
	local original_state = pl.current_state
	pl.current_state = pl.current_state(pl, want_global, want_pl)
	if original_state ~= pl.current_state then
		print(string.format("%s %s -> %s", pl.name, state_names[original_state], state_names[pl.current_state]))
	else
		print(string.format("%s %s", pl.name, state_names[original_state]))
	end
	pl.filter:write_batch(LT.On, want_pl.filter_on)
	pl.vol_pump:write_batch(LT.On, want_pl.volpump_on)
	if want_pl.volpump_on then
		pl.vol_pump:write_batch(LT.Setting, 10)
	end
end

--- Idle state, waiting to dispatch to a useful operation.
--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_wait(pl, want_global, want_pl)
	if is_cooling_tank_below_pressure(pl) then
		if not is_filtration_input_below_pressure(pl) then
			return pl_state_load(pl, want_global, want_pl)
		end
		return pl_state_wait
	end

	if not is_cooling_temperature_good(pl) then
		return pl_state_cooling(pl, want_global, want_pl)
	end

	if is_cold_tank_below_pressure(pl) then
		return pl_state_moving(pl, want_global, want_pl)
	end

	return pl_state_wait
end

--- Load atmospheric gas into the cooling tanks.
--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_load(pl, want_global, want_pl)
	if not is_cooling_tank_below_pressure(pl) then
		return pl_state_cooling(pl, want_global, want_pl)
	end
	if is_filtration_input_below_pressure(pl) then
		return pl_state_wait(pl, want_global, want_pl)
	end
	want_pl.filter_on = 1
	want_global.cooling_active = 1
	return pl_state_load
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_cooling(pl, want_global, want_pl)
	if is_cooling_temperature_good(pl) then
		return pl_state_moving(pl, want_global, want_pl)
	end
	want_global.cooling_active = 1
	return pl_state_cooling
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_moving(pl, want_global, want_pl)
	if
		not is_cooling_temperature_good(pl)
		or not is_cold_tank_below_pressure(pl)
		or is_cooling_tank_below_pressure(pl)
	then
		return pl_state_wait(pl, want_global, want_pl)
	end
	want_pl.volpump_on = 1
	return pl_state_moving
end

--- @param pl Pipeline
--- @return boolean
function is_cooling_temperature_good(pl)
	local cooling_temperature_k = pl.filter:read_batch(LT.TemperatureOutput, LBM.Average)
	local temperature_diff_k = math.abs(cooling_temperature_k - TARGET_TEMPERATURE_K)
	return temperature_diff_k <= TARGET_TEMPERATURE_TOLERANCE_K
end

--- @param pl Pipeline
--- @return boolean
function is_cold_tank_below_pressure(pl)
	return pl.cold_pa:read_batch(LT.Pressure, LBM.Maximum) < pl.target_cold_pressure_kpa
end

--- @param pl Pipeline
--- @return boolean
function is_cooling_tank_below_pressure(pl)
	return pl.filter:read_batch(LT.PressureOutput, LBM.Maximum) < MIN_TANK_PRESSURE
end

--- @param pl Pipeline
--- @return boolean
function is_filtration_input_below_pressure(pl)
	return pl.filter:read_batch(LT.PressureInput, LBM.Maximum) < MIN_TANK_PRESSURE
end

--- @return boolean
function can_fill_atmospheric_tank()
	return INTAKE:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_TANK_PRESSURE
end

--- @return boolean
function is_atmospheric_temperature_good()
	return ATMOSPHERE_GS:read_batch(LT.Temperature, LBM.Average) < INTAKE_BELOW_TEMPERATURE_K
end

state_names = {
	[pl_state_wait] = "wait",
	[pl_state_load] = "load",
	[pl_state_cooling] = "cooling",
	[pl_state_moving] = "moving",
}

configuration()
