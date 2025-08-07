-- Command Service
-- Unified command management with error handling, help, and validation

poopDeck.services = poopDeck.services or {}

-- CommandService class definition  
poopDeck.services.CommandService = poopDeck.core.BaseClass:extend("CommandService")

function poopDeck.services.CommandService:initialize()
    -- Command registry
    self.commands = {}
    self.categories = {}
    self.aliases = {}
    
    -- Execution statistics
    self.statistics = {
        totalExecutions = 0,
        successfulExecutions = 0,
        failedExecutions = 0,
        executionTimes = {},
        commandUsage = {}
    }
    
    -- Settings
    self.settings = {
        trackStatistics = true,
        validateInputs = true,
        requirePermissions = false,
        logExecutions = false
    }
end

-- Enhanced Command class
function poopDeck.services.CommandService:createCommand(definition)
    local command = {
        -- Basic properties
        name = definition.name,
        category = definition.category or "General",
        aliases = definition.aliases or {},
        description = definition.description or "No description available",
        usage = definition.usage or definition.name,
        examples = definition.examples or {},
        
        -- Execution
        handler = definition.handler,
        context = definition.context or "unknown",
        
        -- Validation
        validate = definition.validate,
        permissions = definition.permissions or {},
        
        -- Help
        helpText = definition.helpText or definition.description,
        detailedHelp = definition.detailedHelp,
        
        -- Execution stats
        executionCount = 0,
        lastExecuted = nil,
        averageExecutionTime = 0,
        
        -- Error handling
        onError = definition.onError,
        retryOnFailure = definition.retryOnFailure or false,
        maxRetries = definition.maxRetries or 1
    }
    
    return command
end

-- Command registration
function poopDeck.services.CommandService:registerCommand(definition)
    if not definition.name then
        return false, "Command name is required"
    end
    
    if not definition.handler then
        return false, "Command handler is required"
    end
    
    -- Create command object
    local command = self:createCommand(definition)
    
    -- Register main command
    self.commands[definition.name] = command
    
    -- Register aliases
    for _, alias in ipairs(command.aliases) do
        self.aliases[alias] = definition.name
    end
    
    -- Add to category
    self.categories[command.category] = self.categories[command.category] or {}
    table.insert(self.categories[command.category], definition.name)
    
    self:emit("commandRegistered", definition.name, command)
    return true, "Command registered: " .. definition.name
end

-- Command execution with full error handling
function poopDeck.services.CommandService:executeCommand(commandName, args, context)
    local startTime = os.time()
    args = args or {}
    context = context or "user_input"
    
    -- Resolve alias to command name
    local actualCommandName = self.aliases[commandName] or commandName
    local command = self.commands[actualCommandName]
    
    if not command then
        self:logCommandError("Command not found", commandName, context)
        return false, "Unknown command: " .. commandName
    end
    
    -- Update statistics
    if self.settings.trackStatistics then
        self.statistics.totalExecutions = self.statistics.totalExecutions + 1
        self.statistics.commandUsage[actualCommandName] = 
            (self.statistics.commandUsage[actualCommandName] or 0) + 1
    end
    
    -- Validate permissions
    if self.settings.requirePermissions and #command.permissions > 0 then
        local hasPermission = self:checkPermissions(command.permissions, context)
        if not hasPermission then
            self:logCommandError("Permission denied", actualCommandName, context)
            return false, "Permission denied for command: " .. actualCommandName
        end
    end
    
    -- Validate inputs
    if self.settings.validateInputs and command.validate then
        local validationSuccess, validationError = poopDeck.safe.call(
            command.validate, 
            "validate_" .. actualCommandName, 
            args or {}
        )
        
        if not validationSuccess or validationError then
            self:logCommandError("Validation failed", actualCommandName, context, validationError)
            return false, "Invalid arguments: " .. (validationError or "validation failed")
        end
    end
    
    -- Execute command with error handling and retry logic
    local success, result, errorInfo = self:executeWithRetry(command, args, context)
    
    -- Update execution statistics
    local executionTime = os.time() - startTime
    command.executionCount = command.executionCount + 1
    command.lastExecuted = os.time()
    command.averageExecutionTime = (command.averageExecutionTime + executionTime) / 2
    
    if success then
        self.statistics.successfulExecutions = self.statistics.successfulExecutions + 1
        self:logCommandSuccess(actualCommandName, args, context, executionTime)
        self:emit("commandExecuted", actualCommandName, args, result)
    else
        self.statistics.failedExecutions = self.statistics.failedExecutions + 1
        self:logCommandError("Execution failed", actualCommandName, context, errorInfo)
        self:emit("commandFailed", actualCommandName, args, errorInfo)
    end
    
    return success, result
end

-- Command execution with retry logic
function poopDeck.services.CommandService:executeWithRetry(command, args, context)
    local maxAttempts = command.retryOnFailure and (command.maxRetries + 1) or 1
    local lastError = nil
    
    for attempt = 1, maxAttempts do
        local success, result, errorInfo = poopDeck.safe.call(
            command.handler, 
            command.context .. "_attempt_" .. attempt, 
            table.unpack(args)
        )
        
        if success then
            if attempt > 1 then
                self:logCommandSuccess(command.name, args, context, nil, "retry_successful")
            end
            return true, result
        end
        
        lastError = errorInfo or result
        
        -- Custom error handler
        if command.onError then
            local errorHandlerSuccess, shouldRetry = poopDeck.safe.call(
                command.onError,
                command.context .. "_error_handler",
                lastError, attempt, maxAttempts
            )
            
            if errorHandlerSuccess and not shouldRetry then
                break -- Custom error handler says don't retry
            end
        end
        
        if attempt < maxAttempts then
            self:logCommandError("Command failed, retrying", command.name, context, {
                attempt = attempt,
                maxAttempts = maxAttempts,
                error = lastError
            })
        end
    end
    
    return false, lastError
