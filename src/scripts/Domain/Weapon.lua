-- Weapon domain class
-- Represents ship weapons and their state

poopDeck.domain = poopDeck.domain or {}

-- Weapon class definition
poopDeck.domain.Weapon = poopDeck.core.BaseClass:extend("Weapon")

-- Static weapon configurations
poopDeck.domain.Weapon.TYPES = {
    ballista = {
        name = "Ballista",
        reloadTime = 3,
        range = 10,
        ammunition = {
            dart = {damage = 1, effect = "none", loadCommand = "load ballista with dart"},
            flare = {damage = 1, effect = "flare", loadCommand = "load ballista with flare"}
        },
        fireCommand = "fire ballista at seamonster"
    },
    onager = {
        name = "Onager",
        reloadTime = 4,
        range = 8,
        ammunition = {
            starshot = {damage = 1, effect = "weaken", loadCommand = "load onager with starshot"},
            spidershot = {damage = 1, effect = "slow", loadCommand = "load onager with spidershot"},
            chainshot = {damage = 2, effect = "none", loadCommand = "load onager with chainshot"}
        },
        fireCommand = "fire onager at seamonster"
    },
    thrower = {
        name = "Weapon Thrower",
        reloadTime = 3.5,
        range = 9,
        ammunition = {
            disc = {damage = 1, effect = "none", loadCommand = "load thrower with disc"},
            wardisc = {damage = 1.5, effect = "none", loadCommand = "load thrower with wardisc"}
        },
        fireCommand = "fire thrower at seamonster"
    }
}

function poopDeck.domain.Weapon:initialize(weaponType, config)
    config = config or {}
    
    -- Validate weapon type
    if not poopDeck.domain.Weapon.TYPES[weaponType] then
        error("Invalid weapon type: " .. tostring(weaponType))
    end
    
    -- Basic properties
    self.type = weaponType
    self.data = poopDeck.domain.Weapon.TYPES[weaponType]
    self.name = self.data.name
    
    -- Weapon state
    self.state = {
        loaded = false,
        currentAmmo = nil,
        firing = false,
        lastFired = 0,
        disabled = false
    }
    
    -- Combat tracking
    self.stats = {
        shotsFired = 0,
        shotsHit = 0,
        shotsMissed = 0,
        totalDamage = 0,
        favoriteAmmo = nil,
        ammoUsage = {}
    }
    
    -- Ammunition management
    self.ammo = {
        selected = config.defaultAmmo or self:getFirstAmmoType(),
        alternating = config.alternating or false,
        alternatePattern = config.alternatePattern or nil,
        alternateIndex = 1
    }
    
    -- Cooldown tracking
    self.cooldown = {
        ready = true,
        readyAt = 0
    }
end

-- Combat methods
function poopDeck.domain.Weapon:load(ammoType)
    if self.state.disabled then
        return false, "Weapon is disabled"
    end
    
    if self.state.firing then
        return false, "Weapon is currently firing"
    end
    
    -- Validate ammo type
    if ammoType and not self.data.ammunition[ammoType] then
        return false, "Invalid ammunition type: " .. tostring(ammoType)
    end
    
    -- Use selected ammo if not specified
    ammoType = ammoType or self:getNextAmmo()
    
    self.state.loaded = true
    self.state.currentAmmo = ammoType
    
    self:emit("loaded", ammoType)
    return true, string.format("%s loaded with %s", self.name, ammoType)
end

function poopDeck.domain.Weapon:fire()
    if self.state.disabled then
        return false, "Weapon is disabled"
    end
    
    if not self.state.loaded then
        return false, "Weapon not loaded"
    end
    
    if self.state.firing then
        return false, "Already firing"
    end
    
    if not self:isReady() then
        local remaining = self.cooldown.readyAt - os.time()
        return false, string.format("Weapon on cooldown (%d seconds)", remaining)
    end
    
    -- Start firing sequence
    self.state.firing = true
    self.state.lastFired = os.time()
    
    -- Update cooldown
    self.cooldown.ready = false
    self.cooldown.readyAt = os.time() + self.data.reloadTime
    
    -- Get ammo data
    local ammoData = self.data.ammunition[self.state.currentAmmo]
    
    -- Update statistics
    self.stats.shotsFired = self.stats.shotsFired + 1
    self.stats.ammoUsage[self.state.currentAmmo] = 
        (self.stats.ammoUsage[self.state.currentAmmo] or 0) + 1
    
    -- Reset weapon state
    self.state.loaded = false
    local firedAmmo = self.state.currentAmmo
    self.state.currentAmmo = nil
    self.state.firing = false
    
    self:emit("fired", firedAmmo, ammoData)
    
    -- Schedule ready event
    tempTimer(self.data.reloadTime, function()
        self.cooldown.ready = true
        self:emit("ready")
    end)
    
    return true, {
        weapon = self.type,
        ammo = firedAmmo,
        effect = ammoData.effect,
        damage = ammoData.damage
    }
end

