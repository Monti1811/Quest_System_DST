local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Button = require "widgets/button"
local TextButton = require "widgets/textbutton"
local TextEdit = require "widgets/textedit"
local Screen = require "widgets/screen"
local Templates = require "widgets/templates"
local Templates_R = require "widgets/redux/templates"
local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local FilterBar = require "widgets/redux/filterbar"
local ItemExplorer = require "widgets/redux/itemexplorer"
local STRINGS_QB = STRINGS.QUEST_COMPONENT.QUEST_BOARD
local STRINGS_QL = STRINGS.QUEST_COMPONENT.QUEST_LOG
local QUEST_BOARD = TUNING.QUEST_COMPONENT.QUEST_BOARD
local QUEST_COMPONENT = TUNING.QUEST_COMPONENT
local QUESTS = TUNING.QUEST_COMPONENT.QUESTS


local profile_flairs = require "profile_flairs"
--local util = require "quest_system/Quest_Board_Util"

local colour_difficulty 
if QUEST_COMPONENT.COLORBLINDNESS == 1 then
    colour_difficulty = {
      {120/255,94/255,240/255,1}, 
      {100/255,143/255,255/255,1}, 
      {255/255,176/255,0/255,1},
      {254/255,97/255,0/255,1},
      {220/255,38/255,127/255,1},
    }
else
    colour_difficulty = {
      {23/255,255/255,0/255,1}, 
      {68/255,88/255,255/255,1}, 
      WEBCOLOURS.YELLOW,
      WEBCOLOURS.ORANGE,
      WEBCOLOURS.RED,
    }
end

local button_positions = {
    {{0,170,0},},
    {{0,170,0},{0,70,0}},
    {{0,170,0},{0,70,0},{0,-30,0}},
    {{-175,170,0},{-175,70,0},{-175,-30,0},{175,170,0}},
    {{-175,170,0},{-175,70,0},{-175,-30,0},{175,170,0},{175,70,0}},
    {{-175,170,0},{-175,70,0},{-175,-30,0},{175,170,0},{175,70,0},{175,-30,0}},
}

local spinner_cat = {
    --"Description",
    {STRINGS_QB.REWARD1,QUEST_BOARD.PREFABS_ITEMS},
    {STRINGS_QB.REWARD2,QUEST_BOARD.PREFABS_ITEMS},
    {STRINGS_QB.REWARD3,QUEST_BOARD.PREFABS_ITEMS},
    {STRINGS_QB.DIFFICULTY,QUEST_BOARD.NUMBERS["1_5"]},
    {STRINGS_QB.VICTIM,QUEST_BOARD.PREFABS_MOBS},
    --{STRINGS_QB.NUMBERS,QUEST_BOARD.NUMBERS["1_40"]},
    --{STRINGS_QB.FOODS,QUEST_BOARD.PREFABS_FOODS},
    --{STRINGS_QB.ITEMS,QUEST_BOARD.PREFABS_ITEMS},
}

local spinner_rewards = {
    {STRINGS_QB.REWARD1.." "..STRINGS_QB.AMOUNT,QUEST_BOARD.NUMBERS["0_40"]},
    {STRINGS_QB.REWARD2.." "..STRINGS_QB.AMOUNT,QUEST_BOARD.NUMBERS["0_40"]},
    {STRINGS_QB.REWARD3.." "..STRINGS_QB.AMOUNT,QUEST_BOARD.NUMBERS["0_40"]},
}

local Quest_Board_Widget = Class(Screen, function(self, owner)
    local button_amount = 0
	self.owner = owner

	self.tasks = {}

    local buttons = {}  --{"new_quest","level_rewards","create_new_quest","check_custom_quests","new_quest2"}

    self.new_custom_quest = {}
    if QUEST_BOARD.CUSTOM_QUEST ~= nil then
        self.new_custom_quest = QUEST_BOARD.CUSTOM_QUEST
    end

	Screen._ctor(self, "Quest_Board_Widget")

	self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
 	self.black:SetHRegPoint(ANCHOR_MIDDLE)
 	self.black:SetVAnchor(ANCHOR_MIDDLE)
 	self.black:SetHAnchor(ANCHOR_MIDDLE)
	self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
 	self.black:SetTint(0, 0, 0, .75)

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
 	self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(20, 0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)


    self.bg = self.proot:AddChild(Image("images/quest_board_widget.xml","quest_board_widget.tex"))
    self.bg:SetPosition(0, 25)
	self.bg:SetSize(1400, 950)

    self.bg2 = self.proot:AddChild(Image("images/quest_board_widget2.xml","quest_board_widget2.tex"))
    self.bg2:SetPosition(0, 25)
    self.bg2:SetSize(1400, 950)
    self.bg2:SetTint(0, 0, 0, 1)

    self.bg3 = self.proot:AddChild(Image("images/quest_board_widget2.xml","quest_board_widget2.tex"))
    self.bg3:SetPosition(0, 25)
    self.bg3:SetSize(1400, 950)
    self.bg3:SetTint(1, 1, 1, .75)

	self.root = self.bg3:AddChild(Widget("root"))

	--self.title = self.proot:AddChild(Text(NEWFONT_OUTLINE, 40, STRINGS.QUEST_COMPONENT.QUEST_BOARD.QUEST_BOARD, {unpack(GOLD)}))
  	--self.title:SetPosition(0, 300)

    local button_x = -175 --0
    self.new_quest = self.root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    --self.new_quest:SetPosition(button_x, 170, 0)
    self.new_quest:SetTextSize(30)
    --self.new_quest:SetText(STRINGS_QB.LOOK_FOR_QUESTS)
    --print(self.new_quest.text)
    self.new_quest.text:SetAutoSizingString(STRINGS_QB.LOOK_FOR_QUESTS,290)
    self.new_quest.text:Show()
    button_amount = button_amount + 1
    table.insert(buttons,"new_quest")


    self.new_quest:SetOnClick(function()
        self.root:Hide()
        self:ShowNewQuests()
    end)
    if self.owner.replica.quest_component._acceptedquest:value() == true then --QUEST_BOARD.ACCEPTED_QUEST == true then
        self.new_quest:Disable()
        --self.new_quest:SetText(STRINGS_QB.LOOK_FOR_QUESTS_ACCEPTED)
        self.new_quest.text:SetAutoSizingString(STRINGS_QB.LOOK_FOR_QUESTS_ACCEPTED,290)
    end
    if GetTableSize(self.owner.replica.quest_component._quests) >= self.owner.replica.quest_component._max_amount_of_quests:value() then
        self.new_quest:Disable()
        --self.new_quest:SetText(STRINGS_QB.LOOK_FOR_QUESTS_MAX)
        self.new_quest.text:SetAutoSizingString(STRINGS_QB.LOOK_FOR_QUESTS_MAX,290)
    end


    self.level_rewards = self.root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.level_rewards:SetPosition(button_x, 70, 0)
    self.level_rewards:SetTextSize(30)
    self.level_rewards:SetText(STRINGS_QB.OBTAIN_LEVEL_REWARDS)
    self.level_rewards:SetOnClick(
        function()
            self:CheckLevelRewards()
            self.root:Hide()
        end)

    local function CanCreateQuests(user)
        if TheNet:GetIsServerAdmin() or QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[user.userid] == true then
            return true
        end
    end
    button_amount = button_amount + 1
    table.insert(buttons,"level_rewards")

    if (QUEST_COMPONENT.CUSTOM_QUESTS == 1 or self.owner.userid == "KU_7veFKyHP"
            or (QUEST_COMPONENT.CUSTOM_QUESTS == 2 and TheNet:GetIsServerAdmin())
            or (QUEST_COMPONENT.CUSTOM_QUESTS == 3 and CanCreateQuests(self.owner))) then
        self.create_new_quest = self.root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.create_new_quest:SetPosition(button_x, -30, 0)
        self.create_new_quest:SetTextSize(30)
        self.create_new_quest:SetText(STRINGS_QB.CREATE_NEW_QUESTS)
        self.create_new_quest:SetOnClick(
            function()
                self:CreateNewQuest()
                self.root:Hide()
            end)
        button_amount = button_amount + 1
        table.insert(buttons,"create_new_quest")
    end


    if next(QUEST_COMPONENT.OWN_QUESTS) ~= nil and (QUEST_COMPONENT.MANAGE_CUSTOM_QUESTS == 0 or self.owner.userid == "KU_7veFKyHP" or (QUEST_COMPONENT.MANAGE_CUSTOM_QUESTS == 1 and TheNet:GetIsServerAdmin())) then
        self.check_custom_quests = self.root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.check_custom_quests:SetPosition(300, 170, 0)
        self.check_custom_quests:SetTextSize(30)
        self.check_custom_quests.text:SetAutoSizingString(STRINGS_QB.MANAGE_QUESTS,290)
        self.check_custom_quests.text:Show()
        self.check_custom_quests:SetOnClick(function()
            self:ShowCustomQuests()
            self.root:Hide()
        end)
        --self.check_custom_quests:SetScale(0.65)
        --self.check_custom_quests:SetHoverText(STRINGS_QB.MANAGE_QUESTS)
        --[[self.check_custom_quests_img = self.check_custom_quests:AddChild(Image("images/request_quest.xml","request_quest.tex"))
        self.check_custom_quests_img:SetPosition(0,0)
        self.check_custom_quests_img:SetScale(1)]]
        button_amount = button_amount + 1
        table.insert(buttons,"check_custom_quests")
    end

    for i = 1,#buttons do
        if button_positions[button_amount] then
            if button_positions[button_amount][i] then
                if self[buttons[i]] then
                    self[buttons[i]]:SetPosition(unpack(button_positions[button_amount][i]))
                end
            end
        end
    end

    self.cancel_button = self.proot:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.cancel_button:SetPosition(415, 310, 0)
    self.cancel_button:SetScale(1.3)
    self.cancel_button:SetOnClick(function()
        self:OnClose()
    end)
    self.cancel_button:SetHoverText(STRINGS_QB.CLOSE)
    self.cancel_button:SetImageNormalColour(UICOLOURS.RED)

    self.list_root = self.proot:AddChild(Widget("list_root"))
    self.list_root:SetVAnchor(ANCHOR_MIDDLE)
    self.list_root:SetHAnchor(ANCHOR_MIDDLE)
    self.list_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    --self.list_root:SetPosition(210, -35)


end)

