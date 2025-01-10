local world_path = minetest.get_worldpath()

areas.config = {}

local function setting(tp, name, default)
	local full_name = "areas." .. name
	local value
	if tp == "boolean" then
		value = minetest.settings:get_bool(full_name)
	elseif tp == "string" then
		value = minetest.settings:get(full_name)
	elseif tp == "position" then
		value = minetest.setting_get_pos(full_name)
	elseif tp == "number" then
		value = tonumber(minetest.settings:get(full_name))
	else
		error("Cannot parse setting type " .. tp)
	end

	if value == nil then
		value = default
	end
	areas.config[name] = value
end

--------------
-- Settings --
--------------

setting("string",  "filename", world_path.."/areas.dat")
setting("boolean", "pvp_by_default", false)
setting("number",  "max_area_name_length", 40)

-- Allow players with a privilege create their own areas
-- within the maximum size and number.
setting("boolean",  "self_protection", true)
setting("string",   "self_protection_privilege", "interact")
setting("position", "self_protection_max_size", {x = 128, y = 128, z = 128})
setting("number",   "self_protection_max_areas", 16)
-- For players with the areas_high_limit privilege.
setting("position", "self_protection_max_size_high", {x = 512, y = 512, z = 512})
setting("number",   "self_protection_max_areas_high", 64)
