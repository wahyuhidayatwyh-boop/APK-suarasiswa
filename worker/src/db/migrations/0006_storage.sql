-- Migration: 0006_storage.sql
-- Description: Remote Storage Files in D1 (Persistent across restarts)

CREATE TABLE IF NOT EXISTS storage_files (
  id TEXT PRIMARY KEY,
  school_id TEXT NOT NULL,
  file_name TEXT,
  mime_type TEXT,
  file_size INTEGER,
  file_data TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_storage_files_school ON storage_files(school_id);
