--[[
    Chillui 1.0.0
    A lightweight, modern Roblox UI library.
    Default theme: Crimson Brown
    By deivid (example) / cleaned up + rebuilt as Chillui

    Quick start:
        local Chillui = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOU/Chillui/main/Chillui.lua"))()
        local Window = Chillui:CreateWindow({ Title = "My Script", Footer = "v1.0" })
        local Tab = Window:AddTab("Main", "home")
        Tab:AddLeftGroupbox("General"):AddToggle("Example", { Text = "Example toggle", Default = true })
        Chillui:BuildSettings(Window:AddTab("UI Settings", "settings"))

    Everything is optional. Chillui works fine with zero config.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

if not game:IsLoaded() then game.Loaded:Wait() end
if not Players.LocalPlayer then
	local waited = 0
	while not Players.LocalPlayer and waited < 15 do
		task.wait(0.1)
		waited += 0.1
	end
end
local LocalPlayer = Players.LocalPlayer

local Library
local State

local ENV = (typeof(getgenv) == "function" and getgenv()) or _G
local Options = ENV.Options or {}
local Toggles = ENV.Toggles or {}
ENV.Options = Options
ENV.Toggles = Toggles

local LIB_FOLDER = "Chillui"
local SETTINGS_FILE = LIB_FOLDER .. "/settings.json"
local CONFIG_FOLDER = LIB_FOLDER .. "/configs"

--------------------------------------------------------------------------------
-- small utilities
--------------------------------------------------------------------------------

local function Create(class, props, children)
	local obj = Instance.new(class)
	for k, v in next, props or {} do
		if k ~= "Parent" then
			obj[k] = v
		end
	end
	if children then
		for _, child in next, children do
			child.Parent = obj
		end
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function Clone(tbl)
	local out = {}
	for k, v in next, tbl do
		out[k] = v
	end
	return out
end

local function IsLite()
	return Library and Library.Mode == "Lite"
end

local function Animate(inst, props, time, style, dir)
	if IsLite() or not Library.Config.Animations then
		for k, v in next, props do
			inst[k] = v
		end
		return nil
	end
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function Corner(radius, parent)
	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

local function Pad(top, right, bottom, left, parent)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or top or 0),
		PaddingBottom = UDim.new(0, bottom or top or 0),
		PaddingLeft = UDim.new(0, left or right or top or 0),
		Parent = parent,
	})
end

local function GetGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and coreGui then
		local ok3 = pcall(function()
			local probe = Instance.new("Folder")
			probe.Parent = coreGui
			probe:Destroy()
		end)
		if ok3 then
			return coreGui
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function MouseX()
	return UIS:GetMouseLocation().X
end

local function PointInFrame(point, frame)
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function Hex(color)
	return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function FromHex(text)
	text = tostring(text):gsub("#", "")
	if #text == 3 then
		text = text:sub(1, 1):rep(2) .. text:sub(2, 2):rep(2) .. text:sub(3, 3):rep(2)
	end
	if #text ~= 6 or text:match("%X") then
		return nil
	end
	return Color3.fromHex(text)
end

--------------------------------------------------------------------------------
-- fonts
--------------------------------------------------------------------------------

local FONT_NAMES = {
	"Gotham", "GothamMedium", "GothamBold", "GothamBlack",
	"BuilderSans", "BuilderSansMedium", "BuilderSansBold",
	"Montserrat", "MontserratMedium", "MontserratBold",
	"Roboto", "RobotoCondensed", "RobotoMono",
	"SourceSans", "SourceSansLight", "SourceSansSemibold", "SourceSansBold",
	"Nunito", "Oswald", "Arial", "ArialBold", "Ubuntu", "Merriweather",
	"TitilliumWeb", "Sarpanch", "Michroma", "Jura", "Code", "Cartoon",
	"SciFi", "Fantasy", "Arcade", "Highway", "Bangers", "Creepster",
	"PermanentMarker", "PatrickHand", "LuckiestGuy", "SpecialElite",
	"Garamond", "Legacy", "Antique", "Bodoni", "AmaticSC", "DenkOne",
	"Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower",
	"JosefinSans", "Kalam",
}

local FONTS = {}
local FONT_LIST = {}
for _, name in ipairs(FONT_NAMES) do
	local ok, enum = pcall(function()
		return Enum.Font[name]
	end)
	if ok and enum then
		local label = name:gsub("(%l)(%u)", "%1 %2")
		FONTS[label] = enum
		table.insert(FONT_LIST, label)
	end
end
if not FONTS["Gotham"] then
	FONTS["Gotham"] = Enum.Font.SourceSans
	table.insert(FONT_LIST, 1, "Gotham")
end

--------------------------------------------------------------------------------
-- themes
--------------------------------------------------------------------------------

local function T(name, window, panel, element, hover, stroke, text, subtext, accent, accent2, onAccent)
	return {
		Name = name,
		Window = window,
		Panel = panel,
		Element = element,
		ElementHover = hover,
		Stroke = stroke,
		Text = text,
		SubText = subtext,
		Accent = accent,
		Accent2 = accent2,
		OnAccent = onAccent or Color3.fromRGB(255, 250, 248),
	}
end

local THEMES = {
	T("Crimson Brown",
		Color3.fromRGB(30, 20, 19), Color3.fromRGB(41, 28, 26), Color3.fromRGB(52, 36, 33),
		Color3.fromRGB(66, 46, 42), Color3.fromRGB(86, 59, 54), Color3.fromRGB(246, 235, 231),
		Color3.fromRGB(183, 155, 148), Color3.fromRGB(201, 81, 73), Color3.fromRGB(145, 48, 44)),
	T("Midnight",
		Color3.fromRGB(15, 18, 26), Color3.fromRGB(22, 26, 37), Color3.fromRGB(30, 35, 49),
		Color3.fromRGB(39, 45, 62), Color3.fromRGB(52, 60, 82), Color3.fromRGB(236, 240, 250),
		Color3.fromRGB(146, 158, 184), Color3.fromRGB(96, 132, 255), Color3.fromRGB(60, 90, 200)),
	T("Ocean",
		Color3.fromRGB(12, 25, 29), Color3.fromRGB(18, 35, 40), Color3.fromRGB(25, 47, 54),
		Color3.fromRGB(33, 60, 68), Color3.fromRGB(44, 78, 88), Color3.fromRGB(230, 247, 248),
		Color3.fromRGB(140, 178, 182), Color3.fromRGB(54, 190, 201), Color3.fromRGB(26, 140, 152)),
	T("Forest",
		Color3.fromRGB(16, 24, 18), Color3.fromRGB(23, 34, 25), Color3.fromRGB(31, 46, 33),
		Color3.fromRGB(40, 60, 42), Color3.fromRGB(54, 79, 56), Color3.fromRGB(235, 247, 236),
		Color3.fromRGB(152, 180, 155), Color3.fromRGB(110, 200, 120), Color3.fromRGB(60, 150, 80)),
	T("Rose",
		Color3.fromRGB(30, 18, 24), Color3.fromRGB(41, 25, 33), Color3.fromRGB(52, 33, 42),
		Color3.fromRGB(64, 42, 53), Color3.fromRGB(84, 57, 70), Color3.fromRGB(252, 236, 242),
		Color3.fromRGB(198, 158, 174), Color3.fromRGB(240, 120, 160), Color3.fromRGB(190, 80, 120)),
	T("Mono",
		Color3.fromRGB(22, 22, 24), Color3.fromRGB(30, 30, 33), Color3.fromRGB(38, 38, 42),
		Color3.fromRGB(48, 48, 53), Color3.fromRGB(64, 64, 70), Color3.fromRGB(240, 240, 242),
		Color3.fromRGB(155, 155, 162), Color3.fromRGB(230, 230, 235), Color3.fromRGB(170, 170, 178),
		Color3.fromRGB(20, 20, 22)),
	T("Sunset",
		Color3.fromRGB(34, 20, 16), Color3.fromRGB(45, 28, 21), Color3.fromRGB(58, 36, 27),
		Color3.fromRGB(72, 46, 34), Color3.fromRGB(92, 60, 45), Color3.fromRGB(255, 240, 230),
		Color3.fromRGB(205, 165, 140), Color3.fromRGB(255, 145, 80), Color3.fromRGB(210, 95, 60)),
	T("Cyber",
		Color3.fromRGB(14, 16, 24), Color3.fromRGB(20, 23, 34), Color3.fromRGB(28, 32, 46),
		Color3.fromRGB(37, 42, 60), Color3.fromRGB(52, 58, 82), Color3.fromRGB(230, 250, 250),
		Color3.fromRGB(130, 165, 175), Color3.fromRGB(0, 240, 200), Color3.fromRGB(0, 170, 200)),
	T("Coffee",
		Color3.fromRGB(28, 22, 18), Color3.fromRGB(38, 30, 24), Color3.fromRGB(49, 39, 31),
		Color3.fromRGB(62, 50, 40), Color3.fromRGB(82, 66, 53), Color3.fromRGB(245, 236, 225),
		Color3.fromRGB(185, 165, 145), Color3.fromRGB(200, 150, 105), Color3.fromRGB(150, 105, 70)),
	T("Lavender",
		Color3.fromRGB(24, 20, 32), Color3.fromRGB(33, 27, 44), Color3.fromRGB(43, 35, 57),
		Color3.fromRGB(55, 45, 72), Color3.fromRGB(74, 60, 95), Color3.fromRGB(243, 236, 255),
		Color3.fromRGB(175, 162, 200), Color3.fromRGB(170, 130, 255), Color3.fromRGB(120, 85, 200)),
}

local THEME_LIST = {}
local THEME_MAP = {}
for _, theme in ipairs(THEMES) do
	THEME_MAP[theme.Name] = theme
	table.insert(THEME_LIST, theme.Name)
end

--------------------------------------------------------------------------------
-- library object
--------------------------------------------------------------------------------

Library = {
	Version = "1.0.0",
	Repo = "https://github.com/YOU/Chillui",
	Unloaded = false,
	Mode = nil,
	ShowCustomCursor = false,
	NotifySide = "Right",
	Themes = THEME_LIST,
	Fonts = FONT_LIST,
	Backdrops = { "Solid", "Semi", "Glass", "Acrylic", "Mica", "Vibrant", "Blur", "Image" },
	Keybinds = {},
	Theme = THEME_MAP["Crimson Brown"],
	ThemeName = "Crimson Brown",
	FontName = "Gotham",
	BackdropName = "Glass",
	CornerRadius = 12,
	Transparency = 0,
	Window = nil,
	KeybindFrame = nil,
	KeybindMenu = nil,
	Config = nil,
	UnloadCallbacks = {},
}
Library.__index = Library
Library.Options = Options
Library.Toggles = Toggles

local SoundPresets = {
	["Warm Rise"] = "rbxasset://sounds/electronicpingshort.wav",
	["Soft Click"] = "rbxasset://sounds/clickfast.wav",
	["Switch"] = "rbxasset://sounds/switch3.wav",
	["None"] = nil,
}
local SOUND_LIST = { "Warm Rise", "Soft Click", "Switch", "None" }

Library.Config = {
	Theme = "Crimson Brown",
	Font = "Gotham",
	Accent = Color3.fromRGB(201, 81, 73),
	Backdrop = "Glass",
	CornerRadius = 12,
	DPI = 100,
	Animations = true,
	Sounds = true,
	StartupSound = "Warm Rise",
	BackgroundImage = "",
	BackgroundImageTransparency = 0.25,
	NotifySide = "Right",
	CustomCursor = false,
	MenuKey = "RightShift",
}

--------------------------------------------------------------------------------
-- skin registry (lets us retheme / refont everything live)
--------------------------------------------------------------------------------

local Skin = {
	windows = {},
	panels = {},
	elements = {},
	strokes = {},
	texts = {},
	subtexts = {},
	accentTexts = {},
	onAccents = {},
	accents = {},
	gradients = {},
	dividers = {},
	fonts = {},
}

local function Track(group, obj)
	table.insert(Skin[group], obj)
	return obj
end

local function MakeText(class, props, group)
	local inst = Create(class, props)
	inst.Font = FONTS[Library.FontName] or Enum.Font.Gotham
	table.insert(Skin.fonts, inst)
	if group then
		Track(group, inst)
	end
	return inst
end

local ApplyBackdrop

local function ApplyTheme()
	local theme = Library.Theme
	for _, o in ipairs(Skin.windows) do
		o.BackgroundColor3 = theme.Window
	end
	for _, o in ipairs(Skin.panels) do
		o.BackgroundColor3 = theme.Panel
	end
	for _, o in ipairs(Skin.elements) do
		o.BackgroundColor3 = theme.Element
	end
	for _, o in ipairs(Skin.strokes) do
		o.Color = theme.Stroke
	end
	for _, o in ipairs(Skin.texts) do
		o.TextColor3 = theme.Text
	end
	for _, o in ipairs(Skin.subtexts) do
		o.TextColor3 = theme.SubText
	end
	for _, o in ipairs(Skin.accentTexts) do
		o.TextColor3 = theme.Accent
	end
	for _, o in ipairs(Skin.onAccents) do
		o.TextColor3 = theme.OnAccent
	end
	for _, o in ipairs(Skin.accents) do
		o.BackgroundColor3 = Library.Config.Accent
	end
	for _, o in ipairs(Skin.dividers) do
		o.BackgroundColor3 = theme.Stroke
	end
	for _, g in ipairs(Skin.gradients) do
		g.Color = ColorSequence.new(Library.Config.Accent, theme.Accent2)
	end
	if State and State.bg and State.bg.glowFrames then
		for index, frame in ipairs(State.bg.glowFrames) do
			frame.BackgroundColor3 = (index % 2 == 0) and theme.Accent2 or Library.Config.Accent
		end
	end
	ApplyBackdrop()
	if Library._RefreshElements then
		Library:_RefreshElements()
	end
end

--------------------------------------------------------------------------------
-- backdrop / background image
--------------------------------------------------------------------------------

State = {
	gui = nil,
	root = nil,
	body = nil,
	popups = nil,
	splashGui = nil,
	scale = 1,
	targetPosition = nil,
	dragging = false,
	bg = {},
	notifyRight = nil,
	notifyLeft = nil,
	activePopup = nil,
	settingsElements = {},
	notificationCount = 0,
	connections = {},
}

-- NOTE: backdrops are intentionally UI-only. A Roblox BlurEffect lives in
-- Lighting and blurs the whole 3D game world, never the GUI, so we never touch
-- Lighting. Every backdrop is built from Chillui's own layers behind the window.
function ApplyBackdrop()
	local mode = Library.BackdropName
	local bg = State.bg
	if not bg.root then
		return
	end

	local lite = IsLite()

	if lite then
		bg.root.BackgroundTransparency = 0
		bg.image.Visible = false
		bg.tint.Visible = false
		bg.gradient.Visible = false
		if bg.frost then
			bg.frost.Visible = false
		end
		bg.glow1.Visible = false
		bg.glow2.Visible = false
		return
	end

	local bgTransparency = 0
	local showImage = false
	local showTint = false
	local showGradient = false
	local showFrost = false
	local showGlow = false
	local tintTransparency = 0.72

	if mode == "Solid" then
		bgTransparency = 0
	elseif mode == "Semi" then
		bgTransparency = 0.18
		tintTransparency = 0.55
		showTint = true
	elseif mode == "Glass" then
		bgTransparency = 0.42
		showFrost = true
		showGlow = true
	elseif mode == "Acrylic" then
		bgTransparency = 0.34
		showTint = true
		tintTransparency = 0.85
		showFrost = true
		showGlow = true
	elseif mode == "Mica" then
		bgTransparency = 0.22
		showTint = true
		tintTransparency = 0.55
		showGradient = true
		showFrost = true
		showGlow = true
	elseif mode == "Vibrant" then
		bgTransparency = 0.05
		showGradient = true
		showGlow = true
	elseif mode == "Blur" then
		bgTransparency = 0.5
		showTint = true
		tintTransparency = 0.7
		showFrost = true
	elseif mode == "Image" then
		bgTransparency = 0.02
		showImage = bg.image.Image ~= ""
		showTint = true
		tintTransparency = 0.45 + (Library.Config.BackgroundImageTransparency or 0.25)
	end

	bg.root.BackgroundTransparency = bgTransparency
	bg.image.Visible = showImage
	bg.tint.Visible = showTint
	bg.tint.BackgroundTransparency = tintTransparency
	bg.gradient.Visible = showGradient
	if bg.frost then
		bg.frost.Visible = showFrost
	end
	bg.glow1.Visible = showGlow
	bg.glow2.Visible = showGlow
end

local function ResolveImage(input)
	input = tostring(input or "")
	if input == "" then
		return nil, "No image path provided."
	end
	if input:match("^rbxassetid://") or input:match("^rbxasset://") or input:match("^http") then
		return input
	end
	if typeof(getcustomasset) == "function" then
		local ok, asset = pcall(getcustomasset, input)
		if ok and asset and asset ~= "" then
			return asset
		end
		return nil, "getcustomasset failed. Put the image inside your executor's workspace folder and try the full path."
	end
	return nil, "This executor does not support local images (getcustomasset missing). Use an rbxassetid:// instead."
end

function Library:SetBackgroundImage(path)
	local asset, err = ResolveImage(path)
	if not asset then
		self:Notify({ Title = "Background image", Description = err or "Could not load image." })
		return false
	end
	self.Config.BackgroundImage = path
	if State.bg.image then
		State.bg.image.Image = asset
		State.bg.image.ImageTransparency = self.Config.BackgroundImageTransparency or 0.25
	end
	self.BackdropName = "Image"
	ApplyBackdrop()
	return true
