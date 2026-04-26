local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod
local LST = ic.enums.LogicSlotType

local PH_FERMENTER = 1103525139
local PH_EVAPORATOR = -1429782576
local PH_CONDENSOR = 1420719315
local PH_FILTRATION = -348054045

local NH_DEV = hash("Fermentation")

local MAX_PRESSURE = 10000

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	local ph
	local nh

	nh = NH_DEV

	ph = PH_FERMENTER
	ic.batch_write_name(
		ph,
		nh,
		LT.On,
		bool_to_num(
			num_to_bool(ic.batch_read_slot_name(ph, nh, 0, LST.Occupied, LBM.Maximum))
				and ic.batch_read_name(ph, nh, LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
		)
	)

	ph = PH_EVAPORATOR
	ic.batch_write_name(
		ph,
		nh,
		LT.On,
		bool_to_num(
			ic.batch_read_name(ph, nh, LT.Pressure, LBM.Maximum) > 100
				and ic.batch_read_name(ph, nh, LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
		)
	)

	ph = PH_FILTRATION
	ic.batch_write_name(
		ph,
		nh,
		LT.On,
		bool_to_num(
			ic.batch_read_name(ph, nh, LT.Pressure, LBM.Maximum) > 100
				and ic.batch_read_name(ph, nh, LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
				and ic.batch_read_name(ph, nh, LT.PressureOutput2, LBM.Maximum) < MAX_PRESSURE
		)
	)

	ph = PH_CONDENSOR
	ic.batch_write_name(
		ph,
		nh,
		LT.On,
		bool_to_num(
			ic.batch_read_name(ph, nh, LT.RatioWater, LBM.Maximum) > 0.1
				and ic.batch_read_name(ph, nh, LT.PressureOutput, LBM.Maximum) < MAX_PRESSURE
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
