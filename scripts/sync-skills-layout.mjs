#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const canonicalDir = path.join(repoRoot, ".agents", "skills");
const mirrorDirs = [
  path.join(repoRoot, ".codex", "skills"),
  path.join(repoRoot, ".claude", "skills"),
  path.join(repoRoot, "plugins", "minecraft-codex-skills", "skills")
];
const mode = process.argv[2] ?? "sync";

function rel(file) {
  return path.relative(repoRoot, file).replaceAll(path.sep, "/");
}

function fail(message) {
  console.error(`[FAIL] ${message}`);
  process.exitCode = 1;
}

function listFiles(dir) {
  const files = [];
  function walk(current) {
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.isFile()) files.push(path.relative(dir, full).replaceAll(path.sep, "/"));
    }
  }
  walk(dir);
  return files.sort();
}

function sameFile(left, right) {
  const leftBuffer = fs.readFileSync(left);
  const rightBuffer = fs.readFileSync(right);
  return leftBuffer.length === rightBuffer.length && leftBuffer.equals(rightBuffer);
}

function syncMirror(mirrorDir) {
  fs.mkdirSync(path.dirname(mirrorDir), { recursive: true });
  fs.rmSync(mirrorDir, { recursive: true, force: true });
  fs.cpSync(canonicalDir, mirrorDir, { recursive: true, force: true });
  console.log(`[PASS] Synced ${rel(canonicalDir)} -> ${rel(mirrorDir)}`);
}

function checkMirror(mirrorDir) {
  if (!fs.existsSync(mirrorDir)) {
    fail(`Mirror directory missing: ${rel(mirrorDir)}`);
    return;
  }

  const canonicalFiles = listFiles(canonicalDir);
  const mirrorFiles = listFiles(mirrorDir);
  const allFiles = new Set([...canonicalFiles, ...mirrorFiles]);
  const drift = [];

  for (const file of [...allFiles].sort()) {
    const canonicalFile = path.join(canonicalDir, file);
    const mirrorFile = path.join(mirrorDir, file);
    if (!fs.existsSync(canonicalFile)) drift.push(`extra ${rel(mirrorFile)}`);
    else if (!fs.existsSync(mirrorFile)) drift.push(`missing ${rel(mirrorFile)}`);
    else if (!sameFile(canonicalFile, mirrorFile)) drift.push(`changed ${rel(mirrorFile)}`);
  }

  if (drift.length > 0) {
    fail(`Mirror drift detected between ${rel(canonicalDir)} and ${rel(mirrorDir)}`);
    for (const item of drift) console.error(item);
    return;
  }

  console.log(`[PASS] ${rel(canonicalDir)} and ${rel(mirrorDir)} are in sync`);
}

if (!fs.existsSync(canonicalDir)) {
  fail(`Missing canonical directory: ${rel(canonicalDir)}`);
} else if (!['sync', 'check'].includes(mode)) {
  console.error("Usage: sync-skills-layout.mjs [sync|check]");
  process.exit(2);
} else if (mode === "sync") {
  for (const mirrorDir of mirrorDirs) syncMirror(mirrorDir);
} else {
  for (const mirrorDir of mirrorDirs) checkMirror(mirrorDir);
  if (!process.exitCode) console.log("[PASS] Canonical and all mirror trees are in sync");
}
