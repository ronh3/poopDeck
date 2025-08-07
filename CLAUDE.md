# CLAUDE.md - Development Context for poopDeck

## Project Overview

**poopDeck** is a comprehensive Achaea seafaring automation package for the Mudlet MUD client. This document contains all context needed to resume development.

### Current Status: v2.0.0 - Complete System Deployed

**Released:** January 2024  
**GitHub:** https://github.com/ronh3/poopDeck  
**Latest Tag:** v2.0.0  
**Package:** poopDeck-v2.0.0.mpackage (automated via GitHub Actions)

## Core System Architecture

### Object-Oriented Design
- **BaseClass Pattern**: All components inherit from `src/scripts/Core/BaseClass.lua`
- **Service Layer**: Modular services in `src/scripts/Services/`
- **Domain Objects**: Game entities in `src/scripts/Domain/`
- **Session Manager**: Central coordinator in `src/scripts/Core/SessionManager.lua`

### Key Services
1. **FishingService** - Auto-resume fishing with bait management
2. **CombatService** - Seamonster auto-fire with health safety
3. **StatusWindowService** - Multi-window display system
4. **NotificationService** - 20-minute seamonster spawn timers
5. **PromptService** - Spam reduction and message throttling
6. **ErrorHandlingService** - Automatic recovery with multiple strategies

## Primary User Requirements (Addressed)

### 1. Auto-Resume Fishing (CRITICAL)
**User Issue:** "if a fish gets away for whatever reason, it does not automatically start fishing again"

**Solution:** `FishingService` with comprehensive auto-resume logic
- Location: `src/scripts/Services/FishingService.lua`
- Triggers: `src/triggers/Fishing/Fish_Escape.lua`
- Features: Configurable retry attempts, smart delays, persistent statistics
- Commands: `fish`, `fishbait <type>`, `fishsource <location>`

### 2. Full OOP Architecture 
**User Requirement:** "I would rather be over-engineered than under"

**Solution:** Complete object-oriented system
- BaseClass inheritance pattern for all components
- Service layer with dependency injection
- Event-driven architecture with observer patterns
- Consistent error handling across all services

### 3. FramedBox Capitalization Fix (RESOLVED)
**User Issue:** `<[string "Script: Utilities"]:244: attempt to call field 'FramedBox' (a nil value)>`

**Solution:** Fixed in `src/scripts/Utilities.lua:239`
- Changed `poopDeck.FramedBox` → `poopDeck.framedBox`
- Changed `poopDeck.SmallFramedBox` → `poopDeck.smallFramedBox`

### 4. Command Consistency
**User Requirement:** "aliases...are a touch generic, should instead start with poop"

**Solution:** All commands use "poop" prefix pattern
- Window commands: `poopwindows`, `poopcombat`, `poopfishing`, `poopship`, `poopalerts`
- Settings: `poophp`, `poopquiet`, `poopdebug`
- Help system: `poopsail`, `poopmonster`, `poopfish`, `poopfull`

## File Structure & Key Locations

### Core System Files
```
src/scripts/Core/
├── Initialize.lua          # System bootstrap
├── BaseClass.lua          # Inheritance pattern
├── SessionManager.lua     # Service coordination
├── SafetyWrappers.lua     # Error protection
└── CommandService.lua     # Command routing
```

### Services (Business Logic)
```
src/scripts/Services/
├── FishingService.lua         # Auto-resume fishing (PRIMARY)
├── CombatService.lua          # Seamonster auto-fire
├── StatusWindowService.lua    # Multi-window system
├── NotificationService.lua    # Spawn timers
├── PromptService.lua          # Spam reduction
├── ErrorHandlingService.lua   # Recovery system
├── MonsterTracker.lua         # Combat tracking
└── UIService.lua              # User interface
```

### Domain Objects
```
src/scripts/Domain/
├── Fishing.lua      # Fishing entity management
├── Seamonster.lua   # Monster state tracking
├── Ship.lua         # Ship operations
└── Weapon.lua       # Weapon management
```

### User Interface
```
src/aliases/
├── Fishing/         # 11 fishing commands + aliases.json
├── Sailing/         # 16 ship navigation commands + aliases.json
├── Seamonsters/     # Combat and settings commands + aliases.json
└── Help/            # Help system commands + aliases.json

src/triggers/
├── Fishing/         # Fish events, auto-resume logic
├── Sailing/         # Ship state changes
├── Seamonsters/     # Combat events, weapon firing
└── Utility/         # Prompt parsing, spam reduction
```

