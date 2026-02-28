-- =============================================
-- WAITLIST: Vorab-Registrierung für Partner & Hersteller
-- =============================================

CREATE TABLE IF NOT EXISTS waitlist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('partner', 'hersteller', 'unternehmen')),
  partner_subtype TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index für schnelle Email-Suche
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_type ON waitlist(type);

-- RLS aktivieren
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Anon darf inserten (für das Formular), aber NICHT lesen/updaten/löschen
CREATE POLICY "waitlist_anon_insert" ON waitlist
  FOR INSERT TO anon
  WITH CHECK (true);

-- Admins dürfen alles lesen (für Verwaltung)
CREATE POLICY "waitlist_admin_select" ON waitlist
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users u
      WHERE u.id = auth.uid()
      AND u.raw_user_meta_data->>'role' = 'admin'
    )
  );
