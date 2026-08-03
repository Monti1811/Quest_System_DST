local QUEST_COMPONENT = TUNING.QUEST_COMPONENT
local REWARDS_AMOUNT =  QUEST_COMPONENT.REWARDS_AMOUNT
local QUESTS = QUEST_COMPONENT.QUESTS
local CUSTOM_QUEST_END_FUNCTIONS = QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS
local QUEST_BOARD = QUEST_COMPONENT.QUEST_BOARD

local boss_fight_fns = require("quest_util/boss_fight")


local function onlevelchange(self,level)
	local replica = self.inst.replica.quest_component
	replica._level:set_local(level)
	replica._level:set(level)
end

local function onpointchange(self,point)
	local replica = self.inst.replica.quest_component
	replica._points:set_local(point)
	replica._points:set(point)
end

--[[local function onhudshow(self)
	self.inst.replica.quest_component._showhud:push()
end]]

local function oncompleted_questschange(self,num)
	local replica = self.inst.replica.quest_component
	replica._completed_quest:set_local(num)
	replica._completed_quest:set(num)
end

local function onbossfight(self,num)
	local replica = self.inst.replica.quest_component
	replica._bossfight:set_local(num)
	replica._bossfight:set(num)
end

local function onrankchange(self,num)
	local replica = self.inst.replica.quest_component
	replica._rank:set_local(num)
	replica._rank:set(num)
end

local function on_max_amount_of_quests_change(self,num)
	local replica = self.inst.replica.quest_component
	replica._max_amount_of_quests:set_local(num)
	replica._max_amount_of_quests:set(num)
end

local function onaccepted_level_rewards(self,num)
	local replica = self.inst.replica.quest_component
	local str = tostring(num)
	replica._accepted_level_rewards:set_local(str)
	replica._accepted_level_rewards:set(str)
end


local function OnKilled(inst,data)
	devprint("OnKilled",inst,data.victim)
	if data and data.victim ~= nil then
		local victim = data.victim
		local quest_component = inst.components.quest_component
		local health = victim.components.health
		if health then
			local points = math.floor(health.maxhealth / 100)
			quest_component:AddPoints(points)
		end
		local current_victim = quest_component.current_victims[victim.prefab]
		if current_victim then
			for _,v in ipairs(current_victim) do
				quest_component:UpdateQuest(v)
			end
		end
		if QUEST_COMPONENT.FRIENDLY_KILLS == true then
			local pos = Vector3(victim.Transform:GetWorldPosition())
   			local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 12)
   			for _,v in pairs(ents) do
				if v:HasTag("player") and v ~= inst and v.components.quest_component then
					v:PushEvent("killedbyfriend",data)
				end
			end
		end
	end
end

local function OnKilled2(inst,data)
	devprint("OnKilled2",inst,data.victim)
	if data and data.victim ~= nil then
		local victim = data.victim
		local quest_component = inst.components.quest_component
		local health = victim.components.health
		if health then
			local points = math.floor(health.maxhealth / 100 * 0.7)
			quest_component:AddPoints(points)
		end
		local current_victim = quest_component.current_victims[victim.prefab]
		if current_victim then
			for _,v in ipairs(current_victim) do
				quest_component:UpdateQuest(v)
			end
		end
	end
end

local function OnQuestUpdate(inst,data)
	devprint("OnQuestUpdate",inst,data.amount,data.reset,data.set_amount,data.friendly_goal,data.quest)
	if data and data.quest then
		local quest_component = inst.components.quest_component
		if quest_component.quests[data.quest] ~= nil then
			quest_component:UpdateQuest(data.quest,data.amount,data.reset,data.set_amount)
		end
		if QUEST_COMPONENT.FRIENDLY_KILLS == true and data.friendly_goal == true then
			local pos = Vector3(inst.Transform:GetWorldPosition())
   			local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 12)
   			for _,v in pairs(ents) do
				if v:HasTag("player") and v ~= inst and v.components.quest_component then
					v:PushEvent("quest_update2",data)
				end
			end
		end
	end
end

local function OnQuestUpdate2(inst,data)
	devprint("OnQuestUpdate2",inst,data.amount,data.reset,data.set_amount)
	if data and data.quest then
		local quest_component = inst.components.quest_component
		if quest_component.quests[data.quest] ~= nil then
			quest_component:UpdateQuest(data.quest,data.amount,data.reset,data.set_amount)
		end
	end
