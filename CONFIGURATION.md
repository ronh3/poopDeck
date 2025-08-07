# ⚙️ poopDeck Configuration Guide

Complete configuration reference for customizing poopDeck to your preferences and playstyle.

## 🎯 Configuration Overview

poopDeck uses a layered configuration system:
1. **Default Settings**: Built-in sensible defaults
2. **Persistent Configuration**: Saved settings that survive restarts
3. **Session Overrides**: Temporary changes for current session
4. **Command-line Changes**: Real-time adjustments via commands

## 🎣 Fishing Configuration

### Equipment Settings

```lua
# Bait Configuration
fishbait <type>        # Set default bait type
# Examples:
fishbait bass          # Most common
fishbait shrimp        # Alternative option
fishbait worms         # Another alternative
fishbait <any_name>    # System accepts ANY bait type

# Bait Source Configuration  
fishsource tank        # Get bait from a tank (default)
fishsource inventory   # Use bait from your inventory
fishsource fishbucket  # Get bait from a fishbucket

# Cast Distance Configuration
fishcast short         # Close to shore - faster bites
fishcast medium        # Balanced distance (default)
fishcast long          # Far from shore - potentially better fish
```

### Automation Settings

```lua
# Auto-Restart Configuration (IMPORTANT!)
fishrestart            # Toggle auto-restart when fish escape
# When ON: Automatically restarts fishing after fish escape
# When OFF: Stops fishing when fish escape (manual restart needed)

# Service Management
fishenable             # Enable fishing automation service
fishdisable            # Disable fishing automation service
```

### Advanced Fishing Settings

**Default Configuration:**
```lua
{
  enabled: true,
  autoRestart: true,        # Auto-restart when fish escape
  maxRetries: 3,           # Maximum restart attempts per escape
  retryDelay: 5,           # Seconds between restart attempts  
  defaultBait: "bass",     # Default bait type
  defaultCastDistance: "medium",  # Default cast distance
  baitSource: "tank",      # Default bait source
  debugMode: false         # Enable debug messages
}
```

**Command Generation Examples:**
```lua
# Bait Source: "tank"
queue add freestand bait hook with bass from tank
queue add freestand cast medium

# Bait Source: "inventory"  
queue add freestand bait hook with bass
queue add freestand cast medium

# Bait Source: "fishbucket"
queue add freestand get bass from fishbucket
queue add freestand bait hook with bass
queue add freestand cast medium
```

## 🐙 Seamonster Configuration

### Weapon Settings

```lua
# Weapon Selection
seaweapon ballista     # Balanced damage and speed
seaweapon onager       # Heavy damage (alternates ammo automatically)
seaweapon thrower      # Fast firing rate

# Combat Mode
autosea               # Toggle automatic seamonster combat
# When ON: Automatically fires at seamonsters when they surface
# When OFF: Manual firing required
```

### Health and Safety

```lua
# Health Threshold Configuration
poophp 75             # Default: Stop firing below 75% health
poophp 80             # Conservative: Stop at 80%
poophp 90             # Very safe: Stop at 90%
poophp 65             # Aggressive: Allow down to 65%

# Safety Features:
# - Monitors health via GMCP
# - Automatically enables curing below threshold  
# - Disables combat until health recovers
# - Built-in rescue mode detection
```

### Maintenance Settings

```lua
# Automatic Maintenance During Combat
mainh                 # Always maintain hull during fights
mains                 # Always maintain sails during fights
mainn                 # No automatic maintenance

# Manual Maintenance
srep                  # Manual repair (hull and sails)
```

### Seamonster Advanced Settings

**Default Configuration:**
```lua
{
  autoSeaMonster: false,      # Automatic mode disabled by default
  sipHealthPercent: 75,       # Health threshold percentage
  weapon: "ballista",         # Default weapon selection
  maintain: null,             # No automatic maintenance by default
  rescue: false,              # Rescue mode detection
  firedSpider: false          # Onager ammo tracking
}
```

**Weapon Command Sequences:**
```lua
# Ballista Commands
maintain <type>
load ballista with dart  
fire ballista at seamonster

# Onager Commands (alternates automatically)
maintain <type>
load onager with spidershot    # First shot
fire onager at seamonster

maintain <type>  
load onager with starshot      # Next shot
fire onager at seamonster

# Thrower Commands
maintain <type>
load thrower with disc
fire thrower at seamonster
```

## 🔔 Notification Configuration

### Seamonster Spawn Notifications

