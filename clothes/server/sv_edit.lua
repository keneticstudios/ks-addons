Edit = {}

local function persistQbPlayerskin(citizenid, model, appearance)
    if not citizenid or model == nil or appearance == nil then
        return false
    end
    local skinStr = type(appearance) == 'string' and appearance or json.encode(appearance)
    MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', { citizenid }, function()
        MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {
            citizenid,
            model,
            skinStr,
            1
        })
    end)
    return true
end

--- Client-driven save (replaces routing saves only through qb-clothing); validates source player.
RegisterNetEvent('ks-addons:clothes:server:saveQbSkin', function(model, appearance)
    if Config.Appearance ~= 'qb' then return end
    local src = source
    if GetResourceState('qb-core') ~= 'started' then return end

    local QBCore = exports['qb-core']:GetCoreObject()
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    persistQbPlayerskin(Player.PlayerData.citizenid, model, appearance)
end)

function Edit.GetPlayerIdentifier(src)
    local qb = GetResourceState('qb-core') == 'started'
    local esx = GetResourceState('es_extended') == 'started'

    if qb then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid
    elseif esx then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    end

    local license = GetPlayerIdentifierByType(src, 'license')
    return license or GetPlayerName(src)
end

--- @param id string framework id (e.g. citizenid)
--- @param appearance table|string skin payload (qb skinData or JSON string)
--- @param model number|nil ped model hash; required unless appearance is a table with .model and .skin
function Edit.saveAppearance(id, appearance, model)
    if Config.Appearance == 'bl' then
        exports.bl_appearance:SavePlayerAppearance(id, appearance)

    elseif Config.Appearance == 'illenium' then
        if exports['illenium-appearance']['saveAppearance'] then
             exports['illenium-appearance']:saveAppearance(id, appearance)
        end

    elseif Config.Appearance == 'qb' then
        if not id or appearance == nil then return end
        local payload = appearance
        local modelHash = model
        if type(appearance) == 'table' and appearance.skin ~= nil then
            payload = appearance.skin
            modelHash = modelHash or appearance.model
        end
        if modelHash == nil then
            print('^3[KS-Addons] Edit.saveAppearance(qb): pass model hash as 3rd argument or use { model = ..., skin = ... }^0')
            return
        end
        if type(modelHash) == 'string' then
            modelHash = joaat(modelHash)
        end
        persistQbPlayerskin(id, modelHash, payload)
    end
end

function Edit.Notify(src, msg, type)
    if Config.Notify == 'ox' and GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, { type = type, description = msg })
    elseif Config.Notify == 'esx' and GetResourceState('es_extended') == 'started' then
        TriggerClientEvent('esx:showNotification', src, msg)
    elseif Config.Notify == 'qb' and GetResourceState('qb-core') == 'started' then
        TriggerClientEvent('QBCore:Notify', src, msg, type)
    elseif Config.Notify == 'qbox' and GetResourceState('qbx_core') == 'started' then
        TriggerClientEvent('qbx_core:Notify', src, msg, type)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^1SYSTEM', msg } })
    end
end

return Edit