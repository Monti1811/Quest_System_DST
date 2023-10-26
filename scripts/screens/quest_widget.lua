local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Templates = require "widgets/templates"
local Templates_R = require "widgets/redux/templates"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local ScrollableList = require "widgets/scrollablelist"
local PlayerBadge = require "widgets/playerbadge"
local TextButton = require "widgets/textbutton"
local STRINGS_QL = STRINGS.QUEST_COMPONENT.QUEST_LOG
local profile_flairs = require "profile_flairs"
local scrapbookdata = require("screens/redux/scrapbookdata")


local colour_difficulty 
if TUNING.QUEST_COMPONENT.COLORBLINDNESS == 1 then
    colour_difficulty = {
      {120/255,94/255,240/255,1}, 
      {100/255,143/255,255/255,1}, 
      {255/255,176/255,0/255,1},
      {254/255,97/255,0/255,1},
      {220/255,38/255,127/255,1},
    }
else
    colour_difficulty = {
      {23/255,255/255,0/255,1}, --WEBCOLOURS.GREEN,
      {68/255,88/255,255/255,1}, --WEBCOLOURS.BLUE,
      WEBCOLOURS.YELLOW,
      WEBCOLOURS.ORANGE,
      WEBCOLOURS.RED,
    }
end

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function GetPlayerTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs == nil then
        return {}
    elseif TheNet:GetServerIsClientHosted() then
        return ClientObjs
    end

    --remove dedicate host from player list
    for i, v in ipairs(ClientObjs) do
        if v.performance ~= nil then
            table.remove(ClientObjs, i)
            break
        end
    end
    return ClientObjs
end

local function SetFirstQuestAsFocus(self)
    for num = 1, self.max_amount_of_quests do
        if self["quest_"..num] and self["quest_"..num].description then
            self["quest_"..num].description:SetFocus()
            return
        end
    end
end

local function FindNextExistingQuest(self, num, step)
    while (self["quest_"..num] == nil or self["quest_"..num].name == nil) and num < self.max_amount_of_quests and num > 1 do
        num = num + step
    end
    return self["quest_"..num] and self["quest_"..num].name and num or nil
end

local function createEmptyQuestCard(self,_--[[tab]], x, y, scale, num)

    self["quest_"..num] = self["quest__"..num]:AddChild(Widget("quest_"..num))
    self["quest_"..num].fill = self["quest__"..num]:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    self["quest_"..num].fill:SetPosition(x, y + 40)
    self["quest_"..num].fill:SetScale(.23 * scale, .4 * scale)
    self["quest_"..num].fill:SetTint(1,1,1,0.5)

    self["quest_"..num].title = self["quest__"..num]:AddChild(Text(NEWFONT_OUTLINE, 50, STRINGS_QL.EMPTY_SLOT,{unpack(GOLD)}))
    self["quest_"..num].title:SetPosition(x, y + 60)
    self["quest_"..num].title:SetScale(scale)

end

