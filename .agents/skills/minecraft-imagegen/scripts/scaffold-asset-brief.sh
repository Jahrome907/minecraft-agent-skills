#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash ./scripts/scaffold-asset-brief.sh --type <asset-type> --name <slug> [--out <dir>] [--overwrite]

Examples:
  bash ./scripts/scaffold-asset-brief.sh --type pack-icon --name starforge
  bash ./scripts/scaffold-asset-brief.sh --type release-banner --name skylands --out docs/briefs
EOF
}

TYPE=""
NAME=""
OUT_DIR="__AUTO__"
OVERWRITE=0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SKILL_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)"
HOME_DIR=""

if [[ -n "${HOME:-}" && -d "${HOME:-}" ]]; then
  HOME_DIR="$(CDPATH= cd -- "$HOME" && pwd -P)"
elif [[ -n "${USERPROFILE:-}" && -d "${USERPROFILE:-}" ]]; then
  HOME_DIR="$(CDPATH= cd -- "$USERPROFILE" && pwd -P)"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:-}"
      shift 2
      ;;
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    --out)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

infer_workspace_dir() {
  local cwd
  local oldpwd
  local candidate=""

  if [[ -n "${CODEX_WORKSPACE_ROOT:-}" && -d "${CODEX_WORKSPACE_ROOT:-}" ]]; then
    printf '%s\n' "$(CDPATH= cd -- "$CODEX_WORKSPACE_ROOT" && pwd -P)"
    return 0
  fi

  cwd="$(pwd -P)"
  if [[ "$cwd" != "$SKILL_DIR" && "$cwd" != "$SCRIPT_DIR" && "$cwd" != "$SKILL_DIR/"* ]]; then
    printf '%s\n' "$cwd"
    return 0
  fi

  if [[ -n "${OLDPWD:-}" && -d "${OLDPWD:-}" ]]; then
    oldpwd="$(CDPATH= cd -- "$OLDPWD" && pwd -P)"
    if [[ "$oldpwd" != "$SKILL_DIR" && "$oldpwd" != "$SCRIPT_DIR" && "$oldpwd" != "$SKILL_DIR/"* ]]; then
      printf '%s\n' "$oldpwd"
      return 0
    fi
  fi

  case "$SKILL_DIR" in
    */.agents/skills/*|*/.codex/skills/*|*/.claude/skills/*)
      candidate="$(CDPATH= cd -- "$SKILL_DIR/../../.." && pwd -P)"
      ;;
    */plugins/minecraft-codex-skills/skills/*)
      candidate="$(CDPATH= cd -- "$SKILL_DIR/../../../.." && pwd -P)"
      ;;
  esac

  if [[ -n "$candidate" && -n "$HOME_DIR" && "$candidate" == "$HOME_DIR" ]]; then
    case "$SKILL_DIR" in
      "$HOME_DIR/.agents/skills/"*|"$HOME_DIR/.codex/skills/"*|"$HOME_DIR/.claude/skills/"*)
        candidate=""
        ;;
    esac
  fi

  if [[ -n "$candidate" && "$candidate" != "$SKILL_DIR" && "$candidate" != "$SCRIPT_DIR" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
}

is_absolute_path() {
  local value="$1"
  [[ "$value" == /* || "$value" =~ ^[A-Za-z]:[\\/] ]]
}

resolve_out_dir() {
  local value="$1"
  local workspace=""
  local workspace_file=""

  if [[ "$value" == "__AUTO__" ]]; then
    workspace_file="$(mktemp)"
    if ! infer_workspace_dir >"$workspace_file"; then
      rm -f "$workspace_file"
      return 1
    fi
    cat "$workspace_file"
    rm -f "$workspace_file"
    return 0
  fi

  if is_absolute_path "$value"; then
    printf '%s\n' "$value"
    return 0
  fi

  workspace_file="$(mktemp)"
  if ! infer_workspace_dir >"$workspace_file"; then
    rm -f "$workspace_file"
    echo "Could not infer a project workspace for the relative --out path: $value" >&2
    echo "Re-run the command from your project workspace, set CODEX_WORKSPACE_ROOT, or pass an absolute --out path." >&2
    return 1
  fi
  workspace="$(cat "$workspace_file")"
  rm -f "$workspace_file"

  printf '%s\n' "${workspace%/}/${value#./}"
}

if [[ -z "$TYPE" || -z "$NAME" ]]; then
  echo "--type and --name are required" >&2
  usage >&2
  exit 1
fi

slug="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
if [[ -z "$slug" ]]; then
  echo "Could not derive a safe slug from --name" >&2
  exit 1
fi

requested_out_dir="$OUT_DIR"
resolved_out_dir=""
resolved_out_file="$(mktemp)"
if ! resolve_out_dir "$requested_out_dir" >"$resolved_out_file"; then
  rm -f "$resolved_out_file"
  if [[ "$requested_out_dir" == "__AUTO__" ]]; then
    echo "Could not infer a project workspace for the asset brief." >&2
    echo "Re-run the command from your project workspace or pass --out <dir> explicitly." >&2
  fi
  exit 1
fi
resolved_out_dir="$(cat "$resolved_out_file")"
rm -f "$resolved_out_file"
OUT_DIR="$resolved_out_dir"

mkdir -p "$OUT_DIR"
target="${OUT_DIR%/}/${slug}-asset-brief.md"

if [[ -e "$target" && "$OVERWRITE" -ne 1 ]]; then
  echo "Refusing to overwrite existing file: $target" >&2
  echo "Pass --overwrite if replacement is intentional." >&2
  exit 1
fi

cat >"$target" <<EOF
# ${NAME} Asset Brief

- Asset type: ${TYPE}
- Slug: ${slug}
- Owner: <project or repo name>
- Final path: <where the approved asset should live>

## Goal

<What should this image accomplish?>

## Minecraft Context

<Vanilla-faithful, modded tech, fantasy RPG server, etc.>

## Primary Subject

<Main subject or focal point>

## Must Keep

- <Details that should survive revisions>

## Avoid

- <Watermarks, extra logos, clutter, off-theme props>

## Composition

<Square icon, wide banner, flat texture sheet, mockup panel, etc.>

## Palette

<Color direction>

## Text

<Exact text if any, or state "none">

## Review Notes

- Tiny-size readability:
- Mobile crop concerns:
- Handoff target:
EOF

echo "Wrote $target"
