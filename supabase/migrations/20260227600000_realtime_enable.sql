-- =============================================
-- SUPPTREE - Realtime aktivieren
-- bookings + sent_plans + blood_tests für Live-Subscriptions
-- =============================================

ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE sent_plans;
ALTER PUBLICATION supabase_realtime ADD TABLE blood_tests;
