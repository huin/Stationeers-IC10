local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod
local LST = ic.enums.LogicSlotType

local PH_FERMENTER = 1103525139
local PH_EVAPORATOR = -1429782576
local PH_CONDENSOR = 1420719315
local PH_FILTRATION = -348054045
local PH_AIRCON = -2087593337

local NAME_DEV = "Fermentation"

-- Max gas pressure limited to portable tank.
local MAX_GAS_PRESSURE = 15000
local MAX_LIQ_PRESSURE = 4500

-- Target temperature for evaporator.
local TARGET_TEMPERATURE_K = util.temp(25, "C", "K")

-- include:PrefabNamed.lua

local FERMENTER = PrefabNamed:create(PH_FERMENTER, NAME_DEV)
local EVAPORATOR = PrefabNamed:create(PH_EVAPORATOR, NAME_DEV)
local FILTRATION = PrefabNamed:create(PH_FILTRATION, NAME_DEV)
local CONDENSOR = PrefabNamed:create(PH_CONDENSOR, NAME_DEV)
local AIRCON = PrefabNamed:create(PH_AIRCON, NAME_DEV)

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

	AIRCON:write_batch(LT.Setting, TARGET_TEMPERATURE_K)
	AIRCON:write_batch(LT.On, 1)
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
