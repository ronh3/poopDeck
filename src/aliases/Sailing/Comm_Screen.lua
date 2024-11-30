local state = matches[2]  -- Assuming matches[2] captures "on" or "off"
poopDeck.command.manager:executeCommand("commScreen", state)