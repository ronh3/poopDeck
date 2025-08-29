-- OOP approach - raise weapon fired event
local weapon = matches[2] or "unknown weapon"
raiseEvent("poopDeck.weaponFired", weapon)

-- Fallback for backward compatibility
if poopDeck and poopDeck.seaFired then
    poopDeck.seaFired()
end