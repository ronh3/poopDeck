-- Fishing Service
-- Manages fishing automation, sessions, and state

poopDeck.services = poopDeck.services or {}

-- FishingService class definition
poopDeck.services.FishingService = poopDeck.core.BaseClass:extend("FishingService")

function poopDeck.services.FishingService:initialize(config)
    config = config or {}
    
    -- Service configuration
    self.settings = {
        enabled = config.enabled or false,
        autoRestart = config.autoRestart or true,
        defaultBait = config.defaultBait or "bass",
        defaultHook = config.defaultHook or "medium",
        baitSource = config.baitSource or "tank",  -- tank, inventory, fishbucket
        maxRetries = config.maxRetries or 3,
        retryDelay = config.retryDelay or 5,
        debugMode = config.debugMode or false
    }
    
    -- Current session management
    self.currentSession = nil
    self.sessionHistory = {}
    self.isActive = false
    
    -- Equipment tracking
    self.equipment = {
        availableCastDistances = {"short", "medium", "long"},
        availableBaitSources = {"tank", "inventory", "fishbucket"},
        currentBait = self.settings.defaultBait,
        currentBaitSource = self.settings.baitSource,
        currentCastDistance = self.settings.defaultHook  -- Still using defaultHook internally for compatibility
    }
    
    -- Automation state
    self.automation = {
        restartAttempts = 0,
        lastRestartTime = nil,
        pendingRestart = false,
        restartTimer = nil
    }
    
    -- Statistics (will be loaded from config if available)
    self.stats = {
        totalSessions = 0,
        totalCasts = 0,
        totalCatches = 0,
        totalEscapes = 0,
        longestSession = 0,
        bestCatchRate = 0,
        allTimeBestSession = nil,
        firstFishingDate = nil,
        lastFishingDate = nil
    }
    
    -- Recent sessions summary (keep last 10 sessions)
    self.recentSessionsSummary = {}
end

-- Session management
function poopDeck.services.FishingService:startFishing(config)
    if self.isActive and self.currentSession then
        return false, "Fishing session already active"
    end
    
    config = config or {}
    config.baitType = config.baitType or self.settings.defaultBait
    config.castDistance = config.castDistance or self.settings.defaultHook
    config.autoRestart = self.settings.autoRestart
    
    -- Create new session
    self.currentSession = poopDeck.domain.FishingSession(config)
    self.isActive = true
    self.stats.totalSessions = self.stats.totalSessions + 1
    
    -- Set up session event handlers
    self:setupSessionHandlers()
    
    -- Start the session
    local success, msg = self.currentSession:startFishing()
    if success then
        self:executeCastSequence()
    end
    
    self:emit("fishingStarted", {
        session = self.currentSession,
        config = config
    })
    
    return success, msg
end

function poopDeck.services.FishingService:stopFishing(reason)
    if not self.isActive or not self.currentSession then
        return false, "No active fishing session"
    end
    
    -- Clean up timers
    if self.automation.restartTimer then
        killTimer(self.automation.restartTimer)
        self.automation.restartTimer = nil
    end
    
    -- End session
    local success, msg = self.currentSession:endSession(reason or "manual_stop")
    
    -- Archive session
    table.insert(self.sessionHistory, self.currentSession)
    
    -- Create session summary for recent sessions
    self:archiveSessionSummary()
    
    -- Update service stats
    self:updateServiceStats()
    
    -- Reset state
    self.currentSession = nil
    self.isActive = false
    self.automation.restartAttempts = 0
    self.automation.pendingRestart = false
    
    self:emit("fishingStopped", {
        reason = reason,
        stats = self.stats
    })
    
    return success, msg
end

