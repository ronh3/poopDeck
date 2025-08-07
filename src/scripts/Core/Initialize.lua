-- poopDeck Initialization Script
-- Loads all OOP components in the correct order

-- Preserve existing namespace if it exists
poopDeck = poopDeck or {}

-- Version information
poopDeck.version = "2.0-OOP"
poopDeck.initialized = false

-- Initialize core namespaces
poopDeck.core = poopDeck.core or {}
poopDeck.domain = poopDeck.domain or {}
poopDeck.services = poopDeck.services or {}
poopDeck.command = poopDeck.command or {}

-- Load order is important!
local loadOrder = {
    -- 1. Core infrastructure
    "Core/BaseClass",
    
    -- 2. Domain objects
    "Domain/Ship",
    "Domain/Seamonster", 
    "Domain/Weapon",
    
    -- 3. Service layer
    "Services/CombatService",
    
    -- 4. Session management
    "Core/SessionManager",
    
    -- 5. UI utilities (keep existing)
    "Utilities",
    
    -- 6. Command system (keep existing OOP commands)
    "Sailing/Sailing_Commands",
    "Seamonsters/Seamonster_Functions",
    "Help/Help_Functions",
    "Help/poopDeck_Help"
}

-- Function to safely load a script
local function loadScript(scriptName)
    local scriptPath = "poopDeck.scripts." .. scriptName:gsub("/", ".")
    local success, error = pcall(function()
        -- In Mudlet, scripts are typically already loaded
        -- This is more for documentation of load order
        if poopDeck.debug then
            echo(string.format("[poopDeck] Loading: %s\n", scriptName))
        end
    end)
    
    if not success and poopDeck.debug then
        echo(string.format("[poopDeck] ERROR loading %s: %s\n", scriptName, error))
    end
    
    return success
end

-- Initialize poopDeck
function poopDeck.initialize()
    if poopDeck.initialized then
        return true
    end
    
    echo("[poopDeck] Initializing version " .. poopDeck.version .. "\n")
    
    -- Load all scripts in order
    local allLoaded = true
    for _, script in ipairs(loadOrder) do
        if not loadScript(script) then
            allLoaded = false
        end
    end
    
    if allLoaded then
        poopDeck.initialized = true
        
        -- Initialize the session manager (singleton)
        if not poopDeck.session then
            poopDeck.session = poopDeck.core.SessionManager.getInstance()
        end
        
        -- Load saved configuration
        if poopDeck.session then
            poopDeck.session:loadConfig()
        end
        
        echo("[poopDeck] Initialization complete!\n")
        echo("[poopDeck] Type 'poopdeck' for help.\n")
    else
        echo("[poopDeck] Initialization failed - some components could not be loaded.\n")
    end
    
    return poopDeck.initialized
end

-- Auto-initialize on load
poopDeck.initialize()

-- Export legacy global variables for backward compatibility
poopDeck.autoSeaMonster = false
poopDeck.maintaining = false  
poopDeck.firing = false
poopDeck.oor = false
poopDeck.mode = "manual"
poopDeck.firedSpider = false
poopDeck.seamonsterShots = 0

-- Legacy weapon tracking (now handled by domain objects)
poopDeck.weapons = poopDeck.weapons or {
    ballista = false,
    onager = false,
    thrower = false
}