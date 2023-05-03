-------------------------PlayerPostInit---------------------------
local net_float = GLOBAL.net_float
local net_bool = GLOBAL.net_bool
local net_string = GLOBAL.net_string
local QUEST_COMPONENT = GLOBAL.TUNING.QUEST_COMPONENT
local TheCamera = GLOBAL.TheCamera
local unpack = GLOBAL.unpack
local SpawnPrefab = GLOBAL.SpawnPrefab
local Vector3 = GLOBAL.Vector3
local AllPlayers = GLOBAL.AllPlayers
local TheSim = GLOBAL.TheSim

local NIGHTVISION_COLOURCUBES =
{
    day = "images/colour_cubes/beaver_vision_cc.tex",
    dusk = "images/colour_cubes/beaver_vision_cc.tex",
    night = "images/colour_cubes/beaver_vision_cc.tex",
    full_moon = "images/colour_cubes/beaver_vision_cc.tex",
}

AddPlayerPostInit(function(inst)

    --Add netvars needed for the level system to be shown in the quest log
    if QUEST_COMPONENT.LEVELSYSTEM == 1 then
        inst.q_system = {
            healthbonus = net_float(inst.GUID,"healthbonus"),
            sanitybonus = net_float(inst.GUID,"sanitybonus"),
            hungerbonus = net_float(inst.GUID,"hungerbonus"),
            speedbonus = net_float(inst.GUID,"speedbonus"),
            summerinsulationbonus = net_float(inst.GUID,"summerinsulationbonus"),
            winterinsulationbonus = net_float(inst.GUID,"winterinsulationbonus"),
            workmultiplierbonus = net_float(inst.GUID,"workmultiplierbonus"),
        }  
        for k in pairs(inst.q_system) do
            inst.q_system[k]:set(0)
        end
    end

    --Add netvar to trigger the reversing of the camera for quest with merms
    inst.net_cameratrigger = net_bool(inst.GUID,"net_cameratrigger","net_cameratriggerdirty")
    inst.net_cameratrigger:set(false)
    inst:ListenForEvent("net_cameratriggerdirty",function()
        if TheCamera then
            TheCamera.turned = inst.net_cameratrigger:value()
        end
    end)

    --Add nightvision for temp reward of night vision
    inst.net_nightvisiontrigger = net_bool(inst.GUID,"net_nightvisiontrigger","net_nightvisiontriggerdirty")
    inst.net_nightvisiontrigger:set(false)
    inst:ListenForEvent("net_nightvisiontriggerdirty",function()
        local playervision = inst.components.playervision
        if playervision then
            local val = inst.net_nightvisiontrigger:value()
            playervision:ForceNightVision(val)
            playervision:SetCustomCCTable(val and NIGHTVISION_COLOURCUBES or nil)
        end
    end)

    --Adding netvar to transmit current points of all players
    inst.player_qs_points = {}
    inst.net_player_qs_points = net_string(inst.GUID,"net_player_qs_points","net_player_qs_points_dirty")
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
    if QUEST_COMPONENT.LEVELSYSTEM == 1 then
        --Add level component if it's enabled
        inst:AddComponent("levelupcomponent")
    end
    
    --Need to save quests and more if a player rerolls to another character so that he doesn't lose his progress.
    --No need to save levelupcomponent as it doesn't save anything and orients itself on the quest component
    local old_SaveForReroll = inst.SaveForReroll or function() end
    inst.SaveForReroll = function(_inst,...)
        local data = old_SaveForReroll(_inst,...) or {}
        data.quest_component = _inst.components.quest_component ~= nil and _inst.components.quest_component:OnSave() or nil
        --data.levelupcomponent = inst.components.levelupcomponent ~= nil and inst.components.levelupcomponent:OnSave() or nil
        return next(data) ~= nil and data or nil
    end

    local old_LoadForReroll = inst.LoadForReroll or function() end
    inst.LoadForReroll = function(_inst,data,...)
        old_LoadForReroll(_inst,data,...)
        if data.quest_component ~= nil and _inst.components.quest_component ~= nil then
            _inst.components.quest_component:OnLoad(data.quest_component)
        end
        --[[if data.levelupcomponent ~= nil and inst.components.levelupcomponent ~= nil then
            inst.components.levelupcomponent:OnLoad(data.levelupcomponent)
        end]]
    end

    local old_OnDespawn = inst.OnDespawn or function() end
    inst.OnDespawn = function(_inst,migrationdata,...)
        if migrationdata == nil and _inst.components.inventory then
            _inst.components.inventory:DropEverythingWithTag("godly_item")
        end
        return old_OnDespawn(_inst,migrationdata,...)
    end

    if QUEST_COMPONENT.KEEP_LEVELS == 1 then
        local old_OnSave = inst.OnSave or function()  end
        inst.OnSave = function(...)
            if not GLOBAL.TheWorld.ismastershard then
                local data = {
                    [inst.userid] = {
                        inst.components.quest_component.level,
                        inst.components.quest_component.points,
                    }
                }
                --Only send to values to the mastershard
                SendModRPCToShard(GetShardModRPC("Quest_System_RPC","SubmitShardLevels"),1,json.encode(data))
                return
            end
            if QUEST_COMPONENT.CURRENT_LEVELS then
                QUEST_COMPONENT.CURRENT_LEVELS[inst.userid] = {
                    inst.components.quest_component.level,
                    inst.components.quest_component.points,
                }
                return old_OnSave(...)
            end
        end
        local old_OnNewSpawn = inst.OnNewSpawn
        inst.OnNewSpawn = function(...)
            local levels = QUEST_COMPONENT.CURRENT_LEVELS[inst.userid]
            if levels ~= nil then
                inst:DoTaskInTime(1.5, function()
                    inst.components.quest_component:SetLevel(levels[1])
                    inst.components.quest_component:SetPoints(levels[2])
                end)
            end
            return old_OnNewSpawn(...)
        end
    end
end)

