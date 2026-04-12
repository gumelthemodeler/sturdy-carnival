-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: PathsShopUI
local PathsShopUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Network = ReplicatedStorage:WaitForChild("Network")

local SharedUI = player:WaitForChild("PlayerScripts"):WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local VFXManager = require(player:WaitForChild("PlayerScripts"):WaitForChild("VFXManager"))

local PathsShopEvent = Network:WaitForChild("PathsShopEvent")

function PathsShopUI.Initialize(masterScreenGui)
	local ScreenGui = Instance.new("ScreenGui", masterScreenGui)
	ScreenGui.Name = "PathsShopGUI"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 150 
	ScreenGui.Enabled = false

	local Overlay = Instance.new("Frame", ScreenGui)
	Overlay.Size = UDim2.new(1, 0, 1, 0)
	Overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
	Overlay.BackgroundTransparency = 1 -- Start hidden for fade-in
	Overlay.Active = true 

	local bgImage = Instance.new("ImageLabel", Overlay)
	bgImage.Size = UDim2.new(1.05, 0, 1.05, 0) -- Slightly oversized for panning
	bgImage.Position = UDim2.new(-0.025, 0, -0.025, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = "rbxassetid://129655150803684" -- Ymir/Paths Background
	bgImage.ImageTransparency = 1 -- Start hidden for fade-in
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 0

	-- Soften the image edges to fix render artifacts
	local bgGrad = Instance.new("UIGradient", bgImage)
	bgGrad.Rotation = 90
	bgGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})

	-- Use CanvasGroup so the entire UI and its children fade uniformly
	local MainContainer = Instance.new("CanvasGroup", Overlay)
	MainContainer.Size = UDim2.new(0, 800, 0, 500)
	MainContainer.Position = UDim2.new(0.5, 0, 0.55, 0) -- Start slightly lower for slide-up
	MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	MainContainer.BorderSizePixel = 0
	MainContainer.GroupTransparency = 1 -- Start hidden
	MainContainer.ZIndex = 2
	Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 12)
	local mStroke = Instance.new("UIStroke", MainContainer)
	mStroke.Color = Color3.fromRGB(85, 255, 255); mStroke.Thickness = 2

	local Header = UIHelpers.CreateLabel(MainContainer, "THE COORDINATE", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBlack, Color3.fromRGB(85, 255, 255), 28)
	Header.Position = UDim2.new(0, 0, 0, 10)
	local SubHeader = UIHelpers.CreateLabel(MainContainer, "Manifest your infinite potential using Path Dust. Remaining dust will be lost upon leaving.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
	SubHeader.Position = UDim2.new(0, 0, 0, 55)

	local DustLbl = UIHelpers.CreateLabel(MainContainer, "PATH DUST: 0", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(85, 255, 255), 20)
	DustLbl.Position = UDim2.new(0, 0, 0, 85)

	local RunesContainer = Instance.new("ScrollingFrame", MainContainer)
	RunesContainer.Size = UDim2.new(0.95, 0, 0, 280)
	RunesContainer.Position = UDim2.new(0.025, 0, 0, 130)
	RunesContainer.BackgroundTransparency = 1
	RunesContainer.ScrollBarThickness = 6
	RunesContainer.BorderSizePixel = 0
	local rcLayout = Instance.new("UIGridLayout", RunesContainer)
	rcLayout.CellSize = UDim2.new(0.48, 0, 0, 120)
	rcLayout.CellPadding = UDim2.new(0.04, 0, 0, 15)
	rcLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local LeaveBtn = Instance.new("TextButton", MainContainer)
	LeaveBtn.Size = UDim2.new(0.4, 0, 0, 45)
	LeaveBtn.Position = UDim2.new(0.5, 0, 1, -25)
	LeaveBtn.AnchorPoint = Vector2.new(0.5, 1)
	LeaveBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	LeaveBtn.Font = Enum.Font.GothamBlack
	LeaveBtn.Text = "LEAVE THE PATHS"
	LeaveBtn.TextColor3 = Color3.new(1, 1, 1)
	LeaveBtn.TextSize = 16
	Instance.new("UICorner", LeaveBtn).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", LeaveBtn).Color = Color3.fromRGB(255, 100, 100)

	local RuneDefs = {
		{ Id = "Vanguard", Name = "Rune of the Vanguard", Desc = "+0.2% Total Damage per level.", BaseDust = 5, BaseDews = 10000, BaseXP = 25000, Mult = 1.15, Color = "#FF5555" },
		{ Id = "Wall", Name = "Rune of the Wall", Desc = "+0.25% Damage Reduction per level.", BaseDust = 5, BaseDews = 10000, BaseXP = 25000, Mult = 1.15, Color = "#55AAFF" },
		{ Id = "Avarice", Name = "Rune of Avarice", Desc = "+0.1% Global Drop Rate per level.", BaseDust = 10, BaseDews = 25000, BaseXP = 50000, Mult = 1.20, Color = "#FFD700" },
		{ Id = "Titan", Name = "Rune of the Titan", Desc = "+25 Max Titan Heat per level.", BaseDust = 8, BaseDews = 15000, BaseXP = 30000, Mult = 1.15, Color = "#AA55FF" }
	}

	local runeCards = {}

	for i, rDef in ipairs(RuneDefs) do
		local card = Instance.new("Frame", RunesContainer)
		card.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		local cStroke = Instance.new("UIStroke", card); cStroke.Color = Color3.fromRGB(70, 70, 80)

		local title = UIHelpers.CreateLabel(card, rDef.Name .. " [LVL 0]", UDim2.new(0.6, 0, 0, 25), Enum.Font.GothamBlack, Color3.fromHex(rDef.Color), 16)
		title.Position = UDim2.new(0, 15, 0, 10); title.TextXAlignment = Enum.TextXAlignment.Left; title.RichText = true

		local desc = UIHelpers.CreateLabel(card, rDef.Desc, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12)
		desc.Position = UDim2.new(0, 15, 0, 35); desc.TextXAlignment = Enum.TextXAlignment.Left

		local costLbl = UIHelpers.CreateLabel(card, "Cost: 0 Dust | 0 Dews | 0 XP", UDim2.new(0.6, 0, 0, 30), Enum.Font.GothamMedium, Color3.fromHex("#AAAAAA"), 11)
		costLbl.Position = UDim2.new(0, 15, 0, 55); costLbl.TextXAlignment = Enum.TextXAlignment.Left; costLbl.TextWrapped = true

		local upgBtn = Instance.new("TextButton", card)
		upgBtn.Size = UDim2.new(0, 100, 0, 40)
		upgBtn.Position = UDim2.new(1, -15, 0.5, 0)
		upgBtn.AnchorPoint = Vector2.new(1, 0.5)
		upgBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		upgBtn.Font = Enum.Font.GothamBlack
		upgBtn.Text = "UPGRADE"
		upgBtn.TextSize = 12
		Instance.new("UICorner", upgBtn).CornerRadius = UDim.new(0, 6)
		local uStroke = Instance.new("UIStroke", upgBtn)

		upgBtn.MouseButton1Click:Connect(function() Network:WaitForChild("UpgradeRune"):FireServer(rDef.Id) end)
		runeCards[rDef.Id] = { Title = title, CostLbl = costLbl, Btn = upgBtn, Stroke = uStroke, Def = rDef }
	end

	local function AbbreviateNumber(n)
		local Suffixes = {"", "K", "M", "B"}
		if not n then return "0" end; n = tonumber(n) or 0
		if n < 1000 then return tostring(math.floor(n)) end
		local suffixIndex = math.floor(math.log10(n) / 3); local value = n / (10 ^ (suffixIndex * 3))
		local str = string.format("%.1f", value); str = str:gsub("%.0$", "")
		return str .. (Suffixes[suffixIndex + 1] or "")
	end

	local function UpdateRunes()
		if not ScreenGui.Enabled then return end
		local pDust = player:GetAttribute("PathDust") or 0
		local pXP = player:GetAttribute("XP") or 0
		local ls = player:FindFirstChild("leaderstats"); local pDews = ls and ls:FindFirstChild("Dews") and ls.Dews.Value or 0

		DustLbl.Text = "PATH DUST: " .. pDust

		for id, data in pairs(runeCards) do
			local rDef = data.Def
			local currentLvl = player:GetAttribute("Rune_" .. id) or 0
			data.Title.Text = rDef.Name .. " <font color='#FFFFFF'>[LVL " .. currentLvl .. "]</font>"

			local dustCost = math.floor(rDef.BaseDust * (rDef.Mult ^ currentLvl))
			local dewsCost = math.floor(rDef.BaseDews * (rDef.Mult ^ currentLvl))
			local xpCost = math.floor(rDef.BaseXP * (rDef.Mult ^ currentLvl))

			data.CostLbl.Text = "Req: " .. dustCost .. " Dust | " .. AbbreviateNumber(dewsCost) .. " Dews | " .. AbbreviateNumber(xpCost) .. " XP"

			if pDust >= dustCost and pDews >= dewsCost and pXP >= xpCost then
				data.Btn.TextColor3 = Color3.fromHex(rDef.Color); data.Stroke.Color = Color3.fromHex(rDef.Color)
			else
				data.Btn.TextColor3 = Color3.fromRGB(100, 100, 100); data.Stroke.Color = Color3.fromRGB(70, 70, 80)
			end
		end
	end

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Rune_") or attr == "PathDust" or attr == "XP" then UpdateRunes() end end)
	task.spawn(function() local ls = player:WaitForChild("leaderstats", 10); if ls and ls:FindFirstChild("Dews") then ls.Dews.Changed:Connect(UpdateRunes) end end)

	local isOpen = false
	local panTime = 0
	local panConnection = nil

	PathsShopEvent.OnClientEvent:Connect(function(action)
		if action == "Open" and not isOpen then
			isOpen = true
			if VFXManager then VFXManager.PlaySFX("Reveal", 1) end
			ScreenGui.Enabled = true
			UpdateRunes()

			-- Cinematic Fade In
			TweenService:Create(Overlay, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
			TweenService:Create(bgImage, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {ImageTransparency = 0.6}):Play()
			TweenService:Create(MainContainer, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0}):Play()

			-- Slow, eerie background pan
			if not panConnection then
				panConnection = RunService.RenderStepped:Connect(function(dt)
					panTime += dt * 0.15
					bgImage.Position = UDim2.new(-0.025 + math.sin(panTime)*0.01, 0, -0.025 + math.cos(panTime)*0.01, 0)
				end)
			end
		end
	end)

	LeaveBtn.MouseButton1Click:Connect(function()
		if not isOpen then return end
		isOpen = false
		if VFXManager then VFXManager.PlaySFX("Click", 1) end

		-- Cinematic Fade Out
		TweenService:Create(Overlay, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		TweenService:Create(bgImage, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {ImageTransparency = 1}):Play()
		local exitTween = TweenService:Create(MainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.55, 0), GroupTransparency = 1})
		exitTween:Play()

		exitTween.Completed:Wait()
		if panConnection then panConnection:Disconnect(); panConnection = nil end
		ScreenGui.Enabled = false
		PathsShopEvent:FireServer("Close")
	end)
end

return PathsShopUI