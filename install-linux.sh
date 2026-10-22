#!/usr/bin/env bash
#
# pkmn-ricciolino — Linux installer
#
# Fetches the latest released build and installs it for the current user:
# the binary, the icon, a desktop entry, and an uninstaller. No sudo, nothing
# written outside $HOME, nothing touched that you did not ask for.
#
#   curl -fsSL https://raw.githubusercontent.com/ricciolino/pkmn-ricciolino-releases/main/install-linux.sh | bash
#
# or download it, read it, and run it — which is the better habit.
#
# Uninstall at any time with:  ~/.local/bin/pkmn-ricciolino-uninstall
#
# What it will NOT work on, stated up front rather than failing cryptically:
#   - anything that is not x86_64
#   - distributions without glibc (Alpine and other musl systems)
# The game itself is a single self-contained binary and needs no runtime.

set -euo pipefail

REPO="ricciolino/pkmn-ricciolino-releases"
BRANCH="main"
# Overridable so the script can be tested against a branch — or a local copy —
# before the files it fetches actually exist on main. Default is the real thing.
RAW="${PKMN_RAW:-https://raw.githubusercontent.com/$REPO/$BRANCH/linux}"

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
ICON_DIR="$DATA_DIR/icons/hicolor/256x256/apps"
APP_DIR="$DATA_DIR/applications"

APP="pkmn-ricciolino"
BIN="$BIN_DIR/$APP"
ICON="$ICON_DIR/$APP.png"
DESKTOP="$APP_DIR/$APP.desktop"
UNINSTALL="$BIN_DIR/$APP-uninstall"
# Saves live here and are NEVER touched, not on install and not on uninstall.
SAVES="$DATA_DIR/godot/app_userdata/$APP"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. can we even run here? -------------------------------------------------
arch="$(uname -m)"
[ "$arch" = "x86_64" ] || die "this build is x86_64 only, found: $arch"
command -v curl >/dev/null || die "curl is required"

# --- 2. ask the release API what the latest build is --------------------------
# Resolved every run, so this script does not need updating when a new version
# ships. The JSON is parsed with grep/sed on purpose: no jq, no python.
say "Looking up the latest release…"
api="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")" \
    || die "could not reach the GitHub API"

tag="$(printf '%s' "$api" | grep -m1 '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"

# One asset, delimited by its own fields: from the name to its download URL.
# NOT a fixed line window — inside an asset the digest sits some fifty fields
# after the name, with the uploader object in between, so "grep -A20" silently
# returns nothing and the checksum check quietly turns itself off.
blk="$(printf '%s' "$api" | tr ',' '\n' \
       | sed -n '/"name": *"[^"]*linux-x86_64"/,/browser_download_url/p')"
url="$(printf '%s' "$blk" | grep -m1 'browser_download_url' | sed 's/.*"\(https[^"]*\)".*/\1/')"
[ -n "$url" ] || die "no Linux asset in the latest release ($tag)"

# The API publishes the checksum next to the asset — so we can tell a truncated
# or tampered download from a good one instead of installing it blindly.
want="$(printf '%s' "$blk" | grep -m1 '"digest"' | sed 's/.*sha256:\([a-f0-9]*\)".*/\1/' || true)"

say "Found $tag"

# --- 3. download into a scratch dir, verify, then move ------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
say "Downloading… (about 105 MB)"
curl -fL# -o "$tmp/$APP" "$url" || die "download failed"

if [ -n "$want" ] && command -v sha256sum >/dev/null; then
    got="$(sha256sum "$tmp/$APP" | cut -d' ' -f1)"
    [ "$got" = "$want" ] || die "checksum mismatch — download is not what the release says it is"
    say "Checksum verified."
else
    warn "checksum not verified (no digest published, or sha256sum missing)"
fi

curl -fsSL -o "$tmp/icon.png"    "$RAW/$APP.png"     || die "could not fetch the icon"
curl -fsSL -o "$tmp/app.desktop" "$RAW/$APP.desktop" || die "could not fetch the desktop entry"

# --- 4. the uninstaller, written before anything is installed -----------------
# Built here rather than shipped, because it has to name the exact paths this
# run used — which depend on XDG variables that are not ours to guess twice.
#
# It has to report what it did, and the hard part is that it is usually started
# from a menu entry, where there is no terminal to print to. Three ways out, in
# order: re-open in a terminal, show a dialog, raise a notification. ⚠ In all
# three the removal HAPPENS — having no way to narrate it is not a reason to
# skip it.
cat > "$tmp/uninstall" <<EOF
#!/usr/bin/env bash
# Removes pkmn-ricciolino. Your saves are NOT touched.
set -u

SELF="$UNINSTALL"
SAVES="$SAVES"

# --- Way 1: started from the menu there is no tty, and this script writes and
# waits for ENTER. Argument shapes are not standardised: "-e" covers almost
# everything, gnome-terminal wants "--", wezterm wants "start --". The REEXEC
# guard stops a loop if the terminal we found still gives no tty.
if [ ! -t 0 ] && [ -z "\${PKMN_UNINSTALL_REEXEC:-}" ]; then
    export PKMN_UNINSTALL_REEXEC=1
    for T in "\${TERMINAL:-}" x-terminal-emulator alacritty kitty foot ghostty \\
             wezterm gnome-terminal konsole xfce4-terminal tilix terminator \\
             mate-terminal lxterminal urxvt xterm; do
        [ -z "\$T" ] && continue
        command -v "\$T" >/dev/null 2>&1 || continue
        case "\$T" in
            gnome-terminal) exec "\$T" -- "\$SELF" ;;
            wezterm)        exec "\$T" start -- "\$SELF" ;;
            *)              exec "\$T" -e "\$SELF" ;;
        esac
    done
