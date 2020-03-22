-- This is inspired by the landrush mod by Bremaweb

local S = intllib.make_gettext_pair()

areas.hud = {}

hud.register("areas", {
	hud_elem_type = "text",
	position      = {x = 0,   y =  1},
	alignment     = {x = 1,   y = -1},
	offset        = {x = 8,   y = -8},
	scale         = {x = 200, y = 60},
	text          = "",
	number        = 0xFFFFFF
})

minetest.register_playerstep(function(_, playernames)
	for _, name in pairs(playernames) do
		local player = minetest.get_player_by_name(name)
		if not player or not player:is_player() then return end
		local pos = vector.round(player:get_pos())
		pos = vector.apply(pos, function(p)
			return math.max(math.min(p, 2147483), -2147483)
		end)
		local areaStrings = {}

		for id, area in pairs(areas:getAreasAtPos(pos)) do
			table.insert(areaStrings, ("%s [%u] (%s%s)")
					:format(area.name, id, area.owner,
					area.open and ":open" or ""))
		end

		for i, area in pairs(areas:getExternalHudEntries(pos)) do
			local str = ""
			if area.name then str = area.name .. " " end
			if area.id then str = str.."["..area.id.."] " end
			if area.owner then str = str.."("..area.owner..")" end
			table.insert(areaStrings, str)
		end

		local areaString = ""
		if #areaStrings > 0 then
			areaString = S("Areas:")
			areaString = areaString.."\n"..
				table.concat(areaStrings, "\n")
		end

		if not areas.hud[name] then
			areas.hud[name] = {}
			hud.change_item(player, "areas", {text = areaString})
			areas.hud[name].oldAreas = areaString
			return
		elseif areas.hud[name].oldAreas ~= areaString then
			hud.change_item(player, "areas", {text = areaString})
			areas.hud[name].oldAreas = areaString
		end
	end
end, true) -- Force this callback to run every step for smoother animations

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)
