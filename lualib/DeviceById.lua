--- @class DeviceById
--- @field id ReferenceId
DeviceById = {}

--- @param id ReferenceId
--- @return DeviceById
function DeviceById:create(id)
	local o = {
		id = id,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end
---
