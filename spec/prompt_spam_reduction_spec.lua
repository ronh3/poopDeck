-- Load spec helper
require('spec.spec_helper')

-- Prompt spam reduction tests
describe("poopDeck Prompt Spam Reduction", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock timer system
        _G.activeTimers = {}
        _G.timerIdCounter = 1
        _G.currentTime = os.time()
        
        tempTimer = function(delay, func)
            local timerId = _G.timerIdCounter
            _G.timerIdCounter = _G.timerIdCounter + 1
            
            _G.activeTimers[timerId] = {
                id = timerId,
                delay = delay,
                func = func,
                created = _G.currentTime,
                executed = false
            }
            
            return timerId
        end
        
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
        
        -- Mock echo functions
        echo = function(text)
            _G.lastEcho = text
            _G.allEchoes = _G.allEchoes or {}
            table.insert(_G.allEchoes, text)
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
        
        -- Create PromptService
        poopDeck.services.PromptService = poopDeck.core.BaseClass:extend("PromptService")
        function poopDeck.services.PromptService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.observers = {}
            
            -- Throttling configuration
            instance.throttleConfig = {
                enabled = instance.config.throttleEnabled ~= false,
                quietMode = instance.config.quietMode or false,
                throttleInterval = instance.config.throttleInterval or 2, -- seconds
                maxMessagesPerInterval = instance.config.maxMessagesPerInterval or 1,
                suppressDuplicates = instance.config.suppressDuplicates ~= false
            }
            
            -- Message tracking
            instance.messageHistory = {}
            instance.lastMessages = {}
            instance.suppressedCount = 0
            instance.currentInterval = {
                start = os.time(),
                messageCount = 0,
                messages = {}
            }
            
            -- Timer for flushing suppressed messages
            instance.flushTimer = nil
            
            return instance
        end
        
        function poopDeck.services.PromptService:processPromptMessage(message, messageType)
            if not self.throttleConfig.enabled then
                return self:displayMessage(message, messageType)
            end
            
            messageType = messageType or "normal"
            local currentTime = os.time()
            
            -- Check if we're in quiet mode
            if self.throttleConfig.quietMode then
                return self:handleQuietMode(message, messageType)
            end
            
            -- Check for duplicate suppression
            if self.throttleConfig.suppressDuplicates then
                if self:isDuplicateMessage(message) then
                    return self:handleDuplicateMessage(message, messageType)
                end
            end
            
            -- Check throttling interval
            if self:isWithinThrottleInterval(currentTime) then
                if self.currentInterval.messageCount >= self.throttleConfig.maxMessagesPerInterval then
                    return self:handleThrottledMessage(message, messageType)
                end
            else
                -- New interval started
                self:startNewInterval(currentTime)
            end
            
            -- Message can be displayed
            self.currentInterval.messageCount = self.currentInterval.messageCount + 1
            table.insert(self.currentInterval.messages, {message = message, type = messageType, time = currentTime})
            
            return self:displayMessage(message, messageType)
        end
        
        function poopDeck.services.PromptService:displayMessage(message, messageType)
            -- Record message
            self:recordMessage(message, messageType, "displayed")
            
            -- Display based on type
            if messageType == "ship_movement" then
                echo("🚢 " .. message)
            elseif messageType == "navigation" then
                echo("🧭 " .. message)
            elseif messageType == "system" then
                echo("⚙️ " .. message)
            else
                echo(message)
            end
            
            self:emit("messageDisplayed", message, messageType)
            return true
        end
        
        function poopDeck.services.PromptService:handleQuietMode(message, messageType)
            self:recordMessage(message, messageType, "suppressed_quiet")
            self.suppressedCount = self.suppressedCount + 1
            
            -- Still track for statistics but don't display
            self:emit("messageSuppressed", message, messageType, "quiet_mode")
            return false
        end
        
        function poopDeck.services.PromptService:isDuplicateMessage(message)
            local recentWindow = 5 -- seconds
            local currentTime = os.time()
            
            for i = #self.messageHistory, 1, -1 do
                local record = self.messageHistory[i]
                if currentTime - record.timestamp > recentWindow then
                    break
                end
                if record.message == message and record.status == "displayed" then
                    return true
                end
            end
            
            return false
        end
        
        function poopDeck.services.PromptService:handleDuplicateMessage(message, messageType)
            self:recordMessage(message, messageType, "suppressed_duplicate")
            self.suppressedCount = self.suppressedCount + 1
            self:emit("messageSuppressed", message, messageType, "duplicate")
            return false
        end
        
        function poopDeck.services.PromptService:isWithinThrottleInterval(currentTime)
            return currentTime - self.currentInterval.start < self.throttleConfig.throttleInterval
        end
        
        function poopDeck.services.PromptService:startNewInterval(currentTime)
            -- Flush any pending summary from previous interval
            if self.currentInterval.messageCount > 0 then
                self:flushIntervalSummary()
            end
            
            self.currentInterval = {
                start = currentTime,
                messageCount = 0,
                messages = {}
            }
        end
        
        function poopDeck.services.PromptService:handleThrottledMessage(message, messageType)
            self:recordMessage(message, messageType, "suppressed_throttle")
            self.suppressedCount = self.suppressedCount + 1
            
            -- Store for potential summary
            table.insert(self.currentInterval.messages, {
                message = message,
                type = messageType,
                time = os.time(),
                suppressed = true
            })
            
            -- Schedule flush if not already scheduled
            if not self.flushTimer then
                self.flushTimer = tempTimer(self.throttleConfig.throttleInterval + 1, function()
                    self:flushIntervalSummary()
                    self.flushTimer = nil
                end)
            end
            
            self:emit("messageSuppressed", message, messageType, "throttle")
            return false
        end
        
        function poopDeck.services.PromptService:flushIntervalSummary()
            local suppressedInInterval = 0
            local messageTypes = {}
            
            for _, msgData in ipairs(self.currentInterval.messages) do
                if msgData.suppressed then
                    suppressedInInterval = suppressedInInterval + 1
                    messageTypes[msgData.type] = (messageTypes[msgData.type] or 0) + 1
                end
            end
            
            if suppressedInInterval > 0 then
                local summary = string.format("📢 [%d messages suppressed", suppressedInInterval)
                if next(messageTypes) then
                    local typeList = {}
                    for msgType, count in pairs(messageTypes) do
                        table.insert(typeList, msgType .. ":" .. count)
                    end
                    summary = summary .. " (" .. table.concat(typeList, ", ") .. ")"
                end
                summary = summary .. "]"
                
                self:displayMessage(summary, "system")
            end
        end
        
        function poopDeck.services.PromptService:recordMessage(message, messageType, status)
            table.insert(self.messageHistory, {
                message = message,
                messageType = messageType,
                status = status, -- "displayed", "suppressed_quiet", "suppressed_duplicate", "suppressed_throttle"
                timestamp = os.time()
            })
            
            -- Keep history limited
            if #self.messageHistory > 1000 then
                table.remove(self.messageHistory, 1)
            end
        end
        
        function poopDeck.services.PromptService:setQuietMode(enabled)
            self.throttleConfig.quietMode = enabled
            self:emit("quietModeChanged", enabled)
            return true
        end
        
        function poopDeck.services.PromptService:setThrottleEnabled(enabled)
            self.throttleConfig.enabled = enabled
            if not enabled then
                -- Flush any pending messages
                self:flushIntervalSummary()
            end
            self:emit("throttleEnabledChanged", enabled)
            return true
        end
        
        function poopDeck.services.PromptService:setThrottleInterval(seconds)
            if seconds and seconds > 0 then
                self.throttleConfig.throttleInterval = seconds
                return true
            end
            return false
        end
        
        function poopDeck.services.PromptService:setMaxMessagesPerInterval(count)
            if count and count > 0 then
                self.throttleConfig.maxMessagesPerInterval = count
                return true
            end
            return false
        end
        
        function poopDeck.services.PromptService:setSuppressDuplicates(enabled)
            self.throttleConfig.suppressDuplicates = enabled
            return true
        end
        
        function poopDeck.services.PromptService:getStatistics()
            local totalMessages = #self.messageHistory
            local displayed = 0
            local suppressedQuiet = 0
            local suppressedDuplicate = 0
            local suppressedThrottle = 0
            
            for _, record in ipairs(self.messageHistory) do
                if record.status == "displayed" then
                    displayed = displayed + 1
                elseif record.status == "suppressed_quiet" then
                    suppressedQuiet = suppressedQuiet + 1
                elseif record.status == "suppressed_duplicate" then
                    suppressedDuplicate = suppressedDuplicate + 1
                elseif record.status == "suppressed_throttle" then
                    suppressedThrottle = suppressedThrottle + 1
                end
            end
            
            return {
                totalMessages = totalMessages,
                displayed = displayed,
                suppressed = {
                    total = totalMessages - displayed,
                    quiet = suppressedQuiet,
                    duplicate = suppressedDuplicate,
                    throttle = suppressedThrottle
                },
                config = self.throttleConfig
            }
        end
        
        function poopDeck.services.PromptService:clearHistory()
            self.messageHistory = {}
            self.suppressedCount = 0
            return true
        end
        
        function poopDeck.services.PromptService:getRecentMessages(count)
            count = count or 20
            local recent = {}
            local startIndex = math.max(1, #self.messageHistory - count + 1)
            
            for i = startIndex, #self.messageHistory do
                table.insert(recent, self.messageHistory[i])
            end
            
            return recent
        end
        
        function poopDeck.services.PromptService:getConfiguration()
            return {
                enabled = self.throttleConfig.enabled,
                quietMode = self.throttleConfig.quietMode,
                throttleInterval = self.throttleConfig.throttleInterval,
                maxMessagesPerInterval = self.throttleConfig.maxMessagesPerInterval,
                suppressDuplicates = self.throttleConfig.suppressDuplicates
            }
        end
        
        -- Create command handlers for prompt management
        poopDeck.command = poopDeck.command or {}
        
        poopDeck.command.poopquiet = function()
            local service = poopDeck.services.promptService
            if not service then
                poopDeck.badEcho("Prompt service not available")
                return false
            end
            
            local newState = not service.throttleConfig.quietMode
            service:setQuietMode(newState)
            
            local message = newState and "Quiet mode enabled - prompt spam suppressed" or "Quiet mode disabled - normal prompts restored"
            poopDeck.goodEcho(message)
            return true
        end
        
        poopDeck.command.poopprompts = function()
            local service = poopDeck.services.promptService
            if not service then
                poopDeck.badEcho("Prompt service not available")
                return false
            end
            
            local stats = service:getStatistics()
            local config = service:getConfiguration()
            
            poopDeck.goodEcho("=== Prompt Management Statistics ===")
            poopDeck.goodEcho(string.format("Total Messages: %d", stats.totalMessages))
            poopDeck.goodEcho(string.format("Displayed: %d", stats.displayed))
            poopDeck.goodEcho(string.format("Suppressed: %d (%.1f%%)", 
                stats.suppressed.total, 
                stats.totalMessages > 0 and (stats.suppressed.total / stats.totalMessages) * 100 or 0))
            poopDeck.goodEcho(string.format("  - Quiet Mode: %d", stats.suppressed.quiet))
            poopDeck.goodEcho(string.format("  - Duplicates: %d", stats.suppressed.duplicate))
            poopDeck.goodEcho(string.format("  - Throttled: %d", stats.suppressed.throttle))
            poopDeck.goodEcho("=== Configuration ===")
            poopDeck.goodEcho(string.format("Enabled: %s", config.enabled and "Yes" or "No"))
            poopDeck.goodEcho(string.format("Quiet Mode: %s", config.quietMode and "Yes" or "No"))
            poopDeck.goodEcho(string.format("Throttle Interval: %ds", config.throttleInterval))
            poopDeck.goodEcho(string.format("Max Messages/Interval: %d", config.maxMessagesPerInterval))
            poopDeck.goodEcho(string.format("Suppress Duplicates: %s", config.suppressDuplicates and "Yes" or "No"))
            
            return true
        end
        
        -- Mock echo functions
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
        end
        
        -- Clear test state
        _G.lastEcho = nil
        _G.allEchoes = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.activeTimers = {}
        _G.timerIdCounter = 1
    end)
    
    describe("Basic message processing", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
        end)
        
        it("should display messages when throttling disabled", function()
            service:setThrottleEnabled(false)
            
            local result = service:processPromptMessage("Test message")
            
            assert.are.equal(true, result)
            assert.are.equal("Test message", _G.lastEcho)
        end)
        
        it("should display messages within throttle limits", function()
            local result = service:processPromptMessage("First message")
            
            assert.are.equal(true, result)
            assert.are.equal("First message", _G.lastEcho)
        end)
        
        it("should display different message types correctly", function()
            service:processPromptMessage("Ship moved north", "ship_movement")
            assert.truthy(_G.lastEcho:match("🚢 Ship moved north"))
            
            service:processPromptMessage("Turn complete", "navigation")
            assert.truthy(_G.lastEcho:match("🧭 Turn complete"))
            
            service:processPromptMessage("System ready", "system")
            assert.truthy(_G.lastEcho:match("⚙️ System ready"))
        end)
    end)
    
    describe("Quiet mode functionality", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
        end)
        
        it("should suppress all messages in quiet mode", function()
            service:setQuietMode(true)
            
            local result = service:processPromptMessage("Quiet test message")
            
            assert.are.equal(false, result)
            assert.is_nil(_G.lastEcho)
            
            local stats = service:getStatistics()
            assert.are.equal(1, stats.suppressed.quiet)
        end)
        
        it("should resume normal display when quiet mode disabled", function()
            service:setQuietMode(true)
            service:processPromptMessage("Suppressed message")
            
            service:setQuietMode(false)
            local result = service:processPromptMessage("Normal message")
            
            assert.are.equal(true, result)
            assert.are.equal("Normal message", _G.lastEcho)
        end)
        
        it("should track quiet mode statistics", function()
            service:setQuietMode(true)
            
            service:processPromptMessage("Message 1")
            service:processPromptMessage("Message 2")
            service:processPromptMessage("Message 3")
            
            local stats = service:getStatistics()
            assert.are.equal(3, stats.suppressed.quiet)
            assert.are.equal(0, stats.displayed)
        end)
    end)
    
    describe("Duplicate message suppression", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
        end)
        
        it("should suppress duplicate messages", function()
            service:processPromptMessage("Duplicate test")
            local result = service:processPromptMessage("Duplicate test")
            
            assert.are.equal(false, result)
            
            local stats = service:getStatistics()
            assert.are.equal(1, stats.displayed)
            assert.are.equal(1, stats.suppressed.duplicate)
        end)
        
        it("should allow duplicates after time window", function()
            service:processPromptMessage("Time test message")
            
            -- Simulate time passage
            _G.currentTime = _G.currentTime + 10 -- Beyond 5-second window
            
            local result = service:processPromptMessage("Time test message")
            
            assert.are.equal(true, result)
            
            local stats = service:getStatistics()
            assert.are.equal(2, stats.displayed)
            assert.are.equal(0, stats.suppressed.duplicate)
        end)
        
        it("should handle duplicate suppression disabled", function()
            service:setSuppressDuplicates(false)
            
            service:processPromptMessage("No duplicate suppression")
            local result = service:processPromptMessage("No duplicate suppression")
            
            assert.are.equal(true, result)
            
            local stats = service:getStatistics()
            assert.are.equal(2, stats.displayed)
            assert.are.equal(0, stats.suppressed.duplicate)
        end)
    end)
    
    describe("Throttling functionality", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new({
                throttleInterval = 2,
                maxMessagesPerInterval = 1
            })
        end)
        
        it("should throttle messages exceeding limit", function()
            service:processPromptMessage("First message") -- Should display
            local result = service:processPromptMessage("Second message") -- Should throttle
            
            assert.are.equal(true, service:processPromptMessage("First message"))
            assert.are.equal(false, service:processPromptMessage("Second message"))
            
            local stats = service:getStatistics()
            assert.are.equal(1, stats.displayed)
            assert.are.equal(1, stats.suppressed.throttle)
        end)
        
        it("should start new interval after throttle period", function()
            service:processPromptMessage("Message 1") -- Should display
            service:processPromptMessage("Message 2") -- Should throttle
            
            -- Simulate time passage beyond throttle interval
            _G.currentTime = _G.currentTime + 3
            
            local result = service:processPromptMessage("Message 3") -- Should display (new interval)
            
            assert.are.equal(true, result)
            
            local stats = service:getStatistics()
            assert.are.equal(2, stats.displayed)
            assert.are.equal(1, stats.suppressed.throttle)
        end)
        
        it("should handle custom throttle settings", function()
            service:setThrottleInterval(1)
            service:setMaxMessagesPerInterval(3)
            
            -- Should allow 3 messages in 1-second interval
            assert.are.equal(true, service:processPromptMessage("Message 1"))
            assert.are.equal(true, service:processPromptMessage("Message 2"))
            assert.are.equal(true, service:processPromptMessage("Message 3"))
            assert.are.equal(false, service:processPromptMessage("Message 4"))
        end)
        
        it("should validate throttle configuration", function()
            assert.are.equal(false, service:setThrottleInterval(-1))
            assert.are.equal(false, service:setThrottleInterval(0))
            assert.are.equal(true, service:setThrottleInterval(5))
            
            assert.are.equal(false, service:setMaxMessagesPerInterval(0))
            assert.are.equal(false, service:setMaxMessagesPerInterval(-5))
            assert.are.equal(true, service:setMaxMessagesPerInterval(10))
        end)
    end)
    
    describe("Summary and flushing", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new({
                throttleInterval = 2,
                maxMessagesPerInterval = 1
            })
        end)
        
        it("should generate summary for suppressed messages", function()
            service:processPromptMessage("Message 1", "ship_movement") -- Display
            service:processPromptMessage("Message 2", "ship_movement") -- Suppress
            service:processPromptMessage("Message 3", "navigation") -- Suppress
            
            -- Execute flush timer
            local timerId = nil
            for id, timer in pairs(_G.activeTimers) do
                if not timer.executed then
                    timerId = id
                    break
                end
            end
            
            if timerId then
                _G.executeTimer(timerId)
            end
            
            -- Should have displayed summary
            assert.truthy(_G.lastEcho:match("messages suppressed"))
            assert.truthy(_G.lastEcho:match("ship_movement"))
            assert.truthy(_G.lastEcho:match("navigation"))
        end)
        
        it("should not generate summary when no messages suppressed", function()
            service:processPromptMessage("Only message")
            
            -- Start new interval
            _G.currentTime = _G.currentTime + 3
            service:processPromptMessage("New interval message")
            
            -- Should not mention suppression
            assert.falsy(_G.lastEcho and _G.lastEcho:match("suppressed"))
        end)
    end)
    
    describe("Statistics and reporting", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
        end)
        
        it("should track comprehensive statistics", function()
            service:processPromptMessage("Normal message")
            service:setQuietMode(true)
            service:processPromptMessage("Quiet message")
            service:setQuietMode(false)
            service:processPromptMessage("Duplicate message")
            service:processPromptMessage("Duplicate message") -- Duplicate
            
            local stats = service:getStatistics()
            
            assert.are.equal(4, stats.totalMessages)
            assert.are.equal(2, stats.displayed)
            assert.are.equal(2, stats.suppressed.total)
            assert.are.equal(1, stats.suppressed.quiet)
            assert.are.equal(1, stats.suppressed.duplicate)
        end)
        
        it("should provide recent message history", function()
            for i = 1, 10 do
                service:processPromptMessage("Message " .. i)
            end
            
            local recent = service:getRecentMessages(5)
            
            assert.are.equal(5, #recent)
            assert.are.equal("Message 10", recent[5].message)
            assert.are.equal("Message 6", recent[1].message)
        end)
        
        it("should clear history", function()
            service:processPromptMessage("Test message")
            
            local result = service:clearHistory()
            
            assert.are.equal(true, result)
            
            local stats = service:getStatistics()
            assert.are.equal(0, stats.totalMessages)
        end)
        
        it("should limit history size", function()
            -- Add more than the 1000 limit
            for i = 1, 1100 do
                service:processPromptMessage("Message " .. i, "test")
            end
            
            local stats = service:getStatistics()
            assert.truthy(stats.totalMessages <= 1000)
        end)
    end)
    
    describe("Command integration", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
            poopDeck.services.promptService = service
        end)
        
        it("should toggle quiet mode via command", function()
            local result = poopDeck.command.poopquiet()
            
            assert.are.equal(true, result)
            assert.are.equal(true, service.throttleConfig.quietMode)
            assert.truthy(_G.lastGoodEcho:match("Quiet mode enabled"))
            
            poopDeck.command.poopquiet()
            assert.are.equal(false, service.throttleConfig.quietMode)
            assert.truthy(_G.lastGoodEcho:match("Quiet mode disabled"))
        end)
        
        it("should display statistics via command", function()
            service:processPromptMessage("Test message")
            service:setQuietMode(true)
            service:processPromptMessage("Quiet message")
            
            local result = poopDeck.command.poopprompts()
            
            assert.are.equal(true, result)
            assert.truthy(_G.lastGoodEcho:match("Prompt Management Statistics"))
        end)
        
        it("should handle service unavailability", function()
            poopDeck.services.promptService = nil
            
            local result = poopDeck.command.poopquiet()
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Prompt service not available"))
        end)
    end)
    
    describe("Event system integration", function()
        local service
        local eventReceived = false
        local eventData = nil
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
            eventReceived = false
            eventData = nil
        end)
        
        it("should emit message events", function()
            service:on("messageDisplayed", function(message, messageType)
                eventReceived = true
                eventData = {message = message, messageType = messageType}
            end)
            
            service:processPromptMessage("Event test", "navigation")
            
            assert.are.equal(true, eventReceived)
            assert.are.equal("Event test", eventData.message)
            assert.are.equal("navigation", eventData.messageType)
        end)
        
        it("should emit suppression events", function()
            service:on("messageSuppressed", function(message, messageType, reason)
                eventReceived = true
                eventData = {message = message, messageType = messageType, reason = reason}
            end)
            
            service:setQuietMode(true)
            service:processPromptMessage("Suppressed message", "test")
            
            assert.are.equal(true, eventReceived)
            assert.are.equal("Suppressed message", eventData.message)
            assert.are.equal("quiet_mode", eventData.reason)
        end)
        
        it("should emit configuration change events", function()
            service:on("quietModeChanged", function(enabled)
                eventReceived = true
                eventData = enabled
            end)
            
            service:setQuietMode(true)
            
            assert.are.equal(true, eventReceived)
            assert.are.equal(true, eventData)
        end)
    end)
    
    describe("Configuration management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.PromptService:new()
        end)
        
        it("should get current configuration", function()
            local config = service:getConfiguration()
            
            assert.is_not_nil(config)
            assert.are.equal(true, config.enabled)
            assert.are.equal(false, config.quietMode)
            assert.are.equal(2, config.throttleInterval)
            assert.are.equal(1, config.maxMessagesPerInterval)
            assert.are.equal(true, config.suppressDuplicates)
        end)
        
        it("should initialize with custom configuration", function()
            local customService = poopDeck.services.PromptService:new({
                throttleEnabled = false,
                quietMode = true,
                throttleInterval = 5,
                maxMessagesPerInterval = 3,
                suppressDuplicates = false
            })
            
            local config = customService:getConfiguration()
            
            assert.are.equal(false, config.enabled)
            assert.are.equal(true, config.quietMode)
            assert.are.equal(5, config.throttleInterval)
            assert.are.equal(3, config.maxMessagesPerInterval)
            assert.are.equal(false, config.suppressDuplicates)
        end)
    end)
end)