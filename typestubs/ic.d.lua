--- @meta

--- @alias PrefabHash number
--- @alias NameHash number
--- @alias SlotIndex number
--- @alias DeviceIndex number
--- @alias ReferenceId number
--- @alias NetworkIndex number

--- @alias FindMode "auto" | "exact" | "glob" | "regex"

--- @alias DeviceListEntry {
---   ref_id: ReferenceId, -- Device ReferenceId (for ic.read_id / ic.write_id)
---   prefab_hash: PrefabHash, -- Prefab hash (for ic.batch_read / ic.batch_write)
---   name_hash: NameHash, -- Name hash
---   display_name: string, -- Current display name
--- }
---
--- @alias HostInfo {
---   name: string, -- Display name of the host device
---   ref_id: ReferenceId, -- Host device ReferenceId
---   prefab_hash: PrefabHash, -- Host device prefab hash
---   type: string, -- Host category (see below)
---   wearer: string?, -- Player name (suits only; nil for all other hosts)
--- }

--- @param s string
--- @return NameHash
function hash(s) end

--- @param hash PrefabHash
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

--- Get device display name
--- @param dev DeviceIndex
--- @param net? NetworkIndex
--- @return string?
function device_name(dev, net) end
---	Set device label (also ic.device_label)
--- @param dev DeviceIndex
--- @param name string
function device_label(dev, name) end
--- List all network devices
--- @param net? NetworkIndex
--- @return [DeviceListEntry]
function device_list(net) end
--- Resolve a nameHash by scanning visible devices
--- @param devHash number
--- @param nameHash NameHash
--- @param net? NetworkIndex
--- @return string|nil
function namehash_name(devHash, nameHash, net) end
--- Set the IC housing error state (1=error, 0=clear)
--- @param state number
function raise_error(state) end
--- Clear the IC housing error state
function clear_error() end
--- Halt and catch fire (stops the chip)
function hcf() end

--- @alias LogicType number

--- @alias LogicBatchMethod number

--- @alias LogicSlotType number

ic = {}

ic.enums = {}
--- @type { -- incomplete
---   Mode: LogicType,
---   On: LogicType,
---   Pressure: LogicType,
---   PressureInput: LogicType,
---   PressureInternal: LogicType,
---   PressureOutput2: LogicType,
---   PressureOutput: LogicType,
---   RatioCarbonDioxide: LogicType,
---   RatioNitrogen: LogicType,
---   RatioOxygen: LogicType,
---   RatioWater: LogicType,
---   Setting: LogicType,
---   Temperature: LogicType,
---   TemperatureOutput: LogicType,
--- }
ic.enums.LogicType = {}
--- @type {
---   Average: LogicBatchMethod,
---   Sum: LogicBatchMethod,
---   Minimum: LogicBatchMethod,
---   Maximum: LogicBatchMethod,
--- }
ic.enums.LogicBatchMethod = {}
--- @type { -- incomplete
---   Occupied: LogicSlotType,
--- }
ic.enums.LogicSlotType = {}

