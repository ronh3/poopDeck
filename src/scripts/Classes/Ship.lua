-- Ship Class for poopDeck
-- Handles all ship navigation, state management, and operations using OOP pattern

local Ship = {}
Ship.__index = Ship

-- Constructor
function Ship:new(config)
    local self = setmetatable({}, Ship)
    
    -- Configuration
    self.config = config or {}
    self.name = self.config.name or "Unknown Vessel"
    
    -- Ship state
    self.state = {
        anchored = false,
        plankLowered = false,
        commScreenRaised = false,
        warningEnabled = false,
        currentSpeed = "stopped",      -- Sail setting (full/furl/strike/0-10)
        currentHeading = nil,           -- Direction ship is facing
        actualSpeed = 0,                -- Actual speed in knots from prompt
        windDirection = nil,            -- Wind direction from prompt
        windSpeed = 0,                  -- Wind speed in knots
        seaCondition = "calm",          -- Sea state (calm/choppy/rough/etc)
        isRowing = false,
        isDocked = false,
        dockedDirection = nil,
        isOnFire = false,
        needsMaintenance = false,
        hasBalance = true               -- Ship balance state
    }
    
    -- Command queue for handling balance
    self.commandQueue = {}
    self.processingQueue = false
    
    -- Ship health tracking
    self.health = {
        hull = 100,
        sails = 100,
        maxHealth = 100,
        -- Damage thresholds
        critical = 25,    -- Below this is critical damage
        warning = 50,     -- Below this triggers warnings
        good = 75        -- Above this is good condition
    }
    
    -- Maintenance tracking
    self.maintenance = {
        active = false,
        target = nil,  -- "hull", "sails", or "none"
        lastMaintained = nil
    }
    
    -- Direction mappings - more efficient lookup table
    self.directions = {
        e = "east",
        ene = "east-northeast",
        ese = "east-southeast", 
        n = "north",
        nnw = "north-northwest",
        nne = "north-northeast",
        ne = "northeast",
        nw = "northwest",
        s = "south",
        sse = "south-southeast",
        ssw = "south-southwest",
        se = "southeast", 
        sw = "southwest",
        w = "west",
        wnw = "west-northwest",
        wsw = "west-southwest"
    }
    
    -- Speed commands with validation
    self.speedCommands = {
        strike = "say strike sails!",
        furl = "say furl sails!",
        full = "say full sails!",
        relax = "say relax sails!"
    }
    
    -- Valid speed settings (for direct ship commands)
    self.validSpeeds = {
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "strike", "furl", "full", "relax"
    }
    
    -- Register event handlers
    self:registerEventHandlers()
    
    return self
end

-- Register for Mudlet events
function Ship:registerEventHandlers()
    local self = self  -- Capture self in closure
    
    -- Ship state change events
    registerAnonymousEventHandler("poopDeck.rigClear", function()
        self:onRiggingCleared()
    end)
    
    registerAnonymousEventHandler("poopDeck.shipMoved", function(event, newPosition)
        self:onMovement(newPosition)
    end)
    
    -- Damage/maintenance events
    registerAnonymousEventHandler("poopDeck.shipDamaged", function(event, damageType, severity)
        self:onDamage(damageType, severity)
    end)
    
    registerAnonymousEventHandler("poopDeck.fireDamage", function()
        self:onFire()
    end)
    
    -- Balance events - critical for command queueing
    -- Note: Balance recovery is triggered by the message:
    -- "The crew of your ship is now ready to execute another order."
    registerAnonymousEventHandler("poopDeck.shipBalanceLost", function()
        self:onBalanceLost()
    end)
end

-- Navigation Methods
function Ship:turn(heading)
    if not heading then
        error("Ship:turn() requires a heading parameter")
    end
    
    local direction = self.directions[heading:lower()]
    if not direction then
        error("Invalid heading: " .. tostring(heading))
    end
    
    self.state.currentHeading = direction
    send("say Bring her to the " .. direction .. "!")
    
    -- Assume balance is lost after sending command
    self:onBalanceLost()
    
    raiseEvent("poopDeck.shipTurning", direction, heading)
    return self  -- Method chaining
