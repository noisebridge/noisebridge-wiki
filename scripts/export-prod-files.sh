#!/usr/bin/env bash
set -euo pipefail

mode="${1:-all}"
source_ssh_host="${SOURCE_SSH_HOST:-jetpham@m3.noisebridge.net}"
source_mediawiki_dir="${SOURCE_MEDIAWIKI_DIR:-/srv/mediawiki/noisebridge.net}"
dump_dir="${DUMP_DIR:-$(pwd)/dump}"
timestamp="${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}"
output_dir="${dump_dir}/mediawiki-files-${timestamp}"
rsync_base=(rsync -aH --info=progress2)

mkdir -p "$output_dir"

copy_images=false
copy_img=false
case "$mode" in
  images) copy_images=true ;;
  img) copy_img=true ;;
  all) copy_images=true; copy_img=true ;;
  *)
    echo "Usage: $0 [images|img|all]" >&2
    exit 1
    ;;
esac

if $copy_images; then
  echo "Exporting images/ from ${source_ssh_host}" >&2
  "${rsync_base[@]}" "${source_ssh_host}:${source_mediawiki_dir}/images/" "${output_dir}/images/"
fi

if $copy_img; then
  echo "Exporting img/ from ${source_ssh_host}" >&2
  "${rsync_base[@]}" "${source_ssh_host}:${source_mediawiki_dir}/img/" "${output_dir}/img/"
fi

echo "Capturing LocalSettings.php and extension inventory" >&2
"${rsync_base[@]}" "${source_ssh_host}:${source_mediawiki_dir}/LocalSettings.php" "${output_dir}/LocalSettings.php"
ssh "$source_ssh_host" "ls -1 '${source_mediawiki_dir}/extensions' | sort" > "${output_dir}/extensions.txt"

echo "$output_dir"
