local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod
local LST = ic.enums.LogicSlotType

local PH_FERMENTER = 1103525139
local PH_EVAPORATOR = -1429782576
local PH_CONDENSOR = 1420719315
local PH_FILTRATION = -348054045
local PH_HEATER = -419758574

local NH_DEV = hash("Fermentation")

-- Max gas pressure limited to portable tank.
local MAX_GAS_PRESSURE = 15000
local MAX_LIQ_PRESSURE = 4500

-- Target temperature for evaporator.
local TARGET_TEMPERATURE_K = util.temp(25, "C", "K")

-- include:PrefabNamed.lua

local FERMENTER = PrefabNamed:new({ ph = PH_FERMENTER, nh = NH_DEV })
local EVAPORATOR = PrefabNamed:new({ ph = PH_EVAPORATOR, nh = NH_DEV })
local FILTRATION = PrefabNamed:new({ ph = PH_FILTRATION, nh = NH_DEV })
local CONDENSOR = PrefabNamed:new({ ph = PH_CONDENSOR, nh = NH_DEV })
local HEATER = PrefabNamed:new({ ph = PH_HEATER, nh = NH_DEV })

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	FERMENTER:write_batch(
		LT.On,
		bool_to_num(
			num_to_bool(FERMENTER:read_batch_slot(0, LST.Occupied, LBM.Maximum))
				and FERMENTER:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_LIQ_PRESSURE
		)
	)

	EVAPORATOR:write_batch(
		LT.On,
		bool_to_num(
			FERMENTER:read_batch(LT.PressureOutput, LBM.Maximum) > 100
				and EVAPORATOR:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_GAS_PRESSURE
		)
	)

	FILTRATION:write_batch(
		LT.On,
		bool_to_num(
			FILTRATION:read_batch(LT.PressureInput, LBM.Maximum) > 10
				and FILTRATION:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_GAS_PRESSURE
				and FILTRATION:read_batch(LT.PressureOutput2, LBM.Maximum) < MAX_GAS_PRESSURE
		)
	)

	CONDENSOR:write_batch(
		LT.On,
		bool_to_num(
			FILTRATION:read_batch(LT.PressureOutput, LBM.Maximum) > 10
				and CONDENSOR:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_LIQ_PRESSURE
		)
	)

	HEATER:write_batch(LT.On, bool_to_num(EVAPORATOR:read_batch(LT.Temperature, LBM.Average) < TARGET_TEMPERATURE_K))
end

--- @param n number?
--- @return boolean
function num_to_bool(n)
	return n ~= 0
end

--- @param b boolean
--- @return number
function bool_to_num(b)
	if b then
		return 1
	else
		return 0
	end
end
