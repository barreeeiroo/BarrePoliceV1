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
    return str:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&apos;', '\''):gsub('&#(%d+);', to_utf8):gsub(
        '&#x(%d+);',
        function(n)
            return string.char(tonumber(n, 16)) or n
        end
    ):gsub('&amp;', '&')
end

function plugin.get_redis_hash(id, option, extra)
    local ex = ''
    if option ~= nil then
        ex = ex .. ':' .. option
        if extra ~= nil then
            ex = ex .. ':' .. extra
        end
    end
    return 'rss:' .. id .. ex
end

function plugin.get_url_protocol(url)
    local url, is_http = url:gsub('http://', '')
    local url, is_https = url:gsub('https://', '')
    local protocol = 'http'
    if is_https == 1 then
        protocol = protocol .. 's'
    end
    return url, protocol
end

function plugin.get_parsed_feed(url, protocol)
    local feed, res = nil, 0
    if protocol == 'http' then
        feed, res = http.request(url)
    elseif protocol == 'https' then
        feed, res = https.request(url)
    end
    if res ~= 200 then
        return nil, 'There was an error whilst connecting to ' .. url
    end
    local parse = feedparser.parse(feed)
    if parse == nil then
        return nil, 'There was an error retrieving a valid RSS feed from that url. Please, make sure you typed it correctly, and try again.'
    end
    return parse, nil
end

function plugin.get_new_entries(last_entry, parsed)
    local entries = {}
    for k, v in pairs(parsed) do
        if v.id == last_entry then
            return entries
        else
            table.insert(
                entries,
                v
            )
        end
    end
    return entries
end

function plugin.subscribe(id, url)
    local base_url, protocol = plugin.get_url_protocol(url)
    local protocol_hash = plugin.get_redis_hash(
        base_url,
        'protocol'
    )
    local last_entry_hash = plugin.get_redis_hash(
        base_url,
        'last_entry'
    )
    local subscription_hash = plugin.get_redis_hash(
        base_url,
        'subscriptions'
    )
    local id_hash = plugin.get_redis_hash(id)
    if db:sismember(
        id_hash,
        base_url
    ) then
        return 'You are already subscribed to ' .. url
    end
    local parsed, res = plugin.get_parsed_feed(
        url,
        protocol
    )
    if res ~= nil then
        return res
    end
    local last_entry = ''
    if #parsed.entries > 0 then
        last_entry = parsed.entries[1].id
    end
    local name = parsed.feed.title
    db:set(
        protocol_hash,
        protocol
    )
    db:set(
        last_entry_hash,
        last_entry
    )
    db:sadd(
        subscription_hash,
        id
    )
    db:sadd(
        id_hash,
        base_url
    )
    return 'You are now subscribed to <a href="' .. url .. '">' .. tools.escape_html(name) .. '</a> - you will receive updates for this feed right here in this chat!'
end

function plugin.unsubscribe(id, n)
    if #n > 5 then
        return 'You cannot subscribe to more than 5 RSS feeds!'
    end
    n = tonumber(n)
    local id_hash = plugin.get_redis_hash(id)
    local subscriptions = db:smembers(id_hash)
    if n < 1 or n > #subscriptions then
        return 'Please enter a valid subscription ID.'
    end
    local subscription = subscriptions[n]
    local subscription_hash = plugin.get_redis_hash(
        subscription,
        'subscriptions'
    )
    db:srem(
        id_hash,
        subscription
    )
    db:srem(
        subscription_hash,
        id
    )
    local unsubscribed = db:smembers(subscription_hash)
    if #unsubscribed < 1 then
        db:del(
            plugin.get_redis_hash(
                subscription,
                'protocol'
            )
        )
        db:del(
            plugin.get_redis_hash(
                subscription,
                'last_entry'
            )
        )
    end
    return 'You will no longer receive updates from this feed.'
end

