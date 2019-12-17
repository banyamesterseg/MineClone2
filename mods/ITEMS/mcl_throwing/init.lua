mcl_throwing = {}

local S = minetest.get_translator("mcl_throwing")
local mod_death_messages = minetest.get_modpath("mcl_death_messages")
local mod_fishing = minetest.get_modpath("mcl_fishing")

-- 
-- Snowballs and other throwable items
--

local GRAVITY = tonumber(minetest.settings:get("movement_gravity"))

local entity_mapping = {
	["mcl_throwing:flying_bobber"] = "mcl_throwing:flying_bobber_entity",
	["mcl_throwing:snowball"] = "mcl_throwing:snowball_entity",
	["mcl_throwing:egg"] = "mcl_throwing:egg_entity",
	["mcl_throwing:ender_pearl"] = "mcl_throwing:ender_pearl_entity",
}

local velocities = {
	["mcl_throwing:flying_bobber_entity"] = 5,
	["mcl_throwing:snowball_entity"] = 22,
	["mcl_throwing:egg_entity"] = 22,
	["mcl_throwing:ender_pearl_entity"] = 22,
}

mcl_throwing.throw = function(throw_item, pos, dir, velocity, thrower)
	if velocity == nil then
		velocity = velocities[throw_item]
	end
	if velocity == nil then
		velocity = 22
	end

	local itemstring = ItemStack(throw_item):get_name()
	local obj = minetest.add_entity(pos, entity_mapping[itemstring])
	obj:set_velocity({x=dir.x*velocity, y=dir.y*velocity, z=dir.z*velocity})
	obj:set_acceleration({x=dir.x*-3, y=-GRAVITY, z=dir.z*-3})
	if thrower then
		obj:get_luaentity()._thrower = thrower
	end
	return obj
end

-- Throw item
local player_throw_function = function(entity_name, velocity)
	local func = function(item, player, pointed_thing)
		local playerpos = player:get_pos()
		local dir = player:get_look_dir()
		local obj = mcl_throwing.throw(item, {x=playerpos.x, y=playerpos.y+1.5, z=playerpos.z}, dir, velocity, player:get_player_name())
		if not minetest.settings:get_bool("creative_mode") then
			item:take_item()
		end
		return item
	end
	return func
end

local dispense_function = function(stack, dispenserpos, droppos, dropnode, dropdir)
	-- Launch throwable item
	local shootpos = vector.add(dispenserpos, vector.multiply(dropdir, 0.51))
	mcl_throwing.throw(stack:get_name(), shootpos, dropdir)
end

-- Staticdata handling because objects may want to be reloaded
local get_staticdata = function(self)
	local thrower
	-- Only save thrower if it's a player name
	if type(self._thrower) == "string" then
		thrower = self._thrower
	end
	local data = {
		_lastpos = self._lastpos,
		_thrower = thrower,
	}
	return minetest.serialize(data)
end

local on_activate = function(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if data then
		self._lastpos = data._lastpos
		self._thrower = data._thrower
	end
end

-- The snowball entity
local snowball_ENTITY={
	physical = false,
	timer=0,
	textures = {"mcl_throwing_snowball.png"},
	visual_size = {x=0.5, y=0.5},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = get_staticdata,
	on_activate = on_activate,
	_thrower = nil,

	_lastpos={},
}
local egg_ENTITY={
	physical = false,
	timer=0,
	textures = {"mcl_throwing_egg.png"},
	visual_size = {x=0.45, y=0.45},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = get_staticdata,
	on_activate = on_activate,
	_thrower = nil,

	_lastpos={},
}
-- Ender pearl entity
local pearl_ENTITY={
	physical = false,
	timer=0,
	textures = {"mcl_throwing_ender_pearl.png"},
	visual_size = {x=0.9, y=0.9},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = get_staticdata,
	on_activate = on_activate,

	_lastpos={},
	_thrower = nil,		-- Player ObjectRef of the player who threw the ender pearl
}

local flying_bobber_ENTITY={
	physical = false,
	timer=0,
	textures = {"mcl_fishing_bobber.png"}, --FIXME: Replace with correct texture.
	visual_size = {x=0.5, y=0.5},
	collisionbox = {0,0,0,0,0,0},
	pointable = false,

	get_staticdata = get_staticdata,
	on_activate = on_activate,

	_lastpos={},
	_thrower = nil,
	objtype="fishing",
}

local check_object_hit = function(self, pos, mob_damage)
	for _,object in pairs(minetest.get_objects_inside_radius(pos, 1.5)) do

		local entity = object:get_luaentity()

		if entity
		and entity.name ~= self.object:get_luaentity().name then

			if object:is_player() and self._thrower ~= object:get_player_name() then
				-- TODO: Deal knockback
				self.object:remove()
				return true
			elseif entity._cmi_is_mob == true and (self._thrower ~= object) then
				local dmg = {}
				if mob_damage then
					dmg = mob_damage(entity.name)
				end

				-- FIXME: Knockback is broken
				object:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = dmg,
				}, nil)

				self.object:remove()
				return true
			end
		end
	end
	return false
