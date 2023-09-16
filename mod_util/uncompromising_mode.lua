GLOBAL.SetQuestSystemEnv()

local fancyname = GLOBAL.KnownModIndex:GetModFancyName("workshop-2039181790")
local name = GLOBAL.KnownModIndex:GetModActualName(fancyname)
local custom_functions = GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS

local goals = {}

local function AddPrefabToGoals(prefab,atlas,tex,name)
	local tab = {}
	tab.prefab = prefab
	tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
	tab.tex = tex or prefab..".tex"
	tab.atlas = atlas or "images/victims_uncompromising_mode.xml"
	tab.hovertext = GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.KILL.." x ".."/"..prefab
	return tab
end

local prefabs = {
	"aphid",
	"bushcrab",
	"chimp",
	"fruitbat",
	"hoodedwidow",
	"lureplague_rat",
	"moonmaw_dragonfly",
	"mothermossling",
	"rneskeleton",
	"snowmong",
	"spider_trapdoor",
	"swilson",
	"toadling",
	"woodpecker",
	"snapdragon",
	"uncompromising_rat",
	"uncompromising_toad",

	--Not implemented (yet)
	--"gatorsnake",
	--"haul_hound",
	--"snapperturtle",
	--"snapperturtlebaby",
}


local bosses = {
	EASY = {

		{name = "aphid", health = 1000, damage = 100, scale = 2,},
		{name = "scorpion", health = 1000, damage = 100, scale = 2,},
		{name = "bushcrab", health = 1000, damage = 100, scale = 2,},
		{name = "vampirebat", health = 1000, damage = 100, scale = 2,},

	},

	NORMAL = {

		{name = "lightninghound", health = 3000, damage = 150, scale = 2,},
		{name = "magmahound", health = 3000, damage = 150, scale = 2,},
		{name = "sporehound", health = 3000, damage = 150, scale = 2,},
		{name = "spider_trapdoor", health = 4000, damage = 150, scale = 2,},

	},

	DIFFICULT = {

		{name = "knook", health = 10000, damage = 200, scale = 1.7,},
		{name = "bight", health = 10000, damage = 200, scale = 1.7,},
		{name = "roship", health = 10000, damage = 200, scale = 1.7,},
		--{name = "moonmaw_dragonfly", health = 10000, damage = 200, scale = 1.7,}, --may spawn to other players
		{name = "hoodedwidow", health = 8000, damage = 200, scale = 1.7,},
	},
}

local function RemoveBoss(diff,boss)
	for k,boss_data in ipairs(bosses[diff]) do
		if boss_data.name == boss then
			 return table.remove(bosses[diff],k)
		end
	end
end

for diff,boss in pairs(bosses) do
	for _,data in ipairs(boss) do
		AddBosses(data,diff)
	end
end

--Check all the configs to add only the mobs that were also enabled
if GLOBAL.GetModConfigData("lightninghounds",name) then
	table.insert(prefabs,"lightninghound")
else
	RemoveBoss("NORMAL","lightninghound")
end
if GLOBAL.GetModConfigData("magmahounds",name) then
	table.insert(prefabs,"magmahound")
else
	RemoveBoss("NORMAL","magmahound")
end
if GLOBAL.GetModConfigData("sporehounds",name) then
	table.insert(prefabs,"sporehound")
else
	RemoveBoss("NORMAL","sporehound")
end
if GLOBAL.GetModConfigData("glacialhounds",name) then
	table.insert(prefabs,"glacialhound")
else
	RemoveBoss("NORMAL","glacialhound")
end
if GLOBAL.GetModConfigData("depthseels",name) then
	table.insert(prefabs,"shockworm")
end
if GLOBAL.GetModConfigData("depthsvipers",name) then
	table.insert(prefabs,"viperworm")
end
if GLOBAL.GetModConfigData("adultbatilisks",name) then
	table.insert(prefabs,"vampirebat")
else
	RemoveBoss("NORMAL","vampirebat")
end
if GLOBAL.GetModConfigData("trepidations",name) then
	table.insert(prefabs,"ancient_trepidation")
