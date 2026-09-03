import type { KitchenSendItem } from '../types';

const PRINT_AGENT_URL = 'http://127.0.0.1:17654';
const PRINT_TIMEOUT_MS = 1800;

export interface LocalKitchenPrintContext {
  orderNumber?: string | null;
  tableName?: string | null;
  orderType?: string | null;
  guestCount?: number | null;
  isAr: boolean;
}

function safeText(value: unknown): string {
  return Array.from(String(value ?? ''))
    .filter((ch) => ch === '\n' || ch === '\r' || ch === '\t' || ch >= ' ')
    .join('')
    .trim();
}

function modifierNames(item: KitchenSendItem): string[] {
  return (item.modifiers || [])
    .map((m) => safeText(m.option_name || m.option_name_en))
    .filter(Boolean);
}

export function groupKitchenItemsByStation(items: KitchenSendItem[]): Record<string, KitchenSendItem[]> {
  const groups: Record<string, KitchenSendItem[]> = {};
  for (const item of items) {
    const station = safeText(item.station_code || 'main') || 'main';
    (groups[station] ||= []).push(item);
  }
  return groups;
}

export function buildStationTicketText(
  station: string,
  items: KitchenSendItem[],
  ctx: LocalKitchenPrintContext,
): string {
  const lines: string[] = [];
  const ar = ctx.isAr;
  lines.push('================================');
  lines.push(ar ? `محطة: ${station}` : `Station: ${station}`);
  if (ctx.orderNumber) lines.push(`${ar ? 'طلب' : 'Order'}: ${safeText(ctx.orderNumber)}`);
  if (ctx.tableName) lines.push(`${ar ? 'طاولة' : 'Table'}: ${safeText(ctx.tableName)}`);
  if (ctx.orderType) lines.push(`${ar ? 'النوع' : 'Type'}: ${safeText(ctx.orderType)}`);
  if (ctx.guestCount) lines.push(`${ar ? 'ضيوف' : 'Guests'}: ${ctx.guestCount}`);
  lines.push(new Date().toLocaleString(ar ? 'ar-EG' : 'en-US'));
  lines.push('--------------------------------');

  for (const item of items) {
    const qty = Number(item.quantity || 0);
    lines.push(`${qty} x ${safeText(item.product_name || '—')}`);
    for (const modifier of modifierNames(item)) lines.push(`  + ${modifier}`);
    if (item.notes?.trim()) lines.push(`  * ${safeText(item.notes)}`);
    lines.push('');
  }

  lines.push('================================');
  lines.push('');
  lines.push('');
  return lines.join('\r\n');
}

async function fetchWithTimeout(input: string, init?: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = window.setTimeout(() => controller.abort(), PRINT_TIMEOUT_MS);
  try {
    return await fetch(input, { ...init, signal: controller.signal, cache: 'no-store' });
  } finally {
    window.clearTimeout(timer);
  }
}

/**
 * Print each authoritative kitchen station group through the local Windows agent.
 * Returns true only when every station was routed and accepted. A false result
 * tells the POS to preserve its existing browser-print fallback.
 */
export async function printKitchenStationsLocally(
  items: KitchenSendItem[],
  ctx: LocalKitchenPrintContext,
): Promise<boolean> {
  if (typeof window === 'undefined' || items.length === 0) return false;
  try {
    const health = await fetchWithTimeout(`${PRINT_AGENT_URL}/health`);
    if (!health.ok) return false;
    const groups = groupKitchenItemsByStation(items);
    for (const [station, stationItems] of Object.entries(groups)) {
      const response = await fetchWithTimeout(`${PRINT_AGENT_URL}/print`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          station,
          text: buildStationTicketText(station, stationItems, ctx),
        }),
      });
      if (!response.ok) return false;
      const result = await response.json() as { success?: boolean };
      if (!result.success) return false;
    }
    return true;
  } catch {
    return false;
  }
}

/**
 * Existing POS code immediately opens one browser ticket after send_to_kitchen.
 * When every station was already printed locally, suppress exactly that one
 * popup and restore window.open immediately. If no popup happens, auto-restore.
 */
export function suppressNextKitchenBrowserPopup(): void {
  if (typeof window === 'undefined') return;
  const original = window.open.bind(window);
  let restored = false;
  const restore = () => {
    if (restored) return;
    restored = true;
    window.open = original as typeof window.open;
  };
  window.open = (() => {
    restore();
    return null;
  }) as typeof window.open;
  window.setTimeout(restore, 1200);
}