local function createQuestCard(self,quest, x, y, scale, num)

    devprint("createQuestCard",quest,quest.name,quest.variable_fn,self.ownerofscreen.replica.quest_component.quest_data[quest.name])
    quest.scale = quest.scale or {}

    self["quest_"..num] = self["quest__"..num]:AddChild(Widget("quest_"..num))
    self["quest_"..num].name = quest.name
    self["quest_"..num].fill = self["quest__"..num]:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    self["quest_"..num].fill:SetPosition(x, y + 40)
    self["quest_"..num].fill:SetScale(.23 * scale, .4 * scale)
    self["quest_"..num].fill:SetTint(1,1,1,0.8)

    self["quest_"..num].title = self["quest__"..num]:AddChild(Text(BUTTONFONT, 30, "",{unpack(BLACK)}))
    self["quest_"..num].title:SetPosition(x, y + 162)
    self["quest_"..num].title:SetScale(scale)
    --self["quest_"..num].title:SetRegionSize(150, 50)
    --print("create questcard",quest.overridename,quest.name,quest.scale,GetQuestString(quest.overridename or quest.name,"NAME",unpack{quest.scale}))
    local title =  GetQuestString(quest.overridename or quest.name,"NAME",quest.scale and unpack(quest.scale) or nil)
    self["quest_"..num].title:SetAutoSizingString(title ~= "" and title or quest.name or STRINGS_QL.NO_NAME,150)

    if quest.quest_line then
        self["quest_"..num].quest_line = self["quest__"..num]:AddChild(Image("images/hud.xml","tab_researchable_off.tex"))
        self["quest_"..num].quest_line:SetPosition(x-75, y + 85)
        --self["quest_"..num].quest_line:SetTint(1,0,0,1)
        self["quest_"..num].quest_line:SetScale(0.4,0.4)
        self["quest_"..num].quest_line:SetHoverText(STRINGS_QL.QUEST_LINE)

        self["quest_"..num].quest_line2 = self["quest__"..num]:AddChild(Image("images/hud.xml","tab_researchable_off.tex"))
        self["quest_"..num].quest_line2:SetPosition(x+50, y + 85)
        --self["quest_"..num].quest_line2:SetTint(1,0,0,1)
        self["quest_"..num].quest_line2:SetScale(0.4,0.4)
        self["quest_"..num].quest_line2:SetHoverText(STRINGS_QL.QUEST_LINE)
    end

    local positions = {
        {x-75, y + 185},
        {x-55, y + 185},
    }

    if quest.modname then
        local mod_picture = TUNING.QUEST_COMPONENT.MOD_ICONS[quest.modname]
        if mod_picture then

            self["quest_"..num].quest_mod_picture = self["quest__"..num]:AddChild(Image(mod_picture.atlas, mod_picture.tex))
            self["quest_"..num].quest_mod_picture:SetPosition(positions[1][1], positions[1][2])
            --self["quest_"..num].quest_mod_picture:SetTint(1,1,1,0.3)
            self["quest_"..num].quest_mod_picture:ScaleToSize(20, 20)
            self["quest_"..num].quest_mod_picture:SetHoverText(quest.modname)

            table.remove(positions,1)

            --For entire background
            --[[self["quest_"..num].quest_mod_picture = self["quest__"..num]:AddChild(Image(mod_picture.atlas, mod_picture.tex))
            self["quest_"..num].quest_mod_picture:SetPosition(x+0.5, y+125)
            self["quest_"..num].quest_mod_picture:SetTint(1,1,1,0.3)
            self["quest_"..num].quest_mod_picture:ScaleToSize(173, 147)
            self["quest_"..num].quest_mod_picture:SetHoverText(quest.modname)]]

        end
    end

    if quest.variable_fn then
        self["quest_"..num].quest_scalable_picture = self["quest__"..num]:AddChild(Image("images/victims.xml", "scaling.tex"))
        self["quest_"..num].quest_scalable_picture:SetPosition(positions[1][1], positions[1][2])
        --self["quest_"..num].quest_scalable_picture:SetTint(1,1,1,0.3)
        self["quest_"..num].quest_scalable_picture:ScaleToSize(20, 20)
        self["quest_"..num].quest_scalable_picture:SetHoverText(STRINGS_QL.SCALING)
    end

    self["quest_"..num].difficulty = {}
    local difficulty = quest.difficulty and quest.difficulty < 6 and quest.difficulty > 0 and quest.difficulty or 1
    for count = 1,difficulty do
        self["quest_"..num].difficulty["star"..tostring(count)] = self["quest__"..num]:AddChild(Image("images/global_redux.xml","star_checked.tex"))
        self["quest_"..num].difficulty["star"..tostring(count)]:SetPosition(x - 75 + count * 25, y + 137)
        self["quest_"..num].difficulty["star"..tostring(count)]:SetScale(scale * 0.5)
        self["quest_"..num].difficulty["star"..tostring(count)]:SetTint(unpack(colour_difficulty[difficulty] or {1,1,1,1}))
    end
    for count = difficulty + 1,5 do
        self["quest_"..num].difficulty["star"..tostring(count)] = self["quest__"..num]:AddChild(Image("images/global_redux.xml","star_uncheck.tex"))
        self["quest_"..num].difficulty["star"..tostring(count)]:SetPosition(x - 75 + count * 25, y + 137)
        self["quest_"..num].difficulty["star"..tostring(count)]:SetScale(scale * 0.5)
        self["quest_"..num].difficulty["star"..tostring(count)]:SetTint(unpack(colour_difficulty[difficulty] or {1,1,1,1}))
    end

    self["quest_"..num].description = self["quest__"..num]:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self["quest_"..num].description.image:SetScale(.3)
    self["quest_"..num].description:SetPosition(x, y + 110)
    self["quest_"..num].description:SetFont(CHATFONT)
    self["quest_"..num].description:SetText(STRINGS_QL.DESCRIPTION)
    self["quest_"..num].description:SetTextSize(20)
    self["quest_"..num].description:SetOnClick(function()
        if self.show_rewards and self.show_rewards.shown == true then
            self.show_rewards:Kill()
        end
        self.last_selected = self["quest_"..num].description
        self:ShowDescription(quest,num)
    end)
    self["quest_"..num].description.text:SetAutoSizingString(STRINGS_QL.DESCRIPTION,80)

    self["quest_"..num].rewards = self["quest__"..num]:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self["quest_"..num].rewards.image:SetScale(.3)
    self["quest_"..num].rewards:SetPosition(x, y + 75)
    self["quest_"..num].rewards:SetFont(CHATFONT)
    self["quest_"..num].rewards:SetText(STRINGS_QL.REWARDS)
    self["quest_"..num].rewards:SetTextSize(20)
    self["quest_"..num].rewards:SetOnClick(function()
        self.last_selected = self["quest_"..num].rewards
        if self.show_rewards and self.show_rewards.shown == true then
            self.show_rewards:Kill()
        end
        self:ShowRewards(quest,num)
    end)
    self["quest_"..num].rewards.text:SetAutoSizingString(STRINGS_QL.REWARDS,80)

    self["quest_"..num].progress_title_bg = self["quest__"..num]:AddChild(Image("images/ui.xml","in-window_button_tile_hl_noshadow.tex"))
    self["quest_"..num].progress_title_bg:SetPosition(x+2, y-35)
    self["quest_"..num].progress_title_bg:SetScale(0.78,0.8)
    self["quest_"..num].progress_title_bg:SetTint(1,1,1,0.4)

    self["quest_"..num].progress_title = self["quest__"..num]:AddChild(Text(NEWFONT_OUTLINE, 25))
    self["quest_"..num].progress_title:SetPosition(x, y+35 )
    self["quest_"..num].progress_title:SetString(STRINGS_QL.PROGRESS)
    self["quest_"..num].progress_title:SetScale(scale)
    self["quest_"..num].progress_title:SetRegionSize(175, 350)
    self["quest_"..num].progress_title:EnableWordWrap(true)
    self["quest_"..num].progress_title:EnableWhitespaceWrap(true)

    self["quest_"..num].progress_title_divider = self["quest__"..num]:AddChild(Image("images/quagmire_recipebook.xml","quagmire_recipe_line_veryshort.tex"))
    self["quest_"..num].progress_title_divider:SetPosition(x, y+21)
    self["quest_"..num].progress_title_divider:SetScale(0.6,0.7)


    self["quest_"..num].progress = self["quest__"..num]:AddChild(Text(NEWFONT_OUTLINE, 25))
    self["quest_"..num].progress:SetPosition(x, y )
    self["quest_"..num].progress:SetString(tostring(math.floor(quest.current_amount)).."/"..tostring(math.floor(quest.amount)))
    self["quest_"..num].progress:SetScale(scale)
    self["quest_"..num].progress:SetRegionSize(175, 350)
    self["quest_"..num].progress:EnableWordWrap(true)
    self["quest_"..num].progress:EnableWhitespaceWrap(true)

    self["quest_"..num].victim = self["quest__"..num]:AddChild(Text(NEWFONT_OUTLINE, 25))
    self["quest_"..num].victim:SetPosition(x, y - 30)
    self["quest_"..num].victim:SetAutoSizingString(quest.victim and STRINGS.NAMES[string.upper(quest.victim)] or quest.counter_name or STRINGS_QL.NOT_DEFINED,160)
    self["quest_"..num].victim:SetScale(scale)
    --self["quest_"..num].victim:SetRegionSize(175, 350)
    self["quest_"..num].victim:EnableWordWrap(true)
    self["quest_"..num].victim:EnableWhitespaceWrap(true)

    local target_atlas
    local target_tex
    local data_victim = quest.victim ~= "" and quest.victim or quest.anim_prefab
    local data = data_victim and scrapbookdata[data_victim]
    if TUNING.QUEST_COMPONENT.QL_ANIM ~= 0 and data and data.anim then
        --primeRand(hash((data and data.name or "")..ThePlayer.userid))
        self["quest_"..num].image = self["quest__"..num]:AddChild(UIAnim())
        local creature = self["quest_"..num].image
        creature:GetAnimState():SetBank(data.bank)
        creature:GetAnimState():SetBuild(data.build)
        if data.scrapbook_setanim then
            creature:GetAnimState():SetPercent(data.anim,data.scrapbook_setanim)
        else
            creature:GetAnimState():SetPercent(data.anim,rand())
        end
        if data.scrapbook_overridebuild then
            creature:GetAnimState():AddOverrideBuild(data.scrapbook_overridebuild)
        end
        creature:GetAnimState():Hide("snow")
        if data.scrapbook_hide then
            for _,hide in ipairs(data.scrapbook_hide) do
                creature:GetAnimState():Hide(hide)
            end
        end

        local ACTUAL_X = 120
        local ACTUAL_Y = 75
        local ax,ay = creature:GetBoundingBoxSize()
        devprint("BoundingBoxSize", ax,ay)

        local SCALE = ACTUAL_X/ax
        local has_custom_values = TUNING.QUEST_COMPONENT.CUSTOM_SCALES[data.prefab]
        local has_custom_scale = has_custom_values and has_custom_values.scale

        if ay*SCALE >= ACTUAL_Y then
            SCALE = ACTUAL_Y/ay
            ACTUAL_X = ax*SCALE
        else
            ACTUAL_Y = ay*SCALE
        end
        SCALE = SCALE * (has_custom_scale or data.scrapbook_scale or 1)
        local w,h = TheSim:GetScreenSize()
        devprint("custom scales", data.prefab, has_custom_scale, SCALE, data.scrapbook_scale, w, h, h/880)
        SCALE = SCALE * h/880
        creature:GetAnimState():PlayAnimation(data.anim, true)
        --creature:SetClickable(false)
        if data and data.overridesymbol then
            if type(data.overridesymbol[1]) ~= "table" then
                creature:GetAnimState():OverrideSymbol(data.overridesymbol[1], data.overridesymbol[2], data.overridesymbol[3])
            else
                for _,set in ipairs( data.overridesymbol ) do
                    creature:GetAnimState():OverrideSymbol(set[1], set[2], set[3])
                end
            end
        end

        local extraoffsetx = (has_custom_values and has_custom_values.x) or (data and data.animoffsetx and data.animoffsetx) or 0
        local extraoffsety = (has_custom_values and has_custom_values.y) or (data and data.animoffsety and data.animoffsety) or 0

        --local posx = (offsetx+0+extraoffsetx) * (data.scrapbook_scale or has_custom_scale or 1)
        --local posy = (-offsety-75+extraoffsety) * (data.scrapbook_scale or has_custom_scale or 1)

        devprint("scale image", quest.victim, SCALE, ax, ay, ax * SCALE, ay * SCALE)
        creature:SetScale(SCALE)
        ax,ay = creature:GetBoundingBoxSize()
        local x1, y1, x2, y2 = creature:GetAnimState():GetVisualBB()
        devprint("VisualBB", x1, y1, x2, y2)
        local posx = 0 + (x1+x2) * SCALE/2 + extraoffsetx * SCALE --+ ax/2
        local posy = -75 + (y1+y2)* SCALE/2 + extraoffsety * SCALE  --+ ay/2

        creature:SetPosition(x+ posx,y + posy)

        --creature:SetFacing(FACING_DOWN)
        devprint("scaled boundingbox", creature:GetBoundingBoxSize())
        devprint("pos",posx, posy, x+ posx,y + posy)

    else
        target_atlas = quest.tex and GetInventoryItemAtlas(quest.tex,true) or quest.atlas or (quest.tex and "images/victims.xml")
        target_atlas = target_atlas ~= nil and softresolvefilepath(target_atlas) ~= nil and target_atlas or "images/avatars.xml"
        target_tex = target_atlas ~= "images/avatars.xml" and quest.tex or "avatar_unknown.tex"

        self["quest_"..num].image = self["quest__"..num]:AddChild(Image(target_atlas, target_tex))
        self["quest_"..num].image:ScaleToSize(64,64)
        self["quest_"..num].image:SetPosition(x, y - 80)
    end
    self["quest_"..num].image:MoveToFront()
    if quest.start_fn and type(quest.start_fn) == "string" and string.find(quest.start_fn,"start_fn_") then
        local fn = string.gsub(quest.start_fn,"start_fn_","")
        local text = TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[fn] and TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[fn].text
        if text and type(text) == "string" then
            local new_text = string.gsub(text," x "," "..quest.amount.." ")
            self["quest_"..num].image:SetHoverText(new_text)
        end
    elseif quest.hovertext ~= nil then
        self["quest_"..num].image:SetHoverText(quest.hovertext)
    elseif quest.victim and TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[quest.victim] then
        local text = TUNING.QUEST_COMPONENT.QUEST_BOARD.PREFABS_MOBS[quest.victim].hovertext or ""
        local new_text = string.gsub(text," x "," "..quest.amount.." ")
        local new_text2 = string.split(new_text,"/")
        local new_text3 = new_text2[1]..STRINGS.NAMES[string.upper(new_text2[2])]
        self["quest_"..num].image:SetHoverText(new_text3)
    end

    self["quest_"..num].button = self["quest__"..num]:AddChild(ImageButton("images/frontend.xml", "button_long.tex", "button_long_highlight.tex", "button_long_disabled.tex", nil, nil, {1,1}, {0,0}))
    self["quest_"..num].button:SetPosition(x + 5, y - 150)
    self["quest_"..num].button:SetScale(.5 * scale)
    self["quest_"..num].button:SetText("")
    self["quest_"..num].button.text:SetAutoSizingString(STRINGS_QL.GET_REWARDS, 280)
    self["quest_"..num].button.text:SetPosition(-5, 4)
    self["quest_"..num].button:SetFont(BUTTONFONT)
    if quest.completed ~= true then
        self["quest_"..num].button:Unselect()
    end

    self["quest_"..num].button:SetOnClick(function()
        self.ownerofscreen.replica.quest_component:CompleteQuest(quest.name)
        SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["GetRewards"],quest.name)
        Networking_Announcement(STRINGS_QL.RECEIVE_REWARDS.." "..(GetQuestString(quest.overridename or quest.name,"NAME") ~= "" and GetQuestString(quest.overridename or quest.name,"NAME",unpack(quest.scale)) or quest.name or "No Name").."!")
        self:OnClose()
    end)

    self["quest_"..num].button_close = self["quest__"..num]:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self["quest_"..num].button_close:SetPosition(x + 75, y + 185)
    self["quest_"..num].button_close:SetScale(0.5 * scale)
    self["quest_"..num].button_close:SetOnClick(function()
        self.last_selected = self["quest_"..num].button_close
        if self.show_rewards and self.show_rewards.shown == true then
            self.show_rewards:Kill()
        end
        self:AskForfeitQuest(quest,num)
    end)
    self["quest_"..num].button_close:SetHoverText(STRINGS_QL.FORFEIT_QUEST)
    self["quest_"..num].button_close:SetImageNormalColour(UICOLOURS.RED)

    local function MoveLeft(name)
        local next_quest_num = FindNextExistingQuest(self, num - 1, -1)
        return next_quest_num and self["quest_"..next_quest_num][name] or nil
    end
    local function MoveRight(name)
        local next_quest_num = FindNextExistingQuest(self, num + 1, 1)
        return next_quest_num and self["quest_"..next_quest_num][name] or nil
    end

    self["quest_"..num].button_close:SetFocusChangeDir(MOVE_LEFT, function() return MoveLeft("button_close") end)
    self["quest_"..num].button_close:SetFocusChangeDir(MOVE_RIGHT, function() return MoveRight("button_close") end)
    self["quest_"..num].button_close:SetFocusChangeDir(MOVE_DOWN, self["quest_"..num].description)

    self["quest_"..num].description:SetFocusChangeDir(MOVE_UP, self["quest_"..num].button_close)
    self["quest_"..num].description:SetFocusChangeDir(MOVE_LEFT, function() return MoveLeft("description") end)
    self["quest_"..num].description:SetFocusChangeDir(MOVE_RIGHT, function() return MoveRight("description") end)
    self["quest_"..num].description:SetFocusChangeDir(MOVE_DOWN, self["quest_"..num].rewards)

    self["quest_"..num].rewards:SetFocusChangeDir(MOVE_UP, self["quest_"..num].description)
    self["quest_"..num].rewards:SetFocusChangeDir(MOVE_LEFT, function() return MoveLeft("rewards") end)
    self["quest_"..num].rewards:SetFocusChangeDir(MOVE_RIGHT, function() return MoveRight("rewards") end)
    self["quest_"..num].rewards:SetFocusChangeDir(MOVE_DOWN, self["quest_"..num].image)

    self["quest_"..num].image:SetFocusChangeDir(MOVE_UP, self["quest_"..num].rewards)
    self["quest_"..num].image:SetFocusChangeDir(MOVE_LEFT, function() return MoveLeft("image") end)
    self["quest_"..num].image:SetFocusChangeDir(MOVE_RIGHT, function() return MoveRight("image") end)
    self["quest_"..num].image:SetFocusChangeDir(MOVE_DOWN, self["quest_"..num].button)

    self["quest_"..num].button:SetFocusChangeDir(MOVE_UP, self["quest_"..num].image)
    self["quest_"..num].button:SetFocusChangeDir(MOVE_LEFT, function() return MoveLeft("image") end)
    self["quest_"..num].button:SetFocusChangeDir(MOVE_RIGHT, function() return MoveRight("image") end)
    self["quest_"..num].button:SetFocusChangeDir(MOVE_DOWN, function() return self.bossbutton end)

