-- OOP approach - raise event for monster death
local monsterName = matches[2] or "unknown monster"
raiseEvent("poopDeck.monsterKilled", monsterName)

-- Fallback for backward compatibility
if poopDeck and poopDeck.deadSeamonster then
    poopDeck.deadSeamonster()
end