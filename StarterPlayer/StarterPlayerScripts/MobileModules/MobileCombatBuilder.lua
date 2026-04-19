-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MobileCombatBuilder
local MobileCombatBuilder = {}

local Players = game:GetService("Players")
local SharedUI = script.Parent.Parent:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers"))

local function CreateFlatPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(45, 45, 50)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateFlatBar(parent, title, colorHex, pos, size, alignRight, baseZ, isOverlay)
	baseZ = baseZ or 1
	local cColor = Color3.fromHex(colorHex:gsub("#", ""))
	local shadowColor = Color3.new(cColor.R * 0.4, cColor.G * 0.4, cColor.B * 0.4)

	local container = Instance.new("Frame", parent)
	container.Size = size
	container.Position = pos
	container.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	container.BorderSizePixel = 0
	container.ZIndex = baseZ

	if isOverlay then container.BackgroundTransparency = 1 end

	local strk = Instance.new("UIStroke", container)
	strk.Color = Color3.fromRGB(40, 40, 45)
	strk.Thickness = 1
	strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if isOverlay then strk.Enabled = false end

	local fill = Instance.new("Frame", container)
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.ZIndex = baseZ + 1

	if alignRight then
		fill.AnchorPoint = Vector2.new(1, 0)
		fill.Position = UDim2.new(1, 0, 0, 0)
	end

	local grad = Instance.new("UIGradient", fill)
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, cColor),
		ColorSequenceKeypoint.new(1, shadowColor)
	}
	grad.Rotation = 90

	local txt = UIHelpers.CreateLabel(container, title .. " 100/100", UDim2.new(1, -8, 1, 0), Enum.Font.GothamBold, Color3.fromRGB(240, 240, 240), 16)
	txt.TextScaled = true
	local tsc = Instance.new("UITextSizeConstraint", txt)
	tsc.MinTextSize = 10; tsc.MaxTextSize = 16

	if alignRight then
		txt.TextXAlignment = Enum.TextXAlignment.Right
	else
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.Position = UDim2.new(0, 8, 0, 0)
	end
	txt.ZIndex = baseZ + 2

	return fill, txt, container
end

