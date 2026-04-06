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

lib.callback.register('hydra_alarm:stopAllAlarms', function(sourceId)
    local isAdmin = Framework
        and Framework.Server
        and Framework.Server.isAdmin
        and Framework.Server.isAdmin(sourceId)

    if not isAdmin then
        return {
            ok = false,
            message = L('notify.no_permission'),
        }
    end

    if type(HydraAlarmServerCache) == 'table' then
        for plate in pairs(HydraAlarmServerCache) do
            HydraAlarmServerCache[plate] = nil
        end
    end

    TriggerClientEvent('hydra_alarm:stopAllAlarms', -1)

    return {
        ok = true,
        message = L('command.stopall.success'),
    }
end)
