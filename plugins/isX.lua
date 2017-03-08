local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local ltn12 = require "ltn12"
local https = require "ssl.https"
local HTTP = require('socket.http')
local URL = require('socket.url')

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
   local jsonBody = json:decode(data)
   local response = ""
   if jsonBody["Error Occured"] ~= nil then
      response = jsonBody["Error Occured"]
   elseif jsonBody["Is Porn"] == nil or jsonBody["Reason"] == nil then
      response = "I don't know if that has adult content or not."
   else
      local response = "Skin Colors Level: `" .. jsonBody["Skin Colors"] .. "`\nContains Bad Words: `" .. jsonBody["Is Contain Bad Words"] .. "`\n\n*Is Porn:* " .. jsonBody["Is Porn"] .. "\n*Reason:* _" .. jsonBody["Reason"] .. "_"
   end
   return response
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'isX' or blocks[1] == 'isx' then
    if not blocks[2] then
      api.sendReply(msg, "You have to _send me_ an *Image URL after the command*", true, reply_markup)
    else
      local request_data = request(blocks[2])
      local parse_data = parseData(request_data)
      api.sendReply(msg, parse_data, true, reply_markup)
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
