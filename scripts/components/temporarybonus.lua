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
		if amount < 0 then
			if inst.temp_sanityaura ~= nil then
				inst.temp_sanityaura:Cancel()
				inst.temp_sanityaura = nil
			end
		else
			inst.temp_sanityaura = inst:DoPeriodicTask(0.5,function()
				if inst.components.sanity then
					inst.components.sanity:DoDelta(amount/60)
				end
			end)
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
	if inst.components.health then
		if amount < 0 then
			if inst["healtask_"..name] ~= nil then
				inst["healtask_"..name]:Cancel()
				inst["healtask_"..name] = nil
			end
		else
			amount = inst.prefab == "wanda" and amount * TUNING.OLDAGE_HEALTH_SCALE or amount
			inst["healtask_"..name] = inst:DoPeriodicTask(10,function() 
				if inst.components.health and not inst.components.health:IsDead() then
					inst.components.health:DoDelta(amount)
				end
			end)
		end
	end
end

local function AddDamage(inst,amount)
	if inst.components.combat then
		local old_damage = inst.components.combat.defaultdamage
		inst.components.combat:SetDefaultDamage(old_damage + amount)
	end
end

local function AddDamageReduction(inst,amount,name)
	if inst.components.combat then
		if amount < 0 then
			inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst,name)
		else
			inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst,amount,name)
		end		
	end
end

local function AddRange(inst,amount)
	if inst.components.combat then
		local old_attackrange = inst.components.combat.attackrange
		local old_hitrange = inst.components.combat.hitrange
		inst.components.combat.attackrange = old_attackrange + amount
		inst.components.combat.hitrange = old_hitrange + amount
	end
end


local function AddWinterInsulation(inst,amount)
	if inst.components.temperature then
		local old_insulation = inst.components.temperature.inherentinsulation
		inst.components.temperature.inherentinsulation = old_insulation + amount
	end
end

local function AddSummerInsulation(inst,amount)
	if inst.components.temperature then
		local old_insulation = inst.components.temperature.inherentsummerinsulation
		inst.components.temperature.inherentsummerinsulation = old_insulation + amount
	end
end

local actions = {
	ACTIONS.CHOP,
	ACTIONS.MINE,
	ACTIONS.HAMMER,
}

local function AddWorkingBonus(inst,amount)
	if inst.components.workmultiplier ~= nil then
		if amount < 0 then
			for _,v in ipairs(actions) do
				inst.components.workmultiplier:RemoveMultiplier(v,inst)
			end
		else
			for _,v in ipairs(actions) do
				inst.components.workmultiplier:AddMultiplier(v,amount,inst)
			end
		end
	end
end

local sleepboni = {"hunger_bonus_mult","health_bonus_mult"}

local function AddSleepingBonus(inst,amount)
	if inst.components.sleepingbaguser then
		for _,v in ipairs(sleepboni) do
			local old = inst.components.sleepingbaguser[v]
			inst.components.sleepingbaguser[v] = old + amount
		end
	end
end

local function AddNightSight(inst,amount)
	if inst.components.playervision then
		if amount < 0 then
			inst.components.playervision:ForceNightVision(false)
			if inst.net_nightvisiontrigger then
				inst.net_nightvisiontrigger:set(false)
			end
		else
			inst.components.playervision:ForceNightVision(true)
			if inst.net_nightvisiontrigger then
				inst.net_nightvisiontrigger:set(true)
			end
		end
	end
end

local function AddSpeedbonus(inst,amount,name)
	if inst.components.locomotor then
		if amount < 0 then
			inst.components.locomotor:RemoveExternalSpeedMultiplier(inst,name)
		else
			inst.components.locomotor:SetExternalSpeedMultiplier(inst,name,amount)
		end		
	end
end

local old_SetVal = {}

