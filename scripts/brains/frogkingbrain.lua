require "behaviours/chaseandattack"
require "behaviours/leash"
require "behaviours/wander"


local FrogkingBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.timetochanneling = nil
end)

local function GetHomePos(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function ShouldBeyyyblade(inst)
    return inst.level > 1 and inst.components.combat:HasTarget() and inst.components.combat.target:HasTag("player") and not inst.components.timer:TimerExists("beyblade_cd")
end

local function ShouldCrownPlayer(inst)
    return inst.level > 2 and inst.components.combat:HasTarget() and inst.components.combat.target:HasTag("player") and not inst.components.timer:TimerExists("crowning_cd")
end

local function ShouldBurrowPlayer(inst)
    return inst.components.combat:HasTarget() and inst.components.combat.target:HasTag("player") and not inst.components.timer:TimerExists("burrowing_cd")
end



function FrogkingBrain:OnStart()
    local root = PriorityNode(
    {
        Leash(self.inst, GetHomePos, 30, 25),
        WhileNode(function() return ShouldBurrowPlayer(self.inst) end, "Burrowing",
            ActionNode(function() self.inst:PushEvent("burrowing") end)),
        WhileNode(function() return ShouldBeyyyblade(self.inst) end, "Beyblade",
            ActionNode(function() self.inst:PushEvent("beyblade") end)),
        WhileNode(function() return ShouldCrownPlayer(self.inst) end, "Crowning",
            ActionNode(function() self.inst:PushEvent("crowning") end)),
        ChaseAndAttack(self.inst),
        ParallelNode{
            Wander(self.inst, GetHomePos, 5),
        },
    }, 1)

    self.bt = BT(self.inst, root)
end

function FrogkingBrain:OnInitializationComplete()
    local pos = self.inst:GetPosition()
    pos.y = 0
    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return FrogkingBrain
