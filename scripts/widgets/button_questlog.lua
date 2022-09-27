local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

local Button_QuestLog = Class(Widget, function(self, owner,background)
	Widget._ctor(self,"Button_QuestLog")

	self.owner = owner
	self.root = self:AddChild(Widget("ROOT"))
	if background then
		self.button = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_square_normal.tex", "button_carny_square_hover.tex", "button_carny_square_disabled.tex", "button_carny_square_down.tex"))
		self.button_img = self.button:AddChild(Image("images/images_quest_system.xml","quest_log.tex"))
		self.button:SetScale(1)
	else
		self.button = self:AddChild(ImageButton("images/images_quest_system.xml", "quest_log.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	end
	self.button:SetOnClick(function()
		local screen = TheFrontEnd:GetActiveScreen()
        if not screen or not screen.name then return true end
        if screen.name:find("HUD") then
            TheFrontEnd:PushScreen(require("screens/quest_widget")(self.owner))
            return true
        elseif screen.name:find("PauseScreen") then
        	TheFrontEnd:PopScreen(screen)
            TheFrontEnd:PushScreen(require("screens/quest_widget")(self.owner))
            return true
        else
            if screen.name == "quest_widget" then
                screen:OnClose()
            end
		end
	end)
	self.button:SetTooltip(STRINGS.QUEST_COMPONENT.QUEST_LOG.BUTTON)
	local scale = 64 / math.max(self.button:GetSize())
	self.button:SetScale(scale, scale, scale)
	local w, h = self.button:GetSize()
	self.width = w * scale
	self.height = h * scale

end)

return Button_QuestLog