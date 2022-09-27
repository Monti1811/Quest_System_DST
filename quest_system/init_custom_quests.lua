----------------------------------Creating a new file to save the custom quests-----------------------------------------------------
if TheNet:GetIsServer() or TheNet:IsDedicated() then

	--First idea of how to get own quests saved and loaded, but problematic because shared between worlds.SavePersistenString is better because only used in one world.

	--[[local own_quests
	local file = GLOBAL.io.open("own_quests.txt","r") 
	if file ~= nil then
		print("[Quest System] own_quests.txt file exists")
		if GLOBAL.TUNING.QUEST_COMPONENT.RESET_QUESTS == true then
			print("[Quest System] Resetting quests")
			local text = file:read("*all")
			local file_backup = GLOBAL.io.open("own_quests_backup.txt","w") 
			file_backup:write(text)
        	file_backup:close()
        	own_quests = {}
        	GLOBAL.dumptable(own_quests)
        elseif GLOBAL.TUNING.QUEST_COMPONENT.RESET_QUESTS == 1 then
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
				if v.name ~= nil and GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[v.name] == nil then
					GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[v.name] = v
				else
					print(v.name)
				end
			end
			GLOBAL.dumptable(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS)
		end
	end]]

	
	local file = GLOBAL.io.open("scripts/own_quests.lua","r") 
	if file ~= nil then
		file:close()
		print("[Quest System] own_quests.lua file exists, loading now!")
		local own_quests2 = require "own_quests"
		if type(own_quests2) == "table" then
			for k,v in pairs(own_quests2) do
				if v.name ~= nil and GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2[v.name] == nil then
					GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2[v.name] = v
				else
					print("[Quest System] Name is nil or this quest name exists already:",v.name)
					print("[Quest System] TUNING:",GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2[v.name])
				end
			end
		end
	end
end



----------------------------------------------Adding the custom quests to clients--------------------------------------------------------

local function AddLocalQuests(world,player)
    print("[Quest System] Add Local Quests to",player)
    if player then
    	if GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS ~= nil and next(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS) ~= nil then
	        for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS) do
	        	local rewards = {}
	        	local count = 0
	        	for a,b in pairs(v.rewards) do
	        		count = count + 1
	        		rewards[count] = a.."|"..b
	        	end
	        	local victim = v.victim
	        	if v.victim == "" or v.victim == nil then
	        		victim = v.start_fn
	        		local GOAL_TABLE =  GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS_OUTDATED[victim]
	        		if GOAL_TABLE then
						for kk,vv in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS) do
							if vv.text == GOAL_TABLE.text then
								devprint("was the same",vv.text)
								GLOBAL.devdumptable(GOAL_TABLE)
								start_fn = "start_fn_"..GOAL_TABLE.text
								GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[k].start_fn = start_fn
								devprint(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[k].start_fn)
							end
						end
					end
				end
	        	devprint(player.userid,player,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	        	GLOBAL.devdumptable(rewards)
	            SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),player.userid,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	        end
	    end
	    if GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2 ~= nil and next(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2) ~= nil then
	        for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2) do
	        	local rewards = {}
	        	local count = 0
	        	for a,b in pairs(v.rewards) do
	        		count = count + 1
	        		rewards[count] = a.."|"..b
	        	end
	        	local victim = v.victim
	        	if v.victim == "" or v.victim == nil then
	        		victim = v.start_fn
	        	end
	        	devprint(player.userid,player,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	        	GLOBAL.dumptable(rewards)
	            SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),player.userid,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	        end
	    end

	    player:DoTaskInTime(2, function(inst)
		    if GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
		    	local client_data = GLOBAL.TheNet:GetClientTableForUser(player.userid) 
		    	if client_data and client_data.admin == true then
		    		devprint("is admin")
		    		for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS) do
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
	if GLOBAL.TUNING.QUEST_COMPONENT.RESET_QUESTS == 1 then
		own_quests = DataContainer:GetValue("quest_system".."_backup")
		DataContainer:SetValue("quest_system", own_quests)
    	DataContainer:Save()
	elseif GLOBAL.TUNING.QUEST_COMPONENT.RESET_QUESTS == true then
		own_quests = nil
		own_quests_backup = DataContainer:GetValue("quest_system")
		DataContainer:SetValue("quest_system".."_backup", own_quests_backup)
    	DataContainer:Save()
	else
		own_quests = DataContainer:GetValue("quest_system")
	end
	if own_quests == nil then
		own_quests = {}
	end

	local quest_makers
	if GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
		quest_makers = DataContainer:GetValue("quest_system".."_questmakers")
		if quest_makers and type(quest_makers) == "table" then
			for k,v in pairs(quest_makers) do
				GLOBAL.TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[k] = true
			end
		end
	end

	GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS = own_quests
    if GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS ~= nil and next(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS) ~= nil then
    	local quests_own = 0
    	for k,v in pairs(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS) do
			if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k] == nil then
				quests_own = quests_own + 1
				GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k] = v
				if v.difficulty then
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
			else
				print("[Quest System] Quests exists already!",k)
				GLOBAL.dumptable(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k])
			end
		end
		print("[Quest System] Own Quests loaded! Amount :",quests_own)
	end
	if GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2 ~= nil and next(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2) ~= nil then
		local quests_own = 0
		for k,v in pairs(own_quests2) do
			if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k] == nil then
				quests_own = quests_own + 1
				GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k] = v
				if v.difficulty then
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
				if v.character then
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] = {}
					end
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][k] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][k] = v
					end
					--adding quests to tables of specific difficulties
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] = {}
					end
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][k] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
			else
				print("[Quest System] Quests exists already!",k)
				GLOBAL.dumptable(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[k])
			end
		end
		print("[Quest System] own_quests.lua loaded! Amount :",quests_own)
	end
    TheWorld:ListenForEvent("ms_playerjoined",AddLocalQuests)
