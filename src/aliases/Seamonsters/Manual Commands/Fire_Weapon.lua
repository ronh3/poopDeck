--General purpose fire a weapon alias.
--firb - fire ballista dart
--firf - fire ballista flare
--first - fire onager starshot
--firsp - fire onager spidershot
--firc - fire onager chainshot
--fird - fire thrower disc
--firo - fire alternating starshot and spidershot

-- OOP approach - manual fire through combat object
if poopDeck.combat then
    -- Special handling for 'o' - use auto-fire logic for alternating
    if matches[2] == "o" then
        poopDeck.combat:fire()
    else
        poopDeck.combat:manualFire(matches[2])
    end
else
    echo("poopDeck: Combat system not initialized\n")
end