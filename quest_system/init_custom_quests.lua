local QUEST_COMPONENT = GLOBAL.TUNING.QUEST_COMPONENT
local DecodeAndUnzipString = GLOBAL.DecodeAndUnzipString
local ZipAndEncodeStringBuffer = GLOBAL.ZipAndEncodeStringBuffer
local TheNet = GLOBAL.TheNet
local dumptable = GLOBAL.dumptable

local function EncodeQuest(quest)
	return ZipAndEncodeStringBuffer(json.encode(quest))
end

local function DecodeQuest(data)
	return json.decode(DecodeAndUnzipString(data))
end

local function LoadQuest(name, data)
	local quest_counter = 0
	if QUEST_COMPONENT.QUESTS[name] == nil then
		quest_counter = quest_counter + 1
		QUEST_COMPONENT.QUESTS[name] = data
		if data.difficulty then
			local diff_quest = "QUESTS_DIFFICULTY_"..data.difficulty
			if QUEST_COMPONENT[diff_quest] then
				QUEST_COMPONENT[diff_quest][name] = data
			end
		end
		if data.character then
			local char_quest = "QUESTS_"..data.character
			if QUEST_COMPONENT[char_quest] == nil then
				QUEST_COMPONENT[char_quest] = {}
			end
			local quest = QUEST_COMPONENT[char_quest]
			if quest[name] == nil then
				quest[name] = data
			end
			--adding quests to tables of specific difficulties
			local char_diff_quest = "QUESTS_"..data.character.."_DIFFICULTY_"..data.difficulty
			if QUEST_COMPONENT[char_diff_quest] == nil then
				QUEST_COMPONENT[char_diff_quest] = {}
			end
			local quest_ = QUEST_COMPONENT[char_diff_quest]
			if quest_[name] == nil then
				quest_[name] = data
			end
		end
	else
		print("[Quest System] Quests exists already!",name)
		dumptable(QUEST_COMPONENT.QUESTS[name])
	end
	return quest_counter
end
----------------------------------Creating a new file to save the custom quests-----------------------------------------------------
if TheNet:GetIsServer() or TheNet:IsDedicated() then

	--First idea of how to get own quests saved and loaded, but problematic because shared between worlds.SavePersistentString is better because only used in one world.

	--[[local own_quests
	local file = GLOBAL.io.open("own_quests.txt","r") 
	if file ~= nil then
		print("[Quest System] own_quests.txt file exists")
		if QUEST_COMPONENT.RESET_QUESTS == true then
			print("[Quest System] Resetting quests")
			local text = file:read("*all")
			local file_backup = GLOBAL.io.open("own_quests_backup.txt","w") 
			file_backup:write(text)
        	file_backup:close()
        	own_quests = {}
        	dumptable(own_quests)
        elseif QUEST_COMPONENT.RESET_QUESTS == 1 then
        	print("[Quest System] Taking the backup file")
        	local file_backup = GLOBAL.io.open("own_quests_backup.txt","r") 
        	local text = file_backup:read("*all")
        	own_quests = json.decode(text) ~= nil and json.decode(text) or {}
		else
			print("[Quest System] Loading quests normally")
			local text = file:read("*all")
			own_quests = json.decode(text)
		end
		file:close()
	else
		print("[Quest System] own_quests.txt doesn't exist")
		local file2 = GLOBAL.io.open("own_quests.txt","w") 
		file2:write("{}")
		local text = file2:read("*all")
		own_quests = json.decode(text)
		print("[Quest System] own_quests.txt exists now")
		file2:close()
	end

	if own_quests then
		if type(own_quests) == "table" then
			print("[Quest System] own_quests.txt is a table")
			for k,v in pairs(own_quests) do
				if v.name ~= nil and QUEST_COMPONENT.OWN_QUESTS[v.name] == nil then
					QUEST_COMPONENT.OWN_QUESTS[v.name] = v
				else
					print(v.name)
				end
			end
			dumptable(QUEST_COMPONENT.OWN_QUESTS)
		end
	end]]

	
	local file = GLOBAL.io.open("scripts/own_quests.lua","r") 
	if file ~= nil then
		file:close()
		print("[Quest System] own_quests.lua file exists, loading now!")
		local own_quests2 = require "own_quests"
		if type(own_quests2) == "table" then
			for _,v in pairs(own_quests2) do
				if v.name ~= nil and QUEST_COMPONENT.OWN_QUESTS2[v.name] == nil then
					QUEST_COMPONENT.OWN_QUESTS2[v.name] = v
				else
					print("[Quest System] Name is nil or this quest name exists already:",v.name)
					print("[Quest System] TUNING:",QUEST_COMPONENT.OWN_QUESTS2[v.name])
				end
			end
		end
	end
end



----------------------------------------------Adding the custom quests to clients--------------------------------------------------------

