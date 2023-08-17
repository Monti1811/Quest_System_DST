local function GetSpawnPoint(pt,radius)
    local theta = math.random() * 2 * PI
    radius = radius or math.random(6,14)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

local function StopTask(entity, task)
	if entity[task] ~= nil then
		entity[task]:Cancel()
		entity[task] = nil
	end
end

local function OnForfeit(inst,fn,quest_name)
	local function OnForfeitedQuest(inst,name)
		if name == quest_name then
			fn(inst)
			inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
		end
	end
	inst:ListenForEvent("forfeited_quest",OnForfeitedQuest)
end

local function GetCurrentAmount(player,quest_name)
	if player and player.components.quest_component then
		if player.components.quest_component.quests[quest_name] then
			return player.components.quest_component.quests[quest_name].current_amount or 0
		end
	end
	return 0
end

local function GetValues(player,quest_name,value_name)
	if player.components.quest_component == nil then return end
	local value = 0
	local saved_value = player.components.quest_component:GetQuestData(quest_name,value_name)
	return saved_value or value
end

local function RemoveValues(player,quest_name)
	if player.components.quest_component == nil then return end
	player.components.quest_component.quest_data[quest_name] = nil
end

local function ScaleQuest(inst,quest,val)
	if inst.components.quest_component then
		inst.components.quest_component.scaled_quests[quest] = val
	end
end

