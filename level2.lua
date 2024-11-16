local  level2 = {}
local Gamestate = require "gamestate"
local menu = require "menu"
local calculator = require "calculator"
local level3 = require "level3"
local calculatorActive = false
-- Define possible game states
local STATES = {
    DIALOGUE = "dialogue",
    MOVING = "moving",
    CLOUDS = "clouds",
    RAINING = "raining",
    QUESTION = "question",
    GAMEPLAY = "gameplay"
}
local menuButton = {
    x = 0,
    y = 0,
    width = 40,  -- Made smaller since we're using an arrow
    height = 40,
    text = "<"   -- Simple ASCII arrow character
}
local calculatorButton = {
    x = 730,
    y = 560,
    width = 60,
    height = 40,
    text = "CALC"
}
level2.levelCompleted = false
-- Local variables for level-specific assets
local clouds = {}
local cloudSpawnInterval = 0.3 -- **Decreased from 0.5 to 0.3** seconds for faster cloud spawning
local cloudSpawnTimer = 0
local desiredNumberOfClouds = 3 -- You can adjust this if needed
local grasses = {}
local grassImages = {}
local cloudImage
local raindropImage
-- Banner wave parameters
local bannerWaveTime = 0
local bannerWaveSpeed = 4
local bannerWaveAmplitude = 3
local bannerWavePoints = 8

-- Feedback assets
local checkImage
local xImage
local feedbackState = nil -- "correct" or "incorrect"
local feedbackTimer = 0
local feedbackDuration = 2

-- School and Roof variables (replacing the house)
local school = { x = 50, y = 100, width = 600, height =2000 }
local roof = {
    baseLength = 400, -- Length of the base of the roof
    baseWidth = 150,  -- Width/depth of the building
    height = 140      -- Height of the roof (from base to peak)
}

-- Main building and roof offset (for access in multiple functions)
local mainBuilding = {}
local roofOffset = 40 -- Adjust this value to change the slant of the main roof

-- Tank variables
local tank = {
    x = 0, -- We'll set this in level2:enter()
    y = 350,
    width = 300,
    height = 200,
    waterLevel = 10,
    maxWater = 200,
    image = nil -- Placeholder for the tank image
}
function level2:toWorldCoords(x, y)
    return (x - offsetX) / scale, (y - offsetY) / scale
end

-- Derived tank properties
tank.radius = 2  -- Using radius 2 means area is 12 units (3 * 2 * 2)
tank.maxWater = 50  -- Keep maximum water level relatively small
tank.waterLevel = 0

-- Tube variables
local tubeSegments = {}
local waterDroplets = {}
local tubeDropletSpawnInterval = 0.01 -- **Decreased from 0.05 to 0.02** for faster droplet spawning
local tubeDropletSpawnTimer = 0

-- Rain systems
local raindrops = {}
local raindropSpeedMin = 300
local raindropSpeedMax = 800
local raindropSpawnInterval = 0.02 -- **Decreased from 0.05 to 0.02** for faster raindrop spawning
local raindropSpawnTimer = 0
local maxRaindrops = 10-- Limit the number of raindrops

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
local planeSpawnInterval = 10 -- **Decreased from 7 to 3** seconds between plane spawns
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
local initialBackgroundColor = {0.529, 0.808, 0.980} -- Initial sky blue background
local targetBackgroundColor = {0.5, 0.7, 0.7} -- Darker background color
local backgroundColor = {0.529, 0.808, 0.980} -- Current background color

local rainingTimer = 0
local rainingDuration = 1 -- **Decreased from 2 to 1** second for faster sky darkening
local initialWaterLevel
local targetWaterLevel

-- Define a unified water color
local waterColor = {0.000, 0.749, 1.000, 0.6} -- Same as the tank's water color

-- Add these to the top level variables
local waterMaskPoints = {}
local waterWaveTime = 2
local waterWaveSpeed = 5
local waterWaveHeight = 2

-- Variables for background color transition back to initial color
local backgroundReturnTimer = 0
local backgroundReturnDuration = 1 -- **Decreased from 2 to 1** second for faster sky brightening

-- Fade-Out Variables
local rainFadeOut = false
local rainFadeDuration = 1 -- Duration of fade-out in seconds
local rainFadeTimer = 0

-- Function to generate the water mask points
function level2:generateWaterMaskPoints()
    -- These points define the shape of the water container
    -- Adjust these coordinates to match your tank.png shape
    waterMaskPoints = {
        -- Left side curve
        {x = 0.1, y = 0.9},  -- Bottom left
        {x = 0.05, y = 0.7}, -- Left curve control
        {x = 0.1, y = 0.5},  -- Left middle

        -- Right side curve
        {x = 0.9, y = 0.5},  -- Right middle
        {x = 0.95, y = 0.7}, -- Right curve control
        {x = 0.9, y = 0.9},  -- Bottom right
    }
end

-- Function called when entering Level 1
-- Function called when entering Level 1
function level2:enter()
    print("Entering Level 1")
    -- Load fonts and other assets with error handling
    local success, err = pcall(function()
        defaultFont = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 18)
        questionFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 22)
        feedbackFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 28)
        titleFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 36)
        raindropImage = love.graphics.newImage("assets/images/raindrop.png")
        -- Load grass images
        grassImages[1] = love.graphics.newImage("assets/images/grass.png")
        wallTexture = love.graphics.newImage("assets/images/wall_texture.jpeg")
        columnTexture = love.graphics.newImage("assets/images/wall_texture.jpeg")
        menuButtonFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 18)
        -- Load cloud image
        cloudImage = love.graphics.newImage("assets/images/clouds.png")

        -- Load feedback images
        checkImage = love.graphics.newImage("assets/images/check.png")
        xImage = love.graphics.newImage("assets/images/x.png")

        -- Load plane and banner images
        planeImage = love.graphics.newImage("assets/images/plane.png")
        bannerImage = love.graphics.newImage("assets/images/banner.png")

        -- Load Character Two's image
        character2.image = love.graphics.newImage("assets/images/character2.png")

        -- Load tank image
        tank.image = love.graphics.newImage("assets/images/tank.png")
        -- Load the rain sound
        rainSound = love.audio.newSource("assets/sounds/rain.mp3", "stream")
        rainSound:setLooping(true)        -- Ensure the sound loops continuously
        rainSound:setVolume(0.5)          -- Set the desired volume (0.0 to 1.0)
        kenyanFlagImage = love.graphics.newImage("assets/images/flag_of_kenya.png")
        calculator:init()
        calculator:setPosition(screenWidth - 400, 100)  -- Set position but don't activate
        calculator:deactivate()
        self:updateScale()
        
        
        
        

    end)

    if not success then
        print("Error loading assets:", err)
        -- Handle the error, possibly by exiting the game or loading fallback assets
        -- love.event.quit()
        return
    else
        print("All assets loaded successfully.")
    end

    -- Create multiple grass instances
    for i = 1, 8 do
        table.insert(grasses, {
            x = i * 100,
            y = screenHeight + 40, -- Adjusted to position grass at the bottom
            image = grassImages[1],
            swayOffset = math.random(0, 2 * math.pi),
            swayAmplitude = math.random(2, 4),
            swaySpeed = math.random(1, 2)
        })
    end

    -- Initialize clouds as empty
    clouds = {}

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
            text = "When it rains, the water flows from the roof to the tank."
        },
        {
            character = "assets/images/character2.png",
            text = "Measure the tank first, then calculate the volume of the tank when it is full! Keep in mind the radius is 2."
        }
        -- Additional dialogue entries can be added here
    }

    -- Generate water mask points
    self:generateWaterMaskPoints()

    -- Initialize timers and state
    planeSpawnTimer = 0
    -- Remove the initial setting of correctAnswer here
    -- correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel
    state = STATES.DIALOGUE
    currentDialogue = 1
    userAnswer = ""
    feedbackState = nil
    feedbackTimer = 0

    -- Initialize background color
    backgroundColor = {initialBackgroundColor[1], initialBackgroundColor[2], initialBackgroundColor[3]}

    -- Ensure that the tank does not start filled
    

    -- Define dimensions for the main building
    mainBuilding = {
        x = school.x + 20, -- Slight offset for better positioning
        y = school.y + roof.height, -- Position the building right below the roof
        width = school.width,
        height = 300 -- Reduced from 'school.height - roof.height' to fit on screen
    }

    -- Update tank position to be directly under the water tube
    -- Align the center of the tank with the tube's end
    tank.x = mainBuilding.x + mainBuilding.width - tank.width / 2

    -- Define tube segments based on the school and tank positions
    tubeSegments = {
        {
            startX = mainBuilding.x,
            startY = mainBuilding.y + 10, -- Bottom edge of the roof (gutter starts here)
            endX = mainBuilding.x + mainBuilding.width, -- Horizontal end of the gutter
            endY = mainBuilding.y -- Same y-coordinate along the bottom of the roof
        },
        {
            startX = mainBuilding.x + mainBuilding.width, -- Start at the end of the gutter
            startY = mainBuilding.y,
            endX = mainBuilding.x + mainBuilding.width, -- Vertical down to the tank
            endY = tank.y
        }
    }

    -- Adjust Character Two's velocity for faster movement
    character2.velocityX = 400 -- Increased from 200 to 400
    character2.velocityY = 600 -- Increased from 300 to 600
    self:updateScale()
    
