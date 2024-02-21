local S = areas.S

local enable_damage = minetest.settings:get_bool("enable_damage")

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

local tconcat = table.concat
minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			S("@1 is protected by @2.",
				minetest.pos_to_string(pos),
				tconcat(owners, ", ")))

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
	if time_from_last_punch < 0.25 then
		minetest.chat_send_player(player_name, S("Wow, wow, take it easy!"))
		return true
	end

	-- Allow PvP if both players are in a PvP area
	if can_pvp_at(hitter:get_pos()) and can_pvp_at(player:get_pos()) then
		return false
	end

	-- Otherwise, it doesn't do damage
	minetest.chat_send_player(player_name, S("PvP is not allowed in this area!"))
	return true
end)

local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, hitter, time_from_last_punch, ...)
	if player:is_player() and hitter and hitter:is_player() and
			(time_from_last_punch < 0.25 or not can_pvp_at(player:get_pos()) or
			not can_pvp_at(hitter:get_pos())) then
		return 0
	end
	return old_calculate_knockback(player, hitter, time_from_last_punch, ...)
end
