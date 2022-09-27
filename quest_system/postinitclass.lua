-------------------------------------------------Class Post Constructs-----------------------------------------------

local color_table 
if TUNING.QUEST_COMPONENT.COLORBLINDNESS == 1 then
    color_table = {
        {120/255,94/255,240/255,1}, 
        {100/255,143/255,255/255,1}, 
        {255/255,176/255,0/255,1},
        {254/255,97/255,0/255,1},
        {220/255,38/255,127/255,1},
    }
else
    color_table = {
        {23/255,255/255,0/255,1}, --WEBCOLOURS.GREEN,
        {68/255,88/255,255/255,1}, --WEBCOLOURS.BLUE,
        WEBCOLOURS.YELLOW,
        WEBCOLOURS.ORANGE,
        WEBCOLOURS.RED,
    }
end

--Add colour to the names of the bosses if moused over
AddClassPostConstruct("widgets/hoverer",function(hoverer)
	local old_SetColour = hoverer.text.SetColour
	hoverer.text.SetColour = function(self, colour1, colour2, colour3, colour4)
		colour = { colour1, colour2, colour3, colour4 }
		local target = GLOBAL.TheInput:GetWorldEntityUnderMouse()		
		if target ~= nil then 
			if target:HasTag("Quest_Boss_easy") then
				colour = color_table[1] --{ 0 / 255, 100 / 255, 0 / 255, 1 }		--green
			elseif target:HasTag("Quest_Boss_normal") then
				colour = color_table[3] --{ 255 / 255, 215 / 255, 0 / 255, 1 }		--yellow
			elseif target:HasTag("Quest_Boss_difficult") then
				colour = color_table[5] --{ 255 / 255, 0 / 255, 0 / 255, 1 } 		--red
			end
		end
		return old_SetColour(self, unpack(colour))
	end
end)


--Add button to open quest log
if GLOBAL.TUNING.QUEST_COMPONENT.BUTTON == 1 or GLOBAL.TUNING.QUEST_COMPONENT.BUTTON == 2 then
	local function adjustButtons(self)
		local x, y
		local width, height = TheSim:GetScreenSize()
		local scale = self.top_root:GetScale()
		width  = width  / scale.x / 2
		height = height / scale.y / 2
		local allign = {}
		local sizeb = 64 
		local sized = 10 
		if GLOBAL.TUNING.QUEST_COMPONENT.BUTTON == 1 then
			x = width - 29
			y = -2*height + 102 + sized
			allign = {-1,1}
		else
			x = width - 123 - sized
			y = -2*height + sized
			allign = {-1,1}
		end
		local buttonOne = self.Button_QuestLog
		if buttonOne then
			buttonOne:SetPosition(x + buttonOne.width*allign[1]/2, y + buttonOne.height*allign[2]/2, 0)
		end
	end

	local Button_QuestLog = require "widgets/button_questlog"

	local function AddButtonQuestLog(self)
		self.Button_QuestLog = self.top_root:AddChild(Button_QuestLog(self.owner))
		adjustButtons(self)
		self.owner.HUD.inst:ListenForEvent("refreshhudsize", function(_self, scale) adjustButtons(self) end)
	end

	AddClassPostConstruct("widgets/controls", AddButtonQuestLog)
end

if GLOBAL.TUNING.QUEST_COMPONENT.BUTTON == 3 then
	local Button_QuestLog = require "widgets/button_questlog"
	AddClassPostConstruct("screens/redux/pausescreen",function(self)
		self.Button_QuestLog = self.proot:AddChild(Button_QuestLog(self.owner,true))
		local items = self.menu and self.menu:GetNumberOfItems() or 7
		local y = items == 6 and 180 or 210
		self.Button_QuestLog:SetPosition(100,y)
		self.Button_QuestLog:SetHoverText(GLOBAL.STRINGS.QUEST_COMPONENT.QUEST_LOG.BUTTON)
	end)
end

--Add indicators of which bonis are active at the moment
local function adjustButtons2(self)
	local x,y,x1,y1,x2,y2,x3,y3,x4,y4
	local width, height = TheSim:GetScreenSize()
	local scale = self.top_root:GetScale()
	width  = width  / scale.x / 2
	height = height / scale.y / 2
	local allign = {-1,1}
	local sizeb = 48 
	local sized = 3
	x0 = 0 + 2.5*(sizeb+sized)
	y0 = -0.13*height/scale.y + sized
	x1 = x0 - sizeb - sized
	x2 = x1 - sizeb - sized
	x3 = x2 - sizeb - sized
	x4 = x3 - sizeb - sized
	local x = {x0,x1,x2,x3,x4}
	y1=y0
	y2=y0
	y3=y0
	y4=y0
	local y = {y0,y1,y2,y3,y4}
	for count = 1,5 do
		local button = self["tempboni"..count]
		if button then
			button:SetPosition(x[count] + button.width*allign[1]/2, y[count] + button.height*allign[2]/2, 0)
		end
	end
