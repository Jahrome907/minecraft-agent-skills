#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const ROOT = process.cwd();
const CANONICAL = path.join(ROOT, ".agents", "skills");
const REQUIRED_SKILLS_INDEX = "README.md";
const MIRRORS = [
  { dir: path.join(ROOT, ".codex", "skills"), label: ".codex/skills" },
  { dir: path.join(ROOT, ".claude", "skills"), label: ".claude/skills" },
  { dir: path.join(ROOT, "plugins", "minecraft-codex-skills", "skills"), label: "plugins/minecraft-codex-skills/skills" },
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
  const name = raw.match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const hasDescription = /^description:\s*>?/m.test(raw);
  if (!name) addError(file, "frontmatter missing `name`");
  if (!hasDescription) addError(file, "frontmatter missing `description`");
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
  }
}

function checkPathConventions(file, text) {
  const banned = [
    ["loot_tables", "use `loot_table` for 1.21.x conventions"],
    ["tags/blocks", "use `tags/block` for 1.21.x conventions"],
    ["tags/items", "use `tags/item` for 1.21.x conventions"],
    ["biome_modifiers", "use `biome_modifier` for NeoForge biome modifier path"],
    ["max-player-count", "use `max-players` (server.properties key)"],
    ["<mc_version>-<mod_version>", "use `{mod_version}+{mc_version}` for mod version examples"],
    ["1.21.1-2.0.0", "use `{mod_version}+{mc_version}` for mod version examples"],
  ];

  for (const [needle, msg] of banned) {
    if (text.includes(needle)) addError(file, msg);
  }

  if (/\.agents\/skills\/[^/\s]+\/scripts\/[^\s`]+/.test(text)) {
    addError(file, "hardcoded `.agents/skills/.../scripts/...` path in docs; use mirror-safe `./scripts/...` guidance or document all mirrors explicitly");
  }
}

function checkRoutingBoundaries(file, text) {
  const hasSection = /^### Routing Boundaries$/m.test(text);
  if (!hasSection) {
    addError(file, "missing `### Routing Boundaries` section");
    return;
  }

  const hasUseWhen = /- `Use when`:/m.test(text);
  const hasDoNotUseWhen = /- `Do not use when`:/m.test(text);
  if (!hasUseWhen) addError(file, "routing section missing `- `Use when`:` criterion");
  if (!hasDoNotUseWhen) addError(file, "routing section missing `- `Do not use when`:` criterion");
}

if (!fs.existsSync(CANONICAL)) {
  addError(".agents/skills", "canonical skills directory is missing");
} else {
  const canonicalIndex = path.join(CANONICAL, REQUIRED_SKILLS_INDEX);
  if (!fs.existsSync(canonicalIndex)) {
    addError(rel(canonicalIndex), "required canonical skills index is missing");
  }

  const skillDirs = fs.readdirSync(CANONICAL, { withFileTypes: true }).filter((d) => d.isDirectory());
  for (const dirent of skillDirs) {
    const skillName = dirent.name;
    const skillFile = path.join(CANONICAL, skillName, "SKILL.md");
    const skillRel = rel(skillFile);

    if (!fs.existsSync(skillFile)) {
      addError(path.join(".agents/skills", skillName), "missing SKILL.md");
      continue;
    }

    const text = readText(skillFile);
    const fm = parseFrontmatter(text, skillRel);
    if (fm?.name && fm.name !== skillName) {
      addError(skillRel, `frontmatter name \`${fm.name}\` does not match directory \`${skillName}\``);
    }

    checkRoutingBoundaries(skillRel, text);
    checkRunnableBlocks(skillRel, text);
    checkPathConventions(skillRel, text);
  }

  const canonicalFiles = walkFiles(CANONICAL);
  for (const file of canonicalFiles) {
    if (!file.endsWith(".md") && !file.endsWith(".sh")) continue;
    const txt = readText(file);
    if (file.endsWith(".md")) {
      checkRunnableBlocks(rel(file), txt);
      checkPathConventions(rel(file), txt);
    }
  }
}

for (const { dir: MIRROR, label: mirrorLabel } of MIRRORS) {
  if (!fs.existsSync(MIRROR)) {
    addError(mirrorLabel, "mirror skills directory is missing");
  } else if (fs.existsSync(CANONICAL)) {
    const mirrorIndex = path.join(MIRROR, REQUIRED_SKILLS_INDEX);
    if (!fs.existsSync(mirrorIndex)) {
      addError(rel(mirrorIndex), "required mirrored skills index is missing");
    }

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
