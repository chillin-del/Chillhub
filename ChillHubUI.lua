--[[
	ChillUI v1.0.0
	A lightweight, beautiful Roblox UI library
	Crimson-brown default theme, startup mode selection,
	custom backdrops, font picker, and smooth animations.

	Usage:
		local ChillUI = loadstring(game:HttpGet("YOUR_RAW_URL/ChillUI.lua"))()
		ChillUI:Init({
			Title = "My Script",
			Version = "1.0",
		})
]]

local ChillUI = {}
ChillUI.__index = ChillUI

-- ─────────────────────────────────────────────
--  Services
-- ─────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService    = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
--  Utility helpers
-- ─────────────────────────────────────────────
local function tween(obj, props, t, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir   = dir   or Enum.EasingDirection.Out
	return TweenService:Create(obj, TweenInfo.new(t or 0.2, style, dir), props)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function springTween(obj, prop, target, speed, dampening)
	-- Simple spring approximation using heartbeat
	speed     = speed     or 20
	dampening = dampening or 0.85
	local vel = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local cur = obj[prop]
		local force = (target - cur) * speed
		vel = vel * dampening + force * dt
		local next = cur + vel * dt
		if math.abs(target - next) < 0.001 and math.abs(vel) < 0.001 then
			obj[prop] = target
			conn:Disconnect()
		else
			obj[prop] = next
		end
	end)
	return conn
end

-- ─────────────────────────────────────────────
--  Theme System
-- ─────────────────────────────────────────────
ChillUI.Themes = {
	["Crimson Brown"] = {
		Primary     = Color3.fromRGB(42,  15,  15),
		Secondary   = Color3.fromRGB(61,  21,  21),
		Accent      = Color3.fromRGB(197, 71,  71),
		AccentLight = Color3.fromRGB(232, 146, 106),
		Text        = Color3.fromRGB(240, 220, 210),
		TextDim     = Color3.fromRGB(160, 120, 110),
		Border      = Color3.fromRGB(90,  35,  35),
		Success     = Color3.fromRGB(80,  185, 110),
		Warning     = Color3.fromRGB(220, 160, 50),
		Error       = Color3.fromRGB(220, 70,  70),
		Shadow      = Color3.fromRGB(10,  3,   3),
	},
	["Midnight Blue"] = {
		Primary     = Color3.fromRGB(10,  15,  35),
		Secondary   = Color3.fromRGB(18,  25,  55),
		Accent      = Color3.fromRGB(80,  120, 240),
		AccentLight = Color3.fromRGB(130, 170, 255),
		Text        = Color3.fromRGB(210, 220, 250),
		TextDim     = Color3.fromRGB(120, 135, 180),
		Border      = Color3.fromRGB(40,  55,  110),
		Success     = Color3.fromRGB(80,  210, 130),
		Warning     = Color3.fromRGB(220, 180, 60),
		Error       = Color3.fromRGB(220, 80,  80),
		Shadow      = Color3.fromRGB(3,   5,   15),
	},
	["Forest Green"] = {
		Primary     = Color3.fromRGB(10,  28,  18),
		Secondary   = Color3.fromRGB(18,  45,  28),
		Accent      = Color3.fromRGB(50,  185, 100),
		AccentLight = Color3.fromRGB(100, 220, 150),
		Text        = Color3.fromRGB(200, 240, 215),
		TextDim     = Color3.fromRGB(110, 160, 130),
		Border      = Color3.fromRGB(35,  90,  55),
		Success     = Color3.fromRGB(80,  210, 130),
		Warning     = Color3.fromRGB(210, 175, 50),
		Error       = Color3.fromRGB(220, 70,  70),
		Shadow      = Color3.fromRGB(3,   10,  6),
	},
	["Rose Gold"] = {
		Primary     = Color3.fromRGB(38,  22,  28),
		Secondary   = Color3.fromRGB(60,  35,  42),
		Accent      = Color3.fromRGB(210, 130, 150),
		AccentLight = Color3.fromRGB(240, 175, 190),
		Text        = Color3.fromRGB(245, 225, 230),
		TextDim     = Color3.fromRGB(165, 130, 140),
		Border      = Color3.fromRGB(100, 60,  75),
		Success     = Color3.fromRGB(80,  205, 120),
		Warning     = Color3.fromRGB(220, 170, 55),
		Error       = Color3.fromRGB(220, 70,  70),
		Shadow      = Color3.fromRGB(12,  6,   8),
	},
	["Obsidian"] = {
		Primary     = Color3.fromRGB(14,  14,  18),
		Secondary   = Color3.fromRGB(22,  22,  28),
		Accent      = Color3.fromRGB(140, 100, 240),
		AccentLight = Color3.fromRGB(185, 155, 255),
		Text        = Color3.fromRGB(225, 220, 240),
		TextDim     = Color3.fromRGB(135, 130, 160),
		Border      = Color3.fromRGB(55,  50,  80),
		Success     = Color3.fromRGB(80,  210, 140),
		Warning     = Color3.fromRGB(220, 175, 55),
		Error       = Color3.fromRGB(220, 75,  75),
		Shadow      = Color3.fromRGB(4,   4,   6),
	},
	["Arctic White"] = {
		Primary     = Color3.fromRGB(240, 243, 250),
		Secondary   = Color3.fromRGB(225, 230, 242),
		Accent      = Color3.fromRGB(60,  110, 220),
		AccentLight = Color3.fromRGB(100, 150, 240),
		Text        = Color3.fromRGB(30,  35,  60),
		TextDim     = Color3.fromRGB(100, 110, 150),
		Border      = Color3.fromRGB(190, 200, 225),
		Success     = Color3.fromRGB(50,  185, 110),
		Warning     = Color3.fromRGB(200, 150, 40),
		Error       = Color3.fromRGB(210, 60,  60),
		Shadow      = Color3.fromRGB(160, 170, 200),
	},
}

ChillUI.Fonts = {
	["Gotham"]       = Enum.Font.Gotham,
	["GothamBold"]   = Enum.Font.GothamBold,
	["GothamBlack"]  = Enum.Font.GothamBlack,
	["Montserrat"]   = Enum.Font.Gotham,       -- closest available
	["Code"]         = Enum.Font.Code,
	["Roboto"]       = Enum.Font.Ubuntu,
	["SourceSans"]   = Enum.Font.SourceSans,
	["Nunito"]       = Enum.Font.Nunito,
}

ChillUI.Backdrops = {
	"Solid",
	"Acrylic",
	"Mica",
	"Semi-Transparent",
	"Glassmorphism",
	"Gradient",
	"Neon Glow",
	"Carbon Fiber",
	"Custom Image",
}

ChillUI.StartupSounds = {
	["None"]        = nil,
	["Chime"]       = "rbxassetid://6895079079",
	["Soft Click"]  = "rbxassetid://6042053214",
	["Whoosh"]      = "rbxassetid://5862022429",
	["Crystal"]     = "rbxassetid://5107125922",
}

-- ─────────────────────────────────────────────
--  State
-- ─────────────────────────────────────────────
ChillUI.Options  = {}
ChillUI.Toggles  = {}
ChillUI._tabs    = {}
ChillUI._windows = {}
ChillUI._unloadCallbacks = {}

