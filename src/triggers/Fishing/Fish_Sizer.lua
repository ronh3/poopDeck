-- Extract fish type and notify the fishing service
local fishType = matches[2]
poopDeck.smallGoodEcho("Hooked " .. fishType .. " fish!")

-- Notify the fishing service about the hooked fish
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onFishHooked(fishType, "unknown")
end