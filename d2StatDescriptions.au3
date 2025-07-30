;Array field descriptions:
;1 - ID ;2 - Name1 ;3 - Is Name1 displayed ;4 - Name1 ;5 - Is Name2 displayed

global $g_d2StatNames[][5] = [ _
		[0, "Strength base", True, "+# to Strength", True], _
		[1, "Energy base", True, "+# to Energy", True], _
		[2, "Dexterity base", True, "+# to Dexterity", True], _
		[3, "Vitality base", True, "+# to Vitality", True], _
		[4, "", False, "Free stat points", True], _
		[5, "", False, "Free skill points", True], _
		[6, "", False, "Current Life", True], _
		[7, "", False, "Base Life", True], _
		[8, "", False, "Current Mana", True], _
		[9, "", False, "Base Mana", True], _
		[10, "", False, "Current Stamina", True], _
		[11, "", False, "Maximum Stamina", True], _
		[12, "", False, "Character level", True], _
		[13, "", False, "Current Experience", True], _
		[14, "", False, "Gold amount on character", True], _
		[15, "", False, "Gold amount in stash", True], _
		[16, "", True, "+#% Enhanced Defense", True], _
		[17, "", True, "+#% Enhanced Damage", True], _
		[18, "", True, "", True], _
		[19, "", True, "+# to Attack rating", True], _
		[20, "", True, "+#% Base block chance", True], _
		[21, "", True, "+# to Minimum 1-handed damage", True], _
		[22, "", True, "+# to Maximum 1-handed damage", True], _
		[23, "", True, "+# to Minimum 2-handed damage", True], _
		[24, "", True, "+# to Maximum 2-handed damage", True], _
		[25, "", True, "+#% to Enhanced Weapon Damage", True], _
		[26, "", True, "", True], _
		[27, "", True, "Regenerate Mana #%", True], _
		[28, "", True, "Heal Stamina #%", True], _
		[29, "", True, "", True], _
		[30, "", True, "", True], _
		[31, "", True, "+# Defense", True], _
		[32, "", True, "+# Defense vs. Missile", True], _
		[33, "", True, "+# Defense vs. Melee", True], _
		[34, "", True, "Physical Damage taken reduced by #", True], _
		[35, "", True, "Elemental/Magic Damage taken reduced by #", True], _
		[36, "", True, "Physical Resist +#%", True], _
		[37, "", True, "Magic Resist +#%", True], _
		[38, "", True, "+#% to Maximum Magic Resist", True], _
		[39, "", True, "Fire Resist +#%", True], _
		[40, "", True, "+#% to Maximum Fire Resist", True], _
		[41, "", True, "Lightning Resist +#%", True], _
		[42, "", True, "+#% to Maximum Lightning Resist", True], _
		[43, "", True, "Cold Resist +#%", True], _
		[44, "", True, "+#% to Maximum Cold Resist", True], _
		[45, "", True, "Poison Resist +#%", True], _
		[46, "", True, "+#% to Maximum Poison Resist", True], _
		[47, "", True, "", True], _
		[48, "", True, "+# to Minimum Fire Damage", True], _
		[49, "", True, "+# to Maximum Fire Damage", True], _
		[50, "", True, "+# to Minimum Lightning Damage", True], _
		[51, "", True, "+# to Maximum Lightning Damage", True], _
		[52, "", True, "+# to Minimum Magic Damage", True], _
		[53, "", True, "+# to Maximum Magic Damage", True], _
		[54, "", True, "+# to Minimum Cold Damage", True], _
		[55, "", True, "+# to Maximum Cold Damage", True], _
		[56, "", True, "", True], _
		[57, "", True, "+# to Minimum Poison Damage / second", True], _
		[58, "", True, "+# to Maximum Poison Damage / second", True], _
		[59, "", True, "", True], _
		[60, "", True, "#% Life Stolen Per Hit", True], _
		[61, "", True, "", True], _
		[62, "", True, "#% Mana Stolen Per Hit", True], _
		[63, "", True, "", True], _
		[64, "", True, "#% Stamina Stolen Per Hit", True], _
		[65, "", True, "", True], _
		[66, "", True, "Stun Attack", True], _
		[67, "", True, "Skill Faster Run Walk +#%", True], _
		[68, "", True, "Skill Attack Speed +#%", True], _
		[69, "", True, "", True], _
		[70, "", True, "Quiver/Throwing weapon quantity amount", True], _
		[71, "", True, "Equipped items value", True], _
		[72, "", True, "Equipped items total Durability", True], _
		[73, "", True, "+# Maximum Durability", True], _
		[74, "", True, "Life regenerated per second", True], _
		[75, "", True, "Increase Maximum Durability #%", True], _
		[76, "", True, "Increase Maximum Life #%", True], _
		[77, "", True, "Increase Maximum Mana #%", True], _
		[78, "", True, "Attacker Takes Damage of #", True], _
		[79, "", True, "#% Gold Find", True], _
		[80, "", True, "#% Magic Find", True], _
		[81, "", True, "Knockback", True], _
		[82, "", True, "Unknown (Invisible)", False], _
		[83, "", True, "+# to [CLASS] skill levels", True], _
		[84, "", True, "+# to [ALL_CLASSES] skill levels", True], _
		[85, "", True, "#% To Experience Gained", True], _
		[86, "", True, "+# Life After Each Kill", True], _
		[87, "", True, "+#% to All Vendor prices", True], _
		[88, "", False, "Achievement data", False], _
		[89, "", True, "+# to Light Radius", True], _
		[90, "", True, "", True], _
		[91, "", True, "Requirements #%", True], _
		[92, "", True, "+# Required level", True], _
		[93, "", True, "#% Attack Speed", True], _
		[94, "", True, "", True], _
		[95, "", True, "", True], _
		[96, "", True, "#% Movement Speed", True], _
		[97, "", True, "+# to [OSKILL]", True], _
		[98, "", True, "", True], _
		[99, "", True, "#% Hit Recovery", True], _
		[100, "", True, "", True], _
		[101, "", True, "", True], _
		[102, "", True, "#% Block Speed", True], _
		[103, "", True, "", True], _
		[104, "", True, "", True], _
		[105, "", True, "#% Cast Speed", True], _
		[106, "", True, "", True], _
		[107, "", True, "+# to [CLASS_SKILL]", True], _
		[108, "", True, "Slain Monsters Rest In Peace (0/1)", True], _
		[109, "", True, "Curse Length Reduction: #%", True], _
		[110, "", True, "Poison Length Reduction: #%", True], _
		[111, "", True, "Damage +#", True], _
		[112, "", True, "Hit Causes Monsters to Flee #%", True], _
		[113, "", True, "Hit Blinds Target +#", True], _
		[114, "", True, "#% Damage Taken Goes to Mana", True], _
		[115, "", True, "Ignore Target Defense", True], _
		[116, "", True, "#% Target Defense", True], _
		[117, "", True, "Prevent Monster Heal", True], _
		[118, "", True, "Half Freeze Duration (0/1)", True], _
		[119, "", True, "#% Bonus to Attack Rating", True], _
		[120, "", True, "# to Monster Defense Per Hit", True], _
		[121, "", True, "+#% Damage to Demons", True], _
		[122, "", True, "+#% Damage to Undead", True], _
		[123, "", True, "+# to Attack Rating against Demons", True], _
		[124, "", True, "+# to Attack Rating against Undead", True], _
		[125, "", True, "Throwable", True], _
		[126, "", True, "", True], _
		[127, "", True, "+# to All Skills", True], _
		[128, "", True, "Attacker Takes Lightning Damage of #", True], _
		[129, "", True, "", True], _
		[130, "", True, "", True], _
		[131, "", True, "+#% Damage reflected", True], _
		[132, "", True, "", True], _
		[133, "", True, "", True], _
		[134, "", True, "Freezes Target +#", True], _
		[135, "", True, "#% Chance of Open Wounds", True], _
		[136, "", True, "#% Chance of Crushing Blow", True], _
		[137, "", True, "+# Kick Damage", True], _
		[138, "", True, "+# to Mana After Each Kill", True], _
		[139, "", True, "+# Life after each Demon Kill", True], _
		[140, "", True, "Extra Blood (Invisible)", True], _
		[141, "", True, "#% Deadly Strike", True], _
		[142, "", True, "Fire Absorb #%", True], _
		[143, "", True, "+# Fire Absorb", True], _
		[144, "", True, "Lightning Absorb #%", True], _
		[145, "", True, "+# Lightning Absorb", True], _
		[146, "", True, "Magic Absorb #%", True], _
		[147, "", True, "+# Magic Absorb", True], _
		[148, "", True, "Cold Absorb #%", True], _
		[149, "", True, "+# Cold Absorb", True], _
		[150, "", True, "Slows Target by #%", True], _
		[151, "", True, "Random movement speed bonus (0/1)", True], _
		[152, "", True, "Indestructible (0/1)", True], _
		[153, "", True, "Cannot Be Frozen", True], _
		[154, "", True, "#% Slower Stamina Drain", True], _
		[155, "", True, "#% Reanimate as [MONSTER_NAME]", True], _
		[156, "", True, "Piercing Attack", True], _
		[157, "", True, "Fires Magic Arrows", True], _
		[158, "", True, "Fires Explosive Arrows or Bolts", True], _
		[159, "", True, "+# to Minimum Throw Damage", True], _
		[160, "", True, "+# to Maximum Throw Damage", True], _
		[161, "", True, "", True], _
		[162, "", True, "", True], _
		[163, "", True, "", True], _
		[164, "", True, "+#% Uniterruptable Attack", True], _
		[165, "", True, "", True], _
		[166, "", True, "", True], _
		[167, "", True, "", True], _
		[168, "", True, "", True], _
		[169, "", True, "", True], _
		[170, "", True, "", True], _
		[171, "", True, "+#% Total Character Defense", True], _
		[172, "", True, "", True], _
		[173, "", True, "", True], _
		[174, "", True, "", True], _
		[175, "", True, "", True], _
		[176, "", True, "", True], _
		[177, "", True, "", True], _
		[178, "", True, "", True], _
		[179, "", True, "", True], _
		[180, "", True, "+#% Damage vs. [MONSTER]", True], _
		[181, "", True, "", True], _
		[182, "", True, "#% Defense bonus multiplier (Mostly 'Total character defense = 0' and Runemaster)", True], _
		[183, "", True, "Craft points", False], _
		[184, "", True, "#% Damage reduction from all sources", True], _
		[185, "", False, "Signets of Learning used", True], _
		[186, "", False, "Signets of Skill used", True], _
		[187, "", True, "Barbarian Stance (0-None, 1-Lion, 2-Bear, 3-Snake, 4-Eagle, 5-Wolf)", True], _
		[188, "", True, "", True], _
		[189, "", True, "", True], _
		[190, "", True, "", True], _
		[191, "", True, "", True], _
		[192, "", True, "", True], _
		[193, "", True, "", True], _
		[194, "", True, "Equipped items socket amount", True], _
		[195, "", True, "#% Chance to cast [SKILL] on melee attack", True], _
		[196, "", True, "#% Chance to cast [SKILL] on kill", True], _
		[197, "", True, "#% Chance to cast [SKILL] when you die", True], _
		[198, "", True, "#% Chance to cast [SKILL] on striking", True], _
		[199, "", True, "#% Chance to cast [SKILL] when you level-up", True], _
		[200, "", True, "Mega Impact amount", True], _
		[201, "", True, "#% Chance to cast [SKILL] when struck", True], _
		[202, "", True, "", True], _
		[203, "", True, "", True], _
		[204, "", True, "", True], _
		[205, "", True, "", True], _
		[206, "", True, "", True], _
		[207, "", True, "", True], _
		[208, "", True, "+# Life on striking", True], _
		[209, "", True, "+# Mana on striking", True], _
		[210, "", True, "+# Life on melee attack", True], _
		[211, "", True, "Disable non-melee skills flag (0/1)", True], _
		[212, "", True, "", True], _
		[213, "", True, "#% Max block chance modifier", True], _
		[214, "", True, "+# Defense (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[215, "", True, "+#% Enhanced Defense (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[216, "", True, "+# to Life (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[217, "", True, "+# to Mana (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[218, "", True, "+# to Maximum damage (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[219, "", True, "Shrine Blessed amount", False], _
		[220, "", True, "", True], _
		[221, "", True, "", True], _
		[222, "", True, "", True], _
		[223, "", True, "", True], _
		[224, "", True, "", True], _
		[225, "", True, "", True], _
		[226, "", True, "", True], _
		[227, "", True, "", True], _
		[228, "", True, "", True], _
		[229, "", True, "", True], _
		[230, "", True, "", True], _
		[231, "", True, "", True], _
		[232, "", True, "", True], _
		[233, "", True, "", True], _
		[234, "", True, "", True], _
		[235, "", True, "", True], _
		[236, "", True, "", True], _
		[237, "", True, "", True], _
		[238, "", True, "", True], _
		[239, "", True, "", True], _
		[240, "", True, "", True], _
		[241, "", True, "", True], _
		[242, "", True, "", True], _
		[243, "", True, "", True], _
		[244, "", True, "", True], _
		[245, "", True, "", True], _
		[246, "", True, "", True], _
		[247, "", True, "", True], _
		[248, "", True, "", True], _
		[249, "", True, "", True], _
		[250, "", True, "", True], _
		[251, "", True, "", True], _
		[252, "", True, "", True], _
		[253, "", True, "", True], _
		[254, "", True, "", True], _
		[255, "", True, "", True], _
		[256, "", True, "", True], _
		[257, "", True, "", True], _
		[258, "", True, "", True], _
		[259, "", True, "Charges: #", True], _
		[260, "", True, "", True], _
		[261, "", True, "", True], _
		[262, "", True, "", True], _
		[263, "", True, "", True], _
		[264, "", True, "", True], _
		[265, "", True, "", True], _
		[266, "", True, "Area Effect Attack amount", True], _
		[267, "", True, "", True], _
		[268, "", True, "", True], _
		[269, "", True, "", True], _
		[270, "", True, "Summon Edyrem skill (0/1)", True], _
		[271, "", True, "#% Chance to cast [SKILL] when you die", True], _
		[272, "", True, "", True], _
		[273, "", True, "#% Chance to Crush attacker", True], _
		[274, "", True, "", True], _
		[275, "", True, "Cannot be Disenchanted", True], _
		[276, "", True, "Stun Attack amount", True], _
		[277, "", True, "Area Effect Attack amount", True], _
		[278, "", True, "Strength Factor +#", True], _
		[279, "", True, "", True], _
		[280, "", True, "", True], _
		[281, "", True, "", True], _
		[282, "", True, "", True], _
		[283, "", True, "#% Chance to cast [SKILL] when attacked", True], _
		[284, "", True, "#% Chance to cast [SKILL] when struck by a missile", True], _
		[285, "", True, "", True], _
		[286, "", True, "", True], _
		[287, "", True, "", True], _
		[288, "", True, "Orb effects applied to this item are quadrupled", True], _
		[289, "", True, "Orb effects applied to this item are doubled (amount * 2)", True], _
		[290, "", True, "Mystic orb used amount", True], _
		[291, "", True, "", True], _
		[292, "", True, "#% Chance to cast [SKILL] on death blow", True], _
		[293, "", True, "", True], _
		[294, "", True, "", True], _
		[295, "", True, "+# Mana on melee attack", True], _
		[296, "", True, "", True], _
		[297, "", True, "Mana drain -#% (from Werewolf morph)", True], _
		[298, "", True, "", True], _
		[299, "", True, "", True], _
		[300, "", True, "", True], _
		[301, "", True, "", True], _
		[302, "", True, "", True], _
		[303, "", True, "", True], _
		[304, "", True, "", True], _
		[305, "", True, "", True], _
		[306, "", True, "", True], _
		[307, "", True, "", True], _
		[308, "", True, "", True], _
		[309, "", True, "Cooldown Reduction ???", True], _
		[310, "", True, "", True], _
		[311, "", True, "", True], _
		[312, "", True, "", True], _
		[313, "", True, "", True], _
		[314, "", True, "", True], _
		[315, "", True, "", True], _
		[316, "", True, "", True], _
		[317, "", True, "", True], _
		[318, "", True, "", True], _
		[319, "", True, "", True], _
		[320, "", True, "", True], _
		[321, "", True, "", True], _
		[322, "", True, "", True], _
		[323, "", True, "", True], _
		[324, "", True, "", True], _
		[325, "", True, "", True], _
		[326, "", True, "", True], _
		[327, "", True, "", True], _
		[328, "", False, "", False], _
		[329, "", True, "#% To Fire Spell Damage", True], _
		[330, "", True, "#% To Lightning Spell Damage", True], _
		[331, "", True, "#% To Cold Spell Damage", True], _
		[332, "", True, "#% To Poison Spell Damage", True], _
		[333, "", True, "-#% To Enemy Fire Resistance", True], _
		[334, "", True, "-#% To Enemy Lightning Resistance", True], _
		[335, "", True, "-#% To Enemy Cold Resistance", True], _
		[336, "", True, "-#% To Enemy Poison Resistance", True], _
		[337, "", True, "#% Critical Strike (for Barbarian)", True], _
		[338, "", True, "Dodge +#% (Chance to avoid melee attack while standing)", True], _
		[339, "", True, "Avoid +#% (Chance to avoid projectile attack while standing)", True], _
		[340, "", True, "Evade +#% (Chance to avoid any attack while moving)", True], _
		[341, "", True, "", True], _
		[342, "", True, "", True], _
		[343, "", True, "", True], _
		[344, "", True, "+#% Critical Strike", True], _
		[345, "", True, "", True], _
		[346, "", True, "", True], _
		[347, "", True, "", True], _
		[348, "", True, "", True], _
		[349, "", True, "", True], _
		[350, "", False, "", False], _
		[351, "", False, "", False], _
		[352, "", True, "", True], _
		[353, "", True, "", True], _
		[354, "", True, "", True], _
		[355, "", True, "", True], _
		[356, "", True, "Charms (amount * 2) (for explanation see 'Basic' tab)", True], _
		[357, "", True, "+#% to Physical/Magic spell damage", True], _
		[358, "", True, "-#% To Enemy Physical/Magic Resistance", True], _
		[359, "", True, "Strength +#%", True], _
		[360, "", True, "Dexterity +#%", True], _
		[361, "", True, "Energy +#%", True], _
		[362, "", True, "Vitality +#%", True], _
		[363, "", True, "Slows Attacker +#%", True], _
		[364, "", True, "Attacker flees after striking +#%", True], _
		[365, "", True, "Freezes Attacker +#", True], _
		[366, "", True, "Blinds Attacker +#", True], _
		[367, "", True, "Attacker Takes Cold Damage of #", True], _
		[368, "", True, "Attacker Takes Fire Damage of #", True], _
		[369, "", True, "", True], _
		[370, "", True, "", True], _
		[371, "", True, "Amazing Grace amount", True], _
		[372, "", True, "Equipped runeword amount", True], _
		[373, "", True, "", True], _
		[374, "", True, "", True], _
		[375, "", True, "", True], _
		[376, "", True, "Slows Melee Target +#%", True], _
		[377, "", True, "", True], _
		[378, "", True, "", True], _
		[379, "", True, "", True], _
		[380, "", True, "+#% Bonus Damage to Bloodlust", True], _
		[381, "", True, "+#% Bonus Elemental damage to Bloodlust", True], _
		[382, "", True, "", True], _
		[383, "", True, "Base weapon Innate [ELEMENT_TYPE] damage #%", False], _
		[384, "", True, "", True], _
		[385, "", True, "", True], _
		[386, "", True, "", True], _
		[387, "", True, "+#% Bonus Damage to Mark of the Wild", True], _
		[388, "", True, "+#% Bonus Elemental Damage to Mark of the Wild", True], _
		[389, "", True, "+#% Duration Bonus to Mark of the Wild", True], _
		[390, "", True, "Already enchanted amount", False], _
		[391, "", True, "Mirrored amount", True], _
		[392, "", True, "", True], _
		[393, "", True, "", True], _
		[394, "", True, "", True], _
		[395, "", True, "", True], _
		[396, "", True, "Continuity unlock (0/1)", True], _
		[397, "", True, "Specialization unlock (0/1)", True], _
		[398, "", True, "Valthek set aura flag (0/1)", True], _
		[399, "", True, "", True], _
		[400, "", True, "", True], _
		[401, "", True, "", True], _
		[402, "", True, "", True], _
		[403, "", True, "", True], _
		[404, "", True, "", True], _
		[405, "", True, "", True], _
		[406, "", True, "", True], _
		[407, "", True, "", True], _
		[408, "", True, "", True], _
		[409, "", True, "", True], _
		[410, "", True, "# Prefixes", True], _
		[411, "", True, "# Suffixes", True], _
		[412, "", True, "", True], _
		[413, "", True, "", True], _
		[414, "", True, "+#% Bonus to summoned Edyrem life", True], _
		[415, "", True, "#% Innate Damage", True], _
		[416, "", True, "", True], _
		[417, "", True, "", True], _
		[418, "", True, "", True], _
		[419, "", True, "", True], _
		[420, "", True, "After blocking/taking weapon damage effect active", True], _
		[421, "", True, "", True], _
		[422, "", True, "", True], _
		[423, "", True, "Bone Chimes - [DtU + DtD]% added as [STAT_NAME] +#% Bonus", True], _
		[424, "", True, "", True], _
		[425, "", True, "", True], _
		[426, "", True, "", True], _
		[427, "", True, "Activation Frequency", True], _
		[428, "", True, "+# to Maximum Exodia minions", True], _
		[429, "", True, "+# to Maximum Paladin minions", True], _
		[430, "", True, "", True], _
		[431, "", True, "+#% Bonus to Poison skill duration", True], _
		[432, "", True, "", True], _
		[433, "", True, "", True], _
		[434, "", True, "", True], _
		[435, "", True, "", True], _
		[436, "", True, "", True], _
		[437, "", True, "", True], _
		[438, "", True, "", True], _
		[439, "", True, "+# Life when struck by an enemy", True], _
		[440, "", True, "+# Mana when struck by an enemy", True], _
		[441, "", True, "+# to Maximum Necromancer minions", True], _
		[442, "", True, "", True], _
		[443, "", True, "Already upgraded amount", False], _
		[444, "", True, "Summoned minion life +#%", True], _
		[445, "", True, "+# to Maximum Barbarian minions", True], _
		[446, "", True, "+#% Damage from Protector Spirit Bloodlust", True], _
		[447, "", True, "Restored amount", False], _
		[448, "", True, "#% increased Healing from Potions", True], _
		[449, "", True, "", True], _
		[450, "", True, "Trophy amount", True], _
		[451, "", True, "", True], _
		[452, "", True, "Cube upgrade 1 ???", True], _
		[453, "", True, "Cube upgrade 2 ???", True], _
		[454, "", True, "Cube upgrade 3 ???", True], _
		[455, "", True, "Sunstone of the Twin Seas resist scroll amount (0-3), Dulra Aegis upgrade amount (0-3)", True], _
		[456, "", True, "", True], _
		[457, "", True, "", True], _
		[458, "", True, "", True], _
		[459, "", True, "", True], _
		[460, "", True, "", True], _
		[461, "", True, "", True], _
		[462, "", True, "+#% Bonus damage to Vessel of Judgement", True], _
		[463, "", True, "Class restriction ???", True], _
		[464, "", True, "", True], _
		[465, "", True, "", True], _
		[466, "", True, "Unused Essence slots amount (Umbaru Treasure)", True], _
		[467, "", True, "", True], _
		[468, "", True, "+#% Bonus damage to Vessel of Retribution", True], _
		[469, "", True, "+# to Vessels Extra Targets", True], _
		[470, "", True, "Summoned minion damage +#%", True], _
		[471, "", True, "", True], _
		[472, "", True, "", True], _
		[473, "", True, "Ennead skill unlock (0/1)", True], _
		[474, "", True, "Black Road unlock (0/1)", True], _
		[475, "", True, "", True], _
		[476, "", True, "", True], _
		[477, "", True, "", True], _
		[478, "", True, "", True], _
		[479, "", True, "Maximum Skill level +#", True], _
		[480, "", True, "+# to Vitality per Socketed Gem", True], _
		[481, "", True, "+# to Runemaster Defense Bonus", True], _
		[482, "", True, "Total Vitality bonus from Paragon", True], _
		[483, "", True, "Socketed runes (amount * 32)", True], _
		[484, "", True, "Innate Elemental damage +#%", True], _
		[485, "", True, "+# Spell Focus", True], _
		[486, "", True, "", True], _
		[487, "", True, "Summoned minion resistances +#%", True], _
		[488, "", True, "+#% Spell Focus (from items/runes)", True], _
		[489, "", True, "Target takes additional damage +#", True], _
		[490, "", True, "", True], _
		[491, "", True, "", True], _
		[492, "", True, "", True], _
		[493, "", True, "Slows Ranged Attacker +#%", True], _
		[494, "", True, "", True], _
		[495, "", True, "", True], _
		[496, "", True, "", True], _
		[497, "", True, "Corrupted items amount", True], _
		[498, "", True, "", True], _
		[499, "", True, "", True], _
		[500, "", True, "Summoned minion attack rating +#%", True], _
		[501, "", True, "", True], _
		[502, "", True, "", True], _
		[503, "", True, "", True], _
		[504, "", True, "", True], _
		[505, "", True, "+# Life Regenerated per Second (Based on Character Level) [(value / 32) * [LEVEL]]", True], _
		[506, "", True, "", True], _
		[507, "", True, "", True], _
		[508, "", True, "Runes contributing to Gematria", True], _
		[509, "", True, "", True], _
		[510, "", True, "#% Chance to cast [SKILL] on block", True], _
		[511, "", True, "", True], _
		[512, "", True, "", True], _
		[513, "", True, "", True], _
		[514, "", True, "", True], _
		[515, "", True, "", True], _
		[516, "", True, "", True], _
		[517, "", True, "", True], _
		[518, "", True, "", True], _
		[519, "", True, "", True], _
		[520, "", True, "", True], _
		[521, "", True, "", True], _
		[522, "", True, "", True], _
		[523, "", True, "", True], _
		[524, "", True, "", True], _
		[525, "", True, "", True], _
		[526, "", True, "", True], _
		[527, "", True, "", True], _
		[528, "", True, "", True], _
		[529, "", True, "", True], _
		[530, "", True, "", True], _
		[531, "", True, "", True], _
		[532, "", True, "", True], _
		[533, "", True, "", True], _
		[534, "", True, "", True], _
		[535, "", True, "", True], _
		[536, "", True, "", True], _
		[537, "", True, "", True], _
		[538, "", True, "", True], _
		[539, "", True, "", True], _
		[540, "", True, "", True], _
		[541, "", True, "", True], _
		[542, "", True, "", True], _
		[543, "", True, "", True], _
		[544, "", True, "", True], _
		[545, "", True, "", True], _
		[546, "", True, "", True], _
		[547, "", True, "", True], _
		[548, "", True, "", True], _
		[549, "", True, "", True], _
		[550, "", True, "", True], _
		[551, "", True, "", True], _
		[552, "", True, "", True], _
		[553, "", True, "", True], _
		[554, "", True, "", True], _
		[555, "", True, "", True], _
		[556, "", True, "", True], _
		[557, "", True, "", True], _
		[558, "", True, "", True], _
		[559, "", True, "", True], _
		[560, "", True, "", True], _
		[561, "", True, "", True], _
		[562, "", True, "", True], _
		[563, "", True, "", True], _
		[564, "", True, "", True], _
		[565, "", True, "", True], _
		[566, "", True, "", True], _
		[567, "", True, "", True], _
		[568, "", True, "", True], _
		[569, "", True, "", True], _
		[570, "", True, "", True], _
		[571, "", True, "", True], _
		[572, "", True, "", True], _
		[573, "", True, "", True], _
		[574, "", True, "", True], _
		[575, "", True, "", True], _
		[576, "", True, "", True], _
		[577, "", True, "", True], _
		[578, "", True, "", True], _
		[579, "", True, "", True], _
		[580, "", True, "", True], _
		[581, "", True, "", True], _
		[582, "", True, "", True], _
		[583, "", True, "", True], _
		[584, "", True, "", True], _
		[585, "", True, "", True], _
		[586, "", True, "", True], _
		[587, "", True, "", True], _
		[588, "", True, "", True], _
		[589, "", True, "", True], _
		[590, "", True, "", True], _
		[591, "", True, "", True], _
		[592, "", True, "", True], _
		[593, "", True, "", True], _
		[594, "", True, "", True], _
		[595, "", True, "", True], _
		[596, "", True, "", True], _
		[597, "", True, "", True], _
		[598, "", True, "", True], _
		[599, "", True, "", True], _
		[600, "", True, "", True], _
		[601, "", True, "", True], _
		[602, "", True, "", True], _
		[603, "", True, "", True], _
		[604, "", True, "", True], _
		[605, "", True, "", True], _
		[606, "", True, "", True], _
		[607, "", True, "", True], _
		[608, "", True, "", True], _
		[609, "", True, "", True], _
		[610, "", True, "", True], _
		[611, "", True, "", True], _
		[612, "", True, "", True], _
		[613, "", True, "", True], _
		[614, "", True, "", True], _
		[615, "", True, "", True], _
		[616, "", True, "", True], _
		[617, "", True, "", True], _
		[618, "", True, "", True], _
		[619, "", True, "", True], _
		[620, "", True, "", True], _
		[621, "", True, "", True], _
		[622, "", True, "", True], _
		[623, "", True, "", True], _
		[624, "", True, "", True], _
		[625, "", True, "", True], _
		[626, "", True, "", True], _
		[627, "", True, "", True], _
		[628, "", True, "", True], _
		[629, "", True, "", True], _
		[630, "", True, "", True], _
		[631, "", True, "", True], _
		[632, "", True, "", True], _
		[633, "", True, "", True], _
		[634, "", True, "", True], _
		[635, "", True, "", True], _
		[636, "", True, "", True], _
		[637, "", True, "", True], _
		[638, "", True, "", True], _
		[639, "", True, "", True], _
		[640, "", True, "", True], _
		[641, "", True, "", True], _
		[642, "", True, "", True], _
		[643, "", True, "", True], _
		[644, "", True, "", True], _
		[645, "", True, "", True], _
		[646, "", True, "", True], _
		[647, "", True, "", True], _
		[648, "", True, "", True], _
		[649, "", True, "", True], _
		[650, "", True, "", True], _
		[651, "", True, "", True], _
		[652, "", True, "", True], _
		[653, "", True, "", True], _
		[654, "", True, "", True], _
		[655, "", True, "", True], _
		[656, "", True, "", True], _
		[657, "", True, "", True], _
		[658, "", True, "", True], _
		[659, "", True, "", True], _
		[660, "", True, "", True], _
		[661, "", True, "", True], _
		[662, "", True, "", True], _
		[663, "", True, "", True], _
		[664, "", True, "", True], _
		[665, "", True, "", True], _
		[666, "", True, "", True], _
		[667, "", True, "", True], _
		[668, "", True, "", True], _
		[669, "", True, "", True], _
		[670, "", True, "", True], _
		[671, "", True, "", True], _
		[672, "", True, "", True], _
		[673, "", True, "", True], _
		[674, "", True, "", True], _
		[675, "", True, "", True], _
		[676, "", True, "", True], _
		[677, "", True, "", True], _
		[678, "", True, "", True], _
		[679, "", True, "", True], _
		[680, "", True, "", True], _
		[681, "", True, "", True], _
		[682, "", True, "", True], _
		[683, "", True, "", True], _
		[684, "", True, "", True], _
		[685, "", True, "", True], _
		[686, "", True, "", True], _
		[687, "", True, "", True], _
		[688, "", True, "", True], _
		[689, "", True, "", True], _
		[690, "", True, "", True], _
		[691, "", True, "", True], _
		[692, "", True, "", True], _
		[693, "", True, "", True], _
		[694, "", True, "", True], _
		[695, "", True, "", True], _
		[696, "", True, "", True], _
		[697, "", True, "", True], _
		[698, "", True, "", True], _
		[699, "", True, "", True], _
		[700, "", True, "", True], _
		[701, "", True, "", True], _
		[702, "", True, "", True], _
		[703, "", True, "", True], _
		[704, "", True, "", True], _
		[705, "", True, "", True], _
		[706, "", True, "", True], _
		[707, "", True, "", True], _
		[708, "", True, "", True], _
		[709, "", True, "", True], _
		[710, "", True, "", True], _
		[711, "", True, "", True], _
		[712, "", True, "", True], _
		[713, "", True, "", True], _
		[714, "", True, "", True], _
		[715, "", True, "", True], _
		[716, "", True, "", True], _
		[717, "", True, "", True], _
		[718, "", True, "", True], _
		[719, "", True, "", True], _
		[720, "", True, "", True], _
		[721, "", True, "", True], _
		[722, "", True, "", True], _
		[723, "", True, "", True], _
		[724, "", True, "", True], _
		[725, "", True, "", True], _
		[726, "", True, "", True], _
		[727, "", True, "", True], _
		[728, "", True, "", True], _
		[729, "", True, "", True], _
		[730, "", True, "", True], _
		[731, "", True, "", True], _
		[732, "", True, "", True], _
		[733, "", True, "", True], _
		[734, "", True, "", True], _
		[735, "", True, "", True], _
		[736, "", True, "", True], _
		[737, "", True, "", True], _
		[738, "", True, "", True], _
		[739, "", True, "", True], _
		[740, "", True, "", True], _
		[741, "", True, "", True], _
		[742, "", True, "", True], _
		[743, "", True, "", True], _
		[744, "", True, "", True], _
		[745, "", True, "", True], _
		[746, "", True, "", True], _
		[747, "", True, "", True], _
		[748, "", True, "", True], _
		[749, "", True, "", True], _
		[750, "", True, "", True], _
		[751, "", True, "", True], _
		[752, "", True, "", True], _
		[753, "", True, "", True], _
		[754, "", True, "", True], _
		[755, "", True, "", True], _
		[756, "", True, "", True], _
		[757, "", True, "", True], _
		[758, "", True, "", True], _
		[759, "", True, "", True], _
		[760, "", True, "", True], _
		[761, "", True, "", True], _
		[762, "", True, "", True], _
		[763, "", True, "", True], _
		[764, "", True, "", True], _
		[765, "", True, "", True], _
		[766, "", True, "", True], _
		[767, "", True, "", True], _
		[768, "", True, "", True], _
		[769, "", True, "", True], _
		[770, "", True, "", True], _
		[771, "", True, "", True], _
		[772, "", True, "", True], _
		[773, "", True, "", True], _
		[774, "", True, "", True], _
		[775, "", True, "", True], _
		[776, "", True, "", True], _
		[777, "", True, "", True], _
		[778, "", True, "", True], _
		[779, "", True, "", True], _
		[780, "", True, "", True], _
		[781, "", True, "", True], _
		[782, "", True, "", True], _
		[783, "", True, "", True], _
		[784, "", True, "", True], _
		[785, "", True, "", True], _
		[786, "", True, "", True], _
		[787, "", True, "", True], _
		[788, "", True, "", True], _
		[789, "", True, "", True], _
		[790, "", True, "", True], _
		[791, "", True, "", True], _
		[792, "", True, "", True], _
		[793, "", True, "", True], _
		[794, "", True, "", True], _
		[795, "", True, "", True], _
		[796, "", True, "", True], _
		[797, "", True, "", True], _
		[798, "", True, "", True], _
		[799, "", True, "", True], _
		[800, "", True, "", True], _
		[801, "", True, "", True], _
		[802, "", True, "", True], _
		[803, "", True, "", True], _
		[804, "", True, "", True], _
		[805, "", True, "", True], _
		[806, "", True, "", True], _
		[807, "", True, "", True], _
		[808, "", True, "", True], _
		[809, "", True, "", True], _
		[810, "", True, "", True], _
		[811, "", True, "", True], _
		[812, "", True, "", True], _
		[813, "", True, "", True], _
		[814, "", True, "", True], _
		[815, "", True, "", True], _
		[816, "", True, "", True], _
		[817, "", True, "", True], _
		[818, "", True, "", True], _
		[819, "", True, "", True], _
		[820, "", True, "", True], _
		[821, "", True, "", True], _
		[822, "", True, "", True], _
		[823, "", True, "", True], _
		[824, "", True, "", True], _
		[825, "", True, "", True], _
		[826, "", True, "", True], _
		[827, "", True, "", True], _
		[828, "", True, "", True], _
		[829, "", True, "", True], _
		[830, "", True, "", True], _
		[831, "", True, "", True], _
		[832, "", True, "", True], _
		[833, "", True, "", True], _
		[834, "", True, "", True], _
		[835, "", True, "", True], _
		[836, "", True, "", True], _
		[837, "", True, "", True], _
		[838, "", True, "", True], _
		[839, "", True, "", True], _
		[840, "", True, "", True], _
		[841, "", True, "", True], _
		[842, "", True, "", True], _
		[843, "", True, "", True], _
		[844, "", True, "", True], _
		[845, "", True, "", True], _
		[846, "", True, "", True], _
		[847, "", True, "", True], _
		[848, "", True, "", True], _
		[849, "", True, "", True], _
		[850, "", True, "", True], _
		[851, "", True, "", True], _
		[852, "", True, "", True], _
		[853, "", True, "", True], _
		[854, "", True, "", True], _
		[855, "", True, "", True], _
		[856, "", True, "", True], _
		[857, "", True, "", True], _
		[858, "", True, "", True], _
		[859, "", True, "", True], _
		[860, "", True, "", True], _
		[861, "", True, "", True], _
		[862, "", True, "", True], _
		[863, "", True, "", True], _
		[864, "", True, "", True], _
		[865, "", True, "", True], _
		[866, "", True, "", True], _
		[867, "", True, "", True], _
		[868, "", True, "", True], _
		[869, "", True, "", True], _
		[870, "", True, "", True], _
		[871, "", True, "", True], _
		[872, "", True, "", True], _
		[873, "", True, "", True], _
		[874, "", True, "", True], _
		[875, "", True, "", True], _
		[876, "", True, "", True], _
		[877, "", True, "", True], _
		[878, "", True, "", True], _
		[879, "", True, "", True], _
		[880, "", True, "", True], _
		[881, "", True, "", True], _
		[882, "", True, "", True], _
		[883, "", True, "", True], _
		[884, "", True, "", True], _
		[885, "", True, "", True], _
		[886, "", True, "", True], _
		[887, "", True, "", True], _
		[888, "", True, "", True], _
		[889, "", True, "", True], _
		[890, "", True, "", True], _
		[891, "", True, "", True], _
		[892, "", True, "", True], _
		[893, "", True, "", True], _
		[894, "", True, "", True], _
		[895, "", True, "", True], _
		[896, "", True, "", True], _
		[897, "", True, "", True], _
		[898, "", True, "", True], _
		[899, "", True, "", True], _
		[900, "", True, "+# to Strength (flat)", True], _
		[901, "", True, "+# to Dexterity (flat)", True], _
		[902, "", True, "+# to Vitality (flat)", True], _
		[903, "", True, "+# to Energy (flat)", True], _
		[904, "", True, "Spell Focus cap (max 100%)", True], _
		[905, "", True, "", True], _
		[906, "", True, "", True], _
		[907, "", True, "", True], _
		[908, "", True, "", True], _
		[909, "", True, "", True], _
		[910, "", True, "", True], _
		[911, "", True, "", True], _
		[912, "", True, "", True], _
		[913, "", True, "", True], _
		[914, "", True, "", True], _
		[915, "", True, "", True], _
		[916, "", True, "", True], _
		[917, "", True, "", True], _
		[918, "", True, "", True], _
		[919, "", True, "", True], _
		[920, "", True, "", True], _
		[921, "", True, "", True], _
		[922, "", True, "", True], _
		[923, "", True, "", True], _
		[924, "", True, "", True], _
		[925, "", True, "", True], _
		[926, "", True, "", True], _
		[927, "", True, "", True], _
		[928, "", True, "", True], _
		[929, "", True, "", True], _
		[930, "", True, "", True], _
		[931, "", True, "", True], _
		[932, "", True, "", True], _
		[933, "", True, "", True], _
		[934, "", True, "", True], _
		[935, "", True, "", True], _
		[936, "", True, "", True], _
		[937, "", True, "", True], _
		[938, "", True, "", True], _
		[939, "", True, "", True], _
		[940, "", True, "", True], _
		[941, "", True, "", True], _
		[942, "", True, "", True], _
		[943, "", True, "", True], _
		[944, "", True, "", True], _
		[945, "", True, "", True], _
		[946, "", True, "", True], _
		[947, "", True, "", True], _
		[948, "", True, "", True], _
		[949, "", True, "", True], _
		[950, "", True, "", True], _
		[951, "", True, "", True], _
		[952, "", True, "", True], _
		[953, "", True, "", True], _
		[954, "", True, "", True], _
		[955, "", True, "", True], _
		[956, "", True, "", True], _
		[957, "", True, "", True], _
		[958, "", True, "", True], _
		[959, "", True, "", True], _
		[960, "", True, "", True], _
		[961, "", True, "", True], _
		[962, "", True, "", True], _
		[963, "", True, "", True], _
		[964, "", True, "", True], _
		[965, "", True, "", True], _
		[966, "", True, "", True], _
		[967, "", True, "", True], _
		[968, "", True, "", True], _
		[969, "", True, "", True], _
		[970, "", True, "", True], _
		[971, "", True, "", True], _
		[972, "", True, "", True], _
		[973, "", True, "", True], _
		[974, "", True, "", True], _
		[975, "", True, "", True], _
		[976, "", True, "", True], _
		[977, "", True, "", True], _
		[978, "", True, "", True], _
		[979, "", True, "", True], _
		[980, "", True, "", True], _
		[981, "", True, "", True], _
		[982, "", True, "", True], _
		[983, "", True, "", True], _
		[984, "", True, "", True], _
		[985, "", True, "", True], _
		[986, "", True, "", True], _
		[987, "", True, "", True], _
		[988, "", True, "", True], _
		[989, "", True, "", True], _
		[990, "", True, "", True], _
		[991, "", True, "", True], _
		[992, "", True, "", True], _
		[993, "", True, "", True], _
		[994, "", True, "", True], _
		[995, "", True, "", True], _
		[996, "", True, "", True], _
		[997, "", True, "", True], _
		[998, "", True, "", True], _
		[999, "", True, "", True], _
		[1000, "", True, "", True], _
		[1001, "", True, "", True], _
		[1002, "", True, "", True], _
		[1003, "", True, "", True], _
		[1004, "", True, "", True], _
		[1005, "", True, "", True], _
		[1006, "", True, "", True], _
		[1007, "", True, "", True], _
		[1008, "", True, "", True], _
		[1009, "", True, "", True], _
		[1010, "", True, "", True], _
		[1011, "", True, "", True], _
		[1012, "", True, "", True], _
		[1013, "", True, "", True], _
		[1014, "", True, "", True], _
		[1015, "", True, "", True], _
		[1016, "", True, "", True], _
		[1017, "", True, "", True], _
		[1018, "", True, "", True], _
		[1019, "", True, "", True], _
		[1020, "", True, "", True], _
		[1021, "", True, "", True], _
		[1022, "", True, "", True], _
		[1023, "", True, "", True] _
]