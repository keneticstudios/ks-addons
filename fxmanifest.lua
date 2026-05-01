fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Kenetic Studios'
description 'KS OX Inventory Addons'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'clothes/server/sv_edit.lua',
    'clothes/server/db_clothes.lua',
    'clothes/server/server.lua',
}

client_scripts {
    'clothes/client/cl_edit.lua',
    'clothes/client/client.lua',

    'drops/client.lua',
    'inventory/client.lua',
}

escrow_ignore {
    '**/*',
}
