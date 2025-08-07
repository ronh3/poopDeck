-- Status Window Service
-- Manages dedicated windows for different activity statuses

poopDeck.services = poopDeck.services or {}

-- StatusWindowService class definition
poopDeck.services.StatusWindowService = poopDeck.core.BaseClass:extend("StatusWindowService")

function poopDeck.services.StatusWindowService:initialize(config)
    config = config or {}
    
    -- Window settings
    self.settings = {
        enabled = config.enabled ~= false,
        windowWidth = config.windowWidth or 300,
        windowHeight = config.windowHeight or 150,
        fontSize = config.fontSize or 12,
        fontFamily = config.fontFamily or "Ubuntu Mono",
        refreshRate = config.refreshRate or 1000, -- milliseconds
        autoHide = config.autoHide ~= false
    }
    
    -- Window definitions
    self.windows = {
        combat = {
            name = "poopDeckCombat",
            title = "Combat Status",
            active = false,
            x = 10,
            y = 10,
            content = "",
            colors = {
                bg = "black",
                text = "#00FF00",
                border = "#FF0000"
            }
        },
        ship = {
            name = "poopDeckShip", 
            title = "Ship Status",
            active = false,
            x = 320,
            y = 10,
            content = "",
            colors = {
                bg = "black",
                text = "#00FFFF",
                border = "#0080FF"
            }
        },
        fishing = {
            name = "poopDeckFishing",
            title = "Fishing Status", 
            active = false,
            x = 630,
            y = 10,
            content = "",
            colors = {
                bg = "black",
                text = "#FFFF00",
                border = "#FFA500"
            }
        },
        notifications = {
            name = "poopDeckNotifications",
            title = "Alerts",
            active = false,
            x = 10,
            y = 170,
            content = "",
            colors = {
                bg = "black", 
                text = "#FF69B4",
                border = "#FF1493"
            }
        }
    }
    
    -- Status tracking
    self.status = {
        combat = {
            firing = false,
            weapon = nil,
            target = nil,
            shotsRemaining = 0,
            outOfRange = false,
            autoFire = false
        },
        ship = {
            maintaining = nil,
            hull = 100,
            sails = 100,
            speed = 0,
            heading = "north",
            docked = true
        },
        fishing = {
            active = false,
            baitType = nil,
            lureType = nil,
            hooked = false
        }
    }
    
    -- Update timers
    self.timers = {}
    
    -- Initialize windows if enabled
    if self.settings.enabled then
        self:initializeWindows()
    end
end

-- Window management
function poopDeck.services.StatusWindowService:initializeWindows()
    for windowName, windowData in pairs(self.windows) do
        self:createWindow(windowName, windowData)
    end
    
    -- Start update timer
    self.timers.update = tempTimer(self.settings.refreshRate / 1000, function()
        self:updateAllWindows()
        -- Reschedule
        self.timers.update = tempTimer(self.settings.refreshRate / 1000, function()
            self:updateAllWindows()
        end)
    end)
end

function poopDeck.services.StatusWindowService:createWindow(windowName, windowData)
    -- Close existing window if it exists
    if windowData.active then
        self:closeWindow(windowName)
    end
    
    -- Create new window with safe operations
    local success = poopDeck.safe.openUserWindow(windowData.name, true, "create_window_" .. windowName)
    if not success then
        self:emit("windowCreateFailed", windowName)
        return false, "Failed to create window: " .. windowName
    end
    
    -- Configure window with safety checks
    poopDeck.safe.resizeUserWindow(windowData.name, self.settings.windowWidth, self.settings.windowHeight, "resize_window_" .. windowName)
    poopDeck.safe.moveUserWindow(windowData.name, windowData.x, windowData.y, "move_window_" .. windowName)
    
    -- Set title safely
    local success = poopDeck.safe.call(function()
        setUserWindowTitle(windowData.name, windowData.title)
    end, "set_title_" .. windowName)
    
    if not success then
        -- Fallback: window created but title setting failed
        windowData.title = windowData.title .. " (title failed)"
    end
    
    -- Set styling
    setBackgroundColor(windowData.name, unpack(self:hexToRgb(windowData.colors.bg)))
    
    -- Set font
    setUserWindowStyleSheet(windowData.name, string.format([[
        QTextEdit {
            background-color: %s;
            color: %s;
            border: 2px solid %s;
            font-family: %s;
            font-size: %dpx;
            padding: 5px;
        }
    ]], windowData.colors.bg, windowData.colors.text, windowData.colors.border,
        self.settings.fontFamily, self.settings.fontSize))
    
    windowData.active = true
    self:emit("windowCreated", windowName)
