-- Load spec helper
require('spec.spec_helper')

-- Configuration persistence tests
describe("poopDeck Configuration Persistence", function()
    
    before_each(function()
        -- Initialize test environment
        poopDeck = poopDeck or {}
        poopDeck.services = poopDeck.services or {}
        poopDeck.config = poopDeck.config or {}
        
        -- Mock file system operations
        _G.mockFileSystem = {
            files = {},
            exists = function(path)
                return _G.mockFileSystem.files[path] ~= nil
            end,
            read = function(path)
                return _G.mockFileSystem.files[path]
            end,
            write = function(path, content)
                _G.mockFileSystem.files[path] = content
                return true
            end,
            delete = function(path)
                _G.mockFileSystem.files[path] = nil
                return true
            end
        }
        
        -- Mock Mudlet file functions
        io.exists = function(path)
            return _G.mockFileSystem.exists(path)
        end
        
        -- Override io.open for reading
        _G.originalIoOpen = io.open
        io.open = function(path, mode)
            if mode == "r" then
                if _G.mockFileSystem.exists(path) then
                    local content = _G.mockFileSystem.read(path)
                    return {
                        read = function(self, format)
                            if format == "*all" or format == "*a" then
                                return content
                            end
                            return content
                        end,
                        close = function() end
                    }
                end
                return nil
            elseif mode == "w" then
                return {
                    write = function(self, content)
                        _G.mockFileSystem.write(path, content)
                    end,
                    close = function() end
                }
            end
            return _G.originalIoOpen(path, mode)
        end
        
        -- Mock JSON encoding/decoding
        yajl = yajl or {}
        yajl.to_string = function(data)
            -- Simple JSON encoder for testing
            if type(data) == "table" then
                local result = "{"
                local first = true
                for k, v in pairs(data) do
                    if not first then result = result .. "," end
                    result = result .. '"' .. tostring(k) .. '":'
                    if type(v) == "string" then
                        result = result .. '"' .. v .. '"'
                    elseif type(v) == "boolean" then
                        result = result .. tostring(v)
                    elseif type(v) == "number" then
                        result = result .. tostring(v)
                    elseif type(v) == "table" then
                        result = result .. yajl.to_string(v)
                    end
                    first = false
                end
                result = result .. "}"
                return result
            end
            return tostring(data)
        end
        
        yajl.to_value = function(jsonString)
            -- Simple JSON decoder for testing
            if not jsonString then return nil end
            
            -- Handle basic cases for testing
            if jsonString == '{"defaultBait":"bass","defaultCastDistance":"medium","baitSource":"tank","autoRestart":true}' then
                return {
                    defaultBait = "bass",
                    defaultCastDistance = "medium", 
                    baitSource = "tank",
                    autoRestart = true
                }
            elseif jsonString:match('"defaultBait":"shrimp"') then
                return {
                    defaultBait = "shrimp",
                    defaultCastDistance = "long",
                    baitSource = "inventory",
                    autoRestart = false
                }
            end
            
            return {}
        end
        
        -- Create ConfigurationService
        poopDeck.services.ConfigurationService = {
            new = function(self, configPath)
                local instance = setmetatable({}, {__index = self})
                instance.configPath = configPath or "poopDeck_config.json"
                instance.config = {}
                instance.defaults = {
                    fishing = {
                        defaultBait = "bass",
                        defaultCastDistance = "medium",
                        baitSource = "tank",
                        autoRestart = true,
                        maxRetries = 3,
                        retryDelay = 5,
                        enabled = true
                    },
                    seamonster = {
                        autoSeaMonster = false,
                        sipHealthPercent = 75,
                        weapon = "ballista"
                    },
                    notifications = {
                        fiveMinuteWarning = true,
                        oneMinuteWarning = true,
                        timeToFish = true
                    }
                }
                instance:loadConfig()
                return instance
            end,
            
            loadConfig = function(self)
                if io.exists(self.configPath) then
                    local file = io.open(self.configPath, "r")
                    if file then
                        local content = file:read("*all")
                        file:close()
                        
                        local success, data = pcall(yajl.to_value, content)
                        if success and data then
                            self.config = data
                            return true
                        end
                    end
                end
                
                -- Use defaults if no config file or load failed
                self.config = self:deepCopy(self.defaults)
                return false
            end,
            
            saveConfig = function(self)
                local success, jsonString = pcall(yajl.to_string, self.config)
                if not success then
                    return false, "Failed to serialize configuration"
                end
                
                local file = io.open(self.configPath, "w")
                if not file then
                    return false, "Failed to open config file for writing"
                end
                
                file:write(jsonString)
                file:close()
                return true
            end,
            
            get = function(self, section, key)
                if section and key then
                    return self.config[section] and self.config[section][key]
                elseif section then
                    return self.config[section]
                end
                return self.config
            end,
            
            set = function(self, section, key, value)
                if section and key then
                    self.config[section] = self.config[section] or {}
                    self.config[section][key] = value
                elseif section then
                    self.config[section] = value
                end
                return self:saveConfig()
            end,
            
            reset = function(self, section)
                if section then
                    self.config[section] = self:deepCopy(self.defaults[section])
                else
                    self.config = self:deepCopy(self.defaults)
                end
                return self:saveConfig()
            end,
            
            deepCopy = function(self, obj)
                if type(obj) ~= "table" then return obj end
                local copy = {}
                for k, v in pairs(obj) do
                    copy[k] = self:deepCopy(v)
                end
                return copy
            end
        }
        
        -- Create FishingService with persistence integration
        poopDeck.services.FishingService = {
            new = function(self, config, configService)
                local instance = setmetatable({}, {__index = self})
                instance.configService = configService
                
                -- Load settings from persistent config
                local fishingConfig = configService:get("fishing") or {}
                
                instance.equipment = {
                    currentBait = fishingConfig.defaultBait or "bass",
                    currentCastDistance = fishingConfig.defaultCastDistance or "medium",
                    currentBaitSource = fishingConfig.baitSource or "tank"
                }
                
                instance.autoRestart = fishingConfig.autoRestart ~= false
                instance.maxRetries = fishingConfig.maxRetries or 3
                instance.retryDelay = fishingConfig.retryDelay or 5
                instance.enabled = fishingConfig.enabled ~= false
                
                instance.stats = {
                    totalCasts = 0,
                    totalCatches = 0,
                    escapes = 0,
                    sessionStart = os.time()
                }
                
                return instance
            end,
            
            setBait = function(self, bait)
                self.equipment.currentBait = bait
                return self.configService:set("fishing", "defaultBait", bait)
            end,
            
            setCastDistance = function(self, distance)
                self.equipment.currentCastDistance = distance
                return self.configService:set("fishing", "defaultCastDistance", distance)
            end,
            
            setBaitSource = function(self, source)
                if source ~= "tank" and source ~= "inventory" and source ~= "fishbucket" then
                    return false, "Invalid bait source"
                end
                self.equipment.currentBaitSource = source
                return self.configService:set("fishing", "baitSource", source)
            end,
            
            setAutoRestart = function(self, enabled)
                self.autoRestart = enabled
                return self.configService:set("fishing", "autoRestart", enabled)
            end,
            
            setMaxRetries = function(self, retries)
                self.maxRetries = retries
                return self.configService:set("fishing", "maxRetries", retries)
            end,
            
            setEnabled = function(self, enabled)
                self.enabled = enabled
                return self.configService:set("fishing", "enabled", enabled)
            end,
            
            getConfiguration = function(self)
                return {
                    defaultBait = self.equipment.currentBait,
                    defaultCastDistance = self.equipment.currentCastDistance,
                    baitSource = self.equipment.currentBaitSource,
                    autoRestart = self.autoRestart,
                    maxRetries = self.maxRetries,
                    retryDelay = self.retryDelay,
                    enabled = self.enabled
                }
            end
        }
        
        -- Clear mock filesystem
        _G.mockFileSystem.files = {}
        
        -- Clear test state
        _G.lastConfigSaved = nil
        _G.lastConfigLoaded = nil
    end)
    
    after_each(function()
        -- Restore original io.open if it was mocked
        if _G.originalIoOpen then
            io.open = _G.originalIoOpen
            _G.originalIoOpen = nil
        end
    end)
    
    describe("ConfigurationService basic operations", function()
        local configService
        
        before_each(function()
            configService = poopDeck.services.ConfigurationService:new("test_config.json")
        end)
        
        it("should initialize with default configuration", function()
            assert.is_not_nil(configService.config)
            assert.is_not_nil(configService.config.fishing)
            assert.are.equal("bass", configService.config.fishing.defaultBait)
            assert.are.equal("medium", configService.config.fishing.defaultCastDistance)
            assert.are.equal("tank", configService.config.fishing.baitSource)
            assert.are.equal(true, configService.config.fishing.autoRestart)
        end)
        
        it("should save configuration to file", function()
            local success = configService:saveConfig()
            
            assert.are.equal(true, success)
            assert.are.equal(true, _G.mockFileSystem.exists("test_config.json"))
            
            local content = _G.mockFileSystem.read("test_config.json")
            assert.is_not_nil(content)
            assert.truthy(content:match('"defaultBait"'))
        end)
        
        it("should load existing configuration from file", function()
            -- Pre-populate config file
            local testConfig = '{"fishing":{"defaultBait":"shrimp","defaultCastDistance":"long","baitSource":"inventory","autoRestart":false}}'
            _G.mockFileSystem.write("test_config.json", testConfig)
            
            -- Create new service instance (should load from file)
            local newService = poopDeck.services.ConfigurationService:new("test_config.json")
            
            assert.are.equal("shrimp", newService.config.fishing.defaultBait)
            assert.are.equal("long", newService.config.fishing.defaultCastDistance)
            assert.are.equal("inventory", newService.config.fishing.baitSource)
            assert.are.equal(false, newService.config.fishing.autoRestart)
        end)
        
        it("should handle missing config file gracefully", function()
            local newService = poopDeck.services.ConfigurationService:new("nonexistent.json")
            
            -- Should use defaults
            assert.are.equal("bass", newService.config.fishing.defaultBait)
            assert.are.equal(true, newService.config.fishing.autoRestart)
        end)
    end)
    
    describe("Configuration get/set operations", function()
        local configService
        
        before_each(function()
            configService = poopDeck.services.ConfigurationService:new()
        end)
        
        it("should get configuration values", function()
            local fishingConfig = configService:get("fishing")
            assert.is_not_nil(fishingConfig)
            assert.are.equal("bass", fishingConfig.defaultBait)
            
            local bait = configService:get("fishing", "defaultBait")
            assert.are.equal("bass", bait)
        end)
        
        it("should set and persist configuration values", function()
            local success = configService:set("fishing", "defaultBait", "shrimp")
            assert.are.equal(true, success)
            
            -- Verify value was set
            assert.are.equal("shrimp", configService:get("fishing", "defaultBait"))
            
            -- Verify persistence
            assert.are.equal(true, _G.mockFileSystem.exists(configService.configPath))
        end)
        
        it("should set entire sections", function()
            local newFishingConfig = {
                defaultBait = "worms",
                defaultCastDistance = "short",
                baitSource = "fishbucket",
                autoRestart = false
            }
            
            local success = configService:set("fishing", newFishingConfig)
            assert.are.equal(true, success)
            
            local retrieved = configService:get("fishing")
            assert.are.equal("worms", retrieved.defaultBait)
            assert.are.equal("short", retrieved.defaultCastDistance)
            assert.are.equal("fishbucket", retrieved.baitSource)
            assert.are.equal(false, retrieved.autoRestart)
        end)
        
        it("should reset configuration to defaults", function()
            -- Change some values
            configService:set("fishing", "defaultBait", "changed")
            configService:set("fishing", "autoRestart", false)
            
            -- Reset fishing section
            local success = configService:reset("fishing")
            assert.are.equal(true, success)
            
            -- Verify defaults restored
            assert.are.equal("bass", configService:get("fishing", "defaultBait"))
            assert.are.equal(true, configService:get("fishing", "autoRestart"))
        end)
        
        it("should reset entire configuration", function()
            -- Change values
            configService:set("fishing", "defaultBait", "changed")
            configService:set("seamonster", "autoSeaMonster", true)
            
            -- Reset everything
            local success = configService:reset()
            assert.are.equal(true, success)
            
            -- Verify all defaults restored
            assert.are.equal("bass", configService:get("fishing", "defaultBait"))
            assert.are.equal(false, configService:get("seamonster", "autoSeaMonster"))
        end)
    end)
    
    describe("FishingService persistence integration", function()
        local configService
        local fishingService
        
        before_each(function()
            configService = poopDeck.services.ConfigurationService:new()
            fishingService = poopDeck.services.FishingService:new({}, configService)
        end)
        
        it("should load fishing configuration on initialization", function()
            assert.are.equal("bass", fishingService.equipment.currentBait)
            assert.are.equal("medium", fishingService.equipment.currentCastDistance)
            assert.are.equal("tank", fishingService.equipment.currentBaitSource)
            assert.are.equal(true, fishingService.autoRestart)
        end)
        
        it("should persist bait changes", function()
            local success, error = fishingService:setBait("shrimp")
            
            assert.are.equal(true, success)
            assert.are.equal("shrimp", fishingService.equipment.currentBait)
            assert.are.equal("shrimp", configService:get("fishing", "defaultBait"))
        end)
        
        it("should persist cast distance changes", function()
            local success, error = fishingService:setCastDistance("long")
            
            assert.are.equal(true, success)
            assert.are.equal("long", fishingService.equipment.currentCastDistance)
            assert.are.equal("long", configService:get("fishing", "defaultCastDistance"))
        end)
        
        it("should persist bait source changes", function()
            local success, error = fishingService:setBaitSource("inventory")
            
            assert.are.equal(true, success)
            assert.are.equal("inventory", fishingService.equipment.currentBaitSource)
            assert.are.equal("inventory", configService:get("fishing", "baitSource"))
        end)
        
        it("should reject invalid bait source", function()
            local success, error = fishingService:setBaitSource("invalid")
            
            assert.are.equal(false, success)
            assert.are.equal("Invalid bait source", error)
            assert.are.equal("tank", fishingService.equipment.currentBaitSource) -- Unchanged
        end)
        
        it("should persist auto-restart setting", function()
            local success, error = fishingService:setAutoRestart(false)
            
            assert.are.equal(true, success)
            assert.are.equal(false, fishingService.autoRestart)
            assert.are.equal(false, configService:get("fishing", "autoRestart"))
        end)
        
        it("should persist max retries setting", function()
            local success, error = fishingService:setMaxRetries(5)
            
            assert.are.equal(true, success)
            assert.are.equal(5, fishingService.maxRetries)
            assert.are.equal(5, configService:get("fishing", "maxRetries"))
        end)
        
        it("should persist enabled state", function()
            local success, error = fishingService:setEnabled(false)
            
            assert.are.equal(true, success)
            assert.are.equal(false, fishingService.enabled)
            assert.are.equal(false, configService:get("fishing", "enabled"))
        end)
    end)
    
    describe("Configuration persistence across sessions", function()
        it("should maintain settings between service instances", function()
            -- First session
            local configService1 = poopDeck.services.ConfigurationService:new("session_test.json")
            local fishingService1 = poopDeck.services.FishingService:new({}, configService1)
            
            -- Change settings
            fishingService1:setBait("trout")
            fishingService1:setCastDistance("short")
            fishingService1:setBaitSource("fishbucket")
            fishingService1:setAutoRestart(false)
            
            -- Second session (simulate restart)
            local configService2 = poopDeck.services.ConfigurationService:new("session_test.json")
            local fishingService2 = poopDeck.services.FishingService:new({}, configService2)
            
            -- Verify settings persisted
            assert.are.equal("trout", fishingService2.equipment.currentBait)
            assert.are.equal("short", fishingService2.equipment.currentCastDistance)
            assert.are.equal("fishbucket", fishingService2.equipment.currentBaitSource)
            assert.are.equal(false, fishingService2.autoRestart)
        end)
        
        it("should handle configuration file corruption gracefully", function()
            -- Create corrupted config file
            _G.mockFileSystem.write("corrupted.json", "invalid json content {")
            
            -- Should fall back to defaults
            local configService = poopDeck.services.ConfigurationService:new("corrupted.json")
            local fishingService = poopDeck.services.FishingService:new({}, configService)
            
            assert.are.equal("bass", fishingService.equipment.currentBait)
            assert.are.equal(true, fishingService.autoRestart)
        end)
        
        it("should merge new default settings with existing config", function()
            -- Create config with limited settings
            local limitedConfig = '{"fishing":{"defaultBait":"shrimp"}}'
            _G.mockFileSystem.write("limited.json", limitedConfig)
            
            local configService = poopDeck.services.ConfigurationService:new("limited.json")
            
            -- Should have loaded setting + defaults
            assert.are.equal("shrimp", configService:get("fishing", "defaultBait"))
            assert.are.equal("medium", configService:get("fishing", "defaultCastDistance")) -- Default
            assert.are.equal(true, configService:get("fishing", "autoRestart")) -- Default
        end)
    end)
    
    describe("Configuration validation", function()
        local configService
        
        before_each(function()
            configService = poopDeck.services.ConfigurationService:new()
        end)
        
        it("should validate fishing configuration values", function()
            -- Valid values should succeed
            assert.are.equal(true, configService:set("fishing", "autoRestart", true))
            assert.are.equal(true, configService:set("fishing", "maxRetries", 5))
            assert.are.equal(true, configService:set("fishing", "retryDelay", 10))
            
            -- Settings should be applied
            assert.are.equal(true, configService:get("fishing", "autoRestart"))
            assert.are.equal(5, configService:get("fishing", "maxRetries"))
            assert.are.equal(10, configService:get("fishing", "retryDelay"))
        end)
        
        it("should handle nil values appropriately", function()
            -- Setting nil should work (remove setting)
            configService:set("fishing", "testSetting", nil)
            assert.is_nil(configService:get("fishing", "testSetting"))
        end)
    end)
end)