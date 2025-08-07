-- Load spec helper
require('spec.spec_helper')

-- Command integration tests for poopDeck
describe("poopDeck Command Integration", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Mock SessionManager
        poopDeck.core.SessionManager = {
            new = function(self)
                local instance = setmetatable({}, {__index = self})
                instance.fishing = nil
                instance.notifications = nil
                instance.statusWindows = nil
                return instance
            end,
            getFishingService = function(self)
                return self.fishing
            end,
            getNotificationService = function(self)
                return self.notifications
            end,
            getStatusWindowService = function(self)
                return self.statusWindows
            end
        }
        
        -- Create session manager instance
        poopDeck.sessionManager = poopDeck.core.SessionManager:new()
        
        -- Mock fishing service
        local fishingService = {
            startFishing = function(self, bait, castDistance)
                _G.lastFishingCall = {
                    method = "startFishing",
                    bait = bait,
                    castDistance = castDistance
                }
                return true, "Fishing started"
            end,
            stopFishing = function(self)
                _G.lastFishingCall = {method = "stopFishing"}
                return true, "Fishing stopped"
            end,
            setBaitSource = function(self, source)
                _G.lastFishingCall = {
                    method = "setBaitSource",
                    source = source
                }
                return true
            end,
            setEnabled = function(self, enabled)
                _G.lastFishingCall = {
                    method = "setEnabled",
                    enabled = enabled
                }
            end,
            equipment = {
                currentBait = "bass",
                currentCastDistance = "medium",
                currentBaitSource = "tank"
            },
            config = {
                autoRestart = true
            },
            getStatistics = function(self)
                return {
                    totalCasts = 42,
                    totalCatches = 15,
                    escapes = 3,
                    sessionTime = 1800
                }
            end
        }
        
        poopDeck.sessionManager.fishing = fishingService
        
        -- Mock command functions (these would normally be defined in alias files)
        poopDeck.command = poopDeck.command or {}
        
        -- Fish command handler
        poopDeck.command.fish = function(bait, castDistance)
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            local success, message = service:startFishing(bait, castDistance)
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        -- Stop fishing command handler
        poopDeck.command.stopfish = function()
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            local success, message = service:stopFishing()
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        -- Fishing stats command handler
        poopDeck.command.fishstats = function()
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            local stats = service:getStatistics()
            poopDeck.goodEcho("=== Fishing Statistics ===")
            poopDeck.goodEcho("Total Casts: " .. stats.totalCasts)
            poopDeck.goodEcho("Total Catches: " .. stats.totalCatches)
            poopDeck.goodEcho("Fish Escaped: " .. stats.escapes)
            poopDeck.goodEcho("Session Time: " .. stats.sessionTime .. " seconds")
            return true
        end
        
        -- Bait source command handler
        poopDeck.command.fishsource = function(source)
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            if not source then
                poopDeck.badEcho("Current bait source: " .. service.equipment.currentBaitSource)
                return true
            end
            
            local success = service:setBaitSource(source)
            if success then
                poopDeck.goodEcho("Bait source set to: " .. source)
            else
                poopDeck.badEcho("Invalid bait source. Use: tank, inventory, or fishbucket")
            end
            return success
        end
        
        -- Fishing enable/disable command handlers
        poopDeck.command.fishenable = function()
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            service:setEnabled(true)
            poopDeck.goodEcho("Fishing service enabled")
            return true
        end
        
        poopDeck.command.fishdisable = function()
            local service = poopDeck.sessionManager:getFishingService()
            if not service then
                poopDeck.badEcho("Fishing service not available")
                return false
            end
            
            service:setEnabled(false)
            poopDeck.goodEcho("Fishing service disabled")
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
        _G.lastFishingCall = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
    end)
    
    describe("Fish command integration", function()
        it("should start fishing with default parameters", function()
            local result = poopDeck.command.fish()
            
            assert.are.equal(true, result)
            assert.is_not_nil(_G.lastFishingCall)
            assert.are.equal("startFishing", _G.lastFishingCall.method)
            assert.is_nil(_G.lastFishingCall.bait)
            assert.is_nil(_G.lastFishingCall.castDistance)
            assert.truthy(_G.lastGoodEcho:match("Fishing started"))
        end)
        
        it("should start fishing with custom bait", function()
            local result = poopDeck.command.fish("shrimp")
            
            assert.are.equal(true, result)
            assert.are.equal("shrimp", _G.lastFishingCall.bait)
            assert.is_nil(_G.lastFishingCall.castDistance)
        end)
        
        it("should start fishing with custom bait and cast distance", function()
            local result = poopDeck.command.fish("worms", "long")
            
            assert.are.equal(true, result)
            assert.are.equal("worms", _G.lastFishingCall.bait)
            assert.are.equal("long", _G.lastFishingCall.castDistance)
        end)
        
        it("should handle missing fishing service gracefully", function()
            poopDeck.sessionManager.fishing = nil
            
            local result = poopDeck.command.fish()
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Fishing service not available"))
        end)
    end)
    
    describe("Stop fishing command integration", function()
        it("should stop fishing successfully", function()
            local result = poopDeck.command.stopfish()
            
            assert.are.equal(true, result)
            assert.are.equal("stopFishing", _G.lastFishingCall.method)
            assert.truthy(_G.lastGoodEcho:match("Fishing stopped"))
        end)
        
        it("should handle missing fishing service", function()
            poopDeck.sessionManager.fishing = nil
            
            local result = poopDeck.command.stopfish()
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Fishing service not available"))
        end)
    end)
    
    describe("Fishing statistics command integration", function()
        it("should display comprehensive statistics", function()
            local result = poopDeck.command.fishstats()
            
            assert.are.equal(true, result)
            assert.truthy(_G.lastGoodEcho:match("Fishing Statistics"))
        end)
        
        it("should handle missing fishing service", function()
            poopDeck.sessionManager.fishing = nil
            
            local result = poopDeck.command.fishstats()
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Fishing service not available"))
        end)
    end)
    
    describe("Bait source command integration", function()
        it("should show current bait source when no parameter provided", function()
            local result = poopDeck.command.fishsource()
            
            assert.are.equal(true, result)
            assert.truthy(_G.lastBadEcho:match("Current bait source: tank"))
        end)
        
        it("should set valid bait source", function()
            local result = poopDeck.command.fishsource("inventory")
            
            assert.are.equal(true, result)
            assert.are.equal("setBaitSource", _G.lastFishingCall.method)
            assert.are.equal("inventory", _G.lastFishingCall.source)
            assert.truthy(_G.lastGoodEcho:match("Bait source set to: inventory"))
        end)
        
        it("should reject invalid bait source", function()
            -- Mock invalid response from service
            poopDeck.sessionManager.fishing.setBaitSource = function(self, source)
                return false
            end
            
            local result = poopDeck.command.fishsource("invalid")
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Invalid bait source"))
        end)
    end)
    
    describe("Fishing service management commands", function()
        it("should enable fishing service", function()
            local result = poopDeck.command.fishenable()
            
            assert.are.equal(true, result)
            assert.are.equal("setEnabled", _G.lastFishingCall.method)
            assert.are.equal(true, _G.lastFishingCall.enabled)
            assert.truthy(_G.lastGoodEcho:match("Fishing service enabled"))
        end)
        
        it("should disable fishing service", function()
            local result = poopDeck.command.fishdisable()
            
            assert.are.equal(true, result)
            assert.are.equal("setEnabled", _G.lastFishingCall.method)
            assert.are.equal(false, _G.lastFishingCall.enabled)
            assert.truthy(_G.lastGoodEcho:match("Fishing service disabled"))
        end)
    end)
    
    describe("Command parameter parsing", function()
        it("should handle nil parameters gracefully", function()
            local result = poopDeck.command.fish(nil, nil)
            
            assert.are.equal(true, result)
            assert.is_nil(_G.lastFishingCall.bait)
            assert.is_nil(_G.lastFishingCall.castDistance)
        end)
        
        it("should handle empty string parameters", function()
            local result = poopDeck.command.fish("", "")
            
            assert.are.equal(true, result)
            assert.are.equal("", _G.lastFishingCall.bait)
            assert.are.equal("", _G.lastFishingCall.castDistance)
        end)
        
        it("should handle whitespace-only parameters", function()
            local result = poopDeck.command.fish("  ", "  ")
            
            assert.are.equal(true, result)
            assert.are.equal("  ", _G.lastFishingCall.bait)
            assert.are.equal("  ", _G.lastFishingCall.castDistance)
        end)
    end)
    
    describe("Error handling in commands", function()
        it("should handle service method failures", function()
            -- Mock service failure
            poopDeck.sessionManager.fishing.startFishing = function(self, bait, castDistance)
                return false, "Service error occurred"
            end
            
            local result = poopDeck.command.fish()
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Service error occurred"))
        end)
        
        it("should handle service method exceptions", function()
            -- Mock service exception
            poopDeck.sessionManager.fishing.startFishing = function(self, bait, castDistance)
                error("Unexpected error")
            end
            
            -- Should not crash, but let's test graceful handling if implemented
            assert.has_error(function()
                poopDeck.command.fish()
            end)
        end)
    end)
    
    describe("Command chaining and state management", function()
        it("should allow starting and stopping fishing in sequence", function()
            local startResult = poopDeck.command.fish()
            local stopResult = poopDeck.command.stopfish()
            
            assert.are.equal(true, startResult)
            assert.are.equal(true, stopResult)
        end)
        
        it("should allow configuration changes", function()
            poopDeck.command.fishsource("inventory")
            local result = poopDeck.command.fish("shrimp", "long")
            
            assert.are.equal(true, result)
            assert.are.equal("inventory", _G.lastFishingCall.source)
        end)
        
        it("should allow service disable and enable", function()
            poopDeck.command.fishdisable()
            assert.are.equal(false, _G.lastFishingCall.enabled)
            
            poopDeck.command.fishenable()
            assert.are.equal(true, _G.lastFishingCall.enabled)
        end)
    end)
end)