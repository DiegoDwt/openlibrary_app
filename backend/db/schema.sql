CREATE TABLE IF NOT EXISTS books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    authors TEXT,
    isbn TEXT UNIQUE,
    cover_url TEXT,
    description TEXT,
    language TEXT,
    source_url TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
