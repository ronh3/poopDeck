-- New OOP alias - shows comprehensive ship and combat status
-- Pattern: ^ship status$

if poopDeck.ship and poopDeck.display then
    local shipState = poopDeck.ship:getState()
    local shipHealth = poopDeck.ship:getHealthStatus()
    local combatStatus = poopDeck.combat and poopDeck.combat:getCombatStatus() or nil
    
    -- Display ship health
    poopDeck.display:showMessage(
        string.format("Hull: %d%% | Sails: %d%%", 
            shipHealth.hullPercent, 
            shipHealth.sailsPercent),
        shipHealth.overallPercent >= 75 and "good" or 
        shipHealth.overallPercent >= 50 and "setting" or "bad",
        true
    )
    
    -- Display ship state
    local stateMsg = string.format("Speed: %s | Heading: %s", 
        shipState.currentSpeed or "stopped",
        shipState.currentHeading or "none")
    
    if shipState.windDirection then
        stateMsg = stateMsg .. string.format(" | Wind: %s@%dkts", 
            shipState.windDirection, 
            shipState.windSpeed)
    end
    
    echo("\n" .. stateMsg .. "\n")
    
    -- Display combat status if in combat
    if combatStatus and combatStatus.inCombat then
        poopDeck.display:showMessage(
            string.format("Fighting: %s | Shots: %d/%d", 
                combatStatus.monster or "unknown",
                combatStatus.shotsFired,
                combatStatus.shotsFired + combatStatus.shotsRemaining),
            "shot",
            true
        )
    end
else
    echo("poopDeck: System not initialized\n")
end