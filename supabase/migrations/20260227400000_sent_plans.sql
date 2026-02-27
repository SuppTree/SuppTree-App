-- =============================================
-- SUPPTREE - Sent Plans (Gesendete Pläne)
-- Training, Ernährung, Supplement-Empfehlungen
-- =============================================

CREATE TABLE IF NOT EXISTS sent_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id TEXT NOT NULL,
  partner_name TEXT,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_type TEXT NOT NULL,
  plan_name TEXT,
  plan_data JSONB NOT NULL,
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE sent_plans ENABLE ROW LEVEL SECURITY;

-- Kunden können eigene Pläne lesen
DO $$ BEGIN
  CREATE POLICY "Users can read own sent plans"
    ON sent_plans FOR SELECT
    USING (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Kunden können eigene Pläne als gelesen markieren
DO $$ BEGIN
  CREATE POLICY "Users can update own sent plans"
    ON sent_plans FOR UPDATE
    USING (auth.uid() = customer_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können Pläne einfügen
DO $$ BEGIN
  CREATE POLICY "Partners can insert sent plans"
    ON sent_plans FOR INSERT
    WITH CHECK (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (role = 'seller' OR role = 'admin'))
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Partner können eigene gesendete Pläne sehen
DO $$ BEGIN
  CREATE POLICY "Partners can view own sent plans"
    ON sent_plans FOR SELECT
    USING (partner_id = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Admins können alle Pläne sehen
DO $$ BEGIN
  CREATE POLICY "Admins can view all sent plans"
    ON sent_plans FOR SELECT
    USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_sent_plans_customer_id ON sent_plans(customer_id);
CREATE INDEX IF NOT EXISTS idx_sent_plans_partner_id ON sent_plans(partner_id);
CREATE INDEX IF NOT EXISTS idx_sent_plans_type ON sent_plans(plan_type);
