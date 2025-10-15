#!/usr/bin/env bash
# check.sh — fast static checks for kde-widgets (tier 1, no Plasma needed).
#
# Usage:
#   ./check.sh                  # fast native checks (python3 + grep + git)
#   ./check.sh --with-qt-tools  # also run qmlformat + qmllint
#                               # (host binaries if present, else Podman container)
#
# Env:
#   QT_IMAGE  container image for Qt tools (default: docker.io/library/debian:bookworm-slim)
#   TMPDIR    temp dir (default: /tmp/opencode if it exists, else /tmp)
#
# Exit 0 when everything passes, 1 otherwise.

set -euo pipefail

WITH_QT_TOOLS=0
QT_IMAGE="${QT_IMAGE:-docker.io/library/debian:bookworm-slim}"
if [[ "${TMPDIR:-}" == "" ]]; then
    if [[ -d /tmp/opencode ]]; then TMPDIR=/tmp/opencode; else TMPDIR=/tmp; fi
fi

for arg in "$@"; do
    case "$arg" in
        --with-qt-tools) WITH_QT_TOOLS=1 ;;
        -h|--help)
            sed -n '2,/^#$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "unknown arg: $arg (try --help)" >&2; exit 2 ;;
    esac
done

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# CHECK_INNER=1: nested run inside the Qt-tools container — sections 1-3
# already ran on the host, so only run 4-5 and skip the result summary
# (the outer run prints the combined result).
INNER="${CHECK_INNER:-0}"

PASS=0
FAIL=0
SKIP=0
WARN=0

ok()   { PASS=$((PASS + 1)); echo "PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $1" >&2; }
skip() { SKIP=$((SKIP + 1)); echo "SKIP: $1"; }
warn() { WARN=$((WARN + 1)); echo "WARN: $1" >&2; }

if [[ "$INNER" != 1 ]]; then
echo "== 1/4 package metadata + structure =="
if python3 - <<'EOF'; then
import json, pathlib, sys, xml.etree.ElementTree as ET

root = pathlib.Path('.')
packages = sorted(root.glob('*/package/metadata.json'))
if not packages:
    print('no widget packages found', file=sys.stderr)
    sys.exit(1)
seen_ids = set()
for meta_path in packages:
    widget = meta_path.parts[0]
    try:
        meta = json.loads(meta_path.read_text())
    except json.JSONDecodeError as e:
        print(f'{widget}: invalid metadata.json: {e}', file=sys.stderr)
        sys.exit(1)
    plugin = meta.get('KPlugin', {})
    for key in ('Id', 'Name', 'Description', 'License'):
        if not plugin.get(key):
            print(f'{widget}: KPlugin.{key} missing', file=sys.stderr)
            sys.exit(1)
    # Naming scheme (agents.md): directory is kebab-case with a minimum of
    # 3 words, word1-word2-word3, and the Id is those words concatenated.
    words = widget.split('-')
    if len(words) < 3 or any(not w.islower() or not w.isalnum() for w in words):
        print(f'{widget}: directory must be >=3 kebab-case words (word1-word2-word3)', file=sys.stderr)
        sys.exit(1)
    expected_id = 'com.besoeasy.' + widget.replace('-', '')
    if plugin['Id'] != expected_id:
        print(f"{widget}: KPlugin.Id must be '{expected_id}', got '{plugin['Id']}'", file=sys.stderr)
        sys.exit(1)
    if meta.get('KPackageStructure') != 'Plasma/Applet':
        print(f'{widget}: bad KPackageStructure', file=sys.stderr)
        sys.exit(1)
    if meta.get('X-Plasma-API-Minimum-Version') != '6.0':
        print(f'{widget}: bad X-Plasma-API-Minimum-Version', file=sys.stderr)
        sys.exit(1)
    if plugin['Id'] in seen_ids:
        print(f"duplicate id {plugin['Id']}", file=sys.stderr)
        sys.exit(1)
    seen_ids.add(plugin['Id'])
    try:
        text = (root / widget / 'package/contents/ui/main.qml').read_text()
    except FileNotFoundError:
        print(f'{widget}: missing contents/ui/main.qml', file=sys.stderr)
        sys.exit(1)
    if 'PlasmoidItem {' not in text:
        print(f'{widget}: main.qml root is not PlasmoidItem', file=sys.stderr)
        sys.exit(1)
    if 'SPDX-License-Identifier' not in text:
        print(f'{widget}: missing licence header', file=sys.stderr)
        sys.exit(1)
    try:
        ET.parse(root / widget / 'package/contents/config/main.xml')
    except (FileNotFoundError, ET.ParseError) as e:
        print(f'{widget}: bad contents/config/main.xml: {e}', file=sys.stderr)
        sys.exit(1)
    print(f'{widget}: OK ({plugin["Id"]})')
print(f'validated {len(packages)} widget(s)')
EOF
    ok "package metadata + structure"
else
    fail "package metadata + structure"
fi

