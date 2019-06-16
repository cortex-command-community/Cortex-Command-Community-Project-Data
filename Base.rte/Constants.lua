

-- Misc global constants.. add whatever you like and thinks makes sense across multiple scripts. All should be under the rte table
rte = {};

-- This will be replaced by a more data driven system soon
rte.TechList = {"Browncoats", "Coalition", "Dummy", "Imperatus", "Ronin", "Techion"}; -- Deprecated
rte.OffensiveLoadouts = {"Default", "Infantry Light", "Infantry Heavy", "Infantry CQB", "Infantry Grenadier", "Infantry Sniper", "Mecha"};
rte.DefensiveLoadouts = {"Default", "Infantry Heavy", "Infantry CQB", "Infantry Sniper", "Infantry Engineer", "Mecha"};
rte.EngineerLoadouts = {"Infantry Engineer"};
rte.MOIDCountMax = SettingsMan.RecommendedMOIDCount;--210;
-- Don't let the user set too low number as this will stop the AI from spawning any units at all
if rte.MOIDCountMax < 140 then
	rte.MOIDCountMax = 140
end
rte.DefenderMOIDMax = rte.MOIDCountMax - 80; --140
rte.AIMOIDMax = math.ceil(rte.MOIDCountMax / 4);--50; -- Per every AI team
rte.NoMOID = 255;
rte.SpawnIntervalScale = 1.0;
rte.StartingFundsScale = 1.0;
rte.PassengerMax = 3; -- Deprecated. Use 'Craft.MaxPassengers' instead
rte.DiggersRate = 0.4
rte.MetabaseArea = "MetabaseServiceArea"

-- Materials
rte.airID = 0;
rte.goldID = 2;
rte.doorID = 4;	-- Xenocronium
rte.grassID = 128;