end

local Quest_Widget = Class(Screen, function(self, inst)

  self.inst = inst
  self.ownerofscreen = inst
  self.tasks = {}

  Screen._ctor(self, "Quest_Widget")

  self.max_amount_of_quests = self.ownerofscreen.replica.quest_component and self.ownerofscreen.replica.quest_component._max_amount_of_quests:value() or 10

  self.black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
  self.black.image:SetVRegPoint(ANCHOR_MIDDLE)
  self.black.image:SetHRegPoint(ANCHOR_MIDDLE)
  self.black.image:SetVAnchor(ANCHOR_MIDDLE)
  self.black.image:SetHAnchor(ANCHOR_MIDDLE)
  self.black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
  self.black.image:SetTint(0, 0, 0, .5)
  self.black:SetOnClick(function() TheFrontEnd:PopScreen() end)
  self.black:SetHelpTextMessage("")

  self.proot = self:AddChild(Widget("ROOT"))
  self.proot:SetVAnchor(ANCHOR_MIDDLE)
  self.proot:SetHAnchor(ANCHOR_MIDDLE)
  self.proot:SetPosition(23, 0)
  self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

  --self.bg = self.proot:AddChild(Templates.CurlyWindow(500, 450, 1, 1, 68, -40))
  self.bg = self.proot:AddChild(Image("images/quest_log_bg.xml","quest_log_bg.tex"))
  self.bg:SetPosition(7, -10)
  --self.bg:SetVAnchor(ANCHOR_MIDDLE)
  --self.bg:SetHAnchor(ANCHOR_MIDDLE)
  --self.bg:SetScaleMode(SCALEMODE_PROPORTIONAL)
  self.bg:SetScale(1.1,1)

  --self.title_bg = self.proot:AddChild(Image("images/lavaarena_unlocks.xml","community_unlock_info.tex"))
  --self.title_bg:SetPosition(0, 250)

  self.title = self.proot:AddChild(Text(NEWFONT_OUTLINE, 60, STRINGS_QL.QUEST_LOG, {unpack(UICOLOURS.HIGHLIGHT_GOLD)}))
  self.title:SetPosition(0, 240)

  self.cancel_button = self.proot:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
  self.cancel_button:SetPosition(440, 260, 0)
  self.cancel_button:SetScale(1.3)
  self.cancel_button:SetOnClick(function()
    self:OnClose()
  end)
  self.cancel_button:SetHoverText(STRINGS_QL.CLOSE)
  self.cancel_button:SetImageNormalColour(UICOLOURS.RED)


  -- Create a new root to center the cards
  for i = 1,math.ceil(self.max_amount_of_quests/5) do
    self["quests"..i] = self.proot:AddChild(Widget("ROOT"))
    self["quests"..i]:SetPosition(-100, 0)
    self["quests"..i].cards = {}
    if i ~= 1 then
      self["quests"..i]:Hide()
    end
  end

  for num = 1,self.max_amount_of_quests do
    self["quest__"..num] = self["quests"..(math.floor((num-1)/5+1))]:AddChild(Widget("quest__"..num))
    self["quest__"..num].cards = {}
  end

  self:CreateQuests(inst)

    SetFirstQuestAsFocus(self)

  self.page = 1
  self.min_page = 1
  self.max_page = math.ceil(self.max_amount_of_quests/5)

  self.quests_right_button = self.proot:AddChild(ImageButton("images/ui.xml","arrow2_right.tex","arrow2_right_over.tex","arrow_right_disabled.tex","arrow2_right_down.tex"))
  self.quests_right_button:SetPosition(440, -220, 0)
  self.quests_right_button:SetOnClick(function()
      self["quests"..self.page]:Hide()
      self.page = self.page + 1
      self["quests"..self.page]:Show()
      if self.page == self.max_page then
        self.quests_right_button:Hide()
      else
        self.quests_right_button:SetHoverText(STRINGS_QL["PAGE_"..(self.page+1)])
      end
      if self.quests_left_button.shown == false then
        self.quests_left_button:Show()
      end
      if self.show_rewards and self.show_rewards.shown == true then
          self.show_rewards:Kill()
      end
      if self.stats and self.stats.shown == true then
          self.stats:Hide()
      end
      self.quests_left_button:SetHoverText(STRINGS_QL["PAGE_"..(self.page-1)])
      SetFirstQuestAsFocus(self)
  end)
  self.quests_right_button:SetHoverText(STRINGS_QL.PAGE_2)

  self.quests_left_button = self.proot:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
  self.quests_left_button:SetPosition(-430, -220, 0)
  self.quests_left_button:SetOnClick(function()
      self["quests"..self.page]:Hide()
      self.page = self.page - 1
      self["quests"..self.page]:Show()
      if self.page == self.min_page then
        self.quests_left_button:Hide()
        self.stats:Show()
      else
        self.quests_left_button:SetHoverText(STRINGS_QL["PAGE_"..(self.page-1)])
      end
      if self.quests_right_button.shown == false then
        self.quests_right_button:Show()
      end
      if self.show_rewards and self.show_rewards.shown == true then
          self.show_rewards:Kill()
      end
      self.quests_right_button:SetHoverText(STRINGS_QL["PAGE_"..(self.page+1)])
      SetFirstQuestAsFocus(self)
  end)
  self.quests_left_button:SetHoverText(STRINGS_QL.PAGE_1)
  self.quests_left_button:Hide()

  if self.max_page < 2 then
    self.quests_right_button:Hide()
  end

  self.stats = self.proot:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
  self.stats:SetPosition(-430, -220, 0)
  self.stats:SetOnClick(function()
      self.proot:Hide()
      self.statpage:Show()
      self.initialpage:Show()
      if self.show_rewards and self.show_rewards.shown == true then
          self.show_rewards:Kill()
      end
      if self.bonus_button then
          self.bonus_button:SetFocus()
      end
    end)
  self.stats:SetHoverText(STRINGS_QL.SCOREBOARD)

  self.uibottom = self.proot:AddChild(Widget("ROOT"))

  self._level = self.uibottom:AddChild(Widget())
  self._level:SetPosition(-280, -225, 0)
  self._level:SetScale(0.75)

  self.levelbg_ = self._level:AddChild(Image("images/avatars.xml","avatar_bg_white.tex"))
  self.levelbg_:SetPosition(0, 0, 0)
  self.levelbg_:SetScale(1.1)
  self.levelbg = self._level:AddChild(Image("images/avatars.xml","avatar_frame.tex"))
  self.levelbg:SetPosition(0, 0, 0)
  self.levelbg:SetScale(1.1)
  

  local val = inst.replica.quest_component._level:value() and math.fmod(inst.replica.quest_component._level:value(),195) or 1
  if val == 0 then
    val = 195
  end
  local _profileflair = profile_flairs[val] or "profileflair_theforge_beetletaur.tex"
  self.levelflair = self._level:AddChild(Image("images/profileflair.xml",_profileflair))
  self.levelflair:SetPosition(0, 13, 0)
  self.levelflair:SetScale(.45)
  self.levelflair:SetHoverText(STRINGS_QL.CURRENT_LEVEL)
  
  self.level = self._level:AddChild(Text(CHATFONT_OUTLINE, 30, nil))
  self.level:SetString(tostring(inst.replica.quest_component._level:value() or 1))
  self.level:SetPosition(2, -20, 0)
  self.level:SetHoverText(STRINGS_QL.CURRENT_LEVEL)

  self._rank = self.uibottom:AddChild(Widget())
  self._rank:SetPosition(-150, -225, 0)
  self._rank:SetScale(0.75)

  self.rankbg_ = self._rank:AddChild(Image("images/avatars.xml","avatar_bg.tex"))
  self.rankbg_:SetPosition(0, 0, 0)
  self.rankbg_:SetScale(1.1)
  self.rankbg = self._rank:AddChild(Image("images/avatars.xml","avatar_ghost_frame.tex"))
  self.rankbg:SetPosition(0, 0, 0)
  self.rankbg:SetScale(1.1)

  local rank_colours = {
      D = {120/255,94/255,240/255,1}, 
      C = {100/255,143/255,255/255,1}, 
      B = {255/255,176/255,0/255,1},
      A = {254/255,97/255,0/255,1},
      S = {220/255,38/255,127/255,1},
    }

  self.rank = self._rank:AddChild(Text(TALKINGFONT, 50, nil))
  local rank_str,dist_btw_next_rank = inst.replica.quest_component:GetRankStr()
  self.rank:SetString(rank_str or "D")
  self.rank:SetColour(rank_colours[rank_str or "D"])
  self.rank:SetPosition(4, -5, 0)
  self.rank:SetHoverText(STRINGS_QL.CURR_RANK..(dist_btw_next_rank or "Error"))


  self.bg_points = self.uibottom:AddChild(Image("images/lavaarena_unlocks.xml","tab_active.tex"))
  self.bg_points:SetPosition(250, -215, 0)
  self.bg_points:SetScale(0.6)

  self.points = self.uibottom:AddChild(Text(NEWFONT_OUTLINE, 30, nil))
  self.points:SetAutoSizingString(STRINGS_QL.POINTS..": "..tostring(math.floor(inst.replica.quest_component._points:value() or 0)).."/"..tostring((inst.replica.quest_component._level:value() * 25 + 100) * TUNING.QUEST_COMPONENT.LEVEL_RATE  or 100), 180)
  self.points:SetPosition(250, -200, 0)
  self.progressbar = self.uibottom:AddChild(UIAnim())
  self.progressbar:GetAnimState():SetBank("player_progressbar_small")
  self.progressbar:GetAnimState():SetBuild("player_progressbar_small")
  self.progressbar:GetAnimState():PlayAnimation("fill_progress", true)
  self.progressbar:GetAnimState():SetPercent("fill_progress", 0)
  self.progressbar:SetPosition(250,-240)
  local percent = inst.replica.quest_component._points:value() / ((inst.replica.quest_component._level:value() * 25 + 100) * TUNING.QUEST_COMPONENT.LEVEL_RATE) or 1
  self.progressbar:GetAnimState():SetPercent("fill_progress", percent)
  self.progressbar:SetHoverText(math.floor(percent*100).."%")

    if TUNING.QUEST_COMPONENT.BOSSFIGHTS == true then
        self.bossbutton = self.uibottom:AddChild(ImageButton("images/lavaarena_quests.xml","laq_dailywin.tex","laq_dailywin.tex","laq_dailywin_locked.tex"))
        self.bossbutton:SetPosition(0, -220, 0)
        self.bossbutton:SetOnClick(function()
            SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["BossFight"])
            self:OnClose()
        end)
        self.bossbutton:SetHoverText(STRINGS_QL.BOSSFIGHT)
        self.bossbutton:SetScale(0.7,0.7)
        if inst.replica.quest_component._bossfight:value() <= 0 or TheWorld:HasTag("cave") or self.ownerofscreen:HasTag("currently_in_bossfight") then
            self.bossbutton:Unselect()
        end
        self.bossbutton:SetFocusChangeDir(MOVE_UP, function() SetFirstQuestAsFocus(self) end)
    end

  self.statpage = self:AddChild(Widget("ROOT"))
  self.statpage:SetVAnchor(ANCHOR_MIDDLE)
  self.statpage:SetHAnchor(ANCHOR_MIDDLE)
  self.statpage:SetPosition(20, 0)
  self.statpage:SetScaleMode(SCALEMODE_PROPORTIONAL)


  self.bg2 = self.statpage:AddChild(Templates.CenterPanel(.8, .8, true, 610, 500, 46, -28))
  self.bg2.bg:SetTint(1,1,1,0.5)

  self.title2 = self.statpage:AddChild(Text(NEWFONT_OUTLINE, 50, STRINGS_QL.SCOREBOARD, {unpack(GOLD)}))
  self.title2:SetPosition(0, 250)

  self.initialpage = self.statpage:AddChild(ImageButton("images/ui.xml","arrow2_right.tex","arrow2_right_over.tex","arrow_right_disabled.tex","arrow2_right_down.tex"))
  self.initialpage:SetPosition(440, -220, 0)
  self.initialpage:SetOnClick(
    function()
        self.proot:Show()
        self.statpage:Hide()
        if self.show_bonus and self.show_bonus.shown == true then
            self.show_bonus:Kill()
        end
        self.quests1:Show()
        if self.max_page > 1 then
          self.quests_right_button:Show()
        end
        self.quests_left_button:Hide()
        self.initialpage:Hide()
        self.stats:Show()
        self.uibottom:Show()
        SetFirstQuestAsFocus(self)
    end
  )
  self.initialpage:SetHoverText(STRINGS_QL.PAGE_1)

  self.list_root = self.statpage:AddChild(Widget("list_root"))
  self.list_root:SetVAnchor(ANCHOR_MIDDLE)
  self.list_root:SetHAnchor(ANCHOR_MIDDLE)
  self.list_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
  --self.list_root:SetPosition(210, -35)

  local CalculatePoints = TUNING.QUEST_COMPONENT.CalculatePoints

  local list_elements = {}
  local ClientObjs = GetPlayerTable()
  local ranked_players = {}       

  for _,v in ipairs(ClientObjs) do
    local near_player
    for _,player in ipairs(AllPlayers) do
      if player.userid == v.userid then
        near_player = player
        break
      end
    end
    local value
    if near_player then
      value = CalculatePoints(near_player.replica.quest_component._level:value(),near_player.replica.quest_component._points:value())
      self.ownerofscreen.player_qs_points[v.userid] = value
    end
    ranked_players[v.userid] = value or self.ownerofscreen.player_qs_points[v.userid] or 0
  end

  local count = 0
    for k,v in spairs(ranked_players, function(t,a,b) return t[b] < t[a] end) do
        count = count + 1
        local player_root = Widget("PLAYER_ROOT")
        player_root:SetVAnchor(ANCHOR_MIDDLE)
        player_root:SetHAnchor(ANCHOR_MIDDLE)
        player_root:SetPosition(210, -35)
        local player = player_root:AddChild(Image("images/scoreboard.xml","row.tex"))
        player:SetPosition(22,5)

        if count == 1 then
          player.highlight = player:AddChild(Image("images/scoreboard.xml", "row_goldoutline.tex"))
          player.highlight:SetPosition(0, 0)
        elseif count == 2 then
          player.highlight = player:AddChild(Image("images/scoreboard.xml", "row_goldoutline.tex"))
          player.highlight:SetPosition(0, 0)
          player.highlight:SetTint(0.6,0.75,1,1)
        elseif count == 3 then
          player.highlight = player:AddChild(Image("images/scoreboard.xml", "row_goldoutline.tex"))
          player.highlight:SetPosition(0, 0)
          player.highlight:SetTint(1,0.8,0.31,1)
        end

        local client 
        for _,b in ipairs(ClientObjs) do
          if b.userid == k then    
            client = b                    
            break       
          end
        end
        local colour = count == 1 and {unpack(GOLD)} or count == 2 and {unpack(UICOLOURS.SILVER)} or count == 3 and {unpack(UICOLOURS.BRONZE)} or nil
        if client then
            player.rank = player:AddChild(Text(UIFONT, 35, tostring(count),colour))
            player.rank:SetPosition( -368, 0, 0)
            player.characterBadge = nil
            player.characterBadge = player:AddChild(PlayerBadge("", DEFAULT_PLAYER_COLOUR, false, 0))
            player.characterBadge:SetScale(.8)
            player.characterBadge:SetPosition(-328,0,0)
            player.characterBadge:Set(client.prefab or "", client.colour or DEFAULT_PLAYER_COLOUR, client.performance ~= nil, client.userflags or 0, client.base_skin)
            player.displayName = client.name or ""
            player.name = player:AddChild(Text(UIFONT, 35, player.displayName))
            player.name:SetPosition( -220, 0, 0)
            player.name:SetColour(unpack(client.colour or DEFAULT_PLAYER_COLOUR))
        end
        local level,points = TUNING.QUEST_COMPONENT.CalculateLevel(v)
        player.level = player:AddChild(Text(UIFONT,35, STRINGS_QL.LEVEL..": "..tostring(level) or "No Info",colour))
        player.level:SetPosition(-100, 0)
        player.points = player:AddChild(Text(UIFONT,35,nil,colour))
        player.points:SetString(STRINGS_QL.POINTS..": "..tostring(math.floor(points) or 0))
        player.points:SetPosition(100, 0)
          
        table.insert(list_elements,player)
    end

    self.list = self.list_root:AddChild(ScrollableList(list_elements, 380, 370, 60, 3, nil, nil, nil, nil, nil, -15))
    self.list:SetPosition(220,40)

    self.completed_quests_image = self.statpage:AddChild(Image("images/profileflair.xml","playerlevel_bg_lavaarena.tex"))
    self.completed_quests_image:SetPosition(-268, -210)

    self.completed_quests_text = self.statpage:AddChild(Text(UIFONT, 35, STRINGS_QL.COMPLETED_QUESTS..":"))
    self.completed_quests_text:SetPosition(-380, -200)
    self.completed_quests_text:SetAutoSizingString(STRINGS_QL.COMPLETED_QUESTS..":",170)
    self.completed_quests_text2 = self.statpage:AddChild(Text(UIFONT, 35, tostring(inst.replica.quest_component._completed_quest:value() or 0)))
    self.completed_quests_text2:SetPosition(-268, -200)
      
    self.total_points_image = self.statpage:AddChild(Image("images/profileflair.xml","playerlevel_bg_lavaarena.tex"))
    self.total_points_image:SetPosition(350, -210)
    self.total_points_image:SetScale(1.5,1)

    self.total_points_text = self.statpage:AddChild(Text(UIFONT, 35, STRINGS_QL.TOTAL_POINTS..":"))
    self.total_points_text:SetPosition(218, -200)
    self.total_points_text:SetAutoSizingString(STRINGS_QL.TOTAL_POINTS..":",170)

    self.total_points_text2 = self.statpage:AddChild(Text(UIFONT, 35,tostring(math.floor(CalculatePoints(inst.replica.quest_component._level:value(),inst.replica.quest_component._points:value())) or 0)))
    self.total_points_text2:SetPosition(350, -200)

    if TUNING.QUEST_COMPONENT.LEVELSYSTEM == 1 then

        self.bonus_button = self.statpage:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.bonus_button:SetPosition(0, -200)
        self.bonus_button:SetTextSize(30)
        self.bonus_button:SetScale(0.8,0.8)
        self.bonus_button:SetText(STRINGS_QL.SHOW_BONUS)
        self.bonus_button:SetOnClick(function()
            self.last_selected = self.bonus_button
            self:ShowBonus()
        end)
    end


  self.initialpage:Hide()

  self.statpage:Hide()

  self.tasks.update_amounts = self.inst:DoPeriodicTask(1,function()
    for i = 1,self.max_amount_of_quests do
      if self["quest_"..i] and self["quest_"..i].progress and self["quest_"..i].name then
        local quest = self.ownerofscreen.replica.quest_component._quests[self["quest_"..i].name]
        if quest then
          self["quest_"..i].progress:SetString(tostring(math.floor(quest.current_amount)).."/"..tostring(math.floor(quest.amount)))
          if self["quest_"..i].button and not self["quest_"..i].button:IsEnabled() and quest.completed then
            self["quest_"..i].button:Enable()
          end
        end
      end
    end
  end)

    SetAutopaused(true)

