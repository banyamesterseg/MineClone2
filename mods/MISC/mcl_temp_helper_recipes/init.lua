-- Temporary helper recipes.
-- These recipes are NOT part of Minecraft. They are added to make some currently unobtainable items accessible.
-- TODO: Remove recipes when they become accessible by regular means

minetest.register_craft({
	type = "shapeless",
	output = 'mcl_chests:trapped_chest',
	recipe = {"mcl_core:iron_ingot", "mcl_core:stick", "group:wood", "mcl_chests:chest"},
})

minetest.register_craft({
	output = "mcl_sponges:sponge",
	recipe = {
		{ "mcl_farming:hay_block", "mcl_farming:hay_block", "mcl_farming:hay_block" },
		{ "mcl_farming:hay_block", "mcl_core:goldblock", "mcl_farming:hay_block" },
		{ "mcl_farming:hay_block", "mcl_farming:hay_block", "mcl_farming:hay_block" },
	}
})

minetest.register_craft({
	output = "mcl_ocean:prismarine_shard",
	recipe = {
		{ "mcl_core:glass_cyan", },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_ocean:prismarine_crystals",
	recipe = { "mcl_ocean:prismarine_shard", "mcl_ocean:prismarine_shard", "mcl_ocean:prismarine_shard", "mcl_core:gold_ingot" },
})

minetest.register_craft({
	output = "mcl_mobitems:shulker_shell",
	recipe = {
		 { "mcl_end:purpur_block", "mcl_end:purpur_block", "mcl_end:purpur_block", },
		 { "mcl_end:purpur_block", "mcl_core:goldblock", "mcl_end:purpur_block", },
		 { "mcl_end:purpur_block", "", "mcl_end:purpur_block", },
	}
})

minetest.register_craft({
	output = "3d_armor:helmet_chain",
	recipe = {
		{ "xpanes:bar_flat", "mcl_core:iron_ingot", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
	}
})

minetest.register_craft({
	output = "3d_armor:leggings_chain",
	recipe = {
		{ "xpanes:bar_flat", "mcl_core:iron_ingot", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
	}
})

minetest.register_craft({
	output = "3d_armor:boots_chain",
	recipe = {
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
	}
})

minetest.register_craft({
	output = "3d_armor:chestplate_chain",
	recipe = {
		{ "xpanes:bar_flat", "", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "mcl_core:iron_ingot", "xpanes:bar_flat" },
		{ "xpanes:bar_flat", "xpanes:bar_flat", "xpanes:bar_flat" },
	}
})

-- Make red sand, red sandstone and more craftable in v6
-- NOTE: When you change these, also update mcl_craftguide for the "v6" icon in
-- the craft guide!
if minetest.get_mapgen_setting("mg_name") == "v6" then
	minetest.register_craft({
		output = "mcl_core:redsand 8",
		recipe = {
			{ "mcl_core:sand", "mcl_core:sand", "mcl_core:sand" },
			{ "mcl_core:sand", "mcl_nether:nether_wart_item", "mcl_core:sand" },
			{ "mcl_core:sand", "mcl_core:sand", "mcl_core:sand" },
		}
	})
end


minetest.register_craft({
	output = "mcl_nether:quartz_smooth 4",
	recipe = {
		{ "mcl_nether:quartz_block", "mcl_nether:quartz_block" },
		{ "mcl_nether:quartz_block", "mcl_nether:quartz_block" },
	},
})

minetest.register_craft({
	output = "mcl_core:sandstonesmooth2 4",
	recipe = {
		{ "mcl_core:sandstonesmooth", "mcl_core:sandstonesmooth" },
		{ "mcl_core:sandstonesmooth", "mcl_core:sandstonesmooth" },
	},
})

minetest.register_craft({
	output = "mcl_core:redsandstonesmooth2 4",
	recipe = {
		{ "mcl_core:redsandstonesmooth", "mcl_core:redsandstonesmooth" },
		{ "mcl_core:redsandstonesmooth", "mcl_core:redsandstonesmooth" },
	},
})

minetest.register_craft({
	output = "mcl_core:stone_smooth 2",
	recipe = {
		{ "mcl_stairs:slab_stone" },
		{ "mcl_stairs:slab_stone" },
	},
})

minetest.register_craft({
	output = "mcl_core:gold_ingot 9",
	recipe = {{ "mcl_core:emerald" }},
})
