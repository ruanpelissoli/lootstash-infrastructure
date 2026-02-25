DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE d2.stash_items;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE d2.stash_items REPLICA IDENTITY FULL;

GRANT SELECT ON d2.stash_items TO authenticated;
