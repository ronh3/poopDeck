# poopDeck OOP Architecture Refactor

## Overview
The poopDeck codebase has been refactored to use a comprehensive Object-Oriented Programming architecture for better maintainability, testability, and extensibility.

## Architecture Layers

### 1. Core Infrastructure (`src/scripts/Core/`)
- **BaseClass.lua**: Foundation class with inheritance, event system (observer pattern)
- **SessionManager.lua**: Singleton coordinator for all systems
- **Initialize.lua**: Bootstraps the entire system in correct order

### 2. Domain Layer (`src/scripts/Domain/`)
Business entities representing game concepts:

- **Ship.lua**: Player's vessel with state management
  - Properties: position, speed, heading, condition
  - Methods: dock(), castOff(), turn(), repair()
  - Events: damageReceived, speedChanged, headingChanged

- **Seamonster.lua**: Monster entities with combat tracking
  - Properties: type, health, debuffs, shot history
  - Methods: receiveShot(), kill(), updateDebuffs()
  - Static data: All monster types and HP values

- **Weapon.lua**: Ship weapons with ammunition management
  - Properties: type, cooldown, ammunition, statistics
  - Methods: load(), fire(), setAlternating()
  - Events: fired, ready, interrupted

### 3. Service Layer (`src/scripts/Services/`)
Business logic orchestration:

- **CombatService.lua**: Manages seamonster combat
  - Auto-fire logic
  - Health monitoring
  - Weapon coordination
  - Combat statistics

- **UIService.lua**: All display functionality
  - Framed message boxes
  - Color schemes
  - Emoji support
  - Status displays

### 4. Legacy Compatibility
- Thin wrapper functions maintain backward compatibility
- Existing triggers/aliases continue working unchanged
- All global variables preserved for compatibility

## Key Design Patterns

### Singleton Pattern
- SessionManager and UIService use singleton pattern
- Ensures single source of truth for state

### Observer Pattern
- All classes extend BaseClass with event support
- Components communicate via events, not direct coupling
- Example: Ship emits "damageReceived", CombatService responds

### Command Pattern
- Commands are objects with execute() methods
- CommandManager handles registration and execution
- Allows for undo/redo capabilities (future)

### Strategy Pattern
- Weapon ammunition strategies (alternating patterns)
- Maintenance strategies (hull/sails/none)

## Benefits of OOP Refactor

### 1. **Encapsulation**
- Ship state contained in Ship object
- Combat logic isolated in CombatService
- No more scattered global variables

### 2. **Testability**
- Mock objects easily created for testing
- Services can be tested in isolation
- Clear interfaces between components

### 3. **Extensibility**
- New weapon types: Just extend Weapon class
- New monster types: Add to Seamonster.TYPES
- New UI themes: Add to UIService.colorSchemes

### 4. **Maintainability**
- Clear separation of concerns
- Consistent patterns throughout
- Self-documenting code structure

## Migration Path

### Phase 1: Core Infrastructure ✅
- Base classes created
- Domain objects implemented
- Service layer built

### Phase 2: Integration (Current)
- SessionManager coordinates all systems
- Legacy wrappers maintain compatibility
- Testing with existing functionality

### Phase 3: Future Enhancements
- NavigationService for pathfinding
- FishingService for fishing automation
- PersistenceService for save/load
- AnalyticsService for performance tracking

## Usage Examples

### Creating a new weapon type:
```lua
-- In Domain/Weapon.lua
poopDeck.domain.Weapon.TYPES.harpoon = {
    name = "Harpoon Launcher",
    reloadTime = 5,
    range = 12,
    ammunition = {
        harpoon = {damage = 2, effect = "tether", loadCommand = "load harpoon"},
    }
}
```

### Adding a new monster:
```lua
-- In Domain/Seamonster.lua
poopDeck.domain.Seamonster.TYPES["a colossal kraken"] = {
    shots = 80, 
    tier = "mythic", 
    xp = 1500
}
```

### Custom UI theme:
```lua
-- In Services/UIService.lua or user config
poopDeck.ui.colorSchemes.ocean = {
    good = {edge = "#0066CC", frame = "#003366", ...},
    bad = {edge = "#CC3300", frame = "#660000", ...}
}
poopDeck.ui:setColorScheme("ocean")
```

## Testing
The OOP structure makes testing much easier:

```lua
-- Example test
local mockShip = poopDeck.domain.Ship({name = "Test Ship"})
local mockMonster = poopDeck.domain.Seamonster("a gargantuan megalodon")
local combat = poopDeck.services.CombatService(mockShip)

combat:engageMonster("a gargantuan megalodon")
assert(combat.state.inCombat == true)
```

## Backward Compatibility
All existing functionality preserved:
- `poopDeck.autoFire()` → Calls `session.combat:fire()`
- `poopDeck.goodEcho()` → Calls `ui:good()`
- Global variables mapped to OOP properties

## Performance Considerations
- Singleton pattern prevents duplicate instances
- Event system uses lightweight observers
- Lazy initialization where appropriate
- Minimal overhead compared to procedural code

## Future Roadmap
1. Complete FishingService implementation
2. Add NavigationService with pathfinding
3. Implement achievement/statistics tracking
4. Add plugin system for user extensions
5. Create web-based configuration UI

## Conclusion
The OOP refactor provides a solid foundation for future development while maintaining full backward compatibility. The architecture is now enterprise-grade, testable, and ready for expansion.