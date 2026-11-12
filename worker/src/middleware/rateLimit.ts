import { MiddlewareHandler } from 'hono';
import { Env, Variables } from '../types';
import { errorResponse } from '../utils/response';

// In-memory rate limiting map for edge worker instance
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();

export const rateLimit = (limit = 60, windowSeconds = 60): MiddlewareHandler<{ Bindings: Env; Variables: Variables }> => {
  return async (c, next) => {
    const ip = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || '127.0.0.1';
    const now = Date.now();
    const key = `${ip}:${c.req.path}`;

    const record = rateLimitMap.get(key);
    if (!record || now > record.resetTime) {
      rateLimitMap.set(key, { count: 1, resetTime: now + windowSeconds * 1000 });
    } else {
      record.count++;
      if (record.count > limit) {
        return errorResponse(c, 'RATE_LIMIT_EXCEEDED', 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.', 429);
      }
    }

    // Cleanup old records occasionally
    if (rateLimitMap.size > 1000) {
      for (const [k, v] of rateLimitMap.entries()) {
        if (now > v.resetTime) rateLimitMap.delete(k);
      }
    }

    await next();
  };
};
