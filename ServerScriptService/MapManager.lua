-- @ScriptType: Script
-- @ScriptType: Script
-- Name: MapManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Network") or Instance.new("Folder", ReplicatedStorage)
RemotesFolder.Name = "Network"

local function GetOrCreateEvent(name)
	local r = RemotesFolder:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = RemotesFolder end
	return r
end

local function GetOrCreateFunction(name)
	local r = RemotesFolder:FindFirstChild(name)
	if not r then r = Instance.new("RemoteFunction"); r.Name = name; r.Parent = RemotesFolder end
	return r
end

local MapAction = GetOrCreateEvent("MapAction")
local MapUpdate = GetOrCreateEvent("MapUpdate")
local NotificationEvent = GetOrCreateEvent("NotificationEvent")
local GetMapData = GetOrCreateFunction("GetMapData")

-- ==========================================
-- SQUAD IDENTIFICATION ENGINE
-- ==========================================
local function GetPlayerSquadContext(player)
	local getPartyFunc = RemotesFolder:FindFirstChild("GetPlayerParty")
	if getPartyFunc and getPartyFunc:IsA("BindableFunction") then
		local succ, partyData = pcall(function() return getPartyFunc:Invoke(player) end)
		if succ and partyData and type(partyData) == "table" and partyData.Leader then
			local isLeader = (partyData.Leader.UserId == player.UserId)
			return partyData.Leader.Name .. "'s Squad", isLeader
		end
	end

	-- Fallback: Solo player acts as commander of their own 1-man squad
	return player.Name .. "'s Squad", true
end

-- ==========================================
-- GLOBAL MAP STATE
-- ==========================================
local GlobalMapState = {}
local TOTAL_NODES = 25

for i = 1, TOTAL_NODES do
	GlobalMapState["N"..i] = {
		OwnerSquad = nil,     
		Health = 100,         
		MaxHealth = 100,
		FortificationLevel = 0,
		UnderAttack = false,
		AttackerType = "None" 
	}
end

local function BroadcastMapState()
	for _, p in ipairs(Players:GetPlayers()) do
		local clientState = {}
		local mySquad, _ = GetPlayerSquadContext(p)

		for nodeId, nodeData in pairs(GlobalMapState) do
			local isOwnedByMySquad = (mySquad ~= "None" and nodeData.OwnerSquad == mySquad)
			clientState[nodeId] = {
				Owned = isOwnedByMySquad,
				OwnerName = nodeData.OwnerSquad or "Unclaimed",
				UnderAttack = nodeData.UnderAttack,
				AttackerType = nodeData.AttackerType,
				Fortification = nodeData.FortificationLevel,
				Health = nodeData.Health,
				MaxHealth = nodeData.MaxHealth
			}
		end
		MapUpdate:FireClient(p, clientState)
	end
end

