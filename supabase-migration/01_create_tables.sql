-- SuppTree Knowledge Database Migration
-- Generated from SuppTree_KOMPLETT_FINAL_v2.xlsx

-- ============================
-- Table: supplements_basis (1124 rows)
-- ============================
DROP TABLE IF EXISTS supplements_basis CASCADE;
CREATE TABLE supplements_basis (
  _row_id SERIAL PRIMARY KEY,
  id TEXT,
  name TEXT,
  name_en TEXT,
  auch_bekannt_als TEXT,
  kategorie TEXT,
  unterkategorie TEXT,
  wirkung TEXT,
  wirkung_kurz TEXT,
  symptome_ziele TEXT,
  health_claims_efsa TEXT,
  einnahme_zeitpunkt TEXT,
  einnahme_mit TEXT,
  einnahme_ohne TEXT,
  einnahme_hinweis TEXT,
  max_einzeldosis TEXT,
  kombiniert_gut_mit TEXT,
  nicht_zusammen_mit TEXT,
  zeitlicher_abstand_h TEXT,
  kombinations_hinweis TEXT,
  fettloeslich TEXT,
  wasserloeslich TEXT,
  vegan_verfuegbar TEXT,
  halalzertifiziert_moeglich TEXT,
  schwangerschaft TEXT,
  stillzeit TEXT,
  kinder_geeignet TEXT,
  senioren_hinweis TEXT,
  qualitaetsmerkmale TEXT,
  bioverfuegbarkeit_info TEXT,
  beste_form TEXT,
  lagerung TEXT,
  haltbarkeit_monate TEXT,
  warnhinweise TEXT,
  kontraindikationen TEXT,
  nebenwirkungen_ueberdosis TEXT,
  ueberdosis_symptome TEXT,
  bluttest_empfohlen TEXT,
  welcher_blutwert TEXT,
  optimalbereich TEXT,
  natuerliche_quellen TEXT,
  rda_erwachsene TEXT,
  rda_einheit TEXT,
  ul_efsa TEXT,
  ul_einheit TEXT,
  bfr_hoechstmenge TEXT,
  dge_referenz TEXT,
  letzte_aktualisierung TEXT,
  verifiziert TEXT
);

ALTER TABLE supplements_basis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON supplements_basis FOR SELECT USING (true);

-- ============================
-- Table: laender_regulierung (1105 rows)
-- ============================
DROP TABLE IF EXISTS laender_regulierung CASCADE;
CREATE TABLE laender_regulierung (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  supplement_name TEXT,
  de_max TEXT,
  de_empf TEXT,
  de_status TEXT,
  de_quelle TEXT,
  at_max TEXT,
  at_empf TEXT,
  at_status TEXT,
  at_quelle TEXT,
  ch_max TEXT,
  ch_empf TEXT,
  ch_status TEXT,
  ch_quelle TEXT,
  fr_max TEXT,
  fr_empf TEXT,
  fr_status TEXT,
  fr_quelle TEXT,
  be_max TEXT,
  be_empf TEXT,
  be_status TEXT,
  be_quelle TEXT,
  nl_max TEXT,
  nl_empf TEXT,
  nl_status TEXT,
  nl_quelle TEXT,
  lu_max TEXT,
  lu_empf TEXT,
  lu_status TEXT,
  lu_quelle TEXT,
  it_max TEXT,
  it_empf TEXT,
  it_status TEXT,
  it_quelle TEXT,
  es_max TEXT,
  es_empf TEXT,
  es_status TEXT,
  es_quelle TEXT,
  pt_max TEXT,
  pt_empf TEXT,
  pt_status TEXT,
  pt_quelle TEXT,
  gr_max TEXT,
  gr_empf TEXT,
  gr_status TEXT,
  gr_quelle TEXT,
  mt_max TEXT,
  mt_empf TEXT,
  mt_status TEXT,
  mt_quelle TEXT,
  cy_max TEXT,
  cy_empf TEXT,
  cy_status TEXT,
  cy_quelle TEXT,
  se_max TEXT,
  se_empf TEXT,
  se_status TEXT,
  se_quelle TEXT,
  dk_max TEXT,
  dk_empf TEXT,
  dk_status TEXT,
  dk_quelle TEXT,
  fi_max TEXT,
  fi_empf TEXT,
  fi_status TEXT,
  fi_quelle TEXT,
  no_max TEXT,
  no_empf TEXT,
  no_status TEXT,
  no_quelle TEXT,
  is_max TEXT,
  is_empf TEXT,
  is_status TEXT,
  is_quelle TEXT,
  pl_max TEXT,
  pl_empf TEXT,
  pl_status TEXT,
  pl_quelle TEXT,
  cz_max TEXT,
  cz_empf TEXT,
  cz_status TEXT,
  cz_quelle TEXT,
  sk_max TEXT,
  sk_empf TEXT,
  sk_status TEXT,
  sk_quelle TEXT,
  hu_max TEXT,
  hu_empf TEXT,
  hu_status TEXT,
  hu_quelle TEXT,
  ro_max TEXT,
  ro_empf TEXT,
  ro_status TEXT,
  ro_quelle TEXT,
  bg_max TEXT,
  bg_empf TEXT,
  bg_status TEXT,
  bg_quelle TEXT,
  si_max TEXT,
  si_empf TEXT,
  si_status TEXT,
  si_quelle TEXT,
  hr_max TEXT,
  hr_empf TEXT,
  hr_status TEXT,
  hr_quelle TEXT,
  ee_max TEXT,
  ee_empf TEXT,
  ee_status TEXT,
  ee_quelle TEXT,
  lv_max TEXT,
  lv_empf TEXT,
  lv_status TEXT,
  lv_quelle TEXT,
  lt_max TEXT,
  lt_empf TEXT,
  lt_status TEXT,
  lt_quelle TEXT,
  ie_max TEXT,
  ie_empf TEXT,
  ie_status TEXT,
  ie_quelle TEXT,
  uk_max TEXT,
  uk_empf TEXT,
  uk_status TEXT,
  uk_quelle TEXT
);

