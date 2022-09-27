require("stategraphs/commonstates")

local NO_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost","glommer_boss", "chester_boss", }

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "flyaway"),
}

local SHAKE_DIST = 40
local PUKE_TIMER = 15

local function TryPuke(inst)
    if not inst.is_small_glommer and not inst.components.timer:TimerExists("puke") then
        local target = inst.components.combat.target
        if target ~= nil then
            inst.sg:GoToState("puke", target)
            return true
        end
    end
end

local events=
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(nil,3),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(false,true),
    EventHandler("puke", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            TryPuke(inst)
        else
            inst.sg.mem.wantstopuke = true
        end
    end),
}

local function StartFlap(inst)
	if inst.FlapTask then return end
	inst.FlapTask = inst:DoPeriodicTask(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/flap") end)
end

local function StopFlap(inst)
	if inst.FlapTask then
		inst.FlapTask:Cancel()
		inst.FlapTask = nil
	end
end



local states=
{
	State{
		name = "idle",
		tags = {"idle"},

		onenter = function(inst)
			if not (inst.sg.mem.wantstoslam and TryPuke(inst)) then
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("idle_loop")
				StartFlap(inst)
				if math.random() > 0.75 then
					inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice")
				end
			end
		end,

		timeline =
		{
			TimeEvent(3*FRAMES, function(inst)
				if math.random() > 0.75 then
					inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice")
				end
			end)
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},
	},

	State{
		name = "goo",
		tags = {"busy"},

		onenter = function(inst, fuel)
			inst.Physics:Stop()
			if fuel then
				fuel:Hide()
				inst.sg.statemem.fuel = fuel
			end

			inst.AnimState:PlayAnimation("place")
			StartFlap(inst)
		end,

		timeline =
		{
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/vomit_voice") end),
			TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/vomit_liquid") end),
			TimeEvent(30*FRAMES, function(inst)
				if inst.sg.statemem.fuel then
					inst.sg.statemem.fuel:Show()
				end
			end)
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
		},
	},

	State{
        name = "frozen",
        tags = {"busy", "frozen"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            StopFlap(inst)
            LandFlyingCreature(inst)
        end,

        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
            RaiseFlyingCreature(inst)
        end,

        events=
        {
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),
        },
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            StopFlap(inst)
            LandFlyingCreature(inst)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
            RaiseFlyingCreature(inst)
        end,

        events =
        {
            EventHandler("unfreeze", function(inst)
                if inst.sg.sg.states.hit then
                    inst.sg:GoToState("hit")
                else
                    inst.sg:GoToState("idle")
                end
            end ),
        },
    },

    State{
        name = "flyaway",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
	        inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("walk_pre")
           	StartFlap(inst)
        end,

        timeline =
        {
            TimeEvent(9*FRAMES, function(inst)
                inst.AnimState:PushAnimation("walk_loop", true)
                inst.Physics:SetMotorVel(-2 + math.random()*4, 5+math.random()*3,-2 + math.random()*4)
            end),
            TimeEvent(5, function(inst) inst:Remove() end)
        }
    },

    State{
        name = "puke",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("place")
            inst.components.combat:StartAttack()

            inst.sg.statemem.target = target
            inst.components.timer:StartTimer("puke", PUKE_TIMER)
        end,

        timeline =
    	{
	        TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice") end),
	        TimeEvent(30 * FRAMES, function(inst)
	            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice")
                inst.components.combat:DoAreaAttack(inst,6,nil,nil,nil,NO_TAGS)
	            local pt = inst:GetPosition()
				local glommer_puddle = SpawnPrefab("glommer_puddle_fx")
				if glommer_puddle then
					glommer_puddle.Transform:SetPosition(pt:Get())
				end
	            --ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, SHAKE_DIST)
	        end),
	        TimeEvent(31 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
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
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("collect")
            inst.components.combat:StartAttack()
        end,

        timeline =
    	{
	        TimeEvent(14 * FRAMES, function(inst)
	            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice")
	            
	            if inst.bufferedaction ~= nil and inst.bufferedaction.action == ACTIONS.HAMMER then
	                local target = inst.bufferedaction.target
	                inst:ClearBufferedAction()
	                if target ~= nil and
	                    target:IsValid() and
	                    target.components.workable ~= nil and
	                    target.components.workable:CanBeWorked() and
	                    target.components.workable:GetWorkAction() == ACTIONS.HAMMER then
	                    target.components.workable:Destroy(inst)
	                end
	            end
	            local pt = inst:GetPosition()
				local groundpound = SpawnPrefab("crabking_ring_fx")
				if groundpound then
					groundpound.Transform:SetPosition(pt:Get())
					if inst.is_small_glommer then
						local scale = inst._amount and 1-0.7*inst._amount/20 or 0.3
                        inst.components.combat:DoAreaAttack(inst,6*scale,nil,nil,nil,NO_TAGS)
						groundpound.Transform:SetScale(scale,scale,scale)
					else
                        inst.components.combat:DoAreaAttack(inst,6,nil,nil,nil,NO_TAGS)
						ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, SHAKE_DIST)
					end
				end
	        end),
	        TimeEvent(15 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
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

        timeline = 
		{
			TimeEvent(0, function(inst) StartFlap(inst) end),
			TimeEvent(0, function(inst)	inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/hurt_voice") end)
		},

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if not (inst.sg.mem.wantstopuke and TryPuke(inst)) then
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    },

    State{
        name = "fly_towards",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("walk_pre")
            inst.AnimState:PushAnimation("walk_loop", true)
            StartFlap(inst)
        end,

        onupdate = function(inst,dt)
            inst.Physics:SetMotorVelOverride(2 + math.random(), -5+math.random()*3,2 + math.random())
            local x, y, z = inst.Transform:GetWorldPosition()
            if y < 2 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)

                inst.sg:GoToState("idle")
            end
        end,

        timeline = {
            TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/idle_voice") end),
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
            inst.AnimState:PlayAnimation("death")

            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        timeline =
		{
			TimeEvent(0, function(inst) StartFlap(inst) end),
			TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/die_voice") end),
			TimeEvent(10*FRAMES, function(inst) StopFlap(inst) end),
        	TimeEvent(10*FRAMES, LandFlyingCreature),
			TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/die_ground") end)
		},

    },
}

CommonStates.AddSimpleActionState(states, "action", "idle", FRAMES*5, {"busy"})
CommonStates.AddWalkStates(states,
{
	starttimeline = {TimeEvent(0, function(inst) StartFlap(inst) end)},
	walktimeline = {TimeEvent(0, function(inst) StartFlap(inst) end)},
	endtimeline = {TimeEvent(0, function(inst) StartFlap(inst) end)},
})
CommonStates.AddSleepStates(states,
{
	starttimeline = {TimeEvent(0, function(inst) StartFlap(inst) end)},
	sleeptimeline =
		{
			TimeEvent(0*FRAMES, function(inst) StopFlap(inst) end),
			TimeEvent(35*FRAMES, function(inst) StartFlap(inst) end),
			TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/sleep_voice") end)
		},
	endtimeline = {TimeEvent(0, function(inst) StartFlap(inst) end)},
},
{
    onsleep = LandFlyingCreature,
    onwake = RaiseFlyingCreature,
})

return StateGraph("glommer_boss", states, events, "idle", actionhandlers)