end

-- Snowball on_step()--> called when snowball is moving.
local snowball_on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]

	-- Destroy when hitting a solid node
	if self._lastpos.x~=nil then
		if (def and def.walkable) or not def then
			minetest.sound_play("mcl_throwing_snowball_impact_hard", { pos = self.object:get_pos(), max_hear_distance=16, gain=0.7 })
			self.object:remove()
			return
		end
	end

	local mob_damage = function(mobname)
		if mobname == "mobs_mc:blaze" then
			return {fleshy = 3}
		else
			return {}
		end
	end

	if check_object_hit(self, pos, mob_damage) then
		minetest.sound_play("mcl_throwing_snowball_impact_soft", { pos = self.object:get_pos(), max_hear_distance=16, gain=0.7 })
		return
	end

	self._lastpos={x=pos.x, y=pos.y, z=pos.z} -- Set _lastpos-->Node will be added at last pos outside the node
end

-- Movement function of egg
local egg_on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]

	-- Destroy when hitting a solid node with chance to spawn chicks
	if self._lastpos.x~=nil then
		if (def and def.walkable) or not def then
			-- 1/8 chance to spawn a chick
			-- FIXME: Chicks have a quite good chance to spawn in walls
			local r = math.random(1,8)

			-- Turn given object into a child
			local make_child= function(object)
				local ent = object:get_luaentity()
				object:set_properties({
					visual_size = { x = ent.base_size.x/2, y = ent.base_size.y/2 },
					collisionbox = {
						ent.base_colbox[1]/2,
						ent.base_colbox[2]/2,
						ent.base_colbox[3]/2,
						ent.base_colbox[4]/2,
						ent.base_colbox[5]/2,
						ent.base_colbox[6]/2,
					}
				})
				ent.child = true
			end
			if r == 1 then
				make_child(minetest.add_entity(self._lastpos, "mobs_mc:chicken"))

				-- BONUS ROUND: 1/32 chance to spawn 3 additional chicks
				local r = math.random(1,32)
				if r == 1 then
					local offsets = {
						{ x=0.7, y=0, z=0 },
						{ x=-0.7, y=0, z=-0.7 },
						{ x=-0.7, y=0, z=0.7 },
					}
					for o=1, 3 do
						local pos = vector.add(self._lastpos, offsets[o])
						make_child(minetest.add_entity(pos, "mobs_mc:chicken"))
					end
				end
			end
			minetest.sound_play("mcl_throwing_egg_impact", { pos = self.object:get_pos(), max_hear_distance=10, gain=0.5 })
			self.object:remove()
			return
		end
	end

	-- Destroy when hitting a mob or player (no chick spawning)
	if check_object_hit(self, pos) then
		minetest.sound_play("mcl_throwing_egg_impact", { pos = self.object:get_pos(), max_hear_distance=10, gain=0.5 })
		return
	end

	self._lastpos={x=pos.x, y=pos.y, z=pos.z} -- Set lastpos-->Node will be added at last pos outside the node
end

