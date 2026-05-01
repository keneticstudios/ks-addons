Config = {}

-- Preview ped animation in inventory UI
Config.Animation = {
    dict = "mini@triathlon",
    anim = "idle_e"
}

-- Dropped item visuals
-- DropProps: true/false
-- DropMarker: true/false
-- DefaultProp: array of model hashes/names (first entry is fallback)
Config.DropProps = true
Config.DropMarker = true
Config.DefaultProp = { `prop_paper_bag_01` }
Config.GlowEnabled = false
Config.GlowColor = { r = 255, g = 0, b = 0, a = 255 }

-- Appearance integration options used in code: "bl", "illenium", "qb"
-- Any other value falls back to native SetPed* functions
Config.Appearance = "bl"

-- Folder / resource name of qb-clothing (must match GetResourceState / exports key)
Config.QbClothingResource = "qb-clothing"

-- Main clothing logic mode
-- true  = advanced metadata clothing system
-- false = simple clothing behavior
Config.UseAdvanced = true

-- Advanced mode restrictions (all boolean except timeout/slots)
Config.RequireClothingShopInAdvanced = false
Config.ShopSessionTimeout = 120000 -- milliseconds
Config.WorkModeLockSpecialSlots = true
Config.PlayerInventorySlots = 50

-- Notification provider options used in code: "ox", "esx", "qb", "qbox"
-- Any other value uses GTA notification fallback
Config.Notify = "ox"

-- Extra logs in console
Config.Debug = false

-- Optional custom server event for appearance save forwarding
-- Example: 'my_resource:saveAppearance'
Config.CustomSaveEvent = nil

-- Outfit database schema
-- OutfitColumns defaults expected by install SQL:
-- identifier="citizenid", name="name", data="items"
Config.OutfitTable = 'ks_outfits'
Config.OutfitColumns = {
    identifier = 'citizenid',
    name = 'name',
    data = 'items'
}

-- Clothing item slot map
-- type options used in code: "component" or "prop"
-- id is ped component/prop index, slot is ox inventory slot
Config.ClothingItems = {
    ['hat'] = { type = 'prop', id = 0, slot = 31 },
    ['undershirt'] = { type = 'component', id = 8, slot = 32 },
    ['jacket'] = { type = 'component', id = 11, slot = 33 },
    ['bodyarmor'] = { type = 'component', id = 9, slot = 34 },
    ['gloves'] = { type = 'component', id = 3, slot = 35 },
    ['pants'] = { type = 'component', id = 4, slot = 36 },
    ['shoes'] = { type = 'component', id = 6, slot = 37 },
    ['mask'] = { type = 'component', id = 1, slot = 38 },
    ['glasses'] = { type = 'prop', id = 1, slot = 39 },
    ['earrings'] = { type = 'prop', id = 2, slot = 40 },
    ['chain'] = { type = 'component', id = 7, slot = 41 },
    ['bracelet'] = { type = 'prop', id = 7, slot = 42 },
    ['watch'] = { type = 'prop', id = 6, slot = 43 },
    ['bag'] = { type = 'component', id = 5, slot = 44 }
}

-- Default "unequipped" look
-- component keys: numbers (1,3,4,5,6,7,8,9,11)
-- prop keys: "p0", "p1", "p2", "p6", "p7"
Config.Naked = {
    male = {
        [1] = { drawable = 0, texture = 0 },   [3] = { drawable = 15, texture = 0 },
        [4] = { drawable = 21, texture = 0 },  [5] = { drawable = 0, texture = 0 },
        [6] = { drawable = 34, texture = 0 },  [7] = { drawable = 0, texture = 0 },
        [8] = { drawable = 15, texture = 0 },  [9] = { drawable = 0, texture = 0 },
        [11] = { drawable = 15, texture = 0 }, ['p0'] = { drawable = -1, texture = 0 },
        ['p1'] = { drawable = -1, texture = 0 }, ['p2'] = { drawable = -1, texture = 0 },
        ['p6'] = { drawable = -1, texture = 0 }, ['p7'] = { drawable = -1, texture = 0 },
    },
    female = {
        [1] = { drawable = 0, texture = 0 },   [3] = { drawable = 15, texture = 0 },
        [4] = { drawable = 15, texture = 0 },  [5] = { drawable = 0, texture = 0 },
        [6] = { drawable = 35, texture = 0 },  [7] = { drawable = 0, texture = 0 },
        [8] = { drawable = 14, texture = 0 },  [9] = { drawable = 0, texture = 0 },
        [11] = { drawable = 15, texture = 0 }, ['p0'] = { drawable = -1, texture = 0 },
        ['p1'] = { drawable = -1, texture = 0 }, ['p2'] = { drawable = -1, texture = 0 },
        ['p6'] = { drawable = -1, texture = 0 }, ['p7'] = { drawable = -1, texture = 0 },
    }
}

-- User-facing texts
Config.Locales = {
    no_clothes_slots = 'No clothes in the slots!',
    broken_outfit = 'Broken outfit!',
    no_space = 'You don’t have enough space!',
    db_missing = 'Missing data in the database!',
    outfit_unpacked = 'Outfit unpacked!',
    outfit_created = 'Outfit created!',
    save_outfit_title = 'Save Outfit',
    outfit_name_label = 'Outfit name',
    item_desc = 'Model: %d | Texture: %d',
    outfit_desc = 'Outfit ID: %s',
    clothing_shop_only = 'Go to a clothing shop to change equipped advanced clothes.',
    service_mode_locked = 'You cannot move clothing items while in work mode.'
}

-- Optional prop model overrides by item name
-- Used as fallback by ks drop renderer and patched ox drop resolver
-- Value can be model hash (`hash`) or model name ("prop_name")
Config.ItemModels = {
    ['water'] = `prop_ld_can_01`,
    ['bread'] = `prop_sandwich_01`,
    ['phone'] = `p_amb_phone_01`,
    ['bandage'] = `prop_paper_bag_01`,
    ['pistol'] = `w_pi_pistol`,
}