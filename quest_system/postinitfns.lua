-------------------------PlayerPostInit---------------------------

local NIGHTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/beaver_vision_cc.tex",
    dusk = "images/colour_cubes/beaver_vision_cc.tex",
    night = "images/colour_cubes/beaver_vision_cc.tex",
    full_moon = "images/colour_cubes/beaver_vision_cc.tex",
}

AddPlayerPostInit(function(inst)

    --Add netvars needed for the level system to be shown in the quest log
    if GLOBAL.TUNING.QUEST_COMPONENT.LEVELSYSTEM == 1 then
        inst.q_system = {
            healthbonus = GLOBAL.net_float(inst.GUID,"healthbonus"),
            sanitybonus = GLOBAL.net_float(inst.GUID,"sanitybonus"),
            hungerbonus = GLOBAL.net_float(inst.GUID,"hungerbonus"),
            speedbonus = GLOBAL.net_float(inst.GUID,"speedbonus"),
            summerinsulationbonus = GLOBAL.net_float(inst.GUID,"summerinsulationbonus"),
            winterinsulationbonus = GLOBAL.net_float(inst.GUID,"winterinsulationbonus"),
            workmultiplierbonus = GLOBAL.net_float(inst.GUID,"workmultiplierbonus"),
        }  
        for k,v in pairs(inst.q_system) do
            inst.q_system[k]:set(0)
        end
    end

    --Add netvar to trigger the reversing of the camera for quest with merms
    inst.net_cameratrigger = GLOBAL.net_bool(inst.GUID,"net_cameratrigger","net_cameratriggerdirty")
    inst.net_cameratrigger:set(false)
    inst:ListenForEvent("net_cameratriggerdirty",function(inst)
        if GLOBAL.TheCamera then
            GLOBAL.TheCamera.turned = inst.net_cameratrigger:value()
        end
    end)

    --Add nightvision for temp reward of night vision
    inst.net_nightvisiontrigger = GLOBAL.net_bool(inst.GUID,"net_nightvisiontrigger","net_nightvisiontriggerdirty")
    inst.net_nightvisiontrigger:set(false)
    inst:ListenForEvent("net_nightvisiontriggerdirty",function(inst)
        if inst.components.playervision then
            local val = inst.net_nightvisiontrigger:value()
            inst.components.playervision:ForceNightVision(val)
            inst.components.playervision:SetCustomCCTable(val and NIGHTVISION_COLOURCUBES or nil)
        end
    end)

    --Adding netvar to transmit current points of all players
    inst.player_qs_points = {}
    inst.net_player_qs_points = GLOBAL.net_string(inst.GUID,"net_player_qs_points","net_player_qs_points_dirty")
    inst:ListenForEvent("net_player_qs_points_dirty",function()
        local str = inst.net_player_qs_points:value()
        inst.player_qs_points = json.decode(str)
    end)

	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end

    --Add the quest component (I mean it's the point of this mod)
	inst:AddComponent("quest_component")
    --Add the temporary bonus component which makes you able to get temporary boni (seems like it does what it says)
    inst:AddComponent("temporarybonus")
    if GLOBAL.TUNING.QUEST_COMPONENT.LEVELSYSTEM == 1 then
        --Add level component if it's enabled
        inst:AddComponent("levelupcomponent")
    end
    
    --Need to save quests and more if a player rerolls to another character so that he doesn't lose his progress.
    --No need to save levelupcomponent as it doesn't save anything and orients itself on the quest component
    local old_SaveForReroll = inst.SaveForReroll or function() end
    inst.SaveForReroll = function(inst,...)
        local data = old_SaveForReroll(inst,...) or {}
        data.quest_component = inst.components.quest_component ~= nil and inst.components.quest_component:OnSave() or nil
        --data.levelupcomponent = inst.components.levelupcomponent ~= nil and inst.components.levelupcomponent:OnSave() or nil
        return next(data) ~= nil and data or nil
    end

    local old_LoadForReroll = inst.LoadForReroll or function() end
    inst.LoadForReroll = function(inst,data,...)
        local ret = old_LoadForReroll(inst,data,...)
        if data.quest_component ~= nil and inst.components.quest_component ~= nil then
            inst.components.quest_component:OnLoad(data.quest_component)
        end
        --[[if data.levelupcomponent ~= nil and inst.components.levelupcomponent ~= nil then
            inst.components.levelupcomponent:OnLoad(data.levelupcomponent)
        end]]
    end

    local old_OnDespawn = inst.OnDespawn or function() end
    inst.OnDespawn = function(inst,migrationdata,...)
        if migrationdata == nil and inst.components.inventory then
            inst.components.inventory:DropEverythingWithTag("godly_item")
        end
        return old_OnDespawn(inst,migrationdata,...)
    end

end)



-------------------------PrefabPostInit------------------------

--Add a chance that creatures drop requests 
local function Request_Drop()
    local days = GLOBAL.TheWorld.state.cycles
    days = days < 50 and days/50 or 1
    local requests_chances = {
        request_quest = 75,
        request_quest_very_easy = 5,
        request_quest_easy = 5,
        request_quest_normal = 5,
        request_quest_difficult = 5*days,
        request_quest_very_difficult = 5*days,
    }
    return weighted_random_choice(requests_chances)
end

AddPrefabPostInitAny(function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    if inst.components.lootdropper == nil or inst.components.health == nil or inst.components.workable ~= nil then
        return inst
    end
    local drop = Request_Drop()
    inst.components.lootdropper:AddChanceLoot(drop,GLOBAL.TUNING.QUEST_COMPONENT.REQUEST_QUEST)
end)

--Add an event if something is trapped (used for quests)
local function OnHarvestTrap(inst,data)
    if data and data.doer then
        data.doer:PushEvent("trapped_something",{trap = inst})
    end
end

local function Trapping(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("harvesttrap",OnHarvestTrap)
end

AddPrefabPostInit("birdtrap",Trapping)
AddPrefabPostInit("trap",Trapping)

--Add an event when a fertilizer is used (for quests)
local fertilizers = {"spoiled_fish_small","spoiled_fish","soil_amender_low","soil_amender_med","soil_amender_high","soil_amender_fermented","spoiled_food","rottenegg","compost","compostwrap","poop","guano","fertilizer","glommerfuel","treegrowthsolution",}

for k,v in ipairs(fertilizers) do
    AddPrefabPostInit(v,function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return inst
        end
        local old_onfertilize = inst.components.fertilizer.onappliedfn or function() end
        inst.components.fertilizer.onappliedfn = function(inst, final_use, doer, target,...)
            if doer then
                doer:PushEvent("has_fertilized",{fertilizer = inst.prefab, target = target})
            end
            return GLOBAL.unpack{old_onfertilize(inst, final_use, doer, target,...)}
        end
        local old_ondeploy = inst.components.deployable.ondeploy or function() end
        inst.components.deployable.ondeploy = function(inst, pt, deployer,...)
            if deployer then
                deployer:PushEvent("has_fertilized_ground",{fertilizer = inst.prefab})
            end
            return GLOBAL.unpack{old_ondeploy(inst, pt, deployer,...)}
        end
    end)
end

--Add a tag to the statue of glommer for a quest
AddPrefabPostInit("statueglommer",function(inst)
    inst:AddTag("statueglommer")
end)

--Add an event if the winch raises something (for quests)
AddPrefabPostInit("winch",function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    if inst.components.winch then
        local old_onfullyraisedfn = inst.components.winch.onfullyraisedfn or function() end
        inst.components.winch.onfullyraisedfn = function(inst,...)
            if inst.components.inventory ~= nil and inst.components.inventory:GetItemInSlot(1) then
                local pos = Vector3(inst.Transform:GetWorldPosition())
                local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 12)
                for k,v in pairs(ents) do
                    if v:HasTag("player") then
                        v:PushEvent("raised_salvageable")
                    end
                end
            end
            return old_onfullyraisedfn(inst,...)
        end
    end
end)

--Add an event when something is repaired with a sewing kit or sewing tape that gives the target
local function OnSewn(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    if inst.components.sewing then
        local old_onsewn = inst.components.sewing.onsewn
        inst.components.sewing.onsewn = function(inst,target,doer,...)
            doer:PushEvent("repair",target)
        end
    end
end

AddPrefabPostInit("sewing_kit",OnSewn)
AddPrefabPostInit("sewing_tape",OnSewn)

--Add an event that fires if a vegetables is harvested
local veggies = {}
for k,v in pairs(require("prefabs/farm_plant_defs").PLANT_DEFS) do
    table.insert(veggies,k)
    table.insert(veggies,k.."_oversized")
end

for _,veg in ipairs(veggies) do
    AddPrefabPostInit(veg,function(inst)
        if GLOBAL.TheWorld.ismastersim then
            inst:ListenForEvent("on_loot_dropped",function(inst)
                local pos = inst:GetPosition()
                local player = GLOBAL.FindClosestPlayerInRangeSq(pos.x,pos.y,pos.z,5)
                if player then
                    player:PushEvent("harvested_veg",inst)
                end
            end)
        end
    end)
end

local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = math.random(7,14)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

--Change glommer statue to be activable for quest line
AddPrefabPostInit("statueglommer",function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = function(inst,doer)
        if next(GLOBAL.TheWorld.components.glommer_boss_comp.glommers) ~= nil or GLOBAL.TheWorld.components.glommer_boss_comp.chester ~= nil then
            return false,"GLOMMER_ACTIVE"
        end
        doer:RemoveTag("can_fight_glommer")
        local chester_sounds = {"hurt","pant","death","open","close","pop","boing","lick"}
        local glommer_sounds = {"flap","idle_voice","vomit_voice","vomit_liquid","bounce_voice","bounce_ground","hurt_voice","die_voice","sleep_voice"}
        local function PlaySound(inst,sound)
            if sound == "chester" then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/"..chester_sounds[math.random(#chester_sounds)])
            else
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/"..glommer_sounds[math.random(#glommer_sounds)])
            end
        end
        local function PlaySounds(inst,count)
            count = count or 2
            for i = 1,count do
                inst:DoTaskInTime(math.random()/2,PlaySound,"chester")
                inst:DoTaskInTime(math.random()/2,PlaySound,"glommer")
            end
            if count >=10 then
                return
            end
            local new_count = count+1
            inst:DoTaskInTime(1,PlaySounds,new_count)
        end
        PlaySounds(inst,2)
        inst:DoTaskInTime(10,function()
            doer:PushEvent("started_glommer_fight")
            GLOBAL.TheWorld.components.glommer_boss_comp:StartBossfight(doer)
            local pos = doer:GetPosition()
            local chesterboss = GLOBAL.SpawnPrefab("chester_boss")
            local tries = 0
            local function FindSpawnPoint(pos)
                local pt = GetSpawnPoint(pos)
                tries = tries + 1
                if pt then
                    return pt 
                elseif tries > 200 then
                    pt = GLOBAL.Vector3(0,0,0)
                else
                    return FindSpawnPoint(pos)
                end
            end
            local spawn_point = FindSpawnPoint(pos)
            chesterboss.Transform:SetPosition(spawn_point.x,10,spawn_point.z)
            chesterboss.sg:GoToState("appear")
            GLOBAL.TheWorld.components.glommer_boss_comp.chester = chesterboss
        end)
    end
    inst.components.activatable.inactive = false
    inst.components.activatable.CanActivateFn = function(inst,doer)
        if doer:HasTag("can_fight_glommer") then
            return true
        end
        return false
    end
end)


--Add quest_loadpostpass (used to save the bosses from bossfights), attackwaves (used for quests that call an attackwave) and 
--glommer_boss_comp (used for the glommer bossfight) components to TheWorld, make periodic task that transmits points of players
AddPrefabPostInit("world",function(inst)

	if not inst.ismastersim then
		return inst
	end
	inst:AddComponent("quest_loadpostpass")
    inst:AddComponent("attackwaves")
    inst:AddComponent("glommer_boss_comp")

    inst:DoPeriodicTask(30,function()
        local tab = {}
        for k,v in ipairs(GLOBAL.AllPlayers) do
            if v.components.quest_component then
                tab[v.userid] = TUNING.QUEST_COMPONENT.CalculatePoints(v.components.quest_component.level,v.components.quest_component.points)
            end
        end
        local str = json.encode(tab)
        for k,v in ipairs(GLOBAL.AllPlayers) do
            v.net_player_qs_points:set(str)
        end
    end)

end)

--Add the teleport function to the lavaarena portal to return to the initial starting point
local function teleport_end(teleportee, pos)

    if teleportee.components.inventory ~= nil and teleportee.components.inventory:IsHeavyLifting() then
        teleportee.components.inventory:DropItem(teleportee.components.inventory:Unequip(EQUIPSLOTS.BODY),true,true)
    end

    if teleportee:HasTag("player") then
        teleportee.sg.statemem.teleport_task = nil
        teleportee.sg:GoToState(teleportee:HasTag("playerghost") and "appear" or "wakeup")
        teleportee.SoundEmitter:PlaySound("dontstarve/common/staffteleport")
    else
        teleportee:Show()
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(true)
        end
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(false)
        end
    end
    if teleportee.components.quest_component then
    	teleportee.components.quest_component.pos_before_fight = nil
    	teleportee:RemoveTag("won_against_boss")
    	teleportee:RemoveTag("currently_in_bossfight")
    end
end

local function teleport_continue(teleportee, pos)
    if teleportee.Physics ~= nil then
        teleportee.Physics:Teleport(pos.x, 0, pos.z)
    else
        teleportee.Transform:SetPosition(pos.x, 0, pos.z)
    end

    if teleportee:HasTag("player") then
        teleportee:SnapCamera()
        teleportee:ScreenFade(true, 1)
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(1, teleport_end, pos)
    else
        teleport_end(teleportee, pos)
    end
end

local function TeleportTo(inst,teleportee,pos)
	pos = pos or teleportee.components.quest_component and teleportee.components.quest_component.pos_before_fight or {x = 0, y = 0, z = 0}
    local isplayer = teleportee:HasTag("player")
    if isplayer then
        teleportee.sg:GoToState("forcetele")
    else
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(true)
        end
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(false)
        end
        teleportee:Hide()
    end

    if isplayer then
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(3, teleport_continue, pos)
    else
        teleport_continue(teleportee, pos)
    end
    inst:TurnOff()
end

AddPrefabPostInit("lavaarena_portal",function(inst)

	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("teleporter_boss_island")

	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end

	inst.portalfx = nil
	inst.TurnOn = function()
		if inst.portalfx ~= nil then
			return
		end
		inst.portalfx = SpawnPrefab("lavaarena_portal_activefx")
		inst.portalfx.Transform:SetPosition(inst:GetPosition():Get())
		inst:AddTag("can_be_used")
	end

	inst.TurnOff = function()
		if inst.portalfx == nil then
			return
		end
		inst.portalfx.AnimState:PlayAnimation("portal_pst")
		inst.portalfx:ListenForEvent("animover", inst.portalfx.Remove)
		inst.portalfx = nil
		inst:RemoveTag("can_be_used")
	end

	inst:AddComponent("teleporter")
	inst.components.teleporter.enabled = false


	inst.TeleportTo = TeleportTo
end)

--[[local UpvalueHacker = require("quest_util/upvaluehacker")

local fxs = {"spat_splat_fx","spat_splash_fx_full","spat_splash_fx_med","spat_splash_fx_low","spat_splash_fx_melted"}
for _,fx in ipairs(fxs) do
    AddPrefabPostInit(fx,function(inst)
        local goo = UpvalueHacker.GetUpvalue()]]

--Adding the fuel component to the custom fueltype froglegs for the frogking crown
local FUELTYPE = GLOBAL.FUELTYPE
FUELTYPE.FROGLEGS = "froglegs"

local froglegs = {"froglegs","froglegs_cooked"}

for _,prefab in ipairs(froglegs) do
    AddPrefabPostInit(prefab, function(inst)
        if not inst.components.fuel then
            inst:AddComponent("fuel")
        end
        inst.components.fuel.fueltype = FUELTYPE.FROGLEGS
        inst.components.fuel.fuelvalue = 200
    end)
end


-----------------------------------SimPostInit----------------------------------

local function RemoveQuestFromTuning(name)
    if name then
        GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = nil
        for i = 1,5 do
            GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..i][name] = nil
        end
    end
end

--Add keyhandler for opening the quest log (and for me to open the quest board without clicking on it)
AddSimPostInit(function() 
    GLOBAL.TheInput:AddKeyHandler(function(key, down)
        if not down then return end 
        if key == GLOBAL.TUNING.QUEST_COMPONENT.HOTKEY_QUESTLOG then
            if GLOBAL.ThePlayer then
                if GLOBAL.ThePlayer.HUD:IsCraftingOpen() then 
                    return
                end
                local screen = TheFrontEnd:GetActiveScreen()
                if not screen or not screen.name then return true end
                if screen.name:find("HUD") then
                    TheFrontEnd:PushScreen(require("screens/quest_widget")(GLOBAL.ThePlayer))
                    return true
                else
                    if screen.name == "Quest_Widget" then
                        screen:OnClose()
                    end
                end
            end
        end
        if key == GLOBAL.KEY_O then
            if GLOBAL.ThePlayer and GLOBAL.ThePlayer.userid == "KU_7veFKyHP" then
                if GLOBAL.ThePlayer.HUD:IsCraftingOpen() then 
                    return
                end
                local screen = TheFrontEnd:GetActiveScreen()
                if not screen or not screen.name then return true end
                if screen.name:find("HUD") then
                    TheFrontEnd:PushScreen(require("screens/quest_board_widget")(GLOBAL.ThePlayer))
                    return true
                else
                    if screen.name == "Quest_Board_Widget" then
                        --screen:OnClose()
                    end
                end
            end
        end
    end)

    --Check world settings and disable quests if they are impossible to complete
    if GLOBAL.TUNING.SPAWN_EYEOFTERROR == false then
        RemoveQuestFromTuning("The Eye of Cthulhu")
        RemoveQuestFromTuning("Twins Of Destruction")
    end
    if GLOBAL.TUNING.SPAWN_BEARGER == false then
        RemoveQuestFromTuning("The Fearful Trial")
    end
    if GLOBAL.TUNING.SPAWN_DEERCLOPS == false then
        RemoveQuestFromTuning("The Fearful Trial")
        RemoveQuestFromTuning("Mage of the Manor Baldur")
    end
    if GLOBAL.TUNING.MOOSE_DENSITY == 0 then
        RemoveQuestFromTuning("The Fearful Trial")
    end
    if GLOBAL.TUNING.SPAWN_DRAGONFLY == false then
        --RemoveQuestFromTuning("The Fearful Trial")
    end
    if GLOBAL.TUNING.LEIF_PERCENT_CHANCE == 0 then
        RemoveQuestFromTuning("Treebeard's end")
    end
    if GLOBAL.TUNING.SPAWN_CRABKING == false then
        RemoveQuestFromTuning("The Impregnable Fortress")
    end
    if GLOBAL.TUNING.BEEQUEEN_SPAWN_WORK_THRESHOLD == 0 then
        --RemoveQuestFromTuning("Treebeard's end")
    end
    if GLOBAL.TUNING.SPAWN_TOADSTOOL == false then
        RemoveQuestFromTuning("The Biggest Frog")
    end
    if GLOBAL.TUNING.SPAWN_MALBATROSS == false then
        RemoveQuestFromTuning("The Bane of Lake Nen")
    end
    if GLOBAL.TUNING.SPAWN_KLAUS == false then
        RemoveQuestFromTuning("Ho Ho Ho")
    end
    if GLOBAL.TUNING.SPAWN_SPIDERQUEEN == false then
        --RemoveQuestFromTuning("Ho Ho Ho")
    end
    if GLOBAL.TUNING.SPAWN_MUTATED_HOUNDS == false then
        RemoveQuestFromTuning("Orcus's Living Dead")
    end
    if GLOBAL.TUNING.SHARK_SPAWN_CHANCE == 0 then
        RemoveQuestFromTuning("The Sharks Demise")
    end
    if GLOBAL.TUNING.MERMHOUSE_ENABLED == false then
        RemoveQuestFromTuning("Mirror of Merms")
    end
    if GLOBAL.TUNING.HUNT_COOLDOWN == -1 then
        RemoveQuestFromTuning("Detective Work")
    end
    if GLOBAL.TUNING.MOSQUITO_POND_ENABLED == false then
        RemoveQuestFromTuning("Off to donate blood")
    end
    if GLOBAL.TUNING.PIGHOUSE_ENABLED == false then
        RemoveQuestFromTuning("Front Pigs") 
        RemoveQuestFromTuning("Beyond the Charming Hamlet")
    end

    --Compability with Epic Healthbar
    if TUNING.EPICHEALTHBAR ~= nil and type(TUNING.EPICHEALTHBAR) == "table" then
        TUNING.EPICHEALTHBAR.THEMES.CHESTER_BOSS = { 162 / 255, 0 / 255, 202 / 255 }
        TUNING.EPICHEALTHBAR.PHASES.CHESTER_BOSS = { 0.5 }

        TUNING.EPICHEALTHBAR.THEMES.GLOMMER_BOSS = { 247 / 255, 247 / 255, 247 / 255 }
    end
end)