end


-- Function called when leaving Level 1
function level2:leave()
    print("Leaving Level 1")
    
    -- **Stop and dispose of the rain sound if it's playing**
    if rainSound then
        love.audio.stop(rainSound)
        rainSound:release()
        rainSound = nil
        print("Rain sound stopped and released.")
    end
    
    -- [Clean up other resources if necessary]...
end
function level2:updateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local scaleX = windowWidth / screenWidth
    local scaleY = windowHeight / screenHeight
    scale = math.min(scaleX, scaleY)
    
    -- Calculate offset to center the content
    offsetX = (windowWidth - (screenWidth * scale)) / 2
    offsetY = (windowHeight - (screenHeight * scale)) / 2
end

function level2:resize(w, h)
    self:updateScale()
end
function level2:update(dt)
    -- Update time for smooth sway animation
    time = time + dt

    -- Handle calculator updates first
    if calculatorActive and calculator then
        calculator:update(dt)
        return -- Exit early if calculator is active
    end

    -- Handle feedback state updates
    if state == STATES.FEEDBACK then
        feedbackTimer = feedbackTimer - dt
        if feedbackTimer <= 0 then
            state = STATES.QUESTION
            answerProcessed = false
            -- Update correct answer for new water level
            correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel
        end
        return -- Exit early if in feedback state
    end

    -- Regular state updates
    if state == STATES.DIALOGUE then
        return -- Skip other updates during dialogue
    elseif state == STATES.MOVING then
        -- Update Character Two's position with negative velocity for leftward movement
        character2.x = character2.x - character2.velocityX * dt  -- Changed to minus
        character2.y = character2.y + character2.velocityY * dt

        -- Check if Character Two is off-screen to the left
        if character2.image and (character2.x < -character2.image:getWidth() or  -- Changed condition
           character2.y > screenHeight + character2.image:getHeight()) then
            state = STATES.CLOUDS
            cloudSpawnTimer = 0
            rainingTimer = 0
            initialWaterLevel = tank.waterLevel
            targetWaterLevel = math.min(tank.waterLevel + 10, tank.maxWater)
        end
    elseif state == STATES.CLOUDS then
        -- Cloud spawning and updates
        if #clouds < desiredNumberOfClouds then
            cloudSpawnTimer = cloudSpawnTimer + dt
            if cloudSpawnTimer >= cloudSpawnInterval then
                cloudSpawnTimer = cloudSpawnTimer - cloudSpawnInterval
                self:spawnCloud()
            end
        end

        -- Update existing clouds
        local allCloudsStationary = true
        for i = #clouds, 1, -1 do
            local cloud = clouds[i]
            if cloud.state == 'entering' then
                cloud.x = cloud.x + cloud.speed * dt
                if cloud.x >= 0 then
                    cloud.state = 'stationary'
                    cloud.x = 0
                else
                    allCloudsStationary = false
                end
            elseif cloud.state == 'stationary' then
                cloud.x = cloud.x + cloud.speed * dt * 0.05
            else
                allCloudsStationary = false
            end
        end

        if allCloudsStationary and #clouds >= desiredNumberOfClouds then
            state = STATES.RAINING
            rainingTimer = 0
        end
    elseif state == STATES.RAINING then
        self:updateRainingState(dt)
    elseif state == STATES.QUESTION then
        self:updateQuestionState(dt)
    end

    -- Update planes
    self:updatePlanes(dt)
end

-- Helper function to update raining state
function level2:updateRainingState(dt)
    rainingTimer = rainingTimer + dt

    if rainingTimer <= rainingDuration then
        -- Sky darkening
        local t = rainingTimer / rainingDuration
        for i = 1, 3 do
            backgroundColor[i] = initialBackgroundColor[i] + 
                t * (targetBackgroundColor[i] - initialBackgroundColor[i])
        end
    else
        -- Handle rain effects
        if rainSound and not rainSound:isPlaying() then
            love.audio.play(rainSound)
        end

        self:updateRaindrops(dt)
        self:updateWaterDroplets(dt)
        self:updateCloudsInRain(dt)
    end
end

-- Helper function to update planes
function level2:updatePlanes(dt)
    planeSpawnTimer = planeSpawnTimer + dt
    if planeSpawnTimer >= planeSpawnInterval then
        planeSpawnTimer = planeSpawnTimer - planeSpawnInterval
        self:spawnPlane()
    end

    for i = #planes, 1, -1 do
        local plane = planes[i]
        plane.x = plane.x + plane.speed * dt
        if plane.x > screenWidth + planeImage:getWidth() then
            table.remove(planes, i)
        end
    end
end

-- Function to spawn a new raindrop
function level2:spawnRaindrop()
    if #raindrops >= maxRaindrops then return end

    local speed = math.random(raindropSpeedMin, raindropSpeedMax)
    local scale = math.random(50, 100) / 100
    local opacity = math.random(60, 100) / 100
    table.insert(raindrops, {
        x = math.random(mainBuilding.x, mainBuilding.x + mainBuilding.width),
        y = -10,
        speed = speed,
        scale = scale,
        opacity = opacity
    })
end

-- Function to spawn a water droplet in the tube
function level2:spawnTubeWaterDroplet()
    local droplet = {
        segment = 1,
        x = tubeSegments[1].startX,
        y = tubeSegments[1].startY,
        speed = 150 -- **Increased from 100 to 150** for faster droplet movement
    }
    table.insert(waterDroplets, droplet)
end

-- Function to spawn a new plane
function level2:spawnPlane()
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

-- Function to spawn a new cloud
function level2:spawnCloud()
    local cloud = {
        x = -cloudImage:getWidth() / 2, -- Start closer to the screen
        y = math.random(20, 30),
        speed = math.random(160, 320), -- **Further increased speed for faster cloud movement**
        scale = math.random(50, 100) / 100,
        state = 'entering'
    }
    table.insert(clouds, cloud)
end