function MobileCombatBuilder.Build(masterScreenGui, player)
	local GUI = {}

	GUI.CombatBackdrop = Instance.new("TextButton", masterScreenGui)
	GUI.CombatBackdrop.Name = "MobileCombatBackdrop"
	GUI.CombatBackdrop.Size = UDim2.new(1, 0, 1, 0)
	GUI.CombatBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	GUI.CombatBackdrop.BackgroundTransparency = 1
	GUI.CombatBackdrop.Text = ""
	GUI.CombatBackdrop.AutoButtonColor = false
	GUI.CombatBackdrop.Visible = false
	GUI.CombatBackdrop.ZIndex = 98
	GUI.CombatBackdrop.Active = true

	GUI.CombatWindow = Instance.new("Frame", masterScreenGui)
	GUI.CombatWindow.Name = "MobileCombatWindow"
	GUI.CombatWindow.Size = UDim2.new(1, 0, 1, 0)
	GUI.CombatWindow.Position = UDim2.new(0, 0, 0, 0)
	GUI.CombatWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	GUI.CombatWindow.BackgroundTransparency = 0.1
	GUI.CombatWindow.Visible = false
	GUI.CombatWindow.ZIndex = 100

	GUI.VFXOverlay = Instance.new("Frame", GUI.CombatWindow)
	GUI.VFXOverlay.Size = UDim2.new(1, 0, 1, 0)
	GUI.VFXOverlay.BackgroundTransparency = 1
	GUI.VFXOverlay.ZIndex = 105

	local Header = Instance.new("Frame", GUI.CombatWindow)
	Header.Size = UDim2.new(1, 0, 0.08, 0)
	Header.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	Header.BorderSizePixel = 0
	local hStroke = Instance.new("UIStroke", Header)
	hStroke.Color = Color3.fromRGB(40, 40, 45); hStroke.Thickness = 1
	hStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	GUI.MissionInfoLbl = UIHelpers.CreateLabel(Header, "COMBAT DEPLOYMENT", UDim2.new(1, -20, 0.7, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 18)
	GUI.MissionInfoLbl.Position = UDim2.new(0, 15, 0.15, 0)
	GUI.MissionInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
	GUI.MissionInfoLbl.TextScaled = true
	local mtsc = Instance.new("UITextSizeConstraint", GUI.MissionInfoLbl); mtsc.MaxTextSize = 18

	-- COMBATANTS FRAME
	GUI.CombatantsFrame = Instance.new("Frame", GUI.CombatWindow)
	GUI.CombatantsFrame.Size = UDim2.new(1, -20, 0.28, 0)
	GUI.CombatantsFrame.Position = UDim2.new(0, 10, 0.1, 0)
	GUI.CombatantsFrame.BackgroundTransparency = 1
	GUI.CombatantsFrame.ClipsDescendants = true

	-- Player Half
	GUI.PlayerPanel, _ = CreateFlatPanel(GUI.CombatantsFrame)
	GUI.PlayerPanel.Size = UDim2.new(0.46, 0, 1, 0)
	GUI.PlayerPanel.Position = UDim2.new(0, 0, 0, 0)

	GUI.pAvatar = Instance.new("ImageLabel", GUI.PlayerPanel)
	GUI.pAvatar.Size = UDim2.new(1, 0, 0.8, 0)
	GUI.pAvatar.Position = UDim2.new(0, 10, 0.1, 0)
	GUI.pAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	GUI.pAvatar.ZIndex = 2
	GUI.pAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	GUI.pAvatar.ScaleType = Enum.ScaleType.Crop

	local pAvatarAspect = Instance.new("UIAspectRatioConstraint", GUI.pAvatar)
	pAvatarAspect.AspectRatio = 1
	pAvatarAspect.DominantAxis = Enum.DominantAxis.Height
	local pAvatarStroke = Instance.new("UIStroke", GUI.pAvatar); pAvatarStroke.Color = Color3.fromRGB(85, 170, 255); pAvatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local pInfo = Instance.new("Frame", GUI.PlayerPanel)
	pInfo.Size = UDim2.new(0.65, -10, 0.8, 0)
	pInfo.Position = UDim2.new(0.35, 10, 0.1, 0)
	pInfo.BackgroundTransparency = 1

	GUI.pNameLbl = UIHelpers.CreateLabel(pInfo, player.Name, UDim2.new(1, 0, 0.2, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 20)
	GUI.pNameLbl.Position = UDim2.new(0, 0, 0, 0)
	GUI.pNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	GUI.pNameLbl.TextScaled = true
	local ntsc = Instance.new("UITextSizeConstraint", GUI.pNameLbl); ntsc.MaxTextSize = 20

	GUI.pHPBar, GUI.pHPText = CreateFlatBar(pInfo, "HP", "#44DD44", UDim2.new(0, 0, 0.25, 0), UDim2.new(1, 0, 0.2, 0), false, 1)
	GUI.pGasBar, GUI.pGasText = CreateFlatBar(pInfo, "GAS", "#AADDDD", UDim2.new(0, 0, 0.48, 0), UDim2.new(1, 0, 0.2, 0), false, 1)
	GUI.pHeatBar, GUI.pHeatText, GUI.pHeatContainer = CreateFlatBar(pInfo, "HEAT", "#FF8800", UDim2.new(0, 0, 0.71, 0), UDim2.new(1, 0, 0.2, 0), false, 1)
	GUI.pHeatContainer.Visible = false

	GUI.PlayerStatusBox = Instance.new("Frame", pInfo)
	GUI.PlayerStatusBox.Size = UDim2.new(1, 0, 0.2, 0)
	GUI.PlayerStatusBox.Position = UDim2.new(0, 0, 0.95, 0)
	GUI.PlayerStatusBox.BackgroundTransparency = 1
	local pStatLayout = Instance.new("UIListLayout", GUI.PlayerStatusBox)
	pStatLayout.FillDirection = Enum.FillDirection.Horizontal; pStatLayout.Padding = UDim.new(0, 4)

	-- Ally Intercept Animation Panel
	GUI.AllyPanel, _ = CreateFlatPanel(GUI.CombatantsFrame)
	GUI.AllyPanel.Size = UDim2.new(0.46, 0, 1, 0)
	GUI.AllyPanel.Position = UDim2.new(-0.5, 0, 0, 0)
	GUI.AllyPanel.ZIndex = 5

	GUI.AllyAvatar = Instance.new("ImageLabel", GUI.AllyPanel)
	GUI.AllyAvatar.Size = UDim2.new(1, 0, 0.8, 0)
	GUI.AllyAvatar.Position = UDim2.new(0, 10, 0.1, 0)
	GUI.AllyAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	GUI.AllyAvatar.ScaleType = Enum.ScaleType.Crop
	GUI.AllyAvatar.ZIndex = 6
	local allyAvatarAspect = Instance.new("UIAspectRatioConstraint", GUI.AllyAvatar); allyAvatarAspect.AspectRatio = 1; allyAvatarAspect.DominantAxis = Enum.DominantAxis.Height
	local allyAvatarStrk = Instance.new("UIStroke", GUI.AllyAvatar); allyAvatarStrk.Color = Color3.fromRGB(85, 255, 255); allyAvatarStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local aInfo = Instance.new("Frame", GUI.AllyPanel)
	aInfo.Size = UDim2.new(0.65, -10, 0.8, 0); aInfo.Position = UDim2.new(0.35, 10, 0.1, 0); aInfo.BackgroundTransparency = 1

	GUI.AllyNameLbl = UIHelpers.CreateLabel(aInfo, "ALLY NAME", UDim2.new(1, 0, 0.2, 0), Enum.Font.GothamBold, Color3.fromRGB(85, 255, 255), 18)
	GUI.AllyNameLbl.Position = UDim2.new(0, 0, 0, 0); GUI.AllyNameLbl.TextXAlignment = Enum.TextXAlignment.Left; GUI.AllyNameLbl.ZIndex = 6; GUI.AllyNameLbl.TextScaled = true
	local aNtsc = Instance.new("UITextSizeConstraint", GUI.AllyNameLbl); aNtsc.MaxTextSize = 20

	GUI.AllyQuoteLbl = UIHelpers.CreateLabel(aInfo, '"I\'ve got your back!"', UDim2.new(1, 0, 0.7, 0), Enum.Font.GothamMedium, Color3.fromRGB(220, 220, 220), 16)
	GUI.AllyQuoteLbl.Position = UDim2.new(0, 0, 0.3, 0); GUI.AllyQuoteLbl.TextXAlignment = Enum.TextXAlignment.Left; GUI.AllyQuoteLbl.TextYAlignment = Enum.TextYAlignment.Top; GUI.AllyQuoteLbl.TextWrapped = true; GUI.AllyQuoteLbl.ZIndex = 6

	-- VS Text Middle
	local vsLbl = UIHelpers.CreateLabel(GUI.CombatantsFrame, "VS", UDim2.new(0.08, 0, 1, 0), Enum.Font.GothamBlack, Color3.fromRGB(100, 100, 110), 30)
	vsLbl.Position = UDim2.new(0.46, 0, 0, 0)
	vsLbl.TextScaled = true; local vTsc = Instance.new("UITextSizeConstraint", vsLbl); vTsc.MaxTextSize = 36

	-- Enemy Half
	local EnemyPanel, _ = CreateFlatPanel(GUI.CombatantsFrame)
	EnemyPanel.Size = UDim2.new(0.46, 0, 1, 0)
	EnemyPanel.Position = UDim2.new(0.54, 0, 0, 0)

	GUI.eAvatar = Instance.new("ImageLabel", EnemyPanel)
	GUI.eAvatar.Size = UDim2.new(1, 0, 0.8, 0)
	GUI.eAvatar.Position = UDim2.new(1, -10, 0.1, 0)
	GUI.eAvatar.AnchorPoint = Vector2.new(1, 0)
	GUI.eAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	GUI.eAvatar.Image = "rbxassetid://90132878979603" 
	GUI.eAvatar.ScaleType = Enum.ScaleType.Crop

	local eAvatarAspect = Instance.new("UIAspectRatioConstraint", GUI.eAvatar)
	eAvatarAspect.AspectRatio = 1
	eAvatarAspect.DominantAxis = Enum.DominantAxis.Height
	local eAvatarStroke = Instance.new("UIStroke", GUI.eAvatar); eAvatarStroke.Color = Color3.fromRGB(255, 85, 85); eAvatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local eInfo = Instance.new("Frame", EnemyPanel)
	eInfo.Size = UDim2.new(0.65, -10, 0.8, 0)
	eInfo.Position = UDim2.new(0, 10, 0.1, 0)
	eInfo.BackgroundTransparency = 1

	GUI.eNameLbl = UIHelpers.CreateLabel(eInfo, "UNKNOWN ABNORMAL", UDim2.new(1, 0, 0.2, 0), Enum.Font.GothamBold, Color3.fromRGB(255, 100, 100), 20)
	GUI.eNameLbl.Position = UDim2.new(0, 0, 0, 0)
	GUI.eNameLbl.TextXAlignment = Enum.TextXAlignment.Right
	GUI.eNameLbl.TextScaled = true
	local eNtsc = Instance.new("UITextSizeConstraint", GUI.eNameLbl); eNtsc.MaxTextSize = 20

	GUI.eHPBar, GUI.eHPText, GUI.eHPContainer = CreateFlatBar(eInfo, "HP", "#DD4444", UDim2.new(0, 0, 0.25, 0), UDim2.new(1, 0, 0.2, 0), true, 1)
	GUI.eGateBar, GUI.eGateText, GUI.eGateContainer = CreateFlatBar(eInfo, "ARMOR", "#AAAAAA", UDim2.new(0, 0, 0.25, 0), UDim2.new(1, 0, 0.2, 0), true, 10, true)
	GUI.eGateContainer.Visible = false

	GUI.EnemyStatusBox = Instance.new("Frame", eInfo)
	GUI.EnemyStatusBox.Size = UDim2.new(1, 0, 0.2, 0)
	GUI.EnemyStatusBox.Position = UDim2.new(0, 0, 0.95, 0)
	GUI.EnemyStatusBox.BackgroundTransparency = 1
	local eStatLayout = Instance.new("UIListLayout", GUI.EnemyStatusBox)
	eStatLayout.FillDirection = Enum.FillDirection.Horizontal; eStatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; eStatLayout.Padding = UDim.new(0, 4)

	-- EXECUTE OVERLAY 
	GUI.ExecuteOverlay = Instance.new("Frame", GUI.CombatWindow)
	GUI.ExecuteOverlay.Size = UDim2.new(1, 0, 1, 0); GUI.ExecuteOverlay.BackgroundColor3 = Color3.new(0, 0, 0); GUI.ExecuteOverlay.BackgroundTransparency = 0.3; GUI.ExecuteOverlay.ZIndex = 150; GUI.ExecuteOverlay.Visible = false
	GUI.ExecuteBanner = Instance.new("TextButton", GUI.ExecuteOverlay)
	GUI.ExecuteBanner.Size = UDim2.new(1, 0, 0.25, 0); GUI.ExecuteBanner.Position = UDim2.new(0.5, 0, 0.5, 0); GUI.ExecuteBanner.AnchorPoint = Vector2.new(0.5, 0.5); GUI.ExecuteBanner.BackgroundColor3 = Color3.fromRGB(15, 10, 10); GUI.ExecuteBanner.BorderSizePixel = 0; GUI.ExecuteBanner.AutoButtonColor = false; GUI.ExecuteBanner.Text = ""; GUI.ExecuteBanner.ZIndex = 151
	local ebStroke = Instance.new("UIStroke", GUI.ExecuteBanner); ebStroke.Color = Color3.fromRGB(100, 0, 0); ebStroke.Thickness = 1; ebStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local exGrad = Instance.new("UIGradient", GUI.ExecuteBanner); exGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 5, 5)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}; exGrad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(0.8, 0.2), NumberSequenceKeypoint.new(1, 1)}
	GUI.ExecuteText = UIHelpers.CreateLabel(GUI.ExecuteBanner, "SEVER", UDim2.new(1, 0, 1, 0), Enum.Font.Garamond, Color3.fromRGB(200, 200, 200), 60); GUI.ExecuteText.ZIndex = 152; GUI.ExecuteText.TextScaled = true; local exTsc = Instance.new("UITextSizeConstraint", GUI.ExecuteText); exTsc.MaxTextSize = 75
	local exStroke = Instance.new("UIStroke", GUI.ExecuteText); exStroke.Color = Color3.fromRGB(40, 0, 0); exStroke.Thickness = 2
	local pulsator = Instance.new("UIScale", GUI.ExecuteBanner); pulsator.Name = "Pulsator"
	GUI.ExecuteFlash = Instance.new("Frame", GUI.ExecuteOverlay); GUI.ExecuteFlash.Size = UDim2.new(1, 0, 1, 0); GUI.ExecuteFlash.BackgroundColor3 = Color3.new(1, 1, 1); GUI.ExecuteFlash.BackgroundTransparency = 1; GUI.ExecuteFlash.ZIndex = 155

	-- LOG AREA
	GUI.LogContainer, _ = CreateFlatPanel(GUI.CombatWindow)
	GUI.LogContainer.Size = UDim2.new(1, -20, 0.20, 0)
	GUI.LogContainer.Position = UDim2.new(0, 10, 0.39, 0)

	GUI.LogScroll = Instance.new("ScrollingFrame", GUI.LogContainer)
	GUI.LogScroll.Size = UDim2.new(1, -20, 1, -20)
	GUI.LogScroll.Position = UDim2.new(0, 10, 0, 10)
	GUI.LogScroll.BackgroundTransparency = 1
	GUI.LogScroll.ScrollBarThickness = 6
	GUI.LogScroll.BorderSizePixel = 0

	local logLayout = Instance.new("UIListLayout", GUI.LogScroll)
	logLayout.Padding = UDim.new(0, 6)
	logLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		GUI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10)
		GUI.LogScroll.CanvasPosition = Vector2.new(0, GUI.LogScroll.CanvasSize.Y.Offset)
	end)

	-- ACTION AREA
	GUI.ActionContainer = Instance.new("Frame", GUI.CombatWindow)
	GUI.ActionContainer.Size = UDim2.new(1, -20, 0.39, 0)
	GUI.ActionContainer.Position = UDim2.new(0, 10, 0.60, 0)
	GUI.ActionContainer.BackgroundTransparency = 1

	-- [[ THE FIX: Fully dynamic scaling forces mobile devices to register touch swiping gracefully ]]
	GUI.ActionGrid = Instance.new("ScrollingFrame", GUI.ActionContainer)
	GUI.ActionGrid.Size = UDim2.new(1, 0, 1, 0)
	GUI.ActionGrid.BackgroundTransparency = 1
	GUI.ActionGrid.ScrollBarThickness = 0
	GUI.ActionGrid.ScrollingDirection = Enum.ScrollingDirection.Y
	GUI.ActionGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	GUI.ActionGrid.CanvasSize = UDim2.new(0, 0, 0, 0)

	local acLayout = Instance.new("UIGridLayout", GUI.ActionGrid)
	acLayout.CellSize = UDim2.new(0.23, 0, 0, 45) 
	acLayout.CellPadding = UDim2.new(0.02, 0, 0, 6)
	acLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	acLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	-- Keep manual connection as secondary safety fallback
	acLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GUI.ActionGrid.CanvasSize = UDim2.new(0, 0, 0, acLayout.AbsoluteContentSize.Y + 10)
	end)

	-- TARGET MENU
	GUI.TargetMenu = Instance.new("Frame", GUI.ActionContainer)
	GUI.TargetMenu.Size = UDim2.new(1, 0, 1, 0)
	GUI.TargetMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	GUI.TargetMenu.Visible = false
	local tmStroke = Instance.new("UIStroke", GUI.TargetMenu)
	tmStroke.Color = Color3.fromRGB(40, 40, 45); tmStroke.Thickness = 1; tmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local InfoPanel = Instance.new("Frame", GUI.TargetMenu)
	InfoPanel.Size = UDim2.new(0.5, 0, 1, 0)
	InfoPanel.BackgroundTransparency = 1

	GUI.tHoverTitle = UIHelpers.CreateLabel(InfoPanel, "SELECT TARGET", UDim2.new(1, -20, 0.25, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 26)
	GUI.tHoverTitle.Position = UDim2.new(0, 20, 0.1, 0); GUI.tHoverTitle.TextXAlignment = Enum.TextXAlignment.Left
	GUI.tHoverTitle.TextScaled = true; local ttTsc = Instance.new("UITextSizeConstraint", GUI.tHoverTitle); ttTsc.MaxTextSize = 28

	GUI.tHoverDesc = UIHelpers.CreateLabel(InfoPanel, "Tap a limb to view its tactical effect.", UDim2.new(1, -20, 0.35, 0), Enum.Font.GothamMedium, Color3.fromRGB(180, 180, 180), 16)
	GUI.tHoverDesc.Position = UDim2.new(0, 20, 0.35, 0); GUI.tHoverDesc.TextXAlignment = Enum.TextXAlignment.Left; GUI.tHoverDesc.TextYAlignment = Enum.TextYAlignment.Top; GUI.tHoverDesc.TextWrapped = true
	GUI.tHoverDesc.TextScaled = true; local hdTsc = Instance.new("UITextSizeConstraint", GUI.tHoverDesc); hdTsc.MaxTextSize = 18

	GUI.CancelBtn = Instance.new("TextButton", InfoPanel)
	GUI.CancelBtn.Size = UDim2.new(0.6, 0, 0.25, 0)
	GUI.CancelBtn.Position = UDim2.new(0, 20, 0.70, 0)
	GUI.CancelBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	GUI.CancelBtn.BorderSizePixel = 0
	GUI.CancelBtn.Font = Enum.Font.GothamBold
	GUI.CancelBtn.Text = "CANCEL"
	GUI.CancelBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
	GUI.CancelBtn.TextScaled = true; local cbTsc = Instance.new("UITextSizeConstraint", GUI.CancelBtn); cbTsc.MaxTextSize = 18
	Instance.new("UICorner", GUI.CancelBtn).CornerRadius = UDim.new(0, 4)
	local cbStroke = Instance.new("UIStroke", GUI.CancelBtn); cbStroke.Color = Color3.fromRGB(255, 85, 85); cbStroke.Thickness = 1; cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local BodyContainer = Instance.new("Frame", GUI.TargetMenu)
	BodyContainer.Size = UDim2.new(0.5, 0, 0.9, 0) 
	BodyContainer.Position = UDim2.new(0.75, 0, 0.5, 0)
	BodyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	BodyContainer.BackgroundTransparency = 1
	local aspect = Instance.new("UIAspectRatioConstraint", BodyContainer); aspect.AspectRatio = 0.8

	GUI.Limbs = {}
	local function BuildLimb(name, targetId, size, pos, hoverText, baseColor)
		local limb = Instance.new("TextButton", BodyContainer)
		limb.Size = size; limb.Position = pos
		limb.BackgroundColor3 = Color3.fromRGB(22, 22, 26) 
		limb.Text = name:upper()
		limb.Font = Enum.Font.GothamBlack
		limb.TextColor3 = Color3.fromRGB(255, 255, 255) 
		limb.AutoButtonColor = false
		limb.AnchorPoint = Vector2.new(0.5, 0.5)
		limb.TextScaled = true; local limbtsc = Instance.new("UITextSizeConstraint", limb); limbtsc.MaxTextSize = 16

		local strk = Instance.new("UIStroke", limb)
		strk.Color = baseColor; strk.Thickness = 2; strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		limb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				strk.Color = UIHelpers.Colors.Gold
				strk.Thickness = 3
				GUI.tHoverTitle.Text = "TARGET: " .. string.upper(targetId)
				GUI.tHoverTitle.TextColor3 = baseColor
				GUI.tHoverDesc.Text = hoverText
			end
		end)

		limb.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				strk.Color = baseColor
				strk.Thickness = 2
				GUI.tHoverTitle.Text = "SELECT TARGET"
				GUI.tHoverTitle.TextColor3 = UIHelpers.Colors.Gold
				GUI.tHoverDesc.Text = "Tap a limb to view its tactical effect."
			end
		end)
		GUI.Limbs[targetId] = limb
	end

	BuildLimb("Eyes", "Eyes", UDim2.new(0.24, 0, 0.18, 0), UDim2.new(0.5, 0, 0.08, 0), "Deals 20% Damage. Inflicts Blinded.", Color3.fromRGB(120, 120, 180))
	BuildLimb("Nape", "Nape", UDim2.new(0.24, 0, 0.06, 0), UDim2.new(0.5, 0, 0.22, 0), "Deals 150% Damage. Low accuracy.", Color3.fromRGB(220, 80, 80))
	BuildLimb("Body", "Body", UDim2.new(0.48, 0, 0.38, 0), UDim2.new(0.5, 0, 0.45, 0), "Deals 100% Damage. Standard accuracy.", Color3.fromRGB(80, 160, 80))
	BuildLimb("L.Arm", "LArm", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.14, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	BuildLimb("R.Arm", "RArm", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.86, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	BuildLimb("L.Leg", "LLeg", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.37, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))
	BuildLimb("R.Leg", "RLeg", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.63, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))

	-- VISUAL NOVEL ENGINE ELEMENTS
	GUI.DialogueBox = Instance.new("Frame", GUI.CombatWindow)
	GUI.DialogueBox.Size = UDim2.new(1, -20, 0.33, 0)
	GUI.DialogueBox.Position = UDim2.new(0, 10, 0.65, 0)
	GUI.DialogueBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	GUI.DialogueBox.Visible = false
	local dbStroke = Instance.new("UIStroke", GUI.DialogueBox); dbStroke.Color = Color3.fromRGB(70, 70, 80); dbStroke.Thickness = 2

	GUI.SpeakerLbl = UIHelpers.CreateLabel(GUI.DialogueBox, "SPEAKER", UDim2.new(1, -20, 0.2, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22)
	GUI.SpeakerLbl.Position = UDim2.new(0, 15, 0.05, 0); GUI.SpeakerLbl.TextXAlignment = Enum.TextXAlignment.Left
	GUI.SpeakerLbl.TextScaled = true; local sTsc = Instance.new("UITextSizeConstraint", GUI.SpeakerLbl); sTsc.MaxTextSize = 24

	GUI.DialogueText = UIHelpers.CreateLabel(GUI.DialogueBox, "", UDim2.new(1, -30, 0.5, 0), Enum.Font.GothamMedium, Color3.fromRGB(240, 240, 240), 20)
	GUI.DialogueText.Position = UDim2.new(0, 15, 0.25, 0); GUI.DialogueText.TextXAlignment = Enum.TextXAlignment.Left; GUI.DialogueText.TextYAlignment = Enum.TextYAlignment.Top; GUI.DialogueText.TextWrapped = true
	GUI.DialogueText.TextScaled = true; local dTxtC = Instance.new("UITextSizeConstraint", GUI.DialogueText); dTxtC.MaxTextSize = 20

	GUI.ContinueHint = UIHelpers.CreateLabel(GUI.DialogueBox, "Tap anywhere to continue ▼", UDim2.new(1, -20, 0.15, 0), Enum.Font.GothamBold, Color3.fromRGB(150, 150, 150), 16)
	GUI.ContinueHint.Position = UDim2.new(0, 0, 0.8, 0); GUI.ContinueHint.Visible = false

	GUI.ClickOverlay = Instance.new("TextButton", GUI.CombatWindow)
	GUI.ClickOverlay.Size = UDim2.new(1, 0, 1, 0); GUI.ClickOverlay.BackgroundTransparency = 1; GUI.ClickOverlay.Text = ""; GUI.ClickOverlay.ZIndex = 110; GUI.ClickOverlay.Visible = false

	GUI.ChoicesContainer = Instance.new("Frame", GUI.DialogueBox)
	GUI.ChoicesContainer.Size = UDim2.new(1, 0, 0.75, 0)
	GUI.ChoicesContainer.Position = UDim2.new(0, 0, 0.25, 0)
	GUI.ChoicesContainer.BackgroundTransparency = 1; GUI.ChoicesContainer.Visible = false
	local ccLayout = Instance.new("UIListLayout", GUI.ChoicesContainer)
	ccLayout.Padding = UDim.new(0, 10); ccLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	return GUI
end

return MobileCombatBuilder