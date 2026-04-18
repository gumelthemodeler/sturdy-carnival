-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileExpeditionsTab
local MobileExpeditionsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local SharedUI = playerScripts:WaitForChild("SharedUI")
local UIModules = playerScripts:WaitForChild("UIModules")

local MobileFolder = playerScripts:FindFirstChild("MobileUI") or playerScripts:WaitForChild("MobileModules")

local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local AFKTab = require(UIModules:FindFirstChild("MobileAFKTab") or UIModules:WaitForChild("AFKTab"))
local MobileLabyrinthUI = require(MobileFolder:WaitForChild("MobileLabyrinthUI"))

local notifModule = SharedUI:WaitForChild("NotificationManager", 2)
local NotificationManager = notifModule and require(notifModule) or nil

local CONFIG = { Decals = { Campaign = "rbxassetid://80153476985849", AFK = "rbxassetid://114506098039778", Raid = "rbxassetid://119392967268687", PvP = "rbxassetid://100826303284945", Nightmare = "rbxassetid://90132878979603", WorldBoss = "rbxassetid://129655150803684", Endless = "rbxassetid://81075056647024", Paths = "rbxassetid://90938848776194", Labyrinth = "rbxassetid://90132878979603" } }

local CurrentParty = {}; local IsInParty = false; local IsPartyLeader = false; local PendingInvites = {}; local isListening = false

local function AbbreviateNumber(n)
	local Suffixes = {"", "K", "M", "B", "T", "Qa"}
	if not n then return "0" end; n = tonumber(n) or 0
	if n < 1000 then return tostring(math.floor(n)) end
	local suffixIndex = math.floor(math.log10(n) / 3); local value = n / (10 ^ (suffixIndex * 3))
	local str = string.format("%.1f", value); str = str:gsub("%.0$", "")
	return str .. (Suffixes[suffixIndex + 1] or "")
end

local function FormatTime(seconds)
	local mins = math.floor(seconds / 60); local secs = seconds % 60
	return string.format("%02d:%02d", mins, secs)
