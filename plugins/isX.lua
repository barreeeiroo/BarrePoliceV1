local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local ltn12 = require "ltn12"
local https = require "ssl.https"
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require 'dkjson'

local plugin = {}

local function isempty(s)
  return s == nil or s == ''
end

local function request(imageUrl)
   local api_key = config.mashape_api_key
   if isempty(api_key) then
      return nil, 'Configure your Mashape API Key'
   end

   local api = "https://sphirelabs-advanced-porn-nudity-and-adult-content-detection.p.mashape.com/v1/get/index.php"
   local parameters = "?url="..(URL.escape(imageUrl) or "")
   local url = api..parameters
   local respbody = {}
   local headers = {
      ["X-Mashape-Key"] = api_key,
      ["Accept"] = "Accept: application/json"
   }
   local body, code, headers, status = https.request{
      url = url,
      method = "GET",
      headers = headers,
      sink = ltn12.sink.table(respbody),
      protocol = "tlsv1"
   }
   if code ~= 200 then return "", code end
   local body = table.concat(respbody)
   return body, code
end

local function parseData(data)
   local obj, pos, err = JSON.decode(data, 1, nil)
   local text = "*Skin Colors Level:* `" .. obj.Skin%s+Colors .. "`\n*Contains Bad Words:* `" .. obj.Is%s+Contain%s+Bad%s+Words .. "\n\n*Is Porn:* " .. obj.Is%s+Porn .. "\n*Reason:* _" .. obj.Reason .. "_"

   return text
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'isX' or blocks[1] == 'isx' then
    if not blocks[2] then
      api.sendReply(msg, "You have to _send me_ an *Image URL after the command*", true, reply_markup)
    else
      api.sendReply(msg, parseData(request(blocks[2])), true, nil, true)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(is[x|X]) (.*)$',
    config.cmd..'(is[x|X])$'
	}
}

return plugin
