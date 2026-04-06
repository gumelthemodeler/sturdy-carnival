-- @ScriptType: ModuleScript
-- Name: MobileCombatUI
-- @ScriptType: ModuleScript
local MobileCombatUI = {}

local Players = game:GetService("Players"); local TweenService = game:GetService("TweenService"); local ReplicatedStorage = game:GetService("ReplicatedStorage"); local Network = ReplicatedStorage:WaitForChild("Network"); local CombatAction = Network:WaitForChild("CombatAction"); local CombatUpdate = Network:WaitForChild("CombatUpdate")
local player = Players.LocalPlayer; local playerScripts = player:WaitForChild("PlayerScripts"); local SharedUI = playerScripts:WaitForChild("SharedUI"); local UIHelpers = require(SharedUI:WaitForChild("UIHelpers")); local SkillData = require(ReplicatedStorage:WaitForChild("SkillData")); local VFXManager = require(playerScripts:WaitForChild("VFXManager"))

local MasterGui, GUI; local currentBattleState = nil; local pendingSkillName = nil; local inputLocked = false; local isTypewriting = false; local skipTypewriting = false; local ClickSignal = Instance.new("BindableEvent")
local InstantSkills = { ["Maneuver"] = true, ["Recover"] = true, ["Fall Back"] = true, ["Close In"] = true, ["Retreat"] = true, ["Transform"] = true, ["Eject"] = true, ["Titan Recover"] = true, ["Charge"] = true, ["Advance"] = true }

local function CreateMinimalButton(parent, text, size, baseColorHex)
	local btn = Instance.new("TextButton", parent); btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Text = text
	local cColor = Color3.fromHex(baseColorHex:gsub("#", "")); btn.TextColor3 = cColor
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(45, 45, 50); stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.InputBegan:Connect(function() if btn.Active then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play(); stroke.Color = cColor end end)
	btn.InputEnded:Connect(function() if btn.Active then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play(); stroke.Color = Color3.fromRGB(45, 45, 50) end end)
	return btn
end

local function CreateFlatBar(parent, title, colorHex, pos, size, alignRight, baseZ)
	baseZ = baseZ or 1; local cColor = Color3.fromHex(colorHex:gsub("#", "")); local shadowColor = Color3.new(cColor.R * 0.4, cColor.G * 0.4, cColor.B * 0.4)
	local container = Instance.new("Frame", parent); container.Size = size; container.Position = pos; container.BackgroundColor3 = Color3.fromRGB(12, 12, 15); container.BorderSizePixel = 0; container.ZIndex = baseZ
	local strk = Instance.new("UIStroke", container); strk.Color = Color3.fromRGB(40, 40, 45); strk.Thickness = 1; strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local fill = Instance.new("Frame", container); fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); fill.BorderSizePixel = 0; fill.ZIndex = baseZ + 1
	if alignRight then fill.AnchorPoint = Vector2.new(1, 0); fill.Position = UDim2.new(1, 0, 0, 0) end
	local grad = Instance.new("UIGradient", fill); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, cColor), ColorSequenceKeypoint.new(1, shadowColor)}; grad.Rotation = 90
	local txt = UIHelpers.CreateLabel(container, title .. " 100/100", UDim2.new(1, -6, 1, 0), Enum.Font.GothamBold, Color3.fromRGB(240, 240, 240), 9)
	if alignRight then txt.TextXAlignment = Enum.TextXAlignment.Right else txt.TextXAlignment = Enum.TextXAlignment.Left; txt.Position = UDim2.new(0, 6, 0, 0) end
	txt.ZIndex = baseZ + 2; return fill, txt, container
end