-- ==========================================
-- PVE INVASION ENGINE (The Living Map)
-- ==========================================
task.spawn(function()
	while true do
		task.wait(math.random(180, 400))

		local possibleTargets = {}
		for id, node in pairs(GlobalMapState) do table.insert(possibleTargets, id) end

		local targetId = possibleTargets[math.random(1, #possibleTargets)]
		local node = GlobalMapState[targetId]

		if not node.UnderAttack then
			node.UnderAttack = true
			node.AttackerType = (math.random(1,2) == 1) and "Bandits" or "Pure Titans"

			-- If unowned, hostile forces capture immediately. If owned, it enters danger state.
			if node.OwnerSquad == nil then
				node.OwnerSquad = node.AttackerType
				node.Health = 100
				node.FortificationLevel = 1
				node.UnderAttack = false
			else
				node.Health = math.max(1, node.Health - 20)
			end

			BroadcastMapState()
		end
	end
end)

-- ==========================================
-- INSTANT TACTICAL LOGIC (Fortify Only)
-- ==========================================
local function ProcessNodeInteraction(player, nodeId, actionType)
	local node = GlobalMapState[nodeId]
	if not node then return end

	local ls = player:FindFirstChild("leaderstats")
	if not ls or not ls:FindFirstChild("Dews") then return end

	local mySquad, isLeader = GetPlayerSquadContext(player)
	local FORTIFY_COST = 100000

	if mySquad == "None" then return end

	if actionType == "Fortify" then
		if node.OwnerSquad ~= mySquad then return end
		if not isLeader then
			NotificationEvent:FireClient(player, "Only the Squad Leader can authorize Fortifications.", "Error")
			return
		end
		if ls.Dews.Value >= FORTIFY_COST then
			ls.Dews.Value -= FORTIFY_COST
			node.FortificationLevel += 1
			node.MaxHealth += 50
			node.Health = node.MaxHealth
			node.UnderAttack = false
			node.AttackerType = "None"
			NotificationEvent:FireClient(player, "Garrison fortified to Level " .. node.FortificationLevel .. "!", "Success")
			BroadcastMapState()
		else
			NotificationEvent:FireClient(player, "Not enough Dews to fortify. Requires " .. FORTIFY_COST, "Error")
		end
	end
end

-- ==========================================
-- COMBAT VICTORY LISTENER
-- ==========================================
local territoryEvent = game:GetService("ServerStorage"):FindFirstChild("TerritoryCombatWon")
if not territoryEvent then
	territoryEvent = Instance.new("BindableEvent")
	territoryEvent.Name = "TerritoryCombatWon"
	territoryEvent.Parent = game:GetService("ServerStorage")
end

territoryEvent.Event:Connect(function(player, nodeId, actionType)
	local node = GlobalMapState[nodeId]
	if not node then return end

	local mySquad, isLeader = GetPlayerSquadContext(player)
	if mySquad == "None" then return end

	-- ONE-FIGHT LEADER CAPTURE
	if actionType == "Capture" then
		if node.OwnerSquad == mySquad then return end
		if not isLeader then return end

		node.OwnerSquad = mySquad
		node.Health = 100
		node.MaxHealth = 100
		node.FortificationLevel = 1
		node.UnderAttack = false
		node.AttackerType = "None"
		NotificationEvent:FireClient(player, "Hostile forces crushed! Territory captured for " .. mySquad .. "!", "Success")

		-- MEMBER CHIP DAMAGE
	elseif actionType == "Assault" then
		if node.OwnerSquad == mySquad then return end

		node.UnderAttack = true
		node.AttackerType = "Player"

		node.Health -= 35 

		if node.Health <= 0 then
			node.Health = 1 
			NotificationEvent:FireClient(player, "Defenses shattered! The node is severely weakened, awaiting a Squad Leader to conquer it!", "Success")
		else
			NotificationEvent:FireClient(player, "Chip damage dealt! Enemy garrison health dropped to " .. node.Health .. ".", "Success")
		end

		-- CLEARING DANGER
	elseif actionType == "Defend" then
		if node.UnderAttack then
			node.UnderAttack = false
			node.AttackerType = "None"
			node.Health = math.min(node.MaxHealth, node.Health + 25) 
			NotificationEvent:FireClient(player, "Invasion repelled! " .. mySquad .. " border secured.", "Success")
		end
	end

	BroadcastMapState()
end)

-- ==========================================
-- NETWORK ROUTING
-- ==========================================
GetMapData.OnServerInvoke = function(player)
	local clientState = {}
	local mySquad, _ = GetPlayerSquadContext(player)
	for nodeId, nodeData in pairs(GlobalMapState) do
		clientState[nodeId] = {
			Owned = (mySquad ~= "None" and nodeData.OwnerSquad == mySquad),
			OwnerName = nodeData.OwnerSquad or "Unclaimed",
			UnderAttack = nodeData.UnderAttack,
			AttackerType = nodeData.AttackerType,
			Fortification = nodeData.FortificationLevel,
			Health = nodeData.Health,
			MaxHealth = nodeData.MaxHealth
		}
	end
	return clientState
end

MapAction.OnServerEvent:Connect(function(player, actionCategory, arg1, arg2)
	if actionCategory == "InteractNode" then
		if player:GetAttribute("InCombat") then return end
		local actionType, payload
		if type(arg1) == "string" and type(arg2) == "table" then
			actionType = arg1
			payload = arg2
		else return end

		if payload and payload.NodeId then
			ProcessNodeInteraction(player, payload.NodeId, actionType)
		end
	end
end)

return MapManager