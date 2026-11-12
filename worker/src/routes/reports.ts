import { Hono } from 'hono';
import { Env, Variables, Report, User } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireCounselor } from '../middleware/authorization';

const reports = new Hono<{ Bindings: Env; Variables: Variables }>();

reports.use('*', authMiddleware, schoolContextMiddleware(true));

// Get reports list with role-based isolation
reports.get('/', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  let rows;
  if (membership.role === 'COUNSELOR') {
    // Counselor sees all reports in this school
    rows = await c.env.DB.prepare(`
      SELECT r.*, COALESCE(sp.name, u.name) as student_name, c.name as class_name, u.name as reporter_name,
             (SELECT GROUP_CONCAT(file_url, '|||') FROM report_attachments WHERE report_id = r.id) as attachments_concat
      FROM reports r
      LEFT JOIN student_profiles sp ON sp.user_id = r.student_id AND sp.school_id = r.school_id
      LEFT JOIN classes c ON c.id = sp.class_id
      LEFT JOIN users u ON u.id = r.student_id
      WHERE r.school_id = ?
        AND COALESCE(r.deleted_by_counselor, 0) = 0
        AND NOT (r.status IN ('resolved', 'closed') AND COALESCE(r.resolved_at, r.updated_at) < datetime('now', '-21 days'))
      ORDER BY r.created_at DESC
    `)
      .bind(membership.school_id)
      .all<Report & { student_name: string; class_name: string; reporter_name: string; attachments_concat?: string }>();
    
    if (rows.results) {
      for (const r of rows.results) {
        (r as any).attachment_urls = r.attachments_concat ? r.attachments_concat.split('|||').filter(Boolean) : [];
      }
    }
  } else {
    // Student ONLY sees their own reports in this school
    rows = await c.env.DB.prepare(`
      SELECT r.*, sp.name as student_name, c.name as class_name,
             (SELECT GROUP_CONCAT(file_url, '|||') FROM report_attachments WHERE report_id = r.id) as attachments_concat
      FROM reports r
      LEFT JOIN student_profiles sp ON sp.user_id = r.student_id AND sp.school_id = r.school_id
      LEFT JOIN classes c ON c.id = sp.class_id
      WHERE r.school_id = ? AND r.student_id = ?
        AND COALESCE(r.deleted_by_student, 0) = 0
        AND NOT (r.status IN ('resolved', 'closed') AND COALESCE(r.resolved_at, r.updated_at) < datetime('now', '-21 days'))
      ORDER BY r.created_at DESC
    `)
      .bind(membership.school_id, user.id)
      .all<Report & { student_name: string; class_name: string; attachments_concat?: string }>();

    // Strip internal_notes for student privacy & format attachments
    if (rows.results) {
      rows.results.forEach((r) => {
        delete r.internal_notes;
        (r as any).attachment_urls = r.attachments_concat ? r.attachments_concat.split('|||').filter(Boolean) : [];
      });
    }
  }

  return successResponse(c, rows.results || []);
});

