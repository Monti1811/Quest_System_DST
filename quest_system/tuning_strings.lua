----------------------------------------------------------------------------------------------

GLOBAL.TUNING.QUEST_COMPONENT = {}
GLOBAL.TUNING.QUEST_COMPONENT.QUEST_BOARD = {}
--Check the config if the configs that can be client bound should be defined by the client or the server
local CLIENT_DATA = GetModConfigData("CLIENT_DATA") or false
GLOBAL.TUNING.QUEST_COMPONENT.GLOBAL_REWARDS = GetModConfigData("GLOBAL_REWARDS") or false

--Get the language config
GLOBAL.TUNING.QUEST_COMPONENT.LANGUAGE = GetModConfigData("LANGUAGE",CLIENT_DATA) or "en"
GLOBAL.STRINGS.QUEST_COMPONENT = require("strings/strings_"..GLOBAL.TUNING.QUEST_COMPONENT.LANGUAGE)

GLOBAL.TUNING.QUEST_COMPONENT.QUESTS = {}
for count = 1,5 do
	GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..count] = {}
end

-----------------------------------Functions for getting the correct strings without crashing------------------

local en_strings = require("strings/strings_en")
local de_strings = require("strings/strings_de")
local fr_strings = require("strings/strings_fr")
local es_strings = require("strings/strings_es")
local ch_strings = require("strings/strings_ch")

local _strings = {en_strings,de_strings,fr_strings,es_strings,ch_strings}

local function FormatString(str,...)
	if ... then
		--devprint("FormatString",str,...)
		return string.format(str,...)
	else
		return str
	end
end

--Used for my quests to give back a str from the wanted category. If it doesn't exist in one language,
--search for the same one in another language, otherwise give back an empty string.
function GLOBAL.GetQuestString(name,str,...)
	if GLOBAL.STRINGS.QUEST_COMPONENT.QUESTS[name] then
		if GLOBAL.STRINGS.QUEST_COMPONENT.QUESTS[name][str] then
			return FormatString(GLOBAL.STRINGS.QUEST_COMPONENT.QUESTS[name][str],...)
		end
	end
	for k,v in ipairs(_strings) do
		if v.QUESTS[name] then
			if v.QUESTS[name][str] then
				return FormatString(v.QUESTS[name][str],...)
			end
		end
	end
	if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] ~= nil then
		return FormatString(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name].name,...)
	end
	return ""
end

--Used for the quest board and log. Gives back the string defined in TUNING
function GLOBAL.GetRewardString(name)
	if string.find(name,":func:") then
		if GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[name] ~= nil then
			local str = GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[name][2]
			return str
		end
	end
end

function GLOBAL.GetKillString(victim,amount)
	return GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.KILL.." "..(amount or 1).." "..(GLOBAL.STRINGS.NAMES[string.upper(victim or "")] or "Error")
end

function GLOBAL.ChangeQuestTuning(quest,fn)
	local tab = fn()
	for k,v in pairs(tab) do
		quest[k] = v
	end
end

-----------------------------------------------Different config options---------------------------------------------------------------

