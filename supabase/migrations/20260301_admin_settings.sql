-- =============================================
-- ADMIN SETTINGS TABLE
-- Plattform-Einstellungen persistent in Supabase
-- =============================================

CREATE TABLE IF NOT EXISTS admin_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Index für schnelle Lookups
CREATE INDEX IF NOT EXISTS idx_admin_settings_key ON admin_settings(key);

-- RLS aktivieren
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Nur Admins dürfen lesen
CREATE POLICY "Admins can read settings"
  ON admin_settings FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Nur Admins dürfen schreiben (insert/update)
CREATE POLICY "Admins can upsert settings"
  ON admin_settings FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update settings"
  ON admin_settings FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_admin_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER admin_settings_updated
  BEFORE UPDATE ON admin_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_admin_settings_timestamp();

-- Default-Einträge
INSERT INTO admin_settings (key, value) VALUES
  ('platform', '{"platformName":"SuppTree","supportEmail":"support@supptree.de","maintenance":"Aus"}'),
  ('provision', '{"produktMarge":25,"partnerQR":10,"partnerLink":7,"terminFee":10,"bluttestPartner":25,"minAuszahlung":50,"cookieTage":30,"provisionTage":210}'),
  ('nummern', '{"vorlagen":{"kunde":{"prefix":"91-{LAND}-","suffix":"","pad":5},"bestellung":{"prefix":"{LAND}-","suffix":"","pad":4},"rechnung":{"prefix":"95-{JAHR}-","suffix":"-{LAND}","pad":4},"gutschrift":{"prefix":"99-{JAHR}-","suffix":"-{LAND}","pad":4}},"sequenzen":{"DE":{"kunde":10001,"bestellung":1001,"rechnung":1,"gutschrift":1},"AT":{"kunde":10001,"bestellung":1001,"rechnung":1,"gutschrift":1},"CH":{"kunde":10001,"bestellung":1001,"rechnung":1,"gutschrift":1},"NL":{"kunde":10001,"bestellung":1001,"rechnung":1,"gutschrift":1},"LU":{"kunde":10001,"bestellung":1001,"rechnung":1,"gutschrift":1}}}'),
  ('partner_codes', '{"laender":{"DE":{"nr":"49","label":"Deutschland"},"AT":{"nr":"43","label":"Österreich"},"CH":{"nr":"41","label":"Schweiz"},"NL":{"nr":"31","label":"Niederlande"},"LU":{"nr":"35","label":"Luxemburg"}},"typen":{"partner":{"nr":"01","label":"Partner"},"hersteller":{"nr":"02","label":"Hersteller"},"unternehmen":{"nr":"03","label":"Unternehmen"},"bgm":{"nr":"04","label":"BGM"}},"laufend":{},"pad":5}')
ON CONFLICT (key) DO NOTHING;

-- Seller dürfen partner_codes lesen (für QR-Code Generierung)
CREATE POLICY "Sellers can read partner_codes"
  ON admin_settings FOR SELECT
  USING (
    key = 'partner_codes' AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'seller')
  );

-- Seller dürfen partner_codes aktualisieren (laufende Nummer hochzählen)
CREATE POLICY "Sellers can update partner_codes"
  ON admin_settings FOR UPDATE
  USING (
    key = 'partner_codes' AND
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'seller')
  );

-- Grant für anon/authenticated
GRANT SELECT, INSERT, UPDATE ON admin_settings TO authenticated;
