local MAX_BOSS_TRIES = 5
local QUEST_COMPONENT = TUNING.QUEST_COMPONENT
local BOSSFIGHT_REWARDS = QUEST_COMPONENT.BOSSFIGHT_REWARDS
local REWARDS_AMOUNT =  QUEST_COMPONENT.REWARDS_AMOUNT

local function GetDiff(level)
    local difficulties = {
        EASY = math.max(200 - level * 4,5),	--103 - self.level * 3 > 0 and 100 - self.level * 3 or 0,
        NORMAL = math.max(50 - level,10),		--51 - self.level > 0 and 50 - self.level or 0,
        DIFFICULT = math.min(level - 1,85),
    }
    return weighted_random_choice(difficulties)
end

local function SetPositionAndTeleport(self, pos)
    self.pos_before_fight = pos or (TheWorld.components.playerspawner ~= nil and TheWorld.components.playerspawner:GetAnySpawnPoint()) or Vector3(0,0,0)
    self.bossplatform = self.bossplatform or TheSim:FindFirstEntityWithTag("teleporter_boss_island")
    local plattform = self.bossplatform
    local is_no_plattform
    if plattform == nil then
        plattform = self.inst
        is_no_plattform = true
    end
    self.inst:SnapCamera()
    self.inst:ScreenFade(false, 2)
    self.inst:DoTaskInTime(2, function()
        self.inst:ScreenFade(true, 0.5)
    end)

    if not is_no_plattform then
        self.inst:DoTaskInTime(0.5,function() self.inst.Physics:Teleport(plattform:GetPosition():Get()) end)
    end
    return is_no_plattform
end

local function SpawnBoss(self, difficulty, boss_number)
    local current_boss_tries = 0
    while current_boss_tries < MAX_BOSS_TRIES and self.boss == nil do
        self.boss = TheWorld.components.quest_loadpostpass:MakeBoss(nil,difficulty,boss_number)
        current_boss_tries = current_boss_tries + 1
    end
    return self.boss ~= nil
end

local function SetBossPosition(self, is_no_plattform)
    local x,y,z = self.bossplatform.Transform:GetWorldPosition()
    if is_no_plattform then
        local position = FindWalkableOffset(Vector3(x,y,z),math.random()*PI*2,16,8,true,false)
        if position then
            self.boss.Transform:SetPosition(x+position.x,y+position.y,z+position.z)
        else
            self.boss.Transform:SetPosition(x,y,z)
        end
    else
        local a,b,c = x + 16*(math.random(2) == 1 and -1 or 1),y,z + 16*(math.random(2) == 1 and -1 or 1)
        self.boss.Transform:SetPosition(a,b,c)
        self.inst:AddTag("currently_in_bossfight")
    end
end

-------------------------------------------------------

local function Retarget(inst,player)
    if not inst:IsValid() then return end
    local combat = inst.components.combat
    local health = inst.components.health
    if not health or health:IsDead() then
        return
    end
    if combat and player and player:IsValid() and inst:IsValid() then
        devprint("set target",inst,player)
        combat:SetTarget(player)
    end
    if inst.target_inst ~= nil then
        inst.target_inst:Cancel()
        inst.target_inst = nil
    end

    inst.target_inst = inst:DoTaskInTime(3,Retarget,player)
end

local function GiveRewards(inst,difficulty)
    devprint("GiveRewards",inst,difficulty)
    difficulty = difficulty or "NORMAL"

    local num = math.random(#BOSSFIGHT_REWARDS[difficulty])
    local inventory = inst.components.inventory
    if num and inventory then
        local tab = BOSSFIGHT_REWARDS[difficulty][num]
        if tab.items and tab.amount then
            for k,v in ipairs(tab.items) do
                local amount = math.ceil(math.random(tab.amount[k][1],tab.amount[k][2]) * REWARDS_AMOUNT)
                for _ = 1, amount do
                    local item = SpawnPrefab(v)
                    if item then
                        inventory:GiveItem(item)
                    end
                end
            end
        end
    end
    if inst.components.talker then
        inst.components.talker:Say(STRINGS.QUEST_COMPONENT.TALKING.REWARDS)
    end
    local points = difficulty == "EASY" and 500 or difficulty == "NORMAL" and 1000 or difficulty == "DIFFICULT" and 1500 or 500
    inst.components.quest_component:AddPoints(points)
end

local function OnDeaths(self, difficulty, is_no_plattform)
    devprint("OnDeaths",difficulty, is_no_plattform)
    local pos = self.pos_before_fight or Vector3(0,0,0)
    local BossDeath = function()  end
    local function PlayerDeath()
        if self.inst:HasTag("currently_in_bossfight") == false then return end
        self.bossfight = self.bossfight - 1
        TheNet:Announce(self.inst:GetDisplayName().." was defeated!")
        self.boss:RemoveEventCallback("death", BossDeath)
        self.boss:RemoveEventCallback("onremove", BossDeath)

        self.inst:DoTaskInTime(3,function()
            if self.boss and self.boss:IsValid() then
                self.boss:Remove()
            end
            self.boss = nil
            TheWorld.components.quest_loadpostpass:RemoveBoss(self.bossid)
        end)
        if not is_no_plattform then
            self.inst:DoTaskInTime(5,function(inst)
                --inst:SnapCamera()
                inst:ScreenFade(false, 0.5)
                inst:PushEvent("respawnfromghost")
                inst:DoTaskInTime(0.5,function()
                    inst.Physics:Teleport(pos.x,pos.y,pos.z)
                    inst:RemoveTag("currently_in_bossfight")
                    inst:ScreenFade(true, 0.5)
                end)
            end)
        end
    end

    -- Remove the boss from the quest system and enable the way back for the player
    local tries = 0
    BossDeath = function()
        if self.boss then
            if self.inst:IsValid() then
                self.inst:AddTag("won_against_boss")
                TheNet:Announce(self.inst:GetDisplayName().." was victorious!")
                self.inst:DoTaskInTime(1,GiveRewards,difficulty)
                self.inst:RemoveEventCallback("death", PlayerDeath)
            elseif tries < 5 then
                tries = tries + 1
                TheWorld:DoTaskInTime(0.1, BossDeath)
                return
            end
            if self.bossplatform then
                self.bossplatform:TurnOn()
            end
            self.bossfight = self.bossfight - 1
            self.boss = nil
            TheWorld.components.quest_loadpostpass:RemoveBoss(self.bossid)
        end
    end

    self.boss:ListenForEvent("death", BossDeath)
    self.boss:ListenForEvent("onremove", BossDeath)
    self.inst:ListenForEvent("death", PlayerDeath)
end

local function ConfigureBoss(self, difficulty, number, is_no_plattform)
    OnDeaths(self,difficulty, is_no_plattform)
    self.boss.target_inst = self.boss:DoTaskInTime(3, Retarget, self.inst)
    self.bossid = self.boss.GUID
    TheWorld.components.quest_loadpostpass:InsertBoss(self.bossid, self.boss, difficulty, number)
end

-------------------------------------------------------

return {
    GetDiff = GetDiff,
    SetPositionAndTeleport = SetPositionAndTeleport,
    SpawnBoss = SpawnBoss,
    SetBossPosition = SetBossPosition,
    ConfigureBoss = ConfigureBoss,
    OnDeaths = OnDeaths,
    Retarget = Retarget,
}