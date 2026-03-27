#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const PLUGIN_NAME = "minecraft-codex-skills";
const PACKAGE_JSON = path.join(ROOT, "package.json");
const PLUGIN_ROOT = path.join(ROOT, "plugins", PLUGIN_NAME);
const CODEX_MANIFEST = path.join(PLUGIN_ROOT, ".codex-plugin", "plugin.json");
const CLAUDE_MANIFEST = path.join(PLUGIN_ROOT, ".claude-plugin", "plugin.json");
const PLUGIN_README = path.join(PLUGIN_ROOT, "README.md");
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

function readText(file) {
  if (!fs.existsSync(file)) {
    addError(file, "missing required text file");
    return null;
  }

  return fs.readFileSync(file, "utf8");
}

const pkg = readJson(PACKAGE_JSON);
const codexManifest = readJson(CODEX_MANIFEST);
const claudeManifest = readJson(CLAUDE_MANIFEST);
const marketplace = readJson(MARKETPLACE);
const pluginReadme = readText(PLUGIN_README);

if (!fs.existsSync(PLUGIN_ROOT)) addError(PLUGIN_ROOT, "plugin root directory is missing");
if (!fs.existsSync(PLUGIN_SKILLS)) addError(PLUGIN_SKILLS, "plugin skills directory is missing");

const releaseVersion = pkg?.version;
if (!releaseVersion) {
  addError(PACKAGE_JSON, "missing top-level `version` used as the plugin bundle release source of truth");
}

if (codexManifest) {
  if (codexManifest.name !== PLUGIN_NAME) addError(CODEX_MANIFEST, `expected name \`${PLUGIN_NAME}\``);
  if (codexManifest.version !== releaseVersion) addError(CODEX_MANIFEST, `expected version \`${releaseVersion}\``);
  if (codexManifest.skills !== "./skills/") addError(CODEX_MANIFEST, "expected `skills` to be `./skills/`");
}

if (claudeManifest) {
  if (claudeManifest.name !== PLUGIN_NAME) addError(CLAUDE_MANIFEST, `expected name \`${PLUGIN_NAME}\``);
  if (claudeManifest.version !== releaseVersion) addError(CLAUDE_MANIFEST, `expected version \`${releaseVersion}\``);
}

if (marketplace) {
  const pluginEntry = Array.isArray(marketplace.plugins)
    ? marketplace.plugins.find((entry) => entry?.name === PLUGIN_NAME)
    : null;

  if (!pluginEntry) {
    addError(MARKETPLACE, `missing plugin entry for \`${PLUGIN_NAME}\``);
  } else {
    if (pluginEntry.source?.source !== "local") addError(MARKETPLACE, "expected plugin source.source to be `local`");
    if (pluginEntry.source?.path !== "./plugins/minecraft-codex-skills") {
      addError(MARKETPLACE, "expected plugin source.path to be `./plugins/minecraft-codex-skills`");
    }
    if (pluginEntry.policy?.installation !== "AVAILABLE") {
      addError(MARKETPLACE, "expected plugin policy.installation to be `AVAILABLE`");
    }
    if (pluginEntry.policy?.authentication !== "ON_INSTALL") {
      addError(MARKETPLACE, "expected plugin policy.authentication to be `ON_INSTALL`");
    }
  }
}

if (pluginReadme) {
  const requiredReadmeSnippets = [
    "plugins/minecraft-codex-skills/",
    ".agents/plugins/marketplace.json",
    "Open `/plugins` and install `minecraft-codex-skills` from the repo marketplace.",
    "claude --plugin-dir ./plugins/minecraft-codex-skills",
  ];

  for (const snippet of requiredReadmeSnippets) {
    if (!pluginReadme.includes(snippet)) {
      addError(PLUGIN_README, `missing required install guidance snippet: ${snippet}`);
    }
  }
}

if (errors.length > 0) {
  console.error("Plugin bundle validation failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Plugin bundle validation passed");