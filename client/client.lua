--[[
 _                     
 /$$                       /$$                                     /$$                                  
| $$                      | $$                                    | $$                                  
| $$$$$$$  /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$          /$$$$$$ | $$  /$$$$$$   /$$$$$$  /$$$$$$/$$$$ 
| $$__  $$| $$  | $$ /$$__  $$ /$$__  $$|____  $$ /$$$$$$|____  $$| $$ |____  $$ /$$__  $$| $$_  $$_  $$
| $$  \ $$| $$  | $$| $$  | $$| $$  \__/ /$$$$$$$|______/ /$$$$$$$| $$  /$$$$$$$| $$  \__/| $$ \ $$ \ $$
| $$  | $$| $$  | $$| $$  | $$| $$      /$$__  $$        /$$__  $$| $$ /$$__  $$| $$      | $$ | $$ | $$
| $$  | $$|  $$$$$$$|  $$$$$$$| $$     |  $$$$$$$       |  $$$$$$$| $$|  $$$$$$$| $$      | $$ | $$ | $$
|__/  |__/ \____  $$ \_______/|__/      \_______/        \_______/|__/ \_______/|__/      |__/ |__/ |__/
           /$$  | $$                                                                                    
          |  $$$$$$/                                                                                    
           \______/         
Client script for Hydra Alarm
--]]


local cachedVehicles = {}
local soundLoopThreads = {}
local soundLoopActive = {}
local soundDistanceThreads = {}
local soundDistanceActive = {}
local latestServerAlarmStates = {}
local JUMP_PROXIMITY_RADIUS = 2.5

---@param plate string|nil
---@return string
local function normalizePlate(plate)
    if type(plate) ~= 'string' then
        return ''
    end

    return plate:gsub('^%s*(.-)%s*$', '%1'):upper()
end

---@param plate string
---@param alarmActive boolean
---@param reason string
---@return nil
local function requestServerAlarmState(plate, alarmActive, reason)
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return
    end

    TriggerServerEvent('hydra_alarm:serverSetAlarmState', normalizedPlate, alarmActive == true, reason)
end

---@class AlarmVehicleData
---@field handle number
---@field coords vector3
---@field health number
---@field alarmActive boolean
---@field isLocked boolean
---@field playerOnVehicle boolean
---@field alarmStartTime number
---@field isBeingTowed boolean
---@field lastAlarmTime number
---@field alarmReason string|nil

---@param modelName string|nil
---@return string
local function normalizeModelName(modelName)
    if type(modelName) ~= 'string' then
        return ''
    end

    return modelName:lower()
end

---@param modelList string[]|nil
---@return table<string, boolean>
local function buildModelLookup(modelList)
    local lookup = {}

    if type(modelList) ~= 'table' then
        return lookup
    end

    for _, modelName in ipairs(modelList) do
        local normalized = normalizeModelName(modelName)
        if normalized ~= '' then
            lookup[normalized] = true
        end
    end

    return lookup
end

local blacklistedVehicleLookup = buildModelLookup(Config.BlacklistedVehicles)
local towTruckLookup = buildModelLookup(Config.TowTrucks)

---@param value number|nil
---@return number
local function clampVolume(value)
    local numeric = tonumber(value) or 1.0
    if numeric < 0.0 then
        return 0.0
    end
    if numeric > 1.0 then
        return 1.0
    end
    return numeric
end

---@return number
local function getEffectiveAlarmVolume()
    local baseVolume = clampVolume(Config.InteractSoundVolume)
    local masterVolume = clampVolume(Config.MasterVolume)
    return clampVolume(baseVolume * masterVolume)
end