end

function poopDeck.services.StatusWindowService:closeWindow(windowName)
    local windowData = self.windows[windowName]
    if windowData and windowData.active then
        poopDeck.safe.closeUserWindow(windowData.name, "close_window_" .. windowName)
        windowData.active = false
        self:emit("windowClosed", windowName)
    end
end

-- Status updates
function poopDeck.services.StatusWindowService:updateCombatStatus()
    local combat = self.status.combat
    local content = {}
    
    -- Header
    table.insert(content, "<font color='#FF0000'><b>═══ COMBAT ═══</b></font>")
    table.insert(content, "")
    
    -- Weapon status
    if combat.weapon then
        table.insert(content, string.format("<font color='#00FF00'>Weapon:</font> %s", combat.weapon))
    else
        table.insert(content, "<font color='#808080'>No weapon selected</font>")
    end
    
    -- Firing status
    if combat.firing then
        table.insert(content, "<font color='#FF0000'><b>>>> FIRING! <<<</b></font>")
    else
        table.insert(content, "<font color='#00FF00'>Ready to fire</font>")
    end
    
    -- Auto-fire status
    table.insert(content, string.format("<font color='#00FFFF'>Auto-fire:</font> %s", 
        combat.autoFire and "<font color='#00FF00'>ON</font>" or "<font color='#808080'>OFF</font>"))
    
    -- Target info
    if combat.target then
        table.insert(content, "")
        table.insert(content, string.format("<font color='#FFFF00'>Target:</font> %s", combat.target))
        if combat.shotsRemaining > 0 then
            table.insert(content, string.format("<font color='#FFA500'>Remaining:</font> %d shots", combat.shotsRemaining))
        end
    end
    
    -- Range status
    if combat.outOfRange then
        table.insert(content, "")
        table.insert(content, "<font color='#FF0000'><b>⚠ OUT OF RANGE ⚠</b></font>")
    end
    
    self:updateWindowContent("combat", table.concat(content, "<br>"))
end

function poopDeck.services.StatusWindowService:updateShipStatus()
    local ship = self.status.ship
    local content = {}
    
    -- Header
    table.insert(content, "<font color='#0080FF'><b>═══ SHIP ═══</b></font>")
    table.insert(content, "")
    
    -- Maintenance status
    if ship.maintaining then
        table.insert(content, string.format("<font color='#FFA500'><b>MAINTAINING %s</b></font>", ship.maintaining:upper()))
    else
        table.insert(content, "<font color='#00FF00'>Not maintaining</font>")
    end
    
    -- Hull condition
    local hullColor = ship.hull >= 80 and "#00FF00" or ship.hull >= 50 and "#FFFF00" or "#FF0000"
    table.insert(content, string.format("<font color='%s'>Hull:</font> %d%%", hullColor, ship.hull))
    
    -- Sails condition  
    local sailsColor = ship.sails >= 80 and "#00FF00" or ship.sails >= 50 and "#FFFF00" or "#FF0000"
    table.insert(content, string.format("<font color='%s'>Sails:</font> %d%%", sailsColor, ship.sails))
    
    -- Movement
    table.insert(content, "")
    if ship.docked then
        table.insert(content, "<font color='#808080'>⚓ DOCKED</font>")
    else
        table.insert(content, string.format("<font color='#00FFFF'>Speed:</font> %d", ship.speed))
        table.insert(content, string.format("<font color='#00FFFF'>Heading:</font> %s", ship.heading))
    end
    
    self:updateWindowContent("ship", table.concat(content, "<br>"))
