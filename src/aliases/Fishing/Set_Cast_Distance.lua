-- Set cast distance alias  
-- Usage: fishcast <distance>, setcast <distance>, castdistance <distance>

local castDistance = matches[2]

if castDistance then
    poopDeck.session:executeCommand("fishcast", castDistance)
else
    poopDeck.badEcho("Cast distance required. Available: short, medium, long")
end