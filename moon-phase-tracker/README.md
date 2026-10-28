# moon-phase-tracker

KDE Plasma 6 moon phase widget showing the current lunar phase, illumination
percentage, age since new moon and days to the next full/new moon. Computed
locally — no network, no API key.

- Id: `com.besoeasy.moonphasetracker`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Source: local system clock + lunar cycle calculation

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `refreshMinutes` | `5` | Recompute interval in minutes |

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a moon-phase-tracker/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install moon-phase-tracker/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).