// Create new report
reports.post('/', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;

  const body = await c.req.json<{
    type?: string;
    category?: string;
    description?: string;
    incident_date?: string;
    incident_location?: string;
    reporter_type?: string;
    priority?: string;
    attachment_urls?: string[];
  }>();

  if (!body.category || !body.description || !body.incident_date || !body.incident_location) {
    return errorResponse(c, 'INVALID_INPUT', 'Kategori, deskripsi, tanggal, dan lokasi kejadian wajib diisi.');
  }

  const rawType = (body.type || 'bullying').toLowerCase();
  const validTypes = ['bullying', 'kritik_saran', 'aspirasi', 'grievance', 'suggestion'];
  const reportType = validTypes.includes(rawType) ? rawType : 'bullying';

  const rawPriority = (body.priority || 'normal').toLowerCase();
  const priority = (rawPriority === 'urgent' || rawPriority === 'mendesak') ? 'urgent' 
    : (rawPriority === 'tinggi' || rawPriority === 'high') ? 'high' 
    : 'medium';

  const rawReporter = (body.reporter_type || 'KORBAN').toLowerCase();
  const reporterType = rawReporter.includes('saksi') || rawReporter === 'witness' ? 'witness' 
    : rawReporter.includes('anonim') || rawReporter === 'anonymous' ? 'anonymous' 
    : 'victim';

  const now = new Date();
  const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
  const randomSuffix = crypto.randomUUID().substring(0, 4).toUpperCase();
  const reportCode = `LAP-${dateStr}-${randomSuffix}`;
  const reportId = `REP_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  const nowIso = now.toISOString();

  // 1. Insert report
  await c.env.DB.prepare(`
    INSERT INTO reports (
      id, school_id, student_id, report_code, type, category, description,
      incident_date, incident_location, reporter_type, priority, status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `)
    .bind(
      reportId,
      membership.school_id,
      user.id,
      reportCode,
      reportType,
      body.category,
      body.description,
      body.incident_date,
      body.incident_location,
      reporterType,
      priority,
      'pending',
      nowIso,
      nowIso
    )
    .run();

  // 2. Insert initial timeline item
  await c.env.DB.prepare(
    'INSERT INTO report_timeline (id, report_id, school_id, title, description, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  )
    .bind(crypto.randomUUID(), reportId, membership.school_id, 'Laporan Dibuat', 'Laporan berhasil disampaikan dan menunggu tinjauan Guru BK.', nowIso)
    .run();

  // 3. Attachments if any
  if (body.attachment_urls && body.attachment_urls.length > 0) {
    for (const url of body.attachment_urls) {
      await c.env.DB.prepare(
        'INSERT INTO report_attachments (id, report_id, school_id, file_url, created_at) VALUES (?, ?, ?, ?, ?)'
      )
        .bind(crypto.randomUUID(), reportId, membership.school_id, url, nowIso)
        .run();
    }
  }

  // 4. Audit Log
  await c.env.DB.prepare(
    'INSERT INTO audit_logs (id, school_id, user_id, action, entity_type, entity_id, metadata, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  )
    .bind(crypto.randomUUID(), membership.school_id, user.id, 'REPORT_CREATED', 'report', reportId, JSON.stringify({ code: reportCode, type: reportType }), nowIso)
    .run();

  // 5. Notify all counselors in this school
  try {
    const counselors = await c.env.DB.prepare(
      "SELECT user_id FROM school_memberships WHERE school_id = ? AND role = 'COUNSELOR' AND status = 'ACTIVE'"
    ).bind(membership.school_id).all<{ user_id: string }>();

    if (counselors.results && counselors.results.length > 0) {
      for (const cons of counselors.results) {
        await c.env.DB.prepare(
          'INSERT INTO notifications (id, user_id, school_id, title, body, type, reference_id, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)'
        )
          .bind(
            crypto.randomUUID(),
            cons.user_id,
            membership.school_id,
            'Laporan Siswa Baru',
            `Laporan baru #${reportCode} (${body.category}) masuk dan memerlukan penanganan.`,
            'report_update',
            reportId,
            nowIso
          )
          .run();
      }
    }
  } catch (notifErr) {
    console.error('Failed to notify counselors:', notifErr);
  }

  const createdReport: Report & { attachment_urls?: string[] } = {
    id: reportId,
    school_id: membership.school_id,
    student_id: user.id,
    report_code: reportCode,
    type: reportType,
    category: body.category,
    description: body.description,
    incident_date: body.incident_date,
    incident_location: body.incident_location,
    reporter_type: reporterType,
    priority: priority,
    status: 'pending',
    attachment_urls: body.attachment_urls || [],
    created_at: nowIso,
    updated_at: nowIso,
  };

  return successResponse(c, createdReport);
});

// Get report detail with strict privacy check
reports.get('/:id', async (c) => {
  const reportId = c.req.param('id');
  const user = c.get('user');
  const membership = c.get('membership')!;

  const report = await c.env.DB.prepare(`
    SELECT r.*, COALESCE(sp.name, u.name) as student_name, c.name as class_name
    FROM reports r
    LEFT JOIN student_profiles sp ON sp.user_id = r.student_id AND sp.school_id = r.school_id
    LEFT JOIN classes c ON c.id = sp.class_id
    LEFT JOIN users u ON u.id = r.student_id
    WHERE r.id = ? AND r.school_id = ?
  `)
    .bind(reportId, membership.school_id)
    .first<Report & { student_name?: string; class_name?: string }>();

  if (!report) {
    return errorResponse(c, 'NOT_FOUND', 'Laporan tidak ditemukan di sekolah ini.', 404);
  }

  // Authorization check: Counselor can view, or Student if they are the author
  if (membership.role === 'STUDENT' && report.student_id !== user.id) {
    return errorResponse(c, 'FORBIDDEN', 'Anda tidak memiliki hak untuk melihat laporan ini.', 403);
  }

  // Fetch real uploaded attachments
  const attachments = await c.env.DB.prepare(
    'SELECT file_url FROM report_attachments WHERE report_id = ?'
  )
    .bind(reportId)
    .all<{ file_url: string }>();

  (report as any).attachment_urls = attachments.results?.map((a) => a.file_url) || [];

  // Student cannot see counselor internal notes
  if (membership.role === 'STUDENT') {
    delete report.internal_notes;
  }

  return successResponse(c, report);
});

