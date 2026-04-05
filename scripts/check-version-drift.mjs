#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();

const checks = [
  {
    file: "README.md",
    required: [
      /Paper 1\.21\.11 server/,
      /Vanilla datapack\|1\.21–1\.21\.11 \(formats 48–94\.1; `min_format` \/ `max_format` from 1\.21\.9\+\)\|—/,
      /Resource pack\|1\.21–1\.21\.11 \(formats 34–75\.0; `min_format` \/ `max_format` from 1\.21\.9\+\)\|—/
    ]
  },
  {
    file: ".agents/skills/minecraft-multiloader/SKILL.md",
    required: [
      /minecraft_version=1\.21\.11/,
      /fabric_api_version=0\.116\.10\+1\.21\.1/,
      /neoforge_version=21\.11\.42/,
      /id "architectury-plugin" version "3\.4"/,
      /loom_version=1\.7/
    ],
    forbidden: [
      /1\.9-SNAPSHOT/,
      /21\.1\.172/,
      /0\.114\.0\+1\.21\.1/
    ]
  },
  {
    file: ".agents/skills/minecraft-ci-release/SKILL.md",
    required: [
      /1\.0\.0\+1\.21\.11/,
      /gameVersions\.addAll\("1\.21\.11"\)/,
      /cf\.addGameVersion\("1\.21\.11"\)/,
      /minecraft_version=1\.21\.11/
    ],
    forbidden: [
      /1\.0\.0\+1\.21\.1\s+← mod 1\.0\.0 for MC 1\.21\.1/,
      /gameVersions\.addAll\("1\.21\.1"\)/,
      /cf\.addGameVersion\("1\.21\.1"\)/
    ]
  },
  {
    file: ".agents/skills/minecraft-datapack/SKILL.md",
    required: [
      /1\.21\.11\s+\| `min_format: 94\.1`, `max_format: 94\.1`/,
      /"min_format": 94\.1/,
      /"max_format": 94\.1/
    ]
  },
  {
    file: ".agents/skills/minecraft-resource-pack/SKILL.md",
    required: [
      /1\.21\.11\s+\| `min_format: 75\.0`, `max_format: 75\.0`/,
      /"min_format": 75\.0/,
      /"max_format": 75\.0/
    ]
  },
  {
    file: ".agents/skills/minecraft-modding/references/neoforge-api.md",
    required: [
      /minecraft_version=1\.21\.11/,
      /neo_version=21\.11\.42/,
      /minecraft_version_range=\[1\.21\.11,1\.22\)/
    ],
    forbidden: [
      /neo_version=21\.1\.172/,
      /(^|\r?\n)minecraft_version=1\.21\.1(\r?\n|$)/
    ]
  },
  {
    file: ".agents/skills/minecraft-modding/references/fabric-api.md",
    required: [
      /minecraft_version=1\.21\.11/,
      /loader_version=0\.17\.3/,
      /fabric_version=0\.116\.10\+1\.21\.1/
    ],
    forbidden: [
      /0\.114\.0\+1\.21\.1/,
      /yarn_mappings=1\.21\.1\+build\.3/
    ]
  },
  {
    file: ".agents/skills/minecraft-datapack/scripts/validate-datapack.sh",
    required: [
      /pack\.min_format/,
      /pack\.max_format/
    ]
  },
  {
    file: ".agents/skills/minecraft-resource-pack/scripts/validate-resource-pack.sh",
    required: [
      /pack\.min_format/,
      /pack\.max_format/
    ]
  },
  {
    file: "scripts/run-skill-validator-fixtures.sh",
    required: [
      /datapack legacy pack metadata/,
      /resource-pack legacy pack metadata/,
      /testing valid/,
      /multiloader valid/
    ]
  }
];

let failures = 0;

for (const check of checks) {
  const target = path.join(repoRoot, check.file);
  const text = fs.readFileSync(target, "utf8");

  for (const pattern of check.required ?? []) {
    if (!pattern.test(text)) {
      console.error(`[FAIL] ${check.file} missing required pattern: ${pattern}`);
      failures += 1;
    }
  }

  for (const pattern of check.forbidden ?? []) {
    if (pattern.test(text)) {
      console.error(`[FAIL] ${check.file} still matches forbidden pattern: ${pattern}`);
      failures += 1;
    }
  }
}

if (failures > 0) {
  console.error(`[FAIL] version drift check failed with ${failures} issue(s)`);
  process.exit(1);
}

console.log("[PASS] version drift check passed");