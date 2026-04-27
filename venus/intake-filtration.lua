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

--- @alias WantGlobal {
---   intake_on: number,
---   cooling_active: number,
--- }

--- @alias WantPipeline {
---   filter_on: number,
---   volpump_on: number,
--- }

--- @alias PipelineState fun(pl: Pipeline, want_global: WantGlobal, want_pl: WantPipeline): PipelineState

--- @alias Pipeline {
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

--- @type PrefabNamed
local INTAKE
--- @type PrefabNamed
local COOLER

--- @type Pipeline
local N2_PIPELINE
--- @type Pipeline
local CO2_PIPELINE

function configuration()
	TARGET_TEMPERATURE_K = util.temp(25, "C", "K")
	TARGET_TEMPERATURE_TOLERANCE_K = 3.0

	INTAKE = PrefabNamed:new({ ph = PH_ACTIVE_VENT, nh = hash("AV Atmosphere Intake") })
	COOLER = PrefabNamed:new({ ph = PH_AIRCON, nh = hash("Cooling Tanks Air Conditioner") })

	N2_PIPELINE = {
		filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("N2 Filtration") }),
		vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("N2 Volume Pump") }),
		cold_pa = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("Cold N2 Pipe Analyzer") }),
		target_cooling_pressure_kpa = 1000,
		target_cold_pressure_kpa = 1000,
		current_state = pl_state_wait,
	}
	CO2_PIPELINE = {
		filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("CO2 Filtration") }),
		vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("CO2 Volume Pump") }),
		cold_pa = PrefabNamed:new({ ph = PH_PIPEANA, nh = hash("Cold CO2 Pipe Analyzer") }),
		target_cooling_pressure_kpa = 1000,
		target_cold_pressure_kpa = 5000,
		current_state = pl_state_wait,
	}
end

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	COOLER:write_batch(LT.On, 1)

	local want_global = { cooling_active = false, intake_on = false }
	run_pipeline(N2_PIPELINE, want_global)
	run_pipeline(CO2_PIPELINE, want_global)
	INTAKE:write_batch(LT.On, want_global.intake_on)
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
	-- TODO: Consider loading only during cooler weather.
	pl.current_state = pl.current_state(pl, want_global, want_pl)
	pl.filter:write_batch(LT.On, want_pl.filter_on)
	pl.vol_pump:write_batch(LT.On, want_pl.volpump_on)
	pl.vol_pump:write_batch(LT.Setting, 10)
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_load(pl, want_global, want_pl)
	local out_pressure = pl.filter:read_batch(LT.PressureOutput, LBM.Maximum)
	if out_pressure >= pl.target_cooling_pressure_kpa then
		return pl_state_cooling(pl, want_global, want_pl)
	end
	want_pl.filter_on = 1
	want_pl.volpump_on = 0
	want_global.intake_on = 1
	want_global.cooling_active = 1
	return pl_state_load
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_cooling(pl, want_global, want_pl)
	local cooling_temperature_k = pl.filter:read_batch(LT.TemperatureOutput, LBM.Average)
	local temperature_diff_k = math.abs(cooling_temperature_k - TARGET_TEMPERATURE_K)
	if temperature_diff_k <= TARGET_TEMPERATURE_TOLERANCE_K then
		return pl_state_moving(pl, want_global, want_pl)
	end
	want_pl.filter_on = 0
	want_pl.volpump_on = 0
	want_global.cooling_active = 1
	return pl_state_cooling
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_moving(pl, want_global, want_pl)
	local cold_tank_kpa = pl.cold_pa:read_batch(LT.Pressure, LBM.Maximum)
	if cold_tank_kpa >= pl.target_cold_pressure_kpa then
		return pl_state_wait(pl, want_global, want_pl)
	end
	want_pl.filter_on = 0
	want_pl.volpump_on = 1
	return pl_state_moving
end

--- @param pl Pipeline
--- @param want_global WantGlobal
--- @param want_pl WantPipeline
--- @return PipelineState
function pl_state_wait(pl, want_global, want_pl)
	local cold_tank_kpa = pl.cold_pa:read_batch(LT.Pressure, LBM.Maximum)
	local cooling_tank_kpa = pl.filter:read_batch(LT.TemperatureOutput, LBM.Maximum)
	if cold_tank_kpa < pl.target_cold_pressure_kpa or cooling_tank_kpa < pl.target_cooling_pressure_kpa then
		return pl_state_load(pl, want_global, want_pl)
	end
	want_pl.filter_on = 0
	want_pl.volpump_on = 0
	return pl_state_wait
end

configuration()
