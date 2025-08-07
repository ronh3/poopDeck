-- Session Manager
-- Central coordinator for all poopDeck systems

poopDeck.core = poopDeck.core or {}

-- SessionManager class definition
poopDeck.core.SessionManager = poopDeck.core.BaseClass:extend("SessionManager")

-- Singleton instance
poopDeck.core.SessionManager.instance = nil

function poopDeck.core.SessionManager:initialize()
    -- Domain objects
    self.ship = nil
    self.combat = nil
    self.navigation = nil
    self.fishing = nil
    self.ui = nil
    
    -- Configuration
    local mudletHome = getMudletHomeDir()
    if not mudletHome or mudletHome == "" then
        mudletHome = "."  -- fallback to current directory
    end
    self.config = {
        loaded = false,
        configPath = mudletHome .. "/poopDeckconfig.lua"
    }
    
    -- Session state
    self.session = {
        startTime = os.time(),
        initialized = false
    }
    
    -- Initialize all systems
    self:initializeSystems()
end

function poopDeck.core.SessionManager:initializeSystems()
    -- Create error handling service first (other services depend on it)
    self.errorHandler = poopDeck.services.ErrorHandlingService({
        enabled = true,
        logLevel = "warn",
        displayErrors = true,
        suppressDuplicates = true,
        crashRecovery = true
    })
    
    -- Create domain objects
    self.ship = poopDeck.domain.Ship({
        name = "Player's Vessel",
        type = "strider"
    })
    
    -- Create service layers
    self.combat = poopDeck.services.CombatService(self.ship, {
        autoFire = false,
        healthThreshold = 75,
        maintainDuringCombat = "hull"
    })
    
    -- Create monster tracking service
    self.monsterTracker = poopDeck.services.MonsterTracker()
    
    -- Create notification service
    self.notifications = poopDeck.services.NotificationService({
        enabled = true,
        soundEnabled = false,
        spawnWarnings = {
            fiveMinute = true,
            oneMinute = true,
            timeToFish = true
        }
    })
    
    -- Create prompt service for spam reduction
    self.prompt = poopDeck.services.PromptService({
        enabled = true,
        throttleTime = 10,    -- 10 seconds between same message
        maxRepeats = 2,       -- max 2 repeats before suppressing
        quietMode = false
    })
    
    -- Create status window service
    self.statusWindows = poopDeck.services.StatusWindowService({
        enabled = false,      -- Disabled by default, user can enable
        windowWidth = 280,
        windowHeight = 140,
        fontSize = 11
    })
    
    -- Create fishing service
    self.fishing = poopDeck.services.FishingService({
        enabled = true,
        autoRestart = true,
        defaultBait = "bass",
        defaultHook = "medium",
        baitSource = "tank",
        maxRetries = 3,
        debugMode = false
    })
    
    -- Create command service
    self.commands = poopDeck.services.CommandService({
        trackStatistics = true,
        validateInputs = true,
        requirePermissions = false,
        logExecutions = false
    })
    
    -- Register all commands
    self:registerCommands()
    
    -- Load saved configuration
    self:loadConfig()
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    self.session.initialized = true
    self:emit("initialized")
end

