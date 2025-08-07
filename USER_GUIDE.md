# 🚢 poopDeck User Guide

Your complete guide to using the poopDeck seafaring automation system in Achaea.

## 🎯 Quick Start

### Essential Commands
```lua
poopsail      # Show sailing commands
poopfish      # Show fishing commands  
poopmonster   # Show seamonster commands
poopfull      # Show ALL commands
```

## 🎣 Fishing System

The poopDeck fishing system is designed to be **intelligent and resilient**, automatically handling common fishing scenarios.

### Basic Fishing Commands

```lua
# Start fishing with defaults
fish

# Start with specific bait and cast distance  
fish bass medium
fish shrimp long
fish worms short

# Stop fishing
stopfish

# View detailed statistics
fishstats
```

### Fishing Configuration

```lua
# Set default bait (accepts any bait type)
fishbait bass
fishbait shrimp
fishbait <any_bait_you_have>

# Set bait source
fishsource tank        # Get bait from a tank
fishsource inventory   # Use bait from inventory  
fishsource fishbucket  # Get bait from fishbucket

# Set default cast distance
fishcast short    # Close to shore - faster bites
fishcast medium   # Balanced distance (default)
fishcast long     # Far from shore - potentially better fish

# Toggle auto-restart when fish escape (RECOMMENDED: ON)
fishrestart
```

### 🔄 Auto-Resume Feature (Key Feature!)

The system **automatically restarts fishing** when fish escape for any reason:

- **Automatic**: Detects when fish get away
- **Smart Delays**: 5-second delay between restart attempts
- **Retry Limits**: Up to 3 automatic retries per escape
- **Persistent**: Tracks statistics across all restart attempts
- **Reliable**: Works with any escape reason (line snapped, fish too strong, etc.)

**Example Scenario:**
```
[You cast your line...]
The fish snaps your line and escapes!
🔄 Fish escaped (line snapped). Auto-restarting... (Attempt 1/3)
[System waits 5 seconds then automatically casts again]
```

### Fishing Statistics

```lua
fishstats    # View comprehensive statistics

# Example output:
=== Fishing Statistics ===
Total Casts: 45
Total Catches: 23
Fish Escaped: 12
Success Rate: 51%
Session Time: 1.5 hours
Current Bait: bass (from tank)
Auto-Restart: ENABLED ✅
```

### Fishing Service Management

```lua
fishenable       # Enable fishing automation
fishdisable      # Disable fishing automation
resetfishstats   # Reset all statistics (WARNING: permanent!)
```

## 🐙 Seamonster Combat

Automated seamonster fighting with intelligent weapon management.

### Combat Setup

```lua
# Select your weapon
seaweapon ballista   # Balanced option
seaweapon onager     # Heavy damage (alternates ammo types)
seaweapon thrower    # Fast firing

# Enable automatic mode
autosea

# Set health threshold for safety
poophp 75    # Stop firing below 75% health (default)
poophp 80    # More conservative
```

### Manual Combat Commands

```lua
# Manual firing (when not in auto mode)
firb    # Fire ballista with dart
firo    # Fire onager (alternates starshot/spidershot automatically)  
fird    # Fire thrower with wardisc
firf    # Fire ballista with flare
first   # Fire onager with starshot specifically
firsp   # Fire onager with spidershot specifically
```

### 🔔 Seamonster Notifications

Automatic 20-minute spawn cycle notifications:

- **15 minutes**: "⏰ 5 minutes until seamonster spawn!"
- **19 minutes**: "⚡ 1 minute until seamonster spawn! Get ready!"  
- **20 minutes**: "🐉 Seamonster spawning now! Time to fish!"

*Notifications automatically start a new 20-minute cycle*

### Combat Status

The system tracks:
- **Weapon Selection**: Currently selected weapon
- **Firing State**: Whether currently engaged in combat
- **Health Monitoring**: Automatic safety checks
- **Range Status**: In/out of range tracking
- **Shot Counting**: Number of shots fired per encounter

