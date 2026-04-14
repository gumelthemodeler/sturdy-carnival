-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileBestiaryUI
local MobileBestiaryUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local player = Players.LocalPlayer

-- Gritty Color Palette
local C_VOID = Color3.fromRGB(12, 12, 15)
local C_STEEL = Color3.fromRGB(80, 85, 90)
local C_RUST = Color3.fromRGB(140, 50, 40)
local C_TEXT_MUTED = Color3.fromRGB(180, 180, 180)
local C_GOLD = Color3.fromRGB(252, 228, 141)

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
	lbl.Size = size; lbl.BackgroundTransparency = 1; lbl.Font = font; lbl.TextColor3 = color
	lbl.TextSize = textSize; lbl.Text = text; lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	return lbl
end

local function GenerateTactics(enemy)
	if enemy.Desc then return enemy.Desc end
	local t = "Standard combat protocols apply. Target the nape."
	if enemy.GateType == "Reinforced Skin" then t = "Heavily armored. Use Thunder Spears or high Armor Penetration."
	elseif enemy.GateType == "Hardening" then t = "Crystal hardening present. Massive damage required."
	elseif enemy.GateType == "Steam" then t = "Emits colossal steam. Melee attacks are repelled. Evade to outlast."
	elseif enemy.IsLongRange then t = "Attacks from a distance. Use 'Close In' maneuvers." end
	return t
end

local function ParseDrops(dropsTable)
	local parsed = {}
	if dropsTable.XP then table.insert(parsed, {ItemName = "Experience (XP)", Rate = "100", Color = Color3.fromRGB(85, 255, 85)}) end
	if dropsTable.Dews then table.insert(parsed, {ItemName = "Dews", Rate = "100", Color = Color3.fromRGB(255, 136, 255)}) end

	if dropsTable.ItemChance then
		for itemName, rate in pairs(dropsTable.ItemChance) do
			local color = C_TEXT_MUTED 
			if itemName:find("Serum") or itemName:find("Syringe") then color = Color3.fromRGB(255, 85, 255)
			elseif itemName:find("Fragment") or itemName:find("Crown") then color = C_GOLD
			elseif itemName:find("Blood") then color = Color3.fromRGB(255, 85, 85)
			elseif itemName:find("Crystal") or itemName:find("Shard") then color = Color3.fromRGB(85, 255, 255)
			elseif itemName:find("Steel") or itemName:find("Gear") then color = Color3.fromRGB(150, 150, 200) end
			table.insert(parsed, {ItemName = itemName, Rate = tostring(rate), Color = color})
		end
	end
	table.sort(parsed, function(a, b) return tonumber(a.Rate) > tonumber(b.Rate) end)
	return parsed
end

