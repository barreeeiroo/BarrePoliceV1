local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

local plugin = {}

function plugin.onTextMessage(msg, blocks)
  api.sendChatAction(msg.chat.id, "typing")
  local input = blocks[2]
  if not input then
      api.sendReply(
          msg,
          "Please, specify an Instagram username"
      )
  end
  local body = 'instagram_name=' .. input
  local response = {}
  local _, res = http.request{
      ['url'] = 'http://instadp.com/run.php',
      ['method'] = 'POST',
      ['headers'] = {
          ['Content-Length'] = body:len(),
          ['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8',
          ['Cookie'] = '_asomcnc=1',
          ['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
          ['X-Requested-With'] = 'XMLHttpRequest'
      },
      ['source'] = ltn12.source.string(body),
      ['sink'] = ltn12.sink.table(response)
  }
  local str = table.concat(response)
  if res ~= 200 then
      api.sendReply(
          msg,
          "There was a connection problem. Please, try again later"
      )
  elseif not str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/scontent%.cdninstagram%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>') then
      api.sendReply(
          msg,
          "I couldn't find that person or he has not profile image. Maybe you wrote wrong the username"
      )
  end

  api.sendChatAction(msg.chat.id, "upload_photo")
  api.sendMediaId(msg.chat.id, str:match('%<a href%=%"%#%" onclick%=%"window%.open%(%\'(https%:%/%/scontent%.cdninstagram%.com%/.-)%\'%, %\'%_blank%\'%)%;%"%>'), "photo", msg.message_id, "@"..input.." on Instagram")
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(instagram) (.+)$',
		config.cmd..'(instagram)$'
	}
}

return plugin
