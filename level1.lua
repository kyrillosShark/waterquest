local level1 = {}
local calculator = require "calculator"
local Gamestate = require "gamestate"
local menu = require "menu"
-- Assuming your menu state is in menu.lua

local calculatorActive = false

-- Define possible game states
local STATES = {
    DIALOGUE = "dialogue",
    MEASURING = "measuring",
    MOVING = "moving",
    CLOUDS = "clouds",
    RAINING = "raining",
    QUESTION = "question",
    GAMEPLAY = "gameplay",
    DISPLAY_MEASUREMENTS = "display_measurements",
    FEEDBACK = "feedback",
    LEVEL_COMPLETE = "level_complete"  -- Added new state
}

-- Local variables for level-specific assets
local grasses = {}
local grassImages = {}
local correctCount = 0 -- Number of correct answers
local maxQuestions = 3 -- Number of questions needed to advance
local roofSegments = {}
-- Feedback assets
local checkImage
local xImage
local feedbackState = nil -- "correct" or "incorrect"
local menuButton = {
    x = 20,
    y = 560,
    width = 40,  -- Made smaller since we're using an arrow
    height = 40,
    text = "<"   -- Simple ASCII arrow character
}

-- School and Roof variables
local school = { x = 50, y = 100, width = 600, height = 2000 }
local roof = {
    baseLength = 400, -- Length of the base of the roof
    baseWidth = 150,  -- Width/depth of the building
    height = 140      -- Height of the roof (from base to peak)
}

-- Main building and roof offset
local mainBuilding = {}
local roofOffset = 40

-- Tank variables
local tank = {
    x = 0, -- We'll set this in level1:enter()
    y = 350,
    width = 300,
    height = 200,
    waterLevel = 10,
    maxWater = 200,
    image = nil -- Placeholder for the tank image
}

-- Derived tank properties
tank.radius = 2
tank.waterLevel = 5

-- Tube variables
local tubeSegments = {}
local waterDroplets = {}
local tubeDropletSpawnInterval = 0.02
local tubeDropletSpawnTimer = 0

-- Rain systems
local raindrops = {}
local raindropSpeedMin = 300
local raindropSpeedMax = 800
local raindropSpawnInterval = 0.02
local raindropSpawnTimer = 0
local maxRaindrops = 1000

-- Question and user input
local question = "Based on the measurements, calculate the area of the roof."
local correctAnswer = 0
local userAnswer = ""

-- Margin of error for floating-point comparison
local epsilon = 0.1

-- Time-based variable for smooth animation
local time = 0

-- Screen dimensions and scaling variables
local baseWidth = 800
local baseHeight = 600
local scale = 1
local offsetX = 0
local offsetY = 0

-- Store initial screen dimensions as base
function level1:updateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local scaleX = windowWidth / baseWidth
    local scaleY = windowHeight / baseHeight
    scale = math.min(scaleX, scaleY)
    
    -- Calculate offset to center the content
    offsetX = (windowWidth - (baseWidth * scale)) / 2
    offsetY = (windowHeight - (baseHeight * scale)) / 2
end

-- Function to convert screen coordinates to world coordinates
function level1:toWorldCoords(x, y)
    return (x - offsetX) / scale, (y - offsetY) / scale
end

-- Font settings
local defaultFont
local questionFont
local feedbackFont
local titleFont

-- Plane variables
local planeImage
local bannerImage
local planes = {}
local planeSpawnInterval = 10
local planeSpawnTimer = 0
local planeSpeed = 150

-- Dialogue sequence for characters
local dialogue = {}
local currentDialogue = 1
local state = STATES.DIALOGUE

-- Dialogue sequence identifier
local dialogueSequence = "initial"

-- Character definitions
local character2 = {
    image = nil,
    x = baseWidth / 2 + 270,
    y = baseHeight,
    scale = 0.5,
    velocityX = 0,
    velocityY = 0
}

-- Variables for the raining sequence
local initialBackgroundColor = {0.529, 0.808, 0.980}
local targetBackgroundColor = {0.5, 0.7, 0.7}
local backgroundColor = {0.529, 0.808, 0.980}

local rainingTimer = 0
local rainingDuration = 1
local initialWaterLevel
local targetWaterLevel

-- Define a unified water color
local waterColor = {0.000, 0.749, 1.000, 0.6}

-- Water mask points for animations
local waterMaskPoints = {}
local waterWaveTime = 2
local waterWaveSpeed = 5
local waterWaveHeight = 2

-- Variables for background color transition back to initial color
local backgroundReturnTimer = 0
local backgroundReturnDuration = 1

-- Measuring variables
local measuringActive = false
local measuringStartX, measuringStartY = 0, 0
local measuringEndX, measuringEndY = 0, 0
local measuringPath = nil
local measurements = {}
local maxMeasurements = 2

-- Predefined paths for measuring
local predefinedPaths = {}
local completedMeasurements = {}

-- Progress bar variables
local progressBar = {
    x = 50, -- Starting X position
    y = 20, -- Starting Y position (from the top)
    width = baseWidth - 100, -- Width of the progress bar
    height = 20, -- Height of the progress bar
    borderColor = {0, 0, 0, 1}, -- Black border
    backgroundColor = {0.7, 0.7, 0.7, 1}, -- Grey background
    fillColor = {0, 0.5, 1, 1}, -- Blue fill
    borderThickness = 2, -- Thickness of the border
}
local calculatorButton = {
    x = 90,
    y = 850,
    width = 60,
    height = 40,
    text = "CALC"
}

