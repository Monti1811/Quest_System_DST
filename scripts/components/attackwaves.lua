local STRINGS_AW = STRINGS.QUEST_COMPONENT.ATTACKWAVES

local function PurgeSavedValues(self,player,victim)
	local tables = {"attack_rounds","current_victims","difficulty", "attack_num", "current_attacking_creatures","release_spawns",}
	devprint("PurgeSavedValues")
	if victim then
		for _,tab in ipairs(tables) do
			self[tab][player.userid][victim] = nil
		end
	else
		for _,tab in ipairs(tables) do
			self[tab][player.userid] = nil
		end
	end
end

local function MakeTables(self,userid,victim)
	local tables = {"current_attacking_creatures",}
	for _,tab in ipairs(tables) do
		if self[tab][userid] == nil then
			self[tab][userid] = {}
		end
		self[tab][userid][victim] = {}
	end
	local tables2 = {"talk_task","DoAttackWave_task","attack_rounds","players","attack_num","release_spawns","difficulty",}
	for _,tab in ipairs(tables2) do
		if self[tab][userid] == nil then
			self[tab][userid] = {}
		end
	end
end

local function isSummer()
	return TheWorld.state.season == "summer" or TheWorld.state.season == "autumn"
end

local function StopBrainStalkerMinion(inst)
	devprint("StopBrainStalkerMinion")
	inst:StopBrain()
	inst:SetBrain(nil)
	inst.components.timer:StopTimer("selfdestruct")
	inst.OnEntitySleep = nil
end

local function StopBrain(inst)
	devprint("StopBrain")
	inst:StopBrain()
	inst:SetBrain(nil)
end

local AttackWaves = Class(function(self,inst)
	self.inst = inst
	self.attacking_creatures = {
		{"killerbee","frog","spider","bat","hedgehound","beeguard"
		--"mosquito"
		},
		{"hound",function() return isSummer() and "firehound" or "icehound" end,},--"beeguard",--"spider_water","mutatedhound","eyeofterror_mini","slurper","molebat"},
		{"bunnyman","spider_warrior","spider_hider","spider_spitter","spider_moon","powder_monkey","spider_healer"},
		{"walrus","grassgator","beefalo","worm","merm","pigman","krampus","prime_mate",},
		{"bishop","rook","knight","leif",function() return isSummer() and "koalefant_summer" or "koalefant_winter" end,"warglet", --[["rocky",]]},	--rocky is too strong I think, takes too much time to kill
	}
	self.current_attacking_creatures = {}
	self.attack_num = {}
	self.attack_rounds = {}
	self.difficulty = {}
	self.talk_task = {}
	self.DoAttackWave_task = {}

	self.victims = {
		glommer = true,
		butterfly = StopBrain,
		moonbutterfly = true,
		dustmoth = true,
		stalker_minion1 = StopBrainStalkerMinion,
		stalker_minion2 = StopBrainStalkerMinion,
		chester = true,
		hutch = true,
	}
	self.current_victims = {}
	self.release_spawns = {}
	self.players = {}


	self._onplayerleft = function(_,player)
		if player == nil then return end
		devprint("ms_playerleft",self.current_victims[player.userid])
		if self.players[player.userid] ~= nil then
			if self.current_victims[player.userid] ~= nil then
				for _,v in ipairs(self.players[player.userid]) do
					if self.current_victims[player.userid][v] then
						self.current_victims[player.userid][v]:Remove()
					end
				end
			end
			self:StopAllAttacks(player)
		end
	end
	self.inst:ListenForEvent("ms_playerleft",self._onplayerleft)
end)

local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function GetSpawnPoint(pt)
	if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
		pt = FindNearbyLand(pt, 1) or pt
	end
	local offset = FindWalkableOffset(pt, math.random() * 2 * PI,  12, 12, true, true, NoHoles)
	if offset ~= nil then
		offset.x = offset.x + pt.x
		offset.z = offset.z + pt.z
		return offset
	end
end

