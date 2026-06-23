local S = areas.S

local enable_damage = minetest.settings:get_bool("enable_damage")

local COOLDOWN = math.max(0.05, areas.config.pvp_cooldown)

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		minetest.chat_send_player(name,
			S("This area @1 is protected by another player.", minetest.pos_to_string(pos)))

		-- Little damage player
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			if enable_damage then
				local hp = player:get_hp()
				if hp and hp > 2 then
					player:set_hp(hp - 2)
				end
			end
			local player_pos = player:get_pos()
			if pos.y <= player_pos.y then
				player_pos.y = player_pos.y + 1
				player:set_pos(player_pos)
			end
		end
	end
end)

local function can_pvp_at(pos)
	local default = areas.config.pvp_by_default
	for id in pairs(areas:getAreasAtPos(pos)) do
		-- This uses areas:canPvP instead of area.canPvP in case areas:canPvP
		-- is overridden
		local value = areas:canPvP(id)
		if value ~= default then
			return value
		end
	end
	return default
end

local function pvp_allowed(hitter, player)
	return can_pvp_at(hitter:get_pos()) and can_pvp_at(player:get_pos())
end

local punch_pvp = {
	hitter = nil, victim = nil, allowed = false, ms = 0
}
local last_kb = {}

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch)
	if not enable_damage then
		return true
	end

	-- If it's a mob, deal damage as usual
	if not hitter or not hitter:is_player() then
		return false
	end

	local player_name = hitter:get_player_name()

	-- It is possible to use cheats
	if time_from_last_punch < COOLDOWN then
		minetest.chat_send_player(player_name, S("Wow, wow, take it easy!"))
		return true
	end

	-- Allow PvP if both players are in a PvP area
	local allowed = pvp_allowed(hitter, player)
	punch_pvp.hitter = player_name
	punch_pvp.victim = player:get_player_name()
	punch_pvp.allowed = allowed
	punch_pvp.ms = minetest.get_us_time() / 1000
	if allowed then
		return false
	end

	-- Otherwise, it doesn't do damage
	minetest.chat_send_player(player_name, S("PvP is not allowed in this area!"))
	return true
end)

local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, hitter, time_from_last_punch, ...)
	if player:is_player() and hitter and hitter:is_player() then
		if time_from_last_punch < COOLDOWN then
			return 0
		end

		local now = minetest.get_us_time() / 1000
		local hname, vname = hitter:get_player_name(), player:get_player_name()

		local allowed
		if punch_pvp.hitter == hname and punch_pvp.victim == vname and
				(now - punch_pvp.ms) < 1 then
			allowed = punch_pvp.allowed
		else
			allowed = pvp_allowed(hitter, player)
		end
		if not allowed then
			return 0
		end

		local prev = last_kb[vname]
		if prev and (now - prev) < COOLDOWN * 1000 then
			return 0
		end
		last_kb[vname] = now
	end
	return old_calculate_knockback(player, hitter, time_from_last_punch, ...)
end

minetest.register_on_leaveplayer(function(player)
	last_kb[player:get_player_name()] = nil
end)
