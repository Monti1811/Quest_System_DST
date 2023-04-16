local require = GLOBAL.require

Assets = {
	Asset("ANIM", "anim/player_progressbar_small.zip"),

	--Buildings
	Asset("ANIM", "anim/lavaarena_portal.zip"),
	Asset("ANIM", "anim/lavaarena_portal_fx.zip"),

	Asset("ANIM", "anim/quest_stars.zip"),
	Asset("ANIM", "anim/request_quest.zip"),
	Asset("ANIM", "anim/quest_board.zip"),

	--Big atlases (for inventoryitems and more)
	Asset("ATLAS", "images/victims.xml"),
	Asset("ATLAS", "images/images_quest_system.xml"),

	--Loading screen image
	Asset("ATLAS", "images/loadingtip_quest_board.xml"),
	Asset("IMAGE", "images/loadingtip_quest_board.tex"),

	--Quest board screens
	Asset("ATLAS", "images/quest_board_widget.xml"),
	Asset("ATLAS", "images/quest_board_widget2.xml"),
	Asset("ATLAS", "images/quest_log_bg.xml"),
	Asset("ATLAS", "images/quest_log_page.xml"),
	Asset("ATLAS", "images/quest_log_page2.xml"),

	--Custom Bosses
	Asset("ANIM", "anim/nightmarechester.zip"),
	Asset("ANIM", "anim/nightmarechester_ground_fx.zip"),
    Asset("ANIM", "anim/nightmarechester_splash.zip"),
    Asset("ANIM", "anim/nightmarechester_splat.zip"),

	Asset("ANIM", "anim/glommer_boss.zip"),
    Asset("ANIM", "anim/purple_goo.zip"),

	Asset("ANIM", "anim/frogking.zip"),
    Asset("ANIM", "anim/frogking_anim.zip"),
	Asset("ANIM", "anim/frogking_beyblade.zip"),


	--Custom Rewards
	Asset("ANIM", "anim/frogking_scepter.zip"),
	Asset("ANIM", "anim/frogking_p_crown.zip"),

	Asset("ANIM", "anim/blackglommerfuel.zip"),
	Asset("ANIM", "anim/glommerfuelmachine_item.zip"),
	Asset("ANIM", "anim/blackglommerspit_gerat.zip"),
	Asset("ANIM", "anim/nightmarechester_eyebone.zip"),

}

PrefabFiles = {
	"questboard",
	"request_quest",
	"quest_system_fx",
	"boss_island_ceiling",

	--Custom Rewards
	"glommer_lightflower",
	"shadow_piece_items",

	--Custom Bosses
	"frogking",
	"glommer_puddle",
	"glommer_boss",
	"chester_boss",


}

--Debug functions
function GLOBAL.devprint(...)
	if GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE then
		print(...)
	end
end
function GLOBAL.devdumptable(...)
	if GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE then
		GLOBAL.dumptable(...)
	end
end

devprint = GLOBAL.devprint
devdumptable = GLOBAL.devdumptable

--Make our quest component replicable
AddReplicableComponent("quest_component")

---------------Register custom atlases so that they show up on the client--------------------------------------
local tex_images = require("tex_files")
local function RegisterCustomAtlases(name)
	if tex_images[name] == nil then return end
	for _,tex in ipairs(tex_images[name]) do
		RegisterInventoryItemAtlas("images/"..name..".xml",tex..".tex")
	end
end

RegisterCustomAtlases("victims")
RegisterCustomAtlases("images_quest_system")

----------------------------------------------------------------------------------------------------------------

modimport("quest_system/tuning_strings.lua") 		--initialization of variables
modimport("quest_system/RPC.lua") 					--setting all RPC calls needed for communication between server and client
modimport("quest_system/Quest_Board_Util.lua")		--loading helper functions for the quest board and quest log as well as functions for quests
modimport("quest_system/postinitfns.lua")			--loading all postinit fns added to prefabs
modimport("quest_system/postinitclass.lua")			--loading all postinit fns added to classes
modimport("quest_system/actions.lua")				--loading new/changed actions
modimport("quest_system/consolecommands.lua")		--loading custom console commands to make debugging easier (and cheating if you want to ;))
modimport("quest_system/init_custom_quests.lua")	--loading the custom quests saved as a persistent string and/or json encoded string
modimport("quest_system/recipes.lua")				--loading new recipes
if GLOBAL.TUNING.QUEST_COMPONENT.DEV_MODE then
	modimport("quest_system/random_quest_generator.lua") --load the random quest generator
	--Debug
	--GLOBAL.CHEATS_ENABLED = true
	--GLOBAL.require( 'debugkeys' )
	--GLOBAL.require( 'debugprint' )

end

---------------------------------------------Additional Content from other mods----------------------------------

local additional_content = {
	tropical_experience = 1505270912,
	tap = 2428854303,
	uncompromising_mode = 2039181790,
	legion = 1392778117,
	cherry_forest = 1289779251,
	feast_famine = 1908933602,
	epic = 1615010027,
}

for name,num in pairs(additional_content) do
	if GetModConfigData(string.upper(name)) == true and GLOBAL.KnownModIndex:IsModEnabledAny("workshop-"..num) then
		if kleifileexists(MODS_ROOT..modname.."/images/victims_"..name..".xml") then
			table.insert(Assets,Asset("ATLAS", "images/victims_"..name..".xml"))
		end
		--RegisterCustomAtlases("victims_"..name)
		modimport("mod_util/"..name..".lua")
	end
end

--Insight support
modimport("mod_util/insight.lua")
