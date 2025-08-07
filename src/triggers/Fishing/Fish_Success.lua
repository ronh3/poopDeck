-- Handle successful fish catches
-- This trigger should catch when a fish is successfully reeled in

-- Extract fish data from the match
local fishData = {
    type = "unknown",
    size = "unknown", 
    weight = 0
}

-- Try to extract fish information from the match
if matches[2] then
    fishData.type = matches[2]
end

if matches[3] then
    fishData.size = matches[3]
end

-- Look for weight information if present
if matches[0]:find("(%d+) pounds") then
    local weight = matches[0]:match("(%d+) pounds")
    fishData.weight = tonumber(weight) or 0
end

-- Notify the fishing service about the successful catch
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onFishCaught(fishData)
end

-- Show success message
local fishName = fishData.size ~= "unknown" and (fishData.size .. " " .. fishData.type) or fishData.type
poopDeck.goodEcho("Caught: " .. fishName .. (fishData.weight > 0 and (" (" .. fishData.weight .. " lbs)") or ""))