end)

local boni = {  healthbonus = {-20,150,100},
                sanitybonus = {-20,100,100},
                hungerbonus = {-20,50,100},
                speedbonus = {-20,0,100},
                summerinsulationbonus = {-30,-50,100},
                winterinsulationbonus = {-30,-100,100},
                workmultiplierbonus = {-30,-150,100},
            }


function Quest_Widget:ShowBonus()
    self.show_bonus = self.statpage:AddChild(Widget("show_bonus"))
    self._show_bonus = self.show_bonus:AddChild(Image("images/global_redux.xml","mvp_panel.tex"))
    self._show_bonus:SetScale(1.2,0.75)

    for k,v in pairs(boni) do
        self[k] = self.show_bonus:AddChild(Text(UIFONT, 35, STRINGS_QL[string.upper(k)]))
        self[k]:SetPosition(v[1], v[2])
        self[k]:SetAutoSizingString(STRINGS_QL[string.upper(k)],210)
        local value = 0
        if self.ownerofscreen and self.ownerofscreen.q_system and self.ownerofscreen.q_system[k] then
            value = self.ownerofscreen.q_system[k]:value()
        end
        if k == "speedbonus" or k == "workmultiplierbonus" then
            self[k..2] = self.show_bonus:AddChild(Text(UIFONT, 35, tostring(RoundBiasedUp(value,3))))
        else
            self[k..2] = self.show_bonus:AddChild(Text(UIFONT, 35, tostring(RoundBiasedDown(value,3))))
        end
        self[k..2]:SetPosition(v[3],v[2])
    end

    self.close_bonus = self.show_bonus:AddChild(TextButton())
    self.close_bonus:SetPosition(0, -195, 0)
    self.close_bonus:SetTextSize(25)
    self.close_bonus:SetScale(1,1.25)
    self.close_bonus:SetText(STRINGS_QL.CLOSE)
    self.close_bonus:SetOnClick(function()
        self.show_bonus:Kill()
        self.last_selected:SetFocus()
        self.has_close_button = nil
    end)
    self.has_close_button = self.close_bonus
