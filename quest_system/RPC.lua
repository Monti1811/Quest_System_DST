-----------------------------------------------------------------------------------------------------------------------

--This is where the fun begins!
--This is a function which creates a quest from the passed arguments and returns it.
local function MakeQuest(inst,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	--rewards are saved as a string as "pigskin|3", where the first part is the prefab and the second one is the amount
	local rewards1 = type(reward1) == "string" and string.split(reward1,"|") or {}
	local rewards2 = type(reward2) == "string" and string.split(reward2,"|") or {}
	local rewards3 = type(reward3) == "string" and string.split(reward3,"|") or {}
	--I need to add real victim to make a difference betwenn quests that have a start fn and those who don't
	local real_victim
	local counter
	local start_fn
	local GOAL_TABLE 
	--Quests that have a start fn have the string start_fn_ added at the beginning so that they can be identified.
	if string.find(victim,"start_fn_") then
		real_victim = ""
		start_fn = victim
		GOAL_TABLE =  GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[string.gsub(victim,"start_fn_","")]
		counter = GOAL_TABLE and GOAL_TABLE["counter"]
	--else
		--real_victim = victim
	--end

	--The previous way to do it, but it was not very efficient. I'm just leaving it in some time so that old quests can be converted to the new format.
	--can be deleted after some time(around march 2022)
	elseif type(victim) == "number" then
		if modname == nil then
			start_fn = victim
			GOAL_TABLE =  GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS_OUTDATED[victim]
			if GOAL_TABLE then
				for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS) do
					if v.text == GOAL_TABLE.text then
						GLOBAL.dumptable(GOAL_TABLE)
						start_fn = "start_fn_"..GOAL_TABLE.text
					end
				end
			end
			counter = GOAL_TABLE and GOAL_TABLE["counter"]
			real_victim = ""
		else
			start_fn = modname
			GOAL_TABLE =  GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS_OUTDATED[modname]
			if GOAL_TABLE then
				for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS) do
					if v.text == GOAL_TABLE.text then
						start_fn = "start_fn_"..GOAL_TABLE.text
					end
				end
			end
			counter = GOAL_TABLE and GOAL_TABLE["counter"]
			real_victim = ""
		end
	else
		real_victim = victim
	end
	--till here

	--the quest is now finally built, return it.
	local tab = {
		name = name,
		victim = real_victim,
		counter_name = counter,
		description = description,
		rewards = {
			[rewards1[1] or 1] = rewards1[2],
			[rewards2[1] or 2] = rewards2[2],
			[rewards3[1] or 3] = rewards3[2],
		},
		amount = amount,
		points = points,
		start_fn = start_fn,
		difficulty = difficulty,
		tex = GOAL_TABLE and GOAL_TABLE["tex"] or victim..".tex",
		atlas = atlas or (GOAL_TABLE and GOAL_TABLE["atlas"]) or "images/victims.xml",
		author = inst and inst.name or nil,
	}

	--GLOBAL.dumptable(tab)
	--print(inst,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	return tab
end

---------------------------RPC----------------------------

--RPC to start a bossfight
local function BossFight(inst)
	devprint("BossFight",inst)
	if inst and inst.components.quest_component then
		local pos = inst:GetPosition()
		inst.components.quest_component:StartBossFight(pos)
	end
end

AddModRPCHandler("Quest_System_RPC", "BossFight", BossFight)

--RPC to accept a quest from the quest board
local function AcceptQuest(inst,name)
	devprint("AcceptQuest",inst,name)
	if inst and inst.components.quest_component then
		inst.components.quest_component:AddQuest(name)
	end
end

AddModRPCHandler("Quest_System_RPC", "AcceptQuest", AcceptQuest)

--RPC which is called after accepting a quest, so that you can't accept another quest the same day
local function HasAcceptedQuest(inst)
	devprint("HasAcceptedQuest",inst)
	if inst and inst.replica.quest_component then
		inst.replica.quest_component._acceptedquest:set(true)
	end
end

AddModRPCHandler("Quest_System_RPC", "HasAcceptedQuest", HasAcceptedQuest)

--RPC to forfeit a quest by clicking on the red cross in the quest log
local function ForfeitQuest(inst,name)
	devprint("ForfeitQuest",inst,name)
	if inst and inst.components.quest_component then
		inst.components.quest_component:RemoveQuest(name)
	end
end

AddModRPCHandler("Quest_System_RPC", "ForfeitQuest", ForfeitQuest)

--RPC to give the rewards by clocking on the field "Get Rewards" on the quest log
local function GetRewards(inst,name)
	devprint("GetRewards",inst,name)
	if inst and inst.components.quest_component then
		inst.components.quest_component:CompleteQuest(name)
	end
end

AddModRPCHandler("Quest_System_RPC", "GetRewards", GetRewards)

local custom_rewards = {
	["Additional Quest Slots"] = function(inst,num)
		if inst.components.quest_component then
			inst.components.quest_component.max_amount_of_quests = inst.components.quest_component.max_amount_of_quests + num
			inst.components.quest_component.additional_quest_slots = inst.components.quest_component.additional_quest_slots + num
		end
	end,
}

--RPC to get level rewards by clicking on them on the quest board
local function GetLevelRewards(inst,level)
	devprint("GetLevelRewards",inst,level)
	if inst.components.inventory and level then
		local level_reward = GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS[level] or {pigskin = 3,butterfly = 3}
		for k,v in pairs(level_reward) do
			if custom_rewards[k] then
				custom_rewards[k](inst,v)
			else
				for count = 1,v do
					local item = GLOBAL.SpawnPrefab(k)
					if item then
						inst.components.inventory:GiveItem(item)
					end
				end
			end
		end
		inst.replica.quest_component["accepted_level_rewards"..level]:set(false)
	end
end

AddModRPCHandler("Quest_System_RPC", "GetLevelRewards", GetLevelRewards)

--RPC to mark users as users that can create quests.
local function AddCustomQuestMakerToServer(inst,userid,bool)
	devprint("AddCustomQuestMakerToServer",userid,bool)
	if userid then
		--[[if bool == 1 then
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end]]
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,userid,bool)
        SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddCustomQuestMakerToShards"),nil,userid,bool)
        local PersistentData = require("persistentdata")
		local DataContainer = PersistentData("quest_component")
		local world_key = GLOBAL.TheNet:GetSessionIdentifier()
        DataContainer:SetValue(world_key.."_questmakers", TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS)
    	DataContainer:Save()
	end
