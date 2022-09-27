require "prefabutil"
require "recipe"
require "modutil"

local function OnSpawnFuel(inst)
    inst.slime_left = inst.slime_left - 1
    if inst.slime_left < 1 then
        inst:DoTaskInTime(0,inst.Remove)
    end
end

local function OnSave(inst,data)
    data.slime_left = inst.slime_left
end

local function OnLoad(inst,data)
    if data.slime_left ~= nil then
        inst.slime_left = data.slime_left
    end
end

local assets =
{
    Asset("ANIM", "anim/glommer_lightflower.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("glommer_lightflower")
    inst.AnimState:SetBuild("glommer_lightflower")
    inst.AnimState:PlayAnimation("idle",true)

    inst.entity:AddLight()
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(false)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawnFuel)
    inst.components.periodicspawner.prefab = "glommerfuel"
    inst.components.periodicspawner.basetime = TUNING.TOTAL_DAY_TIME * 0.5
    inst.components.periodicspawner.randtime = TUNING.TOTAL_DAY_TIME * 0.5
    inst.components.periodicspawner:Start()

    inst.slime_left = 20

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("glommer_lightflower", fn, assets)