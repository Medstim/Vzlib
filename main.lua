local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Executor globals (names differ between executors) -----------------
local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------

local DefaultTheme = {
	Background = Color3.fromRGB(16, 16, 16),
	Secondary = Color3.fromRGB(27, 27, 27), -- Secondary Background color

	Element = Color3.fromRGB(34, 34, 34),
	ElementHover = Color3.fromRGB(42, 42, 42),
	ElementPressed = Color3.fromRGB(48, 48, 48),

	Off = Color3.fromRGB(55, 55, 55),
	Knob = Color3.fromRGB(255, 255, 255), -- toggle / slider knob

	Stroke = Color3.fromRGB(171, 171, 171),
	StrokeDim = Color3.fromRGB(65, 65, 65),

	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(175, 175, 175), -- Secondary Text color

	Accent = Color3.fromRGB(100, 160, 255),
	Success = Color3.fromRGB(90, 205, 130),
	Warning = Color3.fromRGB(255, 190, 70),
	WarningBg = Color3.fromRGB(40, 34, 20), -- background of warning rows
	Error = Color3.fromRGB(255, 90, 90),
}

local function cloneTheme(source)
	local theme = {}
	for key, value in pairs(source) do
		theme[key] = value
	end
	return theme
end

-- Keeps only known keys holding Color3 values (warns about the rest).
local function sanitizeTheme(input)
	local clean = {}
	if type(input) ~= "table" then return clean end
	for key, value in pairs(input) do
		if DefaultTheme[key] == nil then
			warn(("[VaehzUI] Unknown theme key '%s' ignored"):format(tostring(key)))
		elseif typeof(value) ~= "Color3" then
			warn(("[VaehzUI] Theme key '%s' must be a Color3 (got %s)"):format(tostring(key), typeof(value)))
		else
			clean[key] = value
		end
	end
	return clean
end

local function applyTheme(base, overrides)
	local theme = cloneTheme(base)
	for key, value in pairs(sanitizeTheme(overrides)) do
		theme[key] = value
	end
	return theme
end

-- Built-in presets. Anything omitted falls back to the default (Dark) value.
local Themes = {
	Dark = cloneTheme(DefaultTheme),

	Light = applyTheme(DefaultTheme, {
		Background = Color3.fromRGB(243, 243, 246),
		Secondary = Color3.fromRGB(232, 232, 237),
		Element = Color3.fromRGB(255, 255, 255),
		ElementHover = Color3.fromRGB(240, 240, 245),
		ElementPressed = Color3.fromRGB(228, 228, 235),
		Off = Color3.fromRGB(200, 200, 210),
		Stroke = Color3.fromRGB(70, 70, 85),
		StrokeDim = Color3.fromRGB(205, 205, 214),
		Text = Color3.fromRGB(24, 24, 30),
		SubText = Color3.fromRGB(105, 105, 118),
		Accent = Color3.fromRGB(55, 115, 235),
		Success = Color3.fromRGB(30, 155, 85),
		Warning = Color3.fromRGB(196, 120, 0),
		WarningBg = Color3.fromRGB(255, 243, 214),
		Error = Color3.fromRGB(214, 60, 60),
	}),

	Midnight = applyTheme(DefaultTheme, {
		Background = Color3.fromRGB(10, 12, 22),
		Secondary = Color3.fromRGB(17, 20, 36),
		Element = Color3.fromRGB(24, 28, 50),
		ElementHover = Color3.fromRGB(32, 37, 64),
		ElementPressed = Color3.fromRGB(40, 46, 78),
		Off = Color3.fromRGB(46, 52, 84),
		Stroke = Color3.fromRGB(150, 160, 210),
		StrokeDim = Color3.fromRGB(55, 62, 100),
		Text = Color3.fromRGB(240, 243, 255),
		SubText = Color3.fromRGB(150, 158, 190),
		Accent = Color3.fromRGB(130, 120, 255),
		Success = Color3.fromRGB(90, 210, 150),
		Error = Color3.fromRGB(255, 95, 110),
	}),

	Rose = applyTheme(DefaultTheme, {
		Background = Color3.fromRGB(20, 14, 17),
		Secondary = Color3.fromRGB(31, 21, 26),
		Element = Color3.fromRGB(40, 28, 34),
		ElementHover = Color3.fromRGB(50, 35, 42),
		ElementPressed = Color3.fromRGB(58, 41, 49),
		Off = Color3.fromRGB(66, 48, 56),
		Stroke = Color3.fromRGB(190, 160, 170),
		StrokeDim = Color3.fromRGB(74, 52, 60),
		Text = Color3.fromRGB(255, 245, 248),
		SubText = Color3.fromRGB(190, 165, 172),
		Accent = Color3.fromRGB(255, 105, 150),
		Success = Color3.fromRGB(110, 215, 150),
	}),
}