end

local limits = {10,25,50,100}

local function GetRank(rank)
	for rang,limit in ipairs(limits) do
		if rank < limit then
			return rang
		end
	end
	return 5
end

local Quest_Component = Class(function(self, inst)
    self.inst = inst
    self.quests = {}
    self.current_victims = {}
    self.level = 1
    self.points = 0
    self.level_rate = QUEST_COMPONENT.LEVEL_RATE or 1
    self.point_cap = (self.level * 25 + 100) * self.level_rate
    --self.showhud = nil

    self.bossfight = 0
    self.bossplatform = nil
    self.boss_place = nil

    self.completed_quests = 0
	self.accepted_level_rewards = "000000000000000000000000000000000000000"
    self.quest_data = {}

	self.selectable_quests = {}

    --self.onfinished = nil

    self.scaled_quests = {}

    self.rank = 0

    self.base_amount_of_quests = QUEST_COMPONENT.BASE_QUEST_SLOTS
    self.additional_quest_slots = 0
    self.max_amount_of_quests = self.base_amount_of_quests + self.additional_quest_slots

    self.inst:ListenForEvent("killed", OnKilled)
    self.inst:ListenForEvent("killedbyfriend", OnKilled2)
    self.inst:ListenForEvent("quest_update", OnQuestUpdate)
    self.inst:ListenForEvent("quest_update2", OnQuestUpdate2)

    self.inst:WatchWorldState("cycles", function() self:GetPossibleQuests() end)

    self:DoInit()

end,
nil,
{
	level = onlevelchange,
	points = onpointchange,
	--showhud = onhudshow,
	completed_quests = oncompleted_questschange,
	bossfight = onbossfight,
	rank = onrankchange,
	accepted_level_rewards = onaccepted_level_rewards,
	max_amount_of_quests = on_max_amount_of_quests_change,
})

function Quest_Component:AddQuest(name,debug)
	print("[Quest System] Add Quest",name,"number of quests",GetTableSize(self.quests))
	if GetTableSize(self.quests) >= self.max_amount_of_quests then return end
	if name == nil or QUESTS[name] == nil then
		print("[Quest System] This quest doesn't exist!",name)
		return
	end
	local quest = QUESTS[name]
	if self.quests[name] ~= nil then
		print("[Quest System] You already have this quest",name)
		return
	end
	if TheWorld.components.quest_loadpostpass:CanQuestLineBeDone(name) == false then
		print("[Quest System] This quest is already active for somebody else",name)
		return
	end
	if quest.character and not debug then
		if quest.character ~= self.inst.prefab then
			print("[Quest System] Tried to add a character specific quest to another character:",name,quest.character)
			return
		end
	end
	local new_quest = deepcopy(quest)
	for k,v in pairs(new_quest) do
		if type(v) == "function" then
			new_quest[k] = nil
		end
	end
	new_quest.current_amount = 0
	new_quest.custom_vars = {}
	devprint("checking old data")
	devdumptable(self.quest_data[name])
	--If there are already prepared custom vars, use them
	if self.quest_data[name] ~= nil and self.quest_data[name].custom_vars ~= nil then
		new_quest.custom_vars = self.quest_data[name].custom_vars
	end
	--If there is a custom_vars_fn and the table of custom vars is empty(if in some case the old data was empty) do the custom_vars_fn
	if quest.custom_vars_fn ~= nil and type(quest.custom_vars_fn) == "function" and next(new_quest.custom_vars) == nil then
		new_quest.custom_vars = quest.custom_vars_fn(self.inst,quest.amount,name)
	end
	--Change the values of the quest depending on the variable_fn
	if quest.variable_fn ~= nil and type(quest.variable_fn) == "function" then
		new_quest = quest.variable_fn(self.inst,new_quest,new_quest.custom_vars)
	end
	--Change the rewards depending on the custom_rewards function
	new_quest.rewards = quest.custom_rewards ~= nil and type(quest.custom_rewards) == "function" and quest.custom_rewards(self.inst,new_quest.rewards,new_quest.custom_vars) or new_quest.rewards
	if new_quest.victim ~= "" and new_quest.victim ~= nil then
		if self.current_victims[new_quest.victim] == nil then
			self.current_victims[new_quest.victim] = {}
		end
		table.insert(self.current_victims[new_quest.victim],name)
	end
	devprint("printing new quest")
	devdumptable(new_quest)
	self.quests[name] = new_quest
	if quest.start_fn and QUEST_COMPONENT.DEBUG ~= 1 then
		--Delay it by a frame so that quests that are directly completed are still
		--shown correctly completed on the client
		self.inst:DoTaskInTime(0, function()
			if type(quest.start_fn) == "string" then
				local fn = string.gsub(quest.start_fn,"start_fn_","")
				local T_fn = QUEST_BOARD.PREFABS_MOBS[fn]
				devprint(fn, T_fn)
				if T_fn ~= nil then
					T_fn.fn(self.inst,new_quest.amount,new_quest.name)
				else
					print("[Quest System] Something broke, the start_fn doesn't exist anymore. Did you disable a mod that added more options to quest making?",name,quest.start_fn)
				end
			elseif type(quest.start_fn) == "function" then
				quest.start_fn(self.inst,new_quest.amount,new_quest.name)
			else
				print("[Quest System] Something broke, the start_fn is not the correct type anymore. start_fn:",quest.start_fn)
			end
		end)
	end
	devprint("name of quest",new_quest.name)
	local data = json.encode({name = name, custom_vars = new_quest.custom_vars})
	self:AddQuestToClient(data)
