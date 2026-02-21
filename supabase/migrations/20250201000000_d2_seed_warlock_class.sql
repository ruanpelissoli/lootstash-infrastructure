INSERT INTO d2.classes (id, name, skill_suffix, skill_trees)
VALUES ('warlock', 'Warlock', 'Warlock', '[
  {
    "name": "Chaos",
    "skills": [
      "Miasma Bolt",
      "Ring of Fire",
      "Sigil: Lethargy",
      "Sigil: Rancor",
      "Miasma Chain",
      "Flame Wave",
      "Sigil: Death",
      "Enhanced Entropy",
      "Apocalypse",
      "Abyss"
    ]
  },
  {
    "name": "Eldritch",
    "skills": [
      "Levitation Mastery",
      "Hex: Bane",
      "Cleave",
      "Echoing Strike",
      "Hex: Purge",
      "Blade Warp",
      "Psychic Ward",
      "Eldritch Blast",
      "Hex: Siphon",
      "Mirrored Blades"
    ]
  },
  {
    "name": "Demon",
    "skills": [
      "Demonic Mastery",
      "Summon Goatman",
      "Blood Oath",
      "Death Mark",
      "Summon Tainted",
      "Blood Boil",
      "Summon Defiler",
      "Engorge",
      "Consume",
      "Bind Demon"
    ]
  }
]'::jsonb)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    skill_suffix = EXCLUDED.skill_suffix,
    skill_trees = EXCLUDED.skill_trees,
    updated_at = NOW();
