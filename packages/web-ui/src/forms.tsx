import { useId, useState, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes } from 'react';

/** A counter that flips between two classes, so the same error can vibrate again each time it is hit. */
export function useShake(): { cls: string; hit: () => void } {
  const [n, setN] = useState(0);
  return { cls: n ? `shk${n}` : '', hit: () => setN((x) => (x === 1 ? 2 : 1)) };
}

const WARN = 'M12 3.5l9 15.5H3zM12 10v4M12 16.5h.01';

export function ErrorLine({ children }: { children: ReactNode }) {
  return (
    <div className="emsg" role="alert">
      <svg viewBox="0 0 24 24" aria-hidden="true"><path className="i" d={WARN}></path></svg>
      {children}
    </div>
  );
}

interface FieldProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
  label: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
  hint?: string;
  icon?: string;
}

/** A labelled input. The error turns it red, makes it vibrate, and says what to do. */
export function Field({ label, value, onChange, error, hint, icon, ...rest }: FieldProps) {
  const id = useId();
  return (
    <div className="fld">
      <label htmlFor={id}>{label}</label>
      <div className={`inp ${error ? 'err shake' : ''}`}>
        {icon && <svg viewBox="0 0 24 24" aria-hidden="true"><path className="i" d={icon}></path></svg>}
        <input id={id} value={value} onChange={(e) => onChange(e.target.value)} aria-invalid={!!error} aria-describedby={error || hint ? `${id}-m` : undefined} {...rest} />
      </div>
      {error ? <div id={`${id}-m`}><ErrorLine>{error}</ErrorLine></div> : hint ? <div id={`${id}-m`} className="help">{hint}</div> : null}
    </div>
  );
}

interface SelectProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, 'onChange'> {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
  error?: string;
}

export function SelectField({ label, value, onChange, options, error, ...rest }: SelectProps) {
  const id = useId();
  return (
    <div className="fld">
      <label htmlFor={id}>{label}</label>
      <div className={`inp ${error ? 'err shake' : ''}`}>
        <select id={id} value={value} onChange={(e) => onChange(e.target.value)} aria-invalid={!!error} style={{ flex: 1, minWidth: 0, border: 0, outline: 0, background: 'none', font: '600 15px var(--fb)', color: 'var(--ink)' }} {...rest}>
          {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
      </div>
      {error && <ErrorLine>{error}</ErrorLine>}
    </div>
  );
}
