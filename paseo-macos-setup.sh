#!/usr/bin/env bash
# Replica no macOS a configuracao do Paseo feita no WSL (2026-07-24):
#   1. config.json         -> habilita MCP tools (merge, preserva o resto)
#   2. orchestration-preferences.json -> agents globais Dev (impl) e QA (audit)
#   3. 17 skills do registry (npx skills add -g)
#   4. 11 skills locais via paseo-skills-bundle.tar.gz (mesmo diretorio do script)
#
# Uso:  bash paseo-macos-setup.sh
set -euo pipefail

PASEO_HOME="${PASEO_HOME:-$HOME/.paseo}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="$SCRIPT_DIR/paseo-skills-bundle.tar.gz"

echo "==> Verificando pre-requisitos"
for cmd in npx python3; do
  command -v "$cmd" >/dev/null || { echo "ERRO: '$cmd' nao encontrado no PATH"; exit 1; }
done
command -v paseo >/dev/null || echo "AVISO: CLI 'paseo' nao encontrado — instale/onboard o Paseo antes de reiniciar o daemon"
command -v claude >/dev/null || echo "AVISO: 'claude' (Claude Code) nao encontrado — e o provider usado pelos agents Dev/QA"

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

echo "==> 2/4 Gravando agents globais Dev/QA em $PASEO_HOME/orchestration-preferences.json"
if [ -f "$PASEO_HOME/orchestration-preferences.json" ]; then
  cp "$PASEO_HOME/orchestration-preferences.json" "$PASEO_HOME/orchestration-preferences.json.bak"
  echo "    (backup salvo em orchestration-preferences.json.bak)"
fi
cat > "$PASEO_HOME/orchestration-preferences.json" <<'JSON'
{
  "providers": {
    "impl": "claude/sonnet",
    "ui": "claude/sonnet",
    "research": "claude/sonnet",
    "planning": "claude/opus",
    "audit": "claude/opus"
  },
  "preferences": [
    "Dev agent (impl/worker role): implement in small verifiable increments. Before finishing an iteration, run the project's own checks (livecart-be: 'go build ./...' and 'go test ./...' from the repo root; livecart-fe: 'pnpm run lint' and 'pnpm run build'). State clearly what changed and what is still pending.",
    "QA agent (audit/verifier role): verify facts only, never fix code. Run the checks, cite the exact commands and their output, inspect the changed files for coherence with the task, and return done=true only when all acceptance criteria are objectively met.",
    "Dev and QA run as a worker/verifier pair via 'paseo loop run': dev on claude/sonnet, QA on claude/opus. Only Claude is installed as a provider on this machine — do not select codex/copilot/opencode/pi unless the user says they installed them."
  ]
}
JSON
echo "    ok"

echo "==> 3/4 Instalando 17 skills do registry (global)"
cd "$HOME"
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

echo "==> 4/4 Skills locais (dev-qa-loop + UX/acessibilidade do livecart-fe)"
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
if [ -f "$BUNDLE" ]; then
  tar -xzf "$BUNDLE" -C "$HOME/.agents/skills"
  for d in dev-qa-loop accesslint-contrast-checker accesslint-link-purpose accesslint-refactor \
           accesslint-use-of-color bencium-controlled-ux-designer bencium-innovative-ux-designer \
           composition-patterns frontend-design ui-ux-pro-max web-design-guidelines; do
    ln -sfn "../../.agents/skills/$d" "$HOME/.claude/skills/$d"
  done
  echo "    ok: 11 skills extraidas e symlinkadas"
else
  echo "    AVISO: $BUNDLE nao encontrado — pulei as 11 skills locais."
  echo "    Copie o tarball para o mesmo diretorio do script e rode de novo (etapas anteriores sao idempotentes)."
fi

echo ""
echo "==> Concluido. Passos finais (manuais):"
echo "    1. Reinicie o daemon para aplicar o config: 'paseo restart'"
echo "       (ATENCAO: mata agentes em execucao neste host — confirme antes)"
echo "    2. Verifique: 'paseo status' e 'ls ~/.agents/skills | wc -l' (esperado: 28+)"
echo "    3. Atualizacoes futuras das skills do registry: 'npx skills update -g'"
