local activeAlarms = {}
local lastAlarmTimes = {}
local vehicleLastDamage = {}
local towedAlarmActive = {}

local function hasAlarm(vehicle)
    local model = GetEntityModel(vehicle)
    return not Config.BlacklistedVehicles[model]
end

local function canTriggerAlarm(veh)
    local t = lastAlarmTimes[veh] or 0
    return (GetGameTimer() - t) > (Config.AlarmCooldown * 1000)
end

local function setAlarmActive(veh)
    activeAlarms[veh] = true
    lastAlarmTimes[veh] = GetGameTimer()
    CreateThread(function()
        Wait(Config.AlarmCooldown * 1000)
        activeAlarms[veh] = nil
    end)
end

-- Damage-State für "nur neuer Schaden nach Abschließen"
local function getVehicleDamageState(veh)
    local state = {
        health = GetEntityHealth(veh),
        tyres = {},
        windows = {},
        doors = {},
        onfire = IsEntityOnFire(veh),
    }
    for i = 0, 5 do state.tyres[i] = IsVehicleTyreBurst(veh, i, false) end
    for i = 0, 7 do state.windows[i] = not IsVehicleWindowIntact(veh, i) end
    for i = 0, 5 do state.doors[i] = GetVehicleDoorAngleRatio(veh, i) > 0.1 end
    return state
end

local function isNewDamage(old, now)
    if not old then return true end
    if now.health < old.health then return true end
    for i = 0, 5 do if now.tyres[i] and not old.tyres[i] then return true end end
    for i = 0, 7 do if now.windows[i] and not old.windows[i] then return true end end
    for i = 0, 5 do if now.doors[i] and not old.doors[i] then return true end end
    if now.onfire and not old.onfire then return true end
    return false
end

local function getNearbyTowtruck(veh, radius)
    local myCoords = GetEntityCoords(veh)
    local handle, tow = FindFirstVehicle()
    local foundTow = nil
    local success
    repeat
        if DoesEntityExist(tow) and tow ~= veh then
            local model = GetEntityModel(tow)
            if Config.TowTrucks[model] then
                local towCoords = GetEntityCoords(tow)
                local dist = #(myCoords - towCoords)
                if dist < (radius or 4.0) then
                    foundTow = tow
                    break
                end
            end
        end
        success, tow = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return foundTow
end

-- EXPORTS
exports('isAlarmActive', function(vehicle)
    return activeAlarms[vehicle] or false
end)
exports('triggerAlarm', function(vehicle)
    if not activeAlarms[vehicle] and canTriggerAlarm(vehicle) then
        TriggerServerEvent('hydraalarm:triggerAlarm', VehToNet(vehicle), false)
        setAlarmActive(vehicle)
    end
end)

-- 1. Beim Abschließen Schaden merken / resetten
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local vehicles = {}
        local handle, veh = FindFirstVehicle()
        local success
        repeat
            if DoesEntityExist(veh) and #(GetEntityCoords(veh) - coords) < 25.0 and hasAlarm(veh) then
                table.insert(vehicles, veh)
            end
            success, veh = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)

        for _, veh in ipairs(vehicles) do
            local locked = GetVehicleDoorLockStatus(veh) == 2
            if locked and not vehicleLastDamage[veh] then
                vehicleLastDamage[veh] = getVehicleDamageState(veh)
            elseif not locked and vehicleLastDamage[veh] then
                vehicleLastDamage[veh] = nil
            end
        end
    end
end)

