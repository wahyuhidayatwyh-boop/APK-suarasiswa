import { Hono } from 'hono';
import { Env, Variables, School, SchoolMembership, CounselorProfile } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireCounselor } from '../middleware/authorization';

const schools = new Hono<{ Bindings: Env; Variables: Variables }>();

// Find school by code (public query used during join onboarding)
schools.get('/find', async (c) => {
  const code = c.req.query('code');
  if (!code) {
    return errorResponse(c, 'INVALID_CODE', 'Kode sekolah harus disertakan.');
  }

  const school = await c.env.DB.prepare(
    'SELECT id, name, school_code, logo_url, address, description FROM schools WHERE school_code = ? AND status = ?'
  )
    .bind(code.toUpperCase().trim(), 'ACTIVE')
    .first<Partial<School>>();

  if (!school) {
    return errorResponse(c, 'NOT_FOUND', 'Sekolah dengan kode tersebut tidak ditemukan.', 404);
  }

  return successResponse(c, school);
});

// Counselor creates new school space (Self-service onboarding)
schools.post('/', authMiddleware, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    school_name: string;
    counselor_name: string;
    nip?: string;
    phone?: string;
    address?: string;
    description?: string;
  }>();

  if (!body.school_name || !body.counselor_name) {
    return errorResponse(c, 'INVALID_INPUT', 'Nama sekolah dan nama Guru BK wajib diisi.');
  }

  // 0. Idempotency: Check if user already owns or belongs to an active school
  const existingMembership = await c.env.DB.prepare(
    'SELECT * FROM school_memberships WHERE user_id = ? AND status = ?'
  )
    .bind(user.id, 'ACTIVE')
    .first<SchoolMembership>();

  if (existingMembership) {
    const existingSchool = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
      .bind(existingMembership.school_id)
      .first<School>();
    const existingProfile = await c.env.DB.prepare('SELECT * FROM counselor_profiles WHERE user_id = ? AND school_id = ?')
      .bind(user.id, existingMembership.school_id)
      .first<CounselorProfile>();

    return successResponse(c, {
      school: existingSchool,
      membership: existingMembership,
      counselor_profile: existingProfile,
    });
  }

  const schoolId = `SCH_${crypto.randomUUID().substring(0, 6).toUpperCase()}`;
  const prefix = body.school_name.length >= 3
    ? body.school_name.substring(0, 3).toUpperCase().replace(/[^A-Z]/g, 'S')
    : 'SCH';
  const randomSuffix = crypto.randomUUID().substring(0, 4).toUpperCase();
  const schoolCode = `${prefix}-${randomSuffix}`;
  const now = new Date().toISOString();

  // 1. Create school
  await c.env.DB.prepare(
    'INSERT INTO schools (id, name, school_code, address, description, owner_user_id, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(schoolId, body.school_name, schoolCode, body.address || null, body.description || null, user.id, 'ACTIVE', now, now)
    .run();

  // 2. Create Owner Membership
  const membershipId = `MEM_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO school_memberships (id, school_id, user_id, role, is_owner, status, joined_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(membershipId, schoolId, user.id, 'COUNSELOR', 1, 'ACTIVE', now, now, now)
    .run();

  // 3. Create Counselor Profile
  const profileId = `PRF_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO counselor_profiles (id, user_id, school_id, name, employee_id, phone, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(profileId, user.id, schoolId, body.counselor_name, body.nip || null, body.phone || null, now, now)
    .run();

  // 4. No starter classes - school starts clean with no dummy classes

  // 5. Create default audit log
  try {
    await c.env.DB.prepare(
      'INSERT INTO audit_logs (id, school_id, user_id, action, entity_type, entity_id, metadata, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    )
      .bind(crypto.randomUUID(), schoolId, user.id, 'SCHOOL_CREATED', 'school', schoolId, JSON.stringify({ name: body.school_name }), now)
      .run();
  } catch (auditErr) {
    console.warn('[CREATE_SCHOOL] Audit log warning:', auditErr);
  }

  const createdSchool: School = {
    id: schoolId,
    name: body.school_name,
    school_code: schoolCode,
    address: body.address || null,
    description: body.description || null,
    owner_user_id: user.id,
    status: 'ACTIVE',
    created_at: now,
    updated_at: now,
  };

  const createdMembership: SchoolMembership = {
    id: membershipId,
    school_id: schoolId,
    user_id: user.id,
    role: 'COUNSELOR',
    is_owner: 1,
    status: 'ACTIVE',
    joined_at: now,
    created_at: now,
    updated_at: now,
  };

  const createdProfile: CounselorProfile = {
    id: profileId,
    user_id: user.id,
    school_id: schoolId,
    name: body.counselor_name,
    employee_id: body.nip || null,
    phone: body.phone || null,
    created_at: now,
    updated_at: now,
  };

  return successResponse(c, {
    school: createdSchool,
    membership: createdMembership,
    counselor_profile: createdProfile,
  });
});

// Get current school details
schools.get('/current', authMiddleware, schoolContextMiddleware(true), async (c) => {
  const membership = c.get('membership')!;
  const school = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
    .bind(membership.school_id)
    .first<School>();

  if (!school) {
    return errorResponse(c, 'NOT_FOUND', 'Sekolah tidak ditemukan.', 404);
  }

  return successResponse(c, school);
});

// Update school details (counselor only)
schools.patch('/current', authMiddleware, schoolContextMiddleware(true), requireCounselor, async (c) => {
  const membership = c.get('membership')!;
  const body = await c.req.json<{
    name?: string;
    address?: string;
    description?: string;
    logo_url?: string;
  }>();

  const now = new Date().toISOString();
  await c.env.DB.prepare(
    `UPDATE schools SET 
      name = COALESCE(?, name),
      address = COALESCE(?, address),
      description = COALESCE(?, description),
      logo_url = COALESCE(?, logo_url),
      updated_at = ?
     WHERE id = ?`
  )
    .bind(body.name || null, body.address || null, body.description || null, body.logo_url || null, now, membership.school_id)
    .run();

  const updatedSchool = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
    .bind(membership.school_id)
    .first<School>();

  return successResponse(c, updatedSchool);
});

// Counselor leaves school
schools.post('/leave', authMiddleware, schoolContextMiddleware(true), requireCounselor, async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  // Deactivate school membership
  await c.env.DB.prepare('UPDATE school_memberships SET status = ?, updated_at = ? WHERE user_id = ? AND school_id = ?')
    .bind('INACTIVE', now, user.id, membership.school_id)
    .run();

  // Remove counselor profile from this school
  await c.env.DB.prepare('DELETE FROM counselor_profiles WHERE user_id = ? AND school_id = ?')
    .bind(user.id, membership.school_id)
    .run();

  return successResponse(c, true);
});

export default schools;
