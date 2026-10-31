# Commanderie de Bordeaux do Brasil — site institucional

## O que é
Site da **Commanderie de Bordeaux do Brasil**, uma confraria dedicada aos vinhos de Bordeaux. Sede em São Paulo (matriz) e cinco núcleos: **São Paulo, Rio de Janeiro, Porto Alegre, Curitiba e Recife**. Lema: **"Bordeaux, toujours Bordeaux"**.

## Publicação (deploy)
- Site **estático** (HTML puro, sem build).
- Hospedado no **GitHub Pages** (migrado da Netlify em 2026-05-30 — ver abaixo), servindo a partir do repositório `lulidias/commanderie-site`, branch `main`, pasta raiz.
- **Todo push para `main` republica o site sozinho** (GitHub Pages rebuilda em ~1 min). Não há build command; publish directory = raiz. Builds do GitHub Pages são **gratuitos e sem cota de créditos**.
- Domínio oficial: **commanderiedebordeaux.com.br**. DNS gerenciado no **Registro.br** (nameservers `*.sec.dns.br`). Apex aponta para os 4 IPs do GitHub Pages (`185.199.108-111.153`); `www` é CNAME para o apex. Arquivo `CNAME` na raiz do repo define o domínio. HTTPS é emitido automaticamente pelo GitHub (marcar "Enforce HTTPS" em Settings → Pages quando o cert ficar pronto). O domínio **gcvb.com.br** deverá redirecionar para o principal (pendente).
- **Por que saiu da Netlify:** o modelo novo da Netlify (plano Free = 300 créditos/mês, cada build/deploy consome crédito) pausou o site em 30/05/2026 depois de muitos deploys no mesmo dia. GitHub Pages não tem essa limitação. **Regra:** agrupar mudanças e publicar menos vezes; manter páginas leves (imagens em `img/`, nunca rebase64).

## Identidade visual
- Inspirada nos diplomas do Grand Conseil de Bordeaux (pergaminho).
- Cores: pergaminho/marfim `#f3ecd9`, azul-marinho `#1e2a56`, dourado `#b08a3a`, vermelho `#8f1d24`, creme `#f8f3e6`, linha `#ddd0ad`.
- Tipografia: títulos em **Georgia** (serifada); textos auxiliares em Arial.
- Brasão da Commanderie em todas as páginas; rodapé com o lema.

## Páginas (todas na raiz do repositório)
- `index.html` — home: hero com brasão, A Commanderie, Núcleos, **A Mesa** (Grão-Mestre e Mestres), Próximos capítulos, Galeria, Como se tornar membro (por indicação), Importadoras parceiras, Doação, Contato.
- `capitulos.html` — histórico de capítulos (realizados I–V) e próximos (VI–VIII).
- `viagens.html` — viagens de enoturismo (parceria VSX Club). Primeira: Primeurs Bordeaux, 19–23/04/2026, com roteiro dia a dia.
- `diretorio.html` — diretório dos 48 membros por capítulo + Membros de Honra. Avatares com iniciais (ou foto, quando houver).
- `login.html` — tela de login (protótipo; senha real depende do backend).
- `area-do-socio.html` — Área do Membro: carteira na Apple Wallet, foto do Comendador (upload com pré-visualização), sugerir nome ao Conselho, minhas sugestões (status), diretório, documentos (Estatuto).
- `adesao.html` — ficha de indicação (2 padrinhos + aval de um Mestre/Grão-Mestre).
- `candidatura.html` — ficha de candidatura à intronização (preenchida pelo candidato aprovado, com código de acesso).
- `painel-conselho.html` — painel do Conselho: indicações, status, pagamentos, financeiro por núcleo (protótipo).
- `Estatuto_Commanderie_Bordeaux_Brasil.pdf` / `.docx` — Estatuto social.

## Graus e carteiras
- Graus: **Commandeur** (membro efetivo), **Mestre** (por núcleo) e **Grão-Mestre** (Brasil); além de **Membro de Honra** (não paga anuidade, recebe diploma).
- Cores de carteira: **marfim** para Commandeur e Membro de Honra; **bordô com moldura dourada** para Mestre e Grão-Mestre.
- Mesa atual: Grão-Mestre **Manu Brandão**; Mestres **Luli Dias** (SP), **Tito Dias** (Recife), **Abner Almeida** (Curitiba), **Jadir Engers** (Porto Alegre); **Leandro Almeida** (Rio de Janeiro, desde 31/10/2026). São CINCO núcleos: SP, Rio, Recife, Curitiba, Porto Alegre.

## Fluxo de adesão (por indicação, nunca aberto ao público)
1. Um membro **sugere um nome** ao Conselho (na Área do Membro).
2. O **Conselho aprova ou recusa**.
3. Se aprovado, o Conselho **envia o formulário** ao candidato (`candidatura.html`).
4. Status acompanhados: Aguardando aprovação → Aprovado → Formulário enviado → Aguardando pagamento → Pago → Membro.

