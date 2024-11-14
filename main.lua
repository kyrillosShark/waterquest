-- main.lua

-- #########################
-- ####### REQUIREMENTS #####
-- #########################

-- Set window size
screenWidth, screenHeight = 800, 600

-- Load required libraries
local Gamestate = require "gamestate"

-- Shared variables
fontLarge, fontMedium, fontSmall = nil, nil, nil
backgroundImage = nil

-- Set up the window
love.window.setMode(screenWidth, screenHeight)
love.window.setTitle("Clean Water Quest")

-- Load fonts
fontLarge = love.graphics.newFont("assets/fonts/Adventure.ttf", 48)
fontMedium = love.graphics.newFont("assets/fonts/Adventure.ttf", 32)
fontSmall = love.graphics.newFont("assets/fonts/Adventure.ttf", 24)

-- Set default font
love.graphics.setFont(fontLarge)

-- Load background image for the main menu
backgroundImage = love.graphics.newImage("assets/images/background.png")
if not backgroundImage then
    print("Error: Failed to load background.png!")
end

-- Require game state files
local level1 = require "level1"
local level2 = require "level2"
local level3 = require "level3"

-- Assign the game states to the Gamestate module
Gamestate.level1 = level1
Gamestate.level2 = level2
Gamestate.level3 = level3

-- Require the menu state after levels are assigned
local menu = require "menu"
Gamestate.menu = menu

-- Initialize gamestate
Gamestate.registerEvents()
Gamestate.switch(Gamestate.menu)  -- Start the game with the main menu

-- No need to define love.update, love.draw, etc., in main.lua
-- Gamestate.registerEvents() handles the callbacks
