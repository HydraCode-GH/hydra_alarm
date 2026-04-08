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

    -- =========================================================
    -- Internal helpers
    -- =========================================================

    ---Get the job name of an online player. Framework-dependent.
    ---Returns nil in standalone mode.
    ---@param source number
    ---@return string|nil
    local function getPlayerJob(source)
        if Framework and Framework.Type == 'esx' and Framework.ESX then
            local xPlayer = Framework.ESX.GetPlayerFromId(source)
            if xPlayer and xPlayer.getJob then
                return xPlayer.getJob().name
            end
        elseif Framework and Framework.Type == 'qbcore' and Framework.QB then
            local player = Framework.QB.Functions.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.job then
                return player.PlayerData.job.name
            end
        end
        return nil
    end

    ---Look up the online player ID that owns a vehicle by plate.
    ---Uses oxmysql for a DB lookup (ESX: owned_vehicles, QB: player_vehicles).
    ---Falls back to checking who is currently sitting in the vehicle if DB is unavailable.
    ---@param plate string
    ---@return number|nil  player source id, or nil if owner is offline/unknown
    local function getVehicleOwner(plate)
        plate = plate:gsub('^%s*(.-)%s*$', '%1'):upper()

        if GetResourceState('oxmysql') == 'started' then
            local ok, result = pcall(function()
                if Framework and Framework.Type == 'esx' then
                    return exports.oxmysql:executeSync(
                        'SELECT owner FROM owned_vehicles WHERE plate = ? LIMIT 1',
                        { plate }
                    )
                elseif Framework and Framework.Type == 'qbcore' then
                    return exports.oxmysql:executeSync(
                        'SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1',
                        { plate }
                    )
                end
                return nil
            end)

            if ok and result and result[1] then
                if Framework.Type == 'esx' then
                    local identifier = result[1].owner
                    local xPlayer = Framework.ESX.GetPlayerFromIdentifier(identifier)
                    return xPlayer and xPlayer.source or nil
                elseif Framework.Type == 'qbcore' then
                    local citizenid = result[1].citizenid
                    if Framework.QB.Functions.GetPlayerByCitizenId then
                        local player = Framework.QB.Functions.GetPlayerByCitizenId(citizenid)
                        return player and player.PlayerData.source or nil
                    end
                end
            end
        end

        -- Fallback: check who is currently sitting in the vehicle
        for _, playerId in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(playerId)
            if ped and ped ~= 0 then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh and veh ~= 0 then
                    local vehPlate = GetVehicleNumberPlateText(veh)
                    if type(vehPlate) == 'string' then
                        vehPlate = vehPlate:gsub('^%s*(.-)%s*$', '%1'):upper()
                        if vehPlate == plate then
                            return tonumber(playerId)
                        end
                    end
                end
            end
        end

        return nil
    end

    -- Expose getVehicleOwner as a callback so other resources/clients can query it.
    lib.callback.register('hydra_alarm:getVehicleOwner', function(_, plate)
        if type(plate) ~= 'string' or plate == '' then
            return nil
        end
        return getVehicleOwner(plate)
    end)

    -- =========================================================
    -- Owner notification
    -- =========================================================

    ---Notify the owner of a vehicle when their alarm triggers.
    ---Uses framework-dependent DB lookup via getVehicleOwner.
    ---@param plate string
    ---@param reason string
    ---@return nil
    function Editable.Server.OwnerNotify(plate, reason)
        local ownerSource = getVehicleOwner(plate)
        if ownerSource then
            Editable.Server.Notify(ownerSource, L('notify.owner_alarm', plate, reason), 'warning', 6000)
        end
    end

    -- =========================================================
    -- Dispatch
    -- =========================================================

    ---Notify all online players whose job matches Config.DispatchJobs.
    ---Replace or extend with a dedicated dispatch resource call if needed (ps-dispatch, cd_dispatch, etc.).
    ---@param coords vector3|nil
    ---@param plate string
    ---@param reason string
    ---@return nil
    function Editable.Server.Dispatch(coords, plate, reason)
        local message = L('notify.dispatch_message', plate, reason)

        local jobLookup = {}
        for _, v in pairs(Config.DispatchJobs or {}) do
            jobLookup[v] = true
        end

        for _, playerId in ipairs(GetActivePlayers()) do
            local job = getPlayerJob(tonumber(playerId))
            if job and jobLookup[job] then
                Editable.Server.Notify(tonumber(playerId), message, 'warning', 8000)
            end
        end

        -- Uncomment to also call ps-dispatch alongside the job notify:
        -- TriggerClientEvent('ps-dispatch:server:CreateDispatchCall', -1, {
        --     callLocation = coords,
        --     callCode     = { code = '10-50', snippet = 'Vehicle Alarm' },
        --     message      = message,
        --     flashes      = true,
        --     image        = '',
        --     blip         = { sprite = 225, scale = 1.2, colour = 1, flashes = true, text = 'Vehicle Alarm', time = 15000 },
        --     jobs         = Config.DispatchJobs,
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
