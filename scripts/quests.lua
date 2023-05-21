--Defining variables

local farm_plants_defs = require("prefabs/farm_plant_defs")
local FrogKing = require("quest_util/frogking")
local Q_TUNING = STRINGS.QUEST_COMPONENT

--Helper functions

local function CheckForLastSeason(inst,quest_name,old_season)
	local curr_season = TheWorld.state.season or "autumn"
	local old_season = old_season or "autumn"
	if curr_season ~= old_season then
		local num_old 
		local num_new
		local seasons = {"autumn","winter","spring","summer"}
		for k,v in ipairs(seasons) do
			if v == curr_season then
				num_new = k
			end
			if v == old_season then
				num_old = k
			end
		end
		if num_new < num_old then
			num_new = num_new + 4
		end
		inst:PushEvent("quest_update",{quest = quest_name,amount = -(num_new-num_old)})
	end
end

local function GetSpawnPoint(pt,radius)
    local theta = math.random() * 2 * PI
    radius = radius or math.random(6,14)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or pt
end

local function OnForfeit(inst,fn,quest_name)
	local OnFinishedQuest = function()  end
	local function OnForfeitedQuest(inst,name)
		if name == quest_name then
			fn(inst)
			inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
			inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
		end
	end
	OnFinishedQuest = function(inst,name)
		if name == quest_name then
			fn(inst)
			inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
			inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
		end
	end
	inst:ListenForEvent("forfeited_quest",OnForfeitedQuest)
	inst:ListenForEvent("finished_quest",OnFinishedQuest)
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

local function ScaleQuest(inst,quest,val)
	inst.components.quest_component.scaled_quests[quest] = val
end

--Quests

