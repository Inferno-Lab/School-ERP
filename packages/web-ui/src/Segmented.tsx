import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';

export interface SegmentOption<T extends string> {
  value: T;
  label: ReactNode;
  count?: number | string;
}

/** Tabs and view switches: a pill track with a white knob that glides under the chosen option. */
export function Segmented<T extends string>({ value, onChange, options, label }: { value: T; onChange: (v: T) => void; options: SegmentOption<T>[]; label: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const [knob, setKnob] = useState({ x: 4, w: 0 });
  useLayoutEffect(() => {
    const measure = () => {
      const b = ref.current?.querySelector<HTMLElement>('button.on');
      if (b) setKnob({ x: b.offsetLeft, w: b.offsetWidth });
    };
    measure();
    const ro = new ResizeObserver(measure);
    if (ref.current) ro.observe(ref.current);
    return () => ro.disconnect();
  }, [value, options.length]);
  return (
    <div className="seg" ref={ref} role="tablist" aria-label={label}>
      <span className="kn" style={{ transform: `translateX(${knob.x}px)`, width: knob.w }} aria-hidden="true"></span>
      {options.map((o) => (
        <button key={o.value} type="button" role="tab" aria-selected={o.value === value} className={o.value === value ? 'on' : ''} onClick={() => onChange(o.value)}>
          {o.label}
          {o.count != null && <span className="chip" style={{ height: 22, padding: '0 8px' }}>{o.count}</span>}
        </button>
      ))}
    </div>
  );
}
