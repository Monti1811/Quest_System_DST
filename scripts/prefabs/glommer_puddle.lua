local assets=
{
	Asset("ANIM", "anim/glommer_puddle.zip")    
}

local function Debuff(player)
	if player.components.health then
		player.components.health:DoDelta(-2,nil,"poison")
		player.AnimState:SetMultColour(0.3,0.3,0.3,1)
		player._debuffed_glommer = true
		if player._debuff_task_remove ~= nil then
			player._debuff_task_remove:Cancel()
			player._debuff_task_remove = nil
		end
		player._debuff_task_remove = player:DoTaskInTime(1.5,function()
			if player._debuffed_glommer == true then
				player.AnimState:SetMultColour(1,1,1,1)
				player._debuffed_glommer = false
			end
		end)
	end
end

local function PuddleDebuff(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, {"player"})
    for k, v in ipairs(ents) do
        Debuff(v)
    end
end

local scale = 1
local function GrowInSize(inst)
	if scale < 2 then
		scale = scale + 0.1
		inst.Transform:SetScale(scale, scale, scale)
		inst:DoTaskInTime(0.1,GrowInSize)
	else
		scale = 1
	end
end

local function OnTimerDone(inst, data)
    if data.name == "disperse" then
        inst.persists = false
        inst.AnimState:PlayAnimation("disappear")
    	inst:DoTaskInTime(20*FRAMES, inst.Remove)
    end
end

local function DebuffTarget(target)
	target.AnimState:SetMultColour(0.25,0.25,0.25,1)
	target.components.combat.externaldamagetakenmultipliers:SetModifier(target,1.2,"blackglommerfuel")
	target.components.combat.externaldamagemultipliers:SetModifier(target,0.6,"blackglommerfuel")
	if target.components.locomotor then
		target.components.locomotor:SetExternalSpeedMultiplier(target,"blackglommerfuel",0.6)
	end
	if target.blackfuel_debuff ~= nil then
		target.blackfuel_debuff:Cancel()
		target.blackfuel_debuff = nil
	end
	target.blackfuel_debuff = target:DoTaskInTime(10,function()
		target.AnimState:SetMultColour(1,1,1,1)
		target.components.combat.externaldamagetakenmultipliers:RemoveModifier(target,"blackglommerfuel")
		target.components.combat.externaldamagemultipliers:RemoveModifier(target,"blackglommerfuel")
		if target.components.locomotor then
			target.components.locomotor:RemoveExternalSpeedMultiplier(target,"blackglommerfuel")
		end
	end)
end

local function OnExplode(inst,target)
    inst.AnimState:PlayAnimation("disappear")
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/glommer/vomit_liquid")
    inst.persists = false
    inst:DoTaskInTime(20*FRAMES,inst.Remove)
    if target then
    	target.components.combat:GetAttacked(inst, 100)
    	DebuffTarget(target)
    end
end


local function basic_fn()
	local inst = CreateEntity()

	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	--trans:SetScale(2, 2, 2)
	inst.entity:AddNetwork()

	--inst:DoTaskInTime(0.1,GrowInSize)
	
	
	--anim:SetBank("glommer_puddle")
	anim:SetBuild("glommer_puddle")
	anim:PlayAnimation("appear")
	anim:PushAnimation("anim",true)
	anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	anim:SetLayer(LAYER_BACKGROUND)
	
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

   	return inst
end

local function puddle_fn()
	local inst = basic_fn()
	inst.AnimState:SetBank("glommer_puddle")
	local scale = 1.2
	inst.Transform:SetScale(scale,scale,scale)

	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("aura")
    inst.components.aura.radius = TUNING.TOADSTOOL_SPORECLOUD_RADIUS
    inst.components.aura.tickperiod = TUNING.TOADSTOOL_SPORECLOUD_TICK
    inst.components.aura.auraexcludetags =  {"playerghost", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "flight", "invisible","glommer_small", "glommer_boss", "chester_boss", }
    inst.components.aura:Enable(true)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("disperse", 15)

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst._debufftask = inst:DoPeriodicTask(1, PuddleDebuff,1)
    return inst
end

local function trap_fn()
	local inst = basic_fn()
	inst.AnimState:SetBank("glommer_puddle_trap")
	inst.entity:AddSoundEmitter()
	inst.Transform:SetScale(0.8, 0.8, 0.8)
	--inst.AnimState:SetMultColour(0.1,0.1,0.1,1)
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("mine")
    inst.components.mine:SetRadius(4)
    inst.components.mine:SetAlignment("player")
    inst.components.mine:SetOnExplodeFn(OnExplode)
    inst.components.mine:SetReusable(false)
    inst.components.mine:Reset()
    inst:DoTaskInTime(15,function()
    	inst.persists = false
    	inst.AnimState:PlayAnimation("disappear")
   		inst:DoTaskInTime(20*FRAMES, inst.Remove)
   	end)
   	return inst
end

return 	Prefab( "glommer_puddle_fx", puddle_fn, assets),
		Prefab( "glommer_puddle_trap", trap_fn, assets)