-- Load spec helper
require('spec.spec_helper')

-- Core architecture tests
describe("poopDeck Core Architecture", function()
    
    before_each(function()
        -- Initialize poopDeck namespace
        poopDeck = poopDeck or {}
        poopDeck.core = poopDeck.core or {}
        
        -- Clear any existing implementations
        poopDeck.core.BaseClass = nil
        
        -- Create BaseClass implementation
        poopDeck.core.BaseClass = {
            extend = function(self, className)
                local class = setmetatable({}, {__index = self})
                class.className = className or "UnnamedClass"
                class.observers = {}
                class.instances = {}
                return class
            end,
            
            new = function(self, ...)
                local instance = setmetatable({}, {__index = self})
                instance.className = self.className
                instance.observers = {}
                instance.instanceId = #self.instances + 1
                
                table.insert(self.instances, instance)
                
                if instance.initialize then
                    instance:initialize(...)
                end
                
                return instance
            end,
            
            on = function(self, event, callback)
                if type(event) ~= "string" then
                    error("Event name must be a string")
                end
                if type(callback) ~= "function" then
                    error("Callback must be a function")
                end
                
                self.observers[event] = self.observers[event] or {}
                table.insert(self.observers[event], callback)
                
                return #self.observers[event] -- Return subscription ID
            end,
            
            off = function(self, event, subscriptionId)
                if self.observers[event] and subscriptionId then
                    self.observers[event][subscriptionId] = nil
                elseif self.observers[event] and not subscriptionId then
                    self.observers[event] = {}
                end
            end,
            
            emit = function(self, event, ...)
                if self.observers[event] then
                    for i, callback in ipairs(self.observers[event]) do
                        if callback then
                            local success, error = pcall(callback, ...)
                            if not success then
                                -- Log error but continue with other callbacks
                                if poopDeck.services and poopDeck.services.errorHandling then
                                    poopDeck.services.errorHandling:handleError(error, 
                                        {event = event, className = self.className}, "event")
                                end
                            end
                        end
                    end
                end
            end,
            
            getClassName = function(self)
                return self.className
            end,
            
            getInstanceId = function(self)
                return self.instanceId
            end,
            
            isInstanceOf = function(self, className)
                local current = getmetatable(self).__index
                while current do
                    if current.className == className then
                        return true
                    end
                    current = getmetatable(current) and getmetatable(current).__index
                end
                return false
            end
        }
        
        -- Add inheritance chain support
        poopDeck.core.BaseClass.inherit = function(self, parentClass)
            setmetatable(self, {__index = parentClass})
            return self
        end
        
        -- Create test classes for inheritance testing
        poopDeck.core.TestParent = poopDeck.core.BaseClass:extend("TestParent")
        function poopDeck.core.TestParent:initialize(name)
            self.name = name or "parent"
            self.parentProperty = "parent_value"
        end
        
        function poopDeck.core.TestParent:parentMethod()
            return "parent_method_called"
        end
        
        function poopDeck.core.TestParent:overridableMethod()
            return "parent_implementation"
        end
        
        -- Child class
        poopDeck.core.TestChild = poopDeck.core.TestParent:extend("TestChild")
        function poopDeck.core.TestChild:initialize(name, childProp)
            -- Call parent constructor
            poopDeck.core.TestParent.initialize(self, name)
            self.childProperty = childProp or "child_value"
        end
        
        function poopDeck.core.TestChild:childMethod()
            return "child_method_called"
        end
        
        function poopDeck.core.TestChild:overridableMethod()
            return "child_implementation"
        end
        
        -- Event system test class
        poopDeck.core.EventTest = poopDeck.core.BaseClass:extend("EventTest")
        function poopDeck.core.EventTest:initialize()
            self.eventHistory = {}
        end
        
        function poopDeck.core.EventTest:triggerEvent(eventName, data)
            table.insert(self.eventHistory, {event = eventName, data = data, timestamp = os.time()})
            self:emit(eventName, data)
        end
        
        function poopDeck.core.EventTest:getEventHistory()
            return self.eventHistory
        end
        
        -- Mock error handling service for event error testing
        poopDeck.services = poopDeck.services or {}
        poopDeck.services.errorHandling = {
            handleError = function(self, error, context, category)
                _G.lastEventError = {
                    error = error,
                    context = context,
                    category = category
                }
                return true
            end
        }
        
        -- Clear test state
        _G.lastEventError = nil
        _G.eventCallbackResults = {}
        _G.callbackExecutionOrder = {}
    end)
    
    describe("BaseClass creation and extension", function()
        it("should create BaseClass with basic properties", function()
            assert.is_not_nil(poopDeck.core.BaseClass)
            assert.is_function(poopDeck.core.BaseClass.extend)
            assert.is_function(poopDeck.core.BaseClass.new)
            assert.is_function(poopDeck.core.BaseClass.on)
            assert.is_function(poopDeck.core.BaseClass.emit)
        end)
        
        it("should extend BaseClass to create new classes", function()
            local TestClass = poopDeck.core.BaseClass:extend("TestClass")
            
            assert.is_not_nil(TestClass)
            assert.are.equal("TestClass", TestClass.className)
            assert.is_table(TestClass.observers)
            assert.is_table(TestClass.instances)
        end)
        
        it("should create instances of extended classes", function()
            local TestClass = poopDeck.core.BaseClass:extend("TestClass")
            local instance = TestClass:new()
            
            assert.is_not_nil(instance)
            assert.are.equal("TestClass", instance.className)
            assert.are.equal(1, instance.instanceId)
            assert.is_table(instance.observers)
        end)
        
        it("should track multiple instances", function()
            local TestClass = poopDeck.core.BaseClass:extend("TestClass")
            local instance1 = TestClass:new()
            local instance2 = TestClass:new()
            local instance3 = TestClass:new()
            
            assert.are.equal(1, instance1.instanceId)
            assert.are.equal(2, instance2.instanceId)
            assert.are.equal(3, instance3.instanceId)
            assert.are.equal(3, #TestClass.instances)
        end)
        
        it("should call initialize method when provided", function()
            local TestClass = poopDeck.core.BaseClass:extend("TestClass")
            TestClass.initialize = function(self, value)
                self.initValue = value
                self.initialized = true
            end
            
            local instance = TestClass:new("test_value")
            
            assert.are.equal("test_value", instance.initValue)
            assert.are.equal(true, instance.initialized)
        end)
    end)
    
    describe("Class inheritance", function()
        it("should inherit from parent class", function()
            local parent = poopDeck.core.TestParent:new("test_parent")
            
            assert.are.equal("test_parent", parent.name)
            assert.are.equal("parent_value", parent.parentProperty)
            assert.are.equal("parent_method_called", parent:parentMethod())
        end)
        
        it("should inherit parent methods in child class", function()
            local child = poopDeck.core.TestChild:new("test_child", "test_child_prop")
            
            -- Should have parent properties and methods
            assert.are.equal("test_child", child.name)
            assert.are.equal("parent_value", child.parentProperty)
            assert.are.equal("parent_method_called", child:parentMethod())
            
            -- Should have child properties and methods
            assert.are.equal("test_child_prop", child.childProperty)
            assert.are.equal("child_method_called", child:childMethod())
        end)
        
        it("should allow method overriding", function()
            local parent = poopDeck.core.TestParent:new()
            local child = poopDeck.core.TestChild:new()
            
            assert.are.equal("parent_implementation", parent:overridableMethod())
            assert.are.equal("child_implementation", child:overridableMethod())
        end)
        
        it("should support instanceof checks", function()
            local parent = poopDeck.core.TestParent:new()
            local child = poopDeck.core.TestChild:new()
            
            assert.are.equal(true, parent:isInstanceOf("TestParent"))
            assert.are.equal(false, parent:isInstanceOf("TestChild"))
            
            assert.are.equal(true, child:isInstanceOf("TestChild"))
            assert.are.equal(true, child:isInstanceOf("TestParent")) -- Inheritance
        end)
        
        it("should return correct class names", function()
            local parent = poopDeck.core.TestParent:new()
            local child = poopDeck.core.TestChild:new()
            
            assert.are.equal("TestParent", parent:getClassName())
            assert.are.equal("TestChild", child:getClassName())
        end)
    end)
    
    describe("Event system", function()
        local eventTest
        
        before_each(function()
            eventTest = poopDeck.core.EventTest:new()
        end)
        
        it("should register event listeners", function()
            local callbackExecuted = false
            
            local subscriptionId = eventTest:on("test_event", function(data)
                callbackExecuted = true
                _G.eventCallbackResults.data = data
            end)
            
            assert.is_number(subscriptionId)
            assert.are.equal(1, subscriptionId)
            
            eventTest:triggerEvent("test_event", "test_data")
            
            assert.are.equal(true, callbackExecuted)
            assert.are.equal("test_data", _G.eventCallbackResults.data)
        end)
        
        it("should support multiple listeners for same event", function()
            local callback1Executed = false
            local callback2Executed = false
            
            eventTest:on("multi_listener", function(data)
                callback1Executed = true
                table.insert(_G.callbackExecutionOrder, "callback1")
            end)
            
            eventTest:on("multi_listener", function(data)
                callback2Executed = true
                table.insert(_G.callbackExecutionOrder, "callback2")
            end)
            
            eventTest:triggerEvent("multi_listener", "data")
            
            assert.are.equal(true, callback1Executed)
            assert.are.equal(true, callback2Executed)
            assert.are.equal(2, #_G.callbackExecutionOrder)
            assert.are.equal("callback1", _G.callbackExecutionOrder[1])
            assert.are.equal("callback2", _G.callbackExecutionOrder[2])
        end)
        
        it("should pass event data to listeners", function()
            local receivedData = nil
            
            eventTest:on("data_test", function(data)
                receivedData = data
            end)
            
            local testData = {value = 42, name = "test"}
            eventTest:triggerEvent("data_test", testData)
            
            assert.are.same(testData, receivedData)
        end)
        
        it("should handle multiple event parameters", function()
            local param1, param2, param3 = nil, nil, nil
            
            eventTest:on("multi_param", function(p1, p2, p3)
                param1 = p1
                param2 = p2
                param3 = p3
            end)
            
            eventTest:emit("multi_param", "first", "second", "third")
            
            assert.are.equal("first", param1)
            assert.are.equal("second", param2)
            assert.are.equal("third", param3)
        end)
        
        it("should validate event registration parameters", function()
            assert.has_error(function()
                eventTest:on(123, function() end) -- Invalid event name
            end)
            
            assert.has_error(function()
                eventTest:on("valid_event", "not_a_function") -- Invalid callback
            end)
        end)
        
        it("should remove event listeners", function()
            local callbackExecuted = false
            
            local subscriptionId = eventTest:on("removable_event", function()
                callbackExecuted = true
            end)
            
            eventTest:off("removable_event", subscriptionId)
            eventTest:triggerEvent("removable_event")
            
            assert.are.equal(false, callbackExecuted)
        end)
        
        it("should remove all listeners for an event", function()
            local callback1Executed = false
            local callback2Executed = false
            
            eventTest:on("clear_all", function() callback1Executed = true end)
            eventTest:on("clear_all", function() callback2Executed = true end)
            
            eventTest:off("clear_all") -- No subscription ID removes all
            eventTest:triggerEvent("clear_all")
            
            assert.are.equal(false, callback1Executed)
            assert.are.equal(false, callback2Executed)
        end)
        
        it("should handle errors in event callbacks gracefully", function()
            local goodCallbackExecuted = false
            
            -- Add a callback that will error
            eventTest:on("error_test", function()
                error("Test error in callback")
            end)
            
            -- Add a good callback after the error one
            eventTest:on("error_test", function()
                goodCallbackExecuted = true
            end)
            
            eventTest:triggerEvent("error_test")
            
            -- Good callback should still execute despite error in first callback
            assert.are.equal(true, goodCallbackExecuted)
            
            -- Error should be handled by error service
            assert.is_not_nil(_G.lastEventError)
            assert.are.equal("event", _G.lastEventError.category)
            assert.are.equal("error_test", _G.lastEventError.context.event)
        end)
    end)
    
    describe("Class method utilities", function()
        it("should provide class name access", function()
            local TestClass = poopDeck.core.BaseClass:extend("UtilityTest")
            local instance = TestClass:new()
            
            assert.are.equal("UtilityTest", instance:getClassName())
        end)
        
        it("should provide instance ID access", function()
            local TestClass = poopDeck.core.BaseClass:extend("IDTest")
            local instance1 = TestClass:new()
            local instance2 = TestClass:new()
            
            assert.are.equal(1, instance1:getInstanceId())
            assert.are.equal(2, instance2:getInstanceId())
        end)
        
        it("should handle deep inheritance chains", function()
            -- Create grandparent -> parent -> child chain
            local GrandParent = poopDeck.core.BaseClass:extend("GrandParent")
            function GrandParent:grandparentMethod()
                return "grandparent"
            end
            
            local Parent = GrandParent:extend("Parent")
            function Parent:parentMethod()
                return "parent"
            end
            
            local Child = Parent:extend("Child")
            function Child:childMethod()
                return "child"
            end
            
            local instance = Child:new()
            
            -- Should have access to all methods in chain
            assert.are.equal("child", instance:childMethod())
            assert.are.equal("parent", instance:parentMethod())
            assert.are.equal("grandparent", instance:grandparentMethod())
            
            -- Should recognize inheritance from all levels
            assert.are.equal(true, instance:isInstanceOf("Child"))
            assert.are.equal(true, instance:isInstanceOf("Parent"))
            assert.are.equal(true, instance:isInstanceOf("GrandParent"))
            assert.are.equal(false, instance:isInstanceOf("UnrelatedClass"))
        end)
    end)
    
    describe("Memory management and cleanup", function()
        it("should track instances properly", function()
            local TestClass = poopDeck.core.BaseClass:extend("MemoryTest")
            
            local instance1 = TestClass:new()
            local instance2 = TestClass:new()
            local instance3 = TestClass:new()
            
            assert.are.equal(3, #TestClass.instances)
            assert.are.equal(instance1, TestClass.instances[1])
            assert.are.equal(instance2, TestClass.instances[2])
            assert.are.equal(instance3, TestClass.instances[3])
        end)
        
        it("should handle large numbers of event listeners", function()
            local TestClass = poopDeck.core.BaseClass:extend("StressTest")
            local instance = TestClass:new()
            
            -- Add many listeners
            for i = 1, 100 do
                instance:on("stress_event", function(data)
                    _G.eventCallbackResults["callback_" .. i] = data
                end)
            end
            
            assert.are.equal(100, #instance.observers.stress_event)
            
            instance:emit("stress_event", "stress_data")
            
            -- All callbacks should have executed
            for i = 1, 100 do
                assert.are.equal("stress_data", _G.eventCallbackResults["callback_" .. i])
            end
        end)
        
        it("should handle event listener removal correctly", function()
            local TestClass = poopDeck.core.BaseClass:extend("RemovalTest")
            local instance = TestClass:new()
            
            -- Add multiple listeners
            local sub1 = instance:on("removal_test", function() _G.callback1 = true end)
            local sub2 = instance:on("removal_test", function() _G.callback2 = true end)
            local sub3 = instance:on("removal_test", function() _G.callback3 = true end)
            
            -- Remove middle listener
            instance:off("removal_test", sub2)
            
            _G.callback1 = false
            _G.callback2 = false
            _G.callback3 = false
            
            instance:emit("removal_test")
            
            -- Only listeners 1 and 3 should execute (2 was removed)
            assert.are.equal(true, _G.callback1)
            assert.are.equal(false, _G.callback2)
            assert.are.equal(true, _G.callback3)
        end)
    end)
    
    describe("Edge cases and error handling", function()
        it("should handle missing initialize method gracefully", function()
            local TestClass = poopDeck.core.BaseClass:extend("NoInitialize")
            -- Don't define initialize method
            
            assert.has_no.errors(function()
                local instance = TestClass:new("some", "parameters")
                assert.is_not_nil(instance)
            end)
        end)
        
        it("should handle circular event emissions", function()
            local TestClass = poopDeck.core.BaseClass:extend("CircularTest")
            local instance = TestClass:new()
            local emissionCount = 0
            
            instance:on("circular_event", function()
                emissionCount = emissionCount + 1
                if emissionCount < 5 then -- Prevent infinite loop
                    instance:emit("circular_event")
                end
            end)
            
            instance:emit("circular_event")
            
            assert.are.equal(5, emissionCount)
        end)
        
        it("should handle nil event names gracefully", function()
            local TestClass = poopDeck.core.BaseClass:extend("NilEventTest")
            local instance = TestClass:new()
            
            assert.has_no.errors(function()
                instance:emit(nil, "data")
            end)
            
            assert.has_no.errors(function()
                instance:off(nil)
            end)
        end)
        
        it("should handle empty observer arrays", function()
            local TestClass = poopDeck.core.BaseClass:extend("EmptyObserverTest")
            local instance = TestClass:new()
            
            -- Create empty observer array
            instance.observers.empty_event = {}
            
            assert.has_no.errors(function()
                instance:emit("empty_event", "data")
            end)
        end)
        
        it("should handle class extension without name", function()
            local UnnamedClass = poopDeck.core.BaseClass:extend()
            
            assert.are.equal("UnnamedClass", UnnamedClass.className)
            
            local instance = UnnamedClass:new()
            assert.are.equal("UnnamedClass", instance:getClassName())
        end)
    end)
    
    describe("Performance considerations", function()
        it("should create instances efficiently", function()
            local TestClass = poopDeck.core.BaseClass:extend("PerformanceTest")
            
            local startTime = os.clock()
            
            -- Create many instances
            local instances = {}
            for i = 1, 1000 do
                instances[i] = TestClass:new()
            end
            
            local endTime = os.clock()
            local duration = endTime - startTime
            
            -- Should complete reasonably quickly (less than 1 second)
            assert.truthy(duration < 1.0)
            assert.are.equal(1000, #TestClass.instances)
        end)
        
        it("should emit events efficiently", function()
            local TestClass = poopDeck.core.BaseClass:extend("EmissionPerformanceTest")
            local instance = TestClass:new()
            
            -- Add many listeners
            for i = 1, 100 do
                instance:on("performance_event", function(data)
                    -- Minimal callback
                end)
            end
            
            local startTime = os.clock()
            
            -- Emit many events
            for i = 1, 100 do
                instance:emit("performance_event", i)
            end
            
            local endTime = os.clock()
            local duration = endTime - startTime
            
            -- Should complete reasonably quickly
            assert.truthy(duration < 1.0)
        end)
    end)
end)