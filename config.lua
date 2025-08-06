Config = {}

Config.Update = true

-- List of vehicles that will NEVER trigger the alarm
Config.BlacklistedVehicles = {
    [GetHashKey('bmx')] = true,         -- BMX bike
    [GetHashKey('faggio')] = true,      -- Faggio scooter
    [GetHashKey('police')] = true,      -- Police car
    [GetHashKey('ambulance')] = true,   -- Ambulance
    [GetHashKey('bus')] = true,         -- Bus
    -- Add more models here if needed
}

-- List of tow trucks that can trigger the tow alarm
Config.TowTrucks = {
    [GetHashKey('flatbed')] = true,
    [GetHashKey('towtruck')] = true,
    [GetHashKey('towtruck2')] = true,
    -- Add more towtruck models if needed
}

-- Name of the alarm sound (OGG file name, without .ogg extension, placed in InteractSound)
Config.InteractSoundName = 'alarm'

-- Maximum distance (in GTA units/meters) at which players can hear the alarm sound
Config.InteractSoundDistance = 25.0

-- Volume of the alarm sound (1.0 = 100%)
Config.InteractSoundVolume = 1.0

-- Length of your alarm sound file (in seconds!)
Config.InteractSoundLength = 13

-- How many seconds before the sound ends should the next loop start (overlap)
Config.InteractSoundLoopOffset = 1

-- Duration of the alarm (in seconds) for lights, horn, and sound
Config.AlarmDuration = 20

-- Time in seconds before the same vehicle can trigger the alarm again (cooldown)
Config.AlarmCooldown = 60

-- Radius (in meters) to detect a towtruck near a vehicle (for tow-alarm fallback)
Config.TowtruckDetectionRadius = 4.0