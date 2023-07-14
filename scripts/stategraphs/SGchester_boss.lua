require("stategraphs/commonstates")

local NUM_FX_VARIATIONS = 7
local MAX_RECENT_FX = 4
local MIN_FX_SCALE = .5
local MAX_FX_SCALE = 1.6

local SLAMDOWN_TIMER = 15
local SPIT_TIMER = 30

local function _dist2dsq(p1, p2)
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

local function _ChangeBurnFX(inst,points)
    for k, point in pairs(points) do
        local ents = TheSim:FindEntities(point.x, point.y, point.z, 3, nil, inst.components.groundpounder.noTags)
        if #ents > 0 then
            for i, v in ipairs(ents) do
                if v:IsValid() and not v:IsInLimbo() and v.components.fueled == nil and v.components.burnable ~= nil and v.components.burnable:IsBurning() then
                    for i2,v2 in pairs(v.components.burnable.fxchildren) do
                        if v2:IsValid() then
                            --v2.AnimState:SetMultColour(0.05,0.05,0.05,1)  --black
                            v2.AnimState:SetAddColour(0/255,200/255,0,1)    --neon green
                            if v:HasTag("player") then
                                v:AddTag("green_flames")
                                v:DoTaskInTime(4,function() v:RemoveTag("green_flames") end)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ChangeBurnFX(inst)
    local points = inst.components.groundpounder:GetPoints(inst:GetPosition())
    local delay = 0
    for i = 1, 2 do
        inst:DoTaskInTime(delay, _ChangeBurnFX, points[i])
        delay = delay + inst.components.groundpounder.ringDelay
    end
end


local function SpawnMoveFx(inst, scale)
    local fx = SpawnPrefab("hutch_move_fx")
    if fx ~= nil then
        if inst.sg.mem.recentfx == nil then
            inst.sg.mem.recentfx = {}
        end
        local recentcount = #inst.sg.mem.recentfx
        local rand = math.random(NUM_FX_VARIATIONS - recentcount)
        if recentcount > 0 then
            while table.contains(inst.sg.mem.recentfx, rand) do
                rand = rand + 1
            end
            if recentcount >= MAX_RECENT_FX then
                table.remove(inst.sg.mem.recentfx, 1)
            end
        end
        table.insert(inst.sg.mem.recentfx, rand)
        fx:SetVariation(rand, fx._min_scale + (fx._max_scale - fx._min_scale) * scale)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function TrySlamDown(inst)
    if not inst.components.timer:TimerExists("slamdown") then
        local target = inst.components.combat.target
        if target ~= nil then
            inst.sg:GoToState("slamdown_pre", target)
            return true
        end
    end
end

local function onattackfn(inst,data,...)
    if inst.components.health ~= nil and not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
        local weapon = inst.components.combat and inst.components.combat:GetWeapon()
        if weapon and weapon:HasTag("spitbomb") and not inst.components.timer:TimerExists("spit") then
            inst.sg:GoToState("launchprojectile", data.target)
        end
        inst.sg:GoToState("attack")
    end
end

