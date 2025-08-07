-- UI Service
-- Handles all user interface and display functionality

poopDeck.services = poopDeck.services or {}

-- UIService class definition
poopDeck.services.UIService = poopDeck.core.BaseClass:extend("UIService")

function poopDeck.services.UIService:initialize(config)
    config = config or {}
    
    -- Display settings
    self.settings = {
        frameWidth = config.frameWidth or 80,
        useEmojis = config.useEmojis ~= false,  -- Default true
        colorScheme = config.colorScheme or "default"
    }
    
    -- Color schemes
    self.colorSchemes = {
        default = {
            good = {edge = "#6aa84f", frame = "#274e13", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,008000"},
            bad = {edge = "#f37735", frame = "#d11141", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,800000"},
            shot = {edge = "#fdb643", frame = "#90d673", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,800000"},
            setting = {edge = "#4f81bd", frame = "#385d8a", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,008080"}
        },
        dark = {
            good = {edge = "#4a7c4e", frame = "#1a3d0c", poop = "#4e1414", text = "#CCCCCC", fill = "#333333,006600"},
            bad = {edge = "#c25d2a", frame = "#a10e30", poop = "#4e1414", text = "#CCCCCC", fill = "#333333,660000"},
            shot = {edge = "#daa53a", frame = "#7fc563", poop = "#4e1414", text = "#CCCCCC", fill = "#333333,660000"},
            setting = {edge = "#3f6fa0", frame = "#2a4a70", poop = "#4e1414", text = "#CCCCCC", fill = "#333333,005566"}
        }
    }
    
    -- Message templates
    self.messages = {
        monsterSpotted = {
            "🐉🌊 Rising Behemoth! 🌊🐉",
            "🔍🌊 Titan of the Deep Spotted! 🌊🔍",
            "🐲🌊 Majestic Leviathan Ascendant! 🌊🐲",
            "🦑🌊 Monstrous Anomaly Unveiled! 🌊🦑",
            "🌌🌊 Awakening of the Abyssal Colossus! 🌊🌌"
        },
        monsterKilled = {
            "🚢🐉 Triumphant Victory! 🐉🚢",
            "⚓🌊 Monster Subdued! 🌊⚓",
            "🔱🌊 Beast Beneath Conquered! 🌊🔱",
            "⛵🌊 Monstrous Foe Defeated! 🌊⛵",
            "🗡️🌊 Siren of the Deep Quelled! 🌊🗡️"
        }
    }
end

-- Core display methods
function poopDeck.services.UIService:framedBox(text, style)
    style = style or "default"
    local colors = self:getColors(style)
    
    -- Calculate dimensions
    local totalWidth = self.settings.frameWidth
    local poopTextLength = 14
    local poopText = colors.edge .. "[ " .. colors.poop .. "poop" .. colors.text .. "Deck " .. colors.edge .. "]"
    local poopPaddingLength = math.floor((totalWidth - poopTextLength) / 2)
    local poopPadding = string.rep("═", poopPaddingLength)
    
    -- Handle text padding
    local textLength = self:getTextLength(text)
    local textPaddingLength = math.floor((totalWidth - textLength - 2) / 2)
    local textPadding = string.rep(" ", textPaddingLength)
    local textPadding2 = textPadding
    
    -- Adjust for emoji width
    if self:containsEmoji(text) then
        textPadding = string.rep(" ", textPaddingLength - 2)
        textPadding2 = string.rep(" ", textPaddingLength - 2)
    end
    
    -- Adjust for odd-length text
    if (textLength % 2 ~= 0) then
        textPadding = textPadding .. " "
    end
    
    -- Build frame lines
    local topLine = colors.edge .. "⌜" .. colors.frame .. poopPadding .. poopText .. colors.frame .. poopPadding .. colors.edge .. "⌝"
    local topMidLine = colors.edge .. "|" .. colors.fill .. string.rep(" ", totalWidth - 2) .. "#r" .. colors.edge .. "|"
    local middleLine = colors.edge .. "|" .. colors.fill .. textPadding .. colors.text .. text .. colors.fill .. textPadding2 .. "#r" .. colors.edge .. "|"
    local bottomMidLine = colors.edge .. "|" .. colors.fill .. string.rep(" ", totalWidth - 2) .. "#r" .. colors.edge .. "|"
    local bottomLine = colors.edge .. "⌞" .. string.rep(colors.frame .. "═", totalWidth - 2) .. colors.edge .. "⌟"
    
    -- Output
    hecho("\n" .. topLine)
    hecho("\n" .. topMidLine)
    hecho("\n" .. middleLine)
    hecho("\n" .. bottomMidLine)
    hecho("\n" .. bottomLine)
end

function poopDeck.services.UIService:smallFramedBox(text, style)
    style = style or "default"
    local colors = self:getColors(style)
    
    -- Calculate dimensions
    local totalWidth = self.settings.frameWidth
    local poopTextLength = 14
    local poopText = colors.edge .. "[ " .. colors.poop .. "poop" .. colors.text .. "Deck " .. colors.edge .. "]"
    local poopPaddingLength = math.floor((totalWidth - poopTextLength) / 2)
    local poopPadding = string.rep("═", poopPaddingLength)
    
    -- Handle text padding
    local textLength = self:getTextLength(text)
    local textPaddingLength = math.floor((totalWidth - textLength - 2) / 2)
    local textPadding = string.rep(" ", textPaddingLength)
    local textPadding2 = textPadding
    
    -- Adjust for emoji width
    if self:containsEmoji(text) then
        textPadding = string.rep(" ", textPaddingLength - 2)
        textPadding2 = string.rep(" ", textPaddingLength - 2)
    end
    
    -- Adjust for odd-length text
    if (textLength % 2 ~= 0) then
        textPadding = textPadding .. " "
    end
    
    -- Build frame lines
    local topLine = colors.edge .. "⌜" .. colors.frame .. poopPadding .. poopText .. colors.frame .. poopPadding .. colors.edge .. "⌝"
    local middleLine = colors.edge .. "|" .. colors.fill .. textPadding .. colors.text .. text .. colors.fill .. textPadding2 .. "#r" .. colors.edge .. "|"
    local bottomLine = colors.edge .. "⌞" .. string.rep(colors.frame .. "═", totalWidth - 2) .. colors.edge .. "⌟"
    
    -- Output
    hecho("\n" .. topLine)
    hecho("\n" .. middleLine)
    hecho("\n" .. bottomLine)
end

function poopDeck.services.UIService:line(text, style)
    style = style or "default"
    local colors = self:getColors(style)
    
    -- Calculate dimensions
    local totalWidth = getWindowWrap("main") / 4
    local textLength = self:getTextLength(text)
    local paddingLength = math.floor((totalWidth - textLength - 2) / 2)
    local padding = string.rep(" ", paddingLength)
    local padding2 = padding
    
    -- Adjust for emoji width
    if self:containsEmoji(text) then
        padding = string.rep(" ", paddingLength - 2)
        padding2 = string.rep(" ", paddingLength - 2)
    end
    
    -- Adjust for odd-length text
    if (textLength % 2 ~= 0) then
        padding = padding .. " "
    end
    
    local line = colors.edge .. "|" .. colors.fill .. padding .. colors.text .. text .. colors.fill .. padding2 .. "#r" .. colors.edge .. "|"
    hecho(line)
end

-- Convenience methods for different message types
function poopDeck.services.UIService:good(text, small)
    if small then
        self:smallFramedBox(text, "good")
    else
        self:framedBox(text, "good")
    end
end

function poopDeck.services.UIService:bad(text, small)
    if small then
        self:smallFramedBox(text, "bad")
    else
        self:framedBox(text, "bad")
    end
end

function poopDeck.services.UIService:shot(text)
    self:smallFramedBox(text, "shot")
end

function poopDeck.services.UIService:setting(text)
    self:smallFramedBox(text, "setting")
end

function poopDeck.services.UIService:fire(text)
    self:line(text, "shot")
end

-- Message generation
function poopDeck.services.UIService:getRandomMessage(messageType)
    local messages = self.messages[messageType]
    if not messages then
        return "Event: " .. tostring(messageType)
    end
    
    if not self.settings.useEmojis then
        -- Strip emojis from messages
        local message = messages[math.random(#messages)]
        return message:gsub("[\128-\191][\128-\191]", ""):gsub("%s+", " "):trim()
    end
    
    return messages[math.random(#messages)]
end

-- Utility methods
function poopDeck.services.UIService:containsEmoji(text)
    return text:match("[\128-\191][\128-\191]") ~= nil
end

function poopDeck.services.UIService:getTextLength(text)
    return utf8.len(text) or string.len(text)
end

function poopDeck.services.UIService:getColors(style)
    local scheme = self.colorSchemes[self.settings.colorScheme] or self.colorSchemes.default
    local styleColors = scheme[style] or scheme.good
    
    return {
        edge = styleColors.edge,
        frame = styleColors.frame,
        poop = styleColors.poop,
        text = styleColors.text,
        fill = styleColors.fill
    }
end

function poopDeck.services.UIService:setColorScheme(scheme)
    if self.colorSchemes[scheme] then
        self.settings.colorScheme = scheme
        self:emit("colorSchemeChanged", scheme)
        return true, "Color scheme set to: " .. scheme
    end
    return false, "Invalid color scheme"
end

function poopDeck.services.UIService:toggleEmojis()
    self.settings.useEmojis = not self.settings.useEmojis
    self:emit("emojisToggled", self.settings.useEmojis)
    return true, "Emojis " .. (self.settings.useEmojis and "enabled" or "disabled")
end

-- Display complex information
function poopDeck.services.UIService:displayStatus(status)
    echo("\n===== poopDeck Status =====\n")
    
    if status.inCombat then
        echo("COMBAT: Active\n")
        if status.monster then
            echo(string.format("  Target: %s (%s)\n", status.monster.name, status.monster.tier))
            echo(string.format("  Progress: %s shots\n", status.monster.shots))
            echo(string.format("  Remaining: %d\n", status.monster.remaining))
        end
    else
        echo("COMBAT: Idle\n")
    end
    
    if status.weapon then
        echo(string.format("WEAPON: %s\n", status.weapon.name))
        echo(string.format("  Status: %s\n", status.weapon.ready and "Ready" or "Cooldown"))
        echo(string.format("  Accuracy: %s\n", status.weapon.accuracy))
    end
    
    echo("\nSETTINGS:\n")
    echo(string.format("  Auto-fire: %s\n", status.autoFire and "ON" or "OFF"))
    echo(string.format("  Health threshold: %d%%\n", status.settings.healthThreshold))
    echo(string.format("  Maintenance: %s\n", status.settings.maintenance or "none"))
    
    echo("===========================\n")
end

function poopDeck.services.UIService:toString()
    return string.format("[UIService: %s scheme, emojis %s]", 
        self.settings.colorScheme,
        self.settings.useEmojis and "on" or "off")
end

-- Create singleton instance
poopDeck.services.UIService.instance = nil

function poopDeck.services.UIService.getInstance()
    if not poopDeck.services.UIService.instance then
        poopDeck.services.UIService.instance = poopDeck.services.UIService()
    end
    return poopDeck.services.UIService.instance
end

-- Initialize UI service
poopDeck.ui = poopDeck.services.UIService.getInstance()

-- Legacy wrapper functions for backward compatibility
function poopDeck.goodEcho(text)
    poopDeck.ui:good(text, false)
end

function poopDeck.badEcho(text)
    poopDeck.ui:bad(text, false)
end

function poopDeck.smallGoodEcho(text)
    poopDeck.ui:good(text, true)
end

function poopDeck.smallBadEcho(text)
    poopDeck.ui:bad(text, true)
end

function poopDeck.shotEcho(text)
    poopDeck.ui:shot(text)
end

function poopDeck.settingEcho(text)
    poopDeck.ui:setting(text)
end

function poopDeck.fireLine(text)
    poopDeck.ui:fire(text)
end