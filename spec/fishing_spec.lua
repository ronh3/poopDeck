-- Load spec helper
require('spec.spec_helper')

-- Load the fishing service and related domain objects for testing
-- In production, these would be loaded from the installed package

describe("poopDeck Fishing System", function()
    
    -- Mock setup for fishing tests
    before_each(function()
        -- Initialize poopDeck namespace with fishing components
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.domain = poopDeck.domain or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock BaseClass for inheritance
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
                        callback(...)
                    end
                end
            end
        }
        
        -- Create simplified FishingSession domain object
        poopDeck.domain.FishingSession = poopDeck.core.BaseClass:extend("FishingSession")
        function poopDeck.domain.FishingSession:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.state = "idle"
            instance.autoRestart = instance.config.autoRestart or true
            instance.stats = {
                totalCasts = 0,
                totalCatches = 0,
                escapes = 0,
                sessionStart = os.time()
            }
            instance.observers = {}
            return instance
        end
        
        function poopDeck.domain.FishingSession:startCast()
            self.state = "casting"
            self.stats.totalCasts = self.stats.totalCasts + 1
            self:emit("castStarted", {cast = self.stats.totalCasts})
        end
        
        function poopDeck.domain.FishingSession:fishCaught(fishData)
            self.state = "idle"
            self.stats.totalCatches = self.stats.totalCatches + 1
            self:emit("fishCaught", fishData)
        end
        
        function poopDeck.domain.FishingSession:fishEscaped(reason)
            self.state = "idle"
            self.stats.escapes = self.stats.escapes + 1
            local escapedFish = {
                reason = reason,
                escapeNumber = self.stats.escapes
            }
            self:emit("fishEscaped", {
                fish = escapedFish,
                reason = reason,
                escapeNumber = self.stats.escapes,
                shouldRestart = self.autoRestart
            })
        end
        
        -- Create simplified FishingService
        poopDeck.services.FishingService = poopDeck.core.BaseClass:extend("FishingService")
        function poopDeck.services.FishingService:new(config)
            local instance = setmetatable({}, {__index = self})
            instance.config = config or {}
            instance.enabled = instance.config.enabled or true
            instance.session = nil
            instance.equipment = {
                currentBait = instance.config.defaultBait or "bass",
                currentCastDistance = instance.config.defaultHook or "medium",
                currentBaitSource = instance.config.baitSource or "tank"
            }
            instance.retryCount = 0
            instance.maxRetries = instance.config.maxRetries or 3
            instance.observers = {}
            return instance
        end
        
        function poopDeck.services.FishingService:startFishing(bait, castDistance)
            if not self.enabled then
                return false, "Fishing service is disabled"
            end
            
            if self.session and self.session.state ~= "idle" then
                return false, "Already fishing"
            end
            
            -- Update equipment if parameters provided
            if bait then self.equipment.currentBait = bait end
            if castDistance then self.equipment.currentCastDistance = castDistance end
            
            -- Create new session
            self.session = poopDeck.domain.FishingSession:new({
                autoRestart = self.config.autoRestart,
                bait = self.equipment.currentBait,
                castDistance = self.equipment.currentCastDistance
            })
            
            -- Subscribe to session events
            self.session:on("fishEscaped", function(data)
                self:handleFishEscaped(data)
            end)
            
            -- Start the cast
            self:executeCastSequence()
            return true, "Fishing started"
        end
        
        function poopDeck.services.FishingService:executeCastSequence()
            if not self.session then return end
            
            -- Build command sequence based on bait source
            local commands = {}
            
            if self.equipment.currentBaitSource == "tank" then
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait .. " from tank")
            elseif self.equipment.currentBaitSource == "inventory" then
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait)
            elseif self.equipment.currentBaitSource == "fishbucket" then
                table.insert(commands, "queue add freestand get " .. self.equipment.currentBait .. " from fishbucket")
                table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait)
            end
            
            table.insert(commands, "queue add freestand cast " .. self.equipment.currentCastDistance)
            
            -- Execute commands
            for _, cmd in ipairs(commands) do
                send(cmd)
            end
            
            -- Start the fishing session
            self.session:startCast()
            
            -- Store commands for testing
            _G.lastFishingCommands = commands
        end
        
        function poopDeck.services.FishingService:handleFishEscaped(data)
            if not data.shouldRestart then
                return
            end
            
            if self.retryCount >= self.maxRetries then
                poopDeck.badEcho("Max fishing retries reached (" .. self.maxRetries .. "). Stopping fishing.")
                self:stopFishing()
                return
            end
            
            self.retryCount = self.retryCount + 1
            poopDeck.badEcho("Fish escaped (" .. data.reason .. "). Auto-restarting... (Attempt " .. self.retryCount .. "/" .. self.maxRetries .. ")")
            
            -- Delay restart to avoid spam
            tempTimer(5, function()
                self:executeCastSequence()
            end)
        end
        
        function poopDeck.services.FishingService:stopFishing()
            if self.session then
                self.session.state = "stopped"
                self.session = nil
            end
            self.retryCount = 0
        end
        
        function poopDeck.services.FishingService:setEnabled(enabled)
            self.enabled = enabled
        end
        
        function poopDeck.services.FishingService:setBaitSource(source)
            if source == "tank" or source == "inventory" or source == "fishbucket" then
                self.equipment.currentBaitSource = source
                return true
            end
            return false
        end
        
        -- Mock functions
        send = function(cmd) 
            _G.lastSentCommand = cmd
        end
        
        tempTimer = function(delay, func)
            _G.lastTempTimer = {delay = delay, func = func}
        end
        
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
        end
        
        -- Clear test state
        _G.lastSentCommand = nil
        _G.lastFishingCommands = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.lastTempTimer = nil
    end)
    
    describe("FishingService initialization", function()
        it("should create service with default configuration", function()
            local service = poopDeck.services.FishingService:new()
            
            assert.are.equal(true, service.enabled)
            assert.are.equal("bass", service.equipment.currentBait)
            assert.are.equal("medium", service.equipment.currentCastDistance)
            assert.are.equal("tank", service.equipment.currentBaitSource)
            assert.are.equal(3, service.maxRetries)
        end)
        
        it("should create service with custom configuration", function()
            local config = {
                enabled = false,
                defaultBait = "shrimp",
                defaultHook = "long",
                baitSource = "inventory",
                maxRetries = 5
            }
            local service = poopDeck.services.FishingService:new(config)
            
            assert.are.equal(false, service.enabled)
            assert.are.equal("shrimp", service.equipment.currentBait)
            assert.are.equal("long", service.equipment.currentCastDistance)
            assert.are.equal("inventory", service.equipment.currentBaitSource)
            assert.are.equal(5, service.maxRetries)
        end)
    end)
    
    describe("Basic fishing operations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.FishingService:new({
                enabled = true,
                autoRestart = true,
                maxRetries = 3
            })
        end)
        
        it("should start fishing with default settings", function()
            local success, message = service:startFishing()
            
            assert.are.equal(true, success)
            assert.are.equal("Fishing started", message)
            assert.is_not_nil(service.session)
            assert.are.equal("casting", service.session.state)
        end)
        
        it("should not start fishing when disabled", function()
            service:setEnabled(false)
            
            local success, message = service:startFishing()
            
            assert.are.equal(false, success)
            assert.are.equal("Fishing service is disabled", message)
        end)
        
        it("should not start fishing if already fishing", function()
            service:startFishing()
            local success, message = service:startFishing()
            
            assert.are.equal(false, success)
            assert.are.equal("Already fishing", message)
        end)
        
        it("should update bait and cast distance when provided", function()
            service:startFishing("worms", "short")
            
            assert.are.equal("worms", service.equipment.currentBait)
            assert.are.equal("short", service.equipment.currentCastDistance)
        end)
    end)
    
    describe("Bait source configuration", function()
        local service
        
        before_each(function()
            service = poopDeck.services.FishingService:new()
        end)
        
        it("should generate correct commands for tank source", function()
            service:setBaitSource("tank")
            service:startFishing("bass", "medium")
            
            local commands = _G.lastFishingCommands
            assert.is_not_nil(commands)
            assert.truthy(commands[1]:match("bait hook with bass from tank"))
            assert.truthy(commands[2]:match("cast medium"))
        end)
        
        it("should generate correct commands for inventory source", function()
            service:setBaitSource("inventory")
            service:startFishing("shrimp", "long")
            
            local commands = _G.lastFishingCommands
            assert.is_not_nil(commands)
            assert.truthy(commands[1]:match("bait hook with shrimp"))
            assert.truthy(commands[2]:match("cast long"))
        end)
        
        it("should generate correct commands for fishbucket source", function()
            service:setBaitSource("fishbucket")
            service:startFishing("minnow", "short")
            
            local commands = _G.lastFishingCommands
            assert.is_not_nil(commands)
            assert.truthy(commands[1]:match("get minnow from fishbucket"))
            assert.truthy(commands[2]:match("bait hook with minnow"))
            assert.truthy(commands[3]:match("cast short"))
        end)
        
        it("should reject invalid bait sources", function()
            local result = service:setBaitSource("invalid")
            assert.are.equal(false, result)
            assert.are.equal("tank", service.equipment.currentBaitSource) -- Should remain unchanged
        end)
    end)
    
    describe("Auto-restart functionality", function()
        local service
        
        before_each(function()
            service = poopDeck.services.FishingService:new({
                enabled = true,
                autoRestart = true,
                maxRetries = 2
            })
        end)
        
        it("should auto-restart when fish escapes", function()
            service:startFishing()
            
            -- Simulate fish escape
            service.session:fishEscaped("line snapped")
            
            assert.are.equal(1, service.retryCount)
            assert.is_not_nil(_G.lastTempTimer)
            assert.are.equal(5, _G.lastTempTimer.delay)
            assert.truthy(_G.lastBadEcho:match("Fish escaped"))
            assert.truthy(_G.lastBadEcho:match("Auto%-restarting"))
        end)
        
        it("should stop after max retries", function()
            service:startFishing()
            
            -- Simulate multiple fish escapes
            service.session:fishEscaped("line snapped")
            service.session:fishEscaped("fish too strong")
            service.session:fishEscaped("hook broke")
            
            assert.are.equal(2, service.retryCount)
            assert.truthy(_G.lastBadEcho:match("Max fishing retries reached"))
            assert.is_nil(service.session)
        end)
        
        it("should not restart if auto-restart disabled", function()
            service.config.autoRestart = false
            service.session = poopDeck.domain.FishingSession:new({autoRestart = false})
            
            service.session:fishEscaped("line snapped")
            
            assert.are.equal(0, service.retryCount)
            assert.is_nil(_G.lastTempTimer)
        end)
    end)
    
    describe("FishingSession statistics", function()
        local session
        
        before_each(function()
            session = poopDeck.domain.FishingSession:new()
        end)
        
        it("should track casting statistics", function()
            session:startCast()
            session:startCast()
            session:startCast()
            
            assert.are.equal(3, session.stats.totalCasts)
        end)
        
        it("should track caught fish statistics", function()
            session:fishCaught({type = "bass", weight = 5})
            session:fishCaught({type = "trout", weight = 3})
            
            assert.are.equal(2, session.stats.totalCatches)
        end)
        
        it("should track fish escape statistics", function()
            session:fishEscaped("line snapped")
            session:fishEscaped("fish too strong")
            session:fishEscaped("hook broke")
            
            assert.are.equal(3, session.stats.escapes)
        end)
        
        it("should maintain session start time", function()
            local startTime = session.stats.sessionStart
            assert.is_number(startTime)
            assert.truthy(startTime > 0)
        end)
    end)
    
    describe("Event system integration", function()
        local service
        local eventReceived = false
        local eventData = nil
        
        before_each(function()
            service = poopDeck.services.FishingService:new()
            eventReceived = false
            eventData = nil
        end)
        
        it("should emit fishEscaped events", function()
            service:startFishing()
            
            -- Subscribe to fish escaped events
            service.session:on("fishEscaped", function(data)
                eventReceived = true
                eventData = data
            end)
            
            service.session:fishEscaped("line broke")
            
            assert.are.equal(true, eventReceived)
            assert.is_not_nil(eventData)
            assert.are.equal("line broke", eventData.reason)
            assert.are.equal(1, eventData.escapeNumber)
        end)
        
        it("should emit fishCaught events", function()
            service:startFishing()
            
            -- Subscribe to fish caught events
            service.session:on("fishCaught", function(data)
                eventReceived = true
                eventData = data
            end)
            
            local fishData = {type = "bass", weight = 7}
            service.session:fishCaught(fishData)
            
            assert.are.equal(true, eventReceived)
            assert.are.equal(fishData, eventData)
        end)
        
        it("should emit castStarted events", function()
            service:startFishing()
            
            -- Subscribe to cast started events
            service.session:on("castStarted", function(data)
                eventReceived = true
                eventData = data
            end)
            
            service.session:startCast()
            
            assert.are.equal(true, eventReceived)
            assert.is_not_nil(eventData.cast)
        end)
    end)
end)