ChillUI.CurrentTheme   = "Crimson Brown"
ChillUI.CurrentFont    = "Gotham"
ChillUI.CurrentBackdrop = "Acrylic"
ChillUI.LiteMode       = false
ChillUI.Unloaded       = false

-- ─────────────────────────────────────────────
--  Root ScreenGui
-- ─────────────────────────────────────────────
local function makeGui(name, resetOnSpawn)
	local sg = Instance.new("ScreenGui")
	sg.Name             = name
	sg.ResetOnSpawnEnabled = resetOnSpawn or false
	sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder     = 999
	sg.IgnoreGuiInset   = true
	sg.Parent           = (syn and syn.protect_gui and syn.protect_gui(sg)) and sg or PlayerGui
	return sg
end

-- ─────────────────────────────────────────────
--  Low-level builders
-- ─────────────────────────────────────────────
local function frame(parent, size, pos, color, alpha, corner, border)
	local f = Instance.new("Frame")
	f.Size            = size or UDim2.new(1, 0, 1, 0)
	f.Position        = pos  or UDim2.new(0, 0, 0, 0)
	f.BackgroundColor3 = color or Color3.new(0,0,0)
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel = 0
	f.Parent          = parent
	if corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, corner)
		c.Parent = f
	end
	if border then
		local s = Instance.new("UIStroke")
		s.Color       = border.Color or Color3.new(1,1,1)
		s.Transparency = border.Alpha or 0.6
		s.Thickness   = border.Width or 1
		s.Parent      = f
	end
	return f
end

local function label(parent, text, size, color, font, pos, sizeUDim, xa, ya)
	local l = Instance.new("TextLabel")
	l.Text            = text or ""
	l.TextSize        = size or 14
	l.TextColor3      = color or Color3.new(1,1,1)
	l.Font            = font  or Enum.Font.Gotham
	l.BackgroundTransparency = 1
	l.Size            = sizeUDim or UDim2.new(1, 0, 0, size and size + 4 or 20)
	l.Position        = pos   or UDim2.new(0, 0, 0, 0)
	l.TextXAlignment  = xa    or Enum.TextXAlignment.Left
	l.TextYAlignment  = ya    or Enum.TextYAlignment.Center
	l.TextWrapped     = true
	l.Parent          = parent
	return l
end

local function imageFrame(parent, id, size, pos, corner)
	local f = Instance.new("ImageLabel")
	f.Image           = id or ""
	f.Size            = size or UDim2.new(1, 0, 1, 0)
	f.Position        = pos  or UDim2.new(0, 0, 0, 0)
	f.BackgroundTransparency = 1
	f.ScaleType       = Enum.ScaleType.Crop
	f.Parent          = parent
	if corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, corner)
		c.Parent = f
	end
	return f
end

local function button(parent, text, fontSize, textColor, bgColor, corner)
	local b = Instance.new("TextButton")
	b.Text            = text or ""
	b.TextSize        = fontSize or 14
	b.TextColor3      = textColor or Color3.new(1,1,1)
	b.Font            = Enum.Font.GothamBold
	b.BackgroundColor3 = bgColor or Color3.fromRGB(80, 80, 80)
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent          = parent
	if corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, corner)
		c.Parent = b
	end
	return b
end

-- ─────────────────────────────────────────────
--  Backdrop Renderer
-- ─────────────────────────────────────────────
local function applyBackdrop(targetFrame, backdropName, theme, imageId)
	-- Remove any existing backdrop children tagged as backdrop
	for _, v in ipairs(targetFrame:GetChildren()) do
		if v:GetAttribute("IsBackdrop") then v:Destroy() end
	end

	local T = ChillUI.Themes[theme or ChillUI.CurrentTheme]
	local bd = backdropName or ChillUI.CurrentBackdrop

	if bd == "Solid" then
		targetFrame.BackgroundColor3 = T.Primary
		targetFrame.BackgroundTransparency = 0

	elseif bd == "Acrylic" then
		targetFrame.BackgroundColor3 = T.Primary
		targetFrame.BackgroundTransparency = 0.08
		-- blur overlay
		local blur = Instance.new("BlurEffect")
		blur.Size   = 20
		blur.Name   = "ChillBlur"
		blur.Parent = game:GetService("Lighting")
		blur:SetAttribute("IsBackdrop", true)
		-- store for cleanup
		ChillUI._blurEffect = blur

	elseif bd == "Mica" then
		targetFrame.BackgroundColor3 = T.Secondary
		targetFrame.BackgroundTransparency = 0.15
		local noise = Instance.new("ImageLabel")
		noise.Image  = "rbxassetid://5417036015" -- subtle noise texture
		noise.Size   = UDim2.new(1, 0, 1, 0)
		noise.BackgroundTransparency = 1
		noise.ImageTransparency = 0.88
		noise.ImageColor3 = T.Text
		noise.ZIndex = targetFrame.ZIndex - 1
		noise:SetAttribute("IsBackdrop", true)
		noise.Parent = targetFrame

	elseif bd == "Semi-Transparent" then
		targetFrame.BackgroundColor3 = T.Primary
		targetFrame.BackgroundTransparency = 0.35

	elseif bd == "Glassmorphism" then
		targetFrame.BackgroundColor3 = T.Secondary
		targetFrame.BackgroundTransparency = 0.55
		local stroke = Instance.new("UIStroke")
		stroke.Color       = T.AccentLight
		stroke.Transparency = 0.7
		stroke.Thickness   = 1
		stroke:SetAttribute("IsBackdrop", true)
		stroke.Parent = targetFrame

	elseif bd == "Gradient" then
		targetFrame.BackgroundColor3 = T.Primary
		targetFrame.BackgroundTransparency = 0
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, T.Primary),
			ColorSequenceKeypoint.new(1, T.Secondary),
		})
		grad.Rotation = 135
		grad:SetAttribute("IsBackdrop", true)
		grad.Parent = targetFrame

	elseif bd == "Neon Glow" then
		targetFrame.BackgroundColor3 = Color3.fromRGB(5, 2, 10)
		targetFrame.BackgroundTransparency = 0
		local glow = Instance.new("UIStroke")
		glow.Color       = T.Accent
		glow.Transparency = 0.1
		glow.Thickness   = 2
		glow:SetAttribute("IsBackdrop", true)
		glow.Parent = targetFrame

	elseif bd == "Carbon Fiber" then
		targetFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		targetFrame.BackgroundTransparency = 0
		local cf = Instance.new("ImageLabel")
		cf.Image  = "rbxassetid://7547775802"
		cf.Size   = UDim2.new(1, 0, 1, 0)
		cf.BackgroundTransparency = 1
		cf.ImageTransparency = 0.5
		cf.TileSize = UDim2.new(0, 32, 0, 32)
		cf.ScaleType = Enum.ScaleType.Tile
		cf:SetAttribute("IsBackdrop", true)
		cf.Parent = targetFrame

	elseif bd == "Custom Image" and imageId then
		targetFrame.BackgroundColor3 = T.Primary
		targetFrame.BackgroundTransparency = 0
		local img = Instance.new("ImageLabel")
		img.Image  = imageId -- supports rbxassetid:// or any loaded asset
		img.Size   = UDim2.new(1, 0, 1, 0)
		img.BackgroundTransparency = 1
		img.ImageTransparency = 0.3
		img.ScaleType = Enum.ScaleType.Crop
		img:SetAttribute("IsBackdrop", true)
		img.Parent = targetFrame
		-- overlay tint
		local tint = frame(targetFrame, UDim2.new(1,0,1,0), nil, T.Primary, 0.45)
		tint:SetAttribute("IsBackdrop", true)
	end
