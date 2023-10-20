local SPECIALINFO = GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO
SPECIALINFO.NIGHTMARE_EYEBONE = ""
SPECIALINFO.FROGKING_P_CROWN = ""
SPECIALINFO.FROGKING_SCEPTER = ""
SPECIALINFO.GLOMMERFUELMACHINE_ITEM = ""
SPECIALINFO.GLOMMERFUELMACHINE = ""
SPECIALINFO.BLACKGLOMMERFUEL = ""
SPECIALINFO.GLOMMER_LIGHTFLOWER = ""
SPECIALINFO.QUESTBOARD = ""
SPECIALINFO.REQUEST_QUEST = ""
SPECIALINFO.SHADOW_CREST = ""
SPECIALINFO.SHADOW_MITRE = ""
SPECIALINFO.SHADOW_LANCE = ""


local ITEMS = {
    nightmarechester_eyebone = {name="nightmarechester_eyebone", tex="nightmarechester_eyebone_closed.tex", type="item", prefab="nightmarechester_eyebone", build="nightmarechester_eyebone", bank="eyebone", anim="idle_loop", specialinfo="NIGHTMARE_EYEBONE"},
    frogking_p_crown = {name="frogking_p_crown", tex="frogking_p_crown.tex", subcat="hat", type="item", prefab="frogking_p_crown", fueledmax=2000, fueledrate=1, fueledtype1="FROGLEGS", build="frogking_p_crown", bank="frogking_p_crown", anim="anim", waterproofer=0.35, insulator=180, insulator_type="winter", deps={"frogking", "frog", "frogking_scepter"}, specialinfo="FROGKING_P_CROWN"},
    frogking_scepter = {name="frogking_scepter", tex="frogking_scepter.tex", subcat="weapon", type="item", prefab="frogking_scepter", weapondamage=45, finiteuses=300, build="frogking_scepter",fueledtype1="FROGLEGS", bank="frogking_scepter", anim="idle_loop", deps={"frogking", "frog", "frogking_p_crown"}, specialinfo="FROGKING_SCEPTER"},
    glommerfuelmachine_item = {name="glommerfuelmachine_item", tex="glommerfuelmachine_item.tex", type="item", prefab="glommerfuelmachine_item", build="glommerfuelmachine_item", bank="glommerfuelmachine_item", anim="idle", deps={"glommerfuelmachine", "glommer_boss"}, specialinfo="GLOMMERFUELMACHINE_ITEM"},
    glommerfuelmachine = {name="glommerfuelmachine", tex="glommerfuelmachine_item.tex", type="thing", prefab="glommerfuelmachine", build="blackglommerspit_gerat", bank="blackglommerspit_gerat", anim="working_nospin", workable="HAMMER", pickable=true, deps={"glommer_boss", "glommerfuelmachine_item"}, specialinfo="GLOMMERFUELMACHINE"},
    blackglommerfuel = {name="blackglommerfuel", tex="blackglommerfuel.tex", type="item", prefab="blackglommerfuel", build="blackglommerfuel", bank="blackglommerfuel", anim="idle",fueltype="BURNABLE", fuelvalue=180, stacksize=10, hungervalue=-75, healthvalue=-60, sanityvalue=-50, specialinfo="BLACKGLOMMERFUEL"},
    glommer_lightflower = {name="glommer_lightflower", tex="glommer_lightflower.tex", type="item", prefab="glommer_lightflower", build="glommer_lightflower", bank="glommer_lightflower", anim="idle", specialinfo="GLOMMER_LIGHTFLOWER"},
    questboard = {name="questboard", tex="questboard.tex", type="thing", prefab="questboard", build="quest_board", bank="quest_board", anim="idle", workable="HAMMER", deps={"cutstone", "rope", "goldnugget"}, specialinfo="QUESTBOARD"},
    request_quest = {name="request_quest", tex="request_quest.tex", type="item", prefab="request_quest", build="request_quest", bank="request_quest", anim="idle", specialinfo="REQUEST_QUEST"},
    shadow_crest = {name="shadow_crest", tex="shadow_crest.tex", subcat="armor", type="item", prefab="shadow_crest",armor=666, absorb_percent=0.9, armor_planardefense=10, build="shadow_crest",fueledtype1="NIGHTMARE", bank="shadow_crest", anim="anim", deps={"shadow_knight", "shadow_bishop", "shadow_rook", "shadow_mitre", "shadow_lance"}, notes={shadow_aligned=true}, specialinfo="SHADOW_CREST"},
    shadow_mitre = {name="shadow_mitre", tex="shadow_mitre.tex", subcat="armor", type="item", prefab="shadow_mitre",armor=1000, absorb_percent=0.9, armor_planardefense=10, build="shadow_mitre",fueledtype1="NIGHTMARE", bank="shadow_mitre", anim="anim", deps={"shadow_knight", "shadow_bishop", "shadow_rook", "shadow_crest", "shadow_lance"}, notes={shadow_aligned=true}, specialinfo="SHADOW_MITRE"},
    shadow_lance = {name="shadow_lance", tex="shadow_lance.tex", subcat="weapon", type="item", prefab="shadow_lance", weapondamage=45, planardamage=15, finiteuses=200, build="shadow_lance",fueledtype1="NIGHTMARE", bank="shadow_lance", anim="anim", deps={"shadow_knight", "shadow_bishop", "shadow_rook", "shadow_crest", "shadow_mitre"}, specialinfo="SHADOW_LANCE"},

}


