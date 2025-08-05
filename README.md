# 🚢 poopDeck - Achaea Seafaring Automation

A comprehensive automation package for seafaring activities in the text-based MMORPG **Achaea**. Designed for the Mudlet MUD client, poopDeck streamlines ship navigation, seamonster combat, and fishing operations.

> *Yes, I chose the name because I have the maturity of a thirteen year old.* 😄

## ✨ Features

### 🧭 **Ship Navigation & Management**
- **Automated Movement**: Docking, casting off, rowing, turning, speed control
- **Ship Maintenance**: Hull and sail repairs, anchor/plank operations  
- **Emergency Response**: Chopping ropes, clearing rigging, fire suppression

### ⚔️ **Seamonster Combat System**
- **Automatic Mode**: Fully automated seamonster hunting with intelligent weapon selection
- **Manual Mode**: Individual weapon firing commands with shot tracking
- **Combat Intelligence**: 
  - Tracks different monster types (20-60 shots required)
  - Alternates ammunition types for optimal damage
  - Manages health/curing during combat
  - Out-of-range detection and repositioning

### 🎣 **Fishing Automation**
- Automated fishing with line management
- Fish sizing and response triggers
- Fisher interaction management

### 🎨 **Smart User Interface**
- Colored, framed message boxes for different event types
- Real-time status indicators in prompt area
- Comprehensive in-game help system with command reference

## 🚀 Installation

1. Download the latest `.mpackage` file from [Releases](https://github.com/ronh3/poopDeck/releases)
2. In Mudlet: **Package Manager → Install**
3. Select the downloaded `.mpackage` file
4. Type `poopdeck` to get started!

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
