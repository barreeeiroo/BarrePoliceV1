local config = require 'config'
local misc = require 'utilities'.misc
local roles = require 'utilities'.roles
local api = require 'methods'

local plugin = {}

----these functions should be globals

local function is_realm(chat_id)
	if db:sismember('bot:realms', chat_id) then
		return true
	else
		return false
	end
end

local function is_paired(chat_id)
	--realm_id: the chat has a realm associated and the chat_id appears in the subgroups of the realm
	--FALSE, 1: the chat_id is a realm
	--FALSE, 2: the chat doesn't have an associated realm
	--FALSE, 3: the chat has an associated realm but the chat_id doesn't appear between the realm subgroups
	
	if db:sismember('bot:realms', chat_id) then
		return false, 1
	else
		local realm_id = db:get('chat:'..chat_id..':realm')
		if not realm_id then
			return false, 2
		else
			local is_in_the_list = db:hget('realm:'..realm_id..':subgroups', chat_id)
			if not is_in_the_list then
				return false, 3
			else
				return realm_id
			end
		end
	end
end

local function is_subgroup(chat_id)
	if db:sismember('bot:realms') then
		return false
	else
		local realm_id = db:get('chat:'..chat_id..':realm')
		if realm_id then
			return realm_id
		else
			return false
		end
	end
end

local function get_realm_id(chat_id)
	return db:get('chat:'..chat_id..':realm')
end

local function get_realm_info(realm_id)
	local text = ''
	if not db:sismember('bot:realms') then
		text = text ..'- Not indexed in "bot:realms"'
	else
		text = text ..'- Indexed in "bot:realms"'
	end
	
	local subgroups = db:hgetall('realm:'..msg.chat.id..':subgroups')
	if not next(subgroups) then
		text = text..'\n\n[No subgroups]'
	else
		text = text..'\n\nSubgroups:\n'
		for subgroup_id, subgroup_name in pairs(subgroups) do
			local subgroup_realm = (db:get('chat:'..subgroup_id..':realm')) or 'none'
			text = text..'   ['..subgroup_id..']>['..subgroup_realm..']\n'
		end
	end
	
	return text
end

local function get_subgroup_info(chat_id)
	local realm_id = db:get('chat:'..chat_id..':realm')
	if not realm_id then
		return 'No realm paired'
	else
		local text = 'Realm id (chat:'..chat_id..':realm) = '..realm_id..'\n'
		local subgroup_name = db:hget('realm:'..realm_id..':subgroups', chat_id)
		if subgroup_name then
			text = text..'Listed in the realm subgroups as "'..subgroup_name..'"'
		else
			text = text..'Not listed in the realm subgroups'
		end
		return text
	end
end

local function remRealm(realm_id)
	local subgroups = db:hgetall('realm:'..realm_id..':subgroups')
	if subgroups then
		if next(subgroups) then
			local count = {total = 0, subgroup_keys_deleted = 0}
			for subgroup_id, subgroup_name in pairs(subgroups) do
				count.total = count.total + 1
				local subgroup_realm_id = db:get('chat:'..subgroup_id..':realm')
				if subgroup_realm_id then
					if tonumber(subgroup_realm_id) == tonumber(realm_id) then
						count.subgroup_keys_deleted = count.subgroup_keys_deleted + 1
						db:del('chat:'..subgroup_id..':realm')
					end
				end
			end
		end
	end
	
	db:del('realm:'..realm_id..':subgroups')
	db:srem('bot:realms', realm_id)
	
	if count then return count end
end

local function unpair_group(realm_id, subgroup_id)
	local subgroup = {
		title = db:hget('realm:'..realm_id..':subgroups', subgroup_id),
		realm = db:get('chat:'..subgroup_id..':realm')
	}
	
	db:del('chat:'..subgroup_id..':realm')
	db:hdel('realm:'..realm_id..':subgroups', subgroup_id)
	
	return subgroup
end

--is_realm
--is_paired
--is_subgroup
--get_429_timeout
--comando per eliminare un realm. Richiede l'approvazione tramite tastiera inline ("are you sure? yes/no")

