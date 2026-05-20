--- @class DeviceByIndex
--- @field dev ReferenceId
DeviceByIndex = {}

--- @param dev DeviceIndex
--- @return DeviceByIndex
function DeviceByIndex:create(dev)
	local o = { dev = dev }
	setmetatable(o, self)
	self.__index = self
	return o
end
--- @param logicType LogicType
--- @param net? NetworkIndex
--- @return number?
function DeviceByIndex:read(logicType, net)
	return ic.read(self.dev, logicType, net)
end
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function DeviceByIndex:write(logicType, value, net)
	ic.write(self.dev, logicType, value, net)
end
--- Polymorphically implementing PrefabNamed:read_batch.
--- @param logicType LogicType
--- @param method LogicBatchMethod
--- @return number?
function DeviceByIndex:read_batch(logicType, method)
	_ = method
	return ic.read(self.dev, logicType)
end
--- Polymorphically implementing PrefabNamed:write_batch.
--- @param logicType LogicType
--- @param value number
function DeviceByIndex:write_batch(logicType, value)
	ic.write(self.dev, logicType, value)
end