end

function poopDeck.services.StatusWindowService:updateFishingStatus()
    local fishing = self.status.fishing
    local content = {}
    
    -- Header
    table.insert(content, "<font color='#FFA500'><b>═══ FISHING ═══</b></font>")
    table.insert(content, "")
    
    if fishing.active then
        table.insert(content, "<font color='#00FF00'><b>🎣 FISHING ACTIVE</b></font>")
        
        if fishing.baitType then
            table.insert(content, string.format("<font color='#FFFF00'>Bait:</font> %s", fishing.baitType))
        end
        
        if fishing.lureType then
            table.insert(content, string.format("<font color='#FFFF00'>Lure:</font> %s", fishing.lureType))
        end
        
        if fishing.hooked then
            table.insert(content, "")
            table.insert(content, "<font color='#FF0000'><b>🐟 FISH HOOKED!</b></font>")
        end
    else
        table.insert(content, "<font color='#808080'>Not fishing</font>")
        table.insert(content, "")
        table.insert(content, "<font color='#808080'>Cast a line to start</font>")
    end
    
    self:updateWindowContent("fishing", table.concat(content, "<br>"))
end

function poopDeck.services.StatusWindowService:updateNotifications()
    -- This window shows recent alerts and spawn timers
    local content = {}
    
    table.insert(content, "<font color='#FF1493'><b>═══ ALERTS ═══</b></font>")
    table.insert(content, "")
    
    -- Spawn countdown
    if poopDeck.session and poopDeck.session.monsterTracker then
        local countdown = poopDeck.session.monsterTracker:getSpawnCountdown()
        if countdown then
            table.insert(content, string.format("<font color='#00FFFF'>Next spawn:</font> %s", countdown))
        end
    end
    
    -- Recent notifications would go here
    table.insert(content, "")
    table.insert(content, "<font color='#808080'>Recent activity will</font>")
    table.insert(content, "<font color='#808080'>appear here...</font>")
    
    self:updateWindowContent("notifications", table.concat(content, "<br>"))
end

function poopDeck.services.StatusWindowService:updateWindowContent(windowName, content)
    local windowData = self.windows[windowName]
    if windowData and windowData.active then
        windowData.content = content
        
        -- Clear window safely
        local clearSuccess = poopDeck.safe.clearUserWindow(windowData.name, "clear_window_" .. windowName)
        
        -- Display content safely
        local success = poopDeck.safe.call(function()
            cecho(windowData.name, content)
        end, "update_content_" .. windowName)
        
        if not success then
            -- Fallback to main window if window update fails
            poopDeck.safe.echo("[" .. windowData.title .. "] " .. content:gsub("<[^>]*>", ""), "window_fallback_" .. windowName)
        end
    end
end

function poopDeck.services.StatusWindowService:updateAllWindows()
    if not self.settings.enabled then
        return
    end
    
    -- Gather current status from global state and session
    self:gatherStatus()
    
    -- Update each active window
    if self.windows.combat.active then
        self:updateCombatStatus()
    end
    
    if self.windows.ship.active then
        self:updateShipStatus()
    end
    
    if self.windows.fishing.active then
        self:updateFishingStatus()
    end
    
    if self.windows.notifications.active then
        self:updateNotifications()
    end
end

