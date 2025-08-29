-- OOP approach - set weapon on combat object
if poopDeck.combat then
    poopDeck.combat:setWeapon(matches[2])
    -- Also save to config for persistence
    if poopDeck.config then
        poopDeck.config:setWeapon(matches[2])
    end
else
    echo("poopDeck: Combat system not initialized\n")
end