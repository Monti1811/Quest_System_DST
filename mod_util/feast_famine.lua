local goals = {}

local MILK = GLOBAL.KnownModIndex:IsModEnabled("workshop-436654027")

local function AddPrefabToGoals(prefab,atlas,tex,name)
	local tab = {}
	tab.prefab = prefab
	tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
	tab.tex = tex or prefab..".tex"
	tab.atlas = atlas or "images/victims_feast_famine.xml"
	return tab
end

local prefabs = {
	"chicken",
}

local item_list = {"flour","rocky_meat","deer_meat","deer_meat_autumn","antlion_meat","beefalo_meat","bunnyman_meat","cat_meat","goat_meat","guardian_meat","koala_summer_meat","koala_winter_meat","malbatross_meat","moose_meat","pasta_wet","pasta_dry","pigskin_leather","stick_pretzels","syrup","tomato_rock_dried","wheatgrass","cheese_goat","egg_pengull","egg_monster","egg_plant","log_lunar","log_twiggy","log_spiky","log_birch","log_livingbirch",}




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
	GLOBAL.AddCustomGoals(goals,"Feast Famine")
	for k,v in pairs(require("Feast_foods")) do
		table.insert(item_list,k)
	end

	if MILK then 
		for k,v in pairs(require("Milk_foods")) do
			table.insert(item_list,k)
		end

		for k,v in pairs(require("Milk_foods_unspicy")) do
			table.insert(item_list,k)
		end
	end
	GLOBAL.AddCustomRewards(item_list)
end)