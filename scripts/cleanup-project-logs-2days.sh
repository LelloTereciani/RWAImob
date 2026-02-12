#!/usr/bin/env bash
set -euo pipefail

# Remove local npm logs older than two days.
find /root/.npm/_logs -type f -name '*.log' -mtime +2 -print -delete 2>/dev/null || true