function Quest_Board_Widget:ShowNewQuests()
    if self.owner.replica.quest_component == nil then print("[Quest System] No Quest_Component") return end

    self.root2 = self.bg3:AddChild(Widget("root"))

    local possible_quests = self.owner.replica.quest_component:GetPossibleQuests()

    for k,v in ipairs(possible_quests) do
        local name = v.name
        if v ~= nil and QUESTS[name] ~= nil then
            local quest = deepcopy(QUESTS[name])
            devprint("Quest_Board_Widget:ShowNewQuests",quest,name,quest.variable_fn)
            if quest.variable_fn then
                devdumptable(quest.variable_fn(self.owner,quest,v.custom_vars))
            end
            quest = quest.variable_fn and quest.variable_fn(self.owner,quest,v.custom_vars) or quest
            quest.scale = quest.scale or {}
            local child_name = "_quest_"..k
            self[child_name] = self.root2:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
            self[child_name]:SetPosition(0, 270 - k*100, 0)
            self[child_name]:SetTextSize(30)
            self[child_name]:SetText("")
            self[child_name].image:SetTint(unpack(colour_difficulty[quest.difficulty]))

            quest.scale = quest.scale or {}
            local title =  GetQuestString(quest.overridename or name,"NAME",unpack(quest.scale))
            self[child_name].text:SetAutoSizingString(title ~= "" and title or quest.name or "No Title found",290)
            self[child_name].text:SetPosition(0,10)

             self[child_name]:SetOnClick(function()
                self:ShowQuestDetails(quest,name)
                self.back_button:Hide()
            end)

            self.difficulty = {}
            local difficulty = quest.difficulty and quest.difficulty < 6 and quest.difficulty > 0 and quest.difficulty or 1
            for count = 1,quest.difficulty do
                self.difficulty["star"..tostring(count)] = self.root2:AddChild(Image("images/global_redux.xml","star_checked.tex"))
                self.difficulty["star"..tostring(count)]:SetPosition(0 - 75 + count * 25, 255 - k*100, 0)
                self.difficulty["star"..tostring(count)]:SetScale(0.5)
                self.difficulty["star"..tostring(count)]:SetTint(1,1,1,1)--unpack(colour_difficulty[difficulty]))
                self.difficulty["star"..tostring(count)]:SetClickable(false)
            end

            for count = quest.difficulty + 1,5 do
                self.difficulty["star"..tostring(count)] = self.root2:AddChild(Image("images/global_redux.xml","star_uncheck.tex"))
                self.difficulty["star"..tostring(count)]:SetPosition(0 - 75 + count * 25, 255 - k*100, 0)
                self.difficulty["star"..tostring(count)]:SetScale(0.5)
                self.difficulty["star"..tostring(count)]:SetTint(1,1,1,1)--unpack(colour_difficulty[difficulty]))
                self.difficulty["star"..tostring(count)]:SetClickable(false)
            end
        end
    end

    self.back_button = self.root2:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
    self.back_button:SetPosition(-410, -160, 0)
    self.back_button:SetOnClick(
        function()
            self.root2:Hide()
            self.root:Show()
            if self.show_quest and self.show_quest.shown == true then
                self.show_quest:Kill()
            end
        end)

end

