---@type ESX|nil
local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil
---@type Ox|nil
local Ox = GetResourceState('ox_core'):find('start') and require '@ox_core/lib/init' or nil
---@type QBCore|nil
local QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

---@param target number
---@param item string
---@param quantity number
local function addItem(target, item, quantity)
    if not target then return end

    if ESX then
        local xPlayer = ESX.GetPlayerFromId(target)
        if not xPlayer then return end
        print(item, quantity)
        return xPlayer.addInventoryItem(item, quantity)
    end
    if QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(target)
        if not xPlayer then return end

        if item == "money" or item == "cash" then
            return xPlayer.Functions.AddMoney("cash", quantity)
        end
        return xPlayer.Functions.AddItem(item, quantity)
    end
    if Ox then
        return exports.ox_inventory:AddItem(target, item, quantity)
    end
end


---@return string
function generatePlate()
    local plate = lib.string.random(Config.Plate.pattern, Config.Plate.maxLetters)
    local table = ESX and "owned_vehicles" or QBCore and "player_vehicles" or Ox and "vehicles"

    local query = ('SELECT plate FROM %s WHERE plate = ? LIMIT 1'):format(table)
    local plateTake = MySQL.scalar.await(query, { plate })

    if plateTake then
        return generatePlate()
    end

    return plate
end

---@param target number
---@param vehicle table
local function giveVehicle(target, vehicle)
    if not target then return end

    local props, class = lib.callback.await("ars_halloween:getVehicleProperties", target, vehicle)
    props.plate = generatePlate()
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(target)
        if not xPlayer then return end

        MySQL.insert('INSERT INTO `owned_vehicles` (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)',
            { xPlayer.identifier, props.plate, json.encode(props), 1 })
    end
    if QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(target)
        if not xPlayer then return end

        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', { xPlayer.PlayerData.license, xPlayer.PlayerData.citizenid, vehicle.model, GetHashKey(model), props, props.plate, 1, "A", })
    end
    if Ox then
        props.plate   = Ox.GenerateVehiclePlate()
        local vin     = Ox.GenerateVehicleVin(vehicle.model)
        local xPlayer = Ox.GetPlayer(target)

        MySQL.insert('INSERT INTO `vehicles` (plate, vin, owner, model, class, data, stored) VALUES (?, ?, ?, ?, ?, ?, ?)', { props.plate, vin, xPlayer.charId, vehicle.model, class, json.encode(props), "A" })
    end
end

---@param rewards table
---@return number | nil
local function collectRandomReward(source, rewards)
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

    local quantity = math.random(item.minQuantity, item.maxQuantity)
    addItem(source, item.name, quantity)

    if vehicle then
        giveVehicle(source, vehicle)
    end

    return vehicle
end


local collectionCount = {}

---@param data table
lib.callback.register("ars_halloween:collectRewards", function(source, data)
    local zoneData = Config.SpookyZones[data.zone]
    local rewards = data.pumpkins and zoneData.pumpkins or data.zombies and zoneData.zombies
    if not rewards then return print("Invalid data passed") end

    -- Verify proximity to entity
    local entity = NetworkGetEntityFromNetworkId(data.netId)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    if #(playerCoords - GetEntityCoords(entity)) > 5 then
        return print(("ID: [%s] triggered event %s"):format(source, "ars_halloween:collectRewards"))
    end
    if #(playerCoords - zoneData.zone.coords) > zoneData.zone.radius then
        return print(("ID: [%s] triggered event %s"):format(source, "ars_halloween:collectRewards"))
    end

    local playerIdentifier = GetPlayerIdentifierByType(source, "license")
    local wonVehicle = collectRandomReward(source, rewards)

    local function updateCollection(type, bonusRewards)
        if not collectionCount[playerIdentifier] then
            collectionCount[playerIdentifier] = {
                ["zombies"] = 0,
                ["pumpkins"] = 0
            }
        end
        collectionCount[playerIdentifier][type] += 1

        local bonusValue = collectionCount[playerIdentifier][type]
        if bonusRewards[bonusValue] and not alreadyCollectedBonus(source, bonusValue, type) then
            wonVehicle = collectRandomReward(source, bonusRewards[bonusValue])
        end
    end

    if data.pumpkins then
        updateCollection("pumpkins", Config.BonusRewards.pumpkins)
    end

    if data.zombies then
        updateCollection("zombies", Config.BonusRewards.zombies)
    end

    DeleteEntity(entity)
    return wonVehicle, collectionCount[playerIdentifier]
end)



local bonusCollected = {}

---@param source number
---@param bonus string
---@param type string
---@return boolean
function alreadyCollectedBonus(source, bonus, type)
    local playerIdentifier = GetPlayerIdentifierByType(source, "license")

    if not bonusCollected[playerIdentifier] then
        bonusCollected[playerIdentifier] = {
            pumpkins = {},
            zombies = {}
        }
    end

    local isCollected = false

    if type == "pumpkins" then
        isCollected = bonusCollected[playerIdentifier].pumpkins[bonus] or false
        if not isCollected then
            bonusCollected[playerIdentifier].pumpkins[bonus] = true
        end
    elseif type == "zombies" then
        isCollected = bonusCollected[playerIdentifier].zombies[bonus] or false
        if not isCollected then
            bonusCollected[playerIdentifier].zombies[bonus] = true
        end
    end

    return isCollected
end

---@param target number
---@param item string
---@param quantity number
---@return boolean
local function removeItem(target, item, quantity)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(target)
        if not xPlayer then return false end

        local hasItem = xPlayer.getInventoryItem(item)
        if not hasItem or hasItem.count < quantity then return false end

        return xPlayer.removeInventoryItem(item, quantity)
    end

    if QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(target)
        if not xPlayer then return false end

        return xPlayer.Functions.RemoveItem(item, quantity)
    end

    if Ox then
        local count = exports.ox_inventory:Search(target, "count", item)
        if not count or count < quantity then return false end

        return exports.ox_inventory:RemoveItem(target, item, quantity)
    end

    return false
end

---@param source number
---@param data table
---@return boolean
lib.callback.register("ars_halloween:sellItem", function(source, data)
    local zoneData = Config.SpookyZones[data.zone]
    local item     = zoneData.shop.items[data.itemIndex]
    if not item then
        print("invalid item data")
        return false
    end

    local itemName     = item.name
    local quantity     = data.quantity
    local moneyToGive  = item.price * quantity

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    if #(playerCoords - zoneData.shop.coords.xyz) > 5 then
        print(("ID: [%s] triggered event %s"):format(source, "ars_halloween:sellItem"))
        return false
    end

    local hasItem = removeItem(source, itemName, quantity)
    if not hasItem then return false end

    addItem(source, "money", moneyToGive)
    return true
end)


lib.versionCheck('Arius-Scripts/ars_halloween')
