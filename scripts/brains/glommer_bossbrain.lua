require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"
require "giantutils"

local SEE_DIST = 40

local CHASE_DIST = 32
local CHASE_TIME = 20

local MAX_WANDER_DIST = 10


local function GetWanderPos(inst)
    if inst.components.knownlocations:GetLocation("targetbase") then
        return inst.components.knownlocations:GetLocation("targetbase")
    elseif inst.components.knownlocations:GetLocation("home") then
        return inst.components.knownlocations:GetLocation("home")
    elseif inst.components.knownlocations:GetLocation("spawnpoint") then
        return inst.components.knownlocations:GetLocation("spawnpoint")
    end
end

local BASEDESTROY_CANT_TAGS = {"wall"}

local function BaseDestroy(inst)
    if not inst.is_small_glommer and not inst.components.knownlocations:GetLocation("targetbase") then
        local target = FindEntity(inst, SEE_DIST, function(item)
                if item.components.workable and item:HasTag("structure")
                        and item.components.workable.action == ACTIONS.HAMMER
                        and item:IsOnValidGround() then
                    return true
                end
            end, nil, BASEDESTROY_CANT_TAGS)
        if target then
            return BufferedAction(inst, target, ACTIONS.HAMMER)
        end
    end
end

local function ShouldPuke(inst)
    return inst.components.combat:HasTarget() and inst.components.combat.target:HasTag("player") and not inst.is_small_glommer and not inst.components.timer:TimerExists("puke")
end


local Glommer_BossBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Glommer_BossBrain:OnStart()
    local root =
    PriorityNode(
    {
        WhileNode(function() return ShouldPuke(self.inst) end, "Puke",
            ActionNode(function() self.inst:PushEvent("puke") end)),
        ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST),
        DoAction(self.inst, BaseDestroy, "DestroyBase", true),
        Wander(self.inst, GetWanderPos, MAX_WANDER_DIST),
    }, 1)
    self.bt = BT(self.inst, root)
end

function Glommer_BossBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return Glommer_BossBrain