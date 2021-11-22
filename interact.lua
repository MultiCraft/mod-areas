local S = areas.S

local enable_damage = minetest.settings:get_bool("enable_damage")

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			S("@1 is protected by @2.",
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))

		-- Little damage player
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			if enable_damage then
				local hp = player:get_hp()
				if hp and hp > 2 then
					player:set_hp(hp - 1)
				end
			end
			local player_pos = player:get_pos()
			if pos.y < player_pos.y then
				player:set_pos({
					x = player_pos.x,
					y = player_pos.y + 1,
					z = player_pos.z
				})
			end
		end
	end
end)

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

	local hitterInPvP
	-- Check if the hitter is in an area with allowed PvP
	local hitterAreas = areas:getAreasAtPos(hitter:get_pos())
	-- If the table is empty, PvP is not allowed
	if not next(hitterAreas) then
		return true
	end
	-- Do any of the areas have allowed PvP?
	for _, area in pairs(hitterAreas) do
		if area.canPvP then
			hitterInPvP = true
			break
		end
	end

	if hitterInPvP then
		-- Check if the victim is in an area with allowed PvP
		local victimAreas = areas:getAreasAtPos(player:get_pos())
		-- If the table is empty, PvP is not allowed
		if not next(victimAreas) then
			return true
		end
		-- Do any of the areas have allowed PvP?
		for _, area in pairs(victimAreas) do
			if area.canPvP then
				return false
			end
		end
	end

	-- Otherwise, it doesn't do damage
	minetest.chat_send_player(player_name, S("PvP is not allowed in this area!"))
	return true
end)