function poopDeck.domain.Weapon:interrupt()
    if not self.state.firing then
        return false, "Not currently firing"
    end
    
    self.state.firing = false
    self.state.loaded = false
    self.state.currentAmmo = nil
    
    self:emit("interrupted")
    return true, "Firing interrupted"
end

-- Ammunition management
function poopDeck.domain.Weapon:setAmmo(ammoType)
    if not self.data.ammunition[ammoType] then
        return false, "Invalid ammunition type"
    end
    
    self.ammo.selected = ammoType
    self.ammo.alternating = false
    
    self:emit("ammoChanged", ammoType)
    return true, string.format("Selected %s ammunition", ammoType)
end

function poopDeck.domain.Weapon:setAlternating(pattern)
    if not pattern then
        -- Default alternating pattern
        local ammoTypes = self:getAmmoTypes()
        if #ammoTypes < 2 then
            return false, "Need at least 2 ammo types to alternate"
        end
        pattern = ammoTypes
    end
    
    -- Validate pattern
    for _, ammoType in ipairs(pattern) do
        if not self.data.ammunition[ammoType] then
            return false, "Invalid ammo type in pattern: " .. tostring(ammoType)
        end
    end
    
    self.ammo.alternating = true
    self.ammo.alternatePattern = pattern
    self.ammo.alternateIndex = 1
    
    self:emit("alternatingSet", pattern)
    return true, "Alternating ammunition enabled"
end

function poopDeck.domain.Weapon:getNextAmmo()
    if not self.ammo.alternating then
        return self.ammo.selected
    end
    
    local ammo = self.ammo.alternatePattern[self.ammo.alternateIndex]
    self.ammo.alternateIndex = (self.ammo.alternateIndex % #self.ammo.alternatePattern) + 1
    return ammo
end

-- State queries
function poopDeck.domain.Weapon:isReady()
    return self.cooldown.ready and not self.state.disabled
end

function poopDeck.domain.Weapon:getCooldownRemaining()
    if self.cooldown.ready then
        return 0
    end
    return math.max(0, self.cooldown.readyAt - os.time())
end

function poopDeck.domain.Weapon:canFire()
    return self:isReady() and self.state.loaded and not self.state.firing
end

-- Statistics methods
function poopDeck.domain.Weapon:recordHit()
    self.stats.shotsHit = self.stats.shotsHit + 1
    self:emit("hit")
end

function poopDeck.domain.Weapon:recordMiss()
    self.stats.shotsMissed = self.stats.shotsMissed + 1
    self:emit("miss")
end

function poopDeck.domain.Weapon:getAccuracy()
    if self.stats.shotsFired == 0 then
        return 0
    end
    return (self.stats.shotsHit / self.stats.shotsFired) * 100
end

function poopDeck.domain.Weapon:getMostUsedAmmo()
    local maxUsage = 0
    local mostUsed = nil
    
    for ammo, usage in pairs(self.stats.ammoUsage) do
        if usage > maxUsage then
            maxUsage = usage
            mostUsed = ammo
        end
    end
    
    return mostUsed, maxUsage
end

-- Utility methods
function poopDeck.domain.Weapon:getAmmoTypes()
    local types = {}
    for ammoType, _ in pairs(self.data.ammunition) do
        table.insert(types, ammoType)
    end
    return types
end

function poopDeck.domain.Weapon:getFirstAmmoType()
    local types = self:getAmmoTypes()
    return types[1] or "dart"
end

function poopDeck.domain.Weapon:getStatus()
    return {
        type = self.type,
        name = self.name,
        loaded = self.state.loaded,
        currentAmmo = self.state.currentAmmo,
        firing = self.state.firing,
        ready = self:isReady(),
        cooldown = self:getCooldownRemaining(),
        disabled = self.state.disabled,
        shotsFired = self.stats.shotsFired,
        accuracy = string.format("%.1f%%", self:getAccuracy()),
        alternating = self.ammo.alternating
    }
end

function poopDeck.domain.Weapon:getCommands()
    local ammo = self.state.currentAmmo or self:getNextAmmo()
    local ammoData = self.data.ammunition[ammo]
    
    return {
        load = ammoData.loadCommand,
        fire = self.data.fireCommand
    }
end

function poopDeck.domain.Weapon:disable()
    self.state.disabled = true
    self:emit("disabled")
    return true, "Weapon disabled"
end

function poopDeck.domain.Weapon:enable()
    self.state.disabled = false
    self:emit("enabled")
    return true, "Weapon enabled"
end

function poopDeck.domain.Weapon:toString()
    return string.format("[Weapon: %s (%s) - %s]", 
        self.name, 
        self.type,
        self.state.loaded and "Loaded" or "Not loaded")
end

-- Class method to get all weapon types
function poopDeck.domain.Weapon.getAllTypes()
    local types = {}
    for weaponType, _ in pairs(poopDeck.domain.Weapon.TYPES) do
        table.insert(types, weaponType)
    end
    return types
end