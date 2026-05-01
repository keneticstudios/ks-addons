local ox_inventory = exports.ox_inventory
local MySQL = exports.oxmysql
local isAdvanced = Config.UseAdvanced ~= false
local requireShopInAdvanced = isAdvanced and Config.RequireClothingShopInAdvanced == true
local serviceModePlayers = {}
local shopSessions = {}
local shopSessionTimeout = Config.ShopSessionTimeout or 120000
local outfitTable = Config.OutfitTable or 'ks_outfits'
local outfitColumns = Config.OutfitColumns or {}
local outfitIdentifierCol = outfitColumns.identifier or 'citizenid'
local outfitNameCol = outfitColumns.name or 'name'
local outfitDataCol = outfitColumns.data or 'items'

local function debugLog(message)
    if Config.Debug then
        print(('[KS-Addons] %s'):format(message))
    end
end

exports('GetConfiguredDropModel', function(itemName)
    if not itemName then return nil end
    return Config.ItemModels and Config.ItemModels[itemName] or nil
end)


local clothingConfig = Config.ClothingItems
local slotToItem = {}
local itemToConfig = {}
local idToName = {}

for name, data in pairs(clothingConfig) do
    slotToItem[data.slot] = name
    itemToConfig[name] = data
    local key = data.type .. "_" .. data.id
    idToName[key] = name
end

local function isPlayerInServiceMode(src)
    return serviceModePlayers[src] == true
end

local function hasActiveShopSession(src)
    if not requireShopInAdvanced then return true end

    local expiresAt = shopSessions[src]
    if not expiresAt then return false end

    local now = GetGameTimer()
    if now > expiresAt then
        shopSessions[src] = nil
        return false
    end

    return true
end

local function refreshShopSession(src)
    if requireShopInAdvanced then
        shopSessions[src] = GetGameTimer() + shopSessionTimeout
    end
end

local function clearShopSession(src)
    shopSessions[src] = nil
end

RegisterNetEvent('ks-addons:clothes:server:setServiceMode', function(state)
    local src = source

    if not isAdvanced then
        serviceModePlayers[src] = false
        return
    end

    serviceModePlayers[src] = state == true
end)

RegisterNetEvent('ks-addons:clothes:server:beginShopSession', function(shopType)
    if not isAdvanced then return end
    if shopType and shopType ~= 'clothing' then return end

    refreshShopSession(source)
end)

RegisterNetEvent('ks-addons:clothes:server:endShopSession', function()
    clearShopSession(source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    serviceModePlayers[src] = nil
    shopSessions[src] = nil
end)




local function RestorePlayerAppearance(src)
    if not isAdvanced then
        for name, config in pairs(clothingConfig) do
            local item = ox_inventory:GetSlot(src, config.slot)

            if not item or item.name ~= name then
                TriggerClientEvent('ks-addons:clothes:client:UnequipItem', src, config, name)
            elseif item.metadata and item.metadata.drawable ~= nil then
                TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, item.metadata, name)
            end
        end

        return
    end

    
    for name, config in pairs(clothingConfig) do
        local item = ox_inventory:GetSlot(src, config.slot)
        
        if item and item.name == name and item.metadata and item.metadata.drawable then
            
            TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, item.metadata, name)
        else
            
            
            TriggerClientEvent('ks-addons:clothes:client:UnequipItem', src, config, name)
        end
    end
end

RegisterNetEvent('ks-addons:clothes:server:syncSlots', function()
    local src = source
    RestorePlayerAppearance(src)
end)




