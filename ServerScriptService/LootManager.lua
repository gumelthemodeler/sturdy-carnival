-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: LootManager
local LootManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local MAX_INVENTORY_CAPACITY = 25
local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500, Transcendent = 0 }

local function GetUniqueSlotCount(plr)
	local count = 0
	for iName, _ in pairs(ItemData.Equipment) do
		if (plr:GetAttribute(iName:gsub("[^%w]", "") .. "Count") or 0) > 0 then count += 1 end
	end
	for iName, _ in pairs(ItemData.Consumables) do
		if (plr:GetAttribute(iName:gsub("[^%w]", "") .. "Count") or 0) > 0 then count += 1 end
	end
	return count
end

function LootManager.GiveOrAutoSellItem(player, itemName, amount)
	local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
	if not iData then return end

	local rarity = iData.Rarity or "Common"
	local isAutoSellEnabled = player:GetAttribute("AutoSell_" .. rarity)

	if isAutoSellEnabled then
		local sellValue = (SellValues[rarity] or 10) * amount
		player.leaderstats.Dews.Value += sellValue
		local NotificationEvent = Network:FindFirstChild("NotificationEvent")
		if NotificationEvent then
			NotificationEvent:FireClient(player, "Auto-Sold " .. itemName .. " for " .. sellValue .. " Dews!", "Success")
		end
	else
		local safeName = itemName:gsub("[^%w]", "") .. "Count"
		local currentAmt = player:GetAttribute(safeName) or 0
		player:SetAttribute(safeName, currentAmt + amount)
	end
end

function LootManager.ProcessDrops(player, enemyDrops, isEndless, currentWave)
	local droppedItems = {}
	local autoSoldDewsCapacity = 0
	local autoSoldDewsSettings = 0
	local currentSlots = GetUniqueSlotCount(player)

	local dropMultiplier = player:GetAttribute("HasDoubleDrops") and 2 or 1
	local isYmirFavored = player:GetAttribute("YmirFavored")
	local favoredMultiplier = isYmirFavored and 1.5 or 1.0 

	local luckBoost = 1.0
	local luckExpiry = player:GetAttribute("Buff_Luck_Expiry") or 0
	if os.time() <= luckExpiry then
		luckBoost = player:GetAttribute("LuckBoost") or 1.0
	end

	if enemyDrops and enemyDrops.ItemChance then
		for itemName, baseChance in pairs(enemyDrops.ItemChance) do
			local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			local rarity = iData and iData.Rarity or "Common"

			local finalChance = baseChance

			if isEndless then
				-- Wave scaling for endless mode
				if rarity == "Mythical" then finalChance += (currentWave * 0.1)
				elseif rarity == "Legendary" then finalChance += (currentWave * 0.3)
				elseif rarity == "Epic" then finalChance += (currentWave * 1.0)
				else finalChance += (currentWave * 2.0) end

				-- Flat 50% bonus to base rates during endless mode
				finalChance = finalChance * 1.5
			end

			-- Apply Global multipliers alongside active Luck buff
			finalChance = finalChance * favoredMultiplier * luckBoost
			finalChance = math.clamp(finalChance, 0.01, 100)

			local roll = math.random() * 100
			if roll <= finalChance then
				local attrName = itemName:gsub("[^%w]", "") .. "Count"
				local currentAmt = player:GetAttribute(attrName) or 0
				local isAutoSellEnabled = player:GetAttribute("AutoSell_" .. rarity)

				if isAutoSellEnabled then
					autoSoldDewsSettings += (SellValues[rarity] or 10) * dropMultiplier
				elseif currentAmt == 0 and currentSlots >= MAX_INVENTORY_CAPACITY then
					autoSoldDewsCapacity += (SellValues[rarity] or 10) * dropMultiplier
				else
					local nameTag = (dropMultiplier > 1) and (itemName .. " (x" .. dropMultiplier .. ")") or itemName
					table.insert(droppedItems, nameTag)
					player:SetAttribute(attrName, currentAmt + dropMultiplier)
					if currentAmt == 0 then currentSlots += 1 end
				end
			end
		end

		-- Guarantee a drop every single endless wave if nothing drops normally
		if isEndless and #droppedItems == 0 and autoSoldDewsCapacity == 0 and autoSoldDewsSettings == 0 then
			local pool = {}
			for iname, _ in pairs(enemyDrops.ItemChance) do 
				local iData = ItemData.Equipment[iname] or ItemData.Consumables[iname]
				if iData and iData.Rarity ~= "Mythical" and iData.Rarity ~= "Legendary" then
					table.insert(pool, iname) 
				end
			end
			if #pool > 0 then
				local pItem = pool[math.random(1, #pool)]
				local attrName = pItem:gsub("[^%w]", "") .. "Count"
				local currentAmt = player:GetAttribute(attrName) or 0
				local iData = ItemData.Equipment[pItem] or ItemData.Consumables[pItem]
				local rarity = iData and iData.Rarity or "Common"
				local isAutoSellEnabled = player:GetAttribute("AutoSell_" .. rarity)

				if isAutoSellEnabled then
					autoSoldDewsSettings += (SellValues[rarity] or 10) * dropMultiplier
				elseif currentAmt == 0 and currentSlots >= MAX_INVENTORY_CAPACITY then
					autoSoldDewsCapacity += (SellValues[rarity] or 10) * dropMultiplier
				else
					local nameTag = (dropMultiplier > 1) and (pItem .. " (x" .. dropMultiplier .. ")") or pItem
					table.insert(droppedItems, nameTag)
					player:SetAttribute(attrName, currentAmt + dropMultiplier)
				end
			end
		end
	end

	if autoSoldDewsSettings > 0 then
		player.leaderstats.Dews.Value += autoSoldDewsSettings
		local NotificationEvent = Network:FindFirstChild("NotificationEvent")
		if NotificationEvent then
			NotificationEvent:FireClient(player, "Auto-Sold dropped items for " .. autoSoldDewsSettings .. " Dews!", "Success")
		end
	end

	if autoSoldDewsCapacity > 0 then
		player.leaderstats.Dews.Value += autoSoldDewsCapacity
	end

	return droppedItems, autoSoldDewsCapacity
end

return LootManager