import { Context } from 'hono';

export function successResponse(c: Context, data: unknown, status = 200) {
  return c.json(
    {
      success: true,
      data,
    },
    status as any
  );
}

export function errorResponse(c: Context, code: string, message: string, status = 400) {
  return c.json(
    {
      success: false,
      error: {
        code,
        message,
      },
    },
    status as any
  );
}
