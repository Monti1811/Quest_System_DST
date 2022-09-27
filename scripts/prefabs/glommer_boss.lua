local assets =
{
    Asset("ANIM", "anim/glommer_boss.zip"),
    Asset("ANIM", "anim/glommer.zip"),
    Asset("SOUND", "sound/glommer.fsb"),
}

local prefabs =
{
    "glommerfuel",
    "glommerwings",
    "monstermeat",
}

local brain = require("brains/glommer_bossbrain")



local TARGET_DIST = 16
local STRUCTURES_PER_HARASS = 5
local STRUCTURE_TAGS = {"structure"}

local function FindBaseToAttack(inst, target)
    local structure = GetClosestInstWithTag(STRUCTURE_TAGS, target, 40)
    if structure ~= nil then
        inst.components.knownlocations:RememberLocation("targetbase", structure:GetPosition())
        inst.AnimState:ClearOverrideSymbol("deerclops_head")
    end
end

local RETARGET_MUST_TAGS = { "_combat","player" }
local RETARGET_CANT_TAGS = { "prey", "smallcreature", "glommer_boss", "chester_boss", "INLIMBO" }

local NOT_VALID = {glommer_boss = true,glommer_small = true,chester_boss = true,chester = true,glommer = true}
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
    if data.attacker ~= nil and data.attacker:HasTag("player") and inst.components.knownlocations:GetLocation("targetbase") == nil and not inst.is_small_glommer then
        FindBaseToAttack(inst, data.attacker)
    end
end

local function OnHitOther(inst, data)
    local other = data.target
    if other ~= nil and not inst.is_small_glommer and other.prefab and not NOT_VALID[other.prefab] then
        if not (other.components.health ~= nil and other.components.health:IsDead()) then
            if other.components.freezable ~= nil then
                other.components.freezable:AddColdness(2)
            end
            if other.components.temperature ~= nil then
                local mintemp = math.max(other.components.temperature.mintemp, 0)
                local curtemp = other.components.temperature:GetCurrent()
                if mintemp < curtemp then
                    other.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
                end
            end
        end
        if other.components.freezable ~= nil then
            other.components.freezable:SpawnShatterFX()
        end
    end
end

local function OnNewTarget(inst, data)
    FindBaseToAttack(inst, data.target or inst)
    if inst.components.knownlocations:GetLocation("targetbase") and data.target:HasTag("player")  then
        inst.structuresDestroyed = inst.structuresDestroyed - 1
        inst.components.knownlocations:ForgetLocation("home")
    end
end

local function ontimerdone(inst, data)
    if data.name == "puke" then
        inst.canpuke = true
    end
end


local function OnDeath(inst)
    if TheWorld then
        if TheWorld.components.glommer_boss_comp then
            local pos = Point(inst.Transform:GetWorldPosition())
            if table.removetablevalue(TheWorld.components.glommer_boss_comp.glommers,inst) then
                TheWorld.components.glommer_boss_comp:OnDeath(inst,pos)
            end
        end
    end
end

local function CheckIfValidTarget(target)
    devprint("CheckIfValidTarget",target)
    if target and target.prefab and NOT_VALID[target.prefab] then
        devprint("not valid",target)
        return false
    end
    return true
end


