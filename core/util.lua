local EM = EquipMate
EM.Util = {}
local U = EM.Util

function U.Trim(value)
  if not value then return "" end
  return string.gsub(string.gsub(value, "^%s+", ""), "%s+$", "")
end

function U.Copy(value, seen)
  if type(value) ~= "table" then return value end
  if not seen then seen = {} end
  if seen[value] then return seen[value] end
  local result = {}
  seen[value] = result
  local k, v
  for k, v in pairs(value) do result[U.Copy(k, seen)] = U.Copy(v, seen) end
  return result
end

function U.SplitFirst(text)
  local _, _, command, rest = string.find(U.Trim(text), "^(%S+)%s*(.-)$")
  return string.lower(command or ""), U.Trim(rest or "")
end

function U.LocationKey(location)
  if not location then return nil end
  if location.kind == "equipment" then return "e:" .. location.slot end
  return "b:" .. location.bag .. ":" .. location.slot
end

function U.TableContains(list, value)
  local i
  for i = 1, table.getn(list or {}) do if list[i] == value then return true end end
  return false
end
