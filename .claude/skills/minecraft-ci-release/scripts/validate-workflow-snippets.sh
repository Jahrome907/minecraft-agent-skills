#!/usr/bin/env bash
set -euo pipefail

ROOT='.'
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: validate-workflow-snippets.sh [--root <path>] [--strict]

Validates workflow snippets inside SKILL.md:
- extracts fenced yaml/yml code blocks
- checks required workflow keys (name/on/jobs) for workflow-like snippets
- detects unresolved placeholders and obviously broken globs
- checks secret usage vs documented secret list in SKILL.md
USAGE
      exit 0
      ;;
    *)
      echo "[FAIL] unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

SKILL_FILE="$ROOT/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "[FAIL] missing SKILL.md at $SKILL_FILE"
  exit 1
fi

node - "$SKILL_FILE" "$STRICT" <<'NODE'
const fs = require('node:fs');

const skillFile = process.argv[2];
const strict = process.argv[3] === '1';

const text = fs.readFileSync(skillFile, 'utf8');

let failures = 0;
let warnings = 0;

const pass = (msg) => console.log(`[PASS] ${msg}`);
const warn = (msg) => {
  warnings += 1;
  console.log(`[WARN] ${msg}`);
};
const fail = (msg) => {
  failures += 1;
  console.log(`[FAIL] ${msg}`);
};

console.log('=== Workflow Snippet Validator ===');

const blocks = [];
const fenceRe = /```(?:yaml|yml)\n([\s\S]*?)```/g;
let match;
while ((match = fenceRe.exec(text)) !== null) {
  blocks.push(match[1]);
}

if (blocks.length === 0) {
  fail('no yaml/yml fenced code blocks found in SKILL.md');
}

const usedSecrets = new Set();
const documentedSecrets = new Set();

const secretUseRe = /\$\{\{\s*secrets\.([A-Z0-9_]+)\s*\}\}/g;
let sm;
while ((sm = secretUseRe.exec(text)) !== null) {
  usedSecrets.add(sm[1]);
}

const lines = text.split(/\r?\n/);
let inSecretSection = false;
for (const line of lines) {
  if (/^##+\s+.*secret/i.test(line)) {
    inSecretSection = true;
    continue;
  }
  if (inSecretSection && /^##+\s+/.test(line)) {
    inSecretSection = false;
  }
  if (!inSecretSection) continue;

  for (const m of line.matchAll(/`([A-Z][A-Z0-9_]{2,})`/g)) {
    documentedSecrets.add(m[1]);
  }
  for (const m of line.matchAll(/\b([A-Z][A-Z0-9_]*(?:TOKEN|SECRET|KEY))\b/g)) {
    documentedSecrets.add(m[1]);
  }
}

if (usedSecrets.size === 0) {
  warn('no `${{ secrets.* }}` references found');
} else {
  pass(`found ${usedSecrets.size} secret reference(s)`);
}

for (const secret of usedSecrets) {
  if (!documentedSecrets.has(secret)) {
    fail(`secret used but not documented in a Secrets section: ${secret}`);
  }
}
for (const secret of documentedSecrets) {
  if (!usedSecrets.has(secret)) {
    warn(`secret documented but not referenced in snippets: ${secret}`);
  }
}

const placeholderRe = /(REPLACE_ME|TODO|<[^>]+>|yourname|your-repo|path\/to\/|example\/repo)/i;
const badGlobRe = /\*\*\*|\*\*\/\*\*\/|\.\*\*/;

blocks.forEach((block, idx) => {
  const label = `block #${idx + 1}`;
  const isWorkflowLike = /^\s*jobs\s*:/m.test(block) || /^\s*on\s*:/m.test(block);

  if (isWorkflowLike) {
    if (!/^\s*name\s*:/m.test(block)) fail(`${label} missing top-level \`name:\``);
    if (!/^\s*on\s*:/m.test(block)) fail(`${label} missing top-level \`on:\``);
    if (!/^\s*jobs\s*:/m.test(block)) fail(`${label} missing top-level \`jobs:\``);
  }

  if (placeholderRe.test(block)) {
    fail(`${label} contains unresolved placeholder text`);
  } else {
    pass(`${label} has no obvious placeholder tokens`);
  }

  if (badGlobRe.test(block)) {
    warn(`${label} contains suspicious glob pattern`);
  }

  const blockLines = block.split(/\r?\n/);
  blockLines.forEach((line, lineIdx) => {
    if (/\t/.test(line)) {
      fail(`${label} line ${lineIdx + 1} contains tab indentation`);
    }
    if (/^ +/.test(line)) {
      const spaces = line.match(/^ +/)[0].length;
      if (spaces % 2 !== 0) {
        warn(`${label} line ${lineIdx + 1} uses odd indentation (${spaces} spaces)`);
      }
    }
  });
});

if (failures > 0) {
  console.log(`[FAIL] workflow snippet validation failed with ${failures} error(s) and ${warnings} warning(s)`);
  process.exit(1);
}

if (strict && warnings > 0) {
  console.log(`[FAIL] workflow snippet strict mode failed on ${warnings} warning(s)`);
  process.exit(1);
}

console.log(`[PASS] workflow snippet validation passed with ${warnings} warning(s)`);
NODE
