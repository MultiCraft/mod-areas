-- This is inspired by the landrush mod by Bremaweb

local S = areas.S

areas.hud = {}

local vround = vector.round
local tconcat = table.concat

hud.register("areas", {
	hud_elem_type = "text",
	position      = {x = 0,   y =  1},
	alignment     = {x = 1,   y = -1},
	offset        = {x = 8,   y = -8},
	scale         = {x = 200, y = 60},
	text          = "",
	number        = 0xFFFFFF
})

local function update_hud(player, name, pos)
	local areaStrings = {
		S("Areas:")
	}

	for id, area in pairs(areas:getAreasAtPos(pos)) do
		areaStrings[#areaStrings + 1] = ("%s [%u] (%s)%s%s")
			:format(area.name, id, area.owner,
				area.open and (" [" .. S("Open") .. "]") or "",
				area.canPvP and (" [" .. S("PvP enabled") .. "]") or "")
	end

	local str = ""
	for _, area in pairs(areas:getExternalHudEntries(pos)) do
		if area.name then str = area.name .. " " end
		if area.id then str = str .. "[" .. area.id .. "] " end
		if area.owner then str = str .. "(" .. area.owner .. ")" end
		areaStrings[#areaStrings + 1] = str
	end

	-- "Areas:" text has index 1
	local areaString = #areaStrings > 1 and tconcat(areaStrings, "\n") or ""

	local phud = areas.hud[name] or {}
	if not phud.oldAreas or phud.oldAreas ~= areaString then
		hud.change_item(player, "areas", {text = areaString})
		phud.oldAreas = areaString
	end
end

minetest.register_playerstep(function(_, playernames)
	for _, name in ipairs(playernames) do
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			local pos = vround(player:get_pos())
			if minetest.is_valid_pos(pos) then
				update_hud(player, name, pos)
			end
		end
	end
end, true) -- Force this callback to run every step to display actual information

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)
