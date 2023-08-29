--Seamonster table to know total shots needed to kill.
poopDeck.Seamonsters = {
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

--Turns your automatic seamonster firing on or off.
function poopDeck.SetSeamonsterAutoFire(mode)
    if mode == "on" then
        enableTrigger("Automatics")
        myMessage = "AUTO FIRE ON"
        poopDeck.mode = "automatic"
        poopDeck.GoodEcho(myMessage)
    else
        disableTrigger("Automatics")
        myMessage = "AUTO FIRE OFF"
        poopDeck.mode = "manual"
        poopDeck.BadEcho(myMessage)
    end
    
end

--Sets which weapon you'll automatically attempt to fire.
function poopDeck.SetWeapon(boomstick)
    poopDeck.Ballista = false
    poopDeck.Onager = false
    poopDeck.Thrower = false
    local myMessage

    if boomstick == "ballista" then 
        poopDeck.Ballista = true
        myMessage = "UNLEASH THE DARTS!"
    elseif boomstick == "onager" then
        poopDeck.Onager = true
        myMessage = "ENGAGE THE MIGHTY SLINGSHOT"
    elseif boomstick == "thrower" then
        poopDeck.Thrower = true
        myMessage = "SEND HAVOC SPINNING!"
    end
    poopDeck.GoodEcho(myMessage)
end

--Automatically fires your set weapon. Will first check for which weapon you're supposed to be firing.
--For ballista and thrower, it's just going to dart and wardisc the monster.
--For the onager, it will rotate between starshot and spidershot.
function poopDeck.AutoFire()
    poopDeck.ToggleCuring(true)
    poopDeck.ShipVitals()

    if poopDeck.Ballista then
        sendAll("maintain hull", "load ballista with dart", "fire ballista at seamonster")
    elseif poopDeck.Thrower then
        sendAll("maintain hull", "load thrower with disc", "fire thrower at seamonster")
    elseif poopDeck.Onager then
        if poopDeck.FiredSpider then
            sendAll("maintain hull", "load onager with starshort", "fire onager at seamonster")
        else
            sendAll("maintain hull", "load onager with spidershot", "fire onager at seamonster")
        end
    end
end

--Manually fire a weapon. Onager will alternate between spidershot and starshot if the correct alias (firo) is used.
function poopDeck.SeaFire(ammo)
    poopDeck.ToggleCuring(true)
    poopDeck.ShipVitals()

    if ammo == "b" then
        sendAll("maintain hull", "load ballista with dart", "fire ballista at seamonster")
    elseif ammo == "bf" then
        sendAll("maintain hull", "load ballista with flare", "fire ballista at seamonster")
    elseif ammo == "o" then
        if poopDeck.FiredSpider then
            sendAll("maintain hull", "load onager with starshort", "fire onager at seamonster")
        else
            sendAll("maintain hull", "load onager with spidershot", "fire onager at seamonster")
        end
    elseif ammo == "sp" then
        sendAll("maintain hull", "load onager with spidershot", "fire onager at seamonster")
    elseif ammo == "st" then
        sendAll("maintain hull", "load onager with starshort", "fire onager at seamonster")
    elseif ammo == "d" then
        sendAll("maintain hull", "load thrower with disc", "fire thrower at seamonster")
    end
end

--Fired a weapon. Setting a temptimer for 4s to fire again if automatic mode is engaged.
--Otherwise, setting a 4s temptimer to let the user know they can shoot again.
function poopDeck.SeaFired()
    local myMessage

    poopDeck.ToggleCuring()
    if poopDeck.mode == "automatic" then
        tempTimer(4, [[poopDeck.AutoFire()]])
    elseif poopDeck.mode == "manual" then
        tempTimer(4, [[myMessage = "READY TO FIRE" poopDeck.GoodEcho(myMessage)]])
    end
end

--Shot counter - Could probably make this cleaner, not sure exactly how though.
function poopDeck.ShotCounter(target)
    local toKill = poopDeck.Seamonsters[target] or 30

    poopDeck.SeamonsterShots = poopDeck.SeamonsterShots or 0
    poopDeck.SeamonsterShots = poopDeck.SeamonsterShots + 1
    cecho("\n<orange>We have taken <green>".. poopDeck.SeamonsterShots .. "<orange> shots. <red>" .. toKill - poopDeck.SeamonsterShots .. "<orange> remain.\n")
end

--Toggle to turn curing on/off automatically while firing.
function poopDeck.ToggleCuring(thankyouherrdoktor)
    if thankyouherrdoktor then
        send("curing off")
    else
        send("curing on")
    end
end

--Ship Vital checker. Do something with this later
function poopDeck.ShipVitals()
    return
end

--If we were out of range, turn curing back on.
function poopDeck.OutOfMonsterRange()
    poopDeck.ToggleCuring()
    enableTrigger("Ship Moved Lets Try Again")
end

--Start shooting if a monster surfaced if set to auto
--For auto and manual, display a warning
function poopDeck.MonsterSurfaced()
    local myMessage
    
    myMessage = "SEAMONSTER HAS SURFACED"
    poopDeck.BadEcho(myMessage)
    if poopDeck.mode == true then poopDeck.AutoFire() end
end