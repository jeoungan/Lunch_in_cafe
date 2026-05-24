import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import test from 'node:test';
import {
  buildPixfluxPayload,
  extractImageReference,
  parseEnvText,
  resolveAssetOutputPath,
  validateAssetSpec,
} from './generate_assets.mjs';

test('parseEnvText prefers the official PIXELLAB_API_KEY name', () => {
  const result = parseEnvText(`
PIXALLAB_API_KEY=legacy-key
PIXELLAB_API_KEY=official-key
`);

  assert.equal(result.apiKey, 'official-key');
});

test('parseEnvText accepts the legacy PIXALLAB_API_KEY alias', () => {
  const result = parseEnvText('PIXALLAB_API_KEY=legacy-key');

  assert.equal(result.apiKey, 'legacy-key');
});

test('buildPixfluxPayload maps an asset spec to the PixelLab request body', () => {
  const payload = buildPixfluxPayload({
    id: 'iced_americano',
    description: 'transparent cup iced americano with clear ice cubes',
    width: 192,
    height: 192,
    no_background: true,
    view: 'side',
    outline: true,
    shading: 'soft',
    detail: 'medium',
  });

  assert.deepEqual(payload, {
    description: 'transparent cup iced americano with clear ice cubes',
    image_size: {
      width: 192,
      height: 192,
    },
    no_background: true,
    view: 'side',
    outline: true,
    shading: 'soft',
    detail: 'medium',
  });
});

test('validateAssetSpec rejects sizes outside the PixelLab bounds', () => {
  assert.throws(
    () => validateAssetSpec({ id: 'too_large', description: 'x', width: 512, height: 192 }),
    /width.*32.*400/
  );
});

test('resolveAssetOutputPath keeps generated files inside the output directory', () => {
  assert.throws(
    () => resolveAssetOutputPath('/project/assets/generated', '../leak.png'),
    /inside the output directory/
  );
});

test('extractImageReference decodes data URL images from JSON responses', () => {
  const body = {
    image: `data:image/png;base64,${Buffer.from('png-bytes').toString('base64')}`,
  };

  const extracted = extractImageReference(body);

  assert.equal(extracted.kind, 'bytes');
  assert.equal(extracted.mimeType, 'image/png');
  assert.equal(Buffer.from(extracted.bytes).toString(), 'png-bytes');
});
