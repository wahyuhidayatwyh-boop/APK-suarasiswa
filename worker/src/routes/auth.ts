import { Hono } from 'hono';
import { Env, Variables, User, SchoolMembership, School, CounselorProfile, StudentProfile } from '../types';
import { signJwt } from '../utils/security';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';

const auth = new Hono<{ Bindings: Env; Variables: Variables }>();

auth.post('/google', async (c) => {
  const body = await c.req.json<{
    google_uid: string;
    email: string;
    name: string;
    photo_url?: string;
  }>();

  if (!body.google_uid || !body.email || !body.name) {
    return errorResponse(c, 'INVALID_INPUT', 'Parameter google_uid, email, dan name wajib diisi.');
  }

  // 1. Check if user already exists
  let user = await c.env.DB.prepare('SELECT * FROM users WHERE google_uid = ?')
    .bind(body.google_uid)
    .first<User>();

  const now = new Date().toISOString();

  if (!user) {
    // Generate new User ID
    const userId = `USR_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
    await c.env.DB.prepare(
      'INSERT INTO users (id, google_uid, email, name, photo_url, auth_provider, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )
      .bind(userId, body.google_uid, body.email, body.name, body.photo_url || null, 'GOOGLE', 'ACTIVE', now, now)
      .run();

    user = {
      id: userId,
      google_uid: body.google_uid,
      email: body.email,
      name: body.name,
      photo_url: body.photo_url || null,
      auth_provider: 'GOOGLE',
      status: 'ACTIVE',
      created_at: now,
      updated_at: now,
    };
  } else {
    // Update name / photo if changed
    await c.env.DB.prepare('UPDATE users SET name = ?, photo_url = ?, updated_at = ? WHERE id = ?')
      .bind(body.name, body.photo_url || user.photo_url, now, user.id)
      .run();
  }

  // 2. Query memberships ordered by latest joined
  const memberships = await c.env.DB.prepare(
    'SELECT * FROM school_memberships WHERE user_id = ? AND status = ? ORDER BY joined_at DESC'
  )
    .bind(user.id, 'ACTIVE')
    .all<SchoolMembership>();

  let activeMembership: SchoolMembership | null = null;
  let activeSchool: School | null = null;
  let counselorProfile: CounselorProfile | null = null;
  let studentProfile: StudentProfile | null = null;

  if (memberships.results && memberships.results.length > 0) {
    activeMembership = memberships.results[0];

    // Fetch school
    activeSchool = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
      .bind(activeMembership.school_id)
      .first<School>();

    // Fetch profile
    if (activeMembership.role === 'COUNSELOR') {
      counselorProfile = await c.env.DB.prepare('SELECT * FROM counselor_profiles WHERE user_id = ? AND school_id = ?')
        .bind(user.id, activeMembership.school_id)
        .first<CounselorProfile>();
    } else {
      studentProfile = await c.env.DB.prepare(`
        SELECT sp.*, c.name as class_name
        FROM student_profiles sp
        LEFT JOIN classes c ON c.id = sp.class_id
        WHERE sp.user_id = ? AND sp.school_id = ?
      `)
        .bind(user.id, activeMembership.school_id)
        .first<StudentProfile & { class_name?: string }>();
    }
  } else {
    // Check fallback in student_profiles
    const fallbackStudent = await c.env.DB.prepare(`
      SELECT sp.*, c.name as class_name
      FROM student_profiles sp
      LEFT JOIN classes c ON c.id = sp.class_id
      WHERE sp.user_id = ?
      ORDER BY sp.created_at DESC
      LIMIT 1
    `)
      .bind(user.id)
      .first<StudentProfile & { class_name?: string }>();

    if (fallbackStudent) {
      studentProfile = fallbackStudent;
      activeSchool = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
        .bind(fallbackStudent.school_id)
        .first<School>();

      activeMembership = {
        id: `MEM_${fallbackStudent.id}`,
        school_id: fallbackStudent.school_id,
        user_id: user.id,
        role: 'STUDENT',
        is_owner: 0,
        status: 'ACTIVE',
        joined_at: fallbackStudent.created_at,
        created_at: fallbackStudent.created_at,
        updated_at: fallbackStudent.updated_at,
      };
    }
  }

  // 3. Issue JWT Token
  const secret = c.env.JWT_SECRET || 'suarasiswa_default_secret_fallback';
  const token = await signJwt(
    {
      sub: user.id,
      email: user.email,
      name: user.name,
    },
    secret
  );

  return successResponse(c, {
    token,
    user,
    membership: activeMembership,
    school: activeSchool,
    counselor_profile: counselorProfile,
    student_profile: studentProfile,
  });
});

auth.get('/me', authMiddleware, async (c) => {
  const user = c.get('user');
  const schoolId = c.req.header('X-School-Id');

  // Find membership
  let membership: SchoolMembership | null = null;
  let school: School | null = null;
  let counselorProfile: CounselorProfile | null = null;
  let studentProfile: StudentProfile | null = null;

  if (schoolId) {
    membership = await c.env.DB.prepare('SELECT * FROM school_memberships WHERE user_id = ? AND school_id = ? AND status = ?')
      .bind(user.id, schoolId, 'ACTIVE')
      .first<SchoolMembership>();

    if (!membership) {
      const stu = await c.env.DB.prepare('SELECT * FROM student_profiles WHERE user_id = ? AND school_id = ?')
        .bind(user.id, schoolId)
        .first<StudentProfile>();
      if (stu) {
        membership = {
          id: `MEM_${stu.id}`,
          school_id: stu.school_id,
          user_id: user.id,
          role: 'STUDENT',
          is_owner: 0,
          status: 'ACTIVE',
          joined_at: stu.created_at,
          created_at: stu.created_at,
          updated_at: stu.updated_at,
        };
      }
    }
  } else {
    // Default to latest active membership
    membership = await c.env.DB.prepare('SELECT * FROM school_memberships WHERE user_id = ? AND status = ? ORDER BY joined_at DESC LIMIT 1')
      .bind(user.id, 'ACTIVE')
      .first<SchoolMembership>();

    if (!membership) {
      const latestStu = await c.env.DB.prepare('SELECT * FROM student_profiles WHERE user_id = ? ORDER BY created_at DESC LIMIT 1')
        .bind(user.id)
        .first<StudentProfile>();
      if (latestStu) {
        membership = {
          id: `MEM_${latestStu.id}`,
          school_id: latestStu.school_id,
          user_id: user.id,
          role: 'STUDENT',
          is_owner: 0,
          status: 'ACTIVE',
          joined_at: latestStu.created_at,
          created_at: latestStu.created_at,
          updated_at: latestStu.updated_at,
        };
      }
    }
  }

  if (membership) {
    school = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
      .bind(membership.school_id)
      .first<School>();

    if (membership.role === 'COUNSELOR') {
      counselorProfile = await c.env.DB.prepare('SELECT * FROM counselor_profiles WHERE user_id = ? AND school_id = ?')
        .bind(user.id, membership.school_id)
        .first<CounselorProfile>();
    } else {
      studentProfile = await c.env.DB.prepare(`
        SELECT sp.*, c.name as class_name
        FROM student_profiles sp
        LEFT JOIN classes c ON c.id = sp.class_id
        WHERE sp.user_id = ? AND sp.school_id = ?
      `)
        .bind(user.id, membership.school_id)
        .first<StudentProfile & { class_name?: string }>();
    }
  }

  return successResponse(c, {
    user,
    membership,
    school,
    counselor_profile: counselorProfile,
    student_profile: studentProfile,
  });
});

auth.post('/logout', authMiddleware, async (c) => {
  return successResponse(c, { message: 'Berhasil keluar.' });
});

export default auth;
