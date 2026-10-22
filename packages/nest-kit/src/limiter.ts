import { ApiError } from './errors.js';

/** At most `limit` calls per `windowMs` for a key. Enough to blunt guessing on one server. */
export class Limiter {
  private readonly hits = new Map<string, number[]>();
  constructor(private readonly limit: number, private readonly windowMs: number) {}
  check(key: string): void {
    const now = Date.now();
    const recent = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    if (recent.length >= this.limit) {
      const retryAfter = Math.ceil((this.windowMs - (now - recent[0]!)) / 1000);
      throw new ApiError('rate_limited', 'Too many tries from this device. Wait a moment and try again.', { retryAfter });
    }
    recent.push(now);
    this.hits.set(key, recent);
    if (this.hits.size > 5000) for (const [k, v] of this.hits) if (!v.some((t) => now - t < this.windowMs)) this.hits.delete(k);
  }
}
