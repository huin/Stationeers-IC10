local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

local PH_GAS_SENSOR = -1252983604
local PH_VOLPUMP = -321403609

-- include:PrefabNamed.lua

--- @alias MinPartialPressure {
---   name: string,
---   ratio_logic_type: LogicType,
---   feed_pump: PrefabNamed,
---   min_pressure: number,
---   target_pressure: number,
--- }

--- @alias Room {
---   name: string,
---   gas_sensor: PrefabNamed,
---   max_pressure: number,
---   partial_pressures: [MinPartialPressure],
--- }

--- @type [Room]
local ROOMS = {
	{
		name = "Habitat",
		gas_sensor = PrefabNamed:create(PH_GAS_SENSOR, "Hab Gas Sensor"),
		max_pressure = 100,
		partial_pressures = {
			{
				name = "O2",
				ratio_logic_type = LT.RatioOxygen,
				feed_pump = PrefabNamed:create(PH_VOLPUMP, "Hab O2 Pump"),
				min_pressure = 22,
				target_pressure = 25,
			},
			{
				name = "N2",
				ratio_logic_type = LT.RatioNitrogen,
				feed_pump = PrefabNamed:create(PH_VOLPUMP, "Hab N2 Pump"),
				min_pressure = 30,
				target_pressure = 32,
			},
		},
	},
	{
		name = "Greenhouse",
		gas_sensor = PrefabNamed:create(PH_GAS_SENSOR, "GH Gas Sensor"),
		max_pressure = 100,
		partial_pressures = {
			{
				name = "CO2",
				ratio_logic_type = LT.RatioOxygen,
				feed_pump = PrefabNamed:create(PH_VOLPUMP, "GH CO2 Pump"),
				min_pressure = 25,
				target_pressure = 27,
			},
			{
				name = "N2",
				ratio_logic_type = LT.RatioNitrogen,
				feed_pump = PrefabNamed:create(PH_VOLPUMP, "GH N2 Pump"),
				min_pressure = 25,
				target_pressure = 27,
			},
		},
	},
}

--- @param dt number
--- @diagnostic disable-next-line:unused-local
function tick(dt)
	for _, room in ipairs(ROOMS) do
		control_room(room)
	end
end

--- Controls gas input flows to the room.
--- @param room Room
function control_room(room)
	local total_pressure = room.gas_sensor:read_batch(LT.Pressure, LBM.Average)
	if total_pressure > room.max_pressure then
		shutoff_all_feed_pumps(room)
		return
	end

	for _, pp in room.partial_pressures do
		local ratio = room.gas_sensor:read_batch(pp.ratio_logic_type, LBM.Average)
		local partial_pressure = total_pressure * ratio

		if partial_pressure < pp.min_pressure then
			pp.feed_pump:write_batch(LT.On, 1)
		elseif partial_pressure > pp.target_pressure then
			pp.feed_pump:write_batch(LT.On, 0)
		end
		-- The implied unstated `else` in the above leaves the feed pump doing what
		-- it's already doing if we're between the min and target pressure
		-- (high/low watermark behaviour).
	end
end

--- @param room Room
function shutoff_all_feed_pumps(room)
	for _, pp in room.partial_pressures do
		pp.feed_pump:write_batch(LT.On, 0)
	end
end