// Update report status (Counselor only)
reports.patch('/:id/status', requireCounselor, async (c) => {
  const reportId = c.req.param('id');
  const membership = c.get('membership')!;
  const body = await c.req.json<{ status: string; note?: string }>();

  if (!body.status) {
    return errorResponse(c, 'INVALID_INPUT', 'Status laporan wajib disertakan.');
  }

  const now = new Date().toISOString();
  const resolvedAt = (body.status === 'resolved' || body.status === 'rejected') ? now : null;

  await c.env.DB.prepare(`
    UPDATE reports SET 
      status = ?,
      resolved_at = COALESCE(?, resolved_at),
      updated_at = ?
    WHERE id = ? AND school_id = ?
  `)
    .bind(body.status, resolvedAt, now, reportId, membership.school_id)
    .run();

  // Add timeline entry
  const statusLabels: Record<string, string> = {
    pending: 'Menunggu Verifikasi',
    investigating: 'Sedang Diselidiki Guru BK',
    action_taken: 'Tindakan Dilakukan',
    resolved: 'Laporan Telah Diselesaikan',
    rejected: 'Laporan Ditutup / Tidak Valid',
  };

  await c.env.DB.prepare(
    'INSERT INTO report_timeline (id, report_id, school_id, title, description, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  )
    .bind(
      crypto.randomUUID(),
      reportId,
      membership.school_id,
      statusLabels[body.status] || `Status Diperbarui: ${body.status}`,
      body.note || `Status laporan diubah menjadi ${body.status}`,
      now
    )
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ?')
    .bind(reportId)
    .first<Report>();

  // Notify student about the status update
  if (updated) {
    try {
      const statusText = statusLabels[body.status] || body.status;
      await c.env.DB.prepare(
        'INSERT INTO notifications (id, user_id, school_id, title, body, type, reference_id, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)'
      )
        .bind(
          crypto.randomUUID(),
          updated.student_id,
          membership.school_id,
          'Status Laporan Diperbarui',
          `Laporan #${updated.report_code} Anda kini berstatus: ${statusText}.`,
          'report_update',
          reportId,
          now
        )
        .run();
    } catch (e) {
      console.error('Failed to notify student:', e);
    }
  }

  return successResponse(c, updated);
});

// Update report priority (Counselor only)
reports.patch('/:id/priority', requireCounselor, async (c) => {
  const reportId = c.req.param('id');
  const membership = c.get('membership')!;
  const body = await c.req.json<{ priority: string }>();

  if (!body.priority) {
    return errorResponse(c, 'INVALID_INPUT', 'Prioritas wajib disertakan.');
  }

  const now = new Date().toISOString();
  await c.env.DB.prepare('UPDATE reports SET priority = ?, updated_at = ? WHERE id = ? AND school_id = ?')
    .bind(body.priority, now, reportId, membership.school_id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ?')
    .bind(reportId)
    .first<Report>();

  return successResponse(c, updated);
});

// Update internal notes / followups (Counselor only - private notes hidden from student)
reports.patch('/:id/followups', requireCounselor, async (c) => {
  const reportId = c.req.param('id');
  const membership = c.get('membership')!;
  const body = await c.req.json<{ internal_notes: string }>();

  const now = new Date().toISOString();
  await c.env.DB.prepare('UPDATE reports SET internal_notes = ?, updated_at = ? WHERE id = ? AND school_id = ?')
    .bind(body.internal_notes || '', now, reportId, membership.school_id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ?')
    .bind(reportId)
    .first<Report>();

  return successResponse(c, updated);
});

// Get report timeline
reports.get('/:id/timeline', async (c) => {
  const reportId = c.req.param('id');
  const user = c.get('user');
  const membership = c.get('membership')!;

  const report = await c.env.DB.prepare('SELECT * FROM reports WHERE id = ? AND school_id = ?')
    .bind(reportId, membership.school_id)
    .first<Report>();

  if (!report) {
    return errorResponse(c, 'NOT_FOUND', 'Laporan tidak ditemukan.', 404);
  }

  if (membership.role === 'STUDENT' && report.student_id !== user.id) {
    return errorResponse(c, 'FORBIDDEN', 'Anda tidak memiliki hak untuk melihat timeline ini.', 403);
  }

  const rows = await c.env.DB.prepare(
    'SELECT * FROM report_timeline WHERE report_id = ? ORDER BY created_at ASC'
  )
    .bind(reportId)
    .all();

  return successResponse(c, rows.results || []);
});

// Delete single report from history (Soft delete for audit retention)
reports.delete('/:id', async (c) => {
  const reportId = c.req.param('id');
  const user = c.get('user');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  if (membership.role === 'COUNSELOR') {
    await c.env.DB.prepare('UPDATE reports SET deleted_by_counselor = 1, updated_at = ? WHERE id = ? AND school_id = ?')
      .bind(now, reportId, membership.school_id)
      .run();
  } else {
    await c.env.DB.prepare('UPDATE reports SET deleted_by_student = 1, updated_at = ? WHERE id = ? AND student_id = ? AND school_id = ?')
      .bind(now, reportId, user.id, membership.school_id)
      .run();
  }

  return successResponse(c, true);
});

// Delete all reports from history for current user/school (Soft delete)
reports.delete('/', async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  if (membership.role === 'COUNSELOR') {
    await c.env.DB.prepare('UPDATE reports SET deleted_by_counselor = 1, updated_at = ? WHERE school_id = ?')
      .bind(now, membership.school_id)
      .run();
  } else {
    await c.env.DB.prepare('UPDATE reports SET deleted_by_student = 1, updated_at = ? WHERE student_id = ? AND school_id = ?')
      .bind(now, user.id, membership.school_id)
      .run();
  }

  return successResponse(c, true);
});

export default reports;