end

function Library:SetBackdrop(name)
	local wanted = tostring(name or ""):lower()
	local match
	for _, entry in ipairs(self.Backdrops) do
		if entry:lower() == wanted then
			match = entry
			break
		end
	end
	if not match then
		if wanted == "milca" or wanted == "micah" then
			match = "Mica"
		elseif wanted == "transparent" or wanted == "semi-transparent" or wanted == "semitransparent" then
			match = "Semi"
		elseif wanted == "native" then
			match = "Solid"
		end
	end
	if not match then
		return false
	end
	self.BackdropName = match
	self.Config.Backdrop = match
	ApplyBackdrop()
	return true
end

--------------------------------------------------------------------------------
-- notifications + sounds
--------------------------------------------------------------------------------

function Library:PlaySound(name)
	if not self.Config.Sounds or IsLite() then
		return
	end
	local id = SoundPresets[name or self.Config.StartupSound]
	if not id then
		return
	end
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = 0.18
		sound.Parent = SoundService
		sound:Play()
		task.delay(3, function()
			sound:Destroy()
		end)
	end)
end

function Library:BlockSound()
	if IsLite() or not self.Config.Sounds then
		return
	end
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/clickfast.wav"
		sound.Volume = 0.08
		sound.Parent = SoundService
		sound:Play()
		task.delay(1, function()
			sound:Destroy()
		end)
	end)
end

local notificationIndex = 0

function Library:Notify(opts)
	opts = opts or {}
	if not State.gui and not State.splashGui then
		return
	end
	notificationIndex += 1
	local lite = IsLite()
	local parentGui = State.gui or State.splashGui
	local container = (self.NotifySide == "Right") and State.notifyRight or State.notifyLeft
	if not container then
		return
	end

	local toast = Create("Frame", {
		Name = "Toast" .. notificationIndex,
		Size = UDim2.fromOffset(292, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = lite and 0 or 0.04,
		LayoutOrder = notificationIndex,
		Parent = container,
	})
	Track("panels", toast)
	Corner(10, toast)
	local stroke = Create("UIStroke", {
		Color = self.Theme.Stroke,
		Transparency = 0.25,
		Thickness = 1,
		Parent = toast,
	})
	Track("strokes", stroke)
	Create("Frame", {
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.new(0, 0, 0, 8),
		BackgroundColor3 = self.Config.Accent,
		Parent = toast,
	}, { Corner(2) })
	Pad(10, 12, 10, 14, toast)

	local title = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 16),
		Text = tostring(opts.Title or "Chillui"),
		TextColor3 = self.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toast,
	}, "texts")

	local desc = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 19),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(opts.Description or opts.Text or ""),
		TextColor3 = self.Theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = toast,
	}, "subtexts")

	task.defer(function()
		toast.Size = UDim2.fromOffset(292, 62 + desc.TextBounds.Y)
	end)

	if not lite then
		toast.BackgroundTransparency = 1
		title.TextTransparency = 1
		desc.TextTransparency = 1
		Animate(toast, { BackgroundTransparency = 0.04 }, 0.25)
		Animate(title, { TextTransparency = 0 }, 0.25)
		Animate(desc, { TextTransparency = 0 }, 0.25)
	end

	local life = tonumber(opts.Time or 4) or 4
	task.delay(life, function()
		if not toast.Parent then
			return
		end
		if lite then
			toast:Destroy()
			return
		end
		Animate(toast, { BackgroundTransparency = 1, Size = UDim2.fromOffset(280, toast.AbsoluteSize.Y) }, 0.25)
		Animate(title, { TextTransparency = 1 }, 0.2)
		Animate(desc, { TextTransparency = 1 }, 0.2)
		Animate(stroke, { Transparency = 1 }, 0.2)
		task.delay(0.3, function()
			toast:Destroy()
		end)
	end)
	return toast
end

--------------------------------------------------------------------------------
-- element base
--------------------------------------------------------------------------------

local Element = {}
Element.__index = Element
local Elements = {}

function Element.new(index, kind)
	local self = setmetatable({}, Element)
	self.Index = index
	self.Type = kind
	self.Value = nil
	self.ChangedCallbacks = {}
	self.ClickCallbacks = {}
	self.Disabled = false
	if index ~= nil then
		Options[index] = self
	end
	return self
end

function Element:OnChanged(fn)
	if type(fn) == "function" then
		table.insert(self.ChangedCallbacks, fn)
	end
	return self
end

function Element:OnClick(fn)
	if type(fn) == "function" then
		table.insert(self.ClickCallbacks, fn)
	end
	return self
end

function Element:_fire(value, silent)
	self.Value = value
	if not silent then
		for _, fn in ipairs(self.ChangedCallbacks) do
			local ok, err = pcall(fn, value)
			if not ok then
				warn("[Chillui] callback error:", err)
			end
		end
	end
	return self
end

function Element:_click()
	for _, fn in ipairs(self.ClickCallbacks) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Chillui] click callback error:", err)
		end
	end
end

function Element:SetValue(value, silent)
	if self._set then
		self._set(value, silent)
	end
	return self
end

function Element:GetValue()
	return self.Value
end

function Element:SetVisible(visible)
	if self.Row then
		self.Row.Visible = not not visible
	end
	return self
end

function Element:SetDisabled(disabled)
	self.Disabled = not not disabled
	if self.Row then
		for _, obj in ipairs(self.Row:GetDescendants()) do
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				obj.TextTransparency = disabled and 0.45 or 0
			end
		end
		if self.Row:IsA("TextLabel") or self.Row:IsA("TextButton") then
			self.Row.TextTransparency = disabled and 0.45 or 0
		end
	end
	return self
end

function Element:SetText(text)
	local value = tostring(text)
	if self.Type == "Label" and self._set then
		self._set(value, false)
		return self
	end
	self.Value = value
	if self.TextLabel then
		self.TextLabel.Text = value
	elseif self.Row and self.Row:IsA("TextLabel") then
		self.Row.Text = value
	end
	return self
end

--------------------------------------------------------------------------------
-- tooltip
--------------------------------------------------------------------------------

local tooltip

local function HideTooltip()
	if tooltip then
		tooltip.Visible = false
	end
end

local function ShowTooltip(text)
	if IsLite() or not State.gui or not text or text == "" then
		return
	end
	if not tooltip or not tooltip.Parent then
		tooltip = Create("TextLabel", {
			Name = "ChilluiTooltip",
			BackgroundColor3 = Library.Theme.Window,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			TextSize = 11,
			TextColor3 = Library.Theme.Text,
			TextWrapped = false,
			Visible = false,
			ZIndex = 9999,
			Parent = State.gui,
		})
		Corner(6, tooltip)
		Create("UIStroke", {
			Color = Library.Theme.Stroke,
			Transparency = 0.3,
			Parent = tooltip,
		})
		Pad(5, 8, 5, 8, tooltip)
	end
	tooltip.Text = tostring(text)
	tooltip.Position = UDim2.fromOffset(UIS:GetMouseLocation().X + 16, UIS:GetMouseLocation().Y + 16)
	tooltip.Visible = true
end

local function AttachTooltip(row, text, disabledText, element)
	if not text and not disabledText then
		return
	end
	row.MouseEnter:Connect(function()
		ShowTooltip((element and element.Disabled and disabledText) or text)
	end)
	row.MouseLeave:Connect(HideTooltip)
end

--------------------------------------------------------------------------------
-- keybind engine
--------------------------------------------------------------------------------

local function KeyNameFromInput(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		return "MB1"
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "MB2"
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		return "MB3"
	elseif input.KeyCode ~= Enum.KeyCode.Unknown then
		return input.KeyCode.Name
	end
	return nil
end

UIS.InputBegan:Connect(function(input, gameProcessed)
	local name = KeyNameFromInput(input)
	if not name then
		return
	end
	if State.bindingElement then
		if input.KeyCode == Enum.KeyCode.Escape then
			State.bindingElement:_finishBind(nil)
		else
			State.bindingElement:_finishBind(name)
		end
		return
	end
	-- Don't steal keys while the user is typing in a text box.
	local focused = UIS.GetFocusedTextBox and UIS:GetFocusedTextBox()
	if focused then
		return
	end
	-- The menu toggle keybind always works, even when the key is otherwise
	-- "game processed" (RightShift is reported as processed by the client).
	-- Match the toggle by ELEMENT IDENTITY, not by index: rebinding then takes
	-- effect immediately, and a second keybind that reuses the "MenuKeybind"
	-- index can no longer keep the old key alive or toggle a second time.
	local toggleElement = Library.ToggleKeybind
	local toggled = false
	for _, keybind in ipairs(Library.Keybinds) do
		if keybind.Key == name then
			if keybind == toggleElement then
				Library:Toggle()
				toggled = true
			elseif not gameProcessed then
				keybind:_press()
			end
		end
	end
	if not toggled and not toggleElement and Library.Config.MenuKey == name then
		Library:Toggle()
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	local name = KeyNameFromInput(input)
	if not name or gameProcessed then
		return
	end
	for _, keybind in ipairs(Library.Keybinds) do
		if keybind.Key == name and keybind.Mode == "Hold" then
			keybind:_release()
		end
	end
end)

--------------------------------------------------------------------------------
-- popup helpers
--------------------------------------------------------------------------------

local function ClosePopup()
	if State.activePopup then
		if State.activePopup.frame then
			State.activePopup.frame:Destroy()
		end
		if State.activePopup.catcher then
			State.activePopup.catcher:Destroy()
		end
		State.activePopup = nil
	end
end

local function OpenPopup(anchor, height, widthOverride)
	ClosePopup()
	local root = State.root
	if not root then
		return nil
	end
	local frame = Create("Frame", {
		Name = "ChilluiPopup",
		BackgroundColor3 = Library.Theme.Window,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 60,
		Visible = false,
		Parent = root,
	})
	Corner(math.min(Library.CornerRadius, 10), frame)
	local stroke = Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Thickness = 1,
		Transparency = 0.15,
		Parent = frame,
	})
	Track("strokes", stroke)

	local scale = 1
	if root.AbsoluteSize.X > 0 and root.Size.X.Offset > 0 then
		scale = root.AbsoluteSize.X / root.Size.X.Offset
	end
	local relative = anchor.AbsolutePosition - root.AbsolutePosition
	local x = relative.X / scale
	local y = relative.Y / scale + anchor.AbsoluteSize.Y / scale + 6
	local width = widthOverride or (anchor.AbsoluteSize.X / scale)
	local limit = root.Size.Y.Offset - 18
	if y + height > limit then
		y = math.max(10, relative.Y / scale - height - 6)
	end
	x = math.clamp(x, 8, math.max(8, root.Size.X.Offset - width - 8))
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(width, height)
	frame.Visible = true

	-- Modal click catcher: sits just behind the popup so any click that misses
	-- the popup closes it. This avoids relying on InputObject.Target, which is
	-- unavailable on some clients/executors.
	local catcher = Create("TextButton", {
		Name = "ChilluiPopupCatcher",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 59,
		Parent = root,
	})
	catcher.MouseButton1Click:Connect(function()
		ClosePopup()
	end)

	State.activePopup = { frame = frame, anchor = anchor, catcher = catcher }
	return frame
end

State.ClosePopup = ClosePopup

local function CreatePopupCard(height, anchor, width)
	return OpenPopup(anchor, height, width)
end

--------------------------------------------------------------------------------
-- splash / mode select
--------------------------------------------------------------------------------

local SPLASH_TIPS = {
	"Warming up colors…",
	"Applying Crimson Brown…",
	"Reticulating splines…",
	"Rounding corners…",
	"Polishing pixels…",
	"Teaching buttons to click…",
	"Almost there…",
}

local function GlowBlob(parent, color, size, position, transparency)
	local blob = Create("Frame", {
		Size = UDim2.fromOffset(size, size),
		Position = position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0.86,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = blob })
	return blob
end

