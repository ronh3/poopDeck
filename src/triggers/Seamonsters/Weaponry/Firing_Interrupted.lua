-- OOP approach - raise shot interrupted event
raiseEvent("poopDeck.shotInterrupted")

-- Fallback for backward compatibility  
if poopDeck and poopDeck.interruptedShot then
    poopDeck.interruptedShot()
end