function Quest_Board_Widget:ShowQuestDetails(quest,name)
    devprint(quest,name)
    self.show_quest = self.proot:AddChild(Widget("show_quest"))
    self._show_quest = self.show_quest:AddChild(Image("images/quest_log_page2.xml","quest_log_page2.tex"))
    self._show_quest:SetTint(1,1,1,1)
    self._show_quest:SetPosition(30,100)
    self._show_quest:SetScale(1.4,1.1)

    self.__show_quest = self.show_quest:AddChild(Text(NEWFONT_OUTLINE, 40))
    local title =  GetQuestString(quest.overridename or name,"NAME",unpack(quest.scale))
    self.__show_quest:SetString(title ~= "" and title or quest.name or STRINGS_QB.NO_NAME)
    self.__show_quest:SetPosition(0, 250)
    self.__show_quest:SetScale(1,1)
    --self._show_quest:SetRegionSize(175, 350)
    self.__show_quest:EnableWordWrap(true)
    self.__show_quest:EnableWhitespaceWrap(true)

    self.__show_quest_divider = self.show_quest:AddChild(Image("images/quagmire_recipebook.xml","quagmire_recipe_line_long.tex"))
    self.__show_quest_divider:SetPosition(0, 225)
    self.__show_quest_divider:SetScale(0.5,1)

    if quest.quest_line then
      self.quest_line = self.show_quest:AddChild(Image("images/hud.xml","tab_researchable_off.tex"))
      self.quest_line:SetPosition(-310,225)
      --self.quest_line:SetTint(1,0,0,1)
      self.quest_line:SetScale(0.4,0.4)
      self.quest_line:SetHoverText(STRINGS_QL.QUEST_LINE)

      self.quest_line2 = self.show_quest:AddChild(Image("images/hud.xml","tab_researchable_off.tex"))
      self.quest_line2:SetPosition(290,225)
      --self.quest_line2:SetTint(1,0,0,1)
      self.quest_line2:SetScale(0.4,0.4)
      self.quest_line2:SetHoverText(STRINGS_QL.QUEST_LINE)
    end

    self.__show_quest.difficulty = {}
    local difficulty = quest.difficulty and quest.difficulty < 6 and quest.difficulty > 0 and quest.difficulty or 1
    for count = 1,difficulty do
      self.__show_quest.difficulty["star"..tostring(count)] = self.show_quest:AddChild(Image("images/global_redux.xml","star_checked.tex"))
      self.__show_quest.difficulty["star"..tostring(count)]:SetPosition( - 75 + count * 25,  200)
      self.__show_quest.difficulty["star"..tostring(count)]:SetScale( 0.5)
      self.__show_quest.difficulty["star"..tostring(count)]:SetTint(unpack(colour_difficulty[difficulty]))
    end
    for count = difficulty + 1,5 do
      self.__show_quest.difficulty["star"..tostring(count)] = self.show_quest:AddChild(Image("images/global_redux.xml","star_uncheck.tex"))
      self.__show_quest.difficulty["star"..tostring(count)]:SetPosition( - 75 + count * 25, 200)
      self.__show_quest.difficulty["star"..tostring(count)]:SetScale(0.5)
      self.__show_quest.difficulty["star"..tostring(count)]:SetTint(unpack(colour_difficulty[difficulty]))
    end

    self.__show_quest2 = self.show_quest:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
    self.__show_quest2:SetMultilineTruncatedString(quest.description,10,360,100,nil,true)
    local w,h = self.__show_quest2:GetRegionSize()
    self.__show_quest2:SetPosition(-110, 180 - 0.5*h)

    local progress_x = 150
    local progress_y = 0

    self.__show_quest2.bg_progress = self.show_quest:AddChild(Image("images/plantregistry.xml","plant_cell.tex"))
    self.__show_quest2.bg_progress:SetPosition(progress_x, progress_y + 70)
    self.__show_quest2.bg_progress:SetScale(1.1)

    self.__show_quest2.progress_title = self.show_quest:AddChild(Text(BUTTONFONT, 20,STRINGS_QB.REQUIREMENTS,UICOLOURS.BLACK))
    self.__show_quest2.progress_title:SetPosition(progress_x, progress_y + 175)
    self.__show_quest2.progress_title:SetRegionSize(165, 350)
    self.__show_quest2.progress_title:EnableWordWrap(true)
    self.__show_quest2.progress_title:EnableWhitespaceWrap(true)

    self.__show_quest2.progress = self.show_quest:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
    self.__show_quest2.progress:SetPosition(progress_x, progress_y + 125)
    self.__show_quest2.progress:SetString(tostring(quest.amount))
    self.__show_quest2.progress:SetScale(1)
    self.__show_quest2.progress:SetRegionSize(100, 350)
    self.__show_quest2.progress:EnableWordWrap(true)
    self.__show_quest2.progress:EnableWhitespaceWrap(true)

    self.__show_quest2.victim = self.show_quest:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
    self.__show_quest2.victim:SetPosition(progress_x, progress_y + 90)
    self.__show_quest2.victim:SetString(quest.victim and STRINGS.NAMES[string.upper(quest.victim)] or quest.counter_name or "Not Defined")
    self.__show_quest2.victim:SetScale(1)
    self.__show_quest2.victim:SetRegionSize(125, 350)
    self.__show_quest2.victim:EnableWordWrap(true)
    self.__show_quest2.victim:EnableWhitespaceWrap(true)

    local target_atlas = quest.tex and GetInventoryItemAtlas(quest.tex,true) or quest.atlas or "images/avatars.xml"
    self.__show_quest2.image = self.show_quest:AddChild(Image(target_atlas, quest.tex or "avatar_unknown.tex"))
    self.__show_quest2.image:SetPosition(progress_x, progress_y + 10)
    if quest.start_fn and type(quest.start_fn) == "string" and string.find(quest.start_fn,"start_fn_") then
        local fn = string.gsub(quest.start_fn,"start_fn_","")
        local text = QUEST_BOARD.PREFABS_MOBS[fn] and QUEST_BOARD.PREFABS_MOBS[fn].text
        if text and type(text) == "string" then
            local new_text = string.gsub(text," x "," "..quest.amount.." ")
            self.__show_quest2.image:SetHoverText(new_text)
        end
    elseif quest.hovertext ~= nil then
        self.__show_quest2.image:SetHoverText(quest.hovertext)
    elseif quest.victim and QUEST_BOARD.PREFABS_MOBS[quest.victim] then
        local text = QUEST_BOARD.PREFABS_MOBS[quest.victim].hovertext or ""
        local new_text = string.gsub(text," x "," "..quest.amount.." ")
        local new_text2 = string.split(new_text,"/")
        local new_text3 = new_text2[1]..(STRINGS.NAMES[string.upper(new_text2[2])] or "")
        self.__show_quest2.image:SetHoverText(new_text3)
    end

    self.__show_quest2.bg_rewards = self.show_quest:AddChild(Image("images/plantregistry.xml","plant_cell.tex"))
    self.__show_quest2.bg_rewards:SetPosition(progress_x + 140, progress_y + 70)
    self.__show_quest2.bg_rewards:SetScale(1.1)

    self.__show_quest2.rewards_title = self.show_quest:AddChild(Text(BUTTONFONT, 20,STRINGS_QB.REWARDS,UICOLOURS.BLACK))
    self.__show_quest2.rewards_title:SetPosition(progress_x + 140, progress_y + 175)
    self.__show_quest2.rewards_title:SetRegionSize(100, 350)
    self.__show_quest2.rewards_title:EnableWordWrap(true)
    self.__show_quest2.rewards_title:EnableWhitespaceWrap(true)

    self.__show_quest2.rewards = self:ShowRewards(quest)
    self.__show_quest2.rewards:SetPosition(progress_x + 140, progress_y + 30)
    self.__show_quest2.rewards:SetScale(0.7)

    self.accept_quest = self.show_quest:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.accept_quest:SetPosition(0, -100, 0)
    self.accept_quest:SetTextSize(30)
    self.accept_quest:SetScale(0.8)
    self.accept_quest:SetText(STRINGS_QB.ACCEPT_QUEST)
    self.accept_quest:SetOnClick(function()
            self.root2:Hide()
            self.root:Show()
            if self.show_quest and self.show_quest.shown == true then
              self.show_quest:Kill()
            end
            SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["AcceptQuest"],name)
            SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["HasAcceptedQuest"])
            self.new_quest:Disable()
            self.new_quest:SetText(STRINGS_QB.ALREADY_ACCEPT_QUEST)
        end)


    self.__show_quest2.button_close = self.show_quest:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.__show_quest2.button_close:SetPosition( 300, 300)
    self.__show_quest2.button_close:SetScale(1)
    self.__show_quest2.button_close:SetOnClick(function()
      if self.show_quest and self.show_quest.shown == true then
        self.show_quest:Kill()
      end
      self.show_quest:Kill()
      self.back_button:Show()
    end)
    self.__show_quest2.button_close:SetHoverText(STRINGS_QB.CLOSE)
    self.__show_quest2.button_close:SetImageNormalColour(UICOLOURS.RED)
end

