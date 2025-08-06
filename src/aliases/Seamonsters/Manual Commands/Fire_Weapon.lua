-- Manual fire weapon commands
-- These aliases execute the pre-registered manual fire commands
-- firb - fire ballista dart
-- firf - fire ballista flare  
-- first - fire onager starshot
-- firsp - fire onager spidershot
-- firc - fire onager chainshot (not implemented yet)
-- fird - fire thrower disc
-- firo - fire alternating starshot and spidershot

-- Execute the appropriate command based on the alias used
local alias = matches[1]
local commandMap = {
    firb = "ballistaDart",
    firf = "ballistaFlare", 
    first = "onagerStarshot",
    firsp = "onagerSpidershot",
    fird = "throwerDisc",
    firo = "onagerAlternating"
}

local commandName = commandMap[alias]
if commandName then
    local command = poopDeck.command.manager:getCommand(commandName)
    if command then
        command:execute()
    else
        poopDeck.badEcho("Command '" .. commandName .. "' not found!")
    end
else
    poopDeck.badEcho("Unknown fire command: " .. alias)
end
