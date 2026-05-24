local spawnedObjects = {}
local inTent = false
local currentTent = nil
local currentTentCoords = nil
local sittingOnChair = false
local currentChair = nil

ESX = exports['es_extended']:getSharedObject()

function GetObjectData(entity)
    for i = 1, #spawnedObjects do
        if spawnedObjects[i].entity == entity then
            return i, spawnedObjects[i]
        end
    end
    return nil, nil
end

RegisterNetEvent('camping:spawnPropClient', function(itemName, stashId)
    local ped = PlayerPedId()
    local cfg = Config.CampProps[itemName]
    if not cfg then return end

    local hash = joaat(cfg.model)
    lib.requestModel(hash)

    local progress = lib.progressBar({
        duration = cfg.duration,
        label = 'A montar ' .. cfg.label,
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { dict = cfg.anim.dict, clip = cfg.anim.clip },
    })

    if not progress then return end

    local forwardCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    local obj = CreateObject(hash, forwardCoords.x, forwardCoords.y, forwardCoords.z + 1.0, true, true, true)

    if itemName == 'fogueira' then
        local success, z = GetGroundZFor_3dCoord(forwardCoords.x, forwardCoords.y, forwardCoords.z + 1.0, false)
        SetEntityCoords(obj, forwardCoords.x, forwardCoords.y, success and z + 0.1 or forwardCoords.z + 0.1, false, false, false, false)
    elseif itemName == 'geladeira' then
        local success, z = GetGroundZFor_3dCoord(forwardCoords.x, forwardCoords.y, forwardCoords.z + 1.0, false)
        SetEntityCoords(obj, forwardCoords.x, forwardCoords.y, success and z + 0.4 or forwardCoords.z + 0.4, false, false, false, false)
    else
        PlaceObjectOnGroundProperly(obj)
    end

    FreezeEntityPosition(obj, true)

    spawnedObjects[#spawnedObjects + 1] = {
        entity = obj,
        item = itemName,
        stashId = stashId,
    }

    AddInteractions(obj)

    lib.notify({
        title = cfg.label,
        description = 'Colocado com sucesso!',
        type = 'success',
    })
end)

function OpenGrillMenu()
    local items = lib.callback.await('camping:getGrillableItems', false)

    if not items or #items == 0 then
        lib.notify({
            title = 'Fogueira',
            description = 'Não tens nada para assar.',
            type = 'error',
        })
        return
    end

    local options = {}
    for i = 1, #items do
        local entry = items[i]
        options[#options + 1] = {
            title = entry.label,
            description = ('Tens: %s'):format(entry.count),
            icon = 'fire',
            onSelect = function()
                GrillItem(entry.item, entry.label, entry.duration)
            end,
        }
    end

    lib.registerContext({
        id = 'camping_grill_menu',
        title = 'Assar na fogueira',
        options = options,
    })

    lib.showContext('camping_grill_menu')
end

function GrillItem(rawItem, label, duration)
    local success = lib.progressBar({
        duration = duration or 8000,
        label = 'A assar ' .. (label or 'comida'),
        canCancel = true,
        disable = { move = true, combat = true },
        anim = {
            dict = 'amb@prop_human_bbq@male@idle_a',
            clip = 'idle_b',
        },
    })

    if not success then return end

    local ok, msg = lib.callback.await('camping:grillItem', false, rawItem)

    if ok then
        lib.notify({
            title = 'Fogueira',
            description = (label or 'Comida') .. ' assado!',
            type = 'success',
        })
    else
        lib.notify({
            title = 'Fogueira',
            description = msg or 'Não foi possível assar.',
            type = 'error',
        })
    end
end

