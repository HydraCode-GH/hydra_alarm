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

---@return nil
RegisterCommand(Config.StopAllAlarmsCommand or 'stopallalarms', function()
    local result = lib.callback.await('hydra_alarm:stopAllAlarms', false)

    if result and result.ok then
        if Framework and Framework.Client and Framework.Client.Notification then
            Framework.Client.Notification('Hydra Alarm', result.message or L('command.stopall.success'), 'success', 4000)
        end
        return
    end

    if Framework and Framework.Client and Framework.Client.Notification then
        Framework.Client.Notification('Hydra Alarm', (result and result.message) or L('command.stopall.denied'), 'error', 4500)
    end
end, false)

-- Debug command: lock/unlock nearby vehicle
if Config.Debug then
    RegisterCommand('togglevehiclelock', function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearbyVehicles = lib.getNearbyVehicles(playerCoords, 10, true)

        if not nearbyVehicles or #nearbyVehicles == 0 then
            if Framework and Framework.Client and Framework.Client.Notification then
                Framework.Client.Notification('DEBUG', 'No nearby vehicles found.', 'error', 3000)
            end
            return
        end

        local vehicle = nearbyVehicles[1].vehicle
        if not DoesEntityExist(vehicle) then
            if Framework and Framework.Client and Framework.Client.Notification then
                Framework.Client.Notification('DEBUG', 'Vehicle does not exist.', 'error', 3000)
            end
            return
        end

        local currentLockStatus = GetVehicleDoorLockStatus(vehicle)
        local isLocked = currentLockStatus > 1

        if isLocked then
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
            if Framework and Framework.Client and Framework.Client.Notification then
                Framework.Client.Notification('DEBUG', 'Vehicle unlocked.', 'success', 2500)
            end
        else
            SetVehicleDoorsLocked(vehicle, 2)
            SetVehicleDoorsLockedForAllPlayers(vehicle, true)
            if Framework and Framework.Client and Framework.Client.Notification then
                Framework.Client.Notification('DEBUG', 'Vehicle locked.', 'success', 2500)
            end
        end
    end, false)
end