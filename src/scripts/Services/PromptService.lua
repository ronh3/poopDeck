-- Prompt Service
-- Manages smart status display with spam reduction

poopDeck.services = poopDeck.services or {}

-- PromptService class definition
poopDeck.services.PromptService = poopDeck.core.BaseClass:extend("PromptService")

function poopDeck.services.PromptService:initialize(config)
    config = config or {}
    
    -- Display settings
    self.settings = {
        enabled = config.enabled ~= false,
        throttleTime = config.throttleTime or 5, -- seconds between duplicate messages
        maxRepeats = config.maxRepeats or 3,     -- max times to show same message
        quietMode = config.quietMode or false,   -- minimal output mode
        showOnChange = config.showOnChange ~= false -- show when status changes
    }
    
    -- State tracking
    self.state = {
        lastMessages = {},     -- track last displayed messages
        lastTimes = {},       -- when messages were last shown
        repeatCounts = {},    -- how many times we've shown each message
        lastStatus = {        -- previous status to detect changes
            maintaining = nil,
            firing = false,
            outOfRange = false
        }
    }
    
    -- Prompt counter for legacy compatibility
    self.promptCount = 0
end

-- Main prompt parsing with intelligent spam reduction
function poopDeck.services.PromptService:parsePrompt()
    self.promptCount = self.promptCount + 1
    local currentTime = os.time()
    local messagesToShow = {}
    local statusChanged = false
    
    -- Check maintenance status
    if poopDeck.maintain then
        local maintainMessage = "MAINTAINING " .. poopDeck.maintain:upper()
        local showMaintain = false
        
        if self.state.lastStatus.maintaining ~= poopDeck.maintain then
            -- Status changed - always show
            showMaintain = true
            statusChanged = true
            self.state.lastStatus.maintaining = poopDeck.maintain
        elseif self:shouldShowMessage("maintain", maintainMessage, currentTime) then
            showMaintain = true
        end
        
        if showMaintain then
            table.insert(messagesToShow, {
                message = maintainMessage,
                type = "maintain",
                echo = function() poopDeck.maintainEcho(maintainMessage) end
            })
            self:recordMessage("maintain", maintainMessage, currentTime)
        end
    else
        -- No longer maintaining
        if self.state.lastStatus.maintaining then
            statusChanged = true
            self.state.lastStatus.maintaining = nil
            self:clearMessage("maintain")
        end
    end
    
    -- Check firing status
    if poopDeck.firing then
        local fireMessage = "FIRING!"
        local showFiring = false
        
        if not self.state.lastStatus.firing then
            -- Started firing - always show
            showFiring = true
            statusChanged = true
            self.state.lastStatus.firing = true
        elseif self:shouldShowMessage("firing", fireMessage, currentTime) then
            showFiring = true
        end
        
        if showFiring then
            table.insert(messagesToShow, {
                message = fireMessage,
                type = "firing",
                echo = function() poopDeck.fireEcho(fireMessage) end
            })
            self:recordMessage("firing", fireMessage, currentTime)
        end
    else
        -- No longer firing
        if self.state.lastStatus.firing then
            statusChanged = true
            self.state.lastStatus.firing = false
            self:clearMessage("firing")
        end
    end
    
    -- Check out of range status with smart limiting
    if poopDeck.oor then
        local rangeMessage = "OUT OF RANGE!"
        local showRange = false
        
        if not self.state.lastStatus.outOfRange then
            -- Just went out of range - always show
            showRange = true
            statusChanged = true
            self.state.lastStatus.outOfRange = true
        elseif self:shouldShowMessage("range", rangeMessage, currentTime) then
            -- Show occasionally if still out of range
            showRange = true
        end
        
        if showRange then
            table.insert(messagesToShow, {
                message = rangeMessage,
                type = "range",
                echo = function() poopDeck.rangeEcho(rangeMessage) end
            })
            self:recordMessage("range", rangeMessage, currentTime)
        end
    else
        -- Back in range
        if self.state.lastStatus.outOfRange then
            statusChanged = true
            self.state.lastStatus.outOfRange = false
            self:clearMessage("range")
            -- Show "back in range" message
            table.insert(messagesToShow, {
                message = "BACK IN RANGE!",
                type = "range_clear",
                echo = function() poopDeck.smallGoodEcho("BACK IN RANGE!") end
            })
        end
    end
    
    -- Display messages if we have any
    if #messagesToShow > 0 then
        echo("\n")
        for _, msg in ipairs(messagesToShow) do
            msg.echo()
        end
        echo("\n")
    end
    
    -- Clean up old message records
    self:cleanupOldMessages(currentTime)
end

