-- =============================================
-- SUPPTREE - Partner-Detail-Felder für profiles
-- SellerNr, ShopName, Provision, Bereiche, Dokumente, Status
-- =============================================

-- 1. Partner-spezifische Felder
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='seller_nr') THEN
    ALTER TABLE profiles ADD COLUMN seller_nr TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='shop_name') THEN
    ALTER TABLE profiles ADD COLUMN shop_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='provision') THEN
    ALTER TABLE profiles ADD COLUMN provision JSONB;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='bereiche') THEN
    ALTER TABLE profiles ADD COLUMN bereiche JSONB;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='seller_dokumente') THEN
    ALTER TABLE profiles ADD COLUMN seller_dokumente JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='verified') THEN
    ALTER TABLE profiles ADD COLUMN verified BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='seller_status') THEN
    ALTER TABLE profiles ADD COLUMN seller_status TEXT;
  END IF;
END $$;

-- 2. Index
CREATE INDEX IF NOT EXISTS idx_profiles_seller_status ON profiles(seller_status) WHERE seller_status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_verified ON profiles(verified) WHERE verified = true;
