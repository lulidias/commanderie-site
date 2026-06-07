// enrich-dica — auto-preenche os dados de uma dica (restaurante/hotel/mercado/museu)
// em Bordeaux / Gironde a partir de nome + cidade, usando a Claude API.
// Segurança: só um comendador LOGADO pode chamar (validamos o usuário pelo token).
//
// Deploy:
//   supabase functions deploy enrich-dica --project-ref saotncritqxuchsvvnzi
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-... --project-ref saotncritqxuchsvvnzi
//
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  try {
    const auth = req.headers.get("Authorization") || "";
    const sb = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: auth } } },
    );
    const { data: { user } } = await sb.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const nome = (body?.nome || "").toString().trim();
    const cidade = (body?.cidade || "").toString().trim();
    if (!nome || !cidade) return json({ error: "nome + cidade required" }, 400);

    const key = Deno.env.get("ANTHROPIC_API_KEY");
    if (!key) return json({ error: "missing ANTHROPIC_API_KEY" }, 500);

    const prompt =
`Pesquise factualmente sobre o estabelecimento "${nome}" em ${cidade}, na região de Bordeaux / Gironde, França.

Retorne APENAS um JSON válido (nada antes ou depois). OMITA campos que não souber — NÃO invente dados.

{
  "categoria": "Categoria curta no estilo de um guia. Ex: 'Francesa Tradicional · Pato & Carnes', 'Hotel 5★ · Relais & Châteaux', 'Mercado · Gastronomia'",
  "tipo": "restaurante" | "hotel" | "mercado" | "museu",
  "endereco": "Endereço completo: rua, número, código postal, cidade",
  "telefone": "Telefone com código do país, formato '+33 5 56 00 00 00'",
  "site": "Site principal SEM https:// (ex: 'latupina.com')",
  "instagram": "Usuário do Instagram SEM @ (ex: 'latupina')",
  "preco": 1,
  "nota": "Distinção principal curta se houver. Ex: '1 Estrela Michelin', 'Relais & Châteaux'",
  "descricao": "Descrição em português do Brasil, 2 a 4 frases, tom de curadoria (elegante, conhecedor, factual, não publicitário). Mencione pratos icônicos, chef se relevante, contexto histórico se interessante."
}

Notas: "preco" é um número de 1 a 4 (1=econômico, 2=médio, 3=caro, 4=luxo). NÃO use hype publicitário nem aspas duplas dentro dos valores.`;

    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 1200,
        messages: [{ role: "user", content: prompt }],
      }),
    });
    if (!resp.ok) {
      const detail = await resp.text();
      return json({ error: "anthropic error", detail }, 502);
    }
    const data = await resp.json();
    const text = data?.content?.[0]?.text || "";
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return json({ error: "no json in response", text }, 502);
    let out: Record<string, unknown>;
    try {
      out = JSON.parse(match[0]);
    } catch (_e) {
      return json({ error: "invalid json from claude", text }, 502);
    }
    return json(out);
  } catch (e) {
    return json({ error: String((e as Error)?.message || e) }, 500);
  }
});
