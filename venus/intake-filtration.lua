-- Lua script to manage intake of atmospheric Venus gasses, filter to collect
-- N2 and CO2 in separate tanks, then cool them to 25C for use in greenhouse
-- and other purposes. The Lua chip can be housed in the air conditioner.

local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

-- include:PrefabNamed.lua

local PH_ACTIVE_VENT = -1129453144
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

--- @alias Pipeline {
---   name: string,
---   filter: PrefabNamed,
---   vol_pump: PrefabNamed,
---   cold_pa: PrefabNamed,
---   target_cooling_pressure_kpa: number,
---   target_cold_pressure_kpa: number,
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
local MAX_TANK_PRESSURE = 46000
--- Maximum pressure to fill a cooling tank to.
--- @type number
local MAX_COOLING_PRESSURE = 5000

--- @type [Pipeline]
local PIPELINES

function configuration()
	TARGET_TEMPERATURE_K = util.temp(25, "C", "K")
	TARGET_TEMPERATURE_TOLERANCE_K = 4.0
	INTAKE_BELOW_TEMPERATURE_K = util.temp(400, "C", "K")

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
		},
		{
			name = "CO2",
			filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("CO2 Filtration") }),
			vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("CO2 Volume Pump") }),
			cold_pa = PrefabNamed:new({ ph = PH_PIPEANA, nh = hash("Cold CO2 Pipe Analyzer") }),
			target_cooling_pressure_kpa = 1000,
			target_cold_pressure_kpa = 5000,
		},
	}
end

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	-- COOLER is assumed to be housing this Lua chip.
	COOLER:write_batch(LT.On, 1)

	can_fill_atmospheric_tank()
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

	local cooling_pressure = pl.filter:read_batch(LT.PressureOutput, LBM.Maximum)
	local cold_pressure = pl.cold_pa:read_batch(LT.Pressure, LBM.Maximum)
	local filtration_input_pressure = pl.filter:read_batch(LT.PressureInput, LBM.Maximum)
	local cooling_temperature_is_good = is_cooling_temperature_good(pl)

	if cooling_temperature_is_good and cooling_pressure > MIN_TANK_PRESSURE and cold_pressure < MAX_TANK_PRESSURE then
		want_pl.volpump_on = 1
	elseif filtration_input_pressure > MIN_TANK_PRESSURE and cooling_pressure <= MAX_COOLING_PRESSURE then
		want_pl.filter_on = 1
	end

	if not cooling_temperature_is_good then
		want_global.cooling_active = 1
	end

	pl.filter:write_batch(LT.On, want_pl.filter_on)
	pl.vol_pump:write_batch(LT.On, want_pl.volpump_on)
	if want_pl.volpump_on then
		pl.vol_pump:write_batch(LT.Setting, 10)
	end
end

--- @param pl Pipeline
--- @return boolean
function is_cooling_temperature_good(pl)
	local cooling_temperature_k = pl.filter:read_batch(LT.TemperatureOutput, LBM.Average)
	local temperature_diff_k = math.abs(cooling_temperature_k - TARGET_TEMPERATURE_K)
	return temperature_diff_k <= TARGET_TEMPERATURE_TOLERANCE_K
end

--- @return boolean
function can_fill_atmospheric_tank()
	return INTAKE:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_TANK_PRESSURE
end

--- @return boolean
function is_atmospheric_temperature_good()
	return ATMOSPHERE_GS:read_batch(LT.Temperature, LBM.Average) < INTAKE_BELOW_TEMPERATURE_K
end

configuration()