end

AddModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToServer", AddCustomQuestMakerToServer)

--RPC to add a quest. Is sent form the quest board after creating the quest, is the first one that is called
local function AddQuestToQuestPoolServer(inst,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	devprint("AddQuestToQuestPoolServer",inst,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	--Don't run MakeQuest here as SendModRPCToShard also runs on this shard
	SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddQuestToQuestPoolShards"),nil,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	--for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS) do
		--print(k,v)
	--end
	--wait a bit and then give the creator requests if they want it
	if GLOBAL.TUNING.QUEST_COMPONENT.GIVE_CREATOR_QUEST ~= 0 then
		inst:DoTaskInTime(1,function()
			for count = 1,GLOBAL.TUNING.QUEST_COMPONENT.GIVE_CREATOR_QUEST do
				local request = GLOBAL.SpawnPrefab("request_quest_specific")
				if request and inst.components.inventory then
					request:SetQuest(name)
					inst.components.inventory:GiveItem(request)
				end
			end
		end)
	end
end

AddModRPCHandler("Quest_System_RPC", "AddQuestToQuestPoolServer", AddQuestToQuestPoolServer)

local function DeleteQuest(inst,name)
	if name then
		SendModRPCToShard(GetShardModRPC("Quest_System_RPC","RemoveQuestShard"),nil,name)
	end
end

AddModRPCHandler("Quest_System_RPC", "DeleteQuest", DeleteQuest)

local function Make_Random_Quest(inst)
	devprint("Make_Random_Quest")
	local tab = MakeRandomQuest()
	GLOBAL.dumptable(tab)
	AddQuestToQuestPoolServer(inst,tab.name,tab.victim,tab.description,tab.amount,tab.points,tab.difficulty,tab.reward1,tab.reward2,tab.reward3)
end

AddModRPCHandler("Quest_System_RPC", "Make_Random_Quest", Make_Random_Quest)


----------------------------ShardRPC-----------------------------------------

--RPC to add a quest to the different shards.
local function AddQuestToQuestPoolShards(shard_id,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	devprint("AddQuestToQuestPoolShards",shard_id,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	local tab = MakeQuest(nil,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = tab
	GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[name] = tab
	if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..difficulty] then
		GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..difficulty][name] = tab
	end

	devdumptable(tab)
	--Send it also to the clients so that they have the same information as the server
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),nil,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas)
	devprint(shard_id,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas)
	--for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS) do
		--print(k,v)
	--end
