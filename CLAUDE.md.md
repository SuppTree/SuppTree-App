# CLAUDE.md – SuppTree Projektübersicht

## Was ist SuppTree?
B2B/B2C Online-Marktplatz für Nahrungsergänzungsmittel in der DACH-Region.
Launch: Juli 2026. Start in Deutschland, dann Österreich & Schweiz.

## Projektstruktur

```
SuppTree/
├── www/              → Kunden-App (PWA) – Supplements kaufen
├── partner/          → Seller Dashboard – Produkte & Bestellungen verwalten
├── admin/            → Admin Panel – Marktplatz verwalten
├── shared/           → Geteilter Code (Auth, Supabase, Utils)
├── android/          → Capacitor Build für Android
├── .claude/          → Claude Code Config
├── capacitor.config  → Capacitor Konfiguration
└── package.json
```

## Tech Stack
- Frontend: Vanilla HTML/CSS/JS (kein Framework)
- PWA mit Capacitor für native Android/iOS Features
- Backend: Supabase (Auth, Database, Storage) – NOCH NICHT VERBUNDEN
- Hosting: Vercel + GitHub

## Nächster Schritt: Auth System
Supabase Auth aufsetzen mit Rollen:
- `customer` → sieht www/ (Kunden-App)
- `seller` → sieht partner/ (Seller Dashboard)  
- `admin` → sieht admin/ (Admin Panel)

Auth-Logik gehört in `shared/auth.js` damit alle Apps denselben Login nutzen.

## Wichtige Regeln

### Design
- Border Radius: 7px
- Primary Green: #2E7D32 / Accent: #66BB6A
- Mobile-First, Touch Targets min 44x44px
- Font: System Stack (-apple-system, sans-serif)

### Rechtlich (Deutschland)
- Preise IMMER inkl. MwSt. + Grundpreis pro kg/L (PAngV)
- Checkout-Button: "Zahlungspflichtig bestellen"
- DSGVO-konform, Double Opt-In für Marketing
- BFSG Barrierefreiheit: Kontrast 4.5:1, WCAG 2.1 AA
- 14 Tage Widerrufsrecht, max 2 Klicks zur Kündigung

### Sprache
- Alle UI-Texte auf Deutsch
- Code-Kommentare auf Deutsch
- Anrede: "Sie" (formell)

## Supabase (geplant)
- Projekt-URL: noch nicht eingerichtet
- Anon Key: noch nicht vorhanden
- Tabellen: users, products, orders, subscriptions, services, appointments
