local function GetCurrentAmount(player,quest_name)
    local quest_component = player.components.quest_component
    if quest_component then
        if quest_component.quests[quest_name] then
            return quest_component.quests[quest_name].current_amount or 0
        end
    end
    return 0
end

local function GetValues(player,quest_name,value_name)
    local quest_component = player.components.quest_component
    if quest_component == nil then
        return
    end
    local value = 0
    local saved_value = quest_component:GetQuestData(quest_name,value_name)
    return saved_value or value
end

local function RemoveValues(player,quest_name)
    local quest_component = player.components.quest_component
    if quest_component == nil then
        return
    end
    quest_component.quest_data[quest_name] = nil
end

local scale_steps = {1,2,3,4,5}

local function MakeScalable(inst, amount, quest_name, getScaleFn)
    local quest_component = inst.components.quest_component
    local max_scale = quest_component and quest_component.scaled_quests[quest_name] and quest_component.scaled_quests[quest_name] + 1 or 1
    max_scale = math.min(max_scale, scale_steps[#scale_steps])
    local scale = getScaleFn and getScaleFn(max_scale) or math.random(math.max(max_scale-1, 1),max_scale)
    return {scale = scale}
end

local function GiveMakeScalableFn(scaleSteps,ScaleFn)
    scaleSteps = scaleSteps or scale_steps
    local scale_fn = function(scale)
        return ScaleFn and ScaleFn(scale) or scaleSteps[math.random(math.max(scale-1, 1),scale)]
    end
    return function(inst, amount, quest_name)
        local quest_component = inst.components.quest_component
        local max_scale = quest_component and quest_component.scaled_quests[quest_name] and quest_component.scaled_quests[quest_name] + 1 or 1
        max_scale = math.min(max_scale, #scaleSteps)
        local scale = scale_fn(max_scale)
        --devprint("GiveMakeScalableFn", inst, amount, quest_name, max_scale, scale)
        return {scale = scale}
    end
end

local function ScaleQuest(inst,quest,val)
    local quest_component = inst.components.quest_component
    if quest_component then
        quest_component.scaled_quests[quest] = val
    end
end

local function ScaleEnd(inst,items,quest_name)
    local quest_component = inst.components.quest_component
    local quest = quest_component.quests[quest_name]
    local scale = quest and quest.custom_vars and quest.custom_vars.scale or 1
    local old_scale = quest_component.scaled_quests[quest_name]
    if old_scale then
        scale = math.max(old_scale,scale)
    end
    ScaleQuest(inst,quest_name,scale)
end

local function CreateQuest(data)
    if data.name == nil or data.difficulty == nil then
        print("[Quest System] Quest could not be created, name or difficulty is missing!", data.name, data.difficulty)
        return
    end
    local isVictimQuest = data.victim ~= "" and data.victim ~= nil
    local quest = {
        name = data.name,
        victim = data.victim,
        counter_name = data.counter_name or (not isVictimQuest and GetQuestString(data.name,"COUNTER")) or nil,
        description = data.description or GetQuestString(data.name,"DESCRIPTION", data.amount),
        amount = data.amount or 1,
        rewards = data.rewards or {},
        points = data.points or 0,
        start_fn = data.start_fn,
        onfinished = data.onfinished,
        difficulty = data.difficulty,
        tex = data.tex or (isVictimQuest and data.victim..".tex") or nil,
        atlas = data.atlas or (isVictimQuest and "images/victims.xml") or nil,
        hovertext = data.hovertext or (isVictimQuest and GetKillString(data.victim, data.amount)) or GetQuestString(data.name,"HOVER", data.amount),
        anim_prefab = data.anim_prefab or isVictimQuest and data.victim or nil,
        quest_line = data.quest_line or nil,
        unlisted = data.unlisted or nil,
        character = data.character or nil,
    }
    --Custom reward paths can be added here
    if data.custom_rewards_paths then
        for reward, paths in pairs(data.custom_rewards_paths) do
            quest["reward_"..reward.."_tex"] = paths[1]
            quest["reward_"..reward.."_atlas"] = paths[2]
        end
    end
    --Scalable code
    local scalable = data.scalable
    if scalable then
        quest.custom_vars_fn = scalable.custom_vars_fn or GiveMakeScalableFn(scalable.scale_steps, scalable.scale_fn)
        if not scalable.no_scale_end then
            local old_onfinished = quest.onfinished
            if old_onfinished == nil then
                quest.onfinished = ScaleEnd
            else
                quest.onfinished = function(...)
                    old_onfinished(...)
                    ScaleEnd(...)
                end
            end
        end
        quest.variable_fn = scalable.variable_fn or function(inst, scaled_quest, quest_data)
            local scale = quest_data and quest_data.scale and tonumber(quest_data.scale) or nil
            if scale and scale > 1 then
                scaled_quest.amount = scalable.amount[scale]
                scaled_quest.points = scalable.points[scale]
                scaled_quest.rewards = scalable.rewards[scale]
                scaled_quest.scale = {scale}
                scaled_quest.difficulty = scale
                scaled_quest.hovertext = scalable.hovertext and scalable.hovertext[scale] or GetQuestString(scaled_quest.name,"HOVER", scalable.amount[scale])
                if scalable.counter_name then
                    scaled_quest.counter_name = scalable.counter_name[scale]
                end
                if scalable.description then
                    scaled_quest.description = scalable.description[scale]
                end
                if scalable.post_fn then
                    scalable.post_fn(inst,scaled_quest,quest_data)
                end
            end
            return scaled_quest
        end
        quest.scale = scalable.scale or {1}
    end
    --If you need to add something to the table
    if data.post_fn ~= nil then
        data.post_fn(quest)
    end
    return quest
end

local function OnForfeit(inst,fn,quest_name)
    local OnFinishedQuest = function() end
    local function OnForfeitedQuest(_inst,name)
        if name == quest_name then
            fn(_inst)
            _inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
            _inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
        end
    end
    OnFinishedQuest = function(_inst,name)
        if name == quest_name then
            fn(_inst)
            _inst:RemoveEventCallback("finished_quest",OnFinishedQuest)
            _inst:RemoveEventCallback("forfeited_quest",OnForfeitedQuest)
        end
    end
    inst:ListenForEvent("forfeited_quest",OnForfeitedQuest)
    inst:ListenForEvent("finished_quest",OnFinishedQuest)
end

return {
    GetCurrentAmount = GetCurrentAmount,
    GetValues = GetValues,
    RemoveValues = RemoveValues,
    MakeScalable = MakeScalable,
    GiveMakeScalableFn = GiveMakeScalableFn,
    ScaleQuest = ScaleQuest,
    ScaleEnd = ScaleEnd,
    CreateQuest = CreateQuest,
    OnForfeit = OnForfeit,
}