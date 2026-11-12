import { Hono } from 'hono';
import { Env, Variables, Content } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';
import { requireCounselor } from '../middleware/authorization';

const contents = new Hono<{ Bindings: Env; Variables: Variables }>();

contents.use('*', authMiddleware, schoolContextMiddleware(true));

// Get contents
contents.get('/', async (c) => {
  const membership = c.get('membership')!;
  const type = c.req.query('type');
  const status = c.req.query('status') || (membership.role === 'STUDENT' ? 'published' : undefined);

  let query = 'SELECT * FROM contents WHERE school_id = ?';
  const params: any[] = [membership.school_id];

  if (type) {
    query += ' AND LOWER(type) = LOWER(?)';
    params.push(type);
  }

  if (status) {
    query += ' AND LOWER(status) = LOWER(?)';
    params.push(status);
  }

  query += ' ORDER BY created_at DESC';

  const rows = await c.env.DB.prepare(query).bind(...params).all<Content>();
  return successResponse(c, rows.results || []);
});

// Get content detail
contents.get('/:id', async (c) => {
  const id = c.req.param('id');
  const membership = c.get('membership')!;

  const content = await c.env.DB.prepare('SELECT * FROM contents WHERE id = ? AND school_id = ?')
    .bind(id, membership.school_id)
    .first<Content>();

  if (!content) {
    return errorResponse(c, 'NOT_FOUND', 'Konten tidak ditemukan.', 404);
  }

  // Increment view count
  await c.env.DB.prepare('UPDATE contents SET views_count = views_count + 1 WHERE id = ?')
    .bind(id)
    .run();

  content.views_count++;
  return successResponse(c, content);
});

// Create content (Counselor only)
contents.post('/', requireCounselor, async (c) => {
  const user = c.get('user');
  const membership = c.get('membership')!;
  const body = await c.req.json<{
    title: string;
    short_description: string;
    body?: string;
    image_url?: string;
    type: string; // article, poster, banner
    status?: string;
  }>();

  if (!body.title || !body.short_description || !body.type) {
    return errorResponse(c, 'INVALID_INPUT', 'Judul, deskripsi singkat, dan tipe konten wajib diisi.');
  }

  const contentId = `CNT_${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
  const now = new Date().toISOString();

  await c.env.DB.prepare(`
    INSERT INTO contents (
      id, school_id, author_id, title, short_description, body, image_url, type, status, views_count, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `)
    .bind(
      contentId,
      membership.school_id,
      user.id,
      body.title,
      body.short_description,
      body.body || null,
      body.image_url || null,
      body.type,
      body.status || 'published',
      0,
      now,
      now
    )
    .run();

  const newContent: Content = {
    id: contentId,
    school_id: membership.school_id,
    author_id: user.id,
    title: body.title,
    short_description: body.short_description,
    body: body.body || null,
    image_url: body.image_url || null,
    type: body.type,
    status: body.status || 'published',
    views_count: 0,
    created_at: now,
    updated_at: now,
  };

  return successResponse(c, newContent);
});

// Update content (Counselor only)
contents.patch('/:id', requireCounselor, async (c) => {
  const id = c.req.param('id');
  const membership = c.get('membership')!;
  const body = await c.req.json<{
    title?: string;
    short_description?: string;
    body?: string;
    image_url?: string;
    status?: string;
  }>();

  const now = new Date().toISOString();
  await c.env.DB.prepare(`
    UPDATE contents SET
      title = COALESCE(?, title),
      short_description = COALESCE(?, short_description),
      body = COALESCE(?, body),
      image_url = COALESCE(?, image_url),
      status = COALESCE(?, status),
      updated_at = ?
    WHERE id = ? AND school_id = ?
  `)
    .bind(
      body.title || null,
      body.short_description || null,
      body.body || null,
      body.image_url || null,
      body.status || null,
      now,
      id,
      membership.school_id
    )
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM contents WHERE id = ?')
    .bind(id)
    .first<Content>();

  return successResponse(c, updated);
});

// Delete content (Counselor only)
contents.delete('/:id', requireCounselor, async (c) => {
  const id = c.req.param('id');
  const membership = c.get('membership')!;

  await c.env.DB.prepare('DELETE FROM contents WHERE id = ? AND school_id = ?')
    .bind(id, membership.school_id)
    .run();

  return successResponse(c, true);
});

// Publish
contents.post('/:id/publish', requireCounselor, async (c) => {
  const id = c.req.param('id');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE contents SET status = ?, updated_at = ? WHERE id = ? AND school_id = ?')
    .bind('published', now, id, membership.school_id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM contents WHERE id = ?')
    .bind(id)
    .first<Content>();

  return successResponse(c, updated);
});

// Unpublish
contents.post('/:id/unpublish', requireCounselor, async (c) => {
  const id = c.req.param('id');
  const membership = c.get('membership')!;
  const now = new Date().toISOString();

  await c.env.DB.prepare('UPDATE contents SET status = ?, updated_at = ? WHERE id = ? AND school_id = ?')
    .bind('draft', now, id, membership.school_id)
    .run();

  const updated = await c.env.DB.prepare('SELECT * FROM contents WHERE id = ?')
    .bind(id)
    .first<Content>();

  return successResponse(c, updated);
});

export default contents;
