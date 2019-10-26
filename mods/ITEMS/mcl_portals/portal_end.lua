local S = minetest.get_translator("mcl_portals")

-- Parameters
local SPAWN_MIN = mcl_vars.mg_end_min+70
local SPAWN_MAX = mcl_vars.mg_end_min+98

local mg_name = minetest.get_mapgen_setting("mg_name")

-- End portal
minetest.register_node("mcl_portals:portal_end", {
	description = S("End Portal"),
	_doc_items_longdesc = S("An End portal teleports creatures and objects to the mysterious End dimension (and back!)."),
	_doc_items_usagehelp = S("Hop into the portal to teleport. Entering an End portal in the Overworld teleports you to a fixed position in the End dimension and creates a 5×5 obsidian platform at your destination. End portals in the End will lead back to your spawn point in the Overworld."),
	tiles = {
		{
			name = "mcl_portals_end_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.0,
			},
		},
		{
			name = "mcl_portals_end_portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 6.0,
			},
		},
		"blank.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = true,
	diggable = false,
	pointable = false,
	buildable_to = false,
	is_ground_content = false,
	drop = "",
	-- This is 15 in MC.
	light_source = 14,
	post_effect_color = {a = 192, r = 0, g = 0, b = 0},
	alpha = 192,
	-- This prevents “falling through”
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -7/16, 0.5},
		},
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 4/16, 0.5},
		},
	},
	groups = {not_in_creative_inventory = 1, disable_jump = 1 },

	_mcl_hardness = -1,
	_mcl_blast_resistance = 18000000,
})

-- Obsidian platform at the End portal destination in the End
local function build_end_portal_destination(pos)
	local p1 = {x = pos.x - 2, y = pos.y, z = pos.z-2}
	local p2 = {x = pos.x + 2, y = pos.y+2, z = pos.z+2}

	for x = p1.x, p2.x do
	for y = p1.y, p2.y do
	for z = p1.z, p2.z do
		local newp = {x=x,y=y,z=z}
		-- Build obsidian platform
		if minetest.registered_nodes[minetest.get_node(newp).name].is_ground_content then
			if y == p1.y then
				minetest.set_node(newp, {name="mcl_core:obsidian"})
			else
				minetest.remove_node(newp)
			end
		end
	end
	end
	end
end


-- Check if pos is part of a valid end portal frame, filled with eyes of ender.
local function check_end_portal_frame(pos)
	-- Check if pos has an end portal frame with eye of ender
	local eframe = function(pos, param2)
		local node = minetest.get_node(pos)
		if node.name == "mcl_portals:end_portal_frame_eye" then
			if param2 == nil or node.param2 == param2 then
				return true, node
			end
		end
		return false
	end

	-- Step 1: Find a row of 3 end portal frames with eyes, all facing the same direction
	local streak = 0
	local streak_start, streak_end, streak_start_node, streak_end_node
	local last_param2
	local axes = { "x", "z" }
	for a=1, #axes do
		local axis = axes[a]
		for b=pos[axis]-2, pos[axis]+2 do
			local cpos = table.copy(pos)
			cpos[axis] = b
			local e, node = eframe(cpos, last_param2)
			if e then
				last_param2 = node.param2
				streak = streak + 1
				if streak == 1 then
					streak_start = table.copy(pos)
					streak_start[axis] = b
					streak_start_node = node
				elseif streak == 3 then
					streak_end = table.copy(pos)
					streak_end[axis] = b
					streak_end_node = node
					break
				end
			else
				streak = 0
				last_param2 = nil
			end
		end
		if streak_end then
			break
		end
		streak = 0
		last_param2 = nil
	end
	-- Has a row been found?
	if streak_end then
		-- Step 2: Using the known facedir, check the remaining spots in which we expect
		-- “eyed” end portal frames.
		local dir = minetest.facedir_to_dir(streak_start_node.param2)
		if dir.x ~= 0 then
			for i=1, 3 do
				if not eframe({x=streak_start.x + i*dir.x, y=streak_start.y, z=streak_start.z - 1}) then
					return false
				end
				if not eframe({x=streak_start.x + i*dir.x, y=streak_start.y, z=streak_end.z + 1}) then
					return false
				end
				if not eframe({x=streak_start.x + 4*dir.x, y=streak_start.y, z=streak_start.z + i-1}) then
					return false
				end
			end
			-- All checks survived! We have a valid portal!
			local k
			if dir.x > 0 then
				k = 1
			else
				k = -3
			end
			return true, { x = streak_start.x + k, y = streak_start.y, z = streak_start.z }
		elseif dir.z ~= 0 then
			for i=1, 3 do
				if not eframe({x=streak_start.x - 1, y=streak_start.y, z=streak_start.z + i*dir.z}) then
					return false
				end
				if not eframe({x=streak_end.x + 1, y=streak_start.y, z=streak_start.z + i*dir.z}) then
					return false
				end
				if not eframe({x=streak_start.x + i-1, y=streak_start.y, z=streak_start.z + 4*dir.z}) then
					return false
				end
			end
			local k
			if dir.z > 0 then
				k = 1
			else
				k = -3
			end
			-- All checks survived! We have a valid portal!
			return true, { x = streak_start.x, y = streak_start.y, z = streak_start.z + k }
		end
	end
	return false
