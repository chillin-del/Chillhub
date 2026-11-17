--[[
	ChillUI v2.0.0  –  github.com/chillin-del/Chillhub
	Completely rewritten for reliability.
	
	Usage:
		local ChillUI = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/chillin-del/Chillhub/refs/heads/main/ChillHubUI.lua"
		))()
		local Window = ChillUI:CreateWindow({ Title = "My Script", Version = "1.0" })
		local Tabs = { Main = Window:AddTab("Main") }
		local GB   = Tabs.Main:AddGroupbox({ Name = "Controls" })
		GB:AddToggle("MyToggle", { Text = "Toggle me", Default = false, Callback = function(v) print(v) end })
]]

-- ─────────────────────────────────────────────
--  Services
-- ─────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
--  Library table
-- ─────────────────────────────────────────────
local ChillUI = {}
ChillUI.Options          = {}
ChillUI.Toggles          = {}
ChillUI.Unloaded         = false
ChillUI.LiteMode         = false
ChillUI.CurrentTheme     = "Crimson Brown"
ChillUI.CurrentFont      = "Gotham"
ChillUI.CurrentBackdrop  = "Solid"
ChillUI._unloadFns       = {}
ChillUI._connections     = {}

-- ─────────────────────────────────────────────
--  Themes
-- ─────────────────────────────────────────────
ChillUI.Themes = {
	["Crimson Brown"] = {
		Primary     = Color3.fromRGB(28,  10,  10),
		Secondary   = Color3.fromRGB(45,  16,  16),
		Accent      = Color3.fromRGB(197, 71,  71),
		AccentLight = Color3.fromRGB(232, 146, 106),
		Text        = Color3.fromRGB(240, 220, 210),
		TextDim     = Color3.fromRGB(150, 110, 100),
		Border      = Color3.fromRGB(80,  30,  30),
		ScrollBar   = Color3.fromRGB(197, 71,  71),
	},
	["Midnight Blue"] = {
		Primary     = Color3.fromRGB(10,  13,  30),
		Secondary   = Color3.fromRGB(18,  24,  52),
		Accent      = Color3.fromRGB(80,  120, 240),
		AccentLight = Color3.fromRGB(130, 170, 255),
		Text        = Color3.fromRGB(210, 220, 250),
		TextDim     = Color3.fromRGB(110, 130, 175),
		Border      = Color3.fromRGB(38,  52,  105),
		ScrollBar   = Color3.fromRGB(80,  120, 240),
	},
	["Forest Green"] = {
		Primary     = Color3.fromRGB(8,   22,  14),
		Secondary   = Color3.fromRGB(15,  40,  24),
		Accent      = Color3.fromRGB(50,  185, 100),
		AccentLight = Color3.fromRGB(100, 220, 150),
		Text        = Color3.fromRGB(200, 240, 215),
		TextDim     = Color3.fromRGB(100, 155, 120),
		Border      = Color3.fromRGB(30,  85,  50),
		ScrollBar   = Color3.fromRGB(50,  185, 100),
	},
	["Rose Gold"] = {
		Primary     = Color3.fromRGB(35,  20,  25),
		Secondary   = Color3.fromRGB(55,  32,  40),
		Accent      = Color3.fromRGB(210, 130, 150),
		AccentLight = Color3.fromRGB(240, 175, 190),
		Text        = Color3.fromRGB(245, 225, 230),
		TextDim     = Color3.fromRGB(155, 120, 132),
		Border      = Color3.fromRGB(95,  55,  70),
		ScrollBar   = Color3.fromRGB(210, 130, 150),
	},
	["Obsidian"] = {
		Primary     = Color3.fromRGB(12,  12,  16),
		Secondary   = Color3.fromRGB(20,  20,  26),
		Accent      = Color3.fromRGB(140, 100, 240),
		AccentLight = Color3.fromRGB(185, 155, 255),
		Text        = Color3.fromRGB(225, 220, 240),
		TextDim     = Color3.fromRGB(125, 120, 155),
		Border      = Color3.fromRGB(50,  45,  75),
		ScrollBar   = Color3.fromRGB(140, 100, 240),
	},
	["Arctic White"] = {
		Primary     = Color3.fromRGB(238, 242, 250),
		Secondary   = Color3.fromRGB(220, 227, 242),
		Accent      = Color3.fromRGB(60,  110, 220),
		AccentLight = Color3.fromRGB(100, 150, 240),
		Text        = Color3.fromRGB(28,  33,  58),
		TextDim     = Color3.fromRGB(95,  108, 148),
		Border      = Color3.fromRGB(185, 198, 225),
		ScrollBar   = Color3.fromRGB(60,  110, 220),
	},
}

ChillUI.FontMap = {
	["Gotham"]      = Enum.Font.Gotham,
	["GothamBold"]  = Enum.Font.GothamBold,
	["GothamBlack"] = Enum.Font.GothamBlack,
	["SourceSans"]  = Enum.Font.SourceSans,
	["Nunito"]      = Enum.Font.Nunito,
	["Code"]        = Enum.Font.Code,
	["Roboto"]      = Enum.Font.Ubuntu,
}

ChillUI.StartupSounds = {
	["None"]       = nil,
	["Chime"]      = "rbxassetid://6895079079",
	["Soft Click"] = "rbxassetid://6042053214",
	["Whoosh"]     = "rbxassetid://5862022429",
	["Crystal"]    = "rbxassetid://5107125922",
}

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function T()   return ChillUI.Themes[ChillUI.CurrentTheme] end
local function FONT() return ChillUI.FontMap[ChillUI.CurrentFont] or Enum.Font.Gotham end

local function tw(obj, props, t, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir   = dir   or Enum.EasingDirection.Out
	local ok, tw2 = pcall(TweenService.Create, TweenService, obj, TweenInfo.new(t or 0.18, style, dir), props)
	if ok then tw2:Play() end
end

local function safeParent(sg)
	-- protect_gui support for executors that have it
	local ok, _ = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(sg) end
	end)
	sg.Parent = PlayerGui