**Automatic 20-minute cycle with three alerts:**

```lua
# Notification Timeline:
# 15:00 → "⏰ 5 minutes until seamonster spawn!"
# 19:00 → "⚡ 1 minute until seamonster spawn! Get ready!"  
# 20:00 → "🐉 Seamonster spawning now! Time to fish!"
#         [Cycle automatically restarts]
```

**Configuration:**
```lua
{
  spawnCycle: 1200,           # 20 minutes (1200 seconds)
  fiveMinuteWarning: true,    # 5-minute warning enabled
  oneMinuteWarning: true,     # 1-minute warning enabled  
  timeToFishWarning: true,    # Spawn alert enabled
  enabled: true               # Notification system enabled
}
```

**Customization:**
- Notifications automatically start when seamonsters are detected
- All three warnings enabled by default
- Cycle continues until manually disabled
- Integrates with status window system

## 🪟 Status Window Configuration

### Window Management

```lua
# Individual Window Controls
poopcombat            # Toggle combat status window
poopship              # Toggle ship status window
poopfishing           # Toggle fishing status window  
poopalerts            # Toggle alert messages window

# System Management
poopwindows           # Show all window information and status
```

### Window Settings

**Default Window Layout:**
```lua
{
  combat: {
    position: {x: 0, y: 0},
    size: {width: 300, height: 150},
    maxLines: 20,
    autoHide: true,           # Hide after 5 minutes of inactivity
    color: "red"
  },
  ship: {
    position: {x: 0, y: 160},
    size: {width: 300, height: 200}, 
    maxLines: 25,
    autoHide: false,          # Always visible when shown
    color: "cyan"
  },
  fishing: {
    position: {x: 310, y: 0},
    size: {width: 250, height: 180},
    maxLines: 15,
    autoHide: true,
    color: "green"
  },
  alerts: {
    position: {x: 310, y: 190},
    size: {width: 250, height: 120},
    maxLines: 10, 
    autoHide: false,
    color: "yellow"
  }
}
```

### Window Behavior

- **Auto-show**: Windows appear automatically when relevant events occur
- **Auto-hide**: Inactive windows hide after configured time
- **Persistence**: Window positions saved between sessions
- **Overflow Management**: Old messages automatically cleared when limits reached
- **Color Coding**: Different message types use distinct colors

## 📢 Prompt Management Configuration

### Spam Reduction Settings

```lua
# Quiet Mode Toggle
poopquiet             # Toggle quiet mode (suppresses sailing prompts)

# View Current Statistics
poopprompts           # Shows detailed message management statistics
```

### Advanced Prompt Settings

**Default Configuration:**
```lua
{
  throttleEnabled: true,      # Enable message throttling
  quietMode: false,           # Quiet mode disabled by default
  throttleInterval: 2,        # 2-second throttling window
  maxMessagesPerInterval: 1,  # Max 1 message per interval
  suppressDuplicates: true    # Remove duplicate messages
}
```

**Throttling Behavior:**
- **Normal Mode**: Shows important messages, throttles repetitive ones
- **Quiet Mode**: Suppresses most sailing prompts, shows summaries
- **Duplicate Detection**: Removes identical messages within 5-second window
- **Summary Reports**: Periodic summaries of suppressed messages

## 🛡️ Error Handling Configuration

### Error Recovery Settings

**Automatic Recovery Strategies:**

```lua
# Fishing Errors:
restart_fishing        # Stop and restart fishing service
reset_fishing_state    # Clear fishing state variables
reinitialize_fishing   # Full fishing service reinitialization

# Seamonster Errors:
reset_weapon_state     # Clear weapon and firing flags
restart_seamonster_cycle  # Restart notification timers
clear_firing_state     # Reset combat state variables

# Navigation Errors:
reset_ship_state       # Reset ship status variables
clear_navigation_queue # Clear pending navigation commands
reinitialize_navigation # Restart navigation service

# Network Errors:
retry_connection       # Attempt to restore GMCP connection
reset_gmcp            # Reset GMCP data structures
reinitialize_connection # Full connection reinitialization
```

**Error Handling Configuration:**
```lua
{
  logToFile: true,            # Log errors to file
  logToConsole: true,         # Show errors in Mudlet
  logFilePath: "poopDeck_errors.log",
  maxRetries: 3,              # Maximum automatic retry attempts
  retryDelay: 2,              # Seconds between retries
  enabled: true               # Error handling system enabled
}
```

