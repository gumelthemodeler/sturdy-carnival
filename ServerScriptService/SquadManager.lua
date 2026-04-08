-- @ScriptType: Script
-- @ScriptType: Script
-- Name: SquadManager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService") -- [NEW] Cross-server sync

local SquadStore = DataStoreService:GetDataStore("StrikeSquads_V2")
local SquadLeaderboard = DataStoreService:GetOrderedDataStore("Global_Squad_SP_V1")

local Network = ReplicatedStorage:WaitForChild("Network")
local SquadAction = Network:FindFirstChild("SquadAction") or Instance.new("RemoteEvent", Network)
SquadAction.Name = "SquadAction"
local NotificationEvent = Network:WaitForChild("NotificationEvent")

-- BindableEvent to listen for SP gains from other scripts like CombatManager
local AddSquadSP = Network:FindFirstChild("AddSquadSP") or Instance.new("BindableEvent", Network)
AddSquadSP.Name = "AddSquadSP"

local GetPublicSquads = Instance.new("RemoteFunction", Network); GetPublicSquads.Name = "GetPublicSquads"
local GetSquadRoster = Instance.new("RemoteFunction", Network); GetSquadRoster.Name = "GetSquadRoster"
local GetSquadLeaderboard = Instance.new("RemoteFunction", Network); GetSquadLeaderboard.Name = "GetSquadLeaderboard"
local GetSquadRequests = Instance.new("RemoteFunction", Network); GetSquadRequests.Name = "GetSquadRequests"

local ActiveSquads = {}
local GlobalSquadCache = {}
local isFetchingCache = false

-- [NEW] Catch messages from other servers to update live squad cache and apply changes across all servers instantly
pcall(function()
	MessagingService:SubscribeAsync("SquadUpdate", function(message)
		local sqName = message.Data.SquadName
		if ActiveSquads[sqName] then
			pcall(function()
				local latestData = SquadStore:GetAsync(sqName)
				if latestData then
					ActiveSquads[sqName] = latestData
					-- Update the clients in THIS server so they see the fresh data
					local vaultStr = HttpService:JSONEncode(latestData.Vault or {"None","None","None","None","None","None","None","None","None"})
					for _, p in ipairs(Players:GetPlayers()) do
						if p:GetAttribute("SquadName") == sqName then
							p:SetAttribute("SquadSP", latestData.SP)
							p:SetAttribute("SquadVault", vaultStr)
							p:SetAttribute("SquadIsLeader", latestData.Leader == p.UserId)
							p:SetAttribute("YmirFavored", latestData.IsYmirFavored or false)
						end
					end
				end
			end)
		end
	end)
end)

local function UpdateOnlineMembers(sqName)
	local sqData = ActiveSquads[sqName]
	if not sqData then return end
	local vaultStr = HttpService:JSONEncode(sqData.Vault or {"None","None","None","None","None","None","None","None","None"})
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("SquadName") == sqName then
			p:SetAttribute("SquadSP", sqData.SP)
			p:SetAttribute("SquadVault", vaultStr)
			p:SetAttribute("SquadIsLeader", sqData.Leader == p.UserId)
			p:SetAttribute("YmirFavored", sqData.IsYmirFavored or false)
		end
	end
end

local function SaveSquadData(squadName, data)
	pcall(function() 
		SquadStore:SetAsync(squadName, data)
		SquadLeaderboard:SetAsync(squadName, data.SP or 0) 
	end)
	-- [NEW] Tell all other servers that this squad has been updated
	pcall(function() 
		MessagingService:PublishAsync("SquadUpdate", {SquadName = squadName}) 
	end)
end

AddSquadSP.Event:Connect(function(sqName, amount)
	local sqData = ActiveSquads[sqName]
	if sqData then
		sqData.SP = (sqData.SP or 0) + amount
		SaveSquadData(sqName, sqData)
		UpdateOnlineMembers(sqName)
	end
end)

local function RefreshGlobalCache()
	if isFetchingCache then return end
	isFetchingCache = true
	pcall(function()
		local pages = SquadLeaderboard:GetSortedAsync(false, 50)
		local newCache = {}
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local sqName = entry.key
			local sqData = ActiveSquads[sqName] or SquadStore:GetAsync(sqName)
			if sqData then
				local memCount = 0; for _, _ in pairs(sqData.Members or {}) do memCount += 1 end
				table.insert(newCache, {
					Name = sqData.Name, Desc = sqData.Desc, Logo = sqData.Logo ~= "" and sqData.Logo or "rbxassetid://100826303284945",
					Level = sqData.Level or 1, MemberCount = memCount .. "/15", SP = sqData.SP or 0
				})
			end
		end
		GlobalSquadCache = newCache
	end)
	isFetchingCache = false
end

