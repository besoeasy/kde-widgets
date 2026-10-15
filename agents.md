# agents.md — working on `kde-widgets`

Guidance for humans and AI agents working in this repository. Read this first.

## What this project is

A collection of **KDE Plasma 6 widgets (plasmoids)** for the Linux desktop,
built with Qt 6, QML and Kirigami. Each widget owns its own look — they are
independent applets, not a matched set.

Two things matter in every change:

1. Each widget is a self-contained, installable Plasma applet package.
2. Each widget follows the basic theme principles below so it respects the
   user's desktop (light/dark mode, accent colour, font settings).

## Repository layout

```
kde-widgets/
├── agents.md              # this file
├── README.md              # project overview + quickstart
├── .gitignore
├── crypto-price-tracker/  # one widget per top-level directory
│   ├── README.md
│   └── package/           # <- this directory is what gets installed/shipped
│       ├── metadata.json
│       └── contents/
│           ├── ui/main.qml
│           └── config/main.xml
├── material-digital-clock/
│   └── package/...
├── live-weather-report/
│   └── package/...
└── pomodoro-focus-timer/
    └── package/...
```

`package/` is the installable root. Everything outside it (README, build files,
screenshots) stays out of the shipped package. This mirrors the layout used by the
[KDE Plasma widget tutorial](https://develop.kde.org/docs/plasma/widget/setup/).

## Basic theme principles

There is no shared theme — each widget styles itself. Follow these so every
widget respects the user's desktop:

1. **Follow the desktop.** Resolve colours, spacing and fonts from the user's
   active Plasma scheme through Kirigami (`Kirigami.Theme.*`,
   `Kirigami.Units.*`) instead of literals, so light/dark mode, the accent
   colour and font settings come for free:
   ```qml
   color: Kirigami.Theme.textColor
   spacing: Kirigami.Units.largeSpacing
   font.pointSize: Kirigami.Theme.defaultFont.pointSize
   ```
2. **No hardcoded colours.** Hex literals (e.g. `"#ff0000"`) break in dark
   mode — `check.sh` fails on them. Numeric sizes are fine where a widget
   genuinely needs its own look.
3. **Widgets are independent.** Nothing is shared between widget packages;
   give each widget its own layout, sizing and personality.

## Design: Google Material Design for every widget

All widgets follow [Google Material Design 3](https://m3.material.io/)
(Material You), adapted to Plasma: the user's Kirigami colour scheme plays
the role of Material's dynamic colour, and `Kirigami.Units` the role of dp.

1. **Responsive at any size.** Every widget provides both a
   `compactRepresentation` (panel strip) and a `fullRepresentation`
   (desktop card / popup). Build both from `RowLayout`/`ColumnLayout` with
   `Layout.fillWidth`/`fillHeight`, `elide` on single-line labels and
   `wrapMode` on multi-line ones. Size minimums only as
   `Kirigami.Units.gridUnit` multiples (DPI-aware) — never fixed pixels;
   `check.sh` fails on fixed-pixel sizes.
2. **Live and dynamic.** Drive the UI from properties and `Timer`s: every
   async fetch has loading, error and empty states, and
   `toolTipMainText`/`toolTipSubText` reflect the current data.
3. **Vector graphics only.** Icons via `Kirigami.Icon` system names or
   bundled `.svg` files — never commit raster images (`.png`/`.jpg`/…);
   `check.sh` fails on those.
4. **Material colour roles** — map roles to the desktop scheme, never hex
   (`check.sh` fails on hex literals):

   | Material role | Kirigami source |
   | --- | --- |
   | primary | `Kirigami.Theme.highlightColor` |
   | surface / surface-container | `Kirigami.Theme.backgroundColor` + `highlightColor` wash at 0.07 `opacity` |
   | on-surface | `Kirigami.Theme.textColor` |
   | on-surface-variant | `Kirigami.Theme.neutralTextColor` |
   | error | `Kirigami.Theme.negativeTextColor` |
   | tertiary (success/rest states) | `Kirigami.Theme.positiveTextColor` |

5. **Material type scale** — display (hero readout, ≈2.2× default, bold),
   title (headers, default size, bold), body (default size), label
   (metadata, `smallFont`, `neutralTextColor`).
6. **Material shape scale** — card corners ≈ 1.15× `gridUnit`, icon-badge
   corners ≈ 0.65× `gridUnit`, pills fully rounded (`radius` = `gridUnit`).
   Card tonal wash ≈ 0.11 `opacity` (Pixel-style, fully rounded).
   No shadows on the desktop; elevation is expressed through the tonal
   surface wash. Motion is a short fade (`NumberAnimation` with
   `Kirigami.Units.shortDuration`), e.g. list-row hover.
7. **Card recipe.** Full-representation content sits on one rounded
   `Rectangle`: header row (tonal icon badge + title/subtitle titles),
   hairline divider (`textColor` at 0.1 `opacity`, `devicePixelRatio`
   thick), hero readout, status pills, metadata, then full-width action
   button(s) below the card. `material-digital-clock/` is the reference
   implementation.

## Adding a new widget

1. Copy an existing widget directory (e.g. `material-digital-clock/`) to the new name.
   The directory name must have **minimum 3 words** in kebab-case:
   `word1-word2-word3` (e.g. `crypto-price-tracker/`).
2. Give it a unique reverse-DNS `KPlugin.Id` in `package/metadata.json`
   (e.g. `com.besoeasy.mywidget`). The installed folder name is the Id, so it must
   not collide with any other widget.
3. Update `Name`, `Description`, `Icon` and `Category` in `metadata.json`.
4. Keep `"KPackageStructure": "Plasma/Applet"` and
   `"X-Plasma-API-Minimum-Version": "6.0"` — both are required for Plasma 6.
5. Build the UI in `contents/ui/main.qml` following the theme principles above.

## Conventions

- **Entry point** is `contents/ui/main.qml`; its root must be a `PlasmoidItem`.
- **Follow the desktop**: resolve colours from `Kirigami.Theme.*` (no hex
  literals); each widget owns its own spacing and sizing.
- **Licence header** on every QML/JS file:
  ```
  // SPDX-FileCopyrightText: 2026 besoeasy
  // SPDX-License-Identifier: GPL-3.0-or-later
  ```
- **Name scheme**: directory is kebab-case with **minimum 3 words**,
  `word1-word2-word3` (e.g. `crypto-price-tracker/`).
- **Id scheme**: `com.besoeasy.<words-concatenated>` (directory hyphens
  stripped, e.g. `com.besoeasy.cryptopricetracker`).
- Keep configuration keys in `contents/config/main.xml` and load them via
  `plasmoid.configuration.*`.

## Build, test, package

```bash
# Static checks (tier 1, no Plasma needed — metadata, visual rules,
# qmlformat + qmllint via Podman when host Qt tools are missing):
./check.sh
./check.sh --with-qt-tools

# Preview a widget without installing it:
plasmoidviewer -a material-digital-clock/package

# Render PNG previews of every widget into out/ (headless Plasma 6 in a
# Podman container; light and dark, full representation; out/ is gitignored):
./previews.sh
./previews.sh --themes breeze-dark material-digital-clock

# Install / upgrade locally (Plasma 6):
kpackagetool6 --type Plasma/Applet --install material-digital-clock/package
kpackagetool6 --type Plasma/Applet --upgrade material-digital-clock/package

# Remove:
kpackagetool6 --type Plasma/Applet --remove com.besoeasy.materialdigitalclock

# Reload the shell after installing:
systemctl --user restart plasma-plasmashell

# Package one widget for distribution (contents of package/ at the zip root):
(cd material-digital-clock/package && zip -r ../../material-digital-clock.plasmoid .)
```

Requires `plasma-sdk` (for `plasmoidviewer`) and `kpackagetool6`.

CI runs both check commands on every push to `main` and every pull request
(`.github/workflows/ci.yml`), installing the Qt QML tools on the runner.

## Status

Six widgets are implemented (`crypto-price-tracker`,
`material-digital-clock`, `live-weather-report`, `pomodoro-focus-timer`,
`github-trending-repos`, `public-ip-info`), each with its own styling.
