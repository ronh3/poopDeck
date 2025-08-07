-- Error Handling Service
-- Centralized error management, logging, and recovery

poopDeck.services = poopDeck.services or {}

-- ErrorHandlingService class definition
poopDeck.services.ErrorHandlingService = poopDeck.core.BaseClass:extend("ErrorHandlingService")

function poopDeck.services.ErrorHandlingService:initialize(config)
    config = config or {}
    
    -- Error handling settings
    self.settings = {
        enabled = config.enabled ~= false,
        logLevel = config.logLevel or "warn", -- "debug", "info", "warn", "error", "fatal"
        maxLogEntries = config.maxLogEntries or 1000,
        displayErrors = config.displayErrors ~= false,
        suppressDuplicates = config.suppressDuplicates ~= false,
        crashRecovery = config.crashRecovery ~= false
    }
    
    -- Log levels hierarchy
    self.logLevels = {
        debug = 1,
        info = 2,
        warn = 3,
        error = 4,
        fatal = 5
    }
    
    -- Error log storage
    self.errorLog = {}
    self.errorCounts = {} -- For duplicate suppression
    
    -- Recovery state
    self.recoveryAttempts = {}
    self.maxRecoveryAttempts = 3
    
    -- External API safety checks
    self.externalAPIs = {
        mudlet = {
            available = true,
            functions = {
                "openUserWindow", "closeUserWindow", "resizeUserWindow", 
                "moveUserWindow", "setUserWindowTitle", "clearUserWindow",
                "echo", "hecho", "cecho", "send", "tempTimer", "killTimer"
            }
        },
        gmcp = {
            available = true,
            lastCheck = 0,
            checkInterval = 30 -- seconds
        }
    }
    
    -- Initialize error tracking
    self:checkExternalAPIs()
end

-- Core error handling methods
function poopDeck.services.ErrorHandlingService:safeCall(func, context, ...)
    if not func then
        return false, self:logError("Function is nil", context, "error")
    end
    
    local success, result, errorMsg = xpcall(func, debug.traceback, ...)
    
    if not success then
        local errorInfo = {
            context = context or "unknown",
            error = result, -- xpcall puts error message in result when success=false
            traceback = result:match("stack traceback:(.*)") or "no traceback",
            timestamp = os.time(),
            args = {...}
        }
        
        self:logError("Function call failed", errorInfo, "error")
        return false, errorInfo.error, errorInfo
    end
    
    return true, result, errorMsg
end

function poopDeck.services.ErrorHandlingService:safeCallWithRecovery(func, recoveryFunc, context, ...)
    local success, result, errorInfo = self:safeCall(func, context, ...)
    
    if not success and recoveryFunc then
        local recoveryKey = context or "unknown"
        local attempts = self.recoveryAttempts[recoveryKey] or 0
        
        if attempts < self.maxRecoveryAttempts then
            self.recoveryAttempts[recoveryKey] = attempts + 1
            
            self:logInfo("Attempting recovery", {
                context = context,
                attempt = attempts + 1,
                maxAttempts = self.maxRecoveryAttempts
            })
            
            local recoverySuccess = self:safeCall(recoveryFunc, context .. "_recovery", ...)
            if recoverySuccess then
                self.recoveryAttempts[recoveryKey] = nil -- Reset on success
                return self:safeCall(func, context .. "_retry", ...) -- Retry original
            end
        else
            self:logError("Recovery attempts exhausted", {
                context = context,
                attempts = attempts
            }, "fatal")
        end
    end
    
    return success, result, errorInfo
end

