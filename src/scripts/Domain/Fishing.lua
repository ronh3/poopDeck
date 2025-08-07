-- Fishing domain classes
-- Represents fishing sessions, equipment, and catches

poopDeck.domain = poopDeck.domain or {}

-- Fishing Session class - tracks a single fishing attempt
poopDeck.domain.FishingSession = poopDeck.core.BaseClass:extend("FishingSession")

function poopDeck.domain.FishingSession:initialize(config)
    config = config or {}
    
    -- Session identification
    self.id = os.time() .. "_" .. math.random(1000)
    self.startTime = os.time()
    self.endTime = nil
    
    -- Session configuration
    self.baitType = config.baitType or "bass"
    self.hookType = config.hookType or "medium"
    self.location = config.location or "unknown"
    self.autoRestart = config.autoRestart or true
    
    -- Session state
    self.state = {
        phase = "idle",     -- idle, casting, waiting, nibbling, hooked, reeling, complete
        isActive = false,
        lineOut = false,
        fishHooked = false,
        currentFish = nil
    }
    
    -- Session statistics
    self.stats = {
        casts = 0,
        nibbles = 0,
        hooks = 0,
        catches = 0,
        escapes = 0,
        totalFishWeight = 0,
        averageFishSize = 0
    }
    
    -- Timing data
    self.timing = {
        lastCast = nil,
        lastNibble = nil,
        lastHook = nil,
        phaseStartTime = os.time()
    }
end

-- State management
function poopDeck.domain.FishingSession:setState(newPhase, data)
    local oldPhase = self.state.phase
    self.state.phase = newPhase
    self.timing.phaseStartTime = os.time()
    
    self:emit("phaseChanged", {
        from = oldPhase,
        to = newPhase,
        data = data,
        timestamp = os.time()
    })
    
    return true, "Phase changed from " .. oldPhase .. " to " .. newPhase
end

function poopDeck.domain.FishingSession:startFishing()
    if self.state.isActive then
        return false, "Fishing session already active"
    end
    
    self.state.isActive = true
    self:setState("casting")
    self.stats.casts = self.stats.casts + 1
    self.timing.lastCast = os.time()
    
    self:emit("sessionStarted", {
        baitType = self.baitType,
        hookType = self.hookType,
        location = self.location
    })
    
    return true, "Started fishing with " .. self.baitType .. " bait"
end

function poopDeck.domain.FishingSession:castLine()
    if not self.state.isActive then
        return false, "Session not active"
    end
    
    self:setState("waiting")
    self.timing.lastCast = os.time()
    self.stats.casts = self.stats.casts + 1
    self.state.lineOut = true
    
    self:emit("lineCast", {
        baitType = self.baitType,
        hookType = self.hookType,
        castNumber = self.stats.casts
    })
    
    return true, "Line cast (#" .. self.stats.casts .. ")"
end

function poopDeck.domain.FishingSession:fishNibble(fishType)
    if self.state.phase ~= "waiting" then
        return false, "Not in waiting phase"
    end
    
    self:setState("nibbling", {fishType = fishType})
    self.timing.lastNibble = os.time()
    self.stats.nibbles = self.stats.nibbles + 1
    
    self:emit("fishNibbling", {
        fishType = fishType,
        nibbleNumber = self.stats.nibbles
    })
    
    return true, "Fish nibbling detected"
end

function poopDeck.domain.FishingSession:fishHooked(fishType, size)
    if self.state.phase ~= "nibbling" and self.state.phase ~= "waiting" then
        return false, "Not in appropriate phase for hooking"
    end
    
    self.state.fishHooked = true
    self.state.currentFish = {
        type = fishType,
        size = size or "unknown",
        hookedAt = os.time()
    }
    
    self:setState("hooked", {fish = self.state.currentFish})
    self.timing.lastHook = os.time()
    self.stats.hooks = self.stats.hooks + 1
    
    self:emit("fishHooked", {
        fish = self.state.currentFish,
        hookNumber = self.stats.hooks
    })
    
    return true, "Fish hooked: " .. fishType
end

function poopDeck.domain.FishingSession:startReeling()
    if self.state.phase ~= "hooked" then
        return false, "No fish hooked"
    end
    
    self:setState("reeling")
    
    self:emit("startedReeling", {
        fish = self.state.currentFish
    })
    
    return true, "Started reeling in fish"
end

