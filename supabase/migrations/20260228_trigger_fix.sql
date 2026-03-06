-- =============================================
-- TRIGGER FIX: handle_new_user() mit korrektem search_path
-- =============================================

-- 1. Funktion neu erstellen mit SET search_path
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'name', '')
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Falls INSERT fehlschlägt, trotzdem User erstellen (Profil kann später erstellt werden)
  RAISE LOG 'handle_new_user failed: % %', SQLERRM, SQLSTATE;
  RETURN NEW;
END;
$$;

-- 2. Trigger sicherstellen
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Sicherheitshalber: Grant INSERT auf profiles für alle relevanten Rollen
GRANT INSERT ON public.profiles TO postgres, service_role, supabase_auth_admin;
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO supabase_auth_admin;
