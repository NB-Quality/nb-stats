fx_version 'cerulean'
game 'gta5'
author 'negbook'

lua54 'yes'

client_scripts {
'config.lua',
'lib/scaleform.lua',
'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}

shared_scripts {
    'import.lua',
    'csv.lua',
    'callback.lua'
}

files {
    'data/*.csv',
}

dependencies {
	'oxmysql',
}
