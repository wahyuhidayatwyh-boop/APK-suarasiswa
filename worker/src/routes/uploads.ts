import { Hono } from 'hono';
import { Env, Variables } from '../types';
import { successResponse, errorResponse } from '../utils/response';
import { authMiddleware } from '../middleware/auth';
import { schoolContextMiddleware } from '../middleware/schoolContext';

const uploads = new Hono<{ Bindings: Env; Variables: Variables }>();

// Upload file to R2 (Authenticated)
uploads.post('/', authMiddleware, schoolContextMiddleware(true), async (c) => {
  const membership = c.get('membership')!;

  try {
    const formData = await c.req.formData();
    const file = formData.get('file') as File | null;

    if (!file) {
      return errorResponse(c, 'NO_FILE', 'File harus disertakan.');
    }

    // Validation: Max 10MB
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      return errorResponse(c, 'FILE_TOO_LARGE', 'Ukuran file tidak boleh melebihi 10MB.');
    }

    // Validation: Allowed MIME types
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
    if (!allowedTypes.includes(file.type)) {
      return errorResponse(c, 'INVALID_FILE_TYPE', 'Format file harus berupa JPG, PNG, WEBP, atau PDF.');
    }

    const fileExt = file.name.split('.').pop() || 'jpg';
    const key = `schools/${membership.school_id}/${crypto.randomUUID()}.${fileExt}`;

    if (c.env.STORAGE_BUCKET) {
      const buffer = await file.arrayBuffer();
      await c.env.STORAGE_BUCKET.put(key, buffer, {
        httpMetadata: { contentType: file.type },
      });

      return successResponse(c, {
        key,
        url: `/api/uploads/attachments/${encodeURIComponent(key)}`,
        file_name: file.name,
        file_type: file.type,
        file_size: file.size,
      });
    } else {
      // Fallback: Persistent Remote D1 Database storage
      const buffer = await file.arrayBuffer();
      const bytes = new Uint8Array(buffer);
      let binary = '';
      const len = bytes.byteLength;
      for (let i = 0; i < len; i++) {
        binary += String.fromCharCode(bytes[i]);
      }
      const base64Data = btoa(binary);

      await c.env.DB.prepare(`
        INSERT INTO storage_files (id, school_id, file_name, mime_type, file_size, file_data, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `)
        .bind(
          key,
          membership.school_id,
          file.name,
          file.type,
          file.size,
          base64Data,
          new Date().toISOString()
        )
        .run();

      return successResponse(c, {
        key,
        url: `/api/uploads/attachments/${encodeURIComponent(key)}`,
        file_name: file.name,
        file_type: file.type,
        file_size: file.size,
      });
    }
  } catch (err: any) {
    return errorResponse(c, 'UPLOAD_FAILED', `Gagal mengunggah file: ${err.message || 'error'}`);
  }
});

// Stream attachment from R2 or D1 database
uploads.get('/attachments/:key', async (c) => {
  const key = decodeURIComponent(c.req.param('key'));

  if (c.env.STORAGE_BUCKET) {
    try {
      const object = await c.env.STORAGE_BUCKET.get(key);
      if (object) {
        const headers = new Headers();
        object.writeHttpMetadata(headers);
        headers.set('etag', object.httpEtag);
        headers.set('Access-Control-Allow-Origin', '*');
        headers.set('Cache-Control', 'public, max-age=31536000');
        return new Response(object.body as any, { headers });
      }
    } catch (_) {}
  }

  // Check persistent D1 storage
  const record = await c.env.DB.prepare('SELECT * FROM storage_files WHERE id = ?')
    .bind(key)
    .first<{ file_name: string; mime_type: string; file_data: string }>();

  if (!record || !record.file_data) {
    return errorResponse(c, 'NOT_FOUND', 'File tidak ditemukan.', 404);
  }

  const binaryString = atob(record.file_data);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  return new Response(bytes.buffer, {
    headers: {
      'Content-Type': record.mime_type || 'image/jpeg',
      'Content-Length': bytes.length.toString(),
      'Access-Control-Allow-Origin': '*',
      'Cache-Control': 'public, max-age=31536000',
    },
  });
});

export default uploads;
