-- Config laden
Config = Config or {}
local alarmVehicles = {}

local function debugPrint(msg)
    if Config.Debug then
        print(msg)
    end
end

-- Blacklist aus Config
local vehicleBlacklist = Config.VehicleBlacklist or {}

-- Helper: Check ob Fahrzeugmodell auf Blacklist steht
local function isBlacklistedVehicle(veh)
    local model = GetEntityModel(veh)
    local modelName = GetDisplayNameFromVehicleModel(model)
    modelName = string.upper(modelName)
    for _, blacklisted in ipairs(vehicleBlacklist) do
        if modelName == blacklisted then
            return true
        end
    end
    return false
end

-- Helper: Fahrzeug abgeschlossen?
local function isVehicleLocked(veh)
    local lockStatus = GetVehicleDoorLockStatus(veh)
    return lockStatus == 2 or lockStatus == 3 or lockStatus == 4 -- Locked
end

RegisterNetEvent('carAlarm:triggerAlarm', function(vehNetId)
    local veh = NetToVeh(vehNetId)
    if DoesEntityExist(veh) then
        SetVehicleAlarm(veh, true)
        StartVehicleAlarm(veh)
        StartVehicleHorn(veh, Config.AlarmDuration or 3000, GetHashKey("HELDDOWN"), false)
    end
end)

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            debugPrint('Player is in a vehicle, skipping alarm check.')
        else
            for veh in EnumerateVehicles() do
                if not isBlacklistedVehicle(veh) and isVehicleLocked(veh) then
                    local vehNetId = NetworkGetNetworkIdFromEntity(veh)

                    if IsEntityTouchingEntity(ped, veh) and not alarmVehicles[vehNetId] then
                        TriggerServerEvent('carAlarm:serverTrigger', vehNetId)
                        alarmVehicles[vehNetId] = true
                    end

                    for i = 0, 7 do
                        if IsVehicleWindowIntact(veh, i) == false and not alarmVehicles[vehNetId] then
                            TriggerServerEvent('carAlarm:serverTrigger', vehNetId)
                            alarmVehicles[vehNetId] = true
                            break
                        end
                    end

                    if IsEntityOnFire(veh) and not alarmVehicles[vehNetId] then
                        TriggerServerEvent('carAlarm:serverTrigger', vehNetId)
                        alarmVehicles[vehNetId] = true
                    end
                end
            end
        end
    end
end)

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        if not veh or veh == 0 then
            EndFindVehicle(handle)
            return
        end

        local success
        repeat
            coroutine.yield(veh)
            success, veh = FindNextVehicle(handle)
        until not success

        EndFindVehicle(handle)
    end)
end

exports('TriggerAlarm', function(vehNetId)
    local veh = NetToVeh(vehNetId)
    if DoesEntityExist(veh) then
        SetVehicleAlarm(veh, true)
        StartVehicleAlarm(veh)
        StartVehicleHorn(veh, Config.AlarmDuration or 3000, GetHashKey("HELDDOWN"), false)
    end
end)

exports('TriggerAlarmServer', function(vehNetId)
    TriggerClientEvent('carAlarm:triggerAlarm', -1, vehNetId)
end)