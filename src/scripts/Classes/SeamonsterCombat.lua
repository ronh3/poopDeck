-- SeamonsterCombat Class for poopDeck
-- Handles seamonster tracking, weapon management, and combat automation

local SeamonsterCombat = {}
SeamonsterCombat.__index = SeamonsterCombat

-- Constructor
function SeamonsterCombat:new(config, ship)
    local self = setmetatable({}, SeamonsterCombat)
    
    -- Dependencies
    self.config = config
    self.ship = ship  -- Reference to ship for health checks
    
    -- Combat state
    self.state = {
        inCombat = false,
        currentMonster = nil,
        monsterHealth = 0,
        shotsFired = 0,
        shotsRemaining = 0,
        
        -- Firing state
        isFiring = false,
        outOfRange = false,
        lastFireTime = 0,
        fireTimer = nil,
        
        -- Auto-fire state
        mode = "manual",  -- "manual" or "automatic"
        autoFireEnabled = false,
        firedSpider = false  -- For alternating onager shots
    }
    
    -- Weapon configuration
    self.weapons = {
        current = nil,  -- Currently selected weapon
        ballista = false,
        onager = false,
        thrower = false
    }
    
    -- Monster database (shots required to kill)
    self.monsterDatabase = {
        ["a legendary leviathan"] = 60,
        ["a hulking oceanic cyclops"] = 60,
        ["a towering oceanic hydra"] = 60,
        ["a sea hag"] = 40,
        ["a monstrous ketea"] = 40,
        ["a monstrous picaroon"] = 40,
        ["an unmarked warship"] = 40,
        ["a red-sailed Kashari raider"] = 30,
        ["a furious sea dragon"] = 30,
        ["a pirate ship"] = 30,
        ["a trio of raging sea serpents"] = 30,
        ["a raging shraymor"] = 25,
        ["a mass of sargassum"] = 25,
        ["a gargantuan megalodon"] = 25,
        ["a gargantuan angler fish"] = 25,
        ["a mudback septacean"] = 20,
        ["a flying sheilei"] = 20,
        ["a foam-wreathed sea serpent"] = 20,
        ["a red-faced septacean"] = 20
    }
    
    -- Timers for monster warnings
    self.timers = {
        fiveMinute = nil,
        oneMinute = nil,
        spawnTimer = nil
    }
    
    -- Constants
    self.RELOAD_TIME = 4  -- Seconds between shots
    self.FIVE_MINUTES = 900
    self.ONE_MINUTE = 1140
    self.NEW_MONSTER = 1200
    
    -- Register event handlers
    self:registerEventHandlers()
    
    return self
end

-- Register for Mudlet events
function SeamonsterCombat:registerEventHandlers()
    local self = self
    
    -- Monster spawn/death events
    registerAnonymousEventHandler("poopDeck.monsterSpawned", function(event, monsterName)
        self:onMonsterSpawn(monsterName)
    end)
    
    registerAnonymousEventHandler("poopDeck.monsterKilled", function(event, monsterName)
        self:onMonsterDeath(monsterName)
    end)
    
    -- Someone else killed it
    registerAnonymousEventHandler("poopDeck.monsterKilledExternal", function(event)
        self:onMonsterDeathExternal()
    end)
    
    -- Firing events
    registerAnonymousEventHandler("poopDeck.weaponFired", function(event, weapon)
        self:onWeaponFired(weapon)
    end)
    
    registerAnonymousEventHandler("poopDeck.outOfRange", function()
        self:onOutOfRange()
    end)
    
    registerAnonymousEventHandler("poopDeck.shotInterrupted", function()
        self:onShotInterrupted()
    end)
    
    registerAnonymousEventHandler("poopDeck.shotHit", function(event, target)
        self:onShotHit(target)
    end)
    
    -- Ship movement for range checks
    registerAnonymousEventHandler("poopDeck.shipMoved", function()
        self:onShipMoved()
    end)
    
    -- Config changes
    registerAnonymousEventHandler("poopDeck.configValueChanged", function(event, key, value)
        if key == "autoFire" then
            self:setAutoMode(value)
        elseif key == "selectedWeapon" then
            self:setWeapon(value)
        end
    end)
end

-- Monster spawn handling
function SeamonsterCombat:onMonsterSpawn(monsterName)
    -- Clean up any previous combat state first
    self:cleanupCombat()
    
    -- Set up new combat
    self.state.inCombat = true
    self.state.currentMonster = monsterName
    self.state.shotsFired = 0
    
    -- Look up monster health
    local totalShots = self.monsterDatabase[monsterName]
    if totalShots then
        self.state.monsterHealth = totalShots
        self.state.shotsRemaining = totalShots
    else
        -- Unknown monster, use default
        self.state.monsterHealth = 30
        self.state.shotsRemaining = 30
    end
    
    -- Set up warning timers
    self:setupWarningTimers()
    
    -- Raise event for other systems
    raiseEvent("poopDeck.combatStarted", monsterName, self.state.monsterHealth)
    
    -- Start auto-fire if enabled
    if self.state.mode == "automatic" and self.weapons.current then
        tempTimer(0.5, function() self:startAutoFire() end)
    end
