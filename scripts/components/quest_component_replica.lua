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

local function UnconcatString(str)
	devprint("UnconcatString",str)
	if str == nil then return end
	local new_tab = {}
	local tab = string.split(str,",")
	--devdumptable(tab)
	for _,kv_pairs in ipairs(tab) do
		local pair = string.split(kv_pairs,"=")
		new_tab[pair[1]] = pair[2]
	end
	devdumptable(new_tab)
	return new_tab
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

local function OnPossibleQuestDirty(self,inst,num)
	devprint("OnPossibleQuestDirty",inst,num,self["_quest"..num]:value())
	self["quest"..num] = self["_quest"..num]:value()
	if string.find(self["quest"..num],"@") and string.find(self["quest"..num],"=") then
		local quest_data = string.split(self["quest"..num],"@")
		devprint("is data quest",quest_data[1],quest_data[2])
		self["quest"..num] = quest_data[1]
		self.quest_data[quest_data[1]] = UnconcatString(quest_data[2])
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

    self._quest1 = net_string(inst.GUID, "quest_component._quest1","quest_component._quest1_dirty")
    self._quest2 = net_string(inst.GUID, "quest_component._quest2","quest_component._quest2_dirty")
    self._quest3 = net_string(inst.GUID, "quest_component._quest3","quest_component._quest3_dirty")

    self._max_amount_of_quests = net_byte(inst.GUID, "quest_component._max_amount_of_quests")

    for count = 5,195,5 do
    	self["accepted_level_rewards"..count] = net_bool(inst.GUID,"quest_component.accepted_level_rewards"..count)
    	self["accepted_level_rewards"..count]:set(false)
    end

    self._acceptedquest = net_bool(inst.GUID,"quest_component._acceptedquest")

    for i = 1,3 do
    	self.inst:ListenForEvent("quest_component._quest"..i.."_dirty", function()
    		OnPossibleQuestDirty(self,inst,i)
    	end)
    end

    if not TheWorld.ismastersim then
		self.inst:ListenForEvent("quest_component._showhud", OnShowHUDDirty)
	end

	self.quest_data = {}

end)

function Quest_Component:AddQuest(name,current_amount,custom_vars)
	devprint("[Quest System] Adding Quest",name,current_amount,custom_vars)
	if name and TUNING.QUEST_COMPONENT.QUESTS[name] then
		local quest = TUNING.QUEST_COMPONENT.QUESTS[name]
		local new_quest = deepcopy(quest)
		new_quest.current_amount = current_amount or 0
		if new_quest.current_amount >= new_quest.amount then
			new_quest.completed = true
		end
		new_quest.custom_vars = UnconcatString(custom_vars)
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
	name = TUNING.QUEST_COMPONENT.QUESTS[name] and TUNING.QUEST_COMPONENT.QUESTS[name].name or name
	Networking_Announcement(name..": "..STRINGS.QUEST_COMPONENT.QUEST_LOG.SUCCESS)
end

function Quest_Component:CompleteQuest(name)
	self._current_victims[name] = nil
	self._quests[name] = nil
end

-------------------------------------------------------

function Quest_Component:GetPossibleQuests()
	local quest1,quest2,quest3 = self.quest1,self.quest2,self.quest3
	devprint("get possible quests",quest1,quest2,quest3)
	return {quest1,quest2,quest3}
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