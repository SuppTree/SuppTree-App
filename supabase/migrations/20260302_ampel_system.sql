-- ============================================
-- Ampelsystem: Medikament-Supplement Wechselwirkungen
-- Migration: 2026-03-02
-- ============================================

-- my_supplements erweitern
ALTER TABLE my_supplements ADD COLUMN IF NOT EXISTS wirkstoff_id TEXT;
ALTER TABLE my_supplements ADD COLUMN IF NOT EXISTS ampel_status TEXT DEFAULT 'gruen';
ALTER TABLE my_supplements ADD COLUMN IF NOT EXISTS ampel_overridden BOOLEAN DEFAULT FALSE;
ALTER TABLE my_supplements ADD COLUMN IF NOT EXISTS ampel_disclaimer_ts TIMESTAMPTZ;
ALTER TABLE my_supplements ADD COLUMN IF NOT EXISTS manual_time_slot TEXT;

-- my_medications erweitern
ALTER TABLE my_medications ADD COLUMN IF NOT EXISTS gruppe_id TEXT;

-- Index fuer schnelle Ampel-Lookups
CREATE INDEX IF NOT EXISTS idx_my_supplements_ampel ON my_supplements(user_id, ampel_status);
CREATE INDEX IF NOT EXISTS idx_my_medications_gruppe ON my_medications(user_id, gruppe_id);
