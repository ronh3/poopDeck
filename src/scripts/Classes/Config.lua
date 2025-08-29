-- Config Class for poopDeck
-- Handles configuration persistence and settings with OOP pattern

local Config = {}
Config.__index = Config

-- Constructor
function Config:new(filename)
    local self = setmetatable({}, Config)
    
    -- Configuration storage
    self.filename = filename or getMudletHomeDir() .. "/poopDeckconfig.lua"
    self.data = {}
    self.defaults = {
        sipHealthPercent = 75,
        autoFire = false,
        selectedWeapon = nil,
        maintainMode = false,
        version = "2.0"
    }
    
    -- Load existing config or set defaults
    self:load()
    
    -- Register event handlers
    self:registerEventHandlers()
    
    return self
end

-- Register for Mudlet events
function Config:registerEventHandlers()
    local self = self  -- Capture self in closure
    
    -- System events
    registerAnonymousEventHandler("sysExitEvent", function()
        self:save()
    end)
    
    registerAnonymousEventHandler("sysLoadEvent", function()
        self:load()
    end)
    
    -- Configuration change events
    registerAnonymousEventHandler("poopDeck.configChanged", function(event, key, value)
        self:set(key, value)
    end)
end

-- Load configuration from file
function Config:load()
    if io.exists(self.filename) then
        local success = pcall(function()
            self.data = {}  -- Clear existing data
            table.load(self.filename, self.data)
        end)
        
        if not success then
            echo("poopDeck: Warning - Could not load config file, using defaults\n")
            self.data = {}
        end
    end
    
    -- Ensure all defaults are set
    for key, value in pairs(self.defaults) do
        if self.data[key] == nil then
            self.data[key] = value
        end
    end
    
    -- Raise event that config was loaded
    raiseEvent("poopDeck.configLoaded", self.data)
end

-- Save configuration to file
function Config:save()
    local success = pcall(function()
        table.save(self.filename, self.data)
    end)
    
    if not success then
        echo("poopDeck: Warning - Could not save config file\n")
    end
end

-- Get configuration value
function Config:get(key)
    return self.data[key]
end

-- Set configuration value
function Config:set(key, value)
    local oldValue = self.data[key]
    self.data[key] = value
    
    -- Raise event about the change
    raiseEvent("poopDeck.configValueChanged", key, value, oldValue)
    
    -- Auto-save on changes (optional - could be disabled for performance)
    self:save()
    
    return self  -- Return self for method chaining
end

-- Get all configuration data
function Config:getAll()
    -- Return a copy to prevent external modification
    local copy = {}
    for key, value in pairs(self.data) do
        copy[key] = value
    end
    return copy
end

-- Reset to defaults
function Config:reset()
    self.data = {}
    for key, value in pairs(self.defaults) do
        self.data[key] = value
    end
    
    self:save()
    raiseEvent("poopDeck.configReset")
    
    return self
end

-- Update multiple values at once
function Config:update(values)
    for key, value in pairs(values) do
        self.data[key] = value
        raiseEvent("poopDeck.configValueChanged", key, value, nil)
    end
    
    self:save()
    raiseEvent("poopDeck.configUpdated", values)
    
    return self
end

-- Validate configuration values
function Config:validate()
    local errors = {}
    
    -- Validate sipHealthPercent
    local healthPercent = self.data.sipHealthPercent
    if type(healthPercent) ~= "number" or healthPercent < 0 or healthPercent > 100 then
        table.insert(errors, "sipHealthPercent must be a number between 0 and 100")
        self.data.sipHealthPercent = self.defaults.sipHealthPercent
    end
    
    -- Validate weapon selection
    local weapon = self.data.selectedWeapon
    if weapon and weapon ~= "ballista" and weapon ~= "onager" and weapon ~= "thrower" then
        table.insert(errors, "selectedWeapon must be ballista, onager, or thrower")
        self.data.selectedWeapon = nil
    end
    
    if #errors > 0 then
        raiseEvent("poopDeck.configValidationErrors", errors)
        self:save()  -- Save corrected values
    end
    
    return #errors == 0, errors
end

-- Helper methods for common config operations
function Config:getHealthPercent()
    return self.data.sipHealthPercent
end

function Config:setHealthPercent(percent)
    if type(percent) ~= "number" or percent < 0 or percent > 100 then
        error("Health percent must be a number between 0 and 100")
    end
    
    self:set("sipHealthPercent", percent)
    raiseEvent("poopDeck.healthPercentChanged", percent)
    
    return self
end

function Config:isAutoFire()
    return self.data.autoFire == true
end

function Config:setAutoFire(enabled)
    self:set("autoFire", enabled == true)
    raiseEvent("poopDeck.autoFireChanged", enabled)
    
    return self
end

function Config:getWeapon()
    return self.data.selectedWeapon
end

function Config:setWeapon(weapon)
    local validWeapons = {ballista = true, onager = true, thrower = true}
    
    if weapon and not validWeapons[weapon] then
        error("Invalid weapon: " .. tostring(weapon))
    end
    
    self:set("selectedWeapon", weapon)
    raiseEvent("poopDeck.weaponChanged", weapon)
    
    return self
end

-- Export the class
return Config