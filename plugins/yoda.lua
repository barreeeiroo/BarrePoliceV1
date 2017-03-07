local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local HTTP = require('socket.http')
local URL = require('socket.url')

local plugin = {}

function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'yoda' then
    local base_url = "http://scripts.thunkable.ga/BarrePolice/yoda/"

    if not blocks[2] then
      local output, res = HTTP.request(base_url)
      api.sendReply(msg, output, true, reply_markup)
    else
      local input = urlencode(blocks[2])
      local url = base_url .. "?input=" .. input
      local output, res = HTTP.request(url)
      api.sendReply(msg, output, true, reply_markup)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(yoda) (.*)$',
    config.cmd..'(yoda)$'
	}
}

return plugin
