local config = require '../config'
local u = require 'utilities'
local api = require 'methods'
local HTTP = require('socket.http')
local URL = require('socket.url')

local plugin = {}

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'apod' then
		local base_url = "http://barreeeiroo.ga/BarrePolice/apod/?key="..config.apod_api_key
		if not blocks[2] then
			local message = "*Avaliable Commands:*\n\n- /apod `image` - _Sends the NASA Image of the day_\n- /apod `hd` - _Sends the NASA Image of the day in HD quality_\n- /apod `data` - _Sends the data of the NASA Image of the day_"
			api.sendReply(msg, message, true, nil, true)
		else
			if blocks[2] == 'image' then

				local url = base_url .. "&image"
				local output, res = HTTP.request(url)
		    if not output or res ~= 200 or output:len() == 0 then
		        output, res = HTTP.request(url)
		    end
				local message = "[Today's NASA Image]("..output..")"
				api.sendReply(msg, message, true, nil, true)


			elseif blocks[2] == 'hd' then


				local url = base_url .. "&hd"
				local output, res = HTTP.request(url)
		    if not output or res ~= 200 or output:len() == 0 then
		        output, res = HTTP.request(url)
		    end
				local message = "[Today's NASA Image in High-Definition]("..output..")"
				api.sendReply(msg, message, true, nil, true)


			elseif blocks[2] == 'data' then


				local url = base_url .. "&data"
				local output, res = HTTP.request(url)
		    if not output or res ~= 200 or output:len() == 0 then
		        output, res = HTTP.request(url)
		    end
				api.sendReply(msg, output, true, reply_markup)


			else
				local message = "Unknown request"
				api.sendReply(msg, message, true, reply_markup)
			end
		end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(apod) (.+)$',
		config.cmd..'(apod)$'
	}
}

return plugin