-- Function to draw dialogue on the screen
function level2:drawDialogue()
    if state == STATES.DIALOGUE and dialogue[currentDialogue] then
        local dialogWidth = 400
        local dialogHeight = 100

        -- Calculate center position
        local dialogX = (screenWidth - dialogWidth) / 2 - 10
        local dialogY = screenHeight - dialogHeight - 50

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
function level2:drawCharacters()
    if character2.image then
        love.graphics.setColor(1, 1, 1) -- Ensure color is reset to white
        love.graphics.draw(
            character2.image,
            character2.x - 530, -- Slight offset for better positioning
            character2.y,
            0,
            character2.scale,
            character2.scale,
            character2.image:getWidth() / 2,
            character2.image:getHeight()
        )
    end
end
function level2:drawWindows()
    local windowWidth = 30
    local windowHeight = 60
    local numWindows = 3
    local spacing = (mainBuilding.width - numWindows * windowWidth) / (numWindows + 1)
    local wy = mainBuilding.y + 60

    for i = 1, numWindows do
        local wx = mainBuilding.x + spacing * i + windowWidth * (i - 1)
        
        -- Draw window frame
        love.graphics.setColor(0.2, 0.2, 0.2) -- Dark gray frame
        love.graphics.rectangle("fill", wx - 2, wy - 2, windowWidth + 4, windowHeight + 4)
        
        -- Draw window glass with higher transparency and more saturated blue tint
        love.graphics.setColor(0.7, 0.85, 1.0, 0.4) -- Increase blue component and alpha
        love.graphics.rectangle("fill", wx, wy, windowWidth, windowHeight)

        -- Draw window panes with darker color for better visibility
        love.graphics.setColor(0.1, 0.1, 0.1, 0.7) -- Darker and more opaque panes
        love.graphics.setLineWidth(2) -- Make panes thicker
        -- Vertical pane
        love.graphics.line(wx + windowWidth / 2, wy, wx + windowWidth / 2, wy + windowHeight)
        -- Horizontal pane
        love.graphics.line(wx, wy + windowHeight / 2, wx + windowWidth, wy + windowHeight / 2)
        love.graphics.setLineWidth(1) -- Reset line width
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Function to draw the tube (gutter)
function level2:drawTube()
    love.graphics.setColor(0.6, 0.6, 0.6) -- Tube color
    local tubeWidth = 10
    -- Draw horizontal segment (gutter along the roof)
    local x = tubeSegments[1].startX
    local y = tubeSegments[1].startY - tubeWidth / 2
    local width = tubeSegments[1].endX - tubeSegments[1].startX
    love.graphics.rectangle("fill", x, y, width, tubeWidth)
    -- Draw vertical segment (downspout to the tank)
    x = tubeSegments[2].startX - tubeWidth / 2
    y = tubeSegments[2].startY
    local height = tubeSegments[2].endY - tubeSegments[2].startY
    love.graphics.rectangle("fill", x, y, tubeWidth, height)
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
-- Function to modify tube position and draw
function level2:drawTube()
    love.graphics.setColor(0.6, 0.6, 0.6) -- Tube color
    local tubeWidth = 10

    -- Draw horizontal segment (gutter along the roof)
    local x = tubeSegments[1].startX
    local y = tubeSegments[1].startY - tubeWidth / 2
    local width = tubeSegments[1].endX - tubeSegments[1].startX
    love.graphics.rectangle("fill", x, y, width, tubeWidth)

    -- Draw vertical segment (downspout to the tank)
    x = tubeSegments[2].startX - tubeWidth / 2
    y = tubeSegments[2].startY
    local height = tubeSegments[2].endY - tubeSegments[2].startY - 50 -- Shortened to make room for new segments
    love.graphics.rectangle("fill", x, y, tubeWidth, height)

    -- Draw horizontal extension
    local extensionLength = 50
    love.graphics.rectangle("fill", x, y + height, extensionLength, tubeWidth)

    -- Draw final vertical segment
    love.graphics.rectangle("fill", x + extensionLength - tubeWidth/2, y + height, tubeWidth, 50)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Function to draw the school building
