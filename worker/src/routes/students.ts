import { Hono } from 'hono';
import { Env, Variables, School, SchoolClass, StudentProfile, SchoolMembership } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireStudent } from '../middleware/authorization';

const students = new Hono<{ Bindings: Env; Variables: Variables }>();

// Student join school onboarding (Only School Code required, NO Class Code)
students.post('/join', authMiddleware, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    school_code: string;
    student_id: string; // NIS
    student_name: string;
    phone?: string;
  }>();

  if (!body.school_code || !body.student_id || !body.student_name) {
    return errorResponse(c, 'INVALID_INPUT', 'Kode sekolah, NIS, dan nama lengkap wajib diisi.');
  }

  // 1. Verify School Code
  const school = await c.env.DB.prepare('SELECT * FROM schools WHERE school_code = ? AND status = ?')
    .bind(body.school_code.toUpperCase().trim(), 'ACTIVE')
    .first<School>();

  if (!school) {
    return errorResponse(c, 'INVALID_SCHOOL_CODE', 'Kode sekolah tidak valid atau sekolah tidak aktif.', 404);
  }

  // 2. Check if user already joined this school
  const existingMembership = await c.env.DB.prepare(
    'SELECT * FROM school_memberships WHERE school_id = ? AND user_id = ?'
  )
    .bind(school.id, user.id)
    .first<SchoolMembership>();

  if (existingMembership) {
    return errorResponse(c, 'ALREADY_JOINED', 'Akun Anda sudah terdaftar di sekolah ini.', 400);
  }

  // 3. Check if NIS is already registered in this school
  const existingNis = await c.env.DB.prepare(
    'SELECT * FROM student_profiles WHERE school_id = ? AND student_id = ?'
  )
    .bind(school.id, body.student_id.trim())
    .first<StudentProfile>();

  if (existingNis) {
    return errorResponse(c, 'DUPLICATE_NIS', 'Nomor Induk Siswa (NIS) ini sudah terdaftar oleh siswa lain di sekolah ini.', 400);
  }

  const now = new Date().toISOString();

  // 4. Create School Membership
  const membershipId = `MEM_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO school_memberships (id, school_id, user_id, role, is_owner, status, joined_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(membershipId, school.id, user.id, 'STUDENT', 0, 'ACTIVE', now, now, now)
    .run();

  // 5. Create Student Profile with class_id = NULL
  const profileId = `STU_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO student_profiles (id, user_id, school_id, class_id, student_id, name, phone, created_at, updated_at) VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?)'
  )
    .bind(profileId, user.id, school.id, body.student_id.trim(), body.student_name.trim(), body.phone || null, now, now)
    .run();

  // 6. Record Audit Log
  await c.env.DB.prepare(
    'INSERT INTO audit_logs (id, school_id, user_id, action, entity_type, entity_id, metadata, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(crypto.randomUUID(), school.id, user.id, 'STUDENT_JOINED_SCHOOL', 'student', profileId, JSON.stringify({ nis: body.student_id }), now)
    .run();

  const newMembership: SchoolMembership = {
    id: membershipId,
    school_id: school.id,
    user_id: user.id,
    role: 'STUDENT',
    is_owner: 0,
    status: 'ACTIVE',
    joined_at: now,
    created_at: now,
    updated_at: now,
  };

  const newProfile: StudentProfile & { class_name: string | null } = {
    id: profileId,
    user_id: user.id,
    school_id: school.id,
    class_id: null,
    student_id: body.student_id.trim(),
    name: body.student_name.trim(),
    phone: body.phone || null,
    created_at: now,
    updated_at: now,
    class_name: null,
  };

  return successResponse(c, {
    school,
    membership: newMembership,
    student_profile: newProfile,
  });
});

// Get current student profile (LEFT JOIN so null class_id works)
students.get('/me', authMiddleware, schoolContextMiddleware(true), requireStudent, async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  const profile = await c.env.DB.prepare(`
    SELECT s.*, c.name as class_name
    FROM student_profiles s
    LEFT JOIN classes c ON c.id = s.class_id
    WHERE s.user_id = ? AND s.school_id = ?
  `)
    .bind(user.id, membership.school_id)
    .first<StudentProfile & { class_name: string | null }>();

  if (!profile) {
    return errorResponse(c, 'NOT_FOUND', 'Profil siswa tidak ditemukan.', 404);
  }

  return successResponse(c, profile);
});

// Student selects or switches active class (Enforces 1 student = 1 class)
students.post('/select-class', authMiddleware, schoolContextMiddleware(true), requireStudent, async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const body = await c.req.json<{ class_id: string }>();

  if (!body.class_id) {
    return errorResponse(c, 'INVALID_INPUT', 'ID kelas wajib dipilih.');
  }

  // 1. Verify class exists in D1
  const cls = await c.env.DB.prepare(
    'SELECT * FROM classes WHERE id = ?'
  )
    .bind(body.class_id)
    .first<SchoolClass>();

  if (!cls) {
    return errorResponse(c, 'NOT_FOUND', 'Kelas tidak ditemukan.', 404);
  }

  // Verify class belongs to student's school
  if (cls.school_id !== membership.school_id) {
    // If student has profile in cls.school_id, allow and align membership
    const stuInSchool = await c.env.DB.prepare(
      'SELECT * FROM student_profiles WHERE user_id = ? AND school_id = ?'
    )
      .bind(user.id, cls.school_id)
      .first<StudentProfile>();

    if (!stuInSchool) {
      return errorResponse(c, 'FORBIDDEN_TENANT', 'Kelas ini bukan milik sekolah Anda.', 403);
    }
  }

  const now = new Date().toISOString();

  // 2. Update class_id on student profile (Single class per student guarantee)
  await c.env.DB.prepare(
    'UPDATE student_profiles SET class_id = ?, updated_at = ? WHERE user_id = ?'
  )
    .bind(cls.id, now, user.id)
    .run();

  // 3. Fetch and return updated profile with class name
  const updatedProfile = await c.env.DB.prepare(`
    SELECT s.*, c.name as class_name
    FROM student_profiles s
    LEFT JOIN classes c ON c.id = s.class_id
    WHERE s.user_id = ?
    ORDER BY s.updated_at DESC
    LIMIT 1
  `)
    .bind(user.id)
    .first<StudentProfile & { class_name: string }>();

  return successResponse(c, updatedProfile);
});

// Student leaves active class (Sets class_id = NULL, preserves student account & school membership)
students.post('/leave-class', authMiddleware, schoolContextMiddleware(true), requireStudent, async (c) => {
  const user = c.get('user');
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'UPDATE student_profiles SET class_id = NULL, updated_at = ? WHERE user_id = ?'
  )
    .bind(now, user.id)
    .run();

  const updatedProfile = await c.env.DB.prepare(`
    SELECT s.*, NULL as class_name
    FROM student_profiles s
    WHERE s.user_id = ?
    ORDER BY s.updated_at DESC
    LIMIT 1
  `)
    .bind(user.id)
    .first<StudentProfile & { class_name: null }>();

  return successResponse(c, updatedProfile);
});

export default students;