--- @param hash PrefabHash
--- @param logicType LogicType
--- @param method number
--- @param net? NetworkIndex
--- @return number?
function ic.batch_read(hash, logicType, method, net) end
--- @param hash PrefabHash
--- @param nameHash NameHash
--- @param logicType LogicType
--- @param method number
--- @param net? NetworkIndex
--- @return number?
function ic.batch_read_name(hash, nameHash, logicType, method, net) end
---
--- @param hash PrefabHash
--- @param slot SlotIndex
--- @param logicType LogicType
--- @param method number
--- @param net? NetworkIndex
--- @return number?
function ic.batch_read_slot(hash, slot, slotType, logicType, method, net) end
---
--- @param hash PrefabHash
--- @param nameHash NameHash
--- @param slot SlotIndex
--- @param slotType LogicSlotType
--- @param method number
--- @param net? NetworkIndex
--- @return number?
function ic.batch_read_slot_name(hash, nameHash, slot, slotType, method, net) end
---
--- @param hash PrefabHash
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function ic.batch_write(hash, logicType, value, net) end
---
--- @param hash PrefabHash
--- @param nameHash NameHash
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function ic.batch_write_name(hash, nameHash, logicType, value, net) end
---
--- @param hash PrefabHash
--- @param slot SlotIndex
--- @param slotType LogicSlotType
--- @param value number
--- @param net? NetworkIndex
function ic.batch_write_slot(hash, slot, slotType, value, net) end
---
--- @param hash PrefabHash
--- @param nameHash NameHash
--- @param slot SlotIndex
--- @param slotType LogicSlotType
--- @param value number
--- @param net? NetworkIndex
function ic.batch_write_slot_name(hash, nameHash, slot, slotType, value, net) end
--- Read logic value
--- @param dev DeviceIndex
--- @param logicType LogicType
--- @param net? NetworkIndex
--- @return number?
function ic.read(dev, logicType, net) end
--- Write logic value
--- @param dev DeviceIndex
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function ic.write(dev, logicType, value, net) end
--- Read by ReferenceId
--- @param id ReferenceId
--- @param logicType LogicType
--- @param net? NetworkIndex
--- @return number?
function ic.read_id(id, logicType, net) end
--- Write by ReferenceId
--- @param id ReferenceId
--- @param logicType LogicType
--- @param value number
--- @param net? NetworkIndex
function ic.write_id(id, logicType, value, net) end
--- Find by display name
--- @param name string
--- @param mode FindMode
--- @param net? NetworkIndex a single number is net only
--- @return ReferenceId?
function ic.find(name, mode, net) end
--- Find all matches
--- @param name string
--- @param mode FindMode
--- @param net? NetworkIndex
--- @return [ReferenceId]
function ic.find_all(name, mode, net) end
--- Host device metadata
--- @return HostInfo
function ic.host_info() end

-- HTTP:

--- @alias RequestId number

-- HTTP Request functions:

--- id	Start a GET request
--- @param url string
--- @param headers? table<string, string>
--- @param timeout? number
--- @return RequestId
function ic.http.get(url, headers, timeout) end
--- id	Start a POST request
--- @param url string
--- @param body string
--- @param contentType? string
--- @param headers? table<string, string>
--- @param timeout? number
--- @return RequestId
function ic.http.post(url, body, contentType, headers, timeout) end
--- id	Start a PUT request
--- @param url string
--- @param body string
--- @param contentType? string
--- @param headers? table<string, string>
--- @param timeout? number
--- @return RequestId
function ic.http.put(url, body, contentType, headers, timeout) end
--- id	Start a DELETE request
--- @param url string
--- @param headers? table<string, string>
--- @param timeout? number
--- @return RequestId
function ic.http.delete(url, headers, timeout) end
--- id	Start a PATCH request
--- @param url string
--- @param body string
--- @param contentType? string
--- @param headers? table<string, string>
--- @param timeout? number
--- @return RequestId
function ic.http.patch(url, body, contentType, headers, timeout) end
--- err	Retrieve the next completed response
--- id, ok, status, body
--- @return [RequestId, boolean, number, string]
function ic.http.poll() end

-- HTTP Helper functions:

--- Percent-encode a value
--- @param str string
--- @return string
function ic.http.url_encode(str) end
--- Decode a percent-encoded value
--- @param str string
--- @return string
function ic.http.url_decode(str) end
--- Build a query string from a Lua table
--- @param table table<string, string|number|[string|number]>
--- @return string
function ic.http.build_query(table) end
--- Build a full URL with query parameters
--- @param base string
--- @param params table<string, string|number|[string|number]>
--- @return string
function ic.http.build_url(base, params) end

-- Events
--- Register event handler (function or string name)
--- @param name string
--- @param handler string|(fun(any))
function ic.events.on(name, handler) end
--- Unregister event handler
--- @param name string
function ic.events.off(name) end
