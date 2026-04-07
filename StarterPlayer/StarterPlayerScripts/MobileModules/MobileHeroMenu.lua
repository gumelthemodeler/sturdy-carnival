-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileHeroMenu
-- @ScriptType: ModuleScript
local MobileHeroMenu = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local SharedUI = playerScripts:WaitForChild("SharedUI")

local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

local notifModule = SharedUI:WaitForChild("NotificationManager", 2)
local NotificationManager = notifModule and require(notifModule) or nil

local auraModule = SharedUI:WaitForChild("UIAuraManager", 2)
local UIAuraManager = auraModule and require(auraModule) or nil

local VFXManager = require(playerScripts:WaitForChild("VFXManager"))

local cinModule = playerScripts:WaitForChild("UIModules"):WaitForChild("CinematicManager", 2)
local CinematicManager = cinModule and require(cinModule) or nil

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local CosmeticData = require(ReplicatedStorage:WaitForChild("CosmeticData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local hasSkillData, SkillData = pcall(function() 
	return require(ReplicatedStorage:WaitForChild("SkillData")) 
end)

-- ==========================================
-- SHARED UTILITIES & CONSTANTS
-- ==========================================
local RarityColors = { 
	["Common"] = "#AAAAAA", 
	["Uncommon"] = "#55FF55", 
	["Rare"] = "#5588FF", 
	["Epic"] = "#CC44FF", 
	["Legendary"] = "#FFD700", 
	["Mythical"] = "#FF3333", 
	["Transcendent"] = "#FF55FF" 
}
local RarityOrder = { 
	Transcendent = 0, Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 
}
local TEXT_COLORS = { 
	PrestigeYellow = "#FFD700", EloBlue = "#55AAFF", DefaultGreen = "#55FF55", DewsPink = "#FF88FF" 
}
local REG_COLORS = { 
	["Garrison"] = "#FF5555", ["Military Police"] = "#55FF55", ["Scout Regiment"] = "#55AAFF" 
}

local UnlockedCosmeticsCache = { Titles = {}, Auras = {} }
local CosmeticUIUpdaters = {}

-- [[ THE FIX: Suppress notifications entirely until DataLoaded is true ]]
local function EvaluateCosmetics()
	if type(CosmeticData.CheckUnlock) ~= "function" then return end
	local isFullyLoaded = player:GetAttribute("DataLoaded") == true

	for key, data in pairs(CosmeticData.Titles or {}) do
		local meetsReq = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue)
		if meetsReq and not UnlockedCosmeticsCache.Titles[key] then
			UnlockedCosmeticsCache.Titles[key] = true

			-- Only show the notification if their profile has finished loading
			if isFullyLoaded and NotificationManager and type(NotificationManager.Show) == "function" then 
				NotificationManager.Show("New Title Unlocked: " .. data.Name, "Success") 
			end
		end
	end

	for key, data in pairs(CosmeticData.Auras or {}) do
		local meetsReq = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue)
		if meetsReq and not UnlockedCosmeticsCache.Auras[key] then
			UnlockedCosmeticsCache.Auras[key] = true

			-- Only show the notification if their profile has finished loading
			if isFullyLoaded and NotificationManager and type(NotificationManager.Show) == "function" then 
				NotificationManager.Show("New Aura Unlocked: " .. data.Name, "Success") 
			end
		end
	end

	for _, updater in ipairs(CosmeticUIUpdaters) do 
		if type(updater) == "function" then updater() end 
	end
end

-- Instantly evaluate silently on boot to populate the cache
EvaluateCosmetics()

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	return frame, stroke
end

local function CreateSharpLabel(parent, text, size, font, color, textSize)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size = size
	lbl.BackgroundTransparency = 1
	lbl.Font = font
	lbl.TextColor3 = color
	lbl.TextSize = textSize
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	return lbl
end

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size
	btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = font
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextSize = textSize
	btn.Text = text

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.InputBegan:Connect(function() 
		stroke.Color = Color3.fromRGB(225, 185, 60)
		btn.TextColor3 = Color3.fromRGB(225, 185, 60) 
	end)

	btn.InputEnded:Connect(function() 
		stroke.Color = Color3.fromRGB(70, 70, 80)
		btn.TextColor3 = Color3.fromRGB(245, 245, 245) 
	end)

	return btn, stroke
