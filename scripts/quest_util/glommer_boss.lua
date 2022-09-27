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

local RETARGET_MUST_TAGS = { "_combat" }
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
    if data.attacker ~= nil and data.attacker:HasTag("player") and inst.components.knownlocations:GetLocation("targetbase") == nil then
        FindBaseToAttack(inst, data.attacker)
    end
end

local function OnHitOther(inst, data)
    local other = data.target
    if other ~= nil then
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
    if inst.components.knownlocations:GetLocation("targetbase") and data.target:HasTag("player") then
        inst.structuresDestroyed = inst.structuresDestroyed - 1
        inst.components.knownlocations:ForgetLocation("home")
    end
end

local function ontimerdone(inst, data)
    if data.name == "puke" then
        inst.canpuke = true
    end
end


local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "meat", "meat", "deerclops_eyeball",}
local function ChangeGlommerToBoss(inst)

	inst:SetBrain(require("brains/glommer_bossbrain"))
    inst:SetStateGraph("SGglommer_boss")
    inst.AnimState:SetScale(2,2,2)
    

	inst.components.health:SetMaxHealth(666)

	inst.components.combat:SetDefaultDamage(TUNING.DEERCLOPS_DAMAGE*0.1)
	inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst,0.1,"glommer_panzer")
	inst.components.combat.playerdamagepercent = TUNING.DEERCLOPS_DAMAGE_PLAYER_PERCENT
	inst.components.combat:SetRange(6)
	inst.components.combat:SetAreaDamage(TUNING.DEERCLOPS_AOE_RANGE, TUNING.DEERCLOPS_AOE_SCALE)

	inst.components.combat:SetAttackPeriod(TUNING.DEERCLOPS_ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(1, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst.structuresDestroyed = 1

	inst:AddComponent("explosiveresist")

	inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

	inst.components.lootdropper:SetLoot(loot)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onhitother", OnHitOther)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
end

return ChangeGlommerToBoss