local function fn(small)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, .75)
    inst.Transform:SetFourFaced()

    MakeGhostPhysics(inst, 1, .5)

    inst.MiniMapEntity:SetIcon("glommer.png")
    inst.MiniMapEntity:SetPriority(5)

    inst.AnimState:SetBank("glommer_boss")
    inst.AnimState:SetBuild("glommer_boss")
    inst.AnimState:PlayAnimation("idle_loop")

    inst:AddTag("glommer_boss")
    inst:AddTag("flying")
    inst:AddTag("hostile")
    inst:AddTag("largecreature")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("epic")

    MakeInventoryFloatable(inst, "med")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    local health = small and 33 or 666
    inst.components.health:SetMaxHealth(health)

    inst:AddComponent("combat")
    local damage = small and 10 or 100
    inst.components.combat:SetDefaultDamage(damage)
    inst.components.combat.playerdamagepercent = TUNING.DEERCLOPS_DAMAGE_PLAYER_PERCENT
    local range = small and 2 or 3
    inst.components.combat:SetRange(range)

    inst.components.combat:SetAttackPeriod(TUNING.DEERCLOPS_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:ListenForEvent("attacked", OnAttacked)
    

    inst:AddComponent("explosiveresist")

    inst:AddComponent("knownlocations")
    inst:AddComponent("lootdropper")
    
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.pathcaps = {allowocean = true}

    inst:SetBrain(brain)
    inst:SetStateGraph("SGglommer_boss")

    MakeMediumFreezableCharacter(inst, "glommer_body")


    MakeHauntablePanic(inst)

    return inst
end

local function fn_small()
    local inst = fn(true)
    inst.net_size = net_float(inst.GUID,"net_size","net_size_dirty")
    inst.net_size:set(0.5)
    inst:ListenForEvent("net_size_dirty",function(inst)
        local scale = inst.net_size:value() or 0.5
        inst.Transform:SetScale(scale,scale,scale)
    end)
    inst.is_small_glommer = true
    inst:AddTag("glommer_small")

    local scale = 0.5
    inst.Transform:SetScale(scale,scale,scale)

    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.lootdropper:SetLoot({"glommerfuel"})
    inst.components.combat.playerstunlock = PLAYERSTUNLOCK.NEVER

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremove", OnDeath)
    return inst
end

local function fn_big()
    local inst = fn()
    inst.AnimState:SetScale(2,2,2)

    inst:AddTag("epic")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.combat:SetAreaDamage(TUNING.DEERCLOPS_AOE_RANGE, TUNING.DEERCLOPS_AOE_SCALE)
    inst.components.combat.areahitcheck = CheckIfValidTarget
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst,0.1,"glommer_panzer")

    inst.components.lootdropper:SetLoot({"glommerfuel"})
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst.structuresDestroyed = 1
    inst:ListenForEvent("death",function(inst) 
        TheWorld:PushEvent("glommerboss_was_killed") 
        if TheWorld.components.quest_loadpostpass and TheWorld.components.quest_loadpostpass.glommerfuelmachine < TUNING.QUEST_COMPONENT.MAX_AMOUNT_GODLY_ITEMS then
            TheWorld.components.quest_loadpostpass.glommerfuelmachine = TheWorld.components.quest_loadpostpass.glommerfuelmachine + 1
            inst.components.lootdropper:FlingItem(SpawnPrefab("glommerfuelmachine_item"))
        end
    end)
    return inst
end

---------------------------------------------------------------------------------------------------------------------------

local assets3 =
{
    Asset("ANIM", "anim/blackglommerspit_gerat.zip"),
    Asset("ANIM", "anim/glommerfuelmachine_item.zip"),
}

local prefabs3 = 
{
    "collapse_small",
    "collapse_big",
    "ancient_altar_broken_ruinsrespawner_inst",
    "ancient_altar_ruinsrespawner_inst",
}

local function ondeploy(inst, pt, deployer)
    local turret = SpawnPrefab("glommerfuelmachine")
    if turret ~= nil then
        turret.Physics:SetCollides(false)
        turret.Physics:Teleport(pt.x, 0, pt.z)
        turret.Physics:SetCollides(true)
        turret:syncanim("place")
        turret:syncanimpush("working_nospin", true)
        turret.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")
        inst:Remove()
    end
end

local function syncanim(inst, animname, loop)
    inst.AnimState:PlayAnimation(animname, loop)
end

local function syncanimpush(inst, animname, loop)
    inst.AnimState:PushAnimation(animname, loop)
end

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    local scale = 0.4
    inst.Transform:SetScale(scale,scale,scale)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("glommerfuelmachine_item")
    inst.AnimState:SetBuild("glommerfuelmachine_item")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("eyeturret")
    inst:AddTag("godly_item")

    inst:SetPrefabNameOverride("glommerfuelmachine")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)

    MakeHauntableLaunch(inst)

    --Tag to make proper sound effects play on hit.
    inst:AddTag("largecreature")

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    --inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)

    return inst
end


local MAX_BLACKGLOMMERFUEL = 5

local function ForceNextSpawn(inst)
    inst.components.periodicspawner:ForceNextSpawn()
    inst.components.periodicspawner:Start()
    inst.AnimState:PushAnimation("working_nospin",true)
