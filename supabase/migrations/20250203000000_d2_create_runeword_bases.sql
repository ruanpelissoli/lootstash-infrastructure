CREATE TABLE IF NOT EXISTS d2.runeword_bases (
    id SERIAL PRIMARY KEY,
    runeword_id INT NOT NULL REFERENCES d2.runewords(id) ON DELETE CASCADE,
    item_base_id INT NOT NULL,
    item_base_code VARCHAR(10) NOT NULL,
    item_base_name VARCHAR(100) NOT NULL,
    category VARCHAR(20) NOT NULL,
    max_sockets INT DEFAULT 0,
    required_sockets INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (runeword_id, item_base_id)
);
