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

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function plugin.onTextMessage(msg, blocks)
  if msg.chat.type == 'private' then
  	api.sendChatAction(msg.chat.id, "typing")
    local base_url = "http://barreeeiroo.ga/BarrePolice/cleverbot/"
    local key = config.cleverbot_api_key
    local input = urlencode(blocks[1])

    local url = base_url .. "?key=" .. key .. "&input=" .. input

    local output, res = HTTP.request(url)

    if not output or res ~= 200 or output:len() == 0 then
        url = base_url .. "?input=" .. request_text .. "&key=" .. api_key
        output, res = HTTP.request(url)
    end

    api.sendReply(msg, "`"..output.."`", true, nil, true)
  else
    if string.starts(blocks[1],"bot") or string.starts(blocks[1],"Bot") then
      api.sendChatAction(msg.chat.id, "typing")
      local base_url = "http://barreeeiroo.ga/BarrePolice/cleverbot/"
      local key = config.cleverbot_api_key
      local input = urlencode(blocks[2]:gsub(",%s+", ""))

      local url = base_url .. "?key=" .. key .. "&input=" .. input

      local output, res = HTTP.request(url)

      if not output or res ~= 200 or output:len() == 0 then
          url = base_url .. "?input=" .. request_text .. "&key=" .. api_key
          output, res = HTTP.request(url)
      end

      api.sendReply(msg, "`"..output.."`", true, nil, true)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
    '([B/b]ot),? (.*)$',
		'(.*)$'
	}
}

return plugin
