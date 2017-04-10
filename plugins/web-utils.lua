local helpers = require "OAuth.helpers"
local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local http = require('socket.http')
local https = require('ssl.https')
local URL = require('socket.url')

local plugin = {}

local base = 'https://screenshotmachine.com/'
local url = base .. 'processor.php'

function plugin.get_webshot_url(param)
   local response_body = {}
   local request_constructor = {
      url = url,
      method = "GET",
      sink = ltn12.sink.table(response_body),
      headers = {
         referer = base,
         dnt = "1",
         origin = base,
         ["User-Agent"] = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36"
      },
      redirect = false
   }

   local arguments = {
      urlparam = param,
      size = "FULL"
   }

   request_constructor.url = url .. "?" .. helpers.url_encode_arguments(arguments)

   local ok, response_code, response_headers, response_status_line = https.request(request_constructor)
   if not ok or response_code ~= 200 then
      return nil
   end

   local response = table.concat(response_body)
   return string.match(response, "href='(.-)'")
end

function plugin.onTextMessage(msg, blocks)
  if blocks[2] then
    local input = blocks[2]
    if not string.match(input, "http") then
      input = "http://"..input
    end

    api.sendChatAction(msg.chat.id, "upload_photo")
    local find = plugin.get_webshot_url(blocks[2])
    if find then
      local imgurl = base .. find
      api.sendMediaId(msg.chat.id, imgurl, "photo", msg.message_id, blocks[2])
    else
      api.sendReply(msg, "There was an error making the WebShot", true, nil, true)
    end
  else
    api.sendReply(msg, "Specify an URL", true, nil, true)
  end
end


plugin.triggers = {
	onTextMessage = {
		config.cmd..'(webshot) (.+)$',
		config.cmd..'(webshot)$'
	}
}

return plugin
