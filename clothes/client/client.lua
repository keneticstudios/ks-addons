local nakedDefaults = Config.Naked
local ServiceMode = false 
local saveToken = 0
local isAdvanced = Config.UseAdvanced ~= false
local componentToItem = {}

for itemName, cfg in pairs(Config.ClothingItems) do
    componentToItem[cfg.type .. '_' .. cfg.id] = itemName
end

local simpleCache = {}
local shopSessionActive = false

local function debugLog(message)
    if Config.Debug then
        print(('[KS-Addons] %s'):format(message))
    end
end




local function SaveLook()
    
    if ServiceMode then return end

    saveToken = saveToken + 1
    local token = saveToken

    
    
    SetTimeout(1000, function()
        if token ~= saveToken then return end

        local ped = PlayerPedId()
        
        
        local appearance = Edit.GetPedAppearance(ped)
        
        
        Edit.SavePlayerAppearance(appearance)

        debugLog('Appearance saved to database')
    end)
end

local function SetServiceMode(state, shouldSyncServer)
    if not isAdvanced then
        state = false
    end

    ServiceMode = state == true

    LocalPlayer.state:set('ksServiceMode', ServiceMode, true)

    if shouldSyncServer ~= false then
        TriggerServerEvent('ks-addons:clothes:server:setServiceMode', ServiceMode)
    end

    if ServiceMode then
        TriggerServerEvent('ks-addons:clothes:server:validateServiceModeSlots')
    end
end

local function BeginShopSession(shopType)
    if not isAdvanced then return end

    TriggerServerEvent('ks-addons:clothes:server:beginShopSession', shopType or 'clothing')
    shopSessionActive = true

    if not ServiceMode then
        SetServiceMode(true, true)
    end
end

local function EndShopSession()
    if not isAdvanced then
        shopSessionActive = false
        return
    end

    if shopSessionActive then
        TriggerServerEvent('ks-addons:clothes:server:endShopSession')
        shopSessionActive = false
    end

    if ServiceMode then
        SetServiceMode(false, true)
    end
end

local function ScheduleFullReloadSync(delayMs)
    SetTimeout(delayMs or 1000, function()
        TriggerServerEvent('ks-addons:clothes:server:fullReloadSync')
    end)
end

local function RestoreAppearanceFromFramework()
    local illeniumStarted = GetResourceState('illenium-appearance') == 'started'
    local blStarted = GetResourceState('bl_appearance') == 'started'

    if Config.Appearance == 'illenium' and illeniumStarted then
        lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
            if appearance then
                exports['illenium-appearance']:setPlayerAppearance(appearance)
            end
            ScheduleFullReloadSync(500)
        end)
        return
    end

    if Config.Appearance == 'bl' and blStarted then
        TriggerEvent('bl_appearance:client:reloadSkin')
        ScheduleFullReloadSync(1000)
        return
    end

    if Config.Appearance == 'qb' then
        local qbRes = Edit.QbClothingResource()
        if GetResourceState(qbRes) == 'started' then
            local health = GetEntityHealth(PlayerPedId())
            local ok = pcall(function()
                exports[qbRes]:reloadSkin(health)
            end)
            if not ok then
                TriggerServerEvent('qb-clothes:loadPlayerSkin')
            end
            ScheduleFullReloadSync(3000)
            return
        end
    end

    if illeniumStarted then
        lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
            if appearance then
                exports['illenium-appearance']:setPlayerAppearance(appearance)
            end
            ScheduleFullReloadSync(500)
        end)
        return
    end

    if blStarted then
        TriggerEvent('bl_appearance:client:reloadSkin')
        ScheduleFullReloadSync(1000)
        return
    end

    ScheduleFullReloadSync(1000)
end

exports('ToggleServiceMode', function(state)
    SetServiceMode(state, true)

    if ServiceMode then
        
    else
        RestoreAppearanceFromFramework()
    end
end)

exports('BeginShopSession', function(shopType)
    BeginShopSession(shopType)
end)

exports('EndShopSession', function()
    EndShopSession()
end)




local function RestoreClothes()
    ServiceMode = false
    RestoreAppearanceFromFramework()
end

exports('RestoreClothes', RestoreClothes)
exports('IsAdvancedMode', function()
    return isAdvanced
end)

exports('IsServiceMode', function()
    return ServiceMode
end)

RegisterNetEvent('ks-addons:client:RestoreClothes', function()
    RestoreClothes()
end)

RegisterNetEvent('ks-addons:clothes:client:beginShopSession', function(shopType)
    BeginShopSession(shopType)
end)

RegisterNetEvent('ks-addons:clothes:client:endShopSession', function()
    EndShopSession()
end)


local explicitOpenEvents = {
    'bl_appearance:client:openClothingShop',
    'bl_appearance:client:openClothingMenu'
}

for i = 1, #explicitOpenEvents do
    AddEventHandler(explicitOpenEvents[i], function()
        BeginShopSession('clothing')
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
        BeginShopSession('clothing')
    end)
end

local closeEvents = {
    'bl_appearance:client:saveAppearance',
    'bl_appearance:client:cancelAppearance',
    'bl_appearance:client:closeClothingShop',
    'bl_appearance:client:closeShop',
    'bl_appearance:client:finishCustomization'
}

for i = 1, #closeEvents do
    AddEventHandler(closeEvents[i], function()
        EndShopSession()
    end)
end

AddEventHandler('bl_appearance:client:reloadSkin', function()
    EndShopSession()
end)

AddEventHandler('illenium-appearance:client:reloadSkin', function()
    EndShopSession()
end)




