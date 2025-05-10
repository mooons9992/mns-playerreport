fx_version 'cerulean'
game 'gta5'

author 'Mooons'
description 'MNS Player Report System'
version '1.1.0'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'utils/utils.lua',  -- Make sure utils.lua is loaded BEFORE server.lua
    'server/*.lua'
}

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'html/sounds/*.ogg'
}

dependencies {
    'qb-core'
}