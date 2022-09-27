GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

require("map/tasks")
require("map/lockandkey")

if GetModConfigData("BOSS_ISLAND") == true then

	Layouts["boss_island"] = StaticLayout.Get("map/static_layouts/boss_island",
		{
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER,
			disable_transform = true,
		})


	AddLevelPreInitAny(function(level)
		if level.location == "forest" then
			if level.ocean_prefill_setpieces ~= nil then
				level.ocean_prefill_setpieces["boss_island"]  = 1
			end
		end
	end)
	
end

