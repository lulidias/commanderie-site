// Primeiro acesso por LINK MÁGICO (sem senha). Só envia para e-mail que já é comendador na lista.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const REDIRECT = "https://commanderiedebordeaux.com.br/?ligar=1";
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const json = (o: unknown) => new Response(JSON.stringify(o), { headers: { ...CORS, "Content-Type": "application/json" } });
  try {
    const { email } = await req.json();
    const em = String(email || "").trim().toLowerCase();
    if (!em || em.indexOf("@") < 1) return json({ ok: false, motivo: "email_invalido" });
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: m } = await sb.from("membros").select("nome").ilike("email", em).maybeSingle();
    if (!m) return json({ ok: false, motivo: "nao_encontrado" });
    // garante o usuario de auth (sem senha, email confirmado)
    try { await sb.auth.admin.createUser({ email: em, email_confirm: true }); } catch (_e) { /* ja existe */ }
    const { data: lk, error: le } = await sb.auth.admin.generateLink({ type: "magiclink", email: em, options: { redirectTo: REDIRECT } });
    const link = lk?.properties?.action_link;
    if (le || !link) return json({ ok: false, motivo: "falha_link", erro: String(le?.message || "") });
    const { error: ee } = await sb.rpc("enviar_modelo", { p_to: em, p_chave: "primeiro_acesso_magico", v: { nome: m.nome, link } });
    if (ee) return json({ ok: false, motivo: "falha_envio", erro: ee.message });
    return json({ ok: true, email: em });
  } catch (e) {
    return json({ ok: false, motivo: "erro", erro: String(e) });
  }
});