GLOBAL.TUNING.QUEST_COMPONENT.REQUEST_QUEST = GetModConfigData("REQUEST_QUEST") ~= nil and GetModConfigData("REQUEST_QUEST") or 0.01
GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUESTS = GetModConfigData("CUSTOM_QUESTS") ~= nil and GetModConfigData("CUSTOM_QUESTS") or 1
GLOBAL.TUNING.QUEST_COMPONENT.HOTKEY_QUESTLOG = GetModConfigData("HOTKEY_QUESTLOG",CLIENT_DATA) ~= nil and GetModConfigData("HOTKEY_QUESTLOG",CLIENT_DATA) or 1
GLOBAL.TUNING.QUEST_COMPONENT.MANAGE_CUSTOM_QUESTS = GetModConfigData("MANAGE_CUSTOM_QUESTS") ~= nil and GetModConfigData("MANAGE_CUSTOM_QUESTS") or 1 
GLOBAL.TUNING.QUEST_COMPONENT.BOSS_DIFFICULTY = GetModConfigData("BOSS_DIFFICULTY") ~= nil and GetModConfigData("BOSS_DIFFICULTY") or 1
GLOBAL.TUNING.QUEST_COMPONENT.LEVEL_RATE = GetModConfigData("LEVEL_RATE") ~= nil and GetModConfigData("LEVEL_RATE") or 1
GLOBAL.TUNING.QUEST_COMPONENT.BUTTON = GetModConfigData("BUTTON",CLIENT_DATA) ~= nil and GetModConfigData("BUTTON",CLIENT_DATA) or 2
GLOBAL.TUNING.QUEST_COMPONENT.COLORBLINDNESS = GetModConfigData("COLORBLINDNESS",CLIENT_DATA) ~= nil and GetModConfigData("COLORBLINDNESS",CLIENT_DATA) or 0 
GLOBAL.TUNING.QUEST_COMPONENT.RESET_QUESTS = GetModConfigData("RESET_QUESTS") ~= nil and GetModConfigData("RESET_QUESTS") or 0
GLOBAL.TUNING.QUEST_COMPONENT.PROB_CHAR_QUEST = GetModConfigData("PROB_CHAR_QUEST") ~= nil and GetModConfigData("PROB_CHAR_QUEST") or 0.1
GLOBAL.TUNING.QUEST_COMPONENT.GIVE_CREATOR_QUEST = GetModConfigData("GIVE_CREATOR_QUEST") ~= nil and GetModConfigData("GIVE_CREATOR_QUEST") or 0
GLOBAL.TUNING.QUEST_COMPONENT.BOSSFIGHTS = GetModConfigData("BOSSFIGHTS") ~= nil and GetModConfigData("BOSSFIGHTS") or true
GLOBAL.TUNING.QUEST_COMPONENT.FRIENDLY_KILLS = GetModConfigData("FRIENDLY_KILLS") ~= nil and GetModConfigData("FRIENDLY_KILLS") or true
GLOBAL.TUNING.QUEST_COMPONENT.REWARDS_AMOUNT = GetModConfigData("REWARDS_AMOUNT") or 1
GLOBAL.TUNING.QUEST_COMPONENT.RANK = GetModConfigData("RANK") or false
GLOBAL.TUNING.QUEST_COMPONENT.MAX_AMOUNT_GODLY_ITEMS = GetModConfigData("MAX_AMOUNT_GODLY_ITEMS") or 1
GLOBAL.TUNING.QUEST_COMPONENT.BASE_QUEST_SLOTS = GetModConfigData("BASE_QUEST_SLOTS") or 10

if GLOBAL.TUNING.QUEST_COMPONENT.RANK == true then
	GLOBAL.TUNING.QUEST_COMPONENT.RANK = 0
end
if not MODROOT:find("workshop-") then
	GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE = true
	print("GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE",GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE)
end

GLOBAL.TUNING.QUEST_COMPONENT.LEVELSYSTEM = GetModConfigData("LEVELSYSTEM") ~= nil and GetModConfigData("LEVELSYSTEM") or 1
GLOBAL.TUNING.QUEST_COMPONENT.LEVELUPRATE = GetModConfigData("LEVELUPRATE") ~= nil and GetModConfigData("LEVELUPRATE") or 1

GLOBAL.TUNING.QUEST_COMPONENT.DEBUG = GetModConfigData("DEBUG") ~= nil and GetModConfigData("DEBUG") or 0 

----------------------------------------Initialize quests---------------------------------------------------

local function AddQuestToTuning(v)
	if v.name ~= nil then
		GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[v.name] = v
		if v.difficulty then
			if GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty] then
				GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..v.difficulty][v.name] = v
			end
		end
		if v.character ~= nil then
			--adding table to tables of characterspecific quests
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
		end
	end
