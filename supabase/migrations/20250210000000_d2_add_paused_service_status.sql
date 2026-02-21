ALTER TABLE d2.services
  ADD CONSTRAINT chk_services_status
  CHECK (status IN ('active', 'paused', 'cancelled'));
