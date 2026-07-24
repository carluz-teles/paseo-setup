# paseo-setup

Replicação da configuração do Paseo entre hosts (WSL → macOS).

O Paseo tem arquitetura daemon–cliente: skills, agents globais (Dev/QA) e config
vivem **na máquina onde o daemon roda**. Este repo replica essa configuração em
um novo host.

## Conteúdo

| Arquivo | Descrição |
|---|---|
| `paseo-macos-setup.sh` | Script idempotente de setup (funciona em macOS e Linux) |
| `paseo-skills-bundle.tar.gz` | 11 skills locais que não existem no registry (`dev-qa-loop` + UX/acessibilidade) |

## Uso

```bash
git clone git@github.com:carluz-teles/paseo-setup.git
cd paseo-setup
bash paseo-macos-setup.sh
paseo restart   # atenção: mata agentes em execução no host
```

Pré-requisitos: `npx`, `python3`, CLI `paseo` (onboarded) e `claude` (Claude Code, logado).

## O que o script configura

1. `~/.paseo/config.json` — habilita as Paseo tools via MCP (merge; preserva o resto do config)
2. `~/.paseo/orchestration-preferences.json` — agents globais: **PM** (`planning`, claude/opus), **Dev** (`impl`, claude/sonnet) e **QA** (`audit`, claude/opus)
3. 22 skills do registry (`npx skills add -g`): orquestração Paseo (×5), Go (samber ×4), React/Next/TS (vercel, wshobson, clerk), shadcn, Tailwind, Playwright, Postgres, Docker, Terraform e arquitetura (Matt Pocock + wshobson)
4. 12 skills locais do bundle, symlinkadas em `~/.claude/skills`

Loop Dev/QA em qualquer repo: skill `dev-qa-loop` (worker implementa, verifier
audita com evidências, via `paseo loop run`).

## Manutenção

- Skills do registry: `npx skills update -g`
- Skills do bundle: congeladas — para atualizar, regenere o tarball no host de origem:
  ```bash
  cd ~/.agents/skills && tar -czf paseo-skills-bundle.tar.gz dev-qa-loop accesslint-* bencium-* composition-patterns frontend-design ui-ux-pro-max web-design-guidelines
  ```
