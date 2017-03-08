local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local http = require('socket.http')
local url = require('socket.url')

local plugin = {}

local function getRandomButts(attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request("http://api.obutts.ru/noise/1")

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  -- The OpenBoobs API sometimes returns an empty array
  if not data and attempt <= 3 then
    return getRandomButts(attempt)
  end

  return 'http://media.obutts.ru/' .. data.preview
end

local function getRandomBoobs(attempt)
  attempt = attempt or 0
  attempt = attempt + 1

  local res,status = http.request("http://api.oboobs.ru/noise/1")

  if status ~= 200 then return nil end
  local data = json:decode(res)[1]

  -- The OpenBoobs API sometimes returns an empty array
  if not data and attempt < 10 then
    return getRandomBoobs(attempt)
  end

  return 'http://media.oboobs.ru/' .. data.preview
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'porn' then
    if not blocks[2] then
      local message = "*Avaliable Commands:*\n\n- /porn `boobs` - _Sends random boobs_\n- /porn `butts` - _sends random butts_"
      api.sendReply(msg, message, true, nil, true)
    else
      if blocks[2] == 'boob' or blocks[2] == 'boobs' then
        local getPorn = getRandomBoobs()
        local message = "[Here are your boobs:]("..getPorn..")"
				api.sendReply(msg, message, true, nil, true)
      elseif blocks[2] == 'butt' or blocks[2] == 'butts' then
        local getPorn = getRandomButts()
        local message = "[Here are your butts:]("..getPorn..")"
				api.sendReply(msg, message, true, nil, true)
      else
        local message = "*Avaliable Commands:*\n\n- /porn `boobs` - _Sends random boobs_\n- /porn `butts` - _sends random butts_"
        api.sendReply(msg, message, true, nil, true)
      end
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(porn) (.*)$',
    config.cmd..'(porn)$'
	}
}

return plugin
