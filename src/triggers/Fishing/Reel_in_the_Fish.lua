-- Use the fishing service to handle reeling
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onReadyToReel()
end
deleteLine()