end

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false
	btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
	MasterScroll.Size = UDim2.new(1, 0, 1, 0)
	MasterScroll.BackgroundTransparency = 1
	MasterScroll.ScrollBarThickness = 4
	MasterScroll.BorderSizePixel = 0
	MasterScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local masterLayout = Instance.new("UIListLayout", MasterScroll)
	masterLayout.SortOrder = Enum.SortOrder.LayoutOrder
	masterLayout.Padding = UDim.new(0, 20)
	masterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local masterPad = Instance.new("UIPadding", MasterScroll)
	masterPad.PaddingTop = UDim.new(0, 15); masterPad.PaddingBottom = UDim.new(0, 30)

	local PartyPanel, _ = CreateGrimPanel(BottomContainer)
	PartyPanel.Size = UDim2.new(0.95, 0, 1, 0)
	PartyPanel.Position = UDim2.new(0.5, 0, 0, 0)
	PartyPanel.AnchorPoint = Vector2.new(0.5, 0)

	local ppLayout = Instance.new("UIListLayout", PartyPanel)
	ppLayout.Padding = UDim.new(0, 5); ppLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local ppPad = Instance.new("UIPadding", PartyPanel)
	ppPad.PaddingTop = UDim.new(0, 10); ppPad.PaddingBottom = UDim.new(0, 10)

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
				InvBtn.Activated:Connect(function() if NameInput.Text ~= "" then Network:WaitForChild("PartyAction"):FireServer("Invite", NameInput.Text); NameInput.Text = "" end end)
			end

			local LeaveBtn, _ = CreateSharpButton(PartyPanel, "LEAVE TEAM", UDim2.new(0.9, 0, 0, 30), Enum.Font.GothamBlack, 12); LeaveBtn.LayoutOrder = 4; LeaveBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			LeaveBtn.Activated:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Leave") end)
		else
			local Header = UIHelpers.CreateLabel(PartyPanel, "SOLO DEPLOYMENT", UDim2.new(0.9, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 18); Header.LayoutOrder = 1
			local CreateBtn, _ = CreateSharpButton(PartyPanel, "CREATE TEAM", UDim2.new(0.9, 0, 0, 45), Enum.Font.GothamBlack, 16); CreateBtn.LayoutOrder = 2
			CreateBtn.Activated:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Create") end)

			local inviteCount = 0; for k, v in pairs(PendingInvites) do inviteCount = inviteCount + 1 end
			if inviteCount > 0 then
				local invHeader = UIHelpers.CreateLabel(PartyPanel, "INCOMING INVITES", UDim2.new(0.9, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.Gold, 12); invHeader.LayoutOrder = 3
				local InvList = Instance.new("Frame", PartyPanel); InvList.Size = UDim2.new(0.9, 0, 0, 0); InvList.AutomaticSize = Enum.AutomaticSize.Y; InvList.BackgroundTransparency = 1; InvList.LayoutOrder = 4
				local ilLayout = Instance.new("UIListLayout", InvList); ilLayout.Padding = UDim.new(0, 8)

				for inviterName, _ in pairs(PendingInvites) do
					local iCard, _ = CreateGrimPanel(InvList); iCard.Size = UDim2.new(1, 0, 0, 40)
					local iName = UIHelpers.CreateLabel(iCard, inviterName, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14); iName.Position = UDim2.new(0, 10, 0, 0); iName.TextXAlignment = Enum.TextXAlignment.Left

					local accBtn, _ = CreateSharpButton(iCard, "JOIN", UDim2.new(0.35, 0, 0, 30), Enum.Font.GothamBlack, 12); accBtn.Position = UDim2.new(1, -5, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5); accBtn.TextColor3 = UIHelpers.Colors.Gold
					accBtn.Activated:Connect(function() Network:WaitForChild("PartyAction"):FireServer("AcceptInvite", inviterName); PendingInvites[inviterName] = nil; RenderPartyUI() end)
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
	DeployOverlay.Name = "DeploymentTransition"; DeployOverlay.Size = UDim2.new(1, 0, 1, 0); DeployOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 15); DeployOverlay.BackgroundTransparency = 1; DeployOverlay.ZIndex = 9999; DeployOverlay.Visible = false
	local dStatus = UIHelpers.CreateLabel(DeployOverlay, "ESTABLISHING CONNECTION...", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24); dStatus.Position = UDim2.new(0, 0, 0.5, -20); dStatus.TextTransparency = 1; dStatus.ZIndex = 10000

	local function InitiateDeployment(remoteName, action, payload)
		DeployOverlay.Visible = true; TweenService:Create(DeployOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.1}):Play(); TweenService:Create(dStatus, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		dStatus.Text = "PREPARING STRIKE TEAM..."; task.wait(0.6)
		dStatus.Text = "DEPLOYING TO COMBAT ZONE..."; dStatus.TextColor3 = Color3.fromRGB(255, 100, 100); task.wait(0.8)
		if payload then Network:WaitForChild(remoteName):FireServer(action, payload) else Network:WaitForChild(remoteName):FireServer(action) end
		local t1 = TweenService:Create(DeployOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}); local t2 = TweenService:Create(dStatus, TweenInfo.new(0.5), {TextTransparency = 1})
		t1:Play(); t2:Play(); t1.Completed:Wait(); DeployOverlay.Visible = false; dStatus.TextColor3 = UIHelpers.Colors.Gold
	end

	local function CreateModeCard(parent, title, desc, imageId, layoutOrder, onClick, imageColor)
		local cardBtn = Instance.new("TextButton", parent); cardBtn.LayoutOrder = layoutOrder; cardBtn.Text = ""; cardBtn.AutoButtonColor = false; cardBtn.ClipsDescendants = true; local _, strk = CreateGrimPanel(cardBtn)
		local bg = Instance.new("ImageLabel", cardBtn); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundTransparency = 1; bg.Image = imageId; bg.ScaleType = Enum.ScaleType.Crop; bg.ZIndex = 1
		if imageColor then bg.ImageColor3 = imageColor end

		local gradFrame = Instance.new("Frame", cardBtn); gradFrame.Size = UDim2.new(1, 0, 1, 0); gradFrame.BackgroundColor3 = Color3.new(0,0,0); gradFrame.BorderSizePixel = 0; gradFrame.ZIndex = 2; local grad = Instance.new("UIGradient", gradFrame); grad.Rotation = 90; grad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0.1)}

		local lblTitle = UIHelpers.CreateLabel(cardBtn, title, UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18); lblTitle.Position = UDim2.new(0, 10, 1, -70); lblTitle.TextXAlignment = Enum.TextXAlignment.Left; lblTitle.TextScaled = true; lblTitle.ZIndex = 3; local tCon = Instance.new("UITextSizeConstraint", lblTitle); tCon.MaxTextSize = 18; tCon.MinTextSize = 12
		local lblDesc = UIHelpers.CreateLabel(cardBtn, desc, UDim2.new(1, -20, 0, 35), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12); lblDesc.Position = UDim2.new(0, 10, 1, -40); lblDesc.TextXAlignment = Enum.TextXAlignment.Left; lblDesc.TextYAlignment = Enum.TextYAlignment.Top; lblDesc.TextWrapped = true; lblDesc.ZIndex = 3

		cardBtn.InputBegan:Connect(function() strk.Color = UIHelpers.Colors.Gold; lblTitle.TextColor3 = UIHelpers.Colors.Gold; TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}):Play() end)
		cardBtn.InputEnded:Connect(function() strk.Color = UIHelpers.Colors.BorderMuted; lblTitle.TextColor3 = UIHelpers.Colors.TextWhite; TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play() end)
		cardBtn.Activated:Connect(onClick)
		return lblDesc
	end

	local HeaderFrame = Instance.new("Frame", MissionsPanel); HeaderFrame.Size = UDim2.new(1, 0, 0, 40); HeaderFrame.BackgroundTransparency = 1; HeaderFrame.LayoutOrder = 1
	local Title = UIHelpers.CreateLabel(HeaderFrame, "COMBAT DEPLOYMENT", UDim2.new(1, -80, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); Title.Position = UDim2.new(0, 20, 0, 0); Title.TextXAlignment = Enum.TextXAlignment.Left

	local BackBtn, BackStroke = CreateSharpButton(HeaderFrame, "< BACK", UDim2.new(0, 70, 0, 30), Enum.Font.GothamBlack, 12)
	BackBtn.Position = UDim2.new(1, -15, 0.5, 0); BackBtn.AnchorPoint = Vector2.new(1, 0.5); BackBtn.Visible = false

	local Pages = {}; local FetchLiveMatches; local FetchDoomsdayData; local doomsdayLoopActive = false; local currentDoomsdayData = nil

	local function ShowPage(pageName, titleText)
		for name, frame in pairs(Pages) do frame.Visible = (name == pageName) end
		Title.Text = titleText; BackBtn.Visible = (pageName ~= "Main")

		if pageName == "Main" then
			BottomContainer.Visible = true
			TopContainer.Size = UDim2.new(1, 0, 1, -120)
		else
			BottomContainer.Visible = false
			TopContainer.Size = UDim2.new(1, 0, 1, 0)
		end

		if pageName == "PvP" and FetchLiveMatches then FetchLiveMatches() end
	end
	BackBtn.Activated:Connect(function() ShowPage("Main", "COMBAT DEPLOYMENT") end)

	local GridContainer = Instance.new("Frame", MissionsPanel); GridContainer.Size = UDim2.new(1, 0, 0, 0); GridContainer.AutomaticSize = Enum.AutomaticSize.Y; GridContainer.BackgroundTransparency = 1; GridContainer.LayoutOrder = 2
	Pages["Main"] = GridContainer

	local gridLayout = Instance.new("UIGridLayout", GridContainer)
	gridLayout.CellSize = UDim2.new(0.95, 0, 0, 140)
	gridLayout.CellPadding = UDim2.new(0, 0, 0, 15)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local cPart = player:GetAttribute("CurrentPart") or 1; local cMiss = player:GetAttribute("CurrentMission") or 1
	local campaignDescLbl = CreateModeCard(GridContainer, "STORY CAMPAIGN", string.format("Part %d - Mission %d\nProgress through the main storyline.", cPart, cMiss), CONFIG.Decals.Campaign, 1, function() InitiateDeployment("CombatAction", "EngageStory") end)
	player.AttributeChanged:Connect(function(attr) if attr == "CurrentPart" or attr == "CurrentMission" then campaignDescLbl.Text = string.format("Part %d - Mission %d\nProgress through the main storyline.", player:GetAttribute("CurrentPart") or 1, player:GetAttribute("CurrentMission") or 1) end end)

	local wday = os.date("!*t").wday
	local isPathsOpen = (wday == 7 or wday == 1 or wday == 2)
	local pathsDesc = isPathsOpen and "Venture into the coordinate to farm Path Dust for Memory Runes." or "[EVENT CLOSED] Opens on Sat, Sun, and Mon."
	local pathsCardLbl = CreateModeCard(GridContainer, "THE PATHS (EVENT)", pathsDesc, CONFIG.Decals.Paths, 2, function() 
		if isPathsOpen then InitiateDeployment("CombatAction", "EngagePaths") else
			if NotificationManager and type(NotificationManager.Show) == "function" then NotificationManager.Show("The Paths are currently closed. Returns Sat, Sun & Mon.", "Error") end
		end
	end)
	if not isPathsOpen then pathsCardLbl.TextColor3 = Color3.fromRGB(255, 100, 100) end

	CreateModeCard(GridContainer, "ENDLESS FRONTIER", "Fight infinite waves to harvest resources.", CONFIG.Decals.Endless, 3, function() InitiateDeployment("CombatAction", "EngageEndless") end)

	local function CreateSubPage(name)
		local page = Instance.new("Frame", MissionsPanel); page.Size = UDim2.new(1, 0, 0, 0); page.AutomaticSize = Enum.AutomaticSize.Y; page.BackgroundTransparency = 1; page.Visible = false; page.LayoutOrder = 2
		Pages[name] = page; 
		if name ~= "Labyrinth" and name ~= "Doomsday" and name ~= "AFK" then
			local lay = Instance.new("UIGridLayout", page)
			lay.CellSize = UDim2.new(0.95, 0, 0, 140)
			lay.CellPadding = UDim2.new(0, 0, 0, 15)
			lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
			lay.SortOrder = Enum.SortOrder.LayoutOrder
		end
		return page
	end

	local LabyrinthPage = CreateSubPage("Labyrinth")
	MobileLabyrinthUI.Initialize(LabyrinthPage)

	-- [[ THE FIX: Safely retrieve ScreenGui and pass it into LabyrinthUI.Open ]]
	CreateModeCard(GridContainer, "THE LABYRINTH", "Navigate a dark, shifting maze. Secure loot caches and escape, or die and lose everything.", CONFIG.Decals.Labyrinth, 4, function() 
		ShowPage("Labyrinth", "THE LABYRINTH")
		local masterScreenGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
		MobileLabyrinthUI.Open(masterScreenGui) 
	end, Color3.fromRGB(255, 85, 85))

	CreateModeCard(GridContainer, "MULTIPLAYER RAIDS", "Deploy your party to take down Colossal threats.", CONFIG.Decals.Raid, 5, function() ShowPage("Raids", "MULTIPLAYER RAIDS") end)
	CreateModeCard(GridContainer, "DOOMSDAY BOUNTIES", "Server-wide raid bosses. Fight for the top of the global leaderboard.", CONFIG.Decals.WorldBoss, 6, function() ShowPage("Doomsday", "DOOMSDAY BOUNTIES") end, Color3.fromRGB(255, 50, 50))
	CreateModeCard(GridContainer, "WORLD BOSSES", "A catastrophic threat has appeared.", CONFIG.Decals.WorldBoss, 7, function() ShowPage("WorldBoss", "WORLD BOSSES") end)
	CreateModeCard(GridContainer, "NIGHTMARE HUNTS", "Face corrupted Titans to obtain Cursed Weapons.", CONFIG.Decals.Nightmare, 8, function() ShowPage("Nightmare", "NIGHTMARE HUNTS") end)
	CreateModeCard(GridContainer, "PVP ARENA", "Test your ODM combat skills against other players.", CONFIG.Decals.PvP, 9, function() ShowPage("PvP", "PVP ARENA") end)
	CreateModeCard(GridContainer, "AFK EXPEDITIONS", "Send out scout regiments to gather resources.", CONFIG.Decals.AFK, 10, function() ShowPage("AFK", "AFK EXPEDITIONS") end)

	local AFKPage = CreateSubPage("AFK")
	AFKTab.Initialize(AFKPage, InitiateDeployment)

	local DoomsdayPage = CreateSubPage("Doomsday")
	local ddPgLayout = Instance.new("UIListLayout", DoomsdayPage); ddPgLayout.SortOrder = Enum.SortOrder.LayoutOrder; ddPgLayout.Padding = UDim.new(0, 15); ddPgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local DDContainer, _ = CreateGrimPanel(DoomsdayPage); DDContainer.Name = "DDContainer"; DDContainer.Size = UDim2.new(0.95, 0, 0, 160); DDContainer.LayoutOrder = 1
	local ddTitle = UIHelpers.CreateLabel(DDContainer, "THE PRIMORDIAL THREAT", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); ddTitle.Position = UDim2.new(0, 0, 0, 15)
	local ddHpLbl = UIHelpers.CreateLabel(DDContainer, "GLOBAL HP: FETCHING...", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, Color3.fromRGB(255, 100, 100), 14); ddHpLbl.Name = "GlobalHpLbl"; ddHpLbl.Position = UDim2.new(0, 0, 0, 50)

	local EngageBtn, _ = CreateSharpButton(DDContainer, "DEPLOY TO FRONTLINE", UDim2.new(0.8, 0, 0, 45), Enum.Font.GothamBlack, 14); EngageBtn.Name = "EngageBtn"; EngageBtn.Position = UDim2.new(0.5, 0, 0, 90); EngageBtn.AnchorPoint = Vector2.new(0.5, 0)
	EngageBtn.Activated:Connect(function() if EngageBtn.Text == "DEPLOY TO FRONTLINE" then InitiateDeployment("CombatAction", "EngageDoomsday") end end)

	local DDLeaderboardPanel = Instance.new("Frame", DoomsdayPage); DDLeaderboardPanel.Size = UDim2.new(0.95, 0, 0, 0); DDLeaderboardPanel.AutomaticSize = Enum.AutomaticSize.Y; DDLeaderboardPanel.BackgroundTransparency = 1; DDLeaderboardPanel.LayoutOrder = 2
	local DDLeaderboardTitle = UIHelpers.CreateLabel(DDLeaderboardPanel, "TOP DAMAGE CONTRIBUTORS", UDim2.new(0.6, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14); DDLeaderboardTitle.Position = UDim2.new(0, 0, 0, 0); DDLeaderboardTitle.TextXAlignment = Enum.TextXAlignment.Left
	local DDRefreshBtn, _ = CreateSharpButton(DDLeaderboardPanel, "REFRESH", UDim2.new(0, 80, 0, 24), Enum.Font.GothamBold, 10); DDRefreshBtn.Position = UDim2.new(1, 0, 0, 3); DDRefreshBtn.AnchorPoint = Vector2.new(1, 0)

	local DDScroll = Instance.new("Frame", DDLeaderboardPanel); DDScroll.Size = UDim2.new(1, 0, 0, 0); DDScroll.AutomaticSize = Enum.AutomaticSize.Y; DDScroll.Position = UDim2.new(0, 0, 0, 40); DDScroll.BackgroundTransparency = 1
	local ddLayout = Instance.new("UIListLayout", DDScroll); ddLayout.Padding = UDim.new(0, 6); ddLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	FetchDoomsdayData = function(isBackgroundSync)
		task.spawn(function()
			local data = Network:WaitForChild("GetDoomsdayData"):InvokeServer()
			if data then
				data.LocalSyncTime = os.time()
				currentDoomsdayData = data
				if not isBackgroundSync then
					for _, c in ipairs(DDScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
					for i, pData in ipairs(data.Leaderboard or {}) do
						local card = Instance.new("Frame", DDScroll); card.Size = UDim2.new(1, 0, 0, 36); card.BackgroundColor3 = Color3.fromRGB(25, 25, 30); Instance.new("UIStroke", card).Color = UIHelpers.Colors.BorderMuted
						local cColor = (i==1) and UIHelpers.Colors.Gold or ((i==2) and Color3.fromRGB(200, 200, 200) or UIHelpers.Colors.TextWhite)

						local rLbl = UIHelpers.CreateLabel(card, "#" .. i, UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, cColor, 14)
						local nLbl = UIHelpers.CreateLabel(card, pData.Name, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, cColor, 12); nLbl.Position = UDim2.new(0, 35, 0, 0); nLbl.TextXAlignment = Enum.TextXAlignment.Left
						local dmgLbl = UIHelpers.CreateLabel(card, AbbreviateNumber(pData.Damage) .. " DMG", UDim2.new(0.4, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 12); dmgLbl.Position = UDim2.new(1, -10, 0, 0); dmgLbl.AnchorPoint = Vector2.new(1, 0); dmgLbl.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
			end
		end)
	end
	DDRefreshBtn.Activated:Connect(function() FetchDoomsdayData(false) end)

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

	local PvPPage = CreateSubPage("PvP")
	local PvPQueuePanel, _ = CreateGrimPanel(PvPPage); PvPQueuePanel.Size = UDim2.new(0.95, 0, 0, 140); PvPQueuePanel.LayoutOrder = 1
	local pqTitle = UIHelpers.CreateLabel(PvPQueuePanel, "RANKED MATCHMAKING", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); pqTitle.Position = UDim2.new(0, 0, 0, 10)
	local pqDesc = UIHelpers.CreateLabel(PvPQueuePanel, "Battle other players to increase your Elo Rating.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 13); pqDesc.Position = UDim2.new(0, 0, 0, 40)

	local QueueBtn, _ = CreateSharpButton(PvPQueuePanel, "ENTER QUEUE", UDim2.new(0, 200, 0, 40), Enum.Font.GothamBlack, 16); QueueBtn.Position = UDim2.new(0.5, 0, 0, 80); QueueBtn.AnchorPoint = Vector2.new(0.5, 0)
	local inQueue = false
	QueueBtn.Activated:Connect(function()
		inQueue = not inQueue
		if inQueue then QueueBtn.Text = "LEAVE QUEUE"; QueueBtn.TextColor3 = Color3.fromRGB(255, 100, 100); Network:WaitForChild("PvPAction"):FireServer("JoinQueue")
		else QueueBtn.Text = "ENTER QUEUE"; QueueBtn.TextColor3 = UIHelpers.Colors.TextWhite; Network:WaitForChild("PvPAction"):FireServer("LeaveQueue") end
	end)

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
				specBtn.Activated:Connect(function() Network:WaitForChild("PvPAction"):FireServer("SpectateMatch", matchData.MatchId) end)
			end
		end)
	end
	RefreshBtn.Activated:Connect(FetchLiveMatches)
end

return MobileExpeditionsTab