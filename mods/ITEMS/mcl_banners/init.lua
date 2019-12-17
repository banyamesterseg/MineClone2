local S = minetest.get_translator("mcl_banners")
local N = function(s) return s end

local node_sounds
if minetest.get_modpath("mcl_sounds") then
	node_sounds = mcl_sounds.node_sound_wood_defaults()
end

-- Helper function
local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

mcl_banners = {}

mcl_banners.colors = {
	-- Format:
	-- [ID] = { banner description, wool, unified dyes color group, overlay color, dye, color name for emblazonings }
	["unicolor_white"] =      {"white",      S("White Banner"),      "mcl_wool:white", "#FFFFFF", "mcl_dye:white", N("White") },
	["unicolor_darkgrey"] =   {"grey",       S("Grey Banner"),       "mcl_wool:grey", "#303030", "mcl_dye:dark_grey", N("Grey") },
	["unicolor_grey"] =       {"silver",     S("Light Grey Banner"), "mcl_wool:silver", "#5B5B5B", "mcl_dye:grey", N("Light Grey") },
	["unicolor_black"] =      {"black",      S("Black Banner"),      "mcl_wool:black", "#000000", "mcl_dye:black", N("Black") },
	["unicolor_red"] =        {"red",        S("Red Banner"),        "mcl_wool:red", "#BC0000", "mcl_dye:red", N("Red") },
	["unicolor_yellow"] =     {"yellow",     S("Yellow Banner"),     "mcl_wool:yellow", "#E6CD00", "mcl_dye:yellow", N("Yellow") },
	["unicolor_dark_green"] = {"green",      S("Green Banner"),      "mcl_wool:green", "#006000", "mcl_dye:dark_green", N("Green") },
	["unicolor_cyan"] =       {"cyan",       S("Cyan Banner"),       "mcl_wool:cyan", "#00ACAC", "mcl_dye:cyan", N("Cyan") },
	["unicolor_blue"] =       {"blue",       S("Blue Banner"),       "mcl_wool:blue", "#0000AC", "mcl_dye:blue", N("Blue") },
	["unicolor_red_violet"] = {"magenta",    S("Magenta Banner"),    "mcl_wool:magenta", "#AC007C", "mcl_dye:magenta", N("Magenta")},
	["unicolor_orange"] =     {"orange",     S("Orange Banner"),     "mcl_wool:orange", "#E67300", "mcl_dye:orange", N("Orange") },
	["unicolor_violet"] =     {"purple",     S("Purple Banner"),     "mcl_wool:purple", "#6400AC", "mcl_dye:violet", N("Violet") },
	["unicolor_brown"] =      {"brown",      S("Brown Banner"),      "mcl_wool:brown", "#603000", "mcl_dye:brown", N("Brown") },
	["unicolor_pink"] =       {"pink",       S("Pink Banner"),       "mcl_wool:pink", "#DE557C", "mcl_dye:pink", N("Pink") },
	["unicolor_lime"] =       {"lime",       S("Lime Banner"),       "mcl_wool:lime", "#30AC00", "mcl_dye:green", N("Lime") },
	["unicolor_light_blue"] = {"light_blue", S("Light Blue Banner"), "mcl_wool:light_blue", "#4040CF", "mcl_dye:lightblue", N("Light Blue") },
}

local colors_reverse = {}
for k,v in pairs(mcl_banners.colors) do
	colors_reverse["mcl_banners:banner_item_"..v[1]] = k
end

-- Add pattern/emblazoning crafting recipes
dofile(minetest.get_modpath("mcl_banners").."/patterncraft.lua")

-- Overlay ratios (0-255)
local base_color_ratio = 224
local layer_ratio = 255

local standing_banner_entity_offset = { x=0, y=-0.499, z=0 }
local hanging_banner_entity_offset = { x=0, y=-1.7, z=0 }

local rotation_level_to_yaw = function(rotation_level)
	return (rotation_level * (math.pi/8)) + math.pi
end

local on_dig_banner = function(pos, node, digger)
	-- Check protection
	local name = digger:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return
	end
	-- Drop item
	local meta = minetest.get_meta(pos)
	local item = meta:get_inventory():get_stack("banner", 1)
	if not item:is_empty() then
		minetest.handle_node_drops(pos, {item:to_string()}, digger)
	else
		minetest.handle_node_drops(pos, {"mcl_banners:banner_item_white"}, digger)
	end
	-- Remove node
	minetest.remove_node(pos)
end

