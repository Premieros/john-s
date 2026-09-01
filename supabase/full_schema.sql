-- ============================================================================
-- PREMIER POS & ERP - COMPLETE DATABASE SCHEMA & RPCS
-- Consolidated Build Script generated on 2026-08-29T20:19:16.346Z
-- Contains all 112 migrations in canonical order (001 -> latest)
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ----------------------------------------------------------------------------
-- MIGRATION: 001_combined_setup.sql
-- ----------------------------------------------------------------------------

-- POS System - Complete Setup Script
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard

-- ============ BRANCHES ============
CREATE TABLE IF NOT EXISTS branches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_en text,
  address text,
  phone text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_branches" ON branches;
CREATE POLICY "auth_select_branches" ON branches FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_branches" ON branches;
CREATE POLICY "auth_insert_branches" ON branches FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_branches" ON branches;
CREATE POLICY "auth_update_branches" ON branches FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_branches" ON branches;
CREATE POLICY "auth_delete_branches" ON branches FOR DELETE TO authenticated USING (true);

-- ============ WAREHOUSES ============
CREATE TABLE IF NOT EXISTS warehouses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  address text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_warehouses" ON warehouses;
CREATE POLICY "auth_select_warehouses" ON warehouses FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_warehouses" ON warehouses;
CREATE POLICY "auth_insert_warehouses" ON warehouses FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_warehouses" ON warehouses;
CREATE POLICY "auth_update_warehouses" ON warehouses FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_warehouses" ON warehouses;
CREATE POLICY "auth_delete_warehouses" ON warehouses FOR DELETE TO authenticated USING (true);

-- ============ CATEGORIES ============
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_en text,
  description text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_categories" ON categories;
CREATE POLICY "auth_select_categories" ON categories FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_categories" ON categories;
CREATE POLICY "auth_insert_categories" ON categories FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_categories" ON categories;
CREATE POLICY "auth_update_categories" ON categories FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_categories" ON categories;
CREATE POLICY "auth_delete_categories" ON categories FOR DELETE TO authenticated USING (true);

-- ============ PRODUCTS ============
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_en text,
  barcode text,
  sku text,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  description text,
  cost_price numeric(12,2) NOT NULL DEFAULT 0,
  sale_price numeric(12,2) NOT NULL DEFAULT 0,
  wholesale_price numeric(12,2) NOT NULL DEFAULT 0,
  image_url text,
  is_active boolean NOT NULL DEFAULT true,
  low_stock_threshold integer NOT NULL DEFAULT 5,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_products" ON products;
CREATE POLICY "auth_select_products" ON products FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_products" ON products;
CREATE POLICY "auth_insert_products" ON products FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_products" ON products;
CREATE POLICY "auth_update_products" ON products FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_products" ON products;
CREATE POLICY "auth_delete_products" ON products FOR DELETE TO authenticated USING (true);

-- ============ PRODUCT UNITS ============
CREATE TABLE IF NOT EXISTS product_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  unit_name text NOT NULL,
  unit_name_en text,
  conversion_factor numeric(12,4) NOT NULL DEFAULT 1,
  sale_price numeric(12,2) NOT NULL DEFAULT 0,
  cost_price numeric(12,2) NOT NULL DEFAULT 0,
  barcode text,
  is_base boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE product_units ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_product_units" ON product_units;
CREATE POLICY "auth_select_product_units" ON product_units FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_product_units" ON product_units;
CREATE POLICY "auth_insert_product_units" ON product_units FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_product_units" ON product_units;
CREATE POLICY "auth_update_product_units" ON product_units FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_product_units" ON product_units;
CREATE POLICY "auth_delete_product_units" ON product_units FOR DELETE TO authenticated USING (true);

-- ============ INVENTORY ============
CREATE TABLE IF NOT EXISTS inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id uuid NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  quantity numeric(14,4) NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  UNIQUE (product_id, warehouse_id)
);
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_inventory" ON inventory;
CREATE POLICY "auth_select_inventory" ON inventory FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_inventory" ON inventory;
CREATE POLICY "auth_insert_inventory" ON inventory FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_inventory" ON inventory;
CREATE POLICY "auth_update_inventory" ON inventory FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_inventory" ON inventory;
CREATE POLICY "auth_delete_inventory" ON inventory FOR DELETE TO authenticated USING (true);

-- ============ CUSTOMERS ============
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_en text,
  phone text,
  email text,
  address text,
  tax_number text,
  balance numeric(12,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_customers" ON customers;
CREATE POLICY "auth_select_customers" ON customers FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_customers" ON customers;
CREATE POLICY "auth_insert_customers" ON customers FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_customers" ON customers;
CREATE POLICY "auth_update_customers" ON customers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_customers" ON customers;
CREATE POLICY "auth_delete_customers" ON customers FOR DELETE TO authenticated USING (true);

-- ============ SUPPLIERS ============
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_en text,
  phone text,
  email text,
  address text,
  tax_number text,
  balance numeric(12,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_suppliers" ON suppliers;
CREATE POLICY "auth_select_suppliers" ON suppliers FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_suppliers" ON suppliers;
CREATE POLICY "auth_insert_suppliers" ON suppliers FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_suppliers" ON suppliers;
CREATE POLICY "auth_update_suppliers" ON suppliers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_suppliers" ON suppliers;
CREATE POLICY "auth_delete_suppliers" ON suppliers FOR DELETE TO authenticated USING (true);

-- ============ SALES ============
CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text NOT NULL,
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  warehouse_id uuid REFERENCES warehouses(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  cashier_id uuid,
  salesperson_id uuid,
  subtotal numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  discount_type text DEFAULT 'amount',
  tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  bonus_amount numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  paid_amount numeric(14,2) NOT NULL DEFAULT 0,
  payment_method text DEFAULT 'cash',
  status text DEFAULT 'completed',
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_sales" ON sales;
CREATE POLICY "auth_select_sales" ON sales FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_sales" ON sales;
CREATE POLICY "auth_insert_sales" ON sales FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_sales" ON sales;
CREATE POLICY "auth_update_sales" ON sales FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_sales" ON sales;
CREATE POLICY "auth_delete_sales" ON sales FOR DELETE TO authenticated USING (true);

-- ============ SALE ITEMS ============
CREATE TABLE IF NOT EXISTS sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  unit_name text NOT NULL DEFAULT 'piece',
  quantity numeric(14,4) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  bonus_quantity numeric(14,4) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_sale_items" ON sale_items;
CREATE POLICY "auth_select_sale_items" ON sale_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_sale_items" ON sale_items;
CREATE POLICY "auth_insert_sale_items" ON sale_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_sale_items" ON sale_items;
CREATE POLICY "auth_update_sale_items" ON sale_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_sale_items" ON sale_items;
CREATE POLICY "auth_delete_sale_items" ON sale_items FOR DELETE TO authenticated USING (true);

-- ============ PURCHASES ============
CREATE TABLE IF NOT EXISTS purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text NOT NULL,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  warehouse_id uuid REFERENCES warehouses(id) ON DELETE SET NULL,
  buyer_id uuid,
  subtotal numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  paid_amount numeric(14,2) NOT NULL DEFAULT 0,
  payment_method text DEFAULT 'cash',
  status text DEFAULT 'completed',
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_purchases" ON purchases;
CREATE POLICY "auth_select_purchases" ON purchases FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_purchases" ON purchases;
CREATE POLICY "auth_insert_purchases" ON purchases FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_purchases" ON purchases;
CREATE POLICY "auth_update_purchases" ON purchases FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_purchases" ON purchases;
CREATE POLICY "auth_delete_purchases" ON purchases FOR DELETE TO authenticated USING (true);

-- ============ PURCHASE ITEMS ============
CREATE TABLE IF NOT EXISTS purchase_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  unit_name text NOT NULL DEFAULT 'piece',
  quantity numeric(14,4) NOT NULL DEFAULT 1,
  unit_cost numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_purchase_items" ON purchase_items;
CREATE POLICY "auth_select_purchase_items" ON purchase_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_purchase_items" ON purchase_items;
CREATE POLICY "auth_insert_purchase_items" ON purchase_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_purchase_items" ON purchase_items;
CREATE POLICY "auth_update_purchase_items" ON purchase_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_purchase_items" ON purchase_items;
CREATE POLICY "auth_delete_purchase_items" ON purchase_items FOR DELETE TO authenticated USING (true);

-- ============ EXPENSES ============
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text,
  description text,
  amount numeric(14,2) NOT NULL DEFAULT 0,
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  payment_method text DEFAULT 'cash',
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text,
  created_by uuid,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_expenses" ON expenses;
CREATE POLICY "auth_select_expenses" ON expenses FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_expenses" ON expenses;
CREATE POLICY "auth_insert_expenses" ON expenses FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_expenses" ON expenses;
CREATE POLICY "auth_update_expenses" ON expenses FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_expenses" ON expenses;
CREATE POLICY "auth_delete_expenses" ON expenses FOR DELETE TO authenticated USING (true);

-- ============ USERS (app profiles) ============
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  email text NOT NULL,
  full_name text,
  role text NOT NULL DEFAULT 'cashier',
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_users" ON users;
CREATE POLICY "auth_select_users" ON users FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_users" ON users;
CREATE POLICY "auth_insert_users" ON users FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_users" ON users;
CREATE POLICY "auth_update_users" ON users FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_users" ON users;
CREATE POLICY "auth_delete_users" ON users FOR DELETE TO authenticated USING (true);

-- ============ AUDIT LOG ============
CREATE TABLE IF NOT EXISTS audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  user_email text,
  action text NOT NULL,
  entity text,
  entity_id uuid,
  details jsonb,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_audit_log" ON audit_log;
CREATE POLICY "auth_select_audit_log" ON audit_log FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_audit_log" ON audit_log;
CREATE POLICY "auth_insert_audit_log" ON audit_log FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_audit_log" ON audit_log;
CREATE POLICY "auth_update_audit_log" ON audit_log FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_audit_log" ON audit_log;
CREATE POLICY "auth_delete_audit_log" ON audit_log FOR DELETE TO authenticated USING (true);

-- ============ SETTINGS ============
CREATE TABLE IF NOT EXISTS settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name text NOT NULL DEFAULT 'My Store',
  store_name_en text,
  store_address text,
  store_phone text,
  currency text NOT NULL DEFAULT 'SAR',
  tax_rate numeric(5,2) NOT NULL DEFAULT 15,
  tax_enabled boolean NOT NULL DEFAULT true,
  receipt_footer text,
  receipt_header text,
  logo_url text,
  language text DEFAULT 'ar',
  theme text DEFAULT 'light',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_settings" ON settings;
CREATE POLICY "auth_select_settings" ON settings FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_settings" ON settings;
CREATE POLICY "auth_insert_settings" ON settings FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_settings" ON settings;
CREATE POLICY "auth_update_settings" ON settings FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_settings" ON settings;
CREATE POLICY "auth_delete_settings" ON settings FOR DELETE TO authenticated USING (true);

-- ============ INDEXES ============
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_sales_branch ON sales(branch_id);
CREATE INDEX IF NOT EXISTS idx_sales_created ON sales(created_at);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);

-- ============ SEED SETTINGS ============
INSERT INTO settings (store_name, store_name_en, store_address, store_phone, currency, tax_rate, tax_enabled, receipt_header, receipt_footer, language, theme)
SELECT 'Ù…ØªØ¬Ø±ÙŠ', 'My Store', '', '', 'SAR', 15, true, 'Ø£Ù‡Ù„Ø§Ù‹ ÙˆØ³Ù‡Ù„Ø§Ù‹', 'Ø´ÙƒØ±Ø§Ù‹ Ù„Ø²ÙŠØ§Ø±ØªÙƒÙ…', 'ar', 'light'
WHERE NOT EXISTS (SELECT 1 FROM settings);

-- ============ HELPER FUNCTION ============
-- NOTE: is_pos_admin() is redefined by migration_enterprise_core.sql to mean
-- super_admin / owner. The base definition below is superseded but harmless;
-- always run migration_enterprise_core.sql after this file.
CREATE OR REPLACE FUNCTION is_pos_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.is_active
    AND users.role IN ('super_admin', 'owner')
  );
$$;

-- ============ BRANCH ISOLATION POLICIES ============
DROP POLICY IF EXISTS "auth_select_sales" ON sales;
CREATE POLICY "auth_select_sales" ON sales FOR SELECT
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_insert_sales" ON sales;
CREATE POLICY "auth_insert_sales" ON sales FOR INSERT
  TO authenticated WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_update_sales" ON sales;
CREATE POLICY "auth_update_sales" ON sales FOR UPDATE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  )) WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_delete_sales" ON sales;
CREATE POLICY "auth_delete_sales" ON sales FOR DELETE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_select_purchases" ON purchases;
CREATE POLICY "auth_select_purchases" ON purchases FOR SELECT
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_insert_purchases" ON purchases;
CREATE POLICY "auth_insert_purchases" ON purchases FOR INSERT
  TO authenticated WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_update_purchases" ON purchases;
CREATE POLICY "auth_update_purchases" ON purchases FOR UPDATE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  )) WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_delete_purchases" ON purchases;
CREATE POLICY "auth_delete_purchases" ON purchases FOR DELETE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_select_expenses" ON expenses;
CREATE POLICY "auth_select_expenses" ON expenses FOR SELECT
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_insert_expenses" ON expenses;
CREATE POLICY "auth_insert_expenses" ON expenses FOR INSERT
  TO authenticated WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_update_expenses" ON expenses;
CREATE POLICY "auth_update_expenses" ON expenses FOR UPDATE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  )) WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));

DROP POLICY IF EXISTS "auth_delete_expenses" ON expenses;
CREATE POLICY "auth_delete_expenses" ON expenses FOR DELETE
  TO authenticated USING (is_pos_admin() OR branch_id IS NULL OR branch_id = (
    SELECT users.branch_id FROM users WHERE users.id = auth.uid()
  ));



-- ----------------------------------------------------------------------------
-- MIGRATION: 002_product_components.sql
-- ----------------------------------------------------------------------------

-- Migration: Product Components (BOM - Bill of Materials)
-- Run in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS product_components (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  component_product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity numeric(14,4) NOT NULL DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  UNIQUE (product_id, component_product_id)
);
ALTER TABLE product_components ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "auth_select_product_components" ON product_components;
CREATE POLICY "auth_select_product_components" ON product_components FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_product_components" ON product_components;
CREATE POLICY "auth_insert_product_components" ON product_components FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_product_components" ON product_components;
CREATE POLICY "auth_update_product_components" ON product_components FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_product_components" ON product_components;
CREATE POLICY "auth_delete_product_components" ON product_components FOR DELETE TO authenticated USING (true);



-- ----------------------------------------------------------------------------
-- MIGRATION: 003_inventory_v2.sql
-- ----------------------------------------------------------------------------

-- Migration: Inventory v2 - Dual Inventory (Ready Products + Manufactured with BOM)
-- Run this in Supabase SQL Editor AFTER combined_setup.sql + migration_components.sql

-- ============ 1. PRODUCT TYPE ============
ALTER TABLE products ADD COLUMN IF NOT EXISTS product_type text NOT NULL DEFAULT 'ready';

-- Backfill: any product that already has a recipe is a manufactured product
UPDATE products SET product_type = 'manufactured'
WHERE product_type = 'ready'
  AND EXISTS (SELECT 1 FROM product_components pc WHERE pc.product_id = products.id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'products_product_type_check') THEN
    ALTER TABLE products ADD CONSTRAINT products_product_type_check
      CHECK (product_type IN ('ready', 'manufactured'));
  END IF;
END $$;

-- ============ 2. STOCK TRANSACTIONS LEDGER ============
-- Every inventory movement is logged here (negative quantity = deduction)
CREATE TABLE IF NOT EXISTS stock_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id uuid REFERENCES warehouses(id) ON DELETE SET NULL,
  branch_id uuid REFERENCES branches(id) ON DELETE SET NULL,
  transaction_type text NOT NULL DEFAULT 'sale' CHECK (transaction_type IN ('sale', 'purchase', 'adjustment')),
  component_flow boolean NOT NULL DEFAULT false,
  reference_type text NOT NULL,
  reference_id uuid,
  quantity numeric(14,4) NOT NULL,
  before_quantity numeric(14,4) NOT NULL DEFAULT 0,
  after_quantity numeric(14,4) NOT NULL DEFAULT 0,
  unit_cost numeric(12,2),
  reason text,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE stock_transactions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_stock_tx_product ON stock_transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_tx_created ON stock_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_tx_branch ON stock_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_stock_tx_reference ON stock_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_stock_tx_component ON stock_transactions(component_flow);

DROP POLICY IF EXISTS "auth_select_stock_transactions" ON stock_transactions;
CREATE POLICY "auth_select_stock_transactions" ON stock_transactions FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_stock_transactions" ON stock_transactions;
CREATE POLICY "auth_insert_stock_transactions" ON stock_transactions FOR INSERT TO authenticated WITH CHECK (true);

-- ============ 3. PROCESS SALE (single atomic transaction) ============
CREATE OR REPLACE FUNCTION process_sale(
  p_invoice_number text,
  p_branch_id uuid,
  p_warehouse_id uuid,
  p_customer_id uuid,
  p_salesperson_id uuid,
  p_subtotal numeric,
  p_discount_amount numeric,
  p_discount_type text,
  p_tax_amount numeric,
  p_bonus_amount numeric,
  p_total numeric,
  p_paid_amount numeric,
  p_payment_method text,
  p_status text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_comp record;
  v_inv record;
  v_warehouse_ids uuid[];
  v_required numeric(14,4);
  v_available numeric(14,4);
  v_remaining numeric(14,4);
  v_deduct numeric(14,4);
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_cost numeric(12,2);
  v_product_type text;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      SELECT product_type INTO v_product_type FROM products WHERE id = v_product_id;
      IF v_product_type IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      IF v_product_type = 'manufactured' THEN
        -- No recipe => cannot sell
        IF NOT EXISTS (SELECT 1 FROM product_components WHERE product_id = v_product_id) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_RECIPE', 'product_id', v_product_id);
        END IF;
        -- Verify ALL components available
        FOR v_comp IN SELECT component_product_id, quantity FROM product_components WHERE product_id = v_product_id
        LOOP
          v_required := COALESCE(v_comp.quantity, 0) * v_quantity;
          SELECT COALESCE(SUM(quantity), 0) INTO v_available
          FROM inventory
          WHERE product_id = v_comp.component_product_id AND warehouse_id = ANY(v_warehouse_ids);
          IF v_available < v_required THEN
            RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_COMPONENT',
              'product_id', v_product_id, 'component_id', v_comp.component_product_id,
              'required', v_required, 'available', v_available);
          END IF;
        END LOOP;
      ELSE
        SELECT COALESCE(SUM(quantity), 0) INTO v_available
        FROM inventory
        WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
        IF v_available < v_quantity THEN
          RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
            'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
        END IF;
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 1: sale header =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      p_subtotal, p_discount_amount, p_discount_type, p_tax_amount, p_bonus_amount,
      p_total, p_paid_amount, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + locked stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
      v_discount_amount := COALESCE((v_item->>'discount_amount')::numeric, 0);
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := COALESCE((v_item->>'total')::numeric, v_quantity * v_unit_price - v_discount_amount);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      SELECT product_type INTO v_product_type FROM products WHERE id = v_product_id;

      IF v_product_type = 'manufactured' THEN
        FOR v_comp IN SELECT component_product_id, quantity FROM product_components WHERE product_id = v_product_id
        LOOP
          v_required := COALESCE(v_comp.quantity, 0) * v_quantity;
          v_remaining := v_required;
          SELECT cost_price INTO v_cost FROM products WHERE id = v_comp.component_product_id;

          FOR v_inv IN SELECT id, warehouse_id, quantity FROM inventory
            WHERE product_id = v_comp.component_product_id AND warehouse_id = ANY(v_warehouse_ids) AND quantity > 0
            ORDER BY quantity DESC
            FOR UPDATE
          LOOP
            IF v_remaining <= 0 THEN EXIT; END IF;
            v_deduct := LEAST(v_inv.quantity, v_remaining);
            v_before := v_inv.quantity;
            v_after := v_inv.quantity - v_deduct;
            UPDATE inventory SET quantity = v_after, updated_at = now() WHERE id = v_inv.id;
            INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
              component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
            VALUES (v_comp.component_product_id, v_inv.warehouse_id, p_branch_id, 'sale',
              true, 'sale', v_sale_id, -v_deduct, v_before, v_after, v_cost, auth.uid());
            v_remaining := v_remaining - v_deduct;
          END LOOP;

          IF v_remaining > 0 THEN
            RAISE EXCEPTION 'INSUFFICIENT_COMPONENT: product % needs % but only % available',
              v_product_id, v_required, (v_required - v_remaining);
          END IF;
        END LOOP;
      ELSE
        v_remaining := v_quantity;
        SELECT cost_price INTO v_cost FROM products WHERE id = v_product_id;

        FOR v_inv IN SELECT id, warehouse_id, quantity FROM inventory
          WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids) AND quantity > 0
          ORDER BY quantity DESC
          FOR UPDATE
        LOOP
          IF v_remaining <= 0 THEN EXIT; END IF;
          v_deduct := LEAST(v_inv.quantity, v_remaining);
          v_before := v_inv.quantity;
          v_after := v_inv.quantity - v_deduct;
          UPDATE inventory SET quantity = v_after, updated_at = now() WHERE id = v_inv.id;
          INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
            component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
          VALUES (v_product_id, v_inv.warehouse_id, p_branch_id, 'sale',
            false, 'sale', v_sale_id, -v_deduct, v_before, v_after, v_cost, auth.uid());
          v_remaining := v_remaining - v_deduct;
        END LOOP;

        IF v_remaining > 0 THEN
          RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
            v_product_id, v_quantity, (v_quantity - v_remaining);
        END IF;
      END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_COMPONENT%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_COMPONENT', 'detail', SQLERRM);
    ELSIF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$$;

-- ============ 4. PROCESS PURCHASE (single atomic transaction) ============
CREATE OR REPLACE FUNCTION process_purchase(
  p_invoice_number text,
  p_supplier_id uuid,
  p_branch_id uuid,
  p_warehouse_id uuid,
  p_subtotal numeric,
  p_discount_amount numeric,
  p_tax_amount numeric,
  p_total numeric,
  p_paid_amount numeric,
  p_payment_method text,
  p_status text,
  p_notes text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase_id uuid;
  v_user_branch uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_cost numeric(12,2);
  v_inv record;
  v_before numeric(14,4);
  v_after numeric(14,4);
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    -- Branch isolation (mirror of RLS on purchases)
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    INSERT INTO purchases (invoice_number, supplier_id, branch_id, warehouse_id, buyer_id,
      subtotal, discount_amount, tax_amount, total, paid_amount, payment_method, status, notes)
    VALUES (p_invoice_number, p_supplier_id, p_branch_id, p_warehouse_id, auth.uid(),
      p_subtotal, p_discount_amount, p_tax_amount, p_total, p_paid_amount, p_payment_method, p_status, p_notes)
    RETURNING id INTO v_purchase_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_cost := COALESCE((v_item->>'unit_cost')::numeric, 0);

      INSERT INTO purchase_items (purchase_id, product_id, unit_name, quantity, unit_cost, total)
      VALUES (v_purchase_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_cost, v_quantity * v_unit_cost);

      -- Inventory only when a warehouse is selected (keeps previous optional behavior)
      IF p_warehouse_id IS NOT NULL THEN
        SELECT id, quantity INTO v_inv
        FROM inventory
        WHERE product_id = v_product_id AND warehouse_id = p_warehouse_id
        FOR UPDATE;

        IF v_inv.id IS NULL THEN
          INSERT INTO inventory (product_id, warehouse_id, quantity)
          VALUES (v_product_id, p_warehouse_id, v_quantity)
          RETURNING id, quantity INTO v_inv;
          v_before := 0;
          v_after := v_inv.quantity;
        ELSE
          v_before := v_inv.quantity;
          v_after := v_before + v_quantity;
          UPDATE inventory SET quantity = v_after, updated_at = now() WHERE id = v_inv.id;
        END IF;

        INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
          component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
        VALUES (v_product_id, p_warehouse_id, p_branch_id, 'purchase',
          false, 'purchase', v_purchase_id, v_quantity, v_before, v_after, v_unit_cost, auth.uid());
      END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'purchase_id', v_purchase_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$$;

-- ============ 5. ADJUST STOCK (single atomic transaction) ============
CREATE OR REPLACE FUNCTION adjust_stock(
  p_inventory_id uuid,
  p_new_quantity numeric,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_inv record;
  v_user_branch uuid;
  v_delta numeric(14,4);
BEGIN
  BEGIN
    SELECT i.id, i.product_id, i.warehouse_id, i.quantity, w.branch_id, p.cost_price AS cost
    INTO v_inv
    FROM inventory i
    JOIN warehouses w ON w.id = i.warehouse_id
    JOIN products p ON p.id = i.product_id
    WHERE i.id = p_inventory_id
    FOR UPDATE OF i;

    IF v_inv.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVENTORY_NOT_FOUND');
    END IF;

    -- Branch isolation
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND v_inv.branch_id IS NOT NULL AND v_user_branch <> v_inv.branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    v_delta := p_new_quantity - v_inv.quantity;
    IF v_delta = 0 THEN
      RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id, 'no_change', true);
    END IF;

    UPDATE inventory SET quantity = p_new_quantity, updated_at = now() WHERE id = p_inventory_id;
    INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
      component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, reason, created_by)
    VALUES (v_inv.product_id, v_inv.warehouse_id, v_inv.branch_id, 'adjustment',
      false, 'adjustment', NULL, v_delta, v_inv.quantity, p_new_quantity, v_inv.cost, p_reason, auth.uid());

    RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 004_enterprise_core.sql
-- ----------------------------------------------------------------------------

-- Migration: Enterprise Core - Full branch isolation + enterprise roles + shifts
-- Run this in Supabase SQL Editor AFTER migration_inventory_v2.sql.
-- (The legacy create_user / user_password_delete migrations are consolidated
--  into this file: create_user, delete_user and update_user_password RPCs.)
--
-- WHAT THIS DOES
-- 1. Helper functions: is_pos_admin() now means super_admin/owner and is
--    search_path-safe; new get_branch_id() + is_branch_manager().
-- 2. Role migration: admin->super_admin, manager->branch_manager,
--    salesperson->cashier + a CHECK constraint locking the 8 enterprise roles.
-- 3. branch_id on the catalog tables (products, categories, customers,
--    suppliers) and audit_log; all existing rows are copied to the oldest
--    branch so nothing is lost; columns become NOT NULL + indexed.
-- 4. Full RLS overhaul: every table is branch-scoped. Child tables
--    (sale_items, purchase_items, inventory, product_units) inherit the
--    isolation from their parent (sales, purchases, warehouses, products).
-- 5. Shift system: shifts + shift_operations tables, open_shift / close_shift
--    / get_active_shift RPCs, and process_sale now REQUIRES an open shift for
--    cashiers and logs every paid sale into the shift.
-- 6. User management RPCs updated for the new roles (branch managers can
--    manage staff of their own branch, never super_admin/owner accounts).

-- ============ 1. HELPER FUNCTIONS ============

-- is_pos_admin(): true for super_admin / owner only.
-- SECURITY DEFINER + SET search_path so any caller (including other functions
-- without a search_path) resolves `users` correctly.
CREATE OR REPLACE FUNCTION is_pos_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.is_active
    AND users.role IN ('super_admin', 'owner')
  );
$$;

-- get_branch_id(): the branch of the current user (NULL for admin users).
-- SECURITY DEFINER so RLS on `users` cannot hide the row from the policy engine.
CREATE OR REPLACE FUNCTION get_branch_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT branch_id FROM public.users WHERE users.id = auth.uid();
$$;

-- is_branch_manager(): true when the current user is an active branch manager
-- assigned to a branch (used to scope user management to their own branch).
CREATE OR REPLACE FUNCTION is_branch_manager()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.is_active
    AND users.role = 'branch_manager'
    AND users.branch_id IS NOT NULL
  );
$$;

-- ============ 2. ROLE MIGRATION ============
-- Map legacy roles to the enterprise role model, then lock the column.
-- Any unknown legacy value falls back to cashier so the CHECK constraint below
-- can never fail because of a stale role name.
UPDATE public.users
SET role = CASE role
  WHEN 'admin'       THEN 'super_admin'
  WHEN 'manager'     THEN 'branch_manager'
  WHEN 'salesperson' THEN 'cashier'
  ELSE 'cashier'
END
WHERE role NOT IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                   'warehouse_manager', 'kitchen', 'accountant', 'customer_display');

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check') THEN
    ALTER TABLE public.users ADD CONSTRAINT users_role_check
      CHECK (role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                      'warehouse_manager', 'kitchen', 'accountant', 'customer_display'));
  END IF;
END $$;

-- ============ 3. BRANCH COLUMNS ON CATALOG TABLES ============

ALTER TABLE products   ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id) ON DELETE SET NULL;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id) ON DELETE SET NULL;
ALTER TABLE customers  ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id) ON DELETE SET NULL;
ALTER TABLE suppliers  ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id) ON DELETE SET NULL;
ALTER TABLE audit_log  ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES branches(id) ON DELETE SET NULL;

-- Backfill: copy every existing row to the oldest branch (or create the
-- primary branch when there are no branches at all), then make the columns
-- NOT NULL so no future row can be created without a branch.
DO $$
DECLARE v_default uuid;
BEGIN
  SELECT id INTO v_default FROM public.branches ORDER BY created_at, id LIMIT 1;

  IF v_default IS NULL THEN
    INSERT INTO public.branches (name) VALUES ('Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ')
    RETURNING id INTO v_default;
  END IF;

  UPDATE public.products   SET branch_id = v_default WHERE branch_id IS NULL;
  UPDATE public.categories SET branch_id = v_default WHERE branch_id IS NULL;
  UPDATE public.customers  SET branch_id = v_default WHERE branch_id IS NULL;
  UPDATE public.suppliers  SET branch_id = v_default WHERE branch_id IS NULL;
  UPDATE public.audit_log  SET branch_id = v_default WHERE branch_id IS NULL;
END $$;

ALTER TABLE products   ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE categories ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE customers  ALTER COLUMN branch_id SET NOT NULL;
ALTER TABLE suppliers  ALTER COLUMN branch_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_products_branch    ON products(branch_id);
CREATE INDEX IF NOT EXISTS idx_categories_branch  ON categories(branch_id);
CREATE INDEX IF NOT EXISTS idx_customers_branch   ON customers(branch_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_branch   ON suppliers(branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_branch   ON audit_log(branch_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_branch  ON warehouses(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_branch       ON users(branch_id);

-- ============ 4. FULL RLS OVERHAUL ============

-- ---------- BRANCHES (shared reference: read for all, write for admins) ----------
DROP POLICY IF EXISTS "auth_select_branches" ON branches;
CREATE POLICY "auth_select_branches" ON branches FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_branches" ON branches;
CREATE POLICY "auth_insert_branches" ON branches FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_update_branches" ON branches;
CREATE POLICY "auth_update_branches" ON branches FOR UPDATE TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_delete_branches" ON branches;
CREATE POLICY "auth_delete_branches" ON branches FOR DELETE TO authenticated USING (is_pos_admin());

-- ---------- WAREHOUSES ----------
DROP POLICY IF EXISTS "auth_select_warehouses" ON warehouses;
CREATE POLICY "auth_select_warehouses" ON warehouses FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_warehouses" ON warehouses;
CREATE POLICY "auth_insert_warehouses" ON warehouses FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_warehouses" ON warehouses;
CREATE POLICY "auth_update_warehouses" ON warehouses FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_warehouses" ON warehouses;
CREATE POLICY "auth_delete_warehouses" ON warehouses FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());

-- ---------- CATEGORIES ----------
DROP POLICY IF EXISTS "auth_select_categories" ON categories;
CREATE POLICY "auth_select_categories" ON categories FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_categories" ON categories;
CREATE POLICY "auth_insert_categories" ON categories FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_categories" ON categories;
CREATE POLICY "auth_update_categories" ON categories FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_categories" ON categories;
CREATE POLICY "auth_delete_categories" ON categories FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- ---------- PRODUCTS ----------
DROP POLICY IF EXISTS "auth_select_products" ON products;
CREATE POLICY "auth_select_products" ON products FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_products" ON products;
CREATE POLICY "auth_insert_products" ON products FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_products" ON products;
CREATE POLICY "auth_update_products" ON products FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_products" ON products;
CREATE POLICY "auth_delete_products" ON products FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- ---------- PRODUCT UNITS (isolated via products) ----------
DROP POLICY IF EXISTS "auth_select_product_units" ON product_units;
CREATE POLICY "auth_select_product_units" ON product_units FOR SELECT TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM products p WHERE p.id = product_units.product_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_insert_product_units" ON product_units;
CREATE POLICY "auth_insert_product_units" ON product_units FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM products p WHERE p.id = product_units.product_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_update_product_units" ON product_units;
CREATE POLICY "auth_update_product_units" ON product_units FOR UPDATE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM products p WHERE p.id = product_units.product_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ))
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM products p WHERE p.id = product_units.product_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_delete_product_units" ON product_units;
CREATE POLICY "auth_delete_product_units" ON product_units FOR DELETE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM products p WHERE p.id = product_units.product_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));

-- ---------- INVENTORY (isolated via warehouses) ----------
DROP POLICY IF EXISTS "auth_select_inventory" ON inventory;
CREATE POLICY "auth_select_inventory" ON inventory FOR SELECT TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM warehouses w WHERE w.id = inventory.warehouse_id
    AND (w.branch_id = get_branch_id() OR w.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_insert_inventory" ON inventory;
CREATE POLICY "auth_insert_inventory" ON inventory FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM warehouses w WHERE w.id = inventory.warehouse_id
    AND (w.branch_id = get_branch_id() OR w.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_update_inventory" ON inventory;
CREATE POLICY "auth_update_inventory" ON inventory FOR UPDATE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM warehouses w WHERE w.id = inventory.warehouse_id
    AND (w.branch_id = get_branch_id() OR w.branch_id IS NULL)
  ))
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM warehouses w WHERE w.id = inventory.warehouse_id
    AND (w.branch_id = get_branch_id() OR w.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_delete_inventory" ON inventory;
CREATE POLICY "auth_delete_inventory" ON inventory FOR DELETE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM warehouses w WHERE w.id = inventory.warehouse_id
    AND (w.branch_id = get_branch_id() OR w.branch_id IS NULL)
  ));

-- ---------- CUSTOMERS ----------
DROP POLICY IF EXISTS "auth_select_customers" ON customers;
CREATE POLICY "auth_select_customers" ON customers FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_customers" ON customers;
CREATE POLICY "auth_insert_customers" ON customers FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_customers" ON customers;
CREATE POLICY "auth_update_customers" ON customers FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_customers" ON customers;
CREATE POLICY "auth_delete_customers" ON customers FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- ---------- SUPPLIERS ----------
DROP POLICY IF EXISTS "auth_select_suppliers" ON suppliers;
CREATE POLICY "auth_select_suppliers" ON suppliers FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_suppliers" ON suppliers;
CREATE POLICY "auth_insert_suppliers" ON suppliers FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_suppliers" ON suppliers;
CREATE POLICY "auth_update_suppliers" ON suppliers FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_suppliers" ON suppliers;
CREATE POLICY "auth_delete_suppliers" ON suppliers FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- ---------- SALES ----------
DROP POLICY IF EXISTS "auth_select_sales" ON sales;
CREATE POLICY "auth_select_sales" ON sales FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_sales" ON sales;
CREATE POLICY "auth_insert_sales" ON sales FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_sales" ON sales;
CREATE POLICY "auth_update_sales" ON sales FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_sales" ON sales;
CREATE POLICY "auth_delete_sales" ON sales FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());

-- ---------- SALE ITEMS (via sales) ----------
DROP POLICY IF EXISTS "auth_select_sale_items" ON sale_items;
CREATE POLICY "auth_select_sale_items" ON sale_items FOR SELECT TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id
    AND (s.branch_id = get_branch_id() OR s.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_insert_sale_items" ON sale_items;
CREATE POLICY "auth_insert_sale_items" ON sale_items FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id
    AND (s.branch_id = get_branch_id() OR s.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_update_sale_items" ON sale_items;
CREATE POLICY "auth_update_sale_items" ON sale_items FOR UPDATE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id
    AND (s.branch_id = get_branch_id() OR s.branch_id IS NULL)
  ))
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id
    AND (s.branch_id = get_branch_id() OR s.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_delete_sale_items" ON sale_items;
CREATE POLICY "auth_delete_sale_items" ON sale_items FOR DELETE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id
    AND (s.branch_id = get_branch_id() OR s.branch_id IS NULL)
  ));

-- ---------- PURCHASES ----------
DROP POLICY IF EXISTS "auth_select_purchases" ON purchases;
CREATE POLICY "auth_select_purchases" ON purchases FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_purchases" ON purchases;
CREATE POLICY "auth_insert_purchases" ON purchases FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_purchases" ON purchases;
CREATE POLICY "auth_update_purchases" ON purchases FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_purchases" ON purchases;
CREATE POLICY "auth_delete_purchases" ON purchases FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());

-- ---------- PURCHASE ITEMS (via purchases) ----------
DROP POLICY IF EXISTS "auth_select_purchase_items" ON purchase_items;
CREATE POLICY "auth_select_purchase_items" ON purchase_items FOR SELECT TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM purchases p WHERE p.id = purchase_items.purchase_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_insert_purchase_items" ON purchase_items;
CREATE POLICY "auth_insert_purchase_items" ON purchase_items FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM purchases p WHERE p.id = purchase_items.purchase_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_update_purchase_items" ON purchase_items;
CREATE POLICY "auth_update_purchase_items" ON purchase_items FOR UPDATE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM purchases p WHERE p.id = purchase_items.purchase_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ))
  WITH CHECK (is_pos_admin() OR EXISTS (
    SELECT 1 FROM purchases p WHERE p.id = purchase_items.purchase_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));
DROP POLICY IF EXISTS "auth_delete_purchase_items" ON purchase_items;
CREATE POLICY "auth_delete_purchase_items" ON purchase_items FOR DELETE TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM purchases p WHERE p.id = purchase_items.purchase_id
    AND (p.branch_id = get_branch_id() OR p.branch_id IS NULL)
  ));

-- ---------- EXPENSES ----------
DROP POLICY IF EXISTS "auth_select_expenses" ON expenses;
CREATE POLICY "auth_select_expenses" ON expenses FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_expenses" ON expenses;
CREATE POLICY "auth_insert_expenses" ON expenses FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_expenses" ON expenses;
CREATE POLICY "auth_update_expenses" ON expenses FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_delete_expenses" ON expenses;
CREATE POLICY "auth_delete_expenses" ON expenses FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());

-- ---------- STOCK TRANSACTIONS ----------
DROP POLICY IF EXISTS "auth_select_stock_transactions" ON stock_transactions;
CREATE POLICY "auth_select_stock_transactions" ON stock_transactions FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_stock_transactions" ON stock_transactions;
CREATE POLICY "auth_insert_stock_transactions" ON stock_transactions FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());

-- ---------- USERS (admins see all; branch managers see their branch; self always) ----------
DROP POLICY IF EXISTS "auth_select_users" ON users;
CREATE POLICY "auth_select_users" ON users FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id() OR id = auth.uid());
DROP POLICY IF EXISTS "auth_insert_users" ON users;
CREATE POLICY "auth_insert_users" ON users FOR INSERT TO authenticated
  WITH CHECK (
    (id = auth.uid() AND role = 'cashier' AND branch_id IS NULL)
    OR is_pos_admin()
  );
DROP POLICY IF EXISTS "auth_update_users" ON users;
CREATE POLICY "auth_update_users" ON users FOR UPDATE TO authenticated
  USING (is_pos_admin() OR id = auth.uid()
    OR (is_branch_manager() AND branch_id = get_branch_id() AND role NOT IN ('super_admin', 'owner')))
  WITH CHECK (
    is_pos_admin()
    OR (
      id = auth.uid()
      AND role = (SELECT role FROM public.users WHERE id = auth.uid())
      AND branch_id = (SELECT branch_id FROM public.users WHERE id = auth.uid())
    )
    OR (is_branch_manager() AND branch_id = get_branch_id() AND role NOT IN ('super_admin', 'owner'))
  );
DROP POLICY IF EXISTS "auth_delete_users" ON users;
CREATE POLICY "auth_delete_users" ON users FOR DELETE TO authenticated
  USING (is_pos_admin()
    OR (is_branch_manager() AND branch_id = get_branch_id() AND role NOT IN ('super_admin', 'owner')));

-- ---------- AUDIT LOG (branch-scoped read; admin-only write/delete) ----------
DROP POLICY IF EXISTS "auth_select_audit_log" ON audit_log;
CREATE POLICY "auth_select_audit_log" ON audit_log FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_insert_audit_log" ON audit_log;
CREATE POLICY "auth_insert_audit_log" ON audit_log FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id IS NULL OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_update_audit_log" ON audit_log;
CREATE POLICY "auth_update_audit_log" ON audit_log FOR UPDATE TO authenticated
  USING (is_pos_admin()) WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_delete_audit_log" ON audit_log;
CREATE POLICY "auth_delete_audit_log" ON audit_log FOR DELETE TO authenticated
  USING (is_pos_admin());

-- ---------- SETTINGS (store-wide, stays open) ----------
DROP POLICY IF EXISTS "auth_select_settings" ON settings;
CREATE POLICY "auth_select_settings" ON settings FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_insert_settings" ON settings;
CREATE POLICY "auth_insert_settings" ON settings FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "auth_update_settings" ON settings;
CREATE POLICY "auth_update_settings" ON settings FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "auth_delete_settings" ON settings;
CREATE POLICY "auth_delete_settings" ON settings FOR DELETE TO authenticated USING (true);

-- ============ 5. SHIFT SYSTEM ============

-- A shift is an open/closed cash-drawer session for a cashier at a branch.
CREATE TABLE IF NOT EXISTS shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  cashier_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  opening_amount numeric(14,2) NOT NULL DEFAULT 0,
  expected_amount numeric(14,2) NOT NULL DEFAULT 0,
  actual_amount numeric(14,2),
  difference numeric(14,2) DEFAULT 0,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;

-- Every operation that touches the drawer is recorded here.
CREATE TABLE IF NOT EXISTS shift_operations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shift_id uuid NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
  operation_type text NOT NULL CHECK (operation_type IN ('sale', 'refund', 'expense', 'cash_in', 'cash_out', 'opening')),
  amount numeric(14,2) NOT NULL DEFAULT 0,
  payment_method text,
  reference_type text,
  reference_id uuid,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE shift_operations ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_shifts_branch  ON shifts(branch_id);
CREATE INDEX IF NOT EXISTS idx_shifts_cashier ON shifts(cashier_id);
CREATE INDEX IF NOT EXISTS idx_shifts_status  ON shifts(status);
CREATE INDEX IF NOT EXISTS idx_shift_ops_shift ON shift_operations(shift_id);

-- Shifts RLS
DROP POLICY IF EXISTS "auth_select_shifts" ON shifts;
CREATE POLICY "auth_select_shifts" ON shifts FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id() OR cashier_id = auth.uid());
DROP POLICY IF EXISTS "auth_insert_shifts" ON shifts;
CREATE POLICY "auth_insert_shifts" ON shifts FOR INSERT TO authenticated
  WITH CHECK (cashier_id = auth.uid() AND (branch_id = get_branch_id() OR is_pos_admin()));
DROP POLICY IF EXISTS "auth_update_shifts" ON shifts;
CREATE POLICY "auth_update_shifts" ON shifts FOR UPDATE TO authenticated
  USING (is_pos_admin() OR cashier_id = auth.uid())
  WITH CHECK (is_pos_admin() OR cashier_id = auth.uid());
DROP POLICY IF EXISTS "auth_delete_shifts" ON shifts;
CREATE POLICY "auth_delete_shifts" ON shifts FOR DELETE TO authenticated
  USING (is_pos_admin());

-- Shift operations RLS
DROP POLICY IF EXISTS "auth_select_shift_operations" ON shift_operations;
CREATE POLICY "auth_select_shift_operations" ON shift_operations FOR SELECT TO authenticated
  USING (is_pos_admin() OR EXISTS (
    SELECT 1 FROM shifts s WHERE s.id = shift_operations.shift_id
    AND (s.branch_id = get_branch_id() OR s.cashier_id = auth.uid())
  ));
DROP POLICY IF EXISTS "auth_insert_shift_operations" ON shift_operations;
CREATE POLICY "auth_insert_shift_operations" ON shift_operations FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM shifts s WHERE s.id = shift_operations.shift_id AND s.cashier_id = auth.uid()
  ));

-- ============ 6. SHIFT RPCs ============

-- open_shift: a cashier opens the drawer with an opening float.
CREATE OR REPLACE FUNCTION open_shift(p_branch_id uuid, p_opening_amount numeric DEFAULT 0, p_notes text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_role text;
  v_branch uuid;
  v_shift_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHENTICATED');
  END IF;

  SELECT role, branch_id INTO v_role, v_branch FROM public.users WHERE id = v_uid;
  IF v_role IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;

  -- Only register operators (cashiers) open shifts
  IF v_role NOT IN ('cashier') THEN
    RETURN jsonb_build_object('success', false, 'error', 'SHIFT_NOT_ALLOWED',
      'detail', 'Only cashier accounts can open a shift');
  END IF;

  IF p_branch_id IS NULL THEN
    IF v_branch IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'NO_BRANCH',
        'detail', 'You have no branch assigned. Ask an admin to set your branch.');
    END IF;
    p_branch_id := v_branch;
  END IF;

  IF NOT is_pos_admin() AND v_branch IS NOT NULL AND v_branch <> p_branch_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
  END IF;

  IF EXISTS (SELECT 1 FROM shifts WHERE cashier_id = v_uid AND branch_id = p_branch_id AND status = 'open') THEN
    RETURN jsonb_build_object('success', false, 'error', 'SHIFT_ALREADY_OPEN');
  END IF;

  INSERT INTO shifts (branch_id, cashier_id, opening_amount, notes)
  VALUES (p_branch_id, v_uid, COALESCE(p_opening_amount, 0), p_notes)
  RETURNING id INTO v_shift_id;

  INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type)
  VALUES (v_shift_id, 'opening', COALESCE(p_opening_amount, 0), 'cash', 'shift_opening');

  RETURN jsonb_build_object('success', true, 'shift_id', v_shift_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- close_shift: computes expected drawer = opening + cash sales - cash expenses - refunds,
-- then records the actual counted amount and the difference.
CREATE OR REPLACE FUNCTION close_shift(p_shift_id uuid, p_actual_amount numeric, p_notes text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_shift record;
  v_expected numeric(14,2);
  v_diff numeric(14,2);
BEGIN
  SELECT * INTO v_shift FROM shifts WHERE id = p_shift_id;
  IF v_shift.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'SHIFT_NOT_FOUND');
  END IF;

  IF v_shift.status = 'closed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'SHIFT_CLOSED');
  END IF;

  IF NOT is_pos_admin()
     AND v_shift.cashier_id <> v_uid
     AND NOT EXISTS (SELECT 1 FROM public.users
                     WHERE id = v_uid AND is_active AND role = 'branch_manager'
                       AND branch_id = v_shift.branch_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_YOUR_SHIFT');
  END IF;

  SELECT COALESCE(v_shift.opening_amount, 0)
       + COALESCE(SUM(CASE WHEN op.operation_type = 'sale'    AND COALESCE(op.payment_method, 'cash') = 'cash' THEN op.amount ELSE 0 END), 0)
       - COALESCE(SUM(CASE WHEN op.operation_type = 'expense' AND COALESCE(op.payment_method, 'cash') = 'cash' THEN op.amount ELSE 0 END), 0)
       - COALESCE(SUM(CASE WHEN op.operation_type = 'refund'  THEN op.amount ELSE 0 END), 0)
    INTO v_expected
  FROM shift_operations op
  WHERE op.shift_id = p_shift_id;

  v_diff := COALESCE(p_actual_amount, v_expected) - v_expected;

  UPDATE shifts
  SET status = 'closed',
      closed_at = now(),
      expected_amount = v_expected,
      actual_amount = COALESCE(p_actual_amount, v_expected),
      difference = v_diff,
      notes = COALESCE(p_notes, notes)
  WHERE id = p_shift_id;

  RETURN jsonb_build_object('success', true, 'shift_id', p_shift_id,
    'expected', v_expected, 'actual', COALESCE(p_actual_amount, v_expected), 'difference', v_diff);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- get_active_shift: returns the caller's open shift (branch optional).
CREATE OR REPLACE FUNCTION get_active_shift(p_branch_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_shift record;
  v_cash_sales numeric(14,2);
  v_cash_expenses numeric(14,2);
  v_total_sales numeric(14,2);
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHENTICATED');
  END IF;

  SELECT * INTO v_shift
  FROM shifts
  WHERE cashier_id = v_uid AND status = 'open'
    AND (p_branch_id IS NULL OR branch_id = p_branch_id)
  ORDER BY opened_at DESC LIMIT 1;

  IF v_shift.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'open', false);
  END IF;

  SELECT COALESCE(SUM(amount), 0),
         COALESCE(SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END), 0),
         COALESCE(SUM(CASE WHEN operation_type = 'expense' AND payment_method = 'cash' THEN amount ELSE 0 END), 0)
  INTO v_total_sales, v_cash_sales, v_cash_expenses
  FROM shift_operations
  WHERE shift_id = v_shift.id AND operation_type = 'sale';

  RETURN jsonb_build_object(
    'success', true, 'open', true,
    'shift', jsonb_build_object(
      'id', v_shift.id,
      'branch_id', v_shift.branch_id,
      'cashier_id', v_shift.cashier_id,
      'opened_at', v_shift.opened_at,
      'opening_amount', v_shift.opening_amount,
      'expected', v_shift.opening_amount + v_cash_sales - v_cash_expenses,
      'cash_sales', v_cash_sales,
      'total_sales', v_total_sales,
      'notes', v_shift.notes
    )
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- ============ 7. PROCESS SALE (with shift enforcement + logging) ============
-- Adds an optional p_shift_id. Cashiers MUST have an open shift for the sale
-- branch (found automatically when p_shift_id is NULL, so the frontend only
-- needs to pass it when explicitly chosen). Every paid sale is recorded in the
-- shift so the closing report reconciles the drawer.
CREATE OR REPLACE FUNCTION process_sale(
  p_invoice_number text,
  p_branch_id uuid,
  p_warehouse_id uuid,
  p_customer_id uuid,
  p_salesperson_id uuid,
  p_subtotal numeric,
  p_discount_amount numeric,
  p_discount_type text,
  p_tax_amount numeric,
  p_bonus_amount numeric,
  p_total numeric,
  p_paid_amount numeric,
  p_payment_method text,
  p_status text,
  p_items jsonb,
  p_shift_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_comp record;
  v_inv record;
  v_warehouse_ids uuid[];
  v_required numeric(14,4);
  v_available numeric(14,4);
  v_remaining numeric(14,4);
  v_deduct numeric(14,4);
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_cost numeric(12,2);
  v_product_type text;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      SELECT product_type INTO v_product_type FROM products WHERE id = v_product_id;
      IF v_product_type IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      IF v_product_type = 'manufactured' THEN
        IF NOT EXISTS (SELECT 1 FROM product_components WHERE product_id = v_product_id) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_RECIPE', 'product_id', v_product_id);
        END IF;
        FOR v_comp IN SELECT component_product_id, quantity FROM product_components WHERE product_id = v_product_id
        LOOP
          v_required := COALESCE(v_comp.quantity, 0) * v_quantity;
          SELECT COALESCE(SUM(quantity), 0) INTO v_available
          FROM inventory
          WHERE product_id = v_comp.component_product_id AND warehouse_id = ANY(v_warehouse_ids);
          IF v_available < v_required THEN
            RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_COMPONENT',
              'product_id', v_product_id, 'component_id', v_comp.component_product_id,
              'required', v_required, 'available', v_available);
          END IF;
        END LOOP;
      ELSE
        SELECT COALESCE(SUM(quantity), 0) INTO v_available
        FROM inventory
        WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
        IF v_available < v_quantity THEN
          RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
            'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
        END IF;
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 1: sale header =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      p_subtotal, p_discount_amount, p_discount_type, p_tax_amount, p_bonus_amount,
      p_total, p_paid_amount, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + locked stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
      v_discount_amount := COALESCE((v_item->>'discount_amount')::numeric, 0);
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := COALESCE((v_item->>'total')::numeric, v_quantity * v_unit_price - v_discount_amount);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      SELECT product_type INTO v_product_type FROM products WHERE id = v_product_id;

      IF v_product_type = 'manufactured' THEN
        FOR v_comp IN SELECT component_product_id, quantity FROM product_components WHERE product_id = v_product_id
        LOOP
          v_required := COALESCE(v_comp.quantity, 0) * v_quantity;
          v_remaining := v_required;
          SELECT cost_price INTO v_cost FROM products WHERE id = v_comp.component_product_id;

          FOR v_inv IN SELECT id, warehouse_id, quantity FROM inventory
            WHERE product_id = v_comp.component_product_id AND warehouse_id = ANY(v_warehouse_ids) AND quantity > 0
            ORDER BY quantity DESC
            FOR UPDATE
          LOOP
            IF v_remaining <= 0 THEN EXIT; END IF;
            v_deduct := LEAST(v_inv.quantity, v_remaining);
            v_before := v_inv.quantity;
            v_after := v_inv.quantity - v_deduct;
            UPDATE inventory SET quantity = v_after, updated_at = now() WHERE id = v_inv.id;
            INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
              component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
            VALUES (v_comp.component_product_id, v_inv.warehouse_id, p_branch_id, 'sale',
              true, 'sale', v_sale_id, -v_deduct, v_before, v_after, v_cost, auth.uid());
            v_remaining := v_remaining - v_deduct;
          END LOOP;

          IF v_remaining > 0 THEN
            RAISE EXCEPTION 'INSUFFICIENT_COMPONENT: product % needs % but only % available',
              v_product_id, v_required, (v_required - v_remaining);
          END IF;
        END LOOP;
      ELSE
        v_remaining := v_quantity;
        SELECT cost_price INTO v_cost FROM products WHERE id = v_product_id;

        FOR v_inv IN SELECT id, warehouse_id, quantity FROM inventory
          WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids) AND quantity > 0
          ORDER BY quantity DESC
          FOR UPDATE
        LOOP
          IF v_remaining <= 0 THEN EXIT; END IF;
          v_deduct := LEAST(v_inv.quantity, v_remaining);
          v_before := v_inv.quantity;
          v_after := v_inv.quantity - v_deduct;
          UPDATE inventory SET quantity = v_after, updated_at = now() WHERE id = v_inv.id;
          INSERT INTO stock_transactions (product_id, warehouse_id, branch_id, transaction_type,
            component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
          VALUES (v_product_id, v_inv.warehouse_id, p_branch_id, 'sale',
            false, 'sale', v_sale_id, -v_deduct, v_before, v_after, v_cost, auth.uid());
          v_remaining := v_remaining - v_deduct;
        END LOOP;

        IF v_remaining > 0 THEN
          RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
            v_product_id, v_quantity, (v_quantity - v_remaining);
        END IF;
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', COALESCE(p_paid_amount, 0), p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_COMPONENT%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_COMPONENT', 'detail', SQLERRM);
    ELSIF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$$;

-- ============ 8. USER MANAGEMENT RPCs (enterprise roles) ============

-- protect_last_admin: the last active super_admin/owner can never be removed
-- or demoted (including by themselves).
CREATE OR REPLACE FUNCTION protect_last_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_other_active_admins int;
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.role IN ('super_admin', 'owner') AND OLD.is_active THEN
      SELECT count(*) INTO v_other_active_admins
      FROM public.users
      WHERE role IN ('super_admin', 'owner') AND is_active AND id <> OLD.id;
      IF v_other_active_admins = 0 THEN
        RAISE EXCEPTION 'LAST_ADMIN';
      END IF;
    END IF;
    RETURN OLD;
  END IF;

  -- UPDATE
  IF OLD.role IN ('super_admin', 'owner') AND OLD.is_active
     AND (NEW.role NOT IN ('super_admin', 'owner') OR NOT NEW.is_active) THEN
    SELECT count(*) INTO v_other_active_admins
    FROM public.users
    WHERE role IN ('super_admin', 'owner') AND is_active AND id <> OLD.id;
    IF v_other_active_admins = 0 THEN
      RAISE EXCEPTION 'LAST_ADMIN';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_last_admin ON users;
CREATE TRIGGER trg_protect_last_admin
BEFORE UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION protect_last_admin();

-- create_user: admins create any user; branch managers can only create staff of
-- their OWN branch with a non-admin role. Creates auth account + app profile
-- atomically (same dynamic-column technique as before).
CREATE OR REPLACE FUNCTION create_user(
  p_email text,
  p_password text,
  p_full_name text DEFAULT NULL,
  p_role text DEFAULT 'cashier',
  p_branch_id uuid DEFAULT NULL,
  p_is_active boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_role text;
  v_hash text;
  v_email text;
  v_pgc_schema text;
  v_caller_role text;
  v_caller_branch uuid;
  v_u_cols text;
  v_u_vals text;
  v_i_cols text;
  v_i_vals text;
BEGIN
  SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();

  IF is_pos_admin() THEN
    NULL;
  ELSIF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
    -- branch manager: force their own branch and forbid admin roles
    IF p_branch_id IS NOT NULL AND p_branch_id <> v_caller_branch THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Branch managers can only create users in their own branch');
    END IF;
    IF p_role IN ('super_admin', 'owner') THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Only a super admin can create super_admin/owner accounts');
    END IF;
    p_branch_id := v_caller_branch;
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  v_email := lower(btrim(p_email));

  -- Email uniqueness (both auth accounts and app profiles)
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
  FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, %I.gen_salt($2, $3))', v_pgc_schema, v_pgc_schema)
    INTO v_hash USING p_password, 'bf', 10;

  v_role := CASE
    WHEN p_role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                    'warehouse_manager', 'kitchen', 'accountant', 'customer_display') THEN p_role
    ELSE 'cashier'
  END;

  -- A non-admin caller can only create staff accounts inside their own branch
  -- (admin roles were already rejected above).
  IF v_caller_role = 'branch_manager' THEN
    NULL;
  END IF;

  v_user_id := gen_random_uuid();

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_u_cols, v_u_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'instance_id' THEN '''00000000-0000-0000-0000-000000000000'''
        WHEN 'id' THEN quote_literal(v_user_id)
        WHEN 'aud' THEN '''authenticated'''
        WHEN 'role' THEN '''authenticated'''
        WHEN 'email' THEN quote_literal(v_email)
        WHEN 'encrypted_password' THEN quote_literal(v_hash)
        WHEN 'email_confirmed_at' THEN 'now()'
        WHEN 'confirmation_token' THEN ''''''
        WHEN 'recovery_token' THEN ''''''
        WHEN 'email_change' THEN ''''''
        WHEN 'email_change_token_new' THEN ''''''
        WHEN 'email_change_token_current' THEN ''''''
        WHEN 'raw_app_meta_data' THEN format('jsonb_build_object(''provider'',''email'',''providers'',array[''email'']::text[],''email'',%L)', v_email)
        WHEN 'raw_user_meta_data' THEN format('jsonb_build_object(''full_name'',%L,''email'',%L,''email_verified'',true)', p_full_name, v_email)
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'is_anonymous' THEN 'false'
        WHEN 'is_sso_user' THEN 'false'
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'users'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('instance_id','id','aud','role','email','encrypted_password','email_confirmed_at','confirmation_token','recovery_token','email_change','email_change_token_new','email_change_token_current','raw_app_meta_data','raw_user_meta_data','created_at','updated_at','is_anonymous','is_sso_user')
  ) c;

  IF v_u_cols IS NULL OR v_u_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.users');
  END IF;

  EXECUTE 'INSERT INTO auth.users (' || v_u_cols || ') VALUES (' || v_u_vals || ')';

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_i_cols, v_i_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'id' THEN 'gen_random_uuid()'
        WHEN 'provider_id' THEN quote_literal(v_user_id::text)
        WHEN 'user_id' THEN quote_literal(v_user_id)
        WHEN 'identity_data' THEN format('jsonb_build_object(''sub'',%L,''email'',%L)', v_user_id::text, v_email)
        WHEN 'provider' THEN '''email'''
        WHEN 'last_sign_in_at' THEN 'now()'
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'email' THEN quote_literal(v_email)
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'identities'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('id','provider_id','user_id','identity_data','provider','last_sign_in_at','created_at','updated_at','email')
  ) c;

  IF v_i_cols IS NULL OR v_i_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.identities');
  END IF;

  EXECUTE 'INSERT INTO auth.identities (' || v_i_cols || ') VALUES (' || v_i_vals || ')';

  INSERT INTO public.users (id, email, full_name, role, branch_id, is_active)
  VALUES (v_user_id, v_email, p_full_name, v_role, p_branch_id, p_is_active);

  RETURN jsonb_build_object('success', true, 'user_id', v_user_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- update_user_password: super_admin/owner for anyone; branch manager only for
-- non-admin staff of their own branch.
CREATE OR REPLACE FUNCTION update_user_password(p_user_id uuid, p_new_password text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hash text;
  v_pgc_schema text;
  v_caller_role text;
  v_caller_branch uuid;
  v_target_role text;
  v_target_branch uuid;
BEGIN
  IF NOT is_pos_admin() THEN
    SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();
    IF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
      SELECT role, branch_id INTO v_target_role, v_target_branch FROM public.users WHERE id = p_user_id;
      IF v_target_role IN ('super_admin', 'owner') OR v_target_branch IS DISTINCT FROM v_caller_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
          'detail', 'Branch managers can only change passwords of staff in their own branch');
      END IF;
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
    END IF;
  END IF;

  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RETURN jsonb_build_object('success', false, 'error', 'WEAK_PASSWORD');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
  FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, %I.gen_salt($2, $3))', v_pgc_schema, v_pgc_schema)
    INTO v_hash USING p_new_password, 'bf', 10;

  UPDATE auth.users
  SET encrypted_password = v_hash, updated_at = now()
  WHERE id = p_user_id;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'sessions') THEN
    DELETE FROM auth.sessions WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM = 'LAST_ADMIN' THEN
    RETURN jsonb_build_object('success', false, 'error', 'LAST_ADMIN');
  END IF;
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- delete_user: super_admin/owner for anyone; branch manager only for non-admin
-- staff of their own branch. App profile is deleted first so the last-admin
-- trigger still guards the transaction.
CREATE OR REPLACE FUNCTION delete_user(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role text;
  v_caller_branch uuid;
  v_target_role text;
  v_target_branch uuid;
BEGIN
  IF NOT is_pos_admin() THEN
    SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();
    IF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
      SELECT role, branch_id INTO v_target_role, v_target_branch FROM public.users WHERE id = p_user_id;
      IF v_target_role IN ('super_admin', 'owner') OR v_target_branch IS DISTINCT FROM v_caller_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
          'detail', 'Branch managers can only delete staff in their own branch');
      END IF;
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
    END IF;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;

  DELETE FROM public.users WHERE id = p_user_id;

  DELETE FROM auth.users WHERE id = p_user_id;

  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM = 'LAST_ADMIN' THEN
    RETURN jsonb_build_object('success', false, 'error', 'LAST_ADMIN');
  END IF;
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- Refresh the PostgREST schema cache so new tables/constraints (shifts, users FKs)
-- are immediately available to the API without a manual reload.
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 005_sales_user_fks.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- Sales -> users foreign keys (cashier / salesperson)
-- ----------------------------------------------------------------------------
-- On the live database these two constraints existed (the frontend embeds
-- users!fk_sales_cashier, created by renaming sales_cashier_id_fkey in
-- fk_cleanup), but no tracked migration creates them. This file makes a fresh
-- build match the live state before fk_cleanup runs its renames.
-- Additive + idempotent: guarded, creates nothing that already exists.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_cashier_id_fkey' AND conrelid = 'public.sales'::regclass
  ) THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_cashier_id_fkey
      FOREIGN KEY (cashier_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_salesperson_id_fkey' AND conrelid = 'public.sales'::regclass
  ) THEN
    ALTER TABLE public.sales
      ADD CONSTRAINT sales_salesperson_id_fkey
      FOREIGN KEY (salesperson_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END $$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 006_fk_cleanup.sql
-- ----------------------------------------------------------------------------

-- =============================================================
-- Migration: FK naming cleanup + inventory branch_id
--
--   1. Renames the default Postgres FK names to explicit, readable
--      names so PostgREST embed hints are stable and self-documenting.
--   2. Adds branch_id to inventory (NOT NULL, backfilled from the
--      row's warehouse branch) and rewrites inventory RLS to the
--      clean single pattern: is_pos_admin() OR branch_id = get_branch_id()
--
-- The renamed FKs must be matched in the frontend embed hints:
--   src/pages/ReportsPage.tsx:132,176  users!sales_cashier_id_fkey
--     ->  users!fk_sales_cashier
-- =============================================================

BEGIN;

-- ---------- 1. RENAME FOREIGN KEY CONSTRAINTS ----------
ALTER TABLE public.products    RENAME CONSTRAINT products_branch_id_fkey      TO fk_products_branch;
ALTER TABLE public.sales       RENAME CONSTRAINT sales_branch_id_fkey         TO fk_sales_branch;
ALTER TABLE public.sales       RENAME CONSTRAINT sales_cashier_id_fkey        TO fk_sales_cashier;
ALTER TABLE public.sales       RENAME CONSTRAINT sales_salesperson_id_fkey    TO fk_sales_salesperson;
ALTER TABLE public.sale_items  RENAME CONSTRAINT sale_items_product_id_fkey   TO fk_sale_item_product;
ALTER TABLE public.inventory   RENAME CONSTRAINT inventory_product_id_fkey    TO fk_stock_product;
ALTER TABLE public.purchases   RENAME CONSTRAINT purchases_supplier_id_fkey   TO fk_purchase_supplier;

-- ---------- 2. INVENTORY branch_id (NOT NULL, backfilled from warehouse) ----------
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES public.branches(id) ON DELETE RESTRICT;

UPDATE public.inventory i
SET branch_id = w.branch_id
FROM public.warehouses w
WHERE w.id = i.warehouse_id AND i.branch_id IS NULL;

-- Safety: never leave a stock row without a branch (the warehouse must belong
-- to a branch). Failing here rolls the whole migration back.
ALTER TABLE public.inventory ALTER COLUMN branch_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_inventory_branch ON public.inventory(branch_id);

-- ---------- 3. INVENTORY RLS (clean single pattern via inventory.branch_id) ----------
DROP POLICY IF EXISTS "auth_select_inventory" ON public.inventory;
DROP POLICY IF EXISTS "auth_insert_inventory" ON public.inventory;
DROP POLICY IF EXISTS "auth_update_inventory" ON public.inventory;
DROP POLICY IF EXISTS "auth_delete_inventory" ON public.inventory;

CREATE POLICY "auth_select_inventory" ON public.inventory FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "auth_insert_inventory" ON public.inventory FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "auth_update_inventory" ON public.inventory FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "auth_delete_inventory" ON public.inventory FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

COMMIT;

-- Refresh the PostgREST schema cache so the renamed FKs / new column are live
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 007_pin_login.sql
-- ----------------------------------------------------------------------------

-- Migration: Username + 4-digit PIN login
-- Run this in the Supabase SQL Editor AFTER migration_enterprise_core.sql.
--
-- Adds:
--   1. `public.users.username` column (lowercase, unique).
--   2. Backfill: existing accounts get a username from their email prefix.
--   3. `get_login_email(username)` â€” anon-callable lookup used by the login page.
--   4. `create_user` now accepts `p_username`.
--   5. `update_user_password` now accepts 4-digit PINs.

-- ============ 1. USERNAME COLUMN ============
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username text;

-- Refresh the PostgREST schema cache immediately so the new column is usable
-- right away even if a later statement below fails (also repeated at the end).
NOTIFY pgrst, 'reload schema';

-- Backfill existing accounts from their email prefix (deduplicated).
WITH numbered AS (
  SELECT id, lower(split_part(email, '@', 1)) AS base,
         row_number() OVER (PARTITION BY lower(split_part(email, '@', 1)) ORDER BY created_at) AS rn
  FROM public.users
  WHERE username IS NULL OR btrim(username) = ''
)
UPDATE public.users u
SET username = CASE WHEN n.rn = 1 THEN n.base ELSE n.base || '_' || n.rn END
FROM numbered n
WHERE u.id = n.id;

-- Sanitize every username to the allowed charset so the unique index / CHECK
-- constraint below can NEVER fail on existing data (e.g. '+' or Arabic letters
-- in an email prefix would otherwise abort this script before the final reload).
WITH cleaned AS (
  SELECT id,
         regexp_replace(
           regexp_replace(lower(btrim(COALESCE(username, ''))), '[^a-z0-9._-]', '_', 'g'),
           '^[._-]+', '', 'g'
         ) AS clean
  FROM public.users
)
UPDATE public.users u
SET username = CASE WHEN c.clean = '' THEN 'user' || replace(u.id::text, '-', '') ELSE c.clean END
FROM cleaned c
WHERE u.id = c.id;

-- Final dedup after sanitization (very rare: 'a.b' and 'a_b' both become 'a_b').
WITH dup AS (
  SELECT id, row_number() OVER (PARTITION BY username ORDER BY created_at) AS rn
  FROM public.users
  WHERE username IS NOT NULL
)
UPDATE public.users u
SET username = u.username || '_' || d.rn
FROM dup d
WHERE u.id = d.id AND d.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS users_username_uniq_idx ON public.users (username);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_username_format_check;
ALTER TABLE public.users ADD CONSTRAINT users_username_format_check
  CHECK (username IS NULL OR username ~ '^[a-z0-9][a-z0-9._-]*$');

-- ============ 2. LOGIN LOOKUP (anon-callable) ============
-- Returns the email for a username so the client can call
-- auth.signInWithPassword(email, pin). SECURITY DEFINER bypasses RLS.
CREATE OR REPLACE FUNCTION get_login_email(p_username text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user public.users%ROWTYPE;
BEGIN
  SELECT * INTO v_user FROM public.users WHERE username = lower(btrim(p_username));
  IF v_user.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;
  IF NOT v_user.is_active THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_INACTIVE');
  END IF;
  RETURN jsonb_build_object('success', true, 'email', v_user.email);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_login_email(text) TO anon, authenticated;

-- ============ 3. create_user: add p_username ============
CREATE OR REPLACE FUNCTION create_user(
  p_email text,
  p_password text,
  p_full_name text DEFAULT NULL,
  p_role text DEFAULT 'cashier',
  p_branch_id uuid DEFAULT NULL,
  p_is_active boolean DEFAULT true,
  p_username text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_role text;
  v_hash text;
  v_email text;
  v_username text;
  v_pgc_schema text;
  v_caller_role text;
  v_caller_branch uuid;
  v_u_cols text;
  v_u_vals text;
  v_i_cols text;
  v_i_vals text;
BEGIN
  SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();

  IF is_pos_admin() THEN
    NULL;
  ELSIF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
    -- branch manager: force their own branch and forbid admin roles
    IF p_branch_id IS NOT NULL AND p_branch_id <> v_caller_branch THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Branch managers can only create users in their own branch');
    END IF;
    IF p_role IN ('super_admin', 'owner') THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Only a super admin can create super_admin/owner accounts');
    END IF;
    p_branch_id := v_caller_branch;
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  v_email := lower(btrim(p_email));

  -- Email uniqueness (both auth accounts and app profiles)
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;

  -- Username: default to email prefix, sanitized, must be unique
  v_username := regexp_replace(
    regexp_replace(lower(btrim(coalesce(NULLIF(p_username, ''), split_part(v_email, '@', 1)))), '[^a-z0-9._-]', '_', 'g'),
    '^[._-]+', '', 'g'
  );
  IF v_username = '' THEN
    v_username := 'user' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE username = v_username) THEN
    RETURN jsonb_build_object('success', false, 'error', 'USERNAME_TAKEN');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
  FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, %I.gen_salt($2, $3))', v_pgc_schema, v_pgc_schema)
    INTO v_hash USING p_password, 'bf', 10;

  v_role := CASE
    WHEN p_role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                    'warehouse_manager', 'kitchen', 'accountant', 'customer_display') THEN p_role
    ELSE 'cashier'
  END;

  v_user_id := gen_random_uuid();

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_u_cols, v_u_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'instance_id' THEN '''00000000-0000-0000-0000-000000000000'''
        WHEN 'id' THEN quote_literal(v_user_id)
        WHEN 'aud' THEN '''authenticated'''
        WHEN 'role' THEN '''authenticated'''
        WHEN 'email' THEN quote_literal(v_email)
        WHEN 'encrypted_password' THEN quote_literal(v_hash)
        WHEN 'email_confirmed_at' THEN 'now()'
        WHEN 'confirmation_token' THEN ''''''
        WHEN 'recovery_token' THEN ''''''
        WHEN 'email_change' THEN ''''''
        WHEN 'email_change_token_new' THEN ''''''
        WHEN 'email_change_token_current' THEN ''''''
        WHEN 'raw_app_meta_data' THEN format('jsonb_build_object(''provider'',''email'',''providers'',array[''email'']::text[],''email'',%L)', v_email)
        WHEN 'raw_user_meta_data' THEN format('jsonb_build_object(''full_name'',%L,''email'',%L,''email_verified'',true)', p_full_name, v_email)
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'is_anonymous' THEN 'false'
        WHEN 'is_sso_user' THEN 'false'
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'users'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('instance_id','id','aud','role','email','encrypted_password','email_confirmed_at','confirmation_token','recovery_token','email_change','email_change_token_new','email_change_token_current','raw_app_meta_data','raw_user_meta_data','created_at','updated_at','is_anonymous','is_sso_user')
  ) c;

  IF v_u_cols IS NULL OR v_u_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.users');
  END IF;

  EXECUTE 'INSERT INTO auth.users (' || v_u_cols || ') VALUES (' || v_u_vals || ')';

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_i_cols, v_i_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'id' THEN 'gen_random_uuid()'
        WHEN 'provider_id' THEN quote_literal(v_user_id::text)
        WHEN 'user_id' THEN quote_literal(v_user_id)
        WHEN 'identity_data' THEN format('jsonb_build_object(''sub'',%L,''email'',%L)', v_user_id::text, v_email)
        WHEN 'provider' THEN '''email'''
        WHEN 'last_sign_in_at' THEN 'now()'
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'email' THEN quote_literal(v_email)
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'identities'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('id','provider_id','user_id','identity_data','provider','last_sign_in_at','created_at','updated_at','email')
  ) c;

  IF v_i_cols IS NULL OR v_i_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.identities');
  END IF;

  EXECUTE 'INSERT INTO auth.identities (' || v_i_cols || ') VALUES (' || v_i_vals || ')';

  INSERT INTO public.users (id, email, username, full_name, role, branch_id, is_active)
  VALUES (v_user_id, v_email, v_username, p_full_name, v_role, p_branch_id, p_is_active);

  RETURN jsonb_build_object('success', true, 'user_id', v_user_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- ============ 4. update_user_password: allow 4-digit PINs ============
CREATE OR REPLACE FUNCTION update_user_password(p_user_id uuid, p_new_password text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hash text;
  v_pgc_schema text;
  v_caller_role text;
  v_caller_branch uuid;
  v_target_role text;
  v_target_branch uuid;
BEGIN
  IF NOT is_pos_admin() THEN
    SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();
    IF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
      SELECT role, branch_id INTO v_target_role, v_target_branch FROM public.users WHERE id = p_user_id;
      IF v_target_role IN ('super_admin', 'owner') OR v_target_branch IS DISTINCT FROM v_caller_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
          'detail', 'Branch managers can only change PINs of staff in their own branch');
      END IF;
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
    END IF;
  END IF;

  IF p_new_password IS NULL OR char_length(p_new_password) < 4 THEN
    RETURN jsonb_build_object('success', false, 'error', 'WEAK_PASSWORD');
  END IF;
  IF char_length(p_new_password) = 4 AND p_new_password !~ '^[0-9]{4}$' THEN
    RETURN jsonb_build_object('success', false, 'error', 'WEAK_PASSWORD');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
  FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, %I.gen_salt($2, $3))', v_pgc_schema, v_pgc_schema)
    INTO v_hash USING p_new_password, 'bf', 10;

  UPDATE auth.users
  SET encrypted_password = v_hash, updated_at = now()
  WHERE id = p_user_id;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'sessions') THEN
    DELETE FROM auth.sessions WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
  IF SQLERRM = 'LAST_ADMIN' THEN
    RETURN jsonb_build_object('success', false, 'error', 'LAST_ADMIN');
  END IF;
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- Refresh the PostgREST schema cache.
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 008_fix_login.sql
-- ----------------------------------------------------------------------------

-- Migration: Fix login for users created by create_user RPC
-- Run this in Supabase SQL Editor AFTER migration_enterprise_core.sql.
--
-- Even after the instance_id / provider_id fixes, a freshly created account can
-- still fail to sign in when ANY piece of the auth.users row is inconsistent
-- (NULL token column, missing email identity, wrong provider_id, unconfirmed
-- email, missing email_verified meta, wrong aud/role...).
--
-- This migration ships three admin-only tools (all SECURITY DEFINER, they call
-- is_pos_admin() first):
--   * verify_auth_account(user_id)  -> full health report (JSON)
--   * repair_auth_account(user_id)  -> fixes everything in one transaction
--   * password_matches(user_id, pw) -> bcrypt check (resolves pgcrypto schema)

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- ============ 1. VERIFY AUTH ACCOUNT ============
-- Returns a health report so we can see exactly why a login fails.
CREATE OR REPLACE FUNCTION verify_auth_account(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row record;
  v_identity record;
  v_pgc_schema text;
BEGIN
  -- Only admins can run diagnostics
  IF NOT public.is_pos_admin() THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT email, encrypted_password, aud, role, instance_id,
         email_confirmed_at, confirmation_token, recovery_token,
         email_change, email_change_token_new, email_change_token_current,
         raw_user_meta_data
    INTO v_row
    FROM auth.users WHERE id = p_user_id;

  IF v_row IS NULL OR v_row.email IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND',
      'hint', 'No row found in auth.users for this id');
  END IF;

  SELECT provider, provider_id, user_id, identity_data, email
    INTO v_identity
    FROM auth.identities
    WHERE user_id = p_user_id AND provider = 'email'
    ORDER BY created_at LIMIT 1;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
    FROM pg_extension WHERE extname = 'pgcrypto';

  RETURN jsonb_build_object(
    'success', true,
    'email', v_row.email,
    'aud', v_row.aud,
    'auth_role', v_row.role,
    'instance_ok', COALESCE(v_row.instance_id, '') = '00000000-0000-0000-0000-000000000000',
    'confirmed', v_row.email_confirmed_at IS NOT NULL,
    'tokens_ok', v_row.confirmation_token IS NOT NULL
                 AND v_row.recovery_token IS NOT NULL
                 AND v_row.email_change IS NOT NULL
                 AND v_row.email_change_token_new IS NOT NULL
                 AND v_row.email_change_token_current IS NOT NULL,
    'email_verified_meta', COALESCE(v_row.raw_user_meta_data->>'email_verified', 'false') = 'true',
    'hash_present', v_row.encrypted_password IS NOT NULL AND v_row.encrypted_password <> '',
    'hash_prefix', left(COALESCE(v_row.encrypted_password, ''), 4),
    'app_profile', EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id),
    'identity_exists', v_identity IS NOT NULL,
    'identity_provider_ok', v_identity IS NULL OR v_identity.provider_id = p_user_id::text,
    'identity_sub_ok', v_identity IS NULL OR COALESCE(v_identity.identity_data->>'sub', '') = p_user_id::text,
    'identity_email_ok', v_identity IS NULL OR lower(COALESCE(v_identity.email, v_identity.identity_data->>'email', '')) = lower(v_row.email),
    'pgcrypto_schema', v_pgc_schema
  );
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- ============ 2. REPAIR AUTH ACCOUNT ============
-- Fixes every known login-blocking inconsistency in one transaction, then
-- returns the verify report again so you can confirm everything is green.
CREATE OR REPLACE FUNCTION repair_auth_account(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
  v_i_cols text;
  v_i_vals text;
BEGIN
  -- Only admins can repair accounts
  IF NOT public.is_pos_admin() THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = p_user_id;
  IF v_email IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;

  -- 1. instance_id: GoTrue looks users up by the default instance UUID; NULL never matches
  UPDATE auth.users SET instance_id = '00000000-0000-0000-0000-000000000000'
    WHERE id = p_user_id AND instance_id IS DISTINCT FROM '00000000-0000-0000-0000-000000000000';

  -- 2. token columns -> '' (GoTrue scans them as strings, NULL breaks login)
  UPDATE auth.users SET
    confirmation_token       = COALESCE(confirmation_token, ''),
    recovery_token           = COALESCE(recovery_token, ''),
    email_change             = COALESCE(email_change, ''),
    email_change_token_new   = COALESCE(email_change_token_new, ''),
    email_change_token_current = COALESCE(email_change_token_current, '')
    WHERE id = p_user_id;

  -- 3. confirm the email
  UPDATE auth.users SET email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = p_user_id;

  -- 4. aud / role must be 'authenticated'
  UPDATE auth.users SET aud = COALESCE(NULLIF(aud, ''), 'authenticated'),
                        role = COALESCE(NULLIF(role, ''), 'authenticated')
    WHERE id = p_user_id;

  -- 5. mark email as verified in metadata
  UPDATE auth.users SET raw_user_meta_data =
      jsonb_set(COALESCE(raw_user_meta_data, '{}'::jsonb), '{email_verified}', 'true', true)
    WHERE id = p_user_id;

  -- 6. ensure the email identity exists with provider_id = user_id::text and sub = user_id::text
  IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = p_user_id AND provider = 'email') THEN
    SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
    INTO v_i_cols, v_i_vals
    FROM (
      SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
        CASE cols.column_name
          WHEN 'id' THEN 'gen_random_uuid()'
          WHEN 'provider_id' THEN quote_literal(p_user_id::text)
          WHEN 'user_id' THEN quote_literal(p_user_id)
          WHEN 'identity_data' THEN format('jsonb_build_object(''sub'',%L,''email'',%L)', p_user_id::text, v_email)
          WHEN 'provider' THEN '''email'''
          WHEN 'last_sign_in_at' THEN 'now()'
          WHEN 'created_at' THEN 'now()'
          WHEN 'updated_at' THEN 'now()'
          WHEN 'email' THEN quote_literal(v_email)
        END AS val
      FROM information_schema.columns cols
      WHERE cols.table_schema = 'auth' AND cols.table_name = 'identities'
        AND cols.is_generated = 'NEVER'
        AND cols.column_name IN ('id','provider_id','user_id','identity_data','provider','last_sign_in_at','created_at','updated_at','email')
    ) c;

    IF v_i_cols IS NOT NULL AND v_i_vals IS NOT NULL THEN
      EXECUTE 'INSERT INTO auth.identities (' || v_i_cols || ') VALUES (' || v_i_vals || ')';
    END IF;
  ELSE
    UPDATE auth.identities
    SET provider_id = p_user_id::text,
        email = v_email,
        identity_data = jsonb_build_object('sub', p_user_id::text, 'email', v_email)
    WHERE user_id = p_user_id AND provider = 'email';
  END IF;

  -- Return the post-repair health report
  RETURN public.verify_auth_account(p_user_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;

-- ============ 3. PASSWORD MATCH CHECK ============
-- Tests whether a stored bcrypt hash matches a given password. Resolves the
-- pgcrypto schema at runtime so it works on any Supabase project.
CREATE OR REPLACE FUNCTION password_matches(p_user_id uuid, p_password text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hash text;
  v_pgc_schema text;
  v_ok boolean;
BEGIN
  IF NOT public.is_pos_admin() THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT encrypted_password INTO v_hash FROM auth.users WHERE id = p_user_id;
  IF v_hash IS NULL OR v_hash = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND',
      'hint', 'No encrypted_password stored for this user');
  END IF;

  IF p_password IS NULL OR p_password = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMPTY_PASSWORD');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
    FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, $2) = $2', v_pgc_schema) INTO v_ok USING p_password, v_hash;

  RETURN jsonb_build_object('success', true, 'matched', COALESCE(v_ok, false),
    'hint', CASE WHEN COALESCE(v_ok, false) THEN 'Password matches the stored hash' ELSE 'Password does NOT match the stored hash' END);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 009_roles.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- Roles table + role helpers (get_user_role / can_permission)
-- ----------------------------------------------------------------------------
-- The `roles` permission matrix and the two helper functions it backs were
-- defined by the legacy migration_audit_fixes.sql (now archived in legacy/).
-- The live D-series and manufacturing/accounting RPCs depend on all three, so
-- a fresh build must create them too. This file is additive and idempotent:
--   * roles table + RLS, seeded with the six base roles (ON CONFLICT DO NOTHING
--     preserves any edits made from Settings);
--   * get_user_role()  - the role of the current user;
--   * can_permission() - permission lookup in the roles matrix.
-- production_manager is inserted later by 010_manufacturing_schema.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.roles (
  role text PRIMARY KEY,
  name_ar text NOT NULL,
  name_en text NOT NULL,
  permissions jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth_select_roles" ON public.roles;
CREATE POLICY "auth_select_roles" ON public.roles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "auth_write_roles" ON public.roles;
CREATE POLICY "auth_write_roles" ON public.roles FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_write_roles_upd" ON public.roles;
CREATE POLICY "auth_write_roles_upd" ON public.roles FOR UPDATE TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_write_roles_del" ON public.roles;
CREATE POLICY "auth_write_roles_del" ON public.roles FOR DELETE TO authenticated USING (is_pos_admin());

INSERT INTO public.roles (role, name_ar, name_en, permissions) VALUES
  ('super_admin', 'Ù…Ø¯ÙŠØ± Ø¹Ø§Ù…', 'Super Admin',
   '["dashboard.view","pos.sell","products.view","products.manage","products.assign","categories.view","categories.manage","components.view","components.manage","purchases.view","purchases.manage","inventory.view","inventory.manage","warehouses.view","warehouses.manage","customers.view","customers.manage","suppliers.view","suppliers.manage","expenses.view","expenses.manage","sales.view","refunds.approve","reports.view","shifts.view","shifts.open","shifts.close","shifts.manage","users.view","users.manage","audit.view","settings.manage","branches.manage"]'::jsonb),
  ('owner', 'Ù…Ø§Ù„Ùƒ', 'Owner',
   '["dashboard.view","pos.sell","products.view","products.manage","products.assign","categories.view","categories.manage","components.view","components.manage","purchases.view","purchases.manage","inventory.view","inventory.manage","warehouses.view","warehouses.manage","customers.view","customers.manage","suppliers.view","suppliers.manage","expenses.view","expenses.manage","sales.view","refunds.approve","reports.view","shifts.view","shifts.open","shifts.close","shifts.manage","users.view","users.manage","audit.view","settings.manage","branches.manage"]'::jsonb),
  ('branch_manager', 'Ù…Ø¯ÙŠØ± ÙØ±Ø¹', 'Branch Manager',
   '["dashboard.view","pos.sell","products.view","products.manage","categories.view","categories.manage","components.view","components.manage","purchases.view","purchases.manage","inventory.view","inventory.manage","warehouses.view","warehouses.manage","customers.view","customers.manage","suppliers.view","suppliers.manage","expenses.view","expenses.manage","sales.view","refunds.approve","shifts.view","shifts.open","shifts.close","shifts.manage","reports.view","users.view","users.manage"]'::jsonb),
  ('cashier', 'Ø£Ù…ÙŠÙ† ØµÙ†Ø¯ÙˆÙ‚', 'Cashier',
   '["dashboard.view","pos.sell","products.view","customers.view","customers.manage","inventory.view","sales.view","shifts.view","shifts.open","shifts.close"]'::jsonb),
  ('warehouse_manager', 'Ù…Ø¯ÙŠØ± Ù…Ø®Ø§Ø²Ù†', 'Warehouse Manager',
   '["dashboard.view","products.view","products.manage","categories.view","categories.manage","components.view","components.manage","inventory.view","inventory.manage","warehouses.view","warehouses.manage","purchases.view","purchases.manage","suppliers.view","suppliers.manage","shifts.view"]'::jsonb),
  ('accountant', 'Ù…Ø­Ø§Ø³Ø¨', 'Accountant',
   '["dashboard.view","sales.view","purchases.view","expenses.view","expenses.manage","inventory.view","customers.view","suppliers.view","reports.view","shifts.view"]'::jsonb)
ON CONFLICT (role) DO NOTHING;

-- Role of the current user (NULL for anonymous / unknown).
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path TO 'public'
AS $fn$
  SELECT role FROM public.users WHERE users.id = auth.uid();
$fn$;

-- Does the current user hold a dotted permission? Admins always pass.
CREATE OR REPLACE FUNCTION public.can_permission(p_permission text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $fn$
  SELECT is_pos_admin() OR EXISTS (
    SELECT 1 FROM public.users u
    JOIN public.roles r ON r.role = u.role
    WHERE u.id = auth.uid() AND r.permissions ? p_permission
  );
$fn$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 010_document_serials.sql
-- ----------------------------------------------------------------------------

-- Migration: Sequential document serials (invoices & purchase invoices)
-- Run this in the Supabase SQL Editor AFTER migration_pin_login.sql (or any setup).
--
-- Adds:
--   1. `document_sequences` â€” atomic counters per document type (`sale`, `purchase`).
--   2. `next_document_number(p_type)` â€” returns `<store_name>-<NNNNN>` serial that
--      increments atomically (never duplicated, even under concurrency).
--
-- The POS / Purchases pages call this RPC just before creating a document, so the
-- number shown on the invoice, the receipt and in the lists is the store name + a
-- continuous sequential number (e.g. "Premier-00001").

-- ============ 1. SEQUENCE COUNTERS ============
CREATE TABLE IF NOT EXISTS public.document_sequences (
  seq_type   text PRIMARY KEY,
  next_value bigint NOT NULL DEFAULT 1
);

-- Seed the two default counters (no-op if they already exist).
INSERT INTO public.document_sequences (seq_type, next_value)
VALUES ('sale', 1), ('purchase', 1)
ON CONFLICT (seq_type) DO NOTHING;

-- ============ 2. ATOMIC SERIAL GENERATOR ============
-- SECURITY DEFINER so `authenticated` callers can use the counter without direct
-- table access. Allocates the next number atomically (row UPDATE ... RETURNING),
-- so concurrent calls never collide. Falls back to a robust upsert if a counter
-- row is missing for a given type.
CREATE OR REPLACE FUNCTION public.next_document_number(p_type text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_store text;
  v_num   bigint;
BEGIN
  IF p_type NOT IN ('sale', 'purchase') THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_TYPE');
  END IF;

  LOOP
    UPDATE public.document_sequences
       SET next_value = next_value + 1
     WHERE seq_type = p_type
    RETURNING next_value - 1 INTO v_num;
    EXIT WHEN v_num IS NOT NULL;

    -- Counter row missing: create it (first number = 1) and retry.
    INSERT INTO public.document_sequences (seq_type, next_value)
    VALUES (p_type, 2)
    ON CONFLICT (seq_type) DO NOTHING;
  END LOOP;

  SELECT btrim(coalesce(store_name, '')) INTO v_store FROM public.settings LIMIT 1;
  IF v_store IS NULL OR v_store = '' THEN
    v_store := 'POS';
  END IF;

  RETURN jsonb_build_object('success', true, 'number', v_store || '-' || lpad(v_num::text, 5, '0'), 'raw', v_num);
END;
$$;

REVOKE ALL ON FUNCTION public.next_document_number(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.next_document_number(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.next_document_number(text) TO authenticated;

-- Refresh the PostgREST schema cache so the new RPC is callable immediately.
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 011_manufacturing_schema.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase B1: Manufacturing, Warehouses, Batches & Inventory Ledger schema
-- =====================================================================
-- Adds: units, raw_materials, raw_material_inventory, raw_material_batches,
--       recipes, recipe_items, production_orders, production_waste,
--       warehouse_transfers, warehouse_transfer_items, inventory_batches,
--       inventory_ledger, batch columns on inventory, warehouses.warehouse_type,
--       document sequences for production_order/transfer, production_manager role.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Shared updated_at trigger function
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 2. Units of measure (global master data)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.units (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text NOT NULL UNIQUE,
  name        text NOT NULL UNIQUE,
  symbol      text,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.units IS 'ÙˆØ­Ø¯Ø§Øª Ø§Ù„Ù‚ÙŠØ§Ø³ (Ù‚Ø·Ø¹Ø©ØŒ ÙƒÙŠÙ„ÙˆØŒ Ù„ØªØ±ØŒ ÙƒØ±ØªÙˆÙ†Ø© ...)';

INSERT INTO public.units (code, name, symbol) VALUES
  ('PCS', 'Ù‚Ø·Ø¹Ø©', 'Ù‚Ø·Ø¹Ø©'),
  ('UNIT', 'ÙˆØ­Ø¯Ø©', 'ÙˆØ­Ø¯Ø©'),
  ('KG', 'ÙƒÙŠÙ„ÙˆØºØ±Ø§Ù…', 'ÙƒØ¬Ù…'),
  ('GM', 'Ø¬Ø±Ø§Ù…', 'Ø¬Ù…'),
  ('LITR', 'Ù„ØªØ±', 'Ù„ØªØ±'),
  ('ML', 'Ù…Ù„Ù„ÙŠÙ„ØªØ±', 'Ù…Ù„'),
  ('BOX', 'ØµÙ†Ø¯ÙˆÙ‚', 'ØµÙ†Ø¯ÙˆÙ‚'),
  ('CARTON', 'ÙƒØ±ØªÙˆÙ†Ø©', 'ÙƒØ±ØªÙˆÙ†Ø©'),
  ('PACK', 'ÙƒÙŠØ³', 'ÙƒÙŠØ³'),
  ('BAG', 'Ø´Ù†Ø·Ø©', 'Ø´Ù†Ø·Ø©'),
  ('BOTTLE', 'Ø²Ø¬Ø§Ø¬Ø©', 'Ø²Ø¬Ø§Ø¬Ø©'),
  ('CAN', 'Ø¹Ù„Ø¨Ø©', 'Ø¹Ù„Ø¨Ø©'),
  ('JAR', 'Ø¨Ø±Ø·Ù…Ø§Ù†', 'Ø¨Ø±Ø·Ù…Ø§Ù†'),
  ('CUP', 'ÙƒÙˆØ¨', 'ÙƒÙˆØ¨'),
  ('PLATE', 'Ø·Ø¨Ù‚', 'Ø·Ø¨Ù‚'),
  ('TRAY', 'ØµÙŠÙ†ÙŠØ©', 'ØµÙŠÙ†ÙŠØ©'),
  ('DOZEN', 'Ø¯Ø³ØªØ©', 'Ø¯Ø³ØªØ©'),
  ('CASE', 'Ø¯Ø±Ø¨ÙƒØ©', 'Ø¯Ø±Ø¨ÙƒØ©'),
  ('ROLL', 'Ù„ÙØ©', 'Ù„ÙØ©'),
  ('TIN', 'ØªÙ†ÙƒØ©', 'ØªÙ†ÙƒØ©'),
  ('BUNDLE', 'Ø­Ø²Ù…Ø©', 'Ø­Ø²Ù…Ø©'),
  ('PORTION', 'Ø­ØµØ©', 'Ø­ØµØ©')
ON CONFLICT (code) DO NOTHING;

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "units_select" ON public.units
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "units_write" ON public.units
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 3. Raw materials (global master data) + branch-scoped stock
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.raw_materials (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code          text NOT NULL UNIQUE,
  name          text NOT NULL,
  unit_id       uuid REFERENCES public.units(id) ON DELETE SET NULL,
  category      text,
  min_stock     numeric(14,4) NOT NULL DEFAULT 0,
  default_cost  numeric(12,2) NOT NULL DEFAULT 0,
  description   text,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.raw_materials IS 'Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù… (Ù…Ø®Ø²ÙˆÙ† Ø§Ù„Ù…ÙˆØ§Ø¯)';

CREATE INDEX IF NOT EXISTS idx_raw_materials_name ON public.raw_materials (name);
CREATE INDEX IF NOT EXISTS idx_raw_materials_active ON public.raw_materials (is_active);

ALTER TABLE public.raw_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "raw_materials_select" ON public.raw_materials
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "raw_materials_write" ON public.raw_materials
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

CREATE TRIGGER trg_raw_materials_updated BEFORE UPDATE ON public.raw_materials
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------
-- 4. Raw material inventory (aggregate per branch) + batches (lots)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.raw_material_inventory (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_material_id   uuid NOT NULL REFERENCES public.raw_materials(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  quantity          numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  avg_cost          numeric(12,2) NOT NULL DEFAULT 0,
  min_stock         numeric(14,4) NOT NULL DEFAULT 0,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (raw_material_id, branch_id)
);
COMMENT ON TABLE public.raw_material_inventory IS 'Ø±ØµÙŠØ¯ Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù… Ù„ÙƒÙ„ ÙØ±Ø¹ (Ø±ØµÙŠØ¯ Ø¥Ø¬Ù…Ø§Ù„ÙŠ + Ù…ØªÙˆØ³Ø· Ø§Ù„ØªÙƒÙ„ÙØ©)';

CREATE INDEX IF NOT EXISTS idx_raw_inv_branch ON public.raw_material_inventory (branch_id);

ALTER TABLE public.raw_material_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "raw_material_inventory_select" ON public.raw_material_inventory
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "raw_material_inventory_write" ON public.raw_material_inventory
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

CREATE TABLE IF NOT EXISTS public.raw_material_batches (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_material_id   uuid NOT NULL REFERENCES public.raw_materials(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  batch_number      text,
  quantity          numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  unit_cost         numeric(12,2) NOT NULL DEFAULT 0,
  production_date   date,
  expiry_date       date,
  source_type       text NOT NULL DEFAULT 'purchase',
  source_id         uuid,
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.raw_material_batches IS 'Ø¯ÙØ¹Ø§Øª Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù… (Ø§Ù„Ø§Ø³ØªÙ‡Ù„Ø§Ùƒ Ø¨Ø£Ù‚Ø±Ø¨ ØªØ§Ø±ÙŠØ® Ø§Ù†ØªÙ‡Ø§Ø¡ Ø£ÙˆÙ„Ø§Ù‹ FIFO)';

CREATE INDEX IF NOT EXISTS idx_raw_batches_material ON public.raw_material_batches (raw_material_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_raw_batches_expiry ON public.raw_material_batches (raw_material_id, expiry_date);

ALTER TABLE public.raw_material_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "raw_material_batches_select" ON public.raw_material_batches
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "raw_material_batches_write" ON public.raw_material_batches
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 5. Recipes (product -> raw materials)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.recipes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id      uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name            text,
  yield_quantity  numeric(14,4) NOT NULL DEFAULT 1 CHECK (yield_quantity > 0),
  notes           text,
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (product_id, branch_id)
);
COMMENT ON TABLE public.recipes IS 'Ø§Ù„ÙˆØµÙØ§Øª: Ø±Ø¨Ø· Ø§Ù„Ù…Ù†ØªØ¬ Ø§Ù„Ù…ØµÙ†Ù‘Ø¹ Ø¨Ù…ÙƒÙˆÙ†Ø§ØªÙ‡ Ù…Ù† Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù…';

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recipes_select" ON public.recipes
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "recipes_write" ON public.recipes
  FOR ALL TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());

CREATE TRIGGER trg_recipes_updated BEFORE UPDATE ON public.recipes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.recipe_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id         uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  raw_material_id   uuid NOT NULL REFERENCES public.raw_materials(id),
  quantity          numeric(14,4) NOT NULL CHECK (quantity > 0),
  wastage_percent   numeric(5,2) NOT NULL DEFAULT 0 CHECK (wastage_percent >= 0),
  note              text,
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.recipe_items IS 'Ù…ÙƒÙˆÙ†Ø§Øª Ø§Ù„ÙˆØµÙØ© (ÙƒÙ…ÙŠØ© Ù…Ù† Ù…Ø§Ø¯Ø© Ø®Ø§Ù… Ù„ÙƒÙ„ ÙˆØµÙØ©)';

ALTER TABLE public.recipe_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recipe_items_select" ON public.recipe_items
  FOR SELECT TO authenticated USING (
    is_pos_admin() OR EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_items.recipe_id AND r.branch_id = get_branch_id()
    )
  );
CREATE POLICY "recipe_items_write" ON public.recipe_items
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 6. Production orders + waste
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.production_orders (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number      text NOT NULL UNIQUE,
  product_id        uuid NOT NULL REFERENCES public.products(id),
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  warehouse_id      uuid REFERENCES public.warehouses(id),
  quantity          numeric(14,4) NOT NULL CHECK (quantity > 0),
  batch_number      text,
  status            text NOT NULL DEFAULT 'planned'
                    CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
  total_cost        numeric(12,2) NOT NULL DEFAULT 0,
  planned_at        date DEFAULT CURRENT_DATE,
  completed_at      timestamptz,
  cancelled_at      timestamptz,
  cancel_reason     text,
  notes             text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.production_orders IS 'Ø£ÙˆØ§Ù…Ø± Ø§Ù„Ø¥Ù†ØªØ§Ø¬ (ØªØµÙ†ÙŠØ¹ Ù…Ù†ØªØ¬ Ù…Ù† Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù… Ø¹Ø¨Ø± Ø§Ù„ÙˆØµÙØ©)';

CREATE INDEX IF NOT EXISTS idx_production_orders_status ON public.production_orders (status, branch_id);
CREATE INDEX IF NOT EXISTS idx_production_orders_product ON public.production_orders (product_id);

ALTER TABLE public.production_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "production_orders_select" ON public.production_orders
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "production_orders_write" ON public.production_orders
  FOR ALL TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());

CREATE TRIGGER trg_production_orders_updated BEFORE UPDATE ON public.production_orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.production_waste (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          uuid NOT NULL REFERENCES public.production_orders(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  raw_material_id   uuid REFERENCES public.raw_materials(id),
  product_id        uuid REFERENCES public.products(id),
  quantity          numeric(14,4) NOT NULL CHECK (quantity >= 0),
  reason            text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  CHECK (raw_material_id IS NOT NULL OR product_id IS NOT NULL)
);
COMMENT ON TABLE public.production_waste IS 'Ù‡Ø§Ù„Ùƒ Ø§Ù„Ø¥Ù†ØªØ§Ø¬ (Ù…ÙˆØ§Ø¯ Ø®Ø§Ù… Ø£Ùˆ Ù…Ù†ØªØ¬Ø§Øª ØªØ§Ù„ÙØ©)';

ALTER TABLE public.production_waste ENABLE ROW LEVEL SECURITY;

CREATE POLICY "production_waste_select" ON public.production_waste
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "production_waste_write" ON public.production_waste
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 7. Warehouse transfers (finished goods between warehouses)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.warehouse_transfers (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_number     text NOT NULL UNIQUE,
  from_warehouse_id   uuid NOT NULL REFERENCES public.warehouses(id),
  to_warehouse_id     uuid NOT NULL REFERENCES public.warehouses(id),
  branch_id           uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  status              text NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'approved', 'rejected')),
  reason              text,
  notes               text,
  requested_by        uuid REFERENCES public.users(id),
  requested_at        timestamptz NOT NULL DEFAULT now(),
  approved_by         uuid REFERENCES public.users(id),
  approved_at         timestamptz,
  rejection_reason    text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CHECK (from_warehouse_id <> to_warehouse_id)
);
COMMENT ON TABLE public.warehouse_transfers IS 'Ø§Ù„ØªØ­ÙˆÙŠÙ„Ø§Øª Ø¨ÙŠÙ† Ø§Ù„Ù…Ø®Ø§Ø²Ù† (Ø¨Ø¶Ø§Ø¹Ø© Ø¬Ø§Ù‡Ø²Ø©)';

CREATE INDEX IF NOT EXISTS idx_warehouse_transfers_status ON public.warehouse_transfers (status, branch_id);

ALTER TABLE public.warehouse_transfers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "warehouse_transfers_select" ON public.warehouse_transfers
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "warehouse_transfers_write" ON public.warehouse_transfers
  FOR ALL TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());

CREATE TRIGGER trg_warehouse_transfers_updated BEFORE UPDATE ON public.warehouse_transfers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.warehouse_transfer_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_id     uuid NOT NULL REFERENCES public.warehouse_transfers(id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products(id),
  quantity        numeric(14,4) NOT NULL CHECK (quantity > 0),
  unit_cost       numeric(12,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK (product_id IS NOT NULL)
);
COMMENT ON TABLE public.warehouse_transfer_items IS 'Ù…Ù†ØªØ¬Ø§Øª Ø§Ù„ØªØ­ÙˆÙŠÙ„';

ALTER TABLE public.warehouse_transfer_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "warehouse_transfer_items_select" ON public.warehouse_transfer_items
  FOR SELECT TO authenticated USING (
    is_pos_admin() OR EXISTS (
      SELECT 1 FROM public.warehouse_transfers wt
      WHERE wt.id = warehouse_transfer_items.transfer_id AND wt.branch_id = get_branch_id()
    )
  );
CREATE POLICY "warehouse_transfer_items_write" ON public.warehouse_transfer_items
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 8. Finished-goods batches (expiry-aware FIFO for sales)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.inventory_batches (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id        uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  warehouse_id      uuid NOT NULL REFERENCES public.warehouses(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  batch_number      text,
  quantity          numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  unit_cost         numeric(12,2) NOT NULL DEFAULT 0,
  production_date   date,
  expiry_date       date,
  source_type       text NOT NULL DEFAULT 'purchase',
  source_id         uuid,
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.inventory_batches IS 'Ø¯ÙØ¹Ø§Øª Ø§Ù„Ø¨Ø¶Ø§Ø¹Ø© Ø§Ù„Ø¬Ø§Ù‡Ø²Ø© (Ø§Ù„Ø¨ÙŠØ¹ Ø¨Ø£Ù‚Ø±Ø¨ ØªØ§Ø±ÙŠØ® Ø§Ù†ØªÙ‡Ø§Ø¡ Ø£ÙˆÙ„Ø§Ù‹ FIFO)';

CREATE INDEX IF NOT EXISTS idx_inventory_batches_product ON public.inventory_batches (product_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_inventory_batches_expiry ON public.inventory_batches (product_id, expiry_date);

ALTER TABLE public.inventory_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventory_batches_select" ON public.inventory_batches
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "inventory_batches_write" ON public.inventory_batches
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 9. Inventory ledger (single source of truth for all movements)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.inventory_ledger (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id        uuid REFERENCES public.products(id) ON DELETE CASCADE,
  raw_material_id   uuid REFERENCES public.raw_materials(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  warehouse_id      uuid REFERENCES public.warehouses(id),
  batch_number      text,
  quantity          numeric(14,4) NOT NULL,
  unit_cost         numeric(12,2) NOT NULL DEFAULT 0,
  total_cost        numeric(14,2) NOT NULL DEFAULT 0,
  before_qty        numeric(14,4),
  after_qty         numeric(14,4),
  entry_type        text NOT NULL,
  reference_type    text,
  reference_id      uuid,
  reference_number  text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  CHECK ((product_id IS NOT NULL) <> (raw_material_id IS NOT NULL))
);
COMMENT ON TABLE public.inventory_ledger IS 'Ø¯ÙØªØ± Ø§Ù„Ù…Ø®Ø²ÙˆÙ†: ÙƒÙ„ Ø­Ø±ÙƒØ© ÙƒÙ…ÙŠØ© Ø³ÙˆØ§Ø¡ Ù…Ù†ØªØ¬Ø§Øª Ø£Ùˆ Ù…ÙˆØ§Ø¯ Ø®Ø§Ù…';

CREATE INDEX IF NOT EXISTS idx_inventory_ledger_product ON public.inventory_ledger (product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_raw ON public.inventory_ledger (raw_material_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_branch ON public.inventory_ledger (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_reference ON public.inventory_ledger (reference_type, reference_id);

ALTER TABLE public.inventory_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventory_ledger_select" ON public.inventory_ledger
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "inventory_ledger_write" ON public.inventory_ledger
  FOR ALL TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 10. Extend existing tables
-- ---------------------------------------------------------------------
ALTER TABLE public.inventory
  ADD COLUMN IF NOT EXISTS batch_number text,
  ADD COLUMN IF NOT EXISTS production_date date,
  ADD COLUMN IF NOT EXISTS expiry_date date;

ALTER TABLE public.warehouses
  ADD COLUMN IF NOT EXISTS warehouse_type text NOT NULL DEFAULT 'general'
  CHECK (warehouse_type IN ('general', 'raw', 'finished'));

ALTER TABLE public.purchase_items
  ADD COLUMN IF NOT EXISTS raw_material_id uuid REFERENCES public.raw_materials(id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_raw ON public.purchase_items (raw_material_id);

-- ---------------------------------------------------------------------
-- 11. Document sequences for new documents
-- ---------------------------------------------------------------------
INSERT INTO public.document_sequences (seq_type, next_value) VALUES
  ('production_order', 1),
  ('transfer', 1)
ON CONFLICT (seq_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 12. Backfill inventory_batches from existing inventory rows
--     (opening batches keep product.cost_price so FIFO invariant holds)
-- ---------------------------------------------------------------------
INSERT INTO public.inventory_batches (product_id, warehouse_id, branch_id, batch_number, quantity, unit_cost, source_type)
SELECT i.product_id, i.warehouse_id, i.branch_id, 'OPENING', i.quantity, COALESCE(p.cost_price, 0), 'opening'
FROM public.inventory i
JOIN public.products p ON p.id = i.product_id
WHERE i.quantity > 0;

INSERT INTO public.inventory_ledger (product_id, branch_id, warehouse_id, quantity, unit_cost, total_cost,
  before_qty, after_qty, entry_type, reference_type, reference_number)
SELECT i.product_id, i.branch_id, i.warehouse_id, i.quantity, COALESCE(p.cost_price, 0),
  i.quantity * COALESCE(p.cost_price, 0), 0, i.quantity, 'opening', 'opening', 'OPENING'
FROM public.inventory i
JOIN public.products p ON p.id = i.product_id
WHERE i.quantity > 0;

-- ---------------------------------------------------------------------
-- 13. production_manager role
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_role_check' AND conrelid = 'public.users'::regclass
  ) THEN
    ALTER TABLE public.users ADD CONSTRAINT users_role_check
      CHECK (role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                      'warehouse_manager', 'accountant', 'production_manager'));
  ELSE
    ALTER TABLE public.users DROP CONSTRAINT users_role_check;
    ALTER TABLE public.users ADD CONSTRAINT users_role_check
      CHECK (role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                      'warehouse_manager', 'accountant', 'production_manager'));
  END IF;
END $$;

INSERT INTO public.roles (role, name_ar, name_en, permissions, updated_at)
VALUES (
  'production_manager', 'Ù…Ø¯ÙŠØ± Ø¥Ù†ØªØ§Ø¬', 'Production Manager',
  '[
    "dashboard.view", "products.view", "products.manage", "categories.view", "categories.manage",
    "raw_materials.view", "raw_materials.manage", "recipes.view", "recipes.manage",
    "production.view", "production.manage", "production.waste",
    "inventory.view", "inventory.manage", "warehouses.view", "warehouses.manage",
    "inventory.transfers", "inventory.transfers.approve",
    "purchases.view", "purchases.manage", "suppliers.view", "suppliers.manage",
    "inventory.ledger.view", "shifts.view"
  ]'::jsonb,
  now()
)
ON CONFLICT (role) DO UPDATE SET
  name_ar = EXCLUDED.name_ar, name_en = EXCLUDED.name_en,
  permissions = EXCLUDED.permissions, updated_at = now();

-- ---------------------------------------------------------------------
-- 14. create_user: allow production_manager (and drop stale role names)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_user(p_email text, p_password text, p_full_name text DEFAULT NULL::text, p_role text DEFAULT 'cashier'::text, p_branch_id uuid DEFAULT NULL::uuid, p_is_active boolean DEFAULT true, p_username text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id uuid;
  v_role text;
  v_hash text;
  v_email text;
  v_username text;
  v_pgc_schema text;
  v_caller_role text;
  v_caller_branch uuid;
  v_u_cols text;
  v_u_vals text;
  v_i_cols text;
  v_i_vals text;
BEGIN
  SELECT role, branch_id INTO v_caller_role, v_caller_branch FROM public.users WHERE id = auth.uid();

  IF is_pos_admin() THEN
    NULL;
  ELSIF v_caller_role = 'branch_manager' AND v_caller_branch IS NOT NULL THEN
    -- branch manager: force their own branch and forbid admin roles
    IF p_branch_id IS NOT NULL AND p_branch_id <> v_caller_branch THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Branch managers can only create users in their own branch');
    END IF;
    IF p_role IN ('super_admin', 'owner') THEN
      RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED',
        'detail', 'Only a super admin can create super_admin/owner accounts');
    END IF;
    p_branch_id := v_caller_branch;
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  v_email := lower(btrim(p_email));

  -- Email uniqueness (both auth accounts and app profiles)
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE email = v_email) THEN
    RETURN jsonb_build_object('success', false, 'error', 'EMAIL_TAKEN');
  END IF;

  -- Username: default to email prefix, sanitized, must be unique
  v_username := regexp_replace(
    regexp_replace(lower(btrim(coalesce(NULLIF(p_username, ''), split_part(v_email, '@', 1)))), '[^a-z0-9._-]', '_', 'g'),
    '^[._-]+', '', 'g'
  );
  IF v_username = '' THEN
    v_username := 'user' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE username = v_username) THEN
    RETURN jsonb_build_object('success', false, 'error', 'USERNAME_TAKEN');
  END IF;

  SELECT extnamespace::regnamespace::text INTO v_pgc_schema
  FROM pg_extension WHERE extname = 'pgcrypto';

  IF v_pgc_schema IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'pgcrypto extension is not enabled');
  END IF;

  EXECUTE format('SELECT %I.crypt($1, %I.gen_salt($2, $3))', v_pgc_schema, v_pgc_schema)
    INTO v_hash USING p_password, 'bf', 10;

  v_role := CASE
    WHEN p_role IN ('super_admin', 'owner', 'branch_manager', 'cashier',
                    'warehouse_manager', 'accountant', 'production_manager') THEN p_role
    ELSE 'cashier'
  END;

  v_user_id := gen_random_uuid();

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_u_cols, v_u_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'instance_id' THEN '''00000000-0000-0000-0000-000000000000'''
        WHEN 'id' THEN quote_literal(v_user_id)
        WHEN 'aud' THEN '''authenticated'''
        WHEN 'role' THEN '''authenticated'''
        WHEN 'email' THEN quote_literal(v_email)
        WHEN 'encrypted_password' THEN quote_literal(v_hash)
        WHEN 'email_confirmed_at' THEN 'now()'
        WHEN 'confirmation_token' THEN ''''''
        WHEN 'recovery_token' THEN ''''''
        WHEN 'email_change' THEN ''''''
        WHEN 'email_change_token_new' THEN ''''''
        WHEN 'email_change_token_current' THEN ''''''
        WHEN 'raw_app_meta_data' THEN format('jsonb_build_object(''provider'',''email'',''providers'',array[''email'']::text[],''email'',%L)', v_email)
        WHEN 'raw_user_meta_data' THEN format('jsonb_build_object(''full_name'',%L,''email'',%L,''email_verified'',true)', p_full_name, v_email)
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'is_anonymous' THEN 'false'
        WHEN 'is_sso_user' THEN 'false'
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'users'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('instance_id','id','aud','role','email','encrypted_password','email_confirmed_at','confirmation_token','recovery_token','email_change','email_change_token_new','email_change_token_current','raw_app_meta_data','raw_user_meta_data','created_at','updated_at','is_anonymous','is_sso_user')
  ) c;

  IF v_u_cols IS NULL OR v_u_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.users');
  END IF;

  EXECUTE 'INSERT INTO auth.users (' || v_u_cols || ') VALUES (' || v_u_vals || ')';

  SELECT string_agg(c.col, ', ' ORDER BY c.ord), string_agg(c.val, ', ' ORDER BY c.ord)
  INTO v_i_cols, v_i_vals
  FROM (
    SELECT cols.ordinal_position AS ord, quote_ident(cols.column_name) AS col,
      CASE cols.column_name
        WHEN 'id' THEN 'gen_random_uuid()'
        WHEN 'provider_id' THEN quote_literal(v_user_id::text)
        WHEN 'user_id' THEN quote_literal(v_user_id)
        WHEN 'identity_data' THEN format('jsonb_build_object(''sub'',%L,''email'',%L)', v_user_id::text, v_email)
        WHEN 'provider' THEN '''email'''
        WHEN 'last_sign_in_at' THEN 'now()'
        WHEN 'created_at' THEN 'now()'
        WHEN 'updated_at' THEN 'now()'
        WHEN 'email' THEN quote_literal(v_email)
      END AS val
    FROM information_schema.columns cols
    WHERE cols.table_schema = 'auth' AND cols.table_name = 'identities'
      AND cols.is_generated = 'NEVER'
      AND cols.column_name IN ('id','provider_id','user_id','identity_data','provider','last_sign_in_at','created_at','updated_at','email')
  ) c;

  IF v_i_cols IS NULL OR v_i_vals IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', 'no insertable columns found for auth.identities');
  END IF;

  EXECUTE 'INSERT INTO auth.identities (' || v_i_cols || ') VALUES (' || v_i_vals || ')';

  INSERT INTO public.users (id, email, username, full_name, role, branch_id, is_active)
  VALUES (v_user_id, v_email, v_username, p_full_name, v_role, p_branch_id, p_is_active);

  RETURN jsonb_build_object('success', true, 'user_id', v_user_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', 'UNKNOWN_ERROR', 'detail', SQLERRM);
END;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 012_sales_refund_columns.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- Refund tracking columns on sales / sale_items
-- ----------------------------------------------------------------------------
-- process_refund (defined later in manufacturing_rpc) and the receivable
-- checks in accounting_rpc / d1_foundation read sales.refunded_amount and
-- sale_items.refunded_quantity / refunded_amount. On the live database these
-- columns were added by the legacy audit_fixes migration; this file recreates
-- them for a fresh build. Additive + idempotent.
-- ============================================================================

ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS refunded_amount numeric(14,2) NOT NULL DEFAULT 0;
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS refunded_quantity numeric(14,4) NOT NULL DEFAULT 0;
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS refunded_amount numeric(14,2) NOT NULL DEFAULT 0;



-- ----------------------------------------------------------------------------
-- MIGRATION: 013_manufacturing_rpc.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase B2: Manufacturing, Warehouse Transfers & Inventory Ledger RPCs
-- =====================================================================
-- Internal FIFO helpers + production/transfer RPCs + rewritten
-- process_purchase / process_sale / process_refund / adjust_stock /
-- adjust_raw_stock, all writing inventory_ledger as the source of truth.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Allow new movement types in the legacy stock_transactions log
-- ---------------------------------------------------------------------
ALTER TABLE public.stock_transactions DROP CONSTRAINT IF EXISTS stock_transactions_transaction_type_check;
ALTER TABLE public.stock_transactions ADD CONSTRAINT stock_transactions_transaction_type_check
  CHECK (transaction_type IN ('sale', 'purchase', 'adjustment', 'refund',
                              'transfer', 'production', 'waste', 'opening'));

-- purchase items must reference exactly one of product or raw material
ALTER TABLE public.purchase_items DROP CONSTRAINT IF EXISTS purchase_items_one_target;
ALTER TABLE public.purchase_items ADD CONSTRAINT purchase_items_one_target
  CHECK (num_nonnulls(product_id, raw_material_id) = 1);

-- ---------------------------------------------------------------------
-- 1. next_document_number: accept any document type
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.next_document_number(p_type text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_store text;
  v_num   bigint;
BEGIN
  IF p_type IS NULL OR btrim(p_type) = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_TYPE');
  END IF;

  LOOP
    UPDATE public.document_sequences
       SET next_value = next_value + 1
     WHERE seq_type = p_type
    RETURNING next_value - 1 INTO v_num;
    EXIT WHEN v_num IS NOT NULL;

    -- Counter row missing: create it (first number = 1) and retry.
    INSERT INTO public.document_sequences (seq_type, next_value)
    VALUES (p_type, 2)
    ON CONFLICT (seq_type) DO NOTHING;
  END LOOP;

  SELECT btrim(coalesce(store_name, '')) INTO v_store FROM public.settings LIMIT 1;
  IF v_store IS NULL OR v_store = '' THEN
    v_store := 'POS';
  END IF;

  RETURN jsonb_build_object('success', true, 'number', v_store || '-' || lpad(v_num::text, 5, '0'), 'raw', v_num);
END;
$function$;

-- ---------------------------------------------------------------------
-- 2. Internal helper: add quantity of a finished product
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._product_inv_add(
  p_product_id uuid, p_warehouse_id uuid, p_branch_id uuid, p_qty numeric,
  p_unit_cost numeric DEFAULT 0,
  p_batch_number text DEFAULT NULL,
  p_production_date date DEFAULT NULL,
  p_expiry_date date DEFAULT NULL,
  p_entry_type text DEFAULT 'purchase',
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_batch_no text;
BEGIN
  IF p_qty IS NULL OR p_qty <= 0 OR p_warehouse_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_PARAMS');
  END IF;

  v_batch_no := COALESCE(NULLIF(btrim(COALESCE(p_batch_number, '')), ''),
                         'B-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  SELECT COALESCE(quantity, 0) INTO v_before
  FROM public.inventory WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;
  IF v_before IS NULL THEN v_before := 0; END IF;
  v_after := v_before + p_qty;

  INSERT INTO public.inventory (product_id, warehouse_id, branch_id, quantity, batch_number, production_date, expiry_date, updated_at)
  VALUES (p_product_id, p_warehouse_id, p_branch_id, p_qty, v_batch_no, p_production_date, p_expiry_date, now())
  ON CONFLICT (product_id, warehouse_id)
  DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity,
    branch_id = EXCLUDED.branch_id, updated_at = now();

  INSERT INTO public.inventory_batches (product_id, warehouse_id, branch_id, batch_number, quantity, unit_cost, production_date, expiry_date, source_type, source_id)
  VALUES (p_product_id, p_warehouse_id, p_branch_id, v_batch_no, p_qty, COALESCE(p_unit_cost, 0),
          p_production_date, p_expiry_date, COALESCE(p_reference_type, p_entry_type), p_reference_id);

  INSERT INTO public.inventory_ledger (product_id, branch_id, warehouse_id, batch_number, quantity, unit_cost, total_cost, before_qty, after_qty, entry_type, reference_type, reference_id, reference_number, created_by)
  VALUES (p_product_id, p_branch_id, p_warehouse_id, v_batch_no, p_qty, COALESCE(p_unit_cost, 0),
          p_qty * COALESCE(p_unit_cost, 0), v_before, v_after, p_entry_type,
          p_reference_type, p_reference_id, p_reference_number, p_created_by);

  INSERT INTO public.stock_transactions (product_id, warehouse_id, branch_id, transaction_type, component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
  VALUES (p_product_id, p_warehouse_id, p_branch_id, p_entry_type, false,
          COALESCE(p_reference_type, p_entry_type), p_reference_id, p_qty, v_before, v_after,
          COALESCE(p_unit_cost, 0), p_created_by);

  RETURN jsonb_build_object('success', true, 'before_qty', v_before, 'after_qty', v_after, 'batch_number', v_batch_no);
END;
$function$;

-- ---------------------------------------------------------------------
-- 3. Internal helper: remove finished product FIFO (nearest expiry first)
--    p_warehouse_id NULL => consume across all branch warehouses.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._product_inv_remove_fifo(
  p_product_id uuid, p_warehouse_id uuid, p_branch_id uuid, p_qty numeric,
  p_entry_type text DEFAULT 'sale',
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_remaining numeric(14,4);
  v_batch record;
  v_deduct numeric(14,4);
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_total_cost numeric(14,2) := 0;
  v_total_removed numeric(14,4) := 0;
  v_shortage numeric(14,4) := 0;
BEGIN
  IF p_qty IS NULL OR p_qty <= 0 THEN
    RETURN jsonb_build_object('success', true, 'shortage', 0, 'removed', 0, 'total_cost', 0, 'avg_cost', 0);
  END IF;

  v_remaining := p_qty;

  FOR v_batch IN
    SELECT b.id, b.warehouse_id, b.quantity, b.unit_cost, b.batch_number
    FROM public.inventory_batches b
    WHERE b.product_id = p_product_id AND b.quantity > 0 AND b.branch_id = p_branch_id
      AND (p_warehouse_id IS NULL OR b.warehouse_id = p_warehouse_id)
    ORDER BY b.expiry_date NULLS LAST, b.created_at ASC, b.id ASC
    FOR UPDATE
  LOOP
    IF v_remaining <= 0 THEN EXIT; END IF;
    v_deduct := LEAST(v_batch.quantity, v_remaining);

    SELECT COALESCE(quantity, 0) INTO v_before
    FROM public.inventory WHERE product_id = p_product_id AND warehouse_id = v_batch.warehouse_id;
    IF v_before IS NULL THEN v_before := 0; END IF;
    v_after := v_before - v_deduct;
    IF v_after < 0 THEN v_after := 0; END IF;

    UPDATE public.inventory SET quantity = v_after, updated_at = now()
    WHERE product_id = p_product_id AND warehouse_id = v_batch.warehouse_id;
    UPDATE public.inventory_batches SET quantity = quantity - v_deduct WHERE id = v_batch.id;

    INSERT INTO public.inventory_ledger (product_id, branch_id, warehouse_id, batch_number, quantity, unit_cost, total_cost, before_qty, after_qty, entry_type, reference_type, reference_id, reference_number, created_by)
    VALUES (p_product_id, p_branch_id, v_batch.warehouse_id, v_batch.batch_number, -v_deduct,
            v_batch.unit_cost, -v_deduct * v_batch.unit_cost, v_before, v_after, p_entry_type,
            p_reference_type, p_reference_id, p_reference_number, p_created_by);

    INSERT INTO public.stock_transactions (product_id, warehouse_id, branch_id, transaction_type, component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
    VALUES (p_product_id, v_batch.warehouse_id, p_branch_id, p_entry_type, false,
            COALESCE(p_reference_type, p_entry_type), p_reference_id, -v_deduct, v_before, v_after,
            v_batch.unit_cost, p_created_by);

    v_total_cost := v_total_cost + v_deduct * v_batch.unit_cost;
    v_total_removed := v_total_removed + v_deduct;
    v_remaining := v_remaining - v_deduct;
  END LOOP;

  v_shortage := v_remaining;

  RETURN jsonb_build_object('success', true, 'shortage', v_shortage, 'removed', v_total_removed,
    'total_cost', v_total_cost,
    'avg_cost', CASE WHEN v_total_removed > 0 THEN round(v_total_cost / v_total_removed, 2) ELSE 0 END);
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. Internal helper: add raw material quantity (branch-scoped, weighted avg)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._raw_add(
  p_raw_material_id uuid, p_branch_id uuid, p_qty numeric,
  p_unit_cost numeric DEFAULT 0,
  p_batch_number text DEFAULT NULL,
  p_production_date date DEFAULT NULL,
  p_expiry_date date DEFAULT NULL,
  p_entry_type text DEFAULT 'purchase',
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_inv record;
  v_new_qty numeric(14,4);
  v_new_avg numeric(12,2);
  v_before numeric(14,4) := 0;
  v_after numeric(14,4);
  v_batch_no text;
BEGIN
  IF p_qty IS NULL OR p_qty <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_PARAMS');
  END IF;

  v_batch_no := COALESCE(NULLIF(btrim(COALESCE(p_batch_number, '')), ''),
                         'RB-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  SELECT * INTO v_inv
  FROM public.raw_material_inventory
  WHERE raw_material_id = p_raw_material_id AND branch_id = p_branch_id
  FOR UPDATE;

  IF v_inv.id IS NULL THEN
    v_before := 0;
    v_after := p_qty;
    v_new_avg := COALESCE(p_unit_cost, 0);
    INSERT INTO public.raw_material_inventory (raw_material_id, branch_id, quantity, avg_cost)
    VALUES (p_raw_material_id, p_branch_id, p_qty, v_new_avg);
  ELSE
    v_before := v_inv.quantity;
    v_after := v_before + p_qty;
    v_new_avg := CASE WHEN v_after > 0
      THEN round((v_inv.quantity * v_inv.avg_cost + p_qty * COALESCE(p_unit_cost, 0)) / v_after, 2)
      ELSE COALESCE(p_unit_cost, 0) END;
    UPDATE public.raw_material_inventory
    SET quantity = v_after, avg_cost = v_new_avg, updated_at = now()
    WHERE id = v_inv.id;
  END IF;

  INSERT INTO public.raw_material_batches (raw_material_id, branch_id, batch_number, quantity, unit_cost, production_date, expiry_date, source_type, source_id)
  VALUES (p_raw_material_id, p_branch_id, v_batch_no, p_qty, COALESCE(p_unit_cost, 0),
          p_production_date, p_expiry_date, COALESCE(p_reference_type, p_entry_type), p_reference_id);

  INSERT INTO public.inventory_ledger (raw_material_id, branch_id, batch_number, quantity, unit_cost, total_cost, before_qty, after_qty, entry_type, reference_type, reference_id, reference_number, created_by)
  VALUES (p_raw_material_id, p_branch_id, v_batch_no, p_qty, COALESCE(p_unit_cost, 0),
          p_qty * COALESCE(p_unit_cost, 0), v_before, v_after, p_entry_type,
          p_reference_type, p_reference_id, p_reference_number, p_created_by);

  RETURN jsonb_build_object('success', true, 'before_qty', v_before, 'after_qty', v_after,
    'avg_cost', v_new_avg, 'batch_number', v_batch_no);
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. Internal helper: remove raw material FIFO (nearest expiry first)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._raw_remove_fifo(
  p_raw_material_id uuid, p_branch_id uuid, p_qty numeric,
  p_entry_type text DEFAULT 'production',
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_remaining numeric(14,4);
  v_batch record;
  v_deduct numeric(14,4);
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_avg_val numeric(14,2) := 0;
  v_total_cost numeric(14,2) := 0;
  v_total_removed numeric(14,4) := 0;
  v_shortage numeric(14,4) := 0;
BEGIN
  IF p_qty IS NULL OR p_qty <= 0 THEN
    RETURN jsonb_build_object('success', true, 'shortage', 0, 'removed', 0, 'total_cost', 0, 'avg_cost', 0);
  END IF;

  v_remaining := p_qty;

  SELECT COALESCE(quantity, 0) INTO v_before
  FROM public.raw_material_inventory
  WHERE raw_material_id = p_raw_material_id AND branch_id = p_branch_id;
  IF v_before IS NULL THEN v_before := 0; END IF;
  v_after := v_before;

  FOR v_batch IN
    SELECT b.id, b.quantity, b.unit_cost, b.batch_number
    FROM public.raw_material_batches b
    WHERE b.raw_material_id = p_raw_material_id AND b.branch_id = p_branch_id AND b.quantity > 0
    ORDER BY b.expiry_date NULLS LAST, b.created_at ASC, b.id ASC
    FOR UPDATE
  LOOP
    IF v_remaining <= 0 THEN EXIT; END IF;
    v_deduct := LEAST(v_batch.quantity, v_remaining);

    UPDATE public.raw_material_batches SET quantity = quantity - v_deduct WHERE id = v_batch.id;

    v_after := v_after - v_deduct;
    INSERT INTO public.inventory_ledger (raw_material_id, branch_id, batch_number, quantity, unit_cost, total_cost, before_qty, after_qty, entry_type, reference_type, reference_id, reference_number, created_by)
    VALUES (p_raw_material_id, p_branch_id, v_batch.batch_number, -v_deduct, v_batch.unit_cost,
            -v_deduct * v_batch.unit_cost, v_after + v_deduct, v_after, p_entry_type,
            p_reference_type, p_reference_id, p_reference_number, p_created_by);

    v_total_cost := v_total_cost + v_deduct * v_batch.unit_cost;
    v_total_removed := v_total_removed + v_deduct;
    v_remaining := v_remaining - v_deduct;
  END LOOP;

  v_shortage := v_remaining;

  SELECT COALESCE(SUM(b.quantity), 0), COALESCE(SUM(b.quantity * b.unit_cost), 0)
  INTO v_after, v_avg_val
  FROM public.raw_material_batches b
  WHERE b.raw_material_id = p_raw_material_id AND b.branch_id = p_branch_id;

  UPDATE public.raw_material_inventory
  SET quantity = v_after,
      avg_cost = CASE WHEN v_after > 0 THEN round(v_avg_val / v_after, 2) ELSE 0 END,
      updated_at = now()
  WHERE raw_material_id = p_raw_material_id AND branch_id = p_branch_id;

  RETURN jsonb_build_object('success', true, 'shortage', v_shortage, 'removed', v_total_removed,
    'total_cost', v_total_cost,
    'avg_cost', CASE WHEN v_total_removed > 0 THEN round(v_total_cost / v_total_removed, 2) ELSE 0 END);
END;
$function$;

-- ---------------------------------------------------------------------
-- 6. Internal helper: move finished product between warehouses (FIFO)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._product_inv_move(
  p_product_id uuid, p_from_wh uuid, p_to_wh uuid, p_branch_id uuid, p_qty numeric,
  p_reference_type text DEFAULT 'transfer',
  p_reference_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_to_branch uuid;
  v_remaining numeric(14,4);
  v_batch record;
  v_deduct numeric(14,4);
  v_before numeric(14,4);
  v_after numeric(14,4);
  v_shortage numeric(14,4) := 0;
BEGIN
  SELECT COALESCE(branch_id, p_branch_id) INTO v_to_branch FROM public.warehouses WHERE id = p_to_wh;

  v_remaining := p_qty;

  FOR v_batch IN
    SELECT b.id, b.warehouse_id, b.quantity, b.unit_cost, b.batch_number, b.production_date, b.expiry_date
    FROM public.inventory_batches b
    WHERE b.product_id = p_product_id AND b.quantity > 0 AND b.warehouse_id = p_from_wh
    ORDER BY b.expiry_date NULLS LAST, b.created_at ASC, b.id ASC
    FOR UPDATE
  LOOP
    IF v_remaining <= 0 THEN EXIT; END IF;
    v_deduct := LEAST(v_batch.quantity, v_remaining);

    SELECT COALESCE(quantity, 0) INTO v_before
    FROM public.inventory WHERE product_id = p_product_id AND warehouse_id = p_from_wh;
    IF v_before IS NULL THEN v_before := 0; END IF;
    v_after := v_before - v_deduct;
    IF v_after < 0 THEN v_after := 0; END IF;
    UPDATE public.inventory SET quantity = v_after, updated_at = now()
    WHERE product_id = p_product_id AND warehouse_id = p_from_wh;
    UPDATE public.inventory_batches SET quantity = quantity - v_deduct WHERE id = v_batch.id;

    INSERT INTO public.inventory_ledger (product_id, branch_id, warehouse_id, batch_number, quantity, unit_cost, total_cost, before_qty, after_qty, entry_type, reference_type, reference_id, reference_number, created_by)
    VALUES (p_product_id, p_branch_id, p_from_wh, v_batch.batch_number, -v_deduct, v_batch.unit_cost,
            -v_deduct * v_batch.unit_cost, v_before, v_after, 'transfer',
            p_reference_type, p_reference_id, p_reference_number, p_created_by);

    INSERT INTO public.stock_transactions (product_id, warehouse_id, branch_id, transaction_type, component_flow, reference_type, reference_id, quantity, before_quantity, after_quantity, unit_cost, created_by)
    VALUES (p_product_id, p_from_wh, p_branch_id, 'transfer', false,
            p_reference_type, p_reference_id, -v_deduct, v_before, v_after, v_batch.unit_cost, p_created_by);

    PERFORM public._product_inv_add(p_product_id, p_to_wh, COALESCE(v_to_branch, p_branch_id),
      v_deduct, v_batch.unit_cost, v_batch.batch_number, v_batch.production_date, v_batch.expiry_date,
      'transfer', p_reference_type, p_reference_id, p_reference_number, p_created_by);

    v_remaining := v_remaining - v_deduct;
  END LOOP;

  v_shortage := v_remaining;

  RETURN jsonb_build_object('success', true, 'shortage', v_shortage, 'moved', p_qty - v_remaining);
END;
$function$;

-- =====================================================================
-- PRODUCTION ORDERS
-- =====================================================================

CREATE OR REPLACE FUNCTION public.create_production_order(
  p_product_id uuid, p_branch_id uuid, p_warehouse_id uuid, p_quantity numeric,
  p_batch_number text DEFAULT NULL, p_planned_at date DEFAULT CURRENT_DATE, p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_order_id uuid;
  v_number text;
  v_batch text;
  v_user_branch uuid;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('production.manage') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Creating production orders requires the production.manage permission.');
    END IF;

    IF p_quantity IS NULL OR p_quantity <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE id = p_product_id AND branch_id = p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH', 'product_id', p_product_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM recipes WHERE product_id = p_product_id AND branch_id = p_branch_id AND is_active) THEN
      RETURN jsonb_build_object('success', false, 'error', 'NO_RECIPE', 'product_id', p_product_id);
    END IF;

    IF p_warehouse_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_warehouse_id AND is_active) THEN
      RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_NOT_FOUND');
    END IF;

    v_number := (public.next_document_number('production_order')->>'number')::text;
    v_batch := COALESCE(NULLIF(btrim(COALESCE(p_batch_number, '')), ''),
                        'B-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

    INSERT INTO public.production_orders (order_number, product_id, branch_id, warehouse_id, quantity, batch_number, planned_at, notes, created_by)
    VALUES (v_number, p_product_id, p_branch_id, p_warehouse_id, p_quantity, v_batch, p_planned_at, p_notes, auth.uid())
    RETURNING id INTO v_order_id;

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id, 'order_number', v_number, 'batch_number', v_batch);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.start_production_order(p_order_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('production.manage') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    SELECT status INTO v_status FROM public.production_orders WHERE id = p_order_id;
    IF v_status IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;
    IF v_status <> 'planned' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_status);
    END IF;

    UPDATE public.production_orders SET status = 'in_progress' WHERE id = p_order_id;
    RETURN jsonb_build_object('success', true, 'order_id', p_order_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_production_order(
  p_order_id uuid, p_waste jsonb DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_order record;
  v_recipe_id uuid;
  v_recipe_yield numeric(14,4);
  v_factor numeric(14,4);
  v_item record;
  v_waste_item jsonb;
  v_req numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cost numeric(14,2) := 0;
  v_unit_cost numeric(12,2) := 0;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('production.manage') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    SELECT * INTO v_order FROM public.production_orders WHERE id = p_order_id FOR UPDATE;
    IF v_order.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;
    IF v_order.status NOT IN ('planned', 'in_progress') THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_order.status);
    END IF;
    IF v_order.warehouse_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_REQUIRED',
        'detail', 'Assign an output warehouse to the production order before completing it.');
    END IF;

    SELECT id, yield_quantity INTO v_recipe_id, v_recipe_yield
    FROM public.recipes
    WHERE product_id = v_order.product_id AND branch_id = v_order.branch_id AND is_active
    ORDER BY updated_at DESC LIMIT 1;
    IF v_recipe_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'NO_RECIPE', 'product_id', v_order.product_id);
    END IF;

    v_recipe_yield := COALESCE(v_recipe_yield, 1);
    v_factor := v_order.quantity / v_recipe_yield;

    -- Consume raw materials (FIFO by nearest expiry)
    FOR v_item IN SELECT * FROM public.recipe_items WHERE recipe_id = v_recipe_id
    LOOP
      v_req := COALESCE(v_item.quantity, 0) * v_factor;
      IF v_req <= 0 THEN CONTINUE; END IF;

      v_res := public._raw_remove_fifo(v_item.raw_material_id, v_order.branch_id, v_req,
        'production', 'production_order', v_order.id, v_order.order_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_RAW',
          'raw_material_id', v_item.raw_material_id, 'required', v_req,
          'available', v_req - v_short,
          'detail', 'Not enough raw material to complete production. The order was not completed.');
      END IF;
      v_cost := v_cost + (v_res->>'total_cost')::numeric;
    END LOOP;

    -- Record waste (extra raw material consumed beyond the recipe)
    IF p_waste IS NOT NULL AND jsonb_array_length(p_waste) > 0 THEN
      FOR v_waste_item IN SELECT * FROM jsonb_array_elements(p_waste)
      LOOP
        v_req := COALESCE((v_waste_item->>'quantity')::numeric, 0);
        IF v_req <= 0 THEN CONTINUE; END IF;
        v_res := public._raw_remove_fifo((v_waste_item->>'raw_material_id')::uuid, v_order.branch_id, v_req,
          'waste', 'production_order', v_order.id, v_order.order_number, auth.uid());
        v_cost := v_cost + (v_res->>'total_cost')::numeric;
        INSERT INTO public.production_waste (order_id, branch_id, raw_material_id, quantity, reason)
        VALUES (v_order.id, v_order.branch_id, (v_waste_item->>'raw_material_id')::uuid, v_req,
                COALESCE(v_waste_item->>'reason', 'Ø¥Ù†ØªØ§Ø¬'));
      END LOOP;
    END IF;

    -- Produce output as a new batch
    v_unit_cost := CASE WHEN v_order.quantity > 0 THEN round(v_cost / v_order.quantity, 2) ELSE 0 END;
    v_res := public._product_inv_add(v_order.product_id, v_order.warehouse_id, v_order.branch_id,
      v_order.quantity, v_unit_cost, v_order.batch_number, CURRENT_DATE, NULL,
      'production', 'production_order', v_order.id, v_order.order_number, auth.uid());
    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    UPDATE public.production_orders
    SET status = 'completed', total_cost = v_cost, completed_at = now()
    WHERE id = v_order.id;

    RETURN jsonb_build_object('success', true, 'order_id', v_order.id, 'order_number', v_order.order_number,
      'total_cost', v_cost, 'unit_cost', v_unit_cost);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_production_order(p_order_id uuid, p_reason text DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('production.manage') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    SELECT status INTO v_status FROM public.production_orders WHERE id = p_order_id;
    IF v_status IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;
    IF v_status NOT IN ('planned', 'in_progress') THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_status);
    END IF;

    UPDATE public.production_orders
    SET status = 'cancelled', cancelled_at = now(), cancel_reason = p_reason
    WHERE id = p_order_id;

    RETURN jsonb_build_object('success', true, 'order_id', p_order_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- =====================================================================
-- WAREHOUSE TRANSFERS
-- =====================================================================

CREATE OR REPLACE FUNCTION public.create_warehouse_transfer(
  p_from_warehouse_id uuid, p_to_warehouse_id uuid, p_branch_id uuid,
  p_items jsonb, p_reason text DEFAULT NULL, p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_transfer_id uuid;
  v_number text;
  v_item jsonb;
  v_product_id uuid;
  v_qty numeric(14,4);
  v_user_branch uuid;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('inventory.transfers') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Creating transfers requires the inventory.transfers permission.');
    END IF;

    IF p_from_warehouse_id IS NULL OR p_to_warehouse_id IS NULL OR p_from_warehouse_id = p_to_warehouse_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_WAREHOUSES');
    END IF;
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_from_warehouse_id AND is_active)
       OR NOT EXISTS (SELECT 1 FROM warehouses WHERE id = p_to_warehouse_id AND is_active) THEN
      RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_NOT_FOUND');
    END IF;

    v_number := (public.next_document_number('transfer')->>'number')::text;

    INSERT INTO public.warehouse_transfers (transfer_number, from_warehouse_id, to_warehouse_id, branch_id, reason, notes, requested_by)
    VALUES (v_number, p_from_warehouse_id, p_to_warehouse_id, p_branch_id, p_reason, p_notes, auth.uid())
    RETURNING id INTO v_transfer_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_qty := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_product_id IS NULL OR v_qty <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_ITEM', 'item', v_item);
      END IF;
      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;
      INSERT INTO public.warehouse_transfer_items (transfer_id, product_id, quantity, unit_cost)
      VALUES (v_transfer_id, v_product_id, v_qty, COALESCE((v_item->>'unit_cost')::numeric, 0));
    END LOOP;

    RETURN jsonb_build_object('success', true, 'transfer_id', v_transfer_id, 'transfer_number', v_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.approve_warehouse_transfer(p_transfer_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_transfer record;
  v_item record;
  v_avail numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('inventory.transfers.approve') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Approving transfers requires the inventory.transfers.approve permission.');
    END IF;

    SELECT * INTO v_transfer FROM public.warehouse_transfers WHERE id = p_transfer_id FOR UPDATE;
    IF v_transfer.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'TRANSFER_NOT_FOUND');
    END IF;
    IF v_transfer.status <> 'pending' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_transfer.status);
    END IF;

    -- Validate availability for all items before moving anything
    FOR v_item IN SELECT * FROM public.warehouse_transfer_items WHERE transfer_id = p_transfer_id
    LOOP
      SELECT COALESCE(SUM(quantity), 0) INTO v_avail
      FROM public.inventory_batches
      WHERE product_id = v_item.product_id AND warehouse_id = v_transfer.from_warehouse_id;
      IF v_avail < v_item.quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_item.product_id, 'required', v_item.quantity, 'available', v_avail);
      END IF;
    END LOOP;

    FOR v_item IN SELECT * FROM public.warehouse_transfer_items WHERE transfer_id = p_transfer_id
    LOOP
      v_res := public._product_inv_move(v_item.product_id, v_transfer.from_warehouse_id,
        v_transfer.to_warehouse_id, v_transfer.branch_id, v_item.quantity,
        'warehouse_transfer', v_transfer.id, v_transfer.transfer_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_item.product_id, 'shortage', v_short);
      END IF;
    END LOOP;

    UPDATE public.warehouse_transfers
    SET status = 'approved', approved_by = auth.uid(), approved_at = now()
    WHERE id = p_transfer_id;

    RETURN jsonb_build_object('success', true, 'transfer_id', p_transfer_id, 'transfer_number', v_transfer.transfer_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reject_warehouse_transfer(p_transfer_id uuid, p_reason text DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('inventory.transfers.approve') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    SELECT status INTO v_status FROM public.warehouse_transfers WHERE id = p_transfer_id;
    IF v_status IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'TRANSFER_NOT_FOUND');
    END IF;
    IF v_status <> 'pending' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_status);
    END IF;

    UPDATE public.warehouse_transfers
    SET status = 'rejected', approved_by = auth.uid(), approved_at = now(), rejection_reason = p_reason
    WHERE id = p_transfer_id;

    RETURN jsonb_build_object('success', true, 'transfer_id', p_transfer_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- =====================================================================
-- PURCHASES (rewritten: products + raw materials, batches, avg cost)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.process_purchase(p_invoice_number text, p_supplier_id uuid, p_branch_id uuid, p_warehouse_id uuid, p_subtotal numeric, p_discount_amount numeric, p_tax_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_notes text, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_purchase_id uuid;
  v_user_branch uuid;
  v_item jsonb;
  v_product_id uuid;
  v_raw_id uuid;
  v_quantity numeric(14,4);
  v_unit_cost numeric(12,2);
  v_res jsonb;
  v_unit_name text;
  v_stock numeric(14,4);
  v_stock_val numeric(14,2);
  v_new_cost numeric(12,2);
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    -- Only admins, branch managers and warehouse managers create purchases
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Creating purchases requires the purchases.manage permission.');
    END IF;

    -- Branch isolation (mirror of RLS on purchases)
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Validate items before writing
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_raw_id := (v_item->>'raw_material_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF (v_product_id IS NULL) = (v_raw_id IS NULL) THEN
        RETURN jsonb_build_object('success', false, 'error', 'ITEM_MISSING_TYPE');
      END IF;
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY');
      END IF;
      IF v_product_id IS NOT NULL AND p_warehouse_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_REQUIRED',
          'detail', 'Select a warehouse to receive product items.');
      END IF;
    END LOOP;

    INSERT INTO purchases (invoice_number, supplier_id, branch_id, warehouse_id, buyer_id,
      subtotal, discount_amount, tax_amount, total, paid_amount, payment_method, status, notes)
    VALUES (p_invoice_number, p_supplier_id, p_branch_id, p_warehouse_id, auth.uid(),
      p_subtotal, p_discount_amount, p_tax_amount, p_total, p_paid_amount, p_payment_method, p_status, p_notes)
    RETURNING id INTO v_purchase_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_raw_id := (v_item->>'raw_material_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_cost := COALESCE((v_item->>'unit_cost')::numeric, 0);

      IF v_product_id IS NOT NULL THEN
        INSERT INTO purchase_items (purchase_id, product_id, unit_name, quantity, unit_cost, total)
        VALUES (v_purchase_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
          v_quantity, v_unit_cost, v_quantity * v_unit_cost);

        v_res := public._product_inv_add(v_product_id, p_warehouse_id, p_branch_id, v_quantity,
          v_unit_cost, v_item->>'batch_number',
          (v_item->>'production_date')::date, (v_item->>'expiry_date')::date,
          'purchase', 'purchase', v_purchase_id, p_invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;

        -- Weighted-average cost on the product master
        SELECT COALESCE(SUM(b.quantity), 0), COALESCE(SUM(b.quantity * b.unit_cost), 0)
        INTO v_stock, v_stock_val
        FROM public.inventory_batches b WHERE b.product_id = v_product_id;
        v_new_cost := CASE WHEN v_stock > 0 THEN round(v_stock_val / v_stock, 2) ELSE v_unit_cost END;
        UPDATE public.products SET cost_price = v_new_cost, updated_at = now() WHERE id = v_product_id;
      ELSE
        SELECT COALESCE(u.symbol, u.name, 'ÙˆØ­Ø¯Ø©') INTO v_unit_name
        FROM public.raw_materials rm LEFT JOIN public.units u ON u.id = rm.unit_id
        WHERE rm.id = v_raw_id;

        INSERT INTO purchase_items (purchase_id, raw_material_id, unit_name, quantity, unit_cost, total)
        VALUES (v_purchase_id, v_raw_id, COALESCE(NULLIF(v_item->>'unit_name', ''), v_unit_name),
          v_quantity, v_unit_cost, v_quantity * v_unit_cost);

        v_res := public._raw_add(v_raw_id, p_branch_id, v_quantity, v_unit_cost,
          v_item->>'batch_number', (v_item->>'production_date')::date, (v_item->>'expiry_date')::date,
          'purchase', 'purchase', v_purchase_id, p_invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
      END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'purchase_id', v_purchase_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- =====================================================================
-- SALES (rewritten: FIFO by nearest expiry, no component consumption)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.process_sale(p_invoice_number text, p_branch_id uuid, p_warehouse_id uuid, p_customer_id uuid, p_salesperson_id uuid, p_subtotal numeric, p_discount_amount numeric, p_discount_type text, p_tax_amount numeric, p_bonus_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_items jsonb, p_shift_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_warehouse_ids uuid[];
  v_available numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      -- Branch ownership: the product must belong to the sale branch
      IF NOT EXISTS (
        SELECT 1 FROM products WHERE id = v_product_id AND branch_id = p_branch_id
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH',
          'product_id', v_product_id, 'branch_id', p_branch_id);
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_available
      FROM inventory_batches
      WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
      IF v_available < v_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 1: sale header =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      p_subtotal, p_discount_amount, p_discount_type, p_tax_amount, p_bonus_amount,
      p_total, p_paid_amount, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + FIFO stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
      v_discount_amount := COALESCE((v_item->>'discount_amount')::numeric, 0);
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := COALESCE((v_item->>'total')::numeric, v_quantity * v_unit_price - v_discount_amount);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      v_res := public._product_inv_remove_fifo(v_product_id, NULL, p_branch_id, v_quantity,
        'sale', 'sale', v_sale_id, p_invoice_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
          v_product_id, v_quantity, (v_quantity - v_short);
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', COALESCE(p_paid_amount, 0), p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- =====================================================================
-- REFUNDS (rewritten: restore stock to original warehouses as new batch)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.process_refund(p_sale_id uuid, p_items jsonb DEFAULT NULL::jsonb, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale record;
  v_user_branch uuid;
  v_shift_id uuid;
  v_refund_total numeric(14,2) := 0;
  v_item record;
  v_req jsonb;
  v_item_id uuid;
  v_req_qty numeric(14,4);
  v_already numeric(14,4);
  v_ref_qty numeric(14,4);
  v_item_line_total numeric(14,2);
  v_item_ref_amt numeric(14,2);
  v_all_refunded boolean := true;
  v_remaining numeric(14,4);
  v_back numeric(14,4);
  v_ld record;
  v_res jsonb;
  v_fallback_wh uuid;
  v_last_cost numeric(12,2);
BEGIN
  BEGIN
    IF p_sale_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_SALE');
    END IF;

    SELECT id, branch_id, warehouse_id, status, total, paid_amount
      INTO v_sale FROM public.sales WHERE id = p_sale_id;
    IF v_sale.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'SALE_NOT_FOUND');
    END IF;

    IF v_sale.status = 'returned' THEN
      RETURN jsonb_build_object('success', false, 'error', 'ALREADY_RETURNED');
    END IF;

    -- Permission: refunds.approve (admins always pass)
    IF NOT is_pos_admin() AND NOT can_permission('refunds.approve') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'You need the refunds.approve permission.');
    END IF;

    -- Branch isolation
    SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND v_user_branch IS NOT NULL
       AND v_sale.branch_id IS NOT NULL AND v_user_branch <> v_sale.branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    -- Active shift of the refunding operator (for the drawer log, optional)
    SELECT id INTO v_shift_id FROM shifts
      WHERE cashier_id = auth.uid() AND branch_id = v_sale.branch_id AND status = 'open'
      ORDER BY opened_at DESC LIMIT 1;

    SELECT id INTO v_fallback_wh FROM warehouses
      WHERE branch_id = v_sale.branch_id AND is_active = true ORDER BY created_at LIMIT 1;

    -- ===== VALIDATION PHASE =====
    IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
      FOR v_req IN SELECT * FROM jsonb_array_elements(p_items)
      LOOP
        v_item_id := (v_req->>'sale_item_id')::uuid;
        v_req_qty := COALESCE((v_req->>'quantity')::numeric, 0);
        IF v_req_qty <= 0 THEN
          RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'sale_item_id', v_item_id);
        END IF;
        SELECT id, quantity, refunded_quantity INTO v_item
          FROM sale_items WHERE id = v_item_id AND sale_id = p_sale_id;
        IF v_item.id IS NULL THEN
          RETURN jsonb_build_object('success', false, 'error', 'ITEM_NOT_FOUND', 'sale_item_id', v_item_id);
        END IF;
        v_already := COALESCE(v_item.refunded_quantity, 0);
        IF v_req_qty > v_item.quantity - v_already THEN
          RETURN jsonb_build_object('success', false, 'error', 'REFUND_EXCEEDS_QUANTITY',
            'sale_item_id', v_item_id, 'max', v_item.quantity - v_already);
        END IF;
      END LOOP;
    END IF;

    -- ===== REFUND + RESTOCK PHASE =====
    FOR v_item IN SELECT id, product_id, quantity, unit_price, discount_amount, refunded_quantity
                  FROM sale_items WHERE sale_id = p_sale_id
    LOOP
      IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
        v_req_qty := 0;
        SELECT (req->>'quantity')::numeric INTO v_req_qty
        FROM jsonb_array_elements(p_items) req
        WHERE (req->>'sale_item_id')::uuid = v_item.id;
        v_req_qty := COALESCE(v_req_qty, 0);
      ELSE
        v_req_qty := v_item.quantity - COALESCE(v_item.refunded_quantity, 0);
      END IF;
      IF v_req_qty <= 0 THEN CONTINUE; END IF;

      v_item_line_total := v_item.quantity * v_item.unit_price - v_item.discount_amount;
      IF v_item.quantity > 0 THEN
        v_item_ref_amt := ROUND(v_item_line_total * v_req_qty / v_item.quantity, 2);
      ELSE
        v_item_ref_amt := 0;
      END IF;
      v_refund_total := v_refund_total + v_item_ref_amt;

      UPDATE sale_items
        SET refunded_quantity = COALESCE(refunded_quantity, 0) + v_req_qty,
            refunded_amount = COALESCE(refunded_amount, 0) + v_item_ref_amt
        WHERE id = v_item.id;

      -- Restore stock to the warehouses the sale deducted from (FIFO restore as new batch)
      v_remaining := v_req_qty;
      SELECT COALESCE(l.unit_cost, p.cost_price, 0) INTO v_last_cost
      FROM products p LEFT JOIN inventory_ledger l
        ON l.product_id = p.id AND l.quantity < 0 AND l.reference_type = 'sale'
           AND l.reference_id = p_sale_id
      WHERE p.id = v_item.product_id
      ORDER BY l.id DESC NULLS LAST LIMIT 1;

      FOR v_ld IN
        SELECT l.warehouse_id, l.batch_number, l.unit_cost, -l.quantity AS debited
        FROM inventory_ledger l
        WHERE l.product_id = v_item.product_id AND l.reference_type = 'sale'
          AND l.reference_id = p_sale_id AND l.quantity < 0
        ORDER BY l.id ASC
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_back := LEAST(COALESCE(v_ld.debited, 0), v_remaining);
        IF v_back <= 0 OR v_ld.warehouse_id IS NULL THEN CONTINUE; END IF;
        v_res := public._product_inv_add(v_item.product_id, v_ld.warehouse_id, v_sale.branch_id, v_back,
          COALESCE(v_ld.unit_cost, v_last_cost),
          'R-' || COALESCE(v_ld.batch_number, 'RETURN'), NULL, NULL,
          'refund', 'refund', p_sale_id, NULL, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
        v_remaining := v_remaining - v_back;
      END LOOP;

      IF v_remaining > 0 AND v_fallback_wh IS NOT NULL THEN
        v_res := public._product_inv_add(v_item.product_id, v_fallback_wh, v_sale.branch_id, v_remaining,
          v_last_cost, 'R-RETURN', NULL, NULL, 'refund', 'refund', p_sale_id, NULL, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
      END IF;
    END LOOP;

    -- Update header: full refund flips the status, otherwise accumulate refunded_amount
    SELECT bool_and(quantity = refunded_quantity) INTO v_all_refunded
      FROM sale_items WHERE sale_id = p_sale_id;
    UPDATE sales SET
      refunded_amount = COALESCE(refunded_amount, 0) + v_refund_total,
      status = CASE WHEN v_all_refunded THEN 'returned' ELSE status END,
      notes = CASE WHEN p_reason IS NOT NULL THEN COALESCE(notes, '') || E'\n' || p_reason ELSE notes END
      WHERE id = p_sale_id;

    -- Log the cash-out into the active shift
    IF v_shift_id IS NOT NULL AND v_refund_total > 0 THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'refund', v_refund_total, 'cash', 'refund', p_sale_id, auth.uid());
    END IF;

    RETURN jsonb_build_object('success', true, 'sale_id', p_sale_id,
      'refunded_amount', v_refund_total, 'fully_refunded', v_all_refunded);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- =====================================================================
-- STOCK ADJUSTMENTS (rewritten with ledger) + new adjust_raw_stock
-- =====================================================================
CREATE OR REPLACE FUNCTION public.adjust_stock(p_inventory_id uuid, p_new_quantity numeric, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_inv record;
  v_user_branch uuid;
  v_delta numeric(14,4);
  v_res jsonb;
BEGIN
  BEGIN
    -- Only admins, branch managers and warehouse managers may adjust stock
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Stock adjustments require the warehouse manager or branch manager role.');
    END IF;

    SELECT i.id, i.product_id, i.warehouse_id, i.quantity, i.branch_id, p.cost_price AS cost
    INTO v_inv
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    WHERE i.id = p_inventory_id
    FOR UPDATE OF i;

    IF v_inv.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVENTORY_NOT_FOUND');
    END IF;

    -- Branch isolation
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND v_inv.branch_id IS NOT NULL AND v_user_branch <> v_inv.branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    v_delta := p_new_quantity - v_inv.quantity;
    IF v_delta = 0 THEN
      RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id, 'no_change', true);
    END IF;

    IF v_delta > 0 THEN
      v_res := public._product_inv_add(v_inv.product_id, v_inv.warehouse_id, v_inv.branch_id, v_delta,
        COALESCE(v_inv.cost, 0), 'ADJ', NULL, NULL,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
    ELSE
      v_res := public._product_inv_remove_fifo(v_inv.product_id, v_inv.warehouse_id, v_inv.branch_id, -v_delta,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
    END IF;

    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.adjust_raw_stock(p_raw_material_id uuid, p_branch_id uuid, p_new_quantity numeric, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_cur numeric(14,4);
  v_delta numeric(14,4);
  v_user_branch uuid;
  v_res jsonb;
  v_cost numeric(12,2);
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Raw material adjustments require the warehouse manager or branch manager role.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    SELECT COALESCE(quantity, 0), COALESCE(avg_cost, 0)
    INTO v_cur, v_cost
    FROM public.raw_material_inventory
    WHERE raw_material_id = p_raw_material_id AND branch_id = p_branch_id;
    IF v_cur IS NULL THEN v_cur := 0; END IF;

    v_delta := p_new_quantity - v_cur;
    IF v_delta = 0 THEN
      RETURN jsonb_build_object('success', true, 'raw_material_id', p_raw_material_id, 'no_change', true);
    END IF;

    IF v_delta > 0 THEN
      v_res := public._raw_add(p_raw_material_id, p_branch_id, v_delta, v_cost,
        'ADJ', NULL, NULL, 'adjustment', 'adjustment', NULL, p_reason, auth.uid());
    ELSE
      v_res := public._raw_remove_fifo(p_raw_material_id, p_branch_id, -v_delta,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
    END IF;

    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    RETURN jsonb_build_object('success', true, 'raw_material_id', p_raw_material_id, 'quantity', p_new_quantity);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 014_manufacturing_policies.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase B3: relax write policies for permission-gated roles
-- =====================================================================
-- The B1 schema locked writes on master data to is_pos_admin() only, but
-- production_manager (and other roles) hold manage permissions via the
-- `roles` table. Relax policies so those roles can manage master data
-- through the frontend, consistent with the can_permission() checks used
-- by the SECURITY DEFINER RPCs.
-- =====================================================================

DROP POLICY IF EXISTS raw_materials_write ON public.raw_materials;
CREATE POLICY raw_materials_write ON public.raw_materials
  FOR ALL TO authenticated
  USING (can_permission('raw_materials.manage'))
  WITH CHECK (can_permission('raw_materials.manage'));

DROP POLICY IF EXISTS raw_material_inventory_write ON public.raw_material_inventory;
CREATE POLICY raw_material_inventory_write ON public.raw_material_inventory
  FOR ALL TO authenticated
  USING (is_pos_admin() OR (can_permission('raw_materials.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('raw_materials.manage') AND branch_id = get_branch_id()));

DROP POLICY IF EXISTS raw_material_batches_write ON public.raw_material_batches;
CREATE POLICY raw_material_batches_write ON public.raw_material_batches
  FOR ALL TO authenticated
  USING (is_pos_admin() OR (can_permission('raw_materials.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('raw_materials.manage') AND branch_id = get_branch_id()));

DROP POLICY IF EXISTS recipes_write ON public.recipes;
CREATE POLICY recipes_write ON public.recipes
  FOR ALL TO authenticated
  USING (is_pos_admin() OR (can_permission('recipes.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('recipes.manage') AND branch_id = get_branch_id()));

DROP POLICY IF EXISTS recipe_items_write ON public.recipe_items;
CREATE POLICY recipe_items_write ON public.recipe_items
  FOR ALL TO authenticated
  USING (
    is_pos_admin() OR (
      can_permission('recipes.manage') AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_items.recipe_id AND r.branch_id = get_branch_id()
      )
    )
  )
  WITH CHECK (
    is_pos_admin() OR (
      can_permission('recipes.manage') AND EXISTS (
        SELECT 1 FROM public.recipes r
        WHERE r.id = recipe_items.recipe_id AND r.branch_id = get_branch_id()
      )
    )
  );



-- ----------------------------------------------------------------------------
-- MIGRATION: 015_accounting_schema.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase C1: Chart of Accounts + Journal Entries schema
-- =====================================================================
-- Adds: chart_of_accounts, journal_entries, journal_entry_lines,
--       customer_payments. Auto-seeds a standard chart of accounts per
--       branch (system accounts are locked; others editable). Journal
--       entries are immutable (audit trail) and branch-scoped.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Chart of accounts (one chart per branch, seeded automatically)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  code          text NOT NULL,
  name          text NOT NULL,
  name_en       text,
  account_type  text NOT NULL
                CHECK (account_type IN ('asset', 'liability', 'equity', 'income', 'expense')),
  is_system     boolean NOT NULL DEFAULT false,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, code)
);
COMMENT ON TABLE public.chart_of_accounts IS 'Ø´Ø¬Ø±Ø© Ø§Ù„Ø­Ø³Ø§Ø¨Ø§Øª Ø§Ù„Ù…Ø³ØªÙ‚Ù„Ø© Ù„ÙƒÙ„ ÙØ±Ø¹ (ÙŠØªÙ… ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹ Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨Ø§Øª Ù†Ø¸Ø§Ù… Ø¹Ù†Ø¯ Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„ÙØ±Ø¹)';

CREATE INDEX IF NOT EXISTS idx_coa_branch ON public.chart_of_accounts (branch_id, account_type);

-- System account codes used by auto-posting (resolved by code within a branch).
-- These must never be deleted and their code/type must never change.
CREATE OR REPLACE FUNCTION public.protect_system_accounts()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' AND OLD.is_system THEN
    RAISE EXCEPTION 'SYSTEM_ACCOUNT_PROTECTED: % (%)', OLD.code, OLD.name;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.is_system THEN
    IF NEW.code IS DISTINCT FROM OLD.code OR NEW.account_type IS DISTINCT FROM OLD.account_type THEN
      RAISE EXCEPTION 'SYSTEM_ACCOUNT_PROTECTED: % (%)', OLD.code, OLD.name;
    END IF;
  END IF;
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    NEW.name := btrim(NEW.name);
    IF NEW.name = '' THEN
      RAISE EXCEPTION 'ACCOUNT_NAME_REQUIRED';
    END IF;
    NEW.code := upper(btrim(NEW.code));
    IF NEW.code = '' THEN
      RAISE EXCEPTION 'ACCOUNT_CODE_REQUIRED';
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_system_accounts ON public.chart_of_accounts;
CREATE TRIGGER trg_protect_system_accounts
  BEFORE INSERT OR UPDATE OR DELETE ON public.chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION public.protect_system_accounts();

CREATE TRIGGER trg_coa_updated BEFORE UPDATE ON public.chart_of_accounts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "coa_select" ON public.chart_of_accounts
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "coa_insert" ON public.chart_of_accounts
  FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
CREATE POLICY "coa_update" ON public.chart_of_accounts
  FOR UPDATE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
CREATE POLICY "coa_delete" ON public.chart_of_accounts
  FOR DELETE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));

-- ---------------------------------------------------------------------
-- 2. Standard chart seed (called for every branch + on new branch insert)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ensure_chart_of_accounts(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.chart_of_accounts (branch_id, code, name, name_en, account_type, is_system)
  SELECT p_branch_id, c.code, c.name, c.name_en, c.account_type, c.is_system
  FROM (VALUES
    ('1000','Ø§Ù„Ù†Ù‚Ø¯ÙŠØ© Ø¨Ø§Ù„Ø®Ø²ÙŠÙ†Ø©','Cash on Hand','asset',true),
    ('1010','Ø§Ù„Ø¨Ù†Ùƒ','Bank','asset',true),
    ('1100','Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡ (Ø°Ù…Ù… Ù…Ø¯ÙŠÙ†Ø©)','Accounts Receivable','asset',true),
    ('1200','Ø§Ù„Ù…Ø®Ø²ÙˆÙ† (Ø¨Ø¶Ø§Ø¹Ø© Ø¬Ø§Ù‡Ø²Ø©)','Finished Goods Inventory','asset',true),
    ('1210','Ù…Ø®Ø²ÙˆÙ† Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù…','Raw Materials Inventory','asset',false),
    ('1500','Ø§Ù„Ø£ØµÙˆÙ„ Ø§Ù„Ø«Ø§Ø¨ØªØ©','Fixed Assets','asset',false),
    ('2000','Ø§Ù„Ù…ÙˆØ±Ø¯ÙˆÙ† (Ø°Ù…Ù… Ø¯Ø§Ø¦Ù†Ø©)','Accounts Payable','liability',true),
    ('2100','Ø¶Ø±ÙŠØ¨Ø© Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ù…Ø¶Ø§ÙØ© Ø§Ù„Ù…Ø³ØªØ­Ù‚Ø©','VAT Payable','liability',true),
    ('2300','Ø§Ù„Ù‚Ø±ÙˆØ¶','Loans','liability',false),
    ('3000','Ø±Ø£Ø³ Ø§Ù„Ù…Ø§Ù„','Capital','equity',false),
    ('3100','Ø§Ù„Ø£Ø±Ø¨Ø§Ø­ Ø§Ù„Ù…Ø­ØªØ¬Ø²Ø©','Retained Earnings','equity',false),
    ('4000','Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª','Sales Revenue','income',true),
    ('4100','Ø®ØµÙ… Ù…Ø³Ù…ÙˆØ­ Ø¨Ù‡','Discount Given','income',true),
    ('4200','Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø£Ø®Ø±Ù‰','Other Income','income',false),
    ('5000','ØªÙƒÙ„ÙØ© Ø§Ù„Ø¨Ø¶Ø§Ø¹Ø© Ø§Ù„Ù…Ø¨Ø§Ø¹Ø©','Cost of Goods Sold','expense',true),
    ('5100','Ù…ØµØ§Ø±ÙŠÙ ØªØ´ØºÙŠÙ„ÙŠØ©','Operating Expenses','expense',false),
    ('5200','Ø£Ø¬ÙˆØ± ÙˆØ±ÙˆØ§ØªØ¨','Salaries & Wages','expense',false),
    ('5300','Ø¥ÙŠØ¬Ø§Ø±','Rent','expense',false),
    ('5400','Ù…Ø±Ø§ÙÙ‚','Utilities','expense',false),
    ('5900','Ù…ØµØ§Ø±ÙŠÙ Ø£Ø®Ø±Ù‰','Other Expenses','expense',false)
  ) AS c(code, name, name_en, account_type, is_system)
  ON CONFLICT (branch_id, code) DO UPDATE SET
    name = EXCLUDED.name,
    name_en = EXCLUDED.name_en,
    account_type = EXCLUDED.account_type,
    is_system = COALESCE(public.chart_of_accounts.is_system, EXCLUDED.is_system),
    updated_at = now();
END;
$function$;

-- Seed every existing branch now and every future branch automatically.
SELECT public.ensure_chart_of_accounts(id) FROM public.branches;

CREATE OR REPLACE FUNCTION public.seed_chart_for_new_branch()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  PERFORM public.ensure_chart_of_accounts(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_seed_chart_on_branch_insert ON public.branches;
CREATE TRIGGER trg_seed_chart_on_branch_insert
  AFTER INSERT ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.seed_chart_for_new_branch();

-- ---------------------------------------------------------------------
-- 3. Journal entries (immutable audit trail)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_number      text NOT NULL UNIQUE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  entry_date        date NOT NULL DEFAULT CURRENT_DATE,
  reference_type    text,
  reference_id      uuid,
  reference_number  text,
  description       text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.journal_entries IS 'Ù‚ÙŠÙˆØ¯ Ø§Ù„ÙŠÙˆÙ…ÙŠØ© (ÙƒÙ„ Ù‚ÙŠØ¯ Ù…Ø¯ÙŠÙ† = Ø¯Ø§Ø¦Ù† ØªÙ„Ù‚Ø§Ø¦ÙŠØ§Ù‹)';

CREATE INDEX IF NOT EXISTS idx_journal_branch_date ON public.journal_entries (branch_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_journal_reference ON public.journal_entries (reference_type, reference_id);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "journal_entries_select" ON public.journal_entries
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "journal_entries_insert" ON public.journal_entries
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
-- No UPDATE / DELETE policies: posted entries are immutable.

CREATE TABLE IF NOT EXISTS public.journal_entry_lines (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  journal_entry_id  uuid NOT NULL REFERENCES public.journal_entries(id) ON DELETE CASCADE,
  account_id        uuid NOT NULL REFERENCES public.chart_of_accounts(id),
  debit             numeric(14,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
  credit            numeric(14,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
  customer_id       uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  supplier_id       uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  note              text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  CHECK ((debit > 0) <> (credit > 0))
);
COMMENT ON TABLE public.journal_entry_lines IS 'Ø£Ø·Ø±Ø§Ù Ù‚ÙŠØ¯ Ø§Ù„ÙŠÙˆÙ…ÙŠØ© (Ù…Ø¯ÙŠÙ† Ø£Ùˆ Ø¯Ø§Ø¦Ù† Ù„ÙƒÙ„ Ø­Ø³Ø§Ø¨)';

CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON public.journal_entry_lines (journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_lines_account ON public.journal_entry_lines (account_id, created_at);

ALTER TABLE public.journal_entry_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "journal_entry_lines_select" ON public.journal_entry_lines
  FOR SELECT TO authenticated USING (
    is_pos_admin() OR EXISTS (
      SELECT 1 FROM public.journal_entries je
      WHERE je.id = journal_entry_lines.journal_entry_id AND je.branch_id = get_branch_id()
    )
  );
CREATE POLICY "journal_entry_lines_insert" ON public.journal_entry_lines
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
-- No UPDATE / DELETE policies.

-- ---------------------------------------------------------------------
-- 4. Customer payments (AR collections)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customer_payments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id       uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  amount            numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_method    text NOT NULL DEFAULT 'cash',
  sale_id           uuid REFERENCES public.sales(id) ON DELETE SET NULL,
  reference_number  text,
  notes             text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.customer_payments IS 'Ø³Ù†Ø¯Ø§Øª Ø§Ù„Ù‚Ø¨Ø¶ (ØªØ­ØµÙŠÙ„ Ù…Ù† Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡ Ù…Ù‚Ø§Ø¨Ù„ Ø°Ù…Ù… Ù…Ø¯ÙŠÙ†Ø©)';

CREATE INDEX IF NOT EXISTS idx_customer_payments_customer ON public.customer_payments (customer_id, created_at);

ALTER TABLE public.customer_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_payments_select" ON public.customer_payments
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "customer_payments_insert" ON public.customer_payments
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 5. Document sequence for journal entries
-- ---------------------------------------------------------------------
INSERT INTO public.document_sequences (seq_type, next_value) VALUES ('journal', 1)
ON CONFLICT (seq_type) DO NOTHING;



-- ----------------------------------------------------------------------------
-- MIGRATION: 016_accounting_rpc.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase C2: Auto-posting (sales + COGS) and financial report RPCs
-- =====================================================================
-- Adds: _post_journal_entry internal helper, process_sale updated to post
--       its journal entry in the same transaction, receive_payment for AR
--       collections, and read-only report RPCs (trial balance, general
--       ledger, income statement, balance sheet, AR aging) + opening
--       balance seed.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Internal helper: post a balanced journal entry by account code
--    p_lines = [{"account_code","debit","credit","customer_id","supplier_id","note"}]
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._post_journal_entry(
  p_branch_id uuid,
  p_reference_type text,
  p_reference_id uuid,
  p_reference_number text,
  p_description text,
  p_lines jsonb
) RETURNS uuid
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_entry_id uuid;
  v_entry_no text;
  v_line jsonb;
  v_account uuid;
  v_debit numeric(14,2);
  v_credit numeric(14,2);
  v_total_debit numeric(14,2) := 0;
  v_total_credit numeric(14,2) := 0;
BEGIN
  IF p_lines IS NULL OR jsonb_array_length(p_lines) = 0 THEN
    RAISE EXCEPTION 'JOURNAL_EMPTY_LINES';
  END IF;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::numeric, 0);
    v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::numeric, 0);
  END LOOP;

  IF round(v_total_debit, 2) <> round(v_total_credit, 2) THEN
    RAISE EXCEPTION 'JOURNAL_UNBALANCED: debit % <> credit %',
      round(v_total_debit, 2), round(v_total_credit, 2);
  END IF;

  v_entry_no := (public.next_document_number('journal')->>'number')::text;

  INSERT INTO public.journal_entries
    (entry_number, branch_id, entry_date, reference_type, reference_id, reference_number, description, created_by)
  VALUES (v_entry_no, p_branch_id, CURRENT_DATE, p_reference_type, p_reference_id,
          p_reference_number, p_description, auth.uid())
  RETURNING id INTO v_entry_id;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_debit := COALESCE((v_line->>'debit')::numeric, 0);
    v_credit := COALESCE((v_line->>'credit')::numeric, 0);
    IF v_debit <= 0 AND v_credit <= 0 THEN CONTINUE; END IF;

    SELECT id INTO v_account
    FROM public.chart_of_accounts
    WHERE branch_id = p_branch_id AND code = btrim((v_line->>'account_code')::text);
    IF v_account IS NULL THEN
      RAISE EXCEPTION 'ACCOUNT_NOT_FOUND: %', v_line->>'account_code';
    END IF;

    INSERT INTO public.journal_entry_lines
      (journal_entry_id, account_id, debit, credit, customer_id, supplier_id, note)
    VALUES (v_entry_id, v_account, v_debit, v_credit,
            (v_line->>'customer_id')::uuid, (v_line->>'supplier_id')::uuid, v_line->>'note');
  END LOOP;

  RETURN v_entry_id;
END;
$function$;

-- ---------------------------------------------------------------------
-- 2. process_sale: rewritten to ALSO post the sales + COGS journal entry
--    (revenue / discount / VAT / cash|AR on the credit side balance,
--     COGS vs inventory on the stock side) inside the same transaction.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_sale(p_invoice_number text, p_branch_id uuid, p_warehouse_id uuid, p_customer_id uuid, p_salesperson_id uuid, p_subtotal numeric, p_discount_amount numeric, p_discount_type text, p_tax_amount numeric, p_bonus_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_items jsonb, p_shift_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_warehouse_ids uuid[];
  v_available numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cogs_total numeric(14,2) := 0;
  v_paid numeric(14,2);
  v_ar numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
  v_balance_account text;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      -- Branch ownership: the product must belong to the sale branch
      IF NOT EXISTS (
        SELECT 1 FROM products WHERE id = v_product_id AND branch_id = p_branch_id
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH',
          'product_id', v_product_id, 'branch_id', p_branch_id);
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_available
      FROM inventory_batches
      WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
      IF v_available < v_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 1: sale header =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      p_subtotal, p_discount_amount, p_discount_type, p_tax_amount, p_bonus_amount,
      p_total, p_paid_amount, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + FIFO stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
      v_discount_amount := COALESCE((v_item->>'discount_amount')::numeric, 0);
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := COALESCE((v_item->>'total')::numeric, v_quantity * v_unit_price - v_discount_amount);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      v_res := public._product_inv_remove_fifo(v_product_id, NULL, p_branch_id, v_quantity,
        'sale', 'sale', v_sale_id, p_invoice_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
          v_product_id, v_quantity, (v_quantity - v_short);
      END IF;
      v_cogs_total := v_cogs_total + COALESCE((v_res->>'total_cost')::numeric, 0);
    END LOOP;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', COALESCE(p_paid_amount, 0), p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    -- ===== WRITE PHASE 4: post the sales + COGS journal entry =====
    v_paid := round(COALESCE(p_paid_amount, 0), 2);
    v_ar := round(GREATEST(COALESCE(p_total, 0) - v_paid, 0), 2);

    IF v_paid > 0 THEN
      v_balance_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN '1000' ELSE '1010' END;
      v_lines := v_lines || jsonb_build_object('account_code', v_balance_account,
        'debit', v_paid, 'credit', 0, 'note', p_invoice_number);
      v_dr := v_dr + v_paid;
    END IF;
    IF v_ar > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '1100',
        'debit', v_ar, 'credit', 0, 'customer_id', p_customer_id, 'note', p_invoice_number);
      v_dr := v_dr + v_ar;
    END IF;
    IF COALESCE(p_discount_amount, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '4100', 'debit', p_discount_amount, 'credit', 0);
      v_dr := v_dr + p_discount_amount;
    END IF;
    IF COALESCE(p_subtotal, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '4000', 'debit', 0, 'credit', p_subtotal);
      v_cr := v_cr + p_subtotal;
    END IF;
    IF COALESCE(p_tax_amount, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '2100', 'debit', 0, 'credit', p_tax_amount);
      v_cr := v_cr + p_tax_amount;
    END IF;
    IF v_cogs_total > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '5000', 'debit', v_cogs_total, 'credit', 0);
      v_lines := v_lines || jsonb_build_object('account_code', '1200', 'debit', 0, 'credit', v_cogs_total);
      v_dr := v_dr + v_cogs_total;
      v_cr := v_cr + v_cogs_total;
    END IF;

    -- Balance any rounding/frontend discrepancy on the discount account so a
    -- posted entry is always balanced (normally the difference is zero).
    v_diff := round(v_dr - v_cr, 2);
    IF v_diff <> 0 THEN
      IF v_diff > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_code', '4100', 'debit', 0, 'credit', v_diff);
      ELSE
        v_lines := v_lines || jsonb_build_object('account_code', '4100', 'debit', -v_diff, 'credit', 0);
      END IF;
    END IF;

    PERFORM public._post_journal_entry(p_branch_id, 'sale', v_sale_id, p_invoice_number,
      'ÙØ§ØªÙˆØ±Ø© Ù…Ø¨ÙŠØ¹Ø§Øª ' || p_invoice_number, v_lines);

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number,
      'cogs', v_cogs_total);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 3. Opening balance seed: current stock value -> capital (per branch)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.seed_opening_balances(p_branch_id uuid)
RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_finished numeric(14,2);
  v_raw numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_total numeric(14,2) := 0;
BEGIN
  BEGIN
    IF NOT is_pos_admin() THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE branch_id = p_branch_id AND reference_type = 'opening'
    ) THEN
      RETURN jsonb_build_object('success', false, 'error', 'OPENING_ALREADY_EXISTS');
    END IF;

    SELECT COALESCE(SUM(b.quantity * b.unit_cost), 0) INTO v_finished
    FROM public.inventory_batches b WHERE b.branch_id = p_branch_id;

    SELECT COALESCE(SUM(b.quantity * b.unit_cost), 0) INTO v_raw
    FROM public.raw_material_batches b WHERE b.branch_id = p_branch_id;

    v_total := round(v_finished + v_raw, 2);
    IF v_total <= 0 THEN
      RETURN jsonb_build_object('success', true, 'skipped', true, 'total', 0);
    END IF;

    IF v_finished > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '1200', 'debit', round(v_finished, 2), 'credit', 0, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…Ø®Ø²ÙˆÙ†');
    END IF;
    IF v_raw > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_code', '1210', 'debit', round(v_raw, 2), 'credit', 0, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù…');
    END IF;
    v_lines := v_lines || jsonb_build_object('account_code', '3000', 'debit', 0, 'credit', v_total, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ');

    PERFORM public._post_journal_entry(p_branch_id, 'opening', NULL, 'OPENING',
      'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…Ø®Ø²ÙˆÙ†', v_lines);

    RETURN jsonb_build_object('success', true, 'total', v_total, 'finished', v_finished, 'raw', v_raw);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. receive_payment: collect AR, optionally against a specific invoice
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.receive_payment(
  p_customer_id uuid, p_branch_id uuid, p_amount numeric,
  p_payment_method text DEFAULT 'cash', p_sale_id uuid DEFAULT NULL, p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_payment_id uuid;
  v_number text;
  v_user_branch uuid;
  v_remaining numeric(14,2);
  v_sale record;
  v_applied numeric(14,2);
  v_open numeric(14,2);
  v_total_open numeric(14,2);
  v_payment_account text;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager', 'cashier') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE id = p_customer_id AND branch_id = p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'CUSTOMER_NOT_FOUND');
    END IF;

    -- Payments must be backed by open receivable (no free-floating credits).
    SELECT COALESCE(SUM(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)), 0)
    INTO v_total_open
    FROM public.sales s
    WHERE s.customer_id = p_customer_id AND s.branch_id = p_branch_id AND s.status <> 'returned';

    IF p_sale_id IS NULL THEN
      IF round(p_amount, 2) > round(v_total_open, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_AR',
          'open', round(v_total_open, 2), 'detail', 'The payment exceeds the customer open balance.');
      END IF;
    ELSE
      SELECT total, COALESCE(paid_amount, 0), COALESCE(refunded_amount, 0) INTO v_sale
      FROM public.sales WHERE id = p_sale_id AND customer_id = p_customer_id AND branch_id = p_branch_id
        AND status <> 'returned' FOR UPDATE;
      IF v_sale.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'SALE_NOT_FOUND',
          'detail', 'No open invoice found for this customer with that id.');
      END IF;
      IF round(p_amount, 2) > round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_INVOICE',
          'open', round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2));
      END IF;
    END IF;

    v_number := (public.next_document_number('payment')->>'number')::text;

    INSERT INTO public.customer_payments (customer_id, branch_id, amount, payment_method, sale_id, reference_number, notes, created_by)
    VALUES (p_customer_id, p_branch_id, p_amount, p_payment_method, p_sale_id, v_number, p_notes, auth.uid())
    RETURNING id INTO v_payment_id;

    -- Apply payment against invoices (specific or oldest open first)
    v_remaining := round(p_amount, 2);

    IF p_sale_id IS NOT NULL THEN
      v_open := round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2);
      v_applied := LEAST(v_remaining, v_open);
      UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
      WHERE id = p_sale_id;
      v_remaining := round(v_remaining - v_applied, 2);
    ELSIF v_remaining > 0 THEN
      FOR v_sale IN
        SELECT id, total, paid_amount, refunded_amount FROM public.sales
        WHERE customer_id = p_customer_id AND branch_id = p_branch_id AND status <> 'returned'
          AND (total - COALESCE(paid_amount, 0) - COALESCE(refunded_amount, 0)) > 0
        ORDER BY created_at ASC
        FOR UPDATE
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_open := round(v_sale.total - COALESCE(v_sale.paid_amount, 0) - COALESCE(v_sale.refunded_amount, 0), 2);
        v_applied := LEAST(v_remaining, v_open);
        UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
        WHERE id = v_sale.id;
        v_remaining := round(v_remaining - v_applied, 2);
      END LOOP;
    END IF;

    -- Post the collection journal entry
    v_payment_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN '1000' ELSE '1010' END;
    v_lines := v_lines || jsonb_build_object('account_code', v_payment_account,
      'debit', round(p_amount, 2), 'credit', 0, 'note', v_number);
    v_lines := v_lines || jsonb_build_object('account_code', '1100',
      'debit', 0, 'credit', round(p_amount, 2), 'customer_id', p_customer_id, 'note', v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'payment', v_payment_id, v_number,
      'Ø³Ù†Ø¯ Ù‚Ø¨Ø¶ ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'payment_id', v_payment_id, 'reference_number', v_number,
      'unapplied', v_remaining);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. Reports
-- ---------------------------------------------------------------------

-- Trial balance: every account with total debit, total credit, net balance
CREATE OR REPLACE FUNCTION public.get_trial_balance(p_branch_id uuid, p_to_date date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.code), '[]'::jsonb)
FROM (
  SELECT a.code, a.name, a.name_en, a.account_type,
         COALESCE(SUM(l.debit), 0) AS debit,
         COALESCE(SUM(l.credit), 0) AS credit,
         round(COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0), 2) AS balance
  FROM public.chart_of_accounts a
  LEFT JOIN public.journal_entry_lines l ON l.account_id = a.id
  LEFT JOIN public.journal_entries j ON j.id = l.journal_entry_id
    AND j.branch_id = p_branch_id AND j.entry_date <= p_to_date
  WHERE a.branch_id = p_branch_id AND a.is_active
  GROUP BY a.code, a.name, a.name_en, a.account_type
  HAVING COALESCE(SUM(l.debit), 0) <> 0 OR COALESCE(SUM(l.credit), 0) <> 0
) row;
$function$;

-- General ledger: all lines of one account with running balance
CREATE OR REPLACE FUNCTION public.get_general_ledger(
  p_branch_id uuid, p_account_id uuid,
  p_from_date date DEFAULT NULL, p_to_date date DEFAULT NULL
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.entry_date, row.entry_number, row.line_id), '[]'::jsonb)
FROM (
  SELECT l.id AS line_id, j.entry_date, j.entry_number, j.description, j.reference_number,
         l.debit, l.credit,
         round(SUM(
           CASE WHEN a.account_type IN ('asset', 'expense') THEN l.debit - l.credit
                ELSE l.credit - l.debit END
         ) OVER (ORDER BY j.entry_date, j.entry_number, l.id), 2) AS balance
  FROM public.journal_entry_lines l
  JOIN public.journal_entries j ON j.id = l.journal_entry_id
  JOIN public.chart_of_accounts a ON a.id = l.account_id
  WHERE l.account_id = p_account_id AND j.branch_id = p_branch_id
    AND (p_from_date IS NULL OR j.entry_date >= p_from_date)
    AND (p_to_date IS NULL OR j.entry_date <= p_to_date)
) row;
$function$;

-- Income statement (single period)
CREATE OR REPLACE FUNCTION public.get_income_statement(
  p_branch_id uuid, p_from_date date, p_to_date date DEFAULT CURRENT_DATE
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT jsonb_build_object(
  'revenue',      round(COALESCE(SUM(CASE WHEN a.code IN ('4000','4200') THEN l.credit - l.debit ELSE 0 END), 0), 2),
  'discount',     round(COALESCE(SUM(CASE WHEN a.code = '4100' THEN l.debit - l.credit ELSE 0 END), 0), 2),
  'net_revenue',  round(COALESCE(SUM(CASE WHEN a.code IN ('4000','4200') THEN l.credit - l.debit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.code = '4100' THEN l.debit - l.credit ELSE 0 END), 0), 2),
  'cogs',         round(COALESCE(SUM(CASE WHEN a.code = '5000' THEN l.debit - l.credit ELSE 0 END), 0), 2),
  'gross_profit', round(
                  COALESCE(SUM(CASE WHEN a.code IN ('4000','4200') THEN l.credit - l.debit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.code = '4100' THEN l.debit - l.credit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.code = '5000' THEN l.debit - l.credit ELSE 0 END), 0), 2),
  'expenses',     round(COALESCE(SUM(CASE WHEN a.account_type = 'expense' AND a.code <> '5000' THEN l.debit - l.credit ELSE 0 END), 0), 2),
  'net_income',   round(
                  COALESCE(SUM(CASE WHEN a.code IN ('4000','4200') THEN l.credit - l.debit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.code = '4100' THEN l.debit - l.credit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.code = '5000' THEN l.debit - l.credit ELSE 0 END), 0)
                  - COALESCE(SUM(CASE WHEN a.account_type = 'expense' AND a.code <> '5000' THEN l.debit - l.credit ELSE 0 END), 0), 2)
)
FROM public.journal_entry_lines l
JOIN public.journal_entries j ON j.id = l.journal_entry_id
JOIN public.chart_of_accounts a ON a.id = l.account_id
WHERE j.branch_id = p_branch_id
  AND j.entry_date >= p_from_date AND j.entry_date <= p_to_date;
$function$;

-- Balance sheet as of a date
CREATE OR REPLACE FUNCTION public.get_balance_sheet(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH bal AS (
  SELECT a.account_type, a.code,
         COALESCE(SUM(l.debit), 0) AS debit,
         COALESCE(SUM(l.credit), 0) AS credit
  FROM public.chart_of_accounts a
  LEFT JOIN public.journal_entry_lines l ON l.account_id = a.id
  LEFT JOIN public.journal_entries j ON j.id = l.journal_entry_id
    AND j.branch_id = p_branch_id AND j.entry_date <= p_as_of
  WHERE a.branch_id = p_branch_id AND a.is_active
  GROUP BY a.account_type, a.code
), summary AS (
  SELECT
    round(COALESCE(SUM(CASE WHEN account_type = 'asset' THEN debit - credit ELSE 0 END), 0), 2) AS assets,
    round(COALESCE(SUM(CASE WHEN account_type = 'liability' THEN credit - debit ELSE 0 END), 0), 2) AS liabilities,
    round(COALESCE(SUM(CASE WHEN code = '3000' THEN credit - debit ELSE 0 END), 0), 2) AS capital,
    round(COALESCE(SUM(CASE WHEN code = '3100' THEN credit - debit ELSE 0 END), 0), 2) AS retained,
    round(COALESCE(SUM(CASE WHEN account_type = 'income' THEN credit - debit ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN account_type = 'expense' THEN debit - credit ELSE 0 END), 0), 2) AS net_income
  FROM bal
)
SELECT jsonb_build_object(
  'assets', assets,
  'liabilities', liabilities,
  'capital', capital,
  'retained', retained,
  'net_income', net_income,
  'equity', round(capital + retained + net_income, 2),
  'balanced', round(assets - (liabilities + capital + retained + net_income), 2) = 0
)
FROM summary;
$function$;

-- AR aging: open receivable per customer in 30-day buckets
CREATE OR REPLACE FUNCTION public.get_ar_aging(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.open_amount DESC), '[]'::jsonb)
FROM (
  SELECT c.id AS customer_id, c.name, c.phone,
         sum(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)) AS open_amount,
         round(sum(CASE WHEN (p_as_of - s.created_at::date) <= 30 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_0_30,
         round(sum(CASE WHEN (p_as_of - s.created_at::date) BETWEEN 31 AND 60 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_31_60,
         round(sum(CASE WHEN (p_as_of - s.created_at::date) BETWEEN 61 AND 90 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_61_90,
         round(sum(CASE WHEN (p_as_of - s.created_at::date) > 90 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_90_plus
  FROM public.sales s
  JOIN public.customers c ON c.id = s.customer_id
  WHERE s.branch_id = p_branch_id AND s.status <> 'returned'
    AND (s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)) > 0
  GROUP BY c.id, c.name, c.phone
) row;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 017_accounting_permissions.sql
-- ----------------------------------------------------------------------------

-- Add Phase C permission keys to DB `roles` rows (source of truth for
-- DB-side can_permission() checks and the frontend RolesContext map).
DO $$
DECLARE
  r text;
BEGIN
  FOREACH r IN ARRAY ARRAY['accounts.view', 'accounts.manage', 'reports.financial']::text[] LOOP
    UPDATE public.roles
    SET permissions = permissions || to_jsonb(r)
    WHERE role IN ('branch_manager', 'accountant')
      AND NOT (permissions ? r);
  END LOOP;
END $$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 018_accounting_fixes.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase C fixes
-- =====================================================================
-- 1. products.updated_at: process_purchase's weighted-cost update writes
--    products.updated_at but the column never existed (latent B2 bug that
--    broke any product-line purchase). Add the column + timestamp trigger.
-- 2. receive_payment redefinition: reject payments that exceed the open
--    receivable (no free-floating AR credits).
-- =====================================================================

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DROP TRIGGER IF EXISTS trg_products_updated ON public.products;
CREATE TRIGGER trg_products_updated BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();



CREATE OR REPLACE FUNCTION public.receive_payment(
  p_customer_id uuid, p_branch_id uuid, p_amount numeric,
  p_payment_method text DEFAULT 'cash', p_sale_id uuid DEFAULT NULL, p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_payment_id uuid;
  v_number text;
  v_user_branch uuid;
  v_remaining numeric(14,2);
  v_sale record;
  v_applied numeric(14,2);
  v_open numeric(14,2);
  v_total_open numeric(14,2);
  v_payment_account text;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager', 'cashier') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE id = p_customer_id AND branch_id = p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'CUSTOMER_NOT_FOUND');
    END IF;

    -- Payments must be backed by open receivable (no free-floating credits).
    SELECT COALESCE(SUM(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)), 0)
    INTO v_total_open
    FROM public.sales s
    WHERE s.customer_id = p_customer_id AND s.branch_id = p_branch_id AND s.status <> 'returned';

    IF p_sale_id IS NULL THEN
      IF round(p_amount, 2) > round(v_total_open, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_AR',
          'open', round(v_total_open, 2), 'detail', 'The payment exceeds the customer open balance.');
      END IF;
    ELSE
      SELECT total, COALESCE(paid_amount, 0), COALESCE(refunded_amount, 0) INTO v_sale
      FROM public.sales WHERE id = p_sale_id AND customer_id = p_customer_id AND branch_id = p_branch_id
        AND status <> 'returned' FOR UPDATE;
      IF v_sale.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'SALE_NOT_FOUND',
          'detail', 'No open invoice found for this customer with that id.');
      END IF;
      IF round(p_amount, 2) > round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_INVOICE',
          'open', round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2));
      END IF;
    END IF;

    v_number := (public.next_document_number('payment')->>'number')::text;

    INSERT INTO public.customer_payments (customer_id, branch_id, amount, payment_method, sale_id, reference_number, notes, created_by)
    VALUES (p_customer_id, p_branch_id, p_amount, p_payment_method, p_sale_id, v_number, p_notes, auth.uid())
    RETURNING id INTO v_payment_id;

    -- Apply payment against invoices (specific or oldest open first)
    v_remaining := round(p_amount, 2);

    IF p_sale_id IS NOT NULL THEN
      v_open := round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2);
      v_applied := LEAST(v_remaining, v_open);
      UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
      WHERE id = p_sale_id;
      v_remaining := round(v_remaining - v_applied, 2);
    ELSIF v_remaining > 0 THEN
      FOR v_sale IN
        SELECT id, total, paid_amount, refunded_amount FROM public.sales
        WHERE customer_id = p_customer_id AND branch_id = p_branch_id AND status <> 'returned'
          AND (total - COALESCE(paid_amount, 0) - COALESCE(refunded_amount, 0)) > 0
        ORDER BY created_at ASC
        FOR UPDATE
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_open := round(v_sale.total - COALESCE(v_sale.paid_amount, 0) - COALESCE(v_sale.refunded_amount, 0), 2);
        v_applied := LEAST(v_remaining, v_open);
        UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
        WHERE id = v_sale.id;
        v_remaining := round(v_remaining - v_applied, 2);
      END LOOP;
    END IF;

    -- Post the collection journal entry
    v_payment_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN '1000' ELSE '1010' END;
    v_lines := v_lines || jsonb_build_object('account_code', v_payment_account,
      'debit', round(p_amount, 2), 'credit', 0, 'note', v_number);
    v_lines := v_lines || jsonb_build_object('account_code', '1100',
      'debit', 0, 'credit', round(p_amount, 2), 'customer_id', p_customer_id, 'note', v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'payment', v_payment_id, v_number,
      'Ø³Ù†Ø¯ Ù‚Ø¨Ø¶ ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'payment_id', v_payment_id, 'reference_number', v_number,
      'unapplied', v_remaining);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. Reports
-- ---------------------------------------------------------------------

-- Trial balance: every account with total debit, total credit, net balance



-- ----------------------------------------------------------------------------
-- MIGRATION: 019_d1_foundation.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D1: Foundation - account_mappings + idempotent posting + keys
-- =====================================================================
-- Adds:
--   1. Extended chart seed (WIP, accumulated depreciation, input VAT,
--      purchase discount, stock variance, depreciation & bank charges).
--   2. account_mappings (semantic key -> account per branch) seeded for
--      every branch + auto-seeded on new branches.
--   3. resolve_account_key helper.
--   4. _post_journal_entry rewritten to accept account_key (with
--      account_code fallback) and to be idempotent per (type, reference).
--   5. process_sale / receive_payment / seed_opening_balances rewritten
--      to post via semantic keys instead of hard-coded codes.
--   6. Income statement + balance sheet resolved via account_mappings.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Extended standard chart seed (existing accounts unchanged)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ensure_chart_of_accounts(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.chart_of_accounts (branch_id, code, name, name_en, account_type, is_system)
  SELECT p_branch_id, c.code, c.name, c.name_en, c.account_type, c.is_system
  FROM (VALUES
    ('1000','Ø§Ù„Ù†Ù‚Ø¯ÙŠØ© Ø¨Ø§Ù„Ø®Ø²ÙŠÙ†Ø©','Cash on Hand','asset',true),
    ('1010','Ø§Ù„Ø¨Ù†Ùƒ','Bank','asset',true),
    ('1100','Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡ (Ø°Ù…Ù… Ù…Ø¯ÙŠÙ†Ø©)','Accounts Receivable','asset',true),
    ('1200','Ø§Ù„Ù…Ø®Ø²ÙˆÙ† (Ø¨Ø¶Ø§Ø¹Ø© Ø¬Ø§Ù‡Ø²Ø©)','Finished Goods Inventory','asset',true),
    ('1210','Ù…Ø®Ø²ÙˆÙ† Ø§Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù…','Raw Materials Inventory','asset',false),
    ('1300','Ù…ØµÙ†Ø¹ ØªØ­Øª Ø§Ù„ØªØ´ØºÙŠÙ„','Work In Progress','asset',true),
    ('1500','Ø§Ù„Ø£ØµÙˆÙ„ Ø§Ù„Ø«Ø§Ø¨ØªØ©','Fixed Assets','asset',false),
    ('1520','Ù…Ø¬Ù…Ø¹ Ø¥Ù‡Ù„Ø§Ùƒ Ø§Ù„Ø£ØµÙˆÙ„ Ø§Ù„Ø«Ø§Ø¨ØªØ©','Accumulated Depreciation','asset',true),
    ('2000','Ø§Ù„Ù…ÙˆØ±Ø¯ÙˆÙ† (Ø°Ù…Ù… Ø¯Ø§Ø¦Ù†Ø©)','Accounts Payable','liability',true),
    ('2100','Ø¶Ø±ÙŠØ¨Ø© Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ù…Ø¶Ø§ÙØ© Ø§Ù„Ù…Ø³ØªØ­Ù‚Ø©','VAT Payable','liability',true),
    ('2110','Ø¶Ø±ÙŠØ¨Ø© Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ù…Ø¶Ø§ÙØ© (Ù…Ø´ØªØ±ÙŠØ§Øª)','Input VAT','liability',true),
    ('2300','Ø§Ù„Ù‚Ø±ÙˆØ¶','Loans','liability',false),
    ('3000','Ø±Ø£Ø³ Ø§Ù„Ù…Ø§Ù„','Capital','equity',false),
    ('3100','Ø§Ù„Ø£Ø±Ø¨Ø§Ø­ Ø§Ù„Ù…Ø­ØªØ¬Ø²Ø©','Retained Earnings','equity',false),
    ('4000','Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª','Sales Revenue','income',true),
    ('4100','Ø®ØµÙ… Ù…Ø³Ù…ÙˆØ­ Ø¨Ù‡','Discount Given','income',true),
    ('4110','Ø®ØµÙ… Ù…ÙƒØªØ³Ø¨','Purchase Discount','income',true),
    ('4200','Ø¥ÙŠØ±Ø§Ø¯Ø§Øª Ø£Ø®Ø±Ù‰','Other Income','income',false),
    ('5000','ØªÙƒÙ„ÙØ© Ø§Ù„Ø¨Ø¶Ø§Ø¹Ø© Ø§Ù„Ù…Ø¨Ø§Ø¹Ø©','Cost of Goods Sold','expense',true),
    ('5100','Ù…ØµØ§Ø±ÙŠÙ ØªØ´ØºÙŠÙ„ÙŠØ©','Operating Expenses','expense',false),
    ('5200','Ø£Ø¬ÙˆØ± ÙˆØ±ÙˆØ§ØªØ¨','Salaries & Wages','expense',false),
    ('5300','Ø¥ÙŠØ¬Ø§Ø±','Rent','expense',false),
    ('5400','Ù…Ø±Ø§ÙÙ‚','Utilities','expense',false),
    ('5500','ÙØ±ÙˆÙ‚ Ø¬Ø±Ø¯ Ø§Ù„Ù…Ø®Ø²ÙˆÙ†','Stock Variance','expense',true),
    ('5600','Ù…ØµØ§Ø±ÙŠÙ Ø§Ù„Ø¥Ù‡Ù„Ø§Ùƒ','Depreciation Expense','expense',true),
    ('5700','Ù…ØµØ§Ø±ÙŠÙ Ø§Ù„Ø¨Ù†Ùƒ','Bank Charges','expense',true),
    ('5900','Ù…ØµØ§Ø±ÙŠÙ Ø£Ø®Ø±Ù‰','Other Expenses','expense',false)
  ) AS c(code, name, name_en, account_type, is_system)
  ON CONFLICT (branch_id, code) DO UPDATE SET
    name = EXCLUDED.name,
    name_en = EXCLUDED.name_en,
    account_type = EXCLUDED.account_type,
    is_system = COALESCE(public.chart_of_accounts.is_system, EXCLUDED.is_system),
    updated_at = now();
END;
$function$;

-- Apply the extended chart to every existing branch.
SELECT public.ensure_chart_of_accounts(id) FROM public.branches;

-- ---------------------------------------------------------------------
-- 2. account_mappings: semantic key -> account per branch
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.account_mappings (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  semantic_key  text NOT NULL,
  account_id    uuid NOT NULL REFERENCES public.chart_of_accounts(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, semantic_key)
);
COMMENT ON TABLE public.account_mappings IS 'Ø§Ù„Ø±Ø¨Ø· Ø§Ù„Ø¯Ù„Ø§Ù„ÙŠ Ù„Ù„Ø­Ø³Ø§Ø¨Ø§Øª: Ù…ÙØªØ§Ø­ (Ù†Ù‚Ø¯ÙŠØ©ØŒ Ø¨Ù†ÙƒØŒ Ù…Ø¨ÙŠØ¹Ø§Øª...) Ø¥Ù„Ù‰ Ø­Ø³Ø§Ø¨ Ù„ÙƒÙ„ ÙØ±Ø¹';

CREATE INDEX IF NOT EXISTS idx_account_mappings_branch ON public.account_mappings (branch_id);

ALTER TABLE public.account_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "account_mappings_select" ON public.account_mappings
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
CREATE POLICY "account_mappings_insert" ON public.account_mappings
  FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
CREATE POLICY "account_mappings_update" ON public.account_mappings
  FOR UPDATE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
CREATE POLICY "account_mappings_delete" ON public.account_mappings
  FOR DELETE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));

CREATE TRIGGER trg_account_mappings_updated BEFORE UPDATE ON public.account_mappings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------
-- 3. Seed mappings per branch (guarantees the chart exists first)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.seed_account_mappings(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.ensure_chart_of_accounts(p_branch_id);

  INSERT INTO public.account_mappings (branch_id, semantic_key, account_id)
  SELECT p_branch_id, m.semantic_key, a.id
  FROM (VALUES
    ('cash','1000'),('bank','1010'),('ar','1100'),('ap','2000'),
    ('inventory_fg','1200'),('inventory_rm','1210'),('wip','1300'),
    ('fixed_assets','1500'),('accumulated_depreciation','1520'),
    ('vat_payable','2100'),('vat_receivable','2110'),
    ('capital','3000'),('retained','3100'),
    ('revenue','4000'),('discount_given','4100'),('discount_received','4110'),
    ('other_income','4200'),
    ('cogs','5000'),('expense_default','5100'),('expense_operating','5100'),
    ('stock_variance','5500'),('depreciation_expense','5600'),('bank_charges','5700')
  ) AS m(semantic_key, code)
  JOIN public.chart_of_accounts a ON a.branch_id = p_branch_id AND a.code = m.code
  ON CONFLICT (branch_id, semantic_key) DO UPDATE SET
    account_id = EXCLUDED.account_id,
    updated_at = now();
END;
$function$;

SELECT public.seed_account_mappings(id) FROM public.branches;

-- Auto-seed mappings for future branches (chart trigger fires first by name).
CREATE OR REPLACE FUNCTION public.seed_mappings_for_new_branch()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  PERFORM public.seed_account_mappings(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_seed_mappings_on_branch_insert ON public.branches;
CREATE TRIGGER trg_seed_mappings_on_branch_insert
  AFTER INSERT ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.seed_mappings_for_new_branch();

-- ---------------------------------------------------------------------
-- 4. resolve_account_key: key first, code fallback
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_account_key(
  p_branch_id uuid, p_key text, p_fallback_code text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql STABLE
SET search_path TO 'public'
AS $function$
DECLARE
  v_account uuid;
BEGIN
  IF p_key IS NOT NULL THEN
    SELECT account_id INTO v_account
    FROM public.account_mappings
    WHERE branch_id = p_branch_id AND semantic_key = btrim(p_key);
    IF v_account IS NOT NULL THEN
      RETURN v_account;
    END IF;
  END IF;

  IF p_fallback_code IS NOT NULL THEN
    SELECT id INTO v_account
    FROM public.chart_of_accounts
    WHERE branch_id = p_branch_id AND code = upper(btrim(p_fallback_code));
    IF v_account IS NOT NULL THEN
      RETURN v_account;
    END IF;
  END IF;

  RETURN NULL;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. _post_journal_entry: account_key support + idempotency guard
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._post_journal_entry(
  p_branch_id uuid,
  p_reference_type text,
  p_reference_id uuid,
  p_reference_number text,
  p_description text,
  p_lines jsonb
) RETURNS uuid
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_entry_id uuid;
  v_entry_no text;
  v_line jsonb;
  v_account uuid;
  v_debit numeric(14,2);
  v_credit numeric(14,2);
  v_total_debit numeric(14,2) := 0;
  v_total_credit numeric(14,2) := 0;
BEGIN
  IF p_lines IS NULL OR jsonb_array_length(p_lines) = 0 THEN
    RAISE EXCEPTION 'JOURNAL_EMPTY_LINES';
  END IF;

  -- Idempotency: never post a second entry for the same reference.
  IF p_reference_id IS NOT NULL THEN
    SELECT id INTO v_entry_id
    FROM public.journal_entries
    WHERE reference_type = p_reference_type AND reference_id = p_reference_id;
    IF v_entry_id IS NOT NULL THEN
      RETURN v_entry_id;
    END IF;
  END IF;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::numeric, 0);
    v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::numeric, 0);
  END LOOP;

  IF round(v_total_debit, 2) <> round(v_total_credit, 2) THEN
    RAISE EXCEPTION 'JOURNAL_UNBALANCED: debit % <> credit %',
      round(v_total_debit, 2), round(v_total_credit, 2);
  END IF;

  v_entry_no := (public.next_document_number('journal')->>'number')::text;

  INSERT INTO public.journal_entries
    (entry_number, branch_id, entry_date, reference_type, reference_id, reference_number, description, created_by)
  VALUES (v_entry_no, p_branch_id, CURRENT_DATE, p_reference_type, p_reference_id,
          p_reference_number, p_description, auth.uid())
  RETURNING id INTO v_entry_id;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_debit := COALESCE((v_line->>'debit')::numeric, 0);
    v_credit := COALESCE((v_line->>'credit')::numeric, 0);
    IF v_debit <= 0 AND v_credit <= 0 THEN CONTINUE; END IF;

    IF v_line ? 'account_key' THEN
      v_account := public.resolve_account_key(p_branch_id, v_line->>'account_key', v_line->>'account_code');
    ELSE
      SELECT id INTO v_account
      FROM public.chart_of_accounts
      WHERE branch_id = p_branch_id AND code = upper(btrim((v_line->>'account_code')::text));
    END IF;
    IF v_account IS NULL THEN
      RAISE EXCEPTION 'ACCOUNT_NOT_FOUND: %', COALESCE(v_line->>'account_key', v_line->>'account_code');
    END IF;

    INSERT INTO public.journal_entry_lines
      (journal_entry_id, account_id, debit, credit, customer_id, supplier_id, note)
    VALUES (v_entry_id, v_account, v_debit, v_credit,
            (v_line->>'customer_id')::uuid, (v_line->>'supplier_id')::uuid, v_line->>'note');
  END LOOP;

  RETURN v_entry_id;
END;
$function$;

-- One journal entry per (reference_type, reference_id).
CREATE UNIQUE INDEX IF NOT EXISTS uq_journal_reference
  ON public.journal_entries (reference_type, reference_id)
  WHERE reference_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- 6. process_sale: post via semantic keys
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_sale(p_invoice_number text, p_branch_id uuid, p_warehouse_id uuid, p_customer_id uuid, p_salesperson_id uuid, p_subtotal numeric, p_discount_amount numeric, p_discount_type text, p_tax_amount numeric, p_bonus_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_items jsonb, p_shift_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_warehouse_ids uuid[];
  v_available numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cogs_total numeric(14,2) := 0;
  v_paid numeric(14,2);
  v_ar numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
  v_balance_account text;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      -- Branch ownership: the product must belong to the sale branch
      IF NOT EXISTS (
        SELECT 1 FROM products WHERE id = v_product_id AND branch_id = p_branch_id
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH',
          'product_id', v_product_id, 'branch_id', p_branch_id);
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_available
      FROM inventory_batches
      WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
      IF v_available < v_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
      END IF;
    END LOOP;

    -- ===== WRITE PHASE 1: sale header =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      p_subtotal, p_discount_amount, p_discount_type, p_tax_amount, p_bonus_amount,
      p_total, p_paid_amount, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + FIFO stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_price := COALESCE((v_item->>'unit_price')::numeric, 0);
      v_discount_amount := COALESCE((v_item->>'discount_amount')::numeric, 0);
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := COALESCE((v_item->>'total')::numeric, v_quantity * v_unit_price - v_discount_amount);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      v_res := public._product_inv_remove_fifo(v_product_id, NULL, p_branch_id, v_quantity,
        'sale', 'sale', v_sale_id, p_invoice_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
          v_product_id, v_quantity, (v_quantity - v_short);
      END IF;
      v_cogs_total := v_cogs_total + COALESCE((v_res->>'total_cost')::numeric, 0);
    END LOOP;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', COALESCE(p_paid_amount, 0), p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    -- ===== WRITE PHASE 4: post the sales + COGS journal entry =====
    v_paid := round(COALESCE(p_paid_amount, 0), 2);
    v_ar := round(GREATEST(COALESCE(p_total, 0) - v_paid, 0), 2);

    IF v_paid > 0 THEN
      v_balance_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END;
      v_lines := v_lines || jsonb_build_object('account_key', v_balance_account,
        'debit', v_paid, 'credit', 0, 'note', p_invoice_number);
      v_dr := v_dr + v_paid;
    END IF;
    IF v_ar > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'ar',
        'debit', v_ar, 'credit', 0, 'customer_id', p_customer_id, 'note', p_invoice_number);
      v_dr := v_dr + v_ar;
    END IF;
    IF COALESCE(p_discount_amount, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', p_discount_amount, 'credit', 0);
      v_dr := v_dr + p_discount_amount;
    END IF;
    IF COALESCE(p_subtotal, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'revenue', 'debit', 0, 'credit', p_subtotal);
      v_cr := v_cr + p_subtotal;
    END IF;
    IF COALESCE(p_tax_amount, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'vat_payable', 'debit', 0, 'credit', p_tax_amount);
      v_cr := v_cr + p_tax_amount;
    END IF;
    IF v_cogs_total > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'cogs', 'debit', v_cogs_total, 'credit', 0);
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', 0, 'credit', v_cogs_total);
      v_dr := v_dr + v_cogs_total;
      v_cr := v_cr + v_cogs_total;
    END IF;

    -- Balance any rounding/frontend discrepancy on the discount account so a
    -- posted entry is always balanced (normally the difference is zero).
    v_diff := round(v_dr - v_cr, 2);
    IF v_diff <> 0 THEN
      IF v_diff > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', 0, 'credit', v_diff);
      ELSE
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', -v_diff, 'credit', 0);
      END IF;
    END IF;

    PERFORM public._post_journal_entry(p_branch_id, 'sale', v_sale_id, p_invoice_number,
      'ÙØ§ØªÙˆØ±Ø© Ù…Ø¨ÙŠØ¹Ø§Øª ' || p_invoice_number, v_lines);

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number,
      'cogs', v_cogs_total);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 7. seed_opening_balances: post via semantic keys
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.seed_opening_balances(p_branch_id uuid)
RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_finished numeric(14,2);
  v_raw numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_total numeric(14,2) := 0;
BEGIN
  BEGIN
    IF NOT is_pos_admin() THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE branch_id = p_branch_id AND reference_type = 'opening'
    ) THEN
      RETURN jsonb_build_object('success', false, 'error', 'OPENING_ALREADY_EXISTS');
    END IF;

    SELECT COALESCE(SUM(b.quantity * b.unit_cost), 0) INTO v_finished
    FROM public.inventory_batches b WHERE b.branch_id = p_branch_id;

    SELECT COALESCE(SUM(b.quantity * b.unit_cost), 0) INTO v_raw
    FROM public.raw_material_batches b WHERE b.branch_id = p_branch_id;

    v_total := round(v_finished + v_raw, 2);
    IF v_total <= 0 THEN
      RETURN jsonb_build_object('success', true, 'skipped', true, 'total', 0);
    END IF;

    IF v_finished > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', round(v_finished, 2), 'credit', 0, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…Ø®Ø²ÙˆÙ†');
    END IF;
    IF v_raw > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', round(v_raw, 2), 'credit', 0, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…ÙˆØ§Ø¯ Ø§Ù„Ø®Ø§Ù…');
    END IF;
    v_lines := v_lines || jsonb_build_object('account_key', 'capital', 'debit', 0, 'credit', v_total, 'note', 'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ');

    PERFORM public._post_journal_entry(p_branch_id, 'opening', NULL, 'OPENING',
      'Ø±ØµÙŠØ¯ Ø§ÙØªØªØ§Ø­ÙŠ Ù„Ù„Ù…Ø®Ø²ÙˆÙ†', v_lines);

    RETURN jsonb_build_object('success', true, 'total', v_total, 'finished', v_finished, 'raw', v_raw);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 8. receive_payment: post via semantic keys
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.receive_payment(
  p_customer_id uuid, p_branch_id uuid, p_amount numeric,
  p_payment_method text DEFAULT 'cash', p_sale_id uuid DEFAULT NULL, p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_payment_id uuid;
  v_number text;
  v_user_branch uuid;
  v_remaining numeric(14,2);
  v_sale record;
  v_applied numeric(14,2);
  v_open numeric(14,2);
  v_total_open numeric(14,2);
  v_payment_account text;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager', 'cashier') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE id = p_customer_id AND branch_id = p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'CUSTOMER_NOT_FOUND');
    END IF;

    -- Payments must be backed by open receivable (no free-floating credits).
    SELECT COALESCE(SUM(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)), 0)
    INTO v_total_open
    FROM public.sales s
    WHERE s.customer_id = p_customer_id AND s.branch_id = p_branch_id AND s.status <> 'returned';

    IF p_sale_id IS NULL THEN
      IF round(p_amount, 2) > round(v_total_open, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_AR',
          'open', round(v_total_open, 2), 'detail', 'The payment exceeds the customer open balance.');
      END IF;
    ELSE
      SELECT total, COALESCE(paid_amount, 0), COALESCE(refunded_amount, 0) INTO v_sale
      FROM public.sales WHERE id = p_sale_id AND customer_id = p_customer_id AND branch_id = p_branch_id
        AND status <> 'returned' FOR UPDATE;
      IF v_sale.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'SALE_NOT_FOUND',
          'detail', 'No open invoice found for this customer with that id.');
      END IF;
      IF round(p_amount, 2) > round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_INVOICE',
          'open', round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2));
      END IF;
    END IF;

    v_number := (public.next_document_number('payment')->>'number')::text;

    INSERT INTO public.customer_payments (customer_id, branch_id, amount, payment_method, sale_id, reference_number, notes, created_by)
    VALUES (p_customer_id, p_branch_id, p_amount, p_payment_method, p_sale_id, v_number, p_notes, auth.uid())
    RETURNING id INTO v_payment_id;

    -- Apply payment against invoices (specific or oldest open first)
    v_remaining := round(p_amount, 2);

    IF p_sale_id IS NOT NULL THEN
      v_open := round(v_sale.total - v_sale.paid_amount - v_sale.refunded_amount, 2);
      v_applied := LEAST(v_remaining, v_open);
      UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
      WHERE id = p_sale_id;
      v_remaining := round(v_remaining - v_applied, 2);
    ELSIF v_remaining > 0 THEN
      FOR v_sale IN
        SELECT id, total, paid_amount, refunded_amount FROM public.sales
        WHERE customer_id = p_customer_id AND branch_id = p_branch_id AND status <> 'returned'
          AND (total - COALESCE(paid_amount, 0) - COALESCE(refunded_amount, 0)) > 0
        ORDER BY created_at ASC
        FOR UPDATE
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_open := round(v_sale.total - COALESCE(v_sale.paid_amount, 0) - COALESCE(v_sale.refunded_amount, 0), 2);
        v_applied := LEAST(v_remaining, v_open);
        UPDATE public.sales SET paid_amount = COALESCE(paid_amount, 0) + v_applied
        WHERE id = v_sale.id;
        v_remaining := round(v_remaining - v_applied, 2);
      END LOOP;
    END IF;

    -- Post the collection journal entry
    v_payment_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END;
    v_lines := v_lines || jsonb_build_object('account_key', v_payment_account,
      'debit', round(p_amount, 2), 'credit', 0, 'note', v_number);
    v_lines := v_lines || jsonb_build_object('account_key', 'ar',
      'debit', 0, 'credit', round(p_amount, 2), 'customer_id', p_customer_id, 'note', v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'payment', v_payment_id, v_number,
      'Ø³Ù†Ø¯ Ù‚Ø¨Ø¶ ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'payment_id', v_payment_id, 'reference_number', v_number,
      'unapplied', v_remaining);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 9. Income statement + balance sheet resolved via account_mappings
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_income_statement(
  p_branch_id uuid, p_from_date date, p_to_date date DEFAULT CURRENT_DATE
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH cfg AS (
  SELECT
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'revenue')        AS revenue_id,
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'other_income')   AS other_income_id,
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'discount_given') AS discount_id,
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'cogs')           AS cogs_id
), agg AS (
  SELECT a.account_type, a.id AS account_id,
         COALESCE(SUM(l.debit), 0) AS debit,
         COALESCE(SUM(l.credit), 0) AS credit
  FROM public.journal_entry_lines l
  JOIN public.journal_entries j ON j.id = l.journal_entry_id
  JOIN public.chart_of_accounts a ON a.id = l.account_id
  WHERE j.branch_id = p_branch_id
    AND j.entry_date >= p_from_date AND j.entry_date <= p_to_date
  GROUP BY a.account_type, a.id
)
SELECT jsonb_build_object(
  'revenue',      round(COALESCE((SELECT SUM(credit - debit) FROM agg, cfg WHERE account_id IN (cfg.revenue_id, cfg.other_income_id)), 0), 2),
  'discount',     round(COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.discount_id), 0), 2),
  'net_revenue',  round(
                    COALESCE((SELECT SUM(credit - debit) FROM agg, cfg WHERE account_id IN (cfg.revenue_id, cfg.other_income_id)), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.discount_id), 0), 2),
  'cogs',         round(COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.cogs_id), 0), 2),
  'gross_profit', round(
                    COALESCE((SELECT SUM(credit - debit) FROM agg, cfg WHERE account_id IN (cfg.revenue_id, cfg.other_income_id)), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.discount_id), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.cogs_id), 0), 2),
  'expenses',     round(COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_type = 'expense' AND account_id <> COALESCE(cfg.cogs_id, '00000000-0000-0000-0000-000000000000')), 0), 2),
  'net_income',   round(
                    COALESCE((SELECT SUM(credit - debit) FROM agg, cfg WHERE account_id IN (cfg.revenue_id, cfg.other_income_id)), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.discount_id), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_id = cfg.cogs_id), 0)
                    - COALESCE((SELECT SUM(debit - credit) FROM agg, cfg WHERE account_type = 'expense' AND account_id <> COALESCE(cfg.cogs_id, '00000000-0000-0000-0000-000000000000')), 0), 2)
)
FROM cfg;
$function$;

CREATE OR REPLACE FUNCTION public.get_balance_sheet(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH cfg AS (
  SELECT
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'capital')  AS capital_id,
    (SELECT account_id FROM public.account_mappings WHERE branch_id = p_branch_id AND semantic_key = 'retained') AS retained_id
), bal AS (
  SELECT a.account_type, a.id AS account_id,
         COALESCE(SUM(l.debit), 0) AS debit,
         COALESCE(SUM(l.credit), 0) AS credit
  FROM public.chart_of_accounts a
  LEFT JOIN public.journal_entry_lines l ON l.account_id = a.id
  LEFT JOIN public.journal_entries j ON j.id = l.journal_entry_id
    AND j.branch_id = p_branch_id AND j.entry_date <= p_as_of
  WHERE a.branch_id = p_branch_id AND a.is_active
  GROUP BY a.account_type, a.id
), summary AS (
  SELECT
    round(COALESCE((SELECT SUM(debit - credit) FROM bal, cfg WHERE account_type = 'asset'), 0), 2) AS assets,
    round(COALESCE((SELECT SUM(credit - debit) FROM bal, cfg WHERE account_type = 'liability'), 0), 2) AS liabilities,
    round(COALESCE((SELECT SUM(credit - debit) FROM bal, cfg WHERE account_id = cfg.capital_id), 0), 2) AS capital,
    round(COALESCE((SELECT SUM(credit - debit) FROM bal, cfg WHERE account_id = cfg.retained_id), 0), 2) AS retained,
    round(COALESCE((SELECT SUM(credit - debit) FROM bal, cfg WHERE account_type = 'income'), 0)
         - COALESCE((SELECT SUM(debit - credit) FROM bal, cfg WHERE account_type = 'expense'), 0), 2) AS net_income
  FROM cfg
)
SELECT jsonb_build_object(
  'assets', assets,
  'liabilities', liabilities,
  'capital', capital,
  'retained', retained,
  'net_income', net_income,
  'equity', round(capital + retained + net_income, 2),
  'balanced', round(assets - (liabilities + capital + retained + net_income), 2) = 0
)
FROM summary;
$function$;

-- ---------------------------------------------------------------------
-- Reload the PostgREST schema cache.
-- ---------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 020_d2_rpc.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D2: Complete the ledger - post purchases, refunds, expenses,
--           production (WIP) and stock variances
-- =====================================================================
-- Rewrites the live RPCs (keeping their stock logic verbatim) and adds
-- journal posting via semantic keys:
--   1. process_purchase      -> inventory_fg/inventory_rm + input VAT +
--                               discount received + cash/bank + AP
--   2. process_refund        -> prorated reversal of the sale entry
--   3. process_expense (new) -> expense account + input VAT + cash/bank
--   4. complete_production_order -> WIP consumption + finished goods
--   5. adjust_stock / adjust_raw_stock -> inventory vs stock variance
-- All posting is skipped for non-completed documents and idempotent per
-- reference; expenses/postings never weaken existing RLS.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. expenses: account linkage + tax columns (kept nullable so existing
--    pages/rows keep working; posting happens through process_expense)
-- ---------------------------------------------------------------------
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS account_id uuid REFERENCES public.chart_of_accounts(id),
  ADD COLUMN IF NOT EXISTS tax_amount numeric(14,2) NOT NULL DEFAULT 0;

-- ---------------------------------------------------------------------
-- 1. process_purchase: keep stock logic, add full posting
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_purchase(p_invoice_number text, p_supplier_id uuid, p_branch_id uuid, p_warehouse_id uuid, p_subtotal numeric, p_discount_amount numeric, p_tax_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_notes text, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_purchase_id uuid;
  v_user_branch uuid;
  v_item jsonb;
  v_product_id uuid;
  v_raw_id uuid;
  v_quantity numeric(14,4);
  v_unit_cost numeric(12,2);
  v_res jsonb;
  v_unit_name text;
  v_stock numeric(14,4);
  v_stock_val numeric(14,2);
  v_new_cost numeric(12,2);
  v_goods_fg numeric(14,2) := 0;
  v_goods_rm numeric(14,2) := 0;
  v_paid numeric(14,2);
  v_ap numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    -- Only admins, branch managers and warehouse managers create purchases
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Creating purchases requires the purchases.manage permission.');
    END IF;

    -- Branch isolation (mirror of RLS on purchases)
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Validate items before writing
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_raw_id := (v_item->>'raw_material_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF (v_product_id IS NULL) = (v_raw_id IS NULL) THEN
        RETURN jsonb_build_object('success', false, 'error', 'ITEM_MISSING_TYPE');
      END IF;
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY');
      END IF;
      IF v_product_id IS NOT NULL AND p_warehouse_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_REQUIRED',
          'detail', 'Select a warehouse to receive product items.');
      END IF;
    END LOOP;

    INSERT INTO purchases (invoice_number, supplier_id, branch_id, warehouse_id, buyer_id,
      subtotal, discount_amount, tax_amount, total, paid_amount, payment_method, status, notes)
    VALUES (p_invoice_number, p_supplier_id, p_branch_id, p_warehouse_id, auth.uid(),
      p_subtotal, p_discount_amount, p_tax_amount, p_total, p_paid_amount, p_payment_method, p_status, p_notes)
    RETURNING id INTO v_purchase_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_raw_id := (v_item->>'raw_material_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_unit_cost := COALESCE((v_item->>'unit_cost')::numeric, 0);

      IF v_product_id IS NOT NULL THEN
        INSERT INTO purchase_items (purchase_id, product_id, unit_name, quantity, unit_cost, total)
        VALUES (v_purchase_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
          v_quantity, v_unit_cost, v_quantity * v_unit_cost);

        v_res := public._product_inv_add(v_product_id, p_warehouse_id, p_branch_id, v_quantity,
          v_unit_cost, v_item->>'batch_number',
          (v_item->>'production_date')::date, (v_item->>'expiry_date')::date,
          'purchase', 'purchase', v_purchase_id, p_invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;

        -- Weighted-average cost on the product master
        SELECT COALESCE(SUM(b.quantity), 0), COALESCE(SUM(b.quantity * b.unit_cost), 0)
        INTO v_stock, v_stock_val
        FROM public.inventory_batches b WHERE b.product_id = v_product_id;
        v_new_cost := CASE WHEN v_stock > 0 THEN round(v_stock_val / v_stock, 2) ELSE v_unit_cost END;
        UPDATE public.products SET cost_price = v_new_cost, updated_at = now() WHERE id = v_product_id;

        v_goods_fg := round(v_goods_fg + v_quantity * v_unit_cost, 2);
      ELSE
        SELECT COALESCE(u.symbol, u.name, 'ÙˆØ­Ø¯Ø©') INTO v_unit_name
        FROM public.raw_materials rm LEFT JOIN public.units u ON u.id = rm.unit_id
        WHERE rm.id = v_raw_id;

        INSERT INTO purchase_items (purchase_id, raw_material_id, unit_name, quantity, unit_cost, total)
        VALUES (v_purchase_id, v_raw_id, COALESCE(NULLIF(v_item->>'unit_name', ''), v_unit_name),
          v_quantity, v_unit_cost, v_quantity * v_unit_cost);

        v_res := public._raw_add(v_raw_id, p_branch_id, v_quantity, v_unit_cost,
          v_item->>'batch_number', (v_item->>'production_date')::date, (v_item->>'expiry_date')::date,
          'purchase', 'purchase', v_purchase_id, p_invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;

        v_goods_rm := round(v_goods_rm + v_quantity * v_unit_cost, 2);
      END IF;
    END LOOP;

    -- ===== LEDGER POSTING (completed purchases only) =====
    IF COALESCE(p_status, 'completed') = 'completed' THEN
      v_paid := round(COALESCE(p_paid_amount, 0), 2);
      v_ap := round(COALESCE(p_total, 0) - v_paid, 2);

      IF v_goods_fg > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', v_goods_fg, 'credit', 0, 'note', p_invoice_number);
        v_dr := v_dr + v_goods_fg;
      END IF;
      IF v_goods_rm > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', v_goods_rm, 'credit', 0, 'note', p_invoice_number);
        v_dr := v_dr + v_goods_rm;
      END IF;
      IF COALESCE(p_tax_amount, 0) > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'vat_receivable', 'debit', p_tax_amount, 'credit', 0);
        v_dr := v_dr + p_tax_amount;
      END IF;
      IF COALESCE(p_discount_amount, 0) > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', 0, 'credit', p_discount_amount);
        v_cr := v_cr + p_discount_amount;
      END IF;
      IF v_paid > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END,
          'debit', 0, 'credit', v_paid, 'note', p_invoice_number);
        v_cr := v_cr + v_paid;
      END IF;
      IF v_ap > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'ap', 'debit', 0, 'credit', v_ap,
          'supplier_id', p_supplier_id, 'note', p_invoice_number);
        v_cr := v_cr + v_ap;
      END IF;

      v_diff := round(v_dr - v_cr, 2);
      IF v_diff <> 0 THEN
        IF v_diff > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', 0, 'credit', v_diff);
        ELSE
          v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', -v_diff, 'credit', 0);
        END IF;
      END IF;

      PERFORM public._post_journal_entry(p_branch_id, 'purchase', v_purchase_id, p_invoice_number,
        'ÙØ§ØªÙˆØ±Ø© Ø´Ø±Ø§Ø¡ ' || p_invoice_number, v_lines);
    END IF;

    RETURN jsonb_build_object('success', true, 'purchase_id', v_purchase_id, 'invoice_number', p_invoice_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 2. process_refund: keep restock logic, add prorated reversal posting
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_refund(p_sale_id uuid, p_items jsonb DEFAULT NULL::jsonb, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale record;
  v_user_branch uuid;
  v_shift_id uuid;
  v_refund_total numeric(14,2) := 0;
  v_item record;
  v_req jsonb;
  v_item_id uuid;
  v_req_qty numeric(14,4);
  v_already numeric(14,4);
  v_ref_qty numeric(14,4);
  v_item_line_total numeric(14,2);
  v_item_ref_amt numeric(14,2);
  v_all_refunded boolean := true;
  v_remaining numeric(14,4);
  v_back numeric(14,4);
  v_ld record;
  v_res jsonb;
  v_fallback_wh uuid;
  v_last_cost numeric(12,2);
  v_sale_entry uuid;
  v_revenue numeric(14,2);
  v_discount numeric(14,2);
  v_vat numeric(14,2);
  v_cogs numeric(14,2);
  v_ratio numeric(14,6);
  v_revenue_r numeric(14,2);
  v_discount_r numeric(14,2);
  v_vat_r numeric(14,2);
  v_cogs_r numeric(14,2);
  v_cash_r numeric(14,2);
  v_ar_r numeric(14,2);
  v_paid_code text;
  v_credit_key text;
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
BEGIN
  BEGIN
    IF p_sale_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_SALE');
    END IF;

    SELECT id, branch_id, warehouse_id, status, total, paid_amount, customer_id, invoice_number
      INTO v_sale FROM public.sales WHERE id = p_sale_id;
    IF v_sale.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'SALE_NOT_FOUND');
    END IF;

    IF v_sale.status = 'returned' THEN
      RETURN jsonb_build_object('success', false, 'error', 'ALREADY_RETURNED');
    END IF;

    -- Permission: refunds.approve (admins always pass)
    IF NOT is_pos_admin() AND NOT can_permission('refunds.approve') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'You need the refunds.approve permission.');
    END IF;

    -- Branch isolation
    SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND v_user_branch IS NOT NULL
       AND v_sale.branch_id IS NOT NULL AND v_user_branch <> v_sale.branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    -- Active shift of the refunding operator (for the drawer log, optional)
    SELECT id INTO v_shift_id FROM shifts
      WHERE cashier_id = auth.uid() AND branch_id = v_sale.branch_id AND status = 'open'
      ORDER BY opened_at DESC LIMIT 1;

    SELECT id INTO v_fallback_wh FROM warehouses
      WHERE branch_id = v_sale.branch_id AND is_active = true ORDER BY created_at LIMIT 1;

    -- ===== VALIDATION PHASE =====
    IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
      FOR v_req IN SELECT * FROM jsonb_array_elements(p_items)
      LOOP
        v_item_id := (v_req->>'sale_item_id')::uuid;
        v_req_qty := COALESCE((v_req->>'quantity')::numeric, 0);
        IF v_req_qty <= 0 THEN
          RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'sale_item_id', v_item_id);
        END IF;
        SELECT id, quantity, refunded_quantity INTO v_item
          FROM sale_items WHERE id = v_item_id AND sale_id = p_sale_id;
        IF v_item.id IS NULL THEN
          RETURN jsonb_build_object('success', false, 'error', 'ITEM_NOT_FOUND', 'sale_item_id', v_item_id);
        END IF;
        v_already := COALESCE(v_item.refunded_quantity, 0);
        IF v_req_qty > v_item.quantity - v_already THEN
          RETURN jsonb_build_object('success', false, 'error', 'REFUND_EXCEEDS_QUANTITY',
            'sale_item_id', v_item_id, 'max', v_item.quantity - v_already);
        END IF;
      END LOOP;
    END IF;

    -- ===== REFUND + RESTOCK PHASE =====
    FOR v_item IN SELECT id, product_id, quantity, unit_price, discount_amount, refunded_quantity
                  FROM sale_items WHERE sale_id = p_sale_id
    LOOP
      IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
        v_req_qty := 0;
        SELECT (req->>'quantity')::numeric INTO v_req_qty
        FROM jsonb_array_elements(p_items) req
        WHERE (req->>'sale_item_id')::uuid = v_item.id;
        v_req_qty := COALESCE(v_req_qty, 0);
      ELSE
        v_req_qty := v_item.quantity - COALESCE(v_item.refunded_quantity, 0);
      END IF;
      IF v_req_qty <= 0 THEN CONTINUE; END IF;

      v_item_line_total := v_item.quantity * v_item.unit_price - v_item.discount_amount;
      IF v_item.quantity > 0 THEN
        v_item_ref_amt := ROUND(v_item_line_total * v_req_qty / v_item.quantity, 2);
      ELSE
        v_item_ref_amt := 0;
      END IF;
      v_refund_total := v_refund_total + v_item_ref_amt;

      UPDATE sale_items
        SET refunded_quantity = COALESCE(refunded_quantity, 0) + v_req_qty,
            refunded_amount = COALESCE(refunded_amount, 0) + v_item_ref_amt
        WHERE id = v_item.id;

      -- Restore stock to the warehouses the sale deducted from (FIFO restore as new batch)
      v_remaining := v_req_qty;
      SELECT COALESCE(l.unit_cost, p.cost_price, 0) INTO v_last_cost
      FROM products p LEFT JOIN inventory_ledger l
        ON l.product_id = p.id AND l.quantity < 0 AND l.reference_type = 'sale'
           AND l.reference_id = p_sale_id
      WHERE p.id = v_item.product_id
      ORDER BY l.id DESC NULLS LAST LIMIT 1;

      FOR v_ld IN
        SELECT l.warehouse_id, l.batch_number, l.unit_cost, -l.quantity AS debited
        FROM inventory_ledger l
        WHERE l.product_id = v_item.product_id AND l.reference_type = 'sale'
          AND l.reference_id = p_sale_id AND l.quantity < 0
        ORDER BY l.id ASC
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_back := LEAST(COALESCE(v_ld.debited, 0), v_remaining);
        IF v_back <= 0 OR v_ld.warehouse_id IS NULL THEN CONTINUE; END IF;
        v_res := public._product_inv_add(v_item.product_id, v_ld.warehouse_id, v_sale.branch_id, v_back,
          COALESCE(v_ld.unit_cost, v_last_cost),
          'R-' || COALESCE(v_ld.batch_number, 'RETURN'), NULL, NULL,
          'refund', 'refund', p_sale_id, NULL, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
        v_remaining := v_remaining - v_back;
      END LOOP;

      IF v_remaining > 0 AND v_fallback_wh IS NOT NULL THEN
        v_res := public._product_inv_add(v_item.product_id, v_fallback_wh, v_sale.branch_id, v_remaining,
          v_last_cost, 'R-RETURN', NULL, NULL, 'refund', 'refund', p_sale_id, NULL, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
      END IF;
    END LOOP;

    -- Update header: full refund flips the status, otherwise accumulate refunded_amount
    SELECT bool_and(quantity = refunded_quantity) INTO v_all_refunded
      FROM sale_items WHERE sale_id = p_sale_id;
    UPDATE sales SET
      refunded_amount = COALESCE(refunded_amount, 0) + v_refund_total,
      status = CASE WHEN v_all_refunded THEN 'returned' ELSE status END,
      notes = CASE WHEN p_reason IS NOT NULL THEN COALESCE(notes, '') || E'\n' || p_reason ELSE notes END
      WHERE id = p_sale_id;

    -- Log the cash-out into the active shift
    IF v_shift_id IS NOT NULL AND v_refund_total > 0 THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'refund', v_refund_total, 'cash', 'refund', p_sale_id, auth.uid());
    END IF;

    -- ===== LEDGER POSTING: prorated reversal of the original sale =====
    IF v_refund_total > 0 THEN
      SELECT id INTO v_sale_entry
      FROM public.journal_entries
      WHERE branch_id = v_sale.branch_id AND reference_type = 'sale' AND reference_id = p_sale_id;

      IF v_sale_entry IS NOT NULL THEN
        SELECT
          round(COALESCE(SUM(CASE WHEN a.id IN (m.revenue_id, m.other_income_id) THEN l.credit - l.debit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.discount_id THEN l.debit - l.credit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.vat_id THEN l.credit - l.debit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.cogs_id THEN l.debit - l.credit ELSE 0 END), 0), 2)
        INTO v_revenue, v_discount, v_vat, v_cogs
        FROM public.journal_entry_lines l
        JOIN public.chart_of_accounts a ON a.id = l.account_id
        CROSS JOIN (
          SELECT
            (SELECT public.resolve_account_key(v_sale.branch_id, 'revenue')) AS revenue_id,
            (SELECT public.resolve_account_key(v_sale.branch_id, 'other_income')) AS other_income_id,
            (SELECT public.resolve_account_key(v_sale.branch_id, 'discount_given')) AS discount_id,
            (SELECT public.resolve_account_key(v_sale.branch_id, 'vat_payable')) AS vat_id,
            (SELECT public.resolve_account_key(v_sale.branch_id, 'cogs')) AS cogs_id
        ) m
        WHERE l.journal_entry_id = v_sale_entry;

        v_ratio := round(v_refund_total / GREATEST(COALESCE(v_sale.total, 0), 1), 6);
        v_revenue_r := round(v_revenue * v_ratio, 2);
        v_discount_r := round(v_discount * v_ratio, 2);
        v_vat_r := round(v_vat * v_ratio, 2);
        v_cogs_r := round(v_cogs * v_ratio, 2);

        -- Credit the account the original collection used (cash/bank/AR)
        SELECT a.code INTO v_paid_code
        FROM public.journal_entry_lines l
        JOIN public.chart_of_accounts a ON a.id = l.account_id
        WHERE l.journal_entry_id = v_sale_entry AND l.debit > 0
          AND a.code IN ('1000', '1010', '1100')
        ORDER BY CASE a.code WHEN '1000' THEN 1 WHEN '1010' THEN 2 ELSE 3 END
        LIMIT 1;

        IF v_paid_code = '1100' THEN
          v_credit_key := 'ar';
          v_ar_r := round(v_refund_total, 2);
          v_cash_r := 0;
        ELSE
          v_credit_key := CASE WHEN v_paid_code = '1010' THEN 'bank' ELSE 'cash' END;
          v_cash_r := round(LEAST(v_refund_total, COALESCE(v_sale.paid_amount, 0)), 2);
          v_ar_r := round(v_refund_total - v_cash_r, 2);
        END IF;

        IF v_revenue_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'revenue', 'debit', v_revenue_r, 'credit', 0);
          v_dr := v_dr + v_revenue_r;
        END IF;
        IF v_discount_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', 0, 'credit', v_discount_r);
          v_cr := v_cr + v_discount_r;
        END IF;
        IF v_vat_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'vat_payable', 'debit', v_vat_r, 'credit', 0);
          v_dr := v_dr + v_vat_r;
        END IF;
        IF v_cogs_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', v_cogs_r, 'credit', 0);
          v_lines := v_lines || jsonb_build_object('account_key', 'cogs', 'debit', 0, 'credit', v_cogs_r);
          v_dr := v_dr + v_cogs_r;
          v_cr := v_cr + v_cogs_r;
        END IF;
        IF v_cash_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', v_credit_key, 'debit', 0, 'credit', v_cash_r, 'note', 'Ù…Ø±ØªØ¬Ø¹ ' || v_sale.invoice_number);
          v_cr := v_cr + v_cash_r;
        END IF;
        IF v_ar_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'ar', 'debit', 0, 'credit', v_ar_r,
            'customer_id', v_sale.customer_id, 'note', 'Ù…Ø±ØªØ¬Ø¹ ' || v_sale.invoice_number);
          v_cr := v_cr + v_ar_r;
        END IF;

        v_diff := round(v_dr - v_cr, 2);
        IF v_diff <> 0 THEN
          IF v_diff > 0 THEN
            v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', 0, 'credit', v_diff);
          ELSE
            v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', -v_diff, 'credit', 0);
          END IF;
        END IF;

        PERFORM public._post_journal_entry(v_sale.branch_id, 'refund', NULL, v_sale.invoice_number,
          'Ù…Ø±ØªØ¬Ø¹ ÙØ§ØªÙˆØ±Ø© ' || v_sale.invoice_number, v_lines);
      END IF;
    END IF;

    RETURN jsonb_build_object('success', true, 'sale_id', p_sale_id,
      'refunded_amount', v_refund_total, 'fully_refunded', v_all_refunded);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 3. process_expense: post an expense with optional VAT
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_expense(
  p_branch_id uuid,
  p_category text,
  p_description text,
  p_amount numeric,
  p_tax_amount numeric DEFAULT 0,
  p_payment_method text DEFAULT 'cash',
  p_account_id uuid DEFAULT NULL,
  p_expense_date date DEFAULT CURRENT_DATE,
  p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_expense_id uuid;
  v_user_branch uuid;
  v_account uuid;
  v_total numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    IF NOT is_pos_admin() AND NOT can_permission('expenses.manage')
       AND get_user_role() NOT IN ('branch_manager', 'accountant') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Creating expenses requires the expenses.manage permission.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Resolve the expense account (explicit, or the default mapping)
    IF p_account_id IS NOT NULL THEN
      SELECT id INTO v_account
      FROM public.chart_of_accounts
      WHERE id = p_account_id AND branch_id = p_branch_id AND is_active;
      IF v_account IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'ACCOUNT_NOT_FOUND', 'detail', 'Expense account not found in this branch.');
      END IF;
    ELSE
      v_account := public.resolve_account_key(p_branch_id, 'expense_default');
      IF v_account IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'ACCOUNT_NOT_FOUND', 'detail', 'No default expense account mapped.');
      END IF;
    END IF;

    INSERT INTO public.expenses (category, description, amount, tax_amount, branch_id, payment_method,
      expense_date, notes, created_by, account_id)
    VALUES (p_category, p_description, p_amount, COALESCE(p_tax_amount, 0), p_branch_id,
      p_payment_method, p_expense_date, p_notes, auth.uid(), v_account)
    RETURNING id INTO v_expense_id;

    v_total := round(p_amount + COALESCE(p_tax_amount, 0), 2);

    v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_account),
      'debit', round(p_amount, 2), 'credit', 0, 'note', COALESCE(p_description, p_category));
    v_dr := v_dr + round(p_amount, 2);
    IF COALESCE(p_tax_amount, 0) > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'vat_receivable', 'debit', p_tax_amount, 'credit', 0);
      v_dr := v_dr + p_tax_amount;
    END IF;
    IF v_total > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END,
        'debit', 0, 'credit', v_total, 'note', COALESCE(p_description, p_category));
      v_cr := v_cr + v_total;
    END IF;

    v_diff := round(v_dr - v_cr, 2);
    IF v_diff <> 0 THEN
      IF v_diff > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_account), 'debit', 0, 'credit', v_diff);
      ELSE
        v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_account), 'debit', -v_diff, 'credit', 0);
      END IF;
    END IF;

    PERFORM public._post_journal_entry(p_branch_id, 'expense', v_expense_id, NULL,
      'Ù…ØµØ±ÙˆÙ ' || COALESCE(p_category, 'Ù…ØµØ±ÙˆÙØ§Øª'), v_lines);

    RETURN jsonb_build_object('success', true, 'expense_id', v_expense_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. complete_production_order: keep stock logic, add WIP posting
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_production_order(p_order_id uuid, p_waste jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_order record;
  v_recipe_id uuid;
  v_recipe_yield numeric(14,4);
  v_factor numeric(14,4);
  v_item record;
  v_waste_item jsonb;
  v_req numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cost numeric(14,2) := 0;
  v_unit_cost numeric(12,2) := 0;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND NOT can_permission('production.manage') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED');
    END IF;

    SELECT * INTO v_order FROM public.production_orders WHERE id = p_order_id FOR UPDATE;
    IF v_order.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;
    IF v_order.status NOT IN ('planned', 'in_progress') THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS', 'status', v_order.status);
    END IF;
    IF v_order.warehouse_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'WAREHOUSE_REQUIRED',
        'detail', 'Assign an output warehouse to the production order before completing it.');
    END IF;

    SELECT id, yield_quantity INTO v_recipe_id, v_recipe_yield
    FROM public.recipes
    WHERE product_id = v_order.product_id AND branch_id = v_order.branch_id AND is_active
    ORDER BY updated_at DESC LIMIT 1;
    IF v_recipe_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'NO_RECIPE', 'product_id', v_order.product_id);
    END IF;

    v_recipe_yield := COALESCE(v_recipe_yield, 1);
    v_factor := v_order.quantity / v_recipe_yield;

    -- Consume raw materials (FIFO by nearest expiry)
    FOR v_item IN SELECT * FROM public.recipe_items WHERE recipe_id = v_recipe_id
    LOOP
      v_req := COALESCE(v_item.quantity, 0) * v_factor;
      IF v_req <= 0 THEN CONTINUE; END IF;

      v_res := public._raw_remove_fifo(v_item.raw_material_id, v_order.branch_id, v_req,
        'production', 'production_order', v_order.id, v_order.order_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_RAW',
          'raw_material_id', v_item.raw_material_id, 'required', v_req,
          'available', v_req - v_short,
          'detail', 'Not enough raw material to complete production. The order was not completed.');
      END IF;
      v_cost := v_cost + (v_res->>'total_cost')::numeric;
    END LOOP;

    -- Record waste (extra raw material consumed beyond the recipe)
    IF p_waste IS NOT NULL AND jsonb_array_length(p_waste) > 0 THEN
      FOR v_waste_item IN SELECT * FROM jsonb_array_elements(p_waste)
      LOOP
        v_req := COALESCE((v_waste_item->>'quantity')::numeric, 0);
        IF v_req <= 0 THEN CONTINUE; END IF;
        v_res := public._raw_remove_fifo((v_waste_item->>'raw_material_id')::uuid, v_order.branch_id, v_req,
          'waste', 'production_order', v_order.id, v_order.order_number, auth.uid());
        v_cost := v_cost + (v_res->>'total_cost')::numeric;
        INSERT INTO public.production_waste (order_id, branch_id, raw_material_id, quantity, reason)
        VALUES (v_order.id, v_order.branch_id, (v_waste_item->>'raw_material_id')::uuid, v_req,
                COALESCE(v_waste_item->>'reason', 'Ø¥Ù†ØªØ§Ø¬'));
      END LOOP;
    END IF;

    -- Produce output as a new batch
    v_unit_cost := CASE WHEN v_order.quantity > 0 THEN round(v_cost / v_order.quantity, 2) ELSE 0 END;
    v_res := public._product_inv_add(v_order.product_id, v_order.warehouse_id, v_order.branch_id,
      v_order.quantity, v_unit_cost, v_order.batch_number, CURRENT_DATE, NULL,
      'production', 'production_order', v_order.id, v_order.order_number, auth.uid());
    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    UPDATE public.production_orders
    SET status = 'completed', total_cost = v_cost, completed_at = now()
    WHERE id = v_order.id;

    -- ===== LEDGER POSTING: raw consumed into WIP, output to finished goods =====
    IF v_cost > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'wip', 'debit', v_cost, 'credit', 0, 'note', v_order.order_number);
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', 0, 'credit', v_cost, 'note', v_order.order_number);
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', v_cost, 'credit', 0, 'note', v_order.order_number);
      v_lines := v_lines || jsonb_build_object('account_key', 'wip', 'debit', 0, 'credit', v_cost, 'note', v_order.order_number);
      PERFORM public._post_journal_entry(v_order.branch_id, 'production', v_order.id, v_order.order_number,
        'Ø¥Ù†ØªØ§Ø¬ ' || v_order.order_number, v_lines);
    END IF;

    RETURN jsonb_build_object('success', true, 'order_id', v_order.id, 'order_number', v_order.order_number,
      'total_cost', v_cost, 'unit_cost', v_unit_cost);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. adjust_stock: post inventory variance against the stock variance a/c
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adjust_stock(p_inventory_id uuid, p_new_quantity numeric, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_inv record;
  v_user_branch uuid;
  v_delta numeric(14,4);
  v_res jsonb;
  v_value numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    -- Only admins, branch managers and warehouse managers may adjust stock
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Stock adjustments require the warehouse manager or branch manager role.');
    END IF;

    SELECT i.id, i.product_id, i.warehouse_id, i.quantity, i.branch_id, p.cost_price AS cost
    INTO v_inv
    FROM inventory i
    JOIN products p ON p.id = i.product_id
    WHERE i.id = p_inventory_id
    FOR UPDATE OF i;

    IF v_inv.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVENTORY_NOT_FOUND');
    END IF;

    -- Branch isolation
    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND v_inv.branch_id IS NOT NULL AND v_user_branch <> v_inv.branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    v_delta := p_new_quantity - v_inv.quantity;
    IF v_delta = 0 THEN
      RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id, 'no_change', true);
    END IF;

    IF v_delta > 0 THEN
      v_res := public._product_inv_add(v_inv.product_id, v_inv.warehouse_id, v_inv.branch_id, v_delta,
        COALESCE(v_inv.cost, 0), 'ADJ', NULL, NULL,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
      v_value := round(v_delta * COALESCE(v_inv.cost, 0), 2);
    ELSE
      v_res := public._product_inv_remove_fifo(v_inv.product_id, v_inv.warehouse_id, v_inv.branch_id, -v_delta,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
      v_value := round(COALESCE((v_res->>'total_cost')::numeric, 0), 2);
    END IF;

    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    -- ===== LEDGER POSTING =====
    IF v_value > 0 THEN
      IF v_delta > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', v_value, 'credit', 0, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
        v_lines := v_lines || jsonb_build_object('account_key', 'stock_variance', 'debit', 0, 'credit', v_value, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
      ELSE
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', 0, 'credit', v_value, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
        v_lines := v_lines || jsonb_build_object('account_key', 'stock_variance', 'debit', v_value, 'credit', 0, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
      END IF;
      PERFORM public._post_journal_entry(v_inv.branch_id, 'adjustment', NULL, NULL,
        'ØªØ³ÙˆÙŠØ© Ù…Ø®Ø²ÙˆÙ† ' || COALESCE(p_reason, ''), v_lines);
    END IF;

    RETURN jsonb_build_object('success', true, 'inventory_id', p_inventory_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 6. adjust_raw_stock: post raw variance against the stock variance a/c
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adjust_raw_stock(p_raw_material_id uuid, p_branch_id uuid, p_new_quantity numeric, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_cur numeric(14,4);
  v_delta numeric(14,4);
  v_user_branch uuid;
  v_res jsonb;
  v_cost numeric(12,2);
  v_value numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Raw material adjustments require the warehouse manager or branch manager role.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    SELECT COALESCE(quantity, 0), COALESCE(avg_cost, 0)
    INTO v_cur, v_cost
    FROM public.raw_material_inventory
    WHERE raw_material_id = p_raw_material_id AND branch_id = p_branch_id;
    IF v_cur IS NULL THEN v_cur := 0; END IF;

    v_delta := p_new_quantity - v_cur;
    IF v_delta = 0 THEN
      RETURN jsonb_build_object('success', true, 'raw_material_id', p_raw_material_id, 'no_change', true);
    END IF;

    IF v_delta > 0 THEN
      v_res := public._raw_add(p_raw_material_id, p_branch_id, v_delta, v_cost,
        'ADJ', NULL, NULL, 'adjustment', 'adjustment', NULL, p_reason, auth.uid());
      v_value := round(v_delta * COALESCE(v_cost, 0), 2);
    ELSE
      v_res := public._raw_remove_fifo(p_raw_material_id, p_branch_id, -v_delta,
        'adjustment', 'adjustment', NULL, p_reason, auth.uid());
      v_value := round(COALESCE((v_res->>'total_cost')::numeric, 0), 2);
    END IF;

    IF NOT (v_res->>'success')::boolean THEN
      RETURN v_res;
    END IF;

    -- ===== LEDGER POSTING =====
    IF v_value > 0 THEN
      IF v_delta > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', v_value, 'credit', 0, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
        v_lines := v_lines || jsonb_build_object('account_key', 'stock_variance', 'debit', 0, 'credit', v_value, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
      ELSE
        v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', 0, 'credit', v_value, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
        v_lines := v_lines || jsonb_build_object('account_key', 'stock_variance', 'debit', v_value, 'credit', 0, 'note', COALESCE(p_reason, 'Ø¬Ø±Ø¯'));
      END IF;
      PERFORM public._post_journal_entry(p_branch_id, 'adjustment', NULL, NULL,
        'ØªØ³ÙˆÙŠØ© Ø®Ø§Ù…Ø§Øª ' || COALESCE(p_reason, ''), v_lines);
    END IF;

    RETURN jsonb_build_object('success', true, 'raw_material_id', p_raw_material_id, 'quantity', p_new_quantity);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- Reload the PostgREST schema cache.
-- ---------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 021_d3_ap.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D3: Accounts payable - supplier payments + purchase returns
-- =====================================================================
-- Adds the AP side of the ledger, mirroring the AR module (Phase C/T0):
--   1. supplier_payments      -> receipts of payments made to suppliers
--   2. pay_supplier (new)     -> cash/bank out, AP in (idempotent per
--                                payment reference, applied to open invoices)
--   3. process_purchase_return (new) -> reverse goods + VAT, remove stock,
--                                adjust discount received, cash/AP back
-- All posting goes through _post_journal_entry with semantic keys and is
-- idempotent; existing RLS is never weakened.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Purchase return tracking columns (mirror of sale_items/sales)
-- ---------------------------------------------------------------------
ALTER TABLE public.purchase_items
  ADD COLUMN IF NOT EXISTS returned_quantity numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS returned_amount numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE public.purchases
  ADD COLUMN IF NOT EXISTS returned_amount numeric(14,2) NOT NULL DEFAULT 0;

-- Allow the new movement type in the legacy stock_transactions log
ALTER TABLE public.stock_transactions DROP CONSTRAINT IF EXISTS stock_transactions_transaction_type_check;
ALTER TABLE public.stock_transactions ADD CONSTRAINT stock_transactions_transaction_type_check
  CHECK (transaction_type IN ('sale', 'purchase', 'adjustment', 'refund',
                              'transfer', 'production', 'waste', 'opening',
                              'purchase_return'));

-- ---------------------------------------------------------------------
-- 1. supplier_payments table (mirror of customer_payments)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.supplier_payments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id       uuid NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  amount            numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_method    text NOT NULL DEFAULT 'cash',
  purchase_id       uuid REFERENCES public.purchases(id) ON DELETE SET NULL,
  reference_number  text,
  notes             text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.supplier_payments IS 'Ø³Ù†Ø¯Ø§Øª Ø§Ù„Ø¯ÙØ¹ (Ø¯ÙØ¹ Ù„Ù„Ù…ÙˆØ±Ø¯ÙŠÙ† Ù…Ù‚Ø§Ø¨Ù„ Ø°Ù…Ù… Ø¯Ø§Ø¦Ù†Ø©)';

CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier ON public.supplier_payments (supplier_id, created_at);

ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "supplier_payments_select" ON public.supplier_payments;
CREATE POLICY "supplier_payments_select" ON public.supplier_payments
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "supplier_payments_insert" ON public.supplier_payments;
CREATE POLICY "supplier_payments_insert" ON public.supplier_payments
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());

INSERT INTO public.document_sequences (seq_type, next_value) VALUES ('supplier_payment', 1)
ON CONFLICT (seq_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. pay_supplier: pay open invoices, post cash/bank vs AP
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pay_supplier(
  p_supplier_id uuid,
  p_branch_id uuid,
  p_amount numeric,
  p_payment_method text DEFAULT 'cash',
  p_purchase_id uuid DEFAULT NULL,
  p_notes text DEFAULT NULL
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_payment_id uuid;
  v_number text;
  v_user_branch uuid;
  v_remaining numeric(14,2);
  v_purchase record;
  v_applied numeric(14,2);
  v_open numeric(14,2);
  v_total_open numeric(14,2);
  v_payment_account text;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Supplier payments require the accountant or branch manager role.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM suppliers WHERE id = p_supplier_id AND branch_id = p_branch_id) THEN
      RETURN jsonb_build_object('success', false, 'error', 'SUPPLIER_NOT_FOUND');
    END IF;

    -- Payments must be backed by open payable (no free-floating debits).
    SELECT COALESCE(SUM(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.returned_amount, 0)), 0)
    INTO v_total_open
    FROM public.purchases s
    WHERE s.supplier_id = p_supplier_id AND s.branch_id = p_branch_id AND s.status = 'completed';

    IF p_purchase_id IS NULL THEN
      IF round(p_amount, 2) > round(v_total_open, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_AP',
          'open', round(v_total_open, 2), 'detail', 'The payment exceeds the supplier open balance.');
      END IF;
    ELSE
      SELECT total, COALESCE(paid_amount, 0), COALESCE(returned_amount, 0) INTO v_purchase
      FROM public.purchases WHERE id = p_purchase_id AND supplier_id = p_supplier_id AND branch_id = p_branch_id
        AND status = 'completed' FOR UPDATE;
      IF v_purchase.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'PURCHASE_NOT_FOUND',
          'detail', 'No completed invoice found for this supplier with that id.');
      END IF;
      IF round(p_amount, 2) > round(v_purchase.total - v_purchase.paid_amount - v_purchase.returned_amount, 2) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PAYMENT_EXCEEDS_INVOICE',
          'open', round(v_purchase.total - v_purchase.paid_amount - v_purchase.returned_amount, 2));
      END IF;
    END IF;

    v_number := (public.next_document_number('supplier_payment')->>'number')::text;

    INSERT INTO public.supplier_payments (supplier_id, branch_id, amount, payment_method, purchase_id, reference_number, notes, created_by)
    VALUES (p_supplier_id, p_branch_id, p_amount, p_payment_method, p_purchase_id, v_number, p_notes, auth.uid())
    RETURNING id INTO v_payment_id;

    -- Apply payment against invoices (specific or oldest open first)
    v_remaining := round(p_amount, 2);

    IF p_purchase_id IS NOT NULL THEN
      v_open := round(v_purchase.total - v_purchase.paid_amount - v_purchase.returned_amount, 2);
      v_applied := LEAST(v_remaining, v_open);
      UPDATE public.purchases SET paid_amount = COALESCE(paid_amount, 0) + v_applied
      WHERE id = p_purchase_id;
      v_remaining := round(v_remaining - v_applied, 2);
    ELSIF v_remaining > 0 THEN
      FOR v_purchase IN
        SELECT id, total, paid_amount, returned_amount FROM public.purchases
        WHERE supplier_id = p_supplier_id AND branch_id = p_branch_id AND status = 'completed'
          AND (total - COALESCE(paid_amount, 0) - COALESCE(returned_amount, 0)) > 0
        ORDER BY created_at ASC
        FOR UPDATE
      LOOP
        IF v_remaining <= 0 THEN EXIT; END IF;
        v_open := round(v_purchase.total - COALESCE(v_purchase.paid_amount, 0) - COALESCE(v_purchase.returned_amount, 0), 2);
        v_applied := LEAST(v_remaining, v_open);
        UPDATE public.purchases SET paid_amount = COALESCE(paid_amount, 0) + v_applied
        WHERE id = v_purchase.id;
        v_remaining := round(v_remaining - v_applied, 2);
      END LOOP;
    END IF;

    -- Post the payment journal entry (AP debit, cash/bank credit)
    v_payment_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END;
    v_lines := v_lines || jsonb_build_object('account_key', 'ap',
      'debit', round(p_amount, 2), 'credit', 0, 'supplier_id', p_supplier_id, 'note', v_number);
    v_lines := v_lines || jsonb_build_object('account_key', v_payment_account,
      'debit', 0, 'credit', round(p_amount, 2), 'note', v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'supplier_payment', v_payment_id, v_number,
      'Ø³Ù†Ø¯ Ø¯ÙØ¹ ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'payment_id', v_payment_id, 'reference_number', v_number,
      'unapplied', v_remaining);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 3. process_purchase_return: return goods to the supplier
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_purchase_return(
  p_purchase_id uuid,
  p_items jsonb DEFAULT NULL::jsonb,
  p_reason text DEFAULT NULL::text
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_purchase record;
  v_user_branch uuid;
  v_return_total numeric(14,2) := 0;
  v_item record;
  v_req jsonb;
  v_item_id uuid;
  v_req_qty numeric(14,4);
  v_already numeric(14,4);
  v_ret_qty numeric(14,4);
  v_item_line_total numeric(14,2);
  v_item_ret_amt numeric(14,2);
  v_all_returned boolean := true;
  v_remaining numeric(14,4);
  v_res jsonb;
  v_purchase_entry uuid;
  v_fg numeric(14,2);
  v_rm numeric(14,2);
  v_vat numeric(14,2);
  v_discount numeric(14,2);
  v_paid_cash numeric(14,2);
  v_paid_bank numeric(14,2);
  v_ap numeric(14,2);
  v_ratio numeric(14,6);
  v_fg_r numeric(14,2);
  v_rm_r numeric(14,2);
  v_vat_r numeric(14,2);
  v_discount_r numeric(14,2);
  v_paid_r numeric(14,2);
  v_ap_r numeric(14,2);
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
  v_credit_key text;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    IF p_purchase_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_PURCHASE');
    END IF;

    SELECT id, branch_id, warehouse_id, status, total, paid_amount, supplier_id, invoice_number
      INTO v_purchase FROM public.purchases WHERE id = p_purchase_id;
    IF v_purchase.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'PURCHASE_NOT_FOUND');
    END IF;

    IF v_purchase.status = 'returned' THEN
      RETURN jsonb_build_object('success', false, 'error', 'ALREADY_RETURNED');
    END IF;
    IF v_purchase.status <> 'completed' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS',
        'status', v_purchase.status, 'detail', 'Only completed purchases can be returned.');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('warehouse_manager','branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Purchase returns require the purchases.manage permission.');
    END IF;

    SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND v_user_branch IS NOT NULL
       AND v_purchase.branch_id IS NOT NULL AND v_user_branch <> v_purchase.branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    -- ===== VALIDATION PHASE =====
    IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
      FOR v_req IN SELECT * FROM jsonb_array_elements(p_items)
      LOOP
        v_item_id := (v_req->>'purchase_item_id')::uuid;
        v_req_qty := COALESCE((v_req->>'quantity')::numeric, 0);
        IF v_req_qty <= 0 THEN
          RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'purchase_item_id', v_item_id);
        END IF;
        SELECT id, quantity, returned_quantity INTO v_item
          FROM purchase_items WHERE id = v_item_id AND purchase_id = p_purchase_id;
        IF v_item.id IS NULL THEN
          RETURN jsonb_build_object('success', false, 'error', 'ITEM_NOT_FOUND', 'purchase_item_id', v_item_id);
        END IF;
        v_already := COALESCE(v_item.returned_quantity, 0);
        IF v_req_qty > v_item.quantity - v_already THEN
          RETURN jsonb_build_object('success', false, 'error', 'RETURN_EXCEEDS_QUANTITY',
            'purchase_item_id', v_item_id, 'max', v_item.quantity - v_already);
        END IF;
      END LOOP;
    END IF;

    -- ===== RETURN + RESTOCK-OUT PHASE =====
    FOR v_item IN SELECT id, product_id, raw_material_id, quantity, unit_cost, returned_quantity
                  FROM purchase_items WHERE purchase_id = p_purchase_id
    LOOP
      IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
        v_req_qty := 0;
        SELECT (req->>'quantity')::numeric INTO v_req_qty
        FROM jsonb_array_elements(p_items) req
        WHERE (req->>'purchase_item_id')::uuid = v_item.id;
        v_req_qty := COALESCE(v_req_qty, 0);
      ELSE
        v_req_qty := v_item.quantity - COALESCE(v_item.returned_quantity, 0);
      END IF;
      IF v_req_qty <= 0 THEN CONTINUE; END IF;

      v_item_line_total := v_item.quantity * v_item.unit_cost;
      IF v_item.quantity > 0 THEN
        v_item_ret_amt := ROUND(v_item_line_total * v_req_qty / v_item.quantity, 2);
      ELSE
        v_item_ret_amt := 0;
      END IF;
      v_return_total := v_return_total + v_item_ret_amt;

      UPDATE purchase_items
        SET returned_quantity = COALESCE(returned_quantity, 0) + v_req_qty,
            returned_amount = COALESCE(returned_amount, 0) + v_item_ret_amt
        WHERE id = v_item.id;

      -- Return the goods to the supplier (remove from the receiving warehouse)
      v_remaining := v_req_qty;
      IF v_item.product_id IS NOT NULL THEN
        v_res := public._product_inv_remove_fifo(v_item.product_id, v_purchase.warehouse_id,
          v_purchase.branch_id, v_remaining, 'purchase_return', 'purchase_return',
          p_purchase_id, v_purchase.invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
      ELSIF v_item.raw_material_id IS NOT NULL THEN
        v_res := public._raw_remove_fifo(v_item.raw_material_id, v_purchase.branch_id,
          v_remaining, 'purchase_return', 'purchase_return', p_purchase_id,
          v_purchase.invoice_number, auth.uid());
        IF NOT (v_res->>'success')::boolean THEN
          RETURN v_res;
        END IF;
      END IF;
    END LOOP;

    -- Update header: full return flips the status, otherwise accumulate returned_amount
    SELECT bool_and(quantity = returned_quantity) INTO v_all_returned
      FROM purchase_items WHERE purchase_id = p_purchase_id;
    UPDATE purchases SET
      returned_amount = COALESCE(returned_amount, 0) + v_return_total,
      status = CASE WHEN v_all_returned THEN 'returned' ELSE status END,
      notes = CASE WHEN p_reason IS NOT NULL THEN COALESCE(notes, '') || E'\n' || p_reason ELSE notes END
      WHERE id = p_purchase_id;

    -- ===== LEDGER POSTING: prorated reversal of the purchase entry =====
    IF v_return_total > 0 THEN
      SELECT id INTO v_purchase_entry
      FROM public.journal_entries
      WHERE branch_id = v_purchase.branch_id AND reference_type = 'purchase' AND reference_id = p_purchase_id;

      IF v_purchase_entry IS NOT NULL THEN
        SELECT
          round(COALESCE(SUM(CASE WHEN a.id = m.fg_id THEN l.debit - l.credit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.rm_id THEN l.debit - l.credit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.vat_id THEN l.debit - l.credit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.disc_id THEN l.credit - l.debit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.cash_id THEN l.credit - l.debit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.bank_id THEN l.credit - l.debit ELSE 0 END), 0), 2),
          round(COALESCE(SUM(CASE WHEN a.id = m.ap_id THEN l.credit - l.debit ELSE 0 END), 0), 2)
        INTO v_fg, v_rm, v_vat, v_discount, v_paid_cash, v_paid_bank, v_ap
        FROM public.journal_entry_lines l
        JOIN public.chart_of_accounts a ON a.id = l.account_id
        CROSS JOIN (
          SELECT
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'inventory_fg')) AS fg_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'inventory_rm')) AS rm_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'vat_receivable')) AS vat_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'discount_received')) AS disc_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'cash')) AS cash_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'bank')) AS bank_id,
            (SELECT public.resolve_account_key(v_purchase.branch_id, 'ap')) AS ap_id
        ) m
        WHERE l.journal_entry_id = v_purchase_entry;

        v_ratio := round(v_return_total / GREATEST(COALESCE(v_purchase.total, 0), 1), 6);
        v_fg_r := round(COALESCE(v_fg, 0) * v_ratio, 2);
        v_rm_r := round(COALESCE(v_rm, 0) * v_ratio, 2);
        v_vat_r := round(COALESCE(v_vat, 0) * v_ratio, 2);
        v_discount_r := round(COALESCE(v_discount, 0) * v_ratio, 2);
        v_paid_r := round((COALESCE(v_paid_cash, 0) + COALESCE(v_paid_bank, 0)) * v_ratio, 2);
        v_ap_r := round(COALESCE(v_ap, 0) * v_ratio, 2);

        v_credit_key := CASE WHEN COALESCE(v_paid_cash, 0) >= COALESCE(v_paid_bank, 0) THEN 'cash' ELSE 'bank' END;

        IF v_fg_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', 0, 'credit', v_fg_r);
          v_cr := v_cr + v_fg_r;
        END IF;
        IF v_rm_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'inventory_rm', 'debit', 0, 'credit', v_rm_r);
          v_cr := v_cr + v_rm_r;
        END IF;
        IF v_vat_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'vat_receivable', 'debit', 0, 'credit', v_vat_r);
          v_cr := v_cr + v_vat_r;
        END IF;
        IF v_discount_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', v_discount_r, 'credit', 0);
          v_dr := v_dr + v_discount_r;
        END IF;
        IF v_paid_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', v_credit_key, 'debit', v_paid_r, 'credit', 0,
            'note', 'Ù…Ø±ØªØ¬Ø¹ ' || v_purchase.invoice_number);
          v_dr := v_dr + v_paid_r;
        END IF;
        IF v_ap_r > 0 THEN
          v_lines := v_lines || jsonb_build_object('account_key', 'ap', 'debit', v_ap_r, 'credit', 0,
            'supplier_id', v_purchase.supplier_id, 'note', 'Ù…Ø±ØªØ¬Ø¹ ' || v_purchase.invoice_number);
          v_dr := v_dr + v_ap_r;
        END IF;

        v_diff := round(v_dr - v_cr, 2);
        IF v_diff <> 0 THEN
          IF v_diff > 0 THEN
            v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', 0, 'credit', v_diff);
          ELSE
            v_lines := v_lines || jsonb_build_object('account_key', 'discount_received', 'debit', -v_diff, 'credit', 0);
          END IF;
        END IF;

        PERFORM public._post_journal_entry(v_purchase.branch_id, 'purchase_return', NULL, v_purchase.invoice_number,
          'Ù…Ø±ØªØ¬Ø¹ ÙØ§ØªÙˆØ±Ø© Ø´Ø±Ø§Ø¡ ' || v_purchase.invoice_number, v_lines);
      END IF;
    END IF;

    RETURN jsonb_build_object('success', true, 'purchase_id', p_purchase_id,
      'returned_amount', v_return_total, 'fully_returned', v_all_returned);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- Reload the PostgREST schema cache.
-- ---------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 022_d4_treasury.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D4: Treasury - cash/bank accounts, transfers & deposits
-- =====================================================================
-- Full treasury module over the chart of accounts:
--   1. treasury_accounts      -> named cash drawers / bank accounts per
--                                branch, each linked to a chart account
--   2. treasury_transactions  -> audit log of every movement
--   3. process_transfer       -> between two treasury accounts
--   4. process_treasury_deposit    -> owner funds entering a treasury account
--   5. process_treasury_withdrawal -> owner funds leaving a treasury account
--   6. get_treasury_balances  -> ledger balance per treasury account
-- All movements post through _post_journal_entry (idempotent per reference)
-- and never weaken existing RLS.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. treasury_accounts
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.treasury_accounts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  account_id      uuid NOT NULL REFERENCES public.chart_of_accounts(id) ON DELETE CASCADE,
  account_type    text NOT NULL DEFAULT 'cash' CHECK (account_type IN ('cash', 'bank')),
  account_name    text NOT NULL,
  account_number  text,
  is_active       boolean NOT NULL DEFAULT true,
  opening_balance numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (branch_id, account_id)
);
COMMENT ON TABLE public.treasury_accounts IS 'Ø­Ø³Ø§Ø¨Ø§Øª Ø§Ù„Ø®Ø²ÙŠÙ†Ø© (Ø¯Ø±Ø¬ Ù†Ù‚Ø¯ÙŠØ© / Ø­Ø³Ø§Ø¨ Ø¨Ù†ÙƒÙŠ) Ù„ÙƒÙ„ ÙØ±Ø¹ØŒ Ù…Ø±ØªØ¨Ø·Ø© Ø¨Ø´Ø¬Ø±Ø© Ø§Ù„Ø­Ø³Ø§Ø¨Ø§Øª';

CREATE INDEX IF NOT EXISTS idx_treasury_accounts_branch ON public.treasury_accounts (branch_id, is_active);

ALTER TABLE public.treasury_accounts ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER trg_treasury_accounts_updated BEFORE UPDATE ON public.treasury_accounts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "treasury_accounts_select" ON public.treasury_accounts;
CREATE POLICY "treasury_accounts_select" ON public.treasury_accounts
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "treasury_accounts_insert" ON public.treasury_accounts;
CREATE POLICY "treasury_accounts_insert" ON public.treasury_accounts
  FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
DROP POLICY IF EXISTS "treasury_accounts_update" ON public.treasury_accounts;
CREATE POLICY "treasury_accounts_update" ON public.treasury_accounts
  FOR UPDATE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));
DROP POLICY IF EXISTS "treasury_accounts_delete" ON public.treasury_accounts;
CREATE POLICY "treasury_accounts_delete" ON public.treasury_accounts
  FOR DELETE TO authenticated
  USING (is_pos_admin() OR (can_permission('accounts.manage') AND branch_id = get_branch_id()));

-- Seed one cash + one bank account per branch from the mapped accounts
CREATE OR REPLACE FUNCTION public.seed_treasury_accounts(p_branch_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.treasury_accounts (branch_id, account_id, account_type, account_name)
  SELECT p_branch_id, m.account_id, m.semantic_key, a.name
  FROM public.account_mappings m
  JOIN public.chart_of_accounts a ON a.id = m.account_id
  WHERE m.branch_id = p_branch_id AND m.semantic_key IN ('cash', 'bank')
  ON CONFLICT (branch_id, account_id) DO NOTHING;
END;
$function$;

SELECT public.seed_treasury_accounts(id) FROM public.branches;

-- ---------------------------------------------------------------------
-- 2. treasury_transactions (movement audit log)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.treasury_transactions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id         uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  transaction_type  text NOT NULL CHECK (transaction_type IN ('transfer', 'deposit', 'withdrawal')),
  from_account_id   uuid REFERENCES public.treasury_accounts(id),
  to_account_id     uuid REFERENCES public.treasury_accounts(id),
  amount            numeric(14,2) NOT NULL CHECK (amount > 0),
  reference_number  text,
  notes             text,
  created_by        uuid REFERENCES public.users(id),
  created_at        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.treasury_transactions IS 'Ø­Ø±ÙƒØ§Øª Ø§Ù„Ø®Ø²ÙŠÙ†Ø© (ØªØ­ÙˆÙŠÙ„ / Ø¥ÙŠØ¯Ø§Ø¹ / Ø³Ø­Ø¨)';

CREATE INDEX IF NOT EXISTS idx_treasury_transactions_branch ON public.treasury_transactions (branch_id, created_at DESC);

ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "treasury_transactions_select" ON public.treasury_transactions;
CREATE POLICY "treasury_transactions_select" ON public.treasury_transactions
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "treasury_transactions_insert" ON public.treasury_transactions;
CREATE POLICY "treasury_transactions_insert" ON public.treasury_transactions
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());

INSERT INTO public.document_sequences (seq_type, next_value) VALUES ('treasury', 1)
ON CONFLICT (seq_type) DO NOTHING;

-- ---------------------------------------------------------------------
-- 3. Shared validation for treasury RPCs
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._treasury_guard(p_branch_id uuid, p_account_id uuid, p_amount numeric)
RETURNS jsonb
LANGUAGE plpgsql STABLE
SET search_path TO 'public'
AS $function$
DECLARE
  v_account record;
  v_user_branch uuid;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'INVALID_AMOUNT');
  END IF;

  IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'NOT_ALLOWED',
      'detail', 'Treasury operations require the accountant or branch manager role.');
  END IF;

  IF NOT is_pos_admin() THEN
    SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
    IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
      RETURN jsonb_build_object('ok', false, 'error', 'BRANCH_MISMATCH');
    END IF;
  END IF;

  IF p_account_id IS NOT NULL THEN
    SELECT id, account_id, account_type, is_active INTO v_account
    FROM public.treasury_accounts
    WHERE id = p_account_id AND branch_id = p_branch_id;
    IF v_account.id IS NULL THEN
      RETURN jsonb_build_object('ok', false, 'error', 'TREASURY_ACCOUNT_NOT_FOUND');
    END IF;
    IF NOT v_account.is_active THEN
      RETURN jsonb_build_object('ok', false, 'error', 'TREASURY_ACCOUNT_INACTIVE');
    END IF;
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. process_transfer: move money between two treasury accounts
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_transfer(
  p_branch_id uuid,
  p_from_account_id uuid,
  p_to_account_id uuid,
  p_amount numeric,
  p_notes text DEFAULT NULL::text
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_guard jsonb;
  v_from record;
  v_to record;
  v_number text;
  v_tx_id uuid;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    v_guard := public._treasury_guard(p_branch_id, p_from_account_id, p_amount);
    IF NOT (v_guard->>'ok')::boolean THEN
      RETURN v_guard;
    END IF;
    v_guard := public._treasury_guard(p_branch_id, p_to_account_id, p_amount);
    IF NOT (v_guard->>'ok')::boolean THEN
      RETURN v_guard;
    END IF;

    IF p_from_account_id = p_to_account_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'SAME_ACCOUNT');
    END IF;

    SELECT id, account_id, account_type, account_name INTO v_from
    FROM public.treasury_accounts WHERE id = p_from_account_id;
    SELECT id, account_id, account_type, account_name INTO v_to
    FROM public.treasury_accounts WHERE id = p_to_account_id;

    v_number := (public.next_document_number('treasury')->>'number')::text;

    INSERT INTO public.treasury_transactions (branch_id, transaction_type, from_account_id, to_account_id, amount, reference_number, notes, created_by)
    VALUES (p_branch_id, 'transfer', p_from_account_id, p_to_account_id, p_amount, v_number, p_notes, auth.uid())
    RETURNING id INTO v_tx_id;

    v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_to.account_id),
      'debit', round(p_amount, 2), 'credit', 0, 'note', 'ØªØ­ÙˆÙŠÙ„ ' || v_number);
    v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_from.account_id),
      'debit', 0, 'credit', round(p_amount, 2), 'note', 'ØªØ­ÙˆÙŠÙ„ ' || v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'transfer', v_tx_id, v_number,
      'ØªØ­ÙˆÙŠÙ„ Ø®Ø²ÙŠÙ†Ø© ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'transaction_id', v_tx_id, 'reference_number', v_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. process_treasury_deposit: owner funds into a treasury account
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_treasury_deposit(
  p_branch_id uuid,
  p_account_id uuid,
  p_amount numeric,
  p_notes text DEFAULT NULL::text
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_guard jsonb;
  v_account record;
  v_number text;
  v_tx_id uuid;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    v_guard := public._treasury_guard(p_branch_id, p_account_id, p_amount);
    IF NOT (v_guard->>'ok')::boolean THEN
      RETURN v_guard;
    END IF;

    SELECT id, account_id INTO v_account FROM public.treasury_accounts WHERE id = p_account_id;

    v_number := (public.next_document_number('treasury')->>'number')::text;

    INSERT INTO public.treasury_transactions (branch_id, transaction_type, to_account_id, amount, reference_number, notes, created_by)
    VALUES (p_branch_id, 'deposit', p_account_id, p_amount, v_number, p_notes, auth.uid())
    RETURNING id INTO v_tx_id;

    v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_account.account_id),
      'debit', round(p_amount, 2), 'credit', 0, 'note', 'Ø¥ÙŠØ¯Ø§Ø¹ ' || v_number);
    v_lines := v_lines || jsonb_build_object('account_key', 'capital',
      'debit', 0, 'credit', round(p_amount, 2), 'note', 'Ø¥ÙŠØ¯Ø§Ø¹ ' || v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'treasury_deposit', v_tx_id, v_number,
      'Ø¥ÙŠØ¯Ø§Ø¹ Ø®Ø²ÙŠÙ†Ø© ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'transaction_id', v_tx_id, 'reference_number', v_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 6. process_treasury_withdrawal: owner funds out of a treasury account
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_treasury_withdrawal(
  p_branch_id uuid,
  p_account_id uuid,
  p_amount numeric,
  p_notes text DEFAULT NULL::text
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_guard jsonb;
  v_account record;
  v_number text;
  v_tx_id uuid;
  v_lines jsonb := '[]'::jsonb;
BEGIN
  BEGIN
    v_guard := public._treasury_guard(p_branch_id, p_account_id, p_amount);
    IF NOT (v_guard->>'ok')::boolean THEN
      RETURN v_guard;
    END IF;

    SELECT id, account_id INTO v_account FROM public.treasury_accounts WHERE id = p_account_id;

    v_number := (public.next_document_number('treasury')->>'number')::text;

    INSERT INTO public.treasury_transactions (branch_id, transaction_type, from_account_id, amount, reference_number, notes, created_by)
    VALUES (p_branch_id, 'withdrawal', p_account_id, p_amount, v_number, p_notes, auth.uid())
    RETURNING id INTO v_tx_id;

    v_lines := v_lines || jsonb_build_object('account_key', 'capital',
      'debit', round(p_amount, 2), 'credit', 0, 'note', 'Ø³Ø­Ø¨ ' || v_number);
    v_lines := v_lines || jsonb_build_object('account_code', (SELECT code FROM public.chart_of_accounts WHERE id = v_account.account_id),
      'debit', 0, 'credit', round(p_amount, 2), 'note', 'Ø³Ø­Ø¨ ' || v_number);

    PERFORM public._post_journal_entry(p_branch_id, 'treasury_withdrawal', v_tx_id, v_number,
      'Ø³Ø­Ø¨ Ø®Ø²ÙŠÙ†Ø© ' || v_number, v_lines);

    RETURN jsonb_build_object('success', true, 'transaction_id', v_tx_id, 'reference_number', v_number);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 7. get_treasury_balances: ledger balance per treasury account
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_treasury_balances(p_branch_id uuid)
RETURNS jsonb
LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE
AS $function$
SELECT COALESCE(jsonb_agg(s.jb ORDER BY s.jb->>'account_type', s.jb->>'account_name'), '[]'::jsonb)
FROM (
  SELECT jsonb_build_object(
    'id', t.id,
    'account_type', t.account_type,
    'account_name', t.account_name,
    'account_number', t.account_number,
    'code', a.code,
    'is_active', t.is_active,
    'opening_balance', round(COALESCE(t.opening_balance, 0), 2),
    'balance', round(COALESCE(SUM(l.debit - l.credit), 0), 2)
  ) AS jb
  FROM public.treasury_accounts t
  JOIN public.chart_of_accounts a ON a.id = t.account_id
  LEFT JOIN public.journal_entry_lines l ON l.account_id = a.id
  WHERE t.branch_id = p_branch_id
  GROUP BY t.id, t.account_type, t.account_name, t.account_number, a.code, t.is_active, t.opening_balance
) s;
$function$;

-- ---------------------------------------------------------------------
-- Reload the PostgREST schema cache.
-- ---------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 023_d5_reconciliation.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D5: Bank reconciliation
-- =====================================================================
-- Reconciling treasury bank accounts against the bank statement:
--   1. bank_reconciliations  -> header (statement date, balances, status)
--   2. bank_statement_lines  -> statement entries, optionally matched to
--                               a posted journal entry
--   3. create_bank_reconciliation -> opens a reconciliation and computes
--                               book balance + difference
--   4. add_statement_line / match_bank_line -> build the statement side
--   5. complete_bank_reconciliation -> validates the difference is fully
--                               explained, then closes the reconciliation
--   6. get_bank_reconciliation -> header + lines + book candidates
-- No posting happens here (bank charges etc. are expense transactions);
-- RLS is never weakened.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. bank_reconciliations
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bank_reconciliations (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id            uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  treasury_account_id  uuid NOT NULL REFERENCES public.treasury_accounts(id) ON DELETE CASCADE,
  statement_date       date NOT NULL,
  statement_balance    numeric(14,2) NOT NULL,
  book_balance         numeric(14,2) NOT NULL DEFAULT 0,
  difference           numeric(14,2) NOT NULL DEFAULT 0,
  status               text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'completed', 'cancelled')),
  created_by           uuid REFERENCES public.users(id),
  created_at           timestamptz NOT NULL DEFAULT now(),
  closed_at            timestamptz
);
COMMENT ON TABLE public.bank_reconciliations IS 'ØªØ³ÙˆÙŠØ§Øª Ø¨Ù†ÙƒÙŠØ©: Ù…Ø·Ø§Ø¨Ù‚Ø© ÙƒØ´Ù Ø§Ù„Ø¨Ù†Ùƒ Ù…Ø¹ Ø§Ù„Ø¯ÙØªØ± Ù„ÙƒÙ„ Ø­Ø³Ø§Ø¨ Ø¨Ù†ÙƒÙŠ';

CREATE INDEX IF NOT EXISTS idx_bank_recon_branch ON public.bank_reconciliations (branch_id, statement_date DESC);

ALTER TABLE public.bank_reconciliations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bank_reconciliations_select" ON public.bank_reconciliations;
CREATE POLICY "bank_reconciliations_select" ON public.bank_reconciliations
  FOR SELECT TO authenticated USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "bank_reconciliations_insert" ON public.bank_reconciliations;
CREATE POLICY "bank_reconciliations_insert" ON public.bank_reconciliations
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "bank_reconciliations_update" ON public.bank_reconciliations;
CREATE POLICY "bank_reconciliations_update" ON public.bank_reconciliations
  FOR UPDATE TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 2. bank_statement_lines
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bank_statement_lines (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reconciliation_id       uuid NOT NULL REFERENCES public.bank_reconciliations(id) ON DELETE CASCADE,
  statement_date          date NOT NULL,
  description             text,
  reference               text,
  amount                  numeric(14,2) NOT NULL,
  matched_journal_entry_id uuid REFERENCES public.journal_entries(id) ON DELETE SET NULL,
  created_at              timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.bank_statement_lines IS 'Ø¨Ù†ÙˆØ¯ ÙƒØ´Ù Ø§Ù„Ø­Ø³Ø§Ø¨ Ø§Ù„Ø¨Ù†ÙƒÙŠ (Ø¥ÙŠØ¯Ø§Ø¹ Ù…ÙˆØ¬Ø¨ / Ø³Ø­Ø¨ Ø³Ø§Ù„Ø¨) Ù…Ø¹ Ø±Ø¨Ø· Ø§Ø®ØªÙŠØ§Ø±ÙŠ Ø¨Ù‚ÙŠØ¯ Ø¯ÙØªØ±';

CREATE INDEX IF NOT EXISTS idx_bank_statement_lines_recon ON public.bank_statement_lines (reconciliation_id);

ALTER TABLE public.bank_statement_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bank_statement_lines_select" ON public.bank_statement_lines;
CREATE POLICY "bank_statement_lines_select" ON public.bank_statement_lines
  FOR SELECT TO authenticated USING (
    is_pos_admin() OR EXISTS (
      SELECT 1 FROM public.bank_reconciliations r
      WHERE r.id = bank_statement_lines.reconciliation_id AND r.branch_id = get_branch_id()
    )
  );
DROP POLICY IF EXISTS "bank_statement_lines_insert" ON public.bank_statement_lines;
CREATE POLICY "bank_statement_lines_insert" ON public.bank_statement_lines
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "bank_statement_lines_update" ON public.bank_statement_lines;
CREATE POLICY "bank_statement_lines_update" ON public.bank_statement_lines
  FOR UPDATE TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

-- ---------------------------------------------------------------------
-- 3. create_bank_reconciliation
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_bank_reconciliation(
  p_branch_id uuid,
  p_treasury_account_id uuid,
  p_statement_date date,
  p_statement_balance numeric
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_account record;
  v_user_branch uuid;
  v_book numeric(14,2);
  v_diff numeric(14,2);
  v_recon_id uuid;
BEGIN
  BEGIN
    IF p_statement_balance IS NULL OR p_statement_date IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_INPUT');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Reconciliation requires the accountant or branch manager role.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    SELECT t.id, t.account_id, t.is_active INTO v_account
    FROM public.treasury_accounts t
    WHERE t.id = p_treasury_account_id AND t.branch_id = p_branch_id;
    IF v_account.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'TREASURY_ACCOUNT_NOT_FOUND');
    END IF;
    IF NOT v_account.is_active THEN
      RETURN jsonb_build_object('success', false, 'error', 'TREASURY_ACCOUNT_INACTIVE');
    END IF;

    -- Book balance of the underlying chart account up to the statement date
    SELECT COALESCE(SUM(jl.debit - jl.credit), 0)
    INTO v_book
    FROM public.journal_entry_lines jl
    JOIN public.journal_entries je ON je.id = jl.journal_entry_id
    WHERE jl.account_id = v_account.account_id
      AND je.branch_id = p_branch_id
      AND je.entry_date <= p_statement_date;

    v_book := round(v_book, 2);
    v_diff := round(p_statement_balance - v_book, 2);

    INSERT INTO public.bank_reconciliations (branch_id, treasury_account_id, statement_date,
      statement_balance, book_balance, difference, created_by)
    VALUES (p_branch_id, p_treasury_account_id, p_statement_date,
      round(p_statement_balance, 2), v_book, v_diff, auth.uid())
    RETURNING id INTO v_recon_id;

    RETURN jsonb_build_object('success', true, 'reconciliation_id', v_recon_id,
      'statement_date', p_statement_date, 'statement_balance', round(p_statement_balance, 2),
      'book_balance', v_book, 'difference', v_diff);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. add_statement_line
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_statement_line(
  p_reconciliation_id uuid,
  p_statement_date date,
  p_description text,
  p_amount numeric,
  p_reference text DEFAULT NULL::text
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_recon record;
  v_line_id uuid;
BEGIN
  BEGIN
    IF p_amount IS NULL OR p_amount = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_AMOUNT');
    END IF;

    SELECT id, branch_id, status INTO v_recon
    FROM public.bank_reconciliations WHERE id = p_reconciliation_id;
    IF v_recon.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_NOT_FOUND');
    END IF;
    IF v_recon.status <> 'open' THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_CLOSED', 'status', v_recon.status);
    END IF;

    INSERT INTO public.bank_statement_lines (reconciliation_id, statement_date, description, reference, amount)
    VALUES (p_reconciliation_id, p_statement_date, p_description, p_reference, round(p_amount, 2))
    RETURNING id INTO v_line_id;

    RETURN jsonb_build_object('success', true, 'line_id', v_line_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 5. match_bank_line
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.match_bank_line(
  p_line_id uuid,
  p_journal_entry_id uuid
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_line record;
  v_account uuid;
  v_matched boolean;
  v_entry_amount numeric(14,2);
  v_line_amount numeric(14,2);
BEGIN
  BEGIN
    SELECT l.id, l.reconciliation_id, l.amount, r.status, r.treasury_account_id
      INTO v_line
    FROM public.bank_statement_lines l
    JOIN public.bank_reconciliations r ON r.id = l.reconciliation_id
    WHERE l.id = p_line_id;
    IF v_line.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'LINE_NOT_FOUND');
    END IF;
    IF v_line.status <> 'open' THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_CLOSED');
    END IF;

    SELECT t.account_id INTO v_account
    FROM public.treasury_accounts t WHERE t.id = v_line.treasury_account_id;

    -- The journal entry must affect this bank account in the same branch
    SELECT EXISTS (
      SELECT 1 FROM public.journal_entry_lines jl
      JOIN public.journal_entries je ON je.id = jl.journal_entry_id
      WHERE jl.journal_entry_id = p_journal_entry_id
        AND jl.account_id = v_account
        AND je.branch_id = (SELECT branch_id FROM public.bank_reconciliations WHERE id = v_line.reconciliation_id)
    ) INTO v_matched;

    IF NOT v_matched THEN
      RETURN jsonb_build_object('success', false, 'error', 'ENTRY_NOT_ON_ACCOUNT',
        'detail', 'The journal entry does not post to this bank account in this branch.');
    END IF;

    -- The entry's net effect on the account must equal the statement line amount
    SELECT round(SUM(jl.debit - jl.credit), 2)
    INTO v_entry_amount
    FROM public.journal_entry_lines jl
    WHERE jl.journal_entry_id = p_journal_entry_id AND jl.account_id = v_account;

    v_line_amount := round(v_line.amount, 2);
    IF round(COALESCE(v_entry_amount, 0), 2) <> v_line_amount THEN
      RETURN jsonb_build_object('success', false, 'error', 'AMOUNT_MISMATCH',
        'entry_amount', round(COALESCE(v_entry_amount, 0), 2), 'statement_amount', v_line_amount,
        'detail', 'The journal entry effect on the bank account must equal the statement line amount.');
    END IF;

    UPDATE public.bank_statement_lines
      SET matched_journal_entry_id = p_journal_entry_id
      WHERE id = p_line_id;

    RETURN jsonb_build_object('success', true, 'line_id', p_line_id, 'journal_entry_id', p_journal_entry_id);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 6. complete_bank_reconciliation
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_bank_reconciliation(p_reconciliation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_recon record;
  v_total numeric(14,2);
  v_matched_total numeric(14,2);
  v_unmatched numeric(14,2);
BEGIN
  BEGIN
    SELECT id, branch_id, status, statement_balance, book_balance, difference
      INTO v_recon
    FROM public.bank_reconciliations WHERE id = p_reconciliation_id;
    IF v_recon.id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_NOT_FOUND');
    END IF;
    IF v_recon.status = 'completed' THEN
      RETURN jsonb_build_object('success', false, 'error', 'ALREADY_COMPLETED');
    END IF;
    IF v_recon.status = 'cancelled' THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_CANCELLED');
    END IF;

    SELECT COALESCE(SUM(amount), 0),
           COALESCE(SUM(CASE WHEN matched_journal_entry_id IS NOT NULL THEN amount ELSE 0 END), 0)
    INTO v_total, v_matched_total
    FROM public.bank_statement_lines WHERE reconciliation_id = p_reconciliation_id;

    v_total := round(v_total, 2);
    v_unmatched := round(COALESCE(v_recon.difference, 0) - v_total, 2);

    IF round(v_unmatched, 2) <> 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'RECON_OUT_OF_BALANCE',
        'difference', round(v_recon.difference, 2), 'statement_lines', v_total,
        'outstanding', v_unmatched,
        'detail', 'The statement lines must explain the full difference between the statement and book balances.');
    END IF;

    UPDATE public.bank_reconciliations
      SET status = 'completed', closed_at = now()
      WHERE id = p_reconciliation_id;

    RETURN jsonb_build_object('success', true, 'reconciliation_id', p_reconciliation_id,
      'difference', round(v_recon.difference, 2), 'statement_lines_total', v_total,
      'matched_total', round(v_matched_total, 2));
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 7. get_bank_reconciliation
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_bank_reconciliation(p_reconciliation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_header jsonb;
  v_lines jsonb;
  v_candidates jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', r.id, 'branch_id', r.branch_id, 'treasury_account_id', r.treasury_account_id,
    'statement_date', r.statement_date, 'statement_balance', r.statement_balance,
    'book_balance', r.book_balance, 'difference', r.difference, 'status', r.status,
    'closed_at', r.closed_at, 'account_name', t.account_name, 'code', a.code
  )
  INTO v_header
  FROM public.bank_reconciliations r
  JOIN public.treasury_accounts t ON t.id = r.treasury_account_id
  JOIN public.chart_of_accounts a ON a.id = t.account_id
  WHERE r.id = p_reconciliation_id;

  IF v_header IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'RECONCILIATION_NOT_FOUND');
  END IF;

  SELECT jsonb_agg(jsonb_build_object(
    'id', l.id, 'statement_date', l.statement_date, 'description', l.description,
    'reference', l.reference, 'amount', l.amount, 'matched_journal_entry_id', l.matched_journal_entry_id
  ) ORDER BY l.statement_date, l.id)
  INTO v_lines
  FROM public.bank_statement_lines l
  WHERE l.reconciliation_id = p_reconciliation_id;

  -- Book candidates: posted journal entries touching this bank account
  SELECT jsonb_agg(s.candidate ORDER BY s.candidate->>'entry_date', s.candidate->>'id')
  INTO v_candidates
  FROM (
    SELECT jsonb_build_object(
      'id', je.id, 'entry_number', je.entry_number, 'entry_date', je.entry_date,
      'reference_type', je.reference_type, 'reference_number', je.reference_number,
      'description', je.description,
      'amount', round(COALESCE(SUM(CASE WHEN jl.account_id = a.id THEN jl.debit - jl.credit ELSE 0 END), 0), 2)
    ) AS candidate
    FROM public.journal_entries je
    JOIN public.journal_entry_lines jl ON jl.journal_entry_id = je.id
    JOIN public.bank_reconciliations r ON r.id = p_reconciliation_id
    JOIN public.treasury_accounts t ON t.id = r.treasury_account_id
    JOIN public.chart_of_accounts a ON a.id = t.account_id
    WHERE je.branch_id = r.branch_id
      AND je.entry_date <= r.statement_date
      AND jl.account_id = a.id
    GROUP BY je.id, je.entry_number, je.entry_date, je.reference_type, je.reference_number, je.description
  ) s;

  RETURN jsonb_build_object('success', true, 'header', v_header,
    'statement_lines', COALESCE(v_lines, '[]'::jsonb), 'book_candidates', COALESCE(v_candidates, '[]'::jsonb));
END;
$function$;

-- ---------------------------------------------------------------------
-- Reload the PostgREST schema cache.
-- ---------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 024_d6_aging.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D6: Open AR/AP aging + journal listing with reference numbers
-- =====================================================================
-- Report surface for the credit-control and audit screens:
--   1. get_ap_aging          -> AP mirror of the existing get_ar_aging
--   2. get_open_invoices     -> invoice-level open AR / AP detail
--   3. get_aging_summary     -> single-row AR + AP totals per bucket
--   4. get_journals          -> posted journal entries with their lines,
--                               entry numbers and source references
-- All are read-only (STABLE, SECURITY DEFINER), branch-scoped, and rely
-- on the existing posted-ledger numbers (no double counting).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. AP aging: open payable per supplier in 30-day buckets
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_ap_aging(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.open_amount DESC), '[]'::jsonb)
FROM (
  SELECT s.id AS supplier_id, s.name, s.phone,
         sum(p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0)) AS open_amount,
         round(sum(CASE WHEN (p_as_of - p.created_at::date) <= 30 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_0_30,
         round(sum(CASE WHEN (p_as_of - p.created_at::date) BETWEEN 31 AND 60 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_31_60,
         round(sum(CASE WHEN (p_as_of - p.created_at::date) BETWEEN 61 AND 90 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_61_90,
         round(sum(CASE WHEN (p_as_of - p.created_at::date) > 90 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_90_plus
  FROM public.purchases p
  JOIN public.suppliers s ON s.id = p.supplier_id
  WHERE p.branch_id = p_branch_id AND p.status = 'completed'
    AND (p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0)) > 0
  GROUP BY s.id, s.name, s.phone
) row;
$function$;

COMMENT ON FUNCTION public.get_ap_aging(uuid, date) IS 'Ø°Ù…Ù… Ø¯Ø§Ø¦Ù†Ø© Ù…ÙØªÙˆØ­Ø© Ù„ÙƒÙ„ Ù…ÙˆØ±Ø¯ Ø­Ø³Ø¨ Ø§Ù„Ø¹Ù…Ø± Ø§Ù„Ø²Ù…Ù†ÙŠ';

-- ---------------------------------------------------------------------
-- 2. Open invoices: invoice-level AR / AP detail with overdue days
--    p_side = 'ar' -> sales invoices, 'ap' -> purchase invoices
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_open_invoices(
  p_branch_id uuid,
  p_side text DEFAULT 'ar',
  p_as_of date DEFAULT CURRENT_DATE
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT CASE
  WHEN COALESCE(p_side, 'ar') = 'ap' THEN (
    SELECT COALESCE(jsonb_agg(row ORDER BY row.invoice_date, row.invoice_number), '[]'::jsonb)
    FROM (
      SELECT p.id AS invoice_id, p.invoice_number, p.supplier_id AS party_id,
             sup.name AS party_name, sup.phone AS party_phone,
             p.created_at::date AS invoice_date,
             (p.created_at::date + 30) AS due_date,
             GREATEST(p_as_of - p.created_at::date, 0) AS days_overdue,
             round(p.total, 2) AS invoice_total,
             round(COALESCE(p.paid_amount, 0), 2) AS paid,
             round(COALESCE(p.returned_amount, 0), 2) AS returned,
             round(p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0), 2) AS open_amount
      FROM public.purchases p
      JOIN public.suppliers sup ON sup.id = p.supplier_id
      WHERE p.branch_id = p_branch_id AND p.status = 'completed'
        AND (p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0)) > 0
    ) row
  ) ELSE (
    SELECT COALESCE(jsonb_agg(row ORDER BY row.invoice_date, row.invoice_number), '[]'::jsonb)
    FROM (
      SELECT s.id AS invoice_id, s.invoice_number, s.customer_id AS party_id,
             c.name AS party_name, c.phone AS party_phone,
             s.created_at::date AS invoice_date,
             (s.created_at::date + 30) AS due_date,
             GREATEST(p_as_of - s.created_at::date, 0) AS days_overdue,
             round(s.total, 2) AS invoice_total,
             round(COALESCE(s.paid_amount, 0), 2) AS paid,
             round(COALESCE(s.refunded_amount, 0), 2) AS returned,
             round(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0), 2) AS open_amount
      FROM public.sales s
      JOIN public.customers c ON c.id = s.customer_id
      WHERE s.branch_id = p_branch_id AND s.status <> 'returned'
        AND (s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)) > 0
    ) row
  ) END;
$function$;

COMMENT ON FUNCTION public.get_open_invoices(uuid, text, date) IS 'ÙÙˆØ§ØªÙŠØ± Ù…ÙØªÙˆØ­Ø© Ø¨Ø§Ù„ØªÙØµÙŠÙ„ (AR Ø£Ùˆ AP) Ù…Ø¹ Ø£ÙŠØ§Ù… Ø§Ù„ØªØ£Ø®ÙŠØ±';

-- ---------------------------------------------------------------------
-- 3. Aging summary: single object with AR/AP totals per bucket
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_aging_summary(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH ar AS (
  SELECT
    round(sum(s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)), 2) AS open_total,
    round(sum(CASE WHEN (p_as_of - s.created_at::date) <= 30 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_0_30,
    round(sum(CASE WHEN (p_as_of - s.created_at::date) BETWEEN 31 AND 60 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_31_60,
    round(sum(CASE WHEN (p_as_of - s.created_at::date) BETWEEN 61 AND 90 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_61_90,
    round(sum(CASE WHEN (p_as_of - s.created_at::date) > 90 THEN s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0) ELSE 0 END), 2) AS bucket_90_plus
  FROM public.sales s
  WHERE s.branch_id = p_branch_id AND s.status <> 'returned'
    AND (s.total - COALESCE(s.paid_amount, 0) - COALESCE(s.refunded_amount, 0)) > 0
), ap AS (
  SELECT
    round(sum(p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0)), 2) AS open_total,
    round(sum(CASE WHEN (p_as_of - p.created_at::date) <= 30 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_0_30,
    round(sum(CASE WHEN (p_as_of - p.created_at::date) BETWEEN 31 AND 60 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_31_60,
    round(sum(CASE WHEN (p_as_of - p.created_at::date) BETWEEN 61 AND 90 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_61_90,
    round(sum(CASE WHEN (p_as_of - p.created_at::date) > 90 THEN p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0) ELSE 0 END), 2) AS bucket_90_plus
  FROM public.purchases p
  WHERE p.branch_id = p_branch_id AND p.status = 'completed'
    AND (p.total - COALESCE(p.paid_amount, 0) - COALESCE(p.returned_amount, 0)) > 0
)
SELECT jsonb_build_object(
  'as_of', p_as_of,
  'ar_open', round(COALESCE((SELECT open_total FROM ar), 0), 2),
  'ap_open', round(COALESCE((SELECT open_total FROM ap), 0), 2),
  'ar', jsonb_build_object('0_30', COALESCE((SELECT bucket_0_30 FROM ar), 0),
                           '31_60', COALESCE((SELECT bucket_31_60 FROM ar), 0),
                           '61_90', COALESCE((SELECT bucket_61_90 FROM ar), 0),
                           '90_plus', COALESCE((SELECT bucket_90_plus FROM ar), 0)),
  'ap', jsonb_build_object('0_30', COALESCE((SELECT bucket_0_30 FROM ap), 0),
                           '31_60', COALESCE((SELECT bucket_31_60 FROM ap), 0),
                           '61_90', COALESCE((SELECT bucket_61_90 FROM ap), 0),
                           '90_plus', COALESCE((SELECT bucket_90_plus FROM ap), 0))
);
$function$;

COMMENT ON FUNCTION public.get_aging_summary(uuid, date) IS 'Ù…Ù„Ø®Øµ Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø°Ù…Ù… Ø§Ù„Ù…Ø¯ÙŠÙ†Ø©/Ø§Ù„Ø¯Ø§Ø¦Ù†Ø© Ø­Ø³Ø¨ Ø§Ù„Ø¹Ù…Ø±';

-- ---------------------------------------------------------------------
-- 4. Journals: posted entries with lines, entry numbers and references
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_journals(
  p_branch_id uuid,
  p_from_date date DEFAULT NULL,
  p_to_date date DEFAULT NULL,
  p_reference_type text DEFAULT NULL,
  p_search text DEFAULT NULL
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(e ORDER BY e.entry_date, e.entry_number), '[]'::jsonb)
FROM (
  SELECT j.id, j.entry_number, j.entry_date, j.reference_type, j.reference_id,
         j.reference_number, j.description, j.created_at,
         round(COALESCE(SUM(l.debit), 0), 2) AS debit_total,
         round(COALESCE(SUM(l.credit), 0), 2) AS credit_total,
         (SELECT COALESCE(jsonb_agg(line ORDER BY line.id), '[]'::jsonb)
          FROM (
            SELECT l.id, a.code, a.name AS account_name, a.account_type,
                   round(l.debit, 2) AS debit, round(l.credit, 2) AS credit,
                   l.note, l.customer_id, l.supplier_id
            FROM public.journal_entry_lines l
            JOIN public.chart_of_accounts a ON a.id = l.account_id
            WHERE l.journal_entry_id = j.id
          ) line) AS lines
  FROM public.journal_entries j
  LEFT JOIN public.journal_entry_lines l ON l.journal_entry_id = j.id
  WHERE j.branch_id = p_branch_id
    AND (p_from_date IS NULL OR j.entry_date >= p_from_date)
    AND (p_to_date IS NULL OR j.entry_date <= p_to_date)
    AND (p_reference_type IS NULL OR j.reference_type = p_reference_type)
    AND (p_search IS NULL OR j.entry_number ILIKE '%' || p_search || '%'
                            OR j.reference_number ILIKE '%' || p_search || '%')
  GROUP BY j.id
) e;
$function$;

COMMENT ON FUNCTION public.get_journals(uuid, date, date, text, text) IS 'Ù‚Ø§Ø¦Ù…Ø© Ù‚ÙŠÙˆØ¯ Ø§Ù„ÙŠÙˆÙ…ÙŠØ© Ù…Ø¹ Ø§Ù„Ø£Ø±Ù‚Ø§Ù… ÙˆØ§Ù„Ù…Ø±Ø§Ø¬Ø¹';

-- ---------------------------------------------------------------------
-- 5. Journal detail: one entry with its lines (for the entry screen)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_journal_entry(p_journal_entry_id uuid)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT jsonb_build_object(
  'entry', jsonb_build_object(
    'id', j.id, 'entry_number', j.entry_number, 'entry_date', j.entry_date,
    'reference_type', j.reference_type, 'reference_id', j.reference_id,
    'reference_number', j.reference_number, 'description', j.description,
    'created_at', j.created_at, 'created_by', j.created_by
  ),
  'lines', (SELECT COALESCE(jsonb_agg(line ORDER BY line.id), '[]'::jsonb)
            FROM (
              SELECT l.id, a.id AS account_id, a.code, a.name AS account_name,
                     a.account_type, round(l.debit, 2) AS debit, round(l.credit, 2) AS credit,
                     l.note, l.customer_id, l.supplier_id
              FROM public.journal_entry_lines l
              JOIN public.chart_of_accounts a ON a.id = l.account_id
              WHERE l.journal_entry_id = j.id
            ) line)
)
FROM public.journal_entries j
WHERE j.id = p_journal_entry_id;
$function$;

COMMENT ON FUNCTION public.get_journal_entry(uuid) IS 'ØªÙØ§ØµÙŠÙ„ Ù‚ÙŠØ¯ ÙŠÙˆÙ…ÙŠØ© ÙˆØ§Ø­Ø¯ Ù…Ø¹ Ø£Ø·Ø±Ø§ÙÙ‡';



-- ----------------------------------------------------------------------------
-- MIGRATION: 025_d7_trial_balance.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D7: Trial balance hardening + balance sheet fix
-- =====================================================================
-- Two fixes to the Phase C report functions:
--   1. get_trial_balance / get_balance_sheet joined journal_entry_lines
--      to journal_entries with the branch/date filter inside the LEFT JOIN
--      condition. Lines belonging to other branches' entries were therefore
--      still summed (the join produced a NULL journal but kept the line).
--      Both are rewritten to filter lines through their entries first.
--   2. get_trial_balance keeps its existing array shape (used by the
--      frontend) and a new get_trial_balance_summary adds totals and a
--      balanced flag.
-- All functions stay read-only, STABLE, SECURITY DEFINER.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Trial balance (array shape preserved; branch filter hardened)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_trial_balance(p_branch_id uuid, p_to_date date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.code), '[]'::jsonb)
FROM (
  SELECT a.code, a.name, a.name_en, a.account_type,
         round(COALESCE(SUM(l.debit), 0), 2) AS debit,
         round(COALESCE(SUM(l.credit), 0), 2) AS credit,
         round(COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0), 2) AS balance
  FROM public.chart_of_accounts a
  LEFT JOIN (
    SELECT l.account_id, l.debit, l.credit
    FROM public.journal_entry_lines l
    JOIN public.journal_entries j ON j.id = l.journal_entry_id
    WHERE j.branch_id = p_branch_id AND j.entry_date <= p_to_date
  ) l ON l.account_id = a.id
  WHERE a.branch_id = p_branch_id AND a.is_active
  GROUP BY a.code, a.name, a.name_en, a.account_type
  HAVING COALESCE(SUM(l.debit), 0) <> 0 OR COALESCE(SUM(l.credit), 0) <> 0
) row;
$function$;

COMMENT ON FUNCTION public.get_trial_balance(uuid, date) IS 'Ù…ÙŠØ²Ø§Ù† Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© (ÙƒÙ„ Ø­Ø³Ø§Ø¨ Ù…Ø¹ Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ù…Ø¯ÙŠÙ†/Ø¯Ø§Ø¦Ù† ÙˆØ§Ù„Ø±ØµÙŠØ¯)';

-- ---------------------------------------------------------------------
-- 2. Trial balance summary: totals + balanced flag
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_trial_balance_summary(p_branch_id uuid, p_to_date date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH rows AS (
  SELECT COALESCE(SUM(l.debit), 0) AS debit, COALESCE(SUM(l.credit), 0) AS credit
  FROM public.chart_of_accounts a
  LEFT JOIN (
    SELECT l.account_id, l.debit, l.credit
    FROM public.journal_entry_lines l
    JOIN public.journal_entries j ON j.id = l.journal_entry_id
    WHERE j.branch_id = p_branch_id AND j.entry_date <= p_to_date
  ) l ON l.account_id = a.id
  WHERE a.branch_id = p_branch_id AND a.is_active
    AND (COALESCE(l.debit, 0) <> 0 OR COALESCE(l.credit, 0) <> 0)
)
SELECT jsonb_build_object(
  'to_date', p_to_date,
  'total_debit', round(COALESCE((SELECT SUM(debit) FROM rows), 0), 2),
  'total_credit', round(COALESCE((SELECT SUM(credit) FROM rows), 0), 2),
  'balanced', round(COALESCE((SELECT SUM(debit) FROM rows), 0), 2)
              = round(COALESCE((SELECT SUM(credit) FROM rows), 0), 2)
);
$function$;

COMMENT ON FUNCTION public.get_trial_balance_summary(uuid, date) IS 'Ù…Ù„Ø®Øµ Ù…ÙŠØ²Ø§Ù† Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø© (Ø¥Ø¬Ù…Ø§Ù„ÙŠØ§Øª ÙˆØ¹Ù„Ø§Ù…Ø© Ø§Ù„ØªÙˆØ§Ø²Ù†)';

-- ---------------------------------------------------------------------
-- 3. Balance sheet (branch filter hardened)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_balance_sheet(p_branch_id uuid, p_as_of date DEFAULT CURRENT_DATE)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH bal AS (
  SELECT a.account_type, a.code,
         COALESCE(SUM(l.debit), 0) AS debit,
         COALESCE(SUM(l.credit), 0) AS credit
  FROM public.chart_of_accounts a
  LEFT JOIN (
    SELECT l.account_id, l.debit, l.credit
    FROM public.journal_entry_lines l
    JOIN public.journal_entries j ON j.id = l.journal_entry_id
    WHERE j.branch_id = p_branch_id AND j.entry_date <= p_as_of
  ) l ON l.account_id = a.id
  WHERE a.branch_id = p_branch_id AND a.is_active
  GROUP BY a.account_type, a.code
), summary AS (
  SELECT
    round(COALESCE(SUM(CASE WHEN account_type = 'asset' THEN debit - credit ELSE 0 END), 0), 2) AS assets,
    round(COALESCE(SUM(CASE WHEN account_type = 'liability' THEN credit - debit ELSE 0 END), 0), 2) AS liabilities,
    round(COALESCE(SUM(CASE WHEN code = '3000' THEN credit - debit ELSE 0 END), 0), 2) AS capital,
    round(COALESCE(SUM(CASE WHEN code = '3100' THEN credit - debit ELSE 0 END), 0), 2) AS retained,
    round(COALESCE(SUM(CASE WHEN account_type = 'income' THEN credit - debit ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN account_type = 'expense' THEN debit - credit ELSE 0 END), 0), 2) AS net_income
  FROM bal
)
SELECT jsonb_build_object(
  'assets', assets,
  'liabilities', liabilities,
  'capital', capital,
  'retained', retained,
  'net_income', net_income,
  'equity', round(capital + retained + net_income, 2),
  'balanced', round(assets - (liabilities + capital + retained + net_income), 2) = 0
)
FROM summary;
$function$;

COMMENT ON FUNCTION public.get_balance_sheet(uuid, date) IS 'Ø§Ù„Ù…ÙŠØ²Ø§Ù†ÙŠØ© Ø§Ù„Ø¹Ù…ÙˆÙ…ÙŠØ© ÙÙŠ ØªØ§Ø±ÙŠØ® Ù…Ø­Ø¯Ø¯';



-- ----------------------------------------------------------------------------
-- MIGRATION: 026_d8_audit.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D8: Audit trail + manual journal entry
-- =====================================================================
-- Accounting audit trail on top of the existing branch-scoped audit_log:
--   1. log_audit_action     -> generic, secure insert into audit_log
--   2. _post_journal_entry  -> now also records a 'journal_post' entry for
--                              every posted journal (one hook, all postings)
--   3. post_manual_journal  -> manual/adjustment entries (accountant+) that
--                              go through _post_journal_entry and are audited
--   4. get_audit_trail      -> filterable read of the accounting trail
-- No RLS is weakened; audit writes happen inside SECURITY DEFINER RPCs that
-- already enforce role/branch authorization.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. log_audit_action helper
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_audit_action(
  p_branch_id uuid,
  p_action text,
  p_entity text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL,
  p_details jsonb DEFAULT NULL
) RETURNS uuid
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.audit_log (user_id, user_email, branch_id, action, entity, entity_id, details)
  VALUES (
    auth.uid(),
    (SELECT email FROM public.users WHERE id = auth.uid()),
    p_branch_id,
    p_action, p_entity, p_entity_id, p_details
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$function$;

-- ---------------------------------------------------------------------
-- 2. _post_journal_entry: same behaviour + audit record on new postings
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._post_journal_entry(
  p_branch_id uuid,
  p_reference_type text,
  p_reference_id uuid,
  p_reference_number text,
  p_description text,
  p_lines jsonb
) RETURNS uuid
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_entry_id uuid;
  v_entry_no text;
  v_line jsonb;
  v_account uuid;
  v_debit numeric(14,2);
  v_credit numeric(14,2);
  v_total_debit numeric(14,2) := 0;
  v_total_credit numeric(14,2) := 0;
BEGIN
  IF p_lines IS NULL OR jsonb_array_length(p_lines) = 0 THEN
    RAISE EXCEPTION 'JOURNAL_EMPTY_LINES';
  END IF;

  -- Idempotency: never post a second entry for the same reference.
  IF p_reference_id IS NOT NULL THEN
    SELECT id INTO v_entry_id
    FROM public.journal_entries
    WHERE reference_type = p_reference_type AND reference_id = p_reference_id;
    IF v_entry_id IS NOT NULL THEN
      RETURN v_entry_id;
    END IF;
  END IF;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::numeric, 0);
    v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::numeric, 0);
  END LOOP;

  IF round(v_total_debit, 2) <> round(v_total_credit, 2) THEN
    RAISE EXCEPTION 'JOURNAL_UNBALANCED: debit % <> credit %',
      round(v_total_debit, 2), round(v_total_credit, 2);
  END IF;

  v_entry_no := (public.next_document_number('journal')->>'number')::text;

  INSERT INTO public.journal_entries
    (entry_number, branch_id, entry_date, reference_type, reference_id, reference_number, description, created_by)
  VALUES (v_entry_no, p_branch_id, CURRENT_DATE, p_reference_type, p_reference_id,
          p_reference_number, p_description, auth.uid())
  RETURNING id INTO v_entry_id;

  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    v_debit := COALESCE((v_line->>'debit')::numeric, 0);
    v_credit := COALESCE((v_line->>'credit')::numeric, 0);
    IF v_debit <= 0 AND v_credit <= 0 THEN CONTINUE; END IF;

    IF v_line ? 'account_key' THEN
      v_account := public.resolve_account_key(p_branch_id, v_line->>'account_key', v_line->>'account_code');
    ELSE
      SELECT id INTO v_account
      FROM public.chart_of_accounts
      WHERE branch_id = p_branch_id AND code = upper(btrim((v_line->>'account_code')::text));
    END IF;
    IF v_account IS NULL THEN
      RAISE EXCEPTION 'ACCOUNT_NOT_FOUND: %', COALESCE(v_line->>'account_key', v_line->>'account_code');
    END IF;

    INSERT INTO public.journal_entry_lines
      (journal_entry_id, account_id, debit, credit, customer_id, supplier_id, note)
    VALUES (v_entry_id, v_account, v_debit, v_credit,
            (v_line->>'customer_id')::uuid, (v_line->>'supplier_id')::uuid, v_line->>'note');
  END LOOP;

  PERFORM public.log_audit_action(p_branch_id, 'journal_post', 'journal_entry', v_entry_id,
    jsonb_build_object('entry_number', v_entry_no, 'reference_type', p_reference_type,
                       'reference_number', p_reference_number,
                       'debit_total', round(v_total_debit, 2), 'credit_total', round(v_total_credit, 2)));

  RETURN v_entry_id;
END;
$function$;

-- ---------------------------------------------------------------------
-- 3. post_manual_journal: accountant + manual adjustment entries
--    p_lines = [{"account_key"|"account_code", "debit", "credit",
--                 "note", "customer_id", "supplier_id"}]
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.post_manual_journal(
  p_branch_id uuid,
  p_description text,
  p_lines jsonb
) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_user_branch uuid;
  v_entry_id uuid;
  v_line jsonb;
  v_debit numeric(14,2) := 0;
  v_credit numeric(14,2) := 0;
BEGIN
  BEGIN
    IF p_branch_id IS NULL OR p_lines IS NULL OR jsonb_array_length(p_lines) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_INPUT',
        'detail', 'Branch and at least one line are required.');
    END IF;

    IF NOT is_pos_admin() AND get_user_role() NOT IN ('accountant', 'branch_manager') THEN
      RETURN jsonb_build_object('success', false, 'error', 'NOT_ALLOWED',
        'detail', 'Manual journal entries require the accountant or branch manager role.');
    END IF;

    IF NOT is_pos_admin() THEN
      SELECT branch_id INTO v_user_branch FROM users WHERE id = auth.uid();
      IF v_user_branch IS NOT NULL AND p_branch_id <> v_user_branch THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
    LOOP
      v_debit := v_debit + COALESCE((v_line->>'debit')::numeric, 0);
      v_credit := v_credit + COALESCE((v_line->>'credit')::numeric, 0);
    END LOOP;
    IF round(v_debit, 2) <> round(v_credit, 2) THEN
      RETURN jsonb_build_object('success', false, 'error', 'JOURNAL_UNBALANCED',
        'debit', round(v_debit, 2), 'credit', round(v_credit, 2));
    END IF;

    -- Manual entries are distinct actions: a fresh reference id per posting.
    v_entry_id := public._post_journal_entry(p_branch_id, 'manual', gen_random_uuid(), NULL,
      p_description, p_lines);

    PERFORM public.log_audit_action(p_branch_id, 'manual_journal', 'journal_entry', v_entry_id,
      jsonb_build_object('description', p_description, 'lines', p_lines));

    RETURN jsonb_build_object('success', true, 'entry_id', v_entry_id,
      'entry_number', (SELECT entry_number FROM public.journal_entries WHERE id = v_entry_id));
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------
-- 4. get_audit_trail: filterable audit reads for the branch
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_audit_trail(
  p_branch_id uuid,
  p_action text DEFAULT NULL,
  p_entity text DEFAULT NULL,
  p_from_date date DEFAULT NULL,
  p_to_date date DEFAULT NULL,
  p_limit integer DEFAULT 200
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.created_at DESC), '[]'::jsonb)
FROM (
  SELECT a.id, a.created_at, a.action, a.entity, a.entity_id, a.details,
         a.branch_id, a.user_id, u.full_name AS user_name,
         COALESCE(a.user_email, u.email) AS user_email
  FROM public.audit_log a
  LEFT JOIN public.users u ON u.id = a.user_id
  WHERE a.branch_id = p_branch_id
    AND (p_action IS NULL OR a.action = p_action)
    AND (p_entity IS NULL OR a.entity = p_entity)
    AND (p_from_date IS NULL OR a.created_at::date >= p_from_date)
    AND (p_to_date IS NULL OR a.created_at::date <= p_to_date)
  ORDER BY a.created_at DESC
  LIMIT p_limit
) row;
$function$;

COMMENT ON FUNCTION public.log_audit_action(uuid, text, text, uuid, jsonb) IS 'ØªØ³Ø¬ÙŠÙ„ Ø­Ø¯Ø« ÙÙŠ Ø³Ø¬Ù„ Ø§Ù„ØªØ¯Ù‚ÙŠÙ‚';
COMMENT ON FUNCTION public.get_audit_trail(uuid, text, text, date, date, integer) IS 'Ù‚Ø±Ø§Ø¡Ø© Ø³Ø¬Ù„ Ø§Ù„ØªØ¯Ù‚ÙŠÙ‚ Ù…Ø¹ Ø§Ù„ÙÙ„Ø§ØªØ±';



-- ----------------------------------------------------------------------------
-- MIGRATION: 027_d9_reporting.sql
-- ----------------------------------------------------------------------------

-- =====================================================================
-- Phase D9: Report queries + schema hardening
-- =====================================================================
-- 1. Missing report indexes (all idempotent CREATE INDEX IF NOT EXISTS)
-- 2. get_cash_flow      -> treasury inflow / outflow / net per account
-- 3. get_party_statement-> chronological AR / AP statement per party with
--                          opening balance and running balance
-- No RLS changes; the new functions are read-only STABLE helpers.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Indexes used by the aging / statement / ledger report queries
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_purchases_branch_created ON public.purchases (branch_id, created_at);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON public.sales (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_branch_created ON public.sales (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_payments_branch ON public.customer_payments (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_supplier_payments_branch ON public.supplier_payments (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bank_reconciliations_branch ON public.bank_reconciliations (branch_id, status);
CREATE INDEX IF NOT EXISTS idx_bank_statement_lines_recon ON public.bank_statement_lines (reconciliation_id);
CREATE INDEX IF NOT EXISTS idx_expenses_branch_date ON public.expenses (branch_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_journal_lines_party ON public.journal_entry_lines (customer_id, created_at);
CREATE INDEX IF NOT EXISTS idx_journal_lines_supplier ON public.journal_entry_lines (supplier_id, created_at);

-- ---------------------------------------------------------------------
-- 2. Cash flow: treasury movements per account for a period
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_cash_flow(
  p_branch_id uuid,
  p_from_date date,
  p_to_date date DEFAULT CURRENT_DATE
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
SELECT COALESCE(jsonb_agg(row ORDER BY row.account_name), '[]'::jsonb)
FROM (
  SELECT t.id AS treasury_account_id, t.account_name, t.account_type, a.code,
         round(COALESCE(SUM(CASE WHEN tx.to_account_id = t.id THEN tx.amount ELSE 0 END), 0), 2) AS inflow,
         round(COALESCE(SUM(CASE WHEN tx.from_account_id = t.id THEN tx.amount ELSE 0 END), 0), 2) AS outflow,
         round(COALESCE(SUM(CASE WHEN tx.to_account_id = t.id THEN tx.amount ELSE -tx.amount END), 0), 2) AS net
  FROM public.treasury_accounts t
  JOIN public.chart_of_accounts a ON a.id = t.account_id
  LEFT JOIN public.treasury_transactions tx
    ON (tx.to_account_id = t.id OR tx.from_account_id = t.id)
   AND tx.branch_id = p_branch_id
   AND tx.created_at::date >= p_from_date AND tx.created_at::date <= p_to_date
  WHERE t.branch_id = p_branch_id AND t.is_active
  GROUP BY t.id, t.account_name, t.account_type, a.code
  HAVING COALESCE(SUM(CASE WHEN tx.to_account_id = t.id THEN tx.amount ELSE -tx.amount END), 0) <> 0
) row;
$function$;

COMMENT ON FUNCTION public.get_cash_flow(uuid, date, date) IS 'Ø§Ù„ØªØ¯ÙÙ‚Ø§Øª Ø§Ù„Ù†Ù‚Ø¯ÙŠØ© (Ø¯Ø§Ø®Ù„/Ø®Ø§Ø±Ø¬/ØµØ§ÙÙŠ) Ù„ÙƒÙ„ Ø­Ø³Ø§Ø¨ Ø®Ø²ÙŠÙ†Ø©';

-- ---------------------------------------------------------------------
-- 3. Party statement: chronological AR ('ar') / AP ('ap') movements with
--    opening balance and running balance from the posted ledger
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_party_statement(
  p_branch_id uuid,
  p_side text,
  p_party_id uuid,
  p_from_date date DEFAULT NULL,
  p_to_date date DEFAULT NULL
) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public' STABLE AS $function$
WITH lines AS (
  SELECT jl.id AS line_id, jl.debit, jl.credit, j.entry_date, j.entry_number,
         j.reference_type, j.reference_number, j.description
  FROM public.journal_entry_lines jl
  JOIN public.journal_entries j ON j.id = jl.journal_entry_id
  WHERE j.branch_id = p_branch_id
    AND (CASE WHEN p_side = 'ap' THEN jl.supplier_id ELSE jl.customer_id END) = p_party_id
    AND (p_to_date IS NULL OR j.entry_date <= p_to_date)
), run AS (
  SELECT line_id, entry_date, entry_number, reference_type, reference_number, description,
         round(debit, 2) AS debit, round(credit, 2) AS credit,
         round(SUM(CASE WHEN p_side = 'ap' THEN credit - debit ELSE debit - credit END)
               OVER (ORDER BY entry_date, entry_number, line_id), 2) AS balance
  FROM lines
)
SELECT jsonb_build_object(
  'party_id', p_party_id, 'side', p_side,
  'opening', round(COALESCE((SELECT SUM(CASE WHEN p_side = 'ap' THEN credit - debit ELSE debit - credit END)
                             FROM lines WHERE p_from_date IS NOT NULL AND entry_date < p_from_date), 0), 2),
  'rows', (SELECT COALESCE(jsonb_agg(r ORDER BY r.entry_date, r.entry_number), '[]'::jsonb)
           FROM (SELECT line_id, entry_date, entry_number, reference_type, reference_number,
                        description, debit, credit, balance
                 FROM run WHERE p_from_date IS NULL OR entry_date >= p_from_date) r)
);
$function$;

COMMENT ON FUNCTION public.get_party_statement(uuid, text, uuid, date, date) IS 'ÙƒØ´Ù Ø­Ø³Ø§Ø¨ Ø¹Ù…ÙŠÙ„/Ù…ÙˆØ±Ø¯ Ù…Ø¹ Ø§Ù„Ø±ØµÙŠØ¯ Ø§Ù„Ø§ÙØªØªØ§Ø­ÙŠ ÙˆØ§Ù„Ø¬Ø§Ø±ÙŠ';



-- ----------------------------------------------------------------------------
-- MIGRATION: 028_d10_security.sql
-- ----------------------------------------------------------------------------

-- Migration: D10 Security hardening
-- Fixes found in the full system audit:
--   1. Privilege escalation: users UPDATE/INSERT policies let any branch
--      manager (or staff) promote ANY account in their branch to
--      super_admin/owner by editing public.users directly (the UsersPage uses
--      a direct table update, and RLS only scopes to the branch, not the
--      role value). Confirmed live.
--   2. trg_protect_last_admin was defined but never attached to users in the
--      live database, so "the last admin cannot be removed" was NOT enforced.
--   3. document_sequences has RLS disabled -> anon/authenticated could read
--      the counters directly via PostgREST.

-- ================================================================
-- 1. guard_user_role_changes: DB-level guard on public.users
--    Enforces (independent of RLS, since RLS cannot inspect NEW values):
--     - Only active super_admin/owner can create or modify admin accounts.
--     - No user may change their OWN role / branch_id / is_active unless
--       they are an admin.
--     - Branch managers can only create/update staff of their own branch.
-- ================================================================
CREATE OR REPLACE FUNCTION public.guard_user_role_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
DECLARE
  v_caller_role text;
  v_caller_branch uuid;
BEGIN
  SELECT role, branch_id INTO v_caller_role, v_caller_branch
  FROM public.users WHERE id = auth.uid();

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  -- Only admins may create or modify admin accounts.
  IF NEW.role IN ('super_admin', 'owner') AND v_caller_role NOT IN ('super_admin', 'owner') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only an admin can assign admin roles';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Only admins may modify existing admin accounts.
    IF OLD.role IN ('super_admin', 'owner') AND v_caller_role NOT IN ('super_admin', 'owner') THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: only an admin can modify admin accounts';
    END IF;

    -- No self-demotion / self-deactivation / self-branch-change for non-admins.
    IF NEW.id = auth.uid() AND v_caller_role NOT IN ('super_admin', 'owner') THEN
      IF NEW.role IS DISTINCT FROM OLD.role
         OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
         OR NEW.is_active IS DISTINCT FROM OLD.is_active THEN
        RAISE EXCEPTION 'PERMISSION_DENIED: users cannot change their own role/branch/status';
      END IF;
    END IF;
  END IF;

  -- Branch managers may only manage staff of their own branch.
  IF v_caller_role = 'branch_manager' THEN
    IF NEW.branch_id IS DISTINCT FROM v_caller_branch THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: branch managers can only manage their own branch';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_users_role_guard ON public.users;
CREATE TRIGGER trg_users_role_guard
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.guard_user_role_changes();

-- ================================================================
-- 2. protect_last_admin: fix the live definition (it still checked the
--    legacy role 'admin' instead of 'super_admin'/'owner', so the last-admin
--    protection was a silent no-op) and (re-)attach the trigger, which was
--    missing from the live database entirely.
-- ================================================================
CREATE OR REPLACE FUNCTION public.protect_last_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_other_active_admins int;
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.role IN ('super_admin', 'owner') AND OLD.is_active THEN
      SELECT count(*) INTO v_other_active_admins
      FROM public.users
      WHERE role IN ('super_admin', 'owner') AND is_active AND id <> OLD.id;
      IF v_other_active_admins = 0 THEN
        RAISE EXCEPTION 'LAST_ADMIN';
      END IF;
    END IF;
    RETURN OLD;
  END IF;

  IF OLD.role IN ('super_admin', 'owner') AND OLD.is_active
     AND (NEW.role NOT IN ('super_admin', 'owner') OR NOT NEW.is_active) THEN
    SELECT count(*) INTO v_other_active_admins
    FROM public.users
    WHERE role IN ('super_admin', 'owner') AND is_active AND id <> OLD.id;
    IF v_other_active_admins = 0 THEN
      RAISE EXCEPTION 'LAST_ADMIN';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_protect_last_admin ON public.users;
CREATE TRIGGER trg_protect_last_admin
BEFORE UPDATE OR DELETE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.protect_last_admin();

-- ================================================================
-- 3. Lock down document_sequences: RLS on, authenticated read-only.
--    Writes happen exclusively through SECURITY DEFINER RPCs which run as
--    the table owner and bypass RLS, so nothing else is affected.
-- ================================================================
ALTER TABLE public.document_sequences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS document_sequences_select ON public.document_sequences;
CREATE POLICY document_sequences_select ON public.document_sequences
  FOR SELECT TO authenticated USING (true);

-- Reject any direct write attempt from the client (there is no policy for
-- INSERT/UPDATE/DELETE, and anon gets nothing).
REVOKE INSERT, UPDATE, DELETE ON public.document_sequences FROM anon, authenticated;
GRANT SELECT ON public.document_sequences TO authenticated;

NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 029_d11_report_rls.sql
-- ----------------------------------------------------------------------------

-- Migration: D11 Reporting-RPC security hardening
-- Confirmed live during the full system audit:
--   1. Every public function granted EXECUTE to PUBLIC + anon. Because the
--      reporting functions are SECURITY DEFINER, any caller (including an
--      unauthenticated request using the public anon key, and any user of any
--      branch) could read ANY branch's financial data by passing an arbitrary
--      p_branch_id. Proven live: anon and a BRANCH_B cashier both retrieved
--      BRANCH_A journals / trial balance.
--   2. The read-only reporting functions also bypass RLS, so passing another
--      branch's id leaked that branch's rows regardless of the caller.

-- ================================================================
-- 1. Restrict EXECUTE to authenticated/service_role only.
--    anon keeps exactly one function: get_login_email (the PIN-login flow
--    resolves username -> email before the user authenticates).
-- ================================================================
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prokind = 'f'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.sig);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', r.sig);
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.get_login_email(text) TO anon;

-- ================================================================
-- 2. Convert the read-only reporting functions to SECURITY INVOKER.
--    They then run under the caller's grants + RLS, so branch isolation is
--    enforced by the policies themselves regardless of the p_branch_id that
--    the client passes (a user can only ever see their own branch; admins
--    still see everything).
-- ================================================================
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prokind = 'f'
      AND p.proname IN (
        'get_journals', 'get_journal_entry', 'get_general_ledger',
        'get_income_statement', 'get_balance_sheet', 'get_trial_balance',
        'get_trial_balance_summary', 'get_cash_flow', 'get_aging_summary',
        'get_ar_aging', 'get_ap_aging', 'get_open_invoices',
        'get_party_statement', 'get_treasury_balances',
        'get_bank_reconciliation', 'get_audit_trail'
      )
  LOOP
    EXECUTE format('ALTER FUNCTION %s SECURITY INVOKER', r.sig);
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';



-- ----------------------------------------------------------------------------
-- MIGRATION: 030_d12_perf_indexes.sql
-- ----------------------------------------------------------------------------

-- Migration: D12 Performance - index coverage
-- Audit finding: several FK / filter columns used by common join and report
-- queries had no index (seq scans as data grows). The only exact-duplicate
-- index (idx_journal_reference, a non-unique copy of uq_journal_reference)
-- is dropped to save write overhead.

DROP INDEX IF EXISTS public.idx_journal_reference;

CREATE INDEX IF NOT EXISTS idx_sale_items_product              ON public.sale_items (product_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_product          ON public.purchase_items (product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_batches_branch        ON public.inventory_batches (branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_branch_date           ON public.audit_log (branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_user                  ON public.audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_bank_statement_lines_matched    ON public.bank_statement_lines (matched_journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_treasury_transactions_from      ON public.treasury_transactions (from_account_id);
CREATE INDEX IF NOT EXISTS idx_treasury_transactions_to        ON public.treasury_transactions (to_account_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_product        ON public.inventory_ledger (product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_ledger_raw            ON public.inventory_ledger (raw_material_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_transfer_items_product ON public.warehouse_transfer_items (product_id);
CREATE INDEX IF NOT EXISTS idx_production_waste_product        ON public.production_waste (product_id);



-- ----------------------------------------------------------------------------
-- MIGRATION: 031_process_sale_pricing.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- D13. Hardening fix: authoritative pricing in process_sale
-- ----------------------------------------------------------------------------
-- The live D1 version trusted client-supplied unit_price / totals, so a
-- tampered payload could book a sale at any price. This migration replaces
-- process_sale with the SAME live implementation (inventory_batches +
-- _product_inv_remove_fifo + products.branch_id model) but recomputes every
-- money figure server-side:
--
--   * unit_price  <- products.sale_price (authoritative catalog price)
--   * item total  <- qty * unit_price - discount (discount clamped)
--   * header      <- subtotal / discount / tax (from settings) / total recomputed
--   * paid        <- clamped >= 0, AR = total - paid
--
-- The frontend already sends product.sale_price and the same formulas, so
-- honest clients see identical numbers; only forged prices are rejected.
-- Additive-only: CREATE OR REPLACE FUNCTION, no data/DDL destructive changes.
-- ============================================================================

-- The inventory_v2-era overload (without p_shift_id) is superseded: the
-- frontend always passes p_shift_id and no code calls the old signature.
-- Keeping it would make every 15-argument call ambiguous, so it is dropped.
DROP FUNCTION IF EXISTS public.process_sale(text, uuid, uuid, uuid, uuid, numeric, numeric, text, numeric, numeric, numeric, numeric, text, text, jsonb);

CREATE OR REPLACE FUNCTION public.process_sale(p_invoice_number text, p_branch_id uuid, p_warehouse_id uuid, p_customer_id uuid, p_salesperson_id uuid, p_subtotal numeric, p_discount_amount numeric, p_discount_type text, p_tax_amount numeric, p_bonus_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_items jsonb, p_shift_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_warehouse_ids uuid[];
  v_available numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cogs_total numeric(14,2) := 0;
  v_subtotal numeric(14,2) := 0;
  v_discount numeric(14,2);
  v_tax numeric(14,2) := 0;
  v_tax_enabled boolean;
  v_tax_rate numeric(14,2);
  v_total numeric(14,2);
  v_paid numeric(14,2);
  v_ar numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
  v_balance_account text;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      -- Branch ownership: the product must belong to the sale branch
      IF NOT EXISTS (
        SELECT 1 FROM products WHERE id = v_product_id AND branch_id = p_branch_id
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH',
          'product_id', v_product_id, 'branch_id', p_branch_id);
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_available
      FROM inventory_batches
      WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
      IF v_available < v_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
      END IF;

      -- Accumulate the authoritative subtotal (catalog price, clamped discount)
      SELECT COALESCE(sale_price, 0) INTO v_unit_price FROM products WHERE id = v_product_id;
      v_discount_amount := GREATEST(COALESCE((v_item->>'discount_amount')::numeric, 0), 0);
      IF v_discount_amount > v_quantity * v_unit_price THEN
        v_discount_amount := v_quantity * v_unit_price;
      END IF;
      v_subtotal := v_subtotal + ROUND(v_quantity * v_unit_price - v_discount_amount, 2);
    END LOOP;

    -- ===== SERVER-SIDE HEADER TOTALS (computed from authoritative prices) =====
    v_discount := GREATEST(COALESCE(p_discount_amount, 0), 0);
    IF v_discount > v_subtotal THEN v_discount := v_subtotal; END IF;
    SELECT COALESCE(tax_enabled, false), COALESCE(tax_rate, 0) INTO v_tax_enabled, v_tax_rate
    FROM public.settings LIMIT 1;
    IF v_tax_enabled THEN
      v_tax := ROUND((v_subtotal - v_discount) * v_tax_rate / 100, 2);
    END IF;
    v_total := ROUND(v_subtotal - v_discount + v_tax, 2);
    v_paid := ROUND(GREATEST(COALESCE(p_paid_amount, 0), 0), 2);
    v_ar := ROUND(GREATEST(v_total - v_paid, 0), 2);

    -- ===== WRITE PHASE 1: sale header (authoritative totals) =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      v_subtotal, v_discount, p_discount_type, v_tax, COALESCE(p_bonus_amount, 0),
      v_total, v_paid, p_payment_method, p_status)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + FIFO stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_discount_amount := GREATEST(COALESCE((v_item->>'discount_amount')::numeric, 0), 0);

      SELECT sale_price INTO v_unit_price FROM products WHERE id = v_product_id;
      v_unit_price := COALESCE(v_unit_price, 0);
      IF v_discount_amount > v_quantity * v_unit_price THEN
        v_discount_amount := v_quantity * v_unit_price;
      END IF;
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := ROUND(v_quantity * v_unit_price - v_discount_amount, 2);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      v_res := public._product_inv_remove_fifo(v_product_id, NULL, p_branch_id, v_quantity,
        'sale', 'sale', v_sale_id, p_invoice_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
          v_product_id, v_quantity, (v_quantity - v_short);
      END IF;
      v_cogs_total := v_cogs_total + COALESCE((v_res->>'total_cost')::numeric, 0);
    END LOOP;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', v_paid, p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    -- ===== WRITE PHASE 4: post the sales + COGS journal entry =====
    IF v_paid > 0 THEN
      v_balance_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END;
      v_lines := v_lines || jsonb_build_object('account_key', v_balance_account,
        'debit', v_paid, 'credit', 0, 'note', p_invoice_number);
      v_dr := v_dr + v_paid;
    END IF;
    IF v_ar > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'ar',
        'debit', v_ar, 'credit', 0, 'customer_id', p_customer_id, 'note', p_invoice_number);
      v_dr := v_dr + v_ar;
    END IF;
    IF v_discount > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', v_discount, 'credit', 0);
      v_dr := v_dr + v_discount;
    END IF;
    IF v_subtotal > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'revenue', 'debit', 0, 'credit', v_subtotal);
      v_cr := v_cr + v_subtotal;
    END IF;
    IF v_tax > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'vat_payable', 'debit', 0, 'credit', v_tax);
      v_cr := v_cr + v_tax;
    END IF;
    IF v_cogs_total > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'cogs', 'debit', v_cogs_total, 'credit', 0);
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', 0, 'credit', v_cogs_total);
      v_dr := v_dr + v_cogs_total;
      v_cr := v_cr + v_cogs_total;
    END IF;

    -- Balance any rounding/frontend discrepancy on the discount account so a
    -- posted entry is always balanced (normally the difference is zero).
    v_diff := round(v_dr - v_cr, 2);
    IF v_diff <> 0 THEN
      IF v_diff > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', 0, 'credit', v_diff);
      ELSE
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', -v_diff, 'credit', 0);
      END IF;
    END IF;

    PERFORM public._post_journal_entry(p_branch_id, 'sale', v_sale_id, p_invoice_number,
      'ÙØ§ØªÙˆØ±Ø© Ù…Ø¨ÙŠØ¹Ø§Øª ' || p_invoice_number, v_lines);

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number,
      'cogs', v_cogs_total);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 032_db_grants.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 032. Table/sequence privileges for authenticated + service_role
-- ----------------------------------------------------------------------------
-- A real Supabase project grants its API roles access to every table in the
-- `public` schema (via ALTER DEFAULT PRIVILEGES set up at project creation).
-- A plain-Postgres fresh build does not: the canonical migrations create the
-- tables but `authenticated` had no privileges, so RLS could never be
-- exercised (permission denied fires before any policy). This file closes
-- that gap so the fresh build behaves exactly like live Supabase.
--
-- RLS stays the security boundary: `authenticated` receives DML privileges but
-- every table's policies still filter rows by branch/role.
--
-- Additive + idempotent. Safe on live (the grants already exist there).
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Object privileges for tables created by the canonical migrations in the future.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated, service_role;

-- 028_d10_security deliberately restricts document_sequences to SELECT-only;
-- preserve that intent (the bulk grant above re-opens it otherwise).
REVOKE INSERT, UPDATE, DELETE ON public.document_sequences FROM authenticated;



-- ----------------------------------------------------------------------------
-- MIGRATION: 033_perf_indexes.sql
-- ----------------------------------------------------------------------------

-- ============================================================
-- 033_perf_indexes.sql
-- Phase 1 audit: FK columns used on hot query paths that lack a
-- leading index. Additive only â€” all CREATE INDEX IF NOT EXISTS.
-- (Skipped low-value audit flags such as *_created_by lookups.)
-- ============================================================

-- Catalog / BOM lookups
CREATE INDEX IF NOT EXISTS idx_product_components_component ON public.product_components (component_product_id);
CREATE INDEX IF NOT EXISTS idx_product_units_product        ON public.product_units (product_id);

-- Recipes / production
CREATE INDEX IF NOT EXISTS idx_recipe_items_recipe          ON public.recipe_items (recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_items_raw             ON public.recipe_items (raw_material_id);
CREATE INDEX IF NOT EXISTS idx_production_waste_order       ON public.production_waste (order_id);
CREATE INDEX IF NOT EXISTS idx_production_orders_branch     ON public.production_orders (branch_id);

-- Warehouses / transfers
CREATE INDEX IF NOT EXISTS idx_inventory_batches_warehouse  ON public.inventory_batches (warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_transactions_warehouse ON public.stock_transactions (warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_transfer_items_tx  ON public.warehouse_transfer_items (transfer_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_transfers_from     ON public.warehouse_transfers (from_warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_transfers_to       ON public.warehouse_transfers (to_warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_transfers_branch   ON public.warehouse_transfers (branch_id);

-- Sales / purchases filters
CREATE INDEX IF NOT EXISTS idx_sales_cashier                ON public.sales (cashier_id);
CREATE INDEX IF NOT EXISTS idx_sales_salesperson            ON public.sales (salesperson_id);
CREATE INDEX IF NOT EXISTS idx_sales_warehouse              ON public.sales (warehouse_id);
CREATE INDEX IF NOT EXISTS idx_purchases_warehouse          ON public.purchases (warehouse_id);

-- Accounting joins
CREATE INDEX IF NOT EXISTS idx_account_mappings_account     ON public.account_mappings (account_id);
CREATE INDEX IF NOT EXISTS idx_expenses_account             ON public.expenses (account_id);
CREATE INDEX IF NOT EXISTS idx_treasury_accounts_coa        ON public.treasury_accounts (account_id);



-- ----------------------------------------------------------------------------
-- MIGRATION: 034_branch_settings.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 034. Per-branch settings table
-- ----------------------------------------------------------------------------
-- The Settings page overrides the global settings row per branch (NULL column
-- = fall back to the global value). This table previously existed only in the
-- archived legacy migration (supabase/legacy/migration_audit_fixes.sql, never
-- applied on fresh builds), so a canonical fresh build had NO branch_settings
-- table and SettingsContext (supabase.from('branch_settings')) failed at
-- runtime. This restores it in the canonical chain.
--
-- Isolation model (matches the app's permission gate on /settings):
--   * SELECT: admins see every branch; staff see only their own branch.
--   * INSERT/UPDATE/DELETE: admins, or a user holding 'settings.manage' for
--     their OWN branch (can_permission is SECURITY DEFINER + STABLE).
-- Additive + idempotent. Table-level privileges come automatically from the
-- ALTER DEFAULT PRIVILEGES set in 032_db_grants.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.branch_settings (
  branch_id uuid PRIMARY KEY REFERENCES public.branches(id) ON DELETE CASCADE,
  receipt_header text,
  receipt_footer text,
  logo_url text,
  tax_rate numeric(5,2),
  tax_enabled boolean,
  currency text,
  low_stock_threshold numeric(12,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.branch_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "auth_select_branch_settings" ON public.branch_settings;
CREATE POLICY "auth_select_branch_settings" ON public.branch_settings FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

DROP POLICY IF EXISTS "auth_write_branch_settings" ON public.branch_settings;
CREATE POLICY "auth_write_branch_settings" ON public.branch_settings FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR (can_permission('settings.manage') AND branch_id = get_branch_id()));

DROP POLICY IF EXISTS "auth_write_branch_settings_upd" ON public.branch_settings;
CREATE POLICY "auth_write_branch_settings_upd" ON public.branch_settings FOR UPDATE TO authenticated
  USING (is_pos_admin() OR (can_permission('settings.manage') AND branch_id = get_branch_id()))
  WITH CHECK (is_pos_admin() OR (can_permission('settings.manage') AND branch_id = get_branch_id()));

DROP POLICY IF EXISTS "auth_write_branch_settings_del" ON public.branch_settings;
CREATE POLICY "auth_write_branch_settings_del" ON public.branch_settings FOR DELETE TO authenticated
  USING (is_pos_admin() OR (can_permission('settings.manage') AND branch_id = get_branch_id()));



-- ----------------------------------------------------------------------------
-- MIGRATION: 035_settings_rls.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 035. Settings expansion + tighten global settings RLS
-- ----------------------------------------------------------------------------
-- 1) The frontend Settings type reads 13 more columns than the canonical 001
--    table created (brand/pos/invoice/receipt/inventory). Those columns lived
--    only in the archived legacy migration, so a canonical fresh build returned
--    NULL/undefined for pos_default_payment_method, invoice_next_number,
--    receipt_width_mm, low_stock_threshold, etc. and the POS/receipt/invoice
--    features silently misbehaved. Add them (idempotent) here.
--
-- 2) settings RLS from 001 was open for EVERY DML command to ANY authenticated
--    user (USING true / WITH CHECK true), so any cashier could rewrite the
--    global configuration directly through PostgREST. The /settings page is
--    admin-only (settings.manage; only super_admin/owner hold it by default),
--    so writes are locked to admins. SELECT stays open: every page resolves
--    the effective settings at boot.
-- Additive + idempotent.
-- ============================================================================

ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS brand_color text;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS pos_default_payment_method text DEFAULT 'cash';
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS pos_barcode_autofocus boolean DEFAULT true;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS pos_line_discount boolean DEFAULT true;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS invoice_prefix text DEFAULT 'INV-';
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS invoice_next_number bigint DEFAULT 1;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS invoice_decimal_places integer DEFAULT 2;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS receipt_width_mm integer DEFAULT 58;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS receipt_copies integer DEFAULT 1;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS receipt_auto_print boolean DEFAULT true;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS receipt_show_tax boolean DEFAULT true;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS receipt_show_qr boolean DEFAULT true;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS low_stock_threshold numeric(12,2) DEFAULT 5;

DROP POLICY IF EXISTS "auth_insert_settings" ON public.settings;
CREATE POLICY "auth_insert_settings" ON public.settings FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin());

DROP POLICY IF EXISTS "auth_update_settings" ON public.settings;
CREATE POLICY "auth_update_settings" ON public.settings FOR UPDATE TO authenticated
  USING (is_pos_admin()) WITH CHECK (is_pos_admin());

DROP POLICY IF EXISTS "auth_delete_settings" ON public.settings;
CREATE POLICY "auth_delete_settings" ON public.settings FOR DELETE TO authenticated
  USING (is_pos_admin());



-- ----------------------------------------------------------------------------
-- MIGRATION: 036_floorplan_orders.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 036. Restaurant floor plan + open orders (Phase 3 foundation)
-- ----------------------------------------------------------------------------
-- Adds the dine-in foundation on top of the completed-sale model:
--   * dining_areas   - floor zones per branch (Terrace, Hall, Second floor...)
--   * dining_tables  - tables in an area with layout {x,y,w,h} + status
--                      (vacant | occupied | reserved | closed)
--   * orders         - open/held in-progress orders (hold/recall carts) with
--                      an order_type (dine_in | takeaway | delivery | drive_thru)
--   * order_items    - lines of an open order (child of orders)
--   * sales          - gains order_type + table_id so completed sales report
--                      the service channel and origin table
--
-- Isolation model (consistent with the branch matrix):
--   * dining_areas:  SELECT admin-or-own-branch; writes admin-only (config).
--   * dining_tables: full (admin-or-own-branch for every command) because the
--                    POS needs to flip status (occupied/vacant) at runtime.
--   * orders:        full (admin-or-own-branch).
--   * order_items:   child rows isolate through their parent order.
-- Table privileges come automatically from 032 ALTER DEFAULT PRIVILEGES.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.dining_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dining_tables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  area_id uuid REFERENCES public.dining_areas(id) ON DELETE SET NULL,
  name text NOT NULL,
  capacity integer NOT NULL DEFAULT 4,
  status text NOT NULL DEFAULT 'vacant',
  shape text NOT NULL DEFAULT 'rect',
  layout jsonb NOT NULL DEFAULT '{"x":0,"y":0,"w":120,"h":80}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number text NOT NULL,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
  order_type text NOT NULL DEFAULT 'dine_in',
  status text NOT NULL DEFAULT 'open',
  table_id uuid REFERENCES public.dining_tables(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  cashier_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  guest_count integer,
  notes text,
  subtotal numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  discount_type text NOT NULL DEFAULT 'amount',
  tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  unit_name text NOT NULL DEFAULT 'piece',
  quantity numeric(14,4) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  bonus_quantity numeric(14,4) NOT NULL DEFAULT 0,
  total numeric(14,2) NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Completed sales record their service channel + origin table.
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS order_type text NOT NULL DEFAULT 'takeaway';
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS table_id uuid REFERENCES public.dining_tables(id) ON DELETE SET NULL;

-- ===== Indexes =====
CREATE INDEX IF NOT EXISTS idx_dining_areas_branch ON public.dining_areas (branch_id);
CREATE INDEX IF NOT EXISTS idx_dining_tables_branch ON public.dining_tables (branch_id);
CREATE INDEX IF NOT EXISTS idx_dining_tables_area ON public.dining_tables (area_id);
CREATE INDEX IF NOT EXISTS idx_dining_tables_status ON public.dining_tables (status);
CREATE INDEX IF NOT EXISTS idx_orders_branch_status ON public.orders (branch_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_table ON public.orders (table_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_type ON public.sales (order_type);

-- ===== RLS =====
ALTER TABLE public.dining_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dining_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- dining_areas: SELECT admin-or-own-branch; writes admin-only.
DROP POLICY IF EXISTS "auth_select_dining_areas" ON public.dining_areas;
CREATE POLICY "auth_select_dining_areas" ON public.dining_areas FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_dining_areas" ON public.dining_areas;
CREATE POLICY "auth_write_dining_areas" ON public.dining_areas FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_write_dining_areas_upd" ON public.dining_areas;
CREATE POLICY "auth_write_dining_areas_upd" ON public.dining_areas FOR UPDATE TO authenticated
  USING (is_pos_admin()) WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "auth_write_dining_areas_del" ON public.dining_areas;
CREATE POLICY "auth_write_dining_areas_del" ON public.dining_areas FOR DELETE TO authenticated
  USING (is_pos_admin());

-- dining_tables: full (admin-or-own-branch for every command).
DROP POLICY IF EXISTS "auth_select_dining_tables" ON public.dining_tables;
CREATE POLICY "auth_select_dining_tables" ON public.dining_tables FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_dining_tables" ON public.dining_tables;
CREATE POLICY "auth_write_dining_tables" ON public.dining_tables FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_dining_tables_upd" ON public.dining_tables;
CREATE POLICY "auth_write_dining_tables_upd" ON public.dining_tables FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_dining_tables_del" ON public.dining_tables;
CREATE POLICY "auth_write_dining_tables_del" ON public.dining_tables FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- orders: full (admin-or-own-branch for every command).
DROP POLICY IF EXISTS "auth_select_orders" ON public.orders;
CREATE POLICY "auth_select_orders" ON public.orders FOR SELECT TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_orders" ON public.orders;
CREATE POLICY "auth_write_orders" ON public.orders FOR INSERT TO authenticated
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_orders_upd" ON public.orders;
CREATE POLICY "auth_write_orders_upd" ON public.orders FOR UPDATE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id())
  WITH CHECK (is_pos_admin() OR branch_id = get_branch_id());
DROP POLICY IF EXISTS "auth_write_orders_del" ON public.orders;
CREATE POLICY "auth_write_orders_del" ON public.orders FOR DELETE TO authenticated
  USING (is_pos_admin() OR branch_id = get_branch_id());

-- order_items: child rows isolate through the parent order.
DROP POLICY IF EXISTS "auth_select_order_items" ON public.order_items;
CREATE POLICY "auth_select_order_items" ON public.order_items FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_id AND (is_pos_admin() OR o.branch_id = get_branch_id())
  ));
DROP POLICY IF EXISTS "auth_write_order_items" ON public.order_items;
CREATE POLICY "auth_write_order_items" ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_id AND (is_pos_admin() OR o.branch_id = get_branch_id())
  ));
DROP POLICY IF EXISTS "auth_write_order_items_upd" ON public.order_items;
CREATE POLICY "auth_write_order_items_upd" ON public.order_items FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_id AND (is_pos_admin() OR o.branch_id = get_branch_id())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_id AND (is_pos_admin() OR o.branch_id = get_branch_id())
  ));
DROP POLICY IF EXISTS "auth_write_order_items_del" ON public.order_items;
CREATE POLICY "auth_write_order_items_del" ON public.order_items FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.id = order_id AND (is_pos_admin() OR o.branch_id = get_branch_id())
  ));



-- ----------------------------------------------------------------------------
-- MIGRATION: 037_floorplan_rpc.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 037. Floor-plan / open-order RPCs (SECURITY DEFINER)
-- ----------------------------------------------------------------------------
-- Hold/recall + table-occupancy need transactional writes that must not be
-- reachable through plain RLS table writes (e.g. freeing a table, flipping an
-- order to completed). These RPCs re-validate the caller's branch exactly like
-- the RLS policies (admin, or own-branch only) and run atomically.
--
--   * create_order      - persist a held cart as an open order; occupies the
--                         chosen table (dine-in).
--   * set_order_status  - open | held | completed | cancelled; completed /
--                         cancelled free the table.
--   * set_table_status  - vacant | occupied | reserved | closed.
-- Additive. All three are idempotent-safe (return success for valid targets).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- create_order: save the current cart as an open/held order
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_order(
  p_branch_id uuid,
  p_order_type text DEFAULT 'dine_in',
  p_table_id uuid DEFAULT NULL,
  p_customer_id uuid DEFAULT NULL,
  p_guest_count integer DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_items jsonb DEFAULT '[]'::jsonb,
  p_subtotal numeric DEFAULT 0,
  p_discount_amount numeric DEFAULT 0,
  p_discount_type text DEFAULT 'amount',
  p_tax_amount numeric DEFAULT 0,
  p_total numeric DEFAULT 0,
  p_cashier_id uuid DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_order_id uuid;
  v_number jsonb;
  v_user_branch uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT branch_id INTO v_user_branch FROM public.users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND COALESCE(v_user_branch, '00000000-0000-0000-0000-000000000000'::uuid) <> p_branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    -- A dine-in order must point at a table in the same branch.
    IF p_table_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.dining_tables WHERE id = p_table_id AND branch_id = p_branch_id AND is_active
    ) THEN
      RETURN jsonb_build_object('success', false, 'error', 'TABLE_NOT_IN_BRANCH', 'table_id', p_table_id);
    END IF;

    -- Validate every line before writing anything.
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;
      IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = v_product_id AND branch_id = p_branch_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH', 'product_id', v_product_id);
      END IF;
    END LOOP;

    v_number := public.next_document_number('order');
    IF NOT (v_number->>'success')::boolean THEN
      RETURN jsonb_build_object('success', false, 'error', 'NUMBERING_FAILED', 'detail', v_number->>'error');
    END IF;

    INSERT INTO public.orders (order_number, branch_id, order_type, status, table_id, customer_id,
      cashier_id, guest_count, notes, subtotal, discount_amount, discount_type, tax_amount, total)
    VALUES (v_number->>'number', p_branch_id, COALESCE(p_order_type, 'dine_in'), 'open', p_table_id,
      p_customer_id, COALESCE(p_cashier_id, auth.uid()), p_guest_count, p_notes,
      COALESCE(p_subtotal, 0), COALESCE(p_discount_amount, 0), COALESCE(p_discount_type, 'amount'),
      COALESCE(p_tax_amount, 0), COALESCE(p_total, 0))
    RETURNING id INTO v_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      INSERT INTO public.order_items (order_id, product_id, unit_name, quantity, unit_price,
        discount_amount, bonus_quantity, total, notes)
      VALUES (v_order_id, (v_item->>'product_id')::uuid,
        COALESCE(v_item->>'unit_name', 'piece'),
        COALESCE((v_item->>'quantity')::numeric, 1),
        COALESCE((v_item->>'unit_price')::numeric, 0),
        COALESCE((v_item->>'discount_amount')::numeric, 0),
        COALESCE((v_item->>'bonus_quantity')::numeric, 0),
        COALESCE((v_item->>'total')::numeric, 0),
        NULLIF(v_item->>'notes', ''));
    END LOOP;

    IF p_table_id IS NOT NULL THEN
      UPDATE public.dining_tables SET status = 'occupied', updated_at = now() WHERE id = p_table_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id, 'order_number', v_number->>'number');
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------------
-- set_order_status: open | held | completed | cancelled
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_order_status(p_order_id uuid, p_status text, p_notes text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_branch_id uuid;
  v_table_id uuid;
  v_user_branch uuid;
BEGIN
  BEGIN
    IF p_status NOT IN ('open', 'held', 'completed', 'cancelled') THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS');
    END IF;

    SELECT branch_id, table_id INTO v_branch_id, v_table_id
    FROM public.orders WHERE id = p_order_id;
    IF v_branch_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
    END IF;

    SELECT branch_id INTO v_user_branch FROM public.users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND COALESCE(v_user_branch, '00000000-0000-0000-0000-000000000000'::uuid) <> v_branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    UPDATE public.orders SET status = p_status, updated_at = now(),
      completed_at = CASE WHEN p_status IN ('completed', 'cancelled') THEN now() ELSE NULL END,
      notes = COALESCE(p_notes, notes)
    WHERE id = p_order_id;

    -- Occupied table while open; freed once the order is done.
    IF v_table_id IS NOT NULL THEN
      UPDATE public.dining_tables SET status =
        CASE WHEN p_status IN ('completed', 'cancelled') THEN 'vacant' ELSE 'occupied' END,
        updated_at = now()
      WHERE id = v_table_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'order_id', p_order_id, 'status', p_status);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;

-- ---------------------------------------------------------------------------
-- set_table_status: vacant | occupied | reserved | closed
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_table_status(p_table_id uuid, p_status text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_branch_id uuid;
  v_user_branch uuid;
BEGIN
  BEGIN
    IF p_status NOT IN ('vacant', 'occupied', 'reserved', 'closed') THEN
      RETURN jsonb_build_object('success', false, 'error', 'INVALID_STATUS');
    END IF;

    SELECT branch_id INTO v_branch_id FROM public.dining_tables WHERE id = p_table_id;
    IF v_branch_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'TABLE_NOT_FOUND');
    END IF;

    SELECT branch_id INTO v_user_branch FROM public.users WHERE id = auth.uid();
    IF NOT is_pos_admin() AND COALESCE(v_user_branch, '00000000-0000-0000-0000-000000000000'::uuid) <> v_branch_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
    END IF;

    UPDATE public.dining_tables SET status = p_status, updated_at = now() WHERE id = p_table_id;
    RETURN jsonb_build_object('success', true, 'table_id', p_table_id, 'status', p_status);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 038_process_sale_order_fields.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 038. process_sale: order channel + table + linked order
-- ----------------------------------------------------------------------------
-- Extends the authoritative process_sale (031) with three trailing arguments:
--   * p_order_type text  DEFAULT 'takeaway'  - dine_in | takeaway | delivery | drive_thru
--   * p_table_id uuid    DEFAULT NULL        - origin table for dine-in
--   * p_order_id uuid    DEFAULT NULL        - an open/held order being paid
-- The order channel + table are stored on the completed sale; a linked order is
-- marked completed and its table freed. Server-side pricing is unchanged.
-- The old 16-argument signature is dropped (the frontend is the only caller and
-- always goes through the API wrapper); trailing defaults keep the pricing
-- integration test's 16-argument call working.
-- ============================================================================

DROP FUNCTION IF EXISTS public.process_sale(text, uuid, uuid, uuid, uuid, numeric, numeric, text, numeric, numeric, numeric, numeric, text, text, jsonb, uuid);

CREATE OR REPLACE FUNCTION public.process_sale(p_invoice_number text, p_branch_id uuid, p_warehouse_id uuid, p_customer_id uuid, p_salesperson_id uuid, p_subtotal numeric, p_discount_amount numeric, p_discount_type text, p_tax_amount numeric, p_bonus_amount numeric, p_total numeric, p_paid_amount numeric, p_payment_method text, p_status text, p_items jsonb, p_shift_id uuid DEFAULT NULL::uuid, p_order_type text DEFAULT 'takeaway', p_table_id uuid DEFAULT NULL::uuid, p_order_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sale_id uuid;
  v_user_branch uuid;
  v_role text;
  v_shift_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity numeric(14,4);
  v_unit_price numeric(12,2);
  v_discount_amount numeric(14,2);
  v_bonus_quantity numeric(14,4);
  v_item_total numeric(14,2);
  v_warehouse_ids uuid[];
  v_available numeric(14,4);
  v_res jsonb;
  v_short numeric(14,4);
  v_cogs_total numeric(14,2) := 0;
  v_subtotal numeric(14,2) := 0;
  v_discount numeric(14,2);
  v_tax numeric(14,2) := 0;
  v_tax_enabled boolean;
  v_tax_rate numeric(14,2);
  v_total numeric(14,2);
  v_paid numeric(14,2);
  v_ar numeric(14,2);
  v_lines jsonb := '[]'::jsonb;
  v_dr numeric(14,2) := 0;
  v_cr numeric(14,2) := 0;
  v_diff numeric(14,2);
  v_balance_account text;
  v_order_table uuid;
BEGIN
  BEGIN
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'EMPTY_CART');
    END IF;

    SELECT role, branch_id INTO v_role, v_user_branch FROM public.users WHERE id = auth.uid();

    -- Branch isolation (mirror of RLS on sales)
    IF NOT is_pos_admin() THEN
      IF v_user_branch IS NOT NULL AND v_user_branch <> p_branch_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'BRANCH_MISMATCH');
      END IF;
    END IF;

    -- Origin table must belong to the sale branch
    IF p_table_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.dining_tables WHERE id = p_table_id AND branch_id = p_branch_id
    ) THEN
      RETURN jsonb_build_object('success', false, 'error', 'TABLE_NOT_IN_BRANCH', 'table_id', p_table_id);
    END IF;

    -- Shift enforcement for register operators
    IF v_role = 'cashier' AND NOT is_pos_admin() THEN
      IF p_shift_id IS NULL THEN
        SELECT id INTO v_shift_id
        FROM shifts
        WHERE cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ORDER BY opened_at DESC LIMIT 1;
      ELSE
        IF NOT EXISTS (
          SELECT 1 FROM shifts
          WHERE id = p_shift_id AND cashier_id = auth.uid() AND branch_id = p_branch_id AND status = 'open'
        ) THEN
          RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
            'detail', 'Open a shift before selling. The sale was not created.');
        END IF;
        v_shift_id := p_shift_id;
      END IF;

      IF v_shift_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'NO_OPEN_SHIFT',
          'detail', 'Open a shift before selling. The sale was not created.');
      END IF;
    END IF;

    -- Stock deduction scope: all active warehouses of the branch
    SELECT array_agg(id) INTO v_warehouse_ids
    FROM warehouses WHERE branch_id = p_branch_id AND is_active = true;

    -- ===== VALIDATION PHASE: check every item BEFORE writing anything =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      IF v_quantity <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'INVALID_QUANTITY', 'product_id', v_product_id);
      END IF;

      IF NOT EXISTS (SELECT 1 FROM products WHERE id = v_product_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_FOUND', 'product_id', v_product_id);
      END IF;

      -- Branch ownership: the product must belong to the sale branch
      IF NOT EXISTS (
        SELECT 1 FROM products WHERE id = v_product_id AND branch_id = p_branch_id
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'PRODUCT_NOT_IN_BRANCH',
          'product_id', v_product_id, 'branch_id', p_branch_id);
      END IF;

      SELECT COALESCE(SUM(quantity), 0) INTO v_available
      FROM inventory_batches
      WHERE product_id = v_product_id AND warehouse_id = ANY(v_warehouse_ids);
      IF v_available < v_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK',
          'product_id', v_product_id, 'required', v_quantity, 'available', v_available);
      END IF;

      -- Accumulate the authoritative subtotal (catalog price, clamped discount)
      SELECT COALESCE(sale_price, 0) INTO v_unit_price FROM products WHERE id = v_product_id;
      v_discount_amount := GREATEST(COALESCE((v_item->>'discount_amount')::numeric, 0), 0);
      IF v_discount_amount > v_quantity * v_unit_price THEN
        v_discount_amount := v_quantity * v_unit_price;
      END IF;
      v_subtotal := v_subtotal + ROUND(v_quantity * v_unit_price - v_discount_amount, 2);
    END LOOP;

    -- ===== SERVER-SIDE HEADER TOTALS (computed from authoritative prices) =====
    v_discount := GREATEST(COALESCE(p_discount_amount, 0), 0);
    IF v_discount > v_subtotal THEN v_discount := v_subtotal; END IF;
    SELECT COALESCE(tax_enabled, false), COALESCE(tax_rate, 0) INTO v_tax_enabled, v_tax_rate
    FROM public.settings LIMIT 1;
    IF v_tax_enabled THEN
      v_tax := ROUND((v_subtotal - v_discount) * v_tax_rate / 100, 2);
    END IF;
    v_total := ROUND(v_subtotal - v_discount + v_tax, 2);
    v_paid := ROUND(GREATEST(COALESCE(p_paid_amount, 0), 0), 2);
    v_ar := ROUND(GREATEST(v_total - v_paid, 0), 2);

    -- ===== WRITE PHASE 1: sale header (authoritative totals) =====
    INSERT INTO sales (invoice_number, branch_id, warehouse_id, customer_id, cashier_id, salesperson_id,
      subtotal, discount_amount, discount_type, tax_amount, bonus_amount, total, paid_amount, payment_method, status, order_type, table_id)
    VALUES (p_invoice_number, p_branch_id, p_warehouse_id, p_customer_id, auth.uid(), p_salesperson_id,
      v_subtotal, v_discount, p_discount_type, v_tax, COALESCE(p_bonus_amount, 0),
      v_total, v_paid, p_payment_method, p_status, COALESCE(p_order_type, 'takeaway'), p_table_id)
    RETURNING id INTO v_sale_id;

    -- ===== WRITE PHASE 2: items + FIFO stock deduction + ledger =====
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_product_id := (v_item->>'product_id')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::numeric, 0);
      v_discount_amount := GREATEST(COALESCE((v_item->>'discount_amount')::numeric, 0), 0);

      SELECT sale_price INTO v_unit_price FROM products WHERE id = v_product_id;
      v_unit_price := COALESCE(v_unit_price, 0);
      IF v_discount_amount > v_quantity * v_unit_price THEN
        v_discount_amount := v_quantity * v_unit_price;
      END IF;
      v_bonus_quantity := COALESCE((v_item->>'bonus_quantity')::numeric, 0);
      v_item_total := ROUND(v_quantity * v_unit_price - v_discount_amount, 2);

      INSERT INTO sale_items (sale_id, product_id, unit_name, quantity, unit_price, discount_amount, bonus_quantity, total)
      VALUES (v_sale_id, v_product_id, COALESCE(v_item->>'unit_name', 'piece'),
        v_quantity, v_unit_price, v_discount_amount, v_bonus_quantity, v_item_total);

      v_res := public._product_inv_remove_fifo(v_product_id, NULL, p_branch_id, v_quantity,
        'sale', 'sale', v_sale_id, p_invoice_number, auth.uid());
      v_short := (v_res->>'shortage')::numeric;
      IF v_short > 0 THEN
        RAISE EXCEPTION 'INSUFFICIENT_STOCK: product % needs % but only % available',
          v_product_id, v_quantity, (v_quantity - v_short);
      END IF;
      v_cogs_total := v_cogs_total + COALESCE((v_res->>'total_cost')::numeric, 0);
    END LOOP;

    -- ===== WRITE PHASE 2b: settle a linked open/held order =====
    IF p_order_id IS NOT NULL THEN
      SELECT table_id INTO v_order_table FROM public.orders WHERE id = p_order_id;
      IF v_order_table IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
      END IF;
      IF NOT EXISTS (
        SELECT 1 FROM public.orders
        WHERE id = p_order_id AND branch_id = p_branch_id AND status IN ('open', 'held')
      ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'ORDER_NOT_FOUND');
      END IF;
      UPDATE public.orders SET status = 'completed', completed_at = now(), updated_at = now()
      WHERE id = p_order_id;
      UPDATE public.dining_tables SET status = 'vacant', updated_at = now()
      WHERE id = v_order_table;
    END IF;

    -- ===== WRITE PHASE 3: log the sale into the active shift =====
    IF v_shift_id IS NOT NULL THEN
      INSERT INTO shift_operations (shift_id, operation_type, amount, payment_method, reference_type, reference_id, created_by)
      VALUES (v_shift_id, 'sale', v_paid, p_payment_method, 'sale', v_sale_id, auth.uid());
    END IF;

    -- ===== WRITE PHASE 4: post the sales + COGS journal entry =====
    IF v_paid > 0 THEN
      v_balance_account := CASE WHEN COALESCE(p_payment_method, 'cash') = 'cash' THEN 'cash' ELSE 'bank' END;
      v_lines := v_lines || jsonb_build_object('account_key', v_balance_account,
        'debit', v_paid, 'credit', 0, 'note', p_invoice_number);
      v_dr := v_dr + v_paid;
    END IF;
    IF v_ar > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'ar',
        'debit', v_ar, 'credit', 0, 'customer_id', p_customer_id, 'note', p_invoice_number);
      v_dr := v_dr + v_ar;
    END IF;
    IF v_discount > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', v_discount, 'credit', 0);
      v_dr := v_dr + v_discount;
    END IF;
    IF v_subtotal > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'revenue', 'debit', 0, 'credit', v_subtotal);
      v_cr := v_cr + v_subtotal;
    END IF;
    IF v_tax > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'vat_payable', 'debit', 0, 'credit', v_tax);
      v_cr := v_cr + v_tax;
    END IF;
    IF v_cogs_total > 0 THEN
      v_lines := v_lines || jsonb_build_object('account_key', 'cogs', 'debit', v_cogs_total, 'credit', 0);
      v_lines := v_lines || jsonb_build_object('account_key', 'inventory_fg', 'debit', 0, 'credit', v_cogs_total);
      v_dr := v_dr + v_cogs_total;
      v_cr := v_cr + v_cogs_total;
    END IF;

    -- Balance any rounding/frontend discrepancy on the discount account so a
    -- posted entry is always balanced (normally the difference is zero).
    v_diff := round(v_dr - v_cr, 2);
    IF v_diff <> 0 THEN
      IF v_diff > 0 THEN
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', 0, 'credit', v_diff);
      ELSE
        v_lines := v_lines || jsonb_build_object('account_key', 'discount_given', 'debit', -v_diff, 'credit', 0);
      END IF;
    END IF;

    PERFORM public._post_journal_entry(p_branch_id, 'sale', v_sale_id, p_invoice_number,
      'ÙØ§ØªÙˆØ±Ø© Ù…Ø¨ÙŠØ¹Ø§Øª ' || p_invoice_number, v_lines);

    RETURN jsonb_build_object('success', true, 'sale_id', v_sale_id, 'invoice_number', p_invoice_number,
      'cogs', v_cogs_total);
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'INSUFFICIENT_STOCK%' THEN
      RETURN jsonb_build_object('success', false, 'error', 'INSUFFICIENT_STOCK', 'detail', SQLERRM);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'TRANSACTION_FAILED', 'detail', SQLERRM);
  END;
END;
$function$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 039_permissions_floorplan.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 039. Floor-plan permissions
-- ----------------------------------------------------------------------------
-- Grants the floor-plan permissions to the seeded roles (idempotent for the
-- roles that already hold them). Admins bypass via is_pos_admin(); the entries
-- keep the roles matrix consistent for the UI. Non-admin floor-plan layout
-- writes are still branch-gated by the dining_* RLS policies.
-- ============================================================================

UPDATE public.roles
SET permissions = permissions || '["floor_plan.view","floor_plan.manage"]'::jsonb
WHERE role IN ('super_admin', 'owner');

UPDATE public.roles
SET permissions = permissions || '["floor_plan.view"]'::jsonb
WHERE role = 'branch_manager';



-- ----------------------------------------------------------------------------
-- MIGRATION: 040_floorplan_permissions_cashier.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 040. Floor-plan permission for cashiers
-- ----------------------------------------------------------------------------
-- Cashiers serve tables, so they need floor_plan.view to open/resume dine-in
-- orders from the floor. Keeps the DB roles matrix consistent with the code
-- defaults. floor_plan.manage stays admin / branch-manager only.
-- ============================================================================

UPDATE public.roles
SET permissions = permissions || '["floor_plan.view"]'::jsonb
WHERE role = 'cashier';



-- ----------------------------------------------------------------------------
-- MIGRATION: 041_floorplan_branch_manager_manage.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 041. Floor-plan manage for branch managers
-- ----------------------------------------------------------------------------
-- Branch managers administer the floor plan of their branch (add areas/tables,
-- reposition, set statuses). 039 only granted them floor_plan.view; the code
-- defaults (permissionDefs.ts) and the floor_plan.manage usage inside
-- FloorPlanPage expect manage as well. Keeps the DB roles matrix consistent
-- with the UI defaults. floor_plan.manage stays admin / branch-manager only.
-- ============================================================================

UPDATE public.roles
SET permissions = permissions || '["floor_plan.manage"]'::jsonb
WHERE role = 'branch_manager'
  AND NOT permissions ? 'floor_plan.manage';



-- ----------------------------------------------------------------------------
-- MIGRATION: 042_realtime_orders_publication.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 042. Realtime publication for POS live counters
-- ----------------------------------------------------------------------------
-- The POS header strip shows live counters (occupied tables / held / delivery /
-- takeaway). It subscribes via supabase.channel('pos-live-summary') to
-- postgres_changes on orders and dining_tables. Those tables must be members of
-- the supabase_realtime publication, otherwise the browser subscription is
-- rejected. The publication may not exist in some self-hosted / CI setups, so
-- this migration is guarded and idempotent (no-op on Postgres without the
-- supabase_realtime publication).
--
-- NOTE: on hosted Supabase the project owner should also enable realtime for
-- these tables via the dashboard (Database > Replication) or this same SQL; the
-- guard here only makes sure the migration never breaks existing deployments.
-- ============================================================================

DO $$
DECLARE
  pub_exists boolean;
  tbl text;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) INTO pub_exists;

  IF pub_exists THEN
    FOREACH tbl IN ARRAY ARRAY['public.orders', 'public.dining_tables'] LOOP
      IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables pt
        WHERE pt.pubname = 'supabase_realtime'
          AND pt.schemaname || '.' || pt.tablename = tbl
      ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE ' || tbl;
      END IF;
    END LOOP;
  END IF;
END $$;



-- ----------------------------------------------------------------------------
-- MIGRATION: 043_user_role_management.sql
-- ----------------------------------------------------------------------------

-- ============================================================================
-- 043. User & Role Management
-- ----------------------------------------------------------------------------
-- Backing schema for the User & Role Management feature. Additive + idempotent
-- (safe to re-run; the migration runner also gates it by checksum).
--
--   1. roles: `scope` (global/branch) + `branch_id` + descriptions + active
--      flag; branch managers can create/manage roles scoped to their own
--      branch. System/global roles stay admin-managed only.
--   2. users: phone / is_locked / failed_attempts / lock_until / last_login_at;
--      the fixed-role CHECK is dropped so custom roles work. Role validity is
--      enforced by the (updated) role-guard trigger instead.
--   3. guard_user_role_changes: validates assigned roles exist and are
--      assignable in the caller's scope; blocks self-lock tampering; keeps the
--      existing admin/BM safeguards intact.
--   4. login_as_log + login_as_user / return_from_login_as RPCs.
--   5. Login lockout: record_login_failure / record_login_success + a locked
--      check in get_login_email.
--   6. audit_log: ip / device columns.
--   7. Seeds the two legacy role values (kitchen / customer_display) that exist
--      in users but were never in the roles matrix, and appends the new action
--      permissions to the default role matrix.
-- ============================================================================

-- ============ 1. ROLES: SCOPE + BRANCH ============
ALTER TABLE public.roles ADD COLUMN IF NOT EXISTS scope text NOT NULL DEFAULT 'global';
ALTER TABLE public.roles ADD COLUMN IF NOT EXISTS branch_id uuid REFERENCES public.branches(id) ON DELETE CASCADE;
ALTER TABLE public.roles ADD COLUMN IF NOT EXISTS description_ar text;
ALTER TABLE public.roles ADD COLUMN IF NOT EXISTS description_en text;
ALTER TABLE public.roles ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'roles_scope_check') THEN
    ALTER TABLE public.roles ADD CONSTRAINT roles_scope_check CHECK (scope IN ('global', 'branch'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_roles_branch ON public.roles (branch_id);

-- Seed the two legacy role values referenced by users.role that were never in
-- the matrix (kept so the role-guard trigger never rejects existing accounts).
INSERT INTO public.roles (role, name_ar, name_en, permissions, scope) VALUES
  ('kitchen', 'Ø§Ù„Ù…Ø·Ø¨Ø®', 'Kitchen', '["dashboard.view"]'::jsonb, 'global'),
  ('customer_display', 'Ø´Ø§Ø´Ø© Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡', 'Customer Display', '[]'::jsonb, 'global')
ON CONFLICT (role) DO NOTHING;

-- ============ 2. ROLES: RLS (admins all; BMs their own branch) ============
DROP POLICY IF EXISTS "auth_select_roles" ON public.roles;
CREATE POLICY "auth_select_roles" ON public.roles FOR SELECT TO authenticated
  USING (is_pos_admin() OR scope = 'global' OR branch_id = get_branch_id());

DROP POLICY IF EXISTS "auth_write_roles" ON public.roles;
CREATE POLICY "auth_write_roles" ON public.roles FOR INSERT TO authenticated
  WITH CHECK (
    is_pos_admin()
    OR (is_branch_manager() AND scope = 'branch' AND branch_id = get_branch_id())
  );

DROP POLICY IF EXISTS "auth_write_roles_upd" ON public.roles;
CREATE POLICY "auth_write_roles_upd" ON public.roles FOR UPDATE TO authenticated
  USING (
    is_pos_admin()
    OR (is_branch_manager() AND scope = 'branch' AND branch_id = get_branch_id())
  )
  WITH CHECK (
    is_pos_admin()
    OR (is_branch_manager() AND scope = 'branch' AND branch_id = get_branch_id())
  );

DROP POLICY IF EXISTS "auth_write_roles_del" ON public.roles;
CREATE POLICY "auth_write_roles_del" ON public.roles FOR DELETE TO authenticated
  USING (
    is_pos_admin()
    OR (is_branch_manager() AND scope = 'branch' AND branch_id = get_branch_id())
  );

-- ============ 3. USERS: EXTRA COLUMNS, DROP FIXED-ROLE CHECK ============
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_locked boolean NOT NULL DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS failed_attempts integer NOT NULL DEFAULT 0;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS lock_until timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_login_at timestamptz;

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;

-- ============ 4. AUDIT LOG: IP / DEVICE ============
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS ip text;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS device text;

-- ============ 5. ROLE-GUARD TRIGGER (custom roles + lockout safety) ============
-- Keeps every existing safeguard (admins only manage admins, no self
-- role/branch/status changes, BMs scoped to their branch) and adds:
--   * assigned roles must exist in the roles matrix;
--   * BMs may only assign global roles or roles of their own branch;
--   * nobody may clear their own lock / login counters (except the lockout RPC,
--     signalled via the app.login_guard_bypass GUC);
--   * unknown callers may only self-register a fresh cashier row or update
--     lockout counters (anon-callable record_login_failure).
CREATE OR REPLACE FUNCTION public.guard_user_role_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
DECLARE
  v_caller_role text;
  v_caller_branch uuid;
  v_bypass boolean;
BEGIN
  SELECT role, branch_id INTO v_caller_role, v_caller_branch
  FROM public.users WHERE id = auth.uid();

  v_bypass := COALESCE(current_setting('app.login_guard_bypass', true), '') = 'on';

  -- Assigned role must exist in the matrix.
  IF NOT EXISTS (SELECT 1 FROM public.roles WHERE role = NEW.role) THEN
    RAISE EXCEPTION 'UNKNOWN_ROLE';
  END IF;

  -- Unknown / anonymous caller (e.g. anon lockout RPC, or self-registration).
  IF v_caller_role IS NULL THEN
    IF TG_OP = 'INSERT' THEN
      -- Self-registration: fresh basic cashier profile owned by the caller
      -- (RLS already enforces this exact shape).
      IF NEW.id = auth.uid() AND NEW.role = 'cashier' AND NEW.branch_id IS NULL THEN
        RETURN NEW;
      END IF;
      RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;
    -- UPDATE: only lockout counters may change (record_login_failure as anon).
    IF NEW.id IS DISTINCT FROM OLD.id
       OR NEW.role IS DISTINCT FROM OLD.role
       OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
       OR NEW.is_active IS DISTINCT FROM OLD.is_active
       OR NEW.email IS DISTINCT FROM OLD.email
       OR NEW.username IS DISTINCT FROM OLD.username
       OR NEW.full_name IS DISTINCT FROM OLD.full_name
       OR NEW.phone IS DISTINCT FROM OLD.phone THEN
      RAISE EXCEPTION 'PERMISSION_DENIED';
    END IF;
    RETURN NEW;
  END IF;

  -- Only admins may create or modify admin accounts.
  IF NEW.role IN ('super_admin', 'owner') AND v_caller_role NOT IN ('super_admin', 'owner') THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: only an admin can assign admin roles';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Only admins may modify existing admin accounts.
    IF OLD.role IN ('super_admin', 'owner') AND v_caller_role NOT IN ('super_admin', 'owner') THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: only an admin can modify admin accounts';
    END IF;

    -- No self-demotion / self-deactivation / self-branch-change for non-admins.
    IF NEW.id = auth.uid() AND v_caller_role NOT IN ('super_admin', 'owner') THEN
      IF NEW.role IS DISTINCT FROM OLD.role
         OR NEW.branch_id IS DISTINCT FROM OLD.branch_id
         OR NEW.is_active IS DISTINCT FROM OLD.is_active THEN
        RAISE EXCEPTION 'PERMISSION_DENIED: users cannot change their own role/branch/status';
      END IF;

      -- Lockout fields are system-managed (only the lockout RPC may touch them).
      IF NOT v_bypass THEN
        IF NEW.is_locked IS DISTINCT FROM OLD.is_locked
           OR NEW.failed_attempts IS DISTINCT FROM OLD.failed_attempts
           OR NEW.lock_until IS DISTINCT FROM OLD.lock_until THEN
          RAISE EXCEPTION 'PERMISSION_DENIED: users cannot modify their own lock state';
        END IF;
      END IF;
    END IF;
  END IF;

  -- Branch managers may only manage staff of their own branch.
  IF v_caller_role = 'branch_manager' THEN
    IF NEW.branch_id IS DISTINCT FROM v_caller_branch THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: branch managers can only manage their own branch';
    END IF;
    -- Assigned role must be a global role or a role of this branch.
    IF NOT EXISTS (
      SELECT 1 FROM public.roles
      WHERE role = NEW.role AND is_active AND (scope = 'global' OR branch_id = v_caller_branch)
    ) THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: role is not assignable in this branch';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_users_role_guard ON public.users;
CREATE TRIGGER trg_users_role_guard
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.guard_user_role_changes();

-- ============ 6. LOGIN AS (LOGIN_AS_LOG + RPCs) ============
CREATE TABLE IF NOT EXISTS public.login_as_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  admin_email text,
  admin_branch_id uuid,
  target_user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  target_branch_id uuid,
  reason text,
  ip text,
  device text,
  login_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_login_as_log_login ON public.login_as_log (login_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_as_log_target ON public.login_as_log (target_user_id);

ALTER TABLE public.login_as_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "login_as_log_select_admin" ON public.login_as_log;
CREATE POLICY "login_as_log_select_admin" ON public.login_as_log
  FOR SELECT TO authenticated USING (is_pos_admin());
DROP POLICY IF EXISTS "login_as_log_insert_admin" ON public.login_as_log;
CREATE POLICY "login_as_log_insert_admin" ON public.login_as_log
  FOR INSERT TO authenticated WITH CHECK (is_pos_admin());
DROP POLICY IF EXISTS "login_as_log_update_admin" ON public.login_as_log;
CREATE POLICY "login_as_log_update_admin" ON public.login_as_log
  FOR UPDATE TO authenticated USING (is_pos_admin()) WITH CHECK (is_pos_admin());

GRANT SELECT, INSERT, UPDATE ON public.login_as_log TO authenticated;

-- Start impersonating a user. Super admin / owner only. The caller's GoTrue
-- session stays active (the app swaps the resolved profile); RLS stays scoped
-- to the admin, who already sees every branch, so no privilege is widened.
-- The log row is the authoritative audit record for the impersonation.
CREATE OR REPLACE FUNCTION public.login_as_user(
  p_target_user_id uuid,
  p_reason text DEFAULT NULL,
  p_ip text DEFAULT NULL,
  p_device text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin public.users%ROWTYPE;
  v_target public.users%ROWTYPE;
  v_log_id uuid;
BEGIN
  SELECT * INTO v_admin FROM public.users WHERE id = auth.uid();
  IF v_admin.id IS NULL OR NOT v_admin.is_active OR v_admin.role NOT IN ('super_admin', 'owner') THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  SELECT * INTO v_target FROM public.users WHERE id = p_target_user_id;
  IF v_target.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;
  IF NOT v_target.is_active THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_INACTIVE');
  END IF;
  IF v_target.id = v_admin.id THEN
    RETURN jsonb_build_object('success', false, 'error', 'CANNOT_IMPERSONATE_SELF');
  END IF;
  IF v_target.role IN ('super_admin', 'owner') THEN
    RETURN jsonb_build_object('success', false, 'error', 'CANNOT_IMPERSONATE_ADMIN');
  END IF;

  INSERT INTO public.login_as_log (
    admin_user_id, admin_email, admin_branch_id, target_user_id, target_branch_id,
    reason, ip, device
  ) VALUES (
    v_admin.id, v_admin.email, v_admin.branch_id, v_target.id, v_target.branch_id,
    p_reason, p_ip, p_device
  )
  RETURNING id INTO v_log_id;

  RETURN jsonb_build_object(
    'success', true,
    'log_id', v_log_id,
    'target', jsonb_build_object(
      'id', v_target.id,
      'email', v_target.email,
      'username', v_target.username,
      'full_name', v_target.full_name,
      'role', v_target.role,
      'branch_id', v_target.branch_id,
      'phone', v_target.phone,
      'is_active', v_target.is_active,
      'is_locked', v_target.is_locked
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.login_as_user(uuid, text, text, text) TO authenticated;

-- End an impersonation (logs logout_at). Only the same admin can close it.
CREATE OR REPLACE FUNCTION public.return_from_login_as(p_log_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated int;
BEGIN
  UPDATE public.login_as_log
  SET logout_at = now()
  WHERE id = p_log_id AND admin_user_id = auth.uid() AND logout_at IS NULL;
  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.return_from_login_as(uuid) TO authenticated;

-- ============ 7. LOGIN LOCKOUT RPCs ============
-- Client calls this on a failed sign-in (anon session). Increments the failure
-- counter and locks the account after 5 consecutive failures for 5 minutes.
CREATE OR REPLACE FUNCTION public.record_login_failure(p_username text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user public.users%ROWTYPE;
  v_new_attempts int;
BEGIN
  SELECT * INTO v_user FROM public.users WHERE username = lower(btrim(p_username));
  IF v_user.id IS NULL THEN
    RETURN jsonb_build_object('success', true);
  END IF;

  v_new_attempts := v_user.failed_attempts + 1;
  IF v_new_attempts >= 5 THEN
    UPDATE public.users
    SET failed_attempts = v_new_attempts, is_locked = true, lock_until = now() + interval '5 minutes'
    WHERE id = v_user.id;
  ELSE
    UPDATE public.users SET failed_attempts = v_new_attempts WHERE id = v_user.id;
  END IF;
  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_login_failure(text) TO anon, authenticated;

-- Client calls this on a successful sign-in. Resets the counter/lock and
-- records last_login_at. Uses the app.login_guard_bypass GUC so the role-guard
-- trigger lets the lockout fields change without opening self-unlock.
CREATE OR REPLACE FUNCTION public.record_login_success(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id AND NOT is_pos_admin() THEN
    RETURN jsonb_build_object('success', false, 'error', 'PERMISSION_DENIED');
  END IF;

  PERFORM set_config('app.login_guard_bypass', 'on', true);

  UPDATE public.users
  SET failed_attempts = 0, is_locked = false, lock_until = NULL, last_login_at = now()
  WHERE id = p_user_id;

  PERFORM set_config('app.login_guard_bypass', 'off', true);

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_login_success(uuid) TO authenticated;

-- get_login_email: reject locked accounts before returning the email.
CREATE OR REPLACE FUNCTION public.get_login_email(p_username text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user public.users%ROWTYPE;
BEGIN
  SELECT * INTO v_user FROM public.users WHERE username = lower(btrim(p_username));
  IF v_user.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_NOT_FOUND');
  END IF;
  IF NOT v_user.is_active THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_INACTIVE');
  END IF;
  IF v_user.is_locked AND (v_user.lock_until IS NULL OR v_user.lock_until > now()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'USER_LOCKED');
  END IF;
  -- Auto-clear an expired lock so the locked flag never goes stale.
  IF v_user.is_locked AND v_user.lock_until IS NOT NULL AND v_user.lock_until <= now() THEN
    UPDATE public.users SET is_locked = false, failed_attempts = 0, lock_until = NULL WHERE id = v_user.id;
  END IF;
  RETURN jsonxœì}ÛrÉ•à;¿"CÑ ’’Úî†¬Ž…HHÂ4EjªÛ
‡S
`5‹UpU=žˆëNx_÷öÁ3±á™Ý˜˜ýéu¿dÏ%¯uAÔÅ…£MTUfž<yòäÉs=œÌ‚p4ˆO~ð‡Y½–Î†C?MkM‘%3¿)jþ¹„ðób0Ký¤E?7º{7¾øâñÆÆó£ÎÁ±èþ²»ûú¸+Ä³×»Ç=øc:;	ƒakâgƒ0žÑ€×3ÿmÖÇ‡Â‹â¨)¼YvêGY0ô2ýmnŠ'Ö?ñUK^ m±ûº|øróèp¿+:ßwŽºÎçØüøÔIú"HÅ…#ìYx/ˆÒLdòm*Î½,	ÞŠ:>ö½‘ˆÇÂ§^2Æ#„=]ž™)À›ÆÂÃ§bèEÂKÓ`‰á,ÍâsÙÄIâEÃSè9ò&~b‹ÝyÑ•˜„ñ‰2|qÒ_é0žŒYŒà‰ˆ/#ÙWKt/üä*;¢‰ðÃÔuBãvˆ‰¼s_Ì¢à73?‚•c„¶ðM*îó`„Î ’P Þ_õ`²)öÛ LQw0žM qÓÚÞþùÖöÎNkc÷¨ÛÁµ=GÝWûÝ®YckiêBLy®q“~Oaú—q2²ga8 °ñ™Øë>ë¼Þ?¯÷÷ùB‰ó®6DHý¤Æ0jÁHÌfðŸbA:ð†Ypá‹“:ƒUPßYÓ7y(6GÝã×G}ñCG'ûƒç¯;Ï»bN'éoÂ>PûQïø6ëtàÁ±H}/¨¦^v*žHêßèôÅ_lìuw÷Ta\ÞG
ôÇôDÏ—âªX?Fëön~4éð¾´½0„‘rË§’P³Á0S{˜ìûAÿ"°¿xÚ}Þ;€Çýî~w÷˜¨º)Ì:õ`Ã;05À<;:|©˜Óï÷/º°¿¡ùIÕÁ¨Ì†é=šLcXgÜ•u`(/º8¾ D »û}øÊÅÃQ“0É-Zƒ½$½¾88dZ0ýÂq·w[Œãdè¶,qxu€tÌ ¨€È&_{ Ä~÷‹o
piX„`eú¬äácXbâIÃÞµWÝ£—½~vî`¯{ÐëîÑ†âµ‘Ÿ1¯¯=-acq^Éí.xu`bù©×©?8`ªÍ”	ûÀqº)Lˆð‚CA[X…Æ›Ú!NÃ…\œœ˜ÜA&¼á0žEYZ63{µÚOò«%i°»±Ê9
‹=Àða|	LøÎ´óºäÃÞ,@¹]úÊ¢~›Â]¥§HtëM§bšÄã (¶Á­ûË^ÿ¸/êrkïðFµŽÞ¦È’µ¤ËM¾û²ÓÛw¾í¸ÓžT	÷ø``1¢_KîÜ#ìÍÂu†ašøãàmS¤^‡ñoýQSœƒ !NÔùí²wXÒÄŸøoaóøÓÐúu‚:÷Ì^õaìÁªÁCä'½gusÆÜµŒ<ƒ¨$«KtÀ‹ÿ³ÚiÀ?øûWÿÙÛüíöæ×­Áæ¯q²üÏšÒÐµÿü+|qòxÜbA\¶fÐìN©†?jâw¿ƒ½v’fI]MdâGØ7£ø|0#>ßn“È j›5	þNS|uJ°à30Ýš^÷»G—Ý
’PÁLp´t
Sm·a­_$ÈÒœäÐ–'2À{?JAjS$Í!žáûäjšÅ5u*:Â /Î¶ä¾=8üþ`Ð=::<Â†ªñ…¤î(Î„y'¡?* DÝà€¼^“úI¯E=Õ¿€U†H©ÂïMñÅÃFƒî fnî¯Ÿ4ŒC’Ÿ^÷{Ï-ù`=#¥o«ºKÂû&LÞ¥—À–Å»‹ë ÓÚ þ[¸ÈãNÝHÚ÷¹'n‚Ó'Wô¢þôe[Iü1“›ò$ç+ž©/ÊsI™›0Ha†ÏÕÛ“°\_¼S•°Ú…D(|¥zôºdÔO®B8
ã­†×sÌNY\ù[# Zv°HýADÊ¶–›hÞ–~î¤dßV”'¶º ÀóÓ³ypG¸œ¼É¤>lì0Àÿ {Ý#ñô¶€®‘«ÛßH^þÝ†Þ,ê7µŒ¯8³nø	¶"/D9;À[£€Ûí¥ßÌb¸õÑ½²N_ÂfçÑ€9*|…àJîvú]‘ÿH‹f@¢†WpÀ vÉ'0üÚ¶ü·Yòõ>Ëw¥z`áÀó/¬k´7rß{3kHGQìqáYsR‹"ùq@¤™VEkdp…ÆØ#,l4’sèÂË Q|Yoä“’.`Åg~dæU2o£âú/%¤FXô;îuù—7l1œ%	,À\È½Ëˆ´ƒsØÆƒ‘—yòcuú”1ŠÈ¿@Û	95¹Œø—zœÂ//I¼«_é·¿æSüW¿¶üdŸÏ¬ÒµF¸ˆ o˜ÖœP÷ÎXêÇ Ö)HMÔu –Ê¥ ¾ ]K7³éh‘ÏPÿÅÑÕy<KÕ‡ÄuK>LÓxÀBaÉwÈL ›¢Ä§‚ˆ‘„¤ËÇ¿ä,)±ëx!®“!§VÑAÛ–Ï,ëµ’§H^Tƒëo JàÔ°ûP‘_t¿ë¾²Ø_um®Ö¬ÑÛ4™4•nµlã7Ë6t³lÛ6ó»³énÂfÕ^+}¡¶T³dç4Ë¨¶iSNÓ¦¦KMg­ùØ©UêŸ”Ä
‡¾VAÝ½Å@T Ñ‚PÄ4†[1)r¬»n¥8[ëÀEà˜ÏXën\§»Žžü]kˆï:û¯»}ëÍ“ÞÕ>„h	 ød$ }
d¢<ÏP|xpÝQÏL9ÏéäË›I	R…~µ0«†Ûm‘I7´!ECWÉõ!¤O7ÙO¡—f”HAtí±¿R.¿°„ó¡¹¸1x¬Œ•#K¶	¯©é¨™#óü™_œyì’ÑYàŒA	g>)Îh¡{qöh¥æðÈ À#ímO= þ$µ[Ff‰@9ãDShs"_¬7ªÞ¢MKoTª¸SK%Ü´íP|±[hy¤áU“—áhwýån÷YÞhÂÊõÕú¯zõû¾_ÞÌÜk[™Áÿ‹|½©Lsü-Â×Ø‚¿ni;Ù_vŽz¿l‹ƒî÷¢ÃP˜«|¿`îL§~4JIC3eš…*øé\›úÉy¢h
Çi&¶„ÿv'øGp.ÿxuØÇžFAJ:sxÂâ“€&C~&>5nH[®Ø{ª4F)?zf	P=Èyg"žeØ_<¦w'ñÛ–è|-< y4›JÛräƒGGý4e•š„-¸[{‡ycã™eÛ	áã”éÃXì`ø¿dEÌæ7P«¥ «ø+ˆñ@MÝQïÀ–Î.Zôþ¶êÌ7¬ž	Ò÷†§õÚTšmâµ_Ýy£%Qy¯y/E½vKýb«;ìtýîh6ÌÔƒ_×ÚmHkqP½w
R¨¯•V<ŠÛÎêˆWÞ~Â$€Of	¬yj”Î¦Ó00 Ç—&%kØÿÒCÂ¼áóZýÖÀ°0VEŠ82Ot?×Ã-ggôÇA\NÕ¨iCm@ì~Ê;mBùÈPÏª€½Õš-µ …¥."(gN]cÇÁ[—×x‘x!´4èzvv?ö_Ñ³×¯öÐÃ§ ¥G·ûHx"»–L÷°³ßíïv%cÇè^¯Ü;@›WèŸ“QQ¯îÖ©@Š´~
^:À³ªnHÂ7vV§^y"ECxìÒ!Ï(ãa¡DSœµ-ÒÀûÞ³7b:IR47&~{#ÁW5IÙ\á?ìïe$)”XÚbûÑ£Arâè{æGpª·ÐÇhÕƒæ¥©ÛþÃþ ô–8zÚÙö»@Ön5“ˆdhC€ðx¦î"ÒîF x³QµD'¥pòSâ“ÞÞ€4¾h‹D«)Èc~rá±® ã	|vŽ!G¯vÅ8Œ/E„ÆÎ’\Ç³ˆÎÅ$2ïJäÂš(îÁÞÃËB(Í†˜EÞxr?j´6xzBì´ªX²Áñ[ 2 %²Ä¿ˆÏ|ñêõÓýÞ®¼AJÌÄ¥—‚ š@_áwÿp(e‰ì¼qEjº¡\‡cáý}ýä‡ÄÛXëÎÐaQ,ëÐoù„òS'Œžùþ”$\t/lq‡Z"Œ'Zž»ñ_õ$;0~qf®ñ,‰Ë$€…â^¡`—)ßM5ô€‡@«þ0Ž†Aâ—Ä} ‹¬bF<h
ò°ü xœxÑ™|b{>}¸ãÐËÄé±³ñ#í&RT!wº¯PIT¤{ËN½L¹Q–t(¼Þ®`ƒä4`Ë¡O-Ï8KÐµDáQŽp_î‹À¿äáðNã_ £ûSdè¥„>­8ª…ÂZÊ}
P-é—€Ñý¾\‚i‡G@fm6‚Ç	ZÂ3VeN®¶´¾%(ƒÕ º 8b zÒ5 Á% ñ›P¸2¼Éö/~Úbyð/,n û©ã¤7É[-æap†`Ðå‚|½¢èØB"áV{HMêg-!OöÁ,
²ˆAýÆ¥#<©„¾‚»øeI·ƒ:^Ç0jsBX†­©Ež	Þ#u×ò™„æç- 	úcOQ}E¼‡AçÎy7’$HÓ¬'MÍ44a ìçj9‰}¼IÃY
L1DšÄ³É©€¢µBÀùª_º˜ *ÐGÃG‡—À±ÍpµF‰wé'›™w`ãƒ‹ÀC¢‘Óûª%úØ…ÍR½æ¶À&êO»pí*¥pª	. P‰Tjé¾n	Ü>ÉHzœVñk–œüTFx£ŠÛä}ÆÃ3^OZYÏìÍ$ hCñå& u¤‚²|»÷åˆ;Û-Qâ-‰nç¨C`ä=¢Î•µ>¶`e¨7õ3¼×[„ÁûÏ·ž˜ÍÍP¬ôT_ñùÝ•Ÿnm}œ0:êGÝï¿íæÆªá‘£ÌÑ`•ÀZg•­½²õY,Ü²XËà7«£V9è®äTýd1›´^D%?ù˜-—Úe‡¸¨Ÿ¨Fs~¯Ës‚1$–‹â‡f¸€©†0ß£ABàøÅÈO‡I0%<˜ïœ¸r4ƒ›h0”QþØOühXPÁ¦®†pÃ*D>®¢(Kæã*ŽE§Y£Ð
%†»ZOš©<	Xó‰Xpƒ.H§î„A(…¨úéº.çjÙ_ô³'bûöŽë½ƒï:û½½Açåáëƒã¼Ÿ¹­a%¥¹1/àšÍReÓ¥9«¤…ŠtÂ*J¨B{íË>[2NÁ14-;Ù£îîáÁno¿Gwß\½Ï`Ú{
9Õ_|#j(›ÔVÈîþaÝþD‡"³‹=vÙ²H¯Íª@ú %u"5dðEÑU	çôœN/ËN‘ÛÙß?üÞ‰…p}]F'E/¾i ÑwÕ}!fØR‹æ.›&×Bô½åöÑ˜tÛç#gÔjåâgì&+@éÓ£ÎÁî‹ÁË^ÿeçx÷E9\)Z)iOº®…}ÈÜ0å¦°xqShvg"q#V‡)ëeÉÆnø|ÓeðM›‹£™têŠÙ5ÅƒFÃ22£{µYZÉ_å¤obç”-iÃÉ¿Ùˆ<ÏÒ¹ìúÃúõÙR8xÖéíó–/1xÒ**%¡>d`z×¿9ÅŸ½öùÃÇ¥#_ªWîˆ$†}BÊín4¼®²VF#¸îù_ßyÔ|Ð°Úê×‹œº’}„-$Ù°UBÇaKÑd"Ù3þ•–Î:ž
}šŽ X‰¡Øòã2¿5ÙiåÏ{sOÕ%Þ¤E¬jKY¶äÙ«wfqød¥î>ÐÈÇ,û¡NÙõYú©Ÿ¥DŸÚQ*Q‘µÌþVØO
û9Ï`5$n²–Œ&¡©–°9¨Ì'`+É¯8*ˆÕø2þ‚Zd(Dš_Æ—¾$S&ãžÌ…~e›Ù¢æõ™Ð>Oî‡°•?edŒƒ’÷Ä–*±4²ðÿ$‡|ý•M>O
Åö;µzò q99nÍ…ºÇGoˆ	êìîÒ=«4:¸¸Ô£Øçx62™SOézë  V){“dD}Ö C?>ÓT–«Î8àì73 €ˆHE‚l>ölrb!­ÿúefäŸ™ØÄ5&þ(È(µmX§ž}|vË²»ÁÌ'‰WVÀhWšŠ$#têSŠßk‹³;™¦Ø¦É2¯²{¾5ùðÅÜp*‹rljÍÅ ”wL–0tSæiÓ¥ ‡&!£rJu]Ê"Í¹Ž…Ü¢E˜ÃFíÃ*îºxš“^ç~Þ÷‹yæÇ²kÉÙÀ>šî-‹3 Ã’Ë€¢žÊf‘:nw•(UœÙ÷ë/ôèÎw3ókŒåmØ½;ütmO0H)m´‚›@g{ïÍ`÷ðå«ýîqñP®E®Šü}DÐîþþúJò\I>Mõ^Þ1©Ž£óÞZ÷#Š‰¢“§òÍg!’Ç6%•Ûa‹wÄI›yÖº˜šC:ÒŽ
Æ%e8æÝ–ô&APr›ÍÄõW–„ÄËj-Î$X§W ´zTß
¬0Ä‡¯áŽðlð´³œÁ¹#hµœW|N¼#Ì’tÇÓ1ýÅ³ƒCGA4á=§*ÙÏ•áR•šbzòÂ‰á(Ö‘%NüìÒ÷£œ H‰+à”ò”KsG›%–ìB±Mð‚âÇÊÀ*Êº‰(Xè£Ö,ëÙätX~-y‹+Zs6œÕ­óœtèŸ°ð¹zczÑW­]í¤öáMå9ØXWïf”ï¡¶€—¤äð¿ª·˜LÑ˜ÕK>Èâ¹¯Ãà<ÈÈ¥fõþÁövÞZ`dú›Êó¢ÜyŠ	5±¾ÚÇ;‰/Mt1üh™¨F®¿›wûÖÑÅ²KtûžÕ1’ñ/F¨ùkÀŸ3-§Ö©êµ,¹Þkéˆ½YËd™„IÑsŠÔ3Mõ´d31(sœêfôsÃ=@·)æiÚï>;vÔr,ñÌP7cUœmCñ?ÏQYTGR*œœä	t\ax`üÆê5³…@¨ÄFn·Hßúw½!xÔ¹¦iË±A-Ä:-$;-ä³'z8-í;Ìº·Ûôö›'öFqºP»c~¿xb66×Ôéåi¬÷²w¬vì" à;ç„Ž«ìÄC'¿¶íÊzßÎ Y×	 ¼+¥XÜä$±+w(Âþ”;*zA:Ž©½£ÃWâÕá~o÷•míÊð¨6÷„á¬êÙcÅ…e7¤€Ci=Ï‡†â&ê¿»/º»ß.´OrÓ’›eîVy<wê¹½ÄÔhHS—XÉÔ9µÙÍú@íÈ'õÖÍQ»@CBí^5µÌVp¨ILÖšºùû&ÛÍ´²ghžÎÝr×5^í¶+Lpeo9$,Øxep©ùh–{i94/Øxe›qÉùÓvTñ”Ð«­äNL ÅiRÚ 4ò]©Ä®‹íUÕ§ƒõpþNÛtÅû47õÕmÓ%æ¿PÓÕmÑ%¦þ) Xí±%¼PÓÕmÎ¥¦Ž{S6‹º‰q¾ÁA©ÙÔçn¾ùMW»ùòs[Ùæ[fþ5]Ùæ[fêŸ‚åZÁ5]Ùæ[nêTûD…jÂî3ë£‘®âò¶Ê·T~ƒ±›mNÓ§ótîö¼®ñj7haú‹u·ƒTNÌÅíbw9Ü,Øxe›w•hù”EîØåeÁÆ+Ûð«E2•LDÔuZ‘œÁª=mõlîŸ×pµÛ;7­•¿7ŸúW¶{—˜õ'€Z¹nŽÚ®l.5kÜj&B]ÿy“Í¦ÙÓÓçn·ùMW»áòs[ÙŽ[fþ5]Ù®[fêŸ‚åöYÁ5]ÙÞ[nê–}âdD·Nóèº]Xh< CO‰
Ú|R@×2â:è!´m¶™èš
n6ÌXãÊñÒv²¶Ô/ýÄ§T/íBš—UBgÑ¢„-o”SÎ¬”JE¾»‰¡Ž»-!+~±ˆÉîš.>„ñîúj3Úè3•6÷©¼³AÕ€Û–÷é<+:¥ häiJÜ|3³áRq£.îØ”ø‰®ÁšÄ\+èR$v£.îØ¤úÉ®Í§í¼`…D^·f×¦Ç²E0obÜ‹v¶bS)+[]«g³Ä\LuÞê.Á¬o·Kv¶:;×§¹?RÊqÔÛ‘Ò’­Î¢÷©®À\æ¥_lÏÍ¿(súÕ•A.ï¢ÊµˆÞùW]Ì8¶ò‹Å"Sšªc’¢'óm¥–>A´nÞÖk-ÃfËOAo4…k-³½¯Ó^`‹îc[ï®§”;ºõÜX,OéGˆ`ÀÀ	ÊÂ:P@ ?Ta2OêF>Øw#Ïq6òÁOr±¾Ñ:¼ã"»ßë9«8{ÃR•`s‡ˆz\ø-ÔÙA‘G^¿kÉÔöz}ÊÚ0°ƒÝb«2f Ó‘-äÉMô}|Ô{þøª!ð,™ÖR¶§t´(_kzV]T5Üp3ÔæºÙ@jîvv_ˆ£ÃïuŠÌ…óNÈ¹"Q.œh1Wo¦4¹…,¹ž¾Ë ´
›sí 7¶}jçáˆÖÝxvJ‰mÇuüVðøÍ«.G¡GþåÀË2ÿ|
,!Àäj›Hè§vxì"µÉíŠîf¢·Îzi øÂ1s%uë;2Í8®²Ïµ½(‡7×ƒ—A4Š/óäåŽ69{²¼y“ó";`¦Ù#GñÒC|·ò,Kâ|ó_|Ã±ƒ+˜en±Úª|ÉŠâCä›ûbG#ÛiòÍñ¥Ä‘¤ÕÜP‘ù.Ÿäº¢šc3Od£5i0	P&ß/µ/'¡–5í¬(JM4áý~·
¼…@«î9ÏkZSgãK/”}›³WçÝ^%L‹ž×˜u¦wudÛŒÌ.âî–“?sŒ‹>”¼Ën{ƒÐþEŠÇëíÄÆžÞ¢ºHŒßCYÄB¥yÈ‘dºÎIäê¦[7¹|û‘eçæÈK*…Rò:Þ5O¡X.?©©zjU¹¸\Í-EÚ	Å„ú TØ)ošwôí)×åMŸâ®ø$ªó|9ovÁ¶½x˜&?£‚=_¶œÚmÁ³ Ó>"<hvB.0– aýÆTöŽÖÛíì‹g½_‚AFvw-Ê–¦*lˆí‡_a	FÆ5ç2#1 Ú©àTI‘`ï<;ê…¾N±ˆ‰mø*[PÝŠSxî'Mó ¦yž6©ì"Vè!'ôŒä›g½g‡&WŠSÕ‹“Î"èKÔ)•äFU9ä¨Ñ	’$ÑŠø"ÖS‰Rù,îññ|Oâu
f5	| TÁãóó Sà\ž"“¥eµKu`¢!|áùÞ¥wµ5òÃ€
1²N½”k®°ne1Æ`Ÿ±ØOÿ2¥eyšÝãQ¦{T÷hê]a¡NñÁßx!m
]p©3”4e‰ŽËÓ a‡ÿDÒrbØÇ™-hÿ´"º#^+t)G>¬Å$Ý!tî‰Ñl’Ò€ÛoÁbÌ°<’i¦‹_Æðø"€½¡¦ ó8i"m~ˆÙ"Fø­Ði@kª’	1˜É"ÌzY½qF%v¬ÙÉ¾ô$UY¨cŒ7:&¬çñ…LÝÃãøl6QnÊO‹Œuw¾‡Õ¯^`š™š#‘vŽ¢úkÇPÑYžŠ{Qlêë`î×-3á{ã²ÕRSáQZÆ“YF¤M‰zxí½ù´p]À6ÒÄžÿ*ˆeÓ<WÿÉ`{¥jJÀ‰2:AŽW ˜žÂ¤âsÚ¯Öá…gr¡yÿ:ËŸõƒID…X±·YÄ…ÂF¢¬¸OG
³ÐÿÿþË'>DiWL
€wcØêÞÐ¿ƒ*,×K’6‡‹b]Ä@ºƒhv~‚l…ªi’YÀSÕz¨‚tìg¤¸€ã8µŠEàãÙ‰“°’ˆçtAe¯²«©¯ÁÊ¼·%ßžÄÑ,-y^oê£’ïävœûÙi<ÒƒÉÝ¨~“gÉ’Þ’âQN0W¶BÍ™Ï{=ýUMÑy'%™èµ=Us}¢¾‚¹`cÉT}$Ê\SCÈÒÖÖ•ÁA?B”ªºÂt«0ÆóÑofçŠ°’ù=Ò™þ‚Œqš·tª¿
ò²³2éÌa¬N5hïŠ”€þÕ¯ebô`ÝTR¯¤SÌ¦fÍ;=ÅÓ½ä»a<IËG-Ä¶l›ÛW…t1¬ða?U¶Ã½æG8ƒ\.w|‘àÑXÖa¢pë•=÷’ªtðC‘u5“sJ*ÁV¿Â,M¥DÀ)­t.{C³rÓ2Î­öÂÌÁ
‘°o  ›L²Óºüª±šú/Ý—¯Žßv;Gsk¿äjÖëL”ôxÉÜ{Ô?œ\R…¤qÈg*k)g‰®²¦ÐtmZÄë’ùÙoñsL}”4~€„Ã$˜`"5":äO|¬§
¹“øh¥ó&jÑ??Eü±H¦ïQ€5S²ä¡“M÷÷Íç
jÜž)û]0zF>V 8§[Ezë>”¥/I„CrâO@^ÄJ}dØ‹¥Š”}J*ü^e=rIË:°K2¥Z)_ÕQŸë/ÿl3ÕÏó’An§Ì[zgòßQÝÝ«NB„M"™hG“¥RÙZÛ+G<EÊM —VOãÁ[õ´r:°å˜Ð›zÐÑ{vì¤0urÂØxK"ú’WÔC¬“L×TÚ™—§i—Éž¬ä¥ùô¥ŽÓ¶‘•g6?›Ot«FÀ
§?çÑ]CPù1¼l\¯âª9ß(ë8.6eÖ	·Ñ™ß ;V½<G³B’¶+/†ª3y©Õ¥—Ã«2Å]¦‰;“
bÝ%#Ý™\SŸïw©7Æt˜¬œpé‰½Ÿ`~Ly—W~Ö2¬]êù4¬.;7' sKÐØ°Ød÷³±Q²aõpnJÒ^Ó¶AÌÖ6Á"Ä¼<+ Óœú©ŠRµjB¦&PckŸ¢ºH+Ò`ñp˜gÐ±¡æ›Qrß½åÊ•D$‚ºµßŽg±†æ›Ã\¥%$)Â1§VÔ¹lèµúã…œ·hp¢I0ØØW±ñvO*›6ëÝd=rº]É½ˆÄJj#¥1;’(ô±1 ü”¡-³£h96o#qîoÀ!ëÜëæ7ßÔÌ‹Zƒ/¬u#}ù‚&Ú:cµUï±¥¾´o»9 u¿ÈÉÖ·­®øç¯;ÇpgÆgÖ$šÎd¤æn(u&ç$9åÓèØM­NW1WG‡{¯wíM¸Ä<Œ¬_FÀˆNƒ)«3eÓEäÞj	åfh¹V¬-È·Çœ%ÜÚ,¬&s»”õ¯*—åW4MÙºuÅ"¥U°O	¼7YLìžîJPé¨õžÀ£7õïrwšQküÂÞw+Ùrý×Ïžõv{ÝƒãAÿøp÷ÛÅÑ-êø
-°
Zz¡Í!ôÎp8;Ÿ…¨Þ t÷ öÆÀ;=âÂZ×R—õééž0g5Ö)i7¿FÅº’êL¶1‹ji±Ú†wæ5\ÀBŸ“¸\/ã¥¹ïs,µÀV‹¾zÖ’ÿÔ…Ü¡€RÈ*Û–×°T[ÔXÿº/Ž•Õ«aÙ,`RËã¸{˜ö»Gßu6û½½®xÑíàìøð¸³ßçØœYÐ¤áÒˆJ} Z*·Òõ(è½]Ü;˜'”ë™S:·{óö±ƒ¿<åYÚ<¹÷`HçmB•=U:-ŒÖÏˆ2ÊQQúB¸×Sš…­B´èƒõŽ <¯cÝš¡½rZV­mÜ;ÛÛî2ªÉZõi”öˆV/ìÐ®3@ŠIÝ°lµ,«Z)»/)i® Ú”#˜F.Ñ9ö¶¶m^F³¶MgÔŸCgvXR´QúËšãT¯±yzSX†›¦uÑo
×z£°ÂfSH×1Ô4…±Ð`Uc—i
ÙƒM×òbJìÃIS_•ò…jósµŽÙ¼½*gªjZÚŒ¢ÅªYà?M‹„
¶©¦")‹bÜ‰›zV¥&Š¼íÉ˜œþltÛQÃQ¯m˜“×­±+Í5ó(ïA›]` ÃBÞø	acù?™[ÃÝî©oûÛôVK{Âö‹OíôÎ™Ö*ÖÉýªrµ,+œÅäo|þ+ôä8§4ßÔåVi
[¸¤~©€0’¥öÂHîœ$çS"¡b`zcæ…Ykq’4t}ü¡_³jÙ¯K%XÈ¯KÓA®AÛ(ÛÊÃ½e@Œðz•ÆÁ8®»ÀSù	—[àik8wœŒüEÆn˜µEl2e~"–è…j"rö7ù¦  Èûb/"m}Óý‰ˆ|”Âÿ£ùÿDX·ëÂâ"Æ^$›r7`U³0mCë÷}gKI4Ð+ø*Íó¨ùâ¯sœ8þ}Æi.çãc#‹(?]ßr™‰fN% õ·U¶…ä]W H¢ðó$hXÛ\/W*7Ï$TeŒßoÙDd[„+f™Ÿ§k¬s§{á¹Ö[å¬r.ûÖø‹«êíµ}Øxq5¾‹‘ÔØHM#[œ…Í™1J¦ì0Ô|D^]µn
ýT
3Ur`âËrJò;ó›äUY™ãäª„©ê±o©’µJ¸O×\ÐGmYäWb4¥mù¼Ÿ«ºšÃ(];r¼¨è‰€‡¦®øæ\Ir3A¾ÖPfQvWSá·Öâªq'5{Y´Ÿè?÷»R¥ªÇ{æ_¶rP:¥ÇN‚ÌÂyë	Ã¸¹Õ¢8ókEoe	ƒÿ_vRQîn]ì-7Ÿš—ÔJ§à%ù	XwˆZáNqóéyIÅä¬Ûÿj¦hba‹G\ßKMÓÜl¬ÉV­>¯ ]ß»WzâÄ3ß†yÛÕiÁ<”0f­")‡µ«÷ÂËÒ´8d±ZxY¨uô¯
^ìÒ¥3HE,9”QS'spcÆ¯&BóM%óŸäùSfbd¥¦ª{pFo“8¢E¤òÄŸÂWªP¶Þ”Š9£Û²êM:÷3«Ré¶®Š%ŽÐÚœ{!ˆ‹Ü•®¶ßþÖOâFK«Çc».&Lx“&åÔ4—ßåkXš7)÷XGnÝp\#ÄÚ¾)w0ö&WN¡•Ñ«îÑ³Ã£—æN«æP­;W—E®'rÌÚû¿~÷‡wÿòþßýñÝ?‹÷ÿîŸÞÿþÝà#QÃÙ¯5êÊu“Ê•²š;@ÉI¤a•›¾°×®©/	ä%«AŠýÞ·Ý²›ÒOVPm¹ÌTQÒ]ëUÿòîcÉ~6‡qœL›¨”$tøŒÈ~Ö6ä˜«ø4]d6ãápÆ¼–B_î$dìYðsíP¨Ø8 vŸšp§Ý@>þ&Vìáè¸LÃÍYÝsåÃ	â _*}lÀÅMó Gß'¸^9¿<EÏ,ßÔÉÐ˜Çí V_zMÙ¡AüÅÙ`»ZÊÛ-6l·(ÒÀ‘4ÒYDp*y0‰±é‡ÃÙœ"ž	òq‹ÜŠ´%ä€)‡¬Èu‚g¥Ç‹jFÌÐ¡KEÓá'ï*£ºAê²åå˜ÇÀû7œ²¦/¾˜cìÉ…ýå:\>'2Þh„Îë~_ªé=NãŽ+Ã2y\q¤&'E‚.e'W2|u"#ŽZíÎ…Aã°ìì‡C«íå¯Dú@Q¹›Á¢Y}ÝôÀè‰¿YÒ¥=iörH¦€S,›’H¥‚|nÇèÈ_>Âà8JÄ(à…àG¸H›!ÑC1ò¨;)€c ¨?û£{eŠ!Tö@‡ì!§¥:ß û9Q)Ÿ%ÙB×ø•Àîéu‚¹p'¨ð¬P&ÁÒÝøkÙánÒ‘‹Xê&òTnSß~øóa¡Çu¡Z«Ïk`“T[±šª²î0·@À¤Gq×îÃg7°çbÊN¼SÓzTL‰yÂk²*re4¿Ï‡¬•|2™ù)&•C!?_?Ù|…×ý´ªx³,f 5Q,üQ>tG¹Íï+â—*?+Á4V)Ôä£çò]ÍÇŠ‡3i¾¢ôY(=sÃeŒˆyv„Žzf;/JíV1hŸK4@0BP[â¼
¹}&ûÇã×ýyQIÖKm×¦ñP&S©c@ÒKÜtÖ–Ñ?éy† º!kÚÜzîy_ç’Û	›aÞÙ:Xº{=
Ñqõ›:D ­W¶'µ’P†p8œøïÕ–'õÜ…´³UÝ8 Lb§"œmì6½üÛòßfÉÔ¿šEUÉEy¸ØJƒÅòZ¦ÿ²:6ŒEf‰-éÙÎV+ à£ÄŠ]T9¢Ó@ŸFäØwÒ*)½ÝQ™¢]òÞîŒÎÏÜeåStt×ÍñsÏ¥ð]Ô¯Û"Á»tè¾élsæó*‹¶liÉ¬OªºÌßÚ§ÃŠ^2Û@½´Ø'9#”üÄ`Ÿ¸­ú„¥×'JŽÍ;ú¹àG8ãË–Ne®ùvE¬äüê”ðj¡åméh¶Ï¡¨d…IhC¼v»“/*Ìñ’…bIG>åõÐW.ÁÊî:å‚IO=˜°£Ga=ÔýËënAž‘Ò$­ïE% ¬Œ¿ÙÖüHêjÜ›ùIéý»˜¿T“I4oá7³nÎç»f¼;T-Ìœw®idfŸwœÛìWÃ¹mçúÓÍoJh¯lrGï™õ9-â¯Ö¨t-:Ô:,¥Ø
HÒfÅî“Ãý=)!‘7iGp„~f#Õ›ôÕ‘ê"<0¢¸\&•ƒÚm„uDDÛÏœ+c1Ç€ónN´Þl#Þ•®À´¨ V½i1x{Äùš,‰8óÚEl%ÎG9§#aE\eÖÖ#ÿ²!×ùQ7³(ÝçubíR³ =i@cóça-™ÆMÌo
÷5;3šå¦šqâ^Ä¨ö±ŒV9}!­Å0àdØ{CŸÑQ§|s#¥uØ×ÖŽ¥Ñ
(?Ý™ïOq“¥bä½Y˜éœœ¯n<áäbÿ8Ï˜ð6ÚXì²-A7TNòÈK'µÐ¤ÑGˆ)Í-úXáíiâSzõ‹øn­w¡_}ñ g¡;Æ±W™B"¡¨“÷DëÃëVm€Y·šËíµV®~
ÊU+ÙFqL½êhÝYó)óÂY
Ò±õsÔzU$IºS­WÇ=÷™ONcÌ­¦`)‘I”É0~lµWeþ…OHíu˜·Ì{¶Q|¾™]åFÇw-T»§VýÅ™F7Ž0IJvÊ;VN®¦^š’‡Â©ñƒ“ÙªÙ}B¥Bíw^Ê›kóµÂ&©pþ
‹ÁíïTËÝ«]ü§¯ûoÊõñä ÂkY²ŒÒK£jË­µ¡ÒÚÐég¡Õâ‚‰‹@bŒâáŒâøuoP5÷¬«ÖË%A‡Å—¹'o¿ÿ^¿|Ú=ê</»1Ùƒs‹R;j…fL+ÅJ¯m]¯Ší5VÏí­ŽmknY!Ö\2Û
B4Ñ2fÎ–Ó¨{U²º4šB1Ë¢¢:aõeÏÐŠ¸iæTÕyåt•Fú:ÍóMtÌÕjåREruØõQ9{±VÎ~.ÊÙ?%%œMv5›çøº|ø‰kåV©’J«‚#¨V\¡~„u?¹ð·†aœúú>A¾–ãêGÐ]åá®ç4P¹,í·/è¶¼ZQ+R¡ÔÈ{ÿh%¼½‡jrIèoZ–å¡UðÇºé%ûný®Ì…ºÔïê³ÕÚ|_¥JÍ‚æ¶ƒ7\õ¯ØdwâÃßÉ™±Óiwô;ÒŸßÒCo9·~Øå–xÆ^èT}ÇO´zâRzŸ§WÑP8äÖÒûñ¹bQŠè´áÃ«	¨ê´Úå°’f[¯ŠÚ_túœ ˜ýúåÊ„>§oˆIç3ôC¶´hn®tTÀ„õ4JùP®bXX0	Œn&Üäì/Õ—}†¸Už¦2ö¨Í!­Á1>N¼Æu3«°¡mÝ[¤¨¡{6[†¯¯%oíöÂ^?Üßk-²ÏçÕÞe«Ž—©¦ÊË e¤2§BŸ³U­ï|•>ç£Òj}ÕÝcÇãTt»ÁwÜkö¹S<ê~wømWtÐÐs°P#^ÕW¯Ÿî÷v1ø‰
¡Ù&æÇKwŠqÁ“Qõb;.o/a0ö‡WÃPâ=ýŒb;Þ‡8‡M=ÈÙ–Ñ]&æ³)ã•º‘ï²cóí—®&¢”hìÈ¥Ü‡q”f‰DÙÝT”yˆÒ|Ø˜™î˜¢K2*NDðj¢K_ì2© ÷Ä=ÆÈ=L •az’¡ /–À½½fè?Ö)çí¹\ì¡2¢í=ÅZÊ\Îêï±#GŒ$Ž1\îý3ð Ž¨Ñ2ý¡«z~µD4C«zœêˆÃa×©4¥i¢ÖL°8ÌªÃ9,RÁóâ¡ #bm´-‘ÒÕ£Ø)6Ð›45ŽW4So¸€žÎzd
 b6à›­[å’°¦çh£Þ*úb›1­ªŒ§‹Ä—pmFž_êFÀ>Ér§*3lÊjŠ‘Õ£wSCEÖ¾T–ÐãpS%&æBD¿v]Œ™bU¼‘J–”Ž4àÀÃDiZ¥0­$|â¢Ø€3ý›æD¨n&Ì#¤ñf ˜@ËúHµÏË†€m$Rä™¾¥~[N/[6ZŠ—*í§B‰E}"Ã‹	äkŒÆipÙ@=zyë;+Ï<<è:.‘T‚ªNz‰wŽŽ­Žê[ºQùÒËJ’ßÎ×›^2¡ ÒŸ˜n?Û¿ÚÚ~ô¥özLãð‚Í«$Ö+QB—ç´ºŠaa¨4.|7Jâ)f±IJ.[èÕ…b 	Ý)¥Ú¢`ÛìÖX9l	`aH:äò…ìJ¦‚Ï`Q áºÚþ[Œ ²ðê³ªÝÐ.!ª:pXõ°ñ8_'D\TÖ6‰/SŽ³m¬´½Cñ…#ú#râïd`& 
ÅêÙIK[B^›´ù¹²|,ŠÄãš#B×ÚíÄŸC/M]‘¸³Uté®š3’uöPErÐ‡ËSïàX”Œ)Q]¯¿›nŠÀßnCÔ5l‘z…81lâÃâ%?®ÂÅ¶?ÚEÏ©+YSIéïþÀfÝšÜ»ÃBä4¹	Â\ÅCoÕ€”‘ÕâŠWcøÿ_ÜÑýýëv©È»ê¡JðÊ‰Ÿû¯_ä¨¢ÄióN0à–¿Ÿ·Ë«‹_›Ö¢þâáÖ‹G[/¿^=›Å«·¾9š»wY5] .Ë¶‰âµíNÿÁßžCOUßòeZî6?(Þ§×…€œ…€s>¥.Öí¶|º®¼®¼®¼®¼®¼<F×Uƒ×Uƒ­b+ëªÁëªÁëªÁe{–4tëªÁëªÁëªÁëªÁëð¡uÕàuÕ`‘+c»®¼®\²®ëªÁëªÁëªÁëªÁëªÁ7¯ì8®KÏ+!œ3­+
¯+
Z'ûº¢ðº¢ðº¢ðŸBEaGñ{_&e³”å5îè_<j3v¸$Š«Át¡‡7ÍŠý=lStÔ¢.æœÝÐñüFoSõ‡ÿ‚ˆîµ&ÃroZÅ˜ï|rL¿¤€ÅõÁÂ…”+š‹Än–gWµÆY6¿jA;ô<ï÷Wc¾³äX«ÄÍ¢‰#Ö•®×•®×•®×•®×•®×•®×•®×•®×•®×•®	Öu¥ëO<gÉ‹\Ž ŒÇæe	ŒÉ”fb½²àÃg.±¡®ç3>f&2'ŠDzû__
³è¡¾d­FóÑÅç[¦ñs)Ñ¨2C¬‹4.ø¬R•–s½>ŸU±Ø3Uä(G…"GKÖ.ºcÅÏÅ¢ŠŸWè.«øü¸†=ÇD)fgÙô¦ÓSö™<)Nî
L—L\Q¨”®<èö9àêXg*IÝäÄ®®(æö6·MgÙÀƒ»$™~r*¢<¾~†ŽtÁÜq±ž?@Æª¯gzFƒnŸS¢ª¯Zâ•Ÿl’“œi(•N[ú8sšÇÿ‡›ƒzŽÖù¡úx+ÿ–SY¢”¯¬0iGÚ˜*±AÙ‡~ì+»D›uB¢6OáðáT€)JI“g ¦´<£&dAg)’`xæ“µ{ƒ>p(YÌ’RâêcU«"ñ‡>\^G2Ë2[vjrL†‚ýy²&†Aœ\¹µêÛ¾µýègòÙwÒ„Öñ±* rÉasØE„Ä3”6Ò³¹ËKyš¥°\`á û½H#ošžR%8KL¢®Ÿ–ÒÀ&ÕBð±wa¦Ä¸Ð¡„Þ,vSE•ýS Õ¨ƒÙw|Öœ¿63Á`HLçw§³s¥bcj˜©Êå‰â zlí¤“*û ¼>èýùë.©}¸’Š›$¹Áœø’”@:Q»~ZØ'$ÂÇqû´5þ1Òþ]/•ÂŠæCwåg<8ÒGâg³$BšÄÄÕ”l§N™±Cœ¸Í\•>ˆÆqƒb±%Ÿp¸”Ó3žP¼m‰Öüî:z¯P5½(ÞŒ§mô4Ì™oöZªRD=•‘B­'¾²÷ÏEà©Œ÷q  ÎŸQÉEZ%ì=¯	5et<ôÒ¡7òMJ,î¸©V™È çÂï´U	É›$œ¦˜ÿ	³ýãsŸ¦'Ç¥¯0ðIÑr€ “[¹ÚÃY’à÷!A¯„[NwyJAÿ„b`yþ©wÄ”­,Ï¢4Úö@<ŽR4ãz0ÊqZñÖ0ãËÍÙ´ÁiÏyžRÊd®ºHg%–ÌœˆÍÕh°ÈCr|=Æ¤cCJAŒrðŒ=}K§’åyä1ƒ¤t‚±ýF¶7]ÃSôôS½EÌ0cÚÒAÀ‰á’à"A¤Hq4r)¡Ò3Bfýz Sä¨ä¯Žzßdù¼ÛŒìƒ"•™å ýèr‚ÚV/¹¢ŒfÙAÏƒ	›*?‹|\%„}GºNã 87ÜÝ…—.•—âeçèø¶ûF/Î¾ÅçƒûBWc.tGÝgpã9Øíê!ùK?¥h1%'Øíôw;{]ìËM2§+>,®íˆ‹\oòh¨è”JuÏÈ"ð^—ÀB2ï|šýÖt­Åî)êk‚âˆ¤®È…WJ.™hràôöº¿Ì­c0z;(YD~CA¼t©­ëâƒè §kF±€Ê’6•5êÐ˜w¿û]w_À|ì£œhr/œÇ#?^ªä‡:ét6ãd3¾Œ6yüFÓMZœéÕá~o÷•éÞJ ˆXdÙ¬ïÍŸ­F¤ìø–Ý‘7±Tà½É¾1â_÷Ñ£¹žSdA;FlÇ‡þMnófNöÊ&¾lo4oé£R2ïï{Ç/T.´2ùˆ5«EÀ=¤âiU‹ÿQ›sÅÈ»¾GBžä¦«Û9w äîæRÁ7”zfÉ¤tqmÊÛ¾8'QŸP?F]t.Ëìß²†±} ~”ŠÀe¦¬Iôo—j.KÉä&)3I—@Ê¥T)|E*ÕÅ,UsìSk›ÔÛ¤,5ˆÒt¬ÍS·©ËÓW|t%¬…ÓúˆS_àõ—I|ÙB¿{xðN„c±wˆHy\[õwîaæJõ2„»¼˜bÀ³Ô_P“º­°¹Œá6ÞÐ>ô®¸{_£CÞ¢ö®øä½JéªSÌWðÝÛÉ’Ž]©W÷å«Ò[×à,2B·u-iò! Œî<ï—OŠç-cSÃ„H¤ÒIù—á3™Ž1™U–W¬’Í›úÞÕt/NMuÉ…u_¸A†Vë •«“);pœuegÞ%Ym8–=èSŸ+OŠní¢ÚÝ~žõ0‡Œbb¨´å.ÖžœþNÍÂ&Tw}yÂuCs¸Þ0ÚXB7šd6Ê}¢ªœqYÖ.0êãúOuÐ3ŸbÔÄ¢2éÈXâÝš³–á“I½„ƒ,!ÖqÖ’[Ú™}ãÎÊ|éäD€…±¢ŠŠÉ ±i‹ÖÌ{;‚ú01mæƒG_”ÄlY%8M'¹‚¤…0Iú2…f>Ï…ÿÑ×¹ 5ó1WÕ¤oØÔ¼R4áý)ß4¬<kAKùç{VÂ5ÂMCs˜Õ¢½{‰:Ïä“?;ì”ïgÜ$´{`åÖT¶Ýï>;v:ÐQ S’õ[jæã@ËŽã¹|†LÇ$E‘"æ]”oa©~‹]³Û¢^|ýŽ~ñ‹¡¤iÉ)ô'
:öÏ—?>eï„k-ÚùK•¯zQÓö¸>2öƒƒ®“šø1§Æ³5ö§ ª`Þï°$[51/7ë4Þ[þ<Kë©.Z-â£TSýøPª»AGU3ÊÛÈÈ$å'p9óÂ¶ÜX²ð';y2¡‰—ª¾dÌS”3J ‰PºÒK`Ãò•³½×*éÀ)Øy‡7ëÝýÃ~w¯üN­*ŒLÁN/ºX#:ñ%¶Öþžwáï¹PSµz¹ˆjº8]Œè(j‘})h‘¶&À©úg®ýÄ¾Ò£&¿aQæïÓCU†W…Ê!çÀ|,‹¡­Þx
\Ï¯ó5]Â¹S“ürxR®¡2¾ÓÔµ&
"¾[çÑægVv‘-'nØÞTqýãInG¾¢¹íøÈÜ/u|AW öi¥y±í“«ª¡Ïvwâ&þPG
çwcr"Ç1ö×–N2ÚÑ*vYaKšFï¤Æ—§ ü©ûR»¶BvJÁI‰Fò ˜_ÒÉÆ…Ìù8;Q5ÒÙÔ;ñRX?‰fLÈÝÐj1	…ªeÁ¥‰Èb-X„öxçè¨ó†ÿû«Zñ
Iih*/{µ_ÛùL	êÌPq¥i¦?—sÎZ×M[ý#A!k¥ ×¹G-~÷;QkqÐ[ÆµÇeG0i­/p‚Õf«±9Ÿ«×r.ÞÂØTŽ‰Õ¡4tZ÷ÇéWJŠTÝ½3ð×ƒ‘`³xDË„²s}F>Á_·ÄÌ@à„™¨§xFÞ—•œ›äû)="î©2W.	YX£ÈeaþqÍPÔÊ£óKbÒ™î]‘›b<åä£žJž«|Ú²Ó$¾ôè3®²4GrsL®”ë00À–èRîg\Iòs˜Æu/Hi‘Å8ô@Æ–¥)Õ‰|Te9GÊ%BôÙÃ'þˆÜm[D«¡;µrKÎÅS#‘œbÐ¯:’Uª+ºB¿eÌ)•ò¬Nf)NRFÁ}†žïËiþIWfÎxA>’:6.-Ú+®+ÇJ•‰žpýìÛ´ÍcIýò#)xšž´ÎŽÖíàPðÑùF§ºœÜ£*™ZÝ¨D©¼j¦MÓ³é)‚ã‚;"äèFÐ£þzKàQ>‰‰¶Tz¦-tßö¨¯ÐKÕì_ãMbE òîÆÓ0Âi’³¢ôvTYÒåœ=R‡˜:	;ÆWhÙ"â°î`häTMá•r7eµ.ñˆëçÚ•NWïÉX]Œ"ª«ç©í£lÙ7iÙ¾¶ÞáaŸO¹»ÂÒ]¡ÉvE³¸Î¯¸Ž´Ì£Od¹ñ©«Ãp­ï !«Y–ŒàÒÆœaîâÜt¹x›ìº\–˜X6î^Ø†	yŠ›\YI–£6¨<ðy.-ÑG3tsÏÊžŒõÄÉµ^c}‚Ãú²žùJçºˆR¶ê@[Q,¸J™ÈjÖœ‚ÑìêRÑøÀz¢8TÑÏF1–âè…6Sñ._yo¸Å7¹Å%Ú$|Œ.eq,„%òeÎ™ÌMÞß¸í-úU÷èe¯ßÇKô^÷ ×•úÌêú¸¥*åœíªdV¥Tlå”®èŒaÉMJdaB‰u©Þ-S,sË§nè3'0FPáVXþ‰å“uŽ½…Ê‘  Rûhnç¹¶‹t|CäªÌ"Ä0dråC#_H èâ Áöá¼®Ö¤Mºi;ßÊû¿ÿïþýýß¼ûgñî_ÞýÏw|ÿ{J¤òÏ
„òÜËr»Ûûš’ÍðŸ÷1‘ú\€§ESÈ.èCoê)«¨F0OP\ÏebÕkïþýÝÞÿãû¿+ÌHìÀœÉi5—îåÁJzy½<¸u/ —¯,ZÑŒÖâQÕ
XRP‘`ð¿?Z€rÞýwÿhçïÿºH95ºÉ*Ê<:âCÂbõ y%íY†0fA£õ²™¤g³¦8c,I£9¦U™„í¢ÿe?PŽ
œQ¢¤)Âør@v,eî§HÖ4åŽHC5‡TyÊ¸÷þæý}ÿ¼ª|ÿ·wø¯v<KÎ‚ô }ŸžÖöº/7··w¿ð·´bì0ˆ_EmSþ6`­šÁà£9TVæý_0ÿðîß8µgx§s€ÑÐ<ÈAƒ¿ŽÐÀ°;?[šwÿë÷ò_íØ÷Ü'Œ‡90ò&;€”Ëƒñ@ã¿÷GñîŸÞýñÝ¿ ›üÃû¿“8„_ü0c·!šG9hð÷ù+@<ZÜ^ÿ„+c£¡öÊŸ¦AU/s€àï/W€ä_Þýë»?ˆwÿçÝÿEiZécÒ51~û[½X
šŸå Áß8ä#€æa‘Vv††þã  öt–L('W+?ÏÁ¿ÀúÂòÕòpü°èÇíŒ{ç_@µ]¸J‚¬ÆåHå«,øWçá—S,¶,ó«Jf¯ï4E^?=…ÛÒ"Ç+ì~ÿþïNOçim{Gÿ«ÍÁSEdä¿š3=–ãazhzK‰U;®XÅ"-X#Y¥¦ÎZ¸ríW~¤.Œ5s\ÖärK*åšÈÏi)¬Œ¥òkœÌf®åm9Y¼ßíîÍ7¸IK›JÚ²Òë(ô—×{¶+4,ñG#YØT…[œ—üÔË8³ƒÎ1DQ1uõ€”¹Ô<ñ¹W/É‚±‡2 F×4)Y½U×5¨ßg>pE6*«È¤¶þ(7óyâ»¿›GD›JÓ›¿-G•>ºì.qEÉ@‹oe§oÕ=¼ü­º¿W´õtÓ’·J_PþVéŠo?s ú t÷˜øÃ³4õÏ¾ÅÄ
Ví£oç˜3Tßã[F×•\{Mï%…øÐUÂ¶å*7õ¥¯Î(1ãLŸQïõ:ÏûÇ½Ý~Žr±:Ê÷òyWÈ(d>G>
ùgßÖF¨°#êm‹a[Åd`ÇÄ£2¢Lc î~1¹_úÔ“w‚6èF¢OšêG‰wIùÑ0áì†ÅjßQJó0jŒº©ÙÉì‹ÉO	³ˆ;»Á¹)ÂÓÊáAw3ª¥­ùÕ&y¤zÚ²kÓXåKk¤‰›ê[Ô?à’iËª\5RYø¥F›«å±Jä¤ÛÔú'QÈÏqøÔvè.þ£”u¶Ÿûœ™.¡i’Ñ7{ÆðóüŽ)£N/´Õ…ù­=—È#±J`’¼VA\7%­AXUdE+¿ Iå]‚ó4çiJ6ˆ-¢Š!ªø®tüáx.Q•†»”S•þ_GVñÇ!«ŠÃ½„®\ñÂ£—Ë¢é£ºÝ[ŽÊ"ï"su,Õ·«·ØT—Ü*åƒÊ^V
í·–{ÉzÃ ªZA†×Ž0Š†œ\GŸè³WvDL“ßx¬N°úÓ]Ù:IšECdT¶F‚—×Ö]DFw¡4/w£ˆà%]\±€»¯cÈf}QÈ²PöÒÜÅÛ„y¹=}EY\P‡²SÈ‚¾iŽÏ>/gÅ#š˜O³±ÎíqœøÁ$gþª³âëD¥fŸ
v‡E‹òEÏÒð
of@‡\Æ64Æ¿Ó•²ŠQÁö¶û³2¬Ã!Úßúþ”›Ã5r˜‰£§]¼uK7^f®/èO¼á•…#¸A¾ŠÓlrÔí«xÿíÓF¢«ÊùI0™ôy˜$Àèœ‡³óHåè³mí©ôQÁÊä‰Ž¼)ú'@xiÍ/ Ó;%X”yï„ìñõ †3ÕUef°Ð­:¿}Z™[-	˜¿h÷ð |ÔéÁÞ7>Î^
F°ü«±¯¿Ü¶uÁÏg+¹mù£§kH?…ž
ÖÅœ…¡ÊÚIº”h6½«-Â@x!k{I‹O)w¿n(¿Lí¶µÅÇÜ–‘•2XÆR¨¬ª“$ úBÒõÞqpÅR@ÃGÄÆEåÒgU;™1RTBQ•¨RÌ¦ð×ˆÕÖÌe¤ãgZíi,Ð¹ØÒYBÙK•ƒŒªñÍn¥”R5µA%-®ø‡üÁ7¾ÓjæuÖX]‘6ké§±¥æÓ¨raÈ -éÍxv¶~1uKBºôÒ§jàLýrÊ¸2VÎ‹å Ìì9I¨/£š+þ)J¨«FSLÃ™.£ÙÃJ®ì}÷\JO#]ãç;KŠº$ßÆÖYQˆEç¡¡Lë!¿$ÅÄ‚ïº7ŠyŽ¥/-cGµŸcyKcb)¾„ý *»½<å/?sÉÚOòGï'	Øý^í[´J«ƒ…,_ªì.ù>På›Ë Þó™¢ÂBdü±Ñ€Iw5Í6Ü4†óo,¨ÂÐ¾b:IâO÷{˜>lçñ†6|¨@¡ÄëÃ:ˆJ}Byð¦»ÖU¢ïþªìý¯wÿáønè¥Qî}å~Ž$¾Ã>~k×ÖµkëÚµuíÚºvm]»¶®][×®­?f×VL¯K‰¤J”8&Ak²€)_JGI/5º©r$•HÒ²™›–Zé¬”æìi	¸X4„Ò96m—pŸÛÆúÒ»ÂÔx•UÙù9ËEkŽ­¯·Ë[ú>-á¦U­žÂ/Ù…æéÅåéÄŸø£ê§>m—]zKz×RçXå "JzDî¾øÖR‚•¼µ´`Zj°OÇUxenD7wž6m 	5ïà€®² |$à5ƒY»d3çX»d¯]²iìµKöÚ%{í’½vÉ® ªµKö]²Ax¥¦§\@:ˆ³Ç–þkú£	—²;Ñå}Ò-?Î—c×ÞŸ³ƒ7&z®, !©Ü|¦lº–¢*£êòXñY›Uƒ,õÃq˜~z[uv]8¤e‹]A@d™ÎkÞ…aäuyúAêó73ó‰ô0£žÜ»»ëâŸ£S¾ìÔÖþÑ27sš¿èÎ4kþ*‡Ôœ£oz•bMt,Oâp0„ñýäÎ\}É5w/Æ\ñXôix±ËÃÓ+v“ìÝPöhLf	ùïªô[¯{¦’½*×7<õ¢	qÇéT'ßF#rk¢ãXVºÐÇS´Ž¡GyYÑñ]°¹ÏÙQ\Y”³àYûË¿RU¬ðc•U¹2Üv•ýÞ¨(uŸû¼2×µvs]¨ÚÒ¤X´kâæ¾+TØ]²Ÿ±LMêÆâóaßåÛÏgÁ~ä|–©5}ƒI1ñÜ~Rö#'uÃÚÑó‹CãlK„…ÝL>'´5Ê=d	½ß›ø­á½¶øË{2ÿö ^2ó&þ½ö=/¹×ÔÏ9jdxÏ»Ï_áœú+¸gðlooëåË­7ð^áŽ4¯<:…g—¾†’,…g©—Í’‘wuï¯p3ßƒ‰9@ðµ
µvðíofÁðzðÒ3YhcêÇÓ^‘HrU|9@ß÷I
Ì0s©îSò¡Äp„#è–Ô{‰#'þ@‰ú,fé°ûUñbØõ4ïôµï›òà<q3Q‰ àò°W|p`hBV¿3ïÌÇ¼ëê7£FþÂzY]O½+Ì8Ïýbblë;©KÀ€¯Ñ1LüQ`&Eî”ú—Z›sNè€ûä±Hò¢2ïíÀp•Fº%>	0»Ý¨‹çð$;<vïµÑÖ,Wƒj§
&þ9‹ô?l^ ÑÊÞ#â¡7;:éÇ sÅ¸¬ÓÄoÜÞÁw›\-È%NR÷Ú_*pT÷îR|ZÐ˜…NMNÖ+,>G¼ 6±aˆÊ ýºt‡Œ®ÿv DôT.á,³=•¨e²C0~…$&ÕÄúÁì|-ŠË:àzW…õ”t"‹± ¢fÑÔFUç^4ÃM³„zU` R~›¼j–¸™Ì °¥
‹˜ I`€`o»$„î2 ¦—ý‡H[óc )/\ù^Â&±½³¹½Cì‹úLCoˆx| TŽ(ÔT|é“S’$ dä{<¬¾/ÒJUðOÓÓªªÜŽ‘ŒG¶ÐoíÝ5ƒsø¯Ä>m	…rsq	@“§¡§Þ·ã½¯¶ÏÏïá4¦ÎhG2™0žÄj(z ÛÎù-“ã»Ï4o³JDÞ8Îhàwÿûýß¾ûã»?¼ÿoâýß½û×÷¿÷r6ûÛ÷/±6‚!Nbâ/7'ÿ3hŸÅÈñå ’eXÃÂð£4÷èdlPH
ÔÏ³§:sºó÷’wa<Eø°Åwÿ|ÆW¾o¿â	&þ4N²tîôôóø	îKÙ)m|~æîÍ·Ø%üßÐÝM$ßLGãÂy9PEqŒ¥àŸº<ÍÌK^¥#÷	Yê‘â7ƒÑL?Ó¤NÏ,ÚL}	‚Œy(,[J†68ùáJ2 e–!¾}Ž¬È3€;râÉh	>çã/­Íà¥é%ºÝØì7Ö.åÎq:ø´®ä¡7,]ÒMÓXÄ‘œJFÉù€/¦ù§SâÒ’Ãf¡C"§~8•#oü•)Ðë”žvëM›ìÿsU(d“âêÆ;%K‚	:5äýS°Øø_h/‡ƒî÷­bå²Ç¹7pûÊWç“*øJ)	¾PbõñQïùs¸A¹:K&ƒR€©Uo•}À\°Ø“’š«…k­©&^Û”òaA¼~MÃN~\:5OPï.¸F¶¢Û•GœZ:ˆ?ë<zÙdÔ½Kq¹¿\[Ñâ0_'ˆ6Hs…Z¢8ÚÁ=™‘ÓyKrRTr!Cmh¬C &ÙÚX«.n¢ºØ˜SœdáéÝz¤ÛáfeÃ/„ØµFh­Zk„lÐZŒùŒÅª]:Fõ…IIS3'ºÿ/aS
[ 1‡wk¹÷ì˜N’4£˜Ž0öF²—Ú‘–¨é‘ÿ.^0@Ð÷‡géÉI¯^`ýàíÖ.öF›˜ŠZèÑ]8ÊûèËyMRßä*û(à<ã+·" fñ¯«°é18Ó5ˆ72B9N°*'t9
1x H`I™tUW
[íª®.f.¢ K²rWu/ÅÝ6ò‡¡— ë,–`dI¡ýÄ•„ˆÄI —¸ìñÆ‰ÿÏ†úÃd
÷0¬ë§ü41#¯˜xÀµÓ±wº|òO¦"ÂL4@z§D–žìñÜ;S©Š(ÎQ®ÀØBôo†s#Oú£’€OYÚÄE˜Á@h÷Æ"ƒû¶?É¥iÝ©›ÖªÖ€‰K*?–¦i·rk²ôò©Ìk[ÿiƒY"1NâóRï+NÞÄ‰¢¨´m]ö°Sl#½Ù¨àm¤üšüaŒú¡_[ªÎx`Æ‚ka{ªüu³vc‰é_zGªž¹\|Xvù×ï~Wjzæé¤ñÑî©ÓÝŒÉ©`Þ”â´j´þ–K Ði­ƒã‘eun!öÚ¥2qP²S¥‚²û^Åîàœ·ÒmÝ Óx«B³Ê¢q4;!aB£Ã8§,‰bàãDöyÂ(¶º¾!†uE…^îèØ5ŒŠßRjá7½CN—§aãÆWIÁaZ[ãE:Ì‡áÜÀŸžs ß†_(íï˜³2QÝ†m8‹©Í¡§õzy¼+(óˆw»¿)qà6˜—o€zR‹|8>MÃ‰™…æÙÝ1éÙÒLš“@^Ï¡¥|Í=Þ€7òÂ—øñÈ!	Ž‹Ê×ö¬oÀÕ(Â™ƒPâúºÁìÜ­íá`Š´÷Õ`çÁàÔ9uïøêôÕæÜ¬t¢z`«}|	WÊ~Šêb (N2“êW»U™-Tð©÷3ÄJÊÃC¥@¼¦ôq.«¨ug½¤M¨•€,˜´tŒÞ.˜PvNW¬ÉÔ=•·g]Q·÷ü€ÙvEæ¢~UmÂœŠµG½ÝcV¼‚}AùÇ¢/ÄÔ¾A­/4¾÷ÞÌð"5¯(v5&´x5Ó€œ3ÈÇ&_d;‡ŽªN !R¶{ØÙïöw»u+OÎvC|óDl“´~o¥Ê)}ŸÏ§#?*'+ì¨æ#>ãôº>sX¨îÈàAe{ßÈ‰Í¢@â£d²ÚÇ;ÇÿS“5±+Î×‰oä:¥D)õgn§åÌøsèÈ=aÁd®ï<MÍíð:Œ"™•Ì=‹3/¼xF-€FùÙ"h4»µƒFâH»J) ®é6‡¼ù}QW½ƒÐõ`îî¡œa!»‡ûËïœÊNÌ:£CE³Ð³ è‹2Ìô:˜è
å…öc©}}å'äñ1¢i'&gŽ¼IuìFRûE¾Ú ¿˜È†ÖuG¹¯¨³Áä´Êø…•;Çúhh«qíéhq,éöÎ/ëòå:´®N¥}:×ŸkºÕÂü\tè¯nƒ’<»°n"Å‘ÔTœûÄ5˜-%¡Ti‚L÷úk"7A—r«R# ÑÄê^½¶z—øËÅ%=ò2ð¿b¬ÜWöðäêÿ  ÿÿì½]s#G’ øÎ_‘'› ­$È’TR‹%ÊŽb±$ŽXÅj’%­¬­’dN 	Å±±³Ý±µ³y¼»°f7·û²66OûO¤×ù%ç_á™ H°ª4]eÝ™ááááß¾Ì€¢…lÂ nrŸíC‡ßg`vrŽÏG´­î3”stŒñÅö­ÇÏ;÷Æc2Ú¥}»L—–4ë!iõ1”&z1\²Å æëB¾f%º›^«Î¹ÅÛq!ú¬×/z“¡Øz­ˆP¼n!0énwŸma¾µÐVÛàr§¡x7™aú2žÄK'âã-OüñUÖK£BlGU˜„¦éá7É%àcršÇh ÛLËdhKŽŽÅnÇ®H²>ÉEHÀ¢;ödÎ&Â™¦%Ý ø¥V š”àiÞÏ8ï0÷˜ ´€?$;iŒè…°Àé3ƒ“6åàŠyU9™{BylRd˜èÄUPØÝ·Õ9È·j€ú„³À?½e«wQ"v”ÓÙ)&r»¹(`;DS#¦LsvElô‹lÛ£oÑæN%
 J\nc]ƒîa3ZüäX>EpQ3Cn_û#Ëöfe‰ÅX²Dt5	­©]A‘éX¥m–g²Øáé­¼f¤f¿2.üëöÁ)`žÃÜ8’Ù1×o`°·ë¢4[æ—È‘öag^ŒcUO\D–d!¯ÒAwmíé¡öE ‚ÁÚ8è Ÿ Äv«²ü­%t6¨lÓB{>%cé`¾ôÊ+§^VFNÛXÿŸ
yZI`&2ÉqòW§ãÁ­ÂÌŽÿ!QÜûQK“šòcÁD|Šn©³ƒ1¦t|Z*ÿ/¤Ó059¨xCy¯£ÉÝO½&6ÏöiW]y;Ç»)ëá7¯½ÍÀ­žÖN7˜¬ñÎþñ^â‚u[€úHm†›èŒOæà÷xdñþ4ÇjEŒêÌùËù@ŠÖz¢2	¿êþÖn-¶…ù•÷•ÿ’Ð^z­ï—fLÕd²ÅiÀ® ©µWLsßÉIFÜ—‚ñ¤v1³¯q“YèäÜ:Íþ—ÔÆŸ?é´ìOŠ+–þ~=õ…wá:P o%>[d·H~àªø8ÁØ! :Ù¨LÚßdeÑO6’ã)’íÉ ~ÝC¿á«IQrÈ•ÎÓFìS¬×7f·ìa2MÎTpšU<Š@Ãä”º
?ºÞÇ=ž‹üû·ÿôsu ‹	\û4×iAIk÷¾}™&—ãÑô®Ü¿N0ixËõ´’ä“®¹Ã¼}w}"¹ð@NDA—´_~¿­ÙeSM‡™Ð-Yýû¯ÿ—©‡°À•SÚ@×ãü¿S˜ÞoÔÅ§Ád¹¿vÇ–ŸåÜ£pÄã3Wß¢ÍÃÞ£€»a¡‚‹×,o1$Ú(;Ý$Ì¡‰éÞ²Ñx´á™IÚäÏ3`ýÆÏe$ÂhŠï°’Õá&(ÝùpO:ü…;ý”Œ4×îv»·âÇÙ:1}èÉìjKxÃ$Ûé^f@Ì]î‘í^?Â™=&v-‘€¶¤lI1L$Ø$tlÃ
{§JO¸-È˜™Å²}”„A#û†åmwç ^I·ÎÕU7˜|òí«]X+¶æSHH.ÇëÐÒõ¸¬àç]Æ1PFûA+HŒr†[	…ãm0þÁ¬ð,I7_tâ¤JÖ6	Ê©cf¼ÜŽ_}s¼{´Oooï?¼Ü?Ú{jîTª65)¦¹ìÉ#óó•X6ùˆl`hí:-pW‹ÄÓÚþà“ü†,%mqNÊ$.åz\ƒ1õ+ëˆ£#™é6þ›¬ÿúŽÄ–H46ÞA`<Ï§¼?|ÐdÏqå°HTÌF¸“š)$3È)NØw¦B®}f¥ …¤Ü|*luš¤m*NòõÉlô„Àuáðˆ0ë…1­,pb$6‘SßìN²‡o$@0¢àƒ2‰&8ß´n„.#ûpQDyŸ„ˆ³‹t@à¡”2_UÂþ8˜–1Ùüì‹ù¡¨gtˆ÷…FÑ˜yàÆ½oe©Þ8Í2Íßx‘,AB#0ß&¾3Ò†} |!“„ºƒ“Œf—@ûíG›é'¯-_]5=Ë1Ž?/kƒKþðG;c+OÔ×K3Y†S¿`LÌ÷=²ª&«<¬Ÿ*½QYŸ´²©­ñ›0Û­Säql},»ðóûù_þg[—¢õnñÉ—_¦øcSýá£WÈãn%Ÿ|”~dË![ï[KÌ_sÞÔìrRàˆaÂYqáý— ¸\;ú±nñGýq0ú§ð÷Ž¼†áMàk@nù9Œ øGª?ñ?á¿Àžnñ%ðe€Ùˆâ¢óü|6œëLàÏgèÞRÎà%²—ÀQs3ª"Ðœ¨…˜Ý¨Šwø¡{H‘1,Õ‹ú¨ô_	 Yæã0°gDÜ@<rDŠHN&ù¨±óxpõ0Dd½š*Y[®æQÁ¥	`”=Fèçi÷búvØÝ9ÞÝyº‡8‡sí²Zí º.|Â{ÄÖ‘>ºÆ[ØŽ~“Ü'‹4÷U>„ßyä¾=æ°ã}GÚÕõFüYí‹a…/Æ¸4IÇ”-7†"¬px‘1êÊ¾žJv!iñÅƒ¿Á¨EyÞ¬[< Á¢ÕáeŽ½ $uÐâxílªýä.ˆÐ‰Þõ£9PUcÛ–ûþ.a‡¨þÔ‰ƒ4ûM|kw8ðnÓ[¦‡‰Ct@ðyºÏ4ëáN‘‡÷ždX¸Çìëf'´z™àW}O¦²Ë©,Sj:œ3t8ÞÜ»óS¸;wv¿¶p°J…¨¥Bª^½‹5ÂôÆ)Ž³[&&>(¸–RÿÆé¬)å}j¯3¡Îü”,‘»»°Z>KÙmÙZ«ÑÞsÚÒ‹¹à—ÑTèY'²¬ŸDv²sòê8ùnïà%&ÔŒ1#MåŒ#*±å+ÆQ_²pŒ_Ø˜”€õËò¸N~z¹Ç5¨7Âä:3²–«"ëþ[SÚ‡™»YgM©^ê«É RŸÒTTú-ž^ÇÀŒò}Í,üj/jhnk[ ÊC_Ó3¿ÆX yO…ÅVìZR¡Pœÿí/+¼4Å½eî‹òÊL¦¿Û6‡LÛŸì¢úì ¶2¢q.Öæ+‰—öÍYzrvŸ¨×j~¸°ÊÒdmQ{Ç{!|5œfÐšÆ±ýÝÂýNaÁTmY,‡½ÕäÖ|46Ð›lÃ™y%äoyëpÚBg%ûÈÙpiY‹ïMKo¾Uü¾ûB=\£ÓâBê—¤¥Fu_OL…X9rzRj)]{1ºÞYÿúk'lmYÂùW‹åIŽôîÏ­—À,å2#TnÊÇ]ªõîáˆÉ 
3i;]xgÙë3n@á;ØvÈ{Z$ç'b?eÛÊÕ¢ªkqS3–Õ(jEâÚŠËºù·3Â]¯7ð/g-§ké×{‹!MÕwäÅï©`çU3{ðjd0¬ÞJsËJ,ÈÞéŠ8«-¥Æº¨ÀÑ{vøêEvRaŽQ„¢.ˆšŠØ+[iì•äô)ÛN›¡_½„&îm5Ù	½šÃ{-¼ZÂ(ÕÝ\šùrÓ
0äéxeyªºEo³Íy—JÌ =1L™—c‘Ž|6'sK¥˜a$÷)ì7›æ_â½.=‰Œ
Â»˜£ÍŸà¬C‹CÀ®,1ÑÈÚq*ÆŽðˆ,*TRÿ
3“h–§YÌ”:ç5êÌ´F)_™c–zÇ*UÇhÍ•8pƒ¢È‚nŠQ§V,;8yÃ_íÔÛÊöäâÿ=£„¢sO½zÂÉ¹ØFG³ƒWO÷žúÜ¡£9¨¡vy[íúM­Y^»+±Ü ußÇ÷Î‡Ê§ŽîE,T#~7ªç-¬Ç«;<±§FŠ Ã_K<—‹³GÄ1$?…£©ÖÇ˜ËÖ}îYè·*vvåôá±vè¦FN ìÄwI®0‰ëddŠ5VfŽ^îçhLó\`fXj*^0â Ã¼äAž˜"—¢ì”-±SRŠµ» ë©ˆ?d'ÇZš´²êÑÙl8ì¡%Øg4ò]Ñ*L¨äR&4°QU{¨¾C{÷Á‡âaÙXòÙÐŸˆÚIæË^À\µZÉ®èû½…[xÖó~O2¹‡è±$Þ!Õ§‚˜†Y¯?jmÖc4õƒ"lQè®GUµÐï¢`J+Àhž†ãµ£óÍ1³`¨x}µ[w+S5‰øx¤˜
_ÇäWðºd'8¥ztÛáVwÐ~¹Ñ]‡Y §N&à@yÓÊß–mK%åÈµDgã/LÔÅ=øùµ|»…‘"}*=\Lðè›÷è.¯NaYÈ¤p
£­<Òï¾úº—Ò­Jòq¬¹+£ÔúÆ›'‚p¤…ätcd)F•©›T[Z3ES^Æ¯þA§vˆÓÈØNvg'«Ì-/c3Ó»EÌ§·[sûP‚ª¡V0üp|ƒ1yÀ]¶åZètLµ¹=j5žå”½¯}:FWMå¯YÞÂ™N(%ýÝ€eì
Ä]¦Šj0 Û¤{º{Ïwöz';ßï½ð§Ý T„˜½5°x¡_Ée±•H–|ôDd¸Pð6Ù¨˜bvêÔD{ÉÆø·e9ÏßÀááü‰ÌÞÏô®ÛyHOöŸµÝ•K¹ò`d,÷ådÚ–å€ÿ;ÌêQþÁïøÙúßm®Ùí­ÿ'ÛÃç-à[ÿñøâc|È/ÖÄ¶@„ÖBTÖõ”(çMâ s8´ÍDÎóŒ/{3ºv¶¶˜Kl­·üGiò»{`‚‚ÏÁto|x¢ä‹ç{5(!PÁLp´ò
¦ºµ{¨þ"vÈè,c±f¢„Î{ð>)(Íá:CûÉíÕtÜrFÅ›¬HÅðêÅ÷/|ÑÛ;::<ò
îÙñ£ø KœÊ‚¹«'µ[²@¿ÙïROí¿‚]†?Êl’&õi§ÃÂˆ›ÿk‘d‰c;¸c‡Q>:CLß4'u—"×éf"þ-æö)®3à: d¸–ë.E8koˆVžæÜÂeìØ+Ÿ/‚¤ýÍó­ä|8>Í†˜nqú“ KR>wÎ®•ùÆ afø^½?
ËþìEHíB,”_”ˆusP?oRçóHà(¼n­Ðƒ&¸eI±z…°5Â:T?BÉ»Þm7áDQzÜ[;4¶ÌåÆ6òÈºDOÓŒ?ÆÌççmûÆH«á.0  U×í€OŽ·[³çƒ%ÔŠ†Òxû†Mð»Óp8Û \ÑYúól<Åü ´©%ü˜]ŽzLQw0%ÿÐ,á.fÐ
YÖŒª‚¶((wÔÇ.ùæ ‚ßÚ”ë‘æ4»2=0Œpáa¸¶]öNÐ>›©!=-DµoÜÄ…ÓýZ³"á#¢€ùÀ­š¯‘ÀU>Æ{6ÖÍ›()“Bà¤!…Dô¦ã×ùÈÍ+2ï¼õ®nç·0(6bÑvÜko”ß,ù…¤g7X‹«aeT‘U›Û'F(Z¤Ó ek¥-ÙFüÍ<.á¯l2Énÿ`ßþ‘oñ?üQ}ð›¾³¢{pB.˜UäP÷ÞXæìEÏÃS’ÄIh?¬Èù®6âSS66CuÐh<º½ÏJÓ¨n¤aYŽ{ÌFÚ!1rdŠ*F¼Hd…¦ë_(KIdF]/Du¸¢¢pD¨[†cËw–zmø)Žÿ•Ám€’+I¢âZQBôJ+EÞXÔÕT-mÑ¤6)Ó‘Tv/ü4v ÓØ±MÃÓ™ú‡0­;kÑæH¥‘““Æ°6Õ˜“jüH},H½½æk»ï¸VQ‡)K«Õˆ=<;'ì!K—ºA¦3,ÙGÙ@œ¬[ËÎ¶´MIÉÆm’uìüà÷–³×Øw4Oz×z@a9€â½á ì-\á‰BšaèpoÞUÏD9¤tòr9.³’Lo&Õ ÝV‰4_tµÙ^Böv“~Âå¢×å òsÍ×þJ©üÂÎÛ¦â²[XÜ~U¤I²F¼ÔâQ ‡k¿†›ÓD.y9+”±ˆPÆâ½¢Œj¹'î#K‹YThdÄˆ/$íŒ¢Ýr
0Å¶’Ô9iàâ›íAµG4Uz£
WÅzvWe[ÞškÑËQ´ÂÚ-taçŽÍþ¯z÷ Ÿ/güÕJmìÕ?Ù,–B~X5GÌ¾_tëÂ°«v¤˜ùw¾yµ6Ê;¬ìt'¥d8o‘‘Ò¤Ùö•Ëe’Ö“t²µnñw0®%K-`[Û.ókÔ|Xµ¾"—wa3b0±¹½Ö%ý.Yww¬íúü'
XÈ29¾•®Ž÷HiÜ0â í{˜´rTÃÊÚÒ²F¨¦RuÉŠäÛvRWÞCÇh²bi%[˜,ÊS Fl"£×#´n$V°Ò¼{Þe)–‹Î)jKÉãBïˆ["}H*w ´8ù¶wø7šï/ÞÀì¹¿×\XŒBÝq}0f0rêøš]×W³d™tùˆ,Â%+9QCy‘]åº ‡?ýØ¶ó¾°/æ¤ðŠæÍR™µ*;VÕxVÍ›¸säÀµÅÆ_³A„Îœ(äV²É%mBáóyÆJV˜5,+ikeönî0‡§€…û@{ýžªjèfks±ÅšNø°éÆÞU¿¨¤a“ÏœßJ&ó:øŒzÑOèUÐÜZž¢_˜·ÁGÎk'ú•}|F5ÖãŸð+mi¿Z4Q#¶®£ù\°ÃÖ€“êqlq7gC–I¼çùiPk¤f¹ÌŸ¦`¸M\‡.&ç£óàI›¦4|R¥‰¬†¬ƒ¬.õi0ü¡–ã®ÝÂ AÌÔ_Œ™~òË1é6Ìßâ¨ž‰œP¼&±¢2¯[H9*TóÎkàáÝ<"sg2³4¡	èúÅÌlÚ¦d_ÎBÜ7Ä4¼"Üev þ¬È‡®fÈÅ_ÄCq <¢^„êº&ä¦ÊøæÒ»ì`C,7èMÍìiÙ“ÄNuëÂ¯Ý‚:	„–dç)¦¯*kÈ¤ß(ÒößÃ405]½Òf.½;r‚Üî©lK®âýü«»&ÈÏ#»¡¿îm”¤ò‚ÎÎ0±]è¯å¨"^Í\Í9M>k¬×i0ëz&S©xœEù–W|
ìˆ±ÅÓSÔ^ÈogÚŠëHNhÒžkÔNâ¬³rg3·gè^l5it“®ÖlÝ€\Õ:ÃVlÈç¿«äÜªM7¸¬d&5\Cÿ;L{;×fö3&b>\ÀMÚuf3ŒU™‡ªy™t®«yÍ²jÿ6pµÞûöeëa= }÷m–¦]Y=ïqÕY:t‡f„íM³76hï1Åìù/{â ä+'ä½·Fº—$kN_ár7Ïws”3k’©Jùïÿíÿ@G·ðI×“ï¦>ÛñÃÎÁþÓùÖú¿ZtSjÜa>:Ÿ^´ÝËNòUòùý!úqoçûÞËããžÖ@8jä'-I'pâ»+,D^|Û;>9<Úë¡Ÿ\èŽ^¦JúYKèÊœBÃùÕœ¡ö›Ýfê"’&Djå´SOû[P¯Ô£Ô-Q‚)=äœþÏÏu…ÙÒu='©ï“õäyFlùµV–7§©•À'ÛìŠTÍA³Nš<zÜIýçB‹¬0PöoS&Ãž¡£ei”²¥UzFŸ{¡¢&C®µÅÂœüTíÁˆæcÜÆMÓÅM¤TJÅÎåÅx8ðwäÚœ;M9vÍÄ»Ø`3rG¼t+‹‚ž»›ù³½w>ŸÚI.žÛ§ãDØ—±È®ÆüÆh*+¹äeÍ…¼d£2#®©Â *dT§&ðŒÔâbÈÈE&ïÙáÑs¸ù§ìR«òF-· ¼‰“Å;vk;f©±.í1«Y)+DGŽ-G…Ê(Ë xvæ Ô\·Eµ6ÁŒY+ñuY+„7óÄèÝcæ²÷h42Å¿AíÍgía±‹ÓóÝtŸSÀÆl“Ö“-`ìà½ N5ù£—úý>b2´Yƒ»á ~ÆÚ&3â]/Á#`×0!å±æÅ®1'JY‡%¬Š!÷_gYŒÿDÒpÇ"_úY¼·ü|Û6Cs%/s%îKÝ<úr=›œ'è­5g®Ã»ùéï66?{ŒbÚ`2¾Â"z\A¦}™Mû7
v85ŸRjéO6©¯âòj˜_Â|X¥†•ƒn¤¨Œ!Cd³`;H³Îõù,/ñxÎ°å¶³®kSš²S.W5,¤6áVŠH ~áö•çÐS][þÉI•6ìRé+dFô+¬v6Æ­†áNó‰ôYIÙO*²QJÒW
ÓÏ(gñp–ã‘÷xvJ%3ÝÄ®zAQÒè«éíUnÁÂ+¸Úöt<š•‘ç•ñ°tC¤ÝUv‹Ø‚|’y†¹G›[ü¨´¨ìÀW‹Fÿ2Å£«‹Ñ¹¨4±Ùë<»Én[<©Óa¾POÍmsE,ØO¿¥<…£ïÖ‘ÂAÑ:	ek ØîMQÉ@š®Xíã¾·ºéëo¤aNpa«KºF¶©ÍóYú™Èáª>®}û‰•Òkp;0MÏš†@}´Óßë#TÐø#¿É®á: 5T¤S¥à¥O¦±výñy/æMù68„•fbàkíFø]­rÃ°æÑëŠJ¬Džg“ØÓa1²Éè1šÎ¥Ÿ—9MjÁî×¿ggQ$È†ä¿l8^‡³rÚi#«JR|0%QZf*È¾g5 Ô
u›«Å_žüÔÛÝ9:‰Šâhÿ¯p±vé¨BÇ":T%ndŠÊ$l›r6a*<çºë&‡Õ"|Ï“÷ ˆ6xøOgS¿¦ÆÒJçR0M¾6„‰™ÍË]·ÕH¬º‰ÍÖ à±X"»ØÎ6»7¿&M’—ñiÒ†–6‘ù­6×”A:‚ ª;“Èé¹ÉËTØl,ñ [7õÛ¯¾ö¸•˜ÈÝ’‰=ß?~¾s²û90q«“Y„ÃIqŽ:üA½J[’Èú	°8ÅE~PPkê'È·eûÆþj’ˆEì'wZ1JÔHù¶ö_ôxùð±ÁcrêÈÞ÷ÆW™1²y[·/®™=žØ„×½¸[Ð<ÔR|[ÔiH–ÙÓÜ¶ õçº°ö™ød3$½é©ÙzçR<aarçPnÕcøØU÷uª2AK——µŽZV(˜@â#]#rþ^ñ´*õ"ï†t/{‡/÷^ôŽ¿Ûv¢ˆ'P•ÛÆÆÜ„_R@J
ÁqýX:™7ÛÅÿ°ë}µ£bN·ôbÕ¸p²ßF¤[õ¬púM4•déA™“ ŠÕ£BNÈÔw´åºÄñØ|N¹ù’6ŽKÅõˆt^gCÌ”rÿî»¤¬SåLá"‚h&rÓÆ ÇB^“[Ó8z1-à£8—˜”¥‚œVŒ"Ô‰:—Ó«÷b5¿[lÓMvF¶3Ù‹œ+ùRí,SX
rQï§9,.Nm
ÿ½Í§]GÚ­¼M›cO£»˜Ú(rM‘¯¶ùZäÀÚá<”äDÇpWÖ*y-	áíYžSÙk0‘‘wÑ9ì¦Þ-jó©d Âˆ>8ªók±y9L>FÓ@2ÈM`rDØ¢ÏâŸ ¬<ì2¢/sÙLæß1à™Äˆ‘¦t¦Õ_cžÏÀMÂä¬ŽAªCöÝÎñÞWm“Âs$7ËYDdåj´’}ÍÈgDƒ;l¾O‚VË'9«ÖJ+¡Ð×‡‡/×}T’9ë„±!*…Ý§6Y±Z{²«oÍ{üÒên6íö™µ}|HM÷5dÿþÕÎ‹“ý“Ÿ(½‡›DêM¶‚jþª1ÅJ{}ž½NW1—G‡O_ížèCx‡y8^ßÖ}ßÒÍá{ë9”å–e.[[á3î¿rŠ¹Õ$¬vëÓOÖ­ph¾=~õ¼mpºƒØn¨ŠÕé[¢0…ãz§¨$ü¯ÔÚE–ÒÓînÃ£ŸÚíòOšSX}¥ÏÝJŽÜñ«gÏöw÷÷^œ ‹Äî÷‹/·Täæ7(Ìði ¥ö¯Dßé÷g—³!*®(°½X.ã¢¸F‹ÖîgðŸñyBZÅ4é³K´U-Z§f_I)*ß¸MUúÉ…Î€£¡îHè·d8>iÇhiÐ> ©²vÿµÞòßúE"Õ~ÓPJKúØþõqr„¤¬]Ëz€4ùDI xk…—éñÞÑ{GëÇûO÷’ïövP;9<Ù9 ZÕ_^Í0<‰tW>NÐˆeG]¨J™ÝŠùÃ_{oåiÉíÌ)¸ØïÞ½}â­_Ì!ÄúG°­8¹‹8¬œ;LÇÊ„^žxJ³ÐÊa…¬QàyÛj†zç:´­V¼‘<ÚÜô·Ñ™¢-žÔˆö¨sÍ¾¦Q9Ûc»¥ŒGf§tÙ$ò¹h]FpùH÷ãÑ>Ö¿Bæ-y´Å·æEž!7ÜöñŒúóðL{¢-iûF=Ï#É3’'Ê~—*A?M|#ž!Àf5Ó¤‚ºž½ŽýpÌ+mžKéÀ[Mß çœ[œý,µ¢Rš(;WèVN<=ö'ï™/S¥Ú¨Z1Ó
1J>Uì•©Á/…>þ*lv\—¶?ÆÐéL‘^zmœ=±£umQ°Þ“LŒtMXùÉVÂf‹“gûÏ Ó‘éc¾hqüw#Q<ÌµêsŽ¸? ¾ÔÖ/Þ·›=0¨Öì“ßªv·”íU] Kófyª*F»¶•4ÑŒ'õËaŽëÔË^ÉŸ“PEÃ.:=;šÏèªÍ5‹dA Ñ®ÈûyK•ÑÜ°‘U÷%õ×-Qè;ç@á«ËñuÞ;+ÎÆmx®–Td°c)#XFüºù¯ZŒ*w´[!Ê=¯4z”ç
‰¼óÀŸ|]Q„.tU!eËJÁ¿IFy>(á¿hÑ$#êo%(aÆ_½Is×`Q]V`ùçœËîïcŽƒô
Z•!jf½ûàtÝ§Ã¼ªøýCÇE£[&\±º[Ýúúßï>35ÎD|s‘cød½’Ýg´Aš_î™Õ¶“ü,G/Zè¼¥+ö÷)ª‰ ÿÁ&ŠQ¾^°åuÌ€?.á2Ü¡Æ75ýá?Ïy§ê¼VS|9‚ýa7Ø:5ÎÎ¦ù8A¹„>Ø¯BÄŠÞ°æÐÝÚ¦$ÝÚßuA¡ºBB5ºbƒ>™ŠÐð´ãzö)¼a¹ÕtLKØÕgG»?,`Ð¬1iz:n¹Rãûã4«´Yy:`±™v\;ä¯¿oWõ·á:ëg˜®~µÿ®VðFuÑ”’Æàˆu@­[`®_´µÊê¬rm¢6ê&ó’¦9pÀQÙbOc1-£hÇÙÊ¥$£Šé-rò¼‹žÚ²±YjvË×ibŸ
Ï]'»Xâ$íÜß$cI¦«ÓÛÈeoÇrw^H¹+wàü
|—€]Ñ’®‹o“¿Ï&#¸=`ÈÉm¸¢$*wdÕ/
™9ƒœ©=1:˜	Šœ‚†~“äjü;Ú¶“Öi6zÝb÷h3û|ÑeÇ¿þýßGMïu~Ëä>”^9„ÓbªÖ“’èÉ&åüšæ­*ç¡……	ƒ3˜z;‰F™‘¦ ²zw›O+›´¢SÈ&á”¨Ûªˆ¾ËO/›ÔLNi¬V3EËžžÃ±ó¼™¦ÀÕdë6Ík@·º¢U>ÉâY®aÞÔ º!Ì}¹Ï0[µ^fÔ ­
Üëë ÜŠž¼d±ZxY¨bIW/véãƒ¤#î8”3­œ7¬¿	]›ÚU›„„ü&bäY1Á´ƒp!oœMÆ£)–	D,ŸäW†K†=”†8—ã$3½á œ1“úøõáãJ9@îyrIì;wu&÷¶ý»|2–Ôâ1‹:¤6Mx&åÔ¤B" ÝW¸7éëHG°o8®®´?ÕŒ½ÎãÅ1´ÖKÁ„YYv­'×tö®Ô·›/6Ë˜­_þóÏÿüóÿøåÿüù_~þïÉ/ÿøóÿ÷Ë?ýü¿ðQB‰&«â¶,Egé¨.ËØî,d-€ÈMda•C_9ks¢· ½$Ô*9Øÿ~/&Áÿf%ïUãeM´W4Ô²Ž—G;/Žwv—.ÓÙ*æ™yáB+
sºOSjB[.Lÿþ³Ÿ’«ó	:Á¥Lafœ5SR|Ûú
ÿQEÅýo9èo+Ù|üyï¬xÓ‹V€ìb°ÍªÇöîûûƒYt“gXä%6­d„ÎF’ðÈŠYfi2ä>Ä2o>~l$…`VBãçDGoDK£¢ž;£ê_&/æy2ó àcv¦ŠÎžƒ	'YQæìè£Ñþ&WFL+Ã]†°|Äþ—¼D*¹ÔE¹Pa·wŸÂñÞÅä™§yXöÒV,ñ´`ÚÅ²¦Pk'ÅþðöwÇ@<O†yvM)óË.-ÜÅ|ÐMöùåˆ¹jœúPRþCIù%å?””ÿPRþCIyê^Iù÷®\ü{\þC¡÷-ú•z÷Ìþía‚¢_L{Ä½þŠd˜/€§Ø“GŸ­0G+3àãIbYŠ›bzi\3?±	°à±Ò( C&-Io„9PKÒïI˜ëÍÅ¸Ì}pL
K¶}mPP6ö7$7AÚ˜$2Ü—¹ÈK¦w˜0ÝQÈ(Fk¶ªw@§³-#<>6Áß)@V@’¯Wmz3VXØY?+órk§›$ºGÛ81ÛoQx³	–mˆ¸Ý™«l”“6	z(+ù¢!{`À¦´HAªœÅ-ÜŠÐ
#ç°f^>úî»’ 1Ö]ÅÓ¶Mòél‚¹Uc‘Ý]îöÀ=T]°¨@9E‰+›J5ßL1C¼­Y”-•ùjÄHÈP¢SÈz¿˜ôgÅT¤7ÚÊ&ú‘Š`Æ´ôýd2Ã„Ò¼5 Þo±†Å
Ã*É“E "KC2ì%ËI~@ªÄ;|ÞÂÜE©ƒÓ¬ÿú½<`¡Ð²ƒ¯n¬a{Íât]Í Ü8Ï¨ºFáw˜ÒÁÝ”ß“€ô›b4ßtMå‡å	fã@Dd&Gf˜Žu8ÁIòoê¿sñxN> Î	4Wp¥àí{É¯¸lì/Àš_‘Oí•^U.~`’OÔtù­ËqpÊ6G022ôÕTuÂ‰s˜iÊÈÈ¤—`µéL¾ŽÄ×sHÎ*\Ç¹ŽC"O5oä˜4j*Ëîø.O£VmgM;%º§òqÔ¿ßC1™ñâÄÎ“h×[!µ>&gbÍ©å	`ý*Ñ+ëæ·wæŽ;®_U>•D‹†xÌû‡	^’àë0^û	ÙÉ>–K¹f¹.# ¿Û6KV1õ!¾6¶šç£ÚÆ,ch t“³[ öÕü8~–_nX{!|52PÐšÆ±ËMîdûÈwÕÌåuG¡ù ¸c` R¸ž€ê	Ã4®ÕÊ†KËÚSÐ´ôæ[ÿ„Èêá–%$¼Ø½Kwí¯Ç"õ»žba½»ó“NÎê`ðnrŒ£';8úº¤™Òæ¢üŸ~£#üþ{Êãèµç¼R”5&ÓÎJ”bžS±ê¸üÝE8+¬Êë¾S…îŒqÀ²Q°J	³P•ŒyaÂ¼mî<aÊržkgCZ«™ÒàÎ¢e_f]¿žÂ¬[“ðªÃ˜~´÷Ãá÷{ÉjÜ«X®ƒôòÕ7û»Oæ’Êç‘R†²¼|~\x½
JŒ<ÉË£ýç;G?%ßïýD¹31ÑwÆI,ñÎ¼0õô‹ŠÓ78:o¬A›øU¨_]è£3àSf6•_µ‘J[‡ÍÝVœ«|aòä*~SñÍÕö¬ì,´ðµzZ_¼Ð; §é ç‹Ý½ãÇ¥„€O½aÜÝãÝ§{dxS6»HÕýºÂ3f6SÉ‘åîÚ†ØÍ}e®uõmA¾µ¹]]oV{}1¬ì5¾S:ÔÅ&´Úà»‡/0•1È4Qõ\…=Î=²ûÝÞî÷I;Â?ZöÑq©¶~YŽ¡ÃÈ±"ÄÈ0rþS“ð¿rºÓðä¦æTvÖØ °ÖnQÁC ãçþå¿üüß~þ×ŸÿùçýåŸ~þïðè~õÉ—_âÿ7ÓÖ>zUR~¢O>J?úÑætÙJÁßûÆi0ùkö®þè“ÕFFj4È¨¢=òË?@÷ncûö1ŒóØçq0Î§ð÷{ž¡¿Ã_}‹*G¡¦[æf°üùüò?ÿOø/¶§Þ	Ã}é7‹Ë°†y>N)L>C‡r/Aö‚0D™ÒEâø8üšgåó`×wû/¾ok«TÎ{a:ÃŒ÷AÂ{¹BOQoPŽQ˜~~\×¢bùéßµZ¢RiÄúÒé¶$DèƒL*@Ä·¡÷^Pƒ£Ã“ƒ½ö,ñ$ÖAˆ†.8ÁõËCØœŸTzë*= ‡^%ILŸ˜[E:½GW9,kmXjwH^a@*sInKÂü…g¥Ù_JNvß¹-×!Í¯+R3óØ§NòãþÉw†ªVÞÖÍ<N§¨Ä|;HcíÃÉ¯¢ÏÕÏŸRAšÆ¥b”ßAÊÄ)ecl*¼FS¯iãlëyßÕªw+y¼ï&›ˆr7™,¤ÖMD-›äe¬¯‹,­‡Ýö¢€×“ýk£­Xô¢Ýt	b µÒÃKÑä,åÖöÄèË’|k[tdO¹m\”`xŽJ+xÿÕ¶Sá N„£ˆþ†ã……ª²N’ÙxQ]U]ÃåA‰rlü½ùÂ­`ÃîÄ—?µ»V¦NÁ4±º%·‰y*’‚UNkÕGu‹‘J£‰§/eQ2_„®W-'KÏW8ùú¦@Ý´$©‰¤¼hÍhA\ú‚É®©<A;UÿF%7ÇÌùÞ»ãwTqíXzgâÞ$ÿ×ÀùuQÏ×9n¯óo—;]+W8»&¥'•n1yb4òlƒI“W«sj4Qóîã[ÄN€Æ0êÏêHœ§FYÐgu»â±z¸"®ª°"nªó½T•‡ê¶¦÷V?Á»’jê(œ6B.–æ›}1_/¾¯íu®o ºK|Í­„ÏŒ\-êjº]ïhŠž¡‹é+ô-õ¶/<ÌÛžë(œˆ­írúqÕ9”ÏÆÖöUÕ”ãª#_Š¿§û´êâ©`[Z‚7·÷"’|ZëŸXsi;OOÏÑÓabgM¼<½H¹+RÆŠt‰ô£œ¦ùHýMh](­F­ë¦Qkn“9bºþÌ·íxÁlÓPÞ:ð£ºÅp#,¹\µV–S Ðgœž„G¼™Í«;Ä–£­ã-óÇ¥ü39ƒQ-w—çÔœ6éB¥Öcs9þ`¹¾ï$*’qLx£¸pêÓ³ÝóW#A½Ð©)ÍÙ¦4¬pEwÿöfÚí³â’Q-[i´Åé43Ôòˆ'–ÖVöm$‚uV¥Æ¯*eÙMxIëæ}¤ãHÂ$PÑ*.¢ÀØ;:Ú=|º·Ýz¹¹¹ù¨¥íð±âs´~‡—ÄÆ†Žæp«¤a:9Úÿö[@§bšNÎ{u*•	g§±º$ÓOã×’´\î™°/Ò!ííì~G
N3åÅçûVí_ö0KTv•ÝúVvÉ‚R> ™ýKô7…±_fy’X-¸O^ŸÙ¡TYäÑ“’ËÕ’ýŒÅO¶*Ò'ï½±uí.oÇ•¹SnÅhdó|Ôƒ1ãËÞŒsVV»ñ®­aÙ8ß,ŠK“fq[€ÆÄ´ªéÒÈk¦—à+RÇX™Îp‡ RÚ02€ÁQ;BðÙ¶jBÝÚ¤F6Ø’œ¨¯¦½ÙdhŸ5d¯rJ\ÑŠ™
Í»ËäNÆ×ÄãOrd%È0H½ÏN/±ô&Sb\¨î ¹N4mšô~.Rí¨U+®™cí+DÅIž•ã‘]æ¥¹K™ŠµÃÀþ‹§{ÿ!8áÅàMœ´™
]ujsiÖÖÒÚÆÄ™77[È gTƒmK“PG0R|¤ÍÖ¦;v:×âRÃaù†—ºF‹já¤¸Q@[@›”l]\½åÓ)¯*½õi–÷þ”_3sqmùÕôc=[JáÕ‹WøíÉþ.ìŠ¯S˜SÄs:SgÛ3Q(?³»+­¨ùþL^òÃÞòà93½Ñ,ußŠ:m!àî Mº‡V²^yÄÚ#9<¶$Î]1upvžÃ 'Á óüs*„Þê$‡¢šS{hSu@S}ÝcmL•cÖÖ’Œ
©Ð4Á§ éLê²ÜA‰aØ•¥LCQZèÔ†Ø9Um_Þ8qÇqî¤ˆ˜ä×E~#ñ†£t4^¸ cy Ýˆp8oƒ(p¨ëÌoR·/ ®Xé!TmÃlêÉ‘á4Er{ƒ\ë1ýÈnW¢âÞùé9æÄj T0pr_}­¤ƒûŽ¸s Xûô§œÇý½k®B‡5I<âk¨í#V:I/Ö±·«¸ž*QoÚ:J°a‹'íH–¦|ÝÔ²ÓvòY8%å4…"S
²ÝÕXAcñ‡¿,ùÇ7>Ý»ðÖJÉ ZK­‡_œò×‘H¢Š†Þ…Ô/Ñq„¶¿U˜gRô¤Ì÷ƒªÀv÷#&<pr1¿6øgÃìU]‡Ïžaú ?ËfÃ©¯ +ó)EÙS”1jÌ²Ó¬¤òwˆ?¼?5!ÓåÓn^KŠA~9.§çèý_¨p	ø.Ñ¯›âÁAâ;Þ8:8¦Øäü"».Æ“ºl&Zü2+_Sª3Œ“7ßÌF˜-»\(ÞånþkÚÿã®ÄÎdG‚Ø(cÅ¦ g°(ãAÊÛhì
Tix$]6°oÅî%k’N‘ÂÅÞC/“÷.ÞìóM»´T% Ënz˜-G¤\¥+MOEÅ³›ÄM¤€â*çúFÝ@¾qˆµ.¡ÉeVŒŒZ|z1ÏÎ/èÌõÑ‹ÒõÙÓ.ò!ôòDå`™“üiUºôužOþµ;Ý¨šÊ[¶dçéSÀìƒWÏ_b©pŸðZ˜¼
î{J>à `¤zù›Œ’pŒG&…ÍÁQLd™ºk>‹àƒ4¹¤¯#éß¸[’=íÛîÐO
ï{/,=i»‚ºÚíÓ–EW;?<ú#2õº¨æv)â3)àíßî¿ðßÂ<y®CÐä#ìŒY•ÐýT4¦ðþÛ£ÃW/	ªÊ”àíw;? ’â4ÚOaö_àìµq;y´ÖIÞHÔÁä²+‹tÆ^œ—U³&ïòA~žõoÕS>Ñn„ìò´8Ÿ)C$á»­âJ8 ”´8±mö;x)ñP)vÚ¿0W\z­’ï;|lŠaÚý1EÀ`šÓµ§‡aÚ¹bš˜15ÈâàJ”ù­ƒÝ5Ú xl±ÃiÅÓ„öÀÖ%4±í •ô
µþ-XbcŒ\Ö0­ùÏ?ÿËÏÿ+¡¸¡ùùÿýåŸ0¤§U_uÍ?Õn8dkœ:PŸ±Èú„)-,šà tsÍ§/Ô@(Œë‰¬‚ùÑ`¿Ò”«Ø1§-÷Ú9â×;{ßÎïæÈÐöÜÔßÕ£ÛÛÿö™µëÎÂ–Ã£=i÷d®¢¥£÷Zx&ùº´UÂ'ŒNñÞ.ÖE™áìwzíôë““ ­¶O8WÛç ÇÂK‹÷sYÈµšÎT\ÔZÅj£Yhæå²WŸÃèÌ-¾!°1Å\‹[ŒV`|wdªºŠÅ{[“Œ£[ã$™Z­C€xIuL¦›Ì|!\ð#ÔbÁåŸ™×ä¢ylâ3½Ä¾€Y¦Ânâ;RÕ×,"× ß‚}‹A¦RÞGM¢s­ 0'×EYœÃbzÛ]@Þ•.óžbÍÄ‰Ë©:Î­2å³Œê1>‰]¯F†HÝçR¥{Š²¼åšWtÛ,[«ÓðÀ„]÷p8€Ï²ŽËŸ¶òÆg®^ùß|õu¥m½{ÞÑÎ½ç€Gû;=1ê=ß?†G»ßµn+ê‘×äñÖ€Aú*PRGÔõ­¡›µÀûÍ¯šî×ò†[ ñß’>à"›ò‘çwY€ò€%`ØnòëyÆÉ¸¤
ÈGgãIßJ¿VD
ÕÎGî	Ö”,FÙäVä{Tæ±ÙMÊ[Ž'"@Co§¹;øK¬-ž ?pœX[2)~“û„4hð xÈ¬ùuv¸“ŠõÅ›;¾‚õ×ˆÓÅÂv•¹Žk±¬ç³n@pl­uÙ¼Ü?gCgÕ4ÍŒLÉ&»ä]güâP¨kmŠüšA(+Uét«r„Úïì‚LwÜP|ànn&~¢FšÆièsOÈËTŽ0N£Æ	ô^À¯oö€—ì½„»ô°¥]µÇyéî«	”HI_MÆƒƒ	œàX‡¤êq³–,T,€W4¤« s
x®9_W ¸ÏÈì¤ãx
–Ö½·ÒàA¸ùiÉâ¶áòÊq0ûÉU×“2Ü©-/•¢½2vÿmgö_ójÐÞÉcâÅSÂYqàùT·aQç%‚ÃY›]‰[ÑÝ·7;éTûF§žÛò—W&ÂË]ïš,²¤•ÓÅY?÷ŸµAR¹l«K›#mª¯-0¦ÁŒöcñœûÍÞOšÅ~µîOË9'Ëâ¸»}qwhKÂªÇã­0é*ëF©{zWc€þöÙôGÝdg8ßC='èÙÀÜtÈI·JÇË”RBë¶»”“¶¬{cr¢¥´U‡ks:\iÄ3zä·ãŒY=V“GR‘eÅXzO5A‡4i"ÏáoWM‰VØüþëÙÚÎ´ür3qùÝŠ³¼Ûæ[	Î†¾2•HLIMŠŒ‹¶`Á`üí¬œòª5EQé=XÔÔ£örc2Ï5vd[5uÕ4˜dgÓhd¿ÛÇ\£¾ü:,bÑB\ŒK²×IhÇTíiÜ³ÙpHyw&SÎbÈÍ¹s,Ÿ]Vâq"1E‹Ýáã¦`¦yß.CTö4'¾Iö'xƒDB›½<|o0wùdø#¤cÞéûÊG8i¯ÏzkâaÄapîl&‰!Üeem;Xt¶vÄÇÍ`ãTbƒ.HsÄmâN„Çë¦hè95lNÆƒY¿¹'iÓH|nKT|þy–ÁRMo]Ðægéguù{	4ÀÜ¥>2T¿î«o÷^ì¡žåw~:F–ve¤õàNr|rx´÷”‚ùFÀàöÇ¥
=ý¤>±ˆ«“ÚO>ÇO¢Ð,Îo¶ PñÕ‹ýß¿ÚCz®q"U»Úi ‚…w'ÜAMÞWFd°8uPƒ­ŽDÈˆq:¡F¼/±¨•4µ~Ã²!ÙRÁ@W‘ê›èéÞñîA¡•%à÷±PoNÜ"^V;	âs„žÍSsÏJi*®ÃsÑKç×ÓÁiUç´]'–=ö_!_"¯{rK›RÛ¨dß¬¯°Ã ’¤áÝLžþ-X·Jœ‰t³ŠX“]RÕGš˜¡T´‰å W0èÎË—G‡?ø&NÝ\Wb7n†õ7ˆ–˜¥8µ¶¾ùCf¨?«Ö+ÑoaúfA"Ê÷û(±­²RÊG-"‚`1ðÙµBlúeô!.EÐËzz¨†N€‡‡/õz[$Æ3BƒÚƒ"ƒ)–c[ íªg¸ žX´m—Ó{ì#¼ìŒ-Qëë%-Dm7nH5íU,ß‹J±o….5ïúŽ‡x?è{–7‚RŒd}ÎÿUµºÔ$uÁE0¾¼Pë„9J”BUÞ»¿õ¤Rç®ç€Àèîþ¶¬J*JªD¶»/`p†°N’ïUEa…©­T‘½Ú=Hs«'/Ôœl¬ƒ¼’9zwRE6Ìñ¤ì®òQ•q:±©1TØw\ðR³­·ë!®{ÕÔÌŠ¸õ¸UÙÖT¼‚PŠi^M7ÃlPe2óÇÇè¨Í-‘dk—hÇBY÷£´Õ@Cÿ¦X."ÙK;ŽwËG•™\*¨îówÊ÷ù§¾±C‚´0’ïóO»É·{ãÁ™‘SÏ7õ;“ÔÊ@b´$&ŸnLQ‚ÈdSÙ#Ñã¼xø¡1¸(/žÓ|”Ÿý"›ÜöFTAU^üy˜0È½”KØÁdÆÄÑ”Bª<ÏHÎ©&±†eö+ŠƒGŸ9IÐ¶ÆVÄü¨g_m'Ÿ~þ¸#šâš½š{þÂtì5·]{O¡ó/9iÖù$
ÖÜó¦éY5¶ýªg®WLZXLrc_v)CUOœmÎžó[/]ÍÇ|p·DVÚq(Ž˜ÐŽˆl®õ2/á’íù~	—L7~q;R÷Ô™ôÌ'wï¿±Ø‡ë¾ÉdØ wåÐ®Ø–ÃùI›Š&»L±TSó ªñ©¯@í•ê1ö Mš«uX çFÍ.[¡Ã¬×y>UîãMM#š¢û”ë¸nÌé}–ÈU²õ¬®f#ñsH²u½×ÝËŸ™¢¥Â“]«´
wÞ&ì6»`¯zµWìU/vÉr7±k6x£.Ú«^õªåç±«’ßT/:ãu½ªÄå7v-éWþ4×I÷î	‚Êá4–ÇÃ?ò­Ó|	Üû˜ôW?ûY~ê³¦­Ï’ —À5ïTŸQÃUø\Â"Ÿ ±<ŽÌMÖxûl|ýM¾$‡/öÏÏÞÑÞï_Q–ãÅ“ÆØ#"Hô	Ü6¾i§âœ¦^vÒVKÊeWŽgå»°…úXàÊwê¥ú$<ÝQ0UƒºOáø7šÔ§
9·=\å×>nÊMn{hÉ¯C²±]%%ÜÐG­íÙt#Á³í ñ¸IUÓã??½êî¹²¹Î¿³TUïÖö…ñ»t#wïM¨~:þ×Ðéà¿÷«äÏ­ª)¸cw+Ÿã;Ña|×aô&WýÓcìŽ/áÆ”@Åä²D@¢«ˆè5$I©,Ž^îrò:Œ¨´™Gð6¿mVËt9ÏQQºQuœ%ô ·óÙxr‰–fÔËÙ”[–ãäl’—Éî~{OiÊd0FÇ' +Ž@·aÌa>Å Æñpv9â,Æ‹ž^QÀ(*Z%-DBLçHlz‚‡GÇ½³âð0ÅÀ_8I7Fêb¡ÂÓüá´[ÏŠ7	á«¶Ivžáµ¡RÍÄê¬È®ÑN‡%ŽaßmÆKu_`F+Ø_,KµYòwùd¼>ÌGç°oÔYr™M^ç“E¢kãÙÚÖZ["B­±~ÕC -RÄŠÜŸ<ýÍ–Üƒ¨æ—²"ï¦úbVïš¡^<Tª¾¸Õ]ákŠÒ<qXãj"Wb“©)u•„µ®’H±«$Ll(}Î«yõpE¯"áY&9èÚ‘Sµ¯¢Å¯îŒ€ÄJ5Á¢qá<Áñ‚÷qR-†E-ø|A£HI¬5Î×Ô“Ç
»ª–ÈZ›bÃÃú#©–¥„WÜÉ/KÏmj+AÕ”Ÿ—¯¢û(®‘{ƒ²ŒÞ——Á‹Vê²eR*:Q4–S÷{>âßÉïX~š#CT×â‘ë*lÉP~™­ØÚ¹OÃEU­+Õ²–XïjsÅ¾_´@—¿kÛÆ“;Iª¥ºiÌÔëj”¯è›€É³°v?ŽS#yéWñ’ga)/~\_Ïk‚Ôœ¥õmpˆµBB¯OÌü;‘Y}Ì1æèVä„2ÈR¨l¢”ûkQôh”»Ýn‡„íû<¿‚}Ac_^QØ°ÉL®’Û§Ž)sÐÝ°/“¢q>Ê0Ãé;>'!!¾£Ùð¡²W~Pv¿e÷ÒÁCpçÖGØ£˜Á%Â"õÇÙ0/ûyÛÓ&›£¨®o@ÊpfZývžŽ1ù"ÖU¥	ªÀc})ud¨ ÁòªôêÂ5kÓ+ëæ«9mZaê–8àJ[QwMï	õÂš÷ÅTïk,ÝøŠw;¤aÅY\ÏááVCÕÄ×uTUÉWzóUóuy:úJU]}ÓÌ<¥}s_¤¼_¨/ÔâWúò´ùµ'Ï´”ûÇË|áéúk‘i]Uý«OB€sGŠæÿ3kh>8æ£:ƒÁ"&q£Z8‰A¢Ìo‹ü¼7O.³añwyG!:¼·ÍTR
|Ç#Æ-x¢ÖÎh ‹¹æ™úâÉŠ,ß$¿ÊŠ	eó»¼æ—¬ZtŒ  }üÅ;æî¾hàî&9°Ÿì1ü0BsÆ<s‡+W´˜›ì’õÒ‚'¬^7:·)–WÛ-¾Zì¤Goo·¢“mÉõ†ÝI;Öè!*üià3f:­ÐÂ®]õi€ã«_z0‘þë'Ëãå,ª@ÃŠRøž]¡N×ê™Å•	£c|çž]ãý¬5×ËvççAn^ÐªçiE›ú^àßd¢À­Õ±nï€Å-¼aG{/vžï¨Ì-¢®÷'ïáæ¥g>ÂïÛÖxœÉ=w'˜*Y«u÷ïãöd£ÑŒÔ”ïñîx)êîº9þDÝÞpçn|Ëà¸Ù¥§¯j~ÜÏåÛ­e·è®´j&‡ËóKžÜí[QVŸ¾pÙ{¹ÜF*¾g.·¹Û>¤³íÚ*œm#ÊÇ:ÍcDíX£s¬Q8Fµ5ªÆ¨ž±^ÉX§aŒ«W\òÝÖ”|œhWä@{/÷ÙÕ»Î.ï8«uwÛó\fÃS~÷•Ug0ü â$ÎDïØàä6~cÜb¦m{Š3UÛŠÌ¡Ñ¶§NøvUíåaÄv¨ÝÒx±(±BËjênæm§«º·sëÒõæ>8·¾ŸÎ­»‡ÏŸïŸ¼ýÖï`fýÙ¤˜ÞšŒû”{°wž]=d¸îïº˜ ÑðÐhëý·ÿôÿ$ýá¸³´I„Èîë®PÁ·ÆJ€¹¹šŒñ<ôÊ“,¥y‰RòHbwÿ„êË?%íÍÏ¾ØØ|ü¸ÓMv0§ÿxt{‰EÏÐO6ŸpñÐŸ:®ÛâžRŽ¹¶&§K9ŸÁ\šz±ã'R¡„>&ýÉ¸,×¥Žø›:º‚ÐÞMŽüe/kÓÇ^ØZ×¬W¤¾åVí‚=þ,Ö>zòf¬ˆxks«6ÁçbOÑíKdÉyqœ'“†¿©¿E§fò%Ø03ÃsjZšèŸt>+œåæ'ólK©a×¦{4m`É®.’ŒvÐfÉìŠ_×_áM‰äu“c™=qÎ8§)²|â—?ƒ¢qéá–IÊþøJ•¤š|:Î˜j`Ó¦®.äYLU? z™NóÉÈœ¾o¤¦ì:yÃ~@SÜça~^L,ÇÂ)‰¶ø@cB„>ŸaÊ×‹ÇŽæ¢OpÄ©„s1QU!€T”ä§	}´ËI#»*6.a†CØÌ±ŠÏúpKuÞØOwùwx÷†fŽïÏrr%)7ˆiÞ¸ÊÎáwíq_’CÌKxŽßaõMøòQ7 ;MøÉÓ­'ŒÍ®7è®a'éÈO“´ÚýÂí+Ï¡§º¶ü“xÓmuP¹ÝÖ–b~sAâ· —ðÞOfn3 ò'Ýø…p|^ŠsäÂÊ‘D'÷êdÁ­«ïe‘5û´¹i„Jo†e.–¬É. 9¹`u´ƒ·5	!ïÖÙ"y g«Uäæ§7ùX]âJê¨T QéÄô²¹_G"(S·ööÒŒ	Òb	Çµ7†vÒ{]LÀ*Vý	Ù¸³áƒ1ÕÛ+üÇLú—Ä™ÁlÖi6‰ÌÎ@žŽ”dvn†’Â‹ôÕC,ùÞÑËõÍGTh0ùl+ù8à@f%Ð#ŒQ’
„—3Ìy;ž&§y2˜1ÛÁŒí÷Oªæ7ìÜšèzà¾öØM÷#rZ@T#Ý®éæî™XÐ«(#ú³ÁþŽc»2ióCª¢˜Éùm;DHGƒÞtlš§Ðåô"é'ÀRNg…£ŸÎÎ“!L¾z]‘5ü¼³pz3›…Ô…ÖdHn½èJk%$Ëdê“ç 3J_yÂ9ÍO¤<ò0Ø:ç¬0AÒ-føðÔÖaiäë¿Éûæv,ög“¨•‰¿NÕÔÎ$tÀÐWÀH°Eã3xÂ_Q•rìî"Xîù4g<Jµj‹»í¼{ÞM¾œš-9ÆýÞlN‘AC¼‡¢×_×IÊbÈž)\ssÀÑŒØ`2¾1•â×iTZ™)Ã&Ó ž	Ï×9P=’‰ìu‡½0ö¯Z öÁ5„ZqëùÛï¡²ýÂ…‹ü\rÎ·7>ãêš®7oB¢²Unp‚:R¾ËïÉ²‘Š’“¢I%ènÐv4+]@*ØMžã`}_³Ç7•åð¶¹mÜËÍ÷Ó1P‘Î–ØA!¥€÷WÃŒªÕ°¤]XJ´î¿œÁý|ÍBà·ùh#ÃF!"2kñ¶=áJ³ïúu6*J-ÐÒþ’DÁºúYÙÏ@n²ÛÈátËÓDÄˆvkŠñ6“bÙÆ`ãÆ$ŸNnŸ˜Nˆ8y”‰ Èßd}DÀ1Û6#¬Xïg“©>"@›2Àˆõñ•©0èIt=šJrÞÍNwåwÈ&"½ì’n	‹ÿäG®2ƒ+W«Dz²Õ$~¯–"ìi_ºÎ#MÎgyiVÄd«¶rÅ"/y³Ø¼cýÃ[[[Ì°S#`<	Ógï§`¿êGmn³ÈÚ˜B^²4oætÕŽ.Åa¸È‡ƒÖZ'¹¯¿<0“Æ\N.óg³iùý,×~\0'¡†SÃ›<Sà6å°¦›’ æ¿ƒÒü0ž–Ÿß]2•s{œù¯ØÈ%TÍZÖçg“IvÛãê¶´B¥âæ²É•«þá{Ï_žüÔÛÝ9:	S+;¨d•li@SFø-íkçþ0X3ÛÉÎÉ«ã(aJë41gØÄ4š\Âª‰Ú÷ÔÛpê²ÂÝYÆK#¡Q+’fùŽþù˜]:ŒWõÓšÒÐ
[l,{O÷É•¡e|¦ ¡ù4+†Ô¥y.éOdý°\-pÄ9)â»mdmnr¯ÐTsŠòH.tôTJYÕ;À¿)ÿÖ#?Ì? Â,ßSNó;g3¯.òœ„æô\¯/€aŠ%rÆpŒzUæP™…“ÕBÆ(»îÔÚK.ÌÙ®]—d*QaîL4…R?ÁÙ°}SÁR%N_ÅLýº_+ÀQBKÂÑý¦V,<6 µR]ÍÒþ …«µLÂÉ˜É˜Ba„#æÈy9›òÊk³sziI4}mÓÄ7ÇÖv"ÉŽ×¿þºå^´:ŒzOìGöfO,R«oÍ{üÒ* ±Ð—{;¸6îK´ÿjçÅ	ÜÚøLM"õ&kaÑtm±\Våã%ö²æ× `g}ytøôÕîIç–›­—~:ôÖúiÒ“D1²jÏ5ƒ›ª6.RÈœK}HÍKÍÕnû\®R\í¶Ïåš&ÌÒnæÖ<¶|ª®yªã‡BŽÕû xý®º*Þ«Ôr´jYÞDGsÏõ@‘yT&aËhî¨>ìHi*+œ…!IG9É­µÌEÀË£½ã½£PoÈé¾„^vMw;LÔPš.¡¿Pg¢%ùÜ7Hpß0Ë¸A¢ºéŒx×¤½„àbå:ÍBËÞ¦;¶î¾ÎoA\ÈD4/•pZ’‡åcjÌ³4)µæÕFçÃv‡º5¾Ø)=:OP\Ò“#:±_ý¹lÓ¯òxÔè)d‹=Lï2›qÑu™k-êÔãBˆ^°èFUƒ–S­öB>ñ)zØÐ©™¶Ã28oûšhr‘÷óV'Úk§â‹çxËç}Zéµ’©®ƒVaÿÁëÊ Ú,>†ß(ÂëaBÈUì¦KÙçË®ª¶}l'fœƒ}<c,;¢PQ³§Þu¹"ãÜ=‰ÿ¼B!¶Æ„jP!èjåè]À8éoÍu'>†îCzÑ¢8]ÛÜcQÜŸØ:O…r™qt7Ž­0É…Â.#Ke:öJã¥Nu«+’8T×+P¹’}tJ¹iAÜZ˜8à3IzˆOµþ$¾ÓKm›—=¸ó¿n8’ó?ž‡•MØè¶ÀUZŠQu‡•X‚­Bý©õNcÃqäGƒÏIÕMZ7¨¦G‘ô¦»jÔ®ç˜‰Mº_çÂ¡-Çiä-”¤Ûž£Š§þæ¹äV[èN«%¤÷&£7ùÃ~v‚·úãQ¿äµ…ù4™u<<"v¸ >Ïépí,†±*'0'ch<!ÍÎ†Së ÇV›µÀS«fÐªÕjm8ïÝSX›ý°¼â¾aQJ¿¡d="öª‹=Ê2RNPÀm°›Haª¨BÄeùƒ‘[×Y?£JIóJRYãÊ	Úe*MŸ´ávd?Ñ,ƒ6ŒõBXærž¦çN³ãè\÷¨ynÐÈ4N™ ÛaÖž7î¦°‰Á¬€Å‘Å6’éG§8„Iß7EÊ	HôÇ;dlê=ÛÙ?Ø{ŠO­ºóø÷{GGÏMd³ñŸ·Æ‡·á,òÅ¦Wkêf<yÅÆÞzEúcªH¿KÜ®?Ø³3¥ëRn´‹²e¹"ãMzóóG=[æÍ+óJéÆN—…q"š±9eq› mpÅð)µ¹ÁõÙ7à;’;7wá1’¼[³âf¯I·V¿JN‘$¯gX(-i;èè1LácW˜®7Ìçì¨òq¤„¹¹`fb\MŠ2žG~žåþ“íéO®Ì¢±ßï •eé˜ú,¸Ëó±u	«„|ÑšÐ=˜cÐ)+ÈA6Ÿ\äëÊêáÐ%~‚¯O€¢LèÒ'CŽä(y_f@dÎaå&#Ják’1³Kq¶oñžŠtœãQ7^ŸGWYSA§¾ÄÎ¨Ïi>‹Üûb„@_=U6z™ê¿¥D¹ ê’ÃØšzGƒq†Š€^™ÿyÆg~Õ âÂÙŽ#
jî=
J!™ƒ‚H«=ÿØï©^Ž-y–dÉ`’My³½ÇWœ÷½ÖË<·~DÂòèˆŽ®Ì8ž8ô×›±wöpn½,€O+ÇIX7!¹BpfA<¹Æ=äfÄ/’éEwÕË0ß!¡ºJõy©½ò­îq`’¿£Ï Ýšc]Ÿ_8z1ëºW­šÛÞ‘]Ø\n#n0¯©Dßd¤'>?^eÚ³²×Xñ1°p=G:Û-K­»—Ù(;ÏWad¥²Î‡?"›³®î"^±Ï$¢·:‰0W­ .Eï+VWË%V×&¬Ö¡æÊÌÚüâ[±–ô~ôùîðÕñ^-tê(xà©çÖî5¤ Q¯ÈèWâVé‹À5¸1â¾ä¹†+»°íÔ[ðÐxÏs~×ÉØeŒWõ3ª+)þ †û»T¿Š[âWl‹¯ª!¬hc©êíe¦t•ÛÛžßûwy‡T4ô•:L)×B­IŒÃñ¯±_ÖWŒP‰6ƒ±}®R3Øé_L¯~æížßs‹.|ÄtçÆü§+ò*ÌW:¹
¹îÀ;W'½ãMþNAÑèûÙc<‹Ìm2‚ÁêËý¼?)Ú?Ù{Ž#@-S;¹ã€ðmê«±ªwV3m;gÿ¦…ìæÁ¡SäÇ*KUfz³£êG_u‘m56¼R
JÂEÇw¤šÏ°ÍÂMköž$s¸oÙ@W´¼PËlb`á¢(Ò:y¹+WB`Là½LjUHs‹Š9bnòâüŽúz3²$Á&ÄF‘.ÐH´d6îÖ®ícÚÇ¯ž[£/œ+»RdÃèŸu“ïÃ'Ø¢7/sUä>Vá´ÞZÈWhóšJ;›¯‘9ôÎ°ã7õö^KYEÌf
n¬0~¥pßˆHBÄý:÷a)øªåZõîÙY´uE#B¶VÀs…I¢ZÝ«²Xx¶µž‘×«¢ÂØSEwúMÊ¹*Á‚
ÍXFéoŽ«v¯¬T-}SsyšBîèO/È÷YY97Ö1"ØêpÑJdi4/Åêµ°Â½ðdmáÓô7ÅxâPåå))Ú³+ŒåÀZTr*:6Ë,ë’Ëì–-&¢b1^âuMŸÄ4Ø]Rã"Ÿäï@9[,VOøÈ®kgùRºÒPè•ýþjBiÚÞ¡j‚Œc“‡Ð1¼ïÊ„ˆPäs“ò²ºiaÃS<An›íHÊ)ÞF7ÝuB,vÏw‡ç‘Åp‚¡H)«YÑ§G;ÏNZÚåø«ŸÍ4Þ­ÖjiùäªN>Y•lÒ¯P#wT…Šµ¹dˆä‡ed³£	Â÷¤‹;Š<\¯za{®Ø9°Èb9l¹=uNë$‘D¥‘E$‘¨r5W
‰íN­,r9ä]Ê ÎÏ«Ò¿'…xÂÇZ tT@®H}!Âp‚o%«¥*ýf‰òI•×ÛFÆýàÕÓ½§Ý
PJ¨q¢>p ª–Â©fÂJ.)©üª…Š(CMwƒä[)$¦¸*UDQÁŒ³•ä‘Î2¶ü}ä«dñß[®þkþ5ÿÀš?Œ}+H"2k·fì·WŸ!$Š›
°8‚Ø”­©Žãr¶$\XBÉXOöž7£ø_Æm]w½¼ë›=ú"6¿°J@Îý¨Õ€ïàŽ®v¹;úÃ=ûážýpÏþ»»g#Á'ñËöÃ]ù¾ß•udÞÝ•oérd§xßm—oÀõ¯å%¦eIvÄ06ÊsLÑ=M†Àša’±ü]I³UÈ+ê$^È9%—î.dšx—~¸ÿ’¯Ç [Õ‡;ò¡îHk€oÿÖÚZø(6Þœ‹Þš
]ø»U¦TC°£&¥ZÛ‰×."ÏÒmèÙþ–.Ö¯š„³_î–ŽyÊ„}þªoòÈ5ô¯o	fóïo»¯x‡K‹Á»ð'©÷¾]Ñ¿¾û8þ±C+½Úø¿ [ÞÑË7ý¯æ¦_êF4T†2¿VïCûÆ]‡i5*”Óº|¸'—µåF.ƒ·xQò66Ü“ÜàÜ“UØæ¨{?ØW?¶®¼W^ã•gÚJ®¼ˆ)öÃµ·˜¢·BÛ]DÄÛƒä%í	çt¶,
ˆ°8,äüÆ%8Ù’e’gp ®³Iç çº%%' ƒ{åhïÅ‰3\Š½ë"3é@úX:¦:Lœ¥at0É†ÿH4ägÅÙÓ…cbÏ¤c?v„4©¸^¦•´+\ê¯&ëJ1ât£>VÚ˜Î&£’j˜ ‚PÍã< ã–­Ìr
ÇàµÉ3Ã‘r0 ­Ç»°Wvö}¯5]rèmŽ‡ŠâÍoÓŸM¨~Y$öÂâ],.#šÞAð9Èð@ñay©³M”ãÉ…â ë*óÄ#X¡i•0ì¼|ytøSÚÅØ„÷w¬SÂoWžƒãw´(wäÅöûëóÛŒæ›Í¥5¾H¾ù)q¹Žíy¦*W@šÂgúŠxpÁÍd…bˆ,ðvÝÐÞ ŒÀ<Ž3+²¼eá¨xú­»nüœ¾öã¯Ã
L£¡OY…aÐ™‡+ÓO£“M«¨š*ÒjA²ÿ³•þvVN1QDËgd[~W†¦»ñ—L8°J‡QÉÈÐ¦uÀgsX:[[RÜ}5ùvžþÍ«ãË «þ’JÞ…Ê2;úgáäŽksMìû;ÿÕR;¯øÂUaÀzš¶÷®›ª8 #»Ùdy]S–Ãa™N*§æ®Hp|r¸û½$0:þîðèØÃ¥qÁŸ*ë!$$†[#:bþ°‘ûµ0æ«‡……ñ·‡µxJt¿ÔÎæW-ÊV…ZýíÃç6ÕA¹d=œ .õð¶ó›>/FÏ³7€©GAòrü}0¾‘ì§;Ã|2-cYOáÏÒå[Fö‘§üãpv	òètl®z.š¿^“ibg~èáøf™ÏÇ	kåÃŒœ4ˆ› vu”_Á-“Wûñœf\@šÚ¬™À’2Nø¢“c½bõÝdoVÑà  DÊ‘®DÛ‚Å¡a#ä ÐF`©ÚlY”jÖ(¸º”©Ý}s1Æê¶£õÜ-ËL%çQ§*-2ã„gÜSÖK7þôk­`9Ú®®«×ËwaKNhqYL½„iSR¹”X¤-ß0ìÀ"$a™XdÃ¬ØLYeRwLÒnò‡t ŽÆ7å–Hj~çÚ§Ù¤?`1Ú×³0e™û‹ÚšÚÃ‰*H`2uH•úOc¤:3Wç¼‘k¤ÝÏ¦­äï“|Lÿ¿nuÞ¾Î'Š_kÕ$¢‘l•Œ¢uÖ#¦Ôk$úOí–MA*›fÿ†½³¿G™ú;éú©$B—ÈÄ75¤‡^ÅÉ	¾j ø:vt*4‚DÞº¡°¦÷R¶%Ç´:·¸â‹.„ÀGwt<ÍÜ« oŸ˜²€ ùÙå!¬@Ýž«—X¹VÂLˆ8CÕ±3¦°‰j¤Î‚p<†Óîê÷¯öŽ~Z3Òçœ/áX&z&¹:NŠËöUÑ¶#é¬Z/ù#¬pì“3éÛ5ùIýZúâ	=»¡¾±§Üyð”¾K“§ñÝãðOï -ýu•OQnéTš:"+Míƒ°i@„¹¹ÿ0ü$F¨åÃ(ÇÏ¿%z|ÒÞL+»îŸÚaÖëV ðî	†|ÇVÙ!æ¾nímAÅ„n•…>¹ï\x8¼¼œ$¾G·˜•¯pN¦Ømm>—ä –ùhç@ªo¨³”IGRû4ÀMµ×˜…Ã%J¡üVNa,kübJ²D×`‰äD‘qQ?Ö6$CeV ’ÊŒ•þ¨&ý1}Û˜Q°#Øyøê%éÍ„yKŠ”(„¡D¹É £ß`»NÚR†I]lJSSIŸ2ÿOÛSª›-+‚ÝêÉ'.Åà2›gWjíå9%ˆµªV¹YwŽwUZ[þóÊÍÝ;	·Q®ê­GãøP”³ËËlrÛ(<l;{ÉÊ‹Óq6”ïÀ‡ýaS ™bx;-Î-Cï?¿ötœÕs5L˜Gðl¼Á³}£ÛÆ–`‹äÌ¨˜ ·Ø7Hª—ýeóI@Ä—Lïw†Ì9D¯*úD ÂÂTÉäUÀùÁŽQUi‚Bÿ ¬ATûÎ
.a¶~>JÏ+mŠ¶P«ÝOÒÛBMÆ_4u$œ†‹ÁŸ²äËºq±¾nò¯l*^s1. 6¡	àgJL´‰òÆ„À²²dbïkbê…zD\I™dA`Â_¦Ü\“Ã_ÑNs‰÷òsxù>	²ÿn¤Ï÷O¾Ã3Œm„‡Ö©ãRû,ÆWŸÎá«Oæ«+Ÿ»,z*ÿÜoaÄºLzÁX&—ž‘Ç¼kJ½Û~z¶}N"ð€m÷v%ÜÇ—³U[z]ÙÐ‡U.\/­\¸éºëcÆu˜®ŽñãZã†n»¯vþsÙyEf“‚ÇàþÐBŽ;©¤–dµW‹¸„dt—Œ®»ÿ?   ÿÿì}ÛnY’à»¾"·0’mŠ–]×–Ëµ«’e—¦lI%ÉU]h4è™’Ù&™t&)YÆ`Û3h4æeûƒÁ¢w³hzf³_"¿î—lDœ[œK&“IÙUºËRæ9‘ç'"N\xRE®k°¥X˜†á?7¢`8ƒP‚Ú&•`—üO}vöß”>Q0ÔåÛþ1*ŸX‡­@ßâ¶ðÅ—T³•k&üh]‚jâ‘ôI¦Y ›œÃ“Ÿ—žÁlæn5£Ä”è).¡”©)Ä6<6 DI˜#R#LZ²ÎŸ5Sç‹¤ˆ3³fÛ ûwG7úP°íäÍ¨—]®\1zšŽï’Ÿyt'ÚC(º"áð`µ,Êª‰ÐZñpšÃeTOZg-zg\0ÓLÜ’S†þ()¢Ï0Gãž¸Ýˆa›€°â<iÓCïoÈ:¿B§r™ý^>&]ÆTD†ø5,iØÃ1½L³ÞoÒ!íô'TTÖ¼\§ÆðÍt˜äÖ²j8‚Ó¦Z,[_”ë@•åa
XyWL<Â,n‚á?J°)UL§¹ïç)SAïD¦ªtÃ¿CQà‡oªŸ:ZæUAp–Qœ7ÁD¨ECõÃ¹R=eÌötIeõ'ÙÄ6îma ™ØàÒ&y
ä˜ò’ºIM’V­´àäÊ"ÿý÷/ü0èB¾/Ù—ân×/à¨3V\Á‘Þø%VØñ`ëpëÙQáX5XãÑO?_H¢¬øÍs8·o+5FK1š¼§•«ùœÛYêÝê‡Ž°jnq·ojHœ¿7}^Þ´ù¶®-¥ÙqT#5Û7Ýò>æ(PÕŸ|®%û€Ï]c‹/‡n=¿}jÂÏ—ëdÍµÒç6#â¿¦ÂÖ
M	JVfº2=ÿ–ò1`òeN®sOQ¦.¨ñÔÓ"5
ó²~¼”¥7/,aÖ	Ñ†¯—bTÍ~¾6aqp†+@òËˆYï'nàN"$ÜâsWšÅg¸Píq*9fd®Nß1Ÿ<ü[a¶Nùžßoð9ñà›€·ô]T{dƒ°£ÍŠ]÷N¤ëžBý2ÛúI‹Óƒ¶±¯ëºuKØ+°Ù‡nuÊõÞÏ‰c¨?qõz"Z²=éØÄ9j½´Ãu$!Q¡+YÝn¾®r´1RG[û”£™Mªa÷¹’ï×†é0©7þÜúºì#Ž²ní~wP`R(ùÛßF57ÊLH¶ÞZ0Ð(­±©ä\¾ìšzr2ß=ÈIøäÄ½)ö+¹j[ÄEÁn¼A7‚u½m³üÊl`[GÛô½#8'ŽŽ­;½…ÝyB—÷ä‰pC6á´rƒÌÆ¸4³ðÃEü(û2Æ}ßßŒ$ãîF‡I§˜»-'Q`XÞa÷ZŸuû%¦hÉÇ'ýÐ	xü
_ã,îPE“¬r¸ é¼Œ‡g@wõxx	‹Ú¦´TS•¨¦6:S-¬úJ÷Í¨Õj‰B³Qt¿¥†ÅÃ¸™÷r´€«ÃÁå&µÓsÀë^rñ¼ÒSÑD$]öÎ& E90œoGÂè&É(’OîP‘Zà¼ÃñÝŒÖ÷®\©À¨ô"º?4µHè¸ˆiÄå8Êt/V¸ÝŒb˜Šš\ÅuQ7pœ%Ã.¹?iƒ?^¶9…Çô Îà0òFv–¥9FBÑK‚÷eháO¿O{@IžÌˆ÷N@^ÂòÜ¤æô‘võ*q£¸…1tOàyÄðh1°¥ö&4#Û¤gŸ«6²¢K®~H3;8Ü}¶uø}ôõÎ÷Zý:K†m¼!Oí‰È¦å«UÆÞu¸óŽÙ½í÷ãymp8Èê mo=ÚA`i¿+T¢ÈVŠ
‚"‡ÉÅ,ÍýQ$ô¸7H …£ñoüÆ")ëpr©õ9ÁÛhè*Àë\jk òoï?{†¢`®¡(S{àÈ¯]ýùêŸßþ.ºú§«ÿûöoÿÛÕðëÛÿúöwoÿúê£«?Â/óöoáí?Gõ«xû‡èíß\ýëÕŸ®~ØÄ.ÿ~õ'èô»èíà—ßÃÿßÿ¼ùþø#üûwÄmk´ïàîÞ£_8˜Òë¾i‡¨®Q%ÉR|â¦B¶è@‡@Û\qÜ­ggšî²Þ·;O5ÿ÷¢ƒý§»ÛßãøåØ?<OúIgüÁ”a?P‹"¡^ÖšH"õVW¦‰žãÝ@T—5=fšpÍ$[Ð\ªÁ’s‘ÅS½¹GßöW;Û_›	aÙx)=(žeÌ4–ûgH..ZÕ¦‹AEd¤L„£o–œÅY·ŸÀ9‘žÊ[Ù~?Éj  ¥¢ÞÎH!¹ˆ¢\xçˆÓMZ$áq¾nòˆIqÈ»Þ[s'´Výz›?v¾cr2ƒG€»0P¡9í?}ÄßkÓH ¦ítšTl¶©9h“ñº¦drváZ öÕ¶ {DÂñÑ
¬éˆ—<cþHkÛ˜"ÍÐ7¤d•î>yHcÈdœ·ÎÇê\S…‚RÔÆ²õy”L¹±ÿ˜köKÙÙÚþŠ¸•Ò„fA´Z¬ÈÒ»¨÷-„O•Q°ž%*=‚–ŸïHawq±Ý¨N¯ÃE|~F‹Q÷=<³²!Hyâ[A.b,ócvÇW›ÈÔQÍ#Øs¾/(ˆì"ˆç•Ì U‹h‡­¡ÛlÏ‚Á/em"«°mY|amþ= Ž›õâþoß4G“¦u5žZÝä4žô¥Ÿï+_‘ZÊ-….rõ%k¨+ÎF K¬Æ!Dq7 ð…F…»'éà¦ÝwîVéGcÀ/fQ–¶8Wâfð¼ð:`-[ÜÖ€@ŽéèuŠIî•–‹wlñ³_üú=8‡LSŒÎ)ÔŽ­N"£çïF÷66ZðËÏì‹‰0s !Ì´OrÑDÍ£¬ç˜¨Å[xôµÅÊNÆÐœ•ìç4"Ì*á"E‡[A+Ûf¡iZ$–Kë]ÞÉ’d¸Ja"4à©·ÒÓÂØ˜=Ä»-Ö ~el~xp›ý£Þ öt†g¿ç^T“G¢-î'R•?ÞÕ±¹U.l;•f	êo}ÙÒkwÆý6ÅpAáÙ±«gF8…~ÿ·!uËIè2Ïí´¨ªN+/1jqDmbúý¸{Ys£$ ŒÆÚ@TœÛºøàmñ¤/³C2²Ç5YGi5Xu·FßTi Hha+>¾¶s‚Íz~áOøããK7næùV²=Ì¬ßÁw¤LÜÒü°bÀ5í¨èšVßz.àÓ;e–Ë†€>j•ÜZmZVÛ¥Å£Ú)bI<Aµz¾õ‹òbÊÒ«#\æŸ/èˆ?Q†)ùèý?ˆÜ“G’W“$ü)<ÈOÄ<™ÿD°B¬ç?(^×’®u( @&R-ãPÀO8"ÙMŸ"Õ™#	"Â2*;9ô	¬ÒN®t !X6b>ßçƒÃýGÏ·½²¾$ˆÏÎêOÑHj![|¬c$5Ö‰§æ'p²[ÇÞ¶U7%qÕ”.…:Žo\M“ÿÀfŽÖt¿7Lh¡á/Îªb}Nææ8gkòË_Õ67iÅõT´À]Ð:äƒÖQ¨j%óÍ¼Xä1p¬·¥8½,:Œ/¢g²g˜F¾tl2¢k¨©€qÓí4•íú¤¹lHåXÉV9ˆ•‚'.ÚÖd5wÐØk`ºÙó™ÍP»³ Ü=/²ùÒà·º­õÝ¥x©.0ÅK})Y«ö=¯ÍßNƒ“ËBš™DÅÉfÒ:ôû2uó¤•@¾¯Pq{*¾(~w¸ˆpŠ(Bvä^ìº³ó2¤n	ip‚0ûÏ¾~r©·ž–s­â3UNÚŽdò	â¼vÞI†%Þ3CMJú•e›¨P©ßh³f„HóÒ‘+-¶$š8cÍýtÃ°LXc’nêI{5G8Ó-ƒB[Í“›t{ï_U—RúsY†ä[‰EôÂ ]cn-¹@\QöôqËóÊÜœê†¹˜¯W7Wëëÿbõ¸ßÃõn$ÔÇáH(Ç‹¯ ì©ÈË®Ì¥®ØÎq”Ó¶jÛQnÉ)_Øya±2ýÈ>6¼£"p8,è8à‡À2qnó üêî³Ýc“HúéÎüW¢_ð%{9fÏ§{û/’|Ò*ö¨ÞœÁ—z1ª˜ *4XY[½’´fx00> ©ž^˜;%s«D/Ì¥–yqÚËrë2ÉãýØn¸I’rtTØB b{Ôñ¾²¡Â!åFnšh ê½Ë™–ÌsFž09C'½ÚóßÇÔã,‹/IXõŒ”Â¬Ù Šf	ÒN|äÈÆ/ïý*|1,J	ÝkëÛ'¬†“ùÎmïFºÍ9=í»"}|êóN-ZŸw ;
%rM!õÝyAIÆEÌYÄÂbâé³­_Ô-ÈðžS€sæ(BjæÈU3Õ{26"[R·3=ÖÕU6ƒ¡z#ž†žÛF8{hó4­cb3ÞÙ~2V!ŒôÞÊqÏrl¬±üf”øþùr×-zÃ(·Èz"é·Œd«˜Pn	÷–pßÂ-³Š­D‹#b×I±€’iL\~½/bR?ÄæIM”°V¢”~Úòò6Ë"ð¢úöþ“£è4Kä`%2Ë5d|ŸWø]ÜJæ@7‘¡ï¹H{M¡%Š$ÉPRÃè=	)KN;2H_Ãš?i=‰z9è†g1ÝÅ§C}q9H*JÈ|õ*f¡,Èÿ6Ný7AÉšLI¾[ìBŠxä¤1c²Zúý¨´ÐZFæÉBéörQ3ì5è¤gy  r’™ÐÛLç+tËÊµ´‘·llQOÌ9;67Yš
S(‰ÆÜ°7ªÚ¬Sá¡~ËPw(s­¸Q>Ë-Q 0 ^1ª rANlŽ“Î‡d|,dñ¸^¯O#&_v9YK:¿Ã+Ã ñH,P¾2½¬×keù×ó©I!ˆëX=Üm¾x(¹“ÕXRy·Ïãjðc2wNÉÜž´‘çã¹»óÖ““ë†Ò7|Œv®Î$K°puû"Í^öÑôÿäp80¾“ßŒT®„ÃäõDÂhý‹èðñ7øÏ‘²M}3IE
šã¦Ï¾â,
&ké«äÃ“t’Þ9:i×ŸîÑ£/ãÎ+ÚÖ\Š/i@õäMO8t@BVbS#ºcF‘èÏ*+ŠÄ{É…ˆÏ%})¥@ÞGq?žå½n"å›³¸Cñ¸£	p6âõ¤×y%ã=i…ý²ÑŠŽ¡ÛÁ~DQmyôBKÂ/d`)ÓóÐ¼ã®àwMè'#ææ¥¼ch!ÂÑÏ"AGz(‚"\)#w“ˆ%ÞZ7‹OÇµ¨>L£‘¸ i(X":ÕÕ–"uÅ_òÉÉ 7Æ[øClfÒUP2ÚEoHÐ6õKKR[ÜYäJê5Â´ÎÃäÊAErÑ‚}© vi+`M¡3_'WP‰“7°:Ðs=(0Þ~ÕŸ>=»ÚÅè<&G)ø†L1¢*õeíNÔ‰ó—wOâá+ø}ë ÷b‘¶›F)æMŽPB·N0È±MÜ½¥èDã4*(–öd<ÖõŒuÆJ½ý>í&š…ã! *ÉÑg¸pž½ôå#Âèdˆ•€eº[†¹ë¦ÛÕ¸cÒíštÐ9í]ÑF>=E²ÑoVTB¦êÃ4O »ub-åè"‰_%CƒóÐ÷]M„±ÑÒLOÿNÙÐ»Àä¾³°¯†r¨X+)³­(På‚¤· Y³.Ãù¦òoÑJj|Ó1 œ‚
–—ƒs°¾bÙð#Á¥D°?ì“á~õXrûf„ì^0½Yz‘“sbÿ²ÑZ{´ýÅ_¸ò¾J<Ì…|•}/†9Ð!¦R“7]é.,F†Œ$mw^&ÊAf2]—A÷q@	}’)sIL<A ªPÉî›è!y6þ¡67öøcÃ‰SöëŒŠ Ë6@÷I¿¯l$Â©H+>ex+wzïèøpô¡(¼$r´2UƒšLcáãoXŽ“øï_,:Fí^Ë’È$*äÑQÄ&I3w¯ß™‘ z.EçÒ”¹9fžïí‚z°.¨/•$ßQI”Š“ïp«ƒéƒR]Xh"Pv‰_ì§ ]Ž@¾µ(ð3ªf	z%‰ßIð±S¸EôÒYß´ñÓl È^6@‹†ˆ5,›º_}kÎ0Wum’‘».}?y3¢a[RóEwåzˆC¨lƒ¬“ˆŸ\sôŠÕµ¬ëò!•KµX¦’ú`21•fRòèÒ(ýÛÛß]ý/LyDI“®þåêøãï£:<ü<ùfSú3¼Àÿ«ÄJ<SæHš–"Éý²2?í{VyÝ¤ÎRE3Ë¿à¿v^#²c¿ÞEVSq¹×'QX¤»‰O`›ÄY›O;]ç<XÍ8Ú§¯j×>”,p’®ïîì>Ù#Y7¡,bÞª†¹Pðš³Ë+—E²wÛ†\š1mÊ\÷Ç-WÏÂÆ™·{1SËºB*¨MýS qJŽÊU˜°fî£RÄ®G½½?‘Ã‚ð9 Sþ'¾³[!« ®ít˜´Ç1°ô±´¸¯ßL7°ØC½äÂ«!ØÜl<GEþUÂyDCNX@ÔQJájçØNL@|øUFøaqd¥3ªæ~ªFnb0XÂÇOwÝh¸Lé«Ý½'StÍÎKrÀ…Ó¦ù|Y¤l+ãËnº´y`¬•¦|ƒ·2é›s³‰V˜M¬úoªdQu–2oÚµf9ÆZi2¸µÈJçOµ^ÁâVq—d†5‘©à®µ&ÓaÈ5‘¹ÂfÙù…,Ç»¶èÝ5Åë-útrÑåY³òE¯Æ¾¤ìpm&ùüT&$ÚM[ÞÙ ÍÏ×ª[]»Ï˜ýEÅ9©	·Å6šOå"\€ÞV†g3­h5`rA·0bu	h{#«¾8&t3Ã_|òÅÃÇß¬Ô •¾^’rúšÙŸ|I{¹6¨i~-p%¶(	[Svu2I]ÄY7lzêN¸þL7ý¼ÖB2×ÀòïW?¼ýýÕÿ––¸ú3<øãÕQþùêß®mgÁoú¦|ZlM©D.‹TìZ×ë_B	4þ[]¾œ._IQ×{z#º¹ù:üfcªÒ¾	K§y¼k)ÛDÍ3Ë¦DžìˆO])©¸åjue‡+›8ÔpÉ"Û;¡Þ`È¼*Œ!‡„Åê*}–©ŽA„„IÁÞ¯¡}˜™ÐkÚbv¹qMâú¶JÅa£]|¦UßŸo¥jƒ¾ó}­?¿‰HƒÓºÄJµˆ°<VI³‡ðxÉØŠ®Æù5{UmD«3+$\¬Ô¿W……N²E¯Ûw‹âG×Mú Š
Å]ŠQËèí@ØBäD.•íyÇÕœQÖ£U£æÈ¢<¿¿úªïüít…& Ý-¤ðØä(YMÓñ-Pña0YœKásû)ëAÅ±ñÄ3É15©!nDk*þ”Ò„Ôª8
.N·ò?w-U+ÄQf©CŒÃ”\Ér^8«ÕÚB£t%á9'[ÌOUã+<-€­Eº]QËé[9+Äe*!Í”×BÙ°NLÜ¤×ói”…‹1¹g\Ýª o\]Ò¬RE]ÖŸÜ#»cBntÅàrÈ¦ §Eyì°
Ù,ÍÿRß¾ùwº±U¼L¦6ÕÔË¤jJ2“sq™‹³„r;.«Ôº<¿b‰N¤ þÏ·¸úWºè¾Å þþñöo—[‚2fò$ß2AtA_Ñ¨Î0n&ÏAù2oeùv¿Æö¥šÚéB+U:ç¤ÊèÂŸ\±ÒÉã¨˜¦XºPI
A+PÇ;VÕM‡båqªö8›ƒ)Û5õW	²hSµ3sk„ÿLÿ’»KKqh¥.Ê¡Uò‘ë8ƒIÒ-óÜMJ–*Ã¸1‡V9Âoªª“œ
â§ªæpçkãf×BÖnÚÎmEŽŠ’Œƒ>gúXZŒ£"_„i¨<ÓŠVvã
ÝVý†6üÅ'Év“[HºM™‰BÅ–P~‹t„J'å&‘@’&ÿ*j(˜Híå&ÌdÿÒ±›¤Ø¹QŸ¢«YFLè4óR°WJž¿ÄW%	¸¼øe,ÂiºH ã•­0œ_%$ß|ˆÙT¼¡ú·(—
È¯@c:ÈpÞz>XÇx×þw;jM}…Z™è©àÒ²Œ#1üÒËD*wH‘o«&“‡™Òõ4áP×kOãÙîrÚö—‡[{Û_|¹,eÚ’¦ÉúK¼?»ø¡]¶ß~þ…µ8lló.‹XŽ6¬Î³­c³.öÊ°ìlßeU­R ´Ž ÞBÚë_|Qok‘#V¨¡PüÑÑw2õ[ÄÔkÆ¨šÒA ©CÔ›v°xS˜OšV8x“]‹TbJŸ9×ßc;Ð´™cÓä°0ÕpÚæûŠ6áÃ›Š6ÂðßÅÀÄ~£ð`0Ñ°'µ®5×t1K–¡¬­ýdx6~Y—M©ú;G._$ÿÚÝSdð3ë˜”fF’ýŸîïèÃêb+mÒÐÄ.ä¨6nÙ¦Fˆ+ÌO»Ç;ÏÚŠ=°cˆÀ&ƒŠˆª¥>õÃâE›ì.¾éÞ¥7µa£iœ{›N ®DÛ††o”}†}]¦].9e_ÞÜT'}a¿pV°ŸFzÖU—Á2™M*E§›÷]½
5•'Zø27JGk/˜¬úxYOZZÑá€<ª)µ%ýv'ºÇÙ$¢w€QVÂFªòƒEjëdMw'k6×£VŠ!Õ„6B	ÊT}›\äŽùÅöÎ‰~”qzèåðèºþŽáÈ8Ú"‰²ýxk÷)ÊL8úæéÎáá3•»&!qj‚Ä"Õ”½i
K·Ì™(~EŸVPÃÍ=§¶F8Râ_ÿB§VYÿBe¹«<Çî¶Z+Í÷[>d!ù;²­ý…_œ,=³R![‡}×¥â€,©ÏHû`ž€ÇDEk;LX´–T5È`åÎygu¸óœ%^íÎ*r2.¾£g{"‡ûÄY3 X»P¡ÖâÎ$™Ìê&ÿ¼µÐ²1Z%¦\„ü½õ¨MuÉŸ`ò~´”[§µ¦tXPzÄçEÞ¬Á¤N*³¯É;9Ó‡<<pÚÜTÞ¹P¬Æ;9Õk‘ÃîÈˆ»ÚGÇ[ÇÏ‚Ô “.”ª^ÄÌÕr«qŠçÇzˆ·u;Bèà{¤qQ”®0*( ÁA`)v<®
›®¦°ÐÀ2ã¡Çj¯+ºqXˆW4:wƒßS©lŠaÄ²U”"bvúz‘rØÅÈXí!ê¤ #tE°x¨7_¢”¾Wm±‘Õ¿ÖOðü~šNE0É|fS%
¾§vÓ[;çÙÎ‰Ä3™6E’	“!Â²aòDI	ŠòµÍrf+¥u,)¹Ç°” Í±ÄÎH´Ì%iÆ½øÖ²v»Ž.Åu—)ÅSWºáqèVÈü¨ñ@béìö4š§S¦‘I¦)/Ím™!hänºrÞRAHsŽ=hû“ Å:ñÊ­êQ ú:=·+Óóm—“-Ù8´NA›Ëf&%ù[+õR­Ô+A¿Ÿ´ÙùæŒÇ´øB½´ö¡fŽ˜Ÿ„Áåkn#^½uø3mÆ¥wÂðÕõ/”êƒˆrÝv‹è%è0ýe8ûO·
›¡JC°‘ÔoÐ|úúGe †éxIl#„Xõ°­÷ôõbí¼¿Y­÷ôõMÚwÉØçeØ@a˜Å6ÂÒþË0êÑ,Á"jf*ŒÄÁ4kïúÕ¨é•¤jŸæý¨x1IŒPE¼»AP	"²l{ûm1ôGíožïS‘¶­uåöab^Aspˆ¥=˜_ i½æGiJeï
­§?oÉƒ55`3B+ªz^CW¾Qÿë–ÅCÌÅ¹Jé¤pERŠã¥*žòŒ,vS;5‹²,¾‡öUËLj·–X]]·T‘ÃN†!¬¬ÆW2Ýê0*+zJŽÄ­Œõ“’ènÅ¸9Å¸k+ó/çöÓý#ÁïõÃP¼Æ•A8Çr#œÕ^ÀôŽž<ÝÝ9$”ÙÝ+¿!àö8Yµ­Ì÷Ð6ÅÍ7ÀgÇß·ÑÐBª[äigŠô×³2«áÒl†·ÚöBÎ¾aiCæ4ÝÀ±§Èä:ØâL_qä‰LüzÇÓÏxƒÂfVt»NCƒ?,ÉQèâÅOfn`˜Ñ´s¹5#YÂ»òÕŒCÚ\ÌuÝÉM:K=±Äš¦+Â4e•q¹šX5|Æû.;,šJnÛ*!ŒãÂm%ÇšÍn.\¶i”ÝÜ „VmfËù|vsZÄ&ßƒ7í!±å/2i;Ä9‹ÎÇ×‚ÝÐâÔ\žnÖ&ÓÂ˜*zTñ>«ÅÚ‘oW™&Wj
¿·ÑŠ„M$¨gŽ°y]ô†C™ðL¤á,AT$!þ^±ÚY8f¡vzjÕÊ<‘ÊÏò„ùqÙÈÅ§ê,	ÚÚ éœ€.TëÒæ¸•ê^b7 }‰3·`-“,z)w¶wv¿õ´/>€K¿j$mB(¶3„[–MÓxKËþÒDY‚âÎÁ?l³äCP®œ:Igµ)ØŸ´œ«˜mÁö«bÚ3î^Èf>Ý¾kºMM¡CÕ¬Ë¯ê¡oÎåª”1–uan½óíÏÌÐÿ‹Å§žiËîµˆÍáòbQô8ëå$€v¯“"4#q"¯X‚êÖÍV)øã¬[ÖçÆš:ÿEnÊÍ¥s^é%}Ó+Ìzd^©¬môÊªè¨Y­ó³€ÆòÃ¶²¬«ÏÙ¯¸‚I¯ìX^i×øüÌiâ·1dÕ	›ZôÎ@è´^šDuBLjD×”¢#ZíyÉò$Vb‘ä¸<?ˆä½ÇVQéÀN4ÂÍºÄx™C«uÞníí0öàXkyYåY„:_ä7‹¿åîükkš+}ó|çð{&ŠI.¨µê¬g9ÂŸŽf	C<R¸®x¨‰Î°º{‡r¤ôÚšˆÒ°´ÖV§,cîà¤Ö{2Îzƒú¨…˜ÝîZÖ«l`½«ý§š5yµIÀ0ZMZðÞ'8Õ°.ñÙYýu‹Ýþá#ÀÙ/¿^÷[†f¶Ž¶_Þûué4 2§ÑÎ‹Ï„÷®ÓØÔÊÞ¼õí\5hìd±³MÏ÷Ž±½D‡Gx»)MH0äÀQ©Å÷Ýâ[YzXiÞJzø‰gŒù©i-U34m‡xÝò¬‹ì›JzP²˜|Õ@Œüå¯j››R)çK%9IÚå³ž°«í<>Žþr×¤ ’ü£å¥’É‘8!†ûYÙú£Œ2å¨îÝ‡a&½~Ý—Ó ° >Sx´{t¼§®˜¬?\álÑw‡QØ}ÎáÂHiˆ2;p¿ÅÑ­HåØ5—]9êQGy†ô|G¹4t3`]‚Hbß{Ë‘H+î“ÃýçHÛð	É«ËYw“3¼f$h3’Ü’`j~ñ!2‰y¤Ì€è´ñò¾Ÿ‹r*«t\ûQ½ÛËÐä”f2V,Rkj(°Àðg/zÃsnš]Þí']¼ý†“zŒ‰›_Æ£Q¸£ùª—£s–¬4º?8Õêé¼ÄS+¡qQ–¯ø’îÙÉøeÚur}uâüeížÍ°}íf¼)xê™CÖ|KÝk/ŠÍu»0Õô¹\1¼eïºe0˜TlQ©KRëÜbù"“‹iÙT±ðh<}÷>5,oÑ~l¾«ö!¸2œeHiñ¼ãå‚åÖ’y6rºëõ¿Æ ·€¥²M¿Ê×µÈEÓl˜³|ÐŒ ¨°ÐÁ—o5³7ð I7YÛT£CÈÒzÍ¤|ó%ãÓž ¥½N¢ï^-·æÚÀ¥
x1¹´µ±|r"oc»½œ4Ãv< 1ÇoÌï¢Í(îuõ3[1žvV?d{ô±P„¬5h'`Ö8KÄ'‡¾Ñ´þÇóý9‚QÃŠ»•ƒäHPìÁd‘Y¹†ðÚx½€ØYT€uÿr¶c…ÍZ£t¹èF^Ê—Yts[vô—±z,8ÒøÇ³¹ë›´òËÁI
è5‘:Pííï¯þ÷ÕŸ®þý±ä¡¤¾À YDëªÏž¢ˆòh‚ZÒDªÕ2¢V/þH²hºÅîÎøiUˆx½‹)®,,ðsºW§0ëþf6‹æU‚\}üÚbÖOVõ£ü@ì®ÂÕÅéËÝ^
=Õ¦Ã¹‹~gã¢mò`ÃY5¡°OßDìô|AÐ×½®àôÇû	Êá£€ç3}Ë¥÷ˆõz1XÓ|ŸÃ	ºÄ•¹àDC^ŸJ¾
½evIyØó
¹=¦¤s.öI“wÝ*”Ó»ù–í;¡Ó{]3XžÍ‘®ù$X³…ÛŸDè¼c;ä>„<ß*s /–oÊýÐO¸Jc¬’nU‡‡Üd®U>Za”u‹7eÏRîühÜõœB©}“ß‰ û j°PÂƒç‡Û_mí¬ÔPÏäM´ªG¸êL«Î‡çF·PN›ØÊ’«.fr%¹ÜÙÝdzÕ9'{CùUìyU}yr~Imd[~”ù Â"Ã
SÜû¨¥J”zçO÷D ÷ææ&œÜ5uIMòÛŒ‡ ÍÈKó']ÓìÃ)NúýKÝ¼I÷çö5^ôët’ãþJ/ÏÃó-ÔìbÊ›ñ†¶â[hVm†ðÿ‘wSßàsÞ/§W¡vôãí‹l9œä¢0m á‹©Øz’¦ý$¢6Ž¢ôü,M»yûô¬ðî\4È…™•“•–xßÍ
»vŠ_u{§§¡eÀ‹Ðóxä>Êç.JNÚ¶Z/4x›B8Žggoõˆeë%B/`ä4<~ãlŒž¸ZxÜƒ.ÛNx3²÷Ö•`š†µ:Ÿ8<¿ÅðpÌv#Â&ÄÑ|÷†¹ˆ±”&8™Œ÷$9M³$Âr¦èr/Ç/á‘wŽë›¿+ ¼BôvÛ¤Y‡q?–p>w¸×u…øožƒ¬çô”}Ã%he‚Y„ùC6n×wªo+½5Kú‚çÁ
`Ÿñ‘Vw»œ#ŽnÆqÉ,D‹ÓÌ‹np<ö ÿB/‰¾q[ç÷„âBã½·öþ·;‡ú˜ãwþ¢©äÈÁµº*‹xÓ›|1îgIÜeaZf)½„|EÛø²a°Hý¹Š:Š²îóuÔ•ÃñGW¼×Î\Ù+ô'ÑóÇÊ,9qÈÙÃ¹”ö™µõtšû‡øAr,«Æ¨ðùsh,••ÎÉÒfffŠ„§ãƒNQ­—Ž£‚4Š¼™±ÛV?Ë‡e¸©$óÈ@06ì·Š+Š-hYþÔ½òþ”Á¯öŸëÄz]»‡–-ñãG{$Š¾Ç†p0™Ÿ\7u«-Ä€VÙÍ¹Ð÷ ÓäÆµõ‚Ïñ6¬î/T	=ÉM¡hkDh—õß®5­ß‹ißõbc¹qðmÅý&LÊÑÕÖ ~+¥4¼¯ÔÃ_S÷¨ÖÄ{ôüYýD³þ†¸‘.xäzbcmIÇ¤y7¹
®[pâÖæœöI<î¼„m>‘~ÂÑþa€8~hU~“[•a@ù¤èkhc¸k†z_Z½†5õ1ÇšªBžÐ¢‚±ân'¡«A5å¢´t
#¦}÷íMÍMÛ6Í=º~vG²áŸ…ðõ¾9}¹šGNè®ÁÉ(P­á§L2îVd+àYÕ­°	±À{‹ïˆZž°±s7,oÊñø:€9‡ô(*gUõnkˆ†Ôès¨¯)eNk ë›3Ëk>îõûQ:ŒNâÎ+jÝâr`‹÷ª*5\Ópl!zß(~/ ®‡—˜õÔî—¶)ðY!¬"ßZ­ÚCü‰žî<z²s+ƒ1ƒO¢z:ì_–›ª¢§1¦8f˜,My7¹^¢(Èòb>Gt÷xTÞYzïÀ"­Ë‰þ\bÑœéW5VvMB2ñëo?âŽðÆ~•\"k0gÄé™¸ü8éIÁPC?g@BzºÑŒ¨F­„sXnVÝL	þ½Ã`–h‚šä—1Çlšc6Xü³Aáƒ»Ï|â7<GÏkÌý<K|ŽOú‰=ûà×ÙB”Í2Ðw¦	{Qµ†Î#kÕÄ7ø$‹‡dÍ¾#gßqfïô)Ákb›¡‘ÃÂŒ(¨ ®ûá7™¦Aü.r4œÄÃW5û9*^2âN³Q‰»‚q8±\-à–‹Ã†xT²ýñÈš±i€±­ô×™z<*Wä5“€ØÖ©#?Kh¨åçÞ™wÞ«‘~œ«›vŒÆr†°.>[Ä¼lürý`çðñþá3£þ¢ž!¯«Û@DÙe=(¡—HÕlë¥ëÚÛ¿¾úãÕ?½ýýÕWÿ]ýüóÇ«¿j¸%Ýä¢ÍêH¬>¸þv`ÓÁ¨Ÿ÷’`ê¶hŽ Æ€#<n=G.aÍ¶†v-ã)åU}íùÑ{û¿®ºÞÂ¼Ï.*nÂ9eEE?IÃô´:“oFé$xÁ*â‹X\dI´Xu²°Àøên&+«A(ƒ×ªèGç³h=2)Âìü_¬‡ý‹õp-«ÆÇÅ˜}lPn;«O]få4ãéÎÔ´ç¼êl0Ñ™¯ƒ[/•F,Ø;'‡Y ‹™d~æG:b/!K™rÞ¤#àWÌþ¥·àYsº cÝgÊ6-qØ¨C†õQÇ;F[2²s.DÎš‘³fäç¬‘í‘ÌOW6ºfº266âYvL”p/|CÉ`„Ì%º1ƒ.ºI6UrŸ3É¤¬<RZ0u(“TG¦¿ëµ\ûÎôtHöî‹K¬J‰«F×K\åcMôêTõƒ‘kŒÔ5ãöhƒ–LóT”ƒ¤Ó*ÊÜÁ{;~0~G‡öEgÌi¤b~È~ÄN¡cn5!AŸ8r€ºL&'U€Ë_ô€ìƒ&¥0/ê¤Cbé7%¨QÎ.0ONë0¶¤ÞÀ©Þ-‘
¤†™A§Õ·FbÝu:”~ç¡Ç1ÆãÞ JŒÆ¿Á·"w”u
k9Bçe	FÉ"êÉ·÷,w&rÆµ\/ŒŒ3ûÐÁnþÐñÎÓ¬âŽóF‹á‡õgŒ¥(DIq;Ÿ$%·sïDY;­™ûÐ‚úî‚£¬òÁ—-ëÜ{@d=:Èz-FûiŸØVtdsž#ÙôcÄäœMÔ³Ï k¯piîºš#èSqé™&çq"K[èg”d§i6ÀÐ)‘cÎÝ~¤\ªòUŸDÁÎ~Í®e
Ñ „w«=ìF¶·»i‘%ãI6Ä~ñ®¡·+ýè,‡µˆ¨Áy'&c–¦b?Î–aŽGs\Ý2³2yË×üŒèÜiq<áJoã Ly3…5E­æ5qP'ØŒ%þŒ€¸(äKìôp	çN~Ni,ÇŸQö`ku<'GbY¨•»ŽNCµrêŽËtÑkª{È»jÿ¦‰ÓÑ‚ðç8ÐØý®Láqoc£µÝµfÁ ‘>¾A*¸LIÍwV7ÄÖ|Ü½ÕŸmý%‰Z71,^€è ß–Ó£iÇ´>lGžÑ0â	çÈ‰ÊÊ‘ÈÎ‹m!‹ÈI–ÕÎ.ŸîëÊÓõÓ'7Tfæ‚É–9ŸSÊgP«§p)r÷»ŽÖ:ÄW#ò|ÖŠ¾Â"0haÝ´¥r¸k÷£¸3ŽÐ¿³$¡ã©ŒéåiŸÆÚRÁ¡G½³aTš ¿¬ÁËxx|žFÉ›žH¬Ü‰û}dŠ¯’d]¤Ù+xø@–|B#)P.Ð±ê‡Áx0‘ó8¥æP-W£©Ó·M’^5VoZ¸pu?3s¥Ò"……E
ËŠ¨§½,·¬âžQœ¸^©Ù¹(oà·[Ûu¼¯(M³U%#ˆ_Ýùk1²—%²ŒtumûñÂULÒµ	E
¬N7Ü–˜ê¨Pƒvâ7K<3,äFÅÀLÁ‹<ÕJÚ£`‚½y§ÇÄêóN-ZŸwZæÐ"ÁÝyAI¶ˆÂqC/¢:‡77öKY„CÆFÓíúsYõg¶Ì›ºu@[,mMµÆôþß˜›÷E71º…ŠQšjgL×9»™pEC{¾‡Lz‹>Â˜ Ý%H.`]ùÌÈ
Ü+¨Ãø"z¦`Ý2„[†ðþ0„™¯ÜÍ
ÊÀ,CÐäÖ˜°·³)ê¢\C„·¤¿B!~qb¼RÞ³]*l3Úøô“öiï‰ÈZèà€w“Þø²²ÕÂÇ€ 6¢]Kæiï4é\vúÉ&È¥o"ñõÐ “ö'ƒ!ˆõ§I– )µ7Ú‡=^âèá> ÂöÖs ¯ú)ò¡èätŠ¤3!¥‚*
lc4þÚOA9 ·ã“ýª.^ö@K¦Ž’‹dôÑìeÜEpY§‡K:ßØšÈ1@TØu“N?Æ0ŸŽßjµ"ÛêÚŒàYãè‡© ôB¿!ô!PoàÑÁÓ»£³£ožFéd<šŒ£óhà¤Ok’wÒQÒ¢1 Q©Ö¶æÊ ƒ !£Ó¸äŽ«›
¬·5è/|€zÞDÕaw}&ý®è‚úYðà765=§éWñ¡–Ze Mò|6-6@¦9¦Ãu"ô¨.Æ±qzÚ
 ./mºÆo„•C.hX'ÀV_Dê‰p‡ˆ*qôèKèãöçÑ §0bãÓû˜¨¹«ðïñî/61Ö¥ß;½¤¯‰µ”KU11ÜçE£U # –„³!‡Mtt
ÞºSl*®4îá2Ñ­·È¨Û˜¿€N3¼ùBˆáÿÔ$^5æ2ç-¬q”Â2öS@ð‹+­Ð!‚¶Ó¶Öªj·6a†

ÿ”×b	–˜œ]Ï5»Ð%h€i×ü¿šèß½ÏÚm8^1%÷ÚY$>²Î<ùH˜‡Ä]„~ù	¼\~MÌp¦(âNµ )IW$CaÈ\¥L¤0 sà»‰WÔXÈñ›A¢{å#Î1¼âWþ]Äw»Ç_!Ý£¼^÷ï&x¤kS?³î«õS/ü²,~—IvˆÂÈj×“4Áp$5—†ù‚Ü)µŠ`¬ð}÷›ˆrøM»„Ã”è_nQUkÍ¬©'–ø$X–T‡˜­¾Ö›‡Ý;wÌÖ®¸ûÁÇÝ¶Úvîmèl\4ÎKšÒ"$Y‰ú8IS~ÏG–eìuø‰êá ÒyËÆŒs·†÷°*Ø®lç?‘;Ï˜ÒÎ«(ùç¶Žïù.èiX€Ý.T7¾Zþg§ÙRÁzTf&¯(d;‡;LoFÈþ´%£~¿ZT*	²4áúáÞ´`’•´B¿Á>X&‡»úŠ§(k‘,‡ÐTvŠ<>O¢º$Íü «+Ò£õ/@öêµ`ã~zÖ’’íž@,9D¯HR’9J7{;ßòu“Óú€Èˆ2‘ìZÑ¾Ô0MFÚ3	OØ†¤/'Cg£81T[èèw1Ô@ôÝ@lC)ú¨b‘ Š ,á®øäðèøþÆý¨þÁ6I£Ãtº|wÌõ
Tzbt90ìA+ÿ~ÐˆÄ&$o@ìÙ4<ÒSX†3«ìQ†—5uPFiðwa)×ÕãtDwÌÙuÑž7”>²{O%÷nuaž°ZëP½)':KB&È¦ÃäBÏKbLè°)bª±(éç¢fæ>ŒO%º\„½ÊA¸ÅF°Xù¦'5]‘è¡`”‡Ô½ŠÎ{±#Ô`Ü"À¡3ø
ü9N½N$ñ‰Dñn‚V#3º6a@DÕpzy2wI¥½2©;L\$O‡„cñ>P{sÍÜ4…ó—®¹«¾æÊ¡Ê’BÒg¨»IYÎÒPULå“#Ó|Š'æºÈz*£™Ñ¥ ß6éK56#¡;b`¢œ$Ò»\ÇQŠŠ*ÓPÐV/“ÈÕZ+Ö¯Í!s©SÖŽŽ³ò©°¢ò\xºf€ØÁáþ£çÛÇnž5&0Wø§‹ûS“+S+ê¼vÎ»´óyÈIi)é@í…Q„3ßfÈ0FÁCº:ê”}B..á3ºb°ªc
ûË’„‰ÃóA1 C-J,…Drc}ÒÐ¢›I/6nM0Ÿ`	Âdù\ä7Ô’Ù£Ç$´½Œn­ÄónaûKL!ø|o÷ØCh<“,NŽìº×MÌ‘gÝ0Å©ZW†Á;³ŒÀIÛIÔŒ€ÑÁ‘Á …FÆŠˆ~Â#Ú¦9`IÅ#Ø àåœHÜ’FržpÉfks%“;ª“Æ9ÕòBõž8™ê¶6‘êÇAqâ¤¸½¿ôú|'Å•g³f®ü“¸DÈ"¨ô¯íV™Dƒ“·OaåSíƒžÇýDXÔ›,TSš‘ÄYjÞÐùáÔ·Û¾€×œsuõÀºÁð(zX?ð]Y7oVv¾{¥}ÍTje…?¨Ö¤ “WL®\M(Ç% ‹¹XlE˜:‰Ç¾Ú |Euâý´ûøFsöA“ä•Èp*ñ/5ñÍ9K‰T;Ë’6ÊìWµ ¸DA^ò`Aú&àOˆ51§·^þMÅ	Í¸¸MªÒi¡†fUêp¹–
§…j/_þÈ3 õ	ÿ)¿Ec§{,±ÎxŒœÅ£õSÌ¶UEî“õÏÖï}ÒØ6yÓJiŒ¤‰j=rL—?Šv$Ð"'m%Ž	^ôò¸‚èÂá€¢ši‘ ²ÞàÆù8Úøè38æH{–þš¤¸µµfÔ‚šìg6/¢:E(l|üq;Ÿœä¬7¢æ8Í©¨0Ô!*¸0‘$‡¶ÄEÌ6u!ö÷ž~/F˜¦ëAŸøö R_h*•7 §àz6ÕÝzï¡Â
Í¢º¸ˆ»7Fë’mðñ~Ót)§ƒÊn!éÎšˆ˜÷£Ãýƒ» J¨§¸'Hvmä¨ªšl-v¡øW©ˆ…µ›BÌáTqn0Fíôb¨b4ÌCbµìo@¥üqË<2ÀÚ˜*]_ü;œÑKÜù‚—€#°¹yÑëÎ$Ã;ÄKû}mçÉAmõÚ©w+Ä”Vë‰Y9YX¢ŸžÄýö8~£¯v>ÖåÌKXC¼×ÔU-¬÷ÖJxÅ6ü
j ÎõÓ‹$S¦mñ¸ÁÕ.Ñ„6äÄßÿá¯¢Úöž´j××±TVõg[»OŠ0tcB¦.V¡^6¢Ï£O®?¢ïv¶¾nl}·XT.A¬_'¦w’:G~’…žØ;ßXTÙÚ£ãýÃöÞÖ³¢
j*E£›QH8LßVÛ+·QIÀz†!
"¸0Q6¿}¼õõÎ^x~~^hA“€ôu±èZü—LÄ4d5$Ô£€xžØ‰¿í-s¸WÓ0£¦bZBî*ÎåÍ®‹ÆÌnCä¨Yðk…qbN§Z"SÜŠë^>8Î­äøÜÔÂÈsD Ó½y -ãEò+ì¥bDMÁ†ræôMÃËšAÎÖôù™w÷˜'c´¦ææ&æôt÷Ùî1¦>-Ç¶î\çë¤§iÅL¤¼¿x™ö»nÊx+!üÔiºj‘}»¨ç®n½Eg÷t.ö’ÙrQÆš²ªt7&o8ø+m#¨ÅƒdØÅ?K&Y£†µ¦ÈŠ,ÿ‰î]5Ã»ÂÚ½@b½Ìk“KDÞó^Þ“^T$T;ŠdB¶¨.ø¨¹§½l€IT¥õ…n!TD0@b6,>fÉ1X$²½€JPÈÓN<gt~9¹Äó!ÉEB[•¥p£M_>£Ä®x„L)J]K{Ø™e]\äŒõs¥‹šÓ¨i‰Rÿ‘­P>åWfàé©¡:Pìçxaze¥€[ÜÛæ|ØÖÂ¥Ì¶ýÇšOäÉ§? yùó½¯÷ö¿óø¸4—Hñhó!Ký,:Õ ª«Ârð5½¬î"×8û£—!¿=Ž¦¨Âý6a7âGËËÐvâÚÑ±Ð…gHÑVé¾Û•þy­æéÿEÖ€æ€!j4–Q h8 ú¨f€T+1üœ\QÉV%b3qvÖ.Û^€ž¨hU½Õ·Sºâk¸n¨FMþ§||¥Î§êzP™c:â¾k©öREPî'xp£ðÕbqM} pÏ€ê¸7êë	ÞHÿ:Åp7uê"qG¹ïÎa\à`Ã‚zÀ¿AgÀ@Í£H6ð!¿ <èô¢}™búìŒ,îç^D/ñV?¶œ_…Û$1}9=tÍâðüyÝP1Ù72pcäA3ÂŒ ˆôÔ¾3žÄèc)c,AOÓVŽæM«Gwˆ2Î0O‚î¨Âÿ”¦}Jî”"ü ’Ù#bM¦ÑŠ¾ÃUÖŸÄ&øpöãáxýÄ€×ÍÒ‘¬ ©‡w¿‹þ© Ó…=Q6Í˜/^^’uýî ¢=IaÜxï)–§OÎ^bqB×VóY¹xYoÐ ‚wk—„5üï‚|\ëä"(ö‘„ž5hq¦ù½’1i^×W‹`×*ù½’QŒjµùï`Ë¼7AOXº0A¡Sr>dq" ]G£+£çÉƒ,Ò?^ò'¹µß “žñ¼Š–‹¾?ËÒ<—‹æ¾¿u‰]šK,ó–ÌuŒ[Ìð”»¾Š9@ÚÜT˜ÂÔ ÜT*ðÞ’º;mÖÑ»µ×—ôºÀMÀ½qËŠ9€§è+€\à<É1sÍÑ]Å)ºp‹œ£4B`ðe}J™ä5¯(´á~Ñ-_M½2½¬×keŽºá™†"Ýt‰÷X=Üm¾x(y”ÕSy·Ïû²Â¨r'Š*w£ôp1IûÿxccnÇO‹{‡Ì\|}¶AR­C…ÂqÔ–§Ð²ÛmRQ´‹N€ë(Ôšø•:ŒÄÇ½7	ÒL Wó|¿žSY™“ËP”(Š's7¡«,ºÇÝ”’Â=‘ËX[ Y3¼êßøôHÖ!©º~°Ñ$Ã 
Ÿ~r”†”ðì¯7ìô'Ý$çöµAüJÞ É./æ
yzÁ†’š„çè¢ç¾˜hòfÔË` Ú‰&ú!L´×ˆÖ/š²ðüP@Wáã'õ> Ã4²±ÞÅßèÿý—ÿAâu– (®©‡L_aü–%˜æ“Q’áœa÷Ä(>jÁ)
(9NÛ¯z8at—,¼=ì3á­H±!5Ç>ì¶Ô]HÄO‡—Šß“i< ¥°ÖøN™õƒûð¡Î$Cçð—*ÉŒjA4!QÐ<Œ–¸†J®eç÷¢¾^MvtGõÓŒ›ú
Õ’§Wñ›¢WY"ptŠîØ°úúàq6’ñÞÓ[ýËK
~+“®yÙWxÎjâxò™ãx˜ÄiÝi{9²3ë`%‰öBÃLJ©–¦
ÕÒ<ðš**ÑMõ·©E5ÑjvB€°
à„Z´'ÄŽëMooCÄà  ,ç‹®Øo/5ˆ“»œ—“¯¢h£tÉñ¨–NÆµJ]<5ñuh¬¾.rÒ§¯jÚ,STÙß­”:ÒËÒ]žÂ&n=Gö‚½)½ÊÞ½ V "‘˜^:“ÛÕHG-]_”’€Ô»F¤bo¦HEg‰ø—×ÐÛ”²ãuFH_,£ËÃat£–¾K†F¦œNîWVi?aJE³Å®|õöUöWm²™¡³zÆ“Êç”TÃhâ@¥x¿Å‡ÿyÂÔ”ø¿ÅÉ™÷œéiï„œéŽj!r¦h,µ÷›tH÷i*.G7ûùFP¥QpÙP<p“ÚÏ)²Þ@x¿ñóÆTe£u¿´ŸáB¡¾%Þ±¼wï˜¸‰ËÍ5ñV?
”Ïl“ôµ‘¹	ØÛÐÑYªýçJ°@l<¨&àžHW@™x{ÒâT¡ÅÜu!àòwM	{bs(AB¹¬ì%O8qbÞOÜ˜w=ENê1£&#½	!ÌziÅl™QFhªÛÍAh|~x¸³wÜFOb|K‰T6Á†åÆ’ï×†é0©7þÜúºìCT
¬p·‡v¿;()”$·2á¿³¹©zh8f#Ãy#¦¦8™/¥ÀIX:qS
Ë‚%Y+‘³‚`7Þ’¢®»m–ei‰¾w§ÅÑ±•caR•':©ª©Î…%‹W¶¢'hzô¦hˆ´£õA/G}tÛï$ÚS5ŽJ‹Å'×‰{Þ˜;‰U­ÜG­è09O_%d›ÁÒÎ{—4Ñu)t`˜=è¾=vQƒ9Üùvÿë²õsìÐ–ô.\Ÿa
*²Í×ÞNXðVpt®‚Œz"ÅÇv'ÎÇK»B…„î$HºÊ‡É³„*¦{¼¹"'›³Ä¼ZP2¾ÌGAÉÚDÎ[ÐÆñLË¥Eº:eºKg8´E×l‘ü¡Ÿ§0è7êC dÌ%§	92¶—Ö­éýÖô~kz¿5½—›Þ§&i+²Ä:V4Ì‡z¾/vzÏ }k¶¿5ÛßšíoÍö¥
æòEëûíŒô›¶Ø ¥<´•&³4ñúÈS•6#G5!:9xþåÓÝmrÄ)T¼Z*ž µ”±A§8üÞ09=M2$6—»ÇŸ2õmÊ±ü8HõÝä4žôÇM™ÒŽ@¿‡.¤Š–-©8è©°wM‘úpg]hÂžî}ÇŠ¡œY­E¨}âó‹TüÄ©*}ÙØ|½ýºàìÀ›
Ð¦Îv®1Vºê¡Ï>:§P^‘qÄù$£œGKÎªùÌ¤þþìC ˆÊÖÕÙ@DŽÀÍèë'Íè`û¨%ãN«!“|Ô¼cØÈIë°‡uöpÞK.Å‚v<–NQi¦£‹Ô:é°“ŒÆQl†ƒ¤ÛC ùäd]‰ÁJ>Ra”ÆÃø„Ây|ª KËÞ•9Ù3]#½O	MÐŽÕMÞ$2Ó«dÐb,xš ¡fÔë#¿ÄIEýª…Âî´qïC<îoÀ>ý¸aÿ’pŸ‚b‘b.™cKçó†€ÉHø»âhsáDx¯¥öJÛ)Ö¶ž‚ì$usc¯”1JMu¸ƒQùˆåÞ†	ÛÜýVtð5,|¾{©RcŠ<'÷î=@÷M™_l˜$"DØ0eéHLšO†’§hWo‘÷‰§:º˜À$:Øžõ=ô‚ò¤§Â‘!áÀ°K!\À1L ‰*‹
Î¦è5UÖù1ï½oÙ×ÖDÒ3©L?Çt	Q]ÅNƒN*¹˜Q…Ol$áÛ*}CÌøãVôe]nô51h5ŽHµ€!êÛÝïllÛ:Òzx„ŒVä-Æùåà$í³DŠ_tE1J.ˆìÙ'ÒtžKÎ/¿d–FŒ¢è ðš{Ÿ¹çúÚæ.J¢Õe>N+9>ÚŒ¶ ­îÁŽÖ¬¬[üÁp–¬£ÚzÆ¼GÒN%ÞH1Ts*ÜµQàGŸjŠ<ä’ûÉ¨ÈuŸ ¢:¢©:'¤­Vñt:>l‹
?Åžï?ËD'mŸŽ¤“  )KÏ—cùk5A{’ŽÇýän'ÎÆ0yøìÁ	@ýs=pg;7#ë$ÓKVÿr’¡íù £ºþådØŒŽâI'i„ÆÛî÷†¯ Ö¯Ue‘ˆ„Ó‰Aé÷‰ÑªA£n·Àtbòr¦G)<«øuÉÄyçÝâšTŒnmÉèàp÷ÙÖá÷Ñ×;ßk÷Y‚åu‡ÝtÐžˆ{kñ+Õ“²8i5öùÞî7Ïw°[‡’ÔF*Í‹~©=mdYK¨ÎE‡oÍè½ògû«í¯£º€µpeãfm'˜yq‚Wë1~Xý3\eÎ?ÜyºûÞöŽd8¬ë(©3”=Ñè¬¦Áã+à¨7%PLÂF1»¨ƒ·
:„sÆ>Æìïô!ƒOA}P½}QP­Oèö@Ý9y=>æ'…ðò„ãy^%&‡œ.”:@Ãâ$ë³vÆj©d]þ—U¢
ÏÆë”úDªÄn!ªVì±†²Èöþ³g;{t—Ñ2ÞPEµÝ"Îü»u2ËDñN.‹)¼7Œ˜M„û(­2=Š¸Y|éBp­Ú%}|¸ûä	ÈÖîÁlf»†	Ì@ìÚQ)ûöá“\<ÛÙÚþ*:ÜÿÎXTÊª_—RÛ‚x§ôýó¤ò)²\6Øõ893ÙŠž}V¦ÊaeÛ[GÛ[v4—ƒ™ÍÙýb ús:+¹7mŠC«î¥%F3r!ú»!iñ/¥ì±BÔ—a”Ï!O<)!s§¡©-¹?tÅ’¶=	ÁÅïdmà§¦@ù•J(zX×Cï¥ ¤[•r`«Œæâðü"Îé~¤ïNÂnä?.– æ&¹ŽMwî³TjK%
\µs‹`sïœ-Y<9|ä‘÷à‚z‚£»BÐÆ!\JNš‘©€dbÑºÊª Ñ\Ñ•Œ’‡0ÁÓ]U×DT¿«„àzÎ‰•Æ»H©Q¡•$Æ#ÓCÊë ‡IÎòÈw	T™dÃÅèÇª,Ø4 ô\/dþ"Q5¤[F™Õém^*c©U´hu¬h6`¥k‰L²$óÜM®TÀOÝž\š¥^>=KÔÊ ÒæB$²ôcõ“^,&¿Á)°híìÑ[ÔŸî|»óT»>õ(R³(W¯DqÓkQÌ¨ˆHób+ßö‹«Ï‹¼ œ¦¾—Ý®”C²(4ÛMýŠ}MäÑÂæZTPú]¬D@‹³:šôƒTÿf[žw!p{êÂ·Ò(ñhùÔKA¿2Ïzé ›©+f¯«rZ£Ê/>RißÙ÷IVŸ˜¶0#ZM²J¨ä| °¬ê0.^S9W²®Jvs'~Re]à7ëºžT[WûE”:…(N7wHI•›£qÖ'Õfl`Î/è¤HŸ¶¢]á ±x1xwïÑÎ/€Þxw±ÒÏ½s›•0]Mšâ‹¡™<ûh>óTJ9,³ V„Š¿–ƒT†Ä©sVüÈ…n5\ISàê@¿™áNÙxy†ýW5eÌ²ÕcVp§YAžgÌ 0Llk!MKûX8CøLûƒ,l«ˆ+•Wö1	ä•ûÈâóöWbø¼ý•p’ Dõ‡æÔ±Â˜a+bêjV…3mUeIŒyVuù®GŸXî±í|Ôï-/ˆ“»}²áÇ"ú¾rÊïÁºhÏòQ|‰
þÝQ†×í²…HÓk¯OQÅ$ç—»
 ¦ õãËf$!©bi¢F69$!dôÍ<í§­Å{Êlu»äÚ*GÞN4ßE2¬€æ,¿E[EÛûOŸ?ÛSÁ~ÒYRG˜ÈDã‚ë¨S*H§9¢¨vÍVÓƒ:iúJ<P>*èZƒk8o’~_{ªŽLîUxd“á(îu­9íi`²Y³&ËÙÒoô Ž£	 ÉôQ fT_«¹³6ôn¶50q˜czÌ-j•úÑêÏÒQ-â,]Ä´œ.¶]Ov´°²åbÒQTûZ¬¢ÄÍH._ôÿþö¿cJ×1ý"Ñ‹~îÊâ5¡Øƒ©v1>| ƒù°@¬j!‹ßåC@¾g!~Íb7ö$årŠyj<Y‚º S}Or€Ñ{]àGåéi­:‰j9ˆðÐÄARH#§¦t„¥‰kºSME"ZÄÈ»=Œj~M6UÌ)ÔTâl)ÿ
5D¿iQ½B[½jú–¤ÐI6ƒ½GtŸfãéLëÒÔ³Ö¼W-çÓfUØR£¿l¨ÿf32Râ„P0à($ç,\­5a‡òI7îzª.Áåð`{“2NÛcZ¼½¢$„ÿy‘BHz<o?àX‰Òó´×½~…R–e@Ïëˆ¬†•[
lwx÷aröÌE90õ}'@ˆ7QüÂ±R
„
9vè‡,}×¨Í9LOà³(KGxìö–„Âë3¼²X§BÐº?ƒÍ|5Ê›8ä,BŽxEÎå"éZç¦ÔùôòæE5Íkö*SÍ8ü>í˜‰{¨V™×[­NÃª2¾h¿Mâ6_Y9‰ÛŸ÷H¼Š^žíiÎKÏÞàÒ3“€ƒ'¸Vpüœú˜w˜îìÕ˜•î¼Þ+ »9Ý1qbõTÇ>þîÑÜ­³
¹±ùÍMl¶¼ç‘šÑ‹Î65zŸ¾Lßw™¾ØÌL]vßÐÖ'K³¢O‰Ìw„T›?w¬¿s&."§÷rxËºì$×&Q½5õ“KŠ‚Yÿ×@¶­/……;{Æ¬Úâ½c'to—
Á:ç³Ö~_,çD>Pö¶±sû§¢Œ–b6min÷Ô‚µ³Qg5¹>Ý¤¤Šz,ª &¥ÀÀ)Ë0O¡ád1p#>…ñè¹©"Êõa:F.šâ_Å@ÅcÉLñŽ°¡ù©x5L.Ðg8nT)Yy«ëÞêº·º®–n5Ç[Íñý×o5±[Mì}ÑÄ–/3~ÖfVÉð%"RÑjÄÄÏ6£ýùˆžÖÊŒ)¨žÜa÷äåfF°·º]Àf¯[“5“Â¦ÏÑŒ.{	&“Âè~,Ô¹pCw\ËõÓ0žÚ…×ìr(Å9#î•ÞÒ›ä¡Ôÿ  ÿÿì}ko#IràwþŠ2°’³%¶ÔÓ³öH«ÁiZìiaº¥¶¤žñâî@”È’ÄmŠÅe‘ê‘aÎ>ïÚ˜¯÷îÖ6üÀžm¸_"}½_rù®¬ª¬âCÝ3l`¦›U•‘™‘‘‘ñÊ™ú¡ÈmÏÙ#Ñî¸ŠGtWÖ>OºóþšêµÞÌGQÐgDsãuœÒ^Ô€¡Ÿ“ñè.HÆqÀŸ‰'"ð•±šhE—Ê!7š"Kî¼væªnåYÎð1µo6÷ô¾J[ñÊìŽ–Ü]þÉIñ3Eã±ªcþáaD†ÄÈ¿›Ã1,ò”@åQxÉ³Eª&¼5ü¢Û»Ô¼½'né²±LsnõQn>þýZŒ¬è5èmìÜÔC¦ÿÇ*WpõÐNYã×ªÊ…EmC6÷#yÈt>.¸†¬R8ÒÓ·ÃHäS+OU££NÖkD›ÏÖ~ûÒà®Eí6Ÿû;YW¹Ã3ñ»Ã“íäÑïñ<[Ï=†¡âkj
¯ZHTû*¾[1—Ú•0·Á ‰k5B&:±e)#ïÿjék)³ÔWlÝ¡<†‡1åë2Ùr8ù¹HšÒõsÌÉ®4wÐÖéèuO†ŒBBR6»=uÖ¸É-ÉãÞyÔ„E#™ªóH{€ZÜž¡‘ÑTN>T*#£I¢XŒÄ—\«£•ãnôŠ8ò™€fj¦ª25lå¿‹äÁÍ“C?ä}Öë4KfÖ«J;¥w\K…Xiˆ!T)÷3ñ"¾vTF(2ñ¼…Y|ƒG‰™ˆ2µh´?ðYæ4?I”5BÜ=k¢ˆlr3g‹qì¸B×M«›Ø‚gtÇ"²ÏšoN·šPp–ô˜8m‘4Åþ¼~}x¸õòåÓg¯ÎÎšmì‹­õº¤Äc¸S;™?Ã$±µŠ†óiÇÊäâCU~Y¦³¹¡ÊcR7XŸ¡æ“‹¼=ÄÀá§z]#/¬™õ€då¡Nyì­ ;Ù¯NNÞà‡CÏ£QŸéÕ3Øj¿™CeMµ˜˜†—Ï¿—{K)Éï>•(ìhÏZ;ÁÏÕ;×“`g{›Ö	Çñu<ÃŸRXU³îð¸ÓõÒŸ‹rRœ!dPnâQÛ›r„&ùÐ6…e¦´ßX¢’£äSU9FŽëô¨9ÒÙ•¡:‚Ö‹£'T´äM÷”Q§œÀ ÷ÜíZ\Ì›L(—.ÔÏÐ:[Š6àSä¾àÀÍ®Hœ‚X£™ž¤þdÆ¨Ë¬D“-é«ÔëPeÀ	õ4Q4iÉ-EPZB‹‰!l)¤º×>T5OÛ‚Âæì‰'Ë6ÙÍ6h%óÙd>k»-ÛùÏ¤á¥Bè´²q52•\¥þ	^ÄV”ÖöÜýôl+§^@¶!HY2È»•çùñBm¬å­òA­Y+M§M™t)Šn6›«Sç~	7KÂqSQE3´~YÇ»½ðú’pÚŸX6Q.ñy-m®-+©÷q7–fð
5ƒUhX§B²*…š)»@$Ô]1Ý>g,PÈíOâ/.×‡Z}D‰j^ØÐÔ* Q‡»ŠõõéÝFŒÑ2ú&%î9TŒ˜b•€dCÐÛ(¸MAZ³Qî×‰ðò,il~µOCÎSÕ*i_š‚¥ÊŸºr¤fr§L5„éº¼"äÙOÅ$\Ïz“¾TœØø–æÃ¶Ji~wtþ’6ÔôpÖæsHÚBFÈÓ¡ÖHò(WG2qÁÜ5ýæJLm/ŽÐn×2sÜQ|š|Ö’½QÕBYÇ“í~¥ì­QºÏ”ÞË9°†¼¨^ @abJÐUT9‹¦í¥Rèe]z_GSÕ0haæ¦ö˜wWì„ hÍ:®5g‚øÁWgì¥¹JmU¼Ñ¦–ßd
›r¼‰„V (‡‚áZ,.˜§hH¹ŒZŠÏ	™šÍö³HPnX,ÞÎ°µ*VãþV×¥_}Ó%mú“f[ìmR)ŽÂ¾ÁO°U™ìLœ
Þ«D²†œóqeØ ¾ñö(Ä±-x|Ø’SleV¬ÒªÕX¹ÅV¯ê
V^Eµ’µWS¶~R}µ>E›G<PH´ÆLs
Ò¾ü­LxûãÇÊdˆò‹&ÑñUpS#Ç`O÷5„¨
•\
É“8‹«i®!Nì‹Øëâ˜êâéZ‚Ã¾Ø¾ƒ>ƒçØ'/¥ñà€T¸äì¡BYôFˆ=!ÿ©JÁ§¶Ë•¶žúþŽiL¶ ·üaˆj½ŸÆ“d:[~XMR/h’äÝ|Ò^kà¤KHäÖ±²j]Ùå¬VXOÃ,6„ìÌI0åÃº<ë¯Õ|ø›ûß?üõÃÿ~Ë-°vœFïƒ×üì¢¥¤ÓÅøöáw÷ÿpÿðù‹áx˜^Çƒàë$¤9îÿ6ø=5Ñ¼*æçöáo~ Ýý¿³ÿ~ÿO?Üÿ=4ë‚å‚wèk€Ç€ÿ%¼:Œ ’{ÕÀH¹ã¯Ž+Æi·ƒÃÀßË£ã¯WðF´¾2¯k)}Ç9ç«’¸t¶œ°3U¡µÂÀ3“zE¾xz®2º[Û°aÏþðP1­1…Ó´fØ¼äDÜ»bDŒAèÊâ×Œ9Ý…Í ³¶«þKnîû¢Â/z8ëÏ/JWF¨ƒÔë:iKê]ÔI‡eGûùÅûIóp¶UA˜šgôÅZ}Ý=î²³¼{¼úîàWghvÑ<s²×vpv~rÚ=¤þ<~NþLÚŽô,cƒ¨øf2JîbLš½øQ¬"óä;,2?0ROá”KïîÜj¢{¼ZQû’–åÀDŸ‚Hßƒ'°˜l˜nX7àpáC“URa„<±ÃÐ›0ì! ö©ÎJ \1†F¿~a…F“ÆO(’0#´T«~`.±ìáû¾3ô0#aW8dp3Å®s€:k]ÛàÜÎ]ÔRaŒyyÍ]`"aæ–ÍÄ1¯‹CMH(zäÁQÒI9 L4¤	*? Òƒáay@ã.$D»’ÉiàÊ‚*³ÊïZkÙî[/šwt‰Åú;$qÆæEM*áÊxÌèL$ëª[˜ý,GÍ~¨É˜9_d‚;ßèBSæ“•oÊˆMã†ª¶
ò–ê‚ZƒÇ-VÕ«¸Ãªž,ÈHjj…ÆÜÀEwØBV¥H#@Á"ùP›-™¯³±ˆ6†šFSÕCÀ
ŠÀÏ52ÓCB.€»BœA™¹è+%¢X®õì9éqCÚ&åÖÎVðfÆìÌ›½Jmñ)pw8%Wî5]îÕbÂ5k4‰AE—ŠN­ÍÀà5°’ ©tGãÓ
5\¶­Ð‘5Ä‹vØµžLFÏ-í1Îþ•°RŠ£ÄÒûŠë—“(@çÍÎ&Bäƒæ²è§""–¾Òy&?2âÔÅÌîþ¼Š¥ì“ºù£Ð/“ùx Ñ¤+Îœ¬ÃE¶?Ò3íúöÅƒÞEîëV>Æ2¿?;$ÚÆ B«S×™!ÖYÁÌˆ`ÿ”A¥8PFÃœ±oðÝž°/b¸œÙ‚‚ÕY.[ÊaL|¨YÎ¤cÕÅ›Tš‰’6ÅÀ¾â>ïjˆ•&™0kmÙwlÅüKãÐG´4½ÂeàÓ*^MBT3t`¯ÝÖ÷Æê¼Í2TÐð¹­;èOïÜ¥•xÝ¬‚¨~U³X6ié!ÉÁI÷”-qÐül›}y—6yûYâhmÄ3»BMYK3Ùf´$:ø]šRöÚi1¬Ï89†‡WÃñl…1‚ZØû>Eü±ïÍÉ¿;¶(	A,ïõ˜>ˆï2fk|§¦«}‰$Åä°Óî¼õi{w—fßh¸hGé{ˆ¸ÓCó2v»÷}0°9"'‘“Ñ„å†à5ìeQ¾°OGþZ³2¹¯SiÎG¿ZŠ®Qëk8”ôã+škÂ¾89=ìžÂŒvÏž¯Œ£¬±†Wfe½a™$S9ØÅ¯yAÐ‰Ãc³hq.òô\ÿÒþ­Sú&`BÆ^,°ÆàêóQàÿ'®æ‹m#Á$ž·Éj¦¬#Äæ‹íÝ@TÇáÝ¼{‘MI>ç	<e)Æ®´ô˜¿™ÇóNïåÇÇœ™#¹r»Ê•ÀŒYÀé&ŽêMâ34‰áÛ°y5ŽÀ$–F£m^S(:ÿˆS&BÏËé]<E	¹´ìA+v$žEi:¼ÇX¸”4£;5-Áìÿ	õþ$žõÛº[®$û­è!“ø–¿XºÝú)—Bc8’xGk•íÎs
êX}r@èIÚ]+™‡¥•w¢§
d?ýsŠAî«Æ9šÕ#æó£ÅåÃ«šÐO5“3\aZõÏ4UÉàÁk×•ŒÞ[Úwø.¿'•Ùoô@Kð€j„ƒŠ‡<ÅÃƒßŽr…ðøj§3®ïh­UÂ+hÃ
Îâ›”(µ§Q4IÙ‡iÜOÆƒT@\
•€vÁ>6©8éèhÏt¬‰gbÇòŸ&ÂÄS_â]Bä?ªŠ/×ÐæŠ®®ZŽm&M5Â}„·€`Óuô»`aïN†SñÃn’ÁðrÈX}cåoeT¿®Ùqäá²&Cþ®Û‰ °`‚‡"it²òWðFÄâØIÇû¸DÒÕüÏÿµ¹»‹ÓÇ'¨—bÏôE÷ÏÎOžŸ·ºoNž¿¤ARò‹`Ë@4Ü5¹Ak5i°á˜›šäÁI©ºi“?”ˆ\ÕÄkËï[Š70aÃ’w‘ô¥Ÿm]mÔçÄ&²:}ñÙcT«ÈÈK¸D`re¥ª=’š³c«9i/¸Fv9ü~-ÚÎNFÛIéŒ`ºl#ýãÚ0+¤ËWkr†Òbý¢>;b®£é Ÿ˜ìNšÜ‚žM™l7[ïÍ {åìàéjQÓ0#Þ°ð^@4Í|bÝÈ¼Óî”^HÙ“P—Ÿüv;ÿ€¯V™Á#èkÏ¡¸æÕ|ŠkÿÎ&	 ÂoÏ„RŽÚ™C
Î®`9ˆ”WBmÚÆµÒðäÁ«¸ÿß?ÜÿëÃø°ùZ¾Þæ·	¸n!<üöþßþ–5ùýý?ÀÓæ×òýoÁµÙÅ¿²ÿþƒ€Í3ùò)ÿ\(+Z÷xøÛû¿ã]4åŸ‰&B­á=ük¦éP¾Æ[ú£Íâá¯ðo>íòõçÖM	@ïŠoJœ¾:ÃOÈƒ0YtÅ–4¾§w³bWlÉ•œè»Ô€iClTÁdp3q¢9@Ýq¢9&ØÌTý¬°¡ˆg¯iéš ”Ú±œ»ìüSA.¥9û\Û¸Ö6®µk­¥“¡¦šä»Ü”R³ñ¹iL€t(`H¶V³ÜŠ<›Ñ(ØÈðJ‚ö\#†‹òr	6ÅE²yË™t4ƒO"n¹5ÕÚ™T´-£Ã°=ÜKŽ©ÜLŒ¹Ç9ÜÉxa“ñêó§zº# R±!]GkÑÏŸîj×Äž°Ál‰ÁÆ`KLIYFÕÚoÍ˜n×ÒÆ)-'É?Ü•yÊ^&S°Û^Çœ‚ëx•>âï' ¥/á­9Þ²
Ì€Á½ãS?ª41§ûRAÑÍ÷¥ˆ¢k";âÒÄ	@§¾6*ùç0å‚æVÚO&LÔ5oŠ!¡[?ž ²™J Ì•Å³¸FÚƒ‹ù÷£q2Æìp•/!b2Jˆ¡i’ÒJÓhš˜\˜gªé(Ñˆ/.Ë4†¦½Ëáe"Ò+:SPé1îü•¬O¿àóD˜.ôÙ)û;(µüS^nÂ§QP3c,«›FÀmÆ’O™ÌÄö!(&Úª+FÂ‘¶Çþ=Š¯p¡g‰FáuàJF#´š¬ž“~Ö›\Giü´—2âº‰~¶°Cøj¼O©Ôn)…'4ufo²·0øŒ]Ü¦û¼ÜYÀ:PìÃÙÆC5˜’‰›–aÛƒðb¦›lùR¶üMþû9ÿý
sÛ3²ýÐsÛ¯*Wý¢¹çí½±®üóN~™ÙáëäƒoÈ|*3nób5óÄ»óÂoçƒ7’f÷´lÇÙÚƒVêø}Bx2®2)ü&ñû£$~ß$u_SR÷M4ßO/šVÉˆ Û÷m‚û>¦à¾-7ïV÷bçì$Ú	 óU¥ÉhOÖb‡z%ØY·EÆtž+
K_Éó‘*{'7ÃÃ €ý&Ž'në­e¦¢sqOo¹•}V ìÇp	&ÀÆæôÑØœà±Â¢‰¸Eju)Ž=-‚ŒŽµhØ"Ýg#“Aí•ïÃµºâè(Êø!¸…–[<Ï× X8}lÁÛš¥¾	KyÅÒæCRøñå©2¯ˆ2âõÞ6ç´—Ëêð—_æ Ö¡ƒ$&*½ˆG	cž3O™_ËTe$üYscÖÜ˜5ƒYscÖÜ˜57fÍYsMfÍ5ZV®Ð?Ý~ú‹í?Ùùcv
³?üã?Q®@aåUWà9›C0ÎÞ€®Õu@]ÃW_Ê÷ N™Dz…a!UƒN.ˆ€}s“l!À4Ž!9Ÿ—&®¡ â~ Ô’Ò’µ21q`]¢w´€Ë»œ¶T“Mêñú¤:7Úªª`i/\‹».¼`¼3ZtÞ‡Òõl7]2ñ
RzÆÓi±¦Í³·Lêé¾>:î¿úŒ¥0žQ‘Ú±(Mbªm*Ú}‘Ñ}Å¶èó—=6†fŽ4G‡\[®™ZÂv]4Jôä¸n“µÜJSeæxš„ý¾¥§B"07’
.˜>…J1pVzl—uYw¼}¦È'Œ1r½ƒý)à¤Ñ(.4|Q{Ì^ÃÒú«‹"a‡s§w=LÑÀB ´<Üù—VÿšcWýßL’±¶FËëØ§ß[Ë¬ÔQ*Äïz«£àPùõš`Øªößõ´Ðï…Ç³ µ¡ñÈ¬6#Qw¦JpÞÌYOZÆóxTÕ!þš©±c&@’Ž1ŽåXe…–®‹b/ :ŠØá>=P$>dòsÂsÀéÜU{ZÈb3Pê3Üj | ­lõe^ÈY%þ«‡VéÊ_/g=MbæR‡x€ºó>Â"¿ƒ®E¯ê¸ÝHÙÕ$1m#‰J„LæLMŠR37»ûh¢/áÊw?NfÆ¬ä³ÂÃÑ‚Pÿ”¬h\MŽGG‰zèƒ“…q±0~|‡Öôò7&‘Âï¢Y°j»¬­9ÿ£³ÌÅŸyî,üz;«ÎG”'Ü‡•( ¥jZHJ0©ßä8±ù>*¤î(¬K0åÍ‹Z»<QK µ¨ædzH=‰'ê£Îƒr.¢ñ;Œ=#ª.@B´Ê¸?=Ø‚1Ô^Çª°jIÇæ›Â¹éŸ–(‚EÓª ¦ ÊŠNÌÁ™´¸R/aqr©‡7gd:™0’«­k_G‚ëÒk8(ôƒíŒÅwŒåÝ:¨u•z\|:#üÚrik}.˜\:—ÁpÌPß£k. ‡YøŽN6•PùÄt/-1^=,B|HíU¨jcô«Ü^Ñ†/5AÆ‰±-‰ï¼ÏÃÑÈ iEÂxùÒB¡ëJ¢ª…ìÑ´Ì!™ræ‚À”ñsQ$Iá¢€è$X
çÁ‹b‡»í£±Ü!Éí&áø¸11Qh“„bðlsq /âƒ<¡ÂÚ<:þöàÕÑaï¬‹>î¦Œwè^£Ö¸¤ã”ðò’Wòâ^hÈ"£<‘Eœ0îpzæïËµ&@<ª÷âàèU÷	@r¤fxö§¯º§§¯e®é,÷ºv¦-#„@ÊÈŒwßòæ¶7?°½ùåÍß§Î§/¿a/
ûÚÝW(àÑM!ç*
EþX>`zŒü7ÆíÊª"é…Ê¬`1Ž)PfZñK0õ-ìwõ:J¯…8)
±W=ÀÀt¿ì ‹TV‘`z=ë¬8Áâ0H¹‚äÙ²e.%½‰ùë¢º	Å°az¾P»õêèõC³KA’UÝâv(GàÙ©$ÈÊ²…º•Û­²k»…0îýæÃoþöþ÷ÿÜÿÃý?Þÿáá‡û¿{ø¡©÷‹wd_z¿+¬OößÂ;Š"Õòä:Ç¡:†ä•‘£ÝDÔ]+g<ŒÙ†Î8pö{›¢Âà°}™Nhuÿû‡ßAºcÔýß7Û|£@&Ü,6uúÏ ™˜Žnòm+’d0‡M k"E¶I3Ð]Ö2ázB^Ã}v(½>Ù:=ønk{{ÇXF>è#s£4L;¥Ú¸¤"þQ&G…ó
õPŽ×–XãSb™a†lÕÙBýËýß÷ÿÌVí·öŠ…„Æ¨ã÷@ø]3ÜÙ?§%7Ø¡kÙ|öüf«EÄÛqàŠÎdxgt{E–xÓÄNêdTË¼³Ýö
×.bDTËQ©@d-þ½``jE¾:8þ²ÉGÚL˜´¨)	joÇ—¢+Aå@‘Š{Ò?Ií»Ø•Š+ÙW½:¨ŸßŠñÛ ÔwK+°®ð…[án³3Vâ<©É™g¤üï	DoQûgbêƒÊÜŒÆ^Ddš¹¾%õ¡MfrnÖå’°qH$µn—QŠq””“½a¢„IA²²{Îâñm2ì‹œ œ¾y{šÇNew~$%Ò2;
µÀÈŒò‹ù½Oç(½†ôÿI4d¢Âæ"à.ØÞM<»NØ—o±ÆœBµ uÊCRˆÿš ^3Ž­…³×8l
Ôt·4Gp¨mH“ß©ó	9áÝÛPÅZeéVû’CÕe'Js2dmðp¡i—‘tmºÅ¨Ž	Ó@bÒK
ÄWÃí¹÷ êN•¢;òiÿìàU7ø±?ÂÇØDŸCèZ[ÔÆ·‚`ì'¥›•wÅŒàý=}‡ksÈI»¶„žØò/ˆý·kÃÌ¢wqô>ºV_GTe˜(Ø9*v¨Å£†|vR!!SÛ  @ßroXÓ¬³Cò™8éûÕâq(I‡–ó…0“Íóè—ºñ#`^ÍÓH*£HC£-Nm9D¬SžEÁ.Bƒ-Ë¤ ª²”¹“%Æûÿxøëû¿3•+7‘á”
¨LÊjÉÔ;µé!,NhÊŒâ¶¢øøqÚŸñz&èÈ÷ÿåvþÒF\ž,úiI%Ir6¥VÔbX¼5Ý_¥Û`êŽš®*‹a	Öño÷ÿ÷á‡‡¿&…Ê9äðóíÐ²OwÒïJs$N[ùö+7âËÝŸd“€Éî7É ýe¢Ü¦.Î‡½´Ôô´ÇqF8E#“ÛãúežQ’"ã.˜“SÃ€ö
‡«ù¢[Âš1¯¡û\sÐïQ©m|ü¸ÈbåŒM“5féæÓÅ\õ"F€âv£4g¸‹¶¡àèÕÑ7Ý ùÉÃïþêþ_>i‚U\4ï`4Ÿ4Û†Q\ÿhÌX[ŒÑû6Ò4\;LÂ1YÄ¸ãÈ‘•ÙÑ2Ð¨Zt¥ý“È„ÿ@f+èý"±vqëø’¢
ÖûçûÿÃxÉï€Òá§ÅY¹)^Œ{ÏÉ¢«¸tâl9ÃÁC'“šv–îÌ9ëv«¹rN»ßž0…j]Ž{¶ùÞ8¼žI—j‘âÞ¼ýêÕÑó=xÒ-D©¶ ¥÷½ÆU#Xþø\7‡×rqø‹í/¶?ûü½ˆ	EÃ>ÝÛFXæÏ_Ùµáì¯¯o%ãÑ*z*o§AU#eÝe
P@9!âA€M.îÃO¿Ç¿²R$¥Ujq ÈŽkâ0ÝŒ…©»¬“žq#S€ÃþFËmeåñ
Šo*—ú6Kn*£»Oð¹ûQ]KS>I;“YkçYøŒ§éÇïŒÔ^h…5žŒÙ6p5éÝõ<ºe,ë¸¸e2µvþ„½Õò‘+‚Â8HåUÜ“]¾ÀÙ¤ab=µT…<7åtAlÒøjvÝâ_µ3Í–Ï5häãAÉ7 ¦BÐ†).I§æcC`iä'äÒçg¸hR¥9âEnÍŸ­„W³Ò"·Þè ³¶ýí/¿4vO5Üä]}töñ6
D•Úîë7îRµW=¶N“ŽÚçHŒFJ“L¡Z-	Šg"l ¥SÏDv.=¡¬DS²i`¡Ð× žB› 8?eL	«\9G©å°Â]zt,VüSZV.Ù	†WN$e6ŒTPÚ¶f;¢E·¾ü²©^4Û»»bË›^Ï‚¦µ”©VY;™.CQÄËIFW—D˜ÌŸ¾e'0c{Z~hLÓÒŽÅ 2)s’ª¬®ü+~	§ÃSViøD§K^ÒTþÖ‘ÐÈX%oNOß>?Ç¨…£ãí–Êx!CF~tlbe2uTšöCÏ&S¡)Ã<•›„ƒÊ»	=¦ •¨§F³²22¸°tÂ°–¹>ì¹¶4æJñ/))-ƒ”³dögÎµ“[ËRg¹%1¨!Jb)48ˆÈA,rïÐº¨5Ð ý	Á»5³½ákiòçð²Å:V.¦Â{’
ÎMþ¶Ÿ3ÅŽñÕÏ!‹à«·‡ÝCã¹"=Jäe%õ2ÈÐbu9|\*ÃŽüw€d]PîRb8•8.¥¸Ñ°©ÕS¬¡èM¥à3×©¡(¨˜Ê°Æ§.V:“br~ªä¢_Šþ´{±IÞ¾¢Þh,÷ìí‹GÏÀ$ööøè¼wv~òü›¦ö-Ÿq3´P }"©¾Ñ‡­}('ˆ_šëÂÓÀÙÏUQ—Zw÷]CÞÓØ&‰»6ß4ré¹Ð¬¤`(Î“æ|¨ÎƒîŒ/õ¤i‚8B´Îž‡ X²¿ÅÔŠ4†¢qMvŸ“¹‚cú—\|'ä£jÀÿª{pvÞ¢OdN5ÅÌD³Zh!¥Éùì«nñ^\s4S¯r3VHž§¶[…n½Èæþ9ôlÍRÁ0âcÌdo¸¿ì½¥‹½mÕ29¦A9Bù·©,‡Å8ÔC`ÍiÉá8›d¤ö0þK¬±Fg%¹E‘Ì¢öÔ(Ã¨`L’)=áÒ?ÿâ/
8r)'mÊC¿éŒ€.šÑ@|¤•Ip°·G£5¥’3ÅVqr8†šËqÁ_¡uyÚ0}ª–ÆÎHï]sƒ
eæÚG=±YÁ›ÎBF=&ä¼EË’´™ÒhÔ·šØ§ô”„Ü\ ç'¬f­ßÏãåAübçéögÛÛ=ª±Ì|X%šÂìš=¼º¶¦²2ëæ)Œ xsrÆ-’¼{dàzýÛq:‹£A\Šð¼ sk-¡<-{°õ% 	,¢P¹@ÙOUÚ°=È¬YO§ñM4›öR4¼v&Ýÿl˜ö¿tÚ×Òê'£ök¿·Ê<
­ðª9Î5âËÖ¤“€!¼}Ó~#²¬*Ò¤à]!ÃJ'Q?Æ@“chènò]CÂãÎ8PŒ6m³!Ùb¿©“ö9RÆMyïhz5çù>Sš{fXy²Æ`§)˜=Ô3NÉÔ“F¬ŽzÌ#T¢ÑIo0LÉkENNç+e{bOgÑ÷Žo/’ñ<u<Ïô§
™ußªìL/›d½á­¸5,&¨â@´á^Œâì7ÚG-¦¦Š–d”jø
3ùêufl…ã™*ð¡J4÷tó=;¤ýLHˆµGNï™m(òŒ.‰üàøW­[ƒÔR-U¥(«éõmmšâgë|A})´Ô=%ÔæiwrJbQØBìIÞÄfOFŒ´ðAHÆÀñ$ÿÙõƒ@\»ø§F7¾5ªx›ã¦ÌäVvsG)K‚¥È0.¼Za}špÚV2gzLgÜËF
¶T|]Åš-ÕXhjò¥iEuTlÈ.Û®<q>	@NÙßP4Ï’OmM´å5£/bK#³-1°Ì

(ýä*å|¥`í÷Ï›2Gƒ&âÙFeIp(Áj_ä¬v±cþè‹¬=4Ôù\ß9hkç6ð¶®™Ð ™´`Ú0pY;’Íþ"IFq4æ{³-¼.ç§o»%D/›îb±=5?u+åUùD2‚ùøÝ8y?n®e/|6>’ í}!×â(c7@ÀY¯$ú$ÑøýthË¢ä1°*ñóÅp†NÒ¡BtýF—L"´f1Ï¯£Yp#«rE£)“Lï>ƒ40Ñ$€ò/–8ù»‰b‘wè|_Eý»¬tÜ²°«'ÊéÏ1LµA!'8€bâlgSü–ÑÅ%hðÁ“o™ ËzbBÙuÄ†P9;1îRéÖW‚%kë*¥X”4óäX|¹‘d¤’lž(Ûpòq.ÁRb™jOX·+·šùg`“†`‡.
Ó¼B*Üƒ-·pDy2˜>ž/Ç“Ëa$[áº/]5V80·Ì¾„a)Æç5®G9»žA5‰x|™ÀµH#Iu=ÃA®ììêR·xz€L§0Çøúlõg»AÌ;ÆéG¤ä$c¡:QIr– 4v¦1i)¹6vWÎìC_HÏÄÁg¹æ“’˜³€›X6g›À³*gb"æQ±	HÛ¤mÒ6i?Õ€4i}{|ÞúTÚ[£Ä¯<ãÊêG•ùÇ”yE”åÄ“é>ÚQàM¡še²< G¬ÏËƒ3¶FÒs¦GóäÛuÕ7ÒZÔìÈg×›a¹XÖiš–±M`â&0q˜¸	LÜ&n7‰›ÀDÜ_›ÀÄM`â&0q˜øÁ&>Ý~FîàI4œöÜ¦{)cú7Qo0^ÎV™ˆCP>Ö]0˜³1Á½“1ÃÎH+h¿…VòÓ7Ï¹ï¼4³8 Ñ4Z€ì,3Lùñ!J?ƒxÄä7B]PçÉ^–òœÝ­¼f·MÅ…–sÓÈ.­ß¼cð³Ê/Zmj‚ùQ\Ær™@-ZNÚ´‘ÅÍ5‹qÖ­¡yfGÝ>½Ñmò™@3¡ëŽL>hÃVå´TY
²¦”piN¬pÊ~¹¯}bœV$¶UÜv3î-Pð'Â[:@·ù¡©Õ±w¸	ó,†™žßÈ•R‚šA.bîl¼Íø!íõeKx{ŒðÉMo.ÍàÖ²€cáÍéáVNíYÒƒl4­qòžjÐüûóúõááÖË—OŸ½>:;ãQr¤ˆ¤Ÿfþ—ù´c'»Ä‡ºEeÚ±Ò^–©¤"])kš±Â™Ù|§7Àþ§7d@qŒF§ öV©råLýˆS;„„™öSG{ÖÚaÒ”|aM1xìlo·M›¤žØW¦¥­”A‰1O{È^­ÙJ!­LäÓ4d@>.û! +s9?Vs’üJñÓ=¶Pb·PâbZ#G#qž ¢ïL—Z7†€Í¿w*³ñ÷“!£DLhiå1H[³ÈŸ¹êÊv˜³"¸´©mxr$O¨ZƒÍrÝríÎÄf¹j—†ŸÚà §æäV,QÅ\ˆ›XQ¶Põ‚bmÿŠ(s#<Ñ?ÁòÛ€1GKåÖé­ {£Ð¼N„Þš±e{©‰ÛUáQ£Úfhý²èÖ^à
hWpê¥]ºúy2»@SÂàÙ”Aa ³Dâ/Ê(h,äg&Xw5ô•¦–ðÃ›ÿÅEMË€ÐÖ5]kPB‰å­T¯Ê‘ªI’nS]Åz|­ê)7èÝ°sw8‹Ç«=Œ‹Vš¹ê5t·Eýª?xõœ-e4¾{rN/S0¡DÉ­,ŠÓNÐý~˜B	JK/:}u¦ÅƒÍ˜P
 ¡Zå( ¾¶" $Þ’é1M#dÉ£ïÀò¼uq·…ÿPš”3Ú@d(½ŠÆÃ?ÔîrHµ&#„Ë¸C OÓÑüŠž¾=>úÓ·]x¦dvÂ®‚3DÂ£™hgÃ¦ŸFì@üóì÷´3Xƒùdàß ÑÞ«ŠœÞMl«&ŽH¢µÛi÷þŽŸwÝËÒ7Û¦¼ÞcÞÏ¡Ìâ£iòÁð©]'½i2²SN¬™¼CY‘/$‘KÐ²PŠÉâGÏOŽÏÎ™ªÅšk‘pLý‰ûïè¼{Ù}þMÐ²ç	åÅ¬‚&FÁ?˜n]Ñ3jÑlÅ¼:ïžr‚±J±nÙ¸^½}}lQ“sñk­¹¢Ú£ãÃîŸYýß÷Äxzv§ŠÍË*I6ŠÙK ;qÍjÐÝ{f9=a½­²®™ì!«þ*ê¿»ŽFAw	’Ð¢± ŒOy4ilòe~aˆÜ·dFw 5Ç[³dBÒDµ“5Ž Å#XÒÀÖp³ã=fû ISqfÜÓ!rhgÎhƒ#ãÙ‹Nsà¨í†¤ëhîJ©ZÀŽ:zÑº`bêMëcÚxŽýïDŸ4Z Æî.žáT“uOöqÅF}Å€l5\ÃYuë¢Áó¿vlâãŠÃƒÏ÷lá_Í–Ëôˆi`Á.fƒÜÇá—õHD`¸ò…„“\¢ý“>i¦F‡¥•Ké’m…6—Õ–Òn#cn,²”Ùç÷Òj°‰œÛü%Ií‚•ðÞÈFZÎºFá¶ÛÙ_´è“B´‹@Bc±s¹¹Ikî‡î1¾;=ù.xÕý¶ûJï•µ•KT ¢áŽÁ›6æ_Sr0ð´—Æ£¸?ËáC©älJ•¶ÜÇéÂ«ál<ƒDÂ\2b_ñkë0èÄJrcx‘“›ÌÚî›séXwÖBˆ#ûY§üFŠdÈàú‹Þ™\Okâ½¸-Ç;ßã¼wtþR&Þ}Oâi½Á·mè!?R¢ñÜ|(ÍZÊJ¼7åÁ®G¿Åm9ýrA7Ÿ~ëì;)9ò]ñUÑ,ªAòeä®…ê[h®…¼®Ò\½ Ubž+™p!¬4a/H¾×s®ëÀPá¬„!/Hõ·4Ù(iß„œ¦BŽêP Ìa$¹ùk“ÝaÝ,PÀU´ÚRL£9ya…`H Š¯•#äeuÙJ¬†ŒÑtžáiçvdÏÙ3õ·G&J­IÆ4aVëæ¥åâÅqÈ»Žù
½lÁÏùÌ!Ÿ™§lAÇqá!˜˜çÏÛÕV@ªktg·Ò*¬Š@/:ªÔ}Í¬b™‡O‰IorkûºCröpÂ…#Ì« âµh‘sk‹Àå¾.Î`èÚL™ož'“­Q|Ä“>98Ðlöfß@‘Ò³(:ë4÷¼ÀJ¾
ÐßrCÌ(_}f–‘ÕÀ]£;	*f÷¸'i_ÓÙtµ¾¤sÝ³£÷¸ËMç)Þhÿyp9œBðY²~ ÈPù0OzÅÏQ?»{§À9Œ4o‘²Íàí‡à¤i¿'Qš¾O¦í‘•ª2±q¼<Ï{Sðoå¼îÏ§à%¿3ß7»_¿ijwî[êEÞ1b6CîÌˆAz–	.ÔnyO*é÷Õ(¹ˆFõDÞÏý<|Ú¶_2¤‚‹o NKã½ù—ê7ê¥sNñ‰¡ìî£ä}<åFd¾Ø<f¯ôÐwûA‹‘‰ßôß‚æÊ<ù/æ¢×ªÅUÚîëƒ£Wæ¥j‰'ÉO»/ï¾‹—íà—Á/ËwÝƒozoÎÎ¾;9=tŒ…pÖO D?néÛ íæmBÛ‚£€à=&?Ã½¦Ónïøàu7s×\éV©A’5´Ëõb5ùªqDœQ„E§‡Ý;?ø¦{œ™—Ü~ù‘HÛ	™ñdˆÆ¶7#/¥Ð*ép¦î>Ra`.>‹®äv¨<sÔˆ³Ï0à¼Ž©uÚ‚§>sO‹+	Ä$Ú2®Ä¬_'9^ÞD$û“SÑÂaœx3Ž¶fÍ€ÐÑ‰´Æˆ¿œaeî Ú×)qN1ðoçóvh>ç•÷ ½Ü4¤Ã¥ÝIÀ;Ì9Ì²dKôMãø¥R­tã@D,"’žlÚÒ±#'hCM±v@tÿ¤CŽÓëddPîÚ[;¢1ÓÌÙyÚ®Hu\wd3Ü¹³Ý(sŸ_ÈB±&dgbxWŠñ\ô à§¹aµæMü¬iÆ]1!ÀÓÛh4wžƒè.åLCDÐ²Å€¨ÍËáU«M&J¾âÞDcâøîÏ¦¦$Qå±ÈLE¤8ÅÄo%–ñ2›áX@u·IdøØ«8øËË¦Á»È__-MeAp>[èI­%é(µËLßŸ|ç: „ŒedQåUÞrŽoüd"xòýº¡¡¶gbÅñ ÊÅ“÷ê_]³FÙT¼œ )Ãb¬ôVç øA6ï©D¥>zc!¢šdI›«‡Û‡qàgU]t;ï3Í¹wÊ$[ò½èæe°5'’$|ÿŒÔñq2M¥œ±.Æa -# ŽÂN ¯«‚ö«ô	bctûóçm9Y:À„˜´"x7ëh<œ1ôs}‘,ûCJ°É 0mjj^ÜaD&‰—®—Â=°ÎÅ±
 h3þÛðš¯J<ƒ ý™áÔ³ –z­ï«{- nâzì5ìÿŸaøïåð{#X'W+š9íMGézƒM#n|a*ŒY×& Œ½1ƒ€­ä ô"¾—3ÇñûÑÝ©ä[ù:‚¹&•3f’ðNðMO˜3½a[Ÿ¶ÁÔ;Ý£”ßÐe3Ïþ§Ýa»Šg)J%É¾˜`VáNž?*ƒ~sm¬m}ms` œÁrY±‹E.`i3!†çIN\™`"/hþLl¨¤åÂ;ÓÓ¯‰÷¹¾	ù ×Š®ó½e¡B‹åâ¾…†ú?Ã‘‘ŒÃy÷U|)Pm3Q€y_M‰ƒ~rO£«mÇYÊDZïâ‰HÎ‰) !"'ÉtÎ6û{çWÂÀ/UŽ!”“>‰ñ˜{úžpGß;kcO`KöÄ‘FaÅ˜vxÂ6mütelh‰ ^µù`µx<Ý¾";õkù-¼ej^‡[·MAf*WðÿþûÿäFmeê–Â(û·TÙ?5m ?íðë @ã@ç¾~ý†I…µkG*Ã››9Þ§hðÏ:Á Æ3/§ ž&—³­Á0…v{ŒÿRD0:Ïå(Ÿu¦Õ1–%J©‚€˜Ì|uÅ(újM»ÁÅˆéî)fÅÕ˜2¸ÞÛ@^4¡^>ïoéj^0‘ãª0•‘÷Üq{?d;’§0föè"ê¿#ˆ¿è¨¨jY°³Ÿì@ÆÂ*ÚP íYÌØæpv·K€¶‚‚‰“TÇ(#uâr-ó%šƒÜñ÷ûŒ1Ê9yÙÈ™,ƒÑ¼š¢&gÖ:Ž»ß²®Uà•:\9­L¢)Ó¸ƒí9uKzà5®>¥fü‰1]Ì§€$ ìŠñC&ë³ƒfÙ[ÕX¼Í³m¹×¨`Ç’¯ÈáQæLÿQ‰[¨Äó“ã5Z­×§‚“g.á¤aëû-ö'lþ€´éhS–™Z[î™põÕÑá¡ÃnŸ8Û(¾>AAßÃT¤VK²D;3)GÒ_¿ô¹aUC8JÂ7àuÅÊõXx ÅêÉé×½ƒÃ×GÙµpù©Vä¡â)‘.*¸,‰EÁÙ“7…c>¸Ž§àAÁŽßòàÏ´½&/ŠðŸxxN²{ÊË…¢p9æ%cYžwe©~4'±eÎâWJãI0Ò÷¥º÷åÖÌ#Qc‚µ<+‰¢(´ºšBòGá[©eÿ^À¼½2s4g‚†cqCt0¦îæç[ ­€0[p´5¨Ê²¢©5òÊW¨»ãY9o%R"/‘¹¿¼>IÒˆ²jOe®Ó«ãMœæ#–å˜¡Úfk
-BË `¼8y{|è.|åOe°R±3WÅ¢„(Y„¦$¦G6ìÔ¬Õl‘q”H´øG«6 Äºs+¿v|‡bÿÿZÐ³õµ”4ø?ø×DÞ™1paÿâ_ê‰Ò´/5áÇ
èÉ»dÈJù(-ÎÒø¨É¨ŠXg(˜…'uŠ*óÑ¬©Éf¤fõãaVgšÙ0 ’°S2‚»†ŒJ¢Úâ$™Ît«Rÿ2¸ŽíÃßð‡Ý¶%¾]æ¦ÏîªÜPy{WçXmMC­¹Í!…²Û&“˜|Lä5l¸-,#%+ØÎŒRø'VLÛhÞ•C(dz™µ0’®|“À
é.éx‡»Ò’Ëð‰.Îg´ô¡å¶-ÏŠqFw¿ÓŠbØ‰A‘¤Å™A9•#•uwƒç”·£/Ô'm‰†P^T[	‘-ÂæÔÎ†¦%ºGÏO¾þš	jÎ3ÆVT÷‚¨¦¦æÊÄßÒ*à¶fCùªËøMW¨{4îeÛë%fCÆ ªOI¶6ùÌ{j²EÁôôoÖ:EÚ°:¢ñÿºáçE'>XlZ6W+ðÙ¬ìÄÏW„® 	¾H ¶¸)3t¸cˆÂlãIxàâ+ï(šA`’4õ¶4»0mG¸b&ú‘€¢ÙŠ‡ãþh>ˆÉfNQTàˆª?Þè±ŒwÆ#^y˜Â,’Klt@nfè6ã'äÅ7_5SÅ•ÑÛ…|ŒM‹OƒGiA»€!iO÷IáC6ŠážjöÈÕD8ŠNš¼Ôy… À„Ë›4øÛaXî{

CòRCÜÂ!¢ë*h!Öu4™ÄãTjJà±£ö$hd§ÈhSŸ÷÷Óäö2”£#ZàWrò:»T³Ú‹¥å'^•ÐŽ-üÝÉ÷ð÷ÖÕOõÝ	ûfÂŸ†ºZ*û¸6–CîqGóÀW<‚L5æH-fÇíx6kTÉS°â<2%« ÈÛ,ÅW<%„ŒKBh&(häÇÆgÖ@lP´Re$–7kT‰ÌGbÉðµÙøåÍUÒÙ|ð4ÐpÄ’}ðƒ.^yR%*¯|y³†gÖˆbšµ%›_tàš2Ä¾eÐÊDÄ1;¼áø§Õ…S-ò|:]t©YA6¸…ÉH±pi™Ç[Ëô~Q`Ãï	@Qiizç¦=¦ˆ+v9¼‰÷¤2§)v³dN•5f^g"I–|‘QbM+ÖêN^ºÄ2Z:bC¤S8û£|e¼ÚÏ_²1v{Ò²ë²ñÊ9ò’%©‹ªj62‹È_öívJÄçë›»J…ü¢õ]_,öÎ6†Š»ó`ŠèQÂÍUÞžß_â·øÙnðb>ñ»ùÁ!˜UŽÄ\(¡äÜŽÎ—ÓäFD?g€RIü«iLÙGqiHEXêðW—ñˆI™»írÝ	Û(MiùSðÌl’IU|b?2'Ÿ"™¨l#&;¯Ê¡#¯f5	@É:^t ð­%»¾–Ô…‰³­Cé<ŽÑŒkW”¤€ôý¬ë«j6hµà9OÔ›¢±€iR“Ñ~A)Ót)vv©ƒ€b\º•¬émgçÏÞ‰ðlæ«[/®$¦2ý€ë)UçQÞ¬’zã)o‹Iƒó‡±»›!ÞWh‰zi‡Ì<Í¶¾uÊ1T.Ksu¨*–Ê›ùjQUæò1!–kU[ÞÌWIù ÄxŽâ€\G}¬Í\=,â<%M‡ûÔ™_Óur!ÕëªùP|ù5ýÀùÑPÌYKû5]gZªoR™oÒ‚žÕìÕÃ"ÞTÒôqxSùø5]'oR½®š7ÕÁ—_Óœ7­ÅœÁÔA±_Ó5ñ¦e¡
ä&¡!úˆMâ[/‹g…BSQÃG™*ÏÅ§áZÅ%ÑéÊ¥¥Ê¨òiøs£ÕcWH;•±ëÓp]BÒr°¤Û¦<øüVÏŠøPaÃÇáCÕçâÓp|Hvºj>TU>?p>´zìrvR»>×Ä‡–„%Æ‡¤a¼œ‰Oµy‹GEL¨ Ùã° ªó(o¶Nö#ú\5÷©Š¥òf8çY9b9ÿ¨ŠØòfkb:ËAÐ
¼…ç*”_ú
w.è‚¶ö¿g Eà{u…÷ \Âœ«Á#	qÞc/jP‰k.iBBòž@QƒU3´%ÍYÈ-Þs.j°.úZ˜Ñ¨ë"žy¯K,.ß|QÃGòÎWž‹OÃGÜ¯Õ'äÓðãÚ¿ÕqàÓp]~oÑßâ†“ì1îqØfé|-ó²ð®ê‘è%Ì·¨Ç<Ô—0éz >.F²<ÕåËl¨°Àj”…ƒ~?™12é
+Ñ³c{'¹„¥‚î¼ÜMvÝÐm¿ÛËØO¢l)ÛJ­3¹›+µÎTZ­Ô:S…ÔÑºÀíVä†«¶Æn¹s]‹}Jô¹r/ÝÂ˜¬è·a­ùÂ·0òë Z“¬º$²C€bŸO&TÐã°›hè°_åñQû»ìqPRæh¨)sLÔ†”92²òOŒ
è~œó¢=äŸÕçù£:+Åbu0›sÙû¢ˆ¯æc;#~Ì§cÌ²:óæ·Zh¸°Þä±Pë³ìùPNætÈÀÉgÄÞ“z6\çùL¸êÃ†²ØD«ù¸ì&‹á¦*:¶Ä]o·'+2Þ*gXü­CàŸ3—ð
™Œ„çÇh¼&ëËp¾W‡m
øµHDWˆÓbÇP¬áY—‹‹‰UôÞw‰«s?Oñã‚U ‚@ú#[W­¿
uù²ês~Tä8êSQ]`u5sÝ›Dwg§ÊÍÙÆ3.ßå¤í†õú°²fö,¬ò&^|$Swµ5(¿Re®!;/>á:€>.zqÕT‡íˆë*l'ÓÆ"^Ê*2fÙÎ°2lÇ«üB‰×)ô¡Ú”_8©2×G	{XxÂu }\lgqÕT‡íÌ¦q”Î§wU2m´AeÞå±ŠÌ‡Y¶³ ¬ÛY VÆw´ ¬Œ÷È+ŸVBüã°ÃŠ´‘ÏëÌõGåDZ“u mIÈwG~@›3IN bx¬³1f\`	“Õ?.8LêÃÌ?T|ƒykMü‘yµ5ò`è5æþrîò°ÀKî]ÎXG¾ˆÆïzÓ¸ŸŒûÃÑ0òåd®fÚð\¯óxŽëÛ,[b†‰-1#»!Tr¨ŽÄÇá‰µV» øBíy??\Öäëƒû¸xá²ðU\m>(kxûô]ÍìÑY¯yŒõm\¢›.ÑÍ3Kø`5$.=ZÀIfSÃÍx1%7£k@³m5G#\;h –ðæZk±äÀoAt¿„©né1âZütèJ?—@WõÁÕ9W—zã
§Dãù%ÓwæÓß,œFïÙÎâéÍ&h%“x0¥kÊ¤´uÞO‡³8m{ˆ&P…mãyÞák|”•,ùÇ­× |X^½Øã òœ{þÑTeÜk±ˆ¯Ú,^}U |àfðõ`œsÈú¯`M¶ï%bÎbŽl{Bu¸dzW‘ª†9¸Qø°Dõu1o¬Ù¼P?Î[aöcô©½T~¼úüÜ<}Q/rÃ÷Ýl{ÑUYdÛ€tÍ°bEÆÌ›å¿öbŸüÛ–\b!;– =™±ßŒ? Fì»4žL¸Ò¼äxÔÖ·a¼9\rÕ¨®ÃûÃ‰¥/õ1Ð“\¾G¯ÌÓ¯]†EŠf\1oŒÄûòQVÀáJæ°>F]®œƒUBPY£­§‚qTÂiY£ú<¥Çvï?c¡Ï3 ÇÅ¬‚¾Éã3 ¸9Ž PÆv
g°t—ŸX1ÓöÏMÿzÏrULý¸ô¼–³ŒýùàrÉ.»¡¿«ŽPÿæKw¹=.<ënðäêëîß¼sçµiÁy˜L~¥‰2m´ñdÞåqêÌ‡Y†¿ ,›õ;@•Þö›ßãˆ¢— ´8w¥¹®³\7û÷š
v/€Ë:€>pévè7ës/€þ:€ä•ï£tWc•ØÄ=$|åÁÜð»B>YR—ä€¼˜dÙÌE–£Þ‹AzÎ³R\°ckVæZµ¦WÌª9VmŒd÷-ŒTS‡‰È²¶t[âÒOär´ÒÆåx›ÇŸfÊ‚ðl¶âçQáÛw®Ã_j,‰GðŠs~Œ;Ë™x]`kâBKº°\Õ¶þämùËkZ8Èb{^Þ÷><«&ärîUnA\ K·,º¨æýÌ°Ž¼Ÿ‘y$oLõ³Š±„­mv\ˆ–ªðÙª³d3åG¶:¹\{±ÕYìÒmžÜÂ|töÿ  ÿÿ à¡gåxœì}ksGvèwüŠ¾©n@X”ìÍšŠ\‘C	10 i[wk5†ä¬@vÍ½¹UñK«8ù”º`ËwWZÅ¶âWå—P_óKrN¿{¦g0ƒI9–«LÌL÷éÓ§Ï«OwŸ®œNj¡;ê÷üÁZ‰À?üÿÚÍRi»ÓÞ%»ífcë>iìçýFw¯KÜéä¸7ð†ÞÄëº¡wL#¯7Ñ¡öü‰w‘v‹Œ§C¿_K+r³´Õqê{Žh`I`õv‡l;M`ïµ)\o4ñûîÄÀ×ýn£u‡TÝaäa'××‰?z%‚ð¬wàNúÇ^”ÕóPìOz‰:n‰o7S &
rèËuE²AY†`žþq¢wè[{DçõaÔÂÞ‰{Ösû}/ŠzŒý*Šg0Ÿ? …‡ÀÒ×y ñ¾6Z]§cíë{½»dë®³õŽì°õÆCwr„'=wpâ*³º8 Üº8 ÞÅýÝíz¦åÎeQ…«‡Å©2 Å4ËÐya!ÅÂªXQbŸf«V.K«„”®S <*efÏ.[¡ä }u’·Ÿ­Læë^q0¯Ž"™"ÅÁÌ£Dn-ñÂÛA‘‰{0ô¢M2ðGþè¨.•UÅûX%A8ðBñ—;YËÆ
êHäÐ“zqàúë4­FÁPM¶(ÈK‚—
)]ÍæèÒå¨×\´NW«ùûu1êtÞîä¯~ÕÕç¼È_}ui¨¯üŠ„•OâÁÞçÝåÂ±k“9aYõ‰€5S¡dwìRUÊ,šÏT*¹úVH­,ÚASKÌÑÁ" .HÑ,JSoÌA“" æQ=ÌUÊ¡sXA­iö"‡D/Z3¦PŠÖ6Uˆ¨®;RÐ½m‘J»týÿeh„"È®òjI}‘~gW™[²ùä'§x'BÖÚÛ¼·<6¹ŸŽEdôó$¯B ëAö@D¥²Óiß3‡š¼Ì{wŽC‚š? ·ôÁ8x9Bê­m’Í¹Áë%º:ÉÔº(ói¥W•’ºN+LÉ¼•óªÆ«KÄÉhëš¼ðhç­|‚rmh1”9N¨È›LÀ#ª$:ö'âo/{¡;ñƒ¼q§ÒGUƒ¤Çb²"ëæ—0F p4€—§nt†¾Ñzã0LAQ÷ƒ“q0‚/PJ¼›ŽüÉjB~±næ°¬±ÚxÆ¾ä°j+„³¶‹Ã3­n^ºåÍÝÉËqÉŒAºa,ÚÇ2=DF?0A¾;êXžøQ‚Y)‹6k'îÈ=òÊk94¤éKç3„‹Q°(UÏ®:Ñ¹IYŒèEÌcŸ˜ÁÈ¡QYA­qö"K§¤T¹Rÿì*ºzPíì*W}• HO³«Ì-šÃ”W"´*q<´O3¥$˜¥Ï~9#Ã‹˜oœcSÈ•æŸ/JÝâ`V3-¾Š$ÖÅ$.féóåË¡î‰tUº /3––“ØêY–Õpï²rfÅËq^Š÷%OÅK\(Þ¡<¯º‹S¼×y*Î#H4þC*<oL¼üçƒ:Cï2 ¾ïEä¿þáÿwzîàŒÇ`Ö£>Hð€ø#ríÚk9Äµ¤Ð¦ÏYâg­PÈóÉ;¼b–Hõ/¬Mýš<fN/óÉmþÎgUXI8"ÖéEò «B!·ažÑÌPˆØèÊ!™KåÍ¬
sMÏDð£r4Üa•Pº¬£áY-d	žä‰ŠfTË«‘&áÔË9ã)ˆãìj©(ˆþìjyÅž’xÙÑˆ‚½™]m¶·¬ÊäÞV`ÔJ,h_s/í¯¦uûÁ2àÚ¶#ÄàÎÚ–P óKÔÌ^n5Ú¿”í
…˜cÖö…âÄ¾ðí—BqcgÂ¢ŸØÒÃ8—Fìw;åŽyÍcèŒ9LœQÞ8î­½O3§ózîp8G]>,8-N¯nLr¡~9a¦œTM×ÝEúv1^éü]*àªžæ§B ó~rC©<ô]2vCxŸ£<s<(…hòc–ŒµtwOt›Œ3f&‰€Ä©…Ïïñ-ƒÖóZ·wu	ÎÕÐ2>¨¥;{—Iëp½þ˜Ô"ZŸn]Xá3(Iéû<j>À%)wÚö¥éõâ$-à2uøÓ5¦s‹Óµ€KRÕK'éŠbZµ8PXSu¼¾Äï^ãN§¾×h·6Éõk×qí—×76®_ƒÚ’UÔ‹¦ðÄæ1µè·Ã¥#²Šã·1Ç¹¾IvUGÈ_‘.v…Ô±+d^Co%!–
àÕkä6ehR§|Nî¹0“û`“î&ä7ÓQ7î°Ã'+!®3[7ž¾5rä>ôH­Ÿúp¼&©7›øšœx'¸J»v8ñÂMBFÁhòØëø+8Á@±eI\;@X0µi9+‡ñ>ã&ˆÉð‰GPä¨FÚ'zŽHèM\ùÃépG¯¶|>à*b¯~»é ²iµ÷„ÂÑµ—9z¨7AŠÓ)<l;;õýæ9òF=(<NzS¶`·Ó¸WïÜ'ï8÷«P‘ÂcµiEl±µDï8; `[[ŽÑtTõˆŠ«¡­zw«¾í $©>gCC’¬z¨Õzî„Lü/š¸'ãÉïd·FÁieËí··ïTx/ªDÓá¨ëÍ=§ÃÉ™N@§EtÚï‘¦ó®Ó´µßiìÝgí.Ë°uiÆ
¬f–m0£9=K³æÚ¹ùÑj-Éí
”²J	=AÏ÷©0õÝ¡Q ?$ gLXr­Wž.§ëóƒ3}|ÞsÁõúFÞç6(›ÀPØ¶û‚÷› ©1Â£rÄ”N5 4h)4Yh’!¨ß3{£JMjÝÃ_;`þZå}>ÛAzéŽüßÑ¥8d©ðõžÅŠE•µ5PçT¼8ÜèàD«Æ„Nj6&ÒÊ±v¡\¼·’½²Uãûã^Níx™rf¹JÊtHÊÖö`ä\0ç`OoÜ?!Ë˜~-ðúdgÓd’Î\½Öž S+%ÜÑ›¼.›Vù¼¥*4}AX«ðHºž7Ø$nÿÁ¡
Ý‚Çaœ¨”l–âÒe£ÄgÌt?ÃÖÛ, màðF~ŸK:w3EÅEQÚëFWëŒÌV»µZfÏÚÙncá» /Ø¸Ô‡Q@"JÌ ¡:¼IÌ—“z,©T¡Ñ2{¯$³JÕM)xÿm»ÑJª.äÓ¤ºeê’Ô
yÅ6]X™ÞK|(<2KeOôákdÏ?:žx£T7~Íî†~ú“3¶ø¾‰¯6jq§¬¢Í8×È=ú‚Àb$±ÎõugÈ±É ³çÈŠfC “cp@Ùk„q£¦ÜÆâ‰¦b|•Þ¨±“ý§~äÑâoä{ËW ÂE Ýqv›õ-‡ììƒ@4bÊÖúè)]€®ûZ©ãìíwZ]r »£R³Þº³_¿ãœÌw©?]N2:å–Ó{ Ü ÝÉ1†eh³¥z—üìg%ap©JºÕ B``záÙäômW€8b$aô×±{| ØÈqX,0=pçž³>J.RäôLÏF¢žt4Y¼´ˆ÷¥ë·Y.ðK!¯ÅðìâÝÕü’™¤+ìôd9<’ÎMïÈíŸ‘C ,ZûÍ¸%N½²SšÔ×”½c?"x¦"R.?šxGìÈ™À5"§Aø ¿œû€ü©GN|,àTTéÓoX+Ê¹À¬&«Ö2y4‡&(G§ó\Àp46E˜F]*âTI? a‡Ò=€Ú&÷žéx H-:kŸŒþìg`Ò˜Gé¼z‡¹9ÕUiäUnÕHgw‹Í9¡Ä¸Ò9Ú	´¿’ðáô´tÝáRæ¢æNqvåÔÅŒ~Z? æý`²–Ãj€g™ZÂ@
6m‹¶TÌˆ-£E‰Fî	 {×óFòu\	JÜ‰0PøšŠq/
¦aŸ.­-Énév†G>¤(¢ÚC?‘¡Õ¤¶¬êN]UMÜÊB”77)Ú$Ÿ]ÊrYÙ$[·D%»“ƒÈbiíVIØ&#‹ìlØª¥ ¨íí0lY;VÈ~Y&ó:Iæ°KY6)Å³GÅ¸ítÈíûäz^]—"”Yº®EþsuQpõT1á<
Á¥€Xó“@¨Yè†©ªôéZ–”žøMŒ”„Ž‡ã#*¥ÅsÛÙjÖ;´õ°×¨Ú'›º¼IKLÜ)‡‹Ü,Ývî48Ó×¡ì&a0ÈÉ4ÀK˜¸PÍr™(@]¨O·`dï®Ó*iÜÖ‚AÓñ£ÅírêqÁ8c-sá`Æfç,_Ð"‘ãnXRâýY§§ÈKã.Æ\½ƒ©?ô‚ƒßxýI¥M©Œ xºD
­xaÐævÎ½F·<ÞÛvZg»Lù…Úmìàoñ‹ñÊ»^èŠ“³Ì#ŒJ	ÊgûæŒºñ1Ôz3__nƒêØºÛ<z;íýïŠ}6:L#ês9pYýý®ÓÉF¾A·£ð¹{4Qzd0E-Êyfh!ïÖ›ûN—(ÿ¦jO‰N
Db¸nøhØ€ÑvÚIÇapÄ€»t–Éj™+X‰’ÄÞ¢ëÌÌ¨Ä¯r•h)K$Ëf¯
Qû?çJ~+¯³j;H–%ëx'0§`|K£´Â–…ÞÃà—ß’…C ýdË~²eÿãlÙ–;ÂdÆ'†n41itàŽGIÈx¥¢sB?˜Ž&•Ÿ¯Íš¿ð‰ˆÕã^#sÆuA#Ò¬w÷zÌ&,_‚ÊÆQM—’X27Þ@™Oßs5ô£×÷iêv¶Æ¿=>ÀLt<ÊQ,¶zÔT£Ã!Ÿ¢çQÿ‘}5KûGôå¯~}å ¾4mÔŒ	éÊwåšJ![BàÔ·îø–¬w:õû&i›íö®©åó˜|&æaÂÄ¤™9wä44EMÍÜû²wgé&G7:ì7oÒÝCf‡ÁCsš¡‡(ybñŽ‘†.Þ¢7:š‹VQ•l¬É`2È{vÁ[äÚ¢ö¥¾×k:hcÚ-'ÍÎP?•ª%M+Aç‚¹á,¯)J7D7êˆ}4Ê`LG#/š4‹ÏxÜ Ò›¶¼È´xÑ%™¼£,Þ¯~}QkÛ5Ûffº^±Ò%‰‰7¢¬O×^G’¼M¢~èéZ4q'QÎÕm±¿Ç ÷hõŠm"®_ÕZ„ñÅX‘0¾DÃé‘ü¢/>°Ú„¶k•ÿÓ6¯j+ÔQæµý#4‘;qµ/ú·I0q‡=iÒŒoý£úvì
t{±Åºþ²VH´•}Ì”På¿èš ÿT¿c« AMŽ½©dÍ(,–Ý²E§&½ÜL`i‹ÒŠÛA§YÕ<M.ÿÜÀRxo*àœ­s¤P"c¹™îÉÒ]¥4Œ	3 AŸFð±ÌzPŽèOC<hˆ'Qü`Ð£É@ßfÛÅÙüºDR‡ŸåüK1:W‚$t·Š,Í¤k¨e/”%‹¬ºý0ˆ"C{Vp
NÁ2O=ïÊ­Ž	ÀcyÛØ‡‰4Umrg=µ‰65ª
Ô;qý¡Ðt\Ab9ªKµw¸e¾Ç_ŠwÔwÕMYÙÍ»ŽŒëˆâ „¦ã{qtt5­)èUhÃ)]Ö(¥ð‡ þ–dÁ¤þéFm«{q kÕ„zJjÞ©ÆÆ¥äÒ2Û8Òtvör,(ËÉ‰:Ùë±ÊfèÏYp …WKÛ‡)
îæÓ¦+@VøXF³ñŽCÊY&ÿ÷ª4ü†WZaÉÎ9Ë+VŸQAê™é²ôŒ’nº³#EÑìGGCÏðpDX+ØŠ¦eËÂ8[ÕL(Xs>ƒÇt—MMQ#¯œ‘%GSDè£@œb©ó_m2ÈÏíZ9{¡ËNc‰ÑÂË5ÕÚªw„Ð2@b_¹	eÂ.eâ4¡Jyà¥}nm3­R6º@§Z»ôùšÄ€––O—4/ËàW67ã\yQ“3§F¶†>4²ù<(IÏ†sSÕ{6 ‘`EäèJæoô˜¥ØGæGÂl²yœ«¬r•x£hÒ¥ƒ3˜r ¹#¹Ç!em³fg©´—9”M5hBê¹ˆ/›l3Tµéà$ôŽ¼p¹:ÅyOslµCJ,QKÑØ~6Zä[*‹¬Eëá8.W R—z†m¯Ó¸sŒ“:Ä6Ù¶Ñ<5a° ‘V¨ïàÙLN!{a2î´ßCÄ¹(ÏÍ
w þ~ ^ŸõÜÑ w˜ ®G.nîEgÑÄ;yeÎÇ›½uœŒCôb„VåÞt8ñ×÷èd…tõXÃkd‡õ{ýí7éÒ~¯Å&¹?¡imp“%½-zB‘c3)bBP³¡ðƒ†î?aBðŒ	¸	`ž_£{ãÐÇ¦ÊáÐûÀ? êÀijý³>Þ!þaÓOÌ®¿Æ@\¯>äxŽüÈ&á©ô1¥š;„7ã ò'¼éT1é»c€ûéC¦'ÁUNÜñ˜f#fQ5f¬ÈëlO:èë¡âODõ7jÄœ˜W-Ö‡ÞCoe=Ú‹MÔ“.öªÊ}B0Õn4é¦ð+šFc˜S{ _ú lÞpˆ?AÏû¡7à-½YºG0;îÁ¤A£ìË:@éû‡~Ì¦x}àGø(H‘&²‡ùûàL'Ärxý““)Í\À.N ƒ/ˆªwÿØIÀL,#
†SZã¡›Zf€uì­P,¼W•±ìßïÌ\Z%ëoK—V‡‚îº¨$·PgBan°ƒ¢ùÐ‹Ã©ÕjkF9ƒ^ÒÕJ–Ãžqƒ/Åb‘ªþ•hòí©¢À7æ/k\pAë4»`IA*ðð–¼xâ5#ÛÐaæ;©–ª¨_Å\º„
³"ÔVÁHX)çý=§…n{lð/ÆGýðl<	þb5Îž_O¤»tØ³óG0ÆSFPªh	!ÒÓF “.c-ÒÑÁ·2:Îs1Aˆ¥ì%ƒ<BkI¿I4î</ÊÐž]”tíŒ¥´•Z0QüZFr‰Da™e‚9ã9+ÐÄ| ­mçýØ@øƒztØÂ‚–í_VðåÚÍ| xhŸÓ(IE’!«&¡ø9p<M¶½CÄÏå¬r9ë É‚V4¤¯q•äi³ÄÜZ k¥ì^cÿÖ-ÿãÿ6p†½z0sEã„O‡ð„ÏŸqþõùÓó?“—ŸÂÏ'/½ü>yù1<|?áÏ'ç_þäüOçß³ÇÏÏ¿…Ço±(Ÿ;ŠÿoÐáÎ…ÖuD ;qÃ	[xÔOhïÑôÓóçð—#õ	`ù4ýâå§äåcü/¾„ROÎŸÑâ€ò×çÏ-ˆ]ÏØ‘ƒCæ0bÇž9Y$šOÎ¿b~DcÈ~zþ‚œï¿SÈ!òOÏ¿ÒPG2"ùcØÞÈítËò4òG|%ø@û­cø9R1B¡ ±gç/€ÐÏsŠ¼øž2ÃùâåG€í×ðêkY	^=‡¿qôßÈþ›ˆ¦Ú&ÿ0¢LéOZ ¥ÿäú–”cõ`ô±¢ðÇ@Ì¯_þ#A¶yùøå#rþùËÏÐžÎŸÇÐ|sÍ<N5Î÷X°‰Îd©Î¾šc«¹¿ílkqa]5ktifåÅª—Ô?¬ÆN^gvMÔ–sYÖRzþóØL
@ÔÊÈˆÄ5vjn%6×èQ/Ý´Á"“žY„n
:çêxx†løÛ)ÕNìáÌsù¯þ4š'å5†+ö“Œ¦'ü¨l\¯^_K3 l¦sÃD”);wvËtÙvoàžEéyã‚NÁj­·J*E*|ðª&ù«²û¹M=g!ú;f¦ù'Õ–
Œj¶m2&B€’i–Y²iÖô»B¾ªŽL¢A·Ð(¶¹Våc	£dfc¤® ¿ä½˜[Ü(›i&ÍÍDØ³ëo½%ûvmf×„m_¤w+ïœ”jèÛµîÜEÝ›…†Îp|^ñ{³Øø-­‡9ˆoDé¾øV±\Jï.rð6Šžæ¿ã·Qp —ÔÁUxÐ7jdÜ“ý¸šçx%û—àG«¸õ<Nôï,5ÂdJÙâN¸x{„Ñv«û,¿RÏ¹„tö¦®´Æ'„‘g(„“ÐÐ2‡þ£átó=¨à³‰ß’ó@•þƒ{ÛÅÂ`|i µ(Û’p%b[b¬1¦­9»âu^ÏŽoI r\,Ä7ÝSÞœÖá.6½¡Ø‘ÆÝY4Ëˆc	ÐUE|#n5è¿|ôò#-ÖCã•ÝvwNýÿxþ=FDÀáCœóŸ?£œÜÓ€ÄzUúó[¤x¡B?Àÿó õÀ}Fc ŸÑicW¹Ÿ³b²* BÑPqˆ¯Î¿Ah0xòäü)m‘GZ¾¦ˆÿYz¾´Ã«:ÏÎ¿ Ÿéñ!„ûˆ‡¯4ÔÆÓ°ìF^$âPPï;>qP¢QøKcaÍóÏéûO911p¥ÿ€¥_ÐPÐ¿«ØÞJsxï·	RH°†[4‡¾2Ü¾=ÿâå'Öª:ä/iDç©ÀGòÉËGUf¶ÊfáÉV1âEÇýÛTãŒÆé)˜<0XàïÏfØ¯òÎ6clhé?p,’oRúõÌ
þÀðþC[§Tüó²vB÷²¤ö&¹z<•À˜vÿ³—ŸÐE&Hˆ™à^Q>QU¼ÿWJÉ?FEU2š‰]„Œ,"g“áïyàõ™&,äáÐâ	£Ã0ò¥5h©¼¡)öl(j:E ˆLö§—I®ÿ=ÅÍ1¦¸|OÉ—@Œ†4Që=JšŠ+XÌé!˜Èiž“ŒY'âº„ÑBö…ˆ¶Â{NBùÉ~vþ%ª/]ÂŸÐ«¡¸tŒB¯ï5½…þÐÔˆ_¿üà?P?F	ÔµÁ#ºjÁk} >5+T¾žÁû(½PÀÿ)9zGmó1Æ‹U‹Q½úm"Rn)§	¯ÊVD¿8ÿæüOÊ8|ôL“tÊƒp©QŒãcK2e[´žŠŸêÖgÐæ§:fŸãàâ‡˜ý+Öæ¼Ê¨§{hšÞsÑ‡ôf!ª¯(’|IñQÂléÞ×”)¾u¾bbÀÌTˆªGt5æß”
bZê#F$½/:±½úÞ°çŸ`OXG¨ýþŒZÌçJ—	‹<I¬d)<ð˜2à§VþÓ¿` ©er"[ÑÜaòÞùgè‹(J¤ý# þGôõÝíXyc¾”LqMî¡ðŸ¢B;ÿO*?qºÇH;Â/–ó¬«TLÿ¢vPk–"Äl©`bFG\XÏp­Ž s(©fKNÌ;tùæ£	ßP`,Œ[d®§ïW”4|-Õ( u2íç®Yøh(ú™Ê]%q$m^¨¦IO÷	ú¤ë„\ã1˜OÑ,Åêf)6ïd<Î<Ý™Àÿr+-Ã =§Ò›p ˜C÷­ù:&a	î³é/í©ÃÌ!JÑb/ÿtn×·h¥Ø˜~J×Ï¿gEŸA-´Ý	Åöœêëšjº°DÇþád'r¯YŸàJéw(®ÔvióŸˆ1ÇÉR¬–xø†~£< \Pª°`hÚ†K¢S¹Oàiîˆò„qáØ"9PÂùèƒú…uÈÏÿ™P¢>æêY7ø"ð£ZXzQOAþð&¼è7¨ID³¨»¿À Ð‡Àõ{˜~	æû1{‚"ÂZý7ôfH¥ÞÀœ[˜ú;Zãöí1Õ“Ï-:YÖãüB½{%±Ü	‡7OµÒÌßfì÷Päu}?ËTîØ×ÓÊhd<~A}YÊ¡_¼ü=`TßmÄJ³Â´}¯•ãÿ@µÃG)n/“!§³›4=¤1Žìs=“k•¬Uè{Ò„zk†'.Ø+±ååK¹±@{A'¡rñ%þÃDd"SlûA$¹Ÿ³¯ ÄÇœo?DzÿžÏÕ¿#’Ð_š•ž¡IPÆù1p«T~Ï@œ™ûñŒSÜä,ýÌ.1ÎV4¿‡Gå‡ñ¡ü“GˆŽ0+užœÒª*‰(ˆ˜f|"]jåøea3óQt(3k‡ãªûî€à¿Ó†^H+d™_hæÎ4üqk›…-ÌÆûØÉu…0*ºç1DéÇ/øË*G-‰š|¾R-ö'FEkÒ½&ŠvÌÌ8<†—¾1FF&µBâÝj‚ùoðí02¢ÿi6î5ö.mgÌbaý%í{¡s@’‘ãT`lKú`vLžnUï=t‡SOîmÑÏPW11
­„d}ƒœx¸n4ÑzôºFar6Žoè‘Ûh8e±F¡Õ «â;• Šþx}ÿ„íò“Íñ5‡KØ:£F'ÿnüÁƒé8¾cFŽ¢¥‘ªA¾&p×ŽÙÑ9¼¢†²œ<“QË¹Åàã^S•P‹¾ã›$â¯Çauàÿ.þ
/?6“qÉeG‘ÊJ5œk›ÍÍTÑ¼»>Ò!aß
í=H…4É½
žéX`-V¤'Ú¨µ}x“Ô‡Cu,GÈ;žBÜxƒà¢p•p¡ághJÖc|1ý—ÅŠUMÔ«ºâÐR0i 0èa?¡iø9Þ’L™Ñ‚¸¶½5‚üd¯PÖ
j¾š§´u>n¯ÈD_ÊÃÂ…ð¿žï7‹â{]ÇS& KfN9¤‡¥ØáJ›J³$Ãº^#|Wø&¹íF~Ÿì¶»U˜@q¥JvÅX„a¸±F*­€¼³åà/;DÃˆB_Ôå¼“}×ã)éŽWÃž\ipÍ[jŸø"©±i¬þËmÆ*˜‡µÅ
Œ°‹Zu‘ËìD¿žçŽŽ;õàÍW]¶6rá}£(¾+“-î°š#AèjÍß¶°°þ9…±“Eèk!Á7ÀÍÖìXŒÁ bÒÙa+@U²ÅfÂUvh¼úõ¹W5%¨ ¸1à„Ü0Òg^”Ø‚•¾ú"[-Û?±$­­½iQˆøjA|éÃ6ý7&×ñ¹«âK,ý¤W¬øÛ5FïkE¾ñãR,0'6ÉÎ”Nöñüò¨?œP[¦½óT~sÎÔ/«JfãÚ¥hpòój™xìYår	SÅG_ŠÜÿL	K‘„[\XÄ6ÞüqÉØ›5¢ŽãÙ'{U²?º¼)Þ˜áéQš*YßXÙYc©–M¯o A1YÍ
³‚X&ŒÓ½ýæ^c}ÏiÑK¦÷ow·:]Ì¤rñÌX~Œyâ™<ÏcŽ8¤‘<+=¹H€´ãt÷:À'Ý/¡ÙˆÃh&(ä#yÚŸ¥ˆK	XŠì!e^4,;dûòSª¥”9>cyvc™@)ÌlpÉÜ¡	˜"ç‰¥=™Åòsv9òN¯ÒÙFÉ¬ô-h`—:h?3QO‰Ö_¢ÿ€Y-Šæ|@­¹u™™g<o›4pòP÷]Ð‘9ì4{Ly-WtØÄMË«:Õ3Q¥TG«œy×V£Ð~ÎM/–gHû]§Óil_ÊÁåô$<WB³™—Tdžì+·þe@˜#ý 
îƒ³4Ì²w¦kß‹SZr¿‚+8iœ—\ÌI+io<¾²³Tx]3|â¼ë´öp‰µ¾¿ÝØ#ÍöKöJdÞ«+!Áf†©T¯ÂÔÅéœMûf[åöFûÎh1I`ñÍm6H|¥†—ýœŽðÄý=NGêÉ°O¡g °š+ús"«.åª¿âÉÍÄ
l0ô4Šž`óNã¯°”îü‰bñw'ÞÄwY¦0‹Cöþoys“~¼TÔ¢sçv=Å óBºY¥O^‘~øe:ÑØkÔ›äv}ëtwGÜÐÞhÝ!íÎz«ñ¿ë«™Á$×ª,_K*¡Vœñö¦ÐëaÖr³Q7çŠs‰åäd-€jGgµHO®//v²Lµ“³/ü§Æ˜¿S^þÈ¤F{
õ;$’
ó=Ÿ:ˆ—¶)CÊ7¨I?˜IZyYJŸšBÒ$¶xkN•T½øEùß“¿BŠ:@‡”ßºF—²·Ñúj ÔÂ’d–Ýó´ÊÂ[5ÀØ´¾¿w·Ýá‚öf¾íæ>}XÙÕ6õZJŠÅ<—ÎÙs3Ž{1­{“*‘±È,™Ld<ßmºF™hwÍiè0½h[¥õ/;í÷öîï:RûÄ5o²Ø“q]WË0pSÅ¦&F¦Î#àÈM³ŒpU–{K²v=qKð!×/·äw‹a~Ñ¡¸5–ß%(ðe	µÙx*7¾ºn¡ÃÈ$.Ë*¿Ï$ãBãšº#uK»ð©ÎÔö%–+kb(¤ß€’ëÖTuáŒ«åèÞD²‘qùhzwøÐÒe€äØn€ècD‚ø‡æ`ùb45£'‘ãdÐX4ÝXiy÷)†7¶Zm@z§ŽQóœX_¯‘o,¦3ºBôçA”43Ó82Ì”®ˆ#¥kÅ)zCP”ÙTXâÚ-½¹(c‰žéùÐ‘ORþó-ßJ\ÍkãbßìZp•öÕ‚­:´#j–YŽNæ(¨ìxÙi-%Ño®­­‚1
3042».”½Ó’Ë)‰y!jÚuAiw,n›ò™Ä<ì1KÈEë*OÌ˜ñˆÄ¬€E~ˆß…=Ó¿r~R+ãPŠº,”ãúáwºÃaÀæÃj!½CU8qíîï:^}û^£%ÝÇrLC–â„åÂP_´8XY¿±Q~Â9»¹™ù“ZçðÀ#d¤š¤ƒh]*c*’­}Ü,)‡ï²´¤í¶E9qÿ‹"ùö@‘ôvÚû­mJª8Ñâ}ÖP‰f•yQÚntQø¶{wšíÛõfó~.Ô˜¹bÃÑÖ-lW³ºF±^±,sFó˜â¹éÆÖ#{Ýýî.ÐÃ‰$ÃcÖêÒš!HÒ-jðcäÈcö‹R¡ÕîéÑÐÏhøÙ™Ú´Å*¼¶0^:RicdAÏê"¨ÈÞrÑÚª·¶œfs^´DŒ­<geB*éþÍŸeà¤ƒ.]-ß5Y¹Éä¼¿Ûèä ’!YoÉºÍfkÂT´…©®À”€ÏäÄœoMh«—õÄÅRØ÷”y[ÒÐgqÚ…—zÃHgmÁê–²EúO@¬¥¡/'–­lz0‡Wód21ùM![ãì‰µMi^Œý›Ú€ò®LÍb¦ó õGû Ë«+Å…3=Oßt¯gF×À\tÏb—¥ÛlË›BhN`Îÿ£"ýÚIDx¥¿[’×%ò•…[\ˆçüJ¹PBÔ«/éZÄe53Åýj´Øæ0øÑÃÓ’6'ñÊraÓ<Té˜Ò«Y)rpF¢4³#VÔú€¸ÆXÎŽq‚·•µ/FYîƒ'‹â‡íª1ÝªYn«Éyß¬mâiŸPÆ6\ø”R„;Ù´ìÀ~JÜnê7¾±R	‹½Þ´í’žÑÁë“»³‡@ÕëL®ÛÌöfÏ)ÔL^j„ÐÔ‚ƒº\†²c»*ën•ÄîPRmÇ™z»f¹È‰TÄ,ü˜Åƒ€xq‘~O÷ïšä·SðƒðÆ¨ÙÜo¹&jaî_e¸§ÊTºôÀ¾Ü¼•!ÐwVi×
nµëM§»åT*äúÛoKý·¶¹)îvæ‡õcåÔH“nË%Î†£O·+ó“¼y´PòR«œk+«W5Ö•zâDl"b¯ØEhÆ+~áblÀò¬d{é|2wûË,é?mŸnG¶*±L…’µþgåa¾5‡…"é¦x:[«°³ûñl^†V¡D¨ÈvÖ¶8:hWÅ¢½)Õ“ø©|Ê “’2Fåçk‚€ŒQ2Ì@œðÚÚ 9âí[ÐÞâ¡º»ÇÝfáƒ5Û[ï°Yb)Þ®ÆXYÁÿ0fºQôÖ=  9—É®K'Ÿà{†ÖÛäŸ/KjŠO‹N9-)/÷:xýélRò¶ã‚:ŸðgWJº¦þ¤ÒÀÅ4°~^4¦~Ó3D)—Ó›©0¬^ïj‘ý®Ó¹ò:§Ó5Â/¦‡!`ù¶7qýaÞI§8
 o­0W\õä[×¤ûôô-z±Ïôæ®äAžäâèTsúõ%Nã¥0‹¦^Dô¯±t›hêWyÚ0½ßÊœT¥h¶\óU±³eþ}-RË)§*{CÎÌ-A™›‚fmJu¢fî­±I50Cj«`j=3®.tÓŠÕc72ä]Ó„²ªz&|fš|æ6ØdTÔ@Û<\—ka‰k"(Ë/²±·*ZH%ëGG¡‡ÛåŒˆ°¶ÎÈ¨ç±@dF¤fôHF<6,££˜¾Tò¦m0ŸÌŽGp}%Ã£ä…â«Ú+/møøP	V	-1O(˜uÆƒ²q‚+aÛN‡Ü¾¯ãÃ{†QP}g'aêQÜ¦³³Gþ¶Ý°§&ƒÖéþõÃš<Çc¿T¹À‡”ˆ»U¾¾Õ–úSÌZÎ3²TmcrYêþI»‰•à,p`²€J0øfg5ôØ¬rûPc	ÛXKo°6Èú@ê+syðÕ‡U©cP®…jÅ*(.Á
‡ª‚âé?âk‹Rd°E“’¤{«1+=_X ¶nàgšÔy|áÔ–ÎƒÞ¼úHNgÒ©#iD³¦ø@óŽ×ÇX£CÝ“¹å,òt1SG—Ø'õ,‹¨SA¬ˆzVjXžbEÔ³,"N±âI©c¹ËŸPÏqíh|¤gjt¡òqèÈTL—æ¨Z$Í ß$I„ëuýÅ&òfLQh›› -¿Å¾ÌXá¨¨S†§A÷`ÄÏ¬”å¨é{/ô¯¡Y"v`¥?É¢šK9âR6ö‚ÄŠÇN¾”mG_d•¬s1ñš 8­|Òu’^•×^*êhçê}´—²¤:e/Ë©WŒÁù˜³¥ÔcõÁæÆŒ0,•RŸð)ÅSâ%´—&nèå¡K„¹ahî-Úv‚äé¯«,º~¡VÄ¼ P”èˆRì*EsðûgZñŠk™SFe½®A¤;~ÊåïýW¿gUb;-bUåkkÝiäyÙÃmRÚó•ì±fi1íY–‰0Z0þÒt¦ÍN±wfJÉ…ú;5~”¦NÒÜ“Ù}ØÑ§<‡‘dÜ²×?vGGž¡-Ó÷Ç¢ŽãgXÇ½ì”‰ÓòÐNZJ¢{V¾Ï<vŒW½ÔcjQÛ¹‚ÄÑT\p æ¶r†¾ßßœåÏÎa*­Ã›·Këû¦m>“óÄgÌv§=u³™fZ,ÖM%@(±¹qZSë&o²g4:6\,5Oµ°v•ŸÑPÞà(×4‚ì¤4Ã-ãt¥‘ÔIMe&,ëÉX½€évXDSÏbŸjºM	ÕªX-ûÄ-ÖQág7ƒ#vä6sèi,÷¥ãŽsÜKÖÖ«ÆÓmV'æs±O"¥›!8ÿë–Ò’4ÐKîÃeYäT‚¹€Åö[ë/’ð¨ÔRh‚­X™-Wa©ìD:úRu3›ä¨–¬bf]_ès©<ÃD	éRá[f'3çšb¥÷ûÄÌê]Ó¬¦í5[ÐÄF*|+Ü–eÍŠe­a/ód¨÷´5he±¢cWÂRª¨¼@m“E½‚¡ìÜ“‹ËÁIõ™™ü)¡Cca?-ãS±zx.‰cìW–sÚÞ&’˜â»ŠÁàâ•ŽŽR3,­=×Q‘–\EÎÎR)Jr©Ó
é˜_†å\ÜîQ›¢t³"ñÌ8ÜŒ$²ã([2s¢Æ¢-	nID¤ÍŠ¢ŒŠ=ÇøI)FÒ§iK³/Å,Fè€üÚFñ“Eô8Ï¶”óœÑ\§ŒÄtln¿h©yTðÄïµy5i:ï:M"±Òiv×ÈnÔscÙëM˜ ñ¬kÆz/;}aÁèfZ±f[¬¦dÃ9œ³®9Ý.V7Õ˜aš2 à°ïÒayìR*o’]
	­'»±‡Íšª†³~ˆ[‰úÁhÃÒv§½Ëé>ŠµH®‡`ÁËÇ.—Šn
ýÌke•¥ù°¸âãŽÀ€S;}óq×4ö»˜¬’Ø-Uã
­J&Æš]p¡—ùPÏ®DûPG×Î@ÝD“¼×Ø»+2óë;AùG[?òÔ»ØáeÒ7O—ò XÉ0©mTÈôÝ#K“5y—[bäÄ—8mf×¸¸V¸¤ÒìnÌ¬zÑ2˜Naã³•isÖ-2DÜÓÈ‡q¶°äD=UÉœ¾Ïo»)ú …Tè‚Ó‘‘)ª°èÅ2yÇÇËø'X‘ºñ±¶“Š:ÏqŠÐ—"‰¦Ê¡ÈmÌ“¨,¹ÃÃ@V-ÐóŠDìö´í—±î-Ô‹Ôíóámß*ÑJ«Ø §JD.ÉdUb•¥MJ˜.S ØÍ()ÔŠ¯@'%"ÍIŽ“l~HW]ÌÒð^¥Äéà¤¤srRywþ-ò"ßÛ–S(
Z‘Á9Ó^ðBYº¤œ«.”W$ù”½¤m.m]d°Š \«/5P„ªÙu:÷Ý.¦õ†iÒN½µ‚×)XÁz±9zÕ2!¬Æ'U»kw¾o¦µgXêê,…UÍáøÈŠ6÷­}€·ò¦FÆèòÚŒžd@M9nHcæ,rÎ–RÉ‚íX’%,®%¯ÄÒàšyÀùAÑã¾sšu˜onÀ³6º%¹A¿ÆIX¸yÛ&€dó2G†<½Šïn<e=Iµlk¡Túo   ÿÿ ›œ