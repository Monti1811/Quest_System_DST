--------------------------------------------Recipes-----------------------------------------------------

local QUESTBOARD_CONFIG = GetModConfigData("QUEST_BOARD") or 1
local CRAFTING_REQUEST = GetModConfigData("CRAFTING_REQUEST") or false
local CRAFTING_REQUEST_DIFFICULTY = GetModConfigData("CRAFTING_REQUEST_DIFFICULTY") or false

local ingredients = {
	[0] = { Ingredient("flint", 10 ),Ingredient("boards", 3),Ingredient("cutstone", 2)},
	[1] = { Ingredient("rope", 3 ),Ingredient("cutstone", 5),Ingredient("goldnugget", 5)},
	[2] = { Ingredient("marble", 10 ),Ingredient("papyrus", 6),Ingredient("beeswax", 2)},
	[3] = { Ingredient("papyrus", 12 ),Ingredient("thulecite", 5),Ingredient("livinglog", 5)},
}

local tech = {
	[0] = GLOBAL.TECH.SCIENCE_ONE,
	[1] = GLOBAL.TECH.SCIENCE_TWO,
	[2] = GLOBAL.TECH.MAGIC_THREE,
	[3] = GLOBAL.TECH.ANCIENT_FOUR,
}

---------------------------------------------------------------------------------------------------------

local questboard_config = {atlas = "images/images_quest_system.xml",image = "quest_board.tex",placer = "questboard_placer",min_spacing = 3}
local questboard = AddRecipe2("questboard", 
	ingredients[QUESTBOARD_CONFIG],
	tech[QUESTBOARD_CONFIG], questboard_config,{"STRUCTURES"})

---------------------------------------------------------------------------------------------------------
local function request_config(diff) 
	local img_name = "request_quest"..(diff and "_"..diff or "")..".tex"
	return {atlas = "images/images_quest_system.xml",image = img_name}
end

local filter = {"TOOLS"}
if CRAFTING_REQUEST == true then
	local request_quest = AddRecipe2("request_quest", 
		{ Ingredient("papyrus", 1 ),Ingredient("featherpencil", 1),},
		tech[2],request_config(),filter)
end

---------------------------------------------------------------------------------------------------------

if CRAFTING_REQUEST_DIFFICULTY == true then
	local request_quest_very_easy = AddRecipe2("request_quest_very_easy", 
		{ Ingredient("papyrus", 1 ),Ingredient("featherpencil", 1),},
		tech[2],request_config("very_easy"),filter)
	local request_quest_easy = AddRecipe2("request_quest_easy", 
		{ Ingredient("papyrus", 2 ),Ingredient("featherpencil", 2),},
		tech[2],request_config("easy"),filter)
	local request_quest_normal = AddRecipe2("request_quest_normal", 
		{ Ingredient("papyrus", 3 ),Ingredient("featherpencil", 3),},
		tech[2],request_config("normal"),filter)
	local request_quest_difficult = AddRecipe2("request_quest_difficult", 
		{ Ingredient("papyrus", 4 ),Ingredient("featherpencil", 4),},
		tech[2],request_config("difficult"),filter)
	local request_quest_very_difficult = AddRecipe2("request_quest_very_difficult", 
		{ Ingredient("papyrus", 5 ),Ingredient("featherpencil", 5),Ingredient("beeswax", 1)}, 
		tech[2],request_config("very_difficult"),filter)
end
---------------------------------------------------------------------------------------------------------