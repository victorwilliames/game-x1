# game-x1 — Agent operating rules

This repository is the source of truth for a small, original, playable Godot 3D MOBA prototype. Read `GDD.md`, `ART_DIRECTION.md`, and `PROGRESS.md` when relevant. Keep instructions concise and prefer evidence over claims.

## Principles
- Optimize for **a playable vertical slice**, not a generic MOBA framework.
- **Mandatory dev-only visual policy:** do NOT prioritize production graphics, realistic character models, professional art, decorated environments, texture work, complex shaders, polished particles, cosmetic animation, asset packs or Blender. Prioritize mechanics and tests.
- Use **debug/prototype visuals on purpose**: 3D stick figures or articulated skeletons (lines/bones + visible joint dots), simple primitive towers/minions, flat surfaces or grid flooring, debug collision shapes/range circles, and minimal developer HUD. This is not a pixel-art or 2D requirement: gameplay and movement remain fully 3D.
- Visual feedback must exist to verify functionality (attacks, projectiles, cooldowns, death, animation states), but a clear diagnostic shape/colour/label is sufficient. Do not spend time making it beautiful.
- Do not introduce an art-production phase until the project owner explicitly requests it. Keep game logic independent from the debug renderers.
- **No overengineering:** avoid speculative abstractions, unused services, premature ECS frameworks, generic plugin layers, and needless dependencies.
- Implement **one focused increment** at a time; keep changes reviewable and the project runnable.
- When a request is ambiguous, preserve the intended **player experience**, not just a literal checklist. Research close gameplay precedents when necessary.
- Reuse proven components. Extract a reusable workflow/skill only after a procedure works repeatedly.
- Do not use copyrighted game characters, artwork or proprietary assets from referenced MOBAs.

## Engine and workflow
- Godot 4 stable, **GDScript**, true 3D, tilted/isometric-style camera.
- Work **CLI-first**: create/edit text-based scenes and resources, import/run/test/export with the official Godot command-line tools. Do not require the project owner to manipulate the Godot editor.
- Use the Godot Compatibility renderer for the initial Web target; assess Android/Windows compatibility early.
- Prefer procedural original prototype meshes/materials and built-in Godot animation/VFX. Blender and external asset packs are optional later, not prerequisites.
- Keep **gameplay/state** separate from **visual mesh/animation/VFX** so prototype models can be replaced safely.
- Keep small reusable scenes for hero, tower, minion, projectile, and arena; instantiate procedurally where practical. Avoid giant all-in-one scripts.
- Plan for authoritative networking but **do not build full multiplayer before the single-player vs-bot slice is fun**. Simulation rules must be separable from camera, HUD and local input.
- Do not add an MCP, paid API, new game engine, or extensive infrastructure without a measurable need and approval.

## Validation
- After each increment run applicable Godot import/parse and smoke checks; keep explicit reproducible Windows commands/scripts.
- Headless success alone does **not** prove the rendering, animation, input or gameplay feels right. Verify a graphical build and Web export when possible.
- Check the actual game camera for hit feedback, targeting readability, animation timing, movement responsiveness, HUD and performance.
- Never report a build/test as passed unless it actually ran; record limitations and evidence.
- Avoid force-push, destructive rewrites, secrets in Git and overwriting concurrent work. Inspect current state and sync before edits.

## Session continuity / project memory
- **Always read `HANDOFF.md` before resuming a session**. It is the current work handoff and the first place to look for blockers, last checks and next steps. `PROGRESS.md` tracks longer-term milestones; commits hold implementation history. Avoid duplicating full histories in multiple files.
- **Update `HANDOFF.md` at each meaningful milestone and before stopping, pausing, switching agent or ending a task**. It must state: branch/last commit, local uncommitted changes, exact files changed, implemented versus verified, tests and commands with outcome, pending issues, next command/action.
- Label states explicitly **verified**, **reported but unverified**, **pending**, or **blocked**. Never call a Web export visually tested merely because files were generated, and never call local-only code shared until it is pushed.
- Keep the handoff concise (ideally under ~100 lines); replace stale status rather than appending a never-ending transcript. No tokens, credentials, raw private logs or machine-specific secrets.
- Before pushing, fetch/sync remote changes without overwriting local edits. The GitHub `main` may receive documentation updates from the tech lead during local development.
- Do not let memory writing replace development: update concisely and continue the assigned task.

## Delivery format
Report: (1) what the player can do now, (2) files changed, (3) commands/tests actually run and results, (4) how to launch/play, (5) known bugs/next increment. Update `PROGRESS.md` only with verified facts.