-- Accepts a preset name or a (partial) table. Returns a clean patch or nil.
local function resolveThemeInput(input)
	if type(input) == "string" then
		local preset = Themes[input]
		if not preset then
			warn(("[VaehzUI] Unknown theme '%s'"):format(input))
			return nil
		end
		return cloneTheme(preset)
	elseif type(input) == "table" then
		return sanitizeTheme(input)
	end
	warn("[VaehzUI] SetTheme expects a theme name or a table of colors")
	return nil
end

-- Scopes ---------------------------------------------------------------
local THEME_TI = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local REF_MT = {}

local function isRef(v)
	return type(v) == "table" and getmetatable(v) == REF_MT
end

local function resolveValue(v)
	if isRef(v) then return v.scope.colors[v.key] end
	return v
end

local Scope = {}
Scope.__index = Scope

local function newScope(base)
	local scope = setmetatable({
		colors = cloneTheme(base),
		bindings = setmetatable({}, { __mode = "k" }), -- inst -> { prop -> key | fn(colors) }
		listeners = {},
		_nextId = 0,
	}, Scope)

	scope.refs = setmetatable({}, {
		__index = function(refs, key)
			if DefaultTheme[key] == nil then
				warn(("[VaehzUI] Unknown theme key '%s'"):format(tostring(key)))
				return nil
			end
			local ref = setmetatable({ scope = scope, key = key }, REF_MT)
			rawset(refs, key, ref)
			return ref
		end,
	})
	return scope
end

local function evalBinding(scope, binding)
	if type(binding) == "function" then return binding(scope.colors) end
	return scope.colors[binding]
end

-- Bind `inst[prop]` to a theme key, or to a function(colors) for state-dependent colors.
function Scope:Bind(inst, prop, binding)
	local props = self.bindings[inst]
	if not props then
		props = {}
		self.bindings[inst] = props
	end
	props[prop] = binding
	inst[prop] = evalBinding(self, binding)
end

function Scope:Refresh(animate)
	for inst, props in pairs(self.bindings) do
		for prop, binding in pairs(props) do
			local target = evalBinding(self, binding)
			if target ~= nil then
				pcall(function()
					if animate then
						TweenService:Create(inst, THEME_TI, { [prop] = target }):Play()
					else
						inst[prop] = target
					end
				end)
			end
		end
	end
	for _, fn in pairs(self.listeners) do
		task.spawn(fn, self.colors)
	end
end

-- `patch` must already be sanitized (see resolveThemeInput).
function Scope:Apply(patch, animate)
	local changed = false
	for key, value in pairs(patch) do
		if self.colors[key] ~= value then
			self.colors[key] = value
			changed = true
		end
	end
	if changed then self:Refresh(animate) end
	return changed
end

function Scope:Connect(fn)
	self._nextId += 1
	local id = self._nextId
	self.listeners[id] = fn
	return function() self.listeners[id] = nil end
end

local GlobalScope = newScope(DefaultTheme)

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Medium)

local TI    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local STROKE_T = 0.83 -- matches the TopBar stroke

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			if isRef(v) then
				v.scope:Bind(inst, k, v.key)
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in children do c.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(parent, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local function stroke(parent, color, trans, thick)
	return create("UIStroke", {
		Color = color or GlobalScope.refs.Stroke,
		Transparency = trans or 0.5,
		Thickness = thick or 1,
		Parent = parent,
	})
end

-- UIShadow is a beta instance; guard so the lib never hard-errors if it's absent
local function addShadow(parent, blur, trans)
	local ok, shadow = pcall(function()
		return create("UIShadow", {
			BlurRadius = UDim.new(0, blur or 16),
			Transparency = trans or 0.5,
			Parent = parent,
		})
	end)
	return ok and shadow or nil
end

local function tween(obj, info, props)
	local resolved = {}
	for k, v in props do resolved[k] = resolveValue(v) end
	local t = TweenService:Create(obj, info or TI, resolved)
	t:Play()
	return t
end

local function icon(name, size, filled, color)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name or "",
		FontFace = Font.new(BUILDER_ICONS, filled and Enum.FontWeight.Bold or Enum.FontWeight.Regular),
		TextColor3 = color or GlobalScope.refs.Text,
		TextScaled = true,
		Size = UDim2.fromOffset(size or 18, size or 18),
	})
end

-- Draggable window via a handle
local function makeDraggable(frame, handle)
	local dragging, dragInput, startPos, startFramePos
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = inp.Position
			startFramePos = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - startPos
			frame.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
		end
	end)
end

-- Normalized drag region (sliders / color squares). Supports mouse + touch.
local function bindDrag(region, onUpdate)
	local dragging = false
	local function upd(inp)
		local ap, sz = region.AbsolutePosition, region.AbsoluteSize
		local ax = math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1)
		local ay = math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1)
		onUpdate(ax, ay)
	end
	region.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; upd(inp)
		end
	end)
	region.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(inp)
		end
	end)
