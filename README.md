# codera_shops
<img width="1919" height="1079" alt="Screenshot 2026-10-11 171525" src="https://github.com/user-attachments/assets/fc8bd49c-5a1a-4141-85f4-e11556280282" />


## Features

- Ped-based stores with blips and optional job restrictions
- NUI store with categories, cart, quantity controls and tax
- Pay with bank or cash
- Server-side validation: prices, distance, job and quantities are never trusted from the client
- Automatic refund and item rollback if adding items fails
- Auto-detection of framework, inventory, target and item image path

## Supported

| Type | Options |
| --- | --- |
| Framework | `qbx_core`, `qb-core`, `es_extended` |
| Inventory | `ox_inventory`, `qs-inventory`, `codem-inventory`, `ps-inventory`, `lj-inventory`, `qb-inventory`, built-in qb/esx inventory |
| Target | `ox_target`, `qb-target`, `interact` (NoPixel-style [E] prompt), or none (press **E** near the shop) |

## Installation

1. Drop the `codera_shops` folder into your `resources` directory.
2. Add this to your `server.cfg`, after your framework, inventory and target resources:

   ```
   ensure codera_shops
   ```

3. Make sure every item you sell exists in your framework or inventory item list.
4. Edit `config.lua` to your liking and restart the resource.

## Configuration

Everything lives in `config.lua`.

```lua
Config.Framework = 'auto'   -- 'auto' | 'qbx' | 'qb' | 'esx'
Config.Inventory = 'auto'   -- 'auto' | 'ox_inventory' | 'qs-inventory' | 'codem-inventory'
                            --        | 'ps-inventory' | 'lj-inventory' | 'qb-inventory' | 'default'
Config.Target    = 'auto'   -- 'auto' | 'ox_target' | 'qb-target' | 'interact' | 'none'
Config.UseNPC    = true     -- true = spawn a shop ped | false = no ped, interaction point at the shop coords

Config.Debug = true         -- print detection info and purchase errors to the server console
Config.Tax = 0.10           -- 10% tax
Config.MaxPerItem = 99      -- max quantity of a single item per purchase
Config.Currency = '$'
Config.InteractDistance = 2.5      -- range to use the target / [E] prompt
Config.InteractDotDistance = 6.0   -- 'interact' only: range at which the dot appears
Config.ImagePath = 'auto'   -- item image path, %s = item name
```

With `'auto'`, the script checks which resources are running and picks the right one. If the detection is wrong, set the value manually. With `Config.Debug = true`, the server console prints a line like:

```
[codera_shops] framework=qbx inventory=ox_inventory target=ox_target
```

Set `Config.Debug = false` once everything works.

### Adding a shop

```lua
Config.Shops = {
    my_shop = {
        label = 'My Shop',
        targetLabel = 'Open Store',
        targetIcon = 'fa-solid fa-shop',
        npc = true,             -- optional: overrides Config.UseNPC for this shop
        ped = { model = 's_m_y_shop_mask', coords = vec4(24.47, -1346.62, 29.5, 271.0), scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
        blip = { sprite = 52, color = 2, scale = 0.7, label = 'My Shop' },
        job = { police = 0 },   -- optional: job name = minimum grade
        categories = {
            {
                id = 'tools', label = 'Tools', icon = 'fa-solid fa-wrench',
                items = {
                    { name = 'lockpick', label = 'Lockpick', price = 200 },
                }
            },
        }
    },
}
```

| Field | Description |
| --- | --- |
| `ped` | Ped model, `vec4` coordinates and an optional scenario. With `npc = false` only the coordinates are used (as the interaction point) |
| `npc` | Optional. `true`/`false` overrides `Config.UseNPC` for this shop |
| `blip` | Map blip settings, or `nil` for no blip |
| `job` | Optional. Only the listed jobs at or above the given grade can use the shop |
| `categories[].icon` | Any Font Awesome 6 icon class |
| `items[].name` | Item name, must match your inventory item name exactly |

## How a purchase works

1. The client sends the shop id, cart and payment method to the server.
2. The server checks the shop, distance, job, item names and quantities, then recalculates the total from `config.lua` prices.
3. It checks that the player can carry the items and has enough money.
4. It removes the money and gives the items. If any item fails, the items already given are removed and the money is refunded.

## Troubleshooting

**"You can't carry that much."** The inventory is full, or the item does not exist in your item list. Enable `Config.Debug` to see which item failed.

**"Could not add items to your inventory."** The inventory refused the item, usually because the item name is missing from the shared items. The payment is refunded automatically.

**No export `CanAddItem`.** Fixed. Inventories without this export skip the pre-check, and the purchase is still validated when items are added.

**Item images are missing.** Set `Config.ImagePath` manually, for example `nui://ox_inventory/web/images/%s.png`.

**Wrong inventory or framework detected.** Set `Config.Framework`, `Config.Inventory` or `Config.Target` manually instead of `'auto'`.