end

function Quest_Component:UpdateQuest(name,amount,reset,set_amount)
	devprint("UpdateQuest",name,amount,reset,set_amount)
	amount = amount or 1
	local quest = self.quests[name]
	if quest == nil or quest.completed == true then
		return
	end
	local old_amount = quest.current_amount
	quest.current_amount = set_amount
			or (reset and 0)
			or (quest.current_amount and math.max(quest.current_amount + amount,0)) or 0

	if quest.current_amount >= quest.amount then
		self:FinishedQuest(name,quest)
	end
	if old_amount ~= quest.current_amount then
		local tab = {name = name, amount = amount, reset = reset, set_amount = set_amount}
		local data = json.encode(tab)
		self:SendInfoToClient(data)
	end
end

function Quest_Component:FinishedQuest(name,quest)
	devprint("Quest_Component:FinishedQuest",name,quest)
	self.inst:PushEvent("finished_quest",name)
	self.quests[name].completed = true
	self:MarkQuestAsFinished(name)
end

function Quest_Component:CompleteQuest(name)
	devprint("Quest_Component:CompleteQuest",name)
	local quest = self.quests[name]
	if quest == nil then 
		print("[Quest_Component] This quest is not activated!",quest,name)
		return 
	end
	local quest_tuning = QUESTS[name]
	local items = {}
	if self.inst.components.inventory then
		for k,v in pairs(quest.rewards) do
			local amount = tonumber(v) ~= nil and math.ceil(tonumber(v) * REWARDS_AMOUNT) or 0
			devprint("reward",k,v,amount)
			--if type(v) == "function" then
				--print("currently not supported")
			--else
			if string.find(k,":func:") ~= nil then	
				local func = CUSTOM_QUEST_END_FUNCTIONS[k] and CUSTOM_QUEST_END_FUNCTIONS[k][1]
				if func then
					func(self.inst,v,name)
				end
			else
				for _ = 1,amount do
					local new_reward = SpawnPrefab(k)
					if new_reward then --need to check if the reward can be spawned to not crash the game.
						self.inst.components.inventory:GiveItem(new_reward)
						table.insert(items,new_reward)
					end
				end
			end
		end

	end
	if quest_tuning.onfinished then
		quest_tuning.onfinished(self.inst,items,name)
	end
	if self.onfinished ~= nil then
		self.onfinished(self.inst,items)
	end
	self:AddPoints(quest.points)
	self.rank = self.rank + (quest.difficulty or 1)
	if self.current_victims[quest.victim] then
		table.removearrayvalue(self.current_victims[quest.victim],name)
		if next(self.current_victims[quest.victim]) == nil then
			self.current_victims[quest.victim] = nil
		end
	end
	self.inst:PushEvent("complete_quest",name)
	self.quests[name] = nil
	self.quest_data[name] = nil
	self.completed_quests = self.completed_quests + 1