function Quest_Board_Widget:ShowRewards(tab)

    local show_rewards = self.show_quest:AddChild(Widget("ROOT"))
    --[[self.__show_rewards = show_rewards:AddChild(Image("images/quest_log_page.xml","quest_log_page.tex"))
    self.__show_rewards:SetTint(1,1,1,1)
    self.__show_rewards:SetPosition(0,100)]]
  --self.__show_rewards:SetScale(0.5)

    local invimages = {}
    local num = 0 
    for k,v in pairs(tab.rewards) do
        num = num + 1
        local str1 = GetRewardString(k)
        local rew_num = (type(v) == "string" and v) or (v and tostring(math.ceil(v * TUNING.QUEST_COMPONENT.REWARDS_AMOUNT)) or 0)
        if str1 and string.find(str1," x ") then
            str1 = string.gsub(str1," x "," "..rew_num.." ")
        end
        local str  = str1 or tostring(STRINGS.NAMES[string.upper(k)] or k or "?")..(tostring(rew_num) ~= "" and ": "..tostring(rew_num) or "")

        --[[invimages["text"..num] = show_rewards:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
        invimages["text"..num]:SetAutoSizingString(str,200)
        invimages["text"..num]:SetPosition(-20, 210 - num*50)
        invimages["text"..num]:SetScale(1,1)]]
        --invimages["text"..num]:SetRegionSize(175, 350)

        invimages["_"..num] = show_rewards:AddChild(Image("images/hud.xml", "inv_slot.tex"))
        local x,y = -35 + (num-1)%2 * 70,140 - math.floor((num-1)/2)*70
        invimages["_"..num]:SetPosition(x,y)
        invimages["_"..num]:SetScale(0.8,0.8)
        local tex = tab["reward_"..k.."_tex"] or (TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k] and TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k][3]) or k..".tex"
        local atlas = tab["reward_"..k.."_atlas"] or (TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k] and TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[k][4]) or GetInventoryItemAtlas(tex,true)

        if atlas then
            invimages[num] = show_rewards:AddChild(Image(atlas,tex))
            invimages[num]:SetPosition(x,y)
            invimages[num]:SetScale(0.8,0.8)
            invimages[num]:SetHoverText(str)
        end
    end

    --[[self._show_rewards = show_rewards:AddChild(Text(NEWFONT_OUTLINE, 40,nil,UICOLOURS.BLACK))
    self._show_rewards:SetString(STRINGS_QB.REWARDS..":\n")
    self._show_rewards:SetPosition(0, 210)
    self._show_rewards:SetScale(1,1)
    --self._show_rewards:SetRegionSize(175, 350)
    self._show_rewards:EnableWordWrap(true)
    self._show_rewards:EnableWhitespaceWrap(true)]]

    --[[self.__show_rewards_divider = show_rewards:AddChild(Image("images/quagmire_recipebook.xml","quagmire_recipe_line.tex"))
    self.__show_rewards_divider:SetPosition(0, 195)
    self.__show_rewards_divider:SetScale(0.5,1)]]

    self.point = show_rewards:AddChild(Text(BUTTONFONT, 25,nil,UICOLOURS.BLACK))
    self.point:SetAutoSizingString(STRINGS_QB.POINTS..": "..(tab.points or 0),200)
    self.point:SetPosition(30, -80, 0)

    --[[self.close_rewards = self.show_rewards:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_rewards:SetPosition( 170, 300)
    self.close_rewards:SetScale(1)
    self.close_rewards:SetOnClick(function()
        if self.show_rewards and self.show_rewards.shown == true then
            self.show_rewards:Kill()
        end
        self.show_quest:Show()
    end)
    self.close_rewards:SetHoverText(STRINGS_QB.CLOSE)
    self.close_rewards:SetImageNormalColour(UICOLOURS.RED)]]

    return show_rewards

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

local function AskIfDelete(self,name)
    local button1 = {
    text = STRINGS_QB.YES,
    cb = function()
        SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["DeleteQuest"],name)
        TUNING.QUEST_COMPONENT.OWN_QUESTS[name] = nil
        self.root5:Kill()
        if next(TUNING.QUEST_COMPONENT.OWN_QUESTS) ~= nil then
            self:ShowCustomQuests()
        else
            self.cancel_button:Show()
        end
    end,
    }
    local button2 = {
    text = STRINGS_QB.NO,
    cb = function()
        self.askquestion:Kill()
    end,
    }

    self.askquestion = self.root5:AddChild(Templates_R.CurlyWindow(350,225,nil,{button1,button2},nil,string.format(STRINGS_QB.ASK_REMOVE_QUEST,name)))
    self.askquestion.body:SetSize(40)
    self.askquestion.body:SetPosition(0, 70)
end

function Quest_Board_Widget:ShowCustomQuests()
    self.root5 = self.bg3:AddChild(Widget("root5"))
    local list_elements = {}
    local custom_quests = TUNING.QUEST_COMPONENT.OWN_QUESTS
    local counter = 0
    for name,quest in spairs(custom_quests, function(t,a,b) return string.lower(tostring(a)) < string.lower(tostring(b)) end) do
        counter = counter + 1
        local quest_root = Widget("quest_root")
        quest_root:SetVAnchor(ANCHOR_MIDDLE)
        quest_root:SetHAnchor(ANCHOR_MIDDLE)
        quest_root:SetPosition(0, 0)
        local bg = quest_root:AddChild(Widget("bg"))
        bg.image = bg:AddChild(Image("images/frontend_redux.xml","achievement_backing_selected.tex"))
        bg.image:SetScale(0.5,1.4)

        bg.number = bg:AddChild(Text(UIFONT, 40,counter)) 
        bg.number:SetPosition(-300,0)

        bg.title = bg:AddChild(Text(UIFONT, 30,quest.name)) 
        bg.title:SetPosition(-138, 39)
        local target_atlas = quest.tex and GetInventoryItemAtlas(quest.tex,true) or quest.atlas or "images/avatars.xml"
        bg.victim = bg:AddChild(Image(target_atlas, quest.tex or "avatar_unknown.tex"))
        bg.victim:SetPosition(50, 10)
        if quest.start_fn and type(quest.start_fn) == "string" and string.find(quest.start_fn,"start_fn_") then
            local fn = string.gsub(quest.start_fn,"start_fn_","")
            local text = QUEST_BOARD.PREFABS_MOBS[fn] and QUEST_BOARD.PREFABS_MOBS[fn].text
            if text and type(text) == "string" then
                local new_text = string.gsub(text," x "," "..quest.amount.." ")
                bg.victim:SetHoverText(new_text)
            end
        elseif quest.hovertext ~= nil then
            bg.victim:SetHoverText(quest.hovertext)
        elseif quest.victim and QUEST_BOARD.PREFABS_MOBS[quest.victim] then
            local text = QUEST_BOARD.PREFABS_MOBS[quest.victim].hovertext or ""
            local new_text = string.gsub(text," x "," "..quest.amount.." ")
            local new_text2 = string.split(new_text,"/")
            local new_text3 = new_text2[1]..STRINGS.NAMES[string.upper(new_text2[2])]
            bg.victim:SetHoverText(new_text3)
        end
        bg.victim_name = bg:AddChild(Text(NEWFONT_OUTLINE, 25))
        bg.victim_name:SetPosition(50, -30)
        bg.victim_name:SetAutoSizingString(quest.counter_name or (quest.victim and STRINGS.NAMES[string.upper(quest.victim)]) or "Not Defined",100)
        bg.rewards = {}
        local num = 0
        for prefab,amount in pairs(quest.rewards) do
            local reward
            local str1 = GetRewardString(prefab,amount)
            local rew_num = (type(amount) == "string" and amount) or (amount and tostring(math.ceil(amount * TUNING.QUEST_COMPONENT.REWARDS_AMOUNT)) or 0)
            if str1 and string.find(str1," x ") then
                str1 = string.gsub(str1," x "," "..rew_num.." ")
            end
            local str  = str1 or tostring(STRINGS.NAMES[string.upper(prefab)] or prefab or "?")..(tostring(rew_num) ~= "" and ": "..tostring(rew_num) or "")
            local tex = TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[prefab] and TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[prefab][3] or prefab..".tex"
            local atlas = TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[prefab] and TUNING.QUEST_COMPONENT.CUSTOM_QUEST_END_FUNCTIONS[prefab][4] or GetInventoryItemAtlas(tex,true)
            if atlas then
                reward = bg:AddChild(Image(atlas,tex))
                local x = 150 + (num%3)*30
                local y = -30 - 30*(math.floor(num/3))
                reward:SetPosition(x,y)
                reward:SetScale(0.5,0.5)
                reward:SetHoverText(str)
            else
                reward = bg:AddChild(Text(UIFONT, 25,"?")) 
                reward:SetPosition(150 + num*30,-30)
                reward:SetHoverText(str)
            end
            table.insert(bg.rewards,reward)
            num = num + 1
        end
        bg.description = bg:AddChild(Text(UIFONT, 20)) 
        bg.description:SetPosition(-138,-12)
        bg.description:SetMultilineTruncatedString(quest.description,4,225,50,true)

        bg.points = bg:AddChild(Text(UIFONT, 25,STRINGS_QB.POINTS..": "..quest.points)) 
        bg.points:SetPosition(180,9)

        bg.edit = bg:AddChild(ImageButton("images/global_redux.xml", "radiobutton_filled_gold_new.tex"))
        bg.edit:SetPosition(195, 40, 0)
        bg.edit:SetScale(0.5)
        bg.edit:SetHoverText(STRINGS_QB.EDIT_QUEST)
        bg.edit:SetOnClick( function()
            self.root5:Kill()
            self:CreateNewQuest()
            self.editing_custom_quest = quest.name

            --Rewards
            local k = 1
            for prefab,amount in pairs(quest.rewards) do
                local reward_tab = STRINGS_QB["REWARD"..k]
                self.new_custom_quest[reward_tab] = prefab
                local text = GetRewardString(prefab,amount) or STRINGS.NAMES[string.upper(prefab)]
                self.new_custom_quest[reward_tab.."_text"] = text
                self["text_button_"..k].button.text:SetAutoSizingString(text,140)
                self.new_custom_quest[reward_tab.." "..STRINGS_QB.AMOUNT] = amount
                self["spinner_rewards_"..k].spinner:SetSelected(amount)
                k = k + 1
            end
            --Add the remaining rewards that are nonexistent as a 0 amount reward
            if k < 4 then
                for i = k, 3 do
                    local reward_tab = STRINGS_QB["REWARD"..i]
                    self.new_custom_quest[reward_tab.." "..STRINGS_QB.AMOUNT] = 0
                    self["spinner_rewards_"..i].spinner:SetSelected(0)
                end
            end
            --Victim
            local victim_text
            local victim_data
            if quest.start_fn and type(quest.start_fn) == "string" and string.find(quest.start_fn,"start_fn_") then
                local fn = string.gsub(quest.start_fn,"start_fn_","")
                local victim = QUEST_BOARD.PREFABS_MOBS[fn]
                victim_text = victim.text
                victim_data = victim.data
            elseif quest.victim then
                victim_text = STRINGS.NAMES[string.upper(quest.victim)]
                victim_data = quest.victim
            end
            self.new_custom_quest[STRINGS_QB.VICTIM] = victim_data
            self["text_button_5"].button.text:SetAutoSizingString(victim_text,230)
            --Difficulty
            self.new_custom_quest[STRINGS_QB.DIFFICULTY] = quest.difficulty
            self["spinner_4"].spinner:SetSelected(quest.difficulty)
            --Amount
            self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS] = quest.amount
            self["spinner_6"].textbox:SetString(quest.amount)
            --Points
            self.new_custom_quest[STRINGS_QB.POINTS] = quest.points
            self["spinner_7"].textbox:SetString(quest.points)
            --Title
            self.new_custom_quest[STRINGS_QB.TITLE] = quest.name
            self["spinner_rewards_4"].textbox:SetString(quest.name)
            --Description
            self.new_custom_quest.text = quest.description
        end)

        bg.remove = bg:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
        bg.remove:SetPosition(235, 40, 0)
        bg.remove:SetScale(0.8)
        bg.remove:SetHoverText(STRINGS_QB.REMOVE_QUEST)
        bg.remove:SetOnClick( function()
           AskIfDelete(self,name)
        end)
        bg.remove:SetImageNormalColour(UICOLOURS.RED)

        table.insert(list_elements,bg)
    end

    self.list = self.root5:AddChild(ScrollableList(list_elements, 380, 375, 125, 3, nil, nil, nil, nil, nil, -30))
    self.list:SetPosition(150,50)
    self.list:SetScale(0.95)

    self.cancel_button2 = self.root5:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.cancel_button2:SetPosition(415, 285, 0)
    self.cancel_button2:SetScale(1.3)
    self.cancel_button2:SetOnClick(function()
        self.root5:Kill()
        self.root:Show()
        self.cancel_button:Show()
    end)
    self.cancel_button2:SetHoverText(STRINGS_QB.CLOSE)
    self.cancel_button2:SetImageNormalColour(UICOLOURS.RED)
    self.cancel_button:Hide()

    self.back_button = self.root5:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
    self.back_button:SetPosition(-410, -160, 0)
    self.back_button:SetOnClick(function()
        self.root5:Kill()
        self.root:Show()
        self.cancel_button:Show()
    end)