end

local function newGui(name)
	local sg = Instance.new("ScreenGui")
	sg.Name                = name
	sg.ResetOnSpawnEnabled = false
	sg.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder        = 1000
	sg.IgnoreGuiInset      = true
	safeParent(sg)
	return sg
end

local function newFrame(parent, size, pos, color, alpha, radius, strokeColor)
	local f = Instance.new("Frame")
	f.Size                   = size  or UDim2.new(1,0,1,0)
	f.Position               = pos   or UDim2.new(0,0,0,0)
	f.BackgroundColor3       = color or Color3.new(0,0,0)
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel        = 0
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = f
	end
	if strokeColor then
		local s = Instance.new("UIStroke")
		s.Color       = strokeColor
		s.Transparency = 0.55
		s.Thickness   = 1
		s.Parent = f
	end
	f.Parent = parent
	return f
end

local function newLabel(parent, text, sz, color, font, pos, size, xa, ya)
	local l = Instance.new("TextLabel")
	l.Text                   = text  or ""
	l.TextSize               = sz    or 13
	l.TextColor3             = color or Color3.new(1,1,1)
	l.Font                   = font  or Enum.Font.Gotham
	l.BackgroundTransparency = 1
	l.BorderSizePixel        = 0
	l.TextWrapped            = true
	l.RichText               = false
	l.Position               = pos  or UDim2.new(0,0,0,0)
	l.Size                   = size or UDim2.new(1,0,0,sz and sz+6 or 20)
	l.TextXAlignment         = xa   or Enum.TextXAlignment.Left
	l.TextYAlignment         = ya   or Enum.TextYAlignment.Center
	l.Parent = parent
	return l
end

local function newBtn(parent, text, sz, textColor, bgColor, radius)
	local b = Instance.new("TextButton")
	b.Text                   = text     or ""
	b.TextSize               = sz       or 13
	b.TextColor3             = textColor or Color3.new(1,1,1)
	b.Font                   = Enum.Font.GothamBold
	b.BackgroundColor3       = bgColor  or Color3.fromRGB(60,60,60)
	b.BackgroundTransparency = 0
	b.BorderSizePixel        = 0
	b.AutoButtonColor        = false
	if radius then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = b
	end
	b.Parent = parent
	return b
end

local function listLayout(parent, padding, dir, ha, va)
	local l = Instance.new("UIListLayout")
	l.Padding               = UDim.new(0, padding or 4)
	l.FillDirection         = dir or Enum.FillDirection.Vertical
	l.HorizontalAlignment   = ha  or Enum.HorizontalAlignment.Left
	l.VerticalAlignment     = va  or Enum.VerticalAlignment.Top
	l.SortOrder             = Enum.SortOrder.LayoutOrder
	l.Parent                = parent
	return l
end

local function padding(parent, top, bottom, left, right)
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, top    or 0)
	p.PaddingBottom = UDim.new(0, bottom or 0)
	p.PaddingLeft   = UDim.new(0, left   or 0)
	p.PaddingRight  = UDim.new(0, right  or 0)
	p.Parent = parent
	return p
end

-- ─────────────────────────────────────────────
--  Dragging
-- ─────────────────────────────────────────────
local function makeDraggable(handle, win)
	local dragging, dragStart, startPos = false, nil, nil
	local conn1 = handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or
		   inp.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = inp.Position
			startPos  = win.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	local conn2 = UserInputService.InputChanged:Connect(function(inp)
		if not dragging then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or
		   inp.UserInputType == Enum.UserInputType.Touch then
			local d  = inp.Position - dragStart
			local vp = workspace.CurrentCamera.ViewportSize
			local nx = math.clamp(startPos.X.Offset + d.X, 0, vp.X - win.AbsoluteSize.X)
			local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - win.AbsoluteSize.Y)
			win.Position = UDim2.new(0, nx, 0, ny)
		end
	end)
	local conn3 = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or
		   inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	table.insert(ChillUI._connections, conn1)
	table.insert(ChillUI._connections, conn2)
	table.insert(ChillUI._connections, conn3)
end

