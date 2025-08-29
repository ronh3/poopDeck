-- Ship Prompt Trigger for poopDeck OOP
-- Captures all ship vitals from the prompt and updates Ship class instance

-- This trigger should fire on the regex pattern:
-- ^= Sl (?<sails>\w+) - hp (?<sailhp>\d+)\%,Hl: (?<hullhp>\d+)\%,Wd (?<winddir>\w+)\@(?<windspeed>\d+)kts,Cr\/Sp (?<heading>\w+)\@(?<speed>\d+),Sea (?<sea>\w+),?(?<row>Row)?\+?(?<sail>Sail)?,?(?:Turn\-\>)?(?<turn>\w+)?$

-- Update the ship instance with parsed prompt data
if poopDeck and poopDeck.ship then
    poopDeck.ship:parsePromptMatches(matches)
else
    -- If OOP system not initialized yet, just raise event with raw data
    raiseEvent("poopDeck.shipPromptCaptured", matches)
end

-- Optional: Display critical warnings immediately
if matches.hullhp and tonumber(matches.hullhp) <= 25 then
    if poopDeck and poopDeck.display then
        poopDeck.display:showMessage("CRITICAL HULL DAMAGE!", "bad", true)
    end
end

if matches.sailhp and tonumber(matches.sailhp) <= 25 then
    if poopDeck and poopDeck.display then
        poopDeck.display:showMessage("CRITICAL SAIL DAMAGE!", "bad", true)
    end
end

-- Handle special states that might need immediate attention
if matches.turn then
    -- Ship is currently turning, might want to pause certain actions
    raiseEvent("poopDeck.shipInTurn", matches.turn)
end

if matches.row then
    -- Rowing is active
    raiseEvent("poopDeck.rowingActive")
end