function MobileBestiaryUI.Initialize(masterScreenGui)
	local GUI = {}

	GUI.Container = Instance.new("Frame", masterScreenGui)
	GUI.Container.Name = "BestiaryWindow"
	GUI.Container.Size = UDim2.new(1, 0, 1, 0)
	GUI.Container.BackgroundTransparency = 1
	GUI.Container.Visible = true 
	GUI.Container.ZIndex = 100

	-- Mobile uses a stacked 40/60 vertical split instead of horizontal left/right
	local ContentFrame = Instance.new("Frame", GUI.Container)
	ContentFrame.Size = UDim2.new(1, -20, 1, -20)
	ContentFrame.Position = UDim2.new(0, 10, 0, 10)
	ContentFrame.BackgroundTransparency = 1

	-- Top Panel: Enemy List (40% height)
	GUI.ListPanel = Instance.new("ScrollingFrame", ContentFrame)
	GUI.ListPanel.Size = UDim2.new(1, 0, 0.45, 0)
	GUI.ListPanel.Position = UDim2.new(0, 0, 0, 0)
	GUI.ListPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	GUI.ListPanel.BorderSizePixel = 0
	GUI.ListPanel.ScrollingDirection = Enum.ScrollingDirection.Y

	-- [[ THE FIX: AutomaticCanvasSize natively processes folds, and a tiny scrollbar secures mobile touch detection ]]
	GUI.ListPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	GUI.ListPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	GUI.ListPanel.ScrollBarThickness = 2 

	local lpStroke = Instance.new("UIStroke", GUI.ListPanel)
	lpStroke.Color = C_STEEL; lpStroke.Thickness = 1; lpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local listLayout = Instance.new("UIListLayout", GUI.ListPanel)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)

	-- Bottom Panel: Stats & Loot Display (55% height)
	GUI.DisplayPanel, _ = CreateGrimPanel(ContentFrame)
	GUI.DisplayPanel.Size = UDim2.new(1, 0, 0.55, -10)
	GUI.DisplayPanel.Position = UDim2.new(0, 0, 0.45, 10)

	GUI.EnemyName = CreateSharpLabel(GUI.DisplayPanel, "SELECT TARGET", UDim2.new(1, -100, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(240, 240, 240), 16)
	GUI.EnemyName.Position = UDim2.new(0, 10, 0, 10)
	GUI.EnemyName.TextXAlignment = Enum.TextXAlignment.Left

	GUI.WeaknessText = CreateSharpLabel(GUI.DisplayPanel, "Awaiting cross-reference...", UDim2.new(1, -100, 0, 35), Enum.Font.GothamMedium, C_TEXT_MUTED, 11)
	GUI.WeaknessText.Position = UDim2.new(0, 10, 0, 40)
	GUI.WeaknessText.TextWrapped = true
	GUI.WeaknessText.TextYAlignment = Enum.TextYAlignment.Top
	GUI.WeaknessText.TextXAlignment = Enum.TextXAlignment.Left

	GUI.EnemyImage = Instance.new("ImageLabel", GUI.DisplayPanel)
	GUI.EnemyImage.Size = UDim2.new(0, 70, 0, 70)
	GUI.EnemyImage.Position = UDim2.new(1, -80, 0, 10)
	GUI.EnemyImage.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	GUI.EnemyImage.ScaleType = Enum.ScaleType.Crop
	GUI.EnemyImage.Image = EnemyData.BossIcons["System"] or ""
	local imgStroke = Instance.new("UIStroke", GUI.EnemyImage)
	imgStroke.Color = C_STEEL; imgStroke.Thickness = 1; imgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local LootHeader = CreateSharpLabel(GUI.DisplayPanel, "GLOBAL DROP RATES", UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, C_RUST, 14)
	LootHeader.Position = UDim2.new(0, 10, 0, 85)
	LootHeader.TextXAlignment = Enum.TextXAlignment.Left

	GUI.LootScroll = Instance.new("ScrollingFrame", GUI.DisplayPanel)
	GUI.LootScroll.Size = UDim2.new(1, -20, 1, -115)
	GUI.LootScroll.Position = UDim2.new(0, 10, 0, 105)
	GUI.LootScroll.BackgroundTransparency = 1
	GUI.LootScroll.BorderSizePixel = 0
	GUI.LootScroll.ScrollingDirection = Enum.ScrollingDirection.Y

	-- [[ THE FIX ]]
	GUI.LootScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	GUI.LootScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	GUI.LootScroll.ScrollBarThickness = 2 

	local lootLayout = Instance.new("UIListLayout", GUI.LootScroll)
	lootLayout.Padding = UDim.new(0, 4)

	local currentLayoutOrder = 1 

	local function AddEnemyButton(enemyKey, enemyTable)
		local btn = Instance.new("TextButton")
		btn.Name = "EnemyBtn_" .. enemyKey
		btn.Size = UDim2.new(1, 0, 0, 35)
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		btn.BorderSizePixel = 0
		btn.Text = "      " .. string.upper(enemyTable.Name or enemyKey)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = C_TEXT_MUTED; btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left

		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = C_STEEL; stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		btn.InputBegan:Connect(function(input) 
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then 
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
			end
		end)
		btn.InputEnded:Connect(function(input) 
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then 
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
			end
		end)

		btn.Activated:Connect(function()
			local formattedData = {
				Key = enemyKey, Name = enemyTable.Name or enemyKey,
				Tactics = GenerateTactics(enemyTable), Drops = ParseDrops(enemyTable.Drops or {})
			}
			MobileBestiaryUI.LoadEnemyData(GUI, formattedData)

			for _, child in ipairs(GUI.ListPanel:GetChildren()) do
				if child:IsA("TextButton") and string.find(child.Name, "EnemyBtn_") then
					child.BackgroundColor3 = Color3.fromRGB(20, 20, 24); child.TextColor3 = C_TEXT_MUTED
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); btn.TextColor3 = C_GOLD
		end)

		return btn
	end

	local function AddCategory(title, sortedEnemyArray)
		local headerBtn = Instance.new("TextButton", GUI.ListPanel)
		headerBtn.Name = "Header_" .. title
		headerBtn.LayoutOrder = currentLayoutOrder
		currentLayoutOrder += 1

		headerBtn.Size = UDim2.new(1, 0, 0, 30)
		headerBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
		headerBtn.BorderSizePixel = 0
		headerBtn.Text = "  ▼  " .. title
		headerBtn.Font = Enum.Font.GothamBlack; headerBtn.TextColor3 = C_RUST; headerBtn.TextSize = 13
		headerBtn.TextXAlignment = Enum.TextXAlignment.Left; headerBtn.AutoButtonColor = false

		local s = Instance.new("UIStroke", headerBtn)
		s.Color = Color3.fromRGB(60, 20, 20); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local isOpen = true
		local itemBtns = {}

		for _, entry in ipairs(sortedEnemyArray) do
			local btn = AddEnemyButton(entry.Key, entry.Data)
			btn.LayoutOrder = currentLayoutOrder
			currentLayoutOrder += 1
			btn.Parent = GUI.ListPanel
			table.insert(itemBtns, btn)
		end

		headerBtn.Activated:Connect(function()
			isOpen = not isOpen
			headerBtn.Text = (isOpen and "  ▼  " or "  ▶  ") .. title
			for _, b in ipairs(itemBtns) do b.Visible = isOpen end
		end)
	end

	local function DictToSortedArray(dict)
		local arr = {}
		for k, v in pairs(dict or {}) do table.insert(arr, {Key = type(k) == "number" and v.Name or k, Data = v}) end
		table.sort(arr, function(a, b) return string.upper(a.Data.Name or a.Key) < string.upper(b.Data.Name or b.Key) end)
		return arr
	end

	local CampaignArray = {}
	local seenCampaign = {}
	if EnemyData.Parts then
		for i = 1, 20 do 
			local part = EnemyData.Parts[i]
			if part then
				for key, temp in pairs(part.Templates or {}) do
					if temp.Health and not temp.IsDialogue and not temp.IsMinigame then
						local eKey = temp.Name or key
						if not seenCampaign[eKey] then seenCampaign[eKey] = true; table.insert(CampaignArray, {Key = key, Data = temp}) end
					end
				end
				for _, mob in ipairs(part.Mobs or {}) do
					local eKey = mob.Name
					if not seenCampaign[eKey] then seenCampaign[eKey] = true; table.insert(CampaignArray, {Key = mob.Name, Data = mob}) end
				end
			end
		end
	end

	local EndlessArray = {}
	local seenEndless = {}
	local function InsertIntoEndless(key, data)
		local eKey = data.Name or key
		if not seenEndless[eKey] then seenEndless[eKey] = true; table.insert(EndlessArray, {Key = key, Data = data}) end
	end

	for _, entry in ipairs(CampaignArray) do InsertIntoEndless(entry.Key, entry.Data) end
	for k, v in pairs(EnemyData.RaidBosses or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.WorldBosses or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.NightmareHunts or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.PathsMemories or {}) do InsertIntoEndless(k, v) end
	table.sort(EndlessArray, function(a, b) return string.upper(a.Data.Name or a.Key) < string.upper(b.Data.Name or b.Key) end)

	local displayCategories = {
		{ Title = "ENDLESS EXPEDITION", Data = EndlessArray },
		{ Title = "CAMPAIGN MISSIONS", Data = CampaignArray },
		{ Title = "RAID DEPLOYMENTS", Data = DictToSortedArray(EnemyData.RaidBosses) },
		{ Title = "WORLD BOSSES", Data = DictToSortedArray(EnemyData.WorldBosses) },
		{ Title = "NIGHTMARE HUNTS", Data = DictToSortedArray(EnemyData.NightmareHunts) },
		{ Title = "PATHS MEMORIES", Data = DictToSortedArray(EnemyData.PathsMemories) }
	}

	for _, cat in ipairs(displayCategories) do
		if #cat.Data > 0 then AddCategory(cat.Title, cat.Data) end
	end

	return GUI
