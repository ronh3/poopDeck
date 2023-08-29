--Toggle to turn curing on/off automatically while firing.
function poopDeck.ToggleCuring()
    if poopDeck.firing then
        send("curing off")
    else
        send("curing on")
end