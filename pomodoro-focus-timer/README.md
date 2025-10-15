# pomodoro-focus-timer

KDE Plasma 6 Pomodoro focus timer widget with a panel countdown that ticks
**every second** while running.

- Id: `com.besoeasy.pomodorofocustimer`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Logic: pure QML 1-second `Timer`; auto-switches between focus and break
- Defaults: 25 min focus / 5 min break

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `focusMinutes` | `25` | Focus interval in minutes |
| `breakMinutes` | `5` | Break interval in minutes |

Changing either interval resets the timer to the start of a focus session.

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a pomodoro-focus-timer/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install pomodoro-focus-timer/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
