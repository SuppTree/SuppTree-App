-- =============================================
-- SUPPTREE - Realtime aktivieren
-- Alle relevanten Tabellen für Live-Subscriptions
-- =============================================

ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE sent_plans;
ALTER PUBLICATION supabase_realtime ADD TABLE blood_tests;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