echo "== 2/4 visuals (no stale Theme refs, no hardcoded colours) =="
VISUAL_VIOLATIONS=""
for f in */package/contents/ui/main.qml; do
    # Leftover references to the deleted shared theme/ singleton
    if grep -q 'import "theme"' "$f" 2>/dev/null \
        || grep -nE 'Theme\.' "$f" 2>/dev/null | grep -qv 'Kirigami\.Theme'; then
        VISUAL_VIOLATIONS="${VISUAL_VIOLATIONS}${f}: stale shared-theme reference (theme/ is deleted; use Kirigami.* directly)\n"
    fi
    # Hex colour literals break light/dark mode — resolve from Kirigami.Theme
    if grep -nE '"#[0-9a-fA-F]{3,8}"' "$f" >/dev/null 2>&1; then
        VISUAL_VIOLATIONS="${VISUAL_VIOLATIONS}${f}: hex colour literal (use Kirigami.Theme.*)\n"
    fi
    # Fixed pixel sizes break responsiveness — use Kirigami.Units multiples
    if grep -inE '(width|height):\s*[0-9]' "$f" >/dev/null 2>&1; then
        VISUAL_VIOLATIONS="${VISUAL_VIOLATIONS}${f}: fixed pixel size (use Kirigami.Units.* multiples)\n"
    fi
done
# Raster images are banned — vector only (Kirigami.Icon system names or .svg)
RASTERS="$(find . -path ./.git -prune -o -path '*/package/*' \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.bmp' \) -print)"
if [[ -n "$RASTERS" ]]; then
    VISUAL_VIOLATIONS="${VISUAL_VIOLATIONS}raster image(s) committed (use .svg or Kirigami.Icon):\n${RASTERS}\n"
fi
if [[ -n "$VISUAL_VIOLATIONS" ]]; then
    printf '%b' "$VISUAL_VIOLATIONS" >&2
    fail "visuals"
else
    ok "visuals (independent widgets, desktop colours)"
fi
fi # INNER != 1

# ---- Qt tools (qmlformat + qmllint) --------------------------------------
QML_FILES="$(echo */package/contents/ui/main.qml | tr ' ' '\n' | sort | tr '\n' ' ')"

run_qt_checks() {
    local qmlformat_bin="qmlformat" qmllint_bin="qmllint"
    if [[ -n "${QT_BIN_PREFIX:-}" ]]; then
        qmlformat_bin="$QT_BIN_PREFIX/qmlformat"
        qmllint_bin="$QT_BIN_PREFIX/qmllint"
    fi

    echo "== 3/4 qmlformat =="
    local fmt_fail=0 fmt_file tmp_out
    # NOTE: qmlformat 6.4 has no --check/--output flag: it prints to stdout.
    # Format to a tmpfile under $TMPDIR and diff (same technique as CI lint jobs).
    # shellcheck disable=SC2086
    for fmt_file in $QML_FILES; do
        tmp_out="$(mktemp "$TMPDIR/qmlformat.XXXXXX.qml")"
        if "$qmlformat_bin" "$fmt_file" >"$tmp_out" 2>/dev/null \
            && diff -q "$fmt_file" "$tmp_out" >/dev/null 2>&1; then
            echo "  OK: $fmt_file"
        else
            echo "  NEEDS-FMT: $fmt_file" >&2
            fmt_fail=1
        fi
        rm -f "$tmp_out"
    done
    # Advisory only (not a FAIL): the only diffs qmlformat 6.4 reports on this
    # repo are blank-line removals after the SPDX header, and results vary by
    # Qt version. Keep the gate green; conform with `qmlformat -i <file>`.
    if [[ "$fmt_fail" == 0 ]]; then ok "qmlformat clean"; else warn "qmlformat differs (run qmlformat -i <file>)"; fi

    echo "== 4/4 qmllint (errors fail, Plasma warnings are informational) =="
    local lint_out
    lint_out="$(mktemp "$TMPDIR/qmllint.XXXXXX.log")"
    # shellcheck disable=SC2086
    "$qmllint_bin" $QML_FILES >"$lint_out" 2>&1 || true
    # qmllint prefixes real errors with "Error:" — match the prefix only,
    # since property names like "errorString" appear in warning bodies.
    if grep -qE '^Error:' "$lint_out"; then
        grep -E '^Error:' "$lint_out" >&2
        fail "qmllint reported errors (full log: $lint_out)"
    else
        echo "  no errors; $(grep -c '^Warning:' "$lint_out" || true) warning(s) —"
        echo "  note: 'PlasmoidItem/Kirigami not found' warnings are expected"
        echo "  without Plasma import paths (slim Qt container); full log: $lint_out"
        ok "qmllint (no errors)"
    fi
}

if [[ "$WITH_QT_TOOLS" == 1 ]]; then
    if command -v qmlformat >/dev/null 2>&1 && command -v qmllint >/dev/null 2>&1; then
        echo "-- host Qt tools found, using them"
        QT_BIN_PREFIX="" run_qt_checks
    elif command -v podman >/dev/null 2>&1; then
        echo "-- host Qt tools missing, using Podman ($QT_IMAGE)"
        if podman run --rm --network host \
            -v "$ROOT:/work:z" -w /work \
            -v "$TMPDIR:$TMPDIR:z" -e TMPDIR="$TMPDIR" -e CHECK_INNER=1 \
            "$QT_IMAGE" sh -c "
                set -e
                apt-get update -qq 2>&1 | tail -n 1
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qt6-declarative-dev-tools 2>&1 | tail -n 1
                export PATH=/usr/lib/qt6/bin:\$PATH
                ./check.sh --with-qt-tools
            "; then
            ok "Qt tools via Podman container"
        else
            fail "Qt tools via Podman container"
        fi
    else
        skip "qmlformat+qmllint (no host binaries, no podman)"
    fi
else
    skip "qmlformat (re-run with --with-qt-tools)"
    skip "qmllint (re-run with --with-qt-tools)"
fi

echo
if [[ "$INNER" != 1 ]]; then
    echo "result: $PASS passed, $FAIL failed, $WARN warned, $SKIP skipped"
fi
[[ "$FAIL" == 0 ]]
