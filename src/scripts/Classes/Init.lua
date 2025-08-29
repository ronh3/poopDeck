-- poopDeck OOP Initialization Module
-- This script initializes all classes and wires them together

-- Import all class modules
local Display = require("poopDeck.Classes.Display")
local Config = require("poopDeck.Classes.Config")
local Ship = require("poopDeck.Classes.Ship")
local SeamonsterCombat = require("poopDeck.Classes.SeamonsterCombat")

-- Initialize poopDeck namespace if it doesn't exist
poopDeck = poopDeck or {}
poopDeck.version = "2.0-OOP"

-- Initialize function called on package load
function poopDeck.initialize()
    -- Create config instance first (other classes may depend on it)
    poopDeck.config = Config:new()
    
    -- Create display instance
    poopDeck.display = Display:new(poopDeck.config)
    
    -- Create ship instance
    poopDeck.ship = Ship:new(poopDeck.config)
    
    -- Create combat instance (needs config and ship references)
    poopDeck.combat = SeamonsterCombat:new(poopDeck.config, poopDeck.ship)
    
    -- Set up any saved configuration
    if poopDeck.config:get("selectedWeapon") then
        poopDeck.combat:setWeapon(poopDeck.config:get("selectedWeapon"))
    end
    
    if poopDeck.config:get("autoFire") then
        poopDeck.combat:setAutoMode(poopDeck.config:get("autoFire"))
    end
    
    -- Display initialization message
    poopDeck.display:showMessage("poopDeck v" .. poopDeck.version .. " initialized!", "good")
    
    -- Raise initialization event
    raiseEvent("poopDeck.initialized", poopDeck.version)
end

-- Shutdown function for cleanup
function poopDeck.shutdown()
    -- Save configuration
    if poopDeck.config then
        poopDeck.config:save()
    end
    
    -- Clean up any active combat
    if poopDeck.combat then
        poopDeck.combat:cleanupCombat()
    end
    
    -- Raise shutdown event
    raiseEvent("poopDeck.shutdown")
end

-- Helper function to get status of all systems
function poopDeck.status()
    local status = {
        version = poopDeck.version,
        ship = poopDeck.ship and poopDeck.ship:getState() or "Not initialized",
        combat = poopDeck.combat and poopDeck.combat:getCombatStatus() or "Not initialized",
        config = poopDeck.config and poopDeck.config:getAll() or "Not initialized"
    }
    
    display(status)
    return status
end

-- Convenience functions that delegate to class methods
-- These maintain backward compatibility with existing aliases

-- Ship functions
function poopDeck.turnShip(heading)
    if poopDeck.ship then
        poopDeck.ship:turn(heading)
    end
end

function poopDeck.setSpeed(speed)
    if poopDeck.ship then
        poopDeck.ship:setSpeed(speed)
    end
end

function poopDeck.dock(direction)
    if poopDeck.ship then
        poopDeck.ship:dock(direction)
    end
end

function poopDeck.anchor(action)
    if poopDeck.ship then
        poopDeck.ship:anchor(action)
    end
end

function poopDeck.command(cmd, arg)
    -- Map old command system to new methods
    local commandMap = {
        allStop = function() poopDeck.ship:allStop() end,
        anchor = function(a) poopDeck.ship:anchor(a) end,
        castoff = function() poopDeck.ship:castOff() end,
        chop = function() poopDeck.ship:chopTether() end,
        clearRigging = function() poopDeck.ship:clearRigging() end,
        commScreen = function(a) poopDeck.ship:commScreen(a) end,
        douse = function(a) poopDeck.ship:douse(a) end,
        maintain = function(a) poopDeck.ship:maintain(a) end,
        plank = function(a) poopDeck.ship:plank(a) end,
        rainstorm = function() poopDeck.ship:invokeRainstorm() end,
        relaxOars = function() poopDeck.ship:relaxOars() end,
        rowOars = function() poopDeck.ship:row() end,
        shipRepairs = function() poopDeck.ship:repairAll() end,
        shipRescue = function() poopDeck.ship:rescue() end,
        shipWarning = function(a) poopDeck.ship:shipWarning(a == "on") end,
        windboost = function() poopDeck.ship:invokeWindboost() end
    }
    
    local func = commandMap[cmd]
    if func then
        func(arg)
    else
        echo("Unknown command: " .. tostring(cmd) .. "\n")
    end
end

function poopDeck.wavecall(heading, distance)
    if poopDeck.ship then
        poopDeck.ship:wavecall(heading, distance)
    end
end

-- Combat functions
function poopDeck.setWeapon(weapon)
    if poopDeck.combat then
        poopDeck.combat:setWeapon(weapon)
    end
end

function poopDeck.setSeamonsterAutoFire(mode)
    if poopDeck.combat then
        poopDeck.combat:setAutoMode(mode == "on")
    end
end

function poopDeck.seaFire(ammo)
    if poopDeck.combat then
        poopDeck.combat:manualFire(ammo)
    end
end

function poopDeck.autoFire()
    if poopDeck.combat then
        poopDeck.combat:fire()
    end
end

-- Config functions
function poopDeck.setHealth(percent)
    if poopDeck.config then
        poopDeck.config:setHealthPercent(percent)
    end
end

function poopDeck.setMaintain(maintain)
    -- This is now handled by the ship class
    -- Keeping for backward compatibility
    if poopDeck.ship then
        local maintainMap = {h = "hull", s = "sails", n = "none"}
        poopDeck.ship:maintain(maintainMap[maintain] or maintain)
    end
end

-- Register initialization and shutdown handlers
registerAnonymousEventHandler("sysLoadEvent", poopDeck.initialize)
registerAnonymousEventHandler("sysExitEvent", poopDeck.shutdown)

-- Also allow manual initialization
if poopDeck.manualInit then
    poopDeck.initialize()
end