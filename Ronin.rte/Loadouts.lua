--The following is a list of loadout-specific weapon sets that are drawn at random when deploying a Ronin from Loadouts
--Primary, Secondary and Tertiary weapons are always of class HDFirearm
RoninLoadouts = {["Light"] = {}, ["Heavy"] = {}, ["CQB"] = {}, ["Grenadier"] = {}, ["Sniper"] = {}, ["Engineer"] = {}};

RoninLoadouts["Light"]["Primary"] = {"AK-47", "M16A2"};
RoninLoadouts["Light"]["Secondary"] = {".357 Magnum", "Desert Eagle"};
RoninLoadouts["Light"]["Tertiary"] = {"Luger P08", "Beretta 93R", "Shovel", "Medikit"};
RoninLoadouts["Light"]["Throwable"] = {"M67 Grenade", "M24 Potato Masher", "Molotov Cocktail"};

RoninLoadouts["Heavy"]["Headgear"] = {"Soldier Helmet", "Motorcycle Helmet", "Dummy Mask", "Browncoat Mask"};
RoninLoadouts["Heavy"]["Armor"] = {"Chest Plate"};
RoninLoadouts["Heavy"]["Primary"] = {"M60"};
RoninLoadouts["Heavy"]["Secondary"] = {"Luger P08", "Beretta 93R"};
RoninLoadouts["Heavy"]["Tertiary"] = {"Luger P08", "Beretta 93R"};

RoninLoadouts["CQB"]["Headgear"] = {"Dummy Mask", "Browncoat Mask"};
RoninLoadouts["CQB"]["Primary"] = {"Model 590", "SPAS 12"};
RoninLoadouts["CQB"]["Secondary"] = {".357 Magnum", "Desert Eagle", "UZI", "MP5K"};
RoninLoadouts["CQB"]["Tertiary"] = {"Luger P08", "Beretta 93R", "Chainsaw"};

RoninLoadouts["Grenadier"]["Headgear"] = {"Soldier Helmet"};
RoninLoadouts["Grenadier"]["Primary"] = {"RPG-7", "M79", "RPC M17"};
RoninLoadouts["Grenadier"]["Secondary"] = {"UZI", "MP5K"};
RoninLoadouts["Grenadier"]["Throwable"] = {"M67 Grenade", "M24 Potato Masher", "Molotov Cocktail"};

RoninLoadouts["Sniper"]["Headgear"] = {"Sniper Hat"};
RoninLoadouts["Sniper"]["Primary"] = {"Kar98k", "M1 Garand"};
RoninLoadouts["Sniper"]["Secondary"] = {"UZI", "MP5K"};
RoninLoadouts["Sniper"]["Throwable"] = {"Empty Bottle"};

RoninLoadouts["Engineer"]["Headgear"] = {"Soldier Helmet"};
RoninLoadouts["Engineer"]["Primary"] = {"UZI", "MP5K"};
RoninLoadouts["Engineer"]["Secondary"] = {"Shovel"};
RoninLoadouts["Engineer"]["Throwable"] = {"Scrambler"};