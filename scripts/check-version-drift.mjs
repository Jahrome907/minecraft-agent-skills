#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();

const checks = [
  {
    file: ".agents/skills/minecraft-modding/SKILL.md",
    required: [
      /Forge 1\.20\.1/,
      /Forge 1\.20\.1 project signature/,
      /references\/forge-1\.20\.1-api\.md/,
      /ForgeRegistries\.BLOCKS/,
      /FMLJavaModLoadingContext/,
      /Forge\*\* \| 1\.20\.1 legacy lane/,
      /Loot table JSON -> 1\.21\.x: `data\/<modid>\/loot_table\/blocks\/<name>\.json`; Forge 1\.20\.1: `data\/<modid>\/loot_tables\/blocks\/<name>\.json`/
    ]
  },
  {
    file: ".agents/skills/minecraft-modding/references/forge-1.20.1-api.md",
    required: [
      /minecraft_version=1\.20\.1/,
      /forge_version=47\.4\.20/,
      /java\.toolchain\.languageVersion = JavaLanguageVersion\.of\(17\)/,
      /src\/main\/resources\/META-INF\/mods\.toml/,
      /FMLJavaModLoadingContext context/,
      /MinecraftForge\.EVENT_BUS/,
      /ForgeRegistries\.BLOCKS/,
      /RegistryObject<Block>/,
      /NetworkRegistry\.newSimpleChannel/,
      /modEventBus\.addListener\(ModDataGen::gatherData\)/,
      /class ModBlockStateProvider extends BlockStateProvider/,
      /class ModRecipeProvider extends RecipeProvider/,
      /class ModItemTagsProvider extends ItemTagsProvider/,
      /data\/<modid>\/loot_tables\/blocks\/<block>\.json/
    ]
  },
  {
    file: ".agents/skills/minecraft-multiloader/SKILL.md",
    references: [".agents/skills/minecraft-multiloader/references/legacy-1.21.11-template.md"],
    required: [
      /mod_version=1\.0\.0/,
      /minecraft_version=1\.21\.11/,
      /architectury_version=<project pin>/,
      /fabric_loader_version=<project pin>/,
      /fabric_api_version=<project pin ending in \+1\.21\.11>/,
      /neoforge_version=<project pin in the 21\.11\.x family>/,
      /loom_version=<project pin>/,
      /"fabric-api": ">=0\.139\.4\+1\.21\.11"/,
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
    references: [".agents/skills/minecraft-ci-release/references/publishing-gradle.md"],
    required: [
      /1\.0\.0\+26\.2/,
      /gameVersions\.add\(minecraftVersion\)/,
      /mainFile\.addGameVersion\(minecraftVersion\)/,
      /providers\.gradleProperty\("minecraft_version"\)/,
      /minecraft_version=26\.2/,
      /java-version: "25"/
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
      /26\.2\s+\| `min_format: \[107, 1\]`, `max_format: \[107, 1\]`/,
      /"min_format": \[94, 1\]/,
      /"max_format": \[94, 1\]/,
      /"min_format": \[107, 1\]/,
      /"max_format": \[107, 1\]/
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
      /26\.2\s+\| `min_format: \[88, 0\]`, `max_format: \[88, 0\]`/,
      /"min_format": \[75, 0\]/,
      /"max_format": \[75, 0\]/,
      /"min_format": \[88, 0\]/,
      /"max_format": \[88, 0\]/
    ],
    forbidden: [
      /"min_format": 75\.0/,
      /"max_format": 75\.0/
    ]
  },
  {
    file: ".agents/skills/minecraft-modding/scripts/check-build.sh",
    required: [
      /PLATFORM="forge"/,
      /parse_java_major/,
      /MINECRAFT_VERSION" == "1\.20\.1"/,
      /REQUIRED_JAVA=17/,
      /Minecraft 26\.x requires Java 25/,
      /src\/main\/resources\/META-INF\/mods\.toml/
    ]
  },
  {
    file: ".agents/skills/minecraft-plugin-dev/SKILL.md",
    required: [
      /paper-api:26\.2\.build\.\+/,
      /JavaLanguageVersion\.of\(25\)/,
      /api-version: '26\.2'/
    ]
  },
  {
    file: ".agents/skills/minecraft-plugin-dev/scripts/validate-plugin-layout.sh",
    required: [
      /CURRENT_API_RELEASE=2/,
      /\^26\\\.\(\[1-9\]\[0-9\]\*\)\$/,
      /26\.x \/ 1\.21\.x skill scope/
    ]
  },
  {
    file: ".agents/skills/minecraft-testing/SKILL.md",
    required: [
      /mockbukkit-v26\.2:4\.116\.1/,
      /data\/<namespace>\/structure\/<path>\.nbt/,
      /25 for 26\.x, 21 for 1\.21\.x/
    ],
    forbidden: [
      /data\/mymod\/structures\/empty\.nbt/
    ]
  },
  {
    file: ".agents/skills/minecraft-testing/scripts/validate-test-layout.sh",
    required: [
      /data\/\$namespace\/structure\/\$path\.nbt/
    ],
    forbidden: [
      /data\/\$namespace\/structures\/\$path\.nbt/,
      /data\/\*\/structures\/\*\.nbt/
    ]
  },
  {
    file: ".agents/skills/minecraft-server-admin/SKILL.md",
    required: [
      /minecraft-server:java25/,
      /VERSION: "26\.2"/,
      /java -Xms4G -Xmx4G -jar server\.jar --nogui/
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
      /multiloader valid/,
      /multiloader valid 26\.2/
    ]
  }
];

let failures = 0;

for (const check of checks) {
  const target = path.join(repoRoot, check.file);
  const text = [target, ...(check.references ?? []).map((file) => path.join(repoRoot, file))]
    .map((file) => fs.readFileSync(file, "utf8"))
    .join("\n");

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