## 🔧 Advanced System Configuration

### Session Manager Settings

**Service Initialization Order:**
1. Error Handling Service (first)
2. Fishing Service
3. Notification Service  
4. Status Window Service
5. Prompt Service
6. Ship Management Service

**Cross-Service Integration:**
- Fishing events → Status windows
- Notification events → Alert windows  
- Error events → Error handling service
- All services → Error recovery system

### Performance Settings

```lua
{
  # Event System Optimization
  maxEventListeners: 100,     # Maximum listeners per event
  eventTimeout: 5000,         # Event processing timeout (ms)
  
  # Memory Management
  historyLimit: 1000,         # Maximum history entries per service
  statisticsRetention: 7,     # Days to retain statistics
  
  # Timer Management
  maxActiveTimers: 50,        # Maximum concurrent timers
  timerCleanupInterval: 300   # Timer cleanup frequency (seconds)
}
```

## 📁 Configuration Files

### File Locations

```
# Mudlet Profile Directory:
~/.config/mudlet/profiles/<profile>/poopDeck/

# Configuration Files:
poopDeck_config.json       # Main configuration
fishing_statistics.json    # Fishing statistics
window_positions.json      # Status window positions  
error_log.txt             # Error history log
```

### Configuration Persistence

**What's Saved:**
- Fishing equipment preferences (bait, source, cast distance)
- Weapon selections and combat settings
- Health thresholds and safety settings
- Window positions and visibility states
- Notification preferences
- Prompt management settings

**What's Reset Each Session:**
- Current fishing/combat state
- Active timers and notifications
- Temporary error conditions
- Session statistics (unless explicitly saved)

### Backup and Restore

**Manual Backup:**
```bash
# Copy configuration directory
cp -r ~/.config/mudlet/profiles/<profile>/poopDeck/ ~/poopDeck-backup/
```

**Restore Configuration:**
```bash
# Restore from backup
cp -r ~/poopDeck-backup/ ~/.config/mudlet/profiles/<profile>/poopDeck/
```

## 🎛️ Configuration Examples

### Conservative Fishing Setup
```lua
fishbait bass
fishsource tank
fishcast medium
fishrestart               # Enable auto-restart
poophp 85                # Conservative health threshold
fishenable               # Enable service
```

### Aggressive Combat Setup  
```lua
seaweapon onager         # Heavy damage weapon
autosea                  # Enable auto-combat
poophp 70                # Lower health threshold
mainh                    # Maintain hull during combat
```

### Minimal Spam Setup
```lua
poopquiet                # Enable quiet mode
# All status windows disabled by default
# Notifications still work but less verbose
```

### Full Monitoring Setup
```lua
poopwindows              # Enable all status windows
fishstats                # Monitor fishing performance
poopprompts              # Monitor message statistics
# All notifications enabled by default
```

## 🔄 Configuration Updates

### Runtime Changes
Most settings can be changed while the system is running:
```lua
fishbait <new_bait>      # Takes effect on next cast
seaweapon <new_weapon>   # Takes effect immediately  
poophp <new_threshold>   # Takes effect immediately
```

### Restart Required Changes
Some changes require service restart:
- Error handling configuration
- Core service settings
- Cross-service event wiring

### Configuration Validation

The system validates configuration changes:
- **Range Checking**: Numeric values within valid ranges
- **Option Validation**: Enumerated values checked against valid options
- **Dependency Checking**: Related settings verified for consistency
- **Error Recovery**: Invalid configurations revert to defaults

---

## 📞 Configuration Support

### Troubleshooting Configuration Issues

1. **Reset to Defaults**: Remove configuration files to restore defaults
2. **Check Syntax**: Ensure command syntax is correct
3. **Verify Values**: Check that values are within valid ranges
4. **Test Changes**: Make small changes and test before applying more

### Common Configuration Patterns

**New Player Setup:**
```lua
poophp 90        # Very safe health threshold
fishrestart      # Enable auto-resume
mainh           # Maintain hull automatically  
poopquiet       # Reduce spam
```

**Experienced Player Setup:**
```lua
poophp 75        # Standard health threshold
seaweapon onager # Heavy weapon
autosea         # Full automation
poopwindows     # Monitor everything
```

**Testing/Learning Setup:**
```lua
fishdisable     # Manual fishing only
poophp 95       # Ultra-safe health
# All automation disabled for learning
```

---

**⚙️🚢 Configure poopDeck to match your sailing style and preferences!**