-- Determine if a message should be shown based on throttling rules
function poopDeck.services.PromptService:shouldShowMessage(messageType, message, currentTime)
    if self.settings.quietMode then
        return false
    end
    
    local lastTime = self.state.lastTimes[messageType] or 0
    local repeatCount = self.state.repeatCounts[messageType] or 0
    
    -- Don't show if we've hit max repeats
    if repeatCount >= self.settings.maxRepeats then
        return false
    end
    
    -- Don't show if not enough time has passed
    if (currentTime - lastTime) < self.settings.throttleTime then
        return false
    end
    
    return true
end

-- Record that we showed a message
function poopDeck.services.PromptService:recordMessage(messageType, message, currentTime)
    self.state.lastMessages[messageType] = message
    self.state.lastTimes[messageType] = currentTime
    self.state.repeatCounts[messageType] = (self.state.repeatCounts[messageType] or 0) + 1
end

-- Clear message tracking when status changes
function poopDeck.services.PromptService:clearMessage(messageType)
    self.state.lastMessages[messageType] = nil
    self.state.lastTimes[messageType] = nil
    self.state.repeatCounts[messageType] = nil
end

-- Clean up old message records
function poopDeck.services.PromptService:cleanupOldMessages(currentTime)
    local cleanupAge = 300 -- 5 minutes
    
    for messageType, lastTime in pairs(self.state.lastTimes) do
        if (currentTime - lastTime) > cleanupAge then
            self:clearMessage(messageType)
        end
    end
end

-- Settings management
function poopDeck.services.PromptService:enableQuietMode()
    self.settings.quietMode = true
    self:emit("settingChanged", "quietMode", true)
    return true, "Quiet mode enabled - minimal prompt spam"
end

function poopDeck.services.PromptService:disableQuietMode()
    self.settings.quietMode = false
    self:emit("settingChanged", "quietMode", false)
    return true, "Quiet mode disabled - normal prompt display"
end

function poopDeck.services.PromptService:toggleQuietMode()
    if self.settings.quietMode then
        return self:disableQuietMode()
    else
        return self:enableQuietMode()
    end
end

function poopDeck.services.PromptService:setThrottleTime(seconds)
    self.settings.throttleTime = tonumber(seconds) or 5
    self:emit("settingChanged", "throttleTime", self.settings.throttleTime)
    return true, string.format("Throttle time set to %d seconds", self.settings.throttleTime)
end

function poopDeck.services.PromptService:setMaxRepeats(count)
    self.settings.maxRepeats = tonumber(count) or 3
    self:emit("settingChanged", "maxRepeats", self.settings.maxRepeats)
    return true, string.format("Max repeats set to %d", self.settings.maxRepeats)
end

function poopDeck.services.PromptService:togglePrompts()
    self.settings.enabled = not self.settings.enabled
    local status = self.settings.enabled and "enabled" or "disabled"
    self:emit("settingChanged", "enabled", self.settings.enabled)
    return true, string.format("Prompt status display %s", status)
end

-- Status display
function poopDeck.services.PromptService:showSettings()
    echo("\n===== Prompt Settings =====\n")
    echo(string.format("Enabled: %s\n", self.settings.enabled and "YES" or "NO"))
    echo(string.format("Quiet mode: %s\n", self.settings.quietMode and "YES" or "NO"))
    echo(string.format("Throttle time: %d seconds\n", self.settings.throttleTime))
    echo(string.format("Max repeats: %d\n", self.settings.maxRepeats))
    echo(string.format("Show on change: %s\n", self.settings.showOnChange and "YES" or "NO"))
    echo("\nCurrent Status:\n")
    echo(string.format("  Maintaining: %s\n", poopDeck.maintain or "NO"))
    echo(string.format("  Firing: %s\n", poopDeck.firing and "YES" or "NO"))
    echo(string.format("  Out of range: %s\n", poopDeck.oor and "YES" or "NO"))
    echo("===========================\n")
end

-- Reset all throttling
function poopDeck.services.PromptService:resetThrottling()
    self.state.lastMessages = {}
    self.state.lastTimes = {}
    self.state.repeatCounts = {}
    self:emit("throttlingReset")
    return true, "Message throttling reset"
end

function poopDeck.services.PromptService:getStatus()
    return {
        enabled = self.settings.enabled,
        quietMode = self.settings.quietMode,
        throttleTime = self.settings.throttleTime,
        maxRepeats = self.settings.maxRepeats,
        activeMessages = table.size(self.state.lastMessages),
        promptCount = self.promptCount
    }
end

function poopDeck.services.PromptService:toString()
    return string.format("[PromptService: %s, %d messages tracked]", 
        self.settings.enabled and "enabled" or "disabled",
        table.size(self.state.lastMessages))
end