-- Logging methods
function poopDeck.services.ErrorHandlingService:log(level, message, details, skipDisplay)
    if not self.settings.enabled then
        return
    end
    
    local levelNum = self.logLevels[level] or self.logLevels.info
    local currentLevelNum = self.logLevels[self.settings.logLevel] or self.logLevels.warn
    
    if levelNum < currentLevelNum then
        return -- Below log threshold
    end
    
    -- Create log entry
    local logEntry = {
        timestamp = os.time(),
        level = level,
        message = message,
        details = details,
        formattedTime = os.date("%H:%M:%S", os.time())
    }
    
    -- Check for duplicate suppression
    local logKey = level .. ":" .. message
    if self.settings.suppressDuplicates then
        self.errorCounts[logKey] = (self.errorCounts[logKey] or 0) + 1
        if self.errorCounts[logKey] > 1 then
            logEntry.suppressedCount = self.errorCounts[logKey]
        end
    end
    
    -- Add to log storage
    table.insert(self.errorLog, logEntry)
    
    -- Trim log if too large
    if #self.errorLog > self.settings.maxLogEntries then
        table.remove(self.errorLog, 1)
    end
    
    -- Display if appropriate
    if self.settings.displayErrors and not skipDisplay and 
       (not self.settings.suppressDuplicates or self.errorCounts[logKey] <= 3) then
        self:displayError(logEntry)
    end
    
    -- Emit event for other services
    self:emit("logged", logEntry)
    
    return logEntry
end

function poopDeck.services.ErrorHandlingService:logDebug(message, details)
    return self:log("debug", message, details)
end

function poopDeck.services.ErrorHandlingService:logInfo(message, details)
    return self:log("info", message, details)
end

function poopDeck.services.ErrorHandlingService:logWarning(message, details)
    return self:log("warn", message, details)
end

function poopDeck.services.ErrorHandlingService:logError(message, details, level)
    return self:log(level or "error", message, details)
end

function poopDeck.services.ErrorHandlingService:logFatal(message, details)
    return self:log("fatal", message, details)
end

-- External API safety wrappers
function poopDeck.services.ErrorHandlingService:safeGMCP(path, defaultValue, context)
    if not self:checkGMCPAvailable() then
        self:logWarning("GMCP not available", {path = path, context = context})
        return defaultValue
    end
    
    local success, result = self:safeCall(function()
        local parts = {}
        for part in path:gmatch("[^%.]+") do
            table.insert(parts, part)
        end
        
        local current = gmcp
        for _, part in ipairs(parts) do
            if type(current) ~= "table" or current[part] == nil then
                return defaultValue
            end
            current = current[part]
        end
        
        return current
    end, "gmcp_access_" .. path)
    
    return success and result or defaultValue
end

function poopDeck.services.ErrorHandlingService:safeMudletCall(functionName, errorReturn, context, ...)
    if not self:checkMudletFunction(functionName) then
        self:logError("Mudlet function not available", {
            function_name = functionName,
            context = context
        })
        return errorReturn
    end
    
    local func = _G[functionName]
    local success, result = self:safeCall(func, "mudlet_" .. functionName, ...)
    
    if not success then
        return errorReturn
    end
    
    return result
end

-- API availability checking
function poopDeck.services.ErrorHandlingService:checkExternalAPIs()
    -- Check GMCP
    self.externalAPIs.gmcp.available = (type(gmcp) == "table")
    self.externalAPIs.gmcp.lastCheck = os.time()
    
    -- Check Mudlet functions
    for _, funcName in ipairs(self.externalAPIs.mudlet.functions) do
        if type(_G[funcName]) ~= "function" then
            self.externalAPIs.mudlet.available = false
            self:logError("Missing Mudlet function", {function_name = funcName}, "warn")
        end
    end
end

function poopDeck.services.ErrorHandlingService:checkGMCPAvailable()
    local now = os.time()
    if (now - self.externalAPIs.gmcp.lastCheck) > self.externalAPIs.gmcp.checkInterval then
        self.externalAPIs.gmcp.available = (type(gmcp) == "table")
        self.externalAPIs.gmcp.lastCheck = now
    end
    
    return self.externalAPIs.gmcp.available
end

function poopDeck.services.ErrorHandlingService:checkMudletFunction(functionName)
    return type(_G[functionName]) == "function"
