local strings = {
    en_strings = require("strings/strings_en"),
    de_strings = require("strings/strings_de"),
    fr_strings = require("strings/strings_fr"),
    es_strings = require("strings/strings_es"),
    ru_strings = require("strings/strings_ru"),
    ch_strings = require("strings/strings_ch"),
}

if not TUNING.QUEST_COMPONENT.GLOBAL_REWARDS then
    for k,v in pairs(strings) do
        v.QUESTS["Friends in the Shadow Realm"].HOVER = v.QUESTS["Friends in the Shadow Realm"].HOVER1
    end
end

for k,v in pairs(strings) do
    v.QUESTS["A Cute Companion"].COUNTER = STRINGS.NAMES.HUTCH_FISHBOWL
    v.QUESTS["Mage of the Manor Baldur"].COUNTER = STRINGS.NAMES.DEERCLOPS
end

local function getAllStrings()
    return {
        strings.en_strings,
        strings.de_strings,
        strings.fr_strings,
        strings.es_strings,
        strings.ru_strings,
        strings.ch_strings,
    }
end

local function getLanguageStrings(language)
    return strings[language.."_strings"]
end

return {
    getAllStrings = getAllStrings,
    getLanguageStrings = getLanguageStrings,
}
