poopDeck = poopDeck or {}
poopDeck.help = {}
poopDeck.help.HelpManager = {}
poopDeck.help.HelpManager.__index = poopDeck.help.HelpManager

-- HelpManager Class
function poopDeck.help.HelpManager:new(config)
    local instance = setmetatable({}, poopDeck.help.HelpManager)
    instance.config = config
    instance.categories = {}
    return instance
end

function poopDeck.help.HelpManager:addCategory(name, entries)
    self.categories[name] = poopDeck.help.Category:new(name, entries, self.config)
end

function poopDeck.help.HelpManager:createHelp()
    if self.config.headerName then
        poopDeck.help.Header:new(self.config):display()
    end

    -- Use global longest lengths for consistent spacing
    local globalLongestCommandLength, globalLongestAliasLength = poopDeck.help.Utils.addCategoriesFromManager(self, poopDeck.command.manager)

    for _, category in pairs(self.categories) do
        category:display(globalLongestCommandLength, globalLongestAliasLength)
    end

    poopDeck.help.Footer:new(self.config):display()
end

-- Header Class
poopDeck.help.Header = {}
poopDeck.help.Header.__index = poopDeck.help.Header

function poopDeck.help.Header:new(config)
    local instance = setmetatable({}, poopDeck.help.Header)
    instance.config = config
    return instance
end

function poopDeck.help.Header:display()
    local name = self.config.headerName
    local borderC = self.config.borderColor
    local headerFooterColor = self.config.headerFooterColor
    local totalWidth = self.config.width

    local headerLine = string.format("#%s┌─#%s%s#%s─┐#r", borderC, headerFooterColor, name, borderC)
    local bottomLine = "#" .. borderC .. string.rep("─", totalWidth)
    local header = string.format("#%s\n%s\n%s#r", borderC, headerLine, bottomLine)
    hecho(header .. "\n")
end

-- Footer Class
poopDeck.help.Footer = {}
poopDeck.help.Footer.__index = poopDeck.help.Footer

function poopDeck.help.Footer:new(config)
    local instance = setmetatable({}, poopDeck.help.Footer)
    instance.config = config
    return instance
end

function poopDeck.help.Footer:display()
    local name = self.config.footerName
    local borderC = self.config.borderColor
    local headerFooterColor = self.config.headerFooterColor
    local totalWidth = self.config.width

    local topLine = "#" .. borderC .. string.rep("─", totalWidth)
    local paddingLength = totalWidth - #name - 4 -- 4 accounts for "└─" and "─┘"
    local footerLine = string.format("#%s└─#%s%s#%s─┘", borderC, headerFooterColor, name, borderC)
    local paddedFooterLine = string.rep(" ", paddingLength) .. footerLine
    local footer = string.format("#%s%s\n%s#r", borderC, topLine, paddedFooterLine)
    hecho(footer .. "\n")
end

-- Category Class
poopDeck.help.Category = {}
poopDeck.help.Category.__index = poopDeck.help.Category

function poopDeck.help.Category:new(name, entries, config)
    local instance = setmetatable({}, poopDeck.help.Category)
    instance.name = name
    instance.entries = entries
    instance.config = config
    return instance
end

function poopDeck.help.Category:display(globalLongestCommandLength, globalLongestAliasLength)
    local categoryNameFormatted = string.format("#%s[%s]#r", self.config.categoryColor, self.name)
    hecho(categoryNameFormatted .. "\n")

    -- Alphabetize entries
    local sortedEntries = {}
    for command, data in pairs(self.entries) do
        table.insert(sortedEntries, {command = command, alias = data.alias, description = data.description})
    end
    table.sort(sortedEntries, function(a, b) return a.command < b.command end)

    -- Use global longest lengths for alignment
    for _, entry in ipairs(sortedEntries) do
        poopDeck.help.Utils.addEntry(
            entry.command,
            entry.alias,
            entry.description,
            self.config.commandColor,
            self.config.aliasColor,
            self.config.descriptionColor,
            globalLongestCommandLength,
            globalLongestAliasLength
        )
    end
end


-- Utility Functions
poopDeck.help.Utils = {}

function poopDeck.help.Utils.calculateLongestLengths(entries)
    local longestCommandLength = 0
    local longestAliasLength = 0

    for _, data in pairs(entries) do
        local commandLength = #poopDeck.help.Utils.stripColorCodes(data.command)
        local aliasLength = #poopDeck.help.Utils.stripColorCodes(data.alias)

        longestCommandLength = math.max(longestCommandLength, commandLength)
        longestAliasLength = math.max(longestAliasLength, aliasLength)
    end

    return longestCommandLength, longestAliasLength
