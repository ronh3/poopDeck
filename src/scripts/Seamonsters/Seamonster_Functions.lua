--Seamonster Tracking and callouts

--Seamonster table to know total shots needed to kill.
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
    poopDeck.seamonsterShots = 0
    poopDeck.badEcho(myMessage)
    if poopDeck.mode == "automatic" then poopDeck.autoFire() end
    tempTimer(poopDeck.constants.FIVE_MINUTES, [[poopDeck.goodEcho("Monster in 5 minutes")]], 5 .. timerName)
    tempTimer(poopDeck.constants.ONE_MINUTE, [[poopDeck.goodEcho("Monster in 1 minute")]], 1 .. timerName)
    tempTimer(poopDeck.constants.NEW_MONSTER, [[poopDeck.badEcho("Reel in, it's monster time!")]], 0 .. timerName)
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


--Automatic Items
--Turns your automatic seamonster firing on or off.
function poopDeck.setSeamonsterAutoFire(mode)
    local myMessage
    if mode == "on" then
        myMessage = "AUTO FIRE ON"
        poopDeck.mode = "automatic"
        poopDeck.goodEcho(myMessage)
    else
        myMessage = "AUTO FIRE OFF"
        poopDeck.mode = "manual"
        poopDeck.badEcho(myMessage)
    end
    
end

--Sets which weapon you'll automatically attempt to fire.
function poopDeck.setWeapon(boomstick)
    local weaponMessages = {
        ballista = "UNLEASH THE DARTS! - BALLISTA",
        onager = "ENGAGE THE MIGHTY SLINGSHOT - ONAGER",
        thrower = "SEND HAVOC SPINNING! - THROWER"
    }

    -- Reset all weapon flags
    poopDeck.weapons.ballista = false
    poopDeck.weapons.onager = false
    poopDeck.weapons.thrower = false

    -- If the weapon is recognized, set its flag to true and get its message
    if weaponMessages[boomstick] then
        poopDeck[boomstick] = true
        poopDeck.goodEcho(weaponMessages[boomstick])
    else
        poopDeck.badEcho("NO WEAPON SELECTED!")
    end
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
        ballista = {"maintain hull", "load ballista with dart", "fire ballista at seamonster"},
        thrower = {"maintain hull", "load thrower with disc", "fire thrower at seamonster"},
        onager = poopDeck.firedSpider and {"maintain hull", "load onager with starshot", "fire onager at seamonster"} or {"maintain hull", "load onager with spidershot", "fire onager at seamonster"}
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

--Manually fire a weapon. onager will alternate between spidershot and starshot if the correct alias (firo) is used.
function poopDeck.seaFire(ammo)
    -- Define a table that maps each ammo type to its corresponding commands
    local ammoCommands = {
        b = {"maintain hull", "load ballista with dart", "fire ballista at seamonster"},
        bf = {"maintain hull", "load ballista with flare", "fire ballista at seamonster"},
        o = poopDeck.firedSpider and {"maintain hull", "load onager with starshot", "fire onager at seamonster"} or {"maintain hull", "load onager with spidershot", "fire onager at seamonster"},
        sp = {"maintain hull", "load onager with spidershot", "fire onager at seamonster"},
        c = {"maintain hull", "load onager with chainshot", "fire onager at seamonster"},
        st = {"maintain hull", "load onager with starshot", "fire onager at seamonster"},
        d = {"maintain hull", "load thrower with disc", "fire thrower at seamonster"}
    }

    if poopDeck.firing == true then return end
    if poopDeck.toggleCuring() then
        local commands = ammoCommands[ammo]
        if commands then
            sendAll(unpack(commands))
            if ammo == "o" then
                poopDeck.firedSpider = not poopDeck.firedSpider
            end
        else
            -- Handle the case where the ammo type is not recognized
            print("Unknown ammo type: " .. ammo)
        end
    else
        poopDeck.toggleCuring("on")
        local myMessage = "NEED TO HEAL - HOLD FIRE!"
        poopDeck.badEcho(myMessage)
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
        if firstMessage then echo("\n") end
        local myMessage = "OUT OF RANGE!"
        poopDeck.rangeEcho(myMessage)
        firstMessage = false
    end
    if not firstMessage then echo("\n") end
end

--Sets if you maintain on shot or not
function poopDeck.setMaintain(maintain)
    local myMessage
    if maintain == "h" then
        myMessage = "MAINTAINING HULL"
        poopDeck.maintain = "hull"
    elseif maintain == "s" then
        myMessage = "MAINTAINING SAILS"
        poopDeck.maintain = "sails"
    elseif maintain == "n" then
        myMessage = "MAINTAINING NONE"
        poopDeck.maintain = false
    else
        myMessage = "MAINTAINING NONE"
        poopDeck.maintain = false
    end
    poopDeck.goodEcho(myMessage)
end