-- Register all commands with the unified command service
function poopDeck.core.SessionManager:registerCommands()
    -- Anchor command
    self.commands:registerCommand({
        name = "anchor",
        category = "Sailing",
        description = "Raise or lower the ship's anchor",
        usage = "anchor <r|l> (r=raise, l=lower)",
        aliases = {"anc"},
        handler = function(orientation)
            return self:shipCommand("anchor", orientation)
        end,
        validate = function(args)
            if not args[1] or (args[1] ~= "r" and args[1] ~= "l") then
                return false, "Must specify 'r' to raise or 'l' to lower anchor"
            end
            return true
        end,
        context = "sailing_anchor"
    })
    
    -- All Stop command  
    self.commands:registerCommand({
        name = "allstop",
        category = "Sailing",
        description = "Stop the ship immediately",
        usage = "allstop",
        aliases = {"sstop"},
        handler = function()
            return self:shipCommand("allStop")
        end,
        context = "sailing_allstop"
    })
    
    -- Cast Off command
    self.commands:registerCommand({
        name = "castoff",
        category = "Sailing", 
        description = "Cast off from the dock",
        usage = "castoff",
        aliases = {"scast"},
        handler = function()
            return self:shipCommand("castOff")
        end,
        context = "sailing_castoff"
    })
    
    -- Dock command
    self.commands:registerCommand({
        name = "dock",
        category = "Sailing",
        description = "Dock the ship in a specific direction",
        usage = "dock <direction>",
        aliases = {},
        handler = function(direction)
            return self:shipCommand("dock", direction)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify dock direction"
            end
            return true
        end,
        context = "sailing_dock"
    })
    
    -- Plank command
    self.commands:registerCommand({
        name = "plank",
        category = "Sailing",
        description = "Raise or lower the ship's plank",
        usage = "plank <r|l> (r=raise, l=lower)",
        aliases = {"pla"},
        handler = function(orientation)
            return self:shipCommand("plank", orientation)
        end,
        validate = function(args)
            if not args[1] or (args[1] ~= "r" and args[1] ~= "l") then
                return false, "Must specify 'r' to raise or 'l' to lower plank"
            end
            return true
        end,
        context = "sailing_plank"
    })
    
    -- Turn Ship command
    self.commands:registerCommand({
        name = "turn",
        category = "Sailing",
        description = "Turn the ship to a new heading",
        usage = "turn <direction>",
        aliases = {"stt"},
        handler = function(heading)
            return self:shipCommand("turn", heading)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify heading direction"
            end
            return true
        end,
        context = "sailing_turn"
    })
    
    -- Set Speed command
    self.commands:registerCommand({
        name = "setspeed",
        category = "Sailing", 
        description = "Set ship sail speed",
        usage = "setspeed <speed> (0-100 or 'strike'/'full')",
        aliases = {"sss"},
        handler = function(speed)
            return self:shipCommand("setSailSpeed", speed)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify speed"
            end
            local speedNum = tonumber(args[1])
            if not speedNum and args[1] ~= "strike" and args[1] ~= "full" then
                return false, "Speed must be 0-100, 'strike', or 'full'"
            end
            if speedNum and (speedNum < 0 or speedNum > 100) then
                return false, "Speed must be between 0 and 100"
            end
            return true
        end,
        context = "sailing_setspeed"
    })
    
    -- Row Oars command
    self.commands:registerCommand({
        name = "row",
        category = "Sailing",
        description = "Start rowing the oars",
        usage = "row",
        aliases = {"srow"},
        handler = function()
            return self:shipCommand("row")
        end,
        context = "sailing_row"
    })
    
    -- Relax Oars command
    self.commands:registerCommand({
        name = "relaxoars",
        category = "Sailing",
        description = "Stop rowing the oars", 
        usage = "relaxoars",
        aliases = {"sreo"},
        handler = function()
            return self:shipCommand("relaxOars")
        end,
        context = "sailing_relaxoars"
    })
    
    -- Ship Repairs command
    self.commands:registerCommand({
        name = "repair",
        category = "Sailing",
        description = "Repair ship components",
        usage = "repair <target> (all|hull|sails|none)",
        aliases = {"srep"},
        handler = function(target)
            return self:shipCommand("repair", target or "all")
        end,
        validate = function(args)
            local validTargets = {all = true, hull = true, sails = true, none = true}
            local target = args[1] or "all"
            if not validTargets[target] then
                return false, "Repair target must be: all, hull, sails, or none"
            end
            return true
        end,
        context = "sailing_repair"
    })
    
    -- Help commands
    self.commands:registerCommand({
        name = "help",
        category = "Help",
        description = "Show help for commands",
        usage = "help [command]",
        aliases = {"poophelp"},
        handler = function(commandName)
            return self:showCommandHelp(commandName)
        end,
        context = "help_command"
    })
    
    self.commands:registerCommand({
        name = "search",
        category = "Help",
        description = "Search for commands by name or description",
        usage = "search <pattern>",
        aliases = {"poopsearch", "find"},
        handler = function(pattern)
            if not pattern then
                return false, "Search pattern required"
            end
            return self:searchCommands(pattern)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify search pattern"
            end
            return true
        end,
        context = "help_search"
    })
    
    self.commands:registerCommand({
        name = "stats",
        category = "Help",
        description = "Show command usage statistics",
        usage = "stats",
        aliases = {"poopstats", "commandstats"},
        handler = function()
            return self:showCommandStatistics()
        end,
        context = "help_stats"
    })
    
    -- Fishing commands
    self.commands:registerCommand({
        name = "fish",
        category = "Fishing",
        description = "Start fishing with current bait and cast distance",
        usage = "fish [bait] [cast_distance]",
        aliases = {"startfish", "autofish"},
        handler = function(bait, castDistance)
            if not self.fishing.settings.enabled then
                return false, "Fishing service is disabled. Use 'poopfishenable' first."
            end
            
            local config = {}
            if bait then config.baitType = bait end
            if castDistance then config.castDistance = castDistance end
            
            return self.fishing:startFishing(config)
        end,
        examples = {"fish", "fish bass medium", "fish shrimp long"},
        context = "fishing_start"
    })
    
    self.commands:registerCommand({
        name = "stopfish",
        category = "Fishing",
        description = "Stop current fishing session",
        usage = "stopfish",
        aliases = {"fishstop", "quitfish"},
        handler = function()
            if not self.fishing.isActive then
                return false, "No active fishing session"
            end
            return self.fishing:stopFishing("manual")
        end,
        context = "fishing_stop"
    })
    
    self.commands:registerCommand({
        name = "fishstats",
        category = "Fishing",
        description = "Show fishing statistics",
        usage = "fishstats",
        aliases = {"poopfishstats", "fishingstats"},
        handler = function()
            self.fishing:showStats()
            return true
        end,
        context = "fishing_stats"
    })
    
    self.commands:registerCommand({
        name = "fishbait",
        category = "Fishing",
        description = "Set default fishing bait",
        usage = "fishbait <type>",
        aliases = {"setbait", "bait"},
        handler = function(baitType)
            if not baitType then
                return false, "Bait type required (any bait from your inventory)"
            end
            return self.fishing:setBait(baitType)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify bait type"
            end
            if args[1] == "" or args[1]:match("^%s*$") then
                return false, "Bait type cannot be empty"
            end
            return true
        end,
        examples = {"fishbait bass", "fishbait shrimp", "fishbait worms", "fishbait minnow"},
        context = "fishing_bait"
    })
    
    self.commands:registerCommand({
        name = "fishcast",
        category = "Fishing",
        description = "Set default fishing cast distance",
        usage = "fishcast <distance>",
        aliases = {"setcast", "castdistance"},
        handler = function(castDistance)
            if not castDistance then
                return false, "Cast distance required. Available: short, medium, long"
            end
            return self.fishing:setCastDistance(castDistance)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify cast distance"
            end
            local validDistances = {short = true, medium = true, long = true}
            if not validDistances[args[1]] then
                return false, "Invalid cast distance. Available: short, medium, long"
            end
            return true
        end,
        examples = {"fishcast medium", "fishcast long", "fishcast short"},
        context = "fishing_cast_distance"
    })
    
    self.commands:registerCommand({
        name = "fishsource",
        category = "Fishing",
        description = "Set where to get fishing bait from",
        usage = "fishsource <source>",
        aliases = {"baitsource", "setsource"},
        handler = function(baitSource)
            if not baitSource then
                return false, "Bait source required. Available: tank, inventory, fishbucket"
            end
            return self.fishing:setBaitSource(baitSource)
        end,
        validate = function(args)
            if not args[1] then
                return false, "Must specify bait source"
            end
            local validSources = {tank = true, inventory = true, fishbucket = true}
            if not validSources[args[1]] then
                return false, "Invalid bait source. Available: tank, inventory, fishbucket"
            end
            return true
        end,
        examples = {"fishsource tank", "fishsource inventory", "fishsource fishbucket"},
        detailedHelp = "tank: 'get bait from tank' and 'bait hook with bait from tank'\ninventory: 'bait hook with bait' (no get needed)\nfishbucket: 'get bait from fishbucket' and 'bait hook with bait from fishbucket'",
        context = "fishing_bait_source"
    })
    
    self.commands:registerCommand({
        name = "fishrestart",
        category = "Fishing",
        description = "Toggle auto-restart fishing when fish escape",
        usage = "fishrestart",
        aliases = {"autorestart", "fishauto"},
        handler = function()
            return self.fishing:toggleAutoRestart()
        end,
        context = "fishing_autorestart"
    })
    
    self.commands:registerCommand({
        name = "fishenable",
        category = "Fishing",
        description = "Enable the fishing service",
        usage = "fishenable",
        aliases = {"poopfishenable"},
        handler = function()
            return self.fishing:enable()
        end,
        context = "fishing_enable"
    })
    
    self.commands:registerCommand({
        name = "fishdisable",
        category = "Fishing",
        description = "Disable the fishing service",
        usage = "fishdisable", 
        aliases = {"poopfishdisable"},
        handler = function()
            return self.fishing:disable()
        end,
        context = "fishing_disable"
    })
    
    self.commands:registerCommand({
        name = "fishresetstats",
        category = "Fishing",
        description = "Reset all fishing statistics (WARNING: This cannot be undone!)",
        usage = "fishresetstats",
        aliases = {"resetfishstats"},
        handler = function()
            if not self.fishing then
                return false, "Fishing service not available"
            end
            
            -- Reset all statistics
            self.fishing.stats = {
                totalSessions = 0,
                totalCasts = 0,
                totalCatches = 0,
                totalEscapes = 0,
                longestSession = 0,
                bestCatchRate = 0,
                allTimeBestSession = nil,
                firstFishingDate = nil,
                lastFishingDate = nil
            }
            
            -- Clear session history
            self.fishing.recentSessionsSummary = {}
            self.fishing.sessionHistory = {}
            
            -- Save the reset config
            self:saveConfig()
            
            poopDeck.settingEcho("All fishing statistics have been reset!")
            return true, "Statistics reset complete"
        end,
        context = "fishing_reset_stats"
    })