end

local function getGuiParent()
	if gethui then return gethui() end
	local ok, cg = pcall(function()
		return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
	end)
	return ok and cg or game:GetService("CoreGui")
end

-- Copy a string to clipboard. Returns whether a clipboard fn was available.
local function copyToClipboard(str)
	if not setClipboard then return false end
	return pcall(setClipboard, str)
end



----------------------------------------------------------------------
-- Library root
----------------------------------------------------------------------
local Library = {}
Library.__index = Library

local ScreenGui = create("ScreenGui", {
	Name = "VaehzUI",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = getGuiParent()

-- Notification stack (bottom-right)
local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 260, 1, -32),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

Library.MaxNotifications = 5 -- oldest is dismissed past this (0 = unlimited)
Library._windows = {}

local NOTIFY_TYPES = {
	Info    = { color = "Accent",  icon = "circle" },
	Success = { color = "Success", icon = "check" },
	Warning = { color = "Warning", icon = "triangle-exclamation" },
	Error   = { color = "Error",   icon = "x" },
}

local activeNotifs = {}
local notifCounter = 0


function Library:Notify(cfg, scope)
	if type(cfg) == "string" then cfg = { Content = cfg } end
	cfg = cfg or {}
	scope = scope or GlobalScope -- Window:Notify passes the window's own scope
	local Theme = scope.refs

	local kind = NOTIFY_TYPES[cfg.Type] or NOTIFY_TYPES.Info
	local tint = Theme[kind.color]
	local dur = tonumber(cfg.Duration) or 4
	local timed = dur > 0
	local iconName = cfg.Icon
	if iconName == nil then iconName = kind.icon end

	local cap = Library.MaxNotifications
	while cap > 0 and #activeNotifs >= cap do
		activeNotifs[1]:Dismiss()
	end

	notifCounter += 1
	local wrapper = create("Frame", {
		Name = "Notification", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = notifCounter, Parent = NotifHolder,
	})
	local card = create("CanvasGroup", {
		BackgroundColor3 = Theme.Secondary, GroupTransparency = 1, Active = true,
		Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = wrapper,
	})
	corner(card, 8)
	stroke(card, Theme.Stroke, STROKE_T)

	create("Frame", {
		BackgroundColor3 = tint, BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0), Parent = card,
	})

	local padLeft = iconName and 40 or 16
	if iconName then
		local ic = icon(iconName, 18, false, tint)
		ic.Position = UDim2.fromOffset(15, 11)
		ic.Parent = card
	end

	local content = create("Frame", {
		BackgroundTransparency = 1, Position = UDim2.new(0, padLeft, 0, 0),
		Size = UDim2.new(1, -(padLeft + 12), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 13) }),
	})

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or cfg.Type or "Notification",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1, Parent = content,
	})
	local bodyLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Content or "", Visible = cfg.Content ~= nil,
		FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2, Parent = content,
	})

	local bar
	if timed then
		bar = create("Frame", {
			BackgroundColor3 = tint, BackgroundTransparency = 0.4, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 2), ZIndex = 2, Parent = card,
		})
	end

	local handle = { Instance = wrapper }
	local dead, hovered, elapsed, heartbeat = false, false, 0, nil

	function handle:Dismiss()
		if dead then return end
		dead = true
		if heartbeat then heartbeat:Disconnect() end
		local idx = table.find(activeNotifs, handle)
		if idx then table.remove(activeNotifs, idx) end

		tween(card, TI, { GroupTransparency = 1, Position = UDim2.new(0, 32, 0, 0) })
		task.delay(0.16, function()
			if not wrapper.Parent then return end
			-- collapse the gap so the stack closes smoothly
			wrapper.AutomaticSize = Enum.AutomaticSize.None
			wrapper.Size = UDim2.new(1, 0, 0, wrapper.AbsoluteSize.Y)
			local t = tween(wrapper, TI, { Size = UDim2.new(1, 0, 0, 0) })
			t.Completed:Wait()
			wrapper:Destroy()
		end)
	end

	-- Update text in place; restarts the timer.
	function handle:Update(new)
		if dead or type(new) ~= "table" then return end
		if new.Title ~= nil then titleLbl.Text = new.Title end
		if new.Content ~= nil then
			bodyLbl.Text = new.Content
			bodyLbl.Visible = new.Content ~= ""
		end
		elapsed = 0
	end

	card.MouseEnter:Connect(function() hovered = true end)
	card.MouseLeave:Connect(function() hovered = false end)
	if cfg.ClickToDismiss ~= false then
		card.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				handle:Dismiss()
			end
		end)
	end

	if timed then
		heartbeat = RunService.Heartbeat:Connect(function(dt)
			if dead or hovered then return end
			elapsed += dt
			bar.Size = UDim2.new(math.max(1 - elapsed / dur, 0), 0, 0, 2)
			if elapsed >= dur then handle:Dismiss() end
		end)
	end

	table.insert(activeNotifs, handle)
	tween(card, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	return handle
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}

	local scope = newScope(GlobalScope.colors)
	local overrides = {}

	local Window = { Tabs = {}, _current = nil, _scope = scope, _overrides = overrides }
	Window.Theme = scope.colors -- live, resolved colors

	-- Components below read `Theme.X` as a theme reference (see Theme system).
	local Theme = scope.refs

	do
		local initial = {}
		if cfg.Theme ~= nil then
			for k, v in pairs(resolveThemeInput(cfg.Theme) or {}) do initial[k] = v end
		end
		if cfg.Accent then
			for k, v in pairs(sanitizeTheme({ Accent = cfg.Accent })) do initial[k] = v end
		end
		for k in pairs(initial) do overrides[k] = true end
		scope:Apply(initial, false)
	end

	-- Theme API ---------------------------------------------------------
	-- Window:SetTheme("Light") / Window:SetTheme({ Accent = Color3.fromRGB(...) })
	function Window:SetTheme(input, animate)
		local patch = resolveThemeInput(input)
		if not patch then return false end
		for key in pairs(patch) do overrides[key] = true end
		scope:Apply(patch, animate ~= false)
		return true
	end
	function Window:GetTheme() return cloneTheme(scope.colors) end
	function Window:SetAccent(color, animate) return Window:SetTheme({ Accent = color }, animate) end
	function Window:ResetTheme(animate) -- follow the global theme again
		table.clear(overrides)
		scope:Apply(GlobalScope.colors, animate ~= false)
	end
	function Window:OnThemeChanged(fn) return scope:Connect(fn) end
	function Window:Notify(ncfg) return Library:Notify(ncfg, scope) end

	local BG = create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(532, 410),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})
	corner(BG, 6)
	stroke(BG, Theme.Stroke, 0.5)
	addShadow(BG, 20, 0.5)

	-- Top bar
	local TopBar = create("Frame", {
		Name = "TopBar",
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 45),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = BG,
	})
	stroke(TopBar, Theme.Stroke, STROKE_T)
	addShadow(TopBar, 10, 0.86)

	create("TextLabel", {
		Name = "Title", Text = cfg.Title or "Lib Name",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.new(0, 300, 0, 22),
		Parent = TopBar,
	})

	local function ctrlBtn(iconName, offsetX, hoverColor)
		local b = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0), Size = UDim2.fromOffset(26, 26),
			Parent = TopBar,
		})
		corner(b, 6)
		local ic = icon(iconName, 16, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.new(0.5, 0, 0.5, 0)
		ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = hoverColor or Theme.Text })
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tween(ic, TI, { TextColor3 = Theme.SubText })
		end)
		return b
	end

	local CloseBtn = ctrlBtn("x", -10, Color3.fromRGB(255, 90, 90))
	local MinBtn   = ctrlBtn("minus", -42, Theme.Text)
	local settingsBtn = ctrlBtn("gear", -74, Theme.Text)

	----------------------------------------------------------------
		-- TopBar Settings Flyout
		----------------------------------------------------------------
		local settingsMenu = create("CanvasGroup", {
			Name = "SettingsMenu",
			BackgroundColor3 = Theme.Secondary,
			BackgroundTransparency = 0.05,
			Position = UDim2.new(1, -190, 1, 6),
			Size = UDim2.new(0, 180, 0, 0),
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 10,
			Parent = TopBar,
		})
		corner(settingsMenu, 6)
		stroke(settingsMenu, Theme.Stroke, 0.5)
	
		local menuList = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Stroke,
			BorderSizePixel = 0,
			Parent = settingsMenu,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		})
	
		-- Helper: Section Header
		local function addMenuHeader(text)
			create("TextLabel", {
				BackgroundTransparency = 1,
				Text = text,
				FontFace = FONT_TITLE,
				TextColor3 = Theme.SubText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 14),
				Parent = menuList,
			})
		end
	
		-- 1. Theme Presets Label & Dropdown
		addMenuHeader("THEME PRESETS")
	
		local themeNames = Library:GetThemes()
		for _, themeName in ipairs(themeNames) do
			local themeBtn = create("TextButton", {
				Text = "", AutoButtonColor = false,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 24),
				BorderSizePixel = 0,
				Parent = menuList,
			})
			corner(themeBtn, 4)
			stroke(themeBtn, Theme.Stroke, STROKE_T)
	
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = themeName,
				FontFace = FONT_MAIN,
				TextColor3 = Theme.Text,
				TextSize = 12,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = themeBtn,
			})
	
			themeBtn.MouseEnter:Connect(function() tween(themeBtn, TI, { BackgroundColor3 = Theme.ElementHover }) end)
			themeBtn.MouseLeave:Connect(function() tween(themeBtn, TI, { BackgroundColor3 = Theme.Element }) end)
			themeBtn.Activated:Connect(function()
				Window:SetTheme(themeName)
			end)
		end
	
		-- 2. Toggle Keybind Setting
		addMenuHeader("HOTKEY")
	
		local currentToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
		local bindingHotkey = false
	
		local keyBtn = create("TextButton", {
			Text = "", AutoButtonColor = false,
			BackgroundColor3 = Theme.Element,
			Size = UDim2.new(1, 0, 0, 26),
			BorderSizePixel = 0,
			Parent = menuList,
		})
		corner(keyBtn, 4)
		stroke(keyBtn, Theme.Stroke, STROKE_T)
	
		local keyLbl = create("TextLabel", {
			BackgroundTransparency = 1,
			Text = "Toggle: " .. currentToggleKey.Name,
			FontFace = FONT_MAIN,
			TextColor3 = Theme.Text,
			TextSize = 12,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = keyBtn,
		})
	
		keyBtn.Activated:Connect(function()
			if bindingHotkey then return end
			bindingHotkey = true
			keyLbl.Text = "Press key..."
	
			local conn
			conn = UserInputService.InputBegan:Connect(function(inp, gp)
				if gp then return end
				if inp.UserInputType == Enum.UserInputType.Keyboard then
					conn:Disconnect()
					currentToggleKey = inp.KeyCode
					bindingHotkey = false
					keyLbl.Text = "Toggle: " .. currentToggleKey.Name
	
					if toggleConn then toggleConn:Disconnect() end
					toggleConn = UserInputService.InputBegan:Connect(function(newInp, newGp)
						if newGp then return end
						if newInp.KeyCode == currentToggleKey then
							hidden = not hidden
							BG.Visible = not hidden
						end
					end)
				end
			end)
		end)
	
		-- Open/Close Animation for Gear Button
		local menuOpen = false
		settingsBtn.Activated:Connect(function()
			menuOpen = not menuOpen
			if menuOpen then
				settingsMenu.Visible = true
			end
			tween(settingsMenu, TI_S, { Size = UDim2.new(0, 180, 0, menuOpen and 185 or 0) })
			if not menuOpen then
				task.delay(0.18, function()
					if not menuOpen then settingsMenu.Visible = false end
				end)
			end
		end)

	-- Body
	local Body = create("Frame", {
		Name = "Body", BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 1, -45),
		Parent = BG,
	})

	-- Tab list (left)
	local TabList = create("ScrollingFrame", {
		Name = "TabList", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Size = UDim2.new(0, 140, 1, 0),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.5,
		Parent = Body,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})

	-- Content (right)
	local Content = create("Frame", {
		Name = "Content", BackgroundTransparency = 1,
		Position = UDim2.new(0, 141, 0, 0), Size = UDim2.new(1, -141, 1, 0),
		Parent = Body,
	})

	-- Divider between sidebar and content
	create("Frame", {
		Name = "SideDivider", BackgroundColor3 = Theme.Stroke, BackgroundTransparency = STROKE_T,
		BorderSizePixel = 0, Position = UDim2.new(0, 140, 0, 0), Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 2, Parent = Body,
	})

	makeDraggable(BG, TopBar)

	-- Close / minimize
	-- Closing only removes this window (notifications / other windows stay).
	local destroyed = false
	local toggleConn
	function Window:Destroy()
		if destroyed then return end
		destroyed = true
		if toggleConn then toggleConn:Disconnect() end
		local idx = table.find(Library._windows, Window)
		if idx then table.remove(Library._windows, idx) end
		tween(BG, TI, { GroupTransparency = 1, Size = UDim2.fromOffset(BG.AbsoluteSize.X, 0) })
		task.delay(0.18, function() BG:Destroy() end)
	end
	CloseBtn.Activated:Connect(function() Window:Destroy() end)

	local minimized = false
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Body.Visible = false
			tween(BG, TI_S, { Size = UDim2.fromOffset(532, 45) })
		else
			tween(BG, TI_S, { Size = UDim2.fromOffset(532, 410) })
			task.wait(0.12); Body.Visible = true
		end
	end)

	-- Toggle visibility keybind (desktop)
	local hidden = false
	toggleConn = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) then
			hidden = not hidden
			BG.Visible = not hidden
		end
	end)

	----------------------------------------------------------------
	-- Tabs
	----------------------------------------------------------------
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local Tab = { _order = 0 }

		local btn = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
			Parent = TabList,
		})
		corner(btn, 6)

		local ic = icon(tcfg.Icon or "circle", 18, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0, 0.5)
		ic.Position = UDim2.new(0, 8, 0.5, 0)
		ic.Parent = btn

		local nameLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = tcfg.Name or "Tab",
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 34, 0.5, 0),
			Size = UDim2.new(1, -40, 1, 0), Parent = btn,
		})

		local pageWrap = create("CanvasGroup", {
			Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), Visible = false, GroupTransparency = 0,
			Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.5,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			}),
		})

		local function select()
			if Window._current == Tab then return end
			for _, t in Window.Tabs do
				if t ~= Tab then t._wrap.Visible = false end
				tween(t._btn, TI, { BackgroundTransparency = 1 })
				tween(t._icon, TI, { TextColor3 = Theme.SubText })
				tween(t._name, TI, { TextColor3 = Theme.SubText })
			end
			Window._current = Tab
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.04, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = Theme.Accent })
			tween(nameLbl, TI, { TextColor3 = Theme.Text })
		end

		btn.MouseEnter:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 0.6 }) end
		end)
		btn.MouseLeave:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 1 }) end
		end)
		btn.Activated:Connect(select)
		scope:Bind(ic, "TextColor3", function(c) return Window._current == Tab and c.Accent or c.SubText end)
		scope:Bind(nameLbl, "TextColor3", function(c) return Window._current == Tab and c.Text or c.SubText end)

		Tab._btn, Tab._icon, Tab._name, Tab._page, Tab._wrap, Tab._select = btn, ic, nameLbl, page, pageWrap, select
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		-- shared row factory
		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, height or 34),
				LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(row, 6)
			stroke(row, Theme.Stroke, STROKE_T)
			return row
		end

		------------------------------------------------------------
		-- 1. Label
		------------------------------------------------------------
		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Label",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -8, 0, 0),
				Position = UDim2.new(0, 4, 0, 0), Parent = row,
			})
			create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = row })
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		------------------------------------------------------------
		-- 2. Warning
		------------------------------------------------------------
		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			scope:Bind(row, "BackgroundColor3", "WarningBg")
			for _, s in row:GetChildren() do
				if s:IsA("UIStroke") then scope:Bind(s, "Color", "Warning"); s.Transparency = 0.5 end
			end
			-- equal top/bottom padding => single-line text sits centered against the icon
			create("UIPadding", {
				PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = row,
			})
			local ico = icon("triangle-exclamation", 18, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5)
			ico.Position = UDim2.new(0, 0, 0.5, 0)
			ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Warning",
				FontFace = FONT_MAIN, TextColor3 = Theme.Warning, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -28, 0, 0), Position = UDim2.new(0, 28, 0, 0), Parent = row,
			})
			return { Set = function(_, t) lbl.Text = t end, Instance = row }
		end

		------------------------------------------------------------
		-- 3. Button
		------------------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local btnEl = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 36), LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(btnEl, 6); stroke(btnEl, Theme.Stroke, STROKE_T)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = bcfg.Name or "Button",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				Size = UDim2.new(1, 0, 1, 0), Parent = btnEl,
			})
			btnEl.MouseEnter:Connect(function() tween(btnEl, TI, { BackgroundColor3 = Theme.ElementHover }) end)
			btnEl.MouseLeave:Connect(function() tween(btnEl, TI, { BackgroundColor3 = Theme.Element }) end)
			btnEl.Activated:Connect(function()
				tween(btnEl, TI, { BackgroundColor3 = Theme.Accent })
				task.wait(0.12); tween(btnEl, TI, { BackgroundColor3 = Theme.Element })
				if bcfg.Callback then task.spawn(bcfg.Callback) end
			end)
			return { Instance = btnEl }
		end

		------------------------------------------------------------
		-- 4. Toggle
		------------------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = tocfg.Default or false
			local row = newRow(36)
			local btnEl = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = tocfg.Name or "Toggle",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -70, 1, 0), Parent = btnEl,
			})
			local track = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0, Parent = btnEl,
			})
			corner(track, 10)
			scope:Bind(track, "BackgroundColor3", function(c) return state and c.Accent or c.Off end)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Knob, AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, Parent = track,
			})
			corner(knob, 8)

			local api = {}
			function api:Set(v)
				state = v
				tween(track, TI, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
				tween(knob, TI, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
				if tocfg.Callback then task.spawn(tocfg.Callback, state) end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function() api:Set(not state) end)
			if state and tocfg.Callback then task.spawn(tocfg.Callback, true) end
			api.Instance = row
			return api
		end

		------------------------------------------------------------
		-- 5. Stat / Status
		------------------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local row = newRow(34)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = scfg.Name or "Stat",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(scfg.Value or "-"),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			return { Set = function(_, v) valLbl.Text = tostring(v) end, Instance = row }
		end

		------------------------------------------------------------
		-- 6. Slider
		------------------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local min, max = slcfg.Min or 0, slcfg.Max or 100
			local inc = slcfg.Increment or 1
			local value = math.clamp(slcfg.Default or min, min, max)
			local row = newRow(50)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = slcfg.Name or "Slider",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 10, 0, 6),
				Size = UDim2.new(1, -70, 0, 16), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(value),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 6), Size = UDim2.new(0, 60, 0, 16), Parent = row,
			})
			local track = create("Frame", {
				BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 1, -14), Size = UDim2.new(1, -20, 0, 6),
				BorderSizePixel = 0, Parent = row,
			})
			corner(track, 3)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent, Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BorderSizePixel = 0, Parent = track,
			})
			corner(fill, 3)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Knob, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, ZIndex = 2, Parent = track,
			})
			corner(knob, 7)

			local api = {}
			local function apply(alpha, fire)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = tostring(value)
				if fire and slcfg.Callback then task.spawn(slcfg.Callback, value) end
			end
			bindDrag(track, function(ax) apply(ax, true) end)
			function api:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
			function api:Get() return value end
			api.Instance = row
			return api
		end

		------------------------------------------------------------
		-- 7. Textbox
		------------------------------------------------------------
		function Tab:CreateTextbox(txcfg)
			txcfg = txcfg or {}
			local row = newRow(36)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = txcfg.Name or "Textbox",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.4, -10, 1, 0), Parent = row,
			})
			-- wrapper hugs the textbox; textbox grows with text but is clamped so it can't overlap the label
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Secondary, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 0, 0, 24),
				AutomaticSize = Enum.AutomaticSize.X, ClipsDescendants = true,
				BorderSizePixel = 0, Parent = row,
			}, {
				create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }),
			})
			corner(boxWrap, 5)
			local tbStroke = stroke(boxWrap, Theme.Stroke, STROKE_T)
			local tb = create("TextBox", {
				BackgroundTransparency = 1, Text = txcfg.Default or "",
				PlaceholderText = txcfg.Placeholder or "...", PlaceholderColor3 = Theme.SubText,
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
				ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new(txcfg.MinWidth or 56, 0),
					MaxSize = Vector2.new(txcfg.MaxWidth or 180, math.huge),
				}),
			})
			tb.Focused:Connect(function() tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 }) end)
			tb.FocusLost:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if txcfg.Callback then task.spawn(txcfg.Callback, tb.Text) end
			end)
			return {
				Set = function(_, t) tb.Text = t end,
				Get = function() return tb.Text end,
				Instance = row,
			}
		end

		------------------------------------------------------------
		-- 8. Color Picker (inline HSV, expands the row)
		------------------------------------------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = ccfg.Default or Color3.fromRGB(255, 0, 0)
			local h, s, v = color:ToHSV()

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = ccfg.Name or "Color",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -60, 1, 0), Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 18),
				BorderSizePixel = 0, Parent = header,
			})
			corner(swatch, 4); stroke(swatch, Theme.Stroke, 0.4)

			local body = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 130), Visible = false, Parent = row,
			})
			create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = body })

			-- SV square
			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -34, 1, 0),
				BorderSizePixel = 0, Parent = body,
			})
			corner(sv, 4)
			create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,4) }),
			})
			create("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0,0,0)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,4) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.fromOffset(8, 8),
				BorderSizePixel = 0, ZIndex = 5, Parent = sv,
			})
			corner(svCursor, 4); stroke(svCursor, Color3.new(0,0,0), 0.2)

			-- Hue bar
			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 22, 1, 0), BorderSizePixel = 0, Parent = body,
			})
			corner(hue, 4)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
				}),
				Parent = hue,
			})
			local hueCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 4, 0, 4),
				BorderSizePixel = 0, ZIndex = 5, Parent = hue,
			})
			corner(hueCursor, 2); stroke(hueCursor, Color3.new(0,0,0), 0.2)

			local function refresh(fire)
				color = Color3.fromHSV(h, s, v)
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				swatch.BackgroundColor3 = color
				if fire and ccfg.Callback then task.spawn(ccfg.Callback, color) end
			end
			bindDrag(sv, function(ax, ay) s = ax; v = 1 - ay; refresh(true) end)
			bindDrag(hue, function(_, ay) h = ay; refresh(true) end)

			local open = false
			header.Activated:Connect(function()
				open = not open
				if open then body.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and 172 or 36) })
				if not open then task.delay(0.12, function() if not open then body.Visible = false end end) end
			end)

			local api = {}
			function api:Set(c) h, s, v = c:ToHSV(); refresh(true) end
			function api:Get() return color end
			api.Instance = row
			return api
		end

		------------------------------------------------------------
		-- 9. Dropdown (single or multi, inline expand)
		------------------------------------------------------------
		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local options = dcfg.Options or {}
			local multi = dcfg.Multi or false
			local selected = {}
			if dcfg.Default then
				if type(dcfg.Default) == "table" then
					for _, d in dcfg.Default do selected[d] = true end
				else selected[dcfg.Default] = true end
			end

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = row })
			create("TextLabel", {
				BackgroundTransparency = 1, Text = dcfg.Name or "Dropdown",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = header,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0),
				Size = UDim2.new(0.5, -8, 1, 0), Parent = header,
			})
			local chev = icon("chevron-down", 16, false, Theme.SubText)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -10, 0.5, 0)
			chev.Parent = header

			local list = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, Parent = row,
			}, {
				create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
				create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8) }),
			})

			local function updateValLabel()
				local picked = {}
				for _, o in options do if selected[o] then table.insert(picked, o) end end
				valLbl.Text = #picked == 0 and "None" or table.concat(picked, ", ")
			end

			local api = {}
			local optionBtns = {}

			local function rebuild()
				for _, b in optionBtns do b.btn:Destroy() end
				table.clear(optionBtns)
				for i, opt in options do
					local ob = create("TextButton", {
						Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Secondary,
						Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, BorderSizePixel = 0, Parent = list,
					})
					corner(ob, 5)
					local txt = create("TextLabel", {
						BackgroundTransparency = 1, Text = opt, FontFace = FONT_MAIN,
						TextColor3 = selected[opt] and Theme.Accent or Theme.SubText, TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 8, 0, 0),
						Size = UDim2.new(1, -30, 1, 0), Parent = ob,
					})
					scope:Bind(txt, "TextColor3", function(c) return selected[opt] and c.Accent or c.SubText end)
					local check = icon("check", 14, false, Theme.Accent)
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, -8, 0.5, 0)
					check.Visible = selected[opt] == true
					check.Parent = ob

					ob.MouseEnter:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.ElementHover }) end)
					ob.MouseLeave:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.Secondary }) end)
					ob.Activated:Connect(function()
						if multi then
							selected[opt] = not selected[opt]
						else
							table.clear(selected); selected[opt] = true
						end
						for _, b in optionBtns do
							local on = selected[b.opt] == true
							b.check.Visible = on
							tween(b.txt, TI, { TextColor3 = on and Theme.Accent or Theme.SubText })
						end
						updateValLabel()
						if dcfg.Callback then
							if multi then
								local out = {}
								for _, o in options do if selected[o] then table.insert(out, o) end end
								task.spawn(dcfg.Callback, out)
							else
								task.spawn(dcfg.Callback, opt)
							end
						end
						if not multi then
							task.wait(0.05)
							api._toggle(false)
						end
					end)
					table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check })
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #options
				if n == 0 then return 44 end
				return 36 + (n * 28) + ((n - 1) * 2) + 8
			end

			local open = false
			function api._toggle(force)
				if force ~= nil then open = force else open = not open end
				if open then list.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and openHeight() or 36) })
				tween(chev, TI, { Rotation = open and 180 or 0 })
				if not open then task.delay(0.12, function() if not open then list.Visible = false end end) end
			end
			header.Activated:Connect(function() api._toggle() end)

			function api:Refresh(newOpts)
				options = newOpts or options
				rebuild()
				if open then api._toggle(true) end
			end
			function api:Set(val)
				table.clear(selected)
				if type(val) == "table" then for _, x in val do selected[x] = true end
				else selected[val] = true end
				rebuild()
			end
			function api:Get()
				local out = {}
				for _, o in options do if selected[o] then table.insert(out, o) end end
				return multi and out or out[1]
			end
			api.Instance = row
			rebuild()
			return api
		end

		return Tab
	end

	Window.Instance = BG
	table.insert(Library._windows, Window)
	return Window
