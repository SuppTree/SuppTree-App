-- =============================================
-- SUPPTREE - Partner Writes
-- Empfehlungen + Notizen auf customer_berater
-- =============================================

-- Empfehlungen als JSONB auf customer_berater
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customer_berater' AND column_name='empfehlungen') THEN
    ALTER TABLE customer_berater ADD COLUMN empfehlungen JSONB DEFAULT '[]';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customer_berater' AND column_name='notizen') THEN
    ALTER TABLE customer_berater ADD COLUMN notizen JSONB DEFAULT '[]';
  END IF;
END $$;

-- Partner können eigene Kunden-Beziehungen aktualisieren (empfehlungen, notizen)
DO $$ BEGIN
  CREATE POLICY "Partners can update own customer relations"
    ON customer_berater FOR UPDATE
    USING (partner_id = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
