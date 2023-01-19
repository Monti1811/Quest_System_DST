local _G = GLOBAL
local fuel_armor_items = {"shadow_crest", "shadow_mitre"} --, "shadow_lance"

local function AddPrefabDescriptors()
    if not _G.rawget(_G, "Insight") then return end
    local prefab_descriptors = _G.Insight.prefab_descriptors
    for _, item in ipairs(fuel_armor_items) do
        devprint("Insight",item, prefab_descriptors[item])
        prefab_descriptors[item] = {
            Describe = function(inst, context)
                local description
                description = string.format(context.lstr.protection, "90")
                return {
                    priority = 1.1,
                    description = description
                }
            end
        }
        devprint("Insight2",item, prefab_descriptors[item])
    end
    prefab_descriptors["shadow_lance"] = {
        Describe = function(inst, context)
            local description
            description = string.format(context.lstr.weapon_damage,context.lstr.weapon_damage_type.normal, "85").."against Lunar targets"

            return {
                priority = 48.9,
                description = description
            }
        end
    }
    prefab_descriptors["frogking_scepter"] = {
        Describe = function(inst, context)
            local description
            description = string.format(context.lstr.weapon_damage,context.lstr.weapon_damage_type.normal, "90").." against insects"

            return {
                priority = 48.9,
                description = description
            }
        end
    }
    prefab_descriptors["frogking_p_crown"] = {
        Describe = function(inst, context)
            local description
            description = "Frogs are friendly"

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

end

AddSimPostInit(AddPrefabDescriptors)