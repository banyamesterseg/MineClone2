--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")
local mod_bows = minetest.get_modpath("mcl_bows") ~= nil

--###################
--################### SKELETON
--###################



local skeleton = {
	type = "monster",
	hp_min = 20,
	hp_max = 20,
	breath_max = -1,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.98, 0.3},
	pathfinding = 1,
	group_attack = true,
	visual = "mesh",
	mesh = "mobs_mc_skeleton.b3d",
	textures = { {
		"mcl_bows_bow_0.png", -- bow
		"mobs_mc_skeleton.png", -- skeleton
	} },
	visual_size = {x=3, y=3},
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_mc_skeleton_random",
		death = "mobs_mc_skeleton_death",
		damage = "mobs_mc_skeleton_hurt",
		distance = 16,
	},
	walk_velocity = 1.2,
	run_velocity = 2.4,
	damage = 2,
	reach = 2,
	drops = {
		{name = mobs_mc.items.arrow,
		chance = 1,
		min = 0,
		max = 2,},
		{name = mobs_mc.items.bow,
		chance = 11,
		min = 1,
		max = 1,},
		{name = mobs_mc.items.bone,
		chance = 1,
		min = 0,
		max = 2,},

		-- Head
		-- TODO: Only drop if killed by charged creeper
		{name = mobs_mc.items.head_skeleton,
		chance = 200, -- 0.5% chance
		min = 1,
		max = 1,},
	},
	animation = {
		stand_speed = 15,
		stand_start = 0,
		stand_end = 40,
		walk_speed = 15,
		walk_start = 40,
		walk_end = 60,
		run_speed = 30,
		shoot_start = 70,
		shoot_end = 90,
		die_start = 160,
		die_end = 170,
		die_speed = 15,
		die_loop = false,
	},
	sunlight_damage = 1,
	view_range = 16,
	fear_height = 4,
	attack_type = "dogshoot",
	arrow = "mcl_bows:arrow_entity",
	shoot_arrow = function(self, pos, dir)
		if mod_bows then
			-- 2-4 damage per arrow
			local dmg = math.max(4, math.random(2, 8))
			mcl_bows.shoot_arrow("mcl_bows:arrow", pos, dir, self.object:get_yaw(), self.object, nil, dmg)
		end
	end,
	shoot_interval = 2,
	shoot_offset = 1.5,
	dogshoot_switch = 1,
	dogshoot_count_max =1.8,
}

mobs:register_mob("mobs_mc:skeleton", skeleton)


--###################
--################### STRAY
--###################

local stray = table.copy(skeleton)
stray.mesh = "mobs_mc_stray.b3d"
stray.textures = {
	{
		"mcl_bows_bow_0.png",
		"mobs_mc_stray.png",
		"mobs_mc_stray_overlay.png",
	},
}
-- TODO: different sound (w/ echo)
-- TODO: stray's arrow inflicts slowness status
table.insert(stray.drops, {
	-- Chance to drop additional arrow.
	-- TODO: Should be tipped arrow of slowness
	name = mobs_mc.items.arrow,
	chance = 2,
	min = 1,
	max = 1,
})

mobs:register_mob("mobs_mc:stray", stray)

-- compatibility
mobs:alias_mob("mobs:skeleton", "mobs_mc:skeleton")

-- Overworld spawn
mobs:spawn_specific("mobs_mc:skeleton", mobs_mc.spawn.solid, {"air"}, 0, 7, 20, 17000, 2, mobs_mc.spawn_height.overworld_min, mobs_mc.spawn_height.overworld_max)
-- Nether spawn
mobs:spawn_specific("mobs_mc:skeleton", mobs_mc.spawn.nether_fortress, {"air"}, 0, 7, 30, 10000, 3, mobs_mc.spawn_height.nether_min, mobs_mc.spawn_height.nether_max)

-- Stray spawn
-- TODO: Spawn directly under the sky
mobs:spawn_specific("mobs_mc:stray", mobs_mc.spawn.snow, {"air"}, 0, 7, 20, 19000, 2, mobs_mc.spawn_height.water, mobs_mc.spawn_height.overworld_max)


-- spawn eggs
mobs:register_egg("mobs_mc:skeleton", S("Skeleton"), "mobs_mc_spawn_icon_skeleton.png", 0)
mobs:register_egg("mobs_mc:stray", S("Stray"), "mobs_mc_spawn_icon_stray.png", 0)

if minetest.settings:get_bool("log_mods") then
	minetest.log("action", "MC Skeleton loaded")
end
