fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HydraCode'
version '1.0.0 '

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'

server_scripts {
    'server/main.lua',
    'server/update.lua'
}

dependencies{
    'ox_lib',
    'interact-sound'
}

export 'isAlarmActive'
export 'hydra_alarm'