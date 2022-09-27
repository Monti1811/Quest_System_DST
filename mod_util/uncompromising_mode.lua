local name = GLOBAL.KnownModIndex:GetModActualName("󰀕 Uncompromising Mode")

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

		{name = "lightninghound", health = 3500, damage = 150, scale = 2,},
		{name = "magmahound", health = 3500, damage = 150, scale = 2,},
		{name = "sporehound", health = 3500, damage = 150, scale = 2,},
		{name = "spider_trapdoor", health = 4000, damage = 150, scale = 2,},

	},

	DIFFICULT = {

		{name = "knook", health = 10000, damage = 200, scale = 1.7,},
		{name = "bight", health = 10000, damage = 200, scale = 1.7,},
		{name = "roship", health = 10000, damage = 200, scale = 1.7,},
		{name = "moonmaw_dragonfly", health = 10000, damage = 200, scale = 1.7,},
		{name = "hoodedwidow", health = 8000, damage = 200, scale = 1.7,},
	},
}

local function RemoveBoss(diff,boss)
	for k,boss in ipairs(bosses[diff]) do
		if boss.name == boss then
			 return table.remove(bosses[diff],k)
		end
	end
end

for diff,boss in pairs(bosses) do
	for _,data in ipairs(boss) do
		GLOBAL.AddBosses(data,diff)
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
		end
	end
end

local function GetKillString(victim,amount)
	return GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.KILL.." "..(amount or 1).." "..(GLOBAL.STRINGS.NAMES[string.upper(victim)] or "Error")
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
	GLOBAL.AddCustomGoals(goals,"UncompromisingMode")
	GLOBAL.AddCustomRewards(item_list)
	
	local quests = {
		--1
		{
		name = "The Dangerous Widow",
		victim = "hoodedwidow",
		counter_name = nil,
		description = GLOBAL.GetQuestString("The Dangerous Widow","DESCRIPTION"),
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
		description = GLOBAL.GetQuestString("The Mad Adventurer","DESCRIPTION"),
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
	}
	if not GLOBAL.GetModConfigData("harder_shadows",name) then
		RemoveQuest(quests,"The Mad Adventurer")
	end

	GLOBAL.AddQuests(quests)
end)