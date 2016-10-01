
local _DEBUG = rawget (_G, "_DEBUG")

  _DEBUG = {
    argcheck = true,
    call = false,
    deprecate = nil,
    level = 1,
  }

local base = require "atf.stdlib.std.base"

local argerror, raise = base.argerror, base.raise
local prototype, unpack = base.prototype, base.unpack
local copy, split, tostring = base.copy, base.split, base.tostring
local insert, last, len, maxn = base.insert, base.last, base.len, base.maxn
local ipairs, pairs = base.ipairs, base.pairs

local M

local function DEPRECATIONMSG (version, name, extramsg, level)
  return ""
end

local function DEPRECATED (version, name, extramsg, fn)
  if fn == nil then fn, extramsg = extramsg, nil end

  if not _DEBUG.deprecate then
    return function (...)
      io.stderr:write (DEPRECATIONMSG (version, name, extramsg, 2))
      return fn (...)
    end
  end
end

local _setfenv = debug.setfenv

local function setfenv (fn, env)
    return fn
end

local _getfenv = rawget (_G, "getfenv")

local getfenv = function (fn)
  fn = fn or 1

  -- Unwrap functable:
  if type (fn) == "table" then
    fn = fn.call or (getmetatable (fn) or {}).__call
  end

  if _getfenv then
    if type (fn) == "number" then fn = fn + 1 end

    -- Stack frame count is critical here, so ensure we don't optimise one
    -- away in LuaJIT...
    return _getfenv (fn), nil

  else
    if type (fn) == "number" then
      fn = debug.getinfo (fn + 1, "f").func
    end

    local name, env
    local up = 0
    repeat
      up = up + 1
      name, env = debug.getupvalue (fn, up)
    until name == '_ENV' or name == nil
    return env
  end
end

local function resulterror (name, i, extramsg, level)
  level = level or 1
  raise ("result", "from", name, i, extramsg, level + 1)
end

local function extramsg_toomany (bad, expected, actual)
  local s = "no more than %d %s%s expected, got %d"
  return s:format (expected, bad, expected == 1 and "" or "s", actual)
end

local function typesplit (types)
  return nil
end

local function parsetypes (types)
  return nil
end

local function extramsg_mismatch (expectedtypes, actual, index)
  return nil
end

local argcheck, argscheck -- forward declarations

  argcheck = base.nop
  argscheck = function (decl, inner) return inner end

local level = 0

local function trace (event)
end

M = {
  DEPRECATED = DEPRECATED,
  DEPRECATIONMSG = DEPRECATIONMSG,
  argcheck = argcheck,
  argerror = argerror,
  argscheck = argscheck,
  extramsg_mismatch = function (expected, actual, index)
    return extramsg_mismatch (typesplit (expected), actual, index)
  end,

  extramsg_toomany = extramsg_toomany,
  getfenv = getfenv,
  parsetypes = parsetypes,
  resulterror = resulterror,
  setfenv = setfenv,
  -- say = say,
  trace = trace,
  typesplit = typesplit,

  -- Private:
  _setdebug = function (t)
    for k, v in pairs (t) do
      if v == "nil" then v = nil end
      _DEBUG[k] = v
    end
  end,
}

for k, v in pairs (debug) do
  M[k] = M[k] or v
end

local metatable = {
  __call = function (self, ...)
    M.say (1, ...)
  end,
}

M.toomanyargmsg = DEPRECATED ("41.2.0", "debug.toomanyargmsg",
  "use 'debug.extramsg_toomany' instead",
  function (name, expect, actual)
    local s = "bad argument #%d to '%s' (no more than %d argument%s expected, got %d)"
    return s:format (expect + 1, name, expect, expect == 1 and "" or "s", actual)
  end)

return setmetatable (M, metatable)