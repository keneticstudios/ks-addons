# KS Addons

Client and server extensions for **ox_inventory** on FiveM: clothing tied to dedicated inventory slots, outfit storage, world drop visuals, and an in-menu character preview.

## What it provides

- **Clothing system** — Maps clothing items to fixed **ox_inventory** slots; equipping updates the ped and (depending on mode) persists through your appearance resource. Supports **advanced** mode (metadata drawables/textures, shop sessions, slot validation) and **simple** mode.
- **Outfits** — Saves equipped slot items to MySQL (`ks_outfits` by default) and unpacks them back into slots.
- **Drop visuals** — Optional **world props** and/or **markers** for dropped items, with per-item model overrides (`Config.ItemModels`) and a default fallback prop.
- **Inventory preview** — Pause-menu style **cloned ped** preview while browsing inventory (animation configurable).

## Dependencies

| Resource | Role |
|----------|------|
| [ox_inventory](https://github.com/overextended/ox_inventory) | Slots, items, hooks |
| [ox_lib](https://github.com/overextended/ox_lib) | Callbacks, optional input/notifications |
| [oxmysql](https://github.com/overextended/oxmysql) | Outfits + QB skin persistence |

**Framework:** Identifier resolution uses **QBCore** (`qb-core`) or **ESX** (`es_extended`) for citizenid/identifier where needed.

## Supported appearance systems

Set **`Config.Appearance`** in `config.lua`:

| Value | Integration |
|-------|-------------|
| **`"bl"`** | **bl_appearance** — save/load via bl events and exports (see `INSTALL/clothing/bl_appearance`). |
| **`"illenium"`** | [illenium-appearance](https://github.com/iLLeniumStudios/illenium-appearance) — server callback + `setPlayerAppearance`; saves via illenium events. |
| **`"qb"`** | **qb-clothing** — uses `getSkinData` / `syncClothingMapFromPed` / `reloadSkin` (see `INSTALL` patches). Skin rows are written to **`playerskins`** via **`ks-addons:clothes:server:saveQbSkin`** (same table as stock qb-clothing). |
| *anything else* | Native `SetPedComponentVariation` / props only (no third-party skin save). |

For QB, set **`Config.QbClothingResource`** to your resource folder name if it is not `qb-clothing`.

## Configuration (overview)

- **`Config.UseAdvanced`** — Advanced vs simple clothing behavior.
- **`Config.ClothingItems`** — Item names, component/prop IDs, and ox **slot** indices (must match your items + inventory layout).
- **`Config.Naked`** — Default drawables when “unequipping” to underwear/base for male/female freemode.
- **`Config.Notify`** — `ox` | `esx` | `qb` | `qbox` | fallback.
- **`Config.CustomSaveEvent`** — Optional extra server event when appearance is saved from ks-addons.

Full options are documented inline in **`config.lua`**.

## `INSTALL/` folder

Reference copies and integration notes for **bl_appearance**, **illenium-appearance**, **qb-clothing**, and related assets. Merge the relevant changes into your live resources (especially qb-clothing exports used by ks-addons).

## Resource order

Start after **`ox_lib`**, **`ox_inventory`**, **`oxmysql`**, your **framework**, and your **appearance/clothing** resource. Example:

```cfg
ensure ox_lib
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure qb-clothing
ensure ks-addons
```

## Exports (clothing)

- `exports['ks-addons']:ToggleServiceMode(state)`
- `exports['ks-addons']:BeginShopSession(shopType?)` / `EndShopSession()`
- `exports['ks-addons']:RestoreClothes()`
- `exports['ks-addons']:IsAdvancedMode()` / `IsServiceMode()`

Event: **`ks-addons:client:RestoreClothes`** — refresh appearance + inventory clothing sync (e.g. after script restart).

---

**Author:** KS Development · **Description:** KS OX Inventory Addons