local function AddEscapeDeath(inst,amount,name)
	if inst.components.health then
		if amount < 0 then
			if old_SetVal[inst.GUID] and old_SetVal[inst.GUID][name] then
				inst.components.health.SetVal = old_SetVal[inst.GUID][name]
				old_SetVal[inst.GUID][name] = nil
			end
		else
			if old_SetVal[inst.GUID] == nil then
				old_SetVal[inst.GUID] = {}
			end
			old_SetVal[inst.GUID][name] = inst.components.health.SetVal or function() end
			inst.components.health.SetVal = function(self,val,cause,afflicter,...)
				if self.currenthealth > 0 and val <= 0 then
					local a,b,c = inst.Transform:GetWorldPosition()
					local fx = SpawnPrefab("wathgrithr_spirit")
					fx.Transform:SetPosition(a,b,c)
					if amount > 1 then
						local tempbonus = inst.components.temporarybonus
						local time = tempbonus.current_active_boni[name.."escapedeath"] and tempbonus.current_active_boni[name.."escapedeath"].time or 60
						local time_start = tempbonus.current_active_boni[name.."escapedeath"] and tempbonus.current_active_boni[name.."escapedeath"].starting_time or 0
						local time_left = time - (GetTime() - time_start)
						devprint("escapedeath",time,time_start,time_left,inst["remove_task"..name])
						inst.components.temporarybonus:RemoveBonus("escapedeath",name,amount)
						inst.components.temporarybonus:AddBonus("escapedeath",name,amount-1,time_left)
					else
						inst.components.temporarybonus:RemoveBonus("escapedeath",name,amount)
					end
					inst.components.health:SetVal(self:GetMaxWithPenalty()/2)
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
    	damagereduction = AddDamageReduction,
    	range = AddRange,

   		winterinsulation = AddWinterInsulation,
    	summerinsulation = AddSummerInsulation,

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


function TemporaryBonus:AddBonus(bonus,name,amount,time)
	devprint("TemporaryBonus:AddBonus",bonus,name,amount,time)
	name = name or ""
	if self.current_boni >= self.max_boni then
		print("[TemporaryBonus] Max Amount of Boni was reached! Removing one prior Bonus")
		local _,item = GetRandomItemWithIndex(self.current_active_boni)
		self:RemoveBonus(item.bonus,item.name,item.amount)
		self.inst:DoTaskInTime(0.1,function() self:AddBonus(bonus,name,amount,time) end)	
		return	
	end
	self.current_boni = self.current_boni + 1
	if self.current_active_boni[name..bonus] ~= nil then
		name = name.."_1"
	end
	local tab = {
		name = name,
		bonus = bonus,
		amount = amount,
		time = time,
		starting_time = GetTime(),
	}
	self.current_active_boni[name..bonus] = tab
	table.insert(self.boni_num,name..bonus)
	devprint(name..bonus)
	local num = #self.boni_num
	if self.bonusfunctions[bonus] ~= nil then
		self.bonusfunctions[bonus](self.inst,tonumber(amount),name)
	end
	self.inst["remove_task"..name] = self.inst:DoTaskInTime(time,function()
		self:RemoveBonus(bonus,name,amount)
	end)
	self.inst:DoTaskInTime(1+math.random()/2,function()
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
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,tab.bonus.."_"..tab.amount, nil, tab.time - time_passed)
			ChangeBoniClient(self,nil,num+1)
		end
	else
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,nil,true)
	end
end


function TemporaryBonus:RemoveBonus(bonus,name,amount)
	devprint("TemporaryBonus:RemoveBonus",bonus,name,amount)
	if self.current_active_boni[name..bonus] == nil then return end
	if self.inst["remove_task"..name] ~= nil then
		self.inst["remove_task"..name]:Cancel()
		self.inst["remove_task"..name] = nil
	end
	self.current_boni = self.current_boni - 1
	--local old_name = self.current_active_boni[name..bonus].name
	self.current_active_boni[name..bonus] = nil
	if self.bonusfunctions[bonus] ~= nil then
		self.bonusfunctions[bonus](self.inst,-amount,name)
	end

	local num = 1
	for k,v in ipairs(self.boni_num) do
		if v == name..bonus then 
			num = k
			break
		end
	end
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTempBoniToClient"),self.inst.userid,self.inst,num,nil,true)
	ChangeBoniClient(self,name..bonus)
	
end

local current_active_boni_loaded = {}

function TemporaryBonus:Init()
	self.inst:DoTaskInTime(1,function()
		devdumptable(current_active_boni_loaded)
		for _,v in pairs(current_active_boni_loaded) do
			if v.time > 0 then
				self:AddBonus(v.bonus,v.name,v.amount,v.time)
			end
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
	--print("TemporaryBonus save")
	--dumptable(data)
	return data
end

function TemporaryBonus:OnLoad(data)
	if data.current_active_boni ~= nil and next(data.current_active_boni) ~= nil then
		devdumptable(data.current_active_boni)
		for k,v in pairs(data.current_active_boni) do
			current_active_boni_loaded[k] = v
		end
	end
end

return TemporaryBonus