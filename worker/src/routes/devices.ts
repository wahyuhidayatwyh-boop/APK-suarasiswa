import { Hono } from 'hono';
import { Env, Variables } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';

const devices = new Hono<{ Bindings: Env; Variables: Variables }>();

devices.use('*', authMiddleware, schoolContextMiddleware(true));

// Register FCM Device Token
devices.post('/register', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const body = await c.req.json<{ fcm_token: string; platform?: string }>();

  if (!body.fcm_token) {
    return errorResponse(c, 'INVALID_INPUT', 'fcm_token wajib diisi.');
  }

  const tokenId = `DEV_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(`
    INSERT INTO device_tokens (id, user_id, school_id, fcm_token, platform, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, fcm_token) DO UPDATE SET updated_at = ?
  `)
    .bind(tokenId, user.id, membership.school_id, body.fcm_token, body.platform || 'android', now, now, now)
    .run();

  return successResponse(c, { registered: true });
});

// Remove FCM Device Token
devices.delete('/:token', async (c) => {
  const token = c.req.param('token');
  const user = c.get('user');

  await c.env.DB.prepare('DELETE FROM device_tokens WHERE user_id = ? AND fcm_token = ?')
    .bind(user.id, token)
    .run();

  return successResponse(c, { unregistered: true });
});

export default devices;
