-- @ScriptType: LocalScript
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
MasterGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling 
MasterGui.Parent = playerGui

print("[AoT UI] Booting Main Interface...")

-- [[ STRICT HARDWARE DETECTION ]]
local isMobile = false

-- True Mobile Devices have Touch but NO physical mouse.
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
	isMobile = true
end

-- [[ MANUAL OVERRIDE FOR STUDIO TESTING ]]
-- Since the Studio Device Emulator STILL has your physical mouse connected, 
-- it will load the PC UI. Uncomment the line below to force test Mobile in Studio:
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