end

-- Generate or destroy a 3×3 end portal beginning at pos. To be used to fill an end portal framea.
-- If destroy == true, the 3×3 area is removed instead.
local function end_portal_area(pos, destroy)
	local SIZE = 3
	local name
	if destroy then
		name = "air"
	else
		name = "mcl_portals:portal_end"
	end
	for x=pos.x, pos.x+SIZE-1 do
		for z=pos.z, pos.z+SIZE-1 do
			minetest.set_node({x=x,y=pos.y,z=z}, {name=name})
		end
	end
end

minetest.register_abm({
	label = "End portal teleportation",
	nodenames = {"mcl_portals:portal_end"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		for _,obj in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			local lua_entity = obj:get_luaentity() --maikerumine added for objects to travel
			if obj:is_player() or lua_entity then
				local dim = mcl_worlds.pos_to_dimension(pos)

				local objpos = obj:get_pos()
				if objpos == nil then
					return
				end

				-- Check if object is actually in portal.
				objpos.y = math.ceil(objpos.y)
				if minetest.get_node(objpos).name ~= "mcl_portals:portal_end" then
					return
				end

				local target
				if dim == "end" then
					-- End portal in the End:
					-- Teleport back to the player's spawn or world spawn in the Overworld.

					if obj:is_player() then
						target = mcl_spawn.get_spawn_pos(obj)
					else
						target = mcl_spawn.get_world_spawn_pos(obj)
					end
				else
					-- End portal in any other dimension:
					-- Teleport to the End at a fixed position and generate a
					-- 5×5 obsidian platform below.

					local platform_pos = mcl_vars.mg_end_platform_pos
					-- force emerge of target1 area
					minetest.get_voxel_manip():read_from_map(platform_pos, platform_pos)
					if not minetest.get_node_or_nil(platform_pos) then
						minetest.emerge_area(vector.subtract(platform_pos, 3), vector.add(platform_pos, 3))
					end

					-- Build destination
					local function check_and_build_end_portal_destination(pos)
						local n = minetest.get_node_or_nil(pos)
						if n and n.name ~= "mcl_core:obsidian" then
							build_end_portal_destination(pos)
							minetest.after(2, check_and_build_end_portal_destination, pos)
						elseif not n then
							minetest.after(1, check_and_build_end_portal_destination, pos)
						end
					end

					local platform
					build_end_portal_destination(platform_pos)
					check_and_build_end_portal_destination(platform_pos)

					target = table.copy(platform_pos)
					target.y = target.y + 1
				end

				-- Teleport
				obj:set_pos(target)
				if obj:is_player() then
					-- Look towards the main End island
					if dim ~= "end" then
						obj:set_look_horizontal(math.pi/2)
					end
					mcl_worlds.dimension_change(obj, mcl_worlds.pos_to_dimension(target))
					minetest.sound_play("mcl_portals_teleport", {pos=target, gain=0.5, max_hear_distance = 16})
				end
			end
		end
	end,
})

local rotate_frame, rotate_frame_eye

if minetest.get_modpath("screwdriver") then
	-- Intentionally not rotatable
	rotate_frame = false
	rotate_frame_eye = false
end

minetest.register_node("mcl_portals:end_portal_frame", {
	description = S("End Portal Frame"),
	_doc_items_longdesc = S("End portal frames are used in the construction of End portals. Each block has a socket for an eye of ender.") .. "\n" .. S("NOTE: The End dimension is currently incomplete and might change in future versions."),
	_doc_items_usagehelp = S("To create an End portal, you need 12 end portal frames and 12 eyes of ender. The end portal frames have to be arranged around a horizontal 3×3 area with each block facing inward. Any other arrangement will fail.") .. "\n" .. S("Place an eye of ender into each block. The end portal appears in the middle after placing the final eye.") .. "\n" .. S("Once placed, an eye of ender can not be taken back."),
	groups = { creative_breakable = 1, deco_block = 1 },
	tiles = { "mcl_portals_endframe_top.png", "mcl_portals_endframe_bottom.png", "mcl_portals_endframe_side.png" },
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 5/16, 0.5 },
	},
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	paramtype = "light",
	sunlight_propagates = false,
	light_source = 1,

	on_rotate = rotate_frame,

	_mcl_blast_resistance = 18000000,
	_mcl_hardness = -1,
})

