import type { PosPanelId } from '../topbar/PosTopBar';
import type { ActiveCategory } from '../orders/ActiveOrdersDrawer';

interface PosBottomNavProps {
  disabled?: boolean;
  panel: PosPanelId;
  category: ActiveCategory;
  counts: { activeOrders: number; deliveryOrders: number; takeawayOrders: number; occupiedTables: number };
  onOpenOrders: (c: ActiveCategory) => void;
  onOpenTables: () => void;
}

/**
 * Legacy bottom navigation has been retired.
 * POS navigation now belongs to the landing/header workflow so the selling
 * workspace is not permanently reduced by a fixed footer bar.
 */
export function PosBottomNav(props: PosBottomNavProps) {
  void props;
  return null;
}