end

-- Error display
function poopDeck.services.ErrorHandlingService:displayError(logEntry)
    local color = {
        debug = "#888888",
        info = "#00FFFF", 
        warn = "#FFFF00",
        error = "#FF6600",
        fatal = "#FF0000"
    }
    
    local prefix = {
        debug = "🔧",
        info = "ℹ️",
        warn = "⚠️",
        error = "❌",
        fatal = "💀"
    }
    
    local levelColor = color[logEntry.level] or "#FFFFFF"
    local levelPrefix = prefix[logEntry.level] or "•"
    
    -- Format message
    local message = string.format("[%s] %s poopDeck %s: %s", 
        logEntry.formattedTime,
        levelPrefix,
        logEntry.level:upper(),
        logEntry.message
    )
    
    if logEntry.suppressedCount and logEntry.suppressedCount > 1 then
        message = message .. string.format(" (×%d)", logEntry.suppressedCount)
    end
    
    -- Display using appropriate method
    if self:checkMudletFunction("cecho") then
        cecho(string.format("<%s>%s<reset>\n", levelColor, message))
    else
        echo(message .. "\n")
    end
    
    -- Show details if error level or higher
    if self.logLevels[logEntry.level] >= self.logLevels.error and logEntry.details then
        if type(logEntry.details) == "table" then
            for key, value in pairs(logEntry.details) do
                echo(string.format("  %s: %s\n", key, tostring(value)))
            end
        else
            echo(string.format("  Details: %s\n", tostring(logEntry.details)))
        end
    end
end

-- Log management
function poopDeck.services.ErrorHandlingService:getRecentErrors(count, level)
    count = count or 10
    local filtered = {}
    
    for i = #self.errorLog, 1, -1 do
        local entry = self.errorLog[i]
        if not level or entry.level == level then
            table.insert(filtered, entry)
            if #filtered >= count then
                break
            end
        end
    end
    
    return filtered
end

function poopDeck.services.ErrorHandlingService:clearErrorLog()
    self.errorLog = {}
    self.errorCounts = {}
    self.recoveryAttempts = {}
    self:logInfo("Error log cleared")
end

function poopDeck.services.ErrorHandlingService:exportErrorLog()
    local logData = {
        timestamp = os.time(),
        version = poopDeck.version or "unknown",
        settings = self.settings,
        errors = self.errorLog,
        systemInfo = {
            gmcpAvailable = self.externalAPIs.gmcp.available,
            mudletAvailable = self.externalAPIs.mudlet.available
        }
    }
    
    return logData
end

-- Settings management
function poopDeck.services.ErrorHandlingService:setLogLevel(level)
    if not self.logLevels[level] then
        return false, "Invalid log level: " .. tostring(level)
    end
    
    self.settings.logLevel = level
    self:logInfo("Log level changed", {new_level = level})
    self:emit("settingChanged", "logLevel", level)
    return true, "Log level set to " .. level
end

function poopDeck.services.ErrorHandlingService:toggleDisplayErrors()
    self.settings.displayErrors = not self.settings.displayErrors
    local status = self.settings.displayErrors and "enabled" or "disabled"
    self:logInfo("Error display " .. status)
    return true, "Error display " .. status
end

function poopDeck.services.ErrorHandlingService:getStatus()
    local recentErrors = #self.getRecentErrors and #self:getRecentErrors(100) or 0
    
    return {
        enabled = self.settings.enabled,
        logLevel = self.settings.logLevel,
        totalLogEntries = #self.errorLog,
        recentErrors = recentErrors,
        gmcpAvailable = self.externalAPIs.gmcp.available,
        mudletAvailable = self.externalAPIs.mudlet.available
    }
end

function poopDeck.services.ErrorHandlingService:toString()
    return string.format("[ErrorHandlingService: %s, %d entries logged]", 
        self.settings.enabled and "enabled" or "disabled",
        #self.errorLog)
end