local scrapbook_prefabs = require("scrapbook_prefabs")
local scrapbookdata = require("screens/redux/scrapbookdata")

for k, v in pairs(ITEMS) do
    if v.anim ~= nil then
        v.name = v.name or k
        v.prefab = v.prefab or k
        v.tex = v.tex or k..".tex"
        v.type = v.type or "item"
        v.deps = v.deps or {}
        v.notes = v.notes or {}

        scrapbook_prefabs[k] = true
        scrapbookdata[k] = v
    end
end

local CREATURES = {
    nightmarechester = {name="nightmarechester", tex="nightmarechester.tex", type="creature", prefab="nightmarechester", health=450, build="nightmarechester", bank="nightmarechester", anim="idle_loop", deps={"nightmarechester_eyebone"}},
    chester_boss = {name="chester_boss", tex="chester_boss.tex", type="giant", prefab="chester_boss", health=666, damage=150, build="nightmarechester", bank="nightmarechester", anim="idle_loop", deps={"nightmarechester_eyebone", "nightmarechester"}},
    glommer_small = {name="glommer_small", tex="glommer_small.tex", type="creature", prefab="glommer_small", health=33, damage=10, build="glommer_boss", bank="glommer_boss", anim="idle_loop", deps={"glommer_boss", "glommerfuelmachine", "glommerfuelmachine_item", "blackglommerfuel"}},
    glommer_boss = {name="glommer_small", tex="glommer_boss.tex", type="giant", prefab="glommer_small", health=666, damage=100, build="glommer_boss", bank="glommer_boss", anim="idle_loop", deps={"glommer_small", "glommerfuelmachine", "glommerfuelmachine_item", "blackglommerfuel"}},
    frogking = {name="frogking", tex="frogking.tex", type="giant", prefab="frogking", health=30000, damage=250, build="frogking", bank="frogking", anim="idle", deps={"frogking_scepter", "frogking_p_crown"}},
}


for k, v in pairs(CREATURES) do
    v.name = k
    v.prefab = k
    v.tex = k..".tex"
    v.type = v.type or "creature"
    v.deps = v.deps or {}
    v.notes = v.notes or {}

    scrapbook_prefabs[k] = true
    scrapbookdata[k] = v
end

local OldGetScrapbookIconAtlas = GLOBAL.GetScrapbookIconAtlas
function GLOBAL.GetScrapbookIconAtlas(imagename, ...)
    if CREATURES[string.sub(imagename, 1, -5)] then
        return "images/quest_component_scrapbook.xml"
    else
        return OldGetScrapbookIconAtlas(imagename, ...)
    end
end