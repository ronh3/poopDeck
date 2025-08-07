-- Prompt Settings Aliases
-- Manage sailing/combat prompt spam

local command = matches[1]

if command == "poopquiet" or command == "poopquietmode" then
    -- Toggle quiet mode (minimal spam)
    poopDeck.toggleQuiet()
    
elseif command == "poopprompts" or command == "pooppromptsettings" then
    -- Show prompt configuration
    poopDeck.promptSettings()
    
elseif command == "poopresetprompts" then
    -- Reset throttling counters
    poopDeck.resetPrompts()
    
elseif command:match("^poopthrottle(%d+)$") then
    -- Set throttle time: poopthrottle10 = 10 seconds between messages
    local seconds = tonumber(command:match("^poopthrottle(%d+)$"))
    poopDeck.session:setPromptThrottle(seconds)
    
else
    poopDeck.badEcho("Unknown prompt command: " .. command)
    poopDeck.settingEcho("Available: poopquiet, poopprompts, poopresetprompts, poopthrottle[seconds]")
end