local FluxUI = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Config System
local ConfigFolder = "FluxUI_Configs"
local ConfigSystem = {
    CurrentConfig = {},
    Flags = {},
    Initialized = false
}

-- Initialize Config System
local function InitializeConfigSystem()
    if not ConfigSystem.Initialized then
        ConfigSystem.CurrentConfig = {}
        ConfigSystem.Flags = {}
        ConfigSystem.Initialized = true
    end
end

-- Utility Functions
local function Tween(object, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Safe callback wrapper
local function SafeCallback(callback, ...)
    if callback and type(callback) == "function" then
        local success, err = pcall(callback, ...)
        if not success then
            warn("Callback error:", err)
        end
    end
end

local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos
    
    dragHandle = dragHandle or frame
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        Tween(frame, {
            Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        }, 0.1, Enum.EasingStyle.Linear)
    end
    
    -- Mouse Input
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)
end

-- Create GUI Protection
local function CreateScreenGui(name)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name or "FluxUI_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    else
        screenGui.Parent = CoreGui
    end
    
    return screenGui
end

-- Notification System
local NotificationHolder = nil

local function CreateNotification(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or "This is a notification"
    local duration = config.Duration or 3
    local type = config.Type or "Default" -- Default, Success, Warning, Error
    
    if not NotificationHolder then
        NotificationHolder = Instance.new("Frame")
        NotificationHolder.Name = "NotificationHolder"
        NotificationHolder.Size = UDim2.new(0, 300, 1, 0)
        NotificationHolder.Position = UDim2.new(1, -310, 0, 10)
        NotificationHolder.BackgroundTransparency = 1
        NotificationHolder.Parent = CreateScreenGui("FluxUI_Notifications")
        
        local NotifList = Instance.new("UIListLayout")
        NotifList.SortOrder = Enum.SortOrder.LayoutOrder
        NotifList.Padding = UDim.new(0, 10)
        NotifList.VerticalAlignment = Enum.VerticalAlignment.Top
        NotifList.Parent = NotificationHolder
    end
    
    local typeColors = {
        Default = Color3.fromRGB(88, 101, 242),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69)
    }
    
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 0)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.ClipsDescendants = true
    NotifFrame.Parent = NotificationHolder
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame
    
    local NotifAccent = Instance.new("Frame")
    NotifAccent.Size = UDim2.new(0, 4, 1, 0)
    NotifAccent.BackgroundColor3 = typeColors[type] or typeColors.Default
    NotifAccent.BorderSizePixel = 0
    NotifAccent.Parent = NotifFrame
    
    local NotifAccentCorner = Instance.new("UICorner")
    NotifAccentCorner.CornerRadius = UDim.new(0, 10)
    NotifAccentCorner.Parent = NotifAccent
    
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -50, 0, 20)
    NotifTitle.Position = UDim2.new(0, 15, 0, 8)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    NotifTitle.TextSize = 14
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Parent = NotifFrame
    
    local NotifContent = Instance.new("TextLabel")
    NotifContent.Size = UDim2.new(1, -30, 0, 1000)
    NotifContent.Position = UDim2.new(0, 15, 0, 30)
    NotifContent.BackgroundTransparency = 1
    NotifContent.Text = content
    NotifContent.TextColor3 = Color3.fromRGB(180, 180, 190)
    NotifContent.TextSize = 12
    NotifContent.Font = Enum.Font.Gotham
    NotifContent.TextXAlignment = Enum.TextXAlignment.Left
    NotifContent.TextYAlignment = Enum.TextYAlignment.Top
    NotifContent.TextWrapped = true
    NotifContent.Parent = NotifFrame
    
    NotifContent.Size = UDim2.new(1, -30, 0, NotifContent.TextBounds.Y)
    
    local totalHeight = 45 + NotifContent.TextBounds.Y
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Position = UDim2.new(1, -28, 0, 8)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(180, 180, 190)
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = NotifFrame
    
    Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.3, Enum.EasingStyle.Back)
    
    local function closeNotif()
        Tween(NotifFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        NotifFrame:Destroy()
    end
    
    CloseButton.MouseButton1Click:Connect(closeNotif)
    
    task.delay(duration, closeNotif)
end

-- Config System Functions
local function SaveConfig(configName, flags)
    if not flags then
        CreateNotification({
            Title = "Save Failed",
            Content = "Config system not initialized!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
    
    local success1 = pcall(function()
        if not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
    end)
    
    if not success1 then
        CreateNotification({
            Title = "Save Failed",
            Content = "Cannot create config folder. File functions may not be supported.",
            Duration = 5,
            Type = "Error"
        })
        return false
    end
    
    local configData = {}
    for flag, flagData in pairs(flags) do
        if flagData.Get and type(flagData.Get) == "function" then
            local success, value = pcall(flagData.Get)
            if success then
                configData[flag] = value
            end
        end
    end
    
    local success, result = pcall(function()
        local encoded = HttpService:JSONEncode(configData)
        writefile(ConfigFolder .. "/" .. configName .. ".json", encoded)
    end)
    
    if success then
        CreateNotification({
            Title = "Config Saved",
            Content = "Configuration '" .. configName .. "' has been saved successfully!",
            Duration = 3,
            Type = "Success"
        })
        return true
    else
        CreateNotification({
            Title = "Save Failed",
            Content = "Failed to save configuration. File functions may not be supported.",
            Duration = 5,
            Type = "Error"
        })
        return false
    end
end

local function LoadConfig(configName, flags)
    if not flags then
        CreateNotification({
            Title = "Load Failed",
            Content = "Config system not initialized!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
    
    local filePath = ConfigFolder .. "/" .. configName .. ".json"
    
    if not isfile(filePath) then
        CreateNotification({
            Title = "Load Failed",
            Content = "Configuration '" .. configName .. "' not found!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
    
    local success, result = pcall(function()
        local content = readfile(filePath)
        return HttpService:JSONDecode(content)
    end)
    
    if success and result then
        for flag, value in pairs(result) do
            if flags[flag] and flags[flag].Set and type(flags[flag].Set) == "function" then
                pcall(function()
                    flags[flag].Set(value)
                end)
            end
        end
        
        CreateNotification({
            Title = "Config Loaded",
            Content = "Configuration '" .. configName .. "' has been loaded successfully!",
            Duration = 3,
            Type = "Success"
        })
        return true
    else
        CreateNotification({
            Title = "Load Failed",
            Content = "Failed to load configuration!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
end

local function DeleteConfig(configName)
    local filePath = ConfigFolder .. "/" .. configName .. ".json"
    
    if not isfile(filePath) then
        CreateNotification({
            Title = "Delete Failed",
            Content = "Configuration '" .. configName .. "' not found!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
    
    local success = pcall(function()
        delfile(filePath)
    end)
    
    if success then
        CreateNotification({
            Title = "Config Deleted",
            Content = "Configuration '" .. configName .. "' has been deleted!",
            Duration = 3,
            Type = "Success"
        })
        return true
    else
        CreateNotification({
            Title = "Delete Failed",
            Content = "Failed to delete configuration!",
            Duration = 3,
            Type = "Error"
        })
        return false
    end
end

local function GetConfigList()
    local success1 = pcall(function()
        if not isfolder(ConfigFolder) then
            return {}
        end
    end)
    
    if not success1 then
        return {}
    end
    
    local configs = {}
    local success, files = pcall(function()
        return listfiles(ConfigFolder)
    end)
    
    if success and files then
        for _, file in ipairs(files) do
            local configName = file:match("([^/\\]+)%.json$")
            if configName then
                table.insert(configs, configName)
            end
        end
    end
    
    return configs
end

-- Public Notification Function
function FluxUI:Notify(config)
    CreateNotification(config)
end

-- Theme List
FluxUI.Themes = {"Dark", "Light", "Purple", "Ocean", "Sunset", "Rose", "Emerald", "Midnight"}

-- Main Window Class
function FluxUI:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "FluxUI Window"
    local windowSize = config.Size or UDim2.new(0, 550, 0, 400)
    local theme = config.Theme or "Dark"
    
    -- Initialize Config System
    InitializeConfigSystem()
    
    local Window = {
        Tabs = {},
        CurrentTab = nil,
        Theme = theme
    }
    
    -- Theme Colors
    local Themes = {
        Dark = {
            Background = Color3.fromRGB(20, 20, 25),
            Secondary = Color3.fromRGB(30, 30, 35),
            Tertiary = Color3.fromRGB(40, 40, 45),
            Accent = Color3.fromRGB(88, 101, 242),
            AccentHover = Color3.fromRGB(108, 121, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(180, 180, 190),
            Border = Color3.fromRGB(60, 60, 70)
        },
        Light = {
            Background = Color3.fromRGB(245, 245, 250),
            Secondary = Color3.fromRGB(255, 255, 255),
            Tertiary = Color3.fromRGB(235, 235, 240),
            Accent = Color3.fromRGB(88, 101, 242),
            AccentHover = Color3.fromRGB(108, 121, 255),
            Text = Color3.fromRGB(20, 20, 25),
            TextDim = Color3.fromRGB(100, 100, 110),
            Border = Color3.fromRGB(220, 220, 230)
        },
        Purple = {
            Background = Color3.fromRGB(25, 20, 35),
            Secondary = Color3.fromRGB(35, 28, 50),
            Tertiary = Color3.fromRGB(50, 40, 70),
            Accent = Color3.fromRGB(138, 43, 226),
            AccentHover = Color3.fromRGB(160, 80, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(190, 170, 210),
            Border = Color3.fromRGB(80, 60, 100)
        },
        Ocean = {
            Background = Color3.fromRGB(15, 25, 35),
            Secondary = Color3.fromRGB(20, 35, 50),
            Tertiary = Color3.fromRGB(30, 50, 70),
            Accent = Color3.fromRGB(0, 150, 200),
            AccentHover = Color3.fromRGB(50, 180, 230),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(150, 190, 210),
            Border = Color3.fromRGB(50, 80, 110)
        },
        Sunset = {
            Background = Color3.fromRGB(30, 20, 20),
            Secondary = Color3.fromRGB(45, 30, 30),
            Tertiary = Color3.fromRGB(60, 40, 40),
            Accent = Color3.fromRGB(255, 100, 50),
            AccentHover = Color3.fromRGB(255, 130, 80),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(220, 180, 170),
            Border = Color3.fromRGB(100, 60, 50)
        },
        Rose = {
            Background = Color3.fromRGB(30, 20, 25),
            Secondary = Color3.fromRGB(45, 30, 38),
            Tertiary = Color3.fromRGB(60, 40, 50),
            Accent = Color3.fromRGB(255, 80, 120),
            AccentHover = Color3.fromRGB(255, 120, 150),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(220, 180, 195),
            Border = Color3.fromRGB(100, 60, 75)
        },
        Emerald = {
            Background = Color3.fromRGB(18, 28, 22),
            Secondary = Color3.fromRGB(25, 40, 32),
            Tertiary = Color3.fromRGB(35, 55, 45),
            Accent = Color3.fromRGB(50, 205, 100),
            AccentHover = Color3.fromRGB(80, 230, 130),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(170, 210, 185),
            Border = Color3.fromRGB(55, 85, 65)
        },
        Midnight = {
            Background = Color3.fromRGB(10, 10, 20),
            Secondary = Color3.fromRGB(18, 18, 35),
            Tertiary = Color3.fromRGB(28, 28, 50),
            Accent = Color3.fromRGB(100, 100, 255),
            AccentHover = Color3.fromRGB(130, 130, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextDim = Color3.fromRGB(150, 150, 200),
            Border = Color3.fromRGB(50, 50, 80)
        }
    }
    
    local Colors = Themes[theme]
    
    -- Create ScreenGui
    local ScreenGui = CreateScreenGui("FluxUI")
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = windowSize
    MainFrame.Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Drop Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Colors.Secondary
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar
    
    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 12)
    TopBarFix.Position = UDim2.new(0, 0, 1, -12)
    TopBarFix.BackgroundColor3 = Colors.Secondary
    TopBarFix.BorderSizePixel = 0
    TopBarFix.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = windowName
    Title.TextColor3 = Colors.Text
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    
    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
    MinimizeButton.Position = UDim2.new(1, -80, 0, 5)
    MinimizeButton.BackgroundColor3 = Colors.Tertiary
    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.Text = "−"
    MinimizeButton.TextColor3 = Colors.Text
    MinimizeButton.TextSize = 20
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TopBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 8)
    MinimizeCorner.Parent = MinimizeButton
    
    -- Bubble for Minimized State
    local BubbleFrame = Instance.new("Frame")
    BubbleFrame.Name = "BubbleFrame"
    BubbleFrame.Size = UDim2.new(0, 60, 0, 60)
    BubbleFrame.Position = UDim2.new(1, -70, 0, 10)
    BubbleFrame.BackgroundColor3 = Colors.Accent
    BubbleFrame.BorderSizePixel = 0
    BubbleFrame.Visible = false
    BubbleFrame.ZIndex = 1000
    BubbleFrame.Parent = ScreenGui
    
    local BubbleCorner = Instance.new("UICorner")
    BubbleCorner.CornerRadius = UDim.new(1, 0)
    BubbleCorner.Parent = BubbleFrame
    
    -- Bubble Shadow
    local BubbleShadow = Instance.new("ImageLabel")
    BubbleShadow.Name = "Shadow"
    BubbleShadow.Size = UDim2.new(1, 20, 1, 20)
    BubbleShadow.Position = UDim2.new(0, -10, 0, -10)
    BubbleShadow.BackgroundTransparency = 1
    BubbleShadow.Image = "rbxassetid://5554236805"
    BubbleShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    BubbleShadow.ImageTransparency = 0.6
    BubbleShadow.ScaleType = Enum.ScaleType.Slice
    BubbleShadow.SliceCenter = Rect.new(23, 23, 277, 277)
    BubbleShadow.ZIndex = 999
    BubbleShadow.Parent = BubbleFrame
    
    -- Bubble Icon (First letter of window name)
    local BubbleIcon = Instance.new("TextLabel")
    BubbleIcon.Size = UDim2.new(1, 0, 1, 0)
    BubbleIcon.BackgroundTransparency = 1
    BubbleIcon.Text = string.sub(windowName, 1, 1):upper()
    BubbleIcon.TextColor3 = Colors.Text
    BubbleIcon.TextSize = 28
    BubbleIcon.Font = Enum.Font.GothamBold
    BubbleIcon.Parent = BubbleFrame
    
    -- Bubble Gradient
    local BubbleGradient = Instance.new("UIGradient")
    BubbleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(108, 121, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))
    }
    BubbleGradient.Rotation = 45
    BubbleGradient.Parent = BubbleFrame
    
    -- Bubble Stroke
    local BubbleStroke = Instance.new("UIStroke")
    BubbleStroke.Color = Color3.fromRGB(255, 255, 255)
    BubbleStroke.Thickness = 2
    BubbleStroke.Transparency = 0.8
    BubbleStroke.Parent = BubbleFrame
    
    -- Make Bubble Draggable
    MakeDraggable(BubbleFrame, BubbleFrame)
    
    -- Bubble Click to Restore
    local BubbleButton = Instance.new("TextButton")
    BubbleButton.Size = UDim2.new(1, 0, 1, 0)
    BubbleButton.BackgroundTransparency = 1
    BubbleButton.Text = ""
    BubbleButton.ZIndex = 1001
    BubbleButton.Parent = BubbleFrame
    
    local isMinimized = false
    local originalSize = windowSize
    local originalPosition = MainFrame.Position
    
    -- Bubble Pulse Animation
    local pulseConnection = nil
    
    local function startBubblePulse()
        if pulseConnection then return end -- Prevent duplicate connections
        pulseConnection = game:GetService("RunService").RenderStepped:Connect(function()
            if not isMinimized then
                pulseConnection:Disconnect()
                pulseConnection = nil
                return
            end
            
            local scale = 1 + math.sin(tick() * 3) * 0.05
            BubbleFrame.Size = UDim2.new(0, 60 * scale, 0, 60 * scale)
        end)
    end
    
    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = true
        originalPosition = MainFrame.Position
        
        -- Animate main frame out
        Tween(MainFrame, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(1, -30, 0, 30)
        }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.wait(0.3)
        MainFrame.Visible = false
        
        -- Show bubble with animation
        BubbleFrame.Visible = true
        BubbleFrame.Size = UDim2.new(0, 0, 0, 0)
        Tween(BubbleFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.4, Enum.EasingStyle.Back)
        
        -- Start pulse animation
        startBubblePulse()
    end)
    
    BubbleButton.MouseButton1Click:Connect(function()
        isMinimized = false
        
        -- Animate bubble out
        Tween(BubbleFrame, {
            Size = UDim2.new(0, 0, 0, 0)
        }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.wait(0.3)
        BubbleFrame.Visible = false
        BubbleFrame.Size = UDim2.new(0, 60, 0, 60)
        
        -- Show main frame with animation
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        Tween(MainFrame, {
            Size = originalSize,
            Position = originalPosition
        }, 0.4, Enum.EasingStyle.Back)
    end)
    
    -- Bubble hover effects
    BubbleButton.MouseEnter:Connect(function()
        if isMinimized then
            Tween(BubbleFrame, {Size = UDim2.new(0, 70, 0, 70)}, 0.2)
            Tween(BubbleStroke, {Transparency = 0.4}, 0.2)
        end
    end)
    
    BubbleButton.MouseLeave:Connect(function()
        if isMinimized then
            Tween(BubbleFrame, {Size = UDim2.new(0, 60, 0, 60)}, 0.2)
            Tween(BubbleStroke, {Transparency = 0.8}, 0.2)
        end
    end)
    
    MinimizeButton.MouseEnter:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Colors.Accent}, 0.2)
    end)
    
    MinimizeButton.MouseLeave:Connect(function()
        Tween(MinimizeButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
    end)
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(1, -40, 0, 5)
    CloseButton.BackgroundColor3 = Colors.Tertiary
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Colors.Text
    CloseButton.TextSize = 20
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    -- Confirmation Dialog Function
    local function ShowConfirmDialog(dialogConfig)
        dialogConfig = dialogConfig or {}
        local title = dialogConfig.Title or "Confirm"
        local content = dialogConfig.Content or "Are you sure?"
        local confirmText = dialogConfig.ConfirmText or "Yes"
        local cancelText = dialogConfig.CancelText or "No"
        local callback = dialogConfig.Callback or function() end
        
        -- Dialog Overlay
        local DialogOverlay = Instance.new("Frame")
        DialogOverlay.Size = UDim2.new(1, 0, 1, 0)
        DialogOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        DialogOverlay.BackgroundTransparency = 1
        DialogOverlay.ZIndex = 100
        DialogOverlay.Parent = ScreenGui
        
        Tween(DialogOverlay, {BackgroundTransparency = 0.5}, 0.2)
        
        -- Dialog Frame
        local DialogFrame = Instance.new("Frame")
        DialogFrame.Size = UDim2.new(0, 0, 0, 0)
        DialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        DialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        DialogFrame.BackgroundColor3 = Colors.Background
        DialogFrame.BorderSizePixel = 0
        DialogFrame.ZIndex = 101
        DialogFrame.Parent = ScreenGui
        
        local DialogCorner = Instance.new("UICorner")
        DialogCorner.CornerRadius = UDim.new(0, 12)
        DialogCorner.Parent = DialogFrame
        
        -- Dialog Shadow
        local DialogShadow = Instance.new("ImageLabel")
        DialogShadow.Size = UDim2.new(1, 30, 1, 30)
        DialogShadow.Position = UDim2.new(0, -15, 0, -15)
        DialogShadow.BackgroundTransparency = 1
        DialogShadow.Image = "rbxassetid://5554236805"
        DialogShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        DialogShadow.ImageTransparency = 0.4
        DialogShadow.ScaleType = Enum.ScaleType.Slice
        DialogShadow.SliceCenter = Rect.new(23, 23, 277, 277)
        DialogShadow.ZIndex = 100
        DialogShadow.Parent = DialogFrame
        
        -- Icon
        local DialogIcon = Instance.new("TextLabel")
        DialogIcon.Size = UDim2.new(0, 50, 0, 50)
        DialogIcon.Position = UDim2.new(0.5, -25, 0, 20)
        DialogIcon.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
        DialogIcon.BorderSizePixel = 0
        DialogIcon.Text = "!"
        DialogIcon.TextColor3 = Colors.Background
        DialogIcon.TextSize = 28
        DialogIcon.Font = Enum.Font.GothamBold
        DialogIcon.ZIndex = 102
        DialogIcon.Parent = DialogFrame
        
        local IconCorner = Instance.new("UICorner")
        IconCorner.CornerRadius = UDim.new(1, 0)
        IconCorner.Parent = DialogIcon
        
        -- Title
        local DialogTitle = Instance.new("TextLabel")
        DialogTitle.Size = UDim2.new(1, -30, 0, 25)
        DialogTitle.Position = UDim2.new(0, 15, 0, 80)
        DialogTitle.BackgroundTransparency = 1
        DialogTitle.Text = title
        DialogTitle.TextColor3 = Colors.Text
        DialogTitle.TextSize = 18
        DialogTitle.Font = Enum.Font.GothamBold
        DialogTitle.ZIndex = 102
        DialogTitle.Parent = DialogFrame
        
        -- Content
        local DialogContent = Instance.new("TextLabel")
        DialogContent.Size = UDim2.new(1, -30, 0, 40)
        DialogContent.Position = UDim2.new(0, 15, 0, 110)
        DialogContent.BackgroundTransparency = 1
        DialogContent.Text = content
        DialogContent.TextColor3 = Colors.TextDim
        DialogContent.TextSize = 14
        DialogContent.Font = Enum.Font.Gotham
        DialogContent.TextWrapped = true
        DialogContent.ZIndex = 102
        DialogContent.Parent = DialogFrame
        
        -- Cancel Button
        local CancelBtn = Instance.new("TextButton")
        CancelBtn.Size = UDim2.new(0.45, -10, 0, 38)
        CancelBtn.Position = UDim2.new(0, 15, 0, 165)
        CancelBtn.BackgroundColor3 = Colors.Tertiary
        CancelBtn.BorderSizePixel = 0
        CancelBtn.Text = cancelText
        CancelBtn.TextColor3 = Colors.Text
        CancelBtn.TextSize = 14
        CancelBtn.Font = Enum.Font.GothamMedium
        CancelBtn.ZIndex = 102
        CancelBtn.Parent = DialogFrame
        
        local CancelCorner = Instance.new("UICorner")
        CancelCorner.CornerRadius = UDim.new(0, 8)
        CancelCorner.Parent = CancelBtn
        
        -- Confirm Button
        local ConfirmBtn = Instance.new("TextButton")
        ConfirmBtn.Size = UDim2.new(0.45, -10, 0, 38)
        ConfirmBtn.Position = UDim2.new(0.55, 5, 0, 165)
        ConfirmBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        ConfirmBtn.BorderSizePixel = 0
        ConfirmBtn.Text = confirmText
        ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ConfirmBtn.TextSize = 14
        ConfirmBtn.Font = Enum.Font.GothamMedium
        ConfirmBtn.ZIndex = 102
        ConfirmBtn.Parent = DialogFrame
        
        local ConfirmCorner = Instance.new("UICorner")
        ConfirmCorner.CornerRadius = UDim.new(0, 8)
        ConfirmCorner.Parent = ConfirmBtn
        
        -- Animate in
        Tween(DialogFrame, {Size = UDim2.new(0, 300, 0, 220)}, 0.3, Enum.EasingStyle.Back)
        
        -- Button Hovers
        CancelBtn.MouseEnter:Connect(function()
            Tween(CancelBtn, {BackgroundColor3 = Colors.Border}, 0.2)
        end)
        CancelBtn.MouseLeave:Connect(function()
            Tween(CancelBtn, {BackgroundColor3 = Colors.Tertiary}, 0.2)
        end)
        
        ConfirmBtn.MouseEnter:Connect(function()
            Tween(ConfirmBtn, {BackgroundColor3 = Color3.fromRGB(240, 70, 70)}, 0.2)
        end)
        ConfirmBtn.MouseLeave:Connect(function()
            Tween(ConfirmBtn, {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}, 0.2)
        end)
        
        -- Close Dialog Function
        local function closeDialog(result)
            Tween(DialogFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Tween(DialogOverlay, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.2)
            DialogOverlay:Destroy()
            DialogFrame:Destroy()
            SafeCallback(callback, result)
        end
        
        CancelBtn.MouseButton1Click:Connect(function()
            closeDialog(false)
        end)
        
        ConfirmBtn.MouseButton1Click:Connect(function()
            closeDialog(true)
        end)
        
        -- Click overlay to cancel
        DialogOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                closeDialog(false)
            end
        end)
    end
    
    -- Store confirm function in Window
    Window.Confirm = ShowConfirmDialog
    
    CloseButton.MouseButton1Click:Connect(function()
        ShowConfirmDialog({
            Title = "Close Window?",
            Content = "Are you sure you want to close this window?",
            ConfirmText = "Close",
            CancelText = "Cancel",
            Callback = function(confirmed)
                if confirmed then
                    Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    task.wait(0.3)
                    ScreenGui:Destroy()
                end
            end
        })
    end)
    
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}, 0.2)
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
    end)
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 150, 1, -55)
    TabContainer.Position = UDim2.new(0, 10, 0, 50)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabContainer
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -175, 1, -60)
    ContentContainer.Position = UDim2.new(0, 165, 0, 50)
    ContentContainer.BackgroundColor3 = Colors.Secondary
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 10)
    ContentCorner.Parent = ContentContainer
    
    -- Make Draggable
    MakeDraggable(MainFrame, TopBar)
    
    -- Intro Animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(MainFrame, {Size = windowSize}, 0.4, Enum.EasingStyle.Back)
    
    -- Tab Functions
    function Window:CreateTab(tabName, icon)
        local Tab = {
            Name = tabName,
            Elements = {}
        }
        
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.BackgroundColor3 = Colors.Tertiary
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabButton
        
        local TabLabel = Instance.new("TextLabel")
        TabLabel.Size = UDim2.new(1, -10, 1, 0)
        TabLabel.Position = UDim2.new(0, 10, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = tabName
        TabLabel.TextColor3 = Colors.TextDim
        TabLabel.TextSize = 14
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "_Content"
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Colors.Accent
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 8)
        ContentList.Parent = TabContent
        
        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 10)
        end)
        
        -- Tab Button Click
        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundColor3 = Colors.Tertiary
                tab.Label.TextColor3 = Colors.TextDim
                tab.Content.Visible = false
            end
            
            TabButton.BackgroundColor3 = Colors.Accent
            TabLabel.TextColor3 = Colors.Text
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Colors.Border}, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
            end
        end)
        
        -- Store Tab References
        Tab.Button = TabButton
        Tab.Label = TabLabel
        Tab.Content = TabContent
        
        table.insert(Window.Tabs, Tab)
        
        -- Select First Tab
        if #Window.Tabs == 1 then
            TabButton.BackgroundColor3 = Colors.Accent
            TabLabel.TextColor3 = Colors.Text
            TabContent.Visible = true
            Window.CurrentTab = Tab
        end
        
        -- Element Functions
        function Tab:CreateButton(config)
            config = config or {}
            local buttonText = config.Name or "Button"
            local callback = config.Callback or function() end
            
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 40)
            ButtonFrame.BackgroundColor3 = Colors.Tertiary
            ButtonFrame.BorderSizePixel = 0
            ButtonFrame.Parent = TabContent
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 8)
            ButtonCorner.Parent = ButtonFrame
            
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 1, 0)
            Button.BackgroundTransparency = 1
            Button.Text = buttonText
            Button.TextColor3 = Colors.Text
            Button.TextSize = 14
            Button.Font = Enum.Font.Gotham
            Button.Parent = ButtonFrame
            
            Button.MouseButton1Click:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Colors.Accent}, 0.1)
                wait(0.1)
                Tween(ButtonFrame, {BackgroundColor3 = Colors.Tertiary}, 0.1)
                SafeCallback(callback)
            end)
            
            Button.MouseEnter:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Colors.Border}, 0.2)
            end)
            
            Button.MouseLeave:Connect(function()
                Tween(ButtonFrame, {BackgroundColor3 = Colors.Tertiary}, 0.2)
            end)
            
            return {
                SetVisible = function(visible)
                    ButtonFrame.Visible = visible
                end,
                Instance = ButtonFrame
            }
        end
        
        function Tab:CreateToggle(config)
            config = config or {}
            local toggleText = config.Name or "Toggle"
            local default = config.Default or false
            local callback = config.Callback or function() end
            local flag = config.Flag
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = Colors.Tertiary
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = TabContent
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 8)
            ToggleCorner.Parent = ToggleFrame
            
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = toggleText
            ToggleLabel.TextColor3 = Colors.Text
            ToggleLabel.TextSize = 14
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame
            
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(0, 45, 0, 24)
            ToggleButton.Position = UDim2.new(1, -55, 0.5, -12)
            ToggleButton.BackgroundColor3 = default and Colors.Accent or Colors.Border
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Text = ""
            ToggleButton.AutoButtonColor = false
            ToggleButton.Parent = ToggleFrame
            
            local ToggleButtonCorner = Instance.new("UICorner")
            ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
            ToggleButtonCorner.Parent = ToggleButton
            
            local ToggleCircle = Instance.new("Frame")
            ToggleCircle.Size = UDim2.new(0, 18, 0, 18)
            ToggleCircle.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            ToggleCircle.BackgroundColor3 = Colors.Text
            ToggleCircle.BorderSizePixel = 0
            ToggleCircle.Parent = ToggleButton
            
            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = ToggleCircle
            
            local toggled = default
            
            ToggleButton.MouseButton1Click:Connect(function()
                toggled = not toggled
                
                Tween(ToggleButton, {
                    BackgroundColor3 = toggled and Colors.Accent or Colors.Border
                }, 0.2)
                
                Tween(ToggleCircle, {
                    Position = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                }, 0.2)
                
                SafeCallback(callback, toggled)
                
                -- Update config
                if flag and ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = toggled
                end
            end)
            
            -- Tambahkan Touch support
            ToggleButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    toggled = not toggled
                    
                    Tween(ToggleButton, {
                        BackgroundColor3 = toggled and Colors.Accent or Colors.Border
                    }, 0.2)
                    
                    Tween(ToggleCircle, {
                        Position = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    }, 0.2)
                    
                    SafeCallback(callback, toggled)
                    
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = toggled
                    end
                end
            end)
            
            ToggleFrame.MouseEnter:Connect(function()
                Tween(ToggleFrame, {BackgroundColor3 = Colors.Border}, 0.2)
            end)
            
            ToggleFrame.MouseLeave:Connect(function()
                Tween(ToggleFrame, {BackgroundColor3 = Colors.Tertiary}, 0.2)
            end)
            
            local toggleObj = {
                SetValue = function(value)
                    toggled = value
                    ToggleButton.BackgroundColor3 = toggled and Colors.Accent or Colors.Border
                    ToggleCircle.Position = toggled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    SafeCallback(callback, toggled)
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = toggled
                    end
                end,
                SetVisible = function(visible)
                    ToggleFrame.Visible = visible
                end,
                Instance = ToggleFrame
            }
            
            -- Register flag
            if flag and ConfigSystem and ConfigSystem.Flags then
                ConfigSystem.Flags[flag] = {
                    Type = "Toggle",
                    Set = function(value)
                        if toggleObj and toggleObj.SetValue then
                            toggleObj.SetValue(value)
                        end
                    end,
                    Get = function()
                        return toggled
                    end
                }
                if ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = toggled
                end
            end
            
            return toggleObj
        end
        
        function Tab:CreateSlider(config)
            config = config or {}
            local sliderText = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local increment = config.Increment or 1
            local callback = config.Callback or function() end
            local flag = config.Flag
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Colors.Tertiary
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = TabContent
            
            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 8)
            SliderCorner.Parent = SliderFrame
            
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -20, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = sliderText
            SliderLabel.TextColor3 = Colors.Text
            SliderLabel.TextSize = 14
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame
            
            local SliderValue = Instance.new("TextLabel")
            SliderValue.Size = UDim2.new(0, 50, 0, 20)
            SliderValue.Position = UDim2.new(1, -60, 0, 5)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Text = tostring(default)
            SliderValue.TextColor3 = Colors.Accent
            SliderValue.TextSize = 14
            SliderValue.Font = Enum.Font.GothamBold
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right
            SliderValue.Parent = SliderFrame
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 1, -13)
            SliderBar.BackgroundColor3 = Colors.Border
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            
            local SliderBarCorner = Instance.new("UICorner")
            SliderBarCorner.CornerRadius = UDim.new(1, 0)
            SliderBarCorner.Parent = SliderBar
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Colors.Accent
            SliderFill.BorderSizePixel = 0
            SliderFill.Parent = SliderBar
            
            local SliderFillCorner = Instance.new("UICorner")
            SliderFillCorner.CornerRadius = UDim.new(1, 0)
            SliderFillCorner.Parent = SliderFill
            
            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.Position = UDim2.new(0, 0, 0, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBar
            
            local dragging = false
            
            SliderButton.MouseButton1Down:Connect(function()
                dragging = true
            end)

            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            SliderButton.MouseButton1Click:Connect(function()
                local mousePos = UserInputService:GetMouseLocation().X
                local barPos = SliderBar.AbsolutePosition.X
                local barSize = SliderBar.AbsoluteSize.X
                local percentage = math.clamp((mousePos - barPos) / barSize, 0, 1)
                local value = math.floor(min + (max - min) * percentage / increment + 0.5) * increment
                
                SliderValue.Text = tostring(value)
                Tween(SliderFill, {Size = UDim2.new(percentage, 0, 1, 0)}, 0.1)
                SafeCallback(callback, value)
                
                if flag and ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = value
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mousePos = input.Position.X
                    local barPos = SliderBar.AbsolutePosition.X
                    local barSize = SliderBar.AbsoluteSize.X
                    local percentage = math.clamp((mousePos - barPos) / barSize, 0, 1)
                    local value = math.floor(min + (max - min) * percentage / increment + 0.5) * increment
                    
                    SliderValue.Text = tostring(value)
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    SafeCallback(callback, value)
                    
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = value
                    end
                end
            end)
            
            local sliderObj = {
                SetValue = function(value)
                    value = math.clamp(value, min, max)
                    local percentage = (value - min) / (max - min)
                    SliderValue.Text = tostring(value)
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    SafeCallback(callback, value)
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = value
                    end
                end,
                SetVisible = function(visible)
                    SliderFrame.Visible = visible
                end,
                Instance = SliderFrame
            }
            
            -- Register flag
            if flag and ConfigSystem and ConfigSystem.Flags then
                ConfigSystem.Flags[flag] = {
                    Type = "Slider",
                    Set = function(value)
                        if sliderObj and sliderObj.SetValue then
                            sliderObj.SetValue(value)
                        end
                    end,
                    Get = function()
                        return tonumber(SliderValue.Text) or default
                    end
                }
                if ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = default
                end
            end
            
            return sliderObj
        end
        
        function Tab:CreateTextbox(config)
            config = config or {}
            local textboxText = config.Name or "Textbox"
            local placeholder = config.Placeholder or "Enter text..."
            local callback = config.Callback or function() end
            
            local TextboxFrame = Instance.new("Frame")
            TextboxFrame.Size = UDim2.new(1, 0, 0, 70)
            TextboxFrame.BackgroundColor3 = Colors.Tertiary
            TextboxFrame.BorderSizePixel = 0
            TextboxFrame.Parent = TabContent
            
            local TextboxCorner = Instance.new("UICorner")
            TextboxCorner.CornerRadius = UDim.new(0, 8)
            TextboxCorner.Parent = TextboxFrame
            
            local TextboxLabel = Instance.new("TextLabel")
            TextboxLabel.Size = UDim2.new(1, -20, 0, 20)
            TextboxLabel.Position = UDim2.new(0, 10, 0, 5)
            TextboxLabel.BackgroundTransparency = 1
            TextboxLabel.Text = textboxText
            TextboxLabel.TextColor3 = Colors.Text
            TextboxLabel.TextSize = 14
            TextboxLabel.Font = Enum.Font.Gotham
            TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextboxLabel.Parent = TextboxFrame
            
            local Textbox = Instance.new("TextBox")
            Textbox.Size = UDim2.new(1, -20, 0, 30)
            Textbox.Position = UDim2.new(0, 10, 0, 30)
            Textbox.BackgroundColor3 = Colors.Background
            Textbox.BorderSizePixel = 0
            Textbox.PlaceholderText = placeholder
            Textbox.PlaceholderColor3 = Colors.TextDim
            Textbox.Text = ""
            Textbox.TextColor3 = Colors.Text
            Textbox.TextSize = 13
            Textbox.Font = Enum.Font.Gotham
            Textbox.ClearTextOnFocus = false
            Textbox.Parent = TextboxFrame
            
            local TextboxInnerCorner = Instance.new("UICorner")
            TextboxInnerCorner.CornerRadius = UDim.new(0, 6)
            TextboxInnerCorner.Parent = Textbox
            
            local TextboxPadding = Instance.new("UIPadding")
            TextboxPadding.PaddingLeft = UDim.new(0, 10)
            TextboxPadding.PaddingRight = UDim.new(0, 10)
            TextboxPadding.Parent = Textbox
            
            Textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    SafeCallback(callback, Textbox.Text)
                end
            end)
            
            return {
                SetValue = function(text)
                    Textbox.Text = text
                end,
                GetValue = function()
                    return Textbox.Text
                end,
                SetVisible = function(visible)
                    TextboxFrame.Visible = visible
                end,
                Instance = TextboxFrame
            }
        end
        
        function Tab:CreateKeybind(config)
            config = config or {}
            local keybindText = config.Name or "Keybind"
            local default = config.Default or Enum.KeyCode.Unknown
            local callback = config.Callback or function() end
            local flag = config.Flag
            
            local KeybindFrame = Instance.new("Frame")
            KeybindFrame.Size = UDim2.new(1, 0, 0, 40)
            KeybindFrame.BackgroundColor3 = Colors.Tertiary
            KeybindFrame.BorderSizePixel = 0
            KeybindFrame.Parent = TabContent
            
            local KeybindCorner = Instance.new("UICorner")
            KeybindCorner.CornerRadius = UDim.new(0, 8)
            KeybindCorner.Parent = KeybindFrame
            
            local KeybindLabel = Instance.new("TextLabel")
            KeybindLabel.Size = UDim2.new(1, -100, 1, 0)
            KeybindLabel.Position = UDim2.new(0, 15, 0, 0)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.Text = keybindText
            KeybindLabel.TextColor3 = Colors.Text
            KeybindLabel.TextSize = 14
            KeybindLabel.Font = Enum.Font.Gotham
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            KeybindLabel.Parent = KeybindFrame
            
            local KeybindButton = Instance.new("TextButton")
            KeybindButton.Size = UDim2.new(0, 80, 0, 28)
            KeybindButton.Position = UDim2.new(1, -90, 0.5, -14)
            KeybindButton.BackgroundColor3 = Colors.Background
            KeybindButton.BorderSizePixel = 0
            KeybindButton.Text = default ~= Enum.KeyCode.Unknown and default.Name or "None"
            KeybindButton.TextColor3 = Colors.Text
            KeybindButton.TextSize = 13
            KeybindButton.Font = Enum.Font.Gotham
            KeybindButton.Parent = KeybindFrame
            
            local KeybindButtonCorner = Instance.new("UICorner")
            KeybindButtonCorner.CornerRadius = UDim.new(0, 6)
            KeybindButtonCorner.Parent = KeybindButton
            
            local listening = false
            local currentKey = default
            
            KeybindButton.MouseButton1Click:Connect(function()
                listening = true
                KeybindButton.Text = "..."
                Tween(KeybindButton, {BackgroundColor3 = Colors.Accent}, 0.2)
            end)
            
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if listening then
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        listening = false
                        currentKey = input.KeyCode
                        KeybindButton.Text = currentKey.Name
                        Tween(KeybindButton, {BackgroundColor3 = Colors.Background}, 0.2)
                        SafeCallback(callback, currentKey)
                        
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = currentKey.Name
                        end
                    end
                else
                    if input.KeyCode == currentKey then
                        SafeCallback(callback, currentKey)
                    end
                end
            end)
            
            KeybindFrame.MouseEnter:Connect(function()
                Tween(KeybindFrame, {BackgroundColor3 = Colors.Border}, 0.2)
            end)
            
            KeybindFrame.MouseLeave:Connect(function()
                Tween(KeybindFrame, {BackgroundColor3 = Colors.Tertiary}, 0.2)
            end)
            
            local keybindObj = {
                SetValue = function(keyCode)
                    currentKey = keyCode
                    KeybindButton.Text = keyCode ~= Enum.KeyCode.Unknown and keyCode.Name or "None"
                end,
                SetVisible = function(visible)
                    KeybindFrame.Visible = visible
                end,
                Instance = KeybindFrame
            }
            
            -- Register flag
            if flag and ConfigSystem and ConfigSystem.Flags then
                ConfigSystem.Flags[flag] = {
                    Type = "Keybind",
                    Set = function(keyName)
                        local keyCode = Enum.KeyCode[keyName]
                        if keyCode then
                            keybindObj.SetValue(keyCode)
                        end
                    end,
                    Get = function()
                        return currentKey.Name
                    end
                }
            end
            
            return keybindObj
        end 

        function Tab:CreateColorPicker(config)
            config = config or {}
            local pickerText = config.Name or "Color Picker"
            local default = config.Default or Color3.fromRGB(255, 255, 255)
            local callback = config.Callback or function() end
            
            local ColorFrame = Instance.new("Frame")
            ColorFrame.Size = UDim2.new(1, 0, 0, 40)
            ColorFrame.BackgroundColor3 = Colors.Tertiary
            ColorFrame.BorderSizePixel = 0
            ColorFrame.ClipsDescendants = true
            ColorFrame.Parent = TabContent
            
            local ColorCorner = Instance.new("UICorner")
            ColorCorner.CornerRadius = UDim.new(0, 8)
            ColorCorner.Parent = ColorFrame
            
            local ColorLabel = Instance.new("TextLabel")
            ColorLabel.Size = UDim2.new(1, -60, 1, 0)
            ColorLabel.Position = UDim2.new(0, 15, 0, 0)
            ColorLabel.BackgroundTransparency = 1
            ColorLabel.Text = pickerText
            ColorLabel.TextColor3 = Colors.Text
            ColorLabel.TextSize = 14
            ColorLabel.Font = Enum.Font.Gotham
            ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
            ColorLabel.Parent = ColorFrame
            
            local ColorPreview = Instance.new("TextButton")
            ColorPreview.Size = UDim2.new(0, 35, 0, 25)
            ColorPreview.Position = UDim2.new(1, -50, 0.5, -12.5)
            ColorPreview.BackgroundColor3 = default
            ColorPreview.BorderSizePixel = 0
            ColorPreview.Text = ""
            ColorPreview.Parent = ColorFrame
            
            local PreviewCorner = Instance.new("UICorner")
            PreviewCorner.CornerRadius = UDim.new(0, 6)
            PreviewCorner.Parent = ColorPreview
            
            local PreviewStroke = Instance.new("UIStroke")
            PreviewStroke.Color = Colors.Border
            PreviewStroke.Thickness = 1
            PreviewStroke.Parent = ColorPreview
            
            -- Color Picker Panel
            local PickerPanel = Instance.new("Frame")
            PickerPanel.Size = UDim2.new(1, -20, 0, 120)
            PickerPanel.Position = UDim2.new(0, 10, 0, 45)
            PickerPanel.BackgroundColor3 = Colors.Background
            PickerPanel.BorderSizePixel = 0
            PickerPanel.Visible = false
            PickerPanel.Parent = ColorFrame
            
            local PanelCorner = Instance.new("UICorner")
            PanelCorner.CornerRadius = UDim.new(0, 6)
            PanelCorner.Parent = PickerPanel
            
            -- RGB Sliders
            local currentColor = {R = default.R * 255, G = default.G * 255, B = default.B * 255}
            local isOpen = false
            
            local function createColorSlider(name, yPos, defaultVal)
                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Size = UDim2.new(0, 20, 0, 25)
                SliderLabel.Position = UDim2.new(0, 10, 0, yPos)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = name
                SliderLabel.TextColor3 = Colors.Text
                SliderLabel.TextSize = 12
                SliderLabel.Font = Enum.Font.GothamBold
                SliderLabel.Parent = PickerPanel
                
                local SliderBar = Instance.new("Frame")
                SliderBar.Size = UDim2.new(1, -80, 0, 6)
                SliderBar.Position = UDim2.new(0, 35, 0, yPos + 10)
                SliderBar.BackgroundColor3 = Colors.Border
                SliderBar.Parent = PickerPanel
                
                local SliderBarCorner = Instance.new("UICorner")
                SliderBarCorner.CornerRadius = UDim.new(1, 0)
                SliderBarCorner.Parent = SliderBar
                
                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(defaultVal / 255, 0, 1, 0)
                SliderFill.BackgroundColor3 = name == "R" and Color3.fromRGB(255, 100, 100) or (name == "G" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 255))
                SliderFill.Parent = SliderBar
                
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = SliderFill
                
                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(0, 35, 0, 25)
                ValueLabel.Position = UDim2.new(1, -40, 0, yPos)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(math.floor(defaultVal))
                ValueLabel.TextColor3 = Colors.TextDim
                ValueLabel.TextSize = 12
                ValueLabel.Font = Enum.Font.Gotham
                ValueLabel.Parent = PickerPanel
                
                local SliderButton = Instance.new("TextButton")
                SliderButton.Size = UDim2.new(1, 0, 1, 10)
                SliderButton.Position = UDim2.new(0, 0, 0, -5)
                SliderButton.BackgroundTransparency = 1
                SliderButton.Text = ""
                SliderButton.Parent = SliderBar
                
                local dragging = false
                
                SliderButton.MouseButton1Down:Connect(function()
                    dragging = true
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                local function updateSlider(input)
                    local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor(percentage * 255)
                    
                    currentColor[name] = value
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    
                    local newColor = Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B)
                    ColorPreview.BackgroundColor3 = newColor
                    SafeCallback(callback, newColor)
                end
                
                SliderButton.MouseButton1Click:Connect(function()
                    local mouse = UserInputService:GetMouseLocation()
                    updateSlider({Position = Vector2.new(mouse.X, mouse.Y)})
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
            end
            
            createColorSlider("R", 10, currentColor.R)
            createColorSlider("G", 45, currentColor.G)
            createColorSlider("B", 80, currentColor.B)
            
            ColorPreview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    PickerPanel.Visible = true
                    Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, 175)}, 0.3)
                else
                    Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    task.wait(0.3)
                    PickerPanel.Visible = false
                end
            end)
            
            return {
                SetValue = function(color)
                    currentColor = {R = color.R * 255, G = color.G * 255, B = color.B * 255}
                    ColorPreview.BackgroundColor3 = color
                    SafeCallback(callback, color)
                end,
                SetVisible = function(visible)
                    ColorFrame.Visible = visible
                end,
                Instance = ColorFrame
            }
        end
        
        -- ═══════════════════════════════════════════
        -- MODERN DROPDOWN (Unified: Single, Multi, Search)
        -- ═══════════════════════════════════════════
        function Tab:CreateDropdown(config)
            config = config or {}
            local dropdownText = config.Name or "Dropdown"
            local options = config.Options or {"Option 1", "Option 2"}
            local default = config.Default
            local callback = config.Callback or function() end
            local flag = config.Flag
            local multiSelect = config.MultiSelect or false
            local searchEnabled = config.Search or false
            local maxVisible = config.MaxVisible or 6
            local placeholder = config.Placeholder or "Select option..."
            
            -- State management
            local DropdownState = {
                IsOpen = false,
                Selected = multiSelect and {} or (default or options[1]),
                FilteredOptions = options,
                SearchText = ""
            }
            
            -- Initialize multi-select default
            if multiSelect and default and type(default) == "table" then
                DropdownState.Selected = default
            elseif multiSelect then
                DropdownState.Selected = {}
            end
            
            -- Container Frame (visible in tab)
            local Container = Instance.new("Frame")
            Container.Name = "Dropdown_" .. dropdownText
            Container.Size = UDim2.new(1, 0, 0, 40)
            Container.BackgroundTransparency = 1
            Container.Parent = TabContent
            
            -- Dropdown Button
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Name = "Button"
            DropdownButton.Size = UDim2.new(1, 0, 1, 0)
            DropdownButton.BackgroundColor3 = Colors.Tertiary
            DropdownButton.BorderSizePixel = 0
            DropdownButton.Text = ""
            DropdownButton.AutoButtonColor = false
            DropdownButton.Parent = Container
            
            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 8)
            ButtonCorner.Parent = DropdownButton
            
            local ButtonStroke = Instance.new("UIStroke")
            ButtonStroke.Color = Colors.Border
            ButtonStroke.Thickness = 1
            ButtonStroke.Transparency = 0.5
            ButtonStroke.Parent = DropdownButton
            
            -- Button Content
            local ButtonContent = Instance.new("Frame")
            ButtonContent.Name = "Content"
            ButtonContent.Size = UDim2.new(1, -24, 1, 0)
            ButtonContent.Position = UDim2.new(0, 12, 0, 0)
            ButtonContent.BackgroundTransparency = 1
            ButtonContent.Parent = DropdownButton
            
            -- Dropdown Label
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Name = "Label"
            DropdownLabel.Size = UDim2.new(0, 120, 1, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = dropdownText
            DropdownLabel.TextColor3 = Colors.Text
            DropdownLabel.TextSize = 14
            DropdownLabel.Font = Enum.Font.GothamMedium
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = ButtonContent
            
            -- Selected Text
            local SelectedText = Instance.new("TextLabel")
            SelectedText.Name = "SelectedText"
            SelectedText.Size = UDim2.new(1, -150, 1, 0)
            SelectedText.Position = UDim2.new(0, 130, 0, 0)
            SelectedText.BackgroundTransparency = 1
            SelectedText.Text = placeholder
            SelectedText.TextColor3 = Colors.TextDim
            SelectedText.TextSize = 13
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.TextXAlignment = Enum.TextXAlignment.Right
            SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedText.Parent = ButtonContent
            
            -- Arrow
            local Arrow = Instance.new("TextLabel")
            Arrow.Name = "Arrow"
            Arrow.Size = UDim2.new(0, 20, 1, 0)
            Arrow.Position = UDim2.new(1, -8, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Colors.TextDim
            Arrow.TextSize = 12
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Parent = ButtonContent
            
            -- Create Panel (parented to ScreenGui for z-index)
            local Panel = Instance.new("Frame")
            Panel.Name = "DropdownPanel_" .. dropdownText
            Panel.Size = UDim2.fromOffset(0, 0)
            Panel.Position = UDim2.fromOffset(0, 0)
            Panel.BackgroundColor3 = Colors.Tertiary
            Panel.BorderSizePixel = 0
            Panel.ClipsDescendants = true
            Panel.Visible = false
            Panel.ZIndex = 100
            Panel.Parent = ScreenGui
            
            local PanelCorner = Instance.new("UICorner")
            PanelCorner.CornerRadius = UDim.new(0, 8)
            PanelCorner.Parent = Panel
            
            local PanelStroke = Instance.new("UIStroke")
            PanelStroke.Color = Colors.Border
            PanelStroke.Thickness = 1
            PanelStroke.Transparency = 0.3
            PanelStroke.Parent = Panel
            
            -- Panel Shadow
            local PanelShadow = Instance.new("ImageLabel")
            PanelShadow.Name = "Shadow"
            PanelShadow.Size = UDim2.new(1, 30, 1, 30)
            PanelShadow.Position = UDim2.new(0, -15, 0, -15)
            PanelShadow.BackgroundTransparency = 1
            PanelShadow.Image = "rbxassetid://5554236805"
            PanelShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
            PanelShadow.ImageTransparency = 0.6
            PanelShadow.ScaleType = Enum.ScaleType.Slice
            PanelShadow.SliceCenter = Rect.new(23, 23, 277, 277)
            PanelShadow.ZIndex = 99
            PanelShadow.Parent = Panel
            
            -- Close Button
            local CloseButtonHeight = 32
            local OptionsOffset = CloseButtonHeight + 8
            
            local CloseButtonFrame = Instance.new("Frame")
            CloseButtonFrame.Name = "CloseButton"
            CloseButtonFrame.Size = UDim2.new(1, -16, 0, 28)
            CloseButtonFrame.Position = UDim2.new(0, 8, 0, 4)
            CloseButtonFrame.BackgroundColor3 = Colors.Border
            CloseButtonFrame.BorderSizePixel = 0
            CloseButtonFrame.ZIndex = 101
            CloseButtonFrame.Parent = Panel
            
            local CloseCorner = Instance.new("UICorner")
            CloseCorner.CornerRadius = UDim.new(0, 6)
            CloseCorner.Parent = CloseButtonFrame
            
            local CloseButton = Instance.new("TextButton")
            CloseButton.Name = "Close"
            CloseButton.Size = UDim2.new(1, 0, 1, 0)
            CloseButton.BackgroundTransparency = 1
            CloseButton.Text = ""
            CloseButton.ZIndex = 102
            CloseButton.Parent = CloseButtonFrame
            
            local closeIcon = multiSelect and "✓" or "×"
            local closeText = multiSelect and "Done" or "Close"
            local closeColor = multiSelect and Colors.Accent or Colors.TextDim
            
            local CloseIcon = Instance.new("TextLabel")
            CloseIcon.Size = UDim2.new(0, 20, 1, 0)
            CloseIcon.Position = UDim2.new(0, 8, 0, 0)
            CloseIcon.BackgroundTransparency = 1
            CloseIcon.Text = closeIcon
            CloseIcon.TextColor3 = closeColor
            CloseIcon.TextSize = 12
            CloseIcon.Font = Enum.Font.GothamBold
            CloseIcon.ZIndex = 102
            CloseIcon.Parent = CloseButtonFrame
            
            local CloseText = Instance.new("TextLabel")
            CloseText.Size = UDim2.new(1, -28, 1, 0)
            CloseText.Position = UDim2.new(0, 28, 0, 0)
            CloseText.BackgroundTransparency = 1
            CloseText.Text = closeText
            CloseText.TextColor3 = closeColor
            CloseText.TextSize = 12
            CloseText.Font = Enum.Font.GothamMedium
            CloseText.TextXAlignment = Enum.TextXAlignment.Left
            CloseText.ZIndex = 102
            CloseText.Parent = CloseButtonFrame
            
            -- Search Box (if enabled)
            local SearchBox = nil
            if searchEnabled then
                SearchBox = Instance.new("TextBox")
                SearchBox.Name = "Search"
                SearchBox.Size = UDim2.new(1, -16, 0, 32)
                SearchBox.Position = UDim2.new(0, 8, 0, OptionsOffset)
                SearchBox.BackgroundColor3 = Colors.Background
                SearchBox.BorderSizePixel = 0
                SearchBox.Text = ""
                SearchBox.PlaceholderText = "🔍 Search..."
                SearchBox.PlaceholderColor3 = Colors.TextDim
                SearchBox.TextColor3 = Colors.Text
                SearchBox.TextSize = 13
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.TextXAlignment = Enum.TextXAlignment.Left
                SearchBox.ClearTextOnFocus = false
                SearchBox.ZIndex = 101
                SearchBox.Parent = Panel
                
                local SearchCorner = Instance.new("UICorner")
                SearchCorner.CornerRadius = UDim.new(0, 6)
                SearchCorner.Parent = SearchBox
                
                local SearchPadding = Instance.new("UIPadding")
                SearchPadding.PaddingLeft = UDim.new(0, 10)
                SearchPadding.PaddingRight = UDim.new(0, 10)
                SearchPadding.Parent = SearchBox
                
                OptionsOffset = OptionsOffset + 40
            end
            
            -- Options Container
            local OptionsContainer = Instance.new("ScrollingFrame")
            OptionsContainer.Name = "Options"
            OptionsContainer.Size = UDim2.new(1, 0, 1, -OptionsOffset - 8)
            OptionsContainer.Position = UDim2.new(0, 0, 0, OptionsOffset)
            OptionsContainer.BackgroundTransparency = 1
            OptionsContainer.BorderSizePixel = 0
            OptionsContainer.ScrollBarThickness = 4
            OptionsContainer.ScrollBarImageColor3 = Colors.Accent
            OptionsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
            OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptionsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
            OptionsContainer.ZIndex = 101
            OptionsContainer.Parent = Panel
            
            local OptionsLayout = Instance.new("UIListLayout")
            OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsLayout.Padding = UDim.new(0, 2)
            OptionsLayout.Parent = OptionsContainer
            
            local OptionsPadding = Instance.new("UIPadding")
            OptionsPadding.PaddingLeft = UDim.new(0, 8)
            OptionsPadding.PaddingRight = UDim.new(0, 8)
            OptionsPadding.Parent = OptionsContainer
            
            local OptionItems = {}
            local Connections = {}
            
            -- Forward declarations
            local RefreshOptions, UpdateSelectedDisplay, CloseDropdown, OpenDropdown
            
            -- Update panel position
            local function UpdatePanelPosition()
                if not DropdownButton or not DropdownButton.Parent then return end
                
                local buttonPos = DropdownButton.AbsolutePosition
                local buttonSize = DropdownButton.AbsoluteSize
                
                Panel.Position = UDim2.fromOffset(
                    buttonPos.X,
                    buttonPos.Y + buttonSize.Y + 4
                )
                
                if DropdownState.IsOpen then
                    Panel.Size = UDim2.fromOffset(buttonSize.X, Panel.Size.Y.Offset)
                end
            end
            
            -- Create option item
            local function CreateOptionItem(text, index)
                local isSelected = false
                if multiSelect then
                    isSelected = table.find(DropdownState.Selected, text) ~= nil
                else
                    isSelected = DropdownState.Selected == text
                end
                
                local OptionItem = Instance.new("TextButton")
                OptionItem.Name = "Option_" .. index
                OptionItem.Size = UDim2.new(1, 0, 0, 30)
                OptionItem.BackgroundColor3 = isSelected and Colors.Accent or Colors.Background
                OptionItem.BackgroundTransparency = isSelected and 0.1 or 0.5
                OptionItem.BorderSizePixel = 0
                OptionItem.Text = ""
                OptionItem.AutoButtonColor = false
                OptionItem.LayoutOrder = index
                OptionItem.ZIndex = 102
                OptionItem.Parent = OptionsContainer
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 6)
                OptionCorner.Parent = OptionItem
                
                local OptionText = Instance.new("TextLabel")
                OptionText.Name = "Text"
                OptionText.Size = UDim2.new(1, multiSelect and -32 or -16, 1, 0)
                OptionText.Position = UDim2.new(0, 12, 0, 0)
                OptionText.BackgroundTransparency = 1
                OptionText.Text = text
                OptionText.TextColor3 = isSelected and Colors.Text or Colors.TextDim
                OptionText.TextSize = 13
                OptionText.Font = isSelected and Enum.Font.GothamMedium or Enum.Font.Gotham
                OptionText.TextXAlignment = Enum.TextXAlignment.Left
                OptionText.TextTruncate = Enum.TextTruncate.AtEnd
                OptionText.ZIndex = 103
                OptionText.Parent = OptionItem
                
                -- Checkbox for multi-select
                local Checkbox = nil
                if multiSelect then
                    Checkbox = Instance.new("Frame")
                    Checkbox.Name = "Checkbox"
                    Checkbox.Size = UDim2.new(0, 16, 0, 16)
                    Checkbox.Position = UDim2.new(1, -24, 0.5, -8)
                    Checkbox.BackgroundColor3 = isSelected and Colors.Accent or Colors.Border
                    Checkbox.BorderSizePixel = 0
                    Checkbox.ZIndex = 103
                    Checkbox.Parent = OptionItem
                    
                    local CheckCorner = Instance.new("UICorner")
                    CheckCorner.CornerRadius = UDim.new(0, 4)
                    CheckCorner.Parent = Checkbox
                    
                    if isSelected then
                        local CheckMark = Instance.new("TextLabel")
                        CheckMark.Name = "Check"
                        CheckMark.Size = UDim2.new(1, 0, 1, 0)
                        CheckMark.BackgroundTransparency = 1
                        CheckMark.Text = "✓"
                        CheckMark.TextColor3 = Colors.Text
                        CheckMark.TextSize = 12
                        CheckMark.Font = Enum.Font.GothamBold
                        CheckMark.ZIndex = 104
                        CheckMark.Parent = Checkbox
                    end
                end
                
                -- Hover effects
                local conn1 = OptionItem.MouseEnter:Connect(function()
                    Tween(OptionItem, {BackgroundColor3 = Colors.Accent, BackgroundTransparency = 0.3}, 0.15)
                    Tween(OptionText, {TextColor3 = Colors.Text}, 0.15)
                end)
                
                local conn2 = OptionItem.MouseLeave:Connect(function()
                    local currentlySelected = multiSelect and table.find(DropdownState.Selected, text) or DropdownState.Selected == text
                    Tween(OptionItem, {
                        BackgroundColor3 = currentlySelected and Colors.Accent or Colors.Background,
                        BackgroundTransparency = currentlySelected and 0.1 or 0.5
                    }, 0.15)
                    Tween(OptionText, {TextColor3 = currentlySelected and Colors.Text or Colors.TextDim}, 0.15)
                end)
                
                -- Click handling
                local conn3 = OptionItem.MouseButton1Click:Connect(function()
                    if multiSelect then
                        local selectedIndex = table.find(DropdownState.Selected, text)
                        if selectedIndex then
                            table.remove(DropdownState.Selected, selectedIndex)
                        else
                            table.insert(DropdownState.Selected, text)
                        end
                        
                        UpdateSelectedDisplay()
                        RefreshOptions()
                        SafeCallback(callback, DropdownState.Selected)
                        
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = DropdownState.Selected
                        end
                    else
                        DropdownState.Selected = text
                        UpdateSelectedDisplay()
                        CloseDropdown()
                        SafeCallback(callback, text)
                        
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = text
                        end
                    end
                end)
                
                table.insert(Connections, conn1)
                table.insert(Connections, conn2)
                table.insert(Connections, conn3)
                
                OptionItems[text] = {
                    Item = OptionItem,
                    Text = OptionText,
                    Checkbox = Checkbox
                }
                
                return OptionItem
            end
            
            -- Filter options
            local function FilterOptions(searchText)
                searchText = string.lower(searchText or "")
                DropdownState.FilteredOptions = {}
                
                for _, option in ipairs(options) do
                    if searchText == "" or string.find(string.lower(option), searchText, 1, true) then
                        table.insert(DropdownState.FilteredOptions, option)
                    end
                end
                
                RefreshOptions()
            end
            
            -- Refresh options display
            RefreshOptions = function()
                for _, data in pairs(OptionItems) do
                    if data.Item and data.Item.Parent then
                        data.Item:Destroy()
                    end
                end
                OptionItems = {}
                
                for index, option in ipairs(DropdownState.FilteredOptions) do
                    CreateOptionItem(option, index)
                end
                
                local optionCount = math.min(#DropdownState.FilteredOptions, maxVisible)
                local panelHeight = OptionsOffset + (optionCount * 32) + 16
                
                if DropdownState.IsOpen then
                    local buttonWidth = DropdownButton.AbsoluteSize.X
                    Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, panelHeight)}, 0.2)
                end
            end
            
            -- Update selected display
            UpdateSelectedDisplay = function()
                if multiSelect then
                    if #DropdownState.Selected == 0 then
                        SelectedText.Text = placeholder
                        SelectedText.TextColor3 = Colors.TextDim
                    elseif #DropdownState.Selected == 1 then
                        SelectedText.Text = DropdownState.Selected[1]
                        SelectedText.TextColor3 = Colors.Accent
                    else
                        SelectedText.Text = #DropdownState.Selected .. " selected"
                        SelectedText.TextColor3 = Colors.Accent
                    end
                else
                    SelectedText.Text = DropdownState.Selected or placeholder
                    SelectedText.TextColor3 = DropdownState.Selected and Colors.Accent or Colors.TextDim
                end
            end
            
            -- Open dropdown
            OpenDropdown = function()
                if DropdownState.IsOpen then return end
                
                DropdownState.IsOpen = true
                Panel.Visible = true
                UpdatePanelPosition()
                
                local optionCount = math.min(#DropdownState.FilteredOptions, maxVisible)
                local targetHeight = OptionsOffset + (optionCount * 32) + 16
                local buttonWidth = DropdownButton.AbsoluteSize.X
                
                Panel.Size = UDim2.fromOffset(buttonWidth, 0)
                Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, targetHeight)}, 0.25, Enum.EasingStyle.Quart)
                Tween(Arrow, {Rotation = 180, TextColor3 = Colors.Accent}, 0.2)
                Tween(DropdownButton, {BackgroundColor3 = Colors.Border}, 0.2)
                
                if SearchBox then
                    task.wait(0.25)
                    if SearchBox and SearchBox.Parent then
                        SearchBox:CaptureFocus()
                    end
                end
            end
            
            -- Close dropdown
            CloseDropdown = function()
                if not DropdownState.IsOpen then return end
                
                DropdownState.IsOpen = false
                
                local buttonWidth = DropdownButton.AbsoluteSize.X
                Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, 0)}, 0.2, Enum.EasingStyle.Quart)
                Tween(Arrow, {Rotation = 0, TextColor3 = Colors.TextDim}, 0.2)
                Tween(DropdownButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                
                task.delay(0.2, function()
                    if not DropdownState.IsOpen then
                        Panel.Visible = false
                    end
                end)
                
                if SearchBox then
                    SearchBox.Text = ""
                    DropdownState.SearchText = ""
                    DropdownState.FilteredOptions = options
                end
            end
            
            -- Close button events
            CloseButton.MouseEnter:Connect(function()
                Tween(CloseButtonFrame, {BackgroundColor3 = Colors.Accent}, 0.15)
                Tween(CloseIcon, {TextColor3 = Colors.Text}, 0.15)
                Tween(CloseText, {TextColor3 = Colors.Text}, 0.15)
            end)
            
            CloseButton.MouseLeave:Connect(function()
                Tween(CloseButtonFrame, {BackgroundColor3 = Colors.Border}, 0.15)
                Tween(CloseIcon, {TextColor3 = closeColor}, 0.15)
                Tween(CloseText, {TextColor3 = closeColor}, 0.15)
            end)
            
            CloseButton.MouseButton1Click:Connect(CloseDropdown)
            
            -- Search events
            if SearchBox then
                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local searchText = SearchBox.Text
                    task.delay(0.2, function()
                        if SearchBox and SearchBox.Parent and SearchBox.Text == searchText then
                            DropdownState.SearchText = searchText
                            FilterOptions(searchText)
                        end
                    end)
                end)
            end
            
            -- Button click
            DropdownButton.MouseButton1Click:Connect(function()
                if DropdownState.IsOpen then
                    CloseDropdown()
                else
                    OpenDropdown()
                end
            end)
            
            -- Button hover
            DropdownButton.MouseEnter:Connect(function()
                if not DropdownState.IsOpen then
                    Tween(DropdownButton, {BackgroundColor3 = Colors.Border}, 0.2)
                end
            end)
            
            DropdownButton.MouseLeave:Connect(function()
                if not DropdownState.IsOpen then
                    Tween(DropdownButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                end
            end)
            
            -- Click outside to close
            local clickOutsideConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and DropdownState.IsOpen then
                    local mouse = Players.LocalPlayer:GetMouse()
                    local mouseX, mouseY = mouse.X, mouse.Y
                    
                    local buttonPos = DropdownButton.AbsolutePosition
                    local buttonSize = DropdownButton.AbsoluteSize
                    local onButton = (mouseX >= buttonPos.X and mouseX <= buttonPos.X + buttonSize.X and
                                     mouseY >= buttonPos.Y and mouseY <= buttonPos.Y + buttonSize.Y)
                    
                    local onPanel = false
                    if Panel and Panel.Visible then
                        local panelPos = Panel.AbsolutePosition
                        local panelSize = Panel.AbsoluteSize
                        onPanel = (mouseX >= panelPos.X and mouseX <= panelPos.X + panelSize.X and
                                  mouseY >= panelPos.Y and mouseY <= panelPos.Y + panelSize.Y)
                    end
                    
                    if not onButton and not onPanel then
                        CloseDropdown()
                    end
                end
            end)
            table.insert(Connections, clickOutsideConn)
            
            -- ESC to close
            local escConn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Escape and DropdownState.IsOpen then
                    CloseDropdown()
                end
            end)
            table.insert(Connections, escConn)
            
            -- Update position on RenderStepped
            local renderConn = game:GetService("RunService").RenderStepped:Connect(function()
                if DropdownState.IsOpen and Panel.Visible then
                    UpdatePanelPosition()
                end
            end)
            table.insert(Connections, renderConn)
            
            -- Initial setup
            DropdownState.FilteredOptions = options
            RefreshOptions()
            UpdateSelectedDisplay()
            
            local dropdownObj = {
                SetValue = function(value, silent)
                    if multiSelect then
                        DropdownState.Selected = type(value) == "table" and value or {}
                    else
                        DropdownState.Selected = value
                    end
                    
                    UpdateSelectedDisplay()
                    RefreshOptions()
                    
                    if not silent then
                        SafeCallback(callback, DropdownState.Selected)
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = DropdownState.Selected
                        end
                    end
                end,
                GetValue = function()
                    return DropdownState.Selected
                end,
                SetOptions = function(newOptions)
                    options = newOptions or {}
                    DropdownState.FilteredOptions = options
                    RefreshOptions()
                    
                    if multiSelect then
                        local validSelected = {}
                        for _, sel in ipairs(DropdownState.Selected) do
                            if table.find(options, sel) then
                                table.insert(validSelected, sel)
                            end
                        end
                        DropdownState.Selected = validSelected
                    else
                        if not table.find(options, DropdownState.Selected) then
                            DropdownState.Selected = options[1]
                        end
                    end
                    UpdateSelectedDisplay()
                end,
                Refresh = function(newOptions)
                    dropdownObj.SetOptions(newOptions)
                end,
                Open = function()
                    OpenDropdown()
                end,
                Close = function()
                    CloseDropdown()
                end,
                SetVisible = function(visible)
                    Container.Visible = visible
                    if not visible and DropdownState.IsOpen then
                        CloseDropdown()
                    end
                end,
                Destroy = function()
                    CloseDropdown()
                    for _, conn in ipairs(Connections) do
                        if conn.Connected then conn:Disconnect() end
                    end
                    if Container and Container.Parent then Container:Destroy() end
                    if Panel and Panel.Parent then Panel:Destroy() end
                end,
                Instance = Container
            }
            
            -- Register flag
            if flag and ConfigSystem and ConfigSystem.Flags then
                ConfigSystem.Flags[flag] = {
                    Type = "Dropdown",
                    Set = function(value)
                        dropdownObj.SetValue(value)
                    end,
                    Get = function()
                        return DropdownState.Selected
                    end
                }
                if ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = DropdownState.Selected
                end
            end
            
            return dropdownObj
        end
        
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = TabContent
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Colors.TextDim
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            Label.Parent = LabelFrame
            
            return {
                SetText = function(newText)
                    Label.Text = newText
                end,
                SetVisible = function(visible)
                    LabelFrame.Visible = visible
                end,
                Instance = LabelFrame
            }
        end
        
        function Tab:CreateParagraph(config)
            config = config or {}
            local title = config.Title or "Paragraph"
            local content = config.Content or "Paragraph content here."
            
            local ParagraphFrame = Instance.new("Frame")
            ParagraphFrame.Size = UDim2.new(1, 0, 0, 10)
            ParagraphFrame.BackgroundColor3 = Colors.Tertiary
            ParagraphFrame.BorderSizePixel = 0
            ParagraphFrame.Parent = TabContent
            
            local ParagraphCorner = Instance.new("UICorner")
            ParagraphCorner.CornerRadius = UDim.new(0, 8)
            ParagraphCorner.Parent = ParagraphFrame
            
            local ParagraphTitle = Instance.new("TextLabel")
            ParagraphTitle.Size = UDim2.new(1, -20, 0, 25)
            ParagraphTitle.Position = UDim2.new(0, 10, 0, 8)
            ParagraphTitle.BackgroundTransparency = 1
            ParagraphTitle.Text = title
            ParagraphTitle.TextColor3 = Colors.Text
            ParagraphTitle.TextSize = 14
            ParagraphTitle.Font = Enum.Font.GothamBold
            ParagraphTitle.TextXAlignment = Enum.TextXAlignment.Left
            ParagraphTitle.Parent = ParagraphFrame
            
            local ParagraphContent = Instance.new("TextLabel")
            ParagraphContent.Size = UDim2.new(1, -20, 0, 1000)
            ParagraphContent.Position = UDim2.new(0, 10, 0, 33)
            ParagraphContent.BackgroundTransparency = 1
            ParagraphContent.Text = content
            ParagraphContent.TextColor3 = Colors.TextDim
            ParagraphContent.TextSize = 12
            ParagraphContent.Font = Enum.Font.Gotham
            ParagraphContent.TextXAlignment = Enum.TextXAlignment.Left
            ParagraphContent.TextYAlignment = Enum.TextYAlignment.Top
            ParagraphContent.TextWrapped = true
            ParagraphContent.Parent = ParagraphFrame
            
            ParagraphContent.Size = UDim2.new(1, -20, 0, ParagraphContent.TextBounds.Y)
            ParagraphFrame.Size = UDim2.new(1, 0, 0, 48 + ParagraphContent.TextBounds.Y)
            
            return {
                SetTitle = function(newTitle)
                    ParagraphTitle.Text = newTitle
                end,
                SetContent = function(newContent)
                    ParagraphContent.Text = newContent
                    ParagraphContent.Size = UDim2.new(1, -20, 0, ParagraphContent.TextBounds.Y)
                    ParagraphFrame.Size = UDim2.new(1, 0, 0, 48 + ParagraphContent.TextBounds.Y)
                end,
                SetVisible = function(visible)
                    ParagraphFrame.Visible = visible
                end,
                Instance = ParagraphFrame
            }
        end
        
        function Tab:CreateDivider(text)
            local DividerFrame = Instance.new("Frame")
            DividerFrame.Size = UDim2.new(1, 0, 0, 20)
            DividerFrame.BackgroundTransparency = 1
            DividerFrame.Parent = TabContent
            
            if text then
                local DividerLabel = Instance.new("TextLabel")
                DividerLabel.Size = UDim2.new(0, 0, 1, 0)
                DividerLabel.Position = UDim2.new(0, 0, 0, 0)
                DividerLabel.BackgroundTransparency = 1
                DividerLabel.Text = text
                DividerLabel.TextColor3 = Colors.TextDim
                DividerLabel.TextSize = 12
                DividerLabel.Font = Enum.Font.GothamBold
                DividerLabel.TextXAlignment = Enum.TextXAlignment.Left
                DividerLabel.Parent = DividerFrame
                
                DividerLabel.Size = UDim2.new(0, DividerLabel.TextBounds.X + 10, 1, 0)
                
                local Line1 = Instance.new("Frame")
                Line1.Size = UDim2.new(0, 0, 0, 1)
                Line1.Position = UDim2.new(0, DividerLabel.TextBounds.X + 15, 0.5, 0)
                Line1.BackgroundColor3 = Colors.Border
                Line1.BorderSizePixel = 0
                Line1.Parent = DividerFrame
                
                task.wait()
                Line1.Size = UDim2.new(1, -(DividerLabel.TextBounds.X + 15), 0, 1)
            else
                local Line = Instance.new("Frame")
                Line.Size = UDim2.new(1, 0, 0, 1)
                Line.Position = UDim2.new(0, 0, 0.5, 0)
                Line.BackgroundColor3 = Colors.Border
                Line.BorderSizePixel = 0
                Line.Parent = DividerFrame
            end
            
            return {
                SetVisible = function(visible)
                    DividerFrame.Visible = visible
                end,
                Instance = DividerFrame
            }
        end
        
        -- ═══════════════════════════════════════════
        -- SEARCHABLE DROPDOWN (uses Modern Dropdown with Search enabled)
        -- ═══════════════════════════════════════════
        function Tab:CreateSearchDropdown(config)
            config = config or {}
            -- Use the modern dropdown with Search enabled
            return Tab:CreateDropdown({
                Name = config.Name or "Search Dropdown",
                Options = config.Options or {"Option 1", "Option 2", "Option 3"},
                Default = config.Default,
                Callback = config.Callback or function() end,
                Flag = config.Flag,
                Search = true,  -- Enable search
                MultiSelect = false,
                MaxVisible = config.MaxVisible or 6,
                Placeholder = config.Placeholder or "Select option..."
            })
        end
        
        -- ═══════════════════════════════════════════
        -- BAR CHART
        -- ═══════════════════════════════════════════
        function Tab:CreateChart(config)
            config = config or {}
            local chartTitle = config.Name or "Chart"
            local chartType = config.Type or "Bar" -- Bar, Line (future)
            local data = config.Data or {
                {Label = "A", Value = 50},
                {Label = "B", Value = 75},
                {Label = "C", Value = 30}
            }
            local maxValue = config.Max or 100
            local barColor = config.Color or Colors.Accent
            local showValues = config.ShowValues ~= false
            
            local chartHeight = 120
            local ChartFrame = Instance.new("Frame")
            ChartFrame.Size = UDim2.new(1, 0, 0, chartHeight + 50)
            ChartFrame.BackgroundColor3 = Colors.Tertiary
            ChartFrame.BorderSizePixel = 0
            ChartFrame.Parent = TabContent
            
            local ChartCorner = Instance.new("UICorner")
            ChartCorner.CornerRadius = UDim.new(0, 8)
            ChartCorner.Parent = ChartFrame
            
            -- Title
            local ChartTitle = Instance.new("TextLabel")
            ChartTitle.Size = UDim2.new(1, -20, 0, 25)
            ChartTitle.Position = UDim2.new(0, 10, 0, 8)
            ChartTitle.BackgroundTransparency = 1
            ChartTitle.Text = chartTitle
            ChartTitle.TextColor3 = Colors.Text
            ChartTitle.TextSize = 14
            ChartTitle.Font = Enum.Font.GothamBold
            ChartTitle.TextXAlignment = Enum.TextXAlignment.Left
            ChartTitle.Parent = ChartFrame
            
            -- Chart Area
            local ChartArea = Instance.new("Frame")
            ChartArea.Size = UDim2.new(1, -20, 0, chartHeight)
            ChartArea.Position = UDim2.new(0, 10, 0, 35)
            ChartArea.BackgroundColor3 = Colors.Background
            ChartArea.BorderSizePixel = 0
            ChartArea.Parent = ChartFrame
            
            local ChartAreaCorner = Instance.new("UICorner")
            ChartAreaCorner.CornerRadius = UDim.new(0, 6)
            ChartAreaCorner.Parent = ChartArea
            
            -- Bars Container
            local BarsContainer = Instance.new("Frame")
            BarsContainer.Size = UDim2.new(1, -20, 1, -30)
            BarsContainer.Position = UDim2.new(0, 10, 0, 5)
            BarsContainer.BackgroundTransparency = 1
            BarsContainer.Parent = ChartArea
            
            local BarsLayout = Instance.new("UIListLayout")
            BarsLayout.FillDirection = Enum.FillDirection.Horizontal
            BarsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            BarsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            BarsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            BarsLayout.Padding = UDim.new(0, 8)
            BarsLayout.Parent = BarsContainer
            
            local barElements = {}
            local barWidth = math.min(40, (BarsContainer.AbsoluteSize.X - (#data - 1) * 8) / #data)
            
            local function updateChart(newData)
                -- Remove old bars
                for _, bar in ipairs(barElements) do
                    bar:Destroy()
                end
                barElements = {}
                
                barWidth = math.min(40, (ChartArea.AbsoluteSize.X - 20 - (#newData - 1) * 8) / #newData)
                
                for i, item in ipairs(newData) do
                    local barHeight = (item.Value / maxValue) * (chartHeight - 50)
                    
                    local BarFrame = Instance.new("Frame")
                    BarFrame.Size = UDim2.new(0, barWidth, 0, 0)
                    BarFrame.BackgroundTransparency = 1
                    BarFrame.LayoutOrder = i
                    BarFrame.Parent = BarsContainer
                    
                    local Bar = Instance.new("Frame")
                    Bar.Size = UDim2.new(1, 0, 0, 0)
                    Bar.Position = UDim2.new(0, 0, 1, 0)
                    Bar.AnchorPoint = Vector2.new(0, 1)
                    Bar.BackgroundColor3 = barColor
                    Bar.BorderSizePixel = 0
                    Bar.Parent = BarFrame
                    
                    local BarCorner = Instance.new("UICorner")
                    BarCorner.CornerRadius = UDim.new(0, 4)
                    BarCorner.Parent = Bar
                    
                    -- Animate bar
                    Tween(Bar, {Size = UDim2.new(1, 0, 0, barHeight)}, 0.5, Enum.EasingStyle.Back)
                    
                    -- Value label
                    if showValues then
                        local ValueLabel = Instance.new("TextLabel")
                        ValueLabel.Size = UDim2.new(1, 0, 0, 15)
                        ValueLabel.Position = UDim2.new(0, 0, 0, -barHeight - 18)
                        ValueLabel.BackgroundTransparency = 1
                        ValueLabel.Text = tostring(item.Value)
                        ValueLabel.TextColor3 = Colors.Text
                        ValueLabel.TextSize = 10
                        ValueLabel.Font = Enum.Font.GothamBold
                        ValueLabel.Parent = Bar
                    end
                    
                    table.insert(barElements, BarFrame)
                end
                
                data = newData
            end
            
            -- Labels Container
            local LabelsContainer = Instance.new("Frame")
            LabelsContainer.Size = UDim2.new(1, -20, 0, 20)
            LabelsContainer.Position = UDim2.new(0, 10, 1, -25)
            LabelsContainer.BackgroundTransparency = 1
            LabelsContainer.Parent = ChartArea
            
            local LabelsLayout = Instance.new("UIListLayout")
            LabelsLayout.FillDirection = Enum.FillDirection.Horizontal
            LabelsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            LabelsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            LabelsLayout.Padding = UDim.new(0, 8)
            LabelsLayout.Parent = LabelsContainer
            
            for i, item in ipairs(data) do
                local LabelFrame = Instance.new("Frame")
                LabelFrame.Size = UDim2.new(0, barWidth, 0, 20)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.LayoutOrder = i
                LabelFrame.Parent = LabelsContainer
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 1, 0)
                Label.BackgroundTransparency = 1
                Label.Text = item.Label
                Label.TextColor3 = Colors.TextDim
                Label.TextSize = 10
                Label.Font = Enum.Font.Gotham
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.Parent = LabelFrame
            end
            
            -- Initial render
            task.wait()
            updateChart(data)
            
            return {
                SetData = function(newData)
                    -- Update labels
                    for _, child in ipairs(LabelsContainer:GetChildren()) do
                        if child:IsA("Frame") then
                            child:Destroy()
                        end
                    end
                    
                    barWidth = math.min(40, (ChartArea.AbsoluteSize.X - 20 - (#newData - 1) * 8) / #newData)
                    
                    for i, item in ipairs(newData) do
                        local LabelFrame = Instance.new("Frame")
                        LabelFrame.Size = UDim2.new(0, barWidth, 0, 20)
                        LabelFrame.BackgroundTransparency = 1
                        LabelFrame.LayoutOrder = i
                        LabelFrame.Parent = LabelsContainer
                        
                        local Label = Instance.new("TextLabel")
                        Label.Size = UDim2.new(1, 0, 1, 0)
                        Label.BackgroundTransparency = 1
                        Label.Text = item.Label
                        Label.TextColor3 = Colors.TextDim
                        Label.TextSize = 10
                        Label.Font = Enum.Font.Gotham
                        Label.TextTruncate = Enum.TextTruncate.AtEnd
                        Label.Parent = LabelFrame
                    end
                    
                    updateChart(newData)
                end,
                SetMax = function(newMax)
                    maxValue = newMax
                    updateChart(data)
                end,
                SetVisible = function(visible)
                    ChartFrame.Visible = visible
                end,
                Instance = ChartFrame
            }
        end
        
        function Tab:CreateSection(sectionName)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, 0, 0, 35)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Parent = TabContent
            
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Size = UDim2.new(1, -10, 1, 0)
            SectionLabel.Position = UDim2.new(0, 5, 0, 0)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Text = sectionName
            SectionLabel.TextColor3 = Colors.Text
            SectionLabel.TextSize = 15
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = SectionFrame
            
            local SectionLine = Instance.new("Frame")
            SectionLine.Size = UDim2.new(1, 0, 0, 2)
            SectionLine.Position = UDim2.new(0, 0, 1, -2)
            SectionLine.BackgroundColor3 = Colors.Accent
            SectionLine.BorderSizePixel = 0
            SectionLine.Parent = SectionFrame
            
            local SectionLineCorner = Instance.new("UICorner")
            SectionLineCorner.CornerRadius = UDim.new(1, 0)
            SectionLineCorner.Parent = SectionLine
            
            return {
                SetText = function(newText)
                    SectionLabel.Text = newText
                end,
                SetVisible = function(visible)
                    SectionFrame.Visible = visible
                end,
                Instance = SectionFrame
            }
        end
        
        function Tab:CreateCollapsible(config)
            config = config or {}
            local collapsibleName = config.Name or "Collapsible"
            local defaultOpen = config.DefaultOpen or false
            
            local CollapsibleFrame = Instance.new("Frame")
            CollapsibleFrame.Size = UDim2.new(1, 0, 0, 40)
            CollapsibleFrame.BackgroundColor3 = Colors.Tertiary
            CollapsibleFrame.BorderSizePixel = 0
            CollapsibleFrame.ClipsDescendants = true
            CollapsibleFrame.Parent = TabContent
            
            local CollapsibleCorner = Instance.new("UICorner")
            CollapsibleCorner.CornerRadius = UDim.new(0, 8)
            CollapsibleCorner.Parent = CollapsibleFrame
            
            local HeaderButton = Instance.new("TextButton")
            HeaderButton.Size = UDim2.new(1, 0, 0, 40)
            HeaderButton.BackgroundTransparency = 1
            HeaderButton.Text = ""
            HeaderButton.Parent = CollapsibleFrame
            
            local HeaderLabel = Instance.new("TextLabel")
            HeaderLabel.Size = UDim2.new(1, -40, 0, 40)
            HeaderLabel.Position = UDim2.new(0, 15, 0, 0)
            HeaderLabel.BackgroundTransparency = 1
            HeaderLabel.Text = collapsibleName
            HeaderLabel.TextColor3 = Colors.Text
            HeaderLabel.TextSize = 14
            HeaderLabel.Font = Enum.Font.GothamBold
            HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
            HeaderLabel.Parent = CollapsibleFrame
            
            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 20, 0, 40)
            Arrow.Position = UDim2.new(1, -30, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Colors.TextDim
            Arrow.TextSize = 12
            Arrow.Font = Enum.Font.Gotham
            Arrow.Rotation = defaultOpen and 0 or -90
            Arrow.Parent = CollapsibleFrame
            
            local ContentFrame = Instance.new("Frame")
            ContentFrame.Size = UDim2.new(1, -20, 0, 0)
            ContentFrame.Position = UDim2.new(0, 10, 0, 45)
            ContentFrame.BackgroundTransparency = 1
            ContentFrame.Parent = CollapsibleFrame
            
            local ContentList = Instance.new("UIListLayout")
            ContentList.SortOrder = Enum.SortOrder.LayoutOrder
            ContentList.Padding = UDim.new(0, 5)
            ContentList.Parent = ContentFrame
            
            local isOpen = defaultOpen
            
            ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ContentFrame.Size = UDim2.new(1, -20, 0, ContentList.AbsoluteContentSize.Y)
                if isOpen then
                    CollapsibleFrame.Size = UDim2.new(1, 0, 0, 55 + ContentList.AbsoluteContentSize.Y)
                end
            end)
            
            HeaderButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Tween(CollapsibleFrame, {Size = UDim2.new(1, 0, 0, 55 + ContentList.AbsoluteContentSize.Y)}, 0.3)
                    Tween(Arrow, {Rotation = 0}, 0.3)
                else
                    Tween(CollapsibleFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Tween(Arrow, {Rotation = -90}, 0.3)
                end
            end)
            
            if defaultOpen then
                CollapsibleFrame.Size = UDim2.new(1, 0, 0, 55 + ContentList.AbsoluteContentSize.Y)
            end
            
            local Collapsible = {
                ContentFrame = ContentFrame,
                ContentList = ContentList
            }
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddButton
            -- ═══════════════════════════════════════════
            function Collapsible:AddButton(config)
                config = config or {}
                local buttonText = config.Name or "Button"
                local callback = config.Callback or function() end
                
                local ButtonFrame = Instance.new("Frame")
                ButtonFrame.Size = UDim2.new(1, 0, 0, 35)
                ButtonFrame.BackgroundColor3 = Colors.Background
                ButtonFrame.BorderSizePixel = 0
                ButtonFrame.Parent = ContentFrame
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 6)
                ButtonCorner.Parent = ButtonFrame
                
                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 1, 0)
                Button.BackgroundTransparency = 1
                Button.Text = buttonText
                Button.TextColor3 = Colors.Text
                Button.TextSize = 13
                Button.Font = Enum.Font.Gotham
                Button.Parent = ButtonFrame
                
                Button.MouseButton1Click:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Colors.Accent}, 0.1)
                    task.wait(0.1)
                    Tween(ButtonFrame, {BackgroundColor3 = Colors.Background}, 0.1)
                    SafeCallback(callback)
                end)
                
                Button.MouseEnter:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Colors.Border}, 0.2)
                end)
                
                Button.MouseLeave:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Colors.Background}, 0.2)
                end)
                
                return {
                    SetVisible = function(visible)
                        ButtonFrame.Visible = visible
                    end,
                    Instance = ButtonFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddToggle
            -- ═══════════════════════════════════════════
            function Collapsible:AddToggle(config)
                config = config or {}
                local toggleText = config.Name or "Toggle"
                local default = config.Default or false
                local callback = config.Callback or function() end
                local flag = config.Flag
                
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
                ToggleFrame.BackgroundColor3 = Colors.Background
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Parent = ContentFrame
                
                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(0, 6)
                ToggleCorner.Parent = ToggleFrame
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = toggleText
                ToggleLabel.TextColor3 = Colors.Text
                ToggleLabel.TextSize = 13
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleFrame
                
                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Size = UDim2.new(0, 40, 0, 20)
                ToggleButton.Position = UDim2.new(1, -45, 0.5, -10)
                ToggleButton.BackgroundColor3 = default and Colors.Accent or Colors.Border
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Text = ""
                ToggleButton.AutoButtonColor = false
                ToggleButton.Parent = ToggleFrame
                
                local ToggleButtonCorner = Instance.new("UICorner")
                ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
                ToggleButtonCorner.Parent = ToggleButton
                
                local ToggleCircle = Instance.new("Frame")
                ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
                ToggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                ToggleCircle.BackgroundColor3 = Colors.Text
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Parent = ToggleButton
                
                local CircleCorner = Instance.new("UICorner")
                CircleCorner.CornerRadius = UDim.new(1, 0)
                CircleCorner.Parent = ToggleCircle
                
                local toggled = default
                
                ToggleButton.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    
                    Tween(ToggleButton, {
                        BackgroundColor3 = toggled and Colors.Accent or Colors.Border
                    }, 0.2)
                    
                    Tween(ToggleCircle, {
                        Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    }, 0.2)
                    
                    SafeCallback(callback, toggled)
                    
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = toggled
                    end
                end)
                
                local toggleObj = {
                    SetValue = function(value)
                        toggled = value
                        ToggleButton.BackgroundColor3 = toggled and Colors.Accent or Colors.Border
                        ToggleCircle.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                        SafeCallback(callback, toggled)
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = toggled
                        end
                    end,
                    SetVisible = function(visible)
                        ToggleFrame.Visible = visible
                    end,
                    Instance = ToggleFrame
                }
                
                if flag and ConfigSystem and ConfigSystem.Flags then
                    ConfigSystem.Flags[flag] = {
                        Type = "Toggle",
                        Set = function(value) toggleObj.SetValue(value) end,
                        Get = function() return toggled end
                    }
                end
                
                return toggleObj
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddSlider
            -- ═══════════════════════════════════════════
            function Collapsible:AddSlider(config)
                config = config or {}
                local sliderText = config.Name or "Slider"
                local min = config.Min or 0
                local max = config.Max or 100
                local default = config.Default or min
                local increment = config.Increment or 1
                local callback = config.Callback or function() end
                local flag = config.Flag
                
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Size = UDim2.new(1, 0, 0, 45)
                SliderFrame.BackgroundColor3 = Colors.Background
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Parent = ContentFrame
                
                local SliderCorner = Instance.new("UICorner")
                SliderCorner.CornerRadius = UDim.new(0, 6)
                SliderCorner.Parent = SliderFrame
                
                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Size = UDim2.new(1, -60, 0, 18)
                SliderLabel.Position = UDim2.new(0, 10, 0, 4)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = sliderText
                SliderLabel.TextColor3 = Colors.Text
                SliderLabel.TextSize = 13
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderFrame
                
                local SliderValue = Instance.new("TextLabel")
                SliderValue.Size = UDim2.new(0, 50, 0, 18)
                SliderValue.Position = UDim2.new(1, -55, 0, 4)
                SliderValue.BackgroundTransparency = 1
                SliderValue.Text = tostring(default)
                SliderValue.TextColor3 = Colors.Accent
                SliderValue.TextSize = 13
                SliderValue.Font = Enum.Font.GothamBold
                SliderValue.TextXAlignment = Enum.TextXAlignment.Right
                SliderValue.Parent = SliderFrame
                
                local SliderBar = Instance.new("Frame")
                SliderBar.Size = UDim2.new(1, -20, 0, 6)
                SliderBar.Position = UDim2.new(0, 10, 1, -12)
                SliderBar.BackgroundColor3 = Colors.Border
                SliderBar.BorderSizePixel = 0
                SliderBar.Parent = SliderFrame
                
                local SliderBarCorner = Instance.new("UICorner")
                SliderBarCorner.CornerRadius = UDim.new(1, 0)
                SliderBarCorner.Parent = SliderBar
                
                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                SliderFill.BackgroundColor3 = Colors.Accent
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBar
                
                local SliderFillCorner = Instance.new("UICorner")
                SliderFillCorner.CornerRadius = UDim.new(1, 0)
                SliderFillCorner.Parent = SliderFill
                
                local SliderButton = Instance.new("TextButton")
                SliderButton.Size = UDim2.new(1, 0, 1, 10)
                SliderButton.Position = UDim2.new(0, 0, 0, -5)
                SliderButton.BackgroundTransparency = 1
                SliderButton.Text = ""
                SliderButton.Parent = SliderBar
                
                local dragging = false
                local currentValue = default
                
                SliderButton.MouseButton1Down:Connect(function()
                    dragging = true
                end)
                
                SliderButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                
                local function updateSlider(input)
                    local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local value = math.floor((min + (max - min) * percentage) / increment + 0.5) * increment
                    value = math.clamp(value, min, max)
                    
                    currentValue = value
                    SliderValue.Text = tostring(value)
                    SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    SafeCallback(callback, value)
                    
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = value
                    end
                end
                
                SliderButton.MouseButton1Click:Connect(function()
                    local mouse = UserInputService:GetMouseLocation()
                    updateSlider({Position = Vector2.new(mouse.X, mouse.Y)})
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)
                
                local sliderObj = {
                    SetValue = function(value)
                        value = math.clamp(value, min, max)
                        currentValue = value
                        local percentage = (value - min) / (max - min)
                        SliderValue.Text = tostring(value)
                        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                        SafeCallback(callback, value)
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = value
                        end
                    end,
                    SetVisible = function(visible)
                        SliderFrame.Visible = visible
                    end,
                    Instance = SliderFrame
                }
                
                if flag and ConfigSystem and ConfigSystem.Flags then
                    ConfigSystem.Flags[flag] = {
                        Type = "Slider",
                        Set = function(value) sliderObj.SetValue(value) end,
                        Get = function() return currentValue end
                    }
                end
                
                return sliderObj
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddDropdown (Modern with Panel on ScreenGui)
            -- ═══════════════════════════════════════════
            function Collapsible:AddDropdown(config)
                config = config or {}
                local dropdownText = config.Name or "Dropdown"
                local options = config.Options or {"Option 1", "Option 2"}
                local default = config.Default
                local callback = config.Callback or function() end
                local flag = config.Flag
                local multiSelect = config.MultiSelect or false
                local searchEnabled = config.Search or false
                local maxVisible = config.MaxVisible or 5
                local placeholder = config.Placeholder or "Select option..."
                
                -- State management
                local DropdownState = {
                    IsOpen = false,
                    Selected = multiSelect and {} or (default or options[1]),
                    FilteredOptions = options,
                    SearchText = ""
                }
                
                if multiSelect and default and type(default) == "table" then
                    DropdownState.Selected = default
                elseif multiSelect then
                    DropdownState.Selected = {}
                end
                
                -- Container in Collapsible
                local Container = Instance.new("Frame")
                Container.Name = "Dropdown_" .. dropdownText
                Container.Size = UDim2.new(1, 0, 0, 35)
                Container.BackgroundTransparency = 1
                Container.Parent = ContentFrame
                
                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Name = "Button"
                DropdownButton.Size = UDim2.new(1, 0, 1, 0)
                DropdownButton.BackgroundColor3 = Colors.Background
                DropdownButton.BorderSizePixel = 0
                DropdownButton.Text = ""
                DropdownButton.AutoButtonColor = false
                DropdownButton.Parent = Container
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 6)
                ButtonCorner.Parent = DropdownButton
                
                local ButtonStroke = Instance.new("UIStroke")
                ButtonStroke.Color = Colors.Border
                ButtonStroke.Thickness = 1
                ButtonStroke.Transparency = 0.7
                ButtonStroke.Parent = DropdownButton
                
                local ButtonContent = Instance.new("Frame")
                ButtonContent.Size = UDim2.new(1, -20, 1, 0)
                ButtonContent.Position = UDim2.new(0, 10, 0, 0)
                ButtonContent.BackgroundTransparency = 1
                ButtonContent.Parent = DropdownButton
                
                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Size = UDim2.new(0, 100, 1, 0)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = dropdownText
                DropdownLabel.TextColor3 = Colors.Text
                DropdownLabel.TextSize = 13
                DropdownLabel.Font = Enum.Font.GothamMedium
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = ButtonContent
                
                local SelectedText = Instance.new("TextLabel")
                SelectedText.Size = UDim2.new(1, -120, 1, 0)
                SelectedText.Position = UDim2.new(0, 100, 0, 0)
                SelectedText.BackgroundTransparency = 1
                SelectedText.Text = placeholder
                SelectedText.TextColor3 = Colors.TextDim
                SelectedText.TextSize = 12
                SelectedText.Font = Enum.Font.Gotham
                SelectedText.TextXAlignment = Enum.TextXAlignment.Right
                SelectedText.TextTruncate = Enum.TextTruncate.AtEnd
                SelectedText.Parent = ButtonContent
                
                local Arrow = Instance.new("TextLabel")
                Arrow.Size = UDim2.new(0, 15, 1, 0)
                Arrow.Position = UDim2.new(1, -5, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.Text = "▼"
                Arrow.TextColor3 = Colors.TextDim
                Arrow.TextSize = 10
                Arrow.Font = Enum.Font.GothamBold
                Arrow.Parent = ButtonContent
                
                -- Panel on ScreenGui
                local Panel = Instance.new("Frame")
                Panel.Name = "CollapsibleDropdownPanel_" .. dropdownText
                Panel.Size = UDim2.fromOffset(0, 0)
                Panel.Position = UDim2.fromOffset(0, 0)
                Panel.BackgroundColor3 = Colors.Tertiary
                Panel.BorderSizePixel = 0
                Panel.ClipsDescendants = true
                Panel.Visible = false
                Panel.ZIndex = 100
                Panel.Parent = ScreenGui
                
                local PanelCorner = Instance.new("UICorner")
                PanelCorner.CornerRadius = UDim.new(0, 8)
                PanelCorner.Parent = Panel
                
                local PanelStroke = Instance.new("UIStroke")
                PanelStroke.Color = Colors.Border
                PanelStroke.Thickness = 1
                PanelStroke.Transparency = 0.3
                PanelStroke.Parent = Panel
                
                local CloseButtonHeight = 28
                local OptionsOffset = CloseButtonHeight + 6
                
                local CloseButtonFrame = Instance.new("Frame")
                CloseButtonFrame.Size = UDim2.new(1, -12, 0, 24)
                CloseButtonFrame.Position = UDim2.new(0, 6, 0, 3)
                CloseButtonFrame.BackgroundColor3 = Colors.Border
                CloseButtonFrame.ZIndex = 101
                CloseButtonFrame.Parent = Panel
                
                local CloseCorner = Instance.new("UICorner")
                CloseCorner.CornerRadius = UDim.new(0, 5)
                CloseCorner.Parent = CloseButtonFrame
                
                local CloseButton = Instance.new("TextButton")
                CloseButton.Size = UDim2.new(1, 0, 1, 0)
                CloseButton.BackgroundTransparency = 1
                CloseButton.Text = ""
                CloseButton.ZIndex = 102
                CloseButton.Parent = CloseButtonFrame
                
                local closeIcon = multiSelect and "✓" or "×"
                local closeText = multiSelect and "Done" or "Close"
                local closeColor = multiSelect and Colors.Accent or Colors.TextDim
                
                local CloseIcon = Instance.new("TextLabel")
                CloseIcon.Size = UDim2.new(0, 18, 1, 0)
                CloseIcon.Position = UDim2.new(0, 6, 0, 0)
                CloseIcon.BackgroundTransparency = 1
                CloseIcon.Text = closeIcon
                CloseIcon.TextColor3 = closeColor
                CloseIcon.TextSize = 11
                CloseIcon.Font = Enum.Font.GothamBold
                CloseIcon.ZIndex = 102
                CloseIcon.Parent = CloseButtonFrame
                
                local CloseText = Instance.new("TextLabel")
                CloseText.Size = UDim2.new(1, -24, 1, 0)
                CloseText.Position = UDim2.new(0, 22, 0, 0)
                CloseText.BackgroundTransparency = 1
                CloseText.Text = closeText
                CloseText.TextColor3 = closeColor
                CloseText.TextSize = 11
                CloseText.Font = Enum.Font.GothamMedium
                CloseText.TextXAlignment = Enum.TextXAlignment.Left
                CloseText.ZIndex = 102
                CloseText.Parent = CloseButtonFrame
                
                local SearchBox = nil
                if searchEnabled then
                    SearchBox = Instance.new("TextBox")
                    SearchBox.Size = UDim2.new(1, -12, 0, 26)
                    SearchBox.Position = UDim2.new(0, 6, 0, OptionsOffset)
                    SearchBox.BackgroundColor3 = Colors.Background
                    SearchBox.Text = ""
                    SearchBox.PlaceholderText = "🔍 Search..."
                    SearchBox.PlaceholderColor3 = Colors.TextDim
                    SearchBox.TextColor3 = Colors.Text
                    SearchBox.TextSize = 12
                    SearchBox.Font = Enum.Font.Gotham
                    SearchBox.ClearTextOnFocus = false
                    SearchBox.ZIndex = 101
                    SearchBox.Parent = Panel
                    
                    local SearchCorner = Instance.new("UICorner")
                    SearchCorner.CornerRadius = UDim.new(0, 5)
                    SearchCorner.Parent = SearchBox
                    
                    local SearchPadding = Instance.new("UIPadding")
                    SearchPadding.PaddingLeft = UDim.new(0, 8)
                    SearchPadding.PaddingRight = UDim.new(0, 8)
                    SearchPadding.Parent = SearchBox
                    
                    OptionsOffset = OptionsOffset + 32
                end
                
                local OptionsContainer = Instance.new("ScrollingFrame")
                OptionsContainer.Size = UDim2.new(1, 0, 1, -OptionsOffset - 6)
                OptionsContainer.Position = UDim2.new(0, 0, 0, OptionsOffset)
                OptionsContainer.BackgroundTransparency = 1
                OptionsContainer.ScrollBarThickness = 3
                OptionsContainer.ScrollBarImageColor3 = Colors.Accent
                OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
                OptionsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
                OptionsContainer.ZIndex = 101
                OptionsContainer.Parent = Panel
                
                local OptionsLayout = Instance.new("UIListLayout")
                OptionsLayout.Padding = UDim.new(0, 2)
                OptionsLayout.Parent = OptionsContainer
                
                local OptionsPadding = Instance.new("UIPadding")
                OptionsPadding.PaddingLeft = UDim.new(0, 6)
                OptionsPadding.PaddingRight = UDim.new(0, 6)
                OptionsPadding.Parent = OptionsContainer
                
                local OptionItems = {}
                local Connections = {}
                local RefreshOptions, UpdateSelectedDisplay, CloseDropdown, OpenDropdown
                
                local function UpdatePanelPosition()
                    if not DropdownButton or not DropdownButton.Parent then return end
                    local buttonPos = DropdownButton.AbsolutePosition
                    local buttonSize = DropdownButton.AbsoluteSize
                    Panel.Position = UDim2.fromOffset(buttonPos.X, buttonPos.Y + buttonSize.Y + 3)
                    if DropdownState.IsOpen then
                        Panel.Size = UDim2.fromOffset(buttonSize.X, Panel.Size.Y.Offset)
                    end
                end
                
                local function CreateOptionItem(text, index)
                    local isSelected = multiSelect and table.find(DropdownState.Selected, text) or DropdownState.Selected == text
                    
                    local OptionItem = Instance.new("TextButton")
                    OptionItem.Size = UDim2.new(1, 0, 0, 26)
                    OptionItem.BackgroundColor3 = isSelected and Colors.Accent or Colors.Background
                    OptionItem.BackgroundTransparency = isSelected and 0.1 or 0.5
                    OptionItem.Text = ""
                    OptionItem.AutoButtonColor = false
                    OptionItem.LayoutOrder = index
                    OptionItem.ZIndex = 102
                    OptionItem.Parent = OptionsContainer
                    
                    local OptionCorner = Instance.new("UICorner")
                    OptionCorner.CornerRadius = UDim.new(0, 5)
                    OptionCorner.Parent = OptionItem
                    
                    local OptionText = Instance.new("TextLabel")
                    OptionText.Size = UDim2.new(1, multiSelect and -28 or -12, 1, 0)
                    OptionText.Position = UDim2.new(0, 10, 0, 0)
                    OptionText.BackgroundTransparency = 1
                    OptionText.Text = text
                    OptionText.TextColor3 = isSelected and Colors.Text or Colors.TextDim
                    OptionText.TextSize = 12
                    OptionText.Font = isSelected and Enum.Font.GothamMedium or Enum.Font.Gotham
                    OptionText.TextXAlignment = Enum.TextXAlignment.Left
                    OptionText.ZIndex = 103
                    OptionText.Parent = OptionItem
                    
                    local Checkbox = nil
                    if multiSelect then
                        Checkbox = Instance.new("Frame")
                        Checkbox.Size = UDim2.new(0, 14, 0, 14)
                        Checkbox.Position = UDim2.new(1, -20, 0.5, -7)
                        Checkbox.BackgroundColor3 = isSelected and Colors.Accent or Colors.Border
                        Checkbox.ZIndex = 103
                        Checkbox.Parent = OptionItem
                        
                        local CheckCorner = Instance.new("UICorner")
                        CheckCorner.CornerRadius = UDim.new(0, 3)
                        CheckCorner.Parent = Checkbox
                        
                        if isSelected then
                            local CheckMark = Instance.new("TextLabel")
                            CheckMark.Size = UDim2.new(1, 0, 1, 0)
                            CheckMark.BackgroundTransparency = 1
                            CheckMark.Text = "✓"
                            CheckMark.TextColor3 = Colors.Text
                            CheckMark.TextSize = 10
                            CheckMark.Font = Enum.Font.GothamBold
                            CheckMark.ZIndex = 104
                            CheckMark.Parent = Checkbox
                        end
                    end
                    
                    local conn1 = OptionItem.MouseEnter:Connect(function()
                        Tween(OptionItem, {BackgroundColor3 = Colors.Accent, BackgroundTransparency = 0.3}, 0.15)
                        Tween(OptionText, {TextColor3 = Colors.Text}, 0.15)
                    end)
                    
                    local conn2 = OptionItem.MouseLeave:Connect(function()
                        local sel = multiSelect and table.find(DropdownState.Selected, text) or DropdownState.Selected == text
                        Tween(OptionItem, {BackgroundColor3 = sel and Colors.Accent or Colors.Background, BackgroundTransparency = sel and 0.1 or 0.5}, 0.15)
                        Tween(OptionText, {TextColor3 = sel and Colors.Text or Colors.TextDim}, 0.15)
                    end)
                    
                    local conn3 = OptionItem.MouseButton1Click:Connect(function()
                        if multiSelect then
                            local idx = table.find(DropdownState.Selected, text)
                            if idx then table.remove(DropdownState.Selected, idx) else table.insert(DropdownState.Selected, text) end
                            UpdateSelectedDisplay()
                            RefreshOptions()
                            SafeCallback(callback, DropdownState.Selected)
                            if flag and ConfigSystem.CurrentConfig then ConfigSystem.CurrentConfig[flag] = DropdownState.Selected end
                        else
                            DropdownState.Selected = text
                            UpdateSelectedDisplay()
                            CloseDropdown()
                            SafeCallback(callback, text)
                            if flag and ConfigSystem.CurrentConfig then ConfigSystem.CurrentConfig[flag] = text end
                        end
                    end)
                    
                    table.insert(Connections, conn1)
                    table.insert(Connections, conn2)
                    table.insert(Connections, conn3)
                    OptionItems[text] = {Item = OptionItem, Text = OptionText, Checkbox = Checkbox}
                    return OptionItem
                end
                
                local function FilterOptions(searchText)
                    searchText = string.lower(searchText or "")
                    DropdownState.FilteredOptions = {}
                    for _, option in ipairs(options) do
                        if searchText == "" or string.find(string.lower(option), searchText, 1, true) then
                            table.insert(DropdownState.FilteredOptions, option)
                        end
                    end
                    RefreshOptions()
                end
                
                RefreshOptions = function()
                    for _, data in pairs(OptionItems) do
                        if data.Item and data.Item.Parent then data.Item:Destroy() end
                    end
                    OptionItems = {}
                    for index, option in ipairs(DropdownState.FilteredOptions) do
                        CreateOptionItem(option, index)
                    end
                    local optionCount = math.min(#DropdownState.FilteredOptions, maxVisible)
                    local panelHeight = OptionsOffset + (optionCount * 28) + 12
                    if DropdownState.IsOpen then
                        local buttonWidth = DropdownButton.AbsoluteSize.X
                        Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, panelHeight)}, 0.2)
                    end
                end
                
                UpdateSelectedDisplay = function()
                    if multiSelect then
                        if #DropdownState.Selected == 0 then
                            SelectedText.Text = placeholder
                            SelectedText.TextColor3 = Colors.TextDim
                        elseif #DropdownState.Selected == 1 then
                            SelectedText.Text = DropdownState.Selected[1]
                            SelectedText.TextColor3 = Colors.Accent
                        else
                            SelectedText.Text = #DropdownState.Selected .. " selected"
                            SelectedText.TextColor3 = Colors.Accent
                        end
                    else
                        SelectedText.Text = DropdownState.Selected or placeholder
                        SelectedText.TextColor3 = DropdownState.Selected and Colors.Accent or Colors.TextDim
                    end
                end
                
                OpenDropdown = function()
                    if DropdownState.IsOpen then return end
                    DropdownState.IsOpen = true
                    Panel.Visible = true
                    UpdatePanelPosition()
                    local optionCount = math.min(#DropdownState.FilteredOptions, maxVisible)
                    local targetHeight = OptionsOffset + (optionCount * 28) + 12
                    local buttonWidth = DropdownButton.AbsoluteSize.X
                    Panel.Size = UDim2.fromOffset(buttonWidth, 0)
                    Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, targetHeight)}, 0.25, Enum.EasingStyle.Quart)
                    Tween(Arrow, {Rotation = 180, TextColor3 = Colors.Accent}, 0.2)
                    Tween(DropdownButton, {BackgroundColor3 = Colors.Border}, 0.2)
                    if SearchBox then task.wait(0.25) if SearchBox.Parent then SearchBox:CaptureFocus() end end
                end
                
                CloseDropdown = function()
                    if not DropdownState.IsOpen then return end
                    DropdownState.IsOpen = false
                    local buttonWidth = DropdownButton.AbsoluteSize.X
                    Tween(Panel, {Size = UDim2.fromOffset(buttonWidth, 0)}, 0.2, Enum.EasingStyle.Quart)
                    Tween(Arrow, {Rotation = 0, TextColor3 = Colors.TextDim}, 0.2)
                    Tween(DropdownButton, {BackgroundColor3 = Colors.Background}, 0.2)
                    task.delay(0.2, function() if not DropdownState.IsOpen then Panel.Visible = false end end)
                    if SearchBox then SearchBox.Text = "" DropdownState.FilteredOptions = options end
                end
                
                CloseButton.MouseEnter:Connect(function()
                    Tween(CloseButtonFrame, {BackgroundColor3 = Colors.Accent}, 0.15)
                    Tween(CloseIcon, {TextColor3 = Colors.Text}, 0.15)
                    Tween(CloseText, {TextColor3 = Colors.Text}, 0.15)
                end)
                CloseButton.MouseLeave:Connect(function()
                    Tween(CloseButtonFrame, {BackgroundColor3 = Colors.Border}, 0.15)
                    Tween(CloseIcon, {TextColor3 = closeColor}, 0.15)
                    Tween(CloseText, {TextColor3 = closeColor}, 0.15)
                end)
                CloseButton.MouseButton1Click:Connect(CloseDropdown)
                
                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local searchText = SearchBox.Text
                        task.delay(0.15, function()
                            if SearchBox and SearchBox.Parent and SearchBox.Text == searchText then
                                FilterOptions(searchText)
                            end
                        end)
                    end)
                end
                
                DropdownButton.MouseButton1Click:Connect(function()
                    if DropdownState.IsOpen then CloseDropdown() else OpenDropdown() end
                end)
                
                DropdownButton.MouseEnter:Connect(function()
                    if not DropdownState.IsOpen then Tween(DropdownButton, {BackgroundColor3 = Colors.Border}, 0.2) end
                end)
                DropdownButton.MouseLeave:Connect(function()
                    if not DropdownState.IsOpen then Tween(DropdownButton, {BackgroundColor3 = Colors.Background}, 0.2) end
                end)
                
                local clickOutsideConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and DropdownState.IsOpen then
                        local mouse = Players.LocalPlayer:GetMouse()
                        local mouseX, mouseY = mouse.X, mouse.Y
                        local buttonPos = DropdownButton.AbsolutePosition
                        local buttonSize = DropdownButton.AbsoluteSize
                        local onButton = mouseX >= buttonPos.X and mouseX <= buttonPos.X + buttonSize.X and mouseY >= buttonPos.Y and mouseY <= buttonPos.Y + buttonSize.Y
                        local onPanel = false
                        if Panel.Visible then
                            local panelPos = Panel.AbsolutePosition
                            local panelSize = Panel.AbsoluteSize
                            onPanel = mouseX >= panelPos.X and mouseX <= panelPos.X + panelSize.X and mouseY >= panelPos.Y and mouseY <= panelPos.Y + panelSize.Y
                        end
                        if not onButton and not onPanel then CloseDropdown() end
                    end
                end)
                table.insert(Connections, clickOutsideConn)
                
                local escConn = UserInputService.InputBegan:Connect(function(input)
                    if input.KeyCode == Enum.KeyCode.Escape and DropdownState.IsOpen then CloseDropdown() end
                end)
                table.insert(Connections, escConn)
                
                local renderConn = game:GetService("RunService").RenderStepped:Connect(function()
                    if DropdownState.IsOpen and Panel.Visible then UpdatePanelPosition() end
                end)
                table.insert(Connections, renderConn)
                
                -- Monitor collapsible state
                local collapsibleMonitor = game:GetService("RunService").RenderStepped:Connect(function()
                    if DropdownState.IsOpen then
                        local isVisible = Container.Visible and DropdownButton.Visible
                        local checkParent = Container.Parent
                        while checkParent and checkParent ~= ScreenGui do
                            if checkParent:IsA("GuiObject") and not checkParent.Visible then
                                isVisible = false
                                break
                            end
                            if checkParent.ClipsDescendants then
                                local btnBottom = DropdownButton.AbsolutePosition.Y + DropdownButton.AbsoluteSize.Y
                                local parentBottom = checkParent.AbsolutePosition.Y + checkParent.AbsoluteSize.Y
                                if btnBottom > parentBottom + 5 then isVisible = false break end
                            end
                            checkParent = checkParent.Parent
                        end
                        if not isVisible then CloseDropdown() end
                    end
                end)
                table.insert(Connections, collapsibleMonitor)
                
                DropdownState.FilteredOptions = options
                RefreshOptions()
                UpdateSelectedDisplay()
                
                local dropdownObj = {
                    SetValue = function(value, silent)
                        if multiSelect then DropdownState.Selected = type(value) == "table" and value or {}
                        else DropdownState.Selected = value end
                        UpdateSelectedDisplay()
                        RefreshOptions()
                        if not silent then
                            SafeCallback(callback, DropdownState.Selected)
                            if flag and ConfigSystem.CurrentConfig then ConfigSystem.CurrentConfig[flag] = DropdownState.Selected end
                        end
                    end,
                    GetValue = function() return DropdownState.Selected end,
                    SetOptions = function(newOptions)
                        options = newOptions or {}
                        DropdownState.FilteredOptions = options
                        RefreshOptions()
                        if multiSelect then
                            local valid = {}
                            for _, sel in ipairs(DropdownState.Selected) do if table.find(options, sel) then table.insert(valid, sel) end end
                            DropdownState.Selected = valid
                        else
                            if not table.find(options, DropdownState.Selected) then DropdownState.Selected = options[1] end
                        end
                        UpdateSelectedDisplay()
                    end,
                    Refresh = function(newOptions) dropdownObj.SetOptions(newOptions) end,
                    Open = function() OpenDropdown() end,
                    Close = function() CloseDropdown() end,
                    SetVisible = function(visible)
                        Container.Visible = visible
                        if not visible and DropdownState.IsOpen then CloseDropdown() end
                    end,
                    Destroy = function()
                        CloseDropdown()
                        for _, conn in ipairs(Connections) do if conn.Connected then conn:Disconnect() end end
                        if Container.Parent then Container:Destroy() end
                        if Panel.Parent then Panel:Destroy() end
                    end,
                    Instance = Container
                }
                
                if flag and ConfigSystem and ConfigSystem.Flags then
                    ConfigSystem.Flags[flag] = {
                        Type = "Dropdown",
                        Set = function(value) dropdownObj.SetValue(value) end,
                        Get = function() return DropdownState.Selected end
                    }
                    if ConfigSystem.CurrentConfig then ConfigSystem.CurrentConfig[flag] = DropdownState.Selected end
                end
                
                return dropdownObj
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddTextbox
            -- ═══════════════════════════════════════════
            function Collapsible:AddTextbox(config)
                config = config or {}
                local textboxText = config.Name or "Textbox"
                local placeholder = config.Placeholder or "Enter text..."
                local default = config.Default or ""
                local callback = config.Callback or function() end
                
                local TextboxFrame = Instance.new("Frame")
                TextboxFrame.Size = UDim2.new(1, 0, 0, 60)
                TextboxFrame.BackgroundColor3 = Colors.Background
                TextboxFrame.BorderSizePixel = 0
                TextboxFrame.Parent = ContentFrame
                
                local TextboxCorner = Instance.new("UICorner")
                TextboxCorner.CornerRadius = UDim.new(0, 6)
                TextboxCorner.Parent = TextboxFrame
                
                local TextboxLabel = Instance.new("TextLabel")
                TextboxLabel.Size = UDim2.new(1, -20, 0, 18)
                TextboxLabel.Position = UDim2.new(0, 10, 0, 4)
                TextboxLabel.BackgroundTransparency = 1
                TextboxLabel.Text = textboxText
                TextboxLabel.TextColor3 = Colors.Text
                TextboxLabel.TextSize = 13
                TextboxLabel.Font = Enum.Font.Gotham
                TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextboxLabel.Parent = TextboxFrame
                
                local Textbox = Instance.new("TextBox")
                Textbox.Size = UDim2.new(1, -20, 0, 28)
                Textbox.Position = UDim2.new(0, 10, 0, 26)
                Textbox.BackgroundColor3 = Colors.Tertiary
                Textbox.BorderSizePixel = 0
                Textbox.PlaceholderText = placeholder
                Textbox.PlaceholderColor3 = Colors.TextDim
                Textbox.Text = default
                Textbox.TextColor3 = Colors.Text
                Textbox.TextSize = 12
                Textbox.Font = Enum.Font.Gotham
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = TextboxFrame
                
                local TextboxInnerCorner = Instance.new("UICorner")
                TextboxInnerCorner.CornerRadius = UDim.new(0, 4)
                TextboxInnerCorner.Parent = Textbox
                
                local TextboxPadding = Instance.new("UIPadding")
                TextboxPadding.PaddingLeft = UDim.new(0, 8)
                TextboxPadding.PaddingRight = UDim.new(0, 8)
                TextboxPadding.Parent = Textbox
                
                Textbox.FocusLost:Connect(function(enterPressed)
                    SafeCallback(callback, Textbox.Text, enterPressed)
                end)
                
                return {
                    SetValue = function(text)
                        Textbox.Text = text
                    end,
                    GetValue = function()
                        return Textbox.Text
                    end,
                    SetVisible = function(visible)
                        TextboxFrame.Visible = visible
                    end,
                    Instance = TextboxFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddKeybind
            -- ═══════════════════════════════════════════
            function Collapsible:AddKeybind(config)
                config = config or {}
                local keybindText = config.Name or "Keybind"
                local default = config.Default or Enum.KeyCode.Unknown
                local callback = config.Callback or function() end
                local flag = config.Flag
                
                local KeybindFrame = Instance.new("Frame")
                KeybindFrame.Size = UDim2.new(1, 0, 0, 35)
                KeybindFrame.BackgroundColor3 = Colors.Background
                KeybindFrame.BorderSizePixel = 0
                KeybindFrame.Parent = ContentFrame
                
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 6)
                KeybindCorner.Parent = KeybindFrame
                
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Size = UDim2.new(1, -80, 1, 0)
                KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.Text = keybindText
                KeybindLabel.TextColor3 = Colors.Text
                KeybindLabel.TextSize = 13
                KeybindLabel.Font = Enum.Font.Gotham
                KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                KeybindLabel.Parent = KeybindFrame
                
                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(0, 65, 0, 24)
                KeybindButton.Position = UDim2.new(1, -72, 0.5, -12)
                KeybindButton.BackgroundColor3 = Colors.Tertiary
                KeybindButton.BorderSizePixel = 0
                KeybindButton.Text = default ~= Enum.KeyCode.Unknown and default.Name or "None"
                KeybindButton.TextColor3 = Colors.Text
                KeybindButton.TextSize = 11
                KeybindButton.Font = Enum.Font.Gotham
                KeybindButton.Parent = KeybindFrame
                
                local KeybindButtonCorner = Instance.new("UICorner")
                KeybindButtonCorner.CornerRadius = UDim.new(0, 4)
                KeybindButtonCorner.Parent = KeybindButton
                
                local listening = false
                local currentKey = default
                
                KeybindButton.MouseButton1Click:Connect(function()
                    listening = true
                    KeybindButton.Text = "..."
                    Tween(KeybindButton, {BackgroundColor3 = Colors.Accent}, 0.2)
                end)
                
                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    
                    if listening then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            listening = false
                            currentKey = input.KeyCode
                            KeybindButton.Text = currentKey.Name
                            Tween(KeybindButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                            SafeCallback(callback, currentKey)
                            
                            if flag and ConfigSystem.CurrentConfig then
                                ConfigSystem.CurrentConfig[flag] = currentKey.Name
                            end
                        end
                    else
                        if input.KeyCode == currentKey then
                            SafeCallback(callback, currentKey)
                        end
                    end
                end)
                
                local keybindObj = {
                    SetValue = function(keyCode)
                        currentKey = keyCode
                        KeybindButton.Text = keyCode ~= Enum.KeyCode.Unknown and keyCode.Name or "None"
                    end,
                    SetVisible = function(visible)
                        KeybindFrame.Visible = visible
                    end,
                    Instance = KeybindFrame
                }
                
                if flag and ConfigSystem and ConfigSystem.Flags then
                    ConfigSystem.Flags[flag] = {
                        Type = "Keybind",
                        Set = function(keyName)
                            local keyCode = Enum.KeyCode[keyName]
                            if keyCode then keybindObj.SetValue(keyCode) end
                        end,
                        Get = function() return currentKey.Name end
                    }
                end
                
                return keybindObj
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddColorPicker
            -- ═══════════════════════════════════════════
            function Collapsible:AddColorPicker(config)
                config = config or {}
                local pickerText = config.Name or "Color"
                local default = config.Default or Color3.fromRGB(255, 255, 255)
                local callback = config.Callback or function() end
                
                local ColorFrame = Instance.new("Frame")
                ColorFrame.Size = UDim2.new(1, 0, 0, 35)
                ColorFrame.BackgroundColor3 = Colors.Background
                ColorFrame.BorderSizePixel = 0
                ColorFrame.ClipsDescendants = true
                ColorFrame.Parent = ContentFrame
                
                local ColorCorner = Instance.new("UICorner")
                ColorCorner.CornerRadius = UDim.new(0, 6)
                ColorCorner.Parent = ColorFrame
                
                local ColorLabel = Instance.new("TextLabel")
                ColorLabel.Size = UDim2.new(1, -50, 0, 35)
                ColorLabel.Position = UDim2.new(0, 10, 0, 0)
                ColorLabel.BackgroundTransparency = 1
                ColorLabel.Text = pickerText
                ColorLabel.TextColor3 = Colors.Text
                ColorLabel.TextSize = 13
                ColorLabel.Font = Enum.Font.Gotham
                ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
                ColorLabel.Parent = ColorFrame
                
                local ColorPreview = Instance.new("TextButton")
                ColorPreview.Size = UDim2.new(0, 30, 0, 22)
                ColorPreview.Position = UDim2.new(1, -40, 0.5, -11)
                ColorPreview.BackgroundColor3 = default
                ColorPreview.BorderSizePixel = 0
                ColorPreview.Text = ""
                ColorPreview.Parent = ColorFrame
                
                local PreviewCorner = Instance.new("UICorner")
                PreviewCorner.CornerRadius = UDim.new(0, 4)
                PreviewCorner.Parent = ColorPreview
                
                local PreviewStroke = Instance.new("UIStroke")
                PreviewStroke.Color = Colors.Border
                PreviewStroke.Thickness = 1
                PreviewStroke.Parent = ColorPreview
                
                local PickerPanel = Instance.new("Frame")
                PickerPanel.Size = UDim2.new(1, -10, 0, 100)
                PickerPanel.Position = UDim2.new(0, 5, 0, 38)
                PickerPanel.BackgroundColor3 = Colors.Tertiary
                PickerPanel.BorderSizePixel = 0
                PickerPanel.Visible = false
                PickerPanel.Parent = ColorFrame
                
                local PanelCorner = Instance.new("UICorner")
                PanelCorner.CornerRadius = UDim.new(0, 4)
                PanelCorner.Parent = PickerPanel
                
                local currentColor = {R = default.R * 255, G = default.G * 255, B = default.B * 255}
                local isOpen = false
                
                local function createColorSlider(name, yPos, defaultVal)
                    local SliderLabel = Instance.new("TextLabel")
                    SliderLabel.Size = UDim2.new(0, 15, 0, 20)
                    SliderLabel.Position = UDim2.new(0, 8, 0, yPos)
                    SliderLabel.BackgroundTransparency = 1
                    SliderLabel.Text = name
                    SliderLabel.TextColor3 = Colors.Text
                    SliderLabel.TextSize = 11
                    SliderLabel.Font = Enum.Font.GothamBold
                    SliderLabel.Parent = PickerPanel
                    
                    local SliderBar = Instance.new("Frame")
                    SliderBar.Size = UDim2.new(1, -70, 0, 6)
                    SliderBar.Position = UDim2.new(0, 28, 0, yPos + 7)
                    SliderBar.BackgroundColor3 = Colors.Border
                    SliderBar.Parent = PickerPanel
                    
                    local SliderBarCorner = Instance.new("UICorner")
                    SliderBarCorner.CornerRadius = UDim.new(1, 0)
                    SliderBarCorner.Parent = SliderBar
                    
                    local SliderFill = Instance.new("Frame")
                    SliderFill.Size = UDim2.new(defaultVal / 255, 0, 1, 0)
                    SliderFill.BackgroundColor3 = name == "R" and Color3.fromRGB(255, 100, 100) or (name == "G" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 100, 255))
                    SliderFill.Parent = SliderBar
                    
                    local FillCorner = Instance.new("UICorner")
                    FillCorner.CornerRadius = UDim.new(1, 0)
                    FillCorner.Parent = SliderFill
                    
                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Size = UDim2.new(0, 30, 0, 20)
                    ValueLabel.Position = UDim2.new(1, -35, 0, yPos)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.Text = tostring(math.floor(defaultVal))
                    ValueLabel.TextColor3 = Colors.TextDim
                    ValueLabel.TextSize = 10
                    ValueLabel.Font = Enum.Font.Gotham
                    ValueLabel.Parent = PickerPanel
                    
                    local SliderButton = Instance.new("TextButton")
                    SliderButton.Size = UDim2.new(1, 0, 1, 8)
                    SliderButton.Position = UDim2.new(0, 0, 0, -4)
                    SliderButton.BackgroundTransparency = 1
                    SliderButton.Text = ""
                    SliderButton.Parent = SliderBar
                    
                    local dragging = false
                    
                    SliderButton.MouseButton1Down:Connect(function()
                        dragging = true
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    
                    local function updateSlider(input)
                        local percentage = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                        local value = math.floor(percentage * 255)
                        
                        currentColor[name] = value
                        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                        ValueLabel.Text = tostring(value)
                        
                        local newColor = Color3.fromRGB(currentColor.R, currentColor.G, currentColor.B)
                        ColorPreview.BackgroundColor3 = newColor
                        SafeCallback(callback, newColor)
                    end
                    
                    SliderButton.MouseButton1Click:Connect(function()
                        local mouse = UserInputService:GetMouseLocation()
                        updateSlider({Position = Vector2.new(mouse.X, mouse.Y)})
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            updateSlider(input)
                        end
                    end)
                end
                
                createColorSlider("R", 8, currentColor.R)
                createColorSlider("G", 38, currentColor.G)
                createColorSlider("B", 68, currentColor.B)
                
                ColorPreview.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    
                    if isOpen then
                        PickerPanel.Visible = true
                        Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, 145)}, 0.3)
                    else
                        Tween(ColorFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.3)
                        task.wait(0.3)
                        PickerPanel.Visible = false
                    end
                end)
                
                return {
                    SetValue = function(color)
                        currentColor = {R = color.R * 255, G = color.G * 255, B = color.B * 255}
                        ColorPreview.BackgroundColor3 = color
                        SafeCallback(callback, color)
                    end,
                    SetVisible = function(visible)
                        ColorFrame.Visible = visible
                    end,
                    Instance = ColorFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddLabel
            -- ═══════════════════════════════════════════
            function Collapsible:AddLabel(text)
                local LabelFrame = Instance.new("Frame")
                LabelFrame.Size = UDim2.new(1, 0, 0, 25)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.Parent = ContentFrame
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -10, 1, 0)
                Label.Position = UDim2.new(0, 5, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Colors.TextDim
                Label.TextSize = 12
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextWrapped = true
                Label.Parent = LabelFrame
                
                return {
                    SetText = function(newText)
                        Label.Text = newText
                    end,
                    SetVisible = function(visible)
                        LabelFrame.Visible = visible
                    end,
                    Instance = LabelFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddDivider
            -- ═══════════════════════════════════════════
            function Collapsible:AddDivider(text)
                local DividerFrame = Instance.new("Frame")
                DividerFrame.Size = UDim2.new(1, 0, 0, 15)
                DividerFrame.BackgroundTransparency = 1
                DividerFrame.Parent = ContentFrame
                
                if text then
                    local DividerLabel = Instance.new("TextLabel")
                    DividerLabel.Size = UDim2.new(0, 0, 1, 0)
                    DividerLabel.Position = UDim2.new(0, 0, 0, 0)
                    DividerLabel.BackgroundTransparency = 1
                    DividerLabel.Text = text
                    DividerLabel.TextColor3 = Colors.TextDim
                    DividerLabel.TextSize = 10
                    DividerLabel.Font = Enum.Font.GothamBold
                    DividerLabel.TextXAlignment = Enum.TextXAlignment.Left
                    DividerLabel.Parent = DividerFrame
                    
                    task.wait()
                    DividerLabel.Size = UDim2.new(0, DividerLabel.TextBounds.X + 5, 1, 0)
                    
                    local Line = Instance.new("Frame")
                    Line.Size = UDim2.new(1, -(DividerLabel.TextBounds.X + 10), 0, 1)
                    Line.Position = UDim2.new(0, DividerLabel.TextBounds.X + 8, 0.5, 0)
                    Line.BackgroundColor3 = Colors.Border
                    Line.BorderSizePixel = 0
                    Line.Parent = DividerFrame
                else
                    local Line = Instance.new("Frame")
                    Line.Size = UDim2.new(1, 0, 0, 1)
                    Line.Position = UDim2.new(0, 0, 0.5, 0)
                    Line.BackgroundColor3 = Colors.Border
                    Line.BorderSizePixel = 0
                    Line.Parent = DividerFrame
                end
                
                return {
                    SetVisible = function(visible)
                        DividerFrame.Visible = visible
                    end,
                    Instance = DividerFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddParagraph
            -- ═══════════════════════════════════════════
            function Collapsible:AddParagraph(config)
                config = config or {}
                local title = config.Title or "Info"
                local content = config.Content or "Content here"
                
                local ParagraphFrame = Instance.new("Frame")
                ParagraphFrame.Size = UDim2.new(1, 0, 0, 10)
                ParagraphFrame.BackgroundColor3 = Colors.Tertiary
                ParagraphFrame.BorderSizePixel = 0
                ParagraphFrame.Parent = ContentFrame
                
                local ParagraphCorner = Instance.new("UICorner")
                ParagraphCorner.CornerRadius = UDim.new(0, 4)
                ParagraphCorner.Parent = ParagraphFrame
                
                local ParagraphTitle = Instance.new("TextLabel")
                ParagraphTitle.Size = UDim2.new(1, -16, 0, 18)
                ParagraphTitle.Position = UDim2.new(0, 8, 0, 5)
                ParagraphTitle.BackgroundTransparency = 1
                ParagraphTitle.Text = title
                ParagraphTitle.TextColor3 = Colors.Text
                ParagraphTitle.TextSize = 12
                ParagraphTitle.Font = Enum.Font.GothamBold
                ParagraphTitle.TextXAlignment = Enum.TextXAlignment.Left
                ParagraphTitle.Parent = ParagraphFrame
                
                local ParagraphContent = Instance.new("TextLabel")
                ParagraphContent.Size = UDim2.new(1, -16, 0, 1000)
                ParagraphContent.Position = UDim2.new(0, 8, 0, 25)
                ParagraphContent.BackgroundTransparency = 1
                ParagraphContent.Text = content
                ParagraphContent.TextColor3 = Colors.TextDim
                ParagraphContent.TextSize = 11
                ParagraphContent.Font = Enum.Font.Gotham
                ParagraphContent.TextXAlignment = Enum.TextXAlignment.Left
                ParagraphContent.TextYAlignment = Enum.TextYAlignment.Top
                ParagraphContent.TextWrapped = true
                ParagraphContent.Parent = ParagraphFrame
                
                task.wait()
                ParagraphContent.Size = UDim2.new(1, -16, 0, ParagraphContent.TextBounds.Y)
                ParagraphFrame.Size = UDim2.new(1, 0, 0, 35 + ParagraphContent.TextBounds.Y)
                
                return {
                    SetTitle = function(newTitle)
                        ParagraphTitle.Text = newTitle
                    end,
                    SetContent = function(newContent)
                        ParagraphContent.Text = newContent
                        task.wait()
                        ParagraphContent.Size = UDim2.new(1, -16, 0, ParagraphContent.TextBounds.Y)
                        ParagraphFrame.Size = UDim2.new(1, 0, 0, 35 + ParagraphContent.TextBounds.Y)
                    end,
                    SetVisible = function(visible)
                        ParagraphFrame.Visible = visible
                    end,
                    Instance = ParagraphFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddSection
            -- ═══════════════════════════════════════════
            function Collapsible:AddSection(sectionName)
                local SectionFrame = Instance.new("Frame")
                SectionFrame.Size = UDim2.new(1, 0, 0, 28)
                SectionFrame.BackgroundTransparency = 1
                SectionFrame.Parent = ContentFrame
                
                local SectionLabel = Instance.new("TextLabel")
                SectionLabel.Size = UDim2.new(1, -5, 0, 18)
                SectionLabel.Position = UDim2.new(0, 0, 0, 2)
                SectionLabel.BackgroundTransparency = 1
                SectionLabel.Text = sectionName
                SectionLabel.TextColor3 = Colors.Text
                SectionLabel.TextSize = 12
                SectionLabel.Font = Enum.Font.GothamBold
                SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
                SectionLabel.Parent = SectionFrame
                
                local SectionLine = Instance.new("Frame")
                SectionLine.Size = UDim2.new(1, 0, 0, 2)
                SectionLine.Position = UDim2.new(0, 0, 1, -4)
                SectionLine.BackgroundColor3 = Colors.Accent
                SectionLine.BorderSizePixel = 0
                SectionLine.Parent = SectionFrame
                
                local SectionLineCorner = Instance.new("UICorner")
                SectionLineCorner.CornerRadius = UDim.new(1, 0)
                SectionLineCorner.Parent = SectionLine
                
                return {
                    SetText = function(newText)
                        SectionLabel.Text = newText
                    end,
                    SetVisible = function(visible)
                        SectionFrame.Visible = visible
                    end,
                    Instance = SectionFrame
                }
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddSearchDropdown (uses Modern AddDropdown with Search)
            -- ═══════════════════════════════════════════
            function Collapsible:AddSearchDropdown(config)
                config = config or {}
                return Collapsible:AddDropdown({
                    Name = config.Name or "Search Dropdown",
                    Options = config.Options or {"Option 1", "Option 2", "Option 3"},
                    Default = config.Default,
                    Callback = config.Callback or function() end,
                    Flag = config.Flag,
                    Search = true,
                    MultiSelect = false,
                    MaxVisible = config.MaxVisible or 5,
                    Placeholder = config.Placeholder or "Select option..."
                })
            end
            
            -- ═══════════════════════════════════════════
            -- COLLAPSIBLE: AddMultiDropdown (uses Modern AddDropdown with MultiSelect)
            -- ═══════════════════════════════════════════
            function Collapsible:AddMultiDropdown(config)
                config = config or {}
                return Collapsible:AddDropdown({
                    Name = config.Name or "Multi Dropdown",
                    Options = config.Options or {"Option 1", "Option 2", "Option 3"},
                    Default = config.Default or {},
                    Callback = config.Callback or function() end,
                    Flag = config.Flag,
                    Search = config.Search or false,
                    MultiSelect = true,
                    MaxVisible = config.MaxVisible or 5,
                    Placeholder = config.Placeholder or "Select options..."
                })
            end
            
            return Collapsible
        end
        
        -- ═══════════════════════════════════════════
        -- MULTI SELECT DROPDOWN (uses Modern Dropdown with MultiSelect enabled)
        -- ═══════════════════════════════════════════
        function Tab:CreateMultiDropdown(config)
            config = config or {}
            -- Use the modern dropdown with MultiSelect enabled
            return Tab:CreateDropdown({
                Name = config.Name or "Multi Dropdown",
                Options = config.Options or {"Option 1", "Option 2", "Option 3"},
                Default = config.Default or {},
                Callback = config.Callback or function() end,
                Flag = config.Flag,
                Search = config.Search or false,
                MultiSelect = true,  -- Enable multi-select
                MaxVisible = config.MaxVisible or 6,
                Placeholder = config.Placeholder or "Select options..."
            })
        end
        
        return Tab
    end
    
    function Window:Destroy()
        ScreenGui:Destroy()
    end
    
    -- Notification Function
    function Window:Notify(config)
        CreateNotification(config)
    end
    
    -- Config System
    function Window:SaveConfig(configName)
        return SaveConfig(configName, ConfigSystem.Flags)
    end
    
    function Window:LoadConfig(configName)
        return LoadConfig(configName, ConfigSystem.Flags)
    end
    
    function Window:DeleteConfig(configName)
        return DeleteConfig(configName)
    end
    
    function Window:GetConfigs()
        return GetConfigList()
    end
    
    function Window:AutoLoadConfig(configName)
        task.wait(0.5)
        if isfile(ConfigFolder .. "/" .. configName .. ".json") then
            LoadConfig(configName, ConfigSystem.Flags)
        end
    end
    
    -- Create Config Tab
    function Window:AddConfigTab()
        local ConfigTab = self:CreateTab("⚙️ Config")
        
        ConfigTab:CreateSection("Configuration Manager")
        
        ConfigTab:CreateParagraph({
            Title = "About Configs",
            Content = "Save and load your settings easily. Configs are stored locally on your executor."
        })
        
        ConfigTab:CreateDivider()
        
        local configName = ""
        
        ConfigTab:CreateTextbox({
            Name = "Config Name",
            Placeholder = "Enter config name...",
            Callback = function(text)
                configName = text
            end
        })
        
        ConfigTab:CreateButton({
            Name = "💾 Save Config",
            Callback = function()
                if configName ~= "" then
                    self:SaveConfig(configName)
                else
                    CreateNotification({
                        Title = "Error",
                        Content = "Please enter a config name first!",
                        Duration = 3,
                        Type = "Error"
                    })
                end
            end
        })
        
        ConfigTab:CreateDivider()
        
        local configList = self:GetConfigs()
        local selectedConfig = configList[1] or "None"
        
        local configDropdown = ConfigTab:CreateDropdown({
            Name = "Select Config",
            Options = #configList > 0 and configList or {"No configs found"},
            Default = selectedConfig,
            Callback = function(selected)
                selectedConfig = selected
            end
        })
        
        ConfigTab:CreateButton({
            Name = "📂 Load Config",
            Callback = function()
                if selectedConfig and selectedConfig ~= "No configs found" then
                    self:LoadConfig(selectedConfig)
                else
                    CreateNotification({
                        Title = "Error",
                        Content = "No config selected!",
                        Duration = 3,
                        Type = "Error"
                    })
                end
            end
        })
        
        ConfigTab:CreateButton({
            Name = "🗑️ Delete Config",
            Callback = function()
                if selectedConfig and selectedConfig ~= "No configs found" then
                    self:DeleteConfig(selectedConfig)
                    
                    -- Refresh dropdown
                    local newConfigList = self:GetConfigs()
                    configDropdown:Refresh(#newConfigList > 0 and newConfigList or {"No configs found"})
                else
                    CreateNotification({
                        Title = "Error",
                        Content = "No config selected!",
                        Duration = 3,
                        Type = "Error"
                    })
                end
            end
        })
        
        ConfigTab:CreateButton({
            Name = "🔄 Refresh List",
            Callback = function()
                local newConfigList = self:GetConfigs()
                configDropdown:Refresh(#newConfigList > 0 and newConfigList or {"No configs found"})
                CreateNotification({
                    Title = "Refreshed",
                    Content = "Config list has been refreshed!",
                    Duration = 2,
                    Type = "Success"
                })
            end
        })
        
        ConfigTab:CreateDivider()
        
        ConfigTab:CreateLabel("💡 Tip: Configs auto-save all your settings including toggles, sliders, and dropdowns.")
    end
    
    return Window
end

return FluxUI