local function AddLocalQuests(_,player)
    print("[Quest System] Add Local Quests to",player)
    if player then
    	if QUEST_COMPONENT.OWN_QUESTS ~= nil and next(QUEST_COMPONENT.OWN_QUESTS) ~= nil then
	        for _,v in pairs(QUEST_COMPONENT.OWN_QUESTS) do
	        	devprint(player.userid,player,v.name,v.description,v.amount,v.points,v.difficulty)
	            SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),player.userid,EncodeQuest(v))
	        end
	    end
	    if QUEST_COMPONENT.OWN_QUESTS2 ~= nil and next(QUEST_COMPONENT.OWN_QUESTS2) ~= nil then
	        for _,v in pairs(QUEST_COMPONENT.OWN_QUESTS2) do
	        	devprint(player.userid,player,v.name,v.description,v.amount,v.points,v.difficulty)
	            SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),player.userid,EncodeQuest(v))
	        end
	    end

	    player:DoTaskInTime(2, function()
		    if QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
		    	local client_data = TheNet:GetClientTableForUser(player.userid)
		    	if client_data and client_data.admin == true then
		    		devprint("is admin")
		    		for _,v in pairs(QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS) do
		    			if v == true then
		    				SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),player.userid,v,1)
		    			end
		    		end
		    	else
		    		devprint("is not admin")
		    	end
		    end
		end)
    end
end

local PersistentData = require("persistentdata")
local DataContainer = PersistentData("quest_component")

AddSimPostInit(function()
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
	DataContainer:Load()
	local own_quests
	if QUEST_COMPONENT.RESET_QUESTS == 1 then
		own_quests = DataContainer:GetValue("quest_system_backup")
		DataContainer:SetValue("quest_system", own_quests)
    	DataContainer:Save()
	elseif QUEST_COMPONENT.RESET_QUESTS == true then
		own_quests = nil
		local own_quests_backup = DataContainer:GetValue("quest_system")
		DataContainer:SetValue("quest_system_backup", own_quests_backup)
    	DataContainer:Save()
	else
		own_quests = DataContainer:GetValue("quest_system")
	end
	if own_quests == nil then
		own_quests = {}
	end

	local quest_makers
	if QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
		quest_makers = DataContainer:GetValue("quest_system".."_questmakers")
		if quest_makers and type(quest_makers) == "table" then
			for k in pairs(quest_makers) do
				QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[k] = true
			end
		end
	end

	QUEST_COMPONENT.OWN_QUESTS = own_quests
    if own_quests ~= nil and next(own_quests) ~= nil then
    	local quests_own = 0
    	for k,v in pairs(own_quests) do
			if QUEST_COMPONENT.QUESTS[k] == nil then
				quests_own = quests_own + 1
				QUEST_COMPONENT.QUESTS[k] = v
				if v.difficulty then
					if QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
						QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
			else
				print("[Quest System] Quests exists already!",k)
				dumptable(QUEST_COMPONENT.QUESTS[k])
			end
		end
		print("[Quest System] Own Quests loaded! Amount :",quests_own)
	end
	if QUEST_COMPONENT.OWN_QUESTS2 ~= nil and next(QUEST_COMPONENT.OWN_QUESTS2) ~= nil then
		local quests_own = 0
		for name,data in pairs(QUEST_COMPONENT.OWN_QUESTS2) do
			quests_own = quests_own + LoadQuest(name,data)
		end
		print("[Quest System] own_quests.lua loaded! Amount :",quests_own)
	end
    TheWorld:ListenForEvent("ms_playerjoined",AddLocalQuests)

	--Load the old level values
	QUEST_COMPONENT.CURRENT_LEVELS = DataContainer:GetValue("quest_system_levels") or {}

end)

-------------------------------------------Global function to add or save custom quests-------------------------------------------------------

function GLOBAL.SaveOwnQuests()
	if not GLOBAL.TheWorld.ismastershard then return end
    print("[Quest System] Saving own quests!")
    DataContainer:SetValue("quest_system", QUEST_COMPONENT.OWN_QUESTS)
    DataContainer:SetValue("quest_system_questmakers",QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS)
	DataContainer:SetValue("quest_system_levels",QUEST_COMPONENT.CURRENT_LEVELS)
    DataContainer:Save()
    --[[if QUEST_COMPONENT.OWN_QUESTS ~= nil then
        local text = json.encode(QUEST_COMPONENT.OWN_QUESTS)
        local file = GLOBAL.io.open("own_quests.txt","w") 
        file:write(text)
        file:close()
    end]]
end

function GLOBAL.ExportOwnQuests(name)
	name = name or "No_Name"
	print("[Quest System] Exporting quests to own_quests_"..name..".txt!")
	local str = json.encode(QUEST_COMPONENT.OWN_QUESTS)
	local file = GLOBAL.io.open("own_quests_"..name..".txt","w") 
	file:write(str)
    file:close()
