import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { Env, Variables } from './types';
import { rateLimit } from './middleware/rateLimit';
import { errorResponse } from './utils/response';

import authRoutes from './routes/auth';
import schoolRoutes from './routes/schools';
import classRoutes from './routes/classes';
import studentRoutes from './routes/students';
import counselorRoutes from './routes/counselors';
import reportRoutes from './routes/reports';
import messageRoutes from './routes/messages';
import contentRoutes from './routes/contents';
import uploadRoutes from './routes/uploads';
import notificationRoutes from './routes/notifications';
import deviceRoutes from './routes/devices';

const app = new Hono<{ Bindings: Env; Variables: Variables }>();

// 1. Global Middleware: CORS & Rate Limit
app.use('*', async (c, next) => {
  const corsMiddleware = cors({
    origin: c.env.ALLOWED_ORIGIN || '*',
    allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-School-Id'],
    exposeHeaders: ['Content-Length'],
    maxAge: 86400,
  });
  return corsMiddleware(c, next);
});

app.use('*', rateLimit(120, 60)); // 120 reqs / min per client

// 2. Health check route
app.get('/health', (c) => {
  return c.json({ status: 'ok', service: 'suara-siswa-backend', timestamp: new Date().toISOString() });
});

// 3. Mount API Routes
app.route('/api/auth', authRoutes);
app.route('/api/schools', schoolRoutes);
app.route('/api/classes', classRoutes);
app.route('/api/students', studentRoutes);
app.route('/api/counselors', counselorRoutes);
app.route('/api/reports', reportRoutes);
app.route('/api/reports', messageRoutes); // Mounts /api/reports/:id/messages
app.route('/api/contents', contentRoutes);
app.route('/api/uploads', uploadRoutes);
app.route('/api/notifications', notificationRoutes);
app.route('/api/devices', deviceRoutes);

// 4. Global 404 handler
app.notFound((c) => {
  return errorResponse(c, 'NOT_FOUND', `Rute ${c.req.method} ${c.req.path} tidak ditemukan.`, 404);
});

// 5. Global Error Handler
app.onError((err, c) => {
  console.error('Unhandled Worker Error:', err);
  return errorResponse(c, 'INTERNAL_SERVER_ERROR', `Backend Error: ${err.message}`, 500);
});

export default app;
