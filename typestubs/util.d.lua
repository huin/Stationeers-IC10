--- @meta

--- @alias TemperatureUnit "K"|"C"|"F"

util = {}

-- Temperature:

--- @param value number
--- @param from? TemperatureUnit
--- @param to? TemperatureUnit
--- @return number
function util.temp(value, from, to) end

-- Time:
--- Seconds since world start
--- @return number
function util.game_time() end
--- Days passed in world
--- @return number
function util.days_past() end
--- Fraction of day (0..1)
--- @return number
function util.time_of_day() end
--- Formatted clock time
---
--- Token   | Description
--- ------- | -----------
--- HH      | 24-hour hour
--- hh      | 12-hour hour
--- MM / mm | Minutes
--- ss      | Seconds
--- A / a   | AM/PM
--- @param pattern? string
--- @return string
function util.clock_time(pattern) end

-- JSON:

---
--- Encode Lua value to JSON string
--- @param value table|string|number|boolean|nil
--- @return string
function util.json.encode(value) end
--- Decode JSON string to Lua value
--- @param str string
--- @return table|string|number|boolean|nil
function util.json.decode(str) end
