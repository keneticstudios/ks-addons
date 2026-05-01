local previewPed = nil
local frontendActive = false
local currentResourceName = GetCurrentResourceName()
local isRefreshing = false 

-- 1. Helper to stop the game from deleting cars near you
local function ProtectNearbyVehicle()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        return vehicle
    end
    return nil
end

-- 2. Helper to release the car back to normal traffic
local function ReleaseVehicleProtection(vehicle)
    if DoesEntityExist(vehicle) then
        SetVehicleAsNoLongerNeeded(vehicle)
    end
end

local function CleanupFrontendPed()
    frontendActive = false 
    isRefreshing = false

    -- 1. Detach from menu first
    GivePedToPauseMenu(0, 0)

    -- 2. Delete the entity
    if DoesEntityExist(previewPed) then
        SetEntityAsMissionEntity(previewPed, true, true)
        DeleteEntity(previewPed)
        previewPed = nil
    end

    -- 3. Reset UI
    SetPauseMenuPedLighting(false)
    SetFrontendActive(false)
    SetMouseCursorVisibleInMenus(true)
    ReplaceHudColourWithRgba(117, 0, 0, 0, 186) 
end

local function CreateFrontendPed()
    if previewPed then 
        CleanupFrontendPed() 
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    frontendActive = true

    -- Load Animation BEFORE cloning
    if not HasAnimDictLoaded(Config.Animation.dict) then
        RequestAnimDict(Config.Animation.dict)
        while not HasAnimDictLoaded(Config.Animation.dict) do Wait(0) end
    end

    local nearbyCar = ProtectNearbyVehicle()

    -- 1. Activate Menu FIRST
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY_NO_BACKGROUND"), false, -1)
    
    -- 2. CRITICAL WAIT: Give the menu time to open before sending the ped
    Wait(100)

    -- 3. CLONE PED: Local only (false, false)
    previewPed = ClonePed(playerPed, playerHeading, false, false)
    
    if DoesEntityExist(previewPed) then
        -- Setup Physics
        SetEntityAsMissionEntity(previewPed, true, true)
        FreezeEntityPosition(previewPed, true)
        SetEntityHasGravity(previewPed, false)
        SetEntityCollision(previewPed, false, false)
        SetEntityCompletelyDisableCollision(previewPed, false, false)
        SetEntityInvincible(previewPed, true)
        
        -- Move underground
        SetEntityCoords(previewPed, playerCoords.x, playerCoords.y, playerCoords.z - 10.0, false, false, false, true)
        
        -- Ensure it is VISIBLE (The menu needs to 'see' it)
        SetEntityVisible(previewPed, true, false)
        NetworkSetEntityInvisibleToNetwork(previewPed, true)

        -- 4. WAIT AGAIN: Ensure ped is created in the world
        Wait(50)

        -- 5. Attach to Menu
        GivePedToPauseMenu(previewPed, 1)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
        RequestScaleformMovie("PAUSE_MP_MENU_PLAYER_MODEL")
        
        -- 6. Play Animation
        TaskPlayAnim(previewPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        SetPedKeepTask(previewPed, true)
    end

    if nearbyCar then
        ReleaseVehicleProtection(nearbyCar)
    end

    ReplaceHudColourWithRgba(117, 0, 0, 0, 0)
    SetMouseCursorVisibleInMenus(false)

    -- Thread for Loop
    Citizen.CreateThread(function()
        while frontendActive do
            Wait(0)
            SetMouseCursorVisibleInMenus(false)

            if DoesEntityExist(previewPed) then
                -- Keep animation playing
                if not IsEntityPlayingAnim(previewPed, Config.Animation.dict, Config.Animation.anim, 3) then
                    TaskPlayAnim(previewPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            else
                -- If ped was deleted externally (and we aren't refreshing), close menu
                if not isRefreshing then 
                    CleanupFrontendPed()
                end
            end

            -- Close if pause menu was closed by ESC
            if not IsPauseMenuActive() and not isRefreshing then
                CleanupFrontendPed()
            end
        end
    end)
end

function RefreshFrontendPed()
    if not frontendActive then return end
    isRefreshing = true 
    
    GivePedToPauseMenu(0, 0) -- Detach

    if DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end

    -- Wait for cleanup
    Wait(50)

    if not HasAnimDictLoaded(Config.Animation.dict) then
        RequestAnimDict(Config.Animation.dict)
        while not HasAnimDictLoaded(Config.Animation.dict) do Wait(0) end
    end

    local nearbyCar = ProtectNearbyVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Clone again
    previewPed = ClonePed(playerPed, GetEntityHeading(playerPed), false, false)
    
    if DoesEntityExist(previewPed) then
        SetEntityAsMissionEntity(previewPed, true, true)
        SetEntityCoords(previewPed, playerCoords.x, playerCoords.y, playerCoords.z - 10.0, false, false, false, true)
        FreezeEntityPosition(previewPed, true)
        SetEntityHasGravity(previewPed, false)
        SetEntityCollision(previewPed, false, false)
        SetEntityInvincible(previewPed, true)
        SetEntityVisible(previewPed, true, false)
        NetworkSetEntityInvisibleToNetwork(previewPed, true)
        
        Wait(50) -- Wait for existence

        RequestScaleformMovie("PAUSE_MP_MENU_PLAYER_MODEL")
        GivePedToPauseMenu(previewPed, 1)
        SetPauseMenuPedSleepState(true)
        SetMouseCursorVisibleInMenus(false)

        TaskPlayAnim(previewPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        SetPedKeepTask(previewPed, true)
    end
    
    if nearbyCar then ReleaseVehicleProtection(nearbyCar) end
    
    isRefreshing = false 
end

RegisterNetEvent('ks-addons:pedpreview:refreshFrontendPed', function()
    RefreshFrontendPed()
end)

RegisterNetEvent('ks-addons:pedpreview:openFrontendPed', function()
    CreateFrontendPed()
end)

RegisterNetEvent('ks-addons:pedpreview:closeFrontendPed', function()
    CleanupFrontendPed()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (currentResourceName ~= resourceName) then return end
    GivePedToPauseMenu(0, 0)
    if DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end
    ReplaceHudColourWithRgba(117, 0, 0, 0, 186)
end)