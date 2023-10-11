GLOBAL.SetQuestSystemEnv()

local goals = {}

local function AddPrefabToGoals(prefab,atlas,tex,name)
	local tab = {}
	tab.prefab = prefab
	tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
	tab.tex = tex or prefab..".tex"
	tab.atlas = atlas or "images/victims_cherry_forest.xml"
	return tab
end

local prefabs = {
	"catbird",
	"cherryling",
	"cherryling_ancient",
	"cherry_butterfly",
	"cherry_dragonfly",
	"cherry_daylily",
	"cherry_bee",
	"chaffinch",
	"cherry_beequeen",
	"cherry_beeguard",
	"cherry_watcher",
	--"squittle", --WIP
}


local function cherry_beequeen(inst)
	--devprint("cherry_beequeen sg", inst, inst.sg)
	if inst.sg and inst.sg.sg then
		if inst.sg.sg.events then
			--devprint(inst.sg.sg.events.flee)
			inst.sg.sg.events.flee = nil
			--devprint(inst.sg.sg.events.flee)
		end
	end
	inst:DoTaskInTime(2,function()
		--devprint("cherry_beequeen", inst, inst.brain)
		local flee_node
		local pos
		if inst.brain then
			for i,node in ipairs(inst.brain.bt.root.children) do
				if node.name == "FaceEntity" then
					pos = i+1
					flee_node = inst.brain.bt.root.children[pos] and inst.brain.bt.root.children[pos].children[1]
				end
			end
		end
		if flee_node then
			table.remove(inst.brain.bt.root.children[pos].children, 1)
		end
		--devprint("cherry_beequeen after" , inst, inst.brain)
	end)
end

local bosses = {
	EASY = {

		--{name = "cherryling", health = 1000, damage = 100, scale = 2,},
		{name = "cherry_bee", health = 1000, damage = 100, scale = 2,},
		--{name = "cherry_beeguard", health = 1000, damage = 100, scale = 2,},

	},

	NORMAL = {

		{name = "cherry_watcher", health = 3500, damage = 150, scale = 1.6},

	},

	DIFFICULT = {

		{name = "cherry_beequeen", health = 6000, damage = 200, scale = 1.7, fn = cherry_beequeen},
		
	},
}

for diff,boss in pairs(bosses) do
	for _,data in ipairs(boss) do
		AddBosses(data,diff)
	end
end

local item_list = {"armor_cherry","cherry","cherry_double","cherry_beesmoker","cherry_beesmokerfuel","cherry_boomerang","blowdart_cherryroyal","blowdart_cherryrandom","cherry_butterfly","cherry_dragonfly","cherry_fireflies","cherry_honey","cherry_nesthat","cherry_watcherlantern","cherryamulet","cherryaxe","cherrygem","cheerfulgem","cherryhat","cherrymooneye","cherrystaff","feather_catbird","feather_chaffinch","cherryupgrade_friendpit_item","cherryvest","cherryscepter","cherry_pacifier"}


