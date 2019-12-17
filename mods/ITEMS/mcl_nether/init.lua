local S = minetest.get_translator("mcl_nether")

local mod_death_messages = minetest.get_modpath("mcl_death_messages")
local mod_screwdriver = minetest.get_modpath("screwdriver") ~= nil
local on_rotate
if mod_screwdriver then
	on_rotate = screwdriver.rotate_3way
end

minetest.register_node("mcl_nether:glowstone", {
	description = S("Glowstone"),
	_doc_items_longdesc = S("Glowstone is a naturally-glowing block which is home to the Nether."),
	tiles = {"mcl_nether_glowstone.png"},
	is_ground_content = true,
	stack_max = 64,
	groups = {handy=1,building_block=1, material_glass=1},
	drop = {
	max_items = 1,
	items = {
			{items = {'mcl_nether:glowstone_dust 4'},rarity = 3},
			{items = {'mcl_nether:glowstone_dust 3'},rarity = 3},
			{items = {'mcl_nether:glowstone_dust 2'}},
		}
	},
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	sounds = mcl_sounds.node_sound_glass_defaults(),
	_mcl_blast_resistance = 1.5,
	_mcl_hardness = 0.3,
})

minetest.register_node("mcl_nether:quartz_ore", {
	description = S("Nether Quartz Ore"),
	_doc_items_longdesc = S("Nether quartz ore is an ore containing nether quartz. It is commonly found around netherrack in the Nether."),
	stack_max = 64,
	tiles = {"mcl_nether_quartz_ore.png"},
	is_ground_content = true,
	groups = {pickaxey=1, building_block=1, material_stone=1},
	drop = 'mcl_nether:quartz',
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 15,
	_mcl_hardness = 3,
})

-- For eternal fire on top of netherrack and magma blocks
-- (this code does not require a dependency on mcl_fire)
local eternal_after_destruct = function(pos, oldnode)
	pos.y = pos.y + 1
	if minetest.get_node(pos).name == "mcl_fire:eternal_fire" then
		minetest.remove_node(pos)
	end
end
local eternal_on_ignite = function(player, pointed_thing)
	local pos = pointed_thing.under
	local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
	local fn = minetest.get_node(flame_pos)
	local pname = player:get_player_name()
	if minetest.is_protected(flame_pos, pname) then
		minetest.record_protection_violation(flame_pos, pname)
		return
	end
	if fn.name == "air" and pointed_thing.under.y < pointed_thing.above.y then
		minetest.set_node(flame_pos, {name = "mcl_fire:eternal_fire"})
		return true
	else
		return false
	end
end

minetest.register_node("mcl_nether:netherrack", {
	description = S("Netherrack"),
	_doc_items_longdesc = S("Netherrack is a stone-like block home to the Nether. Starting a fire on this block will create an eternal fire."),
	stack_max = 64,
	tiles = {"mcl_nether_netherrack.png"},
	is_ground_content = true,
	groups = {pickaxey=1, building_block=1, material_stone=1, enderman_takable=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 2,
	_mcl_hardness = 0.4,

	-- Eternal fire on top
	after_destruct = eternal_after_destruct,
	_on_ignite = eternal_on_ignite,
})

minetest.register_node("mcl_nether:magma", {
	description = S("Magma Block"),
	_doc_items_longdesc = S("Magma blocks are hot solid blocks which hurt anyone standing on it, unless they have fire resistance. Starting a fire on this block will create an eternal fire."),
	stack_max = 64,
	tiles = {{name="mcl_nether_magma.png", animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=1.5}}},
	is_ground_content = true,
	light_source = 3,
	sunlight_propagates = false,
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	-- From walkover mod
	on_walk_over = function(loc, nodeiamon, player)
		-- Hurt players standing on top of this block
		if player:get_hp() > 0 then
			if mod_death_messages then
				mcl_death_messages.player_damage(player, S("@1 stood too long on a magma block.", player:get_player_name()))
			end
			player:set_hp(player:get_hp() - 1)
		end
	end,
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 0.5,

	-- Eternal fire on top
	after_destruct = eternal_after_destruct,
	_on_ignite = eternal_on_ignite,
})

minetest.register_node("mcl_nether:soul_sand", {
	description = S("Soul Sand"),
	_doc_items_longdesc = S("Soul sand is a block from the Nether. One can only slowly walk on soul sand. The slowing effect is amplified when the soul sand is on top of ice, packed ice or a slime block."),
	stack_max = 64,
	tiles = {"mcl_nether_soul_sand.png"},
	is_ground_content = true,
	groups = {handy=1,shovely=1, building_block=1,soil_nether_wart=1, material_sand=1},
	collision_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0.5 - 2/16, 0.5 },
	},
	sounds = mcl_sounds.node_sound_sand_defaults(),
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 0.5,
	-- Movement handling is done in mcl_playerplus mod
})

