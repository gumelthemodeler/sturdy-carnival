-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ClanData = {
	Clans = {
		["Yeager"] = {
			BaseDmgMult = 1.25, AwakenedDmgMult = 1.50, AbyssalDmgMult = 3.50,
			TitanSynergies = { ["Attack"] = { DmgMult = 0.30 } }
		},
		["Tybur"] = {
			BaseDmgMult = 1.20, AwakenedDmgMult = 1.40, AbyssalDmgMult = 3.00,
			TitanSynergies = { ["War Hammer"] = { DmgMult = 0.30 } }
		},
		["Ackerman"] = {
			BaseDmgMult = 1.50, AwakenedDmgMult = 3.00, AbyssalDmgMult = 6.50,
			BaseSpdMult = 1.50, AwakenedSpdMult = 2.00, AbyssalSpdMult = 4.00,
			BaseSurvivals = 1, AwakenedSurvivals = 3, AbyssalSurvivals = 6,
			SurvivalChance = 100,

			NapeCritMultiplier = 3.0, AbyssalNapeCritMultiplier = 6.0,
			MomentumDamagePerHit = 0.05, AbyssalMomentumDamagePerHit = 0.15,
			MaxMomentumStacks = 20, AbyssalMaxMomentumStacks = 50,
			GasEfficiency = 0.20 
		},
		["Galliard"] = {
			BaseDmgMult = 1.05, AwakenedDmgMult = 1.15, AbyssalDmgMult = 2.50,
			BaseSpdMult = 1.15, AwakenedSpdMult = 1.30, AbyssalSpdMult = 3.00,
			TitanSynergies = { ["Jaw"] = { SpdMult = 0.25, CritBonus = 25 } }
		},
		["Braun"] = {
			BaseArmorMult = 1.20, AwakenedArmorMult = 1.40, AbyssalArmorMult = 4.00,
			TitanSynergies = { ["Armored"] = { ArmorMult = 0.50 } } 
		},
		["Arlert"] = {
			BaseResolveMult = 1.15, AwakenedResolveMult = 1.30, AbyssalResolveMult = 3.00,
			TitanSynergies = { ["Colossal"] = { HpMult = 0.50 } }
		},
		["Braus"] = {
			BaseSpdMult = 1.10, AwakenedSpdMult = 1.20, AbyssalSpdMult = 2.50,
		},
		["Springer"] = {
			DodgeBonus = 15, AbyssalDodgeBonus = 45
		},
		["Reiss"] = {
			BaseHpMult = 1.50, AwakenedHpMult = 2.00, AbyssalHpMult = 4.50,
			BaseResolveMult = 1.25, AwakenedResolveMult = 1.50, AbyssalResolveMult = 3.50,
			BaseSurvivals = 1, AwakenedSurvivals = 2, AbyssalSurvivals = 5,
			SurvivalChance = 75,
			-- [[ THE FIX: Look for "Founding" instead of "Founding Titan" to catch Fusions ]]
			TitanSynergies = { ["Founding"] = { HpMult = 0.50, DmgMult = 0.25, ArmorMult = 0.25 } }
		},
		["Fritz"] = {
			BaseHpMult = 2.00, AwakenedHpMult = 3.00, AbyssalHpMult = 6.00,
			BaseDmgMult = 1.50, AwakenedDmgMult = 2.00, AbyssalDmgMult = 5.00,
			BaseArmorMult = 1.50, AwakenedArmorMult = 2.00, AbyssalArmorMult = 5.00,
			BaseSpdMult = 1.25, AwakenedSpdMult = 1.50, AbyssalSpdMult = 3.50,
			BaseSurvivals = 2, AwakenedSurvivals = 4, AbyssalSurvivals = 8,
			SurvivalChance = 100,
			-- [[ THE FIX: Look for "Founding" instead of "Founding Titan" to catch Fusions ]]
			TitanSynergies = { ["Founding"] = { DmgMult = 0.50, HpMult = 0.50, ArmorMult = 0.50 } }
		}
	}
}

function ClanData.GetClanStats(clanNameStr, isAwakened, titanNameStr, isTransformed)
	local isAbyssal = string.find(clanNameStr or "", "Abyssal") ~= nil
	local baseName = string.gsub(clanNameStr or "None", "Awakened ", "")
	baseName = string.gsub(baseName, "Abyssal ", "") 

	local data = ClanData.Clans[baseName]

	local stats = {
		DmgMult = 1.0, ArmorMult = 1.0, SpdMult = 1.0, ResolveMult = 1.0, HpMult = 1.0,
		CritBonus = 0, DodgeBonus = 0, Survivals = 0, SurvivalChance = 0,
		NapeCritMultiplier = 1.5, MomentumDamagePerHit = 0, MaxMomentumStacks = 0, GasEfficiency = 1.0
	}

	if data then
		stats.DmgMult = isAbyssal and (data.AbyssalDmgMult or 1.0) or (isAwakened and (data.AwakenedDmgMult or 1.0) or (data.BaseDmgMult or 1.0))
		stats.ArmorMult = isAbyssal and (data.AbyssalArmorMult or 1.0) or (isAwakened and (data.AwakenedArmorMult or 1.0) or (data.BaseArmorMult or 1.0))
		stats.SpdMult = isAbyssal and (data.AbyssalSpdMult or 1.0) or (isAwakened and (data.AwakenedSpdMult or 1.0) or (data.BaseSpdMult or 1.0))
		stats.ResolveMult = isAbyssal and (data.AbyssalResolveMult or 1.0) or (isAwakened and (data.AwakenedResolveMult or 1.0) or (data.BaseResolveMult or 1.0))
		stats.HpMult = isAbyssal and (data.AbyssalHpMult or 1.0) or (isAwakened and (data.AwakenedHpMult or 1.0) or (data.BaseHpMult or 1.0))

		stats.Survivals = isAbyssal and (data.AbyssalSurvivals or 0) or (isAwakened and (data.AwakenedSurvivals or 0) or (data.BaseSurvivals or 0))
		stats.SurvivalChance = data.SurvivalChance or 0
		stats.DodgeBonus = isAbyssal and (data.AbyssalDodgeBonus or data.DodgeBonus or 0) or (data.DodgeBonus or 0)

		stats.NapeCritMultiplier = isAbyssal and (data.AbyssalNapeCritMultiplier or data.NapeCritMultiplier or 1.5) or (data.NapeCritMultiplier or 1.5)
		stats.MomentumDamagePerHit = isAbyssal and (data.AbyssalMomentumDamagePerHit or data.MomentumDamagePerHit or 0) or (data.MomentumDamagePerHit or 0)
		stats.MaxMomentumStacks = isAbyssal and (data.AbyssalMaxMomentumStacks or data.MaxMomentumStacks or 0) or (data.MaxMomentumStacks or 0)
		stats.GasEfficiency = data.GasEfficiency or 1.0

		if isTransformed and titanNameStr and data.TitanSynergies then
			for tName, tData in pairs(data.TitanSynergies) do
				if string.find(titanNameStr, tName) then
					stats.DmgMult += (tData.DmgMult or 0)
					stats.ArmorMult += (tData.ArmorMult or 0)
					stats.SpdMult += (tData.SpdMult or 0)
					stats.CritBonus += (tData.CritBonus or 0)
					stats.HpMult += (tData.HpMult or 0)
				end
			end
		end
	end

	return stats
end

return ClanData