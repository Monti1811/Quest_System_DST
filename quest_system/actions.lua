------------------------------Actions-------------------------------------
local unpack = GLOBAL.unpack

--Add the teleport function to the lavaarena portal
local old_jumpin = GLOBAL.ACTIONS.JUMPIN.fn
GLOBAL.ACTIONS.JUMPIN.fn = function(act,...)
	if act.doer and act.doer.sg and act.target ~= nil then
		if act.doer.sg.currentstate.name == "jumpin_pre" then
			if act.target.prefab == "lavaarena_portal" then
				act.target:TeleportTo(act.doer)
				return true
			end
		end
	end
	return unpack({old_jumpin(act,...)})
end

--Add an event if a player is fed by another player
local old_FEEDPLAYER = GLOBAL.ACTIONS.FEEDPLAYER.fn
GLOBAL.ACTIONS.FEEDPLAYER.fn = function(act,...)
	local ret,msg = old_FEEDPLAYER(act,...)
	if ret then
		local was_starving = act.target.components.hunger and act.target.components.hunger:IsStarving()
		act.doer:PushEvent("onfeedplayer",{player = act.target,was_starving = was_starving})
		return ret,msg
	end
end

--Add an event if a player is fed by another player
local old_GIVE = GLOBAL.ACTIONS.GIVE.fn
GLOBAL.ACTIONS.GIVE.fn = function(act,...)
	local ret,msg = old_GIVE(act,...)
	if ret and act.target.components.trader then
		act.doer:PushEvent("fed_creature",{target = act.target,food = act.invobject})
		return ret,msg
	end
end

--Add the jump action to the lavaarena portal
AddComponentAction("SCENE", "teleporter", function(inst, doer, actions, right)
	if inst:HasTag("teleporter_boss_island") and inst:HasTag("can_be_used") and doer:HasTag("won_against_boss") then
		table.insert(actions, GLOBAL.ACTIONS.JUMPIN)
	end
end)

--Add the read action to the quest board
local old_read = GLOBAL.ACTIONS.READ.fn
GLOBAL.ACTIONS.READ.fn = function(act,...)
	if act.doer and act.target ~= nil and act.target.prefab == "questboard" then
		SendModRPCToClient(GetClientModRPC("Quest_System_RPC", "ShowQuestBoard"),act.doer.userid,act.doer)
		return true
	end
	return unpack({old_read(act,...)})
end

AddComponentAction("SCENE", "simplebook", function(inst, doer, actions, right)
	if inst:HasTag("questboard") then
		table.insert(actions, GLOBAL.ACTIONS.READ)
	end
end)

local function ReadQuestBoard(self)
	local old_actionhandler_read = self.actionhandlers[GLOBAL.ACTIONS.READ].deststate
	self.actionhandlers[GLOBAL.ACTIONS.READ].deststate = function(inst,action,...)
		local target = action.target or action.invobject
		if target and target:HasTag("questboard") then
			return "doshortaction"
		else
			return unpack({old_actionhandler_read(inst,action,...)})
		end
	end
end

AddStategraphPostInit("wilson", ReadQuestBoard)
AddStategraphPostInit("wilson_client", ReadQuestBoard)


--Add an event if a vegetable is harvested
local veggies = {}
for k,v in pairs(require("prefabs/farm_plant_defs").PLANT_DEFS) do
	table.insert(veggies,k)
end

local function CheckifVeg(prefab)
	for k,v in ipairs(veggies) do
		if v == prefab then
			return true
		end
	end
end

local old_pick = GLOBAL.ACTIONS.PICK.fn
GLOBAL.ACTIONS.PICK.fn = function(act,...)
	if act.target ~= nil and (act.target:HasTag("oversized_veggie") or CheckifVeg(act.target.prefab)) then
		act.doer:PushEvent("harvested_veg",act.target) --todo: check if this is needed or if the postinitfn is enough
	end
	return old_pick(act,...)
end

--Add an activable action to the glommer statue
local FIGHT_GLOMMER = AddAction("FIGHT_GLOMMER",GLOBAL.STRINGS.QUEST_COMPONENT.ACTIONS.FIGHT_GLOMMER,function(act)
	if act.target.components.activatable ~= nil and act.target.components.activatable:CanActivate(act.doer) then
        local success,msg = act.target.components.activatable:DoActivate(act.doer)
        devprint("FIGHT_GLOMMER",success,msg)
        return (success ~= false),msg
    end
end)

