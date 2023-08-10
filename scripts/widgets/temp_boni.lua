local Widget = require "widgets/widget"
local Image = require "widgets/image"

local STRINGS_TB = STRINGS.QUEST_COMPONENT.TEMP_BONI

local function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function toMin(time)
	time = time or 0
	local minute = math.floor(time/60)
	local seconds = math.floor(math.fmod(time,60))
	if seconds < 10 then
		seconds = "0"..seconds
	end
	return minute..":"..seconds
end

local string = {

	health = function(amount)
		local str = "+"..amount..STRINGS_TB.HEALTH
		local arrow = amount < 11 and 0 or amount < 26 and 1 or amount < 51 and 2 or 3
		return str,arrow
	end,

	sanity = function(amount)
		local str = "+"..amount..STRINGS_TB.SANITY
		local arrow = amount < 11 and 0 or amount < 26 and 1 or amount < 51 and 2 or 3
		return str,arrow
	end,

	hunger = function(amount)
		local str = "+"..amount..STRINGS_TB.HUNGER
		local arrow = amount < 11 and 0 or amount < 26 and 1 or amount < 51 and 2 or 3
		return str,arrow
	end,

	sanityaura = function(amount)
		local str = "+"..amount..STRINGS_TB.SANITYAURA
		local arrow = amount < 2.1 and 0 or amount < 5.1 and 1 or amount < 10.1 and 2 or 3
		return str,arrow
	end,

	hungerrate = function(amount)
		local str = (amount*100)..STRINGS_TB.HUNGERRATE
		local arrow = amount > 0.89 and 0 or amount > 0.79 and 1 or amount > 0.69 and 2 or 3
		return str,arrow
	end,

	healthrate = function(amount)
		local str = "+"..amount..STRINGS_TB.HEALTHRATE
		local arrow = amount < 1.1 and 0 or amount < 2.1 and 1 or amount < 5.1 and 2 or 3
		return str,arrow
	end,

	damage = function(amount)
		local str = "+"..amount..STRINGS_TB.DAMAGE
		local arrow = amount < 2.1 and 0 or amount < 5.1 and 1 or amount < 10.1 and 2 or 3
		return str,arrow
	end,

	planardamage = function(amount)
		local str = "+"..amount..STRINGS_TB.PLANARDAMAGE
		local arrow = amount < 2.1 and 0 or amount < 5.1 and 1 or amount < 10.1 and 2 or 3
		return str,arrow
	end,

	damagereduction = function(amount)
		local str = ((1-amount)*100)..STRINGS_TB.DAMAGEREDUCTION
		local arrow = amount > 0.89 and 0 or amount > 0.79 and 1 or amount > 0.69 and 2 or 3
		return str,arrow
	end,

	planardamage = function(amount)
		local str = "+"..amount..STRINGS_TB.PLANARDEFENSE
		local arrow = amount < 2.1 and 0 or amount < 5.1 and 1 or amount < 10.1 and 2 or 3
		return str,arrow
	end,

	range = function(amount)
		local str = "+"..amount..STRINGS_TB.RANGE
		local arrow = amount < 0.51 and 0 or amount < 1.1 and 1 or amount < 1.51 and 2 or 3
		return str,arrow
	end,

	dodge = function(amount)
		local str = "+"..amount..STRINGS_TB.DODGE
		local arrow = amount < 5.1 and 3 or amount < 10.1 and 2 or amount < 20.1 and 1 or 0
		return str,arrow
	end,

	crit = function(amount)
		local str = amount..STRINGS_TB.DODGE
		local arrow = amount < 1.1 and 0 or amount < 3.1 and 1 or amount < 5.1 and 2 or 3
		return str,arrow
	end,

	winterinsulation = function(amount)
		local str = "+"..amount..STRINGS_TB.WINTERINSULATION
		local arrow = amount < 41 and 0 or amount < 81 and 1 or amount < 121 and 2 or 3
		return str,arrow
	end,

	summerinsulation = function(amount)
		local str = "+"..amount..STRINGS_TB.SUMMERINSULATION
		local arrow = amount < 41 and 0 or amount < 81 and 1 or amount < 121 and 2 or 3
		return str,arrow
	end,

	worker = function(amount)
		local str = "+"..((amount-1)*100)..STRINGS_TB.WORKER
		local arrow = amount < 1.21 and 0 or amount < 1.41 and 1 or amount < 1.61 and 2 or 3
		return str,arrow
	end,

	sleeping = function(amount)
		local str = "+"..amount..STRINGS_TB.SLEEPING
		local arrow = amount < 0.21 and 0 or amount < 0.41 and 1 or amount < 0.61 and 2 or 3
		return str,arrow
	end,

	nightvision = function(amount)
		local str = STRINGS_TB.NIGHTVISION
		local arrow = 0
		return str,arrow
	end,

	speed = function(amount)
		local str = "+"..(amount*100)..STRINGS_TB.SPEED
		local arrow = amount < 0.051 and 0 or amount < 0.11 and 1 or amount < 0.21 and 2 or 3
		return str,arrow
	end,

	escapedeath = function(amount)
		local str = amount..STRINGS_TB.ESCAPEDEATH
		local arrow = amount < 1.1 and 0 or amount < 2.1 and 1 or amount < 3.1 and 2 or 3
		return str,arrow
	end,
}

local Temp_Boni = Class(Widget, function(self, owner)
	Widget._ctor(self,"Temp_Boni")

	self.owner = owner
	self.root = self:AddChild(Widget("ROOT"))

	self.button = self:AddChild(Image("images/victims.xml", "health.tex"))
	self.button:SetTooltip("test")
	self.button:SetTooltipPos(0,-50,0)

	local scale = 48 / math.max(self.button:GetSize())
	self.button:SetScale(scale, scale, scale)
	local w, h = self.button:GetSize()
	self.width = w * scale
	self.height = h * scale

	self.level = self.button:AddChild(Image("images/victims.xml", "arrow_1.tex"))
	self.level:SetScale(scale/1.7)

	--self.task = nil
	--self.time = nil

end)

function Temp_Boni:SetBoniPicture(boni,time)
	devprint("Temp_Boni:SetBoniPicture",boni,time)
	if boni then
		self:Show()
		if self.task ~= nil then
			self.task:Cancel()
			self.task = nil
		end
		local str = mysplit(boni,"_")
		devprint("str",str[1],str[2])
		local atlas = "images/victims.xml"
		local tex = str[1] or "health"
		devprint(atlas,tex)
		self.button:SetTexture(atlas,tex..".tex")
		local tooltip,num
		if string[str[1]] then
			tooltip,num = string[str[1]](tonumber(str[2]))
		end
		devprint("tooltip",tooltip,num)
		tooltip = tooltip or "Error"
		self.button:SetTooltip(tooltip.."\nTime left: "..toMin(time))
		self.time = time or 0
		if num and num > 0 and str[2] then
			local tex2 = "arrow_"..(num)..".tex"
			self.level:SetTexture(atlas,tex2)
			self.level:Show()
		else
			self.level:Hide()
		end
		self.task = self.inst:DoSimPeriodicTask(1, function()
			self.time = self.time - 1
			self.button:SetTooltip(tooltip.."\nTime left: "..toMin(self.time))
		end)
	end
end

function Temp_Boni:RemoveBoniPicture()
	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end
	self:Hide()
end


return Temp_Boni