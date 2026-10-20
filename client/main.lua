local peds, blips, zones = {}, {}, {}
local isOpen, currentShop = false, nil

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() - t > 5000 then return nil end
    end
    return hash
end

local function getJobData()
    if Config.Framework == 'esx' then
        local d = exports['es_extended']:getSharedObject().GetPlayerData()
        return d.job and d.job.name, d.job and d.job.grade
    end
    local PD
    if Config.Framework == 'qbx' then
        local ok, r = pcall(function() return exports.qbx_core:GetPlayerData() end)
        PD = ok and r or nil
    end
    if not PD then
        PD = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
    end
    return PD and PD.job and PD.job.name, PD and PD.job and PD.job.grade and PD.job.grade.level
end

local function hasJobAccess(shop)
    if not shop.job then return true end
    local name, grade = getJobData()
    local min = name and shop.job[name]
    return min ~= nil and (grade or 0) >= min
end

local function openShop(shopId)
    local shop = Config.Shops[shopId]
    if not shop or isOpen then return end
    if not hasJobAccess(shop) then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName("You don't have access to this store.")
        EndTextCommandThefeedPostTicker(false, true)
        return
    end
    isOpen, currentShop = true, shopId
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        shop = { id = shopId, label = shop.label, categories = shop.categories },
        tax = Config.Tax,
        currency = Config.Currency,
        imagePath = Config.ImagePath,
        maxPerItem = Config.MaxPerItem,
    })
end

local function closeShop()
    if not isOpen then return end
    isOpen, currentShop = false, nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function shopHasNPC(shop)
    if shop.npc ~= nil then return shop.npc end
    return Config.UseNPC ~= false
end

local function shopCoords(shop)
    return shop.ped and shop.ped.coords or shop.coords
end

-- ped: entity handle when the shop has an NPC, nil otherwise (then a coords point is used)
local function addTarget(ped, id, shop)
    local label = shop.targetLabel or 'Open Store'
    local icon = shop.targetIcon or 'fa-solid fa-shop'
    local c = shopCoords(shop)
    local point = vec3(c.x, c.y, c.z)
    local canUse = function() return hasJobAccess(shop) end
    local name = 'codera_shop_' .. id

    if Config.Target == 'ox_target' then
        local opt = {
            name = name, icon = icon, label = label,
            distance = Config.InteractDistance,
            canInteract = canUse,
            onSelect = function() openShop(id) end,
        }
        if ped then
            exports.ox_target:addLocalEntity(ped, { opt })
        else
            zones[id] = exports.ox_target:addSphereZone({
                coords = point, radius = Config.InteractDistance,
                debug = false, options = { opt },
            })
        end

    elseif Config.Target == 'qb-target' then
        local opts = {
            options = {{
                icon = icon, label = label,
                canInteract = canUse,
                action = function() openShop(id) end,
            }},
            distance = Config.InteractDistance,
        }
        if ped then
            exports['qb-target']:AddTargetEntity(ped, opts)
        else
            exports['qb-target']:AddCircleZone(name, point, Config.InteractDistance,
                { name = name, debugPoly = false, useZ = true }, opts)
            zones[id] = name
        end

    elseif Config.Target == 'interact' then
        local data = {
            distance = Config.InteractDotDistance or 6.0,
            interactDst = Config.InteractDistance,
            options = {{
                name = name,
                label = label,
                canInteract = canUse,
                action = function() openShop(id) end,
            }},
        }
        if ped then
            data.entity = ped
            data.offset = vec3(0.0, 0.0, 0.3)
            zones[id] = exports.interact:AddLocalEntityInteraction(data)
        else
            data.coords = point + vec3(0.0, 0.0, 0.3)
            data.name = name
            zones[id] = exports.interact:AddInteraction(data)
        end
    end
end

local function spawnShops()
    for id, shop in pairs(Config.Shops) do
        local p = shop.ped or {}
        local c = shopCoords(shop)

        if shopHasNPC(shop) and shop.ped then
            local hash = loadModel(p.model)
            if hash then
                local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false)
                SetEntityAsMissionEntity(ped, true, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedCanRagdoll(ped, false)
                if p.scenario then TaskStartScenarioInPlace(ped, p.scenario, 0, true) end
                SetModelAsNoLongerNeeded(hash)
                peds[id] = ped
                addTarget(ped, id, shop)
            end
        else
            -- no NPC: interaction point at the shop coords
            addTarget(nil, id, shop)
        end

        if shop.blip then
            local b = AddBlipForCoord(c.x, c.y, c.z)
            SetBlipSprite(b, shop.blip.sprite)
            SetBlipColour(b, shop.blip.color)
            SetBlipScale(b, shop.blip.scale)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.blip.label or shop.label)
            EndTextCommandSetBlipName(b)
            blips[#blips + 1] = b
        end
    end
end

CreateThread(spawnShops)

if Config.Target == 'none' then
    CreateThread(function()
        while true do
            local wait = 500
            if not isOpen then
                local pc = GetEntityCoords(PlayerPedId())
                for id, shop in pairs(Config.Shops) do
                    local c = shopCoords(shop)
                    if #(pc - vec3(c.x, c.y, c.z)) <= Config.InteractDistance and hasJobAccess(shop) then
                        wait = 0
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to ' .. (shop.targetLabel or 'Open Store'))
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) then openShop(id) end
                    end
                end
            end
            Wait(wait)
        end
    end)
end

RegisterNUICallback('close', function(_, cb)
    closeShop()
    cb('ok')
end)

RegisterNUICallback('checkout', function(data, cb)
    if currentShop then
        TriggerServerEvent('codera_shops:checkout', currentShop, data.cart, data.method)
    end
    cb('ok')
end)

RegisterNetEvent('codera_shops:result', function(success, message)
    SendNUIMessage({ action = 'result', success = success, message = message })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)

    for id, ped in pairs(peds) do
        if DoesEntityExist(ped) then
            if Config.Target == 'ox_target' then exports.ox_target:removeLocalEntity(ped)
            elseif Config.Target == 'qb-target' then exports['qb-target']:RemoveTargetEntity(ped) end
            DeleteEntity(ped)
        end
    end

    for id, z in pairs(zones) do
        if Config.Target == 'ox_target' then exports.ox_target:removeZone(z)
        elseif Config.Target == 'qb-target' then exports['qb-target']:RemoveZone(z)
        elseif Config.Target == 'interact' then pcall(function() exports.interact:RemoveInteraction(z) end) end
    end

    for _, b in ipairs(blips) do RemoveBlip(b) end
end)