end

--Check how many should be added and save them in the correct tables.
local INITIAL_QUESTS = GetModConfigData("INITIAL_QUESTS") ~= nil and GetModConfigData("INITIAL_QUESTS") or true
local counting = 0
local quests = require ("quests")
local quests_characters = {} --require("quests_characters") --TODO make some character specific quests
local quests_to_remove = {}
--Check the file for quests to remove. If there is a file, replace the empty table with the inverted return of the file
local f,err = GLOBAL.loadfile("scripts/remove_quests") 
if f and type(f) == "function" then
	quests_to_remove = table.invert(f())
end
if INITIAL_QUESTS ~= true then
	for k,v in ipairs(quests) do
		if quests_to_remove[v.name] == nil then
			counting = counting + 1
			if counting >= GLOBAL.TUNING.QUEST_COMPONENT.INITIAL_QUESTS then 
				break
			end
			AddQuestToTuning(v)
		end
	end
else
	for k,v in ipairs(quests) do
		if quests_to_remove[v.name] == nil then
			AddQuestToTuning(v)
		end
	end
	for char,char_quests in pairs(quests_characters) do
		for k,v in ipairs(char_quests) do
			AddQuestToTuning(v)
		end
	end
end

print("[Quest System] Amount of quests:",GLOBAL.GetTableSize(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS))
for count = 1,5 do
	print("[Quest System] Amount of quests difficulty "..count..":",GLOBAL.GetTableSize(GLOBAL.TUNING.QUEST_COMPONENT["QUESTS_DIFFICULTY_"..count]))
end
-----------------------------------------------------------------------------------------------------------------
--create tables where custom quests are saved
GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS = {}
GLOBAL.TUNING.QUEST_COMPONENT.OWN_QUESTS2 = {}

GLOBAL.TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS = {}

---------------------------------------------------------------------------------------------------------------

GLOBAL.TUNING.QUEST_COMPONENT.CalculatePoints = function(level,points)
    if level and points then
        local max_points = 0
        for count = 1,(level - 1) do
            max_points = max_points + (count * 25 + 100) * GLOBAL.TUNING.QUEST_COMPONENT.LEVEL_RATE
        end
        max_points = max_points + points
        return max_points
    end
    return 0
end

GLOBAL.TUNING.QUEST_COMPONENT.CalculateLevel = function(points)
    if points then
        local max_points = 125 * GLOBAL.TUNING.QUEST_COMPONENT.LEVEL_RATE
        local level = 1
        while points >= max_points do
			devprint("CalculateLevel",level,points,max_points)
			level = level + 1
			points = points - max_points
            max_points = (level * 25 + 100) * GLOBAL.TUNING.QUEST_COMPONENT.LEVEL_RATE
			devprint("CalculateLevel after loop",level,points,max_points)
        end
        return level,points
    end
    return 1,0
end

-------------------------------------------Boss characteristics-----------------------------------------------
local function moose(inst)
	if inst.worldstatewatching and inst.worldstatewatching.isspring then
		inst:StopWatchingWorldState("ispring",inst.worldstatewatching.isspring[1])
	end
	if inst.shouldGoAway then
		inst.shouldGoAway = nil
	end
end	

local function minotaur(inst)
	local function OnDeath(inst)
		GLOBAL.TheWorld:DoTaskInTime(0,function()
			if inst:IsValid() then
				local pos = inst:GetPosition()
				local minotaurchest =  TheSim:FindEntities(pos.x,pos.y,pos.z,3, {"CLASSIFIED"})
				for k,v in ipairs(minotaurchest) do
					if v.prefab == "minotaurchestspawner" and v:IsValid() then
						v:Remove()
					end
				end
			end
		end)
	end
	inst:ListenForEvent("death",OnDeath)
end

local function mutated_penguin(inst)
	inst:DoTaskInTime(2*GLOBAL.FRAMES,function(inst)
		inst.OnEntityWake = nil
		inst.OnEntitySleep = nil
	end)
