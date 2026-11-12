-- Migration: 0002_indexes.sql
-- Description: Core indexes for fast lookups and high performance multi-tenant isolation

CREATE INDEX IF NOT EXISTS idx_users_google_uid ON users(google_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE INDEX IF NOT EXISTS idx_schools_school_code ON schools(school_code);
CREATE INDEX IF NOT EXISTS idx_schools_owner ON schools(owner_user_id);

CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes(school_id);
CREATE INDEX IF NOT EXISTS idx_classes_join_code ON classes(join_code);

CREATE INDEX IF NOT EXISTS idx_counselor_profiles_user ON counselor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_counselor_profiles_school ON counselor_profiles(school_id);

CREATE INDEX IF NOT EXISTS idx_student_profiles_user ON student_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_school ON student_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_class ON student_profiles(class_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_student_id ON student_profiles(student_id);
