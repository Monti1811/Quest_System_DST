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

	MEDIUM = {
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
	}

	AddQuests(quests, "Cherry Forest")

	RegisterQuestModIcon("Cherry Forest", "images/cherryimages.xml", "cherryling.tex")

end)