end

function Quest_Widget:ShowRewards(tab)

  self.show_rewards = self.proot:AddChild(Widget("show_rewards"))
  --self.show_rewards:SetTint(1,1,1,1)
  self.show_rewards:SetPosition(0,0)
  self.show_rewards:SetScale(1,1)

  self.show_rewards_bg = self.show_rewards:AddChild(Image("images/quest_log_page.xml","quest_log_page.tex"))
  self.show_rewards_bg:SetPosition(0,0)
  self.show_rewards_bg:SetScale(1,1)


  self._show_rewards = self.show_rewards:AddChild(Text(NEWFONT_OUTLINE, 40,nil,UICOLOURS.BLACK))

  local invimages = {}
  local num = 0 
  for k,v in pairs(tab.rewards) do
    num = num + 1
    local str1 = GetRewardString(k,v)
    local rew_num = (type(v) == "string" and v) or (v and tostring(math.ceil(v * TUNING.QUEST_COMPONENT.REWARDS_AMOUNT)) or 0)
    if str1 and string.find(str1," x ") then
        str1 = string.gsub(str1," x "," "..rew_num.." ")
    end
    local str  = str1 or tostring(STRINGS.NAMES[string.upper(k)] or k or "?")..(tostring(rew_num) ~= "" and ": "..tostring(rew_num) or "")

    invimages["text"..num] = self.show_rewards:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
    invimages["text"..num]:SetAutoSizingString(str,240)
    invimages["text"..num]:SetPosition(-20, 160 - num*50)
    invimages["text"..num]:SetScale(1,1)
    --invimages["text"..num]:SetRegionSize(175, 350)

    invimages["_"..num] = self.show_rewards:AddChild(Image("images/hud.xml", "inv_slot.tex"))
    invimages["_"..num]:SetPosition(120,160 - num*50)
    invimages["_"..num]:SetScale(0.5,0.5)

    local tex = tab["reward_"..k.."_tex"] or (TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k] and FunctionOrValue(TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k][3], v) or k..".tex")
    local atlas = tab["reward_"..k.."_atlas"] or (TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k] and FunctionOrValue(TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k][4], v)) or GetInventoryItemAtlas(tex,true)
    devprint("atlas and tex", tex, atlas, GetInventoryItemAtlas(tex,true))
    if atlas then
      invimages[num] = self.show_rewards:AddChild(Image(atlas,tex))
      invimages[num]:SetPosition(120,160 - num*50)
      invimages[num]:SetScale(0.5,0.5)
    end
  end
  self._show_rewards:SetString(STRINGS_QL.REWARDS..":\n")
  self._show_rewards:SetPosition(0, 160)
  self._show_rewards:SetScale(1,1)
  --self._show_rewards:SetRegionSize(175, 350)
  self._show_rewards:EnableWordWrap(true)
  self._show_rewards:EnableWhitespaceWrap(true)

  self._show_rewards_divider = self.show_rewards:AddChild(Image("images/quagmire_recipebook.xml","quagmire_recipe_line.tex"))
  self._show_rewards_divider:SetPosition(0, 145)
  self._show_rewards_divider:SetScale(0.5,1)

  self.point = self.show_rewards:AddChild(Text(BUTTONFONT, 30,nil,UICOLOURS.BLACK))
  self.point:SetAutoSizingString(STRINGS_QL.POINTS..": "..(tab.points or 0),200)
  self.point:SetPosition(0, -180, 0)

  --[[self.close_rewards = self.show_rewards:AddChild(TextButton())
  self.close_rewards:SetPosition(0, -240, 0)
  self.close_rewards:SetTextSize(25)
  self.close_rewards:SetScale(1,1)
  self.close_rewards:SetText(STRINGS_QL.CLOSE)
  self.close_rewards:SetOnClick(function()
      self.show_rewards:Kill()
    end)]]

    self.close_rewards = self.show_rewards:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_rewards:SetPosition( 175, 200)
    self.close_rewards:SetScale(1)
    self.close_rewards:SetOnClick(function()
        self.last_selected:SetFocus()
        self.show_rewards:Kill()
        self.has_close_button = nil
    end)
    self.close_rewards:SetHoverText(STRINGS_QL.CLOSE)
    self.close_rewards:SetImageNormalColour(UICOLOURS.RED)
    self.has_close_button = self.close_rewards

