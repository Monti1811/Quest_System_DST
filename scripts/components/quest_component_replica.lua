local QUESTS = TUNING.QUEST_COMPONENT.QUESTS


local function OnShowHUDDirty(inst)
	if inst and inst.HUD then
		local screen = TheFrontEnd:GetActiveScreen()
        if not screen or not screen.name then return true end
        if screen.name:find("HUD") then
            TheFrontEnd:PushScreen(require("screens/quest_widget")(inst))
            return true
        else
            if screen.name == "quest_widget" then
                screen:OnClose()
            end
        end
	end
end

local limits = {10,25,50,100,500}

local function GetRank(rank)
	for rang,limit in ipairs(limits) do
		if rank < limit then
			return rang
		end
	end
	return 5
end

local function OnPossibleQuestDirty(self)
	local val = self._selectable_quests:value()
	devprint("OnPossibleQuestDirty",val)
	if val ~= "" then
		self.selectable_quests = json.decode(val)
	end

end


local function OnAcceptedLevelRewards(self)
	local num = self._accepted_level_rewards:value()
	devprint("OnAcceptedLevelRewards",self,num)
	for i = 1,39 do
		local char = num:byte(i)
		if char == 49 then
			self.accepted_level_rewards[i*5] = true
		else
			self.accepted_level_rewards[i*5] = nil
		end
	end
end


local Quest_Component = Class(function(self, inst)
    self.inst = inst
    self._quests = {}
    self._current_victims = {}
    self._level = net_float(inst.GUID, "quest_component._level")
    self._points = net_float(inst.GUID, "quest_component._points")
    self._completed_quest = net_float(inst.GUID, "quest_component._completed_quest")
    self._showhud = net_event(inst.GUID, "quest_component._showhud")
    self._bossfight = net_byte(inst.GUID, "quest_component._bossfight")
    self._rank = net_byte(inst.GUID, "quest_component._rank")

	self.selectable_quests = {}
    self._selectable_quests = net_string(inst.GUID, "quest_component._selectable_quests","quest_component._selectable_quests_dirty")

    self._max_amount_of_quests = net_byte(inst.GUID, "quest_component._max_amount_of_quests")

	self.accepted_level_rewards = {}
    self._accepted_level_rewards = net_string(inst.GUID,"quest_component._accepted_level_rewards", "quest_component._accepted_level_rewards_dirty")

    self._acceptedquest = net_bool(inst.GUID,"quest_component._acceptedquest")

	self._OnPossibleQuestDirty = function() OnPossibleQuestDirty(self) end
	self._OnAcceptedLevelRewards = function() OnAcceptedLevelRewards(self) end
	self.inst:ListenForEvent("quest_component._selectable_quests_dirty", self._OnPossibleQuestDirty)
	self.inst:ListenForEvent("quest_component._accepted_level_rewards_dirty", self._OnAcceptedLevelRewards)

    if not TheWorld.ismastersim then
		self.inst:ListenForEvent("quest_component._showhud", OnShowHUDDirty)
	end

	self.quest_data = {}

end)

function Quest_Component:AddQuest(name,current_amount,custom_vars)
	devprint("[Quest System] Adding Quest",name,current_amount,custom_vars)
	if name and QUESTS[name] then
		local quest = QUESTS[name]
		local new_quest = deepcopy(quest)
		new_quest.current_amount = current_amount or 0
		if new_quest.current_amount >= new_quest.amount then
			new_quest.completed = true
		end
		new_quest.custom_vars = custom_vars
		self.quest_data[name] = self.custom_vars
		if new_quest.variable_fn ~= nil and type(new_quest.variable_fn) == "function" then
			new_quest = new_quest.variable_fn(self.inst,new_quest,new_quest.custom_vars)
		end
		new_quest.rewards = new_quest.custom_rewards ~= nil and type(new_quest.custom_rewards) == "function" and new_quest.custom_rewards(self.inst,new_quest.rewards,new_quest.custom_vars) or new_quest.rewards
		self._quests[name] = new_quest
		if new_quest.victim ~= "" then
			self._current_victims[name] = new_quest.victim
		end
	end
end

function Quest_Component:UpdateQuest(name,amount,reset,set_amount)
	amount = amount or 1
	local quest = self._quests[name]
	if quest == nil then return end
	if quest.current_amount == nil then
		quest.current_amount = 0
	end
	quest.current_amount = math.max(quest.current_amount + amount,0)
	if reset == true then
		quest.current_amount = 0
	end
	if set_amount ~= nil then
		quest.current_amount = set_amount
	end
end

function Quest_Component:MarkQuestAsFinished(name)
	devprint("Quest_Component:MarkQuestAsFinished",name)
	devdumptable(self._quests)
	if self._quests[name] == nil then return end
	self._quests[name].completed = true
	name = QUESTS[name] and QUESTS[name].name or name
	Networking_Announcement(name..": "..STRINGS.QUEST_COMPONENT.QUEST_LOG.SUCCESS)
end

function Quest_Component:CompleteQuest(name)
	self._current_victims[name] = nil
	self._quests[name] = nil
end

-------------------------------------------------------

function Quest_Component:GetPossibleQuests()
	devprint("Quest_Component:GetPossibleQuests()")
	devdumptable(self.selectable_quests)
	return self.selectable_quests
end

local rank_str = {"D","C","B","A","S"}

function Quest_Component:GetRankStr()
	local rank = GetRank(self._rank:value()) or 1
	devprint(rank,limits[rank],self._rank:value())
	local diff = rank < 5 and limits[rank] and limits[rank] - self._rank:value() or "Max Rank reached"
	return rank_str[rank],diff
end

--------------------------------------------------------

return Quest_Component