local function drawTexturedPolygon(texture, mode, ...)
    local vertices = {...}
    
    -- Create mesh with the vertices
    local mesh = love.graphics.newMesh({
        {"VertexPosition", "float", 2},
        {"VertexTexCoord", "float", 2}
    }, #vertices/2, "fan", "static")
    
    -- Calculate bounds
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for i = 1, #vertices, 2 do
        local x, y = vertices[i], vertices[i + 1]
        minX = math.min(minX, x)
        minY = math.min(minY, y)
        maxX = math.max(maxX, x)
        maxY = math.max(maxY, y)
    end
    
    local width = maxX - minX
    local height = maxY - minY
    
    -- Set vertices with texture coordinates
    for i = 1, #vertices, 2 do
        local x, y = vertices[i], vertices[i + 1]
        local u = (x - minX) / width
        local v = (y - minY) / height
        mesh:setVertex((i-1)/2 + 1, {
            x, y,
            u, v
        })
    end
    
    mesh:setTexture(texture)
    love.graphics.draw(mesh)
    mesh:release()
end
function level2:drawShadows()
    love.graphics.setColor(0, 0, 0, 0.2) -- Semi-transparent black for shadows
    local shadowOffsetX = 30 -- Horizontal shadow offset (adjust as needed)
    local shadowOffsetY = 50 
    -- Define shadow polygon points covering both roof and tube
    local shadowPoints = {
        -- Shadow for the roof
        mainBuilding.x, mainBuilding.y,  -- Bottom-left corner of the roof
        mainBuilding.x + mainBuilding.width, mainBuilding.y,  -- Bottom-right corner of the roof
        mainBuilding.x + mainBuilding.width + shadowOffsetX, mainBuilding.y + shadowOffsetY,  -- Offset bottom-right
        mainBuilding.x + shadowOffsetX, mainBuilding.y + shadowOffsetY,  -- Offset bottom-left
    }

    -- Draw the shadow polygon
    love.graphics.polygon("fill", unpack(shadowPoints))

    love.graphics.setColor(1, 1, 1) -- Reset color
end
function level2:drawStairs()
    -- Parameters for stairs
    local numSteps = 3                    -- Fixed number of steps
    local stepHeight = 30                 -- Height of each step
    local stepWidthMultiplier = 1.05       -- Controls the width difference between steps
    local baseStepWidth = mainBuilding.width  -- Width of the top step (matches building)

    -- Starting position of the stairs (smallest/top step aligns with building)
    local startX = mainBuilding.x
    local startY = mainBuilding.y + mainBuilding.height-50   -- Adjust position closer to the bottom

    -- Draw each step from top to bottom
    for i = 1, numSteps do
        local currentStepWidth = baseStepWidth * (stepWidthMultiplier ^ (i - 1))
        local stepX = startX - (currentStepWidth - baseStepWidth) / 2
        local stepY = startY + (i - 1) * stepHeight
        
        -- Draw the step with texture
        love.graphics.setColor(1, 1, 1, 1)
        drawTexturedPolygon(wallTexture, "fill",
            stepX, stepY,                           -- Top-left
            stepX + currentStepWidth, stepY,        -- Top-right
            stepX + currentStepWidth, stepY + stepHeight, -- Bottom-right
            stepX, stepY + stepHeight               -- Bottom-left
        )
        
        -- Draw subtle edge lines
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.line(
            stepX, stepY,
            stepX + currentStepWidth, stepY
        )
    end

    -- Reset color and line width
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Function to draw the school building with columns
function level2:drawSchool()
    -- Existing parameters
    local numWaves = 40         -- Number of complete sine waves across the roof's width
    local amplitude = 3         -- Amplitude of the waves (controls the height of the squiggles)
    local numPoints = 200       -- Total number of points to define the wavy line
    local pointsPerWave = numPoints / numWaves
    local shadowOffsetX = 30    -- Horizontal shadow offset
    local shadowOffsetY = 50    -- Vertical shadow offset
    
    -- Draw the main building wall with texture
    drawTexturedPolygon(wallTexture, "fill",
        mainBuilding.x, mainBuilding.y,
        mainBuilding.x + mainBuilding.width, mainBuilding.y,
        mainBuilding.x + mainBuilding.width, mainBuilding.y + mainBuilding.height + 100,
        mainBuilding.x, mainBuilding.y + mainBuilding.height + 100
    )
    
    -- Parameters for the wavy roof
    local roofWidth = mainBuilding.width
    local roofHeight = roof.height
    local roofX = mainBuilding.x
    local roofY = mainBuilding.y
    
    -- Initialize an empty table to store roof points
    local roofPoints = {}
    
    -- Add the bottom-left point of the roof
    table.insert(roofPoints, roofX)
    table.insert(roofPoints, roofY)
    
    -- Generate points along the bottom edge with sine wave variations
    for i = 1, numPoints do
        local t = i / numPoints                 -- Normalized position [0,1]
        local x = roofX + t * roofWidth         -- Current x position
        local sineValue = math.sin(t * numWaves * math.pi * 2) -- Sine wave for y variation
        local y = roofY + sineValue * amplitude -- Current y position with wave offset
    
        table.insert(roofPoints, x)
        table.insert(roofPoints, y)
    end
    
    -- Add the top-right point of the roof
    table.insert(roofPoints, roofX + roofWidth + roofOffset)
    table.insert(roofPoints, roofY - roofHeight)
    
    -- Add the top-left point of the roof to close the polygon
    table.insert(roofPoints, roofX + roofOffset)
    table.insert(roofPoints, roofY - roofHeight)
    
    -- Draw the wavy roof polygon with texture
    love.graphics.setColor(0.0, 0.2, 0.8, 0.9)
    drawTexturedPolygon(roofTexture, "fill", unpack(roofPoints)) -- Blue with some transparency
    love.graphics.setColor(0.0, 0.0, 0.0, 0.7) 
    drawTexturedPolygon(roofTexture, "fill", unpack(roofPoints))
    
    -- Optional: Draw the outline of the roof for better visibility
    love.graphics.setColor(0.0, 0.2, 0.8, 0.4) -- Slightly different blue for the outline
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", unpack(roofPoints))
    love.graphics.setLineWidth(1)
    
    -- Draw shadows from roof to wall
    local shadowPoints = {
        roofX, roofY,  -- Bottom-left corner
        roofX + roofWidth, roofY,  -- Bottom-right corner
        roofX + roofWidth + shadowOffsetX, roofY + shadowOffsetY,  -- Offset bottom-right
        roofX + shadowOffsetX, roofY + shadowOffsetY  -- Offset bottom-left
    }
    
    -- Draw the shadow polygon
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.polygon("fill", unpack(shadowPoints))
    
    love.graphics.setColor(1, 1, 1)
    
    -- Draw Left Side Wall with texture
    love.graphics.setColor(1, 1, 1) 
    drawTexturedPolygon(wallTexture, "fill",
        roofX, roofY + 5,
        roofX + roofOffset, roofY + 5,
        roofX + roofOffset, roofY + mainBuilding.height,
        roofX, roofY + mainBuilding.height
    )

    self:drawWindows()
    self:drawColumns() -- Call the separate column drawing function
    self:drawStairs()

    -- Draw flagpole and flag
    love.graphics.setColor(0.1, 0.1, 0.1)
    local flagpoleX = roofX + roofWidth + roofOffset + 30
    love.graphics.rectangle("fill", flagpoleX, roofY - roofHeight - 30, 3, mainBuilding.height + roofHeight + 60)
    
    -- Initialize wave parameters for flag animation
    if not level2.flagWaveTime then
        level2.flagWaveTime = 0
        level2.flagWaveSpeed = 4
        level2.flagWaveAmplitude = 3
        level2.flagPoints = 8
    end

    level2.flagWaveTime = level2.flagWaveTime + love.timer.getDelta() * level2.flagWaveSpeed

    -- Create animated flag points
    local flagWidth = 77
    local flagHeight = 80
    local points = {}
    
    -- Generate wavy points for flag
    for i = 0, level2.flagPoints do
        local xPercent = i / level2.flagPoints
        local xPos = flagpoleX + 3 + (xPercent * flagWidth)
        local waveOffset = math.sin(level2.flagWaveTime + (xPercent * 3)) * level2.flagWaveAmplitude
        
        table.insert(points, xPos)
        table.insert(points, roofY - roofHeight - 30 + waveOffset)
        table.insert(points, xPos)
        table.insert(points, roofY - roofHeight + 50 + waveOffset)
    end

    -- Draw the flag with wrinkle shadows
    for i = 1, #points / 4 - 1 do
        local x1, y1 = points[i * 4 - 3], points[i * 4 - 2]
        local x2, y2 = points[i * 4 - 1], points[i * 4]
        local x3, y3 = points[i * 4 + 1], points[i * 4 + 2]
        local x4, y4 = points[i * 4 + 3], points[i * 4 + 4]
        
        local wavePhase = math.sin(level2.flagWaveTime + (i / #points * 3))
        local shadowIntensity = math.abs(wavePhase) * 0.3
        
        local mesh = love.graphics.newMesh({
            {x1, y1, (i - 1) / (level2.flagPoints - 1), 0},
            {x3, y3, i / (level2.flagPoints - 1), 0},
            {x4, y4, i / (level2.flagPoints - 1), 1},
            {x2, y2, (i - 1) / (level2.flagPoints - 1), 1}
        }, "fan", "static")
        
        mesh:setTexture(kenyanFlagImage)
        love.graphics.setColor(1 - shadowIntensity, 1 - shadowIntensity, 1 - shadowIntensity, 1)
        love.graphics.draw(mesh)
        mesh:release()
        
        if wavePhase > 0.7 then
            love.graphics.setColor(0, 0, 0, 0.1)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    -- Add faint white seams
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    
    for wave = 1, numWaves do
        local pointIndex = math.floor(wave * pointsPerWave)
        if pointIndex * 2 + 2 <= #roofPoints then
            local x = roofPoints[pointIndex * 2 - 1]
            local y = roofPoints[pointIndex * 2]
            love.graphics.line(x, y, x + 30, roofY - 130)
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

function level2:drawColumns()
    local numColumns = 4
    local columnWidth = 30
    local columnHeight = mainBuilding.height * 1.8
    local columnSpacing = (mainBuilding.width - (numColumns * columnWidth)) / (numColumns + 1)
    
    for i = 1, numColumns do
        local columnX = mainBuilding.x + columnSpacing * i + (columnWidth * (i - 1))
        local columnY = mainBuilding.y+5
        
        -- Column shadow
        love.graphics.setColor(0.6, 0.6, 0.6, 0.3)
        love.graphics.rectangle("fill", columnX + 5, columnY, columnWidth, columnHeight)
        
        -- Main column body
        love.graphics.setColor(1, 1, 1)
        drawTexturedPolygon(columnTexture, "fill",
            columnX, columnY,
            columnX + columnWidth, columnY,
            columnX + columnWidth, columnY + columnHeight,
            columnX, columnY + columnHeight
        )
        
        -- Column capital
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", columnX - 5, columnY, columnWidth + 10, 20)
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.rectangle("fill", columnX - 3, columnY + 20, columnWidth + 6, 5)
        
        -- Column base
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", columnX - 5, columnY + columnHeight - 25, columnWidth + 10, 25)
        
        -- Vertical grooves
        love.graphics.setColor(0, 0, 0, 0.1)
        for j = 1, 2 do
            local grooveX = columnX + (columnWidth * j / 3)
            love.graphics.rectangle("fill", grooveX, columnY + 25, 2, columnHeight - 50)
        end
        
        -- Column highlights
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("fill", columnX + 2, columnY + 25, 3, columnHeight - 50)
    end
    
    love.graphics.setColor(1, 1, 1)

end
-- Function to update raindrops
function level2:updateRaindrops(dt)
    -- Spawn raindrops
    raindropSpawnTimer = raindropSpawnTimer + dt
    if raindropSpawnTimer >= raindropSpawnInterval then
        raindropSpawnTimer = raindropSpawnTimer - raindropSpawnInterval
        self:spawnRaindrop()
    end

    -- Update raindrops
    for i = #raindrops, 1, -1 do
        local raindrop = raindrops[i]
        raindrop.y = raindrop.y + raindrop.speed * dt

        -- Check if raindrop hits the roof
        if raindrop.y >= mainBuilding.y - roof.height and raindrop.y <= mainBuilding.y and
           raindrop.x >= mainBuilding.x and raindrop.x <= mainBuilding.x + mainBuilding.width then
            -- Remove the raindrop and spawn a droplet in the tube
            table.remove(raindrops, i)
            self:spawnTubeWaterDroplet()
        elseif raindrop.y > screenHeight then
            table.remove(raindrops, i)
        end
    end
end

-- Function to draw raindrops
function level2:drawRaindrops()
    love.graphics.setColor(1, 1, 1) -- Ensure color is reset
    for _, raindrop in ipairs(raindrops) do
        love.graphics.setColor(1, 1, 1, raindrop.opacity)
        love.graphics.draw(raindropImage, raindrop.x, raindrop.y, 0, raindrop.scale, raindrop.scale)
    end
    love.graphics.setColor(1, 1, 1) -- Reset color
end


-- Function to draw all game elements
function level2:draw()
    love.graphics.clear(0.529, 0.808, 0.980)
    
    -- Draw the school building
    love.graphics.push()
    -- Clear the screen with the background color
    love.graphics.clear(backgroundColor[1], backgroundColor[2], backgroundColor[3])
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)

    -- Draw correct answer display if it exists
    if level2.correctAnswerDisplay and level2.displayTimer > 0 then
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(level2.correctAnswerDisplay, 10, 10)
        level2.displayTimer = level2.displayTimer - love.timer.getDelta()
    end
    
    -- Draw clouds
    love.graphics.setColor(1, 1, 1)
    for _, cloud in ipairs(clouds) do
        love.graphics.draw(cloudImage, cloud.x, cloud.y - 150, 0, cloud.scale, cloud.scale)
        love.graphics.draw(cloudImage, cloud.x, cloud.y - 200, 0, cloud.scale, cloud.scale)
    end

    -- Draw planes
    for _, plane in ipairs(planes) do
        love.graphics.draw(
            bannerImage,
            plane.x - 50 - bannerImage:getWidth() * plane.scale,
            plane.y - 20,
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
    
    -- Draw the school building
    
    self:drawSchool()
    
    


    -- Draw the tube (gutter)
    self:drawColumns()
    self:drawTube()
    self.drawShadows()
    
    self:drawStairs()
    

    local roofWidth = mainBuilding.width
    local roofHeight = roof.height
    local roofX = mainBuilding.x
    local roofY = mainBuilding.y
    love.graphics.setColor(0.8, 0.8, 0.8)
    drawTexturedPolygon(wallTexture, "fill",
        roofX + roofWidth+3, roofY, -- Top-left corner
        roofX + roofWidth + roofOffset, roofY - roofHeight, -- Top-right corner
        roofX + roofWidth + roofOffset, mainBuilding.y + mainBuilding.height, -- Bottom-right corner
        roofX + roofWidth, mainBuilding.y + mainBuilding.height -- Bottom-left corner
    )
    
    

    -- --- DRAW EXTENSION WALL ---
    local shiftRight = 40
    local shapeHeight = mainBuilding.height * 0.83
    local verticalAdjustment = mainBuilding.height - shapeHeight

    love.graphics.setColor(0.8, 0.8, 0.8) -- Slightly darker wall color for extension

    love.graphics.push()
        love.graphics.translate(
            mainBuilding.x + mainBuilding.width + roofOffset + shiftRight,
            mainBuilding.y - roof.height + verticalAdjustment +85
        )
        love.graphics.scale(-1, 1)
        drawTexturedPolygon(wallTexture, "fill",
            0, 0,                                -- Top-left corner (pivot point)
            roofOffset, -roof.height,            -- Top-right corner
            roofOffset, shapeHeight,             -- Bottom-right corner
            0, shapeHeight                       -- Bottom-left corner
        )
    love.graphics.pop()
    
    

    -- Draw water droplets in the tube
    love.graphics.setColor(waterColor)
    for _, droplet in ipairs(waterDroplets) do
        love.graphics.circle("fill", droplet.x, droplet.y, 5)
    end
    love.graphics.setColor(1, 1, 1) -- Reset color
   
    -- Draw the tank image first (behind grass)
    if tank.image then
        love.graphics.setColor(1, 1, 1)
        local scale = tank.width / tank.image:getWidth() -- Assuming uniform scaling
        love.graphics.draw(tank.image, tank.x, tank.y, 0, scale, scale, 0, 0) -- Origin at (0,0)
    else
        print("Tank image not loaded.")
    end
   
    -- Draw the water level inside the tank using the new method
    self:drawTankWater()
    

    -- Draw grass (in front of tank)
    love.graphics.setColor(1, 1, 1)
    for _, grass in ipairs(grasses) do
        local swayOffset = math.sin(time * grass.swaySpeed + grass.swayOffset) * grass.swayAmplitude
        love.graphics.draw(grass.image, grass.x + swayOffset, grass.y, 0, 0.5, 0.5, grass.image:getWidth() / 2, grass.image:getHeight())
    end
    
    -- Display tank information
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0)
    local textX = tank.x + tank.width + 20
    local textY = tank.y

    -- Display the question
    if state == STATES.QUESTION then
        -- Draw a fancy question box with shadow
        local boxWidth = screenWidth * 0.8
        local boxHeight = 160
        local boxX = (screenWidth - boxWidth) / 2
        local boxY = 10
        
        -- Draw shadow
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", boxX + 5, boxY + 5, boxWidth, boxHeight, 15, 15)
        
        -- Draw main box with water-themed gradient
        local gradient = {
            {0.000, 0.749, 1.000, 0.9},  -- Light blue (matching water color)
            {0.000, 0.549, 0.800, 0.9}   -- Darker blue
        }
        for i = 0, boxHeight do
            local t = i / boxHeight
            local color = {
                gradient[1][1] * (1-t) + gradient[2][1] * t,
                gradient[1][2] * (1-t) + gradient[2][2] * t,
                gradient[1][3] * (1-t) + gradient[2][3] * t,
                gradient[1][4]
            }
            love.graphics.setColor(unpack(color))
            love.graphics.rectangle("fill", boxX, boxY + i, boxWidth, 1, 15, 15)
        end
        
        -- Draw water droplet decorations
        love.graphics.setColor(1, 1, 1, 0.4)
        local time = love.timer.getTime()
        for i = 1, 3 do
            local dropX = boxX + 30 + (i * 50)
            local dropY = boxY + 15 + math.sin(time * 2 + i) * 5
            self:drawWaterDrop(dropX, dropY, 12)
        end
        
        -- Draw ripple effect border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(3)
        local rippleOffset = math.sin(time * 2) * 2
        love.graphics.rectangle("line", boxX, boxY + rippleOffset, boxWidth, boxHeight, 15, 15)
        
        -- Draw question text with shadow
        love.graphics.setFont(questionFont)
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Calculate:", boxX + 2, boxY + 22, boxWidth, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Calculate:", boxX, boxY + 20, boxWidth, "center")
        
        -- Draw main question text
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(question, boxX + 20, boxY + 60, boxWidth - 40, "center")
        
        -- Draw answer box with wave effect
        local waveOffset = math.sin(time * 3) * 2
        love.graphics.setColor(0.000, 0.749, 1.000, 0.3)
        love.graphics.rectangle("fill", boxX + 100, boxY + 100 + waveOffset, boxWidth - 200, 30, 8, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Your Answer: " .. userAnswer, boxX + 100, boxY + 108 + waveOffset, boxWidth - 200, "center")

        
    end

    -- Helper function to draw a water drop
    function level2:drawWaterDrop(x, y, size)
        local points = {}
        for i = 0, 30 do
            local angle = (i / 30) * math.pi * 2
            local radius = size * (1 - 0.3 * math.sin(angle))
            if angle > math.pi then
                radius = radius * 0.8
            end
            table.insert(points, x + math.sin(angle) * radius)
            table.insert(points, y + math.cos(angle) * radius * 1.3)
        end
        love.graphics.polygon("fill", points)
    end
    function level2:drawCalculatorButton()
        love.graphics.setColor(0.2, 0.2, 0.8, 0.5)
        love.graphics.rectangle("fill", calculatorButton.x, calculatorButton.y, calculatorButton.width, calculatorButton.height, 5, 5)
    
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", calculatorButton.x, calculatorButton.y, calculatorButton.width, calculatorButton.height, 5, 5)
    
        love.graphics.setFont(menuButtonFont or defaultFont)
        love.graphics.printf(
            calculatorButton.text,
            calculatorButton.x,
            calculatorButton.y + (calculatorButton.height / 2) - ((menuButtonFont or defaultFont):getHeight() / 2),
            calculatorButton.width,
            "center"
        )
    end
    self:drawCalculatorButton()
    self:drawMenuButton()
    

    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)

    -- Display the volume equation
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0)
    
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
    love.graphics.setColor(1, 1, 1, 1)
    local waterDisplayY = tank.y + (tank.height * 0.6) * (1 - tank.waterLevel/tank.maxWater) + 20
    love.graphics.printf(
        string.format("%.1f cm", tank.waterLevel),
        tank.x,
        waterDisplayY,
        tank.width,
        "center"
    )
    

    -- Draw Character Two and dialogue
    self:drawDialogue()
    self:drawCharacters()
    
    
    -- Draw measuring tape
    if calculatorActive then
        calculator:draw()
    end

    -- Draw raindrops during raining phase
    if state == STATES.RAINING then
        self:drawRaindrops()
    end

    love.graphics.setColor(1, 1, 1)
    self:drawMeasuringTape()
    self:updateScale()
    love.graphics.pop()
