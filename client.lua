local zones, targetIds, lastCreate = {}, {}, 0

local function Notify(msg, type)
    if Config.NotifyMethod == 'ox_lib' then
        lib.notify({ title = 'Parkir', description = msg, type = type or 'inform' })
    elseif Config.Framework == 'qb' then
        TriggerEvent('QBCore:Notify', msg)
    elseif Config.Framework == 'esx' then
        TriggerEvent('esx:showNotification', msg)
    end
end

local function AddZoneTarget(zone)
    if not zone or not zone.id then return end
    local id = zone.id
    zones[id] = zone
    if Config.Target == 'ox' and exports.ox_target then
        local opts = {
            {
                name = 'park_store_'..id,
                label = '🚗 Parkir ($'..zone.price..')',
                icon = 'fa-solid fa-square-parking',
                onSelect = function()
                    lib.progressBar({duration=Config.ProgressDuration,label='Menyimpan...'})
                    TriggerServerEvent('parking:serverStoreVehicle', id)
                end
            },
            {
                name = 'park_retrieve_'..id,
                label = '🚘 Ambil Kendaraan',
                icon = 'fa-solid fa-car',
                onSelect = function()
                    lib.registerContext({
                        id = 'retrieve_'..id,
                        title = 'Ambil Kendaraan',
                        options = {
                            { title = 'Bayar $'..zone.price, event = 'parking:clientChoosePay', args = { id = id } },
                            { title = 'Kabur Tanpa Bayar', event = 'parking:clientChooseEscape', args = { id = id } }
                        }
                    })
                    lib.showContext('retrieve_'..id)
                end
            },
            {
                name = 'park_remove_'..id,
                label = '❌ Hapus Lahan',
                icon = 'fa-solid fa-trash',
                onSelect = function() TriggerServerEvent('parking:serverDeleteZone', id) end
            }
        }
        exports.ox_target:addSphereZone({
            coords = vector3(zone.coords.x, zone.coords.y, zone.coords.z),
            radius = Config.ZoneRadius,
            options = opts
        })
        targetIds[id] = true
    elseif exports['qb-target'] then
        local options = {
            { type="client", event="parking:clientOpenRetrieveMenu", label="Ambil Kendaraan", zoneId=id },
            { type="server", event="parking:serverStoreVehicle", label="Parkir Kendaraan ($"..zone.price..")", zoneId=id },
            { type="client", event="parking:clientRequestDelete", label="Hapus Lahan", zoneId=id }
        }
        exports['qb-target']:AddCircleZone('park_zone_'..id, vector3(zone.coords.x, zone.coords.y, zone.coords.z), Config.ZoneRadius, { name='park_zone_'..id }, { options=options, distance=2.5 })
        targetIds[id] = true
    end
end

local function RemoveZoneTarget(id)
    if Config.Target == 'ox' then
        exports.ox_target:removeZone('park_zone_'..id)
    elseif exports['qb-target'] then
        exports['qb-target']:RemoveZone('park_zone_'..id)
    end
    zones[id] = nil
    targetIds[id] = nil
end

RegisterNetEvent('parking:clientRegisterZone', function(zone) AddZoneTarget(zone) end)
RegisterNetEvent('parking:bulkRegisterZones', function(all) for k,_ in pairs(zones) do RemoveZoneTarget(k) end for _,z in pairs(all) do AddZoneTarget(z) end end)
RegisterNetEvent('parking:clientRemoveZone', function(id) RemoveZoneTarget(id) end)
RegisterNetEvent('parking:clientFullSync', function(all) for k,_ in pairs(zones) do RemoveZoneTarget(k) end for _,z in pairs(all) do AddZoneTarget(z) end end)

AddEventHandler('playerSpawned', function() TriggerServerEvent('parking:requestZoneSync') end)

RegisterNetEvent('parking:clientOpenRetrieveMenu', function(data)
    local id = data.zoneId
    lib.registerContext({
        id = 'retrieve_menu_'..id,
        title = 'Ambil Kendaraan',
        options = {
            { title = 'Bayar $'..(zones[id] and zones[id].price or Config.DefaultPrice), event = 'parking:clientChoosePay', args = { id = id } },
            { title = 'Kabur Tanpa Bayar', event = 'parking:clientChooseEscape', args = { id = id } }
        }
    })
    lib.showContext('retrieve_menu_'..id)
end)

RegisterNetEvent('parking:clientRequestDelete', function(data) TriggerServerEvent('parking:serverDeleteZone', data.zoneId) end)

RegisterNetEvent('parking:clientChoosePay', function(data)
    lib.progressBar({duration=Config.ProgressDuration,label='Membayar...'})
    TriggerServerEvent('parking:serverPayAndTake', data.id)
end)

RegisterNetEvent('parking:clientChooseEscape', function(data)
    lib.progressBar({duration=Config.ProgressDuration,label='Mengambil...'})
    TriggerServerEvent('parking:serverTakeWithoutPay', data.id)
end)

RegisterNetEvent('parking:clientUseWhistle', function(price)
    local now = GetGameTimer()
    if (now - lastCreate) < Config.CreateCooldown then return Notify('Tunggu sebelum membuat lagi.','error') end
    lastCreate = now
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local zoneId = tostring(math.random(100000,999999))
    TriggerServerEvent('parking:serverCreateZone', zoneId, {x=coords.x,y=coords.y,z=coords.z}, price or Config.DefaultPrice)
end)

RegisterNetEvent('parking:clientNotify', function(msg, type) Notify(msg, type) end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if exports['qb-target'] then for id,_ in pairs(targetIds) do exports['qb-target']:RemoveZone('park_zone_'..id) end end
end)
