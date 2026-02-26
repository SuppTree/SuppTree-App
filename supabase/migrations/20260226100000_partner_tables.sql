-- =============================================
-- SUPPTREE PARTNER-TABELLEN
-- Migration: Partner-spezifische Daten
-- =============================================

-- ============================================
-- 1. PARTNER PRODUKTE
-- ============================================
CREATE TABLE IF NOT EXISTS partner_products (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL, -- lokale ID aus der App
  name TEXT NOT NULL,
  wirkstoff TEXT,
  description TEXT,
  sku TEXT,
  ean TEXT,
  category TEXT,
  icon TEXT DEFAULT '📦',
  images JSONB DEFAULT '[]',
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  content INTEGER DEFAULT 0,
  unit TEXT DEFAULT 'Kapseln',
  weight INTEGER DEFAULT 0,
  stock INTEGER DEFAULT 0,
  flavor TEXT,
  vat TEXT DEFAULT '7',
  storage TEXT,
  origin TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','draft','paused','out')),
  labels JSONB DEFAULT '[]',
  zielgruppen JSONB DEFAULT '[]',
  wirkungsbereiche JSONB DEFAULT '[]',
  allergens JSONB DEFAULT '[]',
  naehrwerte JSONB DEFAULT '{}',
  manufacturer TEXT,
  manu_data JSONB DEFAULT '{}',
  pflichthinweise JSONB DEFAULT '[]',
  ingredients TEXT,
  zutaten JSONB DEFAULT '[]',
  dosage TEXT,
  warnings TEXT,
  discount JSONB,
  sales INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  views INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, product_id)
);

CREATE INDEX idx_partner_products_user ON partner_products(user_id);
CREATE INDEX idx_partner_products_status ON partner_products(user_id, status);

-- ============================================
-- 2. PARTNER SERVICES (Dienstleistungen)
-- ============================================
CREATE TABLE IF NOT EXISTS partner_services (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_id BIGINT NOT NULL, -- lokale ID aus der App
  category TEXT,
  name TEXT NOT NULL,
  description TEXT,
  duration INTEGER DEFAULT 60,
  price_type TEXT DEFAULT 'fixed' CHECK (price_type IN ('fixed','from','request')),
  price DECIMAL(10,2) DEFAULT 0,
  modes JSONB DEFAULT '[]',
  booking_type TEXT DEFAULT 'direct',
  includes JSONB DEFAULT '[]',
  paket_items JSONB DEFAULT '[]',
  prep TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','draft','paused')),
  bookings INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, service_id)
);

CREATE INDEX idx_partner_services_user ON partner_services(user_id);

-- ============================================
-- 3. PARTNER DOKUMENTE
-- ============================================
CREATE TABLE IF NOT EXISTS partner_docs (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL,
  file_name TEXT,
  file_data TEXT, -- Base64
  status TEXT DEFAULT 'uploaded',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_partner_docs_user ON partner_docs(user_id);

-- ============================================
-- 4. PARTNER BLUTTESTS (Auswahl & Preise)
-- ============================================
CREATE TABLE IF NOT EXISTS partner_bluttests (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================
-- 5. TEAM MEMBERS
-- ============================================
CREATE TABLE IF NOT EXISTS team_members (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  role TEXT DEFAULT 'mitarbeiter',
  status TEXT DEFAULT 'active',
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_team_members_user ON team_members(user_id);

-- ============================================
-- 6. RECHTLICHE DOKUMENTE
-- ============================================
CREATE TABLE IF NOT EXISTS recht_docs (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================
-- 7. BRAND PROFILES (Markenprofil / Mein Shop)
-- ============================================
CREATE TABLE IF NOT EXISTS brand_profiles (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================
-- 8. PARTNER DASHBOARD CONFIG
-- ============================================
CREATE TABLE IF NOT EXISTS partner_dash_config (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  config JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================
-- 9. COMMUNITY RECIPES
-- ============================================
CREATE TABLE IF NOT EXISTS community_recipes (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  data JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_community_recipes_user ON community_recipes(user_id);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Partner Products
ALTER TABLE partner_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own products" ON partner_products FOR ALL USING (auth.uid() = user_id);

-- Partner Services
ALTER TABLE partner_services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own services" ON partner_services FOR ALL USING (auth.uid() = user_id);

-- Partner Docs
ALTER TABLE partner_docs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own docs" ON partner_docs FOR ALL USING (auth.uid() = user_id);

-- Partner Bluttests
ALTER TABLE partner_bluttests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own bluttests" ON partner_bluttests FOR ALL USING (auth.uid() = user_id);

-- Team Members
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own team" ON team_members FOR ALL USING (auth.uid() = user_id);

-- Recht Docs
ALTER TABLE recht_docs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own recht docs" ON recht_docs FOR ALL USING (auth.uid() = user_id);

-- Brand Profiles
ALTER TABLE brand_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own brand profile" ON brand_profiles FOR ALL USING (auth.uid() = user_id);

-- Partner Dash Config
ALTER TABLE partner_dash_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own dash config" ON partner_dash_config FOR ALL USING (auth.uid() = user_id);

-- Community Recipes
ALTER TABLE community_recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own recipes" ON community_recipes FOR ALL USING (auth.uid() = user_id);
