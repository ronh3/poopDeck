-- Start fishing alias
-- Usage: fish [bait] [cast_distance]

local bait = matches[2] or nil
local castDistance = matches[3] or nil

if bait and castDistance then
    poopDeck.session:executeCommand("fish", bait, castDistance)
elseif bait then
    poopDeck.session:executeCommand("fish", bait)
else
    poopDeck.session:executeCommand("fish")
end