// =============================================
// SUPPTREE ADMIN-PANEL - JAVASCRIPT
// =============================================

// ===== INITIALISIERUNG =====
document.addEventListener('DOMContentLoaded', async function() {
  console.log('🌳 SuppTree Admin-Panel geladen');

  const session = await checkSession();

  if (session) {
    // Prüfe ob User Admin ist
    const role = await getUserRole(session.user.id);
    if (role !== SUPPTREE_CONFIG.ROLES.ADMIN) {
      alert('Kein Admin-Zugang!');
      await logoutUser();
      return;
    }
    await loadAdminDashboard();
  } else {
    showScreen('loginScreen');
  }
});

// ===== SCREEN MANAGEMENT =====
function showScreen(screenId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const screen = document.getElementById(screenId);
  if (screen) screen.classList.add('active');
}

function showSection(sectionId) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  const section = document.getElementById('section-' + sectionId);
  if (section) section.classList.add('active');

  document.querySelectorAll('.menu-item').forEach(m => m.classList.remove('active'));
  event.target.closest('.menu-item')?.classList.add('active');
}

// ===== LOGIN =====
async function handleAdminLogin() {
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
    errorEl.textContent = 'Anmeldung fehlgeschlagen.';
    errorEl.style.display = 'block';
    return;
  }

  // Nur Admins erlaubt
  const role = await getUserRole(result.user.id);
  if (role !== SUPPTREE_CONFIG.ROLES.ADMIN) {
    errorEl.textContent = 'Kein Admin-Zugang für dieses Konto.';
    errorEl.style.display = 'block';
    await logoutUser();
    return;
  }

  await loadAdminDashboard();
}

// ===== DASHBOARD =====
async function loadAdminDashboard() {
  showScreen('dashboardScreen');

  // TODO: Echte Daten aus Supabase laden
  // await loadUserCount();
  // await loadPartnerCount();
  // await loadProductCount();
  // await loadRevenueStats();

  console.log('✅ Admin-Dashboard geladen');
}

// ===== DATEN LADEN (TODO: Supabase anbinden) =====

async function loadUserCount() {
  // const sb = initSupabase();
  // const { count } = await sb.from('users').select('*', { count: 'exact', head: true });
  // document.getElementById('totalUsers').textContent = count || 0;
}

async function loadPartnerCount() {
  // const sb = initSupabase();
  // const { count } = await sb.from('users').select('*', { count: 'exact', head: true }).eq('role', 'partner');
  // document.getElementById('totalPartners').textContent = count || 0;
}

async function loadProductCount() {
  // const sb = initSupabase();
  // const { count } = await sb.from('products').select('*', { count: 'exact', head: true });
  // document.getElementById('totalProducts').textContent = count || 0;
}

async function loadRevenueStats() {
  // const sb = initSupabase();
  // const { data } = await sb.from('orders').select('total').gte('created_at', startOfMonth);
  // const total = data?.reduce((sum, o) => sum + o.total, 0) || 0;
  // document.getElementById('totalRevenue').textContent = '€' + total.toFixed(2);
}
