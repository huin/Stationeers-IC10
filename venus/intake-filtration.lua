-- Lua script to manage intake of atmospheric Venus gasses, filter to collect
-- N2 and CO2 in separate tanks, then cool them to 25C for use in greenhouse
-- and other purposes. The Lua chip can be housed in the air conditioner.

local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

--- @class PrefabNamed
--- @field ph number
--- @field nh number
local PrefabNamed = {}
--- @param o? table
--- @return PrefabNamed
function PrefabNamed:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
--- @param logicType LogicType
--- @param method LogicBatchMethod
--- @return number?
function PrefabNamed:read_batch(logicType, method)
	return ic.batch_read_name(self.ph, self.nh, logicType, method)
end
--- @param slot number
--- @param slotType LogicSlotType
--- @param method LogicBatchMethod
--- @return number?
function PrefabNamed:read_batch_slot(slot, slotType, method)
	return ic.batch_read_slot_name(self.ph, self.nh, slot, slotType, method)
end
--- @param logicType LogicType
--- @param value number
function PrefabNamed:write_batch(logicType, value)
	ic.batch_write_name(self.ph, self.nh, logicType, value)
end

local PH_ACTIVE_VENT = -842048328
local PH_AIRCON = -2087593337
local PH_FILTRATION = -348054045
local PH_VOLPUMP = -321403609
local PH_PIPEANA = 435685051

--- @class WantGlobal
--- @field intake_on number
--- @field cooling_active number
WantGlobal = {}

--- @class WantPipeline
--- @field filter_on number
--- @field volpump_on number
WantPipeline = {}

--- @alias PipelineState function(pl: Pipeline, want_global: WantGlobal, want_pl: WantPipeline): PipelineState

--- @class Pipeline
--- @field filter PrefabNamed
--- @field vol_pump PrefabNamed
--- @field cold_pa PrefabNamed
--- @field target_cooling_pressure_kpa number
--- @field target_cold_pressure_kpa number
--- @field current_state PipelineState
Pipeline = {}

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

	INTAKE = PrefabNamed:new({ ph = PH_ACTIVE_VENT, nh = hash("AV Atmosphere Intake") }) -- TODO check name
	COOLER = PrefabNamed:new({ ph = PH_AIRCON, nh = hash("Cooling Tanks Air Conditioner") })

	--- @type Pipeline
	N2_PIPELINE = {
		filter = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("N2 Filtration") }),
		vol_pump = PrefabNamed:new({ ph = PH_VOLPUMP, nh = hash("N2 Volume Pump") }),
		cold_pa = PrefabNamed:new({ ph = PH_FILTRATION, nh = hash("Cold N2 Pipe Analyzer") }),
		target_cooling_pressure_kpa = 1000,
		target_cold_pressure_kpa = 5000,
		current_state = pl_state_wait,
	}
	--- @type Pipeline
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
	print("N2")
	run_pipeline(N2_PIPELINE, want_global)
	print("CO2")
	run_pipeline(CO2_PIPELINE, want_global)
	INTAKE:write_batch(LT.On, want_global.intake_on)
	-- Use Mode for aircon, so that it can house the chip (powering itself off
	-- would be a bad idea).
	COOLER:write_batch(LT.Mode, want_global.cooling_active)
	COOLER:write_batch(LT.Temperature, TARGET_TEMPERATURE_K)
end

--- @param pl Pipeline
--- @param want_global WantGlobal
function run_pipeline(pl, want_global)
	pl.cold_pa:write_batch(LT.On, 1)
	--- @type WantPipeline
	local want_pl = { filter_on = 0, volpump_on = 0 }
	-- TODO: Check filtration filters.
	-- TODO: Consider loading only during cooler weather.
	print(pl.current_state)
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
	print("pl_state_load")
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
	print("pl_state_cooling")
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
	print("pl_state_moving")
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
	print("pl_state_wait")
	local cold_tank_kpa = pl.cold_pa:read_batch(LT.Pressure, LBM.Maximum)
	if cold_tank_kpa < pl.target_cold_pressure_kpa then
		return pl_state_load(pl, want_global, want_pl)
	end
	-- TODO: Consider loading the cooling tank if its pressure is low.
	want_pl.filter_on = 0
	want_pl.volpump_on = 0
	return pl_state_wait
end

configuration()