local function BuildMobileGUI()
	GUI = {}
	GUI.CombatBackdrop = Instance.new("TextButton", MasterGui); GUI.CombatBackdrop.Size = UDim2.new(1, 0, 1, 0); GUI.CombatBackdrop.BackgroundColor3 = Color3.new(0, 0, 0); GUI.CombatBackdrop.BackgroundTransparency = 1; GUI.CombatBackdrop.Text = ""; GUI.CombatBackdrop.AutoButtonColor = false; GUI.CombatBackdrop.Visible = false; GUI.CombatBackdrop.ZIndex = 98; GUI.CombatBackdrop.Active = true

	-- [[ THE FIX: Replaced Position with a secure UIScale Pop-In! ]]
	GUI.CombatWindow = Instance.new("Frame", MasterGui); GUI.CombatWindow.Size = UDim2.new(1, 0, 1, 0); GUI.CombatWindow.Position = UDim2.new(0, 0, 0, 0); GUI.CombatWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 18); GUI.CombatWindow.Visible = false; GUI.CombatWindow.ZIndex = 100
	GUI.WindowScale = Instance.new("UIScale", GUI.CombatWindow); GUI.WindowScale.Scale = 0

	GUI.CombatantsFrame = Instance.new("Frame", GUI.CombatWindow); GUI.CombatantsFrame.Size = UDim2.new(1, 0, 0, 60); GUI.CombatantsFrame.Position = UDim2.new(0, 0, 0, 10); GUI.CombatantsFrame.BackgroundTransparency = 1

	GUI.PlayerPanel = Instance.new("Frame", GUI.CombatantsFrame); GUI.PlayerPanel.Size = UDim2.new(0.45, 0, 1, 0); GUI.PlayerPanel.Position = UDim2.new(0, 10, 0, 0); GUI.PlayerPanel.BackgroundTransparency = 1
	GUI.pAvatar = Instance.new("ImageLabel", GUI.PlayerPanel); GUI.pAvatar.Size = UDim2.new(0, 45, 0, 45); GUI.pAvatar.Position = UDim2.new(0, 0, 0, 0); GUI.pAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12); Instance.new("UICorner", GUI.pAvatar).CornerRadius = UDim.new(1,0); local pStrk = Instance.new("UIStroke", GUI.pAvatar); pStrk.Color = Color3.fromRGB(85, 170, 255); pStrk.Thickness = 1
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420); GUI.pAvatar.Image = isReady and content or ""
	GUI.pHPBar, GUI.pHPText = CreateFlatBar(GUI.PlayerPanel, "HP", "#44DD44", UDim2.new(0, 55, 0, 5), UDim2.new(1, -55, 0, 12), false, 1)
	GUI.pGasBar, GUI.pGasText = CreateFlatBar(GUI.PlayerPanel, "GAS", "#AADDDD", UDim2.new(0, 55, 0, 22), UDim2.new(1, -55, 0, 12), false, 1)

	GUI.EnemyPanel = Instance.new("Frame", GUI.CombatantsFrame); GUI.EnemyPanel.Size = UDim2.new(0.45, 0, 1, 0); GUI.EnemyPanel.Position = UDim2.new(1, -10, 0, 0); GUI.EnemyPanel.AnchorPoint = Vector2.new(1, 0); GUI.EnemyPanel.BackgroundTransparency = 1
	GUI.eAvatar = Instance.new("ImageLabel", GUI.EnemyPanel); GUI.eAvatar.Size = UDim2.new(0, 45, 0, 45); GUI.eAvatar.Position = UDim2.new(1, 0, 0, 0); GUI.eAvatar.AnchorPoint = Vector2.new(1, 0); GUI.eAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12); Instance.new("UICorner", GUI.eAvatar).CornerRadius = UDim.new(1,0); local eStrk = Instance.new("UIStroke", GUI.eAvatar); eStrk.Color = Color3.fromRGB(255, 85, 85); eStrk.Thickness = 1
	GUI.eNameLbl = UIHelpers.CreateLabel(GUI.EnemyPanel, "UNKNOWN", UDim2.new(1, -55, 0, 15), Enum.Font.GothamBlack, Color3.fromRGB(255, 100, 100), 10); GUI.eNameLbl.Position = UDim2.new(0, 0, 0, 0); GUI.eNameLbl.TextXAlignment = Enum.TextXAlignment.Right
	GUI.eHPBar, GUI.eHPText, GUI.eHPContainer = CreateFlatBar(GUI.EnemyPanel, "HP", "#DD4444", UDim2.new(0, 0, 0, 18), UDim2.new(1, -55, 0, 12), true, 1)

	GUI.LogContainer = Instance.new("Frame", GUI.CombatWindow); GUI.LogContainer.Size = UDim2.new(0.45, 0, 1, -80); GUI.LogContainer.Position = UDim2.new(0, 10, 1, -10); GUI.LogContainer.AnchorPoint = Vector2.new(0, 1); GUI.LogContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Instance.new("UIStroke", GUI.LogContainer).Color = Color3.fromRGB(45, 45, 50)
	GUI.LogScroll = Instance.new("ScrollingFrame", GUI.LogContainer); GUI.LogScroll.Size = UDim2.new(1, -10, 1, -10); GUI.LogScroll.Position = UDim2.new(0, 5, 0, 5); GUI.LogScroll.BackgroundTransparency = 1; GUI.LogScroll.ScrollBarThickness = 4; GUI.LogScroll.BorderSizePixel = 0
	local logLayout = Instance.new("UIListLayout", GUI.LogScroll); logLayout.Padding = UDim.new(0, 4); logLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() GUI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10); GUI.LogScroll.CanvasPosition = Vector2.new(0, GUI.LogScroll.CanvasSize.Y.Offset) end)

	GUI.ActionContainer = Instance.new("Frame", GUI.CombatWindow); GUI.ActionContainer.Size = UDim2.new(0.5, 0, 1, -80); GUI.ActionContainer.Position = UDim2.new(1, -10, 1, -10); GUI.ActionContainer.AnchorPoint = Vector2.new(1, 1); GUI.ActionContainer.BackgroundTransparency = 1
	GUI.ActionGrid = Instance.new("ScrollingFrame", GUI.ActionContainer); GUI.ActionGrid.Size = UDim2.new(1, 0, 1, 0); GUI.ActionGrid.BackgroundTransparency = 1; GUI.ActionGrid.ScrollBarThickness = 0
	local acLayout = Instance.new("UIGridLayout", GUI.ActionGrid); acLayout.CellSize = UDim2.new(0.48, 0, 0, 35); acLayout.CellPadding = UDim2.new(0.03, 0, 0, 8); acLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; acLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	GUI.TargetMenu = Instance.new("Frame", GUI.ActionContainer); GUI.TargetMenu.Size = UDim2.new(1, 0, 1, 0); GUI.TargetMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 18); GUI.TargetMenu.Visible = false; Instance.new("UIStroke", GUI.TargetMenu).Color = Color3.fromRGB(40, 40, 45)
	local tmLayout = Instance.new("UIGridLayout", GUI.TargetMenu); tmLayout.CellSize = UDim2.new(0.48, 0, 0, 45); tmLayout.CellPadding = UDim2.new(0.04, 0, 0, 10); tmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tmLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	GUI.Limbs = {}
	local function AddTargetBtn(id, label, color) local btn = CreateMinimalButton(GUI.TargetMenu, label, UDim2.new(0,0,0,0), color); GUI.Limbs[id] = btn end
	AddTargetBtn("Eyes", "EYES", "#7878B4"); AddTargetBtn("Nape", "NAPE", "#DC5050"); AddTargetBtn("Body", "BODY", "#50A050"); AddTargetBtn("LArm", "LEFT ARM", "#B48C3C"); AddTargetBtn("RArm", "RIGHT ARM", "#B48C3C"); AddTargetBtn("LLeg", "LEFT LEG", "#508CB4"); AddTargetBtn("RLeg", "RIGHT LEG", "#508CB4")
	GUI.CancelBtn = CreateMinimalButton(GUI.TargetMenu, "CANCEL", UDim2.new(0,0,0,0), "#FF5555")

	GUI.ExecuteOverlay = Instance.new("Frame", GUI.CombatWindow); GUI.ExecuteOverlay.Size = UDim2.new(1, 0, 1, 0); GUI.ExecuteOverlay.BackgroundColor3 = Color3.new(0, 0, 0); GUI.ExecuteOverlay.BackgroundTransparency = 0.3; GUI.ExecuteOverlay.ZIndex = 150; GUI.ExecuteOverlay.Visible = false
	GUI.ExecuteBanner = Instance.new("TextButton", GUI.ExecuteOverlay); GUI.ExecuteBanner.Size = UDim2.new(1, 0, 0, 60); GUI.ExecuteBanner.Position = UDim2.new(0.5, 0, 0.5, 0); GUI.ExecuteBanner.AnchorPoint = Vector2.new(0.5, 0.5); GUI.ExecuteBanner.BackgroundColor3 = Color3.fromRGB(15, 10, 10); GUI.ExecuteBanner.BorderSizePixel = 0; GUI.ExecuteBanner.AutoButtonColor = false; GUI.ExecuteBanner.Text = ""; GUI.ExecuteBanner.ZIndex = 151; Instance.new("UIStroke", GUI.ExecuteBanner).Color = Color3.fromRGB(100, 0, 0)
	local exGrad = Instance.new("UIGradient", GUI.ExecuteBanner); exGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 5, 5)), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}; exGrad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(0.8, 0.2), NumberSequenceKeypoint.new(1, 1)}
	GUI.ExecuteText = UIHelpers.CreateLabel(GUI.ExecuteBanner, "SEVER", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, Color3.fromRGB(200, 200, 200), 32); GUI.ExecuteText.ZIndex = 152