end

----------------------------------------------------------------------
-- Theme API
----------------------------------------------------------------------
Library.Theme = GlobalScope.colors -- live, resolved global theme (read-only by convention)
Library.DefaultTheme = cloneTheme(DefaultTheme)
Library.Themes = Themes

-- Library:RegisterTheme("Mine", { Accent = ..., Background = ... })
-- Missing keys fall back to the default (Dark) value.
function Library:RegisterTheme(name, theme)
	if type(name) ~= "string" or type(theme) ~= "table" then return false end
	Themes[name] = applyTheme(DefaultTheme, theme)
	return true
end

function Library:GetThemes()
	local names = {}
	for name in pairs(Themes) do table.insert(names, name) end
	table.sort(names)
	return names
end

function Library:GetTheme()
	return cloneTheme(GlobalScope.colors)
end

function Library:SetTheme(input, animate)
	local patch = resolveThemeInput(input)
	if not patch then return false end
	animate = animate ~= false

	GlobalScope:Apply(patch, animate)
	for _, win in Library._windows do
		local filtered = {}
		for key, value in pairs(patch) do
			if not win._overrides[key] then filtered[key] = value end
		end
		win._scope:Apply(filtered, animate)
	end
	return true
end

function Library:SetAccent(color, animate)
	return Library:SetTheme({ Accent = color }, animate)
end

function Library:OnThemeChanged(fn)
	return GlobalScope:Connect(fn)
end

-- Remove everything (all windows + notifications).
function Library:Destroy()
	for _, n in table.clone(activeNotifs) do n:Dismiss() end
	table.clear(Library._windows)
	ScreenGui:Destroy()
end

return Library
