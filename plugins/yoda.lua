local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local ltn12 = require "ltn12"
local https = require "ssl.https"

local plugin = {}

local function isempty(s)
  return s == nil or s == ''
end

local function request(text)
   local api = "https://yoda.p.mashape.com/yoda?"
   text = string.gsub(text, " ", "+")
   local parameters = "sentence="..(text or "")
   local url = api..parameters

   local api_key = config.mashape_api_key
   if isempty(api_key) then
      return 'Configure your Mashape API Key'
   end

   local headers = {
      ["X-Mashape-Key"] = api_key,
      ["Accept"] = "text/plain"
   }

   local respbody = {}
   local body, code  = https.request{
      url = url,
      method = "GET",
      headers = headers,
      sink = ltn12.sink.table(respbody),
      protocol = "tlsv1"
   }
   if code ~= 200 then return code end
   local body = table.concat(respbody)
   return body
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'yoda' then
    if not blocks[2] then
      api.sendReply(msg, request("You have to say something to me"), true, reply_markup)
    else
      api.sendReply(msg, request(blocks[2]), true, reply_markup)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(yoda) (.*)$',
    config.cmd..'(yoda)$'
	}
}

return plugin
