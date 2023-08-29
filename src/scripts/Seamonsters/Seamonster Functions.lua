--Seamonster table to know total shots needed to kill.
poopDeck.Seamonsters = {["a legendary leviathan"] = 60, ["a hulking oceanic cyclops"] = 60, ["a towering oceanic hydra"] = 60, ["a sea hag"] = 40, ["a monstrous ketea"] = 40, ["a monstrous picaroon"] = 40, ["an unmarked warship"] = 40, ["a red-sailed Kashari raider"]= 30, ["a furious sea dragon"] = 30, ["a pirate ship"] = 30, ["a trio of raging sea serpents"] = 30, ["a raging shraymor"] = 25, ["a mass of sargassum"] = 25, ["a gargantuan megalodon"] = 25, ["a gargantuan angler fish"] = 25, ["a mudback septacean"] = 20, ["a flying sheilei"] = 20, ["a foam-wreathed sea serpent"] = 20, ["a red-faced septacean"] = 20,}

--Sets if you're going to damage, debuff, or not use automatic weapon firing.
function poopDeck.SetSeamonsterMode(mode)

    local myFormatter = TextFormatter:new( {
        width = 25, 
        cap = "[PoopDeck]",
        capColor = "<green>",
        textColor = "<dodger_blue>"
    })

    if mode == "dam" then
        disableTriggerGroup("Auto Seamonster Debuff")
        enableTriggerGroup("Auto Seamonster Damage")
        myMessage = "AUTO DAMAGE"
        poopDeck.mode = "damage"
    elseif mode == "dbf" then
        disableTriggerGroup("Auto Seamonster Damage")
        enableTriggerGroup("Auto Seamonster Debuff")
        myMessage = "DEBUFF"
        poopDeck.mode = "debuff"
    elseif mode == "off" then
        disableTriggerGroup("Auto Seamonster Damage")
        disableTriggerGroup("Auto Seamonster Debuff")
        myMessage = "AUTO OFF"
        poopDeck.mode = "none"
    end

    cecho("\n"..myFormatter:format(myMessage).."\n")
end

--Sets your weapon for automatic firing
--Fires your selected weapon.
function poopDeck.SeaFire(ammo)

    local command
    poopDeck.pauseCuring()
    poopDeck.shipVitals()

    if ammo == "bal" then
        send(command .. "ship info/maintain hull/load ballista with dart/fire ballista at seamonster")
    elseif ammo == "fla" then
        send(command .. "ship info/maintain hull/load ballista with flare/fire ballista at seamonster")
    elseif ammo == "spid" then
        send(command .. "ship info/maintain hull/load onager with spidershot/fire onager at seamonster")
    elseif ammo == "star" then
        send(command .. "ship info/maintain hull/load onager with starshort/fire onager at seamonster")
    elseif ammo == "dis" then
        send(command .. "ship info/maintain hull/load thrower with disc/fire thrower at seamonster")
    end
end

--Fired Weapon
function poopDeck.SeaFired()


--Shot counter
function poopDeck.ShotCounter(target)
    local toKill = poopDeck.Seamonsters[target] or 30

    poopDeck.SeamonsterShots = poopDeck.SeamonsterShots or 0
    poopDeck.SeamonsterShots = poopDeck.SeamonsterShots + 1

    cecho("\n<orange>We have taken <green>".. poopDeck.SeamonsterShots .. "<orange> shots. <red>" .. toKill - poopDeck.SeamonsterShots .. "<orange> remain.\n")
end