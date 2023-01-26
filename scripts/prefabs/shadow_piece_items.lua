local Assets = {
    Asset("ANIM", "anim/shadow_crest.zip"),
}

local function OnSectionChange(newsection, oldsection, inst)
	if newsection <= 0 then
		inst:RemoveTag("able_to_attack")
		local owner = inst.components.inventoryitem:GetGrandOwner()
		if owner and owner.components.health then
	    	owner.components.health.externalabsorbmodifiers:RemoveModifier(owner,"shadow_crest")
	    end
	elseif newsection == 1 then
		inst:RemoveTag("able_to_attack")
	end
end

local function OnTakeFuel(inst,fuelvalue)
	if inst.components.fueled:GetPercent() >= 0.25 then
		inst:AddTag("able_to_attack")
	end
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner and owner.components.health and not inst.components.fueled:IsEmpty() and inst.components.equippable:IsEquipped() then
    	owner.components.health.externalabsorbmodifiers:SetModifier(owner,0.9,"shadow_crest")
    end
end

local function RookAttack(inst,player,target)
	if target and target:IsValid() and player and player:IsValid() then
		local shadow_rook = SpawnPrefab("shadow_rook")
		local scale = 0.2
		shadow_rook.Transform:SetScale(scale,scale,scale)
		shadow_rook.Transform:SetPosition(player:GetPosition():Get())
		shadow_rook:LevelUp(3)
		shadow_rook.components.combat:SetDefaultDamage(300)
		shadow_rook.sg:GoToState("attack",target)
		shadow_rook:ListenForEvent("newstate",function(shadow_rook,data)
			if data and data.statename ~= "attack" and data.statename ~= "attack_teleport" then
				if shadow_rook:IsValid() then
					shadow_rook:Remove()
				end
			end
		end)
		shadow_rook.persists = false
		inst.components.fueled:DoDelta(-500)
	end
end

local function OnEquip(inst, owner)

    owner.AnimState:OverrideSymbol("swap_hat", "shadow_crest", "swap_hat")
	
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")
	
	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
	end

	inst.onequipfn_crest = function(player,data)
    	if data and data.damage then
    		inst.components.fueled:DoDelta(-data.damage*3)
    	end
    end
    inst:ListenForEvent("attacked",inst.onequipfn_crest,owner)
    if owner.components.health and not inst.components.fueled:IsEmpty() then
    	owner.components.health.externalabsorbmodifiers:SetModifier(owner,0.9,"shadow_crest")
    end
end

local function OnUnequip(inst, owner) 
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAT")
	end
	
	inst:RemoveEventCallback("attacked",inst.onequipfn_crest,owner)
    if owner.components.health then
    	owner.components.health.externalabsorbmodifiers:RemoveModifier(owner,"shadow_crest")
    end
end

local function fn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("custom_hat.tex")

    inst.AnimState:SetBank("shadow_crest")
    inst.AnimState:SetBuild("shadow_crest")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("shadow_crest")
    inst:AddTag("shadow_piece_items")
	inst:AddTag("waterproofer")
	inst:AddTag("gestaltprotection")
	inst:AddTag("able_to_attack")
	
	MakeInventoryFloatable(inst, "small", 0.1, 1.12)
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
	inst.components.fueled:InitializeFuelLevel(2000)
	inst.components.fueled:SetSectionCallback(OnSectionChange)	
	inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
	inst.components.fueled:SetSections(4)
	inst.components.fueled.accepting = true

	inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.2)

    inst.RookAttack = RookAttack

    MakeHauntableLaunch(inst)

    return inst
end

local Assets2 = {
	Asset("ANIM", "anim/shadow_mitre.zip"),
}

local prefabs2 = {
	"shadow_bishop_fx",
}

local function DoSwarmFX(inst)
	if not inst:IsValid() then return end
    local fx = SpawnPrefab("shadow_bishop_fx")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.Transform:SetScale(inst.Transform:GetScale())
    fx.AnimState:SetMultColour(inst.AnimState:GetMultColour())
end