end

function GLOBAL.ImportOwnQuests(name,on_start)
	print("[Quest System] Importing quests from own_quests_"..name..".txt!")
	local file = GLOBAL.io.open("own_quests_"..name..".txt","r") 
	if file then
		local text = file:read("*all")
		local quests = json.decode(text)
		file:close()
		if type(quests) == "table" then
			for k,v in pairs(quests) do
				QUEST_COMPONENT.OWN_QUESTS[k] = v
				LoadQuest(k,v)
				if on_start ~= true then
					local encoded_quest = EncodeQuest(v)
					SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),nil,encoded_quest)
					SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddQuestToQuestPoolShards"),nil,encoded_quest)
				end
			end
		end
	end	
end

function GLOBAL.AddQuests(table, modname)
	print("[Quest System] Adding quests!")
	if table and type(table) == "table" then
		for _,v in pairs(table) do
			v.modname = modname
			LoadQuest(v.name,v)
		end
	else
		print("[Quest System] AddQuests: Wrong arguments passed, quests needs to be a table that can be sorted by pairs!")
		print(table)
	end
end

function GLOBAL.RegisterQuestModIcon(modname, atlas, tex)
	devprint("RegisterQuestModIcon", modname, atlas, tex)
	QUEST_COMPONENT.MOD_ICONS[modname] = {atlas = atlas, tex = tex}
end

function GLOBAL.SetLevelRewards(tab,level)
	if tab then
		if type(tab) == "table" then
			local LEVEL_REWARDS = QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS
			if level ~= nil then
				if LEVEL_REWARDS[level] ~= nil then
					LEVEL_REWARDS[level] = tab
				else
					print("[Quest System] SetLevelRewards: No rewards for this level!",level)
				end
			else
				LEVEL_REWARDS = tab
			end
		else
			print("[Quest System] SetLevelRewards: Table is not the correct type!",type(tab))
		end
	else
		print("[Quest System] SetLevelRewards: Table is nil!",tab)
	end
end

function GLOBAL.AddBosses(boss,difficulty)
	--devprint("AddBosses", boss, difficulty, boss.name)
	local boss_difficulty = QUEST_COMPONENT.BOSSES[difficulty]
	if difficulty and boss_difficulty ~= nil then
		if boss then
			if type(boss) == "table" then
				table.insert(boss_difficulty,boss)
			else
				print("[Quest System] AddBosses: Boss is not the correct type!",type(boss))
			end
		else
			print("[Quest System] AddBosses: Boss is nil!",boss)
		end
	else
		print("[Quest System] AddBosses: Difficulty is nil or doesn't exist!",difficulty)
		if boss_difficulty then
			print(boss_difficulty)
		end
	end
end

local counter = {}

function GLOBAL.AddCustomGoals(goals,modname)
	devprint("AddCustomGoals",goals,modname)
	if modname ~= nil then
		if goals and type(goals) == "table" then
			counter[modname] = counter[modname] or 1
			for _,v in ipairs(goals) do
				local tab = {}
				for kk,vv in pairs(v) do
					tab[kk] = vv
				end

				local key 
				if tab.prefab ~= nil then
					tab.data = tab.prefab
					key = tab.data
				else
					key = tab.text or (counter[modname] or "")..(tab.number)
					tab.data = "start_fn_"..key
				end
				tab.modname = modname..(tab.number or counter[modname])
				QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[key] = tab
				counter[modname] = counter[modname] + 1

			end
		else
			print("[Quest System] AddCustomGoals: Goal is nil or wrong type!",goals)
		end
	else
		print("[Quest System] AddCustomGoals: Workshopnumber must be defined!",modname)
	end
end

--GLOBAL.AddCustomGoals({{text = "test",data = "test2",fn = function() print("it works") end,tex = "test.tex",atlas = "test.xml"},{text = "test",data = "test2",prefab = "pigman"}},"ModName as Test")

