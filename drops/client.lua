local drops = {} 

-- Safety check if Config isn't loaded/defined
local Config = Config or {}
Config.GlowEnabled = Config.GlowEnabled or false
Config.DefaultProp = Config.DefaultProp or { `prop_paper_bag_01` }
Config.ItemModels = Config.ItemModels or {}

local function KSDeleteEntity(entity)
    if DoesEntityExist(entity) then
        -- Set as mission entity to ensure we have control to delete it
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function ApplyGlow(entity)
    if Config.GlowEnabled then
        local r = Config.GlowColor and Config.GlowColor.r or 255
        local g = Config.GlowColor and Config.GlowColor.g or 255
        local b = Config.GlowColor and Config.GlowColor.b or 255
        local a = Config.GlowColor and Config.GlowColor.a or 255

        if SetEntityDrawOutlineColor then
            SetEntityDrawOutlineColor(r, g, b, a)
            SetEntityDrawOutlineShader(1)
        end
        
        if SetEntityDrawOutline then
            SetEntityDrawOutline(entity, true)
        elseif SetEntityDrawOutlineSelection then
            -- Fallback for different builds/frameworks
            SetEntityDrawOutlineSelection(entity, true)
        end
    end
end

local function onEnterDrop(point)
    if not point.entities then point.entities = {} end

    local modelsToSpawn = {}

    -- 1. BUILD THE LIST OF MODELS
    -- We want to ensure every single item gets a prop, even if it's just a paper bag.
    if point.items and #point.items > 0 then
        for _, itemData in ipairs(point.items) do
            local itemName = type(itemData) == 'table' and itemData.name or itemData
            
            -- Check if we have a specific model config for this item name
            if Config.ItemModels and Config.ItemModels[itemName] then
                table.insert(modelsToSpawn, Config.ItemModels[itemName])
            else
                -- If not configured, insert the default prop immediately
                table.insert(modelsToSpawn, Config.DefaultProp[1])
            end
        end
    elseif point.models and #point.models > 0 then
        -- Fallback for systems that pass models directly instead of items
        modelsToSpawn = point.models
    else
        -- Absolute fallback
        modelsToSpawn = Config.DefaultProp
    end

    local coords = point.coords
    local totalItems = #modelsToSpawn

    -- Seed the random generator with the X+Y coords so the "random" positions 
    -- stay consistent every time you look at this specific drop.
    math.randomseed(math.floor(coords.x + coords.y))

    for i = 1, totalItems do
        local model = modelsToSpawn[i]
        if type(model) == 'string' then model = joaat(model) end

        -- 2. VALIDATION CHECK
        -- If model is invalid, swap to default paper bag to prevent errors
        if not IsModelValid(model) then
            local defaultModel = Config.DefaultProp[1]
            if type(defaultModel) == 'string' then defaultModel = joaat(defaultModel) end
            model = defaultModel
        end

        if IsModelValid(model) then
            if lib.requestModel(model, 500) then
                -- 3. CALCULATE POSITION (Circle + Random Jitter)
                local offsetX = 0.0
                local offsetY = 0.0

                if i > 1 then
                    -- Item 1 is center. Items 2+ are in a circle.
                    -- Calculate base angle: (360 degrees / remaining items)
                    local baseAngle = (i - 2) * (360 / (totalItems - 1))
                    
                    -- Add a random offset to angle (-20 to +20 degrees) to look natural
                    local randomAngle = baseAngle + math.random(-20, 20)
                    
                    -- Random radius between 0.25 and 0.45 so they aren't in a perfect robot circle
                    local randomRadius = math.random(25, 45) / 100.0 

                    offsetX = math.cos(math.rad(randomAngle)) * randomRadius
                    offsetY = math.sin(math.rad(randomAngle)) * randomRadius
                end

                -- Create Object
                local entity = CreateObject(model, coords.x + offsetX, coords.y + offsetY, coords.z, false, false, false)

                SetModelAsNoLongerNeeded(model)
                
                -- Place properly on ground
                PlaceObjectOnGroundProperly(entity)
                
                -- Slight random rotation for visual variety
                local currentRot = GetEntityRotation(entity, 2)
                SetEntityRotation(entity, currentRot.x, currentRot.y, math.random(0, 360) + 0.0, 2, true)

                FreezeEntityPosition(entity, true)
                SetEntityCollision(entity, false, true) 

                ApplyGlow(entity)

                table.insert(point.entities, entity)
            end
        end
    end
end

local function onExitDrop(point)
    if point.entities then
        for _, entity in ipairs(point.entities) do
            KSDeleteEntity(entity)
        end
        point.entities = {}
    end
end

local function createDropPoint(dropId, data)
    if not drops then drops = {} end
    
    -- Remove existing drop if it exists to update it
    if drops[dropId] then 
        drops[dropId]:remove() 
    end

    local pointData = {
        coords = data.coords,
        distance = 30,
        invId = dropId,
        instance = data.instance,
        models = data.models,
        items = data.items -- Added items to data so onEnter can access it
    }

    pointData.nearby = function(self)
        -- Only draw marker if configured and close enough
        if Config.DropMarker and self.currentDistance < 10 then
            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z + 0.2, 
                0,0,0, 0,180.0,0, 0.2,0.2,0.2, 255,255,255,100, false, true, 2, false, nil, nil, false)
        end
    end

    local point = lib.points.new(pointData)
    point.onEnter = onEnterDrop
    point.onExit = onExitDrop
    
    drops[dropId] = point
end

-- FIXED TYPO: ks-addonns -> ks-addons
RegisterNetEvent('ks-addons:drop:createDrop', function(dropId, data)
    if not dropId or not data then return end
    createDropPoint(dropId, data)
end)

RegisterNetEvent('ks-addons:drop:removeDrop', function(dropId)
    if drops and drops[dropId] then
        local point = drops[dropId]
        onExitDrop(point) -- Clean up entities first
        point:remove()    -- Remove point from polyzone/lib
        drops[dropId] = nil
    end
end)

RegisterNetEvent('ks-addons:drop:updateDropModels', function(dropId, models)
    if drops and drops[dropId] then
        local point = drops[dropId]
        
        -- Clean up old entities
        onExitDrop(point) 
        
        -- Update model data
        point.models = models 
        
        -- If player is currently standing inside the drop zone, respawn the new models immediately
        if point.currentDistance and point.currentDistance <= point.distance then
            onEnterDrop(point)
        end
    end
end)

local function CleanupDrops()
    if not drops then return end
    
    for dropId, point in pairs(drops) do
        onExitDrop(point)
        if point.remove then
            point:remove()
        end
    end
    
    drops = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupDrops()
end)