end

-- Execute commands through the unified command service
function poopDeck.core.SessionManager:executeCommand(commandName, ...)
    local args = {...}
    local success, result = self.commands:executeCommand(commandName, args, "user_alias")
    return success, result
end

-- Help system integration
function poopDeck.core.SessionManager:showCommandHelp(commandName)
    if not commandName then
        return self:showAllCommandCategories()
    end
    
    local help = self.commands:getCommandHelp(commandName)
    if not help then
        poopDeck.badEcho("Command not found: " .. commandName)
        return false
    end
    
    echo("\n<yellow>===== " .. help.name .. " Command Help =====</yellow>\n")
    echo("<cyan>Category:</cyan> " .. help.category .. "\n")
    echo("<cyan>Description:</cyan> " .. help.description .. "\n")
    echo("<cyan>Usage:</cyan> " .. help.usage .. "\n")
    
    if #help.aliases > 0 then
        echo("<cyan>Aliases:</cyan> " .. table.concat(help.aliases, ", ") .. "\n")
    end
    
    if #help.examples > 0 then
        echo("<cyan>Examples:</cyan>\n")
        for _, example in ipairs(help.examples) do
            echo("  " .. example .. "\n")
        end
    end
    
    if help.detailedHelp then
        echo("<cyan>Details:</cyan>\n" .. help.detailedHelp .. "\n")
    end
    echo("<yellow>==========================================</yellow>\n")
    return true
end

function poopDeck.core.SessionManager:showAllCommandCategories()
    local categories = self.commands:getAllCategories()
    
    echo("\n<yellow>===== poopDeck Command Categories =====</yellow>\n")
    
    for _, category in ipairs(categories) do
        local commands = self.commands:getCommandsByCategory(category)
        
        echo("<cyan>" .. category .. ":</cyan>\n")
        for _, cmd in ipairs(commands) do
            local aliasText = #cmd.aliases > 0 and " (" .. table.concat(cmd.aliases, ", ") .. ")" or ""
            echo(string.format("  %-15s%s - %s\n", cmd.name .. aliasText, "", cmd.description))
        end
        echo("\n")
    end
    
    echo("<yellow>Use 'poophelp <command>' for detailed help on specific commands</yellow>\n")
    echo("<yellow>==========================================</yellow>\n")
    return true
end

