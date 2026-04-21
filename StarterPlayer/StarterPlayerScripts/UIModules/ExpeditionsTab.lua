-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ExpeditionsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Network = ReplicatedStorage:WaitForChild("Network")

local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local AFKTab = require(script.Parent:WaitForChild("AFKTab"))
local NotificationManager = require(SharedUI:WaitForChild("NotificationManager"))
local LabyrinthUI = require(script.Parent:WaitForChild("LabyrinthUI"))

local player = Players.LocalPlayer

local CONFIG = {
	Decals = {
		Campaign = "rbxassetid://80153476985849",
		AFK = "rbxassetid://114506098039778",
		Raid = "rbxassetid://119392967268687",
		PvP = "rbxassetid://100826303284945", 
		Nightmare = "rbxassetid://90132878979603",
		WorldBoss = "rbxassetid://129655150803684",
		Endless = "rbxassetid://81075056647024",
		Paths = "rbxassetid://90938848776194",
		Labyrinth = "rbxassetid://90132878979603",

		MapOcean = "rbxassetid://13583561330",
		MapGrid = "rbxassetid://6500548545", 
		MapFog = "rbxassetid://13835698889",
		HexZone = "rbxassetid://14457173664",
		GlowOrb = "rbxassetid://1311282431", 

		MapMarker = "rbxassetid://000000000", -- Optional Icon ID

		Country_Trost = "rbxassetid://122199458494734", 
		Country_Forest = "rbxassetid://104188447571196",
		Country_Utgard = "rbxassetid://2045145074",
		Country_Wasteland = "rbxassetid://114860169884875",
		Country_Shoreline = "rbxassetid://83678968235830",
		Country_Marley = "rbxassetid://5058208354",
	}
}

local CurrentParty = {}
local IsInParty = false
local IsPartyLeader = false
local PendingInvites = {}
local isListening = false

local function AbbreviateNumber(n)
	local Suffixes = {"", "K", "M", "B", "T", "Qa"}
	if not n then return "0" end; n = tonumber(n) or 0
	if n < 1000 then return tostring(math.floor(n)) end
	local suffixIndex = math.floor(math.log10(n) / 3); local value = n / (10 ^ (suffixIndex * 3))
	local str = string.format("%.1f", value); str = str:gsub("%.0$", "")
	return str .. (Suffixes[suffixIndex + 1] or "")
end

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent); btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.MouseEnter:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

local function GetSquadColor(squadName, isMine)
	if isMine then return UIHelpers.Colors.Gold end 
	if not squadName or squadName == "Unclaimed" or squadName == "None" then return Color3.fromRGB(120, 120, 120) end
	if squadName == "Marleyan Scouts" or squadName == "Pure Titans" then return Color3.fromRGB(200, 20, 20) end

	local hash = 0
	for i = 1, #squadName do hash = hash + string.byte(squadName, i) end
	math.randomseed(hash)
	local r, g, b = math.random(100, 255), math.random(100, 255), math.random(100, 255)
	return Color3.fromRGB(r, g, b)
end

function ExpeditionsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MasterLayout = Instance.new("UIListLayout", parentFrame)
	MasterLayout.FillDirection = Enum.FillDirection.Horizontal; MasterLayout.SortOrder = Enum.SortOrder.LayoutOrder; MasterLayout.Padding = UDim.new(0, 20)

	local MissionsPanel = Instance.new("Frame", parentFrame)
	MissionsPanel.Size = UDim2.new(0.68, 0, 1, 0); MissionsPanel.BackgroundTransparency = 1; MissionsPanel.LayoutOrder = 1
	local mPad = Instance.new("UIPadding", MissionsPanel); mPad.PaddingLeft = UDim.new(0.02, 0)

	local HeaderFrame = Instance.new("Frame", MissionsPanel)
	HeaderFrame.Size = UDim2.new(1, 0, 0, 50); HeaderFrame.BackgroundTransparency = 1; HeaderFrame.ZIndex = 10

	local Title = UIHelpers.CreateLabel(HeaderFrame, "COMBAT DEPLOYMENT", UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22)
	Title.Position = UDim2.new(0, 0, 0, 0); Title.TextXAlignment = Enum.TextXAlignment.Left

	local TabNavFrame = Instance.new("Frame", HeaderFrame)
	TabNavFrame.Size = UDim2.new(0.4, 0, 0, 30); TabNavFrame.Position = UDim2.new(1, 0, 0.5, 0); TabNavFrame.AnchorPoint = Vector2.new(1, 0.5); TabNavFrame.BackgroundTransparency = 1

	local TabNavLayout = Instance.new("UIListLayout", TabNavFrame)
	TabNavLayout.FillDirection = Enum.FillDirection.Horizontal; TabNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; TabNavLayout.Padding = UDim.new(0, 10)

	local MissionsTabBtn, MissionsTabStroke = CreateSharpButton(TabNavFrame, "MISSIONS", UDim2.new(0, 100, 1, 0), Enum.Font.GothamBlack, 12)
	local WorldMapTabBtn, WorldMapTabStroke = CreateSharpButton(TabNavFrame, "WORLD MAP", UDim2.new(0, 100, 1, 0), Enum.Font.GothamBlack, 12)

	local BackBtn, BackStroke = CreateSharpButton(HeaderFrame, "< BACK", UDim2.new(0, 80, 0, 30), Enum.Font.GothamBlack, 12)
	BackBtn.Position = UDim2.new(1, -220, 0.5, 0); BackBtn.AnchorPoint = Vector2.new(1, 0.5); BackBtn.Visible = false

	local Pages = {}
	local MainViewContainer = Instance.new("Frame", MissionsPanel)
	MainViewContainer.Size = UDim2.new(1, 0, 1, -60); MainViewContainer.Position = UDim2.new(0, 0, 0, 50); MainViewContainer.BackgroundTransparency = 1

	local FetchLiveMapData

	local function ShowPage(pageName, titleText)
		for name, frame in pairs(Pages) do frame.Visible = (name == pageName) end
		if titleText then Title.Text = titleText end

		local isBasePage = (pageName == "Main" or pageName == "WorldMap")
		BackBtn.Visible = not isBasePage
		TabNavFrame.Visible = isBasePage

		if pageName == "Main" then
			MissionsTabStroke.Color = UIHelpers.Colors.Gold; MissionsTabBtn.TextColor3 = UIHelpers.Colors.Gold
			WorldMapTabStroke.Color = UIHelpers.Colors.BorderMuted; WorldMapTabBtn.TextColor3 = UIHelpers.Colors.TextWhite
		elseif pageName == "WorldMap" then
			WorldMapTabStroke.Color = UIHelpers.Colors.Gold; WorldMapTabBtn.TextColor3 = UIHelpers.Colors.Gold
			MissionsTabStroke.Color = UIHelpers.Colors.BorderMuted; MissionsTabBtn.TextColor3 = UIHelpers.Colors.TextWhite
			if FetchLiveMapData then FetchLiveMapData() end
		end
	end

	MissionsTabBtn.MouseButton1Click:Connect(function() ShowPage("Main", "COMBAT DEPLOYMENT") end)
	WorldMapTabBtn.MouseButton1Click:Connect(function() ShowPage("WorldMap", "TERRITORY CONTROL") end)
	BackBtn.MouseButton1Click:Connect(function() ShowPage("Main", "COMBAT DEPLOYMENT") end)

	local DeployOverlay = Instance.new("Frame", parentFrame.Parent) 
	DeployOverlay.Name = "DeploymentTransition"; DeployOverlay.Size = UDim2.new(1, 0, 1, 0); DeployOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 15); DeployOverlay.BackgroundTransparency = 1; DeployOverlay.ZIndex = 90; DeployOverlay.Visible = false
	local dStatus = UIHelpers.CreateLabel(DeployOverlay, "ESTABLISHING CONNECTION...", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	dStatus.Position = UDim2.new(0, 0, 0.5, -20); dStatus.TextTransparency = 1; dStatus.ZIndex = 91

	local function InitiateDeployment(remoteName, action, payload)
		DeployOverlay.Visible = true
		TweenService:Create(DeployOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.1}):Play()
		TweenService:Create(dStatus, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		dStatus.Text = "PREPARING STRIKE TEAM..."; task.wait(0.6)
		dStatus.Text = "DEPLOYING TO COMBAT ZONE..."; dStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
		task.wait(0.8)
		if payload then Network:WaitForChild(remoteName):FireServer(action, payload) else Network:WaitForChild(remoteName):FireServer(action) end
		local t1 = TweenService:Create(DeployOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		local t2 = TweenService:Create(dStatus, TweenInfo.new(0.5), {TextTransparency = 1})
		t1:Play(); t2:Play(); t1.Completed:Wait()
		DeployOverlay.Visible = false; dStatus.TextColor3 = UIHelpers.Colors.Gold
	end

	local MissionsBasePage = Instance.new("Frame", MainViewContainer)
	MissionsBasePage.Size = UDim2.new(1, 0, 1, 0); MissionsBasePage.BackgroundTransparency = 1; MissionsBasePage.Visible = true
	Pages["Main"] = MissionsBasePage

	local GridContainer = Instance.new("ScrollingFrame", MissionsBasePage)
	GridContainer.Size = UDim2.new(1, 0, 1, 0); GridContainer.Position = UDim2.new(0, 0, 0, 0); GridContainer.BackgroundTransparency = 1; GridContainer.ScrollBarThickness = 6; GridContainer.BorderSizePixel = 0
	local gridLayout = Instance.new("UIGridLayout", GridContainer); gridLayout.CellSize = UDim2.new(0.48, 0, 0, 150); gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 15); gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() GridContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 40) end)


	-- ==========================================
	-- WORLD MAP: TACTICAL WEB ENGINE
	-- ==========================================
	local WorldMapPage = Instance.new("Frame", MainViewContainer)
	WorldMapPage.Size = UDim2.new(1, 0, 1, 0); WorldMapPage.BackgroundColor3 = Color3.fromRGB(10, 10, 12); WorldMapPage.ClipsDescendants = true; WorldMapPage.Visible = false
	Pages["WorldMap"] = WorldMapPage
	local wmStroke = Instance.new("UIStroke", WorldMapPage); wmStroke.Color = UIHelpers.Colors.BorderMuted; wmStroke.Thickness = 2

	local MapZoom = 2.5 
	local MapCanvas = Instance.new("Frame", WorldMapPage)
	MapCanvas.Size = UDim2.new(MapZoom, 0, MapZoom, 0); MapCanvas.Position = UDim2.new(-0.5, 0, -0.5, 0)
	MapCanvas.BackgroundColor3 = Color3.fromRGB(12, 12, 16)

	local BaseMap = Instance.new("ImageLabel", MapCanvas)
	BaseMap.Size = UDim2.new(1, 0, 1, 0); BaseMap.BackgroundTransparency = 1; BaseMap.Image = CONFIG.Decals.MapOcean
	BaseMap.ScaleType = Enum.ScaleType.Crop; BaseMap.ImageColor3 = Color3.fromRGB(100, 100, 110) 

	local MapGrid = Instance.new("ImageLabel", MapCanvas)
	MapGrid.Size = UDim2.new(1, 0, 1, 0); MapGrid.BackgroundTransparency = 1; MapGrid.Image = CONFIG.Decals.MapGrid
	MapGrid.ScaleType = Enum.ScaleType.Tile; MapGrid.TileSize = UDim2.new(0, 200, 0, 200)
	MapGrid.ImageColor3 = Color3.fromRGB(0, 0, 0); MapGrid.ImageTransparency = 0.5; MapGrid.ZIndex = 2

	local CountryLayer = Instance.new("Frame", MapCanvas)
	CountryLayer.Size = UDim2.new(1, 0, 1, 0); CountryLayer.BackgroundTransparency = 1; CountryLayer.ZIndex = 3

	local function RenderCountryDecal(imageId)
		local cImage = Instance.new("ImageLabel", CountryLayer)
		cImage.Size = UDim2.new(1, 0, 1, 0); cImage.BackgroundTransparency = 1; cImage.Image = imageId
		cImage.ImageColor3 = Color3.fromRGB(60, 60, 65); cImage.ImageTransparency = 0.2
	end

	RenderCountryDecal(CONFIG.Decals.Country_Trost)
	RenderCountryDecal(CONFIG.Decals.Country_Forest)
	RenderCountryDecal(CONFIG.Decals.Country_Utgard)
	RenderCountryDecal(CONFIG.Decals.Country_Wasteland)
	RenderCountryDecal(CONFIG.Decals.Country_Shoreline)
	RenderCountryDecal(CONFIG.Decals.Country_Marley)

	local Vignette = Instance.new("Frame", WorldMapPage)
	Vignette.Size = UDim2.new(1, 0, 1, 0); Vignette.BackgroundTransparency = 0.1; Vignette.ZIndex = 15; Vignette.Interactable = false
	local vGrad = Instance.new("UIGradient", Vignette); vGrad.Color = ColorSequence.new(Color3.new(0,0,0)); vGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.05, 0.8), NumberSequenceKeypoint.new(0.95, 0.8), NumberSequenceKeypoint.new(1, 0)
	}); vGrad.Rotation = 90

	local function ClampMapPosition(posX, posY)
		local parentSize = WorldMapPage.AbsoluteSize; local canvasSize = MapCanvas.AbsoluteSize
		if canvasSize.X <= parentSize.X then posX = 0 else posX = math.clamp(posX, parentSize.X - canvasSize.X, 0) end
		if canvasSize.Y <= parentSize.Y then posY = 0 else posY = math.clamp(posY, parentSize.Y - canvasSize.Y, 0) end
		return posX, posY
	end

	local dragging = false; local dragStart; local startPos = Vector2.new()

	MapCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = Vector2.new(MapCanvas.Position.X.Offset, MapCanvas.Position.Y.Offset)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			local newX, newY = ClampMapPosition(startPos.X + delta.X, startPos.Y + delta.Y)
			MapCanvas.Position = UDim2.new(0, newX, 0, newY)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	MapCanvas.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			MapZoom = math.clamp(MapZoom + (input.Position.Z * 0.15), 1, 5)
			MapCanvas.Size = UDim2.new(MapZoom, 0, MapZoom, 0)
			task.defer(function()
				local newX, newY = ClampMapPosition(MapCanvas.Position.X.Offset, MapCanvas.Position.Y.Offset)
				MapCanvas.Position = UDim2.new(0, newX, 0, newY)
			end)
		end
	end)
	WorldMapPage:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local newX, newY = ClampMapPosition(MapCanvas.Position.X.Offset, MapCanvas.Position.Y.Offset)
		MapCanvas.Position = UDim2.new(0, newX, 0, newY)
	end)

	-- ==========================================
	-- NODE SIDE PANEL (SINGLE BUTTON EDITION)
	-- ==========================================
	local NodePanel = Instance.new("Frame", WorldMapPage)
	NodePanel.Size = UDim2.new(0, 250, 1, 0); NodePanel.Position = UDim2.new(1, 0, 0, 0); NodePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18); NodePanel.ZIndex = 20
	local npStroke = Instance.new("UIStroke", NodePanel); npStroke.Color = UIHelpers.Colors.BorderMuted; npStroke.Thickness = 2
	local NodeTitle = UIHelpers.CreateLabel(NodePanel, "NODE INFO", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); NodeTitle.Position = UDim2.new(0, 10, 0, 10); NodeTitle.TextXAlignment = Enum.TextXAlignment.Left
	local NodeOwner = UIHelpers.CreateLabel(NodePanel, "Owner: Unclaimed", UDim2.new(1, -20, 0, 40), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14); NodeOwner.Position = UDim2.new(0, 10, 0, 40); NodeOwner.TextXAlignment = Enum.TextXAlignment.Left; NodeOwner.TextWrapped = true

	local ActionBtn, _ = CreateSharpButton(NodePanel, "LAUNCH ASSAULT", UDim2.new(1, -20, 0, 45), Enum.Font.GothamBlack, 14); ActionBtn.Position = UDim2.new(0, 10, 0, 90)
	local ClosePanelBtn, _ = CreateSharpButton(NodePanel, "CLOSE", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBold, 12); ClosePanelBtn.Position = UDim2.new(0, 10, 1, -40); ClosePanelBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	ClosePanelBtn.MouseButton1Click:Connect(function() TweenService:Create(NodePanel, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Position = UDim2.new(1, 0, 0, 0)}):Play() end)

	local ActiveSelectedNodeId = nil

	ActionBtn.MouseButton1Click:Connect(function()
		if ActiveSelectedNodeId then
			if string.find(ActionBtn.Text, "FORTIFY") then
				Network:WaitForChild("MapAction"):FireServer("InteractNode", "Fortify", {NodeId = ActiveSelectedNodeId})
			else
				InitiateDeployment("CombatAction", "EngageTerritory", {NodeId = ActiveSelectedNodeId, Action = "Assault"}) 
			end
		end
	end)

	local SupplyLineLayer = Instance.new("Frame", MapCanvas); SupplyLineLayer.Size = UDim2.new(1, 0, 1, 0); SupplyLineLayer.BackgroundTransparency = 1; SupplyLineLayer.ZIndex = 3
	local GlowLayer = Instance.new("Frame", MapCanvas); GlowLayer.Size = UDim2.new(1, 0, 1, 0); GlowLayer.BackgroundTransparency = 1; GlowLayer.ZIndex = 4
	local CapitalPinsLayer = Instance.new("Frame", MapCanvas); CapitalPinsLayer.Size = UDim2.new(1, 0, 1, 0); CapitalPinsLayer.BackgroundTransparency = 1; CapitalPinsLayer.ZIndex = 5

	local AllVisualNodes = {}
	local LiveMapData = {} 

	local TerritoryData = {
		{Id = "N1", Name = "Mitras Capital", Reg = "Interior", Pos = UDim2.new(0.5,0, 0.5,0)},
		{Id = "N2", Name = "Hermiha District", Reg = "Wall Sina", Pos = UDim2.new(0.42,0, 0.42,0)},
		{Id = "N3", Name = "Yarckel District", Reg = "Wall Sina", Pos = UDim2.new(0.58,0, 0.42,0)},
		{Id = "N4", Name = "Stohess District", Reg = "Wall Sina", Pos = UDim2.new(0.58,0, 0.58,0)},
		{Id = "N5", Name = "Ehrmich District", Reg = "Wall Sina", Pos = UDim2.new(0.42,0, 0.58,0)},
		{Id = "N6", Name = "Utopia District", Reg = "Wall Rose", Pos = UDim2.new(0.3,0, 0.3,0)},
		{Id = "N7", Name = "Karanes District", Reg = "Wall Rose", Pos = UDim2.new(0.7,0, 0.3,0)},
		{Id = "N8", Name = "Trost District", Reg = "Wall Rose", Pos = UDim2.new(0.7,0, 0.7,0)},
		{Id = "N9", Name = "Krolva District", Reg = "Wall Rose", Pos = UDim2.new(0.3,0, 0.7,0)},
		{Id = "N10", Name = "Rose Breach Site", Reg = "Wall Rose", Pos = UDim2.new(0.5,0, 0.75,0)},
		{Id = "N11", Name = "Shiganshina", Reg = "Wall Maria", Pos = UDim2.new(0.5,0, 0.85,0)},
		{Id = "N12", Name = "Quinta District", Reg = "Wall Maria", Pos = UDim2.new(0.15,0, 0.3,0)},
		{Id = "N13", Name = "Giant Forest Base", Reg = "Titan Wilds", Pos = UDim2.new(0.85,0, 0.5,0)},
		{Id = "N14", Name = "Utgard Castle", Reg = "Titan Wilds", Pos = UDim2.new(0.15,0, 0.7,0)},
		{Id = "N15", Name = "Titan Graveyard", Reg = "The Wasteland", Pos = UDim2.new(0.85,0, 0.25,0)},
		{Id = "N16", Name = "Abandoned Outpost", Reg = "The Wasteland", Pos = UDim2.new(0.75,0, 0.1,0)},
		{Id = "N17", Name = "Scout Camp", Reg = "Titan Wilds", Pos = UDim2.new(0.25,0, 0.15,0)},
		{Id = "N18", Name = "Shifter's Crag", Reg = "The Wasteland", Pos = UDim2.new(0.1,0, 0.5,0)},
		{Id = "N19", Name = "Cursed Ridge", Reg = "The Wasteland", Pos = UDim2.new(0.9,0, 0.75,0)},
		{Id = "N20", Name = "Southern Valley", Reg = "Titan Wilds", Pos = UDim2.new(0.35,0, 0.9,0)},
		{Id = "N21", Name = "Paradis Port", Reg = "Shoreline", Pos = UDim2.new(0.9,0, 0.9,0)},
		{Id = "N22", Name = "Intercept Fleet", Reg = "Ocean", Pos = UDim2.new(0.95,0, 0.6,0)},
		{Id = "N23", Name = "Fort Slava", Reg = "Mainland", Pos = UDim2.new(0.05,0, 0.1,0)},
		{Id = "N24", Name = "Liberio Zone", Reg = "Mainland", Pos = UDim2.new(0.05,0, 0.3,0)},
		{Id = "N25", Name = "Tybur Estate", Reg = "Mainland", Pos = UDim2.new(0.05,0, 0.8,0)},
	}

	for _, baseData in ipairs(TerritoryData) do
		local pinWrap = Instance.new("Frame", CapitalPinsLayer)
		pinWrap.Size = UDim2.new(0, 0, 0, 0); pinWrap.Position = baseData.Pos; pinWrap.BackgroundTransparency = 1

		local glow = Instance.new("ImageLabel", GlowLayer)
		glow.Size = UDim2.new(0, 180, 0, 180); glow.Position = baseData.Pos; glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundTransparency = 1; glow.Image = CONFIG.Decals.GlowOrb; glow.ImageTransparency = 0.5
		glow.ImageColor3 = Color3.fromRGB(30, 30, 35)

		local pinBtn = Instance.new("TextButton", pinWrap)
		pinBtn.Size = UDim2.new(0, 24, 0, 24); pinBtn.Position = UDim2.new(0, 0, 0, 0); pinBtn.AnchorPoint = Vector2.new(0.5, 0.5)
		pinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); pinBtn.Rotation = 45; pinBtn.Text = ""; pinBtn.AutoButtonColor = false
		local pStroke = Instance.new("UIStroke", pinBtn); pStroke.Color = Color3.fromRGB(120, 120, 120); pStroke.Thickness = 2; pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local pulse = Instance.new("Frame", pinBtn); pulse.Size = UDim2.new(1, 0, 1, 0); pulse.BackgroundColor3 = Color3.fromRGB(255, 0, 0); pulse.BackgroundTransparency = 1; pulse.BorderSizePixel = 0
		local pulseTween = TweenService:Create(pulse, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.4, Size = UDim2.new(2.0,0,2.0,0), Position = UDim2.new(-0.5,0,-0.5,0)})

		local lblTitle = UIHelpers.CreateLabel(pinWrap, string.upper(baseData.Name), UDim2.new(0, 200, 0, 15), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
		lblTitle.Position = UDim2.new(0, 20, 0.5, -5); lblTitle.AnchorPoint = Vector2.new(0, 0.5); lblTitle.TextXAlignment = Enum.TextXAlignment.Left
		local textShadow = Instance.new("UIStroke", lblTitle); textShadow.Color = Color3.new(0,0,0); textShadow.Thickness = 2

		local lblReg = UIHelpers.CreateLabel(pinWrap, string.upper(baseData.Reg), UDim2.new(0, 200, 0, 10), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 10)
		lblReg.Position = UDim2.new(0, 20, 0.5, 10); lblReg.AnchorPoint = Vector2.new(0, 0.5); lblReg.TextXAlignment = Enum.TextXAlignment.Left
		local regShadow = Instance.new("UIStroke", lblReg); regShadow.Color = Color3.new(0,0,0); regShadow.Thickness = 1.5

		pinBtn.MouseButton1Click:Connect(function()
			local serverState = LiveMapData[baseData.Id] or {Owned = false, OwnerName = "Unclaimed", UnderAttack = false, Health = 100, MaxHealth = 100}
			ActiveSelectedNodeId = baseData.Id
			NodeTitle.Text = string.upper(baseData.Name)
			NodeOwner.Text = "Owner: " .. serverState.OwnerName .. "\nHealth: " .. (serverState.Health or 100) .. "/" .. (serverState.MaxHealth or 100)

			if serverState.Owned then 
				NodeOwner.TextColor3 = UIHelpers.Colors.Gold
				ActionBtn.Text = "FORTIFY SECTOR (100k Dews)"
				ActionBtn.TextColor3 = UIHelpers.Colors.Gold
			else 
				NodeOwner.TextColor3 = (serverState.UnderAttack) and Color3.fromRGB(255, 50, 50) or UIHelpers.Colors.TextMuted
				ActionBtn.Text = "LAUNCH ASSAULT"
				ActionBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
			end
			TweenService:Create(NodePanel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -250, 0, 0)}):Play()
		end)

		AllVisualNodes[baseData.Id] = {
			Data = baseData, Wrap = pinWrap, Glow = glow, Pin = pinBtn, Stroke = pStroke, Pulse = pulse, PulseTween = pulseTween
		}
	end

	local function UpdateVisualMapState()
		for id, nodeUI in pairs(AllVisualNodes) do
			local state = LiveMapData[id] or {Owned = false, OwnerName = "Unclaimed", UnderAttack = false}
			local sColor = GetSquadColor(state.OwnerName, state.Owned)

			if state.UnderAttack then
				nodeUI.Stroke.Color = Color3.fromRGB(255, 50, 50)
				nodeUI.Pin.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
				nodeUI.Glow.ImageColor3 = Color3.fromRGB(255, 0, 0)
				nodeUI.Glow.ImageTransparency = 0.3
				nodeUI.PulseTween:Play()
			else
				nodeUI.Stroke.Color = sColor
				nodeUI.Pin.BackgroundColor3 = Color3.fromRGB(sColor.R * 255 * 0.3, sColor.G * 255 * 0.3, sColor.B * 255 * 0.3)
				nodeUI.Glow.ImageColor3 = sColor
				nodeUI.Glow.ImageTransparency = (state.OwnerName == "Unclaimed") and 0.8 or 0.3
				nodeUI.Pulse.BackgroundTransparency = 1
				nodeUI.PulseTween:Cancel()
			end
		end

		for _, child in ipairs(SupplyLineLayer:GetChildren()) do child:Destroy() end

		local DrawnLines = {}
		for i, nA in pairs(AllVisualNodes) do
			local neighbors = {}
			for j, nB in pairs(AllVisualNodes) do
				if nA.Data.Id ~= nB.Data.Id then
					local pA = Vector2.new(nA.Data.Pos.X.Scale, nA.Data.Pos.Y.Scale)
					local pB = Vector2.new(nB.Data.Pos.X.Scale, nB.Data.Pos.Y.Scale)
					table.insert(neighbors, {Node = nB, Dist = (pA - pB).Magnitude})
				end
			end
			table.sort(neighbors, function(a, b) return a.Dist < b.Dist end)

			for k = 1, 2 do 
				local target = neighbors[k].Node
				local linkKey = (nA.Data.Id < target.Data.Id) and (nA.Data.Id .. "_" .. target.Data.Id) or (target.Data.Id .. "_" .. nA.Data.Id)
				if not DrawnLines[linkKey] then
					DrawnLines[linkKey] = {nA, target}
				end
			end
		end

		for _, pair in pairs(DrawnLines) do
			local nA, nB = pair[1], pair[2]
			local stateA = LiveMapData[nA.Data.Id] or {Owned = false}
			local stateB = LiveMapData[nB.Data.Id] or {Owned = false}
			local isSafeRoute = (stateA.Owned and stateB.Owned)

			local line = Instance.new("Frame", SupplyLineLayer)
			line.BackgroundColor3 = isSafeRoute and UIHelpers.Colors.Gold or Color3.fromRGB(50, 50, 55); line.BorderSizePixel = 0

			local posA = Vector2.new(nA.Data.Pos.X.Scale, nA.Data.Pos.Y.Scale)
			local posB = Vector2.new(nB.Data.Pos.X.Scale, nB.Data.Pos.Y.Scale)
			local center = UDim2.new((posA.X + posB.X)/2, 0, (posA.Y + posB.Y)/2, 0)
			line.Position = center; line.AnchorPoint = Vector2.new(0.5, 0.5); line.Rotation = math.deg(math.atan2(posB.Y - posA.Y, posB.X - posA.X))

			local function updateLine()
				local cSize = MapCanvas.AbsoluteSize
				local p1 = Vector2.new(posA.X * cSize.X, posA.Y * cSize.Y)
				local p2 = Vector2.new(posB.X * cSize.X, posB.Y * cSize.Y)
				line.Size = UDim2.new(0, (p1 - p2).Magnitude, 0, isSafeRoute and 4 or 2)
			end
			MapCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLine); updateLine()

			if not isSafeRoute then 
				local dash = Instance.new("UIStroke", line); dash.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; dash.LineJoinMode = Enum.LineJoinMode.Miter; dash.Thickness = 1; dash.Color = Color3.fromRGB(15,15,18) 
			end
		end
	end

	FetchLiveMapData = function()
		task.spawn(function()
			local serverData = Network:WaitForChild("GetMapData"):InvokeServer()
			if serverData and type(serverData) == "table" then
				LiveMapData = serverData
				UpdateVisualMapState()
			end
		end)
	end

	Network:WaitForChild("MapUpdate").OnClientEvent:Connect(function(updatedMapTable)
		if updatedMapTable and type(updatedMapTable) == "table" then
			LiveMapData = updatedMapTable
			UpdateVisualMapState()
		end
	end)

	UpdateVisualMapState()

	-- ==========================================
	-- RIGHT PANEL: PARTY SYSTEM 
	-- ==========================================
	local PartyPanel = Instance.new("Frame", parentFrame)
	PartyPanel.Size = UDim2.new(0.28, 0, 1, -20); PartyPanel.Position = UDim2.new(0, 0, 0, 10); PartyPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18); PartyPanel.LayoutOrder = 2
	local pStroke = Instance.new("UIStroke", PartyPanel); pStroke.Color = UIHelpers.Colors.BorderMuted; pStroke.Thickness = 2

	local PartyContent = Instance.new("Frame", PartyPanel)
	PartyContent.Size = UDim2.new(1, -30, 1, -30); PartyContent.Position = UDim2.new(0, 15, 0, 15); PartyContent.BackgroundTransparency = 1

	local function RenderPartyUI()
		for _, child in ipairs(PartyContent:GetChildren()) do child:Destroy() end
		local pLayout = Instance.new("UIListLayout", PartyContent); pLayout.SortOrder = Enum.SortOrder.LayoutOrder; pLayout.Padding = UDim.new(0, 15); pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		if IsInParty then
			local Header = UIHelpers.CreateLabel(PartyContent, "STRIKE TEAM (" .. #CurrentParty .. "/3)", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); Header.LayoutOrder = 1; Header.TextXAlignment = Enum.TextXAlignment.Left
			local RosterFrame = Instance.new("Frame", PartyContent); RosterFrame.Size = UDim2.new(1, 0, 0, #CurrentParty * 50); RosterFrame.BackgroundTransparency = 1; RosterFrame.LayoutOrder = 2
			local rLayout = Instance.new("UIListLayout", RosterFrame); rLayout.Padding = UDim.new(0, 8)

			for _, member in ipairs(CurrentParty) do
				local mCard = Instance.new("Frame", RosterFrame); mCard.Size = UDim2.new(1, 0, 0, 42); mCard.BackgroundColor3 = Color3.fromRGB(25, 25, 30); local mStroke = Instance.new("UIStroke", mCard); mStroke.Color = UIHelpers.Colors.BorderMuted

				-- Safe verification
				local isMemDict = (type(member) == "table" and typeof(member) ~= "Instance")
				local memName = isMemDict and member.Name or member.Name
				local memIsLeader = isMemDict and member.IsLeader or false
				local memIsFavored = isMemDict and member.IsYmirsFavored or false

				local nameColor = memIsFavored and Color3.fromRGB(100, 150, 255) or UIHelpers.Colors.TextWhite
				local mName = UIHelpers.CreateLabel(mCard, memName, UDim2.new(1, -45, 1, 0), Enum.Font.GothamBold, nameColor, 14); mName.Position = UDim2.new(0, 15, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left
				if memIsLeader then local crown = UIHelpers.CreateLabel(mCard, "👑", UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16); crown.Position = UDim2.new(1, -35, 0, 0) end
			end

			local LeaveBtn = CreateSharpButton(PartyContent, "LEAVE TEAM", UDim2.new(1, 0, 0, 35), Enum.Font.GothamBlack, 14); LeaveBtn.LayoutOrder = 4; LeaveBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			LeaveBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Leave") end)
		else
			local Header = UIHelpers.CreateLabel(PartyContent, "SOLO DEPLOYMENT", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 18); Header.LayoutOrder = 1; Header.TextXAlignment = Enum.TextXAlignment.Left
			local CreateBtn = CreateSharpButton(PartyContent, "CREATE STRIKE TEAM", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, 14); CreateBtn.LayoutOrder = 2
			CreateBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Create") end)
		end
	end

	if not isListening then
		isListening = true
		local PartyUpdate = Network:WaitForChild("PartyUpdate")
		PartyUpdate.OnClientEvent:Connect(function(action, data)
			if action == "UpdateList" then
				IsInParty = true; CurrentParty = data; IsPartyLeader = false
				for _, mem in ipairs(CurrentParty) do 
					local isMemDict = (type(mem) == "table" and typeof(mem) ~= "Instance")
					local mId = isMemDict and mem.UserId or mem.UserId
					local mLead = isMemDict and mem.IsLeader or false
					if mId == player.UserId and mLead then IsPartyLeader = true end 
				end
				PendingInvites = {}; RenderPartyUI()
			elseif action == "IncomingInvite" then PendingInvites[data] = true; RenderPartyUI()
			elseif action == "Disbanded" then IsInParty = false; CurrentParty = {}; IsPartyLeader = false; RenderPartyUI() end
		end)
	end

	RenderPartyUI()
	ShowPage("Main", "COMBAT DEPLOYMENT")
end

return ExpeditionsTab