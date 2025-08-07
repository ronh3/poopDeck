# 🚢 poopDeck - Complete Achaea Seafaring Automation

[![Release](https://img.shields.io/github/v/release/nikolais/poopDeck)](https://github.com/nikolais/poopDeck/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Mudlet](https://img.shields.io/badge/mudlet-4.0%2B-green.svg)](https://www.mudlet.org/)
[![Achaea](https://img.shields.io/badge/game-achaea-orange.svg)](https://www.achaea.com/)

**poopDeck** is a comprehensive automation package for Achaea seafaring, built for the Mudlet MUD client. Whether you're battling seamonsters, managing your ship, or perfecting your fishing technique, poopDeck provides intelligent automation with robust error handling and extensive customization options.

> *Yes, I chose the name because I have the maturity of a thirteen year old.* 😄

## 🎯 Key Features

### 🐙 **Seamonster Combat**
- **Intelligent Auto-Fire**: Automatic weapon management with health monitoring
- **Multi-Weapon Support**: Ballista, onager (alternating ammo), and thrower
- **Safety Systems**: GMCP health monitoring with automatic curing activation
- **Combat State Management**: Robust tracking and recovery systems

### 🎣 **Advanced Fishing System**  
- **🔄 Auto-Resume**: Automatically restarts fishing when fish escape *(Primary user-requested feature)*
- **Smart Bait Management**: Support for ANY bait type from tank, inventory, or fishbucket
- **Comprehensive Statistics**: Persistent tracking across sessions with detailed analytics
- **Intelligent Retry Logic**: Configurable attempts with smart delays

### 🚢 **Complete Ship Management**
- **Full Navigation**: Docking, sailing, rowing, speed control, turning
- **Maintenance Automation**: Hull and sail maintenance with scheduling
- **Emergency Operations**: Wavecall, ship rescue, fire fighting, rope management
- **Safety Features**: Anchor/plank management and collision avoidance

### 🪟 **Multi-Window Status System**
- **Four Specialized Windows**: Combat, Ship, Fishing, and Alerts
- **Intelligent Display**: Auto-show/hide with message history and overflow management
- **Customizable Layout**: Draggable, resizable windows with position persistence
- **Color-Coded Messages**: Distinct colors for different message types

### 🔔 **Seamonster Spawn Notifications**
- **20-Minute Cycle Tracking**: Automatic spawn predictions
- **Multi-Stage Alerts**: 5-minute, 1-minute, and spawn notifications
- **Smart Scheduling**: Auto-restart cycle with timer management

### 📢 **Prompt Spam Reduction**
- **Intelligent Throttling**: Message rate limiting during ship operations
- **Quiet Mode**: Suppress sailing prompts while preserving important alerts
- **Summary Reports**: Periodic summaries of suppressed messages

### 🛡️ **Comprehensive Error Handling**
- **Automatic Recovery**: Service restart and state recovery
- **Multiple Strategies**: Context-aware recovery approaches
- **Error Logging**: Detailed error tracking with user-friendly messages

## 🚀 Quick Start

### Installation

1. **Download**: Get the latest `poopDeck-v2.0.0.mpackage` from [Releases](https://github.com/nikolais/poopDeck/releases)
2. **Install**: Drag-and-drop onto Mudlet or use Package Manager → Install  
3. **Restart**: Restart Mudlet to complete installation
4. **Verify**: Type `poopsail` to see the help system

### Basic Setup

```lua
# Fishing setup
fishbait bass          # Set your preferred bait
fishsource tank        # Set bait source (tank/inventory/fishbucket)
fish                   # Start fishing (auto-resumes when fish escape!)

# Combat setup  
seaweapon ballista     # Choose weapon
autosea                # Enable auto-combat
poophp 75              # Set health safety threshold

# Status monitoring
poopwindows            # Show status window system
```

## 📋 Command Reference

### 🧭 Navigation & Movement

| Command | Alias | Description |
|---------|-------|-------------|
| `scast` | - | Cast off from dock |
| `sstop` | - | All stop (emergency halt) |
| `srow` | - | Start rowing |
| `sreo` | - | Stop rowing (relax oars) |
| `sss[X]` | `sss 50` | Set sail speed (0-100) |
| `stt[X]` | `stt ne` | Turn ship to direction |
| `dock[X]` | `dock north` | Dock in specified direction |

### ⚓ Ship Management

| Command | Alias | Description |
|---------|-------|-------------|
| `ranc` | - | Raise anchor |
| `lanc` | - | Lower anchor |
| `rpla` | - | Raise plank |
| `lpla` | - | Lower plank |
| `srep` | - | Repair hull and sails |
| `scomm on/off` | - | Toggle communication screen |
| `shw on/off` | - | Toggle ship warnings |

### 🆘 Safety & Emergencies

| Command | Alias | Description |
|---------|-------|-------------|
| `chop` | - | Chop enemy tethers |
| `crig` | - | Clear rigging |
| `doum` | - | Douse yourself with bucket |
| `dour` | - | Douse room with bucket |
| `rain` | - | Cast rainstorm (extinguish fires) |
| `sres` | - | Ship rescue (use token) |
| `wav[X][Y]` | `wavne5` | Wavecall X direction for Y spaces |

### ⚔️ Seamonster Combat

#### Automatic Mode
| Command | Alias | Description |
|---------|-------|-------------|
| `autosea` | - | Toggle automatic seamonster firing |
| `seaweapon [X]` | `seaweapon ballista` | Set weapon (ballista/onager/thrower) |
| `poophp [X]` | `poophp 80` | Set health threshold for curing (%) |

#### Manual Weapons
| Command | Alias | Description |
|---------|-------|-------------|
| `firb` | - | Fire ballista dart |
| `firf` | - | Fire ballista flare |
| `fird` | - | Fire thrower wardisc |
| `first` | - | Fire onager starshot |
| `firsp` | - | Fire onager spidershot |
| `firo` | - | Fire onager alternating shots |

#### Combat Settings
| Command | Alias | Description |
|---------|-------|-------------|
| `mainth` | - | Auto-maintain hull during combat |
| `maints` | - | Auto-maintain sails during combat |
| `maintn` | - | Don't auto-maintain during combat |

### 📚 Help System

| Command | Description |
|---------|-------------|
| `poopdeck` | Main help screen |
| `poopsail` | Show sailing commands |
| `poopmonster` | Show seamonster commands |
| `poopfull` | Show all commands |

## 🎯 Combat Strategy

### Monster Types & Shot Requirements
- **Legendary** (60 shots): Leviathan, Oceanic Cyclops, Oceanic Hydra
- **Major** (40 shots): Sea Hag, Ketea, Picaroon, Unmarked Warship  
- **Standard** (30 shots): Kashari Raider, Sea Dragon, Pirate Ship, Sea Serpents
- **Minor** (20-25 shots): Shraymor, Sargassum, Megalodon, Angler Fish, Septaceans

### Weapon Types
- **Ballista**: Fast firing, good for consistent damage (darts/flares)
- **Onager**: Heavy damage, alternates starshot/spidershot for effects
- **Thrower**: Balanced option with wardisc ammunition

## 🔧 Configuration

The package automatically saves your preferences including:
- Health sipping threshold
- Preferred weapons
- Maintenance settings
- Auto-fire preferences

Settings are persisted between Mudlet sessions.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is open source. Feel free to modify and redistribute.

## 🐛 Bug Reports

Please report issues on the [GitHub Issues](https://github.com/ronh3/poopDeck/issues) page.

---

*Built with ❤️ for the Achaea community*
