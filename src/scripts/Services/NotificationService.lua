-- Notification Service
-- Manages timed alerts and reminders

poopDeck.services = poopDeck.services or {}

-- NotificationService class definition
poopDeck.services.NotificationService = poopDeck.core.BaseClass:extend("NotificationService")

function poopDeck.services.NotificationService:initialize(config)
    config = config or {}
    
    -- Notification settings
    self.settings = {
        enabled = config.enabled ~= false,
        soundEnabled = config.soundEnabled or false,
        spawnWarnings = config.spawnWarnings or {
            fiveMinute = true,
            oneMinute = true,
            timeToFish = true
        }
    }
    
    -- Timer tracking
    self.activeTimers = {}
    
    -- Spawn timing constants (in seconds)
    self.timings = {
        SPAWN_INTERVAL = 20 * 60,  -- 20 minutes
        FIVE_MINUTE_WARNING = 15 * 60,  -- 15 minutes after spawn (5 min warning)
        ONE_MINUTE_WARNING = 19 * 60,   -- 19 minutes after spawn (1 min warning)
        TIME_TO_FISH = 20 * 60          -- 20 minutes after spawn (time to fish)
    }
    
    -- Message templates
    self.messages = {
        fiveMinute = {
            "⏰🌊 Monster in 5 minutes! 🌊⏰",
            "🚨🌊 5 Minutes to Monster Spawn! 🌊🚨", 
            "⚓🌊 Prepare for Battle - 5 Minutes! 🌊⚓",
            "🔔🌊 Monster Alert: 5 Minutes! 🌊🔔"
        },
        oneMinute = {
            "⏰🌊 Monster in 1 minute! 🌊⏰",
            "🚨🌊 60 Seconds to Monster! 🌊🚨",
            "⚓🌊 Battle Stations - 1 Minute! 🌊⚓",
            "🔔🌊 Final Warning: 1 Minute! 🌊🔔"
        },
        timeToFish = {
            "🎣🌊 Time to fish! Monster spawning now! 🌊🎣",
            "🐟🌊 Reel in your lines - Monster time! 🌊🐟",
            "🎣🌊 Stop fishing! Seamonster incoming! 🌊🎣",
            "🐟🌊 Monster spawn - cease fishing! 🌊🐟"
        }
    }
end

-- Timer management
function poopDeck.services.NotificationService:startSpawnTimers(lastSpawnTime)
    -- Clear any existing spawn timers
    self:clearSpawnTimers()
    
    local currentTime = os.time()
    lastSpawnTime = lastSpawnTime or currentTime
    
    -- Calculate timer delays
    local fiveMinuteDelay = self.timings.FIVE_MINUTE_WARNING - (currentTime - lastSpawnTime)
    local oneMinuteDelay = self.timings.ONE_MINUTE_WARNING - (currentTime - lastSpawnTime)
    local fishingDelay = self.timings.TIME_TO_FISH - (currentTime - lastSpawnTime)
    
    -- Only create timers for future events
    if fiveMinuteDelay > 0 and self.settings.spawnWarnings.fiveMinute then
        self.activeTimers.fiveMinute = tempTimer(fiveMinuteDelay, function()
            self:showFiveMinuteWarning()
        end)
    end
    
    if oneMinuteDelay > 0 and self.settings.spawnWarnings.oneMinute then
        self.activeTimers.oneMinute = tempTimer(oneMinuteDelay, function()
            self:showOneMinuteWarning()
        end)
    end
    
    if fishingDelay > 0 and self.settings.spawnWarnings.timeToFish then
        self.activeTimers.timeToFish = tempTimer(fishingDelay, function()
            self:showTimeToFishWarning()
        end)
    end
    
    -- Emit event with timer info
    self:emit("spawnTimersStarted", {
        fiveMinute = fiveMinuteDelay > 0,
        oneMinute = oneMinuteDelay > 0,
        timeToFish = fishingDelay > 0,
        nextSpawn = lastSpawnTime + self.timings.SPAWN_INTERVAL
    })
    
    return true, "Spawn timers activated"
end

function poopDeck.services.NotificationService:clearSpawnTimers()
    for timerName, timerId in pairs(self.activeTimers) do
        if timerId then
            killTimer(timerId)
        end
    end
    self.activeTimers = {}
    
    self:emit("spawnTimersCleared")
    return true, "Spawn timers cleared"
end

-- Warning methods
function poopDeck.services.NotificationService:showFiveMinuteWarning()
    if not self.settings.enabled then return end
    
    local message = self:getRandomMessage("fiveMinute")
    poopDeck.badEcho(message)
    
    if self.settings.soundEnabled then
        self:playSound("warning")
    end
    
    self.activeTimers.fiveMinute = nil
    self:emit("fiveMinuteWarning")
end

function poopDeck.services.NotificationService:showOneMinuteWarning()
    if not self.settings.enabled then return end
    
    local message = self:getRandomMessage("oneMinute")
    poopDeck.badEcho(message)
    
    if self.settings.soundEnabled then
        self:playSound("urgent")
    end
    
    self.activeTimers.oneMinute = nil
    self:emit("oneMinuteWarning")
end

function poopDeck.services.NotificationService:showTimeToFishWarning()
    if not self.settings.enabled then return end
    
    local message = self:getRandomMessage("timeToFish")
    poopDeck.badEcho(message)
    
    if self.settings.soundEnabled then
        self:playSound("alert")
    end
    
    self.activeTimers.timeToFish = nil
    self:emit("timeToFishWarning")
