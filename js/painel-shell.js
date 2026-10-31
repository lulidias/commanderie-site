/* Moldura do Painel do Conselho: menu lateral agrupado, contadores do que espera alguém,
   barra de topo com carimbo de atualização e busca (⌘K). Incluir no fim do <body> das telas do Conselho:
   <script src="js/painel-shell.js" data-esconder=".dtop,.dhead"></script>
   Em teste: só liga com ?novo=1 (fica lembrado neste navegador); ?novo=0 desliga. */
(function () {
  var me = document.currentScript;
  var q = new URLSearchParams(location.search);
  try {
    if (q.get("novo") === "1") localStorage.setItem("painelNovo", "1");
    if (q.get("novo") === "0") localStorage.removeItem("painelNovo");
  } catch (e) {}
  var ligado = false;
  try { ligado = localStorage.getItem("painelNovo") === "1"; } catch (e) {}
  if (window.PAINEL_SHELL_PADRAO) ligado = q.get("novo") !== "0";
  if (!ligado) return;

  var I = {
    hoje: '<path d="M3 11l9-7 9 7"/><path d="M5 10v10h14V10"/>',
    bi: '<path d="M4 20h16"/><path d="M7 20v-6M12 20v-11M17 20v-8"/>',
    gente: '<circle cx="9" cy="8" r="3.2"/><path d="M3 20c.6-3.4 3-5.2 6-5.2s5.4 1.8 6 5.2"/><path d="M16 4.6a3 3 0 0 1 0 6M21 20c-.4-2.6-1.8-4.2-3.8-4.8"/>',
    mais: '<circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/>',
    carta: '<path d="M4 6h16v12H4z"/><path d="M4 7l8 6 8-6"/>',
    taca: '<path d="M8 3h8l-1 6a3 3 0 0 1-6 0z"/><path d="M12 12v7M8 21h8"/>',
    cal: '<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
    moeda: '<circle cx="12" cy="12" r="9"/><path d="M14.5 9.2c-.6-.8-1.5-1.2-2.5-1.2-1.5 0-2.6.8-2.6 2s1.1 1.7 2.6 2 2.6.8 2.6 2-1.1 2-2.6 2c-1.1 0-2-.4-2.6-1.2M12 6.5V8M12 16v1.5"/>',
    doc: '<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M9.5 12h6M9.5 16h6"/>',
    caixa: '<path d="M3.5 7.5 12 3l8.5 4.5v9L12 21l-8.5-4.5z"/><path d="M3.5 7.5 12 12l8.5-4.5M12 12v9"/>',
    loja: '<path d="M6 7h12l-1 13H7L6 7z"/><path d="M9 7V5a3 3 0 0 1 6 0v2"/>',
    predio: '<path d="M4 21V8l8-5 8 5v13"/><path d="M9 21v-6h6v6"/>',
    selo: '<circle cx="12" cy="9" r="5"/><path d="M9 13.5 8 21l4-2 4 2-1-7.5"/>',
    insta: '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r=".8"/>',
    mapa: '<path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14M15 6v14"/>',
    aperto: '<path d="M3 12l4-4 5 3 5-3 4 4-9 7z"/>',
    email: '<path d="M3 6h18v12H3z"/><path d="M3 6l9 7 9-7"/>',
    tela: '<rect x="3" y="4" width="18" height="12" rx="1.5"/><path d="M8 20h8M12 16v4"/>',
    pincel: '<path d="M14 4l6 6-9 9H5v-6z"/>',
    lamp: '<path d="M9 18h6M10 21h4"/><path d="M12 3a6 6 0 0 0-3.5 10.9c.7.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z"/>'
  };
  var NAV = [
    { g: null, itens: [{ t: "Hoje", h: "painel-conselho.html", i: "hoje" }, { t: "Indicadores", h: "painel-bi.html", i: "bi" }] },
    { g: "Membros", itens: [
      { t: "Indicações", h: "painel-conselho.html?sec=indicacoes", i: "carta", c: "ind" },
      { t: "Novo membro", h: "painel-conselho.html?sec=novomembro", i: "mais" },
      { t: "Membros", h: "painel-membros.html", i: "gente" },
      { t: "Embaixadas", h: "painel-embaixadas.html", i: "predio" },
      { t: "Membro do Ano", h: "painel-membro-ano.html", i: "selo" },
      { t: "Disciple & Compagnon", h: "disciples-compagnons.html", i: "doc" }] },
    { g: "Eventos", itens: [{ t: "Eventos e Capítulos", h: "painel-conselho.html?sec=eventos", i: "cal", c: "ev" }] },
    { g: "Financeiro", itens: [
      { t: "Financeiro", h: "painel-conselho.html?sec=financeiro", i: "moeda", c: "fin" },
      { t: "Factures (€)", h: "factures.html", i: "doc" },
      { t: "Patrimônio e Estoque", h: "painel-estoque.html", i: "caixa" },
      { t: "Boutique", h: "painel-loja.html", i: "loja" }] },
    { g: "Importadoras", itens: [
      { t: "Importadoras Membros", h: "painel-importadoras.html", i: "taca" },
      { t: "Inscrições", h: "painel-conselho.html?sec=inscricoes", i: "carta", c: "insc" },
      { t: "Diplomas", h: "diploma-importadora.html?v=3", i: "selo" },
      { t: "Certificados MAPA", h: "certificados.html", i: "doc" }] },
    { g: "Comunicação", itens: [
      { t: "Redes sociais", h: "painel-redes.html", i: "insta", c: "redes" },
      { t: "Dicas de Bordeaux", h: "painel-dicas.html", i: "mapa" },
      { t: "Parceiros", h: "painel-parceiros.html", i: "aperto" },
      { t: "Modelos de E-mail", h: "painel-emails.html", i: "email" },
      { t: "Apresentações", h: "painel-apresentacoes.html", i: "tela" },
      { t: "Manual de Marca", h: "manual-marca.html", i: "pincel" }] },
    { g: "Conselho", itens: [{ t: "Melhorias", h: "painel-conselho.html?sec=melhorias", i: "lamp" }] }
  ];
  function ico(n) { return '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (I[n] || "") + "</svg>"; }
  function atual(h) {
    var a = h.split("?"), pag = a[0], sec = new URLSearchParams(a[1] || "").get("sec");
    var aqui = location.pathname.split("/").pop() || "index.html";
    if (aqui !== pag) return false;
    return (q.get("sec") || null) === (sec || null);
  }

  var css = ""
    + ":root{--ps-navy:#1e2a56;--ps-navy2:#16203f;--ps-gold:#b08a3a;--ps-gold2:#d6b66e;--ps-ivory:#f3ecd9;--ps-line:#ddd0ad;--ps-w:258px}"
    + "html.ps-on body{margin:0!important;background:var(--ps-ivory)}"
    + ".ps-side{position:fixed;top:0;left:0;bottom:0;width:var(--ps-w);background:linear-gradient(180deg,var(--ps-navy),var(--ps-navy2));color:#e9e4d4;display:flex;flex-direction:column;z-index:60;border-right:3px solid var(--ps-gold)}"
    + ".ps-marca{display:flex;align-items:center;gap:10px;padding:16px 16px 12px;text-decoration:none;color:#fff;border-bottom:1px solid rgba(214,182,110,.25)}"
    + ".ps-marca img{width:46px;height:auto}.ps-marca b{font:normal 17px/1.15 Georgia,serif;display:block}.ps-marca small{font:11px Arial;letter-spacing:.08em;color:var(--ps-gold2);text-transform:uppercase}"
    + ".ps-nav{overflow-y:auto;padding:8px 0 16px;flex:1}"
    + ".ps-g{font:600 10.5px Arial;letter-spacing:.16em;text-transform:uppercase;color:var(--ps-gold2);padding:16px 20px 6px}"
    + ".ps-i{display:flex;align-items:center;gap:11px;padding:8px 14px 8px 20px;margin:1px 8px;border-radius:9px;color:#e9e4d4;text-decoration:none;font:14px Arial}"
    + ".ps-i:hover{background:rgba(255,255,255,.07)}.ps-i:focus-visible{outline:2px solid var(--ps-gold2);outline-offset:-2px}"
    + ".ps-i.on{background:rgba(214,182,110,.16);color:#fff;box-shadow:inset 3px 0 0 var(--ps-gold2)}"
    + ".ps-i svg{flex:none;color:var(--ps-gold2)}.ps-i span{flex:1}"
    + ".ps-n{min-width:20px;padding:1px 6px;border-radius:10px;background:#8f1d24;color:#fff;font:600 11px Arial;text-align:center;font-variant-numeric:tabular-nums}"
    + ".ps-i.esc{display:none}"
    + ".ps-pe{padding:12px 16px;border-top:1px solid rgba(214,182,110,.25);font:12px Arial;color:#b9b4a4}.ps-pe a{color:var(--ps-gold2);text-decoration:none}"
    + ".ps-top{position:sticky;top:0;z-index:50;margin-left:var(--ps-w);background:var(--ps-navy);color:#fff;display:flex;align-items:center;gap:14px;padding:10px 22px;border-bottom:3px solid var(--ps-gold)}"
    + ".ps-top .ps-tt{font:normal 19px Georgia,serif}.ps-top .ps-tk{font:600 10.5px Arial;letter-spacing:.14em;color:var(--ps-gold2);text-transform:uppercase}"
    + ".ps-busca{margin-left:auto;display:flex;align-items:center;gap:6px;background:rgba(255,255,255,.08);border:1px solid rgba(214,182,110,.35);border-radius:999px;padding:6px 12px}"
    + ".ps-busca input{background:none;border:0;color:#fff;font:13px Arial;width:170px;outline:none}.ps-busca input::placeholder{color:#b9b4a4}.ps-busca kbd{font:11px Arial;color:#b9b4a4}"
    + ".ps-carimbo{display:flex;align-items:center;gap:7px;border:1px solid rgba(214,182,110,.45);border-radius:999px;padding:6px 12px;font:12px Arial;white-space:nowrap}"
    + ".ps-carimbo i{width:7px;height:7px;border-radius:50%;background:#7fc28a;display:inline-block}"
    + ".ps-main{margin-left:var(--ps-w);min-height:100vh}"
    + ".ps-burger{display:none;background:none;border:0;color:#fff;font-size:24px;cursor:pointer;line-height:1;padding:0 4px}"
    + ".ps-veu{display:none}"
    + "@media (max-width:900px){.ps-side{transform:translateX(-100%);transition:transform .2s}.ps-side.ab{transform:none}.ps-top,.ps-main{margin-left:0}.ps-burger{display:block}.ps-busca{display:none}.ps-carimbo span{display:none}.ps-veu.ab{display:block;position:fixed;inset:0;background:rgba(10,14,30,.5);z-index:55}}"
    + "@media (prefers-reduced-motion:reduce){.ps-side{transition:none}}";

  function montar() {
    document.documentElement.classList.add("ps-on");
    var st = document.createElement("style"); st.textContent = css; document.head.appendChild(st);
    (me && me.dataset.esconder ? me.dataset.esconder : ".dtop,.dhead").split(",").forEach(function (s) {
      document.querySelectorAll(s.trim()).forEach(function (e) { e.style.display = "none"; });
    });
    var titulo = (document.title.split("—")[0] || "").trim();
    var nav = NAV.map(function (gr) {
      return (gr.g ? '<div class="ps-g">' + gr.g + "</div>" : "") + gr.itens.map(function (it) {
        return '<a class="ps-i' + (atual(it.h) ? " on" : "") + '" href="' + it.h + '" data-busca="' + (it.t + " " + (gr.g || "")).toLowerCase() + '">' + ico(it.i) + "<span>" + it.t + "</span>" + (it.c ? '<b class="ps-n" data-c="' + it.c + '" hidden></b>' : "") + "</a>";
      }).join("");
    }).join("");
    var side = document.createElement("aside"); side.className = "ps-side"; side.setAttribute("aria-label", "Menu do Conselho");
    side.innerHTML = '<a class="ps-marca" href="painel-conselho.html"><img src="img/brasao-escuro.png" alt=""><div><b>Painel do Conselho</b><small>Commanderie do Brasil</small></div></a>'
      + '<nav class="ps-nav">' + nav + "</nav>"
      + '<div class="ps-pe"><a href="index.html?painel=1">← Painel do Comendador</a></div>';
    var top = document.createElement("header"); top.className = "ps-top";
    var grupo = ""; NAV.forEach(function (gr) { gr.itens.forEach(function (it) { if (atual(it.h)) grupo = gr.g || "Conselho"; }); });
    top.innerHTML = '<button class="ps-burger" aria-label="Abrir menu">☰</button>'
      + "<div><div class=\"ps-tk\">" + (grupo || "Conselho Diretor") + '</div><div class="ps-tt">' + (titulo || "Painel do Conselho") + "</div></div>"
      + '<label class="ps-busca"><input type="search" placeholder="Ir para…" aria-label="Buscar no menu"><kbd>⌘K</kbd></label>'
      + '<div class="ps-carimbo" title="Hora em que os dados desta tela foram carregados"><i></i><span>Dados atualizados às </span><b class="ps-hora"></b></div>';
    var main = document.createElement("div"); main.className = "ps-main";
    var veu = document.createElement("div"); veu.className = "ps-veu";
    while (document.body.firstChild) {
      var n = document.body.firstChild;
      if (n === me || (n.tagName === "SCRIPT")) { document.body.removeChild(n); main.appendChild(n); continue; }
      main.appendChild(n);
    }
    document.body.appendChild(side); document.body.appendChild(veu); document.body.appendChild(top); document.body.appendChild(main);
    var agora = new Date(); top.querySelector(".ps-hora").textContent = agora.toLocaleDateString("pt-BR") + " " + agora.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" });
    var bg = top.querySelector(".ps-burger");
    function abre(v) { side.classList.toggle("ab", v); veu.classList.toggle("ab", v); }
    bg.onclick = function () { abre(!side.classList.contains("ab")); }; veu.onclick = function () { abre(false); };
    var inp = top.querySelector("input");
    inp.oninput = function () {
      var t = inp.value.trim().toLowerCase();
      side.querySelectorAll(".ps-i").forEach(function (a) { a.classList.toggle("esc", !!t && a.dataset.busca.indexOf(t) < 0); });
      side.querySelectorAll(".ps-g").forEach(function (g) { g.style.display = t ? "none" : ""; });
    };
    inp.onkeydown = function (e) { if (e.key === "Enter") { var a = side.querySelector(".ps-i:not(.esc)"); if (a) location.href = a.href; } if (e.key === "Escape") { inp.value = ""; inp.oninput(); inp.blur(); } };
    document.addEventListener("keydown", function (e) { if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); inp.focus(); } });
    hojeHTML();
    contadores();
  }


  // Página inicial "Hoje": o que precisa de atenção, próximo Capítulo e o que sai nas redes hoje
  function hojeHTML() {
    var aqui = location.pathname.split("/").pop() || "";
    var m = document.getElementById("menu");
    if (aqui !== "painel-conselho.html" || q.get("sec") || !m) return;
    var box = document.createElement("div"); box.className = "ps-hoje";
    box.innerHTML = '<style>.ps-hoje{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px;margin:6px 0 22px}'
      + '.ps-cx{background:#fffdf7;border:1px solid #ddd0ad;border-radius:14px;padding:16px 18px}.ps-cx h2{font:normal 18px Georgia,serif;color:#1e2a56;margin:0 0 10px}'
      + '.ps-cx a.l{display:flex;justify-content:space-between;gap:10px;padding:8px 0;border-top:1px solid #efe6cf;color:#2a2620;text-decoration:none;font:14px Arial}.ps-cx a.l:first-of-type{border-top:0}'
      + '.ps-cx a.l b{background:#8f1d24;color:#fff;border-radius:10px;padding:1px 8px;font:600 12px Arial}.ps-cx .ok{color:#2f6b3a;font:14px Arial}.ps-cx .s{color:#8a8270;font:12px Arial}'
      + '.ps-todos{font:600 10.5px Arial;letter-spacing:.16em;text-transform:uppercase;color:#b08a3a;margin:6px 0 10px}</style>'
      + '<div class="ps-cx"><h2>Precisa de atenção</h2><div id="psAt"><span class="s">Carregando…</span></div></div>'
      + '<div class="ps-cx"><h2>Próximo Capítulo</h2><div id="psCap"><span class="s">Carregando…</span></div></div>'
      + '<div class="ps-cx"><h2>Hoje nas redes</h2><div id="psRedes"><span class="s">Carregando…</span></div></div>';
    m.parentNode.insertBefore(box, m);
    var tt = document.createElement("div"); tt.className = "ps-todos"; tt.textContent = "Todos os atalhos"; m.parentNode.insertBefore(tt, m);
    document.addEventListener("painel:pendencias", function (e) {
      var d = e.detail, L = [
        [d.indicacoes, "Indicações a aprovar", "painel-conselho.html?sec=indicacoes"],
        [d.comprovantes, "Comprovantes de anuidade", "painel-conselho.html?sec=financeiro"],
        [d.rsvp, "Comprovantes de eventos a conferir", "painel-conselho.html?sec=eventos"],
        [d.fotos, "Fotos de eventos para aprovar", "painel-conselho.html?sec=eventos"],
        [d.inscricoes, "Inscrições de importadoras", "painel-conselho.html?sec=inscricoes"],
        [d.redes_revisar, "Posts para revisar", "painel-redes.html"],
        [d.redes_pedidos, "Pedidos ao Claude em aberto", "painel-redes.html"]].filter(function (x) { return x[0] > 0; });
      document.getElementById("psAt").innerHTML = L.length ? L.map(function (x) { return '<a class="l" href="' + x[2] + '"><span>' + x[1] + "</span><b>" + x[0] + "</b></a>"; }).join("") : '<span class="ok">Tudo em dia.</span>';
    });
    var sb = window.sb; if (!sb) return;
    sb.from("eventos").select("id,numero,titulo,data,local").eq("tipo", "Capítulo").eq("realizado", false).order("data", { ascending: true }).limit(1).then(function (r) {
      var e = r.data && r.data[0], el = document.getElementById("psCap");
      if (!e) { el.innerHTML = '<span class="s">Nenhum Capítulo marcado.</span>'; return; }
      var dt = new Date(e.data + "T12:00:00"), dias = Math.round((dt - new Date()) / 864e5);
      el.innerHTML = '<a class="l" href="painel-conselho.html?sec=eventos"><span>' + (e.numero ? "Capítulo " + e.numero + " · " : "") + (e.titulo || "") + '<br><span class="s">' + dt.toLocaleDateString("pt-BR") + (e.local ? " · " + e.local : "") + "</span></span><b style=\"background:#1e2a56\">" + (dias >= 0 ? "em " + dias + " d" : "hoje") + "</b></a>";
    });
    var ini = new Date(); ini.setHours(0, 0, 0, 0); var fim = new Date(ini.getTime() + 864e5);
    sb.from("social_posts").select("titulo,quando,tipo,status").gte("quando", ini.toISOString()).lt("quando", fim.toISOString()).neq("status", "recusado").order("quando").then(function (r) {
      var el = document.getElementById("psRedes"), L = (r.data || []);
      el.innerHTML = L.length ? L.map(function (p) { return '<a class="l" href="painel-redes.html"><span>' + new Date(p.quando).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" }) + " · " + p.titulo + '</span><span class="s">' + (p.status === "publicado" ? "publicado" : p.status === "pausado" ? "pausado" : "agendado") + "</span></a>"; }).join("") : '<span class="s">Nada programado para hoje.</span>';
    });
  }

  async function contadores() {
    var sb = window.sb;
    if (!sb && window.supabase) sb = window.supabase.createClient("https://yvdkaycwtulqjnvlpgvy.supabase.co", "sb_publishable_v3QZOo0NYLpOAk9p5JBNjQ_r0vb-Zjd");
    if (!sb) return;
    function conta(p) { return p.then(function (r) { return r.error ? 0 : (r.count || 0); }, function () { return 0; }); }
    var head = { count: "exact", head: true };
    var r = await Promise.all([
      conta(sb.from("indicacoes").select("id", head).in("status", ["Aguardando avais", "Avalizada", "Aguardando aprovação"])),
      conta(sb.from("anuidade_comprovantes").select("id", head).not("status", "in", "(aprovado,conferido,recusado)")),
      conta(sb.from("importadora_inscricoes").select("id", head).eq("status", "Nova")),
      conta(sb.from("evento_fotos_propostas").select("id", head).eq("status", "pendente")),
      conta(sb.from("evento_rsvp").select("id", head).eq("comprovante_status", "revisar")),
      conta(sb.from("social_posts").select("id", head).eq("revisao", "pendente").in("status", ["aprovado", "pausado", "erro"]).neq("tipo", "story")),
      conta(sb.from("social_pedidos").select("id", head).eq("status", "aberto"))
    ]);
    var n = { ind: r[0], fin: r[1] + r[4], insc: r[2], ev: r[3], redes: r[5] + r[6] };
    window.PAINEL_PENDENCIAS = { indicacoes: r[0], comprovantes: r[1], inscricoes: r[2], fotos: r[3], rsvp: r[4], redes_revisar: r[5], redes_pedidos: r[6] };
    document.querySelectorAll(".ps-n").forEach(function (b) { var v = n[b.dataset.c] || 0; b.hidden = !v; b.textContent = v; });
    document.dispatchEvent(new CustomEvent("painel:pendencias", { detail: window.PAINEL_PENDENCIAS }));
  }

  // Só para o Conselho: confirma no banco antes de montar a moldura (visitante e Comendador comum não veem nada)
  async function talvez() {
    try {
      var sb = window.sb || (window.supabase && window.supabase.createClient("https://yvdkaycwtulqjnvlpgvy.supabase.co", "sb_publishable_v3QZOo0NYLpOAk9p5JBNjQ_r0vb-Zjd"));
      if (!sb) return;
      var u = (await sb.auth.getUser()).data.user; if (!u) return;
      var r = await sb.rpc("is_conselho"); if (r.error || !r.data) return;
      montar();
    } catch (e) {}
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", talvez); else talvez();
})();
