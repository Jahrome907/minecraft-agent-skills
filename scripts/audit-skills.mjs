#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import * as yaml from "js-yaml";

const ROOT = process.cwd();
const CANONICAL = path.join(ROOT, ".agents", "skills");
const MIRRORS = [
  { dir: path.join(ROOT, ".codex", "skills"), label: ".codex/skills" },
  { dir: path.join(ROOT, ".claude", "skills"), label: ".claude/skills" },
  { dir: path.join(ROOT, "plugins", "minecraft-codex-skills", "skills"), label: "plugins/minecraft-codex-skills/skills" },
];
const FORBIDDEN_REPO_ROOT_SKILL_FILES = [
  path.join(ROOT, "SKILL.md"),
  path.join(ROOT, "references", "asset-recipes.md"),
  path.join(ROOT, "references", "prompt-patterns.md"),
  path.join(ROOT, "scripts", "scaffold-asset-brief.sh"),
];

const errors = [];

function addError(file, message) {
  errors.push(`${file}: ${message}`);
}

function readText(file) {
  return fs.readFileSync(file, "utf8").replace(/^\uFEFF/, "").replace(/\r\n/g, "\n");
}

function walkFiles(dir) {
  const out = [];
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walkFiles(full));
    else out.push(full);
  }
  return out;
}

function rel(p) {
  return path.relative(ROOT, p).replaceAll(path.sep, "/");
}

function hashFile(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function parseFrontmatter(text, file) {
  const match = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) {
    addError(file, "missing YAML frontmatter");
    return null;
  }
  const raw = match[1];
  let frontmatter;
  try {
    frontmatter = yaml.load(raw);
  } catch (error) {
    addError(file, `invalid YAML frontmatter: ${error.message}`);
    return null;
  }

  const name = typeof frontmatter?.name === "string" ? frontmatter.name.trim() : "";
  const description = typeof frontmatter?.description === "string" ? frontmatter.description.trim() : "";
  if (!name) addError(file, "frontmatter missing `name`");
  if (!description) addError(file, "frontmatter missing `description`");
  if (description.length > 300) {
    addError(file, `frontmatter description is ${description.length} characters; keep discovery metadata at or below 300`);
  }

  return { name };
}

function checkRunnableBlocks(file, text) {
  const chunks = text.split("```");
  const runnableLangs = new Set(["bash", "sh", "mcfunction", "java", "json", "yaml", "yml", "toml", "properties"]);

  for (let i = 1; i < chunks.length; i += 2) {
    const block = chunks[i];
    const nl = block.indexOf("\n");
    if (nl < 0) continue;
    const lang = block.slice(0, nl).trim().toLowerCase();
    const code = block.slice(nl + 1);
    if (!runnableLangs.has(lang)) continue;

    if (/\{player\}/.test(code)) {
      addError(file, "runnable code block contains placeholder `{player}`");
    }
    if (/\brun\s+\.\.\./.test(code)) {
      addError(file, "runnable code block contains unresolved `run ...` placeholder");
    }
    if (/^\s*\.\.\.\s*$/m.test(code)) {
      addError(file, "runnable code block contains unresolved ellipsis line");
    }
    if (lang === "bash" || lang === "sh") checkUnsafeRcon(file, code);
  }
}

function checkUnsafeRcon(file, text) {
  if (/\bmcrcon\b[^\n]*\s-p(?:\s|=)/.test(text)) {
    addError(file, "RCON example passes a password on the command line; use MCRCON_PASS or protected secret injection");
  }
}

