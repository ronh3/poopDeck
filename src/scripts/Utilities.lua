--Setting up namespace and setting current version
poopDeck = poopDeck or {}
poopDeck.config = poopDeck.config or {}
poopDeck.weapons = poopDeck.weapons or {}
poopDeck.command = poopDeck.command or {}
poopDeck.autoSeaMonster = false
poopDeck.maintaining = false
poopDeck.version = "2.0"

-- Table of directions
poopDeck.directions = {
  e = "east",
  ene = "east-northeast",
  ese = "east-southeast",
  n = "north",
  nnw = "north-northwest",
  nne = "north-northeast",
  ne = "northeast",
  nw = "northwest",
  s = "south",
  sse = "south-southeast",
  ssw = "south-southwest",
  se = "southeast",
  sw = "southwest",
  w = "west",
  wnw = "west-northwest",
  wsw = "west-southwest"
}

poopDeck.seamonsters = {
  ["a legendary leviathan"] = 60,
  ["a hulking oceanic cyclops"] = 60,
  ["a towering oceanic hydra"] = 60,
  ["a sea hag"] = 40,
  ["a monstrous ketea"] = 40,
  ["a monstrous picaroon"] = 40,
  ["an unmarked warship"] = 40,
  ["a red-sailed Kashari raider"]= 30,
  ["a furious sea dragon"] = 30,
  ["a pirate ship"] = 30,
  ["a trio of raging sea serpents"] = 30,
  ["a raging shraymor"] = 25,
  ["a mass of sargassum"] = 25,
  ["a gargantuan megalodon"] = 25,
  ["a gargantuan angler fish"] = 25,
  ["a mudback septacean"] = 20,
  ["a flying sheilei"] = 20,
  ["a foam-wreathed sea serpent"] = 20,
  ["a red-faced septacean"] = 20
}

--Table of dead seamonster messages
poopDeck.deadSeamonsterMessages = {
  "🚢🐉 Triumphant Victory! 🐉🚢",
  "⚓🌊 Monster Subdued! 🌊⚓",
  "🔱🌊 Beast Beneath Conquered! 🌊🔱",
  "⛵🌊 Monstrous Foe Defeated! 🌊⛵",
  "🗡️🌊 Siren of the Deep Quelled! 🌊🗡️",
  "⚔️🌊 Sea's Terror Defeated! 🌊⚔️",
  "🦈🌊 Jaws of the Abyss Conquered! 🌊🦈",
  "🚢🌊 Monstrous Victory Achieved! 🌊🚢",
  "🌟🌊 Tidal Terror Tamed! 🌊🌟",
  "🗺️🌊 Legends Born of Victory! 🌊🗺️"
}

--Table of spawned seamonster messages
poopDeck.spottedSeamonsterMessages = {
  "🐉🌊 Rising Behemoth! 🌊🐉",
  "🔍🌊 Titan of the Deep Spotted! 🌊🔍",
  "🐲🌊 Majestic Leviathan Ascendant! 🌊🐲",
  "🦑🌊 Monstrous Anomaly Unveiled! 🌊🦑",
  "🌌🌊 Awakening of the Abyssal Colossus! 🌊🌌",
  "🌊🌊 Ripple of Giants! 🌊🌊",
  "🌟🌊 Deep's Enigma Revealed! 🌊🌟",
  "🐙🌊 Emergence of the Watery Behemoth! 🌊🐙",
  "🔮🌊 Ocean's Secret Unveiled! 🌊🔮",
  "🐍🌊 Serpentine Giant Surfaces! 🌊🐍"
}

--Table of constants that are used throughout the package
poopDeck.constants = {
  FIVE_MINUTES = 900,
  ONE_MINUTE = 1140,
  NEW_MONSTER = 1200
}
--Saving config table if it exists
function poopDeck.saveTable()
  table.save(getMudletHomeDir() .. "/poopDeckconfig.lua", poopDeck.config)
end

--Loading config table if it exists
function poopDeck.loadTable()
  if io.exists(getMudletHomeDir() .. "/poopDeckconfig.lua") then
    table.load(getMudletHomeDir() .. "/poopDeckconfig.lua", poopDeck.config)
  end
  --Setting the percent health to sip at to 75% if the user didn't set a config previously.
  if poopDeck.config.sipHealthPercent == nil then
    poopDeck.config.sipHealthPercent = 75
  end
end