end

local function AppendLog(message, colorHex)
	if not GUI or not GUI.LogScroll or not message or message == "" then return end
	local logColor = colorHex and Color3.fromHex(colorHex:gsub("#", "")) or UIHelpers.Colors.TextWhite
	local panel = Instance.new("Frame", GUI.LogScroll); panel.Size = UDim2.new(1, 0, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18); panel.BackgroundTransparency = 0.3; panel.BorderSizePixel = 0; panel.AutomaticSize = Enum.AutomaticSize.Y
	local pStroke = Instance.new("UIStroke", panel); pStroke.Color = Color3.fromRGB(40, 40, 45); pStroke.Thickness = 1
	local pad = Instance.new("UIPadding", panel); pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6); pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)
	local lbl = UIHelpers.CreateLabel(panel, message, UDim2.new(1, 0, 0, 0), Enum.Font.GothamMedium, logColor, 10); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextWrapped = true; lbl.AutomaticSize = Enum.AutomaticSize.Y

	local children = GUI.LogScroll:GetChildren(); local logCount = 0; for _, c in ipairs(children) do if c:IsA("Frame") then logCount += 1 end end
	if logCount > 30 then for _, c in ipairs(children) do if c:IsA("Frame") then c:Destroy() break end end end
end

local function UpdateState(data)
	if not data or not data.Battle or not GUI then return end
	currentBattleState = data.Battle; local battle = data.Battle
	local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

	if battle.Player then
		local safeHP = math.max(0, battle.Player.HP or 0); local maxHP = battle.Player.MaxHP or 100
		GUI.pHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(maxHP)
		TweenService:Create(GUI.pHPBar, tInfo, {Size = UDim2.new(maxHP > 0 and (safeHP / maxHP) or 0, 0, 1, 0)}):Play()
		local gas = battle.Player.Gas or 0; local maxGas = battle.Player.MaxGas or 50
		GUI.pGasText.Text = "GAS " .. math.floor(gas) .. "/" .. math.floor(maxGas)
		TweenService:Create(GUI.pGasBar, tInfo, {Size = UDim2.new(maxGas > 0 and (gas / maxGas) or 0, 0, 1, 0)}):Play()
	end

	if battle.Enemy then 
		GUI.eNameLbl.Text = (battle.Enemy.Name or "UNKNOWN"):upper() 
		GUI.eHPText.Parent.Visible = true
		local safeHP = math.max(0, battle.Enemy.HP or 0); local maxHP = battle.Enemy.MaxHP or 100
		GUI.eHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(maxHP)
		TweenService:Create(GUI.eHPBar, tInfo, {Size = UDim2.new(maxHP > 0 and (safeHP / maxHP) or 0, 0, 1, 0)}):Play()
	end
