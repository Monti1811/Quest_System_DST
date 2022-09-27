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
                devprint(overflow,num_slots,num,count,item)
                if item then
                    inst.components.container:GiveItem(other.components.inventory:RemoveItem(item,true))
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


local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "meat", "meat", "deerclops_eyeball",}
local function ChangeChesterToBoss(inst)

    inst:RemoveTag("companion")
    inst:RemoveTag("character")
    inst:RemoveTag("notraptrigger")
    inst:RemoveTag("noauradamage")

	inst:SetBrain(require("brains/chester_bossbrain"))
    inst:SetStateGraph("SGchester_boss")
    inst.AnimState:SetScale(2,2,2)

	inst.components.health:SetMaxHealth(666)
    inst.components.health:StartRegen(6.6, 10)
    inst.components.health.fire_damage_scale = 0 -- Take no damage from fire

	inst.components.combat:SetDefaultDamage(TUNING.DEERCLOPS_DAMAGE * 0.1)
	inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst,0.1,"chester_panzer")
	inst.components.combat.playerdamagepercent = TUNING.DEERCLOPS_DAMAGE_PLAYER_PERCENT
	inst.components.combat:SetRange(3)

	inst.components.combat:SetAttackPeriod(2)
	inst.components.combat:SetRetargetFunction(1, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst:AddComponent("explosiveresist")

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.numRings = 3
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.groundpoundfx = "firesplash_fx"
    --inst.components.groundpounder.groundpounddamagemult = 0.5
    inst.components.groundpounder.groundpoundringfx = "firering_fx"
    inst.components.groundpounder.noTags = { "FX", "NOCLICK", "DECOR", "INLIMBO", "glommer_small", "glommer_boss", "chester_boss", }

    inst.canslamdown = false

    --inst:RemoveComponent("container")
    inst.components.container.canbeopened = false

    inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(loot)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onhitother", OnHitOther)
	inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst.is_monster_boss = true

end

return ChangeChesterToBoss