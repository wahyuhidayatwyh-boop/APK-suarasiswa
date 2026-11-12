export interface Env {
  DB: D1Database;
  STORAGE_BUCKET?: R2Bucket;
  JWT_SECRET: string;
  ENVIRONMENT: string;
  ALLOWED_ORIGIN?: string;
}

export type UserRole = 'COUNSELOR' | 'STUDENT';

export interface User {
  id: string;
  google_uid: string;
  email: string;
  name: string;
  photo_url?: string | null;
  auth_provider: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface School {
  id: string;
  name: string;
  school_code: string;
  logo_url?: string | null;
  address?: string | null;
  description?: string | null;
  owner_user_id: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface SchoolMembership {
  id: string;
  school_id: string;
  user_id: string;
  role: UserRole;
  is_owner: number;
  status: string;
  joined_at: string;
  created_at: string;
  updated_at: string;
}

export interface CounselorProfile {
  id: string;
  user_id: string;
  school_id: string;
  name: string;
  employee_id?: string | null;
  phone?: string | null;
  photo_url?: string | null;
  created_at: string;
  updated_at: string;
}

export interface StudentProfile {
  id: string;
  user_id: string;
  school_id: string;
  class_id: string;
  student_id: string; // NIS
  name: string;
  phone?: string | null;
  created_at: string;
  updated_at: string;
}

export interface SchoolClass {
  id: string;
  school_id: string;
  name: string;
  grade: string;
  join_code: string;
  description?: string | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface Report {
  id: string;
  school_id: string;
  student_id: string;
  report_code: string;
  type: string;
  category: string;
  description: string;
  incident_date: string;
  incident_location: string;
  reporter_type: string;
  priority: string;
  status: string;
  internal_notes?: string | null;
  created_at: string;
  updated_at: string;
  resolved_at?: string | null;
}

export interface ReportMessage {
  id: string;
  report_id: string;
  school_id: string;
  sender_user_id: string;
  message: string;
  attachment_url?: string | null;
  created_at: string;
}

export interface Content {
  id: string;
  school_id: string;
  author_id: string;
  title: string;
  short_description: string;
  body?: string | null;
  image_url?: string | null;
  type: string;
  status: string;
  views_count: number;
  created_at: string;
  updated_at: string;
}

export interface AppNotification {
  id: string;
  user_id: string;
  school_id: string;
  title: string;
  body: string;
  type: string;
  reference_id?: string | null;
  is_read: number;
  created_at: string;
}

// Variables attached to Hono Context
export interface Variables {
  user: User;
  membership?: SchoolMembership;
}
