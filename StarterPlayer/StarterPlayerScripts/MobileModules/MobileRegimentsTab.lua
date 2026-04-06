-- @ScriptType: ModuleScript
-- Name: MobileRegimentsTab
-- @ScriptType: ModuleScript
local MobileRegimentsTab = {}
local Players = game:GetService("Players"); local ReplicatedStorage = game:GetService("ReplicatedStorage"); local TweenService = game:GetService("TweenService"); local Network = ReplicatedStorage:WaitForChild("Network")
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts"); local SharedUI = playerScripts:WaitForChild("SharedUI")
local UIHelpers = require(SharedUI:WaitForChild("UIHelpers")); local RegimentData = require(ReplicatedStorage:WaitForChild("RegimentData")); local NotificationManager = require(SharedUI:WaitForChild("NotificationManager"))
local player = Players.LocalPlayer

local function AbbreviateNumber(n)
	if not n then return "0" end; n = tonumber(n) or 0
	if n >= 1e6 then return string.format("%.1fM", n/1e6) elseif n >= 1e3 then return string.format("%.1fK", n/1e3) else return tostring(n) end
end

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22); frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent); btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34); btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Font = font; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btn.TextSize = textSize; btn.Text = text
	local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(70, 70, 80); stroke.Thickness = 2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btn.InputBegan:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.InputEnded:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

function MobileRegimentsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end

	local MainScroll = Instance.new("ScrollingFrame", parentFrame)
	MainScroll.Size = UDim2.new(1, 0, 1, 0); MainScroll.BackgroundTransparency = 1; MainScroll.ScrollBarThickness = 8; MainScroll.BorderSizePixel = 0; MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local mLayout = Instance.new("UIListLayout", MainScroll); mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 15); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", MainScroll).PaddingTop = UDim.new(0, 15); Instance.new("UIPadding", MainScroll).PaddingBottom = UDim.new(0, 20)

	local Title = UIHelpers.CreateLabel(MainScroll, "REGIMENTAL COMMAND", UDim2.new(0.95, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); Title.LayoutOrder = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

	local ActiveRegPanel, _ = CreateGrimPanel(MainScroll)
	ActiveRegPanel.Size = UDim2.new(0.95, 0, 0, 160); ActiveRegPanel.LayoutOrder = 2

	local curIcon = Instance.new("ImageLabel", ActiveRegPanel); curIcon.Size = UDim2.new(0, 90, 0, 90); curIcon.Position = UDim2.new(0, 15, 0.5, 0); curIcon.AnchorPoint = Vector2.new(0, 0.5); curIcon.BackgroundTransparency = 1
	local curName = UIHelpers.CreateLabel(ActiveRegPanel, "CADET CORPS", UDim2.new(1, -120, 0, 25), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 18); curName.Position = UDim2.new(0, 110, 0, 15); curName.TextXAlignment = Enum.TextXAlignment.Left
	local curDesc = UIHelpers.CreateLabel(ActiveRegPanel, "Unassigned.", UDim2.new(1, -120, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 11); curDesc.Position = UDim2.new(0, 110, 0, 40); curDesc.TextXAlignment = Enum.TextXAlignment.Left; curDesc.TextWrapped = true; curDesc.TextYAlignment = Enum.TextYAlignment.Top

	local LeaveBtn, lStroke = CreateSharpButton(ActiveRegPanel, "LEAVE REGIMENT", UDim2.new(0.4, 0, 0, 35), Enum.Font.GothamBlack, 11)
	LeaveBtn.Position = UDim2.new(1, -15, 1, -15); LeaveBtn.AnchorPoint = Vector2.new(1, 1); LeaveBtn.TextColor3 = Color3.fromRGB(255, 100, 100); lStroke.Color = Color3.fromRGB(255, 100, 100)

	local RegList = Instance.new("Frame", MainScroll)
	RegList.Size = UDim2.new(0.95, 0, 0, 0); RegList.AutomaticSize = Enum.AutomaticSize.Y; RegList.BackgroundTransparency = 1; RegList.LayoutOrder = 3
	local rLayout = Instance.new("UIListLayout", RegList); rLayout.Padding = UDim.new(0, 10); rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- [[ THE FIX: Regiment Price Formatting added ]]
	for regName, rData in pairs(RegimentData.Regiments or {}) do
		if regName == "Cadet Corps" then continue end
		local themeStr = rData.ThemeColor or "#FFFFFF"; local cTheme = Color3.fromHex(themeStr:gsub("#", ""))
		local card, stroke = CreateGrimPanel(RegList); card.Size = UDim2.new(1, 0, 0, 90); stroke.Color = cTheme

		local rIcon = Instance.new("ImageLabel", card); rIcon.Size = UDim2.new(0, 70, 0, 70); rIcon.Position = UDim2.new(0, 10, 0.5, 0); rIcon.AnchorPoint = Vector2.new(0, 0.5); rIcon.BackgroundTransparency = 1; rIcon.Image = rData.Icon or ""
		local rLbl = UIHelpers.CreateLabel(card, regName:upper(), UDim2.new(1, -100, 0, 20), Enum.Font.GothamBlack, cTheme, 14); rLbl.Position = UDim2.new(0, 90, 0, 10); rLbl.TextXAlignment = Enum.TextXAlignment.Left
		local rBuff = UIHelpers.CreateLabel(card, rData.BuffDesc or "No additional bonuses.", UDim2.new(1, -100, 0, 25), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 10); rBuff.Position = UDim2.new(0, 90, 0, 30); rBuff.TextXAlignment = Enum.TextXAlignment.Left; rBuff.TextWrapped = true; rBuff.TextYAlignment = Enum.TextYAlignment.Top

		local cost = rData.Cost or 100000
		local JoinBtn, jStroke = CreateSharpButton(card, "JOIN (" .. AbbreviateNumber(cost) .. ")", UDim2.new(0, 100, 0, 30), Enum.Font.GothamBlack, 11)
		JoinBtn.Position = UDim2.new(1, -10, 0.5, 0); JoinBtn.AnchorPoint = Vector2.new(1, 0.5); JoinBtn.TextColor3 = cTheme; jStroke.Color = cTheme

		JoinBtn.MouseButton1Click:Connect(function() Network:WaitForChild("RegimentAction"):FireServer("Join", regName) end)
	end

	LeaveBtn.MouseButton1Click:Connect(function() Network:WaitForChild("RegimentAction"):FireServer("Leave") end)

	local function UpdateUI()
		local myReg = player:GetAttribute("Regiment") or "Cadet Corps"
		if RegimentData.Regiments and RegimentData.Regiments[myReg] then
			local rData = RegimentData.Regiments[myReg]; local themeStr = rData.ThemeColor or "#FFFFFF"
			curIcon.Image = rData.Icon or ""; curName.Text = myReg:upper(); curName.TextColor3 = Color3.fromHex(themeStr:gsub("#", ""))
			curDesc.Text = (rData.Desc or "No description.") .. "\n\n<font color='" .. themeStr .. "'>Bonus: " .. (rData.BuffDesc or "None") .. "</font>"; curDesc.RichText = true
		end
		if myReg == "Cadet Corps" then LeaveBtn.Visible = false else LeaveBtn.Visible = true end
	end
	player.AttributeChanged:Connect(function(attr) if attr == "Regiment" then UpdateUI() end end); UpdateUI()
end

return MobileRegimentsTab