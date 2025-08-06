RegisterNetEvent('hydra_alarm:triggerAlarm', function(vehNetId)
    TriggerClientEvent('hydra_alarm:playAlarm', -1, vehNetId)
end)