-- 2. Überwache auf Schaden, Brand, Aufbrechen, Abschleppen – Alarm nur bei neuem Schaden!
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local vehicles = {}
        local handle, veh = FindFirstVehicle()
        local success
        repeat
            if DoesEntityExist(veh) and #(GetEntityCoords(veh) - coords) < 25.0 and hasAlarm(veh) then
                table.insert(vehicles, veh)
            end
            success, veh = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)

        for _, veh in ipairs(vehicles) do
            -- Abschlepp-Alarm darf nicht mehrfach feuern!
            local attachedTo = GetEntityAttachedTo(veh)
            local towDetected = false

            if attachedTo and attachedTo ~= 0 and Config.TowTrucks[GetEntityModel(attachedTo)] then
                towDetected = true
            else
                local tow = getNearbyTowtruck(veh, Config.TowtruckDetectionRadius or 4.0)
                if tow then towDetected = true end
            end

            if towDetected then
                if not towedAlarmActive[veh] and not activeAlarms[veh] and canTriggerAlarm(veh) and GetVehicleDoorLockStatus(veh) == 2 then
                    print("[hydra_alarm] Abschlepp-Alarm: Vehicle", veh, "attached an Towtruck!")
                    towedAlarmActive[veh] = true
                    TriggerServerEvent('hydraalarm:triggerAlarm', VehToNet(veh), true)
                    setAlarmActive(veh)
                end
            else
                -- Wenn Fahrzeug nicht mehr abgeschleppt wird, Reset für nächsten Tow-Alarm
                towedAlarmActive[veh] = nil
            end

            -- Normale Schadenerkennung wie gehabt
            if not towDetected and not activeAlarms[veh] and canTriggerAlarm(veh) and GetVehicleDoorLockStatus(veh) == 2 then
                local old = vehicleLastDamage[veh]
                local now = getVehicleDamageState(veh)
                if isNewDamage(old, now) then
                    TriggerServerEvent('hydraalarm:triggerAlarm', VehToNet(veh), false)
                    setAlarmActive(veh)
                    vehicleLastDamage[veh] = getVehicleDamageState(veh)
                end
            end
        end
    end
end)

RegisterNetEvent('hydraalarm:playAlarm', function(netid, isTowing)
    local veh = NetToVeh(netid)
    if not DoesEntityExist(veh) then return end

    local alarmTime = Config.AlarmDuration or 20
    local soundName = Config.InteractSoundName or 'alarm'
    local soundLen = Config.InteractSoundLength or 11
    local loopOffset = Config.InteractSoundLoopOffset or 1
    local loops = math.ceil(alarmTime / (soundLen - loopOffset))
    local running = true
    local totalEnd = GetGameTimer() + (alarmTime * 1000)

    -- Sound + Hupe in Schleife
    CreateThread(function()
        for i = 1, loops do
            if not running then break end
            TriggerServerEvent(
                'InteractSound_SV:PlayWithinDistance',
                Config.InteractSoundDistance or 25.0,
                soundName,
                Config.InteractSoundVolume or 1.0
            )
            local playTime = (soundLen - loopOffset) * 1000
            local endTime = GetGameTimer() + playTime
            while GetGameTimer() < endTime and running and GetGameTimer() < totalEnd do
                if GetVehicleDoorLockStatus(veh) ~= 2 then
                    running = false
                    break
                end
                -- Hupe an
                SetVehicleHornEnabled(veh, true)
                Wait(100)
            end
            if not running or GetGameTimer() >= totalEnd then break end
        end
    end)

    -- Scheinwerfer-Blink synchron zur Gesamtdauer
    CreateThread(function()
        while running and GetGameTimer() < totalEnd do
            if GetVehicleDoorLockStatus(veh) ~= 2 then
                running = false
                break
            end
            SetVehicleLights(veh, 2)
            local wait1 = math.min(400, totalEnd - GetGameTimer())
            Wait(wait1)
            if not running or GetGameTimer() >= totalEnd then break end
            SetVehicleLights(veh, 0)
            local wait2 = math.min(200, totalEnd - GetGameTimer())
            Wait(wait2)
        end
    end)

    -- Master-Warte-Schleife, steuert das Ende
    while running and GetGameTimer() < totalEnd do
        if GetVehicleDoorLockStatus(veh) ~= 2 then
            running = false
            break
        end
        Wait(100)
    end

    SetVehicleLights(veh, 0)
    SetVehicleHornEnabled(veh, false)
    TriggerServerEvent('InteractSound_SV:StopSound', soundName)
    towedAlarmActive[veh] = nil
end)