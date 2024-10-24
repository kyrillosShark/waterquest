local level1 = {}

-- Define possible game states
local STATES = {
    DIALOGUE = "dialogue",
    MOVING = "moving",
    RAINING = "raining",
    QUESTION = "question",
    GAMEPLAY = "gameplay"
}

-- Local variables for level-specific assets
local clouds = {}
local grasses = {}
local grassImages = {}
local cloudImage
local raindropImage

-- Feedback assets
local checkImage
local xImage
local feedbackState = nil -- "correct" or "incorrect"
local feedbackTimer = 0
local feedbackDuration = 2

-- House and Tank variables
local house = { x = 50, y = 100, width = 600, height = 600 }
local tank = {
    x = 490, -- Adjusted position to align with house removal of gutters
    y = 350,
    width = 100,
    height = 100,
    waterLevel = 10,
    maxWater = 200
}

-- Rain systems
local raindrops = {}
local rainParticles = {}
local rainParticleSpawnTimer = 0
local rainParticleSpawnInterval = 0.1 -- Spawn rain particles every 0.1 seconds

local raindropSpeedMin = 300
local raindropSpeedMax = 500
local raindropSpawnInterval = 0.05 -- Time between each raindrop spawn
local raindropSpawnTimer = 0

-- Derived tank properties
tank.radius = tank.width / 2

-- Question and user input
local question = "Calculate the volume of water in the tank based on the current water level."
local correctAnswer = 0
local userAnswer = ""

-- Margin of error (epsilon) for floating-point comparison
local epsilon = 0.1

-- Time-based variable for smooth animation
local time = 0

-- Screen dimensions
local screenWidth = 800
local screenHeight = 600

-- Font settings
local defaultFont
local questionFont
local feedbackFont
local titleFont

-- Plane variables
local planeImage
local bannerImage
local planes = {}
local planeSpawnInterval = 7 -- seconds between plane spawns
local planeSpawnTimer = 0
local planeSpeed = 150 -- pixels per second

-- Dialogue sequence for characters
local dialogue = {}
local currentDialogue = 1
local state = STATES.DIALOGUE

-- Character definitions
local character2 = {
    image = nil,
    x = screenWidth / 2 + 250,
    y = screenHeight, -- Positioned above the ground
    scale = 0.5,
    velocityX = 0,
    velocityY = 0
}

-- Variables for the raining sequence
local backgroundColor = {0.529, 0.808, 0.980} -- Initial sky blue background
local targetBackgroundColor = {0.1, 0.1, 0.2} -- Darker background color
local rainingTimer = 0
local rainingDuration = 5 -- Duration of the raining animation in seconds
local initialWaterLevel
local targetWaterLevel

-- House image variable
local houseImage

-- Define the water bar
local waterBar = {
    x = tank.x + tank.width - 170, -- Position the bar to the right of the tank
    y = tank.y,
    width = 20,
    height = tank.height + 30,
    waterLevel = 0,               -- Initial water level
    maxWater = 200,               -- Maximum water level
    fillRate = 100,               -- Units per second
    filled = false                -- Flag to check if the bar is filled
}

-- Define a unified water color
local waterColor = {0.000, 0.749, 1.000, 0.6} -- Same as the tank's water color

