import { Inject, Injectable } from '@nestjs/common';
import { newId } from '@edunest/db';
import { resolveConfig, validateSettingsChanges } from '@edunest/config-engine';
import type { AuditRow, EffectiveConfig, SettingsDoc, SettingsPatch } from '@edunest/contracts';
import type { Registry } from '@edunest/tenancy';
import { ApiError } from '@edunest/nest-kit';
import { REGISTRY, type TenantCtx } from '../tenancy/tenant.js';

/** Sends messages. Only the sandbox exists today: it files them in the console's inbox instead of sending them. */
@Injectable()
export class Messenger {
  constructor(@Inject(REGISTRY) private readonly registry: Registry) {}

  async send(t: TenantCtx, m: { channel: 'sms' | 'email' | 'whatsapp' | 'push'; to: string; subject?: string; body: string }): Promise<void> {
    await this.registry.pool.query(
      'insert into sandbox_messages (id, school_slug, channel, to_addr, subject, body) values ($1,$2,$3,$4,$5,$6)',
      [newId('msg'), t.info.slug, m.channel, m.to, m.subject ?? null, m.body],
    );
  }

  async sendMany(t: TenantCtx, list: { channel: 'sms' | 'email' | 'whatsapp' | 'push'; to: string; subject?: string; body: string }[]): Promise<void> {
    for (const m of list) await this.send(t, m);
  }
}

@Injectable()
export class AuditService {
  async record(t: TenantCtx, e: { actorId?: string | null; actorName?: string; action: string; entity: string; entityId?: string; detail?: Record<string, unknown> }): Promise<void> {
    await t.pool.query(
      'insert into audit_log (id, actor_id, actor_name, action, entity, entity_id, detail) values ($1,$2,$3,$4,$5,$6,$7)',
      [newId('aud'), e.actorId ?? null, e.actorName ?? 'System', e.action, e.entity, e.entityId ?? null, JSON.stringify(e.detail ?? {})],
    );
  }

  async list(t: TenantCtx, limit = 50): Promise<AuditRow[]> {
    const { rows } = await t.pool.query<{ id: string; at: Date; actor_name: string; action: string; entity: string; detail: Record<string, unknown> }>(
      'select id, at, actor_name, action, entity, detail from audit_log order by at desc limit $1', [limit]);
    return rows.map((r) => ({ id: r.id, at: r.at.toISOString(), actor: r.actor_name, action: r.action, entity: r.entity, detail: Object.entries(r.detail).map(([k, v]) => `${k}: ${String(v)}`).join(' · ') }));
  }
}

@Injectable()
export class SettingsService {
  private readonly cache = new Map<string, { at: number; doc: SettingsDoc }>();

  constructor(private readonly audit: AuditService) {}

  async doc(t: TenantCtx): Promise<SettingsDoc> {
    const hit = this.cache.get(t.info.slug);
    if (hit && Date.now() - hit.at < 5000) return hit.doc;
    const [rows, meta] = await Promise.all([
      t.pool.query<{ key: string; value: unknown; updated_at: Date }>('select key, value, updated_at from settings'),
      t.pool.query<{ value: number }>("select value from meta where key = 'settings.version'"),
    ]);
    const values: Record<string, unknown> = {};
    let updated: Date | null = null;
    for (const r of rows.rows) {
      values[r.key] = r.value;
      if (!updated || r.updated_at > updated) updated = r.updated_at;
    }
    const doc: SettingsDoc = { version: meta.rows[0]?.value ?? 1, values, locked: t.info.entitlement.locks, updatedAt: updated?.toISOString() ?? null };
    this.cache.set(t.info.slug, { at: Date.now(), doc });
    return doc;
  }

  async value<T>(t: TenantCtx, key: string, fallback: T): Promise<T> {
    const v = (await this.doc(t)).values[key];
    return (v === undefined ? fallback : v) as T;
  }

  async patch(t: TenantCtx, user: { id: string; name: string }, patch: SettingsPatch): Promise<SettingsDoc> {
    const current = await this.doc(t);
    if (patch.expectedVersion !== undefined && patch.expectedVersion !== current.version) {
      throw new ApiError('conflict', 'Someone else changed these settings a moment ago. Reload to see their changes.');
    }
    const checked = validateSettingsChanges(patch.changes, current.locked);
    if (!checked.ok) {
      const fields = Object.fromEntries(checked.problems.map((p) => [p.key, p.message]));
      throw new ApiError('validation', checked.problems[0]!.message, { fields });
    }
    const client = await t.pool.connect();
    try {
      await client.query('begin');
      for (const [k, v] of Object.entries(checked.values)) {
        await client.query(
          'insert into settings (key, value, updated_by, updated_at) values ($1,$2,$3,now()) on conflict (key) do update set value = excluded.value, updated_by = excluded.updated_by, updated_at = now()',
          [k, JSON.stringify(v), user.id],
        );
      }
      await client.query("update meta set value = to_jsonb((value)::int + 1) where key = 'settings.version'");
      await client.query('commit');
    } catch (err) {
      await client.query('rollback').catch(() => undefined);
      throw err;
    } finally {
      client.release();
    }
    this.cache.delete(t.info.slug);
    await this.audit.record(t, { actorId: user.id, actorName: user.name, action: 'settings.changed', entity: 'settings', detail: { keys: Object.keys(checked.values).join(', ') } });
    return this.doc(t);
  }

  async effective(t: TenantCtx, permissions?: string[]): Promise<EffectiveConfig> {
    return resolveConfig({ settings: await this.doc(t), entitlement: t.info.entitlement, audience: permissions ? { permissions } : undefined });
  }
}