RegisterNetEvent('ks-addons:clothes:server:fullReloadSync', function()
    local src = source

    if not isAdvanced then
        RestorePlayerAppearance(src)
        return
    end

    local identifier = Edit.GetPlayerIdentifier(src)
    
    if not identifier then 
        debugLog('fullReloadSync: no identifier found')
        return 
    end
    
    
    local dbClothes = Edit.GetPlayerDbClothes(src, identifier)
    
    
    local inventoryItems = ox_inventory:GetInventoryItems(src)
    for slot, item in pairs(inventoryItems or {}) do
        local itemSlot = item.slot or slot
        if item and clothingConfig[item.name] then
            local correctSlot = clothingConfig[item.name].slot
            if itemSlot ~= correctSlot then
                ox_inventory:RemoveItem(src, item.name, item.count, nil, itemSlot)
                debugLog(('Removed duplicate %s from slot %s'):format(item.name, itemSlot))
            end
        end
    end
    
    if not dbClothes then
        debugLog('fullReloadSync: no DB clothes found, fallback to syncSlots')
        RestorePlayerAppearance(src)
        return
    end
    
    
    local toRemove, toAdd = Edit.CompareClothesWithSlots(src, dbClothes)
    
    
    for _, item in ipairs(toRemove) do
        ox_inventory:RemoveItem(src, item.name, 1, nil, item.slot)
    end
    
    
    for _, item in ipairs(toAdd) do
        local metadata = {
            drawable = item.drawable,
            texture = item.texture,
            description = string.format(Config.Locales.item_desc, item.drawable, item.texture)
        }
        ox_inventory:AddItem(src, item.name, 1, metadata, item.slot)
    end
    
    
    SetTimeout(100, function()
        RestorePlayerAppearance(src)
    end)
    
    debugLog(('fullReloadSync completed for player %s'):format(src))
end)




