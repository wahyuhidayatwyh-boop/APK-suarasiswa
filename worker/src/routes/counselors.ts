import { Hono } from 'hono';
import { Env, Variables, CounselorProfile, School, SchoolMembership } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireCounselor, requireOwner } from '../middleware/authorization';

const counselors = new Hono<{ Bindings: Env; Variables: Variables }>();

// Get counselors in the active school (accessible by any verified school member)
counselors.get('/', authMiddleware, schoolContextMiddleware(true), async (c) => {
  const membership = c.get('membership')!;

  const rows = await c.env.DB.prepare(`
    SELECT cp.*, u.email, sm.is_owner
    FROM counselor_profiles cp
    JOIN users u ON u.id = cp.user_id
    JOIN school_memberships sm ON sm.user_id = cp.user_id AND sm.school_id = cp.school_id
    WHERE cp.school_id = ?
    ORDER BY sm.is_owner DESC, cp.name ASC
  `)
    .bind(membership.school_id)
    .all<CounselorProfile & { email: string; is_owner: number }>();

  return successResponse(c, rows.results || []);
});

// Get active invites for school (Counselors only)
counselors.get('/invites', authMiddleware, schoolContextMiddleware(true), requireCounselor, async (c) => {
  const membership = c.get('membership')!;

  const rows = await c.env.DB.prepare(`
    SELECT ci.id, ci.code_hash as code, ci.status, ci.expires_at, ci.created_at, u.name as created_by_name
    FROM counselor_invites ci
    LEFT JOIN users u ON u.id = ci.created_by
    WHERE ci.school_id = ? AND ci.status = 'PENDING'
    ORDER BY ci.created_at DESC
  `)
    .bind(membership.school_id)
    .all();

  return successResponse(c, rows.results || []);
});

// Create Counselor Invitation Code (Owner only)
counselors.post('/invites', authMiddleware, schoolContextMiddleware(true), requireOwner, async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  const inviteId = `INV_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  const randomCode = `BK-${crypto.randomUUID().substring(0, 6).toUpperCase()}`;
  const expiresAt = new Date(Date.now() + 7 * 86400 * 1000).toISOString(); // 7 days
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'INSERT INTO counselor_invites (id, school_id, code_hash, created_by, expires_at, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(inviteId, membership.school_id, randomCode, user.id, expiresAt, 'PENDING', now)
    .run();

  await c.env.DB.prepare(
    'INSERT INTO audit_logs (id, school_id, user_id, action, entity_type, entity_id, metadata, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(crypto.randomUUID(), membership.school_id, user.id, 'COUNSELOR_INVITED', 'invite', inviteId, JSON.stringify({ code: randomCode }), now)
    .run();

  return successResponse(c, {
    invite_code: randomCode,
    expires_at: expiresAt,
  });
});

// Counselor joins school via invitation code
counselors.post('/join', authMiddleware, async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    invite_code: string;
    name: string;
    nip?: string;
    phone?: string;
  }>();

  if (!body.invite_code || !body.name) {
    return errorResponse(c, 'INVALID_INPUT', 'Kode undangan dan nama Guru BK wajib diisi.');
  }

  // 1. Verify invitation
  const invite = await c.env.DB.prepare(
    'SELECT * FROM counselor_invites WHERE code_hash = ? AND status = ?'
  )
    .bind(body.invite_code.trim().toUpperCase(), 'PENDING')
    .first<{ id: string; school_id: string; expires_at: string }>();

  if (!invite) {
    return errorResponse(c, 'INVALID_INVITE', 'Kode undangan tidak valid atau sudah digunakan.', 404);
  }

  const now = new Date();
  if (new Date(invite.expires_at) < now) {
    return errorResponse(c, 'INVITE_EXPIRED', 'Kode undangan sudah kadaluarsa.', 400);
  }

  // 2. Check if already member
  const existingMembership = await c.env.DB.prepare(
    'SELECT * FROM school_memberships WHERE school_id = ? AND user_id = ?'
  )
    .bind(invite.school_id, user.id)
    .first<SchoolMembership>();

  if (existingMembership) {
    return errorResponse(c, 'ALREADY_JOINED', 'Akun Anda sudah menjadi anggota di sekolah ini.', 400);
  }

  const nowIso = now.toISOString();

  // 3. Mark invite as used
  await c.env.DB.prepare('UPDATE counselor_invites SET status = ?, used_at = ? WHERE id = ?')
    .bind('USED', nowIso, invite.id)
    .run();

  // 4. Create Membership
  const membershipId = `MEM_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO school_memberships (id, school_id, user_id, role, is_owner, status, joined_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(membershipId, invite.school_id, user.id, 'COUNSELOR', 0, 'ACTIVE', nowIso, nowIso, nowIso)
    .run();

  // 5. Create Profile
  const profileId = `PRF_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  await c.env.DB.prepare(
    'INSERT INTO counselor_profiles (id, user_id, school_id, name, employee_id, phone, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(profileId, user.id, invite.school_id, body.name.trim(), body.nip || null, body.phone || null, nowIso, nowIso)
    .run();

  const school = await c.env.DB.prepare('SELECT * FROM schools WHERE id = ?')
    .bind(invite.school_id)
    .first<School>();

  return successResponse(c, {
    school,
    membership: {
      id: membershipId,
      school_id: invite.school_id,
      user_id: user.id,
      role: 'COUNSELOR',
      is_owner: 0,
      status: 'ACTIVE',
      joined_at: nowIso,
      created_at: nowIso,
      updated_at: nowIso,
    },
    counselor_profile: {
      id: profileId,
      user_id: user.id,
      school_id: invite.school_id,
      name: body.name.trim(),
      employee_id: body.nip || null,
      phone: body.phone || null,
      created_at: nowIso,
      updated_at: nowIso,
    },
  });
});

export default counselors;
