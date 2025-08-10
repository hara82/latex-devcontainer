#!/usr/bin/env bash
# latex_diffgen.sh: interactively pick revisions (commits with tags shown) and create a LaTeX diff .tex
# Requirements: bash, git, fzf, latexdiff-vc (from TeX Live)
# Usage examples:
#   latex_diffgen.sh                        # fully interactive (ask MAIN -> ask OUT -> pick OLD/NEW)
#   latex_diffgen.sh -o diff.tex HEAD~1     # non-interactive (REV provided)
#   latex_diffgen.sh -m paper.tex -o x.tex abc123:def456
# Env:
#   MAX_COMMITS (default 200), MAX_TAGS (default 200)

set -euo pipefail

MAIN="main.tex"      # default main TeX file
OUTTEX=""            # output .tex (full filename, must end with .tex)
MAX_COMMITS="${MAX_COMMITS:-200}"
MAX_TAGS="${MAX_TAGS:-200}"

usage() {
  cat <<USAGE >&2
Usage: latex_diffgen.sh [-m MAIN] [-o OUTFILE.tex] [REV]
  REV: old[:new]  (if :new is omitted, working tree is used)
Options:
  -m MAIN          main TeX file (default: main.tex). If omitted, you'll be prompted first.
  -o OUTFILE.tex   output TeX filename (must end with .tex). If omitted, you'll be prompted second.
  -h               show this help
USAGE
}

# --- options ---
while getopts ":m:o:h" opt; do
  case "$opt" in
    m) MAIN="$OPTARG" ;;
    o) OUTTEX="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
  esac
done
shift $((OPTIND-1))

# --- tools check ---
command -v git >/dev/null 2>&1 || { echo "[error] git is required." >&2; exit 1; }
command -v fzf >/dev/null 2>&1 || { echo "[error] fzf is required. Install fzf and retry." >&2; exit 1; }
command -v latexdiff-vc >/dev/null 2>&1 || { echo "[error] latexdiff-vc not found. Install TeX Live tools and retry." >&2; exit 1; }

# --- 1) MAIN (prompt first if not provided) ---
if [[ ! -f "$MAIN" ]]; then
  read -r -p "Main TeX file [${MAIN}]: " _inp || true
  MAIN="${_inp:-$MAIN}"
fi
if [[ ! -f "$MAIN" ]]; then
  echo "[error] main TeX not found: $MAIN" >&2
  exit 1
fi

# --- 2) OUTTEX (prompt second if not provided) ---
default_out="diff.tex"
if [[ -z "$OUTTEX" ]]; then
  read -r -p "Output .tex filename [${default_out}]: " OUTTEX || true
  OUTTEX="${OUTTEX:-$default_out}"
fi

[[ "$OUTTEX" == *.tex ]] || { echo "[abort] Output filename must end with .tex"; exit 3; }

if [[ -e "$OUTTEX" ]]; then
  while :; do
    read -r -p "[warn] $OUTTEX already exists. Overwrite? [y/N]: " ans || { echo "[abort]"; exit 3; }
    case "$ans" in
      [Yy]|[Yy][Ee][Ss]) break ;;
      [Nn]|[Nn][Oo]|"")  echo "[abort] Choose another name with -o."; exit 3 ;;
      *)                 echo "Please answer 'y' or 'n'." ;;
    esac
  done
fi

# --- 3) REV (argument or interactive picker) ---
REV="${1:-}"
REV="${REV%:}"  # trim trailing colon if any

if [[ -z "$REV" ]]; then
  # Build one unified list where each line is:
  # "<hash>  <date>  <subject>  <decorations>"
  # Decorations show tags/branches like "(HEAD -> main, tag: v1.2, origin/main)".
  # Compose from:
  #   a) recent commits (with decorations)
  #   b) all tag targets (no-walk; includes very old tags)
  commits="$(git log --no-color --date=short --decorate=short --all \
             --pretty=format:'%h  %ad  %s  %d' -n "$MAX_COMMITS" || true)"
  tags="$(git log --no-color --date=short --decorate=short --no-walk=sorted --tags \
          --pretty=format:'%h  %ad  %s  %d' || true)"
  # Merge and deduplicate by hash (first field)
  list="$(printf '%s\n%s\n' "$commits" "$tags" | awk '!seen[$1]++')"

  # OLD selection
  echo "Select OLD (commits with tags visible):"
  old_line="$(printf '%s\n' "$list" | fzf --prompt="OLD > " --height=80% --reverse)"
  [[ -n "$old_line" ]] || { echo "[abort] No selection."; exit 2; }
  old_hash="${old_line%% *}"

  # NEW selection (or WORKTREE)
  echo "Select NEW (or WORKTREE for working tree):"
  new_line="$( { printf '%s\n' WORKTREE; printf '%s\n' "$list"; } | fzf --prompt="NEW > " --height=80% --reverse)"
  [[ -n "$new_line" ]] || { echo "[abort] No selection."; exit 2; }
  if [[ "$new_line" == "WORKTREE" ]]; then
    REV="$old_hash"
  else
    new_hash="${new_line%% *}"
    REV="$old_hash:$new_hash"
  fi
fi

# --- run latexdiff-vc to a temp dir, then copy to OUTTEX ---
tmpdir="$(mktemp -d -t latexdiff-XXXXXX)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

echo "[info] Generating diff: REV=${REV} MAIN=${MAIN}"
latexdiff-vc --git -d "$tmpdir" --revision="$REV" "$MAIN"

src="$tmpdir/$MAIN"
[[ -f "$src" ]] || { echo "[error] diff TeX not found: $src"; exit 1; }

cp "$src" "$OUTTEX"
echo "[done] Generated difference file: $OUTTEX"