fi

# --- Remove. Report only what was REALLY there: listing a file that was already
# gone would make the summary a lie.
# ⚠ The uninstaller is deliberately NOT counted here. It always exists while it
# is running, so counting it would make "nothing to remove" unreachable — a
# branch that can never run is a branch nobody tested.
GONE=""
for f in "$BIN" "$ICON" "$DESKTOP"; do
    [ -e "\$f" ] || continue
    GONE="\$GONE
  \$f"
done
rm -f "$BIN" "$ICON" "$DESKTOP"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" 2>/dev/null

if [ -n "\$GONE" ]; then
    WHAT="Removed:\$GONE
  \$SELF  (this uninstaller)"
else
    WHAT="Nothing to remove — it was not installed."
fi

MSG="pkmn-ricciolino has been uninstalled.

\$WHAT

Your saves were NOT touched. They are still in:
  \$SAVES"

echo "=== Uninstalling pkmn-ricciolino ==="
echo
echo "\$MSG"
echo

# --- Ways 2 and 3: tell someone who has no terminal in front of them.
if [ -t 0 ]; then
    echo "Press [ENTER] to close."
    read -r _
elif command -v zenity >/dev/null 2>&1; then
    zenity --info --width=560 --title="pkmn-ricciolino" --text="\$MSG"
elif command -v kdialog >/dev/null 2>&1; then
    kdialog --title "pkmn-ricciolino" --msgbox "\$MSG"
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "pkmn-ricciolino" "Uninstalled. Your saves are still in \$SAVES"
fi

rm -f "\$SELF"
EOF

# --- 5. install ---------------------------------------------------------------
mkdir -p "$BIN_DIR" "$ICON_DIR" "$APP_DIR"
install -m 755 "$tmp/$APP"     "$BIN"
install -m 644 "$tmp/icon.png" "$ICON"
install -m 755 "$tmp/uninstall" "$UNINSTALL"

sed -e "s|@BIN@|$BIN|g" \
    -e "s|@ICON_NAME@|$APP|g" \
    -e "s|@UNINSTALL@|$UNINSTALL|g" \
    "$tmp/app.desktop" > "$DESKTOP"
chmod 644 "$DESKTOP"

# Best-effort cache refresh. Absent on minimal systems, and the entry works
# without them on most desktops — so a failure here is not a failed install.
command -v update-desktop-database >/dev/null && update-desktop-database "$APP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache  >/dev/null && gtk-update-icon-cache -qtf "$DATA_DIR/icons/hicolor" 2>/dev/null || true

# --- 6. tell the user exactly what happened -----------------------------------
echo
say "Installed $tag"
echo "  binary      $BIN"
echo "  icon        $ICON"
echo "  menu entry  $DESKTOP"
echo "  uninstall   $UNINSTALL"
echo "  saves       $SAVES  (untouched)"
echo

case ":$PATH:" in
    *":$BIN_DIR:"*) echo "Run it with:  $APP" ;;
    *) warn "$BIN_DIR is not in your PATH."
       echo "  Run it with:  $BIN"
       echo "  Or add to your shell profile:  export PATH=\"\$PATH:$BIN_DIR\"" ;;
esac

echo
echo "The menu entry follows the XDG spec, so GNOME, KDE, XFCE and friends will"
echo "pick it up. Bare window managers (i3, sway, dwm) do not read .desktop files"
echo "themselves — launchers like rofi -show drun or dmenu_run do."
