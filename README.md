# Vaehz's Simple lib - [Documentation]

A clean, Simple Roblox UI library designed for simple script GUI's.

## Features

- Clean dark UI
- Lightweight single-file library
- Windows and tabs
- Buttons
- Toggles
- Sliders
- Textboxes
- Dropdowns
- Multi-select dropdowns
- Color pickers
- Labels
- Warning labels
- Stats
- Notifications
- Custom accent colors
- Full theme customization
- Per-window themes
- Customizable toggle key
- Smooth UI animations
- Executor GUI protection support
- And more
---
## All the main stuff 

# Icons: https://kaan650.github.io/builder-icons/

- [Creating a Window](https://github.com/Medstim/UI-lib-/blob/main/README.md#creating-a-window)
- [Creating a Tab](https://github.com/Medstim/UI-lib-/blob/main/README.md#creating-tabs)
- [Components](https://github.com/Medstim/UI-lib-/blob/main/README.md#components)
- [Theme Customization](https://github.com/Medstim/UI-lib-/blob/main/README.md#theme-customization)
- [Complete API](https://github.com/Medstim/UI-lib-/blob/main/README.md#complete-api)
- [Multiple Examples](https://github.com/Medstim/UI-lib-/blob/main/README.md#example-state-pattern)
- [Organization & Credits](https://github.com/Medstim/UI-lib-/blob/main/README.md#recommended-organization)
---
# Quick Start

Here is a complete example showing the main features of the Simple lib.

```lua
--// Load Library
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Medstim/Vzlib/refs/heads/main/main.lua"
))()

--// Theme
Library:SetTheme({
    Background = Color3.fromRGB(16, 16, 16),
    Secondary = Color3.fromRGB(27, 27, 27),
    Element = Color3.fromRGB(34, 34, 34),
    ElementHover = Color3.fromRGB(42, 42, 42),
    ElementPressed = Color3.fromRGB(48, 48, 48),

    Off = Color3.fromRGB(55, 55, 55),

    Stroke = Color3.fromRGB(171, 171, 171),
    StrokeDim = Color3.fromRGB(100, 100, 100),

    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(175, 175, 175),

    Warning = Color3.fromRGB(255, 190, 70),
    Accent = Color3.fromRGB(100, 160, 255),
})

--// Window
local Window = Library:CreateWindow({
    Title = "My Script",
    ToggleKey = Enum.KeyCode.RightShift,
})

--// State
local selectedUpgrades = {}
local autoExample = false

--// Tabs
local MainTab     = Window:CreateTab({ Name = "Main",     Icon = "house" })
local MiscTab     = Window:CreateTab({ Name = "Misc",     Icon = "hammer-code" })
local ExtrasTab   = Window:CreateTab({ Name = "Extras",   Icon = "star" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "gear" })
local GameTab     = Window:CreateTab({ Name = "Game",     Icon = "" })

--// Main
MainTab:CreateLabel("── Main Example ──")

MainTab:CreateToggle({
    Name = "Example Toggle",
    Default = false,

    Callback = function(enabled)
        print("Toggle:", enabled)
    end,
})

MainTab:CreateSlider({
    Name = "Example Slider",
    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 50,

    Callback = function(value)
        print("Slider:", value)
    end,
})

MainTab:CreateButton({
    Name = "Example Button",

    Callback = function()
        print("Button pressed")
    end,
})

--// Misc
MiscTab:CreateLabel("── Upgrades Example ──")

MiscTab:CreateDropdown({
    Name = "Select Example",

    Options = {
        "All Examples",
        "Example1 Multiplier",
        "Example2 Multiplier",
        "Example Speed",
    },

    Multi = true,

    Callback = function(choices)
        selectedUpgrades = choices
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Example",
    Default = false,

    Callback = function(enabled)
        autoExample = enabled

        if not enabled then
            return
        end

        task.spawn(function()
            while autoExample do
                for _, choice in selectedUpgrades do
                    print("Selected:", choice)
                end

                task.wait(0.5)
            end
        end)
    end,
})

--// Extras
ExtrasTab:CreateLabel("── Extra Examples ──")

ExtrasTab:CreateTextbox({
    Name = "Example Textbox",
    Placeholder = "Enter something...",

    Callback = function(text)
        print("Text:", text)
    end,
})

ExtrasTab:CreateColorPicker({
    Name = "Example Color",
    Default = Color3.fromRGB(100, 160, 255),

    Callback = function(color)
        print("Color:", color)
    end,
})

--// Settings
SettingsTab:CreateLabel("── Settings ──")

SettingsTab:CreateDropdown({
    Name = "Mode",

    Options = {
        "Default",
        "Performance",
        "Advanced",
    },

    Default = "Default",

    Callback = function(mode)
        print("Mode:", mode)
    end,
})

SettingsTab:CreateToggle({
    Name = "Notifications",
    Default = true,

    Callback = function(enabled)
        print("Notifications:", enabled)
    end,
})

--// Game
GameTab:CreateLabel("── Game Information ──")

GameTab:CreateStat({
    Name = "Status",
    Value = "Loaded",
})

GameTab:CreateStat({
    Name = "Place ID",
    Value = tostring(game.PlaceId),
})

GameTab:CreateButton({
    Name = "Copy Place ID",

    Callback = function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
        end
    end,
})

--// Loaded
Library:Notify({
    Title = "Loaded",
    Content = "My Script is ready. Press RightShift to toggle.",
    Duration = 4,
})
```

---

# Creating a Window

Windows are created with:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
})
```

## Window Configuration

| Property    | Type         | Description                  |
| ----------- | ------------ | ---------------------------- |
| `Title`     | string       | Window title                 |
| `Accent`    | Color3       | Window accent color          |
| `Theme`     | table        | Custom theme for this window |
| `ToggleKey` | Enum.KeyCode | Key used to show/hide the UI |

Example:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Accent = Color3.fromRGB(255, 90, 120),
    ToggleKey = Enum.KeyCode.RightShift,
})
```

The default toggle key is:

```lua
Enum.KeyCode.RightShift
```

---

# Creating Tabs

Tabs are created from the window:

```lua
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "house",
})
```

Multiple tabs can be created:

```lua
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "house",
})

local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "gear",
})
```

The first created tab is automatically selected.

---

# Components

## Label

Creates a simple text label.

```lua
local Label = MainTab:CreateLabel("Hello World")
```

### Set Text

```lua
Label:Set("New Text")
```

---

## Warning

Creates a warning-style label.

```lua
local Warning = MainTab:CreateWarning(
    "This is an example warning."
)
```

### Set Text

```lua
Warning:Set("Updated warning.")
```

---

# Button

Creates a clickable button.

```lua
MainTab:CreateButton({
    Name = "Click Me",

    Callback = function()
        print("Button clicked")
    end,
})
```

### Configuration

| Property   | Type     | Description         |
| ---------- | -------- | ------------------- |
| `Name`     | string   | Button name         |
| `Callback` | function | Called when clicked |

---

# Toggle

Creates an on/off toggle.

```lua
local Toggle = MainTab:CreateToggle({
    Name = "Auto Example",
    Default = false,

    Callback = function(enabled)
        print("Enabled:", enabled)
    end,
})
```

## Set Value

```lua
Toggle:Set(true)
```

## Get Value

```lua
local enabled = Toggle:Get()

print(enabled)
```

---

# Slider

Creates a numerical slider.

```lua
local Slider = MainTab:CreateSlider({
    Name = "WalkSpeed",

    Min = 0,
    Max = 100,
    Increment = 1,
    Default = 50,

    Callback = function(value)
        print("Value:", value)
    end,
})
```

## Configuration

| Property    | Type     | Description         |
| ----------- | -------- | ------------------- |
| `Name`      | string   | Slider name         |
| `Min`       | number   | Minimum value       |
| `Max`       | number   | Maximum value       |
| `Increment` | number   | Value increment     |
| `Default`   | number   | Starting value      |
| `Callback`  | function | Called when changed |

## Set Value

```lua
Slider:Set(75)
```

## Get Value

```lua
local value = Slider:Get()
```

---

# Textbox

Creates a text input.

```lua
local Textbox = MainTab:CreateTextbox({
    Name = "Username",
    Placeholder = "Enter username...",

    Callback = function(text)
        print("Entered:", text)
    end,
})
```

## Configuration

| Property      | Type     | Description              |
| ------------- | -------- | ------------------------ |
| `Name`        | string   | Textbox name             |
| `Placeholder` | string   | Placeholder text         |
| `Default`     | string   | Initial value            |
| `MinWidth`    | number   | Minimum textbox width    |
| `MaxWidth`    | number   | Maximum textbox width    |
| `Callback`    | function | Called when text changes |

## Set Value

```lua
Textbox:Set("Hello")
```

## Get Value

```lua
local text = Textbox:Get()
```

---

# Color Picker

Creates a color picker.

```lua
local ColorPicker = MainTab:CreateColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(100, 160, 255),

    Callback = function(color)
        print("Selected color:", color)
    end,
})
```

## Set Color

```lua
ColorPicker:Set(Color3.fromRGB(255, 0, 0))
```

## Get Color

```lua
local color = ColorPicker:Get()
```

---

# Dropdown

Creates a standard single-selection dropdown.

```lua
local Dropdown = MainTab:CreateDropdown({
    Name = "Mode",

    Options = {
        "Default",
        "Performance",
        "Advanced",
    },

    Default = "Default",

    Callback = function(choice)
        print("Selected:", choice)
    end,
})
```

## Get Selected Option

```lua
local choice = Dropdown:Get()
```

## Set Selected Option

```lua
Dropdown:Set("Advanced")
```

## Refresh Options

```lua
Dropdown:Refresh({
    "Option 1",
    "Option 2",
    "Option 3",
})
```

---

# Multi-Select Dropdown

Set:

```lua
Multi = true
```

to allow multiple options to be selected.

```lua
local selected = {}

local Dropdown = MainTab:CreateDropdown({
    Name = "Select Options",

    Options = {
        "Option 1",
        "Option 2",
        "Option 3",
        "Option 4",
    },

    Multi = true,

    Callback = function(choices)
        selected = choices
    end,
})
```

The callback receives a table containing the selected options.

Example:

```lua
for _, choice in selected do
    print(choice)
end
```

You can also retrieve the selected options directly:

```lua
local choices = Dropdown:Get()
```

---

# Stat

Creates a small statistic/value display.

```lua
local Status = MainTab:CreateStat({
    Name = "Status",
    Value = "Ready",
})
```

## Update Value

```lua
Status:Set("Running")
```

---

# Notifications

Notifications can be created with:

```lua
Library:Notify({
    Title = "Success",
    Content = "Everything is ready.",
    Duration = 4,
})
```

## Configuration

| Property   | Type   | Description                             |
| ---------- | ------ | --------------------------------------- |
| `Title`    | string | Notification title                      |
| `Content`  | string | Notification message                    |
| `Duration` | number | How long the notification stays visible |

Example:

```lua
Library:Notify({
    Title = "Loaded",
    Content = "The script has successfully loaded.",
    Duration = 5,
})
```
---

# Component Return Values

Most components return an object that can be stored and modified later.

For example:

```lua
local Toggle = MainTab:CreateToggle({
    Name = "Example",
    Default = false,
})
```

You can then use:

```lua
Toggle:Set(true)
```

and:

```lua
print(Toggle:Get())
```

This makes it possible to control UI elements from other parts of your script.

---

# Theme Customization

The UI supports more than just changing the accent color.

The library provides a simple not complete theme system.

## Available Theme Keys

```lua
Library:SetTheme({
    Background = Color3.fromRGB(16, 16, 16),
    Secondary = Color3.fromRGB(27, 27, 27),

    Element = Color3.fromRGB(34, 34, 34),
    ElementHover = Color3.fromRGB(42, 42, 42),
    ElementPressed = Color3.fromRGB(48, 48, 48),

    Off = Color3.fromRGB(55, 55, 55),

    Stroke = Color3.fromRGB(171, 171, 171),
    StrokeDim = Color3.fromRGB(100, 100, 100),

    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(175, 175, 175),

    Warning = Color3.fromRGB(255, 190, 70),

    Accent = Color3.fromRGB(100, 160, 255),
})
```

## Theme Properties

| Property         | Description                  |
| ---------------- | ---------------------------- |
| `Background`     | Main window background       |
| `Secondary`      | Secondary UI background      |
| `Element`        | Standard element background  |
| `ElementHover`   | Element hover color          |
| `ElementPressed` | Element pressed/active color |
| `Off`            | Disabled/off state           |
| `Stroke`         | Main border/stroke color     |
| `StrokeDim`      | Dimmed stroke color          |
| `Text`           | Primary text color           |
| `SubText`        | Secondary text color         |
| `Warning`        | Warning color                |
| `Accent`         | Main accent color            |

---

# Applying a Theme

Themes can be applied using:

```lua
Library:SetTheme({
    Background = Color3.fromRGB(12, 12, 16),
    Secondary = Color3.fromRGB(20, 20, 28),

    Element = Color3.fromRGB(28, 28, 38),
    ElementHover = Color3.fromRGB(36, 36, 48),
    ElementPressed = Color3.fromRGB(44, 44, 58),

    Stroke = Color3.fromRGB(150, 150, 165),
    StrokeDim = Color3.fromRGB(90, 90, 100),

    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(175, 175, 185),

    Warning = Color3.fromRGB(255, 190, 70),
    Accent = Color3.fromRGB(170, 90, 255),
})
```

Only recognized theme properties are applied.

---

# Accent Only

If you only want to change the accent, you can use:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Accent = Color3.fromRGB(255, 80, 120),
})
```

This is useful when you want to keep the default theme while changing the main color.

---

# Per-Window Themes

You can also specify a theme directly when creating a window.

```lua
local Window = Library:CreateWindow({
    Title = "Custom Theme",

    Theme = {
        Background = Color3.fromRGB(12, 12, 16),
        Secondary = Color3.fromRGB(20, 20, 28),
        Accent = Color3.fromRGB(170, 90, 255),
    },
})
```

This allows different windows to use different themes.

You do not need to provide every theme property.

Only the values you want to override need to be included.

For example:

```lua
local Window = Library:CreateWindow({
    Title = "Purple UI",

    Theme = {
        Accent = Color3.fromRGB(170, 90, 255),
    },
})
```

The remaining colors use the default theme.

---

# Important Theme Note

`Library:SetTheme()` changes the default theme used when creating windows.

It does **not** rebuild or retroactively change an already-created window.

For example:

```lua
Library:SetTheme({
    Accent = Color3.fromRGB(255, 0, 0),
})

local Window = Library:CreateWindow({
    Title = "Red UI",
})
```

The new window will use the updated default theme.

If a window already exists, changing the library default does not recreate that window.

---

# Complete API

## Library

```lua
Library:CreateWindow(config)
Library:Notify(config)

Library:SetTheme(theme)

Library.Theme
Library.DefaultTheme
```

---

## Window

```lua
Window:CreateTab(config)
```

---

## Tab

```lua
Tab:CreateLabel(text)

Tab:CreateWarning(text)

Tab:CreateButton(config)

Tab:CreateToggle(config)

Tab:CreateStat(config)

Tab:CreateSlider(config)

Tab:CreateTextbox(config)

Tab:CreateColorPicker(config)

Tab:CreateDropdown(config)
```

---

# Example State Pattern

For larger scripts, it is recommended to keep shared state variables together near the top of the script.

For example:

```lua
--// Load Library
local Library = ...

--// Theme
Library:SetTheme({
    Accent = Color3.fromRGB(100, 160, 255),
})

--// Window
local Window = Library:CreateWindow({
    Title = "My Script",
})

--// State
local selectedUpgrades = {}
local autoExample = false
local currentMode = "Default"
local notificationsEnabled = true

--// Tabs
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "house",
})

local MiscTab = Window:CreateTab({
    Name = "Misc",
    Icon = "hammer-code",
})

--// Main
...
```

Keeping state together makes larger scripts easier to maintain.

---

# Local State vs getgenv()

This lib does not require `getgenv()`.

For most scripts, normal local variables are cleaner:

```lua
local autoExample = false
```

Then:

```lua
autoExample = true
```

and:

```lua
while autoExample do
    task.wait(0.5)
end
```

`getgenv()` is only useful when you intentionally need values to be shared through the executor's global environment.

For normal UI state, local variables are recommended.

---

# Example Multi-Select Pattern

A common pattern is using a multi-select dropdown together with a toggle.

```lua
local selected = {}
local running = false

MiscTab:CreateDropdown({
    Name = "Select Options",

    Options = {
        "Option 1",
        "Option 2",
        "Option 3",
    },

    Multi = true,

    Callback = function(choices)
        selected = choices
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Example",
    Default = false,

    Callback = function(enabled)
        running = enabled

        if not enabled then
            return
        end

        task.spawn(function()
            while running do
                for _, choice in selected do
                    print("Selected:", choice)
                end

                task.wait(0.5)
            end
        end)
    end,
})
```

This keeps the UI state completely local to the script.

---

# Example Project Structure


A script using the library can also remain compact:

```text
MyScript/
│
├── src.lua
└── script.lua
```

You do not need a large collection of ModuleScripts just to create a clean UI.

---

# Minimal Example

If you only need a small UI:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/src.lua"
))()

local Window = Library:CreateWindow({
    Title = "My Script",
})

local Main = Window:CreateTab({
    Name = "Main",
    Icon = "house",
})

Main:CreateButton({
    Name = "Hello",

    Callback = function()
        print("Hello!")
    end,
})

Main:CreateToggle({
    Name = "Example",
    Default = false,

    Callback = function(value)
        print("Enabled:", value)
    end,
})

Library:Notify({
    Title = "Loaded",
    Content = "UI successfully loaded.",
    Duration = 4,
})
```

---

# Recommended Organization

For a larger script, the following structure keeps things readable:

```lua
--// Load Library
local Library = ...

--// Theme
...

--// Window
local Window = ...

--// State
...

--// Tabs
...

--// Main
...

--// Misc
...

--// Extras
...

--// Settings
...

--// Game
...

--// Loaded
...
```

This keeps configuration, state, UI creation, and script logic easy to locate.

---

# Notes

* VaehzUI is designed around a simple API.
* Components can be stored in local variables for later control.
* Dropdowns support both single and multi-select modes.
* Themes can be customized globally for future windows.
* Individual windows can override theme values.
* `Accent` can be set independently from the rest of the theme.
* `getgenv()` is not required by the library.
* The UI can be toggled using the configured `ToggleKey`.

---
# Credits

Original lib Created by **Vaehz**.
---
