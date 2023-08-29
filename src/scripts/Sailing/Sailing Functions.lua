--Raise/lower anchor
function poopDeck.Anchor(whatdo)
    if whatdo == "r" then
        send("ship raise anchor")
    elseif whatdo == "l" then
        send("ship lower anchor")
    end
end

--Cast off from the dock
function poopDeck.CastOff()
    send("ship castoff")
end

--Chop ropes from an enemy ship
function poopDeck.Chop()
    send("chop tether")
end

--Clear the rigging
function poopDeck.ClearRigging()
    send("queue add full climb rigging")
    send("queue add full clear rigging")
    send("queue add full climb rigging")
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
    send("ship dock " .. direction)
end

--Fill a bucket, douse the room or yourself, then fill the bucket up again
function poopDeck.Douse(whatdo)
    send("fill bucket with water")
    if whatdo == "r" then
        send("queue add full douse room")
    elseif whatdo == "m" then
        send("queue add full douse me")
    end
    send("queue add full fill bucket with water")
end

--Raise/lower the plank
function poopDeck.Plank(whatdo)
    if whatdo == "r" then
        send("ship raise plank")
    elseif whatdo == "l" then
        send("ship lower plank")
    end
end

--Cast Rainstorm
function poopDeck.Rain()
    send("invoke rainstorm")
end

--Set the ship's speed. Will accept a number (for percentage) as well as full, relax, furl, and strike
function poopDeck.SetSpeed(zoom)
    