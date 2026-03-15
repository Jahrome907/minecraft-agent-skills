#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);
let root = path.join(process.cwd(), ".github", "workflows");

for (let i = 0; i < args.length; i += 1) {
  const arg = args[i];
  if (arg === "--root") {
    root = path.resolve(args[i + 1] ?? "");
    i += 1;
    continue;
  }

  console.error(`[FAIL] unknown arg: ${arg}`);
  process.exit(1);
}

const errors = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return [];

  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(full));
    else if (entry.isFile() && (entry.name.endsWith(".yml") || entry.name.endsWith(".yaml"))) out.push(full);
  }
  return out;
}

function addError(file, lineNumber, message) {
  errors.push(`${path.relative(process.cwd(), file).replaceAll(path.sep, "/")}:${lineNumber}: ${message}`);
}

function validateUse(file, lineNumber, ref) {
  if (ref.startsWith("./") || ref.startsWith("docker://")) return;

  if (!ref.includes("@")) {
    addError(file, lineNumber, `action reference is missing a ref: ${ref}`);
    return;
  }

  if (ref.startsWith("actions/")) return;

  if (!/@[0-9a-f]{40}$/.test(ref)) {
    addError(file, lineNumber, `third-party action must be pinned to a full commit SHA: ${ref}`);
  }
}

if (!fs.existsSync(root)) {
  console.error(`[FAIL] missing workflows directory: ${root}`);
  process.exit(1);
}

for (const file of walk(root)) {
  const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
  lines.forEach((line, index) => {
    const match = line.match(/^\s*(?:-\s*)?uses:\s*['"]?([^'"#\s]+)['"]?(?:\s+#.*)?$/);
    if (!match) return;
    validateUse(file, index + 1, match[1]);
  });
}

if (errors.length > 0) {
  console.error("Workflow action pin check failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Workflow action pin check passed");
