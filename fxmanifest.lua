fx_version 'cerulean'
game 'gta5'

author 'ZevDev'
description 'Universal Parking Job'
version '1.0.0'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