## 🚢 Ship Navigation & Management

Complete ship operation commands with safety features.

### Navigation Commands

```lua
# Docking and movement
dock north      # Dock in specified direction
dock northeast  # Supports all 8 directions + up/down
scast          # Cast off from dock

# Speed and direction  
sss 50         # Set sail speed (0-100)
stt northwest  # Turn ship to direction
sstop          # All stop (emergency brake)

# Rowing
srow           # Start rowing
sreo           # Stop rowing (relax oars)
```

### Ship Maintenance

```lua
# Manual maintenance
mainh          # Maintain hull
mains          # Maintain sails  
mainn          # Stop maintaining
srep           # Repair hull and sails

# Anchor and plank
lanc           # Lower anchor
ranc           # Raise anchor
lpla           # Lower plank
rpla           # Raise plank
```

### Ship Settings

```lua
# Communication
scomm on       # Turn on communication screen
scomm off      # Turn off communication screen

# Warnings  
shwon          # Enable ship warnings
shwoff         # Disable ship warnings
```

### Emergency Commands

```lua
# Emergency situations
chop           # Chop ropes
crig           # Clear rigging
sres           # Ship rescue (uses token)
rain           # Use rainstorm to extinguish fires

# Fire fighting
doum           # Douse yourself with bucket
dour           # Douse room with bucket

# Wavecall (emergency movement)
wav north 3    # Wavecall north for 3 spaces
wav east 1     # Wavecall east for 1 space
```

## 🪟 Status Windows System

Multi-window display system showing real-time information.

### Window Management

```lua
# Toggle individual windows
poopcombat     # Combat status (weapon, health, firing state)
poopship       # Ship status (speed, direction, maintenance)
poopfishing    # Fishing status (casts, catches, escapes)
poopalerts     # Alert messages (notifications, errors)

# View all windows
poopwindows    # Shows status and position of all windows
```

### Window Features

- **Auto-show**: Windows appear when relevant events occur
- **Auto-hide**: Inactive windows hide after 5 minutes (configurable)
- **Positioning**: Drag windows to preferred locations
- **Resizing**: Resize as needed for your screen
- **Message History**: Each window maintains recent message history
- **Color Coding**: Different message types have distinct colors

### Window Types

1. **Combat Window (Red)**
   - Weapon selections
   - Firing status
   - Health warnings
   - Range notifications

2. **Ship Window (Cyan)**  
   - Speed and direction
   - Maintenance status
   - Anchor/plank state
   - Navigation events

3. **Fishing Window (Green)**
   - Cast attempts
   - Fish caught/escaped
   - Auto-restart notifications
   - Equipment changes

4. **Alerts Window (Yellow)**
   - Seamonster spawn timers
   - System notifications
   - Error messages
   - Important alerts

## 📢 Prompt Management & Spam Reduction

Intelligent message filtering to reduce screen clutter during sailing.

### Quiet Mode

```lua
poopquiet      # Toggle quiet mode (suppresses sailing prompts)

# When enabled:
# - Ship movement prompts are suppressed
# - Important messages still shown
# - Periodic summaries provided
```

### Prompt Statistics

```lua
poopprompts    # View detailed prompt management stats

# Example output:
=== Prompt Management Statistics ===
Total Messages: 1,247
Displayed: 892 (71.5%)
Suppressed: 355 (28.5%)
  - Quiet Mode: 201
  - Duplicates: 89  
  - Throttled: 65
=== Configuration ===
Quiet Mode: Yes
Throttle Interval: 2s
```

## ⚙️ System Configuration

### Health and Safety

```lua
poophp 75      # Set health threshold (default: 75%)
poophp 80      # More conservative setting
poophp 90      # Very conservative (recommended for novices)
```

**How it works:**
- System monitors your health via GMCP
- Stops firing when health drops below threshold  
- Automatically turns curing on
- Resumes when health recovers

### Maintenance Preferences

