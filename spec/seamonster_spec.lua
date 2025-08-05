-- Load spec helper
require('spec.spec_helper')

-- Copy essential functions from Seamonster_Functions.lua for testing
-- (In a real test, these would be loaded from the installed package)

function poopDeck.toggleCuring(curing)
    if poopDeck.rescue == true then 
        return false -- Don't fire if we're in rescue mode
    end

    -- Safe GMCP access with fallbacks
    local currentHP = tonumber(gmcp.Char.Vitals.hp) or 0
    local maxHP = tonumber(gmcp.Char.Vitals.maxhp) or 1
    local healthPercent = (currentHP / maxHP) * 100
    
    -- Use default health threshold if not configured
    local sipThreshold = poopDeck.config.sipHealthPercent or 75
    local shouldCure = healthPercent < sipThreshold
    
    if curing == "on" or shouldCure then
        send("curing on")
        return false -- Don't allow firing when we need to heal
    else
        send("curing off")
        return true -- Safe to fire
    end
end

function poopDeck.autoFire()
    if poopDeck.firing then return end

    -- Check if we have a weapon selected
    local hasWeapon = false
    for weapon, isWeaponActive in pairs(poopDeck.weapons) do
        if isWeaponActive then
            hasWeapon = true
            break
        end
    end
    
    if not hasWeapon then
        poopDeck.badEcho("NO WEAPON SELECTED! Use 'seaweapon ballista/onager/thrower' first.")
        return
    end

    -- Safe maintenance command - default to hull if not set
    local maintainCmd = poopDeck.maintain and ("maintain " .. poopDeck.maintain) or "maintain hull"
    
    -- Define a table that maps each weapon to its corresponding commands
    local weaponCommands = {
        ballista = {maintainCmd, "load ballista with dart", "fire ballista at seamonster"},
        thrower = {maintainCmd, "load thrower with disc", "fire thrower at seamonster"},
        onager = poopDeck.firedSpider and {maintainCmd, "load onager with starshot", "fire onager at seamonster"} or {maintainCmd, "load onager with spidershot", "fire onager at seamonster"}
    }

    -- Check health before firing
    if not poopDeck.toggleCuring() then
        poopDeck.toggleCuring("on")
        local myMessage = "NEED TO HEAL - Hold FIRE!"
        poopDeck.badEcho(myMessage)
        return
    end

    -- Find active weapon and fire
    for weapon, isWeaponActive in pairs(poopDeck.weapons) do
        if isWeaponActive and weaponCommands[weapon] then
            sendAll(unpack(weaponCommands[weapon]))
            if weapon == "onager" then
                poopDeck.firedSpider = not poopDeck.firedSpider
            end
            break
        end
    end
end

