#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import yaml from "js-yaml";

const repoRoot = process.cwd();
const errors = [];

function filePath(relativePath) {
  return path.join(repoRoot, relativePath);
}

function addError(relativePath, message) {
  errors.push(`${relativePath}: ${message}`);
}

function requireFile(relativePath) {
  const fullPath = filePath(relativePath);
  if (!fs.existsSync(fullPath)) {
    addError(relativePath, "missing required file");
    return null;
  }
  return fullPath;
}

function readUtf8(relativePath) {
  const fullPath = requireFile(relativePath);
  if (!fullPath) return "";
  return fs.readFileSync(fullPath, "utf8");
}

function parseYamlFile(relativePath) {
  const source = readUtf8(relativePath);
  if (!source) return null;

  try {
    return yaml.load(source);
  } catch (error) {
    addError(relativePath, `invalid YAML: ${error.message}`);
    return null;
  }
}

const codeownersPath = ".github/CODEOWNERS";
const codeowners = readUtf8(codeownersPath);
if (codeowners) {
  if (!/^\*\s+@\S+/m.test(codeowners)) {
    addError(codeownersPath, "must include a default owner entry like '* @owner'");
  }
}

const prTemplatePath = ".github/PULL_REQUEST_TEMPLATE.md";
const prTemplate = readUtf8(prTemplatePath);
if (prTemplate) {
  for (const token of ["## Summary", "## Verification", "## Checklist", "CHANGELOG.md", "npm run check"]) {
    if (!prTemplate.includes(token)) {
      addError(prTemplatePath, `missing required guidance: ${token}`);
    }
  }
}

function validateIssueForm(relativePath, expectedName) {
  const doc = parseYamlFile(relativePath);
  if (!doc || typeof doc !== "object") return;

  if (doc.name !== expectedName) {
    addError(relativePath, `expected name '${expectedName}'`);
  }
  if (typeof doc.description !== "string" || doc.description.trim() === "") {
    addError(relativePath, "missing non-empty description");
  }
  if (typeof doc.title !== "string" || doc.title.trim() === "") {
    addError(relativePath, "missing title prefix");
  }
  if (!Array.isArray(doc.body) || doc.body.length === 0) {
    addError(relativePath, "must define at least one body element");
  }
}

validateIssueForm(".github/ISSUE_TEMPLATE/bug_report.yml", "Bug report");
validateIssueForm(".github/ISSUE_TEMPLATE/feature_request.yml", "Feature request");

const issueConfigPath = ".github/ISSUE_TEMPLATE/config.yml";
const issueConfig = parseYamlFile(issueConfigPath);
if (issueConfig && typeof issueConfig === "object") {
  if (!Array.isArray(issueConfig.contact_links) || issueConfig.contact_links.length === 0) {
    addError(issueConfigPath, "must define at least one contact link");
  }
}

if (errors.length > 0) {
  console.error("GitHub community file check failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("GitHub community file check passed");
