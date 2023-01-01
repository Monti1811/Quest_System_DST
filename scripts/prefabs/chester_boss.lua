local assets =
{
    Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
    Asset("ANIM", "anim/ui_chest_3x3.zip"),

    Asset("ANIM", "anim/chester_boss.zip"),
    Asset("ANIM", "anim/nightmarechester.zip"),
    --Asset("ANIM", "anim/chester_build.zip"),
   -- Asset("ANIM", "anim/chester_shadow_build.zip"),
    --Asset("ANIM", "anim/chester_snow_build.zip"),

    Asset("SOUND", "sound/chester.fsb"),

    Asset("MINIMAP_IMAGE", "chester"),
    --Asset("MINIMAP_IMAGE", "chestershadow"),
    --Asset("MINIMAP_IMAGE", "chestersnow"),
}

local prefabs =
{
    "chester_eyebone",
    "chesterlight",
    "chester_transform_fx",
    "globalmapiconunderfog",
}

local sounds =
{
    hurt = "dontstarve/creatures/chester/hurt",
    pant = "dontstarve/creatures/chester/pant",
    death = "dontstarve/creatures/chester/death",
    open = "dontstarve/creatures/chester/open",
    close = "dontstarve/creatures/chester/close",
    pop = "dontstarve/creatures/chester/pop",
    boing = "dontstarve/creatures/chester/boing",
    lick = "dontstarve/creatures/chester/lick",
}

local brain = require "brains/chester_bossbrain"

