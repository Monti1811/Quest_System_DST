local workmultiplier_actions = {
	ACTIONS.CHOP,
	ACTIONS.DIG,
	ACTIONS.HAMMER,
	ACTIONS.MINE,
}

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
		workmultiplierbonus = {},

	}

	self.leveluprate = {
		healthbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		sanitybonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		hungerbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		speedbonus = 0.005 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		summerinsulationbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		winterinsulationbonus = 1 * TUNING.QUEST_COMPONENT.LEVELUPRATE,
		workmultiplierbonus = {},
	}

	for _, action in ipairs(workmultiplier_actions) do
		self.bonus.workmultiplierbonus[action] = 1
		self.leveluprate.workmultiplierbonus[action] = 0.08 * TUNING.QUEST_COMPONENT.LEVELUPRATE
	end

	self:Init()

end)

function LevelUpComponent:SetValues()
	local health = self.inst.components.health
	if health then
		local old_health = health.maxhealth
		local old_percent = health:GetPercent()
		health:SetMaxHealth(old_health + self.bonus.healthbonus)
		health:SetPercent(old_percent)
	end

	local hunger = self.inst.components.hunger
	if hunger then
		local old_hunger =hunger.max
		local old_percent = hunger:GetPercent()
		hunger:SetMax(old_hunger + self.bonus.hungerbonus)
		hunger:SetPercent(old_percent)
	end

	local sanity = self.inst.components.sanity
	if sanity then
		local old_sanity = sanity.max
		local old_percent = sanity:GetPercent()
		sanity:SetMax(old_sanity + self.bonus.sanitybonus)
		sanity:SetPercent(old_percent)
	end

	local temperature = self.inst.components.temperature
	if temperature then
		local old_summerinsulation = temperature.inherentsummerinsulation
		temperature.inherentsummerinsulation = old_summerinsulation + self.bonus.summerinsulationbonus
		local old_winterinsulation =temperature.inherentinsulation
		temperature.inherentinsulation = old_winterinsulation + self.bonus.winterinsulationbonus
	end

	local locomotor = self.inst.components.locomotor
	if locomotor then
		locomotor:SetExternalSpeedMultiplier(self.inst, "levelupcomponent", 1 + self.bonus.speedbonus)
	end

	local workmultiplier = self.inst.components.workmultiplier
	if workmultiplier then
		for k,v in pairs(self.bonus.workmultiplierbonus) do
			workmultiplier:AddMultiplier(k,v,self.inst)
		end
	end
end

function LevelUpComponent:RemoveValues()
	local health = self.inst.components.health
	if health then
		local old_health = health.maxhealth
		local old_percent = health:GetPercent()
		health:SetMaxHealth(old_health - self.bonus.healthbonus)
		health:SetPercent(old_percent)
	end

	local hunger = self.inst.components.hunger
	if hunger then
		local old_hunger = hunger.max
		local old_percent = hunger:GetPercent()
		hunger:SetMax(old_hunger - self.bonus.hungerbonus)
		hunger:SetPercent(old_percent)
	end

	local sanity = self.inst.components.sanity
	if sanity then
		local old_sanity = sanity.max
		local old_percent = sanity:GetPercent()
		sanity:SetMax(old_sanity - self.bonus.sanitybonus)
		sanity:SetPercent(old_percent)
	end

	local temperature = self.inst.components.temperature
	if temperature then
		local old_summerinsulation = temperature.inherentsummerinsulation
		temperature.inherentsummerinsulation = old_summerinsulation - self.bonus.summerinsulationbonus
		local old_winterinsulation = temperature.inherentinsulation
		temperature.inherentinsulation = old_winterinsulation - self.bonus.winterinsulationbonus
	end

	local locomotor = self.inst.components.locomotor
	if locomotor then
		locomotor:RemoveExternalSpeedMultiplier(self.inst, "levelupcomponent")
	end

	local workmultiplier = self.inst.components.workmultiplier
	if workmultiplier then
		for k in pairs(self.bonus.workmultiplierbonus) do
			workmultiplier:RemoveMultiplier(k,self.inst)
		end
	end
end

function LevelUpComponent:OnLevelUp(level)
	level = level or 1
	self:RemoveValues()
	for k,v in pairs(self.bonus) do
		if type(v) == "table" then
			for kk,vv in pairs(v) do
				self.bonus[k][kk] = vv + self.leveluprate[k][kk] * level
			end
			self.inst.q_system[k]:set(self.bonus[k][ACTIONS.CHOP])
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

--[[

function LevelUpComponent:OnSave()
	local data = {}
	--data.bonus = self.bonus
	return data
end

function LevelUpComponent:OnLoad(data)
	if data then
		if data.bonus ~= nil then
			--self.bonus = data.bonus
		end
	end
end
]]

return LevelUpComponent