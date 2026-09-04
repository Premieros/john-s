import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.cwd());
const source = (path: string) => readFileSync(resolve(root, path), 'utf8');

describe('V2 POS kitchen-send UI contract', () => {
  it('uses the canonical granular permission and RPC', () => {
    const page = source('src/v2/pages/V2PosPage.tsx');
    const registry = source('src/v2/core/capabilityRegistry.ts');

    expect(page).toContain("useV2Can");
    expect(page).toContain("v2Can('pos.send_kitchen')");
    expect(page).toContain("supabase.rpc('send_to_kitchen'");
    expect(page).toContain('p_order_id: saved.orderId');
    expect(page).toContain('data-testid="v2-pos-send-kitchen"');
    expect(registry).toContain("permission: 'pos.send_kitchen'");
    expect(registry).not.toContain("permission: 'pos.kitchen.send'");
  });

  it('persists the current cart before the kitchen RPC is called', () => {
    const page = source('src/v2/pages/V2PosPage.tsx');
    const sendBlockStart = page.indexOf('const sendToKitchen = async () =>');
    const saveCall = page.indexOf('const saved = await saveOrder();', sendBlockStart);
    const kitchenCall = page.indexOf("supabase.rpc('send_to_kitchen'", sendBlockStart);

    expect(sendBlockStart).toBeGreaterThanOrEqual(0);
    expect(saveCall).toBeGreaterThan(sendBlockStart);
    expect(kitchenCall).toBeGreaterThan(saveCall);
  });
});