end

local function UpdateSkills()
	inputLocked = false
	if GUI.ActionGrid then GUI.ActionGrid.Visible = true; for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end end
	if GUI.TargetMenu then GUI.TargetMenu.Visible = false end

	local currentRange = "Close"; local pState = currentBattleState and currentBattleState.Player or nil
	if currentBattleState and currentBattleState.Context and currentBattleState.Context.Range then currentRange = currentBattleState.Context.Range end
	local isTransformed = pState and pState.Statuses and pState.Statuses["Transformed"]
	local fallbacks = {"Basic Slash", "Heavy Slash", "None", "None"}

	local function CreateSkillButton(skillName, customLabel, baseColor)
		if skillName == "None" or not GUI.ActionGrid then return end
		local btnText = customLabel or string.upper(skillName); local btnColor = baseColor or "#DDDDDD"
		local btn = CreateMinimalButton(GUI.ActionGrid, btnText, UDim2.new(0, 0, 0, 0), btnColor)

		btn.MouseButton1Click:Connect(function()
			if inputLocked then return end; inputLocked = true 
			if InstantSkills[skillName] then
				for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				UIHelpers.CreateLabel(GUI.ActionGrid, "EXECUTING...", UDim2.new(0, 150, 0, 35), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12)
				Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = skillName})
			else
				pendingSkillName = skillName
				Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = pendingSkillName, TargetLimb = "Body"})
				pendingSkillName = nil
			end
		end)
	end

	for i = 1, 4 do local skillName = player:GetAttribute("EquippedSkill_" .. i); if not skillName or skillName == "" or skillName == "None" then skillName = fallbacks[i] end; CreateSkillButton(skillName) end
	CreateSkillButton("Maneuver", "MANEUVER", "#55AAFF")
	CreateSkillButton("Recover", "RECOVER", "#55FF55")
	if currentRange == "Close" then CreateSkillButton("Fall Back", "FALL BACK", "#FFAA55") else CreateSkillButton("Close In", "CLOSE IN", "#FFAA55") end
	CreateSkillButton("Retreat", "FLEE", "#FF5555")
