-- OOP approach - raise out of range event
raiseEvent("poopDeck.outOfRange")

-- Fallback for backward compatibility
if poopDeck and poopDeck.outOfMonsterRange then
    poopDeck.outOfMonsterRange()
end