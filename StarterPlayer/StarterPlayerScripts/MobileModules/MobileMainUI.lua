-- @ScriptType: ModuleScript
-- Name: MobileMainUI
-- @ScriptType: ModuleScript
local MobileMainUI = {}
local Players = game:GetService("Players"); local TweenService = game:GetService("TweenService"); local ReplicatedStorage = game:GetService("ReplicatedStorage"); local Network = ReplicatedStorage:WaitForChild("Network")
local player = Players.LocalPlayer; local playerScripts = player:WaitForChild("PlayerScripts"); local SharedUI = playerScripts:WaitForChild("SharedUI"); local UIModules = playerScripts:WaitForChild("UIModules"); local MobileModules = playerScripts:WaitForChild("MobileModules"); local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local isAdmin = player:GetAttribute("IsAdmin") or player.Name == "girthbender1209"

local MasterGui, MasterWindow, WindowScale, WindowTitle, CurrentOpenTab; local TabContainers = {}; local CurrencyLabels = {}

local CONFIG = {
	Icons = { Background = "rbxassetid://125800917140688", GameLogo = "rbxassetid://129999765135567", RegimentDefault = "rbxassetid://74069077964164" },
	DockTabs = { {Id = "HOME", Icon = "rbxassetid://129528574378357"}, {Id = "PROFILE", Icon = "rbxassetid://106161709171988"}, {Id = "EXPEDITIONS", Icon = "rbxassetid://115407261158495"}, {Id = "SQUADS", Icon = "rbxassetid://111674249930782"}, {Id = "SUPPLY_FORGE", Icon = "rbxassetid://108619507999123"}, {Id = "REGIMENTS", Icon = "rbxassetid://74069077964164"} },
	Currencies = { {Id = "XP", Prefix = "XP:", Color = "#55FF55"}, {Id = "TitanXP", Prefix = "T-XP:", Color = "#FF5555"}, {Id = "Dews", Prefix = "$:", Color = "#FF88FF"}, {Id = "Prestige", Prefix = "PR:", Color = "#FFD700"} }
}

local function FormatAbbreviation(value)
	local num = tonumber(value); if not num then return "0" end
	if num >= 1e9 then return string.format("%.1fB", num / 1e9):gsub("%.0B", "B") elseif num >= 1e6 then return string.format("%.1fM", num / 1e6):gsub("%.0M", "M") elseif num >= 1e3 then return string.format("%.1fK", num / 1e3):gsub("%.0K", "K") else return tostring(num) end
end

local function BuildEnvironment()
	local BGFrame = Instance.new("Frame", MasterGui); BGFrame.Name = "TexturedBackground"; BGFrame.Size = UDim2.new(1, 0, 1, 0); BGFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10); BGFrame.ZIndex = -10
	local Texture = Instance.new("ImageLabel", BGFrame); Texture.Size = UDim2.new(1, 0, 1, 0); Texture.BackgroundTransparency = 1; Texture.Image = CONFIG.Icons.Background; Texture.ImageTransparency = 0.40; Texture.ScaleType = Enum.ScaleType.Crop ; Texture.ZIndex = -9
end

