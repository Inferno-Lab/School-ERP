/** The dark pill that confirms something happened. It sits at the bottom of the frame and says it in one line. */
export function Toast({ text, tone = 'ok' }: { text: string; tone?: 'ok' | 'bad' }) {
  return (
    <div className="toast cs-toast" role="status">
      <span style={{ width: 30, height: 30, borderRadius: '50%', background: tone === 'ok' ? 'var(--g)' : 'var(--r)', display: 'grid', placeItems: 'center', flex: 'none' }}>
        <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
          <path className="i" d={tone === 'ok' ? 'M5 12.5l4.5 4.5L19 7.5' : 'M7 7l10 10M17 7 7 17'} style={{ stroke: '#fff', strokeWidth: 2.6 }}></path>
        </svg>
      </span>
      {text}
    </div>
  );
}