-- ─────────────────────────────────────────────
--  Startup screen
-- ─────────────────────────────────────────────
local function showStartup(config, onDone)
	local sg   = newGui("ChillUI_Startup")
	local root = newFrame(sg, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0), 0.45)

	local card = newFrame(root,
		UDim2.new(0, 440, 0, 290),
		UDim2.new(0.5, -220, 0.5, -175),   -- starts above centre
		Color3.fromRGB(22, 8, 8), 0, 16, Color3.fromRGB(100, 38, 38))

	-- top colour bar
	local bar = newFrame(card, UDim2.new(1,0,0,3), nil, Color3.fromRGB(197,71,71), 0, 0)
	local bg2 = Instance.new("UIGradient")
	bg2.Color  = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220,80,45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160,38,75)),
	})
	bg2.Parent = bar

	newLabel(card, "❄  " .. (config.Title or "ChillUI"), 24,
		Color3.fromRGB(240, 200, 185), Enum.Font.GothamBold,
		UDim2.new(0,0,0,16), UDim2.new(1,0,0,36),
		Enum.TextXAlignment.Center)

	newLabel(card, "v" .. (config.Version or "1.0") .. "  ·  choose a mode",
		11, Color3.fromRGB(140, 95, 85), Enum.Font.Gotham,
		UDim2.new(0,0,0,50), UDim2.new(1,0,0,16),
		Enum.TextXAlignment.Center)

	-- divider
	newFrame(card, UDim2.new(0,360,0,1), UDim2.new(0.5,-180,0,74),
		Color3.fromRGB(90,35,35), 0.4)

	-- mode buttons
	local function modeCard(xOff, bgCol, strokeCol, icon, title, sub)
		local mc = newFrame(card,
			UDim2.new(0, 185, 0, 110),
			UDim2.new(0, xOff, 0, 84),
			bgCol, 0, 10, strokeCol)
		newLabel(mc, icon,  20, Color3.fromRGB(220,160,120), Enum.Font.GothamBold,
			UDim2.new(0,0,0,10), UDim2.new(1,0,0,26), Enum.TextXAlignment.Center)
		newLabel(mc, title, 14, Color3.fromRGB(235,205,195), Enum.Font.GothamBold,
			UDim2.new(0,8,0,38), UDim2.new(1,-16,0,20), Enum.TextXAlignment.Center)
		newLabel(mc, sub,   11, Color3.fromRGB(145,105,96), Enum.Font.Gotham,
			UDim2.new(0,8,0,60), UDim2.new(1,-16,0,46), Enum.TextXAlignment.Center)
		return mc
	end

	local normalCard = modeCard(20,
		Color3.fromRGB(48,16,16), Color3.fromRGB(197,71,71),
		"✦", "Normal", "Full features\nThemes · Backdrops · FX")
	local liteCard   = modeCard(230,
		Color3.fromRGB(28,22,22), Color3.fromRGB(85,68,68),
		"⚡", "Lite",   "Lightweight\nFaster · Less memory")

	-- sound selector
	local soundNames = {}
	for k in pairs(ChillUI.StartupSounds) do table.insert(soundNames, k) end
	table.sort(soundNames)
	local soundIdx  = 1
	local soundLbl  = newLabel(card, soundNames[soundIdx], 11,
		Color3.fromRGB(220,155,115), Enum.Font.GothamBold,
		UDim2.new(0, 155, 0, 206), UDim2.new(0, 95, 0, 16),
		Enum.TextXAlignment.Center)
	newLabel(card, "Sound:", 11, Color3.fromRGB(130,95,85), Enum.Font.Gotham,
		UDim2.new(0, 20, 0, 206), UDim2.new(0, 65, 0, 16))

	local function mkArrow(x, txt, fn)
		local b = newBtn(card, txt, 11, Color3.fromRGB(200,155,125),
			Color3.fromRGB(50,18,18), 4)
		b.Size     = UDim2.new(0, 20, 0, 16)
		b.Position = UDim2.new(0, x, 0, 206)
		b.MouseButton1Click:Connect(fn)
		return b
	end
	mkArrow(130, "◀", function()
		soundIdx = soundIdx == 1 and #soundNames or soundIdx - 1
		soundLbl.Text = soundNames[soundIdx]
	end)
	mkArrow(255, "▶", function()
		soundIdx = soundIdx == #soundNames and 1 or soundIdx + 1
		soundLbl.Text = soundNames[soundIdx]
	end)

	newLabel(card, "click a mode to continue", 10,
		Color3.fromRGB(95,65,60), Enum.Font.Gotham,
		UDim2.new(0,0,1,-20), UDim2.new(1,0,0,16), Enum.TextXAlignment.Center)

	-- animate in
	root.BackgroundTransparency = 1
	card.BackgroundTransparency = 1
	card.Position = UDim2.new(0.5,-220,0.5,-185)
	tw(root, {BackgroundTransparency = 0.45}, 0.3)
	tw(card, {BackgroundTransparency = 0, Position = UDim2.new(0.5,-220,0.5,-155)},
		0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- hover effects
	local function hover(mc, on, base)
		tw(mc, {BackgroundColor3 = on
			and Color3.fromRGB(65, 22, 22)
			or  base}, 0.14)
	end
	normalCard.MouseEnter:Connect(function() hover(normalCard, true,  Color3.fromRGB(48,16,16)) end)
	normalCard.MouseLeave:Connect(function() hover(normalCard, false, Color3.fromRGB(48,16,16)) end)
	liteCard.MouseEnter:Connect(function()   hover(liteCard,   true,  Color3.fromRGB(28,22,22)) end)
	liteCard.MouseLeave:Connect(function()   hover(liteCard,   false, Color3.fromRGB(28,22,22)) end)

	local function pick(lite)
		-- play sound
		local sndId = ChillUI.StartupSounds[soundNames[soundIdx]]
		if sndId then
			local snd = Instance.new("Sound")
			snd.SoundId = sndId
			snd.Volume  = 0.5
			snd.Parent  = sg
			snd:Play()
		end
		tw(card, {BackgroundTransparency = 1,
			Position = UDim2.new(0.5,-220,0.5,-175)}, 0.28)
		tw(root, {BackgroundTransparency = 1}, 0.35)
		task.delay(0.4, function()
			sg:Destroy()
			onDone(lite)
		end)
	end

	normalCard.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then pick(false) end
	end)
	liteCard.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then pick(true) end
	end)
end

-- ─────────────────────────────────────────────
--  Element builders (all return the groupbox so they can be chained)
-- ─────────────────────────────────────────────
local function buildToggle(content, idx, opts)
	opts = opts or {}
	local theme = T()
	local state = opts.Default == true
	ChillUI.Toggles[idx] = {
		Value      = state,
		_cbs       = {},
		SetValue   = function(self, v, silent)
			state = v
			self.Value = v
			tw(self._track, {BackgroundColor3 = v and theme.Accent or theme.Secondary}, 0.18)
			tw(self._thumb, {Position = v
				and UDim2.new(0,20,0.5,-8)
				or  UDim2.new(0,2,0.5,-8)}, 0.18, Enum.EasingStyle.Back)
			if not silent then
				if opts.Callback then pcall(opts.Callback, v) end
				for _, cb in ipairs(self._cbs) do pcall(cb, v) end
			end
		end,
		OnChanged  = function(self, cb) table.insert(self._cbs, cb) end,
	}

	local row = newFrame(content, UDim2.new(1,-2,0,30), nil, Color3.new(0,0,0), 1)
	newLabel(row, opts.Text or idx, 13, theme.Text, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-52,1,0))

	local track = newFrame(row, UDim2.new(0,38,0,20), UDim2.new(1,-44,0.5,-10),
		state and theme.Accent or theme.Secondary, 0, 10, theme.Border)
	local thumb = newFrame(track, UDim2.new(0,16,0,16),
		state and UDim2.new(0,20,0.5,-8) or UDim2.new(0,2,0.5,-8),
		Color3.new(1,1,1), 0, 8)

	ChillUI.Toggles[idx]._track = track
	ChillUI.Toggles[idx]._thumb = thumb

	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			ChillUI.Toggles[idx]:SetValue(not state)
		end
	end)
	row.Parent = content
