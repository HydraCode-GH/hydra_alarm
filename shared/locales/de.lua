--[[
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
--]]

RegisterHydraLocale('de', {
    ['notify.alarm_triggered'] = 'In der Nähe wurde ein Fahrzeuglarm ausgelöst.',
    ['notify.alarm_stopped']   = 'Ein Fahrzeuglarm in der Nähe wurde gestoppt.',
    ['notify.no_permission']   = 'Dir ist nicht erlaubt, diesen Befehl auszuführen.',

    ['command.stopall.success'] = 'Alle Alarme gestoppt.',
    ['command.stopall.denied']  = 'Du bist nicht berechtigt, diesen Befehl zu verwenden.',

    ['notify.owner_alarm']      = 'Dein Fahrzeug (%s) hat Alarm ausgelöst! Grund: %s',
    ['notify.dispatch_message'] = 'Fahrzeugalarm ausgelöst. Kennzeichen: %s | Grund: %s',
})
