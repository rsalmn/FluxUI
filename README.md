# 🎨 FluxUI

<div align="center">

![FluxUI Banner](https://img.shields.io/badge/FluxUI-v1.0.0-blue?style=for-the-badge&logo=lua&logoColor=white)
![Roblox](https://img.shields.io/badge/Roblox-Executor-red?style=for-the-badge&logo=roblox&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A Modern, Feature-Rich UI Library for Roblox Executors**

*Inspired by Wind UI & Fluent UI*

[Features](#-features) • [Installation](#-installation) • [Documentation](#-documentation) • [Themes](#-themes) • [Examples](#-examples)

</div>

---

## ✨ Features

- 🎨 **8 Beautiful Themes** - Dark, Light, Purple, Ocean, Sunset, Rose, Emerald, Midnight
- 💾 **Config System** - Save, Load, Delete configurations with JSON support
- 🔔 **Notification System** - Success, Warning, Error, Default notification types
- 📊 **Chart Component** - Bar charts for data visualization
- 🔍 **Searchable Dropdown** - Filter options with search functionality
- ⚡ **Smooth Animations** - Powered by TweenService
- 📱 **Touch Support** - Mobile/Touch device compatible
- 🛡️ **Protected GUI** - Works with most executors (Synapse, Fluxus, Delta, etc.)
- ⚙️ **Confirmation Dialog** - Close confirmation with custom callbacks
- 🎯 **20+ Components** - Buttons, Toggles, Sliders, Dropdowns, and more!

---

## 📦 Installation

### Method 1: Loadstring (Recommended)
    lua local FluxUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/rsalmn/FluxUI/main/FluxUI.lua"))()
    

### Method 2: Local File
`lua
local FluxUI = loadfile("FluxUI.lua")()
`

---

## 📚 Documentation

### Creating a Window

`lua local FluxUI = loadstring(game:HttpGet("YOUR_RAW_LINK"))()
local Window = FluxUI:CreateWindow({
    Name = "My Script Hub",
    Size = UDim2.new(0, 550, 0, 400),
    Theme = "Dark" -- Dark, Light, Purple, Ocean, Sunset, Rose, Emerald, Midnight
})
`

### Creating Tabs

`lua
local MainTab = Window:CreateTab("🏠 Home")
local SettingsTab = Window:CreateTab("⚙️ Settings")
`

---

## 🧩 Components

### Button
`lua
MainTab:CreateButton({
    Name = "Click Me!",
    Callback = function()
        print("Button clicked!")
    end
})
`

### Toggle
`lua
MainTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Flag = "FeatureToggle",
    Callback = function(value)
        print("Toggle:", value)
    end
})
`

### Slider
`lua
MainTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Flag = "WalkSpeedSlider",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})
`

### Dropdown
`lua
MainTab:CreateDropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Flag = "DropdownFlag",
    Callback = function(selected)
        print("Selected:", selected)
    end
})
`

### Searchable Dropdown
`lua
MainTab:CreateSearchDropdown({
    Name = "Select Player",
    Options = {"Player1", "Player2", "Player3"},
    Placeholder = "Search player...",
    Default = "",
    Callback = function(selected)
        print("Selected:", selected)
    end
})
`

### Multi Dropdown
`lua
MainTab:CreateMultiDropdown({
    Name = "Select Multiple",
    Options = {"A", "B", "C", "D"},
    Default = {"A", "C"},
    Callback = function(selected)
        print("Selected:", table.concat(selected, ", "))
    end
})
`

### Textbox
`lua
MainTab:CreateTextbox({
    Name = "Enter Text",
    Placeholder = "Type here...",
    Callback = function(text, enterPressed)
        if enterPressed then
            print("Submitted:", text)
        end
    end
})
`

### Keybind
`lua
MainTab:CreateKeybind({
    Name = "Toggle GUI",
    Default = Enum.KeyCode.RightShift,
    Flag = "ToggleKeybind",
    Callback = function(key)
        print("Key pressed:", key.Name)
    end
})
`

### Color Picker
`lua
MainTab:CreateColorPicker({
    Name = "Select Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("Color:", color)
    end
})
`

### Label
`lua
local label = MainTab:CreateLabel("This is a label")
label.SetText("Updated label text")
`

### Paragraph
`lua
MainTab:CreateParagraph({
    Title = "Information",
    Content = "This is a paragraph with some useful information about your script."
})
`

### Section
`lua
MainTab:CreateSection("Section Title")
`

### Divider
`lua
MainTab:CreateDivider() -- Simple line
MainTab:CreateDivider("With Text") -- Line with text
`

### Chart (Bar Graph)
`lua local chart = MainTab:CreateChart({
    Name = "Player Stats",
    Type = "Bar",
    Max = 100,
    ShowValues = true,
    Color = Color3.fromRGB(88, 101, 242),
    Data = {
        {Label = "HP", Value = 80},
        {Label = "MP", Value = 50},
        {Label = "STR", Value = 65},
        {Label = "DEF", Value = 40}
    }
})
chart.SetData({
    {Label = "HP", Value = 100},
    {Label = "MP", Value = 75}
})
`

### Collapsible Section
-- All components available:
-- AddButton, AddToggle, AddSlider, AddDropdown, AddTextbox,
-- AddKeybind, AddColorPicker, AddLabel, AddDivider, AddParagraph, AddSection
`lua
local Collapsible = MainTab:CreateCollapsible({
    Name = "Player Options",
    DefaultOpen = false
})
Collapsible:AddButton({
    Name = "Button Inside",
    Callback = function() end
})
Collapsible:AddToggle({
    Name = "Toggle Inside",
    Callback = function(v) end
})
Collapsible:AddSlider({
    Name = "Slider Inside",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(v) end
})
`

---

## 🎨 Themes

FluxUI comes with **8 beautiful pre-built themes**:

| Theme | Preview Colors |
|-------|---------------|
| **Dark** | Deep dark with blue accent |
| **Light** | Clean white with blue accent |
| **Purple** | Dark purple with violet accent |
| **Ocean** | Deep blue with cyan accent |
| **Sunset** | Warm dark with orange accent |
| **Rose** | Dark pink with rose accent |
| **Emerald** | Forest dark with green accent |
| **Midnight** | Ultra dark with indigo accent |

-- Set theme when creating window
-- Available themes: "Dark", "Light", "Purple", "Ocean", "Sunset", "Rose", "Emerald", "Midnight"
`lua FluxUI.Themes -- {"Dark", "Light", "Purple", "Ocean", "Sunset", "Rose", "Emerald", "Midnight"}
local Window = FluxUI:CreateWindow({
    Name = "My Hub",
    Theme = "Ocean"
})
`

---

## 💾 Config System

### Auto Config Tab
`lua
Window:AddConfigTab() -- Adds a complete config management tab
`

### Manual Config Management
`lua
-- Save config
Window:SaveConfig("MyConfig")
`
`
-- Load config
Window:LoadConfig("MyConfig")
`
`
-- Delete config
Window:DeleteConfig("MyConfig")
`
`
-- Get all configs
local configs = Window:GetConfigs()
`
`
-- Auto load config on start
Window:AutoLoadConfig("MyConfig")
`

### Using Flags
Flags are used to save/load component states:
`lua
MainTab:CreateToggle({
    Name = "My Toggle",
    Default = false,
    Flag = "UniqueFlag" -- This will be saved/loaded automatically
})
`

---

## 🔔 Notifications

`lua
-- Using Window method
Window:Notify({
    Title = "Success!",
    Content = "Operation completed successfully.",
    Duration = 3,
    Type = "Success" -- "Default", "Success", "Warning", "Error"
})
`
`
-- Using FluxUI global method
FluxUI:Notify({
    Title = "Warning",
    Content = "Something needs attention!",
    Duration = 5,
    Type = "Warning"
})
`

---

## ⚠️ Confirmation Dialog

Automatically shows when closing the window. You can also call it manually:

`lua
Window.Confirm({
    Title = "Delete Item?",
    Content = "This action cannot be undone.",
    ConfirmText = "Delete",
    CancelText = "Cancel",
    Callback = function(confirmed)
        if confirmed then
            print("User confirmed!")
        else
            print("User cancelled")
        end
    end
})
`

---

## 📱 Full Example

`lua
local FluxUI = loadstring(game:HttpGet("[YOUR_RAW_LINK](https://raw.githubusercontent.com/rsalmn/FluxUI/refs/heads/main/FluxUI.lua)"))()
`

-- Create Window
`
local Window = FluxUI:CreateWindow({
    Name = "🚀 My Script Hub",
    Size = UDim2.new(0, 550, 0, 400),
    Theme = "Purple"
})
`
-- Main Tab
`
local MainTab = Window:CreateTab("🏠 Main")
MainTab:CreateSection("Player Modifications")
`
`
MainTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Flag = "WalkSpeed",
    Callback = function(value)
        if game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})
`
`
MainTab:CreateSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Flag = "JumpPower",
    Callback = function(value)
        if game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
        end
    end
})
`
`
MainTab:CreateToggle({
    Name = "Infinite Jump",
    Default = false,
    Flag = "InfJump",
    Callback = function(value)
        _G.InfiniteJump = value
    end
})
`
`
MainTab:CreateDivider("Teleport")
`
`
local players = {}
for _, player in pairs(game.Players:GetPlayers()) do
    table.insert(players, player.Name)
end
`
`
local playerDropdown = MainTab:CreateSearchDropdown({
    Name = "Select Player",
    Options = players,
    Placeholder = "Search...",
    Callback = function(selected)
        -- Store selected player
    end
})
`
`
MainTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        -- Teleport logic
    end
})
`
-- Settings Tab
`
local SettingsTab = Window:CreateTab("⚙️ Settings")
SettingsTab:CreateSection("UI Settings")
SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        -- Toggle UI visibility
    end
})
`
-- Add Config Tab
`
Window:AddConfigTab()
`
-- Auto load config
`
Window:AutoLoadConfig("Default")
`

-- Show welcome notification
`
Window:Notify({
    Title = "Welcome!",
    Content = "Script loaded successfully!",
    Duration = 3,
    Type = "Success"
})
`

---

## 🔧 Window Methods

| Method | Description |
|--------|-------------|
| `Window:CreateTab(name)` | Create a new tab |
| `Window:Notify(config)` | Show notification |
| `Window.Confirm(config)` | Show confirmation dialog |
| `Window:SaveConfig(name)` | Save configuration |
| `Window:LoadConfig(name)` | Load configuration |
| `Window:DeleteConfig(name)` | Delete configuration |
| `Window:GetConfigs()` | Get all config names |
| `Window:AutoLoadConfig(name)` | Auto load config on start |
| `Window:AddConfigTab()` | Add config management tab |
| `Window:Destroy()` | Destroy the window |

---

## 📋 Component Return Methods

### Toggle
`lua
local toggle = Tab:CreateToggle({...})
toggle.SetValue(true/false)
`

### Slider
`lua
local slider = Tab:CreateSlider({...})
slider.SetValue(50)
`

### Dropdown
`lua
local dropdown = Tab:CreateDropdown({...})
dropdown.SetValue("Option")
dropdown.Refresh({"New", "Options"})
dropdown.SetOptions({"New", "Options"})
`

### Textbox
`lua
local textbox = Tab:CreateTextbox({...})
textbox.SetValue("text")
`

### Label
`lua
local label = Tab:CreateLabel("text")
label.SetText("new text")
`

### Paragraph
`lua
local para = Tab:CreateParagraph({...})
para.SetTitle("New Title")
para.SetContent("New Content")
`

### Chart
`lua
local chart = Tab:CreateChart({...})
chart.SetData({{Label = "A", Value = 50}})
chart.SetMax(200)
`

---

## 🤝 Credits

- **Author:** RSALMAN
- **Inspired by:** Wind UI, Fluent UI
- **Built for:** Roblox Script Executors

---

## 📜 License

This project is licensed under the MIT License - feel free to use it in your projects!

`
MIT License

Copyright (c) 2026 RSALMAN

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
`

---

<div align="center">

**⭐ Star this repo if you find it useful! ⭐**

Made with ❤️ by RSALMAN

</div>