local on_destruct_banner = function(pos, hanging)
	local offset, nodename
	if hanging then
		offset = hanging_banner_entity_offset
		nodename = "mcl_banners:hanging_banner"
	else
		offset = standing_banner_entity_offset
		nodename = "mcl_banners:standing_banner"
	end
	-- Find this node's banner entity and remove it
	local checkpos = vector.add(pos, offset)
	local objects = minetest.get_objects_inside_radius(checkpos, 0.5)
	for _, v in ipairs(objects) do
		local ent = v:get_luaentity()
		if ent and ent.name == nodename then
			v:remove()
		end
	end
end

local on_destruct_standing_banner = function(pos)
	return on_destruct_banner(pos, false)
end

local on_destruct_hanging_banner = function(pos)
	return on_destruct_banner(pos, true)
end

local make_banner_texture = function(base_color, layers)
	local colorize
	if mcl_banners.colors[base_color] then
		colorize = mcl_banners.colors[base_color][4]
	end
	if colorize then
		-- Base texture with base color
		local base = "(mcl_banners_banner_base.png^[mask:mcl_banners_base_inverted.png)^((mcl_banners_banner_base.png^[colorize:"..colorize..":"..base_color_ratio..")^[mask:mcl_banners_base.png)"

		-- Optional pattern layers
		if layers then
			local finished_banner = base
			for l=1, #layers do
				local layerinfo = layers[l]
				local pattern = "mcl_banners_" .. layerinfo.pattern .. ".png"
				local color = mcl_banners.colors[layerinfo.color][4]

				-- Generate layer texture
				local layer = "(("..pattern.."^[colorize:"..color..":"..layer_ratio..")^[mask:"..pattern..")"

				finished_banner = finished_banner .. "^" .. layer
			end
			return { finished_banner }
		end
		return { base }
	else
		return { "mcl_banners_banner_base.png" }
	end
end

local spawn_banner_entity = function(pos, hanging, itemstack)
	local banner
	if hanging then
		banner = minetest.add_entity(pos, "mcl_banners:hanging_banner")
	else
		banner = minetest.add_entity(pos, "mcl_banners:standing_banner")
	end
	if banner == nil then
		return banner
	end
	local imeta = itemstack:get_meta()
	local layers_raw = imeta:get_string("layers")
	local layers = minetest.deserialize(layers_raw)
	local colorid = colors_reverse[itemstack:get_name()]
	banner:get_luaentity():_set_textures(colorid, layers)
	local mname = imeta:get_string("name")
	if mname ~= nil and mname ~= "" then
		banner:get_luaentity()._item_name = mname
		banner:get_luaentity()._item_description = imeta:get_string("description")
	end

	return banner
end

local respawn_banner_entity = function(pos, node, force)
	local hanging = node.name == "mcl_banners:hanging_banner"
	local offset
	if hanging then
		offset = hanging_banner_entity_offset
	else
		offset = standing_banner_entity_offset
	end
	-- Check if a banner entity already exists
	local bpos = vector.add(pos, offset)
	local objects = minetest.get_objects_inside_radius(bpos, 0.5)
	for _, v in ipairs(objects) do
		local ent = v:get_luaentity()
		if ent and (ent.name == "mcl_banners:standing_banner" or ent.name == "mcl_banners:hanging_banner") then
			if force then
				v:remove()
			else
				return
			end
		end
	end
	-- Spawn new entity
	local meta = minetest.get_meta(pos)
	local banner_item = meta:get_inventory():get_stack("banner", 1)
	local banner_entity = spawn_banner_entity(bpos, hanging, banner_item)

	-- Set rotation
	local rotation_level = meta:get_int("rotation_level")
	local final_yaw = rotation_level_to_yaw(rotation_level)
	banner_entity:set_yaw(final_yaw)
end

-- Banner nodes.
-- These are an invisible nodes which are only used to destroy the banner entity.
-- All the important banner information (such as color) is stored in the entity.
-- It is used only used internally.