-- Movement function of ender pearl
local pearl_on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	pos.y = math.floor(pos.y)
	local node = minetest.get_node(pos)
	local nn = node.name
	local def = minetest.registered_nodes[node.name]

	-- Destroy when hitting a solid node
	if self._lastpos.x~=nil then
		local walkable = (def and def.walkable)

		-- No teleport for hitting ignore for now. Otherwise the player could get stuck.
		-- FIXME: This also means the player loses an ender pearl for throwing into unloaded areas
		if node.name == "ignore" then
			self.object:remove()
		-- Activate when hitting a solid node or a plant
		elseif walkable or nn == "mcl_core:vine" or nn == "mcl_core:deadbush" or minetest.get_item_group(nn, "flower") ~= 0 or minetest.get_item_group(nn, "sapling") ~= 0 or minetest.get_item_group(nn, "plant") ~= 0 or minetest.get_item_group(nn, "mushroom") ~= 0 or not def then
			local player = minetest.get_player_by_name(self._thrower)
			if player then
				-- Teleport and hurt player

				-- First determine good teleport position
				local dir = {x=0, y=0, z=0}

				local v = self.object:get_velocity()
				if walkable then
					local vc = table.copy(v) -- vector for calculating
					-- Node is walkable, we have to find a place somewhere outside of that node
					vc = vector.normalize(vc)

					-- Zero-out the two axes with a lower absolute value than
					-- the axis with the strongest force
					local lv, ld
					lv, ld = math.abs(vc.y), "y"
					if math.abs(vc.x) > lv then
						lv, ld = math.abs(vc.x), "x"
					end
					if math.abs(vc.z) > lv then
						lv, ld = math.abs(vc.z), "z"
					end
					if ld ~= "x" then vc.x = 0 end
					if ld ~= "y" then vc.y = 0 end
					if ld ~= "z" then vc.z = 0 end

					-- Final tweaks to the teleporting pos, based on direction
					-- Impact from the side
					dir.x = vc.x * -1
					dir.z = vc.z * -1

					-- Special case: top or bottom of node
					if vc.y > 0 then
						-- We need more space when impact is from below
						dir.y = -2.3
					elseif vc.y < 0 then
						-- Standing on top
						dir.y = 0.5
					end
				end
				-- If node was not walkable, no modification to pos is made.

				-- Final teleportation position
				local telepos = vector.add(pos, dir)
				local telenode = minetest.get_node(telepos)

				--[[ It may be possible that telepos is walkable due to the algorithm.
				Especially when the ender pearl is faster horizontally than vertical.
				This applies final fixing, just to be sure we're not in a walkable node ]]
				if not minetest.registered_nodes[telenode.name] or minetest.registered_nodes[telenode.name].walkable then
					if v.y < 0 then
						telepos.y = telepos.y + 0.5
					else
						telepos.y = telepos.y - 2.3
					end
				end

				local oldpos = player:get_pos()
				-- Teleport and hurt player
				player:set_pos(telepos)
				player:set_hp(player:get_hp() - 5, { type = "fall", origin = "mod" })

				-- 5% chance to spawn endermite at the player's origin
				local r = math.random(1,20)
				if r == 1 then
					minetest.add_entity(oldpos, "mobs_mc:endermite")
				end

			end
			self.object:remove()
			return
		end
	end
	self._lastpos={x=pos.x, y=pos.y, z=pos.z} -- Set lastpos-->Node will be added at last pos outside the node
end

-- Movement function of flying bobber
local flying_bobber_on_step = function(self, dtime)
	self.timer=self.timer+dtime
	local pos = self.object:get_pos()
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	--local player = minetest.get_player_by_name(self._thrower)

	-- Destroy when hitting a solid node
	if self._lastpos.x~=nil then
		if (def and (def.walkable or def.liquidtype == "flowing" or def.liquidtype == "source")) or not def then
			local make_child= function(object)
				local ent = object:get_luaentity()
				ent.player = self._thrower
				ent.child = true
			end
			make_child(minetest.add_entity(self._lastpos, "mcl_fishing:bobber_entity"))
			self.object:remove()
			return
		end
	end
	self._lastpos={x=pos.x, y=pos.y, z=pos.z} -- Set lastpos-->Node will be added at last pos outside the node
end

snowball_ENTITY.on_step = snowball_on_step
egg_ENTITY.on_step = egg_on_step
pearl_ENTITY.on_step = pearl_on_step
flying_bobber_ENTITY.on_step = flying_bobber_on_step

minetest.register_entity("mcl_throwing:snowball_entity", snowball_ENTITY)
minetest.register_entity("mcl_throwing:egg_entity", egg_ENTITY)
minetest.register_entity("mcl_throwing:ender_pearl_entity", pearl_ENTITY)
minetest.register_entity("mcl_throwing:flying_bobber_entity", flying_bobber_ENTITY)

local how_to_throw = S("Use the punch key to throw.")

-- Snowball
minetest.register_craftitem("mcl_throwing:snowball", {
	description = S("Snowball"),
	_doc_items_longdesc = S("Snowballs can be thrown or launched from a dispenser for fun. Hitting something with a snowball does nothing."),
	_doc_items_usagehelp = how_to_throw,
	inventory_image = "mcl_throwing_snowball.png",
	stack_max = 16,
	groups = { weapon_ranged = 1 },
	on_use = player_throw_function("mcl_throwing:snowball_entity"),
	_on_dispense = dispense_function,
})

-- Egg
minetest.register_craftitem("mcl_throwing:egg", {
	description = S("Egg"),
	_doc_items_longdesc = S("Eggs can be thrown or launched from a dispenser and breaks on impact. There is a small chance that 1 or even 4 chicks will pop out of the egg."),
	_doc_items_usagehelp = how_to_throw,
	inventory_image = "mcl_throwing_egg.png",
	stack_max = 16,
	on_use = player_throw_function("mcl_throwing:egg_entity"),
	_on_dispense = dispense_function,
	groups = { craftitem = 1 },
})

-- Ender Pearl
minetest.register_craftitem("mcl_throwing:ender_pearl", {
	description = S("Ender Pearl"),
	_doc_items_longdesc = S("An ender pearl is an item which can be used for teleportation at the cost of health. It can be thrown and teleport the thrower to its impact location when it hits a solid block or a plant. Each teleportation hurts the user by 5 hit points."),
	_doc_items_usagehelp = how_to_throw,
	wield_image = "mcl_throwing_ender_pearl.png",
	inventory_image = "mcl_throwing_ender_pearl.png",
	stack_max = 16,
	on_use = player_throw_function("mcl_throwing:ender_pearl_entity"),
	groups = { transport = 1 },
})

