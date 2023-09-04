--------------------------Local Variables---------------------------------
local DecodeAndUnzipString = GLOBAL.DecodeAndUnzipString
local ZipAndEncodeStringBuffer = GLOBAL.ZipAndEncodeStringBuffer
local QUEST_COMPONENT = GLOBAL.TUNING.QUEST_COMPONENT
local SpawnPrefab = GLOBAL.SpawnPrefab
local AllPlayers = GLOBAL.AllPlayers

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
		local quest_component = inst.components.quest_component
		if quest_component then
			quest_component.max_amount_of_quests = quest_component.max_amount_of_quests + num
			quest_component.additional_quest_slots = quest_component.additional_quest_slots + num
		end
	end,
}

local function replace_char(pos, str, r)
	return ("%s%s%s"):format(str:sub(1,pos-1), r, str:sub(pos+1))
end

--RPC to get level rewards by clicking on them on the quest board
local function GetLevelRewards(inst,level)
	devprint("GetLevelRewards",inst,level)
	if inst.components.inventory and level then
		local level_reward = QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS[level] or {pigskin = 3,butterfly = 3}
		for k,v in pairs(level_reward) do
			if custom_rewards[k] then
				custom_rewards[k](inst,v)
			else
				for _ = 1,v do
					local item = SpawnPrefab(k)
					if item then
						inst.components.inventory:GiveItem(item)
					end
				end
			end
		end
		local quest_component = inst.components.quest_component
		quest_component.accepted_level_rewards = replace_char(level/5, quest_component.accepted_level_rewards, 0)
	end
end

AddModRPCHandler("Quest_System_RPC", "GetLevelRewards", GetLevelRewards)

--RPC to mark users as users that can create quests.
local function AddCustomQuestMakerToServer(_,userid,bool)
	devprint("AddCustomQuestMakerToServer",userid,bool)
	if userid then
		--[[if bool == 1 then
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end]]
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,userid,bool)
        SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddCustomQuestMakerToShards"),nil,userid,bool)
        local PersistentData = require("persistentdata")
		local DataContainer = PersistentData("quest_component")
		local world_key = GLOBAL.TheNet:GetSessionIdentifier()
        DataContainer:SetValue(world_key.."_questmakers", QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS)
    	DataContainer:Save()
	end
end

AddModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToServer", AddCustomQuestMakerToServer)

--RPC to add a quest. Is sent form the quest board after creating the quest, is the first one that is called
local function AddQuestToQuestPoolServer(inst,data)
	devprint("AddQuestToQuestPoolServer",inst,data)
	--local quest = json.decode(DecodeAndUnzipString(data))
	--Don't run MakeQuest here as SendModRPCToShard also runs on this shard
	SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddQuestToQuestPoolShards"),nil,data)
	--for k,v in pairs(QUEST_COMPONENT.QUESTS) do
		--print(k,v)
	--end
end

AddModRPCHandler("Quest_System_RPC", "AddQuestToQuestPoolServer", AddQuestToQuestPoolServer)

local function DeleteQuest(_,name)
	if name then
		SendModRPCToShard(GetShardModRPC("Quest_System_RPC","RemoveQuestShard"),nil,name)
	end
end

AddModRPCHandler("Quest_System_RPC", "DeleteQuest", DeleteQuest)

local function Make_Random_Quest(inst)
	devprint("Make_Random_Quest")
	local tab = MakeRandomQuest()
	GLOBAL.dumptable(tab)
	local json_quest = ZipAndEncodeStringBuffer(json.encode(quest))
	AddQuestToQuestPoolServer(inst,json_quest)
end

AddModRPCHandler("Quest_System_RPC", "Make_Random_Quest", Make_Random_Quest)

local function GiveQuest(inst, name)
	inst:DoTaskInTime(0.5,function()
		for _ = 1, QUEST_COMPONENT.GIVE_CREATOR_QUEST do
			local request = SpawnPrefab("request_quest_specific")
			if request and inst.components.inventory then
				request:SetQuest(name)
				inst.components.inventory:GiveItem(request)
			end
		end
	end)
end

AddModRPCHandler("Quest_System_RPC", "GiveQuest", GiveQuest)

----------------------------ShardRPC-----------------------------------------

--RPC to add a quest to the different shards.
local function AddQuestToQuestPoolShards(shard_id, data)
	devprint("AddQuestToQuestPoolShards",shard_id, data)
	local quest = json.decode(DecodeAndUnzipString(data))
	local name = quest.name

	QUEST_COMPONENT.QUESTS[name] = quest
	QUEST_COMPONENT.OWN_QUESTS[name] = quest
	if QUEST_COMPONENT["QUESTS_DIFFICULTY_"..quest.difficulty] then
		QUEST_COMPONENT["QUESTS_DIFFICULTY_"..quest.difficulty][name] = quest
	end

	devdumptable(quest)
	--Send it also to the clients so that they have the same information as the server
	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),nil,data)
	devprint(shard_id,data)
	--for k,v in pairs(QUEST_COMPONENT.QUESTS) do
		--print(k,v)
	--end
end

