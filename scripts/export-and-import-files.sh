#!/usr/bin/env bash
set -euo pipefail

mode="${1:-all}"
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"

dump_dir="$(${script_dir}/export-prod-files.sh "$mode" | tail -n1)"
${script_dir}/import-files-to-main.sh "$dump_dir" "$mode"