RegisterNetEvent('ks-addons:clothes:server:validateServiceModeSlots', function()
    if not isAdvanced then return end

    local src = source
    local identifier = Edit.GetPlayerIdentifier(src)
    
    if not identifier then return end
    
    
    local dbClothes = Edit.GetPlayerDbClothes(src, identifier)
    
    if not dbClothes then
        debugLog(('validateServiceModeSlots: no DB clothes for %s'):format(src))
        return
    end
    
    
    local toRemove, toAdd = Edit.CompareClothesWithSlots(src, dbClothes)
    
    
    if #toRemove > 0 or #toAdd > 0 then
        
        for _, item in ipairs(toRemove) do
            ox_inventory:RemoveItem(src, item.name, 1, nil, item.slot)
        end
        
        
        for _, item in ipairs(toAdd) do
            local metadata = {
                drawable = item.drawable,
                texture = item.texture,
                description = string.format(Config.Locales.item_desc, item.drawable, item.texture)
            }
            ox_inventory:AddItem(src, item.name, 1, metadata, item.slot)
        end
        
        debugLog(('validateServiceModeSlots: fixed %s items for %s'):format(#toAdd, src))
    end
end)




RegisterNetEvent('ks-addons:clothes:server:CreateOutfit', function(bagSlot, outfitName)
    if not isAdvanced then return end

    local src = source
    local identifier = Edit.GetPlayerIdentifier(src)
    
    local savedClothes = {}

    
    for name, config in pairs(clothingConfig) do
        local item = ox_inventory:GetSlot(src, config.slot)
        if item and item.name == name then
            table.insert(savedClothes, {
                name = item.name,
                metadata = item.metadata,
                label = item.label
            })
        end
    end

    if #savedClothes == 0 then
        Edit.Notify(src, Config.Locales.no_clothes_slots, 'error')
        return
    end

    local jsonData = json.encode(savedClothes)
    local query = ('INSERT INTO `%s` (`%s`, `%s`, `%s`) VALUES (?, ?, ?)'):format(outfitTable, outfitIdentifierCol, outfitNameCol, outfitDataCol)
    
    exports.oxmysql:insert(query, { identifier, outfitName, jsonData }, function(insertId)
        if not insertId then return end

        
        ox_inventory:RemoveItem(src, 'clothing_bag', 1, nil, bagSlot)

        
        

        local metadata = {
            outfitId = insertId,
            label = outfitName,
            description = string.format(Config.Locales.outfit_desc, insertId)
        }
        
        ox_inventory:AddItem(src, 'clothes', 1, metadata)
        Edit.Notify(src, Config.Locales.outfit_created, 'success')
    end)
end)




RegisterNetEvent('ks-addons:clothes:server:UnpackOutfit', function(slot)
    if not isAdvanced then return end

    local src = source
    local identifier = Edit.GetPlayerIdentifier(src)
    local item = ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= 'clothes' then return end
    local metadata = item.metadata
    if not metadata or not metadata.outfitId then return end

    local query = ('SELECT `%s` AS `data` FROM `%s` WHERE `id` = ?'):format(outfitDataCol, outfitTable)
    exports.oxmysql:single(query, { metadata.outfitId }, function(result)
        if not result or not result.data then 
            Edit.Notify(src, Config.Locales.db_missing, 'error')
            return 
        end
        local newOutfitClothes = json.decode(result.data)

        
        local currentClothes = {}
        for name, config in pairs(clothingConfig) do
            local slotItem = ox_inventory:GetSlot(src, config.slot)
            if slotItem and slotItem.name == name then
                table.insert(currentClothes, {
                    name = slotItem.name,
                    metadata = slotItem.metadata,
                    label = slotItem.label
                })
            end
        end

        
        for name, config in pairs(clothingConfig) do
            local slotItem = ox_inventory:GetSlot(src, config.slot)
            if slotItem and slotItem.name == name then
                ox_inventory:RemoveItem(src, name, 1, nil, config.slot)
            end
        end

        
        ox_inventory:RemoveItem(src, 'clothes', 1, nil, slot)

        
        for _, itemInfo in ipairs(newOutfitClothes) do
            if itemInfo.name and itemInfo.metadata then
                local config = clothingConfig[itemInfo.name]
                if config then
                    ox_inventory:AddItem(src, itemInfo.name, 1, itemInfo.metadata, config.slot)
                end
            end
        end

        
        if #currentClothes > 0 then
            local jsonData = json.encode(currentClothes)
            local insertQuery = ('INSERT INTO `%s` (`%s`, `%s`, `%s`) VALUES (?, ?, ?)'):format(outfitTable, outfitIdentifierCol, outfitNameCol, outfitDataCol)
            
            exports.oxmysql:insert(insertQuery, { identifier, metadata.label or 'Swapped Outfit', jsonData }, function(insertId)
                if insertId then
                    local newMeta = {
                        outfitId = insertId,
                        label = metadata.label or 'Swapped Outfit',
                        description = string.format(Config.Locales.outfit_desc, insertId)
                    }
                    ox_inventory:AddItem(src, 'clothes', 1, newMeta)
                end
            end)
        end

        
        exports.oxmysql:update(('DELETE FROM `%s` WHERE `id` = ?'):format(outfitTable), { metadata.outfitId })
        
        Edit.Notify(src, Config.Locales.outfit_unpacked, 'success')
        SetTimeout(500, function() RestorePlayerAppearance(src) end)
    end)
end)




local hookId = ox_inventory:registerHook('swapItems', function(payload)
    local src = payload.source
    local fromSlot = payload.fromSlot

    if not src or type(fromSlot) ~= 'table' or not fromSlot.name then
        return true
    end

    local toSlotIndex = (type(payload.toSlot) == 'table') and payload.toSlot.slot or payload.toSlot
    local fromSlotIndex = (type(fromSlot) == 'table') and fromSlot.slot or fromSlot
    local movingToPlayer = (payload.toInventory == src)
    local movingFromPlayer = (payload.fromInventory == src)
    local fromSpecial = movingFromPlayer and fromSlotIndex and slotToItem[fromSlotIndex]
    local toSpecial = movingToPlayer and toSlotIndex and slotToItem[toSlotIndex]

    if isAdvanced and Config.WorkModeLockSpecialSlots and isPlayerInServiceMode(src) and (fromSpecial or toSpecial) then
        Edit.Notify(src, Config.Locales.service_mode_locked or 'You cannot move clothing items while in work mode.', 'error')
        return false
    end

    if movingToPlayer and toSlotIndex and slotToItem[toSlotIndex] then
        local expectedName = slotToItem[toSlotIndex]

        if requireShopInAdvanced and not hasActiveShopSession(src) then
            Edit.Notify(src, Config.Locales.clothing_shop_only or 'Go to a clothing shop to change equipped advanced clothes.', 'error')
            return false
        end

        if fromSlot.name == expectedName then
            local config = clothingConfig[expectedName]
            if isAdvanced then
                if fromSlot.metadata and fromSlot.metadata.drawable ~= nil then
                    TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, fromSlot.metadata, expectedName)
                end
            else
                TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, fromSlot.metadata, expectedName)
            end
        else
            return false
        end
    end

    if movingFromPlayer and fromSlotIndex and slotToItem[fromSlotIndex] then
        local movedName = fromSlot.name
        if clothingConfig[movedName] and clothingConfig[movedName].slot == fromSlotIndex then
            local movingToSpecialSlot = movingToPlayer and (toSlotIndex and slotToItem[toSlotIndex])
            if not movingToSpecialSlot then
                local config = clothingConfig[movedName]
                TriggerClientEvent('ks-addons:clothes:client:UnequipItem', src, config, movedName)
            end
        end
    end
    return true
end, { print = false })




