-- Simple fishing command - bypass complex service layer for now
local bait = matches[2] or "bass"
local castDistance = matches[3] or "medium"

poopDeck.goodEcho("Starting fishing with " .. bait .. " at " .. castDistance .. " distance")

-- Basic fishing sequence
sendAll(
    "queue addclearfull freestand get " .. bait .. " from tank here",
    "queue add freestand bait hook with " .. bait,
    "queue add freestand cast line " .. castDistance
)