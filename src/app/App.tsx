import { AppProviders } from './providers';
import { AppRoutes } from './routes';
import { FinancialVisibilityAdminControl } from '@/features/admin/components/FinancialVisibilityAdminControl';

export default function App() {
  return (
    <AppProviders>
      <AppRoutes />
      <FinancialVisibilityAdminControl />
    </AppProviders>
  );
}
