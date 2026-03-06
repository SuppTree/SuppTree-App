-- =============================================
-- FIX: Infinite Recursion in profiles RLS
-- Problem: Admin-Policy liest aus profiles um zu prüfen ob User admin ist
--          → Endlosschleife weil profiles selbst geprüft wird
-- Fix: JWT-Metadaten statt Subquery verwenden
-- =============================================

-- Alte Admin-Policies entfernen (die die Rekursion verursachen)
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- Neue Admin-Policies: JWT-Metadaten statt profiles-Subquery
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (
    auth.uid() = id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Alte User-Policy entfernen (wird durch die neue Admin-Policy mit abgedeckt)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Admin kann alle Profile updaten
CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING (
    auth.uid() = id
    OR (auth.jwt()->'user_metadata'->>'role') = 'admin'
  );

-- Alte User-Update-Policy entfernen (wird durch die neue abgedeckt)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- INSERT Policy für handle_new_user() Trigger (SECURITY DEFINER, braucht trotzdem Policy)
CREATE POLICY "Service can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (true);
