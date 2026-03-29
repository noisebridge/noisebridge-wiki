#!/usr/bin/env bash
set -euo pipefail

files_mode="${1:-all}"
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"

${script_dir}/export-and-import-db.sh
${script_dir}/export-and-import-files.sh "$files_mode"
