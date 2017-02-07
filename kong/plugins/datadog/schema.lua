local find = string.find
local pl_utils = require "pl.utils"
local metrics = {
  "request_count",
  "latency",
  "request_size",
  "status_count",
  "response_size",
  "unique_users",
  "request_per_user",
  "upstream_latency",
  "kong_latency",
  "status_count_per_user"
}

local stat_types = {
  "gauge",
  "timer",
  "counter",
  "histogram",
  "meter",
  "set"
}


local default_metrics = {
  {
    name = "request_count",
    stat_type = "counter",
    sample_rate = 1
  },
  {
    name = "latency",
    stat_type = "timer"
  },
  {
    name = "request_size",
    stat_type = "timer"
  },
  {
    name = "status_count",
    stat_type = "counter",
    sample_rate = 1
  },
  {
    name = "response_size",
    stat_type = "timer"
  },
  {
    name = "unique_users",
    stat_type = "set",
    consumer_identifier = "custom_id"
  },
  {
    name = "request_per_user",
    stat_type = "counter",
    sample_rate = 1,
    consumer_identifier = "custom_id"
  },
  {
    name = "upstream_latency",
    stat_type = "timer"
  },
  {
    name = "kong_latency",
    stat_type = "timer"
  },
  {
    name = "status_count_per_user",
    stat_type = "counter",
    sample_rate = 1,
    consumer_identifier = "custom_id"
  }
}

local consumer_identifiers = {
  "consumer_id",
  "custom_id",
  "username"
}

local function check_value(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function check_schema(value)
  for _, entry in ipairs(value) do
    local name_ok = check_value(metrics, entry.name)
    local type_ok = check_value(stat_types, entry.stat_type)
    
    if entry.name == nil or entry.stat_type == nil then
      return false, "name and stat_type must be defined for all stats"
    end
    if not name_ok then
      return false, "unrecognized metric name: "..entry.name
    end
    if not type_ok then
      return false, "unrecognized stat_type: "..entry.stat_type
    end
    if entry.name == "unique_users" and entry.stat_type ~= "set" then
      return false, "unique_users metric only works with stat_type 'set'"
    end
    if (entry.stat_type == "counter" or entry.stat_type == "gauge") and ((entry.sample_rate == nil) or (entry.sample_rate ~= nil and type(entry.sample_rate) ~= "number") or (entry.sample_rate ~= nil and entry.sample_rate < 1)) then
      return false, "sample rate must be defined for counters and gauges."
    end
    if (entry.name == "status_count_per_user" or entry.name == "request_per_user" or entry.name == "unique_users") and entry.consumer_identifier == nil then
      return false, "consumer_identifier must be defined for metric "..entry.name
    end
    if (entry.name == "status_count_per_user" or entry.name == "request_per_user" or entry.name == "unique_users") and entry.consumer_identifier ~= nil then
      local identifier_ok = check_value(consumer_identifiers, entry.consumer_identifier)
      if not identifier_ok then
        return false, "invalid consumer_identifier for metric "..entry.name..". Choices are consumer_id, custom_id, and username"
      end
    end
    if (entry.name == "status_count" or entry.name == "status_count_per_user" or entry.name == "request_per_user") and entry.stat_type ~= "counter" then
      return false, entry.name.." metric only works with stat_type 'counter'"
    end
  end
  return true
end

-- entries must have colons to set the key and value apart
local function check_for_value(value)
  for i, entry in ipairs(value) do
    local ok = find(entry, ":")
    if ok then 
      local _,next = pl_utils.splitv(entry, ':')
      if not next or #next == 0 then
        return false, "key '"..entry.."' has no value, "
      end
    end
  end
  return true
end

return {
  fields = {
    host = {required = true, type = "string", default = "localhost"},
    port = {required = true, type = "number", default = 8125},
    metrics = {required = true, type = "array", enum = metrics, default = default_metrics, check_schema},
    tags = {
      type = "table",
      schema = {
        fields = {
          request_count = {type = "array", default = {}, func = check_for_value},
          latency = {type = "array", default = {}, func = check_for_value},
          request_size = {type = "array", default = {}, func = check_for_value},
          status_count = {type = "array", default = {}, func = check_for_value},
          response_size = {type = "array", default = {}, func = check_for_value},
          unique_users = {type = "array", default = {}, func = check_for_value},
          request_per_user = {type = "array", default = {}, func = check_for_value},
          upstream_latency = {type = "array", default = {}, func = check_for_value}
        }
      }
    },
    timeout = {type = "number", default = 10000}
  }
}
