------------------------------------------------------------------------------------------------
local QUEST_COMPONENT = GLOBAL.TUNING.QUEST_COMPONENT
local STR_QUEST_COMPONENT = GLOBAL.STRINGS.QUEST_COMPONENT
local STR_QF = STR_QUEST_COMPONENT.QUEST_FUNCTIONS
local QUEST_BOARD = QUEST_COMPONENT.QUEST_BOARD
local NAMES = GLOBAL.STRINGS.NAMES
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local unpack = GLOBAL.unpack
local GetTime = GLOBAL.GetTime
local ACTIONS = GLOBAL.ACTIONS

--Make spinners for the quest board to create new quests
local function MakeSpinnerData(min,max)
	local tab = {}
	for count = min,max do
		table.insert(tab,{text = tostring(count),data = count})
	end
	return tab
end


QUEST_BOARD.NUMBERS = {}
QUEST_BOARD.NUMBERS["1_5"] = MakeSpinnerData(1,5)
QUEST_BOARD.NUMBERS["0_10"] = MakeSpinnerData(0,10)
QUEST_BOARD.NUMBERS["0_40"] = MakeSpinnerData(0,40)
--QUEST_BOARD.NUMBERS["0_100"] = MakeSpinnerData(0,100)


local function MakePrefabDataKills(prefab)
	local txt
	if type(prefab) == "table" then
		txt = prefab[2]
		local dat = {
			text = txt,
			data = prefab[1],
			hovertext = STR_QUEST_COMPONENT.QUEST_LOG.KILL.." x ".."/"..prefab[1],
		}
		return dat
	else
		txt = NAMES[string.upper(prefab)] or "No Name"
		local dat = {
			text = txt,
			data = prefab,
			hovertext = STR_QUEST_COMPONENT.QUEST_LOG.KILL.." x ".."/"..prefab,
		}
		return dat
	end
end

local function MakePrefabData(prefab)
	local txt
	if type(prefab) == "table" then
		txt = prefab[2]
		local dat = { text = txt,data = prefab[1]}
		return dat
	else
		txt = NAMES[string.upper(prefab)] or "No Name"
		local dat = { text = txt,data = prefab}
		return dat
	end
end

local prefabs = {
	{"random","Random"},
	"stalker_atrium",
	"antlion",
	"minotaur",
	"bat",
	"bee",
	"killerbee",
	"butterfly",
	"moonbutterfly",
	"beefalo",
	"beequeen",
	"babybeefalo",
	"crow",
	"bird_mutant",
	"bird_mutant_spitter",
	"robin",
	"robin_winter",
	"canary",
	"canary_poisoned",
	"puffin",
	"lightflier",
	"bearger",
	"bunnyman",
	"buzzard",
	"carrat",
	"alterguardian_phase3",
	"chester",
	"hutch",
	"catcoon",
	"cookiecutter",
	"crabking",
	"bishop",
	"knight",
	"rook",
	"dragonfly",
	"deerclops",
	"dustmoth",
	"eyeofterror",
	"eyeofterror_mini",
	"worm",
	"spat",
	"frog",
	"friendlyfruitfly",
	"fruitfly",
	"lordfruitfly",
	"ghost",
	"glommer",
	"gnarwail",
	"grassgekko",
	"grassgator",
	"perd",
	"hound",
	"firehound",
	"icehound",
	"mutatedhound",
	"eyeturret",
	{"koalefant_summer","Koalefant Summer"},
	{"koalefant_winter", "Koalefant Winter"},
	"krampus",
	"lavae_pet",
	"walrus",
	"little_walrus",
	"lightcrab",
	"mandrake_active",
	"malbatross",
	"merm",
	"mole",
	{"moose","Moose/Goose"},
	"mossling",
	"lureplant",
	"eyeplant",
	"mosquito",
	"mushgnome",
	"molebat",
	"penguin",
	"powder_monkey",
	"prim_mate",
	"mutated_penguin",
	"pigman",
	"pigguard",
	{"moonpig","Were Pig"},
	"rabbit",
	"rocky",
	"shark",
	"crawlinghorror",
	"terrorbeak",
	"oceanhorror",
	"fruitdragon",
	"slurper",
	"slurtle",
	"snurtle",
	"monkey",
	"stalker",
	{"stalker_forest","Forest Stalker"},
	"spider",
	"spider_warrior",
	"spiderqueen",
	"spider_hider",
	"spider_spitter",
	"spider_dropper",
	"spider_moon",
	"spider_healer",
	"spider_water",
	"waterplant",
	"squid",
	"shadow_knight",
	"shadow_bishop",
	"shadow_rook",
	"tallbird",
	"smallbird",
	"teenbird",
	"tentacle",
	"tentacle_pillar",
	"toadstool",
	"twinofterror1",
	"twinofterror2",
	"leif",
	"warg",
	"warglet",
	"waterplant",
	"lightninggoat",
	"wobster_sheller_land",
	"wobster_moonglass",
}

QUEST_BOARD.PREFABS_MOBS = {}
for _,v in ipairs(prefabs) do
	local new_tab = MakePrefabDataKills(v)
	QUEST_BOARD.PREFABS_MOBS[new_tab.data] = new_tab
end

local item_list = {
	{"random","Random"},"acorn","amulet","anchor_item","antliontrinket","archive_resonator_item","armor_bramble","armordragonfly","armorgrass","armormarble","armorruins","armor_sanity","armorskeleton","armorslurper","armorsnurtleshell","armorwood","ash","atrium_key","axe","backpack","bandage","batbat","bathbomb","bearger_fur","beargervest","bedroll_straw","bedroll_furry","bee","beef_bell","beefalowool","beemine","beeswax","boards","dug_berrybush","birdtrap","blueprint","boatpatch","boneshard","boomerang","brush","bugnet","bullkelp_root","bundlewrap","butter","butterflywings","candybag","cane","charcoal","chester_eyebone","chum","compass","compost","compostwrap","cookbook","coontail","cutgrass","cutstone","driftwood_log","dustmeringue","bird_egg","bird_egg_cooked","rottenegg","eyeturret_item","farm_hoe","farm_plow_item","featherpencil","feather_crow","feather_robin","feather_robin_winter","feather_canary","fireflies","fishingrod","flint","fossil_piece","froglegs","gears","redgem","bluegem","purplegem","greengem","yellowgem","orangegem","glasscutter","glommerflower","glommerfuel","glommerwings","gnarwail_horn","goatmilk","goldnugget","goose_feather","guano","gunpowder","hammer","strawhat","tophat","beefalohat","featherhat","beehat","minerhat","spiderhat","footballhat","earmuffshat","winterhat","bushhat","flowerhat","walrushat","slurtlehat","ruinshat","molehat","wathgrithrhat","walterhat","icehat","rainhat","catcoonhat","watermelonhat","eyebrellahat","red_mushroomhat","blue_mushroomhat","green_mushroomhat","hivehat","deserthat","goggleshat","moonstorm_goggleshat","skeletonhat","kelphat","mermhat","cookiecutterhat","batnosehat","nutrientsgoggleshat","plantregistryhat","balloonhat","alterguardianhat","hawaiianshirt","healingsalve","honey","honeycomb","horn","houndstooth","hutch_fishbowl","icepack","krampus_sack","lavae_egg","lichen","livinglog","log","malbatross_feather","malbatross_feathered_weave","malbatross_beak","mandrake","manrabbit_tail","mapscroll","marble","marblebean","meat","cookedmeat","meat_dried","monstermeat","cookedmonstermeat","monstermeat_dried","smallmeat","cookedsmallmeat","smallmeat_dried","drumstick","drumstick_cooked","batwing","batwing_cooked","plantmeat","plantmeat_cooked","fishmeat_small","fishmeat_small_cooked","fishmeat","fishmeat_cooked","barnacle","barnacle_cooked","batnose","batnose_cooked","messagebottle","messagebottleempty","miniboatlantern","minifan","miniflare","lantern","minisign_item","minotaurhorn","mole","moonbutterflywings","purplemooneye","bluemooneye","redmooneye","orangemooneye","yellowmooneye","greenmooneye","moonglass","moonrocknugget","moon_tree_blossom","mosquitosack","nitre","oar","oceanfish_small_1_inv","oceanfish_small_2_inv","oceanfish_small_3_inv","oceanfish_small_4_inv","oceanfish_small_5_inv","oceanfish_small_6_inv","oceanfish_small_7_inv","oceanfish_small_8_inv","oceanfish_small_9_inv","oceanfish_medium_1_inv","oceanfish_medium_2_inv","oceanfish_medium_3_inv","oceanfish_medium_4_inv","oceanfish_medium_5_inv","oceanfish_medium_6_inv","oceanfish_medium_7_inv","oceanfish_medium_8_inv","oceanfish_medium_9_inv","oceanfishinglure_spoon_red","oceanfishinglure_spoon_green","oceanfishinglure_spoon_blue","oceanfishinglure_spinner_red","oceanfishinglure_spinner_green","oceanfishinglure_spinner_blue","oceanfishinglure_hermit_rain","oceanfishinglure_hermit_snow","oceanfishinglure_hermit_drowsy","oceanfishinglure_hermit_heavy","oceanfishingrod","oceantreenut","panflute","papyrus","petals","petals_evil","phlegm","pickaxe","pig_coin","pig_token", "pigskin","piggyback","pinecone","pitchfork","poop","portableblender_item", "portablecookpot_item","portablespicer_item","portabletent","pumpkin_lantern", "raincoat","razor","redlantern","cutreeds","refined_dust","reflectivevest","reskin_tool","reviver","rock_avocado_fruit","rocks","rope","royal_jelly","seedpouch","seeds","sewing_tape","sewing_kit","shadowheart","shovel","shroom_skin","silk","singingshell_octave3","singingshell_octave4","singingshell_octave5","slingshot", "slurper_pelt","slurtle_shellpieces","slurtleslime","spear","spicepack","spice_garlic","spice_sugar","spice_chili","spice_salt","spidereggsack","spidergland","steelwool","steeringwheel_item","stinger","sweatervest","tallbirdegg","thulecite","thulecite_pieces","thurible","torch","transistor","trap","trap_bramble","trap_starfish","trap_teeth","treegrowthsolution","trunk_summer","trunk_winter","trunk_cooked","twigs","umbrella","cave_banana","corn","pumpkin","eggplant","durian","pomegranate","dragonfruit","berries","berries_juicy","carrot","fig","cactus_meat","watermelon","kelp","tomato","potato","asparagus","milkywhites","onion","garlic","pepper","wateringcan","premiumwateringcan","ruins_bat","hambat","nightstick","nightsword","trident","tentaclespike","spear_wathgrithr","whip","moonglassaxe","multitool_axe_pickaxe","saddlehorn","oar_driftwood","lighter","icestaff","firestaff","staff_tornado","trunkvest_summer","blueamulet","greenamulet","greenstaff","green_mushroomhat","yellowamulet","opalstaff","purpleamulet","onemanband","trunkvest_winter","yellowstaff","telestaff","orangestaff","orangeamulet","eyemaskhat","shieldofterror","stash_map","cursed_monkey_token","monkey_mediumhat","bananajuice","shadow_forge_kit","voidclothhat","armor_voidcloth","voidcloth_umbrella","voidcloth_scythe","armor_lunarplant","lunarplanthat","bomb_lunarplant","staff_lunarplant","sword_lunarplant","pickaxe_lunarplant","shovel_lunarplant","lunar_forge_kit",
}

for k in pairs(require("preparedfoods")) do
	table.insert(item_list,k)
end

for k in pairs(require("preparedfoods_warly")) do
	table.insert(item_list,k)
end