--misc.get_adminlist must return false + code if an api limit is hit

--must be placed after onmessage.lua

--in remGroup, se "hard", rimuovi anche il realm associato al gruppo, ed il gruppo dai subgruppi del realm associato (unapir_groups)

--[[
GENERAL:
	bot:realms
		REALM_ID
		REALM_ID
		...

REALMS:
	realm:chat_id:subgroups
		ID = TITLE
		ID = TITLE
		...

SUBGROUP:
	chat:chat_id:realm
		REALM_ID
	
]]

local function get_subgroups_number(realm_id, subgroups)
	if not subgroups then
		subgroups = db:hgetall('realm:'..realm_id..':subgroups')
	end
	
	if not next(subgroups) then
		return 0
	else
		local n = 0
		for id, name in pairs(subgroups) do
			n = n + 1
		end
		return n
	end
end

local function realm_get_userid(text)
	--if no user id: returns false and the msg id of the translation for the problem
	if text:match('(@[%w_]+)') then
		local username = text:match('(@[%w_]+)')
		local id = misc.resolve_user(username)
		if not id then
			return false, _("I've never seen this user before.\n"
				.. "If you want to teach me who is he, forward me a message from him")
		else
			return id
		end
	elseif text:match('(%d+)') then
		local id = text:match('(%d+)')
		return id
	else
		return false, _("I've never seen this user before.\n"
				.. "If you want to teach me who is he, forward me a message from him")
	end
end	

local function setrules_subgroup(subgroup_id, subgroup_name, others)
	db:hset('chat:'..subgroup_id..':info', 'rules', others.rules)
end

local function setlog_subgroup(subgroup_id, subgroup_name, others)
	local channel_id = others.channel_id
	local old_log =  db:hget('bot:chatlogs', subgroup_id)
	if old_log ~= channel_id then
		db:hset('bot:chatlogs', subgroup_id, channel_id)
		return 1
	end
end

local function pin_subgroup(subgroup_id, subgroup_name, others)
	local to_pin = others.text_to_pin
	local pin_id = db:get('chat:'..subgroup_id..':pin')
	if to_pin and pin_id then
		local res = api.editMessageText(subgroup_id, pin_id, to_pin, true)
		if res then
			return true
		end
	end	
end

local function sendmessage_subgroup(subgroup_id, subgroup_name, others)
	local res = api.sendMessage(subgroup_id, others.text, true)
	if res then
		return true
	else
		return false
	end
end

local function subgroups_iterator(realm_id, callback_function, others)
	local subgroups = db:hgetall('realm:'..realm_id..':subgroups')
	if not next(subgroups) then
		return false
	else
		local i = 0
		for subgroup_id, subgroup_name in pairs(subgroups) do
			local result = callback_function(subgroup_id, subgroup_name, others)
			if result then
				if type(result) == 'number' then
					i = i + result
				else
					i = i + 1
				end
			end
		end
		return true, i
	end
end

local function doKeyboard_config(chat_id)
    local keyboard = {
        inline_keyboard = {
            {{text = _("🛠 Menu"), callback_data = 'config:menu:'..chat_id}},
            {{text = _("⚡️ Antiflood"), callback_data = 'config:antiflood:'..chat_id}},
            {{text = _("🌈 Media"), callback_data = 'config:media:'..chat_id}},
            {{text = _("🚫 Antispam"), callback_data = 'config:antispam:'..chat_id}}
        }
    }
    
    return keyboard
end

local function doKeyboard_subgroups(subgroups, callback_identifier, insert_all_button)
	local keyboard = {inline_keyboard={}}
	if insert_all_button then
		table.insert(keyboard.inline_keyboard, {{text = 'ALL', callback_data = 'realm:'..callback_identifier..':all'}})
	end
	
	for subgroup_id, name in pairs(subgroups) do
		local line = {{text = name, callback_data = 'realm:'..callback_identifier..':'..subgroup_id}}
		table.insert(keyboard.inline_keyboard, line)
	end
	
	table.insert(keyboard.inline_keyboard, {{text = _('Cancel'), callback_data = 'realm:cancel'}})
	
	return keyboard