end

function Ship:setSpeed(speed)
    if not speed then
        error("Ship:setSpeed() requires a speed parameter")
    end
    
    local speedStr = tostring(speed):lower()
    local command = self.speedCommands[speedStr]
    
    if command then
        -- Named speed command
        send(command)
        self.state.currentSpeed = speedStr
    elseif self:isValidNumericSpeed(speedStr) then
        -- Numeric speed setting
        send("ship sails set " .. speedStr)
        self.state.currentSpeed = speedStr
    else
        error("Invalid speed setting: " .. speedStr)
    end
    
    -- Assume balance is lost after sending command
    self:onBalanceLost()
    
    raiseEvent("poopDeck.speedChanged", speedStr)
    return self
end

function Ship:isValidNumericSpeed(speed)
    for _, validSpeed in ipairs(self.validSpeeds) do
        if validSpeed == speed then
            return true
        end
    end
    return false
end

function Ship:allStop()
    send("say All stop!")
    self.state.currentSpeed = "stopped"
    self.state.isRowing = false
    
    raiseEvent("poopDeck.shipStopped")
    return self
end

-- Docking and Anchoring
function Ship:dock(direction)
    if not direction then
        error("Ship:dock() requires a direction parameter")
    end
    
    send("ship dock " .. direction .. " confirm")
    self.state.isDocked = true
    self.state.dockedDirection = direction
    
    raiseEvent("poopDeck.shipDocked", direction)
    return self
end

function Ship:anchor(action)
    if not action then
        action = self.state.anchored and "raise" or "drop"
    end
    
    if action:lower() == "raise" or action:lower() == "r" then
        send("say weigh anchor!")
        self.state.anchored = false
        raiseEvent("poopDeck.anchorRaised")
    else
        send("say drop the anchor!")
        self.state.anchored = true
        raiseEvent("poopDeck.anchorDropped")
    end
    
    return self
end

function Ship:castOff()
    send("say castoff!")
    self.state.isDocked = false
    self.state.dockedDirection = nil
    
    raiseEvent("poopDeck.castOff")
    return self
end

-- Ship Equipment Controls
function Ship:plank(action)
    if not action then
        action = self.state.plankLowered and "raise" or "lower"
    end
    
    if action:lower() == "raise" or action:lower() == "r" then
        send("say raise the plank!")
        self.state.plankLowered = false
        raiseEvent("poopDeck.plankRaised")
    else
        send("say lower the plank!")
        self.state.plankLowered = true
        raiseEvent("poopDeck.plankLowered")
    end
    
    return self
end

function Ship:commScreen(action)
    if not action then
        action = self.state.commScreenRaised and "lower" or "raise"
    end
    
    if action:lower() == "raise" then
        send("ship commscreen raise")
        self.state.commScreenRaised = true
        raiseEvent("poopDeck.commScreenRaised")
    else
        send("ship commscreen lower")
        self.state.commScreenRaised = false
        raiseEvent("poopDeck.commScreenLowered")
    end
    
    return self
end

function Ship:shipWarning(enabled)
    if enabled == nil then
        enabled = not self.state.warningEnabled
    end
    
    if enabled then
        send("shipwarning on")
        self.state.warningEnabled = true
        raiseEvent("poopDeck.warningEnabled")
    else
        send("shipwarning off") 
        self.state.warningEnabled = false
        raiseEvent("poopDeck.warningDisabled")
    end
    
    return self
end

-- Rowing Controls
function Ship:row()
    send("say row!")
    self.state.isRowing = true
    
    raiseEvent("poopDeck.rowingStarted")
    return self
end

function Ship:relaxOars()
    send("say stop rowing.")
    self.state.isRowing = false
    
    raiseEvent("poopDeck.rowingStopped")
    return self
end