end

local TempBoni = require "widgets/temp_boni"

local function AddButtonTempBoni(self)
	for count = 1,5 do
		self["tempboni"..count] = self.top_root:AddChild(TempBoni(self.owner))
		self["tempboni"..count]:Hide()
	end
	adjustButtons2(self)
	local screensize = {GLOBAL.TheSim:GetScreenSize()}
	self.owner.HUD.inst:ListenForEvent("refreshhudsize", function(_self, scale) adjustButtons2(self) end)
end

AddClassPostConstruct("widgets/controls", AddButtonTempBoni)


--Adding checkboxes to playerstatusscreen to decide who can make quests
if GLOBAL.TUNING.QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
	local function IsEnabled(userid)
		if userid then
			if GLOBAL.TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] == true then
				return true
			end
		end
	end
	local function SetTexture(widget,checked)
		if checked == true then
			widget:SetTextures("images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_normal_check.tex", nil, nil, {1,1}, {0,0})
		else
			widget:SetTextures("images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_normal.tex", nil, nil, {1,1}, {0,0})
		end
	end
	local function ChangePlayer(userid,bool)
		if userid then
			SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["AddCustomQuestMakerToServer"],userid,bool)
		end
	end

	local ImageButton = require "widgets/imagebutton"
	local function AddCheckBox(self)
		local old_DoInit = self.DoInit
		self.DoInit = function(self,ClientObjs,...)
			local ret = {old_DoInit(self,ClientObjs,...)}
			if self.scroll_list ~= nil then
				local clients = GLOBAL.TheNet:GetClientTable() or {}
				for _,playerListing in ipairs(self.player_widgets) do
					local enabled = IsEnabled(playerListing.userid)
					playerListing.checkbox = playerListing:AddChild(ImageButton("images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_normal.tex", nil, nil, {1,1}, {0,0}))
			        playerListing.checkbox:SetPosition(230,3,0)
			        playerListing.checkbox:SetFocusSound("dontstarve/HUD/click_mouseover")
			        playerListing.checkbox:SetHoverText("Choose if the player can create custom quests", { font = NEWFONT_OUTLINE, offset_x = 0, offset_y = 30, colour = {1,1,1,1}})
			        SetTexture(playerListing.checkbox,enabled)
			        playerListing.checkbox:SetOnClick( function()
			        	if enabled == true then
			    			ChangePlayer(playerListing.userid)
			    			enabled = false
			    			SetTexture(playerListing.checkbox,enabled)
			    		else
			    			ChangePlayer(playerListing.userid,1)
			    			enabled = true
			    			SetTexture(playerListing.checkbox,enabled)
			    		end
			        end)
			        playerListing.checkbox:Hide()

			        if TheNet:GetIsServerAdmin() == true then
			        	for _,player in ipairs(clients) do
							if player.userid == playerListing.userid then
								if player.admin == true then
									--nothing
								else
			        				playerListing.checkbox:Show()
			        			end
			        		end
			        	end
			        end
			    end

			    local old_updatefn = self.scroll_list.updatefn or function() end
			    self.scroll_list.updatefn = function(playerListing, client, i,...)
			    	local ret2 =  {old_updatefn(playerListing, client, i,...)}
			    	if playerListing.checkbox ~= nil and TheNet:GetIsServerAdmin() == true then
			    		if client.admin == false then
			    			playerListing.checkbox:Show()
			    		else
			    			playerListing.checkbox:Hide()
			    		end
			    		local enabled = IsEnabled(client.userid)
			    		SetTexture(playerListing.checkbox,enabled)
			    		playerListing.checkbox:SetOnClick(function()
			    			if enabled == true then
			    				ChangePlayer(client.userid)
			    				enabled = false
			    				SetTexture(playerListing.checkbox,enabled)
			    			else
			    				ChangePlayer(client.userid,1)
			    				enabled = true
			    				SetTexture(playerListing.checkbox,enabled)
			    			end
			    		end)
			    	end
			    	return GLOBAL.unpack(ret2)
				end
			end
			return GLOBAL.unpack(ret)
		end
	end

	AddClassPostConstruct("screens/playerstatusscreen", AddCheckBox)