```lua
# Set automatic maintenance during combat
mainh          # Always maintain hull during seamonster fights
mains          # Always maintain sails during seamonster fights  
mainn          # No automatic maintenance
```

## 🛡️ Error Handling & Recovery

The system includes comprehensive error handling:

### Automatic Recovery

- **Fishing Failures**: Auto-restart with fresh equipment
- **Combat Interruptions**: Automatic retry after delays
- **Navigation Errors**: State reset and recovery
- **Service Crashes**: Automatic service restart

### Error Categories

1. **Fishing Errors**: Equipment, location, or command issues
2. **Combat Errors**: Weapon, health, or range problems  
3. **Navigation Errors**: Movement or ship state issues
4. **System Errors**: Service communication or initialization

### Viewing Errors

Errors are handled automatically, but you can review them:
- Check Mudlet's error console for detailed logs
- System provides user-friendly error messages
- Recovery attempts are logged and reported

## 📊 Statistics & Monitoring

### Fishing Statistics
```lua
fishstats      # Comprehensive fishing data
resetfishstats # Clear all fishing statistics
```

### System Status
```lua
poopwindows    # Window system status
poopprompts    # Message management statistics
```

## 🎮 Gameplay Integration

### Best Practices

1. **Start Simple**: Begin with basic fishing and sailing
2. **Test Safely**: Try features in safe areas first
3. **Monitor Health**: Keep health threshold reasonable
4. **Use Windows**: Status windows provide valuable information
5. **Check Statistics**: Review fishing stats to optimize setup

### Typical Workflow

```lua
# 1. Basic setup
poophp 80
fishbait bass
fishsource tank

# 2. Start activities
fish              # Begin fishing
autosea           # Enable seamonster auto-fire
poopwindows       # Show status windows

# 3. Monitor and adjust
fishstats         # Check fishing performance
poopprompts       # Review message management
```

### Integration with Other Systems

poopDeck is designed to work alongside:
- **Manual commands**: You can always override automation
- **Other packages**: Minimal interference with other Mudlet packages
- **Achaea changes**: Robust parsing handles game updates
- **Custom aliases**: Use your own commands alongside poopDeck

## 🚨 Safety Features

### Health Monitoring
- Continuous health tracking via GMCP
- Automatic curing activation when needed
- Combat disengagement below health threshold

### Rescue Mode
- Built-in rescue mode detection
- Disables all combat when rescue is active
- Prevents automated actions during emergencies

### Smart Retries
- Limited retry attempts prevent infinite loops
- Exponential backoff for failed operations
- Automatic service recovery after errors

### User Override
- All automation can be manually stopped
- Emergency commands always work
- User commands take priority over automation

## 🔧 Advanced Usage

### Customization

The system is designed to be flexible:
- All thresholds are configurable
- Bait sources can be changed on-the-fly
- Window positions are remembered
- Statistics can be reset when needed

### Performance Optimization

- Efficient event handling
- Memory management for long sessions
- Optimized message processing
- Minimal impact on Mudlet performance

---

## 📞 Getting Help

### In-Game Help
```lua
poopsail       # Sailing and navigation help
poopfish       # Fishing system help  
poopmonster    # Combat and seamonster help
poopfull       # Complete command reference
```

### Command Categories

- **poop-prefixed**: System management (`poopquiet`, `poopwindows`)
- **fish-prefixed**: Fishing system (`fishbait`, `fishstats`)
- **sea-prefixed**: Seamonster combat (`seaweapon`, `autosea`)
- **s-prefixed**: Ship navigation (`sss`, `stt`, `srep`)
- **Standard**: Common operations (`dock`, `fish`, `firb`)

### Support Resources

1. **GitHub Repository**: Issues, updates, documentation
2. **Mudlet Forums**: Community discussion and tips
3. **In-game testing**: Try features in safe environments first

---

**🚢⚓🎣 Happy sailing! May your holds be full and your seamonster kills be swift!**