end

-- Function to advance the dialogue sequence
function level2:advanceDialogue()
    currentDialogue = currentDialogue + 1
    print("Advancing Dialogue:", currentDialogue)

    if currentDialogue > #dialogue then
        if self.levelCompleted then
            -- Level is completed, switch to level3
            Gamestate.switch(level3)
        else
            state = STATES.MOVING
            character2.velocityX = 400 -- **Increased from 200 to 400**
            character2.velocityY = 600 -- **Increased from 300 to 600**
            print("Dialogue ended. Transitioning to MOVING state.")
        end
    else
        state = STATES.DIALOGUE
        print("Continuing Dialogue.")
    end
end


-- Function to handle text input
function level2:textinput(text)
    if state == STATES.QUESTION then
        if text:match("%d") or text == "." then
            userAnswer = userAnswer .. text
        end
    end
end

-- Function to handle key presses
-- Declare answerProcessed at the appropriate scope
local answerProcessed = false

function level2:keypressed(key)
    if key == "f" then love.graphics.toggleFullscreen() end

    if calculator:isActive() then
        calculator:keypressed(key)
        return
        -- Exit the function if calculator is active
    end
    if state == STATES.DIALOGUE then
        if key == "return" or key == "space" then
            if currentDialogue > #dialogue and tank.waterLevel >= tank.maxWater then
                -- Only switch to level3 when tank is full and dialogue is complete
                Gamestate.switch(level3)
                return
            else
                self:advanceDialogue()
            end
        end

    elseif state == STATES.QUESTION then
        if key == "return" and not answerProcessed then
            if userAnswer == "" then
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                print("User answer is empty.")
                userAnswer = ""
                answerProcessed = true
                state = STATES.FEEDBACK
                return
            end
            --print(math.pi * (tank.radius)^2 * currentWaterLevel)
            local numericAnswer = tonumber(userAnswer)
            if not numericAnswer then
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                userAnswer = ""
                print("User answer is not a number.")
                answerProcessed = true
                state = STATES.FEEDBACK
                return
            end
                
            local currentWaterLevel = tank.waterLevel
                
            if not tank.radius or not currentWaterLevel then
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                userAnswer = ""
                print("Tank radius or water level is invalid.")
                answerProcessed = true
                state = STATES.FEEDBACK
                return
            end
                
            local function roundToTwoDecimalPlaces(value)
                return math.floor(value * 100 + 0.5) / 100
            end
                
            local unroundedCorrectAnswer = math.pi * (tank.radius)^2 * currentWaterLevel
            correctAnswer = roundToTwoDecimalPlaces(unroundedCorrectAnswer)
            numericAnswer = roundToTwoDecimalPlaces(numericAnswer)
            
            print("Tank radius:", tank.radius)
            print("Tank water level:", currentWaterLevel)
            print("Unrounded correct answer:", unroundedCorrectAnswer)
            print("Correct answer (rounded):", correctAnswer)
            print("Numeric answer (user input):", numericAnswer)
                
            local percentageDiff
            if correctAnswer == 0 then
                if numericAnswer == 0 then
                    percentageDiff = 0
                else
                    percentageDiff = math.huge
                end
            else
                percentageDiff = math.abs(numericAnswer - correctAnswer) / correctAnswer * 100
            end

            print("Percentage difference:", percentageDiff)
            answerProcessed = true
                    
            if percentageDiff > 10 then
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
                print("Answer is incorrect.")
                -- Decrease water level when incorrect
                tank.waterLevel = math.max(0, currentWaterLevel - 5)
                userAnswer = ""
                state = STATES.FEEDBACK
                -- The update function will handle the transition back to QUESTION state
                return
            else
                feedbackState = "correct"
                feedbackTimer = feedbackDuration
                print("Answer is correct.")
                -- Increase water level when correct
                tank.waterLevel = math.min(currentWaterLevel + 10, tank.maxWater)
                userAnswer = ""
                state = STATES.FEEDBACK
                -- The update function will handle the transition back to QUESTION state
                return
            end
        elseif key == "backspace" then
            userAnswer = string.sub(userAnswer, 1, -2)
        end
        
    -- Check if tank is at max level after correct answer
    if feedbackState == "correct" and tank.waterLevel >= 50 then
        state = STATES.DIALOGUE
        dialogue = {
            {
                character = "assets/images/character2.png",
                text = "Good job! You did it! Continue to the next level to see how to use the water you collected."
            }
        }
        currentDialogue = 0 -- Reset to 0 so next advance goes to 1
        -- Enter keypress would now advance dialogue and transition to level3
        if feedbackState == "correct" and tank.waterLevel >= tank.maxWater then
            state = STATES.DIALOGUE
            dialogue = {
                {
                    character = "assets/images/character2.png",
                    text = "Good job! You did it! Continue to the next level to see how to use the water you collected."
                }
            }
            currentDialogue = 0 -- Reset to 0 so next advance goes to 1
            self.levelCompleted = true -- Indicate that level is completed
        
            -- Reset character position to be visible on screen
            character2.x = screenWidth - 700
            character2.y = screenHeight 
            character2.velocityX = 0
            character2.velocityY = 0
        elseif key == "backspace" then
            userAnswer = string.sub(userAnswer, 1, -2)
        end
        
        
        -- Reset character position to be visible on screen
        character2.x = screenWidth - 700
        character2.y = screenHeight 
        character2.velocityX = 0
        character2.velocityY = 0
        
    elseif key == "backspace" then
        userAnswer = string.sub(userAnswer, 1, -2)
    end