task.spawn(function()
	RefreshGlobalCache()
	while task.wait(60) do RefreshGlobalCache() end
end)

-- YMIR'S FAVORED DYNAMIC CHECKING
local currentTopSquadName = nil
task.spawn(function()
	while task.wait(60) do
		local success, pages = pcall(function() return SquadLeaderboard:GetSortedAsync(false, 1) end)
		if success and pages then
			local topEntry = pages:GetCurrentPage()[1]
			if topEntry then
				local newTopName = topEntry.key
				if newTopName ~= currentTopSquadName then
					if currentTopSquadName and ActiveSquads[currentTopSquadName] then
						ActiveSquads[currentTopSquadName].IsYmirFavored = false
						SaveSquadData(currentTopSquadName, ActiveSquads[currentTopSquadName])
						UpdateOnlineMembers(currentTopSquadName)
					end
					if ActiveSquads[newTopName] then
						ActiveSquads[newTopName].IsYmirFavored = true
						SaveSquadData(newTopName, ActiveSquads[newTopName])
						UpdateOnlineMembers(newTopName)
						for _, p in ipairs(Players:GetPlayers()) do
							if p:GetAttribute("SquadName") == newTopName then
								NotificationEvent:FireClient(p, "Your Squad is now Ymir's Favored! (+3 Vault Slots, +50% Drop Rates)", "Success")
							end
						end
					end
					currentTopSquadName = newTopName
				end
			end
		end
	end
end)

