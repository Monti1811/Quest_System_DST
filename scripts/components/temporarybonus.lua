local function AddHealth(inst,amount)
	if inst.components.health then
		local old_max = inst.components.health.maxhealth
		local old_percent = inst.components.health:GetPercent()
		amount = inst.prefab == "wanda" and amount * TUNING.OLDAGE_HEALTH_SCALE or amount
		inst.components.health:SetMaxHealth(old_max + amount)
		inst.components.health:SetPercent(old_percent)
	end
end

local function AddSanity(inst,amount)
	if inst.components.sanity then
		local old_max = inst.components.sanity.max
		local old_percent = inst.components.sanity:GetPercent()
		inst.components.sanity:SetMax(old_max + amount)
		inst.components.sanity:SetPercent(old_percent)
	end
end

local function AddHunger(inst,amount)
	if inst.components.hunger then
		local old_max = inst.components.hunger.max
		local old_percent = inst.components.hunger:GetPercent()
		inst.components.hunger:SetMax(old_max + amount)
		inst.components.hunger:SetPercent(old_percent)
	end
end

local function AddSanityAura(inst,amount)
	if inst.components.sanity then
		local externalmodifiers = inst.components.sanity.externalmodifiers
		if amount < 0 then
			externalmodifiers:RemoveModifier(inst,"temp_sanityaura")
		else
			externalmodifiers:SetModifier(inst,amount/60,"temp_sanityaura")
		end
	end
end

local function AddHungerRate(inst,amount,name)
	if inst.components.hunger then
		if amount < 0 then
			inst.components.hunger.burnratemodifiers:RemoveModifier(inst,name)
		else
			inst.components.hunger.burnratemodifiers:SetModifier(inst,amount,name)
		end	
	end
end

local function AddHealthRate(inst,amount,name)
	local health = inst.components.health
	if health then
		local taskname = "healtask_"..name
		if amount < 0 then
			if inst[taskname] ~= nil then
				inst[taskname]:Cancel()
				inst[taskname] = nil
			end
		else
			amount = inst.prefab == "wanda" and amount * TUNING.OLDAGE_HEALTH_SCALE or amount
			inst[taskname] = inst:DoPeriodicTask(10,function()
				if health and not health:IsDead() then
					health:DoDelta(amount)
				end
			end)
		end
	end
end

local function AddDamage(inst,amount,name)
	local combat = inst.components.combat
	if combat then
		if amount < 0 then
			combat.externaldamageadditives:RemoveModifier(inst,name)
		else
			combat.externaldamageadditives:SetModifier(inst,amount,name)
		end
	end
end

local function AddPlanarDamage(inst,amount,name)
	local planardamage = inst.components.planardamage
	if planardamage then
		if amount < 0 then
			planardamage:RemoveBonus(inst,name)
		else
			planardamage:AddBonus(inst,amount,name)
		end
	end
end

local function AddDamageReduction(inst,amount,name)
	local combat = inst.components.combat
	if combat then
		if amount < 0 then
			combat.externaldamagetakenmultipliers:RemoveModifier(inst,name)
		else
			combat.externaldamagetakenmultipliers:SetModifier(inst,amount,name)
		end		
	end
end

local function AddPlanarDefense(inst,amount,name)
	local planardefense = inst.components.planardefense
	if planardefense then
		if amount < 0 then
			planardefense:RemoveBonus(inst,name)
		else
			planardefense:AddBonus(inst,amount,name)
		end
	end
end

local function AddRange(inst,amount)
	local combat = inst.components.combat
	if combat then
		local old_attackrange = combat.attackrange
		local old_hitrange = combat.hitrange
		combat.attackrange = old_attackrange + amount
		combat.hitrange = old_hitrange + amount
	end
end