end

local function SpawnTest(inst)
    if inst.amount_blackglommerfuel < MAX_BLACKGLOMMERFUEL then
        return true
    end
    inst.components.periodicspawner:Stop()
    inst:ListenForEvent("blackglommerfuel_used",ForceNextSpawn)
    return false
end

local function OnEmpty(inst)
   inst.components.periodicspawner:Stop()
   inst.AnimState:PushAnimation("idle",true)
end 

local function ontakefuel(inst)
    if inst.components.periodicspawner.task == nil then
        inst.components.periodicspawner:Start()
    end
    inst.AnimState:PlayAnimation("use")
    inst.AnimState:PushAnimation("working_nospin",true)
end

local function onsave(inst,data)
    if inst.amount_blackglommerfuel then
        data.amount_blackglommerfuel = inst.amount_blackglommerfuel
    end
end

local function onload(inst,data)
    if data.amount_blackglommerfuel ~= nil then
        inst.amount_blackglommerfuel = data.amount_blackglommerfuel
    end
end

local function onbuilt(inst)
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("working_nospin",true)
    end
end

local function gerat()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.8, 1.2)

    
    --inst.MiniMapEntity:SetPriority(5)
    --inst.MiniMapEntity:SetIcon("anvil.tex")

    inst.AnimState:SetBank("blackglommerspit_gerat")
    inst.AnimState:SetBuild("blackglommerspit_gerat")
    inst.AnimState:PushAnimation("working_nospin",true)
    
    inst:AddTag("structure")

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.syncanim = syncanim
    inst.syncanimpush = syncanimpush

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"glommerfuelmachine_item"})

    inst:AddComponent("periodicspawner")
    --inst.components.periodicspawner:SetOnSpawnFn(OnSpawnFuel)
    inst.components.periodicspawner.prefab = "blackglommerfuel"
    inst.components.periodicspawner.basetime = TUNING.TOTAL_DAY_TIME * 2
    inst.components.periodicspawner.randtime = TUNING.TOTAL_DAY_TIME / 4
    inst.components.periodicspawner:Start()
    --inst.components.periodicspawner:SetSpawnTestFn(SpawnTest)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(480*4)
    inst.components.fueled:SetDepletedFn(OnEmpty)
    --inst.components.fueled:SetUpdateFn(fuelupdate)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(7)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:ListenForEvent("onbuilt", onbuilt)

    inst.amount_blackglommerfuel = 0
    TheWorld.blackglommerfuelgerat = inst
    
    MakeHauntableWork(inst)
    
    inst.OnSave = onsave 
    inst.OnLoad = onload


    return inst
end 


--------------------------------------------------------------------------------------------------------------

local assets4 =
{
    Asset("ANIM", "anim/blackglommerfuel.zip"),
}

local prefabs4 =
{
}


local function ondeploy(inst, pt)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/vomit_liquid")
    local puddle = SpawnPrefab("glommer_puddle_trap")
    if puddle ~= nil then
        puddle.Transform:SetPosition(pt:Get())
        inst.components.stackable:Get():Remove()
    end
end

local function fn_blackfuel()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("blackglommerfuel")
    inst.AnimState:SetBuild("blackglommerfuel")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy

    MakeHauntableLaunch(inst)

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = -TUNING.HEALING_HUGE
    inst.components.edible.hungervalue = -TUNING.CALORIES_HUGE
    inst.components.edible.sanityvalue = -TUNING.SANITY_HUGE

    return inst
end

return  Prefab("glommer_small", fn_small, assets, prefabs),
        Prefab("glommer_boss", fn_big, assets,prefabs),
        Prefab("glommerfuelmachine", gerat, assets3,prefabs3),
        Prefab("glommerfuelmachine_item", itemfn, assets3,prefabs3),
        MakePlacer("glommerfuelmachine_item_placer", "blackglommerspit_gerat", "blackglommerspit_gerat", "placer"),
        Prefab("blackglommerfuel", fn_blackfuel, assets4, prefabs4),
        MakePlacer("blackglommerfuel_placer", "glommer_puddle_trap", "glommer_puddle", "anim", true, nil, nil, 0.8) 