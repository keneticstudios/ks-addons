local clothingConfig = Config.ClothingItems


local idToName = {}
for name, data in pairs(clothingConfig) do
    local key = data.type .. "_" .. data.id
    idToName[key] = name
end





lib.callback.register('ks-addons:clothes:getClientAppearance', function(source)
    
    return nil
end)

--- Maps Config.ClothingItems keys to qb-clothing skinData keys (see qb-clothing ClothingMap).
local ksItemToQbSkinKey = {
    hat = 'hat',
    undershirt = 't-shirt',
    jacket = 'torso2',
    bodyarmor = 'vest',
    gloves = 'arms',
    pants = 'pants',
    shoes = 'shoes',
    mask = 'mask',
    glasses = 'glass',
    earrings = 'ear',
    chain = 'accessory',
    bracelet = 'bracelet',
    watch = 'watch',
    bag = 'bag',
}

local function GetPlayerDbClothes(src, identifier)
    if not src or not identifier then return nil end
    
    
    local ok, appearance = pcall(function()
        return lib.callback.await('ks-addons:clothes:client:getAppearance', src)
    end)

    if not ok then
        print(('^3[KS-Addons] GetPlayerDbClothes: failed to fetch client appearance for %s: %s^0'):format(src, appearance))
        return nil
    end
    
    if not appearance then 
        print("^3[KS-Addons] GetPlayerDbClothes: No appearance returned from client^0")
        return nil 
    end
    
    local clothes = {}

    if Config.Appearance == 'qb' then
        for itemName, cfg in pairs(clothingConfig) do
            local qbKey = ksItemToQbSkinKey[itemName]
            local slot = qbKey and appearance[qbKey]
            if qbKey and type(slot) == 'table' and slot.item ~= nil then
                if cfg.type ~= 'prop' or slot.item ~= -1 then
                    clothes[itemName] = {
                        type = cfg.type,
                        id = cfg.id,
                        drawable = slot.item,
                        texture = slot.texture or 0,
                    }
                end
            end
        end
        return clothes
    end
    
    
    if appearance.drawables then
        for _, drawable in pairs(appearance.drawables) do
            local index = drawable.index or drawable.component_id
            if index ~= nil then
                local key = "component_" .. index
                local itemName = idToName[key]
                if itemName then
                    clothes[itemName] = {
                        type = 'component',
                        id = index,
                        drawable = drawable.value or drawable.drawable,
                        texture = drawable.texture or 0
                    }
                end
            end
        end
    end

    if appearance.components then
        for _, component in pairs(appearance.components) do
            local index = component.index or component.component_id
            if index ~= nil then
                local key = "component_" .. index
                local itemName = idToName[key]
                if itemName then
                    clothes[itemName] = {
                        type = 'component',
                        id = index,
                        drawable = component.value or component.drawable,
                        texture = component.texture or 0
                    }
                end
            end
        end
    end
    
    
    if appearance.props then
        for _, prop in pairs(appearance.props) do
            local index = prop.index or prop.prop_id
            if index ~= nil then
                local key = "prop_" .. index
                local itemName = idToName[key]
                local drawableValue = prop.value or prop.drawable
                if itemName and drawableValue and drawableValue ~= -1 then
                    clothes[itemName] = {
                        type = 'prop',
                        id = index,
                        drawable = drawableValue,
                        texture = prop.texture or 0
                    }
                end
            end
        end
    end
    
    return clothes
end

Edit.GetPlayerDbClothes = GetPlayerDbClothes




local function CompareClothesWithSlots(src, dbClothes)
    if not dbClothes then return {}, {} end
    
    local ox_inventory = exports.ox_inventory
    local toRemove = {} 
    local toAdd = {}    
    
    for itemName, dbData in pairs(dbClothes) do
        local config = clothingConfig[itemName]
        if config then
            local slotItem = ox_inventory:GetSlot(src, config.slot)
            
            if slotItem and slotItem.name == itemName then
                
                local meta = slotItem.metadata
                if meta and meta.drawable == dbData.drawable and meta.texture == dbData.texture then
                    
                else
                    
                    table.insert(toRemove, { name = itemName, slot = config.slot })
                    table.insert(toAdd, {
                        name = itemName,
                        slot = config.slot,
                        drawable = dbData.drawable,
                        texture = dbData.texture
                    })
                end
            elseif slotItem then
                
                table.insert(toRemove, { name = slotItem.name, slot = config.slot })
                table.insert(toAdd, {
                    name = itemName,
                    slot = config.slot,
                    drawable = dbData.drawable,
                    texture = dbData.texture
                })
            else
                
                table.insert(toAdd, {
                    name = itemName,
                    slot = config.slot,
                    drawable = dbData.drawable,
                    texture = dbData.texture
                })
            end
        end
    end
    
    
    for itemName, config in pairs(clothingConfig) do
        if not dbClothes[itemName] then
            local slotItem = ox_inventory:GetSlot(src, config.slot)
            if slotItem and slotItem.name == itemName then
                table.insert(toRemove, { name = itemName, slot = config.slot })
            end
        end
    end
    
    return toRemove, toAdd
end

Edit.CompareClothesWithSlots = CompareClothesWithSlots

return Edit
