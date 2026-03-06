-- =============================================
-- Admin-Rolle für Florian Eichkorn setzen
-- Im Supabase SQL Editor ausführen:
-- https://supabase.com/dashboard/project/evqiukaxhqmbkcnmafvo/sql/new
-- =============================================

-- 1. Profil-Tabelle: role auf 'admin' setzen
UPDATE profiles
SET role = 'admin'
WHERE email = 'feichkorn@supptree.de';

-- 2. Auth user_metadata: role auf 'admin' setzen
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'::jsonb
WHERE email = 'feichkorn@supptree.de';

-- Prüfen ob es geklappt hat:
SELECT id, email, role FROM profiles WHERE email = 'feichkorn@supptree.de';
