-- Load spec helper
require('spec.spec_helper')

-- Status window service tests
describe("poopDeck Status Window Service", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.core = poopDeck.core.BaseClass or {}
        
        -- Mock Mudlet window functions
        _G.windowData = {}
        _G.windowState = {}
        
        createMiniConsole = function(name, x, y, width, height)
            _G.windowData[name] = {
                x = x, y = y, width = width, height = height,
                created = true,
                visible = false,
                content = ""
            }
            return true
        end
        
        showWindow = function(name)
            if _G.windowData[name] then
                _G.windowData[name].visible = true
                _G.lastShownWindow = name
                return true
            end
            return false
        end
        
        hideWindow = function(name)
            if _G.windowData[name] then
                _G.windowData[name].visible = false
                _G.lastHiddenWindow = name
                return true
            end
            return false
        end
        
        resizeWindow = function(name, width, height)
            if _G.windowData[name] then
                _G.windowData[name].width = width
                _G.windowData[name].height = height
                _G.lastResizedWindow = {name = name, width = width, height = height}
                return true
            end
            return false
        end
        
        moveWindow = function(name, x, y)
            if _G.windowData[name] then
                _G.windowData[name].x = x
                _G.windowData[name].y = y
                _G.lastMovedWindow = {name = name, x = x, y = y}
                return true
            end
            return false
        end
        
        clearWindow = function(name)
            if _G.windowData[name] then
                _G.windowData[name].content = ""
                _G.lastClearedWindow = name
                return true
            end
            return false
        end
        
        cecho = function(name, text)
            if _G.windowData[name] then
                _G.windowData[name].content = _G.windowData[name].content .. text
                _G.lastCechoWindow = name
                _G.lastCechoText = text
                return true
            end
            return false
        end
        
        echo = function(name, text)
            if _G.windowData[name] then
                _G.windowData[name].content = _G.windowData[name].content .. text
                _G.lastEchoWindow = name
                _G.lastEchoText = text
                return true
            end
            return false
        end
        
        -- Mock BaseClass
        poopDeck.core.BaseClass = {
            extend = function(self, className)
                local class = setmetatable({}, {__index = self})
                class.className = className
                class.observers = {}
                return class
            end,
            on = function(self, event, callback)
                self.observers[event] = self.observers[event] or {}
                table.insert(self.observers[event], callback)
            end,
            emit = function(self, event, ...)
                if self.observers and self.observers[event] then
                    for _, callback in ipairs(self.observers[event]) do
                        pcall(callback, ...)
                    end
                end
            end
        }
        
        -- Create StatusWindowService
        poopDeck.services.StatusWindowService = poopDeck.core.BaseClass:extend("StatusWindowService")
        function poopDeck.services.StatusWindowService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.windows = {}
            instance.observers = {}
            
            -- Default window configurations
            instance.windowConfigs = {
                combat = {
                    name = "poopCombat",
                    title = "Combat Status",
                    x = 0, y = 0,
                    width = 300, height = 150,
                    visible = false,
                    autoHide = true,
                    maxLines = 20
                },
                ship = {
                    name = "poopShip", 
                    title = "Ship Status",
                    x = 0, y = 160,
                    width = 300, height = 200,
                    visible = false,
                    autoHide = false,
                    maxLines = 25
                },
                fishing = {
                    name = "poopFishing",
                    title = "Fishing Status", 
                    x = 310, y = 0,
                    width = 250, height = 180,
                    visible = false,
                    autoHide = true,
                    maxLines = 15
                },
                alerts = {
                    name = "poopAlerts",
                    title = "Alert Messages",
                    x = 310, y = 190,
                    width = 250, height = 120,
                    visible = false,
                    autoHide = false,
                    maxLines = 10
                }
            }
            
            return instance
        end
        
        function poopDeck.services.StatusWindowService:initializeWindows()
            for windowType, config in pairs(self.windowConfigs) do
                local success = self:createWindow(windowType, config)
                if not success then
                    return false, "Failed to create " .. windowType .. " window"
                end
            end
            return true, "All windows initialized"
        end
        
        function poopDeck.services.StatusWindowService:createWindow(windowType, config)
            local success = createMiniConsole(config.name, config.x, config.y, config.width, config.height)
            if success then
                self.windows[windowType] = {
                    config = config,
                    lineCount = 0,
                    lastUpdate = os.time(),
                    content = {}
                }
                
                -- Set window title
                self:updateWindowTitle(windowType)
                return true
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:updateWindowTitle(windowType)
            local window = self.windows[windowType]
            if window then
                local titleText = "<white>" .. window.config.title .. "<reset>"
                cecho(window.config.name, titleText .. "\n")
                cecho(window.config.name, string.rep("-", 30) .. "\n")
            end
        end
        
        function poopDeck.services.StatusWindowService:showWindow(windowType)
            local window = self.windows[windowType]
            if window then
                local success = showWindow(window.config.name)
                if success then
                    window.config.visible = true
                    self:emit("windowShown", windowType)
                end
                return success
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:hideWindow(windowType)
            local window = self.windows[windowType]
            if window then
                local success = hideWindow(window.config.name)
                if success then
                    window.config.visible = false
                    self:emit("windowHidden", windowType)
                end
                return success
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:toggleWindow(windowType)
            local window = self.windows[windowType]
            if window then
                if window.config.visible then
                    return self:hideWindow(windowType)
                else
                    return self:showWindow(windowType)
                end
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:clearWindow(windowType)
            local window = self.windows[windowType]
            if window then
                clearWindow(window.config.name)
                window.lineCount = 0
                window.content = {}
                self:updateWindowTitle(windowType)
                return true
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:addMessage(windowType, message, color)
            local window = self.windows[windowType]
            if not window then return false end
            
            color = color or "white"
            local timestamp = os.date("%H:%M:%S")
            local formattedMessage = string.format("<%s>[%s]<reset> %s", color, timestamp, message)
            
            -- Add to content history
            table.insert(window.content, {
                message = message,
                color = color,
                timestamp = timestamp,
                time = os.time()
            })
            
            -- Manage line count
            window.lineCount = window.lineCount + 1
            if window.lineCount > window.config.maxLines then
                self:clearWindow(windowType)
                -- Re-add recent messages
                local keepCount = math.floor(window.config.maxLines * 0.7)
                local recentMessages = {}
                for i = math.max(1, #window.content - keepCount), #window.content do
                    table.insert(recentMessages, window.content[i])
                end
                window.content = recentMessages
                
                for _, msg in ipairs(recentMessages) do
                    local reFormattedMsg = string.format("<%s>[%s]<reset> %s", msg.color, msg.timestamp, msg.message)
                    cecho(window.config.name, reFormattedMsg .. "\n")
                end
                window.lineCount = #recentMessages
            else
                cecho(window.config.name, formattedMessage .. "\n")
            end
            
            -- Auto-show window if configured
            if not window.config.visible then
                self:showWindow(windowType)
            end
            
            window.lastUpdate = os.time()
            self:emit("messageAdded", windowType, message)
            return true
        end
        
        function poopDeck.services.StatusWindowService:addCombatMessage(message)
            return self:addMessage("combat", message, "red")
        end
        
        function poopDeck.services.StatusWindowService:addShipMessage(message)
            return self:addMessage("ship", message, "cyan")
        end
        
        function poopDeck.services.StatusWindowService:addFishingMessage(message)
            return self:addMessage("fishing", message, "green")
        end
        
        function poopDeck.services.StatusWindowService:addAlertMessage(message)
            return self:addMessage("alerts", message, "yellow")
        end
        
        function poopDeck.services.StatusWindowService:resizeWindow(windowType, width, height)
            local window = self.windows[windowType]
            if window then
                local success = resizeWindow(window.config.name, width, height)
                if success then
                    window.config.width = width
                    window.config.height = height
                end
                return success
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:moveWindow(windowType, x, y)
            local window = self.windows[windowType]
            if window then
                local success = moveWindow(window.config.name, x, y)
                if success then
                    window.config.x = x
                    window.config.y = y
                end
                return success
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:getWindowInfo(windowType)
            local window = self.windows[windowType]
            if window then
                return {
                    name = window.config.name,
                    title = window.config.title,
                    visible = window.config.visible,
                    x = window.config.x,
                    y = window.config.y,
                    width = window.config.width,
                    height = window.config.height,
                    lineCount = window.lineCount,
                    lastUpdate = window.lastUpdate,
                    messageCount = #window.content
                }
            end
            return nil
        end
        
        function poopDeck.services.StatusWindowService:getAllWindowsInfo()
            local info = {}
            for windowType, _ in pairs(self.windows) do
                info[windowType] = self:getWindowInfo(windowType)
            end
            return info
        end
        
        function poopDeck.services.StatusWindowService:setAutoHide(windowType, autoHide)
            local window = self.windows[windowType]
            if window then
                window.config.autoHide = autoHide
                return true
            end
            return false
        end
        
        function poopDeck.services.StatusWindowService:autoHideInactiveWindows(inactiveTime)
            inactiveTime = inactiveTime or 300 -- 5 minutes default
            local currentTime = os.time()
            local hiddenWindows = {}
            
            for windowType, window in pairs(self.windows) do
                if window.config.autoHide and window.config.visible then
                    if currentTime - window.lastUpdate > inactiveTime then
                        self:hideWindow(windowType)
                        table.insert(hiddenWindows, windowType)
                    end
                end
            end
            
            return hiddenWindows
        end
        
        -- Create command handlers
        poopDeck.command = poopDeck.command or {}
        
        poopDeck.command.poopwindows = function()
            local service = poopDeck.services.statusWindows
            if not service then
                poopDeck.badEcho("Status window service not available")
                return false
            end
            
            local info = service:getAllWindowsInfo()
            poopDeck.goodEcho("=== poopDeck Status Windows ===")
            for windowType, windowInfo in pairs(info) do
                local status = windowInfo.visible and "Visible" or "Hidden"
                local pos = string.format("(%d,%d)", windowInfo.x, windowInfo.y)
                local size = string.format("%dx%d", windowInfo.width, windowInfo.height)
                poopDeck.goodEcho(string.format("%s: %s %s %s (%d messages)", 
                    windowInfo.title, status, pos, size, windowInfo.messageCount))
            end
            return true
        end
        
        poopDeck.command.poopcombat = function()
            local service = poopDeck.services.statusWindows
            return service:toggleWindow("combat")
        end
        
        poopDeck.command.poopship = function()
            local service = poopDeck.services.statusWindows
            return service:toggleWindow("ship")
        end
        
        poopDeck.command.poopfishing = function()
            local service = poopDeck.services.statusWindows
            return service:toggleWindow("fishing")
        end
        
        poopDeck.command.poopalerts = function()
            local service = poopDeck.services.statusWindows
            return service:toggleWindow("alerts")
        end
        
        -- Clear test state
        _G.windowData = {}
        _G.lastShownWindow = nil
        _G.lastHiddenWindow = nil
        _G.lastResizedWindow = nil
        _G.lastMovedWindow = nil
        _G.lastClearedWindow = nil
        _G.lastCechoWindow = nil
        _G.lastCechoText = nil
        _G.lastEchoWindow = nil
        _G.lastEchoText = nil
    end)
    
    describe("Window creation and initialization", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
        end)
        
        it("should initialize all windows successfully", function()
            local success, message = service:initializeWindows()
            
            assert.are.equal(true, success)
            assert.are.equal("All windows initialized", message)
            
            -- Verify all windows were created
            assert.is_not_nil(_G.windowData["poopCombat"])
            assert.is_not_nil(_G.windowData["poopShip"])
            assert.is_not_nil(_G.windowData["poopFishing"])
            assert.is_not_nil(_G.windowData["poopAlerts"])
        end)
        
        it("should create individual windows with correct properties", function()
            service:initializeWindows()
            
            local combatWindow = _G.windowData["poopCombat"]
            assert.are.equal(0, combatWindow.x)
            assert.are.equal(0, combatWindow.y)
            assert.are.equal(300, combatWindow.width)
            assert.are.equal(150, combatWindow.height)
            
            local shipWindow = _G.windowData["poopShip"]
            assert.are.equal(0, shipWindow.x)
            assert.are.equal(160, shipWindow.y)
            assert.are.equal(300, shipWindow.width)
            assert.are.equal(200, shipWindow.height)
        end)
        
        it("should set up window titles", function()
            service:initializeWindows()
            
            -- Check that windows have content (titles)
            assert.truthy(_G.windowData["poopCombat"].content:len() > 0)
            assert.truthy(_G.windowData["poopShip"].content:len() > 0)
        end)
    end)
    
    describe("Window visibility management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
        end)
        
        it("should show and hide windows", function()
            local showResult = service:showWindow("combat")
            assert.are.equal(true, showResult)
            assert.are.equal("poopCombat", _G.lastShownWindow)
            assert.are.equal(true, _G.windowData["poopCombat"].visible)
            
            local hideResult = service:hideWindow("combat")
            assert.are.equal(true, hideResult)
            assert.are.equal("poopCombat", _G.lastHiddenWindow)
            assert.are.equal(false, _G.windowData["poopCombat"].visible)
        end)
        
        it("should toggle window visibility", function()
            -- Initially hidden
            assert.are.equal(false, service.windows.combat.config.visible)
            
            -- First toggle should show
            local result1 = service:toggleWindow("combat")
            assert.are.equal(true, result1)
            assert.are.equal(true, service.windows.combat.config.visible)
            
            -- Second toggle should hide
            local result2 = service:toggleWindow("combat")
            assert.are.equal(true, result2)
            assert.are.equal(false, service.windows.combat.config.visible)
        end)
        
        it("should handle invalid window types", function()
            local result = service:showWindow("invalid")
            assert.are.equal(false, result)
        end)
    end)
    
    describe("Message management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
        end)
        
        it("should add messages to windows", function()
            local result = service:addMessage("combat", "Test combat message", "red")
            
            assert.are.equal(true, result)
            assert.are.equal("poopCombat", _G.lastCechoWindow)
            assert.truthy(_G.lastCechoText:match("Test combat message"))
            assert.are.equal(1, service.windows.combat.lineCount)
        end)
        
        it("should add specialized messages", function()
            service:addCombatMessage("Combat event")
            assert.truthy(_G.lastCechoText:match("Combat event"))
            
            service:addShipMessage("Ship status")
            assert.truthy(_G.lastCechoText:match("Ship status"))
            
            service:addFishingMessage("Fish caught")
            assert.truthy(_G.lastCechoText:match("Fish caught"))
            
            service:addAlertMessage("Important alert")
            assert.truthy(_G.lastCechoText:match("Important alert"))
        end)
        
        it("should auto-show windows when messages are added", function()
            -- Combat window starts hidden
            assert.are.equal(false, service.windows.combat.config.visible)
            
            service:addCombatMessage("Auto-show test")
            
            -- Should now be visible
            assert.are.equal(true, service.windows.combat.config.visible)
        end)
        
        it("should manage line count and clear when exceeding max", function()
            local maxLines = service.windowConfigs.combat.maxLines
            
            -- Add messages exceeding max lines
            for i = 1, maxLines + 5 do
                service:addCombatMessage("Message " .. i)
            end
            
            -- Should have cleared and kept recent messages
            assert.truthy(service.windows.combat.lineCount < maxLines)
            assert.are.equal("poopCombat", _G.lastClearedWindow)
        end)
        
        it("should store message history", function()
            service:addCombatMessage("Message 1")
            service:addCombatMessage("Message 2")
            service:addCombatMessage("Message 3")
            
            local content = service.windows.combat.content
            assert.are.equal(3, #content)
            assert.are.equal("Message 1", content[1].message)
            assert.are.equal("Message 3", content[3].message)
        end)
    end)
    
    describe("Window configuration", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
        end)
        
        it("should resize windows", function()
            local result = service:resizeWindow("combat", 400, 200)
            
            assert.are.equal(true, result)
            assert.are.equal("poopCombat", _G.lastResizedWindow.name)
            assert.are.equal(400, _G.lastResizedWindow.width)
            assert.are.equal(200, _G.lastResizedWindow.height)
            assert.are.equal(400, service.windows.combat.config.width)
        end)
        
        it("should move windows", function()
            local result = service:moveWindow("ship", 100, 50)
            
            assert.are.equal(true, result)
            assert.are.equal("poopShip", _G.lastMovedWindow.name)
            assert.are.equal(100, _G.lastMovedWindow.x)
            assert.are.equal(50, _G.lastMovedWindow.y)
            assert.are.equal(100, service.windows.ship.config.x)
        end)
        
        it("should clear windows", function()
            service:addCombatMessage("Test message")
            
            local result = service:clearWindow("combat")
            
            assert.are.equal(true, result)
            assert.are.equal("poopCombat", _G.lastClearedWindow)
            assert.are.equal(0, service.windows.combat.lineCount)
            assert.are.equal(0, #service.windows.combat.content)
        end)
        
        it("should manage auto-hide settings", function()
            local result = service:setAutoHide("combat", false)
            
            assert.are.equal(true, result)
            assert.are.equal(false, service.windows.combat.config.autoHide)
        end)
    end)
    
    describe("Window information", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
        end)
        
        it("should get window information", function()
            service:addCombatMessage("Test message")
            service:showWindow("combat")
            
            local info = service:getWindowInfo("combat")
            
            assert.is_not_nil(info)
            assert.are.equal("poopCombat", info.name)
            assert.are.equal("Combat Status", info.title)
            assert.are.equal(true, info.visible)
            assert.are.equal(1, info.lineCount)
            assert.are.equal(1, info.messageCount)
        end)
        
        it("should get all windows information", function()
            service:addCombatMessage("Combat msg")
            service:addShipMessage("Ship msg")
            
            local allInfo = service:getAllWindowsInfo()
            
            assert.is_not_nil(allInfo.combat)
            assert.is_not_nil(allInfo.ship)
            assert.is_not_nil(allInfo.fishing)
            assert.is_not_nil(allInfo.alerts)
            
            assert.are.equal(1, allInfo.combat.messageCount)
            assert.are.equal(1, allInfo.ship.messageCount)
        end)
        
        it("should return nil for invalid window types", function()
            local info = service:getWindowInfo("invalid")
            assert.is_nil(info)
        end)
    end)
    
    describe("Auto-hide functionality", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
        end)
        
        it("should auto-hide inactive windows", function()
            -- Show and add message to combat window
            service:showWindow("combat")
            service:addCombatMessage("Old message")
            
            -- Manually set old timestamp
            service.windows.combat.lastUpdate = os.time() - 400 -- 400 seconds ago
            
            local hiddenWindows = service:autoHideInactiveWindows(300) -- 5 minute threshold
            
            assert.are.equal(1, #hiddenWindows)
            assert.are.equal("combat", hiddenWindows[1])
            assert.are.equal(false, service.windows.combat.config.visible)
        end)
        
        it("should not auto-hide windows with autoHide disabled", function()
            service:showWindow("ship")
            service:setAutoHide("ship", false)
            service:addShipMessage("Old message")
            
            -- Set old timestamp
            service.windows.ship.lastUpdate = os.time() - 400
            
            local hiddenWindows = service:autoHideInactiveWindows(300)
            
            -- Ship window should not be hidden (autoHide = false)
            assert.are.equal(0, #hiddenWindows)
            assert.are.equal(true, service.windows.ship.config.visible)
        end)
        
        it("should not auto-hide recently active windows", function()
            service:showWindow("fishing")
            service:addFishingMessage("Recent message")
            
            -- Recent timestamp (within threshold)
            service.windows.fishing.lastUpdate = os.time() - 100
            
            local hiddenWindows = service:autoHideInactiveWindows(300)
            
            -- Should not be hidden
            for _, windowType in ipairs(hiddenWindows) do
                assert.are_not.equal("fishing", windowType)
            end
        end)
    end)
    
    describe("Command integration", function()
        local service
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
            poopDeck.services.statusWindows = service
        end)
        
        it("should display windows information", function()
            local result = poopDeck.command.poopwindows()
            
            assert.are.equal(true, result)
            -- Should have displayed window information
        end)
        
        it("should toggle windows via commands", function()
            local result1 = poopDeck.command.poopcombat()
            assert.are.equal(true, result1)
            assert.are.equal(true, service.windows.combat.config.visible)
            
            local result2 = poopDeck.command.poopship()
            assert.are.equal(true, result2)
            assert.are.equal(true, service.windows.ship.config.visible)
            
            local result3 = poopDeck.command.poopfishing()
            assert.are.equal(true, result3)
            assert.are.equal(true, service.windows.fishing.config.visible)
            
            local result4 = poopDeck.command.poopalerts()
            assert.are.equal(true, result4)
            assert.are.equal(true, service.windows.alerts.config.visible)
        end)
        
        it("should handle service unavailability", function()
            poopDeck.services.statusWindows = nil
            
            local result = poopDeck.command.poopwindows()
            
            assert.are.equal(false, result)
        end)
    end)
    
    describe("Event system integration", function()
        local service
        local eventReceived = false
        local eventData = nil
        
        before_each(function()
            service = poopDeck.services.StatusWindowService:new()
            service:initializeWindows()
            eventReceived = false
            eventData = nil
        end)
        
        it("should emit window events", function()
            -- Subscribe to events
            service:on("windowShown", function(windowType)
                eventReceived = true
                eventData = windowType
            end)
            
            service:showWindow("combat")
            
            assert.are.equal(true, eventReceived)
            assert.are.equal("combat", eventData)
        end)
        
        it("should emit message events", function()
            service:on("messageAdded", function(windowType, message)
                eventReceived = true
                eventData = {windowType = windowType, message = message}
            end)
            
            service:addCombatMessage("Test message")
            
            assert.are.equal(true, eventReceived)
            assert.are.equal("combat", eventData.windowType)
            assert.are.equal("Test message", eventData.message)
        end)
    end)
end)