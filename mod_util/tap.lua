local goals = {}

local build_x_y_times = GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["build x y times"]

local structures = {
	{prefab = "kyno_altar_pillar"},
	{prefab = "kyno_lunarextractor", atlas = "images/inventoryimages/kyno_contained.xml", tex = "kyno_contained.tex"},
	{prefab = "kyno_moonglass_meteor",},
	{prefab = "kyno_accomplishment_shrine", atlas = "images/inventoryimages/kyno_inventoryimages_ham.xml", tex = "accomplishment_shrine.tex"},
	{prefab = "kyno_antcache"},
	{prefab = "kyno_antchest"},
	{prefab = "kyno_antcombhome"},
	{prefab = "kyno_antlion"},
	{prefab = "kyno_antlionsinkhole"},
	{prefab = "kyno_antthrone"},
	{prefab = "kyno_ant_queen",atlas = "images/inventoryimages/kyno_antqueen.xml", tex = "kyno_antqueen.tex"},
	{prefab = "kyno_aporkalypse_calendar", atlas = "images/inventoryimages/kyno_calendar.xml", tex = "kyno_calendar.tex"},
	{prefab = "kyno_smashingpot"},
	{prefab = "wall_pig_ruins_item", atlas = "images/inventoryimages/kyno_ancientwall.xml", tex = "kyno_ancientwall.tex"},
	{prefab = "kyno_rock_artichoke", atlas = "images/inventoryimages/kyno_artichoke.xml", tex = "kyno_artichoke.tex"},
	{prefab = "kyno_ruins_head", atlas = "images/inventoryimages/kyno_ruins_gianthead.xml", tex = "kyno_ruins_gianthead.tex"},
	{prefab = "kyno_ruins_pigstatue"},
	{prefab = "kyno_ruins_antstatue"},
	{prefab = "kyno_ruins_idolstatue"},
	{prefab = "kyno_ruins_plaquestatue"},
	{prefab = "kyno_ruins_trufflestatue"},
	{prefab = "kyno_ruins_sowstatue"},
	{prefab = "kyno_brazier"},
	{prefab = "kyno_wishingwell"},
	{prefab = "kyno_endwell"},
	{prefab = "kyno_strikingstatue", atlas = "images/inventoryimages/kyno_dartstatue.xml", tex = "kyno_dartstatue.tex"},

}
if build_x_y_times then
	for k,v in ipairs(structures) do
		local tab = {}
		tab.text = v.prefab
		tab.fn = function(player,amount,questname) build_x_y_times(player,amount,v.prefab,questname) end
		tab.tex = v.tex or v.prefab..".tex"
		tab.atlas = v.atlas or "images/inventoryimages/"..v.prefab..".xml"
		table.insert(goals,tab)
	end
end

AddSimPostInit(function()
	for k,v in ipairs(goals) do
		local prefab = v.text
		local name = GLOBAL.STRINGS.NAMES[string.upper(prefab)]
		v.text = name and "Build x "..name or "No Name"
		v.counter = v.text
	end
	GLOBAL.AddCustomGoals(goals,"TheArchitectPack")
end)