function Library:Splash(cfg)
	cfg = cfg or {}
	if self.Mode then
		return
	end
	if cfg.SkipSplash or self.SkipSplash then
		self.Mode = cfg.Mode or "Normal"
		return
	end
	if cfg.Mode == "Lite" or cfg.Mode == "Normal" then
		self.Mode = cfg.Mode
		return
	end

	local gui = Create("ScreenGui", {
		Name = "ChilluiStartup",
		DisplayOrder = 5000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GetGuiParent(),
	})
	State.splashGui = gui

	local backdrop = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(12, 8, 8),
		BorderSizePixel = 0,
		Parent = gui,
	})
	local bgGradient = Create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(self.Theme.Window, self.Theme.Panel),
		Parent = backdrop,
	})
	local glow1 = GlowBlob(backdrop, self.Config.Accent, 560, UDim2.fromScale(0.28, 0.34), 0.9)
	local glow2 = GlowBlob(backdrop, self.Theme.Accent2, 420, UDim2.fromScale(0.76, 0.7), 0.92)

	local container = Create("Frame", {
		Size = UDim2.fromOffset(520, 328),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	local logo = Create("Frame", {
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.fromOffset(234, 0),
		BackgroundColor3 = self.Config.Accent,
		BorderSizePixel = 0,
		Parent = container,
	})
	Corner(15, logo)
	Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(self.Config.Accent, self.Theme.Accent2),
		Parent = logo,
	})
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "C",
		TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 248, 245),
		Parent = logo,
	})
	local title = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "C H I L L U I",
		TextSize = 28,
		TextColor3 = self.Theme.Text,
		Parent = container,
	})
	local subtitle = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Pick how you want to play",
		TextSize = 13,
		TextColor3 = self.Theme.SubText,
		Parent = container,
	}, "subtexts")

	local cards = Create("Frame", {
		Position = UDim2.fromOffset(24, 132),
		Size = UDim2.new(1, -48, 0, 182),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local chosen = false
	local function Pick(mode)
		if chosen then
			return
		end
		chosen = mode
	end

	local function MakeCard(mode, x, accent, tagline, bullets)
		local card = Create("Frame", {
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(230, 178),
			BackgroundColor3 = self.Theme.Panel,
			BackgroundTransparency = 0.03,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = cards,
		})
		Corner(12, card)
		local stroke = Create("UIStroke", {
			Color = IsLite() and self.Theme.Stroke or accent,
			Transparency = 0.55,
			Thickness = 1,
			Parent = card,
		})
		Track("strokes", stroke)
		Create("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = card,
		})
		MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 18),
			Size = UDim2.new(1, -32, 0, 22),
			Text = mode,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = self.Theme.Text,
			Parent = card,
		})
		MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 40),
			Size = UDim2.new(1, -32, 0, 16),
			Text = tagline,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = self.Theme.SubText,
			TextWrapped = true,
			Parent = card,
		}, "subtexts")
		local y = 68
		for _, bullet in ipairs(bullets) do
			MakeText("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, y),
				Size = UDim2.new(1, -28, 0, 15),
				Text = "•  " .. bullet,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = self.Theme.SubText,
				Parent = card,
			}, "subtexts")
			y += 19
		end
		local pill = Create("Frame", {
			Position = UDim2.new(0, 16, 1, -42),
			Size = UDim2.new(1, -32, 0, 28),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Parent = card,
		})
		Corner(8, pill)
		local pillStroke = Create("UIStroke", {
			Color = accent,
			Transparency = 0.6,
			Parent = pill,
		})
		MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "Select",
			TextSize = 12,
			TextColor3 = accent,
			Parent = pill,
		})
		local click = Create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = card,
		})
		click.MouseEnter:Connect(function()
			Animate(card, { BackgroundTransparency = 0 }, 0.18)
			Animate(stroke, { Transparency = 0.15 }, 0.18)
			Animate(pill, { BackgroundTransparency = 0.78 }, 0.18)
		end)
		click.MouseLeave:Connect(function()
			Animate(card, { BackgroundTransparency = 0.03 }, 0.18)
			Animate(stroke, { Transparency = 0.55 }, 0.18)
			Animate(pill, { BackgroundTransparency = 0.9 }, 0.18)
		end)
		click.MouseButton1Click:Connect(function()
			Library:BlockSound()
			Pick(mode)
		end)
		return card
	end

	MakeCard("Normal", 0, self.Config.Accent, "The full Chillui experience.", {
		"Custom backdrops & blur",
		"Background images",
		"Smooth animations",
	})
	MakeCard("Lite", 242, self.Theme.Accent2, "Barebones, flat and fast.", {
		"Zero effects",
		"Minimal memory use",
		"Made for potato PCs",
	})

	local hint = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 318),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "v" .. self.Version .. "  •  lightweight by design",
		TextSize = 10,
		TextColor3 = self.Theme.SubText,
		Parent = container,
	}, "subtexts")

	while not chosen do
		task.wait(0.05)
	end

	Library.Mode = chosen
	Library.Config.Mode = chosen
	self:PlaySound()

	for _, obj in ipairs(cards:GetChildren()) do
		if obj:IsA("Frame") then
			Animate(obj, { BackgroundTransparency = 1 }, 0.2)
			for _, child in ipairs(obj:GetDescendants()) do
				if child:IsA("Frame") then
					child.BackgroundTransparency = math.max(child.BackgroundTransparency, 0.8)
				elseif child:IsA("TextLabel") then
					child.TextTransparency = 0.8
				elseif child:IsA("UIStroke") then
					child.Transparency = 1
				end
			end
		end
	end
	Animate(subtitle, { TextTransparency = 1 }, 0.2)
	Animate(hint, { TextTransparency = 1 }, 0.2)
	cards.Visible = false
	subtitle.Visible = false
	hint.Visible = false

	local status = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 140),
		Size = UDim2.new(1, 0, 0, 18),
		Text = IsLite() and "Starting lite mode…" or "Starting Chillui…",
		TextSize = 12,
		TextColor3 = self.Theme.SubText,
		Parent = container,
	}, "subtexts")

	local bar = Create("Frame", {
		Position = UDim2.fromOffset(60, 178),
		Size = UDim2.new(1, -120, 0, 6),
		BackgroundColor3 = self.Theme.Element,
		BorderSizePixel = 0,
		Parent = container,
	})
	Corner(3, bar)
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = self.Config.Accent,
		BorderSizePixel = 0,
		Parent = bar,
	})
	Corner(3, fill)
	local barGlow = Create("UIStroke", {
		Color = self.Config.Accent,
		Thickness = 1,
		Transparency = 0.6,
		Parent = bar,
	})

	local steps = IsLite() and 10 or 20
	for index = 1, steps do
		if not gui.Parent then
			break
		end
		fill.Size = UDim2.fromScale(index / steps, 1)
		status.Text = IsLite() and "Loading…" or SPLASH_TIPS[(index % #SPLASH_TIPS) + 1]
		task.wait(IsLite() and 0.035 or 0.055)
	end
	status.Text = "Ready"
	Animate(fill, { BackgroundColor3 = self.Theme.Accent2 }, 0.2)

	task.wait(0.1)
	if not IsLite() then
		Animate(backdrop, { BackgroundTransparency = 1 }, 0.35)
		Animate(glow1, { BackgroundTransparency = 1 }, 0.35)
		Animate(glow2, { BackgroundTransparency = 1 }, 0.35)
		local fadeTargets = {}
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("TextLabel") then
				table.insert(fadeTargets, { obj, { TextTransparency = 1 } })
			elseif obj:IsA("Frame") and obj ~= container then
				table.insert(fadeTargets, { obj, { BackgroundTransparency = 1 } })
			elseif obj:IsA("UIStroke") then
				table.insert(fadeTargets, { obj, { Transparency = 1 } })
			end
		end
		for _, entry in ipairs(fadeTargets) do
			Animate(entry[1], entry[2], 0.3)
		end
		task.wait(0.3)
	end

	gui:Destroy()
	State.splashGui = nil
end

--------------------------------------------------------------------------------
-- window shell
--------------------------------------------------------------------------------

local Tab, Groupbox, Tabbox, SubTab
local CreateGroupbox, CreateTabbox, CreateKeybindFrame

local ICON_GLYPHS = {
	user = "◉", users = "◉", settings = "⚙", key = "⌘", keys = "⌘", home = "⌂",
	star = "★", bolt = "⚡", zap = "⚡", shield = "◈", eye = "◉", code = "⌘",
	sword = "†", swords = "†", box = "▣", boxes = "▣", package = "▣",
	list = "☰", info = "i", palette = "◐", wrench = "✚", tool = "✚",
	target = "◎", folder = "▤", lock = "⚿", sparkles = "✦", heart = "♥",
	music = "♪", globe = "◍", clock = "◷", play = "▶", image = "▧",
	search = "⌕", refresh = "↻", save = "▤", trash = "✕", close = "✕",
	check = "✓", chevron = "▾", plus = "+", minus = "−", cpu = "▣",
	activity = "◷", sliders = "⚙", layers = "▤", terminal = "⌘",
	gamepad = "◎", mouse = "◉", keyboard = "⌨", file = "▤", database = "▤",
	download = "▾", upload = "▴", power = "⏻", flame = "✦", droplet = "◐",
}

local function MakeIcon(parent, icon, size, color, position)
	if not icon then
		return nil
	end
	if type(icon) == "number" or tostring(icon):match("^rbxassetid://") then
		local id = type(icon) == "number" and ("rbxassetid://" .. icon) or icon
		return Create("ImageLabel", {
			Size = UDim2.fromOffset(size, size),
			Position = position or UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Image = id,
			ImageColor3 = color or Color3.fromRGB(255, 255, 255),
			Parent = parent,
		})
	end
	local key = tostring(icon):lower()
	local glyph = ICON_GLYPHS[key] or "◆"
	return MakeText("TextLabel", {
		Size = UDim2.fromOffset(size, size),
		Position = position or UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = glyph,
		TextSize = math.floor(size * 0.95),
		TextColor3 = color or Library.Theme.SubText,
		Parent = parent,
	}, "subtexts")
end

local function SelButton(button, selected, icon, label)
	if selected then
		button.BackgroundColor3 = Library.Config.Accent
		button.BackgroundTransparency = 0.12
		if label then
			label.TextColor3 = Library.Theme.OnAccent
		end
		if icon and icon:IsA("TextLabel") then
			icon.TextColor3 = Library.Theme.OnAccent
		end
	else
		button.BackgroundColor3 = Library.Theme.Element
		button.BackgroundTransparency = 1
		if label then
			label.TextColor3 = Library.Theme.SubText
		end
		if icon and icon:IsA("TextLabel") then
			icon.TextColor3 = Library.Theme.SubText
		end
	end
end

local function CreateTabPage(content, name)
	local page = Create("ScrollingFrame", {
		Name = "Page_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Library.Config.Accent,
		ScrollBarImageTransparency = 0.4,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = content,
	})
	Pad(12, 10, 16, 12, page)
	local columns = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = page,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = columns,
	})
	local left = Create("Frame", {
		Size = UDim2.new(0.5, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = columns,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = left,
	})
	local right = Create("Frame", {
		Size = UDim2.new(0.5, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = columns,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = right,
	})
	return page, left, right
end

local WindowClass = {}
WindowClass.__index = WindowClass

function WindowClass:SelectTab(name)
	local tab = self.Tabs[name]
	if not tab then
		return
	end
	if self.Current and self.Current ~= tab then
		self.Current.Page.Visible = false
		SelButton(self.Current.Button, false, self.Current.Icon, self.Current.Label)
	end
	self.Current = tab
	tab.Page.Visible = true
	SelButton(tab.Button, true, tab.Icon, tab.Label)
	task.defer(function()
		tab.Page.CanvasPosition = Vector2.zero
	end)
end

function WindowClass:AddTab(name, icon)
	if self.Tabs[name] then
		return self.Tabs[name]
	end
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = name

	local button = Create("TextButton", {
		Name = "Tab_" .. name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = self.TabCount,
		Parent = self.TabList,
	})
	self.TabCount = self.TabCount + 1
	Corner(8, button)
	local iconObj = MakeIcon(button, icon, 15, Library.Theme.SubText, UDim2.fromOffset(10, 9))
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Text = name,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	}, "subtexts")
	tab.Button = button
	tab.Icon = iconObj
	tab.Label = label

	button.MouseEnter:Connect(function()
		if self.Current ~= tab then
			Animate(button, { BackgroundTransparency = 0.9 }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if self.Current ~= tab then
			Animate(button, { BackgroundTransparency = 1 }, 0.15)
		end
	end)
	button.MouseButton1Click:Connect(function()
		self:SelectTab(name)
		Library:BlockSound()
	end)

	tab.Page, tab.Left, tab.Right = CreateTabPage(self.Content, name)
	self.Tabs[name] = tab
	if not self.Current then
		self:SelectTab(name)
	end
	return tab
end

function WindowClass:AddKeyTab(name)
	return self:AddTab(name or "Key System", "key")
end

function WindowClass:Hide()
	if State.root then
		State.root.Visible = false
	end
end

function WindowClass:Show()
	if State.root then
		State.root.Visible = true
	end
end

function WindowClass:SetCornerRadius(radius)
	Library:SetCornerRadius(radius)
end

function WindowClass:SetAlwaysOnTop(value)
	self.AlwaysOnTop = value
end

Tab = {}
Tab.__index = Tab

function Tab:AddGroupbox(opts)
	if type(opts) == "string" then
		opts = { Name = opts }
	end
	opts = opts or {}
	local side = tostring(opts.Side or "Left"):lower()
	local column = (side == "right") and self.Right or self.Left
	return CreateGroupbox(column, opts)
end

function Tab:AddLeftGroupbox(name, icon)
	return CreateGroupbox(self.Left, { Name = name, IconName = icon })
end

function Tab:AddRightGroupbox(name, icon)
	return CreateGroupbox(self.Right, { Name = name, IconName = icon })
end

function Tab:AddLeftTabbox()
	return CreateTabbox(self.Left)
end

function Tab:AddRightTabbox()
	return CreateTabbox(self.Right)
end

function Tab:_defaultBox()
	if not self.DefaultBox then
		self.DefaultBox = CreateGroupbox(self.Left, { Headerless = true })
	end
	return self.DefaultBox
end

function Tab:AddLabel(...)
	return self:_defaultBox():AddLabel(...)
end

function Tab:AddButton(...)
	return self:_defaultBox():AddButton(...)
end
function Tab:AddToggle(...)
	return self:_defaultBox():AddToggle(...)
end

function Tab:AddCheckbox(...)
	return self:_defaultBox():AddCheckbox(...)
end

function Tab:AddSlider(...)
	return self:_defaultBox():AddSlider(...)
end

function Tab:AddInput(...)
	return self:_defaultBox():AddInput(...)
end

function Tab:AddDropdown(...)
	return self:_defaultBox():AddDropdown(...)
end

function Tab:AddKeyPicker(...)
	return self:_defaultBox():AddKeyPicker(...)
end

function Tab:AddColorPicker(...)
	return self:_defaultBox():AddColorPicker(...)
end

function Tab:AddDivider(...)
	return self:_defaultBox():AddDivider(...)
end

function Tab:AddKeyBox(...)
	return self:_defaultBox():AddKeyBox(...)
end

Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox:AddLabel(text, opts, index)
	return Elements.Label(self, text, opts, index)
end

function Groupbox:AddDivider()
	return Elements.Divider(self)
end

function Groupbox:AddButton(opts, legacyFunc)
	return Elements.Button(self, opts, legacyFunc)
end

function Groupbox:AddToggle(index, opts)
	return Elements.Toggle(self, index, opts)
end

function Groupbox:AddCheckbox(index, opts)
	return Elements.Checkbox(self, index, opts)
end

function Groupbox:AddSlider(index, opts)
	return Elements.Slider(self, index, opts)
end

function Groupbox:AddInput(index, opts)
	return Elements.Input(self, index, opts)
end

function Groupbox:AddDropdown(index, opts)
	return Elements.Dropdown(self, index, opts)
end

function Groupbox:AddColorPicker(index, opts)
	return Elements.ColorPicker(self, index, opts)
end

function Groupbox:AddKeyPicker(index, opts)
	return Elements.KeyPicker(self, index, opts)
end

function Groupbox:AddKeyBox(callback)
	return Elements.KeyBox(self, callback)
end

function Groupbox:AddTabbox()
	return CreateTabbox(self.Content)
end

Tabbox = {}
Tabbox.__index = Tabbox

SubTab = {}
SubTab.__index = SubTab

function SubTab:AddLabel(...)
	return Elements.Label(self.Box, ...)
end

function SubTab:AddDivider(...)
	return Elements.Divider(self.Box, ...)
end

function SubTab:AddButton(...)
	return Elements.Button(self.Box, ...)
end

function SubTab:AddToggle(...)
	return Elements.Toggle(self.Box, ...)
end

function SubTab:AddCheckbox(...)
	return Elements.Checkbox(self.Box, ...)
end

function SubTab:AddSlider(...)
	return Elements.Slider(self.Box, ...)
end

function SubTab:AddInput(...)
	return Elements.Input(self.Box, ...)
end

function SubTab:AddDropdown(...)
	return Elements.Dropdown(self.Box, ...)
end

function SubTab:AddColorPicker(...)
	return Elements.ColorPicker(self.Box, ...)
end

function SubTab:AddKeyPicker(...)
	return Elements.KeyPicker(self.Box, ...)
end

Tabbox.AddTab = function(self, name)
	local sub = setmetatable({}, SubTab)
	sub.Name = name
	local tabButton = Create("TextButton", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = #self.Tabs + 1,
		Parent = self.TabStrip,
	})
	Corner(6, tabButton)
	local tabText = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0),
		Position = UDim2.fromOffset(7, 0),
		Text = name,
		TextSize = 11,
		TextColor3 = Library.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = tabButton,
	}, "subtexts")
	Pad(0, 7, 0, 0, tabText)
	local content = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Container,
	})
	local list = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = content,
	})
	sub.Box = content
	sub.Button = tabButton
	sub.Label = tabText
	table.insert(self.Tabs, sub)
	tabButton.MouseButton1Click:Connect(function()
		self:Select(name)
	end)
	if #self.Tabs == 1 then
		self:Select(name)
	end
	return sub
end

function Tabbox:Select(name)
	for _, sub in ipairs(self.Tabs) do
		local active = sub.Name == name
		sub.Box.Visible = active
		if active then
			sub.Button.BackgroundColor3 = Library.Config.Accent
			sub.Button.BackgroundTransparency = 0.15
			sub.Label.TextColor3 = Library.Theme.OnAccent
		else
			sub.Button.BackgroundColor3 = Library.Theme.Element
			sub.Button.BackgroundTransparency = 1
			sub.Label.TextColor3 = Library.Theme.SubText
		end
	end
end

function Library:SetDPIScale(percent)
	local value = math.clamp(tonumber(percent) or 100, 50, 200)
	self.Config.DPI = value
	State.scale = value / 100
	if State.root and State.root:FindFirstChildOfClass("UIScale") then
		State.root:FindFirstChildOfClass("UIScale").Scale = State.scale
	end
end

function Library:SetNotifySide(side)
	self.NotifySide = (tostring(side):lower() == "right") and "Right" or "Left"
	self.Config.NotifySide = self.NotifySide
end

function Library:SetCornerRadius(radius)
	local value = math.clamp(tonumber(radius) or 12, 0, 24)
	self.CornerRadius = value
	self.Config.CornerRadius = value
	if State.bg.rootCorner then
		State.bg.rootCorner.CornerRadius = UDim.new(0, value)
	end
	for _, obj in ipairs({ State.bg.image, State.bg.tint, State.bg.gradient, State.bg.frost }) do
		if obj then
			local corner = obj:FindFirstChildOfClass("UICorner")
			if corner then
				corner.CornerRadius = UDim.new(0, value)
			end
		end
	end
	self:_SyncSettings()
	self:_QueueSaveSettings()
end

function Library:SetTheme(name)
	local theme = THEME_MAP[name]
	if not theme then
		for _, candidate in ipairs(THEMES) do
			if candidate.Name:lower() == tostring(name):lower() then
				theme = candidate
				break
			end
		end
	end
	if not theme then
		return false
	end
	self.ThemeName = theme.Name
	self.Theme = theme
	self.Config.Theme = theme.Name
	self.Config.Accent = theme.Accent
	ApplyTheme()
	self:_SyncSettings()
	self:_QueueSaveSettings()
	return true
end

function Library:SetFont(name)
	local label = name
	if not FONTS[label] then
		for candidate in next, FONTS do
			if candidate:lower() == tostring(name):lower() then
				label = candidate
				break
			end
		end
	end
	if not FONTS[label] then
		return false
	end
	self.FontName = label
	self.Config.Font = label
	for _, obj in ipairs(Skin.fonts) do
		if obj.Parent then
			obj.Font = FONTS[label]
		end
	end
	self:_SyncSettings()
	self:_QueueSaveSettings()
	return true
end

function Library:SetAccent(color)
	if typeof(color) ~= "Color3" then
		return false
	end
	self.Config.Accent = color
	ApplyTheme()
	self:_SyncSettings()
	self:_QueueSaveSettings()
	return true
end

function Library:Toggle()
	if not State.root then
		return
	end
	State.root.Visible = not State.root.Visible
	if State.root.Visible then
		self:BlockSound()
	end
end