function poopDeck.core.SessionManager:searchCommands(pattern)
    local matches = self.commands:findCommands(pattern)
    
    if #matches == 0 then
        poopDeck.badEcho("No commands found matching: " .. pattern)
        return false
    end
    
    echo("\n<yellow>===== Commands matching '" .. pattern .. "' =====</yellow>\n")
    
    for _, match in ipairs(matches) do
        local matchType = match.type == "alias" and " (alias)" or 
                         match.type == "description_match" and " (desc)" or ""
        echo(string.format("<%s>%s%s</cyan> - %s\n", 
            match.type == "command" and "cyan" or "white",
            match.name, 
            matchType, 
            match.description))
    end
    
    echo("<yellow>==========================================</yellow>\n")
    return true
end

function poopDeck.core.SessionManager:showCommandStatistics()
    local stats = self.commands:getStatistics()
    
    echo("\n<yellow>===== Command Statistics =====</yellow>\n")
    echo(string.format("Total Commands: %d\n", stats.totalCommands))
    echo(string.format("Total Aliases: %d\n", stats.totalAliases))
    echo(string.format("Categories: %d\n", stats.totalCategories))
    echo(string.format("Total Executions: %d\n", stats.totalExecutions))
    echo(string.format("Successful: %d (%.1f%%)\n", stats.successfulExecutions, stats.successRate))
    echo(string.format("Failed: %d\n", stats.failedExecutions))
    
    if #stats.mostUsedCommands > 0 then
        echo("\n<cyan>Most Used Commands:</cyan>\n")
        for i, cmd in ipairs(stats.mostUsedCommands) do
            echo(string.format("%d. %s (%d uses)\n", i, cmd.name, cmd.usage))
        end
    end
    
    echo("<yellow>===============================</yellow>\n")
    return true
end

function poopDeck.core.SessionManager:setupEventHandlers()
    -- Combat events
    self.combat:on("monsterKilled", function(service, data)
        self:handleMonsterKilled(data)
    end)
    
    self.combat:on("outOfRange", function()
        self:handleOutOfRange()
    end)
    
    self.combat:on("healingNeeded", function()
        self:handleHealingNeeded()
    end)
    
    -- Ship events
    self.ship:on("damageReceived", function(ship, component, amount, level)
        self:handleShipDamage(component, amount, level)
    end)
    
    -- Monster tracker events
    self.monsterTracker:on("monsterSpawned", function(tracker, data)
        self:handleMonsterSpawned(data)
    end)
    
    self.monsterTracker:on("monsterRecorded", function(tracker, record)
        self:handleMonsterRecorded(record)
    end)
    
    -- Notification events
    self.notifications:on("fiveMinuteWarning", function()
        self:handleFiveMinuteWarning()
    end)
    
    self.notifications:on("oneMinuteWarning", function()
        self:handleOneMinuteWarning()
    end)
    
    self.notifications:on("timeToFishWarning", function()
        self:handleTimeToFishWarning()
    end)
end

-- Configuration management
function poopDeck.core.SessionManager:loadConfig()
    if poopDeck.safe.fileExists(self.config.configPath, "load_config") then
        local success, config = poopDeck.safe.loadTable(self.config.configPath, "load_config")
        if success and config then
            -- Apply combat settings
            if config.sipHealthPercent then
                self.combat:setHealthThreshold(config.sipHealthPercent)
            end
            if config.preferredWeapon then
                self.combat:selectWeapon(config.preferredWeapon)
            end
            if config.maintainDuringCombat then
                self.combat:setMaintenance(config.maintainDuringCombat)
            end
            
            -- Apply fishing settings
            if config.fishing then
                if config.fishing.enabled ~= nil then
                    if config.fishing.enabled then
                        self.fishing:enable()
                    else
                        self.fishing:disable()
                    end
                end
                
                if config.fishing.autoRestart ~= nil then
                    self.fishing.settings.autoRestart = config.fishing.autoRestart
                end
                
                if config.fishing.defaultBait then
                    self.fishing:setBait(config.fishing.defaultBait)
                end
                
                if config.fishing.defaultHook then
                    self.fishing:setHook(config.fishing.defaultHook)
                end
                
                if config.fishing.baitSource then
                    self.fishing:setBaitSource(config.fishing.baitSource)
                end
                
                -- Load persistent statistics
                if config.fishing.stats then
                    self.fishing.stats = {
                        totalSessions = config.fishing.stats.totalSessions or 0,
                        totalCasts = config.fishing.stats.totalCasts or 0,
                        totalCatches = config.fishing.stats.totalCatches or 0,
                        totalEscapes = config.fishing.stats.totalEscapes or 0,
                        longestSession = config.fishing.stats.longestSession or 0,
                        bestCatchRate = config.fishing.stats.bestCatchRate or 0,
                        allTimeBestSession = config.fishing.stats.allTimeBestSession or nil,
                        firstFishingDate = config.fishing.stats.firstFishingDate or os.time(),
                        lastFishingDate = config.fishing.stats.lastFishingDate or nil
                    }
                end
                
                -- Load session history summary (keep only recent sessions to avoid huge saves)
                if config.fishing.recentSessions then
                    self.fishing.recentSessionsSummary = config.fishing.recentSessions
                end
            end
            
            self.config.loaded = true
            self:emit("configLoaded", config)
        end
    end
end

