import { MiddlewareHandler } from 'hono';
import { Env, Variables } from '../types';
import { errorResponse } from '../utils/response';

export const requireCounselor: MiddlewareHandler<{ Bindings: Env; Variables: Variables }> = async (c, next) => {
  const membership = c.get('membership');
  if (!membership || membership.role !== 'COUNSELOR') {
    return errorResponse(c, 'FORBIDDEN_ROLE', 'Aksi ini hanya dapat dilakukan oleh Guru BK.', 403);
  }
  await next();
};

export const requireOwner: MiddlewareHandler<{ Bindings: Env; Variables: Variables }> = async (c, next) => {
  const membership = c.get('membership');
  if (!membership || membership.role !== 'COUNSELOR' || membership.is_owner !== 1) {
    return errorResponse(c, 'FORBIDDEN_OWNER', 'Aksi ini hanya dapat dilakukan oleh Guru BK pemilik sekolah.', 403);
  }
  await next();
};

export const requireStudent: MiddlewareHandler<{ Bindings: Env; Variables: Variables }> = async (c, next) => {
  const membership = c.get('membership');
  if (!membership || membership.role !== 'STUDENT') {
    return errorResponse(c, 'FORBIDDEN_ROLE', 'Aksi ini hanya dapat dilakukan oleh Siswa.', 403);
  }
  await next();
};
