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
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        ScreenGui:Destroy()
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
            
            return Button
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
                end
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
                end
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
                end
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
                end
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
                end
            }
        end
        
        function Tab:CreateDropdown(config)
            config = config or {}
            local dropdownText = config.Name or "Dropdown"
            local options = config.Options or {"Option 1", "Option 2"}
            local default = config.Default or options[1]
            local callback = config.Callback or function() end
            local flag = config.Flag
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Colors.Tertiary
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 8)
            DropdownCorner.Parent = DropdownFrame
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 40)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.Parent = DropdownFrame
            
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(1, -60, 0, 40)
            DropdownLabel.Position = UDim2.new(0, 15, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = dropdownText .. ": " .. default
            DropdownLabel.TextColor3 = Colors.Text
            DropdownLabel.TextSize = 14
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame
            
            local DropdownIcon = Instance.new("TextLabel")
            DropdownIcon.Size = UDim2.new(0, 20, 0, 40)
            DropdownIcon.Position = UDim2.new(1, -30, 0, 0)
            DropdownIcon.BackgroundTransparency = 1
            DropdownIcon.Text = "▼"
            DropdownIcon.TextColor3 = Colors.TextDim
            DropdownIcon.TextSize = 12
            DropdownIcon.Font = Enum.Font.Gotham
            DropdownIcon.Parent = DropdownFrame
            
            local OptionsList = Instance.new("Frame")
            OptionsList.Size = UDim2.new(1, -10, 0, #options * 35)
            OptionsList.Position = UDim2.new(0, 5, 0, 45)
            OptionsList.BackgroundTransparency = 1
            OptionsList.Parent = DropdownFrame
            
            local OptionsListLayout = Instance.new("UIListLayout")
            OptionsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsListLayout.Padding = UDim.new(0, 5)
            OptionsListLayout.Parent = OptionsList
            
            local isOpen = false
            local currentOption = default
            
            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50 + #options * 35)}, 0.3)
                    Tween(DropdownIcon, {Rotation = 180}, 0.3)
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Tween(DropdownIcon, {Rotation = 0}, 0.3)
                end
            end)
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, 0, 0, 30)
                OptionButton.BackgroundColor3 = Colors.Background
                OptionButton.BorderSizePixel = 0
                OptionButton.Text = option
                OptionButton.TextColor3 = Colors.Text
                OptionButton.TextSize = 13
                OptionButton.Font = Enum.Font.Gotham
                OptionButton.ZIndex = 6  -- Higher ZIndex
                OptionButton.Parent = OptionsList
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 6)
                OptionCorner.Parent = OptionButton
                
                OptionButton.MouseButton1Click:Connect(function()
                    currentOption = option
                    DropdownLabel.Text = dropdownText .. ": " .. option
                    
                    isOpen = false
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Tween(DropdownIcon, {Rotation = 0}, 0.3)
                    
                    SafeCallback(callback, option)
                    
                    if flag and ConfigSystem.CurrentConfig then
                        ConfigSystem.CurrentConfig[flag] = option
                    end
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Colors.Accent}, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Colors.Background}, 0.2)
                end)
            end
            
            local dropdownObj = {
                SetValue = function(option)
                    if table.find(options, option) then
                        currentOption = option
                        DropdownLabel.Text = dropdownText .. ": " .. option
                        SafeCallback(callback, option)
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = option
                        end
                    end
                end,
                Refresh = function(newOptions)
                    options = newOptions
                    
                    -- Destroy old option buttons
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    
                    -- Create new option buttons
                    for _, option in ipairs(options) do
                        local OptionButton = Instance.new("TextButton")
                        OptionButton.Size = UDim2.new(1, 0, 0, 30)
                        OptionButton.BackgroundColor3 = Colors.Background
                        OptionButton.BorderSizePixel = 0
                        OptionButton.Text = option
                        OptionButton.TextColor3 = Colors.Text
                        OptionButton.TextSize = 13
                        OptionButton.Font = Enum.Font.Gotham
                        OptionButton.ZIndex = 6
                        OptionButton.Parent = OptionsList
                        
                        local OptionCorner = Instance.new("UICorner")
                        OptionCorner.CornerRadius = UDim.new(0, 6)
                        OptionCorner.Parent = OptionButton
                        
                        OptionButton.MouseButton1Click:Connect(function()
                            currentOption = option
                            DropdownLabel.Text = dropdownText .. ": " .. option
                            
                            isOpen = false
                            Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                            Tween(DropdownIcon, {Rotation = 0}, 0.3)
                            
                            SafeCallback(callback, option)
                            
                            if flag and ConfigSystem.CurrentConfig then
                                ConfigSystem.CurrentConfig[flag] = option
                            end
                        end)
                        
                        -- Add hover effects (FIXED!)
                        OptionButton.MouseEnter:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Colors.Accent}, 0.2)
                        end)
                        
                        OptionButton.MouseLeave:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Colors.Background}, 0.2)
                        end)
                    end
                    
                    -- Update OptionsList size
                    OptionsList.Size = UDim2.new(1, -10, 0, #options * 35)
                    
                    -- Update DropdownFrame size if currently open (FIXED!)
                    if isOpen then
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50 + #options * 35)}, 0.3)
                    end
                    
                    -- Reset label if current option not in new options
                    if not table.find(options, currentOption) then
                        currentOption = options[1] or "Select"
                        DropdownLabel.Text = dropdownText .. ": " .. currentOption
                    end
                end,
                SetOptions = function(newOptions)
                    -- Alias for Refresh (untuk konsistensi dengan Collapsible)
                    dropdownObj.Refresh(newOptions)
                end
            }
            
            -- Register flag
            if flag and ConfigSystem and ConfigSystem.Flags then
                ConfigSystem.Flags[flag] = {
                    Type = "Dropdown",
                    Set = function(option)
                        if dropdownObj and dropdownObj.SetValue then
                            dropdownObj.SetValue(option)
                        end
                    end,
                    Get = function()
                        return currentOption
                    end
                }
                if ConfigSystem.CurrentConfig then
                    ConfigSystem.CurrentConfig[flag] = currentOption
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
                end
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
                end
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
                end
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
                
                return Button
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
                    end
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
                    end
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
            -- COLLAPSIBLE: AddDropdown
            -- ═══════════════════════════════════════════
            function Collapsible:AddDropdown(config)
                config = config or {}
                local dropdownText = config.Name or "Dropdown"
                local options = config.Options or {"Option 1", "Option 2"}
                local default = config.Default or options[1]
                local callback = config.Callback or function() end
                local flag = config.Flag
                
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
                DropdownFrame.BackgroundColor3 = Colors.Background
                DropdownFrame.BorderSizePixel = 0
                DropdownFrame.ClipsDescendants = true
                DropdownFrame.Parent = ContentFrame
                
                local DropdownCorner = Instance.new("UICorner")
                DropdownCorner.CornerRadius = UDim.new(0, 6)
                DropdownCorner.Parent = DropdownFrame
                
                local DropdownButton = Instance.new("TextButton")
                DropdownButton.Size = UDim2.new(1, 0, 0, 35)
                DropdownButton.BackgroundTransparency = 1
                DropdownButton.Text = ""
                DropdownButton.Parent = DropdownFrame
                
                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Size = UDim2.new(1, -30, 0, 35)
                DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = dropdownText .. ": " .. tostring(default)
                DropdownLabel.TextColor3 = Colors.Text
                DropdownLabel.TextSize = 13
                DropdownLabel.Font = Enum.Font.Gotham
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownFrame
                
                local DropdownIcon = Instance.new("TextLabel")
                DropdownIcon.Size = UDim2.new(0, 20, 0, 35)
                DropdownIcon.Position = UDim2.new(1, -25, 0, 0)
                DropdownIcon.BackgroundTransparency = 1
                DropdownIcon.Text = "▼"
                DropdownIcon.TextColor3 = Colors.TextDim
                DropdownIcon.TextSize = 10
                DropdownIcon.Font = Enum.Font.Gotham
                DropdownIcon.Parent = DropdownFrame
                
                local OptionsList = Instance.new("Frame")
                OptionsList.Size = UDim2.new(1, -10, 0, #options * 28)
                OptionsList.Position = UDim2.new(0, 5, 0, 38)
                OptionsList.BackgroundTransparency = 1
                OptionsList.Parent = DropdownFrame
                
                local OptionsListLayout = Instance.new("UIListLayout")
                OptionsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptionsListLayout.Padding = UDim.new(0, 3)
                OptionsListLayout.Parent = OptionsList
                
                local isOpen = false
                local currentOption = default
                
                DropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    
                    if isOpen then
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 42 + #options * 28)}, 0.3)
                        Tween(DropdownIcon, {Rotation = 180}, 0.3)
                    else
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.3)
                        Tween(DropdownIcon, {Rotation = 0}, 0.3)
                    end
                end)
                
                for _, option in ipairs(options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Size = UDim2.new(1, 0, 0, 25)
                    OptionButton.BackgroundColor3 = Colors.Tertiary
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = option
                    OptionButton.TextColor3 = Colors.Text
                    OptionButton.TextSize = 12
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.Parent = OptionsList
                    
                    local OptionCorner = Instance.new("UICorner")
                    OptionCorner.CornerRadius = UDim.new(0, 4)
                    OptionCorner.Parent = OptionButton
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        currentOption = option
                        DropdownLabel.Text = dropdownText .. ": " .. option
                        
                        isOpen = false
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.3)
                        Tween(DropdownIcon, {Rotation = 0}, 0.3)
                        
                        SafeCallback(callback, option)
                        
                        if flag and ConfigSystem.CurrentConfig then
                            ConfigSystem.CurrentConfig[flag] = option
                        end
                    end)
                    
                    OptionButton.MouseEnter:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Colors.Accent}, 0.2)
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                    end)
                end
                
                local dropdownObj = {
                    SetValue = function(option)
                        if table.find(options, option) then
                            currentOption = option
                            DropdownLabel.Text = dropdownText .. ": " .. option
                            SafeCallback(callback, option)
                            if flag and ConfigSystem.CurrentConfig then
                                ConfigSystem.CurrentConfig[flag] = option
                            end
                        end
                    end,
                    SetOptions = function(newOptions)
                        options = newOptions
                        
                        -- Destroy old option buttons
                        for _, child in ipairs(OptionsList:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end
                        
                        -- Create new option buttons
                        for _, option in ipairs(options) do
                            local OptionButton = Instance.new("TextButton")
                            OptionButton.Size = UDim2.new(1, 0, 0, 25)
                            OptionButton.BackgroundColor3 = Colors.Tertiary
                            OptionButton.BorderSizePixel = 0
                            OptionButton.Text = option
                            OptionButton.TextColor3 = Colors.Text
                            OptionButton.TextSize = 12
                            OptionButton.Font = Enum.Font.Gotham
                            OptionButton.Parent = OptionsList
                            
                            local OptionCorner = Instance.new("UICorner")
                            OptionCorner.CornerRadius = UDim.new(0, 4)
                            OptionCorner.Parent = OptionButton
                            
                            OptionButton.MouseButton1Click:Connect(function()
                                currentOption = option
                                DropdownLabel.Text = dropdownText .. ": " .. option
                                isOpen = false
                                Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.3)
                                Tween(DropdownIcon, {Rotation = 0}, 0.3)
                                SafeCallback(callback, option)
                                
                                if flag and ConfigSystem.CurrentConfig then
                                    ConfigSystem.CurrentConfig[flag] = option
                                end
                            end)
                            
                            -- Add hover effects (FIXED!)
                            OptionButton.MouseEnter:Connect(function()
                                Tween(OptionButton, {BackgroundColor3 = Colors.Accent}, 0.2)
                            end)
                            
                            OptionButton.MouseLeave:Connect(function()
                                Tween(OptionButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                            end)
                        end
                        
                        -- Update OptionsList size
                        OptionsList.Size = UDim2.new(1, -10, 0, #options * 28)
                        
                        -- Update DropdownFrame size if currently open (FIXED!)
                        if isOpen then
                            Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 42 + #options * 28)}, 0.3)
                        end
                        
                        -- Reset label if current option not in new options
                        if not table.find(options, currentOption) then
                            currentOption = options[1] or "Select"
                            DropdownLabel.Text = dropdownText .. ": " .. currentOption
                        end
                    end
                }
                
                if flag and ConfigSystem and ConfigSystem.Flags then
                    ConfigSystem.Flags[flag] = {
                        Type = "Dropdown",
                        Set = function(option) dropdownObj.SetValue(option) end,
                        Get = function() return currentOption end
                    }
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
                    end
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
                    end
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
                    end
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
                    end
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
                    end
                }
            end
            
            return Collapsible
        end
        
        function Tab:CreateMultiDropdown(config)
            config = config or {}
            local dropdownText = config.Name or "Multi Dropdown"
            local options = config.Options or {"Option 1", "Option 2", "Option 3"}
            local default = config.Default or {}
            local callback = config.Callback or function() end
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
            DropdownFrame.BackgroundColor3 = Colors.Tertiary
            DropdownFrame.BorderSizePixel = 0
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = TabContent
            
            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 8)
            DropdownCorner.Parent = DropdownFrame
            
            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 40)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.Parent = DropdownFrame
            
            local selectedOptions = {}
            for _, v in ipairs(default) do
                selectedOptions[v] = true
            end
            
            local function updateLabel()
                local count = 0
                for _ in pairs(selectedOptions) do
                    count = count + 1
                end
                
                if count == 0 then
                    return dropdownText .. ": None"
                elseif count == 1 then
                    for opt in pairs(selectedOptions) do
                        return dropdownText .. ": " .. opt
                    end
                else
                    return dropdownText .. ": " .. count .. " selected"
                end
            end
            
            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(1, -60, 0, 40)
            DropdownLabel.Position = UDim2.new(0, 15, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = updateLabel()
            DropdownLabel.TextColor3 = Colors.Text
            DropdownLabel.TextSize = 14
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame
            
            local DropdownIcon = Instance.new("TextLabel")
            DropdownIcon.Size = UDim2.new(0, 20, 0, 40)
            DropdownIcon.Position = UDim2.new(1, -30, 0, 0)
            DropdownIcon.BackgroundTransparency = 1
            DropdownIcon.Text = "▼"
            DropdownIcon.TextColor3 = Colors.TextDim
            DropdownIcon.TextSize = 12
            DropdownIcon.Font = Enum.Font.Gotham
            DropdownIcon.Parent = DropdownFrame
            
            local OptionsList = Instance.new("Frame")
            OptionsList.Size = UDim2.new(1, -10, 0, #options * 35)
            OptionsList.Position = UDim2.new(0, 5, 0, 45)
            OptionsList.BackgroundTransparency = 1
            OptionsList.Parent = DropdownFrame
            
            local OptionsListLayout = Instance.new("UIListLayout")
            OptionsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptionsListLayout.Padding = UDim.new(0, 5)
            OptionsListLayout.Parent = OptionsList
            
            local isOpen = false
            
            DropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 50 + #options * 35)}, 0.3)
                    Tween(DropdownIcon, {Rotation = 180}, 0.3)
                else
                    Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Tween(DropdownIcon, {Rotation = 0}, 0.3)
                end
            end)
            
            for _, option in ipairs(options) do
                local OptionButton = Instance.new("TextButton")
                OptionButton.Size = UDim2.new(1, 0, 0, 30)
                OptionButton.BackgroundColor3 = Colors.Background
                OptionButton.BorderSizePixel = 0
                OptionButton.Text = ""
                OptionButton.Parent = OptionsList
                
                local OptionCorner = Instance.new("UICorner")
                OptionCorner.CornerRadius = UDim.new(0, 6)
                OptionCorner.Parent = OptionButton
                
                local Checkbox = Instance.new("Frame")
                Checkbox.Size = UDim2.new(0, 18, 0, 18)
                Checkbox.Position = UDim2.new(0, 8, 0.5, -9)
                Checkbox.BackgroundColor3 = selectedOptions[option] and Colors.Accent or Colors.Border
                Checkbox.BorderSizePixel = 0
                Checkbox.Parent = OptionButton
                
                local CheckboxCorner = Instance.new("UICorner")
                CheckboxCorner.CornerRadius = UDim.new(0, 4)
                CheckboxCorner.Parent = Checkbox
                
                local Checkmark = Instance.new("TextLabel")
                Checkmark.Size = UDim2.new(1, 0, 1, 0)
                Checkmark.BackgroundTransparency = 1
                Checkmark.Text = selectedOptions[option] and "✓" or ""
                Checkmark.TextColor3 = Colors.Text
                Checkmark.TextSize = 14
                Checkmark.Font = Enum.Font.GothamBold
                Checkmark.Parent = Checkbox
                
                local OptionLabel = Instance.new("TextLabel")
                OptionLabel.Size = UDim2.new(1, -35, 1, 0)
                OptionLabel.Position = UDim2.new(0, 30, 0, 0)
                OptionLabel.BackgroundTransparency = 1
                OptionLabel.Text = option
                OptionLabel.TextColor3 = Colors.Text
                OptionLabel.TextSize = 13
                OptionLabel.Font = Enum.Font.Gotham
                OptionLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptionLabel.Parent = OptionButton
                
                OptionButton.MouseButton1Click:Connect(function()
                    selectedOptions[option] = not selectedOptions[option]
                    
                    Tween(Checkbox, {
                        BackgroundColor3 = selectedOptions[option] and Colors.Accent or Colors.Border
                    }, 0.2)
                    
                    Checkmark.Text = selectedOptions[option] and "✓" or ""
                    DropdownLabel.Text = updateLabel()
                    
                    local selected = {}
                    for opt, isSelected in pairs(selectedOptions) do
                        if isSelected then
                            table.insert(selected, opt)
                        end
                    end
                    
                    SafeCallback(callback, selected)
                end)
                
                OptionButton.MouseEnter:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Colors.Tertiary}, 0.2)
                end)
                
                OptionButton.MouseLeave:Connect(function()
                    Tween(OptionButton, {BackgroundColor3 = Colors.Background}, 0.2)
                end)
            end
            
            return {
                SetValue = function(values)
                    selectedOptions = {}
                    for _, v in ipairs(values) do
                        selectedOptions[v] = true
                    end
                    
                    DropdownLabel.Text = updateLabel()
                    
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child:IsA("TextButton") then
                            local optName = child:FindFirstChild("TextLabel").Text
                            local checkbox = child:FindFirstChild("Frame")
                            local checkmark = checkbox:FindFirstChild("TextLabel")
                            
                            checkbox.BackgroundColor3 = selectedOptions[optName] and Colors.Accent or Colors.Border
                            checkmark.Text = selectedOptions[optName] and "✓" or ""
                        end
                    end
                    
                    local selected = {}
                    for opt, isSelected in pairs(selectedOptions) do
                        if isSelected then
                            table.insert(selected, opt)
                        end
                    end
                    SafeCallback(callback, selected)
                end
            }
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
