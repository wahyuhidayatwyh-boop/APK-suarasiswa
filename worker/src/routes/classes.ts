import { Hono } from 'hono';
import { Env, Variables, SchoolClass, StudentProfile } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireCounselor } from '../middleware/authorization';

const classes = new Hono<{ Bindings: Env; Variables: Variables }>();

classes.use('*', authMiddleware, schoolContextMiddleware(true));

// Get all classes for the active school with student counts
classes.get('/', async (c) => {
  const membership = c.get('membership')!;

  const rows = await c.env.DB.prepare(`
    SELECT c.*, COUNT(s.id) as student_count
    FROM classes c
    LEFT JOIN student_profiles s ON s.class_id = c.id
    WHERE c.school_id = ? AND c.status = 'ACTIVE'
    GROUP BY c.id
    ORDER BY c.grade ASC, c.name ASC
  `)
    .bind(membership.school_id)
    .all<SchoolClass & { student_count: number }>();

  return successResponse(c, rows.results || []);
});

// Create new class (Counselor only)
classes.post('/', requireCounselor, async (c) => {
  const membership = c.get('membership')!;
  const body = await c.req.json<{
    name: string;
    grade: string;
    description?: string;
  }>();

  if (!body.name || !body.grade) {
    return errorResponse(c, 'INVALID_INPUT', 'Nama kelas dan tingkatan wajib diisi.');
  }

  const classId = `CLS_${crypto.randomUUID().substring(0, 6).toUpperCase()}`;
  const codePrefix = body.name.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  const shortPrefix = codePrefix.length >= 2 ? (codePrefix.length > 4 ? codePrefix.substring(0, 4) : codePrefix) : 'KLS';
  const randomSuffix = crypto.randomUUID().substring(0, 4).toUpperCase();
  const joinCode = `${shortPrefix}-${randomSuffix}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'INSERT INTO classes (id, school_id, name, grade, join_code, description, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(classId, membership.school_id, body.name, body.grade, joinCode, body.description || null, 'ACTIVE', now, now)
    .run();

  const newClass: SchoolClass & { student_count: number } = {
    id: classId,
    school_id: membership.school_id,
    name: body.name,
    grade: body.grade,
    join_code: joinCode,
    description: body.description || null,
    status: 'ACTIVE',
    created_at: now,
    updated_at: now,
    student_count: 0,
  };

  return successResponse(c, newClass);
});

// Update class
classes.patch('/:id', requireCounselor, async (c) => {
  const classId = c.req.param('id');
  const membership = c.get('membership')!;
  const body = await c.req.json<{
    name?: string;
    grade?: string;
    description?: string;
  }>();

  const now = new Date().toISOString();
  await c.env.DB.prepare(`
    UPDATE classes SET 
      name = COALESCE(?, name),
      grade = COALESCE(?, grade),
      description = COALESCE(?, description),
      updated_at = ?
    WHERE id = ? AND school_id = ?
  `)
    .bind(body.name || null, body.grade || null, body.description || null, now, classId, membership.school_id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM classes WHERE id = ? AND school_id = ?')
    .bind(classId, membership.school_id)
    .first<SchoolClass>();

  if (!updated) {
    return errorResponse(c, 'NOT_FOUND', 'Kelas tidak ditemukan.', 404);
  }

  return successResponse(c, updated);
});

// Archive/Delete class (Counselor only)
classes.delete('/:id', requireCounselor, async (c) => {
  const classId = c.req.param('id');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE classes SET status = ?, updated_at = ? WHERE id = ? AND school_id = ?')
    .bind('ARCHIVED', now, classId, membership.school_id)
    .run();

  // Detach students safely from archived class instead of deleting accounts
  await c.env.DB.prepare('UPDATE student_profiles SET class_id = NULL, updated_at = ? WHERE class_id = ? AND school_id = ?')
    .bind(now, classId, membership.school_id)
    .run();

  return successResponse(c, true);
});

// Remove student from class (Counselor only)
classes.delete('/:id/students/:studentId', requireCounselor, async (c) => {
  const classId = c.req.param('id');
  const studentId = c.req.param('studentId');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  await c.env.DB.prepare(`
    UPDATE student_profiles SET class_id = NULL, updated_at = ?
    WHERE (id = ? OR student_id = ? OR user_id = ?) AND class_id = ? AND school_id = ?
  `)
    .bind(now, studentId, studentId, studentId, classId, membership.school_id)
    .run();

  return successResponse(c, true);
});

// Get students in class
classes.get('/:id/students', requireCounselor, async (c) => {
  const classId = c.req.param('id');
  const membership = c.get('membership')!;

  const rows = await c.env.DB.prepare(`
    SELECT s.*, c.name as class_name
    FROM student_profiles s
    JOIN classes c ON c.id = s.class_id
    WHERE s.class_id = ? AND s.school_id = ?
    ORDER BY s.name ASC
  `)
    .bind(classId, membership.school_id)
    .all<StudentProfile & { class_name: string }>();

  return successResponse(c, rows.results || []);
});

// Regenerate class join code
classes.post('/:id/code', requireCounselor, async (c) => {
  const classId = c.req.param('id');
  const membership = c.get('membership')!;

  const cls = await c.env.DB.prepare('SELECT * FROM classes WHERE id = ? AND school_id = ?')
    .bind(classId, membership.school_id)
    .first<SchoolClass>();

  if (!cls) {
    return errorResponse(c, 'NOT_FOUND', 'Kelas tidak ditemukan.', 404);
  }

  const codePrefix = cls.name.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  const shortPrefix = codePrefix.length > 4 ? codePrefix.substring(0, 4) : codePrefix;
  const randomSuffix = crypto.randomUUID().substring(0, 4).toUpperCase();
  const newJoinCode = `${shortPrefix}-${randomSuffix}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE classes SET join_code = ?, updated_at = ? WHERE id = ?')
    .bind(newJoinCode, now, classId)
    .run();

  return successResponse(c, { join_code: newJoinCode });
});

export default classes;
