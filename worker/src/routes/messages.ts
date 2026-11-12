import { Hono } from 'hono';
import { Env, Variables, Report, ReportMessage } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';

const messages = new Hono<{ Bindings: Env; Variables: Variables }>();

messages.use('*', authMiddleware, schoolContextMiddleware(true));

// Get chat messages for a report
messages.get('/:id/messages', async (c) => {
  const reportId = c.req.param('id');
  const user = c.get('user');
  const membership = c.get('membership')!;

  const report = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ? AND school_id = ?')
    .bind(reportId, membership.school_id)
    .first<Report>();

  if (!report) {
    return errorResponse(c, 'NOT_FOUND', 'Laporan tidak ditemukan.', 404);
  }

  // Student can only see their own report chat
  if (membership.role === 'STUDENT' && report.student_id !== user.id) {
    return errorResponse(c, 'FORBIDDEN', 'Anda tidak memiliki akses ke percakapan laporan ini.', 403);
  }

  const rows = await c.env.DB.prepare(`
    SELECT m.*, u.name as sender_name, u.photo_url as sender_photo,
           COALESCE(sm.role, 'STUDENT') as sender_role,
           CASE WHEN sm.role = 'COUNSELOR' THEN 1 ELSE 0 END as is_counselor
    FROM report_messages m
    JOIN users u ON u.id = m.sender_user_id
    LEFT JOIN school_memberships sm ON sm.user_id = m.sender_user_id AND sm.school_id = m.school_id
    WHERE m.report_id = ? AND m.school_id = ?
    ORDER BY m.created_at ASC
  `)
    .bind(reportId, membership.school_id)
    .all();

  return successResponse(c, rows.results || []);
});

// Send message in report chat
messages.post('/:id/messages', async (c) => {
  const reportId = c.req.param('id');
  const user = c.get('user');
  const membership = c.get('membership')!;

  const body = await c.req.json<{ message: string; attachment_url?: string }>();
  if (!body.message || !body.message.trim()) {
    return errorResponse(c, 'INVALID_INPUT', 'Pesan tidak boleh kosong.');
  }

  const report = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ? AND school_id = ?')
    .bind(reportId, membership.school_id)
    .first<Report>();

  if (!report) {
    return errorResponse(c, 'NOT_FOUND', 'Laporan tidak ditemukan.', 404);
  }

  if (membership.role === 'STUDENT' && report.student_id !== user.id) {
    return errorResponse(c, 'FORBIDDEN', 'Anda tidak memiliki akses ke percakapan laporan ini.', 403);
  }

  const messageId = `MSG_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(
    'INSERT INTO report_messages (id, report_id, school_id, sender_user_id, message, attachment_url, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(messageId, reportId, membership.school_id, user.id, body.message.trim(), body.attachment_url || null, now)
    .run();

  // Send notification to recipient
  try {
    if (membership.role === 'COUNSELOR') {
      // Notify student
      await c.env.DB.prepare(
        'INSERT INTO notifications (id, user_id, school_id, title, body, type, reference_id, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)'
      )
        .bind(
          crypto.randomUUID(),
          report.student_id,
          membership.school_id,
          'Pesan Baru dari Guru BK',
          body.message.trim().length > 80 ? body.message.trim().substring(0, 80) + '...' : body.message.trim(),
          'new_message',
          reportId,
          now
        )
        .run();
    } else {
      // Notify counselors
      const counselors = await c.env.DB.prepare(
        "SELECT user_id FROM school_memberships WHERE school_id = ? AND role = 'COUNSELOR' AND status = 'ACTIVE'"
      ).bind(membership.school_id).all<{ user_id: string }>();

      if (counselors.results) {
        for (const cons of counselors.results) {
          await c.env.DB.prepare(
            'INSERT INTO notifications (id, user_id, school_id, title, body, type, reference_id, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)'
          )
            .bind(
              crypto.randomUUID(),
              cons.user_id,
              membership.school_id,
              `Pesan Siswa #${report.report_code}`,
              body.message.trim().length > 80 ? body.message.trim().substring(0, 80) + '...' : body.message.trim(),
              'new_message',
              reportId,
              now
            )
            .run();
        }
      }
    }
  } catch (notifErr) {
    console.error('Failed to notify message recipient:', notifErr);
  }

  const newMessage = {
    id: messageId,
    report_id: reportId,
    school_id: membership.school_id,
    sender_user_id: user.id,
    sender_name: user.name,
    sender_role: membership.role,
    message: body.message.trim(),
    attachment_url: body.attachment_url || null,
    is_counselor: membership.role === 'COUNSELOR',
    created_at: now,
  };

  return successResponse(c, newMessage);
});

export default messages;
