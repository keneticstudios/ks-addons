Edit = {}

--- qb-clothing resource name (see Config.QbClothingResource).
function Edit.QbClothingResource()
    local name = Config.QbClothingResource
    if type(name) == 'string' and name ~= '' then
        return name
    end
    return 'qb-clothing'
end

function Edit.SyncQbClothingFromPed(ped)
    if Config.Appearance ~= 'qb' then return end
    local res = Edit.QbClothingResource()
    if GetResourceState(res) ~= 'started' then return end
    pcall(function()
        exports[res]:syncClothingMapFromPed(ped or PlayerPedId())
    end)
end

function Edit.Input(title, defaultText)
    if GetResourceState('ox_lib') == 'started' then
        local input = exports.ox_lib:inputDialog(title, {
            { type = 'input', label = title, default = defaultText, required = true }
        })
        return input and input[1] or nil
    else
        AddTextEntry('KS_CLOTHING_INPUT', title)
        DisplayOnscreenKeyboard(1, "KS_CLOTHING_INPUT", "", defaultText or "", "", "", "", 30)
        while UpdateOnscreenKeyboard() == 0 do
            DisableAllControlActions(0)
            Wait(0)
        end
        if GetOnscreenKeyboardResult() then
            return GetOnscreenKeyboardResult()
        end
        return nil
    end
end

function Edit.Notify(msg, type)
    if Config.Notify == 'ox' and GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ type = type, description = msg })
    elseif Config.Notify == 'esx' and GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        ESX.ShowNotification(msg)
    elseif Config.Notify == 'qb' and GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        QBCore.Functions.Notify(msg, type)
    elseif Config.Notify == 'qbox' and GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(msg, type)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end


local function toIlleniumComponent(data)
    return { component_id = data.index, drawable = data.value, texture = data.texture }
end

local function toIlleniumProp(data)
    return { prop_id = data.index, drawable = data.value, texture = data.texture }
end

function Edit.PedComponent(ped, data)
    if Config.Appearance == 'bl' then
        exports.bl_appearance:SetPedDrawable(ped, data)
    elseif Config.Appearance == 'illenium' then
        exports['illenium-appearance']:setPedComponent(ped, toIlleniumComponent(data))
    else 
        SetPedComponentVariation(ped, data.index, data.value, data.texture, 0)
    end
end

function Edit.PedProp(ped, data)
    if Config.Appearance == 'bl' then
        exports.bl_appearance:SetPedProp(ped, data)
    elseif Config.Appearance == 'illenium' then
        exports['illenium-appearance']:setPedProp(ped, toIlleniumProp(data))
    else
        if data.value == -1 then
            ClearPedProp(ped, data.index)
        else
            SetPedPropIndex(ped, data.index, data.value, data.texture, true)
        end
    end
end

function Edit.GetPedAppearance(ped)
    if Config.Appearance == 'bl' and GetResourceState('bl_appearance') == 'started' then
        local ok, appearance = pcall(function()
            return exports.bl_appearance:GetPedAppearance(ped)
        end)
        if ok and appearance then
            return appearance
        end
    elseif Config.Appearance == 'illenium' and GetResourceState('illenium-appearance') == 'started' then
        local ok, appearance = pcall(function()
            return exports['illenium-appearance']:getPedAppearance(ped)
        end)
        if ok and appearance then
            return appearance
        end
    elseif Config.Appearance == 'qb' then
        local res = Edit.QbClothingResource()
        if GetResourceState(res) == 'started' then
            Edit.SyncQbClothingFromPed(ped)
            local ok, data = pcall(function()
                return exports[res]:getSkinData()
            end)
            if ok and type(data) == 'table' then
                return data
            end
        end
    end

    local appearance = {
        model = GetEntityModel(ped),
        components = {},
        props = {},
        hair = {
            color = GetPedHairColor(ped),
            highlight = GetPedHairHighlightColor(ped)
        }
    }

    for i = 0, 11 do
        local drawable = GetPedDrawableVariation(ped, i)
        appearance.components[#appearance.components + 1] = {
            component_id = i,
            index = i,
            drawable = drawable,
            value = drawable,
            texture = GetPedTextureVariation(ped, i)
        }
    end

    for i = 0, 7 do
        local drawable = GetPedPropIndex(ped, i)
        appearance.props[#appearance.props + 1] = {
            prop_id = i,
            index = i,
            drawable = drawable,
            value = drawable,
            texture = math.max(0, GetPedPropTextureIndex(ped, i))
        }
    end

    return appearance
end




function Edit.SavePlayerAppearance(appearance)
    if Config.UseAdvanced and LocalPlayer.state.ksServiceMode then
        return
    end

    local customPayload = appearance

    
    if Config.Appearance == 'bl' then
        TriggerServerEvent("bl_appearance:server:saveAppearance", appearance)

    elseif Config.Appearance == 'illenium' then
        TriggerServerEvent("illenium-appearance:server:saveAppearance", appearance)

    elseif Config.Appearance == 'qb' then
        local ped = PlayerPedId()
        Edit.SyncQbClothingFromPed(ped)
        local toSave = appearance
        local res = Edit.QbClothingResource()
        if GetResourceState(res) == 'started' then
            local ok, data = pcall(function()
                return exports[res]:getSkinData()
            end)
            if ok and type(data) == 'table' then
                toSave = data
            end
        end
        customPayload = toSave
        TriggerServerEvent('ks-addons:clothes:server:saveQbSkin', GetEntityModel(ped), toSave)
    end
    
    
    if Config.CustomSaveEvent and Config.CustomSaveEvent ~= '' then
        TriggerServerEvent(Config.CustomSaveEvent, customPayload)
    end
end




lib.callback.register('ks-addons:clothes:client:getAppearance', function()
    local ped = PlayerPedId()
    return Edit.GetPedAppearance(ped)
end)

return Edit
