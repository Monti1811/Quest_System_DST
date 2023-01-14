local function GetNormalPosition(portal, collider)
    local pt = portal:GetPosition()
    local pt_collider = collider:GetPosition()
end

local function OnCollideCeiling(inst, collider)
    devprint("OnCollideCeiling",inst,collider)
    if collider and collider.Transform ~= nil then
        local cy, cx, cz = collider.Transform:GetWorldPosition()

        if cx < 10 then
            if collider:HasTag("bird") then
                collider:Remove()
            end
        end
    end
end

local function OnCeilingInit(inst)
    local x, _, z = (inst.parent or inst).Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, 10, z)
end

local function ceiling()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    local phys = inst.entity:AddPhysics()
    phys:SetMass(0)
    phys:SetCollisionGroup(COLLISION.WORLD)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.GIANTS)
    phys:CollidesWith(COLLISION.FLYERS)
    phys:SetCylinder(70, 70)
    phys:SetCollisionCallback(OnCollideCeiling)

    inst:DoTaskInTime(0, OnCeilingInit)

    inst.persists = false

    return inst
end

return Prefab("boss_island_ceiling", ceiling)