end

local function birchnutdrake(inst)
	devprint("birchnutdrake",inst.sg)
	if inst.sg and inst.sg.sg then
		if inst.sg.sg.events then
			devprint(inst.sg.sg.events.exit)
			inst.sg.sg.events.exit = nil
			devprint(inst.sg.sg.events.exit)
		end
	end
end

GLOBAL.TUNING.QUEST_COMPONENT.BOSSES = {
	EASY = {

		{name = "hound", 				health = 1000, damage = 100, scale = 2},
		{name = "mutatedhound", 		health = 1000, damage = 100, scale = 2},
		{name = "catcoon", 				health = 1000, damage = 100, scale = 2},
		{name = "birchnutdrake", 		health = 1000, damage = 100, scale = 2, 	fn = birchnutdrake},
		{name = "bunnyman", 			health = 1500, damage = 100, scale = 1.9},
		{name = "frog", 				health = 1500, damage = 100, scale = 1.9},
		{name = "beeguard", 			health = 1500, damage = 100, scale = 1.9},
		{name = "koalefant_winter", 	health = 2000, damage = 80,  scale = 1.6},
		{name = "walrus", 				health = 1000, damage = 75,  scale = 1.6},
		{name = "bird_mutant_spitter", 	health = 1000, damage = 100, scale = 1.9},
		{name = "mutated_penguin", 		health = 1500, damage = 100, scale = 1.9, 	fn = mutated_penguin},
		--{name = "mossling", 			health = 1000, damage = 100, scale = 1.6, 	fn = moose},
		{name = "mosquito", 			health = 1500, damage = 100, scale = 1.9},
		{name = "fruitdragon", 			health = 1500, damage = 100, scale = 1.6},
		{name = "spider_warrior", 		health = 1000, damage = 100, scale = 1.9},
	},

	NORMAL = {

		{name = "beefalo", 		health = 4000, damage = 150, scale = 1.6},
		{name = "deerclops", 	health = 5000, damage = 150, scale = 1.9},
		{name = "spider_hider", health = 3500, damage = 125, scale = 2},
		{name = "bishop", 		health = 3000, damage = 150, scale = 1.7},
		{name = "worm", 		health = 5000, damage = 125, scale = 1.7},
		{name = "grassgator", 	health = 4000, damage = 125, scale = 1.7},
		{name = "pigguard", 	health = 4000, damage = 125, scale = 1.7},
		{name = "krampus", 		health = 4000, damage = 125, scale = 1.7},
		{name = "merm", 		health = 4000, damage = 125, scale = 1.7},
		{name = "rocky", 		health = 5000, damage = 125, scale = 1.5},
		{name = "spider_moon", 	health = 3500, damage = 150, scale = 1.9},
		{name = "tallbird", 	health = 4000, damage = 150, scale = 1.7},
		{name = "warglet", 		health = 3000, damage = 125, scale = 1.7},

	},

	DIFFICULT = {

		{name = "deerclops", 		health = 12000, damage = 200, scale = 2.1},
		{name = "minotaur", 		health = 10000, damage = 200, scale = 2.1, 	fn = minotaur},
		{name = "stalker", 			health = 6000,  damage = 200, scale = 1.4},
		{name = "spat", 			health = 4000,  damage = 100, scale = 1.7},
		{name = "moose", 			health = 12000, damage = 200, scale = 1.7, 	fn = moose},
		{name = "warg",				health = 6000,  damage = 150, scale = 1.7},
		{name = "shadow_knight", 	health = 9000,  damage = 200, scale = 1.7},
		{name = "shadow_bishop", 	health = 9000,  damage = 200, scale = 1.7},
		{name = "shadow_rook", 		health = 9000,  damage = 200, scale = 1.7},
		{name = "spiderqueen", 		health = 6000,  damage = 200, scale = 1.6},
		{name = "eyeofterror", 		health = 10000, damage = 200, scale = 1.8},
		{name = "twinofterror1", 	health = 11000, damage = 200, scale = 1.6},
		{name = "twinofterror2", 	health = 11000, damage = 200, scale = 1.6},

	},
} 