local function OnHaunt(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        inst.components.hauntable.panic = true
        inst.components.hauntable.panictimer = TUNING.HAUNT_PANIC_TIME_SMALL
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local TARGET_DIST = 16

local RETARGET_MUST_TAGS = { "_combat","player" }
local RETARGET_CANT_TAGS = { "prey", "smallcreature", "INLIMBO" }
local function RetargetFn(inst)
    local range = inst:GetPhysicsRadius(0) + 16
    return FindEntity(
            inst,
            TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
                    and (   guy.components.combat:TargetIs(inst) or
                            guy:IsNear(inst, range)
                        )
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS
        )
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnHitOther(inst, data)
    local other = data.target
    if other ~= nil then
        if other.components.inventory then
            local overflow = other.components.inventory:GetOverflowContainer()
            local num_slots = (GetTableSize(other.components.inventory.itemslots) or 0) + (overflow and GetTableSize(overflow.slots) or 0)
            if num_slots > 0 then
                local num = math.random(num_slots)
                local count = 0
                local item = other.components.inventory:FindItem(function(item)
                    count = count + 1
                    if count == num then 
                        return true
                    end
                end)
                --print(overflow,num_slots,num,count,item)
                if item then
                    inst.components.inventory:GiveItem(other.components.inventory:RemoveItem(item,true))
                end
            end
        end
        if other.components.freezable ~= nil then
            other.components.freezable:SpawnShatterFX()
        end
    end
end

local function OnNewTarget(inst, data)
    if inst.components.knownlocations:GetLocation("targetbase") and data.target:HasTag("player") then
        inst.components.knownlocations:ForgetLocation("home")
    end
end

local function ontimerdone(inst, data)
    if data.name == "slamdown" then
        inst.canslamdown = true
    end
end

local function EquipWeapon(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local spitbomb = CreateEntity()
        spitbomb.name = "Spitbomb"
        --[[Non-networked entity]]
        spitbomb.entity:AddTransform()
        spitbomb:AddComponent("weapon")
        spitbomb.components.weapon:SetDamage(TUNING.SPAT_PHLEGM_DAMAGE)
        spitbomb.components.weapon:SetRange(TUNING.SPAT_PHLEGM_ATTACKRANGE)
        spitbomb.components.weapon:SetProjectile("spit_bomb")
        spitbomb:AddComponent("inventoryitem")
        spitbomb.persists = false
        spitbomb.components.inventoryitem:SetOnDroppedFn(spitbomb.Remove)
        spitbomb:AddComponent("equippable")
        spitbomb:AddTag("spitbomb")

        inst.components.inventory:GiveItem(spitbomb)
        inst.spitbomb = spitbomb
    end
end

local function OnHealthDelta(inst)
    local percent = inst.components.health:GetPercent()
    if percent < 0.5 then
        inst.mode2 = true
    else
        inst.mode2 = nil
    end
end

local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "meat", "meat",}

local function create_chester()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    local scale = 3
    inst.AnimState:SetScale(scale,scale,scale)

    MakeCharacterPhysics(inst, 225, 1.5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst:AddTag("scarytoprey")
    inst:AddTag("chester_boss")
    inst:AddTag("epic")

    inst.MiniMapEntity:SetIcon("chester.png")
    inst.MiniMapEntity:SetCanUseCache(false)

    inst.AnimState:SetBank("nightmarechester")
    inst.AnimState:SetBuild("nightmarechester")

    inst.DynamicShadow:SetSize(6, 4.5)

    inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------------------

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "chester_body"
    inst.components.combat:SetDefaultDamage(TUNING.DEERCLOPS_DAMAGE * 0.1)
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst,0.1,"chester_panzer")
    inst.components.combat.playerdamagepercent = TUNING.DEERCLOPS_DAMAGE_PLAYER_PERCENT
    inst.components.combat:SetRange(2)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst.canslamdown = false

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.numRings = 2
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.groundpoundfx = "greenfiresplash_fx" --ThePlayer.components.burnable.fxchildren[1].AnimState:SetMultColour(0,0,0,1) um feuer schwarz zu machen
    --inst.components.groundpounder.groundpounddamagemult = 0.5
    inst.components.groundpounder.groundpoundringfx = "firering_fx"
    inst.components.groundpounder.noTags = { "FX", "NOCLICK", "DECOR", "INLIMBO", "glommer_small", "glommer_boss", "chester_boss", }

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(666)
    inst.components.health:StartRegen(6.6, 10)
    inst.components.health.fire_damage_scale = 0 -- Take no damage from fire

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 7
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("explosiveresist")

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst:AddComponent("knownlocations")

    --MakeSmallBurnableCharacter(inst, "chester_body")

    inst:AddComponent("inventory")

    MakeHauntableDropFirstItem(inst)
    AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

    inst.sounds = sounds

    inst:SetStateGraph("SGchester_boss")
    inst.sg:GoToState("idle")

    inst:ListenForEvent("death",function(inst) 
        TheWorld:PushEvent("chesterboss_was_killed") 
        if TheWorld.components.quest_loadpostpass and TheWorld.components.quest_loadpostpass.nightmarechester < TUNING.QUEST_COMPONENT.MAX_AMOUNT_GODLY_ITEMS then
            TheWorld.components.quest_loadpostpass.nightmarechester = TheWorld.components.quest_loadpostpass.nightmarechester + 1
            inst.components.lootdropper:FlingItem(SpawnPrefab("nightmarechester_eyebone"))
        end
        if TheWorld.components.glommer_boss_comp and TheWorld.components.glommer_boss_comp.chester == inst then
            TheWorld.components.glommer_boss_comp.chester = nil
        end
    end)
    inst:ListenForEvent("healthdelta",OnHealthDelta)

    inst:SetBrain(brain)

    EquipWeapon(inst)

    return inst
end

--------------------------------------------------------------------------------------------------------------------------------

local containers = require "containers"

containers.params.nightmarechester = deepcopy(containers.params.shadowchester)

local assets2 =
{
    Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
    Asset("SOUND", "sound/chester.fsb"),
}

local prefabs2 =
{
    "chester_transform_fx",
    "globalmapiconunderfog",
}

local brain = require "brains/chesterbrain"

local WAKE_TO_FOLLOW_DISTANCE = 14
local SLEEP_NEAR_LEADER_DISTANCE = 7

local function ShouldWakeUp(inst)
    return DefaultWakeTest(inst) or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    --print(inst, "ShouldSleep", DefaultSleepTest(inst), not inst.sg:HasStateTag("open"), inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE))
    return DefaultSleepTest(inst) and not inst.sg:HasStateTag("open") and inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE) and not TheWorld.state.isfullmoon
end

local function ShouldKeepTarget()
    return false -- chester can't attack, and won't sleep if he has a target
end

local function OnOpen(inst)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("open")
    end
end

local function OnClose(inst)
    if not inst.components.health:IsDead() and inst.sg.currentstate.name ~= "transition" then
        inst.sg:GoToState("close")
    end
end

-- eye bone was killed/destroyed
local function OnStopFollowing(inst)
    --print("chester - OnStopFollowing")
    inst:RemoveTag("companion")
end

local function OnStartFollowing(inst)
    --print("chester - OnStartFollowing")
    inst:AddTag("companion")