function poopDeck.services.FishingService:setupSessionHandlers()
    if not self.currentSession then return end
    
    -- Handle fish escaping
    self.currentSession:on("fishEscaped", function(session, data)
        self:handleFishEscaped(data)
    end)
    
    -- Handle successful catches
    self.currentSession:on("fishCaught", function(session, data)
        self:handleFishCaught(data)
    end)
    
    -- Handle phase changes for automation
    self.currentSession:on("phaseChanged", function(session, data)
        self:handlePhaseChange(data)
    end)
    
    -- Handle session events for logging
    self.currentSession:on("fishNibbling", function(session, data)
        self:handleFishNibbling(data)
    end)
    
    self.currentSession:on("fishHooked", function(session, data)
        self:handleFishHooked(data)
    end)
end

-- Event handlers for automation
function poopDeck.services.FishingService:handleFishEscaped(data)
    self.stats.totalEscapes = self.stats.totalEscapes + 1
    
    if self.settings.debugMode then
        poopDeck.badEcho("Fish escaped: " .. (data.reason or "unknown"))
    end
    
    -- Auto-restart if enabled
    if data.shouldRestart and self.settings.autoRestart then
        self:scheduleRestart("fish_escaped")
    else
        self:stopFishing("fish_escaped")
    end
    
    self:emit("fishEscaped", data)
end

function poopDeck.services.FishingService:handleFishCaught(data)
    self.stats.totalCatches = self.stats.totalCatches + 1
    
    if self.settings.debugMode then
        poopDeck.goodEcho("Caught: " .. data.fish.type)
    end
    
    -- Continue fishing if auto-restart is enabled
    if self.settings.autoRestart then
        self:scheduleRestart("fish_caught", 2) -- Short delay after success
    else
        self:stopFishing("fish_caught")
    end
    
    self:emit("fishCaught", data)
end

function poopDeck.services.FishingService:handleFishNibbling(data)
    -- Automatically tease the line
    poopDeck.safe.call(function()
        tempTimer(2, function()
            poopDeck.safe.send("tease line", "fishing_tease")
        end)
    end, "fishing_nibble_response")
end

function poopDeck.services.FishingService:handleFishHooked(data)
    -- Automatically start reeling sequence
    if self.currentSession then
        self.currentSession:startReeling()
    end
end

function poopDeck.services.FishingService:handlePhaseChange(data)
    if self.settings.debugMode then
        poopDeck.smallGoodEcho("Fishing phase: " .. data.from .. " → " .. data.to)
    end
    
    -- Handle automation based on phase changes
    if data.to == "idle" and self.settings.autoRestart then
        -- Session went idle unexpectedly, try to restart
        self:scheduleRestart("phase_idle")
    end
end

-- Automation methods
function poopDeck.services.FishingService:scheduleRestart(reason, delay)
    if self.automation.pendingRestart then
        return false, "Restart already pending"
    end
    
    delay = delay or self.settings.retryDelay
    
    if self.automation.restartAttempts >= self.settings.maxRetries then
        poopDeck.badEcho("Max restart attempts reached, stopping fishing")
        self:stopFishing("max_retries_reached")
        return false, "Max retries reached"
    end
    
    self.automation.pendingRestart = true
    self.automation.restartAttempts = self.automation.restartAttempts + 1
    self.automation.lastRestartTime = os.time()
    
    if self.settings.debugMode then
        poopDeck.settingEcho(string.format("Scheduling restart in %ds (attempt %d/%d, reason: %s)", 
            delay, self.automation.restartAttempts, self.settings.maxRetries, reason))
    end
    
    self.automation.restartTimer = tempTimer(delay, function()
        self:executeRestart(reason)
    end)
    
    return true, "Restart scheduled"
end

function poopDeck.services.FishingService:executeRestart(reason)
    if not self.automation.pendingRestart then
        return false, "No restart pending"
    end
    
    self.automation.pendingRestart = false
    self.automation.restartTimer = nil
    
    if self.settings.debugMode then
        poopDeck.settingEcho("Restarting fishing (reason: " .. reason .. ")")
    end
    
    -- Execute the casting sequence
    self:executeCastSequence()
    
    -- Reset session to waiting state
    if self.currentSession then
        self.currentSession:setState("waiting")
    end
    
    return true, "Fishing restarted"
end

