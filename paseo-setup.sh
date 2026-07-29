#!/usr/bin/env bash
# Configura o Paseo em qualquer host (WSL/Linux ou macOS):
#   1. config.json         -> habilita MCP tools (merge, preserva o resto)
#   2. orchestration-preferences.json -> agents globais PM (planning), Dev (impl),
#      QA (audit) e Code Reviewer (review) — copiado de config/ do repo
#   3. 22 skills do registry (npx skills add -g)
#   4. 13 skills locais via paseo-skills-bundle.tar.gz (mesmo diretorio do script)
#
# Uso:  bash paseo-setup.sh
set -euo pipefail

PASEO_HOME="${PASEO_HOME:-$HOME/.paseo}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="$SCRIPT_DIR/paseo-skills-bundle.tar.gz"
PREFS_SRC="$SCRIPT_DIR/config/orchestration-preferences.json"

case "$(uname -s)" in
  Linux)  HOST_OS="linux (WSL se sob Windows)";;
  Darwin) HOST_OS="macos";;
  *)      HOST_OS="desconhecido";;
esac
echo "==> Host: $HOST_OS"

echo "==> Verificando pre-requisitos"
for cmd in npm npx python3 node; do
  command -v "$cmd" >/dev/null || { echo "ERRO: '$cmd' nao encontrado no PATH (instale Node.js primeiro)"; exit 1; }
done
if ! command -v paseo >/dev/null; then
  echo "    CLI 'paseo' nao encontrado — instalando @getpaseo/cli via npm"
  npm install -g @getpaseo/cli
  command -v asdf >/dev/null && asdf reshim nodejs || true
fi
command -v claude >/dev/null || echo "AVISO: 'claude' (Claude Code) nao encontrado — e o provider usado pelos agents; instale e faca login"

echo "==> 1/4 Habilitando MCP tools em $PASEO_HOME/config.json (merge)"
mkdir -p "$PASEO_HOME"
python3 - "$PASEO_HOME/config.json" <<'PY'
import json, sys, os
path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
cfg.setdefault("$schema", "https://paseo.sh/schemas/paseo.config.v1.json")
cfg.setdefault("version", 1)
daemon = cfg.setdefault("daemon", {})
mcp = daemon.setdefault("mcp", {})
mcp["enabled"] = True
mcp["injectIntoAgents"] = True
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"    ok: {path}")
PY

echo "==> 2/4 Gravando agents globais PM/Dev/QA/Reviewer em $PASEO_HOME/orchestration-preferences.json"
if [ ! -f "$PREFS_SRC" ]; then
  echo "ERRO: $PREFS_SRC nao encontrado — rode o script a partir do clone do repo paseo-setup"
  exit 1
fi
if [ -f "$PASEO_HOME/orchestration-preferences.json" ]; then
  cp -f "$PASEO_HOME/orchestration-preferences.json" "$PASEO_HOME/orchestration-preferences.json.bak"
  echo "    (backup salvo em orchestration-preferences.json.bak)"
fi
cp -f "$PREFS_SRC" "$PASEO_HOME/orchestration-preferences.json"
python3 -m json.tool "$PASEO_HOME/orchestration-preferences.json" > /dev/null
echo "    ok (fonte: config/orchestration-preferences.json)"

echo "==> 3/4 Instalando 22 skills do registry (global)"
cd "$HOME"
npx -y skills add getpaseo/paseo -g -y -a '*' \
  -s paseo -s paseo-advisor -s paseo-committee -s paseo-handoff -s paseo-loop
npx -y skills add samber/cc-skills-golang -g -y -a '*' \
  -s golang-code-style -s golang-error-handling -s golang-testing -s golang-design-patterns
npx -y skills add vercel-labs/agent-skills -g -y -a '*' -s vercel-react-best-practices
npx -y skills add wshobson/agents -g -y -a '*' \
  -s nextjs-app-router-patterns -s typescript-advanced-types -s tailwind-design-system \
  -s postgresql-table-design -s architecture-patterns -s api-design-principles
npx -y skills add clerk/skills -g -y -a '*' -s clerk-nextjs-patterns
npx -y skills add shadcn/ui -g -y -a '*' -s shadcn
npx -y skills add currents-dev/playwright-best-practices-skill -g -y -a '*' -s playwright-best-practices
npx -y skills add github/awesome-copilot -g -y -a '*' -s multi-stage-dockerfile
npx -y skills add mattpocock/skills -g -y -a '*' -s improve-codebase-architecture
npx -y skills add antonbabenko/terraform-skill -g -y -a '*' -s terraform-skill

echo "==> 4/4 Skills locais (pm-plan, dev-qa-loop, code-review-loop + UX/acessibilidade)"
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
if [ -f "$BUNDLE" ]; then
  tar -xzf "$BUNDLE" -C "$HOME/.agents/skills"
  for d in pm-plan dev-qa-loop code-review-loop accesslint-contrast-checker accesslint-link-purpose accesslint-refactor \
           accesslint-use-of-color bencium-controlled-ux-designer bencium-innovative-ux-designer \
           composition-patterns frontend-design ui-ux-pro-max web-design-guidelines; do
    ln -sfn "../../.agents/skills/$d" "$HOME/.claude/skills/$d"
  done
  echo "    ok: 13 skills extraidas e symlinkadas"
else
  echo "    AVISO: $BUNDLE nao encontrado — pulei as 13 skills locais."
  echo "    Copie o tarball para o mesmo diretorio do script e rode de novo (etapas anteriores sao idempotentes)."
fi

echo ""
echo "==> Concluido. Passos finais (manuais):"
echo "    1. Primeira vez neste host? Rode 'paseo onboard' para parear com o app."
echo "    2. Reinicie o daemon para aplicar o config: 'paseo restart'"
echo "       (ATENCAO: mata agentes em execucao neste host — confirme antes)"
echo "    3. Verifique: 'paseo status' e 'ls ~/.agents/skills | wc -l' (esperado: 35)"
echo "    4. Atualizacoes futuras das skills do registry: 'npx skills update -g'"
