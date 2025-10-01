local savedZones = {}

local function GetIdentifierFromSource(src)
    if Config.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return nil end
        return player.PlayerData.citizenid, player
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return nil end
        return xPlayer.identifier, xPlayer
    else
        return tostring(src), nil
    end
end

local function LoadZonesFromDB()
    if not Config.UsePersistence then return end
    MySQL.query('SELECT * FROM '..Config.DBTable, {}, function(result)
        if result and #result > 0 then
            for _, row in ipairs(result) do
                savedZones[row.id] = {
                    id = row.id,
                    owner_identifier = row.owner_identifier,
                    owner_serverid = tonumber(row.owner_serverid),
                    coords = { x = tonumber(row.x), y = tonumber(row.y), z = tonumber(row.z) },
                    price = tonumber(row.price),
                    escapes = tonumber(row.escapes) or 0
                }
            end
            TriggerClientEvent('parking:bulkRegisterZones', -1, savedZones)
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadZonesFromDB()
    end
end)

local function SaveZoneToDB(zone)
    if not Config.UsePersistence then return end
    MySQL.insert('INSERT INTO '..Config.DBTable..' (id, owner_identifier, owner_serverid, x, y, z, price, escapes) VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE owner_identifier=?, owner_serverid=?, x=?, y=?, z=?, price=?, escapes=?',
        {zone.id, zone.owner_identifier, zone.owner_serverid, zone.coords.x, zone.coords.y, zone.coords.z, zone.price, zone.escapes,
         zone.owner_identifier, zone.owner_serverid, zone.coords.x, zone.coords.y, zone.coords.z, zone.price, zone.escapes}
    )
end

local function DeleteZone(id)
    savedZones[id] = nil
    if Config.UsePersistence then
        MySQL.update('DELETE FROM '..Config.DBTable..' WHERE id = ?', {id})
    end
end

local function IsSourceZoneOwner(src, zone)
    local identifier = GetIdentifierFromSource(src)
    if not identifier then return false end
    if type(identifier) == 'table' then identifier = identifier[1] end
    if not zone or not zone.owner_identifier then return false end
    return tostring(identifier) == tostring(zone.owner_identifier)
end

local createCooldown = {}
RegisterNetEvent('parking:serverCreateZone', function(zoneId, coords, price)
    local src = source
    if not zoneId or not coords then return end
    if createCooldown[src] and (os.time() - createCooldown[src]) < (Config.CreateCooldown / 1000) then
        return TriggerClientEvent('parking:clientNotify', src, 'Tunggu sebelum membuat lagi.', 'error')
    end
    local ident, _ = GetIdentifierFromSource(src)
    if not ident then return end
    local cnt = 0
    for _, z in pairs(savedZones) do
        if z.owner_identifier == ident then cnt = cnt + 1 end
    end
    if cnt >= Config.MaxZonesPerPlayer then
        return TriggerClientEvent('parking:clientNotify', src, 'Batas lahan tercapai.', 'error')
    end
    local zone = {
        id = tostring(zoneId),
        owner_identifier = tostring(ident),
        owner_serverid = src,
        coords = coords,
        price = tonumber(price) or Config.DefaultPrice,
        escapes = 0
    }
    savedZones[zone.id] = zone
    SaveZoneToDB(zone)
    createCooldown[src] = os.time()
    TriggerClientEvent('parking:clientRegisterZone', -1, zone)
    TriggerClientEvent('parking:clientNotify', src, 'Lahan dibuat ($'..zone.price..')', 'success')
end)

RegisterNetEvent('parking:serverDeleteZone', function(zoneId)
    local src = source
    local zone = savedZones[tostring(zoneId)]
    if not zone then return end
    if not IsSourceZoneOwner(src, zone) then
        return TriggerClientEvent('parking:clientNotify', src, 'Hanya pemilik bisa hapus.', 'error')
    end
    DeleteZone(zone.id)
    TriggerClientEvent('parking:clientRemoveZone', -1, zone.id)
    TriggerClientEvent('parking:clientNotify', src, 'Lahan dihapus.', 'success')
end)

RegisterNetEvent('parking:serverStoreVehicle', function(zoneId)
    local src = source
    if not savedZones[tostring(zoneId)] then return end
    TriggerClientEvent('parking:clientNotify', src, 'Kendaraan disimpan.', 'success')
end)

RegisterNetEvent('parking:serverPayAndTake', function(zoneId)
    local src = source
    local zone = savedZones[tostring(zoneId)]
    if not zone then return end
    local price = tonumber(zone.price) or Config.DefaultPrice
    if Config.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return end
        if not player.Functions.RemoveMoney(Config.Currency, price, "parking-pay") then
            return TriggerClientEvent('parking:clientNotify', src, 'Uang kurang.', 'error')
        end
        if Config.PayDirectToOwner and zone.owner_serverid and GetPlayerName(zone.owner_serverid) then
            local ownerPlayer = QBCore.Functions.GetPlayer(zone.owner_serverid)
            if ownerPlayer then ownerPlayer.Functions.AddMoney(Config.Currency, price, "parking-receive") end
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        if xPlayer.getMoney() < price then
            return TriggerClientEvent('parking:clientNotify', src, 'Uang kurang.', 'error')
        end
        xPlayer.removeMoney(price)
        if zone.owner_serverid and GetPlayerName(zone.owner_serverid) then
            local oPlayer = ESX.GetPlayerFromId(zone.owner_serverid)
            if oPlayer then oPlayer.addMoney(price) end
        end
    else
        TriggerClientEvent('parking:clientNotify', src, 'Bayar $'..price, 'success')
    end
    zone.escapes = 0
    SaveZoneToDB(zone)
    TriggerClientEvent('parking:clientNotify', src, 'Kamu membayar $'..price, 'success')
end)

RegisterNetEvent('parking:serverTakeWithoutPay', function(zoneId)
    local src = source
    local zone = savedZones[tostring(zoneId)]
    if not zone then return end
    zone.escapes = (zone.escapes or 0) + 1
    SaveZoneToDB(zone)
    if zone.owner_serverid and GetPlayerName(zone.owner_serverid) then
        TriggerClientEvent('parking:clientNotify', zone.owner_serverid, GetPlayerName(src)..' kabur tanpa bayar!', 'error')
    end
    if Config.DiscordWebhook ~= '' then
        local embed = {{
            title = "Kabur Tanpa Bayar",
            description = ("Player: %s (id:%d)\nZone: %s\nEscapes: %d"):format(GetPlayerName(src), src, zone.id, zone.escapes),
            color = 16711680,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
        PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({username='ParkingLogs', embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
    if Config.ImpoundAfterEscapes > 0 and zone.escapes >= Config.ImpoundAfterEscapes then
        if Config.ImpoundResource ~= '' then
            TriggerEvent('cruze_garages:impoundVehicleByPlayer', src, zone.coords)
        end
        zone.escapes = 0
        SaveZoneToDB(zone)
    end
    TriggerClientEvent('parking:clientNotify', src, 'Kamu kabur tanpa bayar.', 'error')
end)

RegisterNetEvent('parking:requestZoneSync', function()
    local src = source
    TriggerClientEvent('parking:clientFullSync', src, savedZones)
end)
