-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileSquadsTab
local MobileSquadsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer

-- [[ THE FIX: Added sleek transparency and rounded corners to remove the ugly gray block aesthetic ]]
local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	frame.BackgroundTransparency = 0.2 
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8) 
	return frame, stroke
end

local function CreateSharpButton(parent, text, size, font, textSize, hexColor)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text; btn.TextScaled = true
	local tsc = Instance.new("UITextSizeConstraint", btn); tsc.MaxTextSize = textSize; tsc.MinTextSize = 10
	local stroke = Instance.new("UIStroke", btn)
	if hexColor then stroke.Color = Color3.fromHex(hexColor:gsub("#","")) else stroke.Color = Color3.fromRGB(70, 70, 80) end
	stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	btn.InputBegan:Connect(function() if btn.Active then btn:SetAttribute("OrigColor", btn.TextColor3); btn:SetAttribute("OrigStroke", stroke.Color); stroke.Color = UIHelpers.Colors.Gold; btn.TextColor3 = UIHelpers.Colors.Gold end end)
	btn.InputEnded:Connect(function() if btn.Active then stroke.Color = btn:GetAttribute("OrigStroke") or Color3.fromRGB(70, 70, 80); btn.TextColor3 = btn:GetAttribute("OrigColor") or Color3.fromRGB(245, 245, 245) end end)
	return btn, stroke
end

local function CreateInput(parent, placeholder, size, pos)
	local input = Instance.new("TextBox", parent)
	input.Size = size; input.Position = pos; input.AnchorPoint = Vector2.new(0.5, 0); input.BackgroundColor3 = Color3.fromRGB(15, 15, 18); input.TextColor3 = UIHelpers.Colors.TextWhite; input.Font = Enum.Font.GothamMedium; input.TextSize = 14; input.PlaceholderText = placeholder; input.Text = ""
	local stroke = Instance.new("UIStroke", input); stroke.Color = UIHelpers.Colors.BorderMuted; Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
	return input
end

function MobileSquadsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainFrame = Instance.new("Frame", parentFrame); MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1
	local mLayout = Instance.new("UIListLayout", MainFrame); mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 10); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", MainFrame).PaddingTop = UDim.new(0, 10)

	local Title = UIHelpers.CreateLabel(MainFrame, "STRIKE SQUADS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20); Title.LayoutOrder = 1
	local SubNav = Instance.new("Frame", MainFrame); SubNav.Size = UDim2.new(1, -10, 0, 40); SubNav.BackgroundTransparency = 1; SubNav.LayoutOrder = 2
	local navLayout = Instance.new("UIListLayout", SubNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 5)
	local ContentArea = Instance.new("Frame", MainFrame); ContentArea.Size = UDim2.new(1, -10, 1, -90); ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 3

	local subTabs = { "MY SQUAD", "SQUAD VAULT", "SQUAD FINDER" }; local activeSubFrames = {}; local subBtns = {}
	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNav, tabName, UDim2.new(0.31, 0, 0, 35), Enum.Font.GothamBold, 11)
		btn.TextColor3 = UIHelpers.Colors.TextMuted; stroke.Color = UIHelpers.Colors.BorderMuted
		local subFrame = Instance.new("ScrollingFrame", ContentArea); subFrame.Name = tabName; subFrame.Size = UDim2.new(1, 0, 1, 0); subFrame.BackgroundTransparency = 1; subFrame.Visible = (i == 1); subFrame.ScrollBarThickness = 4; subFrame.BorderSizePixel = 0
		local sfLayout = Instance.new("UIListLayout", subFrame); sfLayout.Padding = UDim.new(0, 15); sfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		sfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() subFrame.CanvasSize = UDim2.new(0, 0, 0, sfLayout.AbsoluteContentSize.Y + 20) end)
		activeSubFrames[tabName] = subFrame; subBtns[tabName] = {Btn = btn, Stroke = stroke}

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabName) end
			for name, bData in pairs(subBtns) do bData.Btn.TextColor3 = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted; bData.Stroke.Color = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted end
		end)
	end
	subBtns["MY SQUAD"].Btn.TextColor3 = UIHelpers.Colors.Gold; subBtns["MY SQUAD"].Stroke.Color = UIHelpers.Colors.Gold

	local ConfirmOverlay = Instance.new("Frame", parentFrame.Parent)
	ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0); ConfirmOverlay.BackgroundColor3 = Color3.new(0,0,0); ConfirmOverlay.BackgroundTransparency = 0.7; ConfirmOverlay.ZIndex = 100; ConfirmOverlay.Visible = false; ConfirmOverlay.Active = true
	local ConfirmPanel, _ = CreateGrimPanel(ConfirmOverlay)
	ConfirmPanel.Size = UDim2.new(0.9, 0, 0, 220); ConfirmPanel.Position = UDim2.new(0.5, 0, 0.5, 0); ConfirmPanel.AnchorPoint = Vector2.new(0.5, 0.5); ConfirmPanel.ZIndex = 101

	local cTitle = UIHelpers.CreateLabel(ConfirmPanel, "WARNING", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 85, 85), 20); cTitle.ZIndex = 102
	local cDesc = UIHelpers.CreateLabel(ConfirmPanel, "Are you sure you want to do this?", UDim2.new(0.9, 0, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 14); cDesc.Position = UDim2.new(0.05, 0, 0, 50); cDesc.TextWrapped = true; cDesc.ZIndex = 102
	local cYes, cYesStr = CreateSharpButton(ConfirmPanel, "CONFIRM", UDim2.new(0.4, 0, 0, 45), Enum.Font.GothamBlack, 14, "#FF5555"); cYes.Position = UDim2.new(0.1, 0, 1, -60); cYes.TextColor3 = Color3.fromRGB(255, 85, 85); cYes.ZIndex = 102
	local cNo, _ = CreateSharpButton(ConfirmPanel, "CANCEL", UDim2.new(0.4, 0, 0, 45), Enum.Font.GothamBlack, 14); cNo.Position = UDim2.new(0.5, 0, 1, -60); cNo.ZIndex = 102
	cNo.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)

	local function ShowConfirm(title, desc, onConfirm)
		cTitle.Text = title; cDesc.Text = desc; local conn; conn = cYes.MouseButton1Click:Connect(function() conn:Disconnect(); ConfirmOverlay.Visible = false; onConfirm() end); ConfirmOverlay.Visible = true
	end

	local InvOverlay = Instance.new("Frame", MainFrame); InvOverlay.Size = UDim2.new(1, 0, 1, 0); InvOverlay.BackgroundColor3 = Color3.new(0,0,0); InvOverlay.BackgroundTransparency = 0.6; InvOverlay.ZIndex = 50; InvOverlay.Visible = false; InvOverlay.Active = true
	local InvPanel, _ = CreateGrimPanel(InvOverlay); InvPanel.Size = UDim2.new(0.9, 0, 0.7, 0); InvPanel.Position = UDim2.new(0.5, 0, 0.5, 0); InvPanel.AnchorPoint = Vector2.new(0.5, 0.5); InvPanel.ZIndex = 51
	local invTitle = UIHelpers.CreateLabel(InvPanel, "DEPOSIT ITEM", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); invTitle.ZIndex = 52
	local closeInvBtn, _ = CreateSharpButton(InvPanel, "X", UDim2.new(0, 35, 0, 35), Enum.Font.GothamBlack, 16, "#FF5555"); closeInvBtn.Position = UDim2.new(1, -10, 0, 5); closeInvBtn.AnchorPoint = Vector2.new(1, 0); closeInvBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeInvBtn.ZIndex = 52; closeInvBtn.MouseButton1Click:Connect(function() InvOverlay.Visible = false end)
	local InvScroll = Instance.new("ScrollingFrame", InvPanel); InvScroll.Size = UDim2.new(1, -20, 1, -55); InvScroll.Position = UDim2.new(0, 10, 0, 45); InvScroll.BackgroundTransparency = 1; InvScroll.ScrollBarThickness = 6; InvScroll.BorderSizePixel = 0; InvScroll.ZIndex = 52
	local invLayout = Instance.new("UIListLayout", InvScroll); invLayout.Padding = UDim.new(0, 10); invLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InvScroll.CanvasSize = UDim2.new(0,0,0, invLayout.AbsoluteContentSize.Y + 10) end)
	local noItemsLbl = UIHelpers.CreateLabel(InvPanel, "You have no items to deposit.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); noItemsLbl.Position = UDim2.new(0, 0, 0.5, 0); noItemsLbl.AnchorPoint = Vector2.new(0, 0.5); noItemsLbl.ZIndex = 52

	local activeVaultSlot = 1
	local function OpenInventorySelection(slotId)
		activeVaultSlot = slotId; InvOverlay.Visible = true; invTitle.Text = "DEPOSIT ITEM"; noItemsLbl.Visible = true
		for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
		local foundAny = false
		local function ScanItems(dictionary)
			for itemName, _ in pairs(dictionary) do
				local safeName = itemName:gsub("[^%w]", "") .. "Count"; local count = player:GetAttribute(safeName) or 0
				if count > 0 then
					foundAny = true; local btn, stroke = CreateSharpButton(InvScroll, count .. "x " .. itemName, UDim2.new(1, -10, 0, 45), Enum.Font.GothamBold, 12); btn.ZIndex = 53
					btn.MouseButton1Click:Connect(function() InvOverlay.Visible = false; Network:WaitForChild("SquadAction"):FireServer("DepositItem", {Slot = activeVaultSlot, ItemName = itemName}) end)
				end
			end
		end
		ScanItems(ItemData.Equipment or {}); ScanItems(ItemData.Consumables or {}); noItemsLbl.Visible = not foundAny
	end

	local MySquadTab = activeSubFrames["MY SQUAD"]

	local NotInSquadView = Instance.new("Frame", MySquadTab); NotInSquadView.Size = UDim2.new(1, 0, 0, 400); NotInSquadView.BackgroundTransparency = 1; NotInSquadView.Visible = false
	local DashContainer, _ = CreateGrimPanel(NotInSquadView); DashContainer.Size = UDim2.new(1, 0, 1, 0)
	local niTitle = UIHelpers.CreateLabel(DashContainer, "SQUAD REGISTRATION", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); niTitle.Position = UDim2.new(0, 0, 0, 10)
	local niDesc = UIHelpers.CreateLabel(DashContainer, "Found a Strike Squad to accumulate global Squad Points (SP) and unlock utility perks for your members.", UDim2.new(0.9, 0, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); niDesc.Position = UDim2.new(0.05, 0, 0, 45); niDesc.TextWrapped = true

	local NameInput = CreateInput(DashContainer, "Squad Name (Max 20)", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 120))
	local DescInput = CreateInput(DashContainer, "Squad Description / Motto", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 175))
	local LogoInput = CreateInput(DashContainer, "Logo ID (e.g. 12345678)", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.5, 0, 0, 230))

	local CreateBtn, cStroke = CreateSharpButton(DashContainer, "FOUND SQUAD (100K Dews)", UDim2.new(0.8, 0, 0, 50), Enum.Font.GothamBlack, 14, "#FFD700"); CreateBtn.Position = UDim2.new(0.5, 0, 0, 300); CreateBtn.AnchorPoint = Vector2.new(0.5, 0); CreateBtn.TextColor3 = UIHelpers.Colors.Gold
	CreateBtn.MouseButton1Click:Connect(function() if NameInput.Text ~= "" then Network:WaitForChild("SquadAction"):FireServer("Create", {Name = NameInput.Text, Desc = DescInput.Text, Logo = LogoInput.Text}) end end)

	local InSquadView = Instance.new("Frame", MySquadTab); InSquadView.Size = UDim2.new(1, 0, 0, 800); InSquadView.BackgroundTransparency = 1; InSquadView.Visible = true

	local HeaderPanel = Instance.new("Frame", InSquadView); HeaderPanel.Size = UDim2.new(1, 0, 0, 130); CreateGrimPanel(HeaderPanel)
	local SquadLogo = Instance.new("ImageLabel", HeaderPanel); SquadLogo.Size = UDim2.new(0, 90, 0, 90); SquadLogo.Position = UDim2.new(0, 10, 0, 20); SquadLogo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Instance.new("UIStroke", SquadLogo).Color = UIHelpers.Colors.Gold; Instance.new("UICorner", SquadLogo).CornerRadius = UDim.new(0, 6)
	local SquadNameLbl = UIHelpers.CreateLabel(HeaderPanel, "SQUAD NAME", UDim2.new(1, -120, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); SquadNameLbl.Position = UDim2.new(0, 110, 0, 15); SquadNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	local SquadDescLbl = UIHelpers.CreateLabel(HeaderPanel, "Squad Description goes here.", UDim2.new(1, -120, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11); SquadDescLbl.Position = UDim2.new(0, 110, 0, 45); SquadDescLbl.TextXAlignment = Enum.TextXAlignment.Left; SquadDescLbl.TextWrapped = true
	local SpLabel = UIHelpers.CreateLabel(HeaderPanel, "TOTAL SP: 0", UDim2.new(1, -120, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(85, 170, 255), 14); SpLabel.Position = UDim2.new(0, 110, 0, 85); SpLabel.TextXAlignment = Enum.TextXAlignment.Left

	local LeaveDisbandBtn, ldStroke = CreateSharpButton(HeaderPanel, "LEAVE SQUAD", UDim2.new(0, 100, 0, 25), Enum.Font.GothamBlack, 10, "#FF5555"); LeaveDisbandBtn.Position = UDim2.new(1, -10, 0, 10); LeaveDisbandBtn.AnchorPoint = Vector2.new(1, 0); LeaveDisbandBtn.TextColor3 = Color3.fromRGB(255, 85, 85)

	local PerksPanel = Instance.new("Frame", InSquadView); PerksPanel.Size = UDim2.new(1, 0, 0, 100); PerksPanel.Position = UDim2.new(0, 0, 0, 145); CreateGrimPanel(PerksPanel)
	local pkTitle = UIHelpers.CreateLabel(PerksPanel, "ACTIVE SQUAD PERKS", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14); pkTitle.Position = UDim2.new(0, 0, 0, 5)
	local pkDesc = UIHelpers.CreateLabel(PerksPanel, "Logistics II: Max Members +10\nTreasury I: Bounty Dews +10%\nArmory I: Vault Capacity +5", UDim2.new(1, -20, 1, -35), Enum.Font.GothamMedium, Color3.fromRGB(85, 255, 85), 12); pkDesc.Position = UDim2.new(0, 10, 0, 30); pkDesc.TextXAlignment = Enum.TextXAlignment.Left; pkDesc.TextYAlignment = Enum.TextYAlignment.Top

	local RosterPanel = Instance.new("Frame", InSquadView); RosterPanel.Size = UDim2.new(1, 0, 0, 480); RosterPanel.Position = UDim2.new(0, 0, 0, 260); CreateGrimPanel(RosterPanel)
	local RosterTitle = UIHelpers.CreateLabel(RosterPanel, "ACTIVE ROSTER", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16); RosterTitle.Position = UDim2.new(0, 10, 0, 5); RosterTitle.TextXAlignment = Enum.TextXAlignment.Left

	local RosterList = Instance.new("ScrollingFrame", RosterPanel); RosterList.Size = UDim2.new(1, -20, 1, -45); RosterList.Position = UDim2.new(0, 10, 0, 35); RosterList.BackgroundTransparency = 1; RosterList.ScrollBarThickness = 4; RosterList.BorderSizePixel = 0
	local rlLayout = Instance.new("UIListLayout", RosterList); rlLayout.Padding = UDim.new(0, 8); rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RosterList.CanvasSize = UDim2.new(0,0,0, rlLayout.AbsoluteContentSize.Y + 10) end)

	local VaultTab = activeSubFrames["SQUAD VAULT"]
	local VaultNoSquad = UIHelpers.CreateLabel(VaultTab, "YOU MUST BE IN A SQUAD TO ACCESS THE VAULT.", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 16)
	local VaultActiveView = Instance.new("Frame", VaultTab); VaultActiveView.Size = UDim2.new(1, 0, 1, 0); VaultActiveView.BackgroundTransparency = 1; VaultActiveView.Visible = false

	local VaultHeader = UIHelpers.CreateLabel(VaultActiveView, "SQUAD VAULT", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20); VaultHeader.Position = UDim2.new(0, 0, 0, 0)
	local VaultDesc = UIHelpers.CreateLabel(VaultActiveView, "Tap on a slot to deposit or withdraw items. The bottom row is locked unless your Squad ranks #1 globally.", UDim2.new(1, 0, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); VaultDesc.Position = UDim2.new(0, 0, 0, 30); VaultDesc.TextWrapped = true

	local VaultGrid = Instance.new("ScrollingFrame", VaultActiveView); VaultGrid.Size = UDim2.new(1, 0, 1, -80); VaultGrid.Position = UDim2.new(0, 0, 0, 80); VaultGrid.BackgroundTransparency = 1; VaultGrid.ScrollBarThickness = 4; VaultGrid.BorderSizePixel = 0
	local vgLayout = Instance.new("UIGridLayout", VaultGrid); vgLayout.CellSize = UDim2.new(0, 80, 0, 80); vgLayout.CellPadding = UDim2.new(0, 15, 0, 15); vgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; vgLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() VaultGrid.CanvasSize = UDim2.new(0, 0, 0, vgLayout.AbsoluteContentSize.Y + 10) end)

	local vaultBtns = {}
	for i = 1, 9 do
		local vBtn, stroke = CreateSharpButton(VaultGrid, "Empty", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 12); vBtn.TextWrapped = true
		vBtn.MouseButton1Click:Connect(function()
			if not vBtn.Active then return end
			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end
			if squadVault[i] == "None" or not squadVault[i] then OpenInventorySelection(i) else Network:WaitForChild("SquadAction"):FireServer("WithdrawItem", {Slot = i}) end
		end)
		vaultBtns[i] = {Btn = vBtn, Stroke = stroke}
	end

	local function UpdateSquadUI()
		local mySquad = player:GetAttribute("SquadName")
		if mySquad and mySquad ~= "" and mySquad ~= "None" then
			NotInSquadView.Visible = false; InSquadView.Visible = true; VaultNoSquad.Visible = false; VaultActiveView.Visible = true
			local isFavored = player:GetAttribute("YmirFavored")
			if isFavored then SquadNameLbl.Text = "👑 " .. mySquad .. " [YMIR'S FAVORED]"; SquadNameLbl.TextColor3 = Color3.fromRGB(170, 85, 255) else SquadNameLbl.Text = mySquad; SquadNameLbl.TextColor3 = UIHelpers.Colors.Gold end
			SquadDescLbl.Text = player:GetAttribute("SquadDesc") or "No description set."; local rawLogo = player:GetAttribute("SquadLogo") or ""
			if rawLogo ~= "" then SquadLogo.Image = string.match(rawLogo, "rbxassetid") and rawLogo or "rbxassetid://" .. rawLogo:match("%d+") end
			SpLabel.Text = "TOTAL SP: " .. (player:GetAttribute("SquadSP") or 0)

			local isLeader = player:GetAttribute("SquadIsLeader"); if InSquadView:FindFirstChild("ManageReqsBtn") then InSquadView.ManageReqsBtn:Destroy() end
			if isLeader then
				LeaveDisbandBtn.Text = "DISBAND SQUAD"
				LeaveDisbandBtn.MouseButton1Click:Connect(function() ShowConfirm("DISBAND SQUAD", "Are you sure you want to DISBAND your squad? This action is permanent and all items in the Vault will be lost.", function() Network:WaitForChild("SquadAction"):FireServer("Disband") end) end)
				local reqBtn, rStrk = CreateSharpButton(InSquadView, "VIEW REQUESTS", UDim2.new(0, 100, 0, 25), Enum.Font.GothamBlack, 10); reqBtn.Name = "ManageReqsBtn"; reqBtn.Position = UDim2.new(1, -120, 0, 10); reqBtn.AnchorPoint = Vector2.new(1, 0); reqBtn.TextColor3 = UIHelpers.Colors.Gold; rStrk.Color = UIHelpers.Colors.Gold
				reqBtn.MouseButton1Click:Connect(function()
					local reqs = Network:WaitForChild("GetSquadRequests"):InvokeServer()
					if #reqs == 0 then reqBtn.Text = "NO REQUESTS"; task.delay(1.5, function() reqBtn.Text = "VIEW REQUESTS" end); return end
					InvOverlay.Visible = true; invTitle.Text = "PENDING JOINS"; for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end; noItemsLbl.Visible = false
					for _, req in ipairs(reqs) do
						local rCard, _ = CreateGrimPanel(InvScroll); rCard.Size = UDim2.new(1, -10, 0, 45)
						local nLbl = UIHelpers.CreateLabel(rCard, req.Name, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14); nLbl.Position = UDim2.new(0, 10, 0, 0); nLbl.TextXAlignment = Enum.TextXAlignment.Left
						local accBtn = CreateSharpButton(rCard, "ACCEPT", UDim2.new(0, 60, 0, 30), Enum.Font.GothamBlack, 10, "#55FF55"); accBtn.Position = UDim2.new(1, -70, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5)
						local denBtn = CreateSharpButton(rCard, "DENY", UDim2.new(0, 50, 0, 30), Enum.Font.GothamBlack, 10, "#FF5555"); denBtn.Position = UDim2.new(1, -10, 0.5, 0); denBtn.AnchorPoint = Vector2.new(1, 0.5)
						accBtn.MouseButton1Click:Connect(function() rCard:Destroy(); Network:WaitForChild("SquadAction"):FireServer("ManageRequest", {TargetId = req.UserId, Decision = "Accept"}) end)
						denBtn.MouseButton1Click:Connect(function() rCard:Destroy(); Network:WaitForChild("SquadAction"):FireServer("ManageRequest", {TargetId = req.UserId, Decision = "Deny"}) end)
					end
				end)
			else
				LeaveDisbandBtn.Text = "LEAVE SQUAD"
				LeaveDisbandBtn.MouseButton1Click:Connect(function() ShowConfirm("LEAVE SQUAD", "Are you sure you want to leave your squad?", function() Network:WaitForChild("SquadAction"):FireServer("Leave") end) end)
			end

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

			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end

			for i = 1, 9 do
				local storeObj = vaultBtns[i]; local btn = storeObj.Btn; local storedItem = squadVault[i] or "None"
				if i > 6 and not isFavored then
					if storedItem ~= "None" then btn.Active = true; btn.Text = storedItem .. "\n(RECOVER)"; btn.TextColor3 = Color3.fromRGB(255, 100, 100); storeObj.Stroke.Color = Color3.fromRGB(255, 100, 100)
					else btn.Text = "LOCKED"; btn.TextColor3 = Color3.fromRGB(150, 50, 50); storeObj.Stroke.Color = Color3.fromRGB(150, 50, 50); btn.Active = false end
				else
					btn.Active = true; btn.Text = (storedItem == "None" and "Empty" or storedItem)
					if storedItem ~= "None" then storeObj.Stroke.Color = UIHelpers.Colors.Gold; btn.TextColor3 = Color3.fromRGB(230, 230, 230) else storeObj.Stroke.Color = UIHelpers.Colors.BorderMuted; btn.TextColor3 = UIHelpers.Colors.TextMuted end
				end
			end
		else 
			NotInSquadView.Visible = true; InSquadView.Visible = false; VaultNoSquad.Visible = true; VaultActiveView.Visible = false
		end
	end

	task.spawn(function()
		local publicSquads = Network:WaitForChild("GetPublicSquads"):InvokeServer()
		if publicSquads then for _, sq in ipairs(publicSquads) do AddSquadCard(sq.Name, sq.Desc, sq.Logo, sq.Level, sq.MemberCount, sq.SP) end end
	end)

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Squad") or attr == "YmirFavored" then UpdateSquadUI() end end); UpdateSquadUI()

	local FinderTab = activeSubFrames["SQUAD FINDER"]
	local finderTitle = UIHelpers.CreateLabel(FinderTab, "PUBLIC DIRECTORY", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18); finderTitle.Position = UDim2.new(0, 10, 0, 0); finderTitle.TextXAlignment = Enum.TextXAlignment.Left

	function AddSquadCard(sqName, sqDesc, sqLogo, sqLevel, memberCount, spScore)
		local card, _ = CreateGrimPanel(FinderTab); card.Size = UDim2.new(1, -10, 0, 110)
		local logo = Instance.new("ImageLabel", card); logo.Size = UDim2.new(0, 50, 0, 50); logo.Position = UDim2.new(0, 10, 0, 10); logo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); logo.Image = sqLogo; Instance.new("UIStroke", logo).Color = UIHelpers.Colors.BorderMuted; Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 4)
		local nameLbl = UIHelpers.CreateLabel(card, sqName, UDim2.new(1, -75, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14); nameLbl.Position = UDim2.new(0, 70, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		local descLbl = UIHelpers.CreateLabel(card, sqDesc, UDim2.new(1, -75, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 11); descLbl.Position = UDim2.new(0, 70, 0, 30); descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextWrapped = true
		local statsLbl = UIHelpers.CreateLabel(card, "Lv. " .. sqLevel .. " | " .. memberCount .. " Members | " .. spScore .. " SP", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 10); statsLbl.Position = UDim2.new(0, 10, 1, -30); statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		local reqBtn, rStroke = CreateSharpButton(card, "REQUEST JOIN", UDim2.new(0, 100, 0, 30), Enum.Font.GothamBlack, 11); reqBtn.Position = UDim2.new(1, -10, 1, -10); reqBtn.AnchorPoint = Vector2.new(1, 1); reqBtn.TextColor3 = Color3.fromRGB(85, 170, 255); rStroke.Color = Color3.fromRGB(85, 170, 255)
		reqBtn.MouseButton1Click:Connect(function() Network:WaitForChild("SquadAction"):FireServer("RequestJoin", sqName); reqBtn.Text = "REQUEST SENT"; reqBtn.TextColor3 = Color3.fromRGB(150, 150, 150); rStroke.Color = UIHelpers.Colors.BorderMuted; reqBtn.Active = false end)
	end
end

return MobileSquadsTab