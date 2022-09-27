require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "giantutils"

local SEE_DIST = 40

local CHASE_DIST = 45
local CHASE_TIME = 20
local FORCE_MELEE_DIST = 3

local MAX_WANDER_DIST = 10

local OUTSIDE_CATAPULT_RANGE = TUNING.WINONA_CATAPULT_MAX_RANGE + TUNING.WINONA_CATAPULT_KEEP_TARGET_BUFFER + TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 1
local function OceanChaseWaryDistance(inst, target)
    -- We already know the target is on water. We'll approach if our attack can reach, but stay away otherwise.
    return (CanProbablyReachTargetFromShore(inst, target, TUNING.DEERCLOPS_ATTACK_RANGE - 0.25) and 0) or OUTSIDE_CATAPULT_RANGE
end

local function GetWanderPos(inst)
    if inst.components.knownlocations:GetLocation("targetbase") then
        return inst.components.knownlocations:GetLocation("targetbase")
    elseif inst.components.knownlocations:GetLocation("home") then
        return inst.components.knownlocations:GetLocation("home")
    elseif inst.components.knownlocations:GetLocation("spawnpoint") then
        return inst.components.knownlocations:GetLocation("spawnpoint")
    end
end

local function ShouldSlamDown(inst)
    return inst.components.combat:HasTarget() and not inst.components.timer:TimerExists("slamdown")
end

local function CanMeleeNow(inst)
    local target = inst.components.combat.target
    if target == nil or inst.components.combat:InCooldown() then
        return false
    end
    if target.components.pinnable ~= nil then
        return not target.components.pinnable:IsValidPinTarget()
    end
    return inst:IsNear(target, FORCE_MELEE_DIST)
end

local function EquipMeleeAndResetCooldown(inst)
    if inst.spitbomb.components.equippable:IsEquipped() then
        inst.components.combat:ResetCooldown()
        inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
        -- print("melee equipped and cooldown reset")
    end
end


local function CanSpitNow(inst)
    local target = inst.components.combat.target
    return target ~= nil and target.components.pinnable and target.components.pinnable:IsValidPinTarget() and not inst.components.combat:InCooldown() and not inst.components.timer:TimerExists("spit")
end

local function EquipPhlegm(inst)
    if not inst.spitbomb.components.equippable:IsEquipped() then
        inst.components.inventory:Equip(inst.spitbomb)
    end
end

local Chester_BossBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Chester_BossBrain:OnStart()
    local root =
    PriorityNode(
    {   
        WhileNode(function() return ShouldSlamDown(self.inst) end, "SlamDown",
            ActionNode(function() self.inst:PushEvent("slamdown") end)),
        WhileNode(function() return self.inst.mode2 and CanSpitNow(self.inst) end, "AttackMomentarily",
            SequenceNode({
                ActionNode(function() EquipPhlegm(self.inst) end, "Equip spit"),
                ChaseAndAttack(self.inst, CHASE_TIME) })),
        ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST, nil, nil, nil, OceanChaseWaryDistance),
        Wander(self.inst, GetWanderPos, MAX_WANDER_DIST),
    }, 1)
    self.bt = BT(self.inst, root)
end

function Chester_BossBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return Chester_BossBrain