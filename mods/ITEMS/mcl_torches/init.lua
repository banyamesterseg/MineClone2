local S = minetest.get_translator("mcl_torches")

--
-- 3d torch part
--

-- Check if placement at given node is allowed
local function check_placement_allowed(node, wdir)
	-- Torch placement rules: Disallow placement on some nodes. General rule: Solid, opaque, full cube collision box nodes are allowed.
	-- Special allowed nodes:
	-- * soul sand
	-- * mob spawner
	-- * chorus flower
	-- * glass, barrier, ice
	-- * Fence, wall, end portal frame with ender eye: Only on top
	-- * Slab, stairs: Only on top if upside down

	-- Special forbidden nodes:
	-- * Piston, sticky piston
	local def = minetest.registered_nodes[node.name]
	if not def then
		return false
	-- No ceiling torches
	elseif wdir == 0 then
		return false
	elseif not def.buildable_to then
		if node.name ~= "mcl_core:ice" and node.name ~= "mcl_nether:soul_sand" and node.name ~= "mcl_mobspawners:spawner" and node.name ~= "mcl_core:barrier" and node.name ~= "mcl_end:chorus_flower" and node.name ~= "mcl_end:chorus_flower_dead" and (not def.groups.glass) and
				((not def.groups.solid) or (not def.groups.opaque)) then
			-- Only allow top placement on these nodes
			if node.name == "mcl_end:dragon_egg" or node.name == "mcl_portals:end_portal_frame_eye" or def.groups.fence == 1 or def.groups.wall or def.groups.slab_top == 1 or def.groups.anvil or def.groups.pane or (def.groups.stair == 1 and minetest.facedir_to_dir(node.param2).y ~= 0) then
				if wdir ~= 1 then
					return false
				end
			else
				return false
			end
		elseif minetest.get_item_group(node.name, "piston") >= 1 then
			return false
		end
	end
	return true
end

mcl_torches = {}

mcl_torches.register_torch = function(substring, description, doc_items_longdesc, doc_items_usagehelp, icon, mesh_floor, mesh_wall, tiles, light, groups, sounds, moredef)
	local itemstring = minetest.get_current_modname()..":"..substring
	local itemstring_wall = minetest.get_current_modname()..":"..substring.."_wall"

	if light == nil then light = minetest.LIGHT_MAX end
	if mesh_floor == nil then mesh_floor = "mcl_torches_torch_floor.obj" end
	if mesh_wall == nil then mesh_wall = "mcl_torches_torch_wall.obj" end
	if groups == nil then groups = {} end

	groups.attached_node = 1
	groups.torch = 1
	groups.dig_by_water = 1
	groups.destroy_by_lava_flow = 1
	groups.dig_by_piston = 1

	local floordef = {
		description = description,
		_doc_items_longdesc = doc_items_longdesc,
		_doc_items_usagehelp = doc_items_usagehelp,
		drawtype = "mesh",
		mesh = mesh_floor,
		inventory_image = icon,
		wield_image = icon,
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		liquids_pointable = false,
		light_source = light,
		groups = groups,
		drop = itemstring,
		selection_box = {
			type = "wallmounted",
			wall_top = {-1/16, -1/16, -1/16, 1/16, 0.5, 1/16},
			wall_bottom = {-1/16, -0.5, -1/16, 1/16, 1/16, 1/16},
		},
		sounds = sounds,
		node_placement_prediction = "",
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				-- no interaction possible with entities, for now.
				return itemstack
			end

			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local def = minetest.registered_nodes[node.name]
			if not def then return itemstack end

			-- Call on_rightclick if the pointed node defines it
			if placer and not placer:get_player_control().sneak then
				if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
					return minetest.registered_nodes[node.name].on_rightclick(under, node, placer, itemstack) or itemstack
				end
			end

			local above = pointed_thing.above
			local wdir = minetest.dir_to_wallmounted({x = under.x - above.x, y = under.y - above.y, z = under.z - above.z})

			if check_placement_allowed(node, wdir) == false then
				return itemstack
			end

			local itemstring = itemstack:get_name()
			local fakestack = ItemStack(itemstack)
			local idef = fakestack:get_definition()
			local retval

			if wdir == 1 then
				retval = fakestack:set_name(itemstring)
			else
				retval = fakestack:set_name(itemstring_wall)
			end
			if not retval then
				return itemstack
			end

			local success
			itemstack, success = minetest.item_place(fakestack, placer, pointed_thing, wdir)
			itemstack:set_name(itemstring)

			if success and idef.sounds and idef.sounds.place then
				minetest.sound_play(idef.sounds.place, {pos=under, gain=1})
			end
			return itemstack
		end,
		on_rotate = false,
	}
	if moredef ~= nil then
		for k,v in pairs(moredef) do
			floordef[k] = v
		end
	end
	minetest.register_node(itemstring, floordef)

	local groups_wall = table.copy(groups)
	groups_wall.torch = 2

	local walldef = {
		drawtype = "mesh",
		mesh = mesh_wall,
		tiles = tiles,
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		is_ground_content = false,
		walkable = false,
		light_source = light,
		groups = groups_wall,
		drop = itemstring,
		selection_box = {
			type = "wallmounted",
			wall_top = {-0.1, -0.1, -0.1, 0.1, 0.5, 0.1},
			wall_bottom = {-0.1, -0.5, -0.1, 0.1, 0.1, 0.1},
			wall_side = {-0.5, -0.5, -0.1, -0.2, 0.1, 0.1},
		},
		sounds = sounds,
		on_rotate = false,
	}
	if moredef ~= nil then
		for k,v in pairs(moredef) do
			walldef[k] = v
		end
	end
	minetest.register_node(itemstring_wall, walldef)


	-- Add entry alias for the Help
	if minetest.get_modpath("doc") then
		doc.add_entry_alias("nodes", itemstring, "nodes", itemstring_wall)
	end

end

mcl_torches.register_torch("torch",
	S("Torch"),
	S("Torches are light sources which can be placed at the side or on the top of most blocks."),
	nil,
	"default_torch_on_floor.png",
	"mcl_torches_torch_floor.obj", "mcl_torches_torch_wall.obj",
	{{
		name = "default_torch_on_floor_animated.png",
		animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.3}
	}},
	minetest.LIGHT_MAX,
	{dig_immediate=3, torch=1, deco_block=1},
	mcl_sounds.node_sound_wood_defaults(),
	{_doc_items_hidden = false})
	

minetest.register_craft({
	output = "mcl_torches:torch 4",
	recipe = {
		{ "group:coal" },
		{ "mcl_core:stick" },
	}
})

