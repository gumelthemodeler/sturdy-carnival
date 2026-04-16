-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileSupplyForgeTab
local MobileSupplyForgeTab = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local SharedUI = player:WaitForChild("PlayerScripts"):WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local NotificationManager = require(SharedUI:WaitForChild("NotificationManager"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData")) 
local ClanData = require(ReplicatedStorage:WaitForChild("ClanData"))
local hasSkillData, SkillData = pcall(function() return require(ReplicatedStorage:WaitForChild("SkillData")) end)
local VFXManager = require(player:WaitForChild("PlayerScripts"):WaitForChild("VFXManager"))

local CONFIG = {
	RarityColors = {
		Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(85, 255, 85),
		Rare = Color3.fromRGB(85, 85, 255), Epic = Color3.fromRGB(170, 85, 255),
		Legendary = Color3.fromRGB(255, 215, 0), Mythical = Color3.fromRGB(255, 85, 85),
		Transcendent = Color3.fromRGB(255, 85, 255)
	}
}

local function ColorToHex(c3)
	return string.format("#%02X%02X%02X", math.floor(c3.R * 255), math.floor(c3.G * 255), math.floor(c3.B * 255))
end

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
	tsc.MaxTextSize = textSize; tsc.MinTextSize = 9

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

local function GetClanBuffStrings(clanKey, isAbyssal)
	local buffs = {}
	if not ClanData.Clans or not ClanData.Clans[clanKey] then return buffs end
	local cData = ClanData.Clans[clanKey]

	if clanKey == "Fritz" then
		table.insert(buffs, "6.0x MAX HP | 5.0x DMG | 5.0x ARMOR | 3.5x SPEED")
		table.insert(buffs, "8x Guaranteed Death Defiance")
		table.insert(buffs, "Founding Titan Synergy: +0.50x DMG, HP, ARMOR")
		return buffs
	end

	if isAbyssal then
		local statLine = ""
		if cData.AbyssalDmgMult then statLine = statLine .. cData.AbyssalDmgMult .. "x DMG | " end
		if cData.AbyssalHpMult then statLine = statLine .. cData.AbyssalHpMult .. "x HP | " end
		if cData.AbyssalArmorMult then statLine = statLine .. cData.AbyssalArmorMult .. "x ARMOR | " end
		if cData.AbyssalSpdMult then statLine = statLine .. cData.AbyssalSpdMult .. "x SPD | " end
		if statLine ~= "" then table.insert(buffs, statLine:sub(1, -3)) end

		if cData.AbyssalSurvivals then
			table.insert(buffs, cData.AbyssalSurvivals .. "x Death Defiance (" .. (cData.SurvivalChance or 100) .. "%)")
		end
		if cData.AbyssalNapeCritMultiplier then
			table.insert(buffs, cData.AbyssalNapeCritMultiplier .. "x Nape Crit DMG")
		end
		if cData.AbyssalDodgeBonus then
			table.insert(buffs, "+" .. cData.AbyssalDodgeBonus .. "% Dodge Chance")
		end
		if cData.AbyssalMomentumDamagePerHit then
			table.insert(buffs, "+" .. (cData.AbyssalMomentumDamagePerHit*100) .. "% DMG per Momentum Stack")
		end
	end
	return buffs
end

function MobileSupplyForgeTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	local MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1

	local mLayout = Instance.new("UIListLayout", MainFrame)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Padding = UDim.new(0, 10)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local mPad = Instance.new("UIPadding", MainFrame)
	mPad.PaddingTop = UDim.new(0, 10)

	local SubNav = Instance.new("ScrollingFrame", MainFrame)
	SubNav.Size = UDim2.new(1, -10, 0, 40)
	SubNav.BackgroundTransparency = 1
	SubNav.LayoutOrder = 1
	SubNav.ScrollBarThickness = 0
	SubNav.ScrollingDirection = Enum.ScrollingDirection.X

	local navLayout = Instance.new("UIListLayout", SubNav)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 5)
	navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SubNav.CanvasSize = UDim2.new(0, navLayout.AbsoluteContentSize.X + 20, 0, 0) end)

	local ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(1, -10, 1, -60)
	ContentArea.BackgroundTransparency = 1
	ContentArea.LayoutOrder = 2

	local subTabs = { "MARKET", "FORGE", "RITUAL", "FUSION", "TRADE" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNav, tabName, UDim2.new(0, 85, 0, 35), Enum.Font.GothamBold, 11)
		btn.TextColor3 = UIHelpers.Colors.TextMuted
		stroke.Color = UIHelpers.Colors.BorderMuted

		local subFrame = Instance.new("Frame", ContentArea)
		subFrame.Name = tabName
		subFrame.Size = UDim2.new(1, 0, 1, 0)
		subFrame.BackgroundTransparency = 1
		subFrame.Visible = (i == 1)

		activeSubFrames[tabName] = subFrame
		subBtns[tabName] = {Btn = btn, Stroke = stroke}

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabName) end
			for name, bData in pairs(subBtns) do
				bData.Btn.TextColor3 = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted
				bData.Stroke.Color = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted
			end
		end)
	end

	subBtns["MARKET"].Btn.TextColor3 = UIHelpers.Colors.Gold
	subBtns["MARKET"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- 1. MARKETPLACE
	-- ==========================================
	local MarketTab = activeSubFrames["MARKET"]

	local marketTitle = UIHelpers.CreateLabel(MarketTab, "MARKETPLACE & SUPPLY", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18)
	marketTitle.Position = UDim2.new(0, 0, 0, 0)

	local SplitContainer = Instance.new("ScrollingFrame", MarketTab)
	SplitContainer.Size = UDim2.new(1, 0, 1, -30)
	SplitContainer.Position = UDim2.new(0, 0, 0, 30)
	SplitContainer.BackgroundTransparency = 1
	SplitContainer.ScrollBarThickness = 4
	SplitContainer.BorderSizePixel = 0

	local scLayout = Instance.new("UIListLayout", SplitContainer)
	scLayout.FillDirection = Enum.FillDirection.Vertical
	scLayout.Padding = UDim.new(0, 15)
	scLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	scLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		SplitContainer.CanvasSize = UDim2.new(0, 0, 0, scLayout.AbsoluteContentSize.Y + 20) 
	end)

	local LeftPanel = Instance.new("Frame", SplitContainer)
	LeftPanel.Size = UDim2.new(1, -10, 0, 240)
	LeftPanel.BackgroundTransparency = 1

	local PremContainer = Instance.new("Frame", LeftPanel)
	PremContainer.Size = UDim2.new(1, 0, 1, -80)
	PremContainer.BackgroundTransparency = 1

	local pTitle = UIHelpers.CreateLabel(PremContainer, "PREMIUM STORE", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)

	local PremScroll = Instance.new("ScrollingFrame", PremContainer)
	PremScroll.Size = UDim2.new(1, -10, 1, -30)
	PremScroll.Position = UDim2.new(0, 5, 0, 25)
	PremScroll.BackgroundTransparency = 1
	PremScroll.ScrollBarThickness = 4
	PremScroll.BorderSizePixel = 0

	local pslayout = Instance.new("UIListLayout", PremScroll)
	pslayout.Padding = UDim.new(0, 10)
	pslayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PremScroll.CanvasSize = UDim2.new(0,0,0, pslayout.AbsoluteContentSize.Y + 10) end)

	local function CreatePremiumCard(titleText, descText, buyAction, giftAction)
		local pCard = Instance.new("Frame", PremScroll)
		pCard.Size = UDim2.new(1, 0, 0, 75)
		pCard.BackgroundTransparency = 1

		local bgGlow = Instance.new("Frame", pCard)
		bgGlow.Size = UDim2.new(1, 0, 1, 0)
		bgGlow.BackgroundColor3 = UIHelpers.Colors.Gold
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow)
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.7) }

		local pName = UIHelpers.CreateLabel(pCard, string.upper(titleText), UDim2.new(1, -10, 0, 18), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12)
		pName.Position = UDim2.new(0, 5, 0, 5); pName.TextXAlignment = Enum.TextXAlignment.Left; pName.ZIndex = 2

		local pDesc = UIHelpers.CreateLabel(pCard, descText or "A premium item.", UDim2.new(1, -10, 0, 18), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 10)
		pDesc.Position = UDim2.new(0, 5, 0, 23); pDesc.TextXAlignment = Enum.TextXAlignment.Left; pDesc.ZIndex = 2

		local btnContainer = Instance.new("Frame", pCard)
		btnContainer.Size = UDim2.new(1, -10, 0, 25)
		btnContainer.Position = UDim2.new(0, 5, 1, -30)
		btnContainer.BackgroundTransparency = 1
		btnContainer.ZIndex = 3
		local bcLayout = Instance.new("UIListLayout", btnContainer); bcLayout.FillDirection = Enum.FillDirection.Horizontal; bcLayout.Padding = UDim.new(0, 5)

		if giftAction then
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)

			local giftBtn, giftStroke = CreateSharpButton(btnContainer, "GIFT", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
			giftBtn.TextColor3 = Color3.fromRGB(200, 100, 255); giftStroke.Color = Color3.fromRGB(200, 100, 255); giftBtn.MouseButton1Click:Connect(giftAction)
		else
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 12)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)
		end
	end

	if ItemData.Gamepasses then
		for _, gp in ipairs(ItemData.Gamepasses) do CreatePremiumCard(gp.Name, gp.Desc, function() MarketplaceService:PromptGamePassPurchase(player, gp.ID) end, gp.GiftID and function() MarketplaceService:PromptProductPurchase(player, gp.GiftID) end or nil) end
	end
	if ItemData.Products then
		for _, prod in ipairs(ItemData.Products) do
			if not prod.IsReroll and not string.find(prod.Name, "Gift:") then CreatePremiumCard(prod.Name, prod.Desc, function() MarketplaceService:PromptProductPurchase(player, prod.ID) end, nil) end
		end
	end

	local CodeContainer = Instance.new("Frame", LeftPanel)
	CodeContainer.Size = UDim2.new(1, 0, 0, 70)
	CodeContainer.Position = UDim2.new(0, 0, 1, -70)
	CodeContainer.BackgroundTransparency = 1 

	local cInput = Instance.new("TextBox", CodeContainer)
	cInput.Size = UDim2.new(0.65, 0, 0, 30)
	cInput.Position = UDim2.new(0.05, 0, 0.5, 0)
	cInput.AnchorPoint = Vector2.new(0, 0.5)
	cInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	cInput.TextColor3 = UIHelpers.Colors.Gold
	cInput.Font = Enum.Font.GothamBlack
	cInput.TextSize = 12
	cInput.PlaceholderText = "Redeem Code..."
	cInput.Text = ""
	Instance.new("UIStroke", cInput).Color = UIHelpers.Colors.BorderMuted

	local RedeemBtn, redeemStroke = CreateSharpButton(CodeContainer, "REDEEM", UDim2.new(0.25, 0, 0, 30), Enum.Font.GothamBlack, 12)
	RedeemBtn.Position = UDim2.new(0.95, 0, 0.5, 0)
	RedeemBtn.AnchorPoint = Vector2.new(1, 0.5)
	RedeemBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
	redeemStroke.Color = Color3.fromRGB(85, 170, 255)
	RedeemBtn.MouseButton1Click:Connect(function() if cInput.Text ~= "" then Network:WaitForChild("RedeemCode"):FireServer(cInput.Text); cInput.Text = "" end end)

	local RightPanel = Instance.new("Frame", SplitContainer)
	RightPanel.Size = UDim2.new(1, -10, 0, 300)
	RightPanel.BackgroundTransparency = 1

	local rrContainer = Instance.new("Frame", RightPanel)
	rrContainer.Size = UDim2.new(1, 0, 0, 40)
	rrContainer.BackgroundTransparency = 1
	local rrLayout = Instance.new("UIListLayout", rrContainer); rrLayout.FillDirection = Enum.FillDirection.Horizontal; rrLayout.Padding = UDim.new(0, 10); rrLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local rrDews, rrDewsStroke = CreateSharpButton(rrContainer, "RESTOCK (300K Dews)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 11)
	rrDews.TextColor3 = Color3.fromRGB(85, 170, 255)
	rrDewsStroke.Color = Color3.fromRGB(85, 170, 255)

	local rrPremium, rrPremStroke = CreateSharpButton(rrContainer, "RESTOCK (15 R$)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 11)

	local isFreeRestock = false
	local function UpdateRerollButton()
		local hasVIP = player:GetAttribute("HasVIP")
		local lastRoll = player:GetAttribute("LastFreeReroll") or 0
		if hasVIP and (os.time() - lastRoll) >= 86400 then
			rrPremium.Text = "FREE (VIP)"
			rrPremium.TextColor3 = Color3.fromRGB(200, 100, 255)
			rrPremStroke.Color = Color3.fromRGB(200, 100, 255)
			isFreeRestock = true
		else
			rrPremium.Text = "RESTOCK (50 R$)"
			rrPremium.TextColor3 = Color3.fromRGB(85, 255, 85)
			rrPremStroke.Color = Color3.fromRGB(85, 255, 85)
			isFreeRestock = false
		end
	end
	UpdateRerollButton()

	rrDews.MouseButton1Click:Connect(function() Network:WaitForChild("VIPFreeReroll"):FireServer(true) end)
	rrPremium.MouseButton1Click:Connect(function()
		if isFreeRestock then Network:WaitForChild("VIPFreeReroll"):FireServer(false) else
			local rerollId = nil
			if ItemData.Products then for _, prod in ipairs(ItemData.Products) do if prod.IsReroll then rerollId = prod.ID break end end end
			if rerollId then MarketplaceService:PromptProductPurchase(player, rerollId) end
		end
	end)

	local restockTimer = UIHelpers.CreateLabel(RightPanel, "RESTOCKS IN: 00:00", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 150, 100), 12)
	restockTimer.Position = UDim2.new(0, 0, 0, 45)

	local SupplyScroll = Instance.new("Frame", RightPanel)
	SupplyScroll.Size = UDim2.new(1, 0, 1, -70)
	SupplyScroll.Position = UDim2.new(0, 0, 0, 70)
	SupplyScroll.BackgroundTransparency = 1

	local ssLayout = Instance.new("UIListLayout", SupplyScroll)
	ssLayout.Padding = UDim.new(0, 8)
	ssLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		RightPanel.Size = UDim2.new(1, -10, 0, ssLayout.AbsoluteContentSize.Y + 80)
	end)

	local function AddSupplyItem(itemName, itemData, cost, isSoldOut)
		local rarityColor = CONFIG.RarityColors[itemData.Rarity or "Common"] or Color3.fromRGB(200, 200, 200)

		local c = Instance.new("Frame", SupplyScroll)
		c.Size = UDim2.new(1, 0, 0, 65)
		c.BackgroundTransparency = 1

		local bgGlow = Instance.new("Frame", c)
		bgGlow.Size = UDim2.new(1, 0, 1, 0)
		bgGlow.BackgroundColor3 = rarityColor
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow); grad.Rotation = 90; grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.8) }

		local cStroke = Instance.new("UIStroke", c)
		cStroke.Color = rarityColor
		cStroke.Thickness = 2
		cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local nameLbl = UIHelpers.CreateLabel(c, itemName, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBlack, rarityColor, 14)
		nameLbl.Position = UDim2.new(0, 10, 0, 5); nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 2

		local statsTxt = itemData.Bonus and "Provides Stat Bonuses" or (itemData.Desc or "A useful item.")
		local statsLbl = UIHelpers.CreateLabel(c, statsTxt, UDim2.new(0.6, 0, 0, 15), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 10)
		statsLbl.Position = UDim2.new(0, 10, 0, 25); statsLbl.TextXAlignment = Enum.TextXAlignment.Left; statsLbl.ZIndex = 2

		local costLbl = UIHelpers.CreateLabel(c, tostring(cost) .. " Dews", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 11)
		costLbl.Position = UDim2.new(0, 10, 1, -25); costLbl.TextXAlignment = Enum.TextXAlignment.Left; costLbl.ZIndex = 2

		local actionText = isSoldOut and "SOLD" or "BUY"
		local buyBtn, buyStroke = CreateSharpButton(c, actionText, UDim2.new(0, 80, 0, 30), Enum.Font.GothamBlack, 12)
		buyBtn.Position = UDim2.new(1, -10, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5); buyBtn.ZIndex = 3

		if isSoldOut then
			buyBtn.TextColor3 = Color3.fromRGB(100, 100, 100); buyStroke.Color = Color3.fromRGB(70, 70, 80); buyBtn.Active = false
		else
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85)
			buyBtn.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("BuyItem", itemName) end)
		end
	end

	local isShopTimerActive = false
	local function RefreshShop()
		local shopData = Network:WaitForChild("GetShopData"):InvokeServer()
		if not shopData or not shopData.Items then return end
		for _, c in ipairs(SupplyScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, item in ipairs(shopData.Items) do
			local itemDef = ItemData.Equipment[item.Name] or ItemData.Consumables[item.Name]
			if itemDef then AddSupplyItem(item.Name, itemDef, item.Cost, item.SoldOut) end
		end
		local timeLeft = shopData.TimeLeft or 600
		isShopTimerActive = false; task.wait(1.1); isShopTimerActive = true
		task.spawn(function()
			while timeLeft > 0 and isShopTimerActive do
				local m = math.floor(timeLeft / 60); local s = timeLeft % 60
				restockTimer.Text = string.format("RESTOCKS IN: %02d:%02d", m, s)
				task.wait(1); timeLeft -= 1
			end
			if isShopTimerActive then RefreshShop() end
		end)
	end

	player.AttributeChanged:Connect(function(attr)
		if attr == "ShopPurchases_Data" or attr == "PersonalShopSeed" then RefreshShop() end
		if attr == "LastFreeReroll" or attr == "HasVIP" then UpdateRerollButton() end
	end)
	RefreshShop()

	-- ==========================================
	-- 2. THE FORGE
	-- ==========================================
	local ForgeTab = activeSubFrames["FORGE"]

	local fSplitContainer = Instance.new("ScrollingFrame", ForgeTab)
	fSplitContainer.Size = UDim2.new(1, 0, 1, 0)
	fSplitContainer.BackgroundTransparency = 1
	fSplitContainer.ScrollBarThickness = 4
	fSplitContainer.BorderSizePixel = 0

	local fsLayout = Instance.new("UIListLayout", fSplitContainer)
	fsLayout.FillDirection = Enum.FillDirection.Vertical
	fsLayout.Padding = UDim.new(0, 15)
	fsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	fsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		fSplitContainer.CanvasSize = UDim2.new(0, 0, 0, fsLayout.AbsoluteContentSize.Y + 20) 
	end)

	local BlueprintPanel = Instance.new("Frame", fSplitContainer)
	BlueprintPanel.Size = UDim2.new(1, -10, 0, 350)
	BlueprintPanel.LayoutOrder = 1
	BlueprintPanel.BackgroundTransparency = 1

	local InfoView = Instance.new("Frame", BlueprintPanel)
	InfoView.Size = UDim2.new(1, 0, 1, 0)
	InfoView.BackgroundTransparency = 1

	local bpTitle = UIHelpers.CreateLabel(InfoView, "SELECT A BLUEPRINT", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18)
	bpTitle.Position = UDim2.new(0, 10, 0, 10); bpTitle.TextXAlignment = Enum.TextXAlignment.Left

	local bpDesc = UIHelpers.CreateLabel(InfoView, "Select an item from the registry below to begin forging.", UDim2.new(1, -20, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
	bpDesc.Position = UDim2.new(0, 10, 0, 40); bpDesc.TextXAlignment = Enum.TextXAlignment.Left; bpDesc.TextWrapped = true; bpDesc.TextYAlignment = Enum.TextYAlignment.Top

	local ReqTitle = UIHelpers.CreateLabel(InfoView, "REQUIRED MATERIALS", UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
	ReqTitle.Position = UDim2.new(0, 10, 0, 85); ReqTitle.TextXAlignment = Enum.TextXAlignment.Left; ReqTitle.Visible = false

	local ReqList = Instance.new("Frame", InfoView)
	ReqList.Size = UDim2.new(1, -20, 0, 150)
	ReqList.Position = UDim2.new(0, 10, 0, 110)
	ReqList.BackgroundTransparency = 1
	local reqLayout = Instance.new("UIListLayout", ReqList); reqLayout.Padding = UDim.new(0, 8)

	reqLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ReqList.Size = UDim2.new(1, -20, 0, reqLayout.AbsoluteContentSize.Y)
		BlueprintPanel.Size = UDim2.new(1, -10, 0, 115 + reqLayout.AbsoluteContentSize.Y + 70)
	end)

	local CraftBtn, CraftStroke = CreateSharpButton(InfoView, "FORGE EQUIPMENT", UDim2.new(0.8, 0, 0, 45), Enum.Font.GothamBlack, 16)
	CraftBtn.Position = UDim2.new(0.5, 0, 1, -15); CraftBtn.AnchorPoint = Vector2.new(0.5, 1); CraftBtn.Visible = false
	CraftBtn.TextColor3 = Color3.fromRGB(225, 185, 60); CraftStroke.Color = Color3.fromRGB(225, 185, 60)

	local MinigameView = Instance.new("Frame", BlueprintPanel)
	MinigameView.Size = UDim2.new(1, 0, 1, 0)
	MinigameView.BackgroundTransparency = 1
	MinigameView.Visible = false

	local mgTitle = UIHelpers.CreateLabel(MinigameView, "ACTIVE FORGE", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 100, 100), 20)
	mgTitle.Position = UDim2.new(0, 0, 0, 20)

	local mgInst = UIHelpers.CreateLabel(MinigameView, "Strike when the heat aligns perfectly. (0/3)", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12)
	mgInst.Position = UDim2.new(0, 0, 0, 60)

	local BarContainer, bcStroke = CreateGrimPanel(MinigameView)
	BarContainer.Size = UDim2.new(0.85, 0, 0, 40)
	BarContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	BarContainer.AnchorPoint = Vector2.new(0.5, 0.5)

	local SweetSpot = Instance.new("Frame", BarContainer)
	SweetSpot.Size = UDim2.new(0.25, 0, 1, 0) 
	SweetSpot.Position = UDim2.new(0.375, 0, 0, 0)
	SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
	SweetSpot.BorderSizePixel = 0

	local Cursor = Instance.new("Frame", BarContainer)
	Cursor.Size = UDim2.new(0.02, 0, 1.4, 0)
	Cursor.Position = UDim2.new(0, 0, 0.5, 0)
	Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Cursor.BorderSizePixel = 0

	local StrikeBtn, StrikeStroke = CreateSharpButton(MinigameView, "STRIKE", UDim2.new(0.6, 0, 0, 50), Enum.Font.GothamBlack, 20)
	StrikeBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
	StrikeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	StrikeBtn.TextColor3 = Color3.fromRGB(255, 85, 85); StrikeStroke.Color = Color3.fromRGB(255, 85, 85)

	local selectedRecipeName = nil; local mgActive = false; local mgConn = nil; local strikes = 0; local totalAccuracy = 0; local currentTargetCenter = 0.5

	local function ResetSweetSpot()
		local w = 0.25; local p = math.random(10, 65) / 100 
		SweetSpot.Position = UDim2.new(p, 0, 0, 0); currentTargetCenter = p + (w / 2); SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
	end

	local function EndMinigame()
		mgActive = false
		if mgConn then mgConn:Disconnect() mgConn = nil end

		local finalQuality = "Standard"
		local avg = totalAccuracy / 3
		if avg >= 0.80 then finalQuality = "Flawless"
		elseif avg >= 0.40 then finalQuality = "Masterwork" end

		mgInst.Text = "Forge Complete! Quality: <font color='#FFD700'>" .. string.upper(finalQuality) .. "</font>"
		task.wait(1.5)
		MinigameView.Visible = false; InfoView.Visible = true
		if selectedRecipeName then Network:WaitForChild("ForgeItem"):FireServer(selectedRecipeName, finalQuality) end
	end

	StrikeBtn.MouseButton1Click:Connect(function()
		if not mgActive then return end
		local cursorPos = Cursor.Position.X.Scale
		local dist = math.abs(cursorPos - currentTargetCenter)
		local accuracy = 0

		if dist <= 0.125 then
			accuracy = 1 - (dist / 0.125) 
			SweetSpot.BackgroundColor3 = Color3.fromRGB(255, 215, 0) 
		else
			accuracy = 0
			SweetSpot.BackgroundColor3 = Color3.fromRGB(255, 85, 85) 
		end

		totalAccuracy += accuracy; strikes += 1
		mgInst.Text = "Strike when the heat aligns perfectly. (" .. strikes .. "/3)"

		if strikes >= 3 then EndMinigame() else mgActive = false; task.wait(0.4); ResetSweetSpot(); mgActive = true end
	end)

	CraftBtn.MouseButton1Click:Connect(function()
		if not CraftBtn.Active or not selectedRecipeName then return end
		local recipe = ItemData.ForgeRecipes[selectedRecipeName]
		if not recipe then return end

		local hasAllMats = true
		for req, amt in pairs(recipe.ReqItems) do
			local count = tonumber(player:GetAttribute(req:gsub("[^%w]", "") .. "Count")) or 0
			if count < amt then hasAllMats = false; break end
		end
		local dews = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Dews") and player.leaderstats.Dews.Value or 0
		if dews < recipe.DewCost then hasAllMats = false end

		if not hasAllMats then if NotificationManager then NotificationManager.Show("Insufficient Materials!", "Error") end return end

		InfoView.Visible = false; MinigameView.Visible = true; strikes = 0; totalAccuracy = 0; mgInst.Text = "Strike when the heat aligns perfectly. (0/3)"; ResetSweetSpot(); mgActive = true
		BlueprintPanel.Size = UDim2.new(1, -10, 0, 300) 

		local t = 0
		if mgConn then mgConn:Disconnect() end
		mgConn = RunService.RenderStepped:Connect(function(dt)
			if mgActive then
				local speed = 1.8 + (strikes * 0.6) 
				t += dt * speed
				Cursor.Position = UDim2.new((math.sin(t) + 1) / 2, 0, 0.5, 0)
			end
		end)
	end)

	local RecipeList = Instance.new("Frame", fSplitContainer)
	RecipeList.Size = UDim2.new(1, -10, 0, 180)
	RecipeList.BackgroundTransparency = 1
	RecipeList.LayoutOrder = 2
	local rlLayout = Instance.new("UIListLayout", RecipeList); rlLayout.Padding = UDim.new(0, 8)
	rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RecipeList.Size = UDim2.new(1, -10, 0, rlLayout.AbsoluteContentSize.Y) end)

	-- [[ THE FIX: Safely exclude Itemized Abyssal recipes from Mobile Forge Tab ]]
	for rec, recipeData in pairs(ItemData.ForgeRecipes or {}) do
		if rec == "Fritz Clan Serum" or rec == "Ancestral Awakening Serum" or string.find(rec, "Itemized Abyssal") then continue end
		local resItem = recipeData.Result
		local resData = ItemData.Equipment[resItem] or ItemData.Consumables[resItem]
		local rarity = resData and resData.Rarity or "Common"
		local rColor = CONFIG.RarityColors[rarity] or Color3.fromRGB(200,200,200)

		local rBtn = Instance.new("TextButton", RecipeList)
		rBtn.Size = UDim2.new(1, 0, 0, 50)
		rBtn.BackgroundTransparency = 1
		rBtn.AutoButtonColor = false
		rBtn.Text = ""

		local bgGlow = Instance.new("Frame", rBtn)
		bgGlow.Size = UDim2.new(1, 0, 1, 0)
		bgGlow.BackgroundColor3 = rColor
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow); grad.Rotation = 90; grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.8) }

		local rTitleLbl = UIHelpers.CreateLabel(rBtn, string.upper(rec), UDim2.new(1, -15, 0, 20), Enum.Font.GothamBlack, rColor, 12)
		rTitleLbl.Position = UDim2.new(0, 10, 0, 5); rTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; rTitleLbl.ZIndex = 2

		local rTagLbl = UIHelpers.CreateLabel(rBtn, "[" .. string.upper(rarity) .. "]", UDim2.new(1, -15, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 200, 200), 10)
		rTagLbl.Position = UDim2.new(0, 10, 1, -20); rTagLbl.TextXAlignment = Enum.TextXAlignment.Left; rTagLbl.ZIndex = 2

		local rStrk = Instance.new("UIStroke", rBtn); rStrk.Color = rColor; rStrk.Thickness = 2; rStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		rBtn.InputBegan:Connect(function() rTitleLbl.TextColor3 = UIHelpers.Colors.Gold; rTagLbl.TextColor3 = UIHelpers.Colors.Gold; rStrk.Color = UIHelpers.Colors.Gold end)
		rBtn.InputEnded:Connect(function() rTitleLbl.TextColor3 = rColor; rTagLbl.TextColor3 = Color3.fromRGB(200, 200, 200); rStrk.Color = rColor end)

		rBtn.MouseButton1Click:Connect(function()
			selectedRecipeName = rec 
			bpTitle.Text = string.upper(rec); bpTitle.TextColor3 = rColor
			bpDesc.Text = "<font color='" .. ColorToHex(rColor) .. "'>[" .. rarity:upper() .. "]</font> " .. (resData and resData.Desc or "A piece of equipment forged from rare materials."); bpDesc.RichText = true
			ReqTitle.Visible = true; CraftBtn.Visible = true

			for _, c in ipairs(ReqList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			local function MakeReq(matName, amt, hasAmt)
				local rf = Instance.new("Frame", ReqList)
				rf.Size = UDim2.new(1, 0, 0, 25)
				rf.BackgroundTransparency = 1
				rf.ZIndex = 103

				local reqBg = Instance.new("Frame", rf)
				reqBg.Size = UDim2.new(1, 0, 1, 0)
				reqBg.BackgroundColor3 = hasAmt and UIHelpers.Colors.BorderMuted or Color3.fromRGB(150, 40, 40)
				reqBg.BackgroundTransparency = hasAmt and 0.5 or 0 
				reqBg.BorderSizePixel = 0
				local rGrad = Instance.new("UIGradient", reqBg); rGrad.Rotation = 90; rGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.7) }

				local l = UIHelpers.CreateLabel(rf, amt .. "x " .. matName, UDim2.new(1, -10, 1, 0), Enum.Font.GothamBold, hasAmt and UIHelpers.Colors.TextWhite or Color3.fromRGB(255, 100, 100), 11)
				l.Position = UDim2.new(0, 10, 0, 0); l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 104
			end

			local hasAllMats = true
			if ItemData.ForgeRecipes[rec] then
				for mat, amt in pairs(ItemData.ForgeRecipes[rec].ReqItems) do 
					local count = tonumber(player:GetAttribute(mat:gsub("[^%w]", "") .. "Count")) or 0
					local hasEnough = count >= amt; if not hasEnough then hasAllMats = false end
					MakeReq(mat, amt, hasEnough) 
				end
				local dCount = tonumber(player:GetAttribute("Dews")) or 0
				local hasDews = dCount >= ItemData.ForgeRecipes[rec].DewCost; if not hasDews then hasAllMats = false end
				MakeReq("Dews", ItemData.ForgeRecipes[rec].DewCost, hasDews)
			end

			if hasAllMats then
				CraftBtn.Active = true; CraftBtn.Text = "START FORGE"; CraftBtn.TextColor3 = rColor; CraftStroke.Color = rColor
			else
				CraftBtn.Active = false; CraftBtn.Text = "INSUFFICIENT MATERIALS"; CraftBtn.TextColor3 = Color3.fromRGB(100, 100, 100); CraftStroke.Color = Color3.fromRGB(50, 50, 60)
			end
		end)
	end

	-- ==========================================
	-- 2.5 BLOODLINE RITUAL
	-- ==========================================
	local RitualTab = activeSubFrames["RITUAL"]
	local selectedRitualName = nil 

	local rSplitContainer = Instance.new("ScrollingFrame", RitualTab)
	rSplitContainer.Size = UDim2.new(1, 0, 1, 0)
	rSplitContainer.BackgroundTransparency = 1
	rSplitContainer.ScrollBarThickness = 4
	rSplitContainer.BorderSizePixel = 0

	local rsfLayout = Instance.new("UIListLayout", rSplitContainer)
	rsfLayout.FillDirection = Enum.FillDirection.Vertical
	rsfLayout.Padding = UDim.new(0, 15)
	rsfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rsfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		rSplitContainer.CanvasSize = UDim2.new(0, 0, 0, rsfLayout.AbsoluteContentSize.Y + 20) 
	end)

	local RitualPanel = Instance.new("Frame", rSplitContainer)
	RitualPanel.Size = UDim2.new(1, -10, 0, 350)
	RitualPanel.LayoutOrder = 1
	RitualPanel.BackgroundTransparency = 1 

	local RInfoView = Instance.new("Frame", RitualPanel)
	RInfoView.Size = UDim2.new(1, 0, 1, 0)
	RInfoView.BackgroundTransparency = 1

	local rbpTitle = UIHelpers.CreateLabel(RInfoView, "AWAITING TRIBUTE", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(150, 200, 255), 20)
	rbpTitle.Position = UDim2.new(0, 10, 0, 10); rbpTitle.TextXAlignment = Enum.TextXAlignment.Center

	local rbpDesc = UIHelpers.CreateLabel(RInfoView, "Select a rite from the tomes to rewrite your lineage.", UDim2.new(1, -40, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12)
	rbpDesc.Position = UDim2.new(0.5, 0, 0, 45); rbpDesc.AnchorPoint = Vector2.new(0.5, 0); rbpDesc.TextXAlignment = Enum.TextXAlignment.Center; rbpDesc.TextWrapped = true

	local RReqTitle = UIHelpers.CreateLabel(RInfoView, "REQUIRED SACRIFICES", UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
	RReqTitle.Position = UDim2.new(0, 10, 0, 95); RReqTitle.TextXAlignment = Enum.TextXAlignment.Left; RReqTitle.Visible = false

	local RReqList = Instance.new("Frame", RInfoView)
	RReqList.Size = UDim2.new(1, -20, 0, 150)
	RReqList.Position = UDim2.new(0, 10, 0, 120)
	RReqList.BackgroundTransparency = 1
	local rreqLayout = Instance.new("UIListLayout", RReqList); rreqLayout.Padding = UDim.new(0, 8)

	local RBuffList = Instance.new("Frame", RInfoView)
	RBuffList.Size = UDim2.new(1, -20, 0, 100)
	RBuffList.Position = UDim2.new(0, 10, 0, 280) 
	RBuffList.BackgroundTransparency = 1
	local rbuffLayout = Instance.new("UIListLayout", RBuffList)
	rbuffLayout.FillDirection = Enum.FillDirection.Vertical
	rbuffLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rbuffLayout.Padding = UDim.new(0, 5)

	rreqLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RReqList.Size = UDim2.new(1, -20, 0, rreqLayout.AbsoluteContentSize.Y)
		RBuffList.Position = UDim2.new(0, 10, 0, 120 + rreqLayout.AbsoluteContentSize.Y + 10)

		local buffHeight = rbuffLayout.AbsoluteContentSize.Y
		RBuffList.Size = UDim2.new(1, -20, 0, buffHeight)

		RitualPanel.Size = UDim2.new(1, -10, 0, 125 + rreqLayout.AbsoluteContentSize.Y + buffHeight + 80)
	end)

	local RCraftBtn, RCraftStroke = CreateSharpButton(RInfoView, "COMMENCE RITUAL", UDim2.new(0.8, 0, 0, 45), Enum.Font.GothamBlack, 16)
	RCraftBtn.Position = UDim2.new(0.5, 0, 1, -15); RCraftBtn.AnchorPoint = Vector2.new(0.5, 1); RCraftBtn.Visible = false
	RCraftBtn.TextColor3 = Color3.fromRGB(150, 200, 255)
	RCraftStroke.Color = Color3.fromRGB(150, 200, 255)

	TweenService:Create(RCraftStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5}):Play()

	local RMiniView = Instance.new("Frame", RitualPanel)
	RMiniView.Size = UDim2.new(1, 0, 1, 0)
	RMiniView.BackgroundTransparency = 1
	RMiniView.Visible = false

	local rChannelLbl = UIHelpers.CreateLabel(RMiniView, "SYNCHRONIZING WITH THE COORDINATE...", UDim2.new(1, -20, 0, 60), Enum.Font.GothamBlack, Color3.fromRGB(150, 200, 255), 18)
	rChannelLbl.Position = UDim2.new(0.5, 0, 0.3, 0); rChannelLbl.AnchorPoint = Vector2.new(0.5, 0); rChannelLbl.TextWrapped = true

	local rBarContainer, rBcStroke = CreateGrimPanel(RMiniView)
	rBarContainer.Size = UDim2.new(0.8, 0, 0, 20)
	rBarContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
	rBarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	rBarContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	rBcStroke.Color = Color3.fromRGB(50, 50, 70); rBcStroke.Thickness = 2

	local rProgressFill = Instance.new("Frame", rBarContainer)
	rProgressFill.Size = UDim2.new(0, 0, 1, 0)
	rProgressFill.BackgroundColor3 = Color3.fromRGB(150, 200, 255)
	rProgressFill.BorderSizePixel = 0

	RCraftBtn.MouseButton1Click:Connect(function()
		if not RCraftBtn.Active or not selectedRitualName then return end
		local recipe = ItemData.ForgeRecipes[selectedRitualName]
		if not recipe then return end

		local dews = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Dews") and player.leaderstats.Dews.Value or 0
		if dews < recipe.DewCost then NotificationManager.Show("Not enough Dews for this Ritual!", "Error") return end

		local hasMats = true
		for req, amt in pairs(recipe.ReqItems) do
			local count = player:GetAttribute(req:gsub("[^%w]", "") .. "Count") or 0
			if count < amt then hasMats = false; break end
		end

		if recipe.SpecialType == "AbyssalClanRequirement" then
			local abyssalFound = 0
			local abyssalClans = {
				"ItemizedAbyssalYeagerCount", "ItemizedAbyssalTyburCount", "ItemizedAbyssalAckermanCount", 
				"ItemizedAbyssalGalliardCount", "ItemizedAbyssalBraunCount", "ItemizedAbyssalReissCount"
			}
			for _, attr in ipairs(abyssalClans) do
				local count = player:GetAttribute(attr) or 0
				if count > 0 then
					abyssalFound += count
				end
			end
			if abyssalFound < (recipe.AbyssalClanCount or 2) then hasMats = false end
		end

		if not hasMats then NotificationManager.Show("Missing required sacrifices!", "Error") return end

		RInfoView.Visible = false
		RitualPanel.Size = UDim2.new(1, -10, 0, 300) 

		local cinGui = Instance.new("ScreenGui", player.PlayerGui)
		cinGui.Name = "RitualCinematicGui"
		cinGui.DisplayOrder = 1000
		cinGui.IgnoreGuiInset = true

		local bg = Instance.new("Frame", cinGui)
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
		bg.BackgroundTransparency = 1

		TweenService:Create(bg, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
		if VFXManager and type(VFXManager.PlaySFX) == "function" then VFXManager.PlaySFX("Steam", 0.5) end
		task.wait(2)

		local pathsLbl = UIHelpers.CreateLabel(bg, "CALLING UPON THE FOUNDER...", UDim2.new(1, 0, 1, 0), Enum.Font.Garamond, Color3.fromRGB(150, 200, 255), 24)
		pathsLbl.TextTransparency = 1
		TweenService:Create(pathsLbl, TweenInfo.new(1.5), {TextTransparency = 0}):Play()

		task.wait(2)
		TweenService:Create(pathsLbl, TweenInfo.new(1), {TextTransparency = 1}):Play()
		task.wait(1.5)

		pathsLbl.Text = "REWRITING ELDIAN BIOLOGY..."
		pathsLbl.TextColor3 = UIHelpers.Colors.Gold
		TweenService:Create(pathsLbl, TweenInfo.new(1.5), {TextTransparency = 0}):Play()

		if VFXManager and type(VFXManager.ScreenShake) == "function" then VFXManager.ScreenShake(3, 0.6) end
		if VFXManager and type(VFXManager.PlaySFX) == "function" then VFXManager.PlaySFX("TitanRoar", 0.7) end
		task.wait(2.5)

		local flash = Instance.new("Frame", cinGui)
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = UIHelpers.Colors.Gold
		flash.ZIndex = 10
		TweenService:Create(flash, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		if VFXManager and type(VFXManager.PlaySFX) == "function" then VFXManager.PlaySFX("HeavySlash", 0.8) end

		pathsLbl.Text = "BLOODLINE TRANSCENDED"
		pathsLbl.TextSize = 36
		task.wait(3)

		local fadeOut = TweenService:Create(bg, TweenInfo.new(1.5), {BackgroundTransparency = 1})
		TweenService:Create(pathsLbl, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Wait()
		cinGui:Destroy()

		RInfoView.Visible = true
		if selectedRitualName then
			Network:WaitForChild("ForgeItem"):FireServer(selectedRitualName, "Standard")
		end
	end)

	local RitualList = Instance.new("Frame", rSplitContainer)
	RitualList.Size = UDim2.new(1, -10, 0, 180)
	RitualList.BackgroundTransparency = 1
	RitualList.LayoutOrder = 2
	local rillLayout = Instance.new("UIListLayout", RitualList); rillLayout.Padding = UDim.new(0, 8)
	rillLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RitualList.Size = UDim2.new(1, -10, 0, rillLayout.AbsoluteContentSize.Y) end)

	-- [[ THE FIX: Exclusively include Itemized Abyssal Lineages in the Mobile Ritual Tab! ]]
	for rec, recipeData in pairs(ItemData.ForgeRecipes or {}) do
		if rec ~= "Fritz Clan Serum" and rec ~= "Ancestral Awakening Serum" and not string.find(rec, "Itemized Abyssal") then continue end

		local resItem = recipeData.Result
		local resData = ItemData.Equipment[resItem] or ItemData.Consumables[resItem]
		local rarity = resData and resData.Rarity or "Mythical"
		local rColor = CONFIG.RarityColors[rarity] or Color3.fromRGB(200,200,200)

		local rBtn = Instance.new("TextButton", RitualList)
		rBtn.Size = UDim2.new(1, 0, 0, 60)
		rBtn.BackgroundTransparency = 1
		rBtn.AutoButtonColor = false
		rBtn.Text = ""

		local rStrk = Instance.new("UIStroke", rBtn)
		rStrk.Color = rColor
		rStrk.Thickness = 2
		rStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local bgGlow = Instance.new("Frame", rBtn)
		bgGlow.Size = UDim2.new(1, 0, 1, 0)
		bgGlow.BackgroundColor3 = rColor
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow); grad.Rotation = 90; grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.8) }

		local rTitleLbl = UIHelpers.CreateLabel(rBtn, string.upper(rec), UDim2.new(1, -15, 0, 20), Enum.Font.GothamBlack, rColor, 12)
		rTitleLbl.Position = UDim2.new(0, 10, 0, 12)
		rTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; rTitleLbl.ZIndex = 2

		local rTagLbl = UIHelpers.CreateLabel(rBtn, "[ FORBIDDEN RITE ]", UDim2.new(1, -15, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 200, 200), 10)
		rTagLbl.Position = UDim2.new(0, 10, 1, -26)
		rTagLbl.TextXAlignment = Enum.TextXAlignment.Left; rTagLbl.ZIndex = 2

		rBtn.InputBegan:Connect(function() rTitleLbl.TextColor3 = UIHelpers.Colors.Gold; rTagLbl.TextColor3 = UIHelpers.Colors.Gold; rStrk.Color = UIHelpers.Colors.Gold end)
		rBtn.InputEnded:Connect(function() rTitleLbl.TextColor3 = rColor; rTagLbl.TextColor3 = Color3.fromRGB(200, 200, 200); rStrk.Color = rColor end)

		-- [[ THE FIX: Updated parsing for Abyssal recipes so Dynamic Buffs work on Mobile! ]]
		rBtn.MouseButton1Click:Connect(function()
			selectedRitualName = rec 
			rbpTitle.Text = string.upper(rec); rbpTitle.TextColor3 = rColor
			rbpDesc.Text = "<font color='" .. ColorToHex(rColor) .. "'>[" .. rarity:upper() .. "]</font> " .. (resData and resData.Desc or "A forbidden rite."); rbpDesc.RichText = true
			RReqTitle.Visible = true; RCraftBtn.Visible = true

			for _, c in ipairs(RReqList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			for _, c in ipairs(RBuffList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end

			local function MakeReq(matName, amt, hasAmt)
				local rf = Instance.new("Frame", RReqList)
				rf.Size = UDim2.new(1, 0, 0, 25)
				rf.BackgroundTransparency = 1
				rf.ZIndex = 103

				local reqBg = Instance.new("Frame", rf)
				reqBg.Size = UDim2.new(1, 0, 1, 0)
				reqBg.BackgroundColor3 = hasAmt and UIHelpers.Colors.BorderMuted or Color3.fromRGB(150, 40, 40)
				reqBg.BackgroundTransparency = hasAmt and 0.5 or 0 
				reqBg.BorderSizePixel = 0
				local rGrad = Instance.new("UIGradient", reqBg); rGrad.Rotation = 90; rGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.7) }

				local l = UIHelpers.CreateLabel(rf, amt .. "x " .. matName, UDim2.new(1, -10, 1, 0), Enum.Font.GothamBold, hasAmt and UIHelpers.Colors.TextWhite or Color3.fromRGB(255, 100, 100), 11)
				l.Position = UDim2.new(0, 10, 0, 0); l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 104
			end

			local hasAllMats = true
			if ItemData.ForgeRecipes[rec] then
				for mat, amt in pairs(ItemData.ForgeRecipes[rec].ReqItems) do 
					local count = tonumber(player:GetAttribute(mat:gsub("[^%w]", "") .. "Count")) or 0
					local hasEnough = count >= amt; if not hasEnough then hasAllMats = false end
					MakeReq(mat, amt, hasEnough) 
				end

				if ItemData.ForgeRecipes[rec].SpecialType == "AbyssalClanRequirement" then
					local requiredCount = ItemData.ForgeRecipes[rec].AbyssalClanCount or 2
					local abyssalFound = 0
					local abyssalClans = {
						"ItemizedAbyssalYeagerCount", "ItemizedAbyssalTyburCount", "ItemizedAbyssalAckermanCount", 
						"ItemizedAbyssalGalliardCount", "ItemizedAbyssalBraunCount", "ItemizedAbyssalReissCount"
					}

					for _, attr in ipairs(abyssalClans) do
						local count = player:GetAttribute(attr) or 0
						if count > 0 then
							abyssalFound += count
						end
					end

					local hasEnough = abyssalFound >= requiredCount
					if not hasEnough then hasAllMats = false end
					MakeReq("Itemized Abyssal Variant", requiredCount, hasEnough)
				end

				local dCount = tonumber(player:GetAttribute("Dews")) or 0
				local hasDews = dCount >= ItemData.ForgeRecipes[rec].DewCost; if not hasDews then hasAllMats = false end
				MakeReq("Dews", ItemData.ForgeRecipes[rec].DewCost, hasDews)
			end

			local cKey = nil
			local isAbyssal = false
			if rec == "Fritz Clan Serum" then
				cKey = "Fritz"
				isAbyssal = true
			elseif string.find(rec, "Itemized Abyssal") then
				local baseClan = string.gsub(rec, "Itemized Abyssal ", "")
				cKey = baseClan
				isAbyssal = true
			end

			if cKey then
				local buffs = GetClanBuffStrings(cKey, isAbyssal)
				if #buffs > 0 then
					local bTitle = UIHelpers.CreateLabel(RBuffList, "RITUAL EMPOWERMENTS:", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12)
					bTitle.LayoutOrder = 0
					bTitle.TextXAlignment = Enum.TextXAlignment.Left
					for i, txt in ipairs(buffs) do
						local bLbl = UIHelpers.CreateLabel(RBuffList, "• " .. txt, UDim2.new(1, 0, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 220, 255), 11)
						bLbl.LayoutOrder = i
						bLbl.TextXAlignment = Enum.TextXAlignment.Left
						bLbl.AutomaticSize = Enum.AutomaticSize.XY
					end
				end
			end

			if hasAllMats then
				RCraftBtn.Active = true; RCraftBtn.Text = "COMMENCE RITUAL"; RCraftBtn.TextColor3 = rColor; RCraftStroke.Color = rColor
			else
				RCraftBtn.Active = false; RCraftBtn.Text = "INSUFFICIENT SACRIFICES"; RCraftBtn.TextColor3 = Color3.fromRGB(100, 100, 100); RCraftStroke.Color = Color3.fromRGB(50, 50, 60)
			end
		end)
	end

	local ArchivesPanel, aStrk = CreateGrimPanel(rSplitContainer)
	ArchivesPanel.Size = UDim2.new(1, -10, 0, 250)
	ArchivesPanel.LayoutOrder = 3
	aStrk.Color = Color3.fromRGB(100, 150, 255)

	local rRegTitle = UIHelpers.CreateLabel(ArchivesPanel, "ABYSSAL & TRANSCENDENT ARCHIVES", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(150, 200, 255), 14)
	rRegTitle.Position = UDim2.new(0, 0, 0, 10)

	local rRegScroll = Instance.new("ScrollingFrame", ArchivesPanel)
	rRegScroll.Size = UDim2.new(1, -20, 1, -50)
	rRegScroll.Position = UDim2.new(0, 10, 0, 40)
	rRegScroll.BackgroundTransparency = 1
	rRegScroll.ScrollBarThickness = 4
	rRegScroll.BorderSizePixel = 0

	local rrsLayout = Instance.new("UIListLayout", rRegScroll)
	rrsLayout.Padding = UDim.new(0, 10)
	rrsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		rRegScroll.CanvasSize = UDim2.new(0,0,0, rrsLayout.AbsoluteContentSize.Y + 10) 
	end)

	if ClanData and ClanData.Clans then
		local sortedClans = {"Yeager", "Tybur", "Ackerman", "Galliard", "Braun", "Reiss", "Fritz"}
		for _, cName in ipairs(sortedClans) do
			local cData = ClanData.Clans[cName]
			if not cData then continue end

			local buffs = GetClanBuffStrings(cName, true)
			if #buffs > 0 then
				local card, cStroke = CreateGrimPanel(rRegScroll)
				card.AutomaticSize = Enum.AutomaticSize.Y
				card.Size = UDim2.new(1, -10, 0, 0)
				cStroke.Color = (cName == "Fritz") and UIHelpers.Colors.Gold or Color3.fromRGB(150, 200, 255)

				local cPad = Instance.new("UIPadding", card)
				cPad.PaddingTop = UDim.new(0, 10)
				cPad.PaddingBottom = UDim.new(0, 10)
				cPad.PaddingLeft = UDim.new(0, 15)
				cPad.PaddingRight = UDim.new(0, 10)

				local clayout = Instance.new("UIListLayout", card)
				clayout.SortOrder = Enum.SortOrder.LayoutOrder
				clayout.Padding = UDim.new(0, 5)

				local title = UIHelpers.CreateLabel(card, (cName == "Fritz" and "FRITZ LINEAGE" or "ABYSSAL " .. string.upper(cName)), UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, (cName == "Fritz") and UIHelpers.Colors.Gold or Color3.fromRGB(150, 200, 255), 14)
				title.LayoutOrder = 1
				title.TextXAlignment = Enum.TextXAlignment.Left

				for j, txt in ipairs(buffs) do
					local bLbl = UIHelpers.CreateLabel(card, "• " .. txt, UDim2.new(1, 0, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 220, 255), 11)
					bLbl.LayoutOrder = j + 1
					bLbl.TextXAlignment = Enum.TextXAlignment.Left
					bLbl.AutomaticSize = Enum.AutomaticSize.XY
				end
			end
		end
	end


	-- ==========================================
	-- 3. TITAN FUSION
	-- ==========================================
	local FusionTab = activeSubFrames["FUSION"]

	local fSplitContainer = Instance.new("ScrollingFrame", FusionTab)
	fSplitContainer.Size = UDim2.new(1, 0, 1, 0)
	fSplitContainer.BackgroundTransparency = 1
	fSplitContainer.ScrollBarThickness = 4
	fSplitContainer.BorderSizePixel = 0

	local fsfLayout = Instance.new("UIListLayout", fSplitContainer)
	fsfLayout.FillDirection = Enum.FillDirection.Vertical
	fsfLayout.Padding = UDim.new(0, 15)
	fsfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	fsfLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		fSplitContainer.CanvasSize = UDim2.new(0, 0, 0, fsfLayout.AbsoluteContentSize.Y + 20) 
	end)

	local fLeftPanel = Instance.new("Frame", fSplitContainer)
	fLeftPanel.Size = UDim2.new(1, -10, 0, 320)
	fLeftPanel.BackgroundTransparency = 1
	fLeftPanel.LayoutOrder = 1

	local fTitle = UIHelpers.CreateLabel(fLeftPanel, "TITAN HYBRIDIZATION", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(170, 85, 255), 18)
	fTitle.Position = UDim2.new(0, 0, 0, 0)

	local fDesc = UIHelpers.CreateLabel(fLeftPanel, "Fuse two Pure Titans to create a Hybrid. Irreversible.", UDim2.new(1, -20, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
	fDesc.Position = UDim2.new(0, 10, 0, 30)

	local SlotContainer = Instance.new("Frame", fLeftPanel)
	SlotContainer.Size = UDim2.new(1, 0, 0, 200)
	SlotContainer.Position = UDim2.new(0.5, 0, 0.5, -10)
	SlotContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	SlotContainer.BackgroundTransparency = 1

	local function CreateFusionSlot(pos, titleText, isResult)
		local f, fStroke = CreateGrimPanel(SlotContainer)
		f.Size = UDim2.new(0, 90, 0, 90)
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		fStroke.Color = Color3.fromRGB(70, 70, 80)

		local t = UIHelpers.CreateLabel(f, titleText, UDim2.new(1, -10, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 9)
		t.Position = UDim2.new(0, 5, 0, 5)
		t.TextScaled = true; t.ZIndex = 2

		if isResult then
			local qLbl = UIHelpers.CreateLabel(f, "?", UDim2.new(1, 0, 1, -25), Enum.Font.GothamBlack, Color3.fromRGB(80, 70, 90), 36)
			qLbl.Position = UDim2.new(0, 0, 0, 25); qLbl.ZIndex = 2
			return f, t, qLbl, nil
		end

		local addBtn, addStroke = CreateSharpButton(f, "+", UDim2.new(0, 35, 0, 35), Enum.Font.GothamBlack, 18)
		addBtn.Position = UDim2.new(0.5, 0, 0.5, 10); addBtn.AnchorPoint = Vector2.new(0.5, 0.5); addBtn.ZIndex = 2

		local overBtn = Instance.new("TextButton", f)
		overBtn.Size = UDim2.new(1, 0, 1, 0); overBtn.BackgroundTransparency = 1; overBtn.Text = ""; overBtn.ZIndex = 10
		overBtn.InputBegan:Connect(function() fStroke.Color = UIHelpers.Colors.Gold; if addBtn.Visible then addStroke.Color = UIHelpers.Colors.Gold; addBtn.TextColor3 = UIHelpers.Colors.Gold end end)
		overBtn.InputEnded:Connect(function() if t.TextColor3 ~= UIHelpers.Colors.TextMuted then fStroke.Color = t.TextColor3 else fStroke.Color = Color3.fromRGB(70, 70, 80) end; if addBtn.Visible then addStroke.Color = Color3.fromRGB(70, 70, 80); addBtn.TextColor3 = Color3.fromRGB(245, 245, 245) end end)

		return f, t, addBtn, overBtn
	end

	local Slot1, Slot1Title, Slot1AddBtn, Slot1OverBtn = CreateFusionSlot(UDim2.new(0.22, 0, 0.25, 0), "ALPHA", false)
	local Slot2, Slot2Title, Slot2AddBtn, Slot2OverBtn = CreateFusionSlot(UDim2.new(0.78, 0, 0.25, 0), "OMEGA", false)
	local ResultSlot, ResultTitle, ResultLbl = CreateFusionSlot(UDim2.new(0.5, 0, 0.75, 0), "HYBRID", true)

	local l1 = Instance.new("Frame", SlotContainer); l1.Size = UDim2.new(0, 80, 0, 4); l1.Position = UDim2.new(0.35, 0, 0.5, 0); l1.Rotation = 60; l1.AnchorPoint = Vector2.new(0.5, 0.5); l1.BackgroundColor3 = Color3.fromRGB(50, 40, 60); l1.BorderSizePixel = 0
	local l2 = Instance.new("Frame", SlotContainer); l2.Size = UDim2.new(0, 80, 0, 4); l2.Position = UDim2.new(0.65, 0, 0.5, 0); l2.Rotation = -60; l2.AnchorPoint = Vector2.new(0.5, 0.5); l2.BackgroundColor3 = Color3.fromRGB(50, 40, 60); l2.BorderSizePixel = 0

	local FuseBtn, FuseStroke = CreateSharpButton(fLeftPanel, "INITIATE FUSION (300K DEWS)", UDim2.new(0.8, 0, 0, 45), Enum.Font.GothamBlack, 14)
	FuseBtn.Position = UDim2.new(0.5, 0, 1, -10); FuseBtn.AnchorPoint = Vector2.new(0.5, 1); FuseBtn.TextColor3 = Color3.fromRGB(170, 85, 255); FuseStroke.Color = Color3.fromRGB(170, 85, 255)

	local fRightPanel, _ = CreateGrimPanel(fSplitContainer)
	fRightPanel.Size = UDim2.new(1, -10, 0, 300)
	fRightPanel.LayoutOrder = 2

	local regTitle = UIHelpers.CreateLabel(fRightPanel, "FUSION REGISTRY", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(170, 85, 255), 18)
	regTitle.Position = UDim2.new(0, 0, 0, 10)

	local regScroll = Instance.new("Frame", fRightPanel)
	regScroll.Size = UDim2.new(1, -20, 1, -50)
	regScroll.Position = UDim2.new(0, 10, 0, 40)
	regScroll.BackgroundTransparency = 1

	local rsLayout = Instance.new("UIListLayout", regScroll)
	rsLayout.Padding = UDim.new(0, 10)
	rsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		regScroll.Size = UDim2.new(1, -20, 0, rsLayout.AbsoluteContentSize.Y)
		fRightPanel.Size = UDim2.new(1, -10, 0, rsLayout.AbsoluteContentSize.Y + 60)
	end)

	local FusionRecipes = { 
		["Female Titan"] = { ["Founding Titan"] = "Founding Female Titan" }, 
		["Founding Titan"] = { ["Female Titan"] = "Founding Female Titan", ["Attack Titan"] = "Founding Attack Titan" }, 
		["Attack Titan"] = { ["Armored Titan"] = "Armored Attack Titan", ["War Hammer Titan"] = "War Hammer Attack Titan", ["Founding Titan"] = "Founding Attack Titan" }, 
		["Armored Titan"] = { ["Attack Titan"] = "Armored Attack Titan" }, 
		["War Hammer Titan"] = { ["Attack Titan"] = "War Hammer Attack Titan" }, 
		["Colossal Titan"] = { ["Jaw Titan"] = "Colossal Jaw Titan" }, 
		["Jaw Titan"] = { ["Colossal Titan"] = "Colossal Jaw Titan" } 
	}

	local addedFusions = {}
	for alpha, omegas in pairs(FusionRecipes) do
		for omega, res in pairs(omegas) do
			if not addedFusions[res] then
				addedFusions[res] = { Alpha = alpha, Omega = omega }

				local fCard, fStroke = CreateGrimPanel(regScroll)
				fCard.Size = UDim2.new(1, 0, 0, 120)
				fStroke.Color = Color3.fromRGB(170, 85, 255)

				local resLbl = UIHelpers.CreateLabel(fCard, string.upper(res), UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(170, 85, 255), 14)
				resLbl.Position = UDim2.new(0, 10, 0, 10); resLbl.TextXAlignment = Enum.TextXAlignment.Left

				local reqLbl = UIHelpers.CreateLabel(fCard, "Recipe: " .. alpha .. " + " .. omega, UDim2.new(1, -20, 0, 15), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 11)
				reqLbl.Position = UDim2.new(0, 10, 0, 30); reqLbl.TextXAlignment = Enum.TextXAlignment.Left

				local tData = type(TitanData) == "table" and TitanData.Titans and TitanData.Titans[res]
				if tData and tData.Stats then
					local s = tData.Stats
					local statStr = string.format("POW: %s | SPD: %s | HRD: %s | END: %s | PRE: %s | POT: %s", s.Power, s.Speed, s.Hardening, s.Endurance, s.Precision, s.Potential)
					local statLbl = UIHelpers.CreateLabel(fCard, statStr, UDim2.new(1, -20, 0, 15), Enum.Font.GothamBold, UIHelpers.Colors.Gold, 10)
					statLbl.Position = UDim2.new(0, 10, 0, 50); statLbl.TextXAlignment = Enum.TextXAlignment.Left
				end

				local uniqueSkills = {}
				if hasSkillData and type(SkillData) == "table" then
					local sPool = SkillData.Skills or SkillData
					for sName, sData in pairs(sPool) do
						if sData.Requirement and sData.Requirement ~= "AnyTitan" and sData.Requirement ~= "Transformed" and sData.Requirement ~= "Enemy" and sData.Requirement ~= "None" then
							if string.find(res, sData.Requirement) then table.insert(uniqueSkills, sName) end
						end
					end
				end
				local skillsStr = #uniqueSkills > 0 and table.concat(uniqueSkills, ", ") or "Unknown Abilities"

				local skLbl = UIHelpers.CreateLabel(fCard, "Inherits: " .. skillsStr, UDim2.new(1, -20, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 10)
				skLbl.Position = UDim2.new(0, 10, 0, 70); skLbl.TextXAlignment = Enum.TextXAlignment.Left; skLbl.TextWrapped = true; skLbl.TextYAlignment = Enum.TextYAlignment.Top
			end
		end
	end

	local PopupOverlay = Instance.new("Frame", MainFrame)
	PopupOverlay.Size = UDim2.new(1, 0, 1, 0); PopupOverlay.BackgroundColor3 = Color3.new(0,0,0); PopupOverlay.BackgroundTransparency = 0.6; PopupOverlay.ZIndex = 50; PopupOverlay.Visible = false; PopupOverlay.Active = true
	local PopupPanel, _ = CreateGrimPanel(PopupOverlay)
	PopupPanel.Size = UDim2.new(0.9, 0, 0.8, 0); PopupPanel.Position = UDim2.new(0.5, 0, 0.5, 0); PopupPanel.AnchorPoint = Vector2.new(0.5, 0.5); PopupPanel.ZIndex = 51

	local popTitle = UIHelpers.CreateLabel(PopupPanel, "SELECT A TITAN", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16); popTitle.ZIndex = 52
	local closeBtn, _ = CreateSharpButton(PopupPanel, "X", UDim2.new(0, 30, 0, 30), Enum.Font.GothamBlack, 14); closeBtn.Position = UDim2.new(1, -10, 0, 5); closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeBtn.ZIndex = 52; closeBtn.MouseButton1Click:Connect(function() PopupOverlay.Visible = false end)

	local TitanScroll = Instance.new("ScrollingFrame", PopupPanel)
	TitanScroll.Size = UDim2.new(1, -20, 1, -60); TitanScroll.Position = UDim2.new(0, 10, 0, 50); TitanScroll.BackgroundTransparency = 1; TitanScroll.ScrollBarThickness = 6; TitanScroll.BorderSizePixel = 0; TitanScroll.ZIndex = 52
	local tsLayout = Instance.new("UIListLayout", TitanScroll); tsLayout.Padding = UDim.new(0, 10); tsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TitanScroll.CanvasSize = UDim2.new(0,0,0, tsLayout.AbsoluteContentSize.Y + 10) end)

	local noTitansLbl = UIHelpers.CreateLabel(PopupPanel, "No Titans found in Vault.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); noTitansLbl.Position = UDim2.new(0, 0, 0.5, 0); noTitansLbl.AnchorPoint = Vector2.new(0, 0.5); noTitansLbl.ZIndex = 52

	local selectedAlpha, selectedOmega, activeSlotIndex = nil, nil, 1

	local function UpdateFusionUI()
		local function updateSlot(slotData, titleLbl, addBtn, strk, defaultTitle)
			if slotData then
				local tName = slotData.Name; local tData = TitanData.Titans[tName]; local rarity = tData and tData.Rarity or "Common"; local rColor = CONFIG.RarityColors[rarity] or Color3.fromRGB(200,200,200)
				titleLbl.Text = string.upper(tName); titleLbl.TextColor3 = rColor; addBtn.Visible = false; strk.Color = rColor
			else
				titleLbl.Text = defaultTitle; titleLbl.TextColor3 = UIHelpers.Colors.TextMuted; addBtn.Visible = true; strk.Color = Color3.fromRGB(70, 70, 80)
			end
		end

		updateSlot(selectedAlpha, Slot1Title, Slot1AddBtn, Slot1:FindFirstChild("UIStroke"), "SUBJECT ALPHA")
		updateSlot(selectedOmega, Slot2Title, Slot2AddBtn, Slot2:FindFirstChild("UIStroke"), "SUBJECT OMEGA")

		if selectedAlpha and selectedOmega then
			l1.BackgroundColor3 = Color3.fromRGB(170, 85, 255); l2.BackgroundColor3 = Color3.fromRGB(170, 85, 255); ResultLbl.TextColor3 = Color3.fromRGB(170, 85, 255); ResultSlot:FindFirstChild("UIStroke").Color = Color3.fromRGB(170, 85, 255)
		else
			l1.BackgroundColor3 = Color3.fromRGB(50, 40, 60); l2.BackgroundColor3 = Color3.fromRGB(50, 40, 60); ResultLbl.TextColor3 = Color3.fromRGB(80, 70, 90); ResultSlot:FindFirstChild("UIStroke").Color = Color3.fromRGB(70, 70, 80)
		end
	end

	local function OpenTitanSelection(slotId)
		activeSlotIndex = slotId; PopupOverlay.Visible = true
		for _, c in ipairs(TitanScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

		local foundAny = false
		for i = 1, 6 do
			local tName = player:GetAttribute("Titan_Slot" .. i)
			if tName and tName ~= "" and tName ~= "None" then
				if (slotId == 1 and selectedOmega and selectedOmega.Slot == i) or (slotId == 2 and selectedAlpha and selectedAlpha.Slot == i) then continue end
				foundAny = true
				local rarityColor = Color3.fromRGB(200, 200, 200)
				if TitanData.Titans[tName] then rarityColor = CONFIG.RarityColors[TitanData.Titans[tName].Rarity] or rarityColor end

				local tBtn, tBtnStroke = CreateSharpButton(TitanScroll, "SLOT " .. i .. ": " .. string.upper(tName), UDim2.new(1, -10, 0, 45), Enum.Font.GothamBlack, 12); tBtn.ZIndex = 53; tBtn.TextColor3 = rarityColor; tBtnStroke.Color = rarityColor
				tBtn.MouseButton1Click:Connect(function() if activeSlotIndex == 1 then selectedAlpha = {Slot = i, Name = tName} else selectedOmega = {Slot = i, Name = tName} end; PopupOverlay.Visible = false; UpdateFusionUI() end)
			end
		end
		noTitansLbl.Visible = not foundAny
	end

	Slot1OverBtn.MouseButton1Click:Connect(function() OpenTitanSelection(1) end)
	Slot2OverBtn.MouseButton1Click:Connect(function() OpenTitanSelection(2) end)

	FuseBtn.MouseButton1Click:Connect(function()
		if not selectedAlpha or not selectedOmega then if NotificationManager then NotificationManager.Show("Requires two Subjects.", "Error") end return end
		Network:WaitForChild("FuseTitan"):FireServer(selectedAlpha.Slot, selectedOmega.Slot)
		selectedAlpha = nil; selectedOmega = nil; UpdateFusionUI()
	end)

	-- ==========================================
	-- 4. PLAYER TRADE
	-- ==========================================
	local TradeTab = activeSubFrames["TRADE"]

	local tTitle = UIHelpers.CreateLabel(TradeTab, "SECURE TRADING", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(85, 170, 255), 18)
	tTitle.Position = UDim2.new(0, 0, 0, 0)

	local tDesc = UIHelpers.CreateLabel(TradeTab, "Initiate a secure item exchange with another operative.", UDim2.new(1, -20, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
	tDesc.Position = UDim2.new(0, 10, 0, 30)

	local TradePanel, tpStroke = CreateGrimPanel(TradeTab)
	TradePanel.Size = UDim2.new(0.95, 0, 0, 120)
	TradePanel.Position = UDim2.new(0.5, 0, 0, 60)
	TradePanel.AnchorPoint = Vector2.new(0.5, 0)

	local pInput = Instance.new("TextBox", TradePanel)
	pInput.Size = UDim2.new(0.8, 0, 0, 35)
	pInput.Position = UDim2.new(0.5, 0, 0, 15)
	pInput.AnchorPoint = Vector2.new(0.5, 0)
	pInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	pInput.TextColor3 = UIHelpers.Colors.TextWhite
	pInput.Font = Enum.Font.GothamMedium
	pInput.TextSize = 14
	pInput.PlaceholderText = "Target Username..."
	pInput.Text = ""
	Instance.new("UIStroke", pInput).Color = UIHelpers.Colors.BorderMuted

	local SendBtn, sendStroke = CreateSharpButton(TradePanel, "SEND REQUEST", UDim2.new(0.8, 0, 0, 35), Enum.Font.GothamBlack, 14)
	SendBtn.Position = UDim2.new(0.5, 0, 0, 65)
	SendBtn.AnchorPoint = Vector2.new(0.5, 0)
	SendBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
	sendStroke.Color = Color3.fromRGB(85, 170, 255)

	SendBtn.MouseButton1Click:Connect(function()
		if pInput.Text ~= "" then
			Network:WaitForChild("TradeAction"):FireServer("SendRequest", pInput.Text)
			pInput.Text = ""
		end
	end)

	local incTitle = UIHelpers.CreateLabel(TradeTab, "INCOMING REQUESTS", UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)
	incTitle.Position = UDim2.new(0, 10, 0, 190); incTitle.TextXAlignment = Enum.TextXAlignment.Left

	local ReqScroll = Instance.new("ScrollingFrame", TradeTab)
	ReqScroll.Size = UDim2.new(1, -20, 1, -220)
	ReqScroll.Position = UDim2.new(0, 10, 0, 220)
	ReqScroll.BackgroundTransparency = 1
	ReqScroll.ScrollBarThickness = 4
	ReqScroll.BorderSizePixel = 0

	local reqLayout = Instance.new("UIListLayout", ReqScroll)
	reqLayout.Padding = UDim.new(0, 8)
	reqLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ReqScroll.CanvasSize = UDim2.new(0, 0, 0, reqLayout.AbsoluteContentSize.Y + 10)
	end)

	local PendingTrades = {}
	local function UpdateTradeRequests()
		for _, c in ipairs(ReqScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for reqName, _ in pairs(PendingTrades) do
			local rCard, _ = CreateGrimPanel(ReqScroll)
			rCard.Size = UDim2.new(1, 0, 0, 50)

			local nameLbl = UIHelpers.CreateLabel(rCard, reqName, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
			nameLbl.Position = UDim2.new(0, 10, 0, 0); nameLbl.TextXAlignment = Enum.TextXAlignment.Left

			local accBtn, accStrk = CreateSharpButton(rCard, "ACCEPT", UDim2.new(0, 70, 0, 30), Enum.Font.GothamBlack, 11)
			accBtn.Position = UDim2.new(1, -50, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5)
			accBtn.TextColor3 = Color3.fromRGB(85, 255, 85); accStrk.Color = Color3.fromRGB(85, 255, 85)

			local decBtn, decStrk = CreateSharpButton(rCard, "X", UDim2.new(0, 30, 0, 30), Enum.Font.GothamBlack, 14)
			decBtn.Position = UDim2.new(1, -10, 0.5, 0); decBtn.AnchorPoint = Vector2.new(1, 0.5)
			decBtn.TextColor3 = Color3.fromRGB(255, 85, 85); decStrk.Color = Color3.fromRGB(255, 85, 85)

			accBtn.MouseButton1Click:Connect(function() Network:WaitForChild("TradeAction"):FireServer("AcceptRequest", reqName) end)
			decBtn.MouseButton1Click:Connect(function() PendingTrades[reqName] = nil; UpdateTradeRequests(); Network:WaitForChild("TradeAction"):FireServer("DeclineRequest", reqName) end)
		end
	end

	Network:WaitForChild("TradeUpdate").OnClientEvent:Connect(function(action, data)
		if action == "IncomingRequest" then
			PendingTrades[data.Sender] = true
			UpdateTradeRequests()
		elseif action == "CancelRequest" then
			PendingTrades[data.Sender] = nil
			UpdateTradeRequests()
		end
	end)
end

return MobileSupplyForgeTab