local function OnAttacked(inst,data)
	if data then
		if data.attacker and data.attacker.components.combat then
			DoSwarmFX(data.attacker)
			for i = 1,5 do
				data.attacker:DoTaskInTime(0.4*i,function(target)
					DoSwarmFX(target)
					target.components.combat:GetAttacked(inst,5)
				end)
			end
			data.attacker.components.combat:GetAttacked(inst,5)
		end
	end
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "shadow_mitre", "swap_body")
    inst.onequipfn_mitre = function(player,data)
    	OnAttacked(player,data)
    	if data and data.damage then
    		inst.components.fueled:DoDelta(-data.damage*2)
    	end
    end
    inst:ListenForEvent("attacked",inst.onequipfn_mitre,owner)
    if owner.components.health and not inst.components.fueled:IsEmpty() then
    	owner.components.health.externalabsorbmodifiers:SetModifier(owner,0.9,"shadow_mitre")
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("attacked",inst.onequipfn_mitre,owner)
    if owner.components.health then
    	owner.components.health.externalabsorbmodifiers:RemoveModifier(owner,"shadow_mitre")
    end
end

local function OnDepleted(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner and owner.components.health then
    	owner.components.health.externalabsorbmodifiers:RemoveModifier(owner,"shadow_mitre")
    end
end

local function OnTakeFuel(inst,fuelvalue)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner and owner.components.health and not inst.components.fueled:IsEmpty() and inst.components.equippable:IsEquipped() then
    	owner.components.health.externalabsorbmodifiers:SetModifier(owner,0.9,"shadow_mitre")
    end
end


local function fn2()

	local inst = CreateEntity()
    
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
	
    MakeInventoryPhysics(inst)

	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("shadow_mitre.tex")
	
    inst.AnimState:SetBank("shadow_mitre")
    inst.AnimState:SetBuild("shadow_mitre")
    inst.AnimState:PlayAnimation("anim")
	
	inst:AddTag("shadow_mitre")
	inst:AddTag("shadow_piece_items")
	inst:AddTag("gestaltprotection")
	
	MakeInventoryFloatable(inst, "small", 0.2, 1.1)
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
	
	inst:AddComponent("fueled")
	inst.components.fueled:InitializeFuelLevel(2000)
	inst.components.fueled:SetDepletedFn(OnDepleted)	
	inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
	inst.components.fueled.accepting = true
	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    
	MakeHauntableLaunch(inst)
	
    return inst
end

local Assets3 = { 
    Asset("ANIM", "anim/shadow_lance.zip"),
	Asset("ANIM", "anim/shadow_lance_ground.zip"),
}

local function OnEquip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "shadow_lance", "swap_object")

	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner) 
	owner.AnimState:Hide("ARM_carry") 
	owner.AnimState:Show("ARM_normal") 
end

local lunar_targets = {spider_moon = true,fruitdragon = true,mutatedhound = true,mutated_penguin = true,mushgnome = true,lightflier = true,carrat = true,molebat = true,
	alterguardian_phase1 = true,alterguardian_phase2 = true,alterguardian_phase3 = true,dustmoth = true,archive_centipede = true, }

local function Damage(inst,attacker,target)
	if target and target.prefab and lunar_targets[target.prefab] then
		return 85
	else 
		return 55
	end
end

local function OnAttack(inst,attacker,target)
	local delta = target and target.prefab and lunar_targets[target.prefab] and 5 or 10
	inst.components.fueled:DoDelta(-delta)
end

local function OnSectionChange(newsection, oldsection, inst)
	if newsection <= 0 then
		inst.components.equippable.restrictedtag = "fuel is empty"
		local owner = inst.components.inventoryitem.owner
		if inst.components.equippable:IsEquipped() and owner then
			local slot = inst.components.equippable.equipslot
			local item = owner.components.inventory:Unequip(slot)
			owner.components.inventory:GiveItem(item)
		end
	end
end

local function OnTakeFuel(inst)
	if not inst.components.fueled:IsEmpty() then
		inst.components.equippable.restrictedtag = nil
	end
end

local function fn3()

    local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
	
	MakeInventoryPhysics(inst)
	
	-- Add minimap icon. Remember about its XML in modmain.lua!
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("shadow_lance.tex")
	
	inst.AnimState:SetBank("shadow_lance_ground")
	inst.AnimState:SetBuild("shadow_lance_ground")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("shadow_lance")
	inst:AddTag("shadow_piece_items")
	inst:AddTag("gestaltprotection")

    MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(Damage)
	inst.components.weapon:SetOnAttack(OnAttack)

	inst:AddComponent("fueled")
	inst.components.fueled:InitializeFuelLevel(2000)
	inst.components.fueled:SetSectionCallback(OnSectionChange)	
	inst.components.fueled:SetTakeFuelFn(OnTakeFuel)
	inst.components.fueled.accepting = true
	inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE

	MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("shadow_crest", fn, Assets),
		Prefab("shadow_mitre", fn2, Assets2,prefabs2),
		Prefab("shadow_lance", fn3, Assets3)