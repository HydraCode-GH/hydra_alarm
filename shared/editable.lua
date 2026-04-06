Editable = Editable or {}

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
Editable, Everything here is easy to edit and replace. This file is meant to be a bridge for server/client communication and notifications, but you can expand it as needed for your own use.
--]]


if IsDuplicityVersion() then
    Editable.Server = Editable.Server or {}

    ---Send a notification to one player.
    ---@param playerId number
    ---@param message string
    ---@param notifyType? 'info'|'success'|'warning'|'error'|string
    ---@param duration? number
    ---@return nil
    function Editable.Server.Notify(playerId, message, notifyType, duration)
        notifyType = notifyType or 'info'
        duration = duration or 5000

        if Framework and Framework.Type == 'esx' then
            --print('ESX notify: ' .. message) --- IGNORE ---
            TriggerClientEvent('esx:showNotification', playerId, message)
            return
        end

        if Framework and Framework.Type == 'qbcore' then
            TriggerClientEvent('QBCore:Notify', playerId, message, notifyType, duration)
            return
        end

        TriggerClientEvent('hydra_alarm:notify', playerId, message, notifyType, duration)
    end
else
    Editable.Client = Editable.Client or {}

    ---Local client notification helper.
    ---Replace internals with your own UI export if needed.
    ---@param message string
    ---@param notifyType? 'info'|'success'|'warning'|'error'|string
    ---@param duration? number
    ---@return nil
    function Editable.Client.Notify(message, notifyType, duration)
        notifyType = notifyType or 'info'
        duration = duration or 5000

        if Framework and Framework.Type == 'esx' then
            TriggerEvent('esx:showNotification', message)
            return
        end

        if Framework and Framework.Type == 'qbcore' then
            TriggerEvent('QBCore:Notify', message, notifyType, duration)
            return
        end

        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end

    RegisterNetEvent('hydra_alarm:notify', function(message, notifyType, duration)
        Editable.Client.Notify(message, notifyType, duration)
    end)
end