-- Standing banner node
-- This one is also used for the help entry to avoid spamming the help with 16 entries.
minetest.register_node("mcl_banners:standing_banner", {
	_doc_items_entry_name = "Banner",
	_doc_items_image = "mcl_banners_item_base.png^mcl_banners_item_overlay.png",
	_doc_items_longdesc = S("Banners are tall colorful decorative blocks. They can be placed on the floor and at walls. Banners can be emblazoned with a variety of patterns using a lot of dye in crafting."),
	_doc_items_usagehelp = S("Use crafting to draw a pattern on top of the banner. Emblazoned banners can be emblazoned again to combine various patterns. You can draw up to 12 layers on a banner that way. If the banner includes a gradient, only 3 layers are possible.").."\n"..
S("You can copy the pattern of a banner by placing two banners of the same color in the crafting grid—one needs to be emblazoned, the other one must be clean. Finally, you can use a banner on a cauldron with water to wash off its top-most layer."),
	walkable = false,
	is_ground_content = false,
	paramtype = "light",
	sunlight_propagates = true,
	drawtype = "nodebox",
	-- Nodebox is drawn as fallback when the entity is missing, so that the
	-- banner node is never truly invisible.
	-- If the entity is drawn, the nodebox disappears within the real banner mesh.
	node_box = {
		type = "fixed",
		fixed = { -1/32, -0.49, -1/32, 1/32, 1.49, 1/32 },
	},
	-- This texture is based on the banner base texture
	tiles = { "mcl_banners_fallback_wood.png" },

	inventory_image = "mcl_banners_item_base.png",
	wield_image = "mcl_banners_item_base.png",

	selection_box = {type = "fixed", fixed= {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3} },
	groups = {axey=1,handy=1, attached_node = 1, not_in_creative_inventory = 1, not_in_craft_guide = 1, material_wood=1, dig_by_piston=1 },
	stack_max = 16,
	sounds = node_sounds,
	drop = "", -- Item drops are handled in entity code

	on_dig = on_dig_banner,
	on_destruct = on_destruct_standing_banner,
	on_punch = function(pos, node)
		respawn_banner_entity(pos, node)
	end,
	_mcl_hardness = 1,
	_mcl_blast_resistance = 5,
	on_rotate = function(pos, node, user, mode, param2)
		if mode == screwdriver.ROTATE_FACE then
			local meta = minetest.get_meta(pos)
			local rot = meta:get_int("rotation_level")
			rot = (rot - 1) % 16
			meta:set_int("rotation_level", rot)
			respawn_banner_entity(pos, node, true)
			return true
		else
			return false
		end
	end,
})

-- Hanging banner node
minetest.register_node("mcl_banners:hanging_banner", {
	walkable = false,
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	drawtype = "nodebox",
	inventory_image = "mcl_banners_item_base.png",
	wield_image = "mcl_banners_item_base.png",
	tiles = { "mcl_banners_fallback_wood.png" },
	node_box = {
		type = "wallmounted",
		wall_side = { -0.49, 0.41, -0.49, -0.41, 0.49, 0.49 },
		wall_top = { -0.49, 0.41, -0.49, -0.41, 0.49, 0.49 },
		wall_bottom = { -0.49, -0.49, -0.49, -0.41, -0.41, 0.49 },
	},
	selection_box = {type = "wallmounted", wall_side = {-0.5, -0.5, -0.5, -4/16, 0.5, 0.5} },
	groups = {axey=1,handy=1, attached_node = 1, not_in_creative_inventory = 1, not_in_craft_guide = 1, material_wood=1 },
	stack_max = 16,
	sounds = node_sounds,
	drop = "", -- Item drops are handled in entity code

	on_dig = on_dig_banner,
	on_destruct = on_destruct_hanging_banner,
	on_punch = function(pos, node)
		respawn_banner_entity(pos, node)
	end,
	_mcl_hardness = 1,
	_mcl_blast_resistance = 5,
	on_rotate = function(pos, node, user, mode, param2)
		if mode == screwdriver.ROTATE_FACE then
			local r = screwdriver.rotate.wallmounted(pos, node, mode)
			node.param2 = r
			minetest.swap_node(pos, node)
			local meta = minetest.get_meta(pos)
			local rot = 0
			if node.param2 == 2 then
				rot = 12
			elseif node.param2 == 3 then
				rot = 4
			elseif node.param2 == 4 then
				rot = 0
			elseif node.param2 == 5 then
				rot = 8
			end
			meta:set_int("rotation_level", rot)
			respawn_banner_entity(pos, node, true)
			return true
		else
			return false
		end
	end,
})