function poopDeck.services.StatusWindowService:gatherStatus()
    -- Update combat status
    if poopDeck.session and poopDeck.session.combat then
        local combat = poopDeck.session.combat
        self.status.combat.autoFire = combat.settings.autoFire
        self.status.combat.weapon = combat.settings.preferredWeapon
        
        if combat.currentMonster then
            self.status.combat.target = combat.currentMonster.name
            self.status.combat.shotsRemaining = combat.currentMonster:getRemainingShots()
        else
            self.status.combat.target = nil
            self.status.combat.shotsRemaining = 0
        end
    end
    
    -- Update from global variables (legacy compatibility)
    self.status.combat.firing = poopDeck.firing or false
    self.status.combat.outOfRange = poopDeck.oor or false
    self.status.ship.maintaining = poopDeck.maintain
    
    -- Update ship status from session if available
    if poopDeck.session and poopDeck.session.ship then
        local ship = poopDeck.session.ship
        local hullPercent = (ship.condition.hull.current / ship.condition.hull.max) * 100
        local sailsPercent = (ship.condition.sails.current / ship.condition.sails.max) * 100
        
        self.status.ship.hull = math.floor(hullPercent)
        self.status.ship.sails = math.floor(sailsPercent)
        self.status.ship.speed = ship.state.sailSpeed
        self.status.ship.heading = ship.state.heading
        self.status.ship.docked = ship.state.docked
    end
    
    -- Fishing status would be updated here when fishing system is implemented
end

-- Public API methods
function poopDeck.services.StatusWindowService:showWindow(windowName)
    local windowData = self.windows[windowName]
    if not windowData then
        return false, "Unknown window: " .. tostring(windowName)
    end
    
    if not windowData.active then
        self:createWindow(windowName, windowData)
        self:updateAllWindows()
    end
    
    return true, string.format("%s window opened", windowData.title)
end

function poopDeck.services.StatusWindowService:hideWindow(windowName)
    local windowData = self.windows[windowName]
    if not windowData then
        return false, "Unknown window: " .. tostring(windowName)
    end
    
    if windowData.active then
        self:closeWindow(windowName)
    end
    
    return true, string.format("%s window closed", windowData.title)
end

function poopDeck.services.StatusWindowService:toggleWindow(windowName)
    local windowData = self.windows[windowName]
    if not windowData then
        return false, "Unknown window: " .. tostring(windowName)
    end
    
    if windowData.active then
        return self:hideWindow(windowName)
    else
        return self:showWindow(windowName)
    end
end

function poopDeck.services.StatusWindowService:showAllWindows()
    for windowName, _ in pairs(self.windows) do
        self:showWindow(windowName)
    end
    return true, "All status windows opened"
end

function poopDeck.services.StatusWindowService:hideAllWindows()
    for windowName, _ in pairs(self.windows) do
        self:hideWindow(windowName)
    end
    return true, "All status windows closed"
end

function poopDeck.services.StatusWindowService:enable()
    self.settings.enabled = true
    self:initializeWindows()
    self:emit("enabled")
    return true, "Status windows enabled"
end

function poopDeck.services.StatusWindowService:disable()
    self.settings.enabled = false
    self:hideAllWindows()
    
    -- Clear timers
    for timerName, timerId in pairs(self.timers) do
        if timerId then
            killTimer(timerId)
        end
    end
    self.timers = {}
    
    self:emit("disabled")
    return true, "Status windows disabled"
end

-- Utility methods
function poopDeck.services.StatusWindowService:hexToRgb(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1,2)), tonumber("0x" .. hex:sub(3,4)), tonumber("0x" .. hex:sub(5,6))
end

function poopDeck.services.StatusWindowService:getStatus()
    return {
        enabled = self.settings.enabled,
        activeWindows = {},
        windowCount = 0
    }
end

function poopDeck.services.StatusWindowService:toString()
    local activeCount = 0
    for _, windowData in pairs(self.windows) do
        if windowData.active then
            activeCount = activeCount + 1
        end
    end
    
    return string.format("[StatusWindowService: %s, %d windows active]", 
        self.settings.enabled and "enabled" or "disabled",
        activeCount)
end