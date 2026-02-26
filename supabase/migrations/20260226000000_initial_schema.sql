-- =============================================
-- SUPPTREE DATABASE SCHEMA
-- Für Supabase (PostgreSQL)
-- =============================================

-- ============================================
-- 1. USERS & PROFILES
-- ============================================

-- User Profiles (erweitert Supabase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  avatar_emoji TEXT DEFAULT '👤',

  -- Rolle & Typ
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'seller', 'admin')),
  seller_type TEXT CHECK (seller_type IN ('supplement', 'heilpraktiker', 'coach', NULL)),

  -- Persönliche Daten
  birth_date DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'diverse', NULL)),
  height_cm INTEGER,
  weight_kg DECIMAL(5,2),

  -- Kontakt
  phone TEXT,

  -- Gesundheitsprofil
  activity_level TEXT CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  diet_type TEXT CHECK (diet_type IN ('omnivore', 'vegetarian', 'vegan', 'pescatarian', 'keto', 'paleo')),
  allergies TEXT[], -- Array von Allergien
  health_conditions TEXT[], -- Array von Gesundheitszuständen
  health_goals TEXT[], -- Array von Zielen

  -- Schichtarbeit
  is_shift_worker BOOLEAN DEFAULT false,
  shift_pattern TEXT, -- z.B. 'früh-spät-nacht'

  -- Einstellungen
  language TEXT DEFAULT 'de',
  dark_mode BOOLEAN DEFAULT false,
  notifications_enabled BOOLEAN DEFAULT true,

  -- Gamification
  points INTEGER DEFAULT 0,
  tier TEXT DEFAULT 'seed' CHECK (tier IN ('seed', 'sprout', 'sapling', 'tree', 'oak')),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Adressen
CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  label TEXT DEFAULT 'Zuhause', -- Zuhause, Arbeit, etc.
  is_default BOOLEAN DEFAULT false,

  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  street TEXT NOT NULL,
  house_number TEXT,
  address_extra TEXT, -- Apartment, Etage, etc.
  postal_code TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT DEFAULT 'DE',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Zahlungsmethoden (nur Referenz, echte Daten bei Stripe)
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  type TEXT NOT NULL CHECK (type IN ('card', 'paypal', 'sepa', 'klarna')),
  is_default BOOLEAN DEFAULT false,

  -- Nur für Anzeige (keine sensiblen Daten!)
  display_name TEXT, -- "•••• 4242" oder "PayPal: max@..."
  brand TEXT, -- visa, mastercard, etc.

  -- Stripe Reference
  stripe_payment_method_id TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. PRODUCTS (Marktplatz)
-- ============================================

-- Produktkategorien
CREATE TABLE categories (
  id TEXT PRIMARY KEY, -- 'vitamine', 'mineralien', etc.
  name TEXT NOT NULL,
  icon TEXT,
  sort_order INTEGER DEFAULT 0
);

-- Marken/Hersteller
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  logo_url TEXT,
  description TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Produkte
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Basis
  name TEXT NOT NULL,
  brand_id UUID REFERENCES brands(id),
  category_id TEXT REFERENCES categories(id),

  -- Beschreibung
  description TEXT,
  short_description TEXT,
  ingredients TEXT,

  -- Darreichung
  dosage_form TEXT CHECK (dosage_form IN ('capsule', 'tablet', 'powder', 'liquid', 'drops', 'spray', 'gummy')),
  dosage_amount TEXT, -- "500mg", "1000 I.E.", etc.
  servings_per_container INTEGER,

  -- Preis
  price DECIMAL(10,2) NOT NULL,
  price_per_unit DECIMAL(10,2), -- Grundpreis pro kg/L
  compare_at_price DECIMAL(10,2), -- UVP für Streichpreis

  -- Abo
  abo_available BOOLEAN DEFAULT true,
  abo_discount_percent INTEGER DEFAULT 8,

  -- Bilder
  icon TEXT, -- Emoji für Demo
  image_url TEXT,
  images TEXT[], -- Array von Bild-URLs

  -- Bewertungen
  rating DECIMAL(2,1) DEFAULT 0,
  review_count INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  stock_quantity INTEGER DEFAULT 100,

  -- SEO
  slug TEXT UNIQUE,

  -- SuppTree Qualität
  is_st_certified BOOLEAN DEFAULT false,
  lab_tested BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Produkt-Bewertungen
