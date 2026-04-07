-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileAdminTab
local MobileAdminTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer
local selectedPlayerName = nil

local AdminCommand = Network:WaitForChild("AdminCommand")

local CONFIG = {
	Categories = {
		{
			Title = "CURRENCIES", Color = "#FFD700",
			Actions = {
				{Name = "Set Dews", Placeholders = {"Amount"}, BtnText = "SET", Cmd = "SetDews"},
				{Name = "Set Player XP", Placeholders = {"Amount"}, BtnText = "SET", Cmd = "SetXP"},
				{Name = "Set Titan XP", Placeholders = {"Amount"}, BtnText = "SET", Cmd = "SetTitanXP"},
				{Name = "Set Prestige", Placeholders = {"Amount"}, BtnText = "SET", Cmd = "SetPrestige"},
				{Name = "Set Elo Rating", Placeholders = {"Amount"}, BtnText = "SET", Cmd = "SetElo"}
			}
		},
		{
			Title = "BASE STATS", Color = "#55FF55",
			Actions = {
				{Name = "Set Health", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetHealth"},
				{Name = "Set Gas Cap", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetGas"},
				{Name = "Set Strength", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetStrength"},
				{Name = "Set Defense", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetDefense"},
				{Name = "Set Speed", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetSpeed"},
				{Name = "Set Resolve", Placeholders = {"Value"}, BtnText = "SET", Cmd = "SetResolve"}
			}
		},
		{
			Title = "LOADOUT & INVENTORY", Color = "#55AAFF",
			Actions = {
				{Name = "Give Item/Material", Placeholders = {"Item Name", "Amount"}, BtnText = "GIVE", Cmd = "GiveItem"},
				{Name = "Force Equip Weapon", Placeholders = {"Weapon Name"}, BtnText = "EQUIP", Cmd = "EquipWeapon"},
				{Name = "Force Equip Accessory", Placeholders = {"Accessory Name"}, BtnText = "EQUIP", Cmd = "EquipAccessory"},
				{Name = "Force Equip Skill", Placeholders = {"Slot (1-4)", "Skill Name"}, BtnText = "EQUIP", Cmd = "EquipSkill"}
			}
		},
		{
			Title = "PROGRESSION", Color = "#FF88FF",
			Actions = {
				{Name = "Set Story Part", Placeholders = {"Part #"}, BtnText = "SET", Cmd = "SetStoryPart"},
				{Name = "Set Mission", Placeholders = {"Mission #"}, BtnText = "SET", Cmd = "SetMission"},
			}
		},
		{
			Title = "IDENTITY & BUFFS", Color = "#FF5555",
			Actions = {
				{Name = "Unlock Title", Placeholders = {"Title Name"}, BtnText = "UNLOCK", Cmd = "GiveTitle"},
				{Name = "Set Lineage (Clan)", Placeholders = {"Clan Name"}, BtnText = "SET", Cmd = "SetClan"},
				{Name = "Set Titan Shifter", Placeholders = {"Titan Name"}, BtnText = "SET", Cmd = "SetTitan"},
				{Name = "Grant VIP Status", Placeholders = {"True/False"}, BtnText = "SET", Cmd = "SetVIP"},
			}
		},
		{
			Title = "DANGER ZONE", Color = "#FF0000",
			Actions = {
				{Name = "Wipe Data", Placeholders = {}, BtnText = "WIPE PROFILE", Cmd = "WipePlayer"}
			}
		}
	}
}

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22); frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateInputBox(parent, placeholder, size)
	local box = Instance.new("TextBox", parent)
	box.Size = size; box.BackgroundColor3 = Color3.fromRGB(15, 15, 18); box.BorderSizePixel = 0; box.Font = Enum.Font.GothamMedium; box.TextSize = 12; box.TextColor3 = Color3.fromRGB(255, 255, 255); box.PlaceholderText = placeholder; box.PlaceholderColor3 = Color3.fromRGB(100, 100, 110); box.Text = ""; box.ClearTextOnFocus = false
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	local stroke = Instance.new("UIStroke", box); stroke.Color = Color3.fromRGB(45, 45, 50); stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	box.Focused:Connect(function() stroke.Color = UIHelpers.Colors.Gold end)
	box.FocusLost:Connect(function() stroke.Color = Color3.fromRGB(45, 45, 50) end)
	return box
end

local function CreateSharpButton(parent, text, size, font, textSize, hexColor)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromHex(hexColor:gsub("#","")); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromHex(hexColor:gsub("#","")); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.InputBegan:Connect(function() stroke.Color = UIHelpers.Colors.TextWhite; btn.TextColor3 = UIHelpers.Colors.TextWhite end)
	btn.InputEnded:Connect(function() stroke.Color = Color3.fromHex(hexColor:gsub("#","")); btn.TextColor3 = Color3.fromHex(hexColor:gsub("#","")) end)
	return btn
end

function MobileAdminTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainScroll = Instance.new("ScrollingFrame", parentFrame)
	MainScroll.Size = UDim2.new(1, 0, 1, 0)
	MainScroll.BackgroundTransparency = 1
	MainScroll.ScrollBarThickness = 6
	MainScroll.BorderSizePixel = 0

	local mLayout = Instance.new("UIListLayout", MainScroll)
	mLayout.Padding = UDim.new(0, 15)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local mPad = Instance.new("UIPadding", MainScroll)
	mPad.PaddingTop = UDim.new(0, 15)
	mPad.PaddingBottom = UDim.new(0, 40)

	mLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		MainScroll.CanvasSize = UDim2.new(0, 0, 0, mLayout.AbsoluteContentSize.Y + 60)
	end)

	local Header = UIHelpers.CreateLabel(MainScroll, "DEVELOPER OVERRIDE PANEL", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 85, 85), 20)

	-- ==========================================
	-- PLAYER SELECTION
	-- ==========================================
	local PlayerPanel, _ = CreateGrimPanel(MainScroll)
	PlayerPanel.Size = UDim2.new(0.95, 0, 0, 140)

	local ptTitle = UIHelpers.CreateLabel(PlayerPanel, "TARGET PLAYER:", UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)
	ptTitle.Position = UDim2.new(0, 10, 0, 10)
	ptTitle.TextXAlignment = Enum.TextXAlignment.Left

	local pInput = CreateInputBox(PlayerPanel, "Enter exact username...", UDim2.new(1, -20, 0, 40))
	pInput.Position = UDim2.new(0.5, 0, 0, 40)

	local lockBtn = CreateSharpButton(PlayerPanel, "LOCK TARGET", UDim2.new(1, -20, 0, 40), Enum.Font.GothamBlack, 14, "#55FF55")
	lockBtn.Position = UDim2.new(0.5, 0, 0, 90)
	lockBtn.AnchorPoint = Vector2.new(0.5, 0)

	local CurrentTargetLbl = UIHelpers.CreateLabel(MainScroll, "NO TARGET SELECTED", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 16)

	lockBtn.MouseButton1Click:Connect(function()
		if pInput.Text ~= "" then
			selectedPlayerName = pInput.Text
			CurrentTargetLbl.Text = "TARGETING: " .. selectedPlayerName:upper()
			CurrentTargetLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
		else
			selectedPlayerName = nil
			CurrentTargetLbl.Text = "NO TARGET SELECTED"
			CurrentTargetLbl.TextColor3 = UIHelpers.Colors.TextMuted
		end
	end)

	-- ==========================================
	-- ACTIONS
	-- ==========================================
	for _, category in ipairs(CONFIG.Categories) do
		local catTitle = UIHelpers.CreateLabel(MainScroll, category.Title, UDim2.new(0.95, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromHex(category.Color:gsub("#","")), 18)
		catTitle.TextXAlignment = Enum.TextXAlignment.Left

		for _, act in ipairs(category.Actions) do
			local actPanel, _ = CreateGrimPanel(MainScroll)
			local totalHeight = 40 + (#act.Placeholders * 40)
			actPanel.Size = UDim2.new(0.95, 0, 0, totalHeight)

			local aLbl = UIHelpers.CreateLabel(actPanel, act.Name, UDim2.new(1, -20, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
			aLbl.Position = UDim2.new(0, 10, 0, 10); aLbl.TextXAlignment = Enum.TextXAlignment.Left

			local inputBoxes = {}
			local yPos = 40
			for _, placeholder in ipairs(act.Placeholders) do
				local box = CreateInputBox(actPanel, placeholder, UDim2.new(0.6, 0, 0, 30))
				box.Position = UDim2.new(0.05, 0, 0, yPos)
				box.AnchorPoint = Vector2.new(0, 0)
				table.insert(inputBoxes, box)
				yPos += 40
			end

			local btnColor = category.Color
			if act.Color then btnColor = act.Color end

			local btnSizeY = (#act.Placeholders > 0) and (totalHeight - 50) or 30
			local btnPosY = (#act.Placeholders > 0) and 40 or 5

			local btn = CreateSharpButton(actPanel, act.BtnText, UDim2.new(0.3, 0, 0, btnSizeY), Enum.Font.GothamBlack, 12, btnColor)
			btn.Position = UDim2.new(0.95, 0, 0, btnPosY)
			btn.AnchorPoint = Vector2.new(1, 0)

			btn.MouseButton1Click:Connect(function()
				if not selectedPlayerName then return end
				local args = {}
				for _, box in ipairs(inputBoxes) do table.insert(args, box.Text) end
				AdminCommand:FireServer(act.Cmd, selectedPlayerName, unpack(args))
			end)
		end
	end
end

return MobileAdminTab