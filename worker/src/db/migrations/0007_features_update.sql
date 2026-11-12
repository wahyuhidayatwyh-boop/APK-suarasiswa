-- Migration: 0007_features_update.sql
-- Description: Add soft delete columns for reports and notifications

ALTER TABLE reports ADD COLUMN deleted_by_student INTEGER DEFAULT 0;
ALTER TABLE reports ADD COLUMN deleted_by_counselor INTEGER DEFAULT 0;
ALTER TABLE notifications ADD COLUMN deleted_at DATETIME;
