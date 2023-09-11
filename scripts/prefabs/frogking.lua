
local assets =
{
    Asset("ANIM", "anim/frogking.zip"),
    Asset("ANIM", "anim/frogking_anim.zip"),
}


local prefabs =
{
    "frogking_beyblade",
    "frogking_crown",
    "frogking_p_crown",

    --loot
    "froglegs",
    "meat",
    "frogking_scepter",
    "frogking_p_crown",
}


SetSharedLootTable('frogking',
{
    {"froglegs",      1.00},
    {"meat",          1.00},
    {"meat",          1.00},
    {"meat",          1.00},
    {"meat",          0.50},
    {"meat",          0.25},

    {"shroom_skin",   1.00},
    {"frogking_p_crown", 1.00},
    {"frogking_scepter", 1.00},

})


--------------------------------------------------------------------------

local brain = require("brains/frogkingbrain")

--------------------------------------------------------------------------

local FADE_FRAMES = 20
local FADE_INTENSITY = .75
local FADE_RADIUS = 2
local FADE_FALLOFF = .5

local function OnUpdateFade(inst)
    local k
    if inst._fade:value() <= FADE_FRAMES then
        inst._fade:set_local(math.min(inst._fade:value() + 1, FADE_FRAMES))
        k = inst._fade:value() / FADE_FRAMES
    else
        inst._fade:set_local(math.min(inst._fade:value() + 1, FADE_FRAMES * 2 + 1))
        k = (FADE_FRAMES * 2 + 1 - inst._fade:value()) / FADE_FRAMES
    end

    inst.Light:SetIntensity(FADE_INTENSITY * k)
    inst.Light:SetRadius(FADE_RADIUS * k)
    inst.Light:SetFalloff(1 - (1 - FADE_FALLOFF) * k)

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._fade:value() > 0 and inst._fade:value() <= FADE_FRAMES * 2)
    end

    if inst._fade:value() == FADE_FRAMES or inst._fade:value() > FADE_FRAMES * 2 then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
end

local function OnFadeDirty(inst)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
    OnUpdateFade(inst)
end

local function FadeOut(inst)
    inst._fade:set(FADE_FRAMES + 1)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
end

local function CancelFade(inst)
    inst._fade:set(FADE_FRAMES)
    OnFadeDirty(inst)
end


--------------------------------------------------------------------------

