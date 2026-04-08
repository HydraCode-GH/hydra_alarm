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

RegisterHydraLocale('en', {
    ['notify.alarm_triggered'] = 'A vehicle alarm triggered nearby.',
    ['notify.alarm_stopped']   = 'A nearby vehicle alarm stopped.',
    ['notify.no_permission']   = 'You are not allowed to run this command.',

    ['command.stopall.success'] = 'All alarms stopped.',
    ['command.stopall.denied']  = 'Not allowed to use this command.',

    ['notify.owner_alarm']      = 'Your vehicle (%s) triggered an alarm! Reason: %s',
    ['notify.dispatch_message'] = 'Vehicle alarm triggered. Plate: %s | Reason: %s',
})