end

function plugin.onCallbackQuery(msg, blocks)
	if blocks[1] == 'cancel' then
		api.editMessageText(msg.chat.id, msg.message_id, _('_Action aborted_'), true)
	end
	if blocks[1] == 'setrules' then
		local rules = db:get('temp:realm:'..msg.chat.id..':setrules')
		if not rules then
			api.editMessageText(msg.chat.id, msg.message_id, _('_Expired_'), true)
		else
			if blocks[2]:match('^-%d+$') then
				db:hset('chat:'..blocks[2]..':info', 'rules', rules)
				local subgroups = db:hgetall('realm:'..msg.chat.id..':subgroups')
				local keyboard = doKeyboard_subgroups(subgroups, 'setrules', true)
				local text = _("%s\n<b>Applied to</b>: %s"):format(msg.original_text, db:hget('realm:'..msg.chat.id..':subgroups', blocks[2]):escape_html() or 'error')
				api.editMessageText(msg.chat.id, msg.message_id, text, 'html', keyboard)
				api.answerCallbackQuery(msg.cb_id, _('Applied'))
			elseif blocks[2] == 'all' then
				local has_subgroups = subgroups_iterator(msg.chat.id, setrules_subgroup, {rules = rules})
				api.editMessageText(msg.chat.id, msg.message_id, _('Rules applied to every group'))
			end
		end
	end
	if blocks[1] == 'adminlist' then
		local text
		local subgroup_id = blocks[2]
		local creator, adminlist = misc.getAdminlist(subgroup_id)
		if not creator then
			if adminlist == 429 then
				text = _('Too many requests. Please wait some minutes and try again. Note that if you flood this command, I\'ll leave the group and block you')
			else
				text = _('An unexpected error with the api occurred. Please try again later')
			end
		else
			text = _("<b>Creator</b>:\n%s\n\n<b>Admins</b>:\n%s"):format(creator, adminlist)
		end
		api.editMessageText(msg.chat.id, msg.message_id, text, 'html')
	end
	if blocks[1] == 'groupid' then
		local subgroup_name = db:hget('realm:'..msg.chat.id..':subgroups', blocks[2])
		if subgroup_name then
			api.editMessageText(msg.chat.id, msg.message_id, _('ID of %s:'):format(subgroup_name))
		end
		api.sendMessage(msg.chat.id, ('`%s`'):format(blocks[2]), true)
	end
	if blocks[1] == 'send' then
		local text_to_send = db:get('temp:realm:'..msg.chat.id..':send')
		if not text_to_send then
			api.editMessageText(msg.chat.id, msg.message_id, _('_Expired_'), true)
		else
			if blocks[2]:match('^-%d+$') then
				local res, motivation = api.sendMessage(blocks[2], text_to_send, true)
				if res then
					api.editMessageText(msg.chat.id, msg.message_id, _('*Message sent*'), true)
				else
					api.answerCallbackQuery(msg.cb_id, _('I can\'t send the text\nMotivation: %s'):format(motivation), true)
				end
			elseif blocks[2] == 'all' then
				local has_subgroups, i = subgroups_iterator(msg.chat.id, sendmessage_subgroup, {text = text_to_send})
				api.editMessageText(msg.chat.id, msg.message_id, _('Message sent in *%d* groups'):format(i), true)
			end
		end
	end
	if blocks[1] == 'remsubgroup' then
		if not roles.is_owner_cached(msg) then
			api.answerCallbackQuery(msg.cb_id, _('_Only the realm owner can remove a group_'), true)
		else
			local subgroup_info = unpair_group(msg.chat.id, blocks[2])
			local subgroups = db:hgetall('realm:'..msg.chat.id..':subgroups')
			if not next(subgroups) then
				api.editMessageText(msg.chat.id, msg.message_id, '_No groups paired_', true)
			else
				local keyboard = doKeyboard_subgroups(subgroups, 'remove')
				local group_label = blocks[2]
				if subgroup_info.title then group_label = subgroup_info.title end
				api.editMessageText(msg.chat.id, msg.message_id, _('%s removed from your subgroups'):format(group_label), false, keyboard)
			end
		end
	end
	if blocks[1] == 'delrealm' then
		if blocks[2] == 'yes' then
			local count = remRealm(msg.chat.id)
			local text = _('As you wish. This group is no longer a realm.')
			if count and count.total then
				text = text .._('\n_%d associations with subgroups have been deleted_'):format(count.total)
			end
			api.editMessageText(msg.chat.id, msg.message_id, text, true)
		elseif blocks[2] == 'no' then
			api.editMessageText(msg.chat.id, msg.message_id, _('_Action aborted_'), true)
		end
	end
	if blocks[1] == 'config' then
		local subgroup_id = blocks[2]
		local reply_markup = doKeyboard_config(subgroup_id)
		api.editMessageText(msg.chat.id, msg.message_id, _('Manage your group settings from this keyboard'), nil, reply_markup)
	end
	if blocks[1] == 'pin' then
		local text_to_pin = db:get('temp:realm:'..msg.chat.id..':pin')
		if not text_to_pin then
			api.editMessageText(msg.chat.id, msg.message_id, _('_Expired_'), true)
		else
			if blocks[2]:match('^-%d+$') then
				local subgroup_id = blocks[2]
				local pin_id = db:get('chat:'..subgroup_id..':pin')
				if not pin_id then
					api.answerCallbackQuery(msg.cb_id, _("I'm sorry, this group doesn't have any message generated by /pin"), true)
				else
					local res, code = api.editMessageText(subgroup_id, pin_id, text_to_pin, true) --try to edit
					if not res then
						local error_text = _("_I'm sorry, the last message genereted with /pin does not exists anymore_")
						if code == 111 then
							error_text = _("_The text you sent me is the same of the old pinned message_")
						end
						api.editMessageText(msg.chat.id, msg.message_id, error_text, true)
					else
						local subgroups = db:hgetall('realm:'..msg.chat.id..':subgroups')
						local keyboard = doKeyboard_subgroups(subgroups, 'pin', true)
						local text = _("%s\n<b>Applied to</b>: %s"):format(msg.original_text, db:hget('realm:'..msg.chat.id..':subgroups', blocks[2]) or 'error')
						api.editMessageText(msg.chat.id, msg.message_id, text, 'html', keyboard)
						api.answerCallbackQuery(msg.cb_id, _('Applied'))
					end
				end
			elseif blocks[2] == 'all' then
				local has_subgroups, applied_to_n = subgroups_iterator(msg.chat.id, pin_subgroup, {text_to_pin = text_to_pin})
				api.editMessageText(msg.chat.id, msg.message_id, _('Pinned message edited in %d groups. If this number is lower than expected, it means that in some subgroups the last message generated with /pin has been deleted'):format(applied_to_n or 0))
			end
		end
	end
	if blocks[1] == 'setlog' then
		local channel_id = blocks[2]
		if blocks[3]:match('^-%d+$') then
			local callback_answer_text
			local subgroup_id = blocks[3]
			local old_log =  db:hget('bot:chatlogs', subgroup_id)
			print(channel_id, old_log)
			if old_log == channel_id then
	    		api.answerCallbackQuery(msg.cb_id, _('This group is already using this channel'), true)
	    	else
	    		db:hset('bot:chatlogs', subgroup_id, channel_id)
	    		api.answerCallbackQuery(msg.cb_id, _('Log channel added!'), true)
	    		if old_log then
	    			api.sendMessage(old_log, _("<i>%s</i> changed its log channel.\n<i>From a realm, by %s</i>"):format(msg.chat.title:escape_html(), misc.getname_final(msg.from)), 'html')
	    		end
	    		api.sendMessage(channel_id, _("Logs of <i>%s</i> will be posted here.\n<i>From a realm, by %s</i>"):format(msg.chat.title:escape_html(), misc.getname_final(msg.from)), 'html')
	    		local text = _("%s\n<b>Applied to</b>: %s"):format(msg.original_text, db:hget('realm:'..msg.chat.id..':subgroups', subgroup_id):escape_html() or _("<i>undefined</i>"))
	    		local subgroups = db:hgetall(('realm:%d:subgroups'):format(msg.chat.id))
				local reply_markup = doKeyboard_subgroups(subgroups, ('setlog:%s'):format(channel_id), true)
				api.editMessageText(msg.chat.id, msg.message_id, text, 'html', reply_markup)
			end
		elseif blocks[3] == 'all' then
			local has_subgroups, n = subgroups_iterator(msg.chat.id, setlog_subgroup, {channel_id = channel_id})
			api.editMessageText(msg.chat.id, msg.message_id, _('The channel will be used by %d more subgroups.\n<i>If this number is lower than expected, it means that all the other subgroups were already using that channel as log</i>'):format(n or 0), 'html')
		end
	end
