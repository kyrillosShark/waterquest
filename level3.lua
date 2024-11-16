local level3 = {}
local Gamestate = require "gamestate"
local menu = require "menu"
local calculator = require "calculator"
calculatorActive = false
local time = 0

-- Scaling variables
local scale = 1
local offsetX = 0
local offsetY = 0
local screenWidth = 800
local screenHeight = 600

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

-- Game States
local STATES = {
    DIALOGUE = "dialogue",
    MOVING = "moving",
    RAINING = "raining",
    QUESTION = "question",
    GAMEPLAY = "gameplay"
}

local character2 = {
    image = nil,
    x = screenWidth / 2 + 250,
    y = screenHeight, -- Positioned above the ground
    scale = 0.5,
    velocityX = 0,
    velocityY = 0
}

-- Local variables for level-specific assets
local clouds = {}
local grasses = {}
local grassImages = {}
local cloudImage
local raindropImage
local backgroundImage
local currentDialogue = 1
local state = STATES.DIALOGUE

-- Feedback assets
local checkImage
local xImage
local userAnswer = ""
local feedbackState = nil -- "correct" or "incorrect"
local feedbackTimer = 0
local feedbackDuration = 2

local dialogue = {
    {
        character = "assets/images/character2.png",
        text = "Using the water that we gathered lets us..."
    },
    -- Additional dialogue entries can be added here
}

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

-- Game variables
level3.students = 10  -- Number of students
level3.totalWater = 500  -- Total available water for the day

-- Daily water requirements (in liters) per student
level3.requirements = {
    drinking = 2,   -- 2 liters per student for drinking
    cooking = 1,    -- 1 liter per student for cooking
    washing = 3,    -- 3 liters per student for washing
    irrigation = 5  -- 5 liters per student for irrigation
}

-- Questions to ask for water allocation
level3.questions = {
    { question = "How much water is needed for agriculture?", key = "irrigation" },
    { question = "How much water is needed for cooking?", key = "cooking" },
    { question = "How much water is needed for washing?", key = "washing" },
    { question = "How much water is needed for drinking?", key = "drinking" }
}
level3.currentQuestion = 1

-- Function to update scale based on window size
function level3:updateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local scaleX = windowWidth / screenWidth
    local scaleY = windowHeight / screenHeight
    scale = math.min(scaleX, scaleY)
    
    -- Calculate offset to center the content
    offsetX = (windowWidth - (screenWidth * scale)) / 2
    offsetY = (windowHeight - (screenHeight * scale)) / 2
end

function level3:resize(w, h)
    self:updateScale()
end

-- Coordinate conversion function
function level3:toWorldCoords(x, y)
    return (x - offsetX) / scale, (y - offsetY) / scale
end

-- Function called when entering Level 3
function level3:enter()
    state = STATES.QUESTION
    print("gamestate set to question")
    
    -- Load any necessary assets for Level 3 (images, sounds, etc.)
    backgroundImage = love.graphics.newImage("assets/images/mini-white-board.png")
    self.questionBg = love.graphics.newImage("assets/images/character2.png")
    checkImage = love.graphics.newImage("assets/images/check.png")
    xImage = love.graphics.newImage("assets/images/x.png")
    defaultFont = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 18)
    questionFont = love.graphics.newFont("assets/fonts/chalk.otf", 22)
    feedbackFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 28)
    titleFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 36)
    calculator:init()
    calculator:setPosition(screenWidth - 400, 100)  -- Set position but don't activate
    calculator:deactivate()
    
    userAnswer = ""
    
    -- Display instructions to the player
    print("Welcome to Level 3!")
    print("You need to allocate water for " .. self.students .. " students.")
    print("Total available water: " .. self.totalWater .. " liters.")
    print("Daily water needs per student:")
    
    local totalNeeds = self:calculateTotalNeeds()
    for activity, amount in pairs(totalNeeds) do
        print(activity .. ": " .. amount .. " liters")
    end

    self.userAllocations = {}
    
    -- Initialize scaling
    self:updateScale()
end

-- Function to draw menu button
function level3:drawMenuButton()
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

-- Function to draw calculator button
function level3:drawCalculatorButton()
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

