local level3 = {}

-- Game States
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
local backgroundImage

-- Feedback assets
local checkImage
local xImage
local userAnswer =""
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
    { question = "How much water is needed for drinking?", key = "drinking" },
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
    questionFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 22)
    feedbackFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 28)
    titleFont = love.graphics.newFont("assets/fonts/OpenSans-Bold.ttf", 36)
    
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

function level3:draw()
    if backgroundImage then
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local imgWidth, imgHeight = backgroundImage:getDimensions()

        local scale = math.min(screenWidth / imgWidth, screenHeight / imgHeight)

        love.graphics.draw(backgroundImage, 0, 65, 0, scale, scale)
    end

    self:displayQuestion()
    self:displayFeedback()
    self:drawUserAnswer()
end

-- Function to display the user's current answer
function level3:drawUserAnswer()
    if gameState == STATES.QUESTION then
        love.graphics.setFont(questionFont) -- Ensure the question font is active
        love.graphics.setColor(0, 0, 0) -- Black text for visibility
        local displayText = "Your Answer: " .. (userAnswer or "")
        love.graphics.print(displayText, 70, 360) -- Positioned below the question
        love.graphics.setColor(1, 1, 1) -- Reset color to white for subsequent drawings
    end
end

-- Display current question
function level3:displayQuestion()
    local question = self.questions[self.currentQuestion].question

    -- Draw question background
    love.graphics.draw(self.questionBg, 330, 100)

    -- Set font for the question text and draw it on screen
    love.graphics.setFont(questionFont)
    love.graphics.setColor(1, 1, 1)  -- White color for text
    love.graphics.print(question, 70, 320)
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
        feedbackTimer = feedbackTimer - love.timer.getDelta() --Countdown
        if feedbackState == "correct" then
            love.graphics.draw(checkImage, 0, 0)
            love.graphics.setFont(feedbackFont)
            love.graphics.print("Correct!", 0, 0)
        elseif feedbackState == "incorrect" then
            love.graphics.draw(xImage, 0, 0)
            love.graphics.setFont(feedbackFont)
            love.graphics.print("Incorrect!", 0, 0)
        end
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
    if gameState == STATES.DIALOGUE and button == 1 then
        self:advanceDialogue()
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