end

function Quest_Widget:ShowDescription(tab)

    self.show_rewards = self.proot:AddChild(Widget("show_rewards"))
    self.__show_rewards = self.show_rewards:AddChild(Image("images/quest_log_page.xml","quest_log_page.tex"))
    self.__show_rewards:SetTint(1,1,1,1)
    self.__show_rewards:SetPosition(0,0)
    self.__show_rewards:SetScale(1.4,1.2)

    self._show_rewards = self.show_rewards:AddChild(Text(NEWFONT_OUTLINE, 45,nil,UICOLOURS.BLACK))
    local scale = tab.scale or {}
    local name = GetQuestString(tab.overridename or tab.name,"NAME",unpack(scale))
    --self._show_rewards:SetString(name ~= "" and name or tab.name)
    self._show_rewards:SetPosition(0, 165)
    self._show_rewards:SetScale(1,1)
    self._show_rewards:SetRegionSize(500, 50)
    self._show_rewards:EnableWordWrap(true)
    self._show_rewards:EnableWhitespaceWrap(true)
    self._show_rewards:SetAutoSizingString(name ~= "" and name or tab.name, 500)

    self._show_rewards_divider = self.show_rewards:AddChild(Image("images/quagmire_recipebook.xml","quagmire_recipe_line_long.tex"))
    self._show_rewards_divider:SetPosition(0, 140)
    self._show_rewards_divider:SetScale(0.5,1)

    self._show_rewards2 = self.show_rewards:AddChild(Text(BUTTONFONT, 30,nil,UICOLOURS.BLACK))--(BUTTONFONT, 20,nil,UICOLOURS.BLACK))
    --self._show_rewards2:SetScale(1,1)
    self._show_rewards2:SetMultilineTruncatedString(tab.description,15,400,150,nil,true)
    local _,h = self._show_rewards2:GetRegionSize()
    self._show_rewards2:SetPosition(0, 130 - 0.5* h)


    self.close_rewards = self.show_rewards:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_rewards:SetPosition( 250, 240)
    self.close_rewards:SetScale(1)
    self.close_rewards:SetOnClick(function()
        self.last_selected:SetFocus()
        self.show_rewards:Kill()
        self.has_close_button = nil
    end)
    self.close_rewards:SetHoverText(STRINGS_QL.CLOSE)
    self.close_rewards:SetImageNormalColour(UICOLOURS.RED)
    self.has_close_button = self.close_rewards