local function onattackedfn(inst)
    if (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt")) and not inst.components.health:IsDead() then
        if not CommonHandlers.HitRecoveryDelay(inst,nil,3) then
            inst.sg:GoToState("hit")
        end
    end
end

local actionhandlers =
{
}

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("doattack", onattackfn),
    EventHandler("slamdown", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            TrySlamDown(inst)
        else
            inst.sg.mem.wantstoslam = true
        end
    end),
    EventHandler("attacked", onattackedfn),
    CommonHandlers.OnDeath(),
    EventHandler("morph", function(inst, data)
        inst.sg:GoToState("morph", data.morphfn)
    end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            if not (inst.sg.mem.wantstoslam and TrySlamDown(inst)) then
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle_loop")

                if not inst.sg.mem.pant_ducking or inst.sg:InNewState() then
				    inst.sg.mem.pant_ducking = 1
			    end
            end
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        timeline=
        {
            TimeEvent(7*FRAMES, function(inst)
				inst.sg.mem.pant_ducking = inst.sg.mem.pant_ducking or 1

				inst.SoundEmitter:PlaySound(inst.sounds.pant, nil, inst.sg.mem.pant_ducking)
				if inst.sg.mem.pant_ducking and inst.sg.mem.pant_ducking > .35 then
					inst.sg.mem.pant_ducking = inst.sg.mem.pant_ducking - .05
				end
			end),
        },
   },



    State{
        name = "transition",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()

            --Remove ability to open chester for short time.
            inst.components.container:Close()
            inst.components.container.canbeopened = false

            --Create light shaft
            inst.sg.statemem.light = SpawnPrefab("chesterlight")
            inst.sg.statemem.light.Transform:SetPosition(inst:GetPosition():Get())
            inst.sg.statemem.light:TurnOn()

            inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/raise")

            inst.AnimState:PlayAnimation("idle_loop")
            inst.AnimState:PushAnimation("idle_loop")
            inst.AnimState:PushAnimation("idle_loop")
            inst.AnimState:PushAnimation("transition", false)
        end,

        onexit = function(inst)
            --Add ability to open chester again.
            inst.components.container.canbeopened = true
            --Remove light shaft
            if inst.sg.statemem.light then
                inst.sg.statemem.light:TurnOff()
            end
        end,

        timeline =
        {
            TimeEvent(56*FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("chester_transform_fx").Transform:SetPosition(x, y + 1, z)
            end),
            TimeEvent(60*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound( inst.sounds.pop )
                if inst.MorphChester ~= nil then
                    inst:MorphChester()
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "morph",
        tags = {"busy"},
        onenter = function(inst, morphfn)
            inst.Physics:Stop()

            inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/raise")
            inst.AnimState:PlayAnimation("transition", false)

            --Remove ability to open chester for short time.
            inst.components.container.canbeopened = false
            inst.components.container:Close()

            inst.sg.statemem.morphfn = morphfn
        end,

        timeline =
        {

            TimeEvent(1*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/hutch/bounce")
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/hutch/clap")
            end),
            TimeEvent(27*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/hutch/clap")
            end),
            TimeEvent(32*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/hutch/clap")
            end),
            TimeEvent(36*FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("chester_transform_fx").Transform:SetPosition(x, y + 1, z)
            end),
            TimeEvent(37*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/hutch/clap")
            end),
            TimeEvent(40*FRAMES, function(inst)
                if inst.sg.statemem.morphfn ~= nil then
                    local morphfn = inst.sg.statemem.morphfn
                    inst.sg.statemem.morphfn = nil
                    morphfn(inst)
                end
                inst.SoundEmitter:PlaySound( inst.sounds.pop )
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

        onexit = function(inst)
            if inst.sg.statemem.morphfn ~= nil then
                --In case state was interrupted
                local morphfn = inst.sg.statemem.morphfn
                inst.sg.statemem.morphfn = nil
                morphfn(inst)
            end
            --Add ability to open chester again.
            inst.components.container.canbeopened = true
        end,

    },

    State{
        name = "open",
        tags = {"busy", "open"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.sleeper:WakeUp()
            inst.AnimState:PlayAnimation("open")
            if inst.SoundEmitter:PlayingSound("hutchMusic") then
                inst.SoundEmitter:SetParameter("hutchMusic", "intensity", 1)
            end
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("open_idle") end ),
        },

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound( inst.sounds.open ) end),
        },
    },

    State{
        name = "attack",
        tags = { "attack", "busy" ,"nostun" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("chomp")
            inst.components.combat:StartAttack()

            --V2C: Cached to force the target to be the same one later in the timeline
            --     e.g. combat:DoAttack(inst.sg.statemem.target)
            inst.sg.statemem.target = target
        end,

        timeline = {
            TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack") end),
            TimeEvent(8 * FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
                --ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, 40)
            end),
            TimeEvent(2 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        onexit = function(inst)
            
        end,
    
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "slamdown_pre",
        tags = {"attack", "busy","noattack"},

        onenter = function(inst)

            if inst.components.locomotor then
                 inst.components.locomotor:StopMoving()
            end
            inst.sg.statemem.positioned = false
            inst.AnimState:PlayAnimation("jump_pre")     
            inst.sg.statemem.target = inst.components.combat.target
            inst.sg.statemem.target_pos = Point(inst.components.combat.target.Transform:GetWorldPosition())
            inst.sg.statemem.start_pos = Point(inst.Transform:GetWorldPosition())
            inst.sg.statemem.last_pos = inst.sg.statemem.start_pos
            inst.sg.statemem.speed = math.clamp(_dist2dsq(inst.sg.statemem.start_pos,inst.sg.statemem.target_pos) / 10,7,30)
            inst.components.timer:StartTimer("slamdown", SLAMDOWN_TIMER)
            --devprint("slamdown_pre",inst.sg.statemem.speed,_dist2dsq(inst.sg.statemem.start_pos,inst.sg.statemem.target_pos))
        end,

        timeline=
        {
            
        },

        onupdate = function(inst,dt)
            local height = 10
            local speed = inst.sg.statemem.speed or 7

            local target = inst.sg.statemem.target_pos
            local start_pos = inst.sg.statemem.start_pos
            local last_pos = inst.sg.statemem.last_pos
            local dist_st_end = _dist2dsq(start_pos,target)
            local pos = Point(inst.Transform:GetWorldPosition())
            local dist_curr_end = _dist2dsq(pos,target)
            if dist_curr_end < 0.5 then
                inst:PushEvent("done_preparing")
            else
                local delta_x,delta_y,delta_z = target.x - last_pos.x,target.y - last_pos.y,target.z - last_pos.z
                local delta_dist = math.max(VecUtil_Length(delta_x, delta_z), 0.0001)
                local travel_dist = speed * dt 
                local x = travel_dist*delta_x/delta_dist
                local position = (dist_st_end-dist_curr_end)/dist_st_end * 2
                local y = (position-math.pow(position,2)/4) * height 
                local z = travel_dist*delta_z/delta_dist
                inst.Physics:TeleportRespectingInterpolation(pos.x+x,y,pos.z+z)
            end
            inst.sg.statemem.last_pos = pos
        end,

        events =
        {
            EventHandler("done_preparing", function(inst)
                inst.sg.statemem.positioned = true
                inst.sg:GoToState("slamdown")
            end),
        },

        onexit = function(inst)

        end,
    },

    State{
        name = "slamdown",
        tags = { "attack", "busy", "noattack" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("jump_pst",true)
            inst.components.combat:StartAttack()

            inst.sg.statemem.target = target
        end,

        onupdate = function(inst,dt)
            inst.Physics:SetMotorVelOverride(0, -30, 0)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)

                inst.components.groundpounder:GroundPound()
                inst:DoTaskInTime(0,ChangeBurnFX)

                inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/pop")
                ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, 40)
                inst.sg:GoToState("idle")

                local sinkhole = SpawnPrefab("antlion_sinkhole")
                sinkhole.Transform:SetPosition(x,0,z)
                sinkhole:PushEvent("startrepair")
                sinkhole:DoPeriodicTask(15,function(sinkhole) 
                    sinkhole.components.timer:StopTimer("nextrepair")
                    sinkhole:PushEvent("timerdone", {name = "nextrepair"}) 
                end)
                sinkhole.persists = false
            end
        end,

        timeline = {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/pop") end),
        },

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
            inst.Physics:ClearMotorVelOverride()
        end,
    
    },

    State{
        name = "launchprojectile",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("lick")
            inst.components.timer:StartTimer("spit",SPIT_TIMER)
            inst:DoTaskInTime(16*FRAMES,function() inst.components.inventory:Unequip(EQUIPSLOTS.HANDS) end)
        end,


        timeline=
        {
            TimeEvent(10*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.lick)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle") 
            end),
        },
    },

    State{
        name = "appear",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("idle_loop",true)
            inst.components.timer:StartTimer("slamdown", SLAMDOWN_TIMER)
        end,

        onupdate = function(inst,dt)
            inst.Physics:SetMotorVelOverride(0, -5, 0)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)

                inst.components.groundpounder:GroundPound()
                inst:DoTaskInTime(0,ChangeBurnFX)

                inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/pop")
                ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, 40)
                inst.sg:GoToState("idle")

                local sinkhole = SpawnPrefab("antlion_sinkhole")
                sinkhole.Transform:SetPosition(x,0,z)
                sinkhole:PushEvent("startrepair")
                sinkhole:DoPeriodicTask(15,function(sinkhole) 
                    sinkhole.components.timer:StopTimer("nextrepair")
                    sinkhole:PushEvent("timerdone", {name = "nextrepair"}) 
                end)
            end
        end,

        timeline = {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/chester/pop") end),
        },

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
            inst.Physics:ClearMotorVelOverride()
        end,
    
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound(inst.sounds.death)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.inventory:DropEverything()
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        timeline = nil,
    },

    State{
        name = "hit",
        tags = { "hit", "busy" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            inst.AnimState:PlayAnimation("hit")

            if inst.SoundEmitter ~= nil and inst.sounds ~= nil and inst.sounds.hit ~= nil then
                inst.SoundEmitter:PlaySound(inst.sounds.hit)
            end

            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        timeline = nil,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if not (inst.sg.mem.wantstoslam and TrySlamDown(inst)) then
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    },

}