minetest.register_node("mcl_nether:nether_brick", {
	-- Original name: Nether Brick
	description = S("Nether Brick Block"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	tiles = {"mcl_nether_nether_brick.png"},
	is_ground_content = false,
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 30,
	_mcl_hardness = 2,
})

minetest.register_node("mcl_nether:red_nether_brick", {
	-- Original name: Red Nether Brick
	description = S("Red Nether Brick Block"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	tiles = {"mcl_nether_red_nether_brick.png"},
	is_ground_content = false,
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 30,
	_mcl_hardness = 2,
})


minetest.register_node("mcl_nether:nether_wart_block", {
	description = S("Nether Wart Block"),
	_doc_items_longdesc = S("A nether wart block is a purely decorative block made from nether wart."),
	stack_max = 64,
	tiles = {"mcl_nether_nether_wart_block.png"},
	is_ground_content = false,
	groups = {handy=1, building_block=1},
	sounds = mcl_sounds.node_sound_leaves_defaults(
		{
			footstep={name="default_dirt_footstep", gain=0.7},
			dug={name="default_dirt_footstep", gain=1.5},
		}
	),
	_mcl_blast_resistance = 5,
	_mcl_hardness = 1,
})

minetest.register_node("mcl_nether:quartz_block", {
	description = S("Block of Quartz"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	is_ground_content = false,
	tiles = {"mcl_nether_quartz_block_top.png", "mcl_nether_quartz_block_bottom.png", "mcl_nether_quartz_block_side.png"},
	groups = {pickaxey=1, quartz_block=1,building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 4,
	_mcl_hardness = 0.8,
})

minetest.register_node("mcl_nether:quartz_chiseled", {
	description = S("Chiseled Quartz Block"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	is_ground_content = false,
	tiles = {"mcl_nether_quartz_chiseled_top.png", "mcl_nether_quartz_chiseled_top.png", "mcl_nether_quartz_chiseled_side.png"},
	groups = {pickaxey=1, quartz_block=1,building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 4,
	_mcl_hardness = 0.8,
})

minetest.register_node("mcl_nether:quartz_pillar", {
	description = S("Pillar Quartz Block"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	paramtype2 = "facedir",
	is_ground_content = false,
	on_place = mcl_util.rotate_axis,
	tiles = {"mcl_nether_quartz_pillar_top.png", "mcl_nether_quartz_pillar_top.png", "mcl_nether_quartz_pillar_side.png"},
	groups = {pickaxey=1, quartz_block=1,building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_rotate = on_rotate,
	_mcl_blast_resistance = 4,
	_mcl_hardness = 0.8,
})
minetest.register_node("mcl_nether:quartz_smooth", {
	description = S("Smooth Quartz"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	is_ground_content = false,
	tiles = {"mcl_nether_quartz_block_bottom.png"},
	groups = {pickaxey=1, quartz_block=1,building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 4,
	_mcl_hardness = 0.8,
})

minetest.register_craftitem("mcl_nether:glowstone_dust", {
	description = S("Glowstone Dust"),
	_doc_items_longdesc = S("Glowstone dust is the dust which comes out of broken glowstones. It is mainly used in crafting."),
	inventory_image = "mcl_nether_glowstone_dust.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_nether:quartz", {
	description = S("Nether Quartz"),
	_doc_items_longdesc = S("Nether quartz is a versatile crafting ingredient."),
	inventory_image = "mcl_nether_quartz.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

minetest.register_craftitem("mcl_nether:netherbrick", {
	description = S("Nether Brick"),
	_doc_items_longdesc = S("Nether bricks are the main crafting ingredient for crafting nether brick blocks and nether fences."),
	inventory_image = "mcl_nether_netherbrick.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

minetest.register_craft({
	type = "cooking",
	output = "mcl_nether:quartz",
	recipe = "mcl_nether:quartz_ore",
	cooktime = 10,
})

minetest.register_craft({
	output = 'mcl_nether:quartz_block',
	recipe = {
		{'mcl_nether:quartz', 'mcl_nether:quartz'},
		{'mcl_nether:quartz', 'mcl_nether:quartz'},
	}
})

minetest.register_craft({
	output = 'mcl_nether:quartz_pillar 2',
	recipe = {
		{'mcl_nether:quartz_block'},
		{'mcl_nether:quartz_block'},
	}
})

minetest.register_craft({
	output = "mcl_nether:glowstone",
	recipe = {
		{'mcl_nether:glowstone_dust', 'mcl_nether:glowstone_dust'},
		{'mcl_nether:glowstone_dust', 'mcl_nether:glowstone_dust'},
	}
})

minetest.register_craft({
	output = "mcl_nether:magma",
	recipe = {
		{'mcl_mobitems:magma_cream', 'mcl_mobitems:magma_cream'},
		{'mcl_mobitems:magma_cream', 'mcl_mobitems:magma_cream'},
	}
})

minetest.register_craft({
	type = "cooking",
	output = "mcl_nether:netherbrick",
	recipe = "mcl_nether:netherrack",
	cooktime = 10,
})

minetest.register_craft({
	output = "mcl_nether:nether_brick",
	recipe = {
		{'mcl_nether:netherbrick', 'mcl_nether:netherbrick'},
		{'mcl_nether:netherbrick', 'mcl_nether:netherbrick'},
	}
})

minetest.register_craft({
	output = "mcl_nether:red_nether_brick",
	recipe = {
		{'mcl_nether:nether_wart_item', 'mcl_nether:netherbrick'},
		{'mcl_nether:netherbrick', 'mcl_nether:nether_wart_item'},
	}
})
minetest.register_craft({
	output = "mcl_nether:red_nether_brick",
	recipe = {
		{'mcl_nether:netherbrick', 'mcl_nether:nether_wart_item'},
		{'mcl_nether:nether_wart_item', 'mcl_nether:netherbrick'},
	}
})

minetest.register_craft({
	output = "mcl_nether:nether_wart_block",
	recipe = {
		{'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item'},
		{'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item'},
		{'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item', 'mcl_nether:nether_wart_item'},
	}
})

dofile(minetest.get_modpath(minetest.get_current_modname()).."/nether_wart.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/lava.lua")
