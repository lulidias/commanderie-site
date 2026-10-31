/* Rodapé das redes sociais: ícones do Instagram, Facebook e Threads com link para os perfis da Commanderie,
   em todas as páginas. Se a página já tem os três links, não duplica. */
(function () {
  function montar() {
    if (document.querySelector('[data-redes-rodape]')) return;
    // links antigos, pequenos, do rodapé: some o bloco para não duplicar
    document.querySelectorAll('footer a[href*="instagram.com/commanderiedebordeauxbr"], footer a[href*="threads.com/@commanderiedebordeauxbr"], #member a[href*="instagram.com/commanderiedebordeauxbr"]').forEach(function (a) {
      var box = a.parentElement; if (box && box.tagName !== "FOOTER") box.style.display = "none";
    });
    var IG = '<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="M12 2.2c3.2 0 3.6 0 4.8.1 1.2.1 1.8.2 2.2.4.6.2 1 .5 1.4.9.4.4.7.8.9 1.4.2.4.4 1 .4 2.2.1 1.3.1 1.6.1 4.8s0 3.6-.1 4.8c-.1 1.2-.2 1.8-.4 2.2-.2.6-.5 1-.9 1.4-.4.4-.8.7-1.4.9-.4.2-1 .4-2.2.4-1.3.1-1.6.1-4.8.1s-3.6 0-4.8-.1c-1.2-.1-1.8-.2-2.2-.4-.6-.2-1-.5-1.4-.9-.4-.4-.7-.8-.9-1.4-.2-.4-.4-1-.4-2.2C2.2 15.6 2.2 15.2 2.2 12s0-3.6.1-4.8c.1-1.2.2-1.8.4-2.2.2-.6.5-1 .9-1.4.4-.4.8-.7 1.4-.9.4-.2 1-.4 2.2-.4C8.4 2.2 8.8 2.2 12 2.2zm0 4.6a5.2 5.2 0 1 0 0 10.4 5.2 5.2 0 0 0 0-10.4zm0 8.6a3.4 3.4 0 1 1 0-6.8 3.4 3.4 0 0 1 0 6.8zm5.4-9.9a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4z"/></svg>';
    var FB = '<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.78-3.89 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.44 2.89h-2.34v6.99A10 10 0 0 0 22 12z"/></svg>';
    var TH = '<svg viewBox="0 0 192 192" width="19" height="19" fill="currentColor" aria-hidden="true"><path d="M141.5 88.9c-.8-.4-1.7-.8-2.5-1.1-1.5-27.1-16.3-42.6-41.1-42.8h-.3c-14.8 0-27.2 6.3-34.8 17.9l13.6 9.3c5.7-8.6 14.6-10.4 21.2-10.4h.2c8.2.1 14.4 2.4 18.4 7.1 2.9 3.4 4.9 8.1 5.9 14-7.3-1.2-15.2-1.6-23.6-1.1-23.8 1.4-39.1 15.2-38.1 34.4.5 9.7 5.4 18.1 13.7 23.6 7.1 4.7 16.2 7 25.7 6.5 12.5-.7 22.3-5.5 29.2-14.2 5.2-6.6 8.5-15.2 10-26 6 3.6 10.4 8.3 12.9 14 4.2 9.6 4.4 25.4-8.5 38.3-11.3 11.3-24.9 16.2-45.4 16.3-22.8-.2-40-7.5-51.2-21.7C36.3 135.8 30.9 116.6 30.7 96c.2-20.6 5.6-39.8 16-53.2C57.9 28.6 75.1 21.3 97.9 21.1c23 .2 40.5 7.5 52.1 21.8 5.7 7 10 15.8 12.8 26.1l15.9-4.2c-3.4-12.7-8.8-23.6-16.2-32.7C147.6 13.8 125.8 4.7 98 4.5h-.1c-27.7.2-49.1 9.5-63.5 27.7C21.6 48.4 15 70.8 14.7 95.9v.2c.3 25.1 6.9 47.5 19.7 63.7 14.4 18.2 35.8 27.5 63.5 27.7h.1c24.6-.2 42-6.6 56.3-20.9 18.7-18.7 18.2-42.1 12-56.4-4.4-10.2-12.8-18.6-24.8-24.3zm-43.1 40.5c-10.4.6-21.2-4.1-21.7-14.1-.4-7.4 5.3-15.7 22.4-16.7 2-.1 3.9-.2 5.8-.2 6.2 0 12 .6 17.3 1.8-2 24.6-13.5 28.7-23.8 29.2z"/></svg>';
    var redes = [["https://www.instagram.com/commanderiedebordeauxbr/", "Instagram", IG], ["https://www.facebook.com/1323190304220764", "Facebook", FB], ["https://www.threads.com/@commanderiedebordeauxbr", "Threads", TH]];
    var css = '.rr-bar{display:flex;flex-direction:column;align-items:center;gap:8px;padding:18px 16px;font-family:Arial,Helvetica,sans-serif}'
      + '.rr-bar .rr-t{font:normal 15px Georgia,serif;letter-spacing:.3px;color:var(--rr-txt,#e7d8a8)}'
      + '.rr-ic{display:flex;gap:18px}.rr-ic span{display:block;margin-top:6px;font:12px Arial;color:var(--rr-txt,#e7d8a8);text-align:center}.rr-ic div{display:flex;flex-direction:column;align-items:center}.rr-ic a{width:42px;height:42px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:1px solid var(--rr-borda,rgba(231,216,168,.55));color:var(--rr-txt,#e7d8a8);text-decoration:none;transition:background .15s,color .15s}'
      + '.rr-ic a:hover,.rr-ic a:focus-visible{background:var(--rr-txt,#e7d8a8);color:var(--rr-fundo,#1e2a56);outline:none}'
      + '.rr-bar.rr-claro{--rr-txt:#1e2a56;--rr-borda:#b08a3a;--rr-fundo:#f3ecd9;background:#f3ecd9;border-top:1px solid #ddd0ad}';
    var st = document.createElement("style"); st.textContent = css; document.head.appendChild(st);
    var bar = document.createElement("div"); bar.className = "rr-bar"; bar.setAttribute("data-redes-rodape", "");
    bar.innerHTML = '<span class="rr-t">Siga a Commanderie</span><div class="rr-ic">' + redes.map(function (r) {
      return '<div><a href="' + r[0] + '" target="_blank" rel="noopener" aria-label="' + r[1] + ' da Commanderie de Bordeaux do Brasil" title="' + r[1] + '">' + r[2] + "</a><span>" + r[1] + "</span></div>";
    }).join("") + "</div>";
    var ft = document.querySelector("footer");
    if (ft) { ft.appendChild(bar); }
    else { bar.classList.add("rr-claro"); var alvo = document.querySelector(".ps-main") || document.body; alvo.appendChild(bar); }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", montar); else montar();
})();