end

    if key == "escape" then
        Gamestate.switch(menu)
    end
    self:updateScale()
    love.window.setFullscreen(true, "desktop")
end


function level2:update(dt)
    -- Update time for smooth sway animation
    time = time + dt
    if state == STATES.FEEDBACK then
        feedbackTimer = feedbackTimer - dt
        if feedbackTimer <= 0 then
           
            else
                state = STATES.QUESTION
                answerProcessed = false
                -- Update correct answer for new water level
                correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel
            end
        end
    

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
           
            if currentDialogue < #dialogue then
            -- Reset character position if dialogue isn't finished
            character2.x = screenWidth / 2 + 250
            character2.y = screenHeight
            state = STATES.DIALOGUE
            print("Character Two reset - dialogue continuing")
            else
            state = STATES.CLOUDS -- Transition to CLOUDS state
            print("Character Two moved off-screen. Transitioning to CLOUDS state.")

            -- Initialize variables for CLOUDS state
            cloudSpawnTimer = 0
            rainingTimer = 0 
            initialWaterLevel = tank.waterLevel
            targetWaterLevel = math.min(tank.waterLevel + 10, tank.maxWater)
            end
        end

    elseif state == STATES.CLOUDS then
        -- Spawn clouds until desired number is reached
        if #clouds < desiredNumberOfClouds then
            cloudSpawnTimer = cloudSpawnTimer + dt
            if cloudSpawnTimer >= cloudSpawnInterval then
                cloudSpawnTimer = cloudSpawnTimer - cloudSpawnInterval
                self:spawnCloud()
            end
        end

        -- Update clouds
        local allCloudsStationary = true
        for i = #clouds, 1, -1 do
            local cloud = clouds[i]
            if cloud.state == 'entering' then
                -- Move cloud to the right
                cloud.x = cloud.x + cloud.speed * dt
                -- Check if cloud is fully on screen
                if cloud.x >= 0 then
                    cloud.state = 'stationary'
                    -- Adjust x to prevent overshoot
                    cloud.x = 0 
                else
                    allCloudsStationary = false
                end
            elseif cloud.state == 'stationary' then
                -- Clouds can remain stationary or drift slowly
                cloud.x = cloud.x + cloud.speed * dt * 0.05
            else
                allCloudsStationary = false
            end
        end

        -- Check if all clouds are stationary, then transition to RAINING state
        if allCloudsStationary and #clouds >= desiredNumberOfClouds then
            -- Transition to RAINING state
            state = STATES.RAINING
            print("Clouds have appeared. Transitioning to RAINING state.")
            rainingTimer = 0
        end

    elseif state == STATES.RAINING then
        rainingTimer = rainingTimer + dt

        if rainingTimer <= rainingDuration then
            -- Sky Darkening Phase
            local t = rainingTimer / rainingDuration
            backgroundColor = {
                initialBackgroundColor[1] + t * (targetBackgroundColor[1] - initialBackgroundColor[1]),
                initialBackgroundColor[2] + t * (targetBackgroundColor[2] - initialBackgroundColor[2]),
                initialBackgroundColor[3] + t * (targetBackgroundColor[3] - initialBackgroundColor[3])
            }
        else
            -- Raining Phase
            -- Play the rain sound if it's not already playing
            if rainSound and not rainSound:isPlaying() then
                love.audio.play(rainSound)
                print("Rain sound started.")
            end

            -- Update raindrops
            self:updateRaindrops(dt)

            -- Update water droplets in the tube
            for i = #waterDroplets, 1, -1 do
                local droplet = waterDroplets[i]
                if droplet.segment == 1 then
                    droplet.x = droplet.x + droplet.speed * dt
                    if droplet.x >= tubeSegments[1].endX then
                        droplet.x = tubeSegments[1].endX
                        droplet.segment = 2
                    end
                elseif droplet.segment == 2 then
                    droplet.y = droplet.y + droplet.speed * dt
                    if droplet.y >= tubeSegments[2].endY then
                        droplet.y = tubeSegments[2].endY
                        -- Remove the droplet
                        table.remove(waterDroplets, i)
                        -- Increase tank water level, cap at targetWaterLevel
                        if tank.waterLevel < targetWaterLevel then
                            tank.waterLevel = math.min(tank.waterLevel + 1, tank.maxWater)
                        end
                        -- Transition to QUESTION state if tank is full
                        if tank.waterLevel >= targetWaterLevel then
                            state = STATES.QUESTION
                            print("Tank filled. Transitioning to QUESTION state.")
                            -- Initialize background return timer
                            backgroundReturnTimer = 0

                            -- Update correctAnswer based on the current tank water level
                            correctAnswer = math.pi * (tank.radius)^2 * tank.waterLevel

                            -- Set clouds to start exiting
                            for _, cloud in ipairs(clouds) do
                                cloud.state = 'exiting'
                                cloud.speed = math.random(160, 320) -- Increased speed for exiting clouds
                            end
                        end
                    end
                end
            end

            -- Update clouds during raining phase
            for i = #clouds, 1, -1 do
                local cloud = clouds[i]
                if cloud.state == 'stationary' then
                    -- Clouds can drift slowly
                    cloud.x = cloud.x + cloud.speed * dt * 0.05
                elseif cloud.state == 'exiting' then
                    -- Move cloud to the right
                    cloud.x = cloud.x + cloud.speed * dt
                    if cloud.x > screenWidth then
                        table.remove(clouds, i)
                    end
                end
            end

            -- Initiate Fade-Out When Transitioning to QUESTION
            if state == STATES.QUESTION and not rainFadeOut and rainSound and rainSound:isPlaying() then
                rainFadeOut = true
                rainFadeTimer = 0
                print("Initiating rain sound fade-out.")
            end
        end

    elseif state == STATES.QUESTION then
        -- Handle Fade-Out of Rain Sound
        if rainFadeOut and rainSound and rainSound:isPlaying() then
            rainFadeTimer = rainFadeTimer + dt
            local newVolume = math.max(0, 0.5 * (1 - rainFadeTimer / rainFadeDuration))
            rainSound:setVolume(newVolume)
            
            if rainFadeTimer >= rainFadeDuration then
                love.audio.stop(rainSound)
                rainFadeOut = false
                print("Rain sound fade-out completed and stopped.")
                -- Reset volume for future use
                rainSound:setVolume(0.5)
            end
        end

        -- Update feedback timer and handle answer clearing
        
        -- Sky Brightening Phase
        if backgroundReturnTimer < backgroundReturnDuration then
            backgroundReturnTimer = backgroundReturnTimer + dt
            local t = math.min(backgroundReturnTimer / backgroundReturnDuration, 1)
            backgroundColor = {
                targetBackgroundColor[1] + t * (initialBackgroundColor[1] - targetBackgroundColor[1]),
                targetBackgroundColor[2] + t * (initialBackgroundColor[2] - targetBackgroundColor[2]),
                targetBackgroundColor[3] + t * (initialBackgroundColor[3] - targetBackgroundColor[3])
            }
        end

        -- Update clouds during exiting phase
        for i = #clouds, 1, -1 do
            local cloud = clouds[i]
            if cloud.state == 'exiting' then
                cloud.x = cloud.x + cloud.speed * dt
                if cloud.x > screenWidth then
                    table.remove(clouds, i)
                end
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
end

