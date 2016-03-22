URL = require "socket.url"
http = require "socket.http"
https = require "ssl.https"
ltn12 = require "ltn12"
serpent = require "serpent"
feedparser = require "feedparser"

json = (loadfile "./libs/JSON.lua")()
mimetype = (loadfile "./libs/mimetype.lua")()
redis = kos nanat
  local data = load_data(_config.moderation.data)
  local user = msg.from.id
  
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['set_owner'] then
      if data[tostring(msg.to.id)]['set_owner'] == tostring(user) then
        var = true
      end
    end
  end

  if data['admins'] then
    if data['admins'][tostring(user)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
        var = true
    end
  end
  return var
end

function is_owner2(user_id, group_id)
  local var = false
  local data = load_data(_config.moderation.data)

  if data[tostring(group_id)] then
    if data[tostring(group_id)]['set_owner'] then
      if data[tostring(group_id)]['set_owner'] == tostring(user_id) then
        var = true
      end
    end
  end
  
  if data['admins'] then
    if data['admins'][tostring(user_id)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
        var = true
    end
  end
  return var
end

--Check if user is admin or not
function is_admin(msg)
  local var = false
  local data = load_data(_config.moderation.data)
  local user = msg.from.id
  local admins = 'admins'
  if data[tostring(admins)] then
    if data[tostring(admins)][tostring(user)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
        var = true
    end
  end
  return var
end

function is_admin2(user_id)
  local var = false
  local data = load_data(_config.moderation.data)
  local user = user_id
  local admins = 'admins'
  if data[tostring(admins)] then
    if data[tostring(admins)][tostring(user)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == user_id then
        var = true
    end
  end
  return var
end



--Check if user is the mod of that group or not
function is_momod(msg)
  local var = false
  local data = load_data(_config.moderation.data)
  local user = msg.from.id
  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['moderators'] then
      if data[tostring(msg.to.id)]['moderators'][tostring(user)] then
        var = true
      end
    end
  end

  if data[tostring(msg.to.id)] then
    if data[tostring(msg.to.id)]['set_owner'] then
      if data[tostring(msg.to.id)]['set_owner'] == tostring(user) then
        var = true
      end
    end
  end

  if data['admins'] then
    if data['admins'][tostring(user)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == msg.from.id then
        var = true
    end
  end
  return var
end

function is_momod2(user_id, group_id)
  local var = false
  local data = load_data(_config.moderation.data)
  local usert = user_id
  if data[tostring(group_id)] then
    if data[tostring(group_id)]['moderators'] then
      if data[tostring(group_id)]['moderators'][tostring(usert)] then
        var = true
      end
    end
  end

  if data[tostring(group_id)] then
    if data[tostring(group_id)]['set_owner'] then
      if data[tostring(group_id)]['set_owner'] == tostring(user_id) then
        var = true
      end
    end
  end
  
  if data['admins'] then
    if data['admins'][tostring(user_id)] then
      var = true
    end
  end
  for v,user in pairs(_config.sudo_users) do
    if user == usert then
        var = true
    end
  end
  return var
end

-- Returns the name of the sender
function kick_user(user_id, chat_id) 
  if tonumber(user_id) == tonumber(our_id) then -- Ignore bot
    return
  end
  if is_owner2(user_id, chat_id) then -- Ignore admins
    return
  end
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

-- Ban
function ban_user(user_id, chat_id)
  if tonumber(user_id) == tonumber(our_id) then -- Ignore bot
    return
  end
  if is_admin2(user_id) then -- Ignore admins
    return
  end
  -- Save to redis
  local hash =  'banned:'..chat_id
  redis:sadd(hash, user_id)
  -- Kick from chat
  kick_user(user_id, chat_id)
end
-- Global ban
function banall_user(user_id)  
  if tonumber(user_id) == tonumber(our_id) then -- Ignore bot
    return
  end
  if is_admin2(user_id) then -- Ignore admins
    return
  end
  -- Save to redis
  local hash =  'gbanned'
  redis:sadd(hash, user_id)
end
-- Global unban
function unbanall_user(user_id)
  --Save on redis  
  local hash =  'gbanned'
  redis:srem(hash, user_id)
end

-- Check if user_id is banned in chat_id or not
function is_banned(user_id, chat_id)
  --Save on redis  
  local hash =  'banned:'..chat_id
  local banned = redis:sismember(hash, user_id)
  return banned or false
end

-- Check if user_id is globally banned or not
function is_gbanned(user_id)
  --Save on redis
  local hash =  'gbanned'
  local banned = redis:sismember(hash, user_id)
  return banned or false
end

-- Returns chat_id ban list
function ban_list(chat_id)
  local hash =  'banned:'..chat_id
  local list = redis:smembers(hash)
  local text = "Ban list !\n\n"
  for k,v in pairs(list) do
 		local user_info = redis:hgetall('user:'..v)
		if user_info and user_info.print_name then
   	text = text..k.." - "..string.gsub(user_info.print_name, "_", " ").." ["..v.."]\n"
  	else 
    text = text..k.." - "..v.."\n"
		end
	end
 return text
end

-- Returns globally ban list
function banall_list() 
  local hash =  'gbanned'
  local list = redis:smembers(hash)
  local text = "global bans !\n\n"
  for k,v in pairs(list) do
		 		local user_info = redis:hgetall('user:'..v)
		if user_info and user_info.print_name then
   	text = text..k.." - "..string.gsub(user_info.print_name, "_", " ").." ["..v.."]\n"
  	else 
    text = text..k.." - "..v.."\n"
		end
	end
 return text
end

-- /id by reply
function get_message_callback_id(extra, success, result)
    if result.to.type == 'chat' then
        local chat = 'chat#id'..result.to.id
        send_large_msg(chat, result.from.id)
    else
        return 'Use This in Your Groups'
    end
end

-- kick by reply for mods and owner
function Kick_by_reply(extra, success, result)
  if result.to.type == 'chat' then
    local chat = 'chat#id'..result.to.id
    if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't kick myself"
    end
    if is_momod2(result.from.id, result.to.id) then -- Ignore mods,owner,admin
      return "you can't kick mods,owner and admins"
    end
    chat_del_user(chat, 'user#id'..result.from.id, ok_cb, false)
  else
    return 'Use This in Your Groups'
  end
end

-- Kick by reply for admins
function Kick_by_reply_admins(extra, success, result)
  if result.to.type == 'chat' then
    local chat = 'chat#id'..result.to.id
    if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't kick myself"
    end
    if is_admin2(result.from.id) then -- Ignore admins
      return
    end
    chat_del_user(chat, 'user#id'..result.from.id, ok_cb, false)
  else
    return 'Use This in Your Groups'
  end
end

--Ban by reply for admins
function ban_by_reply(extra, success, result)
  if result.to.type == 'chat' then
  local chat = 'chat#id'..result.to.id
  if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't ban myself"
  end
  if is_momod2(result.from.id, result.to.id) then -- Ignore mods,owner,admin
    return "you can't kick mods,owner and admins"
  end
  ban_user(result.from.id, result.to.id)
  send_large_msg(chat, "User "..result.from.id.." Banned")
  else
    return 'Use This in Your Groups'
  end
end

-- Ban by reply for admins
function ban_by_reply_admins(extra, success, result)
  if result.to.type == 'chat' then
    local chat = 'chat#id'..result.to.id
    if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't ban myself"
    end
    if is_admin2(result.from.id) then -- Ignore admins
      return
    end
    ban_user(result.from.id, result.to.id)
    send_large_msg(chat, "User "..result.from.id.." Banned")
  else
    return 'Use This in Your Groups'
  end
end

-- Unban by reply
function unban_by_reply(extra, success, result) 
  if result.to.type == 'chat' then
    local chat = 'chat#id'..result.to.id
    if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't unban myself"
    end
    send_large_msg(chat, "User "..result.from.id.." Unbanned")
    -- Save on redis
    local hash =  'banned:'..result.to.id
    redis:srem(hash, result.from.id)
  else
    return 'Use This in Your Groups'
  end
end
function banall_by_reply(extra, success, result)
  if result.to.type == 'chat' then
    local chat = 'chat#id'..result.to.id
    if tonumber(result.from.id) == tonumber(our_id) then -- Ignore bot
      return "I won't banall myself"
    end
    if is_admin2(result.from.id) then -- Ignore admins
      return 
    end
    local name = user_print_name(result.from)
    banall_user(result.from.id)
    chat_del_user(chat, 'user#id'..result.from.id, ok_cb, false)
    send_large_msg(chat, "User "..name.."["..result.from.id.."] hammered")
  else
    return 'Use This in Your Groups'
  end
end
Kos
