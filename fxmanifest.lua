fx_version "cerulean"
use_experimental_fxv2_oal 'yes'
game 'gta5'
lua54 'yes'
version '1.0.0'


shared_scripts {
    '@ox_lib/init.lua',
    "resource/shared/*.lua",
}

client_scripts {
    "utility/client.lua",
    "resource/client/*.lua",
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "resource/server/*.lua",
}

ui_page "web/index.html"

files {
    "web/index.html",
    "web/**/*.*",
    "stream/*.ydr",
    "stream/*.ytyp",
    "locales/*.json"
}


data_file "DLC_ITYP_REQUEST" "pumpkinreal_ytyp.ytyp"
data_file "DLC_ITYP_REQUEST" "jackolantern_ytyp.ytyp"

dependencies {
    "ox_target",
    "ox_lib"
}