function Library:AddDraggableLabel(text, cfg)
	cfg = cfg or {}
	if not State.gui then
		return nil
	end
	local chip = Create("TextButton", {
		Name = "ChilluiDraggableLabel",
		Size = UDim2.fromOffset(cfg.Width or 170, cfg.Height or 30),
		Position = cfg.Position or UDim2.fromOffset(24, 90),
		BackgroundColor3 = self.Theme.Panel,
		BackgroundTransparency = IsLite() and 0 or 0.08,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 30,
		Parent = State.gui,
	})
	Corner(math.min(self.CornerRadius, 10), chip)
	Track("panels", chip)
	Track("strokes", Create("UIStroke", {
		Color = self.Theme.Stroke,
		Transparency = 0.25,
		Parent = chip,
	}))
	Create("Frame", {
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = self.Config.Accent,
		BorderSizePixel = 0,
		Parent = chip,
	})
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -18, 1, 0),
		Text = tostring(text or "Draggable"),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = self.Theme.Text,
		Parent = chip,
	}, "texts")

	local dragging, dragStart, startPosition, connection
	chip.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		startPosition = chip.Position
		connection = UIS.InputChanged:Connect(function(changed)
			if not dragging then
				return
			end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(changed.Position.X, changed.Position.Y) - dragStart
			local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			chip.Position = UDim2.fromOffset(
				math.clamp(startPosition.X.Offset + delta.X, 0, math.max(viewport.X - chip.AbsoluteSize.X, 0)),
				math.clamp(startPosition.Y.Offset + delta.Y, 0, math.max(viewport.Y - chip.AbsoluteSize.Y, 0))
			)
		end)
	end)
	local endConnection = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end
	end)
	table.insert(State.connections, endConnection)

	return {
		Frame = chip,
		SetText = function(_, value)
			label.Text = tostring(value)
		end,
		Destroy = function()
			chip:Destroy()
		end,
	}
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if self.Window then
		return self.Window
	end
	if not self._settingsLoaded then
		self._settingsLoaded = true
		self:_LoadSettings()
	end
	self:Splash(cfg)

	State.scale = (self.Config.DPI or 100) / 100
	local theme = self.Theme

	local gui = Create("ScreenGui", {
		Name = "Chillui",
		DisplayOrder = 4000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local parented = pcall(function()
		gui.Parent = GetGuiParent()
	end)
	if not parented or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	State.gui = gui

	-- Lite gets a smaller default window, but it is NOT capped: an explicit
	-- Width/Height/Size (or the saved geometry) is always honored, and the user
	-- can resize the window in Lite too via the corner grip.
	local width = IsLite() and 580 or 660
	local height = IsLite() and 400 or 446
	local explicitSize = false
	if cfg.Width then
		width = cfg.Width
		explicitSize = true
	end
	if cfg.Height then
		height = cfg.Height
		explicitSize = true
	end
	if cfg.Size then
		width = cfg.Size.X.Offset
		height = cfg.Size.Y.Offset
		explicitSize = true
	end

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local radius = math.min(self.CornerRadius, 18)
	if IsLite() then
		radius = math.min(radius, 8)
	end

	local savedWindow = self.Config.Window
	local hasSavedGeometry = type(savedWindow) == "table"
	if hasSavedGeometry and not explicitSize then
		if tonumber(savedWindow.W) then
			width = math.clamp(tonumber(savedWindow.W), 360, math.max(viewport.X / State.scale, 360))
		end
		if tonumber(savedWindow.H) then
			height = math.clamp(tonumber(savedWindow.H), 260, math.max(viewport.Y / State.scale, 260))
		end
	end

	local startX = math.max(12, (viewport.X - width * State.scale) / 2)
	local startY = math.max(12, (viewport.Y - height * State.scale) / 2)
	if hasSavedGeometry and tonumber(savedWindow.X) and tonumber(savedWindow.Y) then
		startX = math.clamp(tonumber(savedWindow.X), 0, math.max(viewport.X - width * State.scale, 0))
		startY = math.clamp(tonumber(savedWindow.Y), 0, math.max(viewport.Y - height * State.scale, 0))
	end

	local root = Create("Frame", {
		Name = "Root",
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset(startX, startY),
		BackgroundColor3 = theme.Window,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui,
	})
	State.root = root
	Track("windows", root)
	local rootCorner = Corner(radius, root)
	local rootStroke = Create("UIStroke", {
		Color = theme.Stroke,
		Thickness = 1,
		Transparency = 0.25,
		Parent = root,
	})
	Track("strokes", rootStroke)
	local uiScale = Create("UIScale", {
		Scale = State.scale,
		Parent = root,
	})

	local bgImage = Create("ImageLabel", {
		Name = "BackdropImage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		ImageTransparency = self.Config.BackgroundImageTransparency or 0.25,
		ZIndex = 1,
		Parent = root,
	})
	Corner(radius, bgImage)
	local tint = Create("Frame", {
		Name = "Tint",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Window,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = root,
	})
	Corner(radius, tint)
	local gradient = Create("Frame", {
		Name = "Gradient",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.87,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = root,
	})
	Corner(radius, gradient)
	local gradientObj = Create("UIGradient", {
		Rotation = 125,
		Color = ColorSequence.new(self.Config.Accent, theme.Accent2),
		Parent = gradient,
	})
	Track("gradients", gradientObj)

	-- "Frost" sheen: a soft diagonal highlight used by the glassy backdrops
	-- (Glass / Acrylic / Mica / Blur). Purely a UI layer — nothing here can
	-- affect the game world.
	local frost = Create("Frame", {
		Name = "Frost",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = root,
	})
	Corner(radius, frost)
	local frostGradient = Create("UIGradient", {
		Rotation = 145,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(214, 224, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		Parent = frost,
	})
	Track("gradients", frostGradient)

	local glowLayer = Create("Frame", {
		Name = "Glow",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = root,
	})
	glowLayer.ClipsDescendants = true
	Corner(radius, glowLayer)
	local glowFrames = {}
	local g1 = GlowBlob(glowLayer, self.Config.Accent, 300, UDim2.new(0, 60, 0, -30), 0.9)
	local g1b = GlowBlob(glowLayer, self.Config.Accent, 200, UDim2.new(0, 60, 0, -30), 0.94)
	local g2 = GlowBlob(glowLayer, theme.Accent2, 340, UDim2.new(1, -40, 1, 60), 0.92)
	table.insert(glowFrames, g1)
	table.insert(glowFrames, g1b)
	table.insert(glowFrames, g2)
	State.bg.glowFrames = glowFrames
	State.bg.root = root
	State.bg.rootCorner = rootCorner
	State.bg.image = bgImage
	State.bg.tint = tint
	State.bg.gradient = gradient
	State.bg.frost = frost
	State.bg.glow1 = glowLayer
	State.bg.glow2 = glowLayer

	local body = Create("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = root,
	})
	State.body = body

	local topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local dragArea = Create("TextButton", {
		Name = "DragArea",
		Size = UDim2.new(1, -132, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = topbar,
	})

	local badge = Create("Frame", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromOffset(14, 13),
		BackgroundColor3 = self.Config.Accent,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	Corner(8, badge)
	Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(self.Config.Accent, theme.Accent2),
		Parent = badge,
	})
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "C",
		TextSize = 14,
		TextColor3 = theme.OnAccent,
		Parent = badge,
	})
	local titleLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(50, 11),
		Size = UDim2.new(0, 320, 0, 18),
		Text = tostring(cfg.Title or "Chillui"),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = theme.Text,
		Parent = topbar,
	}, "texts")
	local subtitleLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(50, 28),
		Size = UDim2.new(0, 320, 0, 14),
		Text = tostring(cfg.Footer or ("v" .. self.Version)),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = theme.SubText,
		Parent = topbar,
	}, "subtexts")
	self.TitleLabel = titleLabel

	local chip = Create("Frame", {
		Size = UDim2.fromOffset(52, 20),
		Position = UDim2.new(1, -124, 0, 16),
		BackgroundColor3 = self.Config.Accent,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	Corner(6, chip)
	Create("UIStroke", {
		Color = self.Config.Accent,
		Transparency = 0.65,
		Parent = chip,
	})
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = IsLite() and "LITE" or "FULL",
		TextSize = 9,
		TextColor3 = self.Config.Accent,
		Parent = chip,
	}, "accentTexts")

	local function TopButton(glyph, order, tooltipText)
		local button = Create("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, -64 + (order - 1) * 28, 0, 14),
			BackgroundColor3 = theme.Element,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = topbar,
		})
		Corner(7, button)
		local stroke = Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.6,
			Parent = button,
		})
		MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = glyph,
			TextSize = 12,
			TextColor3 = theme.SubText,
			Parent = button,
		}, "subtexts")
		button.MouseEnter:Connect(function()
			Animate(button, { BackgroundTransparency = 0.15 }, 0.12)
			ShowTooltip(tooltipText)
		end)
		button.MouseLeave:Connect(function()
			Animate(button, { BackgroundTransparency = 0.5 }, 0.12)
			HideTooltip()
		end)
		return button
	end
	local keysButton = TopButton("K", 1, "Keybinds")
	local hideButton = TopButton("×", 2, "Hide menu")
	keysButton.MouseButton1Click:Connect(function()
		if self.KeybindFrame then
			self.KeybindFrame.Visible = not self.KeybindFrame.Visible
		end
	end)
	hideButton.MouseButton1Click:Connect(function()
		self:Toggle()
		self:Notify({
			Title = "Chillui hidden",
			Description = "Use your menu keybind to show it again.",
			Time = 3,
		})
	end)

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(0, 176, 1, -52),
		BackgroundColor3 = theme.Window,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = body,
	})
	Pad(10, 10, 10, 10, sidebar)
	local div = Create("Frame", {
		Size = UDim2.new(0, 1, 1, -24),
		Position = UDim2.new(0, 176, 0, 12),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = body,
	})
	Track("dividers", div)

	if not IsLite() then
		local searchBox = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = theme.Element,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = sidebar,
		})
		Corner(7, searchBox)
		Create("UIStroke", {
			Color = theme.Stroke,
			Transparency = 0.6,
			Parent = searchBox,
		})
		MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.fromOffset(14, 30),
			Text = "⌕",
			TextSize = 14,
			TextColor3 = theme.SubText,
			Parent = searchBox,
		}, "subtexts")
		local searchInput = Create("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Text = "",
			PlaceholderText = "Search…",
			PlaceholderColor3 = theme.SubText,
			TextSize = 11,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = searchBox,
		})
		searchInput.Font = FONTS[self.FontName] or Enum.Font.Gotham
		table.insert(Skin.fonts, searchInput)
		Track("texts", searchInput)
		searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchInput.Text:lower()
			for name, tab in next, self.Tabs do
				local match = query == "" or name:lower():find(query, 1, true) ~= nil
				tab.Button.Visible = match
			end
		end)
	end

	local tabList = Create("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, IsLite() and -26 or -88),
		Position = UDim2.fromOffset(0, IsLite() and 0 or 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = tabList,
	})
	self.TabList = tabList

	local footLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Chillui v" .. self.Version .. (IsLite() and "  •  lite" or ""),
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.SubText,
		Parent = sidebar,
	}, "subtexts")

	local content = Create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(177, 52),
		Size = UDim2.new(1, -177, 1, -52),
		BackgroundTransparency = 1,
		Parent = body,
	})
	self.Content = content

	State.notifyRight = Create("Frame", {
		Name = "NotifyRight",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.fromOffset(292, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 900,
		Parent = gui,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Parent = State.notifyRight,
	})
	State.notifyLeft = Create("Frame", {
		Name = "NotifyLeft",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 18, 1, -18),
		Size = UDim2.fromOffset(292, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 900,
		Parent = gui,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Parent = State.notifyLeft,
	})

	local window = setmetatable({}, WindowClass)
	window.Tabs = {}
	window.TabCount = 1
	window.AlwaysOnTop = true
	window.Gui = gui
	window.TabList = tabList
	window.Content = content
	self.Window = window
	self.ToggleKeybind = nil

	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		ClosePopup()
		local startPosition = root.Position
		local startInput = Vector2.new(input.Position.X, input.Position.Y)
		local moving = true
		local connection, endConnection
		connection = UIS.InputChanged:Connect(function(changed)
			if not moving then
				return
			end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(changed.Position.X, changed.Position.Y) - startInput
			local maxX = math.max(viewport.X - root.AbsoluteSize.X, 0)
			local maxY = math.max(viewport.Y - root.AbsoluteSize.Y, 0)
			local x = math.clamp(startPosition.X.Offset + delta.X, 0, maxX)
			local y = math.clamp(startPosition.Y.Offset + delta.Y, 0, maxY)
			if IsLite() then
				root.Position = UDim2.fromOffset(x, y)
			else
				State.targetPosition = UDim2.fromOffset(x, y)
			end
		end)
		local function finish()
			moving = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
			if endConnection then
				endConnection:Disconnect()
				endConnection = nil
			end
			self:_RememberGeometry()
			if State.targetPosition and IsLite() then
				State.targetPosition = nil
			end
		end
		endConnection = UIS.InputEnded:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseButton1 or changed.UserInputType == Enum.UserInputType.Touch then
				finish()
			end
		end)
	end
	dragArea.InputBegan:Connect(beginDrag)

	-- The smooth-drag tween is a Normal-mode nicety only; Lite snaps directly.
	if not IsLite() then
		local smooth = RunService.RenderStepped:Connect(function(deltaTime)
			if not State.targetPosition or not root.Parent then
				return
			end
			local current = root.Position
			local targetX = State.targetPosition.X.Offset
			local targetY = State.targetPosition.Y.Offset
			local newX = current.X.Offset + (targetX - current.X.Offset) * math.min(deltaTime * 22, 1)
			local newY = current.Y.Offset + (targetY - current.Y.Offset) * math.min(deltaTime * 22, 1)
			root.Position = UDim2.fromOffset(newX, newY)
			if math.abs(targetX - newX) < 0.4 and math.abs(targetY - newY) < 0.4 then
				root.Position = UDim2.fromOffset(targetX, targetY)
				State.targetPosition = nil
			end
		end)
		table.insert(State.connections, smooth)
	end

	-- Corner resizer: available in BOTH modes so Lite users can pick their size.
	local resizer = Create("Frame", {
		Name = "Resizer",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = root,
	})
	local gripA = Create("Frame", {
		Size = UDim2.fromOffset(7, 2),
		Position = UDim2.fromOffset(6, 10),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = resizer,
	})
	Corner(1, gripA)
	local gripB = Create("Frame", {
		Size = UDim2.fromOffset(2, 7),
		Position = UDim2.fromOffset(11, 6),
		BackgroundColor3 = theme.Stroke,
		BorderSizePixel = 0,
		Parent = resizer,
	})
	Corner(1, gripB)

	resizer.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local startSize = root.Size
		local startInput = Vector2.new(input.Position.X, input.Position.Y)
		local resizing = true
		local connection, endConnection
		connection = UIS.InputChanged:Connect(function(changed)
			if not resizing then
				return
			end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(changed.Position.X, changed.Position.Y) - startInput
			local minWidth = IsLite() and 380 or 480
			local minHeight = IsLite() and 280 or 320
			local newWidth = math.clamp(startSize.X.Offset + delta.X / State.scale, minWidth, viewport.X / State.scale)
			local newHeight = math.clamp(startSize.Y.Offset + delta.Y / State.scale, minHeight, viewport.Y / State.scale)
			root.Size = UDim2.fromOffset(newWidth, newHeight)
		end)
		local function finish()
			resizing = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
			if endConnection then
				endConnection:Disconnect()
				endConnection = nil
			end
			self:_RememberGeometry()
		end
		endConnection = UIS.InputEnded:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseButton1 or changed.UserInputType == Enum.UserInputType.Touch then
				finish()
			end
		end)
	end)

	-- Outside clicks are handled by the modal click catcher created in OpenPopup.

	if cfg.ShowCustomCursor or self.Config.CustomCursor then
		self:SetCustomCursor(true)
	end

	if not IsLite() then
		uiScale.Scale = State.scale * 0.94
		Animate(uiScale, { Scale = State.scale }, 0.28, Enum.EasingStyle.Back)
	end

	CreateKeybindFrame(gui)
	if self.Config.BackgroundImage ~= "" and State.bg.image then
		local asset = ResolveImage(self.Config.BackgroundImage)
		if asset then
			State.bg.image.Image = asset
			State.bg.image.ImageTransparency = self.Config.BackgroundImageTransparency or 0.25
		end
	end
	ApplyBackdrop()
	return window
end

function Library:SetCustomCursor(enabled)
	self.ShowCustomCursor = not not enabled
	self.Config.CustomCursor = self.ShowCustomCursor
	if enabled and not IsLite() then
		if not State.cursor then
			State.oldMouseIcon = UIS.MouseIconEnabled
			local cursor = Create("Frame", {
				Name = "ChilluiCursor",
				Size = UDim2.fromOffset(18, 18),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ZIndex = 10000,
				Parent = State.gui,
			})
			local ring = Create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = cursor,
			})
			Corner(9, ring)
			Create("UIStroke", {
				Color = self.Config.Accent,
				Thickness = 1.5,
				Parent = ring,
			})
			local dot = Create("Frame", {
				Size = UDim2.fromOffset(4, 4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = self.Config.Accent,
				BorderSizePixel = 0,
				Parent = cursor,
			})
			Corner(2, dot)
			State.cursor = cursor
			local connection = RunService.RenderStepped:Connect(function()
				if not cursor.Parent then
					return
				end
				local location = UIS:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(location.X, location.Y)
			end)
			table.insert(State.connections, connection)
		end
		State.cursor.Visible = true
		UIS.MouseIconEnabled = false
	else
		if State.cursor then
			State.cursor.Visible = false
		end
		UIS.MouseIconEnabled = true
	end
end

--------------------------------------------------------------------------------
-- groupbox / tabbox builders
--------------------------------------------------------------------------------

local function NextOrder(parent)
	local current = parent:GetAttribute("ChilluiOrder") or 0
	current = current + 1
	parent:SetAttribute("ChilluiOrder", current)
	return current
end

local function ResolveBox(box)
	if type(box) == "table" and box.Content then
		return box.Content
	end
	return box
end

CreateGroupbox = function(column, opts)
	opts = opts or {}
	local group = setmetatable({}, Groupbox)
	group.Options = opts

	local frame = Create("Frame", {
		Name = opts.Name or "Groupbox",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Panel,
		BackgroundTransparency = IsLite() and 0 or 0.28,
		BorderSizePixel = 0,
		LayoutOrder = NextOrder(column),
		Parent = column,
	})
	Corner(10, frame)
	Track("panels", frame)
	local stroke = Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Thickness = 1,
		Transparency = 0.5,
		Parent = frame,
	})
	Track("strokes", stroke)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = frame,
	})

	local content
	if opts.Headerless then
		content = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = frame,
		})
		Pad(2, 10, 10, 10, content)
	else
		local header = Create("TextButton", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 1,
			Parent = frame,
		})
		MakeIcon(header, opts.IconName, 14, Library.Config.Accent, UDim2.fromOffset(10, 10))
		local title = MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.new(1, -80, 1, 0),
			Text = tostring(opts.Name or ""),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Library.Theme.Text,
			Parent = header,
		}, "texts")
		if opts.Description then
			local desc = MakeText("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -30, 0.5, 0),
				Size = UDim2.fromOffset(140, 14),
				Text = tostring(opts.Description),
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = Library.Theme.SubText,
				Parent = header,
			}, "subtexts")
			desc.Name = "Description"
		end
		local chevron = MakeText("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -11, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Text = "▾",
			TextSize = 10,
			TextColor3 = Library.Theme.SubText,
			Parent = header,
		}, "subtexts")

		content = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = frame,
		})
		Pad(2, 10, 10, 10, content)
		local collapsed = false
		header.MouseButton1Click:Connect(function()
			collapsed = not collapsed
			content.Visible = not collapsed
			chevron.Text = collapsed and "▸" or "▾"
			Library:BlockSound()
		end)
		if opts.Collapsed then
			collapsed = true
			content.Visible = false
			chevron.Text = "▸"
		end
		content.Name = "Content"
	end
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = content,
	})
	group.Frame = frame
	group.Content = content
	return group