CREATE TABLE product_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  content TEXT,

  is_verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. ORDERS & CART
-- ============================================

-- Bestellungen
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),

  -- Order Number für Kunden
  order_number TEXT UNIQUE NOT NULL,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),

  -- Beträge
  subtotal DECIMAL(10,2) NOT NULL,
  shipping_cost DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  points_used INTEGER DEFAULT 0,
  points_discount DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,

  -- Punkte verdient
  points_earned INTEGER DEFAULT 0,

  -- Versand
  shipping_address_id UUID REFERENCES addresses(id),
  shipping_method TEXT DEFAULT 'standard',
  tracking_number TEXT,

  -- Payment
  payment_method_id UUID REFERENCES payment_methods(id),
  stripe_payment_intent_id TEXT,
  paid_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

-- Bestellpositionen
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),

  -- Snapshot der Produktdaten zum Bestellzeitpunkt
  product_name TEXT NOT NULL,
  product_brand TEXT,
  product_icon TEXT,

  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,

  -- Abo
  is_subscription BOOLEAN DEFAULT false,
  subscription_interval TEXT, -- 'monthly', 'quarterly'

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Abonnements
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),

  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),

  -- Intervall
  interval TEXT DEFAULT 'monthly' CHECK (interval IN ('monthly', 'quarterly', 'yearly')),

  -- Preis
  price DECIMAL(10,2) NOT NULL,
  discount_percent INTEGER DEFAULT 8,

  -- Nächste Lieferung
  next_delivery_date DATE,

  -- Stripe
  stripe_subscription_id TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  pause_until DATE
);

-- ============================================
-- 4. MEINE SUPPLEMENTS & MEDIKAMENTE
-- ============================================

-- Meine Supplements
CREATE TABLE my_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id), -- NULL wenn manuell hinzugefügt

  -- Basis
  name TEXT NOT NULL,
  brand TEXT,
  icon TEXT DEFAULT '💊',

  -- Dosierung
  dosage_form TEXT,
  dosage_amount TEXT,
  doses_per_day INTEGER DEFAULT 1,

  -- Einnahmezeiten
  take_morning BOOLEAN DEFAULT false,
  take_noon BOOLEAN DEFAULT false,
  take_evening BOOLEAN DEFAULT false,
  take_night BOOLEAN DEFAULT false,
  take_with_meal BOOLEAN DEFAULT false,

  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'finished', 'waiting')),

  -- Tracking
  current_stock INTEGER,
  started_at DATE,
  finished_at DATE,

  -- Notizen
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meine Medikamente
CREATE TABLE my_medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  -- Basis
  name TEXT NOT NULL,
  active_ingredient TEXT, -- Wirkstoff
  icon TEXT DEFAULT '💉',

  -- Dosierung
  dosage TEXT, -- "100mg"
  doses_per_day INTEGER DEFAULT 1,

  -- Einnahmezeiten
  take_morning BOOLEAN DEFAULT false,
  take_noon BOOLEAN DEFAULT false,
  take_evening BOOLEAN DEFAULT false,
  take_night BOOLEAN DEFAULT false,

  -- Arzt
  prescribed_by TEXT,
  prescription_date DATE,

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Wichtig für Interaktionen
  interaction_warnings TEXT[],

  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Supplement Log (Einnahme-Tracking)