end

function plugin.onTextMessage(msg, blocks)
	if blocks[1] == 'setrealm' and blocks[2] then
		if roles.is_owner_cached(msg) then
			if is_realm(msg.chat.id) then
				api.sendReply(msg, _('_This group is a realm, you can set a realm for a realm_'), true)
			else
				local text
				if not is_realm(blocks[2]) then
					text = _('<i>The id you sent doesn\'t belong to a realm</i>')
				else
					local realm = blocks[2]
					local subgroup = msg.chat.id
					local subgroups_number = get_subgroups_number(realm)
					if subgroups_number >= config.bot_settings.realm_max_subgroups then
						text = _('This realm [<code>%s</code>] already reached the max [<code>%d</code>] number of subgroups'):format(realm, subgroups_number)
					else
						local old_realm = db:get('chat:'..subgroup..':realm')
						
						db:set('chat:'..subgroup..':realm', realm)
						db:hset('realm:'..realm..':subgroups', subgroup, msg.chat.title)
						local text_to_send_realm = _('<b>New subgroup added</b>: %s [<code>%d</code>]\n<b>By</b>: %s [@%s][#id%d]'):format(msg.chat.title:escape_html(), msg.chat.id, msg.from.first_name:escape_html(), msg.from.username or '-', msg.from.id)
						if old_realm and old_realm ~= realm then
							db:hdel('realm:'..old_realm..':subgroups', msg.chat.id)
							text = _('The realm of this group changed: <code>%s</code>`'):format(realm)
							api.sendMessage(realm, text_to_send_realm, 'html')
						else
							if realm == old_realm then
								text = _('<i>Already a sub-group of:</i> <code>%s</code>'):format(realm)
							else
								text = _('<b>Group added to the sub-groups of</b>: <code>%s</code>'):format(realm)
								api.sendMessage(realm, text_to_send_realm, 'html')
							end
						end
					end
				end
				api.sendReply(msg, text, 'html')
			end
		end
		return
	end
	if blocks[1] == 'setrealm' and not blocks[2] then
		if is_realm(msg.chat.id) then
			api.sendReply(msg, _('This group is already a realm.\n*Realm id*: `%s`'):format(msg.chat.id), true)
		else
			if not roles.is_owner_cached(msg) then
				api.sendReply(msg, _('_Only the owner can decide to use this group as a realm_'), true)
			else
				if msg.chat.username then
					api.sendReply(msg, _('_I\'m sorry, a public group can\'t be used as realms_'), true)
				else
					local n_members = api.getChatMembersCount(msg.chat.id)
					if not n_members then
						api.sendReply(msg, _('_I\'m sorry, I can\'t get the number of the members of this group now. Try again later_'), true)
					else
						n_members = n_members.result
						if n_members > config.bot_settings.realm_max_members then
							api.sendReply(msg, _('_You can\'t use as realm a group with more than %d members_'):format(config.bot_settings.realm_max_members), true)
						else
							misc.remGroup(msg.chat.id, true, true) --remove all the info that a realm doesn't need
							db:sadd('bot:realms', msg.chat.id)
							api.sendReply(msg, _('This group can now be used as realm: the members of this group can now manage multiple groups from here. To add a sub-group, the group owner must write in the chat:\n"/setrealm %s". He can copy-paste in the group the following text:'):format(msg.chat.id))
							api.sendMessage(msg.chat.id, '`/setrealm '..msg.chat.id..'`', true)
						end
					end
				end
			end
		end
		return
	end
	if blocks[1] == 'delrealm' then
		if is_realm(msg.chat.id) then
			if not roles.is_owner_cached(msg) then
				api.sendReply(msg, _('_This command can be used only by the group owner_'), true)
			else
				local text = _('_This group is no longer going to be used as a realm, and you will lose all the associations with your subgroups._\n*Do you want to continue?*')
				local reply_markup = {inline_keyboard={{{text = 'YES', callback_data = 'realm:delrealm:yes'}, {text = 'NO', callback_data = 'realm:delrealm:no'}}}}
				api.sendReply(msg, text, true, reply_markup)
			end
		end
	end
	if blocks[1] == 'unpair' then
		if roles.is_owner_cached(msg) then
			local text
			if is_realm(msg.chat.id) then
				text = _('<i>This group is a realm, you can use this command only in one subgroup</i>')
			else
				local realm_id = db:get('chat:'..msg.chat.id..':realm')
				if realm_id then
					db:del('chat:'..msg.chat.id..':realm')
					db:hdel('realm:'..realm_id..':subgroups', msg.chat.id)
					text = _("Done. This group does no longer belong to <code>%s</code>"):format(tostring(realm_id))
					local text_realm = _([[<i>A group has been removed from your subgroups</i>
<b>Title</b>: %s
<b>ID</b>: <code>%d</code>
<b>By</b>: %s [@%s] [#id%d] ]]):format(msg.chat.title:escape_html(), msg.chat.id, msg.from.first_name:escape_html(), msg.from.username or '-', msg.from.id)
					api.sendMessage(realm_id, text_realm, 'html')
				else
					text = _("<i>You are not associated with any realm</i>")
				end
			end
			api.sendReply(msg, text, 'html')
		end
	end
	if blocks[1] == 'new_chat_title' and msg.service then
		local realm_id = get_realm_id(msg.chat.id)
		if realm_id then
			db:hset('realm:'..realm_id..':subgroups', msg.chat.id, msg.chat.title)
		end
		return
	end
	if blocks[1] == 'myrealm' then
		if roles.is_admin_cached(msg) then
			local text
			local realm_id = db:get('chat:'..msg.chat.id..':realm')
			if not realm_id then
				text = _('This group is not paired with any realm')
			else
				local in_the_general_list = (tostring(db:sismember('bot:realms', realm_id))) or 'false'
				local saved_as = (db:hget('realm:'..realm_id..':subgroups', msg.chat.id)) or '-'
				text = _('<b>Paired with</b>: %s\n<b>Saved as</b>: %s\n<b>Realm in the global list</b>: %s'):format(tostring(realm_id), saved_as:escape_html(), in_the_general_list)
			end
			api.sendReply(msg, text, 'html')
		end
	end
	if blocks[1] == 'add' then
		if is_realm(msg.chat.id) then
			local text = _('To add a group to the administrated group of this chat, the *owner of the group* have to copy-paste the following message in the group you want to add:')
			api.sendReply(msg, text, true)
			api.sendMessage(msg.chat.id, ('`/setrealm %d`'):format(msg.chat.id), true)
		end
	end
	
	if not is_realm(msg.chat.id) then return true end
	local subgroups = db:hgetall('realm:'..msg.chat.id..':subgroups')
	if not next(subgroups) then
		api.sendReply(msg, _('_I\'m sorry, this realm doesn\'t have subgroups paired with it_'), true) return
	end
	
	if blocks[1] == 'pin' then
		local res, code = api.sendReply(msg, blocks[2], true)
		if not res then
			local text = misc.get_sm_error_string(code)
			api.sendReply(msg, text, true)
		else
			local keyboard = doKeyboard_subgroups(subgroups, 'pin', true)
			db:setex('temp:realm:'..msg.chat.id..':pin', 1800, blocks[2])
			api.editMessageText(msg.chat.id, res.result.message_id, 'Choose the group where apply the rules (choose <b>within 30 minutes from now</b>)', 'html', keyboard)
		end
	end
	if blocks[1] == 'setlog' then
		if msg.forward_from_chat then
			if msg.forward_from_chat.type == 'channel' then
				if not msg.forward_from_chat.username then
					local res, code = api.getChatMember(msg.forward_from_chat.id, msg.from.id)
					if not res then
						if code == 429 then
							api.sendReply(msg, _('_Too many requests. Retry later_'), true)
						else
							api.sendReply(msg, _('_I need to be admin in the channel_'), true)
						end
					else
						if res.result.status == 'creator' then
							local reply_markup = doKeyboard_subgroups(subgroups, ('setlog:%d'):format(msg.forward_from_chat.id), true)
							api.sendMessage(msg.chat.id, _('Select one or more groups that will use that channel as log channel'), true, reply_markup)
						else
							api.sendReply(msg, _('_Only the channel creator can pair a chat with a channel_'), true)
						end
					end
				else
					api.sendReply(msg, _('_I\'m sorry, only private channels are supported for now_'), true)
				end
			end
		else
			api.sendReply(msg, _('You must *forward* the message from the channel you want to use'), true)
		end
	end
	if blocks[1] == 'config' then
		local reply_markup = doKeyboard_subgroups(subgroups, 'config')
		api.sendMessage(msg.chat.id, _('Select a group to manage its settings'), nil, reply_markup)
	end
	if blocks[1] == 'subgroups' then
		local body = ''
		local n = 0
		for id, name in pairs(subgroups) do
			n = n + 1
			body = body..n..' - <code>'..name:escape_html()..'</code>\n'
		end
		local text = _('<b>Your subgroups</b>:\n\n')..body
		api.sendMessage(msg.chat.id, text, 'html')
	end
	if blocks[1] == 'remove' then
		local keyboard = doKeyboard_subgroups(subgroups, 'remsubgroup')
		api.sendMessage(msg.chat.id, _('Choose the subgroup you want to un-pair:'), false, keyboard)
	end
	if blocks[1] == 'realm' then
		local n, total_members = 0, 0
		for subgroup_id, v in pairs(subgroups) do
			n = n + 1
			local n_members = api.getChatMembersCount(subgroup_id)
			if n_members then
				total_members = total_members + n_members.result
			end
		end
		local text = _('<b>Title</b>: %s\n<b>ID</b>: %d\n<b>Subgroups n°</b>: %d\n<b>Total members</b>: %d'):format(msg.chat.title:escape_html(), msg.chat.id, n, total_members)
		api.sendReply(msg, text, 'html')
	end
	if blocks[1] == 'setrules' then
		local res, code = api.sendReply(msg, blocks[2], true)
		if not res then
			local text = misc.get_sm_error_string(code)
			api.sendReply(msg, text, true)
		else
			local keyboard = doKeyboard_subgroups(subgroups, 'setrules', true)
			db:setex('temp:realm:'..msg.chat.id..':setrules', 1800, blocks[2])
			api.editMessageText(msg.chat.id, res.result.message_id, _('Choose the group where apply the rules (choose <b>within 30 minutes from now</b>)'), 'html', keyboard)
		end
	end
	if blocks[1] == 'ban' then
		local user_id
		if blocks[2] then
			user_id, error_message = realm_get_userid(blocks[2])
		else
			if msg.reply then
				if not msg.reply.forward_from then
					api.sendReply(msg, _('_Answer to a forwarded message_'), true) return
				else
					user_id = msg.reply.forward_from.id
				end
			end
		end
		
		if not user_id and error_message then
			api.sendMessage(msg.chat.id, error_message)
		else
			local failed = {limits = 0, not_admin = 0, is_admin = 0, others = 0, names = ''}
			local success = 0
			for subgroup_id, subgroup_name in pairs(subgroups) do
				local res, code = api.banUser(subgroup_id, user_id)
				if not res then
					print(code)
					if code == 429 then
						failed.limits = failed.limits + 1
					elseif code == 101 then
						failed.not_admin = failed.not_admin + 1 --the bot can't kick because it's not admin
					elseif code == 102 then
						failed.is_admin = failed.is_admin + 1 --trying to kick an admin
					else
						failed.others = failed.others + 1
					end
					failed.names = failed.names..'- '..subgroup_name..'\n'
				else
					success = success + 1
				end
			end
			
			local text = _([[Executed.

<b>Success</b>: <code>%d</code>
<b>The bot is not admin</b>: <code>%d</code>
<b>The user is admin</b>: <code>%d</code>
<b>Failed because of limits</b>: <code>%d</code>
<b>Failed because of other reasons</b>: <code>%d</code>
<b>Failed to ban from</b>:
%s]])
			api.sendReply(msg, text:format(success, failed.not_admin, failed.is_admin, failed.limits, failed.others, failed.names:escape_html()), 'html')
		end
	end
	if blocks[1] == 'adminlist' then
		local keyboard = doKeyboard_subgroups(subgroups, 'adminlist')
		api.sendMessage(msg.chat.id, 'Choose a group to see the list of the admins', false, keyboard)
	end
	if blocks[1] == 'id' then
		local reply_markup = doKeyboard_subgroups(subgroups, 'groupid')
		api.sendMessage(msg.chat.id, 'Choose a subgroup to get its Telegram ID', false, reply_markup)
	end
	if blocks[1] == 'send' then
		local res, code = api.sendReply(msg, blocks[2], true)
		if not res then
			local text = misc.get_sm_error_string(code)
			api.sendReply(msg, text, true)
		else
			local keyboard = doKeyboard_subgroups(subgroups, 'send', true)
			db:setex('temp:realm:'..msg.chat.id..':send', 1800, blocks[2])
			api.editMessageText(msg.chat.id, res.result.message_id, 'Choose the group where I have to send the message *within 30 minutes from now*', true, keyboard)
		end
	end
	if blocks[1] == 'log' then
		local text = {_('<i>Log channels used by your subgroups</i>:\n\n')}
		local log_id
		for subgroup_id, subgroup_name in pairs(subgroups) do
			log_id = db:hget('bot:chatlogs', subgroup_id) or '/'
			text[#text+1] = ("<b>%s</b>: <code>%s</code>"):format(subgroup_name, log_id)
			text[#text+1] = '\n'
		end
		text = table.concat(text)
		api.sendReply(msg, text, 'html')
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(setrealm)$',
		config.cmd..'(setrealm) (-%d+)$',
		config.cmd..'(subgroups)$',
		config.cmd..'(remove)$',
		config.cmd..'(adminlist)$',
		config.cmd..'(ban)$',
		config.cmd..'(ban) (.*)$',
		config.cmd..'(setrules) (.*)$',
		config.cmd..'(send) (.*)$',
		config.cmd..'(delrealm)$',
		config.cmd..'(myrealm)$',
		config.cmd..'(unpair)$',
		config.cmd..'(realm)$',
		config.cmd..'(config)$',
		config.cmd..'(add)$',
		config.cmd..'(id)$',
		config.cmd..'(log)s?$',
		config.cmd..'(pin) (.*)$',
		'^/(setlog)$',
		'^###(new_chat_title)$'
	},
	onCallbackQuery = {
		'^###cb:realm:(cancel)$',
		'^###cb:realm:(%w+):(-%d+):(-%d+)$',
		'^###cb:realm:(%w+):(-%d+):(all)$',
		'^###cb:realm:(%w+):(-%d+)$',
		'^###cb:realm:(%w+):(all)$',
		'^###cb:realm:(%w+):(%a+)$',
	}
}

return plugin