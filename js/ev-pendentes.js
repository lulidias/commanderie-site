/* Quem ainda não pagou cada evento, lido das inscrições (evento_rsvp).
   Usado pela Prestação de contas (painel-conselho e simulador-evento) para o
   "ainda não pagaram" acompanhar sozinho o que o Conselho marca no evento.
   EVPEND.carregar(sb) -> {porId:{<evento_id>:{id,titulo,data,mp,cp,nomes:[]}}, porData:{<aaaa-mm-dd>:[...]}}
   EVPEND.daPrest(dados,data) -> o evento ligado à prestação (evento_id salvo ou o único evento na mesma data) */
window.EVPEND = (function () {
  var R = null;
  function vazio(s) { return !(s && ("" + s).trim()); }
  async function carregar(sb) {
    var e = await sb.from("eventos").select("id,titulo,data");
    var r = await sb.from("evento_rsvp").select("id,evento_id,user_id,categoria,status,convidado_nome");
    var m = await sb.from("membros").select("user_id,nome");
    if (e.error || r.error) { R = null; return null; }
    var nomes = {}; ((m && m.data) || []).forEach(function (x) { if (x.user_id) nomes[x.user_id] = x.nome; });
    var porId = {}, porData = {};
    (e.data || []).forEach(function (ev) {
      var o = { id: ev.id, titulo: ev.titulo, data: ("" + (ev.data || "")).slice(0, 10), mp: 0, cp: 0, nomes: [] };
      porId[ev.id] = o; (porData[o.data] = porData[o.data] || []).push(o);
    });
    (r.data || []).forEach(function (x) {
      var o = porId[x.evento_id]; if (!o) return;
      var st = x.status || "", cat = x.categoria || "";
      var membro = !cat || cat === "membro-sem-acesso";
      if (membro && st === "Aguardando pagamento") {
        o.mp++; o.nomes.push(nomes[x.user_id] || "Comendador");
        if (!vazio(x.convidado_nome)) { o.cp++; o.nomes.push(x.convidado_nome + " (convidado)"); }
      } else if ((cat === "convidado-externo" || cat === "futuro-membro") && st !== "Confirmado" && st !== "Recusado") {
        if (cat === "futuro-membro") o.mp++; else o.cp++;
        o.nomes.push(vazio(x.convidado_nome) ? "Convidado" : x.convidado_nome);
      }
    });
    R = { porId: porId, porData: porData };
    return R;
  }
  function daPrest(d, data) {
    if (!R || !d) return null;
    if (d.evento_id && R.porId[d.evento_id]) return R.porId[d.evento_id];
    var L = R.porData[("" + (data || d.data || "")).slice(0, 10)] || [];
    return L.length === 1 ? L[0] : null;
  }
  function todos() { return R ? R.porId : {}; }
  return { carregar: carregar, daPrest: daPrest, _todos: todos };
})();
