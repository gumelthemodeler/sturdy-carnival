-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BestiaryUI = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local player = Players.LocalPlayer

-- Gritty Color Palette
local C_VOID = Color3.fromRGB(12, 12, 15)
local C_STEEL = Color3.fromRGB(80, 85, 90)
local C_RUST = Color3.fromRGB(140, 50, 40)
local C_TEXT_MUTED = Color3.fromRGB(180, 180, 180)
local C_GOLD = Color3.fromRGB(252, 228, 141)

local function GenerateTactics(enemy)
	if enemy.Desc then return enemy.Desc end

	local t = "Standard combat protocols apply. Target the nape."
	if enemy.GateType == "Reinforced Skin" then 
		t = "Heavily armored. Use Thunder Spears or high Armor Penetration to break the gate before striking."
	elseif enemy.GateType == "Hardening" then 
		t = "Crystal hardening present. Massive damage required to shatter the gate."
	elseif enemy.GateType == "Steam" then 
		t = "Emits colossal steam. Melee attacks are repelled. Maneuver and evade to outlast the heat."
	elseif enemy.IsLongRange then 
		t = "Attacks from a distance. Use 'Close In' or 'Advance' maneuvers to reach striking range." 
	end
	return t
end

local function ParseDrops(dropsTable)
	local parsed = {}
	if dropsTable.XP then 
		table.insert(parsed, {ItemName = "Experience (XP)", Rate = "100", Color = Color3.fromRGB(85, 255, 85)}) 
	end
	if dropsTable.Dews then 
		table.insert(parsed, {ItemName = "Dews", Rate = "100", Color = Color3.fromRGB(255, 136, 255)}) 
	end

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

