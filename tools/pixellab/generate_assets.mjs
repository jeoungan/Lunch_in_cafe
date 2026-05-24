#!/usr/bin/env node

import { Buffer } from 'node:buffer';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const DEFAULT_ENDPOINT = 'https://api.pixellab.ai/v1/generate-image-pixflux';
const DEFAULT_CONFIG_PATH = 'tools/pixellab/assets.sample.json';
const DEFAULT_OUTPUT_DIR = 'assets/generated';
const OPTIONAL_PIXFLUX_FIELDS = [
  'negative_description',
  'view',
  'outline',
  'shading',
  'isometric',
  'no_background',
  'detail',
  'direction',
  'seed',
  'text',
  'obfuscate',
];
const PIXFLUX_ENUMS = {
  outline: [
    'single color black outline',
    'single color outline',
    'selective outline',
    'lineless',
  ],
  shading: [
    'flat shading',
    'basic shading',
    'medium shading',
    'detailed shading',
    'highly detailed shading',
  ],
  detail: [
    'low detail',
    'medium detail',
    'highly detailed',
  ],
};

export function parseEnvText(text) {
  const values = {};

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const withoutExport = line.startsWith('export ') ? line.slice('export '.length).trim() : line;
    const separatorIndex = withoutExport.indexOf('=');
    if (separatorIndex === -1) {
      continue;
    }

    const key = withoutExport.slice(0, separatorIndex).trim();
    let value = withoutExport.slice(separatorIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }

  return {
    values,
    apiKey: values.PIXELLAB_API_KEY || values.PIXALLAB_API_KEY || '',
  };
}

export function validateAssetSpec(spec) {
  if (!spec || typeof spec !== 'object' || Array.isArray(spec)) {
    throw new Error('Asset spec must be an object.');
  }
  if (!isNonEmptyString(spec.id)) {
    throw new Error('Asset spec must include a non-empty id.');
  }
  if (!isNonEmptyString(spec.description)) {
    throw new Error(`Asset "${spec.id}" must include a non-empty description.`);
  }

  assertSize('width', spec.width, spec.id);
  assertSize('height', spec.height, spec.id);
  for (const [field, allowedValues] of Object.entries(PIXFLUX_ENUMS)) {
    if (spec[field] !== undefined && !allowedValues.includes(spec[field])) {
      throw new Error(
        `Asset "${spec.id}" ${field} must be a PixelLab value: ${allowedValues.join(', ')}.`
      );
    }
  }

  return spec;
}

export function buildPixfluxPayload(spec) {
  validateAssetSpec(spec);

  const payload = {
    description: spec.description,
    image_size: {
      width: spec.width,
      height: spec.height,
    },
  };

  for (const field of OPTIONAL_PIXFLUX_FIELDS) {
    if (spec[field] !== undefined) {
      payload[field] = spec[field];
    }
  }

  return payload;
}

export function resolveAssetOutputPath(outputDir, requestedOutput) {
  if (!isNonEmptyString(requestedOutput)) {
    throw new Error('Asset output path must be a non-empty string.');
  }

  const root = path.resolve(outputDir);
  const target = path.resolve(root, requestedOutput);
  const relative = path.relative(root, target);

  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error(`Asset output must stay inside the output directory: ${requestedOutput}`);
  }

  return target;
}

export function extractImageReference(value) {
  if (!value) {
    return null;
  }

  if (typeof value === 'string') {
    return stringToImageReference(value);
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const found = extractImageReference(item);
      if (found) {
        return found;
      }
    }
    return null;
  }

  if (typeof value === 'object') {
    if (value.type === 'base64' && typeof value.base64 === 'string') {
      return stringToImageReference(value.base64);
    }

    for (const key of ['image', 'image_url', 'url', 'data', 'output', 'result', 'images']) {
      if (value[key] !== undefined) {
        const found = extractImageReference(value[key]);
        if (found) {
          return found;
        }
      }
    }
  }

  return null;
}

export async function runCli(argv = process.argv.slice(2), options = {}) {
  const cwd = options.cwd || process.cwd();
  const parsed = parseArgs(argv);
  const fetchImpl = options.fetchImpl || globalThis.fetch;
  const endpoint = parsed.endpoint || DEFAULT_ENDPOINT;
  const configPath = path.resolve(cwd, parsed.config || DEFAULT_CONFIG_PATH);
  const config = await readJson(configPath);
  const outputDir = path.resolve(cwd, parsed.outputDir || config.output_dir || DEFAULT_OUTPUT_DIR);
  const assets = normalizeAssetSpecs(config, parsed.only);

  if (parsed.dryRun) {
    for (const asset of assets) {
      const payload = buildPixfluxPayload(asset);
      const targetPath = resolveAssetOutputPath(outputDir, asset.output || `${asset.id}.png`);
      console.log(`[dry-run] ${asset.id}`);
      console.log(`  -> ${path.relative(cwd, targetPath)}`);
      console.log(`  ${JSON.stringify(payload)}`);
    }
    return { generated: 0, planned: assets.length };
  }

  const { apiKey } = await loadLocalEnv(cwd);
  if (!apiKey) {
    throw new Error('Missing PIXELLAB_API_KEY in .env.local. PIXALLAB_API_KEY is also accepted.');
  }

  let generated = 0;
  for (const asset of assets) {
    const payload = buildPixfluxPayload(asset);
    const outputPath = resolveAssetOutputPath(outputDir, asset.output || `${asset.id}.png`);
    const image = await requestPixfluxImage(fetchImpl, endpoint, apiKey, payload);

    await mkdir(path.dirname(outputPath), { recursive: true });
    await writeFile(outputPath, image.bytes);
    generated += 1;
    console.log(`[generated] ${asset.id} -> ${path.relative(cwd, outputPath)}`);
  }

  return { generated, planned: assets.length };
}