end

function Quest_Widget:AskForfeitQuest(tab,num)
  self.show_rewards = self.proot:AddChild(Widget("show_rewards"))

  local button1 = {
    text = STRINGS_QL.YES,
    cb = function()
      self:ForfeitQuest(num)
      SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["ForfeitQuest"],tab.name)
      self.show_rewards:Kill()
    end,
    }
    local button2 = {
    text = STRINGS_QL.NO,
    cb = function()
        self.show_rewards:Kill()
        self.last_selected:SetFocus()
        self.has_close_button = self.old_has_close_button
    end,
    }

    self.askforfeit = self.show_rewards:AddChild(Templates_R.CurlyWindow(450,200,nil,{button1,button2},nil,STRINGS_QL.ASK_FORFEIT))
    self.askforfeit.body:SetSize(40)
    self.askforfeit.body:SetPosition(0, 70)
    self.askforfeit.actions.items[1]:SetFocus()
    self.old_has_close_button = self.has_close_button
    self.has_close_button = self.askforfeit.actions.items[2]
end

function Quest_Widget:CreateQuests(inst)
  inst = inst or ThePlayer or self.inst
  if inst.replica.quest_component then
      local count = 0
      for _,v in pairs(inst.replica.quest_component._quests) do
          count = count + 1
          self["quest__"..count].cards[count] = createQuestCard(self,v, -75 + 180 * ((count-1)%5 + 1 - 2) , 0, 1,count)
          if count >= self.max_amount_of_quests then
            break
          end
      end
      if count < self.max_amount_of_quests then
        for counter = count + 1,self.max_amount_of_quests do 
          self["quest__"..counter].cards[counter]  = createEmptyQuestCard(self,nil, -75 + 180 * ((counter-1)%5 + 1 - 2) , 0, 1,counter)
        end
      end
  end
