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

local function StopTask(entity, task)
	if entity[task] ~= nil then
		entity[task]:Cancel()
		entity[task] = nil
	end
end

local quest_functions = require("quest_util/quest_functions")
local GetCurrentAmount = quest_functions.GetCurrentAmount
local GetValues = quest_functions.GetValues
local RemoveValues = quest_functions.RemoveValues
local MakeScalable = quest_functions.MakeScalable
local ScaleQuest = quest_functions.ScaleQuest
local ScaleEnd = quest_functions.ScaleEnd
local CreateQuest = quest_functions.CreateQuest
local OnForfeit = quest_functions.OnForfeit

local quests = {
	--1
	CreateQuest({
		name = "The Wicked Mist Fury",
		victim = "spider_water",
		description = GetQuestString("The Wicked Mist Fury","DESCRIPTION"),
		amount = 10,
		rewards = {spidereggsack = 1, silk = 12},
		points = 200,
		difficulty = 2,
	}),
	--2
	CreateQuest({
		name = "The Powerful Shadow from Below",
		victim = "oceanhorror",
		description = GetQuestString("The Powerful Shadow from Below","DESCRIPTION"),
		amount = 5,
		rewards = { nightsword = 1, nightmarefuel = 20},
		points = 200,
		difficulty = 3,
	}),
	--3
	CreateQuest({
		name = "The Reckoning of the Gestalt",
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
		difficulty = 1,
		tex = "celestial.tex",
		atlas = "images/victims.xml",
		anim_prefab = "gestalt_guard",
	}),
	--4
	CreateQuest(
	{
		name = "The Corrupt Prophecy Revenge",
		victim = "glommer",
		description = GetQuestString("The Corrupt Prophecy Revenge","DESCRIPTION"),
		amount = 1,
		rewards = {panflute = 1, mandrake = 1},
		points = 150,
		difficulty = 1,
	}),
	--5
	CreateQuest({
		name = "The Monstrous Delicacy",
		description = GetQuestString("The Monstrous Delicacy","DESCRIPTION"),
		amount = 5,
		rewards = {healingsalve = 5, baconeggs = 1},
		points = 100,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst,"monsterlasagna",amount,quest_name)
		end,
		difficulty = 2,
		tex = "monsterlasagna.tex",
		atlas = "images/inventoryimages1.xml",
	}),
	--6
	CreateQuest({
		name = "The Explorers End",
		victim = "alterguardian_phase3",
		description = GetQuestString("The Explorers End","DESCRIPTION"),
		amount = 1,
		rewards = {moonglass_charged = 5,["Duplicate items"] = "Inventory+Equipped"},
		points = 3000,
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
		custom_rewards_paths = {
			["Duplicate items"] = {"backpack.tex","images/inventoryimages1.xml"},
		},
	}),
	--7
	CreateQuest({
		name = "Within the Labyrinth",
		victim = "minotaur",
		description = GetQuestString("Within the Labyrinth","DESCRIPTION"),
		amount = 1,
		rewards = {eyeturret_item = 1},
		points = 1500,
		difficulty = 5,
	}),
	--8
	CreateQuest({
		name = "The Stone from Below",
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
		difficulty = 2,
		tex = "fossil_piece.tex",
		atlas = "images/inventoryimages1.xml",
	}),
	--9
	CreateQuest({
		name = "Beyond the Charming Hamlet",
		victim = "pigman",
		description = GetQuestString("Beyond the Charming Hamlet","DESCRIPTION"),
		amount = 10,
		rewards = {poop = 10, meat = 10, pigskin = 10},
		points = 300,
		difficulty = 3,
	}),
	--10
	CreateQuest({
		name = "Corpses of the Swampy Badlands",
		victim = "tentacle",
		description = GetQuestString("Corpses of the Swampy Badlands","DESCRIPTION"),
		amount = 5,
		rewards = {tentaclespots = 3, boneshard = 10, boards = 6},
		points = 350,
		difficulty = 3,
	}),
	--11
	CreateQuest({
		name = "The Bane of Lake Nen",
		victim = "malbatross",
		description = GetQuestString("The Bane of Lake Nen","DESCRIPTION"),
		amount = 1,
		rewards = {malbatross_feathered_weave = 2, oceanfish_small_8_inv = 1, oceanfish_medium_8_inv = 1},
		points = 1000,
		difficulty = 4,
	}),
	--12
	CreateQuest({
		name = "The Scorched Nightmare Amulet",
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
		difficulty = 3,
		tex = "light.tex",
		atlas = "images/victims.xml",
	}),
	--13
	CreateQuest({
		name = "The Fearful Trial",
		description = GetQuestString("The Fearful Trial","DESCRIPTION"),
		amount = 4,
		rewards = {orangestaff = 1, ruinshat = 2, armorruins = 2, [":func:dodge;5"] = 8,},
		points = 2000,
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
		difficulty = 5,
		tex = "fight.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Fearful Trial","HOVER"),
	}),
	--14
	CreateQuest({
		name = "Across the Desert",
		victim = "antlion",
		description = GetQuestString("Across the Desert","DESCRIPTION"),
		amount = 1,
		rewards = {antliontrinket = 3, blueprint = 3},
		points = 750,
		difficulty = 4,
	}),
	--15
	CreateQuest({
		name = "The Corrupt Darkness",
		description = GetQuestString("The Corrupt Darkness","DESCRIPTION"),
		amount = 10,
		rewards = {armor_sanity = 2, nightsword = 1, nightmarefuel = 15},
		points = 300,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["get hit x times by charlie"](inst,amount,quest_name)
		end,
		difficulty = 3,
		tex = "health.tex",
		atlas = "images/victims.xml",
		anim_prefab = "charlie_npc",
	}),
	--16
	CreateQuest({
		name = "The Legend of the Trade Road",
		description = GetQuestString("The Legend of the Trade Road","DESCRIPTION"),
		amount = 20,
		rewards = {goldnugget = 20},
		points = 100,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["trade x amount of item y with pigking"](inst,amount,nil,quest_name)
		end,
		difficulty = 1,
		tex = "pigking.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigking",
	}),
	--17
	CreateQuest({
		name = "The Vampire Dungeon",
		victim = "bat",
		description = GetQuestString("The Vampire Dungeon","DESCRIPTION"),
		amount = 30,
		rewards = {meat_dried = 5, rocks = 15, flint = 15},
		points = 150,
		difficulty = 2,
	}),
	--18
	CreateQuest({
		name = "Within the Stream",
		counter_name = GetQuestString("Within the Stream","COUNTER"),
		amount = 10,
		rewards = {oceanfish_small_9_inv = 2, oceanfish_small_8_inv = 1, oceanfishingbobber_crow = 1},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["catch x amount of y fish"](inst,amount,nil,quest_name)
		end,
		difficulty = 2,
		tex = "fishing.tex",
		atlas = "images/victims.xml",
	}),
	--19
	CreateQuest({
		name = "Mage of the Manor Baldur",
		description = GetQuestString("Mage of the Manor Baldur","DESCRIPTION"),
		amount = 1,
		rewards = {purplegem = 5, rope = 5, boards = 5},
		points = 400,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["teleport x times y away"](inst,amount,"deerclops",quest_name)
		end,
		difficulty = 3,
		tex = "deerclops.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Mage of the Manor Baldur","HOVER"),
		anim_prefab = "deerclops",
	}),
	--20
	CreateQuest({
		name = "The Rage of Ioun",
		victim = "spider",
		description = GetQuestString("The Rage of Ioun","DESCRIPTION"),
		amount = 25,
		rewards = {goldnugget = 10, boneshard = 6, log = 12},
		points = 350,
		difficulty = 2,
	}),
	--21
	CreateQuest({
		name = "The Sack For the Unlucky",
		victim = "krampus",
		description = GetQuestString("The Sack For the Unlucky","DESCRIPTION"),
		amount = 33,
		rewards = {krampus_sack = 1},
		points = 1000,
		difficulty = 4,
	}),
	--22
	CreateQuest({
		name = "Below the Abandoned Land",
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
		difficulty = 2,
		tex = "tools.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Below the Abandoned Land","HOVER"),
	}),
	--23
	CreateQuest({
		name = "A Cute Companion",
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
		difficulty = 2,
		tex = "hutch_fishbowl.tex",
		atlas = "images/inventoryimages1.xml",
		hovertext = GetQuestString("A Cute Companion","HOVER"),
	}),
	--24
	CreateQuest({
		name = "The Allies Within the Land",
		amount = 10,
		rewards = {onemanband = 3,wormlight = 10},
		points = 350,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["acquire x followers that are y"](inst,amount,nil,quest_name)
		end,
		difficulty = 3,
		tex = "critters.tex",
		atlas = "images/victims.xml",
	}),
	--25
	CreateQuest({
		name = "Orcus's Living Dead",
		victim = "mutatedhound",
		description = GetQuestString("Orcus's Living Dead","DESCRIPTION"),
		amount = 10,
		rewards = {moonrocknugget = 10,moonglass = 10},
		points = 500,
		difficulty = 3,
	}),
	--26
	CreateQuest({
		name = "The Damned Legacy",
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
		difficulty = 4,
		tex = "moonbase.tex",
		atlas = "images/victims.xml",
		--anim_prefab = "moonbase",
	}),
	--27
	CreateQuest({
		name = "The Abandoned Chester",
		victim = "",
		counter_name = GetQuestString("The Abandoned Chester","COUNTER"),
		description = GetQuestString("The Abandoned Chester","DESCRIPTION"),
		amount = 1,
		rewards = {nightmarefuel = 80,purpleamulet = 3},
		points = 1000,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["protect x from y creatures z times"](inst, amount, 6, 3, 15, 4, "chester", quest_name, 90, 180)
		end,
		onfinished = nil,
		difficulty = 4,
		tex = "fight.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Abandoned Chester","HOVER"),
	}),
	--28
	CreateQuest({
		name = "The Sharks Demise",
		victim = "shark",
		description = GetQuestString("The Sharks Demise","DESCRIPTION"),
		amount = 1,
		rewards = {fishmeat = 10,blowdart_yellow = 5},
		points = 800,
		difficulty = 4,
	}),
	--29
	CreateQuest({
		name = "The Houndstooth Curse",
		victim = "warg",
		description = GetQuestString("The Houndstooth Curse","DESCRIPTION"),
		amount = 1,
		rewards = {premiumwateringcan = 1,gears = 5},
		points = 500,
		difficulty = 3,
	}),
	--30
	CreateQuest({
		name = "The Possessed Crows",
		victim = "crow",
		description = GetQuestString("The Possessed Crows","DESCRIPTION"),
		amount = 10,
		rewards = {boards = 5,nitre = 10},
		points = 100,
		difficulty = 1,
	}),
	--31
	CreateQuest({
		name = "Colors of the Rainbow",
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
		difficulty = 3,
		tex = "ancient.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Colors of the Rainbow","HOVER"),
	}),
	--32
	CreateQuest({
		name = "Bright Worshipnight",
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
		difficulty = 2,
		tex = "glommer_lightflower.tex",
		atlas = "images/glommer_lightflower.xml",
		hovertext = GetQuestString("Bright Worshipnight","HOVER"),
		anim_prefab = "glommer_lightflower",
	}),
	--33
	CreateQuest({
		name = "Mirror of Merms",
		victim = "merm",
		counter_name = GetQuestString("Mirror of Merms","COUNTER"),
		description = GetQuestString("Mirror of Merms","DESCRIPTION",5),
		amount = 5,
		rewards = {ruins_bat = 1,rocks = 15,froglegs = 5},
		points = 750,
		start_fn = function(inst,amount,quest_name)
			local function OnHitMerm(inst,data)
				--devprint("OnHitMerm", inst, data.target, data.target and data.target.prefab)
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
		difficulty = 3,
	}),
	--34
	CreateQuest({
		name = "Giving back to Nature",
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
		difficulty = 1,
		tex = "fireflies.tex",
		custom_rewards_paths = {
			onion = {
				"quagmire_onion.tex",
				"images/inventoryimages2.xml",
			}
		},
	}),
	--35
	CreateQuest({
		name = "A Crappy Day",
		description = GetQuestString("A Crappy Day","DESCRIPTION"),
		amount = 5,
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
		difficulty = 2,
		tex = "poop.tex",
	}),
	--36
	CreateQuest({
		name = "Revenge of the crapped victim",
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
		difficulty = 3,
		tex = "phlegm.tex",
		hovertext = GetQuestString("Revenge of the crapped victim","HOVER"),
	}),
	--37
	CreateQuest({
		name = "Luminous globules",
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
		difficulty = 1,
		tex = "lightbulb.tex",
	}),
	--38
	CreateQuest({
		name = "Beary Hunger",
		victim = "perd",
		description = GetQuestString("Beary Hunger","DESCRIPTION"),
		amount = 1,
		rewards = {berries = 10,dug_berrybush = 3},
		points = 125,
		difficulty = 1,
	}),
	--39
	CreateQuest({
		name = "Wetlands",
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
		scalable = {
			amount = {60,120,180,300,480},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {raincoat = 1,umbrella = 1,[":func:hungerrate;0.9"] = 16,},
				[3] = {raincoat = 1,umbrella = 1,[":func:hungerrate;0.8"] = 16,},
				[4] = {raincoat = 1,umbrella = 1,[":func:hungerrate;0.7"] = 16,},
				[5] = {raincoat = 1,umbrella = 1,[":func:hungerrate;0.6"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local minutes = scaled_quest.amount/60 or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", minutes)
				scaled_quest.description = GetQuestString(scaled_quest.name, "DESCRIPTION", minutes)
			end,
		},
	}),
	--40
	CreateQuest({
		name = "Off to sea",
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
		difficulty = 2,
		tex = "boat_item.tex",
		hovertext = GetQuestString("Off to sea","HOVER"),
	}),
	--41
	CreateQuest({
		name = "Hidden Treasures",
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
		difficulty = 3,
		tex = "sunkenchest.tex",
	}),
	--42
	CreateQuest({
		name = "Off to donate blood",
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
		anim_prefab = "mosquito",
	}),
	--43
	CreateQuest({
		name = "The Lonely Woven Shadow",
		description = GetQuestString("The Lonely Woven Shadow","DESCRIPTION"),
		amount = 1,
		rewards = {nightmarefuel = 10,boards = 3},
		points = 150,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["protect x from y creatures z times"](inst, amount, 5, 1, 15, 1, math.random() < 0.5 and "stalker_minion1" or "stalker_minion2", quest_name, 90, 180)
		end,
		difficulty = 1,
		tex = "fight.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Lonely Woven Shadow","HOVER"),
	}),
	--44
	CreateQuest({
		name = "The Eye of Cthulhu",
		victim = "eyeofterror",
		description = GetQuestString("The Eye of Cthulhu","DESCRIPTION"),
		amount = 1,
		rewards = {boards = 10,nitre = 10},
		points = 650,
		difficulty = 4,
	}),
	--45
	CreateQuest({
		name = "The Biggest Veggy",
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
		difficulty = 3,
		tex = "eggplant.tex",
		hovertext = GetQuestString("The Biggest Veggy","HOVER"),
		scalable = {
			custom_vars_fn = function(inst)
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
					--if data.victim and inv_atlas[data.victim] then
					--	quest.atlas = "images/inventoryimages2.xml"
					--end
					quest.scale = {veggy} --used to add strings to the title
				end
				return quest
			end,
		},
	}),
	--46
	CreateQuest({
		name = "A Sailor's Life",
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
	}),
	--47
	CreateQuest({
		name = "Survival: Famine",
		description = GetQuestString("Survival: Famine","DESCRIPTION"),
		amount = 50,
		rewards = {bonestew = 3},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"hunger",quest_name)
		end,
		difficulty = 1,
		tex = "hunger.tex",
		atlas = "images/victims.xml",
		scalable = {
			amount = {50,100,200,400,750},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {bonestew = 3,[":func:hunger;10"] = 16,},
				[3] = {bonestew = 3,[":func:hunger;25"] = 16,},
				[4] = {bonestew = 3,[":func:hunger;50"] = 16,},
				[5] = {bonestew = 3,[":func:hunger;100"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local hunger = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", hunger)
			end,
		},
	}),
	--48
	CreateQuest({
		name = "Survival: Heart attack",
		description = GetQuestString("Survival: Heart attack","DESCRIPTION"),
		amount = 50,
		rewards = {icecream = 3},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"terrorbeak",quest_name)
		end,
		difficulty = 1,
		tex = "terrorbeak.tex",
		atlas = "images/victims.xml",
		anim_prefab = "terrorbeak",
		scalable = {
			amount = {50,100,200,400,750},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {icecream = 3,[":func:sanity;10"] = 16,},
				[3] = {icecream = 3,[":func:sanity;25"] = 16,},
				[4] = {icecream = 3,[":func:sanity;50"] = 16,},
				[5] = {icecream = 3,[":func:sanity;100"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local sanity = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", sanity)
			end,
		},
	}),
	--49
	CreateQuest({
		name = "Survival: Frost Shock",
		description = GetQuestString("Survival: Frost Shock","DESCRIPTION"),
		amount = 50,
		rewards = {dragonchilisalad = 3},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"cold",quest_name)
		end,
		difficulty = 1,
		tex = "winterinsulation.tex",
		atlas = "images/victims.xml",
		scalable = {
			amount = {50,100,200,400,750},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {dragonchilisalad = 3,[":func:winterinsulation;40"] = 16,},
				[3] = {dragonchilisalad = 3,[":func:winterinsulation;80"] = 16,},
				[4] = {dragonchilisalad = 3,[":func:winterinsulation;120"] = 16,},
				[5] = {dragonchilisalad = 3,[":func:winterinsulation;160"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local insulation = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", insulation)
			end,
		},
	}),
	--50
	CreateQuest({
		name = "Survival: Heat exhaustion",
		description = GetQuestString("Survival: Heat exhaustion","DESCRIPTION"),
		amount = 50,
		rewards = {gazpacho = 3},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["damage x amount of life with y"](inst,amount,"hot",quest_name)
		end,
		difficulty = 1,
		tex = "summerinsulation.tex",
		atlas = "images/victims.xml",
		scalable = {
			amount = {50,100,200,400,750},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {gazpacho = 3,[":func:summerinsulation;40"] = 16,},
				[3] = {gazpacho = 3,[":func:summerinsulation;80"] = 16,},
				[4] = {gazpacho = 3,[":func:summerinsulation;120"] = 16,},
				[5] = {gazpacho = 3,[":func:summerinsulation;160"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local insulation = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", insulation)
			end,
		},
	}),
	--51
	CreateQuest({
		name = "Survival: Life-threatening",
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
		difficulty = 1,
		tex = "health.tex",
		atlas = "images/victims.xml",
		scalable = {
			amount = {10,25,50,100,200},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {waffles = 3,[":func:health;10"] = 16,},
				[3] = {waffles = 3,[":func:health;25"] = 16,},
				[4] = {waffles = 3,[":func:health;50"] = 16,},
				[5] = {waffles = 3,[":func:health;100"] = 16,},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local health = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", health)
			end,
		},
	}),
	--52
	CreateQuest({
		name = "The True Enemy",
		victim = "glommer",
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
		custom_rewards_paths = {
			["Next Night"] = {
				"celestial.tex",
				"images/victims.xml",
			},
		},
		quest_line = true,
	}),
	--53
	CreateQuest({
		name = "Treebeard's end",
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
		difficulty = 2,
		tex = "leif.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Treebeard's end","HOVER"),
		anim_prefab = "leif",
	}),
	--54
	CreateQuest({
		name = "Feeding Time",
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
		difficulty = 1,
		tex = "hunger.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Feeding Time","HOVER"),
	}),
	--55
	CreateQuest({
		name = "Catch the stick",
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
							if data.target and data.target:HasTag("hound") then
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
		difficulty = 2,
		tex = "boomerang.tex",
	}),
	--56
	CreateQuest({
		name = "Front Pigs",
		description = GetQuestString("Front Pigs","DESCRIPTION"),
		amount = 5,
		rewards = {footballhat = 1,hambat = 1,[":func:health;25"] = 8},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["acquire x followers that are y"](inst,amount,"pigman",quest_name)
		end,
		difficulty = 2,
		tex = "pigman.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigman",
	}),
	--57
	CreateQuest({
		name = "Detective Work",
		description = GetQuestString("Detective Work","DESCRIPTION"),
		amount = 3,
		rewards = {steelwool = 2,ice = 20},
		points = 150,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["hunt x y times"](inst,amount,nil,quest_name)
		end,
		difficulty = 1,
		tex = "koalefant_summer.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Detective Work","HOVER"),
		anim_prefab = "animal_track",
	}),
	--58
	CreateQuest({
		name = "Twins Of Destruction",
		victim = "",
		counter_name = GetQuestString("Twins Of Destruction","COUNTER"),
		description = GetQuestString("Twins Of Destruction","DESCRIPTION"),
		amount = 2,
		rewards = {gears = 10, transistor = 10,orangegem = 2,milkywhites = 5},
		points = 1750,
		start_fn = function(inst,amount,quest_name)
			local creatures = {twinofterror1 = 1, twinofterror2 = 1}
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill different creatures x y times"](inst, amount, quest_name, creatures)
		end,
		difficulty = 5,
		tex = "twinofterror1.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Twins Of Destruction","HOVER"),
		anim_prefab = "twinofterror1",
	}),
	--59
	CreateQuest({
		name = "The Biggest Frog",
		victim = "toadstool",
		description = GetQuestString("The Biggest Frog","DESCRIPTION"),
		amount = 1,
		rewards = {shroom_skin = 3,sleepbomb = 2,blue_mushroomhat = 1},
		points = 2500,
		difficulty = 5,
	}),
	--60
	CreateQuest({
		name = "Ho Ho Ho",
		victim = "klaus",
		description = GetQuestString("Ho Ho Ho","DESCRIPTION"),
		amount = 1,
		rewards = {giftwrap = 20,[":func:krampus_sack"] = 33,mandrake = 2},
		points = 2000,
		difficulty = 5,
	}),
	--61
	CreateQuest({
		name = "The Impregnable Fortress",
		victim = "crabking",
		description = GetQuestString("The Impregnable Fortress","DESCRIPTION"),
		amount = 1,
		rewards = {yellowgem = 5,greengem = 5,orangegem = 5,trident = 1},
		points = 2200,
		difficulty = 5,
	}),
	--62
	CreateQuest({
		name = "The Master Chef",
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
		difficulty = 2,
		tex = "lobsterdinner.tex",
	}),
	--63
	CreateQuest({
		name = "Destroyer of Ancient Works",
		description = GetQuestString("Destroyer of Ancient Works","DESCRIPTION"),
		amount = 3,
		rewards = {[":func:speed;1.3"] = 16,thulecite = 8,[":func:nightvision;1"] = 8},
		points = 1250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["finish work type z for x amount of y"](inst,ACTIONS.HAMMER,"ancient_altar_broken",amount,quest_name)
		end,
		difficulty = 4,
		tex = "ancient.tex",
		atlas = "images/victims.xml",
	}),
	--64
	CreateQuest({
		name = "The Goodest Boy",
		amount = 2,
		rewards = {[":func:range;1"] = 16,ruins_bat = 2},
		points = 1250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deploy x y times"](inst,amount,"eyeturret_item",quest_name)
		end,
		difficulty = 4,
		tex = "eyeturret_item.tex",
		atlas = "images/inventoryimages1.xml",
	}),
	--65
	CreateQuest({
		name = "The RPG Expert",
		amount = 3,
		rewards = {[":func:health;10"] = 8,[":func:sanity;10"] = 8,[":func:hunger;10"] = 8,[":func:damagereduction;0.9"] = 8,[":func:damage;2"] = 8},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["gain x levels"](inst,amount,quest_name)
		end,
		difficulty = 1,
		tex = "arrow_3.tex",
		atlas = "images/victims.xml",
		scalable = {
			amount = {3,5,10,15,20},
			points = {125,250,500,750,1250},
			rewards = {
				[2] = {[":func:health;10"] = 16,[":func:sanity;10"] = 16,[":func:hunger;10"] = 16,[":func:damagereduction;0.9"] = 16,[":func:damage;2"] = 16},
				[3] = {[":func:health;25"] = 16,[":func:sanity;25"] = 16,[":func:hunger;25"] = 16,[":func:damagereduction;0.8"] = 16,[":func:damage;5"] = 16},
				[4] = {[":func:health;50"] = 16,[":func:sanity;50"] = 16,[":func:hunger;50"] = 16,[":func:damagereduction;0.7"] = 16,[":func:damage;10"] = 16},
				[5] = {[":func:health;100"] = 16,[":func:sanity;100"] = 16,[":func:hunger;100"] = 16,[":func:damagereduction;0.6"] = 16,[":func:damage;20"] = 16},
			},
			post_fn = function(inst, scaled_quest, quest_data)
				local level = scaled_quest.amount or 1
				scaled_quest.hovertext = GetQuestString(scaled_quest.name, "HOVER", level)
				scaled_quest.description = GetQuestString(scaled_quest.name, "DESCRIPTION", level)
			end,
		},
	}),
	--66
	CreateQuest({
		name = "The Questing Adventurer",
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
	}),
	--67
	CreateQuest({
		name = "Night Angler",
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
		difficulty = 2,
		tex = "oceanfishingrod.tex",
		atlas = "images/inventoryimages2.xml",
	}),
	--68 nearly nice
	CreateQuest({
		name = "Kingfisher",
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
		difficulty = 2,
		tex = "tallbird.tex",
		atlas = "images/victims.xml",
		anim_prefab = "tallbird",
	}),
	--69 nice
	CreateQuest({
		name = "The Mad Hatter",
		description = GetQuestString("The Mad Hatter","DESCRIPTION"),
		amount = 3,
		rewards = {eyebrellahat = 1, [":func:winterinsulation;120"] = 16, [":func:summerinsulation;120"] = 16,},
		points = 650,
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
		difficulty = 4,
		tex = "dress.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Mad Hatter","HOVER"),
	}),
	--70 not nice anymore :(
	CreateQuest({
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
		custom_rewards_paths = {
			["Transform Chester to"] = {
				"chester_eyebone_snow.tex",
				"images/inventoryimages1.xml",
			},
		},
		unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
		quest_line = true,
		anim_prefab = "chester",
	}),
	--71
	CreateQuest({
		name = "Shadow World Manipulation",
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
		hovertext = GetQuestString("Shadow World Manipulation","HOVER"),
		unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
		quest_line = true,
	}),
	--72
	CreateQuest({
		name = "Friends in the Shadow Realm",
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
					StopTask(inst, "sanity_check_task")
				else
					inst:DoTaskInTime(1,CheckSanity)
				end
			end
			StopTask(inst, "sanity_check_task")
			inst.sanity_check_task = inst:DoTaskInTime(1,CheckSanity)
			local function OnForfeitedQuest(inst)
				StopTask(inst, "sanity_check_task")
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
	}),
	--73
	CreateQuest({
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
		hovertext = GetQuestString("Your True Friends","HOVER"),
		unlisted = true, --this is part of a quest line, we don't want it to be gotten otherwise
		quest_line = true,
		custom_rewards_paths = {
			["Two Friends"] = {
				"avatar_random.tex",
				"images/avatars.xml",
			},
		},
	}),
	--74
	CreateQuest({
		name = "Spiderman",
		description = GetQuestString("Spiderman","DESCRIPTION"),
		amount = 3,
		rewards = {spiderhat = 1,healingsalve = 10},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y with follower z"](inst,amount,"pigman",{spider = true,spider_warrior = true,spider_hider = true,spider_spitter = true,spider_dropper = true,spider_moon = true,spider_healer = true,spider_water = true},quest_name)
		end,
		difficulty = 2,
		tex = "pigman.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigman",
	}),
	--75
	CreateQuest({
		name = "A Bunnys Job",
		description = GetQuestString("A Bunnys Job","DESCRIPTION"),
		amount = 5,
		rewards = {manrabbit_tail = 5,carrot = 10},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y with follower z"](inst,amount,"bat",{bunnyman = true},quest_name)
		end,
		difficulty = 2,
		tex = "bat.tex",
		atlas = "images/victims.xml",
		anim_prefab = "bat",
	}),
	--76
	CreateQuest({
		name = "Your Own Fault",
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
		difficulty = 2,
		tex = "walrus.tex",
		atlas = "images/victims.xml",
		anim_prefab = "walrus",
	}),
	--77
	CreateQuest({
		name = "Death By Self",
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
		difficulty = 3,
		tex = "pigman.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigman",
	}),
	--78
	CreateQuest({
		name = "The Inner Monster",
		amount = 3,
		rewards = {moonrocknugget = 5,pig_token = 1,pigskin = 5,},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			local function IsMonsterMeat(player, data)
				return data.food.components.edible and data.food.components.edible.foodtype == FOODTYPE.MEAT and data.food.components.edible:GetHealth(data.target) < 0
			end
			local function OnEatMonsterMeat(player, data, UpdateQuest)
				data.target:DoTaskInTime(1,function(pig)
					if pig.components.werebeast and pig.components.werebeast:IsInWereState() then
						UpdateQuest()
					end
				end)
			end
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["feed x y times"](inst,amount,quest_name,"pigman",nil, IsMonsterMeat, OnEatMonsterMeat)
		end,
		difficulty = 2,
		tex = "pigman.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigman",
	}),
	--79
	CreateQuest({
		name = "The Boxer",
		amount = 150,
		rewards = {[":func:damage;10"] = 8},
		points = 275,
		start_fn = function(inst,amount,quest_name)
			local current_amount = GetCurrentAmount(inst,quest_name)
			local function OnDamageDone(inst,data)
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
		difficulty = 2,
		tex = "fight.tex",
		atlas = "images/victims.xml",
	}),
	--80
	CreateQuest({
		name = "The Dish for the Pig",
		description = GetQuestString("The Dish for the Pig","DESCRIPTION"),
		amount = 1,
		rewards = {turkeydinner = 3,[":func:hungerrate;0.8"] = 16,},
		points = 300,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["feed x y times"](inst,amount,quest_name,"pigman","lobsterdinner")
		end,
		difficulty = 2,
		tex = "lobsterdinner.tex",
		hovertext = GetQuestString("The Dish for the Pig","HOVER"),
	}),
	--81
	CreateQuest({
		name = "A Useful Companion",
		amount = 60,
		rewards = {horn = 2,beefalowool = 10,},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TheWorld.components.quest_loadpostpass.quest_lines[quest_name] = true
			local current = GetCurrentAmount(inst,quest_name)
			local function StopTaskInner(inst)
				StopTask(inst, "check_riding_task")
			end
			local function OnMounted(inst,data)
				StopTaskInner(inst)
				inst.check_riding_task = inst:DoPeriodicTask(1,function()
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						inst:RemoveEventCallback("mounted",OnMounted)
						inst:RemoveEventCallback("dismounted",StopTaskInner)
					end
				end)
			end
			if inst.components.rider and inst.components.rider:IsRiding() then
				OnMounted(inst)
			end
			inst:ListenForEvent("mounted",OnMounted)
			inst:ListenForEvent("dismounted",StopTaskInner)
			local function OnForfeitedQuest(inst)
				inst:RemoveEventCallback("mounted",OnMounted)
				inst:RemoveEventCallback("dismounted",StopTaskInner)
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
		quest_line = true,
		anim_prefab = "beefalo",
	}),
	--82
	CreateQuest({
		name = "Marble Trees?!",
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
		quest_line = true,
		unlisted = true,
	}),
	--83
	CreateQuest({
		name = "The Stonemason",
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
		quest_line = true,
		unlisted = true,
	}),
	--84
	CreateQuest({
		name = "The Shadow Plague",
		amount = 30,
		rewards = {leafymeatsouffle = 5,[":func:sanityaura;10"] = 16,[":func:healthrate;2"] = 16,},
		points = 875,
		start_fn = function(inst,amount,quest_name)
			local current = GetCurrentAmount(inst,quest_name)
			local function OnKilled(inst,data)
				if data and data.victim then
					if (data.victim:HasTag("shadowcreature") or data.victim:HasTag("nightmarecreature")) then
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
		quest_line = true,
		unlisted = true,
		anim_prefab = "terrorbeak",
	}),
	--85
	CreateQuest({
		name = "The Pieces of Downfall",
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
		anim_prefab = "shadow_rook",
	}),
	--86
	CreateQuest({
		name = "The Ancient Craft",
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
		custom_rewards_paths = {
			["rock_avocado_fruit"] = {
				"rock_avocado_fruit_rockhard.tex",
			},
		},
	}),
	--87
	CreateQuest({
		name = "The Shadow Slayer",
		description = GetQuestString("The Shadow Slayer","DESCRIPTION"),
		amount = 10,
		rewards = {glasscutter = 2,moonrocknugget = 10,thulecite = 2},
		points = 550,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst, amount, {crawlingnightmare = true,nightmarebeak = true,}, quest_name, function() return TheWorld.state.isnightmarewild end)
		end,
		difficulty = 3,
		tex = "crawlinghorror.tex",
		atlas = "images/victims.xml",
		anim_prefab = "crawlinghorror",
	}),
	--88
	CreateQuest({
		name = "Suicidal Thoughts",
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
		difficulty = 4,
		tex = "gunpowder.tex",
		hovertext = GetQuestString("Suicidal Thoughts","HOVER"),
	}),
	--89
	CreateQuest({
		name = "The Untalented Chef",
		description = GetQuestString("The Untalented Chef","DESCRIPTION"),
		amount = 3,
		rewards = {lobsterdinner = 2},
		points = 130,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["harvest x times y food with z ingredients from cookpot"](inst,amount,"wetgoop",nil,quest_name)
		end,
		difficulty = 1,
		tex = "wetgoop.tex",
	}),
	--90
	CreateQuest({
		name = "The Flower Lover",
		amount = 20,
		rewards = {petals = 20,butter  = 1},
		points = 150,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deploy x y times"](inst,amount,"butterfly",quest_name)
		end,
		difficulty = 1,
		tex = "petals.tex",
	}),
	--91
	CreateQuest({
		name = "The Fish Fisher",
		description = GetQuestString("The Fish Fisher","DESCRIPTION"),
		amount = 2,
		rewards = {messagebottleempty = 3,fig = 20},
		points = 485,
		start_fn = function(inst,amount,quest_name)
			local data = inst.components.quest_component.quests[quest_name] and inst.components.quest_component.quests[quest_name].custom_vars
			local fish = data and data.fish or "oceanfish_small_1"
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["catch x amount of y fish"](inst,amount,fish,quest_name)
		end,
		difficulty = 3,
		tex = "oceanfish_small_1.tex",
		hovertext = GetQuestString("The Fish Fisher","HOVER"),
		scalable = {
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
	}),
	--92
	CreateQuest({
		name = "The Tormented Dust Moth",
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
		anim_prefab = "dustmoth",
	}),
	--93
	CreateQuest({
		name = "The Sleeping Beauty",
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
						StopTask(inst, quest_name)
					end
				else
					StopTask(inst, quest_name)
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
				StopTask(inst, quest_name)
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
		quest_line = true,
	}),
	--94
	CreateQuest({
		name = "The Ocean Chose Me!",
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
		anim_prefab = "waterplant",
		custom_rewards_paths = {
			singingshell_octave3 = {
				"singingshell_octave3_3.tex",
			},
			singingshell_octave4 = {
				"singingshell_octave4_3.tex",
			},
			singingshell_octave5 = {
				"singingshell_octave5_3.tex",
			},
		},
		quest_line = true,
		unlisted = true,
	}),
	--95
	CreateQuest({
		name = "The Seven Dwarfs",
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
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["trade x amount of item y with pigking"](inst, amount, {"trinket_4"}, quest_name, RemoveDwarfDropper)

		end,
		onfinished = function(inst)
			inst:DoTaskInTime(0,function()
				inst.components.quest_component:AddQuest("The Cold Never Bothered Me Anyway!")
			end)
		end,
		difficulty = 3,
		tex = "trinket_4.tex",
		hovertext = GetQuestString("The Seven Dwarfs","HOVER"),
		quest_line = true,
		unlisted = true,
	}),
	--96
	CreateQuest({
		name = "The Cold Never Bothered Me Anyway!",
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
		quest_line = true,
		unlisted = true,
	}),
	--97
	CreateQuest({
		name = "Kiss The Frog!",
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
		difficulty = 5,
		tex = "frog.tex",
		atlas = "images/victims.xml",
		quest_line = true,
		unlisted = true,
		anim_prefab = "frog",
	}),
	--98
	CreateQuest({
		name = "The Gravedigger",
		amount = 3,
		rewards = {shovel_lunarplant = 1,[":func:worker;1.4"] = 16,},
		points = 550,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do work type z for x amount of y"](inst,ACTIONS.DIG,"mound",amount,quest_name)
		end,
		difficulty = 2,
		tex = "shovel.tex",
	}),
	--99
	CreateQuest({
		name = "I've got 99 problems but starving ain't one!",
		amount = 3000,
		rewards = {armorslurper = 1,[":func:hunger;100"] = 16,[":func:hungerrate;0.7"] = 16,},
		points = 1000,
		start_fn = function(inst,amount,quest_name)
			local calories_eaten = GetCurrentAmount(inst,quest_name)
			local OnStarve
			local function Food(_player, data)
				if data and data.food then
					local food = data.food
					local base_mult = _player.components.foodmemory ~= nil and _player.components.foodmemory:GetFoodMultiplier(food.prefab) or 1
					local stack_mult = _player.components.eater.eatwholestack and food.components.stackable ~= nil and food.components.stackable:StackSize() or 1
					local calories = food.components.edible:GetHunger(_player) * base_mult * _player.components.eater.hungerabsorption * stack_mult
					calories_eaten = calories_eaten + calories
					_player:PushEvent("quest_update",{ quest = quest_name, amount = calories})
					if calories_eaten >= amount then
						_player:RemoveEventCallback("oneat",Food)
						_player:RemoveEventCallback("startstarving", OnStarve)
					end
				end
			end
			OnStarve = function(inst)
				inst.components.quest_component:RemoveQuest(quest_name)
				inst:RemoveEventCallback("oneat",Food)
				inst:RemoveEventCallback("startstarving", OnStarve)
			end
			inst:ListenForEvent("oneat",Food)
			inst:ListenForEvent("startstarving", OnStarve)
			local function OnForfeitedQuest(_player)
				_player:RemoveEventCallback("oneat",Food)
				_player:RemoveEventCallback("startstarving", OnStarve)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 4,
		tex = "meatballs.tex",
	}),
	--100
	CreateQuest({
		name = "The Untouchable",
		amount = 900,
		rewards = {[":func:dodge;10"] = 20,},
		points = 600,
		start_fn = function(inst,amount,quest_name)
			local current = GetCurrentAmount(inst,quest_name)
			local OnAttacked
			local function Stop()
				inst:RemoveEventCallback("attacked",OnAttacked)
				StopTask(inst, quest_name.."_task")
			end
			OnAttacked = function(inst, data)
				if data and data.damageresolved and data.damageresolved > 0 then
					current = 0
					inst:PushEvent("quest_update",{quest = quest_name,reset = true})
				end
			end
			inst:ListenForEvent("attacked",OnAttacked)
			local function OnForfeitedQuest(inst)
				Stop()
			end
			inst[quest_name.."_task"] = inst:DoPeriodicTask(1, function()
				if not inst:HasTag("playerghost") then
					current = current + 1
					inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if current >= amount then
						Stop()
					end
				end
			end)
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 3,
		tex = "dodge.tex",
		atlas = "images/victims.xml",
	}),
	--101
	CreateQuest({
		name = "The Hunted Glommer",
		description = GetQuestString("The Hunted Glommer","DESCRIPTION"),
		amount = 1,
		rewards = {nightmarefuel = 20,cutstone = 5,},
		points = 550,
		start_fn = function(player,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["protect x from y creatures z times"](player,amount,5,3,10,2,"glommer",quest_name)
		end,
		difficulty = 2,
		tex = "glommer.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Hunted Glommer","HOVER"),
		anim_prefab  = "glommer"
	}),
	--102
	CreateQuest({
		name = "The Stray Hutch",
		description = GetQuestString("The Stray Hutch","DESCRIPTION"),
		amount = 1,
		rewards = {horrorfuel = 5,rope = 9,},
		points = 550,
		start_fn = function(player,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["protect x from y creatures z times"](player,amount,7,3,10,3,"hutch",quest_name)
		end,
		difficulty = 2,
		tex = "hutch.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("The Stray Hutch","HOVER"),
		anim_prefab = "hutch",
	}),
	--103
	CreateQuest({
		name = "The Healer",
		amount = 150,
		rewards = {reviver = 1, healingsalve = 2},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["heal x amount of life with y"](inst,amount,nil,quest_name)
		end,
		difficulty = 2,
		tex = "healingsalve.tex",
	}),
	--104
	CreateQuest({
		name = "The Attacker",
		amount = 1800,
		rewards = {voidcloth_scythe = 1, [":func:planardamage;10"] = 8},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deal x amount of damage in time y with weapon z"](inst,amount,nil,30,quest_name)
		end,
		difficulty = 3,
		tex = "damage.tex",
		atlas = "images/victims.xml",
	}),
	--105
	CreateQuest({
		name = "The Defender",
		amount = 1200,
		rewards = {armor_voidcloth = 1, [":func:planardefense;10"] = 8},
		points = 125,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["defend x amount of damage"](inst,amount,quest_name)
		end,
		difficulty = 3,
		tex = "damagereduction.tex",
		atlas = "images/victims.xml",
	}),
	--106
	CreateQuest({
		name = "Axe-swinging Competition",
		amount = 20,
		rewards = {moonglassaxe = 1, [":func:worker;1.6"] = 24},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			local chopped = GetCurrentAmount(inst,quest_name)
			local function ListenForEventFinishedWork(_player, data)
				local action = data.action
				--devprint("ListenForEventFinishedWork chop", _player, data.target, action, action and action.id)
				if action == ACTIONS.CHOP then
					if chopped == 0 then
						inst:PushEvent(quest_name)
					end
					chopped = chopped + 1
					_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
					if chopped >= amount then
						_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
					end
				end
			end
			inst:ListenForEvent("finishedwork",ListenForEventFinishedWork)
			local function OnForfeitedQuest(_player)
				_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x y times in z days"](inst,amount,3,quest_name,quest_name)
		end,
		difficulty = 2,
		tex = "axe.tex",
	}),
	--107
	CreateQuest({
		name = "Pickaxe-swinging Competition",
		amount = 10,
		rewards = {pickaxe_lunarplant = 1, [":func:worker;1.6"] = 24},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			local chopped = GetCurrentAmount(inst,quest_name)
			local function ListenForEventFinishedWork(_player, data)
				local action = data.action
				--devprint("ListenForEventFinishedWork mine", _player, data.target, action, action and action.id)
				if action == ACTIONS.MINE then
					if chopped == 0 then
						inst:PushEvent(quest_name)
					end
					chopped = chopped + 1
					_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
					if chopped >= amount then
						_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
					end
				end
			end
			inst:ListenForEvent("finishedwork",ListenForEventFinishedWork)
			local function OnForfeitedQuest(_player)
				_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x y times in z days"](inst,amount,3,quest_name,quest_name)
		end,
		difficulty = 2,
		tex = "pickaxe.tex",
	}),
	--108
	CreateQuest({
		name = "Shovel-digging Competition",
		amount = 15,
		rewards = {shovel_lunarplant = 1, [":func:worker;1.6"] = 24},
		points = 250,
		start_fn = function(inst,amount,quest_name)
			local chopped = GetCurrentAmount(inst,quest_name)
			local function ListenForEventFinishedWork(_player, data)
				local action = data.action
				--devprint("ListenForEventFinishedWork shovel", _player, data.target, action, action and action.id)
				if action == ACTIONS.DIG then
					if chopped == 0 then
						inst:PushEvent(quest_name)
					end
					chopped = chopped + 1
					_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
					if chopped >= amount then
						_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
					end
				end
			end
			inst:ListenForEvent("finishedwork",ListenForEventFinishedWork)
			local function OnForfeitedQuest(_player)
				_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x y times in z days"](inst,amount,3,quest_name,quest_name)
		end,
		difficulty = 2,
		tex = "shovel.tex",
	}),
	--109
	CreateQuest({
		name = "The Fatal Rose",
		description = GetQuestString("The Fatal Rose","DESCRIPTION"),
		amount = 1,
		rewards = {[":func:escapedeath;1"] = 1, [":func:health;50"] = 30, lifeinjector = 5},
		points = 1000,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["die x times from y by z"](inst,amount,"flower",nil,quest_name)
		end,
		difficulty = 4,
		tex = "petals.tex",
		hovertext = GetQuestString("The Fatal Rose","HOVER"),
	}),
	--110
	CreateQuest({
		name = "The Bird Predator",
		amount = 10,
		rewards = {[":func:range;0.5"] = 16, featherhat = 1, trailmix = 3},
		points = 1000,
		start_fn = function(inst,amount,quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst,amount,"robin",quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x y times in z days"](inst,amount,8,nil,quest_name)
		end,
		difficulty = 2,
		tex = "robin.tex",
	}),
	--111
	CreateQuest({
		name = "A Werepigs Worst Nightmare",
		victim = "daywalker",
		amount = 1,
		rewards = {[":func:planardamage;25"] = 16, horrorfuel = 5, dreadstone = 10},
		points = 1750,
		start_fn = function(inst,amount,quest_name)
			local function OnAttackDaywalker(inst, data)
				if data and data.target and data.target.prefab == "daywalker" then
					if data.target.defeated then
						inst:PushEvent("quest_update",{ quest = quest_name, amount = 1, friendly_goal = true,})
						inst:RemoveEventCallback("onattackother",OnAttackDaywalker)
					end
				end
			end
			inst:ListenForEvent("onattackother", OnAttackDaywalker)
			local function OnForfeitedQuest(_player)
				_player:RemoveEventCallback("onattackother",OnAttackDaywalker)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 5,
	}),
	--112
	CreateQuest({
		name = "The Nightmare Trio",
		description = GetQuestString("The Nightmare Trio","DESCRIPTION"),
		amount = 3,
		rewards = {[":func:planardefense;25"] = 8, voidcloth_scythe = 1, voidcloth_umbrella = 1},
		points = 1200,
		start_fn = function(inst,amount,quest_name)
			local creatures = {shadowthrall_wings = 1, shadowthrall_horns = 1, shadowthrall_hands = 1}
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill different creatures x y times"](inst,3,quest_name,creatures)
		end,
		difficulty = 4,
		tex = "icon_shadowaligned.tex",
		atlas = "images/scrapbook_icons1.xml",
		hovertext = GetQuestString("The Nightmare Trio", "HOVER"),
	}),
	--113
	CreateQuest({
		name = "The Acid Bath",
		amount = 300,
		rewards = {[":func:planardefense;25"] = 8, voidcloth_scythe = 1, voidcloth_umbrella = 1},
		points = 1200,
		start_fn = function(inst,amount,quest_name)
			local bathed = GetCurrentAmount(inst,quest_name)
			local function OnAcidRain(inst, isacidrain)
				StopTask(inst, quest_name.."_task")
				if isacidrain then
					inst[quest_name.."_task"] = inst:DoPeriodicTask(1, function()
						if not inst.components.inventory:EquipHasTag("acidrainimmune") then
							inst:PushEvent("quest_update",{ quest = quest_name, amount = 1,})
							if bathed >= amount then
								inst:StopWatchingWorldState("isacidraining",OnAcidRain)
								StopTask(inst, quest_name.."_task")
							end
						end
					end)
				end
			end
			inst:WatchWorldState("isacidraining", OnAcidRain)
			OnAcidRain(inst, TheWorld.state.isacidraining)
			local function OnForfeitedQuest(_player)
				_player:StopWatchingWorldState("isacidraining",OnAcidRain)
				StopTask(inst, quest_name.."_task")
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 3,
		tex = "shadowrift_portal.tex",
		atlas = "images/victims.xml",
		--anim_prefab = "shadowrift_portal",
	}),
	--114
	CreateQuest({
		name = "A Great Ryft",
		amount = 10,
		rewards = {[":func:dodge;20"] = 8, bomb_lunarplant = 3},
		points = 300,
		start_fn = function(inst,amount,quest_name)
			local workables = {lunarrift_crystal_big = true, lunarrift_crystal_small = true}
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["finish work type z for x amount of y"](inst,ACTIONS.MINE,workables,amount,quest_name)
		end,
		difficulty = 2,
		tex = "purebrilliance.tex",
	}),
	--115
	CreateQuest({
		name = "A Grazers Nightmare",
		amount = 1000,
		rewards = {[":func:planardamage;10"] = 8, lunarplant_kit = 1, bomb_lunarplant = 1},
		points = 300,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deal x amount of damage"](inst,amount,nil,quest_name,"lunar_grazer")
		end,
		difficulty = 2,
		tex = "lunar_grazer.tex",
		atlas = "images/victims.xml",
		anim_prefab = "lunar_grazer",
	}),
	--116
	CreateQuest({
		name = "Closest To Oneself",
		amount = 10,
		rewards = {[":func:speed;1.1"] = 8, sewing_kit = 1, carnival_vest_c = 1},
		points = 250,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,nil,"CHARACTER",quest_name)
		end,
		difficulty = 2,
		tex = "tools.tex",
		atlas = "images/victims.xml",
	}),
	--117
	CreateQuest({
		name = "Kill The Lord",
		victim = "lordfruitfly",
		description = GetQuestString("Kill The Lord","DESCRIPTION"),
		amount = 1,
		rewards = {garlic_seeds = 5, pepper_seeds = 5, onion_seeds = 5, soil_amender_fermented = 1},
		points = 500,
		difficulty = 3,
	}),
	--118
	CreateQuest({
		name = "Kill The Innocent",
		amount = 3,
		rewards = {oceanfishingbobber_goose = 1, staff_tornado = 1, turkeydinner = 3},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			local function CheckIfInnocent(target)
				return not target.mother_dead
			end
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst,amount,"mossling",quest_name,CheckIfInnocent)
		end,
		difficulty = 3,
		tex = "mossling.tex",
		atlas = "images/victims.xml",
		anim_prefab = "mossling",
	}),
	--119
	CreateQuest({
		name = "Defeating Rocky",
		victim = "rocky",
		amount = 1,
		rewards = {gunpowder = 10, [":func:damage;10"] = 16,},
		points = 350,
		difficulty = 2,
	}),
	--120
	CreateQuest({
		name = "I'm The Pirate Now!",
		victim = "prime_mate",
		amount = 1,
		rewards = {cave_banana = 10, stash_map = 1, dock_kit = 12},
		points = 350,
		difficulty = 2,
	}),
	--121
	CreateQuest({
		name = "Cannon Fodder",
		amount = 5,
		rewards = {polly_rogershat = 1, dock_kit = 12},
		points = 450,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deploy x y times"](inst,amount,"boat_cannon_kit",quest_name)
		end,
		difficulty = 3,
		tex = "boat_cannon_kit.tex",
	}),
	--122
	CreateQuest({
		name = "Let's Get The Party Started!",
		amount = 5,
		rewards = {[":func:nightvision;1"] = 16, leafymeatburger = 5},
		points = 400,
		start_fn = function(inst, amount, quest_name)
			local cocktails = {bananajuice = true, vegstinger = true, frozenbananadaiquiri = true, }
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst, cocktails, amount, quest_name)
		end,
		difficulty = 3,
		tex = "frozenbananadaiquiri.tex",
	}),
	--123
	CreateQuest({
		name = "Return To Monke",
		description = GetQuestString("Return To Monke", "DESCRIPTION"),
		amount = 1,
		rewards = {[":func:planardamage;10"] = 8, [":func:planardefense;10"] = 8, cave_banana = 10},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			local old_ChangeToMonkey = inst.ChangeToMonkey
			inst.ChangeToMonkey = function(inst, ...)
				inst:PushEvent("quest_update",{quest = quest_name, amount = 1})
				old_ChangeToMonkey(inst, ...)
			end
			local function OnForfeitedQuest()
				inst.ChangeToMonkey = old_ChangeToMonkey
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 3,
		tex = "wonkey.tex",
		atlas = "images/victims.xml",
		hovertext = GetQuestString("Return To Monke", "HOVER"),
		--anim_prefab = "wonkey",
	}),
	--124
	CreateQuest({
		name = "The Punching Bag",
		amount = 50,
		rewards = {[":func:damage;5"] = 16, },
		points = 130,
		start_fn = function(inst, amount, quest_name)
			local targets = {punchingbag = true, punchingbag_shadow = true, punchingbag_lunar = true}
			local current_amount = GetCurrentAmount(inst,quest_name)
			local function OnDamageDone(_,data)
				amount = amount or 1
				if data then
					if data.damageresolved > current_amount then
							if data.target and targets[data.target.prefab] then
								current_amount = data.damageresolved
								inst:PushEvent("quest_update",{quest = quest_name,set_amount = current_amount})
								if current_amount >= amount then
									inst:RemoveEventCallback("onhitother",OnDamageDone)
								end
							end
						end
					end
			end
			inst:ListenForEvent("onhitother",OnDamageDone)
			local function OnForfeitedQuest()
				inst:RemoveEventCallback("onhitother",OnDamageDone)
			end
			OnForfeit(inst,OnForfeitedQuest,quest_name)
		end,
		difficulty = 1,
		tex = "punchingbag.tex",
	}),
	--125
	CreateQuest({
		name = "The Shadowcrafter",
		amount = 10,
		rewards = {[":func:dodge;10"] = 8, voidcloth = 5, voidcloth_kit = 3},
		points = 800,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst, amount, nil, nil, quest_name, {"SHADOWFORGING", 2})
		end,
		difficulty = 4,
		tex = "station_shadow_forge.tex",
		atlas = "images/crafting_menu_icons.xml",
	}),
	--126
	CreateQuest({
		name = "Strong Stomach",
		amount = 10,
		rewards = {ipecacsyrup = 3},
		points = 140,
		start_fn = function(inst, amount, quest_name)
			local foods = "spoiled_food"
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst, foods, amount, quest_name)
		end,
		difficulty = 1,
		tex = "spoiled_food.tex",
	}),
	--127
	CreateQuest({
		name = "Dreadful Constructor",
		amount = 3,
		rewards = {dreadstone = 60, purebrilliance = 60, [":func:crit;40"] = 16},
		points = 1200,
		start_fn = function(inst, amount, quest_name)
			local constructionsites = "support_pillar_dreadstone_scaffold"
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["construct site x y times"](inst, amount, quest_name, constructionsites)
		end,
		difficulty = 4,
		tex = "support_pillar_dreadstone_scaffold.tex",
	}),
	--128
	CreateQuest({
		name = "Poor Doggies",
		amount = 60,
		rewards = {[":func:healthrate;5"] = 8, eyeturret_item = 1},
		points = 900,
		start_fn = function(inst, amount, quest_name)
			local dogs = {hound = true, firehound = true, icehound = true, magmahound = true, sporehound = true, lightninghound = true}
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst, amount, dogs, quest_name)
		end,
		difficulty = 4,
		tex = "hound.tex",
		atlas = "images/victims.xml",
		anim_prefab = "hound",
	}),
	--129
	CreateQuest({
		name = "The Queen Slayer",
		victim = "spiderqueen",
		amount = 5,
		rewards = {silk = 20, [":func:nightvision;1"] = 12, fireflies = 3},
		points = 1200,
		difficulty = 4,
	}),
	--130
	CreateQuest({
		name = "Whac-A-Mole",
		victim = "mole",
		amount = 3,
		rewards = {guacamole = 3, flint = 5, rocks = 5},
		points = 125,
		difficulty = 1,
	}),
	--131
	CreateQuest({
		name = "Running Like Clockwork",
		amount = 20,
		rewards = {thulecite = 10, [":func:build_buffer"] = "dragonflyfurnace",},
		points = 1000,
		start_fn = function(inst, amount, quest_name)
			local clockworks = {knight = true, bishop = true, rook = true, knook = true, bight = true, roship = true, knight_nightmare = true, bishop_nightmare = true, rook_nightmare = true,}
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst, amount, clockworks, quest_name)
		end,
		difficulty = 4,
		tex = "knight.tex",
		atlas = "images/victims.xml",
		anim_prefab = "knight",
	}),
	--132
	CreateQuest({
		name = "A Friend of Bunnymans",
		amount = 5,
		rewards = {manrabbit_tail = 2, [":func:build_buffer"] = "rabbithouse",},
		points = 130,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["feed x y times"](inst,amount,quest_name,"bunnyman","carrot")
		end,
		difficulty = 1,
		tex = "bunnyman.tex",
		atlas = "images/victims.xml",
		anim_prefab = "bunnyman",
	}),
	--133
	CreateQuest({
		name = "Firestarter",
		amount = 75,
		rewards = {[":func:build_buffer"] = "dragonflychest",},
		points = 900,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["start fire with x y times"](inst,amount,quest_name, nil, {torch = true})
		end,
		difficulty = 4,
		tex = "torch.tex",
		--anim_prefab = "leif",
	}),
	--134
	CreateQuest({
		name = "Squid Game",
		victim = "squid",
		amount = 5,
		rewards = {[":func:build_buffer"] = "saltbox",},
		points = 220,
		difficulty = 2,
	}),
	--135
	CreateQuest({
		name = "It's Wednesday my Dudes!",
		victim = "frog",
		amount = 100,
		rewards = {[":func:build_buffer"] = "mushroom_light", [":func:crit;20"] = 16},
		points = 1000,
		difficulty = 4,
	}),
	--136
	CreateQuest({
		name = "The Archive Guardian",
		amount = 6000,
		rewards = {moonrocknugget = 20, thulecite = 10, [":func:crit;20"] = 16},
		points = 1000,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deal x amount of damage"](inst,amount,nil, quest_name, "archive_centipede")
		end,
		difficulty = 4,
		tex = "archive_centipede.tex",
		atlas = "images/victims.xml",
		anim_prefab = "archive_centipede_husk",
	}),
	--137
	CreateQuest({
		name = "Helmet Compulsory",
		amount = 3,
		rewards = {rabbit = 4, carrat = 4, [":func:damagereduction;0.9"] = 16},
		points = 140,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["get hit by x for y times during earthquakes"](inst, amount, quest_name)
		end,
		difficulty = 1,
		tex = "flint.tex",
	}),
	--138
	CreateQuest({
		name = "Good For Your Nerves",
		amount = 1,
		rewards = {leafymeatsouffle = 1, [":func:sanityaura;2"] = 16},
		points = 125,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst, {sweettea = true}, amount, quest_name)
		end,
		difficulty = 1,
		tex = "sweettea.tex",
	}),
	--139
	CreateQuest({
		name = "Nitroglycerin",
		amount = 50,
		rewards = {moonglass_charged = 5, [":func:range;1"] = 8},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["find x amount of y by working"](inst, {moonglass = true}, amount, quest_name)
		end,
		difficulty = 3,
		tex = "moonglass.tex",
	}),
	--140
	CreateQuest({
		name = "It's A Trap!",
		amount = 10,
		rewards = {supertacklecontainer = 1},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["capture x y times"](inst, amount,{spider_warrior = true}, quest_name)
		end,
		onfinished = nil,
		difficulty = 3,
		tex = "spider_warrior.tex",
		atlas = "images/victims.xml",
		anim_prefab = "spider_warrior"
	}),
	--141
	CreateQuest({
		name = "Mischievous Thief",
		amount = 5,
		rewards = {meat = 10, tallbirdegg_cracked = 1, talleggs = 1},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			local function IsTallbirdEgg(_, data)
				return data and data.loot and data.loot.prefab == "tallbirdegg" and 1
			end
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["pick x y times"](inst, amount, quest_name, IsTallbirdEgg)
		end,
		difficulty = 2,
		tex = "tallbirdegg.tex",
	}),
	--142
	CreateQuest({
		name = "People Pleaser",
		amount = 30,
		rewards = {[":func:sanityaura;10"] = 16, leafymeatsouffle = 3},
		points = 500,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["have sanityaura of x"](inst, amount, quest_name)
		end,
		difficulty = 3,
		tex = "flowerhat.tex",
	}),
	--143
	CreateQuest({
		name = "The Hunt For Mutants",
		amount = 3,
		rewards = {security_pulse_cage = 1, wagpunk_bits = 10},
		points = 1750,
		start_fn = function(inst, amount, quest_name)
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["kill x y times"](inst, amount, nil, quest_name, function(_, victim) return victim:HasTag("mutated") and (victim:HasTag("epic") or victim:HasTag("largecreature")) end)
		end,
		onfinished = nil,
		difficulty = 5,
		tex = "mutateddeerclops.tex",
		atlas = "images/victims.xml",
		anim_prefab = "mutateddeerclops",
	}),
	--144
	CreateQuest({
		name = "Praise The Pigking",
		amount = 250,
		rewards = {[":func:build_buffer"] = "cotl_tabernacle_level1", turf_cotl_gold = 40, [":func:crit;20"] = 16},
		points = 1200,
		start_fn = function(inst, amount, quest_name)
			local gold = GetCurrentAmount(inst,quest_name)
			local pigking = TheSim:FindFirstEntityWithTag("king")
			if not pigking then
				print("[Quest System] Pigking could not be found, aborting quest", quest_name)
				return
			end
			local function OnTrade(_,data)
				devprint("OnTrade", inst,amount,quest_name,data.item)
				if data then
					if data.giver == inst then
						local goldvalue = data.item and data.item.components.tradable and data.item.components.tradable.goldvalue
						if goldvalue then
							inst:PushEvent("quest_update",{quest = quest_name,amount = goldvalue})
							gold = gold + goldvalue
							if gold >= amount then
								pigking:RemoveEventCallback("trade",OnTrade)
							end
						end
					end
				end
			end
			pigking:ListenForEvent("trade",OnTrade)
			local function OnForfeitedQuest()
				if pigking then
					pigking:RemoveEventCallback("trade",OnTrade)
				end
			end
			OnForfeit(pigking,OnForfeitedQuest,quest_name)
		end,
		difficulty = 4,
		tex = "pigking.tex",
		atlas = "images/victims.xml",
		anim_prefab = "pigking",
	}),
	--145
	CreateQuest({
		name = "Training Makes Perfect",
		amount = 5000,
		rewards = {houndstooth_blowpipe = 1},
		points = 1750,
		start_fn = function(inst, amount, quest_name)
			local function IsDart(_, data)
				return data and data.weapon and data.weapon.prefab:find("blowdart")
			end
			TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["deal x amount of damage"](inst, amount, nil, quest_name, nil, IsDart)
		end,
		difficulty = 4,
		tex = "blowdart_pipe.tex",
	}),

}


--Remove quests that are only able to be gotten in the beta


if not CurrentRelease.GreaterOrEqualTo("R31_LUNAR_MUTANTS") then
	local quests_to_remove = {145, 143,}
	for _, quest_num in ipairs(quests_to_remove) do
		table.remove(quests, quest_num)
	end
end

--Custom changes to specific quests

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