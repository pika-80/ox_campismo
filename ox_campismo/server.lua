local spawnedProps = {}
local coolerStashes = {}

ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

-- USAR ITEM DE CAMPING
for _, itemName in ipairs(Config.CampingItems) do
    ESX.RegisterUsableItem(itemName, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        if xPlayer.getInventoryItem(itemName).count <= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = itemName,
                description = 'Não tens esse item!',
                type = 'error',
            })
            return
        end

        spawnedProps[source] = spawnedProps[source] or {}
        local stashId = ('camping_%s_%s'):format(source, itemName)

        xPlayer.removeInventoryItem(itemName, 1)
        spawnedProps[source][stashId] = itemName

        if itemName == 'geladeira' then
            ox_inventory:RegisterStash(
                stashId,
                Config.CoolerStash.label,
                Config.CoolerStash.slots,
                Config.CoolerStash.weight,
                stashId
            )
        end

        TriggerClientEvent('camping:spawnPropClient', source, itemName, stashId)
    end)
end

RegisterNetEvent('camping:registerStash', function(stashId)
    print(('^2[Camping] Abrir stash: %s^7'):format(stashId))
end)

RegisterNetEvent('camping:collectItem', function(stashId, itemName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if spawnedProps[src] and spawnedProps[src][stashId] then
        xPlayer.addInventoryItem(itemName, 1)
        spawnedProps[src][stashId] = nil

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Camping',
            description = itemName .. ' recolhido!',
            type = 'success',
        })
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if spawnedProps[src] then
        for stashId in pairs(spawnedProps[src]) do
            coolerStashes[stashId] = nil
        end
    end
    spawnedProps[src] = nil
end)

-- ASSAR NA FOGUEIRA
lib.callback.register('camping:getGrillableItems', function(source)
    local list = {}

    for rawItem, recipe in pairs(Config.GrillRecipes) do
        local count = ox_inventory:GetItemCount(source, rawItem)
        if count and count > 0 then
            list[#list + 1] = {
                item = rawItem,
                label = recipe.label,
                count = count,
                duration = recipe.duration,
            }
        end
    end

    table.sort(list, function(a, b)
        return a.label < b.label
    end)

    return list
end)

lib.callback.register('camping:grillItem', function(source, rawItem)
    local recipe = Config.GrillRecipes[rawItem]
    if not recipe then
        return false, 'Receita inválida.'
    end

    if ox_inventory:GetItemCount(source, rawItem) < 1 then
        return false, 'Já não tens esse item.'
    end

    if not ox_inventory:CanCarryItem(source, recipe.result, 1) then
        return false, 'Inventário cheio.'
    end

    if not ox_inventory:RemoveItem(source, rawItem, 1) then
        return false, 'Erro ao remover o item cru.'
    end

    if not ox_inventory:AddItem(source, recipe.result, 1) then
        ox_inventory:AddItem(source, rawItem, 1)
        return false, 'Erro ao dar o item assado.'
    end

    return true
end)