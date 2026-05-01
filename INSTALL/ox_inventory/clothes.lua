local clothingSlotMap = {
	[31] = { type = 'prop', id = 0 },       -- Hat
	[32] = { type = 'component', id = 8 },  -- Undershirt
	[33] = { type = 'component', id = 11 }, -- Jacket
	[34] = { type = 'component', id = 9 },  -- Body Armor
	[35] = { type = 'component', id = 3 },  -- Gloves
	[36] = { type = 'component', id = 4 },  -- Pants
	[37] = { type = 'component', id = 6 },  -- Shoes
	[38] = { type = 'component', id = 1 },  -- Mask
	[39] = { type = 'prop', id = 1 },       -- Glasses
	[40] = { type = 'prop', id = 2 },       -- Earrings
	[41] = { type = 'component', id = 7 },  -- Chain
	[42] = { type = 'prop', id = 7 },       -- Bracelet
	[43] = { type = 'prop', id = 6 },       -- Watch
	[44] = { type = 'component', id = 5 },  -- Bag
}

local storedClothing = {}

RegisterNUICallback('removeClothing', function(data, cb)
	cb(1)
	
	local slot = data.slot
	local mapping = clothingSlotMap[slot]
	
	if not mapping then return end
	
	local ped = cache.ped
	
	if mapping.type == 'prop' then
		-- Check if prop is currently worn
		local currentProp = GetPedPropIndex(ped, mapping.id)
		local currentTexture = GetPedPropTextureIndex(ped, mapping.id)
		
		if storedClothing[slot] then
			-- Restore the stored prop
			SetPedPropIndex(ped, mapping.id, storedClothing[slot].drawable, storedClothing[slot].texture, true)
			storedClothing[slot] = nil
			TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
		elseif currentProp ~= -1 then
			-- Store current prop and remove it
			storedClothing[slot] = { drawable = currentProp, texture = currentTexture }
			ClearPedProp(ped, mapping.id)
			TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
		end
	elseif mapping.type == 'component' then
		-- Check current component
		local currentDrawable = GetPedDrawableVariation(ped, mapping.id)
		local currentTexture = GetPedTextureVariation(ped, mapping.id)
		
		if storedClothing[slot] then
			-- Restore the stored component
			SetPedComponentVariation(ped, mapping.id, storedClothing[slot].drawable, storedClothing[slot].texture, 0)
			storedClothing[slot] = nil
			TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
		elseif currentDrawable ~= 0 or currentTexture ~= 0 then
			-- Store current component and reset to default
			storedClothing[slot] = { drawable = currentDrawable, texture = currentTexture }
			SetPedComponentVariation(ped, mapping.id, 0, 0, 0)
			TriggerEvent('ks-addons:pedpreview:refreshFrontendPed')
		end
	end
end)