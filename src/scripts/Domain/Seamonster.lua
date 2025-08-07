-- Seamonster domain class
-- Represents seamonsters and their combat state

poopDeck.domain = poopDeck.domain or {}

-- Seamonster class definition
poopDeck.domain.Seamonster = poopDeck.core.BaseClass:extend("Seamonster")

-- Static monster data
poopDeck.domain.Seamonster.TYPES = {
    -- Legendary (60 shots)
    ["a legendary leviathan"] = {shots = 60, tier = "legendary", xp = 1000},
    ["a hulking oceanic cyclops"] = {shots = 60, tier = "legendary", xp = 1000},
    ["a towering oceanic hydra"] = {shots = 60, tier = "legendary", xp = 1000},
    
    -- Major (40 shots)
    ["a sea hag"] = {shots = 40, tier = "major", xp = 750},
    ["a monstrous ketea"] = {shots = 40, tier = "major", xp = 750},
    ["a monstrous picaroon"] = {shots = 40, tier = "major", xp = 750},
    ["an unmarked warship"] = {shots = 40, tier = "major", xp = 750},
    
    -- Standard (30 shots)
    ["a red-sailed Kashari raider"] = {shots = 30, tier = "standard", xp = 500},
    ["a furious sea dragon"] = {shots = 30, tier = "standard", xp = 500},
    ["a pirate ship"] = {shots = 30, tier = "standard", xp = 500},
    ["a trio of raging sea serpents"] = {shots = 30, tier = "standard", xp = 500},
    
    -- Minor (20-25 shots)
    ["a raging shraymor"] = {shots = 25, tier = "minor", xp = 300},
    ["a mass of sargassum"] = {shots = 25, tier = "minor", xp = 300},
    ["a gargantuan megalodon"] = {shots = 25, tier = "minor", xp = 300},
    ["a gargantuan angler fish"] = {shots = 25, tier = "minor", xp = 300},
    ["a mudback septacean"] = {shots = 20, tier = "minor", xp = 250},
    ["a flying sheilei"] = {shots = 20, tier = "minor", xp = 250},
    ["a foam-wreathed sea serpent"] = {shots = 20, tier = "minor", xp = 250},
    ["a red-faced septacean"] = {shots = 20, tier = "minor", xp = 250}
}

function poopDeck.domain.Seamonster:initialize(name, config)
    config = config or {}
    
    -- Basic properties
    self.name = name
    self.data = poopDeck.domain.Seamonster.TYPES[name] or {shots = 30, tier = "unknown", xp = 0}
    
    -- Combat state
    self.state = {
        alive = true,
        surfaced = true,
        flared = false,
        range = "in_range",
        lastSeen = os.time()
    }
    
    -- Combat tracking
    self.combat = {
        shotsReceived = 0,
        shotsRequired = self.data.shots,
        damageDealt = 0,
        startTime = os.time(),
        endTime = nil
    }
    
    -- Debuffs applied
    self.debuffs = {
        slowed = false,         -- From spidershot
        weakened = false,       -- From starshot
        flared = false,         -- From flare
        slowedUntil = 0,
        weakenedUntil = 0,
        flaredUntil = 0
    }
    
    -- Shot history for analytics
    self.shotHistory = {}
    
    -- Spawn timer tracking
    self.timers = {
        spawned = os.time(),
        nextSpawn = os.time() + 1200  -- 20 minutes
    }
end

-- Combat methods
function poopDeck.domain.Seamonster:receiveShot(shotType, weapon)
    if not self.state.alive then
        return false, "Monster already dead"
    end
    
    self.combat.shotsReceived = self.combat.shotsReceived + 1
    
    -- Record shot in history
    table.insert(self.shotHistory, {
        type = shotType,
        weapon = weapon,
        time = os.time(),
        shotNumber = self.combat.shotsReceived
    })
    
    -- Apply shot effects
    self:applyShortEffects(shotType)
    
    -- Check if killed
    if self.combat.shotsReceived >= self.combat.shotsRequired then
        self:kill()
        return true, "Monster killed!"
    end
    
    local remaining = self.combat.shotsRequired - self.combat.shotsReceived
    self:emit("shotReceived", shotType, self.combat.shotsReceived, remaining)
    
    return true, string.format("%d shots taken, %d remaining", 
        self.combat.shotsReceived, remaining)
end

function poopDeck.domain.Seamonster:applyShortEffects(shotType)
    local currentTime = os.time()
    
    if shotType == "spidershot" then
        self.debuffs.slowed = true
        self.debuffs.slowedUntil = currentTime + 30
        self:emit("debuffApplied", "slowed")
    elseif shotType == "starshot" then
        self.debuffs.weakened = true
        self.debuffs.weakenedUntil = currentTime + 30
        self:emit("debuffApplied", "weakened")
    elseif shotType == "flare" then
        self.debuffs.flared = true
        self.debuffs.flaredUntil = currentTime + 60
        self.state.flared = true
        self:emit("debuffApplied", "flared")
    end
    
    -- Update debuff states
    self:updateDebuffs()