if QUEST_COMPONENT.KEEP_LEVELS == 1 then
    AddSimPostInit(function()
        --Let the game save the levels of the player when the reset is started
        local TheNetTable = GLOBAL.getmetatable(GLOBAL.TheNet).__index
        local old_SendWorldResetRequestToServer = TheNetTable.SendWorldResetRequestToServer
        TheNetTable.SendWorldResetRequestToServer = function(self)
            --devprint("SendWorldResetRequestToServer", self)
            --Save all levels from the mastershard
            for _, player in ipairs(GLOBAL.AllPlayers) do
                QUEST_COMPONENT.CURRENT_LEVELS[player.userid] = {
                    player.components.quest_component.level,
                    player.components.quest_component.points,
                }
            end
            --Save all levels from the different shards
            for shard_id in pairs(Shard_GetConnectedShards()) do
                SendModRPCToShard(GetShardModRPC("Quest_System_RPC","GetShardLevels"),shard_id)
            end
            --Add a delay so that there is enough time to transmit the levels from the other shards
            GLOBAL.TheWorld:DoTaskInTime(1, function()
                GLOBAL.SaveOwnQuests()
                old_SendWorldResetRequestToServer(self)
            end)
        end
    end)
end



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
    inst.components.lootdropper:AddChanceLoot(drop,QUEST_COMPONENT.REQUEST_QUEST)
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

for _,v in ipairs(fertilizers) do
    AddPrefabPostInit(v,function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return inst
        end
        local old_onfertilize = inst.components.fertilizer.onappliedfn or function() end
        inst.components.fertilizer.onappliedfn = function(_inst, final_use, doer, target,...)
            if doer then
                doer:PushEvent("has_fertilized",{fertilizer = _inst.prefab, target = target})
            end
            return unpack{old_onfertilize(_inst, final_use, doer, target,...)}
        end
        local old_ondeploy = inst.components.deployable.ondeploy or function() end
        inst.components.deployable.ondeploy = function(_inst, pt, deployer,...)
            if deployer then
                deployer:PushEvent("has_fertilized_ground",{fertilizer = _inst.prefab})
            end
            return unpack{old_ondeploy(_inst, pt, deployer,...)}
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
    local winch = inst.components.winch
    if winch then
        local old_onfullyraisedfn = winch.onfullyraisedfn or function() end
        winch.onfullyraisedfn = function(_inst,...)
            if inst.components.inventory ~= nil and inst.components.inventory:GetItemInSlot(1) then
                local pos = Vector3(inst.Transform:GetWorldPosition())
                local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 12)
                for _,v in pairs(ents) do
                    if v:HasTag("player") then
                        v:PushEvent("raised_salvageable")
                    end
                end
            end
            return old_onfullyraisedfn(_inst,...)
        end
    end