function level2:mousepressed(x, y, button, istouch, presses)
    -- Handle calculator interactions first
    if calculatorActive and calculator:isActive() then
        calculator:mousepressed(x, y, button, istouch, presses)
        return
    end
    x, y = self:toWorldCoords(x, y)

    -- Handle left mouse button clicks
    if button == 1 then
        -- Check menu button
        if isMouseOver(menuButton, x, y) then
            Gamestate.switch(menu)
            print("Returning to the main menu.")
            return
        end

        -- Check calculator button
        if isMouseOver(calculatorButton, x, y) then
            calculator:activate()
            calculatorActive = true
            print("Calculator activated.")
            return
        end
        if button == 1 then
            if x >= menuButton.x and x <= menuButton.x + menuButton.width and
               y >= menuButton.y and y <= menuButton.y + menuButton.height then
                Gamestate.switch(menu)
                return
            end
        end
    

        -- Check dialogue state
        if state == STATES.DIALOGUE then
            self:advanceDialogue()
            return
        end

        -- Check measuring tape interaction
        if state == STATES.QUESTION then
            if x >= tank.x and x <= tank.x + tank.width and
               y >= tank.y + tank.height - 20 and y <= tank.y + tank.height + 20 then
                measureTape.active = true
                measureTape.startX = x
                measureTape.startY = tank.y + tank.height
                measureTape.endX = x
                measureTape.endY = y
            end
        end
    end