function GLOBAL.AddCustomRewards(rewards)
	if rewards then
		if type(rewards) == "table" then
			for _,v in pairs(rewards) do
				if type(v) == "table" then
					local dat = { text = v[2],data = v[1]}
					table.insert(QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
				else 
					local dat = { text = GLOBAL.STRINGS.NAMES[string.upper(v)] or "No Name",data = v}
					table.insert(QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
				end
			end
		else
			print("[Quest System] AddCustomRewards: rewards needs to be a table!",type(rewards))
		end
	else
		print("[Quest System] AddCustomRewards: rewards is nil!",rewards)
	end
end

function GLOBAL.AddCustomFunctionRewards(rewards)
	if rewards then
		if type(rewards) == "table" then
			for _,v in pairs(rewards) do
				if type(v) == "table" then
					local dat = { text = v.text,data = ":func:"..v.name}
					QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[":func:"..v.name] = {v.fn,v.text}
					table.insert(QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
				else
					print("[Quest System] AddCustomFunctionRewards: rewards needs to be a table!",type(v))
				end
			end
		else
			print("[Quest System] AddCustomFunctionRewards: rewards needs to be a table!",type(rewards))
		end
	else
		print("[Quest System] AddCustomFunctionRewards: rewards is nil!",rewards)
	end
end

function GLOBAL.SetBossFightRewards(difficulty,rewards,overwrite)
	local BOSSFIGHT_REWARDS = QUEST_COMPONENT.BOSSFIGHT_REWARDS
	if difficulty and BOSSFIGHT_REWARDS[difficulty] then
		if rewards and type(rewards) == "table" then
			if overwrite == true then
				BOSSFIGHT_REWARDS[difficulty] = rewards
			else
				for _,v in pairs(rewards) do
					table.insert(BOSSFIGHT_REWARDS[difficulty],v)
				end
			end
		else
			print("[Quest System] SetBossFightRewards: rewards is nil or wrong type!",rewards)
		end
	else
		print("[Quest System] SetBossFightRewards: difficulty is nil or wrong type!",difficulty)
	end
end

local function GetCurrentAmount(player,quest_name)
	local quest_component = player.components.quest_component
	if quest_component then
		if quest_component.quests[quest_name] then
			return quest_component.quests[quest_name].current_amount or 0
		end
	end
	return 0
end

local function GetValues(player,quest_name,value_name)
	local quest_component = player.components.quest_component
	if quest_component == nil then
		return
	end
	local value = 0
	local saved_value = quest_component:GetQuestData(quest_name,value_name)
	return saved_value or value
end

local function RemoveValues(player,quest_name)
	local quest_component = player.components.quest_component
	if quest_component == nil then
		return
	end
	quest_component.quest_data[quest_name] = nil
end

local function MakeScalable(inst, amount, quest_name, getScaleFn)
	local quest_component = inst.components.quest_component
	local max_scale = quest_component and quest_component.scaled_quests[quest_name] and quest_component.scaled_quests[quest_name] + 1 or 1
	local scale = getScaleFn and getScaleFn(max_scale) or math.random(1,max_scale)
	return {scale = scale}
end

local function ScaleQuest(inst,quest,val)
	local quest_component = inst.components.quest_component
	if quest_component then
		quest_component.scaled_quests[quest] = val
	end
end

local function ScaleEnd(inst,items,quest_name)
	local quest_component = inst.components.quest_component
	local quest = quest_component.quests[quest_name]
	local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
	local old_scale = quest_component.scaled_quests[quest_name]
	if old_scale then
		scale = math.max(old_scale,scale)
	end
	ScaleQuest(inst,quest_name,scale)
end

local function OnForfeit(inst,fn,quest_name)
	local OnFinishedQuest = function() end
	local function OnForfeitedQuest(_inst,name)
		if name == quest_name then
			fn(_inst)
			_inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
			_inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
		end
	end
	OnFinishedQuest = function(_inst,name)
		if name == quest_name then
			fn(_inst)
			_inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
			_inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
		end
	end
	inst:ListenForEvent("forfeited_quest",OnForfeitedQuest)
	inst:ListenForEvent("finished_quest",OnFinishedQuest)
end

function GLOBAL.SetQuestSystemEnv(env)
	env = env or GLOBAL.getfenv(2)
	env.SaveOwnQuests = GLOBAL.SaveOwnQuests
	env.ExportOwnQuests = GLOBAL.ExportOwnQuests
	env.ImportOwnQuests = GLOBAL.ImportOwnQuests
	env.AddQuests = GLOBAL.AddQuests
	env.RegisterQuestModIcon = GLOBAL.RegisterQuestModIcon
	env.SetLevelRewards = GLOBAL.SetLevelRewards
	env.AddBosses = GLOBAL.AddBosses
	env.SetBossFightRewards = GLOBAL.SetBossFightRewards
	env.AddCustomGoals = GLOBAL.AddCustomGoals
	env.AddCustomRewards = GLOBAL.AddCustomRewards
	env.AddCustomFunctionRewards = GLOBAL.AddCustomFunctionRewards
	env.GetQuestString = GLOBAL.GetQuestString
	env.GetRewardString = GLOBAL.GetRewardString
	env.GetKillString = GLOBAL.GetKillString
	env.GetCurrentAmount = GetCurrentAmount
	env.GetValues = GetValues
	env.RemoveValues = RemoveValues
	env.MakeScalable = MakeScalable
	env.ScaleEnd = ScaleEnd
	env.OnForfeit = OnForfeit
	env.custom_functions = QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS
	GLOBAL.setfenv(1,env)
end