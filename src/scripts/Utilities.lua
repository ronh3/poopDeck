poopDeck = poopDeck or {}
poopDeck.Formatter = require("poopDeck.ftext")

function poopDeck.GoodEcho(daword)
    local TextFormatter = require("poopDeck.ftext").TextFormatter
    myFormatter = TextFormatter:new( {
      width = 70, 
      cap = "[poopDeck]",
      capColor = "<green>",
      textColor = "<dodger_blue>"
    })
    cecho(myFormatter:format(daword))
end

function poopDeck.BadEcho(daword)
    local TextFormatter = require("poopDeck.ftext").TextFormatter
    myFormatter = TextFormatter:new( {
      width = 70, 
      cap = "[poopDeck]",
      capColor = "<red>",
      textColor = "<orange>"
    })
    cecho(myFormatter:format(daword))
end