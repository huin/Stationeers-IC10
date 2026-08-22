-- include:PrefabNamed.lua

local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod
local LST = ic.enums.LogicSlotType

-- PressureOutput - filtered output
-- PressureOutput2 - unfiltered output
-- Slot 0 and 1 for the filters, Dmage for their integrity

local MAX_OUTPUT_PRESSURE_KPA = 40000
local PH_FILTRATION = -348054045
local PH_AIRCON = -2087593337
local PH_GAS_SENSOR = -1252983604
local PH_VOLPUMP = -321403609
local PH_DIGVALVE = -1280984102

--- ac_bypass: a digital valve to bypass the AC when its input reaches < 1K
--- from temperature_k (and therefore would stop running).
--- @alias Loop {
---   name: string,
---   filtrations: [PrefabNamed],
---   ac: PrefabNamed,
---   ac_bypass: PrefabNamed,
---   temperature_k: number,
--- }

--- @type [Loop]
local LOOPS = {
	{
		name = "Hab",
		filtrations = {
			PrefabNamed:create(PH_FILTRATION, "Hab CO2 Filtration"),
			PrefabNamed:create(PH_FILTRATION, "Hab Toxin Filtration"),
		},
		ac = PrefabNamed:create(PH_AIRCON, "Hab A/C"),
		ac_bypass = PrefabNamed:create(PH_DIGVALVE, "Hab A/C Bypass"),
		temperature_k = util.temp(5, "C", "K"),
	},
	{
		name = "Greenhouse",
		filtrations = {
			PrefabNamed:create(PH_FILTRATION, "GH O2 Filtration"),
			PrefabNamed:create(PH_FILTRATION, "GH Toxin Filtration"),
		},
		ac = PrefabNamed:create(PH_AIRCON, "GH A/C"),
		ac_bypass = PrefabNamed:create(PH_DIGVALVE, "GH A/C Bypass"),
		temperature_k = util.temp(22, "C", "K"),
	},
}

--- TODO: Add a removal filter.
--- @alias AtmoFeed {
---   name: string,
---   sensor: PrefabNamed,
---   feedPump: PrefabNamed,
---   logicRatio: LogicType,
---   lowPPkpa: number,
---   highPPkpa: number,
--- }

HAB_GAS_SENSOR = PrefabNamed:create(PH_GAS_SENSOR, "Sensor Mainhab")
GH_GAS_SENSOR = PrefabNamed:create(PH_GAS_SENSOR, "Sensor Greenhouse")

--- @type [AtmoFeed]
local FEEDS = {
	{
		name = "Hab O2",
		sensor = HAB_GAS_SENSOR,
		feedPump = PrefabNamed:create(PH_VOLPUMP, "Hab O2 Feed"),
		logicRatio = LT.RatioOxygen,
		lowPPkpa = 25,
		highPPkpa = 28,
	},
	{
		name = "GH CO2",
		sensor = GH_GAS_SENSOR,
		feedPump = PrefabNamed:create(PH_VOLPUMP, "GH CO2 Feed"),
		logicRatio = LT.RatioCarbonDioxide,
		lowPPkpa = 30,
		highPPkpa = 34,
	},
	{
		name = "GH N2",
		sensor = GH_GAS_SENSOR,
		feedPump = PrefabNamed:create(PH_VOLPUMP, "GH N2 Feed"),
		logicRatio = LT.RatioNitrogen,
		lowPPkpa = 20,
		highPPkpa = 24,
	},
}

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	for _, loop in ipairs(LOOPS) do
		handle_loop(loop)
	end

	for _, feed in ipairs(FEEDS) do
		handle_feed(feed)
	end
end

--- @param loop Loop
function handle_loop(loop)
	for _, filtration in ipairs(loop.filtrations) do
		handle_filtration(loop, filtration)
	end
	handle_ac(loop, loop.ac)
end

--- @param loop Loop
--- @param filtration PrefabNamed
function handle_filtration(loop, filtration)
	local p1 = filtration:read_batch(LT.PressureOutput, LBM.Maximum)
	local p2 = filtration:read_batch(LT.PressureOutput2, LBM.Maximum)
	if p1 == nil or p2 == nil then
		print(string.format("Loop %s: filtration %s missing or not a filtration.", loop.name, filtration.nh))
		return
	end
	local max_output_pressure = math.max(p1, p2)
	local do_run = max_output_pressure < MAX_OUTPUT_PRESSURE_KPA
	filtration:write_batch(LT.Mode, bool_to_num(do_run))
	filtration:write_batch(LT.On, bool_to_num(do_run))

	-- TODO: Check for alert conditions on filters.
	-- for i = 0, 1 do
	-- 	local is_occupied = filtration:read_batch_slot(0, LST.Occupied, LBM.Maximum)
	-- 	if is_occupied ~= nil and is_occupied ~= 0 then
	-- 		local damage = filtration:read_batch_slot(0, LST.Occupied, LBM.Maximum)
	-- 		-- check for redundant filter types, see if we're about to run out of a filter type
	-- 		if damage < 0.2 then
	-- 		end
	-- 	end
	-- end
end

--- @param loop Loop
--- @param ac PrefabNamed
function handle_ac(loop, ac)
	local in_temp = ac:read_batch(LT.TemperatureInput, LBM.Average)
	local disable_ac = math.abs(in_temp - loop.temperature_k) < 1
	loop.ac_bypass:write_batch(LT.On, bool_to_num(disable_ac))
	if disable_ac then
		loop.ac:write_batch(LT.On, 0)
		return
	end

	local p1 = ac:read_batch(LT.PressureOutput, LBM.Maximum)
	if p1 == nil then
		print(string.format("Loop %s: A/C %s missing or not an A/C.", loop.name, ac.nh))
		return
	end
	local do_run = p1 < MAX_OUTPUT_PRESSURE_KPA
	ac:write_batch(LT.Mode, bool_to_num(do_run))
	ac:write_batch(LT.On, bool_to_num(do_run))
	ac:write_batch(LT.Setting, loop.temperature_k)
end

--- @param feed AtmoFeed
function handle_feed(feed)
	local currPPkpa = (
		feed.sensor:read_batch(LT.Pressure, LBM.Average) * feed.sensor:read_batch(feed.logicRatio, LBM.Average)
	)
	feed.feedPump:write_batch(LT.Setting, 10)
	if currPPkpa >= feed.lowPPkpa and currPPkpa <= feed.highPPkpa then
		-- In range; make no change.
		return
	end
	-- Out of range; set to feed gas until highPPkpa is met.
	feed.feedPump:write_batch(LT.On, bool_to_num(currPPkpa < feed.highPPkpa))
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
