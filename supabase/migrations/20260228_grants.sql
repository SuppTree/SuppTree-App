-- =============================================
-- GRANTS: Tabellen-Berechtigungen für anon & authenticated
-- Supabase braucht explizite GRANT-Statements
-- =============================================

-- Schema-Zugriff
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Alle bestehenden Tabellen
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

-- Auch für zukünftige Tabellen
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

-- Sequences (für auto-generated IDs)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO anon, authenticated, service_role;
