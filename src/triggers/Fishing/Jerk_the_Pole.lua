-- Use the fishing service to handle large strikes
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onLargeStrike()
end