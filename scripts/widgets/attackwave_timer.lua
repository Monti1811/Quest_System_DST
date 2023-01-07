local Widget = require "widgets/widget"
local UIAnim = require("widgets/uianim")
local Image = require("widgets/image")
local Text = require("widgets/text")

local types = {
    [0] = "DoTimer",
    [1] = "DoWave",
    [2] = "DoWave",
    [3] = "DoWave",
    [4] = "DoWave",
    [5] = "DoWave",
}

local AttackWaveTimer = Class(Widget, function(self, owner, time, victim, type, atlas)
    Widget._ctor(self,"Button_QuestLog")
    devprint("AttackWaveTimer start",time,victim,atlas,type)
    self.owner = owner
    time = time or 1
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetPosition(0, -100)
    local scale = 0.5
    self.root:SetScale(scale,scale)
    self.bg = self.root:AddChild(Image("images/plantregistry.xml","oversizedpicturefilter.tex"))
    self.bg:SetScale(0.9,0.3)
    self.bg:SetPosition(0, 0)
    type = type or 0
    self[ types[type] ](self,time,victim,atlas,type)
end)

function AttackWaveTimer:DoTimer(time,victim,atlas)
    local victimtex = victim and victim..".tex" or "avatar_unknown.tex"
    local target_atlas = GetInventoryItemAtlas(victimtex or "",true) or atlas or "images/victims.xml"
    local orig_time = time
    devprint("AttackWaveTimer",time,victim,atlas,target_atlas)
    self.victim = self.root:AddChild(Image(target_atlas, victimtex))
    self.victim:SetPosition(75, 0)
    --self.victim:MoveToFront()
    self.progressbar = self.root:AddChild(UIAnim())
    self.progressbar:GetAnimState():SetScale(-1,1,1)
    self.progressbar:GetAnimState():SetBank("player_progressbar_small")
    self.progressbar:GetAnimState():SetBuild("player_progressbar_small")
    self.progressbar:GetAnimState():PlayAnimation("fill_progress", true)
    self.progressbar:GetAnimState():SetPercent("fill_progress", 1)
    self.progressbar:SetPosition(-35,0)
    local name = STRINGS.NAMES[string.upper(victim)] or "victim"
    self.progressbar:SetTooltip(string.format("Time till %s arrives: %i",name,time))
    self.progressbar:SetTooltipPos(0,-50,0)
    --Update the time and description
    self.updatetask = self.inst:DoSimPeriodicTask(1,function()
        time = time - 1
        local percent = time/orig_time
        self.progressbar:GetAnimState():SetPercent("fill_progress", percent)
        self.progressbar:SetTooltip(string.format("Time till %s arrives: %i",name,time))
        if time <= 0 then
            if self.updatetask ~= nil then
                self.updatetask:Cancel()
                self.updatetask = nil
            end
            self:Kill()
        end
    end)
end

function AttackWaveTimer:DoWave(time,victim,atlas,num)
    devprint("doWave",time,victim,atlas,num)
    local victimtex = victim and victim..".tex" or "avatar_unknown.tex"
    local target_atlas = GetInventoryItemAtlas(victimtex,true) or atlas or "images/victims.xml"
    time = time or 1
    num = num or 1
    self.victim = self.root:AddChild(Image(target_atlas, victimtex))
    self.victim:SetPosition(75, 0)
    self.victim:MoveToFront()
    self.victim:SetTooltip(string.format("This wave contains %s enemies that you must defeat",time))
    self.victim:SetTooltipPos(0,-50,0)
    self.wave = self.root:AddChild(Text(BODYTEXTFONT, 33, string.format("Wave %s\n%s enemies",num,time)))
    self.wave:SetPosition(-30,0,0)
end


return AttackWaveTimer
