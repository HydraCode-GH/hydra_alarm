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

HydraAlarmServerCache = HydraAlarmServerCache or {}
local serverVehicleCache = HydraAlarmServerCache

---@param plate string|nil
---@return string
local function normalizePlate(plate)
    if type(plate) ~= 'string' then
        return ''
    end

    return plate:gsub('^%s*(.-)%s*$', '%1'):upper()
end

---@param plate string
---@param alarmActive boolean
---@param reason string|nil
---@param sourceId number
---@param coords? vector3
---@return nil
local function setAlarmState(plate, alarmActive, reason, sourceId, coords)
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return
    end

    local state = serverVehicleCache[normalizedPlate] or {}
    state.alarmActive = alarmActive == true
    state.reason = reason or state.reason or 'unknown'
    state.updatedAt = os.time()
    state.updatedBy = sourceId
    if coords then
        state.coords = coords
    end
    serverVehicleCache[normalizedPlate] = state

    TriggerClientEvent('hydra_alarm:syncAlarmState', -1, normalizedPlate, state.alarmActive, state.reason)
end

---@param sourceId number
---@param message string
---@param notifyType string
---@param duration number
---@return nil
local function notifySource(sourceId, message, notifyType, duration)
    if Editable and Editable.Server and Editable.Server.Notify then
        Editable.Server.Notify(sourceId, message, notifyType, duration)
    end
end

lib.callback.register('hydra_alarm:getNearbyAlarmStates', function(_, nearbyPlates)
    local result = {}

    if type(nearbyPlates) ~= 'table' then
        return result
    end

    for _, plate in ipairs(nearbyPlates) do
        local normalizedPlate = normalizePlate(plate)
        local state = serverVehicleCache[normalizedPlate]
        if state and state.alarmActive then
            result[normalizedPlate] = {
                alarmActive = true,
                reason = state.reason,
                updatedAt = state.updatedAt,
            }
        end
    end

    return result
end)

---@param plate string
---@param alarmActive boolean
---@param reason string
---@param coords? vector3
RegisterNetEvent('hydra_alarm:serverSetAlarmState', function(plate, alarmActive, reason, coords)
    local sourceId = source
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return
    end

    setAlarmState(normalizedPlate, alarmActive, reason, sourceId, coords)

    if alarmActive then
        debugprint('Alarm sync start from ' .. GetPlayerName(sourceId) .. ' | Plate: ' .. normalizedPlate .. ' | Reason: ' .. tostring(reason))
        if Config.NotifyOnAlarm then
            notifySource(sourceId, L('notify.alarm_triggered'), 'warning', 3500)
        end

        if Config.OwnerNotification and Editable and Editable.Server and Editable.Server.OwnerNotify then
            Editable.Server.OwnerNotify(normalizedPlate, reason)
        end

        if Config.DispatchEnabled and Editable and Editable.Server and Editable.Server.Dispatch then
            Editable.Server.Dispatch(coords, normalizedPlate, reason)
        end
    else
        debugprint('Alarm sync stop from ' .. GetPlayerName(sourceId) .. ' | Plate: ' .. normalizedPlate)
        if Config.NotifyOnAlarm then
            notifySource(sourceId, L('notify.alarm_stopped'), 'success', 2500)
        end
    end
end)

---@param plate string
---@param reason string
RegisterNetEvent('hydra_alarm:triggerAlarm', function(plate, reason)
    local sourceId = source
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return
    end

    setAlarmState(normalizedPlate, true, reason or 'legacy_trigger', sourceId)
    debugprint('Alarm triggered by ' .. GetPlayerName(sourceId) .. ' for vehicle: ' .. normalizedPlate .. ' | Reason: ' .. tostring(reason))
    if Config.NotifyOnAlarm then
        notifySource(sourceId, L('notify.alarm_triggered'), 'warning', 3500)
    end
end)

---@param plate string
RegisterNetEvent('hydra_alarm:stopAlarm', function(plate)
    local sourceId = source
    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then
        return
    end

    setAlarmState(normalizedPlate, false, 'legacy_stop', sourceId)
    debugprint('Alarm stopped by ' .. GetPlayerName(sourceId) .. ' for vehicle: ' .. normalizedPlate)
    if Config.NotifyOnAlarm then
        notifySource(sourceId, L('notify.alarm_stopped'), 'success', 2500)
    end
end)

debugprint('Server initialized')