--TODO: Test if woodie works correctly and for multiple dodge buffs active
local function AddDodge(inst,amount)
	local cooldowntime = TUNING.SKILLS.WOODIE.GOOSE_DODGE_COOLDOWN_TIME - math.floor(math.max(0,(25 - amount) / 5)) -- Something between 0 and 5, as cooldowntime is 5
	local function OnWerePlayer()
		inst:DoTaskInTime(3, function()
			if inst.components.attackdodger == nil then
				inst:AddComponent("attackdodger")
			end
			if inst:IsWeregoose() and inst.components.skilltreeupdater:IsActivated("woodie_curse_goose_3") then
				inst.components.attackdodger:SetCooldownTime(cooldowntime)
			else
				inst.components.attackdodger:SetCooldownTime(amount)
				inst.components.attackdodger:SetOnDodgeFn(inst.OnDodgeAttack)
			end
		end)
	end
	local attackdodger = inst.components.attackdodger
	if attackdodger then
		return
	end
	if amount < 0 then
		if inst.prefab == "woodie" then
			inst:RemoveEventCallback("transform_wereplayer", OnWerePlayer)
			if inst:IsWeregoose() and inst.components.skilltreeupdater:IsActivated("woodie_curse_goose_3") then
				if inst.components.attackdodger == nil then
					inst:AddComponent("attackdodger")
				end
				inst.components.attackdodger:SetCooldownTime(TUNING.SKILLS.WOODIE.GOOSE_DODGE_COOLDOWN_TIME)
				inst.components.attackdodger:SetOnDodgeFn(inst.OnDodgeAttack)
				return
			end
		end
		inst:RemoveComponent("attackdodger")
	else
		inst:AddComponent("attackdodger")
		inst.components.attackdodger:SetCooldownTime(amount)
		inst.components.attackdodger:SetOnDodgeFn(function()
			local fx = SpawnPrefab("weregoose_transform_fx")
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			fx.Transform:SetScale(1.3, 1.3, 1.3)
		end)
		if inst.prefab == "woodie" then
			inst:ListenForEvent("transform_wereplayer", OnWerePlayer)
		end
	end
end

local function AddCrit(inst, amount, name)
	amount = amount/100
	local temporarybonus = inst.components.temporarybonus
	local combat = inst.components.combat
	if temporarybonus.crit_boni == nil then
		temporarybonus.crit_boni = {}
	end
	if temporarybonus.crit_chance == nil then
		temporarybonus.crit_chance = 0
	end
	devprint("AddCrit", inst, amount, name, temporarybonus.crit_chance)
	if amount < 0 then
		devdumptable(temporarybonus.crit_boni)
		temporarybonus.crit_boni[name] = nil
		devprint("checking critboni table", next(temporarybonus.crit_boni))
		if next(temporarybonus.crit_boni) == nil then
			combat.CalcDamage = temporarybonus.old_CalcDamage
		end
	elseif temporarybonus.old_CalcDamage == nil then
		temporarybonus.old_CalcDamage = combat.CalcDamage
		combat.CalcDamage = function(self, target, weapon, multiplier, ...)
			local ret = {temporarybonus.old_CalcDamage(self, target, weapon, multiplier, ...)}
			--devprint("new CalcDamage", crit_chance[inst.userid])
			if temporarybonus.crit_chance > 0 and math.random() < temporarybonus.crit_chance then
				--devprint("crit!", target, target and target:IsValid(), target and target:IsValid() and target:GetPosition())
				ret[1] = ret[1] * 1.5
				if target and target:IsValid() then
					local target_pos = target:GetPosition()
					if target_pos then
						SpawnPrefab("explode_small").Transform:SetPosition(target_pos.x, target_pos.y, target_pos.z)
					end
				end
			end
			return unpack(ret)
		end
	end
	if amount > 0 then
		temporarybonus.crit_boni[name] = true
	end
	-- Crit will automatically be reduced as amount will be negative when bonus removed
	temporarybonus.crit_chance = temporarybonus.crit_chance + amount
end

local function AddWinterInsulation(inst,amount)
	local temperature = inst.components.temperature
	if temperature then
		local old_insulation = temperature.inherentinsulation
		temperature.inherentinsulation = old_insulation + amount
	end
end