-- Function to draw Level 3 elements
function level3:draw()
    love.graphics.clear(0.529, 0.808, 0.980) -- Clear with sky blue color
    
    -- Begin scaling
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
    
    local wallWidth = screenWidth
    local wallHeight = screenHeight
    
    -- Draw gradient wall (darker at top, lighter at bottom)
    for i = 0, wallHeight do
        local gradient = 0.88 + (i / wallHeight) * 0.07  -- Gradually gets lighter
        love.graphics.setColor(0.95 * gradient, 0.93 * gradient, 0.88 * gradient)
        love.graphics.line(0, i, wallWidth, i)
    end

    -- Draw perspective lines in corners
    love.graphics.setColor(0.85, 0.83, 0.78, 0.3)
    love.graphics.line(0, 0, 50, 50)  -- Top left corner
    love.graphics.line(wallWidth, 0, wallWidth - 50, 50)  -- Top right corner
    love.graphics.line(0, wallHeight, 50, wallHeight - 50)  -- Bottom left corner
    love.graphics.line(wallWidth, wallHeight, wallWidth - 50, wallHeight - 50)  -- Bottom right corner

    -- Draw chalkboard with slight perspective
    -- Calculate center position
    local boardWidth = 600  -- Adjusted to fit within screen
    local boardHeight = 400 -- 400 pixels tall
    local centerX = (screenWidth - boardWidth) / 2
    local centerY = (screenHeight - boardHeight) / 2
    local holderWidth = boardWidth * 0.8
    local holderHeight = 30
    local holderX = centerX + (boardWidth - holderWidth) / 2
    local holderY = centerY + boardHeight 

    -- Draw main holder body
    love.graphics.setColor(0.4, 0.25, 0.1)
    love.graphics.rectangle("fill", holderX, holderY, holderWidth, holderHeight)

    -- Draw holder edge details
    love.graphics.setColor(0.3, 0.2, 0.1)
    love.graphics.rectangle("fill", holderX - 10, holderY - 5, holderWidth + 20, 10)

    self:drawMenuButton()
    self:drawCalculatorButton()

    -- Draw chalkboard
    love.graphics.setColor(0.2, 0.3, 0.2)
    love.graphics.polygon("fill", 
        centerX, centerY,              -- Top left
        centerX + boardWidth, centerY, -- Top right
        centerX + boardWidth - 10, centerY + boardHeight, -- Bottom right
        centerX + 10, centerY + boardHeight    -- Bottom left
    )
    
    -- Draw wooden frame around chalkboard
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", 
        centerX, centerY,              -- Top left
        centerX + boardWidth, centerY, -- Top right
        centerX + boardWidth - 10, centerY + boardHeight, -- Bottom right
        centerX + 10, centerY + boardHeight    -- Bottom left
    )
    love.graphics.setLineWidth(1)

    -- Reset color to white for subsequent drawings
    love.graphics.setColor(1, 1, 1)

    self:displayQuestion(centerX, centerY, boardWidth, boardHeight)
    self:displayFeedback(centerX, centerY, boardWidth, boardHeight)
    self:drawUserAnswer(centerX, centerY, boardWidth, boardHeight)
    love.graphics.setColor(0.5, 0.3, 0.1)
    self:drawDialogue()
    love.graphics.pop()
end

-- Function to display the question
function level3:displayQuestion(centerX, centerY, boardWidth, boardHeight)
    local question = self.questions[self.currentQuestion].question

    -- Target width and height for shrinking the image
    local targetWidth = 100  -- Adjusted width
    local targetHeight = 100 -- Adjusted height

    -- Get original dimensions of self.questionBg
    local imgWidth, imgHeight = self.questionBg:getDimensions()

    -- Calculate scale factors to shrink the image to target size
    local scaleX = targetWidth / imgWidth
    local scaleY = targetHeight / imgHeight

    -- Draw the question background with scaling applied
    love.graphics.draw(self.questionBg, centerX + 50, centerY + 50, 0, scaleX, scaleY)

    -- Set font for the question text and draw it on screen
    love.graphics.setFont(questionFont)
    love.graphics.setColor(1, 1, 1)  -- White color for text
    love.graphics.printf(question, centerX + 50, centerY + 170, boardWidth - 100, "center")

    love.graphics.setColor(1,1,1)
end

-- Function to display the user's current answer
function level3:drawUserAnswer(centerX, centerY, boardWidth, boardHeight)
    if state == STATES.QUESTION then
        love.graphics.setFont(questionFont) -- Ensure the question font is active
        love.graphics.setColor(1, 1, 1, 1) -- White text for visibility
        local displayText = "Your Answer: " .. (userAnswer or "")
        love.graphics.printf(displayText, centerX + 50, centerY + boardHeight - 50, boardWidth - 100, "center")
        love.graphics.setColor(1, 1, 1) -- Reset color to white for subsequent drawings
    end
end