function poopDeck.core.SessionManager:saveConfig()
    local config = {
        sipHealthPercent = self.combat.settings.healthThreshold,
        preferredWeapon = self.combat.settings.preferredWeapon,
        maintainDuringCombat = self.combat.settings.maintainDuringCombat,
        
        -- Fishing configuration and statistics
        fishing = {
            enabled = self.fishing.settings.enabled,
            autoRestart = self.fishing.settings.autoRestart,
            defaultBait = self.fishing.settings.defaultBait,
            defaultHook = self.fishing.settings.defaultHook,
            baitSource = self.fishing.settings.baitSource,
            maxRetries = self.fishing.settings.maxRetries,
            retryDelay = self.fishing.settings.retryDelay,
            
            -- Persistent statistics
            stats = {
                totalSessions = self.fishing.stats.totalSessions,
                totalCasts = self.fishing.stats.totalCasts,
                totalCatches = self.fishing.stats.totalCatches,
                totalEscapes = self.fishing.stats.totalEscapes,
                longestSession = self.fishing.stats.longestSession,
                bestCatchRate = self.fishing.stats.bestCatchRate,
                allTimeBestSession = self.fishing.stats.allTimeBestSession,
                firstFishingDate = self.fishing.stats.firstFishingDate,
                lastFishingDate = self.fishing.stats.lastFishingDate
            },
            
            -- Recent sessions summary (last 10 sessions)
            recentSessions = self.fishing.recentSessionsSummary or {}
        }
    }
    
    local success = poopDeck.safe.saveTable(self.config.configPath, config, "save_config")
    if success then
        self:emit("configSaved", config)
    else
        if self.errorHandler then
            self.errorHandler:logError("Failed to save configuration", {path = self.config.configPath})
        end
    end
end

-- Event handlers
function poopDeck.core.SessionManager:handleMonsterKilled(data)
    -- Display victory message
    poopDeck.goodEcho(string.format("%s defeated! (%d shots, %.1f%% efficiency)", 
        data.name, data.shots, data.efficiency))
    
    -- Turn curing back on
    send("curing on")
    
    -- Save config with updated stats
    self:saveConfig()
end

function poopDeck.core.SessionManager:handleOutOfRange()
    poopDeck.badEcho("Target out of range!")
end

function poopDeck.core.SessionManager:handleHealingNeeded()
    send("curing on")
    poopDeck.badEcho("NEED TO HEAL - Hold FIRE!")
end

function poopDeck.core.SessionManager:handleShipDamage(component, amount, level)
    if level == "critical" or level == "destroyed" then
        poopDeck.badEcho(string.format("%s critically damaged!", component:upper()))
    end
end

function poopDeck.core.SessionManager:handleMonsterSpawned(data)
    -- Start spawn timers for the next monster
    self.notifications:startSpawnTimers(os.time())
end

function poopDeck.core.SessionManager:handleMonsterRecorded(record)
    -- Monster was killed - start timers for next spawn
    self.notifications:startSpawnTimers(os.time())
    
    -- Display additional kill stats
    poopDeck.smallGoodEcho(string.format("Combat duration: %d seconds, Efficiency: %.1f%%", 
        record.duration, record.efficiency))
end

function poopDeck.core.SessionManager:handleFiveMinuteWarning()
    -- Additional 5-minute warning logic if needed
    -- The NotificationService already displays the message
end

function poopDeck.core.SessionManager:handleOneMinuteWarning()
    -- Additional 1-minute warning logic if needed
    -- Could prepare weapons, check health, etc.
end

function poopDeck.core.SessionManager:handleTimeToFishWarning()
    -- Time to stop fishing - could auto-reel lines if desired
    -- The NotificationService already displays the message
end

