-- =============================================
-- SUPPTREE - Realtime aktivieren
-- bookings + sent_plans für Live-Subscriptions
-- =============================================

ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE sent_plans;