AddSimPostInit(function()
	for _,v in ipairs(prefabs) do
		if type(v) == "table" then
			local goal = AddPrefabToGoals(v.prefab,v.atlas,v.tex,v.name)
			table.insert(goals,goal)
		else
			local goal = AddPrefabToGoals(v)
			table.insert(goals,goal)
		end
	end
	AddCustomGoals(goals,"Cherry Forest")
	for k in pairs(require("cherry_preparedfoods")) do
		table.insert(item_list,k)
	end

	for k in pairs(require("cherry_preparedfoods_warly")) do
		table.insert(item_list,k)
	end
	AddCustomRewards(item_list)

	local quests = {
		--1
		{
			name = "Watch This!",
			victim = "cherry_watcher",
			counter_name = nil,
			description = GetQuestString("Watch This!","DESCRIPTION"),
			amount = 1,
			rewards = {[":func:planardamage;10"] = 16,armor_cherry = 1},
			points = 500,
			start_fn = nil,
			onfinished = nil,
			difficulty = 3,
			tex = "cherry_watcher.tex",
			atlas = "images/victims_cherry_forest.xml",
			hovertext = GetKillString("cherry_watcher",1),
		},
		--2
		{
			name = "Mutated Queen",
			victim = "cherry_beequeen",
			counter_name = nil,
			description = GetQuestString("Mutated Queen","DESCRIPTION"),
			amount = 1,
			rewards = {[":func:planardamage;10"] = 16,armor_cherry = 1},
			points = 2500,
			start_fn = nil,
			onfinished = nil,
			difficulty = 5,
			tex = "cherry_beequeen.tex",
			atlas = "images/victims_cherry_forest.xml",
			hovertext = GetKillString("cherry_beequeen",1),
		},
		--3
		{
			name = "A Reputable Person",
			victim = "",
			counter_name = GetQuestString("A Reputable Person","COUNTER"),
			description = GetQuestString("A Reputable Person","DESCRIPTION"),
			amount = 20,
			rewards = {cherry_taffy = 3, cherrygem = 1 },
			points = 125,
			start_fn = function(inst, amount, quest_name)
				if inst.components.cherryreputation == nil then
					return
				end
				local function OnReputation(inst, data)
					inst:PushEvent("quest_update",{quest = quest_name,set_amount = math.floor(data.new)})
					if data.new >= amount then
						inst:RemoveEventCallback("cherryreputationdelta",OnReputation)
					end
				end
				inst:ListenForEvent("cherryreputationdelta", OnReputation)
				OnReputation(inst, {new = inst.components.cherryreputation:GetReputation()})
				local function OnForfeitedQuest()
					inst:RemoveEventCallback("cherryreputationdelta",OnReputation)
				end
				OnForfeit(inst,OnForfeitedQuest,quest_name)
			end,
			onfinished = ScaleEnd,
			difficulty = 1,
			tex = "cherryrepcoin_percent.tex",
			atlas = "images/bugregistry.xml",
			hovertext = GetQuestString("A Reputable Person","HOVER", 20),
			scale = {1},
			custom_vars_fn = function(inst,amount,quest_name)
				local max_scale = inst.components.quest_component and inst.components.quest_component.scaled_quests[quest_name] and inst.components.quest_component.scaled_quests[quest_name] + 1 or 1
				local scale = math.random(math.max(max_scale-1, 1), max_scale)
				return {scale = scale}
			end,
			variable_fn = function(inst,quest,data)
				if data and data.scale and tonumber(data.scale) > 1 then
					local scale = math.max(math.min(5,tonumber(data.scale)),2)
					local vars = {{20,125},{40,250},{60,500},{80,750},{100,1500}}
					quest.amount = vars[scale][1]
					quest.points = vars[scale][2]
					quest.rewards = {cherry_taffy = 3 * scale,cherrygem = 1 * scale,}
					if scale > 2 then
						quest.rewards.cherry_pie = 1 * (scale - 2)
					end
					--quest.hovertext = GetQuestString(quest.name,"HOVER",vars[scale][1])
					quest.scale = {scale}
					quest.difficulty = scale
				end
				return quest
			end,
		},
		--4
		{
			name = "It's Bugging Me!",
			victim = "",
			counter_name = GetQuestString("It's Bugging Me!","COUNTER"),
			description = GetQuestString("It's Bugging Me!","DESCRIPTION"),
			amount = 5,
			rewards = {[":func:speed;1.1"] = 8,cherrygem = 1},
			points = 260,
			start_fn = function(inst, amount, quest_name)
				local function IsBug(target)
					return target:HasTag("cherryseasonbug")
				end
				custom_functions["do work type z for x amount of y"](inst, ACTIONS.NET, nil, amount, quest_name, IsBug)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "cherrybug_goldbeetle.tex",
			atlas = "images/cherryimages.xml",
			hovertext = GetQuestString("It's Bugging Me!", "HOVER", 5),
		},
		--5
		{
			name = "The Pacifier",
			victim = "",
			counter_name = GetQuestString("The Pacifier","COUNTER"),
			description = GetQuestString("The Pacifier","DESCRIPTION"),
			amount = 2,
			rewards = {[":func:damagereduction;0.7"] = 16,cheerfulgem = 3},
			points = 900,
			start_fn = function(inst, amount, quest_name)
				custom_functions["build x y times"](inst, amount, "cherry_pacifier", quest_name)
			end,
			onfinished = nil,
			difficulty = 4,
			tex = "cherry_pacifier.tex",
			atlas = "images/cherryimages.xml",
			hovertext = GetQuestString("The Pacifier", "HOVER", 2),
		},
	}

	AddQuests(quests, "Cherry Forest")

	RegisterQuestModIcon("Cherry Forest", "images/cherryimages.xml", "cherryling.tex")

end)