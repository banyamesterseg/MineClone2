-- Global namespace for functions

mcl_fire = {}

local S = minetest.get_translator("mcl_fire")
local N = function(s) return s end

--
-- Items
--

-- Flame nodes

-- Fire settings

-- When enabled, fire destroys other blocks.
local fire_enabled = minetest.settings:get_bool("enable_fire", true)

-- Enable sound
local flame_sound = minetest.settings:get_bool("flame_sound", true)

-- Help texts
local fire_help, eternal_fire_help
if fire_enabled then
	fire_help = S("Fire is a damaging and destructive but short-lived kind of block. It will destroy and spread towards near flammable blocks, but fire will disappear when there is nothing to burn left. It will be extinguished by nearby water and rain. Fire can be destroyed safely by punching it, but it is hurtful if you stand directly in it. If a fire is started above netherrack or a magma block, it will immediately turn into an eternal fire.")
else
	fire_help = S("Fire is a damaging but non-destructive short-lived kind of block. It will disappear when there is no flammable block around. Fire does not destroy blocks, at least not in this world. It will be extinguished by nearby water and rain. Fire can be destroyed safely by punching it, but it is hurtful if you stand directly in it. If a fire is started above netherrack or a magma block, it will immediately turn into an eternal fire.")
end

if fire_enabled then
	eternal_fire_help = S("Eternal fire is a damaging block that might create more fire. It will create fire around it when flammable blocks are nearby. Eternal fire can be extinguished by punches and nearby water blocks. Other than (normal) fire, eternal fire does not get extinguished on its own and also continues to burn under rain. Punching eternal fire is safe, but it hurts if you stand inside.")
else
	eternal_fire_help = S("Eternal fire is a damaging block. Eternal fire can be extinguished by punches and nearby water blocks. Other than (normal) fire, eternal fire does not get extinguished on its own and also continues to burn under rain. Punching eternal fire is safe, but it hurts if you stand inside.")
end

local fire_death_messages = {
	N("@1 has been cooked crisp."),
	N("@1 felt the burn."),
	N("@1 died in the flames."),
	N("@1 died in a fire."),
}

minetest.register_node("mcl_fire:fire", {
	description = S("Fire"),
	_doc_items_longdesc = fire_help,
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 1,
	_mcl_node_death_message = fire_death_messages,
	groups = {fire = 1, dig_immediate = 3, not_in_creative_inventory = 1, dig_by_piston=1, destroys_items=1 },
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		if minetest.get_item_group(newnode.name, "water") ~= 0 then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16})
		end
	end,
	on_timer = function(pos)
		local airs = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y+4, z=pos.z+1}, {"air"})
		if (#airs == 0) or ((not fire_enabled) and math.random(1,3) == 1) then
			minetest.remove_node(pos)
			return
		end
		if (not fire_enabled) then
			-- Restart timer
			minetest.get_node_timer(pos):start(math.random(3, 7))
			return
		end
		local burned = false
		if math.random(1,2) == 1 then
			while #airs > 0 do
				local r = math.random(1, #airs)
				if minetest.find_node_near(airs[r], 1, {"group:flammable"}) then
					minetest.set_node(airs[r], {name="mcl_fire:fire"})
					burned = true
					break
				else
					table.remove(airs, r)
				end
			end
		end
		if not burned then
			if math.random(1,3) == 1 then
				minetest.remove_node(pos)
				return
			end
		end
		-- Restart timer
		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	drop = "",
	sounds = {},
	-- Turn into eternal fire on special blocks, light Nether portal (if possible), start burning timer
	on_construct = function(pos)
		local bpos = {x=pos.x, y=pos.y-1, z=pos.z}
		local under = minetest.get_node(bpos).name

		local dim = mcl_worlds.pos_to_dimension(bpos)
		if under == "mcl_nether:magma" or under == "mcl_nether:netherrack" or (under == "mcl_core:bedrock" and dim == "end") then
			minetest.swap_node(pos, {name = "mcl_fire:eternal_fire"})
		end

		if minetest.get_modpath("mcl_portals") then
			mcl_portals.light_nether_portal(pos)
		end

		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_fire:eternal_fire", {
	description = S("Eternal Fire"),
	_doc_items_longdesc = eternal_fire_help,
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 1,
	_mcl_node_death_message = fire_death_messages,
	groups = {fire = 1, dig_immediate = 3, not_in_creative_inventory = 1, dig_by_piston = 1, destroys_items = 1},
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		if minetest.get_item_group(newnode.name, "water") ~= 0 then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16})
		end
	end,
	on_timer = function(pos)
		if fire_enabled then
			local airs = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y+4, z=pos.z+1}, {"air"})
			while #airs > 0 do
				local r = math.random(1, #airs)
				if minetest.find_node_near(airs[r], 1, {"group:flammable"}) then
					minetest.set_node(airs[r], {name="mcl_fire:fire"})
					break
				else
					table.remove(airs, r)
				end
			end
		end
		-- Restart timer
		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	-- Start burning timer and light Nether portal (if possible)
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(3, 7))

		if minetest.get_modpath("mcl_portals") then
			mcl_portals.light_nether_portal(pos)
		end
	end,
	sounds = {},
	drop = "",
	_mcl_blast_resistance = 0,
})

