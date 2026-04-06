Config = {}

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
Config lol
--]]


-- Enables debug prints in console.
Config.Debug = false

-- Active locale key (for example: 'en').
Config.Locale = 'en'

-- =========================================================
-- Framework
-- =========================================================
-- Options:
-- 'auto'       = detect ESX/QBCore automatically, fallback to standalone
-- 'standalone' = force standalone behavior
Config.Framework = 'auto'

-- =========================================================
-- Admin Access
-- =========================================================
-- Admin groups/permissions for all frameworks (ESX, QBCore, etc.).
-- ACE permissions are always checked first, then framework groups.
-- In standalone mode, only ACE is used.
--
-- ACE permission required: 'hydra_alarm.admin'
-- Add one of these to your server.cfg:
--   add_ace group.admin hydra_alarm.admin allow
--   add_ace identifier.steam:XXXXX hydra_alarm.admin allow
--   add_ace identifier.license:XXXXX hydra_alarm.admin allow
--
Config.AdminGroups = {
    'admin',
    'superadmin',
    'god',
}

-- =========================================================
-- Vehicle Lists
-- =========================================================
-- Vehicles ignored by the alarm system.
-- Use model names, not GetHashKey values.
Config.BlacklistedVehicles = {
    'ambulance',
    'bmx',
    'bus',
    'faggio',
    'police',
}

-- Tow truck models that can trigger tow-based alarms.
-- Use model names, not hashes.
Config.TowTrucks = {
    'flatbed',
    'towtruck',
    'towtruck2',
}

-- =========================================================
-- Audio
-- =========================================================
-- Global volume multiplier applied on top of alarm volume.
-- Range: 0.0 to 1.0
Config.MasterVolume = 1.0

-- Name passed to interact-sound/xsound or used as fallback source candidate.
Config.InteractSoundName = 'alarm'

-- Audible radius used by supported sound backends.
-- Unit: game distance units (meters-like)
Config.InteractSoundDistance = 25.0

-- Base alarm volume before global multiplier is applied.
-- Range: 0.0 to 1.0
Config.InteractSoundVolume = 1.0

-- Approximate clip length in seconds, used for manual looping.
Config.InteractSoundLength = 13

-- Seconds before clip end to restart loop (prevents audible gap).
Config.InteractSoundLoopOffset = 1

-- If true, horn pattern plays while alarm is active.
Config.HornEnabled = true

-- Horn pattern options: 'continuous', 'pulse', 'double'
Config.HornPattern = 'double'

-- NUI fallback settings (used only if interact-sound/xsound are unavailable).
-- Modes:
-- 'url'  = remote URL (direct audio or YouTube link)
-- 'file' = local file inside html/
-- 'auto' = automatic source selection
Config.NuiSoundMode = 'file'

-- Remote source used when mode is 'url'.
Config.NuiSoundUrl = 'https://youtu.be/iik25wqIuFo?list=RDiik25wqIuFo'

-- Local source used when mode is 'file' (relative to html/).
Config.NuiSoundFile = 'assets/alarm.mp3'

-- How often distance/attenuation updates are sent to NUI.
-- Unit: milliseconds
Config.NuiDistanceUpdateInterval = 250

-- =========================================================
-- Timing and Sync
-- =========================================================
-- Standard alarm duration.
-- Unit: seconds
Config.AlarmDuration = 20

-- Alarm duration while detected as being towed.
-- Unit: seconds
Config.TowTruckAlarmDuration = 5

-- Cooldown before same vehicle can trigger alarm again.
-- Unit: seconds
Config.AlarmCooldown = 20

-- Interval for polling server authoritative alarm states.
-- Unit: milliseconds
Config.ServerSyncInterval = 1500

-- =========================================================
-- Detection Rules
-- =========================================================
-- Enables tow-triggered alarms.
Config.TowTruckAlarm = true

-- Radius used to search for nearby tow trucks.
-- Unit: game distance units (meters-like)
Config.TowTruckCheckDistance = 50

-- Vertical threshold to count as jumping on top of a vehicle.
-- Unit: height delta
Config.JumpHeightThreshold = 1.0

-- Minimum health loss needed to trigger a damage alarm.
Config.MinimumDamageThreshold = 5

-- =========================================================
-- Commands
-- =========================================================
-- Admin command to stop every active alarm in scope.
Config.StopAllAlarmsCommand = 'stopallalarms'