end

--AddClassPostConstruct to change the way the camera is pointing
AddClassPostConstruct("cameras/followcamera",function(self)
	self.turned = false
	local old_Apply = self.Apply
	self.Apply = function(self,...)
		local ret = old_Apply(self,...)
		if self.turned then
			local pitch = self.pitch * DEGREES
		    local heading = self.heading * DEGREES
		    local cos_pitch = math.cos(pitch)
		    local cos_heading = math.cos(heading)
		    local sin_heading = math.sin(heading)
		    local dx = -cos_pitch * cos_heading
		    local dy = -math.sin(pitch)
		    local dz = -cos_pitch * sin_heading
			--right
		    local right = (self.heading - 90) * DEGREES --right is changed to make the camera change perspective
		    local rx = math.cos(right)
		    local ry = 0
		    local rz = math.sin(right)
		    --up
		    local ux = dy * rz - dz * ry
		    local uy = dz * rx - dx * rz
		    local uz = dx * ry - dy * rx
		    TheSim:SetCameraUp(ux, uy, uz)
		end
		return ret
	end
end)
--TheCamera.turned = true

--Add colour change to flames that are shown if burning to match the colour of chester_boss
AddClassPostConstruct("widgets/fireover",function(self)
	local old_OnUpdate = self.OnUpdate
	self.OnUpdate = function(self,dt,...)
		local ret = old_OnUpdate(self,dt,...)
		if self.owner:HasTag("green_flames") then
			if TheNet:IsServerPaused() then return end
		    self.anim:GetAnimState():SetAddColour(0, 0.8, 0, self.alpha * self.alphamult)
		else
			self.anim:GetAnimState():SetAddColour(0, 0, 0, 0)
		end
		return ret
	end
end)

if GLOBAL.KnownModIndex:IsModEnabledAny("workshop-376333686") then
	AddClassPostConstruct("widgets/wandaagebadge",function(self)
		local OldSetPercent = self.SetPercent
		if OldSetPercent then
			function self:SetPercent(val, max, ...)
				OldSetPercent(self, val, max, ...)
				if not self.active then return end
				local wanda_max = self.owner.replica.health:Max() + TUNING.WANDA_MIN_YEARS_OLD
				local maxnum_str = tostring(math.ceil(wanda_max))
				self.maxnum:SetString("Max:\n"..maxnum_str)
			end
		end
	end)
end



	--------------------------------------------Component Post Inits-------------------------------------------------

--Stop player from dropping inventory when dying in a boss fight
local function inventorypostinit(Inventory,inst)
  local OriginalDropEverything = Inventory.DropEverything
  
  	function Inventory:DropEverything(ondeath,keepequip,...)
    	if inst:HasTag("currently_in_bossfight") then
    		--print(string.format("[Quest System] %s died in the boss fight but didn't lose his items!"),inst.name)
    	else
      		return OriginalDropEverything(self,ondeath,keepequip,...)
    	end
  	end
end

AddComponentPostInit("inventory", inventorypostinit)

--Push an event to the leader if a follower is added
local function LeaderEvent(self)
	local old_AddFollower = self.AddFollower
	self.AddFollower = function(self,follower,...)		
		if self.inst then
			self.inst:PushEvent("added_follower",{follower = follower})
		end
		return old_AddFollower(self,follower,...)
	end
end

AddComponentPostInit("leader", LeaderEvent)

--Push Event when completing a friend task
local function CompleteTask(self)
	local old_CompleteTask = self.CompleteTask
	function self:CompleteTask(task,doer,...)
		if doer then
			doer:PushEvent("completed_friendlvl_task",task)
		end
		return old_CompleteTask(self,task,doer,...)
	end
end

AddComponentPostInit("friendlevels", CompleteTask)

local function OnSleep(self)
	local old_DoSleep = self.DoSleep
	function self:DoSleep(bed,...)
		local ret = old_DoSleep(self,bed,...)
		if self.inst then
			self.inst:PushEvent("startsleeping",bed)
		end
		return ret
	end
end

AddComponentPostInit("sleepingbaguser", OnSleep)

--Stop players from attacking the victims in attackwaves
local function CanBeAttacked(self)
	local old_CanBeAttacked = self.CanBeAttacked
	function self:CanBeAttacked(attacker,...)
		if self.inst and self.inst:HasTag("is_attackwave_victim") then
			if attacker and attacker:HasTag("player") then
				return false
			end
		end
		return old_CanBeAttacked(self,attacker,...)
	end
end

AddClassPostConstruct("components/combat_replica", CanBeAttacked)