ALTER TABLE laender_regulierung ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON laender_regulierung FOR SELECT USING (true);

-- ============================
-- Table: dosierungen_altersgruppen (1106 rows)
-- ============================
DROP TABLE IF EXISTS dosierungen_altersgruppen CASCADE;
CREATE TABLE dosierungen_altersgruppen (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  supplement_name TEXT,
  saeugline_0_6m TEXT,
  saeugline_7_12m TEXT,
  kinder_1_3j TEXT,
  kinder_4_6j TEXT,
  kinder_7_10j TEXT,
  kinder_11_14j TEXT,
  jugend_15_17j TEXT,
  erwachsene_m TEXT,
  erwachsene_w TEXT,
  schwangere TEXT,
  stillende TEXT,
  senioren_65plus TEXT,
  ul_saeugline TEXT,
  ul_kinder TEXT,
  ul_erwachsene TEXT,
  einheit TEXT,
  quelle TEXT
);

ALTER TABLE dosierungen_altersgruppen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON dosierungen_altersgruppen FOR SELECT USING (true);

-- ============================
-- Table: wechselwirkungen_supplements (2790 rows)
-- ============================
DROP TABLE IF EXISTS wechselwirkungen_supplements CASCADE;
CREATE TABLE wechselwirkungen_supplements (
  _row_id SERIAL PRIMARY KEY,
  supplement_a TEXT,
  supplement_b TEXT,
  typ TEXT,
  staerke TEXT,
  richtung TEXT,
  mechanismus TEXT,
  praktische_auswirkung TEXT,
  empfehlung TEXT,
  zeitabstand_h TEXT,
  evidenz TEXT,
  quelle TEXT
);

ALTER TABLE wechselwirkungen_supplements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON wechselwirkungen_supplements FOR SELECT USING (true);

-- ============================
-- Table: medikamenten_interaktionen (3592 rows)
-- ============================
DROP TABLE IF EXISTS medikamenten_interaktionen CASCADE;
CREATE TABLE medikamenten_interaktionen (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  supplement_name TEXT,
  medikament_gruppe TEXT,
  medikament_beispiele TEXT,
  interaktions_typ TEXT,
  mechanismus TEXT,
  risiko_level TEXT,
  klinische_relevanz TEXT,
  empfehlung TEXT,
  quelle TEXT
);

ALTER TABLE medikamenten_interaktionen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON medikamenten_interaktionen FOR SELECT USING (true);

-- ============================
-- Table: symptome_ziele (1619 rows)
-- ============================
DROP TABLE IF EXISTS symptome_ziele CASCADE;
CREATE TABLE symptome_ziele (
  _row_id SERIAL PRIMARY KEY,
  id TEXT,
  name_de TEXT,
  name_en TEXT,
  keywords_de TEXT,
  keywords_en TEXT,
  kategorie TEXT,
  unterkategorie TEXT,
  empfohlene_supplements TEXT,
  prioritaet_reihenfolge TEXT,
  ausschluss_symptome TEXT,
  ausschluss_supplements TEXT,
  wichtiger_hinweis_de TEXT,
  wichtiger_hinweis_en TEXT,
  arzt_pflicht TEXT,
  arzt_grund TEXT
);

ALTER TABLE symptome_ziele ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON symptome_ziele FOR SELECT USING (true);

