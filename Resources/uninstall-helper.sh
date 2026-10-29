#!/bin/sh
# Removes the Breaker LaunchDaemon and lifts the block. Settings are kept in
# /Library/Application Support/Breaker for a later reinstall.
set -u

LABEL=com.breaker.daemon

/bin/launchctl bootout "system/$LABEL" 2>/dev/null || true
/bin/rm -f "/Library/LaunchDaemons/$LABEL.plist" "/Library/PrivilegedHelperTools/$LABEL" "/var/run/$LABEL.sock"
/sbin/pfctl -a "com.apple/050.Breaker" -F rules 2>/dev/null || true
exit 0
