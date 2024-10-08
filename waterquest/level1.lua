local level1 = {}

-- Local variables for level-specific assets
local clouds = {}
local grasses = {}
local grassImages = {}
local cloudImage
local raindropImage -- Add raindrop image

-- Feedback assets
local checkImage
local xImage
local feedbackState = nil -- "correct" or "incorrect"
local feedbackTimer = 0
local feedbackDuration = 2

-- House and Tank variables
local house = { x = 100, y = 300, width = 300, height = 300 }
local tank = {
    x = 450,
    y = 350,
    width = 100,
    height = 200,
    waterLevel = 50,
    maxWater = 200
}

-- Raindrop system
local raindrops = {}
local raindropSpeedMin = 300 -- Minimum speed at which raindrops fall
local raindropSpeedMax = 500 -- Maximum speed at which raindrops fall
local raindropSpawnInterval = 0.05 -- Time between each raindrop spawn
local raindropSpawnTimer = 0

-- Derived tank properties
tank.radius = tank.width / 2

-- Question and user input
local question = "Calculate the volume of water in the tank based on the current water level."
local correctAnswer = 0
local userAnswer = ""

-- Margin of error (epsilon) for floating-point comparison
local epsilon = 0.1 -- Use a reasonable margin for floating-point errors

-- Game states
local askingQuestion = true

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
            y = screenHeight,
            image = grassImages[1],
            swayOffset = math.random(0, 2 * math.pi),
            swayAmplitude = math.random(2, 4),
            swaySpeed = math.random(1, 2)
        })
    end

    -- Load cloud image
    cloudImage = love.graphics.newImage("assets/images/clouds.png")

    -- Initialize clouds
    for i = 1, 5 do
        clouds[i] = {
            x = math.random(0, screenWidth),
            y = math.random(50, 150),
            speed = math.random(20, 50),
            scale = math.random(50, 100) / 100
        }
    end

    -- Load raindrop image
    raindropImage = love.graphics.newImage("assets/images/raindrop.png") -- Add raindrop image

    -- Load feedback images
    checkImage = love.graphics.newImage("assets/images/check.png")
    xImage = love.graphics.newImage("assets/images/x.png")

    -- Calculate the initial correct answer
    correctAnswer = math.floor((math.pi * (tank.radius)^2 * tank.waterLevel) * 10) / 10 -- Formula for cylindrical tank volume
end

function level1:leave()
    print("Leaving Level 1")
end

function level1:update(dt)
    -- Update time for smooth sway animation
    time = time + dt

    -- Update cloud positions
    for _, cloud in ipairs(clouds) do
        cloud.x = cloud.x + cloud.speed * dt
        if cloud.x > screenWidth then
            cloud.x = -cloudImage:getWidth() * cloud.scale
        end
    end

    -- Spawn raindrops periodically
    raindropSpawnTimer = raindropSpawnTimer + dt
    if raindropSpawnTimer >= raindropSpawnInterval then
        raindropSpawnTimer = 0
        spawnRaindrop()
    end

    -- Update raindrop positions
    for i = #raindrops, 1, -1 do
        local raindrop = raindrops[i]
        raindrop.y = raindrop.y + raindrop.speed * dt -- Move the raindrop down

        -- Remove raindrop if it goes off the screen
        if raindrop.y > screenHeight then
            table.remove(raindrops, i)
        end
    end

    -- Update feedback timer
    if feedbackState then
        feedbackTimer = feedbackTimer - dt
        if feedbackTimer <= 0 then
            feedbackState = nil
        end
    end

    -- Recalculate the correct answer if needed (e.g., if the water level changes)
    correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel -- Volume calculation
end

