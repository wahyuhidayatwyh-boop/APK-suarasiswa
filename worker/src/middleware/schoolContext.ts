import { MiddlewareHandler } from 'hono';
import { Env, Variables, SchoolMembership, StudentProfile } from '../types';
import { errorResponse } from '../utils/response';

export const schoolContextMiddleware = (required = true): MiddlewareHandler<{ Bindings: Env; Variables: Variables }> => {
  return async (c, next) => {
    let schoolId = c.req.header('X-School-Id');
    const user = c.get('user');

    if (!user) {
      return errorResponse(c, 'UNAUTHORIZED', 'Sesi tidak valid.', 401);
    }

    let membership: SchoolMembership | null = null;

    // 1. If explicit X-School-Id provided, try to find active membership for that school
    if (schoolId) {
      membership = await c.env.DB.prepare(
        'SELECT * FROM school_memberships WHERE school_id = ? AND user_id = ? AND status = ?'
      )
        .bind(schoolId, user.id, 'ACTIVE')
        .first<SchoolMembership>();

      // Fallback: check student_profiles for this school
      if (!membership) {
        const studentProf = await c.env.DB.prepare(
          'SELECT * FROM student_profiles WHERE school_id = ? AND user_id = ?'
        )
          .bind(schoolId, user.id)
          .first<StudentProfile>();

        if (studentProf) {
          membership = {
            id: `MEM_${studentProf.id}`,
            school_id: studentProf.school_id,
            user_id: user.id,
            role: 'STUDENT',
            is_owner: 0,
            status: 'ACTIVE',
            joined_at: studentProf.created_at,
            created_at: studentProf.created_at,
            updated_at: studentProf.updated_at,
          };
        }
      }
    }

    // 2. Auto-fallback: resolve user's latest active school membership from D1
    if (!membership) {
      membership = await c.env.DB.prepare(
        'SELECT * FROM school_memberships WHERE user_id = ? AND status = ? ORDER BY joined_at DESC LIMIT 1'
      )
        .bind(user.id, 'ACTIVE')
        .first<SchoolMembership>();

      // Fallback to student_profiles if school_memberships not populated
      if (!membership) {
        const latestStudent = await c.env.DB.prepare(
          'SELECT * FROM student_profiles WHERE user_id = ? ORDER BY created_at DESC LIMIT 1'
        )
          .bind(user.id)
          .first<StudentProfile>();

        if (latestStudent) {
          membership = {
            id: `MEM_${latestStudent.id}`,
            school_id: latestStudent.school_id,
            user_id: user.id,
            role: 'STUDENT',
            is_owner: 0,
            status: 'ACTIVE',
            joined_at: latestStudent.created_at,
            created_at: latestStudent.created_at,
            updated_at: latestStudent.updated_at,
          };
        }
      }
    }

    if (!membership) {
      if (required) {
        return errorResponse(c, 'FORBIDDEN_TENANT', 'Anda belum terdaftar di ruang sekolah manapun.', 403);
      }
      return await next();
    }

    c.set('membership', membership);
    await next();
  };
};