-- Game command execution
function poopDeck.services.FishingService:executeCastSequence()
    poopDeck.safe.call(function()
        -- Build commands based on bait source
        local commands = {}
        
        -- Get bait command varies by source
        if self.equipment.currentBaitSource == "tank" then
            table.insert(commands, "queue addclearfull freestand get " .. self.equipment.currentBait .. " from tank here")
        elseif self.equipment.currentBaitSource == "fishbucket" then
            table.insert(commands, "queue addclearfull freestand get " .. self.equipment.currentBait .. " from fishbucket")
        elseif self.equipment.currentBaitSource == "inventory" then
            -- No get command needed for inventory items
        else
            -- Default to tank if unknown source
            table.insert(commands, "queue addclearfull freestand get " .. self.equipment.currentBait .. " from tank here")
        end
        
        -- Bait hook command varies by source
        if self.equipment.currentBaitSource == "tank" then
            table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait .. " from tank")
        elseif self.equipment.currentBaitSource == "fishbucket" then
            table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait .. " from fishbucket")
        elseif self.equipment.currentBaitSource == "inventory" then
            table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait)
        else
            -- Default to tank
            table.insert(commands, "queue add freestand bait hook with " .. self.equipment.currentBait .. " from tank")
        end
        
        -- Cast line command is always the same
        table.insert(commands, "queue add freestand cast line " .. self.equipment.currentCastDistance)
        
        sendAll(table.unpack(commands))
        
        -- Update session state
        if self.currentSession then
            self.currentSession:castLine()
        end
        
        self.stats.totalCasts = self.stats.totalCasts + 1
        
    end, "fishing_cast_sequence")
end

-- Game event handlers (called by triggers)
function poopDeck.services.FishingService:onLineTeased()
    if not self.isActive or not self.currentSession then return end
    
    -- Fish is nibbling, handle in session
    self.currentSession:fishNibble("unknown")
end

function poopDeck.services.FishingService:onLargeStrike()
    if not self.isActive or not self.currentSession then return end
    
    -- Large strike requires jerking the pole
    poopDeck.safe.call(function()
        tempTimer(3.34, function()
            poopDeck.safe.send("jerk pole", "fishing_jerk_1")
        end)
        tempTimer(1.67, function() 
            poopDeck.safe.send("jerk pole", "fishing_jerk_2")
        end)
        poopDeck.safe.send("jerk pole", "fishing_jerk_immediate")
    end, "fishing_large_strike")
end

function poopDeck.services.FishingService:onFishHooked(fishType, size)
    if not self.isActive or not self.currentSession then return end
    
    self.currentSession:fishHooked(fishType, size)
end

function poopDeck.services.FishingService:onReadyToReel()
    if not self.isActive or not self.currentSession then return end
    
    poopDeck.safe.call(function()
        poopDeck.safe.send("reel line", "fishing_reel")
    end, "fishing_reel_command")
end

function poopDeck.services.FishingService:onFishCaught(fishData)
    if not self.isActive or not self.currentSession then return end
    
    self.currentSession:fishCaught(fishData)
end

function poopDeck.services.FishingService:onFishEscaped(reason)
    if not self.isActive or not self.currentSession then return end
    
    self.currentSession:fishEscaped(reason or "unknown")
end

-- Configuration management
function poopDeck.services.FishingService:setBait(baitType)
    -- Accept any bait type - no validation needed
    if not baitType or baitType == "" then
        return false, "Bait type required"
    end
    
    self.equipment.currentBait = baitType
    self.settings.defaultBait = baitType
    
    return true, "Bait set to: " .. baitType
end