--Let the user set a custom HP sipping threshold as a percentage
function poopDeck.setHealth(hpperc)
  local myMessage = "Health sip percentage set to " .. hpperc .. "%"
  poopDeck.config.sipHealthPercent = tonumber(hpperc)
  poopDeck.settingEcho(myMessage)
end

--Function to check if a string contains any emojis
function poopDeck.containsEmoji(text)
  -- This pattern matches characters outside the standard ASCII range, where most emojis reside.
  -- It's a broad check and might include non-emoji characters outside the ASCII range.
  return text:match("[\128-\191][\128-\191]") ~= nil
end

function poopDeck.framedBox(secondLineText, edgeColor, frameColor, poopColor, textColor, fillColor)
  -- Define the static total width and poopText length
  local totalWidth = 80
  local poopTextLength = 14

  -- Center 'poopDeck' in the first line
  local poopText = edgeColor .. "[ " .. poopColor .. "poop" .. textColor .. "Deck " .. edgeColor .. "]"
  local poopPaddingLength = math.floor((totalWidth - poopTextLength) / 2)
  local poopPadding = string.rep("═", poopPaddingLength)

  -- Second line text (variable content) with padding
  local secondLineLength = utf8.len(secondLineText)
  local secondPaddingLength = math.floor((totalWidth - secondLineLength - 2) / 2)
  local secondPadding
  local secondPadding2

  if poopDeck.containsEmoji(secondLineText) then
    secondPadding = string.rep(" ", secondPaddingLength - 2)
    secondPadding2 = string.rep(" ", secondPaddingLength - 2)
  else
    secondPadding = string.rep(" ", secondPaddingLength)
    secondPadding2 = string.rep(" ", secondPaddingLength)
  end

  -- Adjust for odd-length secondLineText
  if (secondLineLength % 2 ~= 0) then
      secondPadding = secondPadding .. " " -- Add an extra space for odd length
      local secondPadding2 = string.rep(" ", secondPaddingLength + 1)

  end

  -- Create the top, middle, and bottom lines
  local topLine = edgeColor .. "⌜" .. frameColor .. poopPadding .. poopText .. frameColor .. poopPadding .. edgeColor .. "⌝"
  local topMidLine = edgeColor .. "|" .. fillColor .. string.rep(" ", 78) .. "#r" .. edgeColor .. "|"
  local middleLine = edgeColor .."|" .. fillColor .. secondPadding .. textColor .. secondLineText .. fillColor .. secondPadding2 .. "#r" .. edgeColor .. "|"
  local bottomMidLine = edgeColor .. "|" .. fillColor .. string.rep(" ", 78) .. "#r" .. edgeColor .. "|"
  local bottomLine = edgeColor .."⌞" .. string.rep(frameColor .. "═", totalWidth - 2) .. edgeColor .."⌟"

  -- Output the lines
  hecho("\n" .. topLine)
  hecho("\n" .. topMidLine)
  hecho("\n" .. middleLine)
  hecho("\n" .. bottomMidLine)
  hecho("\n" .. bottomLine)
end

function poopDeck.SmallFramedBox(secondLineText, edgeColor, frameColor, poopColor, textColor, fillColor)
  -- Define the static total width and poopText length
  local totalWidth = 80
  local poopTextLength = 14
  
  -- Center 'poopDeck' in the first line
  local poopText = edgeColor .. "[ " .. poopColor .. "poop" .. textColor .. "Deck " .. edgeColor .. "]"
  local poopPaddingLength = math.floor((totalWidth - poopTextLength) / 2)
  local poopPadding = string.rep("═", poopPaddingLength)
  
  -- Second line text (variable content) with padding
  local secondLineLength = utf8.len(secondLineText)
  local secondPaddingLength = math.floor((totalWidth - secondLineLength - 2) / 2)
  local secondPadding
  local secondPadding2
  
  if poopDeck.containsEmoji(secondLineText) then
    secondPadding = string.rep(" ", secondPaddingLength - 2)
    secondPadding2 = string.rep(" ", secondPaddingLength - 2)
  else
    secondPadding = string.rep(" ", secondPaddingLength)
    secondPadding2 = string.rep(" ", secondPaddingLength)
  end
  
  -- Adjust for odd-length secondLineText
  if (secondLineLength % 2 ~= 0) then
      secondPadding = secondPadding .. " " -- Add an extra space for odd length
      local secondPadding2 = string.rep(" ", secondPaddingLength + 1)
  
  end
  
  -- Create the top, middle, and bottom lines
  local topLine = edgeColor .. "⌜" .. frameColor .. poopPadding .. poopText .. frameColor .. poopPadding .. edgeColor .. "⌝"
  local topMidLine = edgeColor .. "|" .. fillColor .. string.rep(" ", 78) .. "#r" .. edgeColor .. "|"
  local middleLine = edgeColor .."|" .. fillColor .. secondPadding .. textColor .. secondLineText .. fillColor .. secondPadding2 .. "#r" .. edgeColor .. "|"
  local bottomMidLine = edgeColor .. "|" .. fillColor .. string.rep(" ", 78) .. "#r" .. edgeColor .. "|"
  local bottomLine = edgeColor .."⌞" .. string.rep(frameColor .. "═", totalWidth - 2) .. edgeColor .."⌟"
  
  -- Output the lines
  hecho("\n" .. topLine)
  hecho("\n" .. middleLine)
  hecho("\n" .. bottomLine)
  end

