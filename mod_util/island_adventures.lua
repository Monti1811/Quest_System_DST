GLOBAL.SetQuestSystemEnv()

local goals = {}

local function AddPrefabToGoals(prefab,atlas,tex,name)
    local tab = {}
    tab.prefab = prefab
    tab.text = name or GLOBAL.STRINGS.NAMES[string.upper(prefab)] or "No Name"
    tab.tex = tex or prefab..".tex"
    tab.atlas = atlas or "images/victims_island_adventures.xml"
    tab.hovertext = GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.KILL.." x ".."/"..prefab
    return tab
end

local prefabs = {
    "babyox",
    "ballphin",
    "cormorant",
    "crab",
    "crocodog",
    "poisoncrocodog",
    "watercrocodog",
    "doydoybaby",
    "doydoy",
    "dragoon",
    "elephantcactus_active",
    "flup",
    "jellyfish",
    "knightboatbrain",
    "kraken",
    {prefab = "leif_palm",name = "Palm Treeguard"},
    {prefab = "leif_jungle",name = "Jungle Treeguard"},
    "lobster",
    "mermfisher",
    "ox",
    "packim",
    "primeape",
    "rainbowjellyfish",
    "sharkitten",
    "sharx",
    "snake",
    "snake_poison",
    "stungray",
    "swordfish",
    "tigershark",
    "tropical_spider_warrior",
    "twister",
    "twisterseal",
    "whale_blue",
    "whale_white",
    "wildbore",
    --"wildboreguardian",

}


local bosses = {
    EASY = {

        {name = "crocodog", health = 1000, damage = 100, scale = 2,},
        {name = "poisoncrocodog", health = 1000, damage = 100, scale = 2,},
        {name = "watercrocodog", health = 1000, damage = 100, scale = 2,},
        {name = "tropical_spider_warrior", health = 1000, damage = 100, scale = 2,},

    },

    NORMAL = {

        {name = "dragoon", health = 3000, damage = 150, scale = 2,},
        {name = "leif_palm", health = 3000, damage = 150, scale = 1.5,},
        {name = "leif_jungle", health = 3000, damage = 150, scale = 1.5,},
        {name = "mermfisher", health = 4000, damage = 150, scale = 2,},

    },

    DIFFICULT = {

        {name = "tigershark", health = 10000, damage = 200, scale = 1.5,},
        {name = "twister", health = 10000, damage = 200, scale = 1.5,},

    },
}

local function RemoveBoss(diff,boss)
    for k,boss_data in ipairs(bosses[diff]) do
        if boss_data.name == boss then
            return table.remove(bosses[diff],k)
        end
    end
end

for diff,boss in pairs(bosses) do
    for _,data in ipairs(boss) do
        GLOBAL.AddBosses(data,diff)
    end
end

local item_list = {"antivenom","blubber","bioluminescence","boat_lantern","boat_torch","boatrepairkit","bottlelantern","coconade","obsidiancoconade","coconut","coconut_halved","coconut_cooked","dug_coffeebush","coffeebeans","coffeebeans_cooked","coral","coral_brain","corallarve","crab","cutlass","dorsalfin","doydoyegg","doydoyegg_cooked","doydoyfeather","dragoonheart","dubloon","earring","fabric","solofish_dead","swordfish_dead","lobster_dead","lobster_dead_cooked","fish_tropical","purple_grouper","pierrot_fish","neon_quattro","hail_ice","armorseashell","armorlimestone","armorobsidian","armorcactus","armor_snakeskin","armor_windbreaker","armor_lifejacket","tarsuit","blubbersuit","parrot","parrot_pirate","toucan","cormorant","seagull","blowdart_poison","blowdart_flup","book_meteor","captainhat","snakeskinhat","piratehat","gashat","aerodynamichat","double_umbrellahat","shark_teethhat","brainjellyhat","woodlegshat","oxhat","ia_messagebottle","ia_messagebottleempty","spear_poison","spear_obsidian","needlespear","peg_leg","spoiled_fish_large","volcanostaff","windstaff","ia_trident","bamboo","vine","jellyfish_dead","jellyfish_cooked","jellyjerky","jungletreeseed","limestonenugget","limpets","limpets_cooked","lobster","machete","goldenmachete","obsidianmachete","magic_seal","monkeyball","mosquitosack_yellow","mussel","mussel_cooked","mussel_stick","mysterymeat","obsidian","obsidianaxe","ox_flute","ox_horn","packim_fishbone","palmleaf","palmleaf_umbrella","piratepack","poisonbalm","portablecookpot_item","quackenbeak","quackendrill","quackeringram","rainbowjellyfish_dead","rainbowjellyfish_cooked","rawling","roe","roe_cooked","sail_palmleaf","sail_cloth","sail_snakeskin","sail_feather","ironwind","sail_woodlegs","sand","sandbag_item","sandbagsmall_item","seasack","seashell","seatrap","seaweed","seaweed_cooked","seaweed_dried","shark_fin","shark_gills","snakeoil","snakeskin","spear_launcher","sweet_potato","tar","tarlamp","telescope","supertelescope","terraformstaff","thatchpack","tigereye","tropicalfan","tunacan","turbine_blades","venomgland","wind_conch",}


local function RemoveQuest(tab,quest_name)
    devprint("RemoveQuest",tab,quest_name)
    for k,v in ipairs(tab) do
        if v.name == quest_name then
            table.remove(tab,k)
        end
    end
end

local function GetKillString(victim,amount)
    return GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.KILL.." "..(amount or 1).." "..(GLOBAL.STRINGS.NAMES[string.upper(victim)] or "Error")
end

AddSimPostInit(function()
    for _, v in ipairs(prefabs) do
        if type(v) == "table" then
            local goal = AddPrefabToGoals(v.prefab,v.atlas,v.tex,v.name)
            table.insert(goals,goal)
        else
            local goal = AddPrefabToGoals(v)
            table.insert(goals,goal)
        end
    end
    GLOBAL.AddCustomGoals(goals,"IslandAdventures")
    for k in pairs(GLOBAL.IA_PREPAREDFOODS) do
        table.insert(item_list,k)
    end

    GLOBAL.AddCustomRewards(item_list)

    local quests = {}

    AddQuests(quests)
end)