end

CreateTabbox = function(parent)
	parent = ResolveBox(parent)
	local box = setmetatable({ Tabs = {} }, Tabbox)
	local frame = Create("Frame", {
		Name = "Tabbox",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Panel,
		BackgroundTransparency = IsLite() and 0 or 0.28,
		BorderSizePixel = 0,
		LayoutOrder = NextOrder(parent),
		Parent = parent,
	})
	Corner(10, frame)
	Track("panels", frame)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Thickness = 1,
		Transparency = 0.5,
		Parent = frame,
	}))
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = frame,
	})
	local strip = Create("Frame", {
		Name = "TabStrip",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = frame,
	})
	Pad(10, 8, 0, 8, strip)
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = strip,
	})
	local container = Create("Frame", {
		Name = "Container",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = frame,
	})
	Pad(0, 10, 10, 10, container)
	box.TabStrip = strip
	box.Container = container
	box.Frame = frame
	box.Name = "Tabbox"
	table.insert(State.tabboxes, box)
	return box
end

State.tabboxes = {}

--------------------------------------------------------------------------------
-- element constructors
--------------------------------------------------------------------------------

local function Row(parent, height)
	parent = ResolveBox(parent)
	return Create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = NextOrder(parent),
		Parent = parent,
	})
end

local function MakeButtonSurface(row, height)
	local button = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	return button
end

local function AttachSliderDrag(track, onInput)
	local dragging = false
	local connection, endConnection
	local scrolling = track:FindFirstAncestorOfClass("ScrollingFrame")
	local function update()
		local relative = math.clamp((MouseX() - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		onInput(relative)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		if scrolling then
			scrolling.ScrollingEnabled = false
		end
		update()
		connection = UIS.InputChanged:Connect(function(changed)
			if dragging and (changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch) then
				update()
			end
		end)
		endConnection = UIS.InputEnded:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseButton1 or changed.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				if scrolling then
					scrolling.ScrollingEnabled = true
				end
				if connection then
					connection:Disconnect()
					connection = nil
				end
				if endConnection then
					endConnection:Disconnect()
					endConnection = nil
				end
			end
		end)
	end)
end

local function MiniSlider(parent, order, labelText, minValue, maxValue, value, callback)
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(18, 26),
		Text = labelText,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.SubText,
		Parent = row,
	}, "subtexts")
	local valueLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(34, 26),
		Text = tostring(math.floor(value + 0.5)),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Library.Theme.Text,
		Parent = row,
	}, "texts")
	local track = Create("Frame", {
		Position = UDim2.fromOffset(22, 11),
		Size = UDim2.new(1, -60, 0, 4),
		BackgroundColor3 = Library.Theme.Element,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(2, track)
	Track("elements", track)
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Library.Config.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(2, fill)
	Track("accents", fill)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(6, knob)

	local state = { Value = value, Enabled = true }
	local function apply(newValue, silent)
		local clamped = math.clamp(newValue, minValue, maxValue)
		state.Value = clamped
		local ratio = (clamped - minValue) / math.max(maxValue - minValue, 0.0001)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = tostring(math.floor(clamped + 0.5))
		if not silent and state.Enabled then
			callback(clamped)
		end
	end
	AttachSliderDrag(track, function(relative)
		apply(minValue + (maxValue - minValue) * relative, false)
	end)
	apply(value, true)
	return {
		Value = value,
		Set = apply,
		SetEnabled = function(enabled)
			state.Enabled = enabled
			row.Visible = enabled
		end,
	}
end

Elements.Label = function(box, text, opts, index)
	if type(opts) == "boolean" then
		opts = { DoesWrap = opts }
	elseif type(opts) == "string" then
		index = index or opts
		opts = {}
	elseif type(opts) ~= "table" then
		opts = {}
	else
		opts = Clone(opts or {})
	end
	if type(text) == "table" then
		opts = Clone(text)
		text = opts.Text or ""
		if opts.Idx then
			index = opts.Idx
		end
	end
	if opts.Index then
		index = opts.Index
	end
	local parent = ResolveBox(box)
	local wrap = opts.DoesWrap ~= false
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(text),
		TextSize = opts.Size or 12,
		TextWrapped = wrap,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Library.Theme.Text,
		LayoutOrder = NextOrder(parent),
		Parent = parent,
	}, "texts")
	if index then
		local element = Element.new(index, "Label")
		element.TextLabel = label
		element.Box = parent
		element.Value = tostring(text)
		element._set = function(value, silent)
			element.Value = tostring(value)
			label.Text = tostring(value)
			if not silent then
				element:_fire(element.Value)
			end
		end
		element.AddColorPicker = function(_, pickerIndex, pickerOpts)
			return Elements.ColorPicker(parent, pickerIndex, pickerOpts)
		end
		element.AddKeyPicker = function(_, pickerIndex, pickerOpts)
			return Elements.KeyPicker(parent, pickerIndex, pickerOpts)
		end
		return element
	end
	local handle = {
		SetText = function(_, value)
			label.Text = tostring(value)
		end,
	}
	handle.AddColorPicker = function(_, pickerIndex, pickerOpts)
		return Elements.ColorPicker(parent, pickerIndex, pickerOpts)
	end
	handle.AddKeyPicker = function(_, pickerIndex, pickerOpts)
		return Elements.KeyPicker(parent, pickerIndex, pickerOpts)
	end
	handle.AddButton = function(_, buttonOpts)
		return Elements.Button(parent, buttonOpts)
	end
	return handle
end

Elements.Divider = function(box)
	local parent = ResolveBox(box)
	local divider = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Library.Theme.Stroke,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		LayoutOrder = NextOrder(parent),
		Parent = parent,
	})
	Track("dividers", divider)
	return divider
end

Elements.Button = function(box, opts, legacyFunc)
	if type(opts) == "function" then
		opts = { Text = "Button", Func = opts }
	elseif type(opts) == "string" then
		opts = { Text = opts, Func = legacyFunc }
	end
	opts = opts or {}
	local parent = ResolveBox(box)
	local row = Row(parent, 32)
	local element = Element.new(opts.Index, "Button")
	element.Row = row
	element.Box = parent
	element.Callback = opts.Func
	local button = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(8, button)
	Track("elements", button)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.6,
		Parent = button,
	}))
	MakeIcon(button, opts.Icon, 13, Library.Theme.SubText, UDim2.fromOffset(10, 9))
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(opts.Icon and 30 or 10, 0),
		Size = UDim2.new(1, (opts.Icon and 40 or 20), 1, 0),
		Text = tostring(opts.Text or "Button"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = opts.Risky and Color3.fromRGB(235, 96, 92) or Library.Theme.Text,
		Parent = button,
	}, "texts")
	if opts.Risky then
		element.RiskyLabel = label
	end
	element.TextLabel = label

	local lastClick = 0
	button.MouseEnter:Connect(function()
		if element.Disabled then
			return
		end
		Animate(button, { BackgroundTransparency = 0.05 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Animate(button, { BackgroundTransparency = 0.2 }, 0.15)
	end)
	button.MouseButton1Click:Connect(function()
		if element.Disabled then
			return
		end
		Library:BlockSound()
		local now = os.clock()
		if opts.DoubleClick and now - lastClick > 0.35 then
			lastClick = now
			Library:Notify({
				Title = "Double click",
				Description = "Click \"" .. tostring(opts.Text or "Button") .. "\" again to confirm.",
				Time = 2,
			})
			return
		end
		lastClick = now
		element:_click()
		if element.Callback then
			local ok, err = pcall(element.Callback)
			if not ok then
				warn("[Chillui] button error:", err)
			end
		end
	end)
	AttachTooltip(row, opts.Tooltip, opts.DisabledTooltip, element)
	element.AddButton = function(_, subOpts)
		subOpts = subOpts or {}
		subOpts.Sub = true
		return Elements.Button(parent, subOpts)
	end
	if opts.Disabled then
		element:SetDisabled(true)
	end
	element.SetText = function(_, value)
		label.Text = tostring(value)
	end
	return element
end

local function MakeToggleLike(box, index, opts, kind)
	opts = opts or {}
	local parent = ResolveBox(box)
	local element = Element.new(index, kind == "Checkbox" and "Checkbox" or "Toggle")
	element.Box = parent
	element.Callback = opts.Callback
	local row = Row(parent, 36)
	element.Row = row
	local click = MakeButtonSurface(row)
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -58, 1, 0),
		Text = tostring(opts.Text or index or "Toggle"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = opts.Risky and Color3.fromRGB(235, 96, 92) or Library.Theme.Text,
		Parent = row,
	}, "texts")
	element.TextLabel = label
	if opts.Risky then
		element.RiskyLabel = label
	end

	local track, knob, check
	if kind == "Checkbox" then
		track = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Parent = row,
		})
		Corner(5, track)
		Track("elements", track)
		Track("strokes", Create("UIStroke", {
			Color = Library.Theme.Stroke,
			Transparency = 0.4,
			Parent = track,
		}))
		check = MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "✓",
			TextSize = 12,
			TextColor3 = Library.Theme.OnAccent,
			Parent = track,
		}, "onAccents")
	else
		track = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			Size = UDim2.fromOffset(38, 21),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Parent = row,
		})
		Corner(11, track)
		Track("elements", track)
		knob = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(15, 15),
			BackgroundColor3 = Library.Theme.SubText,
			BorderSizePixel = 0,
			Parent = track,
		})
		Corner(8, knob)
	end

	element._attachRight = kind == "Checkbox" and 26 or 46
	element.ReserveAttach = function(width)
		local right = element._attachRight
		element._attachRight = right + width + 6
		if element.TextLabel then
			element.TextLabel.Size = UDim2.new(1, -(element._attachRight + 8), 1, 0)
		end
		return right
	end

	local function refreshVisuals()
		local on = not not element.Value
		if kind == "Checkbox" then
			track.BackgroundColor3 = on and Library.Config.Accent or Library.Theme.Element
			check.Visible = on
		else
			track.BackgroundColor3 = on and Library.Config.Accent or Library.Theme.Element
			knob.BackgroundColor3 = on and Library.Theme.OnAccent or Library.Theme.SubText
			Animate(knob, {
				Position = on and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}, 0.18, Enum.EasingStyle.Quint)
		end
		if element.RiskyLabel then
			element.RiskyLabel.TextColor3 = Color3.fromRGB(235, 96, 92)
		end
	end

	local function apply(value, silent)
		value = not not value
		element.Value = value
		refreshVisuals()
		if not silent then
			element:_fire(value, false)
		end
	end
	element._set = apply
	element._refreshTheme = refreshVisuals
	if opts.Callback then
		element:OnChanged(opts.Callback)
	end
	click.MouseButton1Click:Connect(function()
		if element.Disabled then
			return
		end
		Library:BlockSound()
		apply(not element.Value, false)
	end)
	click.MouseEnter:Connect(function()
		if element.Disabled then
			return
		end
		Animate(label, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
		if kind == "Toggle" then
			Animate(track, { BackgroundTransparency = 0 }, 0.15)
		end
	end)
	click.MouseLeave:Connect(function()
		if element.RiskyLabel then
			label.TextColor3 = Color3.fromRGB(235, 96, 92)
		else
			Animate(label, { TextColor3 = Library.Theme.Text }, 0.15)
		end
		Animate(track, { BackgroundTransparency = 0.1 }, 0.15)
	end)
	AttachTooltip(row, opts.Tooltip, opts.DisabledTooltip, element)
	apply(opts.Default == true, true)
	Toggles[index] = element
	element.AddColorPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachColorPicker(element, pickerIndex, pickerOpts)
	end
	element.AddKeyPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachKeyPicker(element, pickerIndex, pickerOpts)
	end
	if opts.Disabled then
		element:SetDisabled(true)
	end
	return element
end

Elements.Toggle = function(box, index, opts)
	return MakeToggleLike(box, index, opts, "Toggle")
end

Elements.Checkbox = function(box, index, opts)
	return MakeToggleLike(box, index, opts, "Checkbox")
end

Elements.Slider = function(box, index, opts)
	opts = opts or {}
	local parent = ResolveBox(box)
	local element = Element.new(index, "Slider")
	element.Box = parent
	element.Min = tonumber(opts.Min) or 0
	element.Max = tonumber(opts.Max) or 100
	element.Rounding = tonumber(opts.Rounding) or 0
	element.Suffix = opts.Suffix
	element.HideMax = opts.HideMax
	element.Compact = opts.Compact
	element.FormatDisplayValue = opts.FormatDisplayValue

	local row = Row(parent, 50)
	element.Row = row
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 0, 16),
		Text = tostring(opts.Text or index or "Slider"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.Text,
		Parent = row,
	}, "texts")
	local valueLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(62, 16),
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Library.Theme.SubText,
		Parent = row,
	}, "subtexts")

	if opts.Compact then
		label.Visible = false
		valueLabel.Visible = false
		row.Size = UDim2.new(1, 0, 0, 26)
	end

	local trackY = opts.Compact and 10 or 28
	local track = Create("Frame", {
		Position = UDim2.fromOffset(0, trackY),
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(3, track)
	Track("elements", track)
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Library.Config.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(3, fill)
	Track("accents", fill)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(7, knob)
	Create("UIStroke", {
		Color = Library.Config.Accent,
		Thickness = 1.5,
		Parent = knob,
	})

	local function formatValue(value)
		if element.FormatDisplayValue then
			local ok, result = pcall(element.FormatDisplayValue, element, value)
			if ok and result ~= nil then
				return tostring(result)
			end
		end
		local shown = (element.Rounding > 0) and tostring(value) or tostring(math.floor(value + 0.5))
		if element.Suffix then
			shown = shown .. element.Suffix
		end
		if element.HideMax or element.Compact then
			return shown
		end
		local maxShown = (element.Rounding > 0) and tostring(element.Max) or tostring(math.floor(element.Max + 0.5))
		return shown .. " / " .. maxShown .. (element.Suffix or "")
	end

	local function apply(value, silent)
		value = tonumber(value) or 0
		value = math.clamp(value, element.Min, element.Max)
		if element.Rounding > 0 then
			local step = 10 ^ -element.Rounding
			value = math.floor(value / step + 0.5) * step
			value = math.clamp(value, element.Min, element.Max)
			-- guard float noise
			value = tonumber(string.format("%." .. element.Rounding .. "f", value))
		else
			value = math.floor(value + 0.5)
		end
		element.Value = value
		local ratio = (value - element.Min) / math.max(element.Max - element.Min, 0.0001)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = formatValue(value)
		if not silent then
			element:_fire(value, false)
		end
	end
	element._set = apply
	AttachSliderDrag(track, function(relative)
		apply(element.Min + (element.Max - element.Min) * relative, false)
	end)
	AttachTooltip(row, opts.Tooltip, opts.DisabledTooltip, element)
	apply(opts.Default or element.Min, true)
	if opts.Disabled then
		element:SetDisabled(true)
	end
	return element
end

Elements.Input = function(box, index, opts)
	opts = opts or {}
	local parent = ResolveBox(box)
	local element = Element.new(index, "Input")
	element.Box = parent
	element.Callback = opts.Callback
	local row = Row(parent, 52)
	element.Row = row
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Text = tostring(opts.Text or index or "Input"),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.SubText,
		Parent = row,
	}, "subtexts")
	element.TextLabel = label
	local boxFrame = Create("Frame", {
		Position = UDim2.fromOffset(0, 19),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(7, boxFrame)
	Track("elements", boxFrame)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.5,
		Parent = boxFrame,
	}))
	local textBox = Create("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = tostring(opts.Default or ""),
		PlaceholderText = tostring(opts.Placeholder or ""),
		PlaceholderColor3 = Library.Theme.SubText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.Text,
		ClearTextOnFocus = false,
		Parent = boxFrame,
	})
	textBox.Font = FONTS[Library.FontName] or Enum.Font.Gotham
	table.insert(Skin.fonts, textBox)
	Track("texts", textBox)
	Pad(0, 8, 0, 8, textBox)

	local function commit(value, silent)
		element.Value = tostring(value or "")
		textBox.Text = element.Value
		if not silent then
			element:_fire(element.Value, false)
		end
	end
	element._set = function(value, silent)
		commit(value, silent)
	end

	textBox.Focused:Connect(function()
		if opts.ClearTextOnFocus then
			textBox.Text = ""
		end
		Animate(boxFrame, { BackgroundTransparency = 0.02 }, 0.15)
	end)
	textBox.FocusLost:Connect(function(enterPressed)
		Animate(boxFrame, { BackgroundTransparency = 0.15 }, 0.15)
		local text = textBox.Text
		if opts.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		if opts.MaxLength then
			text = text:sub(1, opts.MaxLength)
		end
		commit(text, false)
	end)
	if not opts.Finished then
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			if not textBox:IsFocused() then
				return
			end
			local text = textBox.Text
			if opts.Numeric then
				local filtered = text:gsub("[^%d%.%-]", "")
				if filtered ~= text then
					textBox.Text = filtered
					return
				end
			end
			if opts.MaxLength and #text > opts.MaxLength then
				textBox.Text = text:sub(1, opts.MaxLength)
				return
			end
			element.Value = text
			element:_fire(text, false)
		end)
	end
	AttachTooltip(row, opts.Tooltip, opts.DisabledTooltip, element)
	element.Value = tostring(opts.Default or "")
	if opts.Disabled then
		element:SetDisabled(true)
	end
	return element