end

local function buildSlider(content, idx, opts)
	opts = opts or {}
	local theme = T()
	local min_, max_, rnd = opts.Min or 0, opts.Max or 100, opts.Rounding or 0
	local val = math.clamp(opts.Default or min_, min_, max_)

	ChillUI.Options[idx] = {
		Value    = val,
		_cbs     = {},
		SetValue = function(self, v, silent)
			v = math.clamp(math.floor(v * 10^rnd + 0.5) / 10^rnd, min_, max_)
			val = v
			self.Value = v
			local pct = (v - min_) / (max_ - min_)
			self._fill.Size     = UDim2.new(pct, 0, 1, 0)
			self._thumb.Position = UDim2.new(pct, -7, 0.5, -7)
			self._lbl.Text      = tostring(v)
			if not silent then
				if opts.Callback then pcall(opts.Callback, v) end
				for _, cb in ipairs(self._cbs) do pcall(cb, v) end
			end
		end,
		OnChanged = function(self, cb) table.insert(self._cbs, cb) end,
	}

	local cont = newFrame(content, UDim2.new(1,-2,0,46), nil, Color3.new(0,0,0), 1)
	newLabel(cont, opts.Text or idx, 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,2), UDim2.new(1,-60,0,16))
	local lbl = newLabel(cont, tostring(val), 12, theme.AccentLight, Enum.Font.GothamBold,
		UDim2.new(1,-52,0,2), UDim2.new(0,44,0,16), Enum.TextXAlignment.Right)

	local track = newFrame(cont, UDim2.new(1,-16,0,6), UDim2.new(0,8,0,30),
		theme.Secondary, 0, 3)
	local fill  = newFrame(track, UDim2.new(0,0,1,0), nil, theme.Accent, 0, 3)
	local thumb = newFrame(track, UDim2.new(0,14,0,14), UDim2.new(0,-7,0.5,-7),
		Color3.new(1,1,1), 0, 7)

	ChillUI.Options[idx]._fill  = fill
	ChillUI.Options[idx]._thumb = thumb
	ChillUI.Options[idx]._lbl   = lbl
	ChillUI.Options[idx]:SetValue(val, true)

	local dragging = false
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	local c1 = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	local c2 = UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local abs  = track.AbsolutePosition
			local sz   = track.AbsoluteSize
			local relX = math.clamp(inp.Position.X - abs.X, 0, sz.X)
			ChillUI.Options[idx]:SetValue(min_ + (relX / sz.X) * (max_ - min_))
		end
	end)
	table.insert(ChillUI._connections, c1)
	table.insert(ChillUI._connections, c2)
	cont.Parent = content
end

local function buildDropdown(content, idx, opts)
	opts = opts or {}
	local theme  = T()
	local values = opts.Values or {}
	local selected = (type(opts.Default) == "number") and values[opts.Default]
		or opts.Default or values[1] or ""

	ChillUI.Options[idx] = {
		Value    = selected,
		_cbs     = {},
		SetValue = function(self, v)
			selected = v
			self.Value = v
			if self._lbl then self._lbl.Text = v end
		end,
		OnChanged = function(self, cb) table.insert(self._cbs, cb) end,
	}

	local cont = newFrame(content, UDim2.new(1,-2,0,30), nil, Color3.new(0,0,0), 1)
	newLabel(cont, opts.Text or idx, 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-148,1,0))

	local dropFrame = newFrame(cont, UDim2.new(0,132,0,22), UDim2.new(1,-136,0.5,-11),
		theme.Secondary, 0, 6, theme.Border)
	local selLbl = newLabel(dropFrame, selected or "...", 12, theme.Text, FONT(),
		UDim2.new(0,6,0,0), UDim2.new(1,-22,1,0))
	newLabel(dropFrame, "▾", 10, theme.TextDim, Enum.Font.GothamBold,
		UDim2.new(1,-16,0,0), UDim2.new(0,12,1,0), Enum.TextXAlignment.Center)

	ChillUI.Options[idx]._lbl = selLbl

	local open, listFrame = false, nil
	dropFrame.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		open = not open
		if open then
			if listFrame then listFrame:Destroy() end
			listFrame = newFrame(cont,
				UDim2.new(0,132, 0, math.min(#values,6)*22+6),
				UDim2.new(1,-136,0,32),
				theme.Secondary, 0, 6, theme.Border)
			listFrame.ZIndex = 60
			listLayout(listFrame, 1)
			padding(listFrame, 3,3,4,4)
			for _, v in ipairs(values) do
				local it = newBtn(listFrame, v, 12,
					v == selected and theme.AccentLight or theme.Text,
					Color3.new(0,0,0), 4)
				it.Size               = UDim2.new(1,-4,0,20)
				it.TextXAlignment     = Enum.TextXAlignment.Left
				it.BackgroundTransparency = 1
				it.Font               = FONT()
				it.MouseButton1Click:Connect(function()
					selected      = v
					selLbl.Text   = v
					ChillUI.Options[idx].Value = v
					if opts.Callback then pcall(opts.Callback, v) end
					for _, cb in ipairs(ChillUI.Options[idx]._cbs) do pcall(cb, v) end
					listFrame:Destroy()
					listFrame = nil
					open = false
				end)
			end
		else
			if listFrame then listFrame:Destroy(); listFrame = nil end
		end
	end)
	cont.Parent = content
end

local function buildButton(content, opts)
	opts = opts or {}
	local theme = T()
	local cont  = newFrame(content, UDim2.new(1,-2,0,28), nil, Color3.new(0,0,0), 1)
	local btn   = newBtn(cont, opts.Text or "Button", 13, theme.Text, theme.Secondary, 6)
	btn.Size    = UDim2.new(1,0,1,0)
	btn.Font    = FONT()
	local stroke = Instance.new("UIStroke")
	stroke.Color       = theme.Border
	stroke.Transparency = 0.4
	stroke.Parent = btn
	btn.MouseEnter:Connect(function()
		tw(btn, {BackgroundColor3 = theme.Accent}, 0.14)
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, {BackgroundColor3 = theme.Secondary}, 0.14)
	end)
	btn.MouseButton1Down:Connect(function()
		tw(btn, {BackgroundColor3 = theme.AccentLight}, 0.08)
	end)
	btn.MouseButton1Up:Connect(function()
		tw(btn, {BackgroundColor3 = theme.Accent}, 0.1)
		if opts.Func and not opts.Disabled then
			task.spawn(opts.Func)
		end
	end)
	cont.Parent = content
