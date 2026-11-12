import { MiddlewareHandler } from 'hono';
import { Env, Variables, User } from '../types';
import { verifyJwt } from '../utils/security';
import { errorResponse } from '../utils/response';

export const authMiddleware: MiddlewareHandler<{ Bindings: Env; Variables: Variables }> = async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(c, 'UNAUTHORIZED', 'Sesi tidak valid atau belum masuk. Silakan login kembali.', 401);
  }

  const token = authHeader.substring(7).trim();
  const secret = c.env.JWT_SECRET || 'suarasiswa_default_secret_fallback';
  const payload = await verifyJwt(token, secret);

  if (!payload || !payload.sub) {
    return errorResponse(c, 'UNAUTHORIZED', 'Token otentikasi tidak valid atau sudah kadaluarsa.', 401);
  }

  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(payload.sub).first<User>();

  if (!user) {
    return errorResponse(c, 'USER_NOT_FOUND', 'Pengguna tidak ditemukan dalam sistem.', 401);
  }

  if (user.status !== 'ACTIVE') {
    return errorResponse(c, 'USER_INACTIVE', 'Akun Anda dinonaktifkan.', 403);
  }

  c.set('user', user);
  await next();
};
