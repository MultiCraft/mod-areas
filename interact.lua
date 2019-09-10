local old_is_protected = minetest.is_protected

local disallowed = {
	["^[A-Za-z]+[0-9][0-9][0-9]"] = "You play using an unofficial client. Your actions are limited. "..
			"Download \"MultiCraft ― Build and Mine!\" on Google Play / App Store to play ad-free!"
}

-- Disable some actions for Guests
function minetest.is_protected_action(pos, name)
	local lname = name:lower()
	for re, reason in pairs(disallowed) do
		if lname:find(re) then
			minetest.chat_send_player(name, reason)
			return true
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
			("%s is protected by %s."):format(
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))
	end
end)