end)

-------------------------------------------Global function to add or save custom quests-------------------------------------------------------

function GLOBAL.SaveOwnQuests()
	if not GLOBAL.TheWorld.ismastershard then return end
    print("[Quest System] Saving own quests!")
    DataContainer:SetValue("quest_system", GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS)
    DataContainer:SetValue("quest_system".."_questmakers",GLOBAL.TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS)
    DataContainer:Save()
    --[[if GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS ~= nil then
        local text = json.encode(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS)
        local file = GLOBAL.io.open("own_quests.txt","w") 
        file:write(text)
        file:close()
    end]]
end

function GLOBAL.ExportOwnQuests(name)
	name = name or "No_Name"
	print("[Quest System] Exporting quests to own_quests_"..name..".txt!")
	local str = json.encode(GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS)
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
				GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS[k] = v
				if v.difficulty then
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
				if v.character then
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] = {}
					end
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][k] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][k] = v
					end
					--adding quests to tables of specific difficulties
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] = {}
					end
					if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][k] == nil then
						GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][k] = v
					end
				end
				local rewards = {}
	        	local count = 0
	        	for a,b in pairs(v.rewards) do
	        		count = count + 1
	        		rewards[count] = a.."|"..b
	        	end
	        	local victim = v.victim
	        	if v.victim == "" or v.victim == nil then
	        		victim = v.start_fn
	        	end
	        	if on_start ~= true then
	            	SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddQuestToQuestPool"),nil,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	            	SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddQuestToQuestPoolShards"),nil,v.name,victim,v.description,v.amount,v.points,v.difficulty,rewards[1],rewards[2],rewards[3])
	            end
			end
		end
	end	
end

function GLOBAL.AddQuests(table)
	print("[Quest System] Adding quests!")
	if table and type(table) == "table" then
		for k,v in pairs(table) do
			if v.name ~= nil and type(v.name) == "string" then
				if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[v.name] == nil then
				 	GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[v.name] = v
					if v.difficulty then
						if v.character then
							--adding quests to tables of character-specific quests
							if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] == nil then
								GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character] = {}
							end
							if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][v.name] == nil then
								GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character][v.name] = v
							end
							--adding quests to tables of specific difficulties
							if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] == nil then
								GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty] = {}
							end
							if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][v.name] == nil then
								GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_"..v.character.."_DIFFICULTY_"..v.difficulty][v.name] = v
							end
						else
							--adding quests to difficulty specific tables
							if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
								GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][v.name] = v
							end
						end
					end
				else
				 	print("[Quest System] AddQuests: This quest name exists already!",v.name)
				end
			else
				print("[Quest System] AddQuests: Name is not the correct format or empty!",v.name)
			end
		end
	else
		print("[Quest System] AddQuests: Wrong arguments passed, quests needs to be a table that can be sorted by pairs!")
		print(table)
	end
end

function GLOBAL.SetLevelRewards(tab,level)
	if tab then
		if type(tab) == "table" then
			if level ~= nil then
				if GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS[level] ~= nil then
					GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS[level] = tab
				else
					print("[Quest System] SetLevelRewards: No rewards for this level!",level)
				end
			else
				GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.LEVEL_REWARDS = tab
			end
		else
			print("[Quest System] SetLevelRewards: Table is not the correct type!",type(tab))
		end
	else
		print("[Quest System] SetLevelRewards: Table is nil!",tab)
	end
end

