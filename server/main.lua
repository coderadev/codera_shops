local QBCore, ESX
local isQB = Config.Framework == 'qb' or Config.Framework == 'qbx'

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local function getPlayer(src)
    if Config.Framework == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    end
    return ESX.GetPlayerFromId(src)
end

local function getMoney(player, account)
    if isQB then
        return player.Functions.GetMoney(account)
    end
    local acc = account == 'bank' and 'bank' or 'money'
    local a = player.getAccount(acc)
    return a and a.money or 0
end

local function removeMoney(player, account, amount, reason)
    if isQB then
        return player.Functions.RemoveMoney(account, amount, reason)
    end
    local acc = account == 'bank' and 'bank' or 'money'
    player.removeAccountMoney(acc, amount, reason)
    return true
end

local function addMoney(player, account, amount, reason)
    if isQB then
        return player.Functions.AddMoney(account, amount, reason)
    end
    local acc = account == 'bank' and 'bank' or 'money'
    player.addAccountMoney(acc, amount, reason)
    return true
end

local function getJob(player)
    if isQB then
        local j = player.PlayerData.job
        return j.name, j.grade and j.grade.level or 0
    end
    local j = player.getJob()
    return j.name, j.grade
end

local function call(res, fn, ...)
    local args = { ... }
    local ok, r = pcall(function()
        return exports[res][fn](exports[res], table.unpack(args))
    end)
    return ok, r
end

local adapters = {
    ['ox_inventory'] = {
        canCarry = function(src, item, n) return call('ox_inventory', 'CanCarryItem', src, item, n) end,
        add      = function(src, item, n) return call('ox_inventory', 'AddItem', src, item, n) end,
        remove   = function(src, item, n) return call('ox_inventory', 'RemoveItem', src, item, n) end,
    },
    ['qs-inventory'] = {
        canCarry = function(src, item, n) return call('qs-inventory', 'CanCarryItem', src, item, n) end,
        add      = function(src, item, n) return call('qs-inventory', 'AddItem', src, item, n) end,
        remove   = function(src, item, n) return call('qs-inventory', 'RemoveItem', src, item, n) end,
    },
    ['codem-inventory'] = {
        add    = function(src, item, n) return call('codem-inventory', 'AddItem', src, item, n) end,
        remove = function(src, item, n) return call('codem-inventory', 'RemoveItem', src, item, n) end,
    },
}
for _, res in ipairs({ 'qb-inventory', 'ps-inventory', 'lj-inventory' }) do
    adapters[res] = {
        canCarry = function(src, item, n) return call(res, 'CanAddItem', src, item, n) end,
        add      = function(src, item, n) return call(res, 'AddItem', src, item, n, false, false, 'codera_shops') end,
        remove   = function(src, item, n) return call(res, 'RemoveItem', src, item, n, false, 'codera_shops:rollback') end,
    }
end

local function canCarry(src, player, item, count)
    local a = adapters[Config.Inventory]
    if a then
        if not a.canCarry then return true end
        local called, ok = a.canCarry(src, item, count)
        if not called then return true end
        return ok and true or false
    end
    if isQB then return true end
    return player.canCarryItem(item, count)
end

local function giveItem(src, player, item, count)
    local a = adapters[Config.Inventory]
    if a then
        local called, ok = a.add(src, item, count)
        return called and ok and true or false
    end
    if isQB then
        return player.Functions.AddItem(item, count) and true or false
    end
    player.addInventoryItem(item, count)
    return true
end

local function removeItem(src, player, item, count)
    local a = adapters[Config.Inventory]
    if a then
        return a.remove(src, item, count)
    end
    if isQB then
        return player.Functions.RemoveItem(item, count)
    end
    player.removeInventoryItem(item, count)
end

local priceIndex = {}
for shopId, shop in pairs(Config.Shops) do
    priceIndex[shopId] = {}
    for _, cat in ipairs(shop.categories) do
        for _, it in ipairs(cat.items) do
            priceIndex[shopId][it.name] = it
        end
    end
end

local function notify(src, success, msg)
    TriggerClientEvent('codera_shops:result', src, success, msg)
end

local busy = {}

RegisterNetEvent('codera_shops:checkout', function(shopId, cart, method)
    local src = source
    if busy[src] then return end
    busy[src] = true

    local function done(success, msg)
        busy[src] = nil
        if Config.Debug and not success then
            print(('^1[codera_shops]^7 purchase failed for %s: %s'):format(src, msg))
        end
        notify(src, success, msg)
    end

    local shop = Config.Shops[shopId]
    if not shop then return done(false, 'Invalid store.') end
    if type(cart) ~= 'table' or #cart == 0 then return done(false, 'Your cart is empty.') end
    if method ~= 'bank' and method ~= 'cash' then return done(false, 'Invalid payment method.') end

    local player = getPlayer(src)
    if not player then return done(false, 'Player not found.') end

    local ped = GetPlayerPed(src)
    local pc = GetEntityCoords(ped)
    local sc = (shop.ped and shop.ped.coords) or shop.coords
    if #(pc - vec3(sc.x, sc.y, sc.z)) > (Config.InteractDistance + 8.0) then
        return done(false, 'You are too far from the store.')
    end

    if shop.job then
        local jobName, grade = getJob(player)
        local min = jobName and shop.job[jobName]
        if min == nil or (grade or 0) < min then
            return done(false, "You don't have access to this store.")
        end
    end

    local subtotal, lines = 0, {}
    local merged = {}
    for _, line in ipairs(cart) do
        local name = type(line) == 'table' and line.name
        local count = type(line) == 'table' and math.floor(tonumber(line.count) or 0)
        local def = name and priceIndex[shopId][name]
        if not def or count < 1 or count > Config.MaxPerItem then
            return done(false, 'Invalid cart.')
        end
        merged[name] = (merged[name] or 0) + count
    end

    for name, count in pairs(merged) do
        if count > Config.MaxPerItem then return done(false, 'Invalid cart.') end
        local def = priceIndex[shopId][name]
        subtotal = subtotal + def.price * count
        lines[#lines + 1] = { name = name, count = count }
    end

    local tax = math.floor(subtotal * Config.Tax + 0.5)
    local total = subtotal + tax

    for _, l in ipairs(lines) do
        if not canCarry(src, player, l.name, l.count) then
            if Config.Debug then print(('^1[codera_shops]^7 canCarry=false item=%s count=%d (item missing in shared items or inventory full)'):format(l.name, l.count)) end
            return done(false, "You can't carry that much.")
        end
    end

    local account = method == 'bank' and 'bank' or 'cash'
    if getMoney(player, account) < total then
        return done(false, 'Not enough money.')
    end

    if not removeMoney(player, account, total, 'codera_shops:' .. shopId) then
        return done(false, 'Payment failed.')
    end

    local given = {}
    for _, l in ipairs(lines) do
        if giveItem(src, player, l.name, l.count) then
            given[#given + 1] = l
        else
            if Config.Debug then print(('^1[codera_shops]^7 AddItem failed item=%s count=%d'):format(l.name, l.count)) end
            for _, g in ipairs(given) do removeItem(src, player, g.name, g.count) end
            addMoney(player, account, total, 'codera_shops:refund')
            return done(false, 'Could not add items to your inventory.')
        end
    end

    done(true, ('Purchase complete: %s%d'):format(Config.Currency, total))
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)