end

AddShardModRPCHandler("Quest_System_RPC", "AddQuestToQuestPoolShards", AddQuestToQuestPoolShards)

--RPC to mark users as users that can create quests.
local function AddCustomQuestMakerToShards(shard_id,userid,bool)
	devprint("AddCustomQuestMakerToShards",shard_id,userid,bool)
	if userid then
		if bool == 1 then
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,userid,bool)
	end
end

AddShardModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToShards", AddCustomQuestMakerToShards)

local function RemoveQuestShard(shard_id,name)
	devprint("AddCustomQuestMakerToShards",shard_id,name)
	if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] ~= nil then
        for k,v in ipairs(GLOBAL.AllPlayers) do
            if v.components.quest_component then
                v.components.quest_component:RemoveQuest(name)
            end
        end
        GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = nil
        GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[name] = nil
        SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,name)
    end
end

AddShardModRPCHandler("Quest_System_RPC", "RemoveQuestShard", RemoveQuestShard)

local function ChangeBlackGlommerFuelCounter(shard_id)
	devprint("ChangeBlackGlommerFuelCounter",shard_id)
	if GLOBAL.TheWorld.blackglommerfuelgerat ~= nil then
		local inst = GLOBAL.TheWorld.blackglommerfuelgerat
		inst.amount_blackglommerfuel = inst.amount_blackglommerfuel - 1
		inst:PushEvent("blackglommerfuel_used") 
	end
end

AddShardModRPCHandler("Quest_System_RPC", "ChangeBlackGlommerFuelCounter", ChangeBlackGlommerFuelCounter)

---------------------------ClientRPC----------------------------------

--RPC to add a certain quest to a client. Better than a netvar as I can change the name so I don't need to make one for each different quest
local function AddQuestToClient(inst,name,current_amount,custom_vars)
	devprint("AddQuestToClient",inst,name,current_amount,custom_vars)
	if inst and inst.replica.quest_component then
		inst.replica.quest_component:AddQuest(name,current_amount,custom_vars)
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddQuestToClient", AddQuestToClient)

--RPC to update quests on the client
local function UpdateQuestOnClient(inst,name,amount,reset,set_amount)
	devprint("UpdateQuestOnClient",inst,name,amount,reset,set_amount)
	if inst and inst.replica.quest_component then
		inst.replica.quest_component:UpdateQuest(name,amount,reset,set_amount)
	end
end

AddClientModRPCHandler("Quest_System_RPC", "UpdateQuestOnClient", UpdateQuestOnClient)

--RPC to mark quests as finished on the client. Used to determine if the rewards can be activated from the quest log
local function MarkQuestAsFinished(inst,name)
	devprint("MarkQuestAsFinished",inst,name)
	if inst and inst.replica.quest_component then
		inst.replica.quest_component:MarkQuestAsFinished(name)
	end
end

AddClientModRPCHandler("Quest_System_RPC", "MarkQuestAsFinished", MarkQuestAsFinished)

--RPC to remove quests from the client
local function RemoveQuestFromClient(inst,name)
	devprint("RemoveQuestFromClient",inst,name)
	if inst and inst.replica.quest_component and name then
		inst.replica.quest_component._current_victims[name] = nil
		inst.replica.quest_component._quests[name] = nil
	end
end

AddClientModRPCHandler("Quest_System_RPC", "RemoveQuestFromClient", RemoveQuestFromClient)

local function DeleteQuestFromClient(name)
	devprint("DeleteQuestFromClient",name)
	if name == nil then return end
	GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = nil
	GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[name] = nil
end

AddClientModRPCHandler("Quest_System_RPC", "DeleteQuestFromClient", DeleteQuestFromClient)

