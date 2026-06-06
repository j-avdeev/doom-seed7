#!/usr/bin/env bash
set -euo pipefail

port="${1:-8080}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

echo "Serving $repo_root"
echo "Open http://localhost:$port/web/index.html"
python -m http.server "$port" --bind 127.0.0.1 --directory "$repo_root"
