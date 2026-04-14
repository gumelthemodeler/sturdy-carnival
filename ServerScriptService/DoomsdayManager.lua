-- @ScriptType: Script
-- @ScriptType: ModuleScript
local DoomsdayManager = {}

local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DoomsdayDataStore = DataStoreService:GetDataStore("Doomsday_Boss_V2")

local BOSS_MAX_HP = 500000000 -- 500 Million HP
local currentBossHP = BOSS_MAX_HP
local damageLeaderboard = {} 

local Network = ReplicatedStorage:WaitForChild("Network")
local GetDoomsdayData = Network:FindFirstChild("GetDoomsdayData") or Instance.new("RemoteFunction", Network)
GetDoomsdayData.Name = "GetDoomsdayData"
local NotificationEvent = Network:WaitForChild("NotificationEvent")

local IsBossActive = false
local BossDuration = 900 -- Active for 15 minutes (900 seconds)

local function DistributeRewards()
	local sorted = {}
	for uid, data in pairs(damageLeaderboard) do table.insert(sorted, {UserId = uid, Name = data.Name, Damage = data.Damage}) end
	table.sort(sorted, function(a, b) return a.Damage > b.Damage end)

	for rank, data in ipairs(sorted) do
		local p = Players:GetPlayerByUserId(data.UserId)
		if p then
			if rank <= 3 then
				p:SetAttribute("AbyssalBloodCount", (p:GetAttribute("AbyssalBloodCount") or 0) + 3)
				p:SetAttribute("SpinalFluidSyringeCount", (p:GetAttribute("SpinalFluidSyringeCount") or 0) + 5)
				local ls = p:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Dews") then ls.Dews.Value += 5000000 end
				NotificationEvent:FireClient(p, "Doomsday Defeated! Rank " .. rank .. " Rewards: 3x Abyssal Blood, 5x Premium Syringes, 5M Dews!", "Success")
			elseif rank <= 10 then
				p:SetAttribute("AbyssalBloodCount", (p:GetAttribute("AbyssalBloodCount") or 0) + 1)
				p:SetAttribute("SpinalFluidSyringeCount", (p:GetAttribute("SpinalFluidSyringeCount") or 0) + 2)
				local ls = p:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Dews") then ls.Dews.Value += 2000000 end
				NotificationEvent:FireClient(p, "Doomsday Defeated! Rank " .. rank .. " Rewards: 1x Abyssal Blood, 2x Premium Syringes, 2M Dews!", "Success")
			else
				p:SetAttribute("StandardTitanSerumCount", (p:GetAttribute("StandardTitanSerumCount") or 0) + 3)
				local ls = p:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Dews") then ls.Dews.Value += 500000 end
				NotificationEvent:FireClient(p, "Doomsday Defeated! Participation Reward: 3x Titan Serums, 500k Dews!", "Info")
			end
		end
	end
end

local function CheckSchedule()
	local currentTime = os.time()
	local currentHourStart = math.floor(currentTime / 3600) * 3600
	local secondsIntoHour = currentTime - currentHourStart

	if secondsIntoHour < BossDuration then
		if not IsBossActive then
			IsBossActive = true
			currentBossHP = BOSS_MAX_HP
			damageLeaderboard = {}
			NotificationEvent:FireAllClients("The Primordial Threat has appeared! Deploy via Combat Deployment!", "Error")
		end
	else
		if IsBossActive then
			IsBossActive = false
			NotificationEvent:FireAllClients("The Doomsday Titan has retreated into the steam.", "Info")
		end
	end

	if IsBossActive and currentBossHP <= 0 then
		IsBossActive = false
		DistributeRewards()
		NotificationEvent:FireAllClients("THE DOOMSDAY TITAN HAS BEEN DEFEATED GLOBALLY!", "Success")
	end
end

MessagingService:SubscribeAsync("DoomsdayDamageTick", function(message)
	local payload = message.Data
	if not IsBossActive then return end
	currentBossHP = math.max(0, currentBossHP - payload.Damage)

	if not damageLeaderboard[payload.UserId] then
		damageLeaderboard[payload.UserId] = {Name = payload.UserName, Damage = 0}
	end
	damageLeaderboard[payload.UserId].Damage += payload.Damage
end)

function DoomsdayManager.RegisterDamage(player, damage)
	if not IsBossActive or currentBossHP <= 0 then return end

	currentBossHP = math.max(0, currentBossHP - damage)

	if not damageLeaderboard[player.UserId] then
		damageLeaderboard[player.UserId] = {Name = player.Name, Damage = 0}
	end
	damageLeaderboard[player.UserId].Damage += damage

	pcall(function()
		MessagingService:PublishAsync("DoomsdayDamageTick", {
			UserId = player.UserId,
			UserName = player.Name,
			Damage = damage
		})
	end)
end

-- Used by CombatManager to auto-eject players
function DoomsdayManager.GetServerData()
	return {
		IsActive = IsBossActive,
		BossHP = currentBossHP
	}
end

GetDoomsdayData.OnServerInvoke = function(player)
	local sortedLeaderboard = {}
	for userId, data in pairs(damageLeaderboard) do
		table.insert(sortedLeaderboard, {Name = data.Name, Damage = data.Damage, UserId = userId})
	end

	table.sort(sortedLeaderboard, function(a, b) return a.Damage > b.Damage end)

	local top100 = {}
	for i = 1, math.min(100, #sortedLeaderboard) do
		table.insert(top100, sortedLeaderboard[i])
	end

	local timeUntilNext = 3600 - (os.time() % 3600)
	local timeRemaining = BossDuration - (os.time() % 3600)

	return {
		IsActive = IsBossActive,
		BossHP = currentBossHP,
		MaxHP = BOSS_MAX_HP,
		Leaderboard = top100,
		TimeUntilNext = timeUntilNext,
		TimeRemaining = timeRemaining
	}
end

task.spawn(function()
	while task.wait(1) do
		CheckSchedule()
	end
end)

return DoomsdayManager