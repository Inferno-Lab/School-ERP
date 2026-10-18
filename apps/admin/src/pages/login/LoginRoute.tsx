import { useQuery } from '@tanstack/react-query';
import { useNavigate, useRouteContext } from '@tanstack/react-router';
import { LoginPage } from '@edunest/web-ui';
import { session } from '../../app/client';

/** Signs in to the school named in the address: password first, then the code. */
export function LoginRoute() {
  const { slug, client } = useRouteContext({ from: '__root__' });
  const navigate = useNavigate();
  const brand = useQuery({ queryKey: ['brand', slug], queryFn: client.api.brand, staleTime: 5 * 60_000, retry: false });
  if (brand.isError) return <NoSchool message={(brand.error as Error).message} />;
  const b = brand.data;
  return (
    <LoginPage
      controller={{
        product: 'admin', schoolName: b?.name ?? 'EduNest', shortName: b?.shortName ?? 'school', demoMode: !!b?.demoMode, goName: 'the dashboard',
        initialEmail: (() => { try { return localStorage.getItem(`edunest.admin.${slug}.email`) ?? ''; } catch { return ''; } })(),
        submitCredentials: async (email, password) => {
          const res = await client.api.login({ identifier: email, password });
          try { localStorage.setItem(`edunest.admin.${slug}.email`, email); } catch { /* ignore */ }
          if (res.step === 'otp') return res.challenge;
          session.write(slug, { accessToken: res.tokens.accessToken, refreshToken: res.tokens.refreshToken, user: res.tokens.user });
          return null;
        },
        submitCode: async (challengeId, code) => {
          const t = await client.api.verify({ challengeId, code });
          session.write(slug, { accessToken: t.accessToken, refreshToken: t.refreshToken, user: t.user });
          return t.user.name;
        },
        enter: () => void navigate({ to: '/' }),
      }}
    />
  );
}

function NoSchool({ message }: { message: string }) {
  return <div style={{ font: '600 16px var(--fb, system-ui)', padding: 40, textAlign: 'center' }}>{message}</div>;
}
