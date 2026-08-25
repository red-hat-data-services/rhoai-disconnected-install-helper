#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 [OPTIONS] [FILE...]"
    echo ""
    echo "Extract ImageSetConfiguration YAML sections from .md files"
    echo "and write them to <basename>-imagesetconfig.yaml files."
    echo ""
    echo "Options:"
    echo "  -d, --dir DIR     Directory containing .md files (default: script directory)"
    echo "  -o, --output DIR  Output directory for .yaml files (default: same as input)"
    echo "  -f, --force       Overwrite existing .yaml files"
    echo "  -n, --dry-run     Show what would be created without writing files"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "If FILE arguments are given, only those files are processed."
    echo "Otherwise, all rhoai-*.md and rhods-*.md files in the directory are processed."
}

DIR="$SCRIPT_DIR"
OUTDIR=""
DRY_RUN=false
FORCE=false
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)    DIR="$2"; shift 2 ;;
        -o|--output) OUTDIR="$2"; shift 2 ;;
        -f|--force)  FORCE=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help)   usage; exit 0 ;;
        -*)          echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)           FILES+=("$1"); shift ;;
    esac
done

OUTDIR="${OUTDIR:-$DIR}"
mkdir -p "$OUTDIR"

if [[ ${#FILES[@]} -eq 0 ]]; then
    shopt -s nullglob
    FILES=("$DIR"/rhoai-*.md "$DIR"/rhods-*.md)
    shopt -u nullglob
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No .md files found in $DIR" >&2
    exit 1
fi

created=0
skipped=0

for mdfile in "${FILES[@]}"; do
    if [[ ! -f "$mdfile" ]]; then
        echo "WARN: file not found: $mdfile" >&2
        continue
    fi

    if ! grep -q "# ImageSetConfiguration" "$mdfile" 2>/dev/null; then
        echo "SKIP (no ImageSetConfiguration): $(basename "$mdfile")"
        skipped=$((skipped + 1))
        continue
    fi

    base="$(basename "${mdfile%.md}")"
    yamlfile="$OUTDIR/${base}-imagesetconfig.yaml"

    content=$(awk '
        /^# ImageSetConfiguration/ { found=1; next }
        found && /^```yaml/ { capture=1; next }
        capture && /^```/ { exit }
        capture { print }
    ' "$mdfile" | sed -e :a -e '/^[[:space:]]*$/{ $d; N; ba; }')

    if [[ -z "$content" ]]; then
        echo "SKIP (empty YAML block): $(basename "$mdfile")"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ -f "$yamlfile" ]] && ! $FORCE; then
        echo "SKIP (already exists, use -f to overwrite): $(basename "$yamlfile")"
        skipped=$((skipped + 1))
        continue
    fi

    if $DRY_RUN; then
        echo "WOULD CREATE: $yamlfile"
    else
        echo "$content" > "$yamlfile"
        echo "CREATED: $yamlfile"
    fi
    created=$((created + 1))
done

echo ""
echo "Summary: $created created, $skipped skipped"
