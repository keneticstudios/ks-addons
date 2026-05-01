local function withKs(cb)
    if GetResourceState('ks-addons') ~= 'started' then
        return
    end

    cb()
end

local function beginClothingSession()
    withKs(function()
        exports['ks-addons']:BeginShopSession('clothing')
    end)
end

local function endClothingSession()
    withKs(function()
        exports['ks-addons']:EndShopSession()
    end)
end


exports('BeginClothingSession', beginClothingSession)
exports('EndClothingSession', endClothingSession)


local explicitOpenEvents = {
    'bl_appearance:client:openClothingShop',
    'bl_appearance:client:openClothingMenu'
}

for i = 1, #explicitOpenEvents do
    AddEventHandler(explicitOpenEvents[i], function()
        beginClothingSession()
    end)
end

local typedOpenEvents = {
    'bl_appearance:client:openShop',
    'bl_appearance:client:startCustomization',
    'bl_appearance:client:openMenu'
}

for i = 1, #typedOpenEvents do
    AddEventHandler(typedOpenEvents[i], function(menuType)
        if menuType ~= 'clothing' then return end
        beginClothingSession()
    end)
end

local closeEvents = {
    'bl_appearance:client:saveAppearance',
    'bl_appearance:client:cancelAppearance',
    'bl_appearance:client:closeClothingShop',
    'bl_appearance:client:closeShop',
    'bl_appearance:client:finishCustomization',
    'bl_appearance:client:reloadSkin'
}

for i = 1, #closeEvents do
    AddEventHandler(closeEvents[i], endClothingSession)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        endClothingSession()
    end
end)