function poopDeck.services.FishingService:setCastDistance(castDistance) 
    local function contains(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then return true end
        end
        return false
    end
    
    if not contains(self.equipment.availableCastDistances, castDistance) then
        return false, "Invalid cast distance: " .. castDistance
    end
    
    self.equipment.currentCastDistance = castDistance
    self.settings.defaultHook = castDistance  -- Still using defaultHook internally for compatibility
    
    return true, "Cast distance set to: " .. castDistance
end

-- Legacy function name for backward compatibility
function poopDeck.services.FishingService:setHook(hookType)
    return self:setCastDistance(hookType)
end

function poopDeck.services.FishingService:setBaitSource(baitSource)
    local function contains(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then return true end
        end
        return false
    end
    
    if not contains(self.equipment.availableBaitSources, baitSource) then
        return false, "Invalid bait source: " .. baitSource .. ". Available: tank, inventory, fishbucket"
    end
    
    self.equipment.currentBaitSource = baitSource
    self.settings.baitSource = baitSource
    
    return true, "Bait source set to: " .. baitSource
end

function poopDeck.services.FishingService:toggleAutoRestart()
    self.settings.autoRestart = not self.settings.autoRestart
    return true, "Auto-restart " .. (self.settings.autoRestart and "enabled" or "disabled")
end

function poopDeck.services.FishingService:enable()
    self.settings.enabled = true
    self:emit("enabled")
    return true, "Fishing service enabled"
end

function poopDeck.services.FishingService:disable()
    if self.isActive then
        self:stopFishing("service_disabled")
    end
    
    self.settings.enabled = false
    self:emit("disabled")
    return true, "Fishing service disabled"
end

-- Archive session summary for recent sessions tracking
function poopDeck.services.FishingService:archiveSessionSummary()
    if not self.currentSession then return end
    
    local session = self.currentSession
    local duration = os.time() - session.startTime
    local catchRate = session.stats.casts > 0 and (session.stats.catches / session.stats.casts) * 100 or 0
    
    local summary = {
        id = session.id,
        date = os.date("%Y-%m-%d %H:%M", session.startTime),
        duration = duration,
        casts = session.stats.casts,
        catches = session.stats.catches,
        escapes = session.stats.escapes,
        catchRate = catchRate,
        baitUsed = session.baitType,
        castUsed = session.castDistance or session.hookType,
        location = session.location,
        endReason = session.state.phase == "complete" and "completed" or "interrupted"
    }
    
    -- Add to recent sessions (keep only last 10)
    table.insert(self.recentSessionsSummary, 1, summary)
    if #self.recentSessionsSummary > 10 then
        table.remove(self.recentSessionsSummary, 11)
    end
end

-- Statistics and reporting  
function poopDeck.services.FishingService:updateServiceStats()
    if not self.currentSession then return end
    
    local sessionStats = self.currentSession.stats
    local duration = os.time() - self.currentSession.startTime
    local catchRate = sessionStats.casts > 0 and (sessionStats.catches / sessionStats.casts) * 100 or 0
    
    -- Update date tracking
    if not self.stats.firstFishingDate then
        self.stats.firstFishingDate = self.currentSession.startTime
    end
    self.stats.lastFishingDate = os.time()
    
    -- Update totals
    self.stats.totalCasts = self.stats.totalCasts + sessionStats.casts
    self.stats.totalCatches = self.stats.totalCatches + sessionStats.catches  
    self.stats.totalEscapes = self.stats.totalEscapes + sessionStats.escapes
    
    -- Update bests
    if duration > self.stats.longestSession then
        self.stats.longestSession = duration
        self.stats.allTimeBestSession = {
            duration = duration,
            catches = sessionStats.catches,
            casts = sessionStats.casts,
            catchRate = catchRate,
            date = os.date("%Y-%m-%d %H:%M", self.currentSession.startTime)
        }
    end
    
    if catchRate > self.stats.bestCatchRate then
        self.stats.bestCatchRate = catchRate
    end
    
    -- Save configuration after each session
    if poopDeck.session then
        poopDeck.session:saveConfig()
    end
end

function poopDeck.services.FishingService:getStatus()
    local status = {
        enabled = self.settings.enabled,
        isActive = self.isActive,
        autoRestart = self.settings.autoRestart,
        currentBait = self.equipment.currentBait,
        currentHook = self.equipment.currentHook,
        stats = self.stats
    }
    
    if self.currentSession then
        status.currentSession = self.currentSession:getStatus()
    end
    
    return status
end

function poopDeck.services.FishingService:showStats()
    local status = self:getStatus()
    
    echo("\n<yellow>===== Fishing Statistics =====</yellow>\n")
    echo(string.format("Service: %s\n", status.enabled and "ENABLED" or "DISABLED"))
    echo(string.format("Auto-restart: %s\n", status.autoRestart and "ON" or "OFF"))
    echo(string.format("Current bait: %s\n", status.currentBait))
    echo(string.format("Current bait source: %s\n", self.equipment.currentBaitSource))
    echo(string.format("Current cast distance: %s\n", self.equipment.currentCastDistance))
    echo("\n")
    
    -- All-time statistics
    echo("<cyan>All-Time Statistics:</cyan>\n")
    echo(string.format("Total sessions: %d\n", status.stats.totalSessions))
    echo(string.format("Total casts: %d\n", status.stats.totalCasts))
    echo(string.format("Total catches: %d\n", status.stats.totalCatches))
    echo(string.format("Total escapes: %d\n", status.stats.totalEscapes))
    
    if status.stats.totalCasts > 0 then
        local overallRate = (status.stats.totalCatches / status.stats.totalCasts) * 100
        echo(string.format("Overall catch rate: %.1f%%\n", overallRate))
        echo(string.format("Best session catch rate: %.1f%%\n", status.stats.bestCatchRate))
    end
    
    if status.stats.longestSession > 0 then
        echo(string.format("Longest session: %d seconds\n", status.stats.longestSession))
    end
    
    -- Date range
    if self.stats.firstFishingDate and self.stats.lastFishingDate then
        local daysSince = math.floor((os.time() - self.stats.firstFishingDate) / 86400)
        echo(string.format("Fishing since: %s (%d days ago)\n", 
            os.date("%Y-%m-%d", self.stats.firstFishingDate), daysSince))
        echo(string.format("Last fished: %s\n", os.date("%Y-%m-%d %H:%M", self.stats.lastFishingDate)))
    end
    
    -- Best session details
    if self.stats.allTimeBestSession then
        echo("\n<cyan>Best Session Ever:</cyan>\n")
        local best = self.stats.allTimeBestSession
        echo(string.format("Date: %s\n", best.date))
        echo(string.format("Duration: %d seconds\n", best.duration))
        echo(string.format("Catches: %d (from %d casts, %.1f%% rate)\n", 
            best.catches, best.casts, best.catchRate))
    end
    
    -- Current session
    if status.currentSession then
        echo("\n<cyan>Current Session:</cyan>\n")
        local session = status.currentSession
        echo(string.format("Phase: %s\n", session.phase))
        echo(string.format("Duration: %d seconds\n", session.duration))
        echo(string.format("Casts: %d\n", session.stats.casts))
        echo(string.format("Catches: %d\n", session.stats.catches))
        echo(string.format("Escapes: %d\n", session.stats.escapes))
        
        if session.stats.casts > 0 then
            local currentRate = (session.stats.catches / session.stats.casts) * 100
            echo(string.format("Current rate: %.1f%%\n", currentRate))
        end
    end
    
    -- Recent sessions
    if #self.recentSessionsSummary > 0 then
        echo("\n<cyan>Recent Sessions:</cyan>\n")
        for i, session in ipairs(self.recentSessionsSummary) do
            if i <= 5 then -- Show top 5 recent
                echo(string.format("%d. %s (%ds) - %d catches/%d casts (%.1f%%) [%s]\n",
                    i, session.date, session.duration, session.catches, 
                    session.casts, session.catchRate, session.endReason))
            end
        end
        if #self.recentSessionsSummary > 5 then
            echo(string.format("... and %d more recent sessions\n", 
                #self.recentSessionsSummary - 5))
        end
    end
    
    echo("<yellow>===============================</yellow>\n")
end

function poopDeck.services.FishingService:toString()
    return string.format("[FishingService: %s, Sessions: %d, Catches: %d]", 
        self.settings.enabled and "enabled" or "disabled",
        self.stats.totalSessions, 
        self.stats.totalCatches)
end