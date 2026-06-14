#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();

const checks = [
  {
    file: "README.md",
    required: [
      /Paper 1\.21\.11 server/,
      /Fabric\|1\.21\.11 line \(`fabric-loader:0\.19\.3`, `fabric-api:0\.141\.4\+1\.21\.11`, Loom 1\.17\.11\)\|21/,
      /Vanilla datapack\|1\.21-1\.21\.11 \(`pack_format` 48-81 through 1\.21\.8; exact 1\.21\.11 metadata uses `\[94, 1\]` full-version arrays\)\|-/,
      /Resource pack\|1\.21-1\.21\.11 \(`pack_format` 34-64 through 1\.21\.8; exact 1\.21\.11 metadata uses `\[75, 0\]` full-version arrays\)\|-/
    ]
  },
  {
    file: ".agents/skills/minecraft-multiloader/SKILL.md",
    required: [
      /mod_version=1\.0\.0/,
      /minecraft_version=1\.21\.11/,
      /architectury_version=19\.0\.1/,
      /fabric_loader_version=0\.19\.3/,
      /fabric_api_version=0\.141\.4\+1\.21\.11/,
      /neoforge_version=21\.11\.42/,
      /id "architectury-plugin" version "3\.4"/,
      /loom_version=1\.17\.11/,
      /dev\.architectury:architectury-fabric/,
      /dev\.architectury:architectury-neoforge/,
      /"fabric-api": ">=0\.141\.4\+1\.21\.11"/,
      /"minecraft": "~1\.21\.11"/,
      /loaderVersion = "\[1,\)"/
    ],
    forbidden: [
      /1\.9-SNAPSHOT/,
      /21\.1\.172/,
      /0\.114\.0\+1\.21\.1/,
      /0\.116\.10\+1\.21\.1/,
      /loom_version=1\.7/,
      /dev\.architectury:architectury-api:/,
      /"fabric-api": "\*"/,
      /"minecraft": "1\.21\.11"/
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
      /1\.21\.11\s+\| `min_format: \[94, 1\]`, `max_format: \[94, 1\]`/,
      /1\.21\.9 \/ 1\.21\.10\s+\| `min_format: \[88, 0\]`, `max_format: \[88, 0\]`/,
      /"min_format": \[94, 1\]/,
      /"max_format": \[94, 1\]/
    ],
    forbidden: [
      /"min_format": 94\.1/,
      /"max_format": 94\.1/
    ]
  },
  {
    file: ".agents/skills/minecraft-resource-pack/SKILL.md",
    required: [
      /1\.21\.9 \/ 1\.21\.10\s+\| `min_format: \[69, 0\]`, `max_format: \[69, 0\]`/,
      /1\.21\.11\s+\| `min_format: \[75, 0\]`, `max_format: \[75, 0\]`/,
      /"min_format": \[75, 0\]/,
      /"max_format": \[75, 0\]/
    ],
    forbidden: [
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
      /loader_version=0\.19\.3/,
      /fabric_version=0\.141\.4\+1\.21\.11/,
      /yarn_mappings=1\.21\.11\+build\.6/,
      /"fabric-api": ">=0\.141\.4\+1\.21\.11"/
    ],
    forbidden: [
      /0\.114\.0\+1\.21\.1/,
      /0\.116\.10\+1\.21\.1/,
      /loader_version=0\.17\.3/,
      /yarn_mappings=1\.21\.1\+build\.3/,
      /"fabric-api": "\*"/
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
