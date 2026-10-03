// Robô: lê comprovante PIX e acumula pagamentos até fechar o valor devido.
// Valores válidos: R$ 950 (Comendador), R$ 1.250 (convidado à parte), R$ 2.200 (os dois juntos).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const V_COMENDADOR = 950, V_CONVIDADO = 1250, V_TOTAL = 2200, CNPJ = "69296264000130";
const VALIDOS = [V_COMENDADOR, V_CONVIDADO, V_TOTAL];
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const json = (o: unknown) => new Response(JSON.stringify(o), { headers: { ...CORS, "Content-Type": "application/json" } });
  try {
    const { rsvp_id, url } = await req.json();
    if (!url) return json({ pago: false, motivo: "sem_url" });
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    let esperado = V_COMENDADOR, temConvidado = false, jaPago = 0, externo = false, quem = "";
    if (rsvp_id) {
      const { data: rr } = await sb.from("evento_rsvp")
        .select("convidado_nome,pago_valor,categoria,evento_id,user_id").eq("id", rsvp_id).maybeSingle();
      // O convidado externo (importador que ainda não é Comendador) paga o
      // preço de convidado e vem SOZINHO — o nome dele está em convidado_nome,
      // que no caso do Comendador significa outra coisa: o acompanhante.
      // Sem esta distinção o robô esperaria R$ 2.200 dele e nunca aprovaria.
      if (rr && rr.categoria === "convidado-externo") { externo = true; esperado = V_CONVIDADO; }
      else if (rr && rr.convidado_nome && String(rr.convidado_nome).trim()) { temConvidado = true; esperado = V_TOTAL; }
      jaPago = Number(rr?.pago_valor) || 0;
      quem = String(rr?.convidado_nome || "").trim();
    }
    const KEY = Deno.env.get("ANTHROPIC_API_KEY");
    if (!KEY) return json({ pago: false, motivo: "robo_inativo", esperado });

    const img = await fetch(url);
    const buf = new Uint8Array(await img.arrayBuffer());
    let bin = ""; for (let i = 0; i < buf.length; i++) bin += String.fromCharCode(buf[i]);
    const b64 = btoa(bin);
    const media = (img.headers.get("content-type") || "image/jpeg").split(";")[0];
    const isPdf = media.includes("pdf");
    const prompt = "Comprovante de pagamento PIX brasileiro. Responda APENAS JSON válido: {\"valor\": number, \"favorecido\": string, \"cnpj\": string, \"data\": string, \"confianca\": number}. valor em reais; cnpj só dígitos; confianca 0..1.";
    const content: unknown[] = [
      isPdf ? { type: "document", source: { type: "base64", media_type: "application/pdf", data: b64 } }
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
    const destinoOk = (cnpjLido === CNPJ || fav.includes("COMMANDERIE"));
    const valorPlausivel = VALIDOS.some((v) => Math.abs(valor - v) <= 1);
    const valido = conf >= 0.7 && destinoOk && valorPlausivel;
    const novoPago = jaPago + (valido ? valor : 0);
    const full = novoPago >= esperado - 1;
    (dados as any).esperado = esperado; (dados as any).pago_valor = novoPago; (dados as any).valido = valido;

    if (rsvp_id) {
      const upd: Record<string, unknown> = {
        comprovante_dados: dados,
        pago_valor: novoPago,
        comprovante_status: valido ? (full ? "aprovado" : "parcial") : "revisar",
      };
      if (full) upd.status = "Confirmado";
      await sb.from("evento_rsvp").update(upd).eq("id", rsvp_id);

      // A contabilidade entra sozinha quando o pagamento fecha. Antes isto era
      // lançado à mão depois, pelo Conselho — e o que se lança à mão depois
      // é o que fica para trás. O índice único por `fonte` garante que rodar
      // o robô de novo não duplica a receita. (03/10/2026)
      if (full) {
        const rotulo = externo
          ? `Jantar de 1 Ano — convidado ${quem || "externo"}`
          : `Jantar de 1 Ano — ${quem ? "Comendador + convidado" : "Comendador"}`;
        await sb.rpc("lancar_receita_rsvp", {
          p_rsvp: rsvp_id, p_valor: novoPago, p_descricao: rotulo,
        });
      }
    }
    return json({ pago: full, parcial: valido && !full, valor, esperado, pago_valor: novoPago, dados });
  } catch (e) {
    return json({ pago: false, motivo: "erro", erro: String(e) });
  }
});
