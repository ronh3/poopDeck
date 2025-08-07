-- Load spec helper
require('spec.spec_helper')

-- Auto-resume functionality tests focusing on the user's primary concern
describe("poopDeck Auto-Resume Functionality", function()
    
    before_each(function()
        -- Initialize comprehensive test environment for auto-resume testing
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.domain = poopDeck.domain or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock BaseClass with full event system
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
        
        -- Create FishingSession with detailed state tracking
        poopDeck.domain.FishingSession = poopDeck.core.BaseClass:extend("FishingSession")
        function poopDeck.domain.FishingSession:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.state = "idle"
            instance.autoRestart = instance.config.autoRestart ~= false -- Default true
            instance.stats = {
                totalCasts = 0,
                totalCatches = 0,
                escapes = 0,
                sessionStart = os.time(),
                escapeReasons = {}
            }
            instance.observers = {}
            return instance
        end
        
        function poopDeck.domain.FishingSession:startCast()
            self.state = "casting"
            self.stats.totalCasts = self.stats.totalCasts + 1
            self:emit("castStarted", {
                cast = self.stats.totalCasts,
                timestamp = os.time()
            })
        end
        
        function poopDeck.domain.FishingSession:fishCaught(fishData)
            self.state = "idle"
            self.stats.totalCatches = self.stats.totalCatches + 1
            self:emit("fishCaught", {
                fish = fishData,
                totalCatches = self.stats.totalCatches,
                timestamp = os.time()
            })
        end
        
        function poopDeck.domain.FishingSession:fishEscaped(reason)
            self.state = "idle"
            self.stats.escapes = self.stats.escapes + 1
            
            -- Track escape reasons
            self.stats.escapeReasons[reason] = (self.stats.escapeReasons[reason] or 0) + 1
            
            local escapedFish = {
                reason = reason,
                escapeNumber = self.stats.escapes,
                timestamp = os.time()
            }
            
            self:emit("fishEscaped", {
                fish = escapedFish,
                reason = reason,
                escapeNumber = self.stats.escapes,
                shouldRestart = self.autoRestart,
                session = self
            })
        end
        
        -- Create FishingService with robust auto-resume logic
        poopDeck.services.FishingService = poopDeck.core.BaseClass:extend("FishingService")
        function poopDeck.services.FishingService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.enabled = instance.config.enabled ~= false
            instance.session = nil
            instance.equipment = {
                currentBait = instance.config.defaultBait or "bass",
                currentCastDistance = instance.config.defaultHook or "medium",
                currentBaitSource = instance.config.baitSource or "tank"
            }
            instance.retryCount = 0
            instance.maxRetries = instance.config.maxRetries or 3
            instance.retryDelay = instance.config.retryDelay or 5
            instance.autoRestart = instance.config.autoRestart ~= false
            instance.observers = {}
            instance.restartHistory = {}
            return instance
        end
        
        function poopDeck.services.FishingService:startFishing(bait, castDistance)
            if not self.enabled then
                return false, "Fishing service is disabled"
            end
            
            if self.session and self.session.state == "casting" then
                return false, "Already fishing"
            end
            
            -- Update equipment if provided
            if bait then self.equipment.currentBait = bait end
            if castDistance then self.equipment.currentCastDistance = castDistance end
            
            -- Create new session if needed
            if not self.session or self.session.state == "stopped" then
                self.session = poopDeck.domain.FishingSession:new({
                    autoRestart = self.autoRestart,
                    bait = self.equipment.currentBait,
                    castDistance = self.equipment.currentCastDistance
                })
                
                -- Subscribe to session events for auto-resume
                self.session:on("fishEscaped", function(data)
                    self:handleFishEscaped(data)
                end)
                
                self.session:on("fishCaught", function(data)
                    self:handleFishCaught(data)
                end)
            end
            
            -- Execute fishing sequence
            self:executeCastSequence()
            return true, "Fishing started"
        end
        
        function poopDeck.services.FishingService:executeCastSequence()
            if not self.session then return end
            
            -- Generate commands based on bait source
            local commands = self:generateFishingCommands()
            
            -- Execute commands
            for _, cmd in ipairs(commands) do
                send(cmd)
            end
            
            -- Start the session
            self.session:startCast()
            
            -- Store for testing
            _G.lastFishingCommands = commands
            _G.lastCastTimestamp = os.time()
        end
        
        function poopDeck.services.FishingService:generateFishingCommands()
            local commands = {}
            
            -- Bait sequence based on source
            if self.equipment.currentBaitSource == "tank" then
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait .. " from tank")
            elseif self.equipment.currentBaitSource == "inventory" then
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait)
            elseif self.equipment.currentBaitSource == "fishbucket" then
                table.insert(commands, "queue add freestand get " .. self.equipment.currentBait .. " from fishbucket")
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait)
            end
            
            -- Cast command
            table.insert(commands, "queue add freestand cast " .. self.equipment.currentCastDistance)
            
            return commands
        end
        
        function poopDeck.services.FishingService:handleFishEscaped(data)
            -- Record escape event
            table.insert(self.restartHistory, {
                type = "escape",
                reason = data.reason,
                timestamp = os.time(),
                retryCount = self.retryCount
            })
            
            -- Check if auto-restart is enabled
            if not data.shouldRestart or not self.autoRestart then
                poopDeck.badEcho("Fish escaped (" .. data.reason .. "). Auto-restart disabled.")
                return
            end
            
            -- Check retry limits
            if self.retryCount >= self.maxRetries then
                poopDeck.badEcho("Fish escaped (" .. data.reason .. "). Max retries reached (" .. self.maxRetries .. "). Stopping fishing.")
                self:stopFishing()
                return
            end
            
            -- Increment retry count and restart
            self.retryCount = self.retryCount + 1
            local message = string.format("Fish escaped (%s). Auto-restarting... (Attempt %d/%d)", 
                data.reason, self.retryCount, self.maxRetries)
            poopDeck.badEcho(message)
            
            -- Schedule restart with delay
            tempTimer(self.retryDelay, function()
                self:executeAutoRestart()
            end)
        end
        
        function poopDeck.services.FishingService:executeAutoRestart()
            if not self.session then return end
            
            -- Record restart attempt
            table.insert(self.restartHistory, {
                type = "restart",
                timestamp = os.time(),
                retryCount = self.retryCount
            })
            
            -- Execute cast sequence again
            self:executeCastSequence()
        end
        
        function poopDeck.services.FishingService:handleFishCaught(data)
            -- Reset retry count on successful catch
            self.retryCount = 0
            
            -- Record successful catch
            table.insert(self.restartHistory, {
                type = "catch",
                fish = data.fish,
                timestamp = os.time()
            })
            
            poopDeck.goodEcho("Fish caught! Resetting retry counter.")
        end
        
        function poopDeck.services.FishingService:stopFishing()
            if self.session then
                self.session.state = "stopped"
            end
            self.retryCount = 0
            poopDeck.goodEcho("Fishing stopped.")
        end
        
        function poopDeck.services.FishingService:setAutoRestart(enabled)
            self.autoRestart = enabled
            if self.session then
                self.session.autoRestart = enabled
            end
        end
        
        function poopDeck.services.FishingService:getRestartHistory()
            return self.restartHistory
        end
        
        -- Mock functions for testing
        send = function(cmd) 
            _G.lastSentCommand = cmd
            _G.sentCommands = _G.sentCommands or {}
            table.insert(_G.sentCommands, cmd)
        end
        
        tempTimer = function(delay, func)
            _G.lastTempTimer = {delay = delay, func = func}
            _G.timerHistory = _G.timerHistory or {}
            table.insert(_G.timerHistory, {delay = delay, timestamp = os.time()})
        end
        
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
            _G.allBadEchos = _G.allBadEchos or {}
            table.insert(_G.allBadEchos, msg)
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
            _G.allGoodEchos = _G.allGoodEchos or {}
            table.insert(_G.allGoodEchos, msg)
        end
        
        -- Clear test state
        _G.lastSentCommand = nil
        _G.sentCommands = nil
        _G.lastFishingCommands = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.allBadEchos = nil
        _G.allGoodEchos = nil
        _G.lastTempTimer = nil
        _G.timerHistory = nil
        _G.lastCastTimestamp = nil
    end)
    
    describe("Basic auto-resume functionality", function()
        local service
        
        before_each(function()
            service = poopDeck.services.FishingService:new({
                enabled = true,
                autoRestart = true,
                maxRetries = 3,
                retryDelay = 5
            })
        end)
        
        it("should automatically restart fishing when a fish escapes", function()
            -- Start fishing
            service:startFishing()
            local initialCasts = service.session.stats.totalCasts
            
            -- Simulate fish escape
            service.session:fishEscaped("line snapped")
            
            -- Verify restart was scheduled
            assert.is_not_nil(_G.lastTempTimer)
            assert.are.equal(5, _G.lastTempTimer.delay)
            assert.are.equal(1, service.retryCount)
            assert.truthy(_G.lastBadEcho:match("Auto%-restarting"))
            
            -- Execute the scheduled restart
            _G.lastTempTimer.func()
            
            -- Verify restart happened
            assert.are.equal(initialCasts + 1, service.session.stats.totalCasts) -- +1 from restart
            assert.is_not_nil(_G.lastFishingCommands)
        end)
        
        it("should track multiple escape and restart attempts", function()
            service:startFishing()
            
            -- Simulate multiple escapes
            service.session:fishEscaped("line broke")
            _G.lastTempTimer.func() -- Execute first restart
            
            service.session:fishEscaped("fish too strong")
            _G.lastTempTimer.func() -- Execute second restart
            
            service.session:fishEscaped("hook bent")
            _G.lastTempTimer.func() -- Execute third restart
            
            -- Verify all attempts were tracked
            assert.are.equal(3, service.retryCount)
            assert.are.equal(3, service.session.stats.escapes)
            
            local history = service:getRestartHistory()
            local escapeCount = 0
            local restartCount = 0
            
            for _, event in ipairs(history) do
                if event.type == "escape" then escapeCount = escapeCount + 1 end
                if event.type == "restart" then restartCount = restartCount + 1 end
            end
            
            assert.are.equal(3, escapeCount)
            assert.are.equal(3, restartCount)
        end)
        
        it("should stop auto-restarting after max retries", function()
            service:startFishing()
            
            -- Exceed max retries
            for i = 1, 4 do
                service.session:fishEscaped("persistent issue")
                if _G.lastTempTimer then
                    _G.lastTempTimer.func()
                end
            end
            
            -- Verify service stopped after max retries
            assert.are.equal("stopped", service.session.state)
            assert.truthy(_G.lastBadEcho:match("Max retries reached"))
            assert.are.equal(0, service.retryCount) -- Reset after stopping
        end)
        
        it("should reset retry count on successful catch", function()
            service:startFishing()
            
            -- Escape and restart
            service.session:fishEscaped("minor issue")
            _G.lastTempTimer.func()
            assert.are.equal(1, service.retryCount)
            
            -- Successful catch
            service.session:fishCaught({type = "bass", weight = 5})
            
            -- Verify retry count reset
            assert.are.equal(0, service.retryCount)
            assert.truthy(_G.lastGoodEcho:match("Resetting retry counter"))
        end)
    end)
    
    describe("Auto-restart configuration", function()
        it("should not restart when auto-restart is disabled", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = false
            })
            
            service:startFishing()
            service.session:fishEscaped("line broke")
            
            -- Verify no restart was scheduled
            assert.is_nil(_G.lastTempTimer)
            assert.are.equal(0, service.retryCount)
            assert.truthy(_G.lastBadEcho:match("Auto%-restart disabled"))
        end)
        
        it("should allow enabling/disabling auto-restart during session", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            
            -- Disable auto-restart
            service:setAutoRestart(false)
            service.session:fishEscaped("test escape")
            
            -- Verify no restart
            assert.is_nil(_G.lastTempTimer)
            
            -- Re-enable auto-restart
            service:setAutoRestart(true)
            service.session:fishEscaped("another escape")
            
            -- Verify restart scheduled
            assert.is_not_nil(_G.lastTempTimer)
        end)
        
        it("should respect custom retry limits", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true,
                maxRetries = 1
            })
            
            service:startFishing()
            
            -- First escape should restart
            service.session:fishEscaped("first escape")
            assert.is_not_nil(_G.lastTempTimer)
            _G.lastTempTimer.func()
            
            -- Second escape should stop (exceeded limit)
            service.session:fishEscaped("second escape")
            assert.are.equal("stopped", service.session.state)
        end)
        
        it("should respect custom retry delay", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true,
                retryDelay = 10
            })
            
            service:startFishing()
            service.session:fishEscaped("delay test")
            
            assert.are.equal(10, _G.lastTempTimer.delay)
        end)
    end)
    
    describe("Escape reason tracking", function()
        it("should track different escape reasons", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            
            -- Different escape scenarios
            service.session:fishEscaped("line snapped")
            service.session:fishEscaped("fish too strong") 
            service.session:fishEscaped("line snapped") -- Repeat reason
            service.session:fishEscaped("hook broke")
            
            -- Verify reasons were tracked
            local reasons = service.session.stats.escapeReasons
            assert.are.equal(2, reasons["line snapped"])
            assert.are.equal(1, reasons["fish too strong"])
            assert.are.equal(1, reasons["hook broke"])
        end)
        
        it("should include escape reason in restart messages", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            service.session:fishEscaped("unique test reason")
            
            assert.truthy(_G.lastBadEcho:match("unique test reason"))
            assert.truthy(_G.lastBadEcho:match("Auto%-restarting"))
        end)
    end)
    
    describe("Complex auto-resume scenarios", function()
        it("should handle rapid succession of escapes and catches", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true,
                maxRetries = 5
            })
            
            service:startFishing()
            
            -- Rapid sequence: escape, restart, catch, escape, restart
            service.session:fishEscaped("quick escape")
            _G.lastTempTimer.func()
            
            service.session:fishCaught({type = "bass"})
            assert.are.equal(0, service.retryCount) -- Reset after catch
            
            service.session:fishEscaped("another escape")
            assert.are.equal(1, service.retryCount) -- New count after reset
        end)
        
        it("should maintain statistics across restarts", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            
            -- Multiple cycles
            for i = 1, 3 do
                service.session:fishEscaped("escape " .. i)
                _G.lastTempTimer.func()
            end
            
            for i = 1, 2 do
                service.session:fishCaught({type = "fish " .. i})
            end
            
            -- Verify cumulative statistics
            assert.are.equal(6, service.session.stats.totalCasts) -- 1 initial + 3 restarts + 2 after catches
            assert.are.equal(2, service.session.stats.totalCatches)
            assert.are.equal(3, service.session.stats.escapes)
        end)
        
        it("should work correctly with different bait sources during restarts", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true,
                baitSource = "fishbucket"
            })
            
            service:startFishing()
            service.session:fishEscaped("test escape")
            _G.lastTempTimer.func()
            
            -- Verify fishbucket commands were used in restart
            local commands = _G.lastFishingCommands
            assert.is_not_nil(commands)
            
            local hasGetCommand = false
            local hasBaitCommand = false
            
            for _, cmd in ipairs(commands) do
                if cmd:match("get .* from fishbucket") then hasGetCommand = true end
                if cmd:match("bait hook with") then hasBaitCommand = true end
            end
            
            assert.are.equal(true, hasGetCommand)
            assert.are.equal(true, hasBaitCommand)
        end)
    end)
    
    describe("Auto-resume edge cases", function()
        it("should handle session being nil during restart", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            service.session:fishEscaped("test escape")
            
            -- Clear session before timer executes
            service.session = nil
            
            -- Should not crash when timer executes
            assert.has_no.errors(function()
                _G.lastTempTimer.func()
            end)
        end)
        
        it("should handle service being disabled during restart", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true
            })
            
            service:startFishing()
            service.session:fishEscaped("test escape")
            
            -- Disable service before timer executes
            service.enabled = false
            
            -- Timer should still execute without error
            assert.has_no.errors(function()
                _G.lastTempTimer.func()
            end)
        end)
        
        it("should maintain restart history even after service stop", function()
            local service = poopDeck.services.FishingService:new({
                autoRestart = true,
                maxRetries = 2
            })
            
            service:startFishing()
            service.session:fishEscaped("first")
            _G.lastTempTimer.func()
            service.session:fishEscaped("second")
            _G.lastTempTimer.func()
            service.session:fishEscaped("third - should stop")
            
            -- Service should be stopped but history preserved
            local history = service:getRestartHistory()
            assert.truthy(#history > 0)
            
            -- Should have escape and restart events
            local hasEscapes = false
            local hasRestarts = false
            
            for _, event in ipairs(history) do
                if event.type == "escape" then hasEscapes = true end
                if event.type == "restart" then hasRestarts = true end
            end
            
            assert.are.equal(true, hasEscapes)
            assert.are.equal(true, hasRestarts)
        end)
    end)
end)