function poopDeck.monsterSurfaced()
    local myMessage = poopDeck.spottedSeamonsterMessages[math.random(#poopDeck.spottedSeamonsterMessages)]
    poopDeck.seamonsterShots = 0
    poopDeck.badEcho(myMessage)
    if poopDeck.mode == "automatic" then 
        poopDeck.autoFire() 
    end
end

function poopDeck.deadSeamonster()
    local myMessage = poopDeck.deadSeamonsterMessages[math.random(#poopDeck.deadSeamonsterMessages)]
    poopDeck.seamonsterShots = 0
    poopDeck.toggleCuring("on")
    poopDeck.goodEcho(myMessage)
    poopDeck.firing = false
    disableTrigger("Ship Moved Lets Try Again")
end

function poopDeck.outOfMonsterRange()
    local myMessage = "OUT OF RANGE!"
    poopDeck.firing = false
    poopDeck.oor = true
    if poopDeck.mode == "automatic" then
        enableTrigger("Ship Moved Lets Try Again")
    end
    poopDeck.toggleCuring("on")
    poopDeck.badEcho(myMessage)
end

function poopDeck.interruptedShot()
    local myMessage = "SHOT INTERRUPTED!"
    local myMessageAuto = "SHOT INTERRUPTED! RETRYING!"
    poopDeck.toggleCuring("on")
    poopDeck.firing = false
    if poopDeck.mode == "automatic" then
        tempTimer(4, [[poopDeck.autoFire()]])
        poopDeck.badEcho(myMessageAuto)
    else
        poopDeck.badEcho(myMessage)
    end
end

describe("poopDeck Seamonster Auto-Fire Logic", function()
    
    -- Mock setup for testing
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.config = poopDeck.config or {}
        poopDeck.weapons = poopDeck.weapons or {}
        poopDeck.command = poopDeck.command or {}
        
        -- Reset state for each test
        poopDeck.firing = false
        poopDeck.oor = false
        poopDeck.mode = "manual"
        poopDeck.autoSeaMonster = false
        poopDeck.firedSpider = false
        poopDeck.maintain = nil
        poopDeck.rescue = false
        
        -- Reset weapons
        poopDeck.weapons.ballista = false
        poopDeck.weapons.onager = false
        poopDeck.weapons.thrower = false
        
        -- Mock GMCP data
        gmcp = gmcp or {}
        gmcp.Char = gmcp.Char or {}
        gmcp.Char.Vitals = gmcp.Char.Vitals or {}
        gmcp.Char.Vitals.hp = "1000"
        gmcp.Char.Vitals.maxhp = "1000"
        
        -- Set default health threshold
        poopDeck.config.sipHealthPercent = 75
        
        -- Mock functions to prevent actual commands being sent
        send = function(cmd) 
            _G.lastSentCommand = cmd
        end
        
        sendAll = function(...)
            _G.lastSentCommands = {...}
        end
        
        poopDeck.badEcho = function(msg)
            _G.lastBadEcho = msg
        end
        
        poopDeck.goodEcho = function(msg)
            _G.lastGoodEcho = msg
        end
        
        enableTrigger = function(name)
            _G.lastEnabledTrigger = name
        end
        
        disableTrigger = function(name)
            _G.lastDisabledTrigger = name
        end
        
        tempTimer = function(delay, code)
            _G.lastTempTimer = {delay = delay, code = code}
        end
        
        -- Clear last actions
        _G.lastSentCommand = nil
        _G.lastSentCommands = nil
        _G.lastBadEcho = nil
        _G.lastGoodEcho = nil
        _G.lastEnabledTrigger = nil
        _G.lastDisabledTrigger = nil
        _G.lastTempTimer = nil
    end)
    
    describe("toggleCuring function", function()
        it("should turn curing on when health is low", function()
            -- Set health to 50% (below 75% threshold)
            gmcp.Char.Vitals.hp = "500"
            gmcp.Char.Vitals.maxhp = "1000"
            
            local result = poopDeck.toggleCuring()
            
            assert.are.equal("curing on", _G.lastSentCommand)
            assert.are.equal(false, result) -- Should return false (don't fire)
        end)
        
        it("should turn curing off when health is high", function()
            -- Set health to 90% (above 75% threshold)
            gmcp.Char.Vitals.hp = "900"
            gmcp.Char.Vitals.maxhp = "1000"
            
            local result = poopDeck.toggleCuring()
            
            assert.are.equal("curing off", _G.lastSentCommand)
            assert.are.equal(true, result) -- Should return true (safe to fire)
        end)
        
        it("should handle missing GMCP data gracefully", function()
            -- Clear GMCP data
            gmcp.Char.Vitals.hp = nil
            gmcp.Char.Vitals.maxhp = nil
            
            local result = poopDeck.toggleCuring()
            
            -- Should default to safe behavior (curing on)
            assert.are.equal("curing on", _G.lastSentCommand)
            assert.are.equal(false, result)
        end)
        
        it("should not fire when in rescue mode", function()
            poopDeck.rescue = true
            
            local result = poopDeck.toggleCuring()
            
            assert.are.equal(false, result)
        end)
    end)
    
    describe("autoFire function", function()
        it("should not fire when already firing", function()
            poopDeck.firing = true
            poopDeck.weapons.ballista = true
            
            poopDeck.autoFire()
            
            assert.is_nil(_G.lastSentCommands)
        end)
        
        it("should show error when no weapon selected", function()
            -- No weapons selected
            
            poopDeck.autoFire()
            
            assert.truthy(_G.lastBadEcho:match("NO WEAPON SELECTED"))
        end)
        
        it("should fire ballista when selected and health is good", function()
            poopDeck.weapons.ballista = true
            gmcp.Char.Vitals.hp = "900"
            gmcp.Char.Vitals.maxhp = "1000"
            
            poopDeck.autoFire()
            
            assert.is_not_nil(_G.lastSentCommands)
            assert.are.equal("maintain hull", _G.lastSentCommands[1])
            assert.are.equal("load ballista with dart", _G.lastSentCommands[2])
            assert.are.equal("fire ballista at seamonster", _G.lastSentCommands[3])
        end)
        
        it("should use custom maintenance when set", function()
            poopDeck.weapons.ballista = true
            poopDeck.maintain = "sails"
            gmcp.Char.Vitals.hp = "900"
            gmcp.Char.Vitals.maxhp = "1000"
            
            poopDeck.autoFire()
            
            assert.are.equal("maintain sails", _G.lastSentCommands[1])
        end)
        
        it("should not fire when health is low", function()
            poopDeck.weapons.ballista = true
            gmcp.Char.Vitals.hp = "500" -- 50% health
            gmcp.Char.Vitals.maxhp = "1000"
            
            poopDeck.autoFire()
            
            assert.truthy(_G.lastBadEcho:match("NEED TO HEAL"))
        end)
        
        it("should alternate onager ammo types", function()
            poopDeck.weapons.onager = true
            poopDeck.firedSpider = false
            gmcp.Char.Vitals.hp = "900"
            gmcp.Char.Vitals.maxhp = "1000"
            
            -- First shot should be spidershot
            poopDeck.autoFire()
            assert.are.equal("load onager with spidershot", _G.lastSentCommands[2])
            
            -- Should toggle firedSpider flag
            assert.are.equal(true, poopDeck.firedSpider)
            
            -- Second shot should be starshot
            poopDeck.firedSpider = true
            poopDeck.autoFire()
            assert.are.equal("load onager with starshot", _G.lastSentCommands[2])
        end)
    end)
    
    describe("Mode switching", function()
        it("should start in manual mode", function()
            assert.are.equal("manual", poopDeck.mode)
            assert.are.equal(false, poopDeck.autoSeaMonster)
        end)
        
        it("should track weapon selection state", function()
            -- Initially no weapons selected
            assert.are.equal(false, poopDeck.weapons.ballista)
            assert.are.equal(false, poopDeck.weapons.onager)
            assert.are.equal(false, poopDeck.weapons.thrower)
            
            -- Select ballista
            poopDeck.weapons.ballista = true
            assert.are.equal(true, poopDeck.weapons.ballista)
        end)
        
        it("should track firing state correctly", function()
            assert.are.equal(false, poopDeck.firing)
            assert.are.equal(false, poopDeck.oor)
            
            poopDeck.firing = true
            assert.are.equal(true, poopDeck.firing)
        end)
    end)
    
    describe("Seamonster event handling", function()
        it("should auto-fire when monster surfaces if in auto mode", function()
            poopDeck.mode = "automatic"
            poopDeck.weapons.ballista = true
            gmcp.Char.Vitals.hp = "900"
            gmcp.Char.Vitals.maxhp = "1000"
            
            poopDeck.monsterSurfaced()
            
            assert.is_not_nil(_G.lastSentCommands)
            assert.are.equal("fire ballista at seamonster", _G.lastSentCommands[3])
        end)
        
        it("should reset state when monster dies", function()
            poopDeck.firing = true
            poopDeck.seamonsterShots = 5
            
            poopDeck.deadSeamonster()
            
            assert.are.equal(false, poopDeck.firing)
            assert.are.equal(0, poopDeck.seamonsterShots)
            assert.are.equal("curing on", _G.lastSentCommand)
            assert.are.equal("Ship Moved Lets Try Again", _G.lastDisabledTrigger)
        end)
        
        it("should handle out of range correctly", function()
            poopDeck.mode = "automatic"
            
            poopDeck.outOfMonsterRange()
            
            assert.are.equal(false, poopDeck.firing)
            assert.are.equal(true, poopDeck.oor)
            assert.are.equal("Ship Moved Lets Try Again", _G.lastEnabledTrigger)
            assert.truthy(_G.lastBadEcho:match("OUT OF RANGE"))
        end)
        
        it("should retry after interrupted shot in auto mode", function()
            poopDeck.mode = "automatic"
            
            poopDeck.interruptedShot()
            
            assert.are.equal(false, poopDeck.firing)
            assert.is_not_nil(_G.lastTempTimer)
            assert.are.equal(4, _G.lastTempTimer.delay)
            assert.truthy(_G.lastBadEcho:match("RETRYING"))
        end)
    end)
end)