local quests = {

	wilson = {
		--1
		{
			name = "The Scientist",
			victim = "",
			counter_name = GetQuestString("The Scientist","COUNTER"),
			description = GetQuestString("The Scientist","DESCRIPTION"),
			amount = 3,
			rewards = {},
			points = 275,
			start_fn = function(inst,amount,quest_name)
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["build x y times"](inst,amount,"researchlab2",quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "science.tex",
			atlas = "images/victims.xml",
			hovertext = GetQuestString("The Scientist","HOVER"),
		},
		--2
		{
			name = "The Alchemist 1",
			victim = "",
			counter_name = GetQuestString("The Alchemist 1","COUNTER"),
			description = GetQuestString("The Alchemist 1","DESCRIPTION", 3),
			amount = 3,
			rewards = {},
			points = 275,
			start_fn = function(inst,amount,quest_name)
				local gems = {redgem = true, bluegem = true, purplegem = true}
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,gems, "CHARACTER", quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "wilson_alchemy_gem_1.tex",
			atlas = "images/skilltree_icons.xml",
			hovertext = GetQuestString("The Alchemist 1","HOVER", 3),
		},
		--3
		{
			name = "The Alchemist 2",
			victim = "",
			counter_name = GetQuestString("The Alchemist 2","COUNTER"),
			description = GetQuestString("The Alchemist 2","DESCRIPTION", 3),
			amount = 3,
			rewards = {},
			points = 550,
			start_fn = function(inst,amount,quest_name)
				local gems = {orangegem = true, yellowgem = true,}
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,gems, "CHARACTER", quest_name)
			end,
			onfinished = nil,
			difficulty = 3,
			tex = "wilson_alchemy_gem_2.tex",
			atlas = "images/skilltree_icons.xml",
			hovertext = GetQuestString("The Alchemist 2","HOVER", 3),
		},
		--4
		{
			name = "The Alchemist 3",
			victim = "",
			counter_name = GetQuestString("The Alchemist 3","COUNTER"),
			description = GetQuestString("The Alchemist 3","DESCRIPTION", 3),
			amount = 3,
			rewards = {},
			points = 1100,
			start_fn = function(inst,amount,quest_name)
				local gems = {opalpreciousgem = true, greengem = true,}
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["craft x y times"](inst,amount,gems, "CHARACTER", quest_name)
			end,
			onfinished = nil,
			difficulty = 4,
			tex = "wilson_alchemy_gem_3.tex",
			atlas = "images/skilltree_icons.xml",
			hovertext = GetQuestString("The Alchemist 3","HOVER", 3),
		},
		--5
		{
			name = "The Bearded",
			victim = "",
			counter_name = GetQuestString("The Bearded","COUNTER"),
			description = GetQuestString("The Bearded","DESCRIPTION", 1200),
			amount = 1200,
			rewards = {},
			points = 200,
			start_fn = function(inst,amount,quest_name)
				local function HasGreatestBeard(player)
					return player.components.beard and player.components.beard.daysgrowth > 15
				end
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x each second for y seconds"](inst,amount,HasGreatestBeard, 5, quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "wilson_beard_speed_3.tex.tex",
			atlas = "images/skilltree_icons.xml",
			hovertext = GetQuestString("The Bearded","HOVER", 1200),
		},
	},

	willow = {

		--1
		{
			name = "The Arsonist",
			victim = "",
			counter_name = GetQuestString("The Arsonist","COUNTER"),
			description = GetQuestString("The Arsonist","DESCRIPTION"),
			amount = 10,
			rewards = {},
			points = 150,
			start_fn = function(inst,amount,quest_name)
				local current = GetCurrentAmount(inst,quest_name)
				local function OnStartedFire(_,data)
					local hand = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if hand and hand.prefab == "lighter" then
						inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
						current = current + 1
						if current >= amount then
							inst:RemoveEventCallback("onstartedfire",OnStartedFire)
						end
					end
				end
				inst:ListenForEvent("onstartedfire",OnStartedFire)
				local function OnForfeitedQuest(_)
					inst:RemoveEventCallback("onstartedfire",OnStartedFire)
				end
				OnForfeit(inst,OnForfeitedQuest,quest_name)
			end,
			onfinished = nil,
			difficulty = 1,
			tex = "lighter.tex",
			atlas = "images/inventoryimages1.xml",
			hovertext = GetQuestString("The Arsonist","HOVER"),
		},

	},

	wolfgang = {

		--1
		{
			name = "The Muscle Man",
			victim = "",
			counter_name = GetQuestString("The Muscle Man","COUNTER"),
			description = GetQuestString("The Muscle Man","DESCRIPTION"),
			amount = 120,
			rewards = {},
			points = 150,
			start_fn = function(inst,amount,quest_name)
				local function CheckMigthiness(inst)
					if inst:GetMightiness() >= 0.9 then
						return true
					end
				end
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["do x each second for y seconds"](inst,amount,CheckMigthiness,1,quest_name)
			end,
			onfinished = nil,
			difficulty = 1,
			tex = "arrow_1.tex",
			atlas = "images/victims.xml",
			hovertext = GetQuestString("The Muscle Man","HOVER"),
		},

	},

	wendy = {

		--1
		{
			name = "The Ghostly Bond",
			victim = "",
			counter_name = GetQuestString("The Ghostly Bond","COUNTER"),
			description = GetQuestString("The Ghostly Bond","DESCRIPTION"),
			amount = 3,
			rewards = {},
			points = 275,
			start_fn = function(inst,amount,quest_name)
				local current = GetCurrentAmount(inst,quest_name)
				local function OnLevelChanged(inst,data)
					if data then
						if data.level == 3 then
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							inst:RemoveEventCallback("ghostlybond_level_change",OnLevelChanged)
						end
					end
				end
				inst:ListenForEvent("ghostlybond_level_change",OnLevelChanged)
				local function OnForfeitedQuest(inst)
					inst:RemoveEventCallback("ghostlybond_level_change",OnLevelChanged)
				end
				OnForfeit(inst,OnForfeitedQuest,quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "science.tex",
			atlas = "images/victims.xml",
			hovertext = GetQuestString("The Ghostly Bond","HOVER"),
		},


	},

	wx78 = {

		--1
		{
			name = "Too Many Gears!",
			victim = "",
			counter_name = GetQuestString("Too Many Gears!","COUNTER"),
			description = GetQuestString("Too Many Gears!","DESCRIPTION"),
			amount = 5,
			rewards = {},
			points = 150,
			start_fn = function(inst,amount,quest_name)
				TUNING.QUEST_COMPONENT.CUSTOM_QUEST_FUNCTIONS["eat x times y"](inst,"gears",amount,quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "gears.tex",
			atlas = "images/inventoryimages1.xml",
			hovertext = GetQuestString("Too Many Gears!","HOVER"),
		},

	},

	wickerbottom = {

		--1
		{
			name = "The Bookworm",
			victim = "",
			counter_name = GetQuestString("The Bookworm","COUNTER"),
			description = GetQuestString("The Bookworm","DESCRIPTION"),
			amount = 5,
			rewards = {},
			points = 150,
			start_fn = function(inst,amount,quest_name)
				if inst.components.quest_component == nil then return end
				local books = {book_birds = true,book_sleep = true,book_tentacles = true,book_brimstone = true,book_horticulture = true,book_silviculture = true,}
				local built = GetCurrentAmount(inst,quest_name)
				local function OnBuild(inst,data)
					if data then
						if data.item and books[data.item.prefab] then
							built = built + 1
							inst:PushEvent("quest_update",{quest = quest_name,amount = 1})
							if built >= amount then
								inst:RemoveEventCallback("builditem",OnBuild)
							end
						end
					end
				end
				inst:ListenForEvent("builditem",OnBuild)
				local function OnForfeitedQuest(inst)
					inst:RemoveEventCallback("builditem",OnBuild)
				end
				OnForfeit(inst,OnForfeitedQuest,quest_name)
			end,
			onfinished = nil,
			difficulty = 2,
			tex = "book_tentacles.tex",
			atlas = "images/inventoryimages1.xml",
			hovertext = GetQuestString("The Bookworm","HOVER"),
		},

	},

	woodie = {


	},

	wes = {


	},

	waxwell = {


	},

	wigfrid = {


	},

	webber = {


	},

	warly = {


	},

	wormwood = {


	},

	winona = {


	},

	wortox = {


	},

	wurt = {


	},

	walter = {


	},

	wanda = {


	},

}

for char,char_quests in pairs(quests) do
	for num,quest in ipairs(char_quests) do
		quests[char][num].character = char
	end
end

return quests