end

--------------------------------------------------------------------------------
-- dropdown
--------------------------------------------------------------------------------

Elements.Dropdown = function(box, index, opts)
	opts = opts or {}
	local parent = ResolveBox(box)
	local element = Element.new(index, "Dropdown")
	element.Box = parent
	element.Multi = not not opts.Multi
	element.Callback = opts.Callback
	element.KeepDisabledValuePosition = opts.KeepDisabledValuePosition
	element.MaxVisibleDropdownItems = opts.MaxVisibleDropdownItems or 8
	element.SpecialType = opts.SpecialType

	local row = Row(parent, 38)
	element.Row = row
	local selector = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(8, selector)
	Track("elements", selector)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.5,
		Parent = selector,
	}))
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.5, -14, 1, 0),
		Text = tostring(opts.Text or index or "Dropdown"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.Text,
		Parent = selector,
	}, "texts")
	local valueLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		Size = UDim2.new(0.5, -20, 1, 0),
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.SubText,
		Parent = selector,
	}, "subtexts")
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -9, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		Text = "▾",
		TextSize = 9,
		TextColor3 = Library.Theme.SubText,
		Parent = selector,
	}, "subtexts")
	element.TextLabel = label

	local items = {} -- { key = ..., label = ... }
	local lookupLabel = {}
	local lookupKey = {}
	local disabled = {}

	local function rebuildDisabled()
		disabled = {}
		for _, value in ipairs(opts.DisabledValues or {}) do
			disabled[value] = true
			if lookupLabel[value] then
				disabled[lookupLabel[value]] = true
			end
		end
	end

	local function rebuildItems(raw)
		items = {}
		lookupLabel = {}
		lookupKey = {}
		if #raw > 0 then
			for _, value in ipairs(raw) do
				table.insert(items, { key = tostring(value), label = tostring(value) })
			end
		else
			for key, value in next, raw do
				table.insert(items, { key = tostring(key), label = tostring(value) })
			end
		end
		for _, item in ipairs(items) do
			lookupLabel[item.key] = item.label
			lookupKey[item.label] = item.key
		end
		rebuildDisabled()
	end
	rebuildItems(opts.Values or {})

	local function labelFor(key)
		return lookupLabel[key] or tostring(key)
	end

	local function valueText()
		if element.Multi then
			local selected = {}
			for key, on in next, element.Value or {} do
				if on then
					table.insert(selected, labelFor(key))
				end
			end
			if #selected == 0 then
				return "None"
			end
			if #selected <= 2 then
				return table.concat(selected, ", ")
			end
			return selected[1] .. " +" .. (#selected - 1)
		end
		if element.Value == nil or element.Value == "" then
			return "None"
		end
		return labelFor(element.Value)
	end

	local function refreshValue()
		valueLabel.Text = valueText()
	end

	local function isSelected(key)
		if element.Multi then
			return (element.Value or {})[key] == true
		end
		return element.Value == key
	end

	local function apply(value, silent)
		if element.Multi then
			if type(value) ~= "table" then
				value = {}
			end
			local copy = {}
			for key, on in next, value do
				if on then
					copy[tostring(key)] = true
				end
			end
			element.Value = copy
		else
			if value ~= nil then
				value = tostring(value)
				if lookupKey[value] then
					value = lookupKey[value]
				end
			end
			element.Value = value
		end
		refreshValue()
		if not silent then
			element:_fire(element.Value, false)
		end
	end
	element._set = apply

	local function openList()
		if State.activePopup and State.activePopup.anchor == selector then
			ClosePopup()
			return
		end
		if element.SpecialType == "Player" then
			local names = {}
			for _, player in ipairs(Players:GetPlayers()) do
				if not (opts.ExcludeLocalPlayer and player == LocalPlayer) then
					table.insert(names, player.Name)
				end
			end
			rebuildItems(names)
			refreshValue()
		elseif element.SpecialType == "Team" then
			local names = {}
			for _, team in ipairs(game:GetService("Teams"):GetTeams()) do
				table.insert(names, team.Name)
			end
			rebuildItems(names)
			refreshValue()
		end

		local searchable = opts.Searchable
		local perPage = element.MaxVisibleDropdownItems
		local shown = math.min(#items, perPage)
		local height = 10 + shown * 28 + (searchable and 32 or 0)
		local popup = OpenPopup(selector, height + 2, selector.AbsoluteSize.X / math.max(State.scale, 0.01))
		if not popup then
			return
		end
		popup.ClipsDescendants = true
		Pad(5, 5, 5, 5, popup)
		local listLayout = Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
			Parent = popup,
		})
		if searchable then
			local searchBox = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				LayoutOrder = 0,
				Parent = popup,
			})
			Corner(6, searchBox)
			local search = Create("TextBox", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				PlaceholderText = "Search…",
				PlaceholderColor3 = Library.Theme.SubText,
				Text = "",
				TextSize = 11,
				TextColor3 = Library.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Parent = searchBox,
			})
			search.Font = FONTS[Library.FontName] or Enum.Font.Gotham
			table.insert(Skin.fonts, search)
			Track("texts", search)
			Pad(0, 6, 0, 6, search)
		end

		local scroller = Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, shown * 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Config.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			LayoutOrder = 1,
			Parent = popup,
		})
		local inner = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = scroller,
		})
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
			Parent = inner,
		})

		local buttons = {}
		local function makeButton(item, order)
			local isDisabled = disabled[item.key] or disabled[item.label]
			local optionButton = Create("TextButton", {
				Name = "Option_" .. item.key,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = Library.Theme.Element,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = order,
				Parent = inner,
			})
			Corner(6, optionButton)
			local optionLabel = MakeText("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Text = item.label,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = isDisabled and Library.Theme.SubText or Library.Theme.Text,
				TextTransparency = isDisabled and 0.5 or 0,
				Parent = optionButton,
			}, "texts")
			local check = MakeText("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(12, 12),
				Text = "✓",
				TextSize = 11,
				TextColor3 = Library.Config.Accent,
				Visible = false,
				Parent = optionButton,
			}, "accentTexts")
			buttons[item.key] = { frame = optionButton, check = check }
			optionButton.MouseEnter:Connect(function()
				if not isDisabled then
					optionButton.BackgroundTransparency = 0.85
				end
			end)
			optionButton.MouseLeave:Connect(function()
				optionButton.BackgroundTransparency = 1
			end)
			optionButton.MouseButton1Click:Connect(function()
				if isDisabled or element.Disabled then
					return
				end
				if element.Multi then
					local current = {}
					for key, on in next, element.Value or {} do
						current[key] = on
					end
					current[item.key] = not current[item.key]
					apply(current, false)
					for key, refs in next, buttons do
						refs.check.Visible = isSelected(key)
					end
				else
					apply(item.key, false)
					ClosePopup()
				end
				valueLabel.Text = valueText()
				Library:BlockSound()
			end)
			return optionButton
		end
		for order, item in ipairs(items) do
			local optionButton = makeButton(item, order)
			optionButton.Visible = true
			local check = buttons[item.key].check
			check.Visible = isSelected(item.key)
		end
		if #items == 0 then
			MakeText("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				Text = "Nothing here",
				TextSize = 11,
				TextColor3 = Library.Theme.SubText,
				LayoutOrder = 99,
				Parent = inner,
			}, "subtexts")
		end
		if searchable and popup:FindFirstChildOfClass("TextBox") == nil then
			-- search created above, but ensure filtering hookup
		end
	end
	element._openList = openList

	-- search filtering hookup (the search box is recreated each open; attach while opening)
	local originalOpen = openList
	openList = function()
		originalOpen()
		local popup = State.activePopup and State.activePopup.frame
		if not popup then
			return
		end
		local search
		for _, obj in ipairs(popup:GetDescendants()) do
			if obj:IsA("TextBox") then
				search = obj
				break
			end
		end
		if search then
			local inner = popup:FindFirstChildOfClass("ScrollingFrame")
			inner = inner and inner:FindFirstChildOfClass("Frame")
			search:GetPropertyChangedSignal("Text"):Connect(function()
				local query = search.Text:lower()
				if not inner then
					return
				end
				for _, optionButton in ipairs(inner:GetChildren()) do
					if optionButton:IsA("TextButton") then
						local labelObj = optionButton:FindFirstChildOfClass("TextLabel")
						local text = labelObj and labelObj.Text:lower() or ""
						optionButton.Visible = query == "" or text:find(query, 1, true) ~= nil
					end
				end
			end)
		end
	end
	element._openList = openList

	selector.MouseEnter:Connect(function()
		Animate(selector, { BackgroundTransparency = 0.1 }, 0.15)
	end)
	selector.MouseLeave:Connect(function()
		Animate(selector, { BackgroundTransparency = 0.25 }, 0.15)
	end)
	selector.MouseButton1Click:Connect(function()
		if element.Disabled then
			return
		end
		Library:BlockSound()
		openList()
	end)

	element.SetValues = function(_, values)
		rebuildItems(values)
		refreshValue()
	end
	element._refreshTheme = function()
		selector.BackgroundColor3 = Library.Theme.Element
	end

	local default = opts.Default
	if default == nil then
		if element.Multi then
			default = {}
		else
			default = items[1] and items[1].key or nil
		end
	end
	if type(default) == "number" and items[default] then
		default = items[default].key
	elseif type(default) == "table" and element.Multi then
		local copy = {}
		for key, on in next, default do
			if on then
				copy[tostring(key)] = true
			end
		end
		default = copy
	elseif type(default) == "string" then
		if lookupKey[default] then
			default = lookupKey[default]
		end
	end
	apply(default, true)
	if opts.Callback then
		element:OnChanged(opts.Callback)
	end
	AttachTooltip(row, opts.Tooltip, opts.DisabledTooltip, element)
	if opts.Disabled then
		element:SetDisabled(true)
	end
	return element
end

--------------------------------------------------------------------------------
-- color picker
--------------------------------------------------------------------------------

local function BuildColorPanel(element, swatch, opts)
	local preview, hexBox, syncPanel

	local function openPanel()
		if State.activePopup and State.activePopup.anchor == swatch then
			ClosePopup()
			return
		end
		local hasTransparency = opts.Transparency ~= nil
		local height = 178 + (hasTransparency and 28 or 0)
		local panel = OpenPopup(swatch, height, 202)
		if not panel then
			return
		end
		Pad(10, 10, 10, 10, panel)
		preview = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = element.Value,
			BorderSizePixel = 0,
			Parent = panel,
		})
		Corner(6, preview)
		Track("strokes", Create("UIStroke", {
			Color = Library.Theme.Stroke,
			Transparency = 0.4,
			Parent = preview,
		}))
		hexBox = Create("TextBox", {
			Position = UDim2.fromOffset(0, 32),
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 0.15,
			Text = Hex(element.Value),
			TextSize = 11,
			TextColor3 = Library.Theme.Text,
			PlaceholderText = "#RRGGBB",
			PlaceholderColor3 = Library.Theme.SubText,
			ClearTextOnFocus = false,
			Parent = panel,
		})
		hexBox.Font = FONTS[Library.FontName] or Enum.Font.Gotham
		table.insert(Skin.fonts, hexBox)
		Track("texts", hexBox)
		Corner(6, hexBox)
		Pad(0, 6, 0, 6, hexBox)

		local sliders = {}
		local function setColor(color, silent)
			if typeof(color) ~= "Color3" then
				return
			end
			element.Value = color
			swatch.BackgroundColor3 = color
			if preview then
				preview.BackgroundColor3 = color
			end
			if silent then
				for _, slider in ipairs(sliders) do
					slider.SetEnabled(true)
				end
			end
			if hexBox and not hexBox:IsFocused() then
				hexBox.Text = Hex(color)
			end
			if not silent then
				element:_fire(color, false)
			end
		end
		element._syncPanel = function(color)
			swatch.BackgroundColor3 = color
			swatch.ImageColor3 = color
			if preview then
				preview.BackgroundColor3 = color
			end
			if hexBox and not hexBox:IsFocused() then
				hexBox.Text = Hex(color)
			end
			if sliders[1] then
				sliders[1].Set(color.R * 255, true)
				sliders[2].Set(color.G * 255, true)
				sliders[3].Set(color.B * 255, true)
			end
		end

		local function fromChannels(which)
			local r, g, b = element.Value.R * 255, element.Value.G * 255, element.Value.B * 255
			if which == "R" then
				r = sliders.rValue or r
			end
			return Color3.fromRGB(
				math.floor(which == "R" and (sliders.rValue or r) or r + 0.5),
				math.floor(which == "G" and (sliders.gValue or g) or g + 0.5),
				math.floor(which == "B" and (sliders.bValue or b) or b + 0.5)
			)
		end

		-- simple channel sliders
		local function channelSlider(order, labelText, channel, y)
			local row = Create("Frame", {
				Position = UDim2.fromOffset(0, y),
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = panel,
			})
			MakeText("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(16, 26),
				Text = labelText,
				TextSize = 10,
				TextColor3 = Library.Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			}, "subtexts")
			local valueLabel = MakeText("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(30, 26),
				Text = "0",
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Library.Theme.Text,
				Parent = row,
			}, "texts")
			local track = Create("Frame", {
				Position = UDim2.fromOffset(20, 11),
				Size = UDim2.new(1, -56, 0, 4),
				BackgroundColor3 = Library.Theme.Element,
				BorderSizePixel = 0,
				Parent = row,
			})
			Corner(2, track)
			Track("elements", track)
			local fill = Create("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Library.Config.Accent,
				BorderSizePixel = 0,
				Parent = track,
			})
			Corner(2, fill)
			Track("accents", fill)
			local knob = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(10, 10),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Parent = track,
			})
			Corner(5, knob)
			local state = { value = 0 }
			local function set(value, silent)
				state.value = math.clamp(tonumber(value) or 0, 0, 255)
				local ratio = state.value / 255
				fill.Size = UDim2.fromScale(ratio, 1)
				knob.Position = UDim2.fromScale(ratio, 0.5)
				valueLabel.Text = tostring(math.floor(state.value + 0.5))
				if not silent then
					element.suppressPanelSync = true
					local c = element.Value
					local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
					if channel == "R" then
						r = math.floor(state.value + 0.5)
					elseif channel == "G" then
						g = math.floor(state.value + 0.5)
					else
						b = math.floor(state.value + 0.5)
					end
					local newColor = Color3.fromRGB(r, g, b)
					element.Value = newColor
					swatch.BackgroundColor3 = newColor
					if preview then
						preview.BackgroundColor3 = newColor
					end
					if hexBox and not hexBox:IsFocused() then
						hexBox.Text = Hex(newColor)
					end
					element:_fire(newColor, false)
					element.suppressPanelSync = false
				end
			end
			AttachSliderDrag(track, function(relative)
				set(relative * 255, false)
			end)
			return { Set = set, state = state }
		end

		local rSlider = channelSlider(1, "R", "R", 62)
		local gSlider = channelSlider(2, "G", "G", 88)
		local bSlider = channelSlider(3, "B", "B", 114)
		table.insert(sliders, rSlider)
		table.insert(sliders, gSlider)
		table.insert(sliders, bSlider)
		rSlider.state.Set = rSlider.Set
		sliders[1].Set(element.Value.R * 255, true)
		sliders[2].Set(element.Value.G * 255, true)
		sliders[3].Set(element.Value.B * 255, true)

		local transparencySlider
		if hasTransparency then
			local transparent = Create("Frame", {
				Position = UDim2.fromOffset(0, 144),
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = panel,
			})
			local label = MakeText("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(60, 26),
				Text = "Opacity",
				TextSize = 10,
				TextColor3 = Library.Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = transparent,
			}, "subtexts")
			local track = Create("Frame", {
				Position = UDim2.fromOffset(64, 11),
				Size = UDim2.new(1, -100, 0, 4),
				BackgroundColor3 = Library.Theme.Element,
				BorderSizePixel = 0,
				Parent = transparent,
			})
			Corner(2, track)
			Track("elements", track)
			local fill = Create("Frame", {
				Size = UDim2.fromScale(1 - (element.Transparency or 0), 1),
				BackgroundColor3 = Library.Config.Accent,
				BorderSizePixel = 0,
				Parent = track,
			})
			Corner(2, fill)
			Track("accents", fill)
			local knob = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(1 - (element.Transparency or 0), 0.5),
				Size = UDim2.fromOffset(10, 10),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Parent = track,
			})
			Corner(5, knob)
			AttachSliderDrag(track, function(relative)
				element.Transparency = 1 - relative
				fill.Size = UDim2.fromScale(relative, 1)
				knob.Position = UDim2.fromScale(relative, 0.5)
				element:_fire(element.Value, false)
			end)
			transparencySlider = transparent
		end

		hexBox.FocusLost:Connect(function()
			local parsed = FromHex(hexBox.Text)
			if parsed then
				setColor(parsed, false)
				sliders[1].Set(parsed.R * 255, true)
				sliders[2].Set(parsed.G * 255, true)
				sliders[3].Set(parsed.B * 255, true)
			else
				hexBox.Text = Hex(element.Value)
			end
		end)
		element._syncPanel = function(color)
			swatch.BackgroundColor3 = color
			if preview then
				preview.BackgroundColor3 = color
			end
			if hexBox and not hexBox:IsFocused() then
				hexBox.Text = Hex(color)
			end
			sliders[1].Set(color.R * 255, true)
			sliders[2].Set(color.G * 255, true)
			sliders[3].Set(color.B * 255, true)
		end
	end

	swatch.MouseButton1Click:Connect(function()
		openPanel()
	end)