end

function poopDeck.domain.Seamonster:updateDebuffs()
    local currentTime = os.time()
    
    if self.debuffs.slowed and currentTime > self.debuffs.slowedUntil then
        self.debuffs.slowed = false
        self:emit("debuffExpired", "slowed")
    end
    
    if self.debuffs.weakened and currentTime > self.debuffs.weakenedUntil then
        self.debuffs.weakened = false
        self:emit("debuffExpired", "weakened")
    end
    
    if self.debuffs.flared and currentTime > self.debuffs.flaredUntil then
        self.debuffs.flared = false
        self.state.flared = false
        self:emit("debuffExpired", "flared")
    end
end

function poopDeck.domain.Seamonster:kill()
    self.state.alive = false
    self.state.surfaced = false
    self.combat.endTime = os.time()
    
    local duration = self.combat.endTime - self.combat.startTime
    local efficiency = (self.combat.shotsRequired / self.combat.shotsReceived) * 100
    
    self:emit("killed", {
        name = self.name,
        tier = self.data.tier,
        xp = self.data.xp,
        shots = self.combat.shotsReceived,
        duration = duration,
        efficiency = efficiency
    })
    
    return true, string.format("Monster killed in %d shots (%.1f%% efficiency)", 
        self.combat.shotsReceived, efficiency)
end

-- State management
function poopDeck.domain.Seamonster:setRange(inRange)
    local oldRange = self.state.range
    self.state.range = inRange and "in_range" or "out_of_range"
    
    if oldRange ~= self.state.range then
        self:emit("rangeChanged", self.state.range)
    end
    
    return true, self.state.range
end

function poopDeck.domain.Seamonster:surface()
    self.state.surfaced = true
    self.state.lastSeen = os.time()
    self:emit("surfaced")
    return true, "Monster surfaced"
end

function poopDeck.domain.Seamonster:submerge()
    self.state.surfaced = false
    self:emit("submerged")
    return true, "Monster submerged"
end

-- Analytics methods
function poopDeck.domain.Seamonster:getEfficiency()
    if self.combat.shotsReceived == 0 then
        return 0
    end
    return (self.combat.shotsRequired / self.combat.shotsReceived) * 100
end

function poopDeck.domain.Seamonster:getCombatDuration()
    if not self.combat.endTime then
        return os.time() - self.combat.startTime
    end
    return self.combat.endTime - self.combat.startTime
end

function poopDeck.domain.Seamonster:getWeaponBreakdown()
    local breakdown = {}
    for _, shot in ipairs(self.shotHistory) do
        breakdown[shot.weapon] = (breakdown[shot.weapon] or 0) + 1
    end
    return breakdown
end

function poopDeck.domain.Seamonster:getShotTypeBreakdown()
    local breakdown = {}
    for _, shot in ipairs(self.shotHistory) do
        breakdown[shot.type] = (breakdown[shot.type] or 0) + 1
    end
    return breakdown
end

-- Status methods
function poopDeck.domain.Seamonster:getStatus()
    self:updateDebuffs()
    
    return {
        name = self.name,
        tier = self.data.tier,
        alive = self.state.alive,
        surfaced = self.state.surfaced,
        range = self.state.range,
        shots = string.format("%d/%d", self.combat.shotsReceived, self.combat.shotsRequired),
        remaining = self.combat.shotsRequired - self.combat.shotsReceived,
        efficiency = string.format("%.1f%%", self:getEfficiency()),
        debuffs = {
            slowed = self.debuffs.slowed,
            weakened = self.debuffs.weakened,
            flared = self.debuffs.flared
        }
    }
end

function poopDeck.domain.Seamonster:getRemainingShots()
    return math.max(0, self.combat.shotsRequired - self.combat.shotsReceived)
end

function poopDeck.domain.Seamonster:getProgress()
    return (self.combat.shotsReceived / self.combat.shotsRequired) * 100
end

-- Utility methods
function poopDeck.domain.Seamonster:toString()
    return string.format("[Seamonster: %s (%s) - %d/%d shots]", 
        self.name, self.data.tier, self.combat.shotsReceived, self.combat.shotsRequired)
end

-- Class method to check if a name is a valid seamonster
function poopDeck.domain.Seamonster.isValidMonster(name)
    return poopDeck.domain.Seamonster.TYPES[name] ~= nil
end

-- Class method to get all monster names
function poopDeck.domain.Seamonster.getAllMonsterNames()
    local names = {}
    for name, _ in pairs(poopDeck.domain.Seamonster.TYPES) do
        table.insert(names, name)
    end
    return names
end