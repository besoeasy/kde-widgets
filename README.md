# KDE Plasma 6 Widgets

[![Star History Rank](https://api.star-history.com/badge?repo=besoeasy/kde-widgets&type=rank)](https://www.star-history.com/besoeasy/kde-widgets)

Themed [KDE Plasma 6](https://kde.org/plasma-desktop/) widgets (plasmoids) for
the Linux desktop, built with Qt 6, QML and Kirigami.

Inspired by [Omarchy](https://omarchy.org/): opinionated defaults, one
cohesive look, beautiful out of the box — that take on a desktop, applied to
Plasma widgets.

## Install

One-liner — installs every widget from the latest release, upgrades the
ones you already have:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/besoeasy/kde-widgets/main/install.sh)"
```

Or install bleeding-edge from source, or only a subset:

```bash
./install.sh --from-source                   # build from main instead of release
./install.sh --no-restart material-digital-clock live-weather-report  # subset
```

Prefer bundles by hand? Grab them from [Releases](../../releases).

## Widgets

| Widget | Description | Download |
| --- | --- | --- |
| [crypto-price-tracker](crypto-price-tracker/) | Crypto price tracker (Bitcoin, Ethereum, Solana via CoinGecko), refreshes every 15 minutes. | [crypto-price-tracker.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/crypto-price-tracker.plasmoid) |
| [material-digital-clock](material-digital-clock/) | Digital clock with date, 12/24-hour and seconds options, ticks every second. | [material-digital-clock.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/material-digital-clock.plasmoid) |
| [live-weather-report](live-weather-report/) | Current temperature and conditions via Open-Meteo (no API key), refreshes every 30 minutes. | [live-weather-report.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/live-weather-report.plasmoid) |
| [pomodoro-focus-timer](pomodoro-focus-timer/) | Pomodoro focus timer with configurable focus/break intervals and a panel countdown. | [pomodoro-focus-timer.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/pomodoro-focus-timer.plasmoid) |
| [github-trending-repos](github-trending-repos/) | Trending GitHub repos of the week, with language filter, refreshes every 60 minutes. | [github-trending-repos.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/github-trending-repos.plasmoid) |
| [public-ip-info](public-ip-info/) | Public IP address, city and country, refreshes every 60 minutes. | [public-ip-info.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/public-ip-info.plasmoid) |
| [air-quality-index](air-quality-index/) | Current US AQI and pollutant levels via Open-Meteo (no API key), refreshes every 30 minutes. | [air-quality-index.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/air-quality-index.plasmoid) |
| [moon-phase-tracker](moon-phase-tracker/) | Current lunar phase, illumination and days to next full/new moon, computed locally. | [moon-phase-tracker.plasmoid](https://github.com/besoeasy/kde-widgets/releases/latest/download/moon-phase-tracker.plasmoid) |

## Vibe coders welcome

Humans and AI coding agents alike — contributions are welcome. Start with
[`agents.md`](agents.md): one installable `package/` per widget, each widget
with its own styling, `PlasmoidItem` root, config in `main.xml`.
Copy `material-digital-clock/`, give it a `com.besoeasy.<name>` id, and build.

## Star History

[![Star History Chart](https://api.star-history.com/chart?repos=besoeasy/kde-widgets&type=date&legend=top-left)](https://www.star-history.com/?repos=besoeasy%2Fkde-widgets&type=date&legend=top-left)

## Licence

GPL-3.0-or-later.
