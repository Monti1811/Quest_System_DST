local LevelUpComponent = Class(function(self, inst)
    self.inst = inst

    self.level = 1
    self.bonus = {
    	healthbonus = 0,
	    sanitybonus = 0,
	    hungerbonus = 0,
	    speedbonus = 0,
	    summerinsulationbonus = 0,
	    winterinsulationbonus = 0,
	    workmultiplierbonus = {
	    	["ACTIONS.CHOP"] = 1,
	    	["ACTIONS.DIG"]= 1,
	    	["ACTIONS.HAMMER"] = 1,
	    	["ACTIONS.MINE"] = 1,
		},

	}

	self.leveluprate = {
		healthbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    sanitybonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    hungerbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    speedbonus = 0.005 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    summerinsulationbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    winterinsulationbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    workmultiplierbonus = {
	    	["ACTIONS.CHOP"] = 0.002 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    	["ACTIONS.DIG"] = 0.002 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    	["ACTIONS.HAMMER"] = 0.002 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
	    	["ACTIONS.MINE"] = 0.002 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		},

	}

	self:Init()

end)

function LevelUpComponent:SetValues()
	if self.inst.components.health then
		local old_health = self.inst.components.health.maxhealth
		local old_percent = self.inst.components.health:GetPercent()
		self.inst.components.health:SetMaxHealth(old_health + self.bonus.healthbonus)
		self.inst.components.health:SetPercent(old_percent)
	end

	if self.inst.components.hunger then
		local old_hunger = self.inst.components.hunger.max
		local old_percent = self.inst.components.hunger:GetPercent()
		self.inst.components.hunger:SetMax(old_hunger + self.bonus.hungerbonus)
		self.inst.components.hunger:SetPercent(old_percent)
	end

	if self.inst.components.sanity then
		local old_sanity = self.inst.components.sanity.max
		local old_percent = self.inst.components.sanity:GetPercent()
		self.inst.components.sanity:SetMax(old_sanity + self.bonus.sanitybonus)
		self.inst.components.sanity:SetPercent(old_percent)
	end

	if self.inst.components.temperature then
		local old_summerinsulation = self.inst.components.temperature.inherentsummerinsulation
		self.inst.components.temperature.inherentsummerinsulation = old_summerinsulation + self.bonus.summerinsulationbonus
		local old_winterinsulation = self.inst.components.temperature.inherentinsulation
		self.inst.components.temperature.inherentinsulation = old_winterinsulation + self.bonus.winterinsulationbonus
	end

	if self.inst.components.locomotor then
		self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "levelupcomponent", 1 + self.bonus.speedbonus)
	end

	if self.inst.components.workmultiplier then
		for k,v in pairs(self.bonus.workmultiplierbonus) do
			self.inst.components.workmultiplier:AddMultiplier(k,v,self.inst)
		end
	end
end

function LevelUpComponent:RemoveValues()
	if self.inst.components.health then
		local old_health = self.inst.components.health.maxhealth
		local old_percent = self.inst.components.health:GetPercent()
		self.inst.components.health:SetMaxHealth(old_health - self.bonus.healthbonus)
		self.inst.components.health:SetPercent(old_percent)
	end

	if self.inst.components.hunger then
		local old_hunger = self.inst.components.hunger.max
		local old_percent = self.inst.components.hunger:GetPercent()
		self.inst.components.hunger:SetMax(old_hunger - self.bonus.hungerbonus)
		self.inst.components.hunger:SetPercent(old_percent)
	end

	if self.inst.components.sanity then
		local old_sanity = self.inst.components.sanity.max
		local old_percent = self.inst.components.sanity:GetPercent()
		self.inst.components.sanity:SetMax(old_sanity - self.bonus.sanitybonus)
		self.inst.components.sanity:SetPercent(old_percent)
	end

	if self.inst.components.temperature then
		local old_summerinsulation = self.inst.components.temperature.inherentsummerinsulation
		self.inst.components.temperature.inherentsummerinsulation = old_summerinsulation - self.bonus.summerinsulationbonus
		local old_winterinsulation = self.inst.components.temperature.inherentinsulation
		self.inst.components.temperature.inherentinsulation = old_winterinsulation - self.bonus.winterinsulationbonus
	end

	if self.inst.components.locomotor then
		self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "levelupcomponent")
	end

	if self.inst.components.workmultiplier then
		for k,v in pairs(self.bonus.workmultiplierbonus) do
			self.inst.components.workmultiplier:RemoveMultiplier(k,self.inst)
		end
	end
end

function LevelUpComponent:OnLevelUp(level)
	level = level or 1
	self:RemoveValues()
	for k,v in pairs(self.bonus) do
		if type(v) == "table" then
			for kk,vv in pairs(v) do
				self.bonus[k][kk] = vv - self.leveluprate[k][kk] * level
			end
			self.inst.q_system[k]:set(self.bonus[k]["ACTIONS.CHOP"])
		else
			self.bonus[k] = v + self.leveluprate[k] * level
			self.inst.q_system[k]:set(self.bonus[k])
		end
	end
	self:SetValues()
end

function LevelUpComponent:Init()
	self.inst:DoTaskInTime(1.1,function()
		if self.inst.components.quest_component then
			self.level = self.inst.components.quest_component.level
		end
		self:OnLevelUp(self.level - 1)
	end)
end

function LevelUpComponent:OnSave()
	--[[local data = {}
	--data.bonus = self.bonus
	return data]]
end

function LevelUpComponent:OnLoad(data)
	--[[if data then
		if data.bonus ~= nil then
			--self.bonus = data.bonus
		end
	end]]
end


return LevelUpComponent