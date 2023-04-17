require "prefabutil"
require "recipe"
require "modutil"

local assets=
{
	Asset("ANIM", "anim/request_quest.zip"),
}

local function GetUnusedQuestWithDifficulty(inst,reader,difficulty,quest_name)
    if reader and reader.components.quest_component then
        if GetTableSize(reader.components.quest_component.quests) >= reader.components.quest_component.max_amount_of_quests then
            reader.components.talker:Say(STRINGS.QUEST_COMPONENT.REQUEST_QUEST.FULL_LOG)
            return
        end
        if TheWorld.components.quest_loadpostpass:CanQuestLineBeDone(quest_name) == false then
            reader.components.talker:Say(string.format("The quest %s of a quest line is already active for somebody else",quest_name))
            inst.quest_name = quest_name
            return
        end
        local character = TUNING.QUEST_COMPONENT.QUESTS[quest_name] and TUNING.QUEST_COMPONENT.QUESTS[quest_name].character
        if character then
            if reader.prefab == character then
                reader.components.talker:Say(string.format("This quest can only be accepted by %s",STRINGS.NAMES[character] or character))
                return
            end
        end
        inst.used = true
        quest_name = quest_name or reader.components.quest_component:GetUnusedQuestNum(type(difficulty) == "number" and difficulty or nil)
        reader.components.quest_component:AddQuest(quest_name)           
        inst:DoTaskInTime(1, function()
            inst:Remove() 
            reader.sg:GoToState("idle")
            reader.components.talker:Say(STRINGS.QUEST_COMPONENT.REQUEST_QUEST.QUEST_ADDED)
        end)
    end
end

--[[local color_table 
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
end]]

local difficulties = {
    "very_easy",
    "easy",
    "normal",
    "difficult",
    "very_difficult",
}

local function SetQuest(inst,quest_name)
    inst.quest_name = quest_name
    if inst.components.named == nil then
        inst:AddComponent("named")
    end
    inst.components.named:SetName(STRINGS.NAMES.REQUEST_QUEST_SPECIFIC..": "..quest_name)
end

local function OnLoad(inst,data)
    if data and data.quest_name then
        inst:SetQuest(data.quest_name)
    end
end

local function OnSave(inst,data)
    if inst.quest_name ~= nil then
        data.quest_name = inst.quest_name
    end
end

local function fn_all(difficulty,particular)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("request_quest")
    inst.AnimState:SetBuild("request_quest")
    inst.AnimState:PlayAnimation("idle")
    if difficulty ~= nil and type(difficulty) == "number" then
        --local tab = color_table[difficulty]
        --inst.AnimState:SetMultColour(tab[1], tab[2], tab[3], tab[4])
        inst:AddTag(difficulties[difficulty])
        inst.AnimState:OverrideSymbol("star","quest_stars","star-"..difficulty)
    end

    local trans = inst.entity:AddTransform()
    trans:SetScale(0.5, 0.5, 0.5)

    inst.difficulty = difficulty

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("simplebook")
    inst.components.simplebook.onreadfn = function(inst,reader)
        if inst.used == true then return end
    	GetUnusedQuestWithDifficulty(inst,reader,difficulty, inst.quest_name)
    end

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    if particular == true then
        inst.SetQuest = SetQuest
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunch(inst)

    return inst
end

local function fn()
    local inst = fn_all(nil)
    return inst
end

local function fn_very_easy()
    local inst = fn_all(1)
    return inst
end

local function fn_easy()
    local inst = fn_all(2)
    return inst
end

local function fn_normal()
    local inst = fn_all(3)
    return inst
end

local function fn_difficult()
    local inst = fn_all(4)
    return inst
end

local function fn_very_difficult()
    local inst = fn_all(5)
    return inst
end

local function fn_specific()
    local inst = fn_all(nil,true)
    return inst
end


return  Prefab("request_quest", fn, assets),
        Prefab("request_quest_very_easy", fn_very_easy, assets),
        Prefab("request_quest_easy", fn_easy, assets),
        Prefab("request_quest_normal", fn_normal, assets),
        Prefab("request_quest_difficult", fn_difficult, assets),
        Prefab("request_quest_very_difficult", fn_very_difficult, assets),
        Prefab("request_quest_specific", fn_specific, assets)