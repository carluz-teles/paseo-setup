#!/usr/bin/env bash
# Replica no macOS a configuracao do Paseo feita no WSL (2026-07-24):
#   1. config.json         -> habilita MCP tools (merge, preserva o resto)
#   2. orchestration-preferences.json -> agents globais PM (planning), Dev (impl),
#      QA (audit) e Code Reviewer (review)
#   3. 22 skills do registry (npx skills add -g)
#   4. 13 skills locais via paseo-skills-bundle.tar.gz (mesmo diretorio do script)
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

echo "==> 2/4 Gravando agents globais PM/Dev/QA/Reviewer em $PASEO_HOME/orchestration-preferences.json"
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
    "audit": "claude/opus",
    "review": "claude/opus"
  },
  "preferences": [
    "Dev agent (impl/worker role): implement in small verifiable increments. Before finishing an iteration, run the project's own checks (livecart-be: 'go build ./...' and 'go test ./...' from the repo root; livecart-fe: 'pnpm run lint' and 'pnpm run build'). State clearly what changed and what is still pending.",
    "QA agent (audit/verifier role): pure QA — verifies exclusively through tests and objective checks: unit tests, integration tests, and e2e via Playwright when the repo has it configured. Runs the checks, cites the exact commands and their output, never fixes code, and does NOT review code style or architecture (that is the Code Reviewer agent's job). Returns done=true only when every acceptance criterion is covered by a passing test.",
    "Dev and QA run as a worker/verifier pair via 'paseo loop run': dev on claude/sonnet, QA on claude/opus. Only Claude is installed as a provider on this machine — do not select codex/copilot/opencode/pi unless the user says they installed them.",
    "TDD policy (Dev agent): for any behavior change (feature or bugfix), write the test that captures the acceptance criterion FIRST, run it to confirm it fails, then implement until it passes. Refactor-only, docs, and config tasks are exempt.",
    "TDD enforcement (QA agent): for feature/bugfix tasks, return done=false if no new or updated test covers the acceptance criteria — pre-existing tests passing is not sufficient. Cite the new/changed test names in the verdict.",
    "PM agent (planning role): analyzes tickets/tasks from a product perspective BEFORE implementation — user value, affected user flows, edge cases, product risks, open questions (only those whose answer changes scope, max 5, prioritized), and measurable acceptance criteria. Read-only: never modifies files. Its acceptance criteria become the Dev agent's TDD tests and the QA agent's verification checklist.",
    "Code Reviewer agent (review role): runs AFTER the dev-qa loop passes, in review rounds against the Dev agent. Reviews the diff for correctness bugs, security issues, project conventions, idiomatic patterns (use the installed language/framework skills as the ruler), and unjustified complexity. BLOCKING findings go into CODE_REVIEW.md at the repo root for the Dev to address and force another round; style suggestions are ADVISORY — reported in the verdict without blocking. Never fixes code itself. Approves only when zero blocking findings remain, then deletes CODE_REVIEW.md."
  ]
}
JSON
echo "    ok"

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

echo "==> 4/4 Skills locais (pm-plan, dev-qa-loop + UX/acessibilidade do livecart-fe)"
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
echo "    1. Reinicie o daemon para aplicar o config: 'paseo restart'"
echo "       (ATENCAO: mata agentes em execucao neste host — confirme antes)"
echo "    2. Verifique: 'paseo status' e 'ls ~/.agents/skills | wc -l' (esperado: 35)"
echo "    3. Atualizacoes futuras das skills do registry: 'npx skills update -g'"