local function AddSummerInsulation(inst,amount)
	local temperature = inst.components.temperature
	if temperature then
		local old_insulation = temperature.inherentsummerinsulation
		temperature.inherentsummerinsulation = old_insulation + amount
	end
end

local function AddWaterproofness(inst, amount, name)
	amount = amount/100
	local moisture = inst.components.moisture
	if moisture then
		if amount < 0 then
			moisture.waterproofnessmodifiers:RemoveModifier(inst,name)
		else
			moisture.waterproofnessmodifiers:SetModifier(inst,amount,name)
		end
	end
end

local actions = {
	ACTIONS.CHOP,
	ACTIONS.MINE,
	ACTIONS.HAMMER,
}

local function AddWorkingBonus(inst,amount)
	local workmultiplier = inst.components.workmultiplier
	if workmultiplier ~= nil then
		if amount < 0 then
			for _,v in ipairs(actions) do
				workmultiplier:RemoveMultiplier(v,inst)
			end
		else
			for _,v in ipairs(actions) do
				workmultiplier:AddMultiplier(v,amount,inst)
			end
		end
	end
end

local sleepboni = {"hunger_bonus_mult","health_bonus_mult"}

local function AddSleepingBonus(inst,amount)
	local sleepingbaguser = inst.components.sleepingbaguser
	if sleepingbaguser then
		for _,v in ipairs(sleepboni) do
			local old = sleepingbaguser[v]
			sleepingbaguser[v] = old + amount
		end
	end
end

local function AddNightSight(inst,amount)
	local playervision = inst.components.playervision
	if playervision then
		if amount < 0 then
			if inst.components.temporarybonus:HasBonus("nightvision") then
				return
			end
			playervision:ForceNightVision(false)
			if inst.net_nightvisiontrigger then
				inst.net_nightvisiontrigger:set(false)
			end
		else
			playervision:ForceNightVision(true)
			if inst.net_nightvisiontrigger then
				inst.net_nightvisiontrigger:set(true)
			end
		end
	end
end

local function AddSpeedbonus(inst,amount,name)
	local locomotor = inst.components.locomotor
	if locomotor then
		if amount < 0 then
			locomotor:RemoveExternalSpeedMultiplier(inst,name)
		else
			locomotor:SetExternalSpeedMultiplier(inst,name,amount)
		end
	end
end

local old_SetVal = {}

local function AddEscapeDeath(inst,amount,name,bonusname)
	local health = inst.components.health
	local tempbonus = inst.components.temporarybonus
	local taskname = name.."escapedeath"
	if health then
		if amount < 0 then
			if old_SetVal[inst.GUID] and old_SetVal[inst.GUID][name] then
				health.SetVal = old_SetVal[inst.GUID][name]
				old_SetVal[inst.GUID][name] = nil
			end
		else
			if old_SetVal[inst.GUID] == nil then
				old_SetVal[inst.GUID] = {}
			end
			old_SetVal[inst.GUID][name] = health.SetVal or function() end
			health.SetVal = function(self,val,cause,afflicter,...)
				if self.currenthealth > 0 and val <= 0 then
					local a,b,c = inst.Transform:GetWorldPosition()
					local fx = SpawnPrefab("wathgrithr_spirit")
					fx.Transform:SetPosition(a,b,c)
					if amount > 1 then
						local time = tempbonus.current_active_boni[taskname] and tempbonus.current_active_boni[taskname].time or 60
						local time_start = tempbonus.current_active_boni[taskname] and tempbonus.current_active_boni[taskname].starting_time or 0
						local time_left = time - (GetTime() - time_start)
						devprint("escapedeath",time,time_start,time_left,inst["remove_task"..name.."escapedeath"])
						tempbonus:RemoveBonus("escapedeath",name,amount,bonusname)
						tempbonus:AddBonus("escapedeath",name,amount-1,time_left)
					else
						tempbonus:RemoveBonus("escapedeath",name,amount,bonusname)
					end
					health:SetVal(self:GetMaxWithPenalty()/2)
					return
				elseif old_SetVal[inst.GUID][name] then
					old_SetVal[inst.GUID][name](self,val,cause,afflicter,...)
				else
					print("No old_SetVal was found, please report that!")
					dumptable(old_SetVal)
				end
			end
		end
	end
