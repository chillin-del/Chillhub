--=====================================================================
--  ChillHubUI  |  v1.0.0
--  A lightweight, self-contained UI library made for ChillHub.
--
--  Everything is built in (no addons to download):
--    * Window + tabs + sections (two column layout)
--    * Toggle / Slider / Dropdown / Input / Keybind / ColorPicker /
--      Button / Label / Paragraph / Divider
--    * Configs (save / load / delete / autoload)
--    * Loading screen, Notifications, Themes, Accent color
--    * Search bar, tooltips, element chaining, window position saving
--    * Mobile / touch support
--    * Two modes: "Normal" (everything) and "Lite" (lighter + faster)
--
--  Quick start:
--      local UI = loadstring(game:HttpGet(".../ChillHubUI.lua"))()
--      UI.Setup{ Title = "ChillHub", Accent = Color3.fromRGB(255,100,0) }
--      local Win = UI.Window{ Title = "ChillHub" }
--      local Tab = Win:Tab("Home", "home")
--      local Box = Tab:Section("Main")
--      Box:Button("Hello", function() UI:Notify("Hi!", "success") end)
--
--  See ChillHubUI_Example.lua for a full demo.
--=====================================================================

local VERSION = "1.0.0"

--=====================================================================
--  SERVICES / ENVIRONMENT
--=====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local ENV = (getgenv and getgenv()) or _G

-- Service-level connections are tracked so UI:Unload() can disconnect them
-- (otherwise stale copies of the library keep reacting to input after unload).
local ServiceConns = {}
local function svc(signal, fn)
    local c = signal:Connect(fn)
    ServiceConns[#ServiceConns + 1] = c
    return c
end

local function fsWrite(path, data)
    if type(writefile) == "function" then pcall(writefile, path, data) return true end
    return false
end
local function fsRead(path)
    if type(readfile) == "function" then
        local ok, data = pcall(readfile, path)
        if ok then return data end
    end
    return nil
end
local function fsExists(path)
    if type(isfile) == "function" then local ok, v = pcall(isfile, path) if ok then return v end end
    return false
end
local function fsMakeFolder(path)
    if type(makefolder) == "function" then pcall(makefolder, path) end
end
local function fsList(path)
    if type(listfiles) == "function" then
        local ok, v = pcall(listfiles, path)
        if ok and type(v) == "table" then return v end
    end
    return {}
end
local function fsDelete(path)
    if type(delfile) == "function" then pcall(delfile, path) end
end

--=====================================================================
--  SMALL UTILITIES
--=====================================================================
local function new(class, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    return inst
end

local function corner(inst, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = inst })
end

local function stroke(inst, col, thick, trans)
    return new("UIStroke", {
        Color = col or Color3.new(1, 1, 1),
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

local function padding(inst, t, r, b, l)
    r = r or t; b = b or t; l = l or r
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        Parent = inst,
    })
end

local function list(inst, dir, gap, halign)
    return new("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 0),
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        Parent = inst,
    })
end

local function round(n)
    return math.floor(n + 0.5)
end

local function clamp(n, a, b)
    if n < a then return a elseif n > b then return b end
    return n
end

--=====================================================================
--  MODE (Normal / Lite)
--=====================================================================
local Mode = { Lite = false, Name = "Normal" }

local function tween(inst, props, time)
    if Mode.Lite then
        for k, v in pairs(props) do inst[k] = v end
        return nil
    end
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

--=====================================================================
--  THEMES
--=====================================================================
local Themes = {}

local function buildTheme(base)
    local t = {}
    local a = base.Accent
    local lum = a.R * 0.299 + a.G * 0.587 + a.B * 0.114
    t.Accent      = a
    t.AccentText  = lum > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    t.AccentDim   = a:Lerp(base.BG, 0.55)
    t.Window      = base.BG
    t.WindowBorder= base.Outline
    t.TitleBar    = base.BG2
    t.Sidebar     = base.BG2
    t.SidebarLine = base.Outline
    t.TabText     = base.SubText
    t.TabActive   = base.Text
    t.TabHover    = base.BG3
    t.Section     = base.BG2
    t.SectionLine = base.Outline
    t.SectionText = base.Text
    t.Element     = base.BG3
    t.ElementHover= base.BG3:Lerp(base.Text, 0.10)
    t.ElementLine = base.Outline
    t.Text        = base.Text
    t.SubText     = base.SubText
    t.DimText     = base.SubText:Lerp(base.BG, 0.30)
    t.Input       = base.BG
    t.InputText   = base.Text
    t.Scrollbar   = base.Outline
    t.Divider     = base.Outline
    t.ToggleOff   = base.BG3:Lerp(base.Text, 0.18)
    t.Toast       = base.BG2
    t.Shadow      = Color3.new(0, 0, 0)
    t.Round       = base.Round or 8
    t.RoundSmall  = base.RoundSmall or 6
    return t
end

Themes["Chill"] = buildTheme({
    BG = Color3.fromRGB(18, 18, 22), BG2 = Color3.fromRGB(24, 24, 30), BG3 = Color3.fromRGB(32, 32, 40),
    Text = Color3.fromRGB(238, 238, 244), SubText = Color3.fromRGB(150, 152, 165),
    Outline = Color3.fromRGB(44, 44, 54), Accent = Color3.fromRGB(255, 100, 0),
})

Themes["Tokyo Night"] = buildTheme({
    BG = Color3.fromRGB(20, 21, 31), BG2 = Color3.fromRGB(26, 27, 38), BG3 = Color3.fromRGB(36, 40, 59),
    Text = Color3.fromRGB(192, 202, 245), SubText = Color3.fromRGB(115, 122, 162),
    Outline = Color3.fromRGB(45, 49, 71), Accent = Color3.fromRGB(122, 162, 247),
})

Themes["Mint"] = buildTheme({
    BG = Color3.fromRGB(16, 24, 22), BG2 = Color3.fromRGB(21, 32, 29), BG3 = Color3.fromRGB(29, 43, 39),
    Text = Color3.fromRGB(220, 245, 236), SubText = Color3.fromRGB(130, 160, 150),
    Outline = Color3.fromRGB(38, 56, 51), Accent = Color3.fromRGB(64, 214, 164),
})

Themes["Midnight"] = buildTheme({
    BG = Color3.fromRGB(10, 10, 14), BG2 = Color3.fromRGB(16, 16, 22), BG3 = Color3.fromRGB(24, 24, 33),
    Text = Color3.fromRGB(230, 230, 240), SubText = Color3.fromRGB(130, 132, 150),
    Outline = Color3.fromRGB(36, 36, 48), Accent = Color3.fromRGB(160, 120, 255),
})

Themes["Rose"] = buildTheme({
    BG = Color3.fromRGB(26, 18, 24), BG2 = Color3.fromRGB(34, 23, 31), BG3 = Color3.fromRGB(45, 31, 41),
    Text = Color3.fromRGB(250, 230, 238), SubText = Color3.fromRGB(180, 145, 160),
    Outline = Color3.fromRGB(58, 40, 52), Accent = Color3.fromRGB(255, 110, 160),
})

Themes["Light"] = buildTheme({
    BG = Color3.fromRGB(245, 246, 250), BG2 = Color3.fromRGB(255, 255, 255), BG3 = Color3.fromRGB(234, 236, 244),
    Text = Color3.fromRGB(30, 32, 40), SubText = Color3.fromRGB(120, 124, 140),
    Outline = Color3.fromRGB(214, 217, 228), Accent = Color3.fromRGB(255, 100, 0),
})

local Theme = {}
for k, v in pairs(Themes["Chill"]) do Theme[k] = v end

-- registry of themeable instances: { inst, prop, key }
local registry = {}
local function reg(inst, prop, key)
    registry[#registry + 1] = { inst = inst, prop = prop, key = key }
    return inst
end

local function applyTheme()
    for i = 1, #registry do
        local e = registry[i]
        local inst = e.inst
        if inst and inst.Parent then
            local col = Theme[e.key]
            if col then pcall(function() inst[e.prop] = col end) end
        end
    end
end

local function setTheme(name)
    if not Themes[name] then return false end
    local accent = Theme.Accent
    local t = Themes[name]
    for k, v in pairs(t) do Theme[k] = v end
    -- keep the user's accent unless the theme defines its own and accent wasn't overridden
    Theme.Accent = accent
    local lum = accent.R * 0.299 + accent.G * 0.587 + accent.B * 0.114
    Theme.AccentText = lum > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    Theme.AccentDim = accent:Lerp(Theme.Window, 0.55)
    Theme.Round = t.Round
    Theme.RoundSmall = t.RoundSmall
    applyTheme()
    return true
end

local function setAccent(color)
    Theme.Accent = color
    local lum = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
    Theme.AccentText = lum > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    Theme.AccentDim = color:Lerp(Theme.Window, 0.55)
    applyTheme()
end

--=====================================================================
--  SETTINGS  (persisted to disk when the executor supports it)
--=====================================================================
local Settings = {
    Title      = "ChillHub",
    Subtitle   = "",
    Mode       = "Auto",              -- "Auto" | "Normal" | "Lite"
    Theme      = "Chill",
    Accent     = Color3.fromRGB(255, 100, 0),
    Folder     = "ChillHub",
    Keybind    = Enum.KeyCode.P,
    Center     = true,
    Config     = nil,                 -- autoload config name
    SaveWindow = true,
    Remember   = false,               -- remember the chosen mode
}

local function settingsPath()
    return Settings.Folder .. "/settings.json"
end

local function saveSettings()
    local data = {
        Mode    = Settings.Mode,
        Theme   = Settings.Theme,
        Remember= Settings.Remember,
        Config  = Settings.Config,
        Accent  = { Settings.Accent.R, Settings.Accent.G, Settings.Accent.B },
    }
    fsMakeFolder(Settings.Folder)
    fsWrite(settingsPath(), HttpService:JSONEncode(data))
end

local function loadSettings()
    local raw = fsRead(settingsPath())
    if not raw then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data) ~= "table" then return end
    if data.Mode and data.Remember then Settings.Mode = data.Mode end
    if data.Theme then Settings.Theme = data.Theme end
    if data.Remember ~= nil then Settings.Remember = data.Remember end
    if data.Config ~= nil then Settings.Config = data.Config end
    if type(data.Accent) == "table" and #data.Accent == 3 then
        Settings.Accent = Color3.new(data.Accent[1], data.Accent[2], data.Accent[3])
    end