-- Public API methods (for triggers/aliases)
function poopDeck.core.SessionManager:monsterSurfaced(monsterName)
    -- Create monster instance via tracker (gets full analytics)
    local monster = self.monsterTracker:spawnMonster(monsterName, true)
    
    -- Engage the monster in combat
    self.combat.currentMonster = monster
    self.combat:engageMonster(monsterName)
    
    -- Display alert with enhanced info
    local messages = poopDeck.spottedSeamonsterMessages or {
        "🐉🌊 Rising Behemoth! 🌊🐉",
        "🔍🌊 Titan of the Deep Spotted! 🌊🔍"
    }
    local message = messages[math.random(#messages)]
    poopDeck.badEcho(message)
    
    -- Show additional monster info
    local history = self.monsterTracker:getMonsterHistory(monsterName)
    if #history > 0 then
        local avgShots = 0
        for _, record in ipairs(history) do
            avgShots = avgShots + record.shots
        end
        avgShots = math.floor(avgShots / #history)
        
        poopDeck.smallGoodEcho(string.format("Previous encounters: %d (avg %d shots)", 
            #history, avgShots))
    end
    
    -- Show spawn prediction
    local countdown = self.monsterTracker:getSpawnCountdown()
    if countdown then
        poopDeck.smallGoodEcho(string.format("Next spawn predicted: %s", countdown))
    end
end

function poopDeck.core.SessionManager:monsterKilled()
    if self.combat.currentMonster then
        self.combat.currentMonster:kill()
    end
end

function poopDeck.core.SessionManager:monsterShot(matches)
    if self.combat.currentMonster then
        local monsterName = matches[2]
        local remaining = self.combat.currentMonster:getRemainingShots()
        poopDeck.shotEcho(string.format("%d shots taken, %d remain.", 
            self.combat.currentMonster.combat.shotsReceived, remaining))
    end
end

function poopDeck.core.SessionManager:setOutOfRange(outOfRange)
    if self.combat.currentMonster then
        self.combat.currentMonster:setRange(not outOfRange)
    end
end

function poopDeck.core.SessionManager:toggleAutoFire()
    local success, msg = self.combat:toggleAutoFire()
    local status = self.combat.settings.autoFire and "ENABLED" or "DISABLED"
    poopDeck.settingEcho(string.format("Automatic firing %s", status))
    
    -- Save config
    self:saveConfig()
end

function poopDeck.core.SessionManager:selectWeapon(weaponType)
    local success, msg = self.combat:selectWeapon(weaponType)
    if success then
        poopDeck.settingEcho(msg)
        self:saveConfig()
    else
        poopDeck.badEcho(msg)
    end
end

function poopDeck.core.SessionManager:setHealthThreshold(percent)
    local success, msg = self.combat:setHealthThreshold(percent)
    poopDeck.settingEcho(msg)
    self:saveConfig()
end

function poopDeck.core.SessionManager:setMaintenance(target)
    local success, msg = self.combat:setMaintenance(target)
    poopDeck.settingEcho(msg)
    self:saveConfig()
end

-- Ship command wrappers with enhanced error handling
function poopDeck.core.SessionManager:shipCommand(command, ...)
    local args = {...}
    
    -- Validate ship instance
    if not self.ship then
        local msg = "Ship not initialized"
        self.errorHandler:logError(msg, {command = command, args = args})
        return false, msg
    end
    
    -- Map commands to ship methods with safe execution
    local commandMap = {
        dock = function() 
            if not args[1] then
                return false, "Dock direction required"
            end
            return poopDeck.safe.call(function() 
                local success, msg = self.ship:dock(args[1])
                if success then
                    poopDeck.safe.send("ship dock " .. args[1] .. " confirm", "ship_dock")
                end
                return success, msg
            end, "ship_dock", args[1])
        end,
        
        castOff = function() 
            return poopDeck.safe.call(function()
                local success, msg = self.ship:castOff()
                if success then
                    poopDeck.safe.send("say castoff!", "ship_castoff")
                end
                return success, msg
            end, "ship_castoff")
        end,
        
        anchor = function() 
            local isRaise = args[1] == "r"
            local isDrop = args[1] == "l"
            if not isRaise and not isDrop then
                return false, "Anchor requires 'r' (raise) or 'l' (lower/drop)"
            end
            
            return poopDeck.safe.call(function()
                local success, msg = self.ship:setAnchor(isDrop)
                if success then
                    local action = isDrop and "say drop the anchor!" or "say weigh anchor!"
                    poopDeck.safe.send(action, "ship_anchor")
                end
                return success, msg
            end, "ship_anchor", args[1])
        end,
        
        plank = function() 
            local isLower = args[1] == "l"
            local isRaise = args[1] == "r"
            if not isLower and not isRaise then
                return false, "Plank requires 'r' (raise) or 'l' (lower)"
            end
            
            return poopDeck.safe.call(function()
                local success, msg = self.ship:setPlank(isLower)
                if success then
                    local action = isLower and "say lower the plank!" or "say raise the plank!"
                    poopDeck.safe.send(action, "ship_plank")
                end
                return success, msg
            end, "ship_plank", args[1])
        end,
        
        turn = function() 
            if not args[1] then
                return false, "Turn direction required"
            end
            
            return poopDeck.safe.call(function()
                local success, msg = self.ship:turn(args[1])
                if success then
                    local direction = poopDeck.directions and poopDeck.directions[args[1]] or args[1]
                    poopDeck.safe.send("say Bring her to the " .. direction .. "!", "ship_turn")
                end
                return success, msg
            end, "ship_turn", args[1])
        end,
        
        setSailSpeed = function() 
            local speed = args[1]
            if not speed then
                return false, "Speed required"
            end
            
            return poopDeck.safe.call(function()
                if speed == "0" or tonumber(speed) == 0 then
                    poopDeck.safe.send("say strike sails!", "ship_speed")
                    return self.ship:setSailSpeed(0)
                elseif speed == "100" or tonumber(speed) == 100 or speed == "full" then
                    poopDeck.safe.send("say full sails!", "ship_speed")
                    return self.ship:setSailSpeed(100)
                elseif speed == "strike" then
                    poopDeck.safe.send("say strike sails!", "ship_speed")
                    return self.ship:setSailSpeed(0)
                else
                    local speedNum = tonumber(speed)
                    if speedNum then
                        poopDeck.safe.send("ship sails set " .. speedNum, "ship_speed")
                        return self.ship:setSailSpeed(speedNum)
                    else
                        return false, "Invalid speed: " .. tostring(speed)
                    end
                end
            end, "ship_set_speed", speed)
        end,
        
        row = function() 
            return poopDeck.safe.call(function()
                local success, msg = self.ship:setRowing(true)
                if success then
                    poopDeck.safe.send("say row!", "ship_row")
                end
                return success, msg
            end, "ship_row")
        end,
        
        relaxOars = function() 
            return poopDeck.safe.call(function()
                local success, msg = self.ship:setRowing(false)
                if success then
                    poopDeck.safe.send("say stop rowing.", "ship_relax_oars")
                end
                return success, msg
            end, "ship_relax_oars")
        end,
        
        allStop = function() 
            return poopDeck.safe.call(function()
                local success, msg = self.ship:allStop()
                if success then
                    poopDeck.safe.send("say All stop!", "ship_all_stop")
                end
                return success, msg
            end, "ship_all_stop")
        end,
        
        repair = function() 
            local target = args[1] or "all"
            local validTargets = {all = true, hull = true, sails = true, none = true}
            if not validTargets[target] then
                return false, "Invalid repair target: " .. tostring(target)
            end
            
            return poopDeck.safe.call(function()
                local success, msg = self.ship:repair(target, 100)
                if success then
                    poopDeck.safe.send("ship repair " .. target, "ship_repair")
                end
                return success, msg
            end, "ship_repair", target)
        end
    }
    
    local handler = commandMap[command]
    if handler then
        local success, result, errorInfo = poopDeck.safe.call(
            handler,
            "ship_command_" .. command,
            table.unpack(args)
        )
        
        if success and result ~= false then
            return result, result == true and "Command completed" or result
        elseif success then
            -- Handler returned false - this is a handled failure
            return false, result or ("Command failed: " .. command)
        else
            -- Execution error
            local msg = "Ship command failed: " .. command
            self.errorHandler:logError(msg, {
                command = command,
                args = args,
                error = errorInfo
            })
            return false, msg
        end
    end
    
    return false, "Unknown ship command: " .. tostring(command)
end

-- Singleton getter
function poopDeck.core.SessionManager.getInstance()
    if not poopDeck.core.SessionManager.instance then
        poopDeck.core.SessionManager.instance = poopDeck.core.SessionManager()
    end
    return poopDeck.core.SessionManager.instance
end

-- Initialize the session manager on load
poopDeck.session = poopDeck.core.SessionManager.getInstance()

--#########################################
-- Legacy Wrapper Functions for Triggers/Aliases
-- These maintain backward compatibility
--#########################################

-- Seamonster triggers
function poopDeck.monsterSurfaced()
    local matches = multimatches[2]
    if matches and matches[2] then
        local monsterName = matches[2]
        poopDeck.session:monsterSurfaced(monsterName)
    end
end

function poopDeck.deadSeamonster()
    poopDeck.session:monsterKilled()
end

function poopDeck.countShots(target)
    poopDeck.session:monsterShot({nil, target})
end

function poopDeck.monsterSpidershot()
    poopDeck.smallGoodEcho("Seamonster Attack Slowed!")
end

function poopDeck.monsterStarshot()
    poopDeck.smallGoodEcho("Seamonster Attack Weakened!")
end

-- Combat functions
function poopDeck.autoFire()
    if poopDeck.session.combat.settings.autoFire then
        poopDeck.session.combat:fire()
    end
end

function poopDeck.toggleCuring(curing)
    if curing == "on" then
        send("curing on")
        return false
    else
        local needsHealing = poopDeck.session.combat:needsHealing()
        if needsHealing then
            send("curing on")
            return false
        else
            send("curing off")
            return true
        end
    end
end

-- Settings functions
function poopDeck.setHealth(hpperc)
    poopDeck.session:setHealthThreshold(hpperc)
end

-- Weapon firing
function poopDeck.fireBallista()
    poopDeck.session:selectWeapon("ballista")
    poopDeck.session.combat:fire()
end

function poopDeck.fireOnager(ammoType)
    poopDeck.session:selectWeapon("onager")
    if ammoType then
        poopDeck.session.combat.activeWeapon:setAmmo(ammoType)
    end
    poopDeck.session.combat:fire()
end

function poopDeck.fireThrower()
    poopDeck.session:selectWeapon("thrower")
    poopDeck.session.combat:fire()
end

-- Out of range handling
function poopDeck.setOutOfRange(oor)
    poopDeck.oor = oor
    poopDeck.session:setOutOfRange(oor)
end

-- Notification management functions
function poopDeck.core.SessionManager:toggleNotifications()
    if self.notifications.settings.enabled then
        self.notifications:disable()
        poopDeck.settingEcho("Spawn notifications disabled")
    else
        self.notifications:enable()
        poopDeck.settingEcho("Spawn notifications enabled")
    end
    self:saveConfig()
end

function poopDeck.core.SessionManager:toggleSpawnWarning(warningType)
    local success, msg = self.notifications:toggleWarning(warningType)
    if success then
        poopDeck.settingEcho(msg)
        self:saveConfig()
    else
        poopDeck.badEcho(msg)
    end
end

function poopDeck.core.SessionManager:getSpawnCountdown()
    local lastSpawn = self.monsterTracker.spawns.lastSpawn
    if not lastSpawn then
        poopDeck.settingEcho("No spawn recorded yet")
        return
    end
    
    local remaining, formatted = self.notifications:getTimeToNextSpawn(lastSpawn)
    if remaining then
        if remaining <= 0 then
            poopDeck.badEcho("Monster spawn overdue!")
        else
            poopDeck.settingEcho(string.format("Next monster in: %s", formatted))
        end
    else
        poopDeck.settingEcho(formatted)
    end
end

function poopDeck.core.SessionManager:showNotificationStatus()
    local status = self.notifications:getStatus()
    
    echo("\n===== Notification Settings =====\n")
    echo(string.format("Notifications: %s\n", status.enabled and "ENABLED" or "DISABLED"))
    echo(string.format("Sound alerts: %s\n", status.soundEnabled and "ENABLED" or "DISABLED"))
    echo("\nSpawn Warnings:\n")
    echo(string.format("  5-minute warning: %s\n", status.warnings.fiveMinute and "ON" or "OFF"))
    echo(string.format("  1-minute warning: %s\n", status.warnings.oneMinute and "ON" or "OFF"))
    echo(string.format("  Time to fish: %s\n", status.warnings.timeToFish and "ON" or "OFF"))
    
    local activeTimers = status.activeTimers
    echo("\nActive Timers:\n")
    if next(activeTimers) then
        for timerName, _ in pairs(activeTimers) do
            echo(string.format("  %s: ACTIVE\n", timerName))
        end
    else
        echo("  None\n")
    end
    echo("================================\n")
end

-- Config functions
function poopDeck.saveTable()
    poopDeck.session:saveConfig()
end

function poopDeck.loadTable()
    poopDeck.session:loadConfig()
end

-- Prompt management functions  
function poopDeck.core.SessionManager:toggleQuietMode()
    local success, msg = self.prompt:toggleQuietMode()
    poopDeck.settingEcho(msg)
    self:saveConfig()
end

function poopDeck.core.SessionManager:setPromptThrottle(seconds)
    local success, msg = self.prompt:setThrottleTime(seconds)
    poopDeck.settingEcho(msg)
    self:saveConfig()
end

function poopDeck.core.SessionManager:showPromptSettings()
    self.prompt:showSettings()
end

function poopDeck.core.SessionManager:resetPromptThrottling()
    local success, msg = self.prompt:resetThrottling()
    poopDeck.settingEcho(msg)
end

-- Legacy wrapper functions for notifications
function poopDeck.toggleNotifications()
    poopDeck.session:toggleNotifications()
end

function poopDeck.spawnCountdown()
    poopDeck.session:getSpawnCountdown()
end

function poopDeck.notificationStatus()
    poopDeck.session:showNotificationStatus()
end

-- Status window management functions
function poopDeck.core.SessionManager:showStatusWindow(windowName)
    local success, msg = self.statusWindows:showWindow(windowName)
    if success then
        poopDeck.settingEcho(msg)
    else
        poopDeck.badEcho(msg)
    end
end

function poopDeck.core.SessionManager:hideStatusWindow(windowName)
    local success, msg = self.statusWindows:hideWindow(windowName)
    if success then
        poopDeck.settingEcho(msg)
    else
        poopDeck.badEcho(msg)
    end
end

function poopDeck.core.SessionManager:toggleStatusWindows()
    if self.statusWindows.settings.enabled then
        self.statusWindows:disable()
        poopDeck.settingEcho("Status windows disabled")
    else
        self.statusWindows:enable()
        poopDeck.settingEcho("Status windows enabled")
    end
    self:saveConfig()
end

-- Legacy wrapper functions for prompts
function poopDeck.parsePrompt()
    if poopDeck.session and poopDeck.session.prompt then
        poopDeck.session.prompt:parsePrompt()
    end
end

function poopDeck.toggleQuiet()
    poopDeck.session:toggleQuietMode()
end

function poopDeck.promptSettings()
    poopDeck.session:showPromptSettings()
end

function poopDeck.resetPrompts()
    poopDeck.session:resetPromptThrottling()
end

-- Legacy wrapper functions for status windows
function poopDeck.showCombatWindow()
    poopDeck.session:showStatusWindow("combat")
end

function poopDeck.showShipWindow()
    poopDeck.session:showStatusWindow("ship")
end

function poopDeck.showFishingWindow()
    poopDeck.session:showStatusWindow("fishing")
end

function poopDeck.showNotificationWindow()
    poopDeck.session:showStatusWindow("notifications")
end

function poopDeck.toggleStatusWindows()
    poopDeck.session:toggleStatusWindows()
end

function poopDeck.showAllWindows()
    local success, msg = poopDeck.session.statusWindows:showAllWindows()
    poopDeck.settingEcho(msg)
end

function poopDeck.hideAllWindows()
    local success, msg = poopDeck.session.statusWindows:hideAllWindows()
    poopDeck.settingEcho(msg)
end

-- Legacy wrapper functions for help system
function poopDeck.help(commandName)
    poopDeck.session:showCommandHelp(commandName)
end

function poopDeck.commandHelp(commandName)
    poopDeck.session:showCommandHelp(commandName)
end

function poopDeck.searchCommands(pattern)
    poopDeck.session:searchCommands(pattern)
end

function poopDeck.commandStats()
    poopDeck.session:showCommandStatistics()
end

-- Legacy wrapper functions for fishing system
function poopDeck.startFishing(bait, castDistance)
    local config = {}
    if bait then config.baitType = bait end
    if castDistance then config.castDistance = castDistance end
    return poopDeck.session.fishing:startFishing(config)
end

function poopDeck.stopFishing()
    return poopDeck.session.fishing:stopFishing("manual")
end

function poopDeck.fishingStats()
    poopDeck.session.fishing:showStats()
end

function poopDeck.setBait(baitType)
    return poopDeck.session.fishing:setBait(baitType)
end

function poopDeck.setCastDistance(castDistance)
    return poopDeck.session.fishing:setCastDistance(castDistance)
end

-- Legacy function for backward compatibility
function poopDeck.setHook(hookType)
    return poopDeck.session.fishing:setCastDistance(hookType)
end

function poopDeck.setBaitSource(baitSource)
    return poopDeck.session.fishing:setBaitSource(baitSource)
end

function poopDeck.toggleAutoFish()
    return poopDeck.session.fishing:toggleAutoRestart()
end

-- Fishing trigger handlers (called by Mudlet triggers)
function poopDeck.fishNibbling()
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onLineTeased()
    end
end

function poopDeck.fishLargeStrike()
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onLargeStrike()
    end
end

function poopDeck.fishHooked(fishType)
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onFishHooked(fishType, "unknown")
    end
end

function poopDeck.fishReadyToReel()
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onReadyToReel()
    end
end

function poopDeck.fishCaught(fishData)
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onFishCaught(fishData or {})
    end
end

function poopDeck.fishEscaped(reason)
    if poopDeck.session and poopDeck.session.fishing then
        poopDeck.session.fishing:onFishEscaped(reason or "unknown")
    end
end