end

local function buildLabel(content, text)
	local theme = T()
	local cont  = newFrame(content, UDim2.new(1,-2,0,0), nil, Color3.new(0,0,0), 1)
	cont.AutomaticSize = Enum.AutomaticSize.Y
	newLabel(cont, text or "", 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-16,0,0))
	cont.Parent = content
end

local function buildDivider(content)
	local theme = T()
	local cont  = newFrame(content, UDim2.new(1,-2,0,10), nil, Color3.new(0,0,0), 1)
	newFrame(cont, UDim2.new(1,-16,0,1), UDim2.new(0,8,0.5,0), theme.Border, 0.5)
	cont.Parent = content
end

local function buildInput(content, idx, opts)
	opts = opts or {}
	local theme = T()
	local cont  = newFrame(content, UDim2.new(1,-2,0,30), nil, Color3.new(0,0,0), 1)
	newLabel(cont, opts.Text or idx, 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-148,1,0))
	local box = Instance.new("TextBox")
	box.Size              = UDim2.new(0,132,0,22)
	box.Position          = UDim2.new(1,-136,0.5,-11)
	box.BackgroundColor3  = theme.Secondary
	box.TextColor3        = theme.Text
	box.PlaceholderText   = opts.Placeholder or ""
	box.PlaceholderColor3 = theme.TextDim
	box.Font              = FONT()
	box.TextSize          = 12
	box.Text              = opts.Default or ""
	box.BorderSizePixel   = 0
	box.ClearTextOnFocus  = opts.ClearTextOnFocus ~= false
	Instance.new("UICorner").CornerRadius = UDim.new(0,5)
	-- (need to parent UICorner properly)
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,5); bc.Parent = box
	box.Parent = cont
	ChillUI.Options[idx] = {
		Value    = box.Text,
		_cbs     = {},
		OnChanged = function(self, cb) table.insert(self._cbs, cb) end,
	}
	box:GetPropertyChangedSignal("Text"):Connect(function()
		ChillUI.Options[idx].Value = box.Text
		if opts.Callback then pcall(opts.Callback, box.Text) end
		for _, cb in ipairs(ChillUI.Options[idx]._cbs) do pcall(cb, box.Text) end
	end)
	cont.Parent = content
end

local function buildKeybind(content, idx, opts)
	opts = opts or {}
	local theme = T()
	local curKey = opts.Default or "None"

	ChillUI.Options[idx] = {
		Value        = curKey,
		_cbs         = {},
		_clickCbs    = {},
		SetValue     = function(self, v)
			curKey = v; self.Value = v
			if self._btn then self._btn.Text = "["..v.."]" end
		end,
		OnChanged    = function(self, cb) table.insert(self._cbs, cb) end,
		OnClick      = function(self, cb) table.insert(self._clickCbs, cb) end,
		GetState     = function() return false end,
	}

	local cont = newFrame(content, UDim2.new(1,-2,0,30), nil, Color3.new(0,0,0), 1)
	newLabel(cont, opts.Text or idx, 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-82,1,0))

	local kb = newBtn(cont, "["..curKey.."]", 11, theme.AccentLight, theme.Secondary, 5)
	kb.Size     = UDim2.new(0,68,0,22)
	kb.Position = UDim2.new(1,-72,0.5,-11)
	kb.Font     = FONT()
	ChillUI.Options[idx]._btn = kb

	local listening = false
	kb.MouseButton1Click:Connect(function()
		if listening then return end
		listening  = true
		kb.Text    = "[...]"
		tw(kb, {BackgroundColor3 = theme.Accent}, 0.14)
		local conn
		conn = UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe then return end
			local k
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				k = inp.KeyCode.Name
			elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then k = "MB1"
			elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then k = "MB2"
			end
			if k then
				curKey = k
				ChillUI.Options[idx].Value = k
				kb.Text = "["..k.."]"
				tw(kb, {BackgroundColor3 = theme.Secondary}, 0.14)
				listening = false
				conn:Disconnect()
				for _, cb in ipairs(ChillUI.Options[idx]._cbs) do pcall(cb, k) end
			end
		end)
	end)

	local mode = opts.Mode or "Toggle"
	if mode == "Toggle" then
		local active = false
		local c = UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe or listening then return end
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton1 and "MB1"
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == curKey then
				active = not active
				if opts.Callback then pcall(opts.Callback, active) end
				for _, cb in ipairs(ChillUI.Options[idx]._clickCbs) do pcall(cb, active) end
			end
		end)
		table.insert(ChillUI._connections, c)
	elseif mode == "Hold" then
		local c1 = UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe or listening then return end
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == curKey and opts.Callback then pcall(opts.Callback, true) end
		end)
		local c2 = UserInputService.InputEnded:Connect(function(inp)
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
				or inp.UserInputType == Enum.UserInputType.MouseButton2 and "MB2"
			if k == curKey and opts.Callback then pcall(opts.Callback, false) end
		end)
		table.insert(ChillUI._connections, c1)
		table.insert(ChillUI._connections, c2)
	elseif mode == "Press" then
		local c = UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe or listening then return end
			local k = inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name
			if k == curKey then
				if opts.Callback then pcall(opts.Callback) end
				for _, cb in ipairs(ChillUI.Options[idx]._clickCbs) do pcall(cb) end
			end
		end)
		table.insert(ChillUI._connections, c)
	end

	cont.Parent = content
