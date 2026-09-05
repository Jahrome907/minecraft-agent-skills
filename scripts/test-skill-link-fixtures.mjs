#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const auditScript = path.resolve("scripts/audit-skills.mjs");
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "minecraft-skill-links-"));
const surfaces = [".agents/skills", ".codex/skills", ".claude/skills", "plugins/minecraft-codex-skills/skills"];
const base = [
  "---",
  "name: link-fixture",
  "description: Validate local skill reference links.",
  "---",
  "# Link Fixture",
  "## Routing Boundaries",
  "- `Use when`: checking local links.",
  "- `Do not use when`: running a game."
].join("\n");

try {
  for (const surface of surfaces) {
    const references = path.join(tempRoot, surface, "link-fixture", "references");
    fs.mkdirSync(references, { recursive: true });
    fs.writeFileSync(path.join(references, "valid.md"), "Valid reference.\n");
    fs.writeFileSync(path.join(references, "valid file.md"), "Valid reference with spaces.\n");
  }

  const cases = [
    { link: '[reference](references/valid.md "Title")\n[reference](<references/valid file.md>)', status: 0 },
    { link: '[reference](references/missing.md "Title")', status: 1, error: "missing local link target" },
    { link: "[reference](<references/missing file.md>)", status: 1, error: "missing local link target" },
    { link: "[reference](<../outside file.md>)", status: 1, error: "local link leaves the self-contained skill" }
  ];
  for (const fixture of cases) {
    for (const surface of surfaces) {
      fs.writeFileSync(path.join(tempRoot, surface, "link-fixture", "SKILL.md"), `${base}\n${fixture.link}\n`);
    }
    const result = spawnSync(process.execPath, [auditScript], { cwd: tempRoot, encoding: "utf8" });
    assert.equal(result.status, fixture.status, `${fixture.link}\n${result.error ?? result.stderr}`);
    if (fixture.error) assert.ok(result.stderr.includes(fixture.error), result.stderr);
  }
  console.log("Skill link fixtures passed");
} finally {
  const relative = path.relative(os.tmpdir(), tempRoot);
  if (relative.startsWith("minecraft-skill-links-") && !relative.includes(path.sep)) {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}