-- Function to display feedback
function level3:displayFeedback(centerX, centerY, boardWidth, boardHeight)
    if feedbackTimer > 0 then
        feedbackTimer = feedbackTimer - love.timer.getDelta()

        -- Set color for feedback text and images based on state
        if feedbackState == "correct" then

            -- Scale and position the checkImage for correct feedback
            local targetWidth = 50   -- Desired width in pixels
            local targetHeight = 50  -- Desired height in pixels
            local scaleX = targetWidth / checkImage:getWidth()
            local scaleY = targetHeight / checkImage:getHeight()

            love.graphics.draw(checkImage, centerX + boardWidth / 2 - targetWidth / 2, centerY + boardHeight / 2 - targetHeight / 2, 0, scaleX, scaleY)
            love.graphics.setFont(feedbackFont)
            love.graphics.setColor(0, 1, 0)  -- Green color for correct feedback
            love.graphics.printf("Correct!", centerX, centerY + boardHeight / 2 + 30, boardWidth, "center")
        elseif feedbackState == "incorrect" then

            -- Scale down xImage
            local targetWidth = 50   -- Desired width in pixels
            local targetHeight = 50  -- Desired height in pixels
            local scaleX = targetWidth / xImage:getWidth()
            local scaleY = targetHeight / xImage:getHeight()

            love.graphics.setColor(1, 0, 0)  -- Red color for "Incorrect" image
            love.graphics.draw(xImage, centerX + boardWidth / 2 - targetWidth / 2, centerY + boardHeight / 2 - targetHeight / 2, 0, scaleX, scaleY)

            -- Set the color for incorrect feedback text
            love.graphics.setColor(1, 0, 0)
            love.graphics.setFont(feedbackFont)
            love.graphics.printf("Incorrect!", centerX, centerY + boardHeight / 2 + 30, boardWidth, "center")
        end

        -- Reset color to white for any other drawings after feedback
        love.graphics.setColor(1, 1, 1)
    end
end

-- Function to draw dialogue
function level3:drawDialogue()
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

-- Function to advance the dialogue sequence
function level3:advanceDialogue()
    currentDialogue = currentDialogue + 1
    print("Advancing Dialogue:", currentDialogue)

    if currentDialogue > #dialogue then
        if self.levelCompleted then
            -- Level is completed, switch to the next level or menu
            Gamestate.switch(menu)
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

-- Function to calculate total needs
function level3:calculateTotalNeeds()
    local totalNeeds = {}
    for activity, amount in pairs(self.requirements) do
        totalNeeds[activity] = amount * self.students
    end
    return totalNeeds
end

-- Function to check if the user's answer is correct
function level3:checkAnswer(answer)
    local questionKey = self.questions[self.currentQuestion].key
    local requiredAmount = self.requirements[questionKey] * self.students
    
    if answer == requiredAmount then
        print("Correct!")
        feedbackState = "correct"
    else
        print("Incorrect. The correct answer is " .. requiredAmount .. " liters.")
        feedbackState = "incorrect"
    end
    
    feedbackTimer = feedbackDuration  -- Start feedback timer
    self.currentQuestion = self.currentQuestion % #self.questions + 1  -- Move to next question
end

-- Function to update Level 3
function level3:update(dt)
    -- Update time for smooth sway animation
    time = time + dt

    -- Handle calculator updates first
    if calculatorActive and calculator then
        calculator:update(dt)
        return -- Exit early if calculator is active
    end

    -- Update feedback timer
    if feedbackTimer > 0 then
        feedbackTimer = feedbackTimer - dt
    end
end

-- Handle key presses
function level3:keypressed(key)
    if key == "f" then love.graphics.toggleFullscreen() end

    if calculator:isActive() then
        calculator:keypressed(key)
        return -- Exit early if calculator is active
    end

    if state == STATES.DIALOGUE then
        if key == "return" or key == "space" then
            self:advanceDialogue()
            return
        end
    elseif state == STATES.QUESTION then
        if tonumber(key) then
            userAnswer = userAnswer .. key
        elseif key == "backspace" then
            userAnswer = string.sub(userAnswer, 1, -2)
        elseif key == "return" then
            local numericAnswer = tonumber(userAnswer)
            if numericAnswer then
                self:checkAnswer(numericAnswer)
            else
                print("Invalid input. Please enter a number.")
                feedbackState = "incorrect"
                feedbackTimer = feedbackDuration
            end
            userAnswer = ""
        end
    end

    if key == "escape" then
        Gamestate.switch(menu)
    end
end

-- Function to check if the mouse is over a button
local function isMouseOver(button, x, y)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Function to handle mouse presses
function level3:mousepressed(x, y, button, istouch, presses)
    -- Convert mouse coordinates to world coordinates
    local worldX, worldY = self:toWorldCoords(x, y)
    
    -- Handle calculator interactions first
    if calculatorActive and calculator:isActive() then
        calculator:mousepressed(worldX, worldY, button, istouch, presses)
        return
    end

    -- Handle left mouse button clicks
    if button == 1 then
        -- Check menu button
        if isMouseOver(menuButton, worldX, worldY) then
            Gamestate.switch(menu)
            print("Returning to the main menu.")
            return
        end

        -- Check calculator button
        if isMouseOver(calculatorButton, worldX, worldY) then
            calculator:activate()
            calculatorActive = true
            print("Calculator activated.")
            return
        end

        -- Check dialogue state
        if state == STATES.DIALOGUE then
            self:advanceDialogue()
            return
        end
    end
end

return level3
