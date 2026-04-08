Editable = Editable or {}

--[[
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
--]]

if IsDuplicityVersion() then
    Editable.Server = Editable.Server or {}

    ---Notify the owner of a vehicle when their alarm triggers.
    ---By default checks if any online player is currently in the vehicle.
    ---For registered ownership, add a database/framework lookup here.
    ---@param plate string
    ---@param reason string
    ---@return nil
    function Editable.Server.OwnerNotify(plate, reason)
        for _, playerId in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(playerId)
            if ped and ped ~= 0 then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh and veh ~= 0 then
                    local vehPlate = GetVehicleNumberPlateText(veh)
                    if type(vehPlate) == 'string' then
                        vehPlate = vehPlate:gsub('^%s*(.-)%s*$', '%1'):upper()
                        if vehPlate == plate then
                            Editable.Server.Notify(playerId, L('notify.owner_alarm', plate, reason), 'warning', 6000)
                            return
                        end
                    end
                end
            end
        end
    end

    ---Send a dispatch alert when a vehicle alarm triggers.
    ---Uncomment and configure the block for your dispatch resource.
    ---@param coords vector3|nil
    ---@param plate string
    ---@param reason string
    ---@return nil
    function Editable.Server.Dispatch(coords, plate, reason)
        -- ps-dispatch example:
        -- TriggerClientEvent('ps-dispatch:server:CreateDispatchCall', -1, {
        --     callLocation = coords,
        --     callCode = { code = '10-50', snippet = 'Vehicle Alarm' },
        --     message = L('notify.dispatch_message', plate, reason),
        --     flashes = true,
        --     image = '',
        --     blip = { sprite = 225, scale = 1.2, colour = 1, flashes = true, text = 'Vehicle Alarm', time = 15000 },
        --     jobs = { 'police' },
        -- })

        -- cd_dispatch example:
        -- TriggerEvent('cd_dispatch:AddNotification', {
        --     job_table = { 'police' },
        --     coords_msg = coords,
        --     tag = '10-50',
        --     title = 'Vehicle Alarm',
        --     message = L('notify.dispatch_message', plate, reason),
        --     flash = 1,
        --     unique_id = tostring(math.random(0000000, 9999999)),
        -- })
    end

    ---Send a notification to one player.
    ---@param playerId number
    ---@param message string
    ---@param notifyType? 'info'|'success'|'warning'|'error'|string
    ---@param duration? number
    ---@return nil
    function Editable.Server.Notify(playerId, message, notifyType, duration)
        notifyType = notifyType or 'info'
        duration = duration or 5000

        if GetResourceState('okokNotify') ~= 'missing' then
            TriggerClientEvent('okokNotify:Alert', playerId, 'Alarm', message, duration, notifyType, false)
            return
        end

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

        if GetResourceState('okokNotify') ~= 'missing' then
            exports['okokNotify']:Alert('Alarm', message, duration, notifyType, false)
            return
        end

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