async function loadLocalEnv(cwd) {
  const chunks = [];
  for (const filename of ['.env', '.env.local']) {
    const candidate = path.resolve(cwd, filename);
    if (existsSync(candidate)) {
      chunks.push(await readFile(candidate, 'utf8'));
    }
  }

  const parsed = parseEnvText(chunks.join('\n'));
  const apiKey =
    process.env.PIXELLAB_API_KEY ||
    process.env.PIXALLAB_API_KEY ||
    parsed.values.PIXELLAB_API_KEY ||
    parsed.values.PIXALLAB_API_KEY ||
    '';

  return {
    values: parsed.values,
    apiKey,
  };
}

function parseArgs(argv) {
  const result = {
    config: DEFAULT_CONFIG_PATH,
    dryRun: false,
    endpoint: DEFAULT_ENDPOINT,
    only: [],
    outputDir: '',
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--dry-run') {
      result.dryRun = true;
    } else if (arg === '--config') {
      result.config = requireValue(argv, index, arg);
      index += 1;
    } else if (arg === '--endpoint') {
      result.endpoint = requireValue(argv, index, arg);
      index += 1;
    } else if (arg === '--only') {
      result.only.push(...requireValue(argv, index, arg).split(',').map((item) => item.trim()));
      index += 1;
    } else if (arg === '--output-dir') {
      result.outputDir = requireValue(argv, index, arg);
      index += 1;
    } else if (arg === '--help' || arg === '-h') {
      printHelp();
      result.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  result.only = result.only.filter(Boolean);
  return result;
}

function requireValue(argv, index, arg) {
  const value = argv[index + 1];
  if (!value || value.startsWith('--')) {
    throw new Error(`${arg} requires a value.`);
  }
  return value;
}

async function readJson(filename) {
  const text = await readFile(filename, 'utf8');
  return JSON.parse(text);
}

function normalizeAssetSpecs(config, onlyIds) {
  if (!config || typeof config !== 'object' || Array.isArray(config)) {
    throw new Error('Config must be a JSON object.');
  }
  if (!Array.isArray(config.assets)) {
    throw new Error('Config must include an assets array.');
  }

  const defaults = config.defaults || {};
  const onlySet = new Set(onlyIds || []);
  const assets = config.assets
    .map((asset) => ({ ...defaults, ...asset }))
    .filter((asset) => onlySet.size === 0 || onlySet.has(asset.id));

  if (assets.length === 0) {
    throw new Error('No assets matched the requested filter.');
  }

  for (const asset of assets) {
    validateAssetSpec(asset);
  }

  return assets;
}

async function requestPixfluxImage(fetchImpl, endpoint, apiKey, payload) {
  const response = await fetchImpl(endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorText = await safeReadText(response);
    throw new Error(`PixelLab request failed (${response.status}): ${errorText}`);
  }

  const contentType = response.headers.get('content-type') || '';
  if (contentType.startsWith('image/')) {
    return {
      bytes: Buffer.from(await response.arrayBuffer()),
      mimeType: contentType.split(';')[0],
    };
  }

  const body = await response.json();
  const reference = extractImageReference(body);
  if (!reference) {
    throw new Error('PixelLab response did not include an image, URL, or data URL.');
  }

  if (reference.kind === 'bytes') {
    return reference;
  }

  const imageResponse = await fetchImpl(reference.url);
  if (!imageResponse.ok) {
    throw new Error(`PixelLab image download failed (${imageResponse.status}).`);
  }

  return {
    bytes: Buffer.from(await imageResponse.arrayBuffer()),
    mimeType: (imageResponse.headers.get('content-type') || 'image/png').split(';')[0],
  };
}

async function safeReadText(response) {
  try {
    return await response.text();
  } catch {
    return 'No error body returned.';
  }
}

function stringToImageReference(value) {
  const trimmed = value.trim();
  const dataUrlMatch = trimmed.match(/^data:([^;]+);base64,(.+)$/i);
  if (dataUrlMatch) {
    return {
      kind: 'bytes',
      mimeType: dataUrlMatch[1],
      bytes: Buffer.from(dataUrlMatch[2], 'base64'),
    };
  }

  if (/^https?:\/\//i.test(trimmed)) {
    return {
      kind: 'url',
      url: trimmed,
    };
  }

  if (/^[A-Za-z0-9+/=]+$/.test(trimmed) && trimmed.length > 64) {
    return {
      kind: 'bytes',
      mimeType: 'image/png',
      bytes: Buffer.from(trimmed, 'base64'),
    };
  }

  return null;
}

function assertSize(name, value, assetId) {
  if (!Number.isInteger(value) || value < 32 || value > 400) {
    throw new Error(`Asset "${assetId}" ${name} must be an integer between 32 and 400.`);
  }
}

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function printHelp() {
  console.log(`Usage:
  node tools/pixellab/generate_assets.mjs --dry-run
  node tools/pixellab/generate_assets.mjs --only iced_americano

Options:
  --config <file>      JSON asset manifest. Defaults to ${DEFAULT_CONFIG_PATH}
  --output-dir <dir>   Output directory. Defaults to ${DEFAULT_OUTPUT_DIR}
  --only <ids>         Comma-separated asset ids to generate.
  --dry-run            Print payloads without using the API key or network.
`);
}

const modulePath = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === modulePath) {
  runCli().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
