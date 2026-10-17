import type { LoginController } from './useLogin';
import { useLogin } from './useLogin';
import { LoginView } from './login.view';
import { useTheme } from '../theme';

/** The sign-in page for the admin and the console. The controller says where credentials and codes are checked. */
export function LoginPage({ controller }: { controller: LoginController }) {
  const { cls } = useTheme();
  const v = useLogin(controller, cls);
  return <LoginView v={v} />;
}
export type { LoginController };
