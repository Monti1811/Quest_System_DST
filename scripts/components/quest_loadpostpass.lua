local Quest_LoadPostPass = Class(function(self, inst)
    self.inst = inst
    self.bosses = {}
    self.can_create_custom_quests = {}
    self.quest_lines = {}

    --self.quest_bossfight_active = net_bool(self.inst,"quest_bossfight_active")
    --self.quest_bossfight_active:set(false)
    --first idea of saving data from who can make quests, but not needed anymore as it's saved as persistent data. 
    --Still here if I need it sometime in the future
    --[[if TUNING.QUEST_COMPONENT.CUSTOM_QUESTS == 3 then
        inst:ListenForEvent("ms_playerjoined",function(_,player)
            if player and player.userid then
                if self.can_create_custom_quests[player.userid] == true then
                    TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS[player.userid] = true
                    SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "AddCustomQuestMakerToClient"),nil,player.userid,1)
                    SendModRPCToShard(GetShardModRPC("Quest_System_RPC","AddCustomQuestMakerToShards"),nil,player.userid,1)
                end
            end
        end)
    end]]

    self.nightmarechester = 0
    self.glommerfuelmachine = 0

end)

function Quest_LoadPostPass:CanQuestLineBeDone(name)
    if self.quest_lines[name] == nil then
        return true
    end
end

function Quest_LoadPostPass:InsertBoss(bossid,boss,diff,num)
    self.bosses[bossid] = {boss,diff,num}
end

function Quest_LoadPostPass:MakeBoss(boss,diff,num,fn)
    if diff == nil or num == nil then return end
    local tuning = TUNING.QUEST_COMPONENT.BOSSES[diff]
    boss = boss ~= "nothing" and boss or SpawnPrefab(tuning[num].name or "hound")
    if boss then
        if boss.components.health then
            boss.components.health:SetMaxHealth((tuning[num].health or 1000) * TUNING.QUEST_COMPONENT.BOSS_DIFFICULTY)
        end
        if boss.components.combat then
            boss.components.combat:SetDefaultDamage((tuning[num].damage or 100) * TUNING.QUEST_COMPONENT.BOSS_DIFFICULTY)
            boss.components.combat:SetRange(boss.components.combat.attackrange * 1.2, boss.components.combat.hitrange * 1.2)
        end
        boss.Transform:SetScale(tuning[num].scale,tuning[num].scale,tuning[num].scale)
        if boss.components.named == nil then
            boss:AddComponent("named")
        end
        boss.components.named:SetName("Boss "..boss:GetDisplayName())
        boss:AddTag("Quest_Boss_"..string.lower(diff))

        fn = fn or tuning[num].fn
        if fn then
            fn(boss)
        end
        return boss
    end
end

function Quest_LoadPostPass:OnSave()
    local bosses_players = {}
    for k,v in pairs(self.bosses) do
        table.insert(bosses_players,v[1].GUID)
    end
    local _bosses = {}
    for k,v in pairs(self.bosses) do
        local tab = {v[1].GUID,v[2],v[3]}
        table.insert(_bosses,tab)
    end
    local can_create_custom_quests = TUNING.QUEST_COMPONENT.CAN_CREATE_CUSTOM_QUESTS
    SaveOwnQuests() --save the custom quests that were made, added here so that they are saved each time the world is saved
    return {bosses_players = bosses_players,
            _bosses = _bosses,
            can_create_custom_quests = can_create_custom_quests, 
            quest_lines = self.quest_lines,
            nightmarechester = self.nightmarechester,
            glommerfuelmachine = self.glommerfuelmachine}, 

            bosses_players 
end

function Quest_LoadPostPass:OnLoad(data)
    if data ~= nil then
        if data._bosses ~= nil then
            for _,v in pairs(data._bosses) do
                if v[1] ~= nil then
                    local tab = {"nothing",v[2],v[3]}
                    self.bosses[v[1]] = tab
                    devdumptable(self.bosses[v[1]])
                end
            end
        end
        if data.can_create_custom_quests ~= nil and next(data.can_create_custom_quests) ~= nil then
            self.can_create_custom_quests = data.can_create_custom_quests
        end
        if data.quest_lines ~= nil and next(data.quest_lines) ~= nil  then
            self.quest_lines = data.quest_lines
        end
        if data.nightmarechester ~= nil and type(data.nightmarechester) == "number" and data.nightmarechester ~= 0 then
            self.nightmarechester = data.nightmarechester
        end
        if data.glommerfuelmachine ~= nil and type(data.glommerfuelmachine) == "number" and data.glommerfuelmachine ~= 0 then
            self.glommerfuelmachine = data.glommerfuelmachine
        end
    end
end

function Quest_LoadPostPass:LoadPostPass(newents, savedata)
	devprint("LoadPostPass world")
	if savedata ~= nil then
		if savedata.bosses_players ~= nil then
            for k,v in ipairs(savedata.bosses_players) do
                local targ = newents[v]
                if targ ~= nil and self.bosses and self.bosses[v] then
                    self.bosses[v][1] = targ.entity
                    self.inst:DoTaskInTime(0,function() self:MakeBoss(self.bosses[v][1],self.bosses[v][2],self.bosses[v][3]) end)
                end
            end
        end
    end
    devdumptable(self.bosses)
end

return Quest_LoadPostPass