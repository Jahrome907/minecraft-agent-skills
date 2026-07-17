#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const PLUGIN_NAME = "minecraft-codex-skills";
const PACKAGE_JSON = path.join(ROOT, "package.json");
const PACKAGE_LOCK = path.join(ROOT, "package-lock.json");
const PLUGIN_ROOT = path.join(ROOT, "plugins", PLUGIN_NAME);
const CODEX_MANIFEST = path.join(PLUGIN_ROOT, ".codex-plugin", "plugin.json");
const CLAUDE_MANIFEST = path.join(PLUGIN_ROOT, ".claude-plugin", "plugin.json");
const PLUGIN_SKILLS = path.join(PLUGIN_ROOT, "skills");
const MARKETPLACE = path.join(ROOT, ".agents", "plugins", "marketplace.json");
const errors = [];

function addError(file, message) {
  errors.push(`${path.relative(ROOT, file).replaceAll(path.sep, "/")}: ${message}`);
}

function readJson(file) {
  if (!fs.existsSync(file)) {
    addError(file, "missing required JSON file");
    return null;
  }

  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    addError(file, `invalid JSON: ${error.message}`);
    return null;
  }
}

function requireText(value, file, field) {
  if (typeof value !== "string" || value.trim() === "") {
    addError(file, `missing non-empty \`${field}\``);
  }
}

const pkg = readJson(PACKAGE_JSON);
const packageLock = readJson(PACKAGE_LOCK);
const codexManifest = readJson(CODEX_MANIFEST);
const claudeManifest = readJson(CLAUDE_MANIFEST);
const marketplace = readJson(MARKETPLACE);

if (!fs.existsSync(PLUGIN_ROOT)) addError(PLUGIN_ROOT, "plugin root directory is missing");
if (!fs.existsSync(PLUGIN_SKILLS)) addError(PLUGIN_SKILLS, "plugin skills directory is missing");

const releaseVersion = pkg?.version;
requireText(releaseVersion, PACKAGE_JSON, "version");

if (packageLock) {
  if (packageLock.version !== releaseVersion) addError(PACKAGE_LOCK, `expected version \`${releaseVersion}\``);
  if (packageLock.packages?.[""]?.version !== releaseVersion) {
    addError(PACKAGE_LOCK, `expected root package version \`${releaseVersion}\``);
  }
}

if (codexManifest) {
  if (codexManifest.name !== PLUGIN_NAME) addError(CODEX_MANIFEST, `expected name \`${PLUGIN_NAME}\``);
  if (codexManifest.version !== releaseVersion) addError(CODEX_MANIFEST, `expected version \`${releaseVersion}\``);
  requireText(codexManifest.description, CODEX_MANIFEST, "description");
  if (codexManifest.skills !== "./skills/") addError(CODEX_MANIFEST, "expected \`skills\` to be \`./skills/\`");
}

if (claudeManifest) {
  if (claudeManifest.name !== PLUGIN_NAME) addError(CLAUDE_MANIFEST, `expected name \`${PLUGIN_NAME}\``);
  if (claudeManifest.version !== releaseVersion) addError(CLAUDE_MANIFEST, `expected version \`${releaseVersion}\``);
  requireText(claudeManifest.description, CLAUDE_MANIFEST, "description");
}

if (marketplace) {
  const pluginEntry = Array.isArray(marketplace.plugins)
    ? marketplace.plugins.find((entry) => entry?.name === PLUGIN_NAME)
    : null;

  if (!pluginEntry) {
    addError(MARKETPLACE, `missing plugin entry for \`${PLUGIN_NAME}\``);
  } else {
    if (pluginEntry.source?.source !== "local") addError(MARKETPLACE, "expected local plugin source");
    if (pluginEntry.source?.path !== "./plugins/minecraft-codex-skills") {
      addError(MARKETPLACE, "expected plugin path \`./plugins/minecraft-codex-skills\`");
    }
    if (pluginEntry.policy?.installation !== "AVAILABLE") addError(MARKETPLACE, "expected installation policy \`AVAILABLE\`");
    if (pluginEntry.policy?.authentication !== "ON_INSTALL") addError(MARKETPLACE, "expected authentication policy \`ON_INSTALL\`");
    requireText(pluginEntry.category, MARKETPLACE, "plugin category");
  }
}

if (errors.length > 0) {
  console.error("Plugin bundle validation failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Plugin bundle validation passed");
