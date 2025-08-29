poopDeck.helpSailing = {
    config = {
        headerName = "Ship Commands",
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "B1D4E0",
        descriptionColor = "FFFFFF",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    },
    categories = {
        ["Navigation and Movement"] = {
            ["dockX"] = "Dock the ship in X direction, can use a space if preferred",
            ["scast"] = "Cast Off",
            ["sreo"] = "Stop rowing",
            ["srow"] = "Start rowing",
            ["sstop"] = "All Stop",
            ["sssX"] = "Set sail speed to X from 0-100, can use a space if preferred",
            ["sttX"] = "Turn the ship to X direction, can use a space if preferred",
        },
        ["Ship Management"] = {
            ["lanc"] = "Lower the anchor",
            ["lpla"] = "Lower the plank",
            ["mainh"] = "Maintain the hull",
            ["mains"] = "Maintain the sails",
            ["ranc"] = "Raise the anchor",
            ["rpla"] = "Raise the plank",
            ["scomm off"] = "Turn off comm screen",
            ["scomm on"] = "Turn on comm screen",
            ["shwoff"] = "Turn ship warning off, can use a space if preferred",
            ["shwon"] = "Turn ship warning on, can use a space if preferred",
            ["srep"] = "Repair the hull and sails",
        },
        ["Safety and Emergencies"] = {
            ["chop"] = "Chop Ropes",
            ["crig"] = "Clear Rigging",
            ["doum"] = "Fill and douse yourself with a bucket",
            ["dour"] = "Fill and douse the room with a bucket",
            ["rain"] = "Use rainstorm to put out fires on the ship",
            ["sres"] = "Use a token to SHIP RESCUE",
            ["wavXY"] = "Use wavecall in X direction for Y spaces, can use a space if preferred"
        }
    }
}

poopDeck.helpSeamonsters = {
    config = {
        headerName = "Manual Ship Weapon Commands",
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "B1D4E0",
        descriptionColor = "FFFFFF",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    },
    categories = {
        Automatic = {
            ["autosea"] = "Turn automatic seamonstering on or off",
            ["seaweapon X"] = "Set what weapon to fire, accepts: ballista, onager, thrower",
            ["poophp X"] = "Set what HP percentage to go down to until curing is turned back on, default 75%"
        },
        Manual = {
            ["firb"] = "Fire a dart from a ballista at a seamonster",
            ["fird"] = "fire a wardisc from a thrower at a seamonster",
            ["firf"] = "fire a flare from a ballista at a seamonster",
            ["firo"] = "fire alternating starshot and spidershot from an onager at a seamonster",
            ["first"] = "fire a starshot from an onager at a seamonster",
            ["firsp"] = "fire a spidershot from an onager at a seamonster"
        }
    }
}

poopDeck.helpSplash = {
    config = {
        headerName = "Welcome to poopDeck!",
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "B1D4E0",
        descriptionColor = "FFFFFF",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    },
    entries = {
        ["poopmonster"] = "Show commands related to seamonsters and ship weapons",
        ["poopsail"] = "Show commands related to sailing a ship",
        ["poopfull"] = "Show all commands"
    }
}

poopDeck.helpFullPoop = {
    config = {
        headerName = "All Commands",
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "B1D4E0",
        descriptionColor = "FFFFFF",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    },
    categories = {
        ["Navigation and Movement"] = {
            ["dockX"] = "Dock the ship in X direction, can use a space if preferred",
            ["scast"] = "Cast Off",
            ["sreo"] = "Stop rowing",
            ["srow"] = "Start rowing",
            ["sstop"] = "All Stop",
            ["sssX"] = "Set sail speed to X from 0-100, can use a space if preferred",
            ["sttX"] = "Turn the ship to X direction, can use a space if preferred",
        },
        ["Ship Management"] = {
            ["lanc"] = "Lower the anchor",
            ["lpla"] = "Lower the plank",
            ["mainh"] = "Maintain the hull",
            ["mains"] = "Maintain the sails",
            ["ranc"] = "Raise the anchor",
            ["rpla"] = "Raise the plank",
            ["scomm off"] = "Turn off comm screen",
            ["scomm on"] = "Turn on comm screen",
            ["shwoff"] = "Turn ship warning off, can use a space if preferred",
            ["shwon"] = "Turn ship warning on, can use a space if preferred",
            ["srep"] = "Repair the hull and sails",
        },
        ["Safety and Emergencies"] = {
            ["chop"] = "Chop Ropes",
            ["crig"] = "Clear Rigging",
            ["doum"] = "Fill and douse yourself with a bucket",
            ["dour"] = "Fill and douse the room with a bucket",
            ["rain"] = "Use rainstorm to put out fires on the ship",
            ["sres"] = "Use a token to SHIP RESCUE",
            ["wavXY"] = "Use wavecall in X direction for Y spaces, can use a space if preferred"
        },
        ["Automatic Weapons"] = {
            ["autosea"] = "Turn automatic seamonstering on or off",
            ["seaweapon X"] = "Set what weapon to fire, accepts: ballista, onager, thrower",
            ["poophp X"] = "Set what HP percentage to go down to until curing is turned back on, default 75%"
        },
        ["Manual Weapons"] = {
            ["firb"] = "Fire a dart from a ballista at a seamonster",
            ["fird"] = "fire a wardisc from a thrower at a seamonster",
            ["firf"] = "fire a flare from a ballista at a seamonster",
            ["firo"] = "fire alternating starshot and spidershot from an onager at a seamonster",
            ["first"] = "fire a starshot from an onager at a seamonster",
            ["firsp"] = "fire a spidershot from an onager at a seamonster"
        }
    }
}
