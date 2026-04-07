-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileExpeditionsTab
-- @ScriptType: ModuleScript
local MobileExpeditionsTab = {}

local Players = game:GetService("Players"); local ReplicatedStorage = game:GetService("ReplicatedStorage"); local TweenService = game:GetService("TweenService"); local Network = ReplicatedStorage:WaitForChild("Network")
local player = Players.LocalPlayer; local playerScripts = player:WaitForChild("PlayerScripts"); local SharedUI = playerScripts:WaitForChild("SharedUI"); local UIModules = playerScripts:WaitForChild("UIModules")

local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local AFKTab = require(UIModules:WaitForChild("AFKTab"))

local CONFIG = { Decals = { Campaign = "rbxassetid://80153476985849", AFK = "rbxassetid://114506098039778", Raid = "rbxassetid://119392967268687", PvP = "rbxassetid://100826303284945", Nightmare = "rbxassetid://90132878979603", WorldBoss = "rbxassetid://129655150803684", Endless = "rbxassetid://108619507999123" } }

local CurrentParty = {}; local IsInParty = false; local IsPartyLeader = false; local PendingInvites = {}; local isListening = false

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22); frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent); btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.InputBegan:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.InputEnded:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

function MobileExpeditionsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local TopContainer = Instance.new("Frame", parentFrame)
	TopContainer.Size = UDim2.new(1, 0, 1, -120)
	TopContainer.Position = UDim2.new(0, 0, 0, 0)
	TopContainer.BackgroundTransparency = 1

	local BottomContainer = Instance.new("Frame", parentFrame)
	BottomContainer.Size = UDim2.new(1, 0, 0, 110)
	BottomContainer.Position = UDim2.new(0, 0, 1, -10)
	BottomContainer.AnchorPoint = Vector2.new(0, 1)
	BottomContainer.BackgroundTransparency = 1

	local MasterScroll = Instance.new("ScrollingFrame", TopContainer)
	MasterScroll.Size = UDim2.new(1, 0, 1, 0); MasterScroll.BackgroundTransparency = 1; MasterScroll.ScrollBarThickness = 8; MasterScroll.BorderSizePixel = 0; MasterScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local masterLayout = Instance.new("UIListLayout", MasterScroll); masterLayout.SortOrder = Enum.SortOrder.LayoutOrder; masterLayout.Padding = UDim.new(0, 20); masterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local masterPad = Instance.new("UIPadding", MasterScroll); masterPad.PaddingTop = UDim.new(0, 15); masterPad.PaddingBottom = UDim.new(0, 30)

	local PartyPanel, _ = CreateGrimPanel(BottomContainer)
	PartyPanel.Size = UDim2.new(0.95, 0, 1, 0)
	PartyPanel.Position = UDim2.new(0.5, 0, 0, 0)
	PartyPanel.AnchorPoint = Vector2.new(0.5, 0)
	local ppLayout = Instance.new("UIListLayout", PartyPanel); ppLayout.Padding = UDim.new(0, 5); ppLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local ppPad = Instance.new("UIPadding", PartyPanel); ppPad.PaddingTop = UDim.new(0, 10); ppPad.PaddingBottom = UDim.new(0, 10)

	local function RenderPartyUI()
		for _, child in ipairs(PartyPanel:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

		if IsInParty then
			local Header = UIHelpers.CreateLabel(PartyPanel, "STRIKE TEAM (" .. #CurrentParty .. "/3)", UDim2.new(0.9, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16); Header.LayoutOrder = 1; Header.TextXAlignment = Enum.TextXAlignment.Center

			local RosterFrame = Instance.new("Frame", PartyPanel); RosterFrame.Size = UDim2.new(0.9, 0, 0, 0); RosterFrame.AutomaticSize = Enum.AutomaticSize.Y; RosterFrame.BackgroundTransparency = 1; RosterFrame.LayoutOrder = 2
			local rLayout = Instance.new("UIListLayout", RosterFrame); rLayout.Padding = UDim.new(0, 4)

			for _, member in ipairs(CurrentParty) do
				local mCard, mStroke = CreateGrimPanel(RosterFrame); mCard.Size = UDim2.new(1, 0, 0, 30)
				local mName = UIHelpers.CreateLabel(mCard, member.Name, UDim2.new(1, -45, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12); mName.Position = UDim2.new(0, 10, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left
				if member.IsLeader then local crown = UIHelpers.CreateLabel(mCard, "👑", UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12); crown.Position = UDim2.new(1, -30, 0, 0) end
			end

			if IsPartyLeader then
				local InviteContainer = Instance.new("Frame", PartyPanel); InviteContainer.Size = UDim2.new(0.9, 0, 0, 30); InviteContainer.BackgroundTransparency = 1; InviteContainer.LayoutOrder = 3
				local NameInput = Instance.new("TextBox", InviteContainer); NameInput.Size = UDim2.new(0.7, -5, 1, 0); NameInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25); NameInput.TextColor3 = UIHelpers.Colors.TextWhite; NameInput.Font = Enum.Font.GothamMedium; NameInput.TextSize = 12; NameInput.PlaceholderText = "Username..."; NameInput.Text = ""; NameInput.BorderSizePixel = 0; Instance.new("UIStroke", NameInput).Color = UIHelpers.Colors.BorderMuted

				local InvBtn, _ = CreateSharpButton(InviteContainer, "INVITE", UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamBlack, 10); InvBtn.Position = UDim2.new(1, 0, 0, 0); InvBtn.AnchorPoint = Vector2.new(1, 0)
				InvBtn.MouseButton1Click:Connect(function() if NameInput.Text ~= "" then Network:WaitForChild("PartyAction"):FireServer("Invite", NameInput.Text); NameInput.Text = "" end end)
			end

			local LeaveBtn, _ = CreateSharpButton(PartyPanel, "LEAVE TEAM", UDim2.new(0.9, 0, 0, 30), Enum.Font.GothamBlack, 12); LeaveBtn.LayoutOrder = 4; LeaveBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			LeaveBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Leave") end)
		else
			local Header = UIHelpers.CreateLabel(PartyPanel, "SOLO DEPLOYMENT", UDim2.new(0.9, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 18); Header.LayoutOrder = 1
			local CreateBtn, _ = CreateSharpButton(PartyPanel, "CREATE TEAM", UDim2.new(0.9, 0, 0, 45), Enum.Font.GothamBlack, 16); CreateBtn.LayoutOrder = 2
			CreateBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Create") end)

			local inviteCount = 0; for k, v in pairs(PendingInvites) do inviteCount = inviteCount + 1 end
			if inviteCount > 0 then
				local invHeader = UIHelpers.CreateLabel(PartyPanel, "INCOMING INVITES", UDim2.new(0.9, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.Gold, 12); invHeader.LayoutOrder = 3
				local InvList = Instance.new("Frame", PartyPanel); InvList.Size = UDim2.new(0.9, 0, 0, 0); InvList.AutomaticSize = Enum.AutomaticSize.Y; InvList.BackgroundTransparency = 1; InvList.LayoutOrder = 4
				local ilLayout = Instance.new("UIListLayout", InvList); ilLayout.Padding = UDim.new(0, 8)

				for inviterName, _ in pairs(PendingInvites) do
					local iCard, _ = CreateGrimPanel(InvList); iCard.Size = UDim2.new(1, 0, 0, 40)
					local iName = UIHelpers.CreateLabel(iCard, inviterName, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14); iName.Position = UDim2.new(0, 10, 0, 0); iName.TextXAlignment = Enum.TextXAlignment.Left

					local accBtn, _ = CreateSharpButton(iCard, "JOIN", UDim2.new(0.35, 0, 0, 30), Enum.Font.GothamBlack, 12); accBtn.Position = UDim2.new(1, -5, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5); accBtn.TextColor3 = UIHelpers.Colors.Gold
					accBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("AcceptInvite", inviterName); PendingInvites[inviterName] = nil; RenderPartyUI() end)
				end
			end
		end
	end

	if not isListening then
		isListening = true
		local PartyUpdate = Network:WaitForChild("PartyUpdate")
		PartyUpdate.OnClientEvent:Connect(function(action, data)
			if action == "UpdateList" then
				IsInParty = true; CurrentParty = data; IsPartyLeader = false
				for _, mem in ipairs(CurrentParty) do if mem.UserId == player.UserId and mem.IsLeader then IsPartyLeader = true end end
				PendingInvites = {}; RenderPartyUI()
			elseif action == "IncomingInvite" then PendingInvites[data] = true; RenderPartyUI()
			elseif action == "Disbanded" then IsInParty = false; CurrentParty = {}; IsPartyLeader = false; RenderPartyUI() end
		end)
	end
	RenderPartyUI()

	local MissionsPanel = Instance.new("Frame", MasterScroll)
	MissionsPanel.Size = UDim2.new(1, 0, 0, 0); MissionsPanel.AutomaticSize = Enum.AutomaticSize.Y; MissionsPanel.BackgroundTransparency = 1; MissionsPanel.LayoutOrder = 2
	local mpLayout = Instance.new("UIListLayout", MissionsPanel); mpLayout.SortOrder = Enum.SortOrder.LayoutOrder; mpLayout.Padding = UDim.new(0, 15)

	local DeployOverlay = Instance.new("Frame", parentFrame.Parent) 
	DeployOverlay.Name = "DeploymentTransition"; DeployOverlay.Size = UDim2.new(1, 0, 1, 0); DeployOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 15); DeployOverlay.BackgroundTransparency = 1; DeployOverlay.ZIndex = 90; DeployOverlay.Visible = false
	local dStatus = UIHelpers.CreateLabel(DeployOverlay, "ESTABLISHING CONNECTION...", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24); dStatus.Position = UDim2.new(0, 0, 0.5, -20); dStatus.TextTransparency = 1; dStatus.ZIndex = 91

	local function InitiateDeployment(remoteName, action, payload)
		DeployOverlay.Visible = true; TweenService:Create(DeployOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.1}):Play(); TweenService:Create(dStatus, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		dStatus.Text = "PREPARING STRIKE TEAM..."; task.wait(0.6)
		dStatus.Text = "DEPLOYING TO COMBAT ZONE..."; dStatus.TextColor3 = Color3.fromRGB(255, 100, 100); task.wait(0.8)
		if payload then Network:WaitForChild(remoteName):FireServer(action, payload) else Network:WaitForChild(remoteName):FireServer(action) end
		local t1 = TweenService:Create(DeployOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}); local t2 = TweenService:Create(dStatus, TweenInfo.new(0.5), {TextTransparency = 1})
		t1:Play(); t2:Play(); t1.Completed:Wait(); DeployOverlay.Visible = false; dStatus.TextColor3 = UIHelpers.Colors.Gold
	end

	local function CreateModeCard(parent, title, desc, imageId, layoutOrder, onClick)
		local cardBtn = Instance.new("TextButton", parent); cardBtn.LayoutOrder = layoutOrder; cardBtn.Text = ""; cardBtn.AutoButtonColor = false; cardBtn.ClipsDescendants = true; local _, strk = CreateGrimPanel(cardBtn)
		local bg = Instance.new("ImageLabel", cardBtn); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundTransparency = 1; bg.Image = imageId; bg.ScaleType = Enum.ScaleType.Crop; bg.ZIndex = 1
		local gradFrame = Instance.new("Frame", cardBtn); gradFrame.Size = UDim2.new(1, 0, 1, 0); gradFrame.BackgroundColor3 = Color3.new(0,0,0); gradFrame.BorderSizePixel = 0; gradFrame.ZIndex = 2; local grad = Instance.new("UIGradient", gradFrame); grad.Rotation = 90; grad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0.1)}

		local lblTitle = UIHelpers.CreateLabel(cardBtn, title, UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18); lblTitle.Position = UDim2.new(0, 10, 1, -70); lblTitle.TextXAlignment = Enum.TextXAlignment.Left; lblTitle.TextScaled = true; lblTitle.ZIndex = 3; local tCon = Instance.new("UITextSizeConstraint", lblTitle); tCon.MaxTextSize = 18; tCon.MinTextSize = 12
		local lblDesc = UIHelpers.CreateLabel(cardBtn, desc, UDim2.new(1, -20, 0, 35), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12); lblDesc.Position = UDim2.new(0, 10, 1, -40); lblDesc.TextXAlignment = Enum.TextXAlignment.Left; lblDesc.TextYAlignment = Enum.TextYAlignment.Top; lblDesc.TextWrapped = true; lblDesc.ZIndex = 3

		cardBtn.InputBegan:Connect(function() strk.Color = UIHelpers.Colors.Gold; lblTitle.TextColor3 = UIHelpers.Colors.Gold; TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}):Play() end)
		cardBtn.InputEnded:Connect(function() strk.Color = UIHelpers.Colors.BorderMuted; lblTitle.TextColor3 = UIHelpers.Colors.TextWhite; TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play() end)
		cardBtn.MouseButton1Click:Connect(onClick)
		return lblDesc
	end

	local HeaderFrame = Instance.new("Frame", MissionsPanel); HeaderFrame.Size = UDim2.new(1, 0, 0, 40); HeaderFrame.BackgroundTransparency = 1; HeaderFrame.LayoutOrder = 1
	local Title = UIHelpers.CreateLabel(HeaderFrame, "COMBAT DEPLOYMENT", UDim2.new(1, -80, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); Title.Position = UDim2.new(0, 20, 0, 0); Title.TextXAlignment = Enum.TextXAlignment.Left

	local BackBtn, BackStroke = CreateSharpButton(HeaderFrame, "< BACK", UDim2.new(0, 70, 0, 30), Enum.Font.GothamBlack, 12)
	BackBtn.Position = UDim2.new(1, -15, 0.5, 0); BackBtn.AnchorPoint = Vector2.new(1, 0.5); BackBtn.Visible = false

	local Pages = {}; local FetchLiveMatches 
	local function ShowPage(pageName, titleText)
		for name, frame in pairs(Pages) do frame.Visible = (name == pageName) end
		Title.Text = titleText; BackBtn.Visible = (pageName ~= "Main")
		if pageName == "PvP" and FetchLiveMatches then FetchLiveMatches() end
	end
	BackBtn.MouseButton1Click:Connect(function() ShowPage("Main", "COMBAT DEPLOYMENT") end)

	local GridContainer = Instance.new("Frame", MissionsPanel); GridContainer.Size = UDim2.new(1, 0, 0, 0); GridContainer.AutomaticSize = Enum.AutomaticSize.Y; GridContainer.BackgroundTransparency = 1; GridContainer.LayoutOrder = 2
	Pages["Main"] = GridContainer

	local gridLayout = Instance.new("UIGridLayout", GridContainer)
	gridLayout.CellSize = UDim2.new(0.45, 0, 0, 160); gridLayout.CellPadding = UDim2.new(0.05, 0, 0, 20); gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local cPart = player:GetAttribute("CurrentPart") or 1; local cMiss = player:GetAttribute("CurrentMission") or 1
	local campaignDescLbl = CreateModeCard(GridContainer, "STORY CAMPAIGN", string.format("Part %d - Mission %d\nProgress through the main storyline.", cPart, cMiss), CONFIG.Decals.Campaign, 1, function() InitiateDeployment("CombatAction", "EngageStory") end)
	player.AttributeChanged:Connect(function(attr) if attr == "CurrentPart" or attr == "CurrentMission" then campaignDescLbl.Text = string.format("Part %d - Mission %d\nProgress through the main storyline.", player:GetAttribute("CurrentPart") or 1, player:GetAttribute("CurrentMission") or 1) end end)

	CreateModeCard(GridContainer, "ENDLESS FRONTIER", "Fight infinite waves to harvest resources.", CONFIG.Decals.Endless, 2, function() InitiateDeployment("CombatAction", "EngageEndless") end)
	CreateModeCard(GridContainer, "MULTIPLAYER RAIDS", "Deploy your party to take down Colossal threats.", CONFIG.Decals.Raid, 3, function() ShowPage("Raids", "MULTIPLAYER RAIDS") end)
	CreateModeCard(GridContainer, "WORLD BOSSES", "A catastrophic threat has appeared.", CONFIG.Decals.WorldBoss, 4, function() ShowPage("WorldBoss", "WORLD BOSSES") end)
	CreateModeCard(GridContainer, "NIGHTMARE HUNTS", "Face corrupted Titans to obtain Cursed Weapons.", CONFIG.Decals.Nightmare, 5, function() ShowPage("Nightmare", "NIGHTMARE HUNTS") end)
	CreateModeCard(GridContainer, "PVP ARENA", "Test your ODM combat skills against other players.", CONFIG.Decals.PvP, 6, function() ShowPage("PvP", "PVP ARENA") end)
	CreateModeCard(GridContainer, "AFK EXPEDITIONS", "Send out scout regiments to gather resources.", CONFIG.Decals.AFK, 7, function() ShowPage("AFK", "AFK EXPEDITIONS") end)

	local function CreateSubPage(name)
		local page = Instance.new("Frame", MissionsPanel); page.Size = UDim2.new(1, 0, 0, 0); page.AutomaticSize = Enum.AutomaticSize.Y; page.BackgroundTransparency = 1; page.Visible = false; page.LayoutOrder = 2
		Pages[name] = page; local lay = Instance.new("UIGridLayout", page); lay.CellSize = UDim2.new(0.45, 0, 0, 180); lay.CellPadding = UDim2.new(0.05, 0, 0, 20); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center; lay.SortOrder = Enum.SortOrder.LayoutOrder
		return page
	end

	local AFKPage = Instance.new("Frame", MissionsPanel); AFKPage.Size = UDim2.new(1, 0, 0, 600); AFKPage.BackgroundTransparency = 1; AFKPage.Visible = false; AFKPage.LayoutOrder = 2
	Pages["AFK"] = AFKPage; AFKTab.Initialize(AFKPage, InitiateDeployment)


	local NightmarePage = CreateSubPage("Nightmare")
	local nIndex = 1
	for id, boss in pairs(EnemyData.NightmareHunts or {}) do
		local icon = EnemyData.BossIcons and EnemyData.BossIcons[id] or CONFIG.Decals.Nightmare
		CreateModeCard(NightmarePage, string.upper(boss.Name), boss.Desc or "Eliminate the corrupted Titan.", icon, nIndex, function() InitiateDeployment("CombatAction", "EngageNightmare", {BossId = id}) end); nIndex += 1
	end

	local WorldBossPage = CreateSubPage("WorldBoss")
	local wIndex = 1
	for id, boss in pairs(EnemyData.WorldBosses or {}) do
		local icon = EnemyData.BossIcons and EnemyData.BossIcons[id] or CONFIG.Decals.WorldBoss
		CreateModeCard(WorldBossPage, string.upper(boss.Name), boss.Desc or "A massive threat approaches.", icon, wIndex, function() InitiateDeployment("CombatAction", "EngageWorldBoss", {BossId = id}) end); wIndex += 1
	end

	local RaidPage = CreateSubPage("Raids")
	local raidList = {}
	for id, boss in pairs(EnemyData.RaidBosses or {}) do table.insert(raidList, {Id = id, Data = boss}) end
	table.sort(raidList, function(a, b) return a.Id < b.Id end)
	for i, rInfo in ipairs(raidList) do
		local id = rInfo.Id; local boss = rInfo.Data; local icon = EnemyData.BossIcons and EnemyData.BossIcons[id] or CONFIG.Decals.Raid
		CreateModeCard(RaidPage, string.upper(boss.Name), "Multiplayer Raid. Manage aggro to survive.", icon, i, function() InitiateDeployment("RaidAction", "DeployParty", {RaidId = id}) end)
	end

	local PvPPage = Instance.new("Frame", MissionsPanel); PvPPage.Size = UDim2.new(1, 0, 0, 0); PvPPage.AutomaticSize = Enum.AutomaticSize.Y; PvPPage.BackgroundTransparency = 1; PvPPage.Visible = false; PvPPage.LayoutOrder = 2
	local pvpLayout = Instance.new("UIListLayout", PvPPage); pvpLayout.SortOrder = Enum.SortOrder.LayoutOrder; pvpLayout.Padding = UDim.new(0, 15); pvpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Pages["PvP"] = PvPPage

	local PvPQueuePanel, _ = CreateGrimPanel(PvPPage); PvPQueuePanel.Size = UDim2.new(0.95, 0, 0, 140); PvPQueuePanel.LayoutOrder = 1
	local pqTitle = UIHelpers.CreateLabel(PvPQueuePanel, "RANKED MATCHMAKING", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); pqTitle.Position = UDim2.new(0, 0, 0, 10)
	local pqDesc = UIHelpers.CreateLabel(PvPQueuePanel, "Battle other players to increase your Elo Rating.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 13); pqDesc.Position = UDim2.new(0, 0, 0, 40)

	local QueueBtn, _ = CreateSharpButton(PvPQueuePanel, "ENTER QUEUE", UDim2.new(0, 200, 0, 40), Enum.Font.GothamBlack, 16); QueueBtn.Position = UDim2.new(0.5, 0, 0, 80); QueueBtn.AnchorPoint = Vector2.new(0.5, 0)
	local inQueue = false
	QueueBtn.MouseButton1Click:Connect(function()
		inQueue = not inQueue
		if inQueue then QueueBtn.Text = "LEAVE QUEUE"; QueueBtn.TextColor3 = Color3.fromRGB(255, 100, 100); Network:WaitForChild("PvPAction"):FireServer("JoinQueue")
		else QueueBtn.Text = "ENTER QUEUE"; QueueBtn.TextColor3 = UIHelpers.Colors.TextWhite; Network:WaitForChild("PvPAction"):FireServer("LeaveQueue") end
	end)

	-- [[ FIX: Automatically un-toggles the queue button if the server successfully matches them ]]
	Network:WaitForChild("PvPUpdate").OnClientEvent:Connect(function(action)
		if action == "MatchStarted" then
			inQueue = false
			QueueBtn.Text = "ENTER QUEUE"
			QueueBtn.TextColor3 = UIHelpers.Colors.TextWhite
		end
	end)

	local SpecHeader = Instance.new("Frame", PvPPage); SpecHeader.Size = UDim2.new(0.95, 0, 0, 30); SpecHeader.BackgroundTransparency = 1; SpecHeader.LayoutOrder = 2
	local PvPMatchesTitle = UIHelpers.CreateLabel(SpecHeader, "ACTIVE SPECTATOR MATCHES", UDim2.new(0.7, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16); PvPMatchesTitle.TextXAlignment = Enum.TextXAlignment.Left
	local RefreshBtn, _ = CreateSharpButton(SpecHeader, "REFRESH", UDim2.new(0, 80, 0, 24), Enum.Font.GothamBlack, 11); RefreshBtn.Position = UDim2.new(1, 0, 0.5, 0); RefreshBtn.AnchorPoint = Vector2.new(1, 0.5)

	local SpectateList = Instance.new("Frame", PvPPage); SpectateList.Size = UDim2.new(0.95, 0, 0, 0); SpectateList.AutomaticSize = Enum.AutomaticSize.Y; SpectateList.BackgroundTransparency = 1; SpectateList.LayoutOrder = 3
	local specLayout = Instance.new("UIListLayout", SpectateList); specLayout.Padding = UDim.new(0, 10); specLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	FetchLiveMatches = function()
		for _, c in ipairs(SpectateList:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
		local loadingLbl = UIHelpers.CreateLabel(SpectateList, "Scanning for live matches...", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBold, UIHelpers.Colors.Gold, 14)

		task.spawn(function()
			local matches = Network:WaitForChild("GetLiveMatches"):InvokeServer()
			if loadingLbl and loadingLbl.Parent then loadingLbl:Destroy() end

			if type(matches) ~= "table" or #matches == 0 then
				UIHelpers.CreateLabel(SpectateList, "No active ranked matches at this time.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
				return
			end

			for _, matchData in ipairs(matches) do
				local mCard, _ = CreateGrimPanel(SpectateList); mCard.Size = UDim2.new(1, 0, 0, 60)
				local vsLbl = UIHelpers.CreateLabel(mCard, (matchData.Player1 or "Fighter") .. "  VS  " .. (matchData.Player2 or "Fighter"), UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14); vsLbl.Position = UDim2.new(0, 15, 0, 0); vsLbl.TextXAlignment = Enum.TextXAlignment.Left
				local specBtn, _ = CreateSharpButton(mCard, "SPECTATE", UDim2.new(0, 100, 0, 36), Enum.Font.GothamBlack, 12); specBtn.Position = UDim2.new(1, -10, 0.5, 0); specBtn.AnchorPoint = Vector2.new(1, 0.5); specBtn.TextColor3 = UIHelpers.Colors.Gold
				specBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PvPAction"):FireServer("SpectateMatch", matchData.MatchId) end)
			end
		end)
	end
	RefreshBtn.MouseButton1Click:Connect(FetchLiveMatches)
end

return MobileExpeditionsTab