-- Refactored Sailing Script to Use Feature-Based Top-Level Namespace

-- Command Manager class
--poopDeck = {}
poopDeck.command = {}
poopDeck.command.CommandManager = {}
poopDeck.command.CommandManager.__index = poopDeck.command.CommandManager

function poopDeck.command.CommandManager:new()
    local instance = setmetatable({}, poopDeck.command.CommandManager)
    instance.commands = {}
    return instance
end

function poopDeck.command.CommandManager:addCommand(name, command)
    self.commands[name] = command
end

function poopDeck.command.CommandManager:executeCommand(name, ...)
    local command = self.commands[name]
    if command then
        command:execute(...)
    else
        echo("Error: Command not found: " .. name)
    end
end

-- Instantiate a general CommandManager
poopDeck.command.manager = poopDeck.command.CommandManager:new()

-- Base Command class
poopDeck.command.Command = {}
poopDeck.command.Command.__index = poopDeck.command.Command

function poopDeck.command.Command:new(name, action, alias, helpText, category)
    local instance = setmetatable({}, poopDeck.command.Command)
    instance.name = name
    instance.action = action or function() end -- Default to an empty function if no action is provided
    instance.alias = alias or "No alias is available for this command."
    instance.helpText = helpText or "No help is available for this command."
    instance.category = category or "Uncategorized"
    return instance
end

function poopDeck.command.Command:execute(...)
    if type(self.action) == "function" then
        self.action(...)
    elseif type(self.action) == "table" then
        for _, cmd in ipairs(self.action) do
            send(cmd) -- Assuming `send()` sends a command to the game
        end
    elseif type(self.action) == "string" then
        send(self.action)
    else
        echo("Error: Invalid command type for: " .. self.name)
    end
end

--#########################################
-- Sailing Commands (poopDeck.sailing.command)
--#########################################
poopDeck.sailing = {}
poopDeck.sailing.command = {}

-- Anchor Command
poopDeck.sailing.command.AnchorCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.AnchorCommand:new()
    local instance = poopDeck.command.Command:new(
        "anchor",
        nil,
        "(r|l)anc",
        "Raise/lower anchor",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.AnchorCommand})
    return instance
end

function poopDeck.sailing.command.AnchorCommand:execute(orientation)
    local anchorActions = {
        r = "say weigh anchor!",
        l = "say drop the anchor!"
    }
    local action = anchorActions[orientation]
    if action then
        send(action)
    else
        echo("Error: Invalid anchor orientation")
    end
end

local anchorCommand = poopDeck.sailing.command.AnchorCommand:new()
poopDeck.command.manager:addCommand("anchor", anchorCommand)

