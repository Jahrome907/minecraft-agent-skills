#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function usageAndExit() {
  process.stderr.write("usage: jq [flags] <filter> <file>\n");
  process.exit(2);
}

function isObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function present(value) {
  return value !== undefined && value !== null;
}

function walk(value, visit) {
  visit(value);
  if (Array.isArray(value)) {
    for (const entry of value) walk(entry, visit);
    return;
  }
  if (!isObject(value)) return;
  for (const entry of Object.values(value)) walk(entry, visit);
}

function collectRecursiveProperty(value, property) {
  const results = [];
  walk(value, (entry) => {
    if (isObject(entry) && present(entry[property])) results.push(entry[property]);
  });
  return results;
}

function collectBlockstateModels(input) {
  const results = [];
  if (isObject(input?.variants)) {
    results.push(...collectRecursiveProperty(input.variants, "model"));
  }

  if (!Array.isArray(input?.multipart)) return results;
  for (const part of input.multipart) {
    const apply = part?.apply;
    if (Array.isArray(apply)) {
      for (const entry of apply) {
        if (present(entry?.model)) results.push(entry.model);
      }
      continue;
    }
    if (isObject(apply) && present(apply.model)) {
      results.push(apply.model);
    }
  }
  return results;
}

function collectSounds(input) {
  const results = [];
  walk(input, (entry) => {
    if (!isObject(entry) || !Array.isArray(entry.sounds)) return;
    for (const sound of entry.sounds) {
      if (typeof sound === "string") {
        results.push(sound);
        continue;
      }
      if (isObject(sound) && present(sound.name)) {
        results.push(sound.name);
      }
    }
  });
  return results;
}

function collectSoundEntries(input) {
  const results = [];
  walk(input, (entry) => {
    if (!isObject(entry) || !Array.isArray(entry.sounds)) return;
    for (const sound of entry.sounds) {
      if (typeof sound === "string") {
        results.push(`file\t${sound}`);
        continue;
      }
      if (isObject(sound)) {
        results.push(`${sound.type ?? "file"}\t${sound.name ?? ""}`);
      }
    }
  });
  return results;
}

function collectItemDefinitionModels(input) {
  const results = [];
  walk(input, (entry) => {
    if (!isObject(entry)) return;
    if (entry.type === "minecraft:model" && typeof entry.model === "string") {
      results.push(entry.model);
    }
  });
  return results;
}

function flattenOptionalField(input, field) {
  const results = [];
  const value = input?.[field];
  if (present(value)) results.push(value);
  if (Array.isArray(value)) {
    for (const entry of value) {
      if (present(entry)) results.push(entry);
    }
  }
  return results;
}

function collectNestedFeatureRefs(input) {
  const results = [];
  if (!Array.isArray(input?.features)) return results;
  for (const group of input.features) {
    if (!Array.isArray(group)) continue;
    for (const entry of group) {
      if (present(entry)) results.push(entry);
    }
  }
  return results;
}

function normalizeFilter(filter) {
  return filter.replace(/\s+/g, "");
}

function isInteger(value) {
  return typeof value === "number" && Number.isInteger(value);
}

function isPackVersion(value) {
  return isInteger(value)
    || (Array.isArray(value) && (value.length === 1 || value.length === 2) && value.every(isInteger));
}

function packHasField(input, field) {
  return isObject(input?.pack) && Object.hasOwn(input.pack, field);
}

function packVersionParts(input, field, maxMinorForShortForm) {
  const value = input?.pack?.[field];
  if (typeof value === "number") return `${value}\t${maxMinorForShortForm ? 2147483647 : 0}`;
  if (Array.isArray(value) && value.length === 1) return `${value[0]}\t${maxMinorForShortForm ? 2147483647 : 0}`;
  if (Array.isArray(value) && value.length === 2) return `${value[0]}\t${value[1]}`;
  return null;
}

function isLegacySupportedFormats(value) {
  if (isInteger(value)) return true;
  if (Array.isArray(value)) {
    return value.length === 2 && value.every(isInteger);
  }
  return isObject(value)
    && isInteger(value.min_inclusive)
    && isInteger(value.max_inclusive);
}

