RegisterNetEvent('carAlarm:serverTrigger', function(vehNetId)
    TriggerClientEvent('carAlarm:triggerAlarm', -1, vehNetId)
end)
