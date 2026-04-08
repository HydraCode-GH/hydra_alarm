# hydra_alarm

```text
 /$$                       /$$                                     /$$
| $$                      | $$                                    | $$
| $$$$$$$  /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$          /$$$$$$ | $$  /$$$$$$   /$$$$$$  /$$$$$$/$$$$
| $$__  $$| $$  | $$ /$$__  $$ /$$__  $$|____  $$ /$$$$$$|____  $$| $$ |____  $$ /$$__  $$| $$_  $$_  $$
| $$  \ $$| $$  | $$| $$  | $$| $$  \__/ /$$$$$$$|______/ /$$$$$$$| $$  /$$$$$$$| $$  \__/| $$ \ $$ \ $$
| $$  | $$| $$  | $$| $$  | $$| $$      /$$__  $$        /$$__  $$| $$ /$$__  $$| $$      | $$ | $$ | $$
| $$  | $$|  $$$$$$$|  $$$$$$$| $$     |  $$$$$$$       |  $$$$$$$| $$|  $$$$$$$| $$      | $$ | $$ | $$
|__/  |__/ \____  $$ \_______/|__/      \_______/        \_______/|__/ \_______/|__/      |__/ |__/ |__/
           /$$  | $$
          |  $$$$$$/
           \______/
```

This is a vehicle alarm resource for FiveM. It watches nearby locked cars and triggers alarms for damage, jumping on top, and towing.

It runs with ESX, QBCore, or standalone mode and it keeps alarm state synced through the server so nearby players hear and see the same result.

## What it does

1. Caches nearby vehicles and tracks them by normalized plate.
2. Triggers alarms from damage, roof-jump checks, and tow detection.
3. Stops alarms when conditions clear, including untowed tow alarms.
4. Syncs alarm state through server callbacks/events.

## Quick setup

1. [Get the newest release here](https://github.com/HydraCode-GH/hydra_alarm/)
1. Put the resource in your server resources folder.
2. Configure the [config.lua](config.lua).
3. Add this in server.cfg and restart the server:

```cfg
start hydra_alarm
```


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

## Preview
[Watch preview video](./preview.mp4)