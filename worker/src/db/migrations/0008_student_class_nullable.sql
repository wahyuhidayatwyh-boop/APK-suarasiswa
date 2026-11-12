-- Migration: 0008_student_class_nullable.sql
-- Description: Make class_id nullable and set ON DELETE SET NULL for safe class deletion

CREATE TABLE IF NOT EXISTS student_profiles_new (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  class_id TEXT,
  student_id TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL
);

INSERT INTO student_profiles_new (id, user_id, school_id, class_id, student_id, name, phone, created_at, updated_at)
SELECT id, user_id, school_id, class_id, student_id, name, phone, created_at, updated_at FROM student_profiles;

DROP TABLE student_profiles;

ALTER TABLE student_profiles_new RENAME TO student_profiles;

CREATE INDEX IF NOT EXISTS idx_student_profiles_user ON student_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_school ON student_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_class ON student_profiles(class_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_student_id ON student_profiles(student_id);
