-- @ScriptType: ModuleScript
-- Name: MobileSupplyForgeTab
-- @ScriptType: ModuleScript
local MobileSupplyForgeTab = {}
local Players = game:GetService("Players"); local RunService = game:GetService("RunService"); local TweenService = game:GetService("TweenService"); local ReplicatedStorage = game:GetService("ReplicatedStorage"); local MarketplaceService = game:GetService("MarketplaceService"); local Network = ReplicatedStorage:WaitForChild("Network")
local player = Players.LocalPlayer; local SharedUI = player:WaitForChild("PlayerScripts"):WaitForChild("SharedUI"); local UIHelpers = require(SharedUI:WaitForChild("UIHelpers")); local NotificationManager = require(SharedUI:WaitForChild("NotificationManager")); local ItemData = require(ReplicatedStorage:WaitForChild("ItemData")); local TitanData = require(ReplicatedStorage:WaitForChild("TitanData")); local VFXManager = require(player.PlayerScripts:WaitForChild("VFXManager"))

local CONFIG = { RarityColors = { Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(85, 255, 85), Rare = Color3.fromRGB(85, 85, 255), Epic = Color3.fromRGB(170, 85, 255), Legendary = Color3.fromRGB(255, 215, 0), Mythical = Color3.fromRGB(255, 85, 85), Transcendent = Color3.fromRGB(255, 85, 255) } }

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent); btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.InputBegan:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.InputEnded:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22); frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

function MobileSupplyForgeTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainFrame = Instance.new("Frame", parentFrame); MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1
	local mLayout = Instance.new("UIListLayout", MainFrame); mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 10); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", MainFrame).PaddingTop = UDim.new(0, 10)

	local SubNavScroll = Instance.new("ScrollingFrame", MainFrame); SubNavScroll.Size = UDim2.new(0.95, 0, 0, 50); SubNavScroll.BackgroundTransparency = 1; SubNavScroll.ScrollBarThickness = 0; SubNavScroll.ScrollingDirection = Enum.ScrollingDirection.X; SubNavScroll.LayoutOrder = 1
	local navLayout = Instance.new("UIListLayout", SubNavScroll); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 15)

	local ContentArea = Instance.new("Frame", MainFrame); ContentArea.Size = UDim2.new(0.95, 0, 1, -70); ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 2

	local subTabs = { "MARKETPLACE", "THE FORGE" }; local activeSubFrames = {}; local subBtns = {}
	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNavScroll, tabName, UDim2.new(0, 160, 0, 40), Enum.Font.GothamBlack, 14)
		btn.TextColor3 = UIHelpers.Colors.TextMuted; stroke.Color = UIHelpers.Colors.BorderMuted
		local subFrame = Instance.new("Frame", ContentArea); subFrame.Name = tabName; subFrame.Size = UDim2.new(1, 0, 1, 0); subFrame.BackgroundTransparency = 1; subFrame.Visible = (i == 1)
		activeSubFrames[tabName] = subFrame; subBtns[tabName] = {Btn = btn, Stroke = stroke}

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabName) end
			for name, bData in pairs(subBtns) do bData.Btn.TextColor3 = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted; bData.Stroke.Color = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted end
		end)
	end
	SubNavScroll.CanvasSize = UDim2.new(0, (#subTabs * 160) + (#subTabs * 15), 0, 0)
	subBtns["MARKETPLACE"].Btn.TextColor3 = UIHelpers.Colors.Gold; subBtns["MARKETPLACE"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- MARKETPLACE
	-- ==========================================
	local MarketTab = activeSubFrames["MARKETPLACE"]
	local MarketScroll = Instance.new("ScrollingFrame", MarketTab); MarketScroll.Size = UDim2.new(1, 0, 1, 0); MarketScroll.BackgroundTransparency = 1; MarketScroll.ScrollBarThickness = 8; MarketScroll.BorderSizePixel = 0; MarketScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local msLayout = Instance.new("UIListLayout", MarketScroll); msLayout.Padding = UDim.new(0, 20); msLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; msLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- [[ THE FIX: Correctly ordered from top to bottom! ]]
	local pTitle = UIHelpers.CreateLabel(MarketScroll, "PREMIUM STORE", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16); pTitle.TextXAlignment = Enum.TextXAlignment.Left; pTitle.LayoutOrder = 1

	local PremScroll = Instance.new("ScrollingFrame", MarketScroll); PremScroll.Size = UDim2.new(1, 0, 0, 100); PremScroll.BackgroundTransparency = 1; PremScroll.ScrollBarThickness = 0; PremScroll.ScrollingDirection = Enum.ScrollingDirection.X; PremScroll.LayoutOrder = 2; PremScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	local pslayout = Instance.new("UIListLayout", PremScroll); pslayout.FillDirection = Enum.FillDirection.Horizontal; pslayout.Padding = UDim.new(0, 15)

	local function CreatePremiumCard(titleText, descText, buyAction, giftAction)
		local pCard, pStroke = CreateGrimPanel(PremScroll); pCard.Size = UDim2.new(0, 220, 1, -10); pCard.BackgroundColor3 = Color3.fromRGB(22, 22, 26); pStroke.Color = Color3.fromRGB(80, 50, 100)
		local pName = UIHelpers.CreateLabel(pCard, string.upper(titleText), UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14); pName.Position = UDim2.new(0, 10, 0, 10); pName.TextXAlignment = Enum.TextXAlignment.Left
		local pDesc = UIHelpers.CreateLabel(pCard, descText or "A premium item.", UDim2.new(1, -20, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11); pDesc.Position = UDim2.new(0, 10, 0, 30); pDesc.TextXAlignment = Enum.TextXAlignment.Left; pDesc.TextWrapped = true; pDesc.TextYAlignment = Enum.TextYAlignment.Top

		local btnContainer = Instance.new("Frame", pCard); btnContainer.Size = UDim2.new(1, -20, 0, 35); btnContainer.Position = UDim2.new(0, 10, 1, -45); btnContainer.BackgroundTransparency = 1
		local bcLayout = Instance.new("UIListLayout", btnContainer); bcLayout.FillDirection = Enum.FillDirection.Horizontal; bcLayout.Padding = UDim.new(0, 10)

		if giftAction then
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(0.45, 0, 1, 0), Enum.Font.GothamBlack, 12); buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)
			local giftBtn, giftStroke = CreateSharpButton(btnContainer, "GIFT", UDim2.new(0.45, 0, 1, 0), Enum.Font.GothamBlack, 12); giftBtn.TextColor3 = Color3.fromRGB(200, 100, 255); giftStroke.Color = Color3.fromRGB(200, 100, 255); giftBtn.MouseButton1Click:Connect(giftAction)
		else
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 12); buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(buyAction)
		end
	end

	if ItemData.Gamepasses then for _, gp in ipairs(ItemData.Gamepasses) do CreatePremiumCard(gp.Name, gp.Desc, function() MarketplaceService:PromptGamePassPurchase(player, gp.ID) end, gp.GiftID and function() MarketplaceService:PromptProductPurchase(player, gp.GiftID) end or nil) end end
	if ItemData.Products then for _, prod in ipairs(ItemData.Products) do if not prod.IsReroll and not string.find(prod.Name, "Gift:") then CreatePremiumCard(prod.Name, prod.Desc, function() MarketplaceService:PromptProductPurchase(player, prod.ID) end, nil) end end end

	local sTitle = UIHelpers.CreateLabel(MarketScroll, "DAILY SUPPLY", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16); sTitle.TextXAlignment = Enum.TextXAlignment.Left; sTitle.LayoutOrder = 3
	local restockTimer = UIHelpers.CreateLabel(MarketScroll, "RESTOCKS IN: 00:00", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 150, 100), 12); restockTimer.TextXAlignment = Enum.TextXAlignment.Center; restockTimer.LayoutOrder = 4

	local restockContainer = Instance.new("Frame", MarketScroll); restockContainer.Size = UDim2.new(1, 0, 0, 45); restockContainer.BackgroundTransparency = 1; restockContainer.LayoutOrder = 5
	local rcLayout = Instance.new("UIListLayout", restockContainer); rcLayout.FillDirection = Enum.FillDirection.Horizontal; rcLayout.Padding = UDim.new(0, 15)
	local rrDews, rrDewsStroke = CreateSharpButton(restockContainer, "RESTOCK (300K)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12); rrDews.TextColor3 = Color3.fromRGB(85, 170, 255); rrDewsStroke.Color = Color3.fromRGB(85, 170, 255)
	local rrPremium, rrPremStroke = CreateSharpButton(restockContainer, "RESTOCK (50 R$)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)

	local SupplyList = Instance.new("Frame", MarketScroll); SupplyList.Size = UDim2.new(1, 0, 0, 0); SupplyList.AutomaticSize = Enum.AutomaticSize.Y; SupplyList.BackgroundTransparency = 1; SupplyList.LayoutOrder = 6
	local slLayout = Instance.new("UIListLayout", SupplyList); slLayout.Padding = UDim.new(0, 10)

	local CodeContainer, _ = CreateGrimPanel(MarketScroll); CodeContainer.Size = UDim2.new(1, 0, 0, 70); CodeContainer.LayoutOrder = 7
	local cInput = Instance.new("TextBox", CodeContainer); cInput.Size = UDim2.new(0.65, 0, 0, 45); cInput.Position = UDim2.new(0, 15, 0.5, 0); cInput.AnchorPoint = Vector2.new(0, 0.5); cInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18); cInput.TextColor3 = UIHelpers.Colors.Gold; cInput.Font = Enum.Font.GothamBlack; cInput.TextSize = 14; cInput.PlaceholderText = "Enter Promo Code..."; cInput.Text = ""; Instance.new("UIStroke", cInput).Color = UIHelpers.Colors.BorderMuted
	local RedeemBtn, redeemStroke = CreateSharpButton(CodeContainer, "REDEEM", UDim2.new(0.25, 0, 0, 45), Enum.Font.GothamBlack, 12); RedeemBtn.Position = UDim2.new(1, -15, 0.5, 0); RedeemBtn.AnchorPoint = Vector2.new(1, 0.5); RedeemBtn.TextColor3 = Color3.fromRGB(85, 170, 255); redeemStroke.Color = Color3.fromRGB(85, 170, 255)
	RedeemBtn.MouseButton1Click:Connect(function() if cInput.Text ~= "" then Network:WaitForChild("RedeemCode"):FireServer(cInput.Text); cInput.Text = "" end end)

	local isFreeRestock = false
	local function UpdateRerollButton()
		local hasVIP = player:GetAttribute("HasVIP"); local lastRoll = player:GetAttribute("LastFreeReroll") or 0
		if hasVIP and (os.time() - lastRoll) >= 86400 then rrPremium.Text = "FREE RESTOCK"; rrPremium.TextColor3 = Color3.fromRGB(200, 100, 255); rrPremStroke.Color = Color3.fromRGB(200, 100, 255); isFreeRestock = true
		else rrPremium.Text = "RESTOCK (50 R$)"; rrPremium.TextColor3 = Color3.fromRGB(85, 255, 85); rrPremStroke.Color = Color3.fromRGB(85, 255, 85); isFreeRestock = false end
	end
	UpdateRerollButton()

	rrDews.MouseButton1Click:Connect(function() Network:WaitForChild("VIPFreeReroll"):FireServer(true) end)
	rrPremium.MouseButton1Click:Connect(function()
		if isFreeRestock then Network:WaitForChild("VIPFreeReroll"):FireServer(false) else
			local rerollId = nil; if ItemData.Products then for _, prod in ipairs(ItemData.Products) do if prod.IsReroll then rerollId = prod.ID break end end end
			if rerollId then MarketplaceService:PromptProductPurchase(player, rerollId) end
		end
	end)

	local function AddSupplyItem(itemName, itemData, cost, isSoldOut)
		local rarityColor = CONFIG.RarityColors[itemData.Rarity or "Common"] or Color3.fromRGB(200, 200, 200)
		local c, cStroke = CreateGrimPanel(SupplyList); c.Size = UDim2.new(1, -10, 0, 70); cStroke.Color = rarityColor
		local nameLbl = UIHelpers.CreateLabel(c, itemName, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBlack, rarityColor, 16); nameLbl.Position = UDim2.new(0, 15, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		local statsTxt = itemData.Desc or "A useful item."
		local statsLbl = UIHelpers.CreateLabel(c, statsTxt, UDim2.new(0.6, 0, 0, 15), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12); statsLbl.Position = UDim2.new(0, 15, 0, 30); statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		local costLbl = UIHelpers.CreateLabel(c, "Cost: " .. tostring(cost) .. " Dews", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 11); costLbl.Position = UDim2.new(0, 15, 1, -25); costLbl.TextXAlignment = Enum.TextXAlignment.Left
		local actionText = isSoldOut and "SOLD" or "BUY"
		local buyBtn, buyStroke = CreateSharpButton(c, actionText, UDim2.new(0, 100, 0, 34), Enum.Font.GothamBlack, 12); buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5)

		if isSoldOut then buyBtn.TextColor3 = Color3.fromRGB(100, 100, 100); buyStroke.Color = Color3.fromRGB(70, 70, 80); buyBtn.Active = false
		else buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85); buyBtn.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("BuyItem", itemName) end) end
	end

	local isShopTimerActive = false
	local function RefreshShop()
		local shopData = Network:WaitForChild("GetShopData"):InvokeServer()
		if not shopData or not shopData.Items then return end
		for _, c in ipairs(SupplyList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
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
	-- THE FORGE 
	-- ==========================================
	local ForgeTab = activeSubFrames["THE FORGE"]
	local RecipeScroll = Instance.new("ScrollingFrame", ForgeTab); RecipeScroll.Size = UDim2.new(1, 0, 1, 0); RecipeScroll.BackgroundTransparency = 1; RecipeScroll.ScrollBarThickness = 8; RecipeScroll.BorderSizePixel = 0; RecipeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local rlLayout = Instance.new("UIListLayout", RecipeScroll); rlLayout.Padding = UDim.new(0, 10); rlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- [[ THE FIX: Restored the Forge Minigame Modal Overlay ]]
	local ForgeModalOverlay = Instance.new("Frame", parentFrame.Parent)
	ForgeModalOverlay.Size = UDim2.new(1, 0, 1, 0); ForgeModalOverlay.BackgroundColor3 = Color3.new(0,0,0); ForgeModalOverlay.BackgroundTransparency = 0.3; ForgeModalOverlay.ZIndex = 100; ForgeModalOverlay.Visible = false; ForgeModalOverlay.Active = true
	local ForgeModal, _ = CreateGrimPanel(ForgeModalOverlay)
	ForgeModal.Size = UDim2.new(0.8, 0, 0.9, 0); ForgeModal.Position = UDim2.new(0.5, 0, 0.5, 0); ForgeModal.AnchorPoint = Vector2.new(0.5, 0.5); ForgeModal.ZIndex = 101

	local closeFBtn, _ = CreateSharpButton(ForgeModal, "X", UDim2.new(0, 40, 0, 40), Enum.Font.GothamBlack, 16); closeFBtn.Position = UDim2.new(1, -15, 0, 15); closeFBtn.AnchorPoint = Vector2.new(1, 0); closeFBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closeFBtn.ZIndex = 102
	closeFBtn.MouseButton1Click:Connect(function() ForgeModalOverlay.Visible = false end)

	local InfoView = Instance.new("Frame", ForgeModal); InfoView.Size = UDim2.new(1, 0, 1, 0); InfoView.BackgroundTransparency = 1; InfoView.ZIndex = 102
	local bpTitle = UIHelpers.CreateLabel(InfoView, "BLUEPRINT", UDim2.new(1, -70, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22); bpTitle.Position = UDim2.new(0, 20, 0, 15); bpTitle.TextXAlignment = Enum.TextXAlignment.Left; bpTitle.ZIndex = 103
	local bpDesc = UIHelpers.CreateLabel(InfoView, "Select an item.", UDim2.new(1, -40, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); bpDesc.Position = UDim2.new(0, 20, 0, 55); bpDesc.TextXAlignment = Enum.TextXAlignment.Left; bpDesc.TextWrapped = true; bpDesc.TextYAlignment = Enum.TextYAlignment.Top; bpDesc.ZIndex = 103

	local ReqList = Instance.new("Frame", InfoView); ReqList.Size = UDim2.new(1, -40, 0, 150); ReqList.Position = UDim2.new(0, 20, 0, 100); ReqList.BackgroundTransparency = 1; ReqList.ZIndex = 103
	local reqLayout = Instance.new("UIListLayout", ReqList); reqLayout.Padding = UDim.new(0, 8)

	local CraftBtn, CraftStroke = CreateSharpButton(InfoView, "START FORGE MINIGAME", UDim2.new(0.8, 0, 0, 55), Enum.Font.GothamBlack, 16); CraftBtn.Position = UDim2.new(0.5, 0, 1, -20); CraftBtn.AnchorPoint = Vector2.new(0.5, 1); CraftBtn.ZIndex = 103

	local MinigameView = Instance.new("Frame", ForgeModal); MinigameView.Size = UDim2.new(1, 0, 1, 0); MinigameView.BackgroundTransparency = 1; MinigameView.Visible = false; MinigameView.ZIndex = 102
	local mgTitle = UIHelpers.CreateLabel(MinigameView, "ACTIVE FORGE", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 100, 100), 24); mgTitle.Position = UDim2.new(0, 0, 0, 20); mgTitle.ZIndex = 103
	local mgInst = UIHelpers.CreateLabel(MinigameView, "Strike when the heat aligns perfectly. (0/3)", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 16); mgInst.Position = UDim2.new(0, 0, 0, 70); mgInst.ZIndex = 103

	local BarContainer, bcStroke = CreateGrimPanel(MinigameView); BarContainer.Size = UDim2.new(0.85, 0, 0, 60); BarContainer.Position = UDim2.new(0.5, 0, 0.45, 0); BarContainer.AnchorPoint = Vector2.new(0.5, 0.5); BarContainer.ZIndex = 103
	local SweetSpot = Instance.new("Frame", BarContainer); SweetSpot.Size = UDim2.new(0.25, 0, 1, 0); SweetSpot.Position = UDim2.new(0.375, 0, 0, 0); SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85); SweetSpot.BorderSizePixel = 0; Instance.new("UICorner", SweetSpot).CornerRadius = UDim.new(0, 8); SweetSpot.ZIndex = 104
	local Cursor = Instance.new("Frame", BarContainer); Cursor.Size = UDim2.new(0.02, 0, 1.4, 0); Cursor.Position = UDim2.new(0, 0, 0.5, 0); Cursor.AnchorPoint = Vector2.new(0.5, 0.5); Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Cursor.BorderSizePixel = 0; Instance.new("UICorner", Cursor).CornerRadius = UDim.new(1, 0); Cursor.ZIndex = 105

	local StrikeBtn, StrikeStroke = CreateSharpButton(MinigameView, "STRIKE", UDim2.new(0.6, 0, 0, 80), Enum.Font.GothamBlack, 28); StrikeBtn.Position = UDim2.new(0.5, 0, 0.85, 0); StrikeBtn.AnchorPoint = Vector2.new(0.5, 0.5); StrikeBtn.TextColor3 = Color3.fromRGB(255, 85, 85); StrikeStroke.Color = Color3.fromRGB(255, 85, 85); StrikeBtn.ZIndex = 103

	local selectedRecipeName = nil; local mgActive = false; local mgConn = nil; local strikes = 0; local totalAccuracy = 0; local currentTargetCenter = 0.5

	local function ResetSweetSpot()
		local p = math.random(10, 65) / 100 
		SweetSpot.Position = UDim2.new(p, 0, 0, 0); currentTargetCenter = p + 0.125; SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
	end

	local function EndMinigame()
		mgActive = false; if mgConn then mgConn:Disconnect() mgConn = nil end
		local finalQuality = "Standard"; local avg = totalAccuracy / 3
		if avg >= 0.80 then finalQuality = "Flawless" elseif avg >= 0.40 then finalQuality = "Masterwork" end
		mgInst.Text = "Forge Complete! Quality: <font color='#FFD700'>" .. string.upper(finalQuality) .. "</font>"
		task.wait(1.5); ForgeModalOverlay.Visible = false
		if selectedRecipeName then Network:WaitForChild("ForgeItem"):FireServer(selectedRecipeName, finalQuality) end
	end

	StrikeBtn.MouseButton1Click:Connect(function()
		if not mgActive then return end
		local cursorPos = Cursor.Position.X.Scale; local dist = math.abs(cursorPos - currentTargetCenter); local accuracy = 0
		if dist <= 0.125 then accuracy = 1 - (dist / 0.125); SweetSpot.BackgroundColor3 = Color3.fromRGB(255, 215, 0) 
		else accuracy = 0; SweetSpot.BackgroundColor3 = Color3.fromRGB(255, 85, 85) end

		totalAccuracy += accuracy; strikes += 1
		mgInst.Text = "Strike when the heat aligns perfectly. (" .. strikes .. "/3)"

		if strikes >= 3 then EndMinigame() else mgActive = false; task.wait(0.4); ResetSweetSpot(); mgActive = true end
	end)

	CraftBtn.MouseButton1Click:Connect(function()
		if not selectedRecipeName then return end
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
		local resItem = recipeData.Result; local resData = ItemData.Equipment[resItem] or ItemData.Consumables[resItem]; local rarity = resData and resData.Rarity or "Common"; local rColor = CONFIG.RarityColors[rarity] or Color3.fromRGB(200,200,200)

		local rBtn, rStrk = CreateSharpButton(RecipeScroll, "", UDim2.new(0.95, 0, 0, 80), Enum.Font.GothamBlack, 12); rStrk.Color = rColor
		local rTitleLbl = UIHelpers.CreateLabel(rBtn, string.upper(rec), UDim2.new(1, -15, 0, 30), Enum.Font.GothamBlack, rColor, 14); rTitleLbl.Position = UDim2.new(0, 15, 0, 10); rTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; rTitleLbl.TextScaled = true; local tCon = Instance.new("UITextSizeConstraint", rTitleLbl); tCon.MaxTextSize = 14
		local rTagLbl = UIHelpers.CreateLabel(rBtn, "[" .. string.upper(rarity) .. "]", UDim2.new(1, -15, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(200, 200, 200), 11); rTagLbl.Position = UDim2.new(0, 15, 1, -25); rTagLbl.TextXAlignment = Enum.TextXAlignment.Left

		rBtn.MouseButton1Click:Connect(function()
			selectedRecipeName = rec; bpTitle.Text = string.upper(rec); bpTitle.TextColor3 = rColor
			bpDesc.Text = "<font color='" .. ColorToHex(rColor) .. "'>[" .. rarity:upper() .. "]</font> " .. (resData and resData.Desc or "A high-tier piece of equipment forged from rare materials."); bpDesc.RichText = true
			CraftStroke.Color = rColor; CraftBtn.TextColor3 = rColor

			for _, c in ipairs(ReqList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			local function MakeReq(matName, amt)
				local rf, rs = CreateGrimPanel(ReqList); rf.Size = UDim2.new(1, 0, 0, 35); rs.Color = UIHelpers.Colors.BorderMuted; rs.Thickness = 1; rf.ZIndex = 103
				local l = UIHelpers.CreateLabel(rf, amt .. "x " .. matName, UDim2.new(1, -20, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14); l.Position = UDim2.new(0, 10, 0, 0); l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 104
			end

			if ItemData.ForgeRecipes[rec] then
				for mat, amt in pairs(ItemData.ForgeRecipes[rec].ReqItems) do MakeReq(mat, amt) end
				MakeReq("Dews", ItemData.ForgeRecipes[rec].DewCost)
			end

			InfoView.Visible = true; MinigameView.Visible = false
			ForgeModalOverlay.Visible = true
		end)
	end
end

return MobileSupplyForgeTab