end

function MobileBestiaryUI.LoadEnemyData(GUI, formattedData)
	GUI.EnemyName.Text = string.upper(formattedData.Name)
	GUI.WeaknessText.Text = "TACTICAL REPORT: " .. formattedData.Tactics

	local fallbackIcon = EnemyData.BossIcons["System"] or ""
	GUI.EnemyImage.Image = EnemyData.BossIcons[formattedData.Key] or EnemyData.BossIcons[formattedData.Name] or fallbackIcon

	for _, child in ipairs(GUI.LootScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if #formattedData.Drops == 0 then
		local dText = CreateSharpLabel(GUI.LootScroll, "No known drops recorded.", UDim2.new(1, 0, 0, 30), Enum.Font.GothamMedium, C_STEEL, 12)
		dText.TextXAlignment = Enum.TextXAlignment.Left
		return
	end

	for _, drop in ipairs(formattedData.Drops) do
		local dropFrame = Instance.new("Frame", GUI.LootScroll)
		dropFrame.Size = UDim2.new(1, 0, 0, 26)
		dropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24); dropFrame.BorderSizePixel = 0

		local rarityColor = drop.Color or C_TEXT_MUTED
		local dStroke = Instance.new("UIStroke", dropFrame)
		dStroke.Color = Color3.new(rarityColor.R * 0.5, rarityColor.G * 0.5, rarityColor.B * 0.5)
		dStroke.Thickness = 1; dStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local nameLbl = CreateSharpLabel(dropFrame, drop.ItemName, UDim2.new(0.7, 0, 1, 0), Enum.Font.GothamBold, rarityColor, 11)
		nameLbl.Position = UDim2.new(0, 10, 0, 0); nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local rateLbl = CreateSharpLabel(dropFrame, drop.Rate .. "%", UDim2.new(0.3, -10, 1, 0), Enum.Font.GothamBlack, C_TEXT_MUTED, 11)
		rateLbl.Position = UDim2.new(0.7, 0, 0, 0); rateLbl.TextXAlignment = Enum.TextXAlignment.Right
	end
end

return MobileBestiaryUI