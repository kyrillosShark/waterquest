-- menu.lua

local menu = {}
local Gamestate = require "gamestate"

function menu:enter()
    -- Initialize menu state
    print("Entering Main Menu State")

    -- Load raindrop image for particles
    self.rainImage = love.graphics.newImage("assets/images/raindrop.png")
    if not self.rainImage then
        print("Error: Failed to load raindrop image!")
    end

    -- Initialize rain particle system
    if self.rainImage then
        self.rainSystem = love.graphics.newParticleSystem(self.rainImage, 1000)
        self.rainSystem:setParticleLifetime(0.5, 1.5)
        self.rainSystem:setEmissionRate(800)
        self.rainSystem:setSizes(0.5, 1)
        self.rainSystem:setSpeed(300, 500)
        self.rainSystem:setDirection(math.pi / 2)
        self.rainSystem:setSpread(0)
        self.rainSystem:setLinearAcceleration(0, 500, 0, 500)
        self.rainSystem:setColors(0.5, 0.5, 1, 0.5, 0.5, 0.5, 1, 0)
        self.rainSystem:setEmissionArea("normal", screenWidth, 0, 0, true)
        self.rainSystem:emit(800)
    else
        print("Rain particle system not initialized due to missing raindrop image.")
    end

    -- Define buttons with their properties
    self.buttons = {
        {
            label = "Level 1",
            x =  screenWidth / 2 - 100,
            y =  screenHeight / 2 - 60,
            width = 200,
            height = 50,
            onClick = function()
                print("Switching to Level 1")
                Gamestate.switch(Gamestate.level1)
            end
        },
        {
            label = "Level 2",
            x =  screenWidth / 2 - 100,
            y =  screenHeight / 2,
            width = 200,
            height = 50,
            onClick = function()
                print("Switching to Level 2")
                Gamestate.switch(Gamestate.level2)
            end
        },
        {
            label = "Level 3",
            x =  screenWidth / 2 - 100,
            y =  screenHeight / 2 + 60,
            width = 200,
            height = 50,
            onClick = function()
                print("Switching to Level 3")
                Gamestate.switch(Gamestate.level3)
            end
        }
    }
end

function menu:update(dt)
    -- Update the rain particle system
    if self.rainSystem then
        self.rainSystem:update(dt)
    end

    -- Update button hover states
    local mx, my = love.mouse.getPosition()
    for _, button in ipairs(self.buttons) do
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
    if self.rainSystem then
        love.graphics.draw(self.rainSystem, 0, 0)
    end

    -- Render the game title
    love.graphics.setFont(fontLarge)
    love.graphics.setColor(1, 1, 1) -- White color for text
    love.graphics.printf("Clean Water Quest", 0, screenHeight / 2 - 150, screenWidth, "center")

    -- Render each button with hover effect
    for _, button in ipairs(self.buttons) do
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
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.label, button.x, button.y + (button.height / 2) - (fontMedium:getHeight() / 2), button.width, "center")
    end
end

function menu:keypressed(key)
    if key == "1" then
        Gamestate.switch(Gamestate.level1)
    elseif key == "2" then
        Gamestate.switch(Gamestate.level2)
    elseif key == "3" then
        Gamestate.switch(Gamestate.level3)
    elseif key == "escape" then
        love.event.quit()
    end
end

function menu:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        for _, btn in ipairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height then
                   btn.onClick()
                   break -- Exit the loop once the clicked button is found
            end
        end
    end
end

return menu