### Configuration & Data
- **mfile** - Mudlet package metadata (version 2.0.0)
- **VERSION** - Current version (2.0.0)
- **User Config** - Saved to Mudlet profile directory as JSON

## Testing Infrastructure

### Comprehensive Test Suite (13 Files)
```
spec/
├── spec_helper.lua                        # Test utilities and mocks
├── fishing_spec.lua                      # Core fishing system
├── auto_resume_spec.lua                  # Fish escape scenarios (CRITICAL)
├── seamonster_spec.lua                   # Combat automation
├── command_integration_spec.lua          # User command interface
├── configuration_persistence_spec.lua    # Settings management
├── navigation_ship_management_spec.lua   # Ship operations
├── status_window_service_spec.lua        # Multi-window system
├── notification_system_spec.lua          # Spawn timers
├── prompt_spam_reduction_spec.lua        # Message filtering
├── error_handling_service_spec.lua       # Recovery systems
├── core_architecture_spec.lua            # OOP patterns
└── session_manager_integration_spec.lua  # Service coordination
```

### Test Commands
```bash
# Run all tests
./run-all-tests.sh

# Run specific test
busted spec/fishing_spec.lua
busted spec/auto_resume_spec.lua  # Critical user feature

# Local testing
./test-local.sh
```

## Development Workflows

### Adding New Features
1. **Create Domain Object** (if needed) in `src/scripts/Domain/`
2. **Create Service** in `src/scripts/Services/` extending BaseClass
3. **Add Commands** in appropriate `src/aliases/` directory with `aliases.json`
4. **Add Triggers** in `src/triggers/` with `triggers.json`
5. **Write Tests** in `spec/` following existing patterns
6. **Update Documentation** in relevant `.md` files

### Testing Strategy
- **Unit Tests**: Individual service functionality
- **Integration Tests**: Cross-service communication
- **Mock System**: Game command simulation in `spec/spec_helper.lua`
- **Edge Cases**: Error conditions and recovery scenarios

### Release Process
1. **Update VERSION** file
2. **Update CHANGELOG.md** with changes
3. **Run Tests**: `./run-all-tests.sh`
4. **Commit Changes**: Follow semantic commit messages
5. **Tag Release**: `git tag -a vX.Y.Z -m "Release message"`
6. **Push**: `git push origin main && git push origin vX.Y.Z`
7. **GitHub Actions**: Automatically creates .mpackage and release

## Critical Implementation Details

### Auto-Resume Fishing Logic
**Location:** `src/scripts/Services/FishingService.lua:handleFishEscaped()`

```lua
function FishingService:handleFishEscaped(data)
    if not data.shouldRestart or not self.autoRestart then return end
    
    if self.retryCount >= self.maxRetries then
        poopDeck.badEcho("Max fishing retries reached. Stopping fishing.")
        self:stopFishing()
        return
    end
    
    self.retryCount = self.retryCount + 1
    poopDeck.badEcho("Fish escaped. Auto-restarting... (Attempt " .. self.retryCount .. "/" .. self.maxRetries .. ")")
    
    tempTimer(5, function()
        self:executeCastSequence()
    end)
end
```

### Fishing Configuration System
**Flexible Bait Management:**
- **Sources**: tank, inventory, fishbucket
- **Bait Types**: ANY string (bass, shrimp, worms, minnow, etc.)
- **Cast Distance**: short, medium, long (NOT "hooks" - user correction)
- **Persistence**: Saved between sessions via JSON

**User Commands:**
- `fish [bait] [distance]` - Start with optional parameters
- `fishbait <type>` - Set default bait
- `fishsource <location>` - Set bait source
- `fishcast <distance>` - Set cast distance
- `fishrestart` - Toggle auto-restart

### Error Handling Philosophy
**Recovery Strategies:**
1. **Immediate Retry** - For transient failures
2. **Service Restart** - For component failures  
3. **Configuration Reset** - For corrupted state
4. **User Notification** - For manual intervention needed

**Implementation:** All services use `pcall/xpcall` with ErrorHandlingService coordination