end

local function NewColorPicker(index, opts, swatch, row)
	opts = opts or {}
	local element = Element.new(index, "ColorPicker")
	element.Transparency = opts.Transparency
	element.Callback = opts.Callback
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	element.Value = color
	swatch.BackgroundColor3 = color
	swatch.BackgroundTransparency = 0
	local function apply(value, silent)
		if typeof(value) ~= "Color3" then
			return
		end
		element.Value = value
		swatch.BackgroundColor3 = value
		if element._syncPanel then
			element._syncPanel(value)
		end
		if not silent then
			element:_fire(value, false)
		end
	end
	element._set = apply
	-- Accept both `element:SetValueRGB(color)` and `element.SetValueRGB(color)`.
	element.SetValueRGB = function(a, b, c)
		if typeof(a) == "Color3" then
			return apply(a, b)
		end
		return apply(b, c)
	end
	BuildColorPanel(element, swatch, opts)
	if opts.Callback then
		element:OnChanged(opts.Callback)
	end
	AttachTooltip(row, opts.Tooltip)
	return element
end

Elements.ColorPicker = function(box, index, opts)
	opts = opts or {}
	local parent = ResolveBox(box)
	local row = Row(parent, 36)
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Text = tostring(opts.Title or opts.Text or index or "Color"),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.Text,
		Parent = row,
	}, "texts")
	local swatch = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = opts.Default or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(6, swatch)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.3,
		Parent = swatch,
	}))
	return NewColorPicker(index, opts, swatch, row)
end

Elements.AttachColorPicker = function(host, index, opts)
	opts = opts or {}
	if not host.Row then
		return Elements.ColorPicker(host.Box or host, index, opts)
	end
	local right = host.ReserveAttach and host.ReserveAttach(22) or 46
	local swatch = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -right, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = opts.Default or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = host.Row,
	})
	Corner(5, swatch)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.3,
		Parent = swatch,
	}))
	local element = NewColorPicker(index, opts, swatch, host.Row)
	-- keep chaining working: toggle:AddColorPicker(a):AddColorPicker(b)
	element.AddColorPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachColorPicker(host, pickerIndex, pickerOpts)
	end
	element.AddKeyPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachKeyPicker(host, pickerIndex, pickerOpts)
	end
	return element
end

--------------------------------------------------------------------------------
-- keybind picker
--------------------------------------------------------------------------------

local KEY_MODES = { "Toggle", "Hold", "Press", "Always" }

Elements.KeyPicker = function(box, index, opts)
	opts = opts or {}
	local parent = ResolveBox(box)
	local element = Element.new(index, "KeyPicker")
	element.Box = parent
	element.Key = opts.Default or "None"
	element.Mode = opts.Mode or "Toggle"
	element.State = false
	element.Callback = opts.Callback
	element.ChangedCallback = opts.ChangedCallback
	element.NoUI = opts.NoUI
	element.Text = tostring(opts.Text or index or "Keybind")

	local row = Row(parent, 36)
	element.Row = row
	local label = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -140, 1, 0),
		Text = element.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.Text,
		Parent = row,
	}, "texts")
	element.TextLabel = label

	local modeChip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -77, 0.5, 0),
		Size = UDim2.fromOffset(47, 23),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(6, modeChip)
	Track("elements", modeChip)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.55,
		Parent = modeChip,
	}))
	local modeLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = element.Mode,
		TextSize = 9,
		TextColor3 = Library.Theme.SubText,
		Parent = modeChip,
	}, "subtexts")

	local keyChip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -2, 0.5, 0),
		Size = UDim2.fromOffset(70, 23),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(6, keyChip)
	Track("elements", keyChip)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.55,
		Parent = keyChip,
	}))
	local keyLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = element.Key,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.Text,
		Parent = keyChip,
	}, "texts")

	local function refresh()
		keyLabel.Text = (element.Key and element.Key ~= "") and tostring(element.Key) or "None"
		modeLabel.Text = element.Mode
		if element._refreshRow then
			element._refreshRow()
		end
	end

	local function beginBind()
		if element.Disabled or State.bindingElement then
			return
		end
		State.bindingElement = element
		element._oldKey = element.Key
		keyLabel.Text = "press…"
		keyChip.BackgroundColor3 = Library.Config.Accent
		keyLabel.TextColor3 = Library.Theme.OnAccent
	end
	element._beginBind = beginBind

	element._finishBind = function(_, name)
		State.bindingElement = nil
		keyChip.BackgroundColor3 = Library.Theme.Element
		keyChip.BackgroundTransparency = 0.25
		keyLabel.TextColor3 = Library.Theme.Text
		if name then
			element.Key = name
			refresh()
			element:_fire(element.Key, false)
			if element.ChangedCallback then
				local ok, err = pcall(element.ChangedCallback, name, nil)
				if not ok then
					warn("[Chillui] keybind changed callback error:", err)
				end
			end
		else
			refresh()
		end
	end

	local function cycleMode()
		if element.Disabled then
			return
		end
		local position = 1
		for index, mode in ipairs(KEY_MODES) do
			if mode == element.Mode then
				position = index
				break
			end
		end
		element.Mode = KEY_MODES[(position % #KEY_MODES) + 1]
		refresh()
		element:_fire(element.Key, false)
		Library:BlockSound()
	end

	element._press = function()
		if element.Disabled then
			return
		end
		if element.Mode == "Toggle" then
			element.State = not element.State
			element:_fire(element.State, false)
			if element.State then
				element:_click()
			end
		elseif element.Mode == "Hold" then
			element.State = true
			element:_fire(true, false)
			element:_click()
		elseif element.Mode == "Press" then
			element:_fire(true, false)
			element:_click()
		elseif element.Mode == "Always" then
			element.State = true
		end
	end

	element._release = function()
		if element.Mode == "Hold" then
			element.State = false
			element:_fire(false, false)
		end
	end

	element.GetState = function()
		return element.State
	end

	element._set = function(value, silent)
		if type(value) == "table" then
			local key = value[1] or value.Key or value.key
			local mode = value[2] or value.Mode or value.mode
			if key then
				element.Key = tostring(key)
			end
			if mode then
				element.Mode = tostring(mode)
			end
		elseif type(value) == "string" then
			element.Key = value
		end
		element.State = false
		refresh()
		if not silent then
			element:_fire(element.Key, false)
		end
	end

	local function applyMode(mode)
		if mode and table.find(KEY_MODES, mode) then
			element.Mode = mode
			refresh()
		end
	end

	element.SetMode = function(_, mode)
		applyMode(mode)
	end

	keyChip.MouseButton1Click:Connect(function()
		Library:BlockSound()
		beginBind()
	end)
	modeChip.MouseButton1Click:Connect(cycleMode)
	keyChip.MouseEnter:Connect(function()
		Animate(keyChip, { BackgroundTransparency = 0.05 }, 0.12)
	end)
	keyChip.MouseLeave:Connect(function()
		Animate(keyChip, { BackgroundTransparency = 0.25 }, 0.12)
	end)
	AttachTooltip(row, opts.Tooltip)
	refresh()
	if opts.Callback then
		element:OnChanged(opts.Callback)
	end
	if opts.ChangedCallback then
		-- already stored
	end

	table.insert(Library.Keybinds, element)
	if Library._AddKeybindRow then
		Library._AddKeybindRow(element)
	end

	if opts.SyncToggleState then
		element.State = false
	end
	return element
end

Elements.AttachKeyPicker = function(host, index, opts)
	opts = opts or {}
	if not host.Row then
		return Elements.KeyPicker(host.Box or host, index, opts)
	end
	local right = host.ReserveAttach and host.ReserveAttach(74) or 46
	local chip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -right, 0.5, 0),
		Size = UDim2.fromOffset(68, 22),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = host.Row,
	})
	Corner(6, chip)
	Track("elements", chip)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.55,
		Parent = chip,
	}))
	local chipLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = tostring(opts.Default or "None"),
		TextSize = 9,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Library.Theme.Text,
		Parent = chip,
	}, "texts")

	local element = Element.new(index, "KeyPicker")
	element.Box = ResolveBox(host)
	element.Key = opts.Default or "None"
	element.Mode = opts.Mode or "Toggle"
	element.State = false
	element.Callback = opts.Callback
	element.ChangedCallback = opts.ChangedCallback
	element.NoUI = opts.NoUI
	element.Text = tostring(opts.Text or index or "Keybind")
	element.Row = host.Row

	local function refresh()
		chipLabel.Text = ((element.Key and element.Key ~= "") and tostring(element.Key) or "None")
			.. (element.Mode ~= "Toggle" and (" · " .. element.Mode) or "")
		if element._refreshRow then
			element._refreshRow()
		end
	end
	chip.MouseButton1Click:Connect(function()
		if element.Disabled or State.bindingElement then
			return
		end
		Library:BlockSound()
		State.bindingElement = element
		chipLabel.Text = "press…"
		chip.BackgroundColor3 = Library.Config.Accent
	end)
	element._finishBind = function(_, name)
		State.bindingElement = nil
		chip.BackgroundColor3 = Library.Theme.Element
		if name then
			element.Key = name
			element:_fire(element.Key, false)
			if element.ChangedCallback then
				pcall(element.ChangedCallback, name, nil)
			end
		end
		refresh()
	end
	element._press = function()
		element.State = not element.State
		element:_fire(element.State, false)
		if element.State then
			element:_click()
		end
	end
	element._release = function()
		element.State = false
	end
	element.GetState = function()
		return element.State
	end
	element._set = function(value, silent)
		if type(value) == "table" then
			element.Key = tostring(value[1] or value.Key or element.Key)
			element.Mode = tostring(value[2] or value.Mode or element.Mode)
		elseif type(value) == "string" then
			element.Key = value
		end
		refresh()
		if not silent then
			element:_fire(element.Key, false)
		end
	end
	element.SetMode = function(_, mode)
		if table.find(KEY_MODES, mode) then
			element.Mode = mode
			refresh()
		end
	end
	if opts.Callback then
		element:OnChanged(opts.Callback)
	end
	refresh()
	table.insert(Library.Keybinds, element)
	if Library._AddKeybindRow then
		Library._AddKeybindRow(element)
	end
	element.AddColorPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachColorPicker(host, pickerIndex, pickerOpts)
	end
	element.AddKeyPicker = function(_, pickerIndex, pickerOpts)
		return Elements.AttachKeyPicker(host, pickerIndex, pickerOpts)
	end
	return element
end

--------------------------------------------------------------------------------
-- key system box
--------------------------------------------------------------------------------

Elements.KeyBox = function(box, callback)
	local parent = ResolveBox(box)
	local row = Row(parent, 48)
	local frame = Create("Frame", {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, -72, 0, 30),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = row,
	})
	Corner(7, frame)
	Track("elements", frame)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.5,
		Parent = frame,
	}))
	local textBox = Create("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		PlaceholderText = "Enter key…",
		PlaceholderColor3 = Library.Theme.SubText,
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.Text,
		ClearTextOnFocus = false,
		Parent = frame,
	})
	textBox.Font = FONTS[Library.FontName] or Enum.Font.Gotham
	table.insert(Skin.fonts, textBox)
	Track("texts", textBox)
	Pad(0, 8, 0, 8, textBox)
	local submit = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 8),
		Size = UDim2.fromOffset(64, 30),
		BackgroundColor3 = Library.Config.Accent,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(7, submit)
	Track("accents", submit)
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "Submit",
		TextSize = 11,
		TextColor3 = Library.Theme.OnAccent,
		Parent = submit,
	}, "onAccents")
	local function fire()
		if callback then
			local ok, err = pcall(callback, textBox.Text, function()
				textBox.Text = ""
			end)
			if not ok then
				warn("[Chillui] keybox error:", err)
			end
		end
		Library:BlockSound()
	end
	submit.MouseButton1Click:Connect(fire)
	textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			fire()
		end
	end)
	return {
		Clear = function()
			textBox.Text = ""
		end,
		SetText = function(_, value)
			textBox.Text = tostring(value)
		end,
	}
end

--------------------------------------------------------------------------------
-- keybind frame
--------------------------------------------------------------------------------

CreateKeybindFrame = function(gui)
	local frame = Create("Frame", {
		Name = "ChilluiKeybindFrame",
		Size = UDim2.fromOffset(250, 236),
		Position = UDim2.fromOffset(26, 160),
		BackgroundColor3 = Library.Theme.Panel,
		BackgroundTransparency = IsLite() and 0 or 0.06,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	})
	Corner(10, frame)
	Track("panels", frame)
	Track("strokes", Create("UIStroke", {
		Color = Library.Theme.Stroke,
		Transparency = 0.2,
		Parent = frame,
	}))
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Text = "Keybinds",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Library.Theme.Text,
		Parent = header,
	}, "texts")
	local close = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Library.Theme.Element,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = header,
	})
	Corner(5, close)
	local closeLabel = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "×",
		TextSize = 12,
		TextColor3 = Library.Theme.SubText,
		Parent = close,
	}, "subtexts")
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Library.Config.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = frame,
	})
	Pad(0, 10, 10, 10, list)
	local inner = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = list,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = inner,
	})
	local empty = MakeText("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "No keybinds yet.\nAdd an element with :AddKeyPicker().",
		TextSize = 10,
		TextWrapped = true,
		TextColor3 = Library.Theme.SubText,
		LayoutOrder = 999,
		Parent = inner,
	}, "subtexts")

	local function addRow(keybind)
		empty.Visible = false
		local row = Create("Frame", {
			Name = "Bind_" .. tostring(keybind.Index),
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Library.Theme.Element,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = #inner:GetChildren(),
			Parent = inner,
		})
		Corner(6, row)
		local name = MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -100, 1, 0),
			Text = keybind.Text or keybind.Index,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Library.Theme.SubText,
			Parent = row,
		}, "subtexts")
		local chip = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(82, 20),
			BackgroundColor3 = Library.Theme.Window,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		Corner(5, chip)
		Track("strokes", Create("UIStroke", {
			Color = Library.Theme.Stroke,
			Transparency = 0.5,
			Parent = chip,
		}))
		local chipLabel = MakeText("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 9,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Library.Theme.Text,
			Parent = chip,
		}, "texts")
		keybind._refreshRow = function()
			chipLabel.Text = ((keybind.Key and keybind.Key ~= "") and tostring(keybind.Key) or "None")
				.. "  " .. (keybind.Mode or "Toggle")
		end
		keybind._refreshRow()
		chip.MouseButton1Click:Connect(function()
			if keybind._beginBind then
				keybind._beginBind()
			else
				State.bindingElement = keybind
				chipLabel.Text = "press…"
			end
		end)
	end

	Library._AddKeybindRow = addRow
	Library.KeybindFrame = frame
	Library.KeybindMenu = {
		SetVisibilityControl = function(_, value)
			frame.Visible = not not value
		end,
	}
	for _, keybind in ipairs(Library.Keybinds) do
		if keybind._refreshRow == nil then
			addRow(keybind)
		end
	end

	-- drag
	local dragging = false
	local dragStart, startPosition, dragConnection
	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		startPosition = frame.Position
		dragConnection = UIS.InputChanged:Connect(function(changed)
			if not dragging then
				return
			end
			if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local delta = Vector2.new(changed.Position.X, changed.Position.Y) - dragStart
			frame.Position = UDim2.fromOffset(
				math.clamp(startPosition.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - frame.AbsoluteSize.X),
				math.clamp(startPosition.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - frame.AbsoluteSize.Y)
			)
		end)
	end)
	local function endDrag()
		dragging = false
		if dragConnection then
			dragConnection:Disconnect()
			dragConnection = nil
		end
	end
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)
	return frame
end

--------------------------------------------------------------------------------
-- settings tab
--------------------------------------------------------------------------------

function Library:_SyncSettings()
	local refs = State.settingsElements
	if not refs then
		return
	end
	if refs.Font then
		refs.Font:SetValue(self.Config.Font, true)
	end
	if refs.Theme then
		refs.Theme:SetValue(self.ThemeName, true)
	end
	if refs.Accent then
		refs.Accent:SetValue(self.Config.Accent, true)
	end
	if refs.Radius then
		refs.Radius:SetValue(self.CornerRadius, true)
	end
	if refs.Backdrop then
		refs.Backdrop:SetValue(self.BackdropName, true)
	end
	if refs.Animations then
		refs.Animations:SetValue(self.Config.Animations, true)
	end
	if refs.Sounds then
		refs.Sounds:SetValue(self.Config.Sounds, true)
	end
	if refs.StartupSound then
		refs.StartupSound:SetValue(self.Config.StartupSound, true)
	end
	if refs.Cursor then
		refs.Cursor:SetValue(self.Config.CustomCursor, true)
	end
end

function Library:_RefreshElements()
	for _, element in next, Options do
		if element._refreshTheme then
			local ok, err = pcall(element._refreshTheme)
			if not ok then
				warn("[Chillui] theme refresh error:", err)
			end
		end
		if element.RiskyLabel then
			element.RiskyLabel.TextColor3 = Color3.fromRGB(235, 96, 92)
		end
	end
	local window = self.Window
	if window then
		for _, tab in next, window.Tabs do
			SelButton(tab.Button, window.Current == tab, tab.Icon, tab.Label)
		end
	end
	for _, box in ipairs(State.tabboxes) do
		for _, sub in ipairs(box.Tabs) do
			local active = sub.Box.Visible
			sub.Button.BackgroundColor3 = active and Library.Config.Accent or Library.Theme.Element
			sub.Button.BackgroundTransparency = active and 0.15 or 1
			sub.Label.TextColor3 = active and Library.Theme.OnAccent or Library.Theme.SubText
		end
	end
