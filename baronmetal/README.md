# BARonMetal Apple Silicon Snapshot

This branch is a public snapshot of the local work that made Beyond All Reason playable on macOS Apple Silicon through a Mesa/Zink/KosmicKrisp-based OpenGL 4.3 path.

It is not an official release and it is not an upstream-ready pull request. Treat it as a research snapshot and patch archive.

## Public Branch

- Repository: `https://github.com/yeojuny/RecoilEngine-apple-silicon-`
- Branch: `macos-port-checkpoint-pre-gs-strip`
- Latest snapshot commit at publication time: `6d4ddb0321`

## Current Local Result

Observed locally on macOS Apple Silicon:

- BAR launches and is playable in local skirmish.
- Audio and music work.
- Windowed play works.
- Minimap rendering and minimap click navigation work.
- Main HUD, top bar, build menu, order menu, health bars, tooltips, and the `I` key unit stats popup are usable.
- Terrain, map edge, water, tree shadows, smoke, particles, and basic post-processing are good enough for actual play.
- Long skirmish play against hard AI was stable during gameplay.

## What Is In This Repository Branch

The RecoilEngine branch contains engine-side changes for:

- macOS Apple Silicon window/context/viewport behavior
- Retina mouse and minimap interaction
- hardware cursor handling
- font path fallback
- terrain/shadow/water/feature rendering fallbacks
- particle alpha and smoke/bubble artifact controls
- shutdown/teardown stability work

Build artifacts, local caches, backup files, and generated binaries were intentionally not committed.

## Companion BAR Content Patch

BAR also needed LuaUI/content-side changes. Those are not part of RecoilEngine upstream, so this branch carries them only as a companion patch:

- `baronmetal/BAR.sdd-local-luaui.patch`

That patch was generated from the local `/Users/yeojun/BAR.sdd` worktree and is intended as a snapshot, not as a clean upstream PR.

It includes local BAR-side work around:

- direct tooltip rendering fallback
- direct `I` key Unit Stats popup fallback
- UI panel restoration
- grid/order/build menu fixes
- health bar fallback
- metalspot visibility experiments
- bloom/SSAO/deferred widget experiments
- GL4 widget fallback and disabling experiments
- map edge and minimap/UI fixes

## Important Caveats

- This does not include a redistributable Mesa/KosmicKrisp runtime.
- This does not include BAR game data, maps, or user `.spring` data.
- Several BAR LuaUI changes are experimental and should be split before proposing upstream.
- Geometry shaders are still not available in the current KosmicKrisp/Zink path, so GS-dependent widgets need fallbacks or rewrites.
- The public branch is useful for research, reproduction, and discussion, not for one-click installation.

## Suggested Public Link

Share this branch first:

`https://github.com/yeojuny/RecoilEngine-apple-silicon-/tree/macos-port-checkpoint-pre-gs-strip`