RegisterNetEvent("ks-addons:clothes:server:processPurchase", function(changedItems)
    local src = source
    if not changedItems then return end

    if not isAdvanced then
        TriggerClientEvent('ks-addons:clothes:client:ApplyChangedItems', src, changedItems)
        return
    end

    refreshShopSession(src)

    for indexStr, data in pairs(changedItems) do
        if type(data) ~= 'table' then
            goto continue
        end

        local index = tonumber(indexStr)
        local changeType = data.type
        local drawable = tonumber(data.drawable)
        local texture = tonumber(data.texture) or 0

        if (changeType ~= 'component' and changeType ~= 'prop') or not index or drawable == nil then
            goto continue
        end

        local key = changeType .. "_" .. index
        local itemName = idToName[key]

        if itemName and drawable ~= -1 then
            local config = clothingConfig[itemName]
            local metadata = {
                texture = texture,
                drawable = drawable,
                description = string.format(Config.Locales.item_desc, drawable, texture)
            }
            if config then
                local currentSlotItem = ox_inventory:GetSlot(src, config.slot)
                if not currentSlotItem then
                    ox_inventory:AddItem(src, itemName, 1, metadata, config.slot)
                elseif currentSlotItem.name ~= itemName then
                    ox_inventory:RemoveItem(src, currentSlotItem.name, 1, nil, config.slot)
                    ox_inventory:AddItem(src, itemName, 1, metadata, config.slot)
                else
                    ox_inventory:RemoveItem(src, itemName, 1, nil, config.slot)
                    ox_inventory:AddItem(src, itemName, 1, metadata, config.slot)
                end

                TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, metadata, itemName)
            else
                ox_inventory:AddItem(src, itemName, 1, metadata)
            end
        end

        ::continue::
    end
    
    SetTimeout(500, function() RestorePlayerAppearance(src) end)
end)

RegisterNetEvent("ks-addons:clothes:server:EquipFullOutfit", function(appearance)
    if not isAdvanced or not appearance then return end

    local src = source
    local function Equip(data, type)
        local index = data.index or data.component_id or data.prop_id
        if index == nil then return end

        local key = type .. '_' .. index
        local itemName = idToName[key]
        if itemName and clothingConfig[itemName] then
            local slot = clothingConfig[itemName].slot
            local drawable = data.value or data.drawable or data.item
            if drawable == nil then return end

            local metadata = {
                texture = data.texture or 0,
                drawable = drawable,
                description = string.format(Config.Locales.item_desc, drawable, data.texture or 0)
            }
            ox_inventory:RemoveItem(src, itemName, 1, nil, slot)
            ox_inventory:AddItem(src, itemName, 1, metadata, slot)
        end
    end

    if appearance.drawables then
        for _, data in pairs(appearance.drawables) do Equip(data, 'component') end
    end

    if appearance.components then
        for _, data in pairs(appearance.components) do Equip(data, 'component') end
    end

    if appearance.props then
        for _, data in pairs(appearance.props) do
            local drawable = data.value or data.drawable or data.item
            if drawable ~= nil and drawable ~= -1 then
                Equip(data, 'prop')
            end
        end
    end

    local qbMap = {
        mask = { type = 'component', id = 1 },
        arms = { type = 'component', id = 3 },
        pants = { type = 'component', id = 4 },
        bag = { type = 'component', id = 5 },
        shoes = { type = 'component', id = 6 },
        accessory = { type = 'component', id = 7 },
        ['t-shirt'] = { type = 'component', id = 8 },
        vest = { type = 'component', id = 9 },
        torso2 = { type = 'component', id = 11 },
        hat = { type = 'prop', id = 0 },
        glass = { type = 'prop', id = 1 },
        ear = { type = 'prop', id = 2 },
        watch = { type = 'prop', id = 6 },
        bracelet = { type = 'prop', id = 7 }
    }

    for key, map in pairs(qbMap) do
        local qbData = appearance[key]
        if qbData and qbData.item ~= nil and (map.type ~= 'prop' or qbData.item ~= -1) then
            Equip({
                index = map.id,
                value = qbData.item,
                texture = qbData.texture or 0
            }, map.type)
        end
    end
end)





