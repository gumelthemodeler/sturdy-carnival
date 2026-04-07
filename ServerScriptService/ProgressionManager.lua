-- @ScriptType: Script
-- @ScriptType: Script
-- Name: ProgressionManager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local AdminManager = require(ReplicatedStorage:WaitForChild("AdminManager"))
local CosmeticData = require(ReplicatedStorage:WaitForChild("CosmeticData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData")) 
local Network = ReplicatedStorage:WaitForChild("Network")
local NotificationEvent = Network:WaitForChild("NotificationEvent")

local AdminCommand = Network:FindFirstChild("AdminCommand") or Instance.new("RemoteEvent", Network)
AdminCommand.Name = "AdminCommand"

AdminCommand.OnServerEvent:Connect(function(player, command, targetStr, args)
	if not AdminManager.IsAdmin(player) then
		player:Kick("Unauthorized Admin Access")
		return
	end

	local target = player
	if targetStr and targetStr ~= "Self" and targetStr ~= "All" then
		target = Players:FindFirstChild(targetStr) or player
	end

	if command == "MaxStats" then
		local ls = target:FindFirstChild("leaderstats")
		local pPrestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0
		local cap = GameData.GetStatCap(pPrestige)
		local stats = {"Health", "Gas", "Strength", "Defense", "Speed", "Resolve", "Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}
		for _, s in ipairs(stats) do target:SetAttribute(s, cap) end
		NotificationEvent:FireClient(player, "Maxed stats for " .. target.Name, "Success")

	elseif command == "SetXP" or command == "GiveXP" then
		target:SetAttribute("XP", tonumber(args) or 100000)
		NotificationEvent:FireClient(player, "Given XP to " .. target.Name, "Success")

	elseif command == "SetTitanXP" or command == "GiveTitanXP" then
		target:SetAttribute("TitanXP", tonumber(args) or 100000)
		NotificationEvent:FireClient(player, "Given Titan XP to " .. target.Name, "Success")

	elseif command == "SetDews" or command == "GiveDews" then
		local ls = target:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Dews") then
			ls.Dews.Value = ls.Dews.Value + (tonumber(args) or 100000)
		end
		NotificationEvent:FireClient(player, "Given Dews to " .. target.Name, "Success")

	elseif command == "GiveItem" then
		local itemName = tostring(args)
		local safeName = itemName:gsub("[^%w]", "") .. "Count"
		target:SetAttribute(safeName, (target:GetAttribute(safeName) or 0) + 1)
		NotificationEvent:FireClient(player, "Spawned " .. itemName, "Success")
	end
end)

local EquipCosmetic = Network:FindFirstChild("EquipCosmetic") or Instance.new("RemoteEvent", Network)
EquipCosmetic.Name = "EquipCosmetic"
local equipDebounce = {}

EquipCosmetic.OnServerEvent:Connect(function(player, typeKey, itemKey)
	if equipDebounce[player.UserId] then return end
	equipDebounce[player.UserId] = true

	local dataPool = typeKey == "Title" and CosmeticData.Titles or CosmeticData.Auras
	local cData = dataPool[itemKey]

	local currentEquipped = player:GetAttribute("Equipped" .. typeKey) or (typeKey == "Title" and "Cadet" or "None")

	if currentEquipped ~= itemKey then
		if cData and CosmeticData.CheckUnlock(player, cData.ReqType, cData.ReqValue) then
			player:SetAttribute("Equipped" .. typeKey, itemKey)
			NotificationEvent:FireClient(player, "Equipped " .. cData.Name .. "!", "Success")
		else
			NotificationEvent:FireClient(player, "Failed to equip cosmetic.", "Error")
		end
	end

	task.delay(0.25, function()
		equipDebounce[player.UserId] = nil
	end)
end)

local EquipSkill = Network:FindFirstChild("EquipSkill") or Instance.new("RemoteEvent", Network)
EquipSkill.Name = "EquipSkill"

EquipSkill.OnServerEvent:Connect(function(player, slotIndex, skillName)
	slotIndex = tonumber(slotIndex)
	if not slotIndex or slotIndex < 1 or slotIndex > 4 then return end

	if not SkillData.Skills[skillName] then return end

	for i = 1, 4 do
		if player:GetAttribute("EquippedSkill_" .. i) == skillName then
			NotificationEvent:FireClient(player, "Skill already equipped in slot " .. i .. "!", "Error")
			return
		end
	end

	player:SetAttribute("EquippedSkill_" .. slotIndex, skillName)
	NotificationEvent:FireClient(player, skillName .. " mapped to Slot " .. slotIndex .. "!", "Success")
end)

Network:WaitForChild("TrainAction").OnServerEvent:Connect(function(player, combo, isTitan)
	combo = tonumber(combo) or 0
	combo = math.clamp(combo, 0, 150)

	-- SAFELY CHECK LEADERSTATS
	local ls = player:FindFirstChild("leaderstats")
	local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

	local totalStats = (player:GetAttribute("Strength") or 10) + (player:GetAttribute("Defense") or 10) + (player:GetAttribute("Speed") or 10) + (player:GetAttribute("Resolve") or 10)
	local baseXP = 1 + (prestige * 50) + math.floor(totalStats / 4)
	local xpGain = math.floor(baseXP * (1.0 + (combo * 0.02)))
	local targetAttr = isTitan and "TitanXP" or "XP"
	player:SetAttribute(targetAttr, (player:GetAttribute(targetAttr) or 0) + xpGain)
end)

Network:WaitForChild("UpgradeStat").OnServerEvent:Connect(function(player, statName, amount)
	local validStats = {
		["Health"]=true, ["Gas"]=true, ["Strength"]=true, ["Defense"]=true, ["Speed"]=true, ["Resolve"]=true, 
		["Titan_Power_Val"]=true, ["Titan_Speed_Val"]=true, ["Titan_Hardening_Val"]=true, 
		["Titan_Endurance_Val"]=true, ["Titan_Precision_Val"]=true, ["Titan_Potential_Val"]=true
	}
	if not validStats[statName] then return end

	amount = math.clamp(tonumber(amount) or 1, 1, 100)
	local isTitanStat = string.match(statName, "Titan_.*_Val$")
	local xpAttr = isTitanStat and "TitanXP" or "XP"

	local currentStat = player:GetAttribute(statName) or 10
	if type(currentStat) == "string" then currentStat = GameData.TitanRanks[currentStat] or 10 end

	-- SAFELY CHECK LEADERSTATS
	local ls = player:FindFirstChild("leaderstats")
	local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

	local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
	local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 10) or (prestige * 5)
	local statCap = GameData.GetStatCap(prestige)

	local totalCost = 0
	local pXP = player:GetAttribute(xpAttr) or 0
	for i = 0, amount - 1 do
		if currentStat + i >= statCap then break end
		totalCost += GameData.CalculateStatCost(currentStat + i, base, prestige)
	end

	if pXP >= totalCost and totalCost > 0 then
		player:SetAttribute(xpAttr, pXP - totalCost)
		player:SetAttribute(statName, currentStat + amount)
	end
end)

