# FiveM Universal Parking Job (Whistle System)

A lightweight and optimized script for **FiveM roleplay servers** that allows players to create their own **parking zones** using a special item (whistle).  
Any player can become a "parking attendant" by using the whistle, and others can park or retrieve their vehicles in these zones — with the option to **pay or escape without paying**.  

## Features
- Works with **QB-Core**, **ESX**, or **Ox** frameworks.  
- Supports **ox_target** and **qb-target**.  
- Configurable in `config.lua`.  
- **Persistent zones** saved in database (optional).  
- Players can:
  - Create zones using the whistle item.  
  - Park vehicles inside the zone.  
  - Retrieve vehicles by paying the owner or escaping without paying.  
- Owners can delete their zones anytime.  
- **Discord webhook logs** when players escape without paying.  
- **Anti-spam cooldowns** and per-player limits.  
- Integration-ready with **Cruze Garages** for impound.  

## Installation
1. Clone or download this repository into your `resources` folder.  
2. Import the provided SQL schema if persistence is enabled:
   ```sql
   CREATE TABLE IF NOT EXISTS parking_zones (
     id VARCHAR(64) NOT NULL PRIMARY KEY,
     owner_identifier VARCHAR(100) NOT NULL,
     owner_serverid INT NOT NULL,
     x DOUBLE NOT NULL,
     y DOUBLE NOT NULL,
     z DOUBLE NOT NULL,
     price INT NOT NULL DEFAULT 500,
     escapes INT NOT NULL DEFAULT 0,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

3. Add to your server.cfg:
   ```cfg
   ensure zv-parkingjob
   ```
4. Configure settings in `config.lua`.
5. Add the whistle item to your inventory system (ox_inventory / qb-inventory / esx). Example for ox_inventory:
   ```lua
   ['whistle'] = {
    label = 'Parking Whistle',
    weight = 10,
    stack = false,
    close = true,
    description = 'Use to create a parking zone.',
    client = {
        event = 'parking:clientUseWhistle',
        args = { price = 500 }
    }
    ```
## Usages

- Give yourself the whistle item.
- Use it to create a parking zone at your current location.
- Other players can park vehicles inside the zone.
- To retrieve a vehicle, they must pay or choose to escape without paying.
- Owners can remove their zones anytime.

## Showcase

- Create your own parking lot anywhere in the city.
- Collect money from other players who park in your zone.
- Handle situations where players escape without paying — fully logged to Discord.

## Credits

Developed by Zevarda
Inspired by Indonesian FiveM RP community needs.
