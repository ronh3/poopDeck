-- Ship domain class
-- Represents the player's vessel and its state

poopDeck.domain = poopDeck.domain or {}

-- Ship class definition
poopDeck.domain.Ship = poopDeck.core.BaseClass:extend("Ship")

function poopDeck.domain.Ship:initialize(config)
    config = config or {}
    
    -- Ship identification
    self.name = config.name or "Unknown Vessel"
    self.type = config.type or "strider"
    
    -- Ship state
    self.state = {
        docked = true,
        anchored = false,
        plankExtended = false,
        rowing = false,
        sailSpeed = 0,
        heading = "north",
        position = {x = 0, y = 0}
    }
    
    -- Ship condition
    self.condition = {
        hull = {
            current = 100,
            max = 100,
            damageLevel = "pristine"
        },
        sails = {
            current = 100,
            max = 100,
            damageLevel = "pristine"
        },
        rigging = {
            tangled = false,
            clearing = false
        }
    }
    
    -- Ship equipment
    self.equipment = {
        weapons = {},
        commScreen = false,
        warnings = true,
        buckets = 5
    }
    
    -- Maintenance settings
    self.maintenance = {
        autoRepair = false,
        prioritizeHull = true,
        threshold = 50
    }
    
    -- Movement capabilities
    self.movement = {
        maxSailSpeed = 100,
        maxRowSpeed = 5,
        turnRate = 45,
        wavecallRange = 8
    }
end

-- State management methods
function poopDeck.domain.Ship:dock(direction)
    if self.state.docked then
        return false, "Already docked"
    end
    
    self.state.docked = true
    self.state.sailSpeed = 0
    self.state.rowing = false
    self:emit("docked", direction)
    return true, "Docked successfully"
end

function poopDeck.domain.Ship:castOff()
    if not self.state.docked then
        return false, "Not docked"
    end
    
    self.state.docked = false
    self:emit("castOff")
    return true, "Cast off successfully"
end

function poopDeck.domain.Ship:setAnchor(dropped)
    if self.state.docked then
        return false, "Cannot change anchor while docked"
    end
    
    self.state.anchored = dropped
    self:emit("anchorChanged", dropped)
    return true, dropped and "Anchor dropped" or "Anchor raised"
end

function poopDeck.domain.Ship:setPlank(extended)
    self.state.plankExtended = extended
    self:emit("plankChanged", extended)
    return true, extended and "Plank extended" or "Plank raised"
end

-- Movement methods
function poopDeck.domain.Ship:setSailSpeed(speed)
    if self.state.docked then
        return false, "Cannot set sail speed while docked"
    end
    
    speed = math.max(0, math.min(speed, self.movement.maxSailSpeed))
    self.state.sailSpeed = speed
    self:emit("speedChanged", speed)
    return true, string.format("Sail speed set to %d", speed)
end

function poopDeck.domain.Ship:setRowing(rowing)
    if self.state.docked then
        return false, "Cannot row while docked"
    end
    
    self.state.rowing = rowing
    self:emit("rowingChanged", rowing)
    return true, rowing and "Rowing started" or "Rowing stopped"
end

function poopDeck.domain.Ship:turn(direction)
    if self.state.docked then
        return false, "Cannot turn while docked"
    end
    
    local validDirections = {
        "n", "ne", "e", "se", "s", "sw", "w", "nw",
        "north", "northeast", "east", "southeast", 
        "south", "southwest", "west", "northwest"
    }
    
    local directionMap = {
        n = "north", ne = "northeast", e = "east", se = "southeast",
        s = "south", sw = "southwest", w = "west", nw = "northwest"
    }
    
    direction = direction:lower()
    if directionMap[direction] then
        direction = directionMap[direction]
    end
    
    local isValid = false
    for _, valid in ipairs(validDirections) do
        if direction == valid then
            isValid = true
            break
        end
    end
    
    if not isValid then
        return false, "Invalid direction"
    end
    
    self.state.heading = direction
    self:emit("headingChanged", direction)
    return true, string.format("Turning to %s", direction)