AddShardModRPCHandler("Quest_System_RPC", "AddQuestToQuestPoolShards", AddQuestToQuestPoolShards)

--RPC to mark users as users that can create quests.
local function AddCustomQuestMakerToShards(shard_id,userid,bool)
	devprint("AddCustomQuestMakerToShards",shard_id,userid,bool)
	if userid then
		if bool == 1 then
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,userid,bool)
	end
end

AddShardModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToShards", AddCustomQuestMakerToShards)

local function RemoveQuestShard(shard_id,name)
	devprint("RemoveQuestShard",shard_id,name)
	if QUEST_COMPONENT.QUESTS[name] ~= nil then
        for _,v in ipairs(AllPlayers) do
			local quest_component = v.components.quest_component
            if quest_component then
                quest_component:RemoveQuest(name)
            end
        end
        QUEST_COMPONENT.QUESTS[name] = nil
        QUEST_COMPONENT.OWN_QUESTS[name] = nil
        SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "DeleteQuestFromClient"),nil,name)
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

if QUEST_COMPONENT.KEEP_LEVELS == 1 then

	local function SubmitShardLevels(shard_id, data)
		devprint("SubmitShardLevels",shard_id, data)
		local level_data = json.decode(data)
		for userid, lvl in pairs(level_data) do
			QUEST_COMPONENT.CURRENT_LEVELS[userid] = lvl
		end
	end

	AddShardModRPCHandler("Quest_System_RPC", "SubmitShardLevels", SubmitShardLevels)

	local function GetShardLevels(shard_id)
		devprint("GetShardLevels",shard_id)
		local data = {}
		for _, player in ipairs(GLOBAL.AllPlayers) do
			data[player.userid] = {
				player.components.quest_component.level,
				player.components.quest_component.points,
			}
		end
		--Only send to values to the mastershard
		SendModRPCToShard(GetShardModRPC("Quest_System_RPC","SubmitShardLevels"),1,json.encode(data))
	end

	AddShardModRPCHandler("Quest_System_RPC", "GetShardLevels", GetShardLevels)

end
---------------------------ClientRPC----------------------------------

--RPC to add a certain quest to a client. Better than a netvar as I can change the name so I don't need to make one for each different quest
local function AddQuestToClient(inst,data)
	devprint("AddQuestToClient",inst,data)
	local replica = inst.replica.quest_component
	data = json.decode(data)
	if replica then
		replica:AddQuest(data.name,data.current_amount,data.custom_vars)
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddQuestToClient", AddQuestToClient)

--RPC to update quests on the client
local function UpdateQuestOnClient(inst,data)
	devprint("UpdateQuestOnClient",inst,data)
	data = json.decode(data)
	if inst and inst.replica.quest_component then
		inst.replica.quest_component:UpdateQuest(data.name,data.amount,data.reset,data.set_amount)
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
	QUEST_COMPONENT.QUESTS[name] = nil
	QUEST_COMPONENT.OWN_QUESTS[name] = nil
end

AddClientModRPCHandler("Quest_System_RPC", "DeleteQuestFromClient", DeleteQuestFromClient)

--RPC to add a quest to the different clients on the same shard
local function AddQuestToQuestPool(data)
	devprint("AddQuestToQuestPool",data)
	local quest = json.decode(DecodeAndUnzipString(data))
	local name = quest.name
	for _,qu in ipairs(QUEST_COMPONENT.QUESTS) do
		if name == qu.name then
			print("[Quest System] This quest exists already:",name)
			return
		end	
    end

	QUEST_COMPONENT.QUESTS[name] = quest
	QUEST_COMPONENT.OWN_QUESTS[name] = quest
	devdumptable(QUEST_COMPONENT.QUESTS[name])

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
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = true
		else
			QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] = nil
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "AddCustomQuestMakerToClient", AddCustomQuestMakerToClient)

--RPC to show the different temp bonis on the client
local function AddTempBoniToClient(inst,num,boni,empty,time)
	devprint("AddTempBoniToClient",inst,num,boni,empty,time)
	if num and inst.HUD and inst.HUD.controls then
		if empty then
			if inst.HUD.controls["tempboni"..num] then
				inst.HUD.controls["tempboni"..num]:Hide()
			end
		else
			if boni and inst.HUD.controls["tempboni"..num] then
				inst.HUD.controls["tempboni"..num]:SetBoniPicture(boni,time)
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

--RPC to change the amount of enemies defeated on the client
local function ChangeEnemiesDefeated(inst,victim)
	devprint("ChangeEnemiesDefeated",inst,victim)
	if inst.HUD and victim then
		if inst.HUD.controls["attackwavetimer"..victim] ~= nil then
			local self = inst.HUD.controls["attackwavetimer"..victim]
			if self then
				self.counter = self.counter + 1
				self.wave:SetString(string.format( STRINGS.QUEST_COMPONENT.ATTACKWAVES.WAVE,self.wave_num, self.counter, self.victims_num))
			end
		end
	end
end

AddClientModRPCHandler("Quest_System_RPC", "ChangeEnemiesDefeated", ChangeEnemiesDefeated)

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



