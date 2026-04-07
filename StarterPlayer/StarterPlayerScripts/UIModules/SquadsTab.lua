-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: SquadsTab
local SquadsTab = {}

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

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function() 
		if btn.Active then 
			btn:SetAttribute("OrigColor", btn.TextColor3)
			btn:SetAttribute("OrigStroke", stroke.Color)
			stroke.Color = UIHelpers.Colors.Gold
			btn.TextColor3 = UIHelpers.Colors.Gold 
		end
	end)
	btn.MouseLeave:Connect(function() 
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

function SquadsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainFrame = Instance.new("Frame", parentFrame); MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1
	local mLayout = Instance.new("UIListLayout", MainFrame); mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 15); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", MainFrame).PaddingTop = UDim.new(0, 15)

	local Title = UIHelpers.CreateLabel(MainFrame, "STRIKE SQUADS COMMAND", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 26); Title.LayoutOrder = 1

	local SubNav = Instance.new("Frame", MainFrame); SubNav.Size = UDim2.new(0.95, 0, 0, 45); SubNav.BackgroundTransparency = 1; SubNav.LayoutOrder = 2
	local navLayout = Instance.new("UIListLayout", SubNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 10)

	local ContentArea = Instance.new("Frame", MainFrame); ContentArea.Size = UDim2.new(0.95, 0, 1, -120); ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 3

	local subTabs = { "MY SQUAD", "SQUAD VAULT", "SQUAD FINDER" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNav, tabName, UDim2.new(0, 160, 0, 30), Enum.Font.GothamBold, 12)
		btn.TextColor3 = UIHelpers.Colors.TextMuted; stroke.Color = UIHelpers.Colors.BorderMuted

		local subFrame = Instance.new("Frame", ContentArea); subFrame.Name = tabName; subFrame.Size = UDim2.new(1, 0, 1, 0); subFrame.BackgroundTransparency = 1; subFrame.Visible = (i == 1)
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
	ConfirmPanel.Size = UDim2.new(0, 400, 0, 220); ConfirmPanel.Position = UDim2.new(0.5, 0, 0.5, 0); ConfirmPanel.AnchorPoint = Vector2.new(0.5, 0.5); ConfirmPanel.ZIndex = 101

	local cTitle = UIHelpers.CreateLabel(ConfirmPanel, "WARNING", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 85, 85), 24); cTitle.ZIndex = 102
	local cDesc = UIHelpers.CreateLabel(ConfirmPanel, "Are you sure you want to do this?", UDim2.new(0.9, 0, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 16); cDesc.Position = UDim2.new(0.05, 0, 0, 50); cDesc.TextWrapped = true; cDesc.ZIndex = 102

	local cYes, cYesStr = CreateSharpButton(ConfirmPanel, "CONFIRM", UDim2.new(0, 150, 0, 45), Enum.Font.GothamBlack, 16); cYes.Position = UDim2.new(0, 30, 1, -60); cYes.TextColor3 = Color3.fromRGB(255, 85, 85); cYesStr.Color = Color3.fromRGB(255, 85, 85); cYes.ZIndex = 102
	local cNo, _ = CreateSharpButton(ConfirmPanel, "CANCEL", UDim2.new(0, 150, 0, 45), Enum.Font.GothamBlack, 16); cNo.Position = UDim2.new(1, -180, 1, -60); cNo.ZIndex = 102
	cNo.MouseButton1Click:Connect(function() ConfirmOverlay.Visible = false end)

	local function ShowConfirm(title, desc, onConfirm)
		cTitle.Text = title; cDesc.Text = desc
		local conn; conn = cYes.MouseButton1Click:Connect(function() conn:Disconnect(); ConfirmOverlay.Visible = false; onConfirm() end)
		ConfirmOverlay.Visible = true
	end

	local InvOverlay = Instance.new("Frame", MainFrame); InvOverlay.Size = UDim2.new(1, 0, 1, 0); InvOverlay.BackgroundColor3 = Color3.new(0,0,0); InvOverlay.BackgroundTransparency = 0.6; InvOverlay.ZIndex = 50; InvOverlay.Visible = false; InvOverlay.Active = true
	local InvPanel, _ = CreateGrimPanel(InvOverlay); InvPanel.Size = UDim2.new(0, 400, 0, 500); InvPanel.Position = UDim2.new(0.5, 0, 0.5, 0); InvPanel.AnchorPoint = Vector2.new(0.5, 0.5); InvPanel.ZIndex = 51
	local invTitle = UIHelpers.CreateLabel(InvPanel, "DEPOSIT ITEM", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20); invTitle.ZIndex = 52
	local closeInvBtn, _ = CreateSharpButton(InvPanel, "X", UDim2.new(0, 40, 0, 40), Enum.Font.GothamBlack, 18); closeInvBtn.Position = UDim2.new(1, -10, 0, 10); closeInvBtn.AnchorPoint = Vector2.new(1, 0); closeInvBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeInvBtn.ZIndex = 52; closeInvBtn.MouseButton1Click:Connect(function() InvOverlay.Visible = false end)
	local InvScroll = Instance.new("ScrollingFrame", InvPanel); InvScroll.Size = UDim2.new(1, -20, 1, -70); InvScroll.Position = UDim2.new(0, 10, 0, 60); InvScroll.BackgroundTransparency = 1; InvScroll.ScrollBarThickness = 6; InvScroll.BorderSizePixel = 0; InvScroll.ZIndex = 52
	local invLayout = Instance.new("UIListLayout", InvScroll); invLayout.Padding = UDim.new(0, 10); invLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InvScroll.CanvasSize = UDim2.new(0,0,0, invLayout.AbsoluteContentSize.Y + 10) end)
	local noItemsLbl = UIHelpers.CreateLabel(InvPanel, "You have no items to deposit.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); noItemsLbl.Position = UDim2.new(0, 0, 0.5, 0); noItemsLbl.AnchorPoint = Vector2.new(0, 0.5); noItemsLbl.ZIndex = 52

	local activeVaultSlot = 1
	local function OpenInventorySelection(slotId)
		activeVaultSlot = slotId; InvOverlay.Visible = true
		invTitle.Text = "DEPOSIT ITEM"
		noItemsLbl.Visible = true
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

	-- MY SQUAD TAB
	local MySquadTab = activeSubFrames["MY SQUAD"]
	local SplitContainer = Instance.new("Frame", MySquadTab); SplitContainer.Size = UDim2.new(1, 0, 1, 0); SplitContainer.BackgroundTransparency = 1
	local scLayout = Instance.new("UIListLayout", SplitContainer); scLayout.FillDirection = Enum.FillDirection.Horizontal; scLayout.Padding = UDim.new(0, 20)

	local LeftPanel = Instance.new("Frame", SplitContainer); LeftPanel.Size = UDim2.new(0.55, 0, 1, 0); LeftPanel.BackgroundTransparency = 1
	local DashContainer, _ = CreateGrimPanel(LeftPanel); DashContainer.Size = UDim2.new(1, 0, 1, 0)

	local NotInSquadView = Instance.new("Frame", DashContainer); NotInSquadView.Size = UDim2.new(1, 0, 1, 0); NotInSquadView.BackgroundTransparency = 1; NotInSquadView.Visible = false
	local niTitle = UIHelpers.CreateLabel(NotInSquadView, "SQUAD REGISTRATION", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); niTitle.Position = UDim2.new(0, 0, 0, 20)
	local niDesc = UIHelpers.CreateLabel(NotInSquadView, "Found a Strike Squad to accumulate global Squad Points (SP) and unlock utility perks for your members.", UDim2.new(0.8, 0, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 13); niDesc.Position = UDim2.new(0.1, 0, 0, 60); niDesc.TextWrapped = true
	local NameInput = CreateInput(NotInSquadView, "Enter Squad Name (Max 20 Chars)", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 120))
	local DescInput = CreateInput(NotInSquadView, "Enter Squad Description / Motto", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 175))
	local LogoInput = CreateInput(NotInSquadView, "Enter Logo Image ID (e.g. 12345678)", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 230))
	local CreateBtn, cStroke = CreateSharpButton(NotInSquadView, "FOUND SQUAD (100K Dews)", UDim2.new(0.6, 0, 0, 50), Enum.Font.GothamBlack, 16); CreateBtn.Position = UDim2.new(0.5, 0, 0, 300); CreateBtn.AnchorPoint = Vector2.new(0.5, 0); CreateBtn.TextColor3 = UIHelpers.Colors.Gold; cStroke.Color = UIHelpers.Colors.Gold
	CreateBtn.MouseButton1Click:Connect(function() if NameInput.Text ~= "" then Network:WaitForChild("SquadAction"):FireServer("Create", {Name = NameInput.Text, Desc = DescInput.Text, Logo = LogoInput.Text}) end end)

	local InSquadView = Instance.new("Frame", DashContainer); InSquadView.Size = UDim2.new(1, 0, 1, 0); InSquadView.BackgroundTransparency = 1; InSquadView.Visible = true
	local SquadLogo = Instance.new("ImageLabel", InSquadView); SquadLogo.Size = UDim2.new(0, 80, 0, 80); SquadLogo.Position = UDim2.new(0, 20, 0, 20); SquadLogo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Instance.new("UIStroke", SquadLogo).Color = UIHelpers.Colors.Gold
	local SquadNameLbl = UIHelpers.CreateLabel(InSquadView, "SQUAD NAME", UDim2.new(1, -120, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24); SquadNameLbl.Position = UDim2.new(0, 115, 0, 20); SquadNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	local SquadDescLbl = UIHelpers.CreateLabel(InSquadView, "Squad Description goes here.", UDim2.new(1, -120, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12); SquadDescLbl.Position = UDim2.new(0, 115, 0, 55); SquadDescLbl.TextXAlignment = Enum.TextXAlignment.Left; SquadDescLbl.TextWrapped = true
	local SpLabel = UIHelpers.CreateLabel(InSquadView, "TOTAL SP: 0", UDim2.new(1, -120, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(85, 170, 255), 14); SpLabel.Position = UDim2.new(0, 115, 0, 85); SpLabel.TextXAlignment = Enum.TextXAlignment.Left

	local LeaveDisbandBtn, ldStroke = CreateSharpButton(InSquadView, "LEAVE SQUAD", UDim2.new(0, 120, 0, 30), Enum.Font.GothamBlack, 10)
	LeaveDisbandBtn.Position = UDim2.new(1, -20, 0, 20); LeaveDisbandBtn.AnchorPoint = Vector2.new(1, 0); LeaveDisbandBtn.TextColor3 = Color3.fromRGB(255, 85, 85); ldStroke.Color = Color3.fromRGB(255, 85, 85)

	local RosterTitle = UIHelpers.CreateLabel(InSquadView, "ACTIVE ROSTER", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16); RosterTitle.Position = UDim2.new(0, 20, 0, 130); RosterTitle.TextXAlignment = Enum.TextXAlignment.Left
	local RosterList = Instance.new("ScrollingFrame", InSquadView); RosterList.Size = UDim2.new(1, -40, 1, -180); RosterList.Position = UDim2.new(0, 20, 0, 160); RosterList.BackgroundTransparency = 1; RosterList.ScrollBarThickness = 4; RosterList.BorderSizePixel = 0
	local rlLayout = Instance.new("UIListLayout", RosterList); rlLayout.Padding = UDim.new(0, 8); rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RosterList.CanvasSize = UDim2.new(0,0,0, rlLayout.AbsoluteContentSize.Y + 10) end)

	local RightPanel = Instance.new("Frame", SplitContainer); RightPanel.Size = UDim2.new(0.45, -20, 1, 0); RightPanel.BackgroundTransparency = 1
	local LbContainer, _ = CreateGrimPanel(RightPanel); LbContainer.Size = UDim2.new(1, 0, 0.6, 0)
	local lbTitle = UIHelpers.CreateLabel(LbContainer, "GLOBAL SQUAD LEADERBOARD", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18)
	local LbScroll = Instance.new("ScrollingFrame", LbContainer); LbScroll.Size = UDim2.new(1, -20, 1, -50); LbScroll.Position = UDim2.new(0, 10, 0, 40); LbScroll.BackgroundTransparency = 1; LbScroll.ScrollBarThickness = 4; LbScroll.BorderSizePixel = 0
	local lsLayout = Instance.new("UIListLayout", LbScroll); lsLayout.Padding = UDim.new(0, 8); lsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LbScroll.CanvasSize = UDim2.new(0,0,0, lsLayout.AbsoluteContentSize.Y + 10) end)

	local PerksContainer, _ = CreateGrimPanel(RightPanel); PerksContainer.Size = UDim2.new(1, 0, 0.35, 0); PerksContainer.Position = UDim2.new(0, 0, 0.65, 0)
	local pkTitle = UIHelpers.CreateLabel(PerksContainer, "ACTIVE SQUAD PERKS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)
	local pkDesc = UIHelpers.CreateLabel(PerksContainer, "Logistics II: Max Members +10\nTreasury I: Bounty Dews +10%\nArmory I: Vault Capacity +5\nAcademy I: Auto-Train Efficiency +5%", UDim2.new(1, -40, 1, -40), Enum.Font.GothamMedium, Color3.fromRGB(85, 255, 85), 13); pkDesc.Position = UDim2.new(0, 20, 0, 30); pkDesc.TextXAlignment = Enum.TextXAlignment.Left; pkDesc.TextYAlignment = Enum.TextYAlignment.Top

	-- ==========================================
	-- SQUAD VAULT TAB
	-- ==========================================
	local VaultTab = activeSubFrames["SQUAD VAULT"]

	local VaultNoSquad = UIHelpers.CreateLabel(VaultTab, "YOU MUST BE IN A SQUAD TO ACCESS THE VAULT.", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 20)
	local VaultActiveView = Instance.new("Frame", VaultTab); VaultActiveView.Size = UDim2.new(1, 0, 1, 0); VaultActiveView.BackgroundTransparency = 1; VaultActiveView.Visible = false

	local VaultPanel, _ = CreateGrimPanel(VaultActiveView); VaultPanel.Size = UDim2.new(0.8, 0, 0.8, 0); VaultPanel.Position = UDim2.new(0.5, 0, 0.5, 0); VaultPanel.AnchorPoint = Vector2.new(0.5, 0.5)

	local VaultHeader = UIHelpers.CreateLabel(VaultPanel, "SQUAD VAULT", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); VaultHeader.Position = UDim2.new(0, 0, 0, 10)
	local VaultDesc = UIHelpers.CreateLabel(VaultPanel, "Click on a slot to deposit or withdraw items. The bottom row is locked unless your Squad ranks #1 globally.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); VaultDesc.Position = UDim2.new(0, 0, 0, 45)

	local VaultGrid = Instance.new("Frame", VaultPanel)
	VaultGrid.Size = UDim2.new(0.8, 0, 0.7, 0); VaultGrid.Position = UDim2.new(0.5, 0, 0.55, 0); VaultGrid.AnchorPoint = Vector2.new(0.5, 0.5); VaultGrid.BackgroundTransparency = 1
	local vgLayout = Instance.new("UIGridLayout", VaultGrid); vgLayout.CellSize = UDim2.new(0.3, -10, 0.3, -10); vgLayout.CellPadding = UDim2.new(0, 15, 0, 15); vgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; vgLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local vaultBtns = {}
	for i = 1, 9 do
		local vBtn, stroke = CreateSharpButton(VaultGrid, "Empty", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 14); vBtn.TextWrapped = true
		vBtn.MouseButton1Click:Connect(function()
			if not vBtn.Active then return end
			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end
			if squadVault[i] == "None" or not squadVault[i] then OpenInventorySelection(i) else Network:WaitForChild("SquadAction"):FireServer("WithdrawItem", {Slot = i}) end
		end)
		vaultBtns[i] = {Btn = vBtn, Stroke = stroke}
	end

	-- ==========================================
	-- UPDATE LOGIC
	-- ==========================================
	local function UpdateSquadUI()
		local mySquad = player:GetAttribute("SquadName")
		if mySquad and mySquad ~= "" and mySquad ~= "None" then
			NotInSquadView.Visible = false; InSquadView.Visible = true
			VaultNoSquad.Visible = false; VaultActiveView.Visible = true

			local isFavored = player:GetAttribute("YmirFavored")
			if isFavored then
				SquadNameLbl.Text = "👑 " .. mySquad .. " [YMIR'S FAVORED]"
				SquadNameLbl.TextColor3 = Color3.fromRGB(170, 85, 255)
			else
				SquadNameLbl.Text = mySquad
				SquadNameLbl.TextColor3 = UIHelpers.Colors.Gold
			end

			SquadDescLbl.Text = player:GetAttribute("SquadDesc") or "No description set."
			local rawLogo = player:GetAttribute("SquadLogo") or ""
			if rawLogo ~= "" then SquadLogo.Image = string.match(rawLogo, "rbxassetid") and rawLogo or "rbxassetid://" .. rawLogo:match("%d+") end
			SpLabel.Text = "TOTAL SP: " .. (player:GetAttribute("SquadSP") or 0)

			local isLeader = player:GetAttribute("SquadIsLeader")
			if InSquadView:FindFirstChild("ManageReqsBtn") then InSquadView.ManageReqsBtn:Destroy() end

			if isLeader then
				LeaveDisbandBtn.Text = "DISBAND SQUAD"
				LeaveDisbandBtn.MouseButton1Click:Connect(function()
					ShowConfirm("DISBAND SQUAD", "Are you sure you want to DISBAND your squad? This action is permanent and all items in the Vault will be lost.", function()
						Network:WaitForChild("SquadAction"):FireServer("Disband")
					end)
				end)

				local reqBtn, rStrk = CreateSharpButton(InSquadView, "VIEW REQUESTS", UDim2.new(0, 120, 0, 30), Enum.Font.GothamBlack, 10)
				reqBtn.Name = "ManageReqsBtn"
				reqBtn.Position = UDim2.new(1, -150, 0, 20)
				reqBtn.AnchorPoint = Vector2.new(1, 0)
				reqBtn.TextColor3 = UIHelpers.Colors.Gold
				rStrk.Color = UIHelpers.Colors.Gold

				reqBtn.MouseButton1Click:Connect(function()
					local reqs = Network:WaitForChild("GetSquadRequests"):InvokeServer()
					if #reqs == 0 then
						reqBtn.Text = "NO REQUESTS"
						task.delay(1.5, function() reqBtn.Text = "VIEW REQUESTS" end)
						return
					end

					InvOverlay.Visible = true
					invTitle.Text = "PENDING JOINS"
					for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
					noItemsLbl.Visible = false

					for _, req in ipairs(reqs) do
						local rCard, _ = CreateGrimPanel(InvScroll)
						rCard.Size = UDim2.new(1, -10, 0, 45)

						local nLbl = UIHelpers.CreateLabel(rCard, req.Name, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
						nLbl.Position = UDim2.new(0, 10, 0, 0); nLbl.TextXAlignment = Enum.TextXAlignment.Left

						local accBtn = CreateSharpButton(rCard, "ACCEPT", UDim2.new(0, 70, 0, 30), Enum.Font.GothamBlack, 11)
						accBtn.Position = UDim2.new(1, -80, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5)
						accBtn.TextColor3 = Color3.fromRGB(85, 255, 85)

						local denBtn = CreateSharpButton(rCard, "DENY", UDim2.new(0, 60, 0, 30), Enum.Font.GothamBlack, 11)
						denBtn.Position = UDim2.new(1, -10, 0.5, 0); denBtn.AnchorPoint = Vector2.new(1, 0.5)
						denBtn.TextColor3 = Color3.fromRGB(255, 85, 85)

						accBtn.MouseButton1Click:Connect(function() 
							rCard:Destroy()
							Network:WaitForChild("SquadAction"):FireServer("ManageRequest", {TargetId = req.UserId, Decision = "Accept"}) 
						end)
						denBtn.MouseButton1Click:Connect(function() 
							rCard:Destroy()
							Network:WaitForChild("SquadAction"):FireServer("ManageRequest", {TargetId = req.UserId, Decision = "Deny"}) 
						end)
					end
				end)
			else
				LeaveDisbandBtn.Text = "LEAVE SQUAD"
				LeaveDisbandBtn.MouseButton1Click:Connect(function()
					ShowConfirm("LEAVE SQUAD", "Are you sure you want to leave your squad?", function()
						Network:WaitForChild("SquadAction"):FireServer("Leave")
					end)
				end)
			end

			task.spawn(function()
				for _, c in ipairs(RosterList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
				local rosterData = Network:WaitForChild("GetSquadRoster"):InvokeServer()
				if rosterData then
					for _, member in ipairs(rosterData) do
						local mCard, _ = CreateGrimPanel(RosterList); mCard.Size = UDim2.new(1, -10, 0, 40)
						local mName = UIHelpers.CreateLabel(mCard, member.Name, UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14); mName.Position = UDim2.new(0, 15, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left
						local mRole = UIHelpers.CreateLabel(mCard, member.Role, UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); mRole.Position = UDim2.new(0.7, -15, 0, 0); mRole.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
			end)

			local rawVault = player:GetAttribute("SquadVault"); local squadVault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then pcall(function() squadVault = HttpService:JSONDecode(rawVault) end) end

			for i = 1, 9 do
				local storeObj = vaultBtns[i]; local btn = storeObj.Btn
				local storedItem = squadVault[i] or "None"

				if i > 6 and not isFavored then
					if storedItem ~= "None" then
						btn.Active = true
						btn.Text = storedItem .. "\n(TAP TO RECOVER)"
						btn.TextColor3 = Color3.fromRGB(255, 100, 100)
						storeObj.Stroke.Color = Color3.fromRGB(255, 100, 100)
					else
						btn.Text = "LOCKED\n(#1 Squad)"
						btn.TextColor3 = Color3.fromRGB(150, 50, 50)
						storeObj.Stroke.Color = Color3.fromRGB(150, 50, 50)
						btn.Active = false
					end
				else
					btn.Active = true
					btn.Text = (storedItem == "None" and "Empty" or storedItem)
					if storedItem ~= "None" then storeObj.Stroke.Color = UIHelpers.Colors.Gold; btn.TextColor3 = Color3.fromRGB(230, 230, 230) else storeObj.Stroke.Color = UIHelpers.Colors.BorderMuted; btn.TextColor3 = UIHelpers.Colors.TextMuted end
				end
			end
		else 
			NotInSquadView.Visible = true; InSquadView.Visible = false 
			VaultNoSquad.Visible = true; VaultActiveView.Visible = false
		end
	end

	task.spawn(function()
		for _, c in ipairs(LbScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local lbData = Network:WaitForChild("GetSquadLeaderboard"):InvokeServer()
		if lbData then
			for i, data in ipairs(lbData) do
				local rankCard, _ = CreateGrimPanel(LbScroll); rankCard.Size = UDim2.new(1, -10, 0, 35)
				local cColor = (i==1) and UIHelpers.Colors.Gold or ((i==2) and Color3.fromRGB(200, 200, 200) or UIHelpers.Colors.TextWhite)
				local rNum = UIHelpers.CreateLabel(rankCard, "#" .. data.Rank, UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, cColor, 14); rNum.Position = UDim2.new(0, 10, 0, 0)
				local sName = UIHelpers.CreateLabel(rankCard, data.Name, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, cColor, 14); sName.Position = UDim2.new(0, 50, 0, 0); sName.TextXAlignment = Enum.TextXAlignment.Left
				local sCp = UIHelpers.CreateLabel(rankCard, tostring(data.SP) .. " SP", UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); sCp.Position = UDim2.new(0.7, -10, 0, 0); sCp.TextXAlignment = Enum.TextXAlignment.Right
			end
		end
	end)

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Squad") or attr == "YmirFavored" then UpdateSquadUI() end end); UpdateSquadUI()

	-- ==========================================
	-- SQUAD FINDER TAB
	-- ==========================================
	local FinderTab = activeSubFrames["SQUAD FINDER"]
	local FinderContainer, _ = CreateGrimPanel(FinderTab); FinderContainer.Size = UDim2.new(1, 0, 1, 0)
	local finderTitle = UIHelpers.CreateLabel(FinderContainer, "PUBLIC SQUAD DIRECTORY", UDim2.new(1, -40, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20); finderTitle.Position = UDim2.new(0, 20, 0, 10); finderTitle.TextXAlignment = Enum.TextXAlignment.Left
	local FinderScroll = Instance.new("ScrollingFrame", FinderContainer); FinderScroll.Size = UDim2.new(1, -40, 1, -70); FinderScroll.Position = UDim2.new(0, 20, 0, 50); FinderScroll.BackgroundTransparency = 1; FinderScroll.ScrollBarThickness = 6; FinderScroll.BorderSizePixel = 0
	local fsLayout = Instance.new("UIListLayout", FinderScroll); fsLayout.Padding = UDim.new(0, 10); fsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() FinderScroll.CanvasSize = UDim2.new(0,0,0, fsLayout.AbsoluteContentSize.Y + 20) end)

	local function AddSquadCard(sqName, sqDesc, sqLogo, sqLevel, memberCount, spScore)
		local card, _ = CreateGrimPanel(FinderScroll); card.Size = UDim2.new(1, -10, 0, 80); card.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		local logo = Instance.new("ImageLabel", card); logo.Size = UDim2.new(0, 60, 0, 60); logo.Position = UDim2.new(0, 10, 0, 10); logo.BackgroundColor3 = Color3.fromRGB(15, 15, 18); logo.Image = sqLogo; Instance.new("UIStroke", logo).Color = UIHelpers.Colors.BorderMuted

		local nameLbl = UIHelpers.CreateLabel(card, sqName, UDim2.new(0.5, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16); nameLbl.Position = UDim2.new(0, 85, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		local descLbl = UIHelpers.CreateLabel(card, sqDesc, UDim2.new(0.5, 0, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12); descLbl.Position = UDim2.new(0, 85, 0, 35); descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextWrapped = true

		local statsLbl = UIHelpers.CreateLabel(card, "Lv. " .. sqLevel .. " | " .. memberCount .. " Members | " .. spScore .. " SP", UDim2.new(0.3, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12); statsLbl.Position = UDim2.new(1, -160, 0, 10); statsLbl.AnchorPoint = Vector2.new(1, 0); statsLbl.TextXAlignment = Enum.TextXAlignment.Right
		local reqBtn, rStroke = CreateSharpButton(card, "REQUEST JOIN", UDim2.new(0, 140, 0, 35), Enum.Font.GothamBlack, 12); reqBtn.Position = UDim2.new(1, -15, 1, -10); reqBtn.AnchorPoint = Vector2.new(1, 1); reqBtn.TextColor3 = Color3.fromRGB(85, 170, 255); rStroke.Color = Color3.fromRGB(85, 170, 255)
		reqBtn.MouseButton1Click:Connect(function() Network:WaitForChild("SquadAction"):FireServer("RequestJoin", sqName); reqBtn.Text = "REQUEST SENT"; reqBtn.TextColor3 = Color3.fromRGB(150, 150, 150); rStroke.Color = UIHelpers.Colors.BorderMuted; reqBtn.Active = false end)
	end

	task.spawn(function()
		local publicSquads = Network:WaitForChild("GetPublicSquads"):InvokeServer()
		if publicSquads then for _, sq in ipairs(publicSquads) do AddSquadCard(sq.Name, sq.Desc, sq.Logo, sq.Level, sq.MemberCount, sq.SP) end end
	end)
end

return SquadsTab