## Modelo de cobrança (futuro backend)
- Plataforma escolhida: **Asaas** (conta única da matriz; núcleos como etiqueta de relatório, sem split entre eles).
- Quatro fluxos: anuidade (recorrente), eventos (só sócios + 1 acompanhante), viagens (split com a empresa de enoturismo VSX Club), doação (espontânea).
- Login real, cadastro/CRM, fotos dos membros e o webhook "pagou → libera carteira" entram com o backend (sugestão: **Supabase** para auth + banco + storage; função na Netlify para o webhook do Asaas).

## Notas técnicas
- O CSS está embutido em `<style>` em cada `.html`. As **imagens compartilhadas** (brasão, hero, logo do topo) ficam em **arquivos na pasta `img/`** e são referenciadas por caminho relativo (ex.: `img/brasao.png`) — assim o navegador baixa e cacheia cada imagem uma única vez para o site inteiro, reduzindo muito o consumo de banda da Netlify. (Antes ficavam em base64 dentro de cada arquivo, o que deixava as páginas pesadas; migrado em 2026-05-30.) Não há CSS/JS externos próprios.
- Por isso, o mesmo bloco de CSS se repete em várias páginas — ao mudar um estilo global, atualizar em todas.
- Importadoras parceiras (seção "Apoio" no index): Epice, Mistral, World Wine, Enclos, Chez France, Interfood, Casa Santa Luzia (logos a inserir).
- As páginas foram geradas originalmente por um script Python no ambiente Cowork (não incluído neste repositório). Daqui em diante, editar os `.html` diretamente.

## Já concluído (estava listado como pendência)
- **Backend no ar** (Supabase): login real por e-mail + ativação por código, cadastro/CRM, storage de fotos (buckets `fotos`/`eventos`/`parceiros`/`dicas`/`loja`), RLS, pg_cron e pg_net.
- **Galeria real** populada: eventos `realizado=true` + tabela `evento_fotos` + lightbox (7 eventos, centenas de fotos).
- **Logos das importadoras** (monocromáticas) na home + página `importadores.html`.
- **Open Graph / compartilhamento** (`img/og-card.png` 1200×630) nas páginas públicas; **PWA instalável** (manifest + ícones + tela cheia no iPhone).

## Pendências / próximos passos
- **Pagamento real (Asaas/PIX)**: hoje `pagamentos.html` só mostra a chave PIX. Falta integrar Asaas (anuidade/eventos/doação) + webhook "pagou → marca pago → libera carteira".
- Tradução PT/EN/FR com seletor de idiomas (há base de `data-i18n`).
- Carteira digital de verdade (Apple Wallet .pkpass / Google Wallet) — hoje é visual.
- gcvb.com.br redirecionando para o domínio principal.
- Fotos dos demais membros no diretório.
- Ligar logins dos outros 5 responsáveis das importadoras (só a Épice está vinculada).

## Trabalho em dupla — Luli e Manu (regra obrigatória, desde 31/10/2026)
Luli (lulidias) e Manu (ManuBrandao) mexem no site ao mesmo tempo, cada um com o seu Claude. Para ninguém sobrescrever o trabalho do outro:
1. **Sempre `git pull --rebase` ANTES de começar a editar e de novo ANTES do push.** Nunca editar uma versão velha do arquivo.
2. **Um assunto por commit, e push logo em seguida.** Nada de deixar mudança parada no computador.
3. **Nunca `git push --force`, nunca `git reset` em commit já publicado, nunca reescrever o arquivo inteiro a partir de uma cópia antiga.** A `main` tem proteção no GitHub contra force push e exclusão.
4. **Se o pull trouxer mudança do outro no mesmo arquivo:** resolver juntando as duas versões. Se houver dúvida, parar e perguntar. Não descartar o que o outro fez.
5. **Antes de mexer num arquivo que o outro alterou nas últimas 24 h** (`git log --since=24.hours -- arquivo`), ler o commit dele e preservar a mudança.
6. **Áreas de cada um** (quem mais mexe; o outro só mexe avisando):
   - **Manu:** diplomas (`diploma-*`, `disciples-compagnons`), importadoras (`painel-importadoras`, `importadores`, PIX das importadoras), `factures`, financeiro do `painel-conselho`.
   - **Luli:** site público (`index`, rodapé, idiomas), redes sociais (`painel-redes`, `js/redes-*`), moldura do painel (`js/painel-shell.js`), filmes e vídeos.
   - **Compartilhado (cuidado redobrado):** `painel-bi.html` — números financeiros SEMPRE via `fin_resumo()` (ver `sql/fin_resumo.sql`); nunca voltar ao cálculo próprio.
7. **Banco (Supabase):** mudanças de estrutura só por arquivo em `sql/` versionado, com data e motivo.
