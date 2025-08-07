-- Handle fish escaping scenarios
-- This trigger should catch all the ways a fish can get away

-- Extract escape reason from the match if possible
local escapeReason = "unknown"

-- Common escape messages
if matches[0]:find("swims away") then
    escapeReason = "swam_away"
elseif matches[0]:find("gets away") or matches[0]:find("got away") then
    escapeReason = "got_away"  
elseif matches[0]:find("line breaks") or matches[0]:find("broke your line") then
    escapeReason = "line_broken"
elseif matches[0]:find("escapes") or matches[0]:find("escaped") then
    escapeReason = "escaped"
elseif matches[0]:find("lost") then
    escapeReason = "lost"
elseif matches[0]:find("struggle") then
    escapeReason = "struggled_free"
end

-- Notify the fishing service about the escape
if poopDeck.session and poopDeck.session.fishing then
    poopDeck.session.fishing:onFishEscaped(escapeReason)
end

-- Show escape message to user
poopDeck.badEcho("Fish escaped (" .. escapeReason .. ")")