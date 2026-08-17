#!/usr/bin/env bash
# Instala as engineering skills deste repo em ~/.claude/skills via symlink.
# Cross-platform (macOS e Linux/WSL). Idempotente — re-rodar é seguro.
#
# Uso:  bash install.sh
#
# Depois de instalado, `git pull` neste repo atualiza as skills automaticamente
# (as skills sao symlinks apontando para skills/ deste clone).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

case "$(uname -s)" in
  Linux)  HOST_OS="linux/WSL";;
  Darwin) HOST_OS="macos";;
  *)      HOST_OS="$(uname -s)";;
esac

echo "==> Host:    $HOST_OS"
echo "==> Fonte:   $SKILLS_SRC"
echo "==> Destino: $CLAUDE_SKILLS"

if [ ! -d "$SKILLS_SRC" ]; then
  echo "ERRO: '$SKILLS_SRC' nao existe — rode a partir do clone do repo." >&2
  exit 1
fi

mkdir -p "$CLAUDE_SKILLS"

count=0
for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  src="${skill_dir%/}"
  target="$CLAUDE_SKILLS/$name"
  # Remove o que estiver la (copia real, symlink velho ou arquivo) antes de relinkar
  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
  fi
  ln -s "$src" "$target"
  echo "    linked: $name -> $src"
  count=$((count + 1))
done

echo "==> Concluido: $count skill(s) symlinkada(s) em $CLAUDE_SKILLS"
