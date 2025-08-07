-- Safety Wrappers
-- Safe versions of external function calls with error handling

poopDeck.safe = poopDeck.safe or {}

-- Get error handler instance
local function getErrorHandler()
    return poopDeck.session and poopDeck.session.errorHandler
end

-- Safe GMCP access
function poopDeck.safe.gmcp(path, defaultValue, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeGMCP(path, defaultValue, context)
    end
    
    -- Fallback for before error handler is initialized
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    if type(gmcp) ~= "table" then
        return defaultValue
    end
    
    local current = gmcp
    for _, part in ipairs(parts) do
        if type(current) ~= "table" or current[part] == nil then
            return defaultValue
        end
        current = current[part]
    end
    
    return current
end

-- Safe Mudlet function calls
function poopDeck.safe.send(command, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("send", false, context or "safe_send", command)
    end
    
    if type(_G.send) == "function" then
        return _G.send(command)
    end
    return false
end

function poopDeck.safe.echo(text, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("echo", false, context or "safe_echo", text)
    end
    
    if type(_G.echo) == "function" then
        return _G.echo(text)
    end
    print(text) -- Fallback to Lua print
    return false
end

function poopDeck.safe.hecho(text, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("hecho", false, context or "safe_hecho", text)
    end
    
    if type(_G.hecho) == "function" then
        return _G.hecho(text)
    end
    -- Fallback to regular echo, stripping color codes
    local cleanText = text:gsub("<[^>]*>", "")
    return poopDeck.safe.echo(cleanText, context)
end

function poopDeck.safe.cecho(text, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("cecho", false, context or "safe_cecho", text)
    end
    
    if type(_G.cecho) == "function" then
        return _G.cecho(text)
    end
    -- Fallback to regular echo, stripping color codes
    local cleanText = text:gsub("<[^>]*>", "")
    return poopDeck.safe.echo(cleanText, context)
end

function poopDeck.safe.tempTimer(delay, func, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("tempTimer", nil, context or "safe_tempTimer", delay, func)
    end
    
    if type(_G.tempTimer) == "function" then
        return _G.tempTimer(delay, func)
    end
    return nil
end

function poopDeck.safe.killTimer(timerId, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("killTimer", false, context or "safe_killTimer", timerId)
    end
    
    if type(_G.killTimer) == "function" and timerId then
        return _G.killTimer(timerId)
    end
    return false
end

-- Safe window operations
function poopDeck.safe.openUserWindow(windowName, floating, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("openUserWindow", false, 
            context or "safe_openUserWindow", windowName, floating)
    end
    
    if type(_G.openUserWindow) == "function" then
        return _G.openUserWindow(windowName, floating)
    end
    return false
end

function poopDeck.safe.closeUserWindow(windowName, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("closeUserWindow", false, 
            context or "safe_closeUserWindow", windowName)
    end
    
    if type(_G.closeUserWindow) == "function" then
        return _G.closeUserWindow(windowName)
    end
    return false
end

function poopDeck.safe.resizeUserWindow(windowName, width, height, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("resizeUserWindow", false, 
            context or "safe_resizeUserWindow", windowName, width, height)
    end
    
    if type(_G.resizeUserWindow) == "function" then
        return _G.resizeUserWindow(windowName, width, height)
    end
    return false
end

function poopDeck.safe.moveUserWindow(windowName, x, y, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("moveUserWindow", false, 
            context or "safe_moveUserWindow", windowName, x, y)
    end
    
    if type(_G.moveUserWindow) == "function" then
        return _G.moveUserWindow(windowName, x, y)
    end
    return false
end

function poopDeck.safe.clearUserWindow(windowName, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeMudletCall("clearUserWindow", false, 
            context or "safe_clearUserWindow", windowName)
    end
    
    if type(_G.clearUserWindow) == "function" then
        return _G.clearUserWindow(windowName)
    end
    return false
end

-- Safe file operations
function poopDeck.safe.fileExists(filePath, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeCall(function(path)
            return io.exists and io.exists(path) or false
        end, context or "safe_fileExists", filePath)
    end
    
    if type(io.exists) == "function" then
        return io.exists(filePath)
    end
    
    -- Fallback using io.open
    local file = io.open(filePath, "r")
    if file then
        file:close()
        return true
    end
    return false
end

function poopDeck.safe.saveTable(filePath, data, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeCall(function(path, tableData)
            if type(table.save) == "function" then
                return table.save(path, tableData)
            end
            return false
        end, context or "safe_saveTable", filePath, data)
    end
    
    if type(table.save) == "function" then
        return table.save(filePath, data)
    end
    return false
end

function poopDeck.safe.loadTable(filePath, context)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeCall(function(path)
            if type(table.load) == "function" and poopDeck.safe.fileExists(path) then
                return table.load(path)
            end
            return nil
        end, context or "safe_loadTable", filePath)
    end
    
    if type(table.load) == "function" and poopDeck.safe.fileExists(filePath) then
        return table.load(filePath)
    end
    return nil
end

-- Health and vitals helpers
function poopDeck.safe.getHealth(context)
    local currentHP = poopDeck.safe.gmcp("Char.Vitals.hp", "0", context)
    local maxHP = poopDeck.safe.gmcp("Char.Vitals.maxhp", "1", context)
    
    local current = tonumber(currentHP) or 0
    local max = tonumber(maxHP) or 1
    local percent = (current / max) * 100
    
    return {
        current = current,
        max = max,
        percent = percent
    }
end

function poopDeck.safe.getMana(context)
    local currentMP = poopDeck.safe.gmcp("Char.Vitals.mp", "0", context)
    local maxMP = poopDeck.safe.gmcp("Char.Vitals.maxmp", "1", context)
    
    local current = tonumber(currentMP) or 0
    local max = tonumber(maxMP) or 1
    local percent = (current / max) * 100
    
    return {
        current = current,
        max = max,
        percent = percent
    }
end

-- Safe function execution with automatic error logging
function poopDeck.safe.call(func, context, ...)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeCall(func, context, ...)
    end
    
    -- Fallback without error handling
    if type(func) == "function" then
        return pcall(func, ...)
    end
    
    return false, "Function is not callable"
end

function poopDeck.safe.callWithRecovery(func, recoveryFunc, context, ...)
    local errorHandler = getErrorHandler()
    if errorHandler then
        return errorHandler:safeCallWithRecovery(func, recoveryFunc, context, ...)
    end
    
    -- Fallback - try main function, then recovery
    local success, result = poopDeck.safe.call(func, context, ...)
    if not success and recoveryFunc then
        local recoverySuccess = poopDeck.safe.call(recoveryFunc, context .. "_recovery", ...)
        if recoverySuccess then
            -- Retry original function
            return poopDeck.safe.call(func, context .. "_retry", ...)
        end
    end
    
    return success, result
end