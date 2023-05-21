GLOBAL.SetQuestSystemEnv()

local goals = {}

local function AddPrefabToGoals(prefab,atlas,tex,name)
	local tab = {}
	tab.prefab = prefab
	tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
	tab.tex = tex or prefab..".tex"
	tab.atlas = atlas or "images/victims_legion.xml"
	return tab
end

local prefabs = {

}

local item_list = {
	"armor_mushaa",
   "armor_mushab",
   "arrowm",
   "bowm",
   "broken_frosthammer",
   "cristal",
   "exp",
   "frosthammer",
   "glowdust",
   "green_fruit",
   "green_fruit_cooked",
   "hat_mbunny",
   "hat_mbunnya",
   "hat_mphoenix",
   "hat_mprincess",
   "hat_mwildcat",
   "musha_egg",
   "musha_egg_cracked",
   "musha_egg_cooked",
   "musha_egg1",
   "musha_egg_cracked1",
   "musha_egg_cooked1",
   "musha_egg2",
   "musha_egg_cracked2",
   "musha_egg_cooked2",
   "musha_egg3",
   "musha_egg_cracked3",
   "musha_egg_cooked3",
   "musha_egg4",
   "musha_egg_cracked4",
   "musha_egg_cooked4",
   "musha_egg5",
   "musha_egg_cracked5",
   "musha_egg_cooked5",
   "musha_egg6",
   "musha_egg_cracked6",
   "musha_egg_cooked6",
   "musha_egg7",
   "musha_egg_cracked7",
   "musha_egg_cooked7",
   "musha_egg_arong",
   "musha_egg_cracked_arong",
   "musha_egg_arong_cooked",
   "musha_egg_random",
   "musha_egg_random_cracked",
   "musha_egg_random_cooked",
   "musha_flute",
   "musha_nametag",
   "mushapacker",
   "mushasword",
   "mushasword4",
   "mushasword_base",
   "mushasword_frost",
   "phoenixspear",
   "pirateback",
   "portion_e",
   "tunacan",
   "tunacan_musha",
}

local build_x_y_times = GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["build x y times"]

local structures = {
	{prefab = "glowdust", atlas = "images/inventoryimages/glowdust.xml", tex = "glowdust.tex"},
	{prefab = "musha_nametag", atlas = "images/inventoryimages/musha_nametag.xml", tex = "musha_nametag.tex"},
	{prefab = "portion_e", atlas = "images/inventoryimages/portion_e.xml", tex = "portion_e.tex"},
	{prefab = "arrowm1", atlas = "images/inventoryimages/arrowm1.xml", tex = "arrowm1.tex"},
	{prefab = "arrowm2", atlas = "images/inventoryimages/arrowm2.xml", tex = "arrowm2.tex"},
	{prefab = "arrowm3", atlas = "images/inventoryimages/arrowm3.xml", tex = "arrowm3.tex"},
	{prefab = "arrowm4", atlas = "images/inventoryimages/arrowm4.xml", tex = "arrowm4.tex"},
	{prefab = "arrowm", atlas = "images/inventoryimages/arrowm.xml", tex = "arrowm.tex"},
	{prefab = "tunacan_musha", atlas = "images/inventoryimages/tunacan_musha.xml", tex = "tunacan_musha.tex"},
	{prefab = "musha_hut", atlas = "images/inventoryimages/musha_hut.xml", tex = "musha_hut.tex"},
	{prefab = "moontree_musha", atlas = "images/inventoryimages/moontree_musha.xml", tex = "moontree_musha.tex"},
	{prefab = "musha_oven", atlas = "images/inventoryimages/musha_oven.xml", tex = "musha_oven.tex"},
	{prefab = "forge_musha", atlas = "images/inventoryimages/forge_musha.xml", tex = "forge_musha.tex"},
	{prefab = "tent_musha", atlas = "images/inventoryimages/tent_musha.xml", tex = "tent_musha.tex"},
	{prefab = "mushasword_base"},
	{prefab = "mushasword"},
	{prefab = "mushasword_frost"},
	{prefab = "bowm"},
	{prefab = "phoenixspear"},
	{prefab = "mushasword4"},
	{prefab = "frosthammer"},
	{prefab = "armor_mushaa"},
	{prefab = "broken_frosthammer"},
	{prefab = "armor_mushab"},
	{prefab = "pirateback"},
	{prefab = "hat_mbunny"},
	{prefab = "hat_mwildcat"},
	{prefab = "hat_mbunnya"},
	{prefab = "hat_mprincess"},
	{prefab = "hat_mphoenix"},
	{prefab = "musha_flute"},
	{prefab = "cristal"},
	{prefab = "musha_egg_arong"},
	{prefab = "musha_egg_random"},
	{prefab = "musha_egg"},
	{prefab = "musha_egg1"},
	{prefab = "musha_egg2"},
	{prefab = "musha_egg3"},
	{prefab = "musha_egg4"},
	{prefab = "musha_egg5"},
	{prefab = "musha_egg6"},
	{prefab = "musha_egg7"},
}

local structure_goals = {}

if build_x_y_times then
	for k,v in ipairs(structures) do
		local tab = {}
		tab.text = v.prefab
		tab.fn = function(player,amount,questname) build_x_y_times(player,amount,v.prefab,questname) end
		tab.tex = v.tex or v.prefab..".tex"
		tab.atlas = v.atlas or "images/inventoryimages/"..v.prefab..".xml"
		table.insert(structure_goals,tab)
	end
end


for k,v in ipairs(prefabs) do
	if type(v) == "table" then
		local goal = AddPrefabToGoals(v.prefab,v.atlas,v.tex,v.name)
		table.insert(goals,goal)
	else
		local goal = AddPrefabToGoals(v)
		table.insert(goals,goal)
	end
end
for k,v in ipairs(structure_goals) do
	local prefab = v.text
	local name = GLOBAL.STRINGS.NAMES[string.upper(prefab)]
	v.text = name and "Build x "..name or "No Name"
	v.counter = name
	table.insert(goals,v)
end
AddCustomGoals(goals,"Musha")

AddCustomRewards(item_list)