end


-- Function to draw the water inside the tank
function level2:drawTankWater()
    if not tank.image then return end

    -- Update wave time
    waterWaveTime = waterWaveTime + love.timer.getDelta() * waterWaveSpeed

    -- Calculate water level fraction (inverted since we're measuring from top)
    local waterLevelFraction = tank.waterLevel / tank.maxWater

    -- Tank dimensions for water placement
    local tankWaterStartY = tank.y + (tank.height * 0.6) -- Start water 20% from top of tank
    local tankWaterHeight = tank.height * 0.9 -- Use 60% of tank height for water area
    local tankWaterBottom = tankWaterStartY + tankWaterHeight -- Bottom boundary for water
    -- Calculate the actual water level position
    -- This maps the water to the usable area of the tank
    local verticalOffset = tankWaterStartY + tankWaterHeight * (1 - waterLevelFraction)

    -- Create the water shape points
    local points = {}

    -- Left side of water
    local leftX = tank.x + (tank.width * 0.2) -- 20% from left edge
    local rightX = tank.x + (tank.width * 0.8) -- 80% from left edge

    -- Add points for water polygon
    -- Top left with wave
    local waveOffset1 = math.sin(waterWaveTime) * waterWaveHeight
    table.insert(points, leftX)
    table.insert(points, verticalOffset + waveOffset1)

    -- Top right with wave (slightly offset phase)
    local waveOffset2 = math.sin(waterWaveTime + math.pi/4) * waterWaveHeight
    table.insert(points, rightX)
    table.insert(points, verticalOffset + waveOffset2)

    -- Bottom right
    table.insert(points, rightX)
    table.insert(points, tankWaterBottom)

    -- Bottom left
    table.insert(points, leftX)
    table.insert(points, tankWaterBottom)

    -- Draw the water with semi-transparency
    love.graphics.setColor(waterColor)
    if #points >= 6 then  -- Need at least 3 points to make a polygon
        love.graphics.polygon("fill", points)
    end
    love.graphics.setColor(waterColor[1], waterColor[2], waterColor[3], 0.3)
    love.graphics.setLineWidth(1)
    if #points >= 6 then
        love.graphics.polygon("line", points)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    
end


-- Variables for measuring tape interaction
local measureTape = {
    active = false,
    startX = 0,
    startY = 0,
    endX = 0,
    endY = 0,
    width = 20,
    color = {0.9, 0.9, 0.2, 0.8},
    markings = 10  -- Number of measurement markings
}

-- Function to handle measuring tape interaction

-- Add this to the draw function after drawing the tank
function level2:drawMeasuringTape()
    if measureTape.active then
        -- Create metallic gradient effect
        local gradientSteps = 10
        local baseColor = {0.85, 0.85, 0.75}
        local width = measureTape.width
        local height = measureTape.startY - measureTape.endY
        
        -- Draw gradient segments
        for i = 0, gradientSteps do
            local t = i / gradientSteps
            local brightness = 0.85 + math.sin(t * math.pi) * 0.15
            love.graphics.setColor(
                baseColor[1] * brightness,
                baseColor[2] * brightness,
                baseColor[3] * brightness,
                0.9
            )
            love.graphics.rectangle("fill",
                measureTape.startX - width/2,
                measureTape.endY + height * (i/gradientSteps),
                width,
                height/gradientSteps + 1
            )
        end
        
        -- Add metallic shine effect
        love.graphics.setColor(1, 1, 0.9, 0.3)
        love.graphics.rectangle("fill",
            measureTape.startX - width/2 + 2,
            measureTape.endY,
            width/4,
            height
        )

        -- Draw measurement markings
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        local spacing = height / measureTape.markings
        local smallFont = love.graphics.newFont(8)
        love.graphics.setFont(smallFont)
        
        for i = 0, measureTape.markings do
            local y = measureTape.endY + (i * spacing)
            
            -- Draw hash marks
            if i % 5 == 0 then
                -- Major marks with values matching tank's water level scale
                love.graphics.setLineWidth(2)
                local measureValue = (tank.maxWater * (measureTape.markings - i) / measureTape.markings)
                love.graphics.line(
                    measureTape.startX - width/2 - 3,
                    y,
                    measureTape.startX - width/2 + width/3,
                    y
                )
            else
                -- Minor marks
                love.graphics.setLineWidth(1)
                love.graphics.line(
                    measureTape.startX - width/2 - 1,
                    y,
                    measureTape.startX - width/2 + width/4,
                    y
                )
            end

            if i % 5 == 0 then
                local measureValue = (measureTape.markings - i) / measureTape.markings * 100
                love.graphics.print(
                    string.format("%d", measureValue),
                    measureTape.startX - width/2 + width/3 + 2,
                    y - 4,
                    0,
                    0.8,
                    0.8
                )
            end
        end
    end
    
    -- Always display the water level over the tank
    love.graphics.setColor(1, 1, 1, 0.9)
    local waterFont = love.graphics.newFont(16)
    love.graphics.setFont(waterFont)
    
    -- Calculate position over the water
    
    
    -- Reset color and line width
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Helper function to check if mouse is over a button
function isMouseOver(button, x, y)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Draw menu button
function level2:drawMenuButton()
    love.graphics.setColor(0.2, 0.2, 0.8, 0.5)
    love.graphics.rectangle("fill", menuButton.x, menuButton.y, menuButton.width, menuButton.height, 5, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", menuButton.x, menuButton.y, menuButton.width, menuButton.height, 5, 5)

    love.graphics.setFont(menuButtonFont or defaultFont)
    love.graphics.printf(
        menuButton.text,
        menuButton.x,
        menuButton.y + (menuButton.height / 2) - ((menuButtonFont or defaultFont):getHeight() / 2),
        menuButton.width,
        "center"
    )
end
return level2