CommonStates.AddWalkStates(states, {
    walktimeline =
    {
        --TimeEvent(0*FRAMES, function(inst)  end),

        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound( inst.sounds.boing )

            inst.components.locomotor:RunForward()

            --Cave chester leaves slime as he bounces
            if inst.leave_slime then
                inst.sg.statemem.slimein = true
                if inst.sg.mem.lastspawnlandingmovefx ~= nil and inst.sg.mem.lastspawnlandingmovefx + 2 > GetTime() then
                    inst.sg.statemem.slimeout = true
                    SpawnMoveFx(inst, .45 + math.random() * .1)
                end
            end
        end),

        TimeEvent(2 * FRAMES, function(inst)
            if inst.sg.statemem.slimeout then
                SpawnMoveFx(inst, .2 + math.random() * .1)
            end
        end),

        TimeEvent(4 * FRAMES, function(inst)
            if inst.sg.statemem.slimeout and math.random() < .7 then
                SpawnMoveFx(inst, .1 + math.random() * .1)
            end
        end),

        TimeEvent(7 * FRAMES, function(inst)
            if inst.sg.statemem.slimeout and math.random() < .3 then
                SpawnMoveFx(inst, 0)
            end
        end),

        TimeEvent(10 * FRAMES, function(inst)
            if inst.sg.statemem.slimein and math.random() < .6 then
                SpawnMoveFx(inst, .05 + math.random() * .1)
            end
        end),

        TimeEvent(12 * FRAMES, function(inst)
            if inst.sg.statemem.slimein then
                SpawnMoveFx(inst, .25 + math.random() * .1)
            end
        end),

        TimeEvent(13*FRAMES, function(inst)
            if inst.sounds.land_hit ~= nil then
                inst.SoundEmitter:PlaySound(inst.sounds.land_hit)
            end
            if inst.sg.statemem.slimein then
                if inst.sounds.land ~= nil then
                    inst.SoundEmitter:PlaySound(inst.sounds.land)
                end
                SpawnMoveFx(inst, .8 + math.random() * .2)
                inst.sg.mem.lastspawnlandingmovefx = GetTime()
            end
        end),

        TimeEvent(14*FRAMES, function(inst)
            PlayFootstep(inst)
            inst.components.locomotor:WalkForward()
        end),
    },

    endtimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
--[[
            if inst.sounds.land_hit then
                inst.SoundEmitter:PlaySound( inst.sounds.land_hit )
            end
            ]]
            if inst.sg.statemem.slimein then
                if inst.sounds.land ~= nil then
                    inst.SoundEmitter:PlaySound(inst.sounds.land)
                end
                SpawnMoveFx(inst, .4 + math.random() * .2)
                inst.sg.mem.lastspawnlandingmovefx = GetTime()
            end
        end),
    },

}, nil, true)

CommonStates.AddHopStates(states, true, nil,
{

    hop_pre =
    {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")
        end),
    }
})

--[[CommonStates.AddCombatStates(states,
{
    attacktimeline =
    {
        TimeEvent(0 * FRAMES, function(inst) print("start attack") inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack") end),
        TimeEvent(1 * FRAMES, function(inst)
            inst.components.combat:DoAttack(inst.sg.statemem.target)
            print("now doing attack")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
            ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, 40)
        end),
        TimeEvent(2 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
    },
},{attack = "chomp",})]]

CommonStates.AddSleepStates(states,
{
    starttimeline =
    {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound( inst.sounds.close ) end)
    },

    sleeptimeline =
    {
        TimeEvent(1*FRAMES, function(inst)
            if inst.sounds.sleep then
                inst.SoundEmitter:PlaySound( inst.sounds.sleep )
            end
        end)
    },
    waketimeline =
    {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound( inst.sounds.open ) end)
    },
})

CommonStates.AddSimpleState(states, "hit", "hit", {"busy"})
CommonStates.AddSinkAndWashAsoreStates(states)

return StateGraph("chester", states, events, "idle", actionhandlers)

