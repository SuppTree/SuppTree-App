-- =============================================
-- SUPPTREE - Bluttest-Ergebnisse (Laborwerte)
-- Standardisierte Marker mit Referenzbereichen
-- =============================================

CREATE TABLE IF NOT EXISTS blood_test_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blood_test_id UUID REFERENCES blood_tests(id) ON DELETE CASCADE,
  marker_key TEXT NOT NULL,
  marker_name TEXT NOT NULL,
  value NUMERIC(10,3) NOT NULL,
  unit TEXT NOT NULL,
  ref_min NUMERIC(10,3),
  ref_max NUMERIC(10,3),
  status TEXT DEFAULT 'normal',
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE blood_test_results ENABLE ROW LEVEL SECURITY;

-- Kunden können eigene Ergebnisse lesen (über blood_tests JOIN)
DO $$ BEGIN
  CREATE POLICY "Users can read own blood test results"
    ON blood_test_results FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM blood_tests
        WHERE blood_tests.id = blood_test_results.blood_test_id
        AND blood_tests.customer_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können Ergebnisse für eigene Bluttests lesen
DO $$ BEGIN
  CREATE POLICY "Sellers can read own partner blood test results"
    ON blood_test_results FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM blood_tests
        WHERE blood_tests.id = blood_test_results.blood_test_id
        AND blood_tests.partner_id = auth.uid()::text
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können Ergebnisse für eigene Bluttests eintragen
DO $$ BEGIN
  CREATE POLICY "Sellers can insert blood test results"
    ON blood_test_results FOR INSERT
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM blood_tests
        WHERE blood_tests.id = blood_test_results.blood_test_id
        AND blood_tests.partner_id = auth.uid()::text
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können eigene Ergebnisse aktualisieren
DO $$ BEGIN
  CREATE POLICY "Sellers can update own blood test results"
    ON blood_test_results FOR UPDATE
    USING (
      EXISTS (
        SELECT 1 FROM blood_tests
        WHERE blood_tests.id = blood_test_results.blood_test_id
        AND blood_tests.partner_id = auth.uid()::text
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können eigene Ergebnisse löschen (für Re-Upload)
DO $$ BEGIN
  CREATE POLICY "Sellers can delete own blood test results"
    ON blood_test_results FOR DELETE
    USING (
      EXISTS (
        SELECT 1 FROM blood_tests
        WHERE blood_tests.id = blood_test_results.blood_test_id
        AND blood_tests.partner_id = auth.uid()::text
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alles sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all blood test results"
    ON blood_test_results FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alles aktualisieren
DO $$ BEGIN
  CREATE POLICY "Admins can update all blood test results"
    ON blood_test_results FOR UPDATE
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_btr_blood_test_id ON blood_test_results(blood_test_id);
CREATE INDEX IF NOT EXISTS idx_btr_marker_key ON blood_test_results(marker_key);
CREATE INDEX IF NOT EXISTS idx_btr_category ON blood_test_results(category);
