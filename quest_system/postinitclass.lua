-------------------------------------------------Class Post Constructs-----------------------------------------------
local TheInput = GLOBAL.TheInput
local unpack = GLOBAL.unpack
local QUEST_COMPONENT = GLOBAL.TUNING.QUEST_COMPONENT
local STR_QUEST_COMPONENT = GLOBAL.STRINGS.QUEST_COMPONENT
local TheSim = GLOBAL.TheSim
local TheNet = GLOBAL.TheNet


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
		local colour = { colour1, colour2, colour3, colour4 }
		local target = TheInput:GetWorldEntityUnderMouse()
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
if QUEST_COMPONENT.BUTTON == 1 or QUEST_COMPONENT.BUTTON == 2 then
	local function adjustButtons(self)
		local x, y
		local width, height = TheSim:GetScreenSize()
		local scale = self.top_root:GetScale()
		width  = width  / scale.x / 2
		height = height / scale.y / 2
		local allign = {}
		local sized = 10 
		if QUEST_COMPONENT.BUTTON == 1 then
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
		self.owner.HUD.inst:ListenForEvent("refreshhudsize", function() adjustButtons(self) end)
	end

	AddClassPostConstruct("widgets/controls", AddButtonQuestLog)
end

if QUEST_COMPONENT.BUTTON == 3 then
	local Button_QuestLog = require "widgets/button_questlog"
	AddClassPostConstruct("screens/redux/pausescreen",function(self)
		self.Button_QuestLog = self.proot:AddChild(Button_QuestLog(self.owner,true))
		local items = self.menu and self.menu:GetNumberOfItems() or 7
		local y = items == 6 and 180 or 210
		self.Button_QuestLog:SetPosition(100,y)
		self.Button_QuestLog:SetHoverText(STR_QUEST_COMPONENT.QUEST_LOG.BUTTON)
	end)
end

--Add indicators of which bonis are active at the moment
local function adjustButtons2(self)
	local x0,y0,x1,y1,x2,y2,x3,y3,x4,y4
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
	local screensize = {TheSim:GetScreenSize()}
	self.owner.HUD.inst:ListenForEvent("refreshhudsize", function() adjustButtons2(self) end)
end

AddClassPostConstruct("widgets/controls", AddButtonTempBoni)


--Adding checkboxes to playerstatusscreen to decide who can make quests
if QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
	local function IsEnabled(userid)
		if userid then
			if QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[userid] == true then
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
				local clients = TheNet:GetClientTable() or {}
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
			    	return unpack(ret2)
				end
			end
			return unpack(ret)
		end
	end

	AddClassPostConstruct("screens/playerstatusscreen", AddCheckBox)
end

