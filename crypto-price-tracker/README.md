# crypto-price-tracker

KDE Plasma 6 widget that shows a cryptocurrency price and refreshes
automatically **every 15 minutes** (configurable).

- Id: `com.besoeasy.cryptopricetracker`
- Entry point: `package/contents/ui/main.qml` (root: `PlasmoidItem`)
- Price source: CoinGecko `simple/price` (no API key), via `XMLHttpRequest`
- Defaults: `bitcoin` / `usd`, refresh every 15 minutes

## Configure

Settings live in `package/contents/config/main.xml` and are read via
`plasmoid.configuration.*`:

| Key | Default | Meaning |
| --- | --- | --- |
| `coinId` | `bitcoin` | CoinGecko coin id (`ethereum`, `solana`, …) |
| `vsCurrency` | `usd` | Fiat currency (`eur`, `gbp`, …) |
| `refreshMinutes` | `15` | Poll interval in minutes |

The `Timer` interval is `refreshMinutes * 60 * 1000`, so the default is
`15 * 60 * 1000 = 900000` ms.

## Try it

```bash
# Preview without installing (needs plasma-sdk):
plasmoidviewer -a crypto-price-tracker/package

# Install locally:
kpackagetool6 --type Plasma/Applet --install crypto-price-tracker/package
systemctl --user restart plasma-plasmashell
```

Style it freely — each widget owns its look; see the repository
[`agents.md`](../agents.md).
