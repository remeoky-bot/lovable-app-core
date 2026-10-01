CREATE TABLE public.app_store (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.app_store TO anon, authenticated;
GRANT ALL ON public.app_store TO service_role;
ALTER TABLE public.app_store ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read store" ON public.app_store FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "insert store" ON public.app_store FOR INSERT TO anon, authenticated WITH CHECK (key = 'printania_db');
CREATE POLICY "update store" ON public.app_store FOR UPDATE TO anon, authenticated USING (key = 'printania_db') WITH CHECK (key = 'printania_db');