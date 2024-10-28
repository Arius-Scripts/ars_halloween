local AddBlipForRadius = AddBlipForRadius
local SetBlipAlpha = SetBlipAlpha
local AddBlipForCoord = AddBlipForCoord
local SetBlipSprite = SetBlipSprite
local SetBlipScale = SetBlipScale
local SetBlipDisplay = SetBlipDisplay
local SetBlipColour = SetBlipColour
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentString = AddTextComponentString
local EndTextCommandSetBlipName = EndTextCommandSetBlipName


UTILS = {}


function UTILS.showNotification(msg, type, title)
    type = type or "info"
    msg = msg or "N/A"
    title = title or "🎃 Halloween"

    lib.notify({
        title = title,
        description = msg,
        type = type,
        position = "center-right",
    })
end

function UTILS.createBlip(data)
    local blip
    if data.radius then
        blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius)
        SetBlipAlpha(blip, 100)
    else
        blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, data.type)
        SetBlipScale(blip, data.scale)
    end

    SetBlipDisplay(blip, 6)
    SetBlipColour(blip, data.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.name)
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, true)

    return blip
end
