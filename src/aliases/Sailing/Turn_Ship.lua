-- OOP approach - direct method call on ship object
if poopDeck.ship then
    poopDeck.ship:turn(matches[2])
else
    echo("poopDeck: Ship not initialized\n")
end