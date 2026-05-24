# PixalLab API Key

Do not paste the real API key into Godot scripts, scenes, commits, or chat logs.

For local development, put the key in this ignored file:

```text
C:\Users\jeoun\OneDrive\바탕 화면\Lunch time in Cafe\.worktrees\first-playable\.env.local
```

Use this format:

```text
PIXALLAB_API_KEY=your-real-api-key-here
```

`.env.local` is ignored by git. Commit `.env.example` only.

For a shipped game, do not call the image API directly from the game client. Use a small backend/proxy so the key is never bundled into the exported game.
