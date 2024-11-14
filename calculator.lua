local calculator = {
    new = function()
        local instance = {}
        setmetatable(instance, { __index = calculator })
        instance:init()
        return instance
    end
}

function calculator:init()
    self.active = false
    self.input = ""
    self.result = ""
    self.operator = nil
    self.operand1 = nil
    self.operand2 = nil
    self.x = 0
    self.y = 0
    self.width = 300
    self.height = 300
    self.lastButtonPress = 0

    -- Load fonts with error handling
    local success, err = pcall(function()
        self.font = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 18)
        self.buttonFont = love.graphics.newFont("assets/fonts/OpenSans-Regular.ttf", 16)
    end)
    
    if not success then
        self.font = love.graphics.newFont(18)
        self.buttonFont = love.graphics.newFont(16)
        print("Warning: Failed to load custom font, using default")
    end

    self.buttons = {}
    self:createButtons()
    self:deactivate()
end

function calculator:createButtons()
    local buttonLabels = {
        {"7", "8", "9", "/"},
        {"4", "5", "6", "*"},
        {"1", "2", "3", "-"},
        {"0", ".", "=", "+"},
    }
    
    local buttonWidth = 60
    local buttonHeight = 40
    local spacing = 10
    local baseX = 20
    local baseY = 100

    for rowIndex, row in ipairs(buttonLabels) do
        for colIndex, label in ipairs(row) do
            local button = {
                baseX = baseX + (colIndex - 1) * (buttonWidth + spacing),
                baseY = baseY + (rowIndex - 1) * (buttonHeight + spacing),
                width = buttonWidth,
                height = buttonHeight,
                label = label
            }
            table.insert(self.buttons, button)
        end
    end

    -- Add clear button
    local clearButton = {
        baseX = baseX,
        baseY = baseY - (buttonHeight + spacing),
        width = buttonWidth * 2 + spacing,
        height = buttonHeight,
        label = "C"
    }
    table.insert(self.buttons, clearButton)

    -- Add close button
    local closeButton = {
        baseX = self.width - 35,
        baseY = 10,
        width = 25,
        height = 25,
        label = "X"
    }
    table.insert(self.buttons, closeButton)
end
function calculator:draw()
    if not self.active then return end

    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate center position
    self.x = (screenWidth - self.width) / 2
    self.y = (screenHeight - self.height) / 2

    -- Draw calculator background
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    
    -- Draw display area
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x + 20, self.y + 20, self.width - 40, 60, 5, 5)
    love.graphics.setColor(0, 0, 0)
    
    -- Draw current input and operation
    love.graphics.setFont(self.font)
    local displayText = self.input
    if self.operator and self.operand1 then
        displayText = tostring(self.operand1) .. " " .. self.operator .. " " .. displayText
    elseif self.result ~= "" then
        displayText = self.result
    end
    love.graphics.printf(displayText, self.x + 30, self.y + 40, self.width - 60, "right")
    
    -- Draw buttons
    for _, button in ipairs(self.buttons) do
        local actualX = self.x + button.baseX
        local actualY = self.y + button.baseY
        
        -- Special styling for close button
        local isCloseButton = button.label == "X"
        if isCloseButton then
            love.graphics.setColor(0.9, 0.3, 0.3)
        else
            love.graphics.setColor(0.9, 0.9, 0.9)
        end
        
        love.graphics.rectangle("fill", actualX, actualY, button.width, button.height, 5, 5)
        
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("line", actualX, actualY, button.width, button.height, 5, 5)
        
        if isCloseButton then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0, 0, 0)
        end
        
        love.graphics.setFont(self.buttonFont)
        love.graphics.printf(button.label, actualX, actualY + (button.height/2 - 8), button.width, "center")
    end
end

function calculator:mousepressed(mx, my, button, istouch, presses)
    if not self.active or button ~= 1 then return end
    
    for _, btn in ipairs(self.buttons) do
        local actualX = self.x + btn.baseX
        local actualY = self.y + btn.baseY
        
        if mx >= actualX and mx <= actualX + btn.width and
           my >= actualY and my <= actualY + btn.height then
            self:buttonPressed(btn.label)
            return
        end
    end
end
function calculator:buttonPressed(label)
    if not self.active then return end
    
    local currentTime = love.timer.getTime()
    if currentTime - self.lastButtonPress < 0.1 then return end
    self.lastButtonPress = currentTime
    
    print("Button pressed:", label)
    print("Button pressed:", label)
    
    if label == "C" then
        self:clear()
    elseif label == "X" then
        self:deactivate()
    elseif label == "=" then
        self:calculateResult()
    elseif label == "+" or label == "-" or label == "*" or label == "/" then
        if self.input ~= "" or self.result ~= "" then
            self.operand1 = tonumber(self.input ~= "" and self.input or self.result)
            self.operator = label
            self.input = ""
            self.result = ""
            print("Operator set:", self.operator, "Operand1:", self.operand1)
        end
    else
        if label == "." and self.input:find("%.") then
            return
        end
        if self.result ~= "" and self.operator == nil then
            self.input = ""
            self.result = ""
        end
        self.input = self.input .. label
        print("Current input:", self.input)
    end
end

-- Modified keypressed function
function calculator:keypressed(key)
    if not self.active then return end

    if key == "backspace" then
        self.input = string.sub(self.input, 1, -2)
    elseif key == "return" or key == "kpenter" then
        self:calculateResult()
    elseif key == "escape" then
        self:deactivate()
    elseif key == "c" then
        self:clear()
    elseif key == "+" or key == "-" or key == "*" or key == "/" then
        self:buttonPressed(key)
    elseif key >= "0" and key <= "9" or key == "." then
        self:buttonPressed(key)
    end
end

-- Input is handled by mousepressed and keypressed functions
function calculator:textinput(t)
    return
end

function calculator:clear()
    self.input = ""
    self.result = ""
    self.operator = nil
    self.operand1 = nil
    self.operand2 = nil
    print("Calculator cleared")
end

function calculator:calculateResult()
    if self.operator and self.operand1 and self.input ~= "" then
        self.operand2 = tonumber(self.input)
        
        print("Calculating:", self.operand1, self.operator, self.operand2)
        
        if not self.operand1 or not self.operand2 then
            self.result = "Error"
            return
        end
        
        if self.operator == "+" then
            self.result = tostring(self.operand1 + self.operand2)
        elseif self.operator == "-" then
            self.result = tostring(self.operand1 - self.operand2)
        elseif self.operator == "*" then
            self.result = tostring(self.operand1 * self.operand2)
        elseif self.operator == "/" then
            if self.operand2 ~= 0 then
                self.result = tostring(self.operand1 / self.operand2)
            else
                self.result = "Error"
            end
        end
        
        if self.result ~= "Error" then
            local num = tonumber(self.result)
            if num then
                if math.floor(num) == num then
                    self.result = tostring(math.floor(num))
                else
                    self.result = string.format("%.6f", num):gsub("0+$", ""):gsub("%.$", "")
                end
            end
        end
        
        print("Result calculated:", self.result)
        self.input = ""
        self.operator = nil
        self.operand1 = nil
        self.operand2 = nil
    end
end

function calculator:activate()
    self.active = true
    self.input = ""
    self.result = ""
    self.operator = nil
    self.operand1 = nil
    self.operand2 = nil
    
end

function calculator:deactivate()
    self.active = false
    
end

function calculator:isActive()
    return self.active
end

function calculator:setPosition(x, y)
    self.x = x
    self.y = y
end

function calculator:update(dt)
    if not self.active then return end
end

return calculator
