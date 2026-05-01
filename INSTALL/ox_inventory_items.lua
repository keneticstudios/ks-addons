--[[
    ks-addons Clothing System - ox_inventory Items
    
    Add these items to your ox_inventory/data/items.lua file.
    These items are required for the clothing system to function properly.
]]

-- Core outfit system items
['clothing_bag'] = { label = 'Clothing Bag', weight = 100, stack = false, close = true, description = 'Use to save your current outfit.', model = 'prop_cs_shopping_bag', client = { event = 'ks-addons:clothes:client:UseBag' } },
['clothes']        = { label = 'Outfit', weight = 2000, stack = false, close = true, description = 'Contains a saved outfit.', model = 'prop_cs_package_01', client = { event = 'ks-addons:clothes:client:UseOutfit' } },

-- Clothing items (wearables)
['mask']       = { label = 'Mask',       weight = 100, stack = false, model = 'p_d_scuba_mask_s' },
['hat']        = { label = 'Hat',        weight = 100, stack = false, model = 'prop_tourist_hat_01' },
['earrings']   = { label = 'Earrings',   weight = 100, stack = false, model = 'v_res_jewelbox' },
['glasses']    = { label = 'Glasses',    weight = 100, stack = false, model = 'prop_glasses_02' },
['chain']      = { label = 'Chain',      weight = 100, stack = false, model = 'p_cs_chain_s' },
['undershirt'] = { label = 'Undershirt', weight = 100, stack = false, model = 'prop_tshirt_01' },
['jacket']     = { label = 'Jacket',     weight = 100, stack = false, model = 'v_16_jacket' },
['bodyarmor']  = { label = 'Body Armor', weight = 100, stack = false, model = 'prop_bodyarmour_02' },
['bracelet']   = { label = 'Bracelet',   weight = 100, stack = false, model = 'p_cs_cuffs_02_s' },
['watch']      = { label = 'Watch',      weight = 100, stack = false, model = 'p_watch_01' },
['bag']        = { label = 'Bag',        weight = 100, stack = false, model = 'p_michael_backpack_s' },
['pants']      = { label = 'Pants',      weight = 100, stack = false, model = 'v_16_trousers' },
['shoes']      = { label = 'Shoes',      weight = 100, stack = false, model = 'v_16_shoes' },
['gloves']     = { label = 'Gloves',     weight = 100, stack = false, model = 'prop_safety_gloves' },