local UnlockPrestigeNode = Network:FindFirstChild("UnlockPrestigeNode") or Instance.new("RemoteEvent", Network)
UnlockPrestigeNode.Name = "UnlockPrestigeNode"
local ActivePrestigeTransactions = {}

UnlockPrestigeNode.OnServerEvent:Connect(function(player, nodeId)
	if ActivePrestigeTransactions[player.UserId] then return end
	ActivePrestigeTransactions[player.UserId] = true

	local node = GameData.PrestigeNodes[nodeId]
	if not node then ActivePrestigeTransactions[player.UserId] = nil; return end

	if player:GetAttribute("PrestigeNode_" .. nodeId) then
		NotificationEvent:FireClient(player, "You already own this talent!", "Error")
		ActivePrestigeTransactions[player.UserId] = nil; return
	end

	local points = player:GetAttribute("PrestigePoints") or 0
	if points < node.Cost then
		NotificationEvent:FireClient(player, "Not enough Prestige Points!", "Error")
		ActivePrestigeTransactions[player.UserId] = nil; return
	end

	if node.Req and not player:GetAttribute("PrestigeNode_" .. node.Req) then
		NotificationEvent:FireClient(player, "You must unlock the previous node first!", "Error")
		ActivePrestigeTransactions[player.UserId] = nil; return
	end

	player:SetAttribute("PrestigePoints", points - node.Cost)
	player:SetAttribute("PrestigeNode_" .. nodeId, true)

	if node.BuffType == "FlatStat" then
		player:SetAttribute(node.BuffStat, (player:GetAttribute(node.BuffStat) or 10) + node.BuffValue)
	elseif node.BuffType == "Special" then
		player:SetAttribute("Prestige_" .. node.BuffStat, (player:GetAttribute("Prestige_" .. node.BuffStat) or 0) + node.BuffValue)
	end

	NotificationEvent:FireClient(player, "Unlocked " .. node.Name .. "!", "Success")
	task.wait(0.2); ActivePrestigeTransactions[player.UserId] = nil
end)

local PrestigeAction = Network:FindFirstChild("PrestigeAction") or Instance.new("RemoteFunction", Network)
PrestigeAction.Name = "PrestigeAction"

PrestigeAction.OnServerInvoke = function(player)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	if currentPart >= 8 then
		-- SAFELY CHECK LEADERSTATS
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Prestige") then ls.Prestige.Value += 1 end

		player:SetAttribute("CurrentPart", 1)
		player:SetAttribute("CurrentWave", 1)
		player:SetAttribute("PathsFloor", 1)
		player:SetAttribute("PrestigePoints", (player:GetAttribute("PrestigePoints") or 0) + 1)
		NotificationEvent:FireClient(player, "You have Prestiged! +1 Prestige Point acquired!", "Success")
		return true
	else
		NotificationEvent:FireClient(player, "You must clear the Campaign (Part 8) before you can Prestige!", "Error")
		return false
	end
end

-- Passive Auto-Training for Gamepass Owners
task.spawn(function()
	while task.wait(5) do
		for _, p in ipairs(Players:GetPlayers()) do
			-- Check if they have the Gamepass or are the specific developer ID
			if p:GetAttribute("HasAutoTrain") or p.UserId == 4068160397 then
				-- SAFELY CHECK LEADERSTATS
				local ls = p:FindFirstChild("leaderstats")
				local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

				local totalStats = (p:GetAttribute("Strength") or 10) + (p:GetAttribute("Defense") or 10) + (p:GetAttribute("Speed") or 10) + (p:GetAttribute("Resolve") or 10)

				-- Base passive generation formula
				local baseXP = 1 + (prestige * 50) + math.floor(totalStats / 4)
				local xpGain = math.floor(baseXP * 1.5) 

				if p:GetAttribute("HasDoubleXP") then xpGain *= 2 end

				-- Distribute Soldier XP
				p:SetAttribute("XP", (p:GetAttribute("XP") or 0) + xpGain)

				-- If they own a Titan, distribute Titan XP passively as well
				if p:GetAttribute("Titan") and p:GetAttribute("Titan") ~= "None" then
					p:SetAttribute("TitanXP", (p:GetAttribute("TitanXP") or 0) + xpGain)
				end
			end
		end
	end
end)