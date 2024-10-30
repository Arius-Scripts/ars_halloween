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

---@param data table
RegisterNetEvent("ars_halloween:collectEntity", function(data)
    local source = source
    local entity = NetworkGetEntityFromNetworkId(data.netId)

    print(Entity(entity).state.zombie)

    local entityCoords = GetEntityCoords(entity)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - entityCoords) > 5 then
        return print(("ID: [%s] triggered event %s"):format(source, "ars_halloween:collectEntity"))
    end

    local item = data.item.name
    local quantity = math.random(data.item.minQuantity, data.item.maxQuantity)
    addItem(source, item, quantity)

    local vehicle = data.vehicle
    if vehicle then
        giveVehicle(source, vehicle)
    end

    DeleteEntity(entity)
end)

---@param source number
---@param bonus string
---@param type string
---@return boolean
lib.callback.register("ars_halloween:checkBonus", function(source, bonus, type)
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
end)

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
    local item        = data.item.name
    local quantity    = data.toSell
    local moneyToGive = data.item.price * quantity

    local hasItem     = removeItem(source, item, quantity)
    if not hasItem then return false end

    addItem(source, "money", moneyToGive)
    return true
end)


lib.versionCheck('Arius-Scripts/ars_halloween')