local quests = {
	--1
	{
	name = "The Wicked Mist Fury",
	victim = "spider_water",
	counter_name = nil,
	description = GetQuestString("The Wicked Mist Fury","DESCRIPTION"),
	amount = 10,
	rewards = {spidereggsack = 1, silk = 12},
	points = 200,
	start_fn = nil,
	onfinished = nil,
	difficulty = 2,
	tex = "spider_water.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("spider_water",10),
	},
	--2
	{
	name = "The Powerful Shadow from Below",
	victim = "oceanhorror",
	counter_name = nil,
	description = GetQuestString("The Powerful Shadow from Below","DESCRIPTION"),
	amount = 5,
	rewards = { nightsword = 1, nightmarefuel = 20},
	points = 200,
	start_fn = nil,
	onfinished = nil,
	difficulty = 3,
	tex = "oceanhorror.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("oceanhorror",5),
	},
	--3
	{
	name = "The Reckoning of the Gestalt",
	victim = "",
	counter_name = GetQuestString("The Reckoning of the Gestalt","COUNTER"),
	description = GetQuestString("The Reckoning of the Gestalt","DESCRIPTION",120),
	amount = 120,
	rewards = {moonglass = 5, moonrocknugget = 5},
	points = 75,
	start_fn = function(inst,amount,quest_name)
		local time = GetCurrentAmount(inst,quest_name)
		local function CheckSanity(inst)
			if inst.components.sanity then
				if inst.components.sanity.mode == SANITY_MODE_LUNACY and inst.components.sanity:GetPercent() > 0.85 then
					time = time + 1
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if time >= amount then
						if inst.check_sanity_quest_component ~= nil then
        					inst.check_sanity_quest_component:Cancel()
        					inst.check_sanity_quest_component = nil
    					end
						return
					end
				else
					if time ~= 0 then
						time = 0
						inst:PushEvent("quest_update",{quest = quest_name,reset = true})
					end
				end
			end
			inst.check_sanity_quest_component = inst:DoTaskInTime(1,CheckSanity)
		end
		if inst.check_sanity_quest_component ~= nil then
        	inst.check_sanity_quest_component:Cancel()
        	inst.check_sanity_quest_component = nil
    	end
		CheckSanity(inst)
		local function OnForfeitedQuest(inst)
			if inst.check_sanity_quest_component ~= nil then
        		inst.check_sanity_quest_component:Cancel()
        		inst.check_sanity_quest_component = nil
    		end
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "celestial.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Reckoning of the Gestalt","HOVER",120),
	},
	--4
	{
	name = "The Corrupt Prophecy Revenge",
	victim = "glommer",
	counter_name = nil,
	description = GetQuestString("The Corrupt Prophecy Revenge","DESCRIPTION"),
	amount = 1,
	rewards = {panflute = 1, mandrake = 1},
	points = 150,
	start_fn = nil,
	onfinished = nil,
	difficulty = 1,
	tex = "glommer.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("glommer",1),
	},
	--5
	{
	name = "The Monstrous Delicacy",
	victim = "",
	counter_name = GetQuestString("The Monstrous Delicacy","COUNTER"),
	description = GetQuestString("The Monstrous Delicacy","DESCRIPTION"),
	amount = 5,
	rewards = {healingsalve = 5, baconeggs = 1},
	points = 100,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst,"monsterlasagna",amount,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "monsterlasagna.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Monstrous Delicacy","HOVER",5),
	},
	--6
	{
	name = "The Explorers End",
	victim = "alterguardian_phase3",
	counter_name = nil,
	description = GetQuestString("The Monstrous Delicacy","DESCRIPTION"),
	amount = 1,
	rewards = {moonglass_charged = 5,["Duplicate items"] = "Inventory+Equipped"},
	points = 3000,
	start_fn = nil,
	onfinished = function(inst)
		local old_items = {}
		if inst.components.inventory then
			for k,v in pairs(inst.components.inventory.itemslots) do
				local _item = v:GetSaveRecord()
				table.insert(old_items,_item)
			end
			for k,v in pairs(inst.components.inventory.equipslots) do
				local _item = v:GetSaveRecord()
				table.insert(old_items,_item)
			end
			for k,v in ipairs(old_items) do
				local item = SpawnSaveRecord(v)
				inst.components.inventory:GiveItem(item)
			end
		end
	end,
	difficulty = 5,
	tex = "alterguardian_phase3.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("alterguardian_phase3",1),
	["reward_Duplicate items_tex"] = "backpack.tex",
	["reward_Duplicate items_atlas"] = "images/inventoryimages1.xml",
	},
	--7
	{
	name = "Within the Labyrinth",
	victim = "minotaur",
	counter_name = nil,
	description = GetQuestString("Within the Labyrinth","DESCRIPTION"),
	amount = 1,
	rewards = {eyeturret_item = 1},
	points = 1500,
	start_fn = nil,
	onfinished = nil,
	difficulty = 5,
	tex = "minotaur.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("minotaur",1),
	},
	--8
	{
	name = "The Stone from Below",
	victim = "",
	counter_name = GetQuestString("The Stone from Below","COUNTER"),
	description = GetQuestString("The Stone from Below","DESCRIPTION"),
	amount = 8,
	rewards = {redgem = 3, bluegem = 3,purplegem = 1},
	points = 150,
	start_fn = function(inst,amount,quest_name)
		local ListenForEventWorkable = function() end
		local current_amount = GetCurrentAmount(inst,quest_name)
		local targets = {}
		local function LookForFossil(boulder,data)
			targets[boulder.GUID] = nil
			if data and data.loot then
				if data.loot.prefab == "fossil_piece" then
					current_amount = current_amount + 1
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if current_amount >= amount then
						inst:RemoveEventCallback("working",ListenForEventWorkable)
					end
				end
			end
		end
		ListenForEventWorkable = function(inst,data)
			if data and data.target and targets[data.target.GUID] == nil then
				data.target:ListenForEvent("loot_prefab_spawned",LookForFossil)
				targets[data.target.GUID] = true
			end
		end
		inst:ListenForEvent("working",ListenForEventWorkable)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("working",ListenForEventWorkable)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "fossil_piece.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Stone from Below","HOVER",8),
	},
	--9
	{
	name = "Beyond the Charming Hamlet",
	victim = "pigman",
	counter_name = nil,
	description = GetQuestString("Beyond the Charming Hamlet","DESCRIPTION"),
	amount = 10,
	rewards = {poop = 10, meat = 10, pigskin = 10},
	points = 300,
	start_fn = nil,
	onfinished = nil,
	difficulty = 3,
	tex = "pigman.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("pigman",10),
	},
	--10
	{
	name = "Corpses of the Swampy Badlands",
	victim = "tentacle",
	counter_name = nil,
	description = GetQuestString("Corpses of the Swampy Badlands","DESCRIPTION"),
	amount = 5,
	rewards = {tentaclespots = 3, boneshard = 10, boards = 6},
	points = 350,
	start_fn = nil,
	onfinished = nil,
	difficulty = 3,
	tex = "tentacle.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("tentacle",5),
	},
	--11
	{
	name = "The Bane of Lake Nen",
	victim = "malbatross",
	counter_name = nil,
	description = GetQuestString("The Bane of Lake Nen","DESCRIPTION"),
	amount = 1,
	rewards = {malbatross_feathered_weave = 2, oceanfish_small_8_inv = 1, oceanfish_medium_8_inv = 1},
	points = 1000,
	start_fn = nil,
	onfinished = nil,
	difficulty = 4,
	tex = "malbatross.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("malbatross",1),
	},
	--12
	{
	name = "The Scorched Nightmare Amulet",
	victim = "",
	counter_name = GetQuestString("The Scorched Nightmare Amulet","COUNTER"),
	description = GetQuestString("The Scorched Nightmare Amulet","DESCRIPTION",60),
	amount = 60,
	rewards = {orangegem = 1, greengem = 1, yellowgem = 1},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		local time = GetCurrentAmount(inst,quest_name)
		local function CheckBurning(inst)
			if inst.components.temperature then
				if inst.components.temperature.current >= inst.components.temperature.overheattemp then
					local hasamulet = false
					if inst.components.inventory then
						for k,v in pairs(inst.components.inventory.equipslots) do
							if v.prefab == "purpleamulet" then
								hasamulet = true
								break
							end
						end
					end
					if hasamulet == true then
						time = time + 1
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						if time >= amount then
							inst.check_overheating_quest_component = nil
							return
						end
					else
						if time ~= 0 then
							time = 0
							inst:PushEvent("quest_update",{quest = quest_name,reset = true})
						end
					end
				else
					if time ~= 0 then
						time = 0
						inst:PushEvent("quest_update",{quest = quest_name,reset = true})
					end
				end
			end
			inst.check_overheating_quest_component = inst:DoTaskInTime(1,CheckBurning)
		end
		if inst.check_overheating_quest_component ~= nil then
        	inst.check_overheating_quest_component:Cancel()
        	inst.check_overheating_quest_component = nil
    	end
		CheckBurning(inst)
		local function OnForfeitedQuest(inst)
			if inst.check_overheating_quest_component ~= nil then
        		inst.check_overheating_quest_component:Cancel()
        		inst.check_overheating_quest_component = nil
    		end
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "light.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Scorched Nightmare Amulet","HOVER",60),
	},
	--13
	{
	name = "The Fearful Trial",
	victim = "",
	counter_name = GetQuestString("The Fearful Trial","COUNTER"),
	description = GetQuestString("The Fearful Trial","DESCRIPTION"),
	amount = 4,
	rewards = {orangestaff = 1, ruinshat = 2, armorruins = 2},
	points = 1000,
	start_fn = function(inst,amount,quest_name)
		local OnSeasonChange = function() end
		if inst.components.quest_component.quest_data[quest_name] == nil then
			inst.components.quest_component.quest_data[quest_name] = {}
		end
		local bosses = inst.components.quest_component:GetQuestData(quest_name,"bosses")
		if bosses == nil then
			bosses = {bearger = false,deerclops = false,moose = false,antlion = false}
			inst.components.quest_component:SetQuestData(quest_name, "bosses", bosses)
		end
		local function OnKilled_Quest(inst,data)
			if data and data.victim then
				for k,v in pairs(bosses) do
					if tostring(k) == data.victim.prefab and v == false then
						bosses[k] = true
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					end
				end
				inst.components.quest_component:SetQuestData(quest_name, "bosses", bosses)
				if bosses.bearger == true and bosses.deerclops == true and bosses.moose == true and bosses.antlion == true then
					inst:RemoveEventCallback("killed",OnKilled_Quest)
					inst:RemoveEventCallback("killedbyfriend",OnKilled_Quest)
					inst:StopWatchingWorldState("season",OnSeasonChange)

					inst.components.quest_component.quest_data[quest_name] = nil
				end
			end
		end
		if inst.components.quest_component.quest_data[quest_name] and inst.components.quest_component.quest_data[quest_name].bosses == nil then
			inst.components.quest_component.quest_data[quest_name].bosses = bosses
		end
		OnSeasonChange = function(inst,season)
			devprint("OnSeasonChange",inst,season)
			if season then
				local boss = inst.components.quest_component.quest_data[quest_name].bosses or {}
				local season_bosses = {autumn = "bearger",winter = "deerclops",spring = "moose",summer = "antlion"}
				for seasons,boss_monster in pairs(season_bosses) do
					if seasons == season then
						if boss[boss_monster] == true then
							boss[boss_monster] = false
							inst:PushEvent("quest_update",{quest = quest_name,amount = -1})
						end
						break
					end
				end
			end
			inst.components.quest_component.quest_data[quest_name].season = season
		end
		local old_season = inst.components.quest_component.quest_data[quest_name].season 
		if old_season then
			local curr_season = TheWorld.state.season or "autumn"
			if curr_season ~= old_season then
				local old_daycount = inst.components.quest_component.quest_data[quest_name].daycount
				if old_daycount then
					local curr_daycount = TheWorld.state.cycles
					local diff = curr_daycount - old_daycount 
					local tab = {
						{"autumn",TheWorld.state.autumnlength,},
						{"winter",TheWorld.state.winterlength,},
						{"spring",TheWorld.state.springlength,},
						{"summer",TheWorld.state.summerlength,},
					}
					local year_length = tab[1][2] + tab[2][2] + tab[3][2] + tab[4][2]
					if diff > year_length then
						inst.components.quest_component.quest_data[quest_name].bosses = bosses
						inst:PushEvent("quest_update",{quest = quest_name,set_amount = 0})
					else
						local index
						for k,v in ipairs(tab) do
							if v[1] == curr_season then
								index = k
								break
							end
						end
						if index then
							for i = 1,4 do
								local season = circular_index(tab,index+i)[1]
								OnSeasonChange(inst,season)
								if season == curr_season then
									break
								end
							end
						end
					end
				end
			end
		end
		inst.components.quest_component.quest_data[quest_name].season = TheWorld.state.season
		inst.components.quest_component.quest_data[quest_name].daycount = TheWorld.state.cycles
		inst:ListenForEvent("killed",OnKilled_Quest)
		inst:ListenForEvent("killedbyfriend", OnKilled_Quest)
		inst:WatchWorldState("season", OnSeasonChange)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled_Quest)
			inst:RemoveEventCallback("killedbyfriend",OnKilled_Quest)
			inst:StopWatchingWorldState("season",OnSeasonChange)
			inst.components.quest_component.quest_data[quest_name] = nil
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "fight.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Fearful Trial","HOVER"),
	},
	--14
	{
	name = "Across the Desert",
	victim = "antlion",
	counter_name = nil,
	description = GetQuestString("Across the Desert","DESCRIPTION"),
	amount = 1,
	rewards = {antliontrinket = 3, blueprint = 3},
	points = 750,
	start_fn = nil,
	onfinished = nil,
	difficulty = 4,
	tex = "antlion.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("antlion",1),
	},
	--15
	{
	name = "The Corrupt Darkness",
	victim = "",
	counter_name = GetQuestString("The Corrupt Darkness","COUNTER"),
	description = GetQuestString("The Corrupt Darkness","DESCRIPTION"),
	amount = 10,
	rewards = {armor_sanity = 2, nightsword = 1, nightmarefuel = 15},
	points = 300,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["get hit x times by charlie"](inst,amount,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "health.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Corrupt Darkness","HOVER",10),
	},
	--16
	{
	name = "The Legend of the Trade Road",
	victim = "",
	counter_name = GetQuestString("The Legend of the Trade Road","COUNTER"),
	description = GetQuestString("The Legend of the Trade Road","DESCRIPTION"),
	amount = 20,
	rewards = {goldnugget = 20},
	points = 100,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["trade x amount of item y with pigking"](inst,amount,nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "pigking.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Legend of the Trade Road","HOVER",20),
	},
	--17
	{
	name = "The Vampire Dungeon",
	victim = "bat",
	counter_name = nil,
	description = GetQuestString("The Vampire Dungeon","DESCRIPTION"),
	amount = 30,
	rewards = {meat_dried = 5, rocks = 15, flint = 15},
	points = 150,
	start_fn = nil,
	onfinished = nil,
	difficulty = 2,
	tex = "bat.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("bat",30),
	},
	--18
	{
	name = "Within the Stream",
	victim = "",
	counter_name = GetQuestString("Within the Stream","COUNTER"),
	description = GetQuestString("Within the Stream","DESCRIPTION",10),
	amount = 10,
	rewards = {oceanfish_small_9_inv = 2, oceanfish_small_8_inv = 1, oceanfishingbobber_crow = 1},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["catch x amount of y fish"](inst,amount,nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "fishing.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Within the Stream","HOVER",10),
	},
	--19
	{
	name = "Mage of the Manor Baldur",
	victim = "",
	counter_name = GetQuestString("Mage of the Manor Baldur","COUNTER"),
	description = GetQuestString("Mage of the Manor Baldur","DESCRIPTION"),
	amount = 1,
	rewards = {purplegem = 5, rope = 5, boards = 5},
	points = 400,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["teleport x times y away"](inst,amount,"deerclops",quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "deerclops.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Mage of the Manor Baldur","HOVER"),
	},
	--20
	{
	name = "The Rage of Ioun",
	victim = "spider",
	counter_name = nil,
	description = GetQuestString("The Rage of Ioun","DESCRIPTION"),
	amount = 25,
	rewards = {goldnugget = 10, boneshard = 6, log = 12},
	points = 350,
	start_fn = nil,
	onfinished = nil,
	difficulty = 2,
	tex = "spider.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("spider",25),
	},
	--21
	{
	name = "The Sack For the Unlucky",
	victim = "krampus",
	counter_name = nil,
	description = GetQuestString("The Sack For the Unlucky","DESCRIPTION"),
	amount = 33,
	rewards = {krampus_sack = 1},
	points = 1000,
	start_fn = nil,
	onfinished = nil,
	difficulty = 4,
	tex = "krampus.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("krampus",33),
	},
	--22
	{
	name = "Below the Abandoned Land",
	victim = "",
	counter_name = GetQuestString("Below the Abandoned Land","COUNTER"),
	description = GetQuestString("Below the Abandoned Land","DESCRIPTION"),
	amount = 1,
	rewards = {goldnugget = 40},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		local rocks = {"stalagmite_full","stalagmite_med","stalagmite_low","stalagmite_tall_full","stalagmite_tall_med","stalagmite_tall_low"}
		local function Workable(inst,data)
			if data and data.target then
				for k,v in ipairs(rocks) do
					if data.target.prefab == v then
						if math.random() < 0.06 then
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							inst:RemoveEventCallback("working",Workable)
							local pos = data.target:GetPosition() or inst:GetPosition() or Vector3(0,0,0)
    						SpawnPrefab("explode_firecrackers").Transform:SetPosition(pos.x, pos.y, pos.z)
						end
						break
					end
				end
			end
		end
		inst:ListenForEvent("working",Workable)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("working",Workable)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "tools.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Below the Abandoned Land","HOVER"),
	},
	--23
	{
	name = "A Cute Companion",
	victim = "",
	counter_name = GetQuestString("A Cute Companion","COUNTER"),
	description = GetQuestString("A Cute Companion","DESCRIPTION"),
	amount = 1,
	rewards = {onemanband = 1,wormlight = 3},
	points = 200,
	start_fn = function(inst,amount,quest_name)
		local function OnGetHutch(inst,data)
			if data and data.item and data.item.prefab == "hutch_fishbowl" then
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				inst:RemoveEventCallback("working",OnGetHutch)
			end
		end
		inst:ListenForEvent("itemget",OnGetHutch)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("working",OnGetHutch)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "hutch_fishbowl.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("A Cute Companion","HOVER"),
	},
	--24
	{
	name = "The Allies Within the Land",
	victim = "",
	counter_name = GetQuestString("The Allies Within the Land","COUNTER"),
	description = GetQuestString("The Allies Within the Land","DESCRIPTION",10),
	amount = 10,
	rewards = {onemanband = 3,wormlight = 10},
	points = 350,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["acquire x followers that are y"](inst,amount,nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "critters.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Allies Within the Land","HOVER",10),
	},
	--25
	{
	name = "Orcus's Living Dead",
	victim = "mutatedhound",
	counter_name = nil,
	description = GetQuestString("Orcus's Living Dead","DESCRIPTION"),
	amount = 10,
	rewards = {moonrocknugget = 10,moonglass = 10},
	points = 500,
	start_fn = nil,
	onfinished = nil,
	difficulty = 3,
	tex = "mutatedhound.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("mutatedhound",10),
	},
	--26
	{
	name = "The Damned Legacy",
	victim = "",
	counter_name = GetQuestString("The Damned Legacy","COUNTER"),
	description = GetQuestString("The Damned Legacy","DESCRIPTION",1),
	amount = 1,
	rewards = {moonrocknugget = 40,moonglass = 40},
	points = 1500,
	start_fn = function(inst,amount,quest_name)
		local defended = 0
		local function CheckIfMoonStaff(moonbase,data)
			if data and data.loot and data.loot.prefab == "opalstaff" then
				defended = defended + 1
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1,friendly_goal = true})
				if defended >= amount then
					inst:RemoveEventCallback("picksomething",CheckIfMoonStaff)
				end
			end
		end
		inst:ListenForEvent("picksomething",CheckIfMoonStaff)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("picksomething",CheckIfMoonStaff)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "moonbase.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Damned Legacy","HOVER",1),
	},
	--27
	{
	name = "The Abandoned Chester",
	victim = "",
	counter_name = GetQuestString("The Abandoned Chester","COUNTER"),
	description = GetQuestString("The Abandoned Chester","DESCRIPTION"),
	amount = 1,
	rewards = {nightmarefuel = 80,purpleamulet = 3},
	points = 1000,
	start_fn = function(inst,amount,quest_name)
		local time = math.random(90,180)
		local attacksize = {6,3}
		local time_inbetween_spawn = 15
		local diff = 4
		local function StartWaves(player)
			if TheWorld and TheWorld.components.attackwaves then
				TheWorld.components.attackwaves:StartAttack(inst,attacksize,time_inbetween_spawn,diff,"chester")
			end
		end
		inst.attack_wave_task_chester = inst:DoTaskInTime(time,StartWaves)
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTimerToClient"),inst.userid,inst,time,"chester")
		local OnWin = function() end
		local function OnLose(inst,victim)
			devprint("OnLose",inst,victim)
			if victim == "chester" and inst.components.quest_component then
				inst.components.quest_component:RemoveQuest(quest_name)
				inst:RemoveEventCallback("succesfully_defended",OnWin)
				inst:RemoveEventCallback("victim_died",OnLose)
				SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"chester")
			end
		end
		OnWin = function(inst)
			inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			inst:RemoveEventCallback("succesfully_defended",OnWin)
			inst:RemoveEventCallback("victim_died",OnLose)
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"chester")
		end

		inst:ListenForEvent("succesfully_defended",OnWin)
		inst:ListenForEvent("victim_died",OnLose)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("succesfully_defended",OnWin)
			inst:RemoveEventCallback("victim_died",OnLose)
			if inst.attack_wave_task_chester ~= nil then
				inst.attack_wave_task_chester:Cancel()
				inst.attack_wave_task_chester = nil
			end
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"chester")
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "fight.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Abandoned Chester","HOVER"),
	},
	--28
	{
	name = "The Sharks Demise",
	victim = "shark",
	counter_name = nil,
	description = GetQuestString("The Sharks Demise","DESCRIPTION"),
	amount = 2,
	rewards = {fishmeat = 20,blowdart_yellow = 10},
	points = 1000,
	start_fn = nil,
	onfinished = nil,
	difficulty = 4,
	tex = "shark.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("shark",2),
	},
	--29
	{
	name = "The Houndstooth Curse",
	victim = "warg",
	counter_name = nil,
	description = GetQuestString("The Houndstooth Curse","DESCRIPTION"),
	amount = 2,
	rewards = {premiumwateringcan = 1,gears = 5},
	points = 500,
	start_fn = nil,
	onfinished = nil,
	difficulty = 3,
	tex = "warg.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("warg",2),
	},
	--30
	{
	name = "The Possessed Crows",
	victim = "crow",
	counter_name = nil,
	description = GetQuestString("The Possessed Crows","DESCRIPTION"),
	amount = 15,
	rewards = {boards = 5,nitre = 10},
	points = 100,
	start_fn = nil,
	onfinished = nil,
	difficulty = 1,
	tex = "crow.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("crow",15),
	},
	--31
	{
	name = "Colors of the Rainbow",
	victim = "",
	counter_name = GetQuestString("Colors of the Rainbow","COUNTER"),
	description = GetQuestString("Colors of the Rainbow","DESCRIPTION"),
	amount = 6,
	rewards = {[":func:nightvision;1"] = 16,goldnugget = 10},
	points = 1000,
	start_fn = function(inst,amount,quest_name)
		local values = inst.components.quest_component:GetQuestData(quest_name,"amount")
		local gems = values or {orangegem = false, yellowgem = false, greengem = false, redgem = false, bluegem = false, purplegem = false,}
		local amount = 0
		local CheckGems = function() end
		local function CheckForGems(inst,item,added)
			for k,v in pairs(gems) do
				if k == item.prefab then
					if added then
						if v == false then
							gems[k] = true
							amount = amount + 1
							inst.components.quest_component:SetQuestData(quest_name,"amount",gems)
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							if amount >= 6 then
								inst:RemoveEventCallback("itemget",CheckGems)
								inst:RemoveEventCallback("itemlose",CheckGems)
							end
						end
						return
					else
						if v == true then
							if inst.components.inventory:Has(k,1) == false then
								gems[k] = false
								inst.components.quest_component:SetQuestData(quest_name,"amount",gems)
								amount = amount - 1
								inst:PushEvent("quest_update",{quest = quest_name,amount = -1})
							end
						end
						return
					end
				end
			end
		end
		CheckGems = function(inst,data)
			if data then 
				if data.item then
					CheckForGems(inst,data.item,true)
				elseif data.prev_item then
					CheckForGems(inst,data.prev_item,false)
				end
			end
		end
		inst:ListenForEvent("itemget",CheckGems)
		inst:ListenForEvent("itemlose",CheckGems)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("itemget",CheckGems)
			inst:RemoveEventCallback("itemlose",CheckGems)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "ancient.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Colors of the Rainbow","HOVER"),
	},
	--32
	{
	name = "Bright Worshipnight",
	victim = "",
	counter_name = GetQuestString("Bright Worshipnight","COUNTER"),
	description = GetQuestString("Bright Worshipnight","DESCRIPTION"),
	amount = 1,
	rewards = {glommer_lightflower = 1},
	points = 300,
	start_fn = function(inst,amount,quest_name)
		local glommerflower = false
		local fireflies = 0
		local OnFullmoon
		local function OnPastFullmoon(chest,isfullmoon)
			if not isfullmoon then
				if chest.components.container then
					chest.components.container:DropEverything()
				end
				chest:Remove()
			end
		end
		local function CheckForItems(chest,item,added)
			if added then
				if item.prefab == "glommerflower" then
					glommerflower = true
				elseif item.prefab == "fireflies" then
					local stacksize = item.components.stackable and item.components.stackable:StackSize() or 1
					fireflies = fireflies + stacksize
				end
			else
				if item.prefab == "glommerflower" then
					glommerflower = false
				elseif item.prefab == "fireflies" then
					local stacksize = item.components.stackable and item.components.stackable:StackSize() or 1
					fireflies = fireflies - stacksize
				end
			end
			if glommerflower == true and fireflies >= 10 then
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				if chest.components.container then
					chest.components.container:Close()
					chest.components.container:DropEverythingWithTag("glommerflower")
					chest:DoTaskInTime(0.5,inst.Remove)
					inst:StopWatchingWorldState("isfullmoon", OnFullmoon)
				end
			end
		end
		local function CheckChest(chest,data)
			if data then 
				if data.item then
					CheckForItems(chest,data.item,true)
				elseif data.prev_item then
					CheckForItems(chest,data.prev_item,false)
				end
			end
		end
		OnFullmoon = function(inst,isfullmoon)
			if TheWorld:HasTag("cave") or not isfullmoon then
				return 
			end
			local statue = TheSim:FindFirstEntityWithTag("statueglommer")
			local x, y, z = statue.Transform:GetWorldPosition()
    		local offset = FindWalkableOffset(Vector3(x, y, z), math.random() * 2 * PI, math.random(20,35), 20, true)
    		local chest = SpawnPrefab("treasurechest")
    		chest.Transform:SetPosition(x+offset.x,y+offset.y,z+offset.z)
    		chest:ListenForEvent("itemget",CheckChest)
    		chest:ListenForEvent("itemlose",CheckChest)
    		chest:WatchWorldState("isfullmoon", OnPastFullmoon)
    		chest.persists = false
		end
		inst:WatchWorldState("isfullmoon", OnFullmoon)
		OnFullmoon(TheWorld,TheWorld.state.isfullmoon)
		local function OnForfeitedQuest(inst)
			inst:StopWatchingWorldState("isfullmoon", OnFullmoon)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "glommer_lightflower.tex",
	atlas = "images/glommer_lightflower.xml",
	hovertext = GetQuestString("Bright Worshipnight","HOVER"),
	},
	--33
	{
	name = "Mirror of Merms",
	victim = "merm",
	counter_name = GetQuestString("Mirror of Merms","COUNTER"),
	description = GetQuestString("Mirror of Merms","DESCRIPTION",5),
	amount = 5,
	rewards = {ruins_bat = 1,rocks = 15,froglegs = 5},
	points = 750,
	start_fn = function(inst,amount,quest_name)
		local function OnHitMerm(inst,data)
			if data and data.target and data.target.prefab == "merm" then
				if inst.net_cameratrigger ~= nil then
					if inst.camera_task ~= nil then
						inst.camera_task:Cancel()
						inst.camera_task = nil
					end
					inst.net_cameratrigger:set(true)
					inst.camera_task = inst:DoTaskInTime(15,function()
						inst.net_cameratrigger:set(false)
					end)
				end
			end
		end
		local function OnFinished(inst,name)
			if name == quest_name then
				inst:RemoveEventCallback("onhitother",OnHitMerm)
				inst:RemoveEventCallback("finished_quest",OnFinished)
				inst:RemoveEventCallback("forfeited_quest",OnFinished)
			end
		end
		inst:ListenForEvent("onhitother",OnHitMerm)
		inst:ListenForEvent("finished_quest",OnFinished)
		inst:ListenForEvent("forfeited_quest",OnFinished)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "merm.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("merm",5),
	},
	--34
	{
	name = "Giving back to Nature",
	victim = "",
	counter_name = GetQuestString("Giving back to Nature","COUNTER"),
	description = GetQuestString("Giving back to Nature","DESCRIPTION"),
	amount = 5,
	rewards = {butter = 1,carrot = 1,onion = 1,potato = 1},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function CheckIfFirefly(inst,data)
			if data and data.item and data.item.prefab == "fireflies" then
				local amount_fireflies = data.item.components.stackable and data.item.components.stackable:StackSize() or 1
				inst:PushEvent("quest_update",{quest = quest_name,amount = amount_fireflies})
				current_amount = current_amount + 1
				if current_amount >= amount then
					inst:RemoveEventCallback("dropitem",CheckIfFirefly)
				end
			end
		end
    	inst:ListenForEvent("dropitem",CheckIfFirefly)
    	local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("dropitem",CheckIfFirefly)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "fireflies.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Giving back to Nature","HOVER",5),
	["reward_onion_tex"] = "quagmire_onion.tex", 
	["reward_onion_atlas"] = "images/inventoryimages2.xml",
	},
	--35
	{
	name = "A Crappy Day",
	victim = "",
	counter_name = GetQuestString("A Crappy Day","COUNTER"),
	description = GetQuestString("A Crappy Day","DESCRIPTION"),
	amount = 10,
	rewards = {fertilizer = 1,livinglog = 3,[":func:sleeping;0.4"] = 16,},
	points = 300,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function CheckIfPoop(inst,data)
			if data then
				if data.attacker ~= nil and data.damage == 0 then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current_amount = current_amount + 1
					if current_amount >= amount then
						inst:RemoveEventCallback("attacked",CheckIfPoop)
					end
				end
			end
		end
    	inst:ListenForEvent("attacked",CheckIfPoop)
    	local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("attacked",CheckIfPoop)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "poop.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("A Crappy Day","HOVER",10),
	},
	--36
	{
	name = "Revenge of the crapped victim",
	victim = "",
	counter_name = GetQuestString("Revenge of the crapped victim","COUNTER"),
	description = GetQuestString("Revenge of the crapped victim","DESCRIPTION"),
	amount = 1,
	rewards = {armor_sanity = 1,nightsword = 1,[":func:sanityaura;10"] = 16,},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		local CheckIfPhlegm = function() end
		local function GetStolenByMonkey(phlegm,data)
			if data and data.owner then
				if data.owner.prefab == "monkey" then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					phlegm:RemoveEventCallback("onpickup",GetStolenByMonkey)
					inst:RemoveEventCallback("dropitem",CheckIfPhlegm)
				end
			end
		end
		CheckIfPhlegm = function(inst,data)
			if data and data.item and data.item.prefab == "phlegm" then
				data.item:ListenForEvent("onpickup",GetStolenByMonkey)
			end
		end
    	inst:ListenForEvent("dropitem",CheckIfPhlegm)
    	local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("dropitem",CheckIfPhlegm)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "phlegm.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("Revenge of the crapped victim","HOVER"),
	},
	--37
	{
	name = "Luminous globules",
	victim = "",
	counter_name = GetQuestString("Luminous globules","COUNTER"),
	description = GetQuestString("Luminous globules","DESCRIPTION"),
	amount = 25,
	rewards = {[":func:health;25"] = 24,twigs = 10,cutgrass = 10},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function OnHealthDelta(inst,data)
			if data then
				if data.amount > 0 then
					if data.cause == "lightbulb" then
						inst:PushEvent("quest_update",{quest = quest_name,amount = data.amount})
						if current_amount >= amount then
							inst:RemoveEventCallback("healthdelta",OnHealthDelta)
						end
					end
				end
			end
		end
		inst:ListenForEvent("healthdelta",OnHealthDelta)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("healthdelta",OnHealthDelta)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "lightbulb.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Luminous globules","HOVER",25),
	},
	--38
	{
	name = "Beary Hunger",
	victim = "perd",
	counter_name = nil,
	description = GetQuestString("Beary Hunger","DESCRIPTION"),
	amount = 2,
	rewards = {berries = 10,dug_berrybush = 3},
	points = 125,
	start_fn = nil,
	onfinished = nil,
	difficulty = 1,
	tex = "perd.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("perd",2),
	},
	--39
	{
	name = "Wetlands",
	victim = "",
	counter_name = GetQuestString("Wetlands","COUNTER"),
	description = GetQuestString("Wetlands","DESCRIPTION",60),
	amount = 60,
	rewards = {raincoat = 1,umbrella = 1},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local time = GetCurrentAmount(inst,quest_name)
		local function CheckWetness(inst)
			if inst.components.moisture then
				if inst.components.moisture.moisture >= 50 then
					time = time + 1
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if time >= amount and inst.check_wetness_quest_component ~= nil then
						inst.check_wetness_quest_component:Cancel()
						inst.check_wetness_quest_component = nil
					end
				end
			end
			inst.check_wetness_quest_component = inst:DoTaskInTime(1,CheckWetness)
		end
		if inst.check_wetness_quest_component ~= nil then
        	inst.check_wetness_quest_component:Cancel()
        	inst.check_wetness_quest_component = nil
    	end
		CheckWetness(inst)
		local function OnForfeitedQuest(inst)
			if inst.check_wetness_quest_component ~= nil then
        		inst.check_wetness_quest_component:Cancel()
        		inst.check_wetness_quest_component = nil
    		end
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "umbrella.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("Wetlands","HOVER"),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale then
			local scale = math.max(math.min(5,tonumber(data.scale)),1)
			local vars = {{60,125},{120,250},{180,500},{300,750},{480,1250}}
			if scale > 1 then
				quest.amount = vars[scale][1]
				quest.points = vars[scale][2]
				local hunger_scale = {[2] = 0.9,[3] = 0.8,[4] = 0.7,[5] = 0.6}
				quest.rewards = {raincoat = 1,umbrella = 1,[":func:hungerrate;"..(hunger_scale[scale or 1] or 0.9)] = 16,}
				devprint(quest.hovertext,quest.description)
				quest.scale = {scale}
				quest.difficulty = scale
			end
			local minutes = vars[scale][1]/60 or 1
			quest.hovertext = GetQuestString(quest.name,"HOVER",minutes)
			quest.description = GetQuestString(quest.name,"DESCRIPTION",minutes)
		end
		return quest
	end,
	},
	--40
	{
	name = "Off to sea",
	victim = "",
	counter_name = GetQuestString("Off to sea","COUNTER"),
	description = GetQuestString("Off to sea","DESCRIPTION"),
	amount = 5,
	rewards = {boatpatch = 5,mastupgrade_lightningrod_item = 1},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		local values = inst.components.quest_component:GetQuestData(quest_name,"amount")
		local items_had = values or {boat = false,oar = false,mast = false,steeringwheel = false,anchor = false}
		local items_needed = {boat_item = "boat",oar = "oar",oar_driftwood = "oar",mast_item = "mast",mast_malbatross_item = "mast",steeringwheel_item = "steeringwheel",anchor_item = "anchor"}
		local CheckSea = function() end
		local function CheckSeaworthy(inst,item,remove)
			devprint("CheckSeaworthy",inst,item,remove)
			if remove then
				for k,v in pairs(items_needed) do
					if k == item.prefab and items_had[v] == true then
						items_had[v] = false
						inst.components.quest_component:SetQuestData(quest_name,"amount",items_had)
						inst:PushEvent("quest_update",{quest = quest_name,amount = -1})
					end
				end
			else
				for k,v in pairs(items_needed) do
					if k == item.prefab and items_had[v] == false then
						items_had[v] = true
						inst.components.quest_component:SetQuestData(quest_name,"amount",items_had)
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						if GetCurrentAmount(inst,quest_name) >= amount then
							inst:RemoveEventCallback("itemget",CheckSea)
							inst:RemoveEventCallback("itemlose",CheckSea)
						end
					end
				end
			end
		end
		CheckSea = function(inst,data)
			if data then
				if data.item ~= nil then
					CheckSeaworthy(inst,data.item)
				elseif data.prev_item ~= nil then
					CheckSeaworthy(inst,data.prev_item,true)
				end
			end
		end
		inst:ListenForEvent("itemget",CheckSea)
		inst:ListenForEvent("itemlose",CheckSea)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("itemget",CheckSea)
			inst:RemoveEventCallback("itemlose",CheckSea)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "boat_item.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Off to sea","HOVER"),
	},
	--41
	{
	name = "Hidden Treasures",
	victim = "",
	counter_name = GetQuestString("Hidden Treasures","COUNTER"),
	description = GetQuestString("Hidden Treasures","DESCRIPTION",3),
	amount = 3,
	rewards = {redgem = 3,bluegem = 3,purplegem = 3},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function OnRaised(inst)
			inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current_amount = current_amount + 1
			if current_amount >= amount then
				inst:RemoveEventCallback("raised_salvageable",OnRaised)
			end
		end
		inst:ListenForEvent("raised_salvageable",OnRaised)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("raised_salvageable",OnRaised)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "sunkenchest.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("Hidden Treasures","HOVER",3),
	},
	--42
	{
	name = "Off to donate blood",
	victim = "",
	counter_name = GetQuestString("Off to donate blood","COUNTER"),
	description = GetQuestString("Off to donate blood","DESCRIPTION"),
	amount = 20,
	rewards = {mosquitosack = 3,[":func:health;50"] = 8},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function OnAttacked(inst,data)
			if data then
				if data.attacker and data.attacker.prefab == "mosquito" then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current_amount = current_amount + 1
					if current_amount >= amount then
						inst:RemoveEventCallback("attacked",OnAttacked)
					end
				end
			end
		end
		inst:ListenForEvent("attacked",OnAttacked)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("attacked",OnAttacked)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "mosquito.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Off to donate blood","HOVER",20),
	},
	--43
	{
	name = "The Lonely Woven Shadow",
	victim = "",
	counter_name = GetQuestString("The Lonely Woven Shadow","COUNTER"),
	description = GetQuestString("The Lonely Woven Shadow","DESCRIPTION"),
	amount = 1,
	rewards = {nightmarefuel = 10,boards = 3},
	points = 150,
	start_fn = function(inst,amount,quest_name)
		local time = math.random(90,180)
		local attacksize = {5,1}
		local time_inbetween_spawn = 15
		local diff = 1
		local function StartWaves(player)
			if TheWorld and TheWorld.components.attackwaves then
				TheWorld.components.attackwaves:StartAttack(inst,attacksize,time_inbetween_spawn,diff,math.random() < 0.5 and "stalker_minion1" or "stalker_minion2")
			end
		end
		inst.attack_wave_task_woven_shadow = inst:DoTaskInTime(time,StartWaves)
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTimerToClient"),inst.userid,inst,time,"stalker_minion1")
		local OnWin = function() end
		local function OnLose(inst,victim)
			if victim == "stalker_minion1" and inst.components.quest_component then
				inst.components.quest_component:RemoveQuest(quest_name)
				inst:RemoveEventCallback("succesfully_defended",OnWin)
				inst:RemoveEventCallback("victim_died",OnLose)
				SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"stalker_minion1")
			end
		end
		OnWin = function(inst)
			inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			inst:RemoveEventCallback("succesfully_defended",OnWin)
			inst:RemoveEventCallback("victim_died",OnLose)
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"stalker_minion1")
		end

		inst:ListenForEvent("succesfully_defended",OnWin)
		inst:ListenForEvent("victim_died",OnLose)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("succesfully_defended",OnWin)
			inst:RemoveEventCallback("victim_died",OnLose)
			if inst.attack_wave_task_woven_shadow ~= nil then
				inst.attack_wave_task_woven_shadow:Cancel()
				inst.attack_wave_task_woven_shadow = nil
			end
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),inst.userid,inst,"stalker_minion1")
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "fight.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Lonely Woven Shadow","HOVER"),
	},
	--44
	{
	name = "The Eye of Cthulhu",
	victim = "eyeofterror",
	counter_name = nil,
	description = GetQuestString("The Eye of Cthulhu","DESCRIPTION"),
	amount = 1,
	rewards = {boards = 10,nitre = 10},
	points = 650,
	start_fn = nil,
	onfinished = nil,
	difficulty = 4,
	tex = "eyeofterror.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("eyeofterror",1),
	},
	--45
	{
	name = "The Biggest Veggy",
	victim = "",
	counter_name = GetQuestString("The Biggest Veggy","COUNTER"),
	description = GetQuestString("The Biggest Veggy","DESCRIPTION"),
	amount = 1,
	rewards = {mandrake = 3, plantmeat = 6, beeswax = 3},
	points = 650,
	start_fn = function(inst,amount,quest_name)
		local data = inst.components.quest_component.quests[quest_name] and inst.components.quest_component.quests[quest_name].custom_vars
		local veggy = data and data.victim or "eggplant_oversized"
		local size = data and data.size or 450
		local function OnHarvestedOversized(inst,veg)
			if veg then
				if veg.prefab == veggy then
					if veg.components.weighable then
						local weight = veg.components.weighable:GetWeight()
						if weight and weight >= size then
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							inst:RemoveEventCallback("harvested_veg",OnHarvestedOversized)
						end
					end
				end
			end
		end
		inst:ListenForEvent("harvested_veg",OnHarvestedOversized)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("harvested_veg",OnHarvestedOversized)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "eggplant.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Biggest Veggy","HOVER"),
	custom_vars_fn = function(inst)
		devprint("custom_vars")
		local veggies = {"carrot_oversized","dragonfruit_oversized","corn_oversized","potato_oversized","tomato_oversized","asparagus_oversized","eggplant_oversized","pumpkin_oversized","watermelon_oversized","durian_oversized","garlic_oversized","onion_oversized","pepper_oversized","pomegranate_oversized",}
		local veg = veggies[math.random(#veggies)]
		local veg_name = string.sub(veg,1,-11)
		local weight = farm_plants_defs.PLANT_DEFS[veg_name]
		local size = weight and math.floor((weight.weight_data[2]-weight.weight_data[1]) * ((math.random() * 0.1) + 0.7) + weight.weight_data[1]) or 450 	
		--make it a number from 70% to 80% between min/max
		return {victim = veg,size = size}
	end,
	variable_fn = function(inst,quest,data)
		if data then
			local veggy = data.victim and STRINGS.NAMES[string.upper(data.victim)] or data.victim or "nil"
			local size = data.size or 450
			quest.counter_name = GetQuestString("The Biggest Veggy","COUNTER",veggy)
			quest.description = GetQuestString("The Biggest Veggy","DESCRIPTION",veggy,veggy,size)
			quest.hovertext = GetQuestString("The Biggest Veggy","HOVER",veggy,size)
			quest.tex = data.victim and data.victim..".tex" or quest.tex
			local inv_atlas = {tomato_oversized = true,pumpkin_oversized = true,watermelon_oversized = true,}
			if data.victim and inv_atlas[data.victim] then
				quest.atlas = "images/inventoryimages2.xml"
			end
			quest.scale = {veggy} --used to add strings to the title
		end
		return quest
	end,
	},
	--46
	{
	name = "A Sailor's Life",
	victim = "",
	counter_name = GetQuestString("A Sailor's Life","COUNTER"),
	description = GetQuestString("A Sailor's Life","DESCRIPTION"),
	amount = 120,
	rewards = {fig = 10,treegrowthsolution = 2},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["stay x amount of time on y boat"](inst,amount,nil,true,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "seafaring.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("A Sailor's Life","HOVER",120),
	},
	--47
	{
	name = "Survival: Famine",
	victim = "",
	counter_name = GetQuestString("Survival: Famine","COUNTER"),
	description = GetQuestString("Survival: Famine","DESCRIPTION"),
	amount = 50,
	rewards = {bonestew = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"hunger",quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		devprint("onfinished hunger",inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		devprint(old_scale,scale)
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "hunger.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Survival: Famine","HOVER",50),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		devprint("custom_vars scaled quests")
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale and tonumber(data.scale) > 1 then
			local scale = math.max(math.min(5,tonumber(data.scale)),2)
			local vars = {{50,125},{100,250},{200,500},{400,750},{750,1250}}
			quest.amount = vars[scale][1]
			quest.points = vars[scale][2]
			local hunger_scale = {[2] = 10,[3] = 25,[4] = 50,[5] = 100}
			quest.rewards = {bonestew = 3 * scale,[":func:hunger;"..(hunger_scale[scale or 1] or 10)] = 16,}
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.scale = {scale}
			quest.difficulty = scale
		end
		return quest
	end,
	},
	--48
	{
	name = "Survival: Heart attack",
	victim = "",
	counter_name = GetQuestString("Survival: Heart attack","COUNTER"),
	description = GetQuestString("Survival: Heart attack","DESCRIPTION"),
	amount = 50,
	rewards = {icecream = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		devprint("Survival: Heart attack start fn",inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"terrorbeak",quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "terrorbeak.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Survival: Heart attack","HOVER",50),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale and tonumber(data.scale) > 1 then
			local scale = math.max(math.min(5,tonumber(data.scale)),2)
			local vars = {{50,125},{100,250},{200,500},{400,750},{750,1250}}
			quest.amount = vars[scale][1]
			quest.points = vars[scale][2]
			local hunger_scale = {[2] = 10,[3] = 25,[4] = 50,[5] = 100}
			quest.rewards = {icecream = 3 * scale,[":func:sanity;"..(hunger_scale[scale or 1] or 10)] = 16,}
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.scale = {scale}
			quest.difficulty = scale
		end
		return quest
	end,
	},
	--49
	{
	name = "Survival: Frost Shock",
	victim = "",
	counter_name = GetQuestString("Survival: Frost Shock","COUNTER"),
	description = GetQuestString("Survival: Frost Shock","DESCRIPTION"),
	amount = 50,
	rewards = {dragonchilisalad = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"cold",quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "winterinsulation.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Survival: Frost Shock","HOVER",50),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale and tonumber(data.scale) > 1 then
			local scale = math.max(math.min(5,tonumber(data.scale)),2)
			local vars = {{50,125},{100,250},{200,500},{400,750},{750,1250}}
			quest.amount = vars[scale][1]
			quest.points = vars[scale][2]
			local hunger_scale = {[2] = 40,[3] = 80,[4] = 120,[5] = 160}
			quest.rewards = {dragonchilisalad = 3 * scale,[":func:winterinsulation;"..(hunger_scale[scale or 1] or 10)] = 16,}
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.scale = {scale}
			quest.difficulty = scale
		end
		return quest
	end,
	},
	--50
	{
	name = "Survival: Heat exhaustion",
	victim = "",
	counter_name = GetQuestString("Survival: Heat exhaustion","COUNTER"),
	description = GetQuestString("Survival: Heat exhaustion","DESCRIPTION"),
	amount = 50,
	rewards = {gazpacho = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"hot",quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "summerinsulation.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Survival: Heat exhaustion","HOVER",50),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale and tonumber(data.scale) > 1 then
			local scale = math.max(math.min(5,tonumber(data.scale)),2)
			local vars = {{50,125},{100,250},{200,500},{400,750},{750,1250}}
			quest.amount = vars[scale][1]
			quest.points = vars[scale][2]
			local hunger_scale = {[2] = 40,[3] = 80,[4] = 120,[5] = 160}
			quest.rewards = {gazpacho = 3 * scale,[":func:summerinsulation;"..(hunger_scale[scale or 1] or 10)] = 16,}
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.scale = {scale}
			quest.difficulty = scale
		end
		return quest
	end,
	},
	--51
	{
	name = "Survival: Life-threatening",
	victim = "",
	counter_name = GetQuestString("Survival: Life-threatening","COUNTER"),
	description = GetQuestString("Survival: Life-threatening","DESCRIPTION"),
	amount = 1,
	rewards = {waffles = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local custom_amount = inst.components.quest_component.quests[quest_name] and inst.components.quest_component.quests[quest_name].custom_amount or 10
		local function OnHealthDelta(inst,data)
			if inst.components.health.currenthealth < custom_amount and not inst.components.health:IsDead() then
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				inst:RemoveEventCallback("healthdelta",OnHealthDelta)
			end
		end
		inst:ListenForEvent("healthdelta",OnHealthDelta)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("healthdelta",OnHealthDelta)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "health.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Survival: Life-threatening","HOVER",10),
	scale = {1},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale and tonumber(data.scale) > 1 then
			local scale = math.max(math.min(5,tonumber(data.scale)),2)
			local vars = {{10,125},{5,250},{3,500},{2,750},{1,1250}}
			quest.custom_amount = vars[scale][1]
			quest.points = vars[scale][2]
			local hunger_scale = {[2] = 10,[3] = 25,[4] = 50,[5] = 100}
			quest.rewards = {waffles = 3 * scale,[":func:health;"..(hunger_scale[scale or 1] or 10)] = 16,}
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.scale = {scale}
			quest.difficulty = scale
		end
		return quest
	end,
	},
	--52
	{
	name = "The True Enemy",
	victim = "glommer",
	counter_name = nil,
	description = GetQuestString("The True Enemy","DESCRIPTION"),
	amount = 1,
	rewards = {moonrocknugget = 10,moonglass = 10,},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TheWorld.components.quest_loadpostpass.quest_lines[quest_name] = true
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function()
			inst.components.quest_component:AddQuest("Wrong Offering")
		end)
	end,
	difficulty = 1,
	tex = "glommer.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("glommer",1),
	["reward_Next Night_tex"] = "celestial.tex",
	["reward_Next Night_atlas"] = "images/victims.xml",
	quest_line = true,
	},
	--53
	{
	name = "Treebeard's end",
	victim = "",
	counter_name = GetQuestString("Treebeard's end","COUNTER"),
	description = GetQuestString("Treebeard's end","DESCRIPTION"),
	amount = 1,
	rewards = {multitool_axe_pickaxe = 1},
	points = 275,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnKilled(inst,data)
			if data and data.victim then
				if data.victim.prefab == "leif" then
					local hand = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if hand and (hand.prefab == "axe" or hand.prefab == "goldenaxe" or hand.prefab == "moonglassaxe" or hand.prefab == "multitool_axe_pickaxe") then
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						if current >= amount then
							inst:RemoveEventCallback("killed",OnKilled)
						end
					end
				end
			end
		end
		inst:ListenForEvent("killed",OnKilled)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "leif.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Treebeard's end","HOVER"),
	},
	--54
	{
	name = "Feeding Time",
	victim = "",
	counter_name = GetQuestString("Feeding Time","COUNTER"),
	description = GetQuestString("Feeding Time","DESCRIPTION"),
	amount = 1,
	rewards = {barnaclinguine = 3},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local function OnFeedPlayer(inst,data)
			if data and data.was_starving then 
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				inst:RemoveEventCallback("onfeedplayer",OnFeedPlayer)
			end
		end
		inst:ListenForEvent("onfeedplayer",OnFeedPlayer)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onfeedplayer",OnFeedPlayer)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "hunger.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Feeding Time","HOVER"),
	},
	--55
	{
	name = "Catch the stick",
	victim = "",
	counter_name = GetQuestString("Catch the stick","COUNTER"),
	description = GetQuestString("Catch the stick","DESCRIPTION"),
	amount = 3,
	rewards = {panflute = 1},
	points = 225,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function OnDamageDone(inst,data)
			if data then
				if data.damageresolved > 0 then
					if data.weapon and data.weapon.prefab == "boomerang" then
						if data.target and (data.target.prefab == "hound" or data.target.prefab == "icehound" or data.target.prefab == "firehound") then
							current_amount = current_amount + 1
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							if current_amount >= amount then
								inst:RemoveEventCallback("onhitother",OnDamageDone)
							end
						end
					end
				end
			end
		end
		inst:ListenForEvent("onhitother",OnDamageDone)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onhitother",OnDamageDone)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "boomerang.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Catch the stick","HOVER",3),
	},
	--56
	{
	name = "Front Pigs",
	victim = "",
	counter_name = GetQuestString("Front Pigs","COUNTER"),
	description = GetQuestString("Front Pigs","DESCRIPTION"),
	amount = 5,
	rewards = {footballhat = 1,hambat = 1,[":func:health;25"] = 8},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["acquire x followers that are y"](inst,amount,"pigman",quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "pigman.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Front Pigs","HOVER",5),
	},
	--57
	{
	name = "Detective Work",
	victim = "",
	counter_name = GetQuestString("Detective Work","COUNTER"),
	description = GetQuestString("Detective Work","DESCRIPTION"),
	amount = 3,
	rewards = {steelwool = 2,ice = 20},
	points = 150,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["hunt x y times"](inst,amount,nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "koalefant_summer.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Detective Work","HOVER"),
	},
	--58
	{
	name = "Twins Of Destruction",
	victim = "",
	counter_name = GetQuestString("Twins Of Destruction","COUNTER"),
	description = GetQuestString("Twins Of Destruction","DESCRIPTION"),
	amount = 2,
	rewards = {gears = 10, transistor = 10,orangegem = 2,milkywhites = 5},
	points = 1750,
	start_fn = function(inst,amount,quest_name)
		local twins = inst.components.quest_component:GetQuestData(quest_name,"twins") or {[1] = false,[2] = false}
		local function OnKilled(inst,data)
			if data and data.victim then
				if data.victim.prefab == "twinofterror1" then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					twins[1] = true
					inst.components.quest_component:SetQuestData(quest_name,"twins",twins)
					inst:RemoveEventCallback("killed",OnKilled)
					inst:RemoveEventCallback("killedbyfriend",OnKilled)
				end
			end
		end
		if twins[1] == false then
			inst:ListenForEvent("killed",OnKilled)
			inst:ListenForEvent("killedbyfriend",OnKilled)
		end
		local function OnKilled2(inst,data)
			if data and data.victim then
				if data.victim.prefab == "twinofterror2" then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					twins[2] = true
					inst.components.quest_component:SetQuestData(quest_name,"twins",twins)
					inst:RemoveEventCallback("killed",OnKilled2)
					inst:RemoveEventCallback("killedbyfriend",OnKilled2)
				end
			end
		end
		if twins[2] == false then
			inst:ListenForEvent("killed",OnKilled2)
			inst:ListenForEvent("killedbyfriend",OnKilled2)
		end
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled)
			inst:RemoveEventCallback("killed",OnKilled2)
			inst:RemoveEventCallback("killedbyfriend",OnKilled)
			inst:RemoveEventCallback("killedbyfriend",OnKilled2)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 5,
	tex = "twinofterror1.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Twins Of Destruction","HOVER"),
	},
	--59
	{
	name = "The Biggest Frog",
	victim = "toadstool",
	counter_name = nil,
	description = GetQuestString("The Biggest Frog","DESCRIPTION"),
	amount = 1,
	rewards = {shroom_skin = 3,sleepbomb = 2,blue_mushroomhat = 1},
	points = 2500,
	start_fn = nil,
	onfinished = nil,
	difficulty = 5,
	tex = "toadstool.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("toadstool",1),
	},
	--60
	{
	name = "Ho Ho Ho",
	victim = "klaus",
	counter_name = nil,
	description = GetQuestString("Ho Ho Ho","DESCRIPTION"),
	amount = 1,
	rewards = {giftwrap = 20,[":func:krampus_sack"] = 10,mandrake = 2},
	points = 2000,
	start_fn = nil,
	onfinished = nil,
	difficulty = 5,
	tex = "klaus.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("klaus",1),
	},
	--61
	{
	name = "The Impregnable Fortress",
	victim = "crabking",
	counter_name = nil,
	description = GetQuestString("The Impregnable Fortress","DESCRIPTION"),
	amount = 1,
	rewards = {yellowgem = 5,greengem = 5,orangegem = 5,trident = 1},
	points = 2200,
	start_fn = nil,
	onfinished = nil,
	difficulty = 5,
	tex = "crabking.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("crabking",1),
	},
	--62
	{
	name = "The Master Chef",
	victim = "",
	counter_name = GetQuestString("The Master Chef","COUNTER"),
	description = GetQuestString("The Master Chef","DESCRIPTION"),
	amount = 1,
	rewards = {[":func:worker;1.6"] = 16,goldnugget = 5,golden_farm_hoe = 1},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["harvest x times y food with z ingredients from cookpot"](inst,amount,"lobsterdinner",nil,quest_name)
		local function OnFinishedQuest(inst,name)
			if name and name == quest_name then
				inst.components.inventory:ConsumeByName("lobsterdinner",1)
				inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
			end
		end
		inst:ListenForEvent("finished_quest",OnFinishedQuest)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "lobsterdinner.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Master Chef","HOVER",1),
	},
	--63
	{
	name = "Destroyer of Ancient Works",
	victim = "",
	counter_name = GetQuestString("Destroyer of Ancient Works","COUNTER"),
	description = GetQuestString("Destroyer of Ancient Works","DESCRIPTION"),
	amount = 3,
	rewards = {[":func:speed;1.3"] = 16,thulecite = 8,[":func:nightvision;1"] = 8},
	points = 1250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["finish work type z for x amount of y"](inst,ACTIONS.HAMMER,"ancient_altar_broken",amount,quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "ancient.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Destroyer of Ancient Works","HOVER",3),
	},
	--64
	{
	name = "The Goodest Boy",
	victim = "",
	counter_name = GetQuestString("The Goodest Boy","COUNTER"),
	description = GetQuestString("The Goodest Boy","DESCRIPTION",2),
	amount = 2,
	rewards = {[":func:range;1"] = 16,ruins_bat = 2},
	points = 1250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deploy x y times"](inst,amount,"eyeturret_item",quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "eyeturret_item.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Goodest Boy","HOVER",2),
	},
	--65
	{
	name = "The RPG Expert",
	victim = "",
	counter_name = GetQuestString("The RPG Expert","COUNTER"),
	description = GetQuestString("The RPG Expert","DESCRIPTION", 3),
	amount = 3,
	rewards = {[":func:health;10"] = 8,[":func:sanity;10"] = 8,[":func:hunger;10"] = 8,[":func:damagereduction;0.9"] = 8,[":func:damage;2"] = 8},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["gain x levels"](inst,amount,quest_name)
	end,
	onfinished = function(inst,items,quest_name)
		local quest = inst.components.quest_component.quests[quest_name]
		local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
		local old_scale = inst.components.quest_component.scaled_quests[quest_name]
		if old_scale then
			scale = math.max(old_scale,scale)
		end
		ScaleQuest(inst,quest_name,scale)
	end,
	difficulty = 1,
	tex = "arrow_3.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The RPG Expert","HOVER", 3),
	},
	custom_vars_fn = function(inst,amount,quest_name)
		local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
		local scale = math.random(1,max_scale)
		return {scale = scale}
	end,
	variable_fn = function(inst,quest,data)
		if data and data.scale then
			local scale = math.max(math.min(5,tonumber(data.scale)),1)
			local vars = {{3,125},{5,250},{10,500},{15,750},{20,1250}}
			if scale > 1 then
				quest.amount = vars[scale][1]
				quest.points = vars[scale][2]
				local reward_scale = {
					{[":func:health;10"] = 8,[":func:sanity;10"] = 8,[":func:hunger;10"] = 8,[":func:damagereduction;0.9"] = 8,[":func:damage;2"] = 8},
					{[":func:health;10"] = 16,[":func:sanity;10"] = 16,[":func:hunger;10"] = 16,[":func:damagereduction;0.9"] = 16,[":func:damage;2"] = 16},
					{[":func:health;25"] = 16,[":func:sanity;25"] = 16,[":func:hunger;25"] = 16,[":func:damagereduction;0.8"] = 16,[":func:damage;5"] = 16},
					{[":func:health;50"] = 16,[":func:sanity;50"] = 16,[":func:hunger;50"] = 16,[":func:damagereduction;0.7"] = 16,[":func:damage;10"] = 16},
				}
				quest.rewards = reward_scale[scale]
				quest.difficulty = scale
			end
			quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
			quest.description = GetQuestString(quest.name,"DESCRIPTION",vars[scale][1])
		end
		return quest
	end,
	--66
	{
	name = "The Questing Adventurer",
	victim = "",
	counter_name = GetQuestString("The Questing Adventurer","COUNTER"),
	description = GetQuestString("The Questing Adventurer","DESCRIPTION",7),
	amount = 7,
	rewards = {[":func:damagereduction;0.7"] = 16,saltrock = 10,refined_dust = 3,cutstone = 5},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["finish x quests of difficulty y"](inst,amount,nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "quest_board.tex",
	atlas = "images/images_quest_system.xml",
	hovertext = GetQuestString("The Questing Adventurer","HOVER",7),
	},
	--67
	{
	name = "Night Angler",
	victim = "",
	counter_name = GetQuestString("Night Angler","COUNTER"),
	description = GetQuestString("Night Angler","DESCRIPTION"),
	amount = 2,
	rewards = {surfnturf = 3,},
	points = 225,
	start_fn = function(inst,amount,quest_name)
		local fishes = GetCurrentAmount(inst,quest_name)
		local function OnCaughtFish(inst, caught_fish)
			if caught_fish then
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				fishes = fishes  + 1
				if fishes >= amount then
					inst:RemoveEventCallback("caught_fish", OnCaughtFish)
				end
			end
		end
		local function OnDisable(inst)
			fishes = 0
			inst:PushEvent("quest_update",{quest = quest_name,reset = true})
			inst:RemoveEventCallback("caught_fish", OnCaughtFish)
		end
		local function OnNight(inst,isnight)
			if not isnight then
				OnDisable(inst)
				return
			end
			inst:ListenForEvent("caught_fish", OnCaughtFish)
		end

		if TheWorld.state.isnight == true then
			OnNight(inst,true)
		end
		inst:WatchWorldState("isnight", OnNight)
		local function OnForfeitedQuest(inst)
			inst:StopWatchingWorldState("isnight", OnNight)
			inst:RemoveEventCallback("caught_fish", OnCaughtFish)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "oceanfishingrod.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("Night Angler","HOVER",2),
	},
	--68 nearly nice
	{
	name = "Kingfisher",
	victim = "",
	counter_name = GetQuestString("Kingfisher","COUNTER"),
	description = GetQuestString("Kingfisher","DESCRIPTION",2),
	amount = 2,
	rewards = {tallbirdegg = 5},
	points = 275,
	start_fn = function(inst,amount,quest_name)
		local frozen = GetCurrentAmount(inst,quest_name)
		local OnFreezeOther = function() end
		local OnFreeze = function() end
		local frozen_creatures = {}
		local listened_creatures = {}
		local function OnFreeze(bird)
			if frozen_creatures[bird.GUID] then
				return 
			end
			inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			bird:RemoveEventCallback("freeze",OnFreeze)
			frozen_creatures[bird.GUID] = true
			frozen = frozen + 1
			bird:DoTaskInTime(1,function() frozen_creatures[bird.GUID] = nil end)
			if frozen >= amount then
				inst:RemoveEventCallback("onhitother",OnFreezeOther)
			end
		end
		OnFreezeOther = function(inst,data)
			if data then
				if data.target and data.target.prefab == "tallbird" then
					if data.weapon and (data.weapon.prefab == "icestaff" or (data.weapon.prefab == "slingshot" and data.projectile == "slingshotammo_freeze_proj")) then
						if listened_creatures[data.target.GUID] ~= nil then
							return
						end
						listened_creatures[data.target.GUID] = true
						data.target:ListenForEvent("freeze",OnFreeze)
						if data.target.listenforfreezetask ~= nil then
							data.target.listenforfreezetask:Cancel()
							data.target.listenforfreezetask = nil
						end
						data.target.listenforfreezetask = data.target:DoTaskInTime(15, function(victim)
							if victim.listenforfreezetask ~= nil then
								victim.listenforfreezetask:Cancel()
								victim.listenforfreezetask = nil
								victim:RemoveEventCallback("freeze",OnFreeze)
								listened_creatures[victim.GUID] = nil
							end
						end)
					end
				end
			end
		end
		inst:ListenForEvent("onattackother",OnFreezeOther)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onattackother",OnFreezeOther)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "tallbird.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Kingfisher","HOVER",2),
	},
	--69 nice
	{
	name = "The Mad Hatter",
	victim = "",
	counter_name = GetQuestString("The Mad Hatter","COUNTER"),
	description = GetQuestString("The Mad Hatter","DESCRIPTION"),
	amount = 4,
	rewards = {eyebrellahat = 1},
	points = 450,
	start_fn = function(inst,amount,quest_name)
		local hats_built = inst.components.quest_component:GetQuestData(quest_name,"hats_built") or {beefalohat = false,featherhat = false,rainhat = false,catcoonhat = false}
		local function OnBuild(inst,data)
			if data then 
				if data.item and data.item.prefab and hats_built[data.item.prefab] == false then
					hats_built[data.item.prefab] = true
					inst.components.quest_component:SetQuestData(quest_name,"hats_built",hats_built)
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					for hat,bool in pairs(hats_built) do
						if bool == false then
							return
						end
					end
					inst:RemoveEventCallback("builditem",OnBuild)
				end
			end
		end
		inst:ListenForEvent("builditem",OnBuild)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("builditem",OnBuild)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "dress.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Mad Hatter","HOVER"),
	},
	--70 not nice anymore
	{
	name = "Wrong Offering",
	victim = "chester",
	counter_name = GetQuestString("Wrong Offering","COUNTER"),
	description = GetQuestString("Wrong Offering","DESCRIPTION"),
	amount = 1,
	rewards = {["Transform Chester to"] = "Ice Chester"},
	points = 166,
	start_fn = nil,
	onfinished = function(inst)
		local chester = TheSim:FindFirstEntityWithTag("chester") or SpawnPrefab("chester")
		local eyebone = TheSim:FindFirstEntityWithTag("chester_eyebone")
		if chester then
			if eyebone then
				local x,y,z = eyebone.Transform:GetWorldPosition()
				local a,b,c = chester.Transform:GetWorldPosition()
				if distsq(a,c,x,z) > 25 then
					chester.Physics:Teleport(x,y,z)
				end
			end
			chester:PushEvent("morph",{morphfn = function(chester) chester.OnPreLoad(chester,{ChesterState = "SNOW"}) end})
		end
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("Shadow World Manipulation") 
		end)
	end,
	difficulty = 2,
	tex = "chester.tex",
	atlas = "images/victims.xml",
	hovertext = GetKillString("chester",1),
	["reward_Transform Chester to_tex"] = "chester_eyebone_snow.tex", -- use this to add a reward picture for some that aren't able to get them by GetInventoryItemAtlas
	["reward_Transform Chester to_atlas"] = "images/inventoryimages1.xml",
	unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
	quest_line = true,
	},
	--71
	{
	name = "Shadow World Manipulation",
	victim = "",
	counter_name = GetQuestString("Shadow World Manipulation","COUNTER"),
	description = GetQuestString("Shadow World Manipulation","DESCRIPTION"),
	amount = 3,
	rewards = {telestaff = 1,purpleamulet = 1,},
	points = 266,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["build x y times"](inst,amount,"researchlab3",quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("Friends in the Shadow Realm")
		end)
	end,
	difficulty = 3,
	tex = "researchlab3.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("Shadow World Manipulation","HOVER"),
	unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
	quest_line = true,
	},
	--72
	{
	name = "Friends in the Shadow Realm",
	victim = "",
	counter_name = GetQuestString("Friends in the Shadow Realm","COUNTER"),
	description = GetQuestString("Friends in the Shadow Realm","DESCRIPTION"),
	amount = 366,
	rewards = {nightmarefuel = 20,},
	points = 366,
	start_fn = function(inst,amount,quest_name)
		local amount = GetCurrentAmount(inst,quest_name)
		local function CheckSanity(inst)
			if inst.components.sanity and inst.components.sanity.current < 5 then
				amount = amount + 1
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			end
			if amount >= amount then
				if inst.sanity_check_task ~= nil then
					inst.sanity_check_task:Cancel()
					inst.sanity_check_task = nil
				end
			else
				inst:DoTaskInTime(1,CheckSanity)
			end
		end
		if inst.sanity_check_task ~= nil then
			inst.sanity_check_task:Cancel()
			inst.sanity_check_task = nil
		end
		inst.sanity_check_task = inst:DoTaskInTime(1,CheckSanity)
		local function OnForfeitedQuest(inst)
			if inst.sanity_check_task ~= nil then
				inst.sanity_check_task:Cancel()
				inst.sanity_check_task = nil
			end
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("Your True Friends")
		end)
	end,
	difficulty = 4,
	tex = "sanity.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Friends in the Shadow Realm","HOVER"),
	unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
	quest_line = true,
	},
	--73
	{
	name = "Your True Friends",
	victim = "",
	counter_name = GetQuestString("Your True Friends","COUNTER"),
	description = GetQuestString("Your True Friends","DESCRIPTION"),
	amount = 2,
	rewards = {["Two Friends"] = ""},
	points = 666,
	start_fn = function(inst,amount,quest_name)
		inst:AddTag("can_fight_glommer")
		local function OnFight(inst)
			inst:PushEvent("quest_update",{quest = quest_name,amount = 2})
			--inst:DoTaskInTime(2*FRAMES,function() inst.components.quest_component:CompleteQuest("Your True Friends") end)
			inst:RemoveEventCallback("started_glommer_fight",OnFight)
		end
		inst:ListenForEvent("started_glommer_fight",OnFight)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("started_glommer_fight",OnFight)
			inst:RemoveTag("can_fight_glommer")
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
	end,
	difficulty = 5,
	tex = "glommerflower.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Your True Friends","HOVER"),
	unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
	quest_line = true,
	["reward_Two Friends_tex"] = "avatar_random.tex", 
	["reward_Two Friends_atlas"] = "images/avatars.xml",
	},
	--74
	{
	name = "Spiderman",
	victim = "",
	counter_name = GetQuestString("Spiderman","COUNTER"),
	description = GetQuestString("Spiderman","DESCRIPTION"),
	amount = 3,
	rewards = {spiderhat = 1,healingsalve = 10},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y with follower z"](inst,amount,"pigman",{spider = true,spider_warrior = true,spider_hider = true,spider_spitter = true,spider_dropper = true,spider_moon = true,spider_healer = true,spider_water = true},quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "pigman.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Spiderman","HOVER",3),
	},
	--75
	{
	name = "A Bunnys Job",
	victim = "",
	counter_name = GetQuestString("A Bunnys Job","COUNTER"),
	description = GetQuestString("A Bunnys Job","DESCRIPTION"),
	amount = 5,
	rewards = {manrabbit_tail = 5,carrot = 10},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y with follower z"](inst,amount,"bat",{bunnyman = true},quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "bat.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("A Bunnys Job","HOVER",5),
	},
	--76
	{
	name = "Your Own Fault",
	victim = "",
	counter_name = GetQuestString("Your Own Fault","COUNTER"),
	description = GetQuestString("Your Own Fault","DESCRIPTION",1),
	amount = 1,
	rewards = {blowdart_sleep = 3,blowdart_fire = 3,blowdart_pipe = 3,blowdart_yellow = 3,},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnKilled(inst,data)
			if data and data.target and data.target.prefab == "walrus" and data.target.components.health and data.target.components.health:IsDead() then
				local weapon = data.weapon
				if weapon and weapon:HasTag("blowdart") then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						inst:RemoveEventCallback("onhitother",OnKilled)
					end
				end
			end
		end
		inst:ListenForEvent("onhitother",OnKilled)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onhitother",OnKilled)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "walrus.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Your Own Fault","HOVER",1),
	},
	--77
	{
	name = "Death By Self",
	victim = "",
	counter_name = GetQuestString("Death By Self","COUNTER"),
	description = GetQuestString("Death By Self","DESCRIPTION",15),
	amount = 15,
	rewards = {[":func:escapedeath;1"] = 8,},
	points = 475,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnKilled(inst,data)
			if data and data.victim then
				if data.victim.prefab == "pigman" then
					local hand = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if hand and hand.prefab == "hambat" then
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						current = current + 1
						if current >= amount then
							inst:RemoveEventCallback("killed",OnKilled)
						end
					end
				end
			end
		end
		inst:ListenForEvent("killed",OnKilled)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "pigman.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Death By Self","HOVER",15),
	},
	--78
	{
	name = "The Inner Monster",
	victim = "",
	counter_name = GetQuestString("The Inner Monster","COUNTER"),
	description = GetQuestString("The Inner Monster","DESCRIPTION",3),
	amount = 3,
	rewards = {moonrocknugget = 5,pig_token = 1,pigskin = 5,},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnFedCreature(inst,data)
			if data and data.target and data.food then
				if data.target.prefab == "pigman" then
					if data.food.components.edible and data.food.components.edible.foodtype == FOODTYPE.MEAT and data.food.components.edible:GetHealth(data.target) < 0 then
						data.target:DoTaskInTime(1,function(pig)
							if pig.components.werebeast and pig.components.werebeast:IsInWereState() then
								current = current + 1
								inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
								if current >= amount then
									inst:RemoveEventCallback("fed_creature",OnFedCreature)
								end
							end
						end)
					end
				end
			end
		end
		inst:ListenForEvent("fed_creature",OnFedCreature)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("fed_creature",OnFedCreature)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "pigman.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Inner Monster","HOVER",3),
	},
	--79
	{
	name = "The Boxer",
	victim = "",
	counter_name = GetQuestString("The Boxer","COUNTER"),
	description = GetQuestString("The Boxer","DESCRIPTION",150),
	amount = 150,
	rewards = {[":func:damage;10"] = 8},
	points = 275,
	start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function OnDamageDone(inst,data)
			devprint("OnDamageDone", inst)
			devdumptable(data)
			if data then
				if data.damageresolved > 0 then
					if data.weapon == nil then
						current_amount = current_amount + data.damageresolved
						inst:PushEvent("quest_update",{quest = quest_name,amount = data.damageresolved})
						if current_amount >= amount then
							inst:RemoveEventCallback("onhitother",OnDamageDone)
						end
					end
				end
			end
		end
		inst:ListenForEvent("onhitother",OnDamageDone)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onhitother",OnDamageDone)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "fight.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Boxer","HOVER",150),
	},
	--80
	{
	name = "The Dish for the Pig",
	victim = "",
	counter_name = GetQuestString("The Dish for the Pig","COUNTER"),
	description = GetQuestString("The Dish for the Pig","DESCRIPTION"),
	amount = 1,
	rewards = {turkeydinner = 3,[":func:hungerrate;0.8"] = 16,},
	points = 300,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnFedCreature(inst,data)
			if data and data.target and data.food then
				if data.target.prefab == "pigman" then
					if data.food.prefab == "lobsterdinner" then
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						inst:RemoveEventCallback("fed_creature",OnFedCreature)
					end
				end
			end
		end
		inst:ListenForEvent("fed_creature",OnFedCreature)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("fed_creature",OnFedCreature)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 2,
	tex = "lobsterdinner.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Dish for the Pig","HOVER"),
	},
	--81
	{
	name = "A Useful Companion",
	victim = "",
	counter_name = GetQuestString("A Useful Companion","COUNTER"),
	description = GetQuestString("A Useful Companion","DESCRIPTION",60),
	amount = 60,
	rewards = {horn = 2,beefalowool = 10,},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		TheWorld.components.quest_loadpostpass.quest_lines[quest_name] = true
		local current = GetCurrentAmount(inst,quest_name)
		local function StopTask(inst)
			if inst.check_riding_task ~= nil then
				inst.check_riding_task:Cancel()
				inst.check_riding_task = nil
			end
		end
		local function OnMounted(inst,data)
			StopTask(inst)
			inst.check_riding_task = inst:DoPeriodicTask(1,function()
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				current = current + 1
				if current >= amount then
					inst:RemoveEventCallback("mounted",OnMounted)
					inst:RemoveEventCallback("dismounted",StopTask)
				end
			end)
		end
		if inst.components.rider and inst.components.rider:IsRiding() then
			OnMounted(inst)
		end
		inst:ListenForEvent("mounted",OnMounted)
		inst:ListenForEvent("dismounted",StopTask)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("mounted",OnMounted)
			inst:RemoveEventCallback("dismounted",StopTask)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("Marble Trees?!")
		end)
	end,
	difficulty = 1,
	tex = "beefalo.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("A Useful Companion","HOVER",60),
	quest_line = true,
	},
	--82
	{
	name = "Marble Trees?!",
	victim = "",
	counter_name = GetQuestString("Marble Trees?!","COUNTER"),
	description = GetQuestString("Marble Trees?!","DESCRIPTION",15),
	amount = 15,
	rewards = {marble = 10,[":func:worker;1.4"] = 16,},
	points = 275,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnDeploy(inst,data)
			if data and data.prefab == "marblebean" then
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				current = current + 1
				if current > amount then
					inst:RemoveEventCallback("deployitem",OnDeploy)
				end
			end
		end
		inst:ListenForEvent("deployitem",OnDeploy)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("deployitem",OnDeploy)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("The Stonemason")
		end)
	end,
	difficulty = 2,
	tex = "marblebean.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Marble Trees?!","HOVER",15),
	quest_line = true,
	unlisted = true,
	},
	--83
	{
	name = "The Stonemason",
	victim = "",
	counter_name = GetQuestString("The Stonemason","COUNTER"),
	description = GetQuestString("The Stonemason","DESCRIPTION",7),
	amount = 7,
	rewards = {marblebean = 10,[":func:damagereduction;0.8"] = 16,},
	points = 550,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,"armormarble",nil,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("The Shadow Plague")
		end)
	end,
	difficulty = 3,
	tex = "armormarble.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Stonemason","HOVER",7),
	quest_line = true,
	unlisted = true,
	},
	--84
	{
	name = "The Shadow Plague",
	victim = "",
	counter_name = GetQuestString("The Shadow Plague","COUNTER"),
	description = GetQuestString("The Shadow Plague","DESCRIPTION",30),
	amount = 30,
	rewards = {leafymeatsouffle = 5,[":func:sanityaura;10"] = 16,[":func:healthrate;2"] = 16,},
	points = 875,
	start_fn = function(inst,amount,quest_name)
		--TODO: check perhaps only for tag shadowcreature
		local current = GetCurrentAmount(inst,quest_name)
		local shadows = {crawlinghorror = true,crawlingnightmare = true,terrorbeak = true,nightmarebeak = true,oceanhorror = true,}
		local function OnKilled(inst,data)
			if data and data.victim and data.victim.prefab then
				if shadows[data.victim.prefab] then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						inst:RemoveEventCallback("killed",OnKilled)
					end
				end
			end
		end
		inst:ListenForEvent("killed",OnKilled)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("The Pieces of Downfall")
		end)
	end,
	difficulty = 4,
	tex = "terrorbeak.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Shadow Plague","HOVER",30),
	quest_line = true,
	unlisted = true,
	},
	--85
	{
	name = "The Pieces of Downfall",
	victim = "",
	counter_name = GetQuestString("The Pieces of Downfall","COUNTER"),
	description = GetQuestString("The Pieces of Downfall","DESCRIPTION"),
	amount = 3,
	rewards = {shadowheart = 1,shadow_crest = 1,shadow_mitre = 1,shadow_lance = 1,},
	points = 1680,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local values = inst.components.quest_component:GetQuestData(quest_name,"marble_statues")
		local marble_statues = values or {chesspiece_rook = false,chesspiece_knight= false,chesspiece_bishop = false,}
		local values2 = inst.components.quest_component:GetQuestData(quest_name,"shadow_pieces")
		local shadow_pieces = values2 or {shadow_knight = false,shadow_bishop = false,shadow_rook = false}
		local function SpawnShadowPieces(inst)
			local pos = inst:GetPosition() or Vector3(0,0,0)
			for piece in pairs(shadow_pieces) do
				local shadow = SpawnPrefab(piece)
				local new_pos = GetSpawnPoint(pos,9)
				shadow.Transform:SetPosition(new_pos:Get())
				shadow:LevelUp(3)
			end
		end
		local function OnEntityDeath(world,data)
			if data and data.inst then
				if shadow_pieces[data.inst.prefab] == false then
					shadow_pieces[data.inst.prefab] = true
					data.inst.components.lootdropper:SetLootSetupFn(nil)
					inst.components.quest_component:SetQuestData(quest_name,"shadow_pieces",shadow_pieces)
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if current >= amount then
						TheWorld:RemoveEventCallback("entity_death",OnEntityDeath)
					end
				end
			end
		end
		local function OnWorkFinished(inst,data)
			if TheWorld.state.isfullmoon and data and data.target then
				if marble_statues[data.target.prefab] == false and data.target.materialid == 1 then 	--materialid 1 is marble
					marble_statues[data.target.prefab] = true
					inst.components.quest_component:SetQuestData(quest_name,"marble_statues",marble_statues)
					for k,v in pairs(marble_statues) do
						if v == false then
							return
						end
					end
					SpawnShadowPieces(inst)
					inst:RemoveEventCallback("finishedwork",OnWorkFinished)
					TheWorld:ListenForEvent("entity_death",OnEntityDeath)
				end
			end
		end
		for k,v in pairs(marble_statues) do
			if v == false then
				inst:ListenForEvent("finishedwork",OnWorkFinished)
				return
			end
		end
		TheWorld:ListenForEvent("entity_death",OnEntityDeath)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("finishedwork",OnWorkFinished)
			TheWorld:RemoveEventCallback("entity_death",OnEntityDeath)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)

	end,
	difficulty = 5,
	tex = "shadow_rook.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Pieces of Downfall","HOVER"),
	quest_line = true,
	unlisted = true,
	},
	--86
	{
	name = "The Ancient Craft",
	victim = "",
	counter_name = GetQuestString("The Ancient Craft","COUNTER"),
	description = GetQuestString("The Ancient Craft","DESCRIPTION"),
	amount = 5,
	rewards = {trunk_winter = 3,rock_avocado_fruit = 10,voltgoatjelly = 2},
	points = 525,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,"thulecite",nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "thulecite.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("The Ancient Craft","HOVER",5),
	reward_rock_avocado_fruit_tex = "rock_avocado_fruit_rockhard.tex",
	},
	--87
	{
	name = "The Shadow Slayer",
	victim = "",
	counter_name = GetQuestString("The Shadow Slayer","COUNTER"),
	description = GetQuestString("The Shadow Slayer","DESCRIPTION"),
	amount = 10,
	rewards = {glasscutter = 2,moonrocknugget = 10,thulecite = 2},
	points = 550,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local shadows = {crawlingnightmare = true,nightmarebeak = true,}
		local function OnKilled(inst,data)
			if data and data.victim and data.victim.prefab then
				if shadows[data.victim.prefab] and TheWorld.state.isnightmarewild then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						inst:RemoveEventCallback("killed",OnKilled)
						inst:RemoveEventCallback("killedbyfriend", OnKilled)
					end
				end
			end
		end
		inst:ListenForEvent("killed",OnKilled)
		inst:ListenForEvent("killedbyfriend", OnKilled)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("killed",OnKilled)
			inst:RemoveEventCallback("killedbyfriend", OnKilled)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "crawlinghorror.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Shadow Slayer","HOVER",10),
	},
	--88
	{
	name = "Suicidal Thoughts",
	victim = "",
	counter_name = GetQuestString("Suicidal Thoughts","COUNTER"),
	description = GetQuestString("Suicidal Thoughts","DESCRIPTION"),
	amount = 1,
	rewards = {[":func:escapedeath;1"] = 16,ruinshat = 1,livinglog = 8,gunpowder = 12,},
	points = 1225,
	start_fn = function(inst,amount,quest_name)
		local function OnExplode(inst,data)
			if data then
				local expl = data.explosive
				if expl and expl.prefab == "gunpowder" and expl.components.stackable and expl.components.stackable:StackSize() >= 25 then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					inst:RemoveEventCallback("explosion",OnExplode)
				end
			end
		end
		inst:ListenForEvent("explosion",OnExplode)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("explosion",OnExplode)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 4,
	tex = "gunpowder.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("Suicidal Thoughts","HOVER"),
	},
	--89
	{
	name = "The Untalented Chef",
	victim = "",
	counter_name = GetQuestString("The Untalented Chef","COUNTER"),
	description = GetQuestString("The Untalented Chef","DESCRIPTION"),
	amount = 3,
	rewards = {lobsterdinner = 2},
	points = 130,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["harvest x times y food with z ingredients from cookpot"](inst,amount,"wetgoop",nil,quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "wetgoop.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("The Untalented Chef","HOVER",3),
	},
	--90
	{
	name = "The Flower Lover",
	victim = "",
	counter_name = GetQuestString("The Flower Lover","COUNTER"),
	description = GetQuestString("The Flower Lover","DESCRIPTION",20),
	amount = 20,
	rewards = {petals = 20,butter  = 1},
	points = 150,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deploy x y times"](inst,amount,"butterfly",quest_name)
	end,
	onfinished = nil,
	difficulty = 1,
	tex = "petals.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("The Flower Lover","HOVER",20),
	},
	--91
	{
	name = "The Fish Fisher",
	victim = "",
	counter_name = GetQuestString("The Fish Fisher","COUNTER"),
	description = GetQuestString("The Fish Fisher","DESCRIPTION"),
	amount = 2,
	rewards = {messagebottleempty = 3,fig = 20},
	points = 485,
	start_fn = function(inst,amount,quest_name)
		local data = inst.components.quest_component.quests[quest_name] and inst.components.quest_component.quests[quest_name].custom_vars
		local fish = data and data.fish or "oceanfish_small_1"
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["catch x amount of y fish"](inst,amount,fish,quest_name)
	end,
	onfinished = nil,
	difficulty = 3,
	tex = "oceanfish_small_1.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("The Fish Fisher","HOVER"),
	custom_vars_fn = function(inst)
		local fishes = {}
		for i = 1,9 do
			table.insert(fishes,"oceanfish_small_"..i)
			table.insert(fishes,"oceanfish_medium_"..i)
		end
		local fish = fishes[math.random(#fishes)]
		return {fish = fish}
	end,
	variable_fn = function(inst,quest,data)
		if data then
			local fish_name = data.fish and STRINGS.NAMES[string.upper(data.fish)] or data.fish or "nil"
			quest.counter_name = GetQuestString("The Fish Fisher","COUNTER",fish_name)
			quest.description = GetQuestString("The Fish Fisher","DESCRIPTION",fish_name)
			quest.hovertext = GetQuestString("The Fish Fisher","HOVER",fish_name)
			quest.tex = data.fish and data.fish.."_inv.tex" or quest.tex
			quest.scale = {fish_name}
		end
		return quest
	end,
	},
	--92
	{
	name = "The Tormented Dust Moth",
	victim = "",
	counter_name = GetQuestString("The Tormented Dust Moth","COUNTER"),
	description = GetQuestString("The Tormented Dust Moth","DESCRIPTION"),
	amount = 1,
	rewards = {thulecite = 20,[":func:escapedeath;2"]  = 16},
	points = 2500,
	start_fn = function(inst,amount,quest_name)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["protect x from y creatures z times"](inst,amount,7,5,15,5,"dustmoth",quest_name,60,120)
	end,
	onfinished = nil,
	difficulty = 5,
	tex = "dustmoth.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Tormented Dust Moth","HOVER"),
	},
	--93
	{
	name = "The Sleeping Beauty",
	victim = "",
	counter_name = GetQuestString("The Sleeping Beauty","COUNTER"),
	description = GetQuestString("The Sleeping Beauty","DESCRIPTION"),
	amount = 30,
	rewards = {flowerhat = 1, halloweenpotion_sanity_large = 1},
	points = 125,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local OnSleep
		local function OnTick(inst)
			if inst.components.sleepingbaguser and inst.components.sleepingbaguser.sleeptask then 
				current = current + 1
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
				if current >= amount then
					inst:RemoveEventCallback("startsleeping",OnSleep)
					if inst.quest_name then 
						inst.quest_name:Cancel()
						inst.quest_name = nil
					end
				end
			else
				if inst.quest_name then 
					inst.quest_name:Cancel()
					inst.quest_name = nil
				end
			end
		end
		OnSleep = function(inst,bed)
			if inst.components.sleepingbaguser and inst.components.sleepingbaguser.sleeptask then 
				inst.quest_name = inst:DoPeriodicTask(1,OnTick)
			end
		end
		inst:ListenForEvent("startsleeping", OnSleep)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("startsleeping",OnSleep)
			if inst.quest_name then 
				inst.quest_name:Cancel()
				inst.quest_name = nil
			end
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("The Ocean Chose Me!")
		end)
	end,
	difficulty = 1,
	tex = "sleeping.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Sleeping Beauty","HOVER",30),
	quest_line = true,
	},
	--94
	{
	name = "The Ocean Chose Me!",
	victim = "",
	counter_name = GetQuestString("The Ocean Chose Me!","COUNTER"),
	description = GetQuestString("The Ocean Chose Me!","DESCRIPTION",3),
	amount = 3,
	rewards = {mast_malbatross_item = 1,singingshell_octave3 = 1,singingshell_octave4 = 1,singingshell_octave5 = 1},
	points = 250,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local function OnHarvest(inst,data)
			if data and data.object then 
				if data.object.prefab == "waterplant" then
					current = current + 1
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if current >= amount then
						inst:RemoveEventCallback("harvestsomething",OnHarvest)
					end
				end
			end
		end
		inst:ListenForEvent("harvestsomething", OnHarvest)
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("harvestsomething",OnHarvest)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("The Seven Dwarfs")
		end)
	end,
	difficulty = 2,
	tex = "waterplant.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("The Ocean Chose Me!","HOVER",3),
	reward_singingshell_octave3_tex = "singingshell_octave3_3.tex",
	reward_singingshell_octave3_atlas = "images/inventoryimages2.xml",
	reward_singingshell_octave4_tex = "singingshell_octave4_3.tex",
	reward_singingshell_octave4_atlas = "images/inventoryimages2.xml",
	reward_singingshell_octave5_tex = "singingshell_octave5_3.tex",
	reward_singingshell_octave5_atlas = "images/inventoryimages2.xml",
	quest_line = true,
	unlisted = true,
	},
	--95
	{
	name = "The Seven Dwarfs",
	victim = "",
	counter_name = GetQuestString("The Seven Dwarfs","COUNTER"),
	description = GetQuestString("The Seven Dwarfs","DESCRIPTION"),
	amount = 7,
	rewards = {[":func:escapedeath;1"] = 16,winter_food2 = 1,winter_food7 = 1,brush = 1},
	points = 500,
	start_fn = function(inst,amount,quest_name)
		local function OnKilled(inst, data)
			if math.random() < 0.05 then
				local victim = data.victim
				if victim and victim.components.lootdropper then
					victim.components.lootdropper:FlingItem(SpawnPrefab("trinket_4"))
				end
			end
		end
		local function RemoveDwarfDropper(inst)
			inst:RemoveEventCallback("killed", OnKilled)
		end
		inst:ListenForEvent("killed", OnKilled)
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["trade x amount of item y with pigking"](inst,amount, {"trinket_4"},quest_name,RemoveDwarfDropper)

	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function()
			inst.components.quest_component:AddQuest("The Cold Never Bothered Me Anyway!")
		end)
	end,
	difficulty = 3,
	tex = "trinket_4.tex",
	atlas = "images/inventoryimages2.xml",
	hovertext = GetQuestString("The Seven Dwarfs","HOVER"),
	quest_line = true,
	unlisted = true,
	},
	--96
	{
	name = "The Cold Never Bothered Me Anyway!",
	victim = "",
	counter_name = GetQuestString("The Cold Never Bothered Me Anyway!","COUNTER"),
	description = GetQuestString("The Cold Never Bothered Me Anyway!","DESCRIPTION"),
	amount = 60,
	rewards = { opalstaff = 1,icestaff = 1, oceanfish_medium_8_inv = 1,ice = 40},
	points = 1000,
	start_fn = function(inst,amount,quest_name)
		local function OnAllGood(inst)
			if inst.components.hunger and inst.components.hunger:IsStarving() then
				if inst.components.sanity and inst.components.sanity.current <= 10 then
					if inst.components.temperature and inst.components.temperature:IsFreezing() then
						return true
					end
				end
			end
		end
		TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x each second for y seconds"](inst,amount,OnAllGood,1,quest_name)
	end,
	onfinished = function(inst)
		inst:DoTaskInTime(0,function() 
			inst.components.quest_component:AddQuest("Kiss The Frog!")
		end)
	end,
	difficulty = 4,
	tex = "icestaff.tex",
	atlas = "images/inventoryimages1.xml",
	hovertext = GetQuestString("The Cold Never Bothered Me Anyway!","HOVER",60),
	quest_line = true,
	unlisted = true,
	},
	--97
	{
	name = "Kiss The Frog!",
	victim = "",
	counter_name = GetQuestString("Kiss The Frog!","COUNTER"),
	description = GetQuestString("Kiss The Frog!","DESCRIPTION"),
	amount = 50,
	rewards = { fireflies = 1, nightstick = 1},
	points = 2000,
	start_fn = function(inst,amount,quest_name)
		local current = GetCurrentAmount(inst,quest_name)
		local FrogRain, StopFrogRain = FrogKing.SpawnFrogRain(inst,{1,0.09,0.09,1})
		local function SpawnFrogKing(inst)
			local spawn_point = GetSpawnPoint(inst:GetPosition())
			local frogking = SpawnPrefab("frogking")
			if frogking then
				frogking.Transform:SetPosition(spawn_point.x, 0, spawn_point.z)
			end
		end
		local function OnHitOther(inst,data)
			if data and data.target then
				if data.target.prefab == "frog" then
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						SpawnFrogKing(inst)
						inst:RemoveEventCallback("onhitother",OnHitOther)
						StopFrogRain(inst)
					else
						FrogRain(inst)
					end
				end
			end
		end
		if current < amount then
			inst:ListenForEvent("onhitother",OnHitOther)
		end
		
		local function OnForfeitedQuest(inst)
			inst:RemoveEventCallback("onhitother",OnHitOther)
			StopFrogRain(inst)
		end
		OnForfeit(inst,OnForfeitedQuest,quest_name)
	end,
	onfinished = nil,
	difficulty = 5,
	tex = "frog.tex",
	atlas = "images/victims.xml",
	hovertext = GetQuestString("Kiss The Frog!","HOVER",50),
	quest_line = true,
	unlisted = true,
	},



}