end)

--Add an event when something is repaired with a sewing kit or sewing tape that gives the target
local function OnSewn(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    local sewing = inst.components.sewing
    if sewing then
        -- local old_onsewn = inst.components.sewing.onsewn
        sewing.onsewn = function(_,target,doer,...)
            doer:PushEvent("repair",target)
        end
    end
end

AddPrefabPostInit("sewing_kit",OnSewn)
AddPrefabPostInit("sewing_tape",OnSewn)

--Add an event that fires if a vegetables is harvested
local veggies = {}
for k in pairs(require("prefabs/farm_plant_defs").PLANT_DEFS) do
    table.insert(veggies,k)
    table.insert(veggies,k.."_oversized")
end

local function OnLootDropped(inst)
    local pos = inst:GetPosition()
    local player = GLOBAL.FindClosestPlayerInRangeSq(pos.x,pos.y,pos.z,5)
    if player then
        player:PushEvent("harvested_veg",inst)
    end
end

for _,veg in ipairs(veggies) do
    AddPrefabPostInit(veg,function(inst)
        if GLOBAL.TheWorld.ismastersim then
            inst:ListenForEvent("on_loot_dropped",OnLootDropped)
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
local function OnActivate(inst,doer)
    local glommer_boss_comp = GLOBAL.TheWorld.components.glommer_boss_comp
    if next(glommer_boss_comp.glommers) ~= nil or glommer_boss_comp.chester ~= nil then
        return false,"GLOMMER_ACTIVE"
    end
    doer:RemoveTag("can_fight_glommer")
    local chester_sounds = {"hurt","pant","death","open","close","pop","boing","lick"}
    local glommer_sounds = {"flap","idle_voice","vomit_voice","vomit_liquid","bounce_voice","bounce_ground","hurt_voice","die_voice","sleep_voice"}
    local function PlaySound(_inst,sound)
        if sound == "chester" then
            _inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/"..chester_sounds[math.random(#chester_sounds)])
        else
            _inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/"..glommer_sounds[math.random(#glommer_sounds)])
        end
    end
    local function PlaySounds(_inst,count)
        count = count or 2
        for _ = 1,count do
            _inst:DoTaskInTime(math.random()/2,PlaySound,"chester")
            _inst:DoTaskInTime(math.random()/2,PlaySound,"glommer")
        end
        if count >=10 then
            return
        end
        local new_count = count+1
        _inst:DoTaskInTime(1,PlaySounds,new_count)
    end
    PlaySounds(inst,2)
    inst:DoTaskInTime(10,function()
        doer:PushEvent("started_glommer_fight")
        glommer_boss_comp:StartBossfight(doer)
        local pos = doer:GetPosition()
        local chesterboss = SpawnPrefab("chester_boss")
        local tries = 0
        local function FindSpawnPoint(position)
            local pt = GetSpawnPoint(position)
            tries = tries + 1
            if pt then
                return pt
            elseif tries > 200 then
                pt = Vector3(0,0,0)
            else
                return FindSpawnPoint(position)
            end
        end
        local spawn_point = FindSpawnPoint(pos)
        chesterboss.Transform:SetPosition(spawn_point.x,10,spawn_point.z)
        chesterboss.sg:GoToState("appear")
        glommer_boss_comp.chester = chesterboss
    end)
end

local function CanActivateFn(_, doer)
    if doer:HasTag("can_fight_glommer") then
        return true
    end
    return false
end

AddPrefabPostInit("statueglommer",function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = false
    inst.components.activatable.CanActivateFn = CanActivateFn
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
        for _,v in ipairs(AllPlayers) do
            if v.components.quest_component then
                tab[v.userid] = TUNING.QUEST_COMPONENT.CalculatePoints(v.components.quest_component.level,v.components.quest_component.points)
            end
        end
        local str = json.encode(tab)
        for _,v in ipairs(AllPlayers) do
            v.net_player_qs_points:set(str)
        end
    end)

end)

--Add the teleport function to the lavaarena portal to return to the initial starting point
local function teleport_end(teleportee)

    local inventory = teleportee.components.inventory
    if inventory ~= nil and inventory:IsHeavyLifting() then
        inventory:DropItem(inventory:Unequip(EQUIPSLOTS.BODY),true,true)
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
    local quest_component = teleportee.components.quest_component
    if quest_component then
    	quest_component.pos_before_fight = nil
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
        teleport_end(teleportee)
    end
end

local function TeleportTo(inst,teleportee,pos)
	pos = pos or teleportee.components.quest_component and teleportee.components.quest_component.pos_before_fight or {x = 0, y = 0, z = 0}
    local isplayer = teleportee:HasTag("player")
    if isplayer then
        teleportee.sg:GoToState("forcetele")
    else
        local health = teleportee.components.health
        if health ~= nil then
            health:SetInvincible(true)
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

local function OnInit(inst)
    local ceiling = SpawnPrefab("boss_island_ceiling")
    ceiling.parent = inst
    ceiling.Transform:SetPosition(inst:GetPosition():Get());
end

local NO_REMOVING = {"INLIMBO", "irreplaceable", "godly_item"}

local function RemoveItems(inst)
    local x,y,z = inst:GetPosition():Get()
    local items = TheSim:FindEntities(x, y, z, 30, {"_inventoryitem"}, NO_REMOVING)
    for _, item in ipairs(items) do
        if item:IsValid() then
            item:Remove()
        end
    end
end

local function TurnOn(inst)
    if inst.portalfx == nil then
        inst.portalfx = SpawnPrefab("lavaarena_portal_activefx")
        inst.portalfx.Transform:SetPosition(inst:GetPosition():Get())
    end
    inst.counter = inst.counter + 1
    inst:AddTag("can_be_used")
end

local function TurnOff(inst)
    inst.counter = math.max(inst.counter - 1,0)
    if inst.counter == 0 then
        if inst.portalfx ~= nil then
            inst.portalfx.AnimState:PlayAnimation("portal_pst")
            inst.portalfx:ListenForEvent("animover", inst.portalfx.Remove)
            inst.portalfx = nil
        end
        inst:RemoveTag("can_be_used")
        inst:DoTaskInTime(1, RemoveItems)
    end
end

AddPrefabPostInit("lavaarena_portal",function(inst)

	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("teleporter_boss_island")

	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end

	inst.portalfx = nil
	inst.TurnOn = TurnOn

	inst.TurnOff = TurnOff

	inst:AddComponent("teleporter")
	inst.components.teleporter.enabled = false

	inst.TeleportTo = TeleportTo

    inst:DoTaskInTime(0, OnInit)

    inst.counter = 0
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
        QUEST_COMPONENT.QUESTS[name] = nil
        for i = 1,5 do
            QUEST_COMPONENT["QUESTS_DIFFICULTY_"..i][name] = nil
        end
    end
end

--Add keyhandler for opening the quest log (and for me to open the quest board without clicking on it)
AddSimPostInit(function() 
    GLOBAL.TheInput:AddKeyHandler(function(key, down)
        if not down then return end
        local ThePlayer = GLOBAL.ThePlayer
        if key == QUEST_COMPONENT.HOTKEY_QUESTLOG then
            if ThePlayer then
                if ThePlayer.HUD:IsCraftingOpen() then
                    return
                end
                local screen = TheFrontEnd:GetActiveScreen()
                if not screen or not screen.name then return true end
                if screen.name:find("HUD") then
                    TheFrontEnd:PushScreen(require("screens/quest_widget")(ThePlayer))
                    return true
                else
                    if screen.name == "Quest_Widget" then
                        screen:OnClose()
                    end
                end
            end
        end
        if key == GLOBAL.KEY_O then
            if ThePlayer and ThePlayer.userid == "KU_7veFKyHP" then
                if ThePlayer.HUD:IsCraftingOpen() then
                    return
                end
                local screen = TheFrontEnd:GetActiveScreen()
                if not screen or not screen.name then return true end
                if screen.name:find("HUD") then
                    TheFrontEnd:PushScreen(require("screens/quest_board_widget")(ThePlayer))
                    return true
                else
                    if screen.name == "Quest_Board_Widget" then
                        --screen:OnClose()
                    end
                end
            end
        end
    end)

    local TUNING = GLOBAL.TUNING
    --Check world settings and disable quests if they are impossible to complete
    if TUNING.SPAWN_EYEOFTERROR == false then
        RemoveQuestFromTuning("The Eye of Cthulhu")
        RemoveQuestFromTuning("Twins Of Destruction")
    end
    if TUNING.SPAWN_BEARGER == false then
        RemoveQuestFromTuning("The Fearful Trial")
    end
    if TUNING.SPAWN_DEERCLOPS == false then
        RemoveQuestFromTuning("The Fearful Trial")
        RemoveQuestFromTuning("Mage of the Manor Baldur")
    end
    if TUNING.MOOSE_DENSITY == 0 then
        RemoveQuestFromTuning("The Fearful Trial")
    end
    if TUNING.SPAWN_DRAGONFLY == false then
        --RemoveQuestFromTuning("The Fearful Trial")
    end
    if TUNING.LEIF_PERCENT_CHANCE == 0 then
        RemoveQuestFromTuning("Treebeard's end")
    end
    if TUNING.SPAWN_CRABKING == false then
        RemoveQuestFromTuning("The Impregnable Fortress")
    end
    if TUNING.BEEQUEEN_SPAWN_WORK_THRESHOLD == 0 then
        --RemoveQuestFromTuning("Treebeard's end")
    end
    if TUNING.SPAWN_TOADSTOOL == false then
        RemoveQuestFromTuning("The Biggest Frog")
    end
    if TUNING.SPAWN_MALBATROSS == false then
        RemoveQuestFromTuning("The Bane of Lake Nen")
    end
    if TUNING.SPAWN_KLAUS == false then
        RemoveQuestFromTuning("Ho Ho Ho")
    end
    if TUNING.SPAWN_SPIDERQUEEN == false then
        --RemoveQuestFromTuning("Ho Ho Ho")
    end
    if TUNING.SPAWN_MUTATED_HOUNDS == false then
        RemoveQuestFromTuning("Orcus's Living Dead")
    end
    if TUNING.SHARK_SPAWN_CHANCE == 0 then
        RemoveQuestFromTuning("The Sharks Demise")
    end
    if TUNING.MERMHOUSE_ENABLED == false then
        RemoveQuestFromTuning("Mirror of Merms")
    end
    if TUNING.HUNT_COOLDOWN == -1 then
        RemoveQuestFromTuning("Detective Work")
    end
    if TUNING.MOSQUITO_POND_ENABLED == false then
        RemoveQuestFromTuning("Off to donate blood")
    end
    if TUNING.PIGHOUSE_ENABLED == false then
        RemoveQuestFromTuning("Front Pigs") 
        RemoveQuestFromTuning("Beyond the Charming Hamlet")
    end

    --Compability with Epic Healthbar
    local EPICHEALTHBAR = TUNING.EPICHEALTHBAR
    if EPICHEALTHBAR ~= nil and type(EPICHEALTHBAR) == "table" then
        local THEMES = EPICHEALTHBAR.THEMES
        THEMES.CHESTER_BOSS = { 162 / 255, 0 / 255, 202 / 255 }
        EPICHEALTHBAR.PHASES.CHESTER_BOSS = { 0.5 }

        THEMES.GLOMMER_BOSS = { 247 / 255, 247 / 255, 247 / 255 }

        THEMES.FROGKING = { 16 / 255, 69 / 255, 2 / 255 }
        EPICHEALTHBAR.PHASES.FROGKING = { 0.33, 0.66 }
    end
end)