end

-- ─────────────────────────────────────────────
--  Startup / Mode Selection Screen
-- ─────────────────────────────────────────────
function ChillUI:_ShowStartup(config, callback)
	local sg = makeGui("ChillUI_Startup")

	-- dim background
	local bg = frame(sg, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0), 0.3)

	-- card
	local card = frame(bg,
		UDim2.new(0, 460, 0, 310),
		UDim2.new(0.5, -230, 0.5, -155),
		Color3.fromRGB(28, 10, 10), 0, 16,
		{Color = Color3.fromRGB(120, 45, 45), Alpha = 0.4, Width = 1}
	)

	-- top gradient bar
	local topBar = frame(card, UDim2.new(1,0,0,3), nil, Color3.fromRGB(197,71,71), 0)
	Instance.new("UICorner").CornerRadius = UDim.new(0, 2)
	local topGrad = Instance.new("UIGradient")
	topGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 90, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 80)),
	})
	topGrad.Parent = topBar

	-- logo/title area
	local logoArea = frame(card, UDim2.new(1,0,0,80), UDim2.new(0,0,0,16), Color3.new(0,0,0), 1)

	local titleLbl = label(logoArea, "❄  " .. (config.Title or "ChillUI"), 26,
		Color3.fromRGB(240, 200, 185), Enum.Font.GothamBold,
		UDim2.new(0,0,0,0), UDim2.new(1,0,1,0),
		Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)

	local verLbl = label(card, "v" .. (config.Version or "1.0") .. "  ·  Select Mode",
		12, Color3.fromRGB(150, 100, 90), Enum.Font.Gotham,
		UDim2.new(0,0,0,88), UDim2.new(1,0,0,18),
		Enum.TextXAlignment.Center)

	-- divider
	local div = frame(card, UDim2.new(0, 360, 0, 1), UDim2.new(0.5, -180, 0, 112),
		Color3.fromRGB(100, 40, 40), 0.3)

	-- mode buttons container
	local modeRow = frame(card, UDim2.new(1, -40, 0, 100), UDim2.new(0, 20, 0, 126),
		Color3.new(0,0,0), 1)

	-- Normal Mode button
	local normalBtn = frame(modeRow,
		UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0),
		Color3.fromRGB(50, 18, 18), 0, 12,
		{Color = Color3.fromRGB(197,71,71), Alpha = 0.5, Width = 1})

	local normalIcon = label(normalBtn, "✦", 22,
		Color3.fromRGB(220, 110, 90), Enum.Font.GothamBold,
		UDim2.new(0,0,0,12), UDim2.new(1,0,0,30),
		Enum.TextXAlignment.Center)
	local normalTitle = label(normalBtn, "Normal", 15,
		Color3.fromRGB(235, 200, 190), Enum.Font.GothamBold,
		UDim2.new(0,8,0,44), UDim2.new(1,-16,0,20),
		Enum.TextXAlignment.Center)
	local normalSub = label(normalBtn, "Full features\nThemes · Images · FX", 11,
		Color3.fromRGB(150, 100, 90), Enum.Font.Gotham,
		UDim2.new(0,8,0,64), UDim2.new(1,-16,0,30),
		Enum.TextXAlignment.Center)

	-- Lite Mode button
	local liteBtn = frame(modeRow,
		UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0),
		Color3.fromRGB(30, 25, 25), 0, 12,
		{Color = Color3.fromRGB(90, 70, 70), Alpha = 0.6, Width = 1})

	local liteIcon = label(liteBtn, "⚡", 22,
		Color3.fromRGB(180, 160, 100), Enum.Font.GothamBold,
		UDim2.new(0,0,0,12), UDim2.new(1,0,0,30),
		Enum.TextXAlignment.Center)
	local liteTitle = label(liteBtn, "Lite", 15,
		Color3.fromRGB(210, 195, 185), Enum.Font.GothamBold,
		UDim2.new(0,8,0,44), UDim2.new(1,-16,0,20),
		Enum.TextXAlignment.Center)
	local liteSub = label(liteBtn, "Lightweight\nFaster · Less memory", 11,
		Color3.fromRGB(130, 115, 110), Enum.Font.Gotham,
		UDim2.new(0,8,0,64), UDim2.new(1,-16,0,30),
		Enum.TextXAlignment.Center)

	-- startup sound selector row
	local soundLbl = label(card, "Startup Sound:", 11, Color3.fromRGB(130,100,90), Enum.Font.Gotham,
		UDim2.new(0, 20, 0, 238), UDim2.new(0,100,0,16))

	local selectedSound = "None"
	local soundNames = {}
	for k in pairs(ChillUI.StartupSounds) do table.insert(soundNames, k) end
	table.sort(soundNames)

	local soundIdx = 1
	local soundValLbl = label(card, selectedSound, 11,
		Color3.fromRGB(220,160,120), Enum.Font.GothamBold,
		UDim2.new(0,120,0,238), UDim2.new(0,120,0,16))

	local prevBtn = button(card, "◀", 11, Color3.fromRGB(200,160,130),
		Color3.fromRGB(55,20,20), 4)
	prevBtn.Size = UDim2.new(0,22,0,16)
	prevBtn.Position = UDim2.new(0,110,0,238)

	local nextBtn = button(card, "▶", 11, Color3.fromRGB(200,160,130),
		Color3.fromRGB(55,20,20), 4)
	nextBtn.Size = UDim2.new(0,22,0,16)
	nextBtn.Position = UDim2.new(0,235,0,238)

	local function updateSound()
		selectedSound = soundNames[soundIdx]
		soundValLbl.Text = selectedSound
	end

	prevBtn.MouseButton1Click:Connect(function()
		soundIdx = soundIdx - 1
		if soundIdx < 1 then soundIdx = #soundNames end
		updateSound()
	end)
	nextBtn.MouseButton1Click:Connect(function()
		soundIdx = soundIdx + 1
		if soundIdx > #soundNames then soundIdx = 1 end
		updateSound()
	end)

	-- footer
	local footer = label(card, "Hover a mode to preview · Click to continue", 10,
		Color3.fromRGB(100, 70, 65), Enum.Font.Gotham,
		UDim2.new(0, 0, 1, -22), UDim2.new(1,0,0,16),
		Enum.TextXAlignment.Center)

	-- animate card in
	card.Position = UDim2.new(0.5, -230, 0.5, -175)
	card.BackgroundTransparency = 1
	bg.BackgroundTransparency  = 1

	tween(bg,  {BackgroundTransparency = 0.3}, 0.4):Play()
	tween(card, {
		Position = UDim2.new(0.5, -230, 0.5, -155),
		BackgroundTransparency = 0
	}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

	-- hover effects
	local function hoverOn(f, strokeColor)
		tween(f, {BackgroundColor3 = Color3.fromRGB(70, 25, 25)}, 0.15):Play()
	end
	local function hoverOff(f, orig)
		tween(f, {BackgroundColor3 = orig}, 0.15):Play()
	end

	normalBtn.MouseEnter:Connect(function() hoverOn(normalBtn) end)
	normalBtn.MouseLeave:Connect(function() hoverOff(normalBtn, Color3.fromRGB(50,18,18)) end)
	liteBtn.MouseEnter:Connect(function() hoverOn(liteBtn) end)
	liteBtn.MouseLeave:Connect(function() hoverOff(liteBtn, Color3.fromRGB(30,25,25)) end)

	-- select handlers
	local function selectMode(lite)
		-- play sound
		local sndId = ChillUI.StartupSounds[selectedSound]
		if sndId then
			local snd = Instance.new("Sound")
			snd.SoundId = sndId
			snd.Volume  = 0.5
			snd.Parent  = sg
			snd:Play()
		end

		-- animate out
		tween(card, {
			Position = UDim2.new(0.5, -230, 0.5, -175),
			BackgroundTransparency = 1
		}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
		tween(bg, {BackgroundTransparency = 1}, 0.35):Play()

		task.delay(0.4, function()
			sg:Destroy()
			callback(lite)
		end)
	end

	-- make buttons clickable (using MouseButton1Click on Frame via InputBegan)
	normalBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			selectMode(false)
		end
	end)
	liteBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			selectMode(true)
		end
	end)