-- Function called when entering Level 1
function level1:enter()
    print("Entering Level 1")

    -- Load fonts
    defaultFont = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 18)
    questionFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 22)
    feedbackFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 28)
    titleFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 36)

    -- Load grass images
    grassImages[1] = love.graphics.newImage("assets/images/grass.png")

    -- Create multiple grass instances
    for i = 1, 8 do
        table.insert(grasses, {
            x = i * 100,
            y = screenHeight, -- Positioned at the bottom
            image = grassImages[1],
            swayOffset = math.random(0, 2 * math.pi),
            swayAmplitude = math.random(2, 4),
            swaySpeed = math.random(1, 2)
        })
    end

    -- Load cloud image
    cloudImage = love.graphics.newImage("assets/images/clouds.png")

    -- Initialize clouds with higher y positions
    for i = 1, 5 do
        table.insert(clouds, {
            x = math.random(0, screenWidth - cloudImage:getWidth()),
            y = math.random(20, 100), -- Adjusted range for higher position
            speed = math.random(10, 30),
            scale = math.random(50, 100) / 100,
            direction = math.random() < 0.5 and -1 or 1
        })
    end

    -- Load raindrop image
    raindropImage = love.graphics.newImage("assets/images/raindrop.png")

    -- Load feedback images
    checkImage = love.graphics.newImage("assets/images/check.png")
    xImage = love.graphics.newImage("assets/images/x.png")

    -- Load plane and banner images
    planeImage = love.graphics.newImage("assets/images/plane.png")
    bannerImage = love.graphics.newImage("assets/images/banner.png")

    -- Initialize planes table
    planes = {}

    -- Initialize dialogue sequence
    dialogue = {
        {
            character = "assets/images/character2.png",
            text = "Welcome to our game! We collect rainwater to sustain our community."
        },
        {
            character = "assets/images/character2.png",
            text = "Today, we need your help to calculate the volume of water collected."
        },
        {
            character = "assets/images/character2.png",
            text = "Watch as we gather rainwater, and then solve the challenge!"
        }
        -- Additional dialogue entries can be added here
    }

    -- Load Character Two's image with error handling
    local success, err = pcall(function()
        character2.image = love.graphics.newImage("assets/images/character2.png")
    end)
    if success then
        print("Character Two image loaded successfully.")
    else
        print("Error loading Character Two image:", err)
    end

    -- Load the house image with error handling
    success, err = pcall(function()
        houseImage = love.graphics.newImage("assets/images/house.png")
    end)
    if success then
        print("House image loaded successfully.")
    else
        print("Error loading house image:", err)
        -- Handle the error as needed, e.g., use a fallback or exit
    end

    -- Initialize timers and state
    planeSpawnTimer = 0
    correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel
    state = STATES.DIALOGUE
    currentDialogue = 1
    userAnswer = ""
    feedbackState = nil
    feedbackTimer = 0

    -- Initialize background color
    backgroundColor = {0.529, 0.808, 0.980}

    -- Initialize the water bar
    waterBar.waterLevel = 0
    waterBar.filled = false

    -- Ensure that the tank does not start filled
    tank.waterLevel = 10
end

-- Function called when leaving Level 1
function level1:leave()
    print("Leaving Level 1")
end

-- Function to update game logic each frame
function level1:update(dt)
    -- Update time for smooth sway animation
    time = time + dt

    if state == STATES.DIALOGUE then
        -- During dialogue, skip other updates
        return
    elseif state == STATES.MOVING then
        -- Update Character Two's position
        character2.x = character2.x + character2.velocityX * dt
        character2.y = character2.y + character2.velocityY * dt

        -- Check if Character Two is off-screen
        if character2.image and (character2.x > screenWidth + character2.image:getWidth() or 
           character2.y > screenHeight + character2.image:getHeight()) then
            state = STATES.RAINING -- Transition to RAINING state
            print("Character Two moved off-screen. Transitioning to RAINING state.")

            -- Initialize variables for RAINING state
            rainingTimer = 0
            initialWaterLevel = tank.waterLevel
            targetWaterLevel = math.min(tank.waterLevel + 50, tank.maxWater)
        end

    elseif state == STATES.RAINING then
        rainingTimer = rainingTimer + dt

        if not waterBar.filled then
            -- Fill the water bar
            waterBar.waterLevel = waterBar.waterLevel + waterBar.fillRate * dt
            if waterBar.waterLevel >= waterBar.maxWater then
                waterBar.waterLevel = waterBar.maxWater
                waterBar.filled = true
                print("Water bar filled. Starting tank filling.")
            end
        else
            -- Proceed to fill the tank as before
            -- Increase number of clouds if needed
            self:increaseClouds(dt)

            -- Update clouds' positions
            self:updateClouds(dt)

            -- Gradually darken background
            self:updateBackgroundDarkness(dt)

            -- Spawn rain particles
            self:spawnRainParticles(dt)

            -- Update rain particles
            self:updateRainParticles(dt)

            -- Check if raining animation is done
            if tank.waterLevel >= targetWaterLevel then
                state = STATES.QUESTION
                print("Raining animation done. Transitioning to QUESTION state.")
            end
        end

    elseif state == STATES.QUESTION then
        -- Update feedback timer
        if feedbackState then
            feedbackTimer = feedbackTimer - dt
            if feedbackTimer <= 0 then
                feedbackState = nil
            end
        end
    end

    -- Plane spawning logic
    planeSpawnTimer = planeSpawnTimer + dt
    if planeSpawnTimer >= planeSpawnInterval then
        planeSpawnTimer = planeSpawnTimer - planeSpawnInterval
        self:spawnPlane()
    end

    -- Update plane positions
    for i = #planes, 1, -1 do
        local plane = planes[i]
        plane.x = plane.x + plane.speed * dt

        if plane.x > screenWidth + planeImage:getWidth() then
            table.remove(planes, i)
        end
    end

    -- Spawn and update raindrops (existing raindrop system)
    raindropSpawnTimer = raindropSpawnTimer + dt
    if raindropSpawnTimer >= raindropSpawnInterval then
        raindropSpawnTimer = raindropSpawnTimer - raindropSpawnInterval
        self:spawnRaindrop()
    end

    for i = #raindrops, 1, -1 do
        local raindrop = raindrops[i]
        raindrop.y = raindrop.y + raindrop.speed * dt

        if raindrop.y > screenHeight then
            table.remove(raindrops, i)
        end
    end

    -- Update correct answer
    correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel
