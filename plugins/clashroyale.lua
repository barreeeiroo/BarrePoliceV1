local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local ltn12 = require "ltn12"
local https = require "ssl.https"
local HTTP = require "socket.http"
local URL = require "socket.url"

local plugin = {}

local function isempty(s)
  return s == nil or s == ''
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] then
    if not blocks[2] then
      api.sendReply(msg, "*Avaliable Commands:*\n\n- /cr `arena` {`ID`} - _Sends a list of all Arenas, or the Arena ID information_\n- /cr `card` {`ID`/`IDname`} - _Sends a list of all Cards, or the Card ID information_\n- /cr `league` {`ID`} - _Sends a list of all Leagues, or the League ID information_\n- /cr `emotions` {`ID`/`IDName`} - _Sends a list of all Emotions, or that emotion in a GIF_\n- /cr `deck` - _Sends a random deck_\n- /cr `chest`\n  `arena` {`ID`} - _Sends the list of all avaliable chests for that arena_\n  `type` {`ID`/`IDName`} - _Sends the list of all avaliable chests matching that type_\n  `image` {`ID`/`IDName`} - _Sends the image of that chest_\n  `info` {`ID`/`IDName`} {`ArenaID`} - _Sends the info of that chest_", true, nil, true)
    else
      if blocks[2] == "arena" or blocks[2] == "arenas" then
        if blocks[3] then
          if tonumber(blocks[3]) ~= nil then
            if tonumber(blocks[3]) >= 12 then
              api.sendChatAction(msg.chat.id, "typing")
              api.sendReply(msg, "Too big Arena ID. The maximum ID is 11", true, nil, true)
            else
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?arenas&id="..blocks[3].."&image")
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "Arena "..blocks[3])

              api.sendChatAction(msg.chat.id, "typing")
              local output2, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?arenas&id="..blocks[3])
              if not output2 or res ~= 200 or output:len() == 0 then
                    output2, res = HTTP.request(url)
              end
              api.sendReply(msg, output2, true, nil, true)
            end
          else
            api.sendChatAction(msg.chat.id, "typing")
            api.sendReply(msg, "The 3rd input must be a number", true, nil, true)
          end
        else
          local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?arenas")
          if not output or res ~= 200 or output:len() == 0 then
                output, res = HTTP.request(url)
          end
          api.sendReply(msg, output, true, nil, true)
        end
      elseif blocks[2] == "card" or blocks[2] == "cards" then
        if blocks[3] then
          if tonumber(blocks[3]) ~= nil then
            if tonumber(blocks[3]) >= 75 then
              api.sendChatAction(msg.chat.id, "typing")
              api.sendReply(msg, "Too big Card ID. The maximum ID is 74", true, nil, true)
            else
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&image")
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              local outputN, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&name")
              if not outputN or res ~= 200 or output:len() == 0 then
                    outputN, res = HTTP.request(url)
              end
              api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, outputN)

              api.sendChatAction(msg.chat.id, "typing")
              local output2, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3])
              if not output2 or res ~= 200 or output:len() == 0 then
                    output2, res = HTTP.request(url)
              end
              api.sendReply(msg, output2, true, nil, true)
            end
          else
            api.sendChatAction(msg.chat.id, "typing")
            local outputT, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3])
            if not outputT or res ~= 200 or outputT:len() == 0 then
                  outputT, res = HTTP.request(url)
            end
            if outputT == "Card not found" then
              api.sendReply(msg, outputT, true, nil, true)
            else
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&image")
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&image")
              end
              local outputN, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&name")
              if not outputN or res ~= 200 or outputN:len() == 0 then
                    outputN, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3].."&name")
              end
              api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, outputN)

              api.sendChatAction(msg.chat.id, "typing")
              local output2, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3])
              if not output2 or res ~= 200 or output2:len() == 0 then
                    output2, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards&id="..blocks[3])
              end
              api.sendReply(msg, output2, true, nil, true)
            end
          end
        else
          api.sendChatAction(msg.chat.id, "typing")
          local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?cards")
          if not output or res ~= 200 or output:len() == 0 then
                output, res = HTTP.request(url)
          end
          api.sendReply(msg, output, true, nil, true)
        end
      elseif blocks[2] == "league" or blocks[2] == "leagues" then
        if blocks[3] then
          if tonumber(blocks[3]) ~= nil then
            if tonumber(blocks[3]) >= 10 then
              api.sendChatAction(msg.chat.id, "typing")
              api.sendReply(msg, "Too big League ID. The maximum ID is 9", true, nil, true)
            else
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?leagues&id="..blocks[3].."&image")
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, "League "..blocks[3])

              api.sendChatAction(msg.chat.id, "typing")
              local output2, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?leagues&id="..blocks[3])
              if not output2 or res ~= 200 or output:len() == 0 then
                    output2, res = HTTP.request(url)
              end
              api.sendReply(msg, output2, true, nil, true)
            end
          else
            api.sendChatAction(msg.chat.id, "typing")
            api.sendReply(msg, "The 3rd input must be a number", true, nil, true)
          end
        else
          api.sendChatAction(msg.chat.id, "typing")
          local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?leagues")
          if not output or res ~= 200 or output:len() == 0 then
                output, res = HTTP.request(url)
          end
          api.sendReply(msg, output, true, nil, true)
        end
      elseif blocks[2] == "emotion" or blocks[2] == "emotions" or blocks[2] == "emoji" or blocks[2] == "emojis"then
        if blocks[3] then
          if tonumber(blocks[3]) ~= nil then
            if tonumber(blocks[3]) >= 5 then
              api.sendChatAction(msg.chat.id, "typing")
              api.sendReply(msg, "Too big Emotion ID. The maximum ID is 4", true, nil, true)
            else
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?emotions&id="..blocks[3])
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              api.sendMediaId(msg.chat.id, output, "video", msg.message_id, false)
            end
          else
            if blocks[3] == "angrer" or blocks[3] == "cry" or blocks[3] == "laugh" or blocks[3] == "thumbs-up" then
              api.sendChatAction(msg.chat.id, "upload_photo")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?emotions&id="..blocks[3])
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              api.sendMediaId(msg.chat.id, output, "video", msg.message_id, false)
            else
              api.sendReply(msg, "Unrecognized emotion", true, nil, true)
            end
          end
        else
          api.sendChatAction(msg.chat.id, "typing")
          local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?emotions")
          if not output or res ~= 200 or output:len() == 0 then
                output, res = HTTP.request(url)
          end
          api.sendReply(msg, output, true, nil, true)
        end
      elseif blocks[2] == "deck" or blocks[2] == "decks" then
        api.sendChatAction(msg.chat.id, "typing")
        local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?random-deck")
        if not output or res ~= 200 or output:len() == 0 then
              output, res = HTTP.request(url)
        end
        api.sendReply(msg, output, true, nil, true)
      elseif blocks[2] == "chest" or blocks[3] == "chests" then
        if blocks[3] then
          if blocks[3] == "arena" then
            if blocks[4] then
              if tonumber(blocks[4]) ~= nil then
                if tonumber(blocks[4]) > 11 then
                  api.sendReply(msg, "Too big Arena ID. The maximum allowed is 11", true, nil, true)
                else
                  api.sendChatAction(msg.chat.id, "typing")
                  local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&arena="..blocks[4])
                  if not output or res ~= 200 or output:len() == 0 then
                        output, res = HTTP.request(url)
                  end
                  api.sendReply(msg, output, true, nil, true)
                end
              else
                api.sendReply(msg, "The Arena input must be a number", true, nil, true)
              end
            else
              api.sendReply(msg, "You must add an Arena ID", true, nil, true)
            end
          elseif blocks[3] == "type" then
            if blocks[4] then
              if tonumber(blocks[4]) ~= nil then
                if tonumber(blocks[4]) > 10 then
                  api.sendReply(msg, "Too big Type ID. The maximum allowed is 10", true, nil, true)
                else
                  local outputI, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id="..blocks[4].."&man")
                  if not outputI or res ~= 200 or outputI:len() == 0 then
                        outputI, res = HTTP.request(url)
                  end
                  if outputI == "Chest not found" then

                  else
                    api.sendChatAction(msg.chat.id, "upload_photo")
                    api.sendMediaId(msg.chat.id, outputI, "photo", msg.message_id, false)
                  end
                  api.sendChatAction(msg.chat.id, "typing")
                  local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&id="..blocks[4])
                  if not output or res ~= 200 or output:len() == 0 then
                        output, res = HTTP.request(url)
                  end
                  api.sendReply(msg, output, true, nil, true)
                end
              else
                api.sendReply(msg, "Type must be a number", true, nil, true)
              end
            else
              api.sendReply(msg, "You must add a Type ID (to get IDs: /cr chest)", true, nil, true)
            end
          elseif blocks[3] == "image" then
            if blocks[4] then
              api.sendChatAction(msg.chat.id, "typing")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id="..blocks[4])
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              if output == "Chest not found" then
                api.sendReply(msg, output, true, nil, true)
              else
                api.sendChatAction(msg.chat.id, "upload_photo")
                api.sendMediaId(msg.chat.id, output, "photo", msg.message_id, false)
              end
            else
              api.sendChatAction(msg.chat.id, "typing")
              local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image")
              if not output or res ~= 200 or output:len() == 0 then
                    output, res = HTTP.request(url)
              end
              api.sendReply(msg, output, true, nil, true)
            end
          elseif blocks[3] == "info" then
            if blocks[4] and blocks[5] then
              if tonumber(blocks[4]) ~= nil then
                if tonumber(blocks[4]) > 10 then
                  return api.sendReply(msg, "Too big Chest Type ID. The maximum allowed is 10", true, nil, true)
                end
              end
              if tonumber(blocks[5]) ~= nil then
                if tonumber(blocks[5]) > 11 then
                  return api.sendReply(msg, "Too big Arena ID. The maximum allowed is 11", true, nil, true)
                else
                  if blocks[4] == "season-reward" then
                    api.sendChatAction(msg.chat.id, "upload_photo")
                    local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id="..blocks[4].."&arena="..blocks[5])
                    if not output or res ~= 200 or output:len() == 0 then
                          output, res = HTTP.request(url)
                    end
                    local outputI, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id=draft")
                    if not outputI or res ~= 200 or output:len() == 0 then
                          outputI, res = HTTP.request(url)
                    end
                    api.sendMediaId(msg.chat.id, outputI, "photo", msg.message_id, false)
                    api.sendReply(msg, output, true, nil, true)
                  else
                    api.sendChatAction(msg.chat.id, "upload_photo")
                    local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id="..blocks[4].."&arena="..blocks[5])
                    if not output or res ~= 200 or output:len() == 0 then
                          output, res = HTTP.request(url)
                    end
                    local outputI, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests&image&id="..blocks[4].."&man")
                    if not outputI or res ~= 200 or output:len() == 0 then
                          outputI, res = HTTP.request(url)
                    end
                    api.sendMediaId(msg.chat.id, outputI, "photo", msg.message_id, false)
                    api.sendReply(msg, output, true, nil, true)
                  end
                end
              else
                api.sendReply(msg, "The 5th input must be a number (Arena ID)", true, nil, true)
              end
            else
              api.sendChatAction(msg.chat.id, "typing")
              api.sendReply(msg, "*Usage:*\n\n- /cr _chest info_  `chestType`/`chestID` `arenaID`", true, nil, true)
            end
          end
        else
          api.sendChatAction(msg.chat.id, "typing")
          local output, res = HTTP.request("http://barreeeiroo.ga/BarrePolice/ClashRoyale/?chests")
          if not output or res ~= 200 or output:len() == 0 then
                output, res = HTTP.request(url)
          end
          api.sendReply(msg, output, true, nil, true)
          api.sendReply(msg, "You can add too after the _"..blocks[2].."_ `arena`, `type`, `info` or `image` to get more info", true, nil, true)
        end
      else
        api.sendChatAction(msg.chat.id, "typing")
        api.sendReply(msg, "Unrecognized request", true, nil, true)
      end
    end
  end
end

plugin.triggers = {
	onTextMessage = {
    config.cmd..'([C/c]lash[R/r]oyale) (.*) (.*) (.*) (.*)$',
    config.cmd..'([C/c]lash[R/r]oyale) (.*) (.*) (.*)$',
    config.cmd..'([C/c]lash[R/r]oyale) (.*) (.*)$',
		config.cmd..'([C/c]lash[R/r]oyale) (.*)$',
    config.cmd..'([C/c]lash[R/r]oyale)$',
    config.cmd..'([C/c][R/r]) (.*) (.*) (.*) (.*)$',
    config.cmd..'([C/c][R/r]) (.*) (.*) (.*)$',
		config.cmd..'([C/c][R/r]) (.*) (.*)$',
		config.cmd..'([C/c][R/r]) (.*)$',
    config.cmd..'([C/c][R/r])$'
	}
}

return plugin
