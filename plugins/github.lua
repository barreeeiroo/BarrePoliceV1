local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local https = require('ssl.https')
local json = require('dkjson')
local tools = require('telegram-bot-lua.tools')

local plugin = {}

function plugin.onTextMessage(msg, blocks)
  local input = blocks[2]
  if not input then
      api.sendReply(
          msg,
          "*Command Usage:*\n\n/github <username> <repository> - Returns information about the specified GitHub repository",
          true,
          nil,
          true
      )
  else
    input = input:gsub('%s', '/')
    local jstr, res = https.request('https://api.github.com/repos/' .. input)
    if res ~= 200 then
      api.sendReply(
          msg,
          "*Ooops* There was an error making your request",
          true,
          nil,
          true
      )
    else
      local jdat = json.decode(jstr)
      if not jdat.id then
        api.sendReply(
            msg,
            "*Ooops* No results were found",
            true,
            nil,
            true
        )
      else
        local title = '<a href="' .. jdat.html_url .. '">' .. tools.escape_html(jdat.full_name) .. '</a>'
        if jdat.language then
            title = title .. '<b>|</b> ' .. jdat.language
        end
        local description = jdat.description and '\n<pre>' .. tools.escape_html(jdat.description) .. '</pre>\n' or '\n'
        local forks, stargazers, subscribers
        if jdat.forks_count == 1 then
            forks = ' fork'
        else
            forks = ' forks'
        end
        if jdat.stargazers_count == 1 then
            stargazers = ' star'
        else
            stargazers = ' stars'
        end
        if jdat.subscribers_count == 1 then
            subscribers = ' watcher'
        else
            subscribers = ' watchers'
        end
        api.sendReply(
            msg,
            title .. description .. '<a href="' .. jdat.html_url .. '/network">' .. jdat.forks_count .. forks .. '</a> <b>|</b> <a href="' .. jdat.html_url .. '/stargazers">' .. jdat.stargazers_count .. stargazers .. '</a> <b>|</b> <a href="' .. jdat.html_url .. '/watchers">' .. jdat.subscribers_count .. subscribers .. '</a>\nLast updated at ' .. jdat.updated_at:gsub('T', ' '):gsub('Z', ''),
            'html',
            nil,
            true
        )
      end
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(github) (.+)$',
		config.cmd..'(github)$'
	}
}

return plugin