QUEST_BOARD.PREFABS_ITEMS = {}
local PREFABS_ITEMS = QUEST_BOARD.PREFABS_ITEMS
for _,v in ipairs(item_list) do
	local new_tab = MakePrefabData(v)
	table.insert(PREFABS_ITEMS,new_tab)
end


local function MakeFuncRewardData(name,func)
	return {text = name,data = func}
end

--functions that can be called as rewards are saved here:
QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS = {
	--[":func:test"] = {function(inst) print("test") end,"Test x Function","tex.tex","atlas.xml"},
	[":func:krampus_sack"] = {
		function(inst,amount)			--function that is run
			if math.random() < amount/100 then
				local krampus_sack = SpawnPrefab("krampus_sack")
				if inst.components.inventory and krampus_sack then
					inst.components.inventory:GiveItem(krampus_sack)
				end
			end
		end,
		function(amount) return string.format(STR_QF.KRAMPUS_SACK, amount or "unknown") end,	--Name that is shown, either a value or a function with the argument of the value
		"krampus_sack.tex", 				--tex
		--"images/inventoryimages1.xml",	--atlas
	},
	[":func:build_buffer"] = {
		function(inst,recname)			--function that is run
			local builder = inst.components.builder
			if not builder:KnowsRecipe(recname, true) then
				builder:UnlockRecipe(recname)
			end
			builder.buffered_builds[recname] = true
			inst.replica.builder:SetIsBuildBuffered(recname, true)
		end,
		function(recname) return string.format(STR_QF.BUILD_BUFFER, STRINGS.NAMES[string.upper(recname)] or "unknown") end,	--Name that is shown, x is amount for the function
		function(recname) return recname..".tex" end, 			--tex
		--"images/inventoryimages1.xml",	--atlas
	},

}

local text_table_boni = {
	sanity = function(amount) return "+"..amount.."/min " end,
	nightvision = function(_) return "" end,
	damagereduction = function(amount) amount = (1-amount) * 100;return "+"..amount.."% " end,
	hungerrate = function(amount) amount = amount * 100;return amount.."% " end,
	escapedeath = function(amount) return amount.." " end,
	dodge = function(amount) return amount.."s " end,
	crit = function(amount) return amount.."% " end,
	waterproofness = function(amount) return amount.."% " end,
}

local function MakeTempRewardData(bonus,amount)
	--devprint("MakeTempRewardData",bonus,amount)
	local fn = function(inst,time,questname)
		local temporarybonus = inst.components.temporarybonus
		if temporarybonus then
			temporarybonus:AddBonus(bonus,questname,amount,time*60)
		end
	end
	local text
	if text_table_boni[bonus] ~= nil then
		local prefix = text_table_boni[bonus](amount)
		--print(prefix)
		text = prefix..STR_QUEST_COMPONENT.REWARDS[bonus]
	else
		text = "+"..amount.." "..STR_QUEST_COMPONENT.REWARDS[bonus]
	end
	local name = bonus..";"..amount
	local tex = bonus..".tex"
	return name,text,fn,tex
end

local temprewards = {
	health = {10,25,50,100,},
	sanity = {10,25,50,100,},
	hunger = {10,25,50,100,},
	sanityaura = {2,5,10,25,},
	hungerrate = {0.9,0.8,0.7,0.6},
	healthrate = {1,2,5,10,},
	damage = {2,5,10,25,},
	planardamage = {2,5,10,25,},
	damagereduction = {0.9,0.8,0.7,0.6},
	planardefense = {2,5,10,25,},
	range = {0.5,1,1.5,2},
	dodge = {30,20,10,5},
	crit = {5,10,20,40},
	winterinsulation = {40,80,120,160},
	summerinsulation = {40,80,120,160},
	waterproofness = {40,60,80,100},
	worker = {1.2,1.4,1.6,2,},
	sleeping = {0.2,0.4,0.6,1,},
	nightvision = {1},
	speed = {1.05,1.1,1.2,1.3,},
	escapedeath = {1,2,3,4,},
}

local CUSTOM_QUEST_END_FUNCTIONS = QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS
for k,v in pairs(temprewards) do
	for _,vv in ipairs(v) do
		local name,text,fn,tex = MakeTempRewardData(k,vv)
		local atlas = "images/victims.xml"
		CUSTOM_QUEST_END_FUNCTIONS[":func:"..name] = {fn,text,tex,atlas}
	end
end
--GLOBAL.dumptable(QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS)

for k,v in pairs(CUSTOM_QUEST_END_FUNCTIONS) do
	local tab = MakeFuncRewardData(v[2],k)
	table.insert(QUEST_BOARD.PREFABS_ITEMS,tab)
end

local LevelRewardData = {
	[5] = {
		monstermeat = 3,
		butterfly = 3,
	},
	[10] = {
		boards = 3,
		bee = 4,
	},
	[15] = {
		pigskin = 4,
		butterfly = 3,
	},
	[20] = {
		pigskin = 3,
		meat = 5,
	},
	[25] = {
		meat_dried = 5,
		bird_egg = 5,
	},
	[30] = {
		cutstone = 10,
		boards = 10,
	},
	[35] = {
		batwing = 10,
		butter = 2,
	},
	[40] = {
		amulet = 1,
		nightsword = 1,
	},
	[45] = {
		mandrake = 1,
		butterfly = 3,
	},
	[50] = {
		marblebean = 15,
		bonestew = 2,
	},
	[55] = {
		deerclops_eyeball = 1,
	},
	[60] = {
		dragonfruit = 5,
		butterfly = 5,
	},
	[65] = {
		spear_wathgrithr = 1,
		twigs = 40,
	},
	[70] = {
		goatmilk = 3,
		garlic = 5,
	},
	[75] = {
		moonglassaxe = 1,
		goldnugget = 15,
	},
	[80] = {
		gears = 10,
		honey = 10,
	},
	[85] = {
		moonbutterflywings = 10,
		onion = 5,
	},
	[90] = {
		pepper = 5,
		firestaff = 1,
	},
	[95] = {
		dustmeringue = 5,
		thulecite_pieces = 6,
	},
	[100] = {
		yellowgem = 3,
		greengem = 3,
		["Additional Quest Slots"] = 5,
	},
	[105] = {
		mashedpotatoes = 3,
		molehat = 1,
	},
	[110] = {
		nightstick = 1,
		redgem = 5,
	},
	[115] = {
		fishsticks = 5,
		bluegem = 5,
	},
	[120] = {
		purpleamulet = 1,
		healingsalve = 5,
	},
	[125] = {
		archive_resonator_item = 2,
	},
	[130] = {
		nutrientsgoggleshat = 1,
	},
	[135] = {
		orangeamulet = 1,
		orangegem = 2,
	},
	[140] = {
		ruins_bat = 2,
		livinglog = 10,
	},
	[145] = {
		ruinshat = 2,
		armorruins = 2,
	},
	[150] = {
		multitool_axe_pickaxe = 2,
		thulecite_pieces = 12,
	},
	[155] = {
		yellowamulet = 1,
		nightmarefuel = 20,
	},
	[160] = {
		greenamulet = 1,
		nightmarefuel = 20,
	},
	[165] = {
		thulecite = 5,
		opalpreciousgem = 1,
	},
	[170] = {
		greenstaff = 1,
		opalstaff = 1,
	},
	[175] = {
		eyeturret_item = 2,
	},
	[180] = {
		thurible = 1,
	},
	[185] = {
		armorskeleton = 1,
	},
	[190] = {
		skeletonhat = 1,
	},
	[195] = {
		alterguardianhat = 1,
		["Additional Quest Slots"] = 5,
	},
}

QUEST_BOARD.LEVEL_REWARDS = LevelRewardData

local tree_seeds = {"pinecone","acorn","twiggy_nut","moonbutterfly","rock_avocado_fruit_sprout",}

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

local function SetValues(player, quest_name, value_name, value)
	local quest_component = player.components.quest_component
	if quest_component == nil then
		return
	end
	quest_component:SetQuestData(quest_name, value_name, value)
end

local function RemoveValues(player,quest_name)
	local quest_component = player.components.quest_component
	if quest_component == nil then
		return
	end
	quest_component.quest_data[quest_name] = nil
end

local function StopTask(entity, task)
	if entity[task] ~= nil then
		entity[task]:Cancel()
		entity[task] = nil
	end
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