function BestiaryUI.Initialize(masterScreenGui)
	local GUI = {}

	GUI.Container = Instance.new("Frame", masterScreenGui)
	GUI.Container.Name = "BestiaryWindow"
	GUI.Container.Size = UDim2.new(1, 0, 1, 0)
	GUI.Container.BackgroundTransparency = 1
	GUI.Container.Visible = true 
	GUI.Container.ZIndex = 100

	local ContentFrame = Instance.new("Frame", GUI.Container)
	ContentFrame.Size = UDim2.new(1, -40, 1, -40)
	ContentFrame.Position = UDim2.new(0, 20, 0, 20)
	ContentFrame.BackgroundColor3 = C_VOID

	local mainStroke = Instance.new("UIStroke", ContentFrame)
	mainStroke.Color = C_RUST
	mainStroke.Thickness = 2
	mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- Left Panel: Enemy List
	GUI.ListPanel = Instance.new("ScrollingFrame", ContentFrame)
	GUI.ListPanel.Size = UDim2.new(0.35, 0, 1, 0)
	GUI.ListPanel.Position = UDim2.new(0, 0, 0, 0)
	GUI.ListPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	GUI.ListPanel.BorderSizePixel = 0
	GUI.ListPanel.ScrollBarThickness = 4

	local lpStroke = Instance.new("UIStroke", GUI.ListPanel)
	lpStroke.Color = C_STEEL
	lpStroke.Thickness = 1
	lpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local listLayout = Instance.new("UIListLayout", GUI.ListPanel)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GUI.ListPanel.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Right Panel: Stats & Loot Display
	GUI.DisplayPanel = Instance.new("Frame", ContentFrame)
	GUI.DisplayPanel.Size = UDim2.new(0.65, 0, 1, 0)
	GUI.DisplayPanel.Position = UDim2.new(0.35, 0, 0, 0)
	GUI.DisplayPanel.BackgroundTransparency = 1

	GUI.EnemyName = Instance.new("TextLabel", GUI.DisplayPanel)
	GUI.EnemyName.Size = UDim2.new(1, -130, 0, 40)
	GUI.EnemyName.Position = UDim2.new(0, 15, 0, 15)
	GUI.EnemyName.BackgroundTransparency = 1
	GUI.EnemyName.Text = "SELECT TARGET"
	GUI.EnemyName.Font = Enum.Font.GothamBlack
	GUI.EnemyName.TextColor3 = Color3.fromRGB(240, 240, 240)
	GUI.EnemyName.TextSize = 24
	GUI.EnemyName.TextXAlignment = Enum.TextXAlignment.Left

	GUI.WeaknessText = Instance.new("TextLabel", GUI.DisplayPanel)
	GUI.WeaknessText.Size = UDim2.new(1, -130, 0, 40)
	GUI.WeaknessText.Position = UDim2.new(0, 15, 0, 55)
	GUI.WeaknessText.BackgroundTransparency = 1
	GUI.WeaknessText.Text = "Awaiting cross-reference..."
	GUI.WeaknessText.Font = Enum.Font.GothamMedium
	GUI.WeaknessText.TextColor3 = C_TEXT_MUTED
	GUI.WeaknessText.TextSize = 13
	GUI.WeaknessText.TextWrapped = true
	GUI.WeaknessText.TextYAlignment = Enum.TextYAlignment.Top
	GUI.WeaknessText.TextXAlignment = Enum.TextXAlignment.Left

	-- Enemy Avatar Display
	GUI.EnemyImage = Instance.new("ImageLabel", GUI.DisplayPanel)
	GUI.EnemyImage.Size = UDim2.new(0, 90, 0, 90)
	GUI.EnemyImage.Position = UDim2.new(1, -105, 0, 15)
	GUI.EnemyImage.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	GUI.EnemyImage.ScaleType = Enum.ScaleType.Crop
	GUI.EnemyImage.Image = EnemyData.BossIcons["System"] or ""

	local imgStroke = Instance.new("UIStroke", GUI.EnemyImage)
	imgStroke.Color = C_STEEL
	imgStroke.Thickness = 1
	imgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- Loot Table Area
	local LootHeader = Instance.new("TextLabel", GUI.DisplayPanel)
	LootHeader.Size = UDim2.new(1, -30, 0, 25)
	LootHeader.Position = UDim2.new(0, 15, 0, 120)
	LootHeader.BackgroundTransparency = 1
	LootHeader.Text = "GLOBAL DROP RATES"
	LootHeader.Font = Enum.Font.GothamBlack
	LootHeader.TextColor3 = C_RUST
	LootHeader.TextSize = 16
	LootHeader.TextXAlignment = Enum.TextXAlignment.Left

	GUI.LootScroll = Instance.new("ScrollingFrame", GUI.DisplayPanel)
	GUI.LootScroll.Size = UDim2.new(1, -30, 1, -160)
	GUI.LootScroll.Position = UDim2.new(0, 15, 0, 150)
	GUI.LootScroll.BackgroundTransparency = 1
	GUI.LootScroll.ScrollBarThickness = 4
	GUI.LootScroll.BorderSizePixel = 0

	local lootLayout = Instance.new("UIListLayout", GUI.LootScroll)
	lootLayout.Padding = UDim.new(0, 6)
	lootLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GUI.LootScroll.CanvasSize = UDim2.new(0, 0, 0, lootLayout.AbsoluteContentSize.Y + 10)
	end)

	local currentLayoutOrder = 1 

	local function AddEnemyButton(enemyKey, enemyTable)
		local btn = Instance.new("TextButton")
		btn.Name = "EnemyBtn_" .. enemyKey
		btn.Size = UDim2.new(1, 0, 0, 35)
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		btn.BorderSizePixel = 0
		btn.Text = "      " .. string.upper(enemyTable.Name or enemyKey)
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = C_TEXT_MUTED
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left

		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = C_STEEL
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		btn.MouseButton1Click:Connect(function()
			local formattedData = {
				Key = enemyKey,
				Name = enemyTable.Name or enemyKey,
				Tactics = GenerateTactics(enemyTable),
				Drops = ParseDrops(enemyTable.Drops or {})
			}
			BestiaryUI.LoadEnemyData(GUI, formattedData)

			for _, child in ipairs(GUI.ListPanel:GetChildren()) do
				if child:IsA("TextButton") and string.find(child.Name, "EnemyBtn_") then
					child.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
					child.TextColor3 = C_TEXT_MUTED
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			btn.TextColor3 = C_GOLD
		end)

		return btn
	end

	local function AddCategory(title, sortedEnemyArray)
		local headerBtn = Instance.new("TextButton", GUI.ListPanel)
		headerBtn.Name = "Header_" .. title
		headerBtn.LayoutOrder = currentLayoutOrder
		currentLayoutOrder = currentLayoutOrder + 1

		headerBtn.Size = UDim2.new(1, 0, 0, 30)
		headerBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
		headerBtn.BorderSizePixel = 0
		headerBtn.Text = "  ▼  " .. title
		headerBtn.Font = Enum.Font.GothamBlack
		headerBtn.TextColor3 = C_RUST
		headerBtn.TextSize = 14
		headerBtn.TextXAlignment = Enum.TextXAlignment.Left
		headerBtn.AutoButtonColor = false

		local s = Instance.new("UIStroke", headerBtn)
		s.Color = Color3.fromRGB(60, 20, 20)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local isOpen = true
		local itemBtns = {}

		for _, entry in ipairs(sortedEnemyArray) do
			local btn = AddEnemyButton(entry.Key, entry.Data)
			btn.LayoutOrder = currentLayoutOrder
			currentLayoutOrder = currentLayoutOrder + 1
			btn.Parent = GUI.ListPanel
			table.insert(itemBtns, btn)
		end

		headerBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			headerBtn.Text = (isOpen and "  ▼  " or "  ▶  ") .. title
			for _, b in ipairs(itemBtns) do
				b.Visible = isOpen
			end
		end)
	end

	local function DictToSortedArray(dict)
		local arr = {}
		for k, v in pairs(dict or {}) do
			table.insert(arr, {Key = type(k) == "number" and v.Name or k, Data = v})
		end
		table.sort(arr, function(a, b) return string.upper(a.Data.Name or a.Key) < string.upper(b.Data.Name or b.Key) end)
		return arr
	end

	-- Extract Campaign Enemies chronologically
	local CampaignArray = {}
	local seenCampaign = {}
	if EnemyData.Parts then
		for i = 1, 20 do 
			local part = EnemyData.Parts[i]
			if part then
				for key, temp in pairs(part.Templates or {}) do
					if temp.Health and not temp.IsDialogue and not temp.IsMinigame then
						local eKey = temp.Name or key
						if not seenCampaign[eKey] then
							seenCampaign[eKey] = true
							table.insert(CampaignArray, {Key = key, Data = temp})
						end
					end
				end
				for _, mob in ipairs(part.Mobs or {}) do
					local eKey = mob.Name
					if not seenCampaign[eKey] then
						seenCampaign[eKey] = true
						table.insert(CampaignArray, {Key = mob.Name, Data = mob})
					end
				end
			end
		end
	end

	-- [[ THE FIX: Aggregating EVERY enemy into Endless Expedition Array ]]
	local EndlessArray = {}
	local seenEndless = {}
	local function InsertIntoEndless(key, data)
		local eKey = data.Name or key
		if not seenEndless[eKey] then
			seenEndless[eKey] = true
			table.insert(EndlessArray, {Key = key, Data = data})
		end
	end

	for _, entry in ipairs(CampaignArray) do InsertIntoEndless(entry.Key, entry.Data) end
	for k, v in pairs(EnemyData.RaidBosses or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.WorldBosses or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.NightmareHunts or {}) do InsertIntoEndless(k, v) end
	for k, v in pairs(EnemyData.PathsMemories or {}) do InsertIntoEndless(k, v) end

	table.sort(EndlessArray, function(a, b) return string.upper(a.Data.Name or a.Key) < string.upper(b.Data.Name or b.Key) end)

	-- Structured UI rendering hierarchy
	local displayCategories = {
		{ Title = "ENDLESS EXPEDITION", Data = EndlessArray },
		{ Title = "CAMPAIGN MISSIONS", Data = CampaignArray },
		{ Title = "RAID DEPLOYMENTS", Data = DictToSortedArray(EnemyData.RaidBosses) },
		{ Title = "WORLD BOSSES", Data = DictToSortedArray(EnemyData.WorldBosses) },
		{ Title = "NIGHTMARE HUNTS", Data = DictToSortedArray(EnemyData.NightmareHunts) },
		{ Title = "PATHS MEMORIES", Data = DictToSortedArray(EnemyData.PathsMemories) }
	}

	for _, cat in ipairs(displayCategories) do
		if #cat.Data > 0 then
			AddCategory(cat.Title, cat.Data)
		end
	end

	return GUI