end

--=====================================================================
--  GUI HOST (one ScreenGui holds everything)
--=====================================================================
local UI = {}
UI.Version  = VERSION
UI.Flags    = {}
UI.Theme    = Theme
UI.Config   = {}
UI.Themes   = Themes
UI.Settings = Settings

local Gui
local function ensureGui()
    if Gui and Gui.Parent then return Gui end
    Gui = new("ScreenGui", {
        Name = "ChillHubUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 2147483000,
    })
    local parented = false
    if type(gethui) == "function" then
        parented = pcall(function() Gui.Parent = gethui() end)
    end
    if not parented then
        parented = pcall(function() Gui.Parent = game:GetService("CoreGui") end)
    end
    if not parented or not Gui.Parent then
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, Gui)
    end
    return Gui
end
UI.Gui = nil

--=====================================================================
--  DRAG / RESIZE HELPERS
--=====================================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local c2 = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    return function() c1:Disconnect() c2:Disconnect() end
end

local function makeResizable(frame, grip)
    local dragging, startPos, startSize
    local c1 = grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startSize = frame.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if Settings.SaveWindow then UI:_saveWindow() end
                end
            end)
        end
    end)
    local c2 = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPos
            frame.Size = UDim2.fromOffset(
                math.max(460, startSize.X + delta.X),
                math.max(300, startSize.Y + delta.Y)
            )
        end
    end)
    return function() c1:Disconnect() c2:Disconnect() end
end

--=====================================================================
--  NOTIFICATIONS
--=====================================================================
local NotifyHolder

local NOTIFY_COLORS = {
    info    = function() return Theme.Accent end,
    success = function() return Color3.fromRGB(80, 210, 120) end,
    warn    = function() return Color3.fromRGB(245, 190, 70) end,
    error   = function() return Color3.fromRGB(240, 85, 85) end,
}

local function ensureNotify()
    if NotifyHolder and NotifyHolder.Parent then return NotifyHolder end
    local gui = ensureGui()
    NotifyHolder = new("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -40),
        Position = UDim2.new(1, -20, 0, 20),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 50,
        Parent = gui,
    })
    list(NotifyHolder, Enum.FillDirection.Vertical, 8)
    return NotifyHolder
end

-- opts: string text OR { Text=, Type=, Duration=, Title= }
function UI:Notify(a, b, c)
    if a == UI then a, b, c = b, c, nil end
    local text, kind, duration, title
    if type(a) == "table" then
        text = a.Text or a.Message or ""
        kind = a.Type or a.Kind or "info"
        duration = a.Duration or a.Time or 4
        title = a.Title
    else
        text = tostring(a or "")
        kind = b or "info"
        duration = c or 4
    end
    kind = string.lower(tostring(kind))
    if not NOTIFY_COLORS[kind] then kind = "info" end

    local holder = ensureNotify()
    local h = title and 58 or 40
    local toast = new("Frame", {
        Size = UDim2.new(1, 0, 0, h),
        BackgroundColor3 = Theme.Toast,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 50,
        Parent = holder,
    })
    corner(toast, Theme.RoundSmall)
    reg(toast, "BackgroundColor3", "Toast")
    stroke(toast, Theme.ElementLine, 1, 0.4)

    local accent = new("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = NOTIFY_COLORS[kind](),
        BorderSizePixel = 0,
        ZIndex = 51,
        Parent = toast,
    })

    local titleLbl
    if title then
        titleLbl = new("TextLabel", {
            Size = UDim2.new(1, -30, 0, 18),
            Position = UDim2.new(0, 14, 0, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(title),
            ZIndex = 51,
            Parent = toast,
        })
        reg(titleLbl, "TextColor3", "Text")
    end

    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -30, 0, h - (title and 26 or 16)),
        Position = UDim2.new(0, 14, 0, title and 26 or 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = title and Theme.SubText or Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Text = text,
        ZIndex = 51,
        Parent = toast,
    })
    reg(lbl, "TextColor3", title and "SubText" or "Text")

    local bar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = NOTIFY_COLORS[kind](),
        BorderSizePixel = 0,
        ZIndex = 52,
        Parent = toast,
    })

    if not Mode.Lite then
        toast.Position = UDim2.new(1, 60, 0, 0)
        tween(toast, { Position = UDim2.new(0, 0, 0, 0) }, 0.22)
        tween(bar, { Size = UDim2.new(0, 0, 0, 3) }, duration)
    else
        bar.Size = UDim2.new(0, 0, 0, 3)
    end

    local closed = false
    local function close()
        if closed then return end
        closed = true
        if Mode.Lite then
            toast:Destroy()
            return
        end
        local t = tween(toast, { Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1 }, 0.2)
        if lbl then tween(lbl, { TextTransparency = 1 }, 0.2) end
        task.delay(0.22, function() toast:Destroy() end)
    end
    task.delay(duration, close)
    toast.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then close() end
    end)
    return { Close = close, Instance = toast }
end

--=====================================================================
--  MODE CHOOSER (Lite vs Normal, shown on first load)
--=====================================================================
function UI:_chooseMode()
    local gui = ensureGui()
    local done = false
    local choice = "Normal"

    local overlay = new("Frame", {
        Name = "ModeChooser",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 60,
        Parent = gui,
    })

    local card = new("Frame", {
        Size = UDim2.new(0, 380, 0, 250),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        ZIndex = 61,
        Parent = overlay,
    })
    corner(card, Theme.Round)
    reg(card, "BackgroundColor3", "Window")
    stroke(card, Theme.WindowBorder, 1, 0.2)

    local logo = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = Theme.Text,
        Text = Settings.Title,
        ZIndex = 62,
        Parent = card,
    })
    reg(logo, "TextColor3", "Text")

    local sub = new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 20, 0, 50),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        Text = "Pick how you want the menu to run",
        ZIndex = 62,
        Parent = card,
    })
    reg(sub, "TextColor3", "SubText")

    local function modeButton(x, title, desc, value)
        local b = new("TextButton", {
            Size = UDim2.new(0, 160, 0, 92),
            Position = UDim2.new(0, x, 0, 80),
            BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 62,
            Parent = card,
        })
        corner(b, Theme.RoundSmall)
        reg(b, "BackgroundColor3", "Element")
        local st = stroke(b, Theme.ElementLine, 1, 0.3)

        local t = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0, 16),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = Theme.Text,
            Text = title,
            ZIndex = 63,
            Parent = b,
        })
        reg(t, "TextColor3", "Text")

        local d = new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 44),
            Position = UDim2.new(0, 10, 0, 42),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Theme.SubText,
            TextWrapped = true,
            Text = desc,
            ZIndex = 63,
            Parent = b,
        })
        reg(d, "TextColor3", "SubText")

        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.ElementHover }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Element }, 0.12) end)
        b.MouseButton1Click:Connect(function()
            if done then return end
            done = true
            choice = value
        end)
        return b
    end

    modeButton(20, "Normal", "All features: search bar, themes, tooltips, resize, everything.", "Normal")
    modeButton(200, "Lite", "Lighter + faster. No search, no tooltips, no animations.", "Lite")

    local rememberBox = new("TextButton", {
        Size = UDim2.new(0, 200, 0, 24),
        Position = UDim2.new(0, 20, 0, 190),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 62,
        Parent = card,
    })
    local check = new("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        ZIndex = 63,
        Parent = rememberBox,
    })
    corner(check, 4)
    reg(check, "BackgroundColor3", "Input")
    stroke(check, Theme.ElementLine, 1, 0.2)
    local checkMark = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.AccentText,
        Text = "",
        ZIndex = 64,
        Parent = check,
    })
    local remember = false
    rememberBox.MouseButton1Click:Connect(function()
        remember = not remember
        checkMark.Text = remember and "X" or ""
        check.BackgroundColor3 = remember and Theme.Accent or Theme.Input
    end)
    local remLbl = new("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Remember my choice",
        ZIndex = 63,
        Parent = rememberBox,
    })
    reg(remLbl, "TextColor3", "SubText")

    while not done do
        task.wait(0.05)
    end
    Settings.Remember = remember
    if remember then
        Settings.Mode = choice
        saveSettings()
    end
    overlay:Destroy()
    return choice
