#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import yaml from "js-yaml";

const ROOT = process.cwd();
const TARGETS = [
  path.join(ROOT, "README.md"),
  path.join(ROOT, "AGENTS.md"),
  path.join(ROOT, "docs"),
  path.join(ROOT, ".agents", "skills"),
  path.join(ROOT, "plugins"),
];

const errors = [];

function walkMarkdownFiles(target) {
  if (!fs.existsSync(target)) return [];
  const stat = fs.statSync(target);
  if (stat.isFile()) return target.endsWith(".md") ? [target] : [];

  const out = [];
  for (const entry of fs.readdirSync(target, { withFileTypes: true })) {
    const full = path.join(target, entry.name);
    if (entry.isDirectory()) out.push(...walkMarkdownFiles(full));
    else if (entry.isFile() && entry.name.endsWith(".md")) out.push(full);
  }
  return out;
}

function rel(file) {
  return path.relative(ROOT, file).replaceAll(path.sep, "/");
}

function addError(file, message) {
  errors.push(`${file}: ${message}`);
}

function validateJson(file, blockIndex, code) {
  const parts = code
    .split(/\n\s*\n(?=(?:\/\/[^\n]*\n\s*)*[\[{])/)
    .map((part) => part.replace(/^\s*\/\/[^\n]*\n/gm, "").trim())
    .filter(Boolean);

  for (const [partIndex, part] of parts.entries()) {
    if (!/^[\[{]/.test(part)) continue;

    try {
      JSON.parse(part);
    } catch (error) {
      const suffix = parts.length > 1 ? ` part #${partIndex + 1}` : "";
      addError(file, `json block #${blockIndex}${suffix} is invalid: ${error.message}`);
    }
  }
}

function validateYaml(file, blockIndex, code) {
  try {
    yaml.load(code);
  } catch (error) {
    addError(file, `yaml block #${blockIndex} is invalid: ${error.message}`);
  }
}

for (const file of TARGETS.flatMap(walkMarkdownFiles)) {
  const text = fs.readFileSync(file, "utf8");
  const fenceRe = /```([^\n]*)\n([\s\S]*?)```/g;
  let match;
  let blockIndex = 0;

  while ((match = fenceRe.exec(text)) !== null) {
    blockIndex += 1;
    const lang = match[1].trim().toLowerCase();
    const code = match[2];

    if (lang === "json") validateJson(rel(file), blockIndex, code);
    if (lang === "yaml" || lang === "yml") validateYaml(rel(file), blockIndex, code);
  }
}

if (errors.length > 0) {
  console.error("Documentation snippet validation failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Documentation snippet validation passed");