function AddInteractions(obj)
    exports.ox_target:addLocalEntity(obj, {
        {
            label = 'Recolher',
            icon = 'fas fa-hand',
            canInteract = function()
                return not inTent and not sittingOnChair
            end,
            onSelect = function()
                CollectProp(obj)
            end,
        },
        {
            label = 'Assar',
            icon = 'fas fa-fire',
            canInteract = function()
                local _, d = GetObjectData(obj)
                return d and d.item == 'fogueira' and not inTent and not sittingOnChair
            end,
            onSelect = function()
                OpenGrillMenu()
            end,
        },
        {
            label = 'Sentar',
            icon = 'fas fa-chair',
            canInteract = function()
                local _, d = GetObjectData(obj)
                return d and d.item == 'cadeira' and not sittingOnChair
            end,
            onSelect = function()
                SitOnChair(obj)
            end,
        },
        {
            label = 'Sair da cadeira',
            icon = 'fas fa-chair',
            canInteract = function()
                return sittingOnChair and currentChair == obj
            end,
            onSelect = function()
                ExitChair()
            end,
        },
        {
            label = 'Entrar na tenda',
            icon = 'fas fa-door-open',
            canInteract = function()
                local _, d = GetObjectData(obj)
                return d and d.item == 'tenda' and not inTent
            end,
            onSelect = function()
                EnterTent(obj)
            end,
        },
        {
            label = 'Sair da tenda',
            icon = 'fas fa-door-open',
            canInteract = function()
                return inTent and currentTent == obj
            end,
            onSelect = function()
                ExitTent()
            end,
        },
        {
            label = 'Abrir geladeira',
            icon = 'fas fa-box',
            canInteract = function()
                local _, d = GetObjectData(obj)
                return d and d.item == 'geladeira'
            end,
            onSelect = function()
                local _, d = GetObjectData(obj)
                if not d then return end

                TriggerServerEvent('camping:registerStash', d.stashId)
                Wait(300)
                exports.ox_inventory:openInventory('stash', d.stashId)
            end,
        },
    })
end

function EnterTent(obj)
    local ped = PlayerPedId()
    currentTentCoords = GetEntityCoords(obj)

    AttachEntityToEntity(ped, obj, -1, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, true)

    inTent = true
    currentTent = obj

    lib.notify({ title = 'Tenda', description = 'Entraste na tenda.', type = 'inform' })
end

function ExitTent()
    local ped = PlayerPedId()

    if not currentTentCoords and currentTent then
        currentTentCoords = GetEntityCoords(currentTent)
    end

    if not currentTentCoords then
        currentTentCoords = GetEntityCoords(ped)
    end

    local exitCoords = currentTentCoords + vector3(2.0, 0.0, 0.0)

    DetachEntity(ped, true, false)
    Wait(100)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    Wait(50)
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    Wait(50)
    ClearPedTasks(ped)

    inTent = false
    currentTent = nil
    currentTentCoords = nil

    lib.notify({ title = 'Tenda', description = 'Saíste da tenda.', type = 'inform' })
end

function SitOnChair(obj)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(obj)
    local heading = GetEntityHeading(obj) - 180.0

    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR', coords.x, coords.y, coords.z, heading, 0, true, true)

    sittingOnChair = true
    currentChair = obj

    lib.notify({ title = 'Cadeira', description = 'Estás sentado.', type = 'inform' })
end

function ExitChair()
    ClearPedTasks(PlayerPedId())
    sittingOnChair = false
    currentChair = nil
    lib.notify({ title = 'Cadeira', description = 'Saíste da cadeira.', type = 'inform' })
end

function CollectProp(entity)
    local index, data = GetObjectData(entity)
    if not data then return end

    local cfg = Config.CampProps[data.item]
    if not cfg then return end

    local progress = lib.progressBar({
        duration = cfg.duration,
        label = 'A desmontar ' .. cfg.label,
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { dict = cfg.anim.dict, clip = cfg.anim.clip },
    })

    if not progress then return end

    exports.ox_target:removeLocalEntity(entity)
    DeleteEntity(entity)
    TriggerServerEvent('camping:collectItem', data.stashId, data.item)
    table.remove(spawnedObjects, index)

    lib.notify({
        title = 'Camping',
        description = cfg.label .. ' recolhido!',
        type = 'success',
    })
end

RegisterNetEvent('camping:cleanup', function()
    for i = #spawnedObjects, 1, -1 do
        local item = spawnedObjects[i]
        if DoesEntityExist(item.entity) then
            exports.ox_target:removeLocalEntity(item.entity)
            DeleteEntity(item.entity)
        end
    end

    spawnedObjects = {}
    inTent = false
    currentTent = nil
    currentTentCoords = nil
    sittingOnChair = false
    currentChair = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerEvent('camping:cleanup')
end)