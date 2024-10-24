-- main.lua

-- #########################
-- ####### REQUIREMENTS #####
-- #########################

-- Load required libraries
local Gamestate = require "gamestate"

-- Require game state files
local level1 = require "level1"      -- Level 1
--local level2 = require "level2"      -- Level 2
--local level3 = require "level3"      -- Level 3
--local instructions = require "instructions" -- Instructions

-- #########################
-- ######## DEFINITIONS ####
-- #########################

-- Shared variables
screenWidth, screenHeight = 800, 600
fontLarge, fontMedium, fontSmall = nil, nil, nil

-- Rain particle system variables
rainSystem = nil
rainImage = nil

-- Background image for the main menu
backgroundImage = nil -- Changed to global

-- #########################
-- ####### MAIN MENU #######
-- #########################

local menu = {}

-- Define buttons with their properties
local buttons = {
    {
        label = "Level 1",
        x =  screenWidth / 2 - 100,
        y =  screenHeight / 2 - 60,
        width = 200,
        height = 50,
        onClick = function()
            Gamestate.switch(level1)
        end
    },
    {
        label = "Level 2",
        x =  screenWidth / 2 - 100,
        y =  screenHeight / 2,
        width = 200,
        height = 50,
        onClick = function()
            Gamestate.switch(level2)
        end
    },
    {
        label = "Level 3",
        x =  screenWidth / 2 - 100,
        y =  screenHeight / 2 + 60,
        width = 200,
        height = 50,
        onClick = function()
            Gamestate.switch(level3)
        end
    }
}

function menu:enter()
    -- Initialize menu state
    print("Entering Main Menu State")
end

function menu:leave()
    -- Cleanup when leaving menu state
    print("Leaving Main Menu State")
end

function menu:update(dt)
    -- Update the rain particle system
    if rainSystem then
        rainSystem:update(dt)
    end

    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, button in ipairs(buttons) do
        if mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height then
               button.isHovered = true
        else
               button.isHovered = false
        end
    end
end

function menu:draw()
    -- Draw the background image first
    if backgroundImage then
        -- Calculate scaling factors to fit the screen
        local scaleX = screenWidth / backgroundImage:getWidth()
        local scaleY = screenHeight / backgroundImage:getHeight()
        -- Draw the background image scaled to the screen size
        love.graphics.draw(backgroundImage, 0, 0, 0, scaleX, scaleY)
    else
        -- Fallback to a solid color if backgroundImage fails to load
        love.graphics.setColor(0.5, 0.7, 1) -- Light blue
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end

    -- Draw rain particles
    if rainSystem then
        love.graphics.draw(rainSystem, 0, 0)
    end

    -- Render the game title
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1) -- White color for text
    love.graphics.printf("Clean Water Quest", 0, screenHeight / 2 - 150, screenWidth, "center")

    -- Render each button with hover effect
    for _, button in ipairs(buttons) do
        if button.isHovered then
            love.graphics.setColor(0.3, 0.7, 0.9) -- Lighter color on hover
        else
            love.graphics.setColor(0.2, 0.6, 0.8) -- Original button color
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

        -- Draw button border
        love.graphics.setColor(1, 1, 1) -- White border
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)

        -- Draw button label
        love.graphics.setFont(fontMedium)
        love.graphics.printf(button.label, button.x, button.y + (button.height / 2) - (fontMedium:getHeight() / 2), button.width, "center")
    end
end

function menu:keypressed(key)
    if key == "1" then
        Gamestate.switch(level1)
    elseif key == "2" then
        Gamestate.switch(level2)
    elseif key == "3" then
        Gamestate.switch(level3)
    elseif key == "escape" then
        love.event.quit()
    end
end

function menu:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- 1 is the left mouse button
        for _, btn in ipairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height then
                   btn.onClick()
                   break -- Exit the loop once the clicked button is found
            end
        end
    end
end

-- #########################
-- ######## LOVE LOAD ######
-- #########################

function love.load()
    -- Set window size
    screenWidth, screenHeight = 800, 600
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Clean Water Quest")

    -- Load fonts
    fontLarge = love.graphics.newFont("assets/fonts/Adventure.ttf", 48)
    fontMedium = love.graphics.newFont("assets/fonts/Adventure.ttf", 32)
    fontSmall = love.graphics.newFont("assets/fonts/Adventure.ttf", 24)
    love.graphics.setFont(fontLarge)  -- Set default font

    -- Load background image for the main menu
    backgroundImage = love.graphics.newImage("assets/images/background.png")
    if not backgroundImage then
        print("Error: Failed to load background.png!")
    end

    -- Load raindrop image for particles
    rainImage = love.graphics.newImage("assets/images/raindrop.png")
    if not rainImage then
        print("Error: Failed to load raindrop image!")
    end

    -- Initialize rain particle system
    if rainImage then
        rainSystem = love.graphics.newParticleSystem(rainImage, 1000)
        rainSystem:setParticleLifetime(0.5, 1.5) -- Lifetime of particles in seconds
        rainSystem:setEmissionRate(800)            -- Particles per second
        rainSystem:setSizes(0.5, 1)               -- Size of raindrops
        rainSystem:setSpeed(300, 500)             -- Speed of raindrops
        rainSystem:setDirection(math.pi / 2)      -- Direction straight down
        rainSystem:setSpread(0)                   -- No spread, straight down
        rainSystem:setLinearAcceleration(0, 500, 0, 500) -- Acceleration to simulate gravity
        rainSystem:setColors(0.5, 0.5, 1, 0.5, 0.5, 0.5, 1, 0) -- Fade out

        -- Set the emission area to cover the entire screen width
        rainSystem:setEmissionArea("normal", screenWidth, 0, 0, true)

        rainSystem:emit(800) -- Pre-emit particles
    else
        print("Rain particle system not initialized due to missing raindrop image.")
    end

    -- Load background music (rain sounds)
    local bgMusic = love.audio.newSource("assets/sounds/background_music.mp3", "stream")
    if bgMusic then
        bgMusic:setLooping(true)
        bgMusic:setVolume(0.5)
        bgMusic:play()
    else
        print("Error: Failed to load background music!")
    end

    -- Initialize gamestate
    Gamestate.registerEvents()
    Gamestate.switch(menu)  -- Start the game with the main menu
end

-- #########################
-- #### LOVE KEYPRESSED ####
-- #########################

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()  -- Quit the game when Escape is pressed
    end
    if Gamestate.current() and Gamestate.current().keypressed then
        Gamestate.current():keypressed(key)
    end
end

-- #########################
-- #### LOVE MOUSEPRESSED ###
-- #########################

function love.mousepressed(x, y, button, istouch, presses)
    if Gamestate.current() and Gamestate.current().mousepressed then
        Gamestate.current():mousepressed(x, y, button, istouch, presses)
    end
end