function checkPathConventions(file, text) {
  const relativeFile = rel(file);
  const legacyForge1201PathNeedles = [
    ["loot_tables", "use `loot_table` for 1.21.x conventions"],
    ["tags/blocks", "use `tags/block` for 1.21.x conventions"],
    ["tags/items", "use `tags/item` for 1.21.x conventions"],
  ];
  const banned = [
    ["biome_modifiers", "use `biome_modifier` for NeoForge biome modifier path"],
    ["max-player-count", "use `max-players` (server.properties key)"],
    ["<mc_version>-<mod_version>", "use `{mod_version}+{mc_version}` for mod version examples"],
    ["1.21.1-2.0.0", "use `{mod_version}+{mc_version}` for mod version examples"],
  ];

  const legacyForgeReference = file.endsWith("forge-1.20.1-api.md");
  const moddingSkill = relativeFile.endsWith("minecraft-modding/SKILL.md");

  for (const line of text.split("\n")) {
    const lineAllowsLegacyForge1201Paths = legacyForgeReference || (moddingSkill && line.includes("Forge 1.20.1"));
    for (const [needle, msg] of legacyForge1201PathNeedles) {
      if (line.includes(needle) && !lineAllowsLegacyForge1201Paths) addError(file, msg);
    }
  }

  for (const [needle, msg] of banned) {
    if (text.includes(needle)) addError(file, msg);
  }

  if (/\.agents\/skills\/[^/\s]+\/scripts\/[^\s`]+/.test(text)) {
    addError(file, "hardcoded `.agents/skills/.../scripts/...` path in docs; use mirror-safe `./scripts/...` guidance or document all mirrors explicitly");
  }
}

function checkRoutingBoundaries(file, text) {
  const hasSection = /^#{2,3} Routing Boundaries$/m.test(text);
  if (!hasSection) {
    addError(file, "missing `Routing Boundaries` section at heading level 2 or 3");
    return;
  }

  const hasUseWhen = /- `Use when`:/m.test(text);
  const hasDoNotUseWhen = /- `Do not use when`:/m.test(text);
  if (!hasUseWhen) addError(file, "routing section missing `- `Use when`:` criterion");
  if (!hasDoNotUseWhen) addError(file, "routing section missing `- `Do not use when`:` criterion");
}

function checkLocalLinks(file, text) {
  const fullPath = path.resolve(ROOT, file);
  const skillDir = path.join(CANONICAL, path.relative(CANONICAL, fullPath).split(path.sep)[0]);
  for (const match of text.matchAll(/\[[^\]]*\]\((?:<([^>]+)>|([^\s)]+))(?:\s+(?:"[^"]*"|'[^']*'|\([^)]*\)))?\)/g)) {
    const href = match[1] ?? match[2];
    if (/^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith("#")) continue;
    const target = path.resolve(path.dirname(fullPath), href.split("#")[0]);
    const relative = path.relative(skillDir, target);
    if (relative.startsWith("..") || path.isAbsolute(relative)) {
      addError(file, `local link leaves the self-contained skill: ${href}`);
    } else if (!fs.existsSync(target)) {
      addError(file, `missing local link target: ${href}`);
    }
  }
}

function checkSpecialSkillRequirements(skillName, file, text) {
  if (skillName !== "minecraft-imagegen") return;

  if (!text.includes("current host does not expose built-in image generation")) {
    addError(file, "minecraft-imagegen must explicitly guard hosts that do not expose image generation");
  }

  if (!text.includes("this skill is unavailable on that host")) {
    addError(file, "minecraft-imagegen must tell unsupported hosts to stop at planning/briefing instead of promising image generation");
  }
}

for (const file of FORBIDDEN_REPO_ROOT_SKILL_FILES) {
  if (fs.existsSync(file)) {
    addError(file, "unexpected repo-root minecraft-imagegen copy; keep image skill files only under .agents/skills and synced mirrors");
  }
}

if (!fs.existsSync(CANONICAL)) {
  addError(".agents/skills", "canonical skills directory is missing");
} else {

  const skillDirs = fs.readdirSync(CANONICAL, { withFileTypes: true }).filter((d) => d.isDirectory());
  for (const dirent of skillDirs) {
    const skillName = dirent.name;
    const skillFile = path.join(CANONICAL, skillName, "SKILL.md");
    const skillRel = rel(skillFile);

    if (!/^[a-z0-9-]+$/.test(skillName) || skillName.length >= 64) {
      addError(path.join(".agents/skills", skillName), "skill directory name must use lowercase letters, digits, and hyphens and stay under 64 characters");
    }

    if (!fs.existsSync(skillFile)) {
      addError(path.join(".agents/skills", skillName), "missing SKILL.md");
      continue;
    }

    const text = readText(skillFile);
    if (text.trimEnd().split("\n").length > 500) {
      addError(skillRel, "SKILL.md exceeds 500 lines; move conditional detail into local references");
    }
    const fm = parseFrontmatter(text, skillRel);
    if (fm?.name && fm.name !== skillName) {
      addError(skillRel, `frontmatter name \`${fm.name}\` does not match directory \`${skillName}\``);
    }

    checkRoutingBoundaries(skillRel, text);
    checkRunnableBlocks(skillRel, text);
    checkPathConventions(skillRel, text);
    checkSpecialSkillRequirements(skillName, skillRel, text);
  }

  const canonicalFiles = walkFiles(CANONICAL);
  for (const file of canonicalFiles) {
    if (!file.endsWith(".md") && !file.endsWith(".sh")) continue;
    const txt = readText(file);
    if (file.endsWith(".md")) {
      checkLocalLinks(rel(file), txt);
      checkRunnableBlocks(rel(file), txt);
      checkPathConventions(rel(file), txt);
    }
    if (file.endsWith(".sh")) checkUnsafeRcon(rel(file), txt);
  }
}

for (const { dir: MIRROR, label: mirrorLabel } of MIRRORS) {
  if (!fs.existsSync(MIRROR)) {
    addError(mirrorLabel, "mirror skills directory is missing");
  } else if (fs.existsSync(CANONICAL)) {

    const canonicalFiles = walkFiles(CANONICAL).map((p) => path.relative(CANONICAL, p)).sort();
    const mirrorFiles = walkFiles(MIRROR).map((p) => path.relative(MIRROR, p)).sort();

    const onlyCanonical = canonicalFiles.filter((f) => !mirrorFiles.includes(f));
    const onlyMirror = mirrorFiles.filter((f) => !canonicalFiles.includes(f));

    for (const f of onlyCanonical) addError(`.agents/skills/${f}`, `missing from mirror ${mirrorLabel}`);
    for (const f of onlyMirror) addError(`${mirrorLabel}/${f}`, "missing from canonical .agents/skills");

    for (const f of canonicalFiles) {
      if (!mirrorFiles.includes(f)) continue;
      const cf = path.join(CANONICAL, f);
      const mf = path.join(MIRROR, f);
      if (hashFile(cf) !== hashFile(mf)) {
        addError(`${mirrorLabel}/${f}`, "content drift from canonical .agents/skills");
      }
    }
  }
}

if (errors.length > 0) {
  console.error("Skill audit failed:\n");
  for (const err of errors) console.error(`- ${err}`);
  process.exit(1);
}

console.log("Skill audit passed");
