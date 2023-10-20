require "prefabutil"
require "recipe"
require "modutil"

local assets=
{
	Asset("ANIM", "anim/quest_board.zip"),
}

local prefabs = 
{
	
}


local function OnRead(inst,doer)
	--SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "ShowQuestBoard"),doer.userid,doer)
end

local function onhammered(inst)
	inst.components.lootdropper:DropLoot()

	local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial("wood")
    
	inst:Remove()
end


local function onsave(inst, data)
	 if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
         data.burnt = true
     end
end

local function onload(inst, data)
	 if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end
----------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1.1)
	
	inst.MiniMapEntity:SetPriority(5)
	inst.MiniMapEntity:SetIcon("quest_board.tex")

	inst.AnimState:SetBank("quest_board")
	inst.AnimState:SetBuild("quest_board")
	inst.AnimState:PlayAnimation("idle")
	inst.Transform:SetScale(0.9, 0.9, 0.9)
	
	inst:AddTag("structure")
	inst:AddTag("questboard")

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("simplebook")
	inst.components.simplebook.onreadfn = OnRead

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(5)
	inst.components.workable:SetOnFinishCallback(onhammered)
	
	MakeHauntableWork(inst)
	
	--inst.OnSave = onsave 
	--inst.OnLoad = onload


	return inst
end

return 	Prefab( "questboard", fn, assets, prefabs),
		MakePlacer( "questboard_placer", "quest_board", "quest_board", "idle", nil, nil, nil, 0.9)