end

function BestiaryUI.LoadEnemyData(GUI, formattedData)
	GUI.EnemyName.Text = string.upper(formattedData.Name)
	GUI.WeaknessText.Text = "TACTICAL REPORT: " .. formattedData.Tactics

	local fallbackIcon = EnemyData.BossIcons["System"] or ""
	GUI.EnemyImage.Image = EnemyData.BossIcons[formattedData.Key] or EnemyData.BossIcons[formattedData.Name] or fallbackIcon

	for _, child in ipairs(GUI.LootScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if #formattedData.Drops == 0 then
		local dText = Instance.new("TextLabel", GUI.LootScroll)
		dText.Size = UDim2.new(1, 0, 0, 30)
		dText.BackgroundTransparency = 1
		dText.Text = "No known drops recorded."
		dText.Font = Enum.Font.GothamMedium
		dText.TextColor3 = C_STEEL
		dText.TextSize = 13
		dText.TextXAlignment = Enum.TextXAlignment.Left
		return
	end

	for _, drop in ipairs(formattedData.Drops) do
		local dropFrame = Instance.new("Frame", GUI.LootScroll)
		dropFrame.Size = UDim2.new(1, 0, 0, 35)
		dropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		dropFrame.BorderSizePixel = 0

		local rarityColor = drop.Color or C_TEXT_MUTED
		local dStroke = Instance.new("UIStroke", dropFrame)
		dStroke.Color = Color3.new(rarityColor.R * 0.5, rarityColor.G * 0.5, rarityColor.B * 0.5)
		dStroke.Thickness = 1
		dStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local nameLbl = Instance.new("TextLabel", dropFrame)
		nameLbl.Size = UDim2.new(0.7, 0, 1, 0)
		nameLbl.Position = UDim2.new(0, 15, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = drop.ItemName
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextColor3 = rarityColor
		nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local rateLbl = Instance.new("TextLabel", dropFrame)
		rateLbl.Size = UDim2.new(0.3, -15, 1, 0)
		rateLbl.Position = UDim2.new(0.7, 0, 0, 0)
		rateLbl.BackgroundTransparency = 1
		rateLbl.Text = drop.Rate .. "%"
		rateLbl.Font = Enum.Font.GothamBlack
		rateLbl.TextColor3 = C_TEXT_MUTED
		rateLbl.TextSize = 13
		rateLbl.TextXAlignment = Enum.TextXAlignment.Right
	end
end

return BestiaryUI