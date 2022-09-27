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
	"elecarmet",
	"boltwingout",
	"cropgnat",
	"cropgnat_infester",
	"raindonate",
	"sandspike_legion",
}

local item_list = {"cutted_rosebush","rosorns","petals_rose","petals_lily","cutted_lilybush","lileaves","petals_orchid","cutted_orchidbush","orchitwigs","neverfade","sachet","foliageath","squamousfruit","monstrain_leaf","book_weather","agronssword","refractedmoonlight","hiddenmoonlight_item","merm_scales","hat_mermbreathing","giantsfoot","fimbul_axe","tourmalinecore","tripleshovelaxe","dualwrench","icire_rock","web_hump_item","soul_contracts","guitar_miguel","hat_cowboy","saddle_baggage","hat_albicans_mushroom","albicans_cap","shyerry","shyerry_cooked","guitar_whitewood","desertdefense","pinkstaff","theemperorscrown","theemperorsmantle","theemperorsscepter","hat_lichen","backcub",}

local function elecarmet(inst)
	local function OnDeath(inst)
		GLOBAL.TheWorld:DoTaskInTime(0,function()
			if inst:IsValid() then
				local pos = inst:GetPosition()
				local elecourmaline = TheSim:FindEntities(pos.x,pos.y,pos.z,3)
				for k,v in ipairs(elecourmaline) do
					if v.prefab == "elecourmaline" and v:IsValid() then
						if v.keystone and type(v.keystone) == "table" then
							for kk,vv in pairs(v.keystone) do
								if vv:IsValid() then
									vv:Remove()
								end
							end
						end
						v:Remove()
					end
				end
			end
		end)
	end
	inst:ListenForEvent("death",OnDeath)
end

local boss = {	name = "elecarmet", health = 10000, damage = 200, scale = 1.7, fn = elecarmet}

AddBosses(boss,"DIFFICULT")

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
	AddCustomGoals(goals,"Legion")
	for k,v in pairs(require("preparedfoods_legion")) do
		table.insert(item_list,k)
	end
	AddCustomRewards(item_list)
end)