CREATE TABLE supplement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  supplement_id UUID REFERENCES my_supplements(id) ON DELETE CASCADE,

  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_time TEXT, -- 'morning', 'noon', 'evening', 'night'

  status TEXT DEFAULT 'taken' CHECK (status IN ('taken', 'skipped', 'snoozed')),

  notes TEXT
);

-- ============================================
-- 5. KUREN
-- ============================================

-- Kur-Definitionen (Templates)
CREATE TABLE kur_templates (
  id TEXT PRIMARY KEY, -- 'darm-kur', 'immun-kur', etc.

  name TEXT NOT NULL,
  category TEXT NOT NULL, -- 'verdauung', 'immunsystem', etc.
  icon TEXT,

  description TEXT,
  short_description TEXT,

  duration_days INTEGER NOT NULL,
  difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),

  -- Phasen als JSON
  phases JSONB, -- [{name, days, description, products}]

  -- Empfohlene Produkte
  recommended_product_ids UUID[],

  -- Preis (Bundle)
  bundle_price DECIMAL(10,2),

  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Aktive Kuren der User
CREATE TABLE my_kuren (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  kur_template_id TEXT REFERENCES kur_templates(id),

  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),

  -- Fortschritt
  started_at DATE NOT NULL DEFAULT CURRENT_DATE,
  current_day INTEGER DEFAULT 1,
  current_phase INTEGER DEFAULT 1,

  -- Anpassungen
  custom_settings JSONB,

  completed_at DATE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. TRAINING & ERNÄHRUNG
-- ============================================

-- Trainingspläne
CREATE TABLE training_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  goal TEXT, -- 'muskelaufbau', 'abnehmen', 'ausdauer', etc.
  icon TEXT DEFAULT '🏋️',

  -- Konfiguration
  frequency_per_week INTEGER DEFAULT 3,
  duration_minutes INTEGER DEFAULT 60,
  location TEXT, -- 'gym', 'home', 'outdoor'
  level TEXT, -- 'beginner', 'intermediate', 'advanced'

  -- Plan Details als JSON
  workouts JSONB, -- [{day, name, exercises}]

  -- Quelle
  source TEXT CHECK (source IN ('self', 'trainer', 'studio')),
  trainer_name TEXT,

  -- Status
  is_active BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ernährungspläne
CREATE TABLE nutrition_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  goal TEXT, -- 'abnehmen', 'muskel', 'vegan', etc.
  icon TEXT DEFAULT '🥗',

  -- Konfiguration
  meals_per_day INTEGER DEFAULT 4,
  daily_calories INTEGER,

  -- Makros
  protein_grams INTEGER,
  carbs_grams INTEGER,
  fat_grams INTEGER,

  -- Einschränkungen
  allergies TEXT[],
  excluded_foods TEXT[],

  -- Plan Details als JSON
  meal_plan JSONB, -- [{day, meals: [{time, name, kcal}]}]

  -- Quelle
  source TEXT CHECK (source IN ('self', 'coach', 'template')),
  coach_name TEXT,

  -- Status
  is_active BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. TERMINE
-- ============================================

-- Termin-Anbieter
CREATE TABLE appointment_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('heilpraktiker', 'hebamme', 'kinderwunsch', 'physio', 'kosmetik')),

  -- Kontakt
  email TEXT,
  phone TEXT,
  website TEXT,

  -- Adresse
  street TEXT,
  postal_code TEXT,
  city TEXT,

  -- Details
  description TEXT,
  specializations TEXT[],

  -- Bewertung
  rating DECIMAL(2,1),
  review_count INTEGER DEFAULT 0,

  -- Preise
  price_from DECIMAL(10,2),

  -- Verfügbarkeit
  is_active BOOLEAN DEFAULT true,
  accepts_online_booking BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Termine
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES appointment_providers(id),

  -- Termin Details
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  duration_minutes INTEGER DEFAULT 60,

  -- Art
  type TEXT, -- 'erstberatung', 'folge', 'behandlung'

  -- Status
  status TEXT DEFAULT 'booked' CHECK (status IN ('booked', 'confirmed', 'completed', 'cancelled', 'no_show')),

  -- Notizen
  notes TEXT,

  -- Erinnerung
  reminder_sent BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. BLUTWERTE
