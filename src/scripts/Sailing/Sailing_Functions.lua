--Raise/lower anchor
function poopDeck.Anchor(whatdo)
    if whatdo == "r" then
        send("say weigh anchor!")
    elseif whatdo == "l" then
        send("say drop the anchor!")
    end
end

--Cast off from the dock
function poopDeck.CastOff()
    send("say castoff!")
end

--Chop ropes from an enemy ship
function poopDeck.Chop()
    send("chop tether")
end

--Clear the rigging
function poopDeck.ClearRigging()
    sendAll("queue add freestand climb rigging", "queue add freestand clear rigging")
end

--Climb down after clearing the rigging
function poopDeck.ClearedRigging()
    send("queue add freestand climb rigging down")
end

--Raise and lower Comm Screen
function poopDeck.CommScreen(whatdo)
    if whatdo == "on" then
        send("ship commscreen raise")
    elseif whatdo == "off" then
        send("ship commscreen lower")
    end
end

--Dock the ship in a direction
function poopDeck.Dock(direction)
    send("ship dock " .. direction .. " confirm")
end

--Fill a bucket, douse the room or yourself, then fill the bucket up again
function poopDeck.Douse(whatdo)
    if whatdo == "r" then
        sendAll("queue add freestand fill bucket with water", "queue add freestand douse room")
    elseif whatdo == "m" then
        sendAll("queue add freestand fill bucket with water", "queue add freestand douse me")
    elseif whatdo == "s" then
        sendAll("queue add freestand fill bucket with water", "queue add freestand douse sails")
    end
    send("queue add freestand fill bucket with water")
end

--Maintain the hull or sails
function poopDeck.maintain(whatdo)
    if whatdo == "h" then
        send("queue add freestand maintain hull")
    elseif whatdo == "s" then
        send("queue add freestand maintain sails")
    elseif whatdo == "n" then
        send("queue add freestand maintain none")
    end
end

--Raise/lower the plank
function poopDeck.Plank(whatdo)
    if whatdo == "r" then
        send("say raise the plank!")
    elseif whatdo == "l" then
        send("say lower the plank!")
    end
end

--Cast Rainstorm
function poopDeck.Rainstorm()
    send("invoke rainstorm")
end

--Relax oars
function poopDeck.relaxOars()
    send("say stop rowing.")
end

--Start Rowing
function poopDeck.rowOars()
    send("say Man the oars!")
end

--Set the ship's speed. Will accept a number (for percentage) as well as full, relax, furl, and strike. I think those last three are all the same? o.O
function poopDeck.SetSpeed(zoom)
    if zoom == "strike" or zoom == "furl" or zoom == "full" or zoom == "relax" then
        send("say " .. zoom .. " sails!")
    elseif zoom == 100 then
        send("say full sails!")
    elseif zoom == 0 then
        send("say strike sails!")
    else
        send("ship sails set " .. zoom)
    end
end

--Get the crew to repairing.
function poopDeck.ShipRepairs()
    send("ship repair all")
end

--Get yourself rescued!
function poopDeck.ShipRescue()
    poopDeck.rescue = true
    sendAll("get token from pack", "ship rescue me")
end

--Turn on/off shipwarning. Honestly, this should always be on. Tempted to make it a trigger. Maybe? We'll see.
function poopDeck.ShipWarning(whatdo)
    if whatdo == "on" then
        send("shipwarning on")
    elseif whatdo == "off" then
        send("shipwarning off")
    end
end

--Turning the ship!
function poopDeck.TurnShip(heading)
    local directions = {
        ["e"] = "east",
        ["ene"] = "east-northeast",
        ["ese"] = "east-southeast",
        ["n"] = "north",
        ["nnw"] = "north-northwest",
        ["nne"] = "north-northeast",
        ["ne"] = "northeast",
        ["nw"] = "northwest",
        ["s"] = "south",
        ["sse"] = "south-southeast",
        ["ssw"] = "south-southwest",
        ["se"] = "southeast",
        ["sw"] = "southwest",
        ["w"] = "west",
        ["wnw"] = "west-northwest",
        ["wsw"] = "west-southwest"
    }
    send("say Bring her to the " .. directions[heading] .. "!")
end

--Wavecall. Takes direction, and number of spaces
function poopDeck.WaveCall(heading, howfar)
    send("invoke wavecall " .. heading .. " " .. howfar)
end

--Windboost. What it says on the tin really.
function poopDeck.Windboost()
    send("invoke windboost")
end

--Send the all stop command
function poopDeck.allStop()
    send("say All stop!")
end