end

local function buildColorPicker(content, idx, opts)
	opts = opts or {}
	local theme = T()
	local curColor = opts.Default or Color3.new(1,0,0)
	ChillUI.Options[idx] = {
		Value        = curColor,
		Transparency = opts.Transparency or 0,
		_cbs         = {},
		SetValueRGB  = function(self, c)
			self.Value = c
			curColor   = c
			if self._swatch then tw(self._swatch, {BackgroundColor3 = c}, 0.18) end
			if opts.Callback then pcall(opts.Callback, c) end
		end,
		OnChanged    = function(self, cb) table.insert(self._cbs, cb) end,
	}
	local cont = newFrame(content, UDim2.new(1,-2,0,30), nil, Color3.new(0,0,0), 1)
	newLabel(cont, opts.Title or idx, 12, theme.TextDim, FONT(),
		UDim2.new(0,8,0,0), UDim2.new(1,-50,1,0))
	local swatch = newFrame(cont, UDim2.new(0,30,0,20), UDim2.new(1,-38,0.5,-10),
		curColor, 0, 5, theme.Border)
	ChillUI.Options[idx]._swatch = swatch
	-- cycle colors on click (simple; full HSV picker is very heavyweight)
	local presets = {
		Color3.fromRGB(220,60,60), Color3.fromRGB(60,180,255),
		Color3.fromRGB(80,220,120), Color3.fromRGB(255,200,50),
		Color3.fromRGB(180,80,220), Color3.fromRGB(255,140,60),
	}
	local pi = 1
	swatch.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			pi = pi % #presets + 1
			ChillUI.Options[idx]:SetValueRGB(presets[pi])
			for _, cb in ipairs(ChillUI.Options[idx]._cbs) do pcall(cb, presets[pi]) end
		end
	end)
	cont.Parent = content
end

-- ─────────────────────────────────────────────
--  Groupbox
-- ─────────────────────────────────────────────
local function makeGroupbox(parent, opts)
	opts = opts or {}
	local theme = T()
	local name  = opts.Name or "Group"

	local outer = newFrame(parent, UDim2.new(1,0,0,0), nil, Color3.new(0,0,0), 1)
	outer.AutomaticSize = Enum.AutomaticSize.Y

	-- header
	local header = newFrame(outer, UDim2.new(1,0,0,27), nil, theme.Secondary, 0, 8, theme.Border)
	local strip  = newFrame(header, UDim2.new(0,3,0.75,0), UDim2.new(0,0,0.125,0), theme.Accent, 0, 2)
	newLabel(header, name, 13, theme.Text, Enum.Font.GothamBold,
		UDim2.new(0,12,0,0), UDim2.new(1,-30,1,0))

	local collapsed = opts.Collapsed == true
	local caret = newLabel(header, collapsed and "▸" or "▾", 12, theme.TextDim,
		Enum.Font.GothamBold, UDim2.new(1,-20,0,0), UDim2.new(0,16,1,0), Enum.TextXAlignment.Center)

	-- body
	local body = newFrame(outer, UDim2.new(1,0,0,0), UDim2.new(0,0,0,27),
		theme.Primary, 0.05, 0, theme.Border)
	body.AutomaticSize = Enum.AutomaticSize.Y
	listLayout(body, 3)
	padding(body, 5, 5, 2, 2)
	body.Visible = not collapsed

	header.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		collapsed    = not collapsed
		caret.Text   = collapsed and "▸" or "▾"
		body.Visible = not collapsed
	end)

	outer.Parent = parent

	-- API
	local gb = { _body = body }

	function gb:AddToggle(idx, o)
		buildToggle(body, idx, o)
		return self
	end
	function gb:AddCheckbox(idx, o) return self:AddToggle(idx, o) end
	function gb:AddSlider(idx, o)
		buildSlider(body, idx, o)
		return self
	end
	function gb:AddDropdown(idx, o)
		buildDropdown(body, idx, o)
		return self
	end
	function gb:AddButton(o)
		buildButton(body, o)
		return self
	end
	function gb:AddLabel(text)
		buildLabel(body, text)
		return self
	end
	function gb:AddDivider()
		buildDivider(body)
		return self
	end
	function gb:AddInput(idx, o)
		buildInput(body, idx, o)
		return self
	end
	function gb:AddColorPicker(idx, o)
		buildColorPicker(body, idx, o)
		return self
	end
	function gb:AddKeyPicker(idx, o)
		buildKeybind(body, idx, o)
		return self
	end

	return gb
end

-- ─────────────────────────────────────────────
--  Notification
-- ─────────────────────────────────────────────
local _notifStack = nil

