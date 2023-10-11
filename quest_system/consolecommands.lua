--------------------------------------------------------------------
local function GetRandomQuest()
    local item = GetRandomItem(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS)
    return item.name
end

function GLOBAL.c_addquest(name,inst)
	if not inst then
        inst = GLOBAL.ThePlayer
    end
    if inst.components.quest_component == nil then
    	print("[Quest System]",inst,"cannot do any quest!")
    	return
    end
    name = name or GetRandomQuest()
    inst.components.quest_component:AddQuest(name)
end

function GLOBAL.c_showquest(inst)
	if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.quest_component == nil then
        print("[Quest System]",inst,"cannot do any quest!")
        return
    end
    for _ = 1,5 do
        inst.components.quest_component:AddQuest(GetRandomQuest())
    end
    inst.components.quest_component:ShowQuestHUD()
end

function GLOBAL.c_deletequest(name)
    if GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] ~= nil then
        for _,v in ipairs(GLOBAL.AllPlayers) do
            if v.components.quest_component then
                v.components.quest_component:RemoveQuest(name)
            end
        end
        GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[name] = nil
    end
end

function GLOBAL.c_deleteallquests()
    for _,v in ipairs(GLOBAL.AllPlayers) do
        if v.components.quest_component then
            v.components.quest_component:RemoveAllQuests()
        end
    end
    GLOBAL.TUNING.QUEST_COMPONENT.QUESTS = {}
end

function GLOBAL.c_levelup(levels,inst)
	if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.quest_component == nil then
    	print("[Quest System]",inst,"cannot do any quest!")
    	return
    end
    levels = levels or 1
    for _ = 1,levels do
    	inst.components.quest_component:LevelUp()
    end
end

function GLOBAL.c_startbossfight(boss_prefab, diff, num, inst)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.quest_component == nil then
        print("[Quest System]",inst,"has no quest component!")
        return
    end
    local pos = inst:GetPosition()
    if boss_prefab then
        for difficulty, bosses in pairs(GLOBAL.TUNING.QUEST_COMPONENT.BOSSES) do
            for number, boss in ipairs(bosses) do
                if boss.name == boss_prefab then
                    diff = difficulty
                    num = number
                    break
                end
            end
        end
    end
    inst.components.quest_component:StartBossFight(pos, diff, num)
end

function GLOBAL.c_resetquests(diff,inst)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.quest_component == nil then
        print("[Quest System]",inst,"has no quest component!")
        return
    end
    diff = diff ~= nil and diff > 0 and diff < 6 and diff or nil
    inst.components.quest_component:GetPossibleQuests(diff)
    inst.replica.quest_component._acceptedquest:set(false)
end

function GLOBAL.c_completequest(name,inst)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.quest_component == nil then
        print("[Quest System]",inst,"has no quest component!")
        return
    end
    local quest 
    if name then
        quest = inst.components.quest_component.quests[name]
    else
        quest = GetRandomItem(inst.components.quest_component.quests)
    end
    if quest then
        local amount = GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[quest.name] and GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[quest.name].amount or 1
        inst.components.quest_component:UpdateQuest(quest.name,amount)
    end
end

function GLOBAL.c_completeallquests(inst)
    inst = inst or GLOBAL.ThePlayer
    for k,v in pairs(inst.components.quest_component.quests) do
        local amount = v.amount or 1
        inst.components.quest_component:UpdateQuest(k,amount)
    end
end

function GLOBAL.c_request(quest_name,inst)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    if inst.components.inventory == nil then return end
    if quest_name and GLOBAL.TUNING.QUEST_COMPONENT.QUESTS[quest_name] ~= nil then
        local request = GLOBAL.SpawnPrefab("request_quest_specific")
        request:SetQuest(quest_name)
        inst.components.inventory:GiveItem(request)
    else
        local request = GLOBAL.SpawnPrefab("request_quest")
        inst.components.inventory:GiveItem(request)
    end
end

--[[function GLOBAL.glommer(x,y,z)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    TheWorld.components.glommer_boss_comp:StartBossfight(inst)
end

function GLOBAL.chester(x,y,z)
    if not (x and y and z) then
        x,y,z = GLOBAL.TheInput.overridepos:Get()
    end
    local chesterboss = GLOBAL.SpawnPrefab("chester_boss")
    chesterboss.Transform:SetPosition(x,y,z)
end]]

function GLOBAL.c_testquests(with_rewards, inst)
    if not inst then
        inst = GLOBAL.ThePlayer--GLOBAL.ConsoleWorldEntityUnderMouse()
    end
    local old_max = inst.components.quest_component.max_amount_of_quests
    inst.components.quest_component.max_amount_of_quests = 9999
    local count = 0
    for k in pairs(GLOBAL.TUNING.QUEST_COMPONENT.QUESTS) do
        count = count + 1
        devprint("c_testquests",k,count)
        inst.components.quest_component:AddQuest(k,true)
        devprint("finished adding quest",k)
    end
    GLOBAL.c_completeallquests(inst)
    inst.components.quest_component.max_amount_of_quests = old_max
    if with_rewards then
        for name in pairs(inst.components.quest_component.quests) do
            inst.components.quest_component:CompleteQuest(name)
        end
    end
end


AddClassPostConstruct("screens/consolescreen",function(self)
    local old_init = self.DoInit
    self.DoInit = function(self,...)
        local ret = old_init(self,...)
        if self.console_edit then
            local prediction_command = {"addquest","showquest","deletequest","deleteallquests","levelup","startbossfight","resetquests","completequest","completeallquests","request",}
            self.console_edit:AddWordPredictionDictionary({words = prediction_command, delim = "c_", num_chars = 0})
        end
        return ret
    end
end)

AddUserCommand("bossisland_rescue", {
    --aliases = schnitzel,
    prettyname = function() return "debug save" end,
    desc = function() return "Debug Save from Boss Island" end,
    permission = "USER",
    params = {},
    slash = false,
    usermenu = false,
    servermenu = false,
    vote = false,
    serverfn = function(_, caller)
        local player = GLOBAL.UserToPlayer(caller.userid)
        if player ~= nil then
            if player.components.quest_component then
                local q_comp = player.components.quest_component
                local gate = q_comp.bossplatform or TheSim:FindFirstEntityWithTag("teleporter_boss_island")
                if gate and player:IsNear(gate,50) then
                    GLOBAL.TheWorld.components.playerspawner:SpawnAtNextLocation(GLOBAL.TheWorld, player)
                end
            end
        end
    end,
})