--RPC to add a quest to the different clients on the same shard
local function AddQuestToQuestPool(name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	devprint("AddQuestToQuestPool",name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	for _,quest in ipairs(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS) do
		if quest.name == name then
			print("[Quest System] This quest exists already:",quest.name,modname)
			return
		end	
    end
    local tab = MakeQuest(nil,name,victim,description,amount,points,difficulty,reward1,reward2,reward3,atlas,modname)
	GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = tab
	GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[name] = tab
	devdumptable(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name])

end

AddClientModRPCHandler("Quest_System_RPC", "AddQuestToQuestPool", AddQuestToQuestPool)

--RPC to open the quest board
local function ShowQuestBoard(inst)
	devprint("ShowQuestBoard",inst)
	local screen = TheFrontEnd:GetActiveScreen()
	if not screen or not screen.name then return true end
	if screen.name:find("HUD") then
		TheFrontEnd:PushScreen(require("screens/quest_board_widget")(inst))
		return true
	else
		if screen.name == "quest_widget" then
			screen:OnClose()
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "ShowQuestBoard", ShowQuestBoard)

--RPC to add the users who can make quests on the client. Needed to determine if this person can make new quests on the quest board
local function AddCustomQuestMakerToClient(userid,bool)
	devprint("AddCustomQuestMakerToClient",userid,bool)
	if userid then
		if bool == 1 then
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToClient", AddCustomQuestMakerToClient)

--RPC to show the different temp bonis on the client
local function AddTempBoniToClient(inst,num,boni,empty)
	devprint("AddTempBoniToClient",inst,num,boni,empty)
	if num and inst.HUD and inst.HUD.controls then
		if empty then
			if inst.HUD.controls["tempboni"..num] then
				inst.HUD.controls["tempboni"..num]:Hide()
			end
		else
			if boni and inst.HUD.controls["tempboni"..num] then
				inst.HUD.controls["tempboni"..num]:SetBoniPicture(boni)
			end
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddTempBoniToClient", AddTempBoniToClient)

--RPC to start the attackwave timer on the client
local counter = {}
local AttackWaveTimer = require "widgets/attackwave_timer"
local function AddTimerToClient(inst,time,victim,type,atlas)
	devprint("AddTimerToClient",inst,time,victim,type,atlas)
	local count
	if time and inst.HUD and inst.HUD.controls then
		if inst.HUD.controls["attackwavetimer"..victim] ~= nil then
			count = inst.HUD.controls["attackwavetimer"..victim].timer_count
			if inst.HUD.controls["attackwavetimer"..victim].updatetask ~= nil then
				inst.HUD.controls["attackwavetimer"..victim].updatetask:Cancel()
				inst.HUD.controls["attackwavetimer"..victim].updatetask = nil
			end
			inst.HUD.controls["attackwavetimer"..victim]:Kill()
			inst.HUD.controls["attackwavetimer"..victim] = nil
		else
			if counter[inst.userid] == nil then
				counter[inst.userid] = 0
			else
				counter[inst.userid] = counter[inst.userid] + 1
			end
		end
		count = count or counter[inst.userid] or 0
		devprint("counter = ",count)
		inst.HUD.controls["attackwavetimer"..victim] = inst.HUD.controls.top_root:AddChild(AttackWaveTimer(inst,time,victim,type,atlas))
		inst.HUD.controls["attackwavetimer"..victim]:SetPosition(count * -130,0,0)
		inst.HUD.controls["attackwavetimer"..victim].timer_count = count
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddTimerToClient", AddTimerToClient)

local function RemoveTimerFromClient(inst,victim)
	devprint("RemoveTimerFromClient",inst,victim)
	if victim and inst.HUD and inst.HUD.controls then
		if inst.HUD.controls["attackwavetimer"..victim] ~= nil then
			if inst.HUD.controls["attackwavetimer"..victim].updatetask ~= nil then
				inst.HUD.controls["attackwavetimer"..victim].updatetask:Cancel()
				inst.HUD.controls["attackwavetimer"..victim].updatetask = nil
			end
			inst.HUD.controls["attackwavetimer"..victim]:Kill()
			inst.HUD.controls["attackwavetimer"..victim] = nil
			if counter[inst.userid] == nil then
				counter[inst.userid] = 0
			else
				counter[inst.userid] = counter[inst.userid] - 1
			end
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "RemoveTimerFromClient", RemoveTimerFromClient)



