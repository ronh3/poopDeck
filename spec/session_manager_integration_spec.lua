-- Load spec helper
require('spec.spec_helper')

-- Session manager integration tests
describe("poopDeck Session Manager Integration", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.core = poopDeck.core or {}
        poopDeck.services = poopDeck.services or {}
        
        -- Mock BaseClass (simplified version)
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
                if self.observers[event] then
                    for _, callback in ipairs(self.observers[event]) do
                        pcall(callback, ...)
                    end
                end
            end
        }
        
        -- Create mock services for integration testing
        local MockFishingService = {
            new = function(self, config)
                local instance = setmetatable({}, {__index = self})
                instance.enabled = true
                instance.config = config or {}
                instance.session = nil
                return instance
            end,
            startFishing = function(self) return true, "Fishing started" end,
            stopFishing = function(self) return true, "Fishing stopped" end,
            setEnabled = function(self, enabled) self.enabled = enabled end,
            getStatistics = function(self) return {totalCasts = 10, totalCatches = 5} end
        }
        
        local MockNotificationService = {
            new = function(self, config)
                local instance = setmetatable({}, {__index = self})
                instance.enabled = true
                instance.config = config or {}
                return instance
            end,
            startSeamonsterCycle = function(self) return true, "Cycle started" end,
            stopSeamonsterCycle = function(self) return true, "Cycle stopped" end,
            setEnabled = function(self, enabled) self.enabled = enabled end
        }
        
        local MockStatusWindowService = {
            new = function(self, config)
                local instance = setmetatable({}, {__index = self})
                instance.windows = {}
                return instance
            end,
            initializeWindows = function(self) return true, "Windows initialized" end,
            showWindow = function(self, windowType) return true end,
            hideWindow = function(self, windowType) return true end,
            addMessage = function(self, windowType, message) return true end
        }
        
        local MockPromptService = {
            new = function(self, config)
                local instance = setmetatable({}, {__index = self})
                instance.enabled = true
                instance.config = config or {}
                return instance
            end,
            processPromptMessage = function(self, message, messageType) return true end,
            setQuietMode = function(self, enabled) self.quietMode = enabled end,
            getStatistics = function(self) return {totalMessages = 100, displayed = 80} end
        }
        
        local MockErrorHandlingService = {
            new = function(self, config)
                local instance = setmetatable({}, {__index = self})
                instance.enabled = true
                instance.errorHistory = {}
                return instance
            end,
            handleError = function(self, error, context, category)
                table.insert(self.errorHistory, {error = error, context = context, category = category})
                return true
            end,
            safeExecute = function(self, func, context, category)
                local success, result = pcall(func)
                if not success then
                    self:handleError(result, context, category)
                    return nil, result
                end
                return result
            end
        }
        
        local MockShipManagementService = {
            new = function(self)
                local instance = setmetatable({}, {__index = self})
                instance.state = {docked = false, sailSpeed = 0}
                return instance
            end,
            dock = function(self, direction) return true, "Docked" end,
            setSailSpeed = function(self, speed) 
                self.state.sailSpeed = speed
                return true, "Speed set"
            end,
            getShipState = function(self) return self.state end
        }
        
        -- Assign mock services
        poopDeck.services.FishingService = MockFishingService
        poopDeck.services.NotificationService = MockNotificationService
        poopDeck.services.StatusWindowService = MockStatusWindowService
        poopDeck.services.PromptService = MockPromptService
        poopDeck.services.ErrorHandlingService = MockErrorHandlingService
        poopDeck.services.ShipManagementService = MockShipManagementService
        
        -- Create SessionManager
        poopDeck.core.SessionManager = poopDeck.core.BaseClass:extend("SessionManager")
        function poopDeck.core.SessionManager:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.services = {}
            instance.initialized = false
            instance.observers = {}
            
            return instance
        end
        
        function poopDeck.core.SessionManager:initialize()
            if self.initialized then
                return false, "Session manager already initialized"
            end
            
            -- Initialize all services
            local initResults = {}
            
            -- Error handling service (initialize first)
            self.services.errorHandling = poopDeck.services.ErrorHandlingService:new(self.config.errorHandling)
            initResults.errorHandling = true
            
            -- Core services
            self.services.fishing = poopDeck.services.FishingService:new(self.config.fishing)
            initResults.fishing = true
            
            self.services.notifications = poopDeck.services.NotificationService:new(self.config.notifications)
            initResults.notifications = true
            
            self.services.statusWindows = poopDeck.services.StatusWindowService:new(self.config.statusWindows)
            local windowSuccess, windowMessage = self.services.statusWindows:initializeWindows()
            initResults.statusWindows = windowSuccess
            
            self.services.promptService = poopDeck.services.PromptService:new(self.config.promptService)
            initResults.promptService = true
            
            self.services.shipManagement = poopDeck.services.ShipManagementService:new(self.config.shipManagement)
            initResults.shipManagement = true
            
            -- Cross-service wiring
            self:wireServiceEvents()
            
            self.initialized = true
            self:emit("initialized", initResults)
            
            return true, initResults
        end
        
        function poopDeck.core.SessionManager:wireServiceEvents()
            -- Wire fishing service events
            if self.services.fishing and self.services.statusWindows then
                self.services.fishing:on("fishCaught", function(fishData)
                    self.services.statusWindows:addFishingMessage("Fish caught: " .. (fishData.type or "unknown"))
                end)
                
                self.services.fishing:on("fishEscaped", function(escapeData)
                    self.services.statusWindows:addFishingMessage("Fish escaped: " .. (escapeData.reason or "unknown"))
                end)
            end
            
            -- Wire notification service to status windows
            if self.services.notifications and self.services.statusWindows then
                self.services.notifications:on("notificationSent", function(notificationType, message)
                    self.services.statusWindows:addAlertMessage(message)
                end)
            end
            
            -- Wire error handling across all services
            if self.services.errorHandling then
                for serviceName, service in pairs(self.services) do
                    if serviceName ~= "errorHandling" and service.on then
                        service:on("error", function(error, context)
                            self.services.errorHandling:handleError(error, 
                                table.merge(context or {}, {service = serviceName}), 
                                serviceName)
                        end)
                    end
                end
            end
        end
        
        function poopDeck.core.SessionManager:getService(serviceName)
            return self.services[serviceName]
        end
        
        function poopDeck.core.SessionManager:getFishingService()
            return self.services.fishing
        end
        
        function poopDeck.core.SessionManager:getNotificationService()
            return self.services.notifications
        end
        
        function poopDeck.core.SessionManager:getStatusWindowService()
            return self.services.statusWindows
        end
        
        function poopDeck.core.SessionManager:getPromptService()
            return self.services.promptService
        end
        
        function poopDeck.core.SessionManager:getErrorHandlingService()
            return self.services.errorHandling
        end
        
        function poopDeck.core.SessionManager:getShipManagementService()
            return self.services.shipManagement
        end
        
        function poopDeck.core.SessionManager:shutdown()
            if not self.initialized then
                return false, "Session manager not initialized"
            end
            
            -- Shutdown services in reverse order
            local shutdownResults = {}
            
            if self.services.fishing and self.services.fishing.stopFishing then
                local success, message = self.services.fishing:stopFishing()
                shutdownResults.fishing = success
            end
            
            if self.services.notifications and self.services.notifications.stopSeamonsterCycle then
                local success, message = self.services.notifications:stopSeamonsterCycle()
                shutdownResults.notifications = success
            end
            
            -- Clear service references
            self.services = {}
            self.initialized = false
            
            self:emit("shutdown", shutdownResults)
            
            return true, shutdownResults
        end
        
        function poopDeck.core.SessionManager:restart()
            local shutdownSuccess, shutdownResult = self:shutdown()
            if not shutdownSuccess then
                return false, "Failed to shutdown: " .. (shutdownResult or "unknown error")
            end
            
            local initSuccess, initResult = self:initialize()
            if not initSuccess then
                return false, "Failed to initialize: " .. (initResult or "unknown error")
            end
            
            return true, "Session manager restarted successfully"
        end
        
        function poopDeck.core.SessionManager:getStatus()
            return {
                initialized = self.initialized,
                serviceCount = self.services and self:countServices() or 0,
                services = self.services and self:getServiceStatus() or {}
            }
        end
        
        function poopDeck.core.SessionManager:countServices()
            local count = 0
            for _ in pairs(self.services) do
                count = count + 1
            end
            return count
        end
        
        function poopDeck.core.SessionManager:getServiceStatus()
            local status = {}
            for serviceName, service in pairs(self.services) do
                status[serviceName] = {
                    available = service ~= nil,
                    enabled = service.enabled,
                    className = service.className
                }
            end
            return status
        end
        
        function poopDeck.core.SessionManager:executeWithErrorHandling(func, context, category)
            if self.services.errorHandling then
                return self.services.errorHandling:safeExecute(func, context, category)
            else
                return func()
            end
        end
        
        -- Global session manager instance
        poopDeck.sessionManager = nil
        
        -- Utility function for merging tables
        table.merge = table.merge or function(t1, t2)
            local result = {}
            for k, v in pairs(t1 or {}) do result[k] = v end
            for k, v in pairs(t2 or {}) do result[k] = v end
            return result
        end
        
        -- Clear test state
        _G.initializationEvents = {}
        _G.shutdownEvents = {}
    end)
    
    describe("Session manager initialization", function()
        it("should create session manager instance", function()
            local sessionManager = poopDeck.core.SessionManager:new()
            
            assert.is_not_nil(sessionManager)
            assert.are.equal("SessionManager", sessionManager.className)
            assert.are.equal(false, sessionManager.initialized)
            assert.is_table(sessionManager.services)
        end)
        
        it("should initialize all services", function()
            local sessionManager = poopDeck.core.SessionManager:new()
            local success, results = sessionManager:initialize()
            
            assert.are.equal(true, success)
            assert.is_table(results)
            assert.are.equal(true, results.fishing)
            assert.are.equal(true, results.notifications)
            assert.are.equal(true, results.statusWindows)
            assert.are.equal(true, results.promptService)
            assert.are.equal(true, results.errorHandling)
            assert.are.equal(true, sessionManager.initialized)
        end)
        
        it("should prevent double initialization", function()
            local sessionManager = poopDeck.core.SessionManager:new()
            sessionManager:initialize()
            
            local success, message = sessionManager:initialize()
            
            assert.are.equal(false, success)
            assert.truthy(message:match("already initialized"))
        end)
        
        it("should initialize with custom configuration", function()
            local config = {
                fishing = {enabled = false},
                notifications = {fiveMinuteWarning = false},
                promptService = {quietMode = true}
            }
            
            local sessionManager = poopDeck.core.SessionManager:new(config)
            local success, results = sessionManager:initialize()
            
            assert.are.equal(true, success)
            assert.is_not_nil(sessionManager.services.fishing)
            assert.is_not_nil(sessionManager.services.notifications)
            assert.is_not_nil(sessionManager.services.promptService)
        end)
    end)
    
    describe("Service access and management", function()
        local sessionManager
        
        before_each(function()
            sessionManager = poopDeck.core.SessionManager:new()
            sessionManager:initialize()
        end)
        
        it("should provide service access methods", function()
            assert.is_not_nil(sessionManager:getFishingService())
            assert.is_not_nil(sessionManager:getNotificationService())
            assert.is_not_nil(sessionManager:getStatusWindowService())
            assert.is_not_nil(sessionManager:getPromptService())
            assert.is_not_nil(sessionManager:getErrorHandlingService())
            assert.is_not_nil(sessionManager:getShipManagementService())
        end)
        
        it("should provide generic service access", function()
            assert.are.equal(sessionManager:getFishingService(), sessionManager:getService("fishing"))
            assert.are.equal(sessionManager:getNotificationService(), sessionManager:getService("notifications"))
            assert.are.equal(sessionManager:getStatusWindowService(), sessionManager:getService("statusWindows"))
        end)
        
        it("should return nil for non-existent services", function()
            assert.is_nil(sessionManager:getService("nonexistent"))
        end)
        
        it("should provide service count", function()
            assert.are.equal(6, sessionManager:countServices()) -- 6 services initialized
        end)
        
        it("should provide service status", function()
            local status = sessionManager:getServiceStatus()
            
            assert.is_not_nil(status.fishing)
            assert.are.equal(true, status.fishing.available)
            assert.are.equal(true, status.fishing.enabled)
            
            assert.is_not_nil(status.notifications)
            assert.are.equal(true, status.notifications.available)
        end)
        
        it("should provide overall session status", function()
            local status = sessionManager:getStatus()
            
            assert.are.equal(true, status.initialized)
            assert.are.equal(6, status.serviceCount)
            assert.is_table(status.services)
        end)
    end)
    
    describe("Service integration and event wiring", function()
        local sessionManager
        
        before_each(function()
            sessionManager = poopDeck.core.SessionManager:new()
            sessionManager:initialize()
            
            -- Add mock event handling to services
            for serviceName, service in pairs(sessionManager.services) do
                if not service.observers then
                    service.observers = {}
                    service.on = poopDeck.core.BaseClass.on
                    service.emit = poopDeck.core.BaseClass.emit
                end
            end
        end)
        
        it("should wire fishing events to status windows", function()
            local statusService = sessionManager:getStatusWindowService()
            local fishingService = sessionManager:getFishingService()
            
            -- Mock the addFishingMessage function to track calls
            statusService.addFishingMessage = function(self, message)
                _G.lastFishingMessage = message
                return true
            end
            
            -- Re-wire events after adding mock
            sessionManager:wireServiceEvents()
            
            -- Trigger fishing event
            fishingService:emit("fishCaught", {type = "bass"})
            
            assert.truthy(_G.lastFishingMessage:match("Fish caught: bass"))
        end)
        
        it("should wire notification events to status windows", function()
            local statusService = sessionManager:getStatusWindowService()
            local notificationService = sessionManager:getNotificationService()
            
            statusService.addAlertMessage = function(self, message)
                _G.lastAlertMessage = message
                return true
            end
            
            sessionManager:wireServiceEvents()
            
            notificationService:emit("notificationSent", "test", "Test notification")
            
            assert.are.equal("Test notification", _G.lastAlertMessage)
        end)
        
        it("should wire error events to error handling service", function()
            local errorService = sessionManager:getErrorHandlingService()
            local fishingService = sessionManager:getFishingService()
            
            sessionManager:wireServiceEvents()
            
            fishingService:emit("error", "Test fishing error", {function = "testFunc"})
            
            -- Error should be recorded in error service
            assert.are.equal(1, #errorService.errorHistory)
            assert.are.equal("Test fishing error", errorService.errorHistory[1].error)
            assert.are.equal("fishing", errorService.errorHistory[1].context.service)
        end)
        
        it("should handle cross-service communication", function()
            -- Test that services can communicate through the session manager
            local fishingService = sessionManager:getFishingService()
            local notificationService = sessionManager:getNotificationService()
            
            -- Verify services are properly integrated
            assert.is_not_nil(fishingService)
            assert.is_not_nil(notificationService)
            
            -- Both services should be accessible through session manager
            assert.are.equal(fishingService, sessionManager:getService("fishing"))
            assert.are.equal(notificationService, sessionManager:getService("notifications"))
        end)
    end)
    
    describe("Error handling integration", function()
        local sessionManager
        
        before_each(function()
            sessionManager = poopDeck.core.SessionManager:new()
            sessionManager:initialize()
        end)
        
        it("should execute functions safely with error handling", function()
            local result = sessionManager:executeWithErrorHandling(function()
                return "success"
            end, {test = true}, "test")
            
            assert.are.equal("success", result)
        end)
        
        it("should handle errors in safe execution", function()
            local result, error = sessionManager:executeWithErrorHandling(function()
                error("Test error")
            end, {function = "testError"}, "test")
            
            assert.is_nil(result)
            assert.is_not_nil(error)
            
            -- Error should be logged in error service
            local errorService = sessionManager:getErrorHandlingService()
            assert.are.equal(1, #errorService.errorHistory)
        end)
        
        it("should handle missing error service gracefully", function()
            -- Remove error service
            sessionManager.services.errorHandling = nil
            
            local result = sessionManager:executeWithErrorHandling(function()
                return "direct execution"
            end)
            
            assert.are.equal("direct execution", result)
        end)
    end)
    
    describe("Session lifecycle management", function()
        local sessionManager
        
        before_each(function()
            sessionManager = poopDeck.core.SessionManager:new()
        end)
        
        it("should track initialization events", function()
            sessionManager:on("initialized", function(results)
                _G.initializationEvent = results
            end)
            
            sessionManager:initialize()
            
            assert.is_not_nil(_G.initializationEvent)
            assert.are.equal(true, _G.initializationEvent.fishing)
        end)
        
        it("should shutdown properly", function()
            sessionManager:initialize()
            
            local success, results = sessionManager:shutdown()
            
            assert.are.equal(true, success)
            assert.is_table(results)
            assert.are.equal(false, sessionManager.initialized)
            assert.are.equal(0, sessionManager:countServices())
        end)
        
        it("should not shutdown when not initialized", function()
            local success, message = sessionManager:shutdown()
            
            assert.are.equal(false, success)
            assert.truthy(message:match("not initialized"))
        end)
        
        it("should track shutdown events", function()
            sessionManager:initialize()
            
            sessionManager:on("shutdown", function(results)
                _G.shutdownEvent = results
            end)
            
            sessionManager:shutdown()
            
            assert.is_not_nil(_G.shutdownEvent)
        end)
        
        it("should restart successfully", function()
            sessionManager:initialize()
            
            local success, message = sessionManager:restart()
            
            assert.are.equal(true, success)
            assert.truthy(message:match("restarted successfully"))
            assert.are.equal(true, sessionManager.initialized)
            assert.are.equal(6, sessionManager:countServices())
        end)
        
        it("should handle restart failure gracefully", function()
            -- Don't initialize first, so shutdown will fail
            local success, message = sessionManager:restart()
            
            assert.are.equal(false, success)
            assert.truthy(message:match("Failed to shutdown"))
        end)
    end)
    
    describe("Global session manager", function()
        it("should support global instance", function()
            poopDeck.sessionManager = poopDeck.core.SessionManager:new()
            poopDeck.sessionManager:initialize()
            
            assert.is_not_nil(poopDeck.sessionManager)
            assert.are.equal(true, poopDeck.sessionManager.initialized)
            
            -- Global access should work
            assert.is_not_nil(poopDeck.sessionManager:getFishingService())
            assert.is_not_nil(poopDeck.sessionManager:getNotificationService())
        end)
        
        it("should provide consistent global access", function()
            poopDeck.sessionManager = poopDeck.core.SessionManager:new()
            poopDeck.sessionManager:initialize()
            
            local fishingService1 = poopDeck.sessionManager:getFishingService()
            local fishingService2 = poopDeck.sessionManager:getService("fishing")
            
            assert.are.equal(fishingService1, fishingService2)
        end)
    end)
    
    describe("Configuration management", function()
        it("should pass configuration to services", function()
            local config = {
                fishing = {
                    enabled = false,
                    maxRetries = 5
                },
                notifications = {
                    fiveMinuteWarning = false,
                    enabled = true
                }
            }
            
            local sessionManager = poopDeck.core.SessionManager:new(config)
            sessionManager:initialize()
            
            -- Configuration should be passed to services
            assert.is_not_nil(sessionManager:getFishingService().config)
            assert.is_not_nil(sessionManager:getNotificationService().config)
        end)
        
        it("should handle missing configuration gracefully", function()
            local sessionManager = poopDeck.core.SessionManager:new()
            local success = sessionManager:initialize()
            
            assert.are.equal(true, success)
            
            -- Services should initialize with default configs
            assert.is_not_nil(sessionManager:getFishingService())
            assert.is_not_nil(sessionManager:getNotificationService())
        end)
        
        it("should handle partial configuration", function()
            local config = {
                fishing = {enabled = false}
                -- Other services not configured
            }
            
            local sessionManager = poopDeck.core.SessionManager:new(config)
            local success = sessionManager:initialize()
            
            assert.are.equal(true, success)
            assert.are.equal(6, sessionManager:countServices())
        end)
    end)
    
    describe("Integration stress testing", function()
        local sessionManager
        
        before_each(function()
            sessionManager = poopDeck.core.SessionManager:new()
            sessionManager:initialize()
        end)
        
        it("should handle multiple rapid service calls", function()
            local fishingService = sessionManager:getFishingService()
            
            -- Make many rapid calls
            for i = 1, 100 do
                local success, message = fishingService:startFishing()
                assert.are.equal(true, success)
                
                success, message = fishingService:stopFishing()
                assert.are.equal(true, success)
            end
        end)
        
        it("should handle multiple concurrent event emissions", function()
            local errorService = sessionManager:getErrorHandlingService()
            local initialErrorCount = #errorService.errorHistory
            
            -- Emit many events from different services
            for i = 1, 50 do
                sessionManager:getService("fishing"):emit("error", "Error " .. i, {test = true})
                sessionManager:getService("notifications"):emit("error", "Notification error " .. i)
            end
            
            -- All errors should be handled
            assert.are.equal(initialErrorCount + 100, #errorService.errorHistory)
        end)
        
        it("should maintain service integrity during stress", function()
            -- Perform many operations
            for i = 1, 20 do
                sessionManager:restart()
            end
            
            -- Services should still be functional
            assert.are.equal(true, sessionManager.initialized)
            assert.are.equal(6, sessionManager:countServices())
            
            local status = sessionManager:getStatus()
            assert.are.equal(true, status.initialized)
            assert.are.equal(6, status.serviceCount)
        end)
    end)
end)