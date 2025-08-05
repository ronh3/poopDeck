-- Spec helper for poopDeck tests
-- This file sets up the testing environment

-- Initialize the poopDeck namespace and required functions
-- These would normally be loaded by Mudlet when the package is installed

-- Mock Mudlet-specific functions that aren't available in test environment
if not tempTimer then
    tempTimer = function(delay, code) 
        return "mock_timer_" .. delay 
    end
end

if not enableTrigger then
    enableTrigger = function(name) 
        -- Mock implementation
    end
end

if not disableTrigger then
    disableTrigger = function(name) 
        -- Mock implementation  
    end
end

if not send then
    send = function(command)
        -- Mock implementation
    end
end

if not sendAll then
    sendAll = function(...)
        -- Mock implementation
    end
end

-- Mock echo functions
if not echo then
    echo = function(text) end
end

if not hecho then
    hecho = function(text) end
end

-- Mock window functions
if not getWindowWrap then
    getWindowWrap = function(name)
        return 80 -- Default width
    end
end

-- Initialize GMCP mock if not present
if not gmcp then
    gmcp = {
        Char = {
            Vitals = {
                hp = "1000",
                maxhp = "1000"
            }
        }
    }
end

-- Set up poopDeck namespace as it would be in the actual package
poopDeck = poopDeck or {}
poopDeck.config = poopDeck.config or {}
poopDeck.weapons = poopDeck.weapons or {}
poopDeck.command = poopDeck.command or {}
poopDeck.seamonster = poopDeck.seamonster or {}
poopDeck.seamonster.command = poopDeck.seamonster.command or {}

-- Initialize default values
poopDeck.autoSeaMonster = false
poopDeck.maintaining = false
poopDeck.firing = false
poopDeck.oor = false
poopDeck.mode = "manual"
poopDeck.firedSpider = false
poopDeck.seamonsterShots = 0
poopDeck.config.sipHealthPercent = 75

-- Mock the echo functions that would be defined in the actual package
poopDeck.badEcho = function(message)
    -- Mock implementation
end

poopDeck.goodEcho = function(message)
    -- Mock implementation
end

poopDeck.smallGoodEcho = function(message)
    -- Mock implementation
end

-- Constants that would be defined in the package
poopDeck.constants = {
    FIVE_MINUTES = 900,
    ONE_MINUTE = 1140,
    NEW_MONSTER = 1200
}

-- Message tables
poopDeck.spottedSeamonsterMessages = {
    "🐉🌊 Rising Behemoth! 🌊🐉"
}

poopDeck.deadSeamonsterMessages = {
    "🚢🐉 Triumphant Victory! 🐉🚢"
}

print("poopDeck test environment initialized")