end

-- ─────────────────────────────────────────────
--  Draggable Window
-- ─────────────────────────────────────────────
local function makeDraggable(handle, window, minX, minY)
	local dragging  = false
	local dragStart = nil
	local startPos  = nil

	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = inp.Position
			startPos  = window.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = inp.Position - dragStart
			local vp    = workspace.CurrentCamera.ViewportSize
			local absX  = startPos.X.Offset + delta.X
			local absY  = startPos.Y.Offset + delta.Y

			absX = math.clamp(absX, 0, vp.X - window.AbsoluteSize.X)
			absY = math.clamp(absY, 0, vp.Y - window.AbsoluteSize.Y)

			window.Position = UDim2.new(0, absX, 0, absY)
		end
	end)

	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- ─────────────────────────────────────────────
--  Toggle Element
-- ─────────────────────────────────────────────
local function createToggle(parent, idx, opts, library)
	opts = opts or {}
	local T = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local state = opts.Default or false
	library.Toggles[idx] = { Value = state, _callbacks = {} }

	local row = frame(parent, UDim2.new(1,-4,0,30), nil, Color3.new(0,0,0), 1)

	local lbl = label(row, opts.Text or idx, 13, T.Text, font,
		UDim2.new(0,8,0,0), UDim2.new(1,-50,1,0))

	-- toggle track
	local track = frame(row, UDim2.new(0,38,0,20), UDim2.new(1,-44,0.5,-10),
		state and T.Accent or T.Secondary, 0, 10,
		{Color = T.Border, Alpha = 0.4, Width = 1})

	local thumb = frame(track, UDim2.new(0,16,0,16), UDim2.new(0,2,0.5,-8),
		Color3.new(1,1,1), 0, 8)

	local function setState(val, silent)
		state = val
		library.Toggles[idx].Value = val
		tween(track, {BackgroundColor3 = val and T.Accent or T.Secondary}, 0.18):Play()
		tween(thumb, {Position = val
			and UDim2.new(0,20,0.5,-8)
			or  UDim2.new(0,2,0.5,-8)
		}, 0.18, Enum.EasingStyle.Back):Play()
		if not silent then
			if opts.Callback then opts.Callback(val) end
			for _, cb in ipairs(library.Toggles[idx]._callbacks) do cb(val) end
		end
	end

	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			setState(not state)
		end
	end)

	-- set initial thumb pos
	thumb.Position = state and UDim2.new(0,20,0.5,-8) or UDim2.new(0,2,0.5,-8)

	library.Toggles[idx].SetValue  = setState
	library.Toggles[idx].OnChanged = function(self, cb)
		table.insert(self._callbacks, cb)
	end

	return row
end

-- ─────────────────────────────────────────────
--  Slider Element
-- ─────────────────────────────────────────────
local function createSlider(parent, idx, opts, library)
	opts = opts or {}
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local min  = opts.Min or 0
	local max  = opts.Max or 100
	local rnd  = opts.Rounding or 0
	local val  = math.clamp(opts.Default or min, min, max)

	library.Options[idx] = { Value = val, _callbacks = {} }

	local container = frame(parent, UDim2.new(1,-4,0,46), nil, Color3.new(0,0,0), 1)

	label(container, opts.Text or idx, 12, T.TextDim, font,
		UDim2.new(0,8,0,2), UDim2.new(1,-16,0,16))

	local valLbl = label(container, tostring(val), 12, T.AccentLight, Enum.Font.GothamBold,
		UDim2.new(1,-50,0,2), UDim2.new(0,42,0,16),
		Enum.TextXAlignment.Right)

	local track = frame(container, UDim2.new(1,-16,0,6), UDim2.new(0,8,0,28),
		T.Secondary, 0, 3)

	local fill = frame(track, UDim2.new(0,0,1,0), nil, T.Accent, 0, 3)
	local thumb = frame(track, UDim2.new(0,14,0,14), UDim2.new(0,-7,0.5,-7),
		Color3.new(1,1,1), 0, 7)

	local function setVal(v, silent)
		v = math.clamp(math.floor(v * 10^rnd + 0.5) / 10^rnd, min, max)
		val = v
		library.Options[idx].Value = v
		local pct = (v - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -7, 0.5, -7)
		valLbl.Text = tostring(v)
		if not silent then
			if opts.Callback then opts.Callback(v) end
			for _, cb in ipairs(library.Options[idx]._callbacks) do cb(v) end
		end
	end

	-- init
	setVal(val, true)

	local dragging = false
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local abs   = track.AbsolutePosition
			local sz    = track.AbsoluteSize
			local relX  = math.clamp(inp.Position.X - abs.X, 0, sz.X)
			setVal(min + (relX / sz.X) * (max - min))
		end
	end)

	library.Options[idx].SetValue  = setVal
	library.Options[idx].OnChanged = function(self, cb)
		table.insert(self._callbacks, cb)
	end

	return container
end

