
-- API for Mobs Redo: MineClone 2 Edition (MRM)

mobs = {}
mobs.mod = "mrm"
mobs.version = "20180531" -- don't rely too much on this, rarely updated, if ever

local MAX_MOB_NAME_LENGTH = 30

-- Localize
local MP = minetest.get_modpath(minetest.get_current_modname())
local S = minetest.get_translator("mcl_mobs")

-- CMI support check
local use_cmi = minetest.global_exists("cmi")


-- Invisibility mod check
mobs.invis = {}
if minetest.global_exists("invisibility") then
	mobs.invis = invisibility
end


-- creative check
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function mobs.is_creative(name)
	return creative_mode_cache or minetest.check_player_privs(name, {creative = true})
end


-- localize math functions
local pi = math.pi
local sin = math.sin
local cos = math.cos
local abs = math.abs
local min = math.min
local max = math.max
local atann = math.atan
local random = math.random
local floor = math.floor
local atan = function(x)
	if not x or x ~= x then
		return 0
	else
		return atann(x)
	end
end


-- Load settings
local damage_enabled = minetest.settings:get_bool("enable_damage")
local mobs_spawn = minetest.settings:get_bool("mobs_spawn") ~= false
local peaceful_only = minetest.settings:get_bool("only_peaceful_mobs")
local disable_blood = minetest.settings:get_bool("mobs_disable_blood")
local mobs_drop_items = minetest.settings:get_bool("mobs_drop_items") ~= false
local mobs_griefing = minetest.settings:get_bool("mobs_griefing") ~= false
local creative = minetest.settings:get_bool("creative_mode")
local spawn_protected = minetest.settings:get_bool("mobs_spawn_protected") ~= false
-- TODO
local remove_far = false
local difficulty = tonumber(minetest.settings:get("mob_difficulty")) or 1.0
local show_health = false
local max_per_block = tonumber(minetest.settings:get("max_objects_per_block") or 99)
local mobs_spawn_chance = tonumber(minetest.settings:get("mobs_spawn_chance") or 2.5)

-- Peaceful mode message so players will know there are no monsters
if peaceful_only then
	minetest.register_on_joinplayer(function(player)
		minetest.chat_send_player(player:get_player_name(),
			S("Peaceful mode active! No monsters will spawn."))
	end)
end

-- calculate aoc range for mob count
local aosrb = tonumber(minetest.settings:get("active_object_send_range_blocks"))
local abr = tonumber(minetest.settings:get("active_block_range"))
local aoc_range = max(aosrb, abr) * 16

-- pathfinding settings
local enable_pathfinding = true
local stuck_timeout = 3 -- how long before mob gets stuck in place and starts searching
local stuck_path_timeout = 10 -- how long will mob follow path before giving up

-- default nodes
local node_fire = "mcl_fire:fire"
local node_permanent_flame = "mcl_fire:eternal_fire"
local node_ice = "mcl_core:ice"
local node_snowblock = "mcl_core:snowblock"
local node_snow = "mcl_core:snow"
mobs.fallback_node = minetest.registered_aliases["mapgen_dirt"] or "mcl_core:dirt"

local mod_weather = minetest.get_modpath("mcl_weather") ~= nil
local mod_tnt = minetest.get_modpath("mcl_tnt") ~= nil
local mod_mobspawners = minetest.get_modpath("mcl_mobspawners") ~= nil
local mod_hunger = minetest.get_modpath("mcl_hunger") ~= nil

-- play sound
local mob_sound = function(self, soundname, is_opinion, fixed_pitch)

	local soundinfo
	if self.sounds_child and self.child then
		soundinfo = self.sounds_child
	elseif self.sounds then
		soundinfo = self.sounds
	end
	if not soundinfo then
		return
	end
	local sound = soundinfo[soundname]
	if sound then
		if is_opinion and self.opinion_sound_cooloff > 0 then
			return
		end
		local pitch
		if not fixed_pitch then
			local base_pitch = soundinfo.base_pitch
			if not base_pitch then
				base_pitch = 1
			end
			if self.child and (not self.sounds_child) then
				-- Children have higher pitch
				pitch = base_pitch * 1.5
			else
				pitch = base_pitch
			end
			-- randomize the pitch a bit
			pitch = pitch + math.random(-10, 10) * 0.005
		end
		minetest.sound_play(sound, {
			object = self.object,
			gain = 1.0,
			max_hear_distance = self.sounds.distance,
			pitch = pitch,
		})
		self.opinion_sound_cooloff = 1
	end
end


-- attack player/mob
local do_attack = function(self, player)

	if self.state == "attack" then
		return
	end

	self.attack = player
	self.state = "attack"

	-- TODO: Implement war_cry sound without being annoying
	--if random(0, 100) < 90 then
		--mob_sound(self, "war_cry", true)
	--end
end


-- move mob in facing direction
local set_velocity = function(self, v)

	-- do not move if mob has been ordered to stay
	if self.order == "stand" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
		return
	end

	local yaw = (self.object:get_yaw() or 0) + self.rotate

	self.object:set_velocity({
		x = sin(yaw) * -v,
		y = self.object:get_velocity().y,
		z = cos(yaw) * v
	})
end


-- calculate mob velocity
local get_velocity = function(self)

	local v = self.object:get_velocity()

	return (v.x * v.x + v.z * v.z) ^ 0.5
end


-- set and return valid yaw
local set_yaw = function(self, yaw, delay)

	if not yaw or yaw ~= yaw then
		yaw = 0
	end

	delay = delay or 0

	if delay == 0 then
		self.object:set_yaw(yaw)
		return yaw
	end

	self.target_yaw = yaw
	self.delay = delay

	return self.target_yaw
end

-- global function to set mob yaw
function mobs:yaw(self, yaw, delay)
	set_yaw(self, yaw, delay)
end

local add_texture_mod = function(self, mod)
	local full_mod = ""
	local already_added = false
	for i=1, #self.texture_mods do
		if mod == self.texture_mods[i] then
			already_added = true
		end
		full_mod = full_mod .. self.texture_mods[i]
	end
	if not already_added then
		full_mod = full_mod .. mod
		table.insert(self.texture_mods, mod)
	end
	self.object:set_texture_mod(full_mod)
end
local remove_texture_mod = function(self, mod)
	local full_mod = ""
	local remove = {}
	for i=1, #self.texture_mods do
		if self.texture_mods[i] ~= mod then
			full_mod = full_mod .. self.texture_mods[i]
		else
			table.insert(remove, i)
		end
	end
	for i=#remove, 1 do
		table.remove(self.texture_mods, remove[i])
	end
	self.object:set_texture_mod(full_mod)
end

-- set defined animation
local set_animation = function(self, anim)

	if not self.animation
	or not anim then return end

	self.animation.current = self.animation.current or ""

	if anim == self.animation.current
	or not self.animation[anim .. "_start"]
	or not self.animation[anim .. "_end"] then
		return
	end

	self.animation.current = anim

	self.object:set_animation({
		x = self.animation[anim .. "_start"],
		y = self.animation[anim .. "_end"]},
		self.animation[anim .. "_speed"] or self.animation.speed_normal or 15,
		0, self.animation[anim .. "_loop"] ~= false)
end


-- above function exported for mount.lua
function mobs:set_animation(self, anim)
	set_animation(self, anim)
end


-- check line of sight (BrunoMine)
local line_of_sight = function(self, pos1, pos2, stepsize)

	stepsize = stepsize or 1

	local s, pos = minetest.line_of_sight(pos1, pos2, stepsize)

	-- normal walking and flying mobs can see you through air
	if s == true then
		return true
	end

	-- New pos1 to be analyzed
	local npos1 = {x = pos1.x, y = pos1.y, z = pos1.z}

	local r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

	-- Checks the return
	if r == true then return true end

	-- Nodename found
	local nn = minetest.get_node(pos).name

	-- Target Distance (td) to travel
	local td = vector.distance(pos1, pos2)

	-- Actual Distance (ad) traveled
	local ad = 0

	-- It continues to advance in the line of sight in search of a real
	-- obstruction which counts as 'normal' nodebox.
	while minetest.registered_nodes[nn]
	and minetest.registered_nodes[nn].walkable == false do

		-- Check if you can still move forward
		if td < ad + stepsize then
			return true -- Reached the target
		end

		-- Moves the analyzed pos
		local d = vector.distance(pos1, pos2)

		npos1.x = ((pos2.x - pos1.x) / d * stepsize) + pos1.x
		npos1.y = ((pos2.y - pos1.y) / d * stepsize) + pos1.y
		npos1.z = ((pos2.z - pos1.z) / d * stepsize) + pos1.z

		-- NaN checks
		if d == 0
		or npos1.x ~= npos1.x
		or npos1.y ~= npos1.y
		or npos1.z ~= npos1.z then
			return false
		end

		ad = ad + stepsize

		-- scan again
		r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

		if r == true then return true end

		-- New Nodename found
		nn = minetest.get_node(pos).name

	end

	return false
end


-- are we flying in what we are suppose to? (taikedz)
local flight_check = function(self, pos_w)

	local nod = self.standing_in
	local def = minetest.registered_nodes[nod]

	if not def then return false end -- nil check

	if type(self.fly_in) == "string"
	and nod == self.fly_in then

		return true

	elseif type(self.fly_in) == "table" then

		for _,fly_in in pairs(self.fly_in) do

			if nod == fly_in then

				return true
			end
		end
	end

	-- stops mobs getting stuck inside stairs and plantlike nodes
	if def.drawtype ~= "airlike"
	and def.drawtype ~= "liquid"
	and def.drawtype ~= "flowingliquid" then
		return true
	end

	return false
end


-- custom particle effects
local effect = function(pos, amount, texture, min_size, max_size, radius, gravity, glow, go_down)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or -10
	glow = glow or 0
	go_down = go_down or false

	local ym
	if go_down then
		ym = 0
	else
		ym = -radius
	end

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = ym, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = 0, y = gravity, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end

local damage_effect = function(self, damage)
	-- damage particles
	if (not disable_blood) and damage > 0 then

		local amount_large = math.floor(damage / 2)
		local amount_small = damage % 2

		local pos = self.object:get_pos()

		pos.y = pos.y + (self.collisionbox[5] - self.collisionbox[2]) * .5

		local texture = "mobs_blood.png"
		-- full heart damage (one particle for each 2 HP damage)
		if amount_large > 0 then
			effect(pos, amount_large, texture, 2, 2, 1.75, 0, nil, true)
		end
		-- half heart damage (one additional particle if damage is an odd number)
		if amount_small > 0 then
			-- TODO: Use "half heart"
			effect(pos, amount_small, texture, 1, 1, 1.75, 0, nil, true)
		end
	end
end

local update_tag = function(self)
	self.object:set_properties({
		nametag = self.nametag,
	})

end


-- drop items
local item_drop = function(self, cooked)

	-- no drops if disabled by setting
	if not mobs_drop_items then return end

	-- no drops for child mobs (except monster)
	if (self.child and self.type ~= "monster") then
		return
	end

	local obj, item, num
	local pos = self.object:get_pos()

	self.drops = self.drops or {} -- nil check

	for n = 1, #self.drops do

		if random(1, self.drops[n].chance) == 1 then

			num = random(self.drops[n].min or 1, self.drops[n].max or 1)
			item = self.drops[n].name

			-- cook items when true
			if cooked then

				local output = minetest.get_craft_result({
					method = "cooking", width = 1, items = {item}})

				if output and output.item and not output.item:is_empty() then
					item = output.item:get_name()
				end
			end

			-- add item if it exists
			obj = minetest.add_item(pos, ItemStack(item .. " " .. num))

			if obj and obj:get_luaentity() then

				obj:set_velocity({
					x = random(-10, 10) / 9,
					y = 6,
					z = random(-10, 10) / 9,
				})
			elseif obj then
				obj:remove() -- item does not exist
			end
		end
	end

	self.drops = {}
