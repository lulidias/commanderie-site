/* Fotos dos eventos: ver TODAS em grade e BAIXAR (uma, ou todas num .zip).  · 04/11/2026
   Usado por eventos.html e index.html (galeria do Painel do Comendador). A página informa:
     FG.config({ lista: () => [urls], atual: () => índice, mostrar: i => {abre a foto i no lightbox}, nome: () => "nome-do-evento" })
   FG.grade() abre a grade; dentro do lightbox aparecem "Ver todas" e "Baixar esta". */
window.FG = (function () {
  var C = {}, el = null;
  function slug(s) { return (s || "evento").normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^A-Za-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 50) || "evento"; }
  function nomeArq(i) { return slug(C.nome ? C.nome() : "evento") + "-" + String(i + 1).padStart(3, "0") + ".jpg"; }
  function toast(t) { var d = document.createElement("div"); d.textContent = t; d.style.cssText = "position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:#1e2a56;color:#fff;padding:10px 16px;border-radius:10px;font:13.5px Arial,sans-serif;z-index:90;max-width:90%;text-align:center;"; document.body.appendChild(d); setTimeout(function () { d.remove(); }, 3500); }
  async function baixar(url, nome) {
    try { var r = await fetch(url, { mode: "cors" }); if (!r.ok) throw 0; var b = await r.blob(); var a = document.createElement("a"); a.href = URL.createObjectURL(b); a.download = nome || "foto.jpg"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(function () { URL.revokeObjectURL(a.href); }, 4000); }
    catch (e) { window.open(url, "_blank"); toast("A foto abriu em outra aba — toque e segure (ou botão direito) para salvar."); }
  }
  function lib(u) { return new Promise(function (ok, er) { var s = document.createElement("script"); s.src = u; s.onload = ok; s.onerror = er; document.head.appendChild(s); }); }
  async function baixarTodas(btn) {
    var L = C.lista ? C.lista() : []; if (!L.length) return;
    try { if (!window.JSZip) await lib("https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"); } catch (e) {}
    if (!window.JSZip) { toast("Baixando uma a uma…"); for (var i = 0; i < L.length; i++) await baixar(L[i], nomeArq(i)); return; }
    btn.disabled = true; var zip = new JSZip(), ok = 0;
    for (var j = 0; j < L.length; j++) { btn.textContent = "Preparando " + (j + 1) + " de " + L.length + "…"; try { var r = await fetch(L[j], { mode: "cors" }); if (r.ok) { zip.file(nomeArq(j), await r.blob()); ok++; } } catch (x) {} }
    btn.textContent = "Compactando…"; var blob = await zip.generateAsync({ type: "blob" });
    var a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = slug(C.nome ? C.nome() : "fotos") + ".zip"; document.body.appendChild(a); a.click(); a.remove();
    btn.disabled = false; btn.innerHTML = "&#11015; Baixar todas (" + L.length + ")"; toast("✔ " + ok + " fotos baixadas num arquivo .zip");
  }
  var IC = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>';
  var BT = "border:none;border-radius:9px;padding:9px 14px;font:13.5px Arial,sans-serif;cursor:pointer;";
  function grade() {
    var L = C.lista ? C.lista() : []; if (!L.length) return;
    var lb = document.getElementById("lightbox"); if (lb) lb.style.display = "none";
    if (!el) { el = document.createElement("div"); el.id = "fgGrade"; el.style.cssText = "position:fixed;inset:0;background:#f8f3e6;z-index:61;overflow:auto;display:none;"; document.body.appendChild(el); }
    el.innerHTML = '<div style="position:sticky;top:0;background:#1e2a56;color:#fff;padding:12px 16px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;z-index:2;">'
      + '<b style="font-family:Georgia,serif;font-weight:normal;font-size:18px;flex:1;min-width:160px;">' + (C.titulo ? C.titulo() : "Fotos") + ' <span style="font-size:13px;color:#e7d8a8;">· ' + L.length + ' fotos</span></b>'
      + '<button id="fgZip" style="' + BT + 'background:#b08a3a;color:#fff;">&#11015; Baixar todas (' + L.length + ')</button>'
      + '<button onclick="FG.fechar()" style="' + BT + 'background:#fff;color:#1e2a56;">&times; Fechar</button></div>'
      + '<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px;padding:12px;">'
      + L.map(function (u, i) { return '<div style="position:relative;aspect-ratio:1;border-radius:8px;overflow:hidden;background:#e9e1cc;cursor:zoom-in;" onclick="FG.ver(' + i + ')"><img src="' + u + '" loading="lazy" alt="" style="width:100%;height:100%;object-fit:cover;display:block;"><button title="Baixar" onclick="event.stopPropagation();FG.baixarN(' + i + ')" style="position:absolute;right:6px;bottom:6px;width:32px;height:32px;border-radius:50%;border:none;background:rgba(30,42,86,.85);color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;">' + IC + '</button></div>'; }).join("")
      + '</div>';
    el.querySelector("#fgZip").onclick = function () { baixarTodas(this); };
    el.style.display = "block"; document.body.style.overflow = "hidden";
  }
  function fechar() { if (el) el.style.display = "none"; document.body.style.overflow = ""; }
  function ver(i) { if (el) el.style.display = "none"; document.body.style.overflow = ""; if (C.mostrar) C.mostrar(i); }
  function botoesLightbox() {
    var lb = document.getElementById("lightbox"); if (!lb || document.getElementById("fgLbBar")) return;
    var d = document.createElement("div"); d.id = "fgLbBar"; d.style.cssText = "position:absolute;top:12px;left:14px;display:flex;gap:8px;z-index:2;";
    d.innerHTML = '<button onclick="event.stopPropagation();FG.grade()" style="' + BT + 'background:rgba(255,255,255,.92);color:#1e2a56;">&#9638; Ver todas</button>'
      + '<button onclick="event.stopPropagation();FG.baixarN(FG.atual())" style="' + BT + 'background:#b08a3a;color:#fff;">&#11015; Baixar esta</button>';
    lb.appendChild(d);
  }
  return {
    config: function (c) { C = c || {}; if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", botoesLightbox); else botoesLightbox(); },
    grade: grade, fechar: fechar, ver: ver,
    atual: function () { return C.atual ? C.atual() : 0; },
    baixarN: function (i) { var L = C.lista ? C.lista() : []; if (L[i]) baixar(L[i], nomeArq(i)); }
  };
})();
document.addEventListener("keydown", function (e) { var g = document.getElementById("fgGrade"); if (e.key === "Escape" && g && g.style.display === "block") FG.fechar(); });
