# 🛠️ poopDeck Troubleshooting Guide

Complete troubleshooting reference for resolving common issues with the poopDeck system.

## 🚨 Quick Diagnosis

### System Status Check
```lua
# Basic system verification
lua poopDeck                    # Should show poopDeck table
lua poopDeck.sessionManager     # Should show session manager
poopsail                        # Should show help system

# Service status
lua poopDeck.sessionManager:getStatus()  # Shows service status
```

### Common Quick Fixes
1. **Restart Mudlet** - Solves 80% of installation issues
2. **Reinstall Package** - Remove and reinstall poopDeck
3. **Check Mudlet Version** - Ensure Mudlet 4.0+
4. **Verify Profile** - Make sure you're in the correct Mudlet profile

## 📦 Installation Issues

### Package Not Loading

**Problem**: Commands don't work, help system doesn't appear
**Symptoms**: 
- `poopsail` shows "command not found"
- `lua poopDeck` returns nil

**Solutions**:
```lua
# 1. Check if package is installed
lua getPackageInfo("poopDeck")

# 2. Check Package Manager
# Go to: Packages → Package Manager
# Look for "poopDeck" in the list
# Ensure it's checked/enabled

# 3. Manual verification
lua io.exists(getMudletHomeDir().."/poopDeck")

# 4. Reinstall steps:
# - Remove package from Package Manager
# - Restart Mudlet
# - Install package again
# - Restart Mudlet again
```

### Package Installation Fails

