local SetRelationshipBetweenGroups = SetRelationshipBetweenGroups
local DecorRegister = DecorRegister
local AddRelationshipGroup = AddRelationshipGroup
local CreateThread = CreateThread
local Wait = Wait
local IsPedHuman = IsPedHuman
local IsPedAPlayer = IsPedAPlayer
local IsPedDeadOrDying = IsPedDeadOrDying
local GetEntityPopulationType = GetEntityPopulationType
local DecorExistOn = DecorExistOn
local SetPedRelationshipGroupHash = SetPedRelationshipGroupHash
local ApplyPedDamagePack = ApplyPedDamagePack
local DecorSetBool = DecorSetBool
local ClearPedSecondaryTask = ClearPedSecondaryTask
local ClearPedTasksImmediately = ClearPedTasksImmediately
local TaskWanderStandard = TaskWanderStandard
local SetEntityHealth = SetEntityHealth
local SetPedRagdollBlockingFlags = SetPedRagdollBlockingFlags
local SetPedCanRagdollFromPlayerImpact = SetPedCanRagdollFromPlayerImpact
local SetPedDiesWhenInjured = SetPedDiesWhenInjured
local DisablePedPainAudio = DisablePedPainAudio
local StopPedSpeaking = StopPedSpeaking
local SetPedMute = SetPedMute
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local RemoveAllPedWeapons = RemoveAllPedWeapons
local SetPedMovementClipset = SetPedMovementClipset
local GetEntityCoords = GetEntityCoords
local TaskGoToEntity = TaskGoToEntity
local TaskPlayAnim = TaskPlayAnim
local ApplyDamageToPed = ApplyDamageToPed
local SetPedToRagdoll = SetPedToRagdoll
local SendNUIMessage = SendNUIMessage
local SetPedMotionBlur = SetPedMotionBlur
local ResetPedMovementClipset = ResetPedMovementClipset
local math = math
local NetworkFadeOutEntity = NetworkFadeOutEntity
local PlaySoundFrontend = PlaySoundFrontend
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity

local zombiesCreated = {}
local zombieGroup = `ZOMBIE`
local playerGroup = `PLAYER`
local drunkMovementSet = lib.requestAnimSet("move_m@drunk@verydrunk")
local injuredMovementSet = lib.requestAnimSet("move_injured_generic")
local crouchMovementSet = lib.requestAnimSet("move_ped_crouched")
local attackAnimationDict = lib.requestAnimDict("melee@unarmed@streamed_core_fps")
local zombiesCollected = 0

SetRelationshipBetweenGroups(0, zombieGroup, playerGroup)
SetRelationshipBetweenGroups(5, playerGroup, zombieGroup)
DecorRegister('Zombie', 2)
AddRelationshipGroup('ZOMBIE')

---@param zone table
function handleZombie(zone)
    CreateThread(function()
        while currentZone do
            for zombie, value in pairs(zombiesCreated) do
                manageZombieBehavior(zombie)
            end
            Wait(2000)
        end
    end)

    CreateThread(function()
        while currentZone do
            local nearbyPeds = lib.getNearbyPeds(zone.coords, zone.radius)

            for _, entity in pairs(nearbyPeds) do
                local zombiePed = entity.ped
                if IsPedHuman(zombiePed) and not IsPedAPlayer(zombiePed) and not IsPedDeadOrDying(zombiePed, true) then
                    if GetEntityPopulationType(zombiePed) == 7 then -- if created from a script then skip
                        goto continue
                    end

                    if not DecorExistOn(zombiePed, 'Zombie') then
                        initializeZombie(zombiePed)
                    end

                    ::continue::
                end
            end
            Wait(5000)
        end
    end)
end

---@param zombie number
function initializeZombie(zombie)
    zombiesCreated[zombie] = true

    ClearPedSecondaryTask(zombie)
    ClearPedTasksImmediately(zombie)

    SetPedRelationshipGroupHash(zombie, 'ZOMBIE')
    ApplyPedDamagePack(zombie, 'BigHitByVehicle', 0.0, 1.0)
    ApplyPedDamagePack(zombie, "SCR_Dumpster", 0.0, 9.0)
    ApplyPedDamagePack(zombie, "SCR_Torture", 0.0, 9.0)
    DecorSetBool(zombie, 'Zombie', true)

    TaskWanderStandard(zombie, 10.0, 10)
    SetEntityHealth(zombie, 350.0)

    SetPedRagdollBlockingFlags(zombie, 1)
    SetPedCanRagdollFromPlayerImpact(zombie, false)
    SetPedDiesWhenInjured(zombie, false)

    DisablePedPainAudio(zombie, true)
    StopPedSpeaking(zombie, true)

    SetPedMute(zombie)
    SetBlockingOfNonTemporaryEvents(zombie, true)
    RemoveAllPedWeapons(zombie, true)

    SetPedMovementClipset(zombie, drunkMovementSet, 1.0)
