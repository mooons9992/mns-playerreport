fx_version 'cerulean'
game 'gta5'

name 'mns-playerreport'
author 'Mooons'
version '1.0.0'

description 'Advanced Player Report System with Discord Integration'
repository 'https://github.com/mooons9992/mns-playerreport'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'utils/*.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/sv_version.lua', -- Version checker loads first
    'server/*.lua'
}

files {
    'html/index.html',
    'html/styles.css',
    'html/script.js',
    'html/sounds/notification.ogg'
}

dependencies {
    'qb-core'
}