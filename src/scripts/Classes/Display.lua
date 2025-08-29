-- Display Class for poopDeck - Efficient Version
-- Handles all UI output and formatting using OOP pattern with Mudlet events

local Display = {}
Display.__index = Display

-- Constructor
function Display:new(config)
    local self = setmetatable({}, Display)
    
    -- Configuration
    self.config = config or {}
    self.totalWidth = self.config.totalWidth or 80
    self.poopTextLength = 14
    
    -- Base colors for inheritance - eliminates duplication
    local baseGood = { edge = "#6aa84f", frame = "#274e13", poop = "#6e1b1b", text = "#FFFFFF" }
    local baseBad = { edge = "#f37735", frame = "#d11141", poop = "#6e1b1b", text = "#FFFFFF" }
    
    -- Efficient color schemes with shared base colors
    self.colors = {
        good = { edge = baseGood.edge, frame = baseGood.frame, poop = baseGood.poop, text = baseGood.text, fill = "#FFFFFF,008000" },
        bad = { edge = baseBad.edge, frame = baseBad.frame, poop = baseBad.poop, text = baseBad.text, fill = "#FFFFFF,800000" },
        shot = { edge = "#fdb643", frame = "#90d673", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,800000" },
        setting = { edge = "#4f81bd", frame = "#385d8a", poop = "#6e1b1b", text = "#FFFFFF", fill = "#FFFFFF,008080" },
        -- These inherit from baseGood, eliminating duplication
        fire = { edge = baseGood.edge, frame = baseGood.frame, poop = baseGood.poop, text = baseGood.text, fill = "#FFFFFF,008000" },
        maintain = { edge = baseGood.edge, frame = baseGood.frame, poop = baseGood.poop, text = baseGood.text, fill = "#FFFFFF,8B4513" },
        range = { edge = baseGood.edge, frame = baseGood.frame, poop = baseGood.poop, text = baseGood.text, fill = "#FFFFFF,E91E63" }
    }
    
    -- Pre-calculate all static elements once (massive performance gain)
    self.poopPaddingLength = math.floor((self.totalWidth - self.poopTextLength) / 2)
    self.poopPadding = string.rep("═", self.poopPaddingLength)
    self.emptyLineSpaces = string.rep(" ", 78)
    self.bottomBorderChars = string.rep("═", self.totalWidth - 2)
    
    -- Pre-built templates for each color scheme - eliminates runtime string building
    self.templates = {}
    for name, colors in pairs(self.colors) do
        local poopText = colors.edge .. "[ " .. colors.poop .. "poop" .. colors.text .. "Deck " .. colors.edge .. "]"
        self.templates[name] = {
            topLine = colors.edge .. "⌜" .. colors.frame .. self.poopPadding .. poopText .. colors.frame .. self.poopPadding .. colors.edge .. "⌝",
            emptyLine = colors.edge .. "|" .. colors.fill .. self.emptyLineSpaces .. "#r" .. colors.edge .. "|",
            textLineFormat = colors.edge .. "|" .. colors.fill .. "%s" .. colors.text .. "%s" .. colors.fill .. "%s#r" .. colors.edge .. "|",
            bottomLine = colors.edge .. "⌞" .. colors.frame .. self.bottomBorderChars .. colors.edge .. "⌟",
            colors = colors  -- Keep reference for prompt lines
        }
    end
    
    -- Victory/spawn messages
    self.victoryMessages = {
        "🚢🐉 Triumphant Victory! 🐉🚢",
        "⚓🌊 Monster Subdued! 🌊⚓", 
        "🔱🌊 Beast Beneath Conquered! 🌊🔱",
        "⛵🌊 Monstrous Foe Defeated! 🌊⛵",
        "🗡️🌊 Siren of the Deep Quelled! 🌊🗡️",
        "⚔️🌊 Sea's Terror Defeated! 🌊⚔️",
        "🦈🌊 Jaws of the Abyss Conquered! 🌊🦈",
        "🚢🌊 Monstrous Victory Achieved! 🌊🚢",
        "🌟🌊 Tidal Terror Tamed! 🌊🌟",
        "🗺️🌊 Legends Born of Victory! 🌊🗺️"
    }
    
    self.spawnMessages = {
        "🐉🌊 Rising Behemoth! 🌊🐉",
        "🔍🌊 Titan of the Deep Spotted! 🌊🔍",
        "🐲🌊 Majestic Leviathan Ascendant! 🌊🐲",
        "🦑🌊 Monstrous Anomaly Unveiled! 🌊🦑",
        "🌌🌊 Awakening of the Abyssal Colossus! 🌊🌌",
        "🌊🌊 Ripple of Giants! 🌊🌊",
        "🌟🌊 Deep's Enigma Revealed! 🌊🌟",
        "🐙🌊 Emergence of the Watery Behemoth! 🌊🐙",
        "🔮🌊 Ocean's Secret Unveiled! 🌊🔮",
        "🐍🌊 Serpentine Giant Surfaces! 🌊🐍"
    }
    
    -- Register event handlers
    self:registerEventHandlers()
    
    return self
end

-- Register for Mudlet events
function Display:registerEventHandlers()
    local self = self  -- Capture self in closure
    
    -- Combat events
    registerAnonymousEventHandler("poopDeck.monsterSpawned", function(event, monsterName)
        self:showMonsterSpawn(monsterName)
    end)
    
    registerAnonymousEventHandler("poopDeck.monsterKilled", function(event, monsterName, totalKills)
        self:showVictory(monsterName)
    end)
    
    registerAnonymousEventHandler("poopDeck.shotFired", function(event, shotNumber, remaining)
        self:showShotCount(shotNumber, remaining)
    end)
    
    registerAnonymousEventHandler("poopDeck.outOfRange", function()
        self:showMessage("OUT OF RANGE!", "bad")
    end)
    
    -- Ship events  
    registerAnonymousEventHandler("poopDeck.shipDocked", function(event, direction)
        self:showMessage("Ship docked " .. direction, "good")
    end)
    
    registerAnonymousEventHandler("poopDeck.speedChanged", function(event, speed)
        self:showMessage("Speed set to " .. speed, "setting")
    end)
    
    -- System events
    registerAnonymousEventHandler("poopDeck.modeChanged", function(event, mode)
        local message = mode == "automatic" and "AUTO FIRE ON" or "AUTO FIRE OFF"
        local type = mode == "automatic" and "good" or "bad"
        self:showMessage(message, type)
    end)
    
    registerAnonymousEventHandler("poopDeck.weaponSet", function(event, weapon)
        local messages = {
            ballista = "UNLEASH THE DARTS! - BALLISTA",
            onager = "ENGAGE THE MIGHTY SLINGSHOT - ONAGER", 
            thrower = "SEND HAVOC SPINNING! - THROWER"
        }
        self:showMessage(messages[weapon] or "NO WEAPON SELECTED!", "good")
    end)
end

-- Efficient padding calculation - simplified emoji handling
function Display:calculatePadding(text)
    local textLength = utf8.len(text)
    local paddingLength = math.floor((self.totalWidth - textLength - 2) / 2)
    
    -- Simple emoji detection - just check for UTF-8 4-byte sequences
    local emojiAdjust = text:match("[\240-\244]") and -2 or 0
    local padding1 = string.rep(" ", math.max(0, paddingLength + emojiAdjust))
    local padding2 = padding1
    
    -- Handle odd text length
    if textLength % 2 ~= 0 then
        padding2 = padding2 .. " "
    end
    
    return padding1, padding2
end

-- Core display method - uses pre-built templates for maximum efficiency
function Display:framedBox(text, colorScheme, small)
    local template = self.templates[colorScheme] or self.templates.good
    local padding1, padding2 = self:calculatePadding(text)
    
    -- Use pre-built template strings - much faster than building each time
    local textLine = string.format(template.textLineFormat, padding1, text, padding2)
    
    hecho("\n" .. template.topLine)
    if not small then
        hecho("\n" .. template.emptyLine)
    end
    hecho("\n" .. textLine)
    if not small then
        hecho("\n" .. template.emptyLine) 
    end
    hecho("\n" .. template.bottomLine)
end

-- Public display methods
function Display:showMessage(text, messageType, small)
    self:framedBox(text, messageType, small)
end

function Display:showVictory(monsterName)
    local message = self.victoryMessages[math.random(#self.victoryMessages)]
    self:showMessage(message, "good")
end

function Display:showMonsterSpawn(monsterName)
    local message = self.spawnMessages[math.random(#self.spawnMessages)]
    self:showMessage(message, "bad")
end

function Display:showShotCount(shotNumber, remaining)
    local message = string.format("%d shots taken, %d remain.", shotNumber, remaining)
    self:showMessage(message, "shot", true)
end

-- Efficient prompt line display
function Display:promptLine(text, colorType)
    local template = self.templates[colorType] or self.templates.good
    local colors = template.colors
    local totalWidth = getWindowWrap("main") / 4
    local textLength = utf8.len(text)
    local paddingLength = math.floor((totalWidth - textLength - 2) / 2)
    
    -- Simplified padding calculation
    local emojiAdjust = text:match("[\240-\244]") and -2 or 0
    local padding1 = string.rep(" ", math.max(0, paddingLength + emojiAdjust))
    local padding2 = (textLength % 2 ~= 0) and padding1 .. " " or padding1
    
    local line = colors.edge .. "|" .. colors.fill .. padding1 .. colors.text .. text .. colors.fill .. padding2 .. "#r" .. colors.edge .. "|"
    hecho(line)
end

-- Export the class
return Display