### Status Window System
**Four Specialized Windows:**
- **Combat**: Weapon firing, health status, monster tracking
- **Ship**: Navigation, maintenance, emergency operations
- **Fishing**: Cast attempts, catches, escapes, statistics
- **Alerts**: Notifications, spawn timers, system messages

**Features:**
- Auto-show/hide based on activity
- Message history with line limits
- Draggable, resizable with position memory
- Color-coded message types

## Known Issues & Future Enhancements

### Current Limitations
1. **Single Profile Support** - Configuration per Mudlet profile only
2. **Manual Bait Acquisition** - User must ensure bait availability
3. **Fixed Timer Intervals** - Seamonster cycle hardcoded to 20 minutes
4. **English Only** - No internationalization support

### Planned Features (User Requests)
1. **Advanced Fishing Analytics** - Optimal bait/location recommendations
2. **Fleet Management** - Multi-ship coordination
3. **Trade Route Automation** - Cargo run automation
4. **Weather Integration** - Strategy adjustments based on conditions

### Performance Considerations
- **Memory Management**: Services properly cleanup timers/events
- **Event Throttling**: Message processing with rate limits
- **Statistics Storage**: Efficient JSON serialization for persistence
- **Window Management**: Lazy loading and cleanup of UI elements

## Essential Commands for Development

### System Status
```lua
# Service status
lua poopDeck.sessionManager:getStatus()

# Individual services
lua poopDeck.sessionManager:getFishingService()
lua poopDeck.sessionManager:getCombatService()

# Configuration
lua poopDeck.sessionManager:getFishingService():getConfiguration()
```

### Debugging
```lua
# Enable debug mode
poopdebug

# View error history
lua poopDeck.sessionManager:getErrorHandlingService():getRecentErrors(10)

# Manual service restart
lua poopDeck.sessionManager:restart()

# Test fishing auto-resume
lua poopDeck.sessionManager:getFishingService():handleFishEscaped({shouldRestart = true, reason = "test"})
```

### Build & Package
```bash
# Local package build
./build-package.sh

# Test package structure
unzip -l poopDeck-v2.0.0.mpackage

# GitHub Actions trigger
git tag vX.Y.Z && git push origin vX.Y.Z
```

## User Feedback Integration

### Primary User Concerns (Addressed)
1. ✅ **Fish Auto-Resume** - "if a fish gets away...it does not automatically start fishing again"
2. ✅ **Over-Engineering** - "I would rather be over-engineered than under"
3. ✅ **Error Handling** - "Error handling is very important"
4. ✅ **Persistent Statistics** - "Will fishstats save between sessions? That would be neat"
5. ✅ **Terminology Correction** - "fishing hook isn't actually about hooks, but cast distance"
6. ✅ **Flexible Bait** - "can we allow the value to be a wildcard?"
7. ✅ **Command Consistency** - "should instead start with poop"

### Testing Verification Points
- **Fish Escape Scenarios**: `spec/auto_resume_spec.lua` - Tests all escape conditions
- **Retry Logic**: Configurable attempts with exponential backoff
- **Bait Flexibility**: Supports any bait string from any source
- **Statistics Persistence**: JSON serialization across sessions
- **Command Integration**: All "poop" prefixed commands tested
- **Error Recovery**: Comprehensive failure scenario testing

## Development Environment Setup

### Requirements
- **Mudlet 4.0+** for package testing
- **Lua 5.3+** for local development
- **Busted** for test framework (`luarocks install busted`)
- **Git** for version control

### Local Development
1. Clone repository
2. Run `./test-local.sh` for immediate feedback
3. Use `./run-all-tests.sh` for comprehensive testing
4. Test in Mudlet by installing via package manager

### Package Testing
1. Build: `./build-package.sh`
2. Install in clean Mudlet profile
3. Verify: `poopsail` (shows help system)
4. Test core functionality: `fish`, `autosea`, `poopwindows`

---

**Note:** This document should be updated with each major feature addition or architectural change. The auto-resume fishing functionality was the primary user-requested feature and should be preserved and enhanced in future versions.

**Next Development Session:** Use this document to understand the complete system architecture, user requirements, and implementation details. Focus on the FishingService for any fishing-related features, and follow the established OOP patterns for new components.