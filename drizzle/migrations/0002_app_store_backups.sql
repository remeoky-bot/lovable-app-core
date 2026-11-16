CREATE TABLE IF NOT EXISTS public.app_store_backups (
  id bigserial PRIMARY KEY,
  key text NOT NULL,
  value jsonb NOT NULL,
  nb_eleves integer,
  reason text,
  saved_at timestamptz NOT NULL DEFAULT now()
);
GRANT ALL ON public.app_store_backups TO service_role;
ALTER TABLE public.app_store_backups ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS app_store_backups_key_saved ON public.app_store_backups(key, saved_at DESC);

CREATE OR REPLACE FUNCTION public.app_store_make_backup()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  old_n integer;
  new_n integer;
  why text;
BEGIN
  BEGIN
    IF OLD.value IS DISTINCT FROM NEW.value THEN
      old_n := CASE WHEN jsonb_typeof(OLD.value->'eleves') = 'array' THEN jsonb_array_length(OLD.value->'eleves') ELSE 0 END;
      new_n := CASE WHEN jsonb_typeof(NEW.value->'eleves') = 'array' THEN jsonb_array_length(NEW.value->'eleves') ELSE 0 END;
      IF new_n < old_n THEN
        why := 'avant baisse du nombre d''élèves (' || old_n || ' -> ' || new_n || ')';
      ELSIF NOT EXISTS (SELECT 1 FROM app_store_backups WHERE key = OLD.key AND saved_at > now() - interval '1 hour') THEN
        why := 'copie horaire';
      END IF;
      IF why IS NOT NULL THEN
        INSERT INTO app_store_backups(key, value, nb_eleves, reason) VALUES (OLD.key, OLD.value, old_n, why);
        DELETE FROM app_store_backups WHERE key = OLD.key AND id NOT IN (
          SELECT id FROM app_store_backups WHERE key = OLD.key ORDER BY saved_at DESC LIMIT 300);
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- une copie ratée ne doit jamais bloquer l'enregistrement
  END;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS app_store_backups_trg ON public.app_store;
CREATE TRIGGER app_store_backups_trg BEFORE UPDATE ON public.app_store
FOR EACH ROW EXECUTE FUNCTION public.app_store_make_backup();