function plugin.get_subs(id)
    local subscriptions = db:smembers(plugin.get_redis_hash(id))
    if not subscriptions[1] then
        return 'You are not subscribed to any RSS feeds!'
    end
    local keyboard = {
    }
    local buttons = {}
    local text = 'This chat is currently receiving updates for the following RSS feeds:'
    for k, v in pairs(subscriptions) do
        text = text .. '\n' .. k .. ': ' .. v .. '\n'
        table.insert(
            buttons,
            {
                ['text'] = '/rss del ' .. k
            }
        )
    end
    keyboard = {
        buttons,
        {
            {
                ['text'] = 'Cancel'
            }
        }
    }
    return text, json.encode(keyboard)
end

function plugin.min_cron()
    local keys = db:keys(
        plugin.get_redis_hash(
            '*',
            'subscriptions'
        )
    )
    for k, v in pairs(keys) do
        local base_url = v:match('rss:(.+):subs')
        local protocol = db:get(
            plugin.get_redis_hash(
                base_url,
                'protocol'
            )
        )
        local last_entry = db:get(
            plugin.get_redis_hash(
                base_url,
                'last_entry'
            )
        )
        base_url = protocol .. '://' .. base_url
        local parsed, res = plugin.get_parsed_feed(base_url, protocol)
        if res ~= nil then
            return
        end
        local new = plugin.get_new_entries(
            last_entry,
            parsed.entries
        )
        local text = ''
        for n, entry in pairs(new) do
            local title = entry.title or 'No title'
            local link = entry.link or entry.id or 'No link'
            local content = ''
            if entry.content then
                content = entry.content:gsub('<br>', '\n'):gsub('%b<>', '')
                if entry.content:len() > 500 then
                    content = plugin.unescape_html(content):sub(1, 500) .. '...'
                else
                    content = plugin.unescape_html(content)
                end
            elseif entry.summary then

            else
                content = ''
            end
            text = text .. '<b>' .. tools.escape_html(title) .. '</b>\n<i>' .. tools.escape_html(tools.trim(content)) .. '</i>\n<a href="' .. link .. '">Read more.</a>'
            if n > 1 then
                break
            end
        end
        if text ~= '' then
            local last_entry = new[1].id or new[1].guid
            db:set(
                plugin.get_redis_hash(
                    base_url,
                    'last_entry'
                ),
                last_entry
            )
            for _,recipient in pairs(
                db:smembers(v)
            ) do
                local success = api.sendMessage(
                    recipient,
                    text,
                    'html'
                )
                if not success then
                    db:srem(
                        v,
                        recipient
                    )
                    db:srem(
                        'rss:' .. recipient,
                        base_url
                    )
                end
            end
        end
    end
end

function plugin.onTextMessage(msg, blocks)
    local input = blocks[2]
    if not input then
      return api.sendReply(
        msg,
        "Avaliable Commands:\n\n- /rss `sub` {_RSS Feed URL_} - Subscribe to that feed\n- /rss `del` {_RSS ID_} - Remove the subscription of that RSS (to get the list of subscriptions: /rss _del_)"
    )
    end
    if input == 'del' and not blocks[3] then
        local output, keyboard = plugin.get_subs(msg.chat.id)
        return api.sendMessage(
            msg.chat.id,
            output
        )
    elseif input == 'sub' and not blocks[3] then
        return api.sendReply(
            msg,
            'Please specify the RSS feed you would like to subscribe to using /rss sub <url>.'
        )
    elseif input == 'sub' and blocks[3] then
        return api.sendReply(
            msg,
            plugin.subscribe(
                msg.chat.id,
                blocks[3]
            ),
            'html'
        )
    elseif input == 'del' and blocks[3] then
        return api.sendReply(
            msg,
            plugin.unsubscribe(
                msg.chat.id,
                blocks[3]
            )
        )
    elseif input == 'reload' then
      if u.is_superadmin(msg.chat.id) then
        plugin.min_cron()
        return api.sendReply(
          msg,
          'Checking for RSS updates...'
        )
      else
        return api.sendReply(
        msg,
          "You are not an admin!"
        )
      end
    else
        return api.sendReply(
            msg,
            "Unrecognized Request"
        )
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
