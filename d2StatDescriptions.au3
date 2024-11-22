global $g_d2StatNames[][2] = [ _
		["Strength base", "+# to Strength"], _
		["Energy base", "+# to Energy"], _
		["Dexterity base", "+# to Dexterity"], _
		["Vitality base", "+# to Vitality"], _
		["Free stat points", "Free stat points"], _
		["Free skill points", "Free skill points"], _
		["Current Life", "Current Life"], _
		["Base Life", "+# to Life"], _
		["Current Mana", "Current Mana"], _
		["Base Mana", "+# to Mana"], _
		["Current Stamina", "Total Stamina"], _
		["Base Stamina", "+# to Maximum Stamina"], _
		["Character level", "Character level"], _
		["Current Experience", "Current Experience"], _
		["Gold amount on character", "Gold amount on character"], _
		["Gold amount in stash", "Gold amount in stash"], _
		["", "+#% Enhanced Defense"], _
		["", "+#% Enhanced Damage"], _
		["", ""], _
		["", "+# to Attack rating"], _
		["", "+#% Base block chance"], _
		["", "+# to Minimum 1-handed damage"], _
		["", "+# to Maximum 1-handed damage"], _
		["", "+# to Minimum 2-handed damage"], _
		["", "+# to Maximum 2-handed damage"], _
		["", "+#% to Enhanced Weapon Damage"], _
		["", ""], _
		["", "Regenerate Mana #%"], _
		["", "Heal Stamina #%"], _
		["", ""], _
		["", ""], _
		["", "+# Defense"], _
		["", "+# Defense vs. Missile"], _
		["", "+# Defense vs. Melee"], _
		["", "Physical Damage Reduced by #"], _
		["", "Elemental/Magic Damage Reduced by #"], _
		["", "Physical Resist +#%"], _
		["", "Magic Resist +#%"], _
		["", "+#% to Maximum Magic Resist"], _
		["", "Fire Resist +#%"], _
		["", "+#% to Maximum Fire Resist"], _
		["", "Lightning Resist +#%"], _
		["", "+#% to Maximum Lightning Resist"], _
		["", "Cold Resist +#%"], _
		["", "+#% to Maximum Cold Resist"], _
		["", "Poison Resist +#%"], _
		["", "+#% to Maximum Poison Resist"], _
		["", ""], _
		["", "+# to Minimum Fire Damage"], _
		["", "+# to Maximum Fire Damage"], _
		["", "+# to Minimum Lightning Damage"], _
		["", "+# to Maximum Lightning Damage"], _
		["", "+# to Minimum Magic Damage"], _
		["", "+# to Maximum Magic Damage"], _
		["", "+# to Minimum Cold Damage"], _
		["", "+# to Maximum Cold Damage"], _
		["", ""], _
		["", "+# to Minimum Poison Damage / second"], _
		["", "+# to Maximum Poison Damage / second"], _
		["", ""], _
		["", "#% Life Stolen Per Hit"], _
		["", ""], _
		["", "#% Mana Stolen Per Hit"], _
		["", ""], _
		["", "#% Stamina Stolen Per Hit"], _
		["", ""], _
		["", ""], _
		["", "Skill Faster Run Walk +#%"], _
		["", "Skill Attack Speed +#%"], _
		["", ""], _
		["", "Quiver/Throwing weapon quantity amount"], _
		["", "Equipped items value"], _
		["", "Equipped items total Durability"], _
		["", "+# Maximum Durability"], _
		["", "Life regenerated per second"], _
		["", "Increase Maximum Durability #%"], _
		["", "Increase Maximum Life #%"], _
		["", "Increase Maximum Mana #%"], _
		["", "Attacker Takes Damage of #"], _
		["", "#% Gold Find"], _
		["", "#% Magic Find"], _
		["", "Knockback"], _
		["", "Unknown (Invisible)"], _
		["", "+# to [CLASS] skill levels"], _
		["", "+# to [ALL_CLASSES] skill levels"], _
		["", "#% To Experience Gained"], _
		["", "+# Life After Each Kill"], _
		["", "+#% to All Vendor prices"], _
		["", ""], _
		["", "+# to Light Radius"], _
		["", ""], _
		["", "Requirements #%"], _
		["", "+# Required level"], _
		["", "#% Increased Attack Speed"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Run/Walk"], _
		["", "+# to [SKILL]"], _
		["", ""], _
		["", "#% Faster Hit Recovery"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Block Rate"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Cast Rate"], _
		["", ""], _
		["", "+# to [SKILL]"], _
		["", "Slain Monsters Rest In Peace (0/1)"], _
		["", "Curse Length Reduced by #%"], _
		["", "Poison Length Reduced by #%"], _
		["", "Damage +#"], _
		["", "Hit Causes Monsters to Flee #%"], _
		["", "Hit Blinds Target +#"], _
		["", "#% Damage Taken Goes to Mana"], _
		["", "Ignore Target Defense"], _
		["", "#% Target Defense"], _
		["", "Prevent Monster Heal"], _
		["", "Half Freeze Duration (0/1)"], _
		["", "#% Bonus to Attack Rating"], _
		["", "# to Monster Defense Per Hit"], _
		["", "+#% Damage to Demons"], _
		["", "+#% Damage to Undead"], _
		["", "+# to Attack Rating against Demons"], _
		["", "+# to Attack Rating against Undead"], _
		["", "Throwable"], _
		["", ""], _
		["", "+# to All Skills"], _
		["", "Attacker Takes Lightning Damage of #"], _
		["", ""], _
		["", ""], _
		["", "+#% Damage reflected"], _
		["", ""], _
		["", ""], _
		["", "Freezes Target +#"], _
		["", "#% Chance of Open Wounds"], _
		["", "#% Chance of Crushing Blow"], _
		["", "+# Kick Damage"], _
		["", "+# to Mana After Each Kill"], _
		["", "+# Life after each Demon Kill"], _
		["", "Extra Blood (Invisible)"], _
		["", "#% Deadly Strike"], _
		["", "Fire Absorb #%"], _
		["", "+# Fire Absorb"], _
		["", "Lightning Absorb #%"], _
		["", "+# Lightning Absorb"], _
		["", "Magic Absorb #%"], _
		["", "+# Magic Absorb"], _
		["", "Cold Absorb #%"], _
		["", "+# Cold Absorb"], _
		["", "Slows Target by #%"], _
		["", ""], _
		["", "Indestructible (0/1)"], _
		["", "Cannot Be Frozen"], _
		["", "#% Slower Stamina Drain"], _
		["", "#% Reanimate as [MONSTER_NAME]"], _
		["", "Piercing Attack"], _
		["", "Fires Magic Arrows"], _
		["", "Fires Explosive Arrows or Bolts"], _
		["", "+# to Minimum Throw Damage"], _
		["", "+# to Maximum Throw Damage"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Uniterruptable Attack"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Total Character Defense"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Damage vs. [MONSTER]"], _
		["", ""], _
		["", "#% Defense bonus multiplier (Mostly 'Total character defense = 0' and Runemaster)"], _
		["", "Craft points - OBSOLETE"], _
		["", "20% Damage reduction flag (0/1)"], _
		["Signets of Learning used", "Signets of Learning used"], _
		["", ""], _
		["", "Barbarian Stance (0-None, 1-Lion, 2-Bear, 3-Snake, 4-Eagle, 5-Wolf)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Equipped items socket amount"], _
		["", "#% Chance to cast [SKILL] on melee attack"], _
		["", "#% Chance to cast [SKILL] on kill"], _
		["", "#% Chance to cast [SKILL] when you die"], _
		["", "#% Chance to cast [SKILL] on striking"], _
		["", "#% Chance to cast [SKILL] when you level-up"], _
		["", "Mega Impact amount"], _
		["", "#% Chance to cast [SKILL] when struck"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# Life on striking"], _
		["", "+# Mana on striking"], _
		["", "+# Life on melee attack"], _
		["", "Disable non-melee skills flag (0/1)"], _
		["", ""], _
		["", "#% Max block chance modifier"], _
		["", "+# Defense (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", "+#% Enhanced Defense (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", "+# to Life (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", "+# to Mana (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", "+# to Maximum damage (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", "Shrine Blessed amount"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Area Effect Attack amount"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "#% Chance to cast [SKILL] when you die"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Cannot be Disenchanted"], _
		["", "Stun Attack amount"], _
		["", "Area Effect Attack amount"], _
		["", "Strength Factor +#"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "#% Chance to cast [SKILL] when attacked"], _
		["", "#% Chance to cast [SKILL] when struck by a missile"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Orb effects applied to this item are quadrupled"], _
		["", "Orb effects applied to this item are doubled (amount * 2)"], _
		["", "Mystic orb used amount"], _
		["", ""], _
		["", "#% Chance to cast [SKILL] on death blow"], _
		["", ""], _
		["", ""], _
		["", "+# Mana on melee attack"], _
		["", ""], _
		["", "Mana drain -#% (from Werewolf morph)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "# Buff activations???"], _
		["", "#% To Fire Spell Damage"], _
		["", "#% To Lightning Spell Damage"], _
		["", "#% To Cold Spell Damage"], _
		["", "#% To Poison Spell Damage"], _
		["", "-#% To Enemy Fire Resistance"], _
		["", "-#% To Enemy Lightning Resistance"], _
		["", "-#% To Enemy Cold Resistance"], _
		["", "-#% To Enemy Poison Resistance"], _
		["", "#% Critical Strike (for Barbarian)"], _
		["", "Dodge +#% (Chance to avoid melee attack while standing)"], _
		["", "Avoid +#% (Chance to avoid projectile attack while standing)"], _
		["", "Evade +#% (Chance to avoid any attack while moving)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Critical Strike"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Increases by 511 when adding points on tree???"], _
		["", "Combined skill level from Reward and Mastery tree???"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Charms (amount * 2) (for explanation see 'Basic' tab)"], _
		["", "+#% to Physical/Magic spell damage"], _
		["", "-#% To Enemy Physical/Magic Resistance"], _
		["", "Strength +#%"], _
		["", "Dexterity +#%"], _
		["", "Energy +#%"], _
		["", "Vitality +#%"], _
		["", "Slows Attacker +#%"], _
		["", "Attacker flees after striking +#%"], _
		["", "Freezes Attacker +#%"], _
		["", "Blinds Attacker +#%"], _
		["", "Attacker Takes Cold Damage of #"], _
		["", "Attacker Takes Fire Damage of #"], _
		["", ""], _
		["", ""], _
		["", "Amazing Grace amount"], _
		["", "Equipped runeword amount"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Slows Melee Target +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus Damage to Bloodlust"], _
		["", "+#% Bonus Elemental damage to Bloodlust"], _
		["", ""], _
		["", "Base weapon Innate [ELEMENT_TYPE] damage #%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus Damage to Mark of the Wild"], _
		["", "+#% Bonus Elemental Damage to Mark of the Wild"], _
		["", "+#% Duration Bonus to Mark of the Wild"], _
		["", "Already enchanted amount"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Continuity unlock (0/1)"], _
		["", "Specialization unlock (0/1)"], _
		["", "Valthek set aura flag (0/1)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "# Prefixes"], _
		["", "# Suffixes"], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus to summoned Edyrem life"], _
		["", "#% Innate Damage"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "After blocking/taking weapon damage effect active"], _
		["", ""], _
		["", ""], _
		["", "Bone Chimes - [DtU + DtD]% added as [STAT_NAME] +#% Bonus"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus to Poison skill duration"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# Life when struck by an enemy"], _
		["", "+# Mana when struck by an enemy"], _
		["", "+# to Maximum Necromancer minions"], _
		["", ""], _
		["", "Already upgraded amount"], _
		["", "Summoned minion life +#%"], _
		["", "+# to Maximum Barbarian minions"], _
		["", "+#% Damage from Protector Spirit Bloodlust"], _
		["", "Restored amount"], _
		["", "#% increased Healing from Potions"], _
		["", ""], _
		["", "Trophy amount"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Sunstone of the Twin Seas resist scroll amount (0-3), Dulra Aegis upgrade amount (0-3)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus damage to Vessel of Judgement"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus damage to Vessel of Retribution"], _
		["", "+# to Vessels Extra Targets"], _
		["", "Summoned minion damage +#%"], _
		["", ""], _
		["", ""], _
		["", "Ennead skill (0/1)"], _
		["", "Black Road (0/1)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Maximum Skill level +#"], _
		["", "+# to Vitality per Socketed Gem"], _
		["", "+# to Runemaster Defense Bonus"], _
		["", ""], _
		["", "Socketed runes (amount * 32)"], _
		["", "Innate Elemental damage +#%"], _
		["", "+# Spell Focus"], _
		["", ""], _
		["", "Summoned minion resistances +#%"], _
		["", "+#% Spell Focus (from items/runes)"], _
		["", "Target takes additional damage +#"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Slows Ranged Attacker +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Corrupted items amount"], _
		["", ""], _
		["", ""], _
		["", "Summoned minion attack rating +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# Life Regenerated per Second (Based on Character Level) [(value / 32) * [LEVEL]]"], _
		["", ""], _
		["", ""], _
		["", "Runes contributing to Gematria"], _
		["", ""], _
		["", "#% Chance to cast [SKILL] when blocking"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# to Strength (base)"], _
		["", "+# to Dexterity (base)"], _
		["", "+# to Vitality (base)"], _
		["", "+# to Energy (base)"], _
		["", "Spell Focus cap (max 100%)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""] _
	]