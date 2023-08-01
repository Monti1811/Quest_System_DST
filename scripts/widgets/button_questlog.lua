local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

--Draggable code is shamelessly stolen from Insight ;)

local Button_QuestLog = Class(ImageButton, function(self, owner,background)
	--ImageButton._ctor(self,"Button_QuestLog")

	if background then
		ImageButton._ctor(self, "images/global_redux.xml", "button_carny_square_normal.tex", "button_carny_square_hover.tex", "button_carny_square_disabled.tex", "button_carny_square_down.tex")
		self.button_img = self:AddChild(Image("images/images_quest_system.xml","quest_log.tex"))
		self:SetScale(1)
		self:SetDraggable(false)
		self:SetOnDragFinish(nil)
	else
		ImageButton._ctor(self, "images/images_quest_system.xml", "quest_log.tex", nil, "quest_log.tex", nil, nil, {1,1}, {0,0})
		self:SetImageNormalColour(1, 1, 1, 1)
		self.move_on_click = false
		self.drag_tolerance = 4
		self:SetDraggable(true)
		--self:SetOnDragFinish(nil)
	end

	self.owner = owner

	self.onclick2 = function()
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
	end
	self:SetTooltip(STRINGS.QUEST_COMPONENT.QUEST_LOG.BUTTON)
	local scale = 64 / math.max(self:GetSize())
	self:SetScale(scale, scale, scale)
	local w, h = self:GetSize()
	self.width = w * scale
	self.height = h * scale



end)

function Button_QuestLog:SetDraggable(bool)
	self.draggable = bool
	if self.draggable then
		self:SetOnDown(function()
			self:BeginDrag()
		end)
		self:SetWhileDown(function()
			self:DoDrag()
		end)
		self.onclick = function(...)
			self:EndDrag()
			if self.onclick2 then
				return self.onclick2(...)
			end
		end
	else
		self:SetOnDown(nil)
		self:SetWhileDown(nil)
		self.onclick = function(...)
			if self.onclick2 then
				return self.onclick2(...)
			end
		end
	end
end

function Button_QuestLog:SetOnDragFinish(fn)
	self.ondragfinish = fn
end

function Button_QuestLog:SetOnClick(fn)
	self.onclick2 = fn
end

function Button_QuestLog:OnGainFocus()
	--devprint("gained focus")
	return ImageButton.OnGainFocus(self)
end

function Button_QuestLog:OnLoseFocus()
	--devprint("lost focus")
	if self:IsDragging() then
		--self:EndDrag()

	end

	return ImageButton.OnLoseFocus(self)
end

function Button_QuestLog:HasMoved()
	if self.drag_state == nil then
		return false
	end

	local bx, by, bz = self.drag_state.origin:Get()
	local x, y, z = self:GetPosition():Get()

	if math.abs(x - bx) + math.abs(y - by) >= self.drag_tolerance then
		return true
	end

	return false
end

function Button_QuestLog:IsDragging()
	return self.drag_state ~= nil
end

function Button_QuestLog:BeginDrag()
	if self:IsDragging() then
		devprint("ALREADY DRAGGING")
		return
	end

	if not TheFrontEnd.lastx or not TheFrontEnd.lasty then
		return
	end

	TheFrontEnd:LockFocus(true)

	self.o_pos = nil

	self.drag_state = {
		origin = self:GetPosition(),
		pos = self:GetPosition(),
		lastx = TheFrontEnd.lastx,
		lasty = TheFrontEnd.lasty
	}

	self.image:SetScale(self.normal_scale[1], self.normal_scale[2], self.normal_scale[3])
	--devprint("Button_QuestLog:BeginDrag", self.image, self.image.shown)
	--devdumptable(self.drag_state)
end

function Button_QuestLog:DoDrag()
	if not self.drag_state then
		-- Happened once
		return
	end
	local pos = self.drag_state.pos

	-- lastx was nil? Which one? Frontend?
	if not TheFrontEnd.lastx or not TheFrontEnd.lasty then
		devprint("FRONTEND MISSING LASTS")
		devprint(TheFrontEnd.lastx, TheFrontEnd.lasty)
	end

	if not self.drag_state.lastx or not self.drag_state.lasty then
		devprint("STATE MISSING LASTS")
		devprint(self.drag_state.lastx, self.drag_state.lasty)
	end

	local deltax = TheFrontEnd.lastx - self.drag_state.lastx
	local deltay = TheFrontEnd.lasty - self.drag_state.lasty

	local scale = self:GetScale()
	local screen_width, screen_height = TheSim:GetScreenSize()
	screen_width = screen_width / scale.x
	screen_height = screen_height / scale.y

	deltax = deltax / scale.x
	deltay = deltay / scale.y

	local nx = pos.x + deltax
	local ny = pos.y + deltay

	local a, b = self:GetSize()

	nx = math.clamp(nx, -screen_width + a/2, -a/2) -- 0,0 is bottom right of screen
	ny = math.clamp(ny, b/2, screen_height - b/2)

	self.drag_state.pos = Vector3(nx, ny, pos.z)
	self:SetPosition(self.drag_state.pos)

	self.drag_state.lastx = TheFrontEnd.lastx
	self.drag_state.lasty = TheFrontEnd.lasty
	--devprint("Button_QuestLog:DoDrag", self.image, self.image.shown)
	--devdumptable(self.drag_state)
end

function Button_QuestLog:EndDrag()
	--devprint("Button_QuestLog:EndDrag", self.image, self.image.atlas,self.image.texture, self.image.shown)
	if not self:IsDragging() then
		devprint('\tnot dragging?')
		return
	end

	TheFrontEnd:LockFocus(false)

	if self.ondragfinish and self:HasMoved() then
		self.ondragfinish(self.drag_state.origin, self:GetPosition())
	end

	self.drag_state = nil

	if self.focus then
		self.image:SetScale(self.focus_scale[1], self.focus_scale[2], self.focus_scale[3])
	end
end

return Button_QuestLog