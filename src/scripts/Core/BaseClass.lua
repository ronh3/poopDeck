-- Base Class implementation for poopDeck OOP architecture
-- Provides inheritance and common functionality for all classes

poopDeck = poopDeck or {}
poopDeck.core = poopDeck.core or {}

-- Base Class definition
poopDeck.core.BaseClass = {}
poopDeck.core.BaseClass.__index = poopDeck.core.BaseClass

function poopDeck.core.BaseClass:new(className)
    local instance = setmetatable({}, self)
    instance.__className = className or "BaseClass"
    instance.__isInitialized = false
    return instance
end

function poopDeck.core.BaseClass:extend(className)
    local subclass = {}
    subclass.__index = subclass
    subclass.__super = self
    setmetatable(subclass, {
        __index = self,
        __call = function(cls, ...)
            local instance = setmetatable({}, cls)
            instance.__className = className
            if instance.initialize then
                instance:initialize(...)
            end
            instance.__isInitialized = true
            return instance
        end
    })
    return subclass
end

function poopDeck.core.BaseClass:getClassName()
    return self.__className
end

function poopDeck.core.BaseClass:isInstanceOf(class)
    local meta = getmetatable(self)
    while meta do
        if meta == class then
            return true
        end
        meta = getmetatable(meta)
    end
    return false
end

function poopDeck.core.BaseClass:toString()
    return string.format("[%s instance]", self.__className)
end

-- Observer pattern support
function poopDeck.core.BaseClass:on(event, callback)
    self._listeners = self._listeners or {}
    self._listeners[event] = self._listeners[event] or {}
    table.insert(self._listeners[event], callback)
end

function poopDeck.core.BaseClass:emit(event, ...)
    if not self._listeners or not self._listeners[event] then
        return
    end
    for _, callback in ipairs(self._listeners[event]) do
        callback(self, ...)
    end
end

function poopDeck.core.BaseClass:off(event, callback)
    if not self._listeners or not self._listeners[event] then
        return
    end
    if not callback then
        self._listeners[event] = nil
        return
    end
    for i, cb in ipairs(self._listeners[event]) do
        if cb == callback then
            table.remove(self._listeners[event], i)
            break
        end
    end
end