-- All Stop Command
poopDeck.sailing.command.AllStopCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.AllStopCommand:new()
    local instance = poopDeck.command.Command:new(
        "allStop", 
        "say All stop!",
        "sstop",
        "Stop the ship and all actions.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.AllStopCommand})
    return instance
end

local allStopCommand = poopDeck.sailing.command.AllStopCommand:new()
poopDeck.command.manager:addCommand("allStop", allStopCommand)

-- Cast Off Command
poopDeck.sailing.command.CastoffCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.CastoffCommand:new()
    local instance = poopDeck.command.Command:new(
        "castoff",
        "say castoff!",
        "scast",
        "Cast off from the dock.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.CastoffCommand})
    return instance
end

local castoffCommand = poopDeck.sailing.command.CastoffCommand:new()
poopDeck.command.manager:addCommand("castoff", castoffCommand)

-- Chop Tether Command
poopDeck.sailing.command.ChopTetherCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.ChopTetherCommand:new()
    local instance = poopDeck.command.Command:new(
        "chop",
        "queue add freestand chop tether",
        "chop",
        "Chop enemy tethers.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.ChopTetherCommand})
    return instance
end

local chopTetherCommand = poopDeck.sailing.command.ChopTetherCommand:new()
poopDeck.command.manager:addCommand("chop", chopTetherCommand)

-- Clear Rigging Command
poopDeck.sailing.command.ClearRiggingCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.ClearRiggingCommand:new()
    local instance = poopDeck.command.Command:new(
        "clearRigging",
        {
            "queue add freestand climb rigging",
            "queue add freestand clear rigging"
        },
        "crig",
        "Clear the rigging.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.ClearRiggingCommand})
    return instance
end

local clearRiggingCommand = poopDeck.sailing.command.ClearRiggingCommand:new()
poopDeck.command.manager:addCommand("clearRigging", clearRiggingCommand)

-- Dock Command
poopDeck.sailing.command.DockCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.DockCommand:new()
    local instance = poopDeck.command.Command:new(
        "dock",
        nil,
        "dock(direction)",
        "Dock the ship.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.DockCommand})
    return instance
end

function poopDeck.sailing.command.DockCommand:execute(direction)
    if direction then
        send("ship dock " .. direction .. " confirm")
    else
        echo("Error: Dock direction is required.")
    end
end

local dockCommand = poopDeck.sailing.command.DockCommand:new()
poopDeck.command.manager:addCommand("dock", dockCommand)

-- Douse Command
poopDeck.sailing.command.DouseCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.DouseCommand:new()
    local instance = poopDeck.command.Command:new(
        "douse",
        nil,
        "dou(r|m|s)",
        "Douse yourself, room, or sails.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.DouseCommand})
    return instance
end

function poopDeck.sailing.command.DouseCommand:execute(target)
    local douseActions = {
        r = {
            "queue add freestand fill bucket with water",
            "queue add freestand douse room"
        },
        m = {
            "queue add freestand fill bucket with water",
            "queue add freestand douse me"
        },
        s = {
            "queue add freestand fill bucket with water",
            "queue add freestand douse sails"
        }
    }
    local action = douseActions[target]
    if action then
        for _, cmd in ipairs(action) do
            send(cmd)
        end
    else
        echo("Error: Invalid douse target")
    end
end

local douseCommand = poopDeck.sailing.command.DouseCommand:new()
poopDeck.command.manager:addCommand("douse", douseCommand)

-- Plank Command
poopDeck.sailing.command.PlankCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.PlankCommand:new()
    local instance = poopDeck.command.Command:new(
        "plank",
        nil,
        "(r|l)pla",
        "Raise or lower the plank.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.PlankCommand})
    return instance
end

function poopDeck.sailing.command.PlankCommand:execute(orientation)
    local plankActions = {
        r = "say raise the plank!",
        l = "say lower the plank!"
    }
    local action = plankActions[orientation]
    if action then
        send(action)
    else
        echo("Error: Invalid plank orientation")
    end
end

local plankCommand = poopDeck.sailing.command.PlankCommand:new()
poopDeck.command.manager:addCommand("plank", plankCommand)

-- Relax Oars Command
poopDeck.sailing.command.RelaxOarsCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.RelaxOarsCommand:new()
    local instance = poopDeck.command.Command:new(
        "relaxOars",
        "say stop rowing.",
        "sreo",
        "Stop rowing.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.RelaxOarsCommand})
    return instance
end

local relaxOarsCommand = poopDeck.sailing.command.RelaxOarsCommand:new()
poopDeck.command.manager:addCommand("relaxOars", relaxOarsCommand)

-- Row Oars Command
poopDeck.sailing.command.RowOarsCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.RowOarsCommand:new()
    local instance = poopDeck.command.Command:new(
    "rowOars",
    "say row!",
    "srow",
    "Start rowing.",
    "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.RowOarsCommand})
    return instance
end

local rowOarsCommand = poopDeck.sailing.command.RowOarsCommand:new()
poopDeck.command.manager:addCommand("rowOars", rowOarsCommand)

-- Set Speed Command
poopDeck.sailing.command.SetSpeedCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.SetSpeedCommand:new()
    local instance = poopDeck.command.Command:new(
        "setSpeed",
        nil,
        "sss(#)",
        "Set ship speed.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.SetSpeedCommand})
    return instance
end

function poopDeck.sailing.command.SetSpeedCommand:execute(speed)
    local speedActions = {
        strike = "say strike sails!",
        full = "say full sails!"
    }

    -- Handle specific numerical values
    if speed == "0" or tonumber(speed) == 0 then
        send(speedActions.strike)
    elseif speed == "100" or tonumber(speed) == 100 then
        send(speedActions.full)
    else
        send("ship sails set " .. speed)
    end
end

local setSpeedCommand = poopDeck.sailing.command.SetSpeedCommand:new()
poopDeck.command.manager:addCommand("setSpeed", setSpeedCommand)

-- Ship Repairs Command
poopDeck.sailing.command.ShipRepairsCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.ShipRepairsCommand:new()
    local instance = poopDeck.command.Command:new(
        "shipRepairs",
        nil,
        "srep(a|h|n|s)",
        "Repair all, hull, none, or sails.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.ShipRepairsCommand})
    return instance
end

function poopDeck.sailing.command.ShipRepairsCommand:execute(option)
    local repairActions = {
        p = "ship repair all",
        n = "ship repair none",
        h = "ship repair hull",
        s = "ship repair sails"
    }
    local action = repairActions[option]
    if action then
        send(action)
    else
        echo("Error: Invalid ship repair option")
    end
end

local shipRepairsCommand = poopDeck.sailing.command.ShipRepairsCommand:new()
poopDeck.command.manager:addCommand("shipRepairs", shipRepairsCommand)

-- Turn Ship Command
poopDeck.sailing.command.TurnShipCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.sailing.command.TurnShipCommand:new()
    local instance = poopDeck.command.Command:new(
        "turnShip",
        nil,
        "stt(direction)",
        "Turn the ship.",
        "Sailing"
    )
    setmetatable(instance, {__index = poopDeck.sailing.command.TurnShipCommand})
    return instance
end

function poopDeck.sailing.command.TurnShipCommand:execute(heading)
    local direction = poopDeck.directions[heading]
    if direction then
        send("say Bring her to the " .. direction .. "!")
    else
        echo("Error: Invalid ship heading")
    end
end

local turnShipCommand = poopDeck.sailing.command.TurnShipCommand:new()
poopDeck.command.manager:addCommand("turnShip", turnShipCommand)

--#########################################
-- Spell Commands (poopDeck.spell.command)
--#########################################
poopDeck.spell = {}
poopDeck.spell.command = {}


-- Rainstorm Command
poopDeck.spell.command.RainstormCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.spell.command.RainstormCommand:new()
    local instance = poopDeck.command.Command:new(
        "rainstorm",
        "invoke rainstorm",
        "rain",
        "Extinguish fires.",
        "Seaspells"
    )
    setmetatable(instance, {__index = poopDeck.spell.command.RainstormCommand})
    return instance
end

local rainstormCommand = poopDeck.spell.command.RainstormCommand:new()
poopDeck.command.manager:addCommand("rainstorm", rainstormCommand)

-- Wavecall Command
poopDeck.spell.command.WavecallCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.spell.command.WavecallCommand:new()
    local instance = poopDeck.command.Command:new(
        "wavecall",
        nil,
        "wav(X)(Y)",
        "Move X spaces in Y direction.",
        "Seaspells"
    )
    setmetatable(instance, {__index = poopDeck.spell.command.WavecallCommand})
    return instance
end

function poopDeck.spell.command.WavecallCommand:execute(heading, distance)
    local direction = poopDeck.directions[heading]
    if direction and tonumber(distance) then
        send("invoke wavecall " .. direction .. " " .. distance)
    else
        echo("Error: Invalid heading or distance for wavecall")
    end
end

local wavecallCommand = poopDeck.spell.command.WavecallCommand:new()
poopDeck.command.manager:addCommand("wavecall", wavecallCommand)

-- Windboost Command
poopDeck.spell.command.WindboostCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.spell.command.WindboostCommand:new()
    local instance = poopDeck.command.Command:new(
        "windboost",
        "invoke windboost",
        "wind",
        "Boost speed.",
        "Seaspells"
    )
    setmetatable(instance, {__index = poopDeck.spell.command.WindboostCommand})
    return instance
end

local windboostCommand = poopDeck.spell.command.WindboostCommand:new()
poopDeck.command.manager:addCommand("windboost", windboostCommand)

--#########################################
-- Support Commands (poopDeck.support.command)
--#########################################
poopDeck.support = {}
poopDeck.support.command = {}

-- Comm Screen Command
poopDeck.support.command.CommScreenCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.support.command.CommScreenCommand:new()
    local instance = poopDeck.command.Command:new(
        "commScreen",
        nil,
        "scomm(on|off)",
        "Toggle comm screen.",
        "Utilities"
    )
    setmetatable(instance, {__index = poopDeck.support.command.CommScreenCommand})
    return instance
end

function poopDeck.support.command.CommScreenCommand:execute(state)
    local actions = {
        on = "ship commscreen raise",
        off = "ship commscreen lower"
    }
    local action = actions[state]
    if action then
        send(action)
    else
        echo("Error: Invalid commScreen state")
    end
end

local commScreenCommand = poopDeck.support.command.CommScreenCommand:new()
poopDeck.command.manager:addCommand("commScreen", commScreenCommand)

-- Ship Rescue Command
poopDeck.support.command.ShipRescueCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.support.command.ShipRescueCommand:new()
    local instance = poopDeck.command.Command:new(
        "shipRescue",
        nil,
        "shres",
        "Rescue from ship.",
        "Utilities"
    )
    setmetatable(instance, {__index = poopDeck.support.command.ShipRescueCommand})
    return instance
end

function poopDeck.support.command.ShipRescueCommand:execute()
    local rescueActions = {
        "get token from pack",
        "curing off",
        "ship rescue me"
    }
    for _, cmd in ipairs(rescueActions) do
        send(cmd)
    end
end

local shipRescueCommand = poopDeck.support.command.ShipRescueCommand:new()
poopDeck.command.manager:addCommand("shipRescue", shipRescueCommand)

-- Ship Warning Command
poopDeck.support.command.ShipWarningCommand = setmetatable({}, {__index = poopDeck.command.Command})

function poopDeck.support.command.ShipWarningCommand:new()
    local instance = poopDeck.command.Command:new(
        "shipWarning",
        nil,
        "shw(on|off)",
        "Toggle ship warning.",
        "Utilities"
    )
    setmetatable(instance, {__index = poopDeck.support.command.ShipWarningCommand})
    return instance
end

function poopDeck.support.command.ShipWarningCommand:execute(state)
    local warningActions = {
        on = "shipwarning on",
        off = "shipwarning off"
    }
    local action = warningActions[state]
    if action then
        send(action)
    else
        echo("Error: Invalid ship warning state")
    end
end

local shipWarningCommand = poopDeck.support.command.ShipWarningCommand:new()
poopDeck.command.manager:addCommand("shipWarning", shipWarningCommand)