end

local function ShowUI(data)
	inputLocked = false
	if GUI.CombatBackdrop then GUI.CombatBackdrop.Visible = true; TweenService:Create(GUI.CombatBackdrop, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play() end

	-- [[ THE FIX: Bulletproof UIScale Pop-In! Never renders off screen! ]]
	if GUI.CombatWindow then 
		GUI.CombatWindow.Visible = true 
		TweenService:Create(GUI.WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end

	if GUI.LogScroll then for _, c in ipairs(GUI.LogScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
	AppendLog("<b>[SYSTEM] Tactical Engagement Initiated.</b>", "#FFD700")
	if data and data.LogMsg then AppendLog(data.LogMsg) end
	if data and data.Battle then UpdateState(data) end
	UpdateSkills()
end

local function CloseUI()
	inputLocked = true
	-- [[ THE FIX: Smooth Scale-Out Transition ]]
	if GUI.CombatWindow then 
		local t1 = TweenService:Create(GUI.WindowScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
		t1:Play(); t1.Completed:Wait(); GUI.CombatWindow.Visible = false 
	end
	if GUI.CombatBackdrop then GUI.CombatBackdrop.Visible = false end
	currentBattleState = nil
end

function MobileCombatUI.Initialize(masterScreenGui)
	MasterGui = masterScreenGui; BuildMobileGUI()
	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		local success, err = pcall(function()
			if action == "Start" or action == "StartMinigame" then ShowUI(data)
			elseif action == "Update" then UpdateState(data); UpdateSkills()
			elseif action == "TurnStrike" then UpdateState(data); if type(data.LogMsg) == "string" and data.LogMsg ~= "" then AppendLog(data.LogMsg, data.IsPlayerAttacking and "#55AAFF" or "#FF5555") end
			elseif action == "WaveComplete" or action == "Victory" then
				UpdateState(data); AppendLog(action == "Victory" and "<b><font color='#55FF55'>VICTORY!</font></b>" or "<b><font color='#55FF55'>WAVE CLEARED!</font></b>", "#55FF55")
				if data and type(data.LogMsg) == "string" and data.LogMsg ~= "" then AppendLog(data.LogMsg, "#FFD700") end
				inputLocked = true
				if GUI.ActionGrid then 
					for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end; GUI.ActionGrid.Visible = true 
					if action == "WaveComplete" then
						local continueBtn = CreateMinimalButton(GUI.ActionGrid, "CONTINUE", UDim2.new(0, 0, 0, 0), "#55FF55"); continueBtn.MouseButton1Click:Connect(function() UpdateSkills() end)
					else
						local closeBtn = CreateMinimalButton(GUI.ActionGrid, "RETURN", UDim2.new(0, 0, 0, 0), "#55FF55"); closeBtn.MouseButton1Click:Connect(function() CloseUI() end)
					end
				end
			elseif action == "Defeat" or action == "PathsDeath" or action == "Fled" then
				UpdateState(data); AppendLog(action == "Fled" and "<b><font color='#AAAAAA'>YOU FLED.</font></b>" or "<b><font color='#FF5555'>DEFEAT...</font></b>", action == "Fled" and "#AAAAAA" or "#FF5555")
				inputLocked = true
				if GUI.ActionGrid then 
					for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end; GUI.ActionGrid.Visible = true 
					local closeBtn = CreateMinimalButton(GUI.ActionGrid, "RETURN", UDim2.new(0, 0, 0, 0), "#FF5555"); closeBtn.MouseButton1Click:Connect(function() CloseUI() end) 
				end
			elseif action == "ExecutionPhase" then
				UpdateState(data); inputLocked = true
				if GUI.ActionGrid then GUI.ActionGrid.Visible = false end
				if GUI.ExecuteOverlay then GUI.ExecuteOverlay.Visible = true end
				GUI.ExecuteBanner.MouseButton1Click:Connect(function() GUI.ExecuteOverlay.Visible = false; Network:WaitForChild("CombatAction"):FireServer("ExecutionComplete") end)
			end
		end)
	end)
end

return MobileCombatUI