local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local pos = inst.components.knownlocations:GetLocation("spawnpoint")

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(pos.x, pos.y, pos.z, TUNING.TOADSTOOL_DEAGGRO_DIST, true)) do
        if toremove[v] then
            toremove[v] = nil
        else
            table.insert(toadd, v)
        end
    end

    for k, v in pairs(toremove) do
        inst.components.grouptargeter:RemoveTarget(k)
    end
    for i, v in ipairs(toadd) do
        inst.components.grouptargeter:AddTarget(v)
    end
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "prey", "companion"--[[, "smallcreature" <- the beeees... - _-" ]] }
local function RetargetFn(inst)
    UpdatePlayerTargets(inst)

    local player = inst.components.combat.target
    if player ~= nil and player:HasTag("player") then
        local newplayer = inst.components.grouptargeter:TryGetNewTarget()
        if newplayer ~= nil and newplayer:IsNear(inst, TUNING.TOADSTOOL_ATTACK_RANGE) then
            return newplayer, true
        elseif player:IsNear(inst, TUNING.TOADSTOOL_ATTACK_RANGE) then
            return
        elseif newplayer ~= nil then
            player = newplayer
        end
    else
        player = nil
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local nearplayers = FindPlayersInRange(x, y, z, TUNING.TOADSTOOL_ATTACK_RANGE, true)
    if #nearplayers > 0 then
        return nearplayers[math.random(#nearplayers)], true
    end

    --Also needs to deal with other creatures in the world
    local spawnpoint = inst.components.knownlocations:GetLocation("spawnpoint")
    local deaggro_dist_sq = TUNING.TOADSTOOL_DEAGGRO_DIST * TUNING.TOADSTOOL_DEAGGRO_DIST
    local creature = FindEntity(
        inst,
        TUNING.TOADSTOOL_AGGRO_DIST,
        function(guy)
            return inst.components.combat:CanTarget(guy)
                and guy:GetDistanceSqToPoint(spawnpoint) < deaggro_dist_sq
        end,
        RETARGET_MUST_TAGS, --see entityreplica.lua
        RETARGET_CANT_TAGS
    )

    if player ~= nil and
        (   creature == nil or
            player:GetDistanceSqToPoint(x, y, z) <= creature:GetDistanceSqToPoint(x, y, z)
        ) then
        return player, true
    end

    if creature ~= nil then
        return creature, true
    end
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
        and target:GetDistanceSqToPoint(inst.components.knownlocations:GetLocation("spawnpoint")) < TUNING.TOADSTOOL_DEAGGRO_DIST * TUNING.TOADSTOOL_DEAGGRO_DIST
end

local function OnNewTarget(inst, data)
    if data.target ~= nil then
        inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        inst.engaged = true

        --Ability first use timers
        --inst.components.timer:StartTimer("sporebomb_cd", TUNING.TOADSTOOL_ABILITY_INTRO_CD)
        --inst.components.timer:StartTimer("mushroombomb_cd", inst.mushroombomb_cd)
        --inst.components.timer:StartTimer("mushroomsprout_cd", inst.mushroomsprout_cd)
        inst.components.timer:StartTimer("pound_cd", TUNING.TOADSTOOL_ABILITY_INTRO_CD, true)
    end
end

local function OnNewState(inst)
    if inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("thawing") then
        inst.components.timer:PauseTimer("mushroomsprout_cd")
    else
        inst.components.timer:ResumeTimer("mushroomsprout_cd")
    end
end

local function ClearRecentAttacker(inst, attacker)
    if inst._recentattackers[attacker] ~= nil then
        inst._recentattackers[attacker]:Cancel()
        inst._recentattackers[attacker] = nil
    end
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil and data.attacker:HasTag("player") then
        if inst._recentattackers[data.attacker] ~= nil then
            inst._recentattackers[data.attacker]:Cancel()
        end
        inst._recentattackers[data.attacker] = inst:DoTaskInTime(120, ClearRecentAttacker, data.attacker)
    end
end

--------------------------------------------------------------------------

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function EnterPhase2Trigger(inst)
    inst.level = 2
end

local function EnterPhase3Trigger(inst)
    inst.level = 3
end

--------------------------------------------------------------------------

local function OnSave(inst, data)
    data.engaged = inst.engaged or nil
end

local function OnLoad(inst, data)

    if data ~= nil then
        if data.engaged then
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
            inst.engaged = true
        end
    end
    local healthpct = inst.components.health:GetPercent()
    inst.level =   (healthpct > 0.66 and 1)
                or (healthpct > 0.33 and 2)
                or 3
end

--------------------------------------------------------------------------

local function ClearRecentlyCharged(inst, other)
    inst.recentlycharged[other] = nil
end

local function OnDestroyOther(inst, other)
    if other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        if other.components.lootdropper ~= nil and (other:HasTag("tree") or other:HasTag("boulder")) then
            other.components.lootdropper:SetLoot({})
        end
        other.components.workable:Destroy(inst)
        if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
            inst.recentlycharged[other] = true
            inst:DoTaskInTime(3, ClearRecentlyCharged, other)
        end
    end
end

local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET and
        not inst.recentlycharged[other] then
        inst:DoTaskInTime(2 * FRAMES, OnDestroyOther, other)
    end
end

--------------------------------------------------------------------------


local function PushMusic(inst)
    if ThePlayer == nil then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 30 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", { name = "toadstool" })
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 40) then
        inst._playingmusic = false
    end
end

--------------------------------------------------------------------------

local function common_fn(build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    inst.DynamicShadow:SetSize(6, 3.5)

    inst.Light:SetRadius(FADE_RADIUS)
    inst.Light:SetFalloff(FADE_FALLOFF)
    inst.Light:SetIntensity(FADE_INTENSITY)
    inst.Light:SetColour(255 / 255, 235 / 255, 153 / 255)
    inst.Light:EnableClientModulation(true)

    MakeGiantCharacterPhysics(inst, 1000, 2.5)

    inst.AnimState:SetBank("frogking")
    inst.AnimState:SetBuild("frogking")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetLightOverride(.3)

    inst:AddTag("epic")
    inst:AddTag("noepicmusic")
    inst:AddTag("monster")
    inst:AddTag("frogking")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    inst._fade = net_smallbyte(inst.GUID, "toadstool._fade", "fadedirty")

    inst.entity:SetPristine()

    --Dedicated server does not need to trigger music
    if not TheNet:IsDedicated() then
        inst._playingmusic = false
        inst:DoPeriodicTask(1, PushMusic, 0)
    end

    if not TheWorld.ismastersim then
        inst:ListenForEvent("fadedirty", OnFadeDirty)

        return inst
    end

    inst.recentlycharged = {}
    inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper.diminishingreturns = true

    inst:AddComponent("locomotor")
    inst.components.locomotor.pathcaps = { ignorewalls = true }
    inst.components.locomotor.walkspeed = 3

    inst:AddComponent("health")
    inst.components.health.nofadeout = true

    inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(0.66, EnterPhase2Trigger)
    inst.components.healthtrigger:AddTrigger(0.33, EnterPhase3Trigger)

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(2.5)
    inst.components.combat.playerdamagepercent = .75
    inst.components.combat:SetRange(4.5)
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.battlecryenabled = false
    inst.components.combat.hiteffectsymbol = "toad_torso"

    inst:AddComponent("explosiveresist")

    inst:AddComponent("sanityaura")

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.TOADSTOOL_EPICSCARE_RANGE)

    inst:AddComponent("timer")
    if not inst.components.timer:TimerExists("beyblade_cd") then
        inst.components.timer:StartTimer("beyblade_cd",20)
    end
    if not inst.components.timer:TimerExists("crowning_cd") then
        inst.components.timer:StartTimer("crowning_cd",35)
    end

    inst:AddComponent("grouptargeter")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.platformPushingRings = 0
    inst.components.groundpounder.groundpounddamagemult = 0.25

    inst:AddComponent("knownlocations")

    MakeLargeBurnableCharacter(inst, "swap_fire")
    MakeHugeFreezableCharacter(inst, "toad_torso")
    inst.components.freezable.diminishingreturns = true

    inst:SetStateGraph("SGfrogking")
    inst:SetBrain(brain)

    inst.pound_cd = TUNING.TOADSTOOL_POUND_CD
    inst.pound_speed = 0
    inst.pound_rnd = false

    inst.hit_recovery = 1.5

    inst.level = 1

    inst._recentattackers = {}
    inst.engaged = false

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("newstate", OnNewState)
    inst:ListenForEvent("attacked", OnAttacked)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.FadeOut = FadeOut
    inst.CancelFade = CancelFade

    return inst
end

local function normal_fn()
    local inst = common_fn("frogking")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.health:SetMaxHealth(30000)
    inst.components.health:SetAbsorptionAmount(0.2)

    inst.components.combat:SetDefaultDamage(250)

    inst.components.lootdropper:SetChanceLootTable("frogking")

    return inst
end

----------------------------------------------------------------------------------------------------------------

--Frogking's Beyblades (or spinning diamonds)

local assets_beyblade =
{
    Asset("ANIM", "anim/frogking_beyblade.zip"),
}


local prefabs_beyblade =
{
    "impact",
}

local function onthrown(inst, data)
    --inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
end



local function OnHitBeyblade(inst,target)
    local cooldown = target and target.beyblade_cooldown or nil
    if target == nil or cooldown ~= nil or target.prefab == "frogking" then
        return
    end
    local impactfx = SpawnPrefab("impact")
    if impactfx ~= nil and target.components.combat then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        if inst ~= nil and inst:IsValid() then
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end
    end
    if target.components.health then
        target.components.health:DoDelta(-5)
    end
    if cooldown ~= nil then
        cooldown:Cancel()
        cooldown = nil
    end
    cooldown = inst:DoTaskInTime(0.5,function()
        if cooldown ~= nil then
            cooldown:Cancel()
            cooldown = nil
        end
    end)
    if target:HasTag("imprisoned") then
        return
    end
    --Launch the hit object
    if target.sg and target:HasTag("player") then
        target.sg:GoToState("knockback",{radius = 2,knocker = inst})
    elseif target.components.inventoryitem then
        Launch2(target,inst,10,2,0.1,0,15)
    elseif target.components.locomotor then
        Launch2(target,inst,200,2,0.1,0,15)
    end
end

local function onhit(inst, attacker, target)
    OnHitBeyblade(attacker,target)
end

local function OnCollideBeyblade(inst, collider)
    --devprint("OnCollideBeyblade",inst,collider)
    OnHitBeyblade(inst,collider)
end

local function Homing(inst)
    if inst:HasTag("activeprojectile") then
        return 
    end
    local pos = inst:GetPosition()
    local nearestplayer = FindClosestPlayerInRange(pos.x,pos.y,pos.z,20,true)
    devprint("Homing: ",nearestplayer)
    if nearestplayer then
        inst.components.projectile:Throw(inst,nearestplayer)
    end
end

local function beyblade()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    --MakeInventoryPhysics(inst)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(100)
    phys:SetFriction(1)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.SMALLOBSTACLES)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
    phys:SetCylinder(1, 1)
    phys:SetCollisionCallback(OnCollideBeyblade)

    inst.AnimState:SetBank("frogking_beyblade")
    inst.AnimState:SetBuild("frogking_beyblade")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("spin_loop",true)
    local scale = 0.4
    inst.AnimState:SetScale(scale,scale,scale)

    inst:AddTag("sharp")

    inst:AddTag("frogking_beyblade")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:AddComponent("locomotor")
    --inst.components.locomotor.walkspeed = 2

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(5)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(2)
    inst.components.projectile:SetOnHitFn(onhit)
    inst:ListenForEvent("onthrown", onthrown)
    -------

    inst:AddComponent("inspectable")

    inst:DoTaskInTime(15,function()
        inst.AnimState:PlayAnimation("disappear")
        inst:DoTaskInTime(0.5,inst.Remove)
    end)

    inst:DoTaskInTime(0,Homing)
    inst:DoPeriodicTask(3,Homing)

    MakeHauntableLaunch(inst)

    inst.persists = false

    return inst
end

-----------------------------------------------------------------------------------------------------------------------

local assets_crown =
{
    Asset("ANIM", "anim/frogking_beyblade.zip"),
}


local prefabs_crown =
{
    "impact",
}

local function Imprison(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x, y, z, 3, {"player"})
    for _,player in ipairs(players) do
        if player.components.playercontroller ~= nil then
            player.components.playercontroller:Enable(false)
            player:AddTag("imprisoned")
            player.DynamicShadow:Enable(false)
            player.AnimState:SetMultColour(0,0,0,0)
            player:DoTaskInTime(5,function()
                if player.components.playercontroller ~= nil then
                    player.components.playercontroller:Enable(true)
                    player.AnimState:SetMultColour(1,1,1,1)
                    player.DynamicShadow:Enable(true)
                    player:RemoveTag("imprisoned")
                end
            end)
        end
    end
end

local function crown()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    --MakeInventoryPhysics(inst)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(99999)
    phys:SetCollisionGroup(COLLISION.GIANTS)
    phys:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.WORLD)
    --phys:CollidesWith(COLLISION.GIANTS)
    phys:SetCylinder(3, 3)

    inst.AnimState:SetBank("frogking_crown")
    inst.AnimState:SetBuild("frogking_beyblade")
    inst.AnimState:PlayAnimation("fall")
    inst.AnimState:PushAnimation("idle",true)
    local scale = 1
    inst.AnimState:SetScale(scale,scale,scale)

    inst:SetPrefabNameOverride("frogking_p_crown")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    -------

    inst:AddComponent("inspectable")

    inst:DoTaskInTime(5,function()
        inst.AnimState:PlayAnimation("disappear")
        inst:DoTaskInTime(0.6,inst.Remove)
    end)

    inst:DoTaskInTime(0.5, Imprison)


    MakeHauntableLaunch(inst)

    inst.persists = false

    return inst
end

--------------------------------------------------------------------------------------------------------------------------------------


local SpawnFrogRainSingle = require("quest_util/frogking").SpawnFrogRainSingle

local assets_p_crown =
{ 
    Asset("ANIM", "anim/frogking_p_crown.zip"),   
}

local function OnSectionChange(newsection, oldsection, inst)
    if newsection <= 0 then
        inst.components.equippable.restrictedtag = "fuel is empty"
        local owner = inst.components.inventoryitem.owner
        if inst.components.equippable:IsEquipped() and owner then
            local slot = inst.components.equippable.equipslot
            local item = owner.components.inventory:Unequip(slot)
            owner.components.inventory:GiveItem(item)
        end
    end
end

local function OnTakeFuel(inst)
    if not inst.components.fueled:IsEmpty() then
        inst.components.equippable.restrictedtag = nil
    end
end


local function OnAttacked(inst,data)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude) return dude:HasTag("frog") and not dude.components.health:IsDead() end, 5)
end