minetest.register_node("mcl_portals:end_portal_frame_eye", {
	description = S("End Portal Frame with Eye of Ender"),
	_doc_items_create_entry = false,
	groups = { creative_breakable = 1, deco_block = 1, comparator_signal = 15 },
	tiles = { "mcl_portals_endframe_top.png^[lowpart:75:mcl_portals_endframe_eye.png", "mcl_portals_endframe_bottom.png", "mcl_portals_endframe_eye.png^mcl_portals_endframe_side.png" },
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 5/16, 0.5 }, -- Frame
			{ -4/16, 5/16, -4/16, 4/16, 0.5, 4/16 }, -- Eye
		},
	},
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	paramtype = "light",
	sunlight_propagates = false,
	light_source = 1,
	on_destruct = function(pos)
		local ok, ppos = check_end_portal_frame(pos)
		if ok then
			end_portal_area(ppos, true)
		end
	end,
	on_construct = function(pos)
		local ok, ppos = check_end_portal_frame(pos)
		if ok then
			end_portal_area(ppos)
		end
	end,

	on_rotate = rotate_frame_eye,

	_mcl_blast_resistance = 18000000,
	_mcl_hardness = -1,
})

if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mcl_portals:end_portal_frame", "nodes", "mcl_portals:end_portal_frame_eye")
end


--[[ ITEM OVERRIDES ]]

-- Portal opener
minetest.override_item("mcl_end:ender_eye", {
	on_place = function(itemstack, user, pointed_thing)
		-- Use pointed node's on_rightclick function first, if present
		local node = minetest.get_node(pointed_thing.under)
		if user and not user:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
			end
		end

		-- Place eye of ender into end portal frame
		if pointed_thing.under and node.name == "mcl_portals:end_portal_frame" then
			local protname = user:get_player_name()
			if minetest.is_protected(pointed_thing.under, protname) then
				minetest.record_protection_violation(pointed_thing.under, protname)
				return itemstack
			end
			minetest.set_node(pointed_thing.under, { name = "mcl_portals:end_portal_frame_eye", param2 = node.param2 })

			if minetest.get_modpath("doc") then
				doc.mark_entry_as_revealed(user:get_player_name(), "nodes", "mcl_portals:end_portal_frame")
			end
			minetest.sound_play(
				"default_place_node_hard",
				{pos = pointed_thing.under, gain = 0.5, max_hear_distance = 16})
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item() -- 1 use
			end

			local ok = check_end_portal_frame(pointed_thing.under)
			if ok then
				if minetest.get_modpath("doc") then
					doc.mark_entry_as_revealed(user:get_player_name(), "nodes", "mcl_portals:portal_end")
				end
			end
		end
		return itemstack
	end,
})

