-- Monster Tracker Service
-- Tracks all seamonsters encountered during session

poopDeck.services = poopDeck.services or {}

-- MonsterTracker class definition
poopDeck.services.MonsterTracker = poopDeck.core.BaseClass:extend("MonsterTracker")

function poopDeck.services.MonsterTracker:initialize()
    -- Active monsters (could be multiple if tracking others' combat)
    self.activeMonsters = {}
    
    -- Historical data for session
    self.history = {
        monsters = {},        -- Array of all monsters encountered
        byType = {},         -- Grouped by monster type
        byTier = {},         -- Grouped by tier
        totalKills = 0,
        totalShots = 0,
        totalXP = 0,
        sessionStart = os.time()
    }
    
    -- Statistics
    self.statistics = {
        mostEfficient = nil,  -- Most efficiently killed monster
        leastEfficient = nil, -- Least efficiently killed monster
        fastestKill = nil,    -- Fastest kill time
        slowestKill = nil,    -- Slowest kill time
        favoriteWeapon = {},  -- Weapon usage stats
        averageEfficiency = 0
    }
    
    -- Spawn predictions
    self.spawns = {
        lastSpawn = nil,
        nextPredicted = nil,
        spawnInterval = 1200  -- 20 minutes default
    }
end

-- Monster lifecycle management
function poopDeck.services.MonsterTracker:spawnMonster(monsterName, isPlayerTarget)
    -- Create new monster instance
    local monster = poopDeck.domain.Seamonster(monsterName)
    
    -- Track spawn time
    monster.spawnTime = os.time()
    monster.isPlayerTarget = isPlayerTarget or false
    
    -- Add to active monsters
    self.activeMonsters[monsterName] = monster
    
    -- Set up event listeners
    self:setupMonsterEvents(monster)
    
    -- Update spawn predictions
    if self.spawns.lastSpawn then
        local interval = os.time() - self.spawns.lastSpawn
        -- Adaptive spawn interval based on observed patterns
        self.spawns.spawnInterval = math.floor((self.spawns.spawnInterval + interval) / 2)
    end
    self.spawns.lastSpawn = os.time()
    self.spawns.nextPredicted = os.time() + self.spawns.spawnInterval
    
    -- Emit event
    self:emit("monsterSpawned", {
        name = monsterName,
        tier = monster.data.tier,
        isTarget = isPlayerTarget,
        predictedNext = self.spawns.nextPredicted
    })
    
    return monster
end

function poopDeck.services.MonsterTracker:setupMonsterEvents(monster)
    -- Track when monster is killed
    monster:on("killed", function(m, data)
        self:recordKill(m, data)
    end)
    
    -- Track shots for statistics
    monster:on("shotReceived", function(m, shotType, current, remaining)
        self:updateStatistics(m, shotType)
    end)
end

function poopDeck.services.MonsterTracker:recordKill(monster, data)
    -- Add to history
    local record = {
        name = monster.name,
        tier = monster.data.tier,
        xp = monster.data.xp,
        shots = monster.combat.shotsReceived,
        efficiency = data.efficiency,
        duration = data.duration,
        spawnTime = monster.spawnTime,
        killTime = os.time(),
        weaponBreakdown = monster:getWeaponBreakdown(),
        shotBreakdown = monster:getShotTypeBreakdown()
    }
    
    -- Add to history arrays
    table.insert(self.history.monsters, record)
    
    -- Group by type
    self.history.byType[monster.name] = self.history.byType[monster.name] or {}
    table.insert(self.history.byType[monster.name], record)
    
    -- Group by tier
    self.history.byTier[monster.data.tier] = self.history.byTier[monster.data.tier] or {}
    table.insert(self.history.byTier[monster.data.tier], record)
    
    -- Update totals
    self.history.totalKills = self.history.totalKills + 1
    self.history.totalShots = self.history.totalShots + monster.combat.shotsReceived
    self.history.totalXP = self.history.totalXP + monster.data.xp
    
    -- Update statistics
    self:updateBestWorst(record)
    
    -- Remove from active monsters
    self.activeMonsters[monster.name] = nil
    
    -- Emit event with comprehensive data
    self:emit("monsterRecorded", record)
end

function poopDeck.services.MonsterTracker:updateBestWorst(record)
    -- Track most/least efficient
    if not self.statistics.mostEfficient or record.efficiency > self.statistics.mostEfficient.efficiency then
        self.statistics.mostEfficient = record
    end
    
    if not self.statistics.leastEfficient or record.efficiency < self.statistics.leastEfficient.efficiency then
        self.statistics.leastEfficient = record
    end
    
    -- Track fastest/slowest
    if not self.statistics.fastestKill or record.duration < self.statistics.fastestKill.duration then
        self.statistics.fastestKill = record
    end
    
    if not self.statistics.slowestKill or record.duration > self.statistics.slowestKill.duration then
        self.statistics.slowestKill = record
    end
    
    -- Update average efficiency
    local totalEfficiency = 0
    for _, monster in ipairs(self.history.monsters) do
        totalEfficiency = totalEfficiency + monster.efficiency
    end
    self.statistics.averageEfficiency = totalEfficiency / #self.history.monsters
end

function poopDeck.services.MonsterTracker:updateStatistics(monster, shotType)
    -- Track weapon usage across all monsters
    local weapon = monster.shotHistory[#monster.shotHistory].weapon
    self.statistics.favoriteWeapon[weapon] = (self.statistics.favoriteWeapon[weapon] or 0) + 1
end

-- Query methods
function poopDeck.services.MonsterTracker:getActiveMonsters()
    local monsters = {}
    for name, monster in pairs(self.activeMonsters) do
        table.insert(monsters, {
            name = name,
            status = monster:getStatus(),
            duration = os.time() - monster.spawnTime
        })
    end
    return monsters
end

function poopDeck.services.MonsterTracker:getMonsterHistory(monsterName)
    return self.history.byType[monsterName] or {}
end

function poopDeck.services.MonsterTracker:getTierHistory(tier)
    return self.history.byTier[tier] or {}
end

function poopDeck.services.MonsterTracker:getSessionStatistics()
    return {
        totalKills = self.history.totalKills,
        totalShots = self.history.totalShots,
        totalXP = self.history.totalXP,
        sessionTime = os.time() - self.history.sessionStart,
        averageEfficiency = self.statistics.averageEfficiency,
        mostEfficient = self.statistics.mostEfficient,
        leastEfficient = self.statistics.leastEfficient,
        fastestKill = self.statistics.fastestKill,
        slowestKill = self.statistics.slowestKill,
        nextSpawn = self.spawns.nextPredicted,
        weaponUsage = self.statistics.favoriteWeapon
    }
end

function poopDeck.services.MonsterTracker:getPredictedSpawnTime()
    return self.spawns.nextPredicted
end

function poopDeck.services.MonsterTracker:getSpawnCountdown()
    if not self.spawns.nextPredicted then
        return nil
    end
    
    local remaining = self.spawns.nextPredicted - os.time()
    if remaining < 0 then
        return "Overdue!"
    end
    
    local minutes = math.floor(remaining / 60)
    local seconds = remaining % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- Analytics methods
function poopDeck.services.MonsterTracker:getBestWeaponForMonster(monsterName)
    local history = self.history.byType[monsterName]
    if not history or #history == 0 then
        return nil
    end
    
    -- Analyze weapon efficiency for this monster type
    local weaponStats = {}
    for _, record in ipairs(history) do
        for weapon, count in pairs(record.weaponBreakdown) do
            weaponStats[weapon] = weaponStats[weapon] or {total = 0, kills = 0, avgEfficiency = 0}
            weaponStats[weapon].total = weaponStats[weapon].total + count
            weaponStats[weapon].kills = weaponStats[weapon].kills + 1
            weaponStats[weapon].avgEfficiency = 
                weaponStats[weapon].avgEfficiency + record.efficiency
        end
    end
    
    -- Find best weapon by efficiency
    local bestWeapon = nil
    local bestEfficiency = 0
    for weapon, stats in pairs(weaponStats) do
        local avgEff = stats.avgEfficiency / stats.kills
        if avgEff > bestEfficiency then
            bestEfficiency = avgEff
            bestWeapon = weapon
        end
    end
    
    return bestWeapon, bestEfficiency
end

function poopDeck.services.MonsterTracker:generateReport()
    local stats = self:getSessionStatistics()
    local report = {}
    
    table.insert(report, "=== SEAMONSTER SESSION REPORT ===")
    table.insert(report, string.format("Session Time: %d minutes", math.floor(stats.sessionTime / 60)))
    table.insert(report, string.format("Total Kills: %d", stats.totalKills))
    table.insert(report, string.format("Total Shots: %d", stats.totalShots))
    table.insert(report, string.format("Total XP: %d", stats.totalXP))
    table.insert(report, string.format("Average Efficiency: %.1f%%", stats.averageEfficiency))
    
    if stats.mostEfficient then
        table.insert(report, string.format("\nBest Kill: %s (%.1f%% efficiency)", 
            stats.mostEfficient.name, stats.mostEfficient.efficiency))
    end
    
    if stats.fastestKill then
        table.insert(report, string.format("Fastest Kill: %s (%d seconds)", 
            stats.fastestKill.name, stats.fastestKill.duration))
    end
    
    table.insert(report, "\n=== WEAPON USAGE ===")
    for weapon, count in pairs(stats.weaponUsage) do
        table.insert(report, string.format("%s: %d shots", weapon, count))
    end
    
    table.insert(report, "\n=== MONSTER BREAKDOWN ===")
    for monsterName, records in pairs(self.history.byType) do
        local avgShots = 0
        for _, record in ipairs(records) do
            avgShots = avgShots + record.shots
        end
        avgShots = avgShots / #records
        
        table.insert(report, string.format("%s: %d killed (avg %.1f shots)", 
            monsterName, #records, avgShots))
    end
    
    return table.concat(report, "\n")
end

function poopDeck.services.MonsterTracker:toString()
    return string.format("[MonsterTracker: %d active, %d killed]", 
        table.size(self.activeMonsters), self.history.totalKills)
end