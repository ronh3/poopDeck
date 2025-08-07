-- Combat Service
-- Orchestrates seamonster combat using domain objects

poopDeck.services = poopDeck.services or {}

-- CombatService class definition
poopDeck.services.CombatService = poopDeck.core.BaseClass:extend("CombatService")

function poopDeck.services.CombatService:initialize(ship, config)
    config = config or {}
    
    -- Dependencies
    self.ship = ship
    self.currentMonster = nil
    self.activeWeapon = nil
    
    -- Combat settings
    self.settings = {
        autoFire = config.autoFire or false,
        healthThreshold = config.healthThreshold or 75,
        maintainDuringCombat = config.maintainDuringCombat or "hull",
        preferredWeapon = config.preferredWeapon or "ballista",
        alternateAmmo = config.alternateAmmo or true
    }
    
    -- Combat state
    self.state = {
        inCombat = false,
        firing = false,
        outOfRange = false,
        needsHealing = false,
        interrupted = false
    }
    
    -- Combat statistics
    self.statistics = {
        monstersKilled = 0,
        totalShots = 0,
        totalTime = 0,
        sessionStart = os.time()
    }
    
    -- Firing queue
    self.firingQueue = {}
    
    -- Set up event listeners
    self:setupEventListeners()
end

function poopDeck.services.CombatService:setupEventListeners()
    -- Listen to ship events
    if self.ship then
        self.ship:on("damageReceived", function(ship, component, amount)
            self:onShipDamaged(component, amount)
        end)
    end
end

-- Monster management
function poopDeck.services.CombatService:engageMonster(monsterName)
    -- Create new monster instance
    self.currentMonster = poopDeck.domain.Seamonster(monsterName)
    
    -- Set up monster event listeners
    self.currentMonster:on("killed", function(monster, data)
        self:onMonsterKilled(data)
    end)
    
    self.currentMonster:on("shotReceived", function(monster, shotType, current, remaining)
        self:onShotReceived(shotType, current, remaining)
    end)
    
    self.currentMonster:on("rangeChanged", function(monster, range)
        self:onRangeChanged(range)
    end)
    
    self.state.inCombat = true
    self:emit("combatStarted", monsterName)
    
    -- Start auto-fire if enabled
    if self.settings.autoFire then
        self:startAutoFire()
    end
    
    return true, string.format("Engaging %s", monsterName)
end

function poopDeck.services.CombatService:disengageMonster()
    if not self.currentMonster then
        return false, "No monster to disengage"
    end
    
    self.state.inCombat = false
    self.state.firing = false
    
    local monsterName = self.currentMonster.name
    self.currentMonster = nil
    
    self:emit("combatEnded", monsterName)
    return true, "Combat ended"
end

-- Weapon management
function poopDeck.services.CombatService:selectWeapon(weaponType)
    -- Validate weapon exists on ship
    local weapon = self.ship:getWeapon(weaponType)
    if not weapon then
        -- Create and add weapon to ship
        weapon = poopDeck.domain.Weapon(weaponType)
        self.ship:addWeapon(weapon)
    end
    
    self.activeWeapon = weapon
    self.settings.preferredWeapon = weaponType
    
    -- Set up weapon event listeners
    weapon:on("fired", function(w, ammo, ammoData)
        self:onWeaponFired(ammo, ammoData)
    end)
    
    weapon:on("ready", function(w)
        self:onWeaponReady()
    end)
    
    self:emit("weaponSelected", weaponType)
    return true, string.format("Selected %s", weapon.name)
end

function poopDeck.services.CombatService:getActiveWeapon()
    if self.activeWeapon then
        return self.activeWeapon
    end
    
    -- Try to get preferred weapon
    if self.settings.preferredWeapon then
        self:selectWeapon(self.settings.preferredWeapon)
        return self.activeWeapon
    end
    
    return nil
end

-- Combat operations
function poopDeck.services.CombatService:fire()
    if not self.state.inCombat then
        return false, "Not in combat"
    end
    
    if not self.currentMonster or not self.currentMonster.state.alive then
        return false, "No valid target"
    end
    
    if self.state.outOfRange then
        return false, "Target out of range"
    end
    
    local weapon = self:getActiveWeapon()
    if not weapon then
        return false, "No weapon selected"
    end
    
    -- Check health
    if self:needsHealing() then
        self:emit("healingNeeded")
        return false, "Need healing"
    end
    
    -- Maintenance check
    if self.settings.maintainDuringCombat then
        self:performMaintenance()
    end
    
    -- Load weapon if needed
    if not weapon.state.loaded then
        local success, msg = weapon:load()
        if not success then
            return false, msg
        end
        send(weapon:getCommands().load)
    end
    
    -- Fire weapon
    local success, result = weapon:fire()
    if not success then
        return false, result
    end
    
    -- Send fire command to game
    send(weapon:getCommands().fire)
    
    -- Update monster
    self.currentMonster:receiveShot(result.ammo, weapon.type)
    
    self.statistics.totalShots = self.statistics.totalShots + 1
    self.state.firing = true
    
    return true, result
end

function poopDeck.services.CombatService:startAutoFire()
    if not self.settings.autoFire then
        self.settings.autoFire = true
    end
    
    if not self.state.inCombat then
        return false, "Not in combat"
    end
    
    self:emit("autoFireStarted")
    self:autoFireLoop()
    return true, "Auto-fire started"