local custom_functions = {
	
	["eat x times y"] = function(player,foods,amount,quest_name)
		local food_eaten = GetCurrentAmount(player,quest_name)
		foods = type(foods) == "string" and {[foods] = true} or foods
		local Food
		local function UpdateQuest()
			food_eaten = food_eaten + 1
			player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
			if food_eaten >= amount then
				player:RemoveEventCallback("oneat",Food)
			end
		end
		Food = function(_, data)
			if data and data.food then
				if foods == nil or foods[data.food.prefab] then
					UpdateQuest()
				end
			end
		end
		player:ListenForEvent("oneat",Food)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("oneat",Food)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["stay x time"] = function(player,component,smaller_or_bigger,percent,period,quest_name,at_once,mode)
		local time = 0
		local fn_name = "check_sanity_quest_"..quest_name
		local function CheckSanity(_player)
			local _component = _player.components[component]
			if _component then
				if (smaller_or_bigger == 0 and _component:GetPercent() < percent or smaller_or_bigger == 1 and _component:GetPercent() > percent) then
					if (component == "sanity" and (mode == nil or _player.components.sanity.mode == mode)) or component ~= "sanity" then
						time = time + 1
						_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
						if time >= period then
							_player[fn_name] = nil
							return
						end
					end
				else
					if at_once == true and time ~= 0 then
						time = 0
						_player:PushEvent("quest_update",{ quest = quest_name, reset = true})
					end
				end
			end
			_player[fn_name] = _player:DoTaskInTime(1,CheckSanity)
		end
		if player[fn_name] ~= nil then
        	player[fn_name]:Cancel()
    	end
		CheckSanity(player)
		local function OnForfeitedQuest(_player)
			if _player[fn_name] ~= nil then
        		_player[fn_name]:Cancel()
    		end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["do work type z for x amount of y"] = function(player,worktype,workable,how_many,quest_name, bool)
		local amount = GetCurrentAmount(player,quest_name)
		workable = type(workable) == "string" and {[workable] = true} or workable
		local ListenForEventFinishedWork
		local function UpdateQuest()
			amount = amount + 1
			player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
			if amount >= how_many then
				player:RemoveEventCallback("working",ListenForEventFinishedWork)
			end
		end
		ListenForEventFinishedWork = function(_, data)
			local action = data.target.components.workable and data.target.components.workable.action
			if worktype == nil or action == worktype then
				if workable == nil or workable[data.target.prefab] then
					if bool == nil or bool(data.target) then
						UpdateQuest()
					end
				end
			end
		end
		player:ListenForEvent("working",ListenForEventFinishedWork)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("working",ListenForEventFinishedWork)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["finish work type z for x amount of y"] = function(player,worktype,workable,how_many,quest_name)
		local amount = GetCurrentAmount(player,quest_name)
		workable = type(workable) == "string" and {[workable] = true} or workable
		local ListenForEventFinishedWork
		local function UpdateQuest()
			amount = amount + 1
			player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
			if amount >= how_many then
				player:RemoveEventCallback("working",ListenForEventFinishedWork)
			end
		end
		ListenForEventFinishedWork = function(_, data)
			local action = data.action
			if worktype == nil or action == worktype then
				if workable == nil or workable[data.target.prefab] then
					UpdateQuest()
				end
			end
		end
		player:ListenForEvent("finishedwork",ListenForEventFinishedWork)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("finishedwork",ListenForEventFinishedWork)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["find x amount of y by working"] = function(player,loots,how_many,quest_name)
		local amount = GetCurrentAmount(player,quest_name)
		local targets = {}
		loots = type(loots) == "string" and {[loots] = true} or loots
		local ListenForEventWorkable = function() end
		local function LookForLoot(object,data)
			targets[object.GUID] = nil
			if data and data.loot then
				if loots == nil or loots[data.loot.prefab] then
					amount = amount + 1
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if amount >= how_many then
						player:RemoveEventCallback("working",LookForLoot)
					end
				end
			end
		end
		ListenForEventWorkable = function(_,data)
			if data and data.target and targets[data.target.GUID] == nil then
				data.target:ListenForEvent("loot_prefab_spawned",LookForLoot)
				targets[data.target.GUID] = true
				player:DoTaskInTime(5, function()
					targets[data.target.GUID] = nil
				end)
			end
		end
		player:ListenForEvent("working",ListenForEventWorkable)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("working",LookForLoot)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["get hit x times by charlie"] = function(player,amount,quest_name)
		local hits = GetCurrentAmount(player,quest_name)
		local function OnHitByGrue(_player)
			hits = hits + 1
			_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
			if hits >= amount then
				_player:RemoveEventCallback("attackedbygrue",OnHitByGrue)
			end
		end
		player:ListenForEvent("attackedbygrue",OnHitByGrue)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("attackedbygrue",OnHitByGrue)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["trade x amount of item y with pigking"] = function(player,amount,trade_item,quest_name,callback)
		local trades = GetCurrentAmount(player,quest_name)
		local pigking = TheSim:FindFirstEntityWithTag("king")
		if not pigking then
			print("pigking could not be found, aborting quest", quest_name)
			return
		end
		trade_item = type(trade_item) == "string" and {[trade_item] = true} or trade_item
		local function OnTrade(_,data)
			devprint("OnTrade", player,amount,trade_item,quest_name,data.item)
			if data then
				if data.giver == player then
					if trade_item == nil or data.item and trade_item[data.item.prefab] then
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						trades = trades  + 1
						if trades >= amount then
							pigking:RemoveEventCallback("quest_update",OnTrade)
							if callback then
								callback(player)
							end
						end
					end
				end
			end
		end 
		pigking:ListenForEvent("trade",OnTrade)
		local function OnForfeitedQuest(_pigking)
			_pigking:RemoveEventCallback("quest_update",OnTrade)
			if callback then
				callback(player)
			end
		end
		OnForfeit(pigking,OnForfeitedQuest,quest_name)
	end,

	["catch x amount of y fish"] = function(player,amount,fish,quest_name)
		local fishes = GetCurrentAmount(player,quest_name)
		local function OnCaughtFish(inst, caught_fish)
			if caught_fish and (fish == nil or caught_fish.prefab == fish) then
				player:PushEvent("quest_update",{quest = quest_name,amount = 1})
				fishes = fishes  + 1
				if fishes >= amount then
					inst:RemoveEventCallback("caught_fish", OnCaughtFish)
				end
			end
		end

		player:ListenForEvent("caught_fish", OnCaughtFish)

		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("caught_fish", OnCaughtFish)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["teleport x times y away"] = function(player,amount,targeted,quest_name)
		local old_ondone
		local teleports = GetCurrentAmount(player,quest_name)
		local OnTelePortTarget
		local function OnEquipStaff(_,data)
			if data and data.eslot == EQUIPSLOTS.HANDS then
				local spellcaster = data.item.components.spellcaster
				if data.item.prefab == "telestaff" and spellcaster ~= nil then
					old_ondone = spellcaster.onspellcast or function() end
					spellcaster.onspellcast = function(item,target,pos,...)
						OnTelePortTarget(item,target,pos)
						return old_ondone(item,target,pos,...)
					end
				end
			end
		end
		local function OnUnEquipStaff(_,data)
			if data and data.item and data.eslot == EQUIPSLOTS.HANDS then
				local spellcaster = data.item.components.spellcaster
				if data.item.prefab == "telestaff" and spellcaster ~= nil and old_ondone ~= nil then
					spellcaster.onspellcast = old_ondone
				end
			end
		end
		OnTelePortTarget = function(staff,target)
			if target and (targeted == nil or target.prefab == targeted) then
				player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			end
			if teleports >= amount then 
				staff.components.spellcaster.onspellcast = old_ondone
				player:RemoveEventCallback("equip",OnEquipStaff)
				player:RemoveEventCallback("unequip",OnUnEquipStaff)
			end
		end
		player:ListenForEvent("equip",OnEquipStaff)
		player:ListenForEvent("unequip",OnUnEquipStaff)
		if player.components.inventory then
			local handitem = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if handitem and handitem.prefab == "telestaff" then
				OnEquipStaff(player,{eslot = EQUIPSLOTS.HANDS,item = handitem})
			end
		end
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("equip",OnEquipStaff)
			_player:RemoveEventCallback("unequip",OnUnEquipStaff)
			if _player.components.inventory then
				local handitem = _player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				if handitem and handitem.prefab == "telestaff" then
					local spellcaster = handitem.components.spellcaster
					if spellcaster ~= nil and old_ondone ~= nil then
						spellcaster.onspellcast = old_ondone
					end
				end
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["acquire x followers that are y"] = function(player,amount,fan,quest_name)
		local function CountFollowerLeader(_player)
			local num = 0
			for k in pairs(_player.components.leader.followers) do
				if fan == nil or k.prefab == fan then
					if k.components.health == nil or not k.components.health:IsDead() then
						num = num + 1
					end
				end
			end
			return num
		end
		if player.components.leader then
			local num = CountFollowerLeader(player)
			player:PushEvent("quest_update",{quest = quest_name,set_amount = num})
		end
		local function RemoveFollower()
			local num = CountFollowerLeader(player)
			player:PushEvent("quest_update",{quest = quest_name,set_amount = num})
		end
		local function CountFollowers(_player, data)
			if _player and _player.components.leader and (fan == nil or (data.follower ~= nil and fan == data.follower.prefab)) then
				local num = CountFollowerLeader(_player)
				_player:PushEvent("quest_update",{ quest = quest_name, set_amount = num})
				if num >= amount then
					_player:RemoveEventCallback("added_follower",CountFollowers)
				end
			end
			if data and data.follower and (fan == nil or fan == data.follower.prefab) then
				data.follower:ListenForEvent("stopfollowing",RemoveFollower)
			end
		end
		player:ListenForEvent("added_follower",CountFollowers)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("added_follower",CountFollowers)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["defend moonbase x times"] = function(player,amount,quest_name)
		local defended = GetCurrentAmount(player,quest_name)
		local function CheckIfMoonStaff(_,data)
			if data and data.loot and data.loot.prefab == "opalstaff" then
				defended = defended + 1
				player:PushEvent("quest_update",{quest = quest_name,amount = 1,friendly_goal = true})
				if defended >= amount then
					player:RemoveEventCallback("picksomething",CheckIfMoonStaff)
				end
			end
		end
		player:ListenForEvent("picksomething",CheckIfMoonStaff)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("picksomething",CheckIfMoonStaff)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["build x y times"] = function(player,amount,structure,quest_name)
		local built = GetCurrentAmount(player,quest_name)
		local function OnBuild(inst,data)
			if data and data.item and (structure == nil or data.item.prefab == structure) then
				built = built + 1
				player:PushEvent("quest_update",{quest = quest_name,amount = 1})
				if built >= amount then
					inst:RemoveEventCallback("buildstructure",OnBuild)
				end
			end
		end
		player:ListenForEvent("buildstructure",OnBuild)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("buildstructure",OnBuild)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["craft x y times"] = function(player,amount,items,tab,quest_name,tech)
		local built = GetCurrentAmount(player,quest_name)
		items = type(items) == "string" and {[items] = true} or items
		local OnBuild
		local function UpdateQuest()
			built = built + 1
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			if built >= amount then
				player:RemoveEventCallback("builditem",OnBuild)
			end
		end
		OnBuild = function(_,data)
			if data then
				if data.recipe and (tab == nil or (CRAFTING_FILTERS[tab] and CRAFTING_FILTERS[tab].default_sort_values[data.recipe.name])) then
					if tech == nil or data.recipe.level[tech[1]] >= tech[2] then
						if items == nil or items[data.item.prefab] then
							UpdateQuest()
						end
					end
				end
			end
		end
		player:ListenForEvent("builditem",OnBuild)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("builditem",OnBuild)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["harvest x veggies y times"] = function(player,amount,veggie,quest_name)
		local harvested = GetCurrentAmount(player,quest_name)
		local function OnHarvestedPlants(farmplant, data)
			local veg = data.loot and data.loot[1]
			if veg then
				if veggie == nil or veg.prefab == veggie then
					harvested = harvested + 1
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					if harvested >= amount then
						player:RemoveEventCallback("picksomething",OnHarvestedPlants)
					end
				end
			end
		end
		player:ListenForEvent("picksomething",OnHarvestedPlants)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("picksomething",OnHarvestedPlants)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["harvest x oversized y times with a weight of z"] = function(player,amount,veggie,size,quest_name)
		local harvested = GetCurrentAmount(player,quest_name)
		size = size or 0
		local function OnHarvestedOversized(farmplant, data)
			local veg = data.loot and data.loot[1]
			if veg then
				if veggie == nil or veg.prefab == veggie then
					if veg.components.weighable then
						local weight = veg.components.weighable:GetWeight()
						if weight and weight >= size then
							harvested = harvested + 1
							player:PushEvent("quest_update",{quest = quest_name,amount = 1})
							if harvested >= amount then
								player:RemoveEventCallback("picksomething",OnHarvestedOversized)
							end
						end
					end
				end
			end
		end
		player:ListenForEvent("picksomething",OnHarvestedOversized)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("picksomething",OnHarvestedOversized)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["plant veggie y x times"] = function(player,amount,veggie,quest_name)
		local planted = GetCurrentAmount(player,quest_name)
		local function OnItemPlanted(src, data)
			if not data then
				--shouldn't happen
			elseif data.doer == player then
				planted = planted + 1
				player:PushEvent("quest_update",{quest = quest_name,amount = 1})
				if planted >= amount then
					player:RemoveEventCallback("itemplanted",OnItemPlanted)
				end
			end
		end
		player:ListenForEvent("itemplanted", OnItemPlanted, TheWorld)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("itemplanted", OnItemPlanted, TheWorld)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["hunt x y times"] = function(player,amount,creature,quest_name)
		local hunted_amount = GetCurrentAmount(player,quest_name)
		local creatures = {"koalefant_summer","koalefant_winter","warg","spat","lightninggoat",}
		local function OnHunted()
			local pos = Vector3(player.Transform:GetWorldPosition())
            local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 45)
            if creature ~= nil then
	            local hunted 
	            for _,v in ipairs(ents) do
	                for _,crea in ipairs(creatures) do
	                	if v.prefab == crea then
	                		hunted = v
	                		break
	                	end
	                end
	            end
	            if hunted ~= nil then
	            	player:PushEvent("quest_update",{quest = quest_name,amount = 1})
	            	hunted_amount = hunted_amount + 1
	            	if hunted_amount >= amount then
	            		player:RemoveEventCallback("huntbeastnearby",OnHunted)
	            	end
	            end
	        else
	        	player:PushEvent("quest_update",{quest = quest_name,amount = 1})
	        	hunted_amount = hunted_amount + 1
	            if hunted_amount >= amount then
	            	player:RemoveEventCallback("huntbeastnearby",OnHunted)
	            end
	        end
		end
		player:ListenForEvent("huntbeastnearby",OnHunted)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("huntbeastnearby",OnHunted)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["capture x y times"] = function(player,amount,creatures,quest_name)
		local caught = GetCurrentAmount(player,quest_name)
		creatures = type(creatures) == "string" and {[creatures] = true} or creatures
		local function OnSomethingTrapped(_,data)
			if data and data.trap then
				if data.trap.components.trap ~= nil and data.trap.components.trap.lootprefabs ~= nil then
					local caught_creature = unpack(data.trap.components.trap.lootprefabs)
					if creatures == nil or creatures[caught_creature] then
						caught = caught + 1
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						if caught >= amount then
							player:RemoveEventCallback("trapped_something",OnSomethingTrapped)
						end
					end
				end
			end
		end
		player:ListenForEvent("trapped_something",OnSomethingTrapped)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("trapped_something",OnSomethingTrapped)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["protect x from y creatures z times"] = function(player,times,amount,rounds,delta,difficulty,creature,quest_name,min,max)
		times = times or 1
		local current = GetCurrentAmount(player,quest_name)
		local OnWin = function() end
		local AttackWave
		local fn_name = "attackwave_"..quest_name
		local function OnLose(inst,victim)
			if victim == creature and inst.components.quest_component then
				inst.components.quest_component:RemoveQuest(quest_name)
				inst:RemoveEventCallback("succesfully_defended",OnWin)
				inst:RemoveEventCallback("victim_died",OnLose)
				SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),player.userid,player,creature)
			end
		end
		OnWin = function(_)
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			player:RemoveEventCallback("succesfully_defended",OnWin)
			player:RemoveEventCallback("victim_died",OnLose)
			current = current + 1
			if current < times then
				AttackWave(player,times,amount,rounds,delta,difficulty,creature,quest_name,min,max)
			end
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"),player.userid,player,creature)
		end
		AttackWave = function(player,amount,rounds,delta,difficulty,creature,min,max)
			min = min or 120
			max = max or 200
			local time = math.random(min,max)
			local attacksize = {amount,rounds}
			local function StartWaves()
				devprint("starting waves")
				GLOBAL.TheWorld.components.attackwaves:StartAttack(player,attacksize,delta,difficulty,creature)
			end
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddTimerToClient"),player.userid,player,time,creature)
			player[fn_name] = player:DoTaskInTime(time,StartWaves)

			player:ListenForEvent("succesfully_defended",OnWin)
			player:ListenForEvent("victim_died",OnLose)
		end
		AttackWave(player,amount,rounds,delta,difficulty,creature,min,max)
		local function OnForfeitedQuest(_player)
			if _player[fn_name] ~= nil then
				_player[fn_name]:Cancel()
				_player[fn_name] = nil
			end
			_player:RemoveEventCallback("succesfully_defended",OnWin)
			_player:RemoveEventCallback("victim_died",OnLose)
			SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "RemoveTimerFromClient"), _player.userid, _player, creature)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["stay x seconds over/under y temperature"] = function(player,period,temperature,smaller_or_bigger,at_once,quest_name)
		local time = GetCurrentAmount(player,quest_name)
		local fn_name = "check_temperature_quest_"..quest_name
		local function CheckTemperature(_player)
			local temperature_cmp = _player.components.temperature
			if temperature_cmp then
				if (smaller_or_bigger == 0 and temperature_cmp:GetCurrent() < temperature or smaller_or_bigger == 1 and temperature_cmp:GetCurrent() > temperature) then
					time = time + 1
					_player:PushEvent("quest_update",{ quest = quest_name, amount = 1})
					if time >= period then
						_player[fn_name] = nil
						return
					end
				else
					if at_once == true and time ~= 0 then
						time = 0
						_player:PushEvent("quest_update",{ quest = quest_name, reset = true})
					end
				end
			end
			_player[fn_name] = _player:DoTaskInTime(1,CheckTemperature)
		end
		if player[fn_name] ~= nil then
        	player[fn_name]:Cancel()
        	player[fn_name] = nil
    	end
		CheckTemperature(player)
		local function OnForfeitedQuest(_player)
			if _player[fn_name] ~= nil then
        		_player[fn_name]:Cancel()
        		_player[fn_name] = nil
    		end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["get hit x times by a lightning strike"] = function(player,amount,quest_name)
		local times = GetCurrentAmount(player,quest_name)
		local playerlightningtarget = player.components.playerlightningtarget
		if playerlightningtarget ~= nil then
			local old_fn = playerlightningtarget.onstrikefn
			playerlightningtarget:SetOnStrikeFn(function(inst,...)
				times = times + 1
				player:PushEvent("quest_update",{quest = quest_name,amount = 1})
				if times >= amount then
					playerlightningtarget.onstrikefn = old_fn
				end
				return unpack{old_fn(inst,...)}
			end)
			local function OnForfeitedQuest(_player)
				playerlightningtarget.onstrikefn = old_fn
			end
			OnForfeit(player,OnForfeitedQuest,quest_name)
		end
	end,

	["heal x amount of life with y"] = function(player,amount,item,quest_name)
		local current_amount = GetCurrentAmount(player,quest_name)
		local function OnHealthDelta(_,data)
			if data then
				if data.amount > 0 then
					if item == nil or data.cause == item then
						local health = player.components.health
						local old_health = data.oldpercent * health.maxhealth
						local new_health = data.newpercent * health.maxhealth
						local change = new_health - old_health
						if change > 0 then
							current_amount = current_amount + new_health - old_health
							player:PushEvent("quest_update",{quest = quest_name,amount = change})
							if current_amount >= amount then
								player:RemoveEventCallback("healthdelta",OnHealthDelta)
							end

						end
					end
				end
			end
		end
		player:ListenForEvent("healthdelta",OnHealthDelta)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("healthdelta",OnHealthDelta)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["damage x amount of life with y"] = function(player,amount,cause,quest_name)
		local current_amount = GetCurrentAmount(player,quest_name)
		local function OnHealthDelta(_,data)
			if data then
				if data.amount < 0 then
					devprint("damage x amount of life with y",player,amount,cause,quest_name,data.amount,data.cause)
					if cause == nil or data.cause == cause then
						current_amount = current_amount - data.amount
						player:PushEvent("quest_update",{quest = quest_name,amount = -data.amount})
						if current_amount >= amount then
							player:RemoveEventCallback("healthdelta",OnHealthDelta)
						end
					end
				end
			end
		end
		player:ListenForEvent("healthdelta",OnHealthDelta)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("healthdelta",OnHealthDelta)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["deal x amount of damage"] = function(player,amount,weapon,quest_name,target)
		local current_amount = GetCurrentAmount(player,quest_name)
		target = type(target) == "string" and {[target] = true} or target
		local function OnDamageDone(_,data)
			if data then
				if data.damageresolved > 0 then
					if weapon == nil or data.weapon and data.weapon.prefab == weapon then
						if target == nil or data.target and target[data.target.prefab] then
							current_amount = current_amount + data.damageresolved
							player:PushEvent("quest_update",{quest = quest_name,amount = data.damageresolved})
							if current_amount >= amount then
								player:RemoveEventCallback("onhitother",OnDamageDone)
							end
						end
					end
				end
			end
		end
		player:ListenForEvent("onhitother",OnDamageDone)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("onhitother",OnDamageDone)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["deal x amount of damage in time y with weapon z"] = function(player,amount,weapon,time,quest_name)
		local damages = {}
		local current_time = GetTime()
		local function OnDamageDone(inst,data)
			if data then
				if data.damageresolved > 0 then
					if weapon == nil or data.weapon and data.weapon.prefab == weapon then
						local current_time2 = GetTime()
						damages[current_time2] = data.damageresolved
						for k,v in pairs(damages) do
							if current_time2 - k > time then
								damages[k] = nil
							end
						end
						inst:DoTaskInTime(0,function()
							local damage = 0
							for _,v in pairs(damages) do
								damage = damage + v
							end
							player:PushEvent("quest_update",{quest = quest_name,set_amount = damage})
							if damage >= amount then
								player:RemoveEventCallback("onhitother",OnDamageDone)
							end
						end)
					end
				end
			end
		end
		player:ListenForEvent("onhitother",OnDamageDone)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("onhitother",OnDamageDone)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["defend x amount of damage"] = function(player,amount,quest_name)
		local current_amount = GetCurrentAmount(player,quest_name)
		local function OnDamageDefended(_,data)
			if data then
				if not data.redirected and data.original_damage > 0 then
					if data.original_damage > data.damageresolved then
						local defended = data.original_damage - data.damageresolved
						current_amount = current_amount + defended
						player:PushEvent("quest_update",{quest = quest_name,amount = defended})
						if current_amount >= amount then
							player:RemoveEventCallback("attacked",OnDamageDefended)
						end
					end
				end
			end
		end
		player:ListenForEvent("attacked",OnDamageDefended)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("attacked",OnDamageDefended)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["cast spell x y times"] = function(player, amount, quest_name, spellcasters, targets, bool, post_fn)
		local current_amount = GetCurrentAmount(player,quest_name)
		spellcasters = type(spellcasters) == "string" and {[spellcasters] = true} or spellcasters
		targets = type(targets) == "string" and {[targets] = true} or targets
		local OnCastSpell
		local function UpdateQuest()
			current_amount = current_amount + 1
			player:PushEvent("quest_update",{quest = quest_name, amount = 1})
			if current_amount >= amount then
				player:RemoveEventCallback("cast_spell",OnCastSpell)
			end
		end
		OnCastSpell = function(_,data)
			if data then
				if spellcasters == nil or data.spellcaster and spellcasters[data.spellcaster.prefab] then
					if targets == nil or data.target and targets[data.target.prefab] then
						if bool == nil or bool(player, data) then
							if post_fn == nil then
								UpdateQuest()
							else
								post_fn(player, data, UpdateQuest)
							end
						end
					end
				end
			end
		end
		player:ListenForEvent("cast_spell",OnCastSpell)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("cast_spell",OnCastSpell)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["deploy x y times"] = function(player,amount,item,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		item = type(item) == "string" and {[item] = true} or item
		local function OnDeployed(_,data)
			if data and data.prefab then
				if item == nil or item[data.prefab] then
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						player:RemoveEventCallback("deployitem",OnDeployed)
					end
				end
			end
		end
		player:ListenForEvent("deployitem",OnDeployed)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("deployitem",OnDeployed)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["sew x times"] = function(player,amount,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local function OnRepaired(inst)
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("repair",OnRepaired)
			end
		end
		player:ListenForEvent("repair",OnRepaired)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("repair",OnRepaired)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["stay x amount of time on y boat"] = function(player,amount,boat,at_once,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local OnEmbarked = function() end
		local fn_name = "ocean_check_task_"..quest_name
		local function CheckIfOcean(inst)
			if player[fn_name] ~= nil then
				player[fn_name] :Cancel()
				player[fn_name]  = nil
			end
			if player:IsOnOcean(true) then
				if boat == nil or player:GetCurrentPlatform().prefab == boat then
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						if player[fn_name] ~= nil then
							player[fn_name]:Cancel()
							player[fn_name] = nil
						end
						player:RemoveEventCallback("done_embark_movement",OnEmbarked)
						return
					end
				end
			end
			player[fn_name] = inst:DoTaskInTime(1,CheckIfOcean)
		end
		OnEmbarked = function(inst)
			if player:IsOnOcean(true) ~= nil then
				CheckIfOcean(inst)
			else
				if player[fn_name] ~= nil then
					player[fn_name]:Cancel()
					player[fn_name] = nil
				end
				if at_once == true then
					player:PushEvent("quest_update",{quest = quest_name,reset = true})
				end
			end
		end
		player:ListenForEvent("done_embark_movement",OnEmbarked)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("done_embark_movement",OnEmbarked)
			if _player[fn_name] ~= nil then
				_player[fn_name]:Cancel()
				_player[fn_name] = nil
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["fertilize x y times with z"] = function(player,amount,plant_tag,fertilizer,quest_name,ground)
		local current = GetCurrentAmount(player,quest_name)
		local function OnFertilized(_,data)
			if data then
				if plant_tag == nil or (data.target and data.target:HasTag(plant_tag) == true) then
					if fertilizer == nil or (data.fertilizer == fertilizer) then
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						current = current + 1
						if current >= amount then
							player:RemoveEventCallback("has_fertilized",OnFertilized)
						end
					end
				end
			end
		end
		local function OnFertilizedGround(_,data)
			if data then
				if fertilizer == nil or (data.fertilizer == fertilizer) then
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						player:RemoveEventCallback("has_fertilized_ground",OnFertilizedGround)
					end
				end
			end
		end
		local OnForfeitedQuest
		if ground == true then
			player:ListenForEvent("has_fertilized_ground",OnFertilizedGround)
			OnForfeitedQuest = function()
				player:RemoveEventCallback("has_fertilized_ground",OnFertilizedGround)
			end
		else
			player:ListenForEvent("has_fertilized",OnFertilized)
			OnForfeitedQuest = function()
				player:RemoveEventCallback("has_fertilized",OnFertilized)
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["do x y times in z days"] = function(player,amount,min,start_event,quest_name)
		min = min or 8
		local quest_component = player.components.quest_component
		local fn_name = "time_up"..quest_name
		local seconds = min * 60
		local time = GetValues(player,quest_name,"time")
		local initial_time = GetTime()
		local has_started = false
		local StartTime
		local function OnPlayerLeft()
			if has_started then
				local exit_time = GetTime()
				time = time + (exit_time - initial_time)
				quest_component:SetQuestData(quest_name,"time",time)
			end
		end
		TheWorld:ListenForEvent("ms_playerdespawn",OnPlayerLeft)
		TheWorld:ListenForEvent("ms_save",OnPlayerLeft)
		TheWorld:ListenForEvent("master_autosaverupdate",OnPlayerLeft)
		local function TimeUp(inst)
			if quest_component then
				player.components.talker:Say("I was not fast enough...")
				quest_component:RemoveQuest(quest_name)
				RemoveValues(player,quest_name)
			end
			TheWorld:RemoveEventCallback("ms_playerdespawn",OnPlayerLeft)
			TheWorld:RemoveEventCallback("ms_save",OnPlayerLeft)
			TheWorld:RemoveEventCallback("master_autosaverupdate",OnPlayerLeft)
		end
		local function SayRemainingTime(_,remaining_time)
			OnPlayerLeft()
			if player.components.talker then
				local minutes = math.floor(remaining_time/60)
				local sec = math.floor(math.fmod(remaining_time,60))
				local time = (minutes == 0 and "0" or minutes)..":"..(sec < 10 and "0"..sec or sec)
				player.components.talker:Say(string.format("I have only %s minutes left to finish the quest %s!",tostring(time),quest_name))
			end
		end
		local times_to_speak = {0.25, 0.5, 0.75, 0.875, 0.95, 0.99}
		StartTime = function()
			has_started = true
			for _,v in ipairs(times_to_speak) do
				if seconds*v - time >= 0 then
					player[quest_name..v] = player:DoTaskInTime((seconds*v - time),SayRemainingTime,seconds*(1-v))
				end
			end
			SayRemainingTime(nil, seconds - time)
			player[fn_name] = player:DoTaskInTime((seconds-time),TimeUp)
			if start_event then
				player:RemoveEventCallback(start_event, StartTime)
			end
		end
		if time == 0 and start_event then
			player:ListenForEvent(start_event, StartTime)
		else
			StartTime()
		end
		local function KillTasks(_,name)
			if name == quest_name then
				for _,v in ipairs(times_to_speak) do
					local taskname = quest_name..v
					if player[taskname] ~= nil then
						player[taskname]:Cancel()
						player[taskname] = nil
					end
				end
			end
			player:RemoveEventCallback("finished_quest",KillTasks)
		end
		player:ListenForEvent("finished_quest",KillTasks)
		local function OnForfeitedQuest(_player)
			KillTasks(_player,quest_name)
			TheWorld:RemoveEventCallback("ms_playerdespawn",OnPlayerLeft)
			TheWorld:RemoveEventCallback("ms_save",OnPlayerLeft)
			TheWorld:RemoveEventCallback("master_autosaverupdate",OnPlayerLeft)
			if _player[fn_name] ~= nil then
				_player[fn_name]:Cancel()
				_player[fn_name] = nil
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["kill x y times"] = function(player,amount,victims,quest_name,check)
		local current = GetCurrentAmount(player,quest_name)
		victims = type(victims) == "string" and {[victims] = true} or victims
		local OnKilled
		local function UpdateQuest()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("killed",OnKilled)
				player:RemoveEventCallback("killedbyfriend", OnKilled)
			end
		end
		OnKilled = function(_,data)
			if data and data.victim then
				if check == nil or check(data.victim) then
					if victims == nil or victims[data.victim.prefab] then
						UpdateQuest()
					end
				end
			end
		end
		player:ListenForEvent("killed",OnKilled)
		player:ListenForEvent("killedbyfriend", OnKilled)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("killed",OnKilled)
			_player:RemoveEventCallback("killedbyfriend", OnKilled)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["kill different creatures x y times"] = function(player,amount,quest_name,victims,check)
		local current = GetCurrentAmount(player,quest_name)
		local listen_functions = {}
		local current_kills = {}
		for prefab, kill_amount in pairs(victims) do
			current_kills[prefab] = GetValues(player, quest_name, prefab)
			if current_kills[prefab] < kill_amount then
				local function OnKilled(_,data)
					if data and data.victim then
						if data.victim.prefab == prefab then
							if check == nil or check(data.victim) then
								player:PushEvent("quest_update",{quest = quest_name,amount = 1})
								current_kills[prefab] = current_kills[prefab] + 1
								SetValues(player, quest_name, prefab, current_kills[prefab])
								current = current + 1
								if current_kills[prefab] >= kill_amount then
									player:RemoveEventCallback("killed",OnKilled)
									player:RemoveEventCallback("killedbyfriend",OnKilled)
								end
								if current >= amount then
									for _, fn in pairs(listen_functions) do
										player:RemoveEventCallback("killed", fn)
										player:RemoveEventCallback("killedbyfriend", fn)
									end
								end
							end
						end
					end
				end
				player:ListenForEvent("killed",OnKilled)
				player:ListenForEvent("killedbyfriend", OnKilled)
				listen_functions[prefab] = OnKilled
			end
		end
		local function OnForfeitedQuest()
			for _, fn in pairs(listen_functions) do
				player:RemoveEventCallback("killed", fn)
				player:RemoveEventCallback("killedbyfriend", fn)
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["die x times from y by z"] = function(player,amount,cause,afflicter,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local function OnDied(_,data)
			devprint("OnDied", data.cause, data.afflicter)
			if data then
				if cause == nil or data.cause == cause then
					if afflicter == nil or data.afflicter and data.afflicter.prefab == afflicter then
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						current = current + 1
						if current >= amount then
							player:RemoveEventCallback("death",OnDied)
						end
					end
				end
			end
		end
		player:ListenForEvent("death",OnDied)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("death",OnDied)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["survive x days"] = function(player, amount, quest_name, at_once)
		local current = GetCurrentAmount(player,quest_name)
		local OnDied = function() end
		local function OnNewDay(_, isday)
			if isday then
				player:PushEvent("quest_update",{quest = quest_name, amount = 1})
				current = current + 1
				if current >= amount then
					player:RemoveEventCallback("death", OnDied)
					player:StopWatchingWorldState("isday", OnNewDay)
				end
			end
		end
		if at_once then
			OnDied = function()
				player:PushEvent("quest_update",{quest = quest_name, reset = true})
			end
		end
		player:WatchWorldState("isday", OnNewDay)
		player:ListenForEvent("death",OnDied)
		local function OnForfeitedQuest()
			player:RemoveEventCallback("death", OnDied)
			player:StopWatchingWorldState("isday", OnNewDay)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["gain x levels"] = function(player,amount,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local function OnLevelUp()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("q_s_levelup",OnLevelUp)
			end
		end
		player:ListenForEvent("q_s_levelup",OnLevelUp)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("q_s_levelup",OnLevelUp)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["finish x quests of difficulty y"] = function(player,amount,difficulty,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local function OnFinishedQuest(_,name)
			if name and quest_name ~= name then
				local quest = QUEST_COMPONENT.QUESTS[name]
				if difficulty == nil or (quest and quest.difficulty == difficulty) then
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
					current = current + 1
					if current >= amount then
						player:RemoveEventCallback("finished_quest",OnFinishedQuest)
					end
				end
			end
		end
		player:ListenForEvent("finished_quest",OnFinishedQuest)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("finished_quest",OnFinishedQuest)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["harvest x times y food with z ingredients from cookpot"] = function(player,amount,food,ingredients,quest_name)
		--ingredients is a table of ingredients that should be used for cooking
		local current = GetCurrentAmount(player,quest_name)
		local function OnCooked(_,data)
			if data then
				if food == nil or data.product == food then
					if ingredients == nil then
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						current = current + 1
						if current >= amount then
							player:RemoveEventCallback("learncookbookrecipe",OnCooked)
						end
					else
						data.ingredients = data.ingredients or {}
						for key,ingredient in ipairs(ingredients) do
							if table.removetablevalue(data.ingredients,ingredient) ~= nil then
								ingredients[key] = nil
							end
						end
						if next(ingredients) == nil then
							player:PushEvent("quest_update",{quest = quest_name,amount = 1})
							current = current + 1
							if current >= amount then
								player:RemoveEventCallback("learncookbookrecipe",OnCooked)
							end
						end
					end
				end
			end
		end
		player:ListenForEvent("learncookbookrecipe",OnCooked)
		local function OnForfeitedQuest(_player)
			_player:RemoveEventCallback("learncookbookrecipe",OnCooked)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["kill x y with follower z"] = function(player,amount,victim,followers,quest_name)
		--followers is a table with accepted followers in the format {spider = true}
		local kills = GetCurrentAmount(player,quest_name)
		local possible_follower = followers
		local function IsPossibleFollower(follower)
			if follower and follower.prefab then
				return possible_follower[follower.prefab]
			end
		end
		local OnAddFollower = function() end
		local function OnKilled(follower,data)
			if data then
				if data.victim then
					if data.victim.prefab == victim then
						player:PushEvent("quest_update",{quest = quest_name,amount = 1})
						if kills >= amount then
							follower:RemoveEventCallback("killed",OnKilled)
							player:RemoveEventCallback("added_follower",OnAddFollower)
						end
					end
				end
			end
		end
		OnAddFollower = function(player,data)
			if data and data.follower and IsPossibleFollower(data.follower) then
				data.follower:ListenForEvent("killed",OnKilled)
			end
		end
		if player.components.leader then
			for k in pairs(player.components.leader.followers) do
				if IsPossibleFollower(k) then
					k:ListenForEvent("killed",OnKilled)
				end
			end
		end
		player:ListenForEvent("added_follower",OnAddFollower)
		local function OnForfeitedQuest(player)
			player:RemoveEventCallback("added_follower",OnAddFollower)
			for k in pairs(player.components.leader.followers) do
				if IsPossibleFollower(k) then
					k:RemoveEventCallback("killed",OnKilled)
				end
			end
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["do x each second for y seconds"] = function(player,amount,bool,time_between_check,quest_name)
		local current = GetCurrentAmount(player,quest_name)
		local fn_name = quest_name.."_task"
		local function CheckBool(_player)
			if bool == nil or bool(_player,amount,quest_name) then
				current = current + 1
				_player:PushEvent("quest_update",{ quest = quest_name, amount = time_between_check})
				if current >= amount then
					StopTask(player, fn_name)
					return
				end
			end
			_player:DoTaskInTime(time_between_check,CheckBool)
		end
		StopTask(player, fn_name)
		CheckBool(player)
		local function OnForfeitedQuest()
			StopTask(player, fn_name)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["do x each second for y seconds with event"] = function(player, amount, quest_name, bool, time_between_check, event)
		local current = GetCurrentAmount(player,quest_name)
		local fn_name = quest_name.."_task"
		local function CheckBool(inst, data)
			StopTask(inst, quest_name.."_task")
			if bool == nil or bool(player, amount, quest_name, inst, data) then
				player[quest_name.."_task"] = player:DoPeriodicTask(1, function()
					current = current + 1
					player:PushEvent("quest_update",{ quest = quest_name, amount = time_between_check})
					if current >= amount then
						StopTask(player, fn_name)
						player:RemoveEventCallback(event, CheckBool)
						return
					end
				end)
			end
			player:DoTaskInTime(time_between_check,CheckBool)
		end
		StopTask(player, fn_name)
		player:ListenForEvent(event, CheckBool)
		local function OnForfeitedQuest()
			StopTask(player, fn_name)
			player:RemoveEventCallback(event, CheckBool)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["construct site x y times"] = function(player, amount, quest_name, constructionsites)
		local current = GetCurrentAmount(player,quest_name)
		constructionsites = type(constructionsites) == "string" and {[constructionsites] = true} or constructionsites
		local OnFinishConstruction
		local function UpdateQuest()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("finish_construction", OnFinishConstruction)
			end
		end
		OnFinishConstruction = function(_, data)
			--devprint("OnFinishConstruction", data.constructionsite, data.constructionsite and data.constructionsite.components.constructionsite:IsComplete())
			if data.constructionsite and data.constructionsite.components.constructionsite:IsComplete() then
				if constructionsites == nil or constructionsites[data.constructionsite.prefab] then
					UpdateQuest()
				end
			end
		end

		player:ListenForEvent("finish_construction", OnFinishConstruction)
		local function OnForfeitedQuest()
			player:RemoveEventCallback("finish_construction", OnFinishConstruction)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["feed x y times"] = function(player, amount, quest_name, targets, foods, bool, post_fn)
		local current = GetCurrentAmount(player,quest_name)
		targets = type(targets) == "string" and {[targets] = true} or targets
		foods = type(foods) == "string" and {[foods] = true} or foods
		local OnFedCreature
		local function UpdateQuest()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("fed_creature", OnFedCreature)
			end
		end
		OnFedCreature = function(_, data)
			--devprint("OnFedCreature", data.target, data.food, data.food and foods and foods[data.food.prefab], data.target and targets and targets[data.target.prefab])
			if data and data.target and data.food then
				if targets == nil or targets[data.target.prefab] then
					if foods == nil or foods[data.food.prefab] then
						if bool == nil or bool(player, data) then
							if post_fn == nil then
								UpdateQuest()
							else
								post_fn(player, data, UpdateQuest)
							end
						end
					end
				end
			end
		end

		player:ListenForEvent("fed_creature", OnFedCreature)
		local function OnForfeitedQuest()
			player:RemoveEventCallback("fed_creature", OnFedCreature)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["start fire with x y times"] = function(player, amount, quest_name, targets, tools, bool)
		local current = GetCurrentAmount(player,quest_name)
		targets = type(targets) == "string" and {[targets] = true} or targets
		tools = type(tools) == "string" and {[tools] = true} or tools
		local OnStartedFire
		local function UpdateQuest()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("onstartedfire", OnStartedFire)
			end
		end
		OnStartedFire = function(_, data)
			--devprint("OnStartedFire", data.target)
			if data and data.target then
				if targets == nil or targets[data.target.prefab] then
					local hand = player.components.inventory and player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if tools == nil or tools[hand.prefab] then
						if bool == nil or bool(player, data) then
							UpdateQuest()
						end
					end
				end
			end
		end

		player:ListenForEvent("onstartedfire", OnStartedFire)
		local function OnForfeitedQuest()
			player:RemoveEventCallback("onstartedfire", OnStartedFire)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	["get hit by x for y times during earthquakes"] = function(player, amount, quest_name, debris, bool)
		local current = GetCurrentAmount(player,quest_name)
		debris = type(debris) == "string" and {[debris] = true} or debris
		local OnHitByDebris
		local function UpdateQuest()
			player:PushEvent("quest_update",{quest = quest_name,amount = 1})
			current = current + 1
			if current >= amount then
				player:RemoveEventCallback("attacked", OnHitByDebris)
			end
		end
		OnHitByDebris = function(_, data)
			if data and data.attacker and data.attacker.shadow ~= nil then
				if debris == nil or debris[data.attacker.prefab] then
					if bool == nil or bool(player, data) then
						UpdateQuest()
					end
				end
			end
		end

		player:ListenForEvent("attacked", OnHitByDebris)
		local function OnForfeitedQuest()
			player:RemoveEventCallback("attacked", OnHitByDebris)
		end
		OnForfeit(player,OnForfeitedQuest,quest_name)
	end,

	--[[["build x structures y in the vicinity of radius z"] = function(player,amount,structure,radius,quest_name)
		if player.components.quest_component == nil then return end
		local current = GetCurrentAmount(player,quest_name)
		local structures = GetValues(player,"structures",quest_name)
		if structures == 0 then
			player.components.quest_component:SetQuestData(quest_name,"structures",{})
		end
		local function OnBuild(inst,data)
			if data and data.item and (structure == nil or data.item.prefab == structure) then
				local quest_data = player.components.quest_component:GetQuestData(quest_name,"structures")
				local pos = data.item:GetPosition()
				if current == 0 then
					table.insert(quest_data,{pos})
					current = current + 1
					player:PushEvent("quest_update",{quest = quest_name,amount = 1})
				else
					local is_near = false
					for k,v in ipairs(quest_data) do
						for kk,vv in ipairs(v) do
							if data.item:GetDistanceSqToPoint(vv) <= radius then
								table.insert(vv,pos)
								is_near = true
							end
						end
					end
					if is_near == false then
						table.insert(quest_data,{pos})
					else
						local highest = 0
						for k,v in ipairs(quest_data) do
							if #v > highest then
								highest = #v
							end
						end
						current = highest
						player:PushEvent("quest_update",{quest = quest_name,set_amount = current})
						if current >= amount then
							inst:RemoveEventCallback("buildstructure",OnBuild)
							RemoveValues(player,quest_name)
						end
					end
					player.components.quest_component:SetQuestData(quest_name,"structures",quest_data)
				end					
			end
		end
		player:ListenForEvent("buildstructure",OnBuild)
	end,]]
}

QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS = custom_functions

local FunctionsForCustomQuests = {
	
	--Sanity
	{ 
		"Stay at over 90% Sanity for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"sanity",1,0.9,seconds,quest_name,true)
		end,
		"Seconds",
		"sanity.tex",
	},
	{ 
		"Stay at under 10% Sanity for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"sanity",0,0.1,seconds,quest_name,true,SANITY_MODE_INSANITY)
		end,
		"Seconds",
		"sanity.tex",
	},
	{ 
		"Stay at under 10% Lunacy for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"sanity",0,0.1,seconds,quest_name,true,SANITY_MODE_LUNACY)
		end,
		"Seconds",
		"celestial.tex",
	},
	{ 
		"Stay at over 90% Lunacy for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"sanity",1,0.9,seconds,quest_name,true,SANITY_MODE_LUNACY)
		end,
		"Seconds",
		"celestial.tex",
	},

	--Hunger
	{ 
		"Stay at over 90% Hunger for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"hunger",1,0.9,seconds,quest_name,true)
		end,
		"Seconds",
		"hunger.tex",
	},
	{ 
		"Stay at under 10% Hunger for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"hunger",0,0.1,seconds,quest_name,true)
		end,
		"Seconds",
		"hunger.tex",
	},
	--Health
	{ 
		"Stay at over 95% Health for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"health",1,0.95,seconds,quest_name,true)
		end,
		"Seconds",
		"health.tex",
	},
	{ 
		"Stay at under 5% Health for x seconds at once!",
		function(player,seconds,quest_name)
			custom_functions["stay x time"](player,"health",0,0.05,seconds,quest_name,true)
		end,
		"Seconds",
		"health.tex",
	},

	--Eating
	{
		"Eat x Monterlasagna",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"monsterlasagna",amount,quest_name)
		end,
		"Monterlasagna",
		"monsterlasagna.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Eat x Surf'n'Turf",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"surfnturf",amount,quest_name)
		end,
		"Surf'n'Turf",
		"surfnturf.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Eat x Wobster Dinner",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"lobsterdinner",amount,quest_name)
		end,
		"Wobster Dinner",
		"lobsterdinner.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Eat x Leafy Meatloaf",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"leafloaf",amount,quest_name)
		end,
		"Leafy Meatloaf",
		"leafloaf.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Eat x Jellybeans",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"jellybean",amount,quest_name)
		end,
		"Jellybeans",
		"jellybean.tex",
		"images/inventoryimages1.xml",
	},
	{	
		"Eat x Fig-Stuffed Trunk",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"koalefig_trunk",amount,quest_name)
		end,
		"Fig-Stuffed Trunk",
		"koalefig_trunk.tex",
		"images/inventoryimages.xml",
	},
	{
		"Eat x Barnacle Nigiri",
		function(player,amount,quest_name)
			custom_functions["eat x times y"](player,"barnaclesushi",amount,quest_name)
		end,
		"Barnacle Nigiri",
		"barnaclesushi.tex",
		"images/inventoryimages1.xml",
	},

	--Mining
	{
		"Find x Fossils by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"fossil_piece",amount,quest_name)
		end,
		"Fossils",
		"fossil_piece.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Find x Gold Nuggets by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"goldnugget",amount,quest_name)
		end,
		"Gold Nuggets",
		"goldnugget.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Find x Red Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"redgem",amount,quest_name)
		end,
		"Red Gems",
		"redgem.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Find x Blue Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"bluegem",amount,quest_name)
		end,
		"Blue Gems",
		"bluegem.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Find x Purple Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"purplegem",amount,quest_name)
		end,
		"Purple Gems",
		"purplegem.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Find x Green Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"greengem",amount,quest_name)
		end,
		"Green Gems",
		"greengem.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Find x Yellow Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"yellowgem",amount,quest_name)
		end,
		"Yellow Gems",
		"yellowgem.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Find x Orange Gems by Mining",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"orangegem",amount,quest_name)
		end,
		"Orange Gems",
		"orangegem.tex",
		"images/inventoryimages2.xml",
	},

	--Chopping
	{
		"Find x Living Logs by chopping",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"livinglog",amount,quest_name)
		end,
		"Living Logs",
		"livinglog.tex",
		"images/inventoryimages1.xml",
	},

	--Digging
	{
		"Find x Life Amulets by digging",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"amulet",amount,quest_name)
		end,
		"Life Amulet",
		"amulet.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Find x Gears by digging",
		function(player,amount,quest_name)
			custom_functions["find x amount of y by working"](player,"gears",amount,quest_name)
		end,
		"Gears",
		"gears.tex",
		"images/inventoryimages1.xml",
	},

	--Charlie
	{
		"Get hit x times by Charlie",
		function(player,amount,quest_name)
			custom_functions["get hit x times by charlie"](player,amount,quest_name)
		end,
		"Hits",
		"health.tex"
	},

	--Trades with Pig King
	{
		"Trade x times with the Pig King",
		function(player,amount,quest_name)
			custom_functions["trade x amount of item y with pigking"](player,amount,nil,quest_name)
		end,
		"Trades",
		"pigking.tex"
	},
	{
		"Trade x times a Dessicated Tentacle with the Pig King",
		function(player,amount,quest_name)
			custom_functions["trade x amount of item y with pigking"](player,amount,"trinket_12",quest_name)
		end,
		"Trades",
		"trinket_12.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Trade x times a Hardened Rubber Bung with the Pig King",
		function(player,amount,quest_name)
			custom_functions["trade x amount of item y with pigking"](player,amount,"trinket_8",quest_name)
		end,
		"Trades",
		"trinket_8.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Trade x times a Lucky Cat Jar with the Pig King",
		function(player,amount,quest_name)
			custom_functions["trade x amount of item y with pigking"](player,amount,"trinket_24",quest_name)
		end,
		"Trades",
		"trinket_24.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Trade x times a Potato Cup with the Pig King",
		function(player,amount,quest_name)
			custom_functions["trade x amount of item y with pigking"](player,amount,"trinket_26",quest_name)
		end,
		"Trades",
		"trinket_26.tex",
		"images/inventoryimages2.xml",
	},

	--Catch Fish
	{
		"Catch x Fishes",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,nil,quest_name)
		end,
		"Fishes",
		"fishing.tex",
	},
	{
		"Catch x Ice Bream",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_medium_8",quest_name)
		end,
		"Ice Breams",
		"oceanfish_medium_8_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Deep Bass",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_medium_2",quest_name)
		end,
		"Deep Basses",
		"oceanfish_medium_2_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Spittlefish",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_small_9",quest_name)
		end,
		"Spittlefishes",
		"oceanfish_small_9_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Scorching Sunfish",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_small_8",quest_name)
		end,
		"Scorching Sunfishes",
		"oceanfish_small_8_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Bloomfin Tuna",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_small_7",quest_name)
		end,
		"Bloomfin Tunas",
		"oceanfish_small_7_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Fallounder",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_small_6",quest_name)
		end,
		"Fallounders",
		"oceanfish_small_6_inv.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Corn Cod",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,"oceanfish_medium_5",quest_name)
		end,
		"Corn Cods",
		"oceanfish_medium_5_inv.tex",
		"images/inventoryimages1.xml",
	},

	--Teleport
	{
		"Teleport x times something away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,nil,quest_name)
		end,
		"Teleports",
		"telestaff.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Teleport x Beefalo away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,"beefalo",quest_name)
		end,
		"Beefalo",
		"beefalo.tex"
	},
	{
		"Teleport x Deerclops away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,"deerclops",quest_name)
		end,
		"Deerclops",
		"deerclops.tex"
	},
	{
		"Teleport x Bearger away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,"bearger",quest_name)
		end,
		"Bearger",
		"bearger.tex"
	},
	{
		"Teleport x Dragonfly away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,"dragonfly",quest_name)
		end,
		"Dragonfly",
		"dragonfly.tex"
	},
	{	
		"Teleport x Moose/Goose away",
		function(player,amount,quest_name)
			custom_functions["teleport x times y away"](player,amount,"moose",quest_name)
		end,
		"Moose/Goose",
		"moose.tex"
	},

	--Defending Moonbase
	{
		"Defend x times the Moon Base",
		function(player,amount,quest_name)
			custom_functions["defend moonbase x times"](player,amount,quest_name)
		end,
		"Times defended",
		"moonbase.tex"
	},

	--Building Structures
	{
		"Build x Pig Houses",
		function(player,amount,quest_name)
			custom_functions["build x y times"](player,amount,"pighouse",quest_name)
		end,
		"Pig Houses",
		"pigman.tex"
	},
	{
		"Build x Bunnyman Houses",
		function(player,amount,quest_name)
			custom_functions["build x y times"](player,amount,"rabbithouse",quest_name)
		end,
		"Bunnyman Houses",
		"bunnyman.tex"
	},
	{
		"Build x Meat Effigies",
		function(player,amount,quest_name)
			custom_functions["build x y times"](player,amount,"resurrectionstatue",quest_name)
		end,
		"Meat Effigies",
		"health.tex"
	},
	{
		"Build x Scaled Chests",
		function(player,amount,quest_name)
			custom_functions["build x y times"](player,amount,"dragonflychest",quest_name)
		end,
		"Scaled Chests",
		"health.tex"
	},

	--Net Catching
	{
		"Catch x Butterflys with a Net",
		function(player,amount,quest_name)
			custom_functions["do work type z for x amount of y"](player,ACTIONS.NET,"butterfly",amount,quest_name)
		end,
		"Butterflys Caught",
		"butterfly.tex"
	},
	{
		"Catch x Bees with a Net",
		function(player,amount,quest_name)
			custom_functions["do work type z for x amount of y"](player,ACTIONS.NET,"bee",amount,quest_name)
		end,
		"Bees Caught",
		"bee.tex"
	},
	{
		"Catch x Killerbees with a Net",
		function(player,amount,quest_name)
			custom_functions["do work type z for x amount of y"](player,ACTIONS.NET,"killerbee",amount,quest_name)
		end,
		"Killerbees Caught",
		"killerbee.tex"
	},
	{
		"Catch x Mosquitos with a Net",
		function(player,amount,quest_name)
			custom_functions["do work type z for x amount of y"](player,ACTIONS.NET,"mosquito",amount,quest_name)
		end,
		"Mosquitos Caught",
		"mosquito.tex"
	},
	{
		"Catch x Fireflies with a Net",
		function(player,amount,quest_name)
			custom_functions["do work type z for x amount of y"](player,ACTIONS.NET,"fireflies",amount,quest_name)
		end,
		"Fireflies Caught",
		"fireflies.tex",
		"images/inventoryimages1.xml"
	},

	--Chopping Missions
	{
		"Chop down x Trees",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.CHOP,nil,amount,quest_name)
		end,
		"Trees",
		"axe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Chop down x Totally Normal Trees",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.CHOP,"livingtree",amount,quest_name)
		end,
		"Totally Normal Trees",
		"axe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Chop down x Lune Trees",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.CHOP,"moon_tree_tall",amount,quest_name)
		end,
		"Lune Trees",
		"axe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Chop down x Above-Average Tree Trunks",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.CHOP,"oceantree_pillar",amount,quest_name)
		end,
		"Above-Average Tree Trunks",
		"axe.tex",
		"images/inventoryimages1.xml",
	},

	--Mining Missions
	{
		"Mine x Boulders",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.MINE,nil,amount,quest_name)
		end,
		"Boulders",
		"pickaxe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Mine x Gold Veins",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.MINE,"rock2",amount,quest_name)
		end,
		"Gold Veins",
		"pickaxe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Mine x Meteors",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.MINE,"rock_moon",amount,quest_name)
		end,
		"Meteors",
		"pickaxe.tex",
		"images/inventoryimages1.xml",
	},

	--Digging Missions
	{
		"Dig up x Times",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.DIG,nil,amount,quest_name)
		end,
		"Digs",
		"shovel.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Dig up x Graves",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.DIG,"mound",amount,quest_name)
		end,
		"Graves",
		"shovel.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Dig up x Grass Tufts",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.DIG,"grass",amount,quest_name)
		end,
		"Grass Tufts",
		"shovel.tex",
		"images/inventoryimages2.xml",
	},


	--Capture Misions
	{
		"Catch x creatures with a Trap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,nil,quest_name)
		end,
		"Creatures Caught",
		"trap.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Catch x Rabbits with a Trap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"rabbit",quest_name)
		end,
		"Rabbits Caught",
		"rabbit.tex",
	},
	{
		"Catch x Spiders with a Trap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"spider",quest_name)
		end,
		"Spiders Caught",
		"spider.tex"
	},
	{
		"Catch x Spider Warriors with a Trap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"spider_warrior",quest_name)
		end,
		"Spider Warriors Caught",
		"spider_warrior.tex"
	},
	{
		"Catch x Birds with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,nil,quest_name)
		end,
		"Creatures Caught",
		"birdtrap.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Catch x Canaries with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"canary",quest_name)
		end,
		"Canaries Caught",
		"canary.tex",
	},
	{
		"Catch x Crows with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"crow",quest_name)
		end,
		"Crows Caught",
		"crow.tex",
	},
	{
		"Catch x Red Birds with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"robin",quest_name)
		end,
		"Red Birds Caught",
		"robin.tex",
	},
	{
		"Catch x Snowbirds with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"robin_winter",quest_name)
		end,
		"Snowbirds Caught",
		"robin_winter.tex",
	},
	{
		"Catch x Puffins with a Birdtrap",
		function(player,amount,quest_name)
			custom_functions["capture x y times"](player,amount,"puffin",quest_name)
		end,
		"Puffins Caught",
		"puffin.tex",
	},

	--Protect Missions
	{
		"Protect a Glommer from x creatures for 3 Very Easy Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,5,3,10,1,"glommer",quest_name)
		end,
		"Times Protected",
		"glommer.tex",
		"images/victims.xml"
	},
	{
		"Protect a Butterfly from x creatures for 3 Easy Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,7,3,10,2,"butterfly",quest_name)
		end,
		"Times Protected",
		"butterfly.tex",
		"images/victims.xml"
	},
	{
		"Protect a Woven Shadow from x creatures for 3 Medium Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,7,3,10,3,"stalker_minion1",quest_name)
		end,
		"Times Protected",
		"stalker_minion1.tex",
		"images/victims.xml"
	},
	{
		"Protect a Woven Shadow from x creatures for 3 Difficult Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,7,3,10,4,"stalker_minion2",quest_name)
		end,
		"Times Protected",
		"stalker_minion2.tex",
		"images/victims.xml"
	},
	{
		"Protect a Dust Moth from x creatures for 3 Very Difficult Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,7,3,10,5,"dustmoth",quest_name)
		end,
		"Times Protected",
		"dustmoth.tex",
		"images/victims.xml"
	},
	{
		"Protect a Moon Moth from x creatures for 5 Very Difficult Waves",
		function(player,amount,quest_name)
			custom_functions["protect x from y creatures z times"](player,amount,7,5,15,5,"moonbutterfly",quest_name)
		end,
		"Times Protected",
		"moonbutterfly.tex",
		"images/victims.xml"
	},

	--Temperature Missions
	{
		"Stay at over 80°C for x seconds at once",
		function(player,amount,quest_name)
			custom_functions["stay x seconds over/under y temperature"](player,amount,80,1,true,quest_name)
		end,
		"Seconds",
		"light.tex"
	},
	{
		"Stay at over 70°C for x seconds at once",
		function(player,amount,quest_name)
			custom_functions["stay x seconds over/under y temperature"](player,amount,70,1,true,quest_name)
		end,
		"Seconds",
		"light.tex"
	},
	{
		"Stay at under 0°C for x seconds at once",
		function(player,amount,quest_name)
			custom_functions["stay x seconds over/under y temperature"](player,amount,0,0,true,quest_name)
		end,
		"Seconds",
		"ice.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Stay at under -10°C for x seconds at once",
		function(player,amount,quest_name)
			custom_functions["stay x seconds over/under y temperature"](player,amount,-10,0,true,quest_name)
		end,
		"Seconds",
		"ice.tex",
		"images/inventoryimages1.xml",
	},

	--Crafting Missions
	{
		"Craft x items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,nil,quest_name)
		end,
		"Items Crafted",
		"structures.tex"
	},
	{
		"Craft x Dark Swords",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,"nightsword",nil,quest_name)
		end,
		"Dark Swords Crafted",
		"nightsword.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Craft x Thulecite Crowns",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,"ruinshat",nil,quest_name)
		end,
		"Thulecite Crowns Crafted",
		"ruinshat.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Craft x Glass Cutters",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,"glasscutter",nil,quest_name)
		end,
		"Glass Cutters Crafted",
		"glasscutter.tex",
		"images/inventoryimages1.xml",
	}, 
	{
		"Craft x Glossamer Saddles",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,"saddle_race",nil,quest_name)
		end,
		"Glossamer Saddles Crafted",
		"saddle_race.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Craft x Magic Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"MAGIC",quest_name)
		end,
		"Magic Items Crafted",
		"magic.tex",
	},
	{
		"Craft x Fighting Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"WAR",quest_name)
		end,
		"Fighting Items Crafted",
		"fight.tex",
	},
	{
		"Craft x Refined Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"REFINE",quest_name)
		end,
		"Refined Items Crafted",
		"refine.tex",
	},
	{
		"Craft x Tool Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"TOOLS",quest_name)
		end,
		"Tool Items Crafted",
		"tools.tex",
	},
	{
		"Craft x Ancient Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"ANCIENT",quest_name)
		end,
		"Ancient Items Crafted",
		"ancient.tex",
	},
	{
		"Craft x Celestial Items",
		function(player,amount,quest_name)
			custom_functions["craft x y times"](player,amount,nil,"CELESTIAL",quest_name)
		end,
		"Celestial Items Crafted",
		"celestial.tex",
	},

	--Healing Missions
	{
		"Heal x Amount of Health",
		function(player,amount,quest_name)
			custom_functions["heal x amount of life with y"](player,amount,nil,quest_name)
		end,
		"Healed",
		"health.tex",
	},
	{
		"Heal x Amount of Health with Spiderglands",
		function(player,amount,quest_name)
			custom_functions["heal x amount of life with y"](player,amount,"spidergland",quest_name)
		end,
		"Healed",
		"spidergland.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Heal x Amount of Health with a Honey Poultice",
		function(player,amount,quest_name)
			custom_functions["heal x amount of life with y"](player,amount,"bandage",quest_name)
		end,
		"Healed",
		"bandage.tex",
		"images/inventoryimages1.xml",
	},

	--Damage Missions
	{
		"Deal x Amount of Damage",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,nil,quest_name)
		end,
		"Damage",
		"fight.tex",
	},
	{
		"Deal x Amount of Damage with a Spear",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,"spear",quest_name)
		end,
		"Damage",
		"spear.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Deal x Amount of Damage with a Bull Kelp Stalk",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,"bullkelp_root",quest_name)
		end,
		"Damage",
		"bullkelp_root.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage with a Sea Fishing Rod",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,"oceanfishingrod",quest_name)
		end,
		"Damage",
		"oceanfishingrod.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage with a Boomerang",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,"boomerang",quest_name)
		end,
		"Damage",
		"boomerang.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage with a Morning Star",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage"](player,amount,"nightstick",quest_name)
		end,
		"Damage",
		"nightstick.tex",
		"images/inventoryimages1.xml",
	},

	--Damage in certain time Missions
	{
		"Deal x Amount of Damage in 10 seconds",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,nil,10,quest_name)
		end,
		"Damage",
		"fight.tex",
	},
	{
		"Deal x Amount of Damage in 30 seconds",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,nil,30,quest_name)
		end,
		"Damage",
		"fight.tex",
	},
	{
		"Deal x Amount of Damage in 60 seconds",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,nil,60,quest_name)
		end,
		"Damage",
		"fight.tex",
	},
	{
		"Deal x Amount of Damage in 10 seconds with a Shadow Sword",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,"nightsword",10,quest_name)
		end,
		"Damage",
		"nightsword.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage in 10 seconds with a Glass Cutter",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,"glasscutter",10,quest_name)
		end,
		"Damage",
		"glasscutter.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage in 10 seconds with a Tentacle Spike",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,"tentaclespike",10,quest_name)
		end,
		"Damage",
		"tentaclespike.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Deal x Amount of Damage in 10 seconds with a Ham Bat",
		function(player,amount,quest_name)
			custom_functions["deal x amount of damage in time y with weapon z"](player,amount,"hambat",10,quest_name)
		end,
		"Damage",
		"hambat.tex",
		"images/inventoryimages1.xml",
	},

	--Follower Missions
	{
		"Have x Followers at once",
		function(player,amount,quest_name)
			custom_functions["acquire x followers that are y"](player,amount,nil,quest_name)
		end,
		"Followers",
		"critters.tex",
	},
	{
		"Have x Pig Followers at once",
		function(player,amount,quest_name)
			custom_functions["acquire x followers that are y"](player,amount,"pigman",quest_name)
		end,
		"Followers",
		"pigman.tex",
	},
	{
		"Have x Bunnyman Followers at once",
		function(player,amount,quest_name)
			custom_functions["acquire x followers that are y"](player,amount,"manrabbit",quest_name)
		end,
		"Followers",
		"manrabbit.tex",
	},
	{
		"Have x Beefalo Followers at once",
		function(player,amount,quest_name)
			custom_functions["acquire x followers that are y"](player,amount,"beefalo",quest_name)
		end,
		"Followers",
		"beefalo.tex",
	},
	{
		"Have x Rock Lobster Followers at once",
		function(player,amount,quest_name)
			custom_functions["acquire x followers that are y"](player,amount,"rocky",quest_name)
		end,
		"Followers",
		"rocky.tex",
	},

	--Deploy Missions
	{
		"Plant x Trees",
		function(player,amount,quest_name)
			custom_functions["deploy x y times"](player,amount,tree_seeds,quest_name)
		end,
		"Trees Planted",
		"pinecone.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Plant x Flowers",
		function(player,amount,quest_name)
			custom_functions["deploy x y times"](player,amount,"butterfly",quest_name)
		end,
		"Flowers Planted",
		"petals.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Create x new Spider Dens",
		function(player,amount,quest_name)
			custom_functions["deploy x y times"](player,amount,"spidereggsack",quest_name)
		end,
		"Spider Dens",
		"spidereggsack.tex",
		"images/inventoryimages2.xml",
	},

	--Repair Items
	{
		"Sew x Items with a Sewing Kit or Trusty Tape",
		function(player,amount,quest_name)
			custom_functions["sew x times"](player,amount,quest_name)
		end,
		"Repairs",
		"sewing_kit.tex",
		"images/inventoryimages2.xml",
	},

	--Staying on Ocean Missions
	{
		"Stay x seconds on a boat",
		function(player,amount,quest_name)
			custom_functions["stay x amount of time on y boat"](player,amount,nil,nil,quest_name)
		end,
		"Seconds",
		"boat_item.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Stay x seconds on a boat at once",
		function(player,amount,quest_name)
			custom_functions["stay x amount of time on y boat"](player,amount,nil,true,quest_name)
		end,
		"Seconds",
		"boat_item.tex",
		"images/inventoryimages1.xml",
	},

	--Fertilizing Missions
	{
		"Fertilize x times",
		function(player,amount,quest_name)
			custom_functions["fertilize x y times with z"](player,amount,nil,nil,quest_name)
		end,
		"Fertilized",
		"green_thumb.tex",
	},
	{
		"Fertilize x times Farm Soil",
		function(player,amount,quest_name)
			custom_functions["fertilize x y times with z"](player,amount,nil,nil,quest_name,true)
		end,
		"Fertilized",
		"green_thumb.tex",
	},
	{
		"Fertilize x times with Manure",
		function(player,amount,quest_name)
			custom_functions["fertilize x y times with z"](player,amount,nil,"poop",quest_name)
		end,
		"Fertilized",
		"poop.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Fertilize x times with Super Growth Formula",
		function(player,amount,quest_name)
			custom_functions["fertilize x y times with z"](player,amount,nil,"soil_amender_fermented",quest_name)
		end,
		"Fertilized",
		"soil_amender_fermented.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Fertilize x times with Glommer's Goop",
		function(player,amount,quest_name)
			custom_functions["fertilize x y times with z"](player,amount,nil,"glommerfuel",quest_name)
		end,
		"Fertilized",
		"glommerfuel.tex",
		"images/inventoryimages1.xml",
	},

	--Timed Missions
	{
		"Kill x Spiders in one day",
		function(player,amount,quest_name)
			custom_functions["kill x y times"](player,amount,"spider",quest_name)
			custom_functions["do x y times in z days"](player,amount,8,nil,quest_name)
		end,
		"Spiders",
		"spider.tex",
	},
	{
		"Kill x Pig Mans in 16 minutes",
		function(player,amount,quest_name)
			custom_functions["kill x y times"](player,amount,"pigman",quest_name)
			custom_functions["do x y times in z days"](player,amount,16,nil,quest_name)
		end,
		"Pigman",
		"pigman.tex",
	},
	{
		"Kill x Bunnyman in 16 minutes",
		function(player,amount,quest_name)
			custom_functions["kill x y times"](player,amount,"manrabbit",quest_name)
			custom_functions["do x y times in z days"](player,amount,16,nil,quest_name)
		end,
		"Bunnyman",
		"manrabbit.tex",
	},
	{
		"Kill x Red Birds in 8 minutes",
		function(player,amount,quest_name)
			custom_functions["kill x y times"](player,amount,"robin",quest_name)
			custom_functions["do x y times in z days"](player,amount,8,nil,quest_name)
		end,
		"Red Bird",
		"robin.tex",
	},
	{
		"Catch x Fish in 16 minutes",
		function(player,amount,quest_name)
			custom_functions["catch x amount of y fish"](player,amount,nil,quest_name)
			custom_functions["do x y times in z days"](player,amount,16,nil,quest_name)
		end,
		"Fishes",
		"fishing.tex",
	},
	{
		"Chop down x trees in 8 minutes",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.CHOP,nil,amount,quest_name)
			custom_functions["do x y times in z days"](player,amount,8,nil,quest_name)
		end,
		"Trees",
		"axe.tex",
		"images/inventoryimages1.xml",
	},
	{
		"Dig up x times in 8 minutes",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.DIG,nil,amount,quest_name)
			custom_functions["do x y times in z days"](player,amount,8,nil,quest_name)
		end,
		"Digs",
		"shovel.tex",
		"images/inventoryimages2.xml",
	},
	{
		"Mine x Boulders in 8 minutes",
		function(player,amount,quest_name)
			custom_functions["finish work type z for x amount of y"](player,ACTIONS.MINE,nil,amount,quest_name)
			custom_functions["do x y times in z days"](player,amount,8,nil,quest_name)
		end,
		"Boulders",
		"pickaxe.tex",
		"images/inventoryimages1.xml",
	},

	--Lightning Strike Missions
	{
		"Get hit x times by a Lightning Strikes",
		function(player,amount,quest_name)
			custom_functions["get hit x times by a lightning strike"](player,amount,quest_name)
		end,
		"Lightning Strikes",
		"lightning_rod.tex",
		"images/inventoryimages1.xml",
	},

	--Dying Missions
	{
		"Die x times",
		function(player,amount,quest_name)
			custom_functions["die x times from y by z"](player,amount,nil,nil,quest_name)
		end,
		"Deaths",
		"health.tex",
	},
	{
		"Die x times by a rose",
		function(player,amount,quest_name)
			custom_functions["die x times from y by z"](player,amount,"flower_rose",nil,quest_name)
		end,
		"Deaths",
		"health.tex",
	},
	{
		"Die x times by Deerclops",
		function(player,amount,quest_name)
			custom_functions["die x times from y by z"](player,amount,"deerclops",nil,quest_name)
		end,
		"Deaths",
		"health.tex",
	},

}


local function AddCustomFunctions(tab)
	for _,v in ipairs(tab) do
		local new_tab = {text = v[1]--[[function(amount) string.format(v[1], amount) end]] ,data = "start_fn_"..v[1],counter = v[3], fn = v[2],tex = v[4], atlas = v[5]}
		QUEST_BOARD.PREFABS_MOBS[v[1]] = new_tab
	end
	print("[Quest System] Amount of custom goals:",GetTableSize(QUEST_BOARD.PREFABS_MOBS))
end


AddCustomFunctions(FunctionsForCustomQuests)

