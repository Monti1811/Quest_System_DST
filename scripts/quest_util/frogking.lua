local function SpawnFrogRain(inst,color)	
	local _frogs = {}
	local _scheduledtasks = {}
	local _activeplayers = {}
	for k,v in ipairs(AllPlayers) do
		_activeplayers[k] = v
	end
	local _updating = false
	local function OnPlayerJoined(src, player)
	    for i, v in ipairs(_activeplayers) do
	        if v == player then
	            return
	        end
	    end
	    table.insert(_activeplayers, player)
	    if _updating then
	        ScheduleSpawn(player, true)
	    end
	end
	local function CancelSpawn(player)
	    if _scheduledtasks[player] ~= nil then
	        _scheduledtasks[player]:Cancel()
	        _scheduledtasks[player] = nil
	    end
	end
	local function AutoRemoveTarget(inst, target)
	    if _frogs[target] ~= nil and target:IsAsleep() then
	        target:Remove()
	    end
	end
	local function OnPlayerLeft(src, player)
	    for i, v in ipairs(_activeplayers) do
	        if v == player then
	            CancelSpawn(player)
	            table.remove(_activeplayers, i)
	            return
	        end
	    end
	end
	local function OnTargetSleep(target)
	    inst:DoTaskInTime(0, AutoRemoveTarget, target)
	end
	local function StopTrackingFn(target)
	    local restore = _frogs[target]
	    if restore ~= nil then
	        target.persists = restore
	        _frogs[target] = nil
	        inst:RemoveEventCallback("entitysleep", OnTargetSleep, target)
	    end
	end
	
	local function StartTrackingFn(target)
		_frogs[target] = target.persists == true
	    target.persists = false
	    inst:ListenForEvent("entitysleep", OnTargetSleep, target)
	    inst:ListenForEvent("onremove", StopTrackingFn, target)
	    inst:ListenForEvent("enterlimbo", StopTrackingFn, target)
	    inst:ListenForEvent("exitlimbo", StartTrackingFn, target)
	end
	local function GetSpawnPoint(pt)
	    local function TestSpawnPoint(offset)
	        local spawnpoint = pt + offset
	        return TheWorld.Map:IsAboveGroundAtPoint(spawnpoint:Get())
	    end

	    local theta = math.random() * 2 * PI
	    local radius = math.random() * TUNING.FROG_RAIN_SPAWN_RADIUS
	    local resultoffset = FindValidPositionByFan(theta, radius, 12, TestSpawnPoint)

	    if resultoffset ~= nil then
	        return pt + resultoffset
	    end
	end

	local function SpawnFrog(spawn_point)
	    local frog = SpawnPrefab("frog")
	    if color then
	    	--frog.AnimState:SetMultColour(0.1,0.1,0.1,1)
			frog.AnimState:SetMultColour(unpack(color))
	    	--frog.AnimState:SetAddColour(unpack(color))
	    end
	    frog.persists = false
	    if math.random() < .5 then
	        frog.Transform:SetRotation(180)
	    end
	    frog.sg:GoToState("fall")
	    frog.Physics:Teleport(spawn_point.x, 35, spawn_point.z)
	    return frog
	end

	local FROGS_MUST_TAGS = { "frog" }
	local function SpawnFrogForPlayer(player, reschedule)
	    local pt = player:GetPosition()
		local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, TUNING.FROG_RAIN_MAX_RADIUS, FROGS_MUST_TAGS)
		if #ents < 50 then
			local spawn_point = GetSpawnPoint(pt)
			if spawn_point ~= nil then
	            -- print("Spawning a frog for player ",player)
				local frog = SpawnFrog(spawn_point)
				StartTrackingFn(frog)
			end
		end
	    _scheduledtasks[player] = nil
	    reschedule(player)
	end
	local function ScheduleSpawn(player, initialspawn)
	    if _scheduledtasks[player] == nil then
	        _scheduledtasks[player] = player:DoTaskInTime(math.random()+0.1, SpawnFrogForPlayer, ScheduleSpawn)
	    end
	end
	local function FrogRain(inst,force)
		if not _updating then
            _updating = true
            for i, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
	    elseif _updating then
	        _updating = false
	        for i, v in ipairs(_activeplayers) do
	            CancelSpawn(v)
	        end
	    end
	end
	local function StopFrogRain(inst)
		inst:RemoveEventCallback("ms_playerjoined", OnPlayerJoined, TheWorld)
		inst:RemoveEventCallback("ms_playerleft", OnPlayerLeft, TheWorld)
		for k,v in ipairs(_activeplayers) do
			CancelSpawn(v)
		end
	end
	inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
	inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
	return FrogRain, StopFrogRain
end

return {SpawnFrogRain = SpawnFrogRain}