end

--=====================================================================
--  LOADING SCREEN
--=====================================================================
-- UI.Loading{ Title=, Subtitle=, Icon=, TotalSteps= }
--   :Message(text)          main status line
--   :Description(text)      secondary line
--   :Step(n, text)          set current step (updates progress)
--   :Progress(0..1)         manual progress
--   :Log(text)              append a line to the sidebar log (Normal)
--   :Close()                fade out and destroy
function UI.Loading(cfg)
    cfg = cfg or {}
    local gui = ensureGui()
    local total = math.max(1, tonumber(cfg.TotalSteps) or 1)
    local current = 0

    local overlay = new("Frame", {
        Name = "LoadingScreen",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        ZIndex = 80,
        Parent = gui,
    })
    reg(overlay, "BackgroundColor3", "Window")

    local bg = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 80,
        Parent = overlay,
    })
    reg(bg, "BackgroundColor3", "Accent")

    local card = new("Frame", {
        Size = UDim2.new(0, 460, 0, 230),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 82,
        Parent = overlay,
    })

    local icon
    if cfg.Icon then
        icon = new("ImageLabel", {
            Size = UDim2.new(0, 64, 0, 64),
            Position = UDim2.new(0.5, 0, 0, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Image = cfg.Icon,
            ZIndex = 82,
            Parent = card,
        })
    end

    local titleY = icon and 80 or 20
    local title = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, titleY),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 26,
        TextColor3 = Theme.Text,
        Text = cfg.Title or Settings.Title,
        ZIndex = 82,
        Parent = card,
    })
    reg(title, "TextColor3", "Text")

    local sub = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, titleY + 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.SubText,
        Text = cfg.Subtitle or "",
        ZIndex = 82,
        Parent = card,
    })
    reg(sub, "TextColor3", "SubText")

    local barBg = new("Frame", {
        Size = UDim2.new(0.8, 0, 0, 6),
        Position = UDim2.new(0.5, 0, 0, titleY + 70),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        ZIndex = 82,
        Parent = card,
    })
    corner(barBg, 6)
    reg(barBg, "BackgroundColor3", "Element")

    local barFill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 83,
        Parent = barBg,
    })
    corner(barFill, 6)
    reg(barFill, "BackgroundColor3", "Accent")

    local status = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, titleY + 86),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.DimText,
        Text = cfg.Message or "Loading...",
        ZIndex = 82,
        Parent = card,
    })
    reg(status, "TextColor3", "DimText")

    local pct = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, titleY + 106),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        Text = "0%",
        ZIndex = 82,
        Parent = card,
    })
    reg(pct, "TextColor3", "Accent")

    -- sidebar log (Normal only)
    local logHolder
    if not Mode.Lite then
        logHolder = new("Frame", {
            Size = UDim2.new(0, 220, 0, 230),
            Position = UDim2.new(1, -20, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Theme.Window,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            ZIndex = 82,
            Parent = overlay,
        })
        corner(logHolder, Theme.RoundSmall)
        reg(logHolder, "BackgroundColor3", "Window")
        stroke(logHolder, Theme.ElementLine, 1, 0.5)
        local lh = new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "ChillHub",
            ZIndex = 83,
            Parent = logHolder,
        })
        reg(lh, "TextColor3", "SubText")
        logHolder:SetAttribute("Header", true)
    end
    local logCount = 0
    local function addLog(text)
        if not logHolder then return end
        logCount = logCount + 1
        new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 10, 0, 30 + (logCount - 1) * 17),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Theme.DimText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(text),
            ZIndex = 83,
            Parent = logHolder,
        })
    end

    local obj = {}
    local function setProgress(frac)
        frac = clamp(frac, 0, 1)
        pct.Text = round(frac * 100) .. "%"
        tween(barFill, { Size = UDim2.new(frac, 0, 1, 0) }, 0.2)
    end

    function obj:Message(text)
        status.Text = tostring(text)
        addLog(text)
        return obj
    end
    function obj:Description(text)
        sub.Text = tostring(text)
        return obj
    end
    function obj:SetMessage(t) return obj:Message(t) end
    function obj:SetDescription(t) return obj:Description(t) end
    function obj:Log(text) addLog(text) return obj end
    function obj:Progress(frac) setProgress(frac) return obj end
    function obj:Step(n, text)
        current = math.max(current, tonumber(n) or current)
        setProgress(current / total)
        if text then status.Text = tostring(text) addLog(text) end
        return obj
    end
    function obj:SetCurrentStep(n) return obj:Step(n) end
    function obj:Close()
        if Mode.Lite then
            overlay:Destroy()
            return
        end
        tween(overlay, { BackgroundTransparency = 1 }, 0.3)
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") then
                tween(d, { TextTransparency = 1 }, 0.3)
            elseif d:IsA("ImageLabel") then
                tween(d, { ImageTransparency = 1 }, 0.3)
            end
        end
        task.delay(0.32, function() overlay:Destroy() end)
    end
    function obj:Destroy() overlay:Destroy() end
    obj.Instance = overlay
    obj.Sidebar = { AddLabel = function(_, t) addLog(t) end }
    return obj
end

--=====================================================================
--  REGISTRIES
--=====================================================================
UI._controls = {}   -- flag -> control
UI._search   = {}   -- searchable entries
UI._usedFlags= {}
UI._unloads  = {}
UI._tabs     = {}
local Typing = false          -- true while a text box is focused

local function makeFlag(text)
    local base = tostring(text or "flag"):gsub("[^%w]", "_")
    if base == "" then base = "flag" end
    local name = base
    local i = 1
    while UI._usedFlags[name] do
        i = i + 1
        name = base .. "_" .. i
    end
    UI._usedFlags[name] = true
    return name
end

--=====================================================================
--  TOOLTIPS
--=====================================================================
local function attachTooltip(inst, text)
    if Mode.Lite or not text then return end
    local tip
    inst.MouseEnter:Connect(function()
        local gui = ensureGui()
        if tip and tip.Parent then tip:Destroy() end
        tip = new("TextLabel", {
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Toast,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Theme.Text,
            Text = "  " .. tostring(text) .. "  ",
            BorderSizePixel = 0,
            ZIndex = 200,
            Parent = gui,
        })
        corner(tip, 5)
        stroke(tip, Theme.ElementLine, 1, 0.3)
        reg(tip, "BackgroundColor3", "Toast")
        reg(tip, "TextColor3", "Text")
        local pos = inst.AbsolutePosition
        tip.Position = UDim2.fromOffset(pos.X, pos.Y - 26)
    end)
    inst.MouseLeave:Connect(function()
        if tip and tip.Parent then tip:Destroy() end
        tip = nil
    end)
end

--=====================================================================
--  CONTROL BASE
--=====================================================================
local Control = {}
Control.__index = Control

local function fire(ctrl, value)
    local cbs = ctrl.Callbacks
    for i = 1, #cbs do
        local ok, err = pcall(cbs[i], value)
        if not ok then warn("[ChillHubUI] callback error: " .. tostring(err)) end
    end
end

function Control:GetValue() return self.Value end
function Control:SetValue(v, silent)
    self.Value = v
    if self._apply then pcall(self._apply, v) end
    if self.Flag then UI.Flags[self.Flag] = v end
    if not silent then fire(self, v) end
    return self
end
function Control:OnChanged(fn)
    table.insert(self.Callbacks, fn)
    return self
end
function Control:SetVisible(v)
    if self.Instance then self.Instance.Visible = v end
    return self
end
function Control:SetText(t)
    self.Text = tostring(t)
    if self.TextInstance then self.TextInstance.Text = tostring(t) end
    return self
end
function Control:Tooltip(t)
    if self.Instance then attachTooltip(self.Instance, t) end
    return self
end
function Control:Destroy()
    if self.Instance then self.Instance:Destroy() end
    return self
end

local function baseControl(section, kind, text, opts)
    opts = opts or {}
    local ctrl = setmetatable({
        Kind = kind,
        Text = tostring(text or ""),
        Section = section,
        Options = opts,
        Callbacks = {},
    }, Control)
    if opts.Callback then table.insert(ctrl.Callbacks, opts.Callback) end
    if opts.Flag then
        ctrl.Flag = opts.Flag
    else
        ctrl.Flag = makeFlag(text)
    end
    UI._controls[ctrl.Flag] = ctrl
    if not Mode.Lite and text and text ~= "" then
        UI._search[#UI._search + 1] = { text = ctrl.Text, tab = section.Tab, section = section, control = ctrl }
    end
    return ctrl
end

local function rowFrame(parent, height)
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        Parent = parent,
    })
end

local function textLabel(parent, props)
    local base = {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    }
    for k, v in pairs(props or {}) do base[k] = v end
    local lbl = new("TextLabel", base)
    return lbl
end

--=====================================================================
--  SECTION (groupbox)
--=====================================================================
local Section = {}
Section.__index = Section

function Section:_add(ctrl, inst)
    ctrl.Instance = inst
    if ctrl.Options.Tooltip then attachTooltip(inst, ctrl.Options.Tooltip) end
    return ctrl
end

