// =============================================
// SUPPTREE - GLOBALE KONFIGURATION
// Diese Datei wird von App, Partner & Admin genutzt
// =============================================

const SUPPTREE_CONFIG = {
  // Supabase
  SUPABASE_URL: 'https://evqiukaxhqmbkcnmafvo.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2cWl1a2F4aHFtYmtjbm1hZnZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MjU4MzEsImV4cCI6MjA4NDAwMTgzMX0.oyblk3zrZoEGnLUT55nepEz6DZt-O3hB5jEwqunuf1c',

  // App-Version
  VERSION: '1.0.0',
  BUILD_DATE: '2026-02-20',

  // Rollen
  ROLES: {
    CUSTOMER: 'customer',
    SELLER: 'seller',
    ADMIN: 'admin'
  },

  // Partner-Typen
  PARTNER_TYPES: {
    HEILPRAKTIKER: 'heilpraktiker',
    FITNESS_TRAINER: 'fitness_trainer',
    ERNAEHRUNGSBERATER: 'ernaehrungsberater',
    MARKE: 'marke',
    APOTHEKE: 'apotheke',
    SONSTIGE: 'sonstige'
  },

  // Provisions-Sätze (%)
  COMMISSION_RATES: {
    STANDARD: 10,
    PREMIUM: 15,
    ELITE: 20
  },

  // Payment (Test-Keys — vor Go-Live durch Live-Keys ersetzen!)
  STRIPE_PK: 'pk_test_DEIN_STRIPE_KEY_HIER',
  PAYPAL_CLIENT_ID: 'DEIN_PAYPAL_CLIENT_ID_HIER',
  PAYMENT_MODE: 'test', // 'test' oder 'live'

  // API Endpoints
  API: {
    BASE_URL: '/api',
    PRODUCTS: '/api/products',
    ORDERS: '/api/orders',
    PARTNERS: '/api/partners'
  }
};