function collectModelTextureEntries(input) {
  const results = [];
  if (!isObject(input?.textures)) return results;
  for (const [key, value] of Object.entries(input.textures)) {
    if (typeof value === "string") {
      results.push(`valid\t${key}\t${value}`);
      continue;
    }
    if (isObject(value)
      && typeof value.sprite === "string"
      && (!present(value.force_translucent) || typeof value.force_translucent === "boolean")) {
      results.push(`valid\t${key}\t${value.sprite}`);
      continue;
    }
    results.push(`invalid\t${key}\t`);
  }
  return results;
}

function collectCustomModelDataSelectCases(input) {
  const results = [];
  walk(input, (entry) => {
    if (!isObject(entry)
      || entry.type !== "minecraft:select"
      || entry.property !== "minecraft:custom_model_data") return;
    for (const entryCase of entry.cases ?? []) {
      const when = entryCase?.when;
      const valid = typeof when === "string"
        || (Array.isArray(when) && when.length > 0 && when.every((value) => typeof value === "string"));
      results.push(valid ? "valid" : "invalid");
    }
  });
  return results;
}

function evaluateFilter(input, filter) {
  switch (normalizeFilter(filter)) {
    case "empty":
      return [];
    case ".pack.pack_format|numbers":
      return typeof input?.pack?.pack_format === "number" ? [input.pack.pack_format] : [];
    case ".pack.pack_format|type==\"number\"and.==floor":
      return isInteger(input?.pack?.pack_format) ? [true] : [false];
    case ".pack.min_format|numbers":
      return typeof input?.pack?.min_format === "number" ? [input.pack.min_format] : [];
    case ".pack.min_format|((type==\"number\"and.==floor)or(type==\"array\"andlength==2andall(.[];type==\"number\"and.==floor)))":
      return [isPackVersion(input?.pack?.min_format)];
    case ".pack.min_format|((type==\"number\"and.==floor)or(type==\"array\"and(length==1orlength==2)andall(.[];type==\"number\"and.==floor)))":
      return [isPackVersion(input?.pack?.min_format)];
    case ".pack.max_format|numbers":
      return typeof input?.pack?.max_format === "number" ? [input.pack.max_format] : [];
    case ".pack.max_format|((type==\"number\"and.==floor)or(type==\"array\"andlength==2andall(.[];type==\"number\"and.==floor)))":
      return [isPackVersion(input?.pack?.max_format)];
    case ".pack.max_format|((type==\"number\"and.==floor)or(type==\"array\"and(length==1orlength==2)andall(.[];type==\"number\"and.==floor)))":
      return [isPackVersion(input?.pack?.max_format)];
    case ".pack|has(\"pack_format\")":
      return [packHasField(input, "pack_format")];
    case ".pack|has(\"min_format\")":
      return [packHasField(input, "min_format")];
    case ".pack|has(\"max_format\")":
      return [packHasField(input, "max_format")];
    case ".pack|has(\"supported_formats\")":
      return [packHasField(input, "supported_formats")];
    case ".pack.min_format|iftype==\"number\"then\"\\(.)\\t0\"eliftype==\"array\"andlength==1then\"\\(.[0])\\t0\"else\"\\(.[0])\\t\\(.[1])\"end": {
      const parts = packVersionParts(input, "min_format", false);
      return parts === null ? [] : [parts];
    }
    case ".pack.max_format|iftype==\"number\"then\"\\(.)\\t2147483647\"eliftype==\"array\"andlength==1then\"\\(.[0])\\t2147483647\"else\"\\(.[0])\\t\\(.[1])\"end": {
      const parts = packVersionParts(input, "max_format", true);
      return parts === null ? [] : [parts];
    }
    case ".pack.supported_formats|((type==\"number\"and.==floor)or(type==\"array\"andlength==2andall(.[];type==\"number\"and.==floor))or(type==\"object\"and(.min_inclusive|type==\"number\"and.==floor)and(.max_inclusive|type==\"number\"and.==floor)))":
      return [isLegacySupportedFormats(input?.pack?.supported_formats)];
    case ".values|type==\"array\"":
      return [Array.isArray(input?.values)];
    case ".values[]?|strings":
      return Array.isArray(input?.values) ? input.values.filter((value) => typeof value === "string") : [];
    case "(.textures//{}|to_entries[]?.value//empty)":
      return isObject(input?.textures) ? Object.values(input.textures).filter(present) : [];
    case "(.textures//{}|to_entries[]?|[(if(.value|type)==\"string\"then\"valid\"elif(.value|type)==\"object\"thenif((.value.sprite?|type)==\"string\"and((.value.force_translucent?|type)==\"null\"or(.value.force_translucent|type)==\"boolean\"))then\"valid\"else\"invalid\"endelse\"invalid\"end),.key,(if(.value|type)==\"string\"then.valueelif(.value|type)==\"object\"then(.value.sprite?//empty)elseemptyend)]|@tsv)":
      return collectModelTextureEntries(input);
    case ".parent?//empty":
      return present(input?.parent) ? [input.parent] : [];
    case ".overrides[]?.model?//empty":
      return Array.isArray(input?.overrides) ? input.overrides.map((entry) => entry?.model).filter(present) : [];
    case "(.variants?//{}|..|objects|.model?//empty),(.multipart[]?.apply?|iftype==\"array\"then.[]?.model?//emptyelse.model?//emptyend)":
      return collectBlockstateModels(input);
    case "..|objects|select(.type?==\"minecraft:model\"and(.model?|type)==\"string\")|.model":
      return collectItemDefinitionModels(input);
    case "..|objects|select(.type?==\"minecraft:select\"and.property?==\"minecraft:custom_model_data\")|.cases[]?|if((.when?|type)==\"string\")or((.when?|type)==\"array\"and(.when|length>0)andall(.when[]?;type==\"string\"))then\"valid\"else\"invalid\"end":
      return collectCustomModelDataSelectCases(input);
    case "..|objects|select(has(\"sounds\"))|.sounds[]?|iftype==\"string\"then.else.name?//emptyend":
      return collectSounds(input);
    case "..|objects|select(has(\"sounds\"))|.sounds[]?|iftype==\"string\"then[\"file\",.]else[(.type//\"file\"),(.name//empty)]end|@tsv":
      return collectSoundEntries(input);
    case ".providers[]?|.file?//empty":
      return Array.isArray(input?.providers) ? input.providers.map((entry) => entry?.file).filter(present) : [];
    case "keys[]":
      return isObject(input) ? Object.keys(input) : [];
    case ".type?//empty":
      return present(input?.type) ? [input.type] : [];
    case "if(.generator?.type?//empty)==\"minecraft:noise\"and(.generator?.settings?|type)==\"string\"then.generator.settingselseemptyend": {
      if (!isObject(input?.generator)) return [];
      return input.generator.type === "minecraft:noise" && typeof input.generator.settings === "string"
        ? [input.generator.settings]
        : [];
    }
    case ".feature?//empty":
      return present(input?.feature) ? [input.feature] : [];
    case ".structures[]?.structure?//empty":
      return Array.isArray(input?.structures) ? input.structures.map((entry) => entry?.structure).filter(present) : [];
    case ".features[][]?//empty":
      return collectNestedFeatureRefs(input);
    case "(.features?//empty),(.features[]?//empty)":
      return flattenOptionalField(input, "features");
    case "(.structures?//empty),(.structures[]?//empty)":
      return flattenOptionalField(input, "structures");
    default:
      throw new Error(`unsupported jq filter: ${filter}`);
  }
}