end

local function OnHaunt(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        inst.components.hauntable.panic = true
        inst.components.hauntable.panictimer = TUNING.HAUNT_PANIC_TIME_SMALL
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function OnLoad(inst,data)
    if data then
        if data.can_do_pickup == nil then
            inst:RemoveTag("can_do_pickup")
        end
    end
end

local function OnSave(inst,data)
    if inst:HasTag("can_do_pickup") then
        data.can_do_pickup = true
    end
end

local function create_nightmarechester()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 75, .5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    inst:AddTag("companion")
    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddTag("nightmarechester")
    inst:AddTag("notraptrigger")
    inst:AddTag("noauradamage")
    inst:AddTag("fridge")
    inst:AddTag("can_do_pickup")

    inst.MiniMapEntity:SetIcon("chester.png")
    inst.MiniMapEntity:SetCanUseCache(false)

    inst.AnimState:SetBank("nightmarechester")
    inst.AnimState:SetBuild("nightmarechester")

    inst.DynamicShadow:SetSize(2, 1.5)

    inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------------------
    inst:AddComponent("maprevealable")
    inst.components.maprevealable:SetIconPrefab("globalmapiconunderfog")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "chester_body"
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(666)
    inst.components.health:StartRegen(TUNING.CHESTER_HEALTH_REGEN_AMOUNT, TUNING.CHESTER_HEALTH_REGEN_PERIOD)

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 7
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("follower")
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
    inst:ListenForEvent("startfollowing", OnStartFollowing)

    inst:AddComponent("knownlocations")

    MakeSmallBurnableCharacter(inst, "chester_body")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("nightmarechester")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    MakeHauntableDropFirstItem(inst)
    AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

    inst.sounds = sounds

    inst:SetStateGraph("SGchester")
    inst.sg:GoToState("idle")

    inst:SetBrain(brain)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end

--------------------------------------------------------------------------------------------------------------------------------

local assets3 =
{
    Asset("ANIM", "anim/nightmarechester_eyebone.zip"),
}

local SPAWN_DIST = 30

local function OpenEye(inst)
    if not inst.isOpenEye then
        inst.isOpenEye = true
        inst.components.inventoryitem.atlasname = "images/images_quest_system.xml"
        inst.components.inventoryitem.imagename = "nightmarechester_eyebone"
        inst.AnimState:PlayAnimation("idle_loop", true)
    end
end

local function CloseEye(inst)
    if inst.isOpenEye then
        inst.isOpenEye = nil
        inst.components.inventoryitem.atlasname = "images/images_quest_system.xml"
        inst.components.inventoryitem.imagename = "nightmarechester_eyebone_closed"
        inst.AnimState:PlayAnimation("dead", true)
    end
end

local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = SPAWN_DIST
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

local function StopRespawn(inst)
    if inst.respawntask ~= nil then
        inst.respawntask:Cancel()
        inst.respawntask = nil
        inst.respawntime = nil
    end
end

local function ReSpawnChester(inst)
    StopRespawn(inst)
    OpenEye(inst)
    local pos = GetSpawnPoint(Point(inst.Transform:GetWorldPosition()))
    if pos then
        local chester = inst.components.petleash:SpawnPetAt(pos:Get())
    end
end

local function StartRespawn(inst, time)
    StopRespawn(inst)
    time = time or 0
    inst.respawntask = inst:DoTaskInTime(time, ReSpawnChester)
    inst.respawntime = GetTime() + time
    CloseEye(inst)
end

local function FixChester(inst)
    if inst.components.petleash:GetNumPets() == 0 then
        CloseEye(inst)
        local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0
        StartRespawn(inst, time_remaining)
    end
end

local function OnPutInInventory(inst, player)
    inst.owner = player
end

local function OnSave(inst, data)
    if inst.respawntime ~= nil then
        local time = GetTime()
        if inst.respawntime > time then
            data.respawntimeremaining = inst.respawntime - time
        end
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end
    if data.respawntimeremaining ~= nil then
        inst.respawntime = data.respawntimeremaining + GetTime()
    else
        OpenEye(inst)
    end
end

local function GetStatus(inst)
    return inst.respawntask ~= nil and "WAITING" or nil
end

local function OnSpawnPet(inst, pet)
    if pet.components.spawnfader ~= nil then
        pet.components.spawnfader:FadeIn()
    end
    inst:ListenForEvent("death", function() inst.StartRespawn(inst, TUNING.CHESTER_RESPAWN_TIME) end, pet)
end

local function OnDespawnPet(inst, pet)
    pet:Remove()
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("chester_eyebone.png")

    MakeInventoryPhysics(inst)

    inst:AddTag("nightmarechester_eyebone")
    inst:AddTag("godly_item")

    inst.AnimState:SetBank("eyebone")
    inst.AnimState:SetBuild("nightmarechester_eyebone")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.openEye = "chester_eyebone"
    inst.closedEye = "chester_eyebone_closed"
    inst.isOpenEye = nil


    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(false)
    inst.components.inventoryitem.keepondeath = true

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable:RecordViews()
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst:AddComponent("leader")
    inst:AddComponent("petleash")
    inst.components.petleash:SetPetPrefab("nightmarechester")
    inst.components.petleash:SetMaxPets(1)
    inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
    inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

    MakeHauntableLaunch(inst)

    inst.StartRespawn = StartRespawn

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    inst.fixtask = inst:DoTaskInTime(1, FixChester)

    return inst
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------

local projectile_assets =
{
    Asset("ANIM", "anim/warg_gingerbread_bomb.zip"),
    Asset("ANIM", "anim/purple_goo.zip"),
}

local projectile_prefabs =
{
    "nightmarechester_splat_fx",
    "nightmarechester_splash_fx_full",
    "nightmarechester_splash_fx_med",
    "nightmarechester_splash_fx_low",
    "nightmarechester_splash_fx_melted",
}

local splashfxlist =
{
    "nightmarechester_splash_fx_full",
    "nightmarechester_splash_fx_med",
    "nightmarechester_splash_fx_low",
    "nightmarechester_splash_fx_melted",
}


local function doprojectilehit(inst, attacker, other)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spat/spit_hit")
    local x, y, z = inst.Transform:GetWorldPosition()
    local splat = SpawnPrefab("nightmarechester_splat_fx")
    splat.Transform:SetPosition(x, 0, z)

    if attacker ~= nil and not attacker:IsValid() then
        attacker = nil
    end

    -- stick whatever got actually hit by the projectile
    -- otherwise stick our target, if he was in splash radius
    if other == nil and attacker ~= nil then
        other = attacker.components.combat.target
        if other ~= nil and not (other:IsValid() and other:IsNear(inst, 3)) then
            other = nil
        end
    end

    if other ~= nil and other:IsValid() then
        if attacker ~= nil then
            attacker.components.combat:DoAttack(other, inst.components.complexprojectile.owningweapon, inst)
        end
        if other.components.pinnable ~= nil then
            other.components.pinnable:Stick("purple_goo",splashfxlist)
        end
    end

    return other
end

local function OnProjectileHit(inst, attacker, other)
    doprojectilehit(inst, attacker, other)
    inst:Remove()
end

local function oncollide(inst, other)
    -- If there is a physics collision, try to do some damage to that thing.
    -- This is so you can't hide forever behind walls etc.

    local attacker = inst.components.complexprojectile.attacker
    if other ~= doprojectilehit(inst, attacker) and
        other ~= nil and
        other:IsValid() and
        other.components.combat ~= nil then
        if attacker ~= nil and attacker:IsValid() then
            attacker.components.combat:DoAttack(other, inst.components.complexprojectile.owningweapon, inst)
        end
        if other.components.pinnable ~= nil then
            other.components.pinnable:Stick()
        end
    end

    inst:Remove()
end

local function projectilefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.Physics:SetMass(2)
    inst.Physics:SetFriction(15)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(0.02, 0.02)

    inst.AnimState:SetBank("spat_bomb")
    inst.AnimState:SetBuild("spat_bomb")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.AnimState:SetMultColour(122/255,122/255,122/255,1)
    inst.AnimState:SetAddColour(0/255,0/255,255/255,1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(oncollide)

    inst.persists = false

    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnProjectileHit)
    inst.components.complexprojectile:SetHorizontalSpeed(25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(3, 2, 0))
    inst.components.complexprojectile.usehigharc = false

    return inst
end


return  Prefab("chester_boss", create_chester, assets, prefabs),
        Prefab("nightmarechester", create_nightmarechester, assets2, prefabs2),
        Prefab("nightmarechester_eyebone", fn, assets3),
        Prefab("spit_bomb", projectilefn, projectile_assets, projectile_prefabs)
