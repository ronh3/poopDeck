-- Set bait source alias
-- Usage: fishsource <source>, baitsource <source>, setsource <source>

local baitSource = matches[2]

if baitSource then
    poopDeck.session:executeCommand("fishsource", baitSource)
else
    poopDeck.badEcho("Bait source required. Available: tank, inventory, fishbucket")
end