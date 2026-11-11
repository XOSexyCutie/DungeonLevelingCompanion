local _, ns = ...

-- Classic (vanilla) XP needed to go from level L to L+1. Forever uses the same table.
ns.XP = {
    400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
    8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
    25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
    50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
    95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
    153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800,
}

-- Dungeon level ranges from Wowhead's WoW Forever dungeon overview (1.60.1): { min, max }.
-- `min` is when a dungeon opens up; the panel points you at the next one and its prequests.
local LEVELS = {
    rfc = { 13, 18 }, hot = { 13, 18 }, rol = { 15, 20 }, wc = { 15, 25 }, dm = { 18, 23 },
    sfk = { 22, 30 }, stocks = { 22, 30 }, bfd = { 24, 32 }, exc = { 24, 29 }, dal = { 28, 33 },
    smgy = { 28, 38 }, gnomer = { 29, 38 }, smlib = { 29, 39 }, rfk = { 30, 40 }, smarm = { 32, 42 },
    drowned = { 35, 40 }, smcath = { 35, 45 }, krol = { 40, 45 }, rfd = { 40, 50 }, ulda = { 42, 52 },
    zf = { 44, 54 }, mara = { 45, 57 }, alcaz = { 48, 53 }, st = { 50, 60 }, brd = { 52, 60 },
    blackmaw = { 55, 60 }, lbrs = { 55, 60 }, dme = { 58, 60 }, dmw = { 58, 60 }, dmn = { 58, 60 },
    shaper = { 58, 60 }, ubrs = { 58, 60 }, stratlive = { 58, 60 }, stratud = { 58, 60 }, scholo = { 58, 60 },
}
ns.LEVELS = LEVELS

