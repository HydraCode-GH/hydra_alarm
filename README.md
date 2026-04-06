# hydra_alarm

```text
 _               _                    _
| |__  _   _  __| |_ __ __ _    __ _| | __ _ _ __ _ __ ___
| '_ \| | | |/ _` | '__/ _` |  / _` | |/ _` | '__| '_ ` _ \
| | | | |_| | (_| | | | (_| | | (_| | | (_| | |  | | | | | |
|_| |_|\__, |\__,_|_|  \__,_|  \__,_|_|\__,_|_|  |_| |_| |_|
       |___/
```

This is a vehicle alarm resource for FiveM. It watches nearby locked cars and triggers alarms for damage, jumping on top, and towing.

It runs with ESX, QBCore, or standalone mode and it keeps alarm state synced through the server so nearby players hear and see the same result.

## What it does

1. Caches nearby vehicles and tracks them by normalized plate.
2. Triggers alarms from damage, roof-jump checks, and tow detection.
3. Stops alarms when conditions clear, including untowed tow alarms.
4. Syncs alarm state through server callbacks/events.

## Quick setup

1. Put the resource in your server resources folder.
2. Ensure dependencies are started.
3. Configure [config.lua](config.lua).
4. Add ensure in server config and restart the resource.


## Notifications and edits

Notification behavior is routed through editable hooks so you can swap to your preferred notify system without touching core logic.

File: [shared/editable.lua](shared/editable.lua)

## Commands

1. `stopallalarms` by default, configurable with `Config.StopAllAlarmsCommand`.

Command registration lives in [client/commands.lua](client/commands.lua).

## Exports

Client exports are defined in [client/client.lua](client/client.lua):

1. `startAlarm(vehicle, reason)`
2. `stopAlarm(vehicle)`
3. `hasAlarm(vehicle)`
4. `getActiveAlarms()`