end

-- Custom notifications
function poopDeck.services.NotificationService:scheduleNotification(message, delaySeconds, style)
    style = style or "good"
    
    local timerId = tempTimer(delaySeconds, function()
        if style == "good" then
            poopDeck.goodEcho(message)
        elseif style == "bad" then
            poopDeck.badEcho(message)
        elseif style == "setting" then
            poopDeck.settingEcho(message)
        else
            poopDeck.smallGoodEcho(message)
        end
        
        self:emit("customNotification", message)
    end)
    
    return timerId, "Notification scheduled"
end

function poopDeck.services.NotificationService:scheduleCountdown(baseName, totalSeconds, intervals)
    intervals = intervals or {300, 60, 30, 10, 5, 3, 2, 1}  -- Default countdown intervals
    
    local timers = {}
    
    for _, interval in ipairs(intervals) do
        if interval < totalSeconds then
            local delay = totalSeconds - interval
            local timerId = tempTimer(delay, function()
                local message = string.format("%s in %s", baseName, self:formatTime(interval))
                poopDeck.settingEcho(message)
                self:emit("countdownTick", baseName, interval)
            end)
            table.insert(timers, timerId)
        end
    end
    
    -- Final notification
    local finalTimerId = tempTimer(totalSeconds, function()
        local message = string.format("%s NOW!", baseName)
        poopDeck.badEcho(message)
        self:emit("countdownComplete", baseName)
    end)
    table.insert(timers, finalTimerId)
    
    return timers, "Countdown scheduled"
end

-- Status and query methods
function poopDeck.services.NotificationService:getActiveTimers()
    local active = {}
    for timerName, timerId in pairs(self.activeTimers) do
        if timerId then
            active[timerName] = true
        end
    end
    return active
end

function poopDeck.services.NotificationService:getTimeToNextSpawn(lastSpawnTime)
    if not lastSpawnTime then
        return nil, "No spawn time recorded"
    end
    
    local nextSpawn = lastSpawnTime + self.timings.SPAWN_INTERVAL
    local remaining = nextSpawn - os.time()
    
    if remaining <= 0 then
        return 0, "Spawn overdue"
    end
    
    return remaining, self:formatTime(remaining)
end

-- Settings management
function poopDeck.services.NotificationService:enable()
    self.settings.enabled = true
    self:emit("settingChanged", "enabled", true)
    return true, "Notifications enabled"
end

function poopDeck.services.NotificationService:disable()
    self.settings.enabled = false
    self:clearSpawnTimers()
    self:emit("settingChanged", "enabled", false)
    return true, "Notifications disabled"
end

function poopDeck.services.NotificationService:toggleWarning(warningType)
    if not self.settings.spawnWarnings[warningType] then
        return false, "Invalid warning type: " .. tostring(warningType)
    end
    
    self.settings.spawnWarnings[warningType] = not self.settings.spawnWarnings[warningType]
    local status = self.settings.spawnWarnings[warningType] and "enabled" or "disabled"
    
    self:emit("settingChanged", warningType, self.settings.spawnWarnings[warningType])
    return true, string.format("%s warning %s", warningType, status)
end

function poopDeck.services.NotificationService:enableSound()
    self.settings.soundEnabled = true
    self:emit("settingChanged", "soundEnabled", true)
    return true, "Sound notifications enabled"
end

function poopDeck.services.NotificationService:disableSound()
    self.settings.soundEnabled = false
    self:emit("settingChanged", "soundEnabled", false)
    return true, "Sound notifications disabled"
end

-- Utility methods
function poopDeck.services.NotificationService:getRandomMessage(messageType)
    local messages = self.messages[messageType]
    if not messages or #messages == 0 then
        return "Notification: " .. tostring(messageType)
    end
    
    return messages[math.random(#messages)]
end

function poopDeck.services.NotificationService:formatTime(seconds)
    if seconds < 60 then
        return string.format("%d seconds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        if remainingSeconds == 0 then
            return string.format("%d minutes", minutes)
        else
            return string.format("%d:%02d", minutes, remainingSeconds)
        end
    else
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return string.format("%d:%02d hours", hours, minutes)
    end
end

function poopDeck.services.NotificationService:playSound(soundType)
    -- Placeholder for sound functionality
    -- Could integrate with Mudlet's sound system or system beeps
    if soundType == "warning" then
        -- Play warning sound
    elseif soundType == "urgent" then
        -- Play urgent sound  
    elseif soundType == "alert" then
        -- Play alert sound
    end
end

function poopDeck.services.NotificationService:getStatus()
    return {
        enabled = self.settings.enabled,
        soundEnabled = self.settings.soundEnabled,
        warnings = {
            fiveMinute = self.settings.spawnWarnings.fiveMinute,
            oneMinute = self.settings.spawnWarnings.oneMinute, 
            timeToFish = self.settings.spawnWarnings.timeToFish
        },
        activeTimers = self:getActiveTimers()
    }
end

function poopDeck.services.NotificationService:toString()
    local activeCount = 0
    for _ in pairs(self.activeTimers) do
        activeCount = activeCount + 1
    end
    
    return string.format("[NotificationService: %s, %d timers]", 
        self.settings.enabled and "enabled" or "disabled",
        activeCount)
end