end

function poopDeck.help.Utils.addEntry(command, alias, description, cmdColor, aliasColor, descColor, cmdWidth, aliasWidth)
    -- Inline color codes for each part
    local commandStyled = string.format("<%s>%s<%s>", cmdColor, command, "reset")
    local aliasStyled = string.format("<%s>%s<%s>", aliasColor, alias, "reset")
    local descriptionStyled = string.format("<%s>%s<%s>", descColor, description, "reset")

    -- Strip color codes to calculate visible lengths
    local visibleCommandLength = #poopDeck.help.Utils.stripColorCodes(command)
    local visibleAliasLength = #poopDeck.help.Utils.stripColorCodes(alias)

    -- Calculate spacing
    local commandSpacing = string.rep(" ", cmdWidth - visibleCommandLength + 5)
    local aliasSpacing = string.rep(" ", aliasWidth - visibleAliasLength + 3)

    -- Construct the final line
    local line = commandStyled .. commandSpacing .. "<orange>| " .. aliasStyled .. aliasSpacing .. "<orange>| " .. descriptionStyled

    -- Use cecho for output
    cecho(line .. "\n")
end

function poopDeck.help.Utils.stripColorCodes(input)
    return input:gsub("#%x%x%x%x%x%x", ""):gsub("<%a+>", ""):gsub("</%a+>", "")
end

function poopDeck.help.Utils.addCategoriesFromManager(helpManager, manager)
    local categorizedCommands = {}
    local globalLongestCommandLength = 0
    local globalLongestAliasLength = 0

    -- Group commands by category and calculate global longest lengths
    for name, commandObj in pairs(manager.commands) do
        local categoryName = commandObj.category or "Uncategorized"
        categorizedCommands[categoryName] = categorizedCommands[categoryName] or {}
        categorizedCommands[categoryName][name] = {
            command = name,
            alias = commandObj.alias or "No alias",
            description = commandObj.helpText
        }

        -- Update global longest lengths
        globalLongestCommandLength = math.max(globalLongestCommandLength, #name)
        globalLongestAliasLength = math.max(globalLongestAliasLength, #commandObj.alias or "No alias")
    end

    -- Sort category names alphabetically
    local sortedCategoryNames = {}
    for categoryName, _ in pairs(categorizedCommands) do
        table.insert(sortedCategoryNames, categoryName)
    end
    table.sort(sortedCategoryNames)

    -- Add categories to the help manager in sorted order
    for _, categoryName in ipairs(sortedCategoryNames) do
        local entries = categorizedCommands[categoryName]
        if next(entries) then
            helpManager:addCategory(categoryName, entries)
        end
    end

    -- Return global longest lengths for alignment
    return globalLongestCommandLength, globalLongestAliasLength
end


function poopDeck.help.Utils.wrapText(text, width)
    local lines = {}
    local currentLine = ""

    for word in text:gmatch("%S+") do
        if #currentLine + #word + 1 > width then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = currentLine == "" and word or (currentLine .. " " .. word)
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

function poopDeck.help.displayDynamicHelp(name)
    local config = {
        headerName = name,
        footerName = "poopDeck",
        borderColor = "00557F",
        commandColor = "honeydew",
        aliasColor = "sky_blue",
        descriptionColor = "honeydew",
        headerFooterColor = "F0F0F0",
        categoryColor = "FFD700",
        width = getWindowWrap("main")
    }

    local helpManager = poopDeck.help.HelpManager:new(config)
    poopDeck.help.Utils.addCategoriesFromManager(helpManager, poopDeck.command.manager)
    helpManager:createHelp()
end

-- Convenience function for direct help configuration objects
function poopDeck.createHelp(helpConfig)
    if not helpConfig or not helpConfig.config then
        poopDeck.badEcho("Invalid help configuration provided")
        return
    end
    
    local helpManager = poopDeck.help.HelpManager:new(helpConfig.config)
    
    -- Add categories from the help configuration
    if helpConfig.categories then
        for categoryName, entries in pairs(helpConfig.categories) do
            helpManager:addCategory(categoryName, entries)
        end
    end
    
    -- Add entries if provided (for simple help configs)
    if helpConfig.entries then
        helpManager:addCategory("Commands", helpConfig.entries)
    end
    
    helpManager:createHelp()
end