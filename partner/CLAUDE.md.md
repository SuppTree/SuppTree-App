# CLAUDE.md – Partner Dashboard Kontext

## Was ist das?
Seller Dashboard für den SuppTree Supplement-Marktplatz (DACH-Region).
Verkäufer verwalten hier: Produkte, Bestellungen, Termine, Services, Affiliate, Finanzen.

## Tech Stack
- Vanilla HTML/CSS/JS (kein Framework)
- Keine Build-Tools nötig – Live Server reicht
- Mock-Daten in index.html (Arrays: products, services, anfragen, orders, etc.)
- Quagga.js für Barcode-Scanning (CDN)

## Design System
- Primary: --green-dark: #2E7D32, --green-accent: #66BB6A
- Border Radius: 7px (--r: 7px)
- Font: System Font Stack (-apple-system, sans-serif)
- Mobile-First, Bottom Navigation (5 Items)
- Touch Targets: min 44x44px

## Wichtige Konventionen
- Sprache: Deutsch (UI-Texte, Kommentare)
- Anrede: "Sie" für formelle Kontexte
- Preise: Immer inkl. MwSt. + Grundpreis pro kg/L (PAngV)
- Checkout-Button: "Zahlungspflichtig bestellen" (rechtlich vorgeschrieben)
- BFSG Barrierefreiheit: Kontrast 4.5:1, Touch 44x44px, prefers-reduced-motion

## Navigation
showScreen('screenId') wechselt zwischen Screens.
Screens: dashboard, products, productDetail, anfragen, chatScreen, 
         services, affiliate, orders, orderDetail, finanzen, mehr, 
         settings (diverse Sub-Screens)

## Geplante Integration
- Backend: Supabase (noch nicht verbunden)
- Auth: shared/auth.js (noch nicht integriert)
- Kunden-App: www/ Ordner
- Admin: admin/ Ordner
