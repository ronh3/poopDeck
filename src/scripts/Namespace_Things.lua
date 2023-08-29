poopDeck = poopDeck or {}
poopDeck.Formatter = require("poopDeck.ftext")

poopDeck.GoodEcho = poopDeck.Formattter:new( {
    width = 25, 
    cap = "[poopDeck]",
    capColor = "<green>",
    textColor = "<dodger_blue>"
})

poopDeck.BadEcho = poopDeck.Formatter:new( {
    width = 25, 
    cap = "[poopDeck]",
    capColor = "<red>",
    textColor = "<orange>"
})