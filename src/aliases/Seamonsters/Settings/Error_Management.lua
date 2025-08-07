-- Error Management Aliases
-- Control logging, debugging, and error handling

local command = matches[1]

if command == "poopdebug" then
    -- Toggle debug mode and set log level to debug
    if poopDeck.session and poopDeck.session.errorHandler then
        local currentLevel = poopDeck.session.errorHandler.settings.logLevel
        if currentLevel == "debug" then
            poopDeck.session.errorHandler:setLogLevel("warn")
            poopDeck.settingEcho("Debug logging disabled (level: warn)")
        else
            poopDeck.session.errorHandler:setLogLevel("debug")
            poopDeck.settingEcho("Debug logging enabled (level: debug)")
        end
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command == "pooperrors" then
    -- Show recent errors
    if poopDeck.session and poopDeck.session.errorHandler then
        local errors = poopDeck.session.errorHandler:getRecentErrors(10)
        if #errors == 0 then
            poopDeck.settingEcho("No recent errors")
        else
            echo("\n<yellow>Recent Errors (last 10):</yellow>\n")
            for i, error in ipairs(errors) do
                local levelColor = {
                    debug = "#888888",
                    info = "#00FFFF", 
                    warn = "#FFFF00",
                    error = "#FF6600",
                    fatal = "#FF0000"
                }
                local color = levelColor[error.level] or "#FFFFFF"
                echo(string.format("<%s>%d. [%s] %s: %s<reset>\n", 
                    color, i, error.formattedTime, error.level:upper(), error.message))
            end
        end
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command == "poopclearerrors" then
    -- Clear error log
    if poopDeck.session and poopDeck.session.errorHandler then
        poopDeck.session.errorHandler:clearErrorLog()
        poopDeck.settingEcho("Error log cleared")
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command == "pooplogging" then
    -- Toggle error display
    if poopDeck.session and poopDeck.session.errorHandler then
        local success, msg = poopDeck.session.errorHandler:toggleDisplayErrors()
        poopDeck.settingEcho(msg)
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command:match("^pooploglevel(%w+)$") then
    -- Set log level: pooploglevelwarn, pooplogleleveldebug, etc.
    local level = command:match("^pooploglevel(%w+)$")
    if poopDeck.session and poopDeck.session.errorHandler then
        local success, msg = poopDeck.session.errorHandler:setLogLevel(level)
        if success then
            poopDeck.settingEcho(msg)
        else
            poopDeck.badEcho(msg)
            poopDeck.settingEcho("Valid levels: debug, info, warn, error, fatal")
        end
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command == "pooperrorstatus" then
    -- Show error handler status
    if poopDeck.session and poopDeck.session.errorHandler then
        local status = poopDeck.session.errorHandler:getStatus()
        echo("\n<yellow>===== Error Handler Status =====</yellow>\n")
        echo(string.format("Enabled: %s\n", status.enabled and "YES" or "NO"))
        echo(string.format("Log Level: %s\n", status.logLevel:upper()))
        echo(string.format("Total Log Entries: %d\n", status.totalLogEntries))
        echo(string.format("Recent Errors: %d\n", status.recentErrors))
        echo(string.format("GMCP Available: %s\n", status.gmcpAvailable and "YES" or "NO"))
        echo(string.format("Mudlet Available: %s\n", status.mudletAvailable and "YES" or "NO"))
        echo("================================\n")
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
elseif command == "pooptest" then
    -- Test error handling system
    if poopDeck.session and poopDeck.session.errorHandler then
        poopDeck.session.errorHandler:logInfo("Test info message", {test = "user_initiated"})
        poopDeck.session.errorHandler:logWarning("Test warning message", {test = "user_initiated"})
        poopDeck.session.errorHandler:logError("Test error message", {test = "user_initiated"})
        poopDeck.settingEcho("Test messages logged - check 'pooperrors' to see them")
    else
        poopDeck.badEcho("Error handler not initialized")
    end
    
else
    poopDeck.badEcho("Unknown error command: " .. command)
    echo("\n<yellow>Error Management Commands:</yellow>\n")
    echo("  <cyan>poopdebug</cyan> - Toggle debug logging on/off\n")
    echo("  <cyan>pooperrors</cyan> - Show recent error messages\n") 
    echo("  <cyan>poopclearerrors</cyan> - Clear error log\n")
    echo("  <cyan>pooplogging</cyan> - Toggle error display on/off\n")
    echo("  <cyan>pooploglevel[level]</cyan> - Set log level (debug/info/warn/error/fatal)\n")
    echo("  <cyan>pooperrorstatus</cyan> - Show error handler status\n")
    echo("  <cyan>pooptest</cyan> - Test error logging system\n")
end