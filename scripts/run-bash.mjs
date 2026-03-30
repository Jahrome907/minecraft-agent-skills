#!/usr/bin/env node
import fs from "node:fs";
import { spawnSync } from "node:child_process";

const bashArgs = process.argv.slice(2);
if (bashArgs.length === 0) {
  console.error("[FAIL] run-bash.mjs requires a target script path.");
  process.exit(2);
}

const candidates = [];
const seenCandidates = new Set();

function addCandidate(candidate) {
  if (!candidate || seenCandidates.has(candidate)) return;
  seenCandidates.add(candidate);
  candidates.push(candidate);
}

function probeBash(candidate) {
  const result = spawnSync(candidate, ["-lc", "exit 0"], {
    encoding: "utf8",
    stdio: "pipe"
  });
  if (result.error?.code === "ENOENT") return { ok: false, reason: result.error.message };
  if (result.error) return { ok: false, reason: result.error.message };
  if ((result.status ?? 1) !== 0) {
    const stderr = (result.stderr || "").trim();
    return { ok: false, reason: stderr || `probe exited with status ${result.status}` };
  }
  return { ok: true };
}

if (process.platform === "win32") {
  const commonRoots = [process.env["ProgramFiles"], process.env["ProgramFiles(x86)"], process.env.LocalAppData]
    .filter(Boolean);
  for (const root of commonRoots) {
    addCandidate(`${root}\\Git\\bin\\bash.exe`);
    addCandidate(`${root}\\Git\\usr\\bin\\bash.exe`);
    addCandidate(`${root}\\Programs\\Git\\bin\\bash.exe`);
    addCandidate(`${root}\\Programs\\Git\\usr\\bin\\bash.exe`);
  }

  const whereResult = spawnSync("where.exe", ["bash"], { encoding: "utf8", stdio: "pipe" });
  if ((whereResult.status ?? 1) === 0) {
    for (const line of (whereResult.stdout || "").split(/\r?\n/)) {
      const candidate = line.trim();
      if (candidate) addCandidate(candidate);
    }
  }
}

addCandidate("bash");

let lastFailure = null;
for (const candidate of candidates) {
  const probe = probeBash(candidate);
  if (!probe.ok) {
    lastFailure = `${candidate}: ${probe.reason}`;
    continue;
  }

  const result = spawnSync(candidate, bashArgs, { stdio: "inherit" });
  if (result.error?.code === "ENOENT") {
    lastFailure = `${candidate}: ${result.error.message}`;
    continue;
  }
  if (result.error) {
    lastFailure = `${candidate}: ${result.error.message}`;
    continue;
  }
  process.exit(result.status ?? 0);
}

console.error("[FAIL] Unable to locate a working bash executable.");
if (lastFailure) console.error(lastFailure);
process.exit(1);