RegisterNetEvent('ks-addons:clothes:server:unequipToInventory', function(itemName, fromSlot)
    local src = source

    if isAdvanced and Config.WorkModeLockSpecialSlots and isPlayerInServiceMode(src) then
        Edit.Notify(src, Config.Locales.service_mode_locked or 'You cannot move clothing items while in work mode.', 'error')
        return
    end

    local config = clothingConfig[itemName]
    if not config then return end
    
    local item = ox_inventory:GetSlot(src, fromSlot)
    if not item or item.name ~= itemName then return end
    
    
    local success = ox_inventory:RemoveItem(src, itemName, 1, nil, fromSlot)
    if success then
        ox_inventory:AddItem(src, itemName, 1, item.metadata)
        TriggerClientEvent('ks-addons:clothes:client:UnequipItem', src, config, itemName)
    end
end)


RegisterNetEvent('ks-addons:clothes:server:equipFromInventory', function(itemName, fromSlot, toSlot)
    local src = source

    if isAdvanced and Config.WorkModeLockSpecialSlots and isPlayerInServiceMode(src) then
        Edit.Notify(src, Config.Locales.service_mode_locked or 'You cannot move clothing items while in work mode.', 'error')
        return
    end

    if requireShopInAdvanced and not hasActiveShopSession(src) then
        Edit.Notify(src, Config.Locales.clothing_shop_only or 'Go to a clothing shop to change equipped advanced clothes.', 'error')
        return
    end

    local config = clothingConfig[itemName]
    if not config then return end
    
    local item = ox_inventory:GetSlot(src, fromSlot)
    if not item or item.name ~= itemName then return end
    
    
    local slotItem = ox_inventory:GetSlot(src, toSlot)
    if slotItem then
        Edit.Notify(src, "Слотът е зает!", "error")
        return
    end
    
    
    local success = ox_inventory:RemoveItem(src, itemName, 1, nil, fromSlot)
    if success then
        ox_inventory:AddItem(src, itemName, 1, item.metadata, toSlot)
        TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, item.metadata, itemName)
    end
end)




RegisterNetEvent('ks-addons:clothes:server:toggleClothing', function(itemName)
    local src = source

    if isAdvanced and Config.WorkModeLockSpecialSlots and isPlayerInServiceMode(src) then
        Edit.Notify(src, Config.Locales.service_mode_locked or 'You cannot move clothing items while in work mode.', 'error')
        return
    end

    local config = clothingConfig[itemName]
    if not config then 
        Edit.Notify(src, "Невалидно облекло", "error")
        return 
    end
    
    
    local slotItem = ox_inventory:GetSlot(src, config.slot)
    
    if slotItem and slotItem.name == itemName then
        
        local success = ox_inventory:RemoveItem(src, itemName, 1, nil, config.slot)
        if success then
            ox_inventory:AddItem(src, itemName, 1, slotItem.metadata)
            TriggerClientEvent('ks-addons:clothes:client:UnequipItem', src, config, itemName)
            Edit.Notify(src, "Свалено: " .. itemName, "success")
        end
    else
        if requireShopInAdvanced and not hasActiveShopSession(src) then
            Edit.Notify(src, Config.Locales.clothing_shop_only or 'Go to a clothing shop to change equipped advanced clothes.', 'error')
            return
        end

        
        local items = ox_inventory:GetInventoryItems(src)
        local foundItem = nil
        local foundSlot = nil
        
        for slot, item in pairs(items or {}) do
            if item.name == itemName then
                foundItem = item
                foundSlot = slot
                break
            end
        end
        
        if foundItem then
            
            if slotItem then
                Edit.Notify(src, "Слотът е зает!", "error")
                return
            end
            
            
            local success = ox_inventory:RemoveItem(src, itemName, 1, nil, foundSlot)
            if success then
                ox_inventory:AddItem(src, itemName, 1, foundItem.metadata, config.slot)
                TriggerClientEvent('ks-addons:clothes:client:EquipItem', src, config, foundItem.metadata, itemName)
                Edit.Notify(src, "Облечено: " .. itemName, "success")
            end
        else
            Edit.Notify(src, "Нямате " .. itemName .. " в инвентара", "error")
        end
    end
end)