local function setupNotifs()
	local sg    = newGui("ChillUI_Notifs")
	local stack = newFrame(sg, UDim2.new(0,270,1,-20), UDim2.new(1,-278,0,10),
		Color3.new(0,0,0), 1)
	local ll = listLayout(stack, 6, Enum.FillDirection.Vertical,
		Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
	_notifStack = stack
end

function ChillUI:Notify(opts)
	opts = opts or {}
	if not _notifStack then return end
	local theme = T()
	local card  = newFrame(_notifStack, UDim2.new(1,0,0,0), nil, theme.Secondary, 0, 10, theme.Accent)
	card.AutomaticSize = Enum.AutomaticSize.Y
	listLayout(card, 3)
	padding(card, 10, 10, 10, 10)
	if opts.Title then
		newLabel(card, opts.Title, 13, theme.Text, Enum.Font.GothamBold,
			nil, UDim2.new(1,0,0,16))
	end
	if opts.Description then
		newLabel(card, opts.Description, 11, theme.TextDim, FONT(),
			nil, UDim2.new(1,0,0,0))
	end
	local prog  = newFrame(card, UDim2.new(1,0,0,2), nil, theme.Accent, 0, 1)
	local secs  = opts.Time or 3
	card.BackgroundTransparency = 1
	tw(card, {BackgroundTransparency = 0}, 0.2)
	tw(prog, {Size = UDim2.new(0,0,0,2)}, secs, Enum.EasingStyle.Linear)
	task.delay(secs, function()
		tw(card, {BackgroundTransparency = 1}, 0.3)
		task.delay(0.35, function() pcall(function() card:Destroy() end) end)
	end)
end

-- ─────────────────────────────────────────────
--  Build main window (called after mode selection)
-- ─────────────────────────────────────────────
local function buildWindow(config)
	local theme   = T()
	local lite    = ChillUI.LiteMode
	local winW    = lite and 490 or 610
	local winH    = lite and 370 or 460
	local sg      = newGui("ChillUI_Main")
	ChillUI._gui  = sg

	-- shadow
	local shadow = newFrame(sg,
		UDim2.new(0, winW+24, 0, winH+24),
		UDim2.new(0.5, -(winW+24)/2, 0.5, -(winH+24)/2),
		Color3.new(0,0,0), 0.55, 18)
	shadow.ZIndex = 1

	-- main window
	local win = newFrame(sg,
		UDim2.new(0, winW, 0, winH),
		UDim2.new(0.5, -winW/2, 0.5, -winH/2),
		theme.Primary, 0, 12, theme.Border)
	win.ZIndex = 2
	ChillUI._window = win

	-- ── title bar ──
	local titleBar = newFrame(win, UDim2.new(1,0,0,38), nil, theme.Secondary, 0, 0, nil)
	do -- round only top corners
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = titleBar
		-- cover the bottom-round with a plain frame so only top is rounded
		newFrame(titleBar, UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), theme.Secondary, 0)
	end
	-- accent top line
	local acLine = newFrame(titleBar, UDim2.new(1,0,0,2), nil, theme.Accent, 0)
	local ag = Instance.new("UIGradient")
	ag.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.Accent),
		ColorSequenceKeypoint.new(0.5, theme.AccentLight),
		ColorSequenceKeypoint.new(1, theme.Accent),
	})
	ag.Parent = acLine

	newLabel(titleBar, "❄  " .. (config.Title or "ChillUI"), 14,
		theme.Text, Enum.Font.GothamBold,
		UDim2.new(0,12,0,0), UDim2.new(1,-110,1,0))
	newLabel(titleBar, "v" .. (config.Version or "1.0"), 11,
		theme.TextDim, FONT(),
		UDim2.new(0,12 + 115,0,0), UDim2.new(1,-230,1,0))

	-- window control buttons
	local function wctrl(xOff, col, ico, fn)
		local b = newFrame(titleBar, UDim2.new(0,14,0,14),
			UDim2.new(1, xOff, 0.5, -7), col, 0, 7)
		newLabel(b, ico, 8, Color3.new(0,0,0), Enum.Font.GothamBold,
			nil, UDim2.new(1,0,1,0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)
		b.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then fn() end
		end)
		return b
	end

	local minimised = false
	local mainScroll -- forward declare

	wctrl(-20, Color3.fromRGB(220,70,70), "✕", function()
		tw(win, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)},
			0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.32, function() pcall(function() win:Destroy(); shadow:Destroy() end) end)
	end)
	wctrl(-38, Color3.fromRGB(220,170,50), "−", function()
		minimised = not minimised
		tw(win, {Size = minimised
			and UDim2.new(0,winW,0,38)
			or  UDim2.new(0,winW,0,winH)}, 0.22)
	end)

	makeDraggable(titleBar, win)

	-- ── tab bar ──
	local tabBar = newFrame(win, UDim2.new(1,0,0,30), UDim2.new(0,0,0,38),
		theme.Primary, 0.7)
	listLayout(tabBar, 2, Enum.FillDirection.Horizontal,
		Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	padding(tabBar, 0, 0, 8, 8)

	-- ── scroll area ──
	mainScroll = Instance.new("ScrollingFrame")
	mainScroll.Size                    = UDim2.new(1,0,1,-70)
	mainScroll.Position                = UDim2.new(0,0,0,70)
	mainScroll.BackgroundTransparency  = 1
	mainScroll.BorderSizePixel         = 0
	mainScroll.ScrollBarThickness      = 3
	mainScroll.ScrollBarImageColor3    = theme.ScrollBar
	mainScroll.CanvasSize              = UDim2.new(0,0,0,0)
	mainScroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	mainScroll.ScrollingDirection      = Enum.ScrollingDirection.Y
	mainScroll.Parent                  = win

	local contentLayout = listLayout(mainScroll, 6)
	padding(mainScroll, 8, 8, 8, 8)

	-- ── tab management ──
	local tabPages  = {}
	local switchTo

	local function addPage(name, icon)
		-- tab button
		local btn = newBtn(tabBar,
			(icon and icon.." " or "") .. name,
			12, theme.TextDim, Color3.new(0,0,0), 6)
		btn.Name                   = name
		btn.BackgroundTransparency = 1
		btn.AutomaticSize          = Enum.AutomaticSize.X
		btn.Size                   = UDim2.new(0,0,1,0)
		btn.Font                   = Enum.Font.GothamBold
		local pp = Instance.new("UIPadding")
		pp.PaddingLeft = UDim.new(0,8); pp.PaddingRight = UDim.new(0,8); pp.Parent = btn

		-- page container
		local page = newFrame(mainScroll, UDim2.new(1,0,0,0), nil, Color3.new(0,0,0), 1)
		page.AutomaticSize = Enum.AutomaticSize.Y
		page.Visible       = false
		listLayout(page, 6)

		tabPages[name] = page

		btn.MouseButton1Click:Connect(function()
			if switchTo then switchTo(name) end
		end)
		return page, btn
	end

	switchTo = function(name)
		for n, p in pairs(tabPages) do p.Visible = (n == name) end
		for _, b in ipairs(tabBar:GetChildren()) do
			if b:IsA("TextButton") then
				local active = b.Name == name
				tw(b, {
					BackgroundTransparency = active and 0 or 1,
					BackgroundColor3       = theme.Accent,
					TextColor3             = active and Color3.new(1,1,1) or theme.TextDim,
				}, 0.14)
			end
		end
	end

	-- built-in settings tab
	local settingsPage, _ = addPage("⚙ Settings", nil)
	task.defer(function()
		local theme2 = T()
		local appGb  = makeGroupbox(settingsPage, {Name = "Appearance"})
		local themeNames = {}
		for k in pairs(ChillUI.Themes) do table.insert(themeNames, k) end
		table.sort(themeNames)
		buildDropdown(appGb._body, "__chill_theme", {
			Text    = "Theme",
			Values  = themeNames,
			Default = ChillUI.CurrentTheme,
			Callback = function(v)
				ChillUI.CurrentTheme = v
				tw(win, {BackgroundColor3 = ChillUI.Themes[v].Primary}, 0.3)
			end,
		})
		if not lite then
			local fontNames = {}
			for k in pairs(ChillUI.FontMap) do table.insert(fontNames, k) end
			table.sort(fontNames)
			buildDropdown(appGb._body, "__chill_font", {
				Text    = "Font",
				Values  = fontNames,
				Default = ChillUI.CurrentFont,
				Callback = function(v) ChillUI.CurrentFont = v end,
			})
		end

		local winGb = makeGroupbox(settingsPage, {Name = "Window"})
		buildSlider(winGb._body, "__chill_radius", {
			Text     = "Corner Radius",
			Min      = 0, Max = 20, Default = 12, Rounding = 0,
			Callback = function(v)
				local c = win:FindFirstChildOfClass("UICorner")
				if c then c.CornerRadius = UDim.new(0,v) end
			end,
		})
		local menuGb = makeGroupbox(settingsPage, {Name = "Keybinds"})
		buildKeybind(menuGb._body, "__chill_menukey", {
			Text    = "Toggle Menu",
			Default = "RightShift",
			Mode    = "Toggle",
			Callback = function()
				win.Visible = not win.Visible
			end,
		})
	end)

	-- menu toggle key (default RightShift, can be overridden)
	local menuKey = Enum.KeyCode.RightShift
	local mc = UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.KeyCode == menuKey then
			win.Visible = not win.Visible
		end
	end)
	table.insert(ChillUI._connections, mc)

	-- ── Window API ──
	local Window = {}

	function Window:AddTab(name, icon)
		local page = addPage(name, icon)
		-- activate first real tab
		task.defer(function()
			if switchTo then
				-- find first non-settings tab
				for n in pairs(tabPages) do
					if not n:find("Settings") then switchTo(n) return end
				end
				switchTo(next(tabPages))
			end
		end)
		local tabObj = {}
		function tabObj:AddGroupbox(o)   return makeGroupbox(page, o) end
		function tabObj:AddLeftGroupbox(n, ic) return makeGroupbox(page, {Name=n, IconName=ic}) end
		function tabObj:AddRightGroupbox(n, ic) return makeGroupbox(page, {Name=n, IconName=ic}) end
		function tabObj:AddRightTabbox() return makeGroupbox(page, {Name="Options"}) end
		function tabObj:AddLabel(o)
			buildLabel(page, type(o)=="string" and o or (o and o.Text or ""))
		end
		function tabObj:AddKeyBox(cb)
			local gb2 = makeGroupbox(page, {Name = "Key System"})
			buildInput(gb2._body, "__keybox__", {
				Text = "Enter key", Placeholder = "...",
				Callback = function(v) if cb then task.spawn(cb, v) end end,
			})
			return gb2
		end
		function tabObj:AddKeyTab() return self end
		return tabObj
	end

	function Window:AddKeyTab(name)
		return self:AddTab(name or "Key", "🔑")
	end

	function Window:SetToggleKey(key)
		if Enum.KeyCode[key] then menuKey = Enum.KeyCode[key] end
	end

	-- pop in animation
	win.Size = UDim2.new(0,0,0,0)
	win.Position = UDim2.new(0.5,0,0.5,0)
	tw(win, {
		Size     = UDim2.new(0, winW, 0, winH),
		Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2),
	}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	return Window
