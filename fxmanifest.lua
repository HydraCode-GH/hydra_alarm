fx_version 'cerulean'
game 'gta5'

author 'HydraCode'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/**/*'
}

client_scripts {
    'client/**/*'
}

server_scripts {
    'server/**/*'
}

dependencies{
    'ox_lib',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/**/*'
}
