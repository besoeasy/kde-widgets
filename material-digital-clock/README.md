# material-digital-clock

KDE Plasma 6 digital clock widget that shows the time and date and ticks
**every second**.

- Id: `com.besoeasy.materialdigitalclock`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Source: local system time, via a 1-second `Timer`

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `use24Hour` | `true` | 24-hour clock (`false` for 12-hour with AM/PM) |
| `showSeconds` | `true` | Show seconds |
| `showDate` | `true` | Show the long locale date |

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a material-digital-clock/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install material-digital-clock/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