end

function Quest_Widget:ForfeitQuest(counter)
    if counter == nil then return end
    if self["quest__"..counter] then
        self["quest__"..counter]:Kill()
    end
    self["quest__"..counter] = self["quests"..(math.floor((counter-1)/5+1))]:AddChild(Widget("quest__"..counter))
    self["quest__"..counter].cards = {}
    self["quest__"..counter].cards[counter] = createEmptyQuestCard(self,nil, -75 + 180 * ((counter-1)%5 + 1 - 2) , 0, 1,counter)

    SetFirstQuestAsFocus(self)
end


function Quest_Widget:OnClose()
  for _,v in pairs(self.tasks) do
    if v then
      v:Cancel()
    end
  end
  local screen = TheFrontEnd:GetActiveScreen()
  if screen and screen.name:find("HUD") == nil then
    TheFrontEnd:PopScreen()
  end
  TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
end

function Quest_Widget:OnOpen()
  local percent = self.inst.replica.quest_component._points:value() / (self.inst.replica.quest_component._level:value() * 100 + 100) or 1
  self.progressbar:GetAnimState():SetPercent("fill_progress", percent)
  self.progressbar:SetHoverText(math.floor(percent*100).."%")
end

function Quest_Widget:OnControl(control, down)
    if Quest_Widget._base.OnControl(self, control, down) then
        return true
    end
    if down then
        if (control == CONTROL_PAUSE or control == CONTROL_MENU_MISC_2) then
            self:OnClose()
            return true
        elseif control == CONTROL_CANCEL and self.has_close_button then
            self.has_close_button.onclick()
            return true
        elseif control == CONTROL_SCROLLBACK then
            if self.quests_left_button:IsVisible() then
                self.quests_left_button.onclick()
                return true
            elseif self.stats:IsVisible() then
                self.stats.onclick()
                return true
            end
        elseif control == CONTROL_SCROLLFWD then
            if self.quests_right_button:IsVisible() then
                self.quests_right_button.onclick()
                return true
            elseif self.initialpage:IsVisible() then
                self.initialpage.onclick()
                return true
            end
        end
    end
end

function Quest_Widget:OnDestroy()
    SetAutopaused(false)
    self._base.OnDestroy(self)
end

function Quest_Widget:GetHelpText()
    local t = {}
    local controller_id = TheInput:GetControllerID()

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_2) .. " " .. STRINGS_QL.CLOSE)

    if self.has_close_button then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS_QL.GO_BACK)
    end

    if self.stats:IsVisible() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK) .. " " .. STRINGS_QL.SHOW_STATS)
    end

    if self.initialpage:IsVisible() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD) .. " " .. STRINGS_QL.SHOW_QUESTS)
    end

    if self.quests_left_button:IsVisible() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLBACK) .. " " .. STRINGS_QL.TURN_LEFT)
    end

    if self.quests_right_button:IsVisible() then
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_SCROLLFWD) .. " " .. STRINGS_QL.TURN_RIGHT)
    end

    return table.concat(t, "  ")
end

return Quest_Widget
