# Seed+ Bridge deploy

Este repositorio publica um unico site no GitHub Pages usando o fluxo oficial do GitHub Actions.

- `main` alimenta a URL publica de producao em `https://hage-tech.github.io/seed-bridge/`
- `dev` alimenta a URL publica de homologacao em `https://hage-tech.github.io/seed-bridge/test/`
- o deploy real usa apenas o environment `github-pages`
- a branch `gh-pages` nao faz mais parte do fluxo ativo

## Como o deploy funciona

Cada deploy recompõe o site inteiro a partir do Git:

- root `/` sempre vem da branch `main`
- subpath `/test/` sempre vem da branch `dev`
- se `dev` ainda nao existir, o deploy publica apenas o root

Isso vale para pushes em `main` e em `dev`. O workflow monta um artifact completo e publica pelo fluxo oficial do Pages:

- `actions/configure-pages`
- `actions/upload-pages-artifact`
- `actions/deploy-pages`

## Workflow

Arquivo: `.github/workflows/pages.yml`

Jobs:

- `validate`: valida os arquivos essenciais do site e o script de composicao
- `build-pages`: monta o artifact com `/` e `/test/`
- `deploy-pages`: publica o artifact no GitHub Pages usando `environment: github-pages`

O workflow roda em:

- `push` para `main`
- `push` para `dev`
- `workflow_dispatch`

## Script de composicao

Arquivo: `scripts/prepare-pages-artifact.sh`

Interface:

```bash
scripts/prepare-pages-artifact.sh <main|dev> <output_dir>
```

Comportamento:

- `main`: usa o checkout atual para o root e tenta extrair `dev` para `/test/`
- `dev`: usa `main` para o root e o checkout atual para `/test/`
- nao faz `git push`
- nao usa `gh-pages`

## Site de homologacao

O ambiente `/test/` continua publico e sinalizado no proprio HTML:

- badge discreta `TEST`
- `data-env="test"`
- `meta name="robots" content="noindex,nofollow"`

O `robots.txt` do root mantem:

```txt
User-agent: *
Allow: /
Disallow: /test/
```

## Configuracao no GitHub

Aplicar no repositorio `hage-tech/seed-bridge`:

1. Criar a branch `dev` a partir da `main`.
2. Em `Settings > Pages`, configurar `Source: GitHub Actions`.
3. Em `Settings > Environments > github-pages`, habilitar custom deployment branches para:
   - `main`
   - `dev`
4. Nao criar `production` e `test` como environments de deploy do Pages.
5. Em `Settings > Actions > General`, garantir que as permissoes padrao permitam o deploy do Pages.

Se isso ja foi configurado no GitHub, essa etapa pode ser considerada concluida.

## Rollout

1. Mergear estas mudancas em `main`.
2. Criar `dev` a partir do mesmo commit e fazer push.
3. Alterar `Settings > Pages` para `GitHub Actions`.
4. Rodar manualmente o workflow em `main`.
5. Validar:
   - `https://hage-tech.github.io/seed-bridge/`
   - `https://hage-tech.github.io/seed-bridge/test/`

Depois disso:

- push em `main` atualiza o root e preserva `/test/` a partir de `dev`
- push em `dev` atualiza `/test/` e recompõe o root a partir de `main`

## Verificacoes locais

- `bash -n scripts/prepare-pages-artifact.sh`
- `test -f site/index.html`
- `test -f site/robots.txt`

## Scripts locais do fluxo Git

- `./scripts/deploy-dev.sh`: faz `git switch dev`, `git add -A`, commit e push para `origin/dev`
- `./scripts/promote-dev.sh`: atualiza `main`, faz merge de `dev` em `main` e push para `origin/main`

Observacao:

- `./scripts/deploy-dev.sh` usa `git add -A`, entao ele inclui qualquer alteracao local rastreada ou nao rastreada do repositorio no commit de `dev`

Ambos aceitam mensagem opcional:

```bash
./scripts/deploy-dev.sh "Update teaser copy"
./scripts/promote-dev.sh "Promote dev to main"
```
