import Database from 'better-sqlite3';
import path from 'path';

export function initDb(dbPath?: string): Database.Database {
  const p = dbPath || path.join(__dirname, '../../data/shortener.db');
  const db = new Database(p);

  // Enable WAL mode for better concurrent access
  db.pragma('journal_mode = WAL');

  db.exec(`
    CREATE TABLE IF NOT EXISTS urls (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_url TEXT NOT NULL,
      short_code TEXT UNIQUE NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      clicks INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS clicks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url_id INTEGER NOT NULL REFERENCES urls(id),
      clicked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      referrer TEXT,
      user_agent TEXT,
      ip_address TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_urls_short_code ON urls(short_code);
    CREATE INDEX IF NOT EXISTS idx_clicks_url_id ON clicks(url_id);
    CREATE INDEX IF NOT EXISTS idx_clicks_clicked_at ON clicks(clicked_at);
  `);

  return db;
}
