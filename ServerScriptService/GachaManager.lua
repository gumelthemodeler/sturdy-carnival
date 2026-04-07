-- @ScriptType: Script
-- @ScriptType: Script
-- Name: GachaManager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local GachaRoll = Network:FindFirstChild("GachaRoll") or Instance.new("RemoteEvent", Network)
GachaRoll.Name = "GachaRoll"
local GachaResult = Network:FindFirstChild("GachaResult") or Instance.new("RemoteEvent", Network)
GachaResult.Name = "GachaResult"

local ManageStorage = Network:FindFirstChild("ManageStorage") or Instance.new("RemoteEvent", Network)
ManageStorage.Name = "ManageStorage"

-- [[ THE FIX: Strict 1-second server debounce to eradicate mobile double-taps ]]
local SwapDebounce = {}

ManageStorage.OnServerEvent:Connect(function(player, gType, slotIndex)
	local now = os.clock()
	if SwapDebounce[player.UserId] and (now - SwapDebounce[player.UserId]) < 1.0 then return end
	SwapDebounce[player.UserId] = now

	local safeGType = tostring(gType)
	local safeIndex = tonumber(slotIndex)

	if not safeIndex or (safeGType ~= "Titan" and safeGType ~= "Clan") then return end

	-- Verify Gamepass Ownership for extra slots (4, 5, 6)
	if safeIndex > 3 and not player:GetAttribute("Has" .. safeGType .. "Vault") then
		return 
	end

	local activeAttr = safeGType 
	local slotAttr = safeGType .. "_Slot" .. safeIndex

	-- [[ THE FIX: Intercept ghost string data and force "None" ]]
	local currentActive = player:GetAttribute(activeAttr)
	if not currentActive or currentActive == "" then currentActive = "None" end

	local currentSlotted = player:GetAttribute(slotAttr)
	if not currentSlotted or currentSlotted == "" then currentSlotted = "None" end

	local NotificationEvent = Network:FindFirstChild("NotificationEvent")

	-- If both slots are empty, send an error and abort
	if currentActive == "None" and currentSlotted == "None" then
		if NotificationEvent then
			NotificationEvent:FireClient(player, "Nothing to swap in this slot.", "Error")
		end
		return
	end

	-- Execute the explicit swap
	player:SetAttribute(activeAttr, currentSlotted)
	player:SetAttribute(slotAttr, currentActive)

	if NotificationEvent then
		-- Explicitly tell the user what just happened so there is zero confusion
		local actionText = ""
		if currentActive ~= "None" and currentSlotted == "None" then
			actionText = "Vaulted " .. currentActive .. "!"
		elseif currentActive == "None" and currentSlotted ~= "None" then
			actionText = "Equipped " .. currentSlotted .. "!"
		else
			actionText = "Swapped " .. currentActive .. " with " .. currentSlotted .. "!"
		end
		NotificationEvent:FireClient(player, actionText, "Success")
	end
end)

GachaRoll.OnServerEvent:Connect(function(player, gType, isPremium)
	local attrReq = (gType == "Titan") and (isPremium and "SpinalFluidSyringeCount" or "StandardTitanSerumCount") or "ClanBloodVialCount"
	local itemsOwned = player:GetAttribute(attrReq) or 0

	if itemsOwned > 0 then
		player:SetAttribute(attrReq, itemsOwned - 1)
		local resultName, rarity

		if gType == "Titan" then
			local legPity = player:GetAttribute("TitanPity") or 0
			local mythPity = player:GetAttribute("TitanMythicalPity") or 0
			if isPremium then legPity += 100 end

			resultName, rarity = TitanData.RollTitan(legPity, mythPity)

			if rarity == "Mythical" or rarity == "Transcendent" then
				player:SetAttribute("TitanPity", 0); player:SetAttribute("TitanMythicalPity", 0)
			elseif rarity == "Legendary" then
				player:SetAttribute("TitanPity", 0); player:SetAttribute("TitanMythicalPity", mythPity + 1)
			else
				player:SetAttribute("TitanPity", legPity + 1); player:SetAttribute("TitanMythicalPity", mythPity + 1)
			end
		else
			local clanPity = player:GetAttribute("ClanPity") or 0
			if clanPity >= 100 then
				local premiumClans = {}
				for cName, w in pairs(TitanData.ClanWeights) do if w <= 4.0 then table.insert(premiumClans, cName) end end
				resultName = premiumClans[math.random(1, #premiumClans)]
				rarity = (TitanData.ClanWeights[resultName] <= 1.5) and "Mythical" or "Legendary"
				player:SetAttribute("ClanPity", 0)
			else
				resultName = TitanData.RollClan()
				local weight = TitanData.ClanWeights[resultName] or 40
				if weight <= 1.5 then rarity = "Mythical" elseif weight <= 4.0 then rarity = "Legendary" elseif weight <= 8.0 then rarity = "Epic" elseif weight <= 15.0 then rarity = "Rare" else rarity = "Common" end
				if rarity == "Legendary" or rarity == "Mythical" or rarity == "Transcendent" then player:SetAttribute("ClanPity", 0) else player:SetAttribute("ClanPity", clanPity + 1) end
			end
		end
		player:SetAttribute(gType, resultName)
		GachaResult:FireClient(player, gType, resultName, rarity)
	else
		GachaResult:FireClient(player, gType, "Error", "None")
	end
end)