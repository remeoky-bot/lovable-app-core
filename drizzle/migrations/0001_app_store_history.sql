CREATE TABLE public.app_store_history (
  id bigserial PRIMARY KEY,
  key text NOT NULL,
  value jsonb NOT NULL,
  saved_at timestamptz NOT NULL DEFAULT now()
);
GRANT ALL ON public.app_store_history TO service_role;
ALTER TABLE public.app_store_history ENABLE ROW LEVEL SECURITY;
CREATE INDEX app_store_history_key_saved ON public.app_store_history(key, saved_at DESC);

CREATE OR REPLACE FUNCTION public.app_store_backup()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF OLD.value IS DISTINCT FROM NEW.value THEN
    -- one snapshot per 10 minutes at most, plus always before a big shrink
    IF NOT EXISTS (SELECT 1 FROM app_store_history WHERE key = OLD.key AND saved_at > now() - interval '10 minutes')
       OR length(NEW.value::text) < length(OLD.value::text) / 2 THEN
      INSERT INTO app_store_history(key, value) VALUES (OLD.key, OLD.value);
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER app_store_backup_trg BEFORE UPDATE ON public.app_store
FOR EACH ROW EXECUTE FUNCTION public.app_store_backup();