-- ============================================

-- Blutwert-Tests
CREATE TABLE blood_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  -- Test Info
  test_date DATE NOT NULL,
  test_type TEXT, -- 'vollblut', 'vitamin', 'hormon', etc.

  -- Quelle
  source TEXT CHECK (source IN ('heilpraktiker', 'testkit', 'arzt', 'manual')),
  provider_name TEXT,

  -- Datei (wenn hochgeladen)
  file_url TEXT,

  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Einzelne Blutwerte
CREATE TABLE blood_values (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blood_test_id UUID REFERENCES blood_tests(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  -- Wert
  marker TEXT NOT NULL, -- 'vitamin_d', 'iron', 'b12', etc.
  value DECIMAL(10,3) NOT NULL,
  unit TEXT NOT NULL, -- 'ng/ml', 'µg/l', etc.

  -- Referenzbereich
  reference_min DECIMAL(10,3),
  reference_max DECIMAL(10,3),

  -- Status
  status TEXT CHECK (status IN ('low', 'normal', 'high', 'critical')),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. SCHICHTKALENDER
-- ============================================

-- Schicht-Definitionen
CREATE TABLE shift_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  name TEXT NOT NULL, -- 'Frühschicht', 'Spätschicht', 'Nachtschicht'
  short_code TEXT NOT NULL, -- 'F', 'S', 'N'
  icon TEXT,
  color TEXT, -- Hex Color

  -- Zeiten
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,

  -- Einnahme-Einstellungen
  meal_times JSONB, -- {breakfast: '06:00', lunch: '12:00', dinner: '18:00'}

  is_default BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Geplante Schichten
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  shift_type_id UUID REFERENCES shift_types(id) ON DELETE CASCADE,

  date DATE NOT NULL,

  -- Override für spezielle Tage
  custom_start_time TIME,
  custom_end_time TIME,

  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, date)
);

-- ============================================
-- 10. FAVORITES & WISHLIST
-- ============================================

CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, product_id)
);

-- ============================================
-- 11. POINTS & REWARDS
-- ============================================

-- Punkte-Transaktionen (History)
CREATE TABLE points_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  type TEXT NOT NULL CHECK (type IN ('earn', 'spend', 'expire', 'bonus')),
  amount INTEGER NOT NULL, -- positiv für earn, negativ für spend

  -- Kontext
  source TEXT, -- 'order', 'review', 'referral', 'bonus'
  reference_id UUID, -- Order ID, Review ID, etc.

  description TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 12. SELLER / PARTNER SYSTEM
-- ============================================

-- Verkäufer-Shops
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,

  -- Basis
  name TEXT NOT NULL,
  slug TEXT UNIQUE, -- URL-freundlicher Name
  description TEXT,
  short_description TEXT,

  -- Branding
  logo_url TEXT,
  banner_url TEXT,

  -- Kontakt
  email TEXT,
  phone TEXT,
  website TEXT,

  -- Adresse
  street TEXT,
  house_number TEXT,
  postal_code TEXT,
  city TEXT,
  country TEXT DEFAULT 'DE',

  -- Geschäftsdaten
  company_name TEXT, -- Firmenname laut Handelsregister
  vat_id TEXT, -- USt-IdNr.
  tax_number TEXT, -- Steuernummer
  iban TEXT, -- Für Auszahlungen

  -- Abo-Plan
  subscription_plan TEXT DEFAULT 'starter' CHECK (subscription_plan IN ('starter', 'professional', 'enterprise')),
  subscription_valid_until DATE,

  -- Verifizierung
  is_verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verification_documents TEXT[], -- URLs zu hochgeladenen Dokumenten

  -- Bewertung
  rating DECIMAL(2,1) DEFAULT 0,
  review_count INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Statistiken (gecacht, wird periodisch aktualisiert)
  total_sales INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seller-Produkte (welcher Seller bietet welches Produkt an)