end

-- Function to increase number of clouds during raining
function level1:increaseClouds(dt)
    local targetCloudCount = 10 -- Increase to 10 clouds during raining
    if #clouds < targetCloudCount then
        -- Add new cloud
        table.insert(clouds, {
            x = math.random(0, screenWidth - cloudImage:getWidth()),
            y = math.random(20, 100), -- Corrected range for higher position
            speed = math.random(10, 30), -- Varying speeds for realism
            scale = math.random(50, 100) / 100,
            direction = math.random() < 0.5 and -1 or 1 -- Random direction: left or right
        })
        -- Optional: Print for debugging
        print("Spawned new cloud at y =", math.random(20, 100))
    end
end

-- Function to update clouds' positions
function level1:updateClouds(dt)
    for _, cloud in ipairs(clouds) do
        -- Move cloud horizontally based on speed and direction
        cloud.x = cloud.x + cloud.speed * cloud.direction * dt

        -- Add slight vertical drift
        local verticalDrift = math.random(-10, 10) * dt -- Adjust drift speed as needed
        cloud.y = cloud.y + verticalDrift

        -- Clamp y position to stay within [20, 100]
        cloud.y = math.max(20, math.min(100, cloud.y))

        -- Wrap around the screen
        if cloud.direction == 1 and cloud.x > screenWidth then
            cloud.x = -cloudImage:getWidth() * cloud.scale
            cloud.y = math.random(20, 100) -- Reset Y to add variability
            -- Optional: Print for debugging
            print("Cloud wrapped to left with y =", math.random(20, 100))
        elseif cloud.direction == -1 and cloud.x + cloudImage:getWidth() * cloud.scale < 0 then
            cloud.x = screenWidth
            cloud.y = math.random(20, 100) -- Corrected range
            -- Optional: Print for debugging
            print("Cloud wrapped to right with y =", math.random(20, 100))
        end
    end
end

-- Function to gradually darken the background color
function level1:updateBackgroundDarkness(dt)
    for i = 1, 3 do
        backgroundColor[i] = backgroundColor[i] + ((targetBackgroundColor[i] - backgroundColor[i]) / rainingDuration) * dt
        -- Clamp values between 0 and 1
        backgroundColor[i] = math.max(0, math.min(1, backgroundColor[i]))
    end
end

-- Function to spawn rain particles directed to the tank
function level1:spawnRainParticles(dt)
    rainParticleSpawnTimer = rainParticleSpawnTimer + dt
    if rainParticleSpawnTimer >= rainParticleSpawnInterval then
        rainParticleSpawnTimer = rainParticleSpawnTimer - rainParticleSpawnInterval
        -- For each cloud, spawn a particle directed to the tank
        for _, cloud in ipairs(clouds) do
            -- Spawn a particle directed to the tank's top center
            table.insert(rainParticles, {
                x = cloud.x + (cloudImage:getWidth() * cloud.scale) / 2,
                y = cloud.y + (cloudImage:getHeight() * cloud.scale),
                targetX = tank.x + tank.width / 2,
                targetY = tank.y,
                speed = 200 + math.random() * 100 -- Adjust speed as needed
            })
        end
    end
end

-- Function to update rain particles moving from clouds to tank
function level1:updateRainParticles(dt)
    for i = #rainParticles, 1, -1 do
        local particle = rainParticles[i]

        -- Calculate direction vector
        local dx = particle.targetX - particle.x
        local dy = particle.targetY - particle.y
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Normalize direction vector
        local vx, vy
        if distance > 0 then
            vx = (dx / distance) * particle.speed * dt
            vy = (dy / distance) * particle.speed * dt
        else
            vx, vy = 0, 0
        end

        -- Update particle position
        particle.x = particle.x + vx
        particle.y = particle.y + vy

        -- Check if particle reached the target
        if distance < 5 then
            table.remove(rainParticles, i)
            -- Increase water level in tank directly
            if tank.waterLevel < targetWaterLevel then
                tank.waterLevel = math.min(tank.waterLevel + 1, targetWaterLevel)
            end
        end
    end
end

