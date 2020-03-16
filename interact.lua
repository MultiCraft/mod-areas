local S = intllib.make_gettext_pair()

local old_is_protected = minetest.is_protected

local disallowed = {
	["^[A-Za-z]+[0-9][0-9][0-9]"] = "You play using an unofficial client. Your actions are limited. "..
			"Download \"MultiCraft ― Build and Mine!\" on Google Play / App Store to play ad-free!"
}

local function old_version(name)
	local info = minetest.get_player_information(name)
	if info and info.version_string and info.version_string < "0.4.16" then
		return true
	end
end

-- Disable some actions for Guests
function minetest.is_protected_action(pos, name)
	for r, reason in pairs(disallowed) do
		if name:lower():find(r) then
			if old_version(name) then
				minetest.chat_send_player(name, reason)
				return true
			end
		end
	end

	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

--==--

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
			(S("%s is protected by %s.")):format(
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))

		-- Little damage player
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			local hp = player:get_hp()
			if hp and hp > 1 then
				player:set_hp(hp - 1)
			end
		end
	end
end)
