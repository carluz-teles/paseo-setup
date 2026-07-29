# paseo-setup

Configuração do Paseo replicável entre hosts (WSL/Linux e macOS).

O Paseo tem arquitetura daemon–cliente: skills, agents globais e config vivem
**na máquina onde o daemon roda**. Este repo configura qualquer host do zero
(ou aplica o delta — o script é idempotente).

## Conteúdo

| Arquivo | Descrição |
|---|---|
| `paseo-setup.sh` | Script idempotente de setup (WSL/Linux e macOS; instala o CLI do Paseo se faltar) |
| `config/config.json` | Config do daemon de referência (MCP tools habilitadas) |
| `config/orchestration-preferences.json` | Fonte de verdade dos agents globais — o script copia daqui |
| `paseo-skills-bundle.tar.gz` | 13 skills locais que não existem no registry (pm-plan, dev-qa-loop, code-review-loop + UX/acessibilidade) |

## Uso

```bash
git clone git@github.com:carluz-teles/paseo-setup.git
cd paseo-setup
bash paseo-setup.sh
paseo onboard   # só na primeira vez no host (parear com o app)
paseo restart   # atenção: mata agentes em execução no host
```

Pré-requisitos: Node.js (`npm`/`npx`), `python3` e `claude` (Claude Code, logado).
O CLI `paseo` é instalado automaticamente se não existir.

## O que o script configura

1. `~/.paseo/config.json` — habilita as Paseo tools via MCP (merge; preserva o resto do config)
2. `~/.paseo/orchestration-preferences.json` — agents globais (copiado de `config/`): **PM** (`planning`, claude/opus), **Dev** (`impl`, claude/sonnet), **QA** (`audit`, claude/opus) e **Code Reviewer** (`review`, claude/opus), com política de TDD
3. 22 skills do registry (`npx skills add -g`): orquestração Paseo (×5), Go (samber ×4), React/Next/TS (vercel, wshobson, clerk), shadcn, Tailwind, Playwright, Postgres, Docker, Terraform e arquitetura (Matt Pocock + wshobson)
4. 13 skills locais do bundle, symlinkadas em `~/.claude/skills`

## O fluxo de trabalho que isso habilita

```
roda o pm: <ticket>   → PM analisa produto/codebase e levanta questões (você responde)
                      → PM + Dev planner escrevem o plano (você aprova)
dev-qa loop           → Dev implementa com TDD; QA verifica por testes até passar
roda o review         → Code Reviewer em rodadas com o Dev até zero achados blocking
você                  → git diff final e commit
```

## Manutenção

- Mudou os agents? Edite `config/orchestration-preferences.json`, commit, e nos hosts:
  `git pull && bash paseo-setup.sh`
- Skills do registry: `npx skills update -g`
- Skills do bundle: congeladas — para atualizar, regenere o tarball no host de origem:
  ```bash
  cd ~/.agents/skills && tar -czf <repo>/paseo-skills-bundle.tar.gz pm-plan dev-qa-loop code-review-loop accesslint-* bencium-* composition-patterns frontend-design ui-ux-pro-max web-design-guidelines
  ```
