local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local http = require('socket.http')
local url = require('socket.url')

local plugin = {}

local images_enabled = true;

local function get_sprite(path)
  local url = "http://pokeapi.co/"..path
  local b,c = http.request(url)
  local data = json:decode(b)
  local image = data.image
  return image
end

local function callback(extra)
  --send_msg(extra.receiver, extra.text, ok_cb, false)
end

local function send_pokemon(query, msg, chat_id)
  local url = "http://pokeapi.co/api/v1/pokemon/" .. query .. "/"
  local b,c = http.request(url)
  local pokemon = json:decode(b)

  if pokemon == nil then
    return api.sendReply(msg, "No pokemon found", true, nil, true)
  end

  -- api returns height and weight x10
  local height = tonumber(pokemon.height)/10
  local weight = tonumber(pokemon.weight)/10

  local text = '*Pokédex ID*: `' .. pokemon.pkdx_id
    ..'`\n*Name:* ' .. pokemon.name
    ..'\n*Weight:* ' .. weight.." kg"
    ..'\n*Height:* ' .. height.." m"
    ..'\n*Speed:* ' .. pokemon.speed

  local image = nil

  if images_enabled and pokemon.sprites and pokemon.sprites[1] then
    local sprite = pokemon.sprites[1].resource_uri
    image = get_sprite(sprite)
  end

  if image then
    image = "http://pokeapi.co"..image
    local extra = {
      receiver = receiver,
      text = text
    }
    api.sendMediaId(chat_id, image, "photo", false, false)
    api.sendMessage(chat_id, text, true, nil, false, false)
  else
    api.sendReply(msg, text, true, nil, true)
  end
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'pokedex' then
    if not blocks[2] then

    else
      local query = blocks[2]
      return send_pokemon(query, msg, msg.chat.id)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(pokedex) (.*)$',
    config.cmd..'(pokedex) (.+)$',
    config.cmd..'(pokedex)$'
	}
}

return plugin
