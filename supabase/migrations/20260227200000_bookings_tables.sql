-- =============================================
-- SUPPTREE - Bookings & Blood Tests Tabellen
-- Termine (Appointments) + Bluttests
-- =============================================

-- 1. Bookings (Termine)
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  partner_id TEXT,
  partner_name TEXT NOT NULL,
  service TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  booking_date DATE NOT NULL,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Kunden können eigene Buchungen lesen
DO $$ BEGIN
  CREATE POLICY "Users can read own bookings"
    ON bookings FOR SELECT
    USING (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Kunden können eigene Buchungen erstellen
DO $$ BEGIN
  CREATE POLICY "Users can insert own bookings"
    ON bookings FOR INSERT
    WITH CHECK (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Buchungen sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all bookings"
    ON bookings FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Buchungen aktualisieren
DO $$ BEGIN
  CREATE POLICY "Admins can update all bookings"
    ON bookings FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Seller können Buchungen sehen bei denen sie Partner sind
DO $$ BEGIN
  CREATE POLICY "Sellers can view own partner bookings"
    ON bookings FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'seller' OR role = 'admin'))
      AND partner_id = auth.uid()::text
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_partner_id ON bookings(partner_id);

-- 2. Blood Tests (Bluttests)
CREATE TABLE IF NOT EXISTS blood_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  partner_id TEXT,
  partner_name TEXT NOT NULL,
  test_name TEXT NOT NULL,
  lab_name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  test_date DATE NOT NULL,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE blood_tests ENABLE ROW LEVEL SECURITY;

-- Kunden können eigene Bluttests lesen
DO $$ BEGIN
  CREATE POLICY "Users can read own blood tests"
    ON blood_tests FOR SELECT
    USING (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Kunden können eigene Bluttests erstellen
DO $$ BEGIN
  CREATE POLICY "Users can insert own blood tests"
    ON blood_tests FOR INSERT
    WITH CHECK (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Bluttests sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all blood tests"
    ON blood_tests FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Bluttests aktualisieren
DO $$ BEGIN
  CREATE POLICY "Admins can update all blood tests"
    ON blood_tests FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Seller können Bluttests sehen bei denen sie Partner sind
DO $$ BEGIN
  CREATE POLICY "Sellers can view own partner blood tests"
    ON blood_tests FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'seller' OR role = 'admin'))
      AND partner_id = auth.uid()::text
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_blood_tests_customer_id ON blood_tests(customer_id);
CREATE INDEX IF NOT EXISTS idx_blood_tests_status ON blood_tests(status);
CREATE INDEX IF NOT EXISTS idx_blood_tests_date ON blood_tests(test_date);
CREATE INDEX IF NOT EXISTS idx_blood_tests_partner_id ON blood_tests(partner_id);
