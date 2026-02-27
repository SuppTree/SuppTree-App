-- =============================================
-- SUPPTREE - Admin-Felder für partner_products
-- Featured, Reklamationen, Sperrhistorie, Dokumente
-- =============================================

-- 1. Admin-spezifische Felder
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='partner_products' AND column_name='featured') THEN
    ALTER TABLE partner_products ADD COLUMN featured BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='partner_products' AND column_name='reklamationen') THEN
    ALTER TABLE partner_products ADD COLUMN reklamationen JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='partner_products' AND column_name='block_history') THEN
    ALTER TABLE partner_products ADD COLUMN block_history JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='partner_products' AND column_name='dokumente') THEN
    ALTER TABLE partner_products ADD COLUMN dokumente JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='partner_products' AND column_name='status_changed_at') THEN
    ALTER TABLE partner_products ADD COLUMN status_changed_at TIMESTAMPTZ;
  END IF;
END $$;

-- 2. Admin RLS-Policies für partner_products

-- Admins können alle Produkte sehen (über alle Seller)
DO $$ BEGIN
  CREATE POLICY "Admins can view all partner products"
    ON partner_products FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Produkte aktualisieren (Status, Featured, Reklamationen etc.)
DO $$ BEGIN
  CREATE POLICY "Admins can update all partner products"
    ON partner_products FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_partner_products_featured ON partner_products(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_partner_products_status ON partner_products(status);
