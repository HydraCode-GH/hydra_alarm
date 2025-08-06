Config = {}

Config.Update = true

-- Blacklist für Fahrzeuge, die KEINE Alarmanlage haben (Modellnamen)
Config.BlacklistedVehicles = { -- z.B. Fahrräder, Boote, Müllwagen etc.
    [`bmx`] = true,
    [`faggio`] = true,
    [`police`] = true,
    [`ambulance`] = true,
    [`bus`] = true,
    -- usw.
}

-- Alle Fahrzeuge außer Blacklist haben eine Alarmanlage!
Config.AlarmDuration = 20
Config.AlarmCooldown = 60

Config.AlarmSound = 'car_alarm'
Config.AlarmSoundRef = 'car_alarm_siren'