-------------------------------------Bossfight rewards---------------------------------------------

GLOBAL.TUNING.QUEST_COMPONENT.BOSSFIGHT_REWARDS = {
	
	EASY = {

		{
			items = {"pigskin","cutstone",},
			amount = {{10,20},{5,10},},
		},
		{
			items = {"boards","nitre",},
			amount = {{10,20},{15,25},},
		},
		{
			items = {"cutgrass","cutstone",},
			amount = {{30,40},{5,10},},
		},
		{
			items = {"silk","marble",},
			amount = {{10,20},{5,10},},
		},
		{
			items = {"flint","gears",},
			amount = {{10,20},{2,5},},
		},
	},

	NORMAL = {

		{	
			items = {"redgem","wathgrithrhat",},
			amount = {{10,20},{1,2},},
		},
		{	
			items = {"bluegem","beardhair",},
			amount = {{10,20},{5,10},},
		},
		{	
			items = {"purplegem","honeycomb",},
			amount = {{10,20},{3,7},},
		},
		{	
			items = {"manrabbit_tail","butter","livinglog",},
			amount = {{5,10},{2,5},{5,10},},
		},
		{	
			items = {"moonrocknugget","dragonfruit","jellybean",},
			amount = {{10,20},{3,7},{3,6},},
		},

	},
	DIFFICULT = {

		{
			items = {"greengem","ruins_bat",},
			amount = {{1,5},{1,3},},
		},
		{
			items = {"yellowgem","ruinshat",},
			amount = {{1,5},{1,3},},
		},
		{
			items = {"orangegem","armorruins",},
			amount = {{1,5},{1,3},},
		},
		{
			items = {"eyebrellahat","yellowamulet",},
			amount = {{1,1},{1,1},},
		},
		{
			items = {"opalstaff","shroom_skin",},
			amount = {{1,2},{2,4},},
		},

	},
}

-------------------------------------------Strings for added items-------------------------------------------

local function AddString(name,name2)
	name2 = name2 or name
	if GLOBAL.STRINGS.QUEST_COMPONENT.NAMES[name2] then
		GLOBAL.STRINGS.NAMES[name] = GLOBAL.STRINGS.QUEST_COMPONENT.NAMES[name2]
	end
	if GLOBAL.STRINGS.QUEST_COMPONENT.DESCRIBE[name2] then
		GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE[name] = GLOBAL.STRINGS.QUEST_COMPONENT.DESCRIBE[name2]
	end
	if GLOBAL.STRINGS.QUEST_COMPONENT.RECIPE_DESC[name2] then
		GLOBAL.STRINGS.RECIPE_DESC[name] = GLOBAL.STRINGS.QUEST_COMPONENT.RECIPE_DESC[name2]
	end
end

local strings_to_add = {
	"REQUEST_QUEST",
	"REQUEST_QUEST_VERY_EASY",
	"REQUEST_QUEST_EASY",
	"REQUEST_QUEST_NORMAL",
	"REQUEST_QUEST_DIFFICULT",
	"REQUEST_QUEST_VERY_DIFFICULT",
	"REQUEST_QUEST_SPECIFIC",
	"QUESTBOARD",
	"GLOMMERFUELMACHINE",
	"GLOMMER_LIGHTFLOWER",
	"CHESTER_BOSS",
	"NIGHTMARECHESTER",
	"NIGHTMARECHESTER_EYEBONE",
	"GLOMMER_SMALL",
	"GLOMMER_BOSS",
	"BLACKGLOMMERFUEL",
	"ADDITIONAL QUEST SLOTS",
	"SHADOW_CREST",
	"SHADOW_MITRE",
	"SHADOW_LANCE"
}

for _,v in ipairs(strings_to_add) do 
	AddString(v)