-- Optional: Initialize a displayedProgress variable for smooth animation
local displayedProgress = 0

-- Helper function to draw a water drop
function level1:drawWaterDrop(x, y, size)
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

-- Assuming you have a next level defined
local nextLevel = require("level2") 
function level1:resize(w, h)
    self:updateScale()
end
-- Function called when entering Level 1
function level1:enter()
    print("Entering Level 1")

    -- Load fonts and other assets with error handling
    local success, err = pcall(function()
        defaultFont = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 18)
        questionFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 22)
        feedbackFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 28)
        titleFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 36)
        menuButtonFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 18)
        raindropImage = love.graphics.newImage("assets/images/raindrop.png")
        -- Load grass images
        grassImages[1] = love.graphics.newImage("assets/images/grass.png")
        wallTexture = love.graphics.newImage("assets/images/wall_texture.jpeg")
        columnTexture = love.graphics.newImage("assets/images/wall_texture.jpeg")
        --roofTexture = love.graphics.newImage("assets/images/roof_texture.jpeg") -- Load roof texture
        
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
        calculator:init()
        calculator:setPosition(baseWidth - 400, 100)  -- Set position but don't activate
        calculator:deactivate()  -- Ensure calculator starts deactivated

        -- Load tank image
        tank.image = love.graphics.newImage("assets/images/tank.png")
        if not tank.image then
            print("Failed to load tank image.")
        else
            print("Tank image loaded successfully.")
        end

        -- Load the rain sound
        rainSound = love.audio.newSource("assets/sounds/rain.mp3", "stream")
        rainSound:setLooping(true)
        rainSound:setVolume(0.5)
        kenyanFlagImage = love.graphics.newImage("assets/images/flag_of_kenya.png")
        self:updateScale()

    end)

    if not success then
        print("Error loading assets:", err)
        return
    else
        print("All assets loaded successfully.")
    end

    -- Create multiple grass instances
    for i = 1, 8 do
        table.insert(grasses, {
            x = i * 100,
            y = baseHeight + 40,
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
            text = "Welcome to Clean Water Quest! We are on a mission to save water."
        },
        {
            character = "assets/images/character2.png",
            text = "Today, we need your help to calculate the area of the roof."
        },
        {
            character = "assets/images/character2.png",
            text = "First, let's measure the sides of the roof."
        },
    }

    -- Initialize timers and state
    planeSpawnTimer = 0
    state = STATES.DIALOGUE
    currentDialogue = 1
    userAnswer = ""
    feedbackState = nil
    dialogueSequence = "initial"

    -- Initialize background color
    backgroundColor = {initialBackgroundColor[1], initialBackgroundColor[2], initialBackgroundColor[3]}

    -- Initialize correct count
    correctCount = 0 -- Reset correctCount on entering the level

    -- Initialize scale based on the current window size
    self:updateScale()

    -- Setup initial roof and building
    self:setupRoofAndBuilding()
    love.window.setFullscreen(true, "desktop")
end

-- Handle window resizing
function level1:resize(w, h)
    self:updateScale()
end

local function isMouseOver(button, mx, my)
    return mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height
end