end

-- ─────────────────────────────────────────────
--  Public API
-- ─────────────────────────────────────────────

--[[
	CreateWindow  –  SYNCHRONOUS  –  shows startup screen, blocks until
	mode is chosen, then builds and returns the Window object.
	
	Usage:
		local Window = ChillUI:CreateWindow({ Title = "...", Version = "..." })
		local Tabs = { Main = Window:AddTab("Main") }
]]
function ChillUI:CreateWindow(config, skipStartup)
	config = config or {}
	setupNotifs()

	if skipStartup then
		return buildWindow(config)
	end

	-- Use coroutine so we can yield inside the event-driven startup screen
	local co    = coroutine.running()
	local result = nil

	showStartup(config, function(lite)
		ChillUI.LiteMode = lite
		result = buildWindow(config)
		if co then
			local ok, err = coroutine.resume(co, result)
			if not ok then warn("[ChillUI] coroutine error:", err) end
		end
	end)

	-- If we're in a coroutine (normal script), yield until startup is done
	if co then
		return coroutine.yield()
	else
		-- Fallback: just wait (shouldn't normally be needed)
		while not result do task.wait() end
		return result
	end
end

-- Keep Init as an alias for people using it
function ChillUI:Init(config)
	return self:CreateWindow(config)
end

function ChillUI:OnUnload(cb)
	table.insert(self._unloadFns, cb)
end

function ChillUI:Unload()
	self.Unloaded = true
	for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
	if self._gui     then pcall(function() self._gui:Destroy()     end) end
	if self._notifGui then pcall(function() self._notifGui:Destroy() end) end
	for _, fn in ipairs(self._unloadFns) do pcall(fn) end
end

return ChillUI