-- ─────────────────────────────────────────────
--  Dropdown Element
-- ─────────────────────────────────────────────
local function createDropdown(parent, idx, opts, library)
	opts = opts or {}
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local values   = opts.Values or {}
	local selected = type(opts.Default) == "number" and values[opts.Default] or opts.Default or values[1]
	library.Options[idx] = { Value = selected, _callbacks = {} }

	local container = frame(parent, UDim2.new(1,-4,0,30), nil, Color3.new(0,0,0), 1)

	if not opts.Compact then
		label(container, opts.Text or idx, 12, T.TextDim, font,
			UDim2.new(0,8,0,0), UDim2.new(1,-16,1,0))
	end

	local dropBtn = frame(container, UDim2.new(0, 130, 0, 22), UDim2.new(1, -138, 0.5, -11),
		T.Secondary, 0, 6, {Color = T.Border, Alpha = 0.5, Width = 1})

	local selLbl = label(dropBtn, selected or "Select...", 12, T.Text, font,
		UDim2.new(0,6,0,0), UDim2.new(1,-24,1,0))

	local arrow = label(dropBtn, "▾", 11, T.TextDim, Enum.Font.GothamBold,
		UDim2.new(1,-18,0,0), UDim2.new(0,14,1,0),
		Enum.TextXAlignment.Center)

	-- dropdown list (shown below)
	local open = false
	local listFrame

	dropBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		open = not open
		if open then
			listFrame = frame(container, UDim2.new(0,130, 0, math.min(#values, 6)*24+4),
				UDim2.new(1,-138,0,32),
				T.Secondary, 0, 6,
				{Color = T.Border, Alpha = 0.4, Width = 1})
			listFrame.ZIndex = 50
			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 2)
			layout.Parent  = listFrame
			local pad = Instance.new("UIPadding")
			pad.PaddingTop  = UDim.new(0,2)
			pad.PaddingLeft = UDim.new(0,4)
			pad.Parent = listFrame

			for _, v in ipairs(values) do
				local item = button(listFrame, v, 12, v == selected and T.AccentLight or T.Text, Color3.new(0,0,0), 4)
				item.Size = UDim2.new(1,-8,0,20)
				item.BackgroundTransparency = 1
				item.TextXAlignment = Enum.TextXAlignment.Left
				item.Font = font
				item.MouseButton1Click:Connect(function()
					selected = v
					selLbl.Text = v
					library.Options[idx].Value = v
					if opts.Callback then opts.Callback(v) end
					for _, cb in ipairs(library.Options[idx]._callbacks) do cb(v) end
					listFrame:Destroy()
					open = false
				end)
			end
		else
			if listFrame then listFrame:Destroy() end
		end
	end)

	library.Options[idx].SetValue  = function(v)
		selected = v
		selLbl.Text = v
		library.Options[idx].Value = v
	end
	library.Options[idx].OnChanged = function(self, cb)
		table.insert(self._callbacks, cb)
	end

	return container
end

-- ─────────────────────────────────────────────
--  Button Element
-- ─────────────────────────────────────────────
local function createButton(parent, opts, library)
	opts = opts or {}
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local container = frame(parent, UDim2.new(1,-4,0,28), nil, Color3.new(0,0,0), 1)

	local btn = button(container,
		opts.Text or "Button", 13,
		T.Text, T.Secondary, 6)
	btn.Size     = UDim2.new(1,0,1,0)
	btn.Font     = font

	local stroke = Instance.new("UIStroke")
	stroke.Color       = T.Border
	stroke.Transparency = 0.4
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = T.Accent}, 0.15):Play()
		tween(btn, {TextColor3 = Color3.new(1,1,1)}, 0.15):Play()
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = T.Secondary}, 0.15):Play()
		tween(btn, {TextColor3 = T.Text}, 0.15):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, {BackgroundColor3 = T.AccentLight}, 0.08):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, {BackgroundColor3 = T.Accent}, 0.1):Play()
		if opts.Func and not opts.Disabled then opts.Func() end
	end)

	return container
end

-- ─────────────────────────────────────────────
--  Label Element
-- ─────────────────────────────────────────────
local function createElement_Label(parent, text, library)
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham
	local container = frame(parent, UDim2.new(1,-4,0,22), nil, Color3.new(0,0,0), 1)
	label(container, text or "", 12, T.TextDim, font, UDim2.new(0,8,0,0), UDim2.new(1,-16,1,0))
	return container
end

-- ─────────────────────────────────────────────
--  Divider Element
-- ─────────────────────────────────────────────
local function createElement_Divider(parent)
	local T = ChillUI.Themes[ChillUI.CurrentTheme]
	local container = frame(parent, UDim2.new(1,-4,0,10), nil, Color3.new(0,0,0), 1)
	frame(container, UDim2.new(1,-16,0,1), UDim2.new(0,8,0.5,-0), T.Border, 0.5)
	return container
end

-- ─────────────────────────────────────────────
--  Keybind Element
-- ─────────────────────────────────────────────
local function createKeybind(parent, idx, opts, library)
	opts = opts or {}
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local currentKey = opts.Default or "None"
	library.Options[idx] = { Value = currentKey, _callbacks = {}, _clickCallbacks = {} }

	local container = frame(parent, UDim2.new(1,-4,0,30), nil, Color3.new(0,0,0), 1)
	label(container, opts.Text or idx, 12, T.TextDim, font,
		UDim2.new(0,8,0,0), UDim2.new(1,-80,1,0))

	local keyBtn = button(container, "[" .. tostring(currentKey) .. "]",
		11, T.AccentLight, T.Secondary, 5)
	keyBtn.Size     = UDim2.new(0,66,0,22)
	keyBtn.Position = UDim2.new(1,-70,0.5,-11)
	keyBtn.Font     = font

	local listening = false
	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		keyBtn.Text = "[...]"
		tween(keyBtn, {BackgroundColor3 = T.Accent}, 0.15):Play()
		local conn
		conn = UserInputService.InputBegan:Connect(function(inp, gpe)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = inp.KeyCode.Name
			elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
				currentKey = "MB1"
			elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
				currentKey = "MB2"
			end
			library.Options[idx].Value = currentKey
			keyBtn.Text = "[" .. currentKey .. "]"
			tween(keyBtn, {BackgroundColor3 = T.Secondary}, 0.15):Play()
			listening = false
			conn:Disconnect()
		end)
	end)

	-- mode detection
	if opts.Mode == "Toggle" then
		local active = false
		UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe then return end
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton1 and "MB1"
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == currentKey then
				active = not active
				if opts.Callback then opts.Callback(active) end
				for _, cb in ipairs(library.Options[idx]._clickCallbacks) do cb(active) end
			end
		end)
	elseif opts.Mode == "Hold" then
		UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe then return end
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == currentKey then
				if opts.Callback then opts.Callback(true) end
			end
		end)
		UserInputService.InputEnded:Connect(function(inp)
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == currentKey then
				if opts.Callback then opts.Callback(false) end
			end
		end)
	end

	library.Options[idx].SetValue  = function(v) currentKey = v; keyBtn.Text = "[" .. v .. "]" end
	library.Options[idx].OnClick   = function(self, cb) table.insert(self._clickCallbacks, cb) end
	library.Options[idx].OnChanged = function(self, cb) table.insert(self._callbacks, cb) end
	library.Options[idx].GetState  = function() return false end

	return container
end

