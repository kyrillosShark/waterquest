local level3 = {}
local Gamestate = require "gamestate"
local menu = require "menu"
local calculator = require "calculator"
calculatorActive = false
local time = 0
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
local userAnswer =""
local feedbackState = nil -- "correct" or "incorrect"
local feedbackTimer = 0
local feedbackDuration = 2
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
    { question = "How much water is needed for agriculture?", key = "drinking" },
    { question = "How much water is needed for cooking?", key = "cooking" },
    { question = "How much water is needed for washing?", key = "washing" },
    { question = "How much water is needed for irrigation?", key = "irrigation" }
}
level3.currentQuestion = 1

function level3:enter()
gameState = STATES.QUESTION
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
    
end
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

function level3:draw()
    -- Create a gradient effect for the back wall
    local wallHeight = love.graphics.getHeight()
    local wallWidth = love.graphics.getWidth()
    
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
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local boardWidth = 810  -- 905 - 95
    local boardHeight = 400 -- 445 - 45
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
        centerX + boardWidth - 10, centerY + 400, -- Bottom right
        centerX + 10, centerY + 400    -- Bottom left
    )
    
    -- Draw wooden frame around chalkboard
    love.graphics.setColor(0.6, 0.4, 0.2)
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", 
        centerX, centerY,              -- Top left
        centerX + boardWidth, centerY, -- Top right
        centerX + boardWidth - 10, centerY + 400, -- Bottom right
        centerX + 10, centerY + 400    -- Bottom left
    )
    love.graphics.setLineWidth(1)

    -- Reset color to white for subsequent drawings
    love.graphics.setColor(1, 1, 1)

    self:displayQuestion()
    self:displayFeedback()
    self:drawUserAnswer()
    love.graphics.setColor(0.5, 0.3, 0.1)
    self:drawDialogue()
    
    
    -- Draw wooden marker holder at the bottom of the chalkboard
    
end

function level3:advanceDialogue()
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


-- Function to display the user's current answer
function level3:drawUserAnswer()
    if gameState == STATES.QUESTION then
        love.graphics.setFont(questionFont) -- Ensure the question font is active
        love.graphics.setColor(1, 1, 1, 1) -- Black text for visibility
        local displayText = "Your Answer: " .. (userAnswer or "")
        love.graphics.print(displayText, 150, 350) -- Positioned below the question
        love.graphics.setColor(1, 1, 1) -- Reset color to white for subsequent drawings
    end
end



-- Reset color
love.graphics.setColor(1, 1, 1)

function level3:displayQuestion()
    local question = self.questions[self.currentQuestion].question

    -- Target width and height for shrinking the image
    local targetWidth = 200  -- Adjust this to your desired width
    local targetHeight = 200 -- Adjust this to your desired height

    -- Get original dimensions of self.questionBg
    local imgWidth, imgHeight = self.questionBg:getDimensions()

    -- Calculate scale factors to shrink the image to target size
    local scaleX = targetWidth / imgWidth
    local scaleY = targetHeight / imgHeight

    -- Draw the question background with scaling applied
    love.graphics.draw(self.questionBg, -10, 400, 0, scaleX, scaleY)

    -- Set font for the question text and draw it on screen
    love.graphics.setFont(questionFont)
    love.graphics.setColor(1, 1, 1)  -- Black color for text
    love.graphics.print(question, 150, 125)

    love.graphics.setColor(1,1,1)
end

-- Check if user answer is correct and give feedback
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

function level3:displayFeedback()
    if feedbackTimer > 0 then
        feedbackTimer = feedbackTimer - love.timer.getDelta()

        -- Set color for feedback text and images based on state
        if feedbackState == "correct" then

    -- Scale and position the checkImage for correct feedback
            local targetWidth = 50   -- Desired width in pixels
            local targetHeight = 50  -- Desired height in pixels
            local scaleX = targetWidth / checkImage:getWidth()
            local scaleY = targetHeight / checkImage:getHeight()

            love.graphics.draw(checkImage,  360, 250, 0, scaleX, scaleY)
            love.graphics.setFont(feedbackFont)
            love.graphics.setColor(0, 1, 0)  -- Green color for correct feedback
            love.graphics.print("Correct!", 340, 350)
        elseif feedbackState == "incorrect" then

             -- Scale down xImage
             local targetWidth = 50   -- Desired width in pixels
             local targetHeight = 50  -- Desired height in pixels
             local scaleX = targetWidth / xImage:getWidth()
             local scaleY = targetHeight / xImage:getHeight()
 
             love.graphics.setColor(1, 0, 0)  -- Red color for "Incorrect" image
             love.graphics.draw(xImage, 375, 250, 0, scaleX, scaleY)  -- Apply the scaling factors
             
            -- Set the color for incorrect feedback text and image separately
            love.graphics.setColor(1, 0, 0)  -- Red color for "incorrect" image

            love.graphics.setColor(1, 0, 0)  -- Yellow color for incorrect feedback text
            love.graphics.print("Incorrect!", 340, 350)
        end

        -- Reset color to white for any other drawings after feedback
        love.graphics.setColor(1, 1, 1)
    end
end
function level3:update(dt)
    -- Update time for smooth sway animation
    time = time + dt

    -- Handle calculator updates first
    if calculatorActive and calculator then
        calculator:update(dt)
        return -- Exit early if calculator is active
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


-- Define a keyDown table to track key presses
local keyDown = {}

-- Handle all input in keypressed
function level3:keypressed(key)
    -- Only process keypress if key is not already held down
    if gameState == STATES.QUESTION and not keyDown[key] then
        keyDown[key] = true -- Mark key as held down

        -- Only process if a number is pressed
        if tonumber(key) then
            userAnswer = (userAnswer or "") .. key
            print("User Answer: " .. userAnswer)  -- Debugging
        elseif key == "return" then
            -- Process the answer on Enter
            local numericAnswer = tonumber(userAnswer)
            if numericAnswer then
                print("Submitted Answer: " .. numericAnswer)
                self:checkAnswer(numericAnswer)
            else
                print("Invalid input. Please enter a number.")
            end
            userAnswer = ""  -- Reset user answer after checking
        elseif key == "backspace" then
            -- Handle backspace for deleting characters
            userAnswer = string.sub(userAnswer, 1, -2)
            print("Backspace pressed. Current Answer: " .. userAnswer)
        end
    end

    if key == "escape" then
        Gamestate.switch(menu)  -- Return to menu
    end
end

-- Reset keyDown state when a key is released
function level3:keyreleased(key)
    keyDown[key] = nil
end
-- Function to handle mouse presses
function level3:mousepressed(x, y, button, istouch, presses)
    -- Handle calculator interactions first
    if calculatorActive and calculator:isActive() then
        calculator:mousepressed(x, y, button, istouch, presses)
        return
    end

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

    end
end


-- Main game loop with question and answer flow
function level3:run()
    if feedbackTimer > 0 then
        feedbackTimer = feedbackTimer - love.timer.getDelta()-- Countdown feedback display
        self:displayQuestion()
    else
        self:displayFeedback()
    end
end

-- Function to draw elements on screen
function love.draw()
    
    if gameState == "level3" then
        level3:draw()
    end
    
end


return level3