AddComponentAction("SCENE", "activatable", function(inst, doer, actions, right)
	if right and doer:HasTag("can_fight_glommer") and inst.prefab == "statueglommer" then
		table.insert(actions, FIGHT_GLOMMER)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(FIGHT_GLOMMER, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(FIGHT_GLOMMER, "dolongaction"))

--Add an activable action to the glommer statue
local SHADOW_ROOK_ATTACK = AddAction("SHADOW_ROOK_ATTACK",GLOBAL.STRINGS.QUEST_COMPONENT.ACTIONS.SHADOW_ROOK_ATTACK,function(act)
	if act.target and act.doer and act.doer.components.inventory then
		local head = act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
		if head and head.prefab == "shadow_crest" and head:HasTag("able_to_attack") then
			head:RookAttack(act.doer,act.target)
			return true
		end
	end
end)
SHADOW_ROOK_ATTACK.distance = 12

AddComponentAction("SCENE", "combat", function(inst, doer, actions, right)
	if right and doer.replica.inventory and doer ~= inst then
		local head = doer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
		if head and head.prefab == "shadow_crest" and head:HasTag("able_to_attack") then
			table.insert(actions, SHADOW_ROOK_ATTACK)
		end
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(SHADOW_ROOK_ATTACK, "doequippedaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(SHADOW_ROOK_ATTACK, "doequippedaction"))

--Add a pickup action for nightmarechester
local function ExtraPickupRange(doer, dest)
	if dest ~= nil then
		local target_x, target_y, target_z = dest:GetPoint()

		local is_on_water = GLOBAL.TheWorld.Map:IsOceanTileAtPoint(target_x, 0, target_z) and not GLOBAL.TheWorld.Map:IsPassableAtPoint(target_x, 0, target_z)
		if is_on_water then
			return 0.75
		end
	end
	return 0
end

local CHESTER_PICKUP = GLOBAL.Action({ priority=1, extra_arrive_dist=ExtraPickupRange, mount_valid=true })
CHESTER_PICKUP.id = "CHESTER_PICKUP"
CHESTER_PICKUP.priority = 5
CHESTER_PICKUP.fn =  function(act)
	local container = act.doer.components.container_proxy
			and act.doer.components.container_proxy:GetMaster()
			and act.doer.components.container_proxy:GetMaster().components.container
			or act.doer.components.container or nil
	if container ~= nil then
		act.doer:PushEvent("onpickupitem", { item = act.target })
		act.doer.components.container:GiveItem(act.target, nil, act.target:GetPosition())
		return true
	end
end

AddAction(CHESTER_PICKUP)

AddStategraphActionHandler("chester", GLOBAL.ActionHandler(CHESTER_PICKUP, "chomp_item"))

--Add a rightclick option to enable/disable pickup chester
local PICKUP_TOGGLE = AddAction("PICKUP_TOGGLE", "Pickup toggle",function(act)
	if act.target then
		if act.target:HasTag("can_do_pickup") then
			act.target:RemoveTag("can_do_pickup")
		else
			act.target:AddTag("can_do_pickup")
		end
	end
end)

PICKUP_TOGGLE.strfn = function(act)
	if act.target then
		if act.target:HasTag("can_do_pickup") then
			devprint("DISABLE", GLOBAL.STRINGS.ACTIONS.PICKUP_TOGGLE.DISABLE)
			return "DISABLE"
		else
			return "ENABLE"
		end
	end
end

GLOBAL.STRINGS.ACTIONS.PICKUP_TOGGLE = {}
GLOBAL.STRINGS.ACTIONS.PICKUP_TOGGLE.DISABLE = "Disable Pickup ability"
GLOBAL.STRINGS.ACTIONS.PICKUP_TOGGLE.ENABLE = "Enable Pickup ability"

AddComponentAction("SCENE", "container", function(inst, doer, actions, right)
	if right and inst.prefab == "nightmarechester" then
		table.insert(actions, PICKUP_TOGGLE)
	end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(PICKUP_TOGGLE, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(PICKUP_TOGGLE, "dolongaction"))
