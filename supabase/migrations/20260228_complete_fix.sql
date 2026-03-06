-- =============================================
-- COMPLETE FIX: RLS + Waitlist + User-Signup
-- Einmal im Supabase SQL Editor ausführen:
-- https://supabase.com/dashboard/project/evqiukaxhqmbkcnmafvo/sql/new
-- =============================================

-- =============================
-- TEIL 1: Profiles RLS Fix
-- Problem: Admin-Policy auf profiles macht SELECT auf profiles → Endlosschleife
-- Fix: JWT-Metadaten statt Subquery verwenden
-- =============================

-- Alte problematische Policies entfernen
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Neue Policies: User sieht eigenes Profil, Admin sieht alle (via JWT)
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (
    auth.uid() = id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (
    auth.uid() = id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- INSERT Policy für handle_new_user() Trigger
DROP POLICY IF EXISTS "Service can insert profiles" ON profiles;
CREATE POLICY "Service can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (true);

-- =============================
-- TEIL 2: Waitlist-Tabelle
-- =============================

CREATE TABLE IF NOT EXISTS waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('partner', 'hersteller', 'unternehmen')),
  partner_subtype TEXT,
  job_title TEXT,
  company_name TEXT,
  bio TEXT,
  profile_ready BOOLEAN DEFAULT false,
  profile_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_type ON waitlist(type);

-- RLS aktivieren
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Anon darf inserten (Registrierungsformular)
DROP POLICY IF EXISTS "waitlist_anon_insert" ON waitlist;
CREATE POLICY "waitlist_anon_insert" ON waitlist
  FOR INSERT TO anon
  WITH CHECK (true);

-- Anon darf lesen (Status-Seite Login-Check)
DROP POLICY IF EXISTS "waitlist_anon_select" ON waitlist;
CREATE POLICY "waitlist_anon_select" ON waitlist
  FOR SELECT TO anon
  USING (true);

-- Anon darf updaten (Profil-Vorbereitung auf Status-Seite)
DROP POLICY IF EXISTS "waitlist_anon_update" ON waitlist;
CREATE POLICY "waitlist_anon_update" ON waitlist
  FOR UPDATE TO anon
  USING (true)
  WITH CHECK (true);

-- Admin darf alles lesen
DROP POLICY IF EXISTS "waitlist_admin_select" ON waitlist;
CREATE POLICY "waitlist_admin_select" ON waitlist
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND u.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- =============================
-- TEIL 3: handle_new_user() Fix
-- Sicherstellen dass der Trigger korrekt existiert
-- =============================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger neu erstellen (falls er fehlt)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================
-- TEIL 4: Alle Admin-Policies in anderen Tabellen fixen
-- Statt profiles-Subquery → auth.users Subquery (kein Rekursions-Risiko)
-- =============================

-- Orders
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins can view all orders"
  ON orders FOR SELECT
  USING (
    auth.uid() = user_id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

DROP POLICY IF EXISTS "Admins can update all orders" ON orders;
CREATE POLICY "Admins can update all orders"
  ON orders FOR UPDATE
  USING (
    (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Order Items
DROP POLICY IF EXISTS "Admins can view all order items" ON order_items;
CREATE POLICY "Admins can view all order items"
  ON order_items FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Addresses
DROP POLICY IF EXISTS "Admins can view all addresses" ON addresses;
CREATE POLICY "Admins can view all addresses"
  ON addresses FOR SELECT
  USING (
    auth.uid() = user_id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Payment Methods
DROP POLICY IF EXISTS "Admins can view all payment methods" ON payment_methods;
CREATE POLICY "Admins can view all payment methods"
  ON payment_methods FOR SELECT
  USING (
    auth.uid() = user_id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Bookings (if table exists) — partner_id ist TEXT, daher ::text cast
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings';
    EXECUTE 'CREATE POLICY "Admins can view all bookings" ON bookings FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'' OR auth.uid() = customer_id OR auth.uid()::text = partner_id)';

    EXECUTE 'DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings';
    EXECUTE 'CREATE POLICY "Admins can update all bookings" ON bookings FOR UPDATE USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'')';
  END IF;
END $$;

-- Blood Tests (if table exists) — partner_id ist TEXT
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'blood_tests') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all blood tests" ON blood_tests';
    EXECUTE 'CREATE POLICY "Admins can view all blood tests" ON blood_tests FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'' OR auth.uid() = customer_id OR auth.uid()::text = partner_id)';

    EXECUTE 'DROP POLICY IF EXISTS "Admins can update all blood tests" ON blood_tests';
    EXECUTE 'CREATE POLICY "Admins can update all blood tests" ON blood_tests FOR UPDATE USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'')';
  END IF;
END $$;

-- Blood Test Results (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'blood_test_results') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all blood test results" ON blood_test_results';
    EXECUTE 'CREATE POLICY "Admins can view all blood test results" ON blood_test_results FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'' OR auth.uid() = user_id)';

    EXECUTE 'DROP POLICY IF EXISTS "Admins can update all blood test results" ON blood_test_results';
    EXECUTE 'CREATE POLICY "Admins can update all blood test results" ON blood_test_results FOR UPDATE USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'')';
  END IF;
END $$;

-- Sent Plans (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sent_plans') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all sent plans" ON sent_plans';
    EXECUTE 'CREATE POLICY "Admins can view all sent plans" ON sent_plans FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'')';
  END IF;
END $$;

-- Partner Products (seller_products, if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'seller_products') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all partner products" ON seller_products';
    EXECUTE 'CREATE POLICY "Admins can view all partner products" ON seller_products FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'' OR is_active = true)';

    EXECUTE 'DROP POLICY IF EXISTS "Admins can update all partner products" ON seller_products';
    EXECUTE 'CREATE POLICY "Admins can update all partner products" ON seller_products FOR UPDATE USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'')';
  END IF;
END $$;

-- Customer Berater (if table exists) — partner_id ist TEXT
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customer_berater') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all customer berater" ON customer_berater';
    EXECUTE 'CREATE POLICY "Admins can view all customer berater" ON customer_berater FOR SELECT USING ((auth.jwt()->''user_metadata''->>''role'') = ''admin'' OR auth.uid() = customer_id OR auth.uid()::text = partner_id)';
  END IF;
END $$;

-- =============================
-- FERTIG! Jetzt sollte User-Signup funktionieren
-- =============================
