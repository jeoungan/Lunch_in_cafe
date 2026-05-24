# PixelLab Asset Generator

This is a development-only helper for generating cafe drink and ingredient images.
It keeps the API key outside Godot and saves finished PNG assets into the project.

## Setup

1. Put the API key in `.env.local`:

```text
PIXELLAB_API_KEY=your-real-api-key-here
```

2. Check the planned prompts without calling the API:

```powershell
node tools\pixellab\generate_assets.mjs --dry-run
```

3. Generate one asset:

```powershell
node tools\pixellab\generate_assets.mjs --only iced_americano
```

4. Generate all sample assets:

```powershell
node tools\pixellab\generate_assets.mjs
```

Generated files are saved under `assets/generated` by default.

## Manifest

Edit `tools/pixellab/assets.sample.json` to add more drinks, ingredient stages,
or toppings. PixelLab Pixflux image sizes must stay between `32` and `400` pixels
for both width and height.