function Section:Label(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "Label", text, opts)
    local lbl = textLabel(self.Body, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = opts.TextSize or 13,
        TextWrapped = true,
        Text = tostring(text),
    })
    reg(lbl, "TextColor3", opts.Color or "Text")
    ctrl.TextInstance = lbl
    return self:_add(ctrl, lbl)
end

function Section:Paragraph(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "Paragraph", text, opts)
    local lbl = textLabel(self.Body, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = opts.TextSize or 12,
        TextColor3 = Theme.SubText,
        TextWrapped = true,
        Text = tostring(text),
    })
    reg(lbl, "TextColor3", opts.Color or "SubText")
    ctrl.TextInstance = lbl
    return self:_add(ctrl, lbl)
end

function Section:Divider()
    local ctrl = baseControl(self, "Divider", "", { Flag = false })
    local d = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        Parent = self.Body,
    })
    reg(d, "BackgroundColor3", "Divider")
    return self:_add(ctrl, d)
end

function Section:Button(text, callback, opts)
    if type(callback) == "table" then opts = callback callback = opts.Callback end
    opts = opts or {}
    local ctrl = baseControl(self, "Button", text, opts)
    if callback then table.insert(ctrl.Callbacks, callback) end

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.Text,
        Text = tostring(text),
        AutoButtonColor = false,
        Parent = self.Body,
    })
    corner(btn, Theme.RoundSmall)
    reg(btn, "BackgroundColor3", "Element")
    reg(btn, "TextColor3", "Text")
    stroke(btn, Theme.ElementLine, 1, 0.35)

    btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.1) end)
    btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Theme.Element }, 0.1) end)
    btn.MouseButton1Click:Connect(function()
        if ctrl._onClick then ctrl._onClick() end
        fire(ctrl, nil)
    end)
    return self:_add(ctrl, btn)
end