for colorid, colortab in pairs(mcl_banners.colors) do
	local itemid = colortab[1]
	local desc = colortab[2]
	local wool = colortab[3]
	local colorize = colortab[4]

	local itemstring = "mcl_banners:banner_item_"..itemid
	local inv
	if colorize then
		inv = "mcl_banners_item_base.png^(mcl_banners_item_overlay.png^[colorize:"..colorize..")"
	else
		inv = "mcl_banners_item_base.png^mcl_banners_item_overlay.png"
	end

	-- Banner items.
	-- This is the player-visible banner item. It comes in 16 base colors.
	-- The multiple items are really only needed for the different item images.
	-- TODO: Combine the items into only 1 item.
	minetest.register_craftitem(itemstring, {
		description = desc,
		_doc_items_create_entry = false,
		inventory_image = inv,
		wield_image = inv,
		-- Banner group groups together the banner items, but not the nodes.
		-- Used for crafting.
		groups = { banner = 1, deco_block = 1, },
		stack_max = 16,

		on_place = function(itemstack, placer, pointed_thing)
			local above = pointed_thing.above
			local under = pointed_thing.under

			local node_under = minetest.get_node(under)
			if placer and not placer:get_player_control().sneak then
				-- Use pointed node's on_rightclick function first, if present
				if minetest.registered_nodes[node_under.name] and minetest.registered_nodes[node_under.name].on_rightclick then
					return minetest.registered_nodes[node_under.name].on_rightclick(under, node_under, placer, itemstack) or itemstack
				end

				if minetest.get_modpath("mcl_cauldrons") then
					-- Use banner on cauldron to remove the top-most layer. This reduces the water level by 1.
					local new_node
					if node_under.name == "mcl_cauldrons:cauldron_3" then
						new_node = "mcl_cauldrons:cauldron_2"
					elseif node_under.name == "mcl_cauldrons:cauldron_2" then
						new_node = "mcl_cauldrons:cauldron_1"
					elseif node_under.name == "mcl_cauldrons:cauldron_1" then
						new_node = "mcl_cauldrons:cauldron"
					elseif node_under.name == "mcl_cauldrons:cauldron_3r" then
						new_node = "mcl_cauldrons:cauldron_2r"
					elseif node_under.name == "mcl_cauldrons:cauldron_2r" then
						new_node = "mcl_cauldrons:cauldron_1r"
					elseif node_under.name == "mcl_cauldrons:cauldron_1r" then
						new_node = "mcl_cauldrons:cauldron"
					end
					if new_node then
						local imeta = itemstack:get_meta()
						local layers_raw = imeta:get_string("layers")
						local layers = minetest.deserialize(layers_raw)
						if type(layers) == "table" and #layers > 0 then
							table.remove(layers)
							imeta:set_string("layers", minetest.serialize(layers))
							local newdesc = mcl_banners.make_advanced_banner_description(itemstack:get_definition().description, layers)
							local mname = imeta:get_string("name")
							-- Don't change description if item has a name
							if mname == "" then
								imeta:set_string("description", newdesc)
							end
						end

						-- Washing off reduces the water level by 1.
						-- (It is possible to waste water if the banner had 0 layers.)
						minetest.set_node(pointed_thing.under, {name=new_node})

						-- Play sound (from mcl_potions mod)
						minetest.sound_play("mcl_potions_bottle_pour", {pos=pointed_thing.under, gain=0.5, max_hear_range=16})

						return itemstack
					end
				end
			end

			-- Place the node!
			local hanging = false

			-- Standing or hanging banner. The placement rules are enforced by the node definitions
			local _, success = minetest.item_place_node(ItemStack("mcl_banners:standing_banner"), placer, pointed_thing)
			if not success then
				-- Forbidden on ceiling
				if pointed_thing.under.y ~= pointed_thing.above.y then
					return itemstack
				end
				_, success = minetest.item_place_node(ItemStack("mcl_banners:hanging_banner"), placer, pointed_thing)
				if not success then
					return itemstack
				end
				hanging = true
			end
			local place_pos
			if minetest.registered_nodes[node_under.name].buildable_to then
				place_pos = under
			else
				place_pos = above
			end
			local bnode = minetest.get_node(place_pos)
			if bnode.name ~= "mcl_banners:standing_banner" and bnode.name ~= "mcl_banners:hanging_banner" then
				minetest.log("error", "[mcl_banners] The placed banner node is not what the mod expected!")
				return itemstack
			end
			local meta = minetest.get_meta(place_pos)
			local inv = meta:get_inventory()
			inv:set_size("banner", 1)
			local store_stack = ItemStack(itemstack)
			store_stack:set_count(1)
			inv:set_stack("banner", 1, store_stack)

			-- Spawn entity
			local entity_place_pos
			if hanging then
				entity_place_pos = vector.add(place_pos, hanging_banner_entity_offset)
			else
				entity_place_pos = vector.add(place_pos, standing_banner_entity_offset)
			end
			local banner_entity = spawn_banner_entity(entity_place_pos, hanging, itemstack)
			-- Set rotation
			local final_yaw, rotation_level
			if hanging then
				local pdir = vector.direction(pointed_thing.under, pointed_thing.above)
				final_yaw = minetest.dir_to_yaw(pdir)
				if pdir.x > 0 then
					rotation_level = 4
				elseif pdir.z > 0 then
					rotation_level = 8
				elseif pdir.x < 0 then
					rotation_level = 12
				else
					rotation_level = 0
				end
			else
				-- Determine the rotation based on player's yaw
				local yaw = placer:get_look_horizontal()
				-- Select one of 16 possible rotations (0-15)
				rotation_level = round((yaw / (math.pi*2)) * 16)
				if rotation_level >= 16 then
					rotation_level = 0
				end
				final_yaw = rotation_level_to_yaw(rotation_level)
			end
			meta:set_int("rotation_level", rotation_level)

			if banner_entity ~= nil then
				banner_entity:set_yaw(final_yaw)
			end

			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			minetest.sound_play({name="default_place_node_hard", gain=1.0}, {pos = place_pos})

			return itemstack
		end,

		_mcl_generate_description = function(itemstack)
			local meta = itemstack:get_meta()
			local layers_raw = meta:get_string("layers")
			if not layers_raw then
				return nil
			end
			local layers = minetest.deserialize(layers_raw)
			local desc = itemstack:get_definition().description
			local newdesc = mcl_banners.make_advanced_banner_description(desc, layers)
			meta:set_string("description", newdesc)
			return newdesc
		end,
	})

	if minetest.get_modpath("mcl_core") and minetest.get_modpath("mcl_wool") then
		minetest.register_craft({
			output = itemstring,
			recipe = {
				{ wool, wool, wool },
				{ wool, wool, wool },
				{ "", "mcl_core:stick", "" },
			}
		})
	end

	if minetest.get_modpath("doc") then
		-- Add item to node alias
		doc.add_entry_alias("nodes", "mcl_banners:standing_banner", "craftitems", itemstring)
	end
