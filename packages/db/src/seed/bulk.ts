import type { Pool, PoolClient } from 'pg';

type Queryable = Pick<Pool | PoolClient, 'query'>;

/**
 * Inserts rows in chunks with one parameterised multi-row statement each.
 * Column and table names come from code, never from users.
 */
export async function bulkInsert(
  db: Queryable,
  table: string,
  columns: string[],
  rows: unknown[][],
  opts: { chunk?: number; onConflict?: string } = {},
): Promise<void> {
  if (!rows.length) return;
  const per = columns.length;
  const chunk = Math.max(1, Math.min(opts.chunk ?? 500, Math.floor(60000 / per)));
  for (let i = 0; i < rows.length; i += chunk) {
    const part = rows.slice(i, i + chunk);
    const params: unknown[] = [];
    const tuples = part.map((row) => {
      if (row.length !== per) throw new Error(`Row for ${table} has ${row.length} values, expected ${per}.`);
      return `(${row.map((v) => { params.push(v); return `$${params.length}`; }).join(',')})`;
    });
    await db.query(
      `insert into ${table} (${columns.map((c) => `"${c}"`).join(',')}) values ${tuples.join(',')} ${opts.onConflict ?? ''}`,
      params,
    );
  }
}
