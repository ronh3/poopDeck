-- Simple anchor command without complex validation
local direction = string.sub(matches[1], 1, 1)
if direction == "r" then
    send("raise anchor")
    poopDeck.goodEcho("Raising anchor")
elseif direction == "l" then  
    send("lower anchor")
    poopDeck.goodEcho("Lowering anchor")
else
    poopDeck.badEcho("Use 'ranc' to raise or 'lanc' to lower anchor")
end