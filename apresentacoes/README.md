# Apresentações da Commanderie de Bordeaux — padrão "DNA"

Padrão visual **reutilizável** para todas as apresentações da confraria.
Toda apresentação nova nasce com a mesma cara: layout 16:9, paleta e
tipografia idênticas ao site, brasão, rodapé com o lema e a assinatura
discreta do parceiro organizador (VSX Club).

## Estrutura

```
apresentacoes/
├── dna.css                 ← o padrão visual (NÃO duplicar; todas as apresentações importam este arquivo)
├── assets/
│   ├── brasao.png          ← brasão oficial da Commanderie
│   ├── vsx-cream.png       ← logo VSX claro  (usar sobre fundo ESCURO: capa, rodapé navy)
│   ├── vsx-navy.png        ← logo VSX navy   (usar sobre fundo CLARO)
│   ├── vsx-gold.png        ← logo VSX dourado (alternativa sobre claro)
│   └── vsx-dark.png        ← logo VSX original (charcoal, fundo transparente)
└── <nome-da-apresentacao>/
    ├── index.html          ← os slides (cada <section class="page"> = 1 slide)
    └── img/                ← fotos específicas daquela apresentação
```

## Como criar uma apresentação nova

1. Crie a pasta `apresentacoes/minha-apresentacao/` com uma subpasta `img/`.
2. No `index.html`, importe o padrão: `<link rel="stylesheet" href="../dna.css">`.
3. Monte cada slide como `<section class="page ...">`. Variantes prontas:
   - **Capa** → `class="page cover"` (foto de fundo + `.veil.dark` + brasão centralizado + assinatura VSX pequena).
   - **Página interna** → `class="page"` com `.head` (cabeçalho com brasão + kicker + título + nº) e `.foot` (rodapé navy com lema + logo VSX).
   - **Roteiro / dia a dia** → use `.dia .tag` + a timeline `.tl > .it` (`.hh` hora/etapa, `.tt` título, `.dd` descrição). Funciona bem sobre foto com `.veil.side`.
   - **Texto + foto** → `.split` com `.col` (texto) e `.photo` (`background-image`).
   - **Números / cartões** → `.card` (fundo marfim, borda dourada); listas com `.inc li`.
   - **Investimento** → `.invest .price` (com `<small>€</small>`).
4. Logo do parceiro: **sempre menor e subordinado** ao brasão da Commanderie.
   Sobre fundo escuro use `vsx-cream.png`; sobre fundo claro use `vsx-navy.png`.

## Paleta (idêntica ao site)

| Cor      | Hex       | Uso                          |
|----------|-----------|------------------------------|
| Marfim   | `#f8f3e6` | fundo de páginas internas    |
| Navy     | `#1e2a56` | títulos, rodapé, fundo escuro |
| Navy fundo | `#0c1020` | véu de capa                |
| Dourado  | `#b08a3a` | kickers, filetes, destaques  |
| Bordô    | `#8f1d24` | números, acentos             |

Títulos em **Georgia** (serifada); textos em Arial. Slides em **1280×720** (16:9).

## Gerar o PDF

Render fiel via Chrome headless (mesma engine do navegador):

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf=saida.pdf "file://$PWD/minha-apresentacao/index.html"
```

O `@page { size:13.333in 7.5in }` no `dna.css` garante páginas 16:9 exatas
(960×540 pt). Cada `.page` quebra em uma página do PDF automaticamente.

## Apresentações já criadas

- **bordeaux-2027/** — 2ª viagem da Commanderie (02–07/maio/2027), curadoria VSX Club. 18 slides.
  Inclui duas páginas de hospedagem em destaque (Château Bellefont-Belcier e InterContinental).
