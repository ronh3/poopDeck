-- Status Window Aliases
-- Manage dedicated status display windows

local command = matches[1]

if command == "poopwindows" or command == "poopstatus" then
    -- Toggle all status windows
    poopDeck.toggleStatusWindows()
    
elseif command == "poopcombat" then
    -- Show combat status window
    poopDeck.session:showStatusWindow("combat")
    
elseif command == "poopship" then
    -- Show ship status window
    poopDeck.session:showStatusWindow("ship")
    
elseif command == "poopfish" or command == "poopfishing" then
    -- Show fishing status window
    poopDeck.session:showStatusWindow("fishing")
    
elseif command == "poopalerts" or command == "poopnotify" then
    -- Show notifications/alerts window
    poopDeck.session:showStatusWindow("notifications")
    
elseif command == "poopshowall" or command == "poopopenall" then
    -- Show all status windows
    poopDeck.showAllWindows()
    
elseif command == "poophideall" or command == "poopcloseall" then
    -- Hide all status windows
    poopDeck.hideAllWindows()
    
elseif command:match("^poophide(.+)$") then
    local windowName = command:match("^poophide(.+)$")
    local windowMap = {
        combat = "combat",
        ship = "ship", 
        fish = "fishing",
        fishing = "fishing",
        alerts = "notifications",
        notify = "notifications"
    }
    
    local actualWindow = windowMap[windowName]
    if actualWindow then
        poopDeck.session:hideStatusWindow(actualWindow)
    else
        poopDeck.badEcho("Unknown window: " .. windowName)
        poopDeck.settingEcho("Available: combat, ship, fish, alerts")
    end
    
else
    poopDeck.badEcho("Unknown window command: " .. command)
    echo("\n<yellow>poopDeck Status Window Commands:</yellow>\n")
    echo("  <cyan>poopwindows</cyan> - Toggle all windows on/off\n")
    echo("  <cyan>poopcombat</cyan> - Show combat status window\n") 
    echo("  <cyan>poopship</cyan> - Show ship status window\n")
    echo("  <cyan>poopfish</cyan> - Show fishing status window\n")
    echo("  <cyan>poopalerts</cyan> - Show alerts/notifications window\n")
    echo("  <cyan>poopshowall</cyan> - Open all status windows\n")
    echo("  <cyan>poophideall</cyan> - Close all status windows\n")
    echo("  <cyan>poophide[window]</cyan> - Close specific window (e.g. poophidecombat)\n")
end