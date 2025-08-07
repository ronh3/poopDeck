-- Load spec helper
require('spec.spec_helper')

-- Navigation and ship management tests
describe("poopDeck Navigation and Ship Management", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.command = poopDeck.command or {}
        poopDeck.config = poopDeck.config or {}
        
        -- Mock ship state
        poopDeck.shipState = {
            docked = false,
            anchorRaised = true,
            plankRaised = true,
            sailSpeed = 0,
            direction = "north",
            commScreen = false,
            warnings = true,
            currentMaintenance = nil
        }
        
        -- Create ShipManagementService
        poopDeck.services.ShipManagementService = {
            new = function(self)
                local instance = setmetatable({}, {__index = self})
                instance.state = poopDeck.shipState
                instance.commandQueue = {}
                return instance
            end,
            
            -- Navigation commands
            dock = function(self, direction)
                if not direction then
                    return false, "Direction required for docking"
                end
                
                local validDirections = {"north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest", "up", "down"}
                local isValid = false
                for _, dir in ipairs(validDirections) do
                    if direction:lower() == dir then
                        isValid = true
                        break
                    end
                end
                
                if not isValid then
                    return false, "Invalid direction for docking"
                end
                
                send("dock " .. direction)
                self.state.docked = true
                return true, "Docking " .. direction
            end,
            
            castOff = function(self)
                if not self.state.docked then
                    return false, "Ship is not docked"
                end
                
                send("cast off")
                self.state.docked = false
                return true, "Cast off"
            end,
            
            startRowing = function(self)
                send("ship row")
                return true, "Started rowing"
            end,
            
            stopRowing = function(self)
                send("ship row stop")
                return true, "Stopped rowing"
            end,
            
            allStop = function(self)
                send("ship stop")
                self.state.sailSpeed = 0
                return true, "All stop"
            end,
            
            setSailSpeed = function(self, speed)
                local numSpeed = tonumber(speed)
                if not numSpeed or numSpeed < 0 or numSpeed > 100 then
                    return false, "Invalid sail speed. Must be 0-100"
                end
                
                send("ship sail " .. numSpeed)
                self.state.sailSpeed = numSpeed
                return true, "Sail speed set to " .. numSpeed
            end,
            
            turnShip = function(self, direction)
                if not direction then
                    return false, "Direction required for turning"
                end
                
                local validDirections = {"north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest"}
                local isValid = false
                for _, dir in ipairs(validDirections) do
                    if direction:lower() == dir then
                        isValid = true
                        break
                    end
                end
                
                if not isValid then
                    return false, "Invalid direction for turning"
                end
                
                send("ship turn " .. direction)
                self.state.direction = direction
                return true, "Turning " .. direction
            end,
            
            -- Anchor and plank operations
            lowerAnchor = function(self)
                if not self.state.anchorRaised then
                    return false, "Anchor is already lowered"
                end
                
                send("ship anchor lower")
                self.state.anchorRaised = false
                return true, "Anchor lowered"
            end,
            
            raiseAnchor = function(self)
                if self.state.anchorRaised then
                    return false, "Anchor is already raised"
                end
                
                send("ship anchor raise")
                self.state.anchorRaised = true
                return true, "Anchor raised"
            end,
            
            lowerPlank = function(self)
                if not self.state.plankRaised then
                    return false, "Plank is already lowered"
                end
                
                send("ship plank lower")
                self.state.plankRaised = false
                return true, "Plank lowered"
            end,
            
            raisePlank = function(self)
                if self.state.plankRaised then
                    return false, "Plank is already raised"
                end
                
                send("ship plank raise")
                self.state.plankRaised = true
                return true, "Plank raised"
            end,
            
            -- Maintenance operations
            maintainHull = function(self)
                send("ship maintain hull")
                self.state.currentMaintenance = "hull"
                return true, "Maintaining hull"
            end,
            
            maintainSails = function(self)
                send("ship maintain sails")
                self.state.currentMaintenance = "sails"
                return true, "Maintaining sails"
            end,
            
            maintainNothing = function(self)
                send("ship maintain nothing")
                self.state.currentMaintenance = nil
                return true, "Stopped maintenance"
            end,
            
            repairShip = function(self)
                sendAll("ship repair hull", "ship repair sails")
                return true, "Repairing hull and sails"
            end,
            
            -- Communication and warnings
            toggleCommScreen = function(self, state)
                if state == "on" then
                    send("ship comm on")
                    self.state.commScreen = true
                    return true, "Communication screen on"
                elseif state == "off" then
                    send("ship comm off")
                    self.state.commScreen = false
                    return true, "Communication screen off"
                else
                    -- Toggle
                    if self.state.commScreen then
                        return self:toggleCommScreen("off")
                    else
                        return self:toggleCommScreen("on")
                    end
                end
            end,
            
            toggleWarnings = function(self, state)
                if state == "on" then
                    send("ship warnings on")
                    self.state.warnings = true
                    return true, "Ship warnings on"
                elseif state == "off" then
                    send("ship warnings off")
                    self.state.warnings = false
                    return true, "Ship warnings off"
                else
                    -- Toggle
                    if self.state.warnings then
                        return self:toggleWarnings("off")
                    else
                        return self:toggleWarnings("on")
                    end
                end
            end,
            
            -- Emergency operations
            chopRopes = function(self)
                send("chop ropes")
                return true, "Chopping ropes"
            end,
            
            clearRigging = function(self)
                send("clear rigging")
                return true, "Clearing rigging"
            end,
            
            douseSelf = function(self)
                send("fill bucket")
                send("douse me with bucket")
                return true, "Dousing self with bucket"
            end,
            
            douseRoom = function(self)
                send("fill bucket")
                send("douse room with bucket")
                return true, "Dousing room with bucket"
            end,
            
            useRainstorm = function(self)
                send("rainstorm")
                return true, "Using rainstorm to put out fires"
            end,
            
            shipRescue = function(self)
                send("ship rescue")
                return true, "Using ship rescue token"
            end,
            
            wavecall = function(self, direction, spaces)
                if not direction then
                    return false, "Direction required for wavecall"
                end
                
                local numSpaces = tonumber(spaces) or 1
                if numSpaces < 1 or numSpaces > 10 then
                    return false, "Invalid space count. Must be 1-10"
                end
                
                send("wavecall " .. direction .. " " .. numSpaces)
                return true, "Wavecall " .. direction .. " " .. numSpaces .. " spaces"
            end,
            
            -- State queries
            getShipState = function(self)
                return {
                    docked = self.state.docked,
                    anchorRaised = self.state.anchorRaised,
                    plankRaised = self.state.plankRaised,
                    sailSpeed = self.state.sailSpeed,
                    direction = self.state.direction,
                    commScreen = self.state.commScreen,
                    warnings = self.state.warnings,
                    currentMaintenance = self.state.currentMaintenance
                }
            end
        }
        
        -- Create command handlers
        poopDeck.command.dock = function(direction)
            local service = poopDeck.services.shipManagement
            if not service then
                poopDeck.badEcho("Ship management service not available")
                return false
            end
            
            local success, message = service:dock(direction)
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        poopDeck.command.scast = function()
            local service = poopDeck.services.shipManagement
            local success, message = service:castOff()
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        poopDeck.command.srow = function()
            local service = poopDeck.services.shipManagement
            local success, message = service:startRowing()
            poopDeck.goodEcho(message)
            return success
        end
        
        poopDeck.command.sreo = function()
            local service = poopDeck.services.shipManagement
            local success, message = service:stopRowing()
            poopDeck.goodEcho(message)
            return success
        end
        
        poopDeck.command.sstop = function()
            local service = poopDeck.services.shipManagement
            local success, message = service:allStop()
            poopDeck.goodEcho(message)
            return success
        end
        
        poopDeck.command.sss = function(speed)
            local service = poopDeck.services.shipManagement
            local success, message = service:setSailSpeed(speed)
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        poopDeck.command.stt = function(direction)
            local service = poopDeck.services.shipManagement
            local success, message = service:turnShip(direction)
            if success then
                poopDeck.goodEcho(message)
            else
                poopDeck.badEcho(message)
            end
            return success
        end
        
        -- Initialize service
        poopDeck.services.shipManagement = poopDeck.services.ShipManagementService:new()
        
        -- Mock functions
        send = function(cmd) 
            _G.lastSentCommand = cmd
            _G.allSentCommands = _G.allSentCommands or {}
            table.insert(_G.allSentCommands, cmd)
        end
        
        sendAll = function(...)
            _G.lastSentCommands = {...}
            _G.allSentCommands = _G.allSentCommands or {}
            for _, cmd in ipairs({...}) do
                table.insert(_G.allSentCommands, cmd)
            end
        end
        
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
        end
        
        -- Clear test state
        _G.lastSentCommand = nil
        _G.lastSentCommands = nil
        _G.allSentCommands = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
    end)
    
    describe("Navigation operations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should dock in valid directions", function()
            local success, message = service:dock("north")
            
            assert.are.equal(true, success)
            assert.are.equal("Docking north", message)
            assert.are.equal("dock north", _G.lastSentCommand)
            assert.are.equal(true, service.state.docked)
        end)
        
        it("should reject invalid dock directions", function()
            local success, message = service:dock("invalid")
            
            assert.are.equal(false, success)
            assert.are.equal("Invalid direction for docking", message)
            assert.is_nil(_G.lastSentCommand)
        end)
        
        it("should require direction for docking", function()
            local success, message = service:dock()
            
            assert.are.equal(false, success)
            assert.are.equal("Direction required for docking", message)
        end)
        
        it("should cast off when docked", function()
            service.state.docked = true
            
            local success, message = service:castOff()
            
            assert.are.equal(true, success)
            assert.are.equal("Cast off", message)
            assert.are.equal("cast off", _G.lastSentCommand)
            assert.are.equal(false, service.state.docked)
        end)
        
        it("should not cast off when not docked", function()
            service.state.docked = false
            
            local success, message = service:castOff()
            
            assert.are.equal(false, success)
            assert.are.equal("Ship is not docked", message)
        end)
        
        it("should start and stop rowing", function()
            local success1, message1 = service:startRowing()
            assert.are.equal(true, success1)
            assert.are.equal("ship row", _G.lastSentCommand)
            
            local success2, message2 = service:stopRowing()
            assert.are.equal(true, success2)
            assert.are.equal("ship row stop", _G.lastSentCommand)
        end)
        
        it("should execute all stop", function()
            service.state.sailSpeed = 50
            
            local success, message = service:allStop()
            
            assert.are.equal(true, success)
            assert.are.equal("ship stop", _G.lastSentCommand)
            assert.are.equal(0, service.state.sailSpeed)
        end)
        
        it("should set valid sail speeds", function()
            local success, message = service:setSailSpeed(75)
            
            assert.are.equal(true, success)
            assert.are.equal("Sail speed set to 75", message)
            assert.are.equal("ship sail 75", _G.lastSentCommand)
            assert.are.equal(75, service.state.sailSpeed)
        end)
        
        it("should reject invalid sail speeds", function()
            local success1, message1 = service:setSailSpeed(-10)
            assert.are.equal(false, success1)
            assert.truthy(message1:match("Invalid sail speed"))
            
            local success2, message2 = service:setSailSpeed(150)
            assert.are.equal(false, success2)
            
            local success3, message3 = service:setSailSpeed("invalid")
            assert.are.equal(false, success3)
        end)
        
        it("should turn ship in valid directions", function()
            local success, message = service:turnShip("southeast")
            
            assert.are.equal(true, success)
            assert.are.equal("Turning southeast", message)
            assert.are.equal("ship turn southeast", _G.lastSentCommand)
            assert.are.equal("southeast", service.state.direction)
        end)
        
        it("should reject invalid turn directions", function()
            local success, message = service:turnShip("invalid")
            
            assert.are.equal(false, success)
            assert.are.equal("Invalid direction for turning", message)
        end)
    end)
    
    describe("Anchor and plank operations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should lower and raise anchor", function()
            -- Lower anchor
            service.state.anchorRaised = true
            local success1, message1 = service:lowerAnchor()
            assert.are.equal(true, success1)
            assert.are.equal("ship anchor lower", _G.lastSentCommand)
            assert.are.equal(false, service.state.anchorRaised)
            
            -- Raise anchor
            local success2, message2 = service:raiseAnchor()
            assert.are.equal(true, success2)
            assert.are.equal("ship anchor raise", _G.lastSentCommand)
            assert.are.equal(true, service.state.anchorRaised)
        end)
        
        it("should not lower already lowered anchor", function()
            service.state.anchorRaised = false
            
            local success, message = service:lowerAnchor()
            
            assert.are.equal(false, success)
            assert.are.equal("Anchor is already lowered", message)
        end)
        
        it("should not raise already raised anchor", function()
            service.state.anchorRaised = true
            
            local success, message = service:raiseAnchor()
            
            assert.are.equal(false, success)
            assert.are.equal("Anchor is already raised", message)
        end)
        
        it("should lower and raise plank", function()
            -- Lower plank
            service.state.plankRaised = true
            local success1, message1 = service:lowerPlank()
            assert.are.equal(true, success1)
            assert.are.equal("ship plank lower", _G.lastSentCommand)
            assert.are.equal(false, service.state.plankRaised)
            
            -- Raise plank
            local success2, message2 = service:raisePlank()
            assert.are.equal(true, success2)
            assert.are.equal("ship plank raise", _G.lastSentCommand)
            assert.are.equal(true, service.state.plankRaised)
        end)
    end)
    
    describe("Maintenance operations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should maintain hull", function()
            local success, message = service:maintainHull()
            
            assert.are.equal(true, success)
            assert.are.equal("ship maintain hull", _G.lastSentCommand)
            assert.are.equal("hull", service.state.currentMaintenance)
        end)
        
        it("should maintain sails", function()
            local success, message = service:maintainSails()
            
            assert.are.equal(true, success)
            assert.are.equal("ship maintain sails", _G.lastSentCommand)
            assert.are.equal("sails", service.state.currentMaintenance)
        end)
        
        it("should stop maintenance", function()
            service.state.currentMaintenance = "hull"
            
            local success, message = service:maintainNothing()
            
            assert.are.equal(true, success)
            assert.are.equal("ship maintain nothing", _G.lastSentCommand)
            assert.is_nil(service.state.currentMaintenance)
        end)
        
        it("should repair ship", function()
            local success, message = service:repairShip()
            
            assert.are.equal(true, success)
            assert.is_not_nil(_G.lastSentCommands)
            assert.are.equal("ship repair hull", _G.lastSentCommands[1])
            assert.are.equal("ship repair sails", _G.lastSentCommands[2])
        end)
    end)
    
    describe("Communication and warnings", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should turn comm screen on and off", function()
            local success1, message1 = service:toggleCommScreen("on")
            assert.are.equal(true, success1)
            assert.are.equal("ship comm on", _G.lastSentCommand)
            assert.are.equal(true, service.state.commScreen)
            
            local success2, message2 = service:toggleCommScreen("off")
            assert.are.equal(true, success2)
            assert.are.equal("ship comm off", _G.lastSentCommand)
            assert.are.equal(false, service.state.commScreen)
        end)
        
        it("should toggle comm screen when no parameter", function()
            service.state.commScreen = false
            
            local success, message = service:toggleCommScreen()
            
            assert.are.equal(true, success)
            assert.are.equal("ship comm on", _G.lastSentCommand)
            assert.are.equal(true, service.state.commScreen)
        end)
        
        it("should toggle warnings", function()
            local success1, message1 = service:toggleWarnings("off")
            assert.are.equal(true, success1)
            assert.are.equal("ship warnings off", _G.lastSentCommand)
            assert.are.equal(false, service.state.warnings)
            
            local success2, message2 = service:toggleWarnings("on")
            assert.are.equal(true, success2)
            assert.are.equal("ship warnings on", _G.lastSentCommand)
            assert.are.equal(true, service.state.warnings)
        end)
    end)
    
    describe("Emergency operations", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should execute emergency commands", function()
            service:chopRopes()
            assert.are.equal("chop ropes", _G.lastSentCommand)
            
            service:clearRigging()
            assert.are.equal("clear rigging", _G.lastSentCommand)
            
            service:shipRescue()
            assert.are.equal("ship rescue", _G.lastSentCommand)
            
            service:useRainstorm()
            assert.are.equal("rainstorm", _G.lastSentCommand)
        end)
        
        it("should execute dousing operations", function()
            service:douseSelf()
            
            local commands = _G.allSentCommands
            assert.truthy(#commands >= 2)
            assert.are.equal("fill bucket", commands[#commands-1])
            assert.are.equal("douse me with bucket", commands[#commands])
        end)
        
        it("should execute wavecall with valid parameters", function()
            local success, message = service:wavecall("north", 5)
            
            assert.are.equal(true, success)
            assert.are.equal("wavecall north 5", _G.lastSentCommand)
            assert.truthy(message:match("Wavecall north 5 spaces"))
        end)
        
        it("should default wavecall spaces to 1", function()
            local success, message = service:wavecall("east")
            
            assert.are.equal(true, success)
            assert.are.equal("wavecall east 1", _G.lastSentCommand)
        end)
        
        it("should validate wavecall parameters", function()
            local success1, message1 = service:wavecall()
            assert.are.equal(false, success1)
            assert.truthy(message1:match("Direction required"))
            
            local success2, message2 = service:wavecall("north", 15)
            assert.are.equal(false, success2)
            assert.truthy(message2:match("Invalid space count"))
        end)
    end)
    
    describe("Command integration", function()
        it("should execute dock command", function()
            local result = poopDeck.command.dock("west")
            
            assert.are.equal(true, result)
            assert.are.equal("dock west", _G.lastSentCommand)
            assert.truthy(_G.lastGoodEcho:match("Docking west"))
        end)
        
        it("should execute navigation commands", function()
            poopDeck.command.scast()
            poopDeck.command.srow()
            poopDeck.command.sreo()
            poopDeck.command.sstop()
            
            -- Check that commands were executed
            assert.is_not_nil(_G.lastSentCommand)
        end)
        
        it("should execute sail speed command", function()
            local result = poopDeck.command.sss(50)
            
            assert.are.equal(true, result)
            assert.are.equal("ship sail 50", _G.lastSentCommand)
        end)
        
        it("should execute turn command", function()
            local result = poopDeck.command.stt("northeast")
            
            assert.are.equal(true, result)
            assert.are.equal("ship turn northeast", _G.lastSentCommand)
        end)
        
        it("should handle service unavailability", function()
            poopDeck.services.shipManagement = nil
            
            local result = poopDeck.command.dock("north")
            
            assert.are.equal(false, result)
            assert.truthy(_G.lastBadEcho:match("Ship management service not available"))
        end)
    end)
    
    describe("State management", function()
        local service
        
        before_each(function()
            service = poopDeck.services.shipManagement
        end)
        
        it("should track ship state accurately", function()
            -- Change various states
            service:dock("north")
            service:setSailSpeed(30)
            service:turnShip("east")
            service:maintainHull()
            service:toggleCommScreen("on")
            service:toggleWarnings("off")
            
            local state = service:getShipState()
            
            assert.are.equal(true, state.docked)
            assert.are.equal(30, state.sailSpeed)
            assert.are.equal("east", state.direction)
            assert.are.equal("hull", state.currentMaintenance)
            assert.are.equal(true, state.commScreen)
            assert.are.equal(false, state.warnings)
        end)
        
        it("should maintain consistent state across operations", function()
            local initialState = service:getShipState()
            
            -- Operations that should change state
            service:lowerAnchor()
            service:lowerPlank()
            
            local newState = service:getShipState()
            
            assert.are.equal(false, newState.anchorRaised)
            assert.are.equal(false, newState.plankRaised)
            
            -- Other states should remain unchanged
            assert.are.equal(initialState.docked, newState.docked)
            assert.are.equal(initialState.sailSpeed, newState.sailSpeed)
            assert.are.equal(initialState.commScreen, newState.commScreen)
        end)
    end)
end)