-- ─────────────────────────────────────────────
--  Groupbox
-- ─────────────────────────────────────────────
local function makeGroupbox(parent, opts, library)
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham
	local name = opts.Name or "Group"

	-- outer container
	local outer = frame(parent, UDim2.new(1,0,0,0), nil, Color3.new(0,0,0), 1)
	outer.AutomaticSize = Enum.AutomaticSize.Y

	-- header bar
	local header = frame(outer, UDim2.new(1,0,0,26), nil, T.Secondary, 0, 8,
		{Color = T.Border, Alpha = 0.45, Width = 1})

	-- accent left strip
	local strip = frame(header, UDim2.new(0,3,1,0), nil, T.Accent, 0)
	Instance.new("UICorner").CornerRadius = UDim.new(0,2); Instance.new("UICorner").Parent = strip

	label(header, name, 13, T.Text, Enum.Font.GothamBold, UDim2.new(0,12,0,0), UDim2.new(1,0,1,0))

	-- collapse button
	local collapsed = opts.Collapsed or false
	local colBtn = label(header, collapsed and "▸" or "▾", 12, T.TextDim,
		Enum.Font.GothamBold,
		UDim2.new(1,-20,0,0), UDim2.new(0,16,1,0),
		Enum.TextXAlignment.Center)

	-- content area
	local content = frame(outer, UDim2.new(1,0,0,0), UDim2.new(0,0,0,26),
		T.Primary, 0.1, 0,
		{Color = T.Border, Alpha = 0.5, Width = 1})
	content.AutomaticSize = Enum.AutomaticSize.Y

	local layout = Instance.new("UIListLayout")
	layout.Padding         = UDim.new(0, 3)
	layout.SortOrder       = Enum.SortOrder.LayoutOrder
	layout.Parent          = content

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft   = UDim.new(0, 2)
	pad.PaddingRight  = UDim.new(0, 2)
	pad.Parent = content

	if collapsed then content.Visible = false end

	-- collapse toggle
	header.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		collapsed = not collapsed
		colBtn.Text     = collapsed and "▸" or "▾"
		content.Visible = not collapsed
	end)

	-- groupbox API
	local gb = { _content = content, _library = library }

	function gb:AddToggle(idx, o)   createToggle(content, idx, o, library); return self end
	function gb:AddCheckbox(idx, o) return self:AddToggle(idx, o) end
	function gb:AddButton(o)        createButton(content, o, library); return self end
	function gb:AddLabel(text)      createElement_Label(content, text, library); return self end
	function gb:AddDivider()        createElement_Divider(content); return self end
	function gb:AddSlider(idx, o)   createSlider(content, idx, o, library); return self end
	function gb:AddDropdown(idx, o) createDropdown(content, idx, o, library); return self end
	function gb:AddInput(idx, o)
		-- simple text input
		local T2   = ChillUI.Themes[ChillUI.CurrentTheme]
		local font2= ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham
		local cont = frame(content, UDim2.new(1,-4,0,30), nil, Color3.new(0,0,0), 1)
		label(cont, o.Text or idx, 12, T2.TextDim, font2, UDim2.new(0,8,0,0), UDim2.new(0,100,1,0))
		local box = Instance.new("TextBox")
		box.Size                  = UDim2.new(1,-115,0,22)
		box.Position              = UDim2.new(0,110,0.5,-11)
		box.BackgroundColor3      = T2.Secondary
		box.TextColor3            = T2.Text
		box.PlaceholderText       = o.Placeholder or ""
		box.PlaceholderColor3     = T2.TextDim
		box.Font                  = font2
		box.TextSize              = 12
		box.Text                  = o.Default or ""
		box.BorderSizePixel       = 0
		box.ClearTextOnFocus      = o.ClearTextOnFocus ~= false
		box.Parent = cont
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,5); corner.Parent = box
		library.Options[idx] = { Value = box.Text, _callbacks = {} }
		box:GetPropertyChangedSignal("Text"):Connect(function()
			library.Options[idx].Value = box.Text
			if o.Callback then o.Callback(box.Text) end
		end)
		return self
	end
	function gb:AddColorPicker(idx, o)
		-- simple color display strip (full HSV picker is heavyweight)
		local T2 = ChillUI.Themes[ChillUI.CurrentTheme]
		local cont = frame(content, UDim2.new(1,-4,0,30), nil, Color3.new(0,0,0), 1)
		label(cont, o.Title or idx, 12, T2.TextDim, Enum.Font.Gotham, UDim2.new(0,8,0,0), UDim2.new(1,-50,1,0))
		local swatch = frame(cont, UDim2.new(0,30,0,20), UDim2.new(1,-38,0.5,-10), o.Default or Color3.new(1,0,0), 0, 5)
		library.Options[idx] = { Value = o.Default or Color3.new(1,0,0), Transparency = o.Transparency or 0 }
		swatch.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				-- cycle through some preset colors
				local presets = {Color3.fromRGB(220,60,60), Color3.fromRGB(60,180,255), Color3.fromRGB(80,220,120), Color3.fromRGB(255,200,50), Color3.fromRGB(180,80,220)}
				local idx2 = 1
				for i,c in ipairs(presets) do if c == library.Options[idx].Value then idx2 = i%#presets+1; break end end
				library.Options[idx].Value = presets[idx2]
				tween(swatch, {BackgroundColor3 = presets[idx2]}, 0.2):Play()
				if o.Callback then o.Callback(presets[idx2]) end
			end
		end)
		return self
	end
	function gb:AddKeyPicker(idx, o) createKeybind(content, idx, o, library); return self end

	return gb
end

-- ─────────────────────────────────────────────
--  Tab System
-- ─────────────────────────────────────────────
local function makeTabSystem(tabBar, tabPages, library)
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local activeTab = nil

	local function switchTo(name)
		for n, page in pairs(tabPages) do
			page.Visible = (n == name)
		end
		activeTab = name
		-- update tab button styles
		for _, btn in ipairs(tabBar:GetChildren()) do
			if btn:IsA("TextButton") then
				local isActive = btn.Name == name
				tween(btn, {
					BackgroundColor3 = isActive and T.Accent or Color3.new(0,0,0),
					BackgroundTransparency = isActive and 0 or 1,
					TextColor3 = isActive and Color3.new(1,1,1) or T.TextDim,
				}, 0.15):Play()
			end
		end
	end

	return switchTo
end