end
if GLOBAL.GetModConfigData("pawns",name) then
	table.insert(prefabs,"knook")
	table.insert(prefabs,"roship")
	table.insert(prefabs,"bight")
else
	RemoveBoss("NORMAL","knook")
	RemoveBoss("NORMAL","roship")
	RemoveBoss("NORMAL","bight")
end
if GLOBAL.GetModConfigData("desertscorpions",name) then
	table.insert(prefabs,"scorpion")
else
	RemoveBoss("NORMAL","scorpion")
end
if GLOBAL.GetModConfigData("pinelings",name) then
	table.insert(prefabs,"stumpling")
	table.insert(prefabs,"birchling")
end
if GLOBAL.GetModConfigData("pollenmites",name) then
	table.insert(prefabs,"pollenmites")
end
if GLOBAL.GetModConfigData("mother_goose",name) then
	table.insert(prefabs,"mothergoose")
end
if GLOBAL.GetModConfigData("wiltfly",name) then
	table.insert(prefabs,"mock_dragonfly")
end
if GLOBAL.GetModConfigData("harder_shadows",name) then
	table.insert(prefabs,"creepingfear") 
	table.insert(prefabs,"dreadeye") 
end


local item_list = {"beefalowings","blueberrypancakes","californiaking","viperfruit","viperjam","liceloaf","seafoodpaella","snotroast","steamedhams","theatercorn","zaspberryparfait","zaspberry","snowcone","simpsalad","greensteamedhams","purplesteamedhams","hardshelltacos","carapacecooler","rice","giant_blueberry","iceboomerang","monstersmallmeat","rat_tail","scorpioncarapace","shadow_crown","shroom_skin_fragment","skullflask","moon_tear","ancient_amulet_red","beargerclaw","bloomershot","book_rain","bugzapper","snowgoggles","crabclaw","cursed_antler","driftwoodfishingrod","hermitshop_rain_horn","glass_scales","feather_frock","gasmask","gore_horn_hat","honey_log","diseasecurebomb","klaus_amulet","plaguemask","ratpoisonbottle","hat_ratmask","saltpack","stanton_shadow_tonic","armor_glassmail","slingshotammo_firecrackers","slobberlobber","whisperpod","um_bear_trap_equippable_tooth","um_bear_trap_equippable_gold","snowball_throwable","sporepack","sunglasses","mutator_trapdoor","rat_whip","watermelon_lantern","widowsgrasp","widowshead",}


local function RemoveQuest(tab,quest_name)
	devprint("RemoveQuest",tab,quest_name)
	for k,v in ipairs(tab) do
		if v.name == quest_name then
			table.remove(tab,k)
			break
		end
	end
end

