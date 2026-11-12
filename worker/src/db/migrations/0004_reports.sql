-- Migration: 0004_reports.sql
-- Description: Reports, evidence attachments, private chat messages, timeline, and followups

CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  school_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  report_code TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL, -- bullying, aspiration, suggestion, grievance
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  incident_date DATETIME NOT NULL,
  incident_location TEXT NOT NULL,
  reporter_type TEXT NOT NULL, -- victim, witness, anonymous
  priority TEXT DEFAULT 'medium', -- low, medium, high, urgent
  status TEXT DEFAULT 'pending', -- pending, investigating, action_taken, resolved, rejected
  internal_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS report_attachments (
  id TEXT PRIMARY KEY,
  report_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_name TEXT,
  file_type TEXT,
  file_size INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS report_messages (
  id TEXT PRIMARY KEY,
  report_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  message TEXT NOT NULL,
  attachment_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS report_timeline (
  id TEXT PRIMARY KEY,
  report_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (report_id) REFERENCES reports(id) ON DELETE CASCADE,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_reports_school_id ON reports(school_id);
CREATE INDEX IF NOT EXISTS idx_reports_student_id ON reports(student_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_code ON reports(report_code);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at);
CREATE INDEX IF NOT EXISTS idx_report_messages_report ON report_messages(report_id);
CREATE INDEX IF NOT EXISTS idx_report_timeline_report ON report_timeline(report_id);
