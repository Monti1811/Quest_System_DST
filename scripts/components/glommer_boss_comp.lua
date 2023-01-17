

local Glommer_Boss_Comp = Class(function(self,inst)

	self.inst = inst

	self.glommers = {}
	self.amount = 20
	self.max_amount = 20

	--self.chester = nil
	--self.glommer_boss = nil

	self.ondeath = function()
		self:OnDeath()
	end

	self:Init()

	self._OnTimerDone = function(_,data)
		devprint("timerdone",data.name)
		if data and data.name == "remove_bosses" then
			for _,v in pairs(self.glommers) do
				if v:IsValid() then
					v.sg:GoToState("flyaway")
				end
			end
			if self.chester and self.chester:IsValid() then
				self.chester:Remove()
			end
			if self.glommer_boss and self.glommer_boss:IsValid() then
				self.glommer_boss.sg:GoToState("flyaway")
			end
			self.inst:DoTaskInTime(1,function()
				if self.glommerboss_spawntask ~= nil then
					self.glommerboss_spawntask:Cancel()
					self.glommerboss_spawntask = nil
				end 
			end)
		end
	end

	self.inst:ListenForEvent("timerdone",self._OnTimerDone)

	local function OnBossesDead()
		--print("OnBossesDead")
		if next(self.glommers) == nil and self.chester == nil then
			--print("remove timer")
			self.inst.components.timer:StopTimer("remove_bosses")
		end
	end

	self.inst:ListenForEvent("chesterboss_was_killed",OnBossesDead)
	self.inst:ListenForEvent("glommerboss_was_killed",OnBossesDead)

end)

function Glommer_Boss_Comp:Init()
	self.inst:DoTaskInTime(1,function()
		if next(self.glommers) ~= nil then
			self:ApplyAmountChanges()
		end
	end)
end

local function GetSpawnPoint(pt,radius)
    local theta = math.random() * 2 * PI
    radius = radius or math.random(6,14)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

function Glommer_Boss_Comp:StartBossfight(target)
	devprint("Glommer_Boss_Comp:StartBossfight",target,self.amount)
	local target_pos = Point(target.Transform:GetWorldPosition())
	self.amount = self.max_amount
	for _ = 1,self.max_amount do
		local glommer = SpawnPrefab("glommer_small")
		table.insert(self.glommers,glommer)
		local pos = GetSpawnPoint(target_pos) or target_pos
		glommer.Transform:SetPosition(pos:Get())
		local fx = SpawnPrefab("small_puff")
		fx.Transform:SetPosition(pos:Get())
		self:ApplyAmountChanges()
	end
	self.inst.components.timer:StartTimer("remove_bosses",11*480)	--11 days till they will be removed
	devdumptable(self.glommers)
	--print(self.chester)
	--print("amount",self.amount)
end

function Glommer_Boss_Comp:OnDeath(glommer,pos)
	devprint("Glommer_Boss_Comp:OnDeath",glommer,pos)
	self.amount = self.amount - 1 
	if self.amount <= 0 then
		self.spawning_glommer_boss = pos
		self.glommerboss_spawntask = self.inst:DoTaskInTime(5,function()
			self:SpawnBossGlommer(pos)
			self.spawning_glommer_boss = nil
		end)
	else
		self:ApplyAmountChanges()
	end
end

function Glommer_Boss_Comp:SpawnBossGlommer(pos)
	devprint("Glommer_Boss_Comp:SpawnBossGlommer",pos)
	pos = GetSpawnPoint(pos,6) or pos or Point(0,0,0)
	local glommer_boss = SpawnPrefab("glommer_boss")
	self.glommer_boss = glommer_boss
	if glommer_boss then
		glommer_boss.Transform:SetPosition(pos.x,15,pos.z)
		glommer_boss.sg:GoToState("fly_towards") 
	end
end

function Glommer_Boss_Comp:ApplyAmountChanges()
	--print("Glommer_Boss_Comp:ApplyAmountChanges",self.amount)
	local dmg = 100
	local sc = 1.5 - 1/self.max_amount * self.amount
	local damage = dmg - (dmg-dmg/self.max_amount)/self.max_amount*self.amount
	local health = 33 + 633*math.pow((1-(self.amount-1)/self.max_amount),2)	--666 - (666-666/self.max_amount)/self.max_amount * self.amount
	local speed = 10 - 0.3 * self.amount
	for _,glommer in pairs(self.glommers) do
		glommer.net_size:set(sc)
		glommer.components.combat:SetDefaultDamage(damage)
		glommer.components.locomotor.walkspeed = speed
		local old_percent = glommer.components.health:GetPercent()
		glommer.components.health:SetMaxHealth(health)
		glommer.components.health:SetPercent(old_percent)
		glommer._amount = self.amount
	end
end

function Glommer_Boss_Comp:OnLoad(data)
	if data then
		if data.amount then
			self.amount = data.amount
		end
	end
end

function Glommer_Boss_Comp:OnSave()
	local data = {}
	local glommers = {}
	for _,v in pairs(self.glommers) do
		table.insert(glommers,v.GUID)
    end
    data.spawning_glommer_boss = self.spawning_glommer_boss
    data.glommers = glommers
    data.amount = self.amount
    if self.chester then
    	table.insert(glommers,self.chester.GUID)
    end
    if self.glommer_boss then
    	table.insert(glommers,self.glommer_boss.GUID)
    end
	return data,glommers
end

function Glommer_Boss_Comp:OnLoad(data)
	if data then
		if data.spawning_glommer_boss then
			self.inst:DoTaskInTime(10,function()
				self:SpawnBossGlommer(data.spawning_glommer_boss)
			end)
		end
		if data.amount then
			self.amount = data.amount
		end
	end
end

function Glommer_Boss_Comp:LoadPostPass(newents, savedata)
	if savedata ~= nil then
		if savedata.glommers ~= nil then
            for _,v in pairs(savedata.glommers) do
                local targ = newents[v]
                if targ ~= nil and targ.entity then
                	if targ.entity.prefab == "chester_boss" then
	                	self.chester = targ.entity
	                elseif targ.entity.prefab == "glommer_boss" then
	                	self.glommer_boss = targ.entity
	                else
	                	table.insert(self.glommers,targ.entity)
	                end
                end
            end
        end
    end
end

return Glommer_Boss_Comp