-- ─────────────────────────────────────────────
--  Settings Tab (Theme/Font/Backdrop)
-- ─────────────────────────────────────────────
local function buildSettingsTab(page, window, library)
	local T = ChillUI.Themes[ChillUI.CurrentTheme]

	local gb = makeGroupbox(page, {Name = "Appearance"}, library)

	-- Theme dropdown
	local themeNames = {}
	for k in pairs(ChillUI.Themes) do table.insert(themeNames, k) end
	table.sort(themeNames)

	createDropdown(gb._content, "__theme__", {
		Text     = "Theme",
		Values   = themeNames,
		Default  = ChillUI.CurrentTheme,
		Callback = function(v)
			ChillUI.CurrentTheme = v
			-- apply new theme colors to window (simplified refresh)
			local newT = ChillUI.Themes[v]
			tween(window, {BackgroundColor3 = newT.Primary}, 0.3):Play()
		end,
	}, library)

	-- Font dropdown (not in Lite)
	if not ChillUI.LiteMode then
		local fontNames = {}
		for k in pairs(ChillUI.Fonts) do table.insert(fontNames, k) end
		table.sort(fontNames)

		createDropdown(gb._content, "__font__", {
			Text     = "Font",
			Values   = fontNames,
			Default  = ChillUI.CurrentFont,
			Callback = function(v)
				ChillUI.CurrentFont = v
			end,
		}, library)

		-- Backdrop dropdown
		createDropdown(gb._content, "__backdrop__", {
			Text     = "Backdrop",
			Values   = ChillUI.Backdrops,
			Default  = ChillUI.CurrentBackdrop,
			Callback = function(v)
				ChillUI.CurrentBackdrop = v
				applyBackdrop(window, v, ChillUI.CurrentTheme)
			end,
		}, library)

		-- Custom image input
		createDropdown(gb._content, "__imageType__", {
			Text   = "Bg Image Type",
			Values = {"rbxassetid://", "URL"},
			Default = "rbxassetid://",
		}, library)

		local imgGb = makeGroupbox(page, {Name = "Custom Image Background"}, library)
		imgGb:AddInput("__bgImageId__", {
			Text        = "Image ID / URL",
			Placeholder = "7547775802",
			Callback    = function(v)
				ChillUI.CurrentBackdrop = "Custom Image"
				applyBackdrop(window, "Custom Image", ChillUI.CurrentTheme, "rbxassetid://" .. v)
			end,
		})
	end

	-- Corner radius
	local cornerGb = makeGroupbox(page, {Name = "Window"}, library)
	cornerGb:AddSlider("__cornerRadius__", {
		Text     = "Corner Radius",
		Min      = 0,
		Max      = 20,
		Default  = 12,
		Rounding = 0,
		Callback = function(v)
			local c = window:FindFirstChildOfClass("UICorner")
			if c then c.CornerRadius = UDim.new(0, v) end
		end,
	})
end

-- ─────────────────────────────────────────────
--  Main Init
-- ─────────────────────────────────────────────
function ChillUI:Init(config)
	config = config or {}

	-- Show startup screen first, then build main window
	self:_ShowStartup(config, function(isLite)
		ChillUI.LiteMode = isLite
		self:_Build(config)
	end)

	return self
end

function ChillUI:_Build(config)
	local T    = ChillUI.Themes[ChillUI.CurrentTheme]
	local font = ChillUI.Fonts[ChillUI.CurrentFont] or Enum.Font.Gotham

	local sg = makeGui("ChillUI_Main")
	ChillUI._gui = sg

	local vp = workspace.CurrentCamera.ViewportSize
	local winW = ChillUI.LiteMode and 480 or 600
	local winH = ChillUI.LiteMode and 360 or 450

	-- ── Main window frame ──
	local window = frame(sg,
		UDim2.new(0, winW, 0, winH),
		UDim2.new(0.5, -winW/2, 0.5, -winH/2),
		T.Primary, 0, 12,
		{Color = T.Border, Alpha = 0.35, Width = 1}
	)
	ChillUI._window = window
	applyBackdrop(window, ChillUI.CurrentBackdrop, ChillUI.CurrentTheme)

	-- shadow (fake)
	local shadow = frame(sg, UDim2.new(0, winW+20, 0, winH+20),
		UDim2.new(0.5, -(winW+20)/2, 0.5, -(winH+20)/2),
		T.Shadow, 0.6, 16)
	shadow.ZIndex = window.ZIndex - 1

	-- ── Title bar ──
	local titleBar = frame(window, UDim2.new(1,0,0,36), nil,
		T.Secondary, 0, 0,
		nil)

	-- top-left rounded corners only
	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 12)
	topCorner.Parent = titleBar

	-- accent bar across top
	local accentLine = frame(titleBar, UDim2.new(1,0,0,2), nil, T.Accent, 0)
	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.Accent),
		ColorSequenceKeypoint.new(0.5, T.AccentLight),
		ColorSequenceKeypoint.new(1, T.Accent),
	})
	accentGrad.Parent = accentLine

	-- title + version
	local titleLbl = label(titleBar, (config.Icon and "  " or "") .. (config.Title or "ChillUI"),
		14, T.Text, Enum.Font.GothamBold,
		UDim2.new(0, 12, 0, 0), UDim2.new(1,-120,1,0))

	local verLbl = label(titleBar, "v" .. (config.Version or "1.0"),
		11, T.TextDim, font,
		UDim2.new(0,12,0,0), UDim2.new(1,-120,1,0))
	verLbl.Position = UDim2.new(0, 12 + titleLbl.TextBounds.X + 8, 0, 0)

	-- window controls (close / minimize)
	local function windowControlBtn(parent, pos, color, ico)
		local b = frame(parent, UDim2.new(0,14,0,14), pos, color, 0, 7)
		label(b, ico, 8, Color3.new(1,1,1), Enum.Font.GothamBold,
			UDim2.new(0,0,0,0), UDim2.new(1,0,1,0),
			Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)
		return b
	end

	local closeBtn = windowControlBtn(titleBar,
		UDim2.new(1,-20,0.5,-7), Color3.fromRGB(220,70,70), "✕")
	local minBtn   = windowControlBtn(titleBar,
		UDim2.new(1,-38,0.5,-7), Color3.fromRGB(220,170,50), "−")

	local minimized = false
	local mainContent -- defined below

	closeBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		tween(window, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)}, 0.3,
			Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
		task.delay(0.35, function() window:Destroy(); shadow:Destroy() end)
	end)

	minBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		minimized = not minimized
		if mainContent then
			tween(window, {
				Size = minimized
					and UDim2.new(0, winW, 0, 36)
					or  UDim2.new(0, winW, 0, winH)
			}, 0.25, Enum.EasingStyle.Quad):Play()
		end
	end)

	-- drag titlebar
	makeDraggable(titleBar, window)

	-- ── Tab bar ──
	local tabBarContainer = frame(window, UDim2.new(1,0,0,30),
		UDim2.new(0,0,0,36), T.Primary, 0.6)

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.FillDirection  = Enum.FillDirection.Horizontal
	tabBarLayout.Padding        = UDim.new(0,2)
	tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabBarLayout.Parent         = tabBarContainer

	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft = UDim.new(0,8)
	tabPad.Parent      = tabBarContainer

	-- ── Main content scroll ──
	mainContent = Instance.new("ScrollingFrame")
	mainContent.Size                   = UDim2.new(1,0,1,-68)
	mainContent.Position               = UDim2.new(0,0,0,68)
	mainContent.BackgroundTransparency = 1
	mainContent.BorderSizePixel        = 0
	mainContent.ScrollBarThickness     = 3
	mainContent.ScrollBarImageColor3   = T.Accent
	mainContent.CanvasSize             = UDim2.new(0,0,0,0)
	mainContent.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	mainContent.Parent                 = window

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding    = UDim.new(0,6)
	contentLayout.SortOrder  = Enum.SortOrder.LayoutOrder
	contentLayout.Parent     = mainContent

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingTop    = UDim.new(0,8)
	contentPad.PaddingLeft   = UDim.new(0,8)
	contentPad.PaddingRight  = UDim.new(0,8)
	contentPad.PaddingBottom = UDim.new(0,8)
	contentPad.Parent        = mainContent

	-- ── Tab pages ──
	local tabPages = {}
	local switchTo

	local function addTabBtn(name, icon)
		local btn = Instance.new("TextButton")
		btn.Name                  = name
		btn.Text                  = (icon and icon .. " " or "") .. name
		btn.Font                  = Enum.Font.GothamBold
		btn.TextSize              = 12
		btn.TextColor3            = T.TextDim
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor       = false
		btn.Size                  = UDim2.new(0,0,1,0)
		btn.AutomaticSize         = Enum.AutomaticSize.X

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,6)
		corner.Parent = btn

		local pad2 = Instance.new("UIPadding")
		pad2.PaddingLeft  = UDim.new(0,8)
		pad2.PaddingRight = UDim.new(0,8)
		pad2.Parent = btn

		btn.Parent = tabBarContainer

		-- page frame
		local page = frame(mainContent, UDim2.new(1,0,0,0), nil, Color3.new(0,0,0), 1)
		page.AutomaticSize = Enum.AutomaticSize.Y
		page.Visible       = false

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding   = UDim.new(0,6)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent    = page

		tabPages[name] = page

		btn.MouseButton1Click:Connect(function()
			if switchTo then switchTo(name) end
		end)

		return page
	end

	-- Tab API
	local tabAPI = {}

	function tabAPI:AddTab(name, icon)
		local page = addTabBtn(name, icon)
		local tabObj = { _page = page, _library = ChillUI }

		function tabObj:AddGroupbox(opts2)
			return makeGroupbox(page, opts2, ChillUI)
		end
		function tabObj:AddLeftGroupbox(name2, icon2)
			return makeGroupbox(page, {Name = name2, IconName = icon2, Side = "Left"}, ChillUI)
		end
		function tabObj:AddRightGroupbox(name2, icon2)
			return makeGroupbox(page, {Name = name2, IconName = icon2, Side = "Right"}, ChillUI)
		end
		function tabObj:AddRightTabbox()
			return self:AddGroupbox({Name = "Options"})
		end
		function tabObj:AddKeyTab()
			return self
		end
		function tabObj:AddLabel(opts2)
			return createElement_Label(page, type(opts2) == "string" and opts2 or opts2.Text, ChillUI)
		end
		function tabObj:AddKeyBox(cb)
			local T2 = ChillUI.Themes[ChillUI.CurrentTheme]
			local gb2 = makeGroupbox(page, {Name = "Key System"}, ChillUI)
			gb2:AddInput("__keyinput__", {
				Text = "Enter Key",
				Placeholder = "...",
				Callback = function(v)
					if cb then cb(v) end
				end,
			})
			return gb2
		end

		tabPages[name] = page
		return tabObj
	end

	-- settings tab (always present)
	local settingsPage = addTabBtn("⚙ Settings", nil)
	task.defer(function()
		buildSettingsTab(settingsPage, window, ChillUI)
	end)

	-- ── Tab switcher ──
	switchTo = makeTabSystem(tabBarContainer, tabPages, ChillUI)

	-- ── Menu keybind ──
	local menuKey = Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.KeyCode == menuKey then
			window.Visible = not window.Visible
		end
	end)

	-- ── Notifications ──
	ChillUI._notifGui = makeGui("ChillUI_Notifs")
	local notifStack = frame(ChillUI._notifGui,
		UDim2.new(0,280,1,0), UDim2.new(1,-290,0,0),
		Color3.new(0,0,0), 1)
	local notifLayout = Instance.new("UIListLayout")
	notifLayout.Padding            = UDim.new(0,6)
	notifLayout.VerticalAlignment  = Enum.VerticalAlignment.Bottom
	notifLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	notifLayout.Parent             = notifStack

	ChillUI._notifStack = notifStack

	-- ── API surface ──
	local Window = {}

	function Window:AddTab(name, icon)
		return tabAPI:AddTab(name, icon)
	end

	function Window:AddKeyTab(name)
		return tabAPI:AddTab(name or "Key", "🔑")
	end

	function Window:SetToggleKey(key)
		if Enum.KeyCode[key] then menuKey = Enum.KeyCode[key] end
	end

	ChillUI._win = Window

	-- activate first tab if any added
	task.defer(function()
		local first = next(tabPages)
		if first then switchTo(first) end
	end)

	return Window
