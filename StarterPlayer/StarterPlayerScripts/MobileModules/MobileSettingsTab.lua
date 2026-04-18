-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileSettingsTab
local MobileSettingsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local SharedUI = playerScripts:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

if player:GetAttribute("Setting_ScreenFlash") == nil then player:SetAttribute("Setting_ScreenFlash", true) end
if player:GetAttribute("Setting_Music") == nil then player:SetAttribute("Setting_Music", true) end
if player:GetAttribute("Setting_AutoTrain") == nil then player:SetAttribute("Setting_AutoTrain", false) end

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateMobileToggleCard(parent, title, desc, attributeName)
	local card, strk = CreateGrimPanel(parent)
	card.Size = UDim2.new(0.95, 0, 0, 90)

	local titleLbl = UIHelpers.CreateLabel(card, title, UDim2.new(0.65, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)
	titleLbl.Position = UDim2.new(0, 15, 0, 10); titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local descLbl = UIHelpers.CreateLabel(card, desc, UDim2.new(0.65, 0, 0, 40), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 11)
	descLbl.Position = UDim2.new(0, 15, 0, 40); descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextWrapped = true; descLbl.TextYAlignment = Enum.TextYAlignment.Top

	local ToggleBtn = Instance.new("TextButton", card)
	ToggleBtn.Size = UDim2.new(0, 90, 0, 45)
	ToggleBtn.Position = UDim2.new(1, -10, 0.5, 0)
	ToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.Font = Enum.Font.GothamBlack
	ToggleBtn.TextSize = 16
	ToggleBtn.AutoButtonColor = false
	ToggleBtn.Selectable = false 

	local btnStroke = Instance.new("UIStroke", ToggleBtn)
	btnStroke.Thickness = 2; btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local function UpdateVisuals()
		local isOn = player:GetAttribute(attributeName)
		if isOn then
			ToggleBtn.Text = "ON"
			ToggleBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
			btnStroke.Color = Color3.fromRGB(85, 255, 85)
		else
			ToggleBtn.Text = "OFF"
			ToggleBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
			btnStroke.Color = Color3.fromRGB(255, 85, 85)
		end
	end

	ToggleBtn.MouseButton1Click:Connect(function()
		local currentState = player:GetAttribute(attributeName)
		player:SetAttribute(attributeName, not currentState)
		UpdateVisuals()
	end)

	UpdateVisuals()
	return card
end

function MobileSettingsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local Header = UIHelpers.CreateLabel(parentFrame, "SETTINGS", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20)
	Header.Position = UDim2.new(0, 15, 0, 5); Header.TextXAlignment = Enum.TextXAlignment.Left

	local ScrollList = Instance.new("ScrollingFrame", parentFrame)
	ScrollList.Size = UDim2.new(1, 0, 1, -60)
	ScrollList.Position = UDim2.new(0, 0, 0, 50)
	ScrollList.BackgroundTransparency = 1
	ScrollList.ScrollBarThickness = 2
	ScrollList.BorderSizePixel = 0
	ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local layout = Instance.new("UIListLayout", ScrollList)
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	CreateMobileToggleCard(ScrollList, "SCREEN FLASH", "Toggles intense combat and titan flashes.", "Setting_ScreenFlash")
	CreateMobileToggleCard(ScrollList, "MUSIC", "Toggles background region music.", "Setting_Music")

	local autoTrainCard = CreateMobileToggleCard(ScrollList, "AUTO TRAIN", "Auto-punches to train stats while AFK.", "Setting_AutoTrain")

	-- [[ THE FIX: Hide toggle entirely if player doesn't own the gamepass ]]
	if not player:GetAttribute("HasAutoTrain") and player.UserId ~= 4068160397 then
		autoTrainCard.Visible = false
	end

	-- [[ THE FIX: Added Gamepass verification directly to the background loop ]]
	if not _G.AutoTrainLoopActive then
		_G.AutoTrainLoopActive = true
		task.spawn(function()
			local trainRemote = Network:WaitForChild("TrainAction")
			while true do
				task.wait(1.0) 
				if player:GetAttribute("Setting_AutoTrain") and (player:GetAttribute("HasAutoTrain") or player.UserId == 4068160397) then
					-- Passes combo '0' and isTitan 'false' to safely trigger baseline training
					trainRemote:FireServer(0, false) 
				end
			end
		end)
	end
end

return MobileSettingsTab