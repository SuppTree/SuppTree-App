// =============================================
// SUPPTREE PARTNER-DASHBOARD - JAVASCRIPT
// =============================================

// ===== APP STATE =====
let currentPartner = null;
let currentSection = 'overview';

// ===== INITIALISIERUNG =====
document.addEventListener('DOMContentLoaded', async function() {
  console.log('🌳 SuppTree Partner-Dashboard geladen');

  // Prüfe ob User eingeloggt ist
  const session = await checkSession();

  if (session) {
    // Eingeloggt → Dashboard zeigen
    await loadDashboard(session.user);
  } else {
    // Nicht eingeloggt → Login zeigen
    showScreen('loginScreen');
  }

  // Datum anzeigen
  const today = new Date();
  const options = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' };
  const dateEl = document.getElementById('dashboardDate');
  if (dateEl) {
    dateEl.textContent = today.toLocaleDateString('de-DE', options);
  }
});

// ===== SCREEN MANAGEMENT =====
function showScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const screen = document.getElementById(screenId);
  if (screen) screen.classList.add('active');
}

function showSection(sectionId) {
  // Sections umschalten
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  const section = document.getElementById('section-' + sectionId);
  if (section) section.classList.add('active');

  // Menü-Item aktiv setzen
  document.querySelectorAll('.menu-item').forEach(m => m.classList.remove('active'));
  event.target.closest('.menu-item')?.classList.add('active');

  currentSection = sectionId;
}

// ===== LOGIN =====
async function handlePartnerLogin() {
  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;
  const errorEl = document.getElementById('loginError');

  if (!email || !password) {
    errorEl.textContent = 'Bitte E-Mail und Passwort eingeben.';
    errorEl.style.display = 'block';
    return;
  }

  const result = await loginUser(email, password);

  if (result.error) {
    errorEl.textContent = 'Anmeldung fehlgeschlagen. Bitte prüfen Sie Ihre Zugangsdaten.';
    errorEl.style.display = 'block';
    return;
  }

  // Rolle prüfen
  const role = await getUserRole(result.user.id);
  if (role !== SUPPTREE_CONFIG.ROLES.PARTNER && role !== SUPPTREE_CONFIG.ROLES.ADMIN) {
    errorEl.textContent = 'Dieses Konto hat keinen Partner-Zugang.';
    errorEl.style.display = 'block';
    await logoutUser();
    return;
  }

  await loadDashboard(result.user);
}

async function handlePasswordReset() {
  const email = document.getElementById('loginEmail').value;
  if (!email) {
    alert('Bitte geben Sie Ihre E-Mail-Adresse ein.');
    return;
  }
  await resetPassword(email);
  alert('Falls ein Konto mit dieser E-Mail existiert, erhalten Sie einen Link zum Zurücksetzen.');
}

// ===== DASHBOARD LADEN =====
async function loadDashboard(user) {
  showScreen('dashboardScreen');

  // Partner-Info in Sidebar setzen
  const nameEl = document.getElementById('partnerName');
  const typeEl = document.getElementById('partnerType');
  const avatarEl = document.getElementById('partnerAvatar');

  if (nameEl) nameEl.textContent = user.email?.split('@')[0] || 'Partner';
  if (avatarEl) {
    const initials = (user.email || 'P').substring(0, 2).toUpperCase();
    avatarEl.textContent = initials;
  }

  // TODO: Partner-Daten aus Supabase laden
  // await loadPartnerStats();
  // await loadRecentActivity();
  // await loadClients();

  console.log('✅ Dashboard geladen für:', user.email);
}

// ===== STATISTIKEN LADEN =====
async function loadPartnerStats() {
  // TODO: Aus Supabase laden
  // const sb = initSupabase();
  // const { data } = await sb.from('partner_stats').select('*').eq('partner_id', currentPartner.id);

  // Platzhalter
  document.getElementById('statClients').textContent = '0';
  document.getElementById('statOrders').textContent = '0';
  document.getElementById('statEarnings').textContent = '€0';
  document.getElementById('statConversion').textContent = '0%';
}

// ===== KLIENTEN =====
async function loadClients() {
  // TODO: Aus Supabase laden
  console.log('📋 Klienten laden...');
}

function inviteClient() {
  // TODO: Einladungs-Dialog öffnen
  alert('Klienten-Einladung kommt in Phase 2!');
}

// ===== PRODUKTE =====
function addProduct() {
  // TODO: Produkt-Dialog öffnen
  alert('Produkte hinzufügen kommt in Phase 2!');
}

// ===== PLÄNE =====
function createPlan(kundeId) {
  if(typeof openTpBuilder === 'function') {
    openTpBuilder(kundeId || null);
  }
}

// ===== EINSTELLUNGEN =====
async function saveSettings() {
  // TODO: In Supabase speichern
  alert('Einstellungen gespeichert! (Demo)');
}