function Section:Input(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "Input", text, opts)
    local row = rowFrame(self.Body, 30)

    local lbl = textLabel(row, {
        Size = UDim2.new(0.45, 0, 1, 0),
        Text = tostring(text),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(lbl, "TextColor3", "Text")

    local box = new("TextBox", {
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0.45, 0, 0, 0),
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.DimText,
        PlaceholderText = opts.Placeholder or "",
        Text = tostring(opts.Default or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = row,
    })
    corner(box, Theme.RoundSmall)
    reg(box, "BackgroundColor3", "Input")
    reg(box, "TextColor3", "InputText")
    stroke(box, Theme.ElementLine, 1, 0.35)
    padding(box, 0, 8, 0, 8)

    local function commit()
        local v = box.Text
        if opts.Numeric then
            v = v:gsub("[^%d%.%-]", "")
            if v == "" or v == "-" or v == "." then v = tostring(opts.Default or 0) end
            box.Text = v
        end
        if ctrl._onInput then ctrl._onInput(v) end
        Control.SetValue(ctrl, v)
    end

    box.Focused:Connect(function() Typing = true end)
    box.FocusLost:Connect(function(enterPressed)
        Typing = false
        if opts.Finished and not enterPressed then return end
        commit()
    end)

    ctrl._apply = function(v)
        if box.Text ~= tostring(v) then box.Text = tostring(v) end
    end
    ctrl._onInput = opts.OnInput
    ctrl.TextInstance = lbl
    ctrl.Value = tostring(opts.Default or "")
    UI.Flags[ctrl.Flag] = ctrl.Value
    return self:_add(ctrl, row)
end

--=====================================================================
--  SHARED DRAG MANAGER (one pair of connections for every slider/bar)
--=====================================================================
local dragActive = nil
local function beginDrag(move, stop)
    dragActive = { move = move, stop = stop }
end
svc(UserInputService.InputChanged, function(input)
    if not dragActive then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragActive.move(input)
    end
end)
svc(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragActive and dragActive.stop then dragActive.stop() end
        dragActive = nil
    end
end)

--=====================================================================
--  TOGGLE
--=====================================================================
function Section:Toggle(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "Toggle", text, opts)
    local row = rowFrame(self.Body, 30)
    row.Active = true

    local lbl = textLabel(row, {
        Size = UDim2.new(1, -50, 1, 0),
        Text = tostring(text),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(lbl, "TextColor3", "Text")

    local switch = new("Frame", {
        Size = UDim2.new(0, 34, 0, 18),
        Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(switch, 9)
    local knob = new("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = switch,
    })
    corner(knob, 7)

    ctrl._apply = function(v)
        v = v == true
        tween(switch, { BackgroundColor3 = v and Theme.Accent or Theme.ToggleOff }, 0.12)
        tween(knob, { Position = UDim2.new(v and 1 or 0, v and -16 or 2, 0.5, -7) }, 0.12)
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Control.SetValue(ctrl, not ctrl.Value)
        end
    end)

    ctrl.TextInstance = lbl
    ctrl.Value = opts.Default == true
    UI.Flags[ctrl.Flag] = ctrl.Value
    ctrl._apply(ctrl.Value)
    return self:_add(ctrl, row)
end

--=====================================================================
--  SLIDER
--=====================================================================
function Section:Slider(text, opts)
    opts = opts or {}
    local min = tonumber(opts.Min) or 0
    local max = tonumber(opts.Max) or 100
    local rounding = tonumber(opts.Rounding) or 0
    local suffix = opts.Suffix or ""
    local ctrl = baseControl(self, "Slider", text, opts)

    local row = rowFrame(self.Body, 38)
    local lbl = textLabel(row, {
        Size = UDim2.new(1, -60, 0, 16),
        Text = tostring(text),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(lbl, "TextColor3", "Text")
    local val = textLabel(row, {
        Size = UDim2.new(0, 55, 0, 16),
        Position = UDim2.new(1, -55, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        Text = "",
    })
    reg(val, "TextColor3", "Accent")

    local bar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(bar, 6)
    reg(bar, "BackgroundColor3", "Element")
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })
    corner(fill, 6)
    reg(fill, "BackgroundColor3", "Accent")
    local knob = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = bar,
    })
    corner(knob, 6)

    local function snap(v)
        if rounding > 0 then return math.floor(v / rounding + 0.5) * rounding end
        return math.floor(v + 0.5)
    end

    ctrl._apply = function(v)
        v = tonumber(v) or min
        v = clamp(v, min, max)
        local rel = (max - min == 0) and 0 or (v - min) / (max - min)
        tween(fill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.08)
        tween(knob, { Position = UDim2.new(rel, 0, 0.5, 0) }, 0.08)
        val.Text = tostring(v) .. suffix
    end

    local function setFromX(x)
        local rel = clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        Control.SetValue(ctrl, clamp(snap(min + (max - min) * rel), min, max))
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
            beginDrag(function(i) setFromX(i.Position.X) end, nil)
        end
    end)

    ctrl.TextInstance = lbl
    ctrl.Value = clamp(tonumber(opts.Default) or min, min, max)
    UI.Flags[ctrl.Flag] = ctrl.Value
    ctrl._apply(ctrl.Value)
    return self:_add(ctrl, row)
end

--=====================================================================
--  DROPDOWN
--=====================================================================
function Section:Dropdown(text, opts)
    opts = opts or {}
    local multi = opts.Multi == true
    local ctrl = baseControl(self, "Dropdown", text, opts)
    local values = {}

    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self.Body,
    })
    list(wrap, Enum.FillDirection.Vertical, 4)

    local lbl = textLabel(wrap, {
        Size = UDim2.new(1, 0, 0, 16),
        Text = tostring(text),
    })
    reg(lbl, "TextColor3", "Text")

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = wrap,
    })
    corner(btn, Theme.RoundSmall)
    reg(btn, "BackgroundColor3", "Input")
    stroke(btn, Theme.ElementLine, 1, 0.35)

    local btnText = textLabel(btn, {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Text = "",
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local arrow = textLabel(btn, {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -22, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.SubText,
        Text = "v",
    })
    reg(arrow, "TextColor3", "SubText")

    local listFrame = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = wrap,
    })
    corner(listFrame, Theme.RoundSmall)
    reg(listFrame, "BackgroundColor3", "Input")
    stroke(listFrame, Theme.ElementLine, 1, 0.35)
    padding(listFrame, 4, 4, 4, 4)
    list(listFrame, Enum.FillDirection.Vertical, 2)

    local selected = {}

    local function refreshText()
        if multi then
            local out = {}
            for _, v in ipairs(values) do
                if selected[v] then out[#out + 1] = v end
            end
            btnText.Text = #out > 0 and table.concat(out, ", ") or "None"
        else
            local v = next(selected)
            btnText.Text = v or "None"
        end
    end

    local function buildList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, v in ipairs(values) do
            local ob = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.Text,
                Text = tostring(v),
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                Parent = listFrame,
            })
            padding(ob, 0, 6, 0, 6)
            ob.MouseEnter:Connect(function() tween(ob, { BackgroundTransparency = 0.6 }, 0.1) end)
            ob.MouseLeave:Connect(function() tween(ob, { BackgroundTransparency = 1 }, 0.1) end)
            ob.MouseButton1Click:Connect(function()
                if multi then
                    selected[v] = not selected[v] or nil
                    ob.TextColor3 = selected[v] and Theme.Accent or Theme.Text
                    refreshText()
                    local arr = {}
                    for _, val in ipairs(values) do
                        if selected[val] then arr[#arr + 1] = val end
                    end
                    Control.SetValue(ctrl, arr)
                else
                    selected = { [v] = true }
                    refreshText()
                    listFrame.Visible = false
                    Control.SetValue(ctrl, v)
                end
            end)
        end
        listFrame.Size = UDim2.new(1, 0, 0, math.min(#values * 24 + 8, 150))
    end

    btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
        arrow.Text = listFrame.Visible and "^" or "v"
    end)

    ctrl._apply = function(v)
        if multi then
            selected = {}
            if type(v) == "table" then
                for _, x in ipairs(v) do selected[tostring(x)] = true end
            end
        else
            selected = {}
            if v ~= nil then selected[tostring(v)] = true end
        end
        refreshText()
    end

    function ctrl:SetValues(newValues)
        values = {}
        for _, v in ipairs(newValues or {}) do values[#values + 1] = tostring(v) end
        buildList()
        return self
    end

    if opts.Players then
        local function refreshPlayers()
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if not (opts.ExcludeLocal and p == LocalPlayer) then
                    names[#names + 1] = p.Name
                end
            end
            table.sort(names)
            ctrl:SetValues(names)
        end
        refreshPlayers()
        Players.PlayerAdded:Connect(refreshPlayers)
        Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshPlayers() end)
        ctrl.Refresh = refreshPlayers
    else
        ctrl:SetValues(opts.Options or opts.Values or {})
    end

    ctrl.TextInstance = lbl
    local def = opts.Default
    ctrl._apply(def)
    if multi then
        ctrl.Value = (type(def) == "table") and def or {}
    else
        ctrl.Value = def ~= nil and tostring(def) or nil
    end
    UI.Flags[ctrl.Flag] = ctrl.Value
    ctrl._listFrame = listFrame
    return self:_add(ctrl, wrap)
end

--=====================================================================
--  KEYBIND
--=====================================================================
local keybindList = {}
local listeningCtrl = nil

local function keyName(key)
    if not key then return "None" end
    if typeof(key) == "EnumItem" then return key.Name end
    return tostring(key)
end

function Section:Keybind(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "Keybind", text, opts)
    ctrl.Mode = opts.Mode or "Toggle"
    ctrl.Toggled = false

    local row = rowFrame(self.Body, 30)
    local lbl = textLabel(row, {
        Size = UDim2.new(1, -84, 1, 0),
        Text = tostring(text),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(lbl, "TextColor3", "Text")

    local btn = new("TextButton", {
        Size = UDim2.new(0, 80, 0, 26),
        Position = UDim2.new(1, -80, 0.5, -13),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(btn, Theme.RoundSmall)
    reg(btn, "BackgroundColor3", "Element")
    stroke(btn, Theme.ElementLine, 1, 0.35)
    local btnText = textLabel(btn, {
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamMedium,
        Text = "",
    })

    ctrl._visual = function()
        btnText.Text = keyName(ctrl.Key)
        if ctrl.Mode == "Toggle" then
            btnText.TextColor3 = ctrl.Toggled and Theme.Accent or Theme.Text
        end
    end

    btn.MouseButton1Click:Connect(function()
        listeningCtrl = ctrl
        btnText.Text = "..."
    end)

    ctrl._apply = function(v)
        if typeof(v) == "EnumItem" then ctrl.Key = v end
        ctrl._visual()
    end

    local def = opts.Default
    if type(def) == "string" then
        local ok, k = pcall(function() return Enum.KeyCode[def] end)
        def = ok and k or nil
    end
    ctrl.Key = def or Enum.KeyCode.Unknown
    ctrl.Value = ctrl.Key
    UI.Flags[ctrl.Flag] = ctrl.Key
    ctrl.TextInstance = lbl
    keybindList[#keybindList + 1] = ctrl
    ctrl._visual()
    return self:_add(ctrl, row)
end

svc(UserInputService.InputBegan, function(input, gameProcessed)
    if listeningCtrl then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local c = listeningCtrl
            listeningCtrl = nil
            c.Key = input.KeyCode
            c.Value = input.KeyCode
            UI.Flags[c.Flag] = input.KeyCode
            c._visual()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            listeningCtrl._visual()
            listeningCtrl = nil
        end
        return
    end
    if gameProcessed or Typing then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for _, kb in ipairs(keybindList) do
        if kb.Key == input.KeyCode and kb.Key ~= Enum.KeyCode.Unknown then
            if kb.Mode == "Hold" then
                fire(kb, true)
            elseif kb.Mode == "Press" then
                fire(kb, true)
            else
                kb.Toggled = not kb.Toggled
                kb._visual()
                fire(kb, kb.Toggled)
            end
        end
    end
end)

svc(UserInputService.InputEnded, function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for _, kb in ipairs(keybindList) do
        if kb.Key == input.KeyCode and kb.Mode == "Hold" then fire(kb, false) end
    end
end)

--=====================================================================
--  COLOR PICKER
--=====================================================================
function Section:ColorPicker(text, opts)
    opts = opts or {}
    local ctrl = baseControl(self, "ColorPicker", text, opts)
    local color = opts.Default or Color3.fromRGB(255, 100, 0)

    local row = rowFrame(self.Body, 30)
    local lbl = textLabel(row, {
        Size = UDim2.new(1, -50, 1, 0),
        Text = tostring(text),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(lbl, "TextColor3", "Text")

    local swatch = new("TextButton", {
        Size = UDim2.new(0, 34, 0, 20),
        Position = UDim2.new(1, -34, 0.5, -10),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(swatch, Theme.RoundSmall)
    stroke(swatch, Theme.ElementLine, 1, 0.3)

    local panel = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Body,
    })
    list(panel, Enum.FillDirection.Vertical, 6)

    -- saturation / value square
    local sv = new("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(sv, Theme.RoundSmall)
    local svWhite = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = sv,
    })
    corner(svWhite, Theme.RoundSmall)
    local svGrad = new("UIGradient", { Parent = svWhite })
    local svBlack = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Parent = sv,
    })
    corner(svBlack, Theme.RoundSmall)
    new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = svBlack,
    })
    local svKnob = new("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = sv,
    })
    corner(svKnob, 5)
    stroke(svKnob, Color3.new(0, 0, 0), 1, 0.4)

    -- hue bar
    local hue = new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = panel,
    })
    corner(hue, 6)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hue,
    })
    local hueKnob = new("Frame", {
        Size = UDim2.new(0, 8, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = hue,
    })
    corner(hueKnob, 4)
    stroke(hueKnob, Color3.new(0, 0, 0), 1, 0.4)

    local hex = textLabel(panel, {
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        Text = "#FFFFFF",
    })
    reg(hex, "TextColor3", "SubText")

    local h, s, v = color:ToHSV()

    local function paint()
        local col = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = col
        svGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
        svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        hex.Text = string.format("#%02X%02X%02X", round(col.R * 255), round(col.G * 255), round(col.B * 255))
        ctrl.Value = col
        UI.Flags[ctrl.Flag] = col
    end

    local function commit()
        paint()
        fire(ctrl, Color3.fromHSV(h, s, v))
    end

    sv.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local function move(i)
            s = clamp((i.Position.X - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
            v = 1 - clamp((i.Position.Y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
            paint()
        end
        move(input)
        beginDrag(move, commit)
    end)
    hue.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local function move(i)
            h = clamp((i.Position.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
            paint()
        end
        move(input)
        beginDrag(move, commit)
    end)

    swatch.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)

    ctrl._apply = function(c)
        if typeof(c) == "Color3" then
            h, s, v = c:ToHSV()
            paint()
        end
    end

    ctrl.Value = color
    UI.Flags[ctrl.Flag] = color
    ctrl.TextInstance = lbl
    ctrl.SetColor = function(_, c) Control.SetValue(ctrl, c) end
    paint()
    return self:_add(ctrl, row)
end

--=====================================================================
--  CONTROL CHAINING  (toggle:ColorPicker(...) / :Keybind(...) / :Slider(...))
--=====================================================================
function Control:ColorPicker(text, opts)
    opts = opts or {}
    return self.Section:ColorPicker(text or (self.Text .. " Color"), opts)
end
function Control:Keybind(text, opts)
    opts = opts or {}
    return self.Section:Keybind(text or (self.Text .. " Key"), opts)
end
function Control:Slider(text, opts)
    opts = opts or {}
    return self.Section:Slider(text or (self.Text .. " Value"), opts)
end
function Control:Toggle(text, opts)
    opts = opts or {}
    return self.Section:Toggle(text or (self.Text .. " Enabled"), opts)
end
function Control:Dropdown(text, opts)
    opts = opts or {}
    return self.Section:Dropdown(text or (self.Text .. " Option"), opts)
end
function Control:Input(text, opts)
    opts = opts or {}
    return self.Section:Input(text or (self.Text .. " Input"), opts)
end

--=====================================================================
--  SECTION CONSTRUCTOR
--=====================================================================
function Section.new(tab, cfg)
    if type(cfg) == "string" then cfg = { Name = cfg } end
    cfg = cfg or {}
    local side = cfg.Side or "Left"
    local self = setmetatable({
        Tab = tab,
        Name = cfg.Name or "Section",
        Side = side,
    }, Section)

    local col = (side == "Right") and tab.RightCol or tab.LeftCol
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Section,
        BorderSizePixel = 0,
        Parent = col,
    })
    corner(frame, Theme.Round)
    reg(frame, "BackgroundColor3", "Section")
    stroke(frame, Theme.SectionLine, 1, 0.35)
    list(frame, Enum.FillDirection.Vertical, 0)

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = frame,
    })
    local hlbl = textLabel(header, {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = self.Name,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    reg(hlbl, "TextColor3", "SectionText")
    local line = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.SectionLine,
        BorderSizePixel = 0,
        Parent = frame,
    })
    reg(line, "BackgroundColor3", "SectionLine")

    local body = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = frame,
    })
    list(body, Enum.FillDirection.Vertical, 8)
    padding(body, 8, 8, 8, 8)

    self.Frame = frame
    self.Body = body
    self.Header = hlbl
    tab.Sections[#tab.Sections + 1] = self
    return self
end

function Section:SetVisible(v)
    self.Frame.Visible = v
    return self
end
function Section:SetName(n)
    self.Name = tostring(n)
    self.Header.Text = self.Name
    return self
end

--=====================================================================
--  ICONS
--=====================================================================
local ICONS = {
    home = "\u{1F3E0}", settings = "\u{2699}\u{FE0F}", user = "\u{1F464}", player = "\u{1F464}",
    eye = "\u{1F441}\u{FE0F}", zap = "\u{26A1}", star = "\u{2B50}", sword = "\u{2694}\u{FE0F}",
    shield = "\u{1F6E1}\u{FE0F}", map = "\u{1F5FA}\u{FE0F}", gamepad = "\u{1F3AE}", party = "\u{1F389}",
    sparkles = "\u{2728}", plane = "\u{2708}\u{FE0F}", ghost = "\u{1F47B}", key = "\u{1F511}",
    refresh = "\u{1F504}", info = "\u{2139}\u{FE0F}", bell = "\u{1F514}", search = "\u{1F50D}",
    fire = "\u{1F525}", heart = "\u{2764}\u{FE0F}", tool = "\u{1F527}", folder = "\u{1F4C1}",
    lock = "\u{1F512}", gift = "\u{1F381}", crown = "\u{1F451}", rocket = "\u{1F680}",
    clock = "\u{1F552}", chart = "\u{1F4CA}", money = "\u{1F4B0}", apple = "\u{1F34E}",
    hand = "\u{270B}", link = "\u{1F517}", bug = "\u{1F41E}", bolt = "\u{26A1}",
}

local function resolveIcon(icon)
    if type(icon) ~= "string" or icon == "" then return nil end
    if icon:match("^rbxasset") or icon:match("^http") then
        return { kind = "image", value = icon }
    end
    local key = string.lower(icon)
    if ICONS[key] then return { kind = "text", value = ICONS[key] } end
    return nil
end

--=====================================================================
--  TAB
--=====================================================================
local Tab = {}
Tab.__index = Tab

local function makeColumns(parent)
    local left = new("ScrollingFrame", {
        Size = UDim2.new(0.5, -6, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Scrollbar,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    list(left, Enum.FillDirection.Vertical, 8)
    local right = new("ScrollingFrame", {
        Size = UDim2.new(0.5, -6, 1, 0),
        Position = UDim2.new(0.5, 6, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Scrollbar,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    list(right, Enum.FillDirection.Vertical, 8)
    return left, right
end

function Tab:Section(a, b)
    local cfg
    if type(a) == "table" then cfg = a else cfg = { Name = a, Side = b } end
    return Section.new(self, cfg)
end

function Tab:Select()
    self.Window:SelectTab(self)
    return self
end

function Tab:SetVisible(v)
    self.Content.Visible = v
    return self
end

--=====================================================================
--  WINDOW
--=====================================================================
local Window = {}
Window.__index = Window

function UI:_windowPath()
    return Settings.Folder .. "/window.json"
end

function UI:_saveWindow()
    local w = UI.Window_ or self.Window_
    if not w or not Settings.SaveWindow then return end
    fsMakeFolder(Settings.Folder)
    fsWrite(self:_windowPath(), HttpService:JSONEncode({
        X = w.Frame.Position.X.Offset, Y = w.Frame.Position.Y.Offset,
        W = w.Frame.AbsoluteSize.X, H = w.Frame.AbsoluteSize.Y,
    }))
end

function UI:_loadWindow()
    local raw = fsRead(self:_windowPath())
    if not raw then return nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok and type(data) == "table" then return data end
    return nil
end

function UI.Window(cfg)
    cfg = cfg or {}
    if not UI._settingsLoaded then
        loadSettings()
        UI._settingsLoaded = true
        setTheme(Settings.Theme)
        setAccent(Settings.Accent)
    end
    if Settings.Mode == "Auto" then
        Mode.Name = UI:_chooseMode()
    else
        Mode.Name = Settings.Mode
    end
    Mode.Lite = (Mode.Name == "Lite")

    local gui = ensureGui()
    UI.Gui = gui

    local title = cfg.Title or Settings.Title
    local subtitle = cfg.Subtitle or Settings.Subtitle
    local saved = UI:_loadWindow()

    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local defW = clamp(round(vp.X * (UserInputService.TouchEnabled and 0.9 or 0.62)), 460, 660)
    local defH = clamp(round(vp.Y * (UserInputService.TouchEnabled and 0.8 or 0.66)), 320, 540)

    local self = setmetatable({
        Tabs = {},
        TabButtons = {},
        ActiveTab = nil,
        Minimized = false,
        Hidden = false,
        Title = title,
    }, Window)

    local main = new("Frame", {
        Name = "ChillHubWindow",
        Size = UDim2.fromOffset(saved and saved.W or defW, saved and saved.H or defH),
        Position = (saved and UDim2.fromOffset(saved.X, saved.Y))
            or (Settings.Center and UDim2.new(0.5, 0, 0.5, 0) or UDim2.fromOffset(60, 60)),
        AnchorPoint = (saved and Vector2.new(0, 0)) or (Settings.Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0)),
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = gui,
    })
    corner(main, Theme.Round)
    reg(main, "BackgroundColor3", "Window")
    stroke(main, Theme.WindowBorder, 1, 0.2)

    -- title bar
    local titleBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.TitleBar,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = main,
    })
    reg(titleBar, "BackgroundColor3", "TitleBar")
    local titleLine = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.SectionLine,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = titleBar,
    })
    reg(titleLine, "BackgroundColor3", "SectionLine")

    local icon = resolveIcon(cfg.Icon)
    local titleX = 12
    if icon then
        if icon.kind == "image" then
            new("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, -9),
                BackgroundTransparency = 1,
                Image = icon.value,
                ZIndex = 12,
                Parent = titleBar,
            })
        else
            textLabel(titleBar, {
                Size = UDim2.new(0, 18, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Text = icon.value,
                TextSize = 14,
                ZIndex = 12,
            })
        end
        titleX = 34
    end

    local titleLbl = textLabel(titleBar, {
        Size = UDim2.new(1, -titleX - 150, 1, 0),
        Position = UDim2.new(0, titleX, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Text = title,
        ZIndex = 12,
    })
    reg(titleLbl, "TextColor3", "Text")

    if subtitle ~= "" then
        local sub = textLabel(titleBar, {
            Size = UDim2.new(0, 140, 1, 0),
            Position = UDim2.new(1, -230, 0, 0),
            TextSize = 11,
            TextColor3 = Theme.SubText,
            Text = subtitle,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12,
        })
        reg(sub, "TextColor3", "SubText")
    end

    -- window buttons
    local function titleButton(text, x, color)
        local b = new("TextButton", {
            Size = UDim2.new(0, 26, 0, 26),
            Position = UDim2.new(1, x, 0.5, -13),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Theme.SubText,
            Text = text,
            AutoButtonColor = false,
            ZIndex = 12,
            Parent = titleBar,
        })
        corner(b, 5)
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundTransparency = 0.6, TextColor3 = color or Theme.Text }, 0.1)
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundTransparency = 1, TextColor3 = Theme.SubText }, 0.1)
        end)
        return b
    end

    local closeBtn = titleButton("X", -8, Color3.fromRGB(255, 90, 90))
    closeBtn.MouseButton1Click:Connect(function() UI:Unload() end)

    local minBtn = titleButton("-", -38)
    minBtn.MouseButton1Click:Connect(function() self:Minimize() end)

    -- search
    local searchBox
    if not Mode.Lite then
        searchBox = new("TextBox", {
            Size = UDim2.new(0, 130, 0, 22),
            Position = UDim2.new(1, -180, 0.5, -11),
            BackgroundColor3 = Theme.Input,
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.DimText,
            PlaceholderText = "Search...",
            Text = "",
            ClearTextOnFocus = false,
            ZIndex = 12,
            Parent = titleBar,
        })
        corner(searchBox, Theme.RoundSmall)
        reg(searchBox, "BackgroundColor3", "Input")
        reg(searchBox, "TextColor3", "InputText")
        stroke(searchBox, Theme.ElementLine, 1, 0.4)
        padding(searchBox, 0, 8, 0, 8)
    end

    -- body
    local body = new("Frame", {
        Size = UDim2.new(1, 0, 1, -34),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = 11,
        Parent = main,
    })

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = body,
    })
    reg(sidebar, "BackgroundColor3", "Sidebar")
    local sideLine = new("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.SidebarLine,
        BorderSizePixel = 0,
        ZIndex = 12,
        Parent = sidebar,
    })
    reg(sideLine, "BackgroundColor3", "SidebarLine")

    local sideScroll = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -8),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Scrollbar,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 11,
        Parent = sidebar,
    })
    list(sideScroll, Enum.FillDirection.Vertical, 3)
    padding(sideScroll, 0, 8, 8, 8)

    local content = new("Frame", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 11,
        Parent = body,
    })
    padding(content, 8, 8, 8, 8)

    -- resize grip (Normal only)
    if not Mode.Lite then
        local grip = new("TextButton", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -16, 1, -16),
            BackgroundTransparency = 1,
            Text = "\u{25E2}",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Theme.DimText,
            AutoButtonColor = false,
            ZIndex = 13,
            Parent = main,
        })
        reg(grip, "TextColor3", "DimText")
        UI:OnUnload(makeResizable(main, grip))
    end

    UI:OnUnload(makeDraggable(main, titleBar))
    local saveConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Settings.SaveWindow then UI:_saveWindow() end
        end
    end)
    UI:OnUnload(function() saveConn:Disconnect() end)

    self.Frame = main
    self.TitleBar = titleBar
    self.Sidebar = sideScroll
    self.Content = content
    self.SearchBox = searchBox

    -- tab creation
    function self:Tab(a, b)
        local name, ico
        if type(a) == "table" then name, ico = a.Name, a.Icon else name, ico = a, b end
        name = name or "Tab"

        local tab = setmetatable({
            Window = self,
            Name = name,
            Icon = ico,
            Sections = {},
        }, Tab)

        local tabContent = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 11,
            Parent = content,
        })
        tabContent.ClipsDescendants = true
        local left, right = makeColumns(tabContent)
        tab.Content = tabContent
        tab.LeftCol = left
        tab.RightCol = right

        -- sidebar button
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Theme.TabHover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 11,
            Parent = sideScroll,
        })
        corner(btn, Theme.RoundSmall)
        local bar = new("Frame", {
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 12,
            Parent = btn,
        })
        corner(bar, 2)
        reg(bar, "BackgroundColor3", "Accent")

        local tx = 10
        local ico = resolveIcon(ico)
        if ico then
            if ico.kind == "image" then
                new("ImageLabel", {
                    Size = UDim2.new(0, 15, 0, 15),
                    Position = UDim2.new(0, 10, 0.5, -7.5),
                    BackgroundTransparency = 1,
                    Image = ico.value,
                    ZIndex = 12,
                    Parent = btn,
                })
            else
                textLabel(btn, {
                    Size = UDim2.new(0, 16, 1, 0),
                    Position = UDim2.new(0, 9, 0, 0),
                    Text = ico.value,
                    TextSize = 13,
                    ZIndex = 12,
                })
            end
            tx = 30
        end
        local nameLbl = textLabel(btn, {
            Size = UDim2.new(1, -tx - 8, 1, 0),
            Position = UDim2.new(0, tx, 0, 0),
            Text = name,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 12,
        })
        reg(nameLbl, "TextColor3", "TabText")

        btn.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab then tween(btn, { BackgroundTransparency = 0.75 }, 0.1) end
        end)
        btn.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab then tween(btn, { BackgroundTransparency = 1 }, 0.1) end
        end)
        btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

        tab.Button = btn
        tab.Bar = bar
        tab.Label = nameLbl
        self.Tabs[#self.Tabs + 1] = tab
        self.TabButtons[tab] = btn

        if #self.Tabs == 1 then
            self:SelectTab(tab)
        end
        return tab
    end

    function self:SelectTab(tab)
        if type(tab) == "string" then
            for _, t in ipairs(self.Tabs) do
                if t.Name == tab then tab = t break end
            end
        end
        if not tab then return end
        for _, t in ipairs(self.Tabs) do
            local active = (t == tab)
            t.Content.Visible = active
            t.Bar.Visible = active
            t.Button.BackgroundTransparency = active and 0.8 or 1
            t.Label.TextColor3 = active and Theme.TabActive or Theme.TabText
        end
        self.ActiveTab = tab
        self.ActiveTab.LeftCol.CanvasPosition = Vector2.new()
        self.ActiveTab.RightCol.CanvasPosition = Vector2.new()
        return tab
    end

    function self:Minimize()
        self.Minimized = not self.Minimized
        if self.Minimized then
            self._restoreH = main.AbsoluteSize.Y
            body.Visible = false
            main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, 34)
        else
            body.Visible = true
            main.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, self._restoreH or defH)
        end
        return self
    end

    function self:SetTitle(t)
        self.Title = tostring(t)
        titleLbl.Text = self.Title
        return self
    end

    function self:Close()
        UI:Unload()
    end

    self._restoreH = main.AbsoluteSize.Y
    UI.Window_ = self

    -- toggle keybind
    local toggleConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or Typing then return end
        if input.KeyCode == Settings.Keybind and input.KeyCode ~= Enum.KeyCode.Unknown then
            self.Hidden = not self.Hidden
            main.Visible = not self.Hidden
        end
    end)
    UI:OnUnload(function() toggleConn:Disconnect() end)

    -- search wiring
    if searchBox then
        local results = new("ScrollingFrame", {
            Name = "SearchResults",
            Size = UDim2.new(0, 260, 0, 0),
            BackgroundColor3 = Theme.Window,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Scrollbar,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 40,
            Parent = gui,
        })
        corner(results, Theme.RoundSmall)
        reg(results, "BackgroundColor3", "Window")
        stroke(results, Theme.ElementLine, 1, 0.3)
        padding(results, 4, 4, 4, 4)
        list(results, Enum.FillDirection.Vertical, 2)

        local function hideResults()
            results.Visible = false
            results.Size = UDim2.new(0, 260, 0, 0)
        end

        local function runSearch(query)
            for _, c in ipairs(results:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            query = string.lower(query)
            if query == "" then hideResults() return end
            local shown = 0
            for _, entry in ipairs(UI._search) do
                if string.find(string.lower(entry.text), query, 1, true) then
                    shown = shown + 1
                    if shown > 8 then break end
                    local row = new("TextButton", {
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = Theme.Text,
                        Text = entry.text .. "  (" .. entry.tab.Name .. ")",
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        AutoButtonColor = false,
                        ZIndex = 41,
                        Parent = results,
                    })
                    padding(row, 0, 6, 0, 6)
                    row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0.7 }, 0.1) end)
                    row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }, 0.1) end)
                    row.MouseButton1Click:Connect(function()
                        self:SelectTab(entry.tab)
                        if entry.control and entry.control.Instance then
                            local inst = entry.control.Instance
                            local col = entry.section.Side == "Right" and entry.tab.RightCol or entry.tab.LeftCol
                            col.CanvasPosition = Vector2.new(0, math.max(0, inst.AbsolutePosition.Y - col.AbsolutePosition.Y + col.CanvasPosition.Y - 40))
                        end
                        hideResults()
                        searchBox.Text = ""
                    end)
                end
            end
            if shown == 0 then
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.DimText,
                    Text = "No results",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 41,
                    Parent = results,
                })
                shown = 1
            end
            results.Size = UDim2.new(0, 260, 0, math.min(shown * 26 + 8, 180))
            results.Visible = true
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function() runSearch(searchBox.Text) end)
        searchBox.Focused:Connect(function()
            Typing = true
            local pos = searchBox.AbsolutePosition
            results.Position = UDim2.fromOffset(pos.X - 130, pos.Y + 26)
        end)
        searchBox.FocusLost:Connect(function()
            Typing = false
            task.delay(0.15, hideResults)
        end)
    end

    if Mode.Lite then
        UI:Notify("ChillHub loaded in Lite mode", "info", 4)
    end
    return self