CREATE TABLE seller_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,

  -- Eigener Preis & Bestand des Sellers
  seller_price DECIMAL(10,2) NOT NULL,
  compare_at_price DECIMAL(10,2), -- UVP / Streichpreis
  seller_stock INTEGER DEFAULT 0,

  -- SKU des Sellers
  seller_sku TEXT,

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Versand
  shipping_time_days INTEGER DEFAULT 3, -- Lieferzeit in Tagen
  free_shipping_above DECIMAL(10,2), -- Gratis-Versand ab Betrag

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(shop_id, product_id)
);

-- Seller-Services (Dienstleistungen von Heilpraktikern, Coaches etc.)
CREATE TABLE seller_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,

  -- Basis
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('beratung', 'behandlung', 'coaching', 'bluttest', 'ernaehrungsplan', 'paket')),
  description TEXT,

  -- Preis & Dauer
  price DECIMAL(10,2) NOT NULL,
  duration_minutes INTEGER DEFAULT 60,

  -- Modus: wie wird der Service erbracht
  mode TEXT[] DEFAULT ARRAY['praxis'], -- 'praxis', 'video', 'phone'

  -- Verfügbarkeit
  is_active BOOLEAN DEFAULT true,
  max_bookings_per_day INTEGER DEFAULT 8,

  -- Extras
  includes TEXT[], -- Was ist enthalten
  icon TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seller-Auszahlungen
CREATE TABLE seller_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,

  -- Beträge
  gross_amount DECIMAL(10,2) NOT NULL, -- Bruttobetrag
  platform_fee DECIMAL(10,2) DEFAULT 0, -- SuppTree Gebühr
  net_amount DECIMAL(10,2) NOT NULL, -- Auszahlungsbetrag

  -- Bankdaten (nur letzte 4 Stellen für Anzeige)
  iban_last4 TEXT,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'paid', 'failed')),

  -- Zeitraum (für welchen Abrechnungszeitraum)
  period_start DATE,
  period_end DATE,

  -- Zahlung
  paid_at TIMESTAMPTZ,
  payment_reference TEXT, -- Bank-Referenz

  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seller-Provisionen (pro Verkauf)
CREATE TABLE seller_commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
  order_item_id UUID REFERENCES order_items(id) ON DELETE SET NULL,
  payout_id UUID REFERENCES seller_payouts(id) ON DELETE SET NULL, -- Zuordnung zur Auszahlung

  -- Beträge
  gross_amount DECIMAL(10,2) NOT NULL, -- Verkaufspreis
  commission_rate DECIMAL(5,2) NOT NULL, -- Provisionssatz in %
  commission_amount DECIMAL(10,2) NOT NULL, -- Provisionsbetrag
  platform_fee DECIMAL(10,2) DEFAULT 0, -- SuppTree Plattform-Gebühr
  net_amount DECIMAL(10,2) NOT NULL, -- Netto an Seller

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'paid', 'refunded')),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. INDEXES FÜR PERFORMANCE
-- ============================================

-- Bestehende Indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_my_supplements_user ON my_supplements(user_id);
CREATE INDEX idx_my_supplements_status ON my_supplements(status);
CREATE INDEX idx_supplement_logs_user ON supplement_logs(user_id);
CREATE INDEX idx_supplement_logs_date ON supplement_logs(taken_at);
CREATE INDEX idx_shifts_user_date ON shifts(user_id, date);
CREATE INDEX idx_appointments_user ON appointments(user_id);
CREATE INDEX idx_blood_values_user ON blood_values(user_id);
CREATE INDEX idx_favorites_user ON favorites(user_id);

