local S = intllib.make_gettext_pair()

local radius = minetest.settings:get("areasprotector_radius") or 8

local function cyan(str)
	return minetest.colorize("#7CFC00", str)
end

local function red(str)
	return minetest.colorize("#FF0000", str)
end

local vadd, vnew = vector.add, vector.new

minetest.register_node("areas:protector", {
	description = S("Protector Block"),
	tiles = {
		"default_stonebrick_carved.png",
		"default_stonebrick_carved.png",
		"default_stonebrick_carved.png^areas_protector_stone.png"
	},
	paramtype = "light",
	groups = {cracky = 1, not_cuttable = 1},
	node_placement_prediction = "",

	on_place = function(itemstack, player, pointed)
		local pos = pointed.above
		local pos1 = vadd(pos, vnew(radius, radius, radius))
		local pos2 = vadd(pos, vnew(-radius, -radius, -radius))
		local name = player:get_player_name()

		if not minetest.is_protected_action(pos, name) then
			local perm, err = areas:canPlayerAddArea(pos1, pos2, name)
			if not perm then
				minetest.chat_send_player(name, red(S("You are not allowed to protect that area: @1", err)))
				return itemstack
			end
			if minetest.find_node_near(pos, 4, {"areas:protector"}) then
				minetest.chat_send_player(name, red(S("You have already protected this area.")))
				return itemstack
			end
			
			local id = areas:add(name, S("Protector Block"), pos1, pos2)
			areas:save()
			minetest.chat_send_player(name,
				(S("The area from @1 to @1 has been protected as ID @1",
				cyan(minetest.pos_to_string(pos1)), cyan(minetest.pos_to_string(pos2)), cyan(id))))
			minetest.set_node(pos, {name = "areas:protector"})
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", (S("Protected area @1, Owned by @1", id, name)))
			meta:set_int("area_id", id)
			meta:set_string("owner", name)
			itemstack:take_item()
			return itemstack
		end
	end,

	after_dig_node = function(_, _, oldmetadata, digger)
		if oldmetadata and oldmetadata.fields then
			local owner = oldmetadata.fields.owner
			local id = tonumber(oldmetadata.fields.area_id)
			local name = digger:get_player_name()
			if areas.areas[id] and areas:isAreaOwner(id, owner) then
				areas:remove(id)
				areas:save()
				minetest.chat_send_player(name, (S("Removed area @1", cyan(id))))
			end
		end
	end,

	on_punch = function(pos)
		local objs = minetest.get_objects_inside_radius(pos, 0.5) -- a radius of 0.5 since the entity serialization seems to be not that precise
		local displayed = false
		for _, o in pairs(objs) do
			if not o:is_player() and o:get_luaentity().name == "areas:display" then
				o:remove()
				return
			end
		end
		if not displayed then -- nothing was removed: there wasn't the entity
			minetest.add_entity(pos, "areas:display")
		end
	end
})

-- entities code below (and above) mostly copied-pasted from Zeg9's protector mod

minetest.register_entity("areas:display", {
	physical = false,
	collisionbox = {0},
	visual = "wielditem",
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5}, -- wielditem seems to be scaled to 1.5 times original node size
	textures = {"areas:display_node"},
	timer = 0,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer > 4 or minetest.get_node(self.object:get_pos()).name ~= "areas:protector" then
			self.object:remove()
		end
	end
})

local nb_radius = radius + 0.55

minetest.register_node("areas:display_node", {
	tiles = {"areas_protector_display.png"},
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			-- sides
			{-nb_radius, -nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius},
			{-nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius, nb_radius},
			{nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius},
			{-nb_radius, -nb_radius, -nb_radius, nb_radius, nb_radius, -nb_radius},
			-- top
			{-nb_radius, nb_radius, -nb_radius, nb_radius, nb_radius, nb_radius},
			-- bottom
			{-nb_radius, -nb_radius, -nb_radius, nb_radius, -nb_radius, nb_radius},
			-- middle (surround protector)
			{-.55, -.55, -.55, .55, .55, .55}
		}
	},
	selection_box = {type = "regular"},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = ""
})

minetest.register_craft({
	output = "areas:protector",
	type = "shapeless",
	recipe = {
		"default:stonebrickcarved", "default:stonebrickcarved", "default:stonebrickcarved",
		"default:stonebrickcarved", "mesecons:wire_00000000_off", "default:stonebrickcarved",
		"default:stonebrickcarved", "default:stonebrickcarved", "default:stonebrickcarved"
	}
})

-- MVPS stopper
if mesecon and mesecon.register_mvps_stopper then
	mesecon.register_mvps_stopper("areas:protector")
end

-- Aliases
minetest.register_alias("areasprotector:protector", "areas:protector")
minetest.register_alias("areasprotector:display_node", "areas:display_node")
