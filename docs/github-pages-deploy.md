# GitHub Pages Deploy

GitHub Pages is configured to publish from:

```text
branch: first-playable
folder: / (root)
```

That means the Godot Web export must be written to the project root as
`index.html`.

## Manual Export

1. Open this worktree in Godot:

```text
C:\Users\jeoun\OneDrive\바탕 화면\Lunch time in Cafe\.worktrees\first-playable
```

2. Open `Project > Export...`.
3. Select the `Web` preset.
4. Make sure `Thread Support` is off.
5. Export to:

```text
C:\Users\jeoun\OneDrive\바탕 화면\Lunch time in Cafe\.worktrees\first-playable\index.html
```

6. Commit and push the generated files.

Expected generated files include `index.html`, `index.js`, `index.wasm`, and
`index.pck`. GitHub Pages will serve those files from the repository root.

## Site URL

After GitHub Pages finishes building, the site should be available at:

```text
https://jeoungan.github.io/Lunch_in_cafe/
```