end

---@param zombie number
function manageZombieBehavior(zombie)
    if IsPedDeadOrDying(zombie) then
        if zombiesCreated[zombie] then zombiesCreated[zombie] = false end
        return
    end

    if IsPedDeadOrDying(playerPed) or LocalPlayer.state.dead then return end

    local playerCoords = cache.coords
    local zombieCoords = GetEntityCoords(zombie)
    local distance = #(zombieCoords - playerCoords)
    local chaseDistance = 60.0

    if distance <= chaseDistance then
        TaskGoToEntity(zombie, playerPed, -1, 0.0, 2.0, 1073741824, 0)
    end
    if distance <= 2.0 then
        attackPlayer(zombie)
    end
end

---@param zombie number
function attackPlayer(zombie)
    CreateThread(function()
        local health = GetEntityHealth(playerPed)
        if health > 0 then
            TaskPlayAnim(zombie, attackAnimationDict, 'ground_attack_0_psycho', 8.0, 1.0, -1, 48, 0.001, false, false,
                false)

            local randomDamage = math.random(1, 5)
            ApplyDamageToPed(playerPed, randomDamage, false)

            local ragdollChance = math.random(1, 100)
            if ragdollChance <= 30 then
                SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
            end
            SendNUIMessage({
                action = "applyDamage",
            })

            Wait(500)

            SetPedMotionBlur(playerPed, true)
            SetPedMovementClipset(playerPed, injuredMovementSet, 0.30)

            Wait(5000)
            ResetPedMovementClipset(playerPed, 0.30)
        end
    end)
end

---@param entity number
function lootZombie(entity)
    SetPedMovementClipset(playerPed, crouchMovementSet, 0.30)

    local progress = lib.progressBar(Config.Progress.zombie)
    ResetPedMovementClipset(playerPed, 0.30)
    if not progress then return end

    local items = currentZone.zombies.items
    local randomIndex = math.random(1, #items)
    local data = {
        item = items[randomIndex],
        netId = NetworkGetNetworkIdFromEntity(entity)
    }

    NetworkFadeOutEntity(entity)
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 0)
    if zombiesCreated[entity] then
        zombiesCreated[entity] = false
    end
    TriggerServerEvent("ars_halloween:collectEntity", data)

    scarePlayer()
    zombiesCollected += 1
    SendNUIMessage({
        action = "updateCard",
        zombiesCollected = zombiesCollected
    })

    local bonus = Config.BonusRewards.pumpkins[zombiesCollected]
    if bonus then
        local alreadyCollected = lib.callback.await("ars_halloween:checkBonus", false, zombiesCollected)
        if alreadyCollected then return end
        local bonusRewardsData = collectRandomReward(bonus)
        local bonusData = {
            item = bonusRewardsData.item,
            netId = NetworkGetNetworkIdFromEntity(entity),
            vehicle = bonusRewardsData.vehicle,
        }

        if bonusRewardsData.vehicle then
            UTILS.showNotification(L("win_vehicle"))
            doCelebration()
        end

        TriggerServerEvent("ars_halloween:collectEntity", bonusData)
    end
end

exports.ox_target:addGlobalPed({
    {
        label = L("examine_zombie_label"),
        icon = "fas fa-skull-crossbones",
        onSelect = function(data)
            local entity = data.entity
            lootZombie(entity)
        end,
        canInteract = function(entity)
            return IsEntityDead(entity) and DecorExistOn(entity, 'Zombie') and currentZone
        end,
        distance = 1.5,
    }
})

function removeAllZombies()
    for zombie, value in pairs(zombiesCreated) do
        if DoesEntityExist(zombie) then
            ClearPedTasksImmediately(zombie)
            DeleteEntity(zombie)
        end
    end
end
