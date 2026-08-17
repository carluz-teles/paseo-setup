# paseo-setup

Engineering skills do fluxo Paseo, versionadas e replicáveis entre hosts (WSL/Linux e macOS).

Cada skill é um diretório em `skills/` com seu `SKILL.md`. O `install.sh` symlinka
cada uma em `~/.claude/skills`, então `git pull` neste repo atualiza tudo — uma fonte
única da verdade, sem cópias que divergem.

## Skills

| Skill | Papel |
|---|---|
| `engineering-orchestrator` | Orquestra o fluxo (roteia PM, Architect, Dev, QA, Reviewer) |
| `product-manager` | Análise de produto/UX/acessibilidade antes de implementar |
| `engineering-architect` | Decisões de arquitetura, boundaries, trade-offs |
| `engineering-developer` | Implementação (repo-first, reuse-check, TDD, convenções) |
| `engineering-qa` | Validação independente contra os critérios de aceite |
| `engineering-reviewer` | Review final de correção, arquitetura, segurança, regressão |

## Instalação

```bash
git clone git@github.com:carluz-teles/paseo-setup.git ~/paseo-setup
cd ~/paseo-setup
bash install.sh
```

Funciona igual em **macOS** e **Linux/WSL**. É idempotente: re-rodar apenas
recria os symlinks. Se já existir uma cópia real em `~/.claude/skills/<skill>`,
o script a substitui pelo symlink.

Destino customizável via env: `CLAUDE_SKILLS_DIR=/caminho bash install.sh`.

## Atualizar

```bash
cd ~/paseo-setup && git pull
```

Os symlinks já apontam para `skills/`, então o pull propaga na hora. Editou uma
skill? Commit + push aqui, e nos outros hosts basta `git pull`.

## Histórico

A configuração anterior deste repo (setup completo do daemon Paseo — `paseo-setup.sh`,
`config/`, bundle de skills do registry) foi substituída por este layout enxuto.
Continua disponível no histórico git (commit `fe1bec4`) se precisar recuperar.
