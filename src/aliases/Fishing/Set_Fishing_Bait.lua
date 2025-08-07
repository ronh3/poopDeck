-- Set fishing bait alias
-- Usage: fishbait <type>, setbait <type>, bait <type>

local baitType = matches[2]

if baitType then
    poopDeck.session:executeCommand("fishbait", baitType)
else
    poopDeck.badEcho("Bait type required (any bait from your inventory)")
end