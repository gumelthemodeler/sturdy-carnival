-- @ScriptType: Script
-- @ScriptType: Script
-- Name: InventoryManager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local CosmeticData = require(ReplicatedStorage:WaitForChild("CosmeticData"))
local Network = ReplicatedStorage:WaitForChild("Network")
local NotificationEvent = Network:WaitForChild("NotificationEvent")
local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500, Transcendent = 0 }

Network:WaitForChild("EquipItem").OnServerEvent:Connect(function(player, itemName)
	if string.match(itemName, "^Unequip_") then
		local slotType = string.gsub(itemName, "Unequip_", "")
		if slotType == "Weapon" then player:SetAttribute("EquippedWeapon", "None"); player:SetAttribute("FightingStyle", "None")
		elseif slotType == "Accessory" then player:SetAttribute("EquippedAccessory", "None") end
		return
	end
	local itemInfo = ItemData.Equipment[itemName]
	if itemInfo then
		local safeName = itemName:gsub("[^%w]", "") .. "Count"
		if (player:GetAttribute(safeName) or 0) > 0 then
			if itemInfo.Type == "Weapon" then player:SetAttribute("EquippedWeapon", itemName); player:SetAttribute("FightingStyle", itemInfo.Style or "None")
			elseif itemInfo.Type == "Accessory" then player:SetAttribute("EquippedAccessory", itemName) end
		end
	end
end)

Network:WaitForChild("SellItem").OnServerEvent:Connect(function(player, itemName, sellAll)
	local safeNameBase = itemName:gsub("[^%w]", "")
	if player:GetAttribute(safeNameBase .. "_Locked") then return end

	local itemInfo = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
	if itemInfo then
		local safeName = safeNameBase .. "Count"
		local count = player:GetAttribute(safeName) or 0
		if count > 0 then
			local sellPrice = SellValues[itemInfo.Rarity or "Common"] or 10
			local amountToSell = sellAll and count or 1

			local newCount = count - amountToSell
			player:SetAttribute(safeName, newCount)
			player.leaderstats.Dews.Value += (sellPrice * amountToSell)

			-- [SECURITY FIX] Force unequip if they sold their last copy
			if newCount <= 0 then
				if player:GetAttribute("EquippedWeapon") == itemName then
					player:SetAttribute("EquippedWeapon", "None")
					player:SetAttribute("FightingStyle", "None")
				elseif player:GetAttribute("EquippedAccessory") == itemName then
					player:SetAttribute("EquippedAccessory", "None")
				end
			end
		end
	end
end)

Network:WaitForChild("AutoSell").OnServerEvent:Connect(function(player, rarity)
	local attrName = "AutoSell_" .. rarity
	player:SetAttribute(attrName, not player:GetAttribute(attrName))
end)

local ToggleLock = Network:FindFirstChild("ToggleLock") or Instance.new("RemoteEvent", Network)
ToggleLock.Name = "ToggleLock"
ToggleLock.OnServerEvent:Connect(function(player, itemName)
	local safeName = itemName:gsub("[^%w]", "") .. "_Locked"
	player:SetAttribute(safeName, not player:GetAttribute(safeName))
end)

Network:WaitForChild("ConsumeItem").OnServerEvent:Connect(function(player, itemName)
	local itemInfo = ItemData.Consumables[itemName]
	if itemInfo and itemInfo.Action then
		local safeName = itemName:gsub("[^%w]", "") .. "Count"
		local count = player:GetAttribute(safeName) or 0
		if count > 0 then
			player:SetAttribute(safeName, count - 1)
			if itemInfo.Action == "EquipTitan" then
				player:SetAttribute("Titan", itemInfo.TitanName)
				NotificationEvent:FireClient(player, "Inherited the " .. itemInfo.TitanName .. "!", "Success")

				-- [NEW] Awakens the player's current Clan
			elseif itemInfo.Action == "AwakenClan" then
				local currentClan = player:GetAttribute("Clan") or "None"
				if currentClan ~= "None" and not string.find(currentClan, "Awakened") then
					player:SetAttribute("Clan", "Awakened " .. currentClan)
					NotificationEvent:FireClient(player, "Your Clan bloodline has awakened to its true power!", "Success")
				else
					player:SetAttribute(safeName, count) -- Refund item
					NotificationEvent:FireClient(player, "You cannot awaken your current lineage.", "Error")
				end

				-- [NEW] Awakens the Attack Titan to the Coordinate
			elseif itemInfo.Action == "AwakenTitan" then
				local currentTitan = player:GetAttribute("Titan") or "None"
				if currentTitan == "Attack Titan" then
					player:SetAttribute("Titan", "Founding Titan") 
					player:SetAttribute("PathsAwakened", "DMG: 50 | DODGE: 10 | MAX HP: 100") 
					NotificationEvent:FireClient(player, "You have reached the Coordinate!", "Success")
				else
					player:SetAttribute(safeName, count) -- Refund item
					NotificationEvent:FireClient(player, "Only the Attack Titan can reach the Coordinate.", "Error")
				end

			elseif itemInfo.Buff == "Dews" then
				local amt = math.random(itemInfo.MinAmount or 5000, itemInfo.MaxAmount or 20000)
				player.leaderstats.Dews.Value += amt
				NotificationEvent:FireClient(player, "Gained " .. amt .. " Dews!", "Success")
			elseif itemInfo.Buff == "Gamepass" then
				player:SetAttribute("Has" .. itemInfo.Unlock, true)
				NotificationEvent:FireClient(player, "Unlocked " .. itemInfo.Unlock .. "!", "Success")
			else
				local expiryAttr = "Buff_" .. itemInfo.Buff .. "_Expiry"
				player:SetAttribute(expiryAttr, os.time() + (itemInfo.Duration or 900))
			end
		end
	end
end)

local EquipCosmetic = Network:FindFirstChild("EquipCosmetic") or Instance.new("RemoteEvent", Network)
EquipCosmetic.Name = "EquipCosmetic"
EquipCosmetic.OnServerEvent:Connect(function(player, cosType, cosKey)
	local dataPool = (cosType == "Title") and CosmeticData.Titles or CosmeticData.Auras
	local data = dataPool[cosKey]
	if data then
		if CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) then
			player:SetAttribute("Equipped" .. cosType, cosKey)
			NotificationEvent:FireClient(player, "Equipped " .. data.Name .. "!", "Success")
		else NotificationEvent:FireClient(player, "You have not unlocked this cosmetic.", "Error") end
	end
end)