local assets =
{
    Asset("ANIM", "anim/nightmarechester_ground_fx.zip"),
    Asset("ANIM", "anim/nightmarechester_splash.zip"),
    Asset("ANIM", "anim/nightmarechester_splat.zip"),
    Asset("ANIM", "anim/purple_goo.zip"),
}


local new_fx = {
    {
        name = "greenfiresplash_fx",
        bank = "dragonfly_ground_fx",
        build = "nightmarechester_ground_fx",
        anim = "idle",
        bloom = true,
    },

    {
        name = "nightmarechester_splat_fx",
        bank = "spat_splat",
        build = "nightmarechester_splat",
        anim = "idle",
    },
    {
        name = "nightmarechester_splash_fx_full",
        bank = "spat_splash",
        build = "nightmarechester_splash",
        anim = "full",
    },
    {
        name = "nightmarechester_splash_fx_med",
        bank = "spat_splash",
        build = "spat_splash",
        anim = "med",
    },
    {
        name = "nightmarechester_splash_fx_low",
        bank = "spat_splash",
        build = "nightmarechester_splash",
        anim = "low",
    },
    {
        name = "nightmarechester_splash_fx_melted",
        bank = "spat_splash",
        build = "nightmarechester_splash",
        anim = "melted",
    },
}

local prefs = {}
local MakeFx = require("quest_util/make_fx")
for _,fxs in ipairs(new_fx) do
    table.insert(prefs, MakeFx(fxs))
end

return unpack(prefs)