end

function Quest_Component:RemoveQuest(name)
	devprint("RemoveQuest",name)
	
	if name == nil then return end
	if self.quests[name] == nil then return end
	local quest = self.quests[name]
	devprint(self.current_victims[name])
	self:RemoveQuestFromClient(name)
	if self.current_victims[quest.victim] then
		table.removearrayvalue(self.current_victims[quest.victim],name)
		if next(self.current_victims[quest.victim]) == nil then
			self.current_victims[quest.victim] = nil
		end
	end
	self.inst:PushEvent("forfeited_quest",name)
	self.quests[name] = nil
	self.quest_data[name] = nil
end

function Quest_Component:RemoveAllQuests()
	for name in pairs(self.quests) do
		self:RemoveQuest(name)
	end
end

----------------------------------------------------------

function Quest_Component:AddQuestToClient(data)
	devprint("Quest_Component:AddQuestToClient",data)
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToClient"),self.inst.userid,self.inst,data)
end

function Quest_Component:SendInfoToClient(data)
	devprint("Quest_Component:SendInfoToClient",data)
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "UpdateQuestOnClient"),self.inst.userid,self.inst,data)
end

function Quest_Component:MarkQuestAsFinished(name)
	devprint("Quest_Component:MarkQuestAsFinished",name)
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "MarkQuestAsFinished"),self.inst.userid,self.inst,name)
end

function Quest_Component:RemoveQuestFromClient(name)
	devprint("Quest_Component:RemoveQuestFromClient",name)
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveQuestFromClient"),self.inst.userid,self.inst,name)
end


---------------------------------------------------------

function Quest_Component:SetPoints(points)
	self.points = points
end

function Quest_Component:AddPoints(points)
	self.points = self.points + points 
	while self.points >= self.point_cap do
		self.points = self.points - self.point_cap
		self:LevelUp()
	end
	devprint(self.points, self.point_cap)
end

local function replace_char(pos, str, r)
	return ("%s%s%s"):format(str:sub(1,pos-1), r, str:sub(pos+1))
end

function Quest_Component:LevelUp()
	self.level = self.level + 1
	if self.onlevelup ~= nil then
		self.onlevelup(self.inst,self.level)
	end
	self.inst:PushEvent("q_s_levelup",self.level)
	if self.level % 5 == 0 and self.level <= 195 then
		self.accepted_level_rewards = replace_char(self.level/5, self.accepted_level_rewards, 1)
	end

	if QUEST_COMPONENT.LEVELSYSTEM == 1 and self.inst.components.levelupcomponent then
		self.inst.components.levelupcomponent:OnLevelUp()
	end

	self:RecalculatePointCap() 
	self:CheckIfBossFight()
end

function Quest_Component:SetLevel(new_level)
	devprint("Quest_Component:SetLevel", new_level, self.level)
	if self.level == new_level then return end
	if self.level > new_level then
		self.level = new_level
		self:RecalculatePointCap()
	else
		for _ = self.level, (new_level - 1) do
    		self.inst.components.quest_component:LevelUp()
    	end
    end
end

function Quest_Component:RecalculatePointCap()
	self.point_cap = (self.level * 25 + 100) * self.level_rate
end

function Quest_Component:SetOnFinished(fn)
	self.onfinished = fn
end

function Quest_Component:SetOnLevelUp(fn)
	self.onlevelup = fn
end

--[[function Quest_Component:ShowQuestHUD()
	if self.showhud == nil then
		self.showhud = true
	else
		self.showhud = not self.showhud
	end
end]]

---------------------------------------------------------

function Quest_Component:CheckIfBossFight()
	if self.bossfight >= 3 then return end
	local chance = math.min(self.level * 0.01,0.5)
	if math.random() < chance then
		self.bossfight = self.bossfight + 1
	end
end

