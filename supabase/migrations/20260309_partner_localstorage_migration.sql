-- =============================================
-- Partner localStorage → Supabase Migration
-- Migriert: welcome_state, onboarding_stats
-- =============================================

-- Welcome-Steps & Dismissed Status (Onboarding-Fortschritt)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='welcome_state') THEN
    ALTER TABLE profiles ADD COLUMN welcome_state JSONB DEFAULT '{}';
  END IF;
END $$;

-- Onboarding-Statistiken (Tracking)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='onboarding_stats') THEN
    ALTER TABLE profiles ADD COLUMN onboarding_stats JSONB DEFAULT '{}';
  END IF;
END $$;
