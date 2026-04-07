-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileSquadsTab
-- @ScriptType: ModuleScript
local MobileSquadsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer

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
	btn.TextScaled = true
	local tsc = Instance.new("UITextSizeConstraint", btn)
	tsc.MaxTextSize = textSize; tsc.MinTextSize = 10

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.InputBegan:Connect(function() 
		if btn.Active then 
			btn:SetAttribute("OrigColor", btn.TextColor3)
			btn:SetAttribute("OrigStroke", stroke.Color)
			stroke.Color = UIHelpers.Colors.Gold
			btn.TextColor3 = UIHelpers.Colors.Gold 
		end
	end)
	btn.InputEnded:Connect(function() 
		if btn.Active then 
			stroke.Color = btn:GetAttribute("OrigStroke") or Color3.fromRGB(70, 70, 80)
			btn.TextColor3 = btn:GetAttribute("OrigColor") or Color3.fromRGB(245, 245, 245)
		end
	end)
	return btn, stroke
end

local function CreateInput(parent, placeholder, size, pos)
	local input = Instance.new("TextBox", parent)
	input.Size = size
	input.Position = pos
	input.AnchorPoint = Vector2.new(0.5, 0)
	input.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	input.TextColor3 = UIHelpers.Colors.TextWhite
	input.Font = Enum.Font.GothamMedium
	input.TextSize = 14
	input.PlaceholderText = placeholder
	input.Text = ""
	local stroke = Instance.new("UIStroke", input)
	stroke.Color = UIHelpers.Colors.BorderMuted
	return input
end

function MobileSquadsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainFrame = Instance.new("Frame", parentFrame); MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1
	local mLayout = Instance.new("UIListLayout", MainFrame); mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 10); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", MainFrame).PaddingTop = UDim.new(0, 10)

	local Title = UIHelpers.CreateLabel(MainFrame, "STRIKE SQUADS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20); Title.LayoutOrder = 1

	local SubNav = Instance.new("Frame", MainFrame); SubNav.Size = UDim2.new(1, -10, 0, 40); SubNav.BackgroundTransparency = 1; SubNav.LayoutOrder = 2
	local navLayout = Instance.new("UIListLayout", SubNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 8)

	local ContentArea = Instance.new("Frame", MainFrame); ContentArea.Size = UDim2.new(1, -10, 1, -90); ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 3

	local subTabs = { "MY SQUAD", "SQUAD FINDER" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNav, tabName, UDim2.new(0.48, 0, 0, 35), Enum.Font.GothamBold, 12)
		btn.TextColor3 = UIHelpers.Colors.TextMuted; stroke.Color = UIHelpers.Colors.BorderMuted

		local subFrame = Instance.new("ScrollingFrame", ContentArea); subFrame.Name = tabName; subFrame.Size = UDim2.new(1, 0, 1, 0); subFrame.BackgroundTransparency = 1; subFrame.Visible = (i == 1)
		subFrame.ScrollBarThickness = 4; subFrame.BorderSizePixel = 0

		local sfLayout = Instance.new("UIListLayout", subFrame)
		sfLayout.Padding = UDim.new(0, 15)
		sfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		sfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() subFrame.CanvasSize = UDim2.new(0, 0, 0, sfLayout.AbsoluteContentSize.Y + 20) end)

		activeSubFrames[tabName] = subFrame; subBtns[tabName] = {Btn = btn, Stroke = stroke}

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabName) end
			for name, bData in pairs(subBtns) do bData.Btn.TextColor3 = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted; bData.Stroke.Color = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted end
		end)
	end

	subBtns["MY SQUAD"].Btn.TextColor3 = UIHelpers.Colors.Gold; subBtns["MY SQUAD"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- MY SQUAD TAB (MOBILE VERTICAL)
	-- ==========================================
	local MySquadTab = activeSubFrames["MY SQUAD"]

	local NotInSquadView = Instance.new("Frame", MySquadTab); NotInSquadView.Size = UDim2.new(1, 0, 0, 400); NotInSquadView.BackgroundTransparency = 1; NotInSquadView.Visible = false
	local DashContainer, _ = CreateGrimPanel(NotInSquadView); DashContainer.Size = UDim2.new(1, 0, 1, 0)

	local niTitle = UIHelpers.CreateLabel(DashContainer, "SQUAD REGISTRATION", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); niTitle.Position = UDim2.new(0, 0, 0, 10)
	local niDesc = UIHelpers.CreateLabel(DashContainer, "Found a Strike Squad to accumulate global Contribution Points (CP) and unlock utility perks for your members.", UDim2.new(0.9, 0, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); niDesc.Position = UDim2.new(0.05, 0, 0, 45); niDesc.TextWrapped = true

	local NameInput = CreateInput(DashContainer, "Squad Name (Max 20)", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 120))
	local DescInput = CreateInput(DashContainer, "Squad Description / Motto", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 175))
	local LogoInput = CreateInput(DashContainer, "Logo ID (e.g. 12345678)", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 230))

	local CreateBtn, cStroke = CreateSharpButton(DashContainer, "FOUND SQUAD (100,000 Dews)", UDim2.new(0.8, 0, 0, 50), Enum.Font.GothamBlack, 14); CreateBtn.Position = UDim2.new(0.5, 0, 0, 300); CreateBtn.AnchorPoint = Vector2.new(0.5, 0); CreateBtn.TextColor3 = UIHelpers.Colors.Gold; cStroke.Color = UIHelpers.Colors.Gold
	CreateBtn.MouseButton1Click:Connect(function() if NameInput.Text ~= "" then Network:WaitForChild("SquadAction"):FireServer("Create", {Name = NameInput.Text, Desc = DescInput.Text, Logo = LogoInput.Text}) end end)

	local InSquadView = Instance.new("Frame", MySquadTab); InSquadView.Size = UDim2.new(1, 0, 0, 800); InSquadView.BackgroundTransparency = 1; InSquadView.Visible = true

	local HeaderPanel = Instance.new("Frame", InSquadView)
	HeaderPanel.Size = UDim2.new(1, 0, 0, 130)
	CreateGrimPanel(HeaderPanel)

	local SquadLogo = Instance.new("ImageLabel", HeaderPanel); SquadLogo.Size = UDim2.new(0, 90, 0, 90); SquadLogo.Position = UDim2.new(0, 10, 0, 20); SquadLogo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Instance.new("UIStroke", SquadLogo).Color = UIHelpers.Colors.Gold
	local SquadNameLbl = UIHelpers.CreateLabel(HeaderPanel, "SQUAD NAME", UDim2.new(1, -120, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); SquadNameLbl.Position = UDim2.new(0, 110, 0, 15); SquadNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	local SquadDescLbl = UIHelpers.CreateLabel(HeaderPanel, "Squad Description goes here.", UDim2.new(1, -120, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11); SquadDescLbl.Position = UDim2.new(0, 110, 0, 45); SquadDescLbl.TextXAlignment = Enum.TextXAlignment.Left; SquadDescLbl.TextWrapped = true
	local CpLabel = UIHelpers.CreateLabel(HeaderPanel, "TOTAL CP: 0", UDim2.new(1, -120, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(85, 170, 255), 14); CpLabel.Position = UDim2.new(0, 110, 0, 85); CpLabel.TextXAlignment = Enum.TextXAlignment.Left

	local PerksPanel = Instance.new("Frame", InSquadView)
	PerksPanel.Size = UDim2.new(1, 0, 0, 100)
	PerksPanel.Position = UDim2.new(0, 0, 0, 145)
	CreateGrimPanel(PerksPanel)

	local pkTitle = UIHelpers.CreateLabel(PerksPanel, "ACTIVE SQUAD PERKS", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
	pkTitle.Position = UDim2.new(0, 0, 0, 5)
	local pkDesc = UIHelpers.CreateLabel(PerksPanel, "Logistics II: Max Members +10\nTreasury I: Bounty Dews +10%\nArmory I: Vault Capacity +5", UDim2.new(1, -20, 1, -35), Enum.Font.GothamMedium, Color3.fromRGB(85, 255, 85), 12); pkDesc.Position = UDim2.new(0, 10, 0, 30); pkDesc.TextXAlignment = Enum.TextXAlignment.Left; pkDesc.TextYAlignment = Enum.TextYAlignment.Top

	local RosterPanel = Instance.new("Frame", InSquadView)
	RosterPanel.Size = UDim2.new(1, 0, 0, 300)
	RosterPanel.Position = UDim2.new(0, 0, 0, 260)
	CreateGrimPanel(RosterPanel)

	local RosterTitle = UIHelpers.CreateLabel(RosterPanel, "ACTIVE ROSTER", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16); RosterTitle.Position = UDim2.new(0, 10, 0, 5); RosterTitle.TextXAlignment = Enum.TextXAlignment.Left
	local RosterList = Instance.new("ScrollingFrame", RosterPanel); RosterList.Size = UDim2.new(1, -20, 1, -45); RosterList.Position = UDim2.new(0, 10, 0, 35); RosterList.BackgroundTransparency = 1; RosterList.ScrollBarThickness = 4; RosterList.BorderSizePixel = 0
	local rlLayout = Instance.new("UIListLayout", RosterList); rlLayout.Padding = UDim.new(0, 8); rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RosterList.CanvasSize = UDim2.new(0,0,0, rlLayout.AbsoluteContentSize.Y + 10) end)

	local VaultPanel = Instance.new("Frame", InSquadView)
	VaultPanel.Size = UDim2.new(1, 0, 0, 150)
	VaultPanel.Position = UDim2.new(0, 0, 0, 575)
	CreateGrimPanel(VaultPanel)

	local VaultTitle = UIHelpers.CreateLabel(VaultPanel, "SQUAD VAULT (Click to Deposit/Withdraw)", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14); VaultTitle.Position = UDim2.new(0, 10, 0, 5); VaultTitle.TextXAlignment = Enum.TextXAlignment.Left
	local VaultContainer = Instance.new("Frame", VaultPanel); VaultContainer.Size = UDim2.new(1, -20, 1, -45); VaultContainer.Position = UDim2.new(0, 10, 0, 35); VaultContainer.BackgroundTransparency = 1
	local vcLayout = Instance.new("UIGridLayout", VaultContainer); vcLayout.CellSize = UDim2.new(0.3, 0, 0, 45); vcLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)

	local InvOverlay = Instance.new("Frame", parentFrame.Parent); InvOverlay.Size = UDim2.new(1, 0, 1, 0); InvOverlay.BackgroundColor3 = Color3.new(0,0,0); InvOverlay.BackgroundTransparency = 0.6; InvOverlay.ZIndex = 50; InvOverlay.Visible = false; InvOverlay.Active = true
	local InvPanel, _ = CreateGrimPanel(InvOverlay); InvPanel.Size = UDim2.new(0.9, 0, 0.7, 0); InvPanel.Position = UDim2.new(0.5, 0, 0.5, 0); InvPanel.AnchorPoint = Vector2.new(0.5, 0.5); InvPanel.ZIndex = 51
	local invTitle = UIHelpers.CreateLabel(InvPanel, "DEPOSIT ITEM", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); invTitle.ZIndex = 52
	local closeInvBtn, _ = CreateSharpButton(InvPanel, "X", UDim2.new(0, 35, 0, 35), Enum.Font.GothamBlack, 16); closeInvBtn.Position = UDim2.new(1, -10, 0, 5); closeInvBtn.AnchorPoint = Vector2.new(1, 0); closeInvBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeInvBtn.ZIndex = 52; closeInvBtn.MouseButton1Click:Connect(function() InvOverlay.Visible = false end)
	local InvScroll = Instance.new("ScrollingFrame", InvPanel); InvScroll.Size = UDim2.new(1, -20, 1, -55); InvScroll.Position = UDim2.new(0, 10, 0, 45); InvScroll.BackgroundTransparency = 1; InvScroll.ScrollBarThickness = 6; InvScroll.BorderSizePixel = 0; InvScroll.ZIndex = 52
	local invLayout = Instance.new("UIListLayout", InvScroll); invLayout.Padding = UDim.new(0, 10); invLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InvScroll.CanvasSize = UDim2.new(0,0,0, invLayout.AbsoluteContentSize.Y + 10) end)
	local noItemsLbl = UIHelpers.CreateLabel(InvPanel, "You have no items to deposit.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); noItemsLbl.Position = UDim2.new(0, 0, 0.5, 0); noItemsLbl.AnchorPoint = Vector2.new(0, 0.5); noItemsLbl.ZIndex = 52

	local activeVaultSlot = 1
	local function OpenInventorySelection(slotId)
		activeVaultSlot = slotId; InvOverlay.Visible = true
		for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
		local foundAny = false
		local function ScanItems(dictionary)
			for itemName, _ in pairs(dictionary) do
				local safeName = itemName:gsub("[^%w]", "") .. "Count"
				local count = player:GetAttribute(safeName) or 0
				if count > 0 then
					foundAny = true
					local btn, stroke = CreateSharpButton(InvScroll, count .. "x " .. itemName, UDim2.new(1, -10, 0, 45), Enum.Font.GothamBold, 12); btn.ZIndex = 53
					btn.MouseButton1Click:Connect(function() InvOverlay.Visible = false; Network:WaitForChild("SquadAction"):FireServer("DepositItem", {Slot = activeVaultSlot, ItemName = itemName}) end)
				end
			end
		end
		ScanItems(ItemData.Equipment or {}); ScanItems(ItemData.Consumables or {})
		noItemsLbl.Visible = not foundAny
	end

	local vaultBtns = {}
	for i = 1, 6 do
		local vBtn, stroke = CreateSharpButton(VaultContainer, "Empty", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 10); vBtn.TextWrapped = true
		vBtn.MouseButton1Click:Connect(function()
			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end
			if squadVault[i] == "None" then OpenInventorySelection(i) else Network:WaitForChild("SquadAction"):FireServer("WithdrawItem", {Slot = i}) end
		end)
		vaultBtns[i] = {Btn = vBtn, Stroke = stroke}
	end

	local function UpdateSquadUI()
		local mySquad = player:GetAttribute("SquadName")
		if mySquad and mySquad ~= "" and mySquad ~= "None" then
			NotInSquadView.Visible = false; InSquadView.Visible = true; SquadNameLbl.Text = mySquad; SquadDescLbl.Text = player:GetAttribute("SquadDesc") or "No description set."
			local rawLogo = player:GetAttribute("SquadLogo") or ""
			if rawLogo ~= "" then SquadLogo.Image = string.match(rawLogo, "rbxassetid") and rawLogo or "rbxassetid://" .. rawLogo:match("%d+") end
			CpLabel.Text = "TOTAL CP: " .. (player:GetAttribute("SquadCP") or 0)

			task.spawn(function()
				for _, c in ipairs(RosterList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
				local rosterData = Network:WaitForChild("GetSquadRoster"):InvokeServer()
				if rosterData then
					for _, member in ipairs(rosterData) do
						local mCard, _ = CreateGrimPanel(RosterList); mCard.Size = UDim2.new(1, -10, 0, 35)
						local mName = UIHelpers.CreateLabel(mCard, member.Name, UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12); mName.Position = UDim2.new(0, 10, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left
						local mRole = UIHelpers.CreateLabel(mCard, member.Role, UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 10); mRole.Position = UDim2.new(0.7, -10, 0, 0); mRole.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
			end)

			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end
			for i = 1, 6 do
				local storeObj = vaultBtns[i]; local btn = storeObj.Btn; local storedItem = squadVault[i] or "None"
				btn.Text = (storedItem == "None" and "Empty" or storedItem)
				if storedItem ~= "None" then storeObj.Stroke.Color = UIHelpers.Colors.Gold; btn.TextColor3 = Color3.fromRGB(230, 230, 230) else storeObj.Stroke.Color = UIHelpers.Colors.BorderMuted; btn.TextColor3 = UIHelpers.Colors.TextMuted end
			end
		else 
			NotInSquadView.Visible = true; InSquadView.Visible = false 
		end
	end

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Squad") then UpdateSquadUI() end end); UpdateSquadUI()

	-- ==========================================
	-- SQUAD FINDER TAB (MOBILE VERTICAL)
	-- ==========================================
	local FinderTab = activeSubFrames["SQUAD FINDER"]

	local finderTitle = UIHelpers.CreateLabel(FinderTab, "PUBLIC DIRECTORY", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18); finderTitle.Position = UDim2.new(0, 10, 0, 0); finderTitle.TextXAlignment = Enum.TextXAlignment.Left

	local function AddSquadCard(sqName, sqDesc, sqLogo, sqLevel, memberCount, cpScore)
		local card, _ = CreateGrimPanel(FinderTab); card.Size = UDim2.new(1, -10, 0, 110); card.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		local logo = Instance.new("ImageLabel", card); logo.Size = UDim2.new(0, 50, 0, 50); logo.Position = UDim2.new(0, 10, 0, 10); logo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); logo.Image = sqLogo; Instance.new("UIStroke", logo).Color = UIHelpers.Colors.BorderMuted

		local nameLbl = UIHelpers.CreateLabel(card, sqName, UDim2.new(1, -75, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14); nameLbl.Position = UDim2.new(0, 70, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		local descLbl = UIHelpers.CreateLabel(card, sqDesc, UDim2.new(1, -75, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 11); descLbl.Position = UDim2.new(0, 70, 0, 30); descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextWrapped = true

		local statsLbl = UIHelpers.CreateLabel(card, "Lv. " .. sqLevel .. " | " .. memberCount .. " Members | " .. cpScore .. " CP", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 10); statsLbl.Position = UDim2.new(0, 10, 1, -30); statsLbl.TextXAlignment = Enum.TextXAlignment.Left

		local reqBtn, rStroke = CreateSharpButton(card, "REQUEST JOIN", UDim2.new(0, 100, 0, 30), Enum.Font.GothamBlack, 11); reqBtn.Position = UDim2.new(1, -10, 1, -10); reqBtn.AnchorPoint = Vector2.new(1, 1); reqBtn.TextColor3 = Color3.fromRGB(85, 170, 255); rStroke.Color = Color3.fromRGB(85, 170, 255)
		reqBtn.MouseButton1Click:Connect(function() Network:WaitForChild("SquadAction"):FireServer("RequestJoin", sqName); reqBtn.Text = "REQUEST SENT"; reqBtn.TextColor3 = Color3.fromRGB(150, 150, 150); rStroke.Color = UIHelpers.Colors.BorderMuted; reqBtn.Active = false end)
	end

	task.spawn(function()
		local publicSquads = Network:WaitForChild("GetPublicSquads"):InvokeServer()
		if publicSquads then for _, sq in ipairs(publicSquads) do AddSquadCard(sq.Name, sq.Desc, sq.Logo, sq.Level, sq.MemberCount, sq.CP) end end
	end)
end

return MobileSquadsTab