--AddClassPostConstruct to change the way the camera is pointing
AddClassPostConstruct("cameras/followcamera",function(self)
	self.turned = false
	local old_Apply = self.Apply
	self.Apply = function(_self,...)
		local ret = old_Apply(_self,...)
		if _self.turned then
			local pitch = _self.pitch * DEGREES
		    local heading = _self.heading * DEGREES
		    local cos_pitch = math.cos(pitch)
		    local cos_heading = math.cos(heading)
		    local sin_heading = math.sin(heading)
		    local dx = -cos_pitch * cos_heading
		    local dy = -math.sin(pitch)
		    local dz = -cos_pitch * sin_heading
			--right
		    local right = (_self.heading - 90) * DEGREES --right is changed to make the camera change perspective
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
	self.OnUpdate = function(_self,dt,...)
		local ret = old_OnUpdate(_self,dt,...)
		local animstate = _self.anim:GetAnimState()
		if _self.owner:HasTag("green_flames") then
			if TheNet:IsServerPaused() then return end
			animstate:SetAddColour(0, 0.8, 0, _self.alpha * _self.alphamult)
		else
			animstate:SetAddColour(0, 0, 0, 0)
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

--Don't drop items if in a boss fight
local function DropNothing(self)
	local old_DropEverything = self.DropEverything
	function self:DropEverything(...)
		if self.inst:HasTag("currently_in_bossfight") then
			return
		end
		return old_DropEverything(self,...)
	end
end

AddComponentPostInit("inventory", DropNothing)

--Push an event to the leader if a follower is added
local function LeaderEvent(self)
	local old_AddFollower = self.AddFollower
	self.AddFollower = function(_self,follower,...)
		if _self.inst then
			_self.inst:PushEvent("added_follower",{follower = follower})
		end
		return old_AddFollower(_self,follower,...)
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

local function OnCatchFish(self)
	local old__LaunchFishProjectile = self._LaunchFishProjectile
	function self:_LaunchFishProjectile(fish, ...)
		local ret = old__LaunchFishProjectile(self,fish, ...)
		if self.fisher then
			self.fisher:PushEvent("caught_fish",fish)
		end
		return ret
	end
end

AddComponentPostInit("oceanfishingrod", OnCatchFish)

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


----------------------------------------Brain Post Inits----------------------------------------

local PICKUP_DISTANCE = 7

local pickup_levels = {
	[1] = 0,
	[2] = 50,
	[3] = 200,
	[4] = 500,
	[5] = 1000,
}

local function getPickupLevel(inst)
	if inst.picked_up_items then
		for lvl, val in ipairs(pickup_levels) do
			if inst.picked_up_items < val then
				return lvl - 1
			end
		end
		return 5
	else
		return 0
	end
end

local function getPickupDistance(inst)
	return PICKUP_DISTANCE + getPickupLevel(inst)
end
local NO_PICKUP_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider", "_container" }

-- Checks if a specific item is able to be chomped
local function IsCorrectItem(inst, v)
	local proxy = inst.components.container_proxy
	local container = proxy
			and proxy:GetMaster()
			and proxy:GetMaster().components.container
			or inst.components.container or nil
	if v.components.inventoryitem ~= nil and
			v.components.inventoryitem.canbepickedup and
			v.components.stackable ~= nil and
			container and container:Has(v.prefab, 1) then
		return true
	end
	return false
end

local function CheckIfItemsPickupable(inst)
	if not inst:HasTag("can_do_pickup_nightmarechester") then
		return false
	end
	local mx, _, mz = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(mx, 0, mz, getPickupDistance(inst), {"_inventoryitem"}, NO_PICKUP_TAGS)
	for i, v in ipairs(ents) do
		if IsCorrectItem(inst, v) then
			return true
		end
	end
	return false
end

local function EatItems(inst)
	if inst.sg:HasStateTag("busy") then
		return
	end
	local mx, _, mz = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(mx, 0, mz, getPickupDistance(inst), {"_inventoryitem"}, NO_PICKUP_TAGS)
	for i, v in ipairs(ents) do
		if IsCorrectItem(inst, v) and v.components.stackable ~= nil then
			return GLOBAL.BufferedAction(inst, v, GLOBAL.ACTIONS.CHESTER_PICKUP)
		end
	end
end

require "behaviours/doaction"

AddBrainPostInit("chesterbrain",function(self)
	local pickup = GLOBAL.WhileNode(function() return CheckIfItemsPickupable(self.inst) end, "Pickup Items",
			DoAction(self.inst, EatItems))
	local pos = 0
	for i,node in ipairs(self.bt.root.children) do
		if node.name == "Follow" then
			pos = i + 1
			break
		end
	end
	table.insert(self.bt.root.children, pos, pickup)
end)

------------------------------------Stategraph Post Inits-----------------------------------------

AddStategraphState("chester",
	GLOBAL.State {

		name = "chomp_item",
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("chomp", true)
		end,

		timeline = {
			GLOBAL.TimeEvent(10 * GLOBAL.FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),
		},

		events = {
			GLOBAL.EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		}

	}
)


