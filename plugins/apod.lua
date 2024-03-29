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
			local message = "*Avaliable Commands:*\n\n- /apod `image` - _Sends the NASA Image of the day_\n- /apod `hd` - _Sends the NASA Image of the day in HD quality_\n- /apod `data` - _Sends the data of the NASA Image of the day_\n- /apod {`image`/`hd`/`data`} {_YYYY-MM-DD_} - _Sends your APOD image of that day_"
			api.sendReply(msg, message, true, nil, true)
		else
			if blocks[3] then
				base_url = base_url .. "&date="..blocks[3]
				if blocks[2] == 'image' then
					api.sendChatAction(msg.chat.id, "upload_photo")
					local url = base_url .. "&image"
					local output, res = HTTP.request(url)
			    if not output or res ~= 200 or output:len() == 0 then
			        output, res = HTTP.request(url)
			    end
					if string.match(output, "http") then
						api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "Today's NASA Image")
					else
						api.sendReply(msg, output, true, reply_markup)
					end
				elseif blocks[2] == 'hd' then
					api.sendChatAction(msg.chat.id, "upload_photo")
					local url = base_url .. "&hd"
					local output, res = HTTP.request(url)
			    if not output or res ~= 200 or output:len() == 0 then
			        output, res = HTTP.request(url)
			    end
					if string.match(output, "http") then
						api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "Today's NASA Image")
					else
						api.sendReply(msg, output, true, reply_markup)
					end
				elseif blocks[2] == 'data' then
					api.sendChatAction(msg.chat.id, "typing")
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
			else
				if blocks[2] == 'image' then
					api.sendChatAction(msg.chat.id, "upload_photo")
					local url = base_url .. "&image"
					local output, res = HTTP.request(url)
			    if not output or res ~= 200 or output:len() == 0 then
			        output, res = HTTP.request(url)
			    end
					api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "Today's NASA Image")

				elseif blocks[2] == 'hd' then
					api.sendChatAction(msg.chat.id, "upload_photo")
					local url = base_url .. "&hd"
					local output, res = HTTP.request(url)
			    if not output or res ~= 200 or output:len() == 0 then
			        output, res = HTTP.request(url)
			    end
					api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "Today's NASA Image")

				elseif blocks[2] == 'data' then
					api.sendChatAction(msg.chat.id, "typing")
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
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(apod) (.+) (.+)$',
		config.cmd..'(apod) (.+)$',
		config.cmd..'(apod)$'
	}
}

return plugin
