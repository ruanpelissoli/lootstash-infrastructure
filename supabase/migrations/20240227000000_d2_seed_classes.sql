INSERT INTO d2.classes (id, name, skill_trees) VALUES
  ('amazon', 'Amazon', '[
    {"name": "Javelin and Spear", "skills": ["Jab", "Power Strike", "Poison Javelin", "Impale", "Lightning Bolt", "Charged Strike", "Plague Javelin", "Fend", "Lightning Strike", "Lightning Fury"]},
    {"name": "Passive and Magic", "skills": ["Inner Sight", "Critical Strike", "Dodge", "Slow Missiles", "Avoid", "Penetrate", "Decoy", "Evade", "Valkyrie", "Pierce"]},
    {"name": "Bow and Crossbow", "skills": ["Magic Arrow", "Fire Arrow", "Cold Arrow", "Multiple Shot", "Exploding Arrow", "Ice Arrow", "Guided Arrow", "Strafe", "Immolation Arrow", "Freezing Arrow"]}
  ]'::jsonb),
  ('necromancer', 'Necromancer', '[
    {"name": "Summoning", "skills": ["Skeleton Mastery", "Raise Skeleton", "Clay Golem", "Golem Mastery", "Raise Skeletal Mage", "Blood Golem", "Summon Resist", "Iron Golem", "Fire Golem", "Revive"]},
    {"name": "Poison and Bone", "skills": ["Teeth", "Bone Armor", "Poison Dagger", "Corpse Explosion", "Bone Wall", "Poison Explosion", "Bone Spear", "Bone Prison", "Poison Nova", "Bone Spirit"]},
    {"name": "Curses", "skills": ["Amplify Damage", "Dim Vision", "Weaken", "Iron Maiden", "Terror", "Confuse", "Life Tap", "Attract", "Decrepify", "Lower Resist"]}
  ]'::jsonb),
  ('barbarian', 'Barbarian', '[
    {"name": "Warcries", "skills": ["Howl", "Find Potion", "Taunt", "Shout", "Find Item", "Battle Cry", "Battle Orders", "Grim Ward", "War Cry", "Battle Command"]},
    {"name": "Combat Masteries", "skills": ["Sword Mastery", "Axe Mastery", "Mace Mastery", "Pole Arm Mastery", "Throwing Mastery", "Spear Mastery", "Increased Stamina", "Iron Skin", "Increased Speed", "Natural Resistance"]},
    {"name": "Combat Skills", "skills": ["Bash", "Leap", "Double Swing", "Stun", "Double Throw", "Leap Attack", "Concentrate", "Frenzy", "Whirlwind", "Berserk"]}
  ]'::jsonb),
  ('sorceress', 'Sorceress', '[
    {"name": "Fire", "skills": ["Fire Bolt", "Warmth", "Inferno", "Blaze", "Fire Ball", "Fire Wall", "Enchant", "Meteor", "Fire Mastery", "Hydra"]},
    {"name": "Lightning", "skills": ["Charged Bolt", "Static Field", "Telekinesis", "Nova", "Lightning", "Chain Lightning", "Teleport", "Thunder Storm", "Energy Shield", "Lightning Mastery"]},
    {"name": "Cold", "skills": ["Ice Bolt", "Frozen Armor", "Frost Nova", "Ice Blast", "Shiver Armor", "Glacial Spike", "Blizzard", "Chilling Armor", "Frozen Orb", "Cold Mastery"]}
  ]'::jsonb),
  ('paladin', 'Paladin', '[
    {"name": "Defensive Auras", "skills": ["Prayer", "Resist Fire", "Defiance", "Resist Cold", "Cleansing", "Resist Lightning", "Vigor", "Meditation", "Redemption", "Salvation"]},
    {"name": "Offensive Auras", "skills": ["Might", "Holy Fire", "Thorns", "Blessed Aim", "Concentration", "Holy Freeze", "Holy Shock", "Sanctuary", "Fanaticism", "Conviction"]},
    {"name": "Combat Skills", "skills": ["Sacrifice", "Smite", "Holy Bolt", "Zeal", "Charge", "Vengeance", "Blessed Hammer", "Conversion", "Holy Shield", "Fist of the Heavens"]}
  ]'::jsonb),
  ('druid', 'Druid', '[
    {"name": "Elemental", "skills": ["Firestorm", "Molten Boulder", "Arctic Blast", "Fissure", "Cyclone Armor", "Twister", "Volcano", "Tornado", "Armageddon", "Hurricane"]},
    {"name": "Shape Shifting", "skills": ["Werewolf", "Lycanthropy", "Werebear", "Maul", "Feral Rage", "Fire Claws", "Rabies", "Shock Wave", "Hunger", "Fury"]},
    {"name": "Summoning", "skills": ["Raven", "Poison Creeper", "Oak Sage", "Summon Spirit Wolf", "Carrion Vine", "Heart of Wolverine", "Summon Dire Wolf", "Solar Creeper", "Spirit of Barbs", "Summon Grizzly"]}
  ]'::jsonb),
  ('assassin', 'Assassin', '[
    {"name": "Martial Arts", "skills": ["Tiger Strike", "Dragon Talon", "Fists of Fire", "Dragon Claw", "Cobra Strike", "Claws of Thunder", "Blades of Ice", "Dragon Tail", "Dragon Flight", "Phoenix Strike"]},
    {"name": "Shadow Disciplines", "skills": ["Claw Mastery", "Psychic Hammer", "Burst of Speed", "Weapon Block", "Cloak of Shadows", "Fade", "Shadow Warrior", "Mind Blast", "Venom", "Shadow Master"]},
    {"name": "Traps", "skills": ["Fire Blast", "Shock Web", "Blade Sentinel", "Charged Bolt Sentry", "Wake of Fire", "Blade Fury", "Lightning Sentry", "Wake of Inferno", "Death Sentry", "Blade Shield"]}
  ]'::jsonb),
  ('warlock', 'Warlock', '[
    {"name": "Chaos", "skills": []},
    {"name": "Demon", "skills": []},
    {"name": "Eldritch", "skills": []}
  ]'::jsonb);
