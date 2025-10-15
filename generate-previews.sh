#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 besoeasy
# SPDX-License-Identifier: GPL-3.0-or-later
#
# generate-previews.sh — render every widget to PNG previews with Podman.
#
# Each widget is shown by plasmoivviewer inside a Plasma 6 container on a
# virtual X display (Xvfb). plasmoivviewer renders the applet's full
# representation (the desktop card) in a popup window; that window is captured
# on its own, so a preview has no wallpaper, panel or viewer chrome in it —
# just the widget, at its natural size, in light and dark themes.
#
# Usage:
#   ./generate-previews.sh [options] [widget...]
#
# Options:
#   --themes "A B"   Plasma themes to render (default: "breeze-light breeze-dark")
#   --out DIR        output directory (default: out, gitignored)
#   --size WxH       host view size that hosts the applet (default: 480x320)
#   --settle SECS    wait after the card appears, for first data fetch (default: 6)
#   --rebuild        force a rebuild of the container image
#   -h, --help       show this help
#
# Env:
#   CONTAINER_ENGINE  podman (default) or docker
#   PREVIEW_IMAGE     image tag (default: kde-widgets-previews)
#   TMPDIR            build context (default: /tmp/opencodedev if writable)
#
# Exit 0 when every requested preview was written, 1 otherwise.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ENGINE="${CONTAINER_ENGINE:-podman}"
IMAGE="${PREVIEW_IMAGE:-kde-widgets-previews}"
THEMES="breeze-light breeze-dark"
OUTDIR="out"
SIZE="480x320"
SETTLE=6
REBUILD=0
SELECT=()

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --themes) THEMES="${2:?}"; shift 2 ;;
        --out)    OUTDIR="${2:?}"; shift 2 ;;
        --size)   SIZE="${2:?}"; shift 2 ;;
        --settle) SETTLE="${2:?}"; shift 2 ;;
        --rebuild) REBUILD=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
        *) SELECT+=("$1"); shift ;;
    esac
done

command -v "$ENGINE" >/dev/null 2>&1 || { echo "$ENGINE not found" >&2; exit 1; }

if [[ -n "${TMPDIR:-}" ]]; then
    BUILD="$TMPDIR/kde-widgets-previews"
elif [[ -d /tmp/opencodedev && -w /tmp/opencodedev ]]; then
    BUILD=/tmp/opencodedev/kde-widgets-previews
else
    BUILD=/tmp/kde-widgets-previews
fi
mkdir -p "$BUILD" "$OUTDIR"

