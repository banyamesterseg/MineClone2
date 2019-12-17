local S = minetest.get_translator("mcl_bows")

mcl_bows = {}

local arrows = {
	["mcl_bows:arrow"] = "mcl_bows:arrow_entity",
}

local GRAVITY = 9.81
local BOW_DURABILITY = 385

-- Charging time in microseconds
local BOW_CHARGE_TIME_HALF = 500000 -- bow level 1
local BOW_CHARGE_TIME_FULL = 1000000 -- bow level 2 (full charge)

-- Factor to multiply with player speed while player uses bow
-- This emulates the sneak speed.
local PLAYER_USE_BOW_SPEED = tonumber(minetest.settings:get("movement_speed_crouch")) / tonumber(minetest.settings:get("movement_speed_walk"))

-- TODO: Use Minecraft speed (ca. 53 m/s)
-- Currently nerfed because at full speed the arrow would easily get out of the range of the loaded map.
local BOW_MAX_SPEED = 26

--[[ Store the charging state of each player.
keys: player name
value:
nil = not charging or player not existing
number: currently charging, the number is the time from minetest.get_us_time
             in which the charging has started
]]
local bow_load = {}

-- Another player table, this one stores the wield index of the bow being charged
local bow_index = {}

mcl_bows.shoot_arrow = function(arrow_item, pos, dir, yaw, shooter, power, damage)
	local obj = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z}, arrows[arrow_item])
	if power == nil then
		power = 19
	end
	if damage == nil then
		damage = 3
	end
	obj:set_velocity({x=dir.x*power, y=dir.y*power, z=dir.z*power})
	obj:set_acceleration({x=0, y=-GRAVITY, z=0})
	obj:set_yaw(yaw-math.pi/2)
	local le = obj:get_luaentity()
	le._shooter = shooter
	le._damage = damage
	le._startpos = pos
	minetest.sound_play("mcl_bows_bow_shoot", {pos=pos})
	if shooter ~= nil and shooter:is_player() then
		if obj:get_luaentity().player == "" then
			obj:get_luaentity().player = shooter
		end
		obj:get_luaentity().node = shooter:get_inventory():get_stack("main", 1):get_name()
	end
	return obj
end

local get_arrow = function(player)
	local inv = player:get_inventory()
	local arrow_stack, arrow_stack_id
	for i=1, inv:get_size("main") do
		local it = inv:get_stack("main", i)
		if not it:is_empty() and minetest.get_item_group(it:get_name(), "ammo_bow") ~= 0 then
			arrow_stack = it
			arrow_stack_id = i
			break
		end
	end
	return arrow_stack, arrow_stack_id
end

local player_shoot_arrow = function(itemstack, player, power, damage)
	local arrow_stack, arrow_stack_id = get_arrow(player)
	local arrow_itemstring
	if not minetest.settings:get_bool("creative_mode") then
		if not arrow_stack then
			return false
		end
		arrow_itemstring = arrow_stack:get_name()
		arrow_stack:take_item()
		local inv = player:get_inventory()
		inv:set_stack("main", arrow_stack_id, arrow_stack)
	end
	local playerpos = player:get_pos()
	local dir = player:get_look_dir()
	local yaw = player:get_look_horizontal()

	if not arrow_itemstring then
		arrow_itemstring = "mcl_bows:arrow"
	end
	mcl_bows.shoot_arrow(arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, dir, yaw, player, power, damage)
	return true
end

-- Bow item, uncharged state
minetest.register_tool("mcl_bows:bow", {
	description = S("Bow"),
	_doc_items_longdesc = S("Bows are ranged weapons to shoot arrows at your foes.").."\n"..
S("The speed and damage of the arrow increases the longer you charge. The regular damage of the arrow is between 1 and 9. At full charge, there's also a 20% of a critical hit, dealing 10 damage instead."),
	_doc_items_usagehelp = S("To use the bow, you first need to have at least one arrow anywhere in your inventory (unless in Creative Mode). Hold down the right mouse button to charge, release to shoot."),
	_doc_items_durability = BOW_DURABILITY,
	inventory_image = "mcl_bows_bow.png",
	stack_max = 1,
	-- Trick to disable melee damage to entities.
	-- Range not set to 0 (unlike the others) so it can be placed into item frames
	range = 1,
	-- Trick to disable digging as well
	on_use = function() end,
	groups = {weapon=1,weapon_ranged=1},
})

-- Iterates through player inventory and resets all the bows in "charging" state back to their original stage
local reset_bows = function(player)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	for place, stack in pairs(list) do
		if stack:get_name()=="mcl_bows:bow_0" or stack:get_name()=="mcl_bows:bow_1" or stack:get_name()=="mcl_bows:bow_2" then
			stack:set_name("mcl_bows:bow")
			list[place] = stack
		end
	end
	inv:set_list("main", list)
end

-- Resets the bow charging state and player speed. To be used when the player is no longer charging the bow
local reset_bow_state = function(player, also_reset_bows)
	bow_load[player:get_player_name()] = nil
	bow_index[player:get_player_name()] = nil
	if minetest.get_modpath("playerphysics") then
		playerphysics.remove_physics_factor(player, "speed", "mcl_bows:use_bow")
	end
	if also_reset_bows then
		reset_bows(player)
	end
end

-- Bow in charging state
for level=0, 2 do
	minetest.register_tool("mcl_bows:bow_"..level, {
		description = S("Bow"),
		_doc_items_create_entry = false,
		inventory_image = "mcl_bows_bow_"..level..".png",
		stack_max = 1,
		range = 0, -- Pointing range to 0 to prevent punching with bow :D
		groups = {not_in_creative_inventory=1, not_in_craft_guide=1},
		on_drop = function(itemstack, dropper, pos)
			reset_bow_state(dropper)
			itemstack:set_name("mcl_bows:bow")
			minetest.item_drop(itemstack, dropper, pos)
			itemstack:take_item()
			return itemstack
		end,
		-- Prevent accidental interaction with itemframes and other nodes
		on_place = function(itemstack)
			return itemstack
		end,
	})