end

function poopDeck.domain.Ship:allStop()
    self.state.sailSpeed = 0
    self.state.rowing = false
    self:emit("allStop")
    return true, "All stop!"
end

-- Condition methods
function poopDeck.domain.Ship:takeDamage(component, amount)
    if component ~= "hull" and component ~= "sails" then
        return false, "Invalid component"
    end
    
    local comp = self.condition[component]
    comp.current = math.max(0, comp.current - amount)
    
    -- Update damage level
    local percent = (comp.current / comp.max) * 100
    if percent >= 90 then
        comp.damageLevel = "pristine"
    elseif percent >= 70 then
        comp.damageLevel = "minor"
    elseif percent >= 50 then
        comp.damageLevel = "moderate"
    elseif percent >= 30 then
        comp.damageLevel = "major"
    elseif percent >= 10 then
        comp.damageLevel = "critical"
    else
        comp.damageLevel = "destroyed"
    end
    
    self:emit("damageReceived", component, amount, comp.damageLevel)
    
    -- Check for auto-repair
    if self.maintenance.autoRepair and percent < self.maintenance.threshold then
        self:emit("maintenanceNeeded", component)
    end
    
    return true, string.format("%s damaged: %d%%", component, percent)
end

function poopDeck.domain.Ship:repair(component, amount)
    if component ~= "hull" and component ~= "sails" and component ~= "all" then
        return false, "Invalid component"
    end
    
    if component == "all" then
        self.condition.hull.current = self.condition.hull.max
        self.condition.sails.current = self.condition.sails.max
        self.condition.hull.damageLevel = "pristine"
        self.condition.sails.damageLevel = "pristine"
        self:emit("repaired", "all", 100)
        return true, "All components repaired"
    end
    
    local comp = self.condition[component]
    comp.current = math.min(comp.max, comp.current + amount)
    
    -- Update damage level
    local percent = (comp.current / comp.max) * 100
    if percent >= 90 then
        comp.damageLevel = "pristine"
    elseif percent >= 70 then
        comp.damageLevel = "minor"
    else
        comp.damageLevel = "moderate"
    end
    
    self:emit("repaired", component, percent)
    return true, string.format("%s repaired to %d%%", component, percent)
end

-- Equipment methods
function poopDeck.domain.Ship:addWeapon(weapon)
    table.insert(self.equipment.weapons, weapon)
    self:emit("weaponAdded", weapon)
end

function poopDeck.domain.Ship:removeWeapon(weaponType)
    for i, weapon in ipairs(self.equipment.weapons) do
        if weapon.type == weaponType then
            table.remove(self.equipment.weapons, i)
            self:emit("weaponRemoved", weapon)
            return true
        end
    end
    return false
end

function poopDeck.domain.Ship:getWeapon(weaponType)
    for _, weapon in ipairs(self.equipment.weapons) do
        if weapon.type == weaponType then
            return weapon
        end
    end
    return nil
end

-- Utility methods
function poopDeck.domain.Ship:getStatus()
    return {
        name = self.name,
        type = self.type,
        docked = self.state.docked,
        anchored = self.state.anchored,
        speed = self.state.sailSpeed,
        rowing = self.state.rowing,
        heading = self.state.heading,
        hull = string.format("%d%% (%s)", 
            (self.condition.hull.current / self.condition.hull.max) * 100,
            self.condition.hull.damageLevel),
        sails = string.format("%d%% (%s)", 
            (self.condition.sails.current / self.condition.sails.max) * 100,
            self.condition.sails.damageLevel)
    }
end

function poopDeck.domain.Ship:canFire()
    -- Check if ship is in a state that allows firing
    if self.state.docked then
        return false, "Cannot fire while docked"
    end
    
    if #self.equipment.weapons == 0 then
        return false, "No weapons equipped"
    end
    
    return true, "Ready to fire"
end

function poopDeck.domain.Ship:toString()
    return string.format("[Ship: %s (%s)]", self.name, self.type)
end