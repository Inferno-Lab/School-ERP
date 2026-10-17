import type { PipeTransform } from '@nestjs/common';
import type { z } from 'zod';
import { ApiError } from './errors.js';

/** Validates a body or query with a zod schema and returns the parsed (defaulted, trimmed) value. */
export class ZodPipe<S extends z.ZodType> implements PipeTransform<unknown, z.output<S>> {
  constructor(private readonly schema: S) {}

  transform(value: unknown): z.output<S> {
    const res = this.schema.safeParse(value ?? {});
    if (res.success) return res.data;
    const fields: Record<string, string> = {};
    for (const issue of res.error.issues) fields[issue.path.join('.') || '_'] ??= issue.message;
    throw new ApiError('validation', Object.values(fields)[0] ?? 'Check the highlighted fields.', { fields });
  }
}