-- Maintenance Operations
function Ship:maintain(what)
    local commands = {
        h = {cmd = "queue add freestand maintain hull", target = "hull"},
        hull = {cmd = "queue add freestand maintain hull", target = "hull"},
        s = {cmd = "queue add freestand maintain sails", target = "sails"}, 
        sails = {cmd = "queue add freestand maintain sails", target = "sails"},
        n = {cmd = "queue add freestand maintain none", target = "none"},
        none = {cmd = "queue add freestand maintain none", target = "none"}
    }
    
    local action = commands[what:lower()]
    if not action then
        error("Invalid maintenance target: " .. tostring(what))
    end
    
    -- Update maintenance tracking
    self.maintenance.active = action.target ~= "none"
    self.maintenance.target = action.target
    self.maintenance.lastMaintained = os.time()
    
    send(action.cmd)
    raiseEvent("poopDeck.maintenanceStarted", action.target)
    return self
end

function Ship:repairAll()
    send("ship repair all")
    -- Reset health to maximum
    self.health.hull = self.health.maxHealth
    self.health.sails = self.health.maxHealth
    self.state.needsMaintenance = false
    raiseEvent("poopDeck.repairsStarted")
    raiseEvent("poopDeck.healthRestored", "full")
    return self
end

-- Rigging Operations
function Ship:clearRigging()
    sendAll("queue add freestand climb rigging", "queue add freestand clear rigging")
    raiseEvent("poopDeck.riggingClearing")
    return self
end

function Ship:onRiggingCleared()
    send("queue add freestand climb rigging down")
    raiseEvent("poopDeck.riggingCleared")
end

-- Emergency Operations  
function Ship:rescue()
    sendAll("get token from pack", "ship rescue me")
    raiseEvent("poopDeck.rescueInitiated")
    return self
end

function Ship:chopTether()
    send("chop tether")
    raiseEvent("poopDeck.tetherChopped")
    return self
end

-- Fire Suppression
function Ship:douse(target)
    local commands = {
        r = {"queue add freestand fill bucket with water", "queue add freestand douse room"},
        room = {"queue add freestand fill bucket with water", "queue add freestand douse room"},
        m = {"queue add freestand fill bucket with water", "queue add freestand douse me"},
        me = {"queue add freestand fill bucket with water", "queue add freestand douse me"},  
        s = {"queue add freestand fill bucket with water", "queue add freestand douse sails"},
        sails = {"queue add freestand fill bucket with water", "queue add freestand douse sails"}
    }
    
    local commandSet = commands[target:lower()]
    if not commandSet then
        error("Invalid douse target: " .. tostring(target))
    end
    
    sendAll(unpack(commandSet))
    raiseEvent("poopDeck.dousingStarted", target)
    return self
end

-- Weather Abilities
function Ship:invokeRainstorm()
    send("invoke rainstorm")
    raiseEvent("poopDeck.rainstormInvoked")
    return self
end

function Ship:invokeWindboost()
    send("invoke windboost")
    raiseEvent("poopDeck.windboostInvoked") 
    return self
end

function Ship:wavecall(heading, distance)
    if not heading or not distance then
        error("Ship:wavecall() requires heading and distance parameters")
    end
    
    send("invoke wavecall " .. heading .. " " .. distance)
    raiseEvent("poopDeck.wavecallInvoked", heading, distance)
    return self
end

-- State Query Methods
function Ship:getState()
    -- Return a copy to prevent external modification
    local stateCopy = {}
    for k, v in pairs(self.state) do
        stateCopy[k] = v
    end
    return stateCopy
end

function Ship:isAnchored()
    return self.state.anchored
end

function Ship:isDocked()
    return self.state.isDocked
end

function Ship:isRowing()
    return self.state.isRowing
end

function Ship:getCurrentSpeed()
    return self.state.currentSpeed
end

function Ship:getCurrentHeading()
    return self.state.currentHeading
end

