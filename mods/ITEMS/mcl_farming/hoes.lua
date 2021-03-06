local S = minetest.get_translator("mcl_farming")

local function create_soil(pos, inv)
	if pos == nil then
		return false
	end
	local node = minetest.get_node(pos)
	local name = node.name
	local above = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
	if minetest.get_item_group(name, "cultivatable") == 2 then
		if above.name == "air" then
			node.name = "mcl_farming:soil"
			minetest.set_node(pos, node)
			minetest.sound_play("default_dig_crumbly", { pos = pos, gain = 0.5 })
			return true
		end
	elseif minetest.get_item_group(name, "cultivatable") == 1 then
		if above.name == "air" then
			node.name = "mcl_core:dirt"
			minetest.set_node(pos, node)
			minetest.sound_play("default_dig_crumbly", { pos = pos, gain = 0.6 })
			return true
		end
	end
	return false
end

local hoe_on_place_function = function(wear_divisor)
	return function(itemstack, user, pointed_thing)
		-- Call on_rightclick if the pointed node defines it
		local node = minetest.get_node(pointed_thing.under)
		if user and not user:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
			end
		end

		if minetest.is_protected(pointed_thing.under, user:get_player_name()) then
			minetest.record_protection_violation(pointed_thing.under, user:get_player_name())
			return itemstack
		end

		if create_soil(pointed_thing.under, user:get_inventory()) then
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:add_wear(65535/wear_divisor)
			end
			return itemstack
		end
	end
end

local hoe_longdesc = S("Hoes are essential tools for growing crops. They are used to create farmland in order to plant seeds on it. Hoes can also be used as very weak weapons in a pinch.")
local hoe_usagehelp = S("Use the hoe on a cultivatable block (by rightclicking it) to turn it into farmland. Dirt, grass blocks and grass paths are cultivatable blocks. Using a hoe on coarse dirt turns it into dirt.")

minetest.register_tool("mcl_farming:hoe_wood", {
	description = S("Wood Hoe"),
	_doc_items_longdesc = hoe_longdesc,
	_doc_items_usagehelp = hoe_usagehelp,
	_doc_items_hidden = false,
	inventory_image = "farming_tool_woodhoe.png",
	on_place = hoe_on_place_function(60),
	groups = { tool=1, hoe=1 },
	tool_capabilities = {
		full_punch_interval = 1,
		damage_groups = { fleshy = 1, }
	},
	_repair_material = "group:wood",
})

minetest.register_craft({
	output = "mcl_farming:hoe_wood",
	recipe = {
		{"group:wood", "group:wood"},
		{"", "mcl_core:stick"},
		{"", "mcl_core:stick"}
	}
})
minetest.register_craft({
	output = "mcl_farming:hoe_wood",
	recipe = {
		{"group:wood", "group:wood"},
		{"mcl_core:stick", ""},
		{"mcl_core:stick", ""}
	}
})
minetest.register_craft({
	type = "fuel",
	recipe = "mcl_farming:hoe_wood",
	burntime = 10,
})

minetest.register_tool("mcl_farming:hoe_stone", {
	description = S("Stone Hoe"),
	_doc_items_longdesc = hoe_longdesc,
	_doc_items_usagehelp = hoe_usagehelp,
	inventory_image = "farming_tool_stonehoe.png",
	on_place = hoe_on_place_function(132),
	groups = { tool=1, hoe=1 },
	tool_capabilities = {
		full_punch_interval = 0.5,
		damage_groups = { fleshy = 1, }
	},
	_repair_material = "mcl_core:cobblestone",
})

minetest.register_craft({
	output = "mcl_farming:hoe_stone",
	recipe = {
		{"mcl_core:cobble", "mcl_core:cobble"},
		{"", "mcl_core:stick"},
		{"", "mcl_core:stick"}
	}
})
minetest.register_craft({
	output = "mcl_farming:hoe_stone",
	recipe = {
		{"mcl_core:cobble", "mcl_core:cobble"},
		{"mcl_core:stick", ""},
		{"mcl_core:stick", ""}
	}
})

minetest.register_tool("mcl_farming:hoe_iron", {
	description = S("Iron Hoe"),
	_doc_items_longdesc = hoe_longdesc,
	_doc_items_usagehelp = hoe_usagehelp,
	inventory_image = "farming_tool_steelhoe.png",
	on_place = hoe_on_place_function(251),
	groups = { tool=1, hoe=1 },
	tool_capabilities = {
		-- 1/3
		full_punch_interval = 0.33333333,
		damage_groups = { fleshy = 1, }
	},
	_repair_material = "mcl_core:iron_ingot",
})

minetest.register_craft({
	output = "mcl_farming:hoe_iron",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot"},
		{"", "mcl_core:stick"},
		{"", "mcl_core:stick"}
	}
})
minetest.register_craft({
	output = "mcl_farming:hoe_iron",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot"},
		{"mcl_core:stick", ""},
		{"mcl_core:stick", ""}
	}
})

minetest.register_craft({
	type = "cooking",
	output = "mcl_core:iron_nugget",
	recipe = "mcl_farming:hoe_iron",
	cooktime = 10,
})

minetest.register_tool("mcl_farming:hoe_gold", {
	description = S("Golden Hoe"),
	_doc_items_longdesc = hoe_longdesc,
	_doc_items_usagehelp = hoe_usagehelp,
	inventory_image = "farming_tool_goldhoe.png",
	on_place = hoe_on_place_function(33),
	groups = { tool=1, hoe=1 },
	tool_capabilities = {
		full_punch_interval = 1,
		damage_groups = { fleshy = 1, }
	},
	_repair_material = "mcl_core:gold_ingot",
})

minetest.register_craft({
	output = "mcl_farming:hoe_gold",
	recipe = {
		{"mcl_core:gold_ingot", "mcl_core:gold_ingot"},
		{"", "mcl_core:stick"},
		{"", "mcl_core:stick"}
	}
})
minetest.register_craft({
	output = "mcl_farming:hoe_gold",
	recipe = {
		{"mcl_core:gold_ingot", "mcl_core:gold_ingot"},
		{"mcl_core:stick", ""},
		{"mcl_core:stick", ""}
	}
})



minetest.register_craft({
	type = "cooking",
	output = "mcl_core:gold_nugget",
	recipe = "mcl_farming:hoe_gold",
	cooktime = 10,
})

minetest.register_tool("mcl_farming:hoe_diamond", {
	description = S("Diamond Hoe"),
	_doc_items_longdesc = hoe_longdesc,
	_doc_items_usagehelp = hoe_usagehelp,
	inventory_image = "farming_tool_diamondhoe.png",
	on_place = hoe_on_place_function(1562),
	groups = { tool=1, hoe=1 },
	tool_capabilities = {
		full_punch_interval = 0.25,
		damage_groups = { fleshy = 1, }
	},
	_repair_material = "mcl_core:diamond",
})

minetest.register_craft({
	output = "mcl_farming:hoe_diamond",
	recipe = {
		{"mcl_core:diamond", "mcl_core:diamond"},
		{"", "mcl_core:stick"},
		{"", "mcl_core:stick"}
	}
})
minetest.register_craft({
	output = "mcl_farming:hoe_diamond",
	recipe = {
		{"mcl_core:diamond", "mcl_core:diamond"},
		{"mcl_core:stick", ""},
		{"mcl_core:stick", ""}
	}
})