-- Alliance dungeons. The route is sorted by min level when it's built.
--   key       short id for slash commands
--   tier      Spelunker achievement (nil = not required)
--   match     lowercase pieces of the instance name (GetInstanceInfo) that identify it
--   subzones  lowercase subzones that tell apart wings sharing one instance name
--   questList "Quest Name (where/giver) [questID]" - the [id] is optional, only where known.
--   secret    hidden boss: { boss = name, how = how to summon it }
--             Quest lists and prerequisites follow Wowhead's Classic dungeon quest guide.
local ALLIANCE = {
    { key = "hot", name = "Hall of Thanes", tier = "Novice",
      match = { "hall of thanes" },
      note = "Do 'Nip 'Em in the Bud' (Dark Iron Spies, Dun Morogh) for the Dark Iron Map quest.",
      questList = { "Important Heirlooms (Thom Filch, outside)", "The Restless Dead (Afadra Dunwall)",
                    "Old Ironforge Incursion (Earthseer Farsen, Dun Morogh)", "An Ancient Grudge (Ghostly Attendant, inside)",
                    "The Treaty of Understanding (tablet in final boss vault)" } },
    { key = "dm", name = "The Deadmines", tier = "Novice",
      match = { "deadmines" },
      note = "Finish the Defias Brotherhood chain first; grab the sleeping bag note in Westfall. Paladin: Whitestone Oak Lumber.",
      questList = { "The Defias Brotherhood (Gryan Stoutmantle, Sentinel Hill) [166]", "Red Silk Bandanas (Scout Riell, Sentinel Hill) [214]",
                    "Collecting Memories (Wilder Thistlenettle, SW Dwarven District) [168]", "Oh Brother. . . (Wilder Thistlenettle, SW Dwarven District) [167]",
                    "Underground Assault (Shoni the Shilent, SW Dwarven District) [2040]", "The Unsent Letter (drops from VanCleef) [373]",
                    "Destruction in Deadmines [92753]" } },
    { key = "wc", name = "Wailing Caverns", tier = "Novice",
      match = { "wailing caverns" },
      note = "Neutral quests from Ratchet. Sleeping bag: Barrens tower + Stonetalon on the way. Deviate hides for skinning/LW.",
      questList = { "Deviate Hides (Nalpak, above WC entrance) [1486]", "Deviate Eradication (Ebru, above WC entrance) [1487]",
                    "Trouble at the Docks (Crane Operator Bigglefuzz, Ratchet) [959]", "Smart Drinks (Mebok Mizzyrix, Ratchet) [1491]",
                    "The Glowing Shard (drops from Mutanus) [6981]" } },
    { key = "rol", name = "Ruins of Lordaeron", tier = "Novice",
      match = { "ruins of lordaeron" },
      note = "Long walk for Alliance (Loch Modan dam + Thoradin's Wall finish the sleeping bag). Pair with SFK. Quests are picked up inside.",
      secret = { boss = "Viktor the Vile", how = "After Rath'mael: take the Soul Flame from the brazier behind his altar to the brazier by the southwest sewer gate, then survive the waves. Guides differ on the details." },
      questList = { "Abominable Creatures (Captain Truman, entrance)", "Bloodied Insignia (drops inside)", "Remember That I Love You (inside)",
                    "Crest of Lordaeron (found inside)",
                    "Friend of the Kirin Tor (from level 24) [92459]" } },
    { key = "sfk", name = "Shadowfang Keep", tier = "Novice",
      match = { "shadowfang" },
      note = "One run for the Spelunker achievement. Paladin: Jordan's Smithing Hammer. Loot the Black Tome behind Arugal (Dalaran secret boss).",
      questList = { "The Test of Righteousness (paladin only)" } },
    { key = "bfd", name = "Blackfathom Deeps", tier = "Experienced",
      match = { "blackfathom" },
      note = "Paladin: Kor Gem. Grab Darnassus/Auberdine quests on the way.",
      questList = { "Knowledge in the Deeps (Gerrig Bonegrip, IF Forlorn Cave) [971]", "Researching the Corruption (Gershala Nightwhisper, Auberdine) [1275]",
                    "Twilight Falls (Argent Guard Manados, Darnassus) [1199]", "Blackfathom Villainy (Argent Guard Thaelrid, inside) [1200]" } },
    { key = "stocks", name = "The Stockade", tier = nil,
      match = { "stockade" },
      note = "Optional - not part of any Spelunker achievement. Short and quest-dense.",
      questList = { "Quell the Uprising (Warden Thelwater, SW) [387]", "The Stockade Riots (Warden Thelwater, SW) [391]",
                    "What Comes Around... (Guard Berton, Lakeshire) [386]", "The Color of Blood (Nikova Raskol, SW Old Town) [388]",
                    "The Fury Runs Deep (Motley Garmason, Dun Modr) [378]", "Crime and Punishment (Councilman Millstipe, Darkshire) [377]" } },
    { key = "rfk", name = "Razorfen Kraul", tier = "Experienced",
      match = { "razorfen kraul" },
      note = "Combine with a Barrens/Ratchet trip. Grab the Blueleaf Tubers items next to Mebok.",
      questList = { "Blueleaf Tubers (Mebok Mizzyrix, Ratchet)", "Mortality Wanes (Heralath Fallowbrook, inside)", "Willix the Importer (escort, inside)",
                    "The Crone of the Kraul (Falfindel Waywarder, Thalanaar - Feralas) [1101]" } },
    { key = "exc", name = "Excavation Site: Wetlands", tier = "Novice",
      match = { "excavation site" },
      note = "Quests from level 24. Thicket raptors = skinning.",
      questList = { "Songblade Search (Dorin Songblade, Lakeshire)", "Lost in the Thicket Things (Caitlin Grassman, Menethil)",
                    "Horrors in the Highland (Rethiel the Greenwarden, Wetlands)", "Highland Hides (James Halloran, Menethil)",
                    "Lost Relic Carry (drops from Relic Guardian)",
                    "Seeking Caitlin [95737]", "Fallen in the Fen [95795]", "Heartwoven [95809]", "Prehistoric Prism [98824]" } },
    { key = "gnomer", name = "Gnomeregan", tier = "Experienced",
      match = { "gnomeregan" },
      note = "Long. Most quests are in Ironforge's Tinkertown. Someone needs the Workshop Key for the back door.",
      questList = { "Save Techbot's Brain! (Tinkmaster Overspark, IF Tinkertown)", "Essential Artificials (Klockmort Spannerspan, IF Tinkertown)",
                    "Data Rescue (Master Mechanic Castpipe, IF Tinkertown)", "The Grand Betrayal (High Tinker Mekkatorque, IF Tinkertown)",
                    "Gyrodrillmatic Excavationators (Shoni the Shilent, SW Dwarven District)", "Gnogaine (Ozzie Togglevolt, Kharanos)",
                    "The Only Cure is More Green Glow (Ozzie Togglevolt, after Gnogaine)", "A Fine Mess (escort Kernobee, inside)",
                    "Grime-Encrusted Ring (drop inside) [2945]" } },
    { key = "smgy", name = "SM Graveyard", tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "graveyard", "forlorn cloister", "chamber of atonement", "honor's tomb" },
      note = "Fast runs - watch the 5 instances/hour cap. No Alliance quests here.",
      questList = {} },
    { key = "dal", name = "City of Dalaran", tier = "Experienced",
      match = { "dalaran" },
      note = "New Forever dungeon. Needs An Alarming Request (Southshore, level 30) for the Dalaran Sewer Key (only one player needs the key). Most mobs are Arcane immune.",
      secret = { boss = "Lyn the Ignored", how = "Use the Tome of Dalaran on the summoning circle in the small room past Atrexis the Grave Knight (straight ahead, not up the ramp)." },
      questList = { "Power Overwhelming (High Sorcerer Andromath, SW Mage Quarter) [92489]", "A Green Sample (Shylamiir, SW The Park) [92456]",
                    "Heart of Disruption (Image of Archmage Modera, Silverpine shore - after An Alarming Request) [92458]", "Starving Arcane (outside the dungeon entrance) [92457]" } },
    { key = "smlib", name = "SM Library", tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "library", "huntsman's cloister", "gallery of treasures", "athenaeum" },
      note = "The Scarlet Key (for Armory/Cathedral) drops here.",
      questList = { "Mythology of the Titans (Librarian Mae Paledust, IF Hall of Explorers)", "Past Due [96800]" } },
    { key = "drowned", name = "The Drowned City", tier = "Experienced",
      match = { "drowned city" },
      note = "New Forever dungeon. Quests from level 30 (Saltseer quests and Gurubashi Secrets from 34).",
      questList = { "Take Two With Water [95787]", "Magics of the Drowned City [95788]",
                    "Shady Saltseers (Krazek, Booty Bay) [95789]", "The Saltseer Captain (Krazek, Booty Bay) [95791]",
                    "Ancient Gurubashi Secrets (Archmage Timear) [97130]" } },
    { key = "smarm", name = "SM Armory", tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "armory", "training grounds", "footman's armory", "crusader's armory", "hall of champions" },
      note = "Needs the Scarlet Key (Library drop).",
      questList = {} },
    { key = "smcath", name = "SM Cathedral", tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "cathedral", "chapel gardens", "crusader's chapel" },
      note = "Needs the Scarlet Key. Turn in 'In the Name of the Light' at Southshore.",
      questList = { "In the Name of the Light (Raleigh the Devout, Southshore)" } },
    { key = "rfd", name = "Razorfen Downs", tier = "Master",
      match = { "razorfen downs" },
      note = "Whole party must finish Scourge of the Downs before taking Extinguishing the Idol.",
      questList = { "Bring the Light (Archbishop Benedictus, SW Cathedral)", "A Host of Evil (Myriam Moonsinger, outside RFD)",
                    "Scourge of the Downs (Belnistrasz, inside)", "Extinguishing the Idol (Belnistrasz escort, inside)",
                    "The Coldbringer's Eye [96773]", "Agamaggan's Blood [93604]" } },
    { key = "ulda", name = "Uldaman", tier = "Master",
      match = { "uldaman" },
      note = "Lots of quests - do the Loch Modan/Badlands prereqs first.",
      questList = { "The Lost Dwarves (Prospector Stormpike, IF Hall of Explorers)", "The Hidden Chamber (Baelog's Journal, inside)",
                    "Agmond's Fate (Prospector Ironband, Loch Modan)", "Uldaman Reagent Run (Ghak Healtouch, Thelsamar)",
                    "Power Stones (Rigglefuzz, Badlands)", "Solution to Doom (Theldurin the Lost, Badlands)",
                    "Reclaimed Treasures (Krom Stoutarm, IF Hall of Explorers)", "The Shattered Necklace (drop outside Uldaman)",
                    "The Platinum Discs (inside, after Archaedas)" } },
    { key = "krol", name = "Krol'dok Stronghold", tier = "Experienced",
      match = { "krol'dok", "kroldok" },
      note = "New Forever dungeon. Do A Small Favor first for Tome of Twilight; Lingering Essence follows Twilight Mementos.",
      questList = { "Krol'dok Moulding [94980]", "Key Ingredients [94981]", "Eye of Mugg [94982]", "Twilight Mementos [94983]",
                    "Tome of Twilight (after A Small Favor) [94984]", "Lingering Essence (after Twilight Mementos) [94997]",
                    "Curios of Curiosity [94998]", "Vengeance of the Highborne [96771]",
                    "Krol'dok No More! (escort Marcus Tilwell, inside) [94969]" } },
    { key = "zf", name = "Zul'Farrak", tier = "Master",
      match = { "zul'farrak", "zulfarrak" },
      note = "Gahz'rilla needs the Mallet of Zul'Farrak (Hinterlands). Basilisks = skinning.",
      questList = { "Divino-matic Rod (Chief Engineer Bilgewhizzle, Gadgetzan)", "Scarab Shells (Tran'rek, Gadgetzan)",
                    "Troll Temper (Trenton Lighthammer, Gadgetzan)", "Tiara of the Deep (Tabetha, Dustwallow Marsh)",
                    "Gahz'rilla (Wizzle Brassbolts, Shimmering Flats)", "The Prophecy of Mosh'aru (Yeh'kinya, Steamwheedle Port)",
                    "Nekrum's Medallion (Thadius Grimshade, Nethergarde Keep)", "The Witch Doctor's Head [96770]" } },
    { key = "mara", name = "Maraudon", tier = "Master",
      match = { "maraudon" },
      note = "Skinning. Nijel's Point and Theramore quests.",
      questList = { "Shadowshard Fragments (Archmage Tervosh, Theramore)", "Vyletongue Corruption (Talendria, Nijel's Point)",
                    "Corruption of Earth and Seed (Keeper Marandis, Nijel's Point)", "Twisted Evils (Willow, Desolace)",
                    "Legends of Maraudon (Cavindra, outside)", "The Scepter of Celebras (Celebras the Redeemed, inside)",
                    "Seed of Life (Zaetar's Spirit, inside)", "The Pariah's Instructions (Centaur Pariah, Desolace)",
                    "Rot and Regret [93404]" } },
    { key = "alcaz", name = "Alcaz Prison", tier = "Master",
      match = { "alcaz" },
      note = "New Forever dungeon. Alcaz Island, off Dustwallow Marsh. Do the SI:7 chain (Our Man in Theramore) first for The Secret Prison.",
      questList = { "The Secret Prison (after The Return of the King?) [95262]", "The Man in the Iron Chains (Ornate Shackle Key from The Questioner, inside) [96335]",
                    "More Valuable Than Gold (Mason Connery, inside - after freeing him) [96337]", "A Bit of Wet Work (for Sully McCleary, Dustwallow Marsh) [96381]",
                    "State Secrets (Document Box, inside) [96377]", "The Dragon's Journal (Zarla's Journal, inside) [96772]",
                    "Somber News (back to Sully McCleary, Dustwallow Marsh) [95263]" } },
    { key = "st", name = "Sunken Temple", tier = "Master",
      match = { "sunken temple", "atal'hakkar" },
      note = "Avatar of Hakkar needs Yeh'kinya's Scroll.",
      questList = { "Into The Temple of Atal'Hakkar (Brohann Caskbelly, SW Dwarven District)", "Into the Depths (Marvon Rivetseeker, Tanaris)",
                    "Secret of the Circle (Marvon Rivetseeker, Tanaris)", "Jammal'an the Prophet (Atal'ai Exile, Hinterlands)",
                    "The God Hakkar (Yeh'kinya, Steamwheedle Port)", "The Essence of Eranikus (drop inside)" } },
    { key = "brd", name = "Blackrock Depths", tier = "Master",
      match = { "blackrock depths" },
      note = "Long - split into wings. Dark Iron Legacy gives the Shadowforge Key.",
      questList = { "Dark Iron Legacy (Franclorn Forgewright, Blackrock Mtn - visible while dead)", "Hurley Blackbreath (Ragnar Thunderbrew, Kharanos)",
                    "Overmaster Pyron (Jalinda Sprig, Morgan's Vigil)", "Incendius! (Jalinda Sprig, after Overmaster Pyron)",
                    "The Good Stuff (Oralius, Morgan's Vigil)", "Ribbly Screwspigot (Yuka Screwspigot, Flame Crest)",
                    "The Heart of the Mountain (Maxwort Uberglint, Flame Crest)", "The Love Potion (Mistress Nagmara, inside)",
                    "Kharan Mighthammer (King Magni, IF)", "The Fate of the Kingdom (King Magni, IF)",
                    "Attunement to the Core (Lothos Riftwaker, Blackrock Mtn)" } },
    { key = "blackmaw", name = "Blackmaw Hold", tier = "Master",
      match = { "blackmaw" },
      note = "New Forever dungeon. Azshara. Big furbolg city with several routes and bosses - estimates assume a BRD-sized run. Get to the Roots of It follows Beneath Nordrassil.",
      questList = { "Get to the Roots of It (after Beneath Nordrassil) [92344]", "Blackmaw Magic (Archmage Timear) [97173]",
                    "The Twin Bears (Lorekeeper Nok, Ursolan) [92066]", "Claws That Rend, Tusks that Gore (Ogtinc, Azshara) [92069]",
                    "Feeding Time! [92067]", "A Lost Memento (Feathered Charm Necklace, inside - to Unele) [92070]",
                    "Blackmaw Pouches (Ekkal, Ruins of Eldarath) [97327]",
                    "Blackmaw Reclamation (Gatekeeper Rageroar, Ursolan - end of Master Feardred's chain) [92065]" } },
    { key = "lbrs", name = "Lower Blackrock Spire", tier = "Master",
      match = { "blackrock spire" },
      note = "Seal of Ascension (UBRS key) starts here.",
      questList = { "Put Her Down (Helendis Riverhorn, Morgan's Vigil)", "En-Ay-Es-Tee-Why (Kibler, Flame Crest)",
                    "Kibler's Exotic Pets (Kibler, Flame Crest)", "Mother's Milk (Ragged John, Flame Crest)",
                    "Urok Doomhowl (Warosh, inside)", "Bijou's Belongings (Bijou, inside)", "Seal of Ascension (drop inside)" } },
    { key = "dme", name = "Dire Maul East", tier = "Master",
      match = { "dire maul" }, subzones = { "warpwood quarter", "the hidden reach", "conservatory", "shrine of eldretharr" },
      note = "One run for the achievement while in Feralas.",
      questList = { "Lethtendris's Web (Latronicus Moonspear, Feathermoon)", "Pusillin and the Elder Azj'Tordin (Azj'Tordin, Feralas)" } },
    { key = "shaper", name = "Shaper's Terrace", tier = "Master",
      match = { "shaper" },
      note = "New Forever dungeon. Northern hills of Un'Goro Crater. Bring Un'Goro power crystals for the consoles inside.",
      questList = { "Quests TBD" } },
    { key = "ubrs", name = "Upper Blackrock Spire", tier = "Master",
      match = { "blackrock spire" }, subzones = { "hordemar city", "dragonspire hall", "hall of blackhand", "rookery", "the beast's lair", "blackrock stadium" },
      note = "At 60. Needs Seal of Ascension.", questList = {} },
    { key = "dmw", name = "Dire Maul West", tier = "Master",
      match = { "dire maul" }, subzones = { "capital gardens", "court of the highborne", "prison of immol'thar", "athenaeum" },
      note = "At 60. Needs the Crescent Key (DM East).", questList = {} },
    { key = "dmn", name = "Dire Maul North", tier = "Master",
      match = { "dire maul" }, subzones = { "gordok commons", "halls of destruction", "broken commons" },
      note = "At 60 (tribute run).", questList = {} },
    { key = "stratlive", name = "Stratholme - Live", tier = "Master",
      match = { "stratholme" }, subzones = { "king's square", "market row", "crusaders' square", "the scarlet bastion", "the hall of lights", "the crimson throne" },
      note = "At 60.", questList = {} },
    { key = "stratud", name = "Stratholme - Undead", tier = "Master",
      match = { "stratholme" }, subzones = { "elders' square", "the gauntlet", "slaughter square", "the slaughter house" },
      note = "At 60.", questList = {} },
    { key = "scholo", name = "Scholomance", tier = "Master",
      match = { "scholomance" },
      note = "At 60. Needs the Skeleton Key.", questList = {} },
}

