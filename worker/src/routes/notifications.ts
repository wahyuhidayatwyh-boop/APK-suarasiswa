import { Hono } from 'hono';
import { Env, Variables, AppNotification } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';

const notifications = new Hono<{ Bindings: Env; Variables: Variables }>();

notifications.use('*', authMiddleware, schoolContextMiddleware(true));

// Get user notifications in current school (with auto-cleanup > 2 weeks)
notifications.get('/', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  // 1. Automatic cleanup: delete notifications older than 2 weeks based on created_at
  try {
    await c.env.DB.prepare(`
      DELETE FROM notifications 
      WHERE user_id = ? AND created_at < datetime('now', '-14 days')
    `)
      .bind(user.id)
      .run();
  } catch (err) {
    console.error('Failed to cleanup old notifications:', err);
  }

  // 2. Fetch active, non-deleted notifications
  const rows = await c.env.DB.prepare(`
    SELECT * FROM notifications 
    WHERE user_id = ? AND school_id = ? AND deleted_at IS NULL
    ORDER BY created_at DESC
  `)
    .bind(user.id, membership.school_id)
    .all<AppNotification>();

  return successResponse(c, rows.results || []);
});

// Mark notification read
notifications.patch('/:id/read', async (c) => {
  const id = c.req.param('id');
  const user = c.get('user');

  await c.env.DB.prepare('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?')
    .bind(id, user.id)
    .run();

  return successResponse(c, true);
});

// Mark all notifications read
notifications.post('/read-all', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  await c.env.DB.prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ? AND school_id = ? AND deleted_at IS NULL')
    .bind(user.id, membership.school_id)
    .run();

  return successResponse(c, true);
});

// Delete single notification (Persistent)
notifications.delete('/:id', async (c) => {
  const id = c.req.param('id');
  const user = c.get('user');
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE notifications SET deleted_at = ? WHERE id = ? AND user_id = ?')
    .bind(now, id, user.id)
    .run();

  return successResponse(c, true);
});

// Delete all notifications for user in current school (Persistent)
notifications.delete('/', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE notifications SET deleted_at = ? WHERE user_id = ? AND school_id = ?')
    .bind(now, user.id, membership.school_id)
    .run();

  return successResponse(c, true);
});

export default notifications;
