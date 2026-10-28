# air-quality-index

KDE Plasma 6 air quality widget that shows the current US AQI and pollutant
levels (PM2.5, PM10, ozone, NO₂, SO₂, CO) via Open-Meteo. No API key
required. Refreshes every 30 minutes (configurable).

- Id: `com.besoeasy.airqualityindex`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Source: Open-Meteo air-quality API

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `latitude` | `52.52` | Location latitude |
| `longitude` | `13.41` | Location longitude |
| `refreshMinutes` | `30` | Refresh interval in minutes |

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a air-quality-index/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install air-quality-index/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).