local config = require 'config'
local u = require 'utilities'
local api = require 'methods'
local HTTP = require('socket.http')
local URL = require('socket.url')
local https = require('ssl.https')
local http = require('socket.http')
local ltn12 = require('ltn12')
local json = require('dkjson')
local feedparser = require('feedparser')
local tools = require('telegram-bot-lua.tools')

local plugin = {}

function plugin.tail(n, k)
    local u, r = ''
    for i = 1, k do
        n, r = math.floor(n / 0x40), n % 0x40
        u = string.char(r + 0x80) .. u
    end
    return u, n
end

function plugin.to_utf8(a)
    local n, r, u = tonumber(a)
    if n < 0x80 then
        return string.char(n)
    elseif n < 0x800 then
        u, n = plugin.tail(n, 1)
        return string.char(n + 0xc0) .. u
    elseif n < 0x10000 then
        u, n = plugin.tail(n, 2)
        return string.char(n + 0xe0) .. u
    elseif n < 0x200000 then
        u, n = plugin.tail(n, 3)
        return string.char(n + 0xf0) .. u
    elseif n < 0x4000000 then
        u, n = plugin.tail(n, 4)
        return string.char(n + 0xf8) .. u
    else
        u, n = plugin.tail(n, 5)
        return string.char(n + 0xfc) .. u
    end
end

function plugin.unescape_html(str)
    return str:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&apos;', '\''):gsub('&#(%d+);', plugin.to_utf8):gsub(
        '&#x(%d+);',
        function(n)
            return string.char(tonumber(n, 16)) or n
        end
    ):gsub('&amp;', '&')
end

function plugin.get_base_redis(id, option, extra)
   local ex = ''
   if option ~= nil then
      ex = ex .. ':' .. option
      if extra ~= nil then
         ex = ex .. ':' .. extra
      end
   end
   return 'rss:' .. id .. ex
end

function plugin.prot_url(url)
   local url, h = string.gsub(url, "http://", "")
   local url, hs = string.gsub(url, "https://", "")
   local protocol = "http"
   if hs == 1 then
      protocol = "https"
   end
   return url, protocol
end

function plugin.get_rss(url, prot)
   local res, code = nil, 0
   if prot == "http" then
      res, code = http.request(url)
   elseif prot == "https" then
      res, code = https.request(url)
   end
   if code ~= 200 then
      return nil, "Error while doing the petition to " .. url
   end
   local parsed = feedparser.parse(res)
   if parsed == nil then
      return nil, "Error decoding the RSS.\nAre you sure that " .. url .. " it's a RSS?"
   end
   return parsed, nil
end

function plugin.get_new_entries(last, nentries)
   local entries = {}
   for k,v in pairs(nentries) do
      if v.id == last then
         return entries
      else
         table.insert(entries, v)
      end
   end
   return entries
end

function plugin.print_subs(id)
   local uhash = plugin.get_base_redis(id)
   local subs = db:smembers(uhash)
   local subs2 = ''
   local text = 'You are subscribed to:\n---------\n'
   for k,v in pairs(subs) do
      subs2 = subs2 .. k .. " - " .. v .. '\n'
   end
   if not subs2  or subs2 == '' then
     return "You are not subscribed to any RSS Feed"
   else
     return text..subs2
   end
end

function plugin.subscribe(id, url)
   local baseurl, protocol = plugin.prot_url(url)

   local prothash = plugin.get_base_redis(baseurl, "protocol")
   local lasthash = plugin.get_base_redis(baseurl, "last_entry")
   local lhash = plugin.get_base_redis(baseurl, "subs")
   local uhash = plugin.get_base_redis(id)

   if db:sismember(uhash, baseurl) then
      return "You are already subscribed to " .. url
   end

   local parsed, err = plugin.get_rss(url, protocol)
   if err ~= nil then
      return err
   end

   local last_entry = ""
   if #parsed.entries > 0 then
      last_entry = parsed.entries[1].id
   end

   local name = parsed.feed.title

   db:set(prothash, protocol)
   db:set(lasthash, last_entry)
   db:sadd(lhash, id)
   db:sadd(uhash, baseurl)

   return "You had been subscribed to " .. name