AddSimPostInit(function()
	for k,v in ipairs(prefabs) do
		if type(v) == "table" then
			local goal = AddPrefabToGoals(v.prefab,v.atlas,v.tex,v.name)
			table.insert(goals,goal)
		else
			local goal = AddPrefabToGoals(v)
			table.insert(goals,goal)
		end
	end
	AddCustomGoals(goals,"UncompromisingMode")
	AddCustomRewards(item_list)
	
	local quests = {
		--1
		{
			name = "The Dangerous Widow",
			victim = "hoodedwidow",
			counter_name = nil,
			description = GetQuestString("The Dangerous Widow","DESCRIPTION"),
			amount = 1,
			rewards = {[":func:health;50"] = 16,[":func:damage;10"] = 16,giant_blueberry = 10},
			points = 2000,
			start_fn = nil,
			onfinished = nil,
			difficulty = 5,
			tex = "hoodedwidow.tex",
			atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetKillString("hoodedwidow",1),
		},
		--2
		{
			name = "The Mad Adventurer",
			victim = "creepingfear",
			counter_name = nil,
			description = GetQuestString("The Mad Adventurer","DESCRIPTION"),
			amount = 1,
			rewards = {[":func:sanityaura;25"] = 16,icecream = 3,purplesteamedhams = 3},
			points = 700,
			start_fn = nil,
			onfinished = nil,
			difficulty = 3,
			tex = "creepingfear.tex",
			atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetKillString("creepingfear",1),
		},
		--3
		{
			name = "The Monster Breeder",
			victim = "",
			counter_name = GetQuestString("The Monster Breeder", "COUNTER"),
			description = GetQuestString("The Monster Breeder", "DESCRIPTION", 15),
			amount = 15,
			rewards = {[":func:planardamage;5"] = 16,blueberrypancakes = 1,},
			points = 250,
			start_fn = function(inst, amount, quest_name)
				local function IsMonsterMeat(_, data)
					return data.food:HasTag("monstermeat")
				end
				custom_functions["feed x y times"](inst, amount, quest_name, "birdcage", nil, IsMonsterMeat)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "um_monsteregg.tex",
			--atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetQuestString("The Monster Breeder", "HOVER", 15),
		},
		--4
		{
			name = "The Ancient Curse",
			victim = "ancient_trepidation",
			counter_name = nil,
			description = GetQuestString("The Ancient Curse","DESCRIPTION"),
			amount = 1,
			rewards = {[":func:crit;20"] = 16,shadow_crown = 1,skullflask = 2},
			points = 1200,
			start_fn = nil,
			onfinished = nil,
			difficulty = 4,
			tex = "ancient_trepidation.tex",
			atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetKillString("ancient_trepidation",1),
		},
		--5
		{
			name = "Oh Sweet Summer Child",
			victim = "",
			counter_name = GetQuestString("Oh Sweet Summer Child", "COUNTER"),
			description = GetQuestString("Oh Sweet Summer Child", "DESCRIPTION", 1),
			amount = 1,
			rewards = {[":func:planardefense;5"] = 16,um_bear_trap_equippable_gold = 1,},
			points = 125,
			start_fn = function(inst, amount, quest_name)
				custom_functions["craft x y times"](inst, amount, {floral_bandage = true}, nil, quest_name)
			end,
			onfinished = nil,
			difficulty = 1,
			tex = "floral_bandage.tex",
			--atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetQuestString("Oh Sweet Summer Child", "HOVER", 1),
		},
		--6
		{
			name = "It's Raining!",
			victim = "",
			counter_name = GetQuestString("It's Raining!", "COUNTER"),
			description = GetQuestString("It's Raining!", "DESCRIPTION", 2),
			amount = 2,
			rewards = {[":func:build_buffer"] = "air_conditioner", [":func:waterproofness;100"] = 16,},
			points = 900,
			start_fn = function(inst, amount, quest_name)
				local function IsRaining(_, _, UpdateQuest)
					inst:DoTaskInTime(1, function()
						if TheWorld.state.precipitation ~= "none" then
							UpdateQuest()
						end
					end)
				end
				custom_functions["cast spell x y times"](inst, amount, quest_name, {rain_horn = true}, nil, nil, IsRaining)
			end,
			onfinished = nil,
			difficulty = 4,
			tex = "rain_horn.tex",
			--atlas = "images/victims_uncompromising_mode.xml",
			hovertext = GetQuestString("It's Raining!", "HOVER", 2),
		},
		--7
		{
			name = "The Uncompromising Experience",
			victim = "",
			counter_name = GetQuestString("The Uncompromising Experience", "COUNTER"),
			description = GetQuestString("The Uncompromising Experience", "DESCRIPTION", 20),
			amount = 20,
			rewards = {snowgoggles = 1, plaguemask = 1, [":func:escapedeath;1"] = 16,},
			points = 600,
			start_fn = function(inst, amount, quest_name)
				custom_functions["survive x days"](inst, amount, quest_name, true)
			end,
			onfinished = nil,
			difficulty = 3,
			tex = "resurrectionstatue.tex",
			--atlas = "images/victims.xml",
			hovertext = GetQuestString("The Uncompromising Experience", "HOVER", 20),
		},
	}
	if not GLOBAL.GetModConfigData("harder_shadows",name) then
		RemoveQuest(quests,"The Mad Adventurer")
	end

	AddQuests(quests, "Uncompromising Mode")
	RegisterQuestModIcon("Uncompromising Mode", "images/UM_TT.xml", "UM_TT.tex")
end)