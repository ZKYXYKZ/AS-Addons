# AS Companion

Source of the AS Companion Windows app. User documentation: [README.md](../README.md#as-companion) (English) · [README.fr.md](../README.fr.md#as-companion) (Français).

- `src/Companion.cs`: the app (C# 5, .NET Framework 4, compiled by the `csc.exe` shipped with Windows).
- `src/icon.ico`: the app icon.
- `web/`: the interface (HTML, CSS, vanilla JavaScript, generated `data.json`), embedded into the exe.

Build: `node tools/build-companion.js` from the repository root. `COMPANION_VERSION=1.2.3` sets the version, otherwise the release tag or `0.0.0`.
