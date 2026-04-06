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
Framework Bridge for ESX/QBCORE/QBOX/Standalone
--]]

Framework = {}
Framework.Type = nil
Framework.ScriptName = 'hydra_alarm'

-- Unified debug print function (must be defined before detectFramework runs)
---@param data any
---@return nil
function debugprint(data)
    if Config and Config.Debug then
        print('^3[' .. Framework.ScriptName .. '] ' .. tostring(data) .. '^7')
    end
end

---@return boolean
local function isStandaloneForced()
    return Config
        and type(Config.Framework) == 'string'
        and Config.Framework:lower() == 'standalone'
end

---@param resourceName string
---@return boolean
local function isResourceStarted(resourceName)
    return GetResourceState(resourceName) == 'started'
end

---@return table|nil
local function getEsxSharedObject()
    if not isResourceStarted('es_extended') then
        return nil
    end

    local ok, result = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok and result then
        return result
    end

    local sharedObject = nil
    TriggerEvent('esx:getSharedObject', function(obj)
        sharedObject = obj
    end)

    return sharedObject
end

---@return table|nil
local function getQbCoreObject()
    if not isResourceStarted('qb-core') then
        return nil
    end

    local ok, result = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok and result then
        return result
    end

    return nil
end

---@param values string[]|nil
---@return table<string, boolean>
local function buildStringLookup(values)
    local lookup = {}
    if type(values) ~= 'table' then
        return lookup
    end

    for _, value in ipairs(values) do
        if type(value) == 'string' and value ~= '' then
            lookup[value:lower()] = true
        end
    end

    return lookup
end

-- Auto-detect framework on client
if IsDuplicityVersion() then
    -- SERVER SIDE
    Framework.Server = {}
    
    ---Detect and initialize server framework bridge.
    ---@return nil
    local function detectFramework()
        if isStandaloneForced() then
            Framework.Type = 'standalone'
            debugprint('Framework bypass enabled: forced standalone mode')
            return
        end

        local esxObject = getEsxSharedObject()
        if esxObject then
            Framework.Type = 'esx'
            Framework.ESX = esxObject
        end
        
        if Framework.Type ~= 'esx' then
            if (Config and Config.Framework == 'qbcore') or isResourceStarted('qb-core') then
                local qbObject = getQbCoreObject()
                if qbObject then
                    Framework.Type = 'qbcore'
                    Framework.QB = qbObject
                end
            end
        end
        
        if not Framework.Type then
            Framework.Type = 'standalone'
            debugprint('No framework detected, running in standalone mode')
        else
            debugprint('Detected framework: ' .. Framework.Type)
        end
    end
    
    detectFramework()
    
    ---Server-side notification helper.
    ---@param player number
    ---@param title string
    ---@param message string
    ---@param type? string
    ---@return nil
    function Framework.Server.Notification(player, title, message, type)
        type = type or 'info'

        if Editable and Editable.Server and Editable.Server.Notify then
            Editable.Server.Notify(player, message, type, 5000)
            return
        end
    end
    
    ---Check if a player has admin permission.
    ---@param source number
    ---@return boolean
    function Framework.Server.isAdmin(source)
        -- Always check ACE permission first (works everywhere)
        if IsPlayerAceAllowed(source, 'hydra_alarm.admin') then
            return true
        end

        -- Standalone mode only uses ACE
        if Framework.Type == 'standalone' then
            return false
        end

        local allowedGroups = buildStringLookup(Config and Config.AdminGroups)

        -- Check ESX groups
        if Framework.Type == 'esx' then
            local xPlayer = Framework.ESX.GetPlayerFromId(source)
            if xPlayer then
                local groupName = xPlayer.getGroup and xPlayer.getGroup() or nil
                if type(groupName) == 'string' then
                    return allowedGroups[groupName:lower()] == true
                end
            end
        end

        -- Check QBCore permissions
        if Framework.Type == 'qbcore' and Framework.QB and Framework.QB.Functions and Framework.QB.Functions.HasPermission then
            for group, _ in pairs(allowedGroups) do
                if Framework.QB.Functions.HasPermission(source, group) then
                    return true
                end
            end
        end

        return false
    end

else
    -- CLIENT SIDE
    Framework.Client = {}
    
    ---Detect and initialize client framework bridge.
    ---@return nil
    local function detectFramework()
        if isStandaloneForced() then
            Framework.Type = 'standalone'
            debugprint('Framework bypass enabled: forced standalone mode')
            return
        end

        local esxObject = getEsxSharedObject()
        if esxObject then
            Framework.Type = 'esx'
            Framework.ESX = esxObject
        end
        
        if Framework.Type ~= 'esx' and isResourceStarted('qb-core') then
            local qbObject = getQbCoreObject()
            if qbObject then
                Framework.Type = 'qbcore'
                Framework.QB = qbObject
            end
        end
        
        if not Framework.Type then
            Framework.Type = 'standalone'
            debugprint('No framework detected, running in standalone mode')
        else
            debugprint('Detected framework: ' .. Framework.Type)
        end
    end
    
    detectFramework()
    
    ---Client-side notification helper.
    ---@param title string
    ---@param message string
    ---@param type? string
    ---@param duration? number
    ---@return nil
    function Framework.Client.Notification(title, message, type, duration)
        type = type or 'info'
        duration = duration or 5000

        if Editable and Editable.Client and Editable.Client.Notify then
            Editable.Client.Notify(message, type, duration)
            return
        end
    end
end
