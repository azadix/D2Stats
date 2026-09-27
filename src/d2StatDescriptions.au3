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
		[67, "", True, "Skill Movement Speed #%", True], _
		[68, "", True, "Skill Attack Speed #%", True], _
		[69, "", True, "Skill Other Animation #%", True], _
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
		[82, "", True, "", False], _
		[83, "", True, "+# to [CLASS] skill levels", True], _
		[84, "", True, "+# to [ALL_CLASSES] skill levels", True], _
		[85, "", True, "#% To Experience Gained", True], _
		[86, "", True, "+# Life After Each Kill", True], _
		[87, "", True, "+#% to All Vendor prices", True], _
		[88, "", False, "", False], _
		[89, "", True, "+# to Light Radius", True], _
		[90, "", True, "Light color", True], _
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
		[108, "", True, "Slain Monsters Rest In Peace", True], _
		[109, "", True, "Curse Length Reduction: #%", True], _
		[110, "", True, "Poison Length Reduction: #%", True], _
		[111, "", True, "Damage +#", True], _
		[112, "", True, "Hit Causes Monsters to Flee #%", True], _
		[113, "", True, "Hit Blinds Target +#", True], _
		[114, "", True, "#% Damage Taken Goes to Mana", True], _
		[115, "", True, "Ignore Target Defense", True], _
		[116, "", True, "#% Target Defense", True], _
		[117, "", True, "Prevent Monster Heal", True], _
		[118, "", True, "Half Freeze duration", True], _
		[119, "", True, "#% Bonus to Attack Rating", True], _
		[120, "", True, "# to Monster Defense Per Hit", True], _
		[121, "", True, "+#% Damage to Demons", True], _
		[122, "", True, "+#% Damage to Undead", True], _
		[123, "", True, "+# to Attack Rating against Demons", True], _
		[124, "", True, "+# to Attack Rating against Undead", True], _
		[125, "", True, "Throwable", True], _
		[126, "", True, "+# to Elemental Skills", True], _
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
		[151, "", True, "Aura", True], _
		[152, "", True, "Indestructible", True], _
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
		[164, "", True, "+#% Chance of Uninterruptable Attack", True], _
		[165, "", True, "", True], _
		[166, "", True, "", True], _
		[167, "", True, "", True], _
		[168, "", True, "", True], _
		[169, "", True, "# Fury charges", True], _
		[170, "", True, "", True], _
		[171, "", True, "+#% Bonus to Defense", True], _
		[172, "", True, "", True], _
		[173, "", True, "", True], _
		[174, "", True, "", True], _
		[175, "", True, "", True], _
		[176, "", True, "", True], _
		[177, "", True, "", True], _
		[178, "", True, "", True], _
		[179, "", True, "", True], _
		[180, "", True, "+#% Damage vs. [MONSTER]", True], _
		[181, "", True, "+#% Attack Rating vs. [MONSTER]", True], _
		[182, "", True, "#% Defense bonus multiplier", True], _
		[183, "", True, "Craft points", False], _
		[184, "", True, "#% Damage reduction from all sources (Grit)", True], _
		[185, "", False, "Signets of Learning used", True], _
		[186, "", False, "Signets of Skill used", True], _
		[187, "", True, "Barbarian Stance (0-None, 1-Lion, 2-Bear, 3-Snake, 4-Eagle, 5-Wolf)", True], _
		[188, "", True, "", True], _
		[189, "", True, "", True], _
		[190, "", True, "", True], _
		[191, "", True, "Fury charges", True], _
		[192, "", True, "#% Chance to cast [SKILL] on kill", True], _
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
		[205, "", True, "+#% Maximum Avoid Chance", True], _
		[206, "", True, "", True], _
		[207, "", True, "", True], _
		[208, "", True, "+# Life on striking", True], _
		[209, "", True, "+# Mana on striking", True], _
		[210, "", True, "+# Life on melee attack", True], _
		[211, "", True, "Disable non-melee skills", True], _
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
		[228, "", True, "#% Mana Cost of skills", True], _
		[229, "", True, "Summon Physical resistance +#%", True], _
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
		[240, "", True, "+# to Strength (flat)", True], _
		[241, "", True, "+# to Dexterity (flat)", True], _
		[242, "", True, "+# to Vitality (flat)", True], _
		[243, "", True, "+# to Energy (flat)", True], _
		[244, "", True, "Spell Focus cap (max 100%)", True], _
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
		[261, "", True, "+# Extra Totems", True], _
		[262, "", True, "", True], _
		[263, "", True, "", True], _
		[264, "", True, "", True], _
		[265, "", True, "", True], _
		[266, "", True, "Area Effect Attack amount", True], _
		[267, "", True, "", True], _
		[268, "", True, "", True], _
		[269, "", True, "", True], _
		[270, "", True, "Summon Edyrem skill available", True], _
		[271, "", True, "#% Chance to cast [SKILL] when you die", True], _
		[272, "", True, "", True], _
		[273, "", True, "#% Chance to Crush attacker", True], _
		[274, "", True, "", True], _
		[275, "", True, "Cannot be Disenchanted", True], _
		[276, "", True, "Stun Attack amount", True], _
		[277, "", True, "Area Effect Attack amount", True], _
		[278, "", True, "Strength Factor +#", True], _
		[279, "", True, "Lion Stance damage bonus", True], _
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
		[297, "", True, "Mana drain -#%", True], _
		[298, "", True, "", True], _
		[299, "", True, "", True], _
		[300, "", True, "Additional Dexterity Damage bonus", True], _
		[301, "", True, "", True], _
		[302, "", True, "", True], _
		[303, "", True, "", True], _
		[304, "", True, "", True], _
		[305, "", True, "", True], _
		[306, "", True, "", True], _
		[307, "", True, "", True], _
		[308, "", True, "", True], _
		[309, "", True, "Cooldown Reduced by #", True], _
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
		[348, "", True, "#% Chance to block attacks and spells while wielding two claws", True], _
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
		[372, "", True, "Equipped runeword amount/Cannot be Unsocketed amount", True], _
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
		[396, "", True, "Continuity unlock", True], _
		[397, "", True, "Specialization unlock", True], _
		[398, "", True, "Valthek set aura", True], _
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
		[409, "", True, "Skill Duration", True], _
		[410, "", True, "# Prefixes", True], _
		[411, "", True, "# Suffixes", True], _
		[412, "", True, "", True], _
		[413, "", True, "", True], _
		[414, "", True, "+#% Bonus to Summoned Edyrem life", True], _
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
		[442, "", True, "Additional Strength Damage bonus", True], _
		[443, "", True, "Already upgraded amount", False], _
		[444, "", True, "Summon life +#%", True], _
		[445, "", True, "+# to Maximum Barbarian minions", True], _
		[446, "", True, "+#% Damage from Protector Spirit Bloodlust", True], _
		[447, "", True, "Restored amount", False], _
		[448, "", True, "#% Potion Effectiveness", True], _
		[449, "", True, "", True], _
		[450, "", True, "Trophy amount", True], _
		[451, "", True, "", True], _
		[452, "", True, "", True], _
		[453, "", True, "", True], _
		[454, "", True, "", True], _
		[455, "", True, "Sunstone of the Twin Seas resist scroll amount (0-3), Dulra Aegis upgrade amount (0-3)", True], _
		[456, "", True, "", True], _
		[457, "", True, "", True], _
		[458, "", True, "", True], _
		[459, "", True, "", True], _
		[460, "", True, "", True], _
		[461, "", True, "", True], _
		[462, "", True, "+#% Bonus damage to Vessel of Judgement", True], _
		[463, "", True, "", True], _
		[464, "", True, "", True], _
		[465, "", True, "", True], _
		[466, "", True, "Unused Essence slots amount (Umbaru Treasure)", True], _
		[467, "", True, "", True], _
		[468, "", True, "+#% Bonus damage to Vessel of Retribution", True], _
		[469, "", True, "+# to Vessels Extra Targets", True], _
		[470, "", True, "Summon damage +#%", True], _
		[471, "", True, "#% Trap Damage", True], _
		[472, "", True, "", True], _
		[473, "", True, "Ennead skill unlock", True], _
		[474, "", True, "Black Road unlock", True], _
		[475, "", True, "", True], _
		[476, "", True, "", True], _
		[477, "", True, "", True], _
		[478, "", True, "Socketed jewels", True], _
		[479, "", True, "Maximum Skill level +#", True], _
		[480, "", True, "+# to Vitality per Socketed Gem", True], _
		[481, "", True, "+# to Runemaster Defense Bonus", True], _
		[482, "", True, "Total Vitality bonus from Paragon", True], _
		[483, "", True, "Socketed runes (amount * 32)", True], _
		[484, "", True, "Innate Elemental damage +#%", True], _
		[485, "", True, "+# Spell Focus", True], _
		[486, "", True, "", True], _
		[487, "", True, "Summon Elemental resistances +#%", True], _
		[488, "", True, "+#% Spell Focus (from items/runes)", True], _
		[489, "", True, "Target takes additional damage +#", True], _
		[490, "", True, "", True], _
		[491, "", True, "", True], _
		[492, "", True, "", True], _
		[493, "", True, "Slows Ranged Attacker +#%", True], _
		[494, "", True, "", True], _
		[495, "", True, "", True], _
		[496, "", True, "'Cube with Oil of Craft to Reveal' amount", True], _
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
		[507, "", True, "# Deimoss pillars enabled/Duncraig totem aura ID", True], _
		[508, "", True, "Runes contributing to Gematria", True], _
		[509, "", True, "", True], _
		[510, "", True, "#% Chance to cast [SKILL] on block", True], _
		[511, "", True, "", True] _
]