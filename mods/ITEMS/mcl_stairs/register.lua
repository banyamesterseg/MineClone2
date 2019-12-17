-- Register all Minecraft stairs and slabs
-- Note about hardness: For some reason, the hardness of slabs and stairs don't always match nicely, so that some
-- slabs actually take slightly longer to be dug than their stair counterparts.
-- Note sure if it is a good idea to preserve this oddity.

local S = minetest.get_translator("mcl_stairs")

local woods = {
	{ "wood", "default_wood.png", S("Oak Wood Stairs"), S("Oak Wood Slab"), S("Double Oak Wood Slab") },
	{ "junglewood", "default_junglewood.png", S("Jungle Wood Stairs"), S("Jungle Wood Slab"), S("Double Jungle Wood Slab") },
	{ "acaciawood", "default_acacia_wood.png", S("Acacia Wood Stairs"), S("Acacia Wood Slab"), S("Double Acacia Wood Slab") },
	{ "sprucewood", "mcl_core_planks_spruce.png", S("Spruce Wood Stairs"), S("Spruce Wood Slab"), S("Double Spruce Wood Slab") },
	{ "birchwood", "mcl_core_planks_birch.png", S("Birch Wood Stairs"), S("Birch Wood Slab"), S("Double Birch Wood Slab") },
	{ "darkwood", "mcl_core_planks_big_oak.png", S("Dark Oak Wood Stairs"), S("Dark Oak Wood Slab"), S("Double Dark Oak Wood Slab") },
}

for w=1, #woods do
	local wood = woods[w]
	mcl_stairs.register_stair(wood[1], "mcl_core:"..wood[1],
			{handy=1,axey=1, flammable=3,wood_stairs=1, material_wood=1},
			{wood[2]},
			wood[3],
			mcl_sounds.node_sound_wood_defaults(),
			2,
			"woodlike")
	mcl_stairs.register_slab(wood[1], "mcl_core:"..wood[1],
			{handy=1,axey=1, flammable=3,wood_slab=1, material_wood=1},
			{wood[2]},
			wood[4],
			mcl_sounds.node_sound_wood_defaults(),
			2,
			wood[5])
end

mcl_stairs.register_stair_and_slab_simple("stone_rough", "mcl_core:stone", S("Stone Stairs"), S("Stone Slab"), S("Double Stone Slab"))

mcl_stairs.register_slab("stone", "mcl_core:stone_smooth",
		{pickaxey=1, material_stone=1},
		{"mcl_stairs_stone_slab_top.png", "mcl_stairs_stone_slab_top.png", "mcl_stairs_stone_slab_side.png"},
		S("Polished Stone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Polished Stone Slab"))

mcl_stairs.register_stair_and_slab_simple("andesite", "mcl_core:andesite", S("Andesite Stairs"), S("Andesite Slab"), S("Double Andesite Slab"))
mcl_stairs.register_stair_and_slab_simple("granite", "mcl_core:granite", S("Granite Stairs"), S("Granite Slab"), S("Double Granite Slab"))
mcl_stairs.register_stair_and_slab_simple("diorite", "mcl_core:diorite", S("Diorite Stairs"), S("Diorite Slab"), S("Double Diorite Slab"))

mcl_stairs.register_stair_and_slab_simple("cobble", "mcl_core:cobble", S("Cobblestone Stairs"), S("Cobblestone Slab"), S("Double Cobblestone Slab"))
mcl_stairs.register_stair_and_slab_simple("mossycobble", "mcl_core:mossycobble", S("Mossy Cobblestone Stairs"), S("Mossy Cobblestone Slab"), S("Double Mossy Cobblestone Slab"))

mcl_stairs.register_stair_and_slab_simple("brick_block", "mcl_core:brick_block", S("Brick Stairs"), S("Brick Slab"), S("Double Brick Slab"))


mcl_stairs.register_stair("sandstone", "group:normal_sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png", "mcl_core_sandstone_bottom.png", "mcl_core_sandstone_normal.png"},
		S("Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, nil, "mcl_core:sandstone")
mcl_stairs.register_slab("sandstone", "group:normal_sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_sandstone_top.png", "mcl_core_sandstone_bottom.png", "mcl_core_sandstone_normal.png"},
		S("Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Sandstone Slab"), "mcl_core:sandstone")
mcl_stairs.register_stair_and_slab_simple("sandstonesmooth2", "mcl_core:sandstonesmooth2", S("Smooth Sandstone Stairs"), S("Smooth Sandstone Slab"), S("Double Smooth Sandstone Slab"))

