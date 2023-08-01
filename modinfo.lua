name = "Quest System [BETA]"
description = "Introduces a quest system into the game!\n\nOpen your quest log to see which quests you can do.\nBuild the quest board to accept new quests or be lucky enough to find requests in the wild!\n\nLevel up, get stronger and compete against powerful Boss Creatures to receive rewards!"
author = "Monti"
version = "1.0.113"

forumthread = ""

api_version = 10

dst_compatible = true

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

all_clients_require_mod = true 
client_only_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

priority = 1.79769313486230e+308

server_filter_tags = {
"quest","mission","custom","create","monti","RPG",
}

bugtracker_config = {
    email = "georgwimbledon@gmail.com",
    upload_client_log = true,
    upload_server_log = true,
    upload_other_mods_crash_log = true,
    
}


local empty_opts = {{description = "", data = 0}}
local function Title(title, hover)
    return {
        name = title,
        hover = hover,  
        options = empty_opts,
        default = 0,
    }
end

folder_name = folder_name or "Quest_System"
if not folder_name:find("workshop-") then
    name = name.." -dev"
end

local function MakeAdditionalModConfig(name,shown_name)
    return {
        name = name,
        label = shown_name,
        hover = "Enable or disable additional quests and quest creation options if you have the mod "..shown_name.." enabled.",
        options = 
        {
            {description = "Enabled", data = true}, 
            {description = "Disabled", data = false},
        },
        default = true,
    }
end

