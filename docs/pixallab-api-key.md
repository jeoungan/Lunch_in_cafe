# PixelLab API Key

Do not paste the real API key into Godot scripts, scenes, commits, or chat logs.

For local development, keep the key in this ignored file at the project root:

```text
.env.local
```

Use the official spelling when possible:

```text
PIXELLAB_API_KEY=your-real-api-key-here
```

The older project alias also works:

```text
PIXALLAB_API_KEY=your-real-api-key-here
```

`.env.local` is ignored by git. Commit `.env.example` only, and keep `.env.example`
as placeholder text.

For a shipped game, do not call the image API directly from the game client. Use
a small backend/proxy, or generate the cafe assets during development and commit
only the exported image files.
