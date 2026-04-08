-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ClanData = {
	Clans = {
		["Yeager"] = {
			BaseDmgMult = 1.25, AwakenedDmgMult = 1.50,
			TitanSynergies = { ["Attack Titan"] = { DmgMult = 0.30 } }
		},
		["Tybur"] = {
			BaseDmgMult = 1.20, AwakenedDmgMult = 1.40,
			TitanSynergies = { ["War Hammer"] = { DmgMult = 0.30 } }
		},
		["Ackerman"] = {
			BaseDmgMult = 1.25, AwakenedDmgMult = 1.60,
			BaseSpdMult = 1.20, AwakenedSpdMult = 1.60,
			BaseSurvivals = 1, AwakenedSurvivals = 3,
			SurvivalChance = 100,
			-- [[ ACKERMAN OVERHAUL PROPERTIES ]]
			NapeCritMultiplier = 4.0, 
			MomentumDamagePerHit = 0.02, 
			MaxMomentumStacks = 25,
			GasEfficiency = 0.50 
		},
		["Galliard"] = {
			BaseDmgMult = 1.05, AwakenedDmgMult = 1.15,
			BaseSpdMult = 1.15, AwakenedSpdMult = 1.30,
			TitanSynergies = { ["Jaw Titan"] = { SpdMult = 0.25, CritBonus = 25 } }
		},
		["Braun"] = {
			BaseArmorMult = 1.20, AwakenedArmorMult = 1.40,
			TitanSynergies = { ["Armored Titan"] = { ArmorMult = 0.50 } } 
		},
		["Arlert"] = {
			BaseResolveMult = 1.15, AwakenedResolveMult = 1.30,
			TitanSynergies = { ["Colossal Titan"] = { HpMult = 0.50 } }
		},
		["Braus"] = {
			BaseSpdMult = 1.10, AwakenedSpdMult = 1.20,
		},
		["Springer"] = {
			DodgeBonus = 15
		},
		["Reiss"] = {
			BaseHpMult = 1.50, AwakenedHpMult = 2.0
		}
	}
}

function ClanData.GetClanStats(clanNameStr, isAwakened, titanNameStr, isTransformed)
	local baseName = string.gsub(clanNameStr or "None", "Awakened ", "")
	local data = ClanData.Clans[baseName]

	-- Added new default empty stats for the Ackerman overhaul variables
	local stats = {
		DmgMult = 1.0, ArmorMult = 1.0, SpdMult = 1.0, ResolveMult = 1.0, HpMult = 1.0,
		CritBonus = 0, DodgeBonus = 0, Survivals = 0, SurvivalChance = 0,
		NapeCritMultiplier = 2.0, MomentumDamagePerHit = 0, MaxMomentumStacks = 0, GasEfficiency = 1.0
	}

	if data then
		stats.DmgMult = isAwakened and (data.AwakenedDmgMult or 1.0) or (data.BaseDmgMult or 1.0)
		stats.ArmorMult = isAwakened and (data.AwakenedArmorMult or 1.0) or (data.BaseArmorMult or 1.0)
		stats.SpdMult = isAwakened and (data.AwakenedSpdMult or 1.0) or (data.BaseSpdMult or 1.0)
		stats.ResolveMult = isAwakened and (data.AwakenedResolveMult or 1.0) or (data.BaseResolveMult or 1.0)
		stats.HpMult = isAwakened and (data.AwakenedHpMult or 1.0) or (data.BaseHpMult or 1.0)

		stats.Survivals = isAwakened and (data.AwakenedSurvivals or 0) or (data.BaseSurvivals or 0)
		stats.SurvivalChance = data.SurvivalChance or 0
		stats.DodgeBonus = data.DodgeBonus or 0

		-- Pass through Ackerman mechanics
		stats.NapeCritMultiplier = data.NapeCritMultiplier or 2.0
		stats.MomentumDamagePerHit = data.MomentumDamagePerHit or 0
		stats.MaxMomentumStacks = data.MaxMomentumStacks or 0
		stats.GasEfficiency = data.GasEfficiency or 1.0

		-- Apply Titan Specific Synergies if transformed
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