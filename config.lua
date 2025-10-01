Config = {}

Config.Framework = 'qb'        -- 'qb' | 'esx' | 'ox'
Config.Target = 'ox'           -- 'ox' | 'qb'
Config.UsePersistence = true
Config.DBTable = 'parking_zones'
Config.DefaultPrice = 500
Config.Currency = 'cash'
Config.MaxZonesPerPlayer = 3
Config.ZoneRadius = 3.0
Config.ProgressDuration = 4000
Config.CreateCooldown = 5000
Config.DiscordWebhook = ''
Config.EnableCCTV = false
Config.PayDirectToOwner = true
Config.AllowFreeTake = true
Config.ImpoundAfterEscapes = 3
Config.ImpoundResource = 'qb-garages'
Config.NotifyMethod = 'ox_lib'
Config.WhistleItem = 'peluit'

-- Admin bypass for deleting zones (group names for ESX or list of identifiers for direct)
Config.AdminBypass = {
    qb = {}, -- e.g. { "license:abc", ... } or leave empty
    esx = {} -- same
}