-- Seller Indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_shops_user ON shops(user_id);
CREATE INDEX idx_shops_active ON shops(is_active);
CREATE INDEX idx_shops_slug ON shops(slug);
CREATE INDEX idx_seller_products_shop ON seller_products(shop_id);
CREATE INDEX idx_seller_products_product ON seller_products(product_id);
CREATE INDEX idx_seller_services_shop ON seller_services(shop_id);
CREATE INDEX idx_seller_services_category ON seller_services(category);
CREATE INDEX idx_seller_payouts_shop ON seller_payouts(shop_id);
CREATE INDEX idx_seller_payouts_status ON seller_payouts(status);
CREATE INDEX idx_seller_commissions_shop ON seller_commissions(shop_id);
CREATE INDEX idx_seller_commissions_payout ON seller_commissions(payout_id);

-- ============================================
-- 14. ROW LEVEL SECURITY (RLS)
-- ============================================

-- RLS aktivieren für alle Tabellen
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE my_supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE my_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE my_kuren ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_commissions ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------
-- User-Policies: Eigene Daten
-- ----------------------------------------
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can manage own addresses" ON addresses FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own payment methods" ON payment_methods FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own subscriptions" ON subscriptions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own supplements" ON my_supplements FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own medications" ON my_medications FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own supplement logs" ON supplement_logs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own kuren" ON my_kuren FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own training plans" ON training_plans FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own nutrition plans" ON nutrition_plans FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own appointments" ON appointments FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own blood tests" ON blood_tests FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own blood values" ON blood_values FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own shift types" ON shift_types FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own shifts" ON shifts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view own points" ON points_transactions FOR SELECT USING (auth.uid() = user_id);

-- ----------------------------------------
-- Public-Policies: Jeder kann lesen
-- ----------------------------------------
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (is_active = true);
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT USING (true);
CREATE POLICY "Brands are viewable by everyone" ON brands FOR SELECT USING (true);
CREATE POLICY "Kur templates are viewable by everyone" ON kur_templates FOR SELECT USING (is_active = true);
CREATE POLICY "Appointment providers are viewable by everyone" ON appointment_providers FOR SELECT USING (is_active = true);
CREATE POLICY "Reviews are viewable by everyone" ON product_reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON product_reviews FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------
-- Seller-Policies: Eigene Shop-Daten
-- ----------------------------------------

-- Shops: Seller sieht/bearbeitet nur eigenen Shop
CREATE POLICY "Seller can manage own shop"
  ON shops FOR ALL
  USING (auth.uid() = user_id);

-- Shops: Kunden können aktive Shops sehen
CREATE POLICY "Active shops are viewable by everyone"
  ON shops FOR SELECT
  USING (is_active = true);

-- Seller-Produkte: Seller sieht/bearbeitet nur eigene
CREATE POLICY "Seller can manage own products"
  ON seller_products FOR ALL
  USING (shop_id IN (SELECT id FROM shops WHERE user_id = auth.uid()));

-- Seller-Produkte: Kunden können aktive sehen
CREATE POLICY "Active seller products are viewable by everyone"
  ON seller_products FOR SELECT
  USING (is_active = true);

-- Seller-Services: Seller sieht/bearbeitet nur eigene
CREATE POLICY "Seller can manage own services"
  ON seller_services FOR ALL
  USING (shop_id IN (SELECT id FROM shops WHERE user_id = auth.uid()));

-- Seller-Services: Kunden können aktive sehen
CREATE POLICY "Active seller services are viewable by everyone"
  ON seller_services FOR SELECT
  USING (is_active = true);

-- Seller-Auszahlungen: Nur eigene sehen
CREATE POLICY "Seller can view own payouts"
  ON seller_payouts FOR SELECT
  USING (shop_id IN (SELECT id FROM shops WHERE user_id = auth.uid()));

