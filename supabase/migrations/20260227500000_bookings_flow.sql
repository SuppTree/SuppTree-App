-- =============================================
-- SUPPTREE - Bookings Flow
-- Neue Spalten für Anfrage → Vorschlag → Bestätigung
-- =============================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='customer_message') THEN
    ALTER TABLE bookings ADD COLUMN customer_message TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='mode') THEN
    ALTER TABLE bookings ADD COLUMN mode TEXT DEFAULT 'praxis';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='duration') THEN
    ALTER TABLE bookings ADD COLUMN duration INTEGER;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='termin_vorschlag') THEN
    ALTER TABLE bookings ADD COLUMN termin_vorschlag JSONB;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='zahlung') THEN
    ALTER TABLE bookings ADD COLUMN zahlung JSONB;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bookings' AND column_name='storno') THEN
    ALTER TABLE bookings ADD COLUMN storno JSONB;
  END IF;
END $$;

-- Partner können Buchungen aktualisieren (Terminvorschlag senden)
DO $$ BEGIN
  CREATE POLICY "Partners can update own bookings"
    ON bookings FOR UPDATE
    USING (partner_id = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