---@param vehicle number
---@return string
local function getVehicleModelName(vehicle)
    return normalizeModelName(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

---@param vehicle number
---@return boolean
local function isBlacklistedVehicle(vehicle)
    return blacklistedVehicleLookup[getVehicleModelName(vehicle)] == true
end

---@param vehicle number
---@return boolean
local function isTowTruckModel(vehicle)
    return towTruckLookup[getVehicleModelName(vehicle)] == true
end

---@param plate string
---@param vehicle number
---@return AlarmVehicleData
local function createVehicleData(plate, vehicle)
    plate = normalizePlate(plate)
    if plate == '' then
        return nil
    end

    local vehicleData = {
        handle = vehicle,
        coords = GetEntityCoords(vehicle),
        health = GetEntityHealth(vehicle),
        alarmActive = false,
        isLocked = GetVehicleDoorLockStatus(vehicle) > 1,
        playerOnVehicle = false,
        alarmStartTime = 0,
        isBeingTowed = false,
        lastAlarmTime = 0,
        alarmReason = nil,
    }

    cachedVehicles[plate] = vehicleData
    return vehicleData
end

---@param value any
---@return boolean
local function isRemoteAudioSource(value)
    return type(value) == 'string' and value:match('^https?://') ~= nil
end

---@return string|nil, string|nil
local function resolveNuiAudioSource()
    local mode = Config.NuiSoundMode or 'auto'
    local url = Config.NuiSoundUrl
    local file = Config.NuiSoundFile
    local soundName = Config.InteractSoundName

    if mode == 'url' and type(url) == 'string' and url ~= '' then
        return 'url', url
    end

    if mode == 'file' and type(file) == 'string' and file ~= '' then
        return 'file', file
    end

    if type(url) == 'string' and url ~= '' then
        return 'url', url
    end

    if type(file) == 'string' and file ~= '' then
        return 'file', file
    end

    if isRemoteAudioSource(soundName) then
        return 'url', soundName
    end

    if type(soundName) == 'string' and soundName:match('%.mp3$') then
        return 'file', soundName
    end

    return nil, nil
end

---@param vehicle number
---@return boolean
function isVehicleBeingTowed(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end

    -- Many towtruck setups attach the towed vehicle entity directly.
    if IsEntityAttached(vehicle) then
        local attachedTo = GetEntityAttachedTo(vehicle)
        if attachedTo and attachedTo ~= 0 and DoesEntityExist(attachedTo) and isTowTruckModel(attachedTo) then
            return true
        end
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    local nearbyVehicles = lib.getNearbyVehicles(vehicleCoords, Config.TowTruckCheckDistance, true)

    for _, towTruck in ipairs(nearbyVehicles) do
        local towTruckVeh = towTruck.vehicle
        if towTruckVeh ~= vehicle and isTowTruckModel(towTruckVeh) then
            if IsVehicleAttachedToTowTruck(towTruckVeh, vehicle) then
                return true
            end

            local hasTrailer, trailerVeh = GetVehicleTrailerVehicle(towTruckVeh)
            if hasTrailer and trailerVeh == vehicle then
                return true
            end

            if IsEntityAttachedToEntity(vehicle, towTruckVeh) then
                return true
            end
        end
    end

    return false
end

---@param vehicle number
---@param plate string
---@param reason string
---@param fromServer? boolean
---@return nil
function startVehicleAlarm(vehicle, plate, reason, fromServer)
    plate = normalizePlate(plate)

    if not DoesEntityExist(vehicle) then
        return
    end

    local vehicleData = cachedVehicles[plate]
    if not vehicleData then
        return
    end

    if vehicleData.alarmActive then
        return
    end

    vehicleData.alarmActive = true
    vehicleData.alarmStartTime = GetGameTimer()
    vehicleData.lastAlarmTime = GetGameTimer()
    vehicleData.alarmReason = reason

    latestServerAlarmStates[plate] = {
        alarmActive = true,
        reason = reason,
    }

    debugprint('ALARM triggered for: ' .. plate .. ' | Reason: ' .. reason .. (vehicleData.isBeingTowed and ' [TOWED]' or ''))
    TriggerEvent('vehicle:alarmStart', vehicle, plate, reason)

    CreateThread(function()
        while vehicleData and vehicleData.alarmActive and DoesEntityExist(vehicle) do
            SetVehicleLights(vehicle, 2)
            Wait(300)
            SetVehicleLights(vehicle, 1)
            Wait(300)
        end
    end)

    if Config.HornEnabled then
        startVehicleHorn(vehicle, plate)
    end

    playAlarmSound(vehicle, plate)

    if not fromServer then
        requestServerAlarmState(plate, true, reason)
    end
end

---@param vehicle number
---@param plate string
---@return nil
function startVehicleHorn(vehicle, plate)
    local vehicleData = cachedVehicles[plate]

    CreateThread(function()
        while vehicleData and vehicleData.alarmActive and DoesEntityExist(vehicle) do
            if Config.HornPattern == 'continuous' then
                SoundVehicleHornThisFrame(vehicle)
            elseif Config.HornPattern == 'pulse' then
                SoundVehicleHornThisFrame(vehicle)
                Wait(500)
                Wait(200)
            elseif Config.HornPattern == 'double' then
                SoundVehicleHornThisFrame(vehicle)
                Wait(300)
                SoundVehicleHornThisFrame(vehicle)
                Wait(800)
            end

            Wait(10)
        end
    end)
end

---@param vehicle number
---@param plate string
---@param fromServer? boolean
---@return nil
function stopVehicleAlarm(vehicle, plate, fromServer)
    plate = normalizePlate(plate)

    if not DoesEntityExist(vehicle) then
        return
    end

    local vehicleData = cachedVehicles[plate]
    if not vehicleData then
        return
    end

    if not vehicleData.alarmActive then
        return
    end

    vehicleData.alarmActive = false
    vehicleData.playerOnVehicle = false
    vehicleData.alarmStartTime = 0
    vehicleData.alarmReason = nil

    latestServerAlarmStates[plate] = nil

    debugprint('ALARM stopped for: ' .. plate)
    SetVehicleLights(vehicle, 0)
    stopAlarmSound(plate)

    TriggerEvent('vehicle:alarmStop', vehicle, plate)

    if not fromServer then
        requestServerAlarmState(plate, false, 'stopped')
    end
end

---@param vehicle number
---@param plate string
---@return nil
function playAlarmSound(vehicle, plate)
    local effectiveVolume = getEffectiveAlarmVolume()

    if GetResourceState('interact-sound') == 'started' then
        debugprint('Using InteractSound for alarm')
        exports['interact-sound']:playOnSource(Config.InteractSoundName, effectiveVolume)

        soundLoopActive[plate] = true
        soundLoopThreads[plate] = CreateThread(function()
            local vehicleData = cachedVehicles[plate]
            while vehicleData and vehicleData.alarmActive and soundLoopActive[plate] do
                Wait((Config.InteractSoundLength - Config.InteractSoundLoopOffset) * 1000)
                if vehicleData.alarmActive and soundLoopActive[plate] then
                    exports['interact-sound']:playOnSource(Config.InteractSoundName, effectiveVolume)
                end
            end

            soundLoopThreads[plate] = nil
        end)
        return
    end

    if GetResourceState('xsound') == 'started' then
        debugprint('Using xSound for alarm')
        TriggerEvent('xsound:PlayUrlStream', GetEntityCoords(vehicle), Config.InteractSoundName, effectiveVolume, Config.InteractSoundDistance)
        return
    end

    debugprint('Using NUI for alarm sound')
    local soundMode, soundSource = resolveNuiAudioSource()
    local maxDistance = Config.InteractSoundDistance or 25.0

    SendNUIMessage({
        type = 'play_alarm_sound',
        plate = plate,
        soundMode = soundMode,
        soundSource = soundSource,
        soundName = Config.InteractSoundName,
        soundUrl = Config.NuiSoundUrl,
        soundFile = Config.NuiSoundFile,
        volume = effectiveVolume,
        maxDistance = maxDistance,
        soundLength = Config.InteractSoundLength,
        soundLoopOffset = Config.InteractSoundLoopOffset,
    })

    soundDistanceActive[plate] = true
    soundDistanceThreads[plate] = CreateThread(function()
        while soundDistanceActive[plate] and DoesEntityExist(vehicle) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehicleCoords)

            SendNUIMessage({
                type = 'update_alarm_distance',
                plate = plate,
                currentDistance = distance,
                maxDistance = maxDistance,
                baseVolume = effectiveVolume,
            })

            Wait(Config.NuiDistanceUpdateInterval or 250)
        end

        soundDistanceThreads[plate] = nil
    end)
end

---@param plate string
---@return nil
function stopAlarmSound(plate)
    soundLoopActive[plate] = false
    soundLoopThreads[plate] = nil
    soundDistanceActive[plate] = false
    soundDistanceThreads[plate] = nil

    SendNUIMessage({
        type = 'stop_alarm_sound',
        plate = plate,
    })
end

AddEventHandler('vehicle:alarmStart', function(vehicle, plate, reason)
    SendNUIMessage({
        type = 'alarm_start',
        plate = plate,
        reason = reason,
    })
end)

AddEventHandler('vehicle:alarmStop', function(_, plate)
    SendNUIMessage({
        type = 'alarm_stop',
        plate = plate,
    })
end)

RegisterNetEvent('hydra_alarm:syncAlarmState', function(plate, alarmActive, reason)
    plate = normalizePlate(plate)
    if plate == '' then
        return
    end

    if alarmActive then
        latestServerAlarmStates[plate] = {
            alarmActive = true,
            reason = reason,
        }
    else
        latestServerAlarmStates[plate] = nil
    end

    local vehicleData = cachedVehicles[plate]
    if not vehicleData then
        return
    end

    if alarmActive and not vehicleData.alarmActive then
        startVehicleAlarm(vehicleData.handle, plate, reason or 'server_sync', true)
        return
    end

    if not alarmActive and vehicleData.alarmActive then
        stopVehicleAlarm(vehicleData.handle, plate, true)
    end
end)

RegisterNetEvent('hydra_alarm:stopAllAlarms', function()
    for plate, vehicleData in pairs(cachedVehicles) do
        if vehicleData.alarmActive then
            stopVehicleAlarm(vehicleData.handle, plate, true)
        end
    end

    latestServerAlarmStates = {}
    SendNUIMessage({ type = 'stop_alarm_sound' })
end)

CreateThread(function()
    while true do
        Wait(Config.CACHE_INTERVAL or 1000)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearbyVehicles = lib.getNearbyVehicles(playerCoords, Config.CacheDistance or 20, true)
        local currentPlates = {}

        for _, vehicleEntry in ipairs(nearbyVehicles) do
            local vehicle = vehicleEntry.vehicle
            if not isBlacklistedVehicle(vehicle) then
                local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
                if plate == '' then
                    goto continue_nearby_vehicle
                end

                currentPlates[plate] = true

                local vehicleData = cachedVehicles[plate]
                if not vehicleData then
                    vehicleData = createVehicleData(plate, vehicle)
                    debugprint('Vehicle added to cache: ' .. plate)
                else
                    vehicleData.coords = GetEntityCoords(vehicle)
                    vehicleData.isLocked = GetVehicleDoorLockStatus(vehicle) > 1
                end

                local serverState = latestServerAlarmStates[plate]
                if serverState and serverState.alarmActive and not vehicleData.alarmActive then
                    startVehicleAlarm(vehicleData.handle, plate, serverState.reason or 'server_sync', true)
                end
            end

            ::continue_nearby_vehicle::
        end

        for plate, vehicleData in pairs(cachedVehicles) do
            if not currentPlates[plate] then
                if vehicleData.alarmActive then
                    stopVehicleAlarm(vehicleData.handle, plate, true)
                end

                debugprint('Vehicle removed from cache: ' .. plate)
                cachedVehicles[plate] = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.ServerSyncInterval or 1500)

        local nearbyPlates = {}
        for plate, vehicleData in pairs(cachedVehicles) do
            if DoesEntityExist(vehicleData.handle) then
                nearbyPlates[#nearbyPlates + 1] = plate
            end
        end

        if #nearbyPlates > 0 then
            local serverStates = lib.callback.await('hydra_alarm:getNearbyAlarmStates', false, nearbyPlates) or {}
            local returnedStates = {}

            for plate, state in pairs(serverStates) do
                local normalizedPlate = normalizePlate(plate)
                returnedStates[normalizedPlate] = true
                latestServerAlarmStates[normalizedPlate] = state

                local vehicleData = cachedVehicles[normalizedPlate]
                if vehicleData and state.alarmActive and not vehicleData.alarmActive then
                    startVehicleAlarm(vehicleData.handle, normalizedPlate, state.reason or 'server_sync', true)
                end
            end

            -- If server no longer reports an alarm for a nearby plate, clear local cached state and stop it.
            for _, plate in ipairs(nearbyPlates) do
                local normalizedPlate = normalizePlate(plate)
                if not returnedStates[normalizedPlate] then
                    latestServerAlarmStates[normalizedPlate] = nil

                    local vehicleData = cachedVehicles[normalizedPlate]
                    if vehicleData and vehicleData.alarmActive then
                        stopVehicleAlarm(vehicleData.handle, normalizedPlate, true)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)

        for _, vehicleData in pairs(cachedVehicles) do
            if DoesEntityExist(vehicleData.handle) then
                vehicleData.isBeingTowed = isVehicleBeingTowed(vehicleData.handle)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.ProximityCheckInterval or 50)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for plate, vehicleData in pairs(cachedVehicles) do
            if DoesEntityExist(vehicleData.handle) then
                local isLocked = GetVehicleDoorLockStatus(vehicleData.handle) > 1

                -- Stop tow-triggered alarm immediately when vehicle is no longer being towed.
                if vehicleData.alarmActive and vehicleData.alarmReason == 'being_towed' and not vehicleData.isBeingTowed then
                    debugprint('Vehicle untowed, stopping tow alarm: ' .. plate)
                    stopVehicleAlarm(vehicleData.handle, plate)
                end

                if vehicleData.alarmActive and not isLocked then
                    debugprint('Vehicle unlocked, stopping alarm: ' .. plate)
                    stopVehicleAlarm(vehicleData.handle, plate)
                end

                local alarmDuration = (vehicleData.isBeingTowed and Config.TowTruckAlarmDuration or Config.AlarmDuration) * 1000
                if vehicleData.alarmActive and (GetGameTimer() - vehicleData.alarmStartTime) >= alarmDuration then
                    debugprint('Alarm duration expired for: ' .. plate)
                    stopVehicleAlarm(vehicleData.handle, plate)
                end

                vehicleData.isLocked = isLocked

                if (GetGameTimer() - vehicleData.lastAlarmTime) < (Config.AlarmCooldown * 1000) then
                    goto continue_vehicle
                end

                if isLocked then
                    local vehicleCoords = GetEntityCoords(vehicleData.handle)
                    local distance = #(playerCoords - vehicleCoords)

                    if distance < JUMP_PROXIMITY_RADIUS then
                        local playerHeight = playerCoords.z
                        local vehicleHeight = vehicleCoords.z

                        if playerHeight > vehicleHeight + Config.JumpHeightThreshold then
                            if not vehicleData.playerOnVehicle then
                                vehicleData.playerOnVehicle = true
                                if not vehicleData.alarmActive then
                                    startVehicleAlarm(vehicleData.handle, plate, 'jump_on')
                                end
                            end
                        else
                            vehicleData.playerOnVehicle = false
                        end
                    else
                        vehicleData.playerOnVehicle = false
                    end

                    local currentHealth = GetEntityHealth(vehicleData.handle)
                    local healthLoss = vehicleData.health - currentHealth
                    if healthLoss > Config.MinimumDamageThreshold and not vehicleData.alarmActive then
                        startVehicleAlarm(vehicleData.handle, plate, 'damage')
                    end

                    vehicleData.health = currentHealth

                    if Config.TowTruckAlarm and vehicleData.isBeingTowed and not vehicleData.alarmActive then
                        startVehicleAlarm(vehicleData.handle, plate, 'being_towed')
                    end
                else
                    vehicleData.health = GetEntityHealth(vehicleData.handle)
                    vehicleData.playerOnVehicle = false
                end

                ::continue_vehicle::
            else
                -- Vehicle was deleted, clean up alarm and data
                if vehicleData.alarmActive then
                    debugprint('Vehicle deleted, stopping alarm: ' .. plate)
                    stopAlarmSound(plate)
                    vehicleData.alarmActive = false
                end
                cachedVehicles[plate] = nil
            end
        end
    end
