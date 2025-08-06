local activeAlarms = {}

-- Hilfsfunktion: Hat das Fahrzeug eine Alarmanlage?
local function hasAlarm(vehicle)
    local model = GetEntityModel(vehicle)
    return not Config.BlacklistedVehicles[model]
end

-- Hauptüberwachung
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local vehicleList = lib.getNearbyVehicles(coords, 25.0) or {}

        for _, veh in pairs(vehicleList) do
            if veh and DoesEntityExist(veh) and hasAlarm(veh) then
                -- Checke, ob der Spieler das Fahrzeug beschädigt hat
                if not activeAlarms[veh] then
                    if GetEntityHealth(veh) < 1000 then
                        TriggerServerEvent('fivemcaralarm:triggerAlarm', VehToNet(veh))
                        activeAlarms[veh] = true
                        Wait(Config.AlarmCooldown * 1000)
                        activeAlarms[veh] = nil
                    else
                        -- Checke auf andere Events (Reifen zerstören, Scheiben etc.)
                        for i = 0, 5 do
                            if IsVehicleTyreBurst(veh, i, false) then
                                TriggerServerEvent('fivemcaralarm:triggerAlarm', VehToNet(veh))
                                activeAlarms[veh] = true
                                Wait(Config.AlarmCooldown * 1000)
                                activeAlarms[veh] = nil
                                break
                            end
                        end
                        for i = 0, 7 do
                            if not IsVehicleWindowIntact(veh, i) then
                                TriggerServerEvent('fivemcaralarm:triggerAlarm', VehToNet(veh))
                                activeAlarms[veh] = true
                                Wait(Config.AlarmCooldown * 1000)
                                activeAlarms[veh] = nil
                                break
                            end
                        end
                        -- Optional: Türen aufbrechen
                        for i = 0, 5 do
                            if GetVehicleDoorAngleRatio(veh, i) > 0.1 then
                                TriggerServerEvent('fivemcaralarm:triggerAlarm', VehToNet(veh))
                                activeAlarms[veh] = true
                                Wait(Config.AlarmCooldown * 1000)
                                activeAlarms[veh] = nil
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Empfang vom Server: Alarm abspielen
RegisterNetEvent('fivemcaralarm:playAlarm', function(netid)
    local veh = NetToVeh(netid)
    if not DoesEntityExist(veh) then return end
    local alarmTime = Config.AlarmDuration
    local alarmSound = Config.AlarmSound
    local alarmRef = Config.AlarmSoundRef

    -- Notification
    lib.notify({
        title = 'Fahrzeugalarm!',
        description = 'Ein Autoalarm wurde ausgelöst!',
        type = 'alert'
    })

    -- Sound & Blinken
    for i = 1, alarmTime do
        -- Alarm-Sound
        PlaySoundFromEntity(-1, alarmSound, veh, alarmRef, false, 0)
        -- Lichter blinken
        SetVehicleLights(veh, math.random(1,2))
        Wait(750)
        SetVehicleLights(veh, 0)
        Wait(250)
    end
    SetVehicleLights(veh, 0)
end)
