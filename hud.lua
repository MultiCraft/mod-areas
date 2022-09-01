-- This is inspired by the landrush mod by Bremaweb

local S = areas.S

areas.hud = {}

local vround = vector.round
local tconcat, tinsert = table.concat, table.insert

local function update_hud(player, name, pos)
	local areaStrings = {}
	local getAreasAtPos = areas:getAreasAtPos(pos)

	for id, area in pairs(getAreasAtPos) do
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

	if areas.invite_code then
		areaStrings[#areaStrings + 1] = areas.invite_code
	end

	if next(getAreasAtPos) then
		tinsert(areaStrings, 1, S("Areas:"))
	end

	local areaString = tconcat(areaStrings, "\n")
	local hud = areas.hud[name]
	if not hud then
		hud = {}
		areas.hud[name] = hud
		hud.areasId = player:hud_add({
			hud_elem_type = "text",
			name		= "Areas",
			number		= 0xFFFFFF,
			position	= {x = 0,   y =  1},
			offset		= {x = 8,   y = -8},
			scale		= {x = 200, y = 60},
			alignment	= {x = 1,   y = -1},
			text		= areaString
		})
		hud.oldAreas = areaString
	elseif hud.oldAreas ~= areaString then
		player:hud_change(hud.areasId, "text", areaString)
		hud.oldAreas = areaString
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
