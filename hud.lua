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
		if minetest.is_valid_pos(pos) then
			local areaStrings = {}

			for id, area in pairs(areas:getAreasAtPos(pos)) do
				areaStrings[#areaStrings+1] = ("%s [%u] (%s%s)")
					:format(area.name, id, area.owner,
						area.open and ":open" or "")
			end

			local str = ""
			for _, area in pairs(areas:getExternalHudEntries(pos)) do
				if area.name then str = area.name .. " " end
				if area.id then str = str .. "[" .. area.id .. "] " end
				if area.owner then str = str .. "(" .. area.owner .. ")" end
				areaStrings[#areaStrings+1] = str
			end

			local areaString = ""
			if #areaStrings > 0 then
				areaString = S("Areas:")
				areaString = areaString .. "\n" ..
					table.concat(areaStrings, "\n")
			end

			local phud = areas.hud[name] or {}
			if not phud.oldAreas or phud.oldAreas ~= areaString then
				hud.change_item(player, "areas", {text = areaString})
				phud.oldAreas = areaString
			end
		end
	end
end, true) -- Force this callback to run every step to display actual information

minetest.register_on_leaveplayer(function(player)
	areas.hud[player:get_player_name()] = nil
end)
