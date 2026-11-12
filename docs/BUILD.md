# Building SongPowder on Windows

## Requirements
| Tool | Version |
|---|---|
| Windows | 10 or 11 (x64) |
| Visual Studio | 2022, workload "Desktop development with C++" |
| Qt | 6.5+ (tested target 6.8 LTS), kit `MSVC 2022 64-bit`, modules: Qt Multimedia, Qt Quick Controls, Qt Quick Dialogs, Qt Shader Tools |
| CMake | 3.21+ |
| Ninja | any recent |
| Inno Setup 6 | optional, for the installer |

## Steps
```
cmake --preset msvc-release -DCMAKE_PREFIX_PATH=C:/Qt/6.8.1/msvc2022_64
cmake --build build/release
ctest --test-dir build/release --output-on-failure
```
Qt Creator also works: open `CMakeLists.txt`, pick the MSVC kit, Run.

If your Qt path differs, edit `CMAKE_PREFIX_PATH` in `CMakePresets.json` or pass it on the command line.

## Release package and installer
One command, from any PowerShell or cmd window in the project folder (it loads the Visual Studio environment itself):
```
scripts\package.bat
scripts\package.bat -QtDir C:\Qt\6.8.1\msvc2022_64 -InnoDir "D:\Programming\Inno Setup"
```
It builds Release in `build\package`, runs `windeployqt --qmldir qml`, checks that the folder is self-contained and creates:
```
dist\SongPowder\                    portable folder
dist\SongPowder-Portable-<ver>.zip   the same folder zipped
dist\SongPowder-Setup-<ver>.exe      installer
```
Options: `-RunTests`, `-SmokeTest`, `-SkipInstaller`, `-SkipPortableZip`, `-Clean`. The Qt kit is auto-detected when `-QtDir` is omitted.

## Licensing notes
- Qt (LGPLv3) must be linked dynamically (windeployqt does this) and its license text shipped with releases.
- The Qt FFmpeg backend bundles FFmpeg (LGPL build). Keep the shared DLLs; do not statically link.
- SongPowder itself is MIT.

## Data locations
`%LOCALAPPDATA%\SongPowder\` : `library.db` (SQLite), `settings.ini`, `covers\` (artwork cache), `logs\songpowder.log`.