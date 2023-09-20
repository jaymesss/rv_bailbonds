fx_version 'cerulean'
game 'gta5'
description 'Bailbonds Job for QBCore'
version '1.0.0'
client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/*.lua',
    '@oxmysql/lib/MySQL.lua'
}
shared_script {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'locale/en.lua'
}
lua54 'yes'