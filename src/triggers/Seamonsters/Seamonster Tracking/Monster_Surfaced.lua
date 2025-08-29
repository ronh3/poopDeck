-- OOP approach - raise event with monster name
local monsterName = matches[2] or "unknown monster"
raiseEvent("poopDeck.monsterSpawned", monsterName)

-- Fallback for backward compatibility if OOP system not loaded
if poopDeck and poopDeck.monsterSurfaced then
    poopDeck.monsterSurfaced()
end