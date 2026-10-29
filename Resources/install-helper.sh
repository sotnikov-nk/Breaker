#!/bin/sh
# Installs or updates the Breaker LaunchDaemon. Run as root with the app's
# Contents/Resources directory as the only argument.
set -eu

SRC="$1"
LABEL=com.breaker.daemon
HELPER=/Library/PrivilegedHelperTools/$LABEL
PLIST=/Library/LaunchDaemons/$LABEL.plist

[ -f "$SRC/breakerd" ] || { echo "breakerd not found in $SRC" >&2; exit 1; }

# Migration from the same app's earlier names (LeakLock, before that VPN Guard): keep
# the settings and learned routes, then remove the old daemon so two kill switches
# never fight over pf. The new daemon loads its own rules right after it starts.
NEW_DIR="/Library/Application Support/Breaker"
for OLD_DIR in "/Library/Application Support/LeakLock" "/Library/Application Support/VPNGuard"; do
    if [ -d "$OLD_DIR" ] && [ ! -d "$NEW_DIR" ]; then
        /bin/cp -R "$OLD_DIR" "$NEW_DIR"
    fi
done
for OLD in com.leaklock.daemon:LeakLock com.vpnguard.daemon:VPNGuard; do
    OLD_LABEL=${OLD%%:*}
    OLD_ANCHOR=${OLD#*:}
    if [ -f "/Library/LaunchDaemons/$OLD_LABEL.plist" ] || [ -f "/Library/PrivilegedHelperTools/$OLD_LABEL" ]; then
        /bin/launchctl bootout "system/$OLD_LABEL" 2>/dev/null || true
        /bin/rm -f "/Library/LaunchDaemons/$OLD_LABEL.plist" "/Library/PrivilegedHelperTools/$OLD_LABEL" "/var/run/$OLD_LABEL.sock"
        /sbin/pfctl -a "com.apple/050.$OLD_ANCHOR" -F rules 2>/dev/null || true
    fi
done

# pf rules stay loaded while the daemon is replaced, so there is no unprotected gap.
/bin/launchctl bootout "system/$LABEL" 2>/dev/null || true

/bin/mkdir -p /Library/PrivilegedHelperTools
/bin/cp "$SRC/breakerd" "$HELPER.new"
/usr/bin/xattr -c "$HELPER.new" 2>/dev/null || true
/usr/sbin/chown root:wheel "$HELPER.new"
/bin/chmod 755 "$HELPER.new"
/bin/mv -f "$HELPER.new" "$HELPER"

/bin/cp "$SRC/$LABEL.plist" "$PLIST"
/usr/bin/xattr -c "$PLIST" 2>/dev/null || true
/usr/sbin/chown root:wheel "$PLIST"
/bin/chmod 644 "$PLIST"

# bootstrap can fail briefly while the old instance is still being torn down.
for _ in 1 2 3 4 5; do
    if /bin/launchctl bootstrap system "$PLIST" 2>/dev/null; then
        exit 0
    fi
    sleep 1
done
/bin/launchctl bootstrap system "$PLIST"