local function SummonSpawn(self,pt,difficulty)
	devprint("SummonSpawn",pt,difficulty)
	difficulty = type(difficulty) == "number" and difficulty or 1
    local spawn_pt = GetSpawnPoint(pt)
    if spawn_pt ~= nil then
		local list = self.attacking_creatures[difficulty] or {}
    	local prefab = FunctionOrValue(list[math.random(#list)]) or "hound"
        local spawn = SpawnPrefab(prefab)
        if spawn ~= nil then
            spawn.Physics:Teleport(spawn_pt:Get())
            spawn:FacePoint(pt)
            SpawnPrefab("shadow_puff_large_front").Transform:SetPosition(spawn_pt:Get())
            if spawn.components.spawnfader ~= nil then
                spawn.components.spawnfader:FadeIn()
            end
            return spawn
        end
    end
end

local function ReleaseSpawn(self,target,difficulty)
	devprint("ReleaseSpawn",target,difficulty)
	if target and target.components.health and not target.components.health:IsDead() then
	    local spawn = SummonSpawn(self,target:GetPosition(),difficulty)
	    devprint("spawn",spawn)
	    if spawn ~= nil then
	        spawn.components.combat:SetTarget(target)
	        return spawn
	    end
	end
    return nil
end

--local loots = {"lootsetupfn","numrandomloot","chanceloot","chanceloottable","ifnotchanceloot","loot",}

function AttackWaves:ReleaseSpawnAfterTime(player,target,delta,attacksize)
	devprint("ReleaseSpawnAfterTime",target,delta,attacksize)
	local prefab = target.prefab
	local release_spawns = self.release_spawns[player.userid]
	local attack_num = self.attack_num[player.userid]
	local attack_rounds = self.attack_rounds[player.userid]
	local current_attacking_creatures = self.current_attacking_creatures[player.userid]
	local difficulty = self.difficulty[player.userid][prefab]

	if release_spawns[prefab] ~= nil then
		release_spawns[prefab]:Cancel()
		release_spawns[prefab] = nil
	end

	for creature in pairs(current_attacking_creatures[prefab]) do
		if creature.components.combat then
			creature.components.combat:SetTarget(target)
		end
	end

	if attack_num[prefab] >= attacksize[1] then
		if next(current_attacking_creatures[prefab]) == nil then
			attack_num[prefab] = 0
			attack_rounds[prefab] = attack_rounds[prefab] + 1
			release_spawns[prefab] = self.inst:DoTaskInTime(5, function() self:DoAttackWave(player,target,attacksize,delta) end)
			return
		else
			release_spawns[prefab] = self.inst:DoTaskInTime(5,function()
				self:ReleaseSpawnAfterTime(player,target,delta,attacksize)
			end)
			return
		end
	end

	local time = delta * (math.random(50,150) / 100)
	local spawn = ReleaseSpawn(self,target,difficulty)
	if spawn == nil then print("[Attackwaves] Something broke, the spawn is nil",spawn,target) return end
	current_attacking_creatures[prefab][spawn] = true
	spawn:ListenForEvent("death", function()
		if current_attacking_creatures[prefab] then
			current_attacking_creatures[prefab][spawn] = nil
		end
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "ChangeEnemiesDefeated"),player.userid,player,target.prefab)
	end)
	--Remove the loot of the spawned enemies
	--[[if spawn.components.lootdropper ~= nil then
		for k,v in ipairs(loots) do
			spawn.components.lootdropper[v] = nil
		end
	end]]

	attack_num[prefab] = attack_num[prefab] + 1
	release_spawns[prefab] = self.inst:DoTaskInTime(time,function()
		self:ReleaseSpawnAfterTime(player,target,delta,attacksize) 
	end)
end


function AttackWaves:StartAttack(player,attacksize,delta,difficulty,_victim)
	if player == nil or _victim == nil then
		print("[Attackwaves] Victim or player was nil",player,attacksize,delta,difficulty,_victim)
		return
	end
	devprint("StartAttack",player,attacksize,delta,difficulty)
	local pos = Vector3(player.Transform:GetWorldPosition())
	local new_pos = FindWalkableOffset(pos,math.random()*PI*2,20,8,true,false)
	local prefab = _victim or GetRandomItemWithIndex(self.victims)
	local victim = SpawnPrefab(prefab)
	if victim == nil then
		print("[Attackwaves] The Victim could not be spawned",victim,_victim,prefab)
		return
	end
	MakeTables(self,player.userid,_victim)
	difficulty = difficulty or 1 --difficulty is 1 to 5
	self.difficulty[player.userid][_victim] = difficulty
	self.current_victims[player.userid] = victim
	local health = victim.components.health
	if health then
		health.maxhealth = 200 + 200 * (difficulty-1)
		health:SetPercent(1)
		health:StopRegen()
	end
	if self.victims[prefab] ~= nil and type(self.victims[prefab]) == "function" then
		self.victims[prefab](victim)
	end
	victim.persists = false
	victim.Transform:SetPosition(pos.x+new_pos.x,pos.y+new_pos.y,pos.z+new_pos.z)
	if victim.components.combat then
		local old_onkill = victim.components.combat.onkilledbyother or function() end
		victim.components.combat.onkilledbyother = function(inst,attacker,...)
			player:PushEvent("victim_died",victim.prefab)
			player.components.talker:Say(STRINGS_AW.MISSION_FAILED)
			self:StopAttacks(player,victim.prefab)
			return unpack({old_onkill(inst,attacker,...)})
		end
		victim.components.combat:SetDefaultDamage(0)
	end
	victim:AddTag("is_attackwave_victim")

	if player.components.talker then
		player.components.talker:Say(string.format(STRINGS_AW.MISSION_OBJECTIVE,STRINGS.NAMES[string.upper(victim.prefab)] or "this creature"))
	end

	self.attack_num[player.userid][_victim] = 0
	self.attack_rounds[player.userid][_victim] = 0
	table.insert(self.players[player.userid],_victim)

	self:DoAttackWave(player,victim,attacksize,delta)
	
end


function AttackWaves:DoAttackWave(player,target,attacksize,delta)
	devprint("DoAttackWave",player,target,attacksize,delta)
	local attack_round = self.attack_rounds[player.userid][target.prefab]
	local current_attacking_creatures = self.current_attacking_creatures[player.userid]
	if attack_round >= attacksize[2] then
		if next(current_attacking_creatures[target.prefab]) == nil then
			player:PushEvent("succesfully_defended")
			player.components.talker:Say(STRINGS_AW.MISSION_SUCCESS)
			SpawnPrefab("shadow_puff_large_front").Transform:SetPosition(self.current_victims[player.userid]:GetPosition():Get())
			self.current_victims[player.userid]:Remove()
			PurgeSavedValues(self,player,target.prefab)
			return
		else
			for creature in pairs(current_attacking_creatures[target.prefab]) do
				if creature.components.combat then
					--print("setting target",v,target)
					creature.components.combat:SetTarget(target)
				end
			end
			self.DoAttackWave_task[player.userid][target.prefab] = self.inst:DoTaskInTime(5,function() self:DoAttackWave(player,target,attacksize,delta) end)
			return
		end
	end
	devprint("AddTimerToClient send",player.userid,player,attacksize[1],target.prefab,attack_round)
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTimerToClient"),player.userid,player,attacksize[1],target.prefab,attack_round+1)
	self.talk_task[player.userid][target.prefab] = player:DoTaskInTime(2,function() player.components.talker:Say("Start of Wave "..((attack_round or 0) + 1)) end)
	self:ReleaseSpawnAfterTime(player,target,delta,attacksize)
end

local tasks_to_stop = {
	"talk_task",
	"DoAttackWave_task",
}

function AttackWaves:StopAttacks(player,victim)
	local release_spawns = self.release_spawns[player.userid]
	local current_attacking_creatures = self.current_attacking_creatures[player.userid]
	devprint("AttackWaves:StopAttacks",player,victim,release_spawns[victim])
	if release_spawns[victim] ~= nil then
		release_spawns[victim]:Cancel()
		release_spawns[victim] = nil
	end
	for _,v in ipairs(tasks_to_stop) do
		local task = self[v][player.userid]
		if task[victim] ~= nil then
			task[victim]:Cancel()
			task[victim] = nil
		end
	end
	devdumptable(current_attacking_creatures)
	if current_attacking_creatures[victim] == nil then return end
	for creature in pairs(current_attacking_creatures[victim]) do
		if creature:IsValid() then
			--if v.components.health then
			--v.components.health:Kill()
			--else
			creature:Remove()
			--end
		end
	end
	PurgeSavedValues(self,player,victim)
end

function AttackWaves:StopAllAttacks(player)
	local release_spawns = self.release_spawns[player.userid] or {}
	local current_attacking_creatures = self.current_attacking_creatures[player.userid] or {}
	for _,victim in ipairs(self.players[player.userid]) do
		if release_spawns[victim] ~= nil then
			release_spawns[victim]:Cancel()
			release_spawns[victim] = nil
		end
		for _,v in ipairs(tasks_to_stop) do
			local task = self[v][player.userid]
			if task[victim] ~= nil then
				task[victim]:Cancel()
				task[victim] = nil
			end
		end
	end
	for _,v in ipairs(current_attacking_creatures) do
		if v == nil then return end
		for creature in pairs(v) do
			if creature:IsValid() then
				--if vv.components.health then
				--vv.components.health:Kill()
				--else
				creature:Remove()
				--end
			end
		end
	end
	PurgeSavedValues(self,player)
end



--[[function AttackWaves:OnSave()
	local data = {}
	return data
end

function AttackWaves:OnLoad(data)
end]]


return AttackWaves