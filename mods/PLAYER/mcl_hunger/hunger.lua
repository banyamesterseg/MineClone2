local S = minetest.get_translator("mcl_hunger")
local mod_death_messages = minetest.get_modpath("mcl_death_messages")

-- wrapper for minetest.item_eat (this way we make sure other mods can't break this one)
local org_eat = minetest.do_item_eat
minetest.do_item_eat = function(hp_change, replace_with_item, itemstack, user, pointed_thing)

	if not user or user:is_player() == false then
		return itemstack
	end

	-- Call on_rightclick if the pointed node defines it
	if pointed_thing.type == "node" then
		local node = minetest.get_node(pointed_thing.under)
		if user and not user:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
			end
		end
	end

	local old_itemstack = itemstack

	local name = user:get_player_name()

	local creative = minetest.settings:get_bool("creative_mode") == true

	-- Special foodstuffs like the cake may disable the eating delay
	local no_eat_delay = creative or (minetest.get_item_group(itemstack:get_name(), "no_eat_delay") == 1)

	-- Allow eating only after a delay of 2 seconds. This prevents eating as an excessive speed.
	-- FIXME: time() is not a precise timer, so the actual delay may be +- 1 second, depending on which fraction
	-- of the second the player made the first eat.
	-- FIXME: In singleplayer, there's a cheat to circumvent this, simply by pausing the game between eats.
	-- This is because os.time() obviously does not care about the pause. A fix needs a different timer mechanism.
	if no_eat_delay or (mcl_hunger.last_eat[name] < 0) or (os.difftime(os.time(), mcl_hunger.last_eat[name]) >= 2) then
		local can_eat_when_full = creative or (mcl_hunger.active == false) or minetest.get_item_group(itemstack:get_name(), "can_eat_when_full") == 1
		-- Don't allow eating when player has full hunger bar (some exceptional items apply)
		if can_eat_when_full or (mcl_hunger.get_hunger(user) < 20) then
			itemstack = mcl_hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
			for _, callback in pairs(minetest.registered_on_item_eats) do
				local result = callback(hp_change, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
				if result then
					return result
				end
			end
			mcl_hunger.last_eat[name] = os.time()
		end
	end

	return itemstack
end

function mcl_hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local item = itemstack:get_name()
	local def = mcl_hunger.registered_foods[item]
	if not def then
		def = {}
		if type(hp_change) ~= "number" then
			hp_change = 1
			minetest.log("error", "Wrong on_use() definition for item '" .. item .. "'")
		end
		def.saturation = hp_change
		def.replace = replace_with_item
	end
	local func = mcl_hunger.item_eat(def.saturation, def.replace, def.poisontime, def.poison, def.exhaust, def.poisonchance, def.sound)
	return func(itemstack, user, pointed_thing)
end

-- Reset HUD bars after poisoning
function mcl_hunger.reset_bars_poison_damage(player)
	hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
end

function mcl_hunger.reset_bars_poison_hunger(player)
	hb.change_hudbar(player, "hunger", nil, nil, "hbhunger_icon.png", nil, "hbhunger_bar.png")
	if mcl_hunger.debug then
		hb.change_hudbar(player, "exhaustion", nil, nil, nil, nil, "mcl_hunger_bar_exhaustion.png")
	end
end

-- Poison player
local function poisonp(tick, time, time_left, damage, exhaustion, name)
	if not mcl_hunger.active then
		return
	end
	local player = minetest.get_player_by_name(name)
	-- First check if player is still there
	if not player then
		return
	end
	local name = player:get_player_name()
	-- Abort if poisonings have been stopped
	if mcl_hunger.poison_damage[name] == 0 and mcl_hunger.poison_hunger[name] == 0 then
		return
	end
	time_left = time_left + tick
	if time_left < time then
		minetest.after(tick, poisonp, tick, time, time_left, damage, exhaustion, name)
	else
		if damage > 0 then
			mcl_hunger.poison_damage[name] = mcl_hunger.poison_damage[name] - 1
		end
		if exhaustion > 0 then
			mcl_hunger.poison_hunger [name] = mcl_hunger.poison_hunger[name] - 1
		end
		if mcl_hunger.poison_damage[name] <= 0 then
			mcl_hunger.reset_bars_poison_damage(player)
		end
		if mcl_hunger.poison_hunger[name] <= 0 then
			mcl_hunger.reset_bars_poison_hunger(player)
		end
	end

	-- Deal damage and exhaust player
	-- TODO: Introduce fatal poison at higher difficulties
	if player:get_hp()-damage > 0 then
		if mod_death_messages then
			mcl_death_messages.player_damage(player, S("@1 succumbed to the poison.", name))
		end
		player:set_hp(player:get_hp()-damage)
	end

	mcl_hunger.exhaust(name, exhaustion)

end

local poisonrandomizer = PseudoRandom(os.time())

function mcl_hunger.item_eat(hunger_change, replace_with_item, poisontime, poison, exhaust, poisonchance, sound)
	return function(itemstack, user, pointed_thing)
		local itemname = itemstack:get_name()
		local creative = minetest.settings:get_bool("creative_mode") == true
		if itemstack:peek_item() ~= nil and user ~= nil then
			if not creative then
				itemstack:take_item()
			end
			local name = user:get_player_name()
			local hp = user:get_hp()

			local pos = user:get_pos()
			-- player height
			pos.y = pos.y + 1.5
			local foodtype = minetest.get_item_group(itemname, "food")
			if foodtype == 3 then
				-- Item is a drink, only play drinking sound (no particle)
				minetest.sound_play("survival_thirst_drink", {
					max_hear_distance = 12,
					gain = 1.0,
					pitch = 1 + math.random(-10, 10)*0.005,
					object = user,
				})
			else
				-- Assume the item is a food
				-- Add eat particle effect and sound
				local def = minetest.registered_items[itemname]
				local texture = def.inventory_image
				if not texture or texture == "" then
					texture = def.wield_image
				end
				-- Special item definition field: _food_particles
				-- If false, force item to not spawn any food partiles when eaten
				if def._food_particles ~= false and texture and texture ~= "" then
					local v = user:get_player_velocity()
					local minvel = vector.add(v, {x=-1, y=1, z=-1})
					local maxvel = vector.add(v, {x=1, y=2, z=1})

					minetest.add_particlespawner({
						amount = math.min(math.max(8, hunger_change*2), 25),
						time = 0.1,
						minpos = {x=pos.x, y=pos.y, z=pos.z},
						maxpos = {x=pos.x, y=pos.y, z=pos.z},
						minvel = minvel,
						maxvel = maxvel,
						minacc = {x=0, y=-5, z=0},
						maxacc = {x=0, y=-9, z=0},
						minexptime = 1,
						maxexptime = 1,
						minsize = 1,
						maxsize = 2,
						collisiondetection = true,
						vertical = false,
						texture = texture,
					})
				end
				minetest.sound_play("mcl_hunger_bite", {
					max_hear_distance = 12,
					gain = 1.0,
					pitch = 1 + math.random(-10, 10)*0.005,
					object = user,
				})
			end

			if mcl_hunger.active and hunger_change then
				-- Add saturation (must be defined in item table)
				local _mcl_saturation = minetest.registered_items[itemname]._mcl_saturation
				local saturation
				if not _mcl_saturation then
					saturation = 0
				else
					saturation = minetest.registered_items[itemname]._mcl_saturation
				end
				mcl_hunger.saturate(name, saturation, false)

				-- Add food points
				local h = mcl_hunger.get_hunger(user)
				if h < 20 and hunger_change then
					h = h + hunger_change
					if h > 20 then h = 20 end
					mcl_hunger.set_hunger(user, h, false)
				end

				hb.change_hudbar(user, "hunger", h)
				mcl_hunger.update_saturation_hud(user, mcl_hunger.get_saturation(user), h)
			end
			-- Poison
			if mcl_hunger.active and poisontime then
				local do_poison = false
				if poisonchance then
					if poisonrandomizer:next(0,100) < poisonchance then
						do_poison = true
					end
				else
					do_poison = true
				end
				if do_poison then
					-- Set poison bars
					if poison and poison > 0 then
						hb.change_hudbar(user, "health", nil, nil, "hbhunger_icon_health_poison.png", nil, "hbhunger_bar_health_poison.png")
						mcl_hunger.poison_damage[name] = mcl_hunger.poison_damage[name] + 1
					end
					if exhaust and exhaust > 0 then
						hb.change_hudbar(user, "hunger", nil, nil, "mcl_hunger_icon_foodpoison.png", nil, "mcl_hunger_bar_foodpoison.png")
						if mcl_hunger.debug then
							hb.change_hudbar(user, "exhaustion", nil, nil, nil, nil, "mcl_hunger_bar_foodpoison.png")
						end
						mcl_hunger.poison_hunger[name] = mcl_hunger.poison_hunger[name] + 1
					end
					poisonp(1, poisontime, 0, poison, exhaust, user:get_player_name())
				end
			end

			if not creative then
				itemstack:add_item(replace_with_item)
			end
		end
		return itemstack
	end
end

if mcl_hunger.active then
	-- player-action based hunger changes
	minetest.register_on_dignode(function(pos, oldnode, player)
		-- is_fake_player comes from the pipeworks, we are not interested in those
		if not player or not player:is_player() or player.is_fake_player == true then
			return
		end
		local name = player:get_player_name()
		-- dig event
		mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_DIG)
	end)
end