end

if minetest.get_modpath("doc") then
	-- Add item to node alias
	doc.add_entry_alias("nodes", "mcl_banners:standing_banner", "nodes", "mcl_banners:hanging_banner")
end


-- Banner entities.
local entity_standing = {
	physical = false,
	collide_with_objects = false,
	visual = "mesh",
	mesh = "amc_banner.b3d",
	visual_size = { x=2.499, y=2.499 },
	textures = make_banner_texture(),
	pointable = false,

	_base_color = nil, -- base color of banner
	_layers = nil, -- table of layers painted over the base color.
		-- This is a table of tables with each table having the following fields:
			-- color: layer color ID (see colors table above)
			-- pattern: name of pattern (see list above)

	get_staticdata = function(self)
		local out = { _base_color = self._base_color, _layers = self._layers, _name = self._name }
		return minetest.serialize(out)
	end,
	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
			local inp = minetest.deserialize(staticdata)
			self._base_color = inp._base_color
			self._layers = inp._layers
			self._name = inp._name
			self.object:set_properties({
				textures = make_banner_texture(self._base_color, self._layers),
			})
		end
		-- Make banner slowly swing
		self.object:set_animation({x=0, y=80}, 25)
		self.object:set_armor_groups({immortal=1})
	end,

	-- Set the banner textures. This function can be used by external mods.
	-- Meaning of parameters:
	-- * self: Lua entity reference to entity.
	-- * other parameters: Same meaning as in make_banner_texture
	_set_textures = function(self, base_color, layers)
		if base_color then
			self._base_color = base_color
		end
		if layers then
			self._layers = layers
		end
		self.object:set_properties({textures = make_banner_texture(self._base_color, self._layers)})
	end,
}
minetest.register_entity("mcl_banners:standing_banner", entity_standing)

local entity_hanging = table.copy(entity_standing)
entity_hanging.mesh = "amc_banner_hanging.b3d"
minetest.register_entity("mcl_banners:hanging_banner", entity_hanging)

-- FIXME: Prevent entity destruction by /clearobjects
minetest.register_lbm({
	label = "Respawn banner entities",
	name = "mcl_banners:respawn_entities",
	run_at_every_load = true,
	nodenames = {"mcl_banners:standing_banner", "mcl_banners:hanging_banner"},
	action = function(pos, node)
		respawn_banner_entity(pos, node)
	end,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:banner",
	burntime = 15,
})