end



function Quest_Board_Widget:CheckLevelRewards()
    devprint("CheckLevelRewards")
    self.root3 = self.bg3:AddChild(Widget("root"))
    self.root3.profileflairs = {}
    local curr_level = self.owner and self.owner.replica.quest_component and self.owner.replica.quest_component._level:value() or 1
    for k,v in ipairs(profile_flairs) do
        if k % 5 == 0 then
            local level_str = "level"..k
            self.root3.profileflairs[level_str] = self.root3:AddChild(ImageButton("images/profileflair.xml",v))
            local posx = k < 51 and -380+((k)*70/5) or k < 101 and -380+((k-50)*70/5) or k < 151 and -380+((k-100)*70/5) or -345+((k-150)*70/5)
            local posy = k < 51 and 200 or k < 101 and 110 or k < 151 and 20 or -70

            self.root3.profileflairs[level_str]:SetPosition(posx, posy, 0)
            self.root3.profileflairs[level_str]:SetScale(.55)
            local str = STRINGS_QB.REWARD_LEVEL.." "..k.."\n"
            for k,v in pairs(QUEST_BOARD.LEVEL_REWARDS[k]) do
                str = str.."\n"..(STRINGS.NAMES[string.upper(k)] or k)..": "..v
            end
            self.root3.profileflairs[level_str]:SetHoverText(str)
            self.root3.profileflairs[level_str]:SetOnClick(function()
                SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["GetLevelRewards"],k)
                Networking_Announcement(STRINGS_QB.ACCEPTED_REWARDS.." "..k.."!")
                self.root3.profileflairs[level_str]:Disable()
                self.root3.profileflairs[level_str].image:SetTint(0.15,0.15,0.15,1)
                end)
            self.root3.profileflairs[level_str]:Disable()
            self.root3.profileflairs[level_str].image:SetTint(0.15,0.15,0.15,1)
            if self.owner.replica.quest_component.accepted_level_rewards[k] == true then
                self.root3.profileflairs[level_str]:Enable()
                self.root3.profileflairs[level_str].image:SetTint(1,1,1,1)
            end

            local level_desc = "level_desc"..k
            self.root3.profileflairs[level_desc] = self.root3:AddChild(Text(NEWFONT_OUTLINE, 20))
            self.root3.profileflairs[level_desc]:SetString(STRINGS_QB.LEVEL.." "..k)
            self.root3.profileflairs[level_desc]:SetPosition(posx, posy-35)
            self.root3.profileflairs[level_desc]:SetScale(1,1)
        end
    end

    self.back_button = self.root3:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
    self.back_button:SetPosition(-410, -160, 0)
    self.back_button:SetOnClick(function()
        self.root3:Hide()
        self.root:Show()
    end)
end


local search_subwords = function( search, str, sub_len )
    local str_len = string.len(str)

    local i = 1
    for i=i,str_len - sub_len + 1 do
        local sub = str:sub( i, i + sub_len - 1 )

        local dist = DamLevDist( search, sub, 2 )
        if dist < 2 then
            return true
        end
    end

    return false
end

local search_match = function( search, str )
    --print("search_match",search,str)
    search = search:gsub(" ", "")
    str = str:gsub(" ", "")

    --Simple find in strings for multi word search
    if string.find( str, search, 1, true ) ~= nil then
        --print("string.find is true",str,search)
        return true
    end
    local sub_len = string.len(search)

    if sub_len > 3 then
        --print("string length more than 3")
        if search_subwords( search, str, sub_len ) then return true end

        --Try again with 1 fewer character
        sub_len = sub_len - 1
        if search_subwords( search, str, sub_len ) then return true end
    end
    --print(search,str, "has no match")

    return false
end


