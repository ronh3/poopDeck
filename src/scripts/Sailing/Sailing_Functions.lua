--Setting directions for turning the boat
local directions = {
    e = "east",
    ene = "east-northeast",
    ese = "east-southeast",
    n = "north",
    nnw = "north-northwest",
    nne = "north-northeast",
    ne = "northeast",
    nw = "northwest",
    s = "south",
    sse = "south-southeast",
    ssw = "south-southwest",
    se = "southeast",
    sw = "southwest",
    w = "west",
    wnw = "west-northwest",
    wsw = "west-southwest"
}

--Speeds for setSpeed function
local speeds = {
    strike = "say strike sails!",
    furl = "say furl sails!",
    full = "say full sails!",
    relax = "say relax sails!",
}

--Table of all of the ship commands that we're dealing with at this time. All are pretty self explanatory.
local commands = {
    allStop = "say All stop!",
    anchor = {r = "say weigh anchor!", l = "say drop the anchor!"},
    castoff = "say castoff!",
    chop = "chop tether",
    clearRigging = {"queue add freestand climb rigging", "queue add freestand clear rigging"},
    clearedRigging = "queue add freestand climb rigging down",
    commScreen = {on = "ship commscreen raise", off = "ship commscreen lower"},
    douse = {
        r = {"queue add freestand fill bucket with water", "queue add freestand douse room"},
        m = {"queue add freestand fill bucket with water", "queue add freestand douse me"},
        s = {"queue add freestand fill bucket with water", "queue add freestand douse sails"}
    },
    maintain = {h = "queue add freestand maintain hull", s = "queue add freestand maintain sails", n = "queue add freestand maintain none"},
    plank = {r = "say raise the plank!", l = "say lower the plank!"},
    rainstorm = "invoke rainstorm",
    relaxOars = "say stop rowing.",
    rowOars = "say row!",
    shipRepairs = "ship repair all",
    shipRescue = {"get token from pack", "ship rescue me"},
    shipWarning = {on = "shipwarning on", off = "shipwarning off"},
    windboost = "invoke windboost",
}

function poopDeck.command(func, whatDo)
    local command = commands[func]
    if not command then
        echo("Error: Command not found: " .. func)
        return
    end
    if type(command) == "table" then
        if whatDo and command[whatDo] then
            sendAll(command[whatDo])
        else
            echo("Error: Value not found in command table: " .. whatDo)
            return
        end
    elseif type(command) == "string" then
        send(command)
    end
end

function poopDeck.dock(direction)
    send("ship dock " .. direction .. " confirm")
end

function poopDeck.setSpeed(speed)
    local command = speeds[speed]
    if not command then
        send("ship sails set " .. speed)
    else
        send(command)
    end
end

function poopDeck.turnShip(heading)
    send("say Bring her to the " .. directions[heading] .. "!")
end

function poopDeck.wavecall(heading, howFar)
    send("invoke wavecall " .. heading .. " " .. howFar)
end