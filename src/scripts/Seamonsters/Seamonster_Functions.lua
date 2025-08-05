--Seamonster Tracking and callouts

--#########################################
-- Seamonster Commands (poopDeck.seamonster.command)
--#########################################
poopDeck.seamonster = poopDeck.seamonster or {}
poopDeck.seamonster.command = {}

--Seamonster table to know total shots needed to kill.
poopDeck.promptCount = 0
poopDeck.seamonsters = {
    ["a legendary leviathan"] = 60,
    ["a hulking oceanic cyclops"] = 60,
    ["a towering oceanic hydra"] = 60,
    ["a sea hag"] = 40,
    ["a monstrous ketea"] = 40,
    ["a monstrous picaroon"] = 40,
    ["an unmarked warship"] = 40,
    ["a red-sailed Kashari raider"]= 30,
    ["a furious sea dragon"] = 30,
    ["a pirate ship"] = 30,
    ["a trio of raging sea serpents"] = 30,
    ["a raging shraymor"] = 25,
    ["a mass of sargassum"] = 25,
    ["a gargantuan megalodon"] = 25,
    ["a gargantuan angler fish"] = 25,
    ["a mudback septacean"] = 20,
    ["a flying sheilei"] = 20,
    ["a foam-wreathed sea serpent"] = 20,
    ["a red-faced septacean"] = 20
}

--Table of dead seamonster messages
poopDeck.deadSeamonsterMessages = {
    "🚢🐉 Triumphant Victory! 🐉🚢",
    "⚓🌊 Monster Subdued! 🌊⚓",
    "🔱🌊 Beast Beneath Conquered! 🌊🔱",
    "⛵🌊 Monstrous Foe Defeated! 🌊⛵",
    "🗡️🌊 Siren of the Deep Quelled! 🌊🗡️",
    "⚔️🌊 Sea's Terror Defeated! 🌊⚔️",
    "🦈🌊 Jaws of the Abyss Conquered! 🌊🦈",
    "🚢🌊 Monstrous Victory Achieved! 🌊🚢",
    "🌟🌊 Tidal Terror Tamed! 🌊🌟",
    "🗺️🌊 Legends Born of Victory! 🌊🗺️"
}

--Table of spawned seamonster messages
poopDeck.spottedSeamonsterMessages = {
    "🐉🌊 Rising Behemoth! 🌊🐉",
    "🔍🌊 Titan of the Deep Spotted! 🌊🔍",
    "🐲🌊 Majestic Leviathan Ascendant! 🌊🐲",
    "🦑🌊 Monstrous Anomaly Unveiled! 🌊🦑",
    "🌌🌊 Awakening of the Abyssal Colossus! 🌊🌌",
    "🌊🌊 Ripple of Giants! 🌊🌊",
    "🌟🌊 Deep's Enigma Revealed! 🌊🌟",
    "🐙🌊 Emergence of the Watery Behemoth! 🌊🐙",
    "🔮🌊 Ocean's Secret Unveiled! 🌊🔮",
    "🐍🌊 Serpentine Giant Surfaces! 🌊🐍"
}


--Shot counter - Could probably make this cleaner, not sure exactly how though.
function poopDeck.countShots(target)
    poopDeck.seamonsterShots = poopDeck.seamonsterShots or 0
    poopDeck.seamonsterShots = poopDeck.seamonsterShots + 1
    local toKill = poopDeck.seamonsters[target] - poopDeck.seamonsterShots
    local myMessage = string.format("%d shots taken, %d remain.", poopDeck.seamonsterShots, toKill)
    poopDeck.shotEcho(myMessage)
end

--Seamonster got spidershotted and is attacking slower
function poopDeck.monsterSpidershot()
    local myMessage = "Seamonster Attack Slowed!"
    poopDeck.smallGoodEcho(myMessage)
end

--Seamonster got starshotted and is attacking lighter
function poopDeck.monsterStarshot()
    local myMessage = "Seamonster Attack Weakened!"
    poopDeck.smallGoodEcho(myMessage)