-- Prompt-Based Health Management
function Ship:updateHealthFromPrompt(sailsPercent, hullPercent)
    -- Store previous values to detect changes
    local prevHull = self.health.hull
    local prevSails = self.health.sails
    
    -- Update current values
    self.health.hull = hullPercent
    self.health.sails = sailsPercent
    
    -- Detect damage or repairs
    local hullChange = hullPercent - prevHull
    local sailsChange = sailsPercent - prevSails
    
    -- Raise appropriate events based on changes
    if hullChange < 0 then
        raiseEvent("poopDeck.shipTookDamage", "hull", math.abs(hullChange), hullPercent)
    elseif hullChange > 0 then
        raiseEvent("poopDeck.shipRepaired", "hull", hullChange, hullPercent)
    end
    
    if sailsChange < 0 then
        raiseEvent("poopDeck.shipTookDamage", "sails", math.abs(sailsChange), sailsPercent)
    elseif sailsChange > 0 then
        raiseEvent("poopDeck.shipRepaired", "sails", sailsChange, sailsPercent)
    end
    
    -- Check overall health status
    self:checkHealthStatus()
    return self
end

-- Parse ship prompt using named captures from trigger
-- Expects matches table with named captures: sails, sailhp, hullhp, winddir, windspeed, heading, speed, sea, row, sail, turn
function Ship:parsePromptMatches(promptMatches)
    -- Update sail setting
    if promptMatches.sails then
        self.state.currentSpeed = promptMatches.sails:lower()
    end
    
    -- Update health with change detection
    if promptMatches.sailhp and promptMatches.hullhp then
        self:updateHealthFromPrompt(tonumber(promptMatches.sailhp), tonumber(promptMatches.hullhp))
    end
    
    -- Update wind conditions
    if promptMatches.winddir and promptMatches.windspeed then
        local prevWindDir = self.state.windDirection
        local prevWindSpeed = self.state.windSpeed
        
        self.state.windDirection = promptMatches.winddir
        self.state.windSpeed = tonumber(promptMatches.windspeed)
        
        -- Only raise event if wind changed
        if prevWindDir ~= promptMatches.winddir or prevWindSpeed ~= self.state.windSpeed then
            raiseEvent("poopDeck.windUpdate", self.state.windDirection, self.state.windSpeed)
        end
    end
    
    -- Update course and actual speed
    if promptMatches.heading and promptMatches.speed then
        self.state.currentHeading = promptMatches.heading
        self.state.actualSpeed = tonumber(promptMatches.speed)
    end
    
    -- Update sea condition
    if promptMatches.sea then
        local prevSea = self.state.seaCondition
        self.state.seaCondition = promptMatches.sea:lower()
        
        if prevSea ~= self.state.seaCondition then
            raiseEvent("poopDeck.seaConditionUpdate", self.state.seaCondition)
        end
    end
    
    -- Handle optional modifiers
    self.state.isRowing = promptMatches.row ~= nil
    self.state.hasSailBoost = promptMatches.sail ~= nil
    
    -- Handle turning state
    if promptMatches.turn then
        self.state.isTurning = true
        self.state.turningTo = promptMatches.turn
        raiseEvent("poopDeck.shipTurning", promptMatches.turn)
    else
        self.state.isTurning = false
        self.state.turningTo = nil
    end
    
    -- Raise general prompt update event with all data
    raiseEvent("poopDeck.promptUpdate", promptMatches)
    
    return self
end

function Ship:getHealthPercent(component)
    if component == "hull" then
        return (self.health.hull / self.health.maxHealth) * 100
    elseif component == "sails" then
        return (self.health.sails / self.health.maxHealth) * 100
    else
        -- Return overall health average
        return ((self.health.hull + self.health.sails) / (self.health.maxHealth * 2)) * 100
    end
end

function Ship:checkHealthStatus()
    local hullPercent = self:getHealthPercent("hull")
    local sailPercent = self:getHealthPercent("sails")
    local overallPercent = self:getHealthPercent()
    
    -- Check for critical damage
    if hullPercent <= self.health.critical then
        raiseEvent("poopDeck.criticalDamage", "hull", hullPercent)
    end
    if sailPercent <= self.health.critical then
        raiseEvent("poopDeck.criticalDamage", "sails", sailPercent)
    end
    
    -- Check for warning levels
    if hullPercent <= self.health.warning and hullPercent > self.health.critical then
        raiseEvent("poopDeck.damageWarning", "hull", hullPercent)
    end
    if sailPercent <= self.health.warning and sailPercent > self.health.critical then
        raiseEvent("poopDeck.damageWarning", "sails", sailPercent)
    end
    
    -- Check if maintenance is still needed
    if overallPercent >= self.health.good then
        self.state.needsMaintenance = false
    end
    
    return overallPercent
