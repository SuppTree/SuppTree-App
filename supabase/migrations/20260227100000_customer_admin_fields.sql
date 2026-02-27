-- =============================================
-- SUPPTREE - Customer Admin Fields
-- Status, Notes, Consent, DSGVO, Kunden-Nr
-- =============================================

-- 1. Customer-Admin-Felder auf profiles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='customer_status') THEN
    ALTER TABLE profiles ADD COLUMN customer_status TEXT DEFAULT 'active';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='admin_notes') THEN
    ALTER TABLE profiles ADD COLUMN admin_notes TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='consent') THEN
    ALTER TABLE profiles ADD COLUMN consent JSONB DEFAULT '{}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='dsgvo') THEN
    ALTER TABLE profiles ADD COLUMN dsgvo JSONB DEFAULT '{}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='customer_nr') THEN
    ALTER TABLE profiles ADD COLUMN customer_nr TEXT;
  END IF;
END $$;

-- 2. Channel-Spalte auf customer_berater
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customer_berater' AND column_name='channel') THEN
    ALTER TABLE customer_berater ADD COLUMN channel TEXT;
  END IF;
END $$;

-- 3. Admin-RLS-Policies

-- Admins können alle Profile sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Profile aktualisieren
DO $$ BEGIN
  CREATE POLICY "Admins can update all profiles"
    ON profiles FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Adressen sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all addresses"
    ON addresses FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Zahlungsmethoden sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all payment methods"
    ON payment_methods FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Berater-Zuordnungen sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all customer berater"
    ON customer_berater FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_customer_status ON profiles(customer_status) WHERE role = 'customer';
CREATE INDEX IF NOT EXISTS idx_profiles_customer_nr ON profiles(customer_nr) WHERE customer_nr IS NOT NULL;