end

local Suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx"}
local function AbbreviateNumber(n)
	if not n then return "0" end
	n = tonumber(n) or 0
	if n < 1000 then return tostring(math.floor(n)) end
	local suffixIndex = math.floor(math.log10(n) / 3)
	local value = n / (10 ^ (suffixIndex * 3))
	local str = string.format("%.1f", value)
	str = str:gsub("%.0$", "")
	return str .. (Suffixes[suffixIndex + 1] or "")
end

local function GetRankColor(rank)
	if rank == "S" then return Color3.fromRGB(255, 215, 0) 
	elseif rank == "A" then return Color3.fromRGB(85, 255, 85) 
	elseif rank == "B" then return Color3.fromRGB(85, 150, 255) 
	elseif rank == "C" then return Color3.fromRGB(170, 85, 255) 
	else return Color3.fromRGB(170, 170, 170) end
end

-- ==========================================
-- 1. IDENTITY TAB
-- ==========================================
local function BuildIdentityTab(parentFrame, cachedTooltipMgr)
	local function DrawLineScale(parent, p1x, p1y, p2x, p2y, color, thickness, zindex)
		local dx = p2x - p1x
		local dy = p2y - p1y
		local dist = math.sqrt(dx*dx + dy*dy)

		local frame = Instance.new("Frame", parent)
		frame.Size = UDim2.new(0, dist, 0, thickness)
		frame.Position = UDim2.new(0, (p1x + p2x)/2, 0, (p1y + p2y)/2)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Rotation = math.deg(math.atan2(dy, dx))
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		frame.ZIndex = zindex or 1
		return frame
	end

	local function DrawUITriangle(parent, p1, p2, p3, color, transp, zIndex)
		local edges = { {p1, p2}, {p2, p3}, {p3, p1} }
		table.sort(edges, function(a, b) return (a[1]-a[2]).Magnitude > (b[1]-b[2]).Magnitude end)

		local a, b = edges[1][1], edges[1][2]
		local c = edges[2][1] == a and edges[2][2] or edges[2][1]
		if c == b then c = edges[3][1] == a and edges[3][2] or edges[3][1] end

		local ab = b - a
		local ac = c - a
		local dir = ab.Unit
		local projLen = ac:Dot(dir)
		local proj = dir * projLen
		local h = (ac - proj).Magnitude
		local w1 = projLen
		local w2 = ab.Magnitude - projLen

		local t1 = Instance.new("ImageLabel")
		t1.BackgroundTransparency = 1
		t1.Image = "rbxassetid://319692171"
		t1.ImageColor3 = color
		t1.ImageTransparency = transp
		t1.ZIndex = zIndex
		t1.BorderSizePixel = 0
		t1.AnchorPoint = Vector2.new(0.5, 0.5)

		local t2 = t1:Clone()
		t1.Size = UDim2.new(0, w1, 0, h)
		t2.Size = UDim2.new(0, w2, 0, h)
		t1.Position = UDim2.new(0, a.X + proj.X/2, 0, a.Y + proj.Y/2)
		t2.Position = UDim2.new(0, b.X + (proj.X - ab.X)/2, 0, b.Y + (proj.Y - ab.Y)/2)
		t1.Rotation = math.deg(math.atan2(dir.Y, dir.X))
		t2.Rotation = math.deg(math.atan2(-dir.Y, -dir.X))

		t1.Parent = parent
		t2.Parent = parent
	end

	local MainScroll = Instance.new("ScrollingFrame", parentFrame)
	MainScroll.Size = UDim2.new(1, 0, 1, 0)
	MainScroll.BackgroundTransparency = 1
	MainScroll.ScrollBarThickness = 8
	MainScroll.BorderSizePixel = 0
	MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local mLayout = Instance.new("UIListLayout", MainScroll)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Padding = UDim.new(0, 15)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local mPad = Instance.new("UIPadding", MainScroll)
	mPad.PaddingTop = UDim.new(0, 10)
	mPad.PaddingBottom = UDim.new(0, 20)

	local ShowcaseCard, scStroke = CreateGrimPanel(MainScroll)
	ShowcaseCard.Size = UDim2.new(0.95, 0, 0, 280)
	ShowcaseCard.LayoutOrder = 1

	local AvatarTitle = CreateSharpLabel(ShowcaseCard, "HUMANITY'S VANGUARD", UDim2.new(1, 0, 0, 25), Enum.Font.Garamond, Color3.fromRGB(225, 185, 60), 22)
	AvatarTitle.Position = UDim2.new(0, 0, 0, 15)

	local AvatarContainer = Instance.new("Frame", ShowcaseCard)
	AvatarContainer.Size = UDim2.new(0, 140, 0, 140)
	AvatarContainer.Position = UDim2.new(0.5, 0, 0, 50)
	AvatarContainer.AnchorPoint = Vector2.new(0.5, 0)
	AvatarContainer.BackgroundTransparency = 1

	local AvatarAuraGlow = Instance.new("Frame", AvatarContainer)
	AvatarAuraGlow.Size = UDim2.new(1, 0, 1, 0)
	AvatarAuraGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	AvatarAuraGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	AvatarAuraGlow.BackgroundTransparency = 1
	Instance.new("UICorner", AvatarAuraGlow).CornerRadius = UDim.new(1, 0)

	local AvatarBox = Instance.new("ImageLabel", AvatarContainer)
	AvatarBox.Size = UDim2.new(1, 0, 1, 0)
	AvatarBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	AvatarBox.AnchorPoint = Vector2.new(0.5, 0.5)
	AvatarBox.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	AvatarBox.Image = "rbxthumb://type=AvatarBust&id="..player.UserId.."&w=420&h=420"
	AvatarBox.BorderSizePixel = 0
	AvatarBox.ZIndex = 5

	local boxCorner = Instance.new("UICorner", AvatarBox)
	boxCorner.CornerRadius = UDim.new(1, 0)
	local boxStroke = Instance.new("UIStroke", AvatarBox)
	boxStroke.Color = Color3.fromRGB(70, 70, 80)
	boxStroke.Thickness = 2

	local PlayerNameLbl = CreateSharpLabel(ShowcaseCard, string.upper(player.Name), UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 24)
	PlayerNameLbl.Position = UDim2.new(0, 0, 0, 200)

	local regIcon = Instance.new("ImageLabel", ShowcaseCard)
	regIcon.Size = UDim2.new(0, 80, 0, 80)
	regIcon.Position = UDim2.new(0, 10, 0, 10)
	regIcon.BackgroundTransparency = 1
	regIcon.ZIndex = 6

	local MidCol, mcStroke = CreateGrimPanel(MainScroll)
	MidCol.Size = UDim2.new(0.95, 0, 0, 400)
	MidCol.LayoutOrder = 2

	local RadarContainer = Instance.new("Frame", MidCol)
	RadarContainer.Size = UDim2.new(0, 200, 0, 200)
	RadarContainer.Position = UDim2.new(0.5, 0, 0, 20)
	RadarContainer.AnchorPoint = Vector2.new(0.5, 0)
	RadarContainer.BackgroundTransparency = 1

	local StatsRect, srStroke = CreateGrimPanel(MidCol)
	StatsRect.Size = UDim2.new(0.9, 0, 0, 90)
	StatsRect.Position = UDim2.new(0.5, 0, 0, 240)
	StatsRect.AnchorPoint = Vector2.new(0.5, 0)

	local srLayout = Instance.new("UIListLayout", StatsRect)
	srLayout.Padding = UDim.new(0, 6)

	local statPad = Instance.new("UIPadding", StatsRect)
	statPad.PaddingTop = UDim.new(0, 12)
	statPad.PaddingBottom = UDim.new(0, 12)
	statPad.PaddingLeft = UDim.new(0, 15)

	local function CreateInfoLabel(parent)
		local l = CreateSharpLabel(parent, "", UDim2.new(1, -15, 0, 24), Enum.Font.GothamBold, Color3.fromRGB(245, 245, 245), 14)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextWrapped = true
		return l
	end

	local titanLabel = CreateInfoLabel(StatsRect)
	titanLabel.RichText = true
	local clanLabel = CreateInfoLabel(StatsRect)
	clanLabel.RichText = true
	local regimentLabel = CreateInfoLabel(StatsRect)
	regimentLabel.RichText = true

	local ActionRow = Instance.new("Frame", MidCol)
	ActionRow.Size = UDim2.new(0.9, 0, 0, 45)
	ActionRow.Position = UDim2.new(0.5, 0, 1, -15)
	ActionRow.AnchorPoint = Vector2.new(0.5, 1)
	ActionRow.BackgroundTransparency = 1

	local toggleStatsBtn, _ = CreateSharpButton(ActionRow, "VIEW TITAN STATS", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 14)

	local TabsWrapper = Instance.new("Frame", MainScroll)
	TabsWrapper.Size = UDim2.new(0.95, 0, 0, 0)
	TabsWrapper.AutomaticSize = Enum.AutomaticSize.Y
	TabsWrapper.BackgroundTransparency = 1
	TabsWrapper.LayoutOrder = 3

	local twLayout = Instance.new("UIListLayout", TabsWrapper)
	twLayout.SortOrder = Enum.SortOrder.LayoutOrder
	twLayout.Padding = UDim.new(0, 15)

	local TopNav, tnStroke = CreateGrimPanel(TabsWrapper)
	TopNav.Size = UDim2.new(1, 0, 0, 45)
	TopNav.LayoutOrder = 1

	local SubNavScroll = Instance.new("ScrollingFrame", TopNav)
	SubNavScroll.Size = UDim2.new(1, 0, 1, 0)
	SubNavScroll.BackgroundTransparency = 1
	SubNavScroll.ScrollBarThickness = 0
	SubNavScroll.ScrollingDirection = Enum.ScrollingDirection.X

	local navLayout = Instance.new("UIListLayout", SubNavScroll)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 8)

	navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		SubNavScroll.CanvasSize = UDim2.new(0, navLayout.AbsoluteContentSize.X + 20, 0, 0) 
	end)

	local ContentArea = Instance.new("Frame", TabsWrapper)
	ContentArea.Size = UDim2.new(1, 0, 0, 0)
	ContentArea.AutomaticSize = Enum.AutomaticSize.Y
	ContentArea.BackgroundTransparency = 1
	ContentArea.LayoutOrder = 2

	local SubTabs = {}
	local SubBtns = {}

	local function CreateSubNavBtn(name, text)
		local btn, subStroke = CreateSharpButton(SubNavScroll, text, UDim2.new(0, 120, 0, 30), Enum.Font.GothamBold, 12)
		btn.TextColor3 = Color3.fromRGB(160, 160, 175)
		subStroke.Color = Color3.fromRGB(70, 70, 80)

		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do 
				v.TextColor3 = Color3.fromRGB(160, 160, 175)
				v:FindFirstChild("UIStroke").Color = Color3.fromRGB(70, 70, 80) 
			end
			btn.TextColor3 = Color3.fromRGB(245, 245, 245)
			subStroke.Color = Color3.fromRGB(225, 185, 60)

			for k, frame in pairs(SubTabs) do 
				frame.Visible = (k == name) 
			end
		end)
		SubBtns[name] = btn
		return btn
	end

	CreateSubNavBtn("Inventory", "INVENTORY")
	CreateSubNavBtn("Titles", "TITLES")
	CreateSubNavBtn("Auras", "AURAS")

	SubBtns["Inventory"].TextColor3 = Color3.fromRGB(245, 245, 245)
	SubBtns["Inventory"]:FindFirstChild("UIStroke").Color = Color3.fromRGB(225, 185, 60)

	SubTabs["Inventory"], _ = CreateGrimPanel(ContentArea)
	SubTabs["Inventory"].Size = UDim2.new(1, 0, 0, 0)
	SubTabs["Inventory"].AutomaticSize = Enum.AutomaticSize.Y
	SubTabs["Inventory"].Visible = true

	local invPadd = Instance.new("UIPadding", SubTabs["Inventory"])
	invPadd.PaddingBottom = UDim.new(0, 15)

	local InvTitle = CreateSharpLabel(SubTabs["Inventory"], "INVENTORY (0/50)", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 16)

	local FilterFrame = Instance.new("Frame", SubTabs["Inventory"])
	FilterFrame.Size = UDim2.new(1, -20, 0, 35)
	FilterFrame.Position = UDim2.new(0, 10, 0, 35)
	FilterFrame.BackgroundTransparency = 1

	local ffLayout = Instance.new("UIListLayout", FilterFrame)
	ffLayout.FillDirection = Enum.FillDirection.Horizontal
	ffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	ffLayout.Padding = UDim.new(0, 10)

	local currentInvFilter = "All"
	local FilterBtns = {}
	local RefreshProfile 

	local function MakeFilterBtn(id, text)
		local btn, stroke = CreateSharpButton(FilterFrame, text, UDim2.new(0, 60, 1, 0), Enum.Font.GothamBlack, 11)
		btn.TextColor3 = Color3.fromRGB(160, 160, 175)

		btn.MouseButton1Click:Connect(function()
			currentInvFilter = id
			for k, v in pairs(FilterBtns) do 
				v.TextColor3 = Color3.fromRGB(160, 160, 175)
				v:FindFirstChild("UIStroke").Color = Color3.fromRGB(70, 70, 80) 
			end
			btn.TextColor3 = Color3.fromRGB(245, 245, 245)
			stroke.Color = Color3.fromRGB(225, 185, 60)
			if RefreshProfile then RefreshProfile() end
		end)

		FilterBtns[id] = btn
		return btn
	end

	MakeFilterBtn("All", "ALL")
	MakeFilterBtn("Gear", "GEAR")
	MakeFilterBtn("Items", "ITEMS")

	FilterBtns["All"].TextColor3 = Color3.fromRGB(245, 245, 245)
	FilterBtns["All"]:FindFirstChild("UIStroke").Color = Color3.fromRGB(225, 185, 60)

	local AutoSellBtn, asStroke = CreateSharpButton(FilterFrame, "AUTO-SELL", UDim2.new(0, 90, 1, 0), Enum.Font.GothamBlack, 11)
	AutoSellBtn.TextColor3 = UIHelpers.Colors.TextMuted

	local AutoSellMenu = Instance.new("Frame", SubTabs["Inventory"])
	AutoSellMenu.Size = UDim2.new(1, -20, 0, 200)
	AutoSellMenu.Position = UDim2.new(0, 10, 0, 80)
	AutoSellMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	AutoSellMenu.Visible = false
	AutoSellMenu.ZIndex = 20
	Instance.new("UIStroke", AutoSellMenu).Color = UIHelpers.Colors.Gold

	local asTitle = UIHelpers.CreateLabel(AutoSellMenu, "AUTO-SELL SETTINGS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)

	local asList = Instance.new("Frame", AutoSellMenu)
	asList.Size = UDim2.new(1, 0, 1, -40)
	asList.Position = UDim2.new(0, 0, 0, 35)
	asList.BackgroundTransparency = 1

	local asLayout = Instance.new("UIListLayout", asList)
	asLayout.Padding = UDim.new(0, 6)
	asLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function CreateASRow(rarityName, hexColor)
		local row = Instance.new("Frame", asList)
		row.Size = UDim2.new(0.9, 0, 0, 30)
		row.BackgroundTransparency = 1

		local lbl = UIHelpers.CreateLabel(row, rarityName:upper(), UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, Color3.fromHex(hexColor:gsub("#","")), 14)
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local tBtn, tStrk = CreateSharpButton(row, "OFF", UDim2.new(0.35, 0, 1, 0), Enum.Font.GothamBlack, 12)
		tBtn.Position = UDim2.new(1, 0, 0, 0)
		tBtn.AnchorPoint = Vector2.new(1, 0)

		local function updateBtn()
			if player:GetAttribute("AutoSell_" .. rarityName) then 
				tBtn.Text = "ON"
				tBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
				tStrk.Color = Color3.fromRGB(100, 255, 100)
			else 
				tBtn.Text = "OFF"
				tBtn.TextColor3 = UIHelpers.Colors.TextMuted
				tStrk.Color = Color3.fromRGB(70, 70, 80) 
			end
		end
		updateBtn()

		tBtn.MouseButton1Click:Connect(function() 
			Network:WaitForChild("AutoSell"):FireServer(rarityName) 
		end)
		player.AttributeChanged:Connect(function(attr) 
			if attr == "AutoSell_" .. rarityName then updateBtn() end 
		end)
	end

	CreateASRow("Common", RarityColors["Common"])
	CreateASRow("Uncommon", RarityColors["Uncommon"])
	CreateASRow("Rare", RarityColors["Rare"])
	CreateASRow("Epic", RarityColors["Epic"])

	AutoSellBtn.MouseButton1Click:Connect(function() 
		AutoSellMenu.Visible = not AutoSellMenu.Visible 
	end)

	local InvGrid = Instance.new("Frame", SubTabs["Inventory"])
	InvGrid.Size = UDim2.new(1, -10, 0, 0)
	InvGrid.AutomaticSize = Enum.AutomaticSize.Y
	InvGrid.Position = UDim2.new(0, 5, 0, 80)
	InvGrid.BackgroundTransparency = 1
	InvGrid.BorderSizePixel = 0

	local gl = Instance.new("UIGridLayout", InvGrid)
	gl.CellSize = UDim2.new(0, 100, 0, 100)
	gl.CellPadding = UDim2.new(0, 12, 0, 15)
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gl.SortOrder = Enum.SortOrder.LayoutOrder

	SubTabs["Titles"] = Instance.new("Frame", ContentArea)
	SubTabs["Titles"].Size = UDim2.new(1, 0, 0, 0)
	SubTabs["Titles"].AutomaticSize = Enum.AutomaticSize.Y
	SubTabs["Titles"].BackgroundTransparency = 1
	SubTabs["Titles"].Visible = false
	SubTabs["Titles"].BorderSizePixel = 0

	local tLayout = Instance.new("UIListLayout", SubTabs["Titles"])
	tLayout.Padding = UDim.new(0, 12)
	tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local tPad = Instance.new("UIPadding", SubTabs["Titles"])
	tPad.PaddingTop = UDim.new(0, 10)
	tPad.PaddingBottom = UDim.new(0, 20)

	SubTabs["Auras"] = Instance.new("Frame", ContentArea)
	SubTabs["Auras"].Size = UDim2.new(1, 0, 0, 0)
	SubTabs["Auras"].AutomaticSize = Enum.AutomaticSize.Y
	SubTabs["Auras"].BackgroundTransparency = 1
	SubTabs["Auras"].Visible = false
	SubTabs["Auras"].BorderSizePixel = 0

	local aLayout = Instance.new("UIListLayout", SubTabs["Auras"])
	aLayout.Padding = UDim.new(0, 12)
	aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local aPad = Instance.new("UIPadding", SubTabs["Auras"])
	aPad.PaddingTop = UDim.new(0, 10)
	aPad.PaddingBottom = UDim.new(0, 20)

	local function BuildCosmeticList(tab, typeKey, dataPool)
		local sorted = {}
		for key, data in pairs(dataPool or {}) do 
			table.insert(sorted, {Key = key, Data = data}) 
		end
		table.sort(sorted, function(a, b) return a.Data.Order < b.Data.Order end)

		for _, item in ipairs(sorted) do
			local card, cStroke = CreateGrimPanel(tab)
			card.Size = UDim2.new(0.95, 0, 0, 85)
			card.LayoutOrder = item.Data.Order

			local cColor = Color3.fromRGB(255,255,255)
			if typeKey == "Title" then 
				cColor = Color3.fromHex((item.Data.Color or "#FFFFFF"):gsub("#", "")) 
			else 
				cColor = Color3.fromHex((item.Data.Color1 or "#FFFFFF"):gsub("#", "")) 
			end

			local title = CreateSharpLabel(card, item.Data.Name, UDim2.new(1, -110, 0, 30), Enum.Font.GothamBlack, cColor, 16)
			title.Position = UDim2.new(0, 15, 0, 5)
			title.TextXAlignment = Enum.TextXAlignment.Left

			local desc = CreateSharpLabel(card, item.Data.