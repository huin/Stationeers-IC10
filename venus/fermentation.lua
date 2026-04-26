local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod
local LST = ic.enums.LogicSlotType

local PH_FERMENTER = 1103525139
local PH_EVAPORATOR = -1429782576
local PH_CONDENSOR = 1420719315
local PH_FILTRATION = -348054045

local NH_DEV = hash("Fermentation")

local MAX_PRESSURE = 10000

--- @class BatchNamed
--- @field ph number
--- @field nh number
local PrefabNamed = {}
--- @param o? table
--- @return BatchNamed
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

local FERMENTER = PrefabNamed:new({ ph = PH_FERMENTER, nh = NH_DEV })
local EVAPORATOR = PrefabNamed:new({ ph = PH_EVAPORATOR, nh = NH_DEV })
local FILTRATION = PrefabNamed:new({ ph = PH_FILTRATION, nh = NH_DEV })
local CONDENSOR = PrefabNamed:new({ ph = PH_CONDENSOR, nh = NH_DEV })

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	FERMENTER:write_batch(
		LT.On,
		bool_to_num(
			num_to_bool(FERMENTER:read_batch_slot(0, LST.Occupied, LBM.Maximum))
				and FERMENTER:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
		)
	)

	EVAPORATOR:write_batch(
		LT.On,
		bool_to_num(
			EVAPORATOR:read_batch(LT.Pressure, LBM.Maximum) > 100
				and EVAPORATOR:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
		)
	)

	FILTRATION:write_batch(
		LT.On,
		bool_to_num(
			FILTRATION:read_batch(LT.Pressure, LBM.Maximum) > 100
				and FILTRATION:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
				and FILTRATION:read_batch(LT.PressureOutput2, LBM.Maximum) < MAX_PRESSURE
		)
	)

	CONDENSOR:write_batch(
		LT.On,
		bool_to_num(
			CONDENSOR:read_batch(LT.RatioWater, LBM.Maximum) > 0.1
				and CONDENSOR:read_batch(LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
		)
	)
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

-- local SRF_MAIN = "main"
-- local LABEL_STYLE = { font_size = 20, color = "#888888" }

-- local ui = ss.ui.surface(SRF_MAIN)
-- ss.ui.activate(SRF_MAIN)
-- local SIZE = ui:size()
-- local W, H = SIZE.w, SIZE.h
-- print(W)
-- print(H)

-- ui:clear()
-- local MAIN = ui:layout({
-- 	layout = "flex",
-- 	rect = { unit = "px", x = 0, y = 0, w = W, h = H },
-- 	direction = "column",
-- 	gap = 1,
-- 	children = {
-- 		-- Title bar.
-- 		{ id = "title", type = "label", props = { text = "Fermentation" }, style = LABEL_STYLE },
-- 		{ id = "sep", type = "divider", rect = { h = 2 } },
-- 		{
-- 			layout = "flex",
-- 			direction = "row",
-- 			rect = { h = 64 },
-- 			children = {
-- 				{ id = "ferm_out_label", type = "label", props = { text = "Fermenter" }, style = LABEL_STYLE },
-- 				{
-- 					id = "ferm_out_gauge",
-- 					type = "gauge",
-- 					rect = { w = 64, h = 64 },
-- 					props = { text = "Fermenter" },
-- 				},
-- 			},
-- 		},
-- 		{ id = "placeholder", type = "panel", flex = 1 },
-- 	},
-- })
--
-- ui:commit()