SquadAction.OnServerEvent:Connect(function(player, action, data)
	if action == "Create" then
		if not data.Name or string.len(data.Name) < 3 or string.len(data.Name) > 20 then NotificationEvent:FireClient(player, "Squad Name must be between 3 and 20 characters.", "Error") return end
		if player:GetAttribute("SquadName") and player:GetAttribute("SquadName") ~= "None" then NotificationEvent:FireClient(player, "You are already in a Squad!", "Error") return end

		local dews = player.leaderstats and player.leaderstats:FindFirstChild("Dews")
		if not dews or dews.Value < 100000 then NotificationEvent:FireClient(player, "Requires 100,000 Dews.", "Error") return end
		if pcall(function() return SquadStore:GetAsync(data.Name) end) and SquadStore:GetAsync(data.Name) then NotificationEvent:FireClient(player, "Squad name taken!", "Error") return end

		dews.Value -= 100000
		local safeLogo = data.Logo or ""; local numId = safeLogo:match("%d+"); if numId then safeLogo = "rbxassetid://" .. numId else safeLogo = "" end

		local newSquadData = {
			Name = data.Name, Desc = data.Desc or "A newly founded Strike Squad.", Logo = safeLogo,
			Leader = player.UserId, Members = { [tostring(player.UserId)] = {Role = "Leader", Name = player.Name} },
			Requests = {}, SP = 0, Level = 1, IsYmirFavored = false,
			Vault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"}
		}

		ActiveSquads[data.Name] = newSquadData
		SaveSquadData(data.Name, newSquadData)

		player:SetAttribute("SquadName", data.Name); player:SetAttribute("SquadDesc", newSquadData.Desc); player:SetAttribute("SquadLogo", newSquadData.Logo); player:SetAttribute("SquadSP", 0); player:SetAttribute("SquadIsLeader", true); player:SetAttribute("YmirFavored", false); player:SetAttribute("SquadVault", HttpService:JSONEncode(newSquadData.Vault))
		NotificationEvent:FireClient(player, "Squad '" .. data.Name .. "' officially founded!", "Success")

	elseif action == "RequestJoin" then
		local sqName = data
		if player:GetAttribute("SquadName") and player:GetAttribute("SquadName") ~= "None" then NotificationEvent:FireClient(player, "You must leave your current Squad first.", "Error") return end

		local sqData = ActiveSquads[sqName] or SquadStore:GetAsync(sqName)
		if not sqData then NotificationEvent:FireClient(player, "Squad not found.", "Error") return end

		local memCount = 0; for _, _ in pairs(sqData.Members) do memCount += 1 end
		if memCount >= 15 then NotificationEvent:FireClient(player, "That Squad is currently full!", "Error") return end

		if not sqData.Requests then sqData.Requests = {} end
		if sqData.Requests[tostring(player.UserId)] then NotificationEvent:FireClient(player, "You already have a pending request for this Squad.", "Error") return end

		-- [NEW] Requests are now bound to the datastore table to persist across servers
		sqData.Requests[tostring(player.UserId)] = player.Name
		SaveSquadData(sqName, sqData)

		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == sqData.Leader then NotificationEvent:FireClient(p, player.Name .. " has requested to join your Squad!", "Info") end
		end
		NotificationEvent:FireClient(player, "Join Request sent to the Squad Leader.", "Success")

	elseif action == "ManageRequest" then
		local sqName = player:GetAttribute("SquadName")
		local targetId = tostring(data.TargetId)
		local decision = data.Decision

		local sqData = ActiveSquads[sqName]
		if not sqData or sqData.Leader ~= player.UserId then return end
		if not sqData.Requests or not sqData.Requests[targetId] then return end

		local targetName = sqData.Requests[targetId]
		sqData.Requests[targetId] = nil 

		if decision == "Accept" then
			local memCount = 0; for _, _ in pairs(sqData.Members) do memCount += 1 end
			if memCount >= 15 then NotificationEvent:FireClient(player, "Squad is full!", "Error"); return end

			sqData.Members[targetId] = {Role = "Member", Name = targetName}
			NotificationEvent:FireClient(player, "Accepted " .. targetName .. " into the Squad.", "Success")

			for _, p in ipairs(Players:GetPlayers()) do
				if tostring(p.UserId) == targetId then
					p:SetAttribute("SquadName", sqName); p:SetAttribute("SquadDesc", sqData.Desc); p:SetAttribute("SquadLogo", sqData.Logo); p:SetAttribute("SquadSP", sqData.SP); p:SetAttribute("SquadIsLeader", false); p:SetAttribute("YmirFavored", sqData.IsYmirFavored or false); p:SetAttribute("SquadVault", HttpService:JSONEncode(sqData.Vault))
					NotificationEvent:FireClient(p, "Your request to join " .. sqName .. " was accepted!", "Success")
				end
			end
		else
			NotificationEvent:FireClient(player, "Denied request from " .. targetName .. ".", "Info")
		end

		SaveSquadData(sqName, sqData)

	elseif action == "DepositItem" then
		local slot = tonumber(data.Slot)
		local itemName = tostring(data.ItemName)
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end

		local sqData = ActiveSquads[sqName]
		if not sqData then return end

		-- [SECURITY FIX] Prevent depositing Locked items
		if player:GetAttribute(itemName:gsub("[^%w]", "") .. "_Locked") then
			NotificationEvent:FireClient(player, "You cannot deposit Locked items!", "Error")
			return
		end

		if slot > 6 and not sqData.IsYmirFavored then
			NotificationEvent:FireClient(player, "Bonus Vault slots are locked! Reach #1 Globally to unlock.", "Error")
			return
		end

		if not sqData.Vault then sqData.Vault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"} end
		if sqData.Vault[slot] and sqData.Vault[slot] ~= "None" then
			NotificationEvent:FireClient(player, "That slot is already full!", "Error")
			return
		end

		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		local pCount = player:GetAttribute(attrName) or 0
		if pCount <= 0 then
			NotificationEvent:FireClient(player, "You do not own this item.", "Error")
			return
		end

		player:SetAttribute(attrName, pCount - 1)
		sqData.Vault[slot] = itemName

		-- [SECURITY FIX] Force unequip if they deposited their last copy
		if (pCount - 1) <= 0 then
			if player:GetAttribute("EquippedWeapon") == itemName then
				player:SetAttribute("EquippedWeapon", "None")
				player:SetAttribute("FightingStyle", "None")
			elseif player:GetAttribute("EquippedAccessory") == itemName then
				player:SetAttribute("EquippedAccessory", "None")
			end
		end

		SaveSquadData(sqName, sqData)
		UpdateOnlineMembers(sqName)
		NotificationEvent:FireClient(player, "Deposited " .. itemName .. " into Vault.", "Success")

	elseif action == "WithdrawItem" then
		local slot = tonumber(data.Slot)
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end

		local sqData = ActiveSquads[sqName]
		if not sqData then return end

		if not sqData.Vault then sqData.Vault = {"None", "None", "None", "None", "None", "None", "None", "None", "None"} end
		local itemName = sqData.Vault[slot]
		if not itemName or itemName == "None" then return end

		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
		sqData.Vault[slot] = "None"
		SaveSquadData(sqName, sqData)
		UpdateOnlineMembers(sqName)
		NotificationEvent:FireClient(player, "Withdrew " .. itemName .. " from Vault.", "Success")

	elseif action == "Leave" then
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end
		local sqData = ActiveSquads[sqName]
		if not sqData then return end

		if sqData.Leader == player.UserId then
			NotificationEvent:FireClient(player, "You are the Leader! You must Disband the Squad.", "Error")
			return
		end

		sqData.Members[tostring(player.UserId)] = nil
		SaveSquadData(sqName, sqData)

		player:SetAttribute("SquadName", "None")
		player:SetAttribute("SquadIsLeader", false)
		player:SetAttribute("YmirFavored", false)
		player:SetAttribute("SquadVault", '{"1":"None","2":"None","3":"None","4":"None","5":"None","6":"None","7":"None","8":"None","9":"None"}')
		NotificationEvent:FireClient(player, "You left the Squad.", "Info")
		UpdateOnlineMembers(sqName)

	elseif action == "Disband" then
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end
		local sqData = ActiveSquads[sqName]
		if not sqData or sqData.Leader ~= player.UserId then return end

		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("SquadName") == sqName then
				p:SetAttribute("SquadName", "None")
				p:SetAttribute("SquadIsLeader", false)
				p:SetAttribute("YmirFavored", false)
				p:SetAttribute("SquadVault", '{"1":"None","2":"None","3":"None","4":"None","5":"None","6":"None","7":"None","8":"None","9":"None"}')
				NotificationEvent:FireClient(p, "Your Squad was disbanded by the Leader.", "Error")
			end
		end

		ActiveSquads[sqName] = nil
		pcall(function()
			SquadStore:RemoveAsync(sqName)
			SquadLeaderboard:RemoveAsync(sqName)
		end)
	end
end)

