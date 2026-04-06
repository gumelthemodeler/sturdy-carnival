-- @ScriptType: ModuleScript
-- Name: MobileSupplyForgeTab
-- @ScriptType: ModuleScript
local MobileSupplyForgeTab = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")

local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))
local NotificationManager = require(SharedUI:WaitForChild("NotificationManager"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData")) 
local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))

local player = Players.LocalPlayer

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

local function CreateSharpTouchButton(parent, text, size, font, textSize)
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

	btn.InputBegan:Connect(function() 
		if btn.Active then 
			stroke.Color = UIHelpers.Colors.Gold
			btn.TextColor3 = UIHelpers.Colors.Gold 
		end
	end)
	btn.InputEnded:Connect(function() 
		if btn.Active then 
			stroke.Color = Color3.fromRGB(70, 70, 80)
			btn.TextColor3 = Color3.fromRGB(245, 245, 245)
		end
	end)
	return btn, stroke
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

	local SubNav = Instance.new("Frame", MainFrame)
	SubNav.Size = UDim2.new(0.95, 0, 0, 35)
	SubNav.BackgroundTransparency = 1
	SubNav.LayoutOrder = 1

	local navLayout = Instance.new("UIListLayout", SubNav)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 10)

	local ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(0.95, 0, 1, -55)
	ContentArea.BackgroundTransparency = 1
	ContentArea.LayoutOrder = 2

	local subTabs = { "MARKETPLACE", "THE FORGE", "TITAN FUSION" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpTouchButton(SubNav, tabName, UDim2.new(0, 140, 0, 25), Enum.Font.GothamBold, 11)
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

	subBtns["MARKETPLACE"].Btn.TextColor3 = UIHelpers.Colors.Gold
	subBtns["MARKETPLACE"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- 1. MARKETPLACE
	-- ==========================================
	local MarketTab = activeSubFrames["MARKETPLACE"]

	local marketTitle = UIHelpers.CreateLabel(MarketTab, "MARKETPLACE & SUPPLY", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)
	marketTitle.Position = UDim2.new(0, 0, 0, 0)

	local SplitContainer = Instance.new("Frame", MarketTab)
	SplitContainer.Size = UDim2.new(1, 0, 1, -30)
	SplitContainer.Position = UDim2.new(0, 0, 0, 30)
	SplitContainer.BackgroundTransparency = 1

	local scLayout = Instance.new("UIListLayout", SplitContainer)
	scLayout.FillDirection = Enum.FillDirection.Horizontal
	scLayout.Padding = UDim.new(0, 15)

	local LeftPanel = Instance.new("Frame", SplitContainer)
	LeftPanel.Size = UDim2.new(0.48, 0, 1, 0)
	LeftPanel.BackgroundTransparency = 1

	local PremContainer = Instance.new("Frame", LeftPanel)
	PremContainer.Size = UDim2.new(1, 0, 0.65, 0)
	CreateGrimPanel(PremContainer)

	local pTitle = UIHelpers.CreateLabel(PremContainer, "PREMIUM STORE", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)

	local PremScroll = Instance.new("ScrollingFrame", PremContainer)
	PremScroll.Size = UDim2.new(1, -20, 1, -35)
	PremScroll.Position = UDim2.new(0, 10, 0, 25)
	PremScroll.BackgroundTransparency = 1
	PremScroll.ScrollBarThickness = 4
	PremScroll.BorderSizePixel = 0

	local pslayout = Instance.new("UIListLayout", PremScroll)
	pslayout.Padding = UDim.new(0, 10)
	pslayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PremScroll.CanvasSize = UDim2.new(0,0,0, pslayout.AbsoluteContentSize.Y + 10) end)

	local function CreatePremiumCard(titleText, descText, buyAction, giftAction)
		local pCard = Instance.new("Frame", PremScroll)
		pCard.Size = UDim2.new(1, -10, 0, 80)
		pCard.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		local pStroke = Instance.new("UIStroke", pCard)
		pStroke.Color = Color3.fromRGB(80, 50, 100)
		pStroke.Thickness = 2

		local pName = UIHelpers.CreateLabel(pCard, string.upper(titleText), UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12)
		pName.Position = UDim2.new(0, 10, 0, 5); pName.TextXAlignment = Enum.TextXAlignment.Left

		local pDesc = UIHelpers.CreateLabel(pCard, descText or "A premium item.", UDim2.new(1, -20, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 10)
		pDesc.Position = UDim2.new(0, 10, 0, 25); pDesc.TextXAlignment = Enum.TextXAlignment.Left

		local btnContainer = Instance.new("Frame", pCard)
		btnContainer.Size = UDim2.new(1, -20, 0, 25)
		btnContainer.Position = UDim2.new(0, 10, 1, -30)
		btnContainer.BackgroundTransparency = 1
		local bcLayout = Instance.new("UIListLayout", btnContainer); bcLayout.FillDirection = Enum.FillDirection.Horizontal; bcLayout.Padding = UDim.new(0, 10)

		if giftAction then
			local buyBtn, buyStroke = CreateSharpTouchButton(btnContainer, "BUY", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 11)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)

			local giftBtn, giftStroke = CreateSharpTouchButton(btnContainer, "GIFT", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 11)
			giftBtn.TextColor3 = Color3.fromRGB(200, 100, 255); giftStroke.Color = Color3.fromRGB(200, 100, 255); giftBtn.MouseButton1Click:Connect(giftAction)
		else
			local buyBtn, buyStroke = CreateSharpTouchButton(btnContainer, "BUY", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 11)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)
		end
	end

	if ItemData.Gamepasses then for _, gp in ipairs(ItemData.Gamepasses) do CreatePremiumCard(gp.Name, gp.Desc, function() MarketplaceService:PromptGamePassPurchase(player, gp.ID) end, gp.GiftID and function() MarketplaceService:PromptProductPurchase(player, gp.GiftID) end or nil) end end
	if ItemData.Products then for _, prod in ipairs(ItemData.Products) do if not prod.IsReroll and not string.find(prod.Name, "Gift:") then CreatePremiumCard(prod.Name, prod.Desc, function() MarketplaceService:PromptProductPurchase(player, prod.ID) end, nil) end end end

	local CodeContainer = Instance.new("Frame", LeftPanel)
	CodeContainer.Size = UDim2.new(1, 0, 0.3, 0)
	CodeContainer.Position = UDim2.new(0, 0, 0.7, 0)
	CreateGrimPanel(CodeContainer)

	local cInput = Instance.new("TextBox", CodeContainer)
	cInput.Size = UDim2.new(0.8, 0, 0, 30)
	cInput.Position = UDim2.new(0.5, 0, 0.35, 0)
	cInput.AnchorPoint = Vector2.new(0.5, 0.5)
	cInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	cInput.TextColor3 = UIHelpers.Colors.Gold
	cInput.Font = Enum.Font.GothamBlack
	cInput.TextSize = 12
	cInput.PlaceholderText = "Redeem Code Here"
	cInput.Text = ""
	Instance.new("UIStroke", cInput).Color = UIHelpers.Colors.BorderMuted

	local RedeemBtn, redeemStroke = CreateSharpTouchButton(CodeContainer, "REDEEM", UDim2.new(0.8, 0, 0, 30), Enum.Font.GothamBlack, 14)
	RedeemBtn.Position = UDim2.new(0.5, 0, 0.75, 0)
	RedeemBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	RedeemBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
	redeemStroke.Color = Color3.fromRGB(85, 170, 255)

	local cHint = UIHelpers.CreateLabel(CodeContainer, "ENTER PROMO CODE:", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 11)
	cHint.Position = UDim2.new(0, 0, 0, 5)

	RedeemBtn.MouseButton1Click:Connect(function()
		if cInput.Text ~= "" then Network:WaitForChild("RedeemCode"):FireServer(cInput.Text); cInput.Text = "" end
	end)

	local RightPanel = Instance.new("Frame", SplitContainer)
	RightPanel.Size = UDim2.new(0.5, 0, 1, 0)
	RightPanel.BackgroundTransparency = 1

	local rrContainer = Instance.new("Frame", RightPanel)
	rrContainer.Size = UDim2.new(1, 0, 0, 35)
	rrContainer.BackgroundTransparency = 1
	local rrLayout = Instance.new("UIListLayout", rrContainer); rrLayout.FillDirection = Enum.FillDirection.Horizontal; rrLayout.Padding = UDim.new(0, 10)

	local rrDews, rrDewsStroke = CreateSharpTouchButton(rrContainer, "RESTOCK (300K Dews)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 10)
	rrDews.TextColor3 = Color3.fromRGB(85, 170, 255); rrDewsStroke.Color = Color3.fromRGB(85, 170, 255)

	local rrPremium, rrPremStroke = CreateSharpTouchButton(rrContainer, "RESTOCK (50 R$)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 10)

	local isFreeRestock = false
	local function UpdateRerollButton()
		local hasVIP = player:GetAttribute("HasVIP"); local lastRoll = player:GetAttribute("LastFreeReroll") or 0
		if hasVIP and (os.time() - lastRoll) >= 86400 then
			rrPremium.Text = "FREE RESTOCK (VIP)"; rrPremium.TextColor3 = Color3.fromRGB(200, 100, 255); rrPremStroke.Color = Color3.fromRGB(200, 100, 255); isFreeRestock = true
		else
			rrPremium.Text = "RESTOCK (50 R$)"; rrPremium.TextColor3 = Color3.fromRGB(85, 255, 85); rrPremStroke.Color = Color3.fromRGB(85, 255, 85); isFreeRestock = false
		end
	end
	UpdateRerollButton()

	rrDews.MouseButton1Click:Connect(function() Network:WaitForChild("VIPFreeReroll"):FireServer(true) end)
	rrPremium.MouseButton1Click:Connect(function()
		if isFreeRestock then Network:WaitForChild("VIPFreeReroll"):FireServer(false)
		else
			local rerollId = nil; if ItemData.Products then for _, prod in ipairs(ItemData.Products) do if prod.IsReroll then rerollId = prod.ID break end end end
			if rerollId then MarketplaceService:PromptProductPurchase(player, rerollId) end
		end
	end)

	local restockTimer = UIHelpers.CreateLabel(RightPanel, "RESTOCKS IN: 00:00", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 150, 100), 12)
	restockTimer.Position = UDim2.new(0, 0, 0, 40)

	local SupplyScroll = Instance.new("ScrollingFrame", RightPanel)
	SupplyScroll.Size = UDim2.new(1, 0, 1, -65)
	SupplyScroll.Position = UDim2.new(0, 0, 0, 65)
	SupplyScroll.BackgroundTransparency = 1
	SupplyScroll.ScrollBarThickness = 6
	SupplyScroll.BorderSizePixel = 0

	local ssLayout = Instance.new("UIListLayout", SupplyScroll)
	ssLayout.Padding = UDim.new(0, 8)
	ssLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SupplyScroll.CanvasSize = UDim2.new(0,0,0, ssLayout.AbsoluteContentSize.Y + 10) end)

	local function AddSupplyItem(itemName, itemData, cost, isSoldOut)
		local rarityColor = CONFIG.RarityColors[itemData.Rarity or "Common"] or Color3.fromRGB(200, 200, 200)

		local c, cStroke = CreateGrimPanel(SupplyScroll)
		c.Size = UDim2.new(1, -10, 0, 65)
		cStroke.Color = rarityColor

		local bgGlow = Instance.new("Frame", c)
		bgGlow.Size = UDim2.new(1, 0, 1, 0); bgGlow.BackgroundColor3 = rarityColor; bgGlow.BorderSizePixel = 0; bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow); grad.Rotation = 90; grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.7) }

		local nameLbl = UIHelpers.CreateLabel(c, itemName, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBlack, rarityColor, 14)
		nameLbl.Position = UDim2.new(0, 10, 0, 5); nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 2

		local statsTxt = ""
		if itemData.Bonus then
			for k, v in pairs(itemData.Bonus) do local s = tostring(k):sub(1,3):upper(); statsTxt = statsTxt .. (v > 0 and "+" or "") .. v .. " " .. s .. " | " end
			statsTxt = statsTxt:sub(1, -3)
		else statsTxt = itemData.Desc or "A useful item." end

		local statsLbl = UIHelpers.CreateLabel(c, statsTxt, UDim2.new(0.6, 0, 0, 15), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 10)
		statsLbl.Position = UDim2.new(0, 10, 0, 25); statsLbl.TextXAlignment = Enum.TextXAlignment.Left; statsLbl.ZIndex = 2

		local costLbl = UIHelpers.CreateLabel(c, "Cost: " .. tostring(cost) .. " Dews", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 10)
		costLbl.Position = UDim2.new(0, 10, 1, -20); costLbl.TextXAlignment = Enum.TextXAlignment.Left; costLbl.ZIndex = 2

		local actionText = isSoldOut and "SOLD" or "BUY"
		local buyBtn, buyStroke = CreateSharpTouchButton(c, actionText, UDim2.new(0, 80, 0, 30), Enum.Font.GothamBlack, 11)
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
	player.AttributeChanged:Connect(function(attr) if attr == "ShopPurchases_Data" or attr == "PersonalShopSeed" then RefreshShop() end; if attr == "LastFreeReroll" or attr == "HasVIP" then UpdateRerollButton() end end)
	RefreshShop()

	-- ==========================================
	-- 2. THE FORGE 
	-- ==========================================
	local ForgeTab = activeSubFrames["THE FORGE"]
	local selectedRecipeName = nil 

	local RecipeList = Instance.new("ScrollingFrame", ForgeTab)
	RecipeList.Size = UDim2.new(0.35, 0, 1, 0)
	RecipeList.BackgroundTransparency = 1
	RecipeList.ScrollBarThickness = 4
	RecipeList.BorderSizePixel = 0
	local rlLayout = Instance.new("UIListLayout", RecipeList); rlLayout.Padding = UDim.new(0, 10)
	rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RecipeList.CanvasSize = UDim2.new(0, 0, 0, rlLayout.AbsoluteContentSize.Y + 20) end)

	local BlueprintPanel = Instance.new("Frame", ForgeTab)
	BlueprintPanel.Size = UDim2.new(0.62, 0, 1, 0)
	BlueprintPanel.Position = UDim2.new(1, 0, 0, 0)
	BlueprintPanel.AnchorPoint = Vector2.new(1, 0)
	CreateGrimPanel(BlueprintPanel)

	local InfoView = Instance.new("Frame", BlueprintPanel)
	InfoView.Size = UDim2.new(1, 0, 1, 0)
	InfoView.BackgroundTransparency = 1

	local bpTitle = UIHelpers.CreateLabel(InfoView, "SELECT A BLUEPRINT", UDim2.new(1, -40, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18)
	bpTitle.Position = UDim2.new(0, 20, 0, 10); bpTitle.TextXAlignment = Enum.TextXAlignment.Left

	local bpDesc = UIHelpers.CreateLabel(InfoView, "Select an item to view its crafting requirements.", UDim2.new(1, -40, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
	bpDesc.Position = UDim2.new(0, 20, 0, 45); bpDesc.TextXAlignment = Enum.TextXAlignment.Left; bpDesc.TextWrapped = true; bpDesc.TextYAlignment = Enum.TextYAlignment.Top

	local ReqTitle = UIHelpers.CreateLabel(InfoView, "REQUIRED MATERIALS", UDim2.new(1, -40, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
	ReqTitle.Position = UDim2.new(0, 20, 0, 85); ReqTitle.TextXAlignment = Enum.TextXAlignment.Left; ReqTitle.Visible = false

	local ReqList = Instance.new("ScrollingFrame", InfoView)
	ReqList.Size = UDim2.new(1, -40, 0, 80)
	ReqList.Position = UDim2.new(0, 20, 0, 110)
	ReqList.BackgroundTransparency = 1
	ReqList.ScrollBarThickness = 4
	ReqList.BorderSizePixel = 0
	local reqLayout = Instance.new("UIListLayout", ReqList); reqLayout.Padding = UDim.new(0, 6)
	reqLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ReqList.CanvasSize = UDim2.new(0, 0, 0, reqLayout.AbsoluteContentSize.Y + 10) end)

	local CraftBtn, CraftStroke = CreateSharpTouchButton(InfoView, "FORGE EQUIPMENT", UDim2.new(0.8, 0, 0, 40), Enum.Font.GothamBlack, 14)
	CraftBtn.Position = UDim2.new(0.5, 0, 1, -15); CraftBtn.AnchorPoint = Vector2.new(0.5, 1); CraftBtn.Visible = false

	local MinigameView = Instance.new("Frame", BlueprintPanel)
	MinigameView.Size = UDim2.new(1, 0, 1, 0)
	MinigameView.BackgroundTransparency = 1
	MinigameView.Visible = false

	local mgTitle = UIHelpers.CreateLabel(MinigameView, "ACTIVE FORGE", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 100, 100), 20)
	mgTitle.Position = UDim2.new(0, 0, 0, 20)

	local mgInst = UIHelpers.CreateLabel(MinigameView, "Strike when the heat aligns perfectly. (0/3)", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12)
	mgInst.Position = UDim2.new(0, 0, 0, 50)

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

	local StrikeBtn, StrikeStroke = CreateSharpTouchButton(MinigameView, "STRIKE", UDim2.new(0.5, 0, 0, 50), Enum.Font.GothamBlack, 20)
	StrikeBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
	StrikeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	StrikeBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
	StrikeStroke.Color = Color3.fromRGB(255, 85, 85)

	local mgActive = false; local mgConn = nil; local strikes = 0; local totalAccuracy = 0; local currentTargetCenter = 0.5

	local function ResetSweetSpot()
		local w = 0.25; local p = math.random(10, 65) / 100 
		SweetSpot.Position = UDim2.new(p, 0, 0, 0)
		currentTargetCenter = p + (w / 2)
		SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
	end

	local function EndMinigame()
		mgActive = false
		if mgConn then mgConn:Disconnect() mgConn = nil end
		local finalQuality = "Standard"; local avg = totalAccuracy / 3
		if avg >= 0.80 then finalQuality = "Flawless" elseif avg >= 0.40 then finalQuality = "Masterwork" end
		mgInst.Text = "Forge Complete! Quality: <font color='#FFD700'>" .. string.upper(finalQuality) .. "</font>"
		task.wait(1.5)
		MinigameView.Visible = false
		InfoView.Visible = true
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
		if not CraftBtn.Active then return end
		if not selectedRecipeName then return end

		-- [[ THE FIX: Check materials and abort securely! ]]
		local recipe = ItemData.ForgeRecipes[selectedRecipeName]; if not recipe then return end

		local dews = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Dews") and player.leaderstats.Dews.Value or 0
		if dews < recipe.DewCost then NotificationManager.Show("Not enough Dews to forge this!", "Error") return end

		local hasMats = true
		for req, amt in pairs(recipe.ReqItems) do
			local count = player:GetAttribute(req:gsub("[^%w]", "") .. "Count") or 0
			if count < amt then hasMats = false; break end
		end
		if not hasMats then NotificationManager.Show("Missing required materials!", "Error") return end

		InfoView.Visible = false; MinigameView.Visible = true; strikes = 0; totalAccuracy = 0; mgInst.Text = "Strike when the heat aligns perfectly. (0/3)"; ResetSweetSpot(); mgActive = true
		local t = 0; if mgConn then mgConn:Disconnect() end
		mgConn = RunService.RenderStepped:Connect(function(dt)
			if mgActive then local speed = 1.8 + (strikes * 0.6); t += dt * speed; Cursor.Position = UDim2.new((math.sin(t) + 1) / 2, 0, 0.5, 0) end
		end)
	end)

	for rec, recipeData in pairs(ItemData.ForgeRecipes or {}) do
		local resItem = recipeData.Result
		local resData = ItemData.Equipment[resItem] or ItemData.Consumables[resItem]
		local rarity = resData and resData.Rarity or "Common"
		local rColor = CONFIG.RarityColors[rarity] or Color3.fromRGB(200,200,200)

		local rBtn = Instance.new("TextButton", RecipeList)
		rBtn.Size = UDim2.new(1, -10, 0, 50)
		rBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		rBtn.BorderSizePixel = 0
		rBtn.AutoButtonColor = false
		rBtn.Text = ""

		local rStrk = Instance.new("UIStroke", rBtn)
		rStrk.Color = rColor
		rStrk.Thickness = 2
		rStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local rTitleLbl = UIHelpers.CreateLabel(rBtn, string.upper(rec), UDim2.new(1, -15, 0, 20), Enum.Font.GothamBlack, rColor, 12)
		rTitleLbl.Position = UDim2.new(0, 10, 0, 5)
		rTitleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local rTagLbl = UIHelpers.CreateLabel(rBtn, "[" .. string.upper(rarity) .. "]", UDim2.new(1, -15, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 200, 200), 10)
		rTagLbl.Position = UDim2.new(0, 10, 1, -22)
		rTagLbl.TextXAlignment = Enum.TextXAlignment.Left

		rBtn.MouseEnter:Connect(function() rTitleLbl.TextColor3 = UIHelpers.Colors.Gold; rTagLbl.TextColor3 = UIHelpers.Colors.Gold; rStrk.Color = UIHelpers.Colors.Gold end)
		rBtn.MouseLeave:Connect(function() rTitleLbl.TextColor3 = rColor; rTagLbl.TextColor3 = Color3.fromRGB(200, 200, 200); rStrk.Color = rColor end)

		rBtn.MouseButton1Click:Connect(function()
			selectedRecipeName = rec 
			bpTitle.Text = string.upper(rec)
			bpTitle.TextColor3 = rColor
			bpDesc.Text = "<font color='" .. ColorToHex(rColor) .. "'>[" .. rarity:upper() .. "]</font> " .. (resData and resData.Desc or "A high-tier piece of equipment forged from rare materials.")
			bpDesc.RichText = true
			ReqTitle.Visible = true
			CraftBtn.Visible = true

			for _, c in ipairs(ReqList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			local function MakeReq(matName, amt, hasAmt)
				local rf, rs = CreateGrimPanel(ReqList)
				rf.Size = UDim2.new(1, 0, 0, 25)
				rs.Color = hasAmt and UIHelpers.Colors.BorderMuted or Color3.fromRGB(150, 40, 40)
				rf.ZIndex = 103
				local l = UIHelpers.CreateLabel(rf, amt .. "x " .. matName, UDim2.new(1, -30, 1, 0), Enum.Font.GothamBold, hasAmt and UIHelpers.Colors.TextWhite or Color3.fromRGB(255, 100, 100), 11)
				l.Position = UDim2.new(0, 15, 0, 0)
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.ZIndex = 104
			end

			local hasAllMats = true
			if ItemData.ForgeRecipes[rec] then
				for mat, amt in pairs(ItemData.ForgeRecipes[rec].ReqItems) do 
					local count = tonumber(player:GetAttribute(mat:gsub("[^%w]", "") .. "Count")) or 0
					local hasEnough = count >= amt
					if not hasEnough then hasAllMats = false end
					MakeReq(mat, amt, hasEnough) 
				end
				local dCount = tonumber(player:GetAttribute("Dews")) or 0
				local hasDews = dCount >= ItemData.ForgeRecipes[rec].DewCost
				if not hasDews then hasAllMats = false end
				MakeReq("Dews", ItemData.ForgeRecipes[rec].DewCost, hasDews)
			end

			if hasAllMats then
				CraftBtn.Active = true
				CraftBtn.Text = "START FORGE MINIGAME"
				CraftBtn.TextColor3 = rColor
				CraftStroke.Color = rColor
			else
				CraftBtn.Active = false
				CraftBtn.Text = "INSUFFICIENT MATERIALS"
				CraftBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
				CraftStroke.Color = Color3.fromRGB(50, 50, 60)
			end
		end)
	end
end

return MobileSupplyForgeTab