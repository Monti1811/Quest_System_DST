local _G = GLOBAL
local fuel_armor_items = {shadow_crest = 3, shadow_mitre = 2} --, "shadow_lance"

local pickup_levels = {
    [1] = 0,
    [2] = 50,
    [3] = 200,
    [4] = 500,
    [5] = 1000,
}

local function getPickupLevel(inst)
    if inst.picked_up_items then
        for lvl, val in ipairs(pickup_levels) do
            if inst.picked_up_items < val then
                return lvl - 1
            end
        end
        return 5
    else
        return 0
    end
end

local function AddPrefabDescriptors()
    if not _G.rawget(_G, "Insight") then return end
    local prefab_descriptors = _G.Insight.prefab_descriptors
    local insight_env = _G.Insight.env
    for item, mult in pairs(fuel_armor_items) do
        prefab_descriptors[item] = {
            Describe = function(inst, context)
                local durabilityValue = insight_env.Round(inst.components.fueled.currentfuel/mult, 0)
                local description = string.format(context.lstr.protection, "90").."\n"..string.format(context.lstr.durability, durabilityValue, insight_env.Round(inst.components.fueled.maxfuel/mult, 0))

                return {
                    priority = 1,
                    description = description
                }
            end
        }
    end

    local AddDescriptorPostDescribe = insight_env.AddDescriptorPostDescribe
    local PrefabHasIcon = insight_env.PrefabHasIcon
    local no_show_prefabs = {shadow_crest = true, shadow_mitre = true, shadow_lance = true}
    if AddDescriptorPostDescribe then
        AddDescriptorPostDescribe("Quest System", "fueled", function(self, context, datas)
            if self.inst and no_show_prefabs[self.inst.prefab] then
                datas[1].description = nil
                datas[1].alt_description = nil
            end
        end)
    end
    prefab_descriptors["shadow_lance"] = {
        Describe = function(inst, context)
            local description, alt_description

            local self = inst.components.fueled
            local action_id = GLOBAL.ACTIONS.ATTACK.id
            local amount = self.maxfuel
            local attack_wear_multiplier = self.inst.components.weapon.attackwearmultipliers and self.inst.components.weapon.attackwearmultipliers:Get() or 1
            local mult = context.player and context.player:HasTag("shadow_aligned") and 2.5 or 1
            mult = 1/10 * mult / attack_wear_multiplier
            local uses = math.ceil(self.currentfuel * mult)
            local max_uses = math.ceil(amount * mult)

            if context.usingIcons and GLOBAL.rawget(context.lstr.actions, action_id) and PrefabHasIcon(context.lstr.actions[action_id]) then
                description = string.format(context.lstr.action_uses, context.lstr.actions[action_id], uses)
                alt_description = string.format(context.lstr.action_uses_verbose, context.lstr.actions[action_id], uses, max_uses)
            else
                description = string.format(context.lstr.lang.action_uses, context.lstr.lang.actions[action_id] or ("<string=ACTIONS." .. action_id .. ">"), uses)
                alt_description = string.format(context.lstr.lang.action_uses_verbose, context.lstr.lang.actions[action_id] or ("<string=ACTIONS." .. action_id .. ">"), uses, max_uses)
            end

            return {
                priority = 10,
                description = description,
                alt_description = alt_description
            }
        end
    }
    --[[prefab_descriptors["frogking_scepter"] = {
        Describe = function(inst, context)
            local description
            description = string.format(context.lstr.weapon_damage,context.lstr.weapon_damage_type.normal, "90").." against insects"

            return {
                priority = 48.9,
                description = description
            }
        end
    }]]
    prefab_descriptors["frogking_p_crown"] = {
        Describe = function(inst, context)
            local description
            description = "Frogs and Merms are friendly"

            return {
                priority = 0,
                description = description
            }
        end
    }
    prefab_descriptors["glommerfuelmachine"] = {
        Describe = function(inst, context)
            if not context.config["display_spawner_information"] then
                return
            end

            local description, alt_description

            local task = inst.components.periodicspawner.task
            local respawn_time = task and GetTaskRemaining(task) or nil

            if respawn_time then
                description = _G.subfmt(context.lstr.spawner.next, { child_name="blackglommerfuel", respawn_time=context.time:SimpleProcess(respawn_time) })
            else
                alt_description = string.format(context.lstr.spawner.child, "blackglommerfuel")
            end

            return {
                priority = 1,
                description = description,
                alt_description = alt_description,
                respawn_time = respawn_time
            }
        end
    }
    prefab_descriptors["glommer_lightflower"] = {
        Describe = function(inst, context)
            if not context.config["display_spawner_information"] then
                return
            end

            local description, alt_description

            local task = inst.components.periodicspawner.task
            local respawn_time = task and GetTaskRemaining(task) or nil

            if respawn_time then
                description = _G.subfmt(context.lstr.spawner.next, { child_name="glommerfuel", respawn_time=context.time:SimpleProcess(respawn_time) })
                description = description.."\nGlommer's Goop left: "..(inst.slime_left or 0)
            else
                alt_description = string.format(context.lstr.spawner.child, "glommerfuel")
            end

            return {
                priority = 1,
                description = description,
                alt_description = alt_description,
                respawn_time = respawn_time
            }
        end
    }
    prefab_descriptors.nightmarechester_eyebone = {
        Describe = function(inst, context)

            local respawn_time
            local description

            if inst.respawntask and inst.respawntime then
                respawn_time = inst.respawntime - GLOBAL.GetTime()
                description = string.format("<color=MOB_SPAWN><prefab=nightmarechester></color> will respawn in: %s", context.time:SimpleProcess(respawn_time))
            end
            local pet = next(inst.components.petleash.pets)
            if pet then
                local pickup_level = getPickupLevel(pet)
                description = (description and description.."\n" or "").."Pickup Level: "..pickup_level.."\n"..pet.picked_up_items..(pickup_level < 5 and "/"..pickup_levels[pickup_level+1] or "")
            end
            return {
                priority = 0,
                description = description,
                respawn_time = respawn_time
            }
        end
    }

end

AddSimPostInit(AddPrefabDescriptors)