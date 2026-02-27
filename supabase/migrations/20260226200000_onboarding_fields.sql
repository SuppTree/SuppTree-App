-- =============================================
-- SUPPTREE - ONBOARDING-FELDER für profiles
-- Erweitert die profiles-Tabelle um Felder
-- die beim Partner-Onboarding erfasst werden
-- =============================================

-- Neue Spalten hinzufügen (IF NOT EXISTS via DO-Block)
DO $$
BEGIN
  -- Anzeigename (z.B. "Dr. Anna Schmidt")
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='display_name') THEN
    ALTER TABLE profiles ADD COLUMN display_name TEXT;
  END IF;

  -- Berufsbezeichnung (z.B. "Naturheilkunde", "Personal Trainer")
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='job_title') THEN
    ALTER TABLE profiles ADD COLUMN job_title TEXT;
  END IF;

  -- Firmenname / Praxis / Einrichtung
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='company_name') THEN
    ALTER TABLE profiles ADD COLUMN company_name TEXT;
  END IF;

  -- Kurzbeschreibung / Bio
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='bio') THEN
    ALTER TABLE profiles ADD COLUMN bio TEXT;
  END IF;

  -- Hauptkategorie: supplement | partner | unternehmen
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='partner_category') THEN
    ALTER TABLE profiles ADD COLUMN partner_category TEXT CHECK (partner_category IN ('supplement', 'partner', 'unternehmen'));
  END IF;

  -- Detaillierte Spezialisierung: heilpraktiker, ernaehrung, trainer, beauty, hebamme, creator, bgm, klinik, sonstiges_u
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='specialty') THEN
    ALTER TABLE profiles ADD COLUMN specialty TEXT;
  END IF;

  -- Onboarding abgeschlossen?
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='onboarding_completed_at') THEN
    ALTER TABLE profiles ADD COLUMN onboarding_completed_at TIMESTAMPTZ;
  END IF;
END $$;

-- Index für Admin-Statistiken (Abfragen nach Kategorie/Spezialisierung)
CREATE INDEX IF NOT EXISTS idx_profiles_partner_category ON profiles(partner_category) WHERE role = 'seller';
CREATE INDEX IF NOT EXISTS idx_profiles_specialty ON profiles(specialty) WHERE role = 'seller';

-- RLS: Seller darf eigene Onboarding-Felder updaten (bereits durch bestehende Policy abgedeckt)
-- profiles_update Policy: auth.uid() = id → erlaubt UPDATE auf eigene Zeile

-- handle_new_user() aktualisieren: seller_type aus Metadaten übernehmen
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role, name, seller_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    CASE
      WHEN COALESCE(NEW.raw_user_meta_data->>'role', 'customer') = 'seller'
      THEN NEW.raw_user_meta_data->>'seller_type'
      ELSE NULL
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