end



local TemporaryBonus = Class(function(self, inst)
    self.inst = inst

    self.bonusfunctions = {
    	health = AddHealth,
    	sanity = AddSanity,
    	hunger = AddHunger,

    	sanityaura = AddSanityAura,
    	hungerrate = AddHungerRate,
    	healthrate = AddHealthRate,

    	damage = AddDamage,
		planardamage = AddPlanarDamage,
    	damagereduction = AddDamageReduction,
		planardefense = AddPlanarDefense,
    	range = AddRange,
		dodge = AddDodge,
		crit = AddCrit,

   		winterinsulation = AddWinterInsulation,
    	summerinsulation = AddSummerInsulation,
		waterproofness = AddWaterproofness,

    	worker = AddWorkingBonus,

    	sleeping = AddSleepingBonus,

    	nightvision = AddNightSight,

    	speed = AddSpeedbonus,

    	escapedeath = AddEscapeDeath,
	}

	self.current_active_boni = {}
	--self.current_active_boni_loaded = {}

	self.current_boni = 0
	self.max_boni = 5
	self.boni_num = {}

	self:Init()

end)

local function getName(self, name, bonus, count)
	if self.current_active_boni[name.."_"..count..bonus] ~= nil then
		return getName(self, name, bonus, count + 1)
	end
	return name.."_"..count
end

local function FindSmallestBonus(self)
	local smallest_name, smallest_val = "", 1000000000000
	local curr_time = GetTime()
	for name, bonus in pairs(self.current_active_boni) do
		local time_passed = curr_time - bonus.starting_time
		local time_left = bonus.time - time_passed
		if time_left < smallest_val then
			smallest_val = time_left
			smallest_name = name
		end
	end
	return smallest_name, self.current_active_boni[smallest_name]
end

local bonus_requirements = {
	dodge = function(inst)
		return not inst.components.attackdodger
	end,
	nightvision = function(inst)
		return not inst.components.temporarybonus:HasBonus("nightvision")
	end
}

function TemporaryBonus:CanAddBonus(bonus)
	if bonus_requirements[bonus] ~= nil then
		return bonus_requirements[bonus](self.inst)
	end
	return true
end

function TemporaryBonus:AddBonus(bonus,name,amount,time)
	devprint("TemporaryBonus:AddBonus",bonus,name,amount,time)
	if not self:CanAddBonus(bonus) then
		print("TemporaryBonus:AddBonus: Tried to add bonus, but requirements were not met", bonus, name, amount, time)
		return
	end
	if time <= 0 then
		print("TemporaryBonus:AddBonus: Tried to add bonus with negative time", bonus, name, amount, time)
		return
	end
	name = name or ""
	if self.current_boni >= self.max_boni then
		print("[TemporaryBonus] Max Amount of Boni was reached! Removing one prior Bonus")
		local bonusname, item = FindSmallestBonus(self)--GetRandomItemWithIndex(self.current_active_boni)
		self:RemoveBonus(item.bonus,item.name,item.amount,bonusname)
		self.inst:DoTaskInTime(0.1,function() self:AddBonus(bonus,name,amount,time) end)
		return
	end
	self.current_boni = self.current_boni + 1
	if self.current_active_boni[name..bonus] ~= nil then
		name = getName(self, name, bonus, 1)
	end
	local bonusname = name..bonus
	local tab = {
		name = name,
		bonus = bonus,
		amount = amount,
		time = time,
		bonusname = bonusname,
		starting_time = GetTime(),
	}
	self.current_active_boni[bonusname] = tab
	table.insert(self.boni_num,bonusname)
	devprint(bonusname)
	local num = #self.boni_num
	if self.bonusfunctions[bonus] ~= nil then
		self.bonusfunctions[bonus](self.inst,tonumber(amount),name, bonusname)
	end
	self.inst["remove_task"..bonusname] = self.inst:DoTaskInTime(time,function()
		devprint("removetask is active", name, bonus, amount,bonusname)
		self:RemoveBonus(bonus,name,amount, bonusname)
	end)
	self.inst:DoTaskInTime(math.random()/2,function()
		if self.inst.userid then
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,bonus.."_"..amount,nil,time)
		end
	end)

