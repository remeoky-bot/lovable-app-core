import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "La Printania — Gestion Scolaire" },
      { name: "description", content: "Gestion scolaire de La Printania : élèves, notes, bulletins, finances et espace parents." },
      { property: "og:title", content: "La Printania — Gestion Scolaire" },
      { property: "og:description", content: "Gestion scolaire de La Printania : élèves, notes, bulletins, finances et espace parents." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <iframe
      src="/printania.html"
      title="La Printania"
      className="fixed inset-0 h-full w-full border-0"
    />
  );
}
