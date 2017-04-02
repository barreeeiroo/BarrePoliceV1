local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

local function list_plugins(only_enabled)
  local text = ''
  for k, v in pairs(u.plugins_names()) do
    --  ✔ enabled, ❌ disabled
    local status = '❌'
    -- Check if is enabled
    for k2, v2 in pairs(config.plugins) do
      if v == v2..'.lua' then
        status = '✅'
      end
    end
    if not only_enabled or status == '✅' then
      -- get the name
      v = string.match (v, "(.*)%.lua")
      if string.match(v, "_") then
        v = v:gsub("_", "\\_")
      end
      text = text .. status..' - '..v..'\n'
    end
  end
  return "*List of avliable plugins:*\n\n"..text
end

function plugin.onTextMessage(msg, blocks)
  if u.is_superadmin(msg.from.id) then
    if not blocks[2] then
      api.sendReply(msg, "*Specify an option* _(_`list`_,_ `enable`_,_ `disable`_)_", true, nil, true)
    else
  	  if blocks[2] == "list" then
        api.sendReply(msg, list_plugins(only_enabled), true, nil, true)
      --[[elseif blocks[2] == "enable" then
        api.sendReply(msg, "*Not working* RN", true, nil, true)
      elseif blocks[2] == "disable" then
        api.sendReply(msg, "*Not working* RN", true, nil, true)]]
      end
    end
 else
   api.sendReply(msg, "*You are not a superadmin!*", true, nil, true)
 end
end

plugin.triggers = {
	onTextMessage = {
    --[[config.cmd..'(plugins)s? (disable) (.+)$',
    config.cmd..'(plugins)s? (disable)$',
    config.cmd..'(plugins)s? (enable) (.+)$',
    config.cmd..'(plugins)s? (enable)$',
		config.cmd..'(plugins)s? (list) (.+)$',]]
		config.cmd..'(plugins)s? (list)$',
		config.cmd..'(plugins)s?$'
	}
}

return plugin
