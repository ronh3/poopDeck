-- OOP approach - raise shot hit event
local monsterName = matches.monster or matches[2] or "unknown monster"
raiseEvent("poopDeck.shotHit", monsterName)

-- Fallback for backward compatibility
if poopDeck and poopDeck.countShots then
    poopDeck.countShots(monsterName)
end