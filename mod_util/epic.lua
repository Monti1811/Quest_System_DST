local goals = {}

local function AddPrefabToGoals(prefab,atlas,tex,name)
	local tab = {}
	tab.prefab = prefab
	tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
	tab.tex = tex or prefab..".tex"
	tab.atlas = atlas or "images/victims_epic.xml"
	return tab
end

local prefabs = {
	"ambushling",
	"forced_ambushling",
	{prefab = "butterfly_spicy",atlas = "images/inventoryimages/inventoryimages_epic.xml"},
	"merm_warbuck",
	"smallwalrus_caught",
	"wyrmmyrrh_boss",
}

local bosses = {
	EASY = {

		{name = "ambushling", health = 1000, damage = 100, scale = 2,},

	},

	DIFFICULT = {

		{name = "wyrmmyrrh_boss", health = 10000, damage = 200, scale = 1.7,},

	},
}

for diff,boss in pairs(bosses) do
	for _,data in ipairs(boss) do
		GLOBAL.AddBosses(data,diff)
	end
end

local item_list = {"armor_artisan","armor_artisan_bp1","armor_artisan_bp2","armor_paperwrap","armor_paperwrap_balloon","armor_silkscarf","armor_spidertux","armorgoldchest","armorsteelchest","armorgoldtits","armorsteeltits","axe_bonechopper","axe_bonechopper_gold","backpack_clear","beautter","bhat","nbhat","bonefragment","bsword","nbsword","butterfly_spicy","cakemc","carrot_gold","cattail","charm_moonglass","clockwork_scraps","cutstone_steel","diamond","enderpearl","grenade_holy","halberd","hat_bat","hat_holhorse","hat_houndfur","hat_houndfur_ice","hat_houndfur_fire","mask_hound","hat_pith","hat_topsilk","hatpirate","headcarver","ingot_steel","holhorse_gun","houndfur","houndfur_ice","houndfur_fire","keyblade","keyblade_moon","lasso","luminut","mcsword_wood","mcsword_stone","mcsword_steel","mcsword_gold","mcsword_diamond","moonblade","moose_ale","nightmarite","nightmarite_axeice","nightmarite_dagger","nightmarite_sword","nightshade","pineapple","pinecoolada","plink_fireflies","pokeball","riskyscitmar","rockhat","s_spatula","steelaxe","staff_sacrifice","sticc","truffle","turkish_sword","villageraxe","viola_gun","wyrmmyrrh_syrup",}


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
	GLOBAL.AddCustomGoals(goals,"Epic")
	GLOBAL.AddCustomRewards(item_list)
end)