if TUNING.QUEST_COMPONENT.GLOBAL_REWARDS then
	quests[52].rewards["Next Night"] = "FullMoon"
	quests[52].onfinished = function(inst)
		TheWorld:PushEvent("ms_setmoonphase", {moonphase = "full", iswaxing = false})
		inst:DoTaskInTime(0,function()
			inst.components.quest_component:AddQuest("Wrong Offering") 
		end)
	end

	quests[72].amount = 66
	quests[72].start_fn = function(inst,amount,quest_name)
		local current_amount = GetCurrentAmount(inst,quest_name)
		local function CheckSanity(world)
			local success = true
			for _,player in ipairs(AllPlayers) do
				if player.components.sanity and player.components.sanity.current < 10 then
					--nothing
				else
					success = false
					break
				end
			end
			if success then
				current_amount = current_amount + 1
				inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
			end
			if current_amount >= amount then
				if TheWorld.sanity_check_all_players_task ~= nil then
					TheWorld.sanity_check_all_players_task:Cancel()
					TheWorld.sanity_check_all_players_task = nil
				end
			else
				TheWorld:DoTaskInTime(1,CheckSanity)
			end
		end
		TheWorld.sanity_check_all_players_task = TheWorld:DoTaskInTime(1,CheckSanity)
	end
end

return quests