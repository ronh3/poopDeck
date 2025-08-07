-- Notification Settings Aliases
-- Manage spawn notification timers

local command = matches[1]

if command == "notifications" or command == "notify" then
    -- Toggle all notifications
    poopDeck.toggleNotifications()
    
elseif command == "spawntimer" or command == "timer" then
    -- Show spawn countdown
    poopDeck.spawnCountdown()
    
elseif command == "notifystatus" then
    -- Show notification settings status
    poopDeck.notificationStatus()
    
elseif command:match("^notify(.+)") then
    local setting = command:match("^notify(.+)")
    
    if setting == "5min" or setting == "5minute" then
        poopDeck.session:toggleSpawnWarning("fiveMinute")
    elseif setting == "1min" or setting == "1minute" then
        poopDeck.session:toggleSpawnWarning("oneMinute")
    elseif setting == "fish" or setting == "fishing" then
        poopDeck.session:toggleSpawnWarning("timeToFish")
    else
        poopDeck.badEcho("Unknown notification setting: " .. setting)
        poopDeck.settingEcho("Available: notify5min, notify1min, notifyfish")
    end
else
    poopDeck.badEcho("Unknown notification command: " .. command)
    poopDeck.settingEcho("Available: notifications, spawntimer, notifystatus")
end