configuration_options = {

Title("Quest Options",""),

    {
        name = "REQUEST_QUEST",
        label   = "Probability of quest drops",
        hover   = "Adjust the probability of creatures dropping requests for quests when killed.",
        options = {
            {description = "0.1%", data = 0.001},
            {description = "0.5%", data = 0.005},
            {description = "1%", data = 0.01},
            {description = "2%", data = 0.02},
            {description = "5%", data = 0.05},
            {description = "10%", data = 0.1},
        },
        default = 0.01,
    },

    {
        name = "RANK",
        label   = "Ranking System",
        hover   = "Define if you can only get quests from the Quest Board that correspond to your rank.",
        options = {
            {description = "Disabled", data = false,  hover = "Quests of all difficulties"},
            {description = "Enabled", data = 0, hover = "Quests of your Rank"},
            {description = "+1", data = 1, hover = "Quests of your Rank + 1"},
            {description = "+2", data = 2, hover = "Quests of your Rank + 2"},
            {description = "+3", data = 3, hover = "Quests of your Rank + 3"},
        },
        default = 1,
    },

    {
        name = "BASE_QUEST_SLOTS",
        label   = "Amount of Quest Slots",
        hover   = "Define how many base quest slots should be available.",
        options = {
            {description = "5", data = 5,  hover = "5 Base Quest Slots"},
            {description = "10", data = 10, hover = "10 Base Quest Slots"},
            {description = "15", data = 15, hover = "15 Base Quest Slots"},
            {description = "20", data = 20, hover = "20 Base Quest Slots"},
        },
        default = 10,
    },

    {
        name = "QUEST_BOARD",
        label = "Quest Board Cost",
        hover = "How difficult the Quest Board should be to make",
        options = 
        {
        	{description = "Easy", data = 0, hover = "󰀝: 10 Flint/3 Boards/2 Cut Stones"}, 
            {description = "Normal", data = 1, hover = "󰀝: 3 Ropes/5 Goldnugget/5 Cut Stones"},
            {description = "Difficult", data = 2, hover = "󰀩: 10 Marmor/6 Papyrus/2 Beeswax",},
            {description = "Very Difficult", data = 3, hover = "󰀀Ancient Psendoscience Station: 12 Papyrus/5 Thulecite/5 Living Logs"},
        },
        default = 1,
    },

    {
        name = "REWARDS_AMOUNT",
        label = "Amount of rewards",
        hover = "How many rewards you should receive when completing quests.",
        options = 
        {
            {description = "Lowest", data = 0.3, hover = "30% of normal rewards"}, 
            {description = "Lower", data = 0.6, hover = "60% of normal rewards"}, 
            {description = "Normal", data = 1, hover = "100% of normal rewards"},
            {description = "Higher", data = 1.5, hover = "150% of normal rewards"},
            {description = "Highest", data = 2, hover = "200% of normal rewards"},
        },
        default = 1,
    }, 

    {
        name = "CRAFTING_REQUEST",
        label = "Crafting Requests",
        hover = "Choose if you want requests to be craftable or not.\nRequests are items that give you a quest upon reading them.",
        options = 
        {
            {description = "Yes", data = true}, 
            {description = "No", data = false},
        },
        default = false,
    },

    {
        name = "CRAFTING_REQUEST_DIFFICULTY",
        label = "Crafting Difficulty Requests",
        hover = "Choose if you want requests of different difficulties to be craftable or not.\nThese Requests are items that give you a quest of a certain difficulty upon reading them.",
        options = 
        {
            {description = "Yes", data = true}, 
            {description = "No", data = false},
        },
        default = false,
    },

    {
        name = "PROB_CHAR_QUEST",
        label = "Probability of Char-specific Quests",
        hover = "Adjust how probable it is to get a characterspecific quest.",
        options = 
        {
            {description = "0%", data = 0, hover = "No chance of getting characterspecific quests"}, 
            {description = "3%", data = 0.03}, 
            {description = "5%", data = 0.05},
            {description = "10%", data = 0.1}, 
            {description = "20%", data = 0.2},
            {description = "30%", data = 0.3}, 
            {description = "40%", data = 0.4},
            {description = "50%", data = 0.5}, 
        },
        default = 0.05,
    },

    {
        name = "FRIENDLY_KILLS",
        label = "Friendly Kills",
        hover = "Choose if kills from players in your proximity should count towards your quests.",
        options = 
        {
            {description = "Enabled", data = true,}, 
            {description = "Disabled", data = false},
        },
        default = true,
    },

    {
        name = "INITIAL_QUESTS",
        label = "Amount of Initial Quests",
        hover = "Choose how many of the already implemented quests you want to use.",
        options = 
        {
            {description = "0", data = 0, hover = "Do this only if you have some quests of your own, otherwise this will cause errors!"}, 
            {description = "5", data = 5},
            {description = "10", data = 10},
            {description = "20", data = 20},
            {description = "30", data = 30},
            {description = "40", data = 40},
            {description = "50", data = 50},
            {description = "All", data = true},
        },
        default = true,
    },

    {
        name = "GLOBAL_REWARDS",
        label = "Global Requirements/Rewards",
        hover = "Choose if you want global quest requirements/rewards to be enabled (i.e. things that concern everyone, for ex. next night fullmoon).",
        options = 
        {
            {description = "Disabled", data = false, hover = "Global quest requirements/rewards will be disabled"}, 
            {description = "Enabled", data = true, hover = "Global quest requirements/rewards will be enabled"},
        },
        default = true,
    },

    {
        name = "MAX_AMOUNT_GODLY_ITEMS",
        label = "Max Amount of strong items",
        hover = "Choose how many strong items can be gotten from finishing quest lines or the likes (for ex:nightmare chester)",
        options = 
        {
            {description = "1", data = 1, hover = "Only 1 of those items can exist"}, 
            {description = "2", data = 2, hover = "2 of those items can exist"}, 
            {description = "3", data = 3, hover = "3 of those items can exist"}, 
            {description = "4", data = 4, hover = "4 of those items can exist"}, 
            {description = "5", data = 5, hover = "5 of those items can exist"}, 
            {description = "6", data = 6, hover = "6 of those items can exist"}, 
            {description = "7", data = 7, hover = "7 of those items can exist"}, 
            {description = "8", data = 8, hover = "8 of those items can exist"}, 
            {description = "9", data = 9, hover = "9 of those items can exist"}, 
            {description = "10", data = 10, hover = "10 of those items can exist"}, 
            
        },
        default = 2,
    }, 

Title("UI Options",""),
    
    {
        name = "LANGUAGE",
        label = "Language",
        hover = "Choose the language you would like to use.",
        options = 
        {
            {description = "English", data = "en"}, 
            {description = "Chinese", data = "ch"},
            {description = "Russian", data = "ru"},
            {description = "German", data = "de"}, 
            {description = "French", data = "fr"},
            {description = "Spanish", data = "es"},
        },
        default = "en",
    },

    {
        name = "BUTTON",
        label = "Quest Log Button",
        hover = "Choose if and where you want a button on the screen to open the quest log or not.",
        options = 
        {
            {description = "Draggable",data = 1, hover = "Located in the bottom right corner, can be dragged to where you want"},
             {description = "Esc Menu",data = 3, hover = "Located in the Pause/Esc Menu"},
            {description = "Disable", data = 0},

        },
        default = 1,
    },

    {
        name = "HOTKEY_QUESTLOG",
        label   = "Hotkey for Quest Log",
        hover   = "Define the hotkey that is used to open your quest log.",
        options = 
            {
            {description="None",data = "nil"},
            {description="A", data = 98},
            {description="B", data = 99},
            {description="C", data = 100},
            {description="D", data = 101},
            {description="E", data = 101},
            {description="F", data = 102},
            {description="G", data = 103},
            {description="H", data = 104},
            {description="I", data = 105},
            {description="J", data = 106},
            {description="K", data = 107},
            {description="L", data = 108},
            {description="M", data = 109},
            {description="N", data = 110},
            {description="O", data = 111},
            {description="P", data = 112},
            {description="Q", data = 113},
            {description="R", data = 114},
            {description="S", data = 115},
            {description="T", data = 116},
            {description="U", data = 117},
            {description="V", data = 118},
            {description="W", data = 119},
            {description="X", data = 120},
            {description="Y", data = 121},
            {description="Z", data = 122},
            {description="F1", data = 282},
            {description="F2", data = 283},
            {description="F3", data = 284},
            {description="F4", data = 285},
            {description="F5", data = 286},
            {description="F6", data = 287},
            {description="F7", data = 288},
            {description="F8", data = 289},
            {description="F9", data = 290},
            {description="F10", data = 291},
            {description="F11", data = 292},
            {description="F12", data = 293},

            {description="UP", data = 273},
            {description="DOWN", data = 274},
            {description="RIGHT", data = 275},
            {description="LEFT", data = 276},
            {description="PAGEUP", data = 281},
            {description="PAGEDOWN", data = 282},

            {description="0", data = 48},
            {description="1", data = 49},
            {description="2", data = 50},
            {description="3", data = 51},
            {description="4", data = 52},
            {description="5", data = 53},
            {description="6", data = 54},
            {description="7", data = 55},
            {description="8", data = 56},
            {description="9", data = 57},
        },
        default = 116,
    },

    {
        name = "COLORBLINDNESS",
        label = "Colorblindness",
        hover = "If you are colorblind, different colors will be used.",
        options = 
        {
            {description = "Enabled", data = 1}, 
            {description = "Disabled", data = 0},
        },
        default = 0,
    },

    {
        name = "LOADING_TIPS",
        label = "Loading Tips",
        hover = "Choose how often loading tips for the quest system should appear.",
        options = 
        {
            {description = "Never", data = 0, hover = "Loading tips will be disable"}, 
            {description = "Barely", data = 0.2,hover = "Loading tips will appear barely (20% of normal)"},
            {description = "Rare", data = 0.5,hover = "Loading tips will appear rarely (50% of normal)"},
            {description = "Normal", data = 1,hover = "Loading tips will appear a normal amount of times"},
            {description = "Often", data = 1.5,hover = "Loading tips will appear often (150% of normal)"},
            {description = "Very Often", data = 2,hover = "Loading tips will appear often (200% of normal)"},
        },
        default = 1,
    },

Title("Custom Quests",""),

    {
        name = "CUSTOM_QUESTS",
        label   = "Custom quests",
        hover   = "Define if custom quests can be created and by who.",
        options = {
            {description = "Nobody", data = 0, hover = "Nobody can create custom quests"},
            {description = "Everyone", data = 1, hover = "Everybody can create custom quests in the quest board"},
            {description = "Admin", data = 2, hover = "Only admins can create custom quests in the quest board"},
            {description = "Custom", data = 3, hover = "Admins can choose who can create quests by holding tab and clicking on the button"},
        },
        default = 1,
    },

    {
        name = "MANAGE_CUSTOM_QUESTS",
        label   = "Manage Custom Quests",
        hover   = "Define who can delete and see all custom quests that were made.",
        options = {
            {description = "Everybody", data = 0, hover = "Everybody can see and delete custom quests"},
            {description = "Admin", data = 1, hover = "Admins can see and delete custom quests"},
            {description = "Nobody", data = 2, hover = "Nobody can see and delete custom quests"},
        },
        default = 1,
    },

    {
        name = "GIVE_CREATOR_QUEST",
        label = "Gain requests for created quests",
        hover = "Choose if you want to receive requests for the specific quest you created and how many.",
        options = 
        {
            {description = "No request", data = 0}, 
            {description = "1", data = 1},
            {description = "2", data = 2}, 
            {description = "3", data = 3},
            {description = "4", data = 4}, 
            {description = "5", data = 5},
        },
        default = 0,
    },

Title("Bossfight Options",""),

    {
        name = "BOSSFIGHTS",
        label = "Bossfights",
        hover = "Choose if you want Bossfights to be enabled.\nBossfights are battles against stronger creatures that ,if beaten, give a reward.",
        options = 
        {
            {description = "Enabled", data = true, hover = "You will be able to start a boss fight from the quest log"}, 
            {description = "Disabled", data = false, hover = "No bossfights for you..."},
        },
        default = true,
    },

    {
        name = "BOSS_DIFFICULTY",
        label = "Boss difficulty",
        hover = "How difficult Bosses should be.",
        options = 
        {
            {description = "Very Easy", data = 0.5, hover = "50% of normal difficulty"}, 
            {description = "Easy", data = 0.75, hover = "75% of normal difficulty"}, 
            {description = "Normal", data = 1, hover = "100% of normal difficulty"},
            {description = "Difficult", data = 1.5, hover = "150% of normal difficulty"},
            {description = "Very Difficult", data = 2, hover = "200% of normal difficulty"},
        },
        default = 1,
    },

    {
        name = "BOSS_ISLAND",
        label   = "Create a boss island",
        hover   = "Enable or disable a creation of a boss island when the server is first created. Doesn't change anything afterwards.",
        options = {
            {description = "Yes", data = true, hover = "A boss island will be created somewhere in the ocean."},
            {description = "No", data = false},
        },
        default = true,
    },

Title("Level System",""),

    {
        name = "LEVELSYSTEM",
        label = "Enable Level System",
        hover = "Enable or disable the Level System, which makes your character stronger as you get a higher level.",
        options = 
        {
            {description = "Enabled", data = 1}, 
            {description = "Disabled", data = 0},
        },
        default = 1,
    },

    {
        name = "LEVEL_RATE",
        label = "Level Rate",
        hover = "Adjust how fast you want to level up.",
        options = 
        {
            {description = "Very Slow", data = 2, hover = "200% of exp needed for level up"}, 
            {description = "Slow", data = 1.5, hover = "150% of exp needed for level up"}, 
            {description = "Normal", data = 1, hover = "100% of exp needed for level up"},
            {description = "Fast", data = 0.75, hover = "75% of exp needed for level up"},
            {description = "Very Fast", data = 0.5}, hover = "50% of exp needed for level up",
        },
        default = 1,
    },

    {
        name = "LEVELUPRATE",
        label = "Level Bonus Amount",
        hover = "Choose how big of a bonus you want for leveling up.",
        options = 
        {
            {description = "Very Small", data = 0.25, hover = "50% of normal bonus"}, 
            {description = "Small", data = 0.375, hover = "75% of normal bonus"},
            {description = "Normal", data = 0.5, hover = "100% of normal bonus"}, 
            {description = "Big", data = 0.75, hover = "150% of normal bonus"},
            {description = "Very Big", data = 1, hover = "200% of normal bonus"}, 
            {description = "Enormous", data = 2.5, hover = "500% of normal bonus"}, 
        },
        default = 1,
    },

    {
        name = "KEEP_LEVELS",
        label = "Keep Levels",
        hover = "Choose if levels are kept if the server is regenerated or not",
        options =
        {
            {description = "Reset", data = 0, hover = "Levels are reset during regeneration"},
            {description = "Kept", data = 1, hover = "Levels are kept during regeneration"},
        },
        default = 0,
    },

Title("Mod Quests",""),

    MakeAdditionalModConfig("ISLAND_ADVENTURES","Island Adventures"),
    MakeAdditionalModConfig("TROPICAL_EXPERIENCE","Tropical Experience"),
    MakeAdditionalModConfig("TAP","The Architect Pack"),
    MakeAdditionalModConfig("UNCOMPROMISING_MODE","Uncompromising Mode"),
    MakeAdditionalModConfig("LEGION","Legion"),
    MakeAdditionalModConfig("CHERRY_FOREST","Cherry Forest"),
    MakeAdditionalModConfig("FEAST_FAMINE","Feast and Famine"),
    MakeAdditionalModConfig("MUSHA","Musha"),
    MakeAdditionalModConfig("FUNCTIONAL_MEDAL","Functional Medal"),

Title("Miscellaneous",""),

    {
        name = "CLIENT_DATA",
        label = "Client/Server Preferences",
        hover = "Choose if you want the language,colorblindness,hotkey and button position to be client defined or defined by the server.",
        options = 
        {
            {description = "Client", data = true, hover = "Clients can choose which language they want and so on..."}, 
            {description = "Server", data = false, hover = "The server settings decide the language and so on..."},
        },
        default = false,
    },
    {
        name = "RESET_QUESTS",
        label = "Reset custom quests",
        hover = "If set on yes, it will remove all custom quests that have been made and save them as a backup. If you already had a backup, it will be overwritten. Load backup loads the backupped file, your original will be overwritten.",
        options = 
        {
            {description = "Yes", data = true}, 
            {description = "No", data = false},
            {description = "Load Backup", data = 1},
        },
        default = false,
    },
    {
        name = "DEBUG",
        label = "Un-Crash Mode",
        hover = "If you experience crashing when starting the server, try to enable this option. It will stop all functions that are run on server start which can cause crashes if you changed mods in between starts.",
        options = 
        {
            {description = "Enabled", data = 1}, 
            {description = "Disabled", data = 0},
        },
        default = 0,
    },



}