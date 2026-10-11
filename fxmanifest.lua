fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'codera_shops'
description 'npv Shops '
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/bridge.lua',
}
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'web/index.html'
files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}
