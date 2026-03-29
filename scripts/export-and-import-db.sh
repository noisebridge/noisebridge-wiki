#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"

dump_path="$(${script_dir}/export-prod-db.sh | tail -n1)"
${script_dir}/import-db-to-main.sh "$dump_path"