-- Function to spawn raindrops
function spawnRaindrop()
    local speed = math.random(raindropSpeedMin, raindropSpeedMax)
    local scale = math.random(50, 100) / 100 -- Randomize scale between 0.5 and 1.0
    local opacity = math.random(60, 100) / 100 -- Randomize opacity between 0.6 and 1.0
    table.insert(raindrops, {
        x = math.random(0, screenWidth),
        y = -10, -- Start raindrops just off the top of the screen
        speed = speed,
        scale = scale,
        opacity = opacity
    })
end

function level1:draw()
    -- Draw the background
    love.graphics.clear(0.529, 0.808, 0.980) -- Sky blue

    -- Draw clouds
    for _, cloud in ipairs(clouds) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(cloudImage, cloud.x, cloud.y, 0, cloud.scale, cloud.scale)
    end

    -- Draw the house
    love.graphics.setColor(0.824, 0.412, 0.118) -- Brown
    love.graphics.rectangle("fill", house.x, house.y, house.width, house.height)

    -- Draw the roof
    love.graphics.setColor(0.545, 0.000, 0.000) -- Dark red
    love.graphics.polygon("fill",
        house.x, house.y,
        house.x + house.width / 2, house.y - house.height / 2,
        house.x + house.width, house.y
    )

    -- Draw the tank outline
    love.graphics.setColor(0.678, 0.847, 0.902)
    love.graphics.rectangle("line", tank.x, tank.y, tank.width, tank.height, 10, 10)

    -- Draw the water level
    love.graphics.setColor(0.000, 0.749, 1.000, 0.6)
    love.graphics.rectangle("fill", tank.x, tank.y + (tank.height - tank.waterLevel), tank.width, tank.waterLevel, 10, 10)

    -- Draw grasses
    for _, grass in ipairs(grasses) do
        local swayOffset = math.sin(time * grass.swaySpeed + grass.swayOffset) * grass.swayAmplitude
        love.graphics.draw(grass.image, grass.x + swayOffset, grass.y, 0, 0.5, 0.5, grass.image:getWidth() / 2, grass.image:getHeight())
    end

    -- Display tank dimensions beside the tank
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0)
    local textX = tank.x + tank.width + 20
    local textY = tank.y
    love.graphics.print(string.format("Radius: %.2f units", tank.radius), textX, textY)
    love.graphics.print(string.format("Height: %d units", tank.height), textX, textY + 25)
    love.graphics.print(string.format("Water Level: %d units", tank.waterLevel), textX, textY + 50)

    -- Display the question
    if askingQuestion then
        love.graphics.setFont(questionFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Question:", 20, 20, screenWidth - 40, "left")
        love.graphics.setFont(defaultFont)
        love.graphics.printf(question, 20, 50, screenWidth - 40, "left")
        love.graphics.print("Your Answer: " .. userAnswer, 20, 100)
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

    -- Draw raindrops with random scale and opacity
    for _, raindrop in ipairs(raindrops) do
        love.graphics.setColor(1, 1, 1, raindrop.opacity)
        love.graphics.draw(raindropImage, raindrop.x, raindrop.y, 0, raindrop.scale, raindrop.scale)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Use love.textinput for user input (numbers and text)
function love.textinput(text)
    if askingQuestion then
        -- Append text if it's a number or a decimal point
        if text:match("%d") or text == "." then
            userAnswer = userAnswer .. text
        end
    end
end

function level1:keypressed(key)
    if askingQuestion then
        if key == "return" then
            local numericAnswer = tonumber(userAnswer)
            -- Check if the user's answer is close enough to the correct answer (using epsilon)
            if numericAnswer and math.abs(numericAnswer - correctAnswer) < epsilon then
                feedbackState = "correct"
                feedbackTimer = feedbackDuration
                tank.waterLevel = math.min(tank.waterLevel + 20, tank.maxWater)
            else
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                tank.waterLevel = math.max(tank.waterLevel - 20, 0)
            end
        elseif key == "backspace" then
            -- Remove the last character for backspace
            userAnswer = string.sub(userAnswer, 1, -2)
        end
    end

    if key == "escape" then
        Gamestate.switch(menu)
    end
end

return level1
