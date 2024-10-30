local SetEntityCoords = SetEntityCoords
local GetClockHours = GetClockHours
local GetClockMinutes = GetClockMinutes
local GetClockSeconds = GetClockSeconds
local CreateObjectNoOffset = CreateObjectNoOffset
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local NetworkOverrideClockTime = NetworkOverrideClockTime
local SetWeatherTypeOvertimePersist = SetWeatherTypeOvertimePersist
local GetPrevWeatherTypeHashName = GetPrevWeatherTypeHashName
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local CreateVehicle = CreateVehicle
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SetEntityVisible = SetEntityVisible
local SetEntityCollision = SetEntityCollision
local NetworkFadeOutEntity = NetworkFadeOutEntity
local TriggerServerEvent = TriggerServerEvent
local PlaySoundFrontend = PlaySoundFrontend
local SendNUIMessage = SendNUIMessage
local CreateThread = CreateThread
local Wait = Wait
local GetVehicleClass = GetVehicleClass
local CreateBlip = UTILS.createBlip
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity

local resourceName = cache.resource
local pumpkinEntities = {}
local lastWeather = GetPrevWeatherTypeHashName()
local lastTime = { h = GetClockHours(), m = GetClockMinutes(), s = GetClockSeconds() }
local pumpkinsCollected = 0
local shopPoint = nil
currentZone = nil
playerPed = cache?.ped or PlayerPedId()

lib.onCache('ped', function(value)
    playerPed = value
end)

--- @param centerCoords table
--- @param radius number
--- @return tablend.
local function getSpawnCoords(centerCoords, radius)
    for _ = 1, 10 do
        local angle = math.random() * 2 * math.pi
        local distance = math.sqrt(math.random()) * radius
        local spawnX = centerCoords.x + math.cos(angle) * distance
        local spawnY = centerCoords.y + math.sin(angle) * distance
        local spawnZ = centerCoords.z + 1.0

        local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ, false)
        if foundGround then
            return { x = spawnX, y = spawnY, z = groundZ }
        end
    end
    return centerCoords
end

local weatherTypes = {
    CLEAR = "CLEAR",
    EXTRASUNNY = "EXTRASUNNY",
    CLOUDS = "CLOUDS",
    OVERCAST = "OVERCAST",
    RAIN = "RAIN",
    CLEARING = "CLEARING",
    THUNDER = "THUNDER",
    SMOG = "SMOG",
    FOGGY = "FOGGY",
    XMAS = "XMAS",
    SNOW = "SNOW",
    SNOWLIGHT = "SNOWLIGHT",
    BLIZZARD = "BLIZZARD",
    HALLOWEEN = "HALLOWEEN",
    NEUTRAL = "NEUTRAL",
}

local function setWeather()
    lastWeather = GetPrevWeatherTypeHashName()
    lastTime = { h = GetClockHours(), m = GetClockMinutes(), s = GetClockSeconds() }

    SetWeatherTypeOvertimePersist(weatherTypes.HALLOWEEN, 10.0)
    NetworkOverrideClockTime(0, 0, 0)
    SetClockTime(0, 0, 0)
end

function resetWeather()
    NetworkOverrideClockTime(lastTime.h, lastTime.m, lastTime.s)
    SetWeatherTypeOvertimePersist(weatherTypes[lastWeather], 2.0)
end

--- @param coords table
--- @return number
local function createPumpkin(coords)
    local pumpkinModelHash = lib.requestModel(Config.PumpkinModel)

    local entity = CreateObjectNoOffset(pumpkinModelHash, coords.x, coords.y, coords.z, true)
    PlaceObjectOnGroundProperly(entity)
    return entity
end

--- @param zone table
function spawnPumpkins(zone)
    CreateThread(function()
        while currentZone do
            if #pumpkinEntities < Config.MaxPumpkinSpawns then
                local coords = getSpawnCoords(zone.coords, zone.radius)
                if coords then
                    local entity = createPumpkin(coords)
                    pumpkinEntities[#pumpkinEntities + 1] = entity
                end
            end
            Wait(1000)
        end
    end)
end

function createShop()
    local coords = currentZone.shop.coords
    shopPoint = lib.points.new({
        coords = coords.xyz,
        distance = 30,
    })

    function shopPoint:onEnter()
        if self.ped then return end

        local model = lib.requestModel(currentZone.shop.model)
        local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)

        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(model)
        exports.ox_target:addLocalEntity(ped, {
            {
                label = L("dealer_interaction_label"),
                icon = "fas fa-skull",
                onSelect = function()
                    local options = {}

                    for i = 1, #currentZone.shop.items do
                        local item = currentZone.shop.items[i]
                        options[#options + 1] = {
                            title = item.label,
                            description = (item.description):format(item.price),
                            icon = Config.IconPath:format(item.name),
                            onSelect = function()
                                local input = lib.inputDialog(L("sell_select_amount_title"), {
                                    { type = 'number', label = L("sell_select_amount_label"), description = L("sell_select_amount_desc"), icon = 'hashtag' },
                                })

                                if not input then return UTILS.showNotification(L("invalid_amount")) end

                                local data = {
                                    item = item,
                                    toSell = input[1]
                                }

                                local success = lib.callback.await("ars_halloween:sellItem", false, data)
                                if not success then return UTILS.showNotification(L("not_enough_items")) end
                                UTILS.showNotification(L("item_sold"):format(input[1], item.label, item.price * input[1]))
                            end
                        }
                    end


                    lib.registerContext({
                        id = 'ars_halloween:zombie_shop',
                        title = L("dealer_menu_title"),
                        options = options
                    })

                    lib.showContext('ars_halloween:zombie_shop')
                end

            }
        })
        self.ped = ped
    end

    function shopPoint:onExit()
        DeleteEntity(self.ped)
        self.ped = nil
    end