-- Seller-Provisionen: Nur eigene sehen
CREATE POLICY "Seller can view own commissions"
  ON seller_commissions FOR SELECT
  USING (shop_id IN (SELECT id FROM shops WHERE user_id = auth.uid()));

-- ============================================
-- 15. FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-Update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers für updated_at (bestehende Tabellen)
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_my_supplements_updated_at BEFORE UPDATE ON my_supplements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_my_medications_updated_at BEFORE UPDATE ON my_medications FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_my_kuren_updated_at BEFORE UPDATE ON my_kuren FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_training_plans_updated_at BEFORE UPDATE ON training_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_nutrition_plans_updated_at BEFORE UPDATE ON nutrition_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Triggers für updated_at (Seller-Tabellen)
CREATE TRIGGER update_shops_updated_at BEFORE UPDATE ON shops FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_seller_products_updated_at BEFORE UPDATE ON seller_products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_seller_services_updated_at BEFORE UPDATE ON seller_services FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_seller_payouts_updated_at BEFORE UPDATE ON seller_payouts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Funktion: Neuen User Profile erstellen bei Registrierung
-- Übernimmt Rolle und Name aus den User-Metadaten
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, role, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Bei neuem Auth User automatisch Profile erstellen
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Funktion: Punkte updaten
CREATE OR REPLACE FUNCTION update_user_points()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET points = points + NEW.amount
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_points_transaction
  AFTER INSERT ON points_transactions
  FOR EACH ROW EXECUTE FUNCTION update_user_points();

-- Funktion: Produkt-Rating updaten bei neuer Review
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products
  SET
    rating = (SELECT AVG(rating) FROM product_reviews WHERE product_id = NEW.product_id),
    review_count = (SELECT COUNT(*) FROM product_reviews WHERE product_id = NEW.product_id)
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_new_review
  AFTER INSERT OR UPDATE OR DELETE ON product_reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- ============================================
-- 16. INITIAL DATA
-- ============================================

-- Kategorien einfügen
INSERT INTO categories (id, name, icon, sort_order) VALUES
('vitamine', 'Vitamine', '💊', 1),
('mineralien', 'Mineralien', '⚡', 2),
('omega', 'Omega Fettsäuren', '🐟', 3),
('sport', 'Sport & Fitness', '💪', 4),
('darm', 'Darmgesundheit', '🦠', 5),
('schlaf', 'Schlaf & Entspannung', '😴', 6),
('immunsystem', 'Immunsystem', '🛡️', 7),
('beauty', 'Haut, Haare, Nägel', '✨', 8),
('energie', 'Energie & Fokus', '⚡', 9),
('herz', 'Herz & Kreislauf', '❤️', 10);

-- Beispiel Kur-Templates
INSERT INTO kur_templates (id, name, category, icon, description, duration_days, difficulty) VALUES
('darm-kur', 'Darmkur Pro', 'verdauung', '🦠', 'Umfassende Darmsanierung in 3 Phasen', 21, 'beginner'),
('immun-kur', 'Immun-Booster', 'immunsystem', '🛡️', 'Stärke dein Immunsystem nachhaltig', 14, 'beginner'),
('detox-kur', 'Detox Intensiv', 'detox', '🌿', 'Entgiftung und Reinigung', 14, 'intermediate'),
('energie-kur', 'Energie-Kick', 'energie', '⚡', 'Mehr Energie im Alltag', 30, 'beginner'),
('schlaf-kur', 'Schlaf-Optimierung', 'schlaf', '😴', 'Endlich besser schlafen', 30, 'beginner'),
('haut-kur', 'Skin Glow', 'beauty', '✨', 'Strahlende Haut von innen', 28, 'beginner'),
('stress-kur', 'Stress-Balance', 'stress', '🧘', 'Innere Ruhe finden', 21, 'intermediate'),
('gelenk-kur', 'Gelenk-Aktiv', 'bewegung', '🦴', 'Beweglich bleiben', 30, 'beginner');