end


controls.register_on_release(function(player, key, time)
	if key~="RMB" then return end
	local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
	local wielditem = player:get_wielded_item()
	if (wielditem:get_name()=="mcl_bows:bow_0" or wielditem:get_name()=="mcl_bows:bow_1" or wielditem:get_name()=="mcl_bows:bow_2") then
		local has_shot = false

		local speed, damage
		local p_load = bow_load[player:get_player_name()]
		local charge
		-- Type sanity check
		if type(p_load) == "number" then
			charge = minetest.get_us_time() - p_load
		else
			-- In case something goes wrong ...
			-- Just assume minimum charge.
			charge = 0
			minetest.log("warning", "[mcl_bows] Player "..player:get_player_name().." fires arrow with non-numeric bow_load!")
		end
		charge = math.max(math.min(charge, BOW_CHARGE_TIME_FULL), 0)

		local charge_ratio = charge / BOW_CHARGE_TIME_FULL
		charge_ratio = math.max(math.min(charge_ratio, 1), 0)

		-- Calculate damage and speed
		-- Fully charged
		if charge >= BOW_CHARGE_TIME_FULL then
			speed = BOW_MAX_SPEED
			local r = math.random(1,5)
			if r == 1 then
				-- 20% chance for critical hit
				damage = 10
			else
				damage = 9
			end
		-- Partially charged
		else
			-- Linear speed and damage increase
			speed = math.max(4, BOW_MAX_SPEED * charge_ratio)
			damage = math.max(1, math.floor(9 * charge_ratio))
		end

		has_shot = player_shoot_arrow(wielditem, player, speed, damage)

		wielditem:set_name("mcl_bows:bow")
		if has_shot and minetest.settings:get_bool("creative_mode") == false then
			wielditem:add_wear(65535/BOW_DURABILITY)
		end
		player:set_wielded_item(wielditem)
		reset_bow_state(player, true)
	end
end)

controls.register_on_hold(function(player, key, time)
	if key ~= "RMB" then
		return
	end
	local name = player:get_player_name()
	local inv = minetest.get_inventory({type="player", name=name})
	local wielditem = player:get_wielded_item()
	if bow_load[name] == nil and wielditem:get_name()=="mcl_bows:bow" and (minetest.settings:get_bool("creative_mode") or inv:contains_item("main", "mcl_bows:arrow")) then
		wielditem:set_name("mcl_bows:bow_0")
		player:set_wielded_item(wielditem)
		if minetest.get_modpath("playerphysics") then
			-- Slow player down when using bow
			playerphysics.add_physics_factor(player, "speed", "mcl_bows:use_bow", PLAYER_USE_BOW_SPEED)
		end
		bow_load[name] = minetest.get_us_time()
		bow_index[name] = player:get_wield_index()
	else
		if player:get_wield_index() == bow_index[name] then
			if type(bow_load[name]) == "number" then
				if wielditem:get_name() == "mcl_bows:bow_0" and minetest.get_us_time() - bow_load[name] >= BOW_CHARGE_TIME_HALF then
					wielditem:set_name("mcl_bows:bow_1")
				elseif wielditem:get_name() == "mcl_bows:bow_1" and minetest.get_us_time() - bow_load[name] >= BOW_CHARGE_TIME_FULL then
					wielditem:set_name("mcl_bows:bow_2")
				end
			else
				if wielditem:get_name() == "mcl_bows:bow_0" or wielditem:get_name() == "mcl_bows:bow_1" or wielditem:get_name() == "mcl_bows:bow_2" then
					wielditem:set_name("mcl_bows:bow")
				end
			end
			player:set_wielded_item(wielditem)
		else
			reset_bow_state(player, true)
		end
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local wielditem = player:get_wielded_item()
		local wieldindex = player:get_wield_index()
		local controls = player:get_player_control()
		if type(bow_load[name]) == "number" and ((wielditem:get_name()~="mcl_bows:bow_0" and wielditem:get_name()~="mcl_bows:bow_1" and wielditem:get_name()~="mcl_bows:bow_2") or wieldindex ~= bow_index[name]) then
			reset_bow_state(player, true)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	reset_bows(player)
end)

minetest.register_on_leaveplayer(function(player)
	reset_bow_state(player, true)
end)

if minetest.get_modpath("mcl_core") and minetest.get_modpath("mcl_mobitems") then
	minetest.register_craft({
		output = 'mcl_bows:bow',
		recipe = {
			{'', 'mcl_core:stick', 'mcl_mobitems:string'},
			{'mcl_core:stick', '', 'mcl_mobitems:string'},
			{'', 'mcl_core:stick', 'mcl_mobitems:string'},
		}
	})
	minetest.register_craft({
		output = 'mcl_bows:bow',
		recipe = {
			{'mcl_mobitems:string', 'mcl_core:stick', ''},
			{'mcl_mobitems:string', '', 'mcl_core:stick'},
			{'mcl_mobitems:string', 'mcl_core:stick', ''},
		}
	})
end

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_bows:bow",
	burntime = 15,
})

-- Add entry aliases for the Help
if minetest.get_modpath("doc") then
	doc.add_entry_alias("tools", "mcl_bows:bow", "tools", "mcl_bows:bow_0")
	doc.add_entry_alias("tools", "mcl_bows:bow", "tools", "mcl_bows:bow_1")
	doc.add_entry_alias("tools", "mcl_bows:bow", "tools", "mcl_bows:bow_2")
end


