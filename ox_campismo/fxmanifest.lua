fx_version 'cerulean'
game 'gta5'

author 'pika80'
discord 'https://discord.gg/4Xq6AZ3nM4'
description 'Sistema de Camping com ox_lib, ox_target e ox_inventory'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'es_extended'
}