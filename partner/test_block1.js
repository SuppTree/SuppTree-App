
(function(){
  var p = new URLSearchParams(window.location.search);
  // ?reset=1 → alles zurücksetzen
  if (p.get('reset') === '1') {
    localStorage.clear();
    window.location.href = window.location.pathname;
    return;
  }
  // ?demo=1 → direkt in Demo-Modus
  if (p.get('demo') === '1') {
    localStorage.setItem('suppTreeAppMode', 'demo');
    localStorage.setItem('suppTreePartnerType', 'supplement');
    window.location.href = window.location.pathname;
    return;
  }
  // ?mode=production → URL-Param setzen
  if (p.get('mode') === 'production') {
    localStorage.setItem('suppTreeAppMode', 'production');
  }
  var mode = localStorage.getItem('suppTreeAppMode') || 'demo';
  // Production-Modus: Loading weg + Auth-Overlay sofort zeigen (wird nach Session-Check ggf. ausgeblendet)
  if (mode === 'production') {
    document.getElementById('authLoading').classList.add('hidden');
    var ov = document.getElementById('partnerAuthOverlay');
    if (ov) ov.classList.add('visible');
    return;
  }
  // Demo-Modus: Overlay nur wenn kein PartnerType gesetzt
  document.getElementById('authLoading').classList.add('hidden');
  if (!localStorage.getItem('suppTreePartnerType')) {
    var ov2 = document.getElementById('partnerAuthOverlay');
    if (ov2) ov2.classList.add('visible');
    var dev = document.getElementById('paDevAccess');
    if (dev) dev.style.display = 'block';
  }
})();
