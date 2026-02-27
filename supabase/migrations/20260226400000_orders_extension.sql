-- =============================================
-- SUPPTREE - Orders-Tabelle Erweiterung
-- Partner/Provision, Rechnung, Versand, Admin-Felder
-- =============================================

-- 1. Partner & Provision-Tracking
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='partner_id') THEN
    ALTER TABLE orders ADD COLUMN partner_id TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='partner_name') THEN
    ALTER TABLE orders ADD COLUMN partner_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='channel') THEN
    ALTER TABLE orders ADD COLUMN channel TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='provision_rate') THEN
    ALTER TABLE orders ADD COLUMN provision_rate DECIMAL(5,2) DEFAULT 0;
  END IF;
END $$;

-- 2. Denormalisierte Felder für Admin-Display
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='customer_name') THEN
    ALTER TABLE orders ADD COLUMN customer_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='seller_name') THEN
    ALTER TABLE orders ADD COLUMN seller_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='items_summary') THEN
    ALTER TABLE orders ADD COLUMN items_summary TEXT;
  END IF;
END $$;

-- 3. Rechnungs-Felder
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_number') THEN
    ALTER TABLE orders ADD COLUMN invoice_number TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_date') THEN
    ALTER TABLE orders ADD COLUMN invoice_date DATE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_netto') THEN
    ALTER TABLE orders ADD COLUMN invoice_netto DECIMAL(10,2);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_mwst') THEN
    ALTER TABLE orders ADD COLUMN invoice_mwst DECIMAL(10,2);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_mwst_rate') THEN
    ALTER TABLE orders ADD COLUMN invoice_mwst_rate INTEGER DEFAULT 19;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_status') THEN
    ALTER TABLE orders ADD COLUMN invoice_status TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_paid_at') THEN
    ALTER TABLE orders ADD COLUMN invoice_paid_at TIMESTAMPTZ;
  END IF;
END $$;

-- 4. Rechnungsadresse & Versand-Details
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='billing_address') THEN
    ALTER TABLE orders ADD COLUMN billing_address JSONB;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='shipping_carrier') THEN
    ALTER TABLE orders ADD COLUMN shipping_carrier TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='shipping_method_name') THEN
    ALTER TABLE orders ADD COLUMN shipping_method_name TEXT;
  END IF;
END $$;

-- 5. RLS-Policies für orders

-- Users können eigene Orders erstellen
DO $$ BEGIN
  CREATE POLICY "Users can create own orders"
    ON orders FOR INSERT
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Users können eigene Orders aktualisieren (z.B. Stornierung)
DO $$ BEGIN
  CREATE POLICY "Users can update own orders"
    ON orders FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Orders sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Orders aktualisieren (Status, Rechnung etc.)
DO $$ BEGIN
  CREATE POLICY "Admins can update all orders"
    ON orders FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 6. RLS für order_items

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Users können eigene Order-Items sehen
DO $$ BEGIN
  CREATE POLICY "Users can view own order items"
    ON order_items FOR SELECT
    USING (
      order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Users können Order-Items für eigene Orders erstellen
DO $$ BEGIN
  CREATE POLICY "Users can insert own order items"
    ON order_items FOR INSERT
    WITH CHECK (
      order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Order-Items sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all order items"
    ON order_items FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 7. Indexes
CREATE INDEX IF NOT EXISTS idx_orders_partner ON orders(partner_id) WHERE partner_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_channel ON orders(channel) WHERE channel IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_invoice_status ON orders(invoice_status) WHERE invoice_status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_seller_name ON orders(seller_name);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
