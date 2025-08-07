-- Use the fishing service to handle line teasing
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onLineTeased()
end