end

-- Capture the current window position/size so it can be restored next launch.
function Library:_RememberGeometry()
	if not State.root then
		return
	end
	local pos = State.targetPosition or State.root.Position
	local size = State.root.Size
	self.Config.Window = {
		X = pos.X.Offset,
		Y = pos.Y.Offset,
		W = size.X.Offset,
		H = size.Y.Offset,
	}
	self:_QueueSaveSettings()
end

function Library:_SaveSettings()
	if typeof(writefile) ~= "function" then
		return false
	end
	pcall(makefolder, LIB_FOLDER)
	local data = {
		Theme = self.ThemeName,
		Font = self.Config.Font,
		Accent = { R = self.Config.Accent.R, G = self.Config.Accent.G, B = self.Config.Accent.B },
		Backdrop = self.BackdropName,
		CornerRadius = self.CornerRadius,
		DPI = self.Config.DPI,
		Animations = self.Config.Animations,
		Sounds = self.Config.Sounds,
		StartupSound = self.Config.StartupSound,
		BackgroundImage = self.Config.BackgroundImage,
		BackgroundImageTransparency = self.Config.BackgroundImageTransparency,
		NotifySide = self.NotifySide,
		CustomCursor = self.Config.CustomCursor,
		MenuKey = self.Config.MenuKey,
		Window = self.Config.Window,
	}
	local ok = pcall(writefile, SETTINGS_FILE, HttpService:JSONEncode(data))
	return ok
end

function Library:_LoadSettings()
	if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
		return
	end
	if not isfile(SETTINGS_FILE) then
		return
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(SETTINGS_FILE))
	end)
	if not ok or type(decoded) ~= "table" then
		return
	end
	if decoded.Theme and THEME_MAP[decoded.Theme] then
		self.ThemeName = decoded.Theme
		self.Theme = THEME_MAP[decoded.Theme]
	else
		self.Theme = THEME_MAP["Crimson Brown"]
		self.ThemeName = "Crimson Brown"
	end
	if decoded.Accent and decoded.Accent.R and decoded.Accent.G and decoded.Accent.B then
		self.Config.Accent = Color3.new(decoded.Accent.R, decoded.Accent.G, decoded.Accent.B)
	else
		self.Config.Accent = self.Theme.Accent
	end
	if decoded.Font and FONTS[decoded.Font] then
		self.FontName = decoded.Font
		self.Config.Font = decoded.Font
	end
	if decoded.Backdrop then
		for _, name in ipairs(self.Backdrops) do
			if name:lower() == tostring(decoded.Backdrop):lower() then
				self.BackdropName = name
				self.Config.Backdrop = name
				break
			end
		end
	end
	if decoded.CornerRadius then
		self.CornerRadius = math.clamp(tonumber(decoded.CornerRadius) or 12, 0, 24)
		self.Config.CornerRadius = self.CornerRadius
	end
	if decoded.DPI then
		self.Config.DPI = math.clamp(tonumber(decoded.DPI) or 100, 50, 200)
	end
	if decoded.Animations ~= nil then
		self.Config.Animations = not not decoded.Animations
	end
	if decoded.Sounds ~= nil then
		self.Config.Sounds = not not decoded.Sounds
	end
	if decoded.StartupSound then
		self.Config.StartupSound = decoded.StartupSound
	end
	if decoded.BackgroundImage then
		self.Config.BackgroundImage = decoded.BackgroundImage
	end
	if decoded.BackgroundImageTransparency then
		self.Config.BackgroundImageTransparency = math.clamp(tonumber(decoded.BackgroundImageTransparency) or 0.25, 0, 0.95)
	end
	if decoded.NotifySide then
		self.NotifySide = decoded.NotifySide == "Right" and "Right" or "Left"
		self.Config.NotifySide = self.NotifySide
	end
	if decoded.CustomCursor ~= nil then
		self.Config.CustomCursor = not not decoded.CustomCursor
	end
	if decoded.MenuKey then
		self.Config.MenuKey = decoded.MenuKey
	end
	if type(decoded.Window) == "table" then
		self.Config.Window = {
			X = tonumber(decoded.Window.X),
			Y = tonumber(decoded.Window.Y),
			W = tonumber(decoded.Window.W),
			H = tonumber(decoded.Window.H),
		}
	end
end

local saveQueued = false

function Library:_QueueSaveSettings()
	if saveQueued then
		return
	end
	saveQueued = true
	task.delay(1.2, function()
		saveQueued = false
		Library:_SaveSettings()
	end)
end

function Library:SaveSettings()
	return self:_SaveSettings()
end

--------------------------------------------------------------------------------
-- configs
--------------------------------------------------------------------------------

local function SanitizeName(name)
	return tostring(name or ""):gsub("[^%w _%-%.]", "")
end

function Library:ListConfigs()
	local out = {}
	if typeof(listfiles) ~= "function" or typeof(isfile) ~= "function" then
		return out
	end
	if typeof(isfolder) ~= "function" or not isfolder(CONFIG_FOLDER) then
		return out
	end
	local ok, files = pcall(listfiles, CONFIG_FOLDER)
	if not ok or type(files) ~= "table" then
		return out
	end
	for _, path in ipairs(files) do
		local name = tostring(path):match("([^/\\]+)%.json$")
		if name then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

function Library:SaveConfig(name)
	name = SanitizeName(name)
	if name == "" then
		self:Notify({ Title = "Config", Description = "Enter a config name first." })
		return false
	end
	if typeof(writefile) ~= "function" then
		self:Notify({ Title = "Config", Description = "writefile is not available in this executor." })
		return false
	end
	pcall(makefolder, LIB_FOLDER)
	pcall(makefolder, CONFIG_FOLDER)
	local data = {
		Library = "Chillui",
		Version = self.Version,
		Theme = self.ThemeName,
		Font = self.Config.Font,
		Backdrop = self.BackdropName,
		Accent = { R = self.Config.Accent.R, G = self.Config.Accent.G, B = self.Config.Accent.B },
		Options = {},
	}
	for index, element in next, Options do
		local kind = element.Type
		if kind == "Toggle" or kind == "Checkbox" then
			data.Options[index] = not not element.Value
		elseif kind == "Slider" then
			data.Options[index] = tonumber(element.Value) or 0
		elseif kind == "Input" then
			data.Options[index] = tostring(element.Value or "")
		elseif kind == "Dropdown" then
			if element.Multi then
				local copy = {}
				for key, on in next, element.Value or {} do
					copy[key] = not not on
				end
				data.Options[index] = copy
			else
				data.Options[index] = element.Value
			end
		elseif kind == "ColorPicker" then
			data.Options[index] = {
				R = element.Value.R,
				G = element.Value.G,
				B = element.Value.B,
				Transparency = element.Transparency,
			}
		elseif kind == "KeyPicker" then
			data.Options[index] = { Key = element.Key, Mode = element.Mode }
		end
	end
	local ok = pcall(writefile, CONFIG_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
	if ok then
		self:Notify({ Title = "Config saved", Description = "Saved \"" .. name .. "\"." })
		if State.configDropdown then
			State.configDropdown:SetValues(self:ListConfigs())
		end
	else
		self:Notify({ Title = "Config", Description = "Could not write the config file." })
	end
	return ok
end

function Library:LoadConfig(name)
	name = SanitizeName(name)
	if typeof(readfile) ~= "function" then
		return false
	end
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	if typeof(isfile) == "function" and not isfile(path) then
		self:Notify({ Title = "Config", Description = "No config named \"" .. name .. "\"." })
		return false
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(decoded) ~= "table" then
		self:Notify({ Title = "Config", Description = "That config file is invalid." })
		return false
	end
	if decoded.Theme and THEME_MAP[decoded.Theme] then
		self:SetTheme(decoded.Theme)
	end
	if decoded.Font and FONTS[decoded.Font] then
		self:SetFont(decoded.Font)
	end
	if decoded.Accent then
		self:SetAccent(Color3.new(decoded.Accent.R or 1, decoded.Accent.G or 1, decoded.Accent.B or 1))
	end
	if decoded.Backdrop then
		self:SetBackdrop(decoded.Backdrop)
	end
	for index, value in next, decoded.Options or {} do
		local element = Options[index]
		if element then
			if element.Type == "ColorPicker" and type(value) == "table" then
				element:SetValue(Color3.new(value.R or 1, value.G or 1, value.B or 1), true)
				if value.Transparency ~= nil then
					element.Transparency = value.Transparency
				end
				element:SetValue(Color3.new(value.R or 1, value.G or 1, value.B or 1), false)
			elseif element.Type == "KeyPicker" and type(value) == "table" then
				element:SetValue({ value.Key, value.Mode }, false)
			else
				element:SetValue(value, false)
			end
		end
	end
	self:Notify({ Title = "Config loaded", Description = "Loaded \"" .. name .. "\"." })
	return true
end

function Library:DeleteConfig(name)
	name = SanitizeName(name)
	if typeof(delfile) ~= "function" then
		return false
	end
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	local ok = pcall(delfile, path)
	if ok then
		self:Notify({ Title = "Config deleted", Description = "Removed \"" .. name .. "\"." })
		if State.configDropdown then
			State.configDropdown:SetValues(self:ListConfigs())
		end
	end
	return ok
end

function Library:BuildSettings(tab)
	if not tab then
		return
	end
	local refs = State.settingsElements

	local appearance = tab:AddGroupbox({ Name = "Appearance", IconName = "palette", Side = "Left" })
	refs.Font = appearance:AddDropdown("UI_Font", {
		Values = self.Fonts,
		Default = self.Config.Font,
		Text = "Font",
		Searchable = true,
		Tooltip = "Changes the font of the whole interface.",
		Callback = function(value)
			self:SetFont(value)
		end,
	})
	refs.Theme = appearance:AddDropdown("UI_Theme", {
		Values = self.Themes,
		Default = self.ThemeName,
		Text = "Theme",
		Searchable = true,
		Tooltip = "Preset color palettes. Accent can be changed separately.",
		Callback = function(value)
			self:SetTheme(value)
		end,
	})
	refs.Accent = appearance:AddColorPicker("UI_Accent", {
		Default = self.Config.Accent,
		Title = "Accent color",
		Tooltip = "Accent used by buttons, sliders and highlights.",
		Callback = function(value)
			self:SetAccent(value)
		end,
	})
	refs.Radius = appearance:AddSlider("UI_Radius", {
		Text = "Corner radius",
		Min = 0,
		Max = 24,
		Default = self.CornerRadius,
		Rounding = 0,
		Tooltip = "Rounds the window corners.",
		Callback = function(value)
			self:SetCornerRadius(value)
		end,
	})
	if not IsLite() then
		refs.Backdrop = appearance:AddDropdown("UI_Backdrop", {
			Values = self.Backdrops,
			Default = self.BackdropName,
			Text = "Backdrop",
			Tooltip = "Solid, Semi, Glass, Acrylic, Mica, Vibrant, Blur or Image.",
			Callback = function(value)
				self:SetBackdrop(value)
			end,
		})
		appearance:AddLabel("Glass, Acrylic and Mica use a blur effect behind the window.", { DoesWrap = true })
		local imageInput = appearance:AddInput("UI_BgImage", {
			Text = "Background image",
			Default = self.Config.BackgroundImage,
			Placeholder = "C:\\pictures\\wallpaper.jpg or rbxassetid://",
			Finished = true,
			Tooltip = "jpg, jpeg, png, bmp and tga are converted by your executor.",
		})
		appearance:AddButton({
			Text = "Apply background image",
			Icon = "image",
			Func = function()
				if self:SetBackgroundImage(imageInput.Value) then
					self:Notify({ Title = "Background set", Description = "Image applied to the window." })
				end
			end,
		})
		appearance:AddSlider("UI_BgTransparency", {
			Text = "Image transparency",
			Min = 0,
			Max = 90,
			Default = math.floor((self.Config.BackgroundImageTransparency or 0.25) * 100),
			Rounding = 0,
			Suffix = "%",
			Callback = function(value)
				self.Config.BackgroundImageTransparency = value / 100
				if State.bg.image then
					State.bg.image.ImageTransparency = self.Config.BackgroundImageTransparency
				end
				if self.BackdropName == "Image" then
					ApplyBackdrop()
				end
			end,
		})
		appearance:AddButton({
			Text = "Clear background image",
			Func = function()
				self.Config.BackgroundImage = ""
				if State.bg.image then
					State.bg.image.Image = ""
				end
				self:SetBackdrop("Solid")
			end,
		})
	end
	refs.Animations = appearance:AddToggle("UI_Animations", {
		Text = "Animations",
		Default = self.Config.Animations,
		Tooltip = "Tweens for toggles, sliders and the window.",
		Callback = function(value)
			self.Config.Animations = value
		end,
	})
	refs.Sounds = appearance:AddToggle("UI_Sounds", {
		Text = "Interface sounds",
		Default = self.Config.Sounds,
		Callback = function(value)
			self.Config.Sounds = value
		end,
	})
	refs.StartupSound = appearance:AddDropdown("UI_StartupSound", {
		Values = SOUND_LIST,
		Default = self.Config.StartupSound,
		Text = "Startup sound",
		Callback = function(value)
			self.Config.StartupSound = value
		end,
	})
	if not IsLite() then
		refs.Cursor = appearance:AddToggle("UI_CustomCursor", {
			Text = "Custom cursor",
			Default = self.Config.CustomCursor,
			Callback = function(value)
				self:SetCustomCursor(value)
			end,
		})
	else
		appearance:AddLabel("Lite mode: heavy visuals and background images are disabled.", { DoesWrap = true })
	end

	local behavior = tab:AddGroupbox({ Name = "Menu", IconName = "settings", Side = "Right" })
	behavior:AddKeyPicker("MenuKeybind", {
		Default = self.Config.MenuKey or "RightShift",
		Mode = "Press",
		Text = "Menu keybind",
		NoUI = true,
		ChangedCallback = function(key)
			self.Config.MenuKey = key
		end,
	})
	self.ToggleKeybind = Options.MenuKeybind
	behavior:AddToggle("UI_KeybindMenu", {
		Text = "Keybind menu",
		Default = false,
		Callback = function(value)
			if self.KeybindFrame then
				self.KeybindFrame.Visible = value
			end
		end,
	})
	behavior:AddDropdown("UI_NotifySide", {
		Values = { "Left", "Right" },
		Default = self.NotifySide,
		Text = "Notification side",
		Callback = function(value)
			self:SetNotifySide(value)
		end,
	})
	behavior:AddDropdown("UI_DPI", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = tostring(self.Config.DPI) .. "%",
		Text = "DPI scale",
		Callback = function(value)
			self:SetDPIScale((value:gsub("%%", "")))
		end,
	})
	behavior:AddDivider()
	behavior:AddButton({
		Text = "Unload Chillui",
		Risky = true,
		Func = function()
			self:Unload()
		end,
	})

	local configBox = tab:AddGroupbox({ Name = "Configs", IconName = "folder", Side = "Right" })
	local nameInput = configBox:AddInput("UI_ConfigName", {
		Text = "Config name",
		Default = "default",
		Placeholder = "my-config",
	})
	State.configDropdown = configBox:AddDropdown("UI_ConfigList", {
		Values = self:ListConfigs(),
		Default = 1,
		Text = "Saved configs",
		Tooltip = "Pick a config, then load or delete it.",
	})
	configBox:AddButton({
		Text = "Save config",
		Func = function()
			self:SaveConfig(nameInput.Value)
		end,
	})
	configBox:AddButton({
		Text = "Load config",
		Func = function()
			local chosen = State.configDropdown.Value
			if chosen and chosen ~= "" then
				self:LoadConfig(chosen)
			end
		end,
	})
	configBox:AddButton({
		Text = "Delete config",
		Risky = true,
		Func = function()
			local chosen = State.configDropdown.Value
			if chosen and chosen ~= "" then
				self:DeleteConfig(chosen)
			end
		end,
	})
	configBox:AddButton({
		Text = "Refresh list",
		Func = function()
			State.configDropdown:SetValues(self:ListConfigs())
		end,
	})
	configBox:AddLabel("UI choices (font, theme, backdrop…) are saved in configs too.", { DoesWrap = true })
end

--------------------------------------------------------------------------------
-- unload
--------------------------------------------------------------------------------

function Library:OnUnload(fn)
	if type(fn) == "function" then
		table.insert(self.UnloadCallbacks, fn)
	end
	return self
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	self:_SaveSettings()
	for _, fn in ipairs(self.UnloadCallbacks) do
		pcall(fn)
	end
	for _, connection in ipairs(State.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(State.connections)
	if typeof(writefile) == "function" then
		pcall(function()
			Library:_SaveSettings()
		end)
	end
	if State.cursor then
		State.cursor:Destroy()
		State.cursor = nil
	end
	UIS.MouseIconEnabled = State.oldMouseIcon ~= false
	-- Chillui never creates a Lighting BlurEffect (backdrops are UI-only), so
	-- there is nothing to clean up in Lighting here.
	if tooltip then
		tooltip:Destroy()
		tooltip = nil
	end
	if State.gui then
		State.gui:Destroy()
	end
	if State.splashGui then
		State.splashGui:Destroy()
	end
	State.gui = nil
	State.root = nil
	State.splashGui = nil
	self.Window = nil
	self.Unloaded = true
end

ENV.Chillui = Library
_G.Chillui = Library

return Library



