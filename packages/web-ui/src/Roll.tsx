import type { CSSProperties } from 'react';
import type { Digit } from './digits';

const STRIP = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/** A number whose digits roll to their new value when it changes. */
export function Roll({ digits }: { digits: Digit[] }) {
  return (
    <span className="roll">
      {digits.map((d, i) =>
        d.isD ? (
          <span className="dg" key={i}>
            <span className="strip" style={{ transform: `translateY(-${d.y}em)` } as CSSProperties}>
              {STRIP.map((n) => (
                <span key={n}>{n}</span>
              ))}
            </span>
          </span>
        ) : (
          <span key={i}>{d.c}</span>
        ),
      )}
    </span>
  );
}
