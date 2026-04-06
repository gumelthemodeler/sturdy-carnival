-- @ScriptType: LocalScript
-- Name: ClientMain
-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")

-- Disable default Roblox UI except Chat
task.spawn(function()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end)
end)

local MasterGui = Instance.new("ScreenGui")
MasterGui.Name = "AoTMasterGui"
MasterGui.ResetOnSpawn = false
MasterGui.IgnoreGuiInset = true
MasterGui.Parent = playerGui

print("[AoT UI] Booting Main Interface...")

-- [[ THE FIX: Roblox Studio Emulator Detection ]]
local isMobile = false

if RunService:IsStudio() then
	-- In Studio, 'MouseEnabled' is always true. We check if the viewport height is small (like a phone).
	local camera = workspace.CurrentCamera
	if camera and (camera.ViewportSize.Y <= 600 or UserInputService.TouchEnabled) then
		isMobile = true
	end
else
	-- In the live game, true mobile devices have Touch but NO Mouse.
	isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- [[ MANUAL OVERRIDE ]]
-- If the emulator STILL fights you, just uncomment the exact line below to force it:
-- isMobile = true

if isMobile then
	print("[AoT UI] Mobile Device Detected. Booting Mobile Framework...")
	local MobileModules = playerScripts:WaitForChild("MobileModules")
	local MobileMainUI = require(MobileModules:WaitForChild("MobileMainUI"))
	MobileMainUI.Initialize(MasterGui)
else
	print("[AoT UI] PC Device Detected. Booting Standard Framework...")
	local UIModules = playerScripts:WaitForChild("UIModules")
	local MainUI = require(UIModules:WaitForChild("MainUI"))
	MainUI.Initialize(MasterGui)
end