end

--=====================================================================
--  CONFIG MANAGER  (built in - no SaveManager addon needed)
--=====================================================================
local function configFolder() return Settings.Folder .. "/configs" end
local function configPath(name) return configFolder() .. "/" .. name .. ".json" end

local function encodeValue(v)
    local t = typeof(v)
    if t == "Color3" then return { __t = "Color3", r = v.R, g = v.G, b = v.B } end
    if t == "EnumItem" then return { __t = "Key", name = v.Name } end
    if t == "Vector2" then return { __t = "Vector2", x = v.X, y = v.Y } end
    if type(v) == "table" then
        local arr = {}
        for i, x in ipairs(v) do arr[i] = encodeValue(x) end
        return arr
    end
    return v
end

local function decodeValue(v)
    if type(v) == "table" then
        if v.__t == "Color3" then return Color3.new(v.r, v.g, v.b) end
        if v.__t == "Key" then return Enum.KeyCode[v.name] end
        if v.__t == "Vector2" then return Vector2.new(v.x, v.y) end
        local arr = {}
        for i, x in ipairs(v) do arr[i] = decodeValue(x) end
        return arr
    end
    return v
end

local SKIP_KINDS = { Button = true, Label = true, Paragraph = true, Divider = true }

function UI.Config:Save(name)
    name = name or self.Current or "default"
    local data = {}
    for flag, ctrl in pairs(UI._controls) do
        if ctrl.Value ~= nil and not SKIP_KINDS[ctrl.Kind] then
            data[flag] = encodeValue(ctrl.Value)
        end
    end
    fsMakeFolder(Settings.Folder)
    fsMakeFolder(configFolder())
    if not fsWrite(configPath(name), HttpService:JSONEncode(data)) then
        UI:Notify("Your executor can't write files", "error", 5)
        return false
    end
    self.Current = name
    UI:Notify("Config saved: " .. name, "success", 3)
    return true
