
local function started(res)
    local s = GetResourceState(res)
    return s == 'started' or s == 'starting'
end

local function detect(list)
    for _, entry in ipairs(list) do
        if started(entry[1]) then return entry[2] end
    end
end

if not Config.Framework or Config.Framework == 'auto' then
    Config.Framework = detect({
        { 'qbx_core',    'qbx' },
        { 'qb-core',     'qb'  },
        { 'es_extended', 'esx' },
    }) or 'qb'
end

if not Config.Inventory or Config.Inventory == 'auto' then
    Config.Inventory = detect({
        { 'ox_inventory',    'ox_inventory'    },
        { 'qs-inventory',    'qs-inventory'    },
        { 'codem-inventory', 'codem-inventory' },
        { 'ps-inventory',    'ps-inventory'    },
        { 'lj-inventory',    'lj-inventory'    },
        { 'qb-inventory',    'qb-inventory'    },
    }) or 'default'
end

if not Config.Target or Config.Target == 'auto' then
    Config.Target = detect({
        { 'ox_target', 'ox_target' },
        { 'qb-target', 'qb-target' },
        { 'interact',  'interact'  },
    }) or 'none'
end

local imagePaths = {
    ['ox_inventory']    = 'nui://ox_inventory/web/images/%s.png',
    ['qs-inventory']    = 'nui://qs-inventory/html/images/%s.png',
    ['codem-inventory'] = 'nui://codem-inventory/html/itemimages/%s.png',
    ['ps-inventory']    = 'nui://ps-inventory/html/images/%s.png',
    ['lj-inventory']    = 'nui://lj-inventory/html/images/%s.png',
    ['qb-inventory']    = 'nui://qb-inventory/html/images/%s.png',
}
if not Config.ImagePath or Config.ImagePath == 'auto' then
    Config.ImagePath = imagePaths[Config.Inventory] or 'nui://qb-inventory/html/images/%s.png'
end

if IsDuplicityVersion() and Config.Debug then
    print(('^2[codera_shops]^7 framework=%s inventory=%s target=%s'):format(
        Config.Framework, Config.Inventory, Config.Target))
end
