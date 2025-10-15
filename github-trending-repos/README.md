# github-trending-repos

KDE Plasma 6 widget that showcases trending GitHub repositories and refreshes
automatically **every 60 minutes** (configurable).

- Id: `com.besoeasy.githubtrendingrepos`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Source: official GitHub search API — top starred repos created in the last
  7 days (no API key), via `XMLHttpRequest`
- Defaults: all languages, 5 repos, refresh every 60 minutes

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `language` | _(empty)_ | Language filter, e.g. `python`, `rust`, `qml` (empty for all) |
| `count` | `5` | Number of repositories to show |
| `refreshMinutes` | `60` | Poll interval in minutes |

The `Timer` interval is `refreshMinutes * 60 * 1000`, so the default is
`60 * 60 * 1000 = 3600000` ms.

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a github-trending-repos/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install github-trending-repos/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
