-- Load spec helper
require('spec.spec_helper')

-- Notification system tests
describe("poopDeck Notification System", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock timer system
        _G.activeTimers = {}
        _G.timerIdCounter = 1
        _G.currentTime = os.time()
        
        tempTimer = function(delay, func, name)
            local timerId = _G.timerIdCounter
            _G.timerIdCounter = _G.timerIdCounter + 1
            
            _G.activeTimers[timerId] = {
                id = timerId,
                delay = delay,
                func = func,
                name = name or "anonymous",
                created = _G.currentTime,
                executed = false
            }
            
            _G.lastTimerCreated = {
                id = timerId,
                delay = delay,
                name = name
            }
            
            return timerId
        end
        
        killTimer = function(timerId)
            if _G.activeTimers[timerId] then
                _G.activeTimers[timerId] = nil
                _G.lastKilledTimer = timerId
                return true
            end
            return false
        end
        
        -- Function to simulate timer execution (for testing)
        _G.executeTimer = function(timerId)
            local timer = _G.activeTimers[timerId]
            if timer and not timer.executed then
                timer.executed = true
                if timer.func then
                    timer.func()
                end
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
        
        -- Create NotificationService
        poopDeck.services.NotificationService = poopDeck.core.BaseClass:extend("NotificationService")
        function poopDeck.services.NotificationService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.observers = {}
            
            -- Seamonster notification configuration
            instance.seamonsterConfig = {
                spawnCycle = 1200, -- 20 minutes
                fiveMinuteWarning = instance.config.fiveMinuteWarning ~= false,
                oneMinuteWarning = instance.config.oneMinuteWarning ~= false,
                timeToFishWarning = instance.config.timeToFishWarning ~= false,
                enabled = instance.config.enabled ~= false
            }
            
            -- Active timers tracking
            instance.activeTimers = {
                fiveMinute = nil,
                oneMinute = nil,
                timeToFish = nil
            }
            
            -- Notification history
            instance.notificationHistory = {}
            
            return instance
        end
        
        function poopDeck.services.NotificationService:startSeamonsterCycle()
            if not self.seamonsterConfig.enabled then
                return false, "Notifications are disabled"
            end
            
            self:clearAllTimers()
            
            local success = true
            local messages = {}
            
            -- 15 minute mark (5 minutes before spawn) - 900 seconds
            if self.seamonsterConfig.fiveMinuteWarning then
                self.activeTimers.fiveMinute = tempTimer(900, function()
                    self:sendNotification("seamonster_5min", "⏰ 5 minutes until seamonster spawn!", "yellow")
                end, "seamonster_5min_warning")
                
                if not self.activeTimers.fiveMinute then
                    success = false
                    table.insert(messages, "Failed to create 5-minute timer")
                end
            end
            
            -- 19 minute mark (1 minute before spawn) - 1140 seconds
            if self.seamonsterConfig.oneMinuteWarning then
                self.activeTimers.oneMinute = tempTimer(1140, function()
                    self:sendNotification("seamonster_1min", "⚡ 1 minute until seamonster spawn! Get ready!", "orange")
                end, "seamonster_1min_warning")
                
                if not self.activeTimers.oneMinute then
                    success = false
                    table.insert(messages, "Failed to create 1-minute timer")
                end
            end
            
            -- 20 minute mark (time to fish) - 1200 seconds
            if self.seamonsterConfig.timeToFishWarning then
                self.activeTimers.timeToFish = tempTimer(1200, function()
                    self:sendNotification("seamonster_spawn", "🐉 Seamonster spawning now! Time to fish!", "red")
                    -- Auto-restart cycle if enabled
                    if self.seamonsterConfig.enabled then
                        self:startSeamonsterCycle()
                    end
                end, "seamonster_spawn_alert")
                
                if not self.activeTimers.timeToFish then
                    success = false
                    table.insert(messages, "Failed to create spawn timer")
                end
            end
            
            local resultMessage = success and "Seamonster notification cycle started" or table.concat(messages, ", ")
            
            self:recordEvent("cycle_started", {
                success = success,
                timers_created = {
                    fiveMinute = self.activeTimers.fiveMinute,
                    oneMinute = self.activeTimers.oneMinute,
                    timeToFish = self.activeTimers.timeToFish
                }
            })
            
            return success, resultMessage
        end
        
        function poopDeck.services.NotificationService:stopSeamonsterCycle()
            local killedCount = self:clearAllTimers()
            
            self:recordEvent("cycle_stopped", {
                timers_killed = killedCount
            })
            
            return true, "Seamonster notification cycle stopped (" .. killedCount .. " timers cleared)"
        end
        
        function poopDeck.services.NotificationService:clearAllTimers()
            local killedCount = 0
            
            for timerType, timerId in pairs(self.activeTimers) do
                if timerId then
                    if killTimer(timerId) then
                        killedCount = killedCount + 1
                    end
                    self.activeTimers[timerType] = nil
                end
            end
            
            return killedCount
        end
        
        function poopDeck.services.NotificationService:sendNotification(notificationType, message, color)
            color = color or "white"
            
            -- Send to status windows if available
            local statusService = poopDeck.services.statusWindows
            if statusService then
                statusService:addAlertMessage(message)
            end
            
            -- Send to main output
            if color == "yellow" then
                poopDeck.smallGoodEcho(message)
            elseif color == "orange" then
                poopDeck.badEcho(message)
            elseif color == "red" then
                poopDeck.badEcho(message)
            else
                poopDeck.goodEcho(message)
            end
            
            -- Record notification
            self:recordEvent("notification_sent", {
                type = notificationType,
                message = message,
                color = color,
                timestamp = os.time()
            })
            
            -- Emit event
            self:emit("notificationSent", notificationType, message, color)
            
            return true
        end
        
        function poopDeck.services.NotificationService:recordEvent(eventType, data)
            table.insert(self.notificationHistory, {
                eventType = eventType,
                data = data,
                timestamp = os.time()
            })
            
            -- Keep history limited
            if #self.notificationHistory > 100 then
                table.remove(self.notificationHistory, 1)
            end
        end
        
        function poopDeck.services.NotificationService:getActiveTimers()
            local timerInfo = {}
            
            for timerType, timerId in pairs(self.activeTimers) do
                if timerId and _G.activeTimers[timerId] then
                    local timer = _G.activeTimers[timerId]
                    timerInfo[timerType] = {
                        id = timerId,
                        delay = timer.delay,
                        name = timer.name,
                        created = timer.created,
                        executed = timer.executed,
                        timeRemaining = timer.created + timer.delay - _G.currentTime
                    }
                end
            end
            
            return timerInfo
        end
        
        function poopDeck.services.NotificationService:getNotificationHistory()
            return self.notificationHistory
        end
        
        function poopDeck.services.NotificationService:setEnabled(enabled)
            self.seamonsterConfig.enabled = enabled
            if not enabled then
                self:stopSeamonsterCycle()
            end
            return true
        end
        
        function poopDeck.services.NotificationService:setWarningEnabled(warningType, enabled)
            if warningType == "5min" or warningType == "fiveMinute" then
                self.seamonsterConfig.fiveMinuteWarning = enabled
            elseif warningType == "1min" or warningType == "oneMinute" then
                self.seamonsterConfig.oneMinuteWarning = enabled
            elseif warningType == "spawn" or warningType == "timeToFish" then
                self.seamonsterConfig.timeToFishWarning = enabled
            else
                return false, "Invalid warning type"
            end
            return true, "Warning setting updated"
        end
        
        function poopDeck.services.NotificationService:getConfiguration()
            return {
                spawnCycle = self.seamonsterConfig.spawnCycle,
                fiveMinuteWarning = self.seamonsterConfig.fiveMinuteWarning,
                oneMinuteWarning = self.seamonsterConfig.oneMinuteWarning,
                timeToFishWarning = self.seamonsterConfig.timeToFishWarning,
                enabled = self.seamonsterConfig.enabled
            }
        end
        
        -- Create custom notification types
        function poopDeck.services.NotificationService:sendCustomNotification(message, delaySeconds, color)
            if delaySeconds and delaySeconds > 0 then
                tempTimer(delaySeconds, function()
                    self:sendNotification("custom", message, color)
                end, "custom_notification")
                return true, "Custom notification scheduled"
            else
                return self:sendNotification("custom", message, color)
            end
        end
        
        -- Mock echo functions
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
            _G.allNotifications = _G.allNotifications or {}
            table.insert(_G.allNotifications, {type = "bad", message = msg})
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
            _G.allNotifications = _G.allNotifications or {}
            table.insert(_G.allNotifications, {type = "good", message = msg})
        end
        
        poopDeck.smallGoodEcho = function(msg)
            _G.lastSmallGoodEcho = msg
            _G.allNotifications = _G.allNotifications or {}
            table.insert(_G.allNotifications, {type = "smallGood", message = msg})
        end
        
        -- Clear test state
        _G.activeTimers = {}
        _G.timerIdCounter = 1
        _G.lastTimerCreated = nil
        _G.lastKilledTimer = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.lastSmallGoodEcho = nil
        _G.allNotifications = nil
    end)
    
    describe("Seamonster notification cycle", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should start complete notification cycle", function()
            local success, message = service:startSeamonsterCycle()
            
            assert.are.equal(true, success)
            assert.are.equal("Seamonster notification cycle started", message)
            
            -- Verify all timers were created
            assert.is_not_nil(service.activeTimers.fiveMinute)
            assert.is_not_nil(service.activeTimers.oneMinute)
            assert.is_not_nil(service.activeTimers.timeToFish)
            
            -- Verify timer delays
            assert.are.equal(900, _G.activeTimers[service.activeTimers.fiveMinute].delay)
            assert.are.equal(1140, _G.activeTimers[service.activeTimers.oneMinute].delay)
            assert.are.equal(1200, _G.activeTimers[service.activeTimers.timeToFish].delay)
        end)
        
        it("should create timers with correct names", function()
            service:startSeamonsterCycle()
            
            assert.are.equal("seamonster_5min_warning", _G.activeTimers[service.activeTimers.fiveMinute].name)
            assert.are.equal("seamonster_1min_warning", _G.activeTimers[service.activeTimers.oneMinute].name)
            assert.are.equal("seamonster_spawn_alert", _G.activeTimers[service.activeTimers.timeToFish].name)
        end)
        
        it("should not start cycle when disabled", function()
            service:setEnabled(false)
            
            local success, message = service:startSeamonsterCycle()
            
            assert.are.equal(false, success)
            assert.are.equal("Notifications are disabled", message)
        end)
        
        it("should stop notification cycle", function()
            service:startSeamonsterCycle()
            
            local success, message = service:stopSeamonsterCycle()
            
            assert.are.equal(true, success)
            assert.truthy(message:match("3 timers cleared"))
            
            -- Verify timers were cleared
            assert.is_nil(service.activeTimers.fiveMinute)
            assert.is_nil(service.activeTimers.oneMinute)
            assert.is_nil(service.activeTimers.timeToFish)
        end)
        
        it("should clear existing timers when starting new cycle", function()
            service:startSeamonsterCycle()
            local firstCycleTimers = {
                fiveMinute = service.activeTimers.fiveMinute,
                oneMinute = service.activeTimers.oneMinute,
                timeToFish = service.activeTimers.timeToFish
            }
            
            service:startSeamonsterCycle()
            
            -- New timers should be different
            assert.are_not.equal(firstCycleTimers.fiveMinute, service.activeTimers.fiveMinute)
            assert.are_not.equal(firstCycleTimers.oneMinute, service.activeTimers.oneMinute)
            assert.are_not.equal(firstCycleTimers.timeToFish, service.activeTimers.timeToFish)
        end)
    end)
    
    describe("Individual warning configurations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should create only enabled warnings", function()
            -- Disable 5-minute warning
            service:setWarningEnabled("5min", false)
            service:startSeamonsterCycle()
            
            assert.is_nil(service.activeTimers.fiveMinute)
            assert.is_not_nil(service.activeTimers.oneMinute)
            assert.is_not_nil(service.activeTimers.timeToFish)
        end)
        
        it("should create service with selective warnings from config", function()
            local customService = poopDeck.services.NotificationService:new({
                fiveMinuteWarning = false,
                oneMinuteWarning = true,
                timeToFishWarning = true
            })
            
            customService:startSeamonsterCycle()
            
            assert.is_nil(customService.activeTimers.fiveMinute)
            assert.is_not_nil(customService.activeTimers.oneMinute)
            assert.is_not_nil(customService.activeTimers.timeToFish)
        end)
        
        it("should validate warning type names", function()
            local success1, message1 = service:setWarningEnabled("invalid", true)
            assert.are.equal(false, success1)
            assert.truthy(message1:match("Invalid warning type"))
            
            local success2, message2 = service:setWarningEnabled("1min", false)
            assert.are.equal(true, success2)
            
            local success3, message3 = service:setWarningEnabled("spawn", true)
            assert.are.equal(true, success3)
        end)
    end)
    
    describe("Notification execution", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should execute 5-minute warning", function()
            service:startSeamonsterCycle()
            
            -- Execute the 5-minute timer
            _G.executeTimer(service.activeTimers.fiveMinute)
            
            assert.truthy(_G.lastSmallGoodEcho:match("5 minutes until seamonster"))
        end)
        
        it("should execute 1-minute warning", function()
            service:startSeamonsterCycle()
            
            -- Execute the 1-minute timer
            _G.executeTimer(service.activeTimers.oneMinute)
            
            assert.truthy(_G.lastBadEcho:match("1 minute until seamonster"))
        end)
        
        it("should execute spawn notification", function()
            service:startSeamonsterCycle()
            
            -- Execute the spawn timer
            _G.executeTimer(service.activeTimers.timeToFish)
            
            assert.truthy(_G.lastBadEcho:match("Seamonster spawning now"))
        end)
        
        it("should auto-restart cycle after spawn notification", function()
            service:startSeamonsterCycle()
            local originalSpawnTimer = service.activeTimers.timeToFish
            
            -- Execute the spawn timer
            _G.executeTimer(originalSpawnTimer)
            
            -- Should have new timers (cycle restarted)
            assert.is_not_nil(service.activeTimers.fiveMinute)
            assert.is_not_nil(service.activeTimers.oneMinute)
            assert.is_not_nil(service.activeTimers.timeToFish)
            assert.are_not.equal(originalSpawnTimer, service.activeTimers.timeToFish)
        end)
        
        it("should not auto-restart when disabled", function()
            service:startSeamonsterCycle()
            local originalSpawnTimer = service.activeTimers.timeToFish
            
            -- Disable before spawn
            service:setEnabled(false)
            
            -- Execute the spawn timer
            _G.executeTimer(originalSpawnTimer)
            
            -- Should not have new timers
            assert.is_nil(service.activeTimers.fiveMinute)
            assert.is_nil(service.activeTimers.oneMinute)
            assert.is_nil(service.activeTimers.timeToFish)
        end)
    end)
    
    describe("Custom notifications", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should send immediate custom notifications", function()
            local success = service:sendCustomNotification("Custom message", nil, "green")
            
            assert.are.equal(true, success)
            assert.truthy(_G.lastGoodEcho:match("Custom message"))
        end)
        
        it("should schedule delayed custom notifications", function()
            local success, message = service:sendCustomNotification("Delayed message", 30, "blue")
            
            assert.are.equal(true, success)
            assert.are.equal("Custom notification scheduled", message)
            assert.are.equal(30, _G.lastTimerCreated.delay)
        end)
        
        it("should handle different color types", function()
            service:sendCustomNotification("Yellow message", nil, "yellow")
            assert.truthy(_G.lastSmallGoodEcho:match("Yellow message"))
            
            service:sendCustomNotification("Orange message", nil, "orange") 
            assert.truthy(_G.lastBadEcho:match("Orange message"))
            
            service:sendCustomNotification("Red message", nil, "red")
            assert.truthy(_G.lastBadEcho:match("Red message"))
        end)
    end)
    
    describe("Timer management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should track active timers", function()
            service:startSeamonsterCycle()
            
            local timerInfo = service:getActiveTimers()
            
            assert.is_not_nil(timerInfo.fiveMinute)
            assert.is_not_nil(timerInfo.oneMinute) 
            assert.is_not_nil(timerInfo.timeToFish)
            
            assert.are.equal(900, timerInfo.fiveMinute.delay)
            assert.are.equal(1140, timerInfo.oneMinute.delay)
            assert.are.equal(1200, timerInfo.timeToFish.delay)
        end)
        
        it("should calculate time remaining", function()
            service:startSeamonsterCycle()
            
            -- Advance time by 100 seconds
            _G.currentTime = _G.currentTime + 100
            
            local timerInfo = service:getActiveTimers()
            
            assert.are.equal(800, timerInfo.fiveMinute.timeRemaining) -- 900 - 100
            assert.are.equal(1040, timerInfo.oneMinute.timeRemaining) -- 1140 - 100
            assert.are.equal(1100, timerInfo.timeToFish.timeRemaining) -- 1200 - 100
        end)
        
        it("should handle executed timers", function()
            service:startSeamonsterCycle()
            
            -- Execute 5-minute timer
            _G.executeTimer(service.activeTimers.fiveMinute)
            
            local timerInfo = service:getActiveTimers()
            
            assert.are.equal(true, timerInfo.fiveMinute.executed)
        end)
    end)
    
    describe("Event history and tracking", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should record notification events", function()
            service:startSeamonsterCycle()
            service:sendNotification("test", "Test message", "white")
            
            local history = service:getNotificationHistory()
            
            assert.truthy(#history >= 2) -- cycle start + notification
            
            -- Find notification event
            local notificationEvent = nil
            for _, event in ipairs(history) do
                if event.eventType == "notification_sent" then
                    notificationEvent = event
                    break
                end
            end
            
            assert.is_not_nil(notificationEvent)
            assert.are.equal("test", notificationEvent.data.type)
            assert.are.equal("Test message", notificationEvent.data.message)
        end)
        
        it("should record cycle events", function()
            service:startSeamonsterCycle()
            service:stopSeamonsterCycle()
            
            local history = service:getNotificationHistory()
            
            -- Should have cycle start and stop events
            local startEvent = nil
            local stopEvent = nil
            
            for _, event in ipairs(history) do
                if event.eventType == "cycle_started" then
                    startEvent = event
                elseif event.eventType == "cycle_stopped" then
                    stopEvent = event
                end
            end
            
            assert.is_not_nil(startEvent)
            assert.is_not_nil(stopEvent)
            assert.are.equal(true, startEvent.data.success)
            assert.are.equal(3, stopEvent.data.timers_killed)
        end)
        
        it("should limit history size", function()
            -- Add many events
            for i = 1, 150 do
                service:sendNotification("test" .. i, "Message " .. i, "white")
            end
            
            local history = service:getNotificationHistory()
            
            -- Should be limited to 100 entries
            assert.truthy(#history <= 100)
        end)
    end)
    
    describe("Event system integration", function()
        local service
        local eventReceived = false
        local eventData = nil
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
            eventReceived = false
            eventData = nil
        end)
        
        it("should emit notification events", function()
            service:on("notificationSent", function(notificationType, message, color)
                eventReceived = true
                eventData = {
                    type = notificationType,
                    message = message,
                    color = color
                }
            end)
            
            service:sendNotification("test", "Test event message", "blue")
            
            assert.are.equal(true, eventReceived)
            assert.are.equal("test", eventData.type)
            assert.are.equal("Test event message", eventData.message)
            assert.are.equal("blue", eventData.color)
        end)
    end)
    
    describe("Configuration management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
        end)
        
        it("should get current configuration", function()
            local config = service:getConfiguration()
            
            assert.is_not_nil(config)
            assert.are.equal(1200, config.spawnCycle)
            assert.are.equal(true, config.fiveMinuteWarning)
            assert.are.equal(true, config.oneMinuteWarning)
            assert.are.equal(true, config.timeToFishWarning)
            assert.are.equal(true, config.enabled)
        end)
        
        it("should enable and disable service", function()
            service:setEnabled(false)
            
            local config = service:getConfiguration()
            assert.are.equal(false, config.enabled)
            
            service:setEnabled(true)
            
            config = service:getConfiguration()
            assert.are.equal(true, config.enabled)
        end)
        
        it("should update individual warning settings", function()
            service:setWarningEnabled("5min", false)
            service:setWarningEnabled("1min", false)
            
            local config = service:getConfiguration()
            
            assert.are.equal(false, config.fiveMinuteWarning)
            assert.are.equal(false, config.oneMinuteWarning)
            assert.are.equal(true, config.timeToFishWarning) -- Should remain unchanged
        end)
    end)
    
    describe("Integration with status windows", function()
        local service
        local mockStatusService
        
        before_each(function()
            service = poopDeck.services.NotificationService:new()
            
            -- Mock status window service
            mockStatusService = {
                addAlertMessage = function(self, message)
                    _G.lastStatusWindowMessage = message
                    return true
                end
            }
            poopDeck.services.statusWindows = mockStatusService
        end)
        
        it("should send notifications to status windows", function()
            service:sendNotification("test", "Status window test", "green")
            
            assert.are.equal("Status window test", _G.lastStatusWindowMessage)
        end)
        
        it("should handle missing status window service gracefully", function()
            poopDeck.services.statusWindows = nil
            
            -- Should not crash
            assert.has_no.errors(function()
                service:sendNotification("test", "No status window", "red")
            end)
            
            -- Should still send to main output
            assert.truthy(_G.lastBadEcho:match("No status window"))
        end)
    end)
end)