end

function Ship:getHealthStatus()
    return {
        hull = self.health.hull,
        sails = self.health.sails,
        hullPercent = self:getHealthPercent("hull"),
        sailsPercent = self:getHealthPercent("sails"),
        overallPercent = self:getHealthPercent(),
        needsMaintenance = self.state.needsMaintenance,
        status = self:getHealthStatusText()
    }
end

function Ship:getHealthStatusText()
    local percent = self:getHealthPercent()
    if percent >= self.health.good then
        return "Good Condition"
    elseif percent >= self.health.warning then
        return "Minor Damage"
    elseif percent >= self.health.critical then
        return "Major Damage"
    else
        return "Critical Damage"
    end
end

-- Event handlers for state changes
function Ship:onMovement(newPosition)
    -- Update internal position tracking if needed
    self.state.currentPosition = newPosition
    raiseEvent("poopDeck.shipMoved", newPosition)
end

function Ship:onDamage(damageType, severity)
    -- Convert severity to damage amount if needed
    local damageAmount = severity or 10
    self:takeDamage(damageType, damageAmount)
end

function Ship:onFire()
    self.state.isOnFire = true
    -- Fire causes continuous damage to sails
    self:takeDamage("sails", 5)
    raiseEvent("poopDeck.shipOnFire")
end

-- Command Queue Management
function Ship:queueCommand(commandFunc, ...)
    -- Store the function and its arguments
    local args = {...}
    table.insert(self.commandQueue, {func = commandFunc, args = args})
    
    -- If we have balance and not processing, start processing
    if self.state.hasBalance and not self.processingQueue then
        self:processCommandQueue()
    end
    
    return self  -- Still allow chaining
end

function Ship:processCommandQueue()
    if #self.commandQueue == 0 then
        self.processingQueue = false
        return
    end
    
    if not self.state.hasBalance then
        -- Wait for balance
        return
    end
    
    self.processingQueue = true
    
    -- Get next command
    local command = table.remove(self.commandQueue, 1)
    
    -- Execute the command
    command.func(self, unpack(command.args))
    
    -- Will continue when balance is recovered
end

function Ship:onBalanceRecovered()
    self.state.hasBalance = true
    raiseEvent("poopDeck.shipBalanceRecovered")
    
    -- Process next queued command if any
    if #self.commandQueue > 0 then
        tempTimer(0.1, function() self:processCommandQueue() end)
    else
        self.processingQueue = false
    end
end

function Ship:onBalanceLost()
    self.state.hasBalance = false
    raiseEvent("poopDeck.shipBalanceLost")
end

-- Modified navigation methods to optionally use queue
function Ship:turnQueued(heading)
    return self:queueCommand(self.turn, heading)
end

function Ship:setSpeedQueued(speed)
    return self:queueCommand(self.setSpeed, speed)
end

function Ship:dockQueued(direction)
    return self:queueCommand(self.dock, direction)
end

-- Chain-friendly methods that use the queue
function Ship:chain()
    -- Returns a chainable object that queues commands
    local chain = {}
    local ship = self
    
    chain.turn = function(_, heading)
        ship:queueCommand(ship.turn, heading)
        return chain
    end
    
    chain.setSpeed = function(_, speed)
        ship:queueCommand(ship.setSpeed, speed)
        return chain
    end
    
    chain.dock = function(_, direction)
        ship:queueCommand(ship.dock, direction)
        return chain
    end
    
    chain.anchor = function(_, action)
        ship:queueCommand(ship.anchor, action)
        return chain
    end
    
    chain.castOff = function(_)
        ship:queueCommand(ship.castOff)
        return chain
    end
    
    chain.execute = function(_)
        -- Start processing the queue
        if ship.state.hasBalance then
            ship:processCommandQueue()
        end
    end
    
    return chain
end

-- Export the class
return Ship