end

-- Monster death handling (we killed it)
function SeamonsterCombat:onMonsterDeath(monsterName)
    -- Clean up combat state
    self:cleanupCombat()
    
    -- Re-enable curing if it was disabled
    self:toggleCuring(true)
    
    -- Raise completion event
    raiseEvent("poopDeck.combatEnded", monsterName, "victory")
end

-- Monster death by someone else
function SeamonsterCombat:onMonsterDeathExternal()
    -- Clean up combat state without victory message
    self:cleanupCombat()
    
    -- Re-enable curing
    self:toggleCuring(true)
    
    -- Raise event indicating external kill
    raiseEvent("poopDeck.combatEnded", self.state.currentMonster, "external")
end

-- Clean up all combat state
function SeamonsterCombat:cleanupCombat()
    -- Cancel all timers
    if self.state.fireTimer then
        killTimer(self.state.fireTimer)
        self.state.fireTimer = nil
    end
    
    for _, timer in pairs(self.timers) do
        if timer then killTimer(timer) end
    end
    self.timers = {fiveMinute = nil, oneMinute = nil, spawnTimer = nil}
    
    -- Reset state
    self.state.inCombat = false
    self.state.currentMonster = nil
    self.state.shotsFired = 0
    self.state.shotsRemaining = 0
    self.state.isFiring = false
    self.state.outOfRange = false
    
    -- Disable movement trigger if it was enabled
    disableTrigger("Ship Moved Lets Try Again")
end

-- Set up warning timers for next monster spawn
function SeamonsterCombat:setupWarningTimers()
    local timerName = os.date("monster%H%M%S")
    
    self.timers.fiveMinute = tempTimer(self.FIVE_MINUTES, function()
        raiseEvent("poopDeck.monsterWarning", 5)
    end)
    
    self.timers.oneMinute = tempTimer(self.ONE_MINUTE, function()
        raiseEvent("poopDeck.monsterWarning", 1)
    end)
    
    self.timers.spawnTimer = tempTimer(self.NEW_MONSTER, function()
        raiseEvent("poopDeck.monsterSpawnExpected")
    end)
end

-- Weapon management
function SeamonsterCombat:setWeapon(weapon)
    -- Validate weapon
    if weapon ~= "ballista" and weapon ~= "onager" and weapon ~= "thrower" then
        error("Invalid weapon: " .. tostring(weapon))
    end
    
    -- Reset all weapon flags
    self.weapons.ballista = false
    self.weapons.onager = false
    self.weapons.thrower = false
    
    -- Set the selected weapon
    self.weapons[weapon] = true
    self.weapons.current = weapon
    
    raiseEvent("poopDeck.weaponSet", weapon)
    return self
end

-- Mode management
function SeamonsterCombat:setAutoMode(enabled)
    self.state.mode = enabled and "automatic" or "manual"
    self.state.autoFireEnabled = enabled
    
    raiseEvent("poopDeck.modeChanged", self.state.mode)
    
    -- If switching to auto and in combat, start firing
    if enabled and self.state.inCombat and not self.state.isFiring then
        self:startAutoFire()
    end
    
    return self
end

-- Start automatic firing
function SeamonsterCombat:startAutoFire()
    if not self.state.inCombat or self.state.isFiring then
        return
    end
    
    if not self.weapons.current then
        raiseEvent("poopDeck.combatError", "No weapon selected")
        return
    end
    
    self:fire()
end

-- Main firing logic
function SeamonsterCombat:fire()
    -- Check if we're already firing or out of range
    if self.state.isFiring or self.state.outOfRange then
        return
    end
    
    -- Check if we should disable curing for low health
    if not self:shouldDisableCuring() then
        self:toggleCuring(true)
        raiseEvent("poopDeck.combatPaused", "Need to heal")
        
        -- Retry in a few seconds if auto mode
        if self.state.mode == "automatic" then
            tempTimer(3, function() self:fire() end)
        end
        return
    end
    
    -- Disable curing and start firing
    self:toggleCuring(false)
    self.state.isFiring = true
    self.state.lastFireTime = os.time()
    
    -- Get weapon commands
    local commands = self:getWeaponCommands()
    if commands then
        sendAll(unpack(commands))
        raiseEvent("poopDeck.firingWeapon", self.weapons.current)
    end
end

