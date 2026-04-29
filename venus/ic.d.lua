--- @meta

--- @param s string
--- @return number
function hash(s) end

--- @param hash number
--- @return string?
function prefab_name(hash) end

--- @param s string
--- @return number
function pack_ascii6(s) end

--- @param n number
--- @return string
function unpack_ascii6(n) end

--- @param s string
--- @return string
function strip_color_tags(s) end

--- @param n number
--- @return number
function int(n) end

--- Bitwise AND
--- @param a number
--- @param b number
--- @return number
function bit_and(a, b) end
--- Bitwise OR
--- @param a number
--- @param b number
--- @return number
function bit_or(a, b) end
--- Bitwise XOR
--- @param a number
--- @param b number
--- @return number
function bit_xor(a, b) end
--- Bitwise NOR
--- @param a number
--- @param b number
--- @return number
function bit_nor(a, b) end
--- Bitwise NOT
--- @param a number
--- @return number
function bit_not(a) end
--- Shift left logical
--- @param a number
--- @param n number
--- @return number
function bit_sll(a, n) end
--- Shift right logical
--- @param a number
--- @param n number
--- @return number
function bit_srl(a, n) end
--- Shift right arithmetic
--- @param a number
--- @param n number
--- @return number
function bit_sra(a, n) end
--- Extract bit field
--- @param val number
--- @param pos number
--- @param len number
--- @return number
function bit_ext(val, pos, len) end
--- Insert bit field
--- @param dst number
--- @param src number
--- @param pos number
--- @param len number
--- @return number
function bit_ins(dst, src, pos, len) end

--- @package
--- @enum LogicType
LogicType = {}

--- @package
--- @enum LogicBatchMethod
LogicBatchMethod = {}

--- @package
--- @enum LogicSlotType
LogicSlotType = {}

--- @type { -- incomplete
---   batch_read: (fun(hash: number, logicType: LogicType, method: number, net?: number): number?),
---   batch_read_name: (fun(hash: number, nameHash: number, logicType: LogicType, method: number, net?: number): number?),
---   batch_read_slot: (fun(hash: number, slot: number, slotType: LogicSlotType, logicType: LogicType, method: number, net?: number): number?),
---   batch_read_slot_name: (fun(hash: number, nameHash: number, slot: number, slotType: LogicSlotType, method: number, net?: number): number?),
---   batch_write: (fun(hash: number, logicType: LogicType, value: number, net?: number)),
---   batch_write_name: (fun(hash: number, nameHash: number, logicType: LogicType, value: number, net?: number)),
---   batch_write_slot: (fun(hash: number, slot: number, slotType: LogicSlotType, value: number, net?: number)),
---   batch_write_slot_name: (fun(hash: number, nameHash: number, slot: number, slotType: LogicSlotType, value: number, net?: number)),
---   enums: {
---     LogicType: { -- incomplete
---       Mode: LogicType,
---       On: LogicType,
---       Pressure: LogicType,
---       PressureInput: LogicType,
---       PressureInternal: LogicType,
---       PressureOutput2: LogicType,
---       PressureOutput: LogicType,
---       RatioWater: LogicType,
---       Setting: LogicType,
---       Temperature: LogicType,
---       TemperatureOutput: LogicType,
---     },
---     LogicBatchMethod: { -- incomplete
---       Average: LogicBatchMethod,
---       Sum: LogicBatchMethod,
---       Minimum: LogicBatchMethod,
---       Maximum: LogicBatchMethod,
---     },
---     LogicSlotType: {
---       Occupied: LogicSlotType,
---     },
---   }}
ic = {}
