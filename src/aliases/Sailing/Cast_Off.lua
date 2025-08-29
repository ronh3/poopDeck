-- OOP approach - single command (immediate)
if poopDeck.ship then
    poopDeck.ship:castOff()
    
    -- For chaining with balance handling, use:
    -- poopDeck.ship:chain():castOff():setSpeed("full"):turn("north"):execute()
    -- This queues commands and executes them as balance allows
else
    echo("poopDeck: Ship not initialized\n")
end