local function AddSearch(self,thin,widget,item_list)
    self.filters = {}
    self.thin_mode = thin

    item_list = item_list or widget.items or {}
    local old_itemlist = {}
    for k,v in ipairs(item_list) do
        old_itemlist[k] = v
    end
    local curr_list = item_list
    local searchbox = Widget("search")
    local box_size = 145
    if self.thin_mode then
        box_size = 120
    end
    local box_height = 40

    searchbox.textbox_root = searchbox:AddChild(Templates_R.StandardSingleLineTextEntry(nil, box_size, box_height))
    searchbox.textbox = searchbox.textbox_root.textbox
    searchbox.textbox:SetTextLengthLimit(16)
    searchbox.textbox:SetForceEdit(true)
    searchbox.textbox:EnableWordWrap(false)
    searchbox.textbox:EnableScrollEditWindow(true)
    searchbox.textbox:SetHelpTextEdit("")
    searchbox.textbox:SetHelpTextApply(STRINGS.UI.WARDROBESCREEN.SEARCH)
    searchbox.textbox:SetTextPrompt(STRINGS.UI.WARDROBESCREEN.SEARCH, UICOLOURS.GREY)
    searchbox.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)

    local function SearchFilter(item_key) 
        local search_str = TrimString(string.upper(searchbox.textbox:GetString()))

        if search_match(search_str, string.upper(item_key)) then
            return true
        end

        return false
    end

    searchbox.textbox.OnTextEntered = function()
        if self.search_delay then
            self.search_delay:Cancel()
            self.search_delay = nil
        end     
        
        searchbox.textbox:SetEditing(true)
        self.entered_string = searchbox.textbox:GetString() --just used for filter on input below, so we can avoid triggering a second refresh
        
        if self.entered_string == "" then
            --Early out
            widget:SetList(old_itemlist)
            return true
        end

        curr_list = {}
        for k,v in ipairs(old_itemlist) do
            curr_list[k] = v
        end
        local rem_list = {}
        for k,v in pairs(curr_list) do
            if SearchFilter(v.text) == false then
                --print(k,v.text)
                rem_list[k] = v
            end
        end
        for k,v in pairs(rem_list) do
            curr_list[k] = nil
        end
        local count = 0
        local curr_list2 = {}
        for k,v in pairs(curr_list) do
            count = count + 1
            curr_list2[count] = v
        end

        widget:SetList(curr_list2)
    end
    searchbox.textbox.OnTextInputted = function()
        
        if self.search_delay then
            self.search_delay:Cancel()
            self.search_delay = nil
        end

        if self.entered_string ~= searchbox.textbox:GetString() then
            self.search_delay = self.inst:DoTaskInTime(0.5, function()
                searchbox.textbox:OnTextEntered()
            end)
        end
        
    end
     -- If searchbox ends up focused, highlight the textbox so we can tell something is focused.
    searchbox:SetOnGainFocus( function() searchbox.textbox:OnGainFocus() end )
    searchbox:SetOnLoseFocus( function() searchbox.textbox:OnLoseFocus() end )

    searchbox.focus_forward = searchbox.textbox

    self.search_box = searchbox


    return searchbox

end

local function AskIfDelete2(self)
    local button1 = {
    text = STRINGS_QB.YES,
    cb = function()
        devprint("making random quest")
        SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["Make_Random_Quest"])
        --self.askquestion:Kill()
        self.root4:Hide()
        self.root:Show()
        Networking_Announcement(STRINGS_QB.ADDED_SUCCESFULLY.." random quest!")
    end,
    }
    local button2 = {
    text = STRINGS_QB.NO,
    cb = function()
        self.askquestion:Kill()
    end,
    }

    self.askquestion = self.root4:AddChild(Templates_R.CurlyWindow(350,225,nil,{button1,button2},nil,"Add random Quest?"))
    self.askquestion.body:SetSize(40)
    self.askquestion.body:SetPosition(0, 70)
end