end

-- Logging helpers
function poopDeck.services.CommandService:logCommandSuccess(commandName, args, context, executionTime, note)
    if not self.settings.logExecutions then return end
    
    local errorHandler = poopDeck.session and poopDeck.session.errorHandler
    if errorHandler then
        errorHandler:logDebug("Command executed successfully", {
            command = commandName,
            args = args,
            context = context,
            executionTime = executionTime,
            note = note
        })
    end
end

function poopDeck.services.CommandService:logCommandError(message, commandName, context, details)
    local errorHandler = poopDeck.session and poopDeck.session.errorHandler
    if errorHandler then
        errorHandler:logError(message, {
            command = commandName,
            context = context,
            details = details
        })
    end
end

-- Permission checking (extensible)
function poopDeck.services.CommandService:checkPermissions(requiredPermissions, context)
    -- For now, all commands are allowed
    -- Future: integrate with user permissions, admin levels, etc.
    return true
end

-- Help system integration
function poopDeck.services.CommandService:getCommandHelp(commandName)
    local actualCommandName = self.aliases[commandName] or commandName
    local command = self.commands[actualCommandName]
    
    if not command then
        return nil, "Command not found: " .. commandName
    end
    
    local help = {
        name = command.name,
        category = command.category,
        description = command.description,
        usage = command.usage,
        aliases = command.aliases,
        examples = command.examples,
        helpText = command.helpText,
        detailedHelp = command.detailedHelp
    }
    
    return help
end

function poopDeck.services.CommandService:getCommandsByCategory(category)
    local commands = self.categories[category] or {}
    local result = {}
    
    for _, commandName in ipairs(commands) do
        local command = self.commands[commandName]
        if command then
            table.insert(result, {
                name = command.name,
                description = command.description,
                usage = command.usage,
                aliases = command.aliases
            })
        end
    end
    
    return result
end

function poopDeck.services.CommandService:getAllCategories()
    local categories = {}
    for category, _ in pairs(self.categories) do
        table.insert(categories, category)
    end
    table.sort(categories)
    return categories
end

-- Command discovery and listing
function poopDeck.services.CommandService:findCommands(pattern)
    local matches = {}
    pattern = pattern:lower()
    
    -- Search command names
    for commandName, command in pairs(self.commands) do
        if commandName:lower():find(pattern) then
            table.insert(matches, {
                name = commandName,
                type = "command",
                description = command.description,
                category = command.category
            })
        end
    end
    
    -- Search aliases
    for alias, commandName in pairs(self.aliases) do
        if alias:lower():find(pattern) then
            local command = self.commands[commandName]
            table.insert(matches, {
                name = alias,
                type = "alias",
                command = commandName,
                description = command and command.description or "No description"
            })
        end
    end
    
    -- Search descriptions
    for commandName, command in pairs(self.commands) do
        if command.description:lower():find(pattern) and 
           not commandName:lower():find(pattern) then
            table.insert(matches, {
                name = commandName,
                type = "description_match",
                description = command.description,
                category = command.category
            })
        end
    end
    
    return matches
end

-- Statistics and reporting
function poopDeck.services.CommandService:getStatistics()
    return {
        totalCommands = table.size(self.commands),
        totalAliases = table.size(self.aliases),
        totalCategories = table.size(self.categories),
        totalExecutions = self.statistics.totalExecutions,
        successfulExecutions = self.statistics.successfulExecutions,
        failedExecutions = self.statistics.failedExecutions,
        successRate = self.statistics.totalExecutions > 0 and 
            (self.statistics.successfulExecutions / self.statistics.totalExecutions) * 100 or 0,
        mostUsedCommands = self:getMostUsedCommands(5)
    }
end

function poopDeck.services.CommandService:getMostUsedCommands(count)
    local sorted = {}
    for commandName, usage in pairs(self.statistics.commandUsage) do
        table.insert(sorted, {name = commandName, usage = usage})
    end
    
    table.sort(sorted, function(a, b) return a.usage > b.usage end)
    
    local result = {}
    for i = 1, math.min(count, #sorted) do
        table.insert(result, sorted[i])
    end
    
    return result
end

-- Settings management
function poopDeck.services.CommandService:enableStatistics()
    self.settings.trackStatistics = true
    self:emit("settingChanged", "trackStatistics", true)
end

function poopDeck.services.CommandService:disableStatistics()
    self.settings.trackStatistics = false
    self:emit("settingChanged", "trackStatistics", false)
end

function poopDeck.services.CommandService:enableLogging()
    self.settings.logExecutions = true
    self:emit("settingChanged", "logExecutions", true)
end

function poopDeck.services.CommandService:disableLogging()
    self.settings.logExecutions = false
    self:emit("settingChanged", "logExecutions", false)
end

function poopDeck.services.CommandService:getStatus()
    return {
        commands = table.size(self.commands),
        aliases = table.size(self.aliases),
        categories = table.size(self.categories),
        statistics = self.settings.trackStatistics,
        logging = self.settings.logExecutions,
        validation = self.settings.validateInputs
    }
end

function poopDeck.services.CommandService:toString()
    return string.format("[CommandService: %d commands, %d aliases, %d categories]", 
        table.size(self.commands), table.size(self.aliases), table.size(self.categories))
end