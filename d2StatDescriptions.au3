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
		["", "+#% Increased chance of blocking"], _
		["", "+# to Minimum 1-handed damage"], _
		["", "+# to Maximum 1-handed damage"], _
		["", "+# to Minimum 2-handed damage"], _
		["", "+# to Maximum 2-handed damage"], _
		["", "+# to Enhanced Weapon Damage"], _
		["", ""], _
		["", "Regenerate Mana #%"], _
		["", "Heal Stamina #%"], _
		["", ""], _
		["", ""], _
		["", "+# Defense"], _
		["", "+# vs. Missile"], _
		["", "+# vs. Melee"], _
		["", "Physical Damage Reduced by #"], _
		["", "Magic Damage Reduced by #"], _
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
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Skill Faster Run Walk +#%"], _
		["", "Skill Attack Speed +#%"], _
		["", ""], _
		["", "Quiver quantity #"], _
		["", "Equipped items value"], _
		["", "Equipped items total Durability"], _
		["", "+# Maximum Durability"], _
		["", "Life regenerated per second"], _
		["", "Increase Maximum Durability #%"], _
		["", "Increase Maximum Life #%"], _
		["", "Increase Maximum Mana #%"], _
		["", "Attacker Takes Damage of #"], _
		["", "#% Extra Gold from Monsters"], _
		["", "#% Better Chance of Getting Magic Items"], _
		["", "Knockback"], _
		["", "Unknown (Invisible)"], _
		["", "Bonus +# to [ALL_CLASSES] skill level"], _
		["", "Bonus +# to [ALL_CLASSES] skill level"], _
		["", "#% To Experience Gained"], _
		["", "+# Life After Each Kill"], _
		["", "Reduces Prices #%"], _
		["", ""], _
		["", "+# to Light Radius"], _
		["", ""], _
		["", "Requirements #%"], _
		["", "+# Required level"], _
		["", "#% Increased Attack Speed"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Run/Walk"], _
		["", "+# skills ([CLASS] only) eg. +17 to Divine Judgement"], _
		["", ""], _
		["", "#% Faster Hit Recovery"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Block Rate"], _
		["", ""], _
		["", ""], _
		["", "#% Faster Cast Rate"], _
		["", ""], _
		["", "+# skills eg. +9 to Teleport"], _
		["", "Slain Monsters Rest In Peace (1/0)"], _
		["", "Curse Length Reduced by #%"], _
		["", "Poison Length Reduced by #%"], _
		["", "Damage +#"], _
		["", "Hit Causes Monsters to Flee #%"], _
		["", "Hit Blinds Target +#"], _
		["", "#% Damage Taken Goes to Mana"], _
		["", "Ignore Target Defense"], _
		["", "#% Target Defense"], _
		["", "Prevent Monster Heal"], _
		["", "Half Freeze Duration (1/0)"], _
		["", "#% Bonus to Attack Rating"], _
		["", "# to Monster Defense Per Hit"], _
		["", "+#% Damage to Demons"], _
		["", "+#% Damage to Undead"], _
		["", "+# to Attack Rating against Demons"], _
		["", "+# to Attack Rating against Undead"], _
		["", "Throwable"], _
		["", ""], _
		["", "All Skill Levels +#"], _
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
		["", "Indestructible (1/0)"], _
		["", "Cannot Be Frozen"], _
		["", "#% Slower Stamina Drain"], _
		["", "#% Chance to Reanimate Target"], _
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
		["", "+#% Total Character Defence"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Damage vs. Necrobots ???"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Melee devotion flag (20% DR)"], _
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
		["", ""], _
		["", ""], _
		["", "#% Chance to cast [SKILL] when struck"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# Life on striking"], _
		["", "+# Mana on striking"], _
		["", "+# Life on attack"], _
		["", "Melee devotion flag (disable non-melee skills)"], _
		["", ""], _
		["", "#% Max block chance modifier"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Riftwalker Eye quest #3"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Stun Attack"], _
		["", ""], _
		["", "Strength Factor +#"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "#% Chance to cast [SKILL] when struck by a missile"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Orb effects applied to this item are doubled amount"], _
		["", "Mystic orb used amount"], _
		["", ""], _
		["", "#% Chance to cast [SKILL] on death blow"], _
		["", ""], _
		["", ""], _
		["", "Mana on attack +#"], _
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
		["", "#% To Fire Skill Damage"], _
		["", "#% To Lightning Skill Damage"], _
		["", "#% To Cold Skill Damage"], _
		["", "#% To Poison Skill Damage"], _
		["", "-#% To Enemy Fire Resistance"], _
		["", "-#% To Enemy Lightning Resistance"], _
		["", "-#% To Enemy Cold Resistance"], _
		["", "-#% To Enemy Poison Resistance"], _
		["", "#% Critical Strike (for Barbarian)"], _
		["", "Dodge +#% (Chance to avoid melee while standing)"], _
		["", "Avoid +#% (Chance to avoid projectile while standing)"], _
		["", "Evade +#% (Chance to avoid any attack while moving)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "#% Critical Strike"], _
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
		["", "Charm counter (Amount *2) (except Ennead charm - 1pt, and Riftwalker - 6 full upgraded)"], _
		["", "+#% to Physical/Magic spell damage"], _
		["", ""], _
		["", "Strength +#%"], _
		["", "Dexterity +#%"], _
		["", "Energy +#%"], _
		["", "Vitality +#%"], _
		["", "Slows Attacker +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
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
		["", "+#% Bonus damage to [SKILL] (Orange text)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+#% Bonus Damage to Mark of the Wild"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Continuity unlock (1/0)"], _
		["", "Specialization unlock (1/0)"], _
		["", ""], _
		["", ""], _
		["", ""], _
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
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "+# to Maximum Necromancer minions"], _
		["", ""], _
		["", "Already upgraded"], _
		["", "Summoned minion life +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "#% increased Healing from Potions"], _
		["", ""], _
		["", "Trophy counter"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Sunstone of the Twin Seas resist scroll counter (0-3), Dulra Aegis upgrades (0-3)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Summoned minion damage +#%"], _
		["", ""], _
		["", ""], _
		["", "Ennead skill unlock flag (1/0)"], _
		["", "Black Road unlock (1/0)"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Maximum Skill level +#"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Increases by 32 for each socketed rune"], _
		["", "Innate Elemental damage +#%"], _
		["", "Spell Focus +#"], _
		["", ""], _
		["", "Summoned minion resistances +#%"], _
		["", ""], _
		["", "Target takes additional damage +# "], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Slows Ranged Attacker +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Corrupted items count"], _
		["", ""], _
		["", ""], _
		["", "Summoned minion attack rating +#%"], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", ""], _
		["", "Strength +#"], _
		["", "Dexterity +#"], _
		["", "Vitality +#"], _
		["", "Energy +#"], _
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