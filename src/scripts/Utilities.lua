--Setting up namespace and setting current version
poopDeck = poopDeck or {}
poopDeck.version = "0.9f"

--Function to check if a string contains any emojis
function poopDeck.containsEmoji(text)
  -- This pattern matches characters outside the standard ASCII range, where most emojis reside.
  -- It's a broad check and might include non-emoji characters outside the ASCII range.
  return text:match("[\128-\191][\128-\191]") ~= nil
end

function poopDeck.FramedBox(secondLineText, edgeColor, frameColor, poopColor, textColor, fillColor)
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
  poopDeck.SmallFramedBox(daword, "#fdb643","#90d673","#6e1b1b","#FFFFFF","#FFFFFF,#fdb643")
end

--Update notification and download new version. Checks what the current version is vs what the version is up on Github.