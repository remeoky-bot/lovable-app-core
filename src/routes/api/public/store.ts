import { createFileRoute } from "@tanstack/react-router";
import { neon } from "@neondatabase/serverless";

// Stockage de l'application Printania dans la base PostgreSQL Neon de l'utilisateur.
const ALLOWED_KEY = "printania_db";

function db() {
  const url = process.env["NEON_DATABASE_URL"];
  if (!url) throw new Error("NEON_DATABASE_URL manquant");
  return neon(url);
}

let ready: Promise<unknown> | undefined;
function ensureTable(sql: ReturnType<typeof db>) {
  ready ??= sql`CREATE TABLE IF NOT EXISTS app_store (key text PRIMARY KEY, value jsonb NOT NULL, updated_at timestamptz NOT NULL DEFAULT now())`;
  return ready;
}

export const Route = createFileRoute("/api/public/store")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const key = new URL(request.url).searchParams.get("key");
        if (key !== ALLOWED_KEY) return new Response("Bad key", { status: 400 });
        const sql = db();
        await ensureTable(sql);
        const rows = (await sql`SELECT value FROM app_store WHERE key = ${key}`) as { value: unknown }[];
        if (!rows.length) return new Response("Not found", { status: 404 });
        return Response.json({ value: rows[0]!.value });
      },
      POST: async ({ request }) => {
        const body = (await request.json()) as { key?: string; value?: unknown };
        if (body.key !== ALLOWED_KEY || body.value == null) return new Response("Bad request", { status: 400 });
        const sql = db();
        await ensureTable(sql);
        await sql`INSERT INTO app_store(key, value) VALUES (${body.key}, ${JSON.stringify(body.value)}::jsonb)
          ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()`;
        return new Response(null, { status: 204 });
      },
    },
  },
});