end)

-- =========================
-- Exports
-- =========================

---@param vehicle number
---@param reason string|nil
---@return boolean
exports('startAlarm', function(vehicle, reason)
    if not DoesEntityExist(vehicle) then
        debugprint('Export error: Vehicle does not exist')
        return false
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local vehicleData = cachedVehicles[plate] or createVehicleData(plate, vehicle)
    if not vehicleData then
        return false
    end

    if vehicleData.alarmActive then
        debugprint('Export: Alarm already active for ' .. plate)
        return false
    end

    reason = reason or 'manual_trigger'
    startVehicleAlarm(vehicle, plate, reason)
    debugprint('Export: Started alarm for ' .. plate .. ' | Reason: ' .. reason)
    return true
end)

---@param vehicle number
---@return boolean
exports('stopAlarm', function(vehicle)
    if not DoesEntityExist(vehicle) then
        debugprint('Export error: Vehicle does not exist')
        return false
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    if plate == '' then
        return false
    end
    local vehicleData = cachedVehicles[plate]

    if not vehicleData or not vehicleData.alarmActive then
        debugprint('Export: No active alarm for ' .. plate)
        return false
    end

    stopVehicleAlarm(vehicle, plate)
    debugprint('Export: Stopped alarm for ' .. plate)
    return true
end)

---@param vehicle number
---@return boolean
exports('hasAlarm', function(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end

    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    if plate == '' then
        return false
    end
    local vehicleData = cachedVehicles[plate]
    return vehicleData and vehicleData.alarmActive or false
end)

---@return table[]
exports('getActiveAlarms', function()
    local alarms = {}

    for plate, vehicleData in pairs(cachedVehicles) do
        if vehicleData.alarmActive then
            table.insert(alarms, {
                plate = plate,
                handle = vehicleData.handle,
                isBeingTowed = vehicleData.isBeingTowed,
                alarmTime = GetGameTimer() - vehicleData.alarmStartTime,
            })
        end
    end

    return alarms
end)