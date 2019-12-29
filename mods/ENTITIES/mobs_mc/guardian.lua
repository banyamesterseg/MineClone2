-- v1.4

--###################
--################### GUARDIAN
--###################

local S = minetest.get_translator("mobs_mc")

mobs:register_mob("mobs_mc:guardian", {
	type = "monster",
	hp_min = 30,
	hp_max = 30,
	breath_max = -1,
    	passive = false,
	attack_type = "dogfight",
	pathfinding = 1,
	view_range = 16,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 6,
	reach = 3,
	collisionbox = {-0.425, 0.25, -0.425, 0.425, 1.1, 0.425},
	visual = "mesh",
	mesh = "mobs_mc_guardian.b3d",
	textures = {
		{"mobs_mc_guardian.png"},
	},
	visual_size = {x=3, y=3},
	sounds = {
		damage = "mobs_mc_squid_hurt",
		-- TODO: more and better sounds
		distance = 16,
	},
	animation = {
		stand_speed = 25, walk_speed = 25, run_speed = 50,
		stand_start = 0,		stand_end = 20,
		walk_start = 0,		walk_end = 20,
		run_start = 0,		run_end = 20,
	},
	drops = {
		-- Greatly increased amounts of prismarine
		{name = mobs_mc.items.prismarine_shard,
		chance = 1,
		min = 0,
		max = 32,},
		-- TODO: Reduce of drops when ocean monument is ready.

		-- The following drops are approximations
		-- Fish / prismarine crystal
		{name = mobs_mc.items.fish_raw,
		chance = 4,
		min = 1,
		max = 1,},
		{name = mobs_mc.items.prismarine_crystals,
		chance = 4,
		min = 1,
		max = 2,},

		-- Rare drop: fish
		{name = mobs_mc.items.fish_raw,
		chance = 160, -- 2.5% / 4
		min = 1,
		max = 1,},
		{name = mobs_mc.items.salmon_raw,
		chance = 160,
		min = 1,
		max = 1,},
		{name = mobs_mc.items.clownfish_raw,
		chance = 160,
		min = 1,
		max = 1,},
		{name = mobs_mc.items.pufferfish_raw,
		chance = 160,
		min = 1,
		max = 1,},
	},
	fly = true,
	fly_in = { mobs_mc.items.water_source, mobs_mc.items.river_water_source },
	stepheight = 0.1,
	jump = false,
	view_range = 16,
})

mobs:spawn_specific("mobs_mc:guardian", mobs_mc.spawn.water, mobs_mc.spawn_water, 0, minetest.LIGHT_MAX+1, 30, 25000, 2, mobs_mc.spawn_height.overworld_min, mobs_mc.spawn_height.water - 10)

-- spawn eggs
mobs:register_egg("mobs_mc:guardian", S("Guardian"), "mobs_mc_spawn_icon_guardian.png", 0)