-- ============================
-- Table: keywords_synonyme (1208 rows)
-- ============================
DROP TABLE IF EXISTS keywords_synonyme CASCADE;
CREATE TABLE keywords_synonyme (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  supplement_name TEXT,
  synonyme_de TEXT,
  synonyme_en TEXT,
  schreibweisen TEXT,
  umgangssprache TEXT,
  verwechslungsgefahr TEXT,
  nicht_verwechseln_mit TEXT
);

ALTER TABLE keywords_synonyme ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON keywords_synonyme FOR SELECT USING (true);

-- ============================
-- Table: formen_vergleich (3420 rows)
-- ============================
DROP TABLE IF EXISTS formen_vergleich CASCADE;
CREATE TABLE formen_vergleich (
  _row_id SERIAL PRIMARY KEY,
  basis_supplement TEXT,
  form_name TEXT,
  form_name_en TEXT,
  bioverfuegbarkeit_prozent TEXT,
  bioverfuegbarkeit_text TEXT,
  vorteile TEXT,
  nachteile TEXT,
  beste_fuer TEXT,
  preis_niveau TEXT,
  vegan TEXT,
  quelle TEXT
);

ALTER TABLE formen_vergleich ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON formen_vergleich FOR SELECT USING (true);

-- ============================
-- Table: quellen_verzeichnis (8093 rows)
-- ============================
DROP TABLE IF EXISTS quellen_verzeichnis CASCADE;
CREATE TABLE quellen_verzeichnis (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  quelle_typ TEXT,
  quelle_name TEXT,
  quelle_url TEXT,
  abgerufen_am TEXT,
  extrahierte_daten TEXT,
  vertrauenswuerdigkeit TEXT
);

ALTER TABLE quellen_verzeichnis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON quellen_verzeichnis FOR SELECT USING (true);

-- ============================
-- Table: studien_evidenz (4525 rows)
-- ============================
DROP TABLE IF EXISTS studien_evidenz CASCADE;
CREATE TABLE studien_evidenz (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  studie_name TEXT,
  pmid TEXT,
  studie_typ TEXT,
  evidenz_level TEXT,
  teilnehmer_n TEXT,
  indikation TEXT,
  dosierung_studie TEXT,
  ergebnis_kurz TEXT,
  effektstaerke TEXT,
  nebenwirkungen TEXT,
  relevanz_fuer_ki TEXT
);

ALTER TABLE studien_evidenz ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON studien_evidenz FOR SELECT USING (true);

-- ============================
-- Table: kontraindikationen_detail (4422 rows)
-- ============================
DROP TABLE IF EXISTS kontraindikationen_detail CASCADE;
CREATE TABLE kontraindikationen_detail (
  _row_id SERIAL PRIMARY KEY,
  supplement_id TEXT,
  supplement_name TEXT,
  kontraindikation TEXT,
  kontraindikation_en TEXT,
  schweregrad TEXT,
  erklaerung TEXT,
  was_passiert TEXT,
  quelle TEXT,
  unnamed_8 TEXT,
  unnamed_9 TEXT,
  unnamed_10 TEXT,
  unnamed_11 TEXT
);

ALTER TABLE kontraindikationen_detail ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON kontraindikationen_detail FOR SELECT USING (true);

-- ============================
-- Table: einheiten_umrechnung (6509 rows)
-- ============================
DROP TABLE IF EXISTS einheiten_umrechnung CASCADE;
CREATE TABLE einheiten_umrechnung (
  _row_id SERIAL PRIMARY KEY,
  supplement TEXT,
  einheit_1 TEXT,
  einheit_2 TEXT,
  umrechnung TEXT,
  beispiel TEXT
);

ALTER TABLE einheiten_umrechnung ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON einheiten_umrechnung FOR SELECT USING (true);

-- ============================
-- Table: kategorien (1129 rows)
-- ============================
DROP TABLE IF EXISTS kategorien CASCADE;
CREATE TABLE kategorien (
  _row_id SERIAL PRIMARY KEY,
  kategorie_id TEXT,
  kategorie_name TEXT,
  kategorie_name_en TEXT,
  beschreibung TEXT
);

ALTER TABLE kategorien ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON kategorien FOR SELECT USING (true);

-- ============================
-- Table: laender_behoerden (48 rows)
-- ============================
DROP TABLE IF EXISTS laender_behoerden CASCADE;
CREATE TABLE laender_behoerden (
  _row_id SERIAL PRIMARY KEY,
  code TEXT,
  land TEXT,
  region TEXT,
  beh_rde TEXT,
  website TEXT,
  anmerkung TEXT
);

ALTER TABLE laender_behoerden ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON laender_behoerden FOR SELECT USING (true);