end

---------------------------------------Action Strings--------------------------------------------------

if GLOBAL.STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.FIGHT_GLOMMER == nil then
	GLOBAL.STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.FIGHT_GLOMMER = {}
end
GLOBAL.STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.FIGHT_GLOMMER.GLOMMER_ACTIVE = "A Friend Fight is still not finished!"


---------------------------------------Add loading tips--------------------------------------------------

local LOADING_TIPS = GetModConfigData("LOADING_TIPS") or 1
if LOADING_TIPS ~= 0 then

	--Set the assets for the tips
	PreloadAssets = {
		Asset("ATLAS", "images/loadingtip_quest_board.xml"),
		Asset("IMAGE", "images/loadingtip_quest_board.tex"),
	}

	ReloadPreloadAssets()

	--Set the icon for your new category
	SetLoadingTipCategoryIcon("QUEST_SYSTEM","images/loadingtip_quest_board.xml","loadingtip_quest_board.tex")
	--Add an own category for the tips, set the number as the workshop number to avoid conflicts
	GLOBAL.LOADING_SCREEN_TIP_CATEGORIES["QUEST_SYSTEM"] = 2597204554

	local start_tab = 
		{
		    QUEST_SYSTEM = 4 * LOADING_TIPS,
		}

	local end_tab = 
	{
	    QUEST_SYSTEM = 1.5 * LOADING_TIPS,
	}
	--Add custom weights for this category
	SetLoadingTipCategoryWeights(GLOBAL.LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_START,start_tab)
	SetLoadingTipCategoryWeights(GLOBAL.LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_END,end_tab)

	--Make a new strings table and add the strings to them
	STRINGS.UI.LOADING_SCREEN_QUEST_SYSTEM_TIPS = {}
	for key,tip in pairs(STRINGS.QUEST_COMPONENT.LOADING_TIPS) do
		AddLoadingTip(STRINGS.UI.LOADING_SCREEN_QUEST_SYSTEM_TIPS,key,tip)
		--Also add it LOADING_SCREEN_OTHER_TIPS so that GenerateControlTipText finds the correct text
		AddLoadingTip(STRINGS.UI.LOADING_SCREEN_OTHER_TIPS,key,tip)
	end

	--Change the PickLoadingTip and CalculateLoadingTipWeights fn so that they also calculate the new category and choose the correct text for them
	AddClassPostConstruct("loadingtipsdata",function(self)
		local old_PickLoadingTip = self.PickLoadingTip
		self.PickLoadingTip = function(self,loadingscreen,...)
			local tipdata = old_PickLoadingTip(self,loadingscreen,...)
			--print("PickLoadingTip",loadingscreen)
			--GLOBAL.dumptable(tipdata)
			if tipdata and tipdata.icon == "loadingtip_quest_board.tex" then
				tipdata.text = self:GenerateControlTipText(tipdata.id)
				--GLOBAL.dumptable(tipdata)
			end
			return tipdata
		end

		local old_CalculateLoadingTipWeights = self.CalculateLoadingTipWeights
		self.CalculateLoadingTipWeights = function(self,...)
			local loadingtipweights = old_CalculateLoadingTipWeights(self,...)
			loadingtipweights[GLOBAL.LOADING_SCREEN_TIP_CATEGORIES.QUEST_SYSTEM] = self:GenerateLoadingTipWeights(STRINGS.UI.LOADING_SCREEN_QUEST_SYSTEM_TIPS)
			return loadingtipweights
		end
	end)

	GLOBAL.TheLoadingTips = require("loadingtipsdata")()

	-- Recalculate loading tip & category weights.
	local TheLoadingTips = GLOBAL.TheLoadingTips
	TheLoadingTips.loadingtipweights = TheLoadingTips:CalculateLoadingTipWeights()
	TheLoadingTips.categoryweights = TheLoadingTips:CalculateCategoryWeights()

	TheLoadingTips:Load()

end