-- Prerequisite quests to do BEFORE a dungeon's first run, one step per quest, in order.
--   q        quest name to track in the quest log
--   id       known quest ID (exact tracking, needed when chain parts share a name)
--   part     part N of `parts` for chains whose quests share one name (tracked by turn-ins)
--   xp       exact quest XP when known (else lvl x 75)
--   lvl      quest level (for the XP estimate)
--   min      estimated minutes, including travel
--   pickup   step is just picking up a quest (done once it's in your log)
--   optional not needed for the main run; left out of the swap estimate
--   unlocks  follow-up quests (names or IDs); if you have or finished one, the step is done
--   item     item step instead of a quest: done once that item ID has been in your bags
--   items    later items in the same chain; having had one also counts the step as done
--   lootIn   dungeon key where the item drops; the panel reminds you to grab it there

-- City of Dalaran secret boss (both factions): Arugal's Black Tome (SFK) becomes the Tome of
-- Dalaran at the Ambermill Leyline Focus, which summons Lyn the Ignored inside Dalaran.
local DALARAN_TOME = {
    { q = "Black Tome", item = 276561, items = { 275989 }, lootIn = "sfk", optional = true, min = 5,
      from = "table behind Arugal, Shadowfang Keep",
      what = "After killing Arugal, take the stairs at the back of his room and loot the Black Tome from the table." },
    { q = "Tome of Dalaran", item = 275989, optional = true, min = 15,
      from = "Ambermill Leyline Focus, Silverpine (63.4, 64.3)",
      what = "Use the Black Tome at the blue crystal next to Archmage Ataeric in the Ambermill town hall. "
          .. "In Dalaran: past Atrexis the Grave Knight, skip the ramp to the Arcane Anomaly, clear the small room "
          .. "straight ahead and use the tome on the summoning circle to summon Lyn the Ignored." },
}

-- Dalaran Sewer Key (Alliance): An Alarming Request leads to Heart of Disruption, which gives the
-- key. Only one player in the group needs it. IDs and coordinates from Wowhead (Forever 1.60.1).
local DALARAN_ALLIANCE = {
    { q = "An Alarming Request", id = 92432, unlocks = { 92458 }, xp = 660, min = 20,
      from = "Emissary Jacques, Southshore (48.3, 60.1) - requires level 30",
      what = "Report to the Image of Archmage Modera on the Silverpine shore of Lordamere Lake (68.4, 45.2). "
          .. "She gives Heart of Disruption and the Dalaran Sewer Key." },
}
for _, s in ipairs(DALARAN_TOME) do table.insert(DALARAN_ALLIANCE, s) end

-- Shaper's Terrace (both factions): power crystals from Un'Goro are used at consoles inside.
-- Blizzard's preview doesn't say which colors or how many, so any crystal counts the step as done.
local UNGORO_CRYSTALS = {
    { q = "Un'Goro Power Crystals", item = 11184, items = { 11185, 11186, 11188 }, min = 20,
      from = "Crystal clusters around Un'Goro Crater",
      what = "Gather Blue, Green, Red and Yellow Power Crystals while questing in Un'Goro - "
          .. "you use them at consoles inside the dungeon. Exact amounts aren't known yet; bring a few of each." },
}

-- Cozy Sleeping Bag (Alliance): picked up in Westfall during the Defias chain, Barrens and
-- Stonetalon on the way to WC, Loch Modan and Thoradin's Wall on the walk to RoL. The quests
-- are level 40 (full XP at any level): 3150 each, Scramble 315, the last one 2350 (Wowhead).
-- Tracked by name: Forever's quest IDs differ from Season of Discovery's.
-- `bag` steps also count as done once you own the Cozy Sleeping Bag.
local BAG_QUESTS = { "Stepping Stones", "Scramble", "Wet Job", "Eagle's Fist", "This Must Be The Place" }
local function After(name)
    local out, found = {}, false
    for _, q in ipairs(BAG_QUESTS) do
        if found then table.insert(out, q) end
        if q == name then found = true end
    end
    return out
end
local BAG_PICKUP = {
    { q = "...and that note you found", pickup = true, bag = true, min = 5, unlocks = BAG_QUESTS,
      from = "Burned-out remains in the wrecked cart, Alexston Farmstead, Westfall (37.1, 50.1)",
      what = "Cozy Sleeping Bag chain: pick up the note while you're in Westfall. The rest is on the way to WC and RoL." },
}
local BAG_BARRENS = {
    { q = "...and that note you found", xp = 3150, bag = true, min = 15, unlocks = BAG_QUESTS,
      from = "Burned tower south of Camp Taurajo, The Barrens (46.1, 74.3)",
      what = "From Ratchet, head south to the burned tower and click the Burned-out Remains." },
    { q = "Stepping Stones", xp = 3150, bag = true, min = 20, unlocks = After("Stepping Stones"),
      from = "Abandoned camp past Sun Rock Retreat, Stonetalon (40.6, 52.4)",
      what = "Follow the hill path northeast of Sun Rock Retreat (50.9, 52.3) to the camp; click the Pocket Litter on the crate." },
    { q = "Rekindle", optional = true, bag = true, min = 2, from = "Campfire at the same camp",
      what = "Use the Flint and Tinder + Simple Wood from the Pocket Litter on the campfire. Optional." },
    { q = "Scramble", xp = 315, bag = true, min = 5, unlocks = After("Scramble"),
      from = "Mound of Dirt on the hill north of the camp (39.6, 49.8)",
      what = "Drop carefully onto the Mound of Dirt - miss and you fall into the ravine." },
}
local BAG_ROL = {
    { q = "Wet Job", xp = 3150, bag = true, min = 10, unlocks = After("Wet Job"),
      from = "Carved figurine on the Stonewrought Dam, Loch Modan (49.4, 12.9)",
      what = "Walk the dam to the middle and drop onto the ledge with the eagle figurine (on the way to the Wetlands)." },
    { q = "Eagle's Fist", xp = 3150, bag = true, min = 10, unlocks = After("Eagle's Fist"),
      from = "Messenger Bag on Thoradin's Wall, Hillsbrad side (87.3, 49.6)",
      what = "Coming from Arathi: climb onto the wall from the leaning cart, follow it to the small platform and click the Messenger Bag." },
    { q = "This Must Be The Place", xp = 2350, bag = true, min = 2,
      from = "Hastily Rolled-Up Satchel, just below the Messenger Bag",
      what = "Click the satchel: Cozy Sleeping Bag + 5 Student Fodder. Lie on it 3 min for Well-Rested (+3% XP)." },
}

-- Cozy Sleeping Bag (Horde): the first two stops are swapped - the note is picked up in the
-- Barrens and turned in in Westfall. Pickup on the way to WC, Westfall on the DM trip,
-- Stonetalon before RFK, Loch Modan dam + Thoradin's Wall around the Wetlands for the
-- Excavation Site. Guides suggest ~30 for the dam: Alliance guards, go as a group.
local BAG_HORDE_PICKUP = {
    { q = "...and that note you found", pickup = true, bag = true, min = 10, unlocks = BAG_QUESTS,
      from = "Burned-out Remains in the burned tower south of Camp Taurajo, The Barrens (46.1, 74.3)",
      what = "Cozy Sleeping Bag chain: pick up the note while you're in the Barrens. You turn it in in Westfall on the Deadmines trip." },
}
local BAG_HORDE_WESTFALL = {
    { q = "...and that note you found", xp = 3150, bag = true, min = 10, unlocks = BAG_QUESTS,
      from = "Wrecked cart, Alexston Farmstead, Westfall (37.1, 50.1)",
      what = "Turn the note in at the remains by the wrecked cart while you're in Westfall for DM. Starts Stepping Stones (Stonetalon, before RFK)." },
}
local BAG_HORDE_WETLANDS = {
    { q = "Wet Job", xp = 3150, bag = true, min = 25, unlocks = After("Wet Job"),
      from = "Carved figurine on the Stonewrought Dam, Loch Modan (49.4, 12.9)",
      what = "From the Wetlands go through Dun Algaz to the dam, walk to the middle and drop onto the ledge with the eagle figurine. Alliance guards on the dam - go as a group." },
    { q = "Eagle's Fist", xp = 3150, bag = true, min = 20, unlocks = After("Eagle's Fist"),
      from = "Messenger Bag on Thoradin's Wall, Hillsbrad side (87.3, 49.6)",
      what = "On the way back to Arathi/Hillsbrad: climb onto the wall from the leaning cart, follow it to the small platform and click the Messenger Bag." },
    BAG_ROL[3],
}

local PREP_ALLIANCE = {
    dal = DALARAN_ALLIANCE,
    shaper = UNGORO_CRYSTALS,
    hot = {
        { q = "Nip 'Em in the Bud", unlocks = { "Old Ironforge Incursion" }, lvl = 12, min = 25, from = "Earthseer Farsen, Dun Morogh (64.8, 58.5)",
          what = "Kill 10 Dark Iron Spies (~76, 60). One drops the Dark Iron Map - use it and return to Farsen." },
    },
    -- Verified on Wowhead: quest IDs 65 > 132 > 135 > 141 > 142 > 155, then 166 (VanCleef) and Red Silk Bandanas.
    dm = {
        BAG_PICKUP[1],
        { q = "The Defias Brotherhood", id = 65, part = 1, parts = 6, xp = 1350, min = 15, unlocks = { 166, 214 },
          from = "Gryan Stoutmantle, Sentinel Hill", what = "Talk to Wiley the Black in the Lakeshire inn (Redridge)." },
        { q = "The Defias Brotherhood", id = 132, part = 2, parts = 6, xp = 680, min = 15, unlocks = { 166, 214 },
          from = "Wiley the Black, Lakeshire", what = "Take Wiley's item back to Gryan Stoutmantle, Sentinel Hill." },
        { q = "The Defias Brotherhood", id = 135, part = 3, parts = 6, xp = 680, min = 10, unlocks = { 166, 214 },
          from = "Gryan Stoutmantle, Sentinel Hill", what = "Take it to Master Mathias Shaw in Stormwind (Old Town)." },
        { q = "The Defias Brotherhood", id = 141, part = 4, parts = 6, xp = 340, min = 10, unlocks = { 166, 214 },
          from = "Master Mathias Shaw, Stormwind", what = "Report back to Gryan Stoutmantle, Sentinel Hill." },
        { q = "The Defias Brotherhood", id = 142, part = 5, parts = 6, xp = 1350, min = 15, unlocks = { 166, 214 },
          from = "Gryan Stoutmantle, Sentinel Hill", what = "Track down the Defias Messenger in Westfall and bring his message to Gryan." },
        { q = "The Defias Brotherhood", id = 155, part = 6, parts = 6, xp = 1700, min = 15, unlocks = { 166, 214 },
          from = "The Defias Traitor, Sentinel Hill", what = "Escort the Defias Traitor to the Defias hideout in Moonbrook. Then Gryan gives the final part (VanCleef)." },
    },
    wc = {
        { q = "Raptor Horns", unlocks = { 1491 }, lvl = 17, min = 20, from = "Mebok Mizzyrix, Ratchet", what = "Intact Raptor Horns from Barrens raptors. Unlocks Smart Drinks." },
        BAG_BARRENS[1], BAG_BARRENS[2], BAG_BARRENS[3], BAG_BARRENS[4],
    },
    rol = BAG_ROL,
    bfd = {
        { q = "In Search of Thaelrid", unlocks = { 1200 }, pickup = true, min = 10, from = "Dawnwatcher Shaedlass, Darnassus",
          what = "Pick up; find Argent Guard Thaelrid inside BFD. Unlocks Blackfathom Villainy." },
    },
    stocks = {
        { q = "Bazil Thredd", unlocks = { 391 }, lvl = 16, min = 15, from = "Baros Alexston, SW (after The Unsent Letter)",
          what = "Turn in The Unsent Letter (VanCleef drop) to Baros Alexston, then see Warden Thelwater. Unlocks The Stockade Riots." },
        { q = "The Dark Iron War", unlocks = { 378 }, optional = true, lvl = 25, min = 30, from = "Motley Garmason, Dun Modr (Wetlands)",
          what = "Elite quest (level 28-30 mobs). Unlocks The Fury Runs Deep. Optional." },
    },
    exc = {
        { q = "Young Crocolisk Skins", unlocks = { "Highland Hides" }, lvl = 24, min = 20, from = "James Halloran, Menethil (8.6, 55.7)", what = "Crocolisk skins. Unlocks Highland Hides." },
        { q = "Tramping Paws", unlocks = { "Horrors in the Highland" }, lvl = 24, min = 20, from = "Rethiel the Greenwarden, Wetlands (56.3, 40.3)", what = "15 Mosshide Gnolls + 10 Mosshide Mongrels." },
        { q = "Fire Taboo", unlocks = { "Horrors in the Highland" }, lvl = 24, min = 15, from = "Rethiel the Greenwarden", what = "9 Crude Flints from Mosshide gnolls." },
        { q = "Blisters on the Land", unlocks = { "Horrors in the Highland" }, lvl = 24, min = 15, from = "Rethiel the Greenwarden", what = "12 stealthed Fen Creepers near water. Unlocks Horrors in the Highland." },
    },
    smcath = {
        { q = "Brother Anton", unlocks = { "Down the Scarlet Path", "In the Name of the Light" }, lvl = 34, min = 15, from = "Brother Crowley, SW Cathedral", what = "Travel to Brother Anton in Southshore." },
        { q = "Down the Scarlet Path", unlocks = { "In the Name of the Light" }, lvl = 34, min = 30, from = "Brother Anton, Southshore",
          what = "Kill Scarlet Crusaders, then In the Name of the Light from Raleigh the Devout." },
    },
    ulda = {
        { q = "Ironband Wants You!", unlocks = { "Find Agmond", "Murdaloc", "Agmond's Fate" }, lvl = 30, min = 15, from = "Ironforge / Loch Modan", what = "Start of the chain to Agmond's Fate." },
        { q = "Find Agmond", unlocks = { "Murdaloc", "Agmond's Fate" }, lvl = 33, min = 20, from = "Prospector Ironband, Loch Modan", what = "Badlands." },
        { q = "Murdaloc", unlocks = { "Agmond's Fate" }, lvl = 33, min = 20, from = "Badlands", what = "Unlocks Agmond's Fate." },
        { q = "Badlands Reagent Run", unlocks = { "Uldaman Reagent Run" }, lvl = 36, min = 30, from = "Ghak Healtouch, Thelsamar", what = "Badlands reagents. Unlocks Uldaman Reagent Run." },
    },
    zf = {
        { q = "Screecher Spirits", unlocks = { "The Prophecy of Mosh'aru" }, lvl = 40, min = 40, from = "Yeh'kinya, Steamwheedle Port (Tanaris)",
          what = "Capture screecher spirits in Feralas. Unlocks The Prophecy of Mosh'aru." },
        { q = "Witherbark Cages", unlocks = { "The Altar of Zul", "Thadius Grimshade", "Nekrum's Medallion" }, optional = true, lvl = 40, min = 15,
          from = "The Hinterlands", what = "Start of the chain to Nekrum's Medallion. Optional." },
        { q = "The Altar of Zul", unlocks = { "Thadius Grimshade", "Nekrum's Medallion" }, optional = true, lvl = 40, min = 15, from = "The Hinterlands", what = "Optional." },
        { q = "Thadius Grimshade", unlocks = { "Nekrum's Medallion" }, optional = true, lvl = 40, min = 15, from = "Nethergarde Keep, Blasted Lands",
          what = "Talk to Thadius Grimshade. Unlocks Nekrum's Medallion. Optional." },
    },
    st = {
        { q = "In Search of The Temple", unlocks = { "To The Hinterlands", "Gryphon Master Talonaxe", "Rhapsody Shindigger", "Rhapsody's Tale", "Into The Temple of Atal'Hakkar" },
          lvl = 38, min = 10, from = "Brohann Caskbelly, SW Dwarven District", what = "Start of the chain to Into The Temple of Atal'Hakkar." },
        { q = "To The Hinterlands", unlocks = { "Gryphon Master Talonaxe", "Rhapsody Shindigger", "Rhapsody's Tale", "Into The Temple of Atal'Hakkar" },
          lvl = 38, min = 15, from = "Brohann Caskbelly", what = "Travel to the Hinterlands (Aerie Peak)." },
        { q = "Gryphon Master Talonaxe", unlocks = { "Rhapsody Shindigger", "Rhapsody's Tale", "Into The Temple of Atal'Hakkar" },
          lvl = 38, min = 10, from = "Aerie Peak, Hinterlands", what = "Talk to Gryphon Master Talonaxe." },
        { q = "Rhapsody Shindigger", unlocks = { "Rhapsody's Tale", "Into The Temple of Atal'Hakkar" }, lvl = 38, min = 15, from = "Gryphon Master Talonaxe",
          what = "Find Rhapsody Shindigger." },
        { q = "Rhapsody's Tale", unlocks = { "Into The Temple of Atal'Hakkar" }, lvl = 38, min = 10, from = "Rhapsody Shindigger",
          what = "Listen to Rhapsody's tale. Unlocks Into The Temple of Atal'Hakkar." },
        { q = "The Sunken Temple", unlocks = { "The Stone Circle", "Into the Depths", "Secret of the Circle" }, lvl = 46, min = 15,
          from = "Angelas Moonbreeze, Feathermoon Stronghold (Feralas)", what = "Go to Marvon Rivetseeker in Tanaris." },
        { q = "The Stone Circle", unlocks = { "Into the Depths", "Secret of the Circle" }, lvl = 46, min = 20, from = "Marvon Rivetseeker, Tanaris (52, 45)",
          what = "Unlocks Into the Depths and Secret of the Circle." },
        { q = "The Ancient Egg", unlocks = { "The God Hakkar" }, lvl = 45, min = 30, from = "Yeh'kinya, Steamwheedle Port",
          what = "After The Prophecy of Mosh'aru (ZF). Unlocks The God Hakkar." },
    },
    brd = {
        { q = "The Smoldering Ruins of Thaurissan", part = 1, parts = 2, unlocks = { "Kharan Mighthammer" }, lvl = 50, min = 20,
          from = "Royal Historian Archesonus, IF", what = "First part (Burning Steppes / Blackrock Mtn)." },
        { q = "The Smoldering Ruins of Thaurissan", part = 2, parts = 2, unlocks = { "Kharan Mighthammer" }, lvl = 50, min = 10,
          from = "Royal Historian Archesonus, IF", what = "Second part. Unlocks Kharan Mighthammer." },
    },
    -- Forever quest chains from Wowhead's quest series (1.60.1); quest levels are estimates.
    krol = {
        { q = "A Small Favor", id = 94907, unlocks = { 94984 }, lvl = 40, min = 15,
          from = "see Wowhead quest 94907", what = "Unlocks Tome of Twilight for Krol'dok Stronghold." },
    },
    blackmaw = {
        { q = "Beneath Nordrassil", id = 92345, unlocks = { 92344 }, lvl = 55, min = 20,
          from = "see Wowhead quest 92345", what = "Unlocks Get to the Roots of It for Blackmaw Hold." },
    },
    -- Alcaz Prison SI:7 chain from Wowhead's quest series (2026-11-10). Givers past the first aren't on Wowhead yet.
    alcaz = {
        { q = "Our Man in Theramore", id = 95194, unlocks = { 95196, 95198, 95262, 96335 }, lvl = 53, min = 15,
          from = "SI:7 - see Wowhead quest 95194", what = "Find Shaw's agent on Theramore Isle." },
        { q = "Watch Yer Back", id = 95196, unlocks = { 95198, 95262, 96335 }, lvl = 53, min = 20,
          from = "Shaw's agent, Theramore", what = "Second part of the SI:7 chain." },
        { q = "The Return of the King?", id = 95198, unlocks = { 95262, 96335 }, lvl = 53, min = 15,
          from = "Theramore / Dustwallow Marsh", what = "Unlocks The Secret Prison for Alcaz Prison." },
    },
}

-- Horde dungeons. Tier, instance matching and secrets are shared with the Alliance entries
-- above; only the quests, notes and prerequisites differ.
-- Ragefire Chasm fills the "Ragefire Chasm or Hall of Thanes" Novice Spelunker slot.
-- The Stockade (Stormwind, optional) is left out.
local EXTRA = {
    rfc = { key = "rfc", name = "Ragefire Chasm", tier = "Novice", match = { "ragefire" } },
}

local HORDE = {
    { "rfc", note = "Hidden Enemies needs the first parts of Thrall's chain.",
      questList = { "Slaying the Beast (Neeru Fireblade, Orgrimmar Cleft of Shadow)", "Testing an Enemy's Strength (Rahauro, Thunder Bluff)",
                    "The Power to Destroy... (Varimathras, Undercity)", "Searching for the Lost Satchel (Maur Grimtotem's satchel, inside)",
                    "Hidden Enemies (Thrall, Orgrimmar)" } },
    { "rol", note = "Easy Horde access from Undercity. Several quests start/end in Undercity.",
      questList = { "Light's Justice (Morbin Lightbane, Undercity Royal Quarter)", "The New Plague (Theodore Griffs, Undercity Apothecarium)",
                    "The Wrath of Rath'mael (Deathguard Kristof, Tirisfal 65, 60)", "A Frightened Request (Tabetha Heartweaver, The Sepulcher)",
                    "Unending Torment (Abominable Head drop, inside)", "Crest of Lordaeron (found inside)",
                    "Shrewd Negotiations (from level 24) [97287]" } },
    { "wc", note = "Deviate hides for skinning/LW. Sleeping bag: grab the note in the burned tower south of Camp Taurajo.",
      questList = { "Serpentbloom (Apothecary Zamah, Thunder Bluff)", "Leaders of the Fang (Nara Wildmane, Thunder Bluff)",
                    "Deviate Hides (Nalpak, above WC entrance) [1486]", "Deviate Eradication (Ebru, above WC entrance) [1487]",
                    "Trouble at the Docks (Crane Operator Bigglefuzz, Ratchet) [959]", "Smart Drinks (Mebok Mizzyrix, Ratchet) [1491]",
                    "The Glowing Shard (drops from Mutanus) [6981]" } },
    { "sfk", note = "Quests from the Sepulcher (Silverpine) and Undercity. Loot the Black Tome behind Arugal (Dalaran secret boss).",
      questList = { "Deathstalkers in Shadowfang (High Executor Hadrec, The Sepulcher)", "Arugal Must Die (Dalar Dawnweaver, The Sepulcher)",
                    "The Book of Ur (Keeper Bel'dugur, Undercity Apothecarium)" } },
    { "bfd", note = "Quests from Zoram'gar Outpost (Ashenvale coast).",
      questList = { "The Essence of Aku'Mai (Je'neu Sancrea, Zoram'gar Outpost)", "Amongst the Ruins (Je'neu Sancrea, Zoram'gar Outpost)",
                    "Blackfathom Villainy (Argent Guard Thaelrid, inside)", "Baron Aquanis (Strange Water Globe drop)",
                    "Allegiance to the Old Gods (Damp Note drop outside - rare)",
                    "Trouble in the Deeps (Tsunaman, Sun Rock Retreat - Stonetalon) [6562]" } },
    { "dm", note = "One run for Novice Spelunker - no Horde quests. Long trip to Westfall: turn in the sleeping bag note at Alexston Farmstead.", questList = {} },
    { "rfk", note = "Combine with a Barrens/Ratchet trip. Grab the Blueleaf Tubers items next to Mebok. Sleeping bag: Stonetalon camp past Sun Rock Retreat first.",
      questList = { "A Vengeful Fate (Auld Stonespire, Thunder Bluff)", "Going, Going, Guano! (Master Apothecary Faranell, Undercity)",
                    "Blueleaf Tubers (Mebok Mizzyrix, Ratchet)", "Willix the Importer (escort, inside)",
                    "An Unholy Alliance (Small Scroll drop from Charlga Razorflank)" } },
    { "exc", note = "Thicket raptors = skinning. Sleeping bag: Loch Modan dam (through Dun Algaz) + Thoradin's Wall finish it - Alliance guards on the dam.",
      questList = { "Changing Tastes (Borstan, Orgrimmar The Drag)", "Open the Maw (Deathstalker Agent, Wetlands 51, 59)",
                    "Elder Knowledge (Titan Relic drop from Relic Guardian)", "Earthen Echo [98823]" } },
    { "gnomer", note = "Long. Someone needs the Workshop Key for the back door.",
      questList = { "Rig Wars (Nogg, Orgrimmar Valley of Honor)", "Chief Engineer Scooty (Sovik, Orgrimmar - after Rig Wars)",
                    "Gnomer-gooooone! (Scooty, Booty Bay)", "A Fine Mess (escort Kernobee, inside)", "Grime-Encrusted Ring (drop inside)" } },
    { "smgy", note = "Fast runs - watch the 5 instances/hour cap.",
      questList = { "Vorrel's Revenge (Vorrel Sengutz, inside)", "Hearts of Zeal (Master Apothecary Faranell, Undercity)" } },
    { "dal", note = "New Forever dungeon. Needs the Dalaran Sewer Key chain from Tarren Mill (only one player needs the key). Swim over from Silverpine. Most mobs are Arcane immune.",
      questList = { "The Grave Knight (Melisara, Tarren Mill) [96986]", "Source of Power (Doctor Martin Felben, Undercity Apothecarium) [96988]",
                    "Opportunistic Education (Rexxie Copperclutch, at the dungeon entrance) [96987]",
                    "Heart of Disruption (Image of Archmage Modera, outside Dalaran - end of the Sewer Key chain) [96984]" } },
    { "smlib", note = "The Scarlet Key (for Armory/Cathedral) drops here.",
      questList = { "Compendium of the Fallen (Sage Truthseeker, Thunder Bluff - not Undead)", "Test of Lore (Parqual Fintallas, Undercity)" } },
    { "drowned", note = "New Forever dungeon. Quests from level 30 (Saltseer quests from 34). Grom'gol and Booty Bay quests.",
      questList = { "The Drowned City (Kin'weelay, Grom'gol) [95775]", "The Only Good Brinescale... (Commander Aggro'gosh, Grom'gol) [95776]",
                    "Shady Saltseers (Krazek, Booty Bay) [95789]", "The Saltseer Captain (Krazek, Booty Bay) [95791]",
                    "Ancient Gurubashi Idol (Mazu'kon) [96774]" } },
    { "smarm", note = "Needs the Scarlet Key (Library drop).", questList = {} },
    { "smcath", note = "Needs the Scarlet Key.",
      questList = { "Into The Scarlet Monastery (Varimathras, Undercity)" } },
    { "rfd", note = "Whole party must finish Scourge of the Downs before taking Extinguishing the Idol.",
      questList = { "Bring the End (Andrew Brownell, Undercity Magic Quarter)", "An Unholy Alliance (Varimathras, Undercity - after the RFK scroll)",
                    "A Host of Evil (Myriam Moonsinger, outside RFD)", "Scourge of the Downs (Belnistrasz, inside)",
                    "Extinguishing the Idol (Belnistrasz escort, inside)",
                    "The Coldbringer's Eye [97196]", "Agamaggan's Blood [93604]" } },
    { "ulda", note = "Kargath (Badlands) is the Horde hub for Uldaman.",
      questList = { "Reclaimed Treasures (Patrick Garrett, Undercity)", "Uldaman Reagent Run (Jarkal Mossmeld, Kargath)",
                    "Power Stones (Rigglefuzz, Badlands)", "Solution to Doom (Theldurin the Lost, Badlands)",
                    "Necklace Recovery (Dran Droffers, Undercity) [2283]", "The Platinum Discs (inside, after Archaedas)" } },
    { "krol", note = "New Forever dungeon.",
      questList = { "Krol'dok Moulding [94973]", "Key Ingredients [94974]", "Eye of Mugg [94968]",
                    "Tome of Twilight [94972]", "A Token of Vengeance [94975]" } },
    { "zf", note = "Gahz'rilla needs the Mallet of Zul'Farrak (Hinterlands). Basilisks = skinning.",
      questList = { "The Spider God (Master Gadrin, Sen'jin Village)", "Divino-matic Rod (Chief Engineer Bilgewhizzle, Gadgetzan)",
                    "Scarab Shells (Tran'rek, Gadgetzan)", "Troll Temper (Trenton Lighthammer, Gadgetzan)",
                    "Tiara of the Deep (Tabetha, Dustwallow Marsh)", "Gahz'rilla (Wizzle Brassbolts, Shimmering Flats)",
                    "The Prophecy of Mosh'aru (Yeh'kinya, Steamwheedle Port)", "Zum'rah's Head [96775]" } },
    { "mara", note = "Skinning. Shadowprey Village quests.",
      questList = { "Shadowshard Fragments (Uthel'nay, Orgrimmar Valley of Spirits)", "Vyletongue Corruption (Vark Battlescar, Shadowprey Village)",
                    "Corruption of Earth and Seed (Selendra, south of Shadowprey)", "Twisted Evils (Willow, Desolace)",
                    "Legends of Maraudon (Cavindra, outside)", "The Scepter of Celebras (Celebras the Redeemed, inside)",
                    "Seed of Life (Zaetar's Spirit, inside)", "The Pariah's Instructions (Centaur Pariah, Desolace)",
                    "Rot and Regret [93404]", "An'she's Radiance [96776]" } },
    { "alcaz", note = "New Forever dungeon. Alcaz Island, off Dustwallow Marsh. Do the Kor'kron chain (The Missing Kor'kron) first for No Orc Left Behind.",
      questList = { "No Orc Left Behind (after Right Place, Wrong Time) [95309]", "The Honor of the Kor'kron (after No Orc Left Behind) [95454]",
                    "Bad News for Folkar (back to Commander Folkar) [96369]", "Thrall Needs to Know (Thrall, Orgrimmar) [95483]",
                    "A Little Payback (for Sergeant Ulka) [96332]", "Blood Red Bandanas (human guards, inside) [96334]",
                    "State Secrets (Document Box, inside) [96376]", "The Man in the Iron Chains (Ornate Shackle Key from The Questioner, inside) [96335]",
                    "More Valuable Than Gold (Mason Connery, inside - after freeing him) [96337]" } },
    { "st", note = "Avatar of Hakkar needs Yeh'kinya's Scroll.",
      questList = { "The Temple of Atal'Hakkar (Fel'zerul, Stonard)", "Zapper Fuel (Liv Rizzlefix, Ratchet)",
                    "Into the Depths (Marvon Rivetseeker, Tanaris)", "Secret of the Circle (Marvon Rivetseeker, Tanaris)",
                    "Jammal'an the Prophet (Atal'ai Exile, Hinterlands)", "The God Hakkar (Yeh'kinya, Steamwheedle Port)",
                    "The Essence of Eranikus (drop inside)" } },
    { "brd", note = "Kargath (Badlands) quest hub. Dark Iron Legacy gives the Shadowforge Key.",
      questList = { "KILL ON SIGHT: Dark Iron Dwarves (WANTED poster, Kargath)", "KILL ON SIGHT: High Ranking Dark Iron Officials (WANTED poster, Kargath)",
                    "Lost Thunderbrew Recipe (Shadowmage Vivian Lagrave, Kargath)", "Disharmony of Flame (Thunderheart, Kargath)",
                    "Disharmony of Fire (Thunderheart, after Disharmony of Flame)", "Commander Gor'shak (Galamav the Marksman, Kargath)",
                    "The Last Element (Shadowmage Vivian Lagrave, Kargath)", "Ribbly Screwspigot (Yuka Screwspigot, Flame Crest)",
                    "The Heart of the Mountain (Maxwort Uberglint, Flame Crest)", "The Love Potion (Mistress Nagmara, inside)",
                    "Dark Iron Legacy (Franclorn Forgewright, Blackrock Mtn - visible while dead)", "Attunement to the Core (Lothos Riftwaker, Blackrock Mtn)",
                    "Fragment of the Firelands [97197]" } },
    { "blackmaw", note = "New Forever dungeon. Northern Azshara. Get to the Roots of It follows Beneath Nordrassil.",
      questList = { "Blackmaw Magic [97198]", "Get to the Roots of It (Nara Wildmane, Thunder Bluff) [92343]",
                    "The Twin Bears (Lorekeeper Nok, Ursolan) [92066]", "Claws That Rend, Tusks that Gore (Ogtinc, Azshara) [92069]",
                    "Feeding Time! [92067]", "A Lost Memento (Feathered Charm Necklace, inside - to Unele) [92070]",
                    "Blackmaw Pouches (Ekkal, Ruins of Eldarath) [97327]",
                    "Blackmaw Reclamation (Gatekeeper Rageroar, Ursolan - end of Master Feardred's chain) [92065]" } },
    { "lbrs", note = "Seal of Ascension (UBRS key) starts here.",
      questList = { "The Pack Mistress (Galamav the Marksman, Kargath)", "Operative Bijou (Lexlort, Kargath)",
                    "Warlord's Command (Warlord Goretooth, Kargath)", "Bijou's Belongings (Bijou, inside)",
                    "En-Ay-Es-Tee-Why (Kibler, Flame Crest)", "Kibler's Exotic Pets (Kibler, Flame Crest)",
                    "Mother's Milk (Ragged John, Flame Crest)", "Urok Doomhowl (Warosh, inside)", "Seal of Ascension (drop inside)",
                    "Blood and Thunder [98325]" } },
    { "dme", note = "One run for the achievement while in Feralas.",
      questList = { "Lethtendris's Web (Talo Thornhoof, Camp Mojache)", "Pusillin and the Elder Azj'Tordin (Azj'Tordin, Feralas)" } },
    { "shaper", note = "New Forever dungeon. Un'Goro Crater. Wowhead lists no quests yet.", questList = { "Quests TBD" } },
    { "ubrs" }, { "dmw" }, { "dmn" }, { "stratlive" }, { "stratud" }, { "scholo" },
}

-- Dalaran Sewer Key (Horde): Tarren Mill chain that ends with Heart of Disruption and the key.
-- Only one player in the group needs the key to open the gate. Order and IDs from Wowhead's
-- City of Dalaran guide; quest levels are estimates.
local DALARAN_KEY_HORDE = {
    { q = "Prison Break In", id = 544, unlocks = { 92434, 96984 }, lvl = 24, min = 25, from = "Magus Wordeen Voidglare, Tarren Mill",
      what = "Find the traitors outside Dalaran and recover their artifacts. Take Key to the City from him too." },
    { q = "Key to the City", id = 93680, unlocks = { 92434, 96984 }, lvl = 24, min = 20, from = "Magus Wordeen Voidglare, Tarren Mill",
      what = "Get the Grimy Key for Magus Voidglare." },
    { q = "Dalaran Patrols", id = 545, unlocks = { 92434, 96984 }, lvl = 24, min = 25, from = "Magus Wordeen Voidglare, Tarren Mill",
      what = "Kill 6 Dalaran Summoners and 12 Elemental Slaves outside Dalaran." },
    { q = "Blood in the Streets", id = 92434, unlocks = { 96984 }, lvl = 24, min = 15, from = "Magus Wordeen Voidglare, Tarren Mill",
      what = "Hand it in to the Image of Archmage Modera outside Dalaran. She gives Heart of Disruption and the Dalaran Sewer Key." },
}
local DALARAN_HORDE = {}
for _, s in ipairs(DALARAN_KEY_HORDE) do table.insert(DALARAN_HORDE, s) end
for _, s in ipairs(DALARAN_TOME) do table.insert(DALARAN_HORDE, s) end

local PREP_HORDE = {
    dal = DALARAN_HORDE,
    shaper = UNGORO_CRYSTALS,
    blackmaw = {
        { q = "Beneath Nordrassil", unlocks = { 92343 }, lvl = 55, min = 20,
          from = "see Wowhead quest 92343", what = "Unlocks Get to the Roots of It for Blackmaw Hold." },
    },
    rfc = {
        { q = "Hidden Enemies", part = 1, parts = 2, lvl = 12, min = 15, from = "Thrall, Orgrimmar Valley of Wisdom",
          what = "First part of Thrall's Hidden Enemies chain (Orgrimmar)." },
        { q = "Hidden Enemies", part = 2, parts = 2, lvl = 12, min = 15, from = "Thrall, Orgrimmar Valley of Wisdom",
          what = "Second part. The next Hidden Enemies is done inside RFC." },
    },
    wc = {
        { q = "Raptor Horns", unlocks = { 1491 }, lvl = 17, min = 20, from = "Mebok Mizzyrix, Ratchet", what = "Intact Raptor Horns from Barrens raptors. Unlocks Smart Drinks." },
        { q = "The Forgotten Pools", unlocks = { "The Stagnant Oasis", "Altered Beings", "Hamuul Runetotem", "Nara Wildmane", "Leaders of the Fang" },
          lvl = 14, min = 15, from = "Tonga Runetotem, Crossroads", what = "Start of the chain to Leaders of the Fang." },
        { q = "The Stagnant Oasis", unlocks = { "Altered Beings", "Hamuul Runetotem", "Nara Wildmane", "Leaders of the Fang" },
          lvl = 16, min = 20, from = "Tonga Runetotem, Crossroads", what = "Barrens oasis." },
        { q = "Altered Beings", unlocks = { "Hamuul Runetotem", "Nara Wildmane", "Leaders of the Fang" },
          lvl = 17, min = 20, from = "Tonga Runetotem, Crossroads", what = "Barrens oasis." },
        { q = "Hamuul Runetotem", unlocks = { "Nara Wildmane", "Leaders of the Fang" }, lvl = 17, min = 10, from = "Tonga Runetotem",
          what = "Travel to Hamuul Runetotem, Thunder Bluff." },
        { q = "Nara Wildmane", unlocks = { "Leaders of the Fang" }, lvl = 17, min = 5, from = "Hamuul Runetotem, Thunder Bluff",
          what = "Talk to Nara Wildmane (Elder Rise). Unlocks Leaders of the Fang." },
        BAG_HORDE_PICKUP[1],
    },
    dm = BAG_HORDE_WESTFALL,
    rfk = { BAG_BARRENS[2], BAG_BARRENS[3], BAG_BARRENS[4] },
    exc = {
        { q = "Dragonmaw Rumors", unlocks = { "Open the Maw" }, lvl = 26, min = 25, from = "Zaruk, Hammerfall (Arathi 74.4, 35.6)",
          what = "Leads to the Deathstalker Agent in the Wetlands (51.4, 59.2). Unlocks Open the Maw." },
        BAG_HORDE_WETLANDS[1], BAG_HORDE_WETLANDS[2], BAG_HORDE_WETLANDS[3],
    },
    smgy = {
        { q = "Going, Going, Guano!", unlocks = { "Hearts of Zeal" }, lvl = 33, min = 10, from = "Master Apothecary Faranell, Undercity",
          what = "RFK quest - turn it in to Faranell to unlock Hearts of Zeal." },
    },
    smlib = {
        { q = "Test of Faith", unlocks = { "Test of Endurance", "Test of Strength", "Test of Lore" }, optional = true, lvl = 26, min = 20,
          from = "Undercity / Thousand Needles", what = "Start of the chain to Test of Lore (good wand). Optional." },
        { q = "Test of Endurance", unlocks = { "Test of Strength", "Test of Lore" }, optional = true, lvl = 30, min = 20, from = "Thousand Needles", what = "Optional." },
        { q = "Test of Strength", unlocks = { "Test of Lore" }, optional = true, lvl = 30, min = 20, from = "Thousand Needles",
          what = "Unlocks Test of Lore. Optional." },
    },
    ulda = {
        { q = "Badlands Reagent Run", unlocks = { "Uldaman Reagent Run" }, lvl = 36, min = 30, from = "Jarkal Mossmeld, Kargath",
          what = "Badlands reagents. Unlocks Uldaman Reagent Run." },
    },
    zf = {
        { q = "Venom Bottles", unlocks = { "Undamaged Venom Sac", "Consult Master Gadrin", "The Spider God" }, lvl = 40, min = 15,
          from = "The Hinterlands", what = "Start of the chain to The Spider God." },
        { q = "Undamaged Venom Sac", unlocks = { "Consult Master Gadrin", "The Spider God" }, lvl = 40, min = 20, from = "The Hinterlands", what = "Hinterlands spiders." },
        { q = "Consult Master Gadrin", unlocks = { "The Spider God" }, lvl = 40, min = 10, from = "Sen'jin Village, Durotar",
          what = "Talk to Master Gadrin. Unlocks The Spider God." },
        { q = "Screecher Spirits", unlocks = { "The Prophecy of Mosh'aru" }, lvl = 40, min = 40, from = "Yeh'kinya, Steamwheedle Port (Tanaris)",
          what = "Capture screecher spirits in Feralas. Unlocks The Prophecy of Mosh'aru." },
    },
    st = {
        { q = "Pool of Tears", unlocks = { "The Atal'ai Exile", "Return to Fel'Zerul", "The Temple of Atal'Hakkar" }, lvl = 38, min = 20,
          from = "Fel'zerul, Stonard", what = "Start of the chain to The Temple of Atal'Hakkar." },
        { q = "The Atal'ai Exile", unlocks = { "Return to Fel'Zerul", "The Temple of Atal'Hakkar" }, lvl = 38, min = 20, from = "The Hinterlands",
          what = "Find the Atal'ai Exile." },
        { q = "Return to Fel'Zerul", unlocks = { "The Temple of Atal'Hakkar" }, lvl = 38, min = 10, from = "Stonard",
          what = "Back to Fel'zerul. Unlocks The Temple of Atal'Hakkar." },
        { q = "Larion and Muigin", unlocks = { "Marvon's Workshop", "Zapper Fuel" }, optional = true, lvl = 47, min = 20, from = "Un'Goro Crater",
          what = "Start of the chain to Zapper Fuel. Optional." },
        { q = "Marvon's Workshop", unlocks = { "Zapper Fuel" }, optional = true, lvl = 47, min = 20, from = "Tanaris", what = "Unlocks Zapper Fuel. Optional." },
        { q = "The Sunken Temple", unlocks = { "The Stone Circle", "Into the Depths", "Secret of the Circle" }, lvl = 46, min = 15,
          from = "Witch Doctor Uzer'i, Camp Mojache (Feralas)", what = "Go to Marvon Rivetseeker in Tanaris." },
        { q = "The Stone Circle", unlocks = { "Into the Depths", "Secret of the Circle" }, lvl = 46, min = 20, from = "Marvon Rivetseeker, Tanaris (52, 45)",
          what = "Unlocks Into the Depths and Secret of the Circle." },
        { q = "The Ancient Egg", unlocks = { "The God Hakkar" }, lvl = 45, min = 30, from = "Yeh'kinya, Steamwheedle Port",
          what = "After The Prophecy of Mosh'aru (ZF). Unlocks The God Hakkar." },
    },
    -- Alcaz Prison Kor'kron chain from Wowhead's quest series (2026-11-10). Givers aren't on Wowhead yet.
    alcaz = {
        { q = "The Missing Kor'kron", id = 95283, unlocks = { 95284, 95285, 95309 }, lvl = 53, min = 15,
          from = "see Wowhead quest 95283", what = "Start of the Kor'kron chain for Alcaz Prison." },
        { q = "The Elite of the Elite", id = 95284, unlocks = { 95285, 95309 }, lvl = 53, min = 20,
          from = "see Wowhead quest 95284", what = "Second part of the Kor'kron chain." },
        { q = "Right Place, Wrong Time", id = 95285, unlocks = { 95309 }, lvl = 53, min = 15,
          from = "see Wowhead quest 95285", what = "Unlocks No Orc Left Behind for Alcaz Prison." },
    },
}

---------------------------------------------------------------------------
-- Build the active route for a faction. ns.ROUTE and ns.BY_KEY are filled in place so
-- every file that grabbed them at load sees the right faction.
---------------------------------------------------------------------------
ns.ROUTE, ns.BY_KEY = {}, {}
ns.TIERS = { "Novice", "Experienced", "Master" }

local BASE = {}
for _, d in ipairs(ALLIANCE) do BASE[d.key] = d end
for k, d in pairs(EXTRA) do BASE[k] = d end

local function CopyStats(src)
    local lv = LEVELS[src.key] or { 1, 60 }
    return { key = src.key, name = src.name, tier = src.tier, minLvl = lv[1], maxLvl = lv[2],
             match = src.match, subzones = src.subzones, secret = src.secret }
end

function ns.BuildRoute(faction)
    local route = {}
    if faction == "Horde" then
        for _, h in ipairs(HORDE) do
            local base = BASE[h[1]]
            local d = CopyStats(base)
            d.note = h.note or base.note
            d.questList = h.questList or base.questList or {}
            d.prep = PREP_HORDE[d.key] or {}
            table.insert(route, d)
        end
    else
        for _, a in ipairs(ALLIANCE) do
            local d = CopyStats(a)
            d.note, d.questList = a.note, a.questList
            d.prep = PREP_ALLIANCE[d.key] or {}
            table.insert(route, d)
        end
    end
    -- By min level; ties keep the order of the list above.
    for i, d in ipairs(route) do d.order = i end
    table.sort(route, function(a, b)
        if a.minLvl ~= b.minLvl then return a.minLvl < b.minLvl end
        return a.order < b.order
    end)
    for k in pairs(ns.ROUTE) do ns.ROUTE[k] = nil end
    for k in pairs(ns.BY_KEY) do ns.BY_KEY[k] = nil end
    for i, d in ipairs(route) do
        d.index = i
        ns.ROUTE[i] = d
        ns.BY_KEY[d.key] = d
    end
    ns.faction = (faction == "Horde") and "Horde" or "Alliance"
    if ns.PrepareQuests then ns.PrepareQuests() end
end

-- Alliance until the player's faction is known (rebuilt on ADDON_LOADED).
ns.BuildRoute("Alliance")
