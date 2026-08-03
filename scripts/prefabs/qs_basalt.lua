local assets =
{
    Asset("ANIM", "anim/blocker.zip"),
}

local function makebasalt(anims)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst:AddTag("blocker")
        local phys = inst.entity:AddPhysics()
        phys:SetMass(0)
        phys:SetCollisionGroup(COLLISION.GROUND)
        phys:ClearCollisionMask()
        phys:CollidesWith(COLLISION.ITEMS)
        phys:CollidesWith(COLLISION.CHARACTERS)
        phys:CollidesWith(COLLISION.GIANTS)
        phys:SetCapsule(1, 10)

        inst.MiniMapEntity:SetIcon("basalt.png")

        inst.AnimState:SetBank("blocker")
        inst.AnimState:SetBuild("blocker")

        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.animname = anims[math.random(#anims)]
        inst.AnimState:PlayAnimation(inst.animname)
        inst.scrapbook_anim = inst.animname
        local color = 0.5 + math.random() * 0.5
        inst.AnimState:SetMultColour(color, color, color, 1)

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "BASALT"
        MakeSnowCovered(inst)
        return inst
    end
end

return Prefab("qs_basalt", makebasalt({"block1", "block4", "block2"}), assets)