function poopDeck.domain.FishingSession:fishCaught(fishData)
    if self.state.phase ~= "reeling" then
        return false, "Not currently reeling"
    end
    
    -- Update session data
    self.state.fishHooked = false
    self.state.lineOut = false
    
    -- Record the catch
    local finalFish = {
        type = fishData.type or (self.state.currentFish and self.state.currentFish.type),
        size = fishData.size or (self.state.currentFish and self.state.currentFish.size),
        weight = fishData.weight or 0,
        caughtAt = os.time(),
        sessionId = self.id
    }
    
    -- Update statistics
    self.stats.catches = self.stats.catches + 1
    if finalFish.weight > 0 then
        self.stats.totalFishWeight = self.stats.totalFishWeight + finalFish.weight
        self.stats.averageFishSize = self.stats.totalFishWeight / self.stats.catches
    end
    
    self:setState("waiting")  -- Ready for next cast
    self.state.currentFish = nil
    
    self:emit("fishCaught", {
        fish = finalFish,
        catchNumber = self.stats.catches,
        sessionStats = self.stats
    })
    
    return true, "Fish caught: " .. finalFish.type
end

function poopDeck.domain.FishingSession:fishEscaped(reason)
    if not self.state.fishHooked then
        return false, "No fish was hooked"
    end
    
    -- Record the escape
    local escapedFish = self.state.currentFish
    escapedFish.escapedAt = os.time()
    escapedFish.escapeReason = reason or "unknown"
    
    -- Update session state
    self.state.fishHooked = false
    self.state.lineOut = false
    self.state.currentFish = nil
    self.stats.escapes = self.stats.escapes + 1
    
    self:setState("idle")  -- Need to restart
    
    self:emit("fishEscaped", {
        fish = escapedFish,
        reason = reason,
        escapeNumber = self.stats.escapes,
        shouldRestart = self.autoRestart
    })
    
    return true, "Fish escaped: " .. reason
end

function poopDeck.domain.FishingSession:endSession(reason)
    self.endTime = os.time()
    self.state.isActive = false
    self.state.lineOut = false
    self.state.fishHooked = false
    
    local duration = self.endTime - self.startTime
    local finalStats = {
        duration = duration,
        casts = self.stats.casts,
        catches = self.stats.catches,
        escapes = self.stats.escapes,
        successRate = self.stats.hooks > 0 and (self.stats.catches / self.stats.hooks) * 100 or 0,
        catchRate = self.stats.casts > 0 and (self.stats.catches / self.stats.casts) * 100 or 0
    }
    
    self:setState("complete", {reason = reason, stats = finalStats})
    
    self:emit("sessionEnded", {
        reason = reason or "manual",
        stats = finalStats,
        duration = duration
    })
    
    return true, "Session ended: " .. (reason or "manual")
end

function poopDeck.domain.FishingSession:getStatus()
    return {
        id = self.id,
        phase = self.state.phase,
        isActive = self.state.isActive,
        lineOut = self.state.lineOut,
        fishHooked = self.state.fishHooked,
        currentFish = self.state.currentFish,
        baitType = self.baitType,
        hookType = self.hookType,
        stats = self.stats,
        duration = os.time() - self.startTime
    }
end

function poopDeck.domain.FishingSession:canRestart()
    return not self.state.isActive and self.autoRestart
end

function poopDeck.domain.FishingSession:toString()
    return string.format("[FishingSession: %s, Phase: %s, Catches: %d]", 
        self.id, self.state.phase, self.stats.catches)
end

-- Fish data class - represents a caught fish
poopDeck.domain.Fish = poopDeck.core.BaseClass:extend("Fish")

function poopDeck.domain.Fish:initialize(data)
    data = data or {}
    
    self.type = data.type or "unknown fish"
    self.size = data.size or "small"
    self.weight = data.weight or 0
    self.caughtAt = data.caughtAt or os.time()
    self.location = data.location or "unknown"
    self.baitUsed = data.baitUsed or "unknown"
    self.sessionId = data.sessionId or nil
end

function poopDeck.domain.Fish:getDisplayName()
    if self.size and self.size ~= "unknown" then
        return "a " .. self.size .. " " .. self.type
    else
        return self.type
    end
end

function poopDeck.domain.Fish:getValue()
    -- Simple value calculation based on size
    local sizeValues = {
        tiny = 1,
        small = 2, 
        medium = 3,
        large = 5,
        huge = 8,
        gargantuan = 15
    }
    
    return sizeValues[self.size] or 1
end

function poopDeck.domain.Fish:toString()
    return string.format("[Fish: %s, Weight: %d, Value: %d]", 
        self:getDisplayName(), self.weight, self:getValue())
end