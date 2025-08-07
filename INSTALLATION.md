# 🚢 poopDeck Installation Guide

Complete installation and setup instructions for the poopDeck Achaea seafaring automation package.

## 📋 Requirements

- **Mudlet 4.0+** (latest version recommended)
- **Achaea character** with access to sailing/seafaring
- **Basic sailing knowledge** recommended but not required

## 🚀 Installation Methods

### Method 1: GitHub Release (Recommended)

1. **Download the latest release:**
   - Go to [poopDeck Releases](https://github.com/nikolais/poopDeck/releases)
   - Download `poopDeck-v2.0.0.mpackage`

2. **Install in Mudlet:**
   - Open Mudlet
   - Go to `Packages` → `Package Manager` 
   - Click `Install` and select the downloaded `.mpackage` file
   - Click `OK` to install

3. **Restart Mudlet** to complete installation

### Method 2: Direct Package Installation

1. **Download package file:**
   ```bash
   wget https://github.com/nikolais/poopDeck/releases/latest/download/poopDeck.mpackage
   ```

2. **Install via Mudlet:**
   - Drag and drop the `.mpackage` file onto Mudlet
   - OR use Package Manager → Install

### Method 3: Development Installation

1. **Clone repository:**
   ```bash
   git clone https://github.com/nikolais/poopDeck.git
   cd poopDeck
   ```

2. **Create package:**
   ```bash
   # Using Mudlet's package creator or manual zip
   zip -r poopDeck.mpackage src/ mfile
   ```

3. **Install in Mudlet** as above

## ⚙️ Initial Setup

### 1. Verify Installation

After installing and restarting Mudlet:

```lua
-- In Mudlet command line, type:
poopsail
```

You should see the help system display. If not, see troubleshooting below.

### 2. Configure Basic Settings

```lua
-- Set your health threshold (default 75%)
poophp 80

-- Enable status windows
poopwindows

-- Test fishing (if you have fishing gear)
fish bass medium
```

### 3. Weapon Configuration (for seamonsters)

```lua
-- Set your preferred weapon
seaweapon ballista

-- Enable automatic mode
autosea
```

## 🎣 Fishing Setup

### Configure Your Fishing Preferences

```lua
-- Set default bait (any type you have)
fishbait bass

-- Set bait source (tank, inventory, or fishbucket)
fishsource tank

-- Set default cast distance
fishcast medium

-- Enable auto-restart when fish escape (recommended)
fishrestart
```

### Test Fishing System

```lua
-- Start fishing with current settings
fish

-- View fishing statistics
fishstats

-- Stop fishing
stopfish
```

## 🐙 Seamonster Setup

### Configure Weapon Settings

```lua
-- Choose your weapon (ballista, onager, or thrower)
seaweapon ballista

-- Set maintenance preference
mainh     # Maintain hull
mains     # Maintain sails
mainn     # No maintenance
```

### Enable Notifications

```lua
-- Seamonster spawn notifications are enabled by default
-- 20-minute cycle with 5min, 1min, and spawn alerts
-- No additional setup required
```

## 🪟 Status Windows

### Window Management

```lua
-- Show/hide individual windows
poopcombat    # Combat status
poopship      # Ship status  
poopfishing   # Fishing status
poopalerts    # Alert messages

-- View all window information
poopwindows
```

### Window Positioning

Windows will appear automatically when relevant events occur. You can:
- **Drag windows** to reposition them
- **Resize windows** as needed
- **Close windows** - they'll reappear when needed

## 🔧 Advanced Configuration

### Prompt Spam Reduction

```lua
-- Enable quiet mode to suppress sailing prompts
poopquiet

-- View prompt statistics
poopprompts
```

### Error Handling

The system automatically handles errors and attempts recovery. No configuration needed, but you can:

```lua
-- View error statistics (if errors occur)
-- Check Mudlet's error console for detailed logs
```

## ✅ Verification Checklist

After installation, verify these features work:

- [ ] **Help System**: `poopsail` shows sailing commands
- [ ] **Fishing**: `fish` starts fishing, `stopfish` stops
- [ ] **Status Windows**: `poopwindows` shows window information  
- [ ] **Navigation**: `dock north` attempts to dock north
- [ ] **Notifications**: Seamonster timer notifications appear
- [ ] **Error Handling**: System recovers from command errors

## 🚨 Troubleshooting

### Package Not Loading

1. **Check Mudlet version**: Ensure you're running Mudlet 4.0+
2. **Restart Mudlet**: Sometimes requires a restart after installation
3. **Check Package Manager**: Ensure poopDeck is listed and enabled
4. **Reinstall**: Remove and reinstall the package

### Commands Not Working

1. **Check installation**: Type `lua poopDeck` - should show table
2. **Case sensitivity**: Commands are case-sensitive
3. **Check aliases**: All commands start with specific prefixes

### Fishing Not Working

1. **Check gear**: Ensure you have fishing pole and bait
2. **Location**: Must be in a fishing location  
3. **Configuration**: Run `fishstats` to see current settings

### Windows Not Appearing

1. **Enable windows**: Use `poopwindows` command
2. **Check triggers**: Windows appear based on game events
3. **Manual show**: Use `poopcombat`, `poopship`, etc.

### Getting Help

1. **In-game help**: Use `poopsail`, `poopfish`, `poopmonster`  
2. **Command reference**: Type `poopfull` for all commands
3. **GitHub issues**: Report problems at the repository
4. **Mudlet forums**: Community support available

## 📚 Next Steps

Once installed:

1. **Read the User Guide** - `USER_GUIDE.md`
2. **Configure settings** to your preferences
3. **Test in safe areas** before relying on automation
4. **Join the community** for tips and updates

---

**🚢⚓🎣 Welcome aboard! poopDeck is ready to enhance your Achaea seafaring adventures!**