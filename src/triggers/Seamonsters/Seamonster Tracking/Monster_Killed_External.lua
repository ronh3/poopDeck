-- Trigger for when someone else kills the monster
-- Common patterns: "The monster sinks", "disappears beneath the waves", etc.

-- OOP approach - raise external kill event
raiseEvent("poopDeck.monsterKilledExternal")

-- Also clean up any display issues immediately
if poopDeck and poopDeck.display then
    poopDeck.display:showMessage("Monster killed by others", "setting", true)
end