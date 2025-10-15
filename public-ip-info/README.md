# public-ip-info

KDE Plasma 6 widget that shows your public IP address, city and country,
and refreshes automatically **every 60 minutes** (configurable).

- Id: `com.besoeasy.publicipinfo`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Source: ipinfo.io geolocation API (no API key), via `XMLHttpRequest`
- Defaults: refresh every 60 minutes

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `refreshMinutes` | `60` | Poll interval in minutes |

The `Timer` interval is `refreshMinutes * 60 * 1000`, so the default is
`60 * 60 * 1000 = 3600000` ms.

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a public-ip-info/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install public-ip-info/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
