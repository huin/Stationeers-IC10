--- @class PrefabNamed
--- @field ph number
--- @field nh number
PrefabNamed = {}
--- @param o? table
--- @return PrefabNamed
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