--
-- Sound
--

if flame_sound then

	local handles = {}
	local timer = 0

	-- Parameters

	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player

	function mcl_fire.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:get_pos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = minetest.find_nodes_in_area(
			areamin,
			areamax,
			{"mcl_fire:fire", "mcl_fire:eternal_fire"}
		)
		-- Total number of flames in radius
		local flames = (num["mcl_fire:fire"] or 0) +
			(num["mcl_fire:eternal_fire"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			minetest.sound_fade(handles[player_name], -0.4, 0.0)
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound
			local handle = minetest.sound_play(
				"fire_fire",
				{
					pos = fposmid,
					to_player = player_name,
					gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
					max_hear_distance = 32,
					loop = true, -- In case of lag
				}
			)
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating players sounds

	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < cycle then
			return
		end

		timer = 0
		local players = minetest.get_connected_players()
		for n = 1, #players do
			mcl_fire.update_player_sound(players[n])
		end
	end)

	-- Stop sound and clear handle on player leave

	minetest.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
	end)
end


--
-- ABMs
--

-- Extinguish all flames quickly with water and such

minetest.register_abm({
	label = "Extinguish flame",
	nodenames = {"mcl_fire:fire", "mcl_fire:eternal_fire"},
	neighbors = {"group:puts_out_fire"},
	interval = 3,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.remove_node(pos)
		minetest.sound_play("fire_extinguish_flame",
			{pos = pos, max_hear_distance = 16, gain = 0.15})
	end,
})


-- Enable the following ABMs according to 'enable fire' setting

if not fire_enabled then

	-- Occasionally remove fire if fire disabled
	-- NOTE: Fire is normally extinguished in timer function
	minetest.register_abm({
		label = "Remove disabled fire",
		nodenames = {"mcl_fire:fire"},
		interval = 10,
		chance = 10,
		catch_up = false,
		action = minetest.remove_node,
	})

else -- Fire enabled

	-- Set fire to air nodes (inverse pyramid pattern) above lava source
	minetest.register_abm({
		label = "Ignite fire by lava",
		nodenames = {"group:lava"},
		interval = 7,
		chance = 2,
		catch_up = false,
		action = function(pos)
			local node = minetest.get_node(pos)
			local def = minetest.registered_nodes[node.name]
			-- Check if liquid source node
			if def and def.liquidtype ~= "source" then
				return
			end
			local function try_ignite(airs)
				while #airs > 0 do
					local r = math.random(1, #airs)
					if minetest.find_node_near(airs[r], 1, {"group:flammable"}) then
						minetest.set_node(airs[r], {name="mcl_fire:fire"})
						return true
					else
						table.remove(airs, r)
					end
				end
				return false
			end
			local airs1 = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y+1, z=pos.z-1}, {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {"air"})
			local ok = try_ignite(airs1)
			if not ok then
				local airs2 = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y+2, z=pos.z-2}, {x=pos.x+2, y=pos.y+2, z=pos.z+2}, {"air"})
				try_ignite(airs2)
			end
		end,
	})

	-- Turn flammable nodes around fire into fire
	minetest.register_abm({
		label = "Remove flammable nodes",
		nodenames = {"group:fire"},
		neighbors = {"group:flammable"},
		interval = 5,
		chance = 18,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local p = minetest.find_node_near(pos, 1, {"group:flammable"})
			if p then
				local flammable_node = minetest.get_node(p)
				local def = minetest.registered_nodes[flammable_node.name]
				if def.on_burn then
					def.on_burn(p)
				else
					minetest.set_node(p, {name="mcl_fire:fire"})
					minetest.check_for_falling(p)
				end
			end
		end,
	})

end

-- Set pointed_thing on (normal) fire.
-- * pointed_thing: Pointed thing to ignite
-- * player: Player who sets fire or nil if nobody
mcl_fire.set_fire = function(pointed_thing, player)
	local pname
	if player == nil then
		pname = ""
	else
		pname = player:get_player_name()
	end
	local n = minetest.get_node(pointed_thing.above)
	if minetest.is_protected(pointed_thing.above, pname) then
		minetest.record_protection_violation(pointed_thing.above, pname)
		return
	end
	if n.name == "air" then
		minetest.add_node(pointed_thing.above, {name="mcl_fire:fire"})
	end
end

minetest.register_alias("mcl_fire:basic_flame", "mcl_fire:fire")
minetest.register_alias("fire:basic_flame", "mcl_fire:fire")
minetest.register_alias("fire:permanent_flame", "mcl_fire:eternal_flame")

dofile(minetest.get_modpath(minetest.get_current_modname()).."/flint_and_steel.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/fire_charge.lua")