function Quest_Component:StartBossFight(pos,diff,num)
	devprint("StartBossFight",pos,diff,num)

	-- Set the position of the player before the fight and teleport him, if necessary
	local is_no_plattform = boss_fight_fns.SetPositionAndTeleport(self,pos)

    local difficulty = diff or boss_fight_fns.GetDiff(self.level)
    local boss_number = num or math.random(#QUEST_COMPONENT.BOSSES[difficulty])
    devprint("difficulty:",difficulty, "number:", boss_number)

	-- Spawn Boss in the arena
	if not boss_fight_fns.SpawnBoss(self,difficulty,boss_number) then
		print("[Quest System] The boss couldn't be spawned!",self.boss,difficulty,boss_number)
		return
	end

	-- Set the position of the boss
	boss_fight_fns.SetBossPosition(self,is_no_plattform)

	-- Configure the boss
	boss_fight_fns.ConfigureBoss(self, difficulty, boss_number, is_no_plattform)

	-- Announce the boss fight
	TheNet:Announce(string.format(STRINGS.QUEST_COMPONENT.TALKING.BOSSFIGHT, self.inst:GetDisplayName(), self.boss:GetDisplayName()))

	devprint("bossfight",self.boss,difficulty,boss_number)
end

------------------------------------------------------
local tries = 0

local function GiveFirstQuest(_,diff)
	local tab
	tries = 0
	if diff and QUEST_COMPONENT["QUESTS_DIFFICULTY_"..diff] ~= nil then
		tab = QUEST_COMPONENT["QUESTS_DIFFICULTY_"..diff]
	else
		tab = QUESTS
	end
	for k in pairs(tab) do
		return k
	end
end

local MAX_TRIES = 200
local FindUnusedQuest
local function Retry(self,difficulty)
	tries = tries + 1
	if tries >= MAX_TRIES then 
		return GiveFirstQuest(self,difficulty)
	else
		return FindUnusedQuest(self,difficulty)
	end
end

local function GetCharacterQuest(self,difficulty)
	local tab2
	local char_diff_quests = "QUESTS_"..self.inst.prefab.."_DIFFICULTY_"..(difficulty or 1)
	if difficulty and QUEST_COMPONENT[char_diff_quests] ~= nil then
		tab2 = QUEST_COMPONENT[char_diff_quests]
	else
		tab2 = QUEST_COMPONENT["QUESTS_"..self.inst.prefab]
	end
	local item = GetRandomItem(tab2)
	if item and item.unlisted == true then
		return GetCharacterQuest(self,difficulty)
	end
	return item
end

FindUnusedQuest = function(self,difficulty)
	local tab
	local quest_diff = "QUESTS_DIFFICULTY_"..(difficulty or 1)
	if difficulty and QUEST_COMPONENT[quest_diff] ~= nil then
		tab = QUEST_COMPONENT[quest_diff]
	else
		tab = QUESTS
	end
	local _item = GetRandomItem(tab)
	if _item == nil then print("[Quest System] Couldn't find any quests!",difficulty) return end
	--Check if the quest is a character quest, if yes look for a new one.
	if _item.character then
		if _item.character ~= self.inst.prefab then
			return Retry(self,difficulty)
		end
	end
	--Check if the quest can be gotten normally or only as from another source
	if _item.unlisted == true then
		return Retry(self,difficulty)
	end
	--Check if a quest line can be added if GLOBAL_REWARDS are active, as then only one person can have the quest line.
	if QUEST_COMPONENT.GLOBAL_REWARDS and not TheWorld.components.quest_loadpostpass:CanQuestLineBeDone(_item.name) then
		return Retry(self,difficulty)
	end
	--Check if it's a scalable quest, if yes check if this quest can be gotten yet.
	--if _item.scale and self.scaled_quests[_item.overridename or _item.name] and self.scaled_quests[_item.overridename or _item.name] < _item.scale - 1 then
	 	--return Retry(self,difficulty)
	--end

	--If character quests exist for this character, look for one
	local _item2 = QUEST_COMPONENT["QUESTS_"..self.inst.prefab] ~= nil and GetCharacterQuest(self,difficulty)


	--If a character quest was chosen, check if this character quest should be chosen, depending on the chosen character quest probability
	local item = math.random() < QUEST_COMPONENT.PROB_CHAR_QUEST and _item2 or _item

	--If this quest is already active, look for a new one.
	if self.quests[item.name] ~= nil then
		return Retry(self,difficulty)
	end
	--If this quest is already chosen as a possible quest to choose from for this day, look for a new one.
	for count = 1,3 do
		local quest = self.selectable_quests[count]
		if quest and quest.name == item.name then
			return Retry(self,difficulty)
		end
	end
	tries = 0
	return item.name
end

function Quest_Component:GetUnusedQuestNum(diff)
	return FindUnusedQuest(self,diff)
end

local function GetCustomVars(self,name)
	local quest = QUESTS[name]
	if quest then
		local custom_vars = quest.custom_vars_fn and type(quest.custom_vars_fn) == "function" and quest.custom_vars_fn(self.inst,quest.amount,quest.name) or nil
		if custom_vars then
			devprint("GetCustomVars",name,custom_vars)
			devdumptable(custom_vars)
			if self.quest_data[name] == nil then
				self.quest_data[name] = {}
			end
			self.quest_data[name].custom_vars = custom_vars
			return custom_vars
		end
	end
end


function Quest_Component:GetPossibleQuests(diff)
	devprint("Quest_Component:GetPossibleQuests",diff,QUEST_COMPONENT.RANK)
	for _,quest in ipairs(self.selectable_quests) do
		if self.quest_data[quest.name] ~= nil then
			self.quest_data[quest.name] = nil
		end
	end

	local ranked = false
	if diff == nil and QUEST_COMPONENT.RANK ~= false then
		diff = self:GetRank()
		ranked = true
	end
	local add = type(QUEST_COMPONENT.RANK) == "number" and QUEST_COMPONENT.RANK or 0
	for count = 1,3 do
		local new_diff = ranked == true and math.random(math.min(diff+add,5)) or diff
		local name = FindUnusedQuest(self,new_diff) or GiveFirstQuest(self,new_diff)
		self.selectable_quests[count] = {name = name, custom_vars = GetCustomVars(self,name)}
		--devprint(self["quest"..count])
	end
	local replica = self.inst.replica.quest_component
	replica._selectable_quests:set(json.encode(self.selectable_quests))
	replica._acceptedquest:set(false)
end

function Quest_Component:GetRank()
	return GetRank(self.rank)
end

------------------------------------------------------

function Quest_Component:SetQuestData(quest_name,key,value)
	local quest_data = self.quest_data
	if quest_data[quest_name] == nil then
		quest_data[quest_name] = {}
	end
	quest_data[quest_name][key] = value
end

function Quest_Component:GetQuestData(quest_name,key)
	local quest_data = self.quest_data[quest_name]
	if quest_data == nil then
		devprint("[Quest System] There exists no data for this quest! QuestName:",quest_name,key)
		return
	end
	return quest_data[key]
end

------------------------------------------------------

function Quest_Component:DoInit()
	
	--Remove all quests that are no longer available to reduce errors (i.e if a mod was deactivated that had custom quests active)
	self.inst:DoTaskInTime(0.1,function()
		for k,v in pairs(self.quests) do
			if QUESTS[v.name] == nil then
				self.quests[k] = nil
			elseif not v.description then
				for key,value in pairs(QUESTS[v.name]) do
					if type(value) ~= "function" then
						self.quests[k][key] = value
					end
				end
			end
		end 
	end)

	self.inst:DoTaskInTime(2,function()
		
		for _,v in pairs(self.quests) do
			--Run the start_fn if there is one available
			if QUESTS[v.name].start_fn ~= nil and not v.completed then
				local quest = QUESTS[v.name]
				if type(quest.start_fn) == "string" then
					local fn = string.gsub(quest.start_fn,"start_fn_","")
					if QUEST_BOARD.PREFABS_MOBS[fn] ~= nil then
						QUEST_BOARD.PREFABS_MOBS[fn]["fn"](self.inst,quest.amount,quest.name)
					else
						print("[Quest System] Something broke, the start_fn doesn't exist anymore. Did you disable a mod that added more options to quest making?",quest.name,quest.start_fn)
					end
				elseif type(quest.start_fn) == "function" then
					quest.start_fn(self.inst,v.amount,quest.name)
				else
					print("[Quest System] Something broke, the start_fn is not the correct type anymore. start_fn:",quest.name,quest.start_fn)
				end
			end
			local data = json.encode({name = v.name, current_amount = v.current_amount, custom_vars = v.custom_vars})
			self:AddQuestToClient(data)
		end
		self.bossplatform = self.bossplatform or TheSim:FindFirstEntityWithTag("teleporter_boss_island")
		local quest_loadpostpass = TheWorld.components.quest_loadpostpass
		if quest_loadpostpass and self.bossid then
			--Find the boss if there was one.
			local saved_boss = quest_loadpostpass.temp_bosses[self.bossid]
			devprint("Checking for saved boss", self.bossid)
			devdumptable(quest_loadpostpass.temp_bosses)
			if saved_boss then
				self.boss = saved_boss[1]
				boss_fight_fns.ConfigureBoss(self, saved_boss[2], self.bossplatform ~= nil)
			else
				self.bossid = nil
			end
		end
		if self.inst:HasTag("won_against_boss") then
			--Make the person able to leave the boss island if they won against the boss
			devprint("won",self.bossplatform)
			if self.bossplatform then
				self.bossplatform:TurnOn()
			end
		end
		devprint("selectable quests", #(self.selectable_quests))
		if #(self.selectable_quests) < 3 then
			self:GetPossibleQuests()
		else
			self.inst.replica.quest_component._selectable_quests:set(json.encode(self.selectable_quests))
		end

		-- I need 39 bits, unfortunately there is no 64 bit netvar...
		if self.accepted_level_rewards == nil then
			self.accepted_level_rewards = "000000000000000000000000000000000000000"
		end
	end)
end

function Quest_Component:OnSave()
	devprint("Quest_Component:OnSave")
	local data = {}
	data.level = self.level
	data.points = self.points
	data.quests = self.quests
	data.current_victims = self.current_victims 
	data.completed_quests = self.completed_quests
	data.pos_before_fight = self.pos_before_fight
	data.bossid = self.bossid
	data.bossfight = self.bossfight
	data.rank = self.rank
	data.scaled_quests = self.scaled_quests
	data.additional_quest_slots = self.additional_quest_slots

	data.selectable_quests = self.selectable_quests

	data.quest_data = self.quest_data

	data.accepted_level_rewards = self.accepted_level_rewards

	data.accepted_quest = self.inst.replica.quest_component._acceptedquest:value()

	if self.inst:HasTag("won_against_boss") then
		data.win = true
	end
	if self.inst:HasTag("currently_in_bossfight") then
		data.in_bossfight = true
	end
	devdumptable(data)
	return data
end

function Quest_Component:OnLoad(data)
	devprint("Quest_Component:OnLoad")
	devdumptable(data)
	if data ~= nil then
		if data.level ~= nil then
			self.level = data.level
			self:RecalculatePointCap()
		end
		if data.points ~= nil then
			self.points = data.points
		end
		if data.quests ~= nil and next(data.quests) ~= nil then
			self.quests = data.quests
		end
		if data.quest_data ~= nil and next(data.quest_data) ~= nil then
			self.quest_data = data.quest_data
		end
		if data.current_victims ~= nil then
			self.current_victims = data.current_victims
		end
		if data.completed_quests ~= nil then
			self.completed_quests = data.completed_quests
		end
		if data.pos_before_fight ~= nil then
			self.pos_before_fight = data.pos_before_fight
		end
		if data.rank ~= nil then
			self.rank = data.rank
		end
		if data.additional_quest_slots ~= nil then
			self.additional_quest_slots = data.additional_quest_slots
			self.max_amount_of_quests = self.base_amount_of_quests + self.additional_quest_slots
		end
		if data.win == true then
			self.inst:AddTag("won_against_boss")
		end
		if data.in_bossfight == true then
			self.inst:AddTag("currently_in_bossfight")
		end
		if data.bossid ~= nil then
			self.bossid = data.bossid
		end
		if data.bossfight ~= nil then
			self.bossfight = data.bossfight
		end
		if data.scaled_quests ~= nil and next(data.scaled_quests) ~= nil then
			self.scaled_quests = data.scaled_quests
		end
		if data.selectable_quests ~= nil then
			devdumptable(data.selectable_quests)
			for i = 1,#data.selectable_quests do
				local quest = data.selectable_quests[i]
				if QUESTS[ quest.name ] ~= nil then
					table.insert(self.selectable_quests,quest)
				end
			end
		end
		if data.accepted_level_rewards ~= nil and type(data.accepted_level_rewards) == "string" then
			self.accepted_level_rewards = data.accepted_level_rewards
		end
		if data.accepted_quest == true then
			self.inst.replica.quest_component._acceptedquest:set(true)
		end
	end
end


---------------------------------------------------------

return Quest_Component
