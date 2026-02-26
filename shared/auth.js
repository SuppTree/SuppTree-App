// =============================================
// SUPPTREE - AUTHENTIFIZIERUNG
// Login, Logout, Register für alle Bereiche
// =============================================

// Einloggen
async function loginUser(email, password) {
  const sb = initSupabase();
  if (!sb) return { error: 'Supabase nicht verfügbar' };

  const { data, error } = await sb.auth.signInWithPassword({
    email: email,
    password: password
  });

  if (error) {
    console.error('Login fehlgeschlagen:', error.message);
    return { error: translateAuthError(error.message) };
  }

  console.log('✅ Login erfolgreich:', data.user.email);
  return { user: data.user, session: data.session };
}

// Registrierung mit Rolle
async function registerUser(email, password, role = 'customer', userData = {}) {
  const sb = initSupabase();
  if (!sb) return { error: 'Supabase nicht verfügbar' };

  // Validierung
  if (!email || !password) {
    return { error: 'E-Mail und Passwort sind erforderlich' };
  }

  if (password.length < 6) {
    return { error: 'Passwort muss mindestens 6 Zeichen lang sein' };
  }

  // Erlaubte Rollen prüfen
  const allowedRoles = ['customer', 'seller', 'admin'];
  if (!allowedRoles.includes(role)) {
    return { error: 'Ungültige Rolle' };
  }

  // User in Supabase Auth registrieren
  const { data, error } = await sb.auth.signUp({
    email: email,
    password: password,
    options: {
      data: {
        role: role,
        ...userData
      }
    }
  });

  if (error) {
    console.error('Registrierung fehlgeschlagen:', error.message);
    return { error: translateAuthError(error.message) };
  }

  // Profil wird automatisch vom DB-Trigger handle_new_user() erstellt
  console.log('✅ Registrierung erfolgreich:', data.user?.email);
  return { user: data.user, session: data.session };
}

// Ausloggen
async function logoutUser() {
  const sb = initSupabase();
  if (!sb) return;

  await sb.auth.signOut();
  console.log('✅ Ausgeloggt');
}

// Passwort zurücksetzen
async function resetPassword(email) {
  const sb = initSupabase();
  if (!sb) return { error: 'Supabase nicht verfügbar' };

  const { error } = await sb.auth.resetPasswordForEmail(email, {
    redirectTo: window.location.origin + '/www/login.html?reset=true'
  });

  if (error) {
    return { error: translateAuthError(error.message) };
  }

  return { success: true };
}

// Auth-Status überwachen (bei Seitenwechsel etc.)
function onAuthStateChange(callback) {
  const sb = initSupabase();
  if (!sb) return;

  sb.auth.onAuthStateChange((event, session) => {
    console.log('🔑 Auth Event:', event);
    callback(event, session);
  });
}

// Session prüfen (beim Laden jeder Seite)
async function checkSession() {
  const sb = initSupabase();
  if (!sb) return null;

  const { data: { session } } = await sb.auth.getSession();
  return session;
}

// Aktuelle Benutzerrolle abrufen
async function getCurrentUserRole() {
  const user = await getCurrentUser();
  if (!user) return null;

  // Erst aus user_metadata versuchen (schneller)
  if (user.user_metadata?.role) {
    return user.user_metadata.role;
  }

  // Dann aus der profiles-Tabelle
  return await getUserRole(user.id);
}

// Prüft ob User die benötigte Rolle hat
async function hasRole(requiredRole) {
  const role = await getCurrentUserRole();
  if (!role) return false;

  // Admin hat immer Zugriff
  if (role === SUPPTREE_CONFIG.ROLES.ADMIN) return true;

  return role === requiredRole;
}

// Seller-spezifische Prüfung
async function isSellerOrAdmin() {
  const role = await getCurrentUserRole();
  if (!role) return false;

  return role === SUPPTREE_CONFIG.ROLES.SELLER ||
         role === SUPPTREE_CONFIG.ROLES.ADMIN;
}

// Auth-Schutz für Seiten - Redirect wenn nicht autorisiert
async function requireAuth(requiredRole = null, redirectUrl = '/www/login.html') {
  const session = await checkSession();

  if (!session) {
    console.log('⛔ Nicht eingeloggt - Weiterleitung zu Login');
    window.location.href = redirectUrl;
    return false;
  }

  if (requiredRole) {
    const hasRequiredRole = await hasRole(requiredRole);
    if (!hasRequiredRole) {
      console.log('⛔ Keine Berechtigung - Rolle:', await getCurrentUserRole());
      window.location.href = redirectUrl + '?error=unauthorized';
      return false;
    }
  }

  return true;
}

// Fehlermeldungen übersetzen
function translateAuthError(message) {
  const translations = {
    'Invalid login credentials': 'Ungültige Anmeldedaten',
    'Email not confirmed': 'E-Mail noch nicht bestätigt',
    'User already registered': 'Diese E-Mail ist bereits registriert',
    'Password should be at least 6 characters': 'Passwort muss mindestens 6 Zeichen haben',
    'Unable to validate email address: invalid format': 'Ungültiges E-Mail-Format',
    'Email rate limit exceeded': 'Zu viele Versuche. Bitte später erneut versuchen.',
    'Invalid email or password': 'Ungültige E-Mail oder Passwort'
  };

  return translations[message] || message;
}

// User-Daten aktualisieren
async function updateUserProfile(updates) {
  const sb = initSupabase();
  if (!sb) return { error: 'Supabase nicht verfügbar' };

  const user = await getCurrentUser();
  if (!user) return { error: 'Nicht eingeloggt' };

  const { error } = await sb
    .from('profiles')
    .update(updates)
    .eq('id', user.id);

  if (error) {
    return { error: error.message };
  }

  return { success: true };
}
