-- mods/default/craftitems.lua

local S = minetest.get_translator("mcl_core")

--
-- Crafting items
--

minetest.register_craftitem("mcl_core:stick", {
	description = S("Stick"),
	_doc_items_longdesc = S("Sticks are a very versatile crafting material; used in countless crafting recipes."),
	_doc_items_hidden = false,
	inventory_image = "default_stick.png",
	stack_max = 64,
	groups = { craftitem=1, stick=1 },
})

minetest.register_craftitem("mcl_core:paper", {
	description = S("Paper"),
	_doc_items_longdesc = S("Paper is used to craft books and maps."),
	inventory_image = "default_paper.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:coal_lump", {
	description = S("Coal"),
	_doc_items_longdesc = S("“Coal” refers to coal lumps obtained by digging coal ore which can be found underground. Coal is your standard furnace fuel, but it can also be used to make torches, coal blocks and a few other things."),
	_doc_items_hidden = false,
	groups = { coal=1 },
	inventory_image = "default_coal_lump.png",
	stack_max = 64,
	groups = { craftitem=1, coal=1 },
})

minetest.register_craftitem("mcl_core:charcoal_lump", {
	description = S("Charcoal"),
	_doc_items_longdesc = S("Charcoal is an alternative furnace fuel created by cooking wood in a furnace. It has the same burning time as coal and also shares many of its crafting recipes, but it can not be used to create coal blocks."),
	_doc_items_hidden = false,
	groups = { coal=1 },
	inventory_image = "mcl_core_charcoal.png",
	stack_max = 64,
	groups = { craftitem=1, coal=1 },
})

minetest.register_craftitem("mcl_core:iron_nugget", {
	description = S("Iron Nugget"),
	_doc_items_longdesc = S("Iron nuggets are very small pieces of molten iron; the main purpose is to create iron ingots."),
	inventory_image = "mcl_core_iron_nugget.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:gold_nugget", {
	description = S("Gold Nugget"),
	_doc_items_longdesc = S("Gold nuggets are very small pieces of molten gold; the main purpose is to create gold ingots."),
	inventory_image = "mcl_core_gold_nugget.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:diamond", {
	description = S("Diamond"),
	_doc_items_longdesc = S("Diamonds are precious minerals and useful to create the highest tier of armor and tools."),
	inventory_image = "default_diamond.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:clay_lump", {
	description = S("Clay Ball"),
	_doc_items_longdesc = S("Clay balls are a raw material, mainly used to create bricks in the furnace."),
	_doc_items_hidden = false,
	inventory_image = "default_clay_lump.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:iron_ingot", {
	description = S("Iron Ingot"),
	_doc_items_longdesc = S("Molten iron. It is used to craft armor, tools, and whatnot."),
	inventory_image = "default_steel_ingot.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:gold_ingot", {
	description = S("Gold Ingot"),
	_doc_items_longdesc = S("Molten gold. It is used to craft armor, tools, and whatnot."),
	inventory_image = "default_gold_ingot.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:emerald", {
	description = S("Emerald"),
	_doc_items_longdesc = S("Emeralds are not very useful on their own, but they can exchanged for gold ingots by crafting."),
	inventory_image = "mcl_core_emerald.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:brick", {
	description = S("Brick"),
	_doc_items_longdesc = S("Bricks are used to craft brick blocks."),
	inventory_image = "default_clay_brick.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:flint", {
	description = S("Flint"),
	_doc_items_longdesc = S("Flint is a raw material."),
	inventory_image = "default_flint.png",
	stack_max = 64,
	groups = { craftitem=1 },
})

minetest.register_craftitem("mcl_core:sugar", {
	description = S("Sugar"),
	_doc_items_longdesc = S("Sugar comes from sugar canes and is used to make sweet foods."),
	inventory_image = "mcl_core_sugar.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

minetest.register_craftitem("mcl_core:bowl",{
	description = S("Bowl"),
	_doc_items_longdesc = S("Bowls are mainly used to hold tasty soups."),
	inventory_image = "mcl_core_bowl.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})

minetest.register_craftitem("mcl_core:apple", {
	description = S("Apple"),
	_doc_items_longdesc = S("Apples are food items which can be eaten."),
	wield_image = "default_apple.png",
	inventory_image = "default_apple.png",
	stack_max = 64,
	on_place = minetest.item_eat(4),
	on_secondary_use = minetest.item_eat(4),
	groups = { food = 2, eatable = 4 },
	_mcl_saturation = 2.4,
})

-- TODO: Status effects
minetest.register_craftitem("mcl_core:apple_gold", {
	description = minetest.colorize("#55FFFF", S("Golden Apple")),
	_doc_items_longdesc = S("Golden apples are precious food items which can be eaten."),
	wield_image = "mcl_core_apple_golden.png",
	inventory_image = "mcl_core_apple_golden.png",
	stack_max = 64,
	-- TODO: Reduce to 4 when it's ready
	on_place = minetest.item_eat(8),
	on_secondary_use = minetest.item_eat(8),
	groups = { food = 2, eatable = 8, can_eat_when_full = 1 },
	_mcl_saturation = 9.6,
})
