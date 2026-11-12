-- Migration: 0003_school_memberships.sql
-- Description: Multi-tenant School memberships and Counselor invitations

CREATE TABLE IF NOT EXISTS school_memberships (
  id TEXT PRIMARY KEY,
  school_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('COUNSELOR', 'STUDENT')),
  is_owner INTEGER DEFAULT 0,
  status TEXT DEFAULT 'ACTIVE',
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(school_id, user_id),
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS counselor_invites (
  id TEXT PRIMARY KEY,
  school_id TEXT NOT NULL,
  code_hash TEXT UNIQUE NOT NULL,
  created_by TEXT NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME,
  status TEXT DEFAULT 'PENDING',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_memberships_user ON school_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_school ON school_memberships(school_id);
CREATE INDEX IF NOT EXISTS idx_memberships_role ON school_memberships(role);
CREATE INDEX IF NOT EXISTS idx_counselor_invites_hash ON counselor_invites(code_hash);