# ---- container image -----------------------------------------------------
# Debian trixie ships Plasma 6 natively, so no third-party repositories are
# needed. plasmoivviewer's own shell is patched: its toolbar is hidden, and the
# applet is auto-expanded so its full representation (the card) opens in a
# popup window (type _KDE_NET_WM_WINDOW_TYPE_APPLET_POPUP) we can capture alone.
cat > "$BUILD/Containerfile" <<'CONTAINERFILE'
FROM docker.io/library/debian:stable
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      plasma-sdk plasma-desktop plasma-desktoptheme \
      qml6-module-org-kde-kirigami qml6-module-org-kde-ksvg \
      qml6-module-org-kde-kquickcontrolsaddons qml6-module-org-kde-kitemmodels \
      qml6-module-org-kde-newstuff qml6-module-org-kde-kquickcontrols \
      libkf6qqc2desktopstyle-data kf6-breeze-icon-theme kde-style-breeze \
      dbus-x11 xvfb xauth imagemagick x11-utils \
      fonts-dejavu-core fonts-noto-core libxcb-cursor0 \
 && rm -rf /var/lib/apt/lists/*
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Hide plasmoivviewer's own control toolbar.
RUN sed -i 's/^    SdkButtons {$/    SdkButtons {\n        visible: false/' \
      /usr/share/plasma/shells/org.kde.plasma.plasmoidviewershell/contents/views/Desktop.qml

# Auto-expand the applet after load so its fullRepresentation opens in the
# "popupWindow" for a clean shot.
RUN f=/usr/share/plasma/shells/org.kde.plasma.plasmoidviewershell/contents/applet/CompactApplet.qml \
 && head -n -1 "$f" > "$f.tmp" \
 && printf '%s\n' \
      '    // Auto-expand for preview capture (kde-widgets generate-previews.sh)' \
      '    Timer {' \
      '        interval: 250; repeat: true; running: true' \
      '        onTriggered: { if (root.plasmoidItem) { root.plasmoidItem.expanded = true; running = false; } }' \
      '    }' \
      '}' >> "$f.tmp" \
 && mv "$f.tmp" "$f"

WORKDIR /work
CONTAINERFILE

if [[ "$REBUILD" == 1 ]] || ! "$ENGINE" image exists "$IMAGE" >/dev/null 2>&1; then
    echo "-- building preview image ($IMAGE)"
    "$ENGINE" build --network host -t "$IMAGE" "$BUILD"
fi

# ---- in-container helper -------------------------------------------------
# capture.sh renders one widget in one theme and grabs the full-representation
# window (typed APPLET_POPUP) to its output path. It waits for that window to
# appear, so it does not depend on a fixed sleep.
cat > "$BUILD/capture.sh" <<'CAPTURE'
#!/usr/bin/env bash
set -uo pipefail
pkg="$1"; theme="$2"; size="$3"; out="$4"

plasmoidviewer -a "$pkg" -l floating -f planar -s "$size" -t "$theme" >/tmp/pv.log 2>&1 &
pv=$!

popup=""
for _ in $(seq 1 30); do
    popup=""
    while read -r id; do
        [[ -z "$id" ]] && continue
        type="$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null || true)"
        [[ "$type" == *APPLET_POPUP* ]] && popup="$id"
    done < <(xwininfo -root -tree 2>/dev/null \
                | grep -F '"plasmoidviewer" "plasmoidviewer"' | awk '{print $1}')
    [[ -n "$popup" ]] && break
    sleep 1
done
sleep "${SETTLE:-1}"
[[ -n "$popup" ]] && import -window "$popup" "$out" 2>/dev/null || true

kill -TERM "$pv" 2>/dev/null || true
pkill -TERM -f plasmoidviewer 2>/dev/null || true
CAPTURE

# ---- in-container driver -------------------------------------------------
cat > "$BUILD/render.sh" <<'RENDER'
#!/usr/bin/env bash
set -uo pipefail
export HOME=/tmp/pvhome XDG_RUNTIME_DIR=/tmp/xdg DISPLAY=:99
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"

Xvfb :99 -screen 0 "${PREVIEW_SCREEN:-1920x1200x24}" -nolisten tcp >/tmp/xvfb.log 2>&1 &
xvfb=$!; trap 'kill $xvfb $DBUS_SESSION_BUS_PID 2>/dev/null' EXIT
sleep 2

# One session bus for the whole run: a bus per widget would leave Plasma
# helper services holding the old bus open and stall shutdown.
eval "$(dbus-launch --sh-syntax)"

ok=0; fail=0
for widget in $WIDGETS; do
    for theme in $THEMES; do
        rm -f "$HOME/.config/plasmoidviewer-appletsrc"
        out="/out/$widget.$theme.png"
        timeout 90 bash /pipeline/capture.sh "/work/$widget/package" "$theme" "$SIZE" "$out"
        if [[ -s "$out" ]]; then
            ok=$((ok + 1))
        else
            fail=$((fail + 1)); echo "FAILED: $widget ($theme)" >&2
        fi
    done
done
echo "rendered $ok preview(s), $fail failed"
[[ "$fail" == 0 ]]
RENDER

# ---- select widgets ------------------------------------------------------
WIDGETS=""
if [[ ${#SELECT[@]} -gt 0 ]]; then
    WIDGETS="${SELECT[*]}"
else
    for meta in */package/metadata.json; do
        [[ -e "$meta" ]] && WIDGETS+="${meta%%/*} "
    done
fi
WIDGETS="${WIDGETS% }"
[[ -n "$WIDGETS" ]] || { echo "no widgets found" >&2; exit 1; }

echo "-- widgets: $WIDGETS"
echo "-- themes:  $THEMES"
echo "-- out:     $OUTDIR"

# Rootless Podman maps container root to the invoking user, so files written to
# /out come back owned by you; a rootful engine is run as your own uid instead.
RUNUSER=()
[[ "$ENGINE" != podman ]] && RUNUSER=(--user "$(id -u):$(id -g)")

"$ENGINE" run --rm --network host \
    "${RUNUSER[@]}" \
    -e HOME=/tmp/pvhome -e XDG_RUNTIME_DIR=/tmp/xdg \
    -e WIDGETS="$WIDGETS" -e THEMES="$THEMES" -e SIZE="$SIZE" -e SETTLE="$SETTLE" \
    -v "$ROOT:/work:ro,z" -v "$BUILD:/pipeline:ro,z" -v "$ROOT/$OUTDIR:/out:z" \
    "$IMAGE" bash /pipeline/render.sh

echo "-- previews in $OUTDIR:"
ls -1 "$OUTDIR" 2>/dev/null || true
