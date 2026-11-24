#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import * as yaml from "js-yaml";

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

function addError(file, location, message) {
  const relativeFile = path.relative(process.cwd(), file).replaceAll(path.sep, "/");
  errors.push(`${relativeFile}${location ? `:${location}` : ""}: ${message}`);
}

function validateUse(file, location, ref) {
  if (typeof ref !== "string" || !ref) {
    addError(file, location, "uses must be a non-empty string");
  } else if (ref.startsWith("docker://")) {
    if (!/^docker:\/\/[^@\s]+@sha256:[0-9a-f]{64}$/.test(ref)) {
      addError(file, location, `Docker action must be pinned to a SHA-256 digest: ${ref}`);
    }
  } else if (!ref.startsWith("./") && !ref.startsWith("$/")) {
    if (!ref.includes("@")) {
      addError(file, location, `action reference is missing a ref: ${ref}`);
    } else if (!/@[0-9a-f]{40}$/.test(ref)) {
      addError(file, location, `action must be pinned to a full commit SHA: ${ref}`);
    }
  }
}

if (!fs.existsSync(root)) {
  console.error(`[FAIL] missing workflows directory: ${root}`);
  process.exit(1);
}

for (const file of walk(root)) {
  let workflow;
  try {
    workflow = yaml.load(fs.readFileSync(file, "utf8"));
  } catch (error) {
    addError(file, "", `invalid workflow YAML: ${error.reason ?? error.message}`);
    continue;
  }
  for (const [jobId, job] of Object.entries(workflow?.jobs ?? {})) {
    if (Object.hasOwn(job ?? {}, "uses")) validateUse(file, `jobs.${jobId}.uses`, job.uses);
    if (!Array.isArray(job?.steps)) continue;
    job.steps.forEach((step, index) => {
      if (Object.hasOwn(step ?? {}, "uses")) {
        validateUse(file, `jobs.${jobId}.steps[${index}].uses`, step.uses);
      }
    });
  }
}

if (errors.length > 0) {
  console.error("Workflow action pin check failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Workflow action pin check passed");
