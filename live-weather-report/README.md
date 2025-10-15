# live-weather-report

KDE Plasma 6 weather widget that shows the current temperature and conditions
and refreshes automatically **every 30 minutes** (configurable).

- Id: `com.besoeasy.liveweatherreport`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Weather source: Open-Meteo `forecast` API (no API key), via `XMLHttpRequest`
- Defaults: Berlin (`52.52`, `13.41`) / `celsius`, refresh every 30 minutes

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `latitude` | `52.52` | Location latitude |
| `longitude` | `13.41` | Location longitude |
| `units` | `celsius` | `celsius` or `fahrenheit` |
| `refreshMinutes` | `30` | Poll interval in minutes |

The `Timer` interval is `refreshMinutes * 60 * 1000`, so the default is
`30 * 60 * 1000 = 1800000` ms.

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a live-weather-report/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install live-weather-report/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
