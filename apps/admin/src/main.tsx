import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from '@tanstack/react-router';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { readSupportHash } from './app/client';
import { resolveSchool } from './app/school';
import { makeRouter } from './router';
import { SchoolPicker } from './pages/status/SchoolPicker';

const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 15_000, retry: 1, refetchOnWindowFocus: false } } });
const { slug, basepath } = resolveSchool();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {slug ? (
      <QueryClientProvider client={queryClient}>
        <Boot slug={slug} basepath={basepath} />
      </QueryClientProvider>
    ) : <SchoolPicker />}
  </StrictMode>,
);

function Boot({ slug, basepath }: { slug: string; basepath: string }) {
  readSupportHash(slug);
  const router = useRouterOnce(slug, basepath);
  return <RouterProvider router={router} />;
}

let cached: ReturnType<typeof makeRouter> | null = null;
function useRouterOnce(slug: string, basepath: string) {
  cached ??= makeRouter(slug, basepath);
  return cached;
}