function Quest_Board_Widget:CreateNewQuest()


    self.root4 = self.bg3:AddChild(Widget("root"))
    
    for k,v in pairs(spinner_cat) do
        if k ~= 4 then
            local width = v[1] == STRINGS_QB.VICTIM and 230 or 140
            local list_elements = {}
            self["widgets_root_"..k] = self.list_root:AddChild(Widget("widgets_root"))
            self["widgets_root_"..k]:SetPosition(0,0)
            local scroll_bg = self["widgets_root_"..k]:AddChild(Image("images/images_quest_system.xml","scroll_list_bg.tex"))
            scroll_bg:SetPosition(0,0)
            scroll_bg:SetScale(2,1.4)
            scroll_bg:MoveToBack()
            local item_data = {}

            for kk,vv in pairs(v[2]) do
                table.insert(item_data,vv)
            end
            self.item_data = item_data
                
            for count = 1,6 do
                local button_root = self["widgets_root_"..k]:AddChild(Widget("PLAYER_ROOT"))
                button_root:SetVAnchor(ANCHOR_MIDDLE)
                button_root:SetHAnchor(ANCHOR_MIDDLE)
                button_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
                button_root:SetPosition(10, -35)
                local button = button_root:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex",nil,{2.2,1}))
                button:SetPosition(22,5)
                button:SetText(item_data[count].text)
                button:SetTextSize(30)
                --button.text:SetAutoSizingString(item_data[count].text,250)
                button:SetOnClick(function()
                    self.new_custom_quest[v[1]] = item_data[count] and item_data[count].data or nil
                    self.new_custom_quest[v[1].."_text"] = item_data[count] and item_data[count].text or "Empty"
                    self.new_custom_quest[v[1].."_modname"] = item_data[count] and item_data[count].modname
                    self["list"..k]:Hide()
                    self["text_button_"..k].button.text:SetAutoSizingString(item_data[count].text,width)
                    self["widgets_root_"..k]:Hide()
                    self.cancel_button:Show()
                    self.back_button:Show()
                end)
                table.insert(list_elements,button)
            end
            
           local function OnUpdateFn(button,data,index)
                button:SetText(data.text)
                --button.text:SetAutoSizingString(data.text,250)
                button:SetOnClick(function()
                    self.new_custom_quest[v[1]] = data.data
                    self.new_custom_quest[v[1].."_text"] = data.text
                    self.new_custom_quest[v[1].."_modname"] = data.modname
                    self["list"..k]:Hide()
                    self["widgets_root_"..k]:Hide()
                    self["text_button_"..k].button.text:SetAutoSizingString(data.text,width)
                    self.cancel_button:Show()
                    self.back_button:Show()
                end)
            end

            self["list"..k] = self.list_root:AddChild(ScrollableList(item_data, 200, 370, 60, 10, OnUpdateFn, list_elements, 30, nil, nil, 50))
            self["list"..k]:SetPosition(280,30)

            
            local cancel_button = self["list"..k]:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
            cancel_button:SetPosition(180, 250, 0)
            cancel_button:SetScale(1.3)
            cancel_button:SetOnClick(function()
                self["list"..k]:Hide()
                self.cancel_button:Show()
                self.back_button:Show()
                self["widgets_root_"..k]:Hide()
            end)
            cancel_button:SetHoverText(STRINGS_QB.CLOSE)
            cancel_button:SetImageNormalColour(UICOLOURS.RED)
            cancel_button:MoveToBack()
            
            local filterbar = self["list"..k]:AddChild(AddSearch(self,nil,self["list"..k],self.item_data))
            filterbar:SetPosition(-250,245)
            filterbar:SetScale(1.5)

            self["list"..k]:Hide()
            self["widgets_root_"..k]:Hide() 

      
            local spinner_bg = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
            spinner_bg:SetSize(360, 40)
            spinner_bg:SetPosition(-165, 230-k*35, 0)

            local width_button = 150
            local offset = 0
            if k == 5 then 
                width_button = 250
                offset = -50
            end
            self["text_button_"..k] = spinner_bg:AddChild(Templates_R.LabelButton(function() 
                self["list"..k]:Show() 
                self.cancel_button:Hide()
                self.back_button:Hide()
                self["widgets_root_"..k]:Show() 

            end,
            v[1],"Random",150,width_button,30,30,CHATFONT,nil,offset))
            self["text_button_"..k]:SetPosition(0,0)
            if k == 5 then
                self["text_button_"..k].label:Nudge(Vector3(20,0,0))
            end
            if self.new_custom_quest[v[1]] == nil then
                self.new_custom_quest[v[1]] = "random"
            end
            if self.new_custom_quest[v[1].."_text"] then
                self["text_button_"..k].button.text:SetAutoSizingString(self.new_custom_quest[v[1].."_text"],width)
            end
        end
    end


    local spinner_bg = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
    spinner_bg:SetSize(360, 40)
    spinner_bg:SetPosition(-165, 230-4*35, 0)
    self["spinner_4"] = self.root4:AddChild(Templates_R.LabelSpinner(STRINGS_QB.DIFFICULTY,QUEST_BOARD.NUMBERS["1_5"],150,150,30,30,nil,nil,nil))
    self["spinner_4"]:SetPosition(-165, 230-4*35, 0)
    self["spinner_4"].spinner:SetSelected(1)
    if self.new_custom_quest[STRINGS_QB.DIFFICULTY] then
        self["spinner_4"].spinner:SetSelected(self.new_custom_quest[STRINGS_QB.DIFFICULTY])
    else
        self.new_custom_quest[STRINGS_QB.DIFFICULTY] = self["spinner_4"].spinner:GetSelected().data
    end
    
    self["spinner_4"].spinner.OnChanged = function(_,data)
        self.new_custom_quest[STRINGS_QB.DIFFICULTY] = data
    end
    

    for k,v in ipairs(spinner_rewards) do
        local spinner_bg = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
        spinner_bg:SetSize(330, 40)
        spinner_bg:SetPosition(190, 230-k*35, 0)
        self["spinner_rewards_"..k] = self.root4:AddChild(Templates_R.LabelSpinner(v[1],v[2],nil,nil,nil,nil,nil,nil,nil))
        self["spinner_rewards_"..k]:SetPosition(170, 230-k*35, 0)
        self["spinner_rewards_"..k].spinner:SetSelected(1)
        if self.new_custom_quest[v[1]] then
            self["spinner_rewards_"..k].spinner:SetSelected(self.new_custom_quest[v[1]])
        else
            self.new_custom_quest[v[1]] = self["spinner_rewards_"..k].spinner:GetSelected().data
        end
        
        self["spinner_rewards_"..k].spinner.OnChanged = function(_,data)
            self.new_custom_quest[v[1]] = data
        end
    end

    local spinner_bg1 = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
    spinner_bg1:SetSize(360, 40)
    spinner_bg1:SetPosition(-165, 230-6*35, 0)
    self["spinner_6"] = self.root4:AddChild(Templates_R.LabelTextbox(STRINGS_QB.AMOUNT_OF_KILLS,"1",150,150,30,30,nil,nil,nil))
    self["spinner_6"]:SetPosition(-165, 230-6*35, 0)
    self["spinner_6"].label:SetAutoSizingString(STRINGS_QB.AMOUNT_OF_KILLS,150)
    self["spinner_6"].label:Nudge(Vector3(45,0,0))
    self["spinner_6"].textbox:SetTextLengthLimit(6)
    self["spinner_6"].textbox:SetCharacterFilter("1234567890")
    if self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS] then
        self["spinner_6"].textbox:SetString(self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS])
    else
        self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS] = 1
    end
    
    local old_ontextinput6 = self["spinner_6"].textbox.OnTextInput
    self["spinner_6"].textbox.OnTextInput = function(textbox,text,...)
        local ret = {old_ontextinput6(textbox,text,...)}
        self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS] = textbox:GetString()
        return unpack(ret)
    end


    local spinner_bg2 = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
    spinner_bg2:SetSize(360, 40)
    spinner_bg2:SetPosition(-165, 230-7*35, 0)
    self["spinner_7"] = self.root4:AddChild(Templates_R.LabelTextbox(STRINGS_QB.POINTS,"10",150,150,30,30,nil,nil,nil))
    self["spinner_7"]:SetPosition(-165, 230-7*35, 0)
    self["spinner_7"].textbox:SetTextLengthLimit(6)
    self["spinner_7"].textbox:SetCharacterFilter("1234567890")
    self["spinner_7"].label:SetHAlign(ANCHOR_RIGHT)
    if self.new_custom_quest[STRINGS_QB.POINTS] then
        self["spinner_7"].textbox:SetString(self.new_custom_quest[STRINGS_QB.POINTS])
    else
        self.new_custom_quest[STRINGS_QB.POINTS] = 10
    end
    
    local old_ontextinput7 = self["spinner_7"].textbox.OnTextInput
    self["spinner_7"].textbox.OnTextInput = function(textbox,text,...)
        local ret = {old_ontextinput7(textbox,text,...)}
        self.new_custom_quest[STRINGS_QB.POINTS] = textbox:GetString()
        return unpack(ret)
    end

    local spinner_bg3 = self.root4:AddChild(Image("images/global_redux.xml", "spinner_background_normal.tex"))
    spinner_bg3:SetSize(330, 40)
    spinner_bg3:SetPosition(190, 230-4*35, 0)
    self["spinner_rewards_4"] = self.root4:AddChild(Templates_R.LabelTextbox(STRINGS_QB.TITLE,"",150,250,30,10,nil,nil,nil))
    self["spinner_rewards_4"]:SetPosition(140, 230-4*35, 0)
    self["spinner_rewards_4"].textbox:SetTextLengthLimit(50)
    if self.new_custom_quest[STRINGS_QB.TITLE] then
        self["spinner_rewards_4"].textbox:SetString(self.new_custom_quest[STRINGS_QB.TITLE])
    end
    local old_ontextinput8 = self["spinner_rewards_4"].textbox.OnTextInput
    self["spinner_rewards_4"].textbox.OnTextInput = function(textbox,text,...)
        local ret = {old_ontextinput8(textbox,text,...)}
        self.new_custom_quest[STRINGS_QB.TITLE] = textbox:GetString()
        return unpack(ret)
    end

    self.write_description = self.root4:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.write_description:SetPosition(190, 20, 0)
    self.write_description:SetTextSize(30)
    self.write_description:SetText(STRINGS_QB.WRITE_DESCRIPTION)
    self.write_description:SetScale(0.7)
    self.write_description:SetOnClick(function()
        self:WriteDescription()
    end)


    self.add_quest = self.root4:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.add_quest:SetPosition(0, -80, 0)
    self.add_quest:SetTextSize(30)
    self.add_quest:SetText(STRINGS_QB.ADD_QUEST)
    self.add_quest:SetScale(0.8)
    self.add_quest:SetOnClick(function()
        if not self.editing_custom_quest then
            for k,v in pairs(QUESTS) do
                if k == self.new_custom_quest[STRINGS_QB.TITLE] then
                    self.add_quest:SetText(STRINGS_QB.QUEST_EXISTS)
                    self.inst:DoTaskInTime(3,function()
                        self.add_quest:SetText(STRINGS_QB.ADD_QUEST)
                    end)
                    return
                end
            end
        end
        self:AddQuestVerify()
    end)
    self.add_quest.text:SetAutoSizingString(STRINGS_QB.ADD_QUEST,275)

    if TUNING.QUEST_COMPONENT.DEV_MODE then
        self.add_random_quest = self.root4:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
        self.add_random_quest:SetPosition(0, -150)
        self.add_random_quest:SetTextSize(30)
        self.add_random_quest:SetText("Add Random Quest")
        self.add_random_quest:SetScale(0.8)
        self.add_random_quest:SetOnClick(function()
            AskIfDelete2(self)
        end)
        self.add_random_quest.text:SetAutoSizingString("Add Random Quest",275)
    end


    self.back_button = self.root4:AddChild(ImageButton("images/ui.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
    self.back_button:SetPosition(-410, -160, 0)
    self.back_button:SetOnClick(function()
        self.root4:Hide()
        self.list1:Hide()
        self.list2:Hide()
        self.list3:Hide()
        self.list5:Hide()
        if self.editing_custom_quest then
            --Set all edited values back  to nil
            self.editing_custom_quest = nil
            self.new_custom_quest[STRINGS_QB.DIFFICULTY] = nil
            self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS] = nil
            self.new_custom_quest[STRINGS_QB.POINTS] = nil
            self.new_custom_quest[STRINGS_QB.TITLE] = nil
            self.new_custom_quest.text = ""
            for k,v in pairs(spinner_cat) do
                self.new_custom_quest[v[1]] = nil
                self.new_custom_quest[v[1].."_text"] = nil
                self.new_custom_quest[v[1].."_modname"] = nil
                if k < 4 then
                    self.new_custom_quest[v[1].." "..STRINGS_QB.AMOUNT] = 1
                end
            end
            self:ShowCustomQuests()
            return
        end
        self.root:Show()
    end)
end


function Quest_Board_Widget:WriteDescription()
    self.desc_edit_bg = self.root4:AddChild(Image("images/lavaarena_unlocks.xml","unlock_bg.tex"))
    self.desc_edit_bg:SetPosition(0,0,0)
    self.desc_edit_bg:SetScale(0.7)

    self.desc_edit = self.root4:AddChild(TextEdit( DEFAULTFONT,  30, "", UICOLOURS.BLACK ) )

    self.desc_edit:EnableWordWrap(true)
    self.desc_edit:EnableScrollEditWindow(false)
    self.desc_edit:EnableWhitespaceWrap(true)
    self.desc_edit:EnableRegionSizeLimit(true)
    self.desc_edit:SetForceEdit(true)
    self.desc_edit:SetAllowNewline(true)

    self.desc_edit.edit_text_color = {1, 1, 1, 1}
    self.desc_edit.idle_text_color = {1, 1, 1, 1}
    self.desc_edit:SetEditCursorColour(1, 1, 1, 1)
    self.desc_edit:SetPosition(0, 0, 0)
    self.desc_edit:SetRegionSize(780, 425)
    self.desc_edit:SetHAlign(ANCHOR_LEFT)
    self.desc_edit:SetVAlign(ANCHOR_TOP)
    self.desc_edit:SetPassControlToScreen(CONTROL_CANCEL, true)
    self.desc_edit:SetHelpTextEdit("")
    self.desc_edit:SetString(self.new_custom_quest.text or "")

    self.save_desc = self.root4:AddChild(TextButton())
    self.save_desc:SetPosition(0, -250, 0)
    self.save_desc:SetTextSize(30)
    self.save_desc:SetScale(1,1)
    self.save_desc:SetText(STRINGS_QB.SAVE_DESCRIPTION)
    self.save_desc:SetOnClick(
        function()
            local txt = self.desc_edit:GetString() or ""
            self.new_custom_quest.text = txt
            self.save_desc:Hide()
            self.desc_edit_bg:Hide()
            self.desc_edit:Hide()
            self.close_desc:Hide()
        end)

    self.close_desc = self.root4:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_desc:SetPosition( 370, 230)
    self.close_desc:SetScale(1)
    self.close_desc:SetOnClick(function()
        self.save_desc:Hide()
        self.desc_edit_bg:Hide()
        self.desc_edit:Hide()
        self.close_desc:Hide()
    end)
    self.close_desc:SetHoverText(STRINGS_QB.CLOSE)
    self.close_desc:SetImageNormalColour(UICOLOURS.RED)
end

local function GetRewardPrefab(prefab,table)
    if prefab == "random" or prefab == "Random" then
        local tab = GetRandomItem(table)
        return tab["data"]
    else
        return prefab
    end
end

function Quest_Board_Widget:AddQuestVerify()
    local button1 = {
    text = STRINGS_QB.YES,
    cb = function()
        if self.editing_custom_quest ~= self.new_custom_quest[STRINGS_QB.TITLE] then
            SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["DeleteQuest"],self.editing_custom_quest)
            TUNING.QUEST_COMPONENT.OWN_QUESTS[self.editing_custom_quest] = nil
        end
        self.editing_custom_quest = nil
        local atlas_path = self.new_custom_quest[STRINGS_QB.VICTIM] and QUEST_BOARD.PREFABS_MOBS[self.new_custom_quest[STRINGS_QB.VICTIM]]
        local victim = GetRewardPrefab(self.new_custom_quest[STRINGS_QB.VICTIM],QUEST_BOARD.PREFABS_MOBS) or "pigman"
        local reward1_amount = self.new_custom_quest[STRINGS_QB.REWARD1.." "..STRINGS_QB.AMOUNT]
        local reward2_amount = self.new_custom_quest[STRINGS_QB.REWARD2.." "..STRINGS_QB.AMOUNT]
        local reward3_amount = self.new_custom_quest[STRINGS_QB.REWARD3.." "..STRINGS_QB.AMOUNT]
        local quest = {
        rewards = {
        [GetRewardPrefab(self.new_custom_quest[STRINGS_QB.REWARD1],QUEST_BOARD.PREFABS_ITEMS)] = reward1_amount ~= 0 and reward1_amount or nil,
        [GetRewardPrefab(self.new_custom_quest[STRINGS_QB.REWARD2],QUEST_BOARD.PREFABS_ITEMS)] = reward2_amount ~= 0 and reward2_amount or nil,
        [GetRewardPrefab(self.new_custom_quest[STRINGS_QB.REWARD3],QUEST_BOARD.PREFABS_ITEMS)] = reward3_amount ~= 0 and reward3_amount or nil,
        },

        amount = tonumber(self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS]) > 0 and tonumber(self.new_custom_quest[STRINGS_QB.AMOUNT_OF_KILLS]) or 10,

        name = self.new_custom_quest[STRINGS_QB.TITLE] or "No_Name_"..math.random(0,1000000000),

        description = self.new_custom_quest["text"] or "No Description",

        points = tonumber(self.new_custom_quest[STRINGS_QB.POINTS]) or 100,

        difficulty = tonumber(self.new_custom_quest[STRINGS_QB.DIFFICULTY]) or 1,

        atlas = atlas_path and atlas_path.atlas or nil,

        author = self.owner and self.owner.name or nil,
        }
        if string.find(victim,"start_fn_") then
        local GOAL_TABLE =  QUEST_BOARD.PREFABS_MOBS[string.gsub(victim,"start_fn_","")]
        quest.counter_name = GOAL_TABLE and GOAL_TABLE["counter"]
        quest.start_fn = victim
        quest.victim = ""
        quest.tex = GOAL_TABLE and GOAL_TABLE["tex"]
        quest.atlas = GOAL_TABLE and GOAL_TABLE["atlas"]
        else
        quest.victim = victim
        quest.tex = victim..".tex"
        end
        devprint("adding quest")
        devdumptable(quest)
        local json_quest = ZipAndEncodeStringBuffer(json.encode(quest))
        SendModRPCToServer(MOD_RPC["Quest_System_RPC"]["AddQuestToQuestPoolServer"],json_quest)

        self.askquestion:Kill()
        self.root4:Hide()
        self.root:Show()
        self.cancel_button:Show()
        QUEST_BOARD.CUSTOM_QUEST = nil
        self.new_custom_quest = {}
        Networking_Announcement(STRINGS_QB.ADDED_SUCCESFULLY.." "..quest.name.."!")
    end,
    }
    local button2 = {
    text = STRINGS_QB.NO,
    cb = function()
        self.askquestion:Kill()
    end,
    }

    local question = self.editing_custom_quest and string.format(STRINGS_QB.ASK_OVERWRITE_QUEST, self.editing_custom_quest) or STRINGS_QB.ASK_ADD_QUEST
    self.askquestion = self.root4:AddChild(Templates_R.CurlyWindow(450,300,nil,{button1,button2},nil,question))
    self.askquestion.body:SetSize(40)
    self.askquestion.body:SetPosition(0, 70)
end

function Quest_Board_Widget:OnClose()
    print("Quest_Board_Widget:OnClose()")
	  for _,v in pairs(self.tasks) do
		  if v then
			   v:Cancel()
              v = nil
		  end
	  end
    QUEST_BOARD.CUSTOM_QUEST = self.new_custom_quest
  	local screen = TheFrontEnd:GetActiveScreen()
  	if screen and screen.name:find("HUD") == nil then
    	TheFrontEnd:PopScreen()
  	end
  	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
end


function Quest_Board_Widget:OnControl(control, down)
  	if Quest_Board_Widget._base.OnControl(self, control, down) then
  	  	return true
 	end
  	if down and (control == CONTROL_PAUSE or control == CONTROL_CANCEL) then
    	self:OnClose()
    	return true
  	end
end



return Quest_Board_Widget