local function OnEquip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_hat", "frogking_p_crown", "swap_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAT_HAIR")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    if owner:HasTag("player") then
        owner.AnimState:Hide("HEADBASE")
        owner.AnimState:Show("HEADBASE_HAT")
    end
    owner:AddTag("frog")
    owner:AddTag("merm")
    inst:ListenForEvent("attacked", OnAttacked, owner)
    inst.components.fueled:StartConsuming()
end

local function OnUnequip(inst, owner) 
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEADBASE")
        owner.AnimState:Hide("HEADBASE_HAT")
    end
    owner:RemoveTag("frog")
    owner:RemoveTag("merm")
    inst:RemoveEventCallback("attacked", OnAttacked, owner)
    inst.components.fueled:StopConsuming()
end
    
local function p_crown()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
        
    inst:AddTag("hat")
    
    inst.AnimState:SetBank("frogking_p_crown")
    inst.AnimState:SetBuild("frogking_p_crown")
    inst.AnimState:PlayAnimation("anim")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
           
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)   
    inst.components.equippable.insulated = true
    
    inst:AddComponent("inventoryitem")

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_MED_LARGE)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALLMED)

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(2000)
    inst.components.fueled:SetSectionCallback(OnSectionChange)  
    inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.FROGLEGS
    
    MakeHauntableLaunch(inst)
    
    return inst
