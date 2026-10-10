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

-- Alliance route, in order. Mirrors the "Route" tab of the WoW Forever Dungeon Route Google Sheet.
--   key       short id for slash commands
--   start/to  leg: run this dungeon from level `start` until level `to`
--   off       average mob level above you
--   elites    estimated elite kills per full clear
--   quests    number of Alliance dungeon quests (for XP estimates)
--   min       estimated minutes per run
--   tier      Spelunker achievement (nil = not required)
--   match     lowercase pieces of the instance name (GetInstanceInfo) that identify it
--   subzones  lowercase subzones that tell apart wings sharing one instance name
--   questList "Quest Name (where/giver) [questID]" - the [id] is optional, only where known.
--             Quest lists and prerequisites follow Wowhead's Classic dungeon quest guide.
local ALLIANCE = {
    { key = "hot", name = "Hall of Thanes", start = 14, to = 17, off = 1, elites = 90, quests = 5, min = 35, tier = "Novice",
      match = { "hall of thanes" },
      note = "Do 'Nip 'Em in the Bud' (Dark Iron Spies, Dun Morogh) for the Dark Iron Map quest.",
      questList = { "Important Heirlooms (Thom Filch, outside)", "The Restless Dead (Afadra Dunwall)",
                    "Old Ironforge Incursion (Earthseer Farsen, Dun Morogh)", "An Ancient Grudge (Ghostly Attendant, inside)",
                    "The Treaty of Understanding (tablet in final boss vault)" } },
    { key = "dm", name = "The Deadmines", start = 17, to = 19, off = 1, elites = 130, quests = 6, min = 50, tier = "Novice",
      match = { "deadmines" },
      note = "Finish the Defias Brotherhood chain first. Paladin: Whitestone Oak Lumber.",
      questList = { "The Defias Brotherhood (Gryan Stoutmantle, Sentinel Hill) [166]", "Red Silk Bandanas (Scout Riell, Sentinel Hill) [214]",
                    "Collecting Memories (Wilder Thistlenettle, SW Dwarven District) [168]", "Oh Brother. . . (Wilder Thistlenettle, SW Dwarven District) [167]",
                    "Underground Assault (Shoni the Shilent, SW Dwarven District) [2040]", "The Unsent Letter (drops from VanCleef) [373]" } },
    { key = "wc", name = "Wailing Caverns", start = 19, to = 20, off = 1, elites = 130, quests = 5, min = 55, tier = "Novice",
      match = { "wailing caverns" },
      note = "Neutral quests from Ratchet. Deviate hides for skinning/LW.",
      questList = { "Deviate Hides (Nalpak, above WC entrance) [1486]", "Deviate Eradication (Ebru, above WC entrance) [1487]",
                    "Trouble at the Docks (Crane Operator Bigglefuzz, Ratchet) [959]", "Smart Drinks (Mebok Mizzyrix, Ratchet) [1491]",
                    "The Glowing Shard (drops from Mutanus) [6981]" } },
    { key = "rol", name = "Ruins of Lordaeron", start = 20, to = 21, off = 1, elites = 120, quests = 4, min = 45, tier = "Novice",
      match = { "ruins of lordaeron" },
      note = "Long walk for Alliance. Pair with SFK. Quests are picked up inside.",
      questList = { "Abominable Creatures (Captain Truman, entrance)", "Bloodied Insignia (drops inside)", "Remember That I Love You (inside)",
                    "Crest of Lordaeron (inside - may be Horde only)" } },
    { key = "sfk", name = "Shadowfang Keep", start = 21, to = 22, off = 1, elites = 110, quests = 0, min = 45, tier = "Novice",
      match = { "shadowfang" },
      note = "One run for the Spelunker achievement. Paladin: Jordan's Smithing Hammer.",
      questList = { "The Test of Righteousness (paladin only)" } },
    { key = "bfd", name = "Blackfathom Deeps", start = 22, to = 24, off = 1, elites = 110, quests = 5, min = 50, tier = "Experienced",
      match = { "blackfathom" },
      note = "Paladin: Kor Gem. Grab Darnassus/Auberdine quests on the way.",
      questList = { "Knowledge in the Deeps (Gerrig Bonegrip, IF Forlorn Cave) [971]", "Researching the Corruption (Gershala Nightwhisper, Auberdine) [1275]",
                    "Twilight Falls (Argent Guard Manados, Darnassus) [1199]", "Blackfathom Villainy (Argent Guard Thaelrid, inside) [1200]" } },
    { key = "stocks", name = "The Stockade", start = 24, to = 25, off = 0, elites = 70, quests = 6, min = 30, tier = nil,
      match = { "stockade" },
      note = "Optional - not part of any Spelunker achievement. Short and quest-dense.",
      questList = { "Quell the Uprising (Warden Thelwater, SW) [387]", "The Stockade Riots (Warden Thelwater, SW) [391]",
                    "What Comes Around... (Guard Berton, Lakeshire) [386]", "The Color of Blood (Nikova Raskol, SW Old Town) [388]",
                    "The Fury Runs Deep (Motley Garmason, Dun Modr) [378]", "Crime and Punishment (Councilman Millstipe, Darkshire) [377]" } },
    { key = "rfk", name = "Razorfen Kraul", start = 25, to = 26, off = 2, elites = 120, quests = 3, min = 50, tier = "Experienced",
      match = { "razorfen kraul" },
      note = "Combine with a Barrens/Ratchet trip. Grab the Blueleaf Tubers items next to Mebok.",
      questList = { "Blueleaf Tubers (Mebok Mizzyrix, Ratchet)", "Mortality Wanes (Heralath Fallowbrook, inside)", "Willix the Importer (escort, inside)" } },
    { key = "exc", name = "Excavation Site: Wetlands", start = 26, to = 28, off = 1, elites = 120, quests = 4, min = 45, tier = "Novice",
      match = { "excavation site" },
      note = "Quests from level 24. Thicket raptors = skinning.",
      questList = { "Songblade Search (Dorin Songblade, Lakeshire)", "Lost in the Thicket Things (Caitlin Grassman, Menethil)",
                    "Horrors in the Highland (Rethiel the Greenwarden, Wetlands)", "Highland Hides (James Halloran, Menethil)",
                    "Lost Relic Carry (drops from Relic Guardian - bugged in beta)" } },
    { key = "gnomer", name = "Gnomeregan", start = 28, to = 30, off = 1, elites = 150, quests = 8, min = 70, tier = "Experienced",
      match = { "gnomeregan" },
      note = "Long. Most quests are in Ironforge's Tinkertown. Someone needs the Workshop Key for the back door.",
      questList = { "Save Techbot's Brain! (Tinkmaster Overspark, IF Tinkertown)", "Essential Artificials (Klockmort Spannerspan, IF Tinkertown)",
                    "Data Rescue (Master Mechanic Castpipe, IF Tinkertown)", "The Grand Betrayal (High Tinker Mekkatorque, IF Tinkertown)",
                    "Gyrodrillmatic Excavationators (Shoni the Shilent, SW Dwarven District)", "Gnogaine (Ozzie Togglevolt, Kharanos)",
                    "The Only Cure is More Green Glow (Ozzie Togglevolt, after Gnogaine)", "Gnomer-gooooone! (Scooty, Booty Bay)",
                    "A Fine Mess (escort Kernobee, inside)" } },
    { key = "smgy", name = "SM Graveyard", start = 30, to = 31, off = 1, elites = 60, quests = 1, min = 15, tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "graveyard", "forlorn cloister", "chamber of atonement", "honor's tomb" },
      note = "Fast runs - watch the 5 instances/hour cap.",
      questList = { "Vorrel's Revenge (Vorrel Sengutz, inside)" } },
    { key = "dal", name = "City of Dalaran", start = 31, to = 33, off = 1, elites = 200, quests = 5, min = 70, tier = "Experienced",
      match = { "dalaran" },
      note = "In beta. If not live: SM Graveyard/Library until 33.",
      questList = { "5 quests (names TBD)" } },
    { key = "smlib", name = "SM Library", start = 33, to = 35, off = 1, elites = 90, quests = 1, min = 30, tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "library", "huntsman's cloister", "gallery of treasures", "athenaeum" },
      note = "The Scarlet Key (for Armory/Cathedral) drops here.",
      questList = { "Mythology of the Titans (Librarian Mae Paledust, IF Hall of Explorers)" } },
    { key = "drowned", name = "The Drowned City", start = 35, to = 37, off = 1, elites = 150, quests = 5, min = 50, tier = "Experienced",
      match = { "drowned city" },
      note = "Reportedly opens ~Dec 9. If not live: SM Library/Armory until 37.",
      questList = { "Quests TBD" } },
    { key = "smarm", name = "SM Armory", start = 37, to = 38, off = 1, elites = 80, quests = 0, min = 30, tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "armory", "training grounds", "footman's armory", "crusader's armory", "hall of champions" },
      note = "Needs the Scarlet Key (Library drop).",
      questList = {} },
    { key = "smcath", name = "SM Cathedral", start = 38, to = 39, off = 1, elites = 100, quests = 1, min = 35, tier = "Experienced",
      match = { "scarlet monastery" }, subzones = { "cathedral", "chapel gardens", "crusader's chapel" },
      note = "Needs the Scarlet Key. Turn in 'In the Name of the Light' at Southshore.",
      questList = { "In the Name of the Light (Raleigh the Devout, Southshore)" } },
    { key = "rfd", name = "Razorfen Downs", start = 39, to = 40, off = 1, elites = 120, quests = 4, min = 50, tier = "Master",
      match = { "razorfen downs" },
      note = "Whole party must finish Scourge of the Downs before taking Extinguishing the Idol.",
      questList = { "Bring the Light (Archbishop Benedictus, SW Cathedral)", "A Host of Evil (Myriam Moonsinger, outside RFD)",
                    "Scourge of the Downs (Belnistrasz, inside)", "Extinguishing the Idol (Belnistrasz escort, inside)" } },
    { key = "ulda", name = "Uldaman", start = 40, to = 42, off = 1, elites = 150, quests = 9, min = 70, tier = "Master",
      match = { "uldaman" },
      note = "Lots of quests - do the Loch Modan/Badlands prereqs first.",
      questList = { "The Lost Dwarves (Prospector Stormpike, IF Hall of Explorers)", "The Hidden Chamber (Baelog's Journal, inside)",
                    "Agmond's Fate (Prospector Ironband, Loch Modan)", "Uldaman Reagent Run (Ghak Healtouch, Thelsamar)",
                    "Power Stones (Rigglefuzz, Badlands)", "Solution to Doom (Theldurin the Lost, Badlands)",
                    "Reclaimed Treasures (Krom Stoutarm, IF Hall of Explorers)", "The Shattered Necklace (drop outside Uldaman)",
                    "The Platinum Discs (inside, after Archaedas)" } },
    { key = "krol", name = "Krol'dok Stronghold", start = 42, to = 44, off = 1, elites = 160, quests = 5, min = 55, tier = "Experienced",
      match = { "krol'dok", "kroldok" },
      note = "Reportedly opens ~Dec 9. If not live: Uldaman until 44.",
      questList = { "Quests TBD" } },
    { key = "zf", name = "Zul'Farrak", start = 44, to = 46, off = 1, elites = 180, quests = 7, min = 60, tier = "Master",
      match = { "zul'farrak", "zulfarrak" },
      note = "Gahz'rilla needs the Mallet of Zul'Farrak (Hinterlands). Basilisks = skinning.",
      questList = { "Divino-matic Rod (Chief Engineer Bilgewhizzle, Gadgetzan)", "Scarab Shells (Tran'rek, Gadgetzan)",
                    "Troll Temper (Trenton Lighthammer, Gadgetzan)", "Tiara of the Deep (Tabetha, Dustwallow Marsh)",
                    "Gahz'rilla (Wizzle Brassbolts, Shimmering Flats)", "The Prophecy of Mosh'aru (Yeh'kinya, Steamwheedle Port)",
                    "Nekrum's Medallion (Thadius Grimshade, Nethergarde Keep)" } },
    { key = "mara", name = "Maraudon", start = 46, to = 49, off = 1, elites = 200, quests = 8, min = 90, tier = "Master",
      match = { "maraudon" },
      note = "Skinning. Nijel's Point and Theramore quests.",
      questList = { "Shadowshard Fragments (Archmage Tervosh, Theramore)", "Vyletongue Corruption (Talendria, Nijel's Point)",
                    "Corruption of Earth and Seed (Keeper Marandis, Nijel's Point)", "Twisted Evils (Willow, Desolace)",
                    "Legends of Maraudon (Cavindra, outside)", "The Scepter of Celebras (Celebras the Redeemed, inside)",
                    "Seed of Life (Zaetar's Spirit, inside)", "The Pariah's Instructions (Centaur Pariah, Desolace)" } },
    { key = "alcaz", name = "Alcaz Prison", start = 49, to = 51, off = 1, elites = 180, quests = 5, min = 60, tier = "Master",
      match = { "alcaz" },
      note = "Reportedly opens ~Dec 9. If not live: Maraudon/Sunken Temple until 51.",
      questList = { "Quests TBD" } },
    { key = "st", name = "Sunken Temple", start = 51, to = 53, off = 1, elites = 170, quests = 6, min = 75, tier = "Master",
      match = { "sunken temple", "atal'hakkar" },
      note = "Avatar of Hakkar needs Yeh'kinya's Scroll.",
      questList = { "Into The Temple of Atal'Hakkar (Brohann Caskbelly, SW Dwarven District)", "Into the Depths (Marvon Rivetseeker, Tanaris)",
                    "Secret of the Circle (Marvon Rivetseeker, Tanaris)", "Jammal'an the Prophet (Atal'ai Exile, Hinterlands)",
                    "The God Hakkar (Yeh'kinya, Steamwheedle Port)", "The Essence of Eranikus (drop inside)" } },
    { key = "brd", name = "Blackrock Depths", start = 53, to = 56, off = 1, elites = 350, quests = 11, min = 120, tier = "Master",
      match = { "blackrock depths" },
      note = "Long - split into wings. Dark Iron Legacy gives the Shadowforge Key.",
      questList = { "Dark Iron Legacy (Franclorn Forgewright, Blackrock Mtn - visible while dead)", "Hurley Blackbreath (Ragnar Thunderbrew, Kharanos)",
                    "Overmaster Pyron (Jalinda Sprig, Morgan's Vigil)", "Incendius! (Jalinda Sprig, after Overmaster Pyron)",
                    "The Good Stuff (Oralius, Morgan's Vigil)", "Ribbly Screwspigot (Yuka Screwspigot, Flame Crest)",
                    "The Heart of the Mountain (Maxwort Uberglint, Flame Crest)", "The Love Potion (Mistress Nagmara, inside)",
                    "Kharan Mighthammer (King Magni, IF)", "The Fate of the Kingdom (King Magni, IF)",
                    "Attunement to the Core (Lothos Riftwaker, Blackrock Mtn)" } },
    { key = "blackmaw", name = "Blackmaw Hold", start = 56, to = 57, off = 1, elites = 200, quests = 5, min = 70, tier = "Master",
      match = { "blackmaw" },
      note = "Not in beta yet. If not live: BRD / DM East until 57.",
      questList = { "Quests TBD" } },
    { key = "lbrs", name = "Lower Blackrock Spire", start = 57, to = 58, off = 1, elites = 200, quests = 7, min = 75, tier = "Master",
      match = { "blackrock spire" },
      note = "Seal of Ascension (UBRS key) starts here.",
      questList = { "Put Her Down (Helendis Riverhorn, Morgan's Vigil)", "En-Ay-Es-Tee-Why (Kibler, Flame Crest)",
                    "Kibler's Exotic Pets (Kibler, Flame Crest)", "Mother's Milk (Ragged John, Flame Crest)",
                    "Urok Doomhowl (Warosh, inside)", "Bijou's Belongings (Bijou, inside)", "Seal of Ascension (drop inside)" } },
    { key = "dme", name = "Dire Maul East", start = 58, to = 58, off = 0, elites = 120, quests = 2, min = 45, tier = "Master",
      match = { "dire maul" }, subzones = { "warpwood quarter", "the hidden reach", "conservatory", "shrine of eldretharr" },
      note = "One run for the achievement while in Feralas.",
      questList = { "Lethtendris's Web (Latronicus Moonspear, Feathermoon)", "Pusillin and the Elder Azj'Tordin (Azj'Tordin, Feralas)" } },
    { key = "shaper", name = "Shaper's Terrace", start = 58, to = 60, off = 1, elites = 200, quests = 5, min = 70, tier = "Master",
      match = { "shaper" },
      note = "Not in beta yet. If not live: LBRS / DM East / Strat / Scholo to 60.",
      questList = { "Quests TBD" } },
    { key = "ubrs", name = "Upper Blackrock Spire", start = 60, to = 60, off = 0, elites = 150, quests = 0, min = 75, tier = "Master",
      match = { "blackrock spire" }, subzones = { "hordemar city", "dragonspire hall", "hall of blackhand", "rookery", "the beast's lair", "blackrock stadium" },
      note = "At 60. Needs Seal of Ascension.", questList = {} },
    { key = "dmw", name = "Dire Maul West", start = 60, to = 60, off = 0, elites = 100, quests = 0, min = 45, tier = "Master",
      match = { "dire maul" }, subzones = { "capital gardens", "court of the highborne", "prison of immol'thar", "athenaeum" },
      note = "At 60. Needs the Crescent Key (DM East).", questList = {} },
    { key = "dmn", name = "Dire Maul North", start = 60, to = 60, off = 0, elites = 80, quests = 0, min = 40, tier = "Master",
      match = { "dire maul" }, subzones = { "gordok commons", "halls of destruction", "broken commons" },
      note = "At 60 (tribute run).", questList = {} },
    { key = "stratlive", name = "Stratholme - Live", start = 60, to = 60, off = 0, elites = 200, quests = 0, min = 60, tier = "Master",
      match = { "stratholme" }, subzones = { "king's square", "market row", "crusaders' square", "the scarlet bastion", "the hall of lights", "the crimson throne" },
      note = "At 60.", questList = {} },
    { key = "stratud", name = "Stratholme - Undead", start = 60, to = 60, off = 0, elites = 200, quests = 0, min = 60, tier = "Master",
      match = { "stratholme" }, subzones = { "elders' square", "the gauntlet", "slaughter square", "the slaughter house" },
      note = "At 60.", questList = {} },
    { key = "scholo", name = "Scholomance", start = 60, to = 60, off = 0, elites = 220, quests = 0, min = 75, tier = "Master",
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
local PREP_ALLIANCE = {
    hot = {
        { q = "Nip 'Em in the Bud", unlocks = { "Old Ironforge Incursion" }, lvl = 12, min = 25, from = "Earthseer Farsen, Dun Morogh (64.8, 58.5)",
          what = "Kill 10 Dark Iron Spies (~76, 60). One drops the Dark Iron Map - use it and return to Farsen." },
    },
    -- Verified on Wowhead: quest IDs 65 > 132 > 135 > 141 > 142 > 155, then 166 (VanCleef) and Red Silk Bandanas.
    dm = {
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
    },
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
}

-- Horde route. Dungeon stats (elites, minutes, tier, instance matching) are shared with the
-- Alliance entries above; only the order, levels, quests and prerequisites differ.
-- Ragefire Chasm fills the "Ragefire Chasm or Hall of Thanes" Novice Spelunker slot.
-- The Stockade (Stormwind, optional) is left out.
local EXTRA = {
    rfc = { key = "rfc", name = "Ragefire Chasm", off = 1, elites = 70, min = 30, tier = "Novice", match = { "ragefire" } },
}

local HORDE = {
    { "rfc", 14, 16, quests = 5, note = "Hidden Enemies needs the first parts of Thrall's chain.",
      questList = { "Slaying the Beast (Neeru Fireblade, Orgrimmar Cleft of Shadow)", "Testing an Enemy's Strength (Rahauro, Thunder Bluff)",
                    "The Power to Destroy... (Varimathras, Undercity)", "Searching for the Lost Satchel (Maur Grimtotem's satchel, inside)",
                    "Hidden Enemies (Thrall, Orgrimmar)" } },
    { "rol", 16, 18, quests = 6, note = "Easy Horde access from Undercity. Several quests start/end in Undercity.",
      questList = { "Light's Justice (Morbin Lightbane, Undercity Royal Quarter)", "The New Plague (Theodore Griffs, Undercity Apothecarium)",
                    "The Wrath of Rath'mael (Deathguard Kristof, Tirisfal 65, 60)", "A Frightened Request (Tabetha Heartweaver, The Sepulcher)",
                    "Unending Torment (Abominable Head drop, inside)", "Crest of Lordaeron (found inside)" } },
    { "wc", 18, 20, quests = 7, note = "Deviate hides for skinning/LW.",
      questList = { "Serpentbloom (Apothecary Zamah, Thunder Bluff)", "Leaders of the Fang (Nara Wildmane, Thunder Bluff)",
                    "Deviate Hides (Nalpak, above WC entrance) [1486]", "Deviate Eradication (Ebru, above WC entrance) [1487]",
                    "Trouble at the Docks (Crane Operator Bigglefuzz, Ratchet) [959]", "Smart Drinks (Mebok Mizzyrix, Ratchet) [1491]",
                    "The Glowing Shard (drops from Mutanus) [6981]" } },
    { "sfk", 20, 22, quests = 3, note = "Quests from the Sepulcher (Silverpine) and Undercity.",
      questList = { "Deathstalkers in Shadowfang (High Executor Hadrec, The Sepulcher)", "Arugal Must Die (Dalar Dawnweaver, The Sepulcher)",
                    "The Book of Ur (Keeper Bel'dugur, Undercity Apothecarium)" } },
    { "bfd", 22, 24, quests = 5, note = "Quests from Zoram'gar Outpost (Ashenvale coast).",
      questList = { "The Essence of Aku'Mai (Je'neu Sancrea, Zoram'gar Outpost)", "Amongst the Ruins (Je'neu Sancrea, Zoram'gar Outpost)",
                    "Blackfathom Villainy (Argent Guard Thaelrid, inside)", "Baron Aquanis (Strange Water Globe drop)",
                    "Allegiance to the Old Gods (Damp Note drop outside - rare)" } },
    { "dm", 24, 24, quests = 0, note = "One run for Novice Spelunker - no Horde quests. Long trip to Westfall.", questList = {} },
    { "rfk", 24, 26, quests = 5, note = "Combine with a Barrens/Ratchet trip. Grab the Blueleaf Tubers items next to Mebok.",
      questList = { "A Vengeful Fate (Auld Stonespire, Thunder Bluff)", "Going, Going, Guano! (Master Apothecary Faranell, Undercity)",
                    "Blueleaf Tubers (Mebok Mizzyrix, Ratchet)", "Willix the Importer (escort, inside)",
                    "An Unholy Alliance (Small Scroll drop from Charlga Razorflank)" } },
    { "exc", 26, 28, quests = 3, note = "Thicket raptors = skinning.",
      questList = { "Changing Tastes (Borstan, Orgrimmar The Drag)", "Open the Maw (Deathstalker Agent, Wetlands 51, 59)",
                    "Elder Knowledge (Titan Relic drop from Relic Guardian)" } },
    { "gnomer", 28, 30, quests = 5, note = "Long. Someone needs the Workshop Key for the back door.",
      questList = { "Rig Wars (Nogg, Orgrimmar Valley of Honor)", "Chief Engineer Scooty (Sovik, Orgrimmar - after Rig Wars)",
                    "Gnomer-gooooone! (Scooty, Booty Bay)", "A Fine Mess (escort Kernobee, inside)", "Grime-Encrusted Ring (drop inside)" } },
    { "smgy", 30, 31, quests = 2, note = "Fast runs - watch the 5 instances/hour cap.",
      questList = { "Vorrel's Revenge (Vorrel Sengutz, inside)", "Hearts of Zeal (Master Apothecary Faranell, Undercity)" } },
    { "dal", 31, 33, quests = 5, note = "In beta. If not live: SM Graveyard/Library until 33.", questList = { "5 quests (names TBD)" } },
    { "smlib", 33, 35, quests = 2, note = "The Scarlet Key (for Armory/Cathedral) drops here.",
      questList = { "Compendium of the Fallen (Sage Truthseeker, Thunder Bluff - not Undead)", "Test of Lore (Parqual Fintallas, Undercity)" } },
    { "drowned", 35, 37, quests = 5, note = "Reportedly opens ~Dec 9. If not live: SM Library/Armory until 37.", questList = { "Quests TBD" } },
    { "smarm", 37, 38, quests = 0, note = "Needs the Scarlet Key (Library drop).", questList = {} },
    { "smcath", 38, 39, quests = 1, note = "Needs the Scarlet Key.",
      questList = { "Into The Scarlet Monastery (Varimathras, Undercity)" } },
    { "rfd", 39, 40, quests = 5, note = "Whole party must finish Scourge of the Downs before taking Extinguishing the Idol.",
      questList = { "Bring the End (Andrew Brownell, Undercity Magic Quarter)", "An Unholy Alliance (Varimathras, Undercity - after the RFK scroll)",
                    "A Host of Evil (Myriam Moonsinger, outside RFD)", "Scourge of the Downs (Belnistrasz, inside)",
                    "Extinguishing the Idol (Belnistrasz escort, inside)" } },
    { "ulda", 40, 42, quests = 6, note = "Kargath (Badlands) is the Horde hub for Uldaman.",
      questList = { "Reclaimed Treasures (Patrick Garrett, Undercity)", "Uldaman Reagent Run (Jarkal Mossmeld, Kargath)",
                    "Power Stones (Rigglefuzz, Badlands)", "Solution to Doom (Theldurin the Lost, Badlands)",
                    "The Shattered Necklace (drop outside Uldaman)", "The Platinum Discs (inside, after Archaedas)" } },
    { "krol", 42, 44, quests = 5, note = "Reportedly opens ~Dec 9. If not live: Uldaman until 44.", questList = { "Quests TBD" } },
    { "zf", 44, 46, quests = 7, note = "Gahz'rilla needs the Mallet of Zul'Farrak (Hinterlands). Basilisks = skinning.",
      questList = { "The Spider God (Master Gadrin, Sen'jin Village)", "Divino-matic Rod (Chief Engineer Bilgewhizzle, Gadgetzan)",
                    "Scarab Shells (Tran'rek, Gadgetzan)", "Troll Temper (Trenton Lighthammer, Gadgetzan)",
                    "Tiara of the Deep (Tabetha, Dustwallow Marsh)", "Gahz'rilla (Wizzle Brassbolts, Shimmering Flats)",
                    "The Prophecy of Mosh'aru (Yeh'kinya, Steamwheedle Port)" } },
    { "mara", 46, 49, quests = 8, note = "Skinning. Shadowprey Village quests.",
      questList = { "Shadowshard Fragments (Uthel'nay, Orgrimmar Valley of Spirits)", "Vyletongue Corruption (Vark Battlescar, Shadowprey Village)",
                    "Corruption of Earth and Seed (Selendra, south of Shadowprey)", "Twisted Evils (Willow, Desolace)",
                    "Legends of Maraudon (Cavindra, outside)", "The Scepter of Celebras (Celebras the Redeemed, inside)",
                    "Seed of Life (Zaetar's Spirit, inside)", "The Pariah's Instructions (Centaur Pariah, Desolace)" } },
    { "alcaz", 49, 51, quests = 5, note = "Reportedly opens ~Dec 9. If not live: Maraudon/Sunken Temple until 51.", questList = { "Quests TBD" } },
    { "st", 51, 53, quests = 7, note = "Avatar of Hakkar needs Yeh'kinya's Scroll.",
      questList = { "The Temple of Atal'Hakkar (Fel'zerul, Stonard)", "Zapper Fuel (Liv Rizzlefix, Ratchet)",
                    "Into the Depths (Marvon Rivetseeker, Tanaris)", "Secret of the Circle (Marvon Rivetseeker, Tanaris)",
                    "Jammal'an the Prophet (Atal'ai Exile, Hinterlands)", "The God Hakkar (Yeh'kinya, Steamwheedle Port)",
                    "The Essence of Eranikus (drop inside)" } },
    { "brd", 53, 56, quests = 12, note = "Kargath (Badlands) quest hub. Dark Iron Legacy gives the Shadowforge Key.",
      questList = { "KILL ON SIGHT: Dark Iron Dwarves (WANTED poster, Kargath)", "KILL ON SIGHT: High Ranking Dark Iron Officials (WANTED poster, Kargath)",
                    "Lost Thunderbrew Recipe (Shadowmage Vivian Lagrave, Kargath)", "Disharmony of Flame (Thunderheart, Kargath)",
                    "Disharmony of Fire (Thunderheart, after Disharmony of Flame)", "Commander Gor'shak (Galamav the Marksman, Kargath)",
                    "The Last Element (Shadowmage Vivian Lagrave, Kargath)", "Ribbly Screwspigot (Yuka Screwspigot, Flame Crest)",
                    "The Heart of the Mountain (Maxwort Uberglint, Flame Crest)", "The Love Potion (Mistress Nagmara, inside)",
                    "Dark Iron Legacy (Franclorn Forgewright, Blackrock Mtn - visible while dead)", "Attunement to the Core (Lothos Riftwaker, Blackrock Mtn)" } },
    { "blackmaw", 56, 57, quests = 5, note = "Not in beta yet. If not live: BRD / DM East until 57.", questList = { "Quests TBD" } },
    { "lbrs", 57, 58, quests = 9, note = "Seal of Ascension (UBRS key) starts here.",
      questList = { "The Pack Mistress (Galamav the Marksman, Kargath)", "Operative Bijou (Lexlort, Kargath)",
                    "Warlord's Command (Warlord Goretooth, Kargath)", "Bijou's Belongings (Bijou, inside)",
                    "En-Ay-Es-Tee-Why (Kibler, Flame Crest)", "Kibler's Exotic Pets (Kibler, Flame Crest)",
                    "Mother's Milk (Ragged John, Flame Crest)", "Urok Doomhowl (Warosh, inside)", "Seal of Ascension (drop inside)" } },
    { "dme", 58, 58, quests = 2, note = "One run for the achievement while in Feralas.",
      questList = { "Lethtendris's Web (Talo Thornhoof, Camp Mojache)", "Pusillin and the Elder Azj'Tordin (Azj'Tordin, Feralas)" } },
    { "shaper", 58, 60, quests = 5, note = "Not in beta yet. If not live: LBRS / DM East / Strat / Scholo to 60.", questList = { "Quests TBD" } },
    { "ubrs", 60, 60 }, { "dmw", 60, 60 }, { "dmn", 60, 60 }, { "stratlive", 60, 60 }, { "stratud", 60, 60 }, { "scholo", 60, 60 },
}

local PREP_HORDE = {
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
    },
    exc = {
        { q = "Dragonmaw Rumors", unlocks = { "Open the Maw" }, lvl = 26, min = 25, from = "Zaruk, Hammerfall (Arathi 74.4, 35.6)",
          what = "Leads to the Deathstalker Agent in the Wetlands (51.4, 59.2). Unlocks Open the Maw." },
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
    return { key = src.key, name = src.name, off = src.off, elites = src.elites, min = src.min, tier = src.tier,
             match = src.match, subzones = src.subzones }
end

function ns.BuildRoute(faction)
    local route = {}
    if faction == "Horde" then
        for _, h in ipairs(HORDE) do
            local base = BASE[h[1]]
            local d = CopyStats(base)
            d.start, d.to = h[2], h[3]
            d.quests = h.quests or base.quests or 0
            d.note = h.note or base.note
            d.questList = h.questList or base.questList or {}
            d.prep = PREP_HORDE[d.key] or {}
            table.insert(route, d)
        end
    else
        for _, a in ipairs(ALLIANCE) do
            local d = CopyStats(a)
            d.start, d.to, d.quests, d.note, d.questList = a.start, a.to, a.quests, a.note, a.questList
            d.prep = PREP_ALLIANCE[d.key] or {}
            table.insert(route, d)
        end
    end
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