function formatOutput(value, rawOutput) {
  if (rawOutput && typeof value === "string") return value;
  if (typeof value === "string") return JSON.stringify(value);
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (value === null) return "null";
  return JSON.stringify(value);
}

const args = process.argv.slice(2);
if (args.length < 2) usageAndExit();

const flags = new Set();
let filter = null;
let file = null;

for (const arg of args) {
  if (filter === null && arg.startsWith("-")) {
    if (arg !== "-e" && arg !== "-r") usageAndExit();
    flags.add(arg);
    continue;
  }
  if (filter === null) {
    filter = arg;
    continue;
  }
  if (file === null) {
    file = arg;
    continue;
  }
  usageAndExit();
}

if (!filter || !file) usageAndExit();

const target = path.resolve(process.cwd(), file);
let jsonInput;
try {
  const raw = fs.readFileSync(target, "utf8");
  jsonInput = JSON.parse(raw);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(4);
}

try {
  const results = evaluateFilter(jsonInput, filter);
  const rawOutput = flags.has("-r");
  const evaluateExitCode = flags.has("-e");

  if (results.length > 0) {
    const stdout = `${results.map((value) => formatOutput(value, rawOutput)).join("\n")}\n`;
    process.stdout.write(stdout);
  }

  if (!evaluateExitCode) {
    process.exit(0);
  }

  if (results.length === 0) {
    process.exit(1);
  }

  const last = results[results.length - 1];
  process.exit(last === false || last === null ? 1 : 0);
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(3);
}