function GLOBAL.AddBosses(boss,difficulty)
	if difficulty and GLOBAL.TUNING.QUEST_COMPONENT.BOSSES[difficulty] ~= nil then
		if boss then
			if type(boss) == "table" then
				table.insert(GLOBAL.TUNING.QUEST_COMPONENT.BOSSES[difficulty],boss)
			else
				print("[Quest System] AddBosses: Boss is not the correct type!",type(boss))
			end
		else
			print("[Quest System] AddBosses: Boss is nil!",boss)
		end
	else
		print("[Quest System] AddBosses: Difficulty is nil or doesn't exist!",difficulty)
		if GLOBAL.TUNING.QUEST_COMPONENT.BOSSES[difficulty] ~= nil then
			print(GLOBAL.TUNING.QUEST_COMPONENT.BOSSES[difficulty])
		end
	end
end

local counter = {}

function GLOBAL.AddCustomGoals(goals,modname)
	devprint("AddCustomGoals",goals,modname)
	if modname ~= nil then
		if goals and type(goals) == "table" then
			counter[modname] = counter[modname] or 1
			for k,v in ipairs(goals) do
				local tab = {}
				for kk,vv in pairs(v) do
					tab[kk] = vv
				end

				--------------outdated---------------
				if tab.prefab ~= nil then
					tab.data = tab.prefab
				else
					tab.data = tab.number or counter[modname]
				end
				tab.modname = modname..(tab.number or counter[modname])
				GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS_OUTDATED[modname..counter[modname]] = tab
				counter[modname] = counter[modname] + 1
				-------------------------------------
				local key 
				if tab.prefab ~= nil then
					tab.data = tab.prefab
					key = tab.data
				else
					key = tab.text or (counter[modname] or "")..(tab.number)
					tab.data = "start_fn_"..key
				end
				tab.modname = modname..(tab.number or counter[modname])
				GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[key] = tab
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
			for k,v in pairs(rewards) do
				if type(v) == "table" then
					local dat = { text = v[2],data = v[1]}
					table.insert(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
				else 
					local dat = { text = GLOBAL.STRINGS.NAMES[string.upper(v)] or "No Name",data = v}
					table.insert(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
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
			for k,v in pairs(rewards) do
				if type(v) == "table" then
					local dat = { text = v.text,data = ":func:"..v.name}
					GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[":func:"..v.name] = {v.fn,v.text}
					table.insert(GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_ITEMS,dat)
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
	if difficulty and GLOBAL.TUNING.QUEST_COMPONENT.BOSSFIGHT_REWARDS[difficulty] then
		if rewards and type(rewards) == "table" then
			if overwrite == true then
				GLOBAL.TUNING.QUEST_COMPONENT.BOSSFIGHT_REWARDS[difficulty] = rewards
			else
				for k,v in pairs(rewards) do
					table.insert(GLOBAL.TUNING.QUEST_COMPONENT.BOSSFIGHT_REWARDS[difficulty],v)
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
	if player and player.components.quest_component then
		if player.components.quest_component.quests[quest_name] then
			return player.components.quest_component.quests[quest_name].current_amount or 0
		end
	end
	return 0
end

local function GetValues(player,quest_name,value_name)
	if player.components.quest_component == nil then return end
	local value = 0
	local saved_value = player.components.quest_component:GetQuestData(quest_name,value_name)
	return saved_value or value
end

local function RemoveValues(player,quest_name)
	if player.components.quest_component == nil then return end
	player.components.quest_component.quest_data[quest_name] = nil
end

local function MakeScalable(inst,amount,quest_name)
	local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
	local scale = math.random(1,max_scale)
	return {scale = scale}
end

local function ScaleQuest(inst,quest,val)
	if inst.components.quest_component then
		inst.components.quest_component.scaled_quests[quest] = val
	end
end

local function ScaleEnd(inst,items,quest_name)
	local quest = inst.components.quest_component.quests[quest_name]
	local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
	local old_scale = inst.components.quest_component.scaled_quests[quest_name]
	if old_scale then
		scale = math.max(old_scale,scale)
	end
	ScaleQuest(inst,quest_name,scale)
end

local function OnForfeit(inst,fn,quest_name)
	local function OnForfeitedQuest(inst,name)
		if name == quest_name then
			fn(inst)
			inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
		end
	end
	inst:ListenForEvent("forfeited_quest",OnForfeitedQuest)
end

function GLOBAL.SetQuestSystemEnv(env)
	env = env or GLOBAL.getfenv(2)
	env.SaveOwnQuests = GLOBAL.SaveOwnQuests
	env.ExportOwnQuests = GLOBAL.ExportOwnQuests
	env.ImportOwnQuests = GLOBAL.ImportOwnQuests
	env.AddQuests = GLOBAL.AddQuests
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
	env.custom_functions = GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS
	GLOBAL.setfenv(1,env)
end