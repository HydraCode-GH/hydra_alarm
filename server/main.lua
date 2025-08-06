RegisterNetEvent('hydraalarm:triggerAlarm', function(vehNetId)
    local src = source
    TriggerClientEvent('hydraalarm:playAlarm', -1, vehNetId)
end)
