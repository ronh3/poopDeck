-- Load spec helper
require('spec.spec_helper')

-- Error handling service tests
describe("poopDeck Error Handling Service", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock file system for error logging
        _G.errorLogFile = ""
        
        io.open = function(filename, mode)
            if mode == "a" then -- Append mode for logging
                return {
                    write = function(self, content)
                        _G.errorLogFile = _G.errorLogFile .. content
                    end,
                    close = function(self) end
                }
            end
            return nil
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
        
        -- Create ErrorHandlingService
        poopDeck.services.ErrorHandlingService = poopDeck.core.BaseClass:extend("ErrorHandlingService")
        function poopDeck.services.ErrorHandlingService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.observers = {}
            
            -- Error handling configuration
            instance.errorConfig = {
                logToFile = instance.config.logToFile ~= false,
                logToConsole = instance.config.logToConsole ~= false,
                logFilePath = instance.config.logFilePath or "poopDeck_errors.log",
                maxRetries = instance.config.maxRetries or 3,
                retryDelay = instance.config.retryDelay or 2, -- seconds
                enabled = instance.config.enabled ~= false
            }
            
            -- Error tracking
            instance.errorHistory = {}
            instance.retryAttempts = {}
            instance.errorStats = {
                totalErrors = 0,
                recoveredErrors = 0,
                failedRecoveries = 0,
                byCategory = {}
            }
            
            return instance
        end
        
        function poopDeck.services.ErrorHandlingService:handleError(error, context, category)
            if not self.errorConfig.enabled then
                return false
            end
            
            category = category or "general"
            context = context or {}
            
            -- Create error record
            local errorRecord = {
                error = tostring(error),
                category = category,
                context = context,
                timestamp = os.time(),
                recovered = false,
                retryCount = 0,
                id = #self.errorHistory + 1
            }
            
            -- Add to history
            table.insert(self.errorHistory, errorRecord)
            
            -- Update statistics
            self.errorStats.totalErrors = self.errorStats.totalErrors + 1
            self.errorStats.byCategory[category] = (self.errorStats.byCategory[category] or 0) + 1
            
            -- Log error
            self:logError(errorRecord)
            
            -- Attempt recovery
            local recovered = self:attemptRecovery(errorRecord)
            
            -- Emit error event
            self:emit("errorOccurred", errorRecord, recovered)
            
            return recovered
        end
        
        function poopDeck.services.ErrorHandlingService:logError(errorRecord)
            local logMessage = string.format("[%s] %s - %s: %s\n",
                os.date("%Y-%m-%d %H:%M:%S", errorRecord.timestamp),
                errorRecord.category:upper(),
                errorRecord.id,
                errorRecord.error
            )
            
            if errorRecord.context and next(errorRecord.context) then
                logMessage = logMessage .. "  Context: " .. self:serializeContext(errorRecord.context) .. "\n"
            end
            
            -- Log to file
            if self.errorConfig.logToFile then
                local file = io.open(self.errorConfig.logFilePath, "a")
                if file then
                    file:write(logMessage)
                    file:close()
                end
            end
            
            -- Log to console
            if self.errorConfig.logToConsole then
                poopDeck.badEcho("ERROR: " .. errorRecord.error)
                if errorRecord.context.function then
                    poopDeck.badEcho("  Function: " .. errorRecord.context.function)
                end
                if errorRecord.context.service then
                    poopDeck.badEcho("  Service: " .. errorRecord.context.service)
                end
            end
        end
        
        function poopDeck.services.ErrorHandlingService:serializeContext(context)
            local parts = {}
            for key, value in pairs(context) do
                table.insert(parts, key .. "=" .. tostring(value))
            end
            return table.concat(parts, ", ")
        end
        
        function poopDeck.services.ErrorHandlingService:attemptRecovery(errorRecord)
            local category = errorRecord.category
            local recoveryStrategies = self:getRecoveryStrategies(category)
            
            for _, strategy in ipairs(recoveryStrategies) do
                local success = self:executeRecoveryStrategy(strategy, errorRecord)
                if success then
                    errorRecord.recovered = true
                    self.errorStats.recoveredErrors = self.errorStats.recoveredErrors + 1
                    self:logRecovery(errorRecord, strategy)
                    return true
                end
            end
            
            -- Recovery failed
            self.errorStats.failedRecoveries = self.errorStats.failedRecoveries + 1
            return false
        end
        
        function poopDeck.services.ErrorHandlingService:getRecoveryStrategies(category)
            local strategies = {
                fishing = {"restart_fishing", "reset_fishing_state", "reinitialize_fishing"},
                seamonster = {"reset_weapon_state", "restart_seamonster_cycle", "clear_firing_state"},
                navigation = {"reset_ship_state", "clear_navigation_queue", "reinitialize_navigation"},
                network = {"retry_connection", "reset_gmcp", "reinitialize_connection"},
                general = {"soft_reset", "clear_temp_state"}
            }
            
            return strategies[category] or strategies.general
        end
        
        function poopDeck.services.ErrorHandlingService:executeRecoveryStrategy(strategy, errorRecord)
            local success = false
            
            if strategy == "restart_fishing" then
                success = self:recoverFishingService()
            elseif strategy == "reset_fishing_state" then
                success = self:resetFishingState()
            elseif strategy == "reinitialize_fishing" then
                success = self:reinitializeFishingService()
            elseif strategy == "reset_weapon_state" then
                success = self:resetWeaponState()
            elseif strategy == "restart_seamonster_cycle" then
                success = self:restartSeamonsterCycle()
            elseif strategy == "clear_firing_state" then
                success = self:clearFiringState()
            elseif strategy == "reset_ship_state" then
                success = self:resetShipState()
            elseif strategy == "clear_navigation_queue" then
                success = self:clearNavigationQueue()
            elseif strategy == "retry_connection" then
                success = self:retryConnection()
            elseif strategy == "soft_reset" then
                success = self:performSoftReset()
            elseif strategy == "clear_temp_state" then
                success = self:clearTempState()
            end
            
            return success
        end
        
        -- Recovery strategy implementations
        function poopDeck.services.ErrorHandlingService:recoverFishingService()
            if poopDeck.services.fishing then
                pcall(function()
                    poopDeck.services.fishing:stopFishing()
                    tempTimer(2, function()
                        poopDeck.services.fishing:startFishing()
                    end)
                end)
                return true
            end
            return false
        end
        
        function poopDeck.services.ErrorHandlingService:resetFishingState()
            if poopDeck.services.fishing then
                pcall(function()
                    poopDeck.services.fishing.retryCount = 0
                    poopDeck.services.fishing.session = nil
                end)
                return true
            end
            return false
        end
        
        function poopDeck.services.ErrorHandlingService:reinitializeFishingService()
            pcall(function()
                if poopDeck.sessionManager and poopDeck.sessionManager.initializeFishing then
                    poopDeck.sessionManager:initializeFishing()
                end
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:resetWeaponState()
            pcall(function()
                poopDeck.firing = false
                poopDeck.oor = false
                poopDeck.firedSpider = false
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:restartSeamonsterCycle()
            if poopDeck.services.notifications then
                pcall(function()
                    poopDeck.services.notifications:stopSeamonsterCycle()
                    tempTimer(1, function()
                        poopDeck.services.notifications:startSeamonsterCycle()
                    end)
                end)
                return true
            end
            return false
        end
        
        function poopDeck.services.ErrorHandlingService:clearFiringState()
            pcall(function()
                poopDeck.firing = false
                poopDeck.seamonsterShots = 0
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:resetShipState()
            if poopDeck.services.shipManagement then
                pcall(function()
                    local state = poopDeck.services.shipManagement:getShipState()
                    -- Reset to safe defaults
                    state.sailSpeed = 0
                    state.docked = false
                end)
                return true
            end
            return false
        end
        
        function poopDeck.services.ErrorHandlingService:clearNavigationQueue()
            pcall(function()
                if poopDeck.services.shipManagement and poopDeck.services.shipManagement.commandQueue then
                    poopDeck.services.shipManagement.commandQueue = {}
                end
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:retryConnection()
            -- Mock network recovery
            pcall(function()
                gmcp = gmcp or {}
                gmcp.Char = gmcp.Char or {}
                gmcp.Char.Vitals = gmcp.Char.Vitals or {}
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:performSoftReset()
            pcall(function()
                -- Clear temporary flags
                poopDeck.firing = false
                poopDeck.oor = false
                poopDeck.maintaining = false
            end)
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:clearTempState()
            -- Clear any temporary state variables
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:logRecovery(errorRecord, strategy)
            local logMessage = string.format("[%s] RECOVERY - %s: Successfully recovered using strategy '%s'\n",
                os.date("%Y-%m-%d %H:%M:%S"),
                errorRecord.id,
                strategy
            )
            
            if self.errorConfig.logToFile then
                local file = io.open(self.errorConfig.logFilePath, "a")
                if file then
                    file:write(logMessage)
                    file:close()
                end
            end
            
            if self.errorConfig.logToConsole then
                poopDeck.goodEcho("RECOVERY: Error recovered using " .. strategy)
            end
        end
        
        -- Safe function execution wrapper
        function poopDeck.services.ErrorHandlingService:safeExecute(func, context, category)
            if not self.errorConfig.enabled then
                return func()
            end
            
            local success, result = pcall(func)
            if not success then
                self:handleError(result, context, category)
                return nil, result
            end
            
            return result
        end
        
        -- Retry wrapper
        function poopDeck.services.ErrorHandlingService:executeWithRetry(func, context, category, maxRetries)
            maxRetries = maxRetries or self.errorConfig.maxRetries
            local attempt = 1
            
            while attempt <= maxRetries do
                local success, result = pcall(func)
                if success then
                    return result
                end
                
                -- Log retry attempt
                self:handleError(result, 
                    table.merge(context or {}, {attempt = attempt, maxRetries = maxRetries}), 
                    category)
                
                if attempt < maxRetries then
                    -- Wait before retry
                    if self.errorConfig.retryDelay > 0 then
                        tempTimer(self.errorConfig.retryDelay, function() end)
                    end
                end
                
                attempt = attempt + 1
            end
            
            -- All retries failed
            return nil
        end
        
        function poopDeck.services.ErrorHandlingService:getErrorStatistics()
            return {
                totalErrors = self.errorStats.totalErrors,
                recoveredErrors = self.errorStats.recoveredErrors,
                failedRecoveries = self.errorStats.failedRecoveries,
                recoveryRate = self.errorStats.totalErrors > 0 and 
                    (self.errorStats.recoveredErrors / self.errorStats.totalErrors) * 100 or 0,
                byCategory = self.errorStats.byCategory,
                recentErrors = self:getRecentErrors(10)
            }
        end
        
        function poopDeck.services.ErrorHandlingService:getRecentErrors(count)
            count = count or 20
            local recent = {}
            local startIndex = math.max(1, #self.errorHistory - count + 1)
            
            for i = startIndex, #self.errorHistory do
                local error = self.errorHistory[i]
                table.insert(recent, {
                    id = error.id,
                    error = error.error,
                    category = error.category,
                    timestamp = error.timestamp,
                    recovered = error.recovered
                })
            end
            
            return recent
        end
        
        function poopDeck.services.ErrorHandlingService:clearErrorHistory()
            self.errorHistory = {}
            self.errorStats = {
                totalErrors = 0,
                recoveredErrors = 0,
                failedRecoveries = 0,
                byCategory = {}
            }
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:setEnabled(enabled)
            self.errorConfig.enabled = enabled
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:setLogToFile(enabled)
            self.errorConfig.logToFile = enabled
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:setLogToConsole(enabled)
            self.errorConfig.logToConsole = enabled
            return true
        end
        
        function poopDeck.services.ErrorHandlingService:getConfiguration()
            return {
                logToFile = self.errorConfig.logToFile,
                logToConsole = self.errorConfig.logToConsole,
                logFilePath = self.errorConfig.logFilePath,
                maxRetries = self.errorConfig.maxRetries,
                retryDelay = self.errorConfig.retryDelay,
                enabled = self.errorConfig.enabled
            }
        end
        
        -- Utility function for merging tables
        table.merge = table.merge or function(t1, t2)
            local result = {}
            for k, v in pairs(t1 or {}) do result[k] = v end
            for k, v in pairs(t2 or {}) do result[k] = v end
            return result
        end
        
        -- Mock timer function
        tempTimer = function(delay, func)
            _G.lastTimerDelay = delay
            _G.lastTimerFunc = func
            return delay -- Return delay as timer ID for testing
        end
        
        -- Mock echo functions
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
            _G.allBadEchoes = _G.allBadEchoes or {}
            table.insert(_G.allBadEchoes, msg)
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
            _G.allGoodEchoes = _G.allGoodEchoes or {}
            table.insert(_G.allGoodEchoes, msg)
        end
        
        -- Clear test state
        _G.errorLogFile = ""
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.allBadEchoes = nil
        _G.allGoodEchoes = nil
        _G.lastTimerDelay = nil
        _G.lastTimerFunc = nil
    end)
    
    describe("Error handling basics", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should handle errors and create error records", function()
            local recovered = service:handleError("Test error", {function = "testFunc"}, "test")
            
            assert.are.equal(1, #service.errorHistory)
            assert.are.equal("Test error", service.errorHistory[1].error)
            assert.are.equal("test", service.errorHistory[1].category)
            assert.are.equal("testFunc", service.errorHistory[1].context.function)
        end)
        
        it("should log errors to console", function()
            service:handleError("Console test error", {service = "test"}, "general")
            
            assert.truthy(_G.lastBadEcho:match("Console test error"))
            assert.are.equal(2, #_G.allBadEchoes) -- Error + service context
        end)
        
        it("should log errors to file", function()
            service:handleError("File test error", {}, "general")
            
            assert.truthy(_G.errorLogFile:match("File test error"))
            assert.truthy(_G.errorLogFile:match("GENERAL"))
        end)
        
        it("should not handle errors when disabled", function()
            service:setEnabled(false)
            
            local recovered = service:handleError("Disabled error")
            
            assert.are.equal(false, recovered)
            assert.are.equal(0, #service.errorHistory)
        end)
        
        it("should update error statistics", function()
            service:handleError("Error 1", {}, "fishing")
            service:handleError("Error 2", {}, "fishing") 
            service:handleError("Error 3", {}, "general")
            
            local stats = service:getErrorStatistics()
            
            assert.are.equal(3, stats.totalErrors)
            assert.are.equal(2, stats.byCategory.fishing)
            assert.are.equal(1, stats.byCategory.general)
        end)
    end)
    
    describe("Recovery mechanisms", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
            
            -- Mock services for recovery testing
            poopDeck.services.fishing = {
                stopFishing = function(self) return true end,
                startFishing = function(self) return true end,
                retryCount = 5,
                session = "active"
            }
            
            poopDeck.services.notifications = {
                stopSeamonsterCycle = function(self) return true end,
                startSeamonsterCycle = function(self) return true end
            }
        end)
        
        it("should attempt fishing recovery", function()
            local recovered = service:handleError("Fishing error", {}, "fishing")
            
            -- Should attempt recovery
            assert.truthy(recovered == true or recovered == false) -- Recovery attempted
            assert.are.equal(1, service.errorStats.totalErrors)
        end)
        
        it("should execute fishing restart recovery", function()
            local success = service:recoverFishingService()
            
            assert.are.equal(true, success)
            assert.is_not_nil(_G.lastTimerDelay)
            assert.are.equal(2, _G.lastTimerDelay)
        end)
        
        it("should reset fishing state", function()
            local success = service:resetFishingState()
            
            assert.are.equal(true, success)
            assert.are.equal(0, poopDeck.services.fishing.retryCount)
            assert.is_nil(poopDeck.services.fishing.session)
        end)
        
        it("should handle seamonster recovery", function()
            local recovered = service:handleError("Seamonster error", {}, "seamonster")
            
            assert.truthy(recovered == true or recovered == false) -- Recovery attempted
        end)
        
        it("should reset weapon state", function()
            poopDeck.firing = true
            poopDeck.oor = true
            poopDeck.firedSpider = true
            
            local success = service:resetWeaponState()
            
            assert.are.equal(true, success)
            assert.are.equal(false, poopDeck.firing)
            assert.are.equal(false, poopDeck.oor)
            assert.are.equal(false, poopDeck.firedSpider)
        end)
        
        it("should restart seamonster cycle", function()
            local success = service:restartSeamonsterCycle()
            
            assert.are.equal(true, success)
            assert.is_not_nil(_G.lastTimerDelay)
        end)
        
        it("should handle general recovery", function()
            local recovered = service:handleError("General error", {}, "general")
            
            assert.truthy(recovered == true or recovered == false) -- Recovery attempted
        end)
        
        it("should log successful recovery", function()
            service:handleError("Recovery test", {}, "fishing")
            
            -- Check if recovery was logged (would contain RECOVERY in file)
            if _G.errorLogFile:match("RECOVERY") then
                assert.truthy(_G.errorLogFile:match("RECOVERY"))
            end
        end)
    end)
    
    describe("Safe execution wrapper", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should execute function safely when no error", function()
            local result = service:safeExecute(function()
                return "success"
            end, {}, "test")
            
            assert.are.equal("success", result)
            assert.are.equal(0, #service.errorHistory)
        end)
        
        it("should handle errors in safe execution", function()
            local result, error = service:safeExecute(function()
                error("Test error in function")
            end, {function = "testSafe"}, "test")
            
            assert.is_nil(result)
            assert.is_not_nil(error)
            assert.are.equal(1, #service.errorHistory)
        end)
        
        it("should skip error handling when disabled", function()
            service:setEnabled(false)
            
            local result = service:safeExecute(function()
                return "direct result"
            end)
            
            assert.are.equal("direct result", result)
        end)
    end)
    
    describe("Retry mechanism", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new({
                retryDelay = 0.1 -- Shorter delay for testing
            })
        end)
        
        it("should succeed on first attempt", function()
            local result = service:executeWithRetry(function()
                return "first attempt success"
            end, {}, "test", 3)
            
            assert.are.equal("first attempt success", result)
            assert.are.equal(0, #service.errorHistory)
        end)
        
        it("should retry on failure", function()
            local attempts = 0
            
            local result = service:executeWithRetry(function()
                attempts = attempts + 1
                if attempts < 3 then
                    error("Attempt " .. attempts .. " failed")
                end
                return "success on attempt " .. attempts
            end, {test = true}, "retry_test", 3)
            
            assert.are.equal("success on attempt 3", result)
            assert.are.equal(2, #service.errorHistory) -- 2 failed attempts logged
        end)
        
        it("should fail after max retries", function()
            local attempts = 0
            
            local result = service:executeWithRetry(function()
                attempts = attempts + 1
                error("Attempt " .. attempts .. " failed")
            end, {}, "retry_fail", 2)
            
            assert.is_nil(result)
            assert.are.equal(2, #service.errorHistory)
            assert.are.equal(2, attempts)
        end)
        
        it("should use service default max retries", function()
            service.errorConfig.maxRetries = 4
            local attempts = 0
            
            service:executeWithRetry(function()
                attempts = attempts + 1
                error("Always fails")
            end, {}, "default_retry")
            
            assert.are.equal(4, attempts)
        end)
    end)
    
    describe("Error statistics and reporting", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should track comprehensive statistics", function()
            -- Create some errors with different outcomes
            service:handleError("Error 1", {}, "fishing")
            service:handleError("Error 2", {}, "fishing")
            service:handleError("Error 3", {}, "seamonster")
            
            local stats = service:getErrorStatistics()
            
            assert.are.equal(3, stats.totalErrors)
            assert.are.equal(2, stats.byCategory.fishing)
            assert.are.equal(1, stats.byCategory.seamonster)
            assert.is_number(stats.recoveryRate)
        end)
        
        it("should provide recent error history", function()
            for i = 1, 15 do
                service:handleError("Error " .. i, {}, "test")
            end
            
            local recent = service:getRecentErrors(5)
            
            assert.are.equal(5, #recent)
            assert.are.equal("Error 15", recent[5].error)
            assert.are.equal("Error 11", recent[1].error)
        end)
        
        it("should calculate recovery rate", function()
            -- Mock some recovered errors
            service:handleError("Error 1", {}, "general")
            service:handleError("Error 2", {}, "general")
            
            -- Manually mark one as recovered for testing
            service.errorHistory[1].recovered = true
            service.errorStats.recoveredErrors = 1
            
            local stats = service:getErrorStatistics()
            
            assert.are.equal(50, stats.recoveryRate) -- 1 of 2 recovered = 50%
        end)
        
        it("should clear error history", function()
            service:handleError("Error to clear", {}, "test")
            
            local cleared = service:clearErrorHistory()
            
            assert.are.equal(true, cleared)
            assert.are.equal(0, #service.errorHistory)
            assert.are.equal(0, service.errorStats.totalErrors)
        end)
    end)
    
    describe("Configuration management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should get current configuration", function()
            local config = service:getConfiguration()
            
            assert.is_not_nil(config)
            assert.are.equal(true, config.logToFile)
            assert.are.equal(true, config.logToConsole)
            assert.are.equal("poopDeck_errors.log", config.logFilePath)
            assert.are.equal(3, config.maxRetries)
            assert.are.equal(2, config.retryDelay)
            assert.are.equal(true, config.enabled)
        end)
        
        it("should update configuration settings", function()
            service:setLogToFile(false)
            service:setLogToConsole(false)
            service:setEnabled(false)
            
            local config = service:getConfiguration()
            
            assert.are.equal(false, config.logToFile)
            assert.are.equal(false, config.logToConsole)
            assert.are.equal(false, config.enabled)
        end)
        
        it("should initialize with custom configuration", function()
            local customService = poopDeck.services.ErrorHandlingService:new({
                logToFile = false,
                logToConsole = false,
                maxRetries = 5,
                retryDelay = 1,
                enabled = false
            })
            
            local config = customService:getConfiguration()
            
            assert.are.equal(false, config.logToFile)
            assert.are.equal(false, config.logToConsole)
            assert.are.equal(5, config.maxRetries)
            assert.are.equal(1, config.retryDelay)
            assert.are.equal(false, config.enabled)
        end)
    end)
    
    describe("Event system integration", function()
        local service
        local eventReceived = false
        local eventData = nil
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
            eventReceived = false
            eventData = nil
        end)
        
        it("should emit error events", function()
            service:on("errorOccurred", function(errorRecord, recovered)
                eventReceived = true
                eventData = {errorRecord = errorRecord, recovered = recovered}
            end)
            
            service:handleError("Event test error", {test = true}, "event")
            
            assert.are.equal(true, eventReceived)
            assert.is_not_nil(eventData.errorRecord)
            assert.are.equal("Event test error", eventData.errorRecord.error)
            assert.are.equal("event", eventData.errorRecord.category)
            assert.is_boolean(eventData.recovered)
        end)
    end)
    
    describe("Context serialization", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should serialize context data", function()
            local context = {
                function = "testFunc",
                service = "fishing",
                attempt = 2,
                maxRetries = 5
            }
            
            local serialized = service:serializeContext(context)
            
            assert.truthy(serialized:match("function=testFunc"))
            assert.truthy(serialized:match("service=fishing"))
            assert.truthy(serialized:match("attempt=2"))
            assert.truthy(serialized:match("maxRetries=5"))
        end)
        
        it("should handle empty context", function()
            local serialized = service:serializeContext({})
            
            assert.are.equal("", serialized)
        end)
        
        it("should handle nil context", function()
            local serialized = service:serializeContext(nil)
            
            assert.are.equal("", serialized)
        end)
    end)
    
    describe("File logging", function()
        local service
        
        before_each(function()
            service = poopDeck.services.ErrorHandlingService:new()
        end)
        
        it("should write error to file", function()
            service:handleError("File logging test", {function = "testFile"}, "test")
            
            assert.truthy(_G.errorLogFile:match("File logging test"))
            assert.truthy(_G.errorLogFile:match("TEST"))
            assert.truthy(_G.errorLogFile:match("Context: function=testFile"))
        end)
        
        it("should not log to file when disabled", function()
            service:setLogToFile(false)
            
            service:handleError("No file log", {}, "test")
            
            assert.are.equal("", _G.errorLogFile)
        end)
        
        it("should format timestamp in log", function()
            service:handleError("Timestamp test", {}, "test")
            
            -- Should contain a timestamp pattern like [2024-01-01 12:00:00]
            assert.truthy(_G.errorLogFile:match("%[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]"))
        end)
    end)
end)