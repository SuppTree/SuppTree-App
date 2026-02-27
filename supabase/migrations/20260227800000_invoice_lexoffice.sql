-- =============================================
-- SUPPTREE - Lexoffice Invoice Integration
-- Neue Spalte für Lexoffice Invoice ID
-- =============================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='invoice_lexoffice_id') THEN
    ALTER TABLE orders ADD COLUMN invoice_lexoffice_id TEXT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_orders_lexoffice_id ON orders(invoice_lexoffice_id) WHERE invoice_lexoffice_id IS NOT NULL;