RegisterNetEvent('ks-addons:clothes:client:UseBag', function(data)
    if not isAdvanced then return Edit.Notify("Outfit system works only in advanced mode", "error") end
    if ServiceMode then return Edit.Notify("Не може да използвате това в момента", "error") end
    TriggerEvent('ks-addons:clothes:client:OpenOutfitDialog', data.slot)
end)

RegisterNetEvent('ks-addons:clothes:client:OpenOutfitDialog', function(bagSlot)
    if not isAdvanced then return end
    if exports.ox_inventory then exports.ox_inventory:closeInventory() end
    local outfitName = Edit.Input(Config.Locales.save_outfit_title or "Име на костюма", "")
    if not outfitName or outfitName == "" then return Edit.Notify("Трябва да въведете име!", "error") end
    TriggerServerEvent('ks-addons:clothes:server:CreateOutfit', bagSlot, outfitName)
end)

RegisterNetEvent('ks-addons:clothes:client:UseOutfit', function(data)
    if not isAdvanced then return Edit.Notify("Outfit system works only in advanced mode", "error") end
    if ServiceMode then return Edit.Notify("Не може да използвате това в момента", "error") end
    TriggerServerEvent('ks-addons:clothes:server:UnpackOutfit', data.slot)
end)

local function IsAllowableProp(type, id)
    if type == 'prop' then return true end
    return false
end


RegisterNetEvent('ks-addons:clothes:client:EquipItem', function(config, metadata, itemName)
    local ped = PlayerPedId()

    if not isAdvanced and itemName and (not metadata or metadata.drawable == nil) then
        metadata = simpleCache[itemName]
    end

    if not metadata or metadata.drawable == nil then return end
    local data = { index = config.id, value = metadata.drawable, texture = metadata.texture or 0 }

    if config.type == 'component' then 
        Edit.PedComponent(ped, data) 
    else 
        Edit.PedProp(ped, data) 
    end

    if not isAdvanced and itemName then
        simpleCache[itemName] = {
            drawable = metadata.drawable,
            texture = metadata.texture or 0
        }
    end
    
    
    if not ServiceMode then
        SaveLook()
        RequestAnimDict("clothingtie")
        while not HasAnimDictLoaded("clothingtie") do Wait(0) end
        TaskPlayAnim(ped, "clothingtie", "try_tie_neutral_a", 8.0, -8.0, 1000, 49, 0, false, false, false)
    end
    TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
end)


RegisterNetEvent('ks-addons:clothes:client:UnequipItem', function(config, itemName)
    local ped = PlayerPedId()

    if not isAdvanced and itemName then
        if config.type == 'component' then
            simpleCache[itemName] = {
                drawable = GetPedDrawableVariation(ped, config.id),
                texture = GetPedTextureVariation(ped, config.id)
            }
        else
            simpleCache[itemName] = {
                drawable = GetPedPropIndex(ped, config.id),
                texture = math.max(0, GetPedPropTextureIndex(ped, config.id))
            }
        end
    end

    local model = GetEntityModel(ped)
    local defaults = (model == 1885233650) and nakedDefaults.male or nakedDefaults.female
    local key = (config.type == 'prop') and ('p'..config.id) or config.id
    local def = defaults[key]

    if def then
        local data = { index = config.id, value = def.drawable, texture = def.texture }
        if config.type == 'component' then 
            Edit.PedComponent(ped, data) 
        else 
            Edit.PedProp(ped, data) 
        end
        
        
        if not ServiceMode then
            SaveLook()
        end
    end
    TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
end)

exports('clearSkin', function() end)

RegisterNetEvent('ks-addons:clothes:client:ApplyChangedItems', function(changedItems)
    if isAdvanced or not changedItems then return end

    local ped = PlayerPedId()

    for indexKey, data in pairs(changedItems) do
        local index = tonumber(indexKey) or tonumber(data.index) or tonumber(data.id)

        if not index and data.type and data.drawable ~= nil then
            local key = data.type .. '_' .. tostring(data.id)
            local itemName = componentToItem[key]
            if itemName and Config.ClothingItems[itemName] then
                index = Config.ClothingItems[itemName].id
            end
        end

        if index and data.drawable ~= nil then
            local payload = { index = index, value = data.drawable, texture = data.texture or 0 }

            if data.type == 'component' then
                Edit.PedComponent(ped, payload)
            elseif data.type == 'prop' then
                Edit.PedProp(ped, payload)
            end
        end
    end

    SaveLook()
    TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
end)

RegisterNetEvent('skinchanger:modelLoaded', function()
    if not ServiceMode then 
        TriggerServerEvent('ks-addons:clothes:server:syncSlots')
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(2000)
        RestoreClothes()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        EndShopSession()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    RestoreClothes()
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(2000)
    RestoreClothes()
end)




local function ToggleClothingItem(itemName)
    local config = Config.ClothingItems[itemName]
    if not config then 
        Edit.Notify("Невалидно облекло: " .. itemName, "error")
        return 
    end
    
    
    TriggerServerEvent('ks-addons:clothes:server:toggleClothing', itemName)
end

exports('ToggleClothing', ToggleClothingItem)


for itemName, _ in pairs(Config.ClothingItems) do
    RegisterCommand(itemName, function()
        ToggleClothingItem(itemName)
    end, false)
end


RegisterCommand('accessories', function()
    ToggleClothingItem('hat')
    Wait(100)
    ToggleClothingItem('glasses')
    Wait(100)
    ToggleClothingItem('earrings')
    Wait(100)
    ToggleClothingItem('chain')
    Wait(100)
    ToggleClothingItem('watch')
    Wait(100)
    ToggleClothingItem('bracelet')
end, false)




CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            SetEntityAlwaysPrerender(ped, true)
            SetEntityRenderScorched(ped, true)
        end
        Wait(2000)
    end
end)