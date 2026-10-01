// Robô que lê o comprovante do PIX e, se bater valor + CNPJ, marca o RSVP como pago.
// À prova de erros: só confirma automaticamente com alta confiança; na dúvida, deixa para o Conselho.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const VALOR_MIN = 950;
const CNPJ = "69296264000130";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const json = (o: unknown) => new Response(JSON.stringify(o), { headers: { ...CORS, "Content-Type": "application/json" } });
  try {
    const { rsvp_id, url } = await req.json();
    if (!url) return json({ pago: false, motivo: "sem_url" });
    const KEY = Deno.env.get("ANTHROPIC_API_KEY");
    if (!KEY) return json({ pago: false, motivo: "robo_inativo" });

    const img = await fetch(url);
    const buf = new Uint8Array(await img.arrayBuffer());
    let bin = ""; for (let i = 0; i < buf.length; i++) bin += String.fromCharCode(buf[i]);
    const b64 = btoa(bin);
    const media = (img.headers.get("content-type") || "image/jpeg").split(";")[0];
    const isPdf = media.includes("pdf");

    const prompt = "Você recebe um comprovante de pagamento PIX brasileiro. Extraia e responda APENAS com JSON válido, sem texto extra, no formato {\"valor\": number, \"favorecido\": string, \"cnpj\": string, \"data\": string, \"confianca\": number}. valor em reais (número). cnpj só dígitos. confianca de 0 a 1 (quão certo você está de que é um comprovante PIX legítimo e legível).";
    const content: unknown[] = [
      isPdf
        ? { type: "document", source: { type: "base64", media_type: "application/pdf", data: b64 } }
        : { type: "image", source: { type: "base64", media_type: media, data: b64 } },
      { type: "text", text: prompt },
    ];
    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": KEY, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({ model: "claude-sonnet-5", max_tokens: 400, messages: [{ role: "user", content }] }),
    });
    const data = await resp.json();
    const txt = (data?.content?.[0]?.text || "").replace(/```json|```/g, "").trim();
    let dados: Record<string, unknown> = {};
    try { dados = JSON.parse(txt); } catch { dados = { raw: txt }; }

    const valor = Number(dados.valor) || 0;
    const cnpjLido = String(dados.cnpj || "").replace(/\D/g, "");
    const fav = String(dados.favorecido || "").toUpperCase();
    const conf = Number(dados.confianca) || 0;
    const bate = valor >= VALOR_MIN && conf >= 0.7 && (cnpjLido === CNPJ || fav.includes("COMMANDERIE"));

    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    if (rsvp_id) {
      await sb.from("evento_rsvp").update({
        comprovante_dados: dados,
        comprovante_status: bate ? "aprovado" : "revisar",
        ...(bate ? { status: "Confirmado" } : {}),
      }).eq("id", rsvp_id);
    }
    return json({ pago: bate, dados });
  } catch (e) {
    return json({ pago: false, motivo: "erro", erro: String(e) });
  }
});