**Problem**: Error during package installation
**Symptoms**:
- "Package installation failed" message
- Partial installation (some commands work, others don't)

**Solutions**:
1. **Check Mudlet version**: Must be 4.0+
   ```lua
   lua getMudletVersion()
   ```

2. **Check file permissions**: Ensure Mudlet can write to profile directory
   ```bash
   ls -la ~/.config/mudlet/profiles/
   ```

3. **Clear cache**: Remove old package data
   ```bash
   rm -rf ~/.config/mudlet/profiles/<profile>/poopDeck*
   ```

4. **Download fresh package**: Re-download from GitHub releases

### Commands Not Recognized

**Problem**: Some commands work but others don't
**Symptoms**:
- `fish` works but `fishbait` doesn't
- `poopsail` works but `seaweapon` doesn't

**Solutions**:
```lua
# 1. Check specific alias installation
lua poopDeck.command.fish       # Should show function
lua poopDeck.command.fishbait   # Should show function

# 2. Verify alias files loaded
# Check: Scripts → Aliases in Mudlet

# 3. Manual alias check
lua table.keys(aliases)         # Should show poopDeck aliases

# 4. Reload specific components
lua dofile(getMudletHomeDir().."/poopDeck/src/aliases/Fishing/aliases.json")
```

## 🎣 Fishing Issues

### Fishing Won't Start

**Problem**: `fish` command doesn't begin fishing
**Symptoms**:
- Command executes but nothing happens
- No casting messages appear
- No error messages

**Diagnostic Steps**:
```lua
# 1. Check fishing service
lua poopDeck.sessionManager:getFishingService()

# 2. Verify service status
lua poopDeck.sessionManager:getFishingService().enabled

# 3. Check fishing location
# Must be in a valid fishing area with proper equipment

# 4. Verify equipment
# Need: fishing pole, bait, appropriate location
```

**Solutions**:
```lua
# 1. Enable fishing service
fishenable

# 2. Check bait configuration
fishbait bass
fishsource tank

# 3. Manual fishing test
send("cast medium")    # Direct game command test

# 4. Reset fishing service
lua poopDeck.sessionManager:getFishingService():stopFishing()
fish
```

### Auto-Resume Not Working

**Problem**: Fish escape but fishing doesn't restart automatically
**Symptoms**:
- Fish escape messages appear
- No auto-restart messages
- Fishing stops permanently

**Diagnostic Steps**:
```lua
# 1. Check auto-restart setting
lua poopDeck.sessionManager:getFishingService().autoRestart

# 2. Check retry count
lua poopDeck.sessionManager:getFishingService().retryCount

# 3. Check max retries
lua poopDeck.sessionManager:getFishingService().maxRetries

# 4. Verify fish escape detection
# Look in triggers: Fishing → Fish_Escape.lua
```

**Solutions**:
```lua
# 1. Enable auto-restart
fishrestart

# 2. Reset retry counter
lua poopDeck.sessionManager:getFishingService().retryCount = 0

# 3. Check trigger patterns
# Fish escape triggers must match game messages exactly

# 4. Manual trigger test
lua poopDeck.fishEscaped("test escape reason")
```

### Fishing Statistics Not Updating

**Problem**: `fishstats` shows zero or incorrect data
**Symptoms**:
- Statistics don't increase
- Data resets unexpectedly
- Missing session information

**Solutions**:
```lua
# 1. Verify statistics tracking
lua poopDeck.sessionManager:getFishingService().stats

# 2. Check file persistence
lua io.exists(getMudletHomeDir().."/poopDeck_fishing_stats.json")

# 3. Reset statistics (will clear all data)
resetfishstats

# 4. Manual statistic increment test
lua poopDeck.sessionManager:getFishingService().stats.totalCasts = 5
fishstats
```

### Bait Source Problems

**Problem**: System can't find bait from configured source
**Symptoms**:
- "Can't find bait" messages
- Fishing attempts fail immediately
- Commands executed but no effect

**Diagnostic Steps**:
```lua
# 1. Check current bait configuration
lua poopDeck.sessionManager:getFishingService().equipment

# 2. Verify bait availability
# Tank: Must have tank with specified bait
# Inventory: Must have bait in inventory
# Fishbucket: Must have fishbucket with specified bait
```

**Solutions**:
```lua
# 1. Verify bait availability in game
inv                    # Check inventory
probe tank            # Check tank contents
probe fishbucket      # Check fishbucket contents

# 2. Change bait source
fishsource inventory   # Switch to inventory
fishbait <available_bait>  # Use available bait

# 3. Test manual bait command
send("bait hook with bass from tank")  # Direct test
```

## 🐙 Seamonster Combat Issues

### Auto-Combat Not Working

**Problem**: Seamonsters surface but auto-firing doesn't begin
**Symptoms**:
- Seamonster surface messages appear
- No automatic weapon firing
- Manual firing works fine

**Diagnostic Steps**:
```lua
# 1. Check automatic mode
lua poopDeck.autoSeaMonster
lua poopDeck.mode

# 2. Verify weapon selection
lua poopDeck.weapons

# 3. Check health status
lua gmcp.Char.Vitals.hp
lua gmcp.Char.Vitals.maxhp
lua poopDeck.config.sipHealthPercent
```

**Solutions**:
```lua
# 1. Enable automatic mode
autosea

# 2. Select a weapon
seaweapon ballista

# 3. Check health threshold
poophp 75

# 4. Verify GMCP connection
lua gmcp.Char.Vitals    # Should show health data

# 5. Manual trigger test
lua poopDeck.monsterSurfaced()
```

### Weapons Not Firing

**Problem**: Combat commands execute but no weapon firing occurs
**Symptoms**:
- Commands accepted but no game action
- No error messages
- Manual weapon commands work

**Diagnostic Steps**:
```lua
# 1. Check firing state
lua poopDeck.firing
lua poopDeck.oor        # Out of range status

# 2. Verify weapon commands
lua poopDeck.weapons.ballista    # Should be true for selected weapon

# 3. Check maintenance setting
lua poopDeck.maintain
```

**Solutions**:
```lua
# 1. Reset firing state
lua poopDeck.firing = false
lua poopDeck.oor = false

# 2. Verify weapon selection
seaweapon ballista
lua poopDeck.weapons    # Check weapon states

# 3. Test manual firing
firb    # Manual ballista fire

# 4. Check ship status
# Must be on a ship with loaded weapons
```

### Health Safety Not Working

**Problem**: System doesn't stop firing when health is low
**Symptoms**:
- Health drops below threshold
- Firing continues
- No curing activation

**Diagnostic Steps**:
```lua
# 1. Check health threshold
lua poopDeck.config.sipHealthPercent

# 2. Verify GMCP health data
lua gmcp.Char.Vitals.hp
lua gmcp.Char.Vitals.maxhp

# 3. Test health calculation
lua (tonumber(gmcp.Char.Vitals.hp)/tonumber(gmcp.Char.Vitals.maxhp))*100
```

**Solutions**:
```lua
# 1. Set proper health threshold
poophp 75

# 2. Test GMCP connection
lua gmcp = gmcp or {}
lua gmcp.Char = gmcp.Char or {}
lua gmcp.Char.Vitals = gmcp.Char.Vitals or {hp = "1000", maxhp = "1000"}

# 3. Manual health check test
lua poopDeck.toggleCuring()

# 4. Reset safety systems
lua poopDeck.rescue = false
```

## 🔔 Notification Issues

### Seamonster Timers Not Working

**Problem**: No notification alerts for seamonster spawns
**Symptoms**:
- No 5-minute, 1-minute, or spawn alerts
- Silent seamonster spawns
- Timer system not starting

**Diagnostic Steps**:
```lua
# 1. Check notification service
lua poopDeck.sessionManager:getNotificationService()

# 2. Verify timer system
lua poopDeck.sessionManager:getNotificationService():getActiveTimers()

# 3. Check notification configuration
lua poopDeck.sessionManager:getNotificationService():getConfiguration()
```

**Solutions**:
```lua
# 1. Start notification cycle manually
lua poopDeck.sessionManager:getNotificationService():startSeamonsterCycle()

# 2. Verify timer creation
lua tempTimer(5, function() echo("Timer test") end)

# 3. Reset notification service
lua poopDeck.sessionManager:getNotificationService():stopSeamonsterCycle()
lua poopDeck.sessionManager:getNotificationService():startSeamonsterCycle()
```

## 🪟 Status Window Issues

### Windows Not Appearing

**Problem**: Status windows don't show up when expected
**Symptoms**:
- `poopwindows` shows windows but they're not visible
- Events occur but no window updates
- Commands execute but no display

**Diagnostic Steps**:
```lua
# 1. Check window service
lua poopDeck.sessionManager:getStatusWindowService()

# 2. Verify window initialization
lua poopDeck.sessionManager:getStatusWindowService():getAllWindowsInfo()

# 3. Check Mudlet window functions
lua createMiniConsole("test", 0, 0, 100, 100)
lua showWindow("test")
```

**Solutions**:
```lua
# 1. Initialize windows manually
lua poopDeck.sessionManager:getStatusWindowService():initializeWindows()

# 2. Show specific windows
poopcombat
poopfishing
poopship
poopalerts

# 3. Reset window system
lua poopDeck.sessionManager:getStatusWindowService():clearWindow("combat")
lua poopDeck.sessionManager:getStatusWindowService():showWindow("combat")
```

### Windows Show Blank/No Content

**Problem**: Windows appear but contain no text
**Symptoms**:
- Windows visible but empty
- No message history
- Events don't populate content

**Solutions**:
```lua
# 1. Test window output
lua poopDeck.sessionManager:getStatusWindowService():addCombatMessage("Test message")

# 2. Verify message formatting
lua cecho("test", "Test message")

# 3. Check window clear/refresh
lua clearWindow("poopCombat")
lua poopDeck.sessionManager:getStatusWindowService():updateWindowTitle("combat")
```

## 📢 Prompt Management Issues

### Quiet Mode Not Working

**Problem**: Messages still appear when quiet mode is enabled
**Symptoms**:
- Sailing prompts continue showing
- No message suppression
- `poopprompts` shows no effect

**Diagnostic Steps**:
```lua
# 1. Check quiet mode status
lua poopDeck.sessionManager:getPromptService().throttleConfig.quietMode

# 2. Verify prompt service
lua poopDeck.sessionManager:getPromptService()

# 3. Check message processing
lua poopDeck.sessionManager:getPromptService():getStatistics()
```

**Solutions**:
```lua
# 1. Enable quiet mode manually
lua poopDeck.sessionManager:getPromptService():setQuietMode(true)

# 2. Test message processing
lua poopDeck.sessionManager:getPromptService():processPromptMessage("Test message")

# 3. Verify trigger integration
# Check: Triggers → Utility → Parsing_Prompt.lua
```

## 🛡️ Error Handling Issues

### System Errors Not Recovering

**Problem**: Errors occur but system doesn't recover automatically
**Symptoms**:
- Repeated error messages
- Services remain in failed state
- No automatic restart attempts

**Diagnostic Steps**:
```lua
# 1. Check error handling service
lua poopDeck.sessionManager:getErrorHandlingService()

# 2. Review error history
lua poopDeck.sessionManager:getErrorHandlingService():getErrorStatistics()

# 3. Check recovery strategies
lua poopDeck.sessionManager:getErrorHandlingService():getRecentErrors(5)
```

**Solutions**:
```lua
# 1. Enable error handling
lua poopDeck.sessionManager:getErrorHandlingService():setEnabled(true)

# 2. Test error recovery
lua poopDeck.sessionManager:getErrorHandlingService():handleError("Test error", {}, "test")

# 3. Manual service restart
lua poopDeck.sessionManager:restart()
```

## 🔧 Advanced Troubleshooting

### GMCP Connection Issues

**Problem**: System can't read character data (health, stats, etc.)
**Symptoms**:
- Health monitoring doesn't work
- Character data unavailable
- System treats player as injured

**Solutions**:
```lua
# 1. Check GMCP status
lua gmcp.Char

# 2. Enable GMCP in Achaea
CONFIG GMCP ON

# 3. Verify Mudlet GMCP
# Settings → Network → Enable GMCP

# 4. Test GMCP data
lua display(gmcp.Char.Vitals)

# 5. Reset GMCP
lua gmcp = {}
# Reconnect to Achaea
```

### Performance Issues

**Problem**: Mudlet becomes slow or unresponsive
**Symptoms**:
- Lag when executing commands
- Slow window updates
- Memory usage increases

**Diagnostic Steps**:
```lua
# 1. Check active timers
lua display(getActiveTimers())

# 2. Check memory usage
lua collectgarbage("collect")
lua collectgarbage("count")

# 3. Monitor service status
lua poopDeck.sessionManager:getStatus()
```

**Solutions**:
```lua
# 1. Clear old timers
lua killTimer("poopDeck_cleanup_timer")

# 2. Restart services
lua poopDeck.sessionManager:restart()

# 3. Clear history
lua poopDeck.sessionManager:getFishingService():clearHistory()

# 4. Reduce window retention
# Adjust maxLines in window configurations
```

### Trigger Pattern Issues

**Problem**: System doesn't respond to game events
**Symptoms**:
- Fish caught/escaped not detected
- Seamonster events ignored
- No automatic responses

**Diagnostic Steps**:
```lua
# 1. Check trigger status
# Scripts → Triggers in Mudlet

# 2. Test patterns manually
# Enable trigger debugging in Mudlet

# 3. Verify trigger patterns
# Check trigger regex patterns match game output
```

**Solutions**:
```lua
# 1. Reload triggers
# Disable and re-enable trigger groups

# 2. Test pattern matching
lua string.match("The fish escapes!", "fish.*escape")

# 3. Update patterns for game changes
# Check recent Achaea announce posts for message changes

# 4. Manual event simulation
lua poopDeck.fishEscaped("manual test")
lua poopDeck.monsterSurfaced()
```

## 📞 Getting Additional Help

### Diagnostic Information Collection

When seeking help, provide this information:

```lua
# System Information
lua getMudletVersion()
lua poopDeck.VERSION or "Unknown"
lua poopDeck.sessionManager and poopDeck.sessionManager:getStatus() or "Not initialized"

# Service Status
lua poopDeck.sessionManager:getStatus()
lua poopDeck.sessionManager:getFishingService() and "Fishing OK" or "Fishing MISSING"
lua poopDeck.sessionManager:getNotificationService() and "Notifications OK" or "Notifications MISSING"

# Configuration
lua poopDeck.sessionManager:getFishingService() and poopDeck.sessionManager:getFishingService():getConfiguration() or "No fishing config"
```

### Error Logs

```lua
# Check error logs
lua io.exists(getMudletHomeDir().."/poopDeck_errors.log")

# View recent errors
lua poopDeck.sessionManager:getErrorHandlingService():getRecentErrors(10)
```

### Community Support

1. **GitHub Issues**: Report bugs with diagnostic information
2. **Mudlet Forums**: Community troubleshooting discussion
3. **Discord/IRC**: Real-time help from other users

### Before Reporting Issues

1. **Restart Mudlet**: Try a clean restart
2. **Reinstall Package**: Remove and reinstall poopDeck
3. **Check Documentation**: Review user guide and configuration docs
4. **Test Minimal Setup**: Try with default configuration
5. **Collect Diagnostics**: Gather system information above

---

**🛠️🚢 Most issues can be resolved with the steps above. Don't hesitate to seek help if problems persist!**