end

local assets_scepter =
{
    Asset("ANIM", "anim/frogking_scepter.zip"),
}

local prefabs_scepter = 
{

}

local function SummonFrogRain(inst)
    local FrogRain, StopFrogRain = SpawnFrogRainSingle(inst,{1,0.09,0.09,1})    --42,3.4,3.4
    TheWorld:PushEvent("ms_forceprecipitation", true)
    FrogRain(inst)
    inst.components.fueled:DoDelta(-100)
    TheWorld:DoTaskInTime(60, function()
        StopFrogRain(inst)
        TheWorld:PushEvent("ms_forceprecipitation", false)
    end)
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "frogking_scepter", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end
  
local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnAttack(inst)
    inst.components.fueled:DoDelta(-1)
end

local function scepter()
  
    local inst = CreateEntity()
 
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
     
    MakeInventoryPhysics(inst)   
      
    inst.AnimState:SetBank("frogking_scepter")
    inst.AnimState:SetBuild("frogking_scepter")
    inst.AnimState:PlayAnimation("idle_loop")
    local scale = 0.7
    inst.AnimState:SetScale(scale,scale)

    inst:AddTag("tool")
    inst:AddTag("sharp")

    inst.entity:SetPristine()
 
    if not TheWorld.ismastersim then
        return inst
    end
     
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.HAMMER, 1.5)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(SummonFrogRain)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster.canuseonpoint_water = true
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(45)
    inst.components.weapon:SetOnAttack(OnAttack)

    local damagetypebonus = inst:AddComponent("damagetypebonus")
    damagetypebonus:AddBonus("insect", inst, 2)
      
    inst:AddComponent("inspectable")
      
    inst:AddComponent("inventoryitem")
          
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip( OnEquip )
    inst.components.equippable:SetOnUnequip( OnUnequip )

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(300)
    inst.components.fueled:SetSectionCallback(OnSectionChange)  
    inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.FROGLEGS
    inst.components.fueled.bonusmult = 0.25
             
    return inst
end

return  Prefab("frogking", normal_fn, assets, prefabs),
        Prefab("frogking_beyblade", beyblade, assets_beyblade, prefabs_beyblade),
        Prefab("frogking_crown", crown, assets_crown, prefabs_crown),
        Prefab("frogking_p_crown", p_crown, assets_p_crown),
        Prefab("frogking_scepter", scepter, assets_scepter, prefabs_scepter)