end

--Start shooting if a monster surfaced if set to auto
--For auto and manual, display a warning
function poopDeck.monsterSurfaced()
    local myMessage = poopDeck.spottedSeamonsterMessages[math.random(#poopDeck.spottedSeamonsterMessages)]
    local timerName = os.date("monster%H%M%S")
    echo(timerName)
    poopDeck.seamonsterShots = 0
    poopDeck.badEcho(myMessage)
    if poopDeck.mode == "automatic" then poopDeck.autoFire() end
    timerName = tempTimer(poopDeck.constants.FIVE_MINUTES, [[poopDeck.goodEcho("Monster in 5 minutes")]])
    timerName2 = tempTimer(poopDeck.constants.ONE_MINUTE, [[poopDeck.goodEcho("Monster in 1 minute")]])
    timerName3 = tempTimer(poopDeck.constants.NEW_MONSTER, [[poopDeck.badEcho("Reel in, it's monster time!")]])
end

--Once a seamonster is killed, this will set the seamonster counter back to zero, give us a nice message that it's dead
--then turn curing back on because why not. Curing on is good. Off is bad, unless it stops us from doing nifty things.
--Like shooting seamonsters. And looking fly.
function poopDeck.deadSeamonster()
    local myMessage = poopDeck.deadSeamonsterMessages[math.random(#poopDeck.deadSeamonsterMessages)]
    poopDeck.seamonsterShots = 0
    poopDeck.toggleCuring("on")
    poopDeck.goodEcho(myMessage)
    poopDeck.firing = false
    disableTrigger("Ship Moved Lets Try Again")
end


-- Auto Fire Toggle Command
poopDeck.seamonster.command.AutoFireToggleCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.seamonster.command.AutoFireToggleCommand:new()
    local instance = poopDeck.command.Command:new(
        "autoFireToggle",
        nil,
        "autosea",
        "Toggle automatic seamonster firing on/off",
        "Seamonsters"
    )
    setmetatable(instance, {__index = poopDeck.seamonster.command.AutoFireToggleCommand})
    return instance
end

function poopDeck.seamonster.command.AutoFireToggleCommand:execute()
    local myMessage
    if poopDeck.autoSeaMonster then
        myMessage = "AUTO FIRE OFF"
        poopDeck.mode = "manual"
        poopDeck.badEcho(myMessage)
        poopDeck.autoSeaMonster = false
    else
        myMessage = "AUTO FIRE ON"
        poopDeck.mode = "automatic"
        poopDeck.goodEcho(myMessage)
        poopDeck.autoSeaMonster = true
    end
end

local autoFireToggleCommand = poopDeck.seamonster.command.AutoFireToggleCommand:new()
poopDeck.command.manager:addCommand("autoFireToggle", autoFireToggleCommand)

--Automatic Items
--Legacy function - kept for backward compatibility
function poopDeck.setSeamonsterAutoFire()
    poopDeck.command.manager:executeCommand("autoFireToggle")
end

-- Set Weapon Command
poopDeck.seamonster.command.SetWeaponCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.seamonster.command.SetWeaponCommand:new()
    local instance = poopDeck.command.Command:new(
        "setWeapon",
        nil,
        "seaweapon X",
        "Set weapon for automatic firing (ballista/b, onager/o, thrower/t)",
        "Seamonsters"
    )
    setmetatable(instance, {__index = poopDeck.seamonster.command.SetWeaponCommand})
    return instance
end

function poopDeck.seamonster.command.SetWeaponCommand:execute(boomstick)
    local weaponMessages = {
        ballista = "UNLEASH THE DARTS! - BALLISTA",
        b = "UNLEASH THE DARTS! - BALLISTA",
        onager = "ENGAGE THE MIGHTY SLINGSHOT - ONAGER",
        o = "ENGAGE THE MIGHTY SLINGSHOT - ONAGER",
        thrower = "SEND HAVOC SPINNING! - THROWER",
        t = "SEND HAVOC SPINNING! - THROWER"
    }

    -- Reset all weapon flags
    poopDeck.weapons.ballista = false
    poopDeck.weapons.onager = false
    poopDeck.weapons.thrower = false

    -- Map short forms to full names for flag setting
    local weaponMap = {
        b = "ballista",
        o = "onager", 
        t = "thrower"
    }
    
    local weaponName = weaponMap[boomstick] or boomstick
    
    -- If the weapon is recognized, set its flag to true and get its message
    if weaponMessages[boomstick] then
        poopDeck.weapons[weaponName] = true
        poopDeck.goodEcho(weaponMessages[boomstick])
    else
        poopDeck.badEcho("NO WEAPON SELECTED!")
    end
end

local setWeaponCommand = poopDeck.seamonster.command.SetWeaponCommand:new()
poopDeck.command.manager:addCommand("setWeapon", setWeaponCommand)

--Legacy function - kept for backward compatibility
function poopDeck.setWeapon(boomstick)
    poopDeck.command.manager:executeCommand("setWeapon", boomstick)
end

--Tracks that you have started firing, so that triggers can be disabled/won't interrupt.
function poopDeck.seaFiring()
    poopDeck.toggleCuring(false)
    poopDeck.firing = true
    poopDeck.oor = false
    disableTrigger("Ship Moved Lets Try Again")
end

--Automatically fires your set weapon. Will first check for which weapon you're supposed to be firing.
--For ballista and thrower, it's just going to dart and wardisc the monster.
--For the onager, it will rotate between starshot and spidershot.
function poopDeck.autoFire()
    if poopDeck.firing then return end

    -- Define a table that maps each weapon to its corresponding commands
    local weaponCommands = {
        ballista = {"maintain " .. poopDeck.maintain, "load ballista with dart", "fire ballista at seamonster"},
        thrower = {"maintain " .. poopDeck.maintain, "load thrower with disc", "fire thrower at seamonster"},
        onager = poopDeck.firedSpider and {"maintain " .. poopDeck.maintain, "load onager with starshot", "fire onager at seamonster"} or {"maintain " .. poopDeck.maintain, "load onager with spidershot", "fire onager at seamonster"}
    }

    if poopDeck.toggleCuring() then
        for weapon, isWeaponActive in pairs(poopDeck.weapons) do
            if isWeaponActive and weaponCommands[weapon] then
                sendAll(unpack(weaponCommands[weapon]))
                if weapon == "onager" then
                    poopDeck.firedSpider = not poopDeck.firedSpider
                end
                break
            end
        end
    else
        poopDeck.toggleCuring("on")
        local myMessage = "NEED TO HEAL - HOLD FIRE!"
        poopDeck.badEcho(myMessage)
    end
end

-- Manual Fire Command - Base class for all manual firing
poopDeck.seamonster.command.ManualFireCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.seamonster.command.ManualFireCommand:new(name, ammo, weapon, alias, helpText)
    local instance = poopDeck.command.Command:new(name, nil, alias, helpText, "Seamonsters")
    setmetatable(instance, {__index = poopDeck.seamonster.command.ManualFireCommand})
    instance.ammo = ammo
    instance.weapon = weapon
    return instance
end

function poopDeck.seamonster.command.ManualFireCommand:execute()
    if poopDeck.firing == true then return end
    if poopDeck.toggleCuring() then
        self:fireWeapon()
    else
        poopDeck.toggleCuring("on")
        local myMessage = "NEED TO HEAL - HOLD FIRE!"
        poopDeck.badEcho(myMessage)
    end
end

function poopDeck.seamonster.command.ManualFireCommand:fireWeapon()
    local maintainCmd = poopDeck.maintain and ("maintain " .. poopDeck.maintain) or "maintain hull"
    local commands = {
        maintainCmd,
        "load " .. self.weapon .. " with " .. self.ammo,
        "fire " .. self.weapon .. " at seamonster"
    }
    sendAll(unpack(commands))
end

-- Ballista Dart Command
local ballistaDartCommand = poopDeck.seamonster.command.ManualFireCommand:new(
    "ballistaDart", "dart", "ballista", "firb", "Fire a dart from ballista at seamonster"
)
poopDeck.command.manager:addCommand("ballistaDart", ballistaDartCommand)

-- Ballista Flare Command  
local ballistaFlareCommand = poopDeck.seamonster.command.ManualFireCommand:new(
    "ballistaFlare", "flare", "ballista", "firf", "Fire a flare from ballista at seamonster"
)
poopDeck.command.manager:addCommand("ballistaFlare", ballistaFlareCommand)

-- Thrower Disc Command
local throwerDiscCommand = poopDeck.seamonster.command.ManualFireCommand:new(
    "throwerDisc", "disc", "thrower", "fird", "Fire a wardisc from thrower at seamonster"
)
poopDeck.command.manager:addCommand("throwerDisc", throwerDiscCommand)

-- Onager Starshot Command
local onagerStarshotCommand = poopDeck.seamonster.command.ManualFireCommand:new(
    "onagerStarshot", "starshot", "onager", "first", "Fire a starshot from onager at seamonster"
)
poopDeck.command.manager:addCommand("onagerStarshot", onagerStarshotCommand)

-- Onager Spidershot Command
local onagerSpidershotCommand = poopDeck.seamonster.command.ManualFireCommand:new(
    "onagerSpidershot", "spidershot", "onager", "firsp", "Fire a spidershot from onager at seamonster"
)
poopDeck.command.manager:addCommand("onagerSpidershot", onagerSpidershotCommand)

-- Onager Alternating Command (special case)
poopDeck.seamonster.command.OnagerAlternatingCommand = setmetatable({}, {__index = poopDeck.seamonster.command.ManualFireCommand})

function poopDeck.seamonster.command.OnagerAlternatingCommand:new()
    local instance = poopDeck.seamonster.command.ManualFireCommand:new(
        "onagerAlternating", nil, "onager", "firo", "Fire alternating starshot/spidershot from onager"
    )
    setmetatable(instance, {__index = poopDeck.seamonster.command.OnagerAlternatingCommand})
    return instance
end

function poopDeck.seamonster.command.OnagerAlternatingCommand:fireWeapon()
    local ammo = poopDeck.firedSpider and "starshot" or "spidershot"
    local maintainCmd = poopDeck.maintain and ("maintain " .. poopDeck.maintain) or "maintain hull"
    local commands = {
        maintainCmd,
        "load onager with " .. ammo,
        "fire onager at seamonster"
    }
    sendAll(unpack(commands))
    poopDeck.firedSpider = not poopDeck.firedSpider
end

local onagerAlternatingCommand = poopDeck.seamonster.command.OnagerAlternatingCommand:new()
poopDeck.command.manager:addCommand("onagerAlternating", onagerAlternatingCommand)

--Legacy function - kept for backward compatibility
function poopDeck.seaFire(ammo)
    local commandMap = {
        b = "ballistaDart",
        bf = "ballistaFlare", 
        d = "throwerDisc",
        st = "onagerStarshot",
        sp = "onagerSpidershot",
        o = "onagerAlternating"
    }
    
    local commandName = commandMap[ammo]
    if commandName then
        poopDeck.command.manager:executeCommand(commandName)
    else
        print("Unknown ammo type: " .. ammo)
    end
end

--Fired a weapon. Setting a temptimer for 4s to fire again if automatic mode is engaged.
--Otherwise, setting a 4s temptimer to let the user know they can shoot again.
function poopDeck.seaFired()
    local myMessage = "READY TO FIRE!"
    poopDeck.toggleCuring("on")
    poopDeck.firing = false
    poopDeck.oor = false
    if poopDeck.mode == "automatic" then
        tempTimer(4, [[poopDeck.autoFire()]])
    else
        tempTimer(4, [[poopDeck.goodEcho("READY TO FIRE!")]])
    end
end

--Toggle to turn curing on/off automatically while firing.
function poopDeck.toggleCuring(curing)
    if poopDeck.rescue == true then return end

    local shouldCure = (tonumber(gmcp.Char.Vitals.hp) / tonumber(gmcp.Char.Vitals.maxhp) * 100) < poopDeck.config.sipHealthPercent
    if curing == "on" or shouldCure then
        send("curing on")
        return false
    else
        send("curing off")
        return true
    end
end

--Ship Vital checker. Do something with this later
function poopDeck.shipVitals()
    return
end

--If we were out of range, turn curing back on. 
--Then turn on the trigger to attempt firing each time the ship moves.
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

--Will pop a notification that your shot got interrupted.
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

--Displays a thingie letting you know that you're shooting at something
function poopDeck.parsePrompt()
    local firstMessage = true
    if poopDeck.maintain then
        echo("\n")
        local myMessage = "MAINTAINING " .. poopDeck.maintain
        poopDeck.maintainEcho(myMessage)
        firstMessage = false
    end
    if poopDeck.firing then
        local myMessage = "FIRING!"
        if firstMessage then echo("\n") end
        poopDeck.fireEcho(myMessage)
        firstMessage = false
    end
    if poopDeck.oor then
      if poopDeck.promptCount < 5 then
        if firstMessage then echo("\n") end
        local myMessage = "OUT OF RANGE!"
        poopDeck.rangeEcho(myMessage)
        firstMessage = false
      else
        poopDeck.promptCount = 0
        poopDeck.oor = nil
      end
    end
    if not firstMessage then echo("\n") end
    poopDeck.promptCount = poopDeck.promptCount + 1
end

-- Set Maintain Command
poopDeck.seamonster.command.SetMaintainCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.seamonster.command.SetMaintainCommand:new()
    local instance = poopDeck.command.Command:new(
        "setMaintain",
        nil,
        "maintain(h|s|n)",
        "Set what to maintain during combat (hull/sails/none)",
        "Seamonsters"
    )
    setmetatable(instance, {__index = poopDeck.seamonster.command.SetMaintainCommand})
    return instance
end

function poopDeck.seamonster.command.SetMaintainCommand:execute(maintain)
    local myMessage
    if maintain == "h" then
        myMessage = "MAINTAINING HULL"
        poopDeck.maintain = "hull"
    elseif maintain == "s" then
        myMessage = "MAINTAINING SAILS"
        poopDeck.maintain = "sails"
    elseif maintain == "n" then
        myMessage = "MAINTAINING NONE"
        poopDeck.maintain = nil
    else
        myMessage = "MAINTAINING NONE"
        poopDeck.maintain = nil
    end
    poopDeck.goodEcho(myMessage)
end

local setMaintainCommand = poopDeck.seamonster.command.SetMaintainCommand:new()
poopDeck.command.manager:addCommand("setMaintain", setMaintainCommand)

-- Set Health Command
poopDeck.seamonster.command.SetHealthCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.seamonster.command.SetHealthCommand:new()
    local instance = poopDeck.command.Command:new(
        "setHealth",
        nil,
        "poophp X",
        "Set HP percentage threshold for curing (default 75%)",
        "Seamonsters"
    )
    setmetatable(instance, {__index = poopDeck.seamonster.command.SetHealthCommand})
    return instance
end

function poopDeck.seamonster.command.SetHealthCommand:execute(hpperc)
    if hpperc and tonumber(hpperc) then
        poopDeck.setHealth(hpperc)
    else
        poopDeck.badEcho("Invalid health percentage!")
    end
end

local setHealthCommand = poopDeck.seamonster.command.SetHealthCommand:new()
poopDeck.command.manager:addCommand("setHealth", setHealthCommand)

--Legacy function - kept for backward compatibility
function poopDeck.setMaintain(maintain)
    poopDeck.command.manager:executeCommand("setMaintain", maintain)
end

--Tracking if you're maintaining
function poopDeck.maintaining(maintain)
    if maintain then
        poopDeck.maintaining = true
    else
        poopDeck.maintaining = false
    end
end