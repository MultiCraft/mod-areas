-- Areas mod by ShadowNinja
-- Based on node_ownership
-- License: LGPLv3+

areas = {}

local S = minetest.get_translator_auto({"ru"})

areas.S = S

areas.adminPrivs = {areas = true}
areas.startTime = os.clock()

areas.modpath = minetest.get_modpath("areas")
dofile(areas.modpath.."/settings.lua")
dofile(areas.modpath.."/api.lua")
dofile(areas.modpath.."/internal.lua")
dofile(areas.modpath.."/chatcommands.lua")
dofile(areas.modpath.."/pos.lua")
dofile(areas.modpath.."/interact.lua")
dofile(areas.modpath.."/hud.lua")
dofile(areas.modpath.."/protector.lua")

areas:load()

minetest.register_privilege("areas", {
	description = S("Can administer areas."),
	give_to_singleplayer = false
})
minetest.register_privilege("areas_high_limit", {
	description = S("Can protect more, bigger areas."),
	give_to_singleplayer = false
})

if not minetest.registered_privileges[areas.config.self_protection_privilege] then
	minetest.register_privilege(areas.config.self_protection_privilege, {
		description = S("Can protect areas.")
	})
end

if minetest.settings:get_bool("log_mods") then
	local diffTime = os.clock() - areas.startTime
	minetest.log("action", "areas loaded in " .. diffTime .. "s.")
end
