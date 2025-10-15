#!/usr/bin/env bash
# install.sh — install every widget, or upgrade the ones you have.
#
# One-liner (fresh machine, needs curl + Plasma 6):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/besoeasy/kde-widgets/main/install.sh)"
#
# Default: installs .plasmoid bundles from the latest GitHub release
# (stable, versioned). Pass --from-source to build from main instead.
#
# From a local checkout:
#   ./install.sh [--no-restart] [--from-source] [widget...]
#
# Behaviour: for every widget, run `kpackagetool6 --upgrade`, falling back
# to `--install` for new widgets. Restarts plasma-plasmashell at the end
# unless --no-restart is given.
#
# Exit 0 when every widget installed/upgraded, 1 otherwise.

set -euo pipefail

OWNER="besoeasy"
REPO="kde-widgets"
THIS="${BASH_SOURCE[0]:-$0}"
RESTART=1
SOURCE="release"
WIDGETS=()
FAILED=0

for arg in "$@"; do
    case "$arg" in
        --no-restart) RESTART=0 ;;
        --from-source) SOURCE="source" ;;
        -h|--help)
            sed -n '2,/^#$/p' "$THIS" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        -*) echo "unknown arg: $arg (try --help)" >&2; exit 2 ;;
        *) WIDGETS+=("$arg") ;;
    esac
done

command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not found (needs Plasma 6)" >&2; exit 1; }

install_pkg() { # $1 = package path (.plasmoid file or package dir), $2 = label
    if kpackagetool6 --type Plasma/Applet --upgrade "$1" >/dev/null 2>&1; then
        echo "upgraded: $2"
    elif kpackagetool6 --type Plasma/Applet --install "$1" >/dev/null 2>&1; then
        echo "installed: $2"
    else
        echo "FAILED: $2" >&2
        return 1
    fi
}

wanted() { # $1 = widget base name (no .plasmoid suffix); 0 when selected
    if [[ "${#WIDGETS[@]}" == 0 ]]; then
        return 0
    fi
    local w
    for w in "${WIDGETS[@]}"; do
        if [[ "${w%.plasmoid}" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

install_release() {
    command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
    command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/kde-widgets.XXXXXX")"
    trap "rm -rf '$work'" EXIT

    local assets
    assets="$(python3 - "$OWNER" "$REPO" <<'EOF'
import json, sys, urllib.request
owner, repo = sys.argv[1], sys.argv[2]
url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})
try:
    rel = json.load(urllib.request.urlopen(req))
except Exception as e:
    print(f"could not query latest release: {e}", file=sys.stderr)
    sys.exit(1)
print("tag: " + rel.get("tag_name", "?"), file=sys.stderr)
for a in rel.get("assets", []):
    name = a.get("name", "")
    if name.endswith(".plasmoid") and a.get("browser_download_url"):
        print(name + " " + a["browser_download_url"])
EOF
)"
    if [[ -z "$assets" ]]; then
        echo "no .plasmoid assets in the latest release" >&2
        exit 1
    fi

    local entry name dlurl base
    while IFS= read -r entry; do
        name="${entry%% *}"
        dlurl="${entry#* }"
        base="${name%.plasmoid}"
        if ! wanted "$base"; then
            continue
        fi
        curl -fsSL -o "$work/$name" "$dlurl"
        install_pkg "$work/$name" "$base" || FAILED=1
    done <<< "$assets"
}

install_source() {
    # No packages here (e.g. running via the curl one-liner)? Clone main.
    if ! compgen -G "*/package/metadata.json" >/dev/null; then
        command -v git >/dev/null || { echo "git is required for --from-source" >&2; exit 1; }
        local src
        src="$(mktemp -d "${TMPDIR:-/tmp}/kde-widgets.XXXXXX")"
        trap "rm -rf '$src'" EXIT
        git clone --depth 1 "https://github.com/$OWNER/$REPO.git" "$src" >&2
        cd "$src"
    fi

    local widgets=()
    if [[ "${#WIDGETS[@]}" == 0 ]]; then
        mapfile -t widgets < <(for m in */package/metadata.json; do dirname "$(dirname "$m")"; done | sort)
    else
        widgets=("${WIDGETS[@]}")
    fi

    local w pkg
    for w in "${widgets[@]}"; do
        w="${w%.plasmoid}"
        pkg="$w/package"
        if [[ ! -f "$pkg/metadata.json" ]]; then
            echo "SKIP: $w (no package/)" >&2
            continue
        fi
        install_pkg "$pkg" "$w" || FAILED=1
    done
}

if [[ "$SOURCE" == "release" ]]; then
    install_release
else
    install_source
fi

if [[ "$RESTART" == 1 ]]; then
    systemctl --user restart plasma-plasmashell && echo "plasmashell restarted"
fi

exit "$FAILED"
