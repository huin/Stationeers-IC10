--- @class DeviceByRef
--- @field id ReferenceId
DeviceByRef = {}

--- @param id ReferenceId
--- @return DeviceByRef
function DeviceByRef:create(id)
	local o = { id = id }
	setmetatable(o, self)
	self.__index = self
	return o
end
--- @param name string
--- @param mode FindMode
--- @param net? NetworkIndex a single number is net only
--- @return DeviceByRef?
function DeviceByRef:find(name, mode, net)
	local id = ic.find(name, mode, net)
	if id == nil then
		return nil
	end
	return DeviceByRef:create(id)
end
--- @param name string
--- @param mode FindMode
--- @param net? NetworkIndex a single number is net only
--- @return [DeviceByRef]
function DeviceByRef:find_all(name, mode, net)
	local ids = ic.find_all(name, mode, net)
	local devices = {}
	for _, id in ipairs(ids) do
		table.insert(devices, DeviceByRef:create(id))
	end
	return devices
end
--- @param logicType LogicType
--- @param net? NetworkIndex
--- @return number?
function DeviceByRef:read(logicType, net)
	return ic.read_id(self.id, logicType, net)
end
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function DeviceByRef:write(logicType, value, net)
	ic.write_id(self.id, logicType, value, net)
end