end


-- check if mob is dead or only hurt
local check_for_death = function(self, cause, cmi_cause)

	-- has health actually changed?
	if self.health == self.old_health and self.health > 0 then
		return
	end

	local damaged = self.health < self.old_health
	self.old_health = self.health

	-- still got some health?
	if self.health > 0 then

		-- make sure health isn't higher than max
		if self.health > self.hp_max then
			self.health = self.hp_max
		end

		-- play damage sound if health was reduced and make mob flash red.
		if damaged then
			add_texture_mod(self, "^[colorize:#FF000040")
			minetest.after(.2, function(self)
				if self and self.object then
					remove_texture_mod(self, "^[colorize:#FF000040")
				end
			end, self)
			mob_sound(self, "damage")
		end

		-- backup nametag so we can show health stats
		if not self.nametag2 then
			self.nametag2 = self.nametag or ""
		end

		if show_health
		and (cmi_cause and cmi_cause.type == "punch") then

			self.htimer = 2
			self.nametag = "♥ " .. self.health .. " / " .. self.hp_max

			update_tag(self)
		end

		return false
	end

	-- dropped cooked item if mob died in lava
	if cause == "lava" then
		item_drop(self, true)
	else
		item_drop(self, nil)
	end

	mob_sound(self, "death")

	local pos = self.object:get_pos()

	-- execute custom death function
	if self.on_die then

		self.on_die(self, pos)

		if use_cmi then
			cmi.notify_die(self.object, cmi_cause)
		end

		self.object:remove()

		return true
	end

	-- default death function and die animation (if defined)
	if self.animation
	and self.animation.die_start
	and self.animation.die_end then

		local frames = self.animation.die_end - self.animation.die_start
		local speed = self.animation.die_speed or 15
		local length = max(frames / speed, 0)

		self.attack = nil
		self.v_start = false
		self.timer = 0
		self.blinktimer = 0
		self.passive = true
		self.state = "die"
		set_velocity(self, 0)
		set_animation(self, "die")

		minetest.after(length, function(self)
			if not self.object:get_luaentity() then
				return
			end
			if use_cmi  then
				cmi.notify_die(self.object, cmi_cause)
			end

			self.object:remove()
		end, self)
	else

		if use_cmi then
			cmi.notify_die(self.object, cmi_cause)
		end

		self.object:remove()
	end

	effect(pos, 20, "tnt_smoke.png")

	return true
end


-- check if within physical map limits (-30911 to 30927)
local within_limits = function(pos, radius)

	if  (pos.x - radius) > -30913
	and (pos.x + radius) <  30928
	and (pos.y - radius) > -30913
	and (pos.y + radius) <  30928
	and (pos.z - radius) > -30913
	and (pos.z + radius) <  30928 then
		return true -- within limits
	end

	return false -- beyond limits
end


-- is mob facing a cliff
local is_at_cliff = function(self)

	if self.fear_height == 0 then -- 0 for no falling protection!
		return false
	end

	local yaw = self.object:get_yaw()
	local dir_x = -sin(yaw) * (self.collisionbox[4] + 0.5)
	local dir_z = cos(yaw) * (self.collisionbox[4] + 0.5)
	local pos = self.object:get_pos()
	local ypos = pos.y + self.collisionbox[2] -- just above floor

	if minetest.line_of_sight(
		{x = pos.x + dir_x, y = ypos, z = pos.z + dir_z},
		{x = pos.x + dir_x, y = ypos - self.fear_height, z = pos.z + dir_z}
	, 1) then

		return true
	end

	return false
end


-- get node but use fallback for nil or unknown
local node_ok = function(pos, fallback)

	fallback = fallback or mobs.fallback_node

	local node = minetest.get_node_or_nil(pos)

	if node and minetest.registered_nodes[node.name] then
		return node
	end

	return minetest.registered_nodes[fallback]
end


