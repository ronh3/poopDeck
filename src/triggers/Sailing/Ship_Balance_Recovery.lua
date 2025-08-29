-- Ship Balance Recovery Trigger
-- Fires when the ship is ready for another command

-- The ship has regained balance and can accept commands
if poopDeck and poopDeck.ship then
    poopDeck.ship:onBalanceRecovered()
else
    -- Fallback - just raise the event
    raiseEvent("poopDeck.shipBalanceRecovered")
end