mcl_stairs.register_stair("redsandstone", "group:red_sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png", "mcl_core_red_sandstone_bottom.png", "mcl_core_red_sandstone_normal.png"},
		S("Red Sandstone Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, nil, "mcl_core:redsandstone")
mcl_stairs.register_slab("redsandstone", "group:red_sandstone",
		{pickaxey=1, material_stone=1},
		{"mcl_core_red_sandstone_top.png", "mcl_core_red_sandstone_bottom.png", "mcl_core_red_sandstone_normal.png"},
		S("Red Sandstone Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Red Sandstone Slab"), "mcl_core:redsandstone")
mcl_stairs.register_stair_and_slab_simple("redsandstonesmooth2", "mcl_core:redsandstonesmooth2", S("Smooth Red Sandstone Stairs"), S("Smooth Red Sandstone Slab"), S("Double Smooth Red Sandstone Slab"))

-- Intentionally not group:stonebrick because of mclx_stairs
mcl_stairs.register_stair("stonebrick", "mcl_core:stonebrick",
		{pickaxey=1, material_stone=1},
		{"default_stone_brick.png"},
		S("Stone Bricks Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 1.5, nil, "mcl_core:stonebrick")
mcl_stairs.register_slab("stonebrick", "mcl_core:stonebrick",
		{pickaxey=1, material_stone=1},
		{"default_stone_brick.png"},
		S("Stone Bricks Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Stone Bricks Slab"), "mcl_core:stonebrick")

mcl_stairs.register_stair("quartzblock", "group:quartz_block",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_top.png", "mcl_nether_quartz_block_bottom.png", "mcl_nether_quartz_block_side.png"},
		S("Quartz Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 0.8, nil, "mcl_nether:quartz_block")
mcl_stairs.register_slab("quartzblock", "group:quartz_block",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_quartz_block_top.png", "mcl_nether_quartz_block_bottom.png", "mcl_nether_quartz_block_side.png"},
		S("Quartz Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Quartz Slab"), "mcl_nether:quartz_block")

mcl_stairs.register_stair_and_slab_simple("quartz_smooth", "mcl_nether:quartz_smooth", S("Smooth Quartz Stairs"), S("Smooth Quartz Slab"), S("Double Smooth Quartz Slab"))

mcl_stairs.register_stair_and_slab("nether_brick", "mcl_nether:nether_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_nether_brick.png"},
		S("Nether Brick Stairs"),
		S("Nether Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(),
		2,
		S("Double Nether Brick Slab"))
mcl_stairs.register_stair_and_slab("red_nether_brick", "mcl_nether:red_nether_brick",
		{pickaxey=1, material_stone=1},
		{"mcl_nether_red_nether_brick.png"},
		S("Red Nether Brick Stairs"),
		S("Red Nether Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(),
		2,
		S("Double Red Nether Brick Slab"))

mcl_stairs.register_stair_and_slab_simple("end_bricks", "mcl_end:end_bricks", S("End Stone Brick Stairs"), S("End Stone Brick Slab"), S("Double End Stone Brick Slab"))

mcl_stairs.register_stair("purpur_block", "group:purpur_block",
		{pickaxey=1, material_stone=1},
		{"mcl_end_purpur_block.png"},
		S("Purpur Stairs"),
		mcl_sounds.node_sound_stone_defaults(),
		1.5)
mcl_stairs.register_slab("purpur_block", "group:purpur_block",
		{pickaxey=1, material_stone=1},
		{"mcl_end_purpur_block.png"},
		S("Purpur Slab"),
		mcl_sounds.node_sound_stone_defaults(),
		2,
		S("Double Purpur Slab"))

mcl_stairs.register_stair_and_slab_simple("prismarine", "mcl_ocean:prismarine", S("Prismarine Stairs"), S("Prismarine Slab"), S("Double Prismarine Slab"))

mcl_stairs.register_stair_and_slab_simple("prismarine_brick", "mcl_ocean:prismarine_brick", S("Prismarine Brick Stairs"), S("Prismarine Brick Slab"), S("Double Prismarine Brick Slab"))
mcl_stairs.register_stair_and_slab_simple("prismarine_dark", "mcl_ocean:prismarine_dark", S("Dark Prismarine Stairs"), S("Dark Prismarine Slab"), S("Double Dark Prismarine Slab"))

mcl_stairs.register_slab("andesite_smooth", "mcl_core:andesite_smooth", {pickaxey=1}, {"mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_stairs_andesite_smooth_slab.png"}, S("Polished Andesite Slab"), nil, nil, S("Double Polished Andesite Slab"))
mcl_stairs.register_stair("andesite_smooth", "mcl_core:andesite_smooth", {pickaxey=1}, {"mcl_stairs_andesite_smooth_slab.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_core_andesite_smooth.png", "mcl_stairs_andesite_smooth_slab.png"}, S("Polished Andesite Stairs"), nil, nil, "woodlike")

mcl_stairs.register_slab("granite_smooth", "mcl_core:granite_smooth", {pickaxey=1}, {"mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_stairs_granite_smooth_slab.png"}, S("Polished Granite Slab"), nil, nil, S("Double Polished Granite Slab"))
mcl_stairs.register_stair("granite_smooth", "mcl_core:granite_smooth", {pickaxey=1}, {"mcl_stairs_granite_smooth_slab.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_core_granite_smooth.png", "mcl_stairs_granite_smooth_slab.png"}, S("Polished Granite Stairs"), nil, nil, "woodlike")

mcl_stairs.register_slab("diorite_smooth", "mcl_core:diorite_smooth", {pickaxey=1}, {"mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_stairs_diorite_smooth_slab.png"}, S("Polished Diorite Slab"), nil, nil, S("Double Polished Diorite Slab"))
mcl_stairs.register_stair("diorite_smooth", "mcl_core:diorite_smooth", {pickaxey=1}, {"mcl_stairs_diorite_smooth_slab.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_core_diorite_smooth.png", "mcl_stairs_diorite_smooth_slab.png"}, S("Polished Diorite Stairs"), nil, nil, "woodlike")

mcl_stairs.register_stair("stonebrickmossy", "mcl_core:stonebrickmossy",
		{pickaxey=1},
		{"mcl_core_stonebrick_mossy.png"},
		S("Mossy Stone Brick Stairs"),
		mcl_sounds.node_sound_stone_defaults(), 1.5, nil, "mcl_core:stonebrickmossy")

mcl_stairs.register_slab("stonebrickmossy", "mcl_core:stonebrickmossy",
		{pickaxey=1},
		{"mcl_core_stonebrick_mossy.png"},
		S("Mossy Stone Brick Slab"),
		mcl_sounds.node_sound_stone_defaults(), 2, S("Double Mossy Stone Brick Slab"), "mcl_core:stonebrickmossy")