--Line echo for firing - Note to self, add for fire, hookshot, etc.
function poopDeck.fireLine(daword, edgeColor, frameColor, poopColor, textColor, fillColor)
-- Second line text (variable content) with padding
  local totalWidth = getWindowWrap("main") / 4
  local secondLineLength = utf8.len(daword)
  local secondPaddingLength = math.floor((totalWidth - secondLineLength - 2) / 2)
  local secondPadding
  local secondPadding2
  if poopDeck.containsEmoji(daword) then
    secondPadding = string.rep(" ", secondPaddingLength - 2)
    secondPadding2 = string.rep(" ", secondPaddingLength - 2)
  else
    secondPadding = string.rep(" ", secondPaddingLength)
    secondPadding2 = string.rep(" ", secondPaddingLength)
  end
  
  -- Adjust for odd-length secondLineText
  if (secondLineLength % 2 ~= 0) then
      secondPadding = secondPadding .. " " -- Add an extra space for odd length
      local secondPadding2 = string.rep(" ", secondPaddingLength + 1)
  
  end
  local middleLine = edgeColor .."|" .. fillColor .. secondPadding .. textColor .. daword .. fillColor .. secondPadding2 .. "#r" .. edgeColor .. "|"
  hecho(middleLine)
end

--Large Echo for good things
function poopDeck.goodEcho(daword)
  poopDeck.FramedBox(daword, "#6aa84f","#274e13","#6e1b1b","#FFFFFF","#FFFFFF,008000")
end

--Large Echo for bad things
function poopDeck.badEcho(daword)
  poopDeck.FramedBox(daword, "#f37735","#d11141","#6e1b1b","#FFFFFF","#FFFFFF,800000")
end

--Small Echo for good things
function poopDeck.smallGoodEcho(daword)
  poopDeck.SmallFramedBox(daword, "#6aa84f","#274e13","#6e1b1b","#FFFFFF","#FFFFFF,008000")
end

--Small Echo for bad things
function poopDeck.smallBadEcho(daword)
  poopDeck.SmallFramedBox(daword, "#f37735","#d11141","#6e1b1b","#FFFFFF","#FFFFFF,800000")
end

--Small Echo for shooting things
function poopDeck.shotEcho(daword)
  poopDeck.SmallFramedBox(daword, "#fdb643","#90d673","#6e1b1b","#FFFFFF","#FFFFFF,800000")
end

--Prompt echo for when firing
function poopDeck.fireEcho(daword)
  poopDeck.fireLine(daword, "#6aa84f","#274e13","#6e1b1b","#FFFFFF","#FFFFFF,008000")
end

--Prompt echo for when maintaining
function poopDeck.maintainEcho(daword)
  poopDeck.fireLine(daword, "#6aa84f", "#274e13", "#6e1b1b", "#FFFFFF", "#FFFFFF,8B4513")
end

--Prompt echo for when out of range
function poopDeck.rangeEcho(daword)
  poopDeck.fireLine(daword, "#6aa84f", "#274e13", "#6e1b1b", "#FFFFFF", "#FFFFFF,E91E63")
end

-- Echo for settings information
function poopDeck.settingEcho(daword)
  poopDeck.SmallFramedBox(daword, "#4f81bd","#385d8a","#6e1b1b","#FFFFFF","#FFFFFF,008080")
end

--Saves and loads the config tables
registerAnonymousEventHandler("sysExitEvent", poopDeck.saveTable)
registerAnonymousEventHandler("sysLoadEvent", poopDeck.loadTable)