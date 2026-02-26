// =============================================
// SUPPTREE - SUPABASE VERBINDUNG
// Wird von App, Partner & Admin genutzt
// =============================================

let supabaseClient = null;

// Supabase initialisieren
function initSupabase() {
  if (supabaseClient) return supabaseClient;

  if (typeof supabase === 'undefined') {
    console.warn('⚠️ Supabase SDK nicht geladen');
    return null;
  }

  supabaseClient = supabase.createClient(
    SUPPTREE_CONFIG.SUPABASE_URL,
    SUPPTREE_CONFIG.SUPABASE_ANON_KEY
  );

  console.log('✅ Supabase verbunden');
  return supabaseClient;
}

// Aktuellen User holen
async function getCurrentUser() {
  const sb = initSupabase();
  if (!sb) return null;

  const { data: { user } } = await sb.auth.getUser();
  return user;
}

// User-Rolle prüfen
async function getUserRole(userId) {
  const sb = initSupabase();
  if (!sb) return null;

  const { data, error } = await sb
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Fehler beim Laden der Rolle:', error);
    return null;
  }

  return data?.role;
}

// Zugriffskontrolle - prüft ob User die richtige Rolle hat
async function checkAccess(requiredRole) {
  const user = await getCurrentUser();

  if (!user) {
    // Nicht eingeloggt → zum Login
    window.location.href = '/www/login.html';
    return false;
  }

  const role = await getUserRole(user.id);

  if (role !== requiredRole && role !== SUPPTREE_CONFIG.ROLES.ADMIN) {
    // Admin hat immer Zugriff, andere brauchen die richtige Rolle
    console.warn('⛔ Kein Zugriff. Rolle:', role, 'Benötigt:', requiredRole);
    window.location.href = '/www/index.html';
    return false;
  }

  return true;
}
