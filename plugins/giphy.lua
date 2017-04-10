local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local ltn12 = require "ltn12"
local http = require('socket.http')
local url = require('socket.url')

local plugin = {}

local BASE_URL = 'http://api.giphy.com/v1'
local API_KEY = 'dc6zaTOxFJmzC' -- public beta key

function plugin.get_image(response)
  local images = json:decode(response).data
  if #images == 0 then return nil end -- No images
  local i = math.random(#images)
  local image =  images[i] -- A random one

  if image.images.downsized then
    return image.images.downsized.url
  end

  if image.images.original then
    return image.original.url
  end

  return nil
end

function plugin.get_random_top()
  local url = BASE_URL.."/gifs/trending?api_key="..API_KEY
  local response, code = http.request(url)
  if code ~= 200 then return nil end
  return plugin.get_image(response)
end

function plugin.search(text)
  text = url.escape(text)
  local url = BASE_URL.."/gifs/search?q="..text.."&api_key="..API_KEY
  local response, code = http.request(url)
  if code ~= 200 then return nil end
  return plugin.get_image(response)
end

function plugin.onTextMessage(msg, blocks)
  local gif_url = nil
  api.sendChatAction(msg.chat.id, "upload_photo")

  if not blocks[2] then
    gif_url = plugin.get_random_top()
  else
    gif_url = plugin.search(blocks[2])
  end

  if not gif_url then
    api.sendReply(msg, "*Error:* GIF not found", true, nil, true)
  end
  api.sendMediaId(msg.chat.id, gif_url, "video", msg.message_id, false)
end

plugin.triggers = {
	onTextMessage = {
    config.cmd..'(giphy) (.*)$',
    config.cmd..'(giphy)$',
		config.cmd..'(gif) (.*)$',
    config.cmd..'(gif)$'
	}
}

return plugin