GetPublicSquads.OnServerInvoke = function()
	local returned = {}; local seen = {}
	for _, sq in ipairs(GlobalSquadCache) do table.insert(returned, sq); seen[sq.Name] = true end
	for name, data in pairs(ActiveSquads) do
		if not seen[name] then
			local mCount = 0; for _, _ in pairs(data.Members or {}) do mCount += 1 end
			table.insert(returned, {Name = data.Name, Desc = data.Desc, Logo = data.Logo, Level = data.Level, MemberCount = mCount .. "/15", SP = data.SP})
			seen[name] = true
		end
	end
	table.sort(returned, function(a, b) return a.SP > b.SP end)
	return returned
end

GetSquadRequests.OnServerInvoke = function(player)
	local sqName = player:GetAttribute("SquadName")
	if not sqName or sqName == "None" then return {} end
	local sqData = ActiveSquads[sqName]
	if not sqData or sqData.Leader ~= player.UserId then return {} end

	local reqs = {}
	-- [NEW] Pull directly from persistent datastore table
	for uid, uname in pairs(sqData.Requests or {}) do table.insert(reqs, {UserId = uid, Name = uname}) end
	return reqs
end

GetSquadRoster.OnServerInvoke = function(player)
	local sqName = player:GetAttribute("SquadName")
	if not sqName or sqName == "None" or sqName == "" then return {} end

	local sqData = ActiveSquads[sqName]
	if not sqData then return {} end

	local roster = {}
	for userId, memData in pairs(sqData.Members) do
		table.insert(roster, { Name = memData.Name, Role = memData.Role })
	end
	table.sort(roster, function(a, b) 
		if a.Role == "Leader" then return true end
		if b.Role == "Leader" then return false end
		return a.Name < b.Name
	end)
	return roster
end

GetSquadLeaderboard.OnServerInvoke = function(player)
	local sorted = {}
	local seen = {}

	for name, data in pairs(ActiveSquads) do
		table.insert(sorted, {Name = data.Name, SP = data.SP})
		seen[name] = true
	end

	for _, sq in ipairs(GlobalSquadCache) do
		if not seen[sq.Name] then
			table.insert(sorted, {Name = sq.Name, SP = sq.SP})
			seen[sq.Name] = true
		end
	end

	table.sort(sorted, function(a, b) return a.SP > b.SP end)

	local top10 = {}
	for i = 1, math.min(10, #sorted) do
		table.insert(top10, {Rank = i, Name = sorted[i].Name, SP = sorted[i].SP})
	end

	return top10
end

local function LoadPlayerSquad(player)
	local mySquad = player:GetAttribute("SquadName")
	if mySquad and mySquad ~= "None" and mySquad ~= "" then
		local sqData = ActiveSquads[mySquad]

		if not sqData then
			local success, data = pcall(function() return SquadStore:GetAsync(mySquad) end)
			if success then
				if data then
					sqData = data
					ActiveSquads[mySquad] = sqData
				else
					player:SetAttribute("SquadName", "None")
					return
				end
			else
				warn("[SquadManager] Failed to load squad data for: " .. mySquad)
				return 
			end
		end

		if sqData then
			player:SetAttribute("SquadDesc", sqData.Desc)
			player:SetAttribute("SquadLogo", sqData.Logo)
			player:SetAttribute("SquadSP", sqData.SP)
			player:SetAttribute("SquadIsLeader", sqData.Leader == player.UserId)
			player:SetAttribute("YmirFavored", sqData.IsYmirFavored or false)
			local vaultStr = HttpService:JSONEncode(sqData.Vault or {"None", "None", "None", "None", "None", "None", "None", "None", "None"})
			player:SetAttribute("SquadVault", vaultStr)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	if player:GetAttribute("DataLoaded") then LoadPlayerSquad(player) end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		if player:GetAttribute("DataLoaded") then LoadPlayerSquad(player) end
	end)
end)