-- environmental damage (water, lava, fire, light etc.)
local do_env_damage = function(self)

	-- feed/tame text timer (so mob 'full' messages dont spam chat)
	if self.htimer > 0 then
		self.htimer = self.htimer - 1
	end

	-- reset nametag after showing health stats
	if self.htimer < 1 and self.nametag2 then

		self.nametag = self.nametag2
		self.nametag2 = nil

		update_tag(self)
	end

	local pos = self.object:get_pos()

	self.time_of_day = minetest.get_timeofday()

	-- remove mob if beyond map limits
	if not within_limits(pos, 0) then
		self.object:remove()
		return
	end


	local deal_light_damage = function(self, pos, damage)
		if not (mod_weather and (mcl_weather.rain.raining or mcl_weather.state == "snow") and mcl_weather.is_outdoor(pos)) then
			self.health = self.health - damage

			effect(pos, 5, "tnt_smoke.png")

			if check_for_death(self, "light", {type = "light"}) then return end
		end
	end

	-- bright light harms mob
	if self.light_damage ~= 0 and (minetest.get_node_light(pos) or 0) > 12 then
		deal_light_damage(self, pos, self.light_damage)
	end
	local _, dim = mcl_worlds.y_to_layer(pos.y)
	if self.sunlight_damage ~= 0 and (minetest.get_node_light(pos) or 0) >= minetest.LIGHT_MAX and dim == "overworld" then
		deal_light_damage(self, pos, self.sunlight_damage)
	end

	local y_level = self.collisionbox[2]

	if self.child then
		y_level = self.collisionbox[2] * 0.5
	end

	-- what is mob standing in?
	pos.y = pos.y + y_level + 0.25 -- foot level
	self.standing_in = node_ok(pos, "air").name

	-- don't fall when on ignore, just stand still
	if self.standing_in == "ignore" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
	end

	local nodef = minetest.registered_nodes[self.standing_in]

	-- rain
	if self.rain_damage and mod_weather then
		if mcl_weather.rain.raining and mcl_weather.is_outdoor(pos) then

			self.health = self.health - self.rain_damage

			if check_for_death(self, "rain", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end
	end

	pos.y = pos.y + 1 -- for particle effect position

	-- water damage
	if self.water_damage
	and nodef.groups.water then

		if self.water_damage ~= 0 then

			self.health = self.health - self.water_damage

			effect(pos, 5, "tnt_smoke.png", nil, nil, 1, nil)

			if check_for_death(self, "water", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- lava damage
	elseif self.lava_damage
	and (nodef.groups.lava) then

		if self.lava_damage ~= 0 then

			self.health = self.health - self.lava_damage

			effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)

			if check_for_death(self, "lava", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- fire damage
	elseif self.fire_damage
	and (nodef.groups.fire) then

		if self.fire_damage ~= 0 then

			self.health = self.health - self.fire_damage

			effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)

			if check_for_death(self, "fire", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- damage_per_second node check
	elseif nodef.damage_per_second ~= 0 then

		self.health = self.health - nodef.damage_per_second

		effect(pos, 5, "tnt_smoke.png")

		if check_for_death(self, "dps", {type = "environment",
				pos = pos, node = self.standing_in}) then return end
	end

	-- Drowning damage
	if self.breath_max ~= -1 then
		local drowning = false
		if self.breathes_in_water then
			if minetest.get_item_group(self.standing_in, "water") == 0 then
				drowning = true
			end
		elseif nodef.drowning > 0 then
			drowning = true
		end
		if drowning then

			self.breath = math.max(0, self.breath - 1)

			effect(pos, 2, "bubble.png", nil, nil, 1, nil)
			if self.breath <= 0 then
				local dmg
				if nodef.drowning > 0 then
					dmg = nodef.drowning
				else
					dmg = 4
				end
				damage_effect(self, dmg)
				self.health = self.health - dmg
			end
			if check_for_death(self, "drowning", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		else
			self.breath = math.min(self.breath_max, self.breath + 1)
		end
	end

	--- suffocation inside solid node
	-- FIXME: Redundant with mcl_playerplus
	if (self.suffocation == true)
	and (nodef.walkable == nil or nodef.walkable == true)
	and (nodef.collision_box == nil or nodef.collision_box.type == "regular")
	and (nodef.node_box == nil or nodef.node_box.type == "regular")
	and (nodef.groups.disable_suffocation ~= 1)
	and (nodef.groups.opaque == 1) then

		-- 2 damage per second
		-- TODO: Deal this damage once every 1/2 second
		self.health = self.health - 2

		if check_for_death(self, "suffocation", {type = "environment",
				pos = pos, node = self.standing_in}) then return end
	end

	check_for_death(self, "", {type = "unknown"})
end


-- jump if facing a solid node (not fences or gates)
local do_jump = function(self)

	if not self.jump
	or self.jump_height == 0
	or self.fly
	or (self.child and self.type ~= "monster")
	or self.order == "stand" then
		return false
	end

	self.facing_fence = false

	-- something stopping us while moving?
	if self.state ~= "stand"
	and get_velocity(self) > 0.5
	and self.object:get_velocity().y ~= 0 then
		return false
	end

	local pos = self.object:get_pos()
	local yaw = self.object:get_yaw()

	-- what is mob standing on?
	pos.y = pos.y + self.collisionbox[2] - 0.2

	local nod = node_ok(pos)

	if minetest.registered_nodes[nod.name].walkable == false then
		return false
	end

	-- where is front
	local dir_x = -sin(yaw) * (self.collisionbox[4] + 0.5)
	local dir_z = cos(yaw) * (self.collisionbox[4] + 0.5)

	-- what is in front of mob?
	local nod = node_ok({
		x = pos.x + dir_x,
		y = pos.y + 0.5,
		z = pos.z + dir_z
	})

	-- this is used to detect if there's a block on top of the block in front of the mob.
	-- If there is, there is no point in jumping as we won't manage.
	local nodTop = node_ok({
		x = pos.x + dir_x,
		y = pos.y + 1.5,
		z = pos.z + dir_z
	}, "air")

	-- we don't attempt to jump if there's a stack of blocks blocking
	if minetest.registered_nodes[nodTop.name] == true then
		return false
	end

	-- thin blocks that do not need to be jumped
	if nod.name == node_snow then
		return false
	end

	if self.walk_chance == 0
	or minetest.registered_items[nod.name].walkable then

		if not nod.name:find("fence")
		and not nod.name:find("fence_gate")
		and not nod.name:find("wall") then

			local v = self.object:get_velocity()

			v.y = self.jump_height

			set_animation(self, "jump") -- only when defined

			self.object:set_velocity(v)

			-- when in air move forward
			minetest.after(0.3, function(self, v)
				if not self.object or not self.object:get_luaentity() then
					return
				end
				self.object:set_acceleration({
					x = v.x * 2,
					y = 0,
					z = v.z * 2,
				})
			end, self, v)

			if self.jump_sound_cooloff <= 0 then
				mob_sound(self, "jump")
				self.jump_sound_cooloff = 0.5
			end
		else
			self.facing_fence = true
		end

		-- if we jumped against a block/wall 4 times then turn
		if self.object:get_velocity().x ~= 0
		and self.object:get_velocity().z ~= 0 then

			self.jump_count = (self.jump_count or 0) + 1

			if self.jump_count == 4 then

				local yaw = self.object:get_yaw() or 0

				yaw = set_yaw(self, yaw + 1.35, 8)

				self.jump_count = 0
			end
		end

		return true
	end

	return false
end


-- blast damage to entities nearby (modified from TNT mod)
local entity_physics = function(pos, radius)

	radius = radius * 2

	local objs = minetest.get_objects_inside_radius(pos, radius)
	local obj_pos, dist

	for n = 1, #objs do

		obj_pos = objs[n]:get_pos()

		dist = vector.distance(pos, obj_pos)
		if dist < 1 then dist = 1 end

		local damage = floor((4 / dist) * radius)
		local ent = objs[n]:get_luaentity()

		-- punches work on entities AND players
		objs[n]:punch(objs[n], 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = damage},
		}, pos)
	end
end


-- should mob follow what I'm holding ?
local follow_holding = function(self, clicker)

	if mobs.invis[clicker:get_player_name()] then
		return false
	end

	local item = clicker:get_wielded_item()
	local t = type(self.follow)

	-- single item
	if t == "string"
	and item:get_name() == self.follow then
		return true

	-- multiple items
	elseif t == "table" then

		for no = 1, #self.follow do

			if self.follow[no] == item:get_name() then
				return true
			end
		end
	end

	return false
end


-- find two animals of same type and breed if nearby and horny
local breed = function(self)

	-- child takes 240 seconds before growing into adult
	if self.child == true then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer > 240 then

			self.child = false
			self.hornytimer = 0

			self.object:set_properties({
				textures = self.base_texture,
				mesh = self.base_mesh,
				visual_size = self.base_size,
				collisionbox = self.base_colbox,
				selectionbox = self.base_selbox,
			})

			-- custom function when child grows up
			if self.on_grown then
				self.on_grown(self)
			else
				-- jump when fully grown so as not to fall into ground
				self.object:set_velocity({
					x = 0,
					y = self.jump_height,
					z = 0
				})
			end
		end

		return
	end

	-- horny animal can mate for 40 seconds,
	-- afterwards horny animal cannot mate again for 200 seconds
	if self.horny == true
	and self.hornytimer < 240 then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer >= 240 then
			self.hornytimer = 0
			self.horny = false
		end
	end

	-- find another same animal who is also horny and mate if nearby
	if self.horny == true
	and self.hornytimer <= 40 then

		local pos = self.object:get_pos()

		effect({x = pos.x, y = pos.y + 1, z = pos.z}, 8, "heart.png", 3, 4, 1, 0.1)

		local objs = minetest.get_objects_inside_radius(pos, 3)
		local num = 0
		local ent = nil

		for n = 1, #objs do

			ent = objs[n]:get_luaentity()

			-- check for same animal with different colour
			local canmate = false

			if ent then

				if ent.name == self.name then
					canmate = true
				else
					local entname = string.split(ent.name,":")
					local selfname = string.split(self.name,":")

					if entname[1] == selfname[1] then
						entname = string.split(entname[2],"_")
						selfname = string.split(selfname[2],"_")

						if entname[1] == selfname[1] then
							canmate = true
						end
					end
				end
			end

			if ent
			and canmate == true
			and ent.horny == true
			and ent.hornytimer <= 40 then
				num = num + 1
			end

			-- found your mate? then have a baby
			if num > 1 then

				self.hornytimer = 41
				ent.hornytimer = 41

				-- spawn baby
				minetest.after(5, function(parent1, parent2, pos)
					if not parent1.object:get_luaentity() then
						return
					end
					if not parent2.object:get_luaentity() then
						return
					end

					-- custom breed function
					if parent1.on_breed then
						-- when false, skip going any further
						if parent1.on_breed(parent1, parent2) == false then
							return
						end
					end

					local child = mobs:spawn_child(pos, parent1.name)

					local ent_c = child:get_luaentity()


					-- Use texture of one of the parents
					local p = math.random(1, 2)
					if p == 1 then
						ent_c.base_texture = parent1.base_texture
					else
						ent_c.base_texture = parent2.base_texture
					end
					child:set_properties({
						textures = ent_c.base_texture
					})

					-- tamed and owned by parents' owner
					ent_c.tamed = true
					ent_c.owner = parent1.owner
				end, self, ent, pos)

				num = 0

				break
			end
		end
	end
end


-- find and replace what mob is looking for (grass, wheat etc.)
local replace = function(self, pos)

	if not self.replace_rate
	or not self.replace_what
	or self.child == true
	or self.object:get_velocity().y ~= 0
	or random(1, self.replace_rate) > 1 then
		return
	end

	local what, with, y_offset

	if type(self.replace_what[1]) == "table" then

		local num = random(#self.replace_what)

		what = self.replace_what[num][1] or ""
		with = self.replace_what[num][2] or ""
		y_offset = self.replace_what[num][3] or 0
	else
		what = self.replace_what
		with = self.replace_with or ""
		y_offset = self.replace_offset or 0
	end

	pos.y = pos.y + y_offset

	if #minetest.find_nodes_in_area(pos, pos, what) > 0 then

		local oldnode = {name = what}
		local newnode = {name = with}
		local on_replace_return

		if self.on_replace then
			on_replace_return = self.on_replace(self, pos, oldnode, newnode)
		end

		if on_replace_return ~= false then

			if mobs_griefing then
				minetest.set_node(pos, {name = with})
			end

		end
	end
end


-- check if daytime and also if mob is docile during daylight hours
local day_docile = function(self)

	if self.docile_by_day == false then

		return false

	elseif self.docile_by_day == true
	and self.time_of_day > 0.2
	and self.time_of_day < 0.8 then

		return true
	end
end


local los_switcher = false
local height_switcher = false

-- path finding and smart mob routine by rnd, line_of_sight and other edits by Elkien3
local smart_mobs = function(self, s, p, dist, dtime)

	local s1 = self.path.lastpos

	local target_pos = self.attack:get_pos()

	-- is it becoming stuck?
	if abs(s1.x - s.x) + abs(s1.z - s.z) < .5 then
		self.path.stuck_timer = self.path.stuck_timer + dtime
	else
		self.path.stuck_timer = 0
	end

	self.path.lastpos = {x = s.x, y = s.y, z = s.z}

	local use_pathfind = false
	local has_lineofsight = minetest.line_of_sight(
		{x = s.x, y = (s.y) + .5, z = s.z},
		{x = target_pos.x, y = (target_pos.y) + 1.5, z = target_pos.z}, .2)

	-- im stuck, search for path
	if not has_lineofsight then

		if los_switcher == true then
			use_pathfind = true
			los_switcher = false
		end -- cannot see target!
	else
		if los_switcher == false then

			los_switcher = true
			use_pathfind = false

			minetest.after(1, function(self)
				if not self.object:get_luaentity() then
					return
				end
				if has_lineofsight then self.path.following = false end
			end, self)
		end -- can see target!
	end

	if (self.path.stuck_timer > stuck_timeout and not self.path.following) then

		use_pathfind = true
		self.path.stuck_timer = 0

		minetest.after(1, function(self)
			if not self.object:get_luaentity() then
				return
			end
			if has_lineofsight then self.path.following = false end
		end, self)
	end

	if (self.path.stuck_timer > stuck_path_timeout and self.path.following) then

		use_pathfind = true
		self.path.stuck_timer = 0

		minetest.after(1, function(self)
			if not self.object:get_luaentity() then
				return
			end
			if has_lineofsight then self.path.following = false end
		end, self)
	end

	if math.abs(vector.subtract(s,target_pos).y) > self.stepheight then

		if height_switcher then
			use_pathfind = true
			height_switcher = false
		end
	else
		if not height_switcher then
			use_pathfind = false
			height_switcher = true
		end
	end

	if use_pathfind then
		-- lets try find a path, first take care of positions
		-- since pathfinder is very sensitive
		local sheight = self.collisionbox[5] - self.collisionbox[2]

		-- round position to center of node to avoid stuck in walls
		-- also adjust height for player models!
		s.x = floor(s.x + 0.5)
		s.z = floor(s.z + 0.5)

		local ssight, sground = minetest.line_of_sight(s, {
			x = s.x, y = s.y - 4, z = s.z}, 1)

		-- determine node above ground
		if not ssight then
			s.y = sground.y + 1
		end

		local p1 = self.attack:get_pos()

		p1.x = floor(p1.x + 0.5)
		p1.y = floor(p1.y + 0.5)
		p1.z = floor(p1.z + 0.5)

		local dropheight = 6
		if self.fear_height ~= 0 then dropheight = self.fear_height end

		self.path.way = minetest.find_path(s, p1, 16, self.stepheight, dropheight, "A*_noprefetch")

		self.state = ""
		do_attack(self, self.attack)

		-- no path found, try something else
		if not self.path.way then

			self.path.following = false

			 -- lets make way by digging/building if not accessible
			if self.pathfinding == 2 and mobs_griefing then

				-- is player higher than mob?
				if s.y < p1.y then

					-- build upwards
					if not minetest.is_protected(s, "") then

						local ndef1 = minetest.registered_nodes[self.standing_in]

						if ndef1 and (ndef1.buildable_to or ndef1.groups.liquid) then

								minetest.set_node(s, {name = mobs.fallback_node})
						end
					end

					local sheight = math.ceil(self.collisionbox[5]) + 1

					-- assume mob is 2 blocks high so it digs above its head
					s.y = s.y + sheight

					-- remove one block above to make room to jump
					if not minetest.is_protected(s, "") then

						local node1 = node_ok(s, "air").name
						local ndef1 = minetest.registered_nodes[node1]

						if node1 ~= "air"
						and node1 ~= "ignore"
						and ndef1
						and not ndef1.groups.level
						and not ndef1.groups.unbreakable
						and not ndef1.groups.liquid then

							minetest.set_node(s, {name = "air"})
							minetest.add_item(s, ItemStack(node1))

						end
					end

					s.y = s.y - sheight
					self.object:set_pos({x = s.x, y = s.y + 2, z = s.z})

				else -- dig 2 blocks to make door toward player direction

					local yaw1 = self.object:get_yaw() + pi / 2
					local p1 = {
						x = s.x + cos(yaw1),
						y = s.y,
						z = s.z + sin(yaw1)
					}

					if not minetest.is_protected(p1, "") then

						local node1 = node_ok(p1, "air").name
						local ndef1 = minetest.registered_nodes[node1]

						if node1 ~= "air"
							and node1 ~= "ignore"
							and ndef1
							and not ndef1.groups.level
							and not ndef1.groups.unbreakable
							and not ndef1.groups.liquid then

							minetest.add_item(p1, ItemStack(node1))
							minetest.set_node(p1, {name = "air"})
						end

						p1.y = p1.y + 1
						node1 = node_ok(p1, "air").name
						ndef1 = minetest.registered_nodes[node1]

						if node1 ~= "air"
						and node1 ~= "ignore"
						and ndef1
						and not ndef1.groups.level
						and not ndef1.groups.unbreakable
						and not ndef1.groups.liquid then

							minetest.add_item(p1, ItemStack(node1))
							minetest.set_node(p1, {name = "air"})
						end

					end
				end
			end

			-- will try again in 2 second
			self.path.stuck_timer = stuck_timeout - 2
		else
			-- yay i found path
			-- TODO: Implement war_cry sound without being annoying
			--mob_sound(self, "war_cry", true)
			set_velocity(self, self.walk_velocity)

			-- follow path now that it has it
			self.path.following = true
		end
	end
end


-- specific attacks
local specific_attack = function(list, what)

	-- no list so attack default (player, animals etc.)
	if list == nil then
		return true
	end

	-- found entity on list to attack?
	for no = 1, #list do

		if list[no] == what then
			return true
		end
	end

	return false
end


-- monster find someone to attack
local monster_attack = function(self)

	if self.type ~= "monster"
	or not damage_enabled
	or creative
	or self.state == "attack"
	or day_docile(self) then
		return
	end

	local s = self.object:get_pos()
	local p, sp, dist
	local player, obj, min_player
	local type, name = "", ""
	local min_dist = self.view_range + 1
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	for n = 1, #objs do
		if objs[n]:is_player() then
			privs = minetest.get_player_privs(objs[n]:get_player_name())
			if mobs.invis[ objs[n]:get_player_name() ] or privs.invincible or not privs.interact then
				type = ""
			else
				player = objs[n]
				type = "player"
				name = "player"
			end
		else
			obj = objs[n]:get_luaentity()

			if obj then
				player = obj.object
				type = obj.type
				name = obj.name or ""
			end
		end

		-- find specific mob to attack, failing that attack player/npc/animal
		if specific_attack(self.specific_attack, name)
		and (type == "player" or type == "npc"
			or (type == "animal" and self.attack_animals == true)) then

			p = player:get_pos()
			sp = s

			dist = vector.distance(p, s)

			-- aim higher to make looking up hills more realistic
			p.y = p.y + 1
			sp.y = sp.y + 1


			-- choose closest player to attack
			if dist < min_dist
			and line_of_sight(self, sp, p, 2) == true then
				min_dist = dist
				min_player = player
			end
		end
	end

	-- attack player
	if min_player then
		do_attack(self, min_player)
	end
end


-- npc, find closest monster to attack
local npc_attack = function(self)

	if self.type ~= "npc"
	or not self.attacks_monsters
	or self.state == "attack" then
		return
	end

	local p, sp, obj, min_player
	local s = self.object:get_pos()
	local min_dist = self.view_range + 1
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	for n = 1, #objs do

		obj = objs[n]:get_luaentity()

		if obj and obj.type == "monster" then

			p = obj.object:get_pos()
			sp = s

			local dist = vector.distance(p, s)

			-- aim higher to make looking up hills more realistic
			p.y = p.y + 1
			sp.y = sp.y + 1

			if dist < min_dist
			and line_of_sight(self, sp, p, 2) == true then
				min_dist = dist
				min_player = obj.object
			end
		end
	end

	if min_player then
		do_attack(self, min_player)
	end
end


-- specific runaway
local specific_runaway = function(list, what)

	-- no list so do not run
	if list == nil then
		return false
	end

	-- found entity on list to attack?
	for no = 1, #list do

		if list[no] == what then
			return true
		end
	end

	return false
end


-- find someone to runaway from
local runaway_from = function(self)

	if not self.runaway_from then
		return
	end

	local s = self.object:get_pos()
	local p, sp, dist
	local player, obj, min_player
	local type, name = "", ""
	local min_dist = self.view_range + 1
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	for n = 1, #objs do

		if objs[n]:is_player() then

			if mobs.invis[ objs[n]:get_player_name() ]
			or self.owner == objs[n]:get_player_name() then

				type = ""
			else
				player = objs[n]
				type = "player"
				name = "player"
			end
		else
			obj = objs[n]:get_luaentity()

			if obj then
				player = obj.object
				type = obj.type
				name = obj.name or ""
			end
		end

		-- find specific mob to runaway from
		if name ~= "" and name ~= self.name
		and specific_runaway(self.runaway_from, name) then

			p = player:get_pos()
			sp = s

			-- aim higher to make looking up hills more realistic
			p.y = p.y + 1
			sp.y = sp.y + 1

			dist = vector.distance(p, s)


			-- choose closest player/mpb to runaway from
			if dist < min_dist
			and line_of_sight(self, sp, p, 2) == true then
				min_dist = dist
				min_player = player
			end
		end
	end

	if min_player then

		local lp = player:get_pos()
		local vec = {
			x = lp.x - s.x,
			y = lp.y - s.y,
			z = lp.z - s.z
		}

		local yaw = (atan(vec.z / vec.x) + 3 * pi / 2) - self.rotate

		if lp.x > s.x then
			yaw = yaw + pi
		end

		yaw = set_yaw(self, yaw, 4)
		self.state = "runaway"
		self.runaway_timer = 3
		self.following = nil
	end
end


-- follow player if owner or holding item, if fish outta water then flop
local follow_flop = function(self)

	-- find player to follow
	if (self.follow ~= ""
	or self.order == "follow")
	and not self.following
	and self.state ~= "attack"
	and self.state ~= "runaway" then

		local s = self.object:get_pos()
		local players = minetest.get_connected_players()

		for n = 1, #players do

			if vector.distance(players[n]:get_pos(), s) < self.view_range
			and not mobs.invis[ players[n]:get_player_name() ] then

				self.following = players[n]

				break
			end
		end
	end

	if self.type == "npc"
	and self.order == "follow"
	and self.state ~= "attack"
	and self.owner ~= "" then

		-- npc stop following player if not owner
		if self.following
		and self.owner
		and self.owner ~= self.following:get_player_name() then
			self.following = nil
		end
	else
		-- stop following player if not holding specific item
		if self.following
		and self.following:is_player()
		and follow_holding(self, self.following) == false then
			self.following = nil
		end

	end

	-- follow that thing
	if self.following then

		local s = self.object:get_pos()
		local p

		if self.following:is_player() then

			p = self.following:get_pos()

		elseif self.following.object then

			p = self.following.object:get_pos()
		end

		if p then

			local dist = vector.distance(p, s)

			-- dont follow if out of range
			if dist > self.view_range then
				self.following = nil
			else
				local vec = {
					x = p.x - s.x,
					z = p.z - s.z
				}

				local yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

				if p.x > s.x then yaw = yaw + pi end

				yaw = set_yaw(self, yaw, 6)

				-- anyone but standing npc's can move along
				if dist > self.reach
				and self.order ~= "stand" then

					set_velocity(self, self.walk_velocity)

					if self.walk_chance ~= 0 then
						set_animation(self, "walk")
					end
				else
					set_velocity(self, 0)
					set_animation(self, "stand")
				end

				return
			end
		end
	end

	-- swimmers flop when out of their element, and swim again when back in
	if self.fly then
		local s = self.object:get_pos()
		if not flight_check(self, s) then

			self.state = "flop"
			self.object:set_velocity({x = 0, y = -5, z = 0})

			set_animation(self, "stand")

			return
		elseif self.state == "flop" then
			self.state = "stand"
		end
	end
end


-- dogshoot attack switch and counter function
local dogswitch = function(self, dtime)

	-- switch mode not activated
	if not self.dogshoot_switch
	or not dtime then
		return 0
	end

	self.dogshoot_count = self.dogshoot_count + dtime

	if (self.dogshoot_switch == 1
	and self.dogshoot_count > self.dogshoot_count_max)
	or (self.dogshoot_switch == 2
	and self.dogshoot_count > self.dogshoot_count2_max) then

		self.dogshoot_count = 0

		if self.dogshoot_switch == 1 then
			self.dogshoot_switch = 2
		else
			self.dogshoot_switch = 1
		end
	end

	return self.dogshoot_switch
end


-- execute current state (stand, walk, run, attacks)
local do_states = function(self, dtime)

	local yaw = self.object:get_yaw() or 0

	if self.state == "stand" then

		if random(1, 4) == 1 then

			local lp = nil
			local s = self.object:get_pos()
			local objs = minetest.get_objects_inside_radius(s, 3)

			for n = 1, #objs do

				if objs[n]:is_player() then
					lp = objs[n]:get_pos()
					break
				end
			end

			-- look at any players nearby, otherwise turn randomly
			if lp then

				local vec = {
					x = lp.x - s.x,
					z = lp.z - s.z
				}

				yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

				if lp.x > s.x then yaw = yaw + pi end
			else
				yaw = yaw + random(-0.5, 0.5)
			end

			yaw = set_yaw(self, yaw, 8)
		end

		set_velocity(self, 0)
		set_animation(self, "stand")

		-- npc's ordered to stand stay standing
		if self.type ~= "npc"
		or self.order ~= "stand" then

			if self.walk_chance ~= 0
			and self.facing_fence ~= true
			and random(1, 100) <= self.walk_chance
			and is_at_cliff(self) == false then

				set_velocity(self, self.walk_velocity)
				self.state = "walk"
				set_animation(self, "walk")
			end
		end

	elseif self.state == "walk" then

		local s = self.object:get_pos()
		local lp = nil

		-- is there something I need to avoid?
		if self.water_damage > 0
		and self.lava_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:water", "group:lava"})

		elseif self.water_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:water"})

		elseif self.lava_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:lava"})
		end

		if lp then

			-- if mob in water or lava then look for land
			if (self.lava_damage
				and minetest.registered_nodes[self.standing_in].groups.lava)
			or (self.water_damage
				and minetest.registered_nodes[self.standing_in].groups.water) then

				lp = minetest.find_node_near(s, 5, {"group:soil", "group:stone",
					"group:sand", node_ice, node_snowblock})

				-- did we find land?
				if lp then

					local vec = {
						x = lp.x - s.x,
						z = lp.z - s.z
					}

					yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

					if lp.x > s.x then yaw = yaw + pi end

					-- look towards land and jump/move in that direction
					yaw = set_yaw(self, yaw, 6)
					do_jump(self)
					set_velocity(self, self.walk_velocity)
				else
					yaw = yaw + random(-0.5, 0.5)
				end

			else

				local vec = {
					x = lp.x - s.x,
					z = lp.z - s.z
				}

				yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

				if lp.x > s.x then yaw = yaw + pi end
			end

			yaw = set_yaw(self, yaw, 8)

		-- otherwise randomly turn
		elseif random(1, 100) <= 30 then

			yaw = yaw + random(-0.5, 0.5)

			yaw = set_yaw(self, yaw, 8)
		end

		-- stand for great fall in front
		local temp_is_cliff = is_at_cliff(self)

		if self.facing_fence == true
		or temp_is_cliff
		or random(1, 100) <= 30 then

			set_velocity(self, 0)
			self.state = "stand"
			set_animation(self, "stand")
		else
			set_velocity(self, self.walk_velocity)

			if flight_check(self)
			and self.animation
			and self.animation.fly_start
			and self.animation.fly_end then
				set_animation(self, "fly")
			else
				set_animation(self, "walk")
			end
		end

	-- runaway when punched
	elseif self.state == "runaway" then

		self.runaway_timer = self.runaway_timer + 1

		-- stop after 5 seconds or when at cliff
		if self.runaway_timer > 5
		or is_at_cliff(self) then
			self.runaway_timer = 0
			set_velocity(self, 0)
			self.state = "stand"
			set_animation(self, "stand")
		else
			set_velocity(self, self.run_velocity)
			set_animation(self, "walk")
		end

	-- attack routines (explode, dogfight, shoot, dogshoot)
	elseif self.state == "attack" then

		-- calculate distance from mob and enemy
		local s = self.object:get_pos()
		local p = self.attack:get_pos() or s
		local dist = vector.distance(p, s)

		-- stop attacking if player invisible or out of range
		if dist > self.view_range
		or not self.attack
		or not self.attack:get_pos()
		or self.attack:get_hp() <= 0
		or (self.attack:is_player() and mobs.invis[ self.attack:get_player_name() ]) then

			self.state = "stand"
			set_velocity(self, 0)
			set_animation(self, "stand")
			self.attack = nil
			self.v_start = false
			self.timer = 0
			self.blinktimer = 0
			self.path.way = nil

			return
		end

		if self.attack_type == "explode" then

			local vec = {
				x = p.x - s.x,
				z = p.z - s.z
			}

			yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

			if p.x > s.x then yaw = yaw + pi end

			yaw = set_yaw(self, yaw)

			local node_break_radius = self.explosion_radius or 1
			local entity_damage_radius = self.explosion_damage_radius
					or (node_break_radius * 2)

			-- start timer when in reach and line of sight
			if not self.v_start
			and dist <= self.reach
			and line_of_sight(self, s, p, 2) then

				self.v_start = true
				self.timer = 0
				self.blinktimer = 0
				mob_sound(self, "fuse", nil, false)

			-- stop timer if out of reach or direct line of sight
			elseif self.allow_fuse_reset
			and self.v_start
			and (dist > self.reach
					or not line_of_sight(self, s, p, 2)) then
				self.v_start = false
				self.timer = 0
				self.blinktimer = 0
				self.blinkstatus = false
				remove_texture_mod(self, "^[brighten")
			end

			-- walk right up to player unless the timer is active
			if self.v_start and (self.stop_to_explode or dist < 1.5) then
				set_velocity(self, 0)
			else
				set_velocity(self, self.run_velocity)
			end

			if self.animation and self.animation.run_start then
				set_animation(self, "run")
			else
				set_animation(self, "walk")
			end

			if self.v_start then

				self.timer = self.timer + dtime
				self.blinktimer = (self.blinktimer or 0) + dtime

				if self.blinktimer > 0.2 then

					self.blinktimer = 0

					if self.blinkstatus then
						remove_texture_mod(self, "^[brighten")
					else
						add_texture_mod(self, "^[brighten")
					end

					self.blinkstatus = not self.blinkstatus
				end

				if self.timer > self.explosion_timer then

					local pos = self.object:get_pos()

					-- dont damage anything if area protected or next to water
					if minetest.find_node_near(pos, 1, {"group:water"})
					or minetest.is_protected(pos, "") then

						node_break_radius = 1
					end

					self.object:remove()

					if mobs_griefing and mod_tnt and tnt and tnt.boom
					and not minetest.is_protected(pos, "") then

						tnt.boom(pos, {
							radius = node_break_radius,
							damage_radius = entity_damage_radius,
							sound = self.sounds.explode,
						})
					else

						minetest.sound_play(self.sounds.explode, {
							pos = pos,
							gain = 1.0,
							max_hear_distance = self.sounds.distance or 32
						})

						entity_physics(pos, entity_damage_radius)
						effect(pos, 32, "tnt_smoke.png", nil, nil, node_break_radius, 1, 0)
					end

					return
				end
			end

		elseif self.attack_type == "dogfight"
		or (self.attack_type == "dogshoot" and dogswitch(self, dtime) == 2)
		or (self.attack_type == "dogshoot" and dist <= self.reach and dogswitch(self) == 0) then

			if self.fly
			and dist > self.reach then

				local p1 = s
				local me_y = floor(p1.y)
				local p2 = p
				local p_y = floor(p2.y + 1)
				local v = self.object:get_velocity()

				if flight_check(self, s) then

					if me_y < p_y then

						self.object:set_velocity({
							x = v.x,
							y = 1 * self.walk_velocity,
							z = v.z
						})

					elseif me_y > p_y then

						self.object:set_velocity({
							x = v.x,
							y = -1 * self.walk_velocity,
							z = v.z
						})
					end
				else
					if me_y < p_y then

						self.object:set_velocity({
							x = v.x,
							y = 0.01,
							z = v.z
						})

					elseif me_y > p_y then

						self.object:set_velocity({
							x = v.x,
							y = -0.01,
							z = v.z
						})
					end
				end

			end

			-- rnd: new movement direction
			if self.path.following
			and self.path.way
			and self.attack_type ~= "dogshoot" then

				-- no paths longer than 50
				if #self.path.way > 50
				or dist < self.reach then
					self.path.following = false
					return
				end

				local p1 = self.path.way[1]

				if not p1 then
					self.path.following = false
					return
				end

				if abs(p1.x-s.x) + abs(p1.z - s.z) < 0.6 then
					-- reached waypoint, remove it from queue
					table.remove(self.path.way, 1)
				end

				-- set new temporary target
				p = {x = p1.x, y = p1.y, z = p1.z}
			end

			local vec = {
				x = p.x - s.x,
				z = p.z - s.z
			}

			yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

			if p.x > s.x then yaw = yaw + pi end

			yaw = set_yaw(self, yaw)

			-- move towards enemy if beyond mob reach
			if dist > self.reach then

				-- path finding by rnd
				if self.pathfinding -- only if mob has pathfinding enabled
				and enable_pathfinding then

					smart_mobs(self, s, p, dist, dtime)
				end

				if is_at_cliff(self) then

					set_velocity(self, 0)
					set_animation(self, "stand")
				else

					if self.path.stuck then
						set_velocity(self, self.walk_velocity)
					else
						set_velocity(self, self.run_velocity)
					end

					if self.animation and self.animation.run_start then
						set_animation(self, "run")
					else
						set_animation(self, "walk")
					end
				end

			else -- rnd: if inside reach range

				self.path.stuck = false
				self.path.stuck_timer = 0
				self.path.following = false -- not stuck anymore

				set_velocity(self, 0)

				if not self.custom_attack then

					if self.timer > 1 then

						self.timer = 0

						if self.double_melee_attack
						and random(1, 2) == 1 then
							set_animation(self, "punch2")
						else
							set_animation(self, "punch")
						end

						local p2 = p
						local s2 = s

						p2.y = p2.y + .5
						s2.y = s2.y + .5

						if line_of_sight(self, p2, s2) == true then

							-- play attack sound
							mob_sound(self, "attack")

							-- punch player (or what player is attached to)
							local attached = self.attack:get_attach()
							if attached then
								self.attack = attached
							end
							self.attack:punch(self.object, 1.0, {
								full_punch_interval = 1.0,
								damage_groups = {fleshy = self.damage}
							}, nil)
						end
					end
				else	-- call custom attack every second
					if self.custom_attack
					and self.timer > 1 then

						self.timer = 0

						self.custom_attack(self, p)
					end
				end
			end

		elseif self.attack_type == "shoot"
		or (self.attack_type == "dogshoot" and dogswitch(self, dtime) == 1)
		or (self.attack_type == "dogshoot" and dist > self.reach and dogswitch(self) == 0) then

			p.y = p.y - .5
			s.y = s.y + .5

			local dist = vector.distance(p, s)
			local vec = {
				x = p.x - s.x,
				y = p.y - s.y,
				z = p.z - s.z
			}

			yaw = (atan(vec.z / vec.x) + pi / 2) - self.rotate

			if p.x > s.x then yaw = yaw + pi end

			yaw = set_yaw(self, yaw)

			set_velocity(self, 0)

			if self.shoot_interval
			and self.timer > self.shoot_interval
			and random(1, 100) <= 60 then

				self.timer = 0
				set_animation(self, "shoot")

				-- play shoot attack sound
				mob_sound(self, "shoot_attack")

				local p = self.object:get_pos()

				p.y = p.y + (self.collisionbox[2] + self.collisionbox[5]) / 2

				-- Shoot arrow
				if minetest.registered_entities[self.arrow] then

					local arrow, ent
					local v = 1
					if not self.shoot_arrow then
						arrow = minetest.add_entity(p, self.arrow)
						ent = arrow:get_luaentity()
						if ent.velocity then
							v = ent.velocity
						end
						ent.switch = 1
						ent.owner_id = tostring(self.object) -- add unique owner id to arrow
					end

					local amount = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
					-- offset makes shoot aim accurate
					vec.y = vec.y + self.shoot_offset
					vec.x = vec.x * (v / amount)
					vec.y = vec.y * (v / amount)
					vec.z = vec.z * (v / amount)
					if self.shoot_arrow then
						vec = vector.normalize(vec)
						self:shoot_arrow(p, vec)
					else
						arrow:set_velocity(vec)
					end
				end
			end
		end
	end
end


-- falling and fall damage
local falling = function(self, pos)

	if self.fly then
		return
	end

	-- floating in water (or falling)
	local v = self.object:get_velocity()

	if v.y > 0 then

		-- apply gravity when moving up
		self.object:set_acceleration({
			x = 0,
			y = -10,
			z = 0
		})

	elseif v.y <= 0 and v.y > self.fall_speed then

		-- fall downwards at set speed
		self.object:set_acceleration({
			x = 0,
			y = self.fall_speed,
			z = 0
		})
	else
		-- stop accelerating once max fall speed hit
		self.object:set_acceleration({x = 0, y = 0, z = 0})
	end

	-- in water then float up
	if minetest.registered_nodes[node_ok(pos).name].groups.water then

		if self.floats == 1 then

			self.object:set_acceleration({
				x = 0,
				y = -self.fall_speed / (max(1, v.y) ^ 2),
				z = 0
			})
		end
	else

		-- fall damage onto solid ground
		if self.fall_damage == 1
		and self.object:get_velocity().y == 0 then

			local d = (self.old_y or 0) - self.object:get_pos().y

			if d > 5 then

				self.health = self.health - floor(d - 5)

				effect(pos, 5, "tnt_smoke.png", 1, 2, 2, nil)

				if check_for_death(self, "fall", {type = "fall"}) then
					return
				end
			end

			self.old_y = self.object:get_pos().y
		end
	end
end


-- deal damage and effects when mob punched
local mob_punch = function(self, hitter, tflp, tool_capabilities, dir)

	-- custom punch function
	if self.do_punch then

		-- when false skip going any further
		if self.do_punch(self, hitter, tflp, tool_caps, dir) == false then
			return
		end
	end

	-- error checking when mod profiling is enabled
	if not tool_capabilities then
		minetest.log("warning", "[mobs] Mod profiling enabled, damage not enabled")
		return
	end

	-- is mob protected?
	if self.protected and hitter:is_player()
	and minetest.is_protected(self.object:get_pos(), hitter:get_player_name()) then
		return
	end


	-- punch interval
	local weapon = hitter:get_wielded_item()
	local punch_interval = 1.4

	-- exhaust attacker
	if mod_hunger and hitter:is_player() then
		mcl_hunger.exhaust(hitter:get_player_name(), mcl_hunger.EXHAUST_ATTACK)
	end

	-- calculate mob damage
	local damage = 0
	local armor = self.object:get_armor_groups() or {}
	local tmp

	-- quick error check incase it ends up 0 (serialize.h check test)
	if tflp == 0 then
		tflp = 0.2
	end

	if use_cmi then
		damage = cmi.calculate_damage(self.object, hitter, tflp, tool_capabilities, dir)
	else

		for group,_ in pairs( (tool_capabilities.damage_groups or {}) ) do

			tmp = tflp / (tool_capabilities.full_punch_interval or 1.4)

			if tmp < 0 then
				tmp = 0.0
			elseif tmp > 1 then
				tmp = 1.0
			end

			damage = damage + (tool_capabilities.damage_groups[group] or 0)
				* tmp * ((armor[group] or 0) / 100.0)
		end
	end

	-- check for tool immunity or special damage
	for n = 1, #self.immune_to do

		if self.immune_to[n][1] == weapon:get_name() then

			damage = self.immune_to[n][2] or 0
			break
		end
	end

	-- healing
	if damage <= -1 then
		self.health = self.health - floor(damage)
		return
	end

	if use_cmi then

		local cancel =  cmi.notify_punch(self.object, hitter, tflp, tool_capabilities, dir, damage)

		if cancel then return end
	end

	if tool_capabilities then
		punch_interval = tool_capabilities.full_punch_interval or 1.4
	end

	-- add weapon wear
	if minetest.settings:get_bool("creative_mode") ~= true
	and weapon:get_definition()
	and weapon:get_definition().tool_capabilities then

		weapon:add_wear(floor((punch_interval / 75) * 9000))
		hitter:set_wielded_item(weapon)
	end

	local die = false

	-- only play hit sound and show blood effects if damage is 1 or over
	if damage >= 1 then

		-- weapon sounds
		if weapon:get_definition().sounds ~= nil then

			local s = random(0, #weapon:get_definition().sounds)

			minetest.sound_play(weapon:get_definition().sounds[s], {
				object = self.object, --hitter,
				max_hear_distance = 8
			})
		else
			minetest.sound_play("default_punch", {
				object = self.object, --hitter,
				max_hear_distance = 5
			})
		end

		damage_effect(self, damage)

		-- do damage
		self.health = self.health - floor(damage)

		-- skip future functions if dead, except alerting others
		if check_for_death(self, "hit", {type = "punch", puncher = hitter}) then
			die = true
		end

		-- knock back effect (only on full punch)
		if not die
		and self.knock_back
		and tflp >= punch_interval then

			local v = self.object:get_velocity()
			local r = 1.4 - min(punch_interval, 1.4)
			local kb = r * 2.0
			local up = 2

			-- if already in air then dont go up anymore when hit
			if v.y > 0
			or self.fly then
				up = 0
			end

			-- direction error check
			dir = dir or {x = 0, y = 0, z = 0}

			-- check if tool already has specific knockback value
			if tool_capabilities.damage_groups["knockback"] then
				kb = tool_capabilities.damage_groups["knockback"]
			else
				kb = kb * 1.5
			end

			self.object:set_velocity({
				x = dir.x * kb,
				y = up,
				z = dir.z * kb
			})

			self.pause_timer = 0.25
		end
	end -- END if damage

	-- if skittish then run away
	if not die and self.runaway == true then

		local lp = hitter:get_pos()
		local s = self.object:get_pos()
		local vec = {
			x = lp.x - s.x,
			y = lp.y - s.y,
			z = lp.z - s.z
		}

		local yaw = (atan(vec.z / vec.x) + 3 * pi / 2) - self.rotate

		if lp.x > s.x then
			yaw = yaw + pi
		end

		yaw = set_yaw(self, yaw, 6)
		self.state = "runaway"
		self.runaway_timer = 0
		self.following = nil
	end

	local name = hitter:get_player_name() or ""

	-- attack puncher and call other mobs for help
	if self.passive == false
	and self.state ~= "flop"
	and (self.child == false or self.type == "monster")
	and hitter:get_player_name() ~= self.owner
	and not mobs.invis[ name ] then

		if not die then
			-- attack whoever punched mob
			self.state = ""
			do_attack(self, hitter)
		end

		-- alert others to the attack
		local objs = minetest.get_objects_inside_radius(hitter:get_pos(), self.view_range)
		local obj = nil

		for n = 1, #objs do

			obj = objs[n]:get_luaentity()

			if obj then

				-- only alert members of same mob or friends
				if obj.group_attack
				and obj.state ~= "attack"
				and obj.owner ~= name then
					if obj.name == self.name then
						do_attack(obj, hitter)
					elseif type(obj.group_attack) == "table" then
						for i=1, #obj.group_attack do
							if obj.name == obj.group_attack[i] then
								do_attack(obj, hitter)
								break
							end
						end
					end
				end

				-- have owned mobs attack player threat
				if obj.owner == name and obj.owner_loyal then
					do_attack(obj, self.object)
				end
			end
		end
	end
end


-- get entity staticdata
local mob_staticdata = function(self)

	-- remove mob when out of range unless tamed
	if remove_far
	and self.can_despawn
	and self.remove_ok
	and ((not self.nametag) or (self.nametag == ""))
	and self.lifetimer <= 20 then

		minetest.log("action", "Mob "..name.." despawns in mob_staticdata at "..minetest.pos_to_string(self.object.get_pos()))
		self.object:remove()

		return ""-- nil
	end

	self.remove_ok = true
	self.attack = nil
	self.following = nil
	self.state = "stand"

	-- used to rotate older mobs
	if self.drawtype
	and self.drawtype == "side" then
		self.rotate = math.rad(90)
	end

	if use_cmi then
		self.serialized_cmi_components = cmi.serialize_components(self._cmi_components)
	end

	local tmp = {}

	for _,stat in pairs(self) do

		local t = type(stat)

		if  t ~= "function"
		and t ~= "nil"
		and t ~= "userdata"
		and _ ~= "_cmi_components" then
			tmp[_] = self[_]
		end
	end

	return minetest.serialize(tmp)
end


-- activate mob and reload settings
local mob_activate = function(self, staticdata, def, dtime)

	-- remove monsters in peaceful mode
	if self.type == "monster"
	and peaceful_only then

		self.object:remove()

		return
	end

	-- load entity variables
	local tmp = minetest.deserialize(staticdata)

	if tmp then
		for _,stat in pairs(tmp) do
			self[_] = stat
		end
	end

	-- select random texture, set model and size
	if not self.base_texture then

		-- compatiblity with old simple mobs textures
		if type(def.textures[1]) == "string" then
			def.textures = {def.textures}
		end

		self.base_texture = def.textures[random(1, #def.textures)]
		self.base_mesh = def.mesh
		self.base_size = self.visual_size
		self.base_colbox = self.collisionbox
		self.base_selbox = self.selectionbox
	end

	-- for current mobs that dont have this set
	if not self.base_selbox then
		self.base_selbox = self.selectionbox or self.base_colbox
	end

	-- set texture, model and size
	local textures = self.base_texture
	local mesh = self.base_mesh
	local vis_size = self.base_size
	local colbox = self.base_colbox
	local selbox = self.base_selbox

	-- specific texture if gotten
	if self.gotten == true
	and def.gotten_texture then
		textures = def.gotten_texture
	end

	-- specific mesh if gotten
	if self.gotten == true
	and def.gotten_mesh then
		mesh = def.gotten_mesh
	end

	-- set child objects to half size
	if self.child == true then

		vis_size = {
			x = self.base_size.x * .5,
			y = self.base_size.y * .5,
		}

		if def.child_texture then
			textures = def.child_texture[1]
		end

		colbox = {
			self.base_colbox[1] * .5,
			self.base_colbox[2] * .5,
			self.base_colbox[3] * .5,
			self.base_colbox[4] * .5,
			self.base_colbox[5] * .5,
			self.base_colbox[6] * .5
		}
		selbox = {
			self.base_selbox[1] * .5,
			self.base_selbox[2] * .5,
			self.base_selbox[3] * .5,
			self.base_selbox[4] * .5,
			self.base_selbox[5] * .5,
			self.base_selbox[6] * .5
		}
	end

	if self.health == 0 then
		self.health = random (self.hp_min, self.hp_max)
	end
	if self.breath == nil then
		self.breath = self.breath_max
	end

	-- pathfinding init
	self.path = {}
	self.path.way = {} -- path to follow, table of positions
	self.path.lastpos = {x = 0, y = 0, z = 0}
	self.path.stuck = false
	self.path.following = false -- currently following path?
	self.path.stuck_timer = 0 -- if stuck for too long search for path

	-- mob defaults
	self.object:set_armor_groups({immortal = 1, fleshy = self.armor})
	self.old_y = self.object:get_pos().y
	self.old_health = self.health
	self.sounds.distance = self.sounds.distance or 10
	self.textures = textures
	self.mesh = mesh
	self.collisionbox = colbox
	self.selectionbox = selbox
	self.visual_size = vis_size
	self.standing_in = ""
	self.jump_sound_cooloff = 0 -- used to prevent jump sound from being played too often in short time
	self.opinion_sound_cooloff = 0 -- used to prevent sound spam of particular sound types

	self.texture_mods = {}

	-- check existing nametag
	if not self.nametag then
		self.nametag = def.nametag
	end

	-- set anything changed above
	self.object:set_properties(self)
	set_yaw(self, (random(0, 360) - 180) / 180 * pi, 6)
	update_tag(self)
	set_animation(self, "stand")

	-- run on_spawn function if found
	if self.on_spawn and not self.on_spawn_run then
		if self.on_spawn(self) then
			self.on_spawn_run = true --  if true, set flag to run once only
		end
	end

	-- run after_activate
	if def.after_activate then
		def.after_activate(self, staticdata, def, dtime)
	end

	if use_cmi then
		self._cmi_components = cmi.activate_components(self.serialized_cmi_components)
		cmi.notify_activate(self.object, dtime)
	end
end


-- main mob function
local mob_step = function(self, dtime)

	if use_cmi then
		cmi.notify_step(self.object, dtime)
	end

	local pos = self.object:get_pos()
	local yaw = 0

	-- Despawning: when lifetimer expires, remove mob
	if remove_far
	and self.can_despawn == true
	and ((not self.nametag) or (self.nametag == "")) then

		-- TODO: Finish up implementation of despawning rules

		self.lifetimer = self.lifetimer - dtime

		if self.lifetimer <= 0 then

			-- only despawn away from player
			local objs = minetest.get_objects_inside_radius(pos, 32)

			for n = 1, #objs do

				if objs[n]:is_player() then

					self.lifetimer = 20

					return
				end
			end

			minetest.log("action", "Mob "..name.." despawns in mob_step at "..minetest.pos_to_string(pos))
			self.object:remove()

			return
		end
	end

	if self.jump_sound_cooloff > 0 then
		self.jump_sound_cooloff = self.jump_sound_cooloff - dtime
	end
	if self.opinion_sound_cooloff > 0 then
		self.opinion_sound_cooloff = self.opinion_sound_cooloff - dtime
	end
	falling(self, pos)

	-- smooth rotation by ThomasMonroe314

	if self.delay and self.delay > 0 then

		local yaw = self.object:get_yaw()

		if self.delay == 1 then
			yaw = self.target_yaw
		else
			local dif = abs(yaw - self.target_yaw)

			if yaw > self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif -- need to add
					yaw = yaw + dif / self.delay
				else
					yaw = yaw - dif / self.delay -- need to subtract
				end

			elseif yaw < self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif
					yaw = yaw - dif / self.delay -- need to subtract
				else
					yaw = yaw + dif / self.delay -- need to add
				end
			end

			if yaw > (pi * 2) then yaw = yaw - (pi * 2) end
			if yaw < 0 then yaw = yaw + (pi * 2) end
		end

		self.delay = self.delay - 1
		self.object:set_yaw(yaw)
	end

	-- end rotation

	-- knockback timer
	if self.pause_timer > 0 then

		self.pause_timer = self.pause_timer - dtime

		return
	end

	-- run custom function (defined in mob lua file)
	if self.do_custom then

		-- when false skip going any further
		if self.do_custom(self, dtime) == false then
			return
		end
	end

	-- attack timer
	self.timer = self.timer + dtime

	if self.state ~= "attack" then

		if self.timer < 1 then
			return
		end

		self.timer = 0
	end

	-- never go over 100
	if self.timer > 100 then
		self.timer = 1
	end

	-- mob plays random sound at times
	if random(1, 100) == 1 then
		mob_sound(self, "random", true)
	end

	-- environmental damage timer (every 1 second)
	self.env_damage_timer = self.env_damage_timer + dtime

	if (self.state == "attack" and self.env_damage_timer > 1)
	or self.state ~= "attack" then

		self.env_damage_timer = 0

		-- check for environmental damage (water, fire, lava etc.)
		do_env_damage(self)

		-- node replace check (cow eats grass etc.)
		replace(self, pos)
	end

	monster_attack(self)

	npc_attack(self)

	breed(self)

	follow_flop(self)

	do_states(self, dtime)

	do_jump(self)

	runaway_from(self)

end


-- default function when mobs are blown up with TNT
local do_tnt = function(obj, damage)

	obj.object:punch(obj.object, 1.0, {
		full_punch_interval = 1.0,
		damage_groups = {fleshy = damage},
	}, nil)

	return false, true, {}
end


mobs.spawning_mobs = {}

-- Code to execute before custom on_rightclick handling
local on_rightclick_prefix = function(self, clicker)
	local item = clicker:get_wielded_item()

	-- Name mob with nametag
	if not self.ignores_nametag and item:get_name() == "mcl_mobs:nametag" then

		local tag = item:get_meta():get_string("name")
		if tag ~= "" then
			if string.len(tag) > MAX_MOB_NAME_LENGTH then
				tag = string.sub(tag, 1, MAX_MOB_NAME_LENGTH)
			end
			self.nametag = tag

			update_tag(self)

			if not mobs.is_creative(clicker:get_player_name()) then
				item:take_item()
				clicker:set_wielded_item(item)
			end
			return true
		end

	end
	return false
end

local create_mob_on_rightclick = function(on_rightclick)
	return function(self, clicker)
		local stop = on_rightclick_prefix(self, clicker)
		if (not stop) and (on_rightclick) then
			on_rightclick(self, clicker)
		end
	end
end

-- register mob entity
function mobs:register_mob(name, def)

	mobs.spawning_mobs[name] = true

local can_despawn
if def.can_despawn ~= nil then
	can_despawn = def.can_despawn
else
	can_despawn = true
end

local function scale_difficulty(value, default, min, special)
	if (not value) or (value == default) or (value == special) then
		return default
	else
		return max(min, value * difficulty)
	end
end

minetest.register_entity(name, {

	stepheight = def.stepheight or 1.1, -- was 0.6
	name = name,
	type = def.type,
	attack_type = def.attack_type,
	fly = def.fly,
	fly_in = def.fly_in or "air",
	owner = def.owner or "",
	order = def.order or "",
	on_die = def.on_die,
	spawn_small_alternative = def.spawn_small_alternative,
	do_custom = def.do_custom,
	jump_height = def.jump_height or 4, -- was 6
	drawtype = def.drawtype, -- DEPRECATED, use rotate instead
	rotate = math.rad(def.rotate or 0), --  0=front, 90=side, 180=back, 270=side2
	lifetimer = def.lifetimer or 57.73,
	hp_min = scale_difficulty(def.hp_min, 5, 1),
	hp_max = scale_difficulty(def.hp_max, 10, 1),
	breath_max = def.breath_max or 15,
        breathes_in_water = def.breathes_in_water or false,
	physical = true,
	collisionbox = def.collisionbox or {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
	selectionbox = def.selectionbox or def.collisionbox,
	visual = def.visual,
	visual_size = def.visual_size or {x = 1, y = 1},
	mesh = def.mesh,
	makes_footstep_sound = def.makes_footstep_sound or false,
	view_range = def.view_range or 16,
	walk_velocity = def.walk_velocity or 1,
	run_velocity = def.run_velocity or 2,
	damage = scale_difficulty(def.damage, 0, 0),
	light_damage = def.light_damage or 0,
	sunlight_damage = def.sunlight_damage or 0,
	water_damage = def.water_damage or 0,
	lava_damage = def.lava_damage or 8,
	fire_damage = def.fire_damage or 1,
	suffocation = def.suffocation or true,
	fall_damage = def.fall_damage or 1,
	fall_speed = def.fall_speed or -10, -- must be lower than -2 (default: -10)
	drops = def.drops or {},
	armor = def.armor or 100,
	on_rightclick = create_mob_on_rightclick(def.on_rightclick),
	arrow = def.arrow,
	shoot_interval = def.shoot_interval,
	sounds = def.sounds or {},
	animation = def.animation,
	follow = def.follow,
	jump = def.jump ~= false,
	walk_chance = def.walk_chance or 50,
	attacks_monsters = def.attacks_monsters or false,
	group_attack = def.group_attack or false,
	passive = def.passive or false,
	knock_back = def.knock_back ~= false,
	shoot_offset = def.shoot_offset or 0,
	floats = def.floats or 1, -- floats in water by default
	replace_rate = def.replace_rate,
	replace_what = def.replace_what,
	replace_with = def.replace_with,
	replace_offset = def.replace_offset or 0,
	on_replace = def.on_replace,
	timer = 0,
	env_damage_timer = 0, -- only used when state = "attack"
	tamed = false,
	pause_timer = 0,
	horny = false,
	hornytimer = 0,
	gotten = false,
	health = 0,
	reach = def.reach or 3,
	htimer = 0,
	texture_list = def.textures,
	child_texture = def.child_texture,
	docile_by_day = def.docile_by_day or false,
	time_of_day = 0.5,
	fear_height = def.fear_height or 0,
	runaway = def.runaway,
	runaway_timer = 0,
	pathfinding = def.pathfinding,
	immune_to = def.immune_to or {},
	explosion_radius = def.explosion_radius,
	explosion_damage_radius = def.explosion_damage_radius,
	explosion_timer = def.explosion_timer or 3,
	allow_fuse_reset = def.allow_fuse_reset ~= false,
	stop_to_explode = def.stop_to_explode ~= false,
	custom_attack = def.custom_attack,
	double_melee_attack = def.double_melee_attack,
	dogshoot_switch = def.dogshoot_switch,
	dogshoot_count = 0,
	dogshoot_count_max = def.dogshoot_count_max or 5,
	dogshoot_count2_max = def.dogshoot_count2_max or (def.dogshoot_count_max or 5),
	attack_animals = def.attack_animals or false,
	specific_attack = def.specific_attack,
	runaway_from = def.runaway_from,
	owner_loyal = def.owner_loyal,
	facing_fence = false,
	_cmi_is_mob = true,

	-- MCL2 extensions
	ignores_nametag = def.ignores_nametag or false,
	rain_damage = def.rain_damage or 0,
	glow = def.glow,
	can_despawn = can_despawn,
	child = def.child or false,
	texture_mods = {},
	shoot_arrow = def.shoot_arrow,
        sounds_child = def.sounds_child,
	-- End of MCL2 extensions

	on_spawn = def.on_spawn,

	on_blast = def.on_blast or do_tnt,

	on_step = mob_step,

	do_punch = def.do_punch,

	on_punch = mob_punch,

	on_breed = def.on_breed,

	on_grown = def.on_grown,

	on_activate = function(self, staticdata, dtime)
		return mob_activate(self, staticdata, def, dtime)
	end,

	get_staticdata = function(self)
		return mob_staticdata(self)
	end,

})

if minetest.get_modpath("doc_identifier") ~= nil then
	doc.sub.identifier.register_object(name, "basics", "mobs")
end

end -- END mobs:register_mob function


-- count how many mobs of one type are inside an area
local count_mobs = function(pos, type)

	local num_type = 0
	local num_total = 0
	local objs = minetest.get_objects_inside_radius(pos, aoc_range)

	for n = 1, #objs do

		if not objs[n]:is_player() then

			local obj = objs[n]:get_luaentity()

			-- count mob type and add to total also
			if obj and obj.name and obj.name == type then

				num_type = num_type + 1
				num_total = num_total + 1

			-- add to total mobs
			elseif obj and obj.name and obj.health ~= nil then

				num_total = num_total + 1
			end
		end
	end

	return num_type, num_total
end


-- global functions

function mobs:spawn_abm_check(pos, node, name)
	-- global function to add additional spawn checks
	-- return true to stop spawning mob
end


function mobs:spawn_specific(name, nodes, neighbors, min_light, max_light,
	interval, chance, aoc, min_height, max_height, day_toggle, on_spawn)

	-- Do mobs spawn at all?
	if not mobs_spawn then
		return
	end

	-- chance/spawn number override in minetest.conf for registered mob
	local numbers = minetest.settings:get(name)

	if numbers then
		numbers = numbers:split(",")
		chance = tonumber(numbers[1]) or chance
		aoc = tonumber(numbers[2]) or aoc

		if chance == 0 then
			minetest.log("warning", string.format("[mobs] %s has spawning disabled", name))
			return
		end

		minetest.log("action",
			string.format("[mobs] Chance setting for %s changed to %s (total: %s)", name, chance, aoc))

	end

	local spawn_action
	spawn_action = function(pos, node, active_object_count, active_object_count_wider, name)

			local orig_pos = table.copy(pos)
			-- is mob actually registered?
			if not mobs.spawning_mobs[name]
			or not minetest.registered_entities[name] then
				minetest.log("warning", "Mob spawn of "..name.." failed, unknown entity or mob is not registered for spawning!")
				return
			end

			-- additional custom checks for spawning mob
			if mobs:spawn_abm_check(pos, node, name) == true then
				minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, ABM check rejected!")
				return
			end

			-- do not spawn if too many of same mob in area
			if active_object_count_wider >= max_per_block
			or count_mobs(pos, name) >= aoc then
				-- too many entities
				minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, too crowded!")
				return
			end

			-- if toggle set to nil then ignore day/night check
			if day_toggle ~= nil then

				local tod = (minetest.get_timeofday() or 0) * 24000

				if tod > 4500 and tod < 19500 then
					-- daylight, but mob wants night
					if day_toggle == false then
						-- mob needs night
						minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, mob needs light!")
						return
					end
				else
					-- night time but mob wants day
					if day_toggle == true then
						-- mob needs day
						minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, mob needs daylight!")
						return
					end
				end
			end

			-- spawn above node
			pos.y = pos.y + 1

			-- only spawn away from player
			local objs = minetest.get_objects_inside_radius(pos, 10)

			for n = 1, #objs do

				if objs[n]:is_player() then
					-- player too close
					minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, player too close!")
					return
				end
			end

			-- mobs cannot spawn in protected areas when enabled
			if not spawn_protected
			and minetest.is_protected(pos, "") then
				minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, position is protected!")
				return
			end

			-- are we spawning within height limits?
			if pos.y > max_height
			or pos.y < min_height then
				minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, out of height limit!")
				return
			end

			-- are light levels ok?
			local light = minetest.get_node_light(pos)
			if not light
			or light > max_light
			or light < min_light then
				minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, bad light!")
				return
			end

			-- do we have enough space to spawn mob?
			local ent = minetest.registered_entities[name]
			local width_x = max(1, math.ceil(ent.collisionbox[4] - ent.collisionbox[1]))
			local min_x, max_x
			if width_x % 2 == 0 then
				max_x = math.floor(width_x/2)
				min_x = -(max_x-1)
			else
				max_x = math.floor(width_x/2)
				min_x = -max_x
			end

			local width_z = max(1, math.ceil(ent.collisionbox[6] - ent.collisionbox[3]))
			local min_z, max_z
			if width_z % 2 == 0 then
				max_z = math.floor(width_z/2)
				min_z = -(max_z-1)
			else
				max_z = math.floor(width_z/2)
				min_z = -max_z
			end

			local max_y = max(0, math.ceil(ent.collisionbox[5] - ent.collisionbox[2]) - 1)

			for y = 0, max_y do
				for x = min_x, max_x do
					for z = min_z, max_z do
						local pos2 = {x = pos.x+x, y = pos.y+y, z = pos.z+z}
						if minetest.registered_nodes[node_ok(pos2).name].walkable == true then
							-- inside block
							minetest.log("info", "Mob spawn of "..name.." at "..minetest.pos_to_string(pos).." failed, too little space!")
							if ent.spawn_small_alternative ~= nil and (not minetest.registered_nodes[node_ok(pos).name].walkable) then
								minetest.log("info", "Trying to spawn smaller alternative mob: "..ent.spawn_small_alternative)
								spawn_action(orig_pos, node, active_object_count, active_object_count_wider, ent.spawn_small_alternative)
							end
							return
						end
					end
				end
			end

			-- spawn mob 1/2 node above ground
			pos.y = pos.y + 0.5
			-- tweak X/Z spawn pos
			if width_x % 2 == 0 then
				pos.x = pos.x + 0.5
			end
			if width_z % 2 == 0 then
				pos.z = pos.z + 0.5
			end

			local mob = minetest.add_entity(pos, name)
			minetest.log("action", "Mob spawned: "..name.." at "..minetest.pos_to_string(pos))

			if on_spawn then

				local ent = mob:get_luaentity()

				on_spawn(ent, pos)
			end
	end

	local function spawn_abm_action(pos, node, active_object_count, active_object_count_wider)
		spawn_action(pos, node, active_object_count, active_object_count_wider, name)
	end

	minetest.register_abm({
		label = name .. " spawning",
		nodenames = nodes,
		neighbors = neighbors,
		interval = interval,
		chance = floor(max(1, chance * mobs_spawn_chance)),
		catch_up = false,
		action = spawn_abm_action,
	})
end


-- compatibility with older mob registration
function mobs:register_spawn(name, nodes, max_light, min_light, chance, active_object_count, max_height, day_toggle)

	mobs:spawn_specific(name, nodes, {"air"}, min_light, max_light, 30,
		chance, active_object_count, -31000, max_height, day_toggle)
end


-- MarkBu's spawn function
function mobs:spawn(def)

	local name = def.name
	local nodes = def.nodes or {"group:soil", "group:stone"}
	local neighbors = def.neighbors or {"air"}
	local min_light = def.min_light or 0
	local max_light = def.max_light or 15
	local interval = def.interval or 30
	local chance = def.chance or 5000
	local active_object_count = def.active_object_count or 1
	local min_height = def.min_height or -31000
	local max_height = def.max_height or 31000
	local day_toggle = def.day_toggle
	local on_spawn = def.on_spawn

	mobs:spawn_specific(name, nodes, neighbors, min_light, max_light, interval,
		chance, active_object_count, min_height, max_height, day_toggle, on_spawn)
end


-- register arrow for shoot attack
function mobs:register_arrow(name, def)

	if not name or not def then return end -- errorcheck

	minetest.register_entity(name, {

		physical = false,
		visual = def.visual,
		visual_size = def.visual_size,
		textures = def.textures,
		velocity = def.velocity,
		hit_player = def.hit_player,
		hit_node = def.hit_node,
		hit_mob = def.hit_mob,
		drop = def.drop or false, -- drops arrow as registered item when true
		collisionbox = {0, 0, 0, 0, 0, 0}, -- remove box around arrows
		timer = 0,
		switch = 0,
		owner_id = def.owner_id,
		rotate = def.rotate,
		automatic_face_movement_dir = def.rotate
			and (def.rotate - (pi / 180)) or false,

		on_activate = def.on_activate,

		on_step = def.on_step or function(self, dtime)

			self.timer = self.timer + 1

			local pos = self.object:get_pos()

			if self.switch == 0
			or self.timer > 150
			or not within_limits(pos, 0) then

				self.object:remove();

				return
			end

			-- does arrow have a tail (fireball)
			if def.tail
			and def.tail == 1
			and def.tail_texture then

				minetest.add_particle({
					pos = pos,
					velocity = {x = 0, y = 0, z = 0},
					acceleration = {x = 0, y = 0, z = 0},
					expirationtime = def.expire or 0.25,
					collisiondetection = false,
					texture = def.tail_texture,
					size = def.tail_size or 5,
					glow = def.glow or 0,
				})
			end

			if self.hit_node then

				local node = node_ok(pos).name

				if minetest.registered_nodes[node].walkable then

					self.hit_node(self, pos, node)

					if self.drop == true then

						pos.y = pos.y + 1

						self.lastpos = (self.lastpos or pos)

						minetest.add_item(self.lastpos, self.object:get_luaentity().name)
					end

					self.object:remove();

					return
				end
			end

			if self.hit_player or self.hit_mob then

				for _,player in pairs(minetest.get_objects_inside_radius(pos, 1.0)) do

					if self.hit_player
					and player:is_player() then

						self.hit_player(self, player)
						self.object:remove();
						return
					end

					local entity = player:get_luaentity()

					if entity
					and self.hit_mob
					and entity._cmi_is_mob == true
					and tostring(player) ~= self.owner_id
					and entity.name ~= self.object:get_luaentity().name then

						self.hit_mob(self, player)

						self.object:remove();

						return
					end
				end
			end

			self.lastpos = pos
		end
	})
end


-- compatibility function
function mobs:explosion(pos, radius)
	local self = {sounds = {}}
	self.sounds.explode = "tnt_explode"
	mobs:boom(self, pos, radius)
end


-- no damage to nodes explosion
function mobs:safe_boom(self, pos, radius)

	minetest.sound_play(self.sounds and self.sounds.explode or "tnt_explode", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = self.sounds and self.sounds.distance or 32
	})

	entity_physics(pos, radius)
	effect(pos, 32, "tnt_smoke.png", radius * 3, radius * 5, radius, 1, 0)
end


-- make explosion with protection and tnt mod check
function mobs:boom(self, pos, radius)

	if mobs_griefing
	and mod_tnt and tnt and tnt.boom
	and not minetest.is_protected(pos, "") then

		tnt.boom(pos, {
			radius = radius,
			damage_radius = radius,
			sound = self.sounds and self.sounds.explode,
			explode_center = true,
		})
	else
		mobs:safe_boom(self, pos, radius)
	end
end


-- Register spawn eggs

-- Note: This also introduces the “spawn_egg” group:
-- * spawn_egg=1: Spawn egg (generic mob, no metadata)
-- * spawn_egg=2: Spawn egg (captured/tamed mob, metadata)
function mobs:register_egg(mob, desc, background, addegg, no_creative)

	local grp = {spawn_egg = 1}

	-- do NOT add this egg to creative inventory (e.g. dungeon master)
	if creative and no_creative == true then
		grp.not_in_creative_inventory = 1
	end

	local invimg = background

	if addegg == 1 then
		invimg = "mobs_chicken_egg.png^(" .. invimg ..
			"^[mask:mobs_chicken_egg_overlay.png)"
	end

	-- register old stackable mob egg
	minetest.register_craftitem(mob, {

		description = desc,
		inventory_image = invimg,
		groups = grp,

		_doc_items_longdesc = S("This allows you to place a single mob."),
		_doc_items_usagehelp = S("Just place it where you want the mob to appear. Animals will spawn tamed, unless you hold down the sneak key while placing. If you place this on a mob spawner, you change the mob it spawns."),

		on_place = function(itemstack, placer, pointed_thing)

			local pos = pointed_thing.above

			-- am I clicking on something with existing on_rightclick function?
			local under = minetest.get_node(pointed_thing.under)
			local def = minetest.registered_nodes[under.name]
			if def and def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, under, placer, itemstack)
			end

			if pos
			and within_limits(pos, 0)
			and not minetest.is_protected(pos, placer:get_player_name()) then

				local name = placer:get_player_name()
				local privs = minetest.get_player_privs(name)
				if mod_mobspawners and under.name == "mcl_mobspawners:spawner" then
					if minetest.is_protected(pointed_thing.under, name) then
						minetest.record_protection_violation(pointed_thing.under, name)
						return itemstack
					end
					if not privs.maphack then
						minetest.chat_send_player(name, S("You need the “maphack” privilege to change the mob spawner."))
						return itemstack
					end
					mcl_mobspawners.setup_spawner(pointed_thing.under, itemstack:get_name())
					if not minetest.settings:get_bool("creative_mode") then
						itemstack:take_item()
					end
					return itemstack
				end

				if not minetest.registered_entities[mob] then
					return itemstack
				end

				pos.y = pos.y + 1

				local mob = minetest.add_entity(pos, mob)
				local ent = mob:get_luaentity()

				-- don't set owner if monster or sneak pressed
				if ent.type ~= "monster"
				and not placer:get_player_control().sneak then
					ent.owner = placer:get_player_name()
					ent.tamed = true
				end

				-- set nametag
				local nametag = itemstack:get_meta():get_string("name")
				if nametag ~= "" then
					if string.len(nametag) > MAX_MOB_NAME_LENGTH then
						nametag = string.sub(nametag, 1, MAX_MOB_NAME_LENGTH)
					end
					ent.nametag = nametag
					update_tag(ent)
				end

				-- if not in creative then take item
				if not mobs.is_creative(placer:get_player_name()) then
					itemstack:take_item()
				end
			end

			return itemstack
		end,
	})

end


-- No-op in MCL2 (capturing mobs is not possible).
-- Provided for compability with Mobs Redo
function mobs:capture_mob(self, clicker, chance_hand, chance_net, chance_lasso, force_take, replacewith)
	return false
end


-- No-op in MCL2 (protecting mobs is not possible).
function mobs:protect(self, clicker)
	return false
end


local mob_obj = {}
local mob_sta = {}

-- feeding, taming and breeding (thanks blert2112)
function mobs:feed_tame(self, clicker, feed_count, breed, tame)
	if not self.follow then
		return false
	end

	-- can eat/tame with item in hand
	if follow_holding(self, clicker) then

		-- if not in creative then take item
		if not mobs.is_creative(clicker:get_player_name()) then

			local item = clicker:get_wielded_item()

			item:take_item()

			clicker:set_wielded_item(item)
		end

		-- increase health
		self.health = self.health + 4

		if self.health >= self.hp_max then

			self.health = self.hp_max

			if self.htimer < 1 then
				self.htimer = 5
			end
		end

		self.object:set_hp(self.health)

		update_tag(self)

		-- make children grow quicker
		if self.child == true then

			self.hornytimer = self.hornytimer + 20

			return true
		end

		-- feed and tame
		self.food = (self.food or 0) + 1
		if self.food >= feed_count then

			self.food = 0

			if breed and self.hornytimer == 0 then
				self.horny = true
			end

			if tame then

				self.tamed = true

				if not self.owner or self.owner == "" then
					self.owner = clicker:get_player_name()
				end
			end

			-- make sound when fed so many times
			mob_sound(self, "random", true)
		end

		return true
	end

	return false
end

-- Spawn a child
function mobs:spawn_child(pos, mob_type)
	local child = minetest.add_entity(pos, mob_type)
	if not child then
		return
	end

	local ent = child:get_luaentity()
	effect(pos, 15, "tnt_smoke.png", 1, 2, 2, 15, 5)

	ent.child = true

	local textures
	-- using specific child texture (if found)
	if ent.child_texture then
		textures = ent.child_texture[1]
	end

	-- and resize to half height
	child:set_properties({
		textures = textures,
		visual_size = {
			x = ent.base_size.x * .5,
			y = ent.base_size.y * .5,
		},
		collisionbox = {
			ent.base_colbox[1] * .5,
			ent.base_colbox[2] * .5,
			ent.base_colbox[3] * .5,
			ent.base_colbox[4] * .5,
			ent.base_colbox[5] * .5,
			ent.base_colbox[6] * .5,
		},
		selectionbox = {
			ent.base_selbox[1] * .5,
			ent.base_selbox[2] * .5,
			ent.base_selbox[3] * .5,
			ent.base_selbox[4] * .5,
			ent.base_selbox[5] * .5,
			ent.base_selbox[6] * .5,
		},
	})

	return child
end


-- compatibility function for old entities to new modpack entities
function mobs:alias_mob(old_name, new_name)

	-- spawn egg
	minetest.register_alias(old_name, new_name)

	-- entity
	minetest.register_entity(":" .. old_name, {

		physical = false,

		on_step = function(self)

			if minetest.registered_entities[new_name] then
				minetest.add_entity(self.object:get_pos(), new_name)
			end

			self.object:remove()
		end
	})

end
