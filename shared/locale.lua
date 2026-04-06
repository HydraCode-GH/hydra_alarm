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
Locale helper :)
--]]

HydraLocale = HydraLocale or {}
HydraLocale.data = HydraLocale.data or {}

---@param code string
---@param entries table<string, string>
---@return nil
function RegisterHydraLocale(code, entries)
    if type(code) ~= 'string' or code == '' then
        return
    end

    if type(entries) ~= 'table' then
        return
    end

    HydraLocale.data[code] = entries
end

---@param key string
---@param ... any
---@return string
function L(key, ...)
    local localeCode = (Config and Config.Locale) or 'en'
    local dict = HydraLocale.data[localeCode] or HydraLocale.data.en or {}
    local template = dict[key] or key

    if select('#', ...) == 0 then
        return template
    end

    local ok, formatted = pcall(string.format, template, ...)
    if ok and type(formatted) == 'string' then
        return formatted
    end

    return template
end