end

function UI.Config:Load(name)
    name = name or self.Current
    if not name then UI:Notify("No config selected", "warn", 3) return false end
    local raw = fsRead(configPath(name))
    if not raw then UI:Notify("Config not found: " .. tostring(name), "error", 4) return false end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok or type(data) ~= "table" then
        UI:Notify("Config is corrupt", "error", 4)
        return false
    end
    local count = 0
    for flag, raw2 in pairs(data) do
        local ctrl = UI._controls[flag]
        if ctrl then
            ctrl:SetValue(decodeValue(raw2), true)
            count = count + 1
        end
    end
    self.Current = name
    UI:Notify("Loaded config: " .. name, "success", 3)
    return true
end

function UI.Config:Delete(name)
    name = name or self.Current
    if not name then return false end
    fsDelete(configPath(name))
    UI:Notify("Deleted config: " .. name, "info", 3)
    return true
end

function UI.Config:List()
    local out = {}
    for _, path in ipairs(fsList(configFolder())) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end

function UI.Config:Autoload(name)
    self.AutoloadName = name
    Settings.Config = name
    if name then return self:Load(name) end
    return false
end

function UI.Config:Build(tab, opts)
    opts = opts or {}
    local box = tab:Section({ Name = opts.Name or "Configs", Side = opts.Side or "Right" })
    box:Label("Save and load your settings")
    local nameInput = box:Input("Config Name", { Default = self.Current or "default", Placeholder = "my config" })
    local dd = box:Dropdown("Saved Configs", { Options = self:List() })

    local function refresh()
        local l = self:List()
        if #l == 0 then l = { "(none)" } end
        dd:SetValues(l)
    end
    refresh()

    box:Button("Save Config", function()
        local n = tostring(nameInput.Value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if n == "" then UI:Notify("Enter a config name first", "warn", 3) return end
        if self:Save(n) then refresh() end
    end)
    box:Button("Load Config", function()
        local n = dd.Value
        if n and n ~= "(none)" then self:Load(n) end
    end)
    box:Button("Delete Config", function()
        local n = dd.Value
        if n and n ~= "(none)" then self:Delete(n) refresh() end
    end)
    box:Button("Refresh List", refresh)

    local auto = box:Toggle("Autoload on join", { Default = Settings.Config ~= nil })
    auto:OnChanged(function(v)
        Settings.Config = v and (dd.Value ~= "(none)" and dd.Value or self.Current) or nil
        self.AutoloadName = Settings.Config
        saveSettings()
    end)
    self._refresh = refresh
    return box
end

--=====================================================================
--  DIALOGS
--=====================================================================
function UI:Confirm(title, text, onYes, onNo)
    local gui = ensureGui()
    local overlay = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 90,
        Parent = gui,
    })
    local card = new("Frame", {
        Size = UDim2.new(0, 320, 0, 150),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        ZIndex = 91,
        Parent = overlay,
    })
    corner(card, Theme.Round)
    reg(card, "BackgroundColor3", "Window")
    stroke(card, Theme.WindowBorder, 1, 0.2)

    local t = textLabel(card, {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 14, 0, 12),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Text = tostring(title or "Are you sure?"),
        ZIndex = 92,
    })
    reg(t, "TextColor3", "Text")
    local d = textLabel(card, {
        Size = UDim2.new(1, -28, 0, 56),
        Position = UDim2.new(0, 14, 0, 38),
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(text or ""),
        ZIndex = 92,
    })
    reg(d, "TextColor3", "SubText")

    local function close()
        overlay:Destroy()
    end

    local yes = new("TextButton", {
        Size = UDim2.new(0, 130, 0, 30),
        Position = UDim2.new(0, 14, 1, -44),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.AccentText,
        Text = "Yes",
        AutoButtonColor = false,
        ZIndex = 92,
        Parent = card,
    })
    corner(yes, Theme.RoundSmall)
    reg(yes, "BackgroundColor3", "Accent")
    reg(yes, "TextColor3", "AccentText")

    local no = new("TextButton", {
        Size = UDim2.new(0, 130, 0, 30),
        Position = UDim2.new(1, -144, 1, -44),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        Text = "No",
        AutoButtonColor = false,
        ZIndex = 92,
        Parent = card,
    })
    corner(no, Theme.RoundSmall)
    reg(no, "BackgroundColor3", "Element")
    reg(no, "TextColor3", "Text")

    yes.MouseButton1Click:Connect(function() close() if onYes then pcall(onYes) end end)
    no.MouseButton1Click:Connect(function() close() if onNo then pcall(onNo) end end)
    return { Close = close, Instance = overlay }