-- Get commands for current weapon
function SeamonsterCombat:getWeaponCommands()
    local weapon = self.weapons.current
    
    if weapon == "ballista" then
        return {"maintain hull", "load ballista with dart", "fire ballista at seamonster"}
    elseif weapon == "thrower" then
        return {"maintain hull", "load thrower with disc", "fire thrower at seamonster"}
    elseif weapon == "onager" then
        -- Alternate between spider and star shot
        if self.state.firedSpider then
            self.state.firedSpider = false
            return {"maintain hull", "load onager with starshot", "fire onager at seamonster"}
        else
            self.state.firedSpider = true
            return {"maintain hull", "load onager with spidershot", "fire onager at seamonster"}
        end
    end
    
    return nil
end

-- Manual fire with specific ammo
function SeamonsterCombat:manualFire(ammoType)
    if self.state.isFiring then
        return
    end
    
    local ammoCommands = {
        b = {"maintain hull", "load ballista with dart", "fire ballista at seamonster"},
        bf = {"maintain hull", "load ballista with flare", "fire ballista at seamonster"},
        sp = {"maintain hull", "load onager with spidershot", "fire onager at seamonster"},
        c = {"maintain hull", "load onager with chainshot", "fire onager at seamonster"},
        st = {"maintain hull", "load onager with starshot", "fire onager at seamonster"},
        d = {"maintain hull", "load thrower with disc", "fire thrower at seamonster"}
    }
    
    local commands = ammoCommands[ammoType]
    if not commands then
        raiseEvent("poopDeck.combatError", "Unknown ammo type: " .. tostring(ammoType))
        return
    end
    
    if not self:shouldDisableCuring() then
        self:toggleCuring(true)
        raiseEvent("poopDeck.combatPaused", "Need to heal")
        return
    end
    
    self:toggleCuring(false)
    self.state.isFiring = true
    sendAll(unpack(commands))
    raiseEvent("poopDeck.firingWeapon", "manual", ammoType)
end

-- Handle successful weapon fire
function SeamonsterCombat:onWeaponFired(weapon)
    self.state.isFiring = false
    self:toggleCuring(true)
    
    -- Schedule next shot if auto mode
    if self.state.mode == "automatic" and self.state.inCombat then
        self.state.fireTimer = tempTimer(self.RELOAD_TIME, function()
            self:fire()
        end)
    else
        -- Manual mode - just notify ready
        tempTimer(self.RELOAD_TIME, function()
            raiseEvent("poopDeck.readyToFire")
        end)
    end
end

-- Handle shot hitting monster
function SeamonsterCombat:onShotHit(target)
    if not self.state.inCombat then
        return
    end
    
    self.state.shotsFired = self.state.shotsFired + 1
    self.state.shotsRemaining = math.max(0, self.state.monsterHealth - self.state.shotsFired)
    
    raiseEvent("poopDeck.shotFired", self.state.shotsFired, self.state.shotsRemaining)
end

-- Handle out of range
function SeamonsterCombat:onOutOfRange()
    self.state.isFiring = false
    self.state.outOfRange = true
    self:toggleCuring(true)
    
    -- Enable movement trigger for auto mode
    if self.state.mode == "automatic" then
        enableTrigger("Ship Moved Lets Try Again")
    end
    
    raiseEvent("poopDeck.outOfRange")
end

-- Handle ship movement (to retry after out of range)
function SeamonsterCombat:onShipMoved()
    if self.state.outOfRange and self.state.mode == "automatic" then
        self.state.outOfRange = false
        disableTrigger("Ship Moved Lets Try Again")
        tempTimer(0.5, function() self:fire() end)
    end
end

-- Handle shot interruption
function SeamonsterCombat:onShotInterrupted()
    self.state.isFiring = false
    self:toggleCuring(true)
    
    if self.state.mode == "automatic" then
        -- Retry after delay
        tempTimer(self.RELOAD_TIME, function()
            self:fire()
        end)
    end
    
    raiseEvent("poopDeck.shotInterrupted")
end

-- Curing management
function SeamonsterCombat:shouldDisableCuring()
    if not self.config then
        return true  -- No config, default to allowing fire
    end
    
    local healthPercent = tonumber(gmcp.Char.Vitals.hp) / tonumber(gmcp.Char.Vitals.maxhp) * 100
    local threshold = self.config:get("sipHealthPercent") or 75
    
    return healthPercent >= threshold
end

function SeamonsterCombat:toggleCuring(enable)
    if enable then
        send("curing on")
    else
        send("curing off")
    end
end

-- Query methods
function SeamonsterCombat:getCombatStatus()
    return {
        inCombat = self.state.inCombat,
        monster = self.state.currentMonster,
        shotsFired = self.state.shotsFired,
        shotsRemaining = self.state.shotsRemaining,
        mode = self.state.mode,
        weapon = self.weapons.current,
        isFiring = self.state.isFiring,
        outOfRange = self.state.outOfRange
    }
end

function SeamonsterCombat:isInCombat()
    return self.state.inCombat
end

function SeamonsterCombat:getCurrentMonster()
    return self.state.currentMonster
end

-- Export the class
return SeamonsterCombat