-- Function to setup roof and building dimensions
function level1:setupRoofAndBuilding()
    -- Generate a random scaling factor for this problem (between 0.8 and 1.5)
    local scalingFactor = love.math.random() * 0.7 + 0.8  -- This gives us random values between 0.8 and 1.5
    
    -- Fixed visual dimensions (these control how it looks)
    local visualWidth = 600
    local visualBaseLength = 400
    local visualBaseWidth = 150
    local visualHeight = 140

    -- Apply scaling factor to get random actual values while keeping visual dimensions the same
    roof.width = visualWidth * scalingFactor  -- Random actual width
    roof.baseLength = visualBaseLength * scalingFactor -- Random actual baseLength
    roof.baseWidth = visualBaseWidth * scalingFactor -- Random actual baseWidth
    roof.height = visualHeight * scalingFactor -- Random actual height
    
    -- Store the visual dimensions separately (these control how it's drawn)
    roof.visualWidth = visualWidth
    roof.visualBaseLength = visualBaseLength
    roof.visualBaseWidth = visualBaseWidth
    roof.visualHeight = visualHeight

    -- Define dimensions for the main building (using visual dimensions for drawing)
    mainBuilding = {
        x = school.x + 20,
        y = school.y + visualHeight,
        width = visualWidth,
        height = 300
    }

    -- Update tank position to be directly under the water tube
    tank.x = mainBuilding.x + mainBuilding.width - tank.width / 2
    tank.y = mainBuilding.y + mainBuilding.height + 40

    -- Define tube segments based on the school and tank positions
    tubeSegments = {
        {
            startX = mainBuilding.x,
            startY = mainBuilding.y + 10,
            endX = mainBuilding.x + mainBuilding.width,
            endY = mainBuilding.y
        },
        {
            startX = mainBuilding.x + mainBuilding.width,
            startY = mainBuilding.y,
            endX = mainBuilding.x + mainBuilding.width,
            endY = tank.y
        }
    }

    -- Adjust Character Two's velocity for faster movement
    character2.velocityX = 400
    character2.velocityY = 600

    -- Define roof parameters for drawing (using visual dimensions)
    local roofX = mainBuilding.x
    local roofY = mainBuilding.y
    local roofWidth = mainBuilding.width
    local roofHeight = visualHeight

    -- Define predefined measuring paths (using actual scaled values for measurements)
    predefinedPaths = {
        {
            name = "Left Side",
            startX = roofX + roofOffset,
            startY = roofY - roofHeight,
            endX = roofX,
            endY = roofY,
            actualLength = roof.height  -- This will use the scaled value
        },
        {
            name = "Top Side",
            startX = roofX + roofOffset,
            startY = roofY - roofHeight,
            endX = roofX + roofWidth + roofOffset,
            endY = roofY - roofHeight,
            actualLength = roof.width  -- This will use the scaled value
        }
    }

    -- Store the scaling factor for calculations
    roof.scalingFactor = scalingFactor

    -- Clear any previous measurements
    measurements = {}

    -- Reset measuring variables
    measuringActive = false
    measuringStartX, measuringStartY = 0, 0
    measuringEndX, measuringEndY = 0, 0
    measuringPath = nil
end

-- Function to calculate distance from a point to a line segment
function level1:pointToSegmentDistance(px, py, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    if dx == 0 and dy == 0 then
        return math.sqrt((px - x1)^2 + (py - y1)^2)
    end

    local t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = math.max(0, math.min(1, t))
    local closestX = x1 + t * dx
    local closestY = y1 + t * dy
    return math.sqrt((px - closestX)^2 + (py - closestY)^2)
end

function level1:drawSchool()
    -- Existing parameters
    local numWaves = 40
    local amplitude = 3
    local numPoints = 200
    local pointsPerWave = numPoints / numWaves
    local shadowOffsetX = 30
    local shadowOffsetY = 50

    -- Draw the main building wall with texture
    self:drawTexturedPolygon(wallTexture, "fill",
        mainBuilding.x, mainBuilding.y,
        mainBuilding.x + mainBuilding.width, mainBuilding.y,
        mainBuilding.x + mainBuilding.width, mainBuilding.y + mainBuilding.height + 100,
        mainBuilding.x, mainBuilding.y + mainBuilding.height + 100
    )

    -- Parameters for the wavy roof
    local roofWidth = roof.visualWidth
    local roofHeight = roof.visualHeight
    local roofX = mainBuilding.x
    local roofY = mainBuilding.y

    -- Initialize an empty table to store roof points
    local roofPoints = {}

    -- Add the bottom-left point of the roof
    table.insert(roofPoints, roofX)
    table.insert(roofPoints, roofY)

    -- Generate points along the bottom edge with sine wave variations
    for i = 1, numPoints do
        local t = i / numPoints
        local x = roofX + t * roofWidth
        local sineValue = math.sin(t * numWaves * math.pi * 2)
        local y = roofY + sineValue * amplitude

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
    self:drawTexturedPolygon(roofTexture, "fill", unpack(roofPoints))
    love.graphics.setColor(0.0, 0.0, 0.0, 0.7)
    self:drawTexturedPolygon(roofTexture, "fill", unpack(roofPoints))

    -- Optional: Draw the outline of the roof for better visibility
    love.graphics.setColor(0.0, 0.2, 0.8, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", unpack(roofPoints))
    love.graphics.setLineWidth(1)

    -- Draw shadows from roof to wall
    local shadowPoints = {
        roofX, roofY,
        roofX + roofWidth, roofY,
        roofX + roofWidth + shadowOffsetX, roofY + shadowOffsetY,
        roofX + shadowOffsetX, roofY + shadowOffsetY
    }

    -- Draw the shadow polygon
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.polygon("fill", unpack(shadowPoints))

    love.graphics.setColor(1, 1, 1)

    -- Draw Left Side Wall with texture
    love.graphics.setColor(1, 1, 1)
    self:drawTexturedPolygon(wallTexture, "fill",
        roofX, roofY + 5,
        roofX + roofOffset, roofY + 5,
        roofX + roofOffset, roofY + mainBuilding.height,
        roofX, roofY + mainBuilding.height
    )

    -- Draw flagpole and flag
    love.graphics.setColor(0.1, 0.1, 0.1)
    local flagpoleX = roofX + roofWidth + roofOffset + 30
    love.graphics.rectangle("fill", flagpoleX, roofY - roofHeight - 30, 3, mainBuilding.height + roofHeight + 60)

    -- Initialize wave parameters for flag animation
    if not level1.flagWaveTime then
        level1.flagWaveTime = 0
        level1.flagWaveSpeed = 4
        level1.flagWaveAmplitude = 3
        level1.flagPoints = 8
    end

    level1.flagWaveTime = level1.flagWaveTime + love.timer.getDelta() * level1.flagWaveSpeed

    -- Create animated flag points
    local flagWidth = 77
    local flagHeight = 80
    local points = {}

    -- Generate wavy points for flag
    for i = 0, level1.flagPoints do
        local xPercent = i / level1.flagPoints
        local xPos = flagpoleX + 3 + (xPercent * flagWidth)
        local waveOffset = math.sin(level1.flagWaveTime + (xPercent * 3)) * level1.flagWaveAmplitude

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

        local wavePhase = math.sin(level1.flagWaveTime + (i / #points * 3))
        local shadowIntensity = math.abs(wavePhase) * 0.3

        local mesh = love.graphics.newMesh({
            {x1, y1, (i - 1) / (level1.flagPoints - 1), 0},
            {x3, y3, i / (level1.flagPoints - 1), 0},
            {x4, y4, i / (level1.flagPoints - 1), 1},
            {x2, y2, (i - 1) / (level1.flagPoints - 1), 1}
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

function level1:drawTexturedPolygon(texture, mode, ...)
    local vertices = {...}

    -- Create mesh with the vertices
    local mesh = love.graphics.newMesh({
        {"VertexPosition", "float", 2},
        {"VertexTexCoord", "float", 2}
    }, #vertices / 2, "fan", "static")

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
        mesh:setVertex((i - 1) / 2 + 1, {
            x, y,
            u, v
        })
    end

    mesh:setTexture(texture)
    love.graphics.draw(mesh)
    mesh:release()
end

-- Function called when leaving Level 1
function level1:leave()
    print("Leaving Level 1")
    -- Clean up resources if necessary
    if rainSound then
        love.audio.stop(rainSound)
        rainSound:release()
        rainSound = nil
        print("Rain sound stopped and released.")
    end
end

-- Function to update game logic each frame
function level1:update(dt)
    -- Update time for smooth sway animation
    time = time + dt
    if calculatorActive then
        if calculator then
            calculator:update(dt)
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
        if character2.image and (character2.x > baseWidth + character2.image:getWidth() or
           character2.y > baseHeight + character2.image:getHeight()) then
            state = STATES.CLOUDS -- Transition to CLOUDS state
            print("Character Two moved off-screen. Transitioning to CLOUDS state.")

            -- Initialize variables for CLOUDS state
            cloudSpawnTimer = 0
            rainingTimer = 0
            initialWaterLevel = tank.waterLevel
            targetWaterLevel = math.min(tank.waterLevel + 50, tank.maxWater)
        end

    elseif state == STATES.MEASURING then
        if measuringActive and measuringPath then
            local mouseX, mouseY = love.mouse.getPosition()
            mouseX, mouseY = self:toWorldCoords(mouseX, mouseY)
            -- Project mouse position onto the path
            local startX = measuringStartX
            local startY = measuringStartY
            local endX = measuringPath.endX
            local endY = measuringPath.endY

            -- If measuring in reverse direction, swap start and end
            if measuringDirection == -1 then
                startX, endX = endX, startX
                startY, endY = endY, startY
            end

            local APx = mouseX - startX
            local APy = mouseY - startY
            local ABx = endX - startX
            local ABy = endY - startY

            local abSquared = ABx * ABx + ABy * ABy
            local apDotAb = APx * ABx + APy * ABy

            local t = apDotAb / abSquared
            t = math.max(0, math.min(1, t)) -- Clamp t to [0,1]

            measuringEndX = startX + t * ABx
            measuringEndY = startY + t * ABy
        end

    elseif state == STATES.DISPLAY_MEASUREMENTS then
        -- Handle any updates needed during DISPLAY_MEASUREMENTS state
    elseif state == STATES.QUESTION then
        -- No feedbackTimer handling here
    elseif state == STATES.FEEDBACK then
        -- Wait for user to proceed
    end

    -- Update planes
    planeSpawnTimer = planeSpawnTimer + dt
    if planeSpawnTimer >= planeSpawnInterval then
        planeSpawnTimer = planeSpawnTimer - planeSpawnInterval
        --self:spawnPlane() -- Commented out as planes are optional here
    end

    for i = #planes, 1, -1 do
        local plane = planes[i]
        plane.x = plane.x + plane.speed * dt

        if plane.x > baseWidth + planeImage:getWidth() then
            table.remove(planes, i)
        end
    end
end

-- Function to draw dialogue on the screen
function level1:drawDialogue()
    if (state == STATES.DIALOGUE or state == STATES.DISPLAY_MEASUREMENTS) and dialogue[currentDialogue] then
        local dialogWidth = 400
        local dialogHeight = 100

        -- Calculate position at the bottom of the screen
        local dialogX = (baseWidth - dialogWidth) / 2 - 10
        local dialogY = baseHeight - dialogHeight - 50

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
    elseif state == STATES.LEVEL_COMPLETE then
        -- Draw the final dialogue box
        local dialogWidth = 500
        local dialogHeight = 150

        -- Position at the center of the screen
        local dialogX = (baseWidth - dialogWidth) / 2 
        local dialogY = (baseHeight - dialogHeight) / 2

        love.graphics.setFont(titleFont)
        love.graphics.setColor(0, 0, 0, 0.8)

        love.graphics.rectangle(
            "fill",
            dialogX,
            dialogY,
            dialogWidth,
            dialogHeight,
            15, 15
        )

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "Congratulations!\nYou've completed Level 1.",
            dialogX + 20,
            dialogY + 30,
            dialogWidth - 40,
            "center"
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
            character2.x - 530,
            character2.y,
            0,
            character2.scale,
            character2.scale,
            character2.image:getWidth() / 2,
            character2.image:getHeight()
        )
    end
end

-- Function to draw grass
function level1:drawGrass()
    love.graphics.setColor(1, 1, 1)
    for _, grass in ipairs(grasses) do
        local swayOffset = math.sin(time * grass.swaySpeed + grass.swayOffset) * grass.swayAmplitude
        love.graphics.draw(grass.image, grass.x + swayOffset, grass.y, 0, 0.5, 0.5, grass.image:getWidth() / 2, grass.image:getHeight())
    end
end

-- Function to advance the dialogue sequence
function level1:advanceDialogue()
    currentDialogue = currentDialogue + 1
    print("Advancing Dialogue:", currentDialogue)

    if currentDialogue > #dialogue then
        if dialogueSequence == "initial" then
            -- Start character exit animation
            character2.velocityX = 400
            character2.velocityY = -600
            state = STATES.MEASURING
            print("Dialogue ended. Character exiting. Transitioning to MEASURING state.")
        elseif dialogueSequence == "post_measurement" then
            -- Proceed to QUESTION state
            state = STATES.QUESTION
            self:calculateCorrectAnswer()
            -- Remove character from screen or have them exit
            character2.velocityX = 400
            character2.velocityY = -600
            dialogueSequence = "finished"
        elseif dialogueSequence == "final" then
            -- Proceed to LEVEL_COMPLETE state
            state = STATES.LEVEL_COMPLETE
            print("Final dialogue over. Transitioning to LEVEL_COMPLETE state.")
        end
    else
        state = STATES.DIALOGUE
        print("Continuing Dialogue.")
    end
end

-- Function to handle key presses
function level1:keypressed(key)
    if calculator:isActive() then
        calculator:keypressed(key)
        -- Exit the function if calculator is active
    end

    if state == STATES.DIALOGUE then
        if key == "return" then
            self:advanceDialogue()
        end
    elseif state == STATES.DISPLAY_MEASUREMENTS then
        if key == "return" then
            self:advanceDialogue()
        end
    elseif state == STATES.QUESTION then
        if key == "return" then
            self:checkAnswer()
        elseif key == "backspace" then
            userAnswer = string.sub(userAnswer, 1, -2)
        end
    elseif state == STATES.FEEDBACK then
        if key == "return" then
            if feedbackState == "correct" then
                if correctCount >= maxQuestions then
                    -- Set up final dialogue before moving to next level
                    dialogue = {
                        {
                            character = "assets/images/character2.png",
                            text = "Now that we've measured the roof, let's go measure the water. Remember that the volume is L x W x H."
                        },
                    }
                    currentDialogue = 1
                    dialogueSequence = "final"
                    state = STATES.DIALOGUE
                    print("Starting final dialogue before moving to next level.")
                else
                    -- Prepare for the next question
                    self:setupRoofAndBuilding()
                    state = STATES.MEASURING
                    userAnswer = ""
                    feedbackState = nil
                    -- Reset dialogue for measuring
                    dialogue = {
                        {
                            character = "assets/images/character2.png",
                            text = "Great job! Let's try another one."
                        },
                        {
                            character = "assets/images/character2.png",
                            text = "Measure the sides of the new roof."
                        },
                    }
                    currentDialogue = 1
                    dialogueSequence = "initial"
                    character2.x = baseWidth / 2 + 250
                    character2.y = baseHeight
                    character2.velocityX = 0
                    character2.velocityY = 0
                    state = STATES.DIALOGUE
                end
            else
                -- Reset for incorrect answer
                self:setupRoofAndBuilding()
                measurements = {} -- Clear previous measurements
                userAnswer = ""
                feedbackState = nil
                -- Set dialogue for retry
                dialogue = {
                    {
                        character = "assets/images/character2.png",
                        text = "Not quite right. Let's try measuring the roof again."
                    },
                    {
                        character = "assets/images/character2.png",
                        text = "Make sure to measure carefully!"
                    },
                }
                currentDialogue = 1
                dialogueSequence = "initial"
                character2.x = baseWidth / 2 + 250
                character2.y = baseHeight
                character2.velocityX = 0
                character2.velocityY = 0
                state = STATES.DIALOGUE
            end
        end
    elseif state == STATES.LEVEL_COMPLETE then
        if key == "return" or key == "space" then
            -- Transition to the next level
            Gamestate.switch(nextLevel)
            print("Transitioning to the next level.")
        end
    elseif key == "escape" then
        -- Add a fade-out transition
        local function onComplete()
            Gamestate.switch(menu)
        end
        
        -- Create a fade transition
        local transition = {
            alpha = 0,
            duration = 0.5,
            timer = 0,
            update = function(self, dt)
                self.timer = self.timer + dt
                self.alpha = math.min(1, self.timer / self.duration)
                if self.timer >= self.duration then
                    onComplete()
                end
            end,
            draw = function(self)
                love.graphics.setColor(0, 0, 0, self.alpha)
                love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)
            end
        }
        
        -- Replace the current state with the transition
        state = "transitioning"
        self.transition = transition
    end

    if key == "escape" then
        Gamestate.switch(menu)
    end
end

-- Function to handle text input
function level1:textinput(text)
    if state == STATES.QUESTION then
        if text:match("[0-9%.]") then
            userAnswer = userAnswer .. text
        end
    end
end

-- Function to handle mouse presses
function level1:mousepressed(x, y, button, istouch, presses)
    if calculatorActive then
        if calculator:isActive() then
            calculator:mousepressed(x, y, button, istouch, presses)
            return
        end
    end
    if button == 1 then -- Left mouse button
        if isMouseOver(menuButton, x, y) then
            Gamestate.switch(menu)  -- Switch to the main menu state
            print("Returning to the main menu.")
            return -- Exit the function to prevent other interactions
        elseif isMouseOver(calculatorButton, x, y) then
            -- Switch to the calculator state
            calculator:activate() 
            calculatorActive = true     -- Activate the calculator
            print("Calculator activated.")
            return
        end
    end

    x, y = self:toWorldCoords(x, y)

    if state == STATES.DIALOGUE and button == 1 then
        self:advanceDialogue()
    elseif state == STATES.MEASURING and button == 1 then
        local clickX, clickY = x, y
        local threshold = 20

        -- Check if we already measured this path
        local function isPathMeasured(path)
            for _, measurement in ipairs(measurements) do
                if measurement.name == path.name then
                    return true
                end
            end
            return false
        end

        for _, path in ipairs(predefinedPaths) do
            -- Skip if we already measured this path
            if isPathMeasured(path) then
                goto continue
            end

            -- Check if click is near the path (start or end)
            local distanceToStart = math.sqrt((clickX - path.startX)^2 + (clickY - path.startY)^2)
            local distanceToEnd = math.sqrt((clickX - path.endX)^2 + (clickY - path.endY)^2)
            local distanceToSegment = self:pointToSegmentDistance(clickX, clickY, path.startX, path.startY, path.endX, path.endY)

            if distanceToStart <= threshold or distanceToEnd <= threshold or distanceToSegment <= threshold then
                measuringActive = true
                measuringPath = path
                measuringStartX = path.startX
                measuringStartY = path.startY
                measuringEndX = path.startX
                measuringEndY = path.startY
                measuringDirection = 1
                break
            end
            ::continue::
        end
    elseif state == STATES.LEVEL_COMPLETE and button == 1 then
        -- Transition to the next level on mouse click
        Gamestate.switch(nextLevel)
        print("Transitioning to the next level.")
    end
end

-- Function to handle mouse releases
function level1:mousereleased(x, y, button, istouch, presses)
    x, y = self:toWorldCoords(x, y)
    if state == STATES.MEASURING and button == 1 then
        if measuringActive and measuringPath then
            measuringActive = false
            -- Set end point to the path's end point (considering direction)
            if measuringDirection == 1 then
                measuringEndX = measuringPath.endX
                measuringEndY = measuringPath.endY
            else
                measuringEndX = measuringPath.startX
                measuringEndY = measuringPath.startY
            end

            -- Store the measurement including the measuring tape visualization data
            table.insert(measurements, {
                name = measuringPath.name,
                startX = measuringStartX,
                startY = measuringStartY,
                endX = measuringEndX,
                endY = measuringEndY,
                length = measuringPath.actualLength,  -- Use the actualLength
                showTape = true
            })

            measuringPath = nil
            measuringDirection = nil

            -- Check if measurements are complete
            if #measurements >= maxMeasurements then
                -- Append new dialogue
                table.insert(dialogue, {
                    character = "assets/images/character2.png",
                    text = "Now that you have measured the roof, let's calculate the area. Remember that the area is L x W."
                })
                currentDialogue = #dialogue
                state = STATES.DIALOGUE
                dialogueSequence = "post_measurement"
                -- Bring the character back to the screen
                character2.x = baseWidth / 2 + 250
                character2.y = baseHeight
                character2.velocityX = 0
                character2.velocityY = 0
            end
        end
    end
end

-- Function to calculate the correct answer based on measurements
function level1:calculateCorrectAnswer()
    -- Example calculation using scaled values
    local leftSide = roof.height
    local topSide = roof.width
    -- Your specific calculation here using the scaled values
    correctAnswer = leftSide * topSide 
    -- Round to 1 decimal place to avoid floating point issues
    correctAnswer = math.floor(correctAnswer * 10) / 10
end

-- Function to check the user's answer
function level1:checkAnswer()
    if userAnswer == "" then
        feedbackState = "incorrect"
        state = STATES.FEEDBACK
        return
    end

    local numericAnswer = tonumber(userAnswer)
    if not numericAnswer then
        feedbackState = "incorrect"
        state = STATES.FEEDBACK
        return
    end

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

    if percentageDiff <= 10 then
        feedbackState = "correct"
        correctCount = correctCount + 1 -- Increment correct answers
        print("Correct answer! correctCount is now:", correctCount)
    else
        feedbackState = "incorrect"
        print("Incorrect answer. correctCount remains:", correctCount)
    end

    if correctCount >= maxQuestions then
        -- Set up final dialogue before moving to next level
        dialogue = {
            {
                character = "assets/images/character2.png",
                text = "Now that we've measured the roof, let's go measure the water."
            },
        }
        currentDialogue = 1
        dialogueSequence = "final"
        state = STATES.DIALOGUE
        print("Starting final dialogue before moving to next level.")
    else
        state = STATES.FEEDBACK
        print("State changed to FEEDBACK, feedbackState:", feedbackState)
    end
end

function level1:drawTube()
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

function level1:drawColumns()
    local numColumns = 4
    local columnWidth = 30
    local columnHeight = mainBuilding.height * 1.8
    local columnSpacing = (mainBuilding.width - (numColumns * columnWidth)) / (numColumns + 1)
    
    for i = 1, numColumns do
        local columnX = mainBuilding.x + columnSpacing * i + (columnWidth * (i - 1))
        local columnY = mainBuilding.y + 5
        
        -- Column shadow
        love.graphics.setColor(0.6, 0.6, 0.6, 0.3)
        love.graphics.rectangle("fill", columnX + 5, columnY, columnWidth, columnHeight)
        
        -- Main column body
        love.graphics.setColor(1, 1, 1)
        self:drawTexturedPolygon(columnTexture, "fill",
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

function level1:drawProgressBar()
    -- Draw the border
    love.graphics.setColor(progressBar.borderColor)
    love.graphics.rectangle("line", progressBar.x, progressBar.y, progressBar.width, progressBar.height, 5, 5)
    
    -- Draw the background
    love.graphics.setColor(progressBar.backgroundColor)
    love.graphics.rectangle("fill", progressBar.x, progressBar.y, progressBar.width, progressBar.height, 5, 5)
    
    -- Calculate fill width based on progress
    local fillWidth = (correctCount / maxQuestions) * (progressBar.width - 4) -- Subtracting for border
    
    -- Draw the filled portion
    love.graphics.setColor(progressBar.fillColor)
    love.graphics.rectangle("fill", progressBar.x + 2, progressBar.y + 2, fillWidth, progressBar.height - 4, 3, 3)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw the progress text
    local progressText = string.format("Progress: %d / %d", correctCount, maxQuestions)
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 0, 0, 1) -- Black text shadow
    love.graphics.printf(progressText, progressBar.x + 2, progressBar.y + (progressBar.height / 2) - 10, progressBar.width, "center")
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.printf(progressText, progressBar.x, progressBar.y + (progressBar.height / 2) - 12, progressBar.width, "center")
end

function level1:drawStairs()
    -- Parameters for stairs
    local numSteps = 3                    -- Fixed number of steps
    local stepHeight = 30                 -- Height of each step
    local stepWidthMultiplier = 1.05       -- Controls the width difference between steps
    local baseStepWidth = mainBuilding.width  -- Width of the top step (matches building)

    -- Starting position of the stairs (smallest/top step aligns with building)
    local startX = mainBuilding.x
    local startY = mainBuilding.y + mainBuilding.height - 50   -- Adjust position closer to the bottom

    -- Draw each step from top to bottom
    for i = 1, numSteps do
        local currentStepWidth = baseStepWidth * (stepWidthMultiplier ^ (i - 1))
        local stepX = startX - (currentStepWidth - baseStepWidth) / 2
        local stepY = startY + (i - 1) * stepHeight
        
        -- Draw the step with texture
        love.graphics.setColor(1, 1, 1, 1)
        self:drawTexturedPolygon(wallTexture, "fill",
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

function level1:drawWindows()
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

-- Function to draw all game elements
function level1:draw()
    -- Clear the screen with the background color
    love.graphics.clear(0.529, 0.808, 0.980)

    -- Apply scaling and translation
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale)

    -- Draw the progress bar
    self:drawProgressBar()

    -- Draw other elements
    self:drawSchool()
    self:drawWindows()
    self:drawColumns()
    self:drawStairs()

    -- Use visual dimensions for roof
    local roofWidth = roof.visualWidth      -- Use visual width
    local roofHeight = roof.visualHeight    -- Use visual height
    local roofX = mainBuilding.x
    local roofY = mainBuilding.y

    love.graphics.setColor(0.8, 0.8, 0.8)
    self:drawTexturedPolygon(wallTexture, "fill",
        roofX + roofWidth + 3, roofY,                                   -- Top-left corner
        roofX + roofWidth + roofOffset, roofY - roofHeight,             -- Top-right corner
        roofX + roofWidth + roofOffset, mainBuilding.y + mainBuilding.height, -- Bottom-right corner
        roofX + roofWidth, mainBuilding.y + mainBuilding.height         -- Bottom-left corner
    )

    -- --- DRAW EXTENSION WALL ---
    local shiftRight = 40
    local fixedShapeHeight = 116           -- Fixed value for shape height
    local fixedVerticalAdjustment = 24     -- Fixed value for vertical adjustment

    love.graphics.setColor(0.8, 0.8, 0.8)  -- Slightly darker wall color for extension

    love.graphics.push()
        love.graphics.translate(
            mainBuilding.x + roof.visualWidth + roofOffset + shiftRight,  -- Fixed horizontal position
            mainBuilding.y - roof.visualHeight + fixedVerticalAdjustment + 150  -- Fixed vertical position
        )
        love.graphics.scale(-1, 1)  -- Mirror the extension wall if needed
        self:drawTexturedPolygon(wallTexture, "fill",
            0, 0,                                    -- Top-left corner (pivot point)
            roofOffset, -roof.visualHeight,          -- Top-right corner
            roofOffset, fixedShapeHeight,            -- Bottom-right corner
            0, fixedShapeHeight                      -- Bottom-left corner
        )
    love.graphics.pop()

    -- Draw the tube
    self:drawTube()

    -- Draw the tank image
    if tank.image then
        love.graphics.setColor(1, 1, 1)
        local scaleFactor = tank.width / tank.image:getWidth()
        love.graphics.draw(
            tank.image,
            tank.x + 150,
            tank.y + 50,
            0,
            scaleFactor,
            scaleFactor,
            tank.image:getWidth() / 2,
            tank.image:getHeight()
        )
    else
        print("Tank image not loaded.")
    end

    -- Draw grass
    self:drawGrass()

    -- Draw characters and dialogue
    self:drawDialogue()
    self:drawCharacters()

    -- Draw measuring tape if in appropriate state
    if state == STATES.MEASURING or state == STATES.DISPLAY_MEASUREMENTS or
       (state == STATES.DIALOGUE and dialogueSequence == "post_measurement") or state == STATES.QUESTION then

        love.graphics.setFont(defaultFont)
        love.graphics.setColor(0, 0, 0)
        if state == STATES.MEASURING then
            love.graphics.print("Measure the sides of the roof by dragging along the highlighted edges.", 50, 50)
        end

        -- Draw the predefined paths as dashed lines
        love.graphics.setColor(0, 0, 1)
        for _, path in ipairs(predefinedPaths) do
            self:drawDashedLine(path.startX, path.startY, path.endX, path.endY, 5, 5)
        end

        -- Draw markers at both ends of the measuring paths
        love.graphics.setColor(0, 1, 0)
        for _, path in ipairs(predefinedPaths) do
            love.graphics.circle("fill", path.startX, path.startY, 5)
            love.graphics.circle("fill", path.endX, path.endY, 5)
        end

        -- Draw the current measuring tape if active
        if measuringActive and measuringPath then
            self:drawMeasuringTape(
                measuringStartX,
                measuringStartY,
                measuringEndX,
                measuringEndY,
                measuringPath.actualLength  -- Pass the actualLength here
            )
        end

        -- Draw any completed measurements with their tapes and labels
        if #measurements > 0 then
            for _, measurement in ipairs(measurements) do
                -- Draw the measuring tape for completed measurements
                self:drawMeasuringTape(
                    measurement.startX,
                    measurement.startY,
                    measurement.endX,
                    measurement.endY,
                    measurement.length  -- Pass the actualLength here
                )
            end
        end

        love.graphics.setColor(1, 1, 1) -- Reset color
    end

    -- After displaying measurements, show volume calculation prompt
    if state == STATES.QUESTION then
        -- Draw a fancy question box with shadow
        local boxWidth = baseWidth * 0.5
        local boxHeight = 160
        local boxX = (baseWidth - boxWidth) / 3 + 50
        local boxY = 300

        -- Draw shadow
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", boxX + 5, boxY + 5, boxWidth, boxHeight, 15, 15)

        -- Draw main box with water-themed gradient
        local gradient = {
            {0.000, 0.749, 1.000, 0.9},
            {0.000, 0.549, 0.800, 0.9}
        }
        for i = 0, boxHeight do
            local t = i / boxHeight
            local color = {
                gradient[1][1] * (1 - t) + gradient[2][1] * t,
                gradient[1][2] * (1 - t) + gradient[2][2] * t,
                gradient[1][3] * (1 - t) + gradient[2][3] * t,
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

    -- Draw feedback during FEEDBACK state
    if state == STATES.FEEDBACK then
        -- Draw feedback background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", baseWidth / 4, baseHeight / 2 - 50, baseWidth / 2, 100, 10, 10)

        if feedbackState == "correct" then
            love.graphics.setFont(feedbackFont)
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.printf("Correct!", 0, baseHeight / 2 - 20, baseWidth, "center")
        elseif feedbackState == "incorrect" then
            love.graphics.setFont(feedbackFont)
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.printf("Incorrect. Try Again!", 0, baseHeight / 2 - 20, baseWidth, "center")
        end

        -- Draw continue prompt
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Press Enter to continue", 0, baseHeight / 2 + 20, baseWidth, "center")
    end

    -- Reset transformations
    love.graphics.pop()

    -- Draw UI elements without scaling
    self:drawCalculatorButton()
    self:drawMenuButton()

    -- Draw the calculator if it's active
    if calculator then
        calculator:draw()
    end
end

function level1:drawMeasuringTape(startX, startY, endX, endY, displayedDistance)
    -- Calculate the angle between the start and end points
    local angle = math.atan2(endY - startY, endX - startX)

    -- Calculate the distance between the start and end points
    local distance = math.sqrt((endX - startX)^2 + (endY - startY)^2)

    -- Set the color for the measuring tape
    love.graphics.setColor(1, 1, 0) -- Yellow color

    -- Set the width of the measuring tape
    local tapeWidth = 10

    -- Save the current coordinate system
    love.graphics.push()

    -- Move the coordinate system to the start point
    love.graphics.translate(startX, startY)

    -- Rotate the coordinate system to align with the measuring path
    love.graphics.rotate(angle)

    -- Draw the measuring tape as a rectangle
    love.graphics.rectangle("fill", 0, -tapeWidth / 2, distance, tapeWidth)

    -- Draw tick marks on the measuring tape
    love.graphics.setColor(0, 0, 0)
    local tickSpacing = 20
    for i = 0, distance, tickSpacing do
        love.graphics.rectangle("fill", i, -tapeWidth / 2, 2, tapeWidth)
    end

    -- Restore the original coordinate system
    love.graphics.pop()

    -- Calculate position for label above the measuring tape
    local midX = (startX + endX) / 2
    local midY = (startY + endY) / 2
    local labelOffset = 30 -- Distance above the tape

    -- Calculate the perpendicular offset for the label
    local labelX = midX - (labelOffset * math.sin(angle))
    local labelY = midY - (labelOffset * math.cos(angle))

    -- Draw background for the label
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", labelX - 40, labelY - 15, 80, 30, 5, 5)

    -- Draw the measurement text using displayedDistance
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("%.2f units", displayedDistance),
        labelX - 40,
        labelY - 10,
        80,
        "center"
    )

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function level1:drawMenuButton()
    love.graphics.setColor(0.2, 0.2, 0.8, 0.5)
    love.graphics.rectangle("fill", menuButton.x, menuButton.y, menuButton.width, menuButton.height, 5, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", menuButton.x, menuButton.y, menuButton.width, menuButton.height, 5, 5)

    love.graphics.setFont(menuButtonFont or defaultFont)
    love.graphics.printf(
        menuButton.text,
        menuButton.x,
        menuButton.y + (menuButton.height / 2) - ((menuButtonFont or defaultFont):getHeight() / 2)-100,
        menuButton.width,
        "center"
    )
end

function level1:drawCalculatorButton()
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

function level1:drawDashedLine(x1, y1, x2, y2, dashLength, gapLength)
    dashLength = dashLength or 5
    gapLength = gapLength or 5

    local dx = x2 - x1
    local dy = y2 - y1
    local lineLength = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)
    local cosAngle = math.cos(angle)
    local sinAngle = math.sin(angle)

    local numDashes = math.floor(lineLength / (dashLength + gapLength))
    for i = 0, numDashes - 1 do
        local startX = x1 + (i * (dashLength + gapLength)) * cosAngle
        local startY = y1 + (i * (dashLength + gapLength)) * sinAngle
        local endX = startX + dashLength * cosAngle
        local endY = startY + dashLength * sinAngle
        love.graphics.line(startX, startY, endX, endY)
    end
end

return level1
