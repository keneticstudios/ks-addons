# ks-addons Clothing System - Installation Guide

## 1. Database Setup

Run the SQL file to create the required tables:
This creates the `ks_outfits` table for storing saved outfits.

---

## 2. ox_inventory Items

Add the items from `INSTALL/ox_inventory_items.lua` to your `ox_inventory/data/items.lua` file.

### Core Items (Required)
| Item | Description |
|------|-------------|
| `clothing_bag` | Used to save current outfit |
| `clothes` | Contains a saved outfit (created when using clothing_bag) |

### Wearable Items
| Item | Description |
|------|-------------|
| `mask` | Face mask |
| `hat` | Hat/headwear |
| `earrings` | Earrings |
| `glasses` | Glasses/eyewear |
| `chain` | Necklace/chain |
| `undershirt` | Undershirt/t-shirt |
| `jacket` | Jacket/top |
| `bodyarmor` | Body armor (clothing) |
| `bracelet` | Bracelet |
| `watch` | Watch |
| `bag` | Bag/backpack |
| `pants` | Pants/legwear |
| `shoes` | Shoes/footwear |
| `gloves` | Gloves |

---

## 3. Appearance Script Integration

Copy the files from the appropriate folder in `INSTALL/clothing/`:

- **bl_appearance**: Copy files from `INSTALL/clothing/bl_appearance/`
- **illenium_appearance**: Copy files from `INSTALL/clothing/illenium_appearance/`
- **qb-clothing**: Copy files from `INSTALL/clothing/qb-clothing/`

---

## 4. Commands

After installation, players can use these commands:

| Command | Action |
|---------|--------|
| `/hat` | Toggle hat |
| `/mask` | Toggle mask |
| `/glasses` | Toggle glasses |
| `/earrings` | Toggle earrings |
| `/chain` | Toggle chain |
| `/jacket` | Toggle jacket |
| `/undershirt` | Toggle undershirt |
| `/bodyarmor` | Toggle body armor |
| `/pants` | Toggle pants |
| `/shoes` | Toggle shoes |
| `/gloves` | Toggle gloves |
| `/bag` | Toggle bag |
| `/watch` | Toggle watch |
| `/bracelet` | Toggle bracelet |
| `/accessories` | Toggle all accessories |

---

## 5. Exports

```lua
-- Toggle clothing item on/off
exports['ks-addons']:ToggleClothing('hat')

-- Enable/disable service mode (visual changes only) -- When job scripts change player clothing - Doesn't save the player clothes but only changes them visualy, Usually these exports are integrated into the apperance files but might require adding these exports to the job scripts!
exports['ks-addons']:ToggleServiceMode(true) -- Turn on the service mode
exports['ks-addons']:ToggleServiceMode(false) / exports['ks-addons']:RestoreClothes() -- Turn off the service mode and restores clothes
```