end

function plugin.unsubscribe(id, n)
   if #n > 5 then
      return "The maximum number of subscription is 5"
   end
   n = tonumber(n)

   local uhash = plugin.get_base_redis(id)
   local subs = db:smembers(uhash)
   if n < 1 or n > #subs then
      return "Subscription id out of range!"
   end
   local sub = subs[n]
   local lhash = plugin.get_base_redis(sub, "subs")

   db:srem(uhash, sub)
   db:srem(lhash, id)

   local left = db:smembers(lhash)
   if #left < 1 then -- no one subscribed, remove it
      local prothash = plugin.get_base_redis(sub, "protocol")
      local lasthash = plugin.get_base_redis(sub, "last_entry")
      db:del(prothash)
      db:del(lasthash)
   end

   return "You had been unsubscribed from " .. sub
end

function plugin.min_cron()
   -- sync every 15 mins?
   local keys = db:keys(plugin.get_base_redis("*", "subs"))
   for k,v in pairs(keys) do
      local base = string.match(v, "rss:(.+):subs")  -- Get the URL base
      local prot = db:get(plugin.get_base_redis(base, "protocol"))
      local last = db:get(plugin.get_base_redis(base, "last_entry"))
      local url = prot .. "://" .. base
      local parsed, err = plugin.get_rss(url, prot)
      if err ~= nil then
         return
      end
      local newentr = plugin.get_new_entries(last, parsed.entries)
      local subscribers = {}
      local text = ''  -- Send only one message with all updates
      for k2, v2 in pairs(newentr) do
         local title = v2.title or 'No title'
         local author = v2.author or 'Anonymous'
         local link = v2.link or v2.id or 'No Link'
         if v2.summary or v2.description or v2.content then
          summary_text = v2.summary or v2.description or v2.content
          content = summary_text:gsub('<br>', '\n'):gsub('%b<>', '')
          if summary_text:len() > 500 then
            content = plugin.unescape_html(content):sub(1, 500) .. '...'
          else
            content = plugin.unescape_html(content)
          end
        else
          content = ''
        end

        text = text .. "<b>"..tools.escape_html(title).."</b>\nby <i>"..tools.escape_html(author).."</i>\n\n"..tools.escape_html(content).."\n\n<a href='"..tools.escape_html(link).."'>Read more</a>\n"
      end
      if text ~= '' then
         local newlast = newentr[1].id
         db:set(plugin.get_base_redis(base, "last_entry"), newlast)
         for k2, receiver in pairs(db:smembers(v)) do
            api.sendMessage(receiver, text, "html")
         end
      end
   end
end

function plugin.onTextMessage(msg, blocks)
   local id = msg.chat.id

   if blocks[1] == "rss" and not blocks[2] and not blocks[3] then
      api.sendReply(msg, plugin.print_subs(id))
   elseif blocks[2] == "sync" then
      if not u.is_superadmin(id) then
         api.sendReply(msg, "Only superadmins can refresh the RSS", true, nil, true)
      else
        api.sendReply(msg, "Fetching RSS Feeds...", true, nil, true)
        plugin.min_cron()
      end
   elseif blocks[3] then
     if blocks[2] == "subscribe" or blocks[2] == "sub" then
        api.sendReply(msg, plugin.subscribe(id, blocks[3]))
     elseif blocks[2] == "unsubscribe" or blocks[2] == "uns" or blocks[2] == "del" or blocks[2] == "delete" then
        if tonumber(blocks[3]) ~= nil then
          api.sendReply(msg, plugin.unsubscribe(id, blocks[3]))
        else
          api.sendReply(msg, "You must input a number (acording to the RSS Feed ID)")
        end
     end
   else
     api.sendReply(msg, "You should input an URL")
   end
end

plugin.triggers = {
    onTextMessage = {
        config.cmd..'(rss) (.+) (.+)$',
        config.cmd..'(rss) (.+)$',
        config.cmd..'(rss)$'
    }
}

return plugin
