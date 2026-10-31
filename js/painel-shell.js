/* Moldura do Painel do Conselho: menu lateral agrupado, contadores do que espera alguém,
   barra de topo com carimbo de atualização e busca (⌘K). Incluir no fim do <body> das telas do Conselho:
   <script src="js/painel-shell.js" data-esconder=".dtop,.dhead"></script>
   Ligada para todo o Conselho; ?novo=0 mostra o formato antigo. */
(function () {
  var me = document.currentScript;
  var q = new URLSearchParams(location.search);
  // Padrão para todo o Conselho desde 31/10/2026 (?novo=0 mostra o formato antigo nesta visita)
  var ligado = q.get("novo") !== "0";
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


  // Página inicial "Hoje": saudação, números do dia, o que espera alguém, próximo Capítulo, redes de hoje (miniaturas) e atalhos
  function hojeHTML() {
    var aqui = location.pathname.split("/").pop() || "";
    var m = document.getElementById("menu");
    if (aqui !== "painel-conselho.html" || q.get("sec") || !m) return;
    m.style.display = "none";   // a grade antiga de 22 cartões sai: o menu lateral já leva a tudo
    var cab = document.querySelector(".dhead"); if (cab) cab.style.display = "none";
    var h = new Date().getHours(), oi = h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite";
    var dia = new Date().toLocaleDateString("pt-BR", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
    var box = document.createElement("div"); box.className = "hj";
    box.innerHTML = '<style>'
      + '.hj{max-width:1120px;margin:0 auto;padding:26px 26px 60px;font-family:Arial,Helvetica,sans-serif;color:#2a2620}'
      + '.hj-oi{display:flex;flex-wrap:wrap;align-items:flex-end;justify-content:space-between;gap:10px;margin-bottom:20px}'
      + '.hj-oi h1{font:normal 32px/1.15 Georgia,serif;color:#1e2a56;margin:0}.hj-oi p{margin:4px 0 0;color:#8a8270;font-size:13.5px;text-transform:capitalize}'
      + '.hj-lema{font:italic 15px Georgia,serif;color:#b08a3a}'
      + '.hj-num{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;margin-bottom:18px}'
      + '.hj-n{background:#fffdf7;border:1px solid #ddd0ad;border-radius:14px;padding:14px 16px;text-decoration:none;color:inherit;display:block}'
      + '.hj-n:hover{border-color:#b08a3a}.hj-n small{display:block;font:600 10.5px Arial;letter-spacing:.14em;text-transform:uppercase;color:#b08a3a}'
      + '.hj-n b{display:block;font:normal 30px Georgia,serif;color:#1e2a56;margin-top:4px;font-variant-numeric:tabular-nums}.hj-n span{font-size:12.5px;color:#8a8270}'
      + '.hj-n .barra{height:5px;background:#efe6cf;border-radius:3px;margin-top:8px;overflow:hidden}.hj-n .barra i{display:block;height:100%;background:#b08a3a}'
      + '.hj-2{display:grid;grid-template-columns:1.1fr .9fr;gap:14px;margin-bottom:14px}@media(max-width:820px){.hj-2{grid-template-columns:1fr}}'
      + '.hj-cx{background:#fffdf7;border:1px solid #ddd0ad;border-radius:14px;padding:16px 18px}.hj-cx h2{font:normal 19px Georgia,serif;color:#1e2a56;margin:0 0 10px;display:flex;justify-content:space-between;align-items:baseline}'
      + '.hj-cx h2 a{font:12.5px Arial;color:#b08a3a;text-decoration:none}'
      + '.hj-a{display:flex;align-items:center;gap:12px;padding:10px 0;border-top:1px solid #efe6cf;text-decoration:none;color:#2a2620;font-size:14.5px}.hj-a:first-of-type{border-top:0}'
      + '.hj-a span{flex:1}.hj-a b{background:#8f1d24;color:#fff;border-radius:11px;padding:2px 9px;font:600 12px Arial}.hj-a:hover span{color:#1e2a56;text-decoration:underline}'
      + '.hj-ok{display:flex;align-items:center;gap:10px;color:#2f6b3a;font-size:15px;padding:8px 0}'
      + '.hj-cap{display:flex;gap:16px;align-items:center}.hj-cal{flex:none;width:76px;text-align:center;border:1px solid #ddd0ad;border-radius:12px;overflow:hidden;background:#fff}'
      + '.hj-cal i{display:block;background:#8f1d24;color:#fff;font:600 11px Arial;letter-spacing:.1em;text-transform:uppercase;padding:4px 0;font-style:normal}.hj-cal b{display:block;font:normal 32px Georgia,serif;color:#1e2a56;padding:4px 0 6px}'
      + '.hj-cap h3{font:normal 18px Georgia,serif;color:#1e2a56;margin:0}.hj-cap p{margin:3px 0 0;color:#8a8270;font-size:13px}'
      + '.hj-bt{display:inline-block;margin-top:12px;background:#1e2a56;color:#fff;border-radius:9px;padding:8px 14px;font-size:13px;text-decoration:none}'
      + '.hj-redes{display:flex;gap:12px;overflow-x:auto;padding-bottom:4px}.hj-p{flex:none;width:150px;text-decoration:none;color:inherit}'
      + '.hj-p .im{width:150px;height:188px;border-radius:10px;background:#e9e1cb center/cover no-repeat;position:relative;overflow:hidden}'
      + '.hj-p .im video{width:100%;height:100%;object-fit:cover}.hj-p .tp{position:absolute;left:6px;top:6px;background:rgba(20,28,60,.82);color:#fff;font-size:10.5px;padding:2px 7px;border-radius:7px}'
      + '.hj-p .hr{position:absolute;right:6px;bottom:6px;background:#fffdf7;color:#1e2a56;font:600 11.5px Arial;padding:2px 7px;border-radius:7px}'
      + '.hj-p .ok{background:#2f6b3a;color:#fff}'
      + '.hj-at{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin-top:14px}'
      + '.hj-at a{display:flex;align-items:center;gap:9px;background:#1e2a56;color:#f3ecd9;border-radius:12px;padding:12px 14px;text-decoration:none;font-size:14px}.hj-at a:hover{background:#26346a}.hj-at svg{color:#d6b66e;flex:none}'
      + '.hj .s{color:#8a8270;font-size:13px}</style>'
      + '<div class="hj-oi"><div><h1 id="hjOi">' + oi + '</h1><p>' + dia + '</p></div><div class="hj-lema">Bordeaux, toujours Bordeaux.</div></div>'
      + '<div class="hj-num">'
      +   '<a class="hj-n" href="painel-membros.html"><small>Membros</small><b id="hjMem">—</b><span id="hjMemS">&nbsp;</span></a>'
      +   '<a class="hj-n" href="painel-conselho.html?sec=financeiro"><small>Anuidades em dia</small><b id="hjAn">—</b><span id="hjAnS">&nbsp;</span><div class="barra"><i id="hjAnB" style="width:0"></i></div></a>'
      +   '<a class="hj-n" href="painel-conselho.html?sec=eventos"><small>Próximo Capítulo</small><b id="hjCapN">—</b><span id="hjCapS">&nbsp;</span></a>'
      +   '<a class="hj-n" href="painel-redes.html"><small>Redes nesta semana</small><b id="hjSem">—</b><span>posts no feed</span></a>'
      + '</div>'
      + '<div class="hj-2"><div class="hj-cx"><h2>Precisa de atenção</h2><div id="psAt"><span class="s">Carregando…</span></div></div>'
      +   '<div class="hj-cx"><h2>Próximo Capítulo <a href="painel-conselho.html?sec=eventos">Eventos →</a></h2><div id="psCap"><span class="s">Carregando…</span></div></div></div>'
      + '<div class="hj-cx"><h2>Hoje nas redes <a href="painel-redes.html">Agenda completa →</a></h2><div id="psRedes" class="hj-redes"><span class="s">Carregando…</span></div></div>'
      + '<div class="hj-at">'
      +   '<a href="painel-conselho.html?sec=indicacoes">' + ico("carta") + 'Indicações</a>'
      +   '<a href="painel-conselho.html?sec=eventos">' + ico("cal") + 'Eventos</a>'
      +   '<a href="painel-conselho.html?sec=financeiro">' + ico("moeda") + 'Financeiro</a>'
      +   '<a href="painel-membros.html">' + ico("gente") + 'Membros</a>'
      +   '<a href="painel-redes.html">' + ico("insta") + 'Redes sociais</a>'
      +   '<a href="painel-bi.html">' + ico("bi") + 'Indicadores</a>'
      + '</div>';
    m.parentNode.insertBefore(box, m);
    document.addEventListener("painel:pendencias", function (e) {
      var d = e.detail, L = [
        [d.indicacoes, "Indicações a aprovar", "painel-conselho.html?sec=indicacoes"],
        [d.comprovantes, "Comprovantes de anuidade a conferir", "painel-conselho.html?sec=financeiro"],
        [d.rsvp, "Comprovantes de eventos a conferir", "painel-conselho.html?sec=eventos"],
        [d.fotos, "Fotos de eventos para aprovar", "painel-conselho.html?sec=eventos"],
        [d.inscricoes, "Inscrições de importadoras", "painel-conselho.html?sec=inscricoes"],
        [d.redes_revisar, "Posts das redes para revisar", "painel-redes.html"],
        [d.redes_pedidos, "Pedidos ao Claude em aberto", "painel-redes.html"]].filter(function (x) { return x[0] > 0; });
      document.getElementById("psAt").innerHTML = L.length ? L.map(function (x) { return '<a class="hj-a" href="' + x[2] + '"><span>' + x[1] + "</span><b>" + x[0] + "</b></a>"; }).join("") : '<div class="hj-ok">✓ Tudo em dia. Nada esperando por você.</div>';
    });
    var sb = window.sb; if (!sb) return;
    sb.auth.getUser().then(function (u) {
      var id = u.data && u.data.user && u.data.user.id; if (!id) return;
      sb.from("membros").select("nome").eq("user_id", id).maybeSingle().then(function (r) { var n = r.data && r.data.nome ? String(r.data.nome).split(" ")[0] : ""; if (n) document.getElementById("hjOi").textContent = oi + ", " + n; });
    });
    sb.from("membros").select("anuidade_paga").then(function (r) {
      var L = r.data || []; if (!L.length) return;
      var pag = L.filter(function (x) { return !!x.anuidade_paga; }).length;
      document.getElementById("hjMem").textContent = L.length; document.getElementById("hjMemS").textContent = "Comendadores no cadastro";
      document.getElementById("hjAn").textContent = Math.round(100 * pag / L.length) + "%"; document.getElementById("hjAnS").textContent = pag + " de " + L.length + " com a anuidade paga";
      document.getElementById("hjAnB").style.width = Math.round(100 * pag / L.length) + "%";
    });
    sb.from("eventos").select("id,numero,titulo,data,local").eq("tipo", "Capítulo").eq("realizado", false).gte("data", new Date().toISOString().slice(0, 10)).order("data", { ascending: true }).limit(1).then(function (r) {
      var e = r.data && r.data[0], el = document.getElementById("psCap");
      if (!e) { el.innerHTML = '<span class="s">Nenhum Capítulo marcado. Crie o próximo em Eventos.</span><br><a class="hj-bt" href="painel-conselho.html?sec=eventos">Criar evento</a>'; document.getElementById("hjCapN").textContent = "—"; document.getElementById("hjCapS").textContent = "nenhum marcado"; return; }
      var dt = new Date(e.data + "T12:00:00"), dias = Math.max(0, Math.round((dt - new Date()) / 864e5));
      document.getElementById("hjCapN").textContent = dias === 0 ? "Hoje" : dias + (dias === 1 ? " dia" : " dias");
      document.getElementById("hjCapS").textContent = dt.toLocaleDateString("pt-BR", { day: "numeric", month: "long" });
      el.innerHTML = '<div class="hj-cap"><div class="hj-cal"><i>' + dt.toLocaleDateString("pt-BR", { month: "short" }).replace(".", "") + "</i><b>" + dt.getDate() + "</b></div><div><h3>" + (e.numero ? "Capítulo " + e.numero : (e.titulo || "Capítulo")) + "</h3><p>" + (e.numero && e.titulo ? e.titulo + " · " : "") + (e.local || "") + '</p><p id="hjIns"></p></div></div><a class="hj-bt" href="painel-conselho.html?sec=eventos">Abrir o evento</a>';
      sb.from("evento_rsvp").select("status", { count: "exact" }).eq("evento_id", e.id).then(function (x) {
        var L = x.data || [], c = L.filter(function (y) { return y.status === "Confirmado"; }).length;
        if (L.length) document.getElementById("hjIns").textContent = L.length + " inscritos · " + c + " confirmados";
      });
    });
    var ini = new Date(); ini.setHours(0, 0, 0, 0); var fim = new Date(ini.getTime() + 864e5);
    var seg = new Date(ini); seg.setDate(ini.getDate() - ((ini.getDay() + 6) % 7)); var dom = new Date(seg.getTime() + 7 * 864e5);
    sb.from("social_posts").select("id", { count: "exact", head: true }).in("tipo", ["carrossel", "reel"]).neq("status", "recusado").gte("quando", seg.toISOString()).lt("quando", dom.toISOString()).then(function (r) { document.getElementById("hjSem").textContent = r.count == null ? "—" : r.count; });
    sb.from("social_posts").select("titulo,quando,tipo,status,imagens,video_url").in("tipo", ["carrossel", "reel"]).gte("quando", ini.toISOString()).lt("quando", fim.toISOString()).neq("status", "recusado").order("quando").then(function (r) {
      var el = document.getElementById("psRedes"), L = r.data || [];
      if (!L.length) { el.innerHTML = '<span class="s">Nenhum post no feed hoje.</span>'; return; }
      el.innerHTML = L.map(function (p) {
        var hr = new Date(p.quando).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" }), pub = p.status === "publicado";
        var img = p.imagens && p.imagens[0];
        return '<a class="hj-p" href="painel-redes.html" title="' + String(p.titulo || "").replace(/"/g, "&quot;") + '"><div class="im"' + (img ? ' style="background-image:url(\'' + img + '\')"' : "") + ">"
          + (!img && p.video_url ? '<video src="' + p.video_url + '#t=2" preload="metadata" muted playsinline></video>' : "")
          + '<span class="tp">' + (p.tipo === "reel" ? "Vídeo" : "Carrossel") + '</span><span class="hr' + (pub ? " ok" : "") + '">' + (pub ? "✓ " : "") + hr + "</span></div></a>";
      }).join("");
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
