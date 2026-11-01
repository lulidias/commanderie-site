/* Números das redes sociais (só o Conselho: a tabela social_metricas tem RLS is_conselho).
   Uso: redesMetricas(elemento, sb, { modo: "compacto" | "completo" })
   O coletor (commanderie-social/publicador/metricas.py) grava uma linha por dia e plataforma a cada 3 horas. */
(function () {
  var CSS = '<style>'
    + '.rm{font-family:Arial,Helvetica,sans-serif;color:#2a2620}'
    + '.rm-pl{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:12px}'
    + '.rm-c{background:#fffdf7;border:1px solid #ddd0ad;border-radius:14px;padding:14px 16px}'
    + '.rm-c h4{margin:0;font:600 13px Arial;color:#1e2a56;display:flex;align-items:center;gap:7px}'
    + '.rm-c h4 svg{color:#b08a3a}'
    + '.rm-big{font:normal 34px Georgia,serif;color:#1e2a56;margin:6px 0 0;font-variant-numeric:tabular-nums}'
    + '.rm-big small{font:13px Arial;color:#8a8270;margin-left:6px}'
    + '.rm-l{display:flex;justify-content:space-between;gap:8px;font-size:13px;padding:5px 0;border-top:1px solid #efe6cf}'
    + '.rm-l:first-of-type{margin-top:8px}.rm-l span{color:#6d6656}.rm-l b{font-variant-numeric:tabular-nums;color:#2a2620}'
    + '.rm-v{font:600 11.5px Arial;margin-left:6px}.rm-up{color:#2f6b3a}.rm-dn{color:#8f1d24}.rm-eq{color:#8a8270}'
    + '.rm-off{color:#8a8270;font-size:13.5px;margin-top:10px;line-height:1.45}'
    + '.rm-gr{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:12px;margin-top:12px}'
    + '.rm-g h5{margin:0 0 8px;font:600 13px Arial;color:#1e2a56}.rm-g h5 span{font-weight:normal;color:#8a8270}'
    + '.rm-g svg{display:block;width:100%;height:auto}'
    + '.rm-ft{display:flex;flex-wrap:wrap;justify-content:space-between;gap:6px;margin-top:10px;font-size:12px;color:#8a8270}'
    + '.rm-ft a{color:#b08a3a;text-decoration:none}.rm-alerta{color:#8f1d24;font-weight:600}'
    + '</style>';
  var ICO = {
    ig: '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r=".8" fill="currentColor"/>',
    fb: '<path d="M14 8h3V4h-3a4 4 0 0 0-4 4v3H7v4h3v6h4v-6h3l1-4h-4V8z"/>',
    th: '<path d="M16.5 11.3c-.4-2.6-2.1-4-4.6-4-2.4 0-4 1.4-4.4 3.5M8 12.5c0 3.4 1.6 5.5 4.3 5.5 2.4 0 4.2-1.6 4.2-3.8 0-2-1.6-3.2-4-3.2-1.8 0-3 .9-3 2.2 0 1.1.9 1.9 2.2 1.9 2 0 3.1-1.7 3.1-4.6"/>'
  };
  function ico(n) { return '<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + ICO[n] + "</svg>"; }
  function n(v) { return v == null ? "—" : Number(v).toLocaleString("pt-BR"); }
  function iso(d) { return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0"); }
  function soma(L, campo, de, ate) { var s = 0, tem = false; L.forEach(function (r) { if (r.data >= de && r.data <= ate && r[campo] != null) { s += r[campo]; tem = true; } }); return tem ? s : null; }
  function variacao(a, b) {
    if (a == null || b == null) return "";
    if (b === 0) return a > 0 ? '<span class="rm-v rm-up">novo</span>' : "";
    var p = Math.round(100 * (a - b) / b);
    return '<span class="rm-v ' + (p > 0 ? "rm-up" : p < 0 ? "rm-dn" : "rm-eq") + '" title="Comparado com os 7 dias anteriores">' + (p > 0 ? "+" : "") + p + "%</span>";
  }
  function barras(L, campo, dias, cor) {
    var hoje = new Date(), pts = [];
    for (var i = dias - 1; i >= 0; i--) { var d = new Date(hoje); d.setDate(hoje.getDate() - i); var k = iso(d), r = L.filter(function (x) { return x.data === k; })[0]; pts.push({ d: d, v: r && r[campo] != null ? r[campo] : 0 }); }
    var max = Math.max.apply(null, pts.map(function (p) { return p.v; }).concat([1])), W = 560, H = 130, bw = W / dias;
    var s = '<svg viewBox="0 0 ' + W + " " + (H + 22) + '" role="img">';
    pts.forEach(function (p, i) {
      var h = Math.round((H - 16) * p.v / max), x = i * bw + 2, y = H - h;
      s += '<rect x="' + x.toFixed(1) + '" y="' + y + '" width="' + (bw - 4).toFixed(1) + '" height="' + Math.max(h, 1) + '" rx="2" fill="' + (p.v ? cor : "#e9e1cb") + '"><title>' + p.d.toLocaleDateString("pt-BR", { day: "numeric", month: "short" }) + ": " + p.v + "</title></rect>";
      if (p.v && p.v === max) s += '<text x="' + (x + (bw - 4) / 2).toFixed(1) + '" y="' + (y - 4) + '" text-anchor="middle" font-size="11" fill="#6d6656" font-family="Arial">' + p.v + "</text>";
      if (i % 7 === 0 || i === dias - 1) s += '<text x="' + (i === 0 ? 0 : i === dias - 1 ? W : x + (bw - 4) / 2).toFixed(1) + '" y="' + (H + 16) + '" text-anchor="' + (i === 0 ? "start" : i === dias - 1 ? "end" : "middle") + '" font-size="10.5" fill="#8a8270" font-family="Arial">' + p.d.toLocaleDateString("pt-BR", { day: "numeric", month: "numeric" }) + "</text>";
    });
    return s + '<line x1="0" y1="' + H + '" x2="' + W + '" y2="' + H + '" stroke="#ddd0ad"/></svg>';
  }
  window.redesMetricas = function (el, sb, op) {
    op = op || {}; var completo = op.modo === "completo";
    if (!el || !sb) return;
    el.innerHTML = '<span style="color:#8a8270;font-size:13px">Carregando números das redes…</span>';
    var hoje = new Date(), d30 = new Date(hoje); d30.setDate(hoje.getDate() - 35);
    sb.from("social_metricas").select("*").gte("data", iso(d30)).order("data").then(function (r) {
      if (r.error) { el.innerHTML = '<span class="rm-alerta" style="font-size:13px">Não foi possível ler os números das redes: ' + r.error.message + "</span>"; return; }
      var L = r.data || [];
      if (!L.length) { el.innerHTML = '<span style="color:#8a8270;font-size:13px">Ainda não há números coletados.</span>'; return; }
      var ig = L.filter(function (x) { return x.plataforma === "instagram"; }), fb = L.filter(function (x) { return x.plataforma === "facebook"; }), th = L.filter(function (x) { return x.plataforma === "threads"; });
      var h = iso(hoje), d = function (k) { var x = new Date(hoje); x.setDate(hoje.getDate() - k); return iso(x); };
      var a7 = d(6), b7 = d(13), b7f = d(7), a30 = d(29);
      var igU = ig.filter(function (x) { return x.seguidores != null; }).pop() || {}, fbU = fb.filter(function (x) { return x.seguidores != null; }).pop() || {}, thU = th.filter(function (x) { return x.seguidores != null; }).pop() || {};
      var nov7 = soma(ig, "novos_seguidores", a7, h), nov7p = soma(ig, "novos_seguidores", b7, b7f), nov30 = soma(ig, "novos_seguidores", a30, h);
      var com7 = soma(ig, "comentarios", a7, h), com7p = soma(ig, "comentarios", b7, b7f);
      var alc7 = soma(ig, "alcance", a7, h), alc7p = soma(ig, "alcance", b7, b7f);
      var int7 = soma(ig, "interacoes", a7, h), int7p = soma(ig, "interacoes", b7, b7f);
      var vis7 = soma(ig, "visitas_perfil", a7, h), vis7p = soma(ig, "visitas_perfil", b7, b7f);
      var html = CSS + '<div class="rm"><div class="rm-pl">'
        + '<div class="rm-c"><h4>' + ico("ig") + 'Instagram</h4><div class="rm-big">' + n(igU.seguidores) + "<small>seguidores</small></div>"
        + '<div class="rm-l"><span>Novos seguidores · 7 dias</span><b>' + (nov7 == null ? "—" : "+" + n(nov7)) + variacao(nov7, nov7p) + "</b></div>"
        + '<div class="rm-l"><span>Novos seguidores · 30 dias</span><b>' + (nov30 == null ? "—" : "+" + n(nov30)) + "</b></div>"
        + '<div class="rm-l"><span>Comentários · 7 dias</span><b>' + n(com7) + variacao(com7, com7p) + "</b></div>"
        + (completo ? '<div class="rm-l"><span>Interações · 7 dias</span><b>' + n(int7) + variacao(int7, int7p) + "</b></div>"
          + '<div class="rm-l"><span>Alcance somado · 7 dias</span><b>' + n(alc7) + variacao(alc7, alc7p) + "</b></div>"
          + '<div class="rm-l"><span>Visitas ao perfil · 7 dias</span><b>' + n(vis7) + variacao(vis7, vis7p) + "</b></div>"
          + '<div class="rm-l"><span>Posts publicados</span><b>' + n(igU.posts) + "</b></div>" : "")
        + "</div>"
        + '<div class="rm-c"><h4>' + ico("fb") + 'Facebook</h4><div class="rm-big">' + n(fbU.seguidores) + "<small>seguidores</small></div>"
        + '<div class="rm-l"><span>Posts publicados</span><b>' + n(fbU.posts) + "</b></div>"
        + '<div class="rm-off">Comentários e alcance do Facebook entram quando a Meta liberar a permissão de leitura da página.</div></div>'
        + (thU.data ? '<div class="rm-c"><h4>' + ico("th") + 'Threads</h4><div class="rm-big">' + n(thU.seguidores) + "<small>seguidores</small></div>"
          + '<div class="rm-l"><span>Respostas · 7 dias</span><b>' + n(soma(th, "comentarios", a7, h)) + "</b></div>"
          + '<div class="rm-l"><span>Interações · 7 dias</span><b>' + n(soma(th, "interacoes", a7, h)) + "</b></div>"
          + (completo ? '<div class="rm-l"><span>Visitas ao perfil · 7 dias</span><b>' + n(soma(th, "visitas_perfil", a7, h)) + "</b></div>" : "")
          + '<div class="rm-l"><span>Posts publicados</span><b>' + n(thU.posts) + "</b></div></div>"
          : '<div class="rm-c"><h4>' + ico("th") + 'Threads</h4><div class="rm-big">—</div><div class="rm-off">Os números aparecem aqui na próxima coleta.</div></div>')
        + "</div>";
      if (completo) html += '<div class="rm-gr">'
        + '<div class="rm-c rm-g"><h5>Novos seguidores por dia <span>· Instagram, 28 dias</span></h5>' + barras(ig, "novos_seguidores", 28, "#1e2a56") + "</div>"
        + '<div class="rm-c rm-g"><h5>Interações por dia <span>· curtidas, comentários, salvos e compartilhamentos</span></h5>' + barras(ig, "interacoes", 28, "#b08a3a") + "</div>"
        + "</div>";
      var ult = L.map(function (x) { return x.atualizado_em; }).filter(Boolean).sort().pop(), dt = ult ? new Date(ult) : null;
      var velho = !dt || (Date.now() - dt.getTime()) > 7 * 3600e3;
      var quando = dt ? (iso(dt) === h ? "hoje às " : dt.toLocaleDateString("pt-BR", { day: "numeric", month: "short" }) + " às ") + dt.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" }) : "nunca";
      html += '<div class="rm-ft"><span class="' + (velho ? "rm-alerta" : "") + '">' + (velho ? "⚠ A coleta automática está atrasada. Última: " + quando : "Atualizado " + quando + " · coleta automática a cada 3 horas") + "</span>"
        + (op.link ? '<a href="' + op.link + '">Ver todos os números →</a>' : "") + "</div></div>";
      el.innerHTML = html;
    });
  };
})();
