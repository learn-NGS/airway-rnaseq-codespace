#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-8000}"
echo "Serving ./results on port $PORT"
echo "In GitHub Codespaces, open the PORTS tab and click the forwarded port."
python -m http.server "$PORT" --directory results
