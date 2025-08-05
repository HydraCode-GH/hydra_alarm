fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HydraCode'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'

server_scripts {
    'server/main.lua',
    'server/update.lua'
}

dependency 'ox_lib'

export 'TriggerAlarm'

server_export 'TriggerAlarmServer'