end

--- @param zone table
function startHalloweenEvent(zone)
    SendNUIMessage({ action = "startEvent" })
    setWeather()
    handleZombie(zone)
    spawnPumpkins(zone)
    createShop()
end

function stopHalloweenEvent()
    SendNUIMessage({ action = "stopEvent" })
    resetWeather()
    deleteEntities()
end

function deleteEntities()
    for i = 1, #pumpkinEntities do
        if DoesEntityExist(pumpkinEntities[i]) then
            DeleteEntity(pumpkinEntities[i])
        end
        pumpkinEntities[i] = nil
    end
end

function loadZones()
    for _, data in ipairs(Config.SpookyZones) do
        local zone = data.zone


        data.blip.coords = zone.coords
        CreateBlip(data.blip)
        data.blip.radius = zone.radius
        CreateBlip(data.blip)

        -- entry and exit handlers
        lib.zones.sphere({
            coords = zone.coords,
            radius = zone.radius,
            -- debug = true,
            onEnter = function(self)
                currentZone = data
                startHalloweenEvent(zone)
            end,
            onExit = function(self)
                stopHalloweenEvent()
                currentZone = nil
                shopPoint:remove()
                shopPoint = nil
            end,
        })
    end
end

function collectRandomReward(rewards)
    local randomItemIndex = math.random(1, #rewards.items)
    local item = rewards.items[randomItemIndex]

    local vehicle = nil
    if #rewards.vehicles > 0 then
        local randomVehIndex = math.random(1, #rewards.vehicles)
        local potentialVehicle = rewards.vehicles[randomVehIndex]

        if math.random(1, 100) <= potentialVehicle.chance then
            vehicle = potentialVehicle
        end
    end

    return { item = item, vehicle = vehicle }
end

exports.ox_target:addModel(Config.PumpkinModel, {
    {
        label = L("pumpkin_collect_label"),
        icon = "fas fa-ghost",
        onSelect = function(pumpkin)
            local entity = pumpkin.entity
            if not lib.progressBar(Config.Progress.pumpkin) then return end

            NetworkFadeOutEntity(entity)
            Wait(100)

            local data = {
                netId = NetworkGetNetworkIdFromEntity(entity),
                rewards = currentZone.pumpkins,
                pumpkinBonus = Config.BonusRewards.pumpkins[pumpkinsCollected],
                bonusValue = pumpkinsCollected
            }

            local wonVehicle = lib.callback.await("ars_halloween:collectRewards", false, data)
            if wonVehicle then
                UTILS.showNotification(L("win_vehicle"))
                doCelebration()
            end
            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 0)

            pumpkinsCollected += 1
            SendNUIMessage({
                action = "updateCard",
                pumpkinsCollected = pumpkinsCollected,
            })

            -- if rewardsData.vehicle then
            --     UTILS.showNotification(L("win_vehicle"))
            --     doCelebration()
            -- end

            -- TriggerServerEvent("ars_halloween:collectEntity", data)
            scarePlayer()
        end
    }
})

function scarePlayer()
    if math.random(1, 100) <= Config.ScareProbability then
        SendNUIMessage({ action = "scareMf" })
        Wait(3000)
        UTILS.showNotification("Sorry :D")
    end
end

AddEventHandler('onResourceStop', function(res)
    if resourceName ~= res then return end
    stopHalloweenEvent()
    removeAllZombies()
end)

AddEventHandler('onClientResourceStart', function(res)
    if resourceName ~= res then return end
    loadZones()
end)

--- @param data table
--- @return table

lib.callback.register("ars_halloween:getVehicleProperties", function(data)
    local vehicleProperties = {}

    local coords = cache.coords
    local model = lib.requestModel(data.model)

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, false, false)
    local vehicleClass = GetVehicleClass(vehicle)

    SetModelAsNoLongerNeeded(model)
    SetEntityVisible(vehicle, false, false)
    SetEntityCollision(vehicle, false)

    lib.setVehicleProperties(vehicle, data.modifications)
    vehicleProperties = lib.getVehicleProperties(vehicle)
    DeleteVehicle(vehicle)

    return vehicleProperties, vehicleClass
end)



function doCelebration() -- not synced because i am lazy
    local particleDict = "scr_indep_fireworks"
    local asset = "scr_indep_firework_shotburst"
    lib.requestNamedPtfxAsset(particleDict)

    for i = 1, 10 do
        local fireworkPos = cache.coords
        UseParticleFxAssetNextCall(particleDict)
        StartNetworkedParticleFxNonLoopedAtCoord(asset, fireworkPos.x, fireworkPos.y, fireworkPos.z, 0.0, 0.0, 0.0,
            math.random() * 0.3 + 0.5, false, false, false)
        Wait(math.random(200, 1000))
    end
end