-- Function to spawn a new raindrop (existing raindrop system)
function level1:spawnRaindrop()
    local speed = math.random(raindropSpeedMin, raindropSpeedMax)
    local scale = math.random(50, 100) / 100
    local opacity = math.random(60, 100) / 100
    table.insert(raindrops, {
        x = math.random(0, screenWidth),
        y = -10,
        speed = speed,
        scale = scale,
        opacity = opacity
    })
end

-- Function to spawn a new plane
function level1:spawnPlane()
    if #planes >= 3 then return end

    local yPositions = {100, 150, 200}
    local y = yPositions[math.random(#yPositions)]
    local scale = math.random(20, 40) / 100

    table.insert(planes, {
        x = -planeImage:getWidth() * scale,
        y = y,
        speed = planeSpeed,
        scale = scale
    })
end

-- Function to draw dialogue on the screen
function level1:drawDialogue()
    if state == STATES.DIALOGUE and dialogue[currentDialogue] then
        local dialogWidth = 400
        local dialogHeight = 100

        -- Calculate center position
        local dialogX = (screenWidth - dialogWidth) / 2
        local dialogY = (screenHeight - dialogHeight) 

        love.graphics.setFont(defaultFont)
        love.graphics.setColor(0, 0, 0, 0.7)

        love.graphics.rectangle(
            "fill",
            dialogX,
            dialogY,
            dialogWidth,
            dialogHeight,
            10, 10
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            dialogue[currentDialogue].text,
            dialogX + 10,
            dialogY + 10,
            dialogWidth - 20,
            "left"
        )
    end
    love.graphics.setColor(1, 1, 1) -- Reset color
end

-- Function to draw characters on the screen
function level1:drawCharacters()
    if character2.image then
        love.graphics.setColor(1, 1, 1) -- Ensure color is reset to white
        love.graphics.draw(
            character2.image,
            character2.x - 10, -- Slight offset for better positioning
            character2.y,
            0,
            character2.scale,
            character2.scale,
            character2.image:getWidth() / 2,
            character2.image:getHeight()
        )
    end
end

-- Function to draw rain particles directed to tank
function level1:drawRainParticles()
    love.graphics.setColor(0, 0, 1, 0.7) -- Blue with some transparency
    for _, particle in ipairs(rainParticles) do
        love.graphics.circle("fill", particle.x, particle.y, 2)
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset to white
end

-- Function to draw the vertical water bar
function level1:drawWaterBar()
    -- Remove the water bar background by commenting out or deleting these lines
    -- love.graphics.setColor(0.8, 0.8, 0.8) -- Light gray background
    -- love.graphics.rectangle("fill", waterBar.x, waterBar.y, waterBar.width, waterBar.height, 5, 5)

    -- Draw the filled portion of the water bar using the unified water color
    love.graphics.setColor(waterColor)
    local filledHeight = (waterBar.waterLevel / waterBar.maxWater) * waterBar.height

    -- *** Modified the y-coordinate to make the bar fill from top down ***
    love.graphics.rectangle("fill", waterBar.x, waterBar.y, waterBar.width, filledHeight, 5, 5)

    -- Optionally, add a border around the water bar for better visibility

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Function to draw all game elements
function level1:draw()
    -- Draw the background
    love.graphics.clear(backgroundColor[1], backgroundColor[2], backgroundColor[3])

    -- Draw clouds
    love.graphics.setColor(1, 1, 1)
    for _, cloud in ipairs(clouds) do
        love.graphics.draw(cloudImage, cloud.x, cloud.y, 0, cloud.scale, cloud.scale)
    end

    -- Draw planes
    for _, plane in ipairs(planes) do
        love.graphics.draw(
            bannerImage,
            plane.x - bannerImage:getWidth() * plane.scale,
            plane.y,
            0,
            plane.scale,
            plane.scale
        )

        love.graphics.draw(
            planeImage,
            plane.x,
            plane.y,
            0,
            plane.scale,
            plane.scale,
            planeImage:getWidth() / 2,
            planeImage:getHeight() / 2
        )
    end

    -- Draw the house image
    if houseImage then
        -- Calculate scale factors based on desired width and height
        local scaleX = house.width / houseImage:getWidth()
        local scaleY = house.height / houseImage:getHeight()

        love.graphics.setColor(1, 1, 1) -- Ensure the image is drawn with its original colors
        love.graphics.draw(
            houseImage,
            house.x,
            house.y,
            0,          -- rotation
            scaleX,     -- scaleX
            scaleY,     -- scaleY
            0,          -- origin offset X
            0           -- origin offset Y
        )
    end

    -- Draw grass
    love.graphics.setColor(1, 1, 1)
    for _, grass in ipairs(grasses) do
        local swayOffset = math.sin(time * grass.swaySpeed + grass.swayOffset) * grass.swayAmplitude
        love.graphics.draw(grass.image, grass.x + swayOffset, grass.y, 0, 0.5, 0.5, grass.image:getWidth() / 2, grass.image:getHeight())
    end

    -- Draw the tank

    -- Draw the water level using the unified water color
    love.graphics.setColor(waterColor)
    love.graphics.rectangle("fill", tank.x, tank.y + (tank.height - tank.waterLevel), tank.width, tank.waterLevel, 10, 10)

    -- Display tank information
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0)
    local textX = tank.x + tank.width + 20
    local textY = tank.y
    love.graphics.print(string.format("Radius: %.2f units", tank.radius), textX, textY)
    love.graphics.print(string.format("Height: %d units", tank.height), textX, textY + 25)
    love.graphics.print(string.format("Water Level: %d units", tank.waterLevel), textX, textY + 50)

    -- Draw the vertical water bar
    self:drawWaterBar()

    -- Display the question
    if state == STATES.QUESTION then
        love.graphics.setFont(questionFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Question:", 0, 10, screenWidth, "center")

        love.graphics.setFont(defaultFont)
        love.graphics.printf(question, 0, 40, screenWidth, "center")
        love.graphics.printf("Your Answer: " .. userAnswer, 0, 80, screenWidth, "center")
    end

    -- Display the volume equation
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(string.format("Volume = π × (radius)^2 × water level"), textX, textY + 100)
    love.graphics.print(string.format("Volume = π × (%.2f)^2 × %d", tank.radius, tank.waterLevel), textX, textY + 125)
    love.graphics.print(string.format("Correct Volume: %.2f units³", correctAnswer), textX, textY + 150)

    -- Display feedback
    if feedbackState == "correct" then
        love.graphics.setFont(feedbackFont)
        love.graphics.setColor(0, 0.6, 0)
        love.graphics.printf("Correct!", 0, screenHeight / 2, screenWidth, "center")
    elseif feedbackState == "incorrect" then
        love.graphics.setFont(feedbackFont)
        love.graphics.setColor(0.8, 0, 0)
        love.graphics.printf("Incorrect. Try Again!", 0, screenHeight / 2, screenWidth, "center")
    end

    -- Draw raindrops (existing raindrop system)
    love.graphics.setColor(1, 1, 1)
    for _, raindrop in ipairs(raindrops) do
        love.graphics.setColor(1, 1, 1, raindrop.opacity)
        love.graphics.draw(raindropImage, raindrop.x, raindrop.y, 0, raindrop.scale, raindrop.scale)
    end

    -- Draw rain particles directed to the tank
    self:drawRainParticles()

    -- Draw Character Two and dialogue
    self:drawCharacters()
    self:drawDialogue()

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Function to advance the dialogue sequence
function level1:advanceDialogue()
    currentDialogue = currentDialogue + 1
    print("Advancing Dialogue:", currentDialogue)

    if currentDialogue > #dialogue then
        state = STATES.MOVING
        character2.velocityX = 200
        character2.velocityY = 300
        print("Dialogue ended. Transitioning to MOVING state.")
    else
        state = STATES.DIALOGUE
        print("Continuing Dialogue.")
    end
end

-- Function to handle text input
function level1:textinput(text)
    if state == STATES.QUESTION then
        if text:match("%d") or text == "." then
            userAnswer = userAnswer .. text
        end
    end
end

-- Function to handle key presses
function level1:keypressed(key)
    if state == STATES.DIALOGUE then
        if key == "return" then
            self:advanceDialogue()
        end
    elseif state == STATES.QUESTION then
        if key == "return" then
            local numericAnswer = tonumber(userAnswer)
            if numericAnswer and math.abs(numericAnswer - correctAnswer) < epsilon then
                feedbackState = "correct"
                feedbackTimer = feedbackDuration
                tank.waterLevel = math.min(tank.waterLevel + 20, tank.maxWater)
            else
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                tank.waterLevel = math.max(tank.waterLevel - 20, 0)
            end
            userAnswer = ""
        elseif key == "backspace" then
            userAnswer = string.sub(userAnswer, 1, -2)
        end
    end

    if key == "escape" then
        Gamestate.switch(menu)
    end
end

-- Function to handle mouse presses
function level1:mousepressed(x, y, button, istouch, presses)
    if state == STATES.DIALOGUE and button == 1 then
        self:advanceDialogue()
    end
end

return level1
