-- =============================================
-- SUPPTREE - Kunden-Tabellen & Profil-Erweiterung
-- Favorites, Berater-Beziehung, Health/Personal Data
-- =============================================

-- 1. Health Profile & Personal Data als JSONB in profiles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='health_profile') THEN
    ALTER TABLE profiles ADD COLUMN health_profile JSONB;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='personal_data') THEN
    ALTER TABLE profiles ADD COLUMN personal_data JSONB;
  END IF;
END $$;

-- 2. Favorites-Tabelle
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own favorites"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);

-- 3. Berater-Beziehung
CREATE TABLE IF NOT EXISTS customer_berater (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_id TEXT NOT NULL,
  partner_name TEXT,
  partner_avatar TEXT,
  partner_role TEXT,
  partner_role_label TEXT,
  status TEXT DEFAULT 'active',
  connected_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE customer_berater ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can read own berater"
  ON customer_berater FOR SELECT
  USING (auth.uid() = customer_id);

CREATE POLICY "Customers can insert own berater"
  ON customer_berater FOR INSERT
  WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update own berater"
  ON customer_berater FOR UPDATE
  USING (auth.uid() = customer_id);

CREATE POLICY "Customers can delete own berater"
  ON customer_berater FOR DELETE
  USING (auth.uid() = customer_id);

CREATE INDEX IF NOT EXISTS idx_customer_berater_customer_id ON customer_berater(customer_id);
