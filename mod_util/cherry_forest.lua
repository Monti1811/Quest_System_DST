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
	--"squittle", --WIP
}

local bosses = {
	EASY = {

		--{name = "cherryling", health = 1000, damage = 100, scale = 2,},
		{name = "cherry_bee", health = 1000, damage = 100, scale = 2,},
		--{name = "cherry_beeguard", health = 1000, damage = 100, scale = 2,},

	},

	DIFFICULT = {

		{name = "cherry_beequeen", health = 10000, damage = 200, scale = 1.7,},
		
	},
}

for diff,boss in pairs(bosses) do
	for _,data in ipairs(boss) do
		GLOBAL.AddBosses(data,diff)
	end
end

local item_list = {"armorcherry","cherry","cherry_double","cherry_beesmoker","cherry_beesmokerfuel","cherry_boomerang","blowdart_cherryroyal","blowdart_cherryrandom","cherry_butterfly","cherry_dragonfly","cherry_fireflies","cherry_honey","cherry_nesthat","cherry_watcherlantern","cherryamulet","cherryaxe","cherrygem","cheerfulgem","cherryhat","cherrymooneye","cherrystaff","feather_catbird","feather_chaffinch","cherryupgrade_friendpit_item",}


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
	GLOBAL.AddCustomGoals(goals,"Cherry Forest")
	for k,v in pairs(require("cherry_preparedfoods")) do
		table.insert(item_list,k)
	end

	for k,v in pairs(require("cherry_preparedfoods_warly")) do
		table.insert(item_list,k)
	end
	GLOBAL.AddCustomRewards(item_list)
end)