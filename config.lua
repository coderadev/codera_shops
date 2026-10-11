Config = {}

-- Framework: 'auto' (detect) | 'qbx' | 'qb' | 'esx'
Config.Framework = 'auto'
-- Inventory: 'auto' | 'ox_inventory' | 'qs-inventory' | 'codem-inventory' | 'ps-inventory'
--            | 'lj-inventory' | 'qb-inventory' | 'default' (built-in qb/esx inventory)
Config.Inventory = 'auto'
-- Target: 'auto' | 'ox_target' | 'qb-target' | 'none' (none = press E near the NPC)
Config.Target = 'auto'

-- Print detection info and purchase errors to the server console (set to false in production)
Config.Debug = true

Config.Tax = 0.10            -- 10% tax
Config.MaxPerItem = 99       -- Max quantity of a single item per purchase
Config.Currency = '$'
Config.InteractDistance = 2.5

-- Item image path (%s = item name) | 'auto' = based on the detected inventory
Config.ImagePath = 'auto'

Config.Shops = {
    davis_mega_mall = {
        label = 'Davis Mega Mall',
        targetLabel = 'Open Store',
        targetIcon = 'fa-solid fa-shop',
        ped = { model = 's_m_y_shop_mask', coords = vec4(24.47, -1346.62, 29.5, 271.0), scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
        blip = { sprite = 52, color = 2, scale = 0.7, label = 'Davis Mega Mall' },
        categories = {
            {
                id = 'tools', label = 'Tools', icon = 'fa-solid fa-wrench',
                items = {
                    { name = 'lockpick', label = 'Lockpick', price = 200 },
                    { name = 'wrench',   label = 'Wrench',   price = 250 },
                }
            },
            {
                id = 'electronics', label = 'Electronics', icon = 'fa-solid fa-mobile-screen',
                items = {
                    { name = 'phone', label = 'Phone', price = 850 },
                    { name = 'radio', label = 'Radio', price = 250 },
                }
            },
        }
    },

    police_armory = {
        label = 'Police Armory',
        targetLabel = 'Open Armory',
        targetIcon = 'fa-solid fa-shield-halved',
        ped = { model = 's_m_y_cop_01', coords = vec4(452.6, -980.0, 30.69, 180.0), scenario = 'WORLD_HUMAN_COP_IDLES' },
        blip = nil,
        -- job = { police = 0 },  -- (optional) job restriction: job name = minimum grade
        categories = {
            {
                id = 'weapons', label = 'Weapons', icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_pistol',        label = 'Pistol',        price = 1400 },
                    { name = 'weapon_flashlight',    label = 'Flashlight',    price = 500 },
                    { name = 'weapon_stungun',       label = 'Stun Gun',      price = 1500 },
                    { name = 'weapon_nightstick',    label = 'Nightstick',    price = 1500 },
                }
            },
            {
                id = 'medical', label = 'Medical', icon = 'fa-solid fa-syringe',
                items = {
                    { name = 'bandage', label = 'Bandage', price = 50 },
                }
            },
        }
    },
}
