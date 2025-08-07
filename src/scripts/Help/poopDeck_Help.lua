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
            ["mainn"] = "Maintain nothing",
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
        ["Settings"] = {
            ["mainth"] = "Automatically maintain the hull",
            ["maints"] = "Automatically maintain the sails",
            ["maintn"] = "Automatically maintain nothing",
            ["poophp X"] = "Set what HP percentage to go down to until curing is turned back on, default 75%"
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
            ["seaweapon X"] = "Set what weapon to fire, accepts: ballista, b, onager, o, thrower, t",
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

poopDeck.helpFishing = {
    config = {
        headerName = "Fishing Commands",
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "B1D4E0",
        descriptionColor = "FFFFFF",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    },
    categories = {
        ["Basic Fishing"] = {
            ["fish"] = "Start fishing with current defaults (auto-restarts when fish escape)",
            ["fish bass medium"] = "Start fishing with bass bait at medium cast distance",
            ["fish shrimp long"] = "Start fishing with shrimp bait at long cast distance",
            ["stopfish"] = "Stop current fishing session",
            ["fishstats"] = "View comprehensive fishing statistics and session history"
        },
        ["Equipment Configuration"] = {
            ["fishbait <type>"] = "Set default bait to any type from your inventory",
            ["fishcast medium"] = "Set default cast distance to medium (also: short, long)",
            ["fishsource tank"] = "Set bait source: tank, inventory, or fishbucket",
            ["fishrestart"] = "Toggle auto-restart when fish escape (recommended: ON)"
        },
        ["Service Management"] = {
            ["fishenable"] = "Enable the fishing automation service",
            ["fishdisable"] = "Disable the fishing automation service", 
            ["resetfishstats"] = "Reset all fishing statistics (WARNING: Cannot be undone!)"
        },
        ["Cast Distance Guide"] = {
            ["short"] = "Fish close to shore - different fish types, faster bites",
            ["medium"] = "Standard distance - balanced fishing, good for most situations", 
            ["long"] = "Fish far from shore - potentially better fish, longer waits"
        },
        ["Bait System"] = {
            ["Any bait type"] = "System accepts any bait from your chosen source (bass, shrimp, worms, minnow, etc.)",
            ["Bait sources"] = "tank: stored bait | inventory: carried bait | fishbucket: fishing container",
            ["Commands"] = "fishbait <name> sets type, fishsource <location> sets source",
            ["Auto commands"] = "System automatically gets bait and baits hook based on your source setting"
        },
        ["How Auto-Restart Works"] = {
            ["Automatic"] = "When fish escape, system automatically casts again (up to 3 retries)",
            ["Smart Delays"] = "Uses 5-second delays between restart attempts to avoid spamming",
            ["Session Tracking"] = "Tracks all escapes, catches, and statistics persistently"
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
        ["poopfish"] = "Show commands related to fishing automation",
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
        },
        ["Basic Fishing"] = {
            ["fish"] = "Start fishing with current defaults (auto-restarts when fish escape)",
            ["fish bass medium"] = "Start fishing with bass bait at medium cast distance",
            ["stopfish"] = "Stop current fishing session",
            ["fishstats"] = "View comprehensive fishing statistics and session history"
        },
        ["Fishing Configuration"] = {
            ["fishbait <type>"] = "Set default bait to any type from your chosen source",
            ["fishsource tank"] = "Set bait source: tank, inventory, or fishbucket", 
            ["fishcast medium"] = "Set default cast distance to medium (also: short, long)",
            ["fishrestart"] = "Toggle auto-restart when fish escape (recommended: ON)",
            ["fishenable"] = "Enable the fishing automation service",
            ["fishdisable"] = "Disable the fishing automation service"
        }
    }
}