local function BuildMasterWindow()
	MasterWindow = Instance.new("Frame", MasterGui); MasterWindow.Name = "MasterWindow"; MasterWindow.Size = UDim2.new(1, 0, 1, 0); MasterWindow.Position = UDim2.new(0, 0, 0, 0); MasterWindow.Visible = false; MasterWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 18); MasterWindow.BorderSizePixel = 0
	WindowScale = Instance.new("UIScale", MasterWindow); WindowScale.Scale = 0

	-- [[ THE FIX: Header Increased to 42px. Currencies Enlarged. Fonts Switched to Gotham. ]]
	local Header = Instance.new("Frame", MasterWindow); Header.Size = UDim2.new(1, 0, 0, 42); Header.BackgroundColor3 = Color3.fromRGB(12, 12, 15); Header.BorderSizePixel = 0; local headerStroke = Instance.new("UIStroke", Header); headerStroke.Color = Color3.fromRGB(45, 45, 50); headerStroke.Thickness = 1
	WindowTitle = UIHelpers.CreateLabel(Header, "COMMAND CENTER", UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14); WindowTitle.Position = UDim2.new(0, 15, 0, 0); WindowTitle.TextXAlignment = Enum.TextXAlignment.Left

	local CloseBtn = Instance.new("TextButton", Header); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -6, 0.5, 0); CloseBtn.AnchorPoint = Vector2.new(1, 0.5); CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 15); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85); CloseBtn.BorderSizePixel = 0; local cbStroke = Instance.new("UIStroke", CloseBtn); cbStroke.Color = Color3.fromRGB(150, 40, 40); cbStroke.Thickness = 1; cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
	CloseBtn.MouseButton1Click:Connect(function() CurrentOpenTab = nil; local t = TweenService:Create(WindowScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}); t:Play(); t.Completed:Wait(); MasterWindow.Visible = false end)

	local StatsContainer = Instance.new("Frame", Header); StatsContainer.Size = UDim2.new(0.65, 0, 1, 0); StatsContainer.Position = UDim2.new(1, -45, 0, 0); StatsContainer.AnchorPoint = Vector2.new(1, 0); StatsContainer.BackgroundTransparency = 1; local statLayout = Instance.new("UIListLayout", StatsContainer); statLayout.FillDirection = Enum.FillDirection.Horizontal; statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; statLayout.VerticalAlignment = Enum.VerticalAlignment.Center; statLayout.Padding = UDim.new(0, 8)

	-- [[ THE FIX: Bigger top boxes, more readable text ]]
	local function CreateTopBox(prefix, hexColor)
		local box = Instance.new("Frame", StatsContainer); box.Size = UDim2.new(0, 95, 0, 26); box.BackgroundColor3 = Color3.fromRGB(18, 18, 22); box.BorderSizePixel = 0; local bStroke = Instance.new("UIStroke", box); bStroke.Color = Color3.fromRGB(50, 50, 60); bStroke.Thickness = 1; bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
		local vLbl = UIHelpers.CreateLabel(box, prefix .. " 0", UDim2.new(1, -8, 1, 0), Enum.Font.GothamBlack, Color3.fromHex(hexColor:gsub("#","")), 13); vLbl.Position = UDim2.new(0.5, 0, 0.5, 0); vLbl.AnchorPoint = Vector2.new(0.5, 0.5); vLbl.TextXAlignment = Enum.TextXAlignment.Center; vLbl.TextScaled = true; local vCon = Instance.new("UITextSizeConstraint", vLbl); vCon.MaxTextSize = 13; return vLbl
	end

	for _, cData in ipairs(CONFIG.Currencies) do CurrencyLabels[cData.Id] = CreateTopBox(cData.Prefix, cData.Color); CurrencyLabels[cData.Id]:SetAttribute("Prefix", cData.Prefix) end

	local function UpdateCurrencies()
		local ls = player:FindFirstChild("leaderstats")
		if CurrencyLabels.Prestige then CurrencyLabels.Prestige.Text = CurrencyLabels.Prestige:GetAttribute("Prefix") .. " " .. FormatAbbreviation((ls and ls:FindFirstChild("Prestige")) and ls.Prestige.Value or 0) end
		if CurrencyLabels.Dews then CurrencyLabels.Dews.Text = CurrencyLabels.Dews:GetAttribute("Prefix") .. " " .. FormatAbbreviation(player:GetAttribute("Dews") or 0) end
		if CurrencyLabels.XP then CurrencyLabels.XP.Text = CurrencyLabels.XP:GetAttribute("Prefix") .. " " .. FormatAbbreviation(player:GetAttribute("XP") or 0) end
		if CurrencyLabels.TitanXP then CurrencyLabels.TitanXP.Text = CurrencyLabels.TitanXP:GetAttribute("Prefix") .. " " .. FormatAbbreviation(player:GetAttribute("TitanXP") or 0) end
	end
	player.AttributeChanged:Connect(function(a) if a == "Dews" or a == "XP" or a == "TitanXP" then UpdateCurrencies() end end); task.spawn(function() local ls = player:WaitForChild("leaderstats", 10); if ls then for _, child in ipairs(ls:GetChildren()) do if child:IsA("IntValue") then child.Changed:Connect(UpdateCurrencies) end end end; UpdateCurrencies() end)

	local ContentArea = Instance.new("Frame", MasterWindow); ContentArea.Size = UDim2.new(1, 0, 1, -92); ContentArea.Position = UDim2.new(0, 0, 0, 42); ContentArea.BackgroundTransparency = 1

	local tabs = {"HOME", "PROFILE", "EXPEDITIONS", "SQUADS", "SUPPLY_FORGE", "REGIMENTS"}; if isAdmin then table.insert(tabs, "ADMIN") end
	for _, tabName in ipairs(tabs) do local tabFrame = Instance.new("Frame", ContentArea); tabFrame.Name = tabName; tabFrame.Size = UDim2.new(1, 0, 1, 0); tabFrame.BackgroundTransparency = 1; tabFrame.Visible = false; TabContainers[tabName] = tabFrame end

	local hTab = TabContainers["HOME"]
	local homeLbl = UIHelpers.CreateLabel(hTab, "WELCOME TO THE VANGUARD", UDim2.new(1,0,1,0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); homeLbl.Position = UDim2.new(0, 0, -0.1, 0)
	local homeSub = UIHelpers.CreateLabel(hTab, "Select a protocol from the console below to deploy.", UDim2.new(1,0,1,0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 13)

	local function SafeLoad(mobileName, pcName, tabKey)
		task.spawn(function() local mod; if MobileModules:FindFirstChild(mobileName) then mod = require(MobileModules[mobileName]) else mod = require(UIModules:WaitForChild(pcName)) end; if mod and mod.Initialize then mod.Initialize(TabContainers[tabKey]) end end)
	end
	SafeLoad("MobileHeroMenu", "HeroMenu", "PROFILE"); SafeLoad("MobileExpeditionsTab", "ExpeditionsTab", "EXPEDITIONS"); SafeLoad("MobileSupplyForgeTab", "SupplyForgeTab", "SUPPLY_FORGE"); SafeLoad("SquadsTab", "SquadsTab", "SQUADS"); SafeLoad("MobileRegimentsTab", "RegimentsTab", "REGIMENTS") 
	if isAdmin then task.spawn(function() local AdminMod = require(UIModules:WaitForChild("AdminTab")); if AdminMod.Initialize then AdminMod.Initialize(TabContainers["ADMIN"]) end end) end
end

local function OpenMasterTab(tabName, displayTitle)
	if CurrentOpenTab == tabName and MasterWindow.Visible then CurrentOpenTab = nil; local t = TweenService:Create(WindowScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}); t:Play(); t.Completed:Wait(); MasterWindow.Visible = false; return end
	for name, frame in pairs(TabContainers) do frame.Visible = (name == tabName) end
	CurrentOpenTab = tabName; local titles = { HOME = "COMMAND CENTER", PROFILE = "OPERATIVE", EXPEDITIONS = "COMBAT", SQUADS = "SQUADS", SUPPLY_FORGE = "MARKET & FORGE", REGIMENTS = "REGIMENTS", ADMIN = "DEBUG" }; if WindowTitle then WindowTitle.Text = titles[tabName] or tabName end
	if not MasterWindow.Visible then MasterWindow.Visible = true; TweenService:Create(WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play() end
end

local function BuildBottomBar()
	local Dock = Instance.new("Frame", MasterGui); Dock.AnchorPoint = Vector2.new(0.5, 1); Dock.Position = UDim2.new(0.5, 0, 1, 0); Dock.Size = UDim2.new(1, 0, 0, 50); Dock.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Dock.BorderSizePixel = 0
	local dStroke = Instance.new("UIStroke", Dock); dStroke.Color = Color3.fromRGB(60, 60, 70); dStroke.Thickness = 1
	local dGrad = Instance.new("UIGradient", Dock); dGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 18))}; dGrad.Rotation = 90
	local layout = Instance.new("UIListLayout", Dock); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0.02, 0) 

	if isAdmin then table.insert(CONFIG.DockTabs, {Id = "ADMIN", Title = "DEBUG", Icon = "rbxassetid://100709766417970"}) end

	for _, btnData in ipairs(CONFIG.DockTabs) do
		local btn = Instance.new("ImageButton", Dock); btn.Size = UDim2.new(0, 38, 0, 38); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.Image = btnData.Icon; btn.BorderSizePixel = 0; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		local bStrk = Instance.new("UIStroke", btn); bStrk.Color = Color3.fromRGB(80, 80, 90); bStrk.Thickness = 1; bStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		btn.MouseButton1Click:Connect(function() OpenMasterTab(btnData.Id, btnData.Id) end)
		btn.InputBegan:Connect(function() bStrk.Color = UIHelpers.Colors.Gold; btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45) end)
		btn.InputEnded:Connect(function() bStrk.Color = Color3.fromRGB(80, 80, 90); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30) end)

		if btnData.Id == "REGIMENTS" then
			local function UpdateRegimentIcon()
				local currentReg = player:GetAttribute("Regiment") or "Cadet Corps"; local hasRegData, regDataModule = pcall(function() return require(game.ReplicatedStorage:WaitForChild("RegimentData")) end); local newIcon = CONFIG.Icons.RegimentDefault
				if hasRegData and regDataModule and regDataModule.Regiments[currentReg] then newIcon = regDataModule.Regiments[currentReg].Icon end
				btn.Image = newIcon
			end
			player.AttributeChanged:Connect(function(attr) if attr == "Regiment" then UpdateRegimentIcon() end end); UpdateRegimentIcon()
		end
	end
end

function MobileMainUI.Initialize(masterScreenGui)
	MasterGui = masterScreenGui; BuildEnvironment(); BuildMasterWindow(); BuildBottomBar()
	task.spawn(function() local CombatMod = require(script.Parent:WaitForChild("MobileCombatUI")); if CombatMod.Initialize then CombatMod.Initialize(MasterGui) end end)
	OpenMasterTab("HOME", "COMMAND CENTER")
end

return MobileMainUI