end

function UI:Prompt(title, placeholder, default, callback)
    local gui = ensureGui()
    local overlay = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 90,
        Parent = gui,
    })
    local card = new("Frame", {
        Size = UDim2.new(0, 320, 0, 120),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        ZIndex = 91,
        Parent = overlay,
    })
    corner(card, Theme.Round)
    reg(card, "BackgroundColor3", "Window")
    stroke(card, Theme.WindowBorder, 1, 0.2)

    local t = textLabel(card, {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 12),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Text = tostring(title or "Input"),
        ZIndex = 92,
    })
    reg(t, "TextColor3", "Text")

    local box = new("TextBox", {
        Size = UDim2.new(1, -28, 0, 28),
        Position = UDim2.new(0, 14, 0, 40),
        BackgroundColor3 = Theme.Input,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.DimText,
        PlaceholderText = tostring(placeholder or ""),
        Text = tostring(default or ""),
        ClearTextOnFocus = false,
        ZIndex = 92,
        Parent = card,
    })
    corner(box, Theme.RoundSmall)
    reg(box, "BackgroundColor3", "Input")
    stroke(box, Theme.ElementLine, 1, 0.3)
    padding(box, 0, 8, 0, 8)

    local ok = new("TextButton", {
        Size = UDim2.new(0, 130, 0, 28),
        Position = UDim2.new(1, -144, 1, -40),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.AccentText,
        Text = "OK",
        AutoButtonColor = false,
        ZIndex = 92,
        Parent = card,
    })
    corner(ok, Theme.RoundSmall)
    reg(ok, "BackgroundColor3", "Accent")
    reg(ok, "TextColor3", "AccentText")

    box.Focused:Connect(function() Typing = true end)
    local function submit()
        local v = box.Text
        overlay:Destroy()
        if callback then pcall(callback, v) end
    end
    box.FocusLost:Connect(function(enter)
        Typing = false
        if enter then submit() end
    end)
    ok.MouseButton1Click:Connect(function() Typing = false submit() end)
    return { Close = function() overlay:Destroy() end, Instance = overlay }
end

--=====================================================================
--  PUBLIC API
--=====================================================================
function UI.Setup(cfg)
    cfg = cfg or {}
    for k, v in pairs(cfg) do Settings[k] = v end
    if not UI._settingsLoaded then
        loadSettings()
        UI._settingsLoaded = true
    end
    if cfg.Theme then Settings.Theme = cfg.Theme end
    if cfg.Accent then Settings.Accent = cfg.Accent end
    setTheme(Settings.Theme)
    setAccent(Settings.Accent)
    return UI
end

function UI:Get(flag) return UI.Flags[flag] end
function UI:GetControl(flag) return UI._controls[flag] end
function UI:Set(flag, value)
    local c = UI._controls[flag]
    if c then c:SetValue(value) else UI.Flags[flag] = value end
    return UI
end
function UI:Toggle(flag)
    local c = UI._controls[flag]
    if c and c.Kind == "Toggle" then c:SetValue(not c.Value) end
    return UI
end
function UI:SelectTab(name) if UI.Window_ then UI.Window_:SelectTab(name) end end
function UI:SetTheme(name) return setTheme(name) end
function UI:SetAccent(color) setAccent(color) return UI end
function UI:ThemeList()
    local out = {}
    for k in pairs(Themes) do out[#out + 1] = k end
    table.sort(out)
    return out
end
function UI:IsLite() return Mode.Lite end
function UI:OnUnload(fn)
    UI._unloads[#UI._unloads + 1] = fn
    return UI
end
function UI:Unload()
    if UI._unloaded then return end
    UI._unloaded = true
    for i = #UI._unloads, 1, -1 do pcall(UI._unloads[i]) end
    table.clear(UI._unloads)
    for _, c in ipairs(ServiceConns) do pcall(function() c:Disconnect() end) end
    table.clear(ServiceConns)
    table.clear(keybindList)
    listeningCtrl = nil
    dragActive = nil
    table.clear(UI.Flags)
    table.clear(UI._controls)
    table.clear(UI._search)
    table.clear(UI._tabs)
    if Gui then pcall(function() Gui:Destroy() end) end
    Gui = nil
    UI.Gui = nil
    UI.Window_ = nil
    if ENV.ChillHubUI_Unload then ENV.ChillHubUI_Unload = nil end
end

ENV.ChillHubUI = UI
ENV.ChillHubUI_Unload = function() pcall(function() UI:Unload() end) end

return UI