end

-- ─────────────────────────────────────────────
--  Notification
-- ─────────────────────────────────────────────
function ChillUI:Notify(opts)
	opts = opts or {}
	local T = ChillUI.Themes[ChillUI.CurrentTheme]
	local stack = ChillUI._notifStack
	if not stack then return end

	local card = frame(stack, UDim2.new(1,0,0,0), nil, T.Secondary, 0, 10,
		{Color = T.Accent, Alpha = 0.4, Width = 1})
	card.AutomaticSize = Enum.AutomaticSize.Y

	local pad2 = Instance.new("UIPadding")
	pad2.PaddingTop    = UDim.new(0,10)
	pad2.PaddingLeft   = UDim.new(0,10)
	pad2.PaddingRight  = UDim.new(0,10)
	pad2.PaddingBottom = UDim.new(0,10)
	pad2.Parent = card

	local cLayout = Instance.new("UIListLayout")
	cLayout.Padding = UDim.new(0,4)
	cLayout.Parent  = card

	if opts.Title then
		label(card, opts.Title, 13, T.Text, Enum.Font.GothamBold,
			nil, UDim2.new(1,0,0,16))
	end
	if opts.Description then
		label(card, opts.Description, 11, T.TextDim, Enum.Font.Gotham,
			nil, UDim2.new(1,0,0,0))
	end

	-- progress bar
	local prog = frame(card, UDim2.new(1,0,0,2), nil, T.Accent, 0, 1)
	local time = opts.Time or 3

	card.BackgroundTransparency = 1
	tween(card, {BackgroundTransparency = 0}, 0.2):Play()
	tween(prog, {Size = UDim2.new(0,0,0,2)}, time, Enum.EasingStyle.Linear):Play()

	task.delay(time, function()
		tween(card, {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0)}, 0.3):Play()
		task.delay(0.35, function() card:Destroy() end)
	end)
end

-- ─────────────────────────────────────────────
--  OnUnload
-- ─────────────────────────────────────────────
function ChillUI:OnUnload(cb)
	table.insert(ChillUI._unloadCallbacks, cb)
end

function ChillUI:Unload()
	ChillUI.Unloaded = true
	if ChillUI._blurEffect then ChillUI._blurEffect:Destroy() end
	if ChillUI._gui     then ChillUI._gui:Destroy()     end
	if ChillUI._notifGui then ChillUI._notifGui:Destroy() end
	for _, cb in ipairs(ChillUI._unloadCallbacks) do cb() end
end

-- ─────────────────────────────────────────────
--  CreateWindow shortcut (Obsidian-style API compat)
-- ─────────────────────────────────────────────
function ChillUI:CreateWindow(opts)
	opts = opts or {}
	-- defer to Init if not already done
	if not ChillUI._win then
		self:Init(opts)
		return ChillUI._win or {}
	end
	return ChillUI._win
end

return ChillUI