end

local function ChangeBoniClient(self,name,num)
	devprint("ChangeBoniClient",name,num)
	if num == nil then
		for k,v in ipairs(self.boni_num) do
			if v == name then
				num = k
				break
			end
		end
	end
	if num == nil then
		print("TemporaryBonus:ChangeBoniClient num is nil",num,name)
		return
	end
	self.boni_num[num] = nil
	if self.boni_num[num+1] ~= nil then
		self.boni_num[num] = self.boni_num[num+1]
		local tab = self.current_active_boni[self.boni_num[num]]
		if tab and self.inst.userid then
			local time_passed = GetTime() - tab.starting_time
			devprint("changing time passed",time_passed, tab.starting_time, GetTime(),  tab.time, tab.time - time_passed, tab.bonus.."_"..tab.amount, num)
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,tab.bonus.."_"..tab.amount, nil, tab.time - time_passed)
			ChangeBoniClient(self,nil,num+1)
		end
	else
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,nil,true)
	end
end


function TemporaryBonus:RemoveBonus(bonus, name, amount, name_bonus)
	devprint("TemporaryBonus:RemoveBonus",bonus, name, amount, name_bonus)
	name_bonus = name_bonus or name..bonus
	local taskname = "remove_task"..name_bonus
	if self.current_active_boni[name_bonus] == nil then return end
	if self.inst[taskname] ~= nil then
		self.inst[taskname]:Cancel()
		self.inst[taskname] = nil
	end
	self.current_boni = self.current_boni - 1
	--local old_name = self.current_active_boni[name..bonus].name
	self.current_active_boni[name_bonus] = nil
	if self.bonusfunctions[bonus] ~= nil then
		self.bonusfunctions[bonus](self.inst,-amount,name)
	end

	local num = 1
	for k,v in ipairs(self.boni_num) do
		if v == name_bonus then
			num = k
			break
		end
	end
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,nil,true)
	ChangeBoniClient(self,name_bonus)

end

function TemporaryBonus:HasBonus(bonus)
	for name, boni in pairs(self.current_active_boni) do
		if boni.bonus == bonus then
			return true
		end
	end
	return false
end

local current_active_boni_loaded = {}

function TemporaryBonus:Init()
	self.inst:DoTaskInTime(3,function()
		devprint("TemporaryBonus:Init")
		devdumptable(current_active_boni_loaded)
		if current_active_boni_loaded[self.inst.userid] ~= nil then
			for _,v in pairs(current_active_boni_loaded[self.inst.userid]) do
				if v.time > 5 then
					self:AddBonus(v.bonus,v.name,v.amount,v.time)
				end
			end
			current_active_boni_loaded[self.inst.userid] = nil
		end
	end)
end

function TemporaryBonus:OnSave()
	local data = {}
	data.current_active_boni = {}
	for k,v in pairs(self.current_active_boni) do
		local time_passed = GetTime() - v.starting_time
		v.time = v.time - time_passed
		data.current_active_boni[k] = v
	end
	devprint("TemporaryBonus save")
	devdumptable(data)
	return data
end

function TemporaryBonus:OnLoad(data)
	if data.current_active_boni ~= nil and next(data.current_active_boni) ~= nil then
		devprint("TemporaryBonus:OnLoad")
		devdumptable(data.current_active_boni)
		local userid = self.inst.userid or 1
		current_active_boni_loaded[userid] = {}
		for k,v in pairs(data.current_active_boni) do
			current_active_boni_loaded[userid][k] = v
		end
	end
end

return TemporaryBonus