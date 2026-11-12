# SongPowder architecture

## Decisions
- **Audio engine: Qt Multimedia (FFmpeg backend), not libmpv.** One dependency family, LGPL-friendly, no extra DLL packaging, same decoder for playback and tag reading. Trade-off: no DSP/EQ; if that is needed later, `PlayerController` is the only class to swap for libmpv/miniaudio.
- **Metadata: Qt `QMediaMetaData`** through a dedicated async extractor. A file the decoder rejects is flagged broken and hidden (content-based validation).
- **DB: SQLite via QtSql**, WAL mode, schema versioned with `PRAGMA user_version`.
- **UI: Qt Quick, "Basic" style**, fully custom controls. Glass effect = translucent panels over a blurred colour backdrop (`MultiEffect`); true behind-window acrylic is intentionally not used (not reliable across Win10/11 in Qt Quick).

## Layers (src/)
| Module | Responsibility |
|---|---|
| Core | `Track`/`FolderInfo` types, file logger (rotating) |
| Settings | `SettingsManager`: theme, volume, shuffle (INI) |
| Database | schema, scan reconciliation, recent plays |
| MediaLibrary | `LibraryManager` (folders, background scan via QtConcurrent, QFileSystemWatcher + debounce + periodic/on-open rescan), `MetadataExtractor`, `TrackModel` |
| AudioEngine | `PlayerController`: queue, shuffle bag, history, auto-next, error skipping |
| LyricsManager | LRC parser and position sync, UI-independent |
| qml/ | Theme singleton, components, pages |

## Schema (v1)
`folders(id, path UNIQUE, name, added_at)` ·
`tracks(id, folder_id FK CASCADE, path, title, artist, album, duration_ms, cover, size, mtime, state[0 pending,1 ready,2 broken], UNIQUE(folder_id,path))` ·
`recent(path PK, title, artist, album, duration_ms, cover, last_played, play_count)`

## Behaviours worth knowing
- An unreachable folder (unplugged drive) keeps its cached tracks; nothing is wiped.
- End of list: auto-next stops playback; manual Next at the end does nothing. Shuffle cycles endlessly without immediate repeats.
- Watcher covers up to ~200 sub-directories per library; periodic (5 min) and on-open rescans cover the rest.
- Alphabetical sort uses `QCollator` (locale aware, numeric mode).

## Known limits / risks
- Not yet compiled or run by the author on Windows: expect small build fixes on first compile.
- Format support depends on the Qt FFmpeg backend build (WMA/OPUS usually fine, verify on target PCs).
- Large libraries: tag reading is sequential (about 20-60 files/s typical), so first import of 10k+ files takes minutes in background.

## Customization (Settings > Customization)
- `CustomizationManager` (C++, `src/Customization`) is the single source of truth for every visual token (77 keys, each with type, range and default). It exposes `overrides` (only what the user changed), a draft/saved split (live preview, Apply, Cancel, Reset), named collections (themes, profiles, visualizer presets) and validated JSON import/export. State lives in `customization.json` (atomic writes, versioned, damaged files are set aside as `.bak`).
- `Theme.qml` consumes `overrides` (bound from `Main.qml`) and keeps the built-in look as every token's default; components never hardcode colours, radii, fonts or durations (`Theme.dur()`, `Theme.px()`, `Theme.ipx()`, `Theme.btnR()`).
- UI: `CustomizationPage` + `Cz*` sections/controls. Adding a setting = one row in the schema, one default literal in `Theme.qml`, one control in a section (`tst_customization` checks the schema rules).
- Not implemented (no subsystem behind them yet): Home/album grid, Vinyl and Waveform players, audio-quality badge, particle effects, dynamic album colours, duotone icons.
