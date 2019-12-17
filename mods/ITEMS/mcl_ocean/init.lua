-- Nodes

local S = minetest.get_translator("mcl_ocean")

minetest.register_node("mcl_ocean:sea_lantern", {
	description = S("Sea Lantern"),
	_doc_items_longdesc = S("Sea lanterns are decorative light sources which look great underwater but can be placed anywhere."),
	paramtype2 = "facedir",
	is_ground_content = false,
	stack_max = 64,
	light_source = minetest.LIGHT_MAX,
	drop = {
		max_items = 1,
		items = {
			{ items = {'mcl_ocean:prismarine_crystals 3'}, rarity = 2 },
			{ items = {'mcl_ocean:prismarine_crystals 2'}}
		}
	},
	tiles = {{name="mcl_ocean_sea_lantern.png", animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=1.25}}},
	groups = {handy=1, building_block=1, material_glass=1},
	sounds = mcl_sounds.node_sound_glass_defaults(),
	_mcl_blast_resistance = 1.5,
	_mcl_hardness = 0.3,
})

minetest.register_node("mcl_ocean:prismarine", {
	description = S("Prismarine"),
	_doc_items_longdesc = S("Prismarine is used as a building block. It slowly changes its color."),
	stack_max = 64,
	is_ground_content = false,
	-- Texture should have 22 frames for smooth transitions.
	tiles = {{name="mcl_ocean_prismarine_anim.png", animation={type="vertical_frames", aspect_w=32, aspect_h=32, length=45.0}}},
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 30,
	_mcl_hardness = 1.5,
})

minetest.register_node("mcl_ocean:prismarine_brick", {
	description = S("Prismarine Bricks"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	is_ground_content = false,
	tiles = {"mcl_ocean_prismarine_bricks.png"},
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 30,
	_mcl_hardness = 1.5,
})

minetest.register_node("mcl_ocean:prismarine_dark", {
	description = S("Dark Prismarine"),
	_doc_items_longdesc = doc.sub.items.temp.build,
	stack_max = 64,
	is_ground_content = false,
	tiles = {"mcl_ocean_prismarine_dark.png"},
	groups = {pickaxey=1, building_block=1, material_stone=1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 30,
	_mcl_hardness = 1.5,
})

-- Craftitems

minetest.register_craftitem("mcl_ocean:prismarine_crystals", {
	description = S("Prismarine Crystals"),
	_doc_items_longdesc = doc.sub.items.temp.craftitem,
	inventory_image = "mcl_ocean_prismarine_crystals.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

minetest.register_craftitem("mcl_ocean:prismarine_shard", {
	description = S("Prismarine Shard"),
	_doc_items_longdesc = doc.sub.items.temp.craftitem,
	inventory_image = "mcl_ocean_prismarine_shard.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

-- Crafting

minetest.register_craft({
	output = 'mcl_ocean:sea_lantern',
	recipe = {
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_crystals', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_crystals', 'mcl_ocean:prismarine_crystals', 'mcl_ocean:prismarine_crystals'},
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_crystals', 'mcl_ocean:prismarine_shard'},
	}
})

minetest.register_craft({
	output = 'mcl_ocean:prismarine',
	recipe = {
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
	}
})

minetest.register_craft({
	output = 'mcl_ocean:prismarine_brick',
	recipe = {
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
	}
})

minetest.register_craft({
	output = 'mcl_ocean:prismarine_dark',
	recipe = {
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_shard', 'mcl_dye:black', 'mcl_ocean:prismarine_shard'},
		{'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard', 'mcl_ocean:prismarine_shard'},
	}
})

