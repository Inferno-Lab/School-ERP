import { useEffect, useRef, useState } from 'react';

export type ToastState = { text: string; tone: 'ok' | 'bad' } | null;

/** `say("Saved")` shows the toast for a few seconds; the timer is cleared if the page goes away first. */
export function useToast(): { toast: ToastState; say: (text: string, tone?: 'ok' | 'bad') => void } {
  const [toast, setToast] = useState<ToastState>(null);
  const t = useRef<ReturnType<typeof setTimeout>>(undefined);
  useEffect(() => () => clearTimeout(t.current), []);
  return { toast, say: (text, tone = 'ok') => { clearTimeout(t.current); setToast({ text, tone }); t.current = setTimeout(() => setToast(null), 4200); } };
}
