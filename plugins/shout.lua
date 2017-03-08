local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

function trim(str)
    local s = str:gsub('^%s*(.-)%s*$', '%1')
    return s
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'shout' then
    if not blocks[2] then
      message = "*Avaliable Commands:*\n\n- /shout `something` - _Shout the _`something`"
      api.sendReply(msg, message, true, nil, true)
    else
      local input = blocks[2]

      input = trim(input)
      input = input:upper()

      local output = ''
      local inc = 0
      local ilen = 0
      local utf8_char = '('..u.char.utf_8..'*)'
      for match in input:gmatch(utf8_char) do
        if ilen < 20 then
          ilen = ilen + 1
          output = output .. match .. ' '
        end
      end
      ilen = 0
      output = output .. '\n'
      for match in input:sub(2):gmatch(utf8_char) do
        if ilen < 19 then
          local spacing = ''
          for _ = 1, inc do
            spacing = spacing .. '  '
          end
          inc = inc + 1
          ilen = ilen + 1
          output = output .. match .. ' ' .. spacing .. match .. '\n'
        end
      end
      message = '```\n' .. trim(output) .. '\n```'
      api.sendReply(msg, message, true, nil, true)
    end
  end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(shout) (.+)$',
		config.cmd..'(shout)$'
	}
}

return plugin