end

function poopDeck.services.CombatService:stopAutoFire()
    self.settings.autoFire = false
    self:emit("autoFireStopped")
    return true, "Auto-fire stopped"
end

function poopDeck.services.CombatService:autoFireLoop()
    if not self.settings.autoFire or not self.state.inCombat then
        return
    end
    
    -- Attempt to fire
    local success, result = self:fire()
    
    if success then
        -- Schedule next fire after weapon cooldown
        local weapon = self:getActiveWeapon()
        if weapon then
            tempTimer(weapon.data.reloadTime + 0.5, function()
                self:autoFireLoop()
            end)
        end
    else
        -- Retry in 2 seconds if failed
        tempTimer(2, function()
            self:autoFireLoop()
        end)
    end
end

-- Health management
function poopDeck.services.CombatService:needsHealing()
    -- Check GMCP health data safely
    local health = poopDeck.safe.getHealth("combat_needs_healing")
    return health.percent < self.settings.healthThreshold
end

function poopDeck.services.CombatService:performMaintenance()
    if not self.settings.maintainDuringCombat then
        return
    end
    
    local maintainTarget = self.settings.maintainDuringCombat
    if maintainTarget == "hull" or maintainTarget == "sails" then
        send("maintain " .. maintainTarget)
    end
end

-- Event handlers
function poopDeck.services.CombatService:onMonsterKilled(data)
    self.statistics.monstersKilled = self.statistics.monstersKilled + 1
    self.state.inCombat = false
    
    -- Display victory message
    local messages = {
        "🚢🐉 Triumphant Victory! 🐉🚢",
        "⚓🌊 Monster Subdued! 🌊⚓",
        "🔱🌊 Beast Beneath Conquered! 🌊🔱"
    }
    local message = messages[math.random(#messages)]
    
    self:emit("monsterKilled", data)
    
    -- Schedule warning for next monster
    tempTimer(900, function()  -- 15 minutes
        self:emit("monsterWarning", "5 minutes")
    end)
    
    tempTimer(1140, function()  -- 19 minutes
        self:emit("monsterWarning", "1 minute")
    end)
    
    tempTimer(1200, function()  -- 20 minutes
        self:emit("monsterWarning", "Monster incoming!")
    end)
end

function poopDeck.services.CombatService:onShotReceived(shotType, current, remaining)
    self:emit("shotLanded", {
        type = shotType,
        current = current,
        remaining = remaining
    })
end

function poopDeck.services.CombatService:onRangeChanged(range)
    self.state.outOfRange = (range == "out_of_range")
    
    if self.state.outOfRange then
        self:emit("outOfRange")
    else
        self:emit("inRange")
        -- Resume auto-fire if it was active
        if self.settings.autoFire then
            self:autoFireLoop()
        end
    end
end

function poopDeck.services.CombatService:onWeaponFired(ammo, ammoData)
    self.state.firing = false
    self:emit("weaponFired", {
        ammo = ammo,
        effect = ammoData.effect,
        damage = ammoData.damage
    })
end

function poopDeck.services.CombatService:onWeaponReady()
    self:emit("weaponReady")
end

function poopDeck.services.CombatService:onShipDamaged(component, amount)
    -- Auto-repair if needed
    if self.ship.maintenance.autoRepair then
        local percent = (self.ship.condition[component].current / self.ship.condition[component].max) * 100
        if percent < self.ship.maintenance.threshold then
            self:performMaintenance()
        end
    end
end

-- Settings management
function poopDeck.services.CombatService:setHealthThreshold(percent)
    self.settings.healthThreshold = tonumber(percent) or 75
    self:emit("settingChanged", "healthThreshold", self.settings.healthThreshold)
    return true, string.format("Health threshold set to %d%%", self.settings.healthThreshold)
end

function poopDeck.services.CombatService:setMaintenance(target)
    if target ~= "hull" and target ~= "sails" and target ~= "none" then
        return false, "Invalid maintenance target"
    end
    
    self.settings.maintainDuringCombat = (target == "none") and nil or target
    self:emit("settingChanged", "maintenance", target)
    return true, string.format("Maintenance set to %s", target)
end

function poopDeck.services.CombatService:toggleAutoFire()
    if self.settings.autoFire then
        return self:stopAutoFire()
    else
        return self:startAutoFire()
    end
end

-- Status and statistics
function poopDeck.services.CombatService:getStatus()
    return {
        inCombat = self.state.inCombat,
        autoFire = self.settings.autoFire,
        monster = self.currentMonster and self.currentMonster:getStatus() or nil,
        weapon = self.activeWeapon and self.activeWeapon:getStatus() or nil,
        settings = {
            healthThreshold = self.settings.healthThreshold,
            maintenance = self.settings.maintainDuringCombat,
            preferredWeapon = self.settings.preferredWeapon
        },
        statistics = {
            monstersKilled = self.statistics.monstersKilled,
            totalShots = self.statistics.totalShots,
            sessionTime = os.time() - self.statistics.sessionStart
        }
    }
end

